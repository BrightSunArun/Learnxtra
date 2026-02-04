// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.learnxtra.in';

  Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ───────────────────────────────────────────────
  //  New: Admin Login Method
  // ───────────────────────────────────────────────
  Future<Map<String, dynamic>?> adminLogin({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/admin/login');

      final response = await http.post(
        uri,
        headers: _defaultHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print(
            'POST /api/admin/login → ${response.statusCode} ${response.reasonPhrase}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e, stack) {
      print('Admin login error: $e');
      print(stack);
      return null;
    }
  }

  // ───────────────────────────────────────────────
  //  Existing methods (unchanged)
  // ───────────────────────────────────────────────

  Future<Map<String, dynamic>?> _get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: headers ?? _defaultHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print(
            'GET $endpoint → ${response.statusCode} ${response.reasonPhrase}');
        print('Body: ${response.body}');
        return null;
      }
    } catch (e, stack) {
      print('GET error on $endpoint: $e');
      print(stack);
      return null;
    }
  }

  Future<Map<String, dynamic>?> _put(
    String endpoint, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http.put(
        uri,
        headers: headers ?? _defaultHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>?;
      } else {
        print(
            'PUT $endpoint → ${response.statusCode} ${response.reasonPhrase}');
        print('Body: ${response.body}');
        return null;
      }
    } catch (e, stack) {
      print('PUT error on $endpoint: $e');
      print(stack);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDashboardOverview() async {
    return _get('/api/admin/dashboard/overview');
  }

  Future<Map<String, dynamic>?> getScreenTimePolicy() async {
    return _get('/api/admin/policies/screen-time');
  }

  Future<Map<String, dynamic>?> getQuestions({
    required int grade,
    required String board,
    int page = 1,
  }) async {
    return _get(
      '/api/admin/questions',
      queryParams: {
        'grade': grade.toString(),
        'board': board,
        'page': page.toString(),
      },
    );
  }

  Future<Map<String, dynamic>?> getSystemControls() async {
    return _get('/api/admin/system/controls');
  }

  Future<Map<String, dynamic>?> updateScreenTimePolicy({
    required int totalQuizQuestions,
    required int minQuizPassScore,
  }) async {
    final body = {
      'totalQuizQuestions': totalQuizQuestions,
      'minQuizPassScore': minQuizPassScore,
    };

    return _put(
      '/api/admin/policies/screen-time',
      body: body,
    );
  }

  Future<Map<String, dynamic>?> getLearningGatePolicy() async {
    return _get('/api/admin/policies/learning-gate');
  }
}
