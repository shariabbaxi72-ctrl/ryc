
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import 'expertEditSolutionView.dart';

class ExpertDashboardView extends StatefulWidget {
  final VoidCallback onAddSolution;
  final VoidCallback onProfileLoaded;

  const ExpertDashboardView({super.key, required this.onAddSolution, required this.onProfileLoaded});

  @override
  State<ExpertDashboardView> createState() => _ExpertDashboardViewState();
}

class _ExpertDashboardViewState extends State<ExpertDashboardView> {
  String name = "Loading...";
  String cat = "Expert";
  bool isLoading = true;
  List<dynamic> solutions = [];

  double overallRating = 0.0;
  int totalReviews = 0;
  int totalSolutionsCount = 0;

  String selectedMake = "All";
  List<String> availableMakes = ["All"];
  double filteredBrandRating = 0.0;

  @override
  void initState() {
    super.initState();
    fetchMakesAndLoadData();
  }

  Future<void> fetchMakesAndLoadData() async {
    try {
      var makes = await ApiService.fetchAvailableMakes();
      if (mounted) {
        setState(() {
          availableMakes = makes;
        });
      }
      await loadExpertData();
    } catch (e) {
      print("Error in initial load: $e");
    }
  }

  Future<void> loadExpertData() async {
    try {
      if (!isLoading) setState(() => isLoading = true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int uId = prefs.getInt('userId') ?? 0;
      int eId = prefs.getInt('expertId') ?? 0;

      if (uId != 0) {
        var profileData = await ApiService.fetchExpertProfile(uId);
        var dashboardRes = await ApiService.fetchExpertDashboardData(eId, selectedMake);
        var perfData = await ApiService.fetchExpertPerformance(uId);

        if (mounted) {
          setState(() {
            if (profileData != null) {
              name = profileData['username']?.toString() ?? "No Name";
              cat = profileData['category']?.toString() ?? "No Category";
              prefs.setString('saved_upicture', profileData['upicture']?.toString() ?? "");
            }
            if (perfData != null) {
              overallRating = double.tryParse(perfData['overallRating']?.toString() ?? '0.0') ?? 0.0;
              totalReviews = int.tryParse(perfData['totalReviews']?.toString() ?? '0') ?? 0;
              totalSolutionsCount = int.tryParse(perfData['totalSolutions']?.toString() ?? '0') ?? 0;
            }
            if (dashboardRes != null) {
              solutions = dashboardRes['solutions'] ?? [];
              filteredBrandRating = double.tryParse(dashboardRes['filteredOverallRating']?.toString() ?? '0.0') ?? 0.0;
            }
            isLoading = false;
          });
          widget.onProfileLoaded();
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1B2E4B)));
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text("$name ($cat)", style: const TextStyle(color: Color(0xFF1B2E4B), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // 1. OVERALL PERFORMANCE CARD
          //_buildPerformanceCard(),

          const SizedBox(height: 20),

          // 2. FILTER & LIST HEADER (Card ke nichay set kiya hai)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("List Of Solutions", style: TextStyle(fontWeight: FontWeight.bold)),
                  if (selectedMake != "All")
                    Text(
                      "$selectedMake Score: ${filteredBrandRating.toStringAsFixed(1)} ★",
                      style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedMake,
                    icon: const Icon(Icons.filter_list, size: 16, color: Colors.blue),
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => selectedMake = newValue);
                        loadExpertData();
                      }
                    },
                    items: availableMakes.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3. SOLUTIONS LIST
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadExpertData,
              color: const Color(0xFF1B2E4B),
              child: solutions.isEmpty
                  ? ListView(
                children: const [
                  SizedBox(height: 50),
                  Center(child: Text("No solutions found.")),
                ],
              )
                  : ListView.builder(
                itemCount: solutions.length,
                itemBuilder: (context, index) {
                  var item = solutions[index];
                  String displayTitle = item['solution']?['title']?.toString() ?? "No Title";
                  double itemRating = double.tryParse(item['Rating']?.toString() ?? '0.0') ?? 0.0;
                  int itemRatingCount = int.tryParse(item['RatingCount']?.toString() ?? '0') ?? 0;
                  int sid = item['sid'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined, color: Color(0xFF1B2E4B)),
                      title: Text("${index + 1}. $displayTitle", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Row(
                        children: [
                          // 1. Stars Generate karna (5 Stars loop)
                          ...List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < itemRating.floor()
                                  ? Icons.star
                                  : (starIndex < itemRating ? Icons.star_half : Icons.star_border),
                              color: Colors.amber,
                              size: 14,
                            );
                          }),
                          const SizedBox(width: 8),
                          // 2. Rating Value (e.g. 4.5) aur Count (e.g. 10)
                          Text(
                            "${itemRating.toStringAsFixed(1)} ($itemRatingCount)",
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditSolutionView(sidToEdit: sid)),
                          ).then((value) => loadExpertData());
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: widget.onAddSolution,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2E4B), minimumSize: const Size(double.infinity, 45)),
            child: const Text("Add New Solution", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Overall Performance", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < overallRating.floor() ? Icons.star : (index < overallRating ? Icons.star_half : Icons.star_border),
                          color: Colors.orangeAccent,
                          size: 18,
                        );
                      }),
                      const SizedBox(width: 5),
                      Text(overallRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Solutions", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text("$totalSolutionsCount", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B2E4B))),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.people, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text("Based on $totalReviews user reviews", style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}