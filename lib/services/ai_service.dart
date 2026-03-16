import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_models.dart';

class AIService {
  static String get _baseUrl {
    return 'https://cognify-backend.onrender.com/api';
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

  Future<List<dynamic>> getHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/history'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        print('Error fetching history: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception in getHistory: $e');
      return [];
    }
  }
}
