/////orignal
// import 'package:flutter/material.dart';
// import '../../services/api_service.dart';
//
// class AdminExpertScreen extends StatefulWidget {
//   final String adminName;
//   const AdminExpertScreen({super.key, required this.adminName});
//
//   @override
//   State<AdminExpertScreen> createState() => _AdminExpertScreenState();
// }
//
// class _AdminExpertScreenState extends State<AdminExpertScreen> {
//   String currentSection = "Approved";
//   List<dynamic> expertsList = [];
//   bool isLoading = false;
//
//   TextEditingController nameController = TextEditingController();
//   TextEditingController passController = TextEditingController();
//   TextEditingController confirmController = TextEditingController();
//   bool electrical = false;
//   bool mechanical = false;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchExpertsData();
//   }
//
//   Future<void> fetchExpertsData() async {
//     if (currentSection == "Add") return;
//     setState(() => isLoading = true);
//     List<dynamic> data;
//     if (currentSection == "Approved") {
//       data = await ApiService.getApprovedExperts();
//     } else {
//       data = await ApiService.getPendingExperts();
//     }
//     setState(() {
//       expertsList = data;
//       isLoading = false;
//     });
//   }
//
//   // Pending list se expert ko reject/delete karne ke liye confirmation dialog
//   void confirmDelete(int uid) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Confirm Action"),
//         content: const Text("Are you sure you want to reject this expert?"),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               handleUserAction(uid, "delete"); // Pending tab se permanent delete karne ke liye
//             },
//             child: const Text("Yes, Delete", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void handleUserAction(int uid, String actionType) async {
//     setState(() => isLoading = true);
//     bool success = false;
//
//     if (actionType == "approve") {
//       // Pending Tab: Tick dabane par approve karega (IsActive = 1)
//       success = await ApiService.approveExpert(uid);
//       if (success) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Expert Approved Successfully!"), backgroundColor: Colors.green),
//           );
//         }
//       }
//     }
//     else if (actionType == "toggle_status") {
//       // ⭐ IOS FLOW FIXED: Approved Tab mein checkmark dabane par ApiService.deleteUser chalega
//       // Kyunke aapka C# backend delete route par IsActive status toggle karta hai!
//       success = await ApiService.deleteUser(uid);
//       if (success) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Status Toggled Successfully!"), backgroundColor: Colors.orange),
//           );
//         }
//       }
//     }
//     else if (actionType == "delete") {
//       // Pending Tab: Cross dabane par user database se remove ho jayega
//       success = await ApiService.deleteUser(uid);
//       if (success) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Expert Rejected successfully!"), backgroundColor: Colors.redAccent),
//           );
//         }
//       }
//     }
//
//     // Refresh data after operation
//     fetchExpertsData();
//   }
//
//   void saveExpertByAdmin() async {
//     if (passController.text != confirmController.text) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
//       return;
//     }
//     String category = electrical ? "Electrical" : "Mechanical";
//     bool ok = await ApiService.addExpertAdmin(nameController.text, passController.text, category);
//     if (ok) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Expert Added Successfully!")));
//       nameController.clear(); passController.clear(); confirmController.clear();
//       setState(() => currentSection = "Approved");
//       fetchExpertsData();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildHeader(),
//               const SizedBox(height: 25),
//               _buildTabsRow(),
//               const SizedBox(height: 25),
//               Expanded(
//                 child: isLoading
//                     ? const Center(child: CircularProgressIndicator())
//                     : (currentSection == "Add" ? _showAddForm() : _showExpertList()),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20), onPressed: () => Navigator.pop(context)),
//             const Text('Welcome', style: TextStyle(fontSize: 28, fontWeight: FontWeight.normal, color: Color(0xFF001F3F))),
//           ],
//         ),
//         Padding(
//           padding: const EdgeInsets.only(left: 45),
//           child: Text(widget.adminName, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTabsRow() {
//     return Container(
//       decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
//       child: Row(
//         children: [_myTab("Approved"), _myTab("Pending"), _myTab("Add")],
//       ),
//     );
//   }
//
//   Widget _showExpertList() {
//     if (expertsList.isEmpty) return const Center(child: Text("No experts found."));
//     return ListView.builder(
//       itemCount: expertsList.length,
//       itemBuilder: (context, index) {
//         final expert = expertsList[index];
//
//         // Active status check (True ho to active, false ho to inactive/fade)
//         // Pending list mein default 100% active dikhana hai bina kisi opacity/fade ke
//         bool isActive = currentSection == "Approved" ? (expert['IsActive'] != false) : true;
//
//         return Container(
//           margin: const EdgeInsets.only(bottom: 12),
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(10),
//             boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)],
//           ),
//           child: Opacity(
//             // Inactive experts ko 50% opacity par fade karna hai, active visual ko 100% rakhna hai
//             opacity: isActive ? 1.0 : 0.5,
//             child: Row(
//               children: [
//                 CircleAvatar(
//                   backgroundColor: Colors.blueGrey.shade100,
//                   backgroundImage: expert['upicture'] != null
//                       ? NetworkImage(ApiService.getFullImageUrl(expert['upicture']))
//                       : null,
//                   child: expert['upicture'] == null ? const Icon(Icons.person, color: Colors.white) : null,
//                 ),
//                 const SizedBox(width: 15),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(expert['username'] ?? "Unknown", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
//                     Text(expert['category'] ?? "Expert", style: const TextStyle(fontSize: 12, color: Colors.grey)),
//                   ],
//                 ),
//                 const Spacer(),
//
//                 currentSection == "Approved"
//                     ? Container(
//                   decoration: BoxDecoration(
//                     color: (isActive ? Colors.green : Colors.red).withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: IconButton(
//                     icon: Icon(
//                       isActive ? Icons.check_circle : Icons.block,
//                       color: isActive ? Colors.green : Colors.red,
//                     ),
//                     // ⭐ iOS Flow: Approved tab ke checkmark button par active/inactive toggle call ho raha hai
//                     onPressed: () => handleUserAction(expert['uid'], "toggle_status"),
//                   ),
//                 )
//                     : Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.check, color: Colors.green), // Tick button
//                       onPressed: () => handleUserAction(expert['uid'], "approve"),
//                     ),
//                     const SizedBox(width: 10),
//                     IconButton(
//                       icon: const Icon(Icons.close, color: Colors.red), // Cross button
//                       onPressed: () => confirmDelete(expert['uid']),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _showAddForm() {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text("Expert Name", style: TextStyle(fontWeight: FontWeight.bold)),
//           const SizedBox(height: 5),
//           _customTextField(nameController, "Enter Name"),
//           const SizedBox(height: 15),
//           const Text("Password", style: TextStyle(fontWeight: FontWeight.bold)),
//           const SizedBox(height: 5),
//           _customTextField(passController, "Enter Password", isPass: true),
//           const SizedBox(height: 15),
//           const Text("Confirm Password", style: TextStyle(fontWeight: FontWeight.bold)),
//           const SizedBox(height: 5),
//           _customTextField(confirmController, "Repeat Password", isPass: true),
//           const SizedBox(height: 10),
//           CheckboxListTile(
//             title: const Text("Electrical "),
//             value: electrical,
//             onChanged: (val) => setState(() { electrical = val!; if(val) mechanical = false; }),
//             controlAffinity: ListTileControlAffinity.leading,
//           ),
//           CheckboxListTile(
//             title: const Text("Mechanical "),
//             value: mechanical,
//             onChanged: (val) => setState(() { mechanical = val!; if(val) electrical = false; }),
//             controlAffinity: ListTileControlAffinity.leading,
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             width: double.infinity,
//             height: 50,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001F3F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
//               onPressed: saveExpertByAdmin,
//               child: const Text("SAVE EXPERT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   Widget _customTextField(TextEditingController controller, String hint, {bool isPass = false}) {
//     return TextField(
//       controller: controller,
//       obscureText: isPass,
//       decoration: InputDecoration(
//         hintText: hint,
//         filled: true,
//         fillColor: Colors.grey.shade100,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
//       ),
//     );
//   }
//
//   Widget _myTab(String title) {
//     bool selected = currentSection == title;
//     return Expanded(
//       child: InkWell(
//         onTap: () {
//           setState(() => currentSection = title);
//           fetchExpertsData();
//         },
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           decoration: BoxDecoration(
//             color: selected ? const Color(0xFF001F3F) : Colors.transparent,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Center(
//             child: Text(title, style: TextStyle(color: selected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
//           ),
//         ),
//       ),
//     );
//   }
// }

////////////////////////////////////////////////Purana code

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'admin_ranking_view.dart';

class AdminExpertScreen extends StatefulWidget {
  final String adminName;
  const AdminExpertScreen({super.key, required this.adminName});

  @override
  State<AdminExpertScreen> createState() => _AdminExpertScreenState();
}

class _AdminExpertScreenState extends State<AdminExpertScreen> {
  String currentSection = "Approved";
  List<dynamic> expertsList = [];
  bool isLoading = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController confirmController = TextEditingController();
  bool electrical = false;
  bool mechanical = false;

  @override
  void initState() {
    super.initState();
    fetchExpertsData();
  }

  Future<void> fetchExpertsData() async {
    if (currentSection == "Add" || currentSection == "Ranking") return;
    setState(() => isLoading = true);
    List<dynamic> data;
    if (currentSection == "Approved") {
      data = await ApiService.getApprovedExperts();
    } else {
      data = await ApiService.getPendingExperts();
    }
    setState(() {
      expertsList = data;
      isLoading = false;
    });
  }

  // Pending list se expert ko reject/delete karne ke liye confirmation dialog
  void confirmDelete(int uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Action"),
        content: const Text("Are you sure you want to reject this expert?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              handleUserAction(uid, "delete"); // Pending tab se permanent delete karne ke liye
            },
            child: const Text("Yes, Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void handleUserAction(int uid, String actionType) async {
    setState(() => isLoading = true);
    bool success = false;

    if (actionType == "approve") {
      // Pending Tab: Tick dabane par approve karega (api/users/approveexpert/{uid})
      success = await ApiService.approveExpert(uid);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Expert Approved Successfully!"), backgroundColor: Colors.green),
          );
        }
      }
    }
    else if (actionType == "toggle_status") {
      // Approved Tab: Status Toggle (api/users/disableexpert/{uid})
      success = await ApiService.disableExpert(uid);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Status Toggled Successfully!"), backgroundColor: Colors.orange),
          );
        }
      }
    }
    else if (actionType == "delete") {
      // Pending Tab: Cross dabane par user database se hard delete ho jayega (api/users/{uid})
      success = await ApiService.deleteUser(uid);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Expert Rejected successfully!"), backgroundColor: Colors.redAccent),
          );
        }
      }
    }

    // Refresh data after operation
    fetchExpertsData();
  }

  void saveExpertByAdmin() async {
    if (passController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
      return;
    }
    String category = electrical ? "Electrical" : "Mechanical";
    bool ok = await ApiService.addExpertAdmin(nameController.text, passController.text, category);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Expert Added Successfully!")));
      nameController.clear(); passController.clear(); confirmController.clear();
      setState(() => currentSection = "Approved");
      fetchExpertsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 25),
              _buildTabsRow(),
              const SizedBox(height: 25),Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : currentSection == "Ranking"
                    ? const AdminExpertRankingView() // 👈 Agar Ranking select hai to naya view dikhao
                    : (currentSection == "Add" ? _showAddForm() : _showExpertList()), // 👈 Warna purana flow
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // ⭐ FIXED: Arrow function syntax mistake yahan theek kar di hai
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20), onPressed: () => Navigator.pop(context)),
            const Text('Welcome', style: TextStyle(fontSize: 28, fontWeight: FontWeight.normal, color: Color(0xFF001F3F))),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 45),
          child: Text(widget.adminName, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTabsRow() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [_myTab("Approved"), _myTab("Pending"), _myTab("Add"),_myTab("Ranking")],
      ),
    );
  }

  Widget _showExpertList() {
    if (expertsList.isEmpty) return const Center(child: Text("No experts found."));
    return ListView.builder(
      itemCount: expertsList.length,
      itemBuilder: (context, index) {
        final expert = expertsList[index];

        // Active status check (True ho to active, false ho to inactive/fade)
        bool isActive = currentSection == "Approved" ? (expert['IsActive'] != false) : true;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Opacity(
            // Inactive (IsActive == false) experts ko 50% opacity par fade karna hai
            opacity: isActive ? 1.0 : 0.5,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blueGrey.shade100,
                  backgroundImage: expert['upicture'] != null && expert['upicture'].toString().isNotEmpty
                      ? NetworkImage(ApiService.getFullImageUrl(expert['upicture']))
                      : null,
                  child: expert['upicture'] == null || expert['upicture'].toString().isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expert['username'] ?? "Unknown", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(
                        (expert['category'] != null && expert['category'].toString().isNotEmpty)
                            ? expert['category'].toString()
                            : "General Expert", // Agar category null ho to ye dikhaye
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue, // Isay blue rakhte hain taake iOS jaisa look aaye
                            fontWeight: FontWeight.w500
                        )),
                  ],
                ),
                const Spacer(),

                currentSection == "Approved"
                    ? Container(
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.green : Colors.red).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isActive ? Icons.check_circle : Icons.block,
                      color: isActive ? Colors.green : Colors.red,
                    ),
                    onPressed: () => handleUserAction(expert['uid'], "toggle_status"),
                  ),
                )
                    : Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green), // Tick button (Approve)
                      onPressed: () => handleUserAction(expert['uid'], "approve"),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red), // Cross button (Reject / Permanent Delete)
                      onPressed: () => confirmDelete(expert['uid']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _showAddForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Expert Name", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          _customTextField(nameController, "Enter Name"),
          const SizedBox(height: 15),
          const Text("Password", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          _customTextField(passController, "Enter Password", isPass: true),
          const SizedBox(height: 15),
          const Text("Confirm Password", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          _customTextField(confirmController, "Repeat Password", isPass: true),
          const SizedBox(height: 10),
          CheckboxListTile(
            title: const Text("Electrical "),
            value: electrical,
            onChanged: (val) => setState(() { electrical = val!; if(val) mechanical = false; }),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            title: const Text("Mechanical "),
            value: mechanical,
            onChanged: (val) => setState(() { mechanical = val!; if(val) electrical = false; }),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001F3F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: saveExpertByAdmin,
              child: const Text("SAVE EXPERT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _customTextField(TextEditingController controller, String hint, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _myTab(String title) {
    bool selected = currentSection == title;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => currentSection = title);
          fetchExpertsData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF001F3F) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(title, style: TextStyle(color: selected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold,fontSize: 12,)),
          ),
        ),
      ),
    );
  }
}