import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    this.title = 'Welcome back',
    this.subtitle = 'Sign in to manage your portfolio',
  });

  final Widget child;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;

          if (wide) {
            return Row(
              children: [
                Expanded(
                  child: Container(
                    color: AppColors.ink,
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PropVault',
                          style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white,
                            fontSize: 36,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'INVESTOR PLATFORM',
                          style: GoogleFonts.dmSans(
                            color: AppColors.gold,
                            letterSpacing: 1.5,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Portfolio intelligence for\nindividual real estate investors.',
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(48),
                      child: _FormCard(title: title, subtitle: subtitle, child: child),
                    ),
                  ),
                ),
              ],
            );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    Text(
                      'PropVault',
                      style: GoogleFonts.dmSerifDisplay(
                        color: AppColors.text1,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'INVESTOR PLATFORM',
                      style: GoogleFonts.dmSans(
                        color: AppColors.goldDark,
                        letterSpacing: 1.5,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _FormCard(title: title, subtitle: subtitle, child: child),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PropVaultFormSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text3),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class PropVaultFormSurface extends StatelessWidget {
  const PropVaultFormSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
