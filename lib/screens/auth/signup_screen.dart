import 'package:flutter/material.dart';
import 'package:ryc/routes/routes.dart';
import 'package:ryc/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String selectedRole = "User";
  bool isPasswordHidden = true;
  bool isConfirmHidden = true;
  bool isElectrical = false;
  bool isMechanical = false;

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmController = TextEditingController();

  // --- Register API Integration ---
  void _handleRegister() async {
    String name = usernameController.text.trim();
    String pass = passwordController.text.trim();
    String confirm = confirmController.text.trim();

    // 1. Validations
    if (name.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showSnackBar("All fields required");
      return;
    }
    if (pass != confirm) {
      _showSnackBar("Passwords do not match");
      return;
    }
    if (pass.length < 6) {
      _showSnackBar("Password must be 6 characters");
      return;
    }
    if (selectedRole == "Expert" && !isElectrical && !isMechanical) {
      _showSnackBar("Select at least one expertise");
      return;
    }

    // 2. Expert Category Logic
    String? category;
    if (selectedRole == "Expert") {
      category = isElectrical && isMechanical ? "Both" : (isElectrical ? "Electrical" : "Mechanical");
    }

    // 3. Loading Indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 4. Call API
    var result = await AuthService.register(
      username: name,
      password: pass,
      type: selectedRole,
      category: category,
    );

    if (mounted) Navigator.pop(context); // Close loading

    // 5. Response Handle
    if (result['status'] == "success") {
      _showSnackBar("Register Success! Please Login");
      Navigator.pushNamed(context, AppRoutes.login);
    } else {
      _showSnackBar(result['message']);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.welcome),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text("Welcome", style: TextStyle(fontSize: 40, color: Color.fromARGB(255, 1, 44, 78), fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(hintText: "username", prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: isPasswordHidden,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(icon: Icon(isPasswordHidden ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: confirmController,
                obscureText: isConfirmHidden,
                decoration: InputDecoration(
                  hintText: "Confirm password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(icon: Icon(isConfirmHidden ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => isConfirmHidden = !isConfirmHidden)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<String>(value: "User", groupValue: selectedRole, onChanged: (value) => setState(() => selectedRole = value!)),
                  const Text("User"),
                  Radio<String>(value: "Expert", groupValue: selectedRole, onChanged: (value) => setState(() => selectedRole = value!)),
                  const Text("Expert"),
                ],
              ),
              if (selectedRole == "Expert") ...[
                CheckboxListTile(title: const Text("Electrical"), value: isElectrical, onChanged: (value) => setState(() => isElectrical = value!)),
                CheckboxListTile(title: const Text("Mechanical"), value: isMechanical, onChanged: (value) => setState(() => isMechanical = value!)),
              ],
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45), backgroundColor: const Color.fromARGB(255, 7, 2, 39), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                child: const Text("Register", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}