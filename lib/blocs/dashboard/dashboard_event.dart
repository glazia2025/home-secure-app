part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}

class DashboardNotificationReceived extends DashboardEvent {
  const DashboardNotificationReceived(this.notification);

  final AppNotification notification;

  @override
  List<Object?> get props => [notification];
}

class DashboardNotificationReadRequested extends DashboardEvent {
  const DashboardNotificationReadRequested(this.notification);

  final AppNotification notification;

  @override
  List<Object?> get props => [notification];
}

class DashboardNotificationDeleteRequested extends DashboardEvent {
  const DashboardNotificationDeleteRequested(this.notification);

  final AppNotification notification;

  @override
  List<Object?> get props => [notification];
}

class DashboardNotificationsClearRequested extends DashboardEvent {
  const DashboardNotificationsClearRequested();
}
