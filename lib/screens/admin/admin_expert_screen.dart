import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminExpertScreen extends StatefulWidget {
  final String adminName;
  const AdminExpertScreen({super.key, required this.adminName});

  @override
  State<AdminExpertScreen> createState() => _AdminExpertScreenState();
}

class _AdminExpertScreenState extends State<AdminExpertScreen> {
  String currentSection = "Approved";
  List<dynamic> expertsList = [];
  bool isLoading = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController confirmController = TextEditingController();
  bool electrical = false;
  bool mechanical = false;

  @override
  void initState() {
    super.initState();
    fetchExpertsData();
  }

  Future<void> fetchExpertsData() async {
    if (currentSection == "Add") return;
    setState(() => isLoading = true);
    List<dynamic> data;
    if (currentSection == "Approved") {
      data = await ApiService.getApprovedExperts();
    } else {
      data = await ApiService.getPendingExperts();
    }
    setState(() {
      expertsList = data;
      isLoading = false;
    });
  }

  // --- NEW: Alert Dialog for Delete ---
  void confirmDelete(int uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this expert?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              handleUserAction(uid, "delete");
            },
            child: const Text("Yes, Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void handleUserAction(int uid, String actionType) async {
    bool success = false;
    if (actionType == "approve") {
      success = await ApiService.approveExpert(uid);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expert Approved Successfully!"), backgroundColor: Colors.green),
        );
      }
    } else {
      success = await ApiService.deleteUser(uid);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expert Deleted Successfully!"), backgroundColor: Colors.redAccent),
        );
      }
    }

    if (success) fetchExpertsData();
  }

  void saveExpertByAdmin() async {
    if (passController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
      return;
    }
    String category = electrical ? "Electrical" : "Mechanical";
    bool ok = await ApiService.addExpertAdmin(nameController.text, passController.text, category);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Expert Added Successfully!")));
      nameController.clear(); passController.clear(); confirmController.clear();
      setState(() => currentSection = "Approved");
      fetchExpertsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 25),
              _buildTabsRow(),
              const SizedBox(height: 25),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (currentSection == "Add" ? _showAddForm() : _showExpertList()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20), onPressed: () => Navigator.pop(context)),
            const Text('Welcome', style: TextStyle(fontSize: 28, fontWeight: FontWeight.normal, color: Color(0xFF001F3F))),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 45),
          child: Text(widget.adminName, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTabsRow() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [_myTab("Approved"), _myTab("Pending"), _myTab("Add")],
      ),
    );
  }

  Widget _showExpertList() {
    if (expertsList.isEmpty) return const Center(child: Text("No experts found."));
    return ListView.builder(
      itemCount: expertsList.length,
      itemBuilder: (context, index) {
        final expert = expertsList[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blueGrey.shade100,
                backgroundImage: expert['upicture'] != null
                    ? NetworkImage(ApiService.getFullImageUrl(expert['upicture']))
                    : null,
                child: expert['upicture'] == null ? const Icon(Icons.person, color: Colors.white) : null,
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expert['username'] ?? "Unknown", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(expert['category'] ?? "Expert", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              currentSection == "Approved"
                  ? IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => confirmDelete(expert['uid']))
                  : Row(
                children: [
                  IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => handleUserAction(expert['uid'], "approve")),
                  IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => confirmDelete(expert['uid'])),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _showAddForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Expert Name", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          _customTextField(nameController, "Enter Name"),
          const SizedBox(height: 15),
          const Text("Password", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          _customTextField(passController, "Enter Password", isPass: true),
          const SizedBox(height: 15),
          const Text("Confirm Password", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          _customTextField(confirmController, "Repeat Password", isPass: true),
          const SizedBox(height: 10),
          CheckboxListTile(
            title: const Text("Electrical "),
            value: electrical,
            onChanged: (val) => setState(() { electrical = val!; if(val) mechanical = false; }),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            title: const Text("Mechanical "),
            value: mechanical,
            onChanged: (val) => setState(() { mechanical = val!; if(val) electrical = false; }),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001F3F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: saveExpertByAdmin,
              child: const Text("SAVE EXPERT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _customTextField(TextEditingController controller, String hint, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _myTab(String title) {
    bool selected = currentSection == title;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => currentSection = title);
          fetchExpertsData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF001F3F) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(title, style: TextStyle(color: selected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}