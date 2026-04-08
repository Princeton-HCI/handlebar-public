import 'package:handlebar/features/research_group/presentation/views/research_group_dashboard.dart';
import 'package:handlebar/features/researcher/presentation/view_models/collector_creation_view_model.dart';
import 'package:handlebar/features/researcher/presentation/views/create_collector_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/research_group/models/research_group.dart';
import '../features/research_group/presentation/view_models/research_group_detail_view_model.dart';
import '../features/research_group/presentation/views/research_group_detail.dart';
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
          path: '/dashboard',
          builder: (BuildContext context, GoRouterState state) {
            return const ResearchGroupDashboard();
          }),
      GoRoute(
          path: '/group-detail',
          builder: (BuildContext context, GoRouterState state) {
            final group = state.extra as ResearchGroup;

            return ChangeNotifierProvider(
              create: (_) => ResearchGroupDetailViewModel(initialGroup: group),
              child: const ResearchGroupDetail(),
            );
          }),
      GoRoute(
          path: '/define-collector',
          builder: (BuildContext context, GoRouterState state) {
            final groupId = state.extra as int;

            return ChangeNotifierProvider(
              create: (_) => CollectorCreationViewModel(groupId: groupId),
              child: const CreateCollectorPage(),
            );
          }),
    ],
  );
}
