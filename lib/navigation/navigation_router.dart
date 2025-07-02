import 'package:dsc_mobile_rework/storage/device/secure_storage.dart';
import 'package:dsc_mobile_rework/views/login.dart';
import 'package:dsc_mobile_rework/views/home.dart';
import 'package:dsc_mobile_rework/views/study_consent.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The route configuration.
GoRouter navigationRouter() {
  return GoRouter(
    redirect: (context, state) {
      final isAuthenticated = true; // Mock authentication for now
      final localStorage = SecureStorage();
      
      if (!isAuthenticated && state.fullPath != '/login') {
        if (localStorage.refreshToken.isNotEmpty) {
          return null;
        }
        else {
          return '/login';
        }
      }
      return null; // Allow navigation to any route when authenticated
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const Home(); // Fixed: Home screen instead of Login
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const Login();
        },
      ),
      GoRoute(
        path: '/study-consent',
        builder: (BuildContext context, GoRouterState state) {
          return const StudyConsent();
        },
      ),
    ],
  );
}

