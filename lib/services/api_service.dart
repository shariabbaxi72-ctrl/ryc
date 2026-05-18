import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static Map<String, String> get headers => {
    "Accept": "application/json",
    "ngrok-skip-browser-warning": "69420",
  };

  // --- Purani APIs (Don't touch) ---
  static Future<Map<String, dynamic>?> fetchExpertProfile(int uid) async {
    try {
      final response = await http.get(Uri.parse("${AppConstants.baseUrl}/users/Currentuser?uid=$uid"), headers: headers);
      return response.statusCode == 200 ? json.decode(response.body) : null;
    } catch (e) { return null; }
  }

  // ApiService.dart mein ye method replace karein
  static Future<List<dynamic>> fetchExpertSolutions(int eid) async {
    try {
      // Ye timestamp har bar UNIQUE request banaye ga taake purana data na aaye
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final response = await http.get(
          Uri.parse("${AppConstants.baseUrl}/VPS?v=$timestamp"), // 👈 Ye zaroori hai
          headers: headers
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        if (decodedData is Map && decodedData.containsKey('records')) {
          List<dynamic> allRecords = decodedData['records'];

          // Filtering: Sirf is expert ke records
          // .toString() use karein taake comparison error na aaye
          return allRecords.where((record) =>
          record['eid'].toString() == eid.toString() ||
              record['expertId'].toString() == eid.toString()
          ).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ApiService.dart mein add karein
  static Future<List<dynamic>> fetchAllVehicles() async {
    try {
      // Apne backend ka route use karein jo saari gariyan deta hai
      final url = "${AppConstants.baseUrl}/vehicles/getallvehicles";
      final res = await http.get(Uri.parse(url), headers: headers);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        // Backend se jo structure aa raha hai uske mutabiq (usually 'vehicles' key hoti hai)
        return data['vehicles'] ?? [];
      }
      return [];
    } catch (e) { return []; }
  }

  // ApiService.dart mein ye method aisa hona chahiye:
  static Future<List<dynamic>> fetchAllProblems() async {
    try {
      final url = "${AppConstants.baseUrl}/problems/getallproblem";
      final res = await http.get(Uri.parse(url), headers: headers);

      if (res.statusCode == 200) {
        final decodedData = json.decode(res.body);
        // Browser mein "problems" key aa rahi hai, is liye yahan bhi wahi likhna hai
        if (decodedData is Map && decodedData.containsKey('problems')) {
          return decodedData['problems'] as List;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }


  static Future<List<dynamic>> fetchFilteredProblems(String category) async {
    try {
      final url = "${AppConstants.baseUrl}/problems/filter?category=$category";
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final decodedData = json.decode(res.body);
        if (decodedData is List) return decodedData;
        if (decodedData is Map && decodedData.containsKey('\$values')) {
          return decodedData['\$values'];
        }
      }
      return [];
    } catch (e) {
      print("Error: $e");
      return [];

    }
  }

  // --- NEW: Upload Solution & Steps Method ---
  // --- NEW: Upload Solution & Steps Method (iOS Synchronized) ---
  static Future<bool> uploadExpertSolution({
    required int expertId,
    required int vid,
    required int pid,
    required String title,
    required List<Map<String, dynamic>> steps,
  }) async {
    try {
      // ==========================================
      // STEP 1: CREATE CORE SOLUTION ROW
      // ==========================================
      // Route: api/vehicles/{vid}/problems/{pid}/solutions?eid={eid}
      final solUrl = "${AppConstants.baseUrl}/vehicles/$vid/problems/$pid/solutions?eid=$expertId";

      final solRes = await http.post(
        Uri.parse(solUrl),
        headers: {"Content-Type": "application/json", ...headers},
        body: jsonEncode({"stitle": title}),
      );

      if (solRes.statusCode == 201 || solRes.statusCode == 200) {
        final solData = jsonDecode(solRes.body);
        int newSid = solData['solutionId']; // Response se generated ID mili

        // ==========================================
        // STEP 2: LINK EXPERT TO SOLUTION (Junction Table: ExpertSolutions)
        // ==========================================
        // iOS target: api/expertsolutions?eid={eid}&sid={sid}
        final linkUrl = "${AppConstants.baseUrl}/expertsolutions?eid=$expertId&sid=$newSid";

        final linkRes = await http.post(
          Uri.parse(linkUrl),
          headers: {"Content-Type": "application/json", ...headers},
          body: jsonEncode({}), // Empty JSON body as iOS
        );

        // Agar expert link successfully create ho jaye, tabhi steps upload karenge
        if (linkRes.statusCode == 200 || linkRes.statusCode == 201) {

          // ==========================================
          // STEP 3: UPLOAD ALL STEPS SEQUENTIALLY
          // ==========================================
          for (int i = 0; i < steps.length; i++) {
            final stepUrl = "${AppConstants.baseUrl}/steps/add";
            var request = http.MultipartRequest('POST', Uri.parse(stepUrl));
            request.headers.addAll(headers);

            // Step details (sid, stepNo, stepDescription)
            request.fields['sid'] = newSid.toString();
            request.fields['stepNo'] = (i + 1).toString();
            request.fields['stepDescription'] = steps[i]['controller'].text;

            // Step Image
            if (steps[i]['image'] != null) {
              File imgFile = steps[i]['image'];
              request.files.add(await http.MultipartFile.fromPath(
                'stepImg', // Controller parameter name matching stepImg
                imgFile.path,
              ));
            }

            var streamedRes = await request.send();
            var stepRes = await http.Response.fromStream(streamedRes);

            if (stepRes.statusCode != 200 && stepRes.statusCode != 201) {
              print("Step ${i + 1} failed to upload: ${stepRes.body}");
              return false; // Agar koi ek step bhi fail hua to transactional flow break ho jaye
            }
          }

          return true; // Core Solution created, Linked with Expert, and all Steps uploaded successfully!
        } else {
          print("Failed to link Expert ($expertId) with Solution ($newSid): ${linkRes.body}");
          return false;
        }
      }

      print("Core Solution insertion failed with code: ${solRes.statusCode}");
      return false;
    } catch (e) {
      print("Main Upload Error: $e");
      return false;
    }
  }

  static Future<bool> addVehicle(Map<String, dynamic> carData) async {
    try {
      final url = "${AppConstants.baseUrl}/vehicles/addvehicle";
      final Map<String, dynamic> formattedData = {
        "make": carData['vmake'],    // Database column name
        "model": carData['vmodel'],  // Database column name
        "variant": carData['vvariant'],
        "year": carData['vyear'],
        "status": carData['vstatus'], // "pending" ya "Approved"
      };

      final res = await http.post(Uri.parse(url), headers: {"Content-Type": "application/json", ...headers}, body: jsonEncode(formattedData));
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) { return false; }
  }


  // 2. Fetch Pending Requests (Jinka status 0 hai)
  static Future<List<dynamic>> fetchPendingVehicles() async {
    try {
      // Aapke naye controller ka route 'pending' hai
      final url = "${AppConstants.baseUrl}/vehicles/pending";
      final res = await http.get(Uri.parse(url), headers: headers);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        // Aapka backend { vehicles: [...] } bhej raha hai
        return data['vehicles'] ?? [];
      }
      return [];
    } catch (e) {
      print("Pending Fetch Error: $e");
      return [];
    }
  }
  static Future<bool> approveVehicle(int vid) async {
    try {
      // Aapke naye controller mein route GET hai: /approve?vid=5
      final url = "${AppConstants.baseUrl}/vehicles/approve?vid=$vid";
      final res = await http.get(Uri.parse(url), headers: headers);
      return res.statusCode == 200;
    } catch (e) { return false; }
  }
  static Future<bool> deleteVehicle(int vid) async {
    try {
      // Route: api/vehicles/{vid}
      final url = "${AppConstants.baseUrl}/vehicles/$vid";
      final res = await http.delete(Uri.parse(url), headers: headers);
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  // 3. Update Status (Tick = 1, Cross = Delete)
  static Future<bool> updateVehicleStatus(int vid, int status) async {
    try {
      if (status == -1) { // Cross button logic
        final res = await http.delete(Uri.parse("${AppConstants.baseUrl}/vehicles/delete/$vid"), headers: headers);
        return res.statusCode == 200;
      } else { // Tick button logic
        final res = await http.put(
            Uri.parse("${AppConstants.baseUrl}/vehicles/updatestatus/$vid?status=$status"),
            headers: headers
        );
        return res.statusCode == 200;
      }
    } catch (e) { return false; }
  }

  // ApiService.dart mein ye copy kar lo
  static Future<bool> addProblem(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse("${AppConstants.baseUrl}/problems/addprob");

      // Backend ke field names ke saath exact match
      final body = jsonEncode({
        "ptitle": data['title'],
        "pdescription": data['description'],
        "ptype": data['category'].toString().toLowerCase(),
        "type": data['type'],
        "uid": data['uid']
      });

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json", ...headers},
        body: body,
      );

      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  static Future<bool> updateProblem(Map<String, dynamic> problemData) async {
    try {
      int pid = problemData['pid']; // Object se ID nikalo
      final url = "${AppConstants.baseUrl}/problems/$pid"; // Yeh route tumhare C# se match karega

      final res = await http.put(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(problemData), // Pura object bhejo
      );

      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteProblem(int pid) async {
    try {
      // Tumhare backend route {pid:int} se match kar raha hai
      final url = Uri.parse("${AppConstants.baseUrl}/problems/$pid");

      final res = await http.delete(
          url,
          headers: headers
      );

      // Status 200 aana chahiye
      return res.statusCode == 200;
    } catch (e) {
      print("Delete Error: $e");
      return false;
    }

  }
//----------------------------------------------update profile---//
// --- Profile Fetch ---
  static Future<Map<String, dynamic>?> getExpertProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // 🔥 Yahan 'userId' use karein (kyunke login mein humne userId save ki thi)
      int? uid = prefs.getInt('userId');

      final url = "${AppConstants.baseUrl}/users/Currentuser?uid=$uid";
      print("DEBUG: Fetching profile for UID: $uid"); // Console mein check karne ke liye

      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
      return null;
    } catch (e) { return null; }
  }
  // --- Profile Update (With Image) ---
  static Future<List<dynamic>> fetchSolutionsByVehicleAndProblem(int vid, int pid) async {
    try {
      // Ye wala URL Expert ka naam (ExpertName) bhejta hai
      final url = "${AppConstants.baseUrl}/vehicles/$vid/problems/$pid/solutions";

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Backend se 'solutions' ki key mein data aa raha hai
        List<dynamic> solutions = data['solutions'] ?? data['Solutions'] ?? [];

        print("Data mil gaya: ${solutions.length} records");
        return solutions;
      }
      return [];
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  // ApiService.dart mein ye add karein
  static Future<List<dynamic>> fetchStepsBySolutionId(int sid) async {
    try {
      final url = "${AppConstants.baseUrl}/steps/$sid";
      final res = await http.get(Uri.parse(url), headers: headers);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        // Backend response mein 'steps' naam ki key hai
        return data['steps'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error fetching steps: $e");
      return [];
    }
  }

  // --- Profile Update (With Image) ---
  // --- Profile Update (With Image) ---
  static Future<bool> updateExpertProfile(Map<String, dynamic> data, File? image) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // 🔥 FIX: 'saved_uid' ko 'userId' se badal diya kyunke login mein 'userId' save ho raha hai
      int? uid = prefs.getInt('userId');

      final url = "${AppConstants.baseUrl}/users/updateexpertprofile";
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);

      request.fields['uid'] = uid.toString();
      request.fields['username'] = data['username'] ?? "";
      request.fields['oldpassword'] = data['oldPass'] ?? "";
      request.fields['newpassword'] = data['newPass'] ?? "";
      request.fields['category'] = data['category'] ?? "Electrical";

      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath('profileImage', image.path));
      }

      var streamedRes = await request.send();
      var res = await http.Response.fromStream(streamedRes);

      print("DEBUG: Update Response Code: ${res.statusCode} for UID: $uid");
      return res.statusCode == 200;
    } catch (e) {
      print("DEBUG: Exception in updateExpertProfile: $e");
      return false;
    }
  }



  static Future<List<dynamic>> getAllUsers() async {
    try {
      // 🚩 URL FIX: Controller ka RoutePrefix + Route name
      final url = "${AppConstants.baseUrl}/users/getallusers";

      print("Fetching from: $url");
      final response = await http.get(
          Uri.parse(url),
          headers: headers
      );

      print("Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Aapke C# Controller mein direct list return ho rahi hai,
        // is liye '$values' ki zaroorat nahi parni chahiye, lekin safety ke liye dono check rakhin
        return data is List ? data : (data['\$values'] ?? []);
      }
      return [];
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }
  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";

    // Base URL se /api hatane ke liye (iOS wala logic)
    String baseUrl = AppConstants.baseUrl;
    if (baseUrl.endsWith("/api")) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    } else if (baseUrl.endsWith("/api/")) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 5);
    }

    // Agar path ke shuru mein / nahi hai to laga do
    String cleanPath = path.replaceAll(r'\', '/');
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }

    return baseUrl + cleanPath;
  }
  // 1. Approved Experts Fetch karne ke liye
  static Future<List<dynamic>> getApprovedExperts() async {
    try {
      final url = "${AppConstants.baseUrl}/users/getapprovedexperts";
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        // Agar backend direct list de raha hai to theek, warna $values check karo
        return data is List ? data : (data['\$values'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. Pending Experts Fetch karne ke liye (Approval ke liye wait kar rahe hain)
  static Future<List<dynamic>> getPendingExperts() async {
    try {
      final url = "${AppConstants.baseUrl}/users/getpendingexperts";
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data is List ? data : (data['\$values'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 3. Expert ko Approve karne ke liye (PUT method)
  static Future<bool> approveExpert(int uid) async {
    try {
      final url = "${AppConstants.baseUrl}/users/approveexpert/$uid";
      final response = await http.put(Uri.parse(url), headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 4. Admin panel se direct naya Expert add karne ke liye
  static Future<bool> addExpertAdmin(String name, String password, String category) async {
    try {
      final url = "${AppConstants.baseUrl}/users/addexpertadmin";
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json", ...headers},
        body: json.encode({
          "username": name,
          "password": password,
          "category": category,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 5. User/Expert ko delete karne ke liye
  static Future<bool> deleteUser(int uid) async {
    try {
      final url = "${AppConstants.baseUrl}/users/$uid";
      final response = await http.delete(Uri.parse(url), headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  // 1. User ki Default Vehicle ID lane ke liye (iOS Flow)
  // Purane getDefaultVehicleId ko is se replace kar dein
  static Future<Map<String, dynamic>?> getUserProfile(int uid) async {
    try {
      final url = "${AppConstants.baseUrl}/users/Currentuser?uid=$uid";
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
      return null;
    } catch (e) {
      print("Profile Fetch Error: $e");
      return null;
    }
  }

  // 2. User ki saari gariyan lane ke liye
  static Future<List<dynamic>> getUserVehicles(int uid) async {
    try {
      final url = "${AppConstants.baseUrl}/vps/user-vehicles/$uid";
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        // Agar backend direct list de raha hai to theek, warna key check karein
        if (data is List) return data;
        return data['vehicles'] ?? data['\$values'] ?? [];
      }
      return [];
    } catch (e) { return []; }
  }



  // User ki car save karne ke liye (vid = Vehicle ID)
  // Agar POST kaam nahi kar raha, toh isse replace karke check karein
// 'void' ki jagah 'Future<bool>' likhein
  static Future<bool> addUserVehicle({
    required int uid,
    required int vid,
    required bool isDefault,
  }) async {
    try {
      final String url = "${AppConstants.baseUrl}/users/$uid/vehicles";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "69420",
        },
        body: jsonEncode({
          "vid": vid,
          "isDefault": isDefault,
        }),
      );

      if (response.statusCode == 200) {
        print("Gaari add ho gayi!");
        return true; // <--- Yeh zaroori hai
      } else {
        print("Backend Error: ${response.statusCode}");
        return false; // <--- Yeh zaroori hai
      }
    } catch (e) {
      print("Connection Error: $e");
      return false; // <--- Yeh zaroori hai
    }
  }

  static Future<bool> updateProfile({
    required int uid,
    required String username,
    String? oldPass,
    String? newPass,
    File? image,
  }) async {
    try {
      // 1. URL wahi use karein jo aapke backend mein [Route("updateexpertprofile")] hai
      final url = "${AppConstants.baseUrl}/users/updateexpertprofile";

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);

      // 2. Kye names exact C# controller wale hone chahiye
      request.fields['uid'] = uid.toString();
      request.fields['username'] = username;
      request.fields['oldpassword'] = oldPass ?? ""; // C# mein 'oldpassword' lowercase hai
      request.fields['newpassword'] = newPass ?? ""; // C# mein 'newpassword' lowercase hai
      request.fields['category'] = "Electrical";    // Default category bhejni lazmi hai kyunke backend parse kar raha hai

      // 3. Image handle karein
      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profileImage', // Backend IFormFile ka naam
          image.path,
        ));
      }


      var streamedRes = await request.send();
      var res = await http.Response.fromStream(streamedRes);

      print("DEBUG: Status Code: ${res.statusCode}");
      print("DEBUG: Response Body: ${res.body}");

      return res.statusCode == 200;
    } catch (e) {
      print("Error updating profile: $e");
      return false;
    }
  }
// 1. Solution ki detail aur steps fetch karna (iOS: loadInitialData)
  static Future<Map<String, dynamic>?> fetchSolutionDetails(int sid) async {
    try {
      // API Route: GET api/solutions/{sid}
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/solutions/$sid'), headers: headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Fetch Solution Detail Error: $e");
    }
    return null;
  }

  // 2. Solution ka Title update karna (iOS: updateCompleteSolution -> Step 1)
  // 1. Purana Step update karna (Description aur StepNo)
  static Future<bool> updateStep({required int stepId, required String description, int stepNo = 1}) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/steps/$stepId');
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json", ...headers},
        body: json.encode({
          "stepid": stepId,
          "stepDescription": description,
          "stepNo": stepNo,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

// 2. Step ki Image update karna (Specific Route)
  static Future<bool> updateStepImage(int stepId, File imageFile, {String? description, int? stepNo}) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/steps/$stepId/image');
      var request = http.MultipartRequest('PUT', url);
      request.headers.addAll(headers);

      // Image file add karein
      request.files.add(await http.MultipartFile.fromPath('stepImg', imageFile.path));

      // Agar sath mein description ya stepNo bhi bhejna ho (form-data mein)
      if (description != null) request.fields['stepDescription'] = description;
      if (stepNo != null) request.fields['stepNo'] = stepNo.toString();

      var streamedRes = await request.send();
      return streamedRes.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

// 3. Naya Step add karna (iOS: uploadstepwithimage wala kaam)
  static Future<bool> uploadNewStep({required int sid, required int stepNo, required String description, required File imageFile}) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/steps/add');
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      request.fields['sid'] = sid.toString();
      request.fields['stepNo'] = stepNo.toString();
      request.fields['stepDescription'] = description;

      request.files.add(await http.MultipartFile.fromPath('stepImg', imageFile.path));

      var streamedRes = await request.send();
      return streamedRes.statusCode == 200 || streamedRes.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
  // ApiService.dart mein isay add karein
  static Future<bool> updateSolutionTitle(int sid, String title) async {
    try {
      // Backend route: api/solutions/{sid}
      final url = Uri.parse('${AppConstants.baseUrl}/solutions/$sid');

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          ...headers // ngrok headers include karne ke liye
        },
        body: json.encode({
          "sid": sid,
          "stitle": title // Backend key 'stitle' check karlein agar title hai toh wo likhein
        }),
      );

      print("Title Update Status: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating solution title: $e");
      return false;
    }
  }

  // Active/Inactive toggle karne ke liye (Sama as iOS: disableexpert/{uid})
  static Future<bool> disableExpert(int uid) async {
    try {
      final url = "${AppConstants.baseUrl}/users/disableexpert/$uid";
      final response = await http.put(Uri.parse(url), headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      print("Toggle Status Error: $e");
      return false;
    }
  }
//////////////////////////////////////////////////New
  static Future<List<dynamic>> getAllSolutions() async {
    try {
      // 🚩 EXACT URL jo aapne chrome mein check kiya
      final url = "${AppConstants.baseUrl}/expertsolutions";

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Chrome response ke mutabiq 'assignments' key se data nikalna hai
        if (data.containsKey('assignments') && data['assignments'] is List) {
          print("Data mil gaya! Total: ${data['total']}");
          return data['assignments'];
        }
      }
      return [];
    } catch (e) {
      print("Fetch Error: $e");
      return [];
    }
  }

  // Sirf Admin ke liye alag function
  static Future<List<dynamic>> fetchStepsForAdmin(int sid) async {
    try {
      final url = "${AppConstants.baseUrl}/steps/$sid";
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        // Admin logic: steps key check karo
        if (data is Map && data.containsKey('steps')) return data['steps'];
        return data is List ? data : (data['\$values'] ?? []);
      }
      return [];
    } catch (e) { return []; }
  }

  static Future<bool> approveSolution(int sid) async {
    try {
      final url = "${AppConstants.baseUrl}/users/approvesolution/$sid";
      final response = await http.put(Uri.parse(url), headers: headers);
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

// ApiService.dart ke andar ye naya function add karein
  static String getAdminImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";

    // Base URL se /api hatane wala logic (Sirf Admin/iOS ke liye)
    String baseUrl = AppConstants.baseUrl;
    if (baseUrl.endsWith("/api")) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    } else if (baseUrl.endsWith("/api/")) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 5);
    }

    String cleanPath = path.replaceAll(r'\', '/');
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }

    return baseUrl + cleanPath;
  }

  // --- DELETE STEP (iOS Synchronized Logic) ---
  static Future<bool> deleteStep(int stepId) async {
    try {
      // Backend Route matching iOS: DELETE api/steps/{id}
      final url = Uri.parse("${AppConstants.baseUrl}/steps/$stepId");

      final response = await http.delete(
        url,
        headers: headers, // ngrok skip browser warning headers
      );

      print("Delete Step Status: ${response.statusCode}");

      // Agar backend 200 (OK) ya 204 (No Content) return kare
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Delete Step Error: $e");
      return false;
    }
  }
  // --- NEW: Expert Ranking for Admin (iOS Flow) ---
  static Future<List<dynamic>> fetchExpertRankings() async {
    try {
      // Same iOS endpoint
      final url = "${AppConstants.baseUrl}/users/getapprovedexperts";
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List<dynamic> experts = [];

        if (data is List) {
          experts = data;
        } else if (data is Map && data.containsKey('\$values')) {
          experts = data['\$values'];
        }

        // iOS Logic: Sorting by Overall Rating (Highest to Lowest)
        experts.sort((a, b) {
          double ratingA = double.tryParse(a['overallRating']?.toString() ?? '0') ?? 0.0;
          double ratingB = double.tryParse(b['overallRating']?.toString() ?? '0') ?? 0.0;
          return ratingB.compareTo(ratingA);
        });

        return experts;
      }
      return [];
    } catch (e) {
      print("Ranking API Error: $e");
      return [];
    }
  }


  // ApiService.dart mein niche ye add karein
  static Future<Map<String, dynamic>?> fetchExpertPerformance(int uid) async {
    try {
      // Route exact yahi hona chahiye: users/ExpertPerformance
      final url = "${AppConstants.baseUrl}/users/expertperformance/$uid";
      print("DEBUG: API URL: $url");

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      print("DEBUG: API Error Code: ${response.statusCode}");
      return null;
    } catch (e) {
      return null;
    }
  }


// 1. Gaariyon ki list lane ke liye (Filter Dropdown)
  static Future<List<String>> fetchAvailableMakes() async {
    try {
      final url = "${AppConstants.baseUrl}/vehicles/make";
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List<String> makes = List<String>.from(jsonResponse['makes'] ?? []);
        makes.sort();
        return ["All", ...makes]; // "All" ka option khud add kiya
      }
      return ["All"];
    } catch (e) {
      return ["All"];
    }
  }
////////////////////////////smmj yh
// 2. Dashboard ka main data (Solutions + Brand Score)
  static Future<Map<String, dynamic>?> fetchExpertDashboardData(int eid, String make) async {
    try {
      // 🔥 Make parameter URL mein pass ho raha hai
      final url = "${AppConstants.baseUrl}/expertsolutions/expert/$eid?make=$make";
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body); // Poora object return hoga (solutions aur filteredOverallRating)
      }
      return null;
    } catch (e) {
      return null;
    }
  }
// --- Admin Dashboard Counts (iOS Synchronized) ---
  static Future<Map<String, int>> fetchAdminDashboardCounts() async {
    try {
      // Backend Endpoint: api/users/admin/counts
      final url = "${AppConstants.baseUrl}/users/admin/counts";

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);

        // Map<String, dynamic> ko Map<String, int> mein convert kar rahe hain
        return decodedData.map((key, value) => MapEntry(key, int.tryParse(value.toString()) ?? 0));
      }
      return {}; // Error ki surat mein empty map
    } catch (e) {
      print("Counts Fetch Error: $e");
      return {};
    }
  }

  // 1. Check karna ke user ne is step ko pehle rate kiya hai ya nahi
  // Route: api/stepfeedback/get/{stepid}
  static Future<List<dynamic>> getStepFeedback(int stepId) async {
    try {
      final url = "${AppConstants.baseUrl}/stepfeedback/get/$stepId";
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ratings'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. Step ki rating submit karna (Native wala logic)
  // Route: api/stepfeedback/add
  static Future<bool> submitStepFeedback({
    required int stepId,
    required int sid,
    required int uid,
    required int rating,
    required String review,
  }) async {
    try {
      final url = "${AppConstants.baseUrl}/stepfeedback/add";
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json", ...headers},
        body: json.encode({
          "stepid": stepId,
          "sid": sid,
          "uid": uid,
          "srating": rating,
          "sreview": review.trim()
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }



  static Future<List<dynamic>> fetchStepRatings(int stepId) async {
    try {
      final response = await http.get(
        Uri.parse("${AppConstants.baseUrl}/stepfeedback/get/$stepId"),
        headers: {"ngrok-skip-browser-warning": "69420"},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ratings'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- NEW: Vehicle ki Rating base par Top Problem lana (iOS Synchronized) ---
  static Future<String?> fetchTopRatedProblem(int vid) async {
    try {
      // Exact iOS endpoint: expertsolutions/vehicle/{vid}/top-rated-problem
      final url = "${AppConstants.baseUrl}/expertsolutions/vehicle/$vid/top-rated-problem";

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend se 'problemTitle' key mein data aa raha hai
        return data['problemTitle'] as String?;
      }
      return null;
    } catch (e) {
      print("Error fetching top rated problem: $e");
      return null;
    }
  }

  }




