import 'package:handlebar/features/researcher/presentation/views/researcher_settings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_locator.dart';
import '../features/home/presentation/views/home.dart';
import '../features/auth/presentation/views/login.dart';
import '../features/terms/presentation/views/study_consent.dart';

/// The route configuration.
GoRouter navigationRouter() {
  return GoRouter(
    redirect: (context, state) {
      // Check if user is authenticated (RequestHandler should already be initialized)
      final isAuthenticated = tokens.isAuthenticated;

      // If not authenticated and not already on login page, redirect to login
      if (!isAuthenticated && state.fullPath != '/login') {
        return '/login';
      }

      // If authenticated and on login page, redirect to home
      if (isAuthenticated && state.fullPath == '/login') {
        return '/';
      }

      return null; // Allow navigation to requested route
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const Home();
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
      GoRoute(
        path: '/replay-snapshot',
        builder: (BuildContext context, GoRouterState state) {
          return const ResearcherSettings();
        },
      ),
    ],
  );
}
