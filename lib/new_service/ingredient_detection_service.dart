import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';

class IngredientDetectionService {
  static String get _url => ApiEndpoints.detectQty;

  Future<Map<String, dynamic>> detectIngredients(XFile image, {String userId = "U1"}) async {
    final startTime = DateTime.now();
    debugPrint("🚀 [IngredientDetectionService] Starting detection at: ${startTime.millisecondsSinceEpoch}");
    debugPrint("🌐 [API] Request to: $_url");

    try {
      var request = http.MultipartRequest("POST", Uri.parse(_url));
      request.fields['userId'] = userId;
      
      // Specify content type to avoid Vertex AI application/octet-stream error
      request.files.add(await http.MultipartFile.fromPath(
        "file", 
        image.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      final endTime = DateTime.now();
      debugPrint("📌 [API] Response received in ${endTime.difference(startTime).inMilliseconds}ms");
      debugPrint("📄 [API] Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return data;
        } else {
          throw Exception("API returned ok: false");
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ [IngredientDetectionService] Error: $e");
      rethrow;
    }
  }
}
