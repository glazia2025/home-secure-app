import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';
import 'models.dart';

class AppRepository {
  AppRepository({SharedPreferences? preferences})
    : _preferencesFuture = preferences == null
          ? SharedPreferences.getInstance()
          : Future.value(preferences);

  static const tokenKey = 'auth_token';
  static const hubRulesPrefix = 'hub_rules';
  static const sensorManualPrefix = 'sensor_manual';
  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://home-secure.glazia.in',
  );

  final Future<SharedPreferences> _preferencesFuture;
  ApiClient? _apiClient;

  Future<String> getBaseUrl() async {
    return defaultBaseUrl;
  }

  Future<ApiClient> apiClient() async {
    final baseUrl = await getBaseUrl();
    final client = _apiClient;
    if (client != null && client.baseUrl == baseUrl) {
      return client;
    }
    return _apiClient = ApiClient(baseUrl: baseUrl);
  }

  Future<void> saveBaseUrl(String baseUrl) async {
    final trimmed = baseUrl.trim().replaceAll(RegExp(r'/$'), '');
    _apiClient = ApiClient(baseUrl: trimmed);
  }

  Future<String?> token() async {
    final preferences = await _preferencesFuture;
    return preferences.getString(tokenKey);
  }

  Future<void> saveToken(String token) async {
    final preferences = await _preferencesFuture;
    await preferences.setString(tokenKey, token);
  }

  Future<void> clearToken() async {
    final preferences = await _preferencesFuture;
    await preferences.remove(tokenKey);
  }

  Future<AuthSession> login(String email, String password) async {
    final client = await apiClient();
    final session = await client.login(email: email, password: password);
    await saveToken(session.token);
    return session;
  }

  Future<AuthSession> register(
    String name,
    String email,
    String password,
  ) async {
    final client = await apiClient();
    await client.register(name: name, email: email, password: password);
    return login(email, password);
  }

  Future<OtpRequestResult> requestOtp(String phoneNumber) async {
    final client = await apiClient();
    return client.requestOtp(phoneNumber: phoneNumber);
  }

  Future<OtpVerifyResult> verifyOtp(String phoneNumber, String otp) async {
    final client = await apiClient();
    final result = await client.verifyOtp(phoneNumber: phoneNumber, otp: otp);
    final session = result.session;
    if (session != null) {
      await saveToken(session.token);
    }
    return result;
  }

  Future<AuthSession> completeOtpRegistration({
    required String otpSessionId,
    required String name,
    required String email,
    required String phoneNumber,
  }) async {
    final client = await apiClient();
    final session = await client.completeOtpRegistration(
      otpSessionId: otpSessionId,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
    );
    await saveToken(session.token);
    return session;
  }

  Future<AuthSession?> restoreSession() async {
    final savedToken = await token();
    if (savedToken == null) return null;
    try {
      final client = await apiClient();
      return client.me(savedToken);
    } catch (_) {
      await clearToken();
      rethrow;
    }
  }

  Future<List<Home>> homes() async {
    final savedToken = await token();
    if (savedToken == null) return const [];
    final client = await apiClient();
    return client.homes(savedToken);
  }

  Future<List<AppNotification>> notifications() async {
    final savedToken = await token();
    if (savedToken == null) return const [];
    final client = await apiClient();
    return client.notifications(savedToken);
  }

  Future<SetupSession> startHubSetup({
    required String hubMacAddress,
    required String homeName,
    required String location,
  }) async {
    final savedToken = await _requireToken();
    final client = await apiClient();
    return client.startHubSetup(
      token: savedToken,
      hubMacAddress: hubMacAddress,
      homeName: homeName,
      location: location,
    );
  }

  Future<PairSensorResult> pairSensor({
    required Home home,
    required String eui,
    required String cc,
    required String v,
    required String name,
    required String zone,
  }) async {
    final savedToken = await _requireToken();
    final client = await apiClient();
    return client.pairSensor(
      token: savedToken,
      homeId: home.id,
      eui: eui,
      cc: cc,
      v: v,
      name: name,
      zone: zone,
    );
  }

  Future<void> deleteSensor({
    required Home home,
    required Sensor sensor,
  }) async {
    final savedToken = await _requireToken();
    final client = await apiClient();
    await client.deleteSensor(
      token: savedToken,
      homeId: home.id,
      sensorId: sensor.id,
    );
    final preferences = await _preferencesFuture;
    await preferences.remove('$sensorManualPrefix:${sensor.id}');
  }

  Future<void> deleteHub(Home home) async {
    final savedToken = await _requireToken();
    final client = await apiClient();
    await client.deleteHub(token: savedToken, homeId: home.id);
  }

  Future<DoorLockCommand> openDoorLock(Home home) async {
    final savedToken = await _requireToken();
    final client = await apiClient();
    return client.openDoorLock(token: savedToken, homeId: home.id);
  }

  Future<DoorLockCommand?> latestDoorLockCommand(Home home) async {
    final savedToken = await _requireToken();
    final client = await apiClient();
    return client.latestDoorLockCommand(token: savedToken, homeId: home.id);
  }

  Future<AppNotification> markNotificationRead(String notificationId) async {
    final savedToken = await _requireToken();
    final client = await apiClient();
    return client.markNotificationRead(savedToken, notificationId);
  }

  Future<void> deleteNotification(String notificationId) async {
    final savedToken = await _requireToken();
    final client = await apiClient();
    await client.deleteNotification(savedToken, notificationId);
  }

  Future<void> clearNotifications() async {
    final savedToken = await _requireToken();
    final client = await apiClient();
    await client.clearNotifications(savedToken);
  }

  Future<void> registerPushToken(String pushToken, String platform) async {
    final savedToken = await _requireToken();
    final client = await apiClient();
    await client.registerPushToken(
      token: savedToken,
      pushToken: pushToken,
      platform: platform,
    );
  }

  Future<void> unregisterPushToken(String pushToken) async {
    final savedToken = await _requireToken();
    final client = await apiClient();
    await client.unregisterPushToken(token: savedToken, pushToken: pushToken);
  }

  Future<Stream<AppNotification>> notificationStream() async {
    final savedToken = await _requireToken();
    final client = await apiClient();
    return client.notificationStream(savedToken);
  }

  Future<LiveFeedSignalingSession> liveFeedSignalingSession(Home home) async {
    final savedToken = await _requireToken();
    final client = await apiClient();
    return LiveFeedSignalingSession(
      WebSocketChannel.connect(
        client.liveFeedUri(token: savedToken, hubId: home.hub.id),
      ),
    );
  }

  Future<HubRuleSettings> hubRuleSettings(Home home) async {
    final preferences = await _preferencesFuture;
    final raw = preferences.getString('$hubRulesPrefix:${home.hub.id}');
    if (raw == null || raw.isEmpty) {
      return HubRuleSettings.defaults(home.hub.id, home.sensors);
    }

    try {
      return HubRuleSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
        home.sensors,
      );
    } catch (_) {
      return HubRuleSettings.defaults(home.hub.id, home.sensors);
    }
  }

  Future<void> saveHubRuleSettings(HubRuleSettings settings) async {
    final preferences = await _preferencesFuture;
    await preferences.setString(
      '$hubRulesPrefix:${settings.hubId}',
      jsonEncode(settings.toJson()),
    );
  }

  Future<bool> sensorManualEnabled(Sensor sensor) async {
    final preferences = await _preferencesFuture;
    return preferences.getBool('$sensorManualPrefix:${sensor.id}') ??
        sensor.status != 'offline';
  }

  Future<bool> anySensorManualEnabled(Home home) async {
    if (home.sensors.isEmpty) return false;
    final preferences = await _preferencesFuture;
    for (final sensor in home.sensors) {
      final enabled =
          preferences.getBool('$sensorManualPrefix:${sensor.id}') ??
          sensor.status != 'offline';
      if (enabled) return true;
    }
    return false;
  }

  Future<void> saveSensorManualEnabled(String sensorId, bool enabled) async {
    final preferences = await _preferencesFuture;
    await preferences.setBool('$sensorManualPrefix:$sensorId', enabled);
  }

  Future<bool> setSensorManualEnabled({
    required Home home,
    required Sensor sensor,
    required bool enabled,
  }) async {
    final savedToken = await _requireToken();
    final client = await apiClient();
    final result = await client.setSensorEnabled(
      token: savedToken,
      homeId: home.id,
      sensorId: sensor.id,
      enabled: enabled,
    );
    final preferences = await _preferencesFuture;
    await preferences.setBool('$sensorManualPrefix:${sensor.id}', enabled);
    return result['commandSent'] == true;
  }

  Future<String> _requireToken() async {
    final savedToken = await token();
    if (savedToken == null) {
      throw const ApiException('Not signed in');
    }
    return savedToken;
  }
}

class LiveFeedSignalingSession {
  LiveFeedSignalingSession(this._channel);

  final WebSocketChannel _channel;

  Stream<Map<String, dynamic>> get messages {
    return _channel.stream.where((raw) => raw is String).map((raw) {
      return jsonDecode(raw as String) as Map<String, dynamic>;
    });
  }

  void send(Map<String, dynamic> message) {
    _channel.sink.add(jsonEncode(message));
  }

  Future<void> close() async {
    await _channel.sink.close();
  }
}
