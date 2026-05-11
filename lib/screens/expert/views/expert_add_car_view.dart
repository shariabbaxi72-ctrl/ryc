import 'package:flutter/material.dart';

import '../../../services/api_service.dart';

class ExpertAddCarView extends StatefulWidget {
  final bool isAdmin;
  final Function() onCarAdded;

  const ExpertAddCarView({super.key, required this.isAdmin, required this.onCarAdded});

  @override
  State<ExpertAddCarView> createState() => _ExpertAddCarViewState();
}


class _ExpertAddCarViewState extends State<ExpertAddCarView> {
  final TextEditingController makeCtrl = TextEditingController();
  final TextEditingController modelCtrl = TextEditingController();
  final TextEditingController variantCtrl = TextEditingController();
  final TextEditingController yearCtrl = TextEditingController();
  bool isSaving = false;

  // ExpertAddCarView.dart mein is function ko aise replace karein

  void _submit() async {
    if (makeCtrl.text.isEmpty || modelCtrl.text.isEmpty || yearCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All fields are required!")));
      return;
    }

    setState(() => isSaving = true);

    Map<String, dynamic> carData = {
      "vmake": makeCtrl.text.trim(),
      "vmodel": modelCtrl.text.trim(),
      "vvariant": variantCtrl.text.trim(),
      "vyear": int.tryParse(yearCtrl.text.trim()) ?? 0,
      // Yahan status text bhej rahe hain
      "vstatus": widget.isAdmin ? "Approved" : "pending",
    };

    bool success = await ApiService.addVehicle(carData);
    setState(() => isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vehicle saved!")));
      widget.onCarAdded();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fail to save car. Check server logs.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(widget.isAdmin ? "Add Vehicle" : "Add New Vehicle",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _inputBox("Make", "e.g. Suzuki", makeCtrl),
            const SizedBox(height: 15),
            _inputBox("Model", "e.g. Mehran", modelCtrl),
            const SizedBox(height: 15),
            _inputBox("Variant", "e.g. EURO II", variantCtrl),
            const SizedBox(height: 15),
            _inputBox("Year", "e.g. 2022", yearCtrl),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B2E4B),
                minimumSize: const Size(double.infinity, 45),
              ),
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.isAdmin ? "Add" : "Send Request", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBox(String label, String hint, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label, hintText: hint, border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
    );
  }
}