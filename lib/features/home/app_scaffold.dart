import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../data/models.dart';
import '../notifications/notifications_page.dart';
import '../settings/settings_page.dart';
import 'home_page.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key, required this.user});

  final AppUser user;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, dashboard) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Glazia Home Secure'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => context.read<DashboardBloc>().add(
                  const DashboardRefreshed(),
                ),
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async =>
                context.read<DashboardBloc>().add(const DashboardRefreshed()),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_index),
                child: [
                  HomePage(user: widget.user, homes: dashboard.homes),
                  NotificationsPage(notifications: dashboard.notifications),
                  SettingsPage(
                    user: widget.user,
                    homes: dashboard.homes,
                    notifications: dashboard.notifications,
                  ),
                ][_index],
              ),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Badge.count(
                  count: dashboard.unreadNotifications,
                  isLabelVisible: dashboard.unreadNotifications > 0,
                  child: const Icon(Icons.notifications_outlined),
                ),
                selectedIcon: Badge.count(
                  count: dashboard.unreadNotifications,
                  isLabelVisible: dashboard.unreadNotifications > 0,
                  child: const Icon(Icons.notifications),
                ),
                label: 'Alerts',
              ),
              const NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
