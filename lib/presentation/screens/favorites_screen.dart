import 'package:flutter/material.dart';

import '../../data/favorites_repository.dart';
import '../../data/github_api.dart';
import '../../domain/models/github_user.dart';
import '../widgets/user_tile.dart';
import '../widgets/empty_state.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.api,
    required this.favorites,
  });
  final GitHubApi api;
  final FavoritesRepository favorites;
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    widget.favorites.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.favorites.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<GitHubUser>>(
    future: widget.favorites.all(),
    builder: (context, snap) {
      if (!snap.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final users = snap.data!;
      if (users.isEmpty) {
        return const Center(
          child: EmptyState(
            icon: Icons.favorite_border,
            title: 'No favorites yet',
            subtitle: 'Save profiles to keep them available offline.',
          ),
        );
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your favorites',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: wide
                      ? GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 350,
                                mainAxisExtent: 112,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: users.length,
                          itemBuilder: (_, i) => UserTile(
                            user: users[i],
                            favorites: widget.favorites,
                          ),
                        )
                      : ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => UserTile(
                            user: users[i],
                            favorites: widget.favorites,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
