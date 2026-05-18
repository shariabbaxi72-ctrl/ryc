import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import '../admin/admin_problem_screen.dart';
import 'views/expert_dashboard_view.dart';
import 'views/expert_add_car_view.dart';
import 'views/expert_profile_view.dart';
import 'views/expert_add_solution_view.dart';

class ExpertHomeScreen extends StatefulWidget {
  final int expertId;
  const ExpertHomeScreen({super.key, required this.expertId});

  @override
  State<ExpertHomeScreen> createState() => _ExpertHomeScreenState();
}


class _ExpertHomeScreenState extends State<ExpertHomeScreen> {
  int currentScreen = 0;
  String? savedPicPath = "";


  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        savedPicPath = prefs.getString('saved_upicture') ?? "";
      });
    }
  }
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            // 1. NO Button: Sirf dialog band karega
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No"),
            ),
            // 2. YES Button: Dialog band karke Welcome screen pe le jayega
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context); // Dialog band karo
                Navigator.pushReplacementNamed(context, '/welcome'); // Screen change karo
              },
              child: const Text("Yes", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  Widget _buildBody() {
    switch (currentScreen) {
      case 0:
        return ExpertDashboardView(

          onAddSolution: () => setState(() => currentScreen = 1),
          onProfileLoaded: _loadSavedImage,
        );
      case 1:
        return ExpertAddSolutionView(
          onSave: () => setState(() => currentScreen = 0),
          onBack: () => setState(() => currentScreen = 0),
          currentExpertId: widget.expertId,
        );
      case 2: return ExpertAddCarView(isAdmin: false, onCarAdded: () => setState(() => currentScreen = 0));
      case 3: return ExpertProfileView(onBack: () {
        _loadSavedImage();
        setState(() => currentScreen = 0);
      });
      case 4:
        return AdminProblemScreen(
          adminName: "Expert User",
          isAdmin: false,
        );
      default:
        return ExpertDashboardView(
          key: UniqueKey(),
          onAddSolution: () => setState(() => currentScreen = 1),
          onProfileLoaded: _loadSavedImage,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white, elevation: 0,
          title: const Text("Expert Dashboard", style: TextStyle(color: Colors.black)),
          leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () => Scaffold.of(context).openDrawer())),
          actions:currentScreen == 3 ? [] : [
            IconButton(
                onPressed: () => setState(() => currentScreen = 3),
                icon: CircleAvatar(
                  backgroundColor: const Color(0xFF1B2E4B),
                  backgroundImage: (savedPicPath != null && savedPicPath!.isNotEmpty)
                      ? NetworkImage(ApiService.getFullImageUrl(savedPicPath!))
                      : null,
                  child: (savedPicPath == null || savedPicPath!.isEmpty)
                      ? const Icon(Icons.person, size: 20, color: Colors.white)
                      : null,
                )
            )
          ]
      ),
      drawer: Drawer(
        child: Column(children: [
          const SizedBox(height: 60),
          ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text("Add New Car"),
              onTap: () { setState(() => currentScreen = 2); Navigator.pop(context); }
          ),
          ListTile(
              leading: const Icon(Icons.report_problem),
              title: const Text("Add Problem"),
              onTap: () {
                setState(() => currentScreen = 4);
                Navigator.pop(context);
              }
          ),
          const Spacer(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout"),
            onTap: () {
              // Jab user click karega, pehle confirmation dialog khulega
              _showLogoutConfirmation(context);
            },
          ),
        ]),
      ),
      body: _buildBody(),
    );
  }
}
