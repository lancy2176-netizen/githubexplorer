import 'package:flutter/material.dart';
import 'data/auth_repository.dart';
import 'data/favorites_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthRepository();
  await auth.restore();
  final favorites = FavoritesRepository();
  await favorites.initialize();
  runApp(GitHubExplorer(auth: auth, favorites: favorites));
}
