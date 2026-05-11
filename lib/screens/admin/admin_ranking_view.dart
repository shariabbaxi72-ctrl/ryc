import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminExpertRankingView extends StatefulWidget {
  const AdminExpertRankingView({super.key});

  @override
  State<AdminExpertRankingView> createState() => _AdminExpertRankingViewState();
}

class _AdminExpertRankingViewState extends State<AdminExpertRankingView> {
  List<dynamic> rankingList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRankings();
  }

  Future<void> loadRankings() async {
    setState(() => isLoading = true);
    // iOS synchronized endpoint call
    final data = await ApiService.fetchExpertRankings();
    setState(() {
      rankingList = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (rankingList.isEmpty) return const Center(child: Text("No ranking data available"));

    return ListView.builder(
      itemCount: rankingList.length,
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemBuilder: (context, index) {
        final expert = rankingList[index];
        double rating = double.tryParse(expert['overallRating']?.toString() ?? '0.0') ?? 0.0;
        int reviews = int.tryParse(expert['totalReviews']?.toString() ?? '0') ?? 0;

        return _buildRankingRow(expert['username'], rating, reviews);
      },
    );
  }
  Widget _buildRankingRow(String name, double rating, int reviews) {
    // iOS Badge Logic (Same as before)
    String statusText = "NEW";
    Color statusColor = Colors.grey;

    if (rating >= 4.5) { statusText = "EXCELLENT"; statusColor = Colors.green; }
    else if (rating >= 3.5) { statusText = "VERY GOOD"; statusColor = Colors.blue; }
    else if (rating >= 2.5) { statusText = "AVERAGE"; statusColor = Colors.orange; }
    else if (rating > 0) { statusText = "BAD"; statusColor = Colors.red; }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Left Side: Name & Review Count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 4),
                Text("$reviews Reviews", style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),

          // Right Side: 5 Stars & Badge (Purana single star remove kar diya hai)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  _buildStarRating(rating), // 👈 Sirf ye function stars dikhaye ga
                  const SizedBox(width: 8),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Helper function to build 5 stars based on rating
  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index + 1 <= rating) {
          return const Icon(Icons.star, color: Colors.yellow, size: 16);
        } else if (index < rating && index + 1 > rating) {
          return const Icon(Icons.star_half, color: Colors.yellow, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.grey, size: 16);
        }
      }),
    );
  }
}