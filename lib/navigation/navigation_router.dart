import 'package:handlebar/storage/device/secure_storage.dart';
import 'package:handlebar/network/request_handler.dart';
import 'package:handlebar/views/login.dart';
import 'package:handlebar/views/home.dart';
import 'package:handlebar/views/study_consent.dart';
import 'package:handlebar/views/crepe_events_test.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The route configuration.
GoRouter navigationRouter() {
  return GoRouter(
    redirect: (context, state) {
      final requestHandler = RequestHandler();
      
      // Check if user is authenticated (RequestHandler should already be initialized)
      final isAuthenticated = requestHandler.isAuthenticated();
      
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
        path: '/crepe-events-test',
        builder: (BuildContext context, GoRouterState state) {
          return const CrepeEventsTest();
        },
      ),
    ],
  );
}

