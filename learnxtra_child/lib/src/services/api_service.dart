import 'dart:convert';
import 'package:LearnXtraChild/src/utils/api_exception.dart';
import 'package:http/http.dart' as http;

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
    required String childId,
    required int grade,
    required String board,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/$childId/quiz/start';

    final body = {
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

  Future<Map<String, dynamic>> getSosStatus({
    required String sosId,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/sos/$sosId/status';

    final mergedHeaders = _mergeHeaders(extraHeaders);
    final uri = _buildUri(path);

    final response =
        await http.get(uri, headers: mergedHeaders).timeout(timeout);

    return _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitQuizAnswer({
    required String childId,
    required String questionId,
    required String selectedAnswer,
    Map<String, String>? extraHeaders,
  }) async {
    final path = 'child/quiz/$childId/answer';

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
}
