import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A button for authentication actions (login/registration)
class AuthButton extends StatelessWidget {
  final bool isLoading;
  final String loadingText;
  final VoidCallback? onPressed;
  final String text;

  const AuthButton({
    super.key,
    required this.isLoading,
    required this.loadingText,
    this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: PlatformElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(loadingText),
                ],
              )
            : Text(text),
      ),
    );
  }
}
