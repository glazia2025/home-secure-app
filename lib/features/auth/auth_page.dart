import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/cards.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _requestOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _validationError = 'Phone number is required');
      return;
    }
    setState(() => _validationError = null);
    context.read<AuthBloc>().add(AuthOtpRequested(phone));
  }

  void _verifyOtp(AuthState state) {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      setState(() => _validationError = 'Enter a valid OTP');
      return;
    }
    setState(() => _validationError = null);
    context.read<AuthBloc>().add(
      AuthOtpVerified(phoneNumber: state.phoneNumber, otp: otp),
    );
  }

  void _completeRegistration(AuthState state) {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty) {
      setState(() => _validationError = 'Name is required');
      return;
    }
    if (email.isEmpty) {
      setState(() => _validationError = 'Email is required');
      return;
    }
    setState(() => _validationError = null);
    context.read<AuthBloc>().add(
      AuthOtpRegistrationCompleted(
        name: name,
        email: email,
        phoneNumber: state.phoneNumber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.background,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 64, 22, 28),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final busy = state.isBusy;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - value)),
                          child: child,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AnimatedShield(status: state.status),
                          const SizedBox(height: 22),
                          Text(
                            'Glazia Home Secure',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _subtitle(state),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _AuthPanel(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.04),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: _AuthFields(
                                key: ValueKey(state.status),
                                state: state,
                                busy: busy,
                                phoneController: _phoneController,
                                otpController: _otpController,
                                nameController: _nameController,
                                emailController: _emailController,
                                onRequestOtp: _requestOtp,
                                onVerifyOtp: () => _verifyOtp(state),
                                onCompleteRegistration: () =>
                                    _completeRegistration(state),
                              ),
                            ),
                          ),
                          if ((_validationError ?? state.error) != null) ...[
                            const SizedBox(height: 12),
                            ErrorBanner(
                              message: _validationError ?? state.error!,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(AuthState state) {
    return switch (state.status) {
      AuthStatus.otpSent => 'Enter the OTP sent to ${state.phoneNumber}.',
      AuthStatus.registrationRequired =>
        'Complete registration to secure your home.',
      _ => 'Sign in or register with phone OTP.',
    };
  }
}

class _AnimatedShield extends StatelessWidget {
  const _AnimatedShield({required this.status});

  final AuthStatus status;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        final clamped = value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.76 + (0.24 * clamped),
          child: Opacity(opacity: clamped, child: child),
        );
      },
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: AppColors.button.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(
            switch (status) {
              AuthStatus.otpSent => Icons.sms_outlined,
              AuthStatus.registrationRequired => Icons.person_add_alt,
              _ => Icons.shield_outlined,
            },
            size: 34,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _AuthFields extends StatelessWidget {
  const _AuthFields({
    super.key,
    required this.state,
    required this.busy,
    required this.phoneController,
    required this.otpController,
    required this.nameController,
    required this.emailController,
    required this.onRequestOtp,
    required this.onVerifyOtp,
    required this.onCompleteRegistration,
  });

  final AuthState state;
  final bool busy;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final VoidCallback onRequestOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onCompleteRegistration;

  @override
  Widget build(BuildContext context) {
    if (state.status == AuthStatus.registrationRequired) {
      phoneController.text = state.phoneNumber;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your details to complete the verified phone login.',
            style: TextStyle(color: AppColors.mutedText, height: 1.35),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            loading: busy,
            onPressed: onCompleteRegistration,
            icon: Icons.person_add_alt,
            label: 'Complete registration',
          ),
        ],
      );
    }

    if (state.status == AuthStatus.otpSent ||
        busy && state.phoneNumber.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter OTP',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Code sent to ${state.phoneNumber}',
            style: const TextStyle(color: AppColors.mutedText, height: 1.35),
          ),
          if (state.devOtp != null) ...[
            const SizedBox(height: 14),
            _DevOtpCard(otp: state.devOtp!),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'OTP',
              prefixIcon: Icon(Icons.password_outlined),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            loading: busy,
            onPressed: onVerifyOtp,
            icon: Icons.verified_outlined,
            label: 'Verify OTP',
          ),
          TextButton(
            onPressed: busy ? null : onRequestOtp,
            child: const Text('Resend code'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Login',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your phone number to continue with OTP.',
          style: TextStyle(color: AppColors.mutedText, height: 1.35),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          loading: busy,
          onPressed: onRequestOtp,
          icon: Icons.sms_outlined,
          label: 'Send OTP',
        ),
      ],
    );
  }
}

class _DevOtpCard extends StatelessWidget {
  const _DevOtpCard({required this.otp});

  final String otp;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.button.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.34)),
      ),
      child: Row(
        children: [
          const Icon(Icons.developer_mode_outlined, color: AppColors.accent),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Development OTP',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            otp,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
