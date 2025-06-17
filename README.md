# dsc_mobile_rework

Driver's Seat API user interface for iOS and Android devices

## Installation from Git

To use the latest version from the main branch, add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  crepe_plugin:
    git:
      url: git@github.com:Princeton-HCI/crepe-flutter-plugin.git
      ref: main
```

This will use the main branch of the plugin, ensuring you have access to the latest features and updates.

### SSH Keys Requirement

**Important**: For local development, you must have SSH keys configured with GitHub access to the Princeton-HCI organization repository. If you don't have SSH access configured, the dependency installation will fail.

### Making Changes to the Plugin

To make changes to the plugin:
1. Push your changes to the main branch of the plugin repository
2. Run `flutter pub get` in your project repository to fetch the latest version
3. For development, you may need to clear Flutter's package cache: `flutter pub cache clean`

**Note**: Since this dependency points to the `main` branch, your application will automatically use the latest changes from the plugin repository each time you run `flutter pub get`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
