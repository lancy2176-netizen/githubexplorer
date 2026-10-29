import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:githubexplorer/data/github_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('search sends query and page and maps GitHub users', () async {
    late Uri requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response(jsonEncode({'items': [
        {'id': 7, 'login': 'octocat', 'avatar_url': 'https://example.com/avatar.png', 'html_url': 'https://github.com/octocat'},
      ]}), 200);
    });
    final users = await GitHubApi(client: client).search('octo cat', 2);
    expect(requested.queryParameters, {'q': 'octo cat', 'page': '2', 'per_page': '20'});
    expect(users.single.login, 'octocat');
    expect(users.single.url, 'https://github.com/octocat');
  });

  test('search reports GitHub rate limit errors', () async {
    final api = GitHubApi(client: MockClient((_) async => http.Response('{}', 403)));
    expect(() => api.search('flutter', 1), throwsA(isA<ApiException>()));
  });
}
