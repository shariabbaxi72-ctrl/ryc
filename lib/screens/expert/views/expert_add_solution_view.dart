import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';

class ExpertAddSolutionView extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onBack;
  final int currentExpertId;

  const ExpertAddSolutionView({super.key, required this.onSave, required this.onBack, required this.currentExpertId});

  @override
  State<ExpertAddSolutionView> createState() => _ExpertAddSolutionViewState();
}

class _ExpertAddSolutionViewState extends State<ExpertAddSolutionView> {
  String expertise = "Electrical";
  final TextEditingController titleController = TextEditingController();
  List<Map<String, dynamic>> stepsList = [{"controller": TextEditingController(), "image": null}];
  final ImagePicker _picker = ImagePicker();

  List<dynamic> allVehicles = [];
  List<String> makes = [];
  List<String> models = [];
  List<String> years = [];
  List<dynamic> variants = [];
  List<dynamic> allProblems = [];
  List<dynamic> filteredProblems = [];

  String? sMake, sModel, sYear;
  dynamic sVariant, sProblem;
  int? selectedVid;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    var vehicleData = await ApiService.fetchAllVehicles();
    if (vehicleData.isNotEmpty) {
      setState(() {
        allVehicles = vehicleData;
        makes = allVehicles.where((e) => e['make'] != null).map((e) => e['make'].toString()).toSet().toList();
      });
    }
    var problemData = await ApiService.fetchAllProblems();
    setState(() {
      allProblems = problemData;
      _applyLocalFilter();
    });
  }

  void _applyLocalFilter() {
    setState(() {
      filteredProblems = allProblems.where((p) {
        // Updated mapping to match your C# API response
        String typeFromApi = (p['ptype'] ?? p['problemType'] ?? "").toString().toLowerCase().trim();
        return typeFromApi == expertise.toLowerCase().trim();
      }).toList();
      sProblem = null;
    });
  }

  void _handleSave() async {
    if (selectedVid == null || sProblem == null || titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all details!")));
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    bool success = await ApiService.uploadExpertSolution(
      expertId: widget.currentExpertId,
      vid: selectedVid!,
      pid: sProblem['pid'], // Using 'pid' from your C# controller
      title: titleController.text.trim(),
      steps: stepsList,
    );

    Navigator.pop(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solution Saved Successfully!"), backgroundColor: Colors.green));
      widget.onSave();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save. Check Console."), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Text("Add New Solution", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _carDropdowns(),
        _radioSelection(),
        // Problem Dropdown Fix
        _dropdownBox(filteredProblems.isEmpty ? "No problem found" : "Select Problem", filteredProblems, (val) => setState(() => sProblem = val), sProblem),
        const Align(alignment: Alignment.centerLeft, child: Text("Solution Title", style: TextStyle(fontWeight: FontWeight.bold))),
        _solutionTitleField(),
        const SizedBox(height: 25),
        ...stepsList.asMap().entries.map((entry) => _stepCard(entry.key)).toList(),
        _addStepButton(),
        const SizedBox(height: 30),
        _actionButtons(),
      ]),
    );
  }

  // --- Helper UI Widgets ---
  Widget _carDropdowns() {
    return Column(children: [
      Row(children: [
        Expanded(child: _dropdownBox("Make", makes, (v) => setState(() {
          sMake = v; sModel = null; sYear = null; sVariant = null;
          models = allVehicles.where((e) => e['make'] == v).map((e) => e['model'].toString()).toSet().toList();
        }), sMake)),
        const SizedBox(width: 10),
        Expanded(child: _dropdownBox("Model", models, (v) => setState(() {
          sModel = v; sYear = null; sVariant = null;
          years = allVehicles.where((e) => e['make'] == sMake && e['model'] == v).map((e) => e['year'].toString()).toSet().toList();
        }), sModel)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _dropdownBox("Year", years, (v) => setState(() {
          sYear = v; sVariant = null;
          variants = allVehicles.where((e) => e['make'] == sMake && e['model'] == sModel && e['year'].toString() == v).toList();
        }), sYear)),
        const SizedBox(width: 10),
        Expanded(child: _dropdownBox("Variant", variants, (v) => setState(() { sVariant = v; selectedVid = v['vid']; }), sVariant)),
      ]),
    ]);
  }

  Widget _dropdownBox(String hint, List<dynamic> items, Function(dynamic) onChange, dynamic currentVal) {
    bool valueExists = items.contains(currentVal);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10), margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(5)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          isExpanded: true, hint: Text(hint), value: valueExists ? currentVal : null,
          onChanged: (v) => onChange(v),
          items: items.map((e) {
            // --- FIX: Map keys properly to show text ---
            String displayText = "";
            if (e is Map) {
              // Check for vehicle variant, problem title (ptitle), or general title
              displayText = (e['variant'] ?? e['ptitle'] ?? e['title'] ?? "").toString();
            } else {
              displayText = e.toString();
            }

            return DropdownMenuItem(
              value: e,
              child: Text(displayText, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _radioSelection() => Row(children: [Radio(value: "Electrical", groupValue: expertise, onChanged: (v) { setState(() => expertise = v!); _applyLocalFilter(); }), const Text("Electrical"), const SizedBox(width: 20), Radio(value: "Mechanical", groupValue: expertise, onChanged: (v) { setState(() => expertise = v!); _applyLocalFilter(); }), const Text("Mechanical")]);
  Widget _solutionTitleField() => Container(padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(5)), child: TextField(controller: titleController, decoration: const InputDecoration(hintText: "Add solution title", border: InputBorder.none)));
  Widget _stepCard(int index) => Container(margin: const EdgeInsets.symmetric(vertical: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Step ${index + 1}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)), TextField(controller: stepsList[index]["controller"], decoration: const InputDecoration(hintText: "Explain step...", border: InputBorder.none)), if (stepsList[index]["image"] != null) Image.file(stepsList[index]["image"]!, height: 120, width: double.infinity, fit: BoxFit.cover), _pickImageButton(index)]));
  Widget _pickImageButton(int index) => ElevatedButton.icon(onPressed: () => _pickImage(index), icon: const Icon(Icons.camera_alt, size: 16), label: const Text("Select Image"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A5C7A), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 36)));
  Widget _addStepButton() => TextButton.icon(onPressed: () => setState(() => stepsList.add({"controller": TextEditingController(), "image": null})), icon: const Icon(Icons.add), label: const Text("Add Step"), style: TextButton.styleFrom(backgroundColor: Colors.grey.shade100, minimumSize: const Size(double.infinity, 40)));
  Widget _actionButtons() => Row(children: [Expanded(child: OutlinedButton(onPressed: widget.onBack, child: const Text("Back"))), const SizedBox(width: 15), Expanded(child: ElevatedButton(onPressed: _handleSave, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2E4B)), child: const Text("Save", style: TextStyle(color: Colors.white))))]);

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => stepsList[index]["image"] = File(image.path));
  }
}