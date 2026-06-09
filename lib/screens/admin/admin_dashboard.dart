// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Isse add kar lena
// import 'package:ryc/routes/routes.dart';
// import 'package:ryc/screens/admin/admin_problem_screen.dart';
// import 'package:ryc/screens/admin/admin_vehicle_screen.dart';
//
// import 'admin_expert_screen.dart';
// import 'admin_solutions_screen.dart';
// import 'admin_user_screen.dart';
//
// class AdminScreen extends StatefulWidget {
//   final String adminName;
//
//   const AdminScreen({
//     super.key,
//     required this.adminName,
//   });
//
//   @override
//   State<AdminScreen> createState() => _AdminScreenState();
// }
//
// class _AdminScreenState extends State<AdminScreen> {
//   String active = "Expert";
//
//   // --- ASAN LOGOUT LOGIC ---
//   void logoutAction() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Logout"),
//         content: const Text("Are you sure you want to logout?"),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
//           TextButton(
//             onPressed: () async {
//               SharedPreferences prefs = await SharedPreferences.getInstance();
//               await prefs.clear(); // Login data delete
//               Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
//             },
//             child: const Text("Yes"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       // SafeArea lagane se top bar (time, battery) ke niche content nahi dabi ga
//       body: SafeArea(
//         child: SingleChildScrollView( // <--- Ye line add ki hai overflow khatam karne ke liye
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const SizedBox(height: 40), // Top margin
//                 const Text(
//                   'Admin Dashboard',
//                   style: TextStyle(
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF001F3F),
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 Container(width: 80, height: 2, color: Colors.blueGrey),
//                 const SizedBox(height: 50),
//
//                 // Row 1: Expert & Vehicle
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     _buildMenuButton("Expert", () {
//                       Navigator.push(context, MaterialPageRoute(builder: (context) => AdminExpertScreen(adminName: widget.adminName)));
//                     }),
//                     const SizedBox(width: 20),
//                     _buildMenuButton("Vehicle", () {
//                       Navigator.push(context, MaterialPageRoute(builder: (context) => AdminVehicleScreen(adminName: widget.adminName)));
//                     }),
//                   ],
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // Row 2: User & Problem
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     _buildMenuButton("User", () {
//                       Navigator.push(context, MaterialPageRoute(builder: (context) => AdminUserScreen(adminName: widget.adminName)));
//                     }),
//                     const SizedBox(width: 20),
//                     _buildMenuButton("Problem", () {
//                       Navigator.push(context, MaterialPageRoute(builder: (context) => AdminProblemScreen(adminName: widget.adminName)));
//                     }),
//                   ],
//                 ),
//                 // Row 2 ke niche ye add karein:
//                 const SizedBox(height: 20),
//
// // Row 3: Solutions Button
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     _buildMenuButton("Solutions", () {
//                       // Abhi humne screen nahi banayi, isliye screen banane ke baad navigation add karenge
//                       Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => AdminSolutionsScreen(adminName: widget.adminName))
//                       );
//                     }),
//                   ],
//                 ),
//
//                 const SizedBox(height: 50),
//
//                 // Logout Button
//                 SizedBox(
//                   width: 260,
//                   height: 50,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF3B5998),
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                     ),
//                     onPressed: logoutAction,
//                     child: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold)),
//                   ),
//                 ),
//                 const SizedBox(height: 40), // Bottom margin
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Common Button Style (Purana Logic)
//   Widget _buildMenuButton(String title, VoidCallback onTap) {
//     return SizedBox(
//       width: 120,
//       height: 100,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: active == title ? const Color(0xFF3B5998) : Colors.white,
//           foregroundColor: active == title ? Colors.white : Colors.black,
//           side: BorderSide(color: Colors.grey.shade300),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         ),
//         onPressed: () {
//           setState(() { active = title; });
//           onTap();
//         },
//         child: Text(title),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ryc/services/api_service.dart'; // Ensure this import is correct
import 'admin_expert_screen.dart';
import 'admin_solutions_screen.dart';
import 'admin_user_screen.dart';
import 'admin_problem_screen.dart';
import 'admin_vehicle_screen.dart';

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

  // 1. Counts store karne ke liye Map (iOS same keys)
  Map<String, int> counts = {
    "experts": 0,
    "vehicles": 0,
    "users": 0,
    "problems": 0,
    "solutions": 0
  };

  @override
  void initState() {
    super.initState();
    loadCounts(); // Screen load hotay hi counts fetch honge
  }

  // 2. Naya Function: Backend se counts lane ke liye
  Future<void> loadCounts() async {
    try {
      var data = await ApiService.fetchAdminDashboardCounts();
      if (mounted && data.isNotEmpty) {
        setState(() {
          counts = data;
        });
      }
    } catch (e) {
      print("Error loading counts: $e");
    }
  }

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
              await prefs.clear();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadCounts, // Pull to refresh feature
          color: const Color(0xFF001F3F),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
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
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminExpertScreen(adminName: widget.adminName))).then((_) => loadCounts());
                      }),
                      const SizedBox(width: 20),
                      _buildMenuButton("Vehicle", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminVehicleScreen(adminName: widget.adminName))).then((_) => loadCounts());
                      }),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Row 2: User & Problem
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMenuButton("User", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminUserScreen(adminName: widget.adminName))).then((_) => loadCounts());
                      }),
                      const SizedBox(width: 20),
                      _buildMenuButton("Problem", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminProblemScreen(adminName: widget.adminName))).then((_) => loadCounts());
                      }),
                    ],
                  ),

                  const SizedBox(height: 20),


                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMenuButton("Solutions", () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminSolutionsScreen(adminName: widget.adminName))).then((_) => loadCounts());
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
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Updated Button Style: Jaisa iOS mein tha (Title + Count Badge)
  Widget _buildMenuButton(String title, VoidCallback onTap) {
    // Key mapping to match backend/iOS
    String key = title.toLowerCase();
    if (key == "expert") key = "experts";
    if (key == "vehicle") key = "vehicles";
    if (key == "user") key = "users";
    if (key == "problem") key = "problems";

    int countValue = counts[key] ?? 0;

    return SizedBox(
      width: 140, // Width match with iOS box style
      height: 110,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 3,
          side: BorderSide(color: Colors.grey.shade200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          setState(() { active = title; });
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$countValue",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}