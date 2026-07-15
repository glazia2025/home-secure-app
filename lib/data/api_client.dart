import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  Uri _uri(String path) => Uri.parse('$baseUrl/api$path');

  Uri liveFeedUri({required String token, required String hubId}) {
    final uri = Uri.parse(baseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(
      scheme: wsScheme,
      path: '/ws/live-feed',
      queryParameters: {
        'role': 'viewer',
        'mode': 'webrtc',
        'token': token,
        'hubId': hubId,
      },
    );
  }

  Uri cameraStreamUri(String streamPath) {
    final uri = Uri.parse(baseUrl);
    return uri.replace(
      path: streamPath,
      queryParameters: {'t': DateTime.now().millisecondsSinceEpoch.toString()},
    );
  }

  Map<String, String> _headers([String? token]) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    final dynamic body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body as Map<String, dynamic>;
    }

    final message = body is Map<String, dynamic>
        ? body['message'] as String? ??
              body['error'] as String? ??
              'Request failed'
        : 'Request failed';
    throw ApiException(message);
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _http.post(
      _uri('/auth/register'),
      headers: _headers(),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final body = await _decode(response);
    return AppUser.fromJson(body['user'] as Map<String, dynamic>);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _http.post(
      _uri('/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = await _decode(response);
    return AuthSession(
      token: body['token'] as String? ?? '',
      user: AppUser.fromJson(body['user'] as Map<String, dynamic>),
      homes: (body['homes'] as List<dynamic>? ?? const [])
          .map((item) => Home.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<OtpRequestResult> requestOtp({required String phoneNumber}) async {
    final response = await _http.post(
      _uri('/auth/otp/request'),
      headers: _headers(),
      body: jsonEncode({'phoneNumber': phoneNumber}),
    );
    final body = await _decode(response);
    return OtpRequestResult.fromJson(body);
  }

  Future<OtpVerifyResult> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final response = await _http.post(
      _uri('/auth/otp/verify'),
      headers: _headers(),
      body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp}),
    );
    final body = await _decode(response);
    return OtpVerifyResult.fromJson(body);
  }

  Future<AuthSession> completeOtpRegistration({
    required String otpSessionId,
    required String name,
    required String email,
    required String phoneNumber,
  }) async {
    final response = await _http.post(
      _uri('/auth/otp/register'),
      headers: _headers(),
      body: jsonEncode({
        'otpSessionId': otpSessionId,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
      }),
    );
    final body = await _decode(response);
    return AuthSession(
      token: body['token'] as String? ?? '',
      user: AppUser.fromJson(body['user'] as Map<String, dynamic>),
      homes: (body['homes'] as List<dynamic>? ?? const [])
          .map((item) => Home.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<AuthSession> me(String token) async {
    final response = await _http.get(
      _uri('/auth/me'),
      headers: _headers(token),
    );
    final body = await _decode(response);
    return AuthSession(
      token: token,
      user: AppUser.fromJson(body['user'] as Map<String, dynamic>),
      homes: (body['homes'] as List<dynamic>? ?? const [])
          .map((item) => Home.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<Home>> homes(String token) async {
    final response = await _http.get(_uri('/homes'), headers: _headers(token));
    final body = await _decode(response);
    return (body['homes'] as List<dynamic>? ?? const [])
        .map((item) => Home.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SetupSession> startHubSetup({
    required String token,
    required String hubMacAddress,
    required String homeName,
    required String location,
  }) async {
    final response = await _http.post(
      _uri('/homes/setup-hub'),
      headers: _headers(token),
      body: jsonEncode({
        'hubMacAddress': hubMacAddress,
        'homeName': homeName,
        'location': location,
      }),
    );
    final body = await _decode(response);
    return SetupSession.fromJson(body['setupSession'] as Map<String, dynamic>);
  }

  Future<PairSensorResult> pairSensor({
    required String token,
    required String homeId,
    required String sensorMacAddress,
    required String name,
    required String zone,
    String type = 'contact',
  }) async {
    final response = await _http.post(
      _uri('/homes/$homeId/sensors/pair'),
      headers: _headers(token),
      body: jsonEncode({
        'sensorMacAddress': sensorMacAddress,
        'name': name,
        'type': type,
        'zone': zone,
      }),
    );
    final body = await _decode(response);
    return PairSensorResult.fromJson(body);
  }

  Future<void> deleteSensor({
    required String token,
    required String homeId,
    required String sensorId,
  }) async {
    final response = await _http.delete(
      _uri('/homes/$homeId/sensors/$sensorId'),
      headers: _headers(token),
    );
    await _decode(response);
  }

  Future<Map<String, dynamic>> setSensorEnabled({
    required String token,
    required String homeId,
    required String sensorId,
    required bool enabled,
  }) async {
    final response = await _http.patch(
      _uri('/homes/$homeId/sensors/$sensorId/enabled'),
      headers: _headers(token),
      body: jsonEncode({'enabled': enabled}),
    );
    return _decode(response);
  }

  Future<void> deleteHub({
    required String token,
    required String homeId,
  }) async {
    final response = await _http.delete(
      _uri('/homes/$homeId'),
      headers: _headers(token),
    );
    await _decode(response);
  }

  Future<DoorLockCommand> openDoorLock({
    required String token,
    required String homeId,
  }) async {
    final response = await _http.post(
      _uri('/homes/$homeId/door-lock/open'),
      headers: _headers(token),
    );
    final body = await _decode(response);
    return DoorLockCommand.fromJson(
      body['command'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<DoorLockCommand?> latestDoorLockCommand({
    required String token,
    required String homeId,
  }) async {
    final response = await _http.get(
      _uri('/homes/$homeId/door-lock'),
      headers: _headers(token),
    );
    final body = await _decode(response);
    final command = body['command'];
    if (command is! Map<String, dynamic>) return null;
    return DoorLockCommand.fromJson(command);
  }

  Future<String> createCameraStreamPath({
    required String token,
    required String homeId,
  }) async {
    final response = await _http.post(
      _uri('/homes/$homeId/camera/stream-token'),
      headers: _headers(token),
    );
    final body = await _decode(response);
    final streamPath = body['streamPath'] as String? ?? '';
    if (streamPath.isEmpty) {
      throw const ApiException('Camera stream path missing');
    }
    return streamPath;
  }

  Future<List<AppNotification>> notifications(String token) async {
    final response = await _http.get(
      _uri('/notifications'),
      headers: _headers(token),
    );
    final body = await _decode(response);
    return (body['notifications'] as List<dynamic>? ?? const [])
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AppNotification> markNotificationRead(
    String token,
    String notificationId,
  ) async {
    final response = await _http.patch(
      _uri('/notifications/$notificationId/read'),
      headers: _headers(token),
    );
    final body = await _decode(response);
    return AppNotification.fromJson(
      body['notification'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteNotification(String token, String notificationId) async {
    final response = await _http.delete(
      _uri('/notifications/$notificationId'),
      headers: _headers(token),
    );
    await _decode(response);
  }

  Future<void> clearNotifications(String token) async {
    final response = await _http.delete(
      _uri('/notifications'),
      headers: _headers(token),
    );
    await _decode(response);
  }

  Future<void> registerPushToken({
    required String token,
    required String pushToken,
    required String platform,
  }) async {
    final response = await _http.post(
      _uri('/notifications/push-token'),
      headers: _headers(token),
      body: jsonEncode({'token': pushToken, 'platform': platform}),
    );
    await _decode(response);
  }

  Future<void> unregisterPushToken({
    required String token,
    required String pushToken,
  }) async {
    final response = await _http.delete(
      _uri('/notifications/push-token'),
      headers: _headers(token),
      body: jsonEncode({'token': pushToken}),
    );
    await _decode(response);
  }

  Stream<AppNotification> notificationStream(String token) async* {
    final request = http.Request('GET', _uri('/notifications/stream'));
    request.headers.addAll({
      'Accept': 'text/event-stream',
      'Authorization': 'Bearer $token',
    });

    final response = await _http.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Notification stream failed with status ${response.statusCode}',
      );
    }

    var eventName = '';
    final dataLines = <String>[];
    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.isEmpty) {
        if (eventName == 'notification' && dataLines.isNotEmpty) {
          yield AppNotification.fromJson(
            jsonDecode(dataLines.join('\n')) as Map<String, dynamic>,
          );
        }
        eventName = '';
        dataLines.clear();
        continue;
      }

      if (line.startsWith('event:')) {
        eventName = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trim());
      }
    }
  }
}
