import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';

const _pageBackground = AppColors.background;
const _textPrimary = AppColors.text;
const _textSecondary = AppColors.secondaryText;

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
      return;
    }
    context.read<AuthBloc>().add(AuthOtpRequested(phone));
  }

  void _verifyOtp(AuthState state) {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      return;
    }
    context.read<AuthBloc>().add(
      AuthOtpVerified(phoneNumber: state.phoneNumber, otp: otp),
    );
  }

  void _completeRegistration(AuthState state) {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || email.isEmpty) {
      return;
    }
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
      backgroundColor: _pageBackground,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const _HeroImage(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 40, 25, 34),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: _AuthFields(
                          key: ValueKey(state.status),
                          state: state,
                          phoneController: _phoneController,
                          otpController: _otpController,
                          nameController: _nameController,
                          emailController: _emailController,
                          onRequestOtp: _requestOtp,
                          onVerifyOtp: () => _verifyOtp(state),
                          onCompleteRegistration: () =>
                              _completeRegistration(state),
                          onChangePhone: () {
                            _otpController.clear();
                            context.read<AuthBloc>().add(
                              const AuthPhoneChangeRequested(),
                            );
                          },
                        ),
                      ),
                    ),
                    const _Footer(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxWidth * (382 / 390);
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(22),
          ),
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: Image.asset(
              'assets/images/login.png',
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
        );
      },
    );
  }
}

class _AuthFields extends StatelessWidget {
  const _AuthFields({
    super.key,
    required this.state,
    required this.phoneController,
    required this.otpController,
    required this.nameController,
    required this.emailController,
    required this.onRequestOtp,
    required this.onVerifyOtp,
    required this.onCompleteRegistration,
    required this.onChangePhone,
  });

  final AuthState state;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final VoidCallback onRequestOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onCompleteRegistration;
  final VoidCallback onChangePhone;

