import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminSolutionDetailScreen extends StatefulWidget {
  final int sid;
  final String title, expert, category;
  final double rating;

  AdminSolutionDetailScreen({
    required this.sid,
    required this.title,
    required this.expert,
    required this.category,
    required this.rating,
  });

  @override
  _AdminSolutionDetailScreenState createState() => _AdminSolutionDetailScreenState();
}

class _AdminSolutionDetailScreenState extends State<AdminSolutionDetailScreen> {
  List<dynamic> steps = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadStepsData();
  }

  loadStepsData() async {
    // ApiService mein fetchStepsBySolutionId ya fetchStepsForAdmin use karein
    var data = await ApiService.fetchStepsBySolutionId(widget.sid);
    setState(() {
      steps = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF2F2F7), // iOS System Background
      appBar: AppBar(
        title: Text("Solution Detail", style: TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expert Info Card
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: TextStyle(fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
                  Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Expert: ${widget.expert}", style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("Category: ${widget.category}",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.yellow.withValues(alpha: 0.1),
                            // Naya syntax use karein
                            borderRadius: BorderRadius.circular(8)
                        ),
                        child: Row(
                          children: [
                            // Ye raha numeric rating text
                            Text(
                                widget.rating.toStringAsFixed(1),
                                style: TextStyle(fontWeight: FontWeight.bold)
                            ),
                            SizedBox(width: 5),
                            // Ye loop 5 stars generate karega
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < widget.rating.floor()
                                      ? Icons.star
                                      : (index < widget.rating
                                      ? Icons.star_half
                                      : Icons.star_border),
                                  color: Colors.orangeAccent,
                                  size: 16,
                                );
                              }),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("Implementation Steps",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            if (isLoading)
              Center(child: Padding(padding: EdgeInsets.all(50),
                  child: CircularProgressIndicator()))
            else
              if (steps.isEmpty)
                Center(child: Padding(padding: EdgeInsets.all(50),
                    child: Text("No steps found.",
                        style: TextStyle(color: Colors.grey))))
              else
                ...steps.map((step) => _buildStepCard(step)).toList(),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showStepRatingsSheet(int stepId, int stepNo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          Container(
            height: MediaQuery
                .of(context)
                .size
                .height * 0.6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  margin: EdgeInsets.only(top: 10),
                  height: 4, width: 40,
                  decoration: BoxDecoration(color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Ratings for Step $stepNo", style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: ApiService.fetchStepRatings(stepId),
                    // Aapka pehle se bana function
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text(
                            "No reviews found for this step.",
                            style: TextStyle(color: Colors.grey)));
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        itemBuilder: (context, index) {
                          final review = snapshot.data![index];
                          return ListTile(
                            leading: CircleAvatar(
                                child: Text(review['rname']?[0] ?? "U")),
                            title: Text(review['rname'] ?? "User",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(review['review'] ?? "No comment"),
                            // ... baki sheet ka code same rahay ga
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Ye loop 5 stars generate karega
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    // rating ko double mein convert karain safety ke liye
                                    double currentRating = double.tryParse(review['rating'].toString()) ?? 0.0;

                                    return Icon(
                                      starIndex < currentRating.floor()
                                          ? Icons.star
                                          : (starIndex < currentRating ? Icons.star_half : Icons.star_border),
                                      color: Colors.orangeAccent,
                                      size: 16,
                                    );
                                  }),
                                ),
                                SizedBox(width: 4),
                                Text(
                                    "${review['rating']}",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                                ),
                              ],
                            ),
// ...
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildStepCard(dynamic step) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Step Number and Check Ratings Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5)
                ),
                child: Text(
                  "Step ${step['stepNo']}",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue
                  ),
                ),
              ),

              // iOS Style Check Ratings Button
              InkWell(
                onTap: () =>
                    _showStepRatingsSheet(step['stepId'], step['stepNo']),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade300),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_outline_rounded, color: Colors.blue,
                          size: 14),
                      SizedBox(width: 4),
                      Text(
                        "Check Ratings",
                        style: TextStyle(
                            color: Colors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // Step Description
          Text(
              step['stepDescription'] ?? step['description'] ??
                  "No description",
              style: TextStyle(fontSize: 15, color: Colors.black87)
          ),

          // Step Image
          if (step['stepImg'] != null || step['image'] != null)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  ApiService.getAdminImageUrl(step['stepImg'] ?? step['image']),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}