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
        title: const Text(
          'GitHub Explorer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => widget.auth.logout(),
            icon: const Icon(Icons.logout),
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
                    return offline
                        ? Material(
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  'You are offline. Saved favorites are still available.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink();
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
