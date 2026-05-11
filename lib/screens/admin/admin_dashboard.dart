import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Isse add kar lena
import 'package:ryc/routes/routes.dart';
import 'package:ryc/screens/admin/admin_problem_screen.dart';
import 'package:ryc/screens/admin/admin_vehicle_screen.dart';

import 'admin_expert_screen.dart';
import 'admin_solutions_screen.dart';
import 'admin_user_screen.dart';

class AdminScreen extends StatefulWidget {
  final String adminName;

  const AdminScreen({
    super.key,
    required this.adminName,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String active = "Expert";

  // --- ASAN LOGOUT LOGIC ---
  void logoutAction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Login data delete
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // SafeArea lagane se top bar (time, battery) ke niche content nahi dabi ga
      body: SafeArea(
        child: SingleChildScrollView( // <--- Ye line add ki hai overflow khatam karne ke liye
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40), // Top margin
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF001F3F),
                  ),
                ),
                const SizedBox(height: 5),
                Container(width: 80, height: 2, color: Colors.blueGrey),
                const SizedBox(height: 50),

                // Row 1: Expert & Vehicle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMenuButton("Expert", () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AdminExpertScreen(adminName: widget.adminName)));
                    }),
                    const SizedBox(width: 20),
                    _buildMenuButton("Vehicle", () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AdminVehicleScreen(adminName: widget.adminName)));
                    }),
                  ],
                ),

                const SizedBox(height: 20),

                // Row 2: User & Problem
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMenuButton("User", () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AdminUserScreen(adminName: widget.adminName)));
                    }),
                    const SizedBox(width: 20),
                    _buildMenuButton("Problem", () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AdminProblemScreen(adminName: widget.adminName)));
                    }),
                  ],
                ),
                // Row 2 ke niche ye add karein:
                const SizedBox(height: 20),

// Row 3: Solutions Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMenuButton("Solutions", () {
                      // Abhi humne screen nahi banayi, isliye screen banane ke baad navigation add karenge
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminSolutionsScreen(adminName: widget.adminName))
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 50),

                // Logout Button
                SizedBox(
                  width: 260,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5998),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: logoutAction,
                    child: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40), // Bottom margin
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Common Button Style (Purana Logic)
  Widget _buildMenuButton(String title, VoidCallback onTap) {
    return SizedBox(
      width: 120,
      height: 100,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: active == title ? const Color(0xFF3B5998) : Colors.white,
          foregroundColor: active == title ? Colors.white : Colors.black,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          setState(() { active = title; });
          onTap();
        },
        child: Text(title),
      ),
    );
  }
}