  @override
  Widget build(BuildContext context) {
    if (state.status == AuthStatus.registrationRequired) {
      phoneController.text = state.phoneNumber;
      return _FormSection(
        title: 'Create profile',
        subtitle: 'Add your details to finish securing your home.',
        children: [
          _LabeledField(
            label: 'NAME',
            controller: nameController,
            hint: 'Your name',
            icon: Icons.person_outline,
          ),
          _LabeledField(
            label: 'EMAIL',
            controller: emailController,
            hint: 'Email address',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          _LabeledField(
            label: 'PHONE NUMBER',
            controller: phoneController,
            hint: state.phoneNumber,
            icon: Icons.phone_outlined,
            readOnly: true,
          ),
          _MetalButton(
            loading: state.isBusy,
            label: 'Complete registration',
            icon: Icons.person_add_alt_1_outlined,
            onPressed: onCompleteRegistration,
          ),
        ],
      );
    }

    if (state.status == AuthStatus.otpSent ||
        state.isBusy && state.phoneNumber.isNotEmpty) {
      return _FormSection(
        title: 'Enter OTP',
        subtitle: 'Enter the code sent to ${state.phoneNumber}.',
        children: [
          _OtpCodeField(controller: otpController, enabled: !state.isBusy),
          const SizedBox(height: 18),
          _MetalButton(
            loading: state.isBusy,
            label: 'Verify OTP',
            icon: Icons.check_circle_outline,
            onPressed: onVerifyOtp,
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: state.isBusy ? null : onRequestOtp,
            child: const Text(
              'Resend code',
              style: TextStyle(
                color: _textPrimary,
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 23),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: state.isBusy ? null : onChangePhone,
              style: TextButton.styleFrom(
                foregroundColor: _textPrimary,
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.arrow_back, size: 22),
              label: const Text(
                'Change phone number',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return _FormSection(
      title: 'Sign in',
      subtitle: 'Enter your phone number to continue with OTP.',
      children: [
        _LabeledField(
          label: 'PHONE NUMBER',
          controller: phoneController,
          hint: 'Phone number',
          prefixText: '+91  •  ',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 1, bottom: 17),
          child: Text(
            'A one-time code will be sent to this number.',
            style: TextStyle(color: _textSecondary, fontSize: 11),
          ),
        ),
        _MetalButton(
          loading: state.isBusy,
          label: 'Send OTP',
          icon: Icons.chat_bubble_outline,
          onPressed: onRequestOtp,
        ),
      ],
    );
  }
}

class _OtpCodeField extends StatefulWidget {
  const _OtpCodeField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  State<_OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<_OtpCodeField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _focusNode.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant _OtpCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focusNode.removeListener(_refresh);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VERIFICATION CODE',
          style: TextStyle(
            color: _textPrimary,
            fontFamily: 'IBM Plex Mono',
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w600,
            letterSpacing: .96,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: widget.enabled ? _focusNode.requestFocus : null,
          child: Stack(
            children: [
              Row(
                children: List.generate(6, (index) {
                  final hasValue = index < code.length;
                  final selected = _focusNode.hasFocus && index == code.length;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
                      child: _GlassBox(
                        height: 49,
                        borderRadius: 6,
                        borderColor: selected
                            ? AppColors.accent.withValues(alpha: .78)
                            : Colors.white.withValues(alpha: .22),
                        borderWidth: selected ? 1.2 : .8,
                        alignment: Alignment.center,
                        child: Text(
                          hasValue ? code[index] : '',
                          style: const TextStyle(
                            color: _textPrimary,
                            fontFamily: 'IBM Plex Mono',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 24,
            height: 30 / 24,
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          style: const TextStyle(
            color: _textSecondary,
            fontFamily: 'Inter',
            fontSize: 14,
            height: 22 / 14,
          ),
        ),
        const SizedBox(height: 19),
        ...children,
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.readOnly = false,
    this.prefixText,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _textPrimary,
              fontFamily: 'IBM Plex Mono',
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              letterSpacing: .96,
            ),
          ),
          const SizedBox(height: 10),
          _GlassBox(
            height: 49,
            borderColor: Colors.white.withValues(alpha: .24),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              readOnly: readOnly,
              style: const TextStyle(
                color: _textPrimary,
                fontFamily: 'Inter',
                fontSize: 16,
                height: 26 / 16,
              ),
              decoration: InputDecoration(
                hintText: hint,
                prefixText: prefixText,
                prefixStyle: const TextStyle(
                  color: _textPrimary,
                  fontFamily: 'Inter',
                  fontSize: 16,
                  height: 26 / 16,
                ),
                hintStyle: const TextStyle(
                  color: _textSecondary,
                  fontFamily: 'Inter',
                  fontSize: 16,
                ),
                prefixIcon: Icon(icon, color: _textPrimary, size: 23),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBox extends StatelessWidget {
  const _GlassBox({
    required this.child,
    required this.height,
    required this.borderColor,
    this.borderRadius = 5,
    this.borderWidth = .8,
    this.alignment,
  });

  final Widget child;
  final double height;
  final Color borderColor;
  final double borderRadius;
  final double borderWidth;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: .035),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            alignment: alignment,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: borderColor, width: borderWidth),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .105),
                  AppColors.inputFill.withValues(alpha: .48),
                  Colors.white.withValues(alpha: .035),
                ],
                stops: const [0, .52, 1],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _MetalButton extends StatelessWidget {
  const _MetalButton({
    required this.loading,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final bool loading;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.disabled, AppColors.divider],
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.mutedText, width: .7),
      ),
      child: SizedBox(
        height: 49,
        child: TextButton(
          onPressed: loading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: loading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  children: [
                    Icon(icon, size: 21),
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .96,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(25, 108, 25, 37),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'GLAZIA',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontFamily: 'Space Grotesk',
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          Text(
            'SECURE LIVING, SIMPLIFIED',
            style: TextStyle(
              color: AppColors.mutedText,
              fontFamily: 'IBM Plex Mono',
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }
}
