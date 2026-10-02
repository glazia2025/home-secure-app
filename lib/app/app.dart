import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/dashboard/dashboard_bloc.dart';
import '../data/app_repository.dart';
import '../features/auth/auth_page.dart';
import '../features/home/app_scaffold.dart';
import '../features/splash/splash_page.dart';
import 'app_colors.dart';

class GlaziaHomeSecureApp extends StatelessWidget {
  const GlaziaHomeSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = baseTextTheme
        .copyWith(
          displayLarge: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 56,
            height: 60 / 56,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.12,
          ),
          headlineMedium: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 40,
            height: 46 / 40,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          headlineSmall: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 32,
            height: 38 / 32,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 24,
            height: 30 / 24,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            height: 28 / 20,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            height: 28 / 18,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            height: 26 / 16,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 22 / 14,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: const TextStyle(
            fontFamily: 'IBM Plex Mono',
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w600,
            letterSpacing: .96,
          ),
          labelSmall: const TextStyle(
            fontFamily: 'IBM Plex Mono',
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w400,
          ),
        )
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text);

    return RepositoryProvider(
      create: (_) => AppRepository(),
      child: BlocProvider(
        create: (context) =>
            AuthBloc(context.read<AppRepository>())..add(const AuthStarted()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Glazia Home',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.accent,
              brightness: Brightness.dark,
              primary: AppColors.accent,
              secondary: AppColors.secondary,
              error: AppColors.error,
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
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w600,
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
            dividerTheme: const DividerThemeData(color: AppColors.divider),
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
            textTheme: textTheme,
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
          home: const SplashPage(child: AppGate()),
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
