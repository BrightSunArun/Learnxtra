import 'dart:convert';
import 'package:LearnXtraChild/src/utils/api_exception.dart';
import 'package:http/http.dart' as http;

class SosStatusResponse {
  final String id;
  final String childId;
  final String status;
  final String? approvedBy;
  final String? approvedAt;
  final String createdAt;
  final String updatedAt;

  SosStatusResponse({
    required this.id,
    required this.childId,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SosStatusResponse.fromJson(Map<String, dynamic> json) {
    return SosStatusResponse(
      id: json['id'] as String? ?? '',
      childId: json['child_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  bool get isApproved => status == 'approved';
}

class ApiService {
  final Map<String, String> defaultHeaders;
  final Duration timeout;

  ApiService({
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    this.timeout = const Duration(seconds: 30),
  });

  final String baseUrl = 'https://api.learnxtra.in/api/';

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final uri = Uri.parse(baseUrl + path);
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(queryParameters: queryParameters);
  }

  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    return {...defaultHeaders, if (headers != null) ...headers};
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final merged = _mergeHeaders(headers);

    final response = await http.get(uri, headers: merged).timeout(timeout);
    return _handleResponse(response);
  }

  Future<dynamic> post(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final merged = _mergeHeaders(headers);
    final encoded = _encodeBody(body, merged);

    final response =
        await http.post(uri, headers: merged, body: encoded).timeout(timeout);
    return _handleResponse(response);
  }

  Future<dynamic> put(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final merged = _mergeHeaders(headers);
    final encoded = _encodeBody(body, merged);

    final response =
        await http.put(uri, headers: merged, body: encoded).timeout(timeout);
    return _handleResponse(response);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final merged = _mergeHeaders(headers);
    final encoded = _encodeBody(body, merged);

    final response =
        await http.delete(uri, headers: merged, body: encoded).timeout(timeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> linkChildDevice({
    required String childLinkCode,
    required String deviceUuid,
    Map<String, String>? extraHeaders,
  }) async {
    const path = 'child/link-device';

    final body = {
      "childLinkCode": childLinkCode,
      "deviceInfo": {
        "uuid": deviceUuid,
      }
    };

    final mergedHeaders = _mergeHeaders(extraHeaders);
    final uri = _buildUri(path);
    final encodedBody = jsonEncode(body);
    final response = await http
        .post(
          uri,
          headers: mergedHeaders,
          body: encodedBody,
        )
        .timeout(timeout);
    return _handleResponse(response) as Map<String, dynamic>;
  }

  dynamic _encodeBody(dynamic body, Map<String, String> headers) {
    if (body == null) return null;
    final contentType = headers['Content-Type'] ?? '';
    if (contentType.contains('application/json')) {
      return jsonEncode(body);
    }
    return body;
  }

  dynamic _handleResponse(http.Response response) {
    final status = response.statusCode;
    final body = response.body;

    if (status >= 200 && status < 300) {
      if (body.isEmpty) return null;
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }

    throw ApiException.fromResponse(response);
  }

  Future<Map<String, dynamic>> startQuiz({
    required String subject,
    required String childId,
    required int grade,
    required String board,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/$childId/quiz/start';

    final body = {
      "subject": subject,
      "grade": grade,
      "board": board,
    };

    final mergedHeaders = _mergeHeaders(extraHeaders);
    final uri = _buildUri(path);

    final response = await http
        .post(
          uri,
          headers: mergedHeaders,
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendSosRequest({
    required String childId,
    required String reason,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/$childId/sos/request';

    final body = {
      "reason": reason,
    };

    final mergedHeaders = _mergeHeaders(extraHeaders);
    final uri = _buildUri(path);

    final response = await http
        .post(
          uri,
          headers: mergedHeaders,
          body: jsonEncode(body),
        )
        .timeout(timeout);

    return _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getQuizConfig({
    required String childId,
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/$childId/quiz/config';
    final mergedHeaders = _mergeHeaders(extraHeaders);
    final uri = _buildUri(path, queryParameters);

    final response =
        await http.get(uri, headers: mergedHeaders).timeout(timeout);

    return _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLockStatus({
    required String childId,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/$childId/lock-status';

    final mergedHeaders = _mergeHeaders(extraHeaders);
    final uri = _buildUri(path);

    final response =
        await http.get(uri, headers: mergedHeaders).timeout(timeout);

    return _handleResponse(response) as Map<String, dynamic>;
  }

  /// GET /api/child/sos/{sosId}/status — returns SOS request status (e.g. approved, pending).
  Future<SosStatusResponse> getSosStatus({
    required String sosId,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/sos/$sosId/status';

    final mergedHeaders = _mergeHeaders(extraHeaders);
    final uri = _buildUri(path);

    final response =
        await http.get(uri, headers: mergedHeaders).timeout(timeout);

    final data = _handleResponse(response) as Map<String, dynamic>;
    return SosStatusResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> submitQuizAnswer({
    required String sessionId,
    required String questionId,
    required String selectedAnswer,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/quiz/$sessionId/answer';

    final body = {
      "questionId": questionId,
      "selectedAnswer": selectedAnswer,
    };

    final mergedHeaders = _mergeHeaders(extraHeaders);
    final uri = _buildUri(path);

    final response = await http
        .post(
          uri,
          headers: mergedHeaders,
          body: jsonEncode(body),
        )
        .timeout(timeout);

    return _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeQuiz({
    required String quizId,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/quiz/$quizId/complete';

    final mergedHeaders = _mergeHeaders(extraHeaders);
    final uri = _buildUri(path);

    final response = await http
        .post(
          uri,
          headers: mergedHeaders,
        )
        .timeout(timeout);

    return _handleResponse(response) as Map<String, dynamic>;
  }

  Future<dynamic> getEmergencyContacts({
    required String parentId,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/emergency-contacts/$parentId';

    final mergedHeaders = _mergeHeaders(extraHeaders);
    final uri = _buildUri(path);

    final response =
        await http.get(uri, headers: mergedHeaders).timeout(timeout);

    return _handleResponse(response);
  }

  Future<dynamic> getScreenTime({
    required String childId,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/$childId/screen-time';

    final mergedHeaders = _mergeHeaders(extraHeaders);
    final uri = _buildUri(path);

    final response =
        await http.get(uri, headers: mergedHeaders).timeout(timeout);

    return _handleResponse(response);
  }

  Future<dynamic> getUsageChart({
    required String childId,
    required String type,
    required int year,
    required int month,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/$childId/usage-chart';
    final queryParameters = {
      'type': type,
      'year': year.toString(),
      'month': month.toString(),
    };
    final mergedHeaders = _mergeHeaders(extraHeaders);
    final uri = _buildUri(path, queryParameters);

    final response =
        await http.get(uri, headers: mergedHeaders).timeout(timeout);

    return _handleResponse(response);
  }

  Future<dynamic> getPerformanceChart({
    required String childId,
    required String type,
    required int year,
    required int month,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/$childId/performance-chart';
    final queryParameters = {
      'type': type,
      'year': year.toString(),
      'month': month.toString(),
    };
    final mergedHeaders = _mergeHeaders(extraHeaders);
    final uri = _buildUri(path, queryParameters);

    final response =
        await http.get(uri, headers: mergedHeaders).timeout(timeout);

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> unlockParentMode({
    required String childId,
    required String pinCode,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/$childId/parent-mode/unlock';

    final body = {
      "pin_code": pinCode,
    };

    final mergedHeaders = _mergeHeaders(extraHeaders);
    final uri = _buildUri(path);

    final response = await http
        .post(
          uri,
          headers: mergedHeaders,
          body: jsonEncode(body),
        )
        .timeout(timeout);

    return _handleResponse(response) as Map<String, dynamic>;
  }

  Future<List<String>> getAdminSubjects({
    Map<String, String>? extraHeaders,
  }) async {
    final decoded = await get('admin/subjects', headers: extraHeaders);
    if (decoded == null) return [];
    if (decoded is Map<String, dynamic>) {
      final list = decoded['data'];
      if (list is List) {
        return list
            .map((e) {
              if (e is Map && e['name'] != null) {
                return e['name'].toString();
              }
              return null;
            })
            .whereType<String>()
            .toList();
      }
    }
    return [];
  }
}
