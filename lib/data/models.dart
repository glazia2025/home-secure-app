class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String email;
  final String phoneNumber;
}

sealed class LiveFeedEvent {
  const LiveFeedEvent();

  factory LiveFeedEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    return switch (type) {
      'status' => LiveFeedStatus.fromJson(json),
      'ready' => LiveFeedReady.fromJson(json),
      'error' => LiveFeedError(json['message'] as String? ?? 'Live feed error'),
      _ => LiveFeedError('Unknown live feed event'),
    };
  }
}

class LiveFeedReady extends LiveFeedEvent {
  const LiveFeedReady({
    required this.hubId,
    required this.role,
    required this.status,
  });

  factory LiveFeedReady.fromJson(Map<String, dynamic> json) {
    return LiveFeedReady(
      hubId: json['hubId'] as String? ?? '',
      role: json['role'] as String? ?? '',
      status: json['status'] as String? ?? 'waiting',
    );
  }

  final String hubId;
  final String role;
  final String status;
}

class LiveFeedStatus extends LiveFeedEvent {
  const LiveFeedStatus({required this.hubId, required this.status, this.at});

  factory LiveFeedStatus.fromJson(Map<String, dynamic> json) {
    return LiveFeedStatus(
      hubId: json['hubId'] as String? ?? '',
      status: json['status'] as String? ?? 'waiting',
      at: json['at'] as String?,
    );
  }

  final String hubId;
  final String status;
  final String? at;
}

class LiveFeedError extends LiveFeedEvent {
  const LiveFeedError(this.message);

  final String message;
}

class DoorLockCommand {
  const DoorLockCommand({
    required this.id,
    required this.homeId,
    required this.hubId,
    required this.mode,
    required this.action,
    required this.durationMs,
    required this.status,
    this.lockState,
    this.error,
  });

  factory DoorLockCommand.fromJson(Map<String, dynamic> json) {
    return DoorLockCommand(
      id: json['id'] as String? ?? '',
      homeId: json['homeId'] as String? ?? '',
      hubId: json['hubId'] as String? ?? '',
      mode: json['mode'] as String? ?? '',
      action: json['action'] as String? ?? '',
      durationMs: json['durationMs'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      lockState: json['lockState'] as String?,
      error: json['error'] as String?,
    );
  }

  final String id;
  final String homeId;
  final String hubId;
  final String mode;
  final String action;
  final int durationMs;
  final String status;
  final String? lockState;
  final String? error;
}

class OtpRequestResult {
  const OtpRequestResult({
    required this.phoneNumber,
    required this.expiresAt,
    this.otp,
  });

  factory OtpRequestResult.fromJson(Map<String, dynamic> json) {
    return OtpRequestResult(
      phoneNumber: json['phoneNumber'] as String? ?? '',
      expiresAt: json['expiresAt'] as String? ?? '',
      otp: json['otp'] as String?,
    );
  }

  final String phoneNumber;
  final String expiresAt;
  final String? otp;
}

class OtpVerifyResult {
  const OtpVerifyResult({
    required this.status,
    this.phoneNumber,
    this.otpSessionId,
    this.session,
  });

  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String?;
    return OtpVerifyResult(
      status: json['status'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      otpSessionId: json['otpSessionId'] as String?,
      session: token == null
          ? null
          : AuthSession(
              token: token,
              user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
              homes: (json['homes'] as List<dynamic>? ?? const [])
                  .map((item) => Home.fromJson(item as Map<String, dynamic>))
                  .toList(),
            ),
    );
  }

  final String status;
  final String? phoneNumber;
  final String? otpSessionId;
  final AuthSession? session;
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    required this.homes,
  });

  final String token;
  final AppUser user;
  final List<Home> homes;
}

class Home {
  const Home({
    required this.id,
    required this.name,
    required this.location,
    required this.hub,
    required this.sensors,
  });

