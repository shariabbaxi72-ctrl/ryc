import 'package:flutter/material.dart';
import 'package:ryc/screens/user/view/add_car_view.dart';
import 'package:ryc/screens/user/view/profile_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ryc/services/api_service.dart';
import 'view/dashboard_view.dart';
import 'view/my_vehicles_view.dart';
import 'view/expert_solutions_view.dart';
import 'view/solution_detail_view.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  List<Map<String, dynamic>> dbProblems = []; // Yeh list problems store karegi
  int _currentView = 0;
  String? selectedCar;
  String? selectedProblem;
  Map<String, String>? selectedSolutionData;
  String userName = "User";
  String? userPicture;
  bool _showProfileIcon = true; // <--- Naya variable control karne ke liye

  List<Map<String, dynamic>> myCars = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchVehicles();
    _fetchProblems();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('username') ?? "User";
      userPicture = prefs.getString('userPicture'); // upicture path

      // Login ke waqt agar default vehicle save hui thi, to uska ID uthao
      // Agar nahi hai, to null hi rahega (hardcode nahi)
      int? defaultId = prefs.getInt('default_vid');
      if (defaultId != null) {
        selectedCar = defaultId.toString();
      }
    });
    int uid = prefs.getInt('userId') ?? 0;
    if(uid != 0) {
      final profile = await ApiService.getUserProfile(uid);
      if (profile != null && mounted) {
        setState(() {
          userName = profile['username'] ?? userName;
          userPicture = profile['upicture']; // C# controller se 'upicture' aa raha hai
        });
        // Save for next time
        await prefs.setString('username', userName);
        if(userPicture != null) await prefs.setString('userPicture', userPicture!);
      }
    }
  }

  // --- IS CODE KO ADD KAREIN ---
  Future<void> refreshAllData() async {
    // 1. Pehle user ka naya default_vid uthao (SharedPrefs se)
    final prefs = await SharedPreferences.getInstance();

    // 2. API se naya profile data mangwao taake default car update ho
    int uid = prefs.getInt('userId') ?? 0;
    final profile = await ApiService.getUserProfile(uid);

    if (profile != null && profile['default_vid'] != null) {
      await prefs.setInt('default_vid', profile['default_vid']);
    }

    // 3. Purane fetch functions ko dobara call karein
    await _loadUserData(); // Ye selectedCar (default) ko update karega
    await _fetchVehicles(); // Ye list ko update karega
    await _fetchProblems();
  }
