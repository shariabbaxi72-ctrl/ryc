import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';

class ExpertProfileView extends StatefulWidget {
  final VoidCallback onBack;
  const ExpertProfileView({super.key, required this.onBack});

  @override
  State<ExpertProfileView> createState() => _ExpertProfileViewState();
}

class _ExpertProfileViewState extends State<ExpertProfileView> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController oldPassController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  // Visibility states for eye icons
  bool isOldHidden = true;
  bool isNewHidden = true;
  bool isConfirmHidden = true;

  bool isElectrical = true;
  bool isMechanical = false;
  bool isLoading = false;

  File? _image;
  final ImagePicker _picker = ImagePicker();
  String? imgUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {

    setState(() => isLoading = true);

    var profile = await ApiService.getExpertProfile();

    if (mounted) {
      setState(() {
        if (profile != null) {
          userController.text = profile['username'] ?? "";
          imgUrl = profile['upicture'];
          String cat = profile['category'] ?? "Electrical";
          isMechanical = (cat == "Mechanical");
          isElectrical = !isMechanical;
        }
        isLoading = false;
      });

    }
  }

  Future<void> _updateProfile() async {
    if (newPassController.text != confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New Passwords don't match!")));
      return;
    }

    if (oldPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter old password to update!")));
      return;
    }

    setState(() => isLoading = true);

    Map<String, dynamic> data = {
      "username": userController.text,
      "oldPass": oldPassController.text,
      "newPass": newPassController.text,
      "category": isElectrical ? "Electrical" : "Mechanical",
    };

    bool success = await ApiService.updateExpertProfile(data, _image);

    if (mounted) {
      if (success) {
        // 🔥 UPDATE KE BAAD DATA DUBARA LOAD KAREIN
        await _loadProfileData();

        setState(() {
          isLoading = false;
          _image = null; // Gallery selection clear karein taake server wali pic dikhe
          oldPassController.clear();
          newPassController.clear();
          confirmPassController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated Successfully!")));
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Update failed! Check password.")));
      }
    }
  }
  @override
// ... baqi imports wahi rahenge

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Scaffold wrap kiya taake layout set rahe
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Back Button

            const SizedBox(height: 20),

            // Profile Image (Decorated)
            Center(
              child: GestureDetector(
                onTap: () async {
                  final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
                  if (file != null) setState(() => _image = File(file.path));
                },
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _image != null
                      ? FileImage(_image!) // Agar gallery se pick ki
                      : (imgUrl != null && imgUrl!.isNotEmpty)
                      ? NetworkImage(ApiService.getFullImageUrl(imgUrl)) as ImageProvider // Server wali pic
                      : null,
                  child: (_image == null && (imgUrl == null || imgUrl!.isEmpty))
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Inputs (Decoration ke sath)
            _buildLabel("Username"),
            _buildInput(userController, false, null),

            const SizedBox(height: 15),
            _buildLabel("Old Password"),
            _buildInput(oldPassController, true, isOldHidden),

            const SizedBox(height: 15),
            _buildLabel("New Password"),
            _buildInput(newPassController, true, isNewHidden),

            const SizedBox(height: 15),
            _buildLabel("Confirm Password"),
            _buildInput(confirmPassController, true, isConfirmHidden),

            const SizedBox(height: 20),
            const Text("Select Category:", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Radio<bool>(value: true, groupValue: isElectrical, onChanged: (v) => setState(() { isElectrical = true; isMechanical = false; })),
                const Text("Electrical"),
                Radio<bool>(value: false, groupValue: isElectrical, onChanged: (v) => setState(() { isElectrical = false; isMechanical = true; })),
                const Text("Mechanical"),
              ],
            ),

            const SizedBox(height: 30),

            // Buttons Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onBack,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black, minimumSize: const Size(0, 50)),
                    child: const Text("Back"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
                    child: const Text("Update Profile"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
// ... baki _buildInput wahi rahenge

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)));

  Widget _buildInput(TextEditingController controller, bool isPass, bool? isHidden) {
    return TextFormField(
      controller: controller,
      obscureText: isPass ? isHidden! : false,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        suffixIcon: isPass ? IconButton(icon: Icon(isHidden! ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() {
          if (controller == oldPassController) isOldHidden = !isOldHidden;
          else if (controller == newPassController) isNewHidden = !isNewHidden;
          else isConfirmHidden = !isConfirmHidden;
        })) : null,
      ),
    );
  }
}