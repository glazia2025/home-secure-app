import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_colors.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../data/app_repository.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/cards.dart';
import '../../services/local_security_service.dart';
import '../hub_setup/hub_setup_page.dart';
import '../live_feed/live_feed_page.dart';
import '../sensor_pairing/sensor_pairing_page.dart';
import 'hub_settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user, required this.homes});

  final AppUser user;
  final List<Home> homes;

  @override
  Widget build(BuildContext context) {
    Future<void> openHubSetup() async {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RepositoryProvider.value(
            value: context.read<AppRepository>(),
            child: const HubSetupPage(),
          ),
        ),
      );
      if (context.mounted) {
        context.read<DashboardBloc>().add(const DashboardRefreshed());
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _HomeHero(
          user: user,
          hasHubs: homes.isNotEmpty,
          onAddHub: openHubSetup,
        ),
        if (homes.isEmpty)
          _EmptyHomeExperience(onAddHub: openHubSetup)
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
            child: Text(
              'Your hubs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ...homes.map((home) => HubListTile(home: home)),
        ],
      ],
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.user,
    required this.hasHubs,
    required this.onAddHub,
  });

  final AppUser user;
  final bool hasHubs;
  final VoidCallback onAddHub;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 440),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.button.withValues(alpha: 0.36),
              AppColors.surfaceElevated,
              AppColors.softAccent.withValues(alpha: 0.92),
            ],
          ),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: AppColors.button.withValues(alpha: 0.18),
              blurRadius: 38,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_moon_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user.name.isEmpty ? 'Home owner' : user.name}',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasHubs
                            ? 'Monitor your hubs and sensor activity.'
                            : 'Set up your first hub to start monitoring.',
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Add hub',
              icon: Icons.add_home_work_outlined,
              onPressed: onAddHub,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHomeExperience extends StatelessWidget {
  const _EmptyHomeExperience({required this.onAddHub});

  final VoidCallback onAddHub;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.95),
                        AppColors.button.withValues(alpha: 0.7),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.button.withValues(alpha: 0.28),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.router_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No hubs connected',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan the hub QR, send provisioning over BLE, then refresh once the device registers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedText, height: 1.45),
                ),
                const SizedBox(height: 18),
                AppButton(
                  label: 'Start hub setup',
                  icon: Icons.qr_code_scanner,
                  onPressed: onAddHub,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _SetupHintTile(
            icon: Icons.qr_code_2_outlined,
            title: 'Scan hub QR',
            subtitle: 'Read the MAC address from the device.',
          ),
          const _SetupHintTile(
            icon: Icons.bluetooth_connected_outlined,
            title: 'Provision securely',
            subtitle: 'Send the setup token to the hub over BLE.',
          ),
          const _SetupHintTile(
            icon: Icons.sensors_outlined,
            title: 'Pair sensors',
            subtitle: 'Open hub details after setup and add sensors there.',
          ),
        ],
      ),
    );
  }
}

