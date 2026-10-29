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
      return LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return Padding(
            padding: EdgeInsets.all(wide ? 28 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR COLLECTION',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  letterSpacing: 1.3,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Favorite developers',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.7,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Saved profiles stay close, even when you’re offline.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            size: 17,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${users.length}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: users.isEmpty
                      ? Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: const EmptyState(
                                  icon: Icons.favorite_border_rounded,
                                  title: 'Your collection starts here',
                                  subtitle: 'Tap the heart on a developer profile and it will be saved here for later.',
                                ),
                              ),
                            ),
                          ),
                        )
                      : wide
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
