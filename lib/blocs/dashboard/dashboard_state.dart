part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, ready, failure }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.homes = const [],
    this.notifications = const [],
    this.error,
  });

  final DashboardStatus status;
  final List<Home> homes;
  final List<AppNotification> notifications;
  final String? error;

  int get unreadNotifications =>
      notifications.where((notification) => notification.readAt == null).length;

  DashboardState copyWith({
    DashboardStatus? status,
    List<Home>? homes,
    List<AppNotification>? notifications,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      homes: homes ?? this.homes,
      notifications: notifications ?? this.notifications,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, homes, notifications, error];
}
