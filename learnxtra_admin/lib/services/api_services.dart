// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://api.learnxtra.in';

  Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

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

  Future<Map<String, dynamic>?> _post(
    String endpoint, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http.post(
        uri,
        headers: headers ?? _defaultHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = response.body;
        if (responseBody.isEmpty) return <String, dynamic>{};
        return jsonDecode(responseBody) as Map<String, dynamic>?;
      } else {
        print(
            'POST $endpoint → ${response.statusCode} ${response.reasonPhrase}');
        print('Body: ${response.body}');
        return null;
      }
    } catch (e, stack) {
      print('POST error on $endpoint: $e');
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

  Future<bool> _delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      final response = await http.delete(
        uri,
        headers: headers ?? _defaultHeaders,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print(
            'DELETE $endpoint → ${response.statusCode} ${response.reasonPhrase}');
        print('Body: ${response.body}');
        return false;
      }
    } catch (e, stack) {
      print('DELETE error on $endpoint: $e');
      print(stack);
      return false;
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

  Future<Map<String, dynamic>?> getGlobalPolicies() async {
    return _get('/api/admin/global-policies');
  }

  Future<bool> updateGlobalPolicy({
    required String policyId,
    required String type,
    required Map<String, dynamic> data,
    String? createdAt,
    String? updatedAt,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'data': data,
    };
    if (createdAt != null) body['created_at'] = createdAt;
    if (updatedAt != null) body['updated_at'] = updatedAt;
    final result = await _put(
      '/api/admin/global-policies/$policyId',
      body: body,
    );
    return result != null;
  }

  Future<Map<String, dynamic>?> getAllQuestionsNoFilter() async {
    return _get('/api/admin/questions');
  }

  Future<Map<String, dynamic>?> getParentsChildDetail() async {
    return _get('/api/admin/parents-child-detail');
  }

  Future<Map<String, dynamic>?> updateQuestion({
    required String grade,
    required String board,
    required String subject,
    required String questionId,
    required String questionText,
    required String option1,
    required String option2,
    required String option3,
    required String option4,
    required String correctAnswer,
  }) async {
    final body = {
      'question_text': questionText,
      'options': {
        "A": option1,
        "B": option2,
        "C": option3,
        "D": option4,
      },
      'correct_answer': correctAnswer,
    };

    return _put(
      '/api/admin/questions/$questionId',
      body: body,
    );
  }

  Future<Map<String, dynamic>?> createQuestion({
    required String grade,
    required String board,
    required String questionText,
    required String option1,
    required String option2,
    required String option3,
    required String option4,
    required String correctAnswer,
    required String subject,
  }) async {
    return _post(
      '/api/admin/questions',
      body: {
        'grade': grade,
        'board': board,
        'question_text': questionText,
        'options': {
          "A": option1,
          "B": option2,
          "C": option3,
          "D": option4,
        },
        'correct_answer': correctAnswer,
        'subject': subject,
      },
    );
  }

  Future<bool> deleteQuestion(String questionId) async {
    return _delete('/api/admin/questions/$questionId');
  }

  Future<Map<String, dynamic>?> createBoard({required String name}) async {
    return _post(
      '/api/admin/boards',
      body: {'name': name},
    );
  }

  Future<Map<String, dynamic>?> createGrade({
    required String name,
  }) async {
    return _post(
      '/api/admin/grades',
      body: {'name': name},
    );
  }

  Future<Map<String, dynamic>?> createSubject({
    required int gradeId,
    required String name,
    required String boardId,
  }) async {
    return _post(
      '/api/admin/subjects',
      body: {
        'board_id': boardId,
        'grade_id': gradeId,
        'name': name,
      },
    );
  }

  Future<Map<String, dynamic>?> getBoards() async {
    return _get('/api/admin/boards');
  }

  Future<Map<String, dynamic>?> updateBoard({
    required int id,
    required String name,
  }) async {
    return _put(
      '/api/admin/boards/$id',
      body: {'name': name},
    );
  }

  Future<Map<String, dynamic>?> getGrades({int? boardId}) async {
    return _get('/api/admin/grades');
  }

  Future<Map<String, dynamic>?> updateGrade({
    required int id,
    required String name,
  }) async {
    return _put(
      '/api/admin/grades/$id',
      body: {'name': name},
    );
  }

  Future<Map<String, dynamic>?> getSubjects({int? gradeId}) async {
    return _get('/api/admin/subjects');
  }

  Future<Map<String, dynamic>?> getSosRequests() async {
    return _get('/api/admin/sos-requests');
  }

  Future<Map<String, dynamic>?> getRegistrationStats({
    required String type,
    required int year,
    int? month,
  }) async {
    final params = <String, String>{
      'type': type,
      'year': year.toString(),
    };
    if (month != null) params['month'] = month.toString();
    return _get('/api/admin/registration-stats', queryParams: params);
  }

  Future<Map<String, dynamic>?> updateSubject({
    required int id,
    required int gradeId,
    required String boardId,
    required String name,
  }) async {
    return _put(
      '/api/admin/subjects/$id',
      body: {
        'board_id': boardId,
        'grade_id': gradeId,
        'name': name,
      },
    );
  }

  Future<bool> deleteBoard(int boardId) async {
    return _delete('/api/admin/boards/$boardId');
  }

  Future<bool> deleteGrade(int gradeId) async {
    return _delete('/api/admin/grades/$gradeId');
  }

  Future<bool> deleteSubject(int subjectId) async {
    return _delete('/api/admin/subjects/$subjectId');
  }
}
