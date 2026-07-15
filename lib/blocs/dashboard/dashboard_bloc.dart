import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_repository.dart';
import '../../data/models.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._repository) : super(const DashboardState()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardRefreshed>(_onRefreshed);
    on<DashboardNotificationReceived>(_onNotificationReceived);
    on<DashboardNotificationReadRequested>(_onNotificationReadRequested);
    on<DashboardNotificationDeleteRequested>(_onNotificationDeleteRequested);
    on<DashboardNotificationsClearRequested>(_onNotificationsClearRequested);
  }

  final AppRepository _repository;
  StreamSubscription<AppNotification>? _notificationSubscription;

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading, clearError: true));
    await _load(emit);
    await _notificationSubscription?.cancel();
    try {
      final stream = await _repository.notificationStream();
      _notificationSubscription = stream.listen(
        (notification) => add(DashboardNotificationReceived(notification)),
      );
    } catch (_) {}
  }

  Future<void> _onRefreshed(
    DashboardRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<DashboardState> emit) async {
    try {
      final homes = await _repository.homes();
      final notifications = await _repository.notifications();
      emit(
        state.copyWith(
          status: DashboardStatus.ready,
          homes: homes,
          notifications: notifications,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DashboardStatus.failure,
          error: error.toString(),
        ),
      );
    }
  }

  void _onNotificationReceived(
    DashboardNotificationReceived event,
    Emitter<DashboardState> emit,
  ) {
    emit(
      state.copyWith(
        notifications: [
          event.notification,
          ...state.notifications.where(
            (notification) => notification.id != event.notification.id,
          ),
        ],
      ),
    );
  }

  Future<void> _onNotificationReadRequested(
    DashboardNotificationReadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final updated = await _repository.markNotificationRead(
        event.notification.id,
      );
      emit(
        state.copyWith(
          notifications: state.notifications
              .map((item) => item.id == updated.id ? updated : item)
              .toList(),
        ),
      );
    } catch (error) {
      emit(state.copyWith(error: error.toString()));
    }
  }

  Future<void> _onNotificationDeleteRequested(
    DashboardNotificationDeleteRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final previousNotifications = state.notifications;
    emit(
      state.copyWith(
        notifications: state.notifications
            .where((item) => item.id != event.notification.id)
            .toList(),
      ),
    );
    try {
      await _repository.deleteNotification(event.notification.id);
    } catch (error) {
      emit(
        state.copyWith(
          notifications: previousNotifications,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onNotificationsClearRequested(
    DashboardNotificationsClearRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final previousNotifications = state.notifications;
    emit(state.copyWith(notifications: const []));
    try {
      await _repository.clearNotifications();
    } catch (error) {
      emit(
        state.copyWith(
          notifications: previousNotifications,
          error: error.toString(),
        ),
      );
    }
  }
}
