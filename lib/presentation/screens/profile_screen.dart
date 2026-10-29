import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/favorites_repository.dart';
import '../../data/github_api.dart';
import '../../domain/models/github_user.dart';
import '../widgets/empty_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.login,
    required this.api,
    required this.favorites,
  });
  final String login;
  final GitHubApi api;
  final FavoritesRepository favorites;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<GitHubUser> future = _loadProfile();

  Future<GitHubUser> _loadProfile() async {
    try {
      return await widget.api.profile(widget.login);
    } on Object {
      final saved = await widget.favorites.find(widget.login);
      if (saved != null) return saved;
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<GitHubUser>(
    future: future,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snap.hasError) {
        return Center(
          child: EmptyState(
            icon: Icons.cloud_off,
            title: 'Profile unavailable',
            subtitle: snap.error.toString(),
            action: FilledButton.tonal(
              onPressed: () => setState(() => future = _loadProfile()),
              child: const Text('Retry'),
            ),
          ),
        );
      }
      final u = snap.data!;
      return LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 700;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _identity(context, u)),
                          const SizedBox(width: 28),
                          Expanded(child: _details(context, u)),
                        ],
                      )
                    : Column(
                        children: [
                          _identity(context, u),
                          const SizedBox(height: 20),
                          _details(context, u),
                        ],
                      ),
              ),
            ),
          );
        },
      );
    },
  );
  Widget _identity(BuildContext context, GitHubUser u) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 132,
            height: 132,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: ClipOval(
                child: Image.network(
                  u.avatarUrl,
                  width: 124,
                  height: 124,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.person_rounded,
                    size: 54,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            u.name ?? u.login,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.5),
            textAlign: TextAlign.center,
          ),
          Container(
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '@${u.login}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (u.bio != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(u.bio!, textAlign: TextAlign.center),
            ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (u.isDetailed) ...[
                _stat('Followers', u.followers),
                _stat('Following', u.following),
                _stat('Repos', u.publicRepos),
              ] else
                Text(
                  'Saved offline',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              FutureBuilder<bool>(
                future: widget.favorites.contains(u.login),
                builder: (context, snap) => FilledButton.tonalIcon(
                  onPressed: () => widget.favorites.toggle(u),
                  icon: Icon(
                    snap.data == true ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: Text(snap.data == true ? 'Favorited' : 'Favorite'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    Share.share(u.url, subject: 'GitHub profile: ${u.login}'),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  Widget _details(BuildContext context, GitHubUser u) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_pin_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 9),
              Text(
                'About',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _info(Icons.business, u.company),
          _info(Icons.location_on, u.location),
          _info(Icons.link, u.blog),
          _info(Icons.person, u.name),
          const SizedBox(height: 10),
          SelectableText(
            u.url,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    ),
  );
  Widget _stat(String label, int value) => Column(
    children: [
      Text(
        '$value',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      Text(label),
    ],
  );
  Widget _info(IconData icon, String? text) => text == null || text.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Icon(icon, size: 19),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
            ],
          ),
        );
}
