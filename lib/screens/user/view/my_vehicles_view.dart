import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import 'add_car_view.dart'; // Iska path check kar lena (Add car ya Choose car)


class MyVehiclesView extends StatefulWidget {
  final VoidCallback onBack;
  const MyVehiclesView({super.key, required this.onBack});

  @override
  State<MyVehiclesView> createState() => _MyVehiclesViewState();
}

class _MyVehiclesViewState extends State<MyVehiclesView> {
  List<dynamic> userVehicles = [];
  bool isLoading = true;
  String defaultVid = "0";

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> loadAllData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int uid = prefs.getInt('userId') ?? 0;

    try {
      final profile = await ApiService.getUserProfile(uid);
      if (profile != null && profile['default_vid'] != null) {
        defaultVid = profile['default_vid'].toString();
        await prefs.setInt('default_vid', int.parse(defaultVid));
      } else {
        defaultVid = (prefs.getInt('default_vid') ?? 0).toString();
      }

      List<dynamic> apiVehicles = await ApiService.getUserVehicles(uid);
      String userSpecificKey = 'my_local_cars_$uid';
      String localJson = prefs.getString(userSpecificKey) ?? "[]";
      List<dynamic> localList = jsonDecode(localJson);

      Map<String, dynamic> uniqueMap = {};
      for (var v in apiVehicles) {
        uniqueMap[v['vid'].toString()] = v;
      }
      for (var v in localList) {
        uniqueMap[v['vid'].toString()] = v;
      }

      List<dynamic> finalList = uniqueMap.values.toList();

      finalList.sort((a, b) {
        if (a['vid'].toString() == defaultVid) return -1;
        if (b['vid'].toString() == defaultVid) return 1;
        return 0;
      });

      setState(() {
        userVehicles = finalList;
      });
    } catch (e) {
      debugPrint("Refresh Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: loadAllData,
        color: const Color(0xFF1B2E4B),
        child: isLoading && userVehicles.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B2E4B)))
            : ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          itemCount: userVehicles.length,
          separatorBuilder: (context, index) => Divider(color: Colors.grey.shade300, indent: 20, endIndent: 20),
          itemBuilder: (context, index) {
            final car = userVehicles[index];
            bool isDef = car['vid'].toString() == defaultVid;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${car['make']} ${car['model']} ${car['variant'] ?? ''} ${car['year']}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                  ),
                  if (isDef)
                    const Row(
                      children: [
                        SizedBox(width: 4),
                        Text("Default",
                            style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),

      // --- NAYA BUTTON SECTION ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: widget.onBack, // Dashboard pe wapis jane k liye
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B2E4B), // Wahi Blue shade
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              "Back To Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}