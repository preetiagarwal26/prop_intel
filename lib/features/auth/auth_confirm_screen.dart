import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';

enum ConfirmStatus { loading, success, error }

class AuthConfirmScreen extends ConsumerStatefulWidget {
  const AuthConfirmScreen({super.key});

  @override
  ConsumerState<AuthConfirmScreen> createState() => _AuthConfirmScreenState();
}

class _AuthConfirmScreenState extends ConsumerState<AuthConfirmScreen> {
  ConfirmStatus _status = ConfirmStatus.loading;
  String? _errorMessage;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    _resolveConfirmation();
  }

  Future<void> _resolveConfirmation() async {
    final uri = Uri.base;
    final hashParams = uri.fragment.isNotEmpty
        ? Uri.splitQueryString(uri.fragment)
        : <String, String>{};

    final error = uri.queryParameters['error'] ?? hashParams['error'];
    final errorDescription = uri.queryParameters['error_description'] ??
        hashParams['error_description'];
    final accessToken = hashParams['access_token'];
    final type = hashParams['type'];

    if (error != null) {
      setState(() {
        _status = ConfirmStatus.error;
        _errorMessage = Uri.decodeComponent(
          (errorDescription ?? error).replaceAll('+', ' '),
        );
      });
      return;
    }

    // Supabase may have already established a session from the URL hash.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final session = ref.read(supabaseClientProvider).auth.currentSession;

    if (!mounted) {
      return;
    }

    if (session != null) {
      setState(() {
        _status = ConfirmStatus.success;
        _hasSession = true;
      });
      return;
    }

    if (accessToken != null ||
        type == 'signup' ||
        type == 'email_change' ||
        (uri.fragment.isEmpty && uri.query.isEmpty)) {
      setState(() {
        _status = ConfirmStatus.success;
        _hasSession = false;
      });
      return;
    }

    // Tokens may still be processing — brief wait then show success.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) {
      return;
    }

    final lateSession = ref.read(supabaseClientProvider).auth.currentSession;
    setState(() {
      _status = ConfirmStatus.success;
      _hasSession = lateSession != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (_status) {
              ConfirmStatus.loading => _StatusCard(
                  icon: Icons.hourglass_top,
                  title: 'Confirming your email',
                  message: 'Please wait while we finish verification.',
                ),
              ConfirmStatus.success => _StatusCard(
                  icon: Icons.check_circle_outline,
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: 'Email confirmed',
                  message: _hasSession
                      ? 'Your account is verified. Continue to your portfolio.'
                      : 'Your account is verified. Sign in to the app to continue.',
                  actionLabel: _hasSession ? 'Go to portfolio' : 'Sign in',
                  onAction: () => context.go(_hasSession ? '/portfolio' : '/login'),
                ),
              ConfirmStatus.error => _StatusCard(
                  icon: Icons.error_outline,
                  iconColor: Theme.of(context).colorScheme.error,
                  title: 'Confirmation failed',
                  message: _errorMessage ??
                      'The confirmation link is invalid or has expired.',
                  actionLabel: 'Back to sign in',
                  onAction: () => context.go('/login'),
                ),
            },
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
