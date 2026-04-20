import 'package:flutter/foundation.dart';
import 'package:handlebar/features/crepe/presentation/views/accessibility_screen.dart';
import 'package:handlebar/features/researcher/presentation/view_models/collector_creation_view_model.dart';
import 'package:handlebar/features/researcher/presentation/views/create_collector_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/features/terms/presentation/views/terms_screen.dart';
import 'package:provider/provider.dart';

import '../core/shared_widgets/handlebar_layout.dart';
import '../core/storage/auth_token_store.dart';
import '../features/auth/presentation/views/login_screen.dart';
import '../features/auth/presentation/views/signup_flow_screen.dart';
import '../features/home/presentation/view_models/participant_home_view_model.dart';
import '../features/home/presentation/view_models/researcher_home_view_model.dart';
import '../features/home/presentation/views/participant_home_screen.dart';
import '../features/home/presentation/views/researcher_home_screen.dart';
import '../features/research_group/presentation/view_models/research_group_detail_view_model.dart';
import '../features/research_group/presentation/views/research_group_detail.dart';
import '../features/researcher/presentation/view_models/create_study_view_model.dart';
import '../features/researcher/presentation/views/create_study_screen.dart';
import 'app_locator.dart';

// Create GlobalKeys for the navigators
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

/// The route configuration.
GoRouter navigationRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: getIt<AuthTokenStore>() as Listenable,
    initialLocation: '/',
    redirect: (context, state) {
      // =================================
      // IDENTITY AND LEGAL/OS COMPLIANCE
      // =================================
      final authStore = getIt<AuthTokenStore>();

      // Grab our synchronous state
      final isAuthenticated = authStore.isAuthenticated;
      final needsTerms = authStore.needsTermsAcceptance;
      final needsAccessibility = authStore.needsAccessibilityAcceptance;

      final isAuthRoute =
          state.fullPath == '/login' || state.fullPath == '/register';
      final isAcceptTermsRoute = state.fullPath == '/accept-terms';
      final isAcceptAccessibilityRoute =
          state.fullPath == '/accept-accessibility';

      // WATERFALL STEP 1: Are they logged in at all?
      if (!isAuthenticated) {
        if (isAuthRoute) return null;
        return '/login';
      }

      // WATERFALL STEP 2: Do they need to accept Terms?
      if (needsTerms) {
        if (isAcceptTermsRoute) return null;
        return '/accept-terms';
      }

      // WATERFALL STEP 3: Do they need to enable Accessibility?
      // ONLY applies if they are NOT on web
      if (!kIsWeb && needsAccessibility) {
        if (isAcceptAccessibilityRoute) return null;
        return '/accept-accessibility';
      }

      // Block Web users from manually typing /accept-accessibility in the URL
      if (kIsWeb && isAcceptAccessibilityRoute) {
        return '/';
      }

      // WATERFALL STEP 4: Fully compliant
      // If they are trying to visit a trapdoor or auth route, send them Home.
      if (isAuthRoute || isAcceptTermsRoute || isAcceptAccessibilityRoute) {
        return '/';
      }

      // Let them visit normal routes (like / or /studies/123)
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const SignupFlowScreen(),
      ),
      GoRoute(
        path: '/accept-terms',
        builder: (context, state) => const TermsScreen(isMandatory: true),
      ),
      GoRoute(
        path: '/accept-accessibility',
        builder: (context, state) =>
            const AccessibilityScreen(isMandatory: true),
      ),

      // Layout shell
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          // Wrap the child in our smart responsive layout
          return HandlebarLayout(
            child: child,
          );
        },
        routes: [
          // Top Level Routes
          GoRoute(
            path: '/',
            builder: (context, state) {
              // 1. Return the correct screen wrapped in its Provider
              final role = getIt<AuthTokenStore>().userRole;
              if (role == 'researcher') {
                return Provider(
                  create: (_) => ResearcherHomeViewModel(),
                  dispose: (_, vm) => vm.dispose(),
                  child: const ResearcherHomeScreen(),
                );
              } else {
                // Default to the Participant view
                return Provider(
                  create: (_) => ParticipantHomeViewModel(),
                  dispose: (_, vm) => vm.dispose(),
                  child: const ParticipantHomeScreen(),
                );
              }
            },
          ),
          GoRoute(
            path: '/accessibility',
            builder: (context, state) =>
                const AccessibilityScreen(isMandatory: false),
          ),
          GoRoute(
            path: '/terms',
            builder: (context, state) => const TermsScreen(isMandatory: false),
          ),
          GoRoute(
              path: '/create-study',
              redirect: (context, state) {
                final role = getIt<AuthTokenStore>().userRole;
                if (role != 'researcher') {
                  // If a participant tries to sneak in, kick them back to their Home screen
                  return '/';
                }

                // If they are a researcher, let them through
                return null;
              },
              builder: (context, state) => Provider(
                    create: (_) => CreateStudyViewModel(),
                    dispose: (_, vm) => vm.dispose(),
                    child: const CreateStudyScreen(),
                  )),
          // Detail Routes (Sub-routes of /studies)
          GoRoute(
              path: '/studies/:code',
              builder: (context, state) {
                final studyCode = state.pathParameters['code']!;

                return Provider(
                  create: (_) => ResearchGroupDetailViewModel(
                    studyCode: studyCode,
                  ),
                  dispose: (_, vm) => vm.dispose(),
                  child: const ResearchGroupDetail(),
                );
              }),
          GoRoute(
              path: '/studies/:code/define-collector',
              redirect: (context, state) {
                if (kIsWeb) {
                  final code = state.pathParameters['code'];
                  return '/studies/$code';
                }
                return null;
              },
              builder: (context, state) {
                final studyCode = state.pathParameters['code']!;

                // We pass the studyCode to the ViewModel instead of an ID
                return Provider(
                  create: (_) =>
                      CollectorCreationViewModel(studyCode: studyCode),
                  dispose: (_, vm) => vm.dispose(),
                  child: const CreateCollectorPage(),
                );
              })
        ],
      )
    ],
  );
}