  factory Home.fromJson(Map<String, dynamic> json) {
    return Home(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      hub: Hub.fromJson(json['hub'] as Map<String, dynamic>? ?? const {}),
      sensors: (json['sensors'] as List<dynamic>? ?? const [])
          .map((item) => Sensor.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final String location;
  final Hub hub;
  final List<Sensor> sensors;
}

class Hub {
  const Hub({
    required this.id,
    required this.name,
    required this.location,
    required this.macAddress,
    required this.hardwareModel,
    required this.status,
    this.serialNumber,
    this.lastSeenAt,
  });

  factory Hub.fromJson(Map<String, dynamic> json) {
    return Hub(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      macAddress: json['macAddress'] as String? ?? '',
      hardwareModel: json['hardwareModel'] as String? ?? '',
      status: json['status'] as String? ?? '',
      serialNumber: json['serialNumber'] as String?,
      lastSeenAt: json['lastSeenAt'] as String?,
    );
  }

  final String id;
  final String name;
  final String location;
  final String macAddress;
  final String hardwareModel;
  final String status;
  final String? serialNumber;
  final String? lastSeenAt;
}

class Sensor {
  const Sensor({
    required this.id,
    required this.macAddress,
    required this.name,
    required this.type,
    required this.zone,
    required this.hardwareModel,
    required this.status,
    required this.provisioning,
    this.lastActivityAt,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      id: json['id'] as String? ?? '',
      macAddress: json['macAddress'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      zone: json['zone'] as String? ?? '',
      hardwareModel: json['hardwareModel'] as String? ?? '',
      status: json['status'] as String? ?? '',
      provisioning: Map<String, dynamic>.from(
        json['provisioning'] as Map? ?? const {},
      ),
      lastActivityAt: json['lastActivityAt'] as String?,
    );
  }

  final String id;
  final String macAddress;
  final String name;
  final String type;
  final String zone;
  final String hardwareModel;
  final String status;
  final Map<String, dynamic> provisioning;
  final String? lastActivityAt;
}

class SetupSession {
  const SetupSession({
    required this.id,
    required this.hubMacAddress,
    required this.provisioningToken,
    required this.expiresAt,
  });

  factory SetupSession.fromJson(Map<String, dynamic> json) {
    return SetupSession(
      id: json['setupSessionId'] as String? ?? '',
      hubMacAddress: json['hubMacAddress'] as String? ?? '',
      provisioningToken: json['provisioningToken'] as String? ?? '',
      expiresAt: json['expiresAt'] as String? ?? '',
    );
  }

  final String id;
  final String hubMacAddress;
  final String provisioningToken;
  final String expiresAt;
}

class PairSensorResult {
  const PairSensorResult({
    required this.home,
    required this.sensor,
    required this.hubPayload,
    required this.sensorPayload,
  });

  factory PairSensorResult.fromJson(Map<String, dynamic> json) {
    final provisioning =
        json['provisioning'] as Map<String, dynamic>? ?? const {};
    return PairSensorResult(
      home: Home.fromJson(json['home'] as Map<String, dynamic>? ?? const {}),
      sensor: Sensor.fromJson(
        json['sensor'] as Map<String, dynamic>? ?? const {},
      ),
      hubPayload: Map<String, dynamic>.from(
        provisioning['hub'] as Map? ?? const {},
      ),
      sensorPayload: Map<String, dynamic>.from(
        provisioning['sensor'] as Map? ?? const {},
      ),
    );
  }

  final Home home;
  final Sensor sensor;
  final Map<String, dynamic> hubPayload;
  final Map<String, dynamic> sensorPayload;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.eventType,
    required this.severity,
    required this.title,
    required this.message,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      severity: json['severity'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      readAt: json['readAt'] as String?,
    );
  }

  final String id;
  final String eventType;
  final String severity;
  final String title;
  final String message;
  final String createdAt;
  final String? readAt;
}

class SensorRuleSettings {
  const SensorRuleSettings({
    required this.sensorId,
    required this.enabled,
    required this.useGlobalSchedule,
    required this.activeFrom,
    required this.activeTo,
    required this.activeDays,
  });

  factory SensorRuleSettings.fromJson(Map<String, dynamic> json) {
    return SensorRuleSettings(
      sensorId: json['sensorId'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      useGlobalSchedule: json['useGlobalSchedule'] as bool? ?? true,
      activeFrom: json['activeFrom'] as String? ?? '00:00',
      activeTo: json['activeTo'] as String? ?? '23:59',
      activeDays:
          (json['activeDays'] as List<dynamic>? ?? const [1, 2, 3, 4, 5, 6, 7])
              .map((day) => int.tryParse(day.toString()) ?? 1)
              .toList(),
    );
  }

  final String sensorId;
  final bool enabled;
  final bool useGlobalSchedule;
  final String activeFrom;
  final String activeTo;
  final List<int> activeDays;

  Map<String, dynamic> toJson() {
    return {
      'sensorId': sensorId,
      'enabled': enabled,
      'useGlobalSchedule': useGlobalSchedule,
      'activeFrom': activeFrom,
      'activeTo': activeTo,
      'activeDays': activeDays,
    };
  }

  SensorRuleSettings copyWith({
    bool? enabled,
    bool? useGlobalSchedule,
    String? activeFrom,
    String? activeTo,
    List<int>? activeDays,
  }) {
    return SensorRuleSettings(
      sensorId: sensorId,
      enabled: enabled ?? this.enabled,
      useGlobalSchedule: useGlobalSchedule ?? this.useGlobalSchedule,
      activeFrom: activeFrom ?? this.activeFrom,
      activeTo: activeTo ?? this.activeTo,
      activeDays: activeDays ?? this.activeDays,
    );
  }
}

class HubRuleSettings {
  const HubRuleSettings({
    required this.hubId,
    required this.globalEnabled,
    required this.globalActiveFrom,
    required this.globalActiveTo,
    required this.globalActiveDays,
    required this.sensorRules,
  });

  factory HubRuleSettings.defaults(String hubId, List<Sensor> sensors) {
    return HubRuleSettings(
      hubId: hubId,
      globalEnabled: true,
      globalActiveFrom: '00:00',
      globalActiveTo: '23:59',
      globalActiveDays: const [1, 2, 3, 4, 5, 6, 7],
      sensorRules: {
        for (final sensor in sensors)
          sensor.id: SensorRuleSettings(
            sensorId: sensor.id,
            enabled: true,
            useGlobalSchedule: true,
            activeFrom: '00:00',
            activeTo: '23:59',
            activeDays: const [1, 2, 3, 4, 5, 6, 7],
          ),
      },
    );
  }

  factory HubRuleSettings.fromJson(
    Map<String, dynamic> json,
    List<Sensor> sensors,
  ) {
    final parsedRules = <String, SensorRuleSettings>{};
    final rawRules = json['sensorRules'];
    if (rawRules is Map<String, dynamic>) {
      for (final entry in rawRules.entries) {
        if (entry.value is Map<String, dynamic>) {
          parsedRules[entry.key] = SensorRuleSettings.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }
    }

    for (final sensor in sensors) {
      parsedRules.putIfAbsent(
        sensor.id,
        () => SensorRuleSettings(
          sensorId: sensor.id,
          enabled: true,
          useGlobalSchedule: true,
          activeFrom: '00:00',
          activeTo: '23:59',
          activeDays: const [1, 2, 3, 4, 5, 6, 7],
        ),
      );
    }

    return HubRuleSettings(
      hubId: json['hubId'] as String? ?? '',
      globalEnabled: json['globalEnabled'] as bool? ?? true,
      globalActiveFrom: json['globalActiveFrom'] as String? ?? '00:00',
      globalActiveTo: json['globalActiveTo'] as String? ?? '23:59',
      globalActiveDays:
          (json['globalActiveDays'] as List<dynamic>? ??
                  const [1, 2, 3, 4, 5, 6, 7])
              .map((day) => int.tryParse(day.toString()) ?? 1)
              .toList(),
      sensorRules: parsedRules,
    );
  }

  final String hubId;
  final bool globalEnabled;
  final String globalActiveFrom;
  final String globalActiveTo;
  final List<int> globalActiveDays;
  final Map<String, SensorRuleSettings> sensorRules;

  Map<String, dynamic> toJson() {
    return {
      'hubId': hubId,
      'globalEnabled': globalEnabled,
      'globalActiveFrom': globalActiveFrom,
      'globalActiveTo': globalActiveTo,
      'globalActiveDays': globalActiveDays,
      'sensorRules': sensorRules.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  HubRuleSettings copyWith({
    bool? globalEnabled,
    String? globalActiveFrom,
    String? globalActiveTo,
    List<int>? globalActiveDays,
    Map<String, SensorRuleSettings>? sensorRules,
  }) {
    return HubRuleSettings(
      hubId: hubId,
      globalEnabled: globalEnabled ?? this.globalEnabled,
      globalActiveFrom: globalActiveFrom ?? this.globalActiveFrom,
      globalActiveTo: globalActiveTo ?? this.globalActiveTo,
      globalActiveDays: globalActiveDays ?? this.globalActiveDays,
      sensorRules: sensorRules ?? this.sensorRules,
    );
  }
}
