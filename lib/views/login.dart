import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:url_launcher/link.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
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
                    //controller: TextEditingController(text: ""),
                    //keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Enter your email"),
                    //onChanged: (value) => openReport.latitude = value,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextField(
                    //controller: TextEditingController(text: ""),
                    //keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Enter your password"),
                    //onChanged: (value) => openReport.latitude = value,
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
                  onPressed: () {},
                  child: const Text("Login"),
                ),
                PlatformElevatedButton(
                  onPressed: () {},
                  child: const Text("I'm a New User"),
                ),
          ]),
        ),
      ),
    );
  }
}
