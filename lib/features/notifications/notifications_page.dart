import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_colors.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../data/models.dart';
import '../../shared/widgets/cards.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.notifications});

  final List<AppNotification> notifications;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const _swipePreviewKey = 'alerts_swipe_preview_seen';

  bool _showSwipePreview = false;

  @override
  void initState() {
    super.initState();
    _loadSwipePreviewState();
  }

  Future<void> _loadSwipePreviewState() async {
    final preferences = await SharedPreferences.getInstance();
    final seen = preferences.getBool(_swipePreviewKey) ?? false;
    if (!seen && mounted) {
      setState(() => _showSwipePreview = true);
      await preferences.setBool(_swipePreviewKey, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = widget.notifications;
    if (notifications.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          EmptyState(
            icon: Icons.notifications_none,
            title: 'No alerts',
            message: 'Hub and sensor events will appear here in real time.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: notifications.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _AlertsHeader(
            count: notifications.length,
            onClearAll: () => _confirmClearAll(context),
          );
        }

        final notification = notifications[index - 1];
        return _SwipeableAlertCard(
          key: ValueKey(notification.id),
          notification: notification,
          preview: _showSwipePreview && index == 1,
          onPreviewComplete: () {
            if (mounted) setState(() => _showSwipePreview = false);
          },
          onDelete: () => context.read<DashboardBloc>().add(
            DashboardNotificationDeleteRequested(notification),
          ),
          onMarkRead: notification.readAt == null
              ? () => context.read<DashboardBloc>().add(
                  DashboardNotificationReadRequested(notification),
                )
              : null,
        );
      },
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all alerts?'),
        content: const Text('This will remove all alerts from this account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<DashboardBloc>().add(
        const DashboardNotificationsClearRequested(),
      );
    }
  }
}

class _AlertsHeader extends StatelessWidget {
  const _AlertsHeader({required this.count, required this.onClearAll});

  final int count;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count alert${count == 1 ? '' : 's'}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: 'Clear all',
            onPressed: onClearAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
    );
  }
}

class _SwipeableAlertCard extends StatefulWidget {
  const _SwipeableAlertCard({
    super.key,
    required this.notification,
    required this.preview,
    required this.onPreviewComplete,
    required this.onDelete,
    required this.onMarkRead,
  });

  final AppNotification notification;
  final bool preview;
  final VoidCallback onPreviewComplete;
  final VoidCallback onDelete;
  final VoidCallback? onMarkRead;

  @override
  State<_SwipeableAlertCard> createState() => _SwipeableAlertCardState();
}

class _SwipeableAlertCardState extends State<_SwipeableAlertCard> {
  static const double _deleteWidth = 68;

  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _runPreviewIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _SwipeableAlertCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.preview && widget.preview) {
      _runPreviewIfNeeded();
    }
  }

  Future<void> _runPreviewIfNeeded() async {
    if (!widget.preview) return;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _revealed = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    setState(() => _revealed = false);
    widget.onPreviewComplete();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 8),
              color: AppColors.error.withValues(alpha: 0.18),
              child: IconButton(
                tooltip: 'Delete alert',
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
              _revealed ? -_deleteWidth : 0,
              0,
              0,
            ),
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -80) {
                  setState(() => _revealed = true);
                } else if (velocity > 80) {
                  setState(() => _revealed = false);
                }
              },
              onTap: () {
                if (_revealed) setState(() => _revealed = false);
              },
              child: _AlertCard(
                notification: widget.notification,
                onMarkRead: widget.onMarkRead,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.notification, required this.onMarkRead});

  final AppNotification notification;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final unread = notification.readAt == null;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: unread ? AppColors.accent : AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _severityColor(
              notification.severity,
            ).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _severityIcon(notification.severity),
            color: _severityColor(notification.severity),
          ),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${notification.message}\n${_formatIndianTime(notification.createdAt)}',
          ),
        ),
        isThreeLine: true,
        trailing: onMarkRead != null
            ? IconButton(
                tooltip: 'Mark read',
                onPressed: onMarkRead,
                icon: const Icon(Icons.done),
              )
            : const Icon(Icons.done_all, color: AppColors.mutedText),
      ),
    );
  }

  IconData _severityIcon(String severity) {
    return switch (severity) {
      'critical' => Icons.warning_amber,
      'warning' => Icons.error_outline,
      _ => Icons.info_outline,
    };
  }

  Color _severityColor(String severity) {
    return switch (severity) {
      'critical' => AppColors.error,
      'warning' => AppColors.warning,
      _ => AppColors.accent,
    };
  }

  String _formatIndianTime(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    final ist = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
    final nowIst = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final dateLabel = _isSameDate(ist, nowIst)
        ? 'Today'
        : _isSameDate(ist, nowIst.subtract(const Duration(days: 1)))
        ? 'Yesterday'
        : '${ist.day.toString().padLeft(2, '0')}/${ist.month.toString().padLeft(2, '0')}/${ist.year}';

    final hour12 = ist.hour % 12 == 0 ? 12 : ist.hour % 12;
    final minute = ist.minute.toString().padLeft(2, '0');
    final meridiem = ist.hour >= 12 ? 'PM' : 'AM';
    return '$dateLabel, $hour12:$minute $meridiem IST';
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
