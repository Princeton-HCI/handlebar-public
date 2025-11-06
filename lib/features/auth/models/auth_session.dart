/// Represents the persisted auth token and minimal user data used by the app
class AuthSession {
  final String token;
  final Map<String, dynamic> userData;

  const AuthSession({
    required this.token,
    required this.userData,
  });
}
