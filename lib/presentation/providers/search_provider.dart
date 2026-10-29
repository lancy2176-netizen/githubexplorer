import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/github_api.dart';
import '../../domain/models/github_user.dart';

final githubApiProvider = Provider<GitHubApi>((ref) => GitHubApi());
final searchProvider = NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

enum SearchPhase { idle, loading, success, empty, error }
enum SearchErrorKind { network, rateLimit, api }

class SearchState {
  const SearchState({this.phase = SearchPhase.idle, this.query = '', this.users = const [],
    this.page = 1, this.hasMore = false, this.loadingMore = false, this.error, this.errorKind});

  final SearchPhase phase;
  final String query;
  final List<GitHubUser> users;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final String? error;
  final SearchErrorKind? errorKind;
}

class SearchNotifier extends Notifier<SearchState> {
  Timer? _debounce;
  int _generation = 0;
  GitHubApi get _api => ref.read(githubApiProvider);

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchState();
  }

  void queryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    _generation++;
    state = SearchState(query: query);
    if (query.isEmpty) return;
    final generation = _generation;
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(generation: generation));
  }

  Future<void> retry() async {
    if (state.query.isEmpty) return;
    _debounce?.cancel();
    _generation++;
    await _load(generation: _generation);
  }

  Future<void> loadMore() async {
    if (state.phase != SearchPhase.success || !state.hasMore || state.loadingMore) return;
    final generation = _generation;
    final requestedPage = state.page + 1;
    state = SearchState(phase: SearchPhase.success, query: state.query, users: state.users,
      page: state.page, hasMore: state.hasMore, loadingMore: true);
    try {
      final next = await _api.search(state.query, requestedPage);
      if (generation != _generation) return;
      state = SearchState(phase: SearchPhase.success, query: state.query,
        users: [...state.users, ...next], page: requestedPage, hasMore: next.length == 20);
    } catch (error) {
      if (generation != _generation) return;
      state = SearchState(phase: SearchPhase.success, query: state.query, users: state.users,
        page: state.page, hasMore: state.hasMore, error: _message(error), errorKind: _kind(error));
    }
  }

  Future<void> _load({required int generation}) async {
    final query = state.query;
    if (query.isEmpty) return;
    state = SearchState(phase: SearchPhase.loading, query: query);
    try {
      final users = await _api.search(query, 1);
      if (generation != _generation) return;
      state = SearchState(phase: users.isEmpty ? SearchPhase.empty : SearchPhase.success,
        query: query, users: users, hasMore: users.length == 20);
    } catch (error) {
      if (generation != _generation) return;
      state = SearchState(phase: SearchPhase.error, query: query, error: _message(error), errorKind: _kind(error));
    }
  }

  SearchErrorKind _kind(Object error) => error is SocketException
      ? SearchErrorKind.network
      : error is ApiException && error.statusCode == 403
          ? SearchErrorKind.rateLimit
          : SearchErrorKind.api;

  String _message(Object error) => error is SocketException
      ? 'No internet connection. Check your connection and retry.'
      : error.toString();
}
