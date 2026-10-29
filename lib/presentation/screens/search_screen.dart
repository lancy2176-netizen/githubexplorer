import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/favorites_repository.dart';
import '../../data/github_api.dart';
import '../../domain/models/github_user.dart';
import '../widgets/user_tile.dart';
import '../widgets/empty_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.api, required this.favorites});
  final GitHubApi api;
  final FavoritesRepository favorites;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  Timer? timer;
  List<GitHubUser> users = [];
  bool loading = false, more = false;
  int page = 1;
  String? error;
  String query = '';
  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  void changed(String value) {
    timer?.cancel();
    setState(() {
      query = value.trim();
      error = null;
      users = [];
      page = 1;
      more = false;
    });
    if (query.isEmpty) return;
    timer = Timer(const Duration(milliseconds: 400), () => search());
  }

  Future<void> search({bool next = false}) async {
    if (query.isEmpty || loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await widget.api.search(query, next ? page + 1 : 1);
      if (!mounted) return;
      setState(() {
        if (next) {
          users.addAll(result);
          page++;
        } else {
          users = result;
          page = 1;
        }
        more = result.length == 20;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
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
              onChanged: changed,
              decoration: InputDecoration(
                hintText: 'Search by username or name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          changed('');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(child: _body(wide)),
          ],
        ),
      );
    },
  );
  Widget _body(bool wide) {
    if (query.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.people_outline,
          title: 'Search GitHub users',
          subtitle: 'Start typing to discover developers around the world.',
        ),
      );
    }
    if (loading && users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && users.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.wifi_off,
          title: 'Could not load results',
          subtitle: error!,
          action: FilledButton.tonal(
            onPressed: search,
            child: const Text('Retry'),
          ),
        ),
      );
    }
    if (!loading && users.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.person_search,
          title: 'No users found',
          subtitle: 'Try another search term.',
        ),
      );
    }
    return Column(
      children: [
        if (error != null)
          MaterialBanner(
            content: Text(error!),
            actions: [
              TextButton(onPressed: search, child: const Text('Retry')),
            ],
          ),
        Expanded(
          child: wide
              ? GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    mainAxisExtent: 112,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: users.length,
                  itemBuilder: (_, i) =>
                      UserTile(user: users[i], favorites: widget.favorites),
                )
              : ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      UserTile(user: users[i], favorites: widget.favorites),
                ),
        ),
        if (loading) const LinearProgressIndicator(),
        if (more)
          Padding(
            padding: const EdgeInsets.all(8),
            child: OutlinedButton(
              onPressed: loading ? null : () => search(next: true),
              child: const Text('Load more'),
            ),
          ),
      ],
    );
  }
}
