// import 'package:flutter/material.dart';
// import '../../services/api_service.dart';
// import 'dmin_solution_detail_screen.dart';
// //import 'admin_solution_detail_screen.dart';
//
// class AdminSolutionsScreen extends StatefulWidget {
//   @override
//   final String adminName; // 👈 Ye line add karein
//
//   // Constructor ko update karein taake wo naam le sakay
//   const AdminSolutionsScreen({super.key, required this.adminName});
//   _AdminSolutionsScreenState createState() => _AdminSolutionsScreenState();
// }
//
// class _AdminSolutionsScreenState extends State<AdminSolutionsScreen> {
//   List<dynamic> assignments = [];
//   bool isLoading = true;
//
//
//   @override
//   void initState() {
//     super.initState();
//     fetchData();
//   }
//
//   Future<void> fetchData() async {
//     setState(() => isLoading = true);
//     var data = await ApiService.getAllSolutions(); // iOS: adminGetAllSolutions
//     setState(() {
//       assignments = data;
//       isLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFF5F7F9),
//       appBar: AppBar(
//         title: Text("Experts Solutions", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 1,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         itemCount: assignments.length,
//         itemBuilder: (context, index) {
//           final item = assignments[index];
//           double rating = (item['Rating'] ?? 0.0).toDouble();
//
//           return GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => AdminSolutionDetailScreen(
//                     sid: item['sid'],
//                     title: item['SolutionTitle'] ?? "No Title",
//                     expert: item['ExpertName'] ?? "Unknown",
//                     category: item['ExpertCategory'] ?? "General",
//                     rating: rating,
//                   ),
//                 ),
//               ).then((_) => fetchData());
//             },
//             child: Container(
//               margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
//               padding: EdgeInsets.all(15),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(item['SolutionTitle'] ?? "No Title",
//                             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                         SizedBox(height: 4),
//                         Row(
//                           children: [
//                             Text(item['ExpertName'] ?? "",
//                                 style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
//                             Text(" • ${item['ExpertCategory']}",
//                                 style: TextStyle(color: Colors.grey, fontSize: 13)),
//                           ],
//                         ),
//                         SizedBox(height: 6),
//                         // Exact Decimal Star Logic
//                         Row(
//                           children: [
//                             _buildStarRating(rating),
//                             SizedBox(width: 5),
//                             Text(rating.toStringAsFixed(1),
//                                 style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
//                             Text(" (${item['ReviewCount'] ?? 0})",
//                                 style: TextStyle(fontSize: 11, color: Colors.grey)),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   // iOS-style star masking logic
//   Widget _buildStarRating(double rating) {
//     return Stack(
//       children: [
//         Row(
//           children: List.generate(5, (index) => Icon(Icons.star, color: Colors.grey.withOpacity(0.3), size: 14)),
//         ),
//         ClipRect(
//           clipper: StarClipper(rating),
//           child: Row(
//             children: List.generate(5, (index) => Icon(Icons.star, color: Colors.orangeAccent, size: 14)),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class StarClipper extends CustomClipper<Rect> {
//   final double rating;
//   StarClipper(this.rating);
//   @override
//   Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width * (rating / 5), size.height);
//   @override
//   bool shouldReclip(CustomClipper<Rect> oldClipper) => true;
// }

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dmin_solution_detail_screen.dart';

class AdminSolutionsScreen extends StatefulWidget {
  final String adminName;
  const AdminSolutionsScreen({super.key, required this.adminName});

  @override
  _AdminSolutionsScreenState createState() => _AdminSolutionsScreenState();
}

class _AdminSolutionsScreenState extends State<AdminSolutionsScreen> {
  List<dynamic> assignments = []; // Asli data
  List<dynamic> filteredAssignments = []; // Search wala data
  bool isLoading = true;

  // Search ke liye controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    var data = await ApiService.getAllSolutions();
    setState(() {
      assignments = data;
      filteredAssignments = data; // Shuru mein dono same honge
      isLoading = false;
    });
  }

  // 🔥 React wali Deep Search Logic (Dart Version)
  void _runSearch(String query) {
    List<dynamic> results = [];
    if (query.isEmpty) {
      results = assignments;
    } else {
      // User ke words ko split karna (e.g "Suzuki 2019")
      List<String> searchWords = query.toLowerCase().trim().split(RegExp(r'\s+'));

      results = assignments.where((item) {
        // Poore object ki values ko aik string mein jama karna (React logic)
        // Isme Make, Model, Year, Title sab shamil hain
        String allValues = "${item['SolutionTitle']} ${item['ExpertName']} ${item['ExpertCategory']} ${item['Make']} ${item['Model']} ${item['Variant']} ${item['Year']}"
            .toLowerCase();

        // Check karna ke user ke SARE words matches hain ya nahi
        return searchWords.every((word) => allValues.contains(word));
      }).toList();
    }

    setState(() {
      filteredAssignments = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7F9),
      appBar: AppBar(
        title: Text("Experts Solutions", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Search Bar (React UI ki tarah)
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runSearch(value),
              decoration: InputDecoration(
                hintText: "Search any car (e.g. Suzuki Alto)...",
                prefixIcon: Icon(Icons.search, color: Color(0xFF1B2E4B)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF1B2E4B)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredAssignments.isEmpty
                ? Center(child: Text("No solutions found matching \"${_searchController.text}\""))
                : ListView.builder(
              itemCount: filteredAssignments.length,
              itemBuilder: (context, index) {
                final item = filteredAssignments[index];
                double rating = (item['Rating'] ?? 0.0).toDouble();

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminSolutionDetailScreen(
                          sid: item['sid'],
                          title: item['SolutionTitle'] ?? "No Title",
                          expert: item['ExpertName'] ?? "Unknown",
                          category: item['ExpertCategory'] ?? "General",
                          rating: rating,
                        ),
                      ),
                    ).then((_) => fetchData());
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['SolutionTitle'] ?? "No Title",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 4),
                              // Car Info like React (Make, Model, Year)
                              // Text(
                              //   "Car: ${item['Make'] ?? ''} ${item['Model'] ?? ''} ${item['Year'] ?? ''}",
                              //   style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                              // ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(item['ExpertName'] ?? "",
                                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text(" • ${item['ExpertCategory']}",
                                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildStarRating(rating),
                                  SizedBox(width: 5),
                                  Text(rating.toStringAsFixed(1),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text(" (${item['ReviewCount'] ?? 0})",
                                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Stack(
      children: [
        Row(
          children: List.generate(5, (index) => Icon(Icons.star, color: Colors.grey.withOpacity(0.3), size: 14)),
        ),
        ClipRect(
          clipper: StarClipper(rating),
          child: Row(
            children: List.generate(5, (index) => Icon(Icons.star, color: Colors.orangeAccent, size: 14)),
          ),
        ),
      ],
    );
  }
}

class StarClipper extends CustomClipper<Rect> {
  final double rating;
  StarClipper(this.rating);
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width * (rating / 5), size.height);
  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => true;
}