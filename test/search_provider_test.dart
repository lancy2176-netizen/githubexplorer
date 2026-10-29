import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:githubexplorer/data/github_api.dart';
import 'package:githubexplorer/presentation/providers/search_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('search transitions loading to success after 400 ms debounce', () async {
    final container = ProviderContainer(
      overrides: [
        githubApiProvider.overrideWithValue(
          GitHubApi(
            client: MockClient(
              (_) async => http.Response(
                jsonEncode({
                  'items': [
                    {
                      'login': 'octocat',
                      'avatar_url': '',
                      'html_url': 'https://github.com/octocat',
                    },
                  ],
                }),
                200,
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(searchProvider.notifier).queryChanged('octo');
    expect(container.read(searchProvider).phase, SearchPhase.loading);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    expect(container.read(searchProvider).phase, SearchPhase.success);
    expect(container.read(searchProvider).users.single.login, 'octocat');
  });

  test('search distinguishes empty results and rate limiting', () async {
    final empty = ProviderContainer(
      overrides: [
        githubApiProvider.overrideWithValue(
          GitHubApi(
            client: MockClient((_) async => http.Response('{"items":[]}', 200)),
          ),
        ),
      ],
    );
    addTearDown(empty.dispose);
    empty.read(searchProvider.notifier).queryChanged('nobody');
    await Future<void>.delayed(const Duration(milliseconds: 420));
    expect(empty.read(searchProvider).phase, SearchPhase.empty);

    final limited = ProviderContainer(
      overrides: [
        githubApiProvider.overrideWithValue(
          GitHubApi(client: MockClient((_) async => http.Response('{}', 403))),
        ),
      ],
    );
    addTearDown(limited.dispose);
    limited.read(searchProvider.notifier).queryChanged('flutter');
    await Future<void>.delayed(const Duration(milliseconds: 420));
    expect(limited.read(searchProvider).phase, SearchPhase.error);
    expect(limited.read(searchProvider).errorKind, SearchErrorKind.rateLimit);
  });
}
