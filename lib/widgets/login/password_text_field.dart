import 'package:flutter/material.dart';

/// A text field for entering passwords
class PasswordTextField extends StatelessWidget {
  final TextEditingController passwordController;
  final Function(String)? onChanged;

  const PasswordTextField(
      {super.key, required this.passwordController, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: passwordController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: "Password",
        hintText: "Enter your password",
        prefixIcon: Icon(Icons.lock),
      ),
      obscureText: true,
      validator: _validatePassword,
      onChanged: onChanged,
    );
  }

  static String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }
}
