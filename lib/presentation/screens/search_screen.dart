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
            Text(
              'Find your next follow',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('Search millions of GitHub developers.'),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              onChanged: (value) =>
                  ref.read(searchProvider.notifier).queryChanged(value),
              decoration: InputDecoration(
                hintText: 'Search by username or name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          ref.read(searchProvider.notifier).queryChanged('');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
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