// -----------------------------




  Future<void> _fetchVehicles() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.fetchAllVehicles();
      setState(() {
        myCars = List<Map<String, dynamic>>.from(data);

        // Dynamic Check:
        // Agar selectedCar (jo humne prefs se li) list mein mojood hai to sahi,
        // warna selectedCar ko null rakho (dropdown khali dikhaye ga)
        bool exists = myCars.any((c) => c['vid'].toString() == selectedCar);
        if (!exists) {
          selectedCar = null;
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error loading: $e");
    }
  }
  List<Map<String, dynamic>> allProblems = []; // Yeh list class level pe define kar lo

  Future<void> _fetchProblems() async {
    try {
      // Apni API service ka function call karo
      final data = await ApiService.fetchAllProblems();
      setState(() {
        allProblems = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      print("Error loading problems: $e");
    }
  }

  // YE HAI WO LOGIC JO LIST KO UPDATE KAREGA (Duplicates & Default Check)
  void _handleCarAdded(Map<String, dynamic> newCar, bool isDefault) {
    setState(() {
      if (isDefault) {
        selectedCar = newCar['vid'].toString(); // UI Dropdown update
        // Purani cars se default status hatao
        for (var car in myCars) car['isDefault'] = false;
      }

      // List mein check karo agar pehle se hai to update, warna add
      int index = myCars.indexWhere((c) => c['vid'] == newCar['vid']);
      if (index != -1) {
        myCars[index] = {...newCar, 'isDefault': isDefault};
      } else {
        myCars.add({...newCar, 'isDefault': isDefault});
      }

      _currentView = 1; // My Vehicles View par le jao
    });
  }


  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/welcome');
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(_getTitle(), style: const TextStyle(color: Colors.black)),
        actions: _currentView == 5 ? []: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: () => setState(() => _currentView = 5),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF1B2E4B),
                backgroundImage: (userPicture != null && userPicture!.isNotEmpty)
                    ? NetworkImage(ApiService.getFullImageUrl(userPicture)) as ImageProvider
                    : null,
                child: (userPicture == null || userPicture!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const SizedBox(height: 60),
            _drawerTile(Icons.directions_car_outlined, "My Vehicle", () {
              setState(() => _currentView = 1);
              Navigator.pop(context);
            }),
            _drawerTile(Icons.car_repair_rounded, "Choose Car", () {
              setState(() => _currentView = 2);
              Navigator.pop(context);
            }),
            const Spacer(),
            _drawerTile(Icons.logout, "Logout", _showLogoutDialog),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : _buildBody(),
    );
  }

  String _getTitle() {
    if (_currentView == 0) return "Welcome\n $userName";
    if (_currentView == 1) return "My Vehicles";
    if (_currentView == 2) return "Choose Car";
    if (_currentView == 3) return "Expert Solutions";
    if (_currentView == 5) return "My Profile"; // <--- YE ADD KAREIN
    return "Solution Detail";
  }


  Widget _buildBody() {
    switch (_currentView) {
      case 1:
      // Ab MyVehiclesView ko myCars list ki zaroorat nahi, wo dummy dikhayega
        return MyVehiclesView(onBack: () => setState(() => _currentView = 0));
      case 2:
        return ChooseCarView(
          // onDone: _handleCarAdded,  <-- Is line ko delete kar do ya comment kar do
          onBack: () {
            setState(() => _currentView = 0); // Back dabane pe dashboard pe wapas
            // Agar tum chahity ho ke back aate hi data refresh ho, to yahan refresh function call kar lo
          },
        );
      case 3:
      // 1. Dropdown se aayi hui 'selectedCar' (ID) ko use karke list mein se poora object nikalna
        final car = myCars.firstWhere(
                (c) => c['vid'].toString() == selectedCar.toString(),
            orElse: () => {'make': 'Unknown', 'model': '', 'variant': '', 'year': ''}
        );

        // 2. Full Name construct karna (Make + Model + Variant)
        String fullCarName = "${car['make']} ${car['model']} ${car['variant']} (${car['year']})";

        // 3. ID ko integer mein convert karna (Database query ke liye)
        int vid = int.tryParse(selectedCar ?? "0") ?? 0;

        // Problem ID ke liye: Aapka dropdown list of objects hai, yahan humein problem ka ID chahiye
        // Agar 'selectedProblem' problem ka Title hai, toh humein 'allProblems' list se uski 'pid' dhoondni hogi
        final prob = allProblems.firstWhere(
                (p) => p['ptitle'] == selectedProblem,
            orElse: () => {'pid': 0}
        );
        int pid = prob['pid'] ?? 0;


        return ExpertSolutionsView(
            vid: vid,
            pid: pid,
            selectedCar: fullCarName, // Yahan full name ja raha hai
            selectedProblem: selectedProblem ?? "Not Selected",
            onSelect: (data) => setState(() {
              // Data ko convert karke save karna taake detail view mein use ho
              selectedSolutionData = Map<String, String>.from(data.map((key, value) => MapEntry(key, value.toString())));
              _currentView = 4;
            }),
            onBack: () => setState(() => _currentView = 0)
        );

    // Case 4 ko update karein:
      case 4:
      // 1. Car ka poora naam
        final car = myCars.firstWhere(
                (c) => c['vid'].toString() == selectedCar.toString(),
            orElse: () => {'make': 'Unknown', 'model': '', 'variant': '', 'year': ''}
        );
        String fullName = "${car['make'] ?? ''} ${car['model'] ?? ''} ${car['variant'] ?? ''} (${car['year'] ?? ''})";

        // 2. Yahan 'expertName' ko selectedSolutionData se extract karo
        String expertName = selectedSolutionData?['expertName'] ?? "Unknown Expert";

        return SolutionDetailView(
            sid: int.tryParse(selectedSolutionData?['sid']?.toString() ?? "0") ?? 0,
            selectedCar: fullName,
            selectedProblem: selectedProblem,
            expertName: expertName, // <--- YE BHEJNA ZAROORI THA!
            onFinish: () => setState(() => _currentView = 3)
        );
      case 5:
        return ProfileView(
          onBack: () => setState(() => _currentView = 0),
          onUpdateSuccess: refreshAllData, // Profile update ho to dashboard refresh ho jaye
        );

      default: return DashboardView(
        myCars: myCars,
        allProblems: allProblems, // Yahan wo list bhej di
        selectedCar: selectedCar,
        selectedProblem: selectedProblem,
        onCarChanged: (v) => setState(() => selectedCar = v),
        onProblemChanged: (v) => setState(() => selectedProblem = v),
        onRefresh: refreshAllData,
        onFindExpert: () {
          // Yahan check karein ke kya ID se naam nikal sakte hain?
          // Agar selectedCar ek ID hai, toh myCars list se uska naam dhoondein:
          final car = myCars.firstWhere((c) => c['vid'].toString() == selectedCar, orElse: () => {});

          setState(() {
            _currentView = 3; // Ye ExpertSolutionsView ko trigger karega
          });
        },
      );
    }

  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap) => ListTile(
    leading: Icon(icon), title: Text(title), onTap: onTap,
  );
}