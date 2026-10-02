import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_colors.dart';
import '../../data/app_repository.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/cards.dart';
import '../../services/local_security_service.dart';

class HubSettingsPage extends StatefulWidget {
  const HubSettingsPage({super.key, required this.home});

  final Home home;

  @override
  State<HubSettingsPage> createState() => _HubSettingsPageState();
}

class _HubSettingsPageState extends State<HubSettingsPage> {
  HubRuleSettings? _settings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await context.read<AppRepository>().hubRuleSettings(
      widget.home,
    );
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final settings = _settings;
    if (settings == null) return;

    final authorized = await LocalSecurityService.authorizeSensitiveAction(
      'Authenticate to change hub settings.',
    );
    if (!authorized || !mounted) return;

    await context.read<AppRepository>().saveHubRuleSettings(settings);
    if (mounted) AppToast.show(context, 'Hub rules saved');
  }

  Future<String?> _pickTime(String current) async {
    final parts = current.split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 0,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
    );
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Hub Settings')),
      body: _loading || settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                SectionCard(
                  title: 'Global Sensor Rules',
                  icon: Icons.rule_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SettingsSwitchTile(
                        icon: Icons.schedule_outlined,
                        title: 'Schedule all sensors',
                        subtitle:
                            'Automatically arm or pause every sensor in this hub.',
                        value: settings.globalEnabled,
                        onChanged: (value) => setState(
                          () => _settings = settings.copyWith(
                            globalEnabled: value,
                          ),
                        ),
                      ),
                      _ScheduleEditor(
                        activeFrom: settings.globalActiveFrom,
                        activeTo: settings.globalActiveTo,
                        activeDays: settings.globalActiveDays,
                        onFromTap: () async {
                          final value = await _pickTime(
                            settings.globalActiveFrom,
                          );
                          if (value != null) {
                            setState(
                              () => _settings = settings.copyWith(
                                globalActiveFrom: value,
                              ),
                            );
                          }
                        },
                        onToTap: () async {
                          final value = await _pickTime(
                            settings.globalActiveTo,
                          );
                          if (value != null) {
                            setState(
                              () => _settings = settings.copyWith(
                                globalActiveTo: value,
                              ),
                            );
                          }
                        },
                        onDaysChanged: (days) => setState(
                          () => _settings = settings.copyWith(
                            globalActiveDays: days,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  title: 'Sensor Rules',
                  icon: Icons.sensors_outlined,
                  child: widget.home.sensors.isEmpty
                      ? const Text('No sensors paired with this hub yet.')
                      : Column(
                          children: widget.home.sensors.map((sensor) {
                            final rule = settings.sensorRules[sensor.id]!;
                            return _SensorRuleTile(
                              sensor: sensor,
                              rule: rule,
                              pickTime: _pickTime,
                              onChanged: (updated) {
                                final rules =
                                    Map<String, SensorRuleSettings>.from(
                                      settings.sensorRules,
                                    );
                                rules[sensor.id] = updated;
                                setState(
                                  () => _settings = settings.copyWith(
                                    sensorRules: rules,
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                ),
                AppButton(
                  label: 'Save rules',
                  icon: Icons.save_outlined,
                  onPressed: _save,
                ),
              ],
            ),
    );
  }
}

class _SensorRuleTile extends StatelessWidget {
  const _SensorRuleTile({
    required this.sensor,
    required this.rule,
    required this.pickTime,
    required this.onChanged,
  });

  final Sensor sensor;
  final SensorRuleSettings rule;
  final Future<String?> Function(String current) pickTime;
  final ValueChanged<SensorRuleSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: rule.enabled
                  ? AppColors.success.withValues(alpha: 0.18)
                  : AppColors.softAccent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.sensors_outlined,
              color: rule.enabled ? AppColors.success : AppColors.accent,
            ),
          ),
          title: Text(
            sensor.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            sensor.zone.isEmpty ? sensor.macAddress : sensor.zone,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.mutedText),
          ),
          children: [
            _SettingsSwitchTile(
              icon: Icons.power_settings_new_outlined,
              title: 'Sensor active',
              subtitle: 'Manual control for this sensor.',
              value: rule.enabled,
              onChanged: (value) => onChanged(rule.copyWith(enabled: value)),
            ),
            _SettingsSwitchTile(
              icon: Icons.rule_folder_outlined,
              title: 'Use global schedule',
              subtitle: 'Follow the hub-level active hours.',
              value: rule.useGlobalSchedule,
              onChanged: (value) =>
                  onChanged(rule.copyWith(useGlobalSchedule: value)),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: rule.useGlobalSchedule
                  ? const SizedBox.shrink()
                  : _ScheduleEditor(
                      activeFrom: rule.activeFrom,
                      activeTo: rule.activeTo,
                      activeDays: rule.activeDays,
                      onFromTap: () async {
                        final value = await pickTime(rule.activeFrom);
                        if (value != null) {
                          onChanged(rule.copyWith(activeFrom: value));
                        }
                      },
                      onToTap: () async {
                        final value = await pickTime(rule.activeTo);
                        if (value != null) {
                          onChanged(rule.copyWith(activeTo: value));
                        }
                      },
                      onDaysChanged: (days) =>
                          onChanged(rule.copyWith(activeDays: days)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value
              ? AppColors.accent.withValues(alpha: 0.28)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: value ? AppColors.softAccent : AppColors.surface,
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
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ScheduleEditor extends StatelessWidget {
  const _ScheduleEditor({
    required this.activeFrom,
    required this.activeTo,
    required this.activeDays,
    required this.onFromTap,
    required this.onToTap,
    required this.onDaysChanged,
  });

  final String activeFrom;
  final String activeTo;
  final List<int> activeDays;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final ValueChanged<List<int>> onDaysChanged;

  static const _days = {1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S'};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _TimeButton(
                onPressed: onFromTap,
                icon: const Icon(Icons.play_arrow_outlined),
                label: 'From',
                value: activeFrom,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TimeButton(
                onPressed: onToTap,
                icon: const Icon(Icons.stop_outlined),
                label: 'To',
                value: activeTo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _days.entries.map((entry) {
            final selected = activeDays.contains(entry.key);
            return FilterChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (value) {
                final next = [...activeDays];
                if (value) {
                  next.add(entry.key);
                } else {
                  next.remove(entry.key);
                }
                next.sort();
                onDaysChanged(next);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.value,
  });

  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            IconTheme(
              data: const IconThemeData(color: AppColors.accent, size: 20),
              child: icon,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
