import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/favorites_repository.dart';
import '../../domain/models/github_user.dart';

class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.favorites,
    this.onTap,
  });
  final GitHubUser user;
  final FavoritesRepository favorites;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: favorites,
    builder: (context, _) => Card(
      child: ListTile(
        onTap: onTap ?? () => context.go('/users/${user.login}'),
        leading: CircleAvatar(
          backgroundImage: NetworkImage(user.avatarUrl),
          onBackgroundImageError: (_, _) {},
        ),
        title: Text(
          user.login,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: user.name == null ? null : Text(user.name!),
        trailing: FutureBuilder<bool>(
          future: favorites.contains(user.login),
          builder: (context, snap) => IconButton(
            tooltip: snap.data == true ? 'Remove favorite' : 'Add favorite',
            onPressed: () => favorites.toggle(user),
            icon: Icon(
              snap.data == true ? Icons.favorite : Icons.favorite_border,
              color: snap.data == true ? Colors.pink : null,
            ),
          ),
        ),
      ),
    ),
  );
}
