import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';

enum AppNav { dashboard, properties, attention }

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.currentNav,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.floatingActionButton,
  });

  final AppNav currentNav;
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attentionAsync = ref.watch(attentionProvider);
    final openCount = attentionAsync.valueOrNull?.length ?? 0;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    if (wide) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        floatingActionButton: floatingActionButton,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              currentNav: currentNav,
              openCount: openCount,
              onSignOut: () => _signOut(context, ref),
            ),
            Expanded(
              child: _MainArea(
                title: title,
                subtitle: subtitle,
                actions: actions,
                body: body,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      drawer: Drawer(
        backgroundColor: AppColors.ink,
        child: _Sidebar(
          currentNav: currentNav,
          openCount: openCount,
          onSignOut: () => _signOut(context, ref),
          inDrawer: true,
        ),
      ),
      appBar: AppBar(
        title: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
        actions: [
          ...actions,
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }

    // Invalidate before await — navigation after sign-out can dispose this widget.
    ref.invalidate(portfolioProvider);
    ref.invalidate(attentionProvider);

    await ref.read(supabaseClientProvider).auth.signOut();
  }
}

class SecondaryScaffold extends StatelessWidget {
  const SecondaryScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.onBack,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack ?? () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

class _MainArea extends StatelessWidget {
  const _MainArea({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.body,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text3),
                      ),
                    ],
                  ],
                ),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: actions),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
            child: body,
          ),
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.currentNav,
    required this.openCount,
    required this.onSignOut,
    this.inDrawer = false,
  });

  final AppNav currentNav;
  final int openCount;
  final VoidCallback onSignOut;
  final bool inDrawer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: inDrawer ? null : 220,
      color: AppColors.ink,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: _Logo(),
            ),
            const Divider(height: 1, color: Color(0x14FFFFFF)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                children: [
                  _NavSection(label: 'Portfolio'),
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    selected: currentNav == AppNav.dashboard,
                    onTap: () => _go(context, '/dashboard'),
                  ),
                  _NavItem(
                    icon: Icons.home_work_outlined,
                    label: 'Properties',
                    selected: currentNav == AppNav.properties,
                    onTap: () => _go(context, '/properties'),
                  ),
                  _NavItem(
                    icon: Icons.notifications_outlined,
                    label: 'Needs Attention',
                    selected: currentNav == AppNav.attention,
                    badge: openCount > 0 ? '$openCount' : null,
                    onTap: () => _go(context, '/attention'),
                  ),
                  const SizedBox(height: 8),
                  _NavSection(label: 'Tools'),
                  _NavItem(
                    icon: Icons.upload_file_outlined,
                    label: 'Upload Document',
                    selected: false,
                    onTap: () => _go(context, '/upload'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x14FFFFFF)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout, size: 18, color: Colors.white70),
                label: const Text('Sign out', style: TextStyle(color: Colors.white70)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    if (inDrawer) {
      Navigator.of(context).pop();
    }
    context.go(route);
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PropVault',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'INVESTOR PLATFORM',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.gold,
                letterSpacing: 1.5,
              ),
        ),
      ],
    );
  }
}

class _NavSection extends StatelessWidget {
  const _NavSection({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.25),
              letterSpacing: 1.5,
            ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected
            ? AppColors.gold.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? AppColors.goldLight : Colors.white.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? AppColors.goldLight : Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.notificationDot,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top-bar action buttons styled like the vision mockup.
class PropVaultTopActions extends ConsumerWidget {
  const PropVaultTopActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attentionAsync = ref.watch(attentionProvider);
    final openCount = attentionAsync.valueOrNull?.length ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NotifButton(
          count: openCount,
          onTap: () => context.push('/attention'),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: () => context.push('/upload'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Upload Document'),
        ),
      ],
    );
  }
}

class _NotifButton extends StatelessWidget {
  const _NotifButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(Icons.notifications_outlined, size: 20, color: AppColors.text2),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.notificationDot,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
