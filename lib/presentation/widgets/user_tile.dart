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
    this.selected = false,
  });
  final GitHubUser user;
  final FavoritesRepository favorites;
  final VoidCallback? onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: favorites,
    builder: (context, _) => Card(
      color: selected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: .09)
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
        minLeadingWidth: 48,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onTap: onTap ?? () => context.go('/users/${user.login}'),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: ClipOval(
            child: Image.network(
              user.avatarUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.person_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        title: Text(
          user.login,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: user.name == null
            ? Text(
                '@${user.login}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : Text(
                user.name!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
        trailing: FutureBuilder<bool>(
          future: favorites.contains(user.login),
          builder: (context, snap) => IconButton.filledTonal(
            tooltip: snap.data == true ? 'Remove favorite' : 'Add favorite',
            onPressed: () => favorites.toggle(user),
            style: IconButton.styleFrom(
              foregroundColor: snap.data == true
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              backgroundColor: snap.data == true
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: .12)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            icon: Icon(
              snap.data == true
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
          ),
        ),
      ),
    ),
  );
}
