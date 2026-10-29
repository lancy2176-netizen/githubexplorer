# GitHub Explorer

A responsive Flutter app for searching GitHub users, viewing account profiles, and saving favorites for offline browsing.

## Features

- GitHub REST API search with a 400 ms debounce, 20 results per page, load-more pagination, and distinct loading, empty, network, API, and rate-limit states.
- Profile details from `GET /users/{username}` with native share-sheet support.
- Mock login with JWT-shaped credentials saved by `flutter_secure_storage`, Bearer headers, an eight-hour expiry, and automatic return to login when the session expires.
- SQLite favorites available without a network connection.
- GoRouter navigation and authentication redirects, including resuming a protected deep link after login.
- Custom profile URI: `githubexplorer://user/{username}` (for example, `githubexplorer://user/octocat`).
- Responsive list/grid screens and a two-column profile layout on wider screens.
- Light and dark themes follow the device setting; an offline banner appears when connectivity is lost.
- Montserrat typography, a violet accent palette, and shared rounded surfaces keep the interface consistent across screens.

## Architecture and state management

The project separates responsibilities into `lib/data`, `lib/domain`, and `lib/presentation`. The search flow uses Riverpod `Notifier` state so query debounce, page loading, and idle/loading/success/empty/error transitions are kept outside the widget. Auth and SQLite persistence are repository classes; GoRouter owns navigation and redirects. The GitHub client is injected through a Riverpod provider, making repository and state tests deterministic.

## Authentication and API assumptions

This assignment uses a mock identity provider: any non-empty username and password sign in. It does not create a GitHub account and the JWT-shaped value is not GitHub OAuth. The mock Bearer token is attached to GitHub requests; if GitHub rejects it, the public API call is retried without that mock credential. Real authenticated GitHub access requires a GitHub OAuth/PAT flow; never commit a personal token. GitHub's anonymous API rate limit applies.

## Persistence and offline behavior

Favorites are stored as JSON profile snapshots in a local SQLite table, allowing the favorites page to render without API access. Profile views fall back to a saved snapshot when refresh fails; snapshots from search may contain only basic account details. Search requires internet access. Saved user avatars are remote image URLs and may not display offline.

## Deep links

Android and iOS register the `githubexplorer` custom URL scheme. The router maps `githubexplorer://user/octocat` to `/users/octocat`. If the app is signed out, the requested destination is preserved through login.

## Run and verify

Requires Flutter with Dart SDK `^3.13.3`.

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

The GitHub API tests cover query and pagination parameters, response mapping, and rate-limit errors. Riverpod tests cover debounced loading, success, empty, and rate-limit transitions; widget tests cover loading, retryable error, and empty states. GitHub Actions runs analysis and tests on pushes and pull requests.

## Native integration and limitations

The native integration is profile sharing through the platform share sheet (`share_plus`). Connectivity status is provided by `connectivity_plus`; connectivity signals can vary by platform and do not guarantee that a remote service is reachable. Mock authentication is intentionally local and is not a production security boundary.
