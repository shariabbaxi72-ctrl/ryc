
import 'package:flutter/material.dart';
import 'package:ryc/services/api_service.dart';
import 'package:ryc/utils/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SolutionDetailView extends StatefulWidget {
  final int sid;
  final String? selectedCar;
  final String? selectedProblem;
  final String? expertName;
  final VoidCallback onFinish;

  const SolutionDetailView({
    super.key, required this.sid, this.selectedCar, this.selectedProblem, this.expertName, required this.onFinish,
  });

  @override
  State<SolutionDetailView> createState() => _SolutionDetailViewState();
}

class _SolutionDetailViewState extends State<SolutionDetailView> {
  int _userRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  late Future<List<dynamic>> _stepsFuture;
  Future<List<dynamic>>? _reviewsFuture;
  String? _enlargedImage;
  bool _alreadyReviewed = false;
  int? _currentUid;


  @override
  void initState() {
    super.initState();

    _loadUserId();


    _stepsFuture = ApiService.fetchStepsBySolutionId(widget.sid);
    _reviewsFuture = _fetchReviews();
  }


  void _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUid = prefs.getInt('userId');
    });
  }



  Future<List<dynamic>> _fetchReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String currentUserName = prefs.getString('username') ?? "";

      final url = "${AppConstants.baseUrl}/ratings/solution/${widget.sid}";
      final response = await http.get(Uri.parse(url), headers: {"ngrok-skip-browser-warning": "69420"});

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _alreadyReviewed = data.any((rev) => rev['reviewerName'] == currentUserName);
        });
        return data;
      }
      return [];
    } catch (e) { return []; }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _headerSection(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  FutureBuilder<List<dynamic>>(
                    future: _stepsFuture,
                    builder: (context, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      return Column(
                        children: snap.data!.map((s) => StepRatingCard(
                          step: s,
                          sid: widget.sid,
                          uid: _currentUid,
                          onZoom: (url) => setState(() => _enlargedImage = url),
                        )).toList(),
                      );
                    },
                  ),
                  const Text("User Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  FutureBuilder<List<dynamic>>(
                    future: _reviewsFuture,
                    builder: (context, rev) {
                      if (!rev.hasData || rev.data!.isEmpty) return const Padding(padding: EdgeInsets.all(10), child: Text("No reviews yet."));
                      return Column(children: rev.data!.map((r) => _reviewTile(r)).toList());
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  if (_alreadyReviewed) {
                    widget.onFinish();
                  } else {
                    _showRatingDialog();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2E4B),
                    minimumSize: const Size(double.infinity, 50)),
                child: const Text("Finish", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
        if (_enlargedImage != null) _zoomOverlay(),
      ],
    );
  }

  Widget _headerSection() => Container(
    margin: const EdgeInsets.all(20),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Vehicle: ${widget.selectedCar ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text("Problem: ${widget.selectedProblem ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
        const SizedBox(height: 5),
        Text("Expert: ${widget.expertName ?? 'N/A'}", style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );

  Widget _zoomOverlay() => GestureDetector(
    onTap: () => setState(() => _enlargedImage = null),
    child: Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(child: Image.network(_enlargedImage!)),
    ),
  );

  Widget _reviewTile(dynamic rev) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      title: Text(rev['reviewerName'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(rev['reviewText'] ?? ""),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < (rev['rating'] ?? 0) ? Colors.amber : Colors.grey))),
    ),
  );

  void _showRatingDialog() {
    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text("Rate Solution"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(onTap: () => setDialogState(() => _userRating = i + 1), child: Icon(_userRating > i ? Icons.star : Icons.star_border, color: Colors.amber, size: 40)))),
        TextField(controller: _reviewController, decoration: const InputDecoration(hintText: "Review (optional)")),
      ]),
      actions: [
        TextButton(onPressed: () { Navigator.pop(context); widget.onFinish(); }, child: const Text("Skip")),
        ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2E4B)),
            onPressed: () async {
              if (_userRating > 0) {
                await _submitRating();
                Navigator.pop(context);
                widget.onFinish();
              } else {
                Navigator.pop(context);
                widget.onFinish();
              }
            },
            child: const Text("Submit", style: TextStyle(color: Colors.white))
        ),
      ],
    )));
  }

  Future<void> _submitRating() async {
    try {
      final url = "${AppConstants.baseUrl}/ratings";
      await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json", "ngrok-skip-browser-warning": "69420"},
          body: json.encode({
            "uid": _currentUid,
            "sid": widget.sid,
            "rating": _userRating,
            "review": _reviewController.text
          })
      );
    } catch (e) { debugPrint("Rating Submit Error: $e"); }
  }
}

class StepRatingCard extends StatefulWidget {
  final dynamic step;
  final int sid;
  final int? uid;
  final Function(String) onZoom;

  const StepRatingCard({super.key, required this.step, required this.sid, required this.uid, required this.onZoom});

  @override
  State<StepRatingCard> createState() => _StepRatingCardState();
}

class _StepRatingCardState extends State<StepRatingCard> {
  bool _showInput = false;
  int _sRating = 0;
  final TextEditingController _sReview = TextEditingController();
  bool _isSubmitted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (widget.uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {

      final prefs = await SharedPreferences.getInstance();
      String currentUserName = prefs.getString('username') ?? "";

      final stepId = widget.step['stepId'] ?? widget.step['id'];
      final url = "${AppConstants.baseUrl}/stepfeedback/get/$stepId";

      final res = await http.get(
          Uri.parse(url),
          headers: {"ngrok-skip-browser-warning": "69420"}
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final List ratings = data['ratings'] ?? [];

        setState(() {

          _isSubmitted = ratings.any((r) {

            bool nameMatch = r['rname']?.toString().toLowerCase() == currentUserName.toLowerCase();


            bool idMatch = r['uid']?.toString() == widget.uid.toString() ||
                r['userId']?.toString() == widget.uid.toString();

            return nameMatch || idMatch;
          });
        });
      }
    } catch (e) {
      debugPrint("Status Check Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitStepFeedback() async {
    if (_sRating == 0) return;
    try {
      final url = "${AppConstants.baseUrl}/stepfeedback/add";
      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json", "ngrok-skip-browser-warning": "69420"},
        body: json.encode({
          "stepid": widget.step['stepId'] ?? widget.step['id'],
          "sid": widget.sid,
          "uid": widget.uid,
          "srating": _sRating,
          "sreview": _sReview.text.trim()
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() { _isSubmitted = true; _showInput = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Step feedback sent!")));
      }
    } catch (e) { debugPrint("Submit Step Error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    String url = "${AppConstants.baseUrl.replaceFirst('/api', '')}/${widget.step['image'] ?? ''}";
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Step ${widget.step['stepNo']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            if (!_isLoading) InkWell(
              onTap: () => _isSubmitted ? null : setState(() => _showInput = !_showInput),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _isSubmitted ? Colors.green.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(_isSubmitted ? Icons.check_circle : Icons.star_outline, size: 16, color: _isSubmitted ? Colors.green : Colors.blue),
                  const SizedBox(width: 4),
                  Text(_isSubmitted ? "Submitted" : "Rate Step", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isSubmitted ? Colors.green : Colors.blue)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(widget.step['description'] ?? ""),
        const SizedBox(height: 12),
        if (widget.step['image'] != null) GestureDetector(
          onTap: () => widget.onZoom(url),
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(url, height: 160, width: double.infinity, fit: BoxFit.cover)),
        ),
        if (_showInput && !_isSubmitted) ...[
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(onTap: () => setState(() => _sRating = i + 1), child: Icon(_sRating > i ? Icons.star : Icons.star_border, color: Colors.amber, size: 30)))),
              const SizedBox(height: 10),
              TextField(controller: _sReview, decoration: const InputDecoration(hintText: "Step review (optional)", border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8))),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _sRating > 0 ? _submitStepFeedback : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2E4B), minimumSize: const Size(double.infinity, 40)),
                child: const Text("SUBMIT FEEDBACK", style: TextStyle(color: Colors.white, fontSize: 12)),
              )
            ]),
          )
        ]
      ]),
    );
  }
}