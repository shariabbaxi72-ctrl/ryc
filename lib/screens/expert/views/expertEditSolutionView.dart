import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

class StepEditModel {
  int? stepId;
  int stepNo;
  TextEditingController descriptionController;
  String? existingImageUrl;
  File? newImageFile;

  StepEditModel({
    this.stepId,
    required this.stepNo,
    required String description,
    this.existingImageUrl,
  }) : descriptionController = TextEditingController(text: description);
}

class EditSolutionView extends StatefulWidget {
  final int sidToEdit;
  const EditSolutionView({super.key, required this.sidToEdit});

  @override
  State<EditSolutionView> createState() => _EditSolutionViewState();
}

class _EditSolutionViewState extends State<EditSolutionView> {
  final TextEditingController _titleController = TextEditingController();
  List<StepEditModel> steps = [];
  bool isLoading = true;
  bool isUpdating = false;
  String expertImgUrl = "";

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      expertImgUrl = prefs.getString('saved_upicture') ?? "";

      var data = await ApiService.fetchSolutionDetails(widget.sidToEdit);

      if (data != null) {
        setState(() {
          // Backend keys check karein: 'stitle' ya 'title'
          _titleController.text = data['solution']?['stitle'] ?? data['solution']?['title'] ?? "";
          var apiSteps = data['steps'] as List? ?? [];

          steps = apiSteps.map((s) => StepEditModel(
            // Backend labels: 'stepId' ya 'stepid'
            stepId: s['stepId'] ?? s['stepid'],
            stepNo: s['stepNo'] ?? s['stepno'] ?? 1,
            description: s['description'] ?? s['stepDescription'] ?? "",
            existingImageUrl: s['image'] ?? s['stepImg'],
          )).toList();
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> deleteStepLogic(int index) async {
    var step = steps[index];

    // Case 1: Agar step pehle se database mein hai (Purana Step)
    if (step.stepId != null && step.stepId != 0) {
      setState(() => isLoading = true);

      bool success = await ApiService.deleteStep(step.stepId!);

      if (success) {
        _removeAndReorderUI(index);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Step deleted from server")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete step")));
      }

      setState(() => isLoading = false);
    }
    // Case 2: Agar naya add kiya hua step hai (Abhi save nahi hua)
    else {
      _removeAndReorderUI(index);
    }
  }

  void _removeAndReorderUI(int index) {
    setState(() {
      steps.removeAt(index);
      // iOS ki tarah numbering reset karein
      for (int i = 0; i < steps.length; i++) {
        steps[i].stepNo = i + 1;
      }
    });
  }
  // --- MAIN UPDATE FUNCTION (SMART LOGIC) ---
  Future<void> updateEverything() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title is required")));
      return;
    }

    setState(() => isUpdating = true);

    try {
      // 1. Update Title (Backend API call)
      await ApiService.updateSolutionTitle(widget.sidToEdit, _titleController.text);

      // 2. Loop through steps
      for (int i = 0; i < steps.length; i++) {
        var step = steps[i];

        if (step.stepId != null && step.stepId != 0) {
          // --- CASE A: PURANA STEP UPDATE ---

          if (step.newImageFile != null) {
            // Expert ne Image badli hai (Yahi call description bhi update kar degi)
            await ApiService.updateStepImage(
              step.stepId!,
              step.newImageFile!,
              description: step.descriptionController.text,
              stepNo: i + 1,
            );
          } else {
            // Expert ne sirf description badli hai
            await ApiService.updateStep(
              stepId: step.stepId!,
              description: step.descriptionController.text,
              stepNo: i + 1,
            );
          }
        } else {
          // --- CASE B: NAYA STEP ADD (If Expert added a new step card) ---
          if (step.newImageFile != null) {
            await ApiService.uploadNewStep(
              sid: widget.sidToEdit,
              stepNo: i + 1,
              description: step.descriptionController.text,
              imageFile: step.newImageFile!,
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Solution updated successfully!")));
        Navigator.pop(context, true); // Dashboard ko batao ke refresh kare
      }
    } catch (e) {
      debugPrint("Update Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Something went wrong during update")));
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Solution"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: (expertImgUrl.isNotEmpty)
                  ? NetworkImage(ApiService.getFullImageUrl(expertImgUrl))
                  : null,
              child: expertImgUrl.isEmpty ? const Icon(Icons.person, color: Colors.blue) : null,
            ),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Solution Title",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 20),

            // Steps List Rendering
            ...steps.asMap().entries.map((entry) {
              int index = entry.key;
              StepEditModel step = entry.value;
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("STEP ${index + 1}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => deleteStepLogic(index), // Naya function call karein
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: step.descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: "What to do in this step?",
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Step Image UI
                      GestureDetector(
                        onTap: () async {
                          final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            setState(() => step.newImageFile = File(picked.path));
                          }
                        },
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: step.newImageFile != null
                                ? Image.file(step.newImageFile!, fit: BoxFit.cover)
                                : (step.existingImageUrl != null && step.existingImageUrl!.isNotEmpty
                                ? Image.network(
                              ApiService.getFullImageUrl(step.existingImageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image)),
                            )
                                : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                Text("Change Image", style: TextStyle(color: Colors.grey)),
                              ],
                            )),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  steps.add(StepEditModel(stepNo: steps.length + 1, description: ""));
                });
              },
              icon: const Icon(Icons.add),
              label: const Text("ADD ANOTHER STEP"),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isUpdating ? null : updateEverything,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.blueAccent,
              ),
              child: isUpdating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SAVE ALL CHANGES",
                  style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );

  }
}