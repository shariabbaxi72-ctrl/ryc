import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'EditProblemScreen.dart';

class AdminProblemScreen extends StatefulWidget {
  final String adminName;
  final bool isAdmin;
  const AdminProblemScreen({super.key, required this.adminName, this.isAdmin = true});

  @override
  State<AdminProblemScreen> createState() => _AdminProblemScreenState();
}


class _AdminProblemScreenState extends State<AdminProblemScreen> {
  String currentSection = "Approved";
  bool showRejectReasons = false;
  List<dynamic> allProblems = [];
  bool isLoading = true;

  String selectedType = "Electrical";
  TextEditingController titleController = TextEditingController();
  TextEditingController descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!widget.isAdmin) currentSection = "Add";
    loadProblems();
  }

  void loadProblems() async {
    setState(() => isLoading = true);
    var data = await ApiService.fetchAllProblems();
    if (mounted) {
      setState(() {
        allProblems = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Agar reject screen dikhani hai, toh sirf wahi return karo
    if (showRejectReasons) {
      return Scaffold(
        body: SafeArea(child: _buildRejectReasonScreen()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isAdmin) _buildHeader(),
              if (!widget.isAdmin) const SizedBox(height: 20),
              _buildTabs(),
              const SizedBox(height: 25),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : currentSection == "Add"
                    ? _buildAddProblemForm()
                    : _buildProblemList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProblemList() {
    List filtered = allProblems.where((p) {
      if (p == null) return false;
      if (currentSection == "Pending") return p['type'] == "expert";
      if (currentSection == "Approved") return p['type'] == "admin";



      return false;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async => loadProblems(),
      child: filtered.isEmpty
          ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.only(top: 50), child: Text("No ${currentSection} records found.")))])
          : ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {

          var p = filtered[index];
          // Ensure 'pid' access, fall back to 'id' if needed
          var problemId = p['pid'] ?? p['id'];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Row(
              children: [
                Expanded(child: Text(p['ptitle'] ?? "Problem", style: const TextStyle(fontWeight: FontWeight.w500))),

                if (currentSection == "Approved")
                  Row(
                    children: [
                      // EDIT BUTTON
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 24),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProblemScreen(
                                problem: p,
                                onUpdate: () => loadProblems(),
                              ),
                            ),
                          );
                        },
                      ),

                    ],
                  )
                else
                  Row(
                    children: [
                      // TICK (APPROVE)
                      IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                          onPressed: () async {
                            // Current 'p' object mein status badlo
                            Map<String, dynamic> updatedData = Map<String, dynamic>.from(p);
                            updatedData['type'] = 'admin';

                            // Api call karo
                            bool success = await ApiService.updateProblem(updatedData);
                            if (success) {
                              loadProblems();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update Failed!")));
                            }
                          }
                      ),
                      // CROSS (DELETE)
                      // Cross (Delete) button action
                      IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                          onPressed: () async {
                            // Backend se pid mang raha hai
                            var pid = p['pid'];

                            if (pid != null) {
                              bool success = await ApiService.deleteProblem(pid);
                              if (success) {
                                loadProblems(); // UI refresh
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Problem Deleted!")));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot delete: Linked with solutions!")));
                              }
                            }
                          }
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddProblemForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(widget.isAdmin ? "Add Problem" : " Problem", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio(value: "Electrical", groupValue: selectedType, onChanged: (val) => setState(() => selectedType = val.toString())),
              const Text("Electrical"),
              const SizedBox(width: 20),
              Radio(value: "Mechanical", groupValue: selectedType, onChanged: (val) => setState(() => selectedType = val.toString())),
              const Text("Mechanical"),
            ],
          ),
          const SizedBox(height: 20),
          TextField(controller: titleController, decoration: InputDecoration(labelText: "Problem Title", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 15),
          TextField(controller: descController, maxLines: 4, decoration: InputDecoration(labelText: "Problem Description", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001F3F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                int? userId = prefs.getInt('userId');
                if (userId == null) return;

                bool success = await ApiService.addProblem({
                  "title": titleController.text,
                  "description": descController.text,
                  "category": selectedType,
                  "type": widget.isAdmin ? "admin" : "expert",
                  "uid": userId
                });

                if (success) {
                  titleController.clear();
                  descController.clear();
                  loadProblems();
                }
              },
              child: const Text("Save", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    if (!widget.isAdmin) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: ["Approved", "Pending", "Add"].map((t) => Expanded(
          child: InkWell(
            onTap: () => setState(() => currentSection = t),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: currentSection == t ? const Color(0xFF001F3F) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(t, style: TextStyle(color: currentSection == t ? Colors.white : Colors.black54, fontWeight: FontWeight.bold))),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20), onPressed: () => Navigator.pop(context)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
            Text(widget.adminName, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ],
    );
  }
  Widget _buildRejectReasonScreen() => Column(children: [
    const Text("Reject Reason"),
    ElevatedButton(onPressed: () => setState(() => showRejectReasons = false), child: const Text("Back"))
  ]);
}
