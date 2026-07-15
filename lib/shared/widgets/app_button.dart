import 'package:flutter/material.dart';

import '../../app/app_colors.dart';

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool outlined;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null || widget.loading) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final buttonIcon = widget.loading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : widget.icon == null
        ? null
        : Icon(widget.icon);

    final button = widget.outlined
        ? OutlinedButton.icon(
            onPressed: widget.loading ? null : widget.onPressed,
            icon: buttonIcon ?? const SizedBox.shrink(),
            label: Text(widget.label),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
            ),
          )
        : FilledButton.icon(
            onPressed: widget.loading ? null : widget.onPressed,
            icon: buttonIcon ?? const SizedBox.shrink(),
            label: Text(widget.label),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.button,
              foregroundColor: Colors.white,
              shadowColor: AppColors.accent.withValues(alpha: 0.35),
              elevation: 8,
            ),
          );

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerCancel: (_) => _setPressed(false),
      onPointerUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: widget.loading ? 0.82 : 1,
          duration: const Duration(milliseconds: 180),
          child: SizedBox(width: double.infinity, child: button),
        ),
      ),
    );
  }
}
