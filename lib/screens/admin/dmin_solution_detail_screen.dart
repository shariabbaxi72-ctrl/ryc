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
        title: Text("Solution Detail", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17)),
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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                  Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Expert: ${widget.expert}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("Category: ${widget.category}", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.yellow.withValues(alpha: 0.1), // Naya syntax use karein
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
                                      : (index < widget.rating ? Icons.star_half : Icons.star_border),
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
              child: Text("Implementation Steps", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            if (isLoading)
              Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator()))
            else if (steps.isEmpty)
              Center(child: Padding(padding: EdgeInsets.all(50), child: Text("No steps found.", style: TextStyle(color: Colors.grey))))
            else
              ...steps.map((step) => _buildStepCard(step)).toList(),

            SizedBox(height: 30),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
            child: Text("Step ${step['stepNo']}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          SizedBox(height: 12),
          Text(step['description'] ?? "No description", style: TextStyle(fontSize: 15)),
          if (step['image'] != null && step['image'].toString().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  // Naya wala image function call karein jo main ne bataya tha
                  ApiService.getAdminImageUrl(step['image']),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
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