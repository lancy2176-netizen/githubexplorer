import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:githubexplorer/data/favorites_repository.dart';
import 'package:githubexplorer/data/github_api.dart';
import 'package:githubexplorer/presentation/providers/search_provider.dart';
import 'package:githubexplorer/presentation/screens/search_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Widget appWithResponse(int code, String body) => ProviderScope(
  overrides: [
    githubApiProvider.overrideWithValue(
      GitHubApi(client: MockClient((_) async => http.Response(body, code))),
    ),
  ],
  child: MaterialApp(
    home: Scaffold(body: SearchScreen(favorites: FavoritesRepository())),
  ),
);

void main() {
  testWidgets('search screen shows loading then a retryable error', (
    tester,
  ) async {
    await tester.pumpWidget(appWithResponse(403, '{}'));
    await tester.enterText(find.byType(TextField), 'flutter');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 410));
    await tester.pumpAndSettle();
    expect(find.text('GitHub rate limit reached'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('search screen shows the empty-results state', (tester) async {
    await tester.pumpWidget(appWithResponse(200, '{"items":[]}'));
    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.pump(const Duration(milliseconds: 410));
    await tester.pumpAndSettle();
    expect(find.text('No users found'), findsOneWidget);
  });
}
