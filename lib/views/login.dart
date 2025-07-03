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
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Image.asset('assets/logo-small.png'),
                const Text("Log In"),
                const Text("Welcome back!"),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextField(
                    controller: TextEditingController(text: email),
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Enter your email"),
                    onChanged: (value) => email = value,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextField(
                    controller: TextEditingController(text: password),
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Enter your password"),
                    onChanged: (value) => password = value,
                    obscureText: true,
                  ),
                ),
                Link(
                  uri: Uri.parse(
                      'https://www.driversseat.co/contact'),
                  builder: (BuildContext context, FollowLink? followLink) =>
                      PlatformElevatedButton(
                        onPressed: followLink,
                        child: const Text('Forgot Password?'),
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
                PlatformElevatedButton(
                  onPressed: () async {
                    await requestHandler.requestNewUser(email, password);
                  },
                  child: const Text("I'm a New User"),
                ),
          ]),
        ),
      ),
    );
  }
}
