import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/favorites_repository.dart';
import '../providers/search_provider.dart';
import 'profile_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/user_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, required this.favorites});
  final FavoritesRepository favorites;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final controller = TextEditingController();
  String? selectedLogin;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final state = ref.watch(searchProvider);
      final wide = constraints.maxWidth >= 900;
      return Padding(
        padding: EdgeInsets.all(wide ? 28 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: .09),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'DEVELOPER DISCOVERY',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .9,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Find your people.',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.1),
            ),
            const SizedBox(height: 5),
            Text(
              'Explore developers and the work they share.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              onChanged: (value) =>
                  ref.read(searchProvider.notifier).queryChanged(value),
              decoration: InputDecoration(
                hintText: 'Search by username, name, or skill',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          ref.read(searchProvider.notifier).queryChanged('');
                        },
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: _content(state, wide)),
          ],
        ),
      );
    },
  );

  Widget _content(SearchState state, bool wide) {
    switch (state.phase) {
      case SearchPhase.idle:
        return const Center(
          child: EmptyState(
            icon: Icons.people_outline,
            title: 'Search GitHub users',
            subtitle: 'Start typing to discover developers around the world.',
          ),
        );
      case SearchPhase.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchPhase.empty:
        return const Center(
          child: EmptyState(
            icon: Icons.person_search,
            title: 'No users found',
            subtitle: 'Try another search term.',
          ),
        );
      case SearchPhase.error:
        return Center(
          child: EmptyState(
            icon: state.errorKind == SearchErrorKind.network
                ? Icons.wifi_off
                : Icons.cloud_off,
            title: state.errorKind == SearchErrorKind.rateLimit
                ? 'GitHub rate limit reached'
                : 'Could not load results',
            subtitle: state.error ?? 'Something went wrong.',
            action: FilledButton.tonal(
              onPressed: () => ref.read(searchProvider.notifier).retry(),
              child: const Text('Retry'),
            ),
          ),
        );
      case SearchPhase.success:
        return Column(
          children: [
            if (state.error != null)
              MaterialBanner(
                content: Text(state.error!),
                actions: [
                  TextButton(
                    onPressed: () =>
                        ref.read(searchProvider.notifier).loadMore(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Results for “${state.query}”',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${state.users.length} found',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: wide ? _masterDetail(state) : _phoneResults(state)),
            if (state.loadingMore) const LinearProgressIndicator(),
            if (state.hasMore && !wide)
              Padding(
                padding: const EdgeInsets.all(8),
                child: OutlinedButton(
                  onPressed: state.loadingMore
                      ? null
                      : () => ref.read(searchProvider.notifier).loadMore(),
                  child: const Text('Load more'),
                ),
              ),
          ],
        );
    }
  }

  Widget _phoneResults(SearchState state) => ListView.separated(
    itemCount: state.users.length,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (_, i) =>
        UserTile(user: state.users[i], favorites: widget.favorites),
  );

  Widget _masterDetail(SearchState state) {
    final selected = state.users.any((user) => user.login == selectedLogin)
        ? selectedLogin!
        : state.users.first.login;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 340,
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: state.users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => UserTile(
                    user: state.users[i],
                    favorites: widget.favorites,
                    selected: state.users[i].login == selected,
                    onTap: () =>
                        setState(() => selectedLogin = state.users[i].login),
                  ),
                ),
              ),
              if (state.hasMore)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: OutlinedButton(
                    onPressed: state.loadingMore
                        ? null
                        : () => ref.read(searchProvider.notifier).loadMore(),
                    child: const Text('Load more'),
                  ),
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 24),
        Expanded(
          child: ProfileScreen(
            key: ValueKey(selected),
            login: selected,
            api: ref.read(githubApiProvider),
            favorites: widget.favorites,
          ),
        ),
      ],
    );
  }
}
