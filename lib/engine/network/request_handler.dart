import 'dart:io';
import 'dart:convert';
import 'package:dsc_mobile_rework/engine/storage/device/secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class RequestHandler {
  final localStorage = SecureStorage();
  final requestHeaders = <String, String>{
  'authorization': 'null',
  'Content-Type': 'application/json; charset=UTF-8',
  };

  // Singleton instance
  static final RequestHandler _requestHandler = RequestHandler._internal();

  // Public factory constructor for accessing the singleton instance
  factory RequestHandler() {
    return _requestHandler;
  }

  // Private named constructor
  RequestHandler._internal();

  static Future<File> saveDataToFolder(String folderName, String fileName, String data) async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final saveFile = File('${appDocumentsDir.path}/$folderName/$fileName');
    return saveFile.writeAsString(data);
  }

  static Future<Map> loadDataFromFolder(String folderName, String fileName) async {
    try {
      final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
      final loadFile = File('${appDocumentsDir.path}/$folderName/$fileName');

      // Read the file
      final contents = await loadFile.readAsString();
      //print("load complete");
      //print(contents);
      return jsonDecode(contents) as Map<String, dynamic>;
    } catch (e) {
      // If encountering an error, return empty dictionary
      print("error in loading");
      return {};
    }
  }

  Future<void> requestNewUser(String newEmail, String newPassword) async {
    final requestBody = '{"user":{"email":"$newEmail","password":"$newPassword","referral_code":null,"source":"app"}}';

    final response = await http.post(
      Uri.parse('https://dsc-api-service-23350212163.us-central1.run.app/api/users'),
      headers: requestHeaders,
      body: requestBody,
    );

    if (response.statusCode == 200) {
      print("New user created successfully: ${response.body}");
      //saveDataToFolder("download", "surveyParameters.json", response.body);
    } else {
      // If the server did not return a 201 CREATED response,
      // then throw an exception.
      print("Failed to fetch parameters. Status code: ${response.statusCode}");
    }
  }

  Future<void> requestSession(String email, String password) async {
    final requestBody = '{"session":{"email":"$email","password":"$password"}}';

    final response = await http.post(
      Uri.parse('https://dsc-api-service-23350212163.us-central1.run.app/api/sessions'),
      headers: requestHeaders,
      body: requestBody,
    );

    if (response.statusCode == 200) {
      print("Session started successfully: ${response.body}");
      //saveDataToFolder("download", "reportParameters.json", response.body);
      //need an equivalent save reports to folder function here
    } else {
      // If the server did not return a 201 CREATED response,
      // then throw an exception.
      print("Failed to download reports. Status code: ${response.statusCode}");
      print("Error explanation: ${response.body}");
    }
  }

}