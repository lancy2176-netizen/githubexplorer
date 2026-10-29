# GitHub Explorer

A Flutter app for discovering GitHub users, viewing profiles, and keeping a local favorites list.

## Features

- Search GitHub users through the public GitHub REST API after a 400 ms debounce.
- Load results 20 at a time and request subsequent pages with **Load more**.
- Open profiles with account details, repository and follower counts, and a native share action.
- Save and remove favorites in SQLite. Favorite records remain available offline.
- Responsive search and favorites views: cards form a grid on wide screens; profiles use a two pane layout on larger screens.
- GoRouter routes for login, search, favorites, and `/users/:login` deep links. Unauthenticated deep links return to login and resume through the router after signing in.
- Mock sign-in with an eight hour JWT-shaped token in platform secure storage. Empty credentials are rejected and expiry clears the session and returns to login.
- Loading, empty, retryable error, rate limit, and offline-friendly favorite states.

## Sign in

This assignment uses a mock identity provider; enter any non-empty username and password. It does not create a GitHub account or grant GitHub OAuth access. The local mock token is attached as a Bearer credential to API requests; because GitHub cannot validate a mock credential, a 401 response is retried without it so public profile and search requests continue to work. Authenticated calls to a real protected service would require replacing the mock identity provider with one that issues credentials accepted by that service.

## Run

Requires Flutter with Dart SDK `^3.13.3`.

```sh
flutter pub get
flutter run
```

Internet access is needed for live GitHub search and profile refreshes. Favorites are stored on device and can be browsed without a connection. The app makes unauthenticated public GitHub API calls as a fallback and therefore remains subject to GitHub's anonymous rate limit.

## Checks

```sh
flutter analyze
flutter test
```

The tests cover GitHub search query/pagination parameters, response mapping, and rate limit error conversion.

## Structure

The app currently keeps the assignment's compact domain, data, and presentation layers in `lib/main.dart`: `GitHubUser` is the domain model; `GitHubApi`, `AuthRepository`, and `FavoritesRepository` provide API, session, and persistence responsibilities; screens and routing form the presentation layer. SQLite uses a `favorites` table and secure storage keeps the mock token and expiry separate from the database.
# githubexplorer
