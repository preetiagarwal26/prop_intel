import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'core/routing/go_router_refresh_stream.dart';
import '../data/models/document_upload_draft.dart';
import 'features/attention/attention_screen.dart';
import 'features/auth/auth_confirm_screen.dart';
import 'features/auth/check_email_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/properties/properties_screen.dart';
import 'features/property/document_detail_screen.dart';
import 'features/property/property_detail_screen.dart';
import 'features/review/review_screen.dart';
import 'features/upload/upload_document_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authRefresh = GoRouterRefreshStream(client.auth.onAuthStateChange);
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final session = client.auth.currentSession;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/signup/check-email' ||
          state.matchedLocation == '/auth/confirm';

      if (session == null && !isAuthRoute) {
        return '/login';
      }
      if (session != null && isAuthRoute) {
        return '/dashboard';
      }
      if (state.matchedLocation == '/portfolio') {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/signup/check-email',
        builder: (context, state) {
          final email = state.extra as String? ?? 'your email';
          return CheckEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: '/auth/confirm',
        builder: (context, state) => const AuthConfirmScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/portfolio',
        redirect: (context, state) => '/dashboard',
      ),
      GoRoute(
        path: '/properties',
        builder: (context, state) => const PropertiesScreen(),
      ),
      GoRoute(
        path: '/attention',
        builder: (context, state) => const AttentionScreen(),
      ),
      GoRoute(
        path: '/upload',
        builder: (context, state) {
          final onboarding = state.uri.queryParameters['onboarding'] == '1';
          return UploadDocumentScreen(onboardingMode: onboarding);
        },
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) {
          final draft = state.extra as DocumentUploadDraft?;
          if (draft == null) {
            return const UploadDocumentScreen();
          }
          return ReviewScreen(draft: draft);
        },
      ),
      GoRoute(
        path: '/property/:id',
        builder: (context, state) {
          final propertyId = state.pathParameters['id']!;
          return PropertyDetailScreen(propertyId: propertyId);
        },
        routes: [
          GoRoute(
            path: 'document/:docId',
            builder: (context, state) {
              final propertyId = state.pathParameters['id']!;
              final documentId = state.pathParameters['docId']!;
              return DocumentDetailScreen(
                propertyId: propertyId,
                documentId: documentId,
              );
            },
          ),
        ],
      ),
    ],
  );
});

class RealEstatePortfolioApp extends ConsumerWidget {
  const RealEstatePortfolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PropVault',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
