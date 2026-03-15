import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_models.dart';

class AIService {
  // Use 10.0.2.2 for Android emulator to access localhost, otherwise localhost
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    } else {
      return 'http://localhost:8000/api';
    }
  }

  Future<SimplifyResponse?> simplifyText(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/simplify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        return SimplifyResponse.fromJson(jsonDecode(response.body));
      } else {
        print('Error simplifying text: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception in simplifyText: $e');
      return null;
    }
  }

  Future<QuizResponse?> generateQuiz(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/quiz'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        return QuizResponse.fromJson(jsonDecode(response.body));
      } else {
        print('Error generating quiz: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception in generateQuiz: $e');
      return null;
    }
  }
}
