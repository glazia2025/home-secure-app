import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/dashboard/dashboard_bloc.dart';
import '../data/app_repository.dart';
import '../features/auth/auth_page.dart';
import '../features/home/app_scaffold.dart';
import 'app_colors.dart';

class GlaziaHomeSecureApp extends StatelessWidget {
  const GlaziaHomeSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => AppRepository(),
      child: BlocProvider(
        create: (context) =>
            AuthBloc(context.read<AppRepository>())..add(const AuthStarted()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Glazia Home Secure',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.accent,
              brightness: Brightness.dark,
              primary: AppColors.accent,
              secondary: AppColors.accent,
              surface: AppColors.surface,
              onSurface: AppColors.text,
            ),
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.text,
              centerTitle: false,
              elevation: 0,
              titleTextStyle: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.softAccent,
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => TextStyle(
                  color: states.contains(WidgetState.selected)
                      ? AppColors.accent
                      : AppColors.mutedText,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
              iconTheme: WidgetStateProperty.resolveWith(
                (states) => IconThemeData(
                  color: states.contains(WidgetState.selected)
                      ? AppColors.accent
                      : AppColors.mutedText,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              labelStyle: const TextStyle(color: AppColors.text),
              floatingLabelStyle: const TextStyle(color: AppColors.accent),
              prefixIconColor: AppColors.accent,
              filled: true,
              fillColor: AppColors.surfaceElevated,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.accent,
                  width: 1.5,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            cardTheme: CardThemeData(
              color: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.black.withValues(alpha: 0.3),
            ),
            dividerTheme: const DividerThemeData(color: AppColors.border),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.accent
                    : AppColors.mutedText,
              ),
              trackColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.softAccent
                    : AppColors.surfaceElevated,
              ),
            ),
            textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: AppColors.text,
              displayColor: AppColors.text,
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.button,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            ),
            useMaterial3: true,
          ),
          home: const AppGate(),
        ),
      ),
    );
  }
}

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.initial ||
            state.status == AuthStatus.loading && state.user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!state.isAuthenticated || state.user == null) {
          return const AuthPage();
        }

        return BlocProvider(
          key: ValueKey(state.token),
          create: (context) =>
              DashboardBloc(context.read<AppRepository>())
                ..add(const DashboardStarted()),
          child: AppScaffold(user: state.user!),
        );
      },
    );
  }
}
