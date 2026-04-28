import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print("Connecting to: ${AppConstants.loginUrl}");

      final response = await http.post(
        Uri.parse(AppConstants.loginUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "ngrok-skip-browser-warning": "69420",
        },
        body: json.encode({
          "username": username,
          "password": password,
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();

        // FIX: Database se 'userId' aa raha hai, 'uid' nahi.
        // Hum 'userId' aur 'expertId' dono save kar rahe hain taake aage kaam aayein.
        await prefs.setInt('userId', data['userId'] ?? 0);
        await prefs.setInt('expertId', data['expertId'] ?? 0);
        await prefs.setString('username', data['username'] ?? "");
        await prefs.setString('type', data['type'] ?? "");

        return {"status": "success", "data": data};
      } else {
        return {"status": "error", "message": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      print("Detailed Error: $e");
      return {"status": "error", "message": "Check Internet/URL"};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String type,
    String? category,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.signupUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "ngrok-skip-browser-warning": "69420",
        },
        body: json.encode({
          "username": username,
          "password": password,
          "type": type.toLowerCase(),
          "category": category,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {"status": "success"};
      } else {
        return {"status": "error", "message": "Signup Failed: ${response.statusCode}"};
      }
    } catch (e) {
      return {"status": "error", "message": "Server Error: $e"};
    }
  }
}