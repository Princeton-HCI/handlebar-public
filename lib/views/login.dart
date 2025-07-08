import 'package:dsc_mobile_rework/network/request_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/link.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    final RequestHandler requestHandler = RequestHandler();
    String email = "";
    String password = "";
    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(
          child: Column(children: [
            Image.asset('assets/logo-small.png'),
            PlatformText("Welcome back!"),
            PlatformText("Log In"),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: PlatformTextField(
                controller: TextEditingController(text: email),
                hintText: "Enter your email",
                onChanged: (value) => email = value,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: PlatformTextField(
                controller: TextEditingController(text: password),
                hintText: "Enter your password",
                onChanged: (value) => password = value,
                obscureText: true,
              ),
            ),
            PlatformElevatedButton(
              onPressed: () async {
                await requestHandler.requestSession(email, password);
                if (context.mounted) {
                  context.go('/'); // Navigate to home using GoRouter
                }
              },
              child: const Text("Login"),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Link(
                  uri: Uri.parse('https://www.driversseat.co/contact'),
                  builder: (BuildContext context, FollowLink? followLink) =>
                      PlatformTextButton(
                    onPressed: followLink,
                    child: const Text('Forgot Password?'),
                  ),
                ),
                PlatformTextButton(
                  onPressed: () async {
                    await requestHandler.requestNewUser(email, password);
                  },
                  child: const Text("I'm a New User"),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
