import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

class ChooseCarView extends StatefulWidget {
  final VoidCallback onBack;
  const ChooseCarView({super.key, required this.onBack});

  @override
  State<ChooseCarView> createState() => _ChooseCarViewState();
}

class _ChooseCarViewState extends State<ChooseCarView> {
  List<dynamic> allVehicles = [];
  List<String> makes = [], models = [], variants = [], years = [];
  String? sMake, sModel, sVariant, sYear;
  bool isDefaultChecked = false;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      List<dynamic> data = await ApiService.fetchAllVehicles();
      if (data.isNotEmpty) {
        setState(() {
          allVehicles = data;
          makes = data.map((e) => e['make'].toString()).toSet().toList()..sort();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // handleDone function ka updated hissa
  Future<void> handleDone() async {
    if (sMake == null || sModel == null || sVariant == null || sYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select all fields")));
      return;
    }

    final selectedV = allVehicles.firstWhere((e) =>
    e['make'] == sMake && e['model'] == sModel &&
        e['variant'] == sVariant && e['year'].toString() == sYear);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int uid = prefs.getInt('userId') ?? 0;

    setState(() => isSaving = true);

    if (isDefaultChecked) {
      bool success = await ApiService.addUserVehicle(uid: uid, vid: selectedV['vid'], isDefault: true);
      if (success) {
        await prefs.setInt('default_vid', selectedV['vid']);
        await _saveToLocal(selectedV, uid); // Pass UID
        widget.onBack();
      } else {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Server Error")));
      }
    } else {
      await _saveToLocal(selectedV, uid); // Pass UID
      widget.onBack();
    }
  }

  Future<void> _saveToLocal(dynamic vehicle, int uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userSpecificKey = 'my_local_cars_$uid'; // USER SPECIFIC KEY
    String existingJson = prefs.getString(userSpecificKey) ?? "[]";
    List<dynamic> localCars = jsonDecode(existingJson);

    bool alreadyExists = localCars.any((c) => c['vid'] == vehicle['vid']);
    if (!alreadyExists) {
      localCars.add(vehicle);
      await prefs.setString(userSpecificKey, jsonEncode(localCars));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      /*appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: widget.onBack),
        title: const Text("Choose Car", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),*/

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B2E4B)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _formDropdown("Make", makes, sMake, (v) => setState(() { sMake = v; sModel = sVariant = sYear = null; models = allVehicles.where((e) => e['make'] == v).map((e) => e['model'].toString()).toSet().toList()..sort(); })),
            _formDropdown("Model", models, sModel, (v) => setState(() { sModel = v; sVariant = sYear = null; variants = allVehicles.where((e) => e['make'] == sMake && e['model'] == v).map((e) => e['variant'].toString()).toSet().toList()..sort(); })),
            _formDropdown("Variant", variants, sVariant, (v) => setState(() { sVariant = v; sYear = null; years = allVehicles.where((e) => e['make'] == sMake && e['model'] == sModel && e['variant'] == v).map((e) => e['year'].toString()).toSet().toList()..sort((a,b)=>b.compareTo(a)); })),
            _formDropdown("Year", years, sYear, (v) => setState(() => sYear = v)),
            Row(
              children: [
                Checkbox(
                    value: isDefaultChecked,
                    onChanged: (val) => setState(() => isDefaultChecked = val!),
                    activeColor: const Color(0xFF1B2E4B)
                ),
                const Text("Set as Default Car", style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: isSaving ? null : handleDone,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2E4B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Done", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formDropdown(String hint, List<String> items, String? val, Function(String?) onCh) => Container(
    margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: val, hint: Text(hint), isExpanded: true, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onCh)),
  );
}