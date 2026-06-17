import 'package:flutter/material.dart';

/// WHY THIS FILE EXISTS:
/// Every form in this app (login, register, add property, etc.) needs text
/// fields with the same look (rounded border, label, error text styling).
/// Instead of repeating that styling code in every screen, we define it
/// ONCE here. If the designer later says "make all input fields have a
/// slightly different border radius," you change ONE file instead of
/// twenty.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        // Rounded border everywhere - this is what gives forms a "modern"
        // feel compared to the default sharp-cornered Material text field.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
    );
  }
}
