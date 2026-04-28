import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ryc/services/api_service.dart';

class ProfileView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onUpdateSuccess;

  const ProfileView({super.key, required this.onBack, required this.onUpdateSuccess});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController(); // Added Confirm Pass

  File? _imageFile;
  String? _networkImage;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // Profile data fetch karne ka function
  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    int uid = prefs.getInt('userId') ?? 0;

    final data = await ApiService.getUserProfile(uid);
    if (mounted && data != null) {
      setState(() {
        _nameController.text = data['username'] ?? "";
        _networkImage = data['upicture'];
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username cannot be empty!")));
      return;
    }

    // Password Match Check
    if (_newPassController.text.isNotEmpty && (_newPassController.text != _confirmPassController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New Passwords don't match!")));
      return;
    }

    // Security Check
    if (_oldPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter old password to confirm changes")));
      return;
    }

    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    int uid = prefs.getInt('userId') ?? 0;

    final success = await ApiService.updateProfile(
      uid: uid,
      username: _nameController.text,
      oldPass: _oldPassController.text,
      newPass: _newPassController.text,
      image: _imageFile,
    );

    if (mounted) {
      if (success) {
        // 🔥 UPDATE KE BAAD DATA DUBARA LOAD KAREIN (Expert Logic)
        await _fetchProfile();

        setState(() {
          _isSaving = false;
          _imageFile = null; // Gallery pick reset karein taake server wali nayi pic dikhe
          _oldPassController.clear();
          _newPassController.clear();
          _confirmPassController.clear();
        });

        await prefs.setString('username', _nameController.text);
        widget.onUpdateSuccess();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated Successfully!")));
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update failed! Check old password.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Profile Picture
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_networkImage != null && _networkImage!.isNotEmpty)
                      ? NetworkImage(ApiService.getFullImageUrl(_networkImage)) as ImageProvider
                      : null,
                  child: (_imageFile == null && (_networkImage == null || _networkImage!.isEmpty))
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
                GestureDetector(
                  onTap: _pickImage,
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF1B2E4B),
                    child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            _buildField("Username", _nameController, false),
            const SizedBox(height: 20),
            _buildField("Old Password *", _oldPassController, true),
            const SizedBox(height: 15),
            _buildField("New Password", _newPassController, true),
            const SizedBox(height: 15),
            _buildField("Confirm New Password", _confirmPassController, true),

            const SizedBox(height: 40),

            // --- SAVE CHANGES BUTTON ---
            ElevatedButton(
              onPressed: _isSaving ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B2E4B), // Dark Blue
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Changes",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 15), // Thora sa gap dono buttons ke darmiyan

            // --- BACK TO DASHBOARD BUTTON ---
            ElevatedButton(
              onPressed: () => widget.onBack(), // Dashboard par wapis bhejne ke liye
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200, // Light color taake secondary button lage
                foregroundColor: const Color(0xFF1B2E4B), // Text color dark blue
                minimumSize: const Size(double.infinity, 55), // Same size as Save button
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0, // Flat design
              ),
              child: const Text("Back to Dashboard",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, bool isPass) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        obscureText: isPass,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        ),
      ),
    ],
  );
}