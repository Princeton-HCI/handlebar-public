import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

/// How far along the participant is in granting location access.
///
/// Android splits this into two grants that cannot be requested together:
/// foreground ("While using the app") first, then background ("Allow all the
/// time"). On API 30+ the second one cannot be requested with a dialog at all —
/// the OS requires the participant to change it on a settings screen.
enum LocationPermissionStatus {
  /// Nothing granted. The foreground dialog is the next step.
  denied,

  /// Foreground granted, background not. Sampling works only while Handlebar
  /// is visible, which is never during real collection — the participant is in
  /// DoorDash, not in Handlebar.
  foregroundOnly,

  /// "Allow all the time". The only state in which collection actually works.
  always,

  /// Denied permanently, or blocked by policy. A dialog will not appear again;
  /// the only route is the app's settings page.
  permanentlyDenied,

  /// Not an Android device, so there is nothing to grant.
  unsupported,
}

/// Wraps the location and notification permission flows.
///
/// Uses `permission_handler` rather than the Crepe plugin: `CrepePlugin` holds
/// only an application `Context` and is not `ActivityAware`, so it cannot call
/// `requestPermissions` at all. It can only fire settings Intents, which is why
/// accessibility is granted that way.
class LocationPermissionService {
  final _logger = Logger('LocationPermissionService');

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  Future<LocationPermissionStatus> check() async {
    if (!_isAndroid) return LocationPermissionStatus.unsupported;

    final fine = await Permission.locationWhenInUse.status;
    if (fine.isPermanentlyDenied) {
      return LocationPermissionStatus.permanentlyDenied;
    }
    if (!fine.isGranted) return LocationPermissionStatus.denied;

    final always = await Permission.locationAlways.status;
    return always.isGranted
        ? LocationPermissionStatus.always
        : LocationPermissionStatus.foregroundOnly;
  }

  /// Step one: the foreground dialog. Safe to call when already granted.
  Future<LocationPermissionStatus> requestForeground() async {
    if (!_isAndroid) return LocationPermissionStatus.unsupported;

    final result = await Permission.locationWhenInUse.request();
    _logger.info('foreground location request -> $result');

    if (result.isPermanentlyDenied) {
      return LocationPermissionStatus.permanentlyDenied;
    }
    return result.isGranted
        ? LocationPermissionStatus.foregroundOnly
        : LocationPermissionStatus.denied;
  }

  /// Step two: "Allow all the time".
  ///
  /// Must be called only after foreground is granted — requesting it first is
  /// an automatic denial on Android. On API 30+ this shows no dialog; it sends
  /// the participant to a settings screen, so the caller must re-[check] when
  /// the app resumes rather than trusting the returned value.
  Future<LocationPermissionStatus> requestBackground() async {
    if (!_isAndroid) return LocationPermissionStatus.unsupported;

    final fine = await Permission.locationWhenInUse.status;
    if (!fine.isGranted) {
      _logger.warning(
          'refusing to request background location before foreground is granted');
      return LocationPermissionStatus.denied;
    }

    final result = await Permission.locationAlways.request();
    _logger.info('background location request -> $result');

    if (result.isGranted) return LocationPermissionStatus.always;
    if (result.isPermanentlyDenied) {
      return LocationPermissionStatus.permanentlyDenied;
    }
    return LocationPermissionStatus.foregroundOnly;
  }

  /// Needed on API 33+ for the "collecting location" notification to be
  /// visible. Deliberately not blocking: collection still works without it,
  /// the participant just loses the transparency signal.
  Future<bool> requestNotifications() async {
    if (!_isAndroid) return true;
    final result = await Permission.notification.request();
    _logger.info('notification request -> $result');
    return result.isGranted;
  }

  Future<bool> hasNotificationPermission() async {
    if (!_isAndroid) return true;
    return (await Permission.notification.status).isGranted;
  }

  /// The only remaining route once a permission is permanently denied.
  Future<bool> openSettings() => openAppSettings();
}
