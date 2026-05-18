// import 'package:flutter/material.dart';
// import '../../../services/api_service.dart';
// import '../../../utils/constants.dart';
//
// class ExpertSolutionsView extends StatefulWidget {
//   final int vid;
//   final int pid;
//   final String? selectedCar;
//   final String? selectedProblem;
//   final Function(Map<String, dynamic>) onSelect;
//   final VoidCallback onBack;
//
//   const ExpertSolutionsView({
//     super.key,
//     required this.vid,
//     required this.pid,
//     this.selectedCar,
//     this.selectedProblem,
//     required this.onSelect,
//     required this.onBack,
//   });
//
//   @override
//   State<ExpertSolutionsView> createState() => _ExpertSolutionsViewState();
// }
//
// class _ExpertSolutionsViewState extends State<ExpertSolutionsView> {
//   late Future<List<dynamic>> _solutionsFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     // ApiService ka wahi function call ho raha hai jo aapne bataya
//     _solutionsFuture =
//         ApiService.fetchSolutionsByVehicleAndProblem(widget.vid, widget.pid);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       body: Column(
//         children: [
//           // 1. TOP CARD: Vehicle & Problem (iOS Style)
//           Card(
//             margin: const EdgeInsets.all(16.0),
//             elevation: 4,
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12)),
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   _infoRow("Vehicle:", widget.selectedCar ?? 'N/A'),
//                   const Divider(),
//                   _infoRow("Problem:", widget.selectedProblem ?? 'N/A'),
//                 ],
//               ),
//             ),
//           ),
//
//           // Section Title
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16.0),
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: Text("Expert Solutions",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             ),
//           ),
//
//           // 2. SOLUTIONS LIST
//           Expanded(
//             child: FutureBuilder<List<dynamic>>(
//               future: _solutionsFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.hasError) {
//                   return Center(child: Text("Error: ${snapshot.error}"));
//                 }
//                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return const Center(
//                       child: Text("No expert has provided a solution yet."));
//                 }
//
//                 final solutions = snapshot.data!;
//                 return ListView.builder(
//                   padding: const EdgeInsets.all(8.0),
//                   itemCount: solutions.length,
//                   itemBuilder: (context, index) {
//                     final sol = solutions[index];
//                     return _buildExpertCard(sol);
//                   },
//                 );
//               },
//             ),
//           ),
//
//           // 3. BACK BUTTON
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: ElevatedButton(
//               onPressed: widget.onBack,
//               style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blueAccent,
//                   minimumSize: const Size(double.infinity, 50)
//               ),
//               child: const Text(
//                   "Back to Dashboard", style: TextStyle(color: Colors.white)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _infoRow(String label, String value) {
//     return Row(
//       children: [
//         Text(label, style: const TextStyle(
//             fontWeight: FontWeight.bold, color: Colors.blueGrey)),
//         const Spacer(),
//         Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
//       ],
//     );
//   }
//
//   // IOS Style Expert Card
//   Widget _buildExpertCard(dynamic sol) {
//     // 1. Data uthao (Naye structure ke mutabiq)
//     final String title = sol['title'] ?? sol['solutionTitle'] ?? "No Title Provided";
//
//     // Ab yahan "ExpertName" show hoga jo notepad wali API bhej rahi hai
//     final String expertName = sol['expertName'] ?? sol['ExpertName'] ?? "Expert #${sol['expertId'] ?? sol['eid'] ?? 'N/A'}";
//
//     final double rating = (sol['overallRating'] ?? sol['OverallRating'] ?? 0.0).toDouble();
//     final int reviewCount = sol['reviewCount'] ?? sol['ReviewCount'] ?? 0;
//     final String? expertImg = sol['expertPicture'] ?? sol['ExpertPicture'];
//
//     // --- YE LINE SAB SE ZAROORI HAI ---
//     // Backend se 'solutionId' aa raha hai, humein isay 'sid' bana kar bhejna hai taake steps fetch hon
//     final int actualSid = sol['solutionId'] ?? sol['sid'] ?? 0;
//
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 3,
//       child: InkWell(
//         // Yahan hum 'sid' ko inject kar rahay hain taake agla page (Steps) na hiley
//         onTap: () => widget.onSelect({...sol, 'sid': actualSid}),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: 25,
//
//                 backgroundColor: Colors.blueAccent,
//                 backgroundImage: (expertImg != null && expertImg.isNotEmpty)
//                     ? NetworkImage("${AppConstants.baseUrl.replaceAll('/api', '')}/$expertImg")
//                     : null,
//                 child: expertImg == null ? const Icon(Icons.person, color: Colors.white) : null,
//               ),
//               const SizedBox(width: 15),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
//
//                     // AB YAHAN NAAM SHOW HOGA!
//                     Text(expertName, style: const TextStyle(color: Colors.grey, fontSize: 13)),
//
//                     const SizedBox(height: 5),
//                     Row(
//                       children: [
//                         Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
//                         const SizedBox(width: 4),
//                         Row(
//                           children: List.generate(5, (index) {
//                             double starValue = rating - index;
//                             return Icon(
//                               starValue >= 1 ? Icons.star : (starValue >= 0.5 ? Icons.star_half : Icons.star_border),
//                               color: Colors.amber, size: 16,
//                             );
//                           }),
//                         ),
//                         const SizedBox(width: 5),
//                         Text("($reviewCount Reviews)", style: const TextStyle(fontSize: 11, color: Colors.grey)),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../utils/constants.dart';

class ExpertSolutionsView extends StatefulWidget {
  final int vid;
  final int pid;
  final String? selectedCar;
  final String? selectedProblem;
  final Function(Map<String, dynamic>) onSelect;
  final VoidCallback onBack;

  const ExpertSolutionsView({
    super.key,
    required this.vid,
    required this.pid,
    this.selectedCar,
    this.selectedProblem,
    required this.onSelect,
    required this.onBack,
  });

  @override
  State<ExpertSolutionsView> createState() => _ExpertSolutionsViewState();
}

class _ExpertSolutionsViewState extends State<ExpertSolutionsView> {
  late Future<List<dynamic>> _solutionsFuture;

  @override
  void initState() {
    super.initState();
    _solutionsFuture =
        ApiService.fetchSolutionsByVehicleAndProblem(widget.vid, widget.pid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _infoRow("Vehicle:", widget.selectedCar ?? 'N/A'),
                  const Divider(),
                  _infoRow("Problem:", widget.selectedProblem ?? 'N/A'),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Expert Solutions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _solutionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("No expert has provided a solution yet."));
                }

                final solutions = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: solutions.length,
                  itemBuilder: (context, index) {
                    final sol = solutions[index];
                    return _buildExpertCard(sol);
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: widget.onBack,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 50)
              ),
              child: const Text(
                  "Back to Dashboard", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildExpertCard(dynamic sol) {
    final String title = sol['title'] ?? sol['solutionTitle'] ?? "No Title Provided";
    final String expertName = sol['expertName'] ?? sol['ExpertName'] ?? "Expert";


    final double solRating = (sol['overallRating'] ?? sol['OverallRating'] ?? 0.0).toDouble();
    final int reviewCount = sol['reviewCount'] ?? sol['ReviewCount'] ?? 0;

    // 2. Expert ki Overall Profile Performance (Niche dikhani hai)
    //final double expertOverallRating = (sol['expertOverallRating'] ?? sol['ExpertOverallRating'] ?? 0.0).toDouble();

    final String? expertImg = sol['expertPicture'] ?? sol['ExpertPicture'];
    final int actualSid = sol['solutionId'] ?? sol['sid'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        onTap: () => widget.onSelect({...sol, 'sid': actualSid}),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blueAccent,
                backgroundImage: (expertImg != null && expertImg.isNotEmpty)
                    ? NetworkImage("${AppConstants.baseUrl.replaceAll('/api', '')}/$expertImg")
                    : null,
                child: expertImg == null ? const Icon(Icons.person, color: Colors.white) : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(expertName, style: const TextStyle(color: Colors.grey, fontSize: 13)),

                    const SizedBox(height: 5),


                    Row(
                      children: [
                        Text(solRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(width: 4),
                        _buildStars(solRating, size: 14),
                        const SizedBox(width: 5),
                        Text("($reviewCount Reviews)", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),

                    const Divider(height: 20),


                    Row(
                      children: [
                        //const Icon(Icons.verified_user, size: 12, color: Colors.blueAccent),
                        const SizedBox(width: 4),
                       // const Text("Expert Rating: ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                        //_buildStars(expertOverallRating, size: 11),
                        const SizedBox(width: 4),
                        //Text(expertOverallRating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Star function
  Widget _buildStars(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        double starValue = rating - index;
        return Icon(
          starValue >= 1 ? Icons.star : (starValue >= 0.5 ? Icons.star_half : Icons.star_border),
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
}