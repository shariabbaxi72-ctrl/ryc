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
  String? _enlargedImage; // Zoom ke liye

  @override
  void initState() {
    super.initState();
    _stepsFuture = ApiService.fetchStepsBySolutionId(widget.sid);
    _reviewsFuture = _fetchReviews();
  }

  Future<List<dynamic>> _fetchReviews() async {
    try {
      final url = "${AppConstants.baseUrl}/ratings/solution/${widget.sid}";
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200 ? json.decode(response.body) : [];
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
                      return Column(children: snap.data!.map((s) => _stepCard(s)).toList());
                    },
                  ),
                  const Text("User Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                onPressed: () => _showRatingDialog(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2E4B), minimumSize: const Size(double.infinity, 50)),
                child: const Text("Finish & Rate", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
        // Image Zoom Overlay
        if (_enlargedImage != null) _zoomOverlay(),
      ],
    );
  }

  Widget _headerSection() => Container(
    margin: const EdgeInsets.all(20),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15)
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Vehicle: ${widget.selectedCar ?? 'N/A'}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        // Yahan Problem add kiya hai
        Text("Problem: ${widget.selectedProblem ?? 'N/A'}",
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
        const SizedBox(height: 5),
        Text("Expert: ${widget.expertName ?? 'N/A'}",
            style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );

  Widget _stepCard(dynamic step) {
    String url = "${AppConstants.baseUrl.replaceFirst('/api', '')}/${step['image'] ?? ''}";
    return Container(
      margin: const EdgeInsets.only(bottom: 15), padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Step ${step['stepNo']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        const SizedBox(height: 8),
        Text(step['description'] ?? ""),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => _enlargedImage = url),
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(url, height: 160, width: double.infinity, fit: BoxFit.cover)),
        ),
      ]),
    );
  }

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
                // Rating submit hone ka wait karo
                await _submitRating();
                // Submit hone ke baad hi screen band karo
                Navigator.pop(context);
                widget.onFinish();
              } else {
                // Agar rating nahi di, to sirf skip
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
      int uid = (await SharedPreferences.getInstance()).getInt('userId') ?? 0;

      // Yahan URL check karo. Agar baseUrl mein '/api' pehle se hai,
      // to yahan '/ratings' likho. Agar nahi hai, to '/api/ratings' likho.
      final url = "${AppConstants.baseUrl.replaceAll('/api', '')}/api/ratings";

      final response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "uid": uid,
            "sid": widget.sid,
            "rating": _userRating,
            "review": _reviewController.text
          })
      );

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Rating Submit Error: $e");
    }
  }
}