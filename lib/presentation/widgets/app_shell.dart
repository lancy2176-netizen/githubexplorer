import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../data/auth_repository.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child, required this.auth});
  final Widget child;
  final AuthRepository auth;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final connectivity = Connectivity();
  late Future<List<ConnectivityResult>> initialConnectivity = connectivity
      .checkConnectivity();

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.code_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GitHub Explorer',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'DEVELOPER DIRECTORY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              tooltip: 'Sign out',
              onPressed: () => widget.auth.logout(),
              icon: const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<List<ConnectivityResult>>(
            future: initialConnectivity,
            builder: (context, snapshot) =>
                StreamBuilder<List<ConnectivityResult>>(
                  stream: connectivity.onConnectivityChanged,
                  initialData: snapshot.data,
                  builder: (context, state) {
                    final offline =
                        state.hasData &&
                        state.data!.every(
                          (result) => result == ConnectivityResult.none,
                        );
                    return AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: offline
                          ? Material(
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer,
                              child: SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 9,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.wifi_off_rounded,
                                        size: 17,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'You’re offline · Saved favorites are still available',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onErrorContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
          ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: loc == '/favorites' ? 1 : 0,
        onDestinationSelected: (i) => context.go(i == 0 ? '/' : '/favorites'),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favorites'),
        ],
      ),
    );
  }
}
