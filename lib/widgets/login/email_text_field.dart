import 'package:flutter/material.dart';

/// A text field for entering email addresses
class EmailTextField extends StatelessWidget {
  final TextEditingController emailController;
  final Function(String)? onChanged;

  const EmailTextField(
      {super.key, required this.emailController, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: emailController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: "Email",
        hintText: "Enter your email",
        prefixIcon: Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: _validateEmail,
      onChanged: onChanged,
    );
  }

  static String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}