class _SetupHintTile extends StatelessWidget {
  const _SetupHintTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.softAccent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HubListTile extends StatefulWidget {
  const HubListTile({super.key, required this.home});

  final Home home;

  @override
  State<HubListTile> createState() => _HubListTileState();
}

class _HubListTileState extends State<HubListTile> {
  bool _hasEnabledSensor = false;
  bool _loadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void didUpdateWidget(covariant HubListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.home.id != widget.home.id ||
        oldWidget.home.sensors.length != widget.home.sensors.length) {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    final enabled = await context.read<AppRepository>().anySensorManualEnabled(
      widget.home,
    );
    if (!mounted) return;
    setState(() {
      _hasEnabledSensor = enabled;
      _loadingStatus = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: widget.home.hub.name,
      icon: Icons.router_outlined,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RepositoryProvider.value(
                value: context.read<AppRepository>(),
                child: HubDetailsPage(home: widget.home),
              ),
            ),
          );
          if (context.mounted) {
            context.read<DashboardBloc>().add(const DashboardRefreshed());
            _loadStatus();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.home.name),
                    const SizedBox(height: 6),
                    Text('${widget.home.sensors.length} sensors'),
                  ],
                ),
              ),
              StatusPill(
                label: _loadingStatus
                    ? 'unknown'
                    : _hasEnabledSensor
                    ? 'online'
                    : 'offline',
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class HubDetailsPage extends StatelessWidget {
  const HubDetailsPage({super.key, required this.home});

  final Home home;

  @override
  Widget build(BuildContext context) {
    Future<void> deleteHub() async {
      final authorized = await LocalSecurityService.authorizeSensitiveAction(
        'Authenticate to delete this hub.',
      );
      if (!authorized || !context.mounted) return;

      final confirmed = await _confirmDestructiveAction(
        context,
        title: 'Delete hub?',
        message:
            'This removes the hub, sensors, and home from your account. The backend will ask the ESP32 hub to format and reset.',
        actionLabel: 'Delete hub',
      );
      if (!confirmed || !context.mounted) return;

      try {
        await context.read<AppRepository>().deleteHub(home);
        if (!context.mounted) return;
        AppToast.show(context, 'Hub deleted');
        context.read<DashboardBloc>().add(const DashboardRefreshed());
        Navigator.of(context).pop();
      } catch (error) {
        if (!context.mounted) return;
        AppToast.show(context, 'Unable to delete hub');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(home.hub.name),
        actions: [
          IconButton(
            tooltip: 'Main door live feed',
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RepositoryProvider.value(
                  value: context.read<AppRepository>(),
                  child: LiveFeedPage(home: home),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Add sensor',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RepositoryProvider.value(
                    value: context.read<AppRepository>(),
                    child: SensorPairingPage(home: home),
                  ),
                ),
              );
              if (context.mounted) {
                context.read<DashboardBloc>().add(const DashboardRefreshed());
                Navigator.of(context).pop();
              }
            },
          ),
          IconButton(
            tooltip: 'Hub settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RepositoryProvider.value(
                  value: context.read<AppRepository>(),
                  child: HubSettingsPage(home: home),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delete hub',
            icon: const Icon(Icons.delete_outline),
            onPressed: deleteHub,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _HubDetailsHero(home: home),
          SectionCard(
            title: 'Hub details',
            icon: Icons.router_outlined,
            child: Column(
              children: [
                DetailRow(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  value: home.name,
                ),
                DetailRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Serial',
                  value: home.hub.serialNumber ?? 'Not set',
                ),
                DetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Last seen',
                  value: home.hub.lastSeenAt ?? 'No last seen time',
                ),
              ],
            ),
          ),
          DoorUnlockCard(home: home),
          SectionCard(
            title: 'Sensors',
            icon: Icons.sensors_outlined,
            child: home.sensors.isEmpty
                ? const _InlineEmptyPanel(
                    icon: Icons.sensors_off_outlined,
                    title: 'No sensors paired',
                    message:
                        'Press the hub pair button, then use the scan icon above to add a sensor.',
                  )
                : Column(
                    children: home.sensors
                        .map(
                          (sensor) => SensorManualToggleTile(
                            home: home,
                            sensor: sensor,
                            onDeleted: () {
                              context.read<DashboardBloc>().add(
                                const DashboardRefreshed(),
                              );
                              Navigator.of(context).pop();
                            },
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InlineEmptyPanel extends StatelessWidget {
  const _InlineEmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedText, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _HubDetailsHero extends StatelessWidget {
  const _HubDetailsHero({required this.home});

  final Home home;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.button.withValues(alpha: 0.34),
              AppColors.surfaceElevated,
              AppColors.softAccent.withValues(alpha: 0.88),
            ],
          ),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: AppColors.button.withValues(alpha: 0.16),
              blurRadius: 34,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Icon(
                Icons.router_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    home.hub.name,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${home.sensors.length} sensors paired',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            StatusPill(
              label: home.hub.status.isEmpty ? 'unknown' : home.hub.status,
            ),
          ],
        ),
      ),
    );
  }
}

class DoorUnlockCard extends StatefulWidget {
  const DoorUnlockCard({super.key, required this.home});

  final Home home;

  @override
  State<DoorUnlockCard> createState() => _DoorUnlockCardState();
}

