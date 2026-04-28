import 'package:flutter/foundation.dart';
import 'package:handlebar/features/crepe/presentation/views/accessibility_screen.dart';
import 'package:handlebar/features/researcher/presentation/view_models/collector_creation_view_model.dart';
import 'package:handlebar/features/researcher/presentation/views/create_collector_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:handlebar/features/study/presentation/views/study_screen.dart';
import 'package:handlebar/features/terms/presentation/views/terms_screen.dart';
import 'package:provider/provider.dart';

import '../core/shared_services/notification_service.dart';
import '../core/shared_widgets/handlebar_layout.dart';
import '../core/storage/auth_token_store.dart';
import '../features/auth/presentation/view_models/login_viewmodel.dart';
import '../features/auth/presentation/view_models/signup_viewmodel.dart';
import '../features/auth/presentation/views/login_screen.dart';
import '../features/auth/presentation/views/signup_flow_screen.dart';
import '../features/crepe/presentation/view_models/accessibility_view_model.dart';
import '../features/home/presentation/view_models/participant_home_view_model.dart';
import '../features/home/presentation/view_models/researcher_home_view_model.dart';
import '../features/home/presentation/views/participant_home_screen.dart';
import '../features/home/presentation/views/researcher_home_screen.dart';
import '../features/auth/presentation/view_models/create_study_view_model.dart';
import '../features/researcher/presentation/views/create_study_screen.dart';
import '../features/study/presentation/view_models/study_view_model.dart';
import '../features/terms/presentation/view_models/terms_view_model.dart';
import 'app_locator.dart';

final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

/// The route configuration.
final GoRouter navigationRouter = GoRouter(
  navigatorKey: NotificationService().navigatorKey,
  refreshListenable: getIt<AuthTokenStore>() as Listenable,
  initialLocation: '/',
  redirect: (context, state) {
    // =================================
    // IDENTITY AND LEGAL/OS COMPLIANCE
    // =================================
    final authStore = getIt<AuthTokenStore>();

    // Grab our synchronous state
    final isInitialized = authStore.isInitialized;
    final isAuthenticated = authStore.isAuthenticated;
    final needsTerms = authStore.needsTermsAcceptance;
    final needsAccessibility = authStore.needsAccessibilityAcceptance;

    final isAuthRoute =
        state.fullPath == '/login' || state.fullPath == '/register';
    final isAcceptTermsRoute = state.fullPath == '/accept-terms';
    final isAcceptAccessibilityRoute =
        state.fullPath == '/accept-accessibility';
    final isLoadingRoute = state.fullPath == '/loading';

    // WATERFALL STEP 0: Wait for the app to boot
    if (!isInitialized) {
      if (isLoadingRoute) return null;
      return '/loading';
    }

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
    if (isAuthRoute ||
        isAcceptTermsRoute ||
        isAcceptAccessibilityRoute ||
        isLoadingRoute) {
      return '/';
    }

    // Let them visit normal routes (like / or /studies/123)
    return null;
  },
  routes: [
    GoRoute(
      path: '/loading',
      builder: (context, state) => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => Provider(
        create: (_) => getIt<LoginViewModel>(),
        dispose: (_, vm) => vm.dispose(),
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => Provider(
        create: (_) => getIt<SignupViewModel>(),
        dispose: (_, vm) => vm.dispose(),
        child: const SignupFlowScreen(),
      ),
    ),
    GoRoute(
      path: '/accept-terms',
      builder: (context, state) => Provider(
        create: (_) => getIt<TermsViewModel>(),
        dispose: (_, vm) => vm.dispose(),
        child: const TermsScreen(isMandatory: true),
      ),
    ),
    GoRoute(
      path: '/accept-accessibility',
      builder: (context, state) => Provider(
        create: (_) => getIt<AccessibilityViewModel>(),
        dispose: (_, vm) => vm.dispose(),
        child: const AccessibilityScreen(isMandatory: true),
      ),
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
                create: (_) => getIt<ResearcherHomeViewModel>(),
                dispose: (_, vm) => vm.dispose(),
                child: const ResearcherHomeScreen(),
              );
            } else {
              // Default to the Participant view
              return Provider(
                create: (_) => getIt<ParticipantHomeViewModel>(),
                dispose: (_, vm) => vm.dispose(),
                child: const ParticipantHomeScreen(),
              );
            }
          },
        ),
        GoRoute(
          path: '/terms',
          builder: (context, state) => Provider(
            create: (_) => getIt<TermsViewModel>(),
            dispose: (_, vm) => vm.dispose(),
            child: const TermsScreen(isMandatory: true),
          ),
        ),
        GoRoute(
          path: '/accessibility',
          builder: (context, state) => Provider(
            create: (_) => getIt<AccessibilityViewModel>(),
            dispose: (_, vm) => vm.dispose(),
            child: const AccessibilityScreen(isMandatory: true),
          ),
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
                  create: (_) => getIt<CreateStudyViewModel>(),
                  dispose: (_, vm) => vm.dispose(),
                  child: const CreateStudyScreen(),
                )),
        // Detail Routes (Sub-routes of /studies)
        GoRoute(
            path: '/studies/:code',
            builder: (context, state) {
              final studyCode = state.pathParameters['code']!;

              return Provider(
                create: (_) => StudyViewModel(
                  studyCode: studyCode,
                ),
                dispose: (_, vm) => vm.dispose(),
                child: const StudyScreen(),
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

              return Provider(
                create: (_) => CollectorCreationViewModel(studyCode: studyCode),
                dispose: (_, vm) => vm.dispose(),
                child: const CreateCollectorPage(),
              );
            })
      ],
    )
  ],
);
