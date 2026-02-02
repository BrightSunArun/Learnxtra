import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic details;

  ApiException({
    this.statusCode,
    required this.message,
    this.details,
  });

  factory ApiException.fromResponse(http.Response response) {
    dynamic parsedBody;
    String message = 'Unknown error';
    try {
      if (response.body.isNotEmpty) {
        parsedBody = jsonDecode(response.body);
        if (parsedBody is Map && parsedBody['message'] != null) {
          message = parsedBody['message'].toString();
        } else {
          message = response.body;
        }
      } else {
        message = response.reasonPhrase ?? 'No response body';
      }
    } catch (_) {
      message = response.body.isNotEmpty
          ? response.body
          : response.reasonPhrase ?? 'Unknown error';
      parsedBody = response.body;
    }

    return ApiException(
      statusCode: response.statusCode,
      message: message,
      details: parsedBody,
    );
  }

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, message: $message, details: $details)';
  }
}