class _DoorUnlockCardState extends State<DoorUnlockCard> {
  DoorLockCommand? _command;
  bool _loading = true;
  bool _unlocking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  Future<void> _loadLatest() async {
    try {
      final command = await context.read<AppRepository>().latestDoorLockCommand(
        widget.home,
      );
      if (!mounted) return;
      setState(() {
        _command = command;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _unlock() async {
    if (_unlocking) return;
    setState(() {
      _unlocking = true;
      _error = null;
    });

    try {
      final command = await context.read<AppRepository>().openDoorLock(
        widget.home,
      );
      if (!mounted) return;
      setState(() {
        _command = command;
        _unlocking = false;
      });
      AppToast.show(context, 'Unlock command sent to hub');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _unlocking = false;
        _error = error.toString();
      });
      AppToast.show(context, 'Unable to send unlock command');
    }
  }

  @override
  Widget build(BuildContext context) {
    final command = _command;
    final status = command?.status ?? (_loading ? 'loading' : 'ready');

    return SectionCard(
      title: 'Main door lock',
      icon: Icons.lock_open_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.softAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.door_front_door_outlined,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Automatic unlock',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        command == null
                            ? 'Send unlock command to the ESP32 hub.'
                            : 'Last command: ${command.action} • ${command.status}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                StatusPill(label: _statusLabel(status)),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 14),
          AppButton(
            label: 'Unlock main door',
            icon: Icons.lock_open_outlined,
            loading: _unlocking,
            onPressed: _unlocking || _loading ? null : _unlock,
          ),
          const SizedBox(height: 10),
          const Text(
            'The app requests unlock from the backend. The backend pushes the command to ESP32 over the hub control WebSocket.',
            style: TextStyle(color: AppColors.mutedText, height: 1.35),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'executed' => 'online',
      'failed' => 'offline',
      'queued' => 'queued',
      'delivered' => 'sent',
      'loading' => 'loading',
      _ => 'ready',
    };
  }
}

class SensorManualToggleTile extends StatefulWidget {
  const SensorManualToggleTile({
    super.key,
    required this.home,
    required this.sensor,
    required this.onDeleted,
  });

  final Home home;
  final Sensor sensor;
  final VoidCallback onDeleted;

  @override
  State<SensorManualToggleTile> createState() => _SensorManualToggleTileState();
}

class _SensorManualToggleTileState extends State<SensorManualToggleTile> {
  bool _enabled = true;
  bool _loading = true;
  bool _deleting = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await context.read<AppRepository>().sensorManualEnabled(
      widget.sensor,
    );
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    final previous = _enabled;
    setState(() {
      _enabled = value;
      _toggling = true;
    });
    try {
      final commandSent = await context
          .read<AppRepository>()
          .setSensorManualEnabled(
            home: widget.home,
            sensor: widget.sensor,
            enabled: value,
          );
      if (!mounted) return;
      AppToast.show(
        context,
        commandSent
            ? value
                  ? 'Sensor enable command sent'
                  : 'Sensor disable command sent'
            : 'Hub is offline. Sensor setting saved in app.',
      );
      setState(() => _toggling = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enabled = previous;
        _toggling = false;
      });
      AppToast.show(context, 'Unable to update sensor');
    }
  }

  Future<void> _deleteSensor() async {
    final authorized = await LocalSecurityService.authorizeSensitiveAction(
      'Authenticate to delete this sensor.',
    );
    if (!authorized || !mounted) return;

    final confirmed = await _confirmDestructiveAction(
      context,
      title: 'Delete sensor?',
      message:
          'This removes ${widget.sensor.name} from the hub. The backend will ask the ESP32 hub to remove this sensor from NVS memory.',
      actionLabel: 'Delete sensor',
    );
    if (!confirmed || !mounted || _deleting) return;

    setState(() => _deleting = true);
    try {
      await context.read<AppRepository>().deleteSensor(
        home: widget.home,
        sensor: widget.sensor,
      );
      if (!mounted) return;
      AppToast.show(context, 'Sensor deleted');
      widget.onDeleted();
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppToast.show(context, 'Unable to delete sensor');
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = _enabled && widget.sensor.status != 'offline';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: online
              ? const Color(0xFF7DDE9E).withValues(alpha: 0.22)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: online ? const Color(0xFF103A26) : AppColors.softAccent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.sensors_outlined,
              color: online ? const Color(0xFF7DDE9E) : AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.sensor.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusPill(label: online ? 'online' : 'offline'),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  widget.sensor.zone.isEmpty
                      ? widget.sensor.macAddress
                      : '${widget.sensor.zone}  ${widget.sensor.macAddress}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Delete sensor',
            onPressed: _deleting ? null : _deleteSensor,
            icon: _deleting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
          ),
          const SizedBox(width: 4),
          _loading
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _toggling
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(value: _enabled, onChanged: _toggle),
        ],
      ),
    );
  }
}

Future<bool> _confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE5484D),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(actionLabel),
            ),
          ],
        ),
      ) ??
      false;
}
