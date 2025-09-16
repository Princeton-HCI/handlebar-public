import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

/// A text link for navigating to the forgot password page
class ForgotPasswordLink extends StatelessWidget {
  const ForgotPasswordLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Link(
      uri: Uri.parse('https://www.driversseat.co/contact'),
      builder: (BuildContext context, FollowLink? followLink) => TextButton(
        onPressed: followLink,
        child: const Text('Forgot Password?'),
      ),
    );
  }
}
