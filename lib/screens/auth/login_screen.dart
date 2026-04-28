import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ryc/routes/routes.dart';
import 'package:ryc/services/auth_service.dart';
import 'package:ryc/screens/expert/expert.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../admin/admin_dashboard.dart';
import '../admin/admin_vehicle_screen.dart'; // Import expert dashboard

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isPasswordHidden = true;
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  void _handleLogin() async {
    String username = usernameController.text.trim();
    String pass = passwordController.text.trim();

    if (username.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All fields required")));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    var result = await AuthService.login(username, pass);

    if (mounted) Navigator.pop(context);

    if (result['status'] == "success") {
      var userData = result['data'];

      SharedPreferences prefs = await SharedPreferences.getInstance();

      // 1. UserID hamesha save hogi (Kyunke ye null nahi hoti)
      await prefs.setInt('userId', userData['userId'] ?? 0);

      if (userData['defaultVehicle'] != null) {
        await prefs.setInt('default_vid', userData['defaultVehicle']['vid']);
        // Poora object string bana kar save karo taake MyVehicles mein foran dikhay
        await prefs.setString('default_vehicle_data', jsonEncode(userData['defaultVehicle']));
      } else {
        await prefs.remove('default_vid');
        await prefs.remove('default_vehicle_data');
      }

      // 2. ExpertID sirf tab save hogi jab admin/user NA HO (Crash se bachne ke liye)
      if (userData['expertId'] != null) {
        await prefs.setInt('expertId', userData['expertId']);
      } else {
        await prefs.remove('expertId'); // Agar pehle se koi kachra hai to saaf
      }

      // 3. Picture string handle ho gayi
      await prefs.setString('saved_upicture', userData['upicture'] ?? "");

      String role = userData['type'].toString().toLowerCase();

      if (role == "admin") {
        String username = userData['username'] ?? "Admin";

        // Yahan AdminScreen ko call karo, vehicle screen ko nahi
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminScreen(adminName: username), // Dashboard wali class
          ),
        );
      }

      else if (role == "expert") {
        // Expert ID dynamic uthayi
        int eid = userData['expertId'] ?? userData['eid'] ?? userData['uid'] ?? 0;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ExpertHomeScreen(expertId: eid)),
        );
      } // LoginScreen mein 'user' role wali condition update karo:
      else if (role == "user") {
        // Navigator.pushReplacementNamed use karo
        Navigator.pushReplacementNamed(context, AppRoutes.user);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Login Failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(35),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text("Welcome", style: TextStyle(fontSize: 40, color: Color.fromARGB(255, 5, 54, 97), fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(controller: usernameController, decoration: InputDecoration(hintText: " Enter username", prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: isPasswordHidden,
                decoration: InputDecoration(
                  hintText: " Enter Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(icon: Icon(isPasswordHidden ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  //Expanded(child: ElevatedButton(onPressed: _handleLogin, style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 7, 2, 39), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text("Login", style: TextStyle(color: Colors.white)))),

                  Expanded(child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.welcome), style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 143, 143, 143), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text("Cancel", style: TextStyle(color: Colors.white)))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(onPressed: _handleLogin, style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 7, 2, 39), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text("Login", style: TextStyle(color: Colors.white)))),

                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}