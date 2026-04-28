class ExpertSolution {
  final int vpsId;
  final String expertName;
  final String solutionTitle;
  final double rating;
  final int reviews;
  final String steps; // Json ya string list
  final String imageUrl;

  ExpertSolution({
    required this.vpsId,
    required this.expertName,
    required this.solutionTitle,
    required this.rating,
    required this.reviews,
    required this.steps,
    required this.imageUrl,
  });

  factory ExpertSolution.fromJson(Map<String, dynamic> json) {
    return ExpertSolution(
      vpsId: json['vpsId'],
      expertName: json['expertName'],
      solutionTitle: json['solutionTitle'],
      rating: (json['rating'] as num).toDouble(),
      reviews: json['reviews'],
      steps: json['steps'],
      imageUrl: json['imageUrl'],
    );
  }
}