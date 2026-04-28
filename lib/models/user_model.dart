class UserModel {
  final int uid;
  final String username;
  final String type;
  final int? defaultVid; // Gari ki ID (nullable kyunke signup pe 0 ya null ho sakti hai)

  UserModel({
    required this.uid,
    required this.username,
    required this.type,
    this.defaultVid,
  });

  // API se aane wale JSON ko Flutter Object mein convert karne ke liye
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['userId'] ?? 0, // C# mein aapne 'userId' bheja hai
      username: json['username'] ?? '',
      type: json['type'] ?? '',
      defaultVid: json['defaultVehicle'] != null ? json['defaultVehicle']['vid'] : null,
    );
  }

  // Agar kabhi data wapis bhejni ho JSON mein (Optional)
 /* Map<String, dynamic> toJson() {
    return {
      'userId': uid,
      'username': username,
      'type': type,
    };
  }*/
}