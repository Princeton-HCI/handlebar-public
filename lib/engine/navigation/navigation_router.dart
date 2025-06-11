import 'package:dsc_mobile_rework/engine/storage/device/secure_storage.dart';
import 'package:dsc_mobile_rework/views/login.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The route configuration.
GoRouter navigationRouter() {
  return GoRouter(
    redirect: (context, state) {
      final isAuthenticated = true;
      final localStorage = SecureStorage();
      if (!isAuthenticated && state.fullPath != '/login') {
        if (localStorage.refreshToken.isNotEmpty) {
          return null;
        }
        else {
          return '/login';
        }
      }
      // If authenticated and on login page, send to home
      if (isAuthenticated && state.fullPath == '/login') {
        return '/';
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const Login();
        },
        routes: <RouteBase>[
          GoRoute(path: 'login', builder: (BuildContext context, GoRouterState state) {
            return const Login();
          }),
        ],
      ),
    ],
  );
}

