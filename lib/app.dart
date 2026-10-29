import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'data/auth_repository.dart';
import 'data/favorites_repository.dart';
import 'data/github_api.dart';
import 'presentation/screens/favorites_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/search_screen.dart';
import 'presentation/widgets/app_shell.dart';

class GitHubExplorer extends StatefulWidget {
  const GitHubExplorer({
    super.key,
    required this.auth,
    required this.favorites,
  });
  final AuthRepository auth;
  final FavoritesRepository favorites;
  @override
  State<GitHubExplorer> createState() => _GitHubExplorerState();
}

class _GitHubExplorerState extends State<GitHubExplorer> {
  late final GitHubApi api = GitHubApi()..token = widget.auth.token;
  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_syncToken);
    api.token = widget.auth.token;
  }

  void _syncToken() => api.token = widget.auth.token;

  @override
  void dispose() {
    widget.auth.removeListener(_syncToken);
    router.dispose();
    super.dispose();
  }

  late final GoRouter router = GoRouter(
    initialLocation: widget.auth.isAuthenticated ? '/' : '/login',
    refreshListenable: widget.auth,
    redirect: (context, state) {
      final login = state.matchedLocation == '/login';
      if (!widget.auth.isAuthenticated && !login) return '/login';
      if (widget.auth.isAuthenticated && login) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => LoginScreen(auth: widget.auth),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(auth: widget.auth, child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                SearchScreen(api: api, favorites: widget.favorites),
          ),
          GoRoute(
            path: '/favorites',
            builder: (_, _) =>
                FavoritesScreen(api: api, favorites: widget.favorites),
          ),
          GoRoute(
            path: '/users/:login',
            builder: (_, state) => ProfileScreen(
              login: state.pathParameters['login']!,
              api: api,
              favorites: widget.favorites,
            ),
          ),
        ],
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'GitHub Explorer',
    routerConfig: router,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6c63ff)),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xfff7f7fb),
    ),
  );
}
