import 'package:flutter/material.dart';
import 'package:ryc/services/api_service.dart';
import 'package:ryc/services/auth_service.dart'; // Register ke liye

class AdminUserScreen extends StatefulWidget {
  final String adminName;
  const AdminUserScreen({super.key, required this.adminName});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  String currentSection = "List of all user";
  bool isLoading = false;
  List<dynamic> usersList = []; // Real Data List

  // Add User Form Controllers
  TextEditingController userNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Screen load hote hi users le aao
  }

  // --- Logic: API se Users Fetch karna ---
  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    final data = await ApiService.getAllUsers();
    setState(() {
      usersList = data;
      isLoading = false;
    });
  }

  // --- Logic: Naya User Save karna ---
  Future<void> _saveUser() async {
    if (userNameController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackBar("Fields Empty!");
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      _showSnackBar("Password Does not  Match !");
      return;
    }

    setState(() => isLoading = true);

    // AuthService ka register function use ho raha hai
    final result = await AuthService.register(
      username: userNameController.text,
      password: passwordController.text,
      type: "user", // Admin panel se hamesha 'user' add hoga
    );

    setState(() => isLoading = false);

    if (result['status'] == "success") {
      _showSnackBar("User Saved Successfully!");
      userNameController.clear();
      passwordController.clear();
      confirmPasswordController.clear();

      // Save hote hi List wale tab par le jao aur refresh karo
      setState(() => currentSection = "List of all user");
      _fetchUsers();
    } else {
      _showSnackBar(result['message'] ?? "Error saving user");
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
              // 1. Back Arrow and Title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Admin',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 45),
                child: Text(widget.adminName, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ),
              const SizedBox(height: 25),

              // 2. Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    _userTab("List of all user"),
                    _userTab("Add User"),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 3. Dynamic Content
              Expanded(
                child: isLoading && currentSection == "List of all user"
                    ? const Center(child: CircularProgressIndicator())
                    : currentSection == "Add User"
                    ? _buildAddUserForm()
                    : _buildUserList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- USER LIST SECTION (REAL DATA) ---
  // --- USER LIST SECTION (REAL DATA) ---
  Widget _buildUserList() {
    if (usersList.isEmpty) return const Center(child: Text("No users found."));

    return RefreshIndicator(
      onRefresh: _fetchUsers, // Swipe down to refresh
      color: const Color(0xFF001F3F),
      child: ListView.builder(
        itemCount: usersList.length,
        physics: const AlwaysScrollableScrollPhysics(), // Zaroori hai refresh ke liye
        itemBuilder: (context, index) {
          final user = usersList[index];

          // Debugging ke liye (Console mein check karein path aa raha hai ya nahi)
          print("User: ${user['username']}, Image: ${user['upicture']}");

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                // --- PROFILE PIC LOGIC (EXPERT WALI) ---
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFF001F3F),
                  backgroundImage: (user['upicture'] != null && user['upicture'].toString().isNotEmpty)
                      ? NetworkImage(ApiService.getFullImageUrl(user['upicture']))
                      : null,
                  child: (user['upicture'] == null || user['upicture'].toString().isEmpty)
                      ? Text(
                    (user['username'] ?? "U")[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )
                      : null,
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['username'] ?? "No Name",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user['type'] ?? "user",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  // --- ADD USER FORM SECTION ---
  Widget _buildAddUserForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputLabel("User Name"),
          _inputField("Enter User Name", userNameController),

          _inputLabel("Password"),
          _inputField("Enter Password", passwordController, isPassword: true),

          _inputLabel("Confirm Password"),
          _inputField("Confirm Password", confirmPasswordController, isPassword: true),

          const SizedBox(height: 40),

          Center(
            child: SizedBox(
              width: 150,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F3F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isLoading ? null : _saveUser,
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputLabel(String label) => Padding(
    padding: const EdgeInsets.only(top: 15, bottom: 5),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  Widget _inputField(String hint, TextEditingController ctrl, {bool isPassword = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _userTab(String title) {
    bool isSelected = currentSection == title;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => currentSection = title);
          if (title == "List of all user") _fetchUsers();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF001F3F) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}