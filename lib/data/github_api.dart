import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/models/github_user.dart';

class GitHubApi {
  GitHubApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String? token;

  Future<dynamic> _get(String path) async {
    final uri = Uri.https('api.github.com', path);
    var response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    // GitHub cannot validate this assignment's mock JWT; retry publicly if rejected.
    if (response.statusCode == 401 && token != null) {
      response = await _client.get(
        uri,
        headers: {'Accept': 'application/vnd.github+json'},
      );
    }
    if (response.statusCode == 401) {
      throw const ApiException(
        'Session expired. Please sign in again.',
        unauthorized: true,
      );
    }
    if (response.statusCode == 403) {
      throw const ApiException('GitHub rate limit reached. Try again later.', statusCode: 403);
    }
    if (response.statusCode == 404) {
      throw const ApiException('GitHub user not found.', statusCode: 404);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('GitHub is unavailable. Please try again.', statusCode: response.statusCode);
    }
    return jsonDecode(response.body);
  }

  Future<List<GitHubUser>> search(String query, int page) async {
    final uri = Uri.https('api.github.com', '/search/users', {
      'q': query,
      'page': '$page',
      'per_page': '20',
    });
    var response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/vnd.github+json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 401 && token != null) {
      response = await _client.get(
        uri,
        headers: {'Accept': 'application/vnd.github+json'},
      );
    }
    if (response.statusCode == 401) {
      throw const ApiException(
        'Session expired. Please sign in again.',
        unauthorized: true,
      );
    }
    if (response.statusCode == 403) {
      throw const ApiException('GitHub rate limit reached. Try again later.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Could not search GitHub users.', statusCode: response.statusCode);
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    return (result['items'] as List<dynamic>)
        .map((e) => GitHubUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GitHubUser> profile(String username) async => GitHubUser.fromJson(
    await _get('/users/$username') as Map<String, dynamic>,
  );
}

class ApiException implements Exception {
  const ApiException(this.message, {this.unauthorized = false, this.statusCode});
  final String message;
  final bool unauthorized;
  final int? statusCode;
  @override
  String toString() => message;
}
