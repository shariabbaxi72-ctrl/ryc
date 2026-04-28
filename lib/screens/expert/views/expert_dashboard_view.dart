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

  @override
  void initState() {
    super.initState();
    loadExpertData();
  }

  Future<void> loadExpertData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // 🔥 Login se match ki hui keys
      int uId = prefs.getInt('userId') ?? 0;
      int eId = prefs.getInt('expertId') ?? 0;

      print("DEBUG: Fetching for UID: $uId, EID: $eId");

      if (uId != 0) {
        var profileData = await ApiService.fetchExpertProfile(uId);
        var solutionsData = await ApiService.fetchExpertSolutions(eId);

        if (mounted) {
          setState(() {
            if (profileData != null) {
              name = profileData['username']?.toString() ?? "No Name";
              cat = profileData['category']?.toString() ?? "No Category";
              prefs.setString('saved_upicture', profileData['upicture']?.toString() ?? "");
            }
            solutions = solutionsData ?? [];
            isLoading = false; // ✅ Data mil gaya, loading stop
          });
          widget.onProfileLoaded();
        }
      } else {
        // Agar ID nahi mili, tab bhi circle band karo
        print("DEBUG: ID not found, stopping loader");
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print("DEBUG: Error: $e");
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
          const SizedBox(height: 30),
          const Align(alignment: Alignment.centerLeft, child: Text("List Of Solutions", style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              onRefresh: loadExpertData,
              color: const Color(0xFF1B2E4B),
              child: solutions.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text("No solutions added yet.\nPull down to refresh.")),
                ],
              )
                  : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: solutions.length,
                itemBuilder: (context, index) {
                  var sol = solutions[index];
                  String displayTitle = sol['solutionTitle']?.toString() ?? sol['stitle']?.toString() ?? "No Title";
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined, color: Color(0xFF1B2E4B)),
                      title: Text(displayTitle.trim(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                        onPressed: () {
                          // Navigator use karke sid pass karo
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditSolutionView(sidToEdit: sol['sid']),
                            ),
                          ).then((value) {
                            if (value == true) {
                              loadExpertData(); // Wapis aane par refresh
                            }
                          });
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
}