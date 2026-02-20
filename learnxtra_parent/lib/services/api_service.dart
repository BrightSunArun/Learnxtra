// ignore_for_file: avoid_print, unnecessary_this

import 'dart:convert';
import 'package:LearnXtraParent/services/token_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:LearnXtraParent/utils/api_endpoints.dart';
import 'package:LearnXtraParent/utils/api_exception.dart';

class ApiService extends GetxService {
  final token = RxnString();
  final refreshToken = RxnString();

  final Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final Duration timeout = const Duration(seconds: 30);

  final String baseUrl = 'https://api.learnxtra.in/api/';

  void setToken(String? newToken) {
    token.value = newToken;
    if (newToken != null && newToken.isNotEmpty) {
      TokenStorage.saveToken(newToken);
      print("Token saved to secure storage");
    } else {
      TokenStorage.deleteToken();
      print("Token cleared from secure storage");
    }
    print(
      "\n\nToken set on ApiService ${this.hashCode}: ${token.value}\n\n",
    );
  }

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    token.value = accessToken;
    this.refreshToken.value = refreshToken;

    await TokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    print(
        "\n\nSet both tokens on ApiService ${this.hashCode}. accessToken=${token.value}, refreshToken set\n\n");
  }

  Future<void> clearTokens() async {
    token.value = null;
    refreshToken.value = null;
    await TokenStorage.clearAll();
    print("Cleared both access and refresh tokens from storage");
  }

  void clearToken() {
    setToken(null);
  }

  Future<void> init() async {
    final stored = await TokenStorage.getToken();
    final storedRefresh = await TokenStorage.getRefreshToken();
    if (stored != null && stored.isNotEmpty) {
      token.value = stored;
      print(
        "Loaded token from storage into ApiService ${this.hashCode}: ${token.value}",
      );
    } else {
      print(
        "No access token found in storage for ApiService ${this.hashCode}",
      );
    }

    if (storedRefresh != null && storedRefresh.isNotEmpty) {
      refreshToken.value = storedRefresh;
      print(
        "Loaded refresh token from storage into ApiService ${this.hashCode}",
      );
    } else {
      print(
        "No refresh token found in storage for ApiService ${this.hashCode}",
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    TokenStorage.getToken().then(
      (stored) {
        if (stored != null && stored.isNotEmpty) {
          token.value = stored;
          print(
            "onInit loaded token for ApiService ${this.hashCode}: ${token.value}",
          );
        }
      },
    );

    TokenStorage.getRefreshToken().then(
      (storedRefresh) {
        if (storedRefresh != null && storedRefresh.isNotEmpty) {
          refreshToken.value = storedRefresh;
          print(
            "onInit loaded refresh token for ApiService ${this.hashCode}",
          );
        }
      },
    );
  }

  Map<String, String> _getAuthHeaders([Map<String, String>? extraHeaders]) {
    final headers = <String, String>{...defaultHeaders};

    final currentToken = token.value;
    if (currentToken == null || currentToken.isEmpty) {
      throw ApiException(
        message: "Authentication token is missing or empty",
        statusCode: 401,
      );
    }

    headers['Authorization'] = 'Bearer $currentToken';

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final uri = Uri.parse(baseUrl + path);
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(queryParameters: queryParameters);
  }

  Map<String, String> _mergeHeaders({
    Map<String, String>? extraHeaders,
    bool requireAuth = true,
  }) {
    if (requireAuth) {
      return _getAuthHeaders(extraHeaders);
    }
    final headers = <String, String>{...defaultHeaders};
    if (extraHeaders != null) headers.addAll(extraHeaders);
    return headers;
  }

  String? _encodeBody(dynamic body, Map<String, String> headers) {
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

  Future<bool> _refreshToken() async {
    final currentRefresh = refreshToken.value;
    if (currentRefresh == null || currentRefresh.isEmpty) {
      print("No refresh token available to refresh access token");
      return false;
    }

    try {
      final uri = _buildUri('auth/refresh');
      final headers = <String, String>{...defaultHeaders};
      final body = jsonEncode({'refreshToken': currentRefresh});

      final response =
          await http.post(uri, headers: headers, body: body).timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = decoded['accessToken'] as String?;
        final newRefresh = decoded['refreshToken'] as String?;

        if (newAccess == null || newRefresh == null) {
          print(
              "Refresh endpoint returned success but missing tokens: $decoded");
          return false;
        }

        await setTokens(accessToken: newAccess, refreshToken: newRefresh);
        print("Successfully refreshed tokens via auth/refresh");
        return true;
      }

      print(
          "Refresh endpoint returned non-success status: ${response.statusCode}");
      return false;
    } catch (e) {
      print("Error while refreshing token: $e");
      return false;
    }
  }

  Future<dynamic> _performRequest(
    String method,
    String path, {
    Map<String, String>? headers,
    dynamic body,
    Map<String, String>? queryParameters,
    bool requireAuth = true,
  }) async {
    final uri = _buildUri(path, queryParameters);
    Map<String, String> merged;
    try {
      merged = _mergeHeaders(extraHeaders: headers, requireAuth: requireAuth);
    } on ApiException catch (e) {
      print("Error while merging headers: $e");
      rethrow;
    }

    final encoded = _encodeBody(body, merged);

    final request = http.Request(method, uri);
    request.headers.addAll(merged);
    if (encoded != null) {
      request.body = encoded;
    }

    var streamedResponse = await request.send().timeout(timeout);
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401 && requireAuth) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        final newMerged =
            _mergeHeaders(extraHeaders: headers, requireAuth: requireAuth);
        final retryRequest = http.Request(method, uri);
        retryRequest.headers.addAll(newMerged);
        if (encoded != null) retryRequest.body = encoded;

        final retryStream = await retryRequest.send().timeout(timeout);
        response = await http.Response.fromStream(retryStream);
      } else {
        throw ApiException.fromResponse(response);
      }
    }

    return _handleResponse(response);
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    bool requireAuth = true,
  }) async {
    return _performRequest(
      'GET',
      path,
      headers: headers,
      queryParameters: queryParameters,
      requireAuth: requireAuth,
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    Map<String, String>? queryParameters,
    bool requireAuth = true,
  }) async {
    return _performRequest(
      'POST',
      path,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
      requireAuth: requireAuth,
    );
  }

  Future<dynamic> _put(
    String path, {
    Map<String, String>? headers,
    dynamic body,
    Map<String, String>? queryParameters,
    bool requireAuth = true,
  }) async {
    print('→ PUT request starting: $path');
    print('  • requireAuth   : $requireAuth');
    print('  • query params  : ${queryParameters ?? "<none>"}');
    print('  • has body      : ${body != null}');
    if (body != null) {
      // Be careful — don't print huge bodies or sensitive data in production!
      print('  • body type     : ${body.runtimeType}');
      // Uncomment only when needed and safe:
      // print('  • body preview  : ${body.toString().substring(0, body.toString().length.clamp(0, 500))}');
    }
    print('  • custom headers: ${headers?.keys.toList() ?? "<none>"}');

    try {
      print('  → Calling _performRequest...');

      final result = await _performRequest(
        'PUT',
        path,
        headers: headers,
        body: body,
        queryParameters: queryParameters,
        requireAuth: requireAuth,
      );

      print('  ✓ PUT request completed successfully for: $path');
      // print('  • Response type : ${result.runtimeType}'); // uncomment if needed

      return result;
    } catch (e, stackTrace) {
      print('  ✗ PUT request FAILED for: $path');
      print('  • Error type    : ${e.runtimeType}');
      print('  • Error message : $e');
      print('  • Stack trace   :');
      print('    ${stackTrace.toString().split('\n').take(8).join('\n    ')}');

      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateEmergencyContact({
    required String id,
    required String name,
    required String relation,
    required String phoneNumber,
    bool isActive = true,
  }) async {
    final body = {
      "name": name,
      "relation": relation,
      "phone_number": phoneNumber,
      "is_active": isActive,
    };

    final path = '${ApiEndpoints.emergencyContacts}/$id';

    final response = await _put(
      path,
      body: body,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format when updating emergency contact',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> deleteEmergencyContact(String id) async {
    final path = '${ApiEndpoints.emergencyContacts}/$id';

    final response = await _performRequest(
      'DELETE',
      path,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format when deleting emergency contact',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> sendOtp(String mobileNumber) async {
    final body = {"mobileNumber": mobileNumber};

    final response = await post(
      ApiEndpoints.sendOTP,
      body: body,
      requireAuth: false,
    );

    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    final body = {
      "mobileNumber": mobileNumber,
      "otp": otp,
    };

    final response = await post(
      ApiEndpoints.verifyOTP,
      body: body,
      requireAuth: false,
    );

    return response as Map<String, dynamic>;
  }

  Future<dynamic> getSubjects() async {
    final response = await get(
      'admin/subjects',
      requireAuth: false,
    );
    return response;
  }

  Future<dynamic> getGrades() async {
    final response = await get(
      'admin/grades',
      requireAuth: false,
    );
    return response;
  }

  Future<dynamic> getBoards({String? name}) async {
    final response = await _performRequest(
      'GET',
      'admin/boards',
      requireAuth: false,
    );
    return response;
  }

  Future<Map<String, dynamic>> addChild({
    required String name,
    required int grade,
    required String board,
    required int age,
    required String state,
    required String schoolName,
    required String schoolAddress,
  }) async {
    print(
        "\n\naddChild called on ApiService instance ${this.hashCode}, token: ${token.value}\n\n");

    final body = {
      "name": name,
      "grade": grade,
      "board": board,
      "age": age,
      "state": state,
      "schoolName": schoolName,
      "schoolAddress": schoolAddress,
    };

    final response = await post(
      ApiEndpoints.child,
      body: body,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format when adding child',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> updateChildProfile({
    required String childId,
    required String name,
    required int grade,
    required String board,
    required int age,
    required String state,
    required String schoolName,
    required String schoolAddress,
    required List<String> subjects,
  }) async {
    print(
        "\n\nupdateChildProfile called on ApiService instance ${this.hashCode}, token: ${token.value}\n\n");

    final body = {
      "name": name,
      "grade": grade,
      "board": board,
      "age": age,
      "state": state,
      "schoolName": schoolName,
      "schoolAddress": schoolAddress,
      "subjects": subjects
    };

    final path = '${ApiEndpoints.child}/$childId';

    final response = await _put(
      path,
      body: body,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format when updating child profile',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> saveChildSettings({
    required String childId,
    required int dailyUnlockCount,
    required int unlockDuration,
  }) async {
    print(
        "\n\nsaveChildSettings called on ApiService instance ${this.hashCode}, token: ${token.value}\n\n");

    final body = {
      "defaultDailyUnlocks": dailyUnlockCount,
      "defaultUnlockDuration": unlockDuration
    };

    final path = '${ApiEndpoints.child}/$childId/current-unlock-session';

    final response = await post(
      path,
      body: body,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format when saving child settings',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> generateChildCode({
    required String childId,
    Map<String, dynamic>? requestBody,
  }) async {
    print(
        "\n\ngenerateChildCode called on ApiService instance ${this.hashCode}, token: ${token.value}\n\n");

    final body = requestBody ?? {};

    final path = 'child/$childId/generate-code';

    final response = await post(
      path,
      body: body.isEmpty ? null : body,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format from generate-child-code',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> addEmergencyContact({
    required String name,
    required String relation,
    required String phoneNumber,
  }) async {
    final body = {
      "name": name,
      "relation": relation,
      "phoneNumber": phoneNumber,
    };

    final response = await post(
      ApiEndpoints.emergencyContacts,
      body: body,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format when adding emergency contact',
      statusCode: 500,
    );
  }

  Future<List<dynamic>> getEmergencyContacts() async {
    final response = await get(
      ApiEndpoints.emergencyContacts,
    );

    if (response is List<dynamic>) {
      return response;
    }

    if (response is Map<String, dynamic> && response['data'] is List) {
      return response['data'] as List<dynamic>;
    }

    throw ApiException(
      message: 'Unexpected response format from emergency contacts',
      statusCode: 500,
    );
  }

  Future<List<dynamic>> getSosRequests() async {
    final response = await get(
      'sos-requests',
      requireAuth: true,
    );

    if (response is List<dynamic>) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      if (response['data'] is List<dynamic>) {
        return response['data'] as List<dynamic>;
      }
      if (response['requests'] is List<dynamic>) {
        return response['requests'] as List<dynamic>;
      }
    }

    throw ApiException(
      message: 'Unexpected response format from SOS requests list',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> approveSosRequest(String sosRequestId) async {
    final path = 'sos-requests/$sosRequestId/approve';

    final response = await post(
      path,
      body: {},
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format when approving SOS request',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> rejectSosRequest(String sosRequestId) async {
    final path = 'sos-requests/$sosRequestId/reject';

    final response = await post(
      path,
      body: {},
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format when rejecting SOS request',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> getParentDashboard() async {
    final response = await get(
      ApiEndpoints.parentDashboard,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format from parent dashboard',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> getParentProfile() async {
    final response = await get(
      ApiEndpoints.parentProfile,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format from get parent profile',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> createParentProfile({
    required String fullName,
    required String email,
    String profileImageUrl = '',
    required String address,
    required String pinCode,
    required String mobileNumber,
  }) async {
    final body = {
      "fullName": fullName,
      "email": email,
      "profileImageUrl": profileImageUrl,
      "address": address,
      "pinCode": pinCode,
      "mobile_number": mobileNumber,
    };

    final response = await post(
      ApiEndpoints.parentProfile,
      body: body,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format from create parent profile',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> updateParentProfile({
    required String fullName,
    required String email,
    String? profileImageUrl,
    required String address,
    required int pinCode,
  }) async {
    final body = <String, dynamic>{};

    if (fullName.isNotEmpty) body['fullName'] = fullName;
    if (email.isNotEmpty) body['email'] = email;
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      body['profileImageUrl'] = profileImageUrl;
    }
    if (address.isNotEmpty) body['address'] = address;
    body['pinCode'] = pinCode;

    if (body.isEmpty) {
      throw ApiException(
        message: 'No fields provided to update in parent profile',
        statusCode: 400,
      );
    }

    final response = await _put(
      ApiEndpoints.parentProfile,
      body: body,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format from update parent profile',
      statusCode: 500,
    );
  }

  /// DELETE parent account. Uses parentId in URL. requireAuth = true.
  Future<Map<String, dynamic>> deleteParent(String parentId) async {
    final path = 'parent/$parentId';

    final response = await _performRequest(
      'DELETE',
      path,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format from delete parent',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> getChildLearningProgress(String childId) async {
    final path = 'child/$childId/learning-progress';
    final response = await get(
      path,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is Map<String, dynamic> && response['data'] is Map) {
      return response['data'] as Map<String, dynamic>;
    }

    throw ApiException(
      message: 'Unexpected response format from child learning progress',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> getChildDetails(String childId) async {
    final path = '${ApiEndpoints.child}/$childId';

    final response = await get(
      path,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format from get child details',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> deleteChild(String childId) async {
    final path = '${ApiEndpoints.child}/$childId';

    final response = await _performRequest(
      'DELETE',
      path,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format from delete child',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> createChildScreenTime({
    required String childId,
    required int dailyUnlockCount,
    required int unlockDurationMinutes,
    required String startTime,
    required String endTime,
  }) async {
    final body = {
      "childId": childId,
      "dailyUnlockCount": dailyUnlockCount,
      "unlockDurationMinutes": unlockDurationMinutes,
      "start_time": startTime,
      "end_time": endTime,
    };

    print("\n\ncreateChildScreenTime called - childId: $childId, "
        "daily: $dailyUnlockCount, duration: $unlockDurationMinutes mins\n\n");

    final response = await post(
      'child/screen-time',
      body: body,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format when creating screen-time session',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> getChildScreenTime(String childId) async {
    final path = 'child/$childId/screen-time';

    print(
        "\n\ngetChildScreenTime called for childId: $childId on ApiService ${this.hashCode}\n\n");

    final response = await get(
      path,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      return response['data'] as Map<String, dynamic>;
    }

    throw ApiException(
      message: 'Unexpected response format from get child screen-time',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> updateChildScreenTime({
    required String childId,
    required int defaultDailyUnlocks,
    required int defaultUnlockDuration,
    required String startTime,
    required String endTime,
  }) async {
    final body = <String, dynamic>{};

    body["defaultDailyUnlocks"] = defaultDailyUnlocks;
    body["defaultUnlockDuration"] = defaultUnlockDuration;
    if (startTime.trim().isNotEmpty) {
      body["start_time"] = startTime.trim();
    }
    if (endTime.trim().isNotEmpty) {
      body["end_time"] = endTime.trim();
    }

    if (body.isEmpty) {
      throw ApiException(
        message: 'No fields provided to update screen-time settings',
        statusCode: 400,
      );
    }

    final path = '$childId/screen-time';

    print('┌───────────────────────────────────────────────');
    print('│ updateChildScreenTime for child: $childId');
    print('│ Fields to update : ${body.keys.join(', ')}');
    print('│ Payload preview  : ${jsonEncode(body)}');
    print('└───────────────────────────────────────────────');

    // Force correct headers — this fixes most Postman-vs-Flutter mismatches
    final customHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      final response = await _put(
        path,
        body: body,
        headers: customHeaders, // ← crucial line
        requireAuth: true,
      );

      print('┌───────────────────────────────────────────────');
      print('│ updateChildScreenTime SUCCESS');
      print('│ Raw response type: ${response.runtimeType}');
      print('└───────────────────────────────────────────────');

      if (response is Map<String, dynamic>) {
        return response;
      }

      if (response is Map<String, dynamic> &&
          response['data'] is Map<String, dynamic>) {
        return response['data'] as Map<String, dynamic>;
      }

      throw ApiException(
        message: 'Unexpected response format from update screen-time',
        statusCode: 500,
      );
    } catch (e, stack) {
      print('┌───────────────────────────────────────────────');
      print('│ updateChildScreenTime FAILED');
      print('│ Error          : $e');
      print('│ Stack (first 5):');
      print('│   ${stack.toString().split("\n").take(5).join("\n│   ")}');
      print('└───────────────────────────────────────────────');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> setParentPin({
    required String parentId,
    required String pinCode,
  }) async {
    final path = 'parent/$parentId/pin/set';

    final body = {
      "pin_code": pinCode,
    };

    final response = await post(
      path,
      body: body,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format when setting parent PIN',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> changeParentPin({
    required String parentId,
    required String oldPin,
    required String newPin,
  }) async {
    final path = 'parent/$parentId/pin/change';

    final body = {
      "old_pin": oldPin,
      "new_pin": newPin,
    };

    final response = await post(
      path,
      body: body,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format when changing parent PIN',
      statusCode: 500,
    );
  }

  Future<Map<String, dynamic>> getParentPinStatus({
    required String parentId,
  }) async {
    final path = 'parent/$parentId/pin/status';

    final response = await get(
      path,
      requireAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw ApiException(
      message: 'Unexpected response format from parent PIN status',
      statusCode: 500,
    );
  }

  Future<dynamic> getParentPerformance({
    required String parentId,
    required String childId,
    required int year,
    required int month,
    String type = 'yearly',
  }) async {
    final path = 'parent-performance/$parentId';
    final queryParams = <String, String>{
      'type': type,
      'child_id': childId,
      'year': year.toString(),
      'month': month.toString(),
    };
    return get(path, queryParameters: queryParams, requireAuth: true);
  }

  Future<dynamic> getParentUsage({
    required String parentId,
    required String childId,
    required int year,
    required int month,
    String type = 'yearly',
  }) async {
    final path = 'parent-usage/$parentId';
    final queryParams = <String, String>{
      'type': type,
      'child_id': childId,
      'year': year.toString(),
      'month': month.toString(),
    };
    return get(path, queryParameters: queryParams, requireAuth: true);
  }
}
