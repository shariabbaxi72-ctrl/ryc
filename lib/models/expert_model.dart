class ExpertModel {
  final int eid;
  final int uid;
  final String category;
  final String? username; // User table se join ho kar aye to

  ExpertModel({
    required this.eid,
    required this.uid,
    required this.category,
    this.username,
  });

  factory ExpertModel.fromJson(Map<String, dynamic> json) {
    return ExpertModel(
      eid: json['eid'] ?? 0,
      uid: json['uid'] ?? 0,
      category: json['category'] ?? '',
      username: json['username'],
    );
  }
}