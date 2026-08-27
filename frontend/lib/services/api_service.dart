import 'dart:convert';
import 'package:http/http.dart' as http;

/// Handles all HTTP communication with the Bharosa Pay FastAPI backend.
///
/// Screens must NOT make http calls directly — they call methods on
/// this class instead. This keeps networking logic in one place and
/// keeps the UI code simple.
///
/// This file does NOT talk to Supabase and does NOT calculate any
/// trust score — the backend is the only source of truth for that.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // TODO: Replace with the real deployed backend URL once available.
  // Using 10.0.2.2 works for the Android emulator to reach a FastAPI
  // server running on your machine's localhost. On a real physical
  // Android phone, replace this with your machine's LAN IP (e.g.
  // http://192.168.x.x:8000) or the deployed backend URL.
static const String _baseUrl =
    'https://web-production-c5b77.up.railway.app';
    
  static const Duration _timeout = Duration(seconds: 15);

  /// Sends the decoded UPI QR payload to the backend for verification.
  ///
  /// Returns the parsed JSON response as a Map, exactly as the backend
  /// sent it (trust_classification, trust_score, merchant_name, reasons).
  /// This method does not interpret or transform that data — it is
  /// handed back as-is for the screens/models to use.
  ///
  /// Throws an [ApiException] with a user-friendly message if the
  /// request fails for any reason (no network, backend down, bad
  /// response, etc.) so the calling screen can show an appropriate
  /// error instead of crashing.
  Future<Map<String, dynamic>> verifyQr(String qrPayload) async {
    final uri = Uri.parse('$_baseUrl/verify-qr');

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'qr_payload': qrPayload}),
          )
          .timeout(_timeout);
    } on http.ClientException {
      throw ApiException(
        'Could not reach the server. Please check your internet connection.',
      );
    } catch (_) {
      throw ApiException(
        'Something went wrong while checking this QR. Please try again.',
      );
    }

    return _parseJsonResponse(response);
  }

  /// Reports a suspicious/incorrect QR to the backend.
  ///
  /// [qrPayload] is the raw scanned QR string, [category] must be one
  /// of the backend-supported categories (e.g. QR_APPEARS_TAMPERED).
  ///
  /// Returns the parsed JSON response (e.g. {"status": "received"}).
  Future<Map<String, dynamic>> reportQr({
    required String qrPayload,
    required String category,
  }) async {
    final uri = Uri.parse('$_baseUrl/report-qr');

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'qr_payload': qrPayload,
              'category': category,
            }),
          )
          .timeout(_timeout);
    } on http.ClientException {
      throw ApiException(
        'Could not reach the server. Please check your internet connection.',
      );
    } catch (_) {
      throw ApiException(
        'Something went wrong while submitting your report. Please try again.',
      );
    }

    return _parseJsonResponse(response);
  }

  /// Shared response handling for both endpoints:
  ///   - Checks the HTTP status code.
  ///   - Safely decodes the JSON body.
  ///   - Wraps any failure into a single, consistent [ApiException].
  Map<String, dynamic> _parseJsonResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'The server returned an error (status ${response.statusCode}). Please try again.',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException('The server sent back an unexpected response.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw ApiException('The server sent back an unexpected response.');
    }

    return decoded;
  }

  /// Releases the underlying HTTP client's resources.
  /// Call this when ApiService is no longer needed (e.g. in dispose()
  /// of whatever widget owns it), if you created it without passing
  /// in your own client.
  void dispose() {
    _client.close();
  }
}

/// Thrown by [ApiService] whenever a request fails for any reason.
///
/// [message] is safe to show directly to the user.
class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}