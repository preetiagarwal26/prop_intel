import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../data/models/document_upload_draft.dart';
import 'features/auth/auth_confirm_screen.dart';
import 'features/auth/check_email_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/portfolio/portfolio_screen.dart';
import 'features/property/property_detail_screen.dart';
import 'features/review/review_screen.dart';
import 'features/upload/upload_document_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/portfolio',
    redirect: (context, state) {
      final session = authState.valueOrNull?.session;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/signup/check-email' ||
          state.matchedLocation == '/auth/confirm';

      if (session == null && !isAuthRoute) {
        return '/login';
      }
      if (session != null && isAuthRoute) {
        return '/portfolio';
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
        path: '/portfolio',
        builder: (context, state) => const PortfolioScreen(),
      ),
      GoRoute(
        path: '/upload',
        builder: (context, state) => const UploadDocumentScreen(),
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
      title: 'Real Estate Portfolio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B4332)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
