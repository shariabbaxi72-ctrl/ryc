import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EditProblemScreen extends StatefulWidget {
  final Map<String, dynamic> problem;
  final Function onUpdate;

  EditProblemScreen({required this.problem, required this.onUpdate});

  @override
  _EditProblemScreenState createState() => _EditProblemScreenState();
}

class _EditProblemScreenState extends State<EditProblemScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _selectedPType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.problem['ptitle'] ?? "");
    _descController = TextEditingController(text: widget.problem['pdescription'] ?? "");
    _selectedPType = widget.problem['ptype']?.toString().toLowerCase() ?? "electrical";
  }

  // Common Input Decoration for consistency
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF001F3F)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF001F3F), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Problem", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF001F3F),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //const Text("Update Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
            const SizedBox(height: 25),


            // Title TextField
            TextField(
              controller: _titleController,
              decoration: _inputDecoration("Problem Title"),
            ),
            const SizedBox(height: 20),

            // Description TextField
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: _inputDecoration("Problem Description"),
            ),
            const SizedBox(height: 25),

            const Text("Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),

            // Radio Buttons - Fixed Alignment
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Radio<String>(
                  value: "electrical",
                  groupValue: _selectedPType,
                  activeColor: const Color(0xFF001F3F),
                  onChanged: (val) => setState(() => _selectedPType = val!),
                ),
                const Text("Electrical", style: TextStyle(fontSize: 15)),
                const SizedBox(width: 20),
                Radio<String>(
                  value: "mechanical",
                  groupValue: _selectedPType,
                  activeColor: const Color(0xFF001F3F),
                  onChanged: (val) => setState(() => _selectedPType = val!),
                ),
                const Text("Mechanical", style: TextStyle(fontSize: 15)),
              ],
            ),

            const SizedBox(height: 40),

            // Update Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F3F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
                onPressed: () async {
                  Map<String, dynamic> updatedData = Map.from(widget.problem);
                  updatedData['ptitle'] = _titleController.text.trim();
                  updatedData['pdescription'] = _descController.text.trim();
                  updatedData['ptype'] = _selectedPType;

                  if (updatedData['ptitle'].isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title cannot be empty!")));
                    return;
                  }

                  bool success = await ApiService.updateProblem(updatedData);
                  if (success) {
                    widget.onUpdate();
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update!")));
                  }
                },
                child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            )
          ],
        ),
      ),
    );
  }
}