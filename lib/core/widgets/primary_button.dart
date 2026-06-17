import 'package:flutter/material.dart';

/// WHY THIS FILE EXISTS:
/// Almost every screen has a "main action" button (Log In, Register, Save,
/// Send Request, etc.) and almost all of them need to show a SPINNER while
/// an async operation is in progress, and be DISABLED during that time (so
/// the user can't double-tap and, e.g., submit a form twice).
///
/// Wrapping this logic in one widget means every primary button in the app
/// automatically gets this loading/disabled behavior "for free," and looks
/// consistent.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        // While loading, `onPressed` becomes null, which Flutter
        // automatically renders as a disabled (greyed out) button.
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
