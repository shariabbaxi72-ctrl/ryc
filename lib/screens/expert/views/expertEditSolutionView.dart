
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
          _titleController.text = data['solution']?['stitle'] ?? data['solution']?['title'] ?? "";
          var apiSteps = data['steps'] as List? ?? [];

          steps = apiSteps.map((s) => StepEditModel(
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

  // --- Step Ratings View (Fix: Keys match iOS Logic) ---
  // --- Step Ratings View (Stars Fixed) ---
  void _showStepRatings(int stepId, int stepNo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ratings for Step $stepNo", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
                ],
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: ApiService.fetchStepRatings(stepId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No reviews for this step yet."));
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        var r = snapshot.data![index];

                        // Keys handling
                        String userName = (r['rname'] ?? r['userName'] ?? r['name'] ?? "User").toString();
                        String reviewText = (r['sreview'] ?? r['review'] ?? r['comment'] ?? "No comment").toString();

                        // Rating value ko double mein le rahay hain taake stars count kar sakein
                        double ratingValue = double.tryParse((r['srating'] ?? r['rating'] ?? r['stars'] ?? "0").toString()) ?? 0;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : "U", style: const TextStyle(color: Colors.blue)),
                            ),
                            title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 👇 Yahan Stars add kiye hain poore 5
                                // Row(
                                //   children: List.generate(5, (starIndex) {
                                //     return Icon(
                                //       starIndex < ratingValue ? Icons.star : Icons.star_border,
                                //       color: Colors.amber,
                                //       size: 16,
                                //     );
                                //   }),
                                // ),
                                const SizedBox(height: 4),
                                Text(reviewText),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> deleteStepLogic(int index) async {
    var step = steps[index];
    if (step.stepId != null && step.stepId != 0) {
      setState(() => isLoading = true);
      bool success = await ApiService.deleteStep(step.stepId!);
      if (success) {
        _removeAndReorderUI(index);
      }
      setState(() => isLoading = false);
    } else {
      _removeAndReorderUI(index);
    }
  }

  void _removeAndReorderUI(int index) {
    setState(() {
      steps.removeAt(index);
      for (int i = 0; i < steps.length; i++) {
        steps[i].stepNo = i + 1;
      }
    });
  }

  Future<void> updateEverything() async {
    if (_titleController.text.isEmpty) return;
    setState(() => isUpdating = true);
    try {
      await ApiService.updateSolutionTitle(widget.sidToEdit, _titleController.text);
      for (int i = 0; i < steps.length; i++) {
        var step = steps[i];
        if (step.stepId != null && step.stepId != 0) {
          if (step.newImageFile != null) {
            await ApiService.updateStepImage(step.stepId!, step.newImageFile!, description: step.descriptionController.text, stepNo: i + 1);
          } else {
            await ApiService.updateStep(stepId: step.stepId!, description: step.descriptionController.text, stepNo: i + 1);
          }
        } else {
          if (step.newImageFile != null) {
            await ApiService.uploadNewStep(sid: widget.sidToEdit, stepNo: i + 1, description: step.descriptionController.text, imageFile: step.newImageFile!);
          }
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Solution"),
        backgroundColor: const Color(0xFF1B2E4B),
        foregroundColor: Colors.white,
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Title")),
            const SizedBox(height: 20),
            ...steps.asMap().entries.map((entry) {
              int index = entry.key;
              StepEditModel step = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("STEP ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          // Row(
                          //   children: [
                          //     if (step.stepId != null && step.stepId != 0)
                          //       IconButton(icon: const Icon(Icons.star_border, color: Colors.blue), onPressed: () => _showStepRatings(step.stepId!, index + 1)),
                          //     IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => deleteStepLogic(index)),
                          //   ],
                          // )
                        ],
                      ),
                      TextField(controller: step.descriptionController),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (picked != null) setState(() => step.newImageFile = File(picked.path));
                        },
                        child: Container(
                          height: 150, width: double.infinity, color: Colors.grey[200],
                          child: step.newImageFile != null ? Image.file(step.newImageFile!, fit: BoxFit.cover) :
                          (step.existingImageUrl != null ? Image.network(ApiService.getFullImageUrl(step.existingImageUrl!), fit: BoxFit.cover) : const Icon(Icons.add_a_photo)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            TextButton(onPressed: () => setState(() => steps.add(StepEditModel(stepNo: steps.length + 1, description: ""))), child: const Text("ADD STEP")),
            ElevatedButton(onPressed: isUpdating ? null : updateEverything, child: const Text("SAVE CHANGES")),
          ],
        ),
      ),
    );
  }
}