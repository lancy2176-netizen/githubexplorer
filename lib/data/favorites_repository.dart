import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../domain/models/github_user.dart';

class FavoritesRepository extends ChangeNotifier {
  Database? _db;
  Future<void> initialize() async {
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'github_explorer.db'),
      version: 1,
      onCreate: (db, version) => db.execute(
        'CREATE TABLE favorites (login TEXT PRIMARY KEY, data TEXT NOT NULL)',
      ),
    );
  }

  Future<List<GitHubUser>> all() async {
    final rows = await _db!.query('favorites', orderBy: 'login COLLATE NOCASE');
    return rows
        .map(
          (r) => GitHubUser.fromJson(
            jsonDecode(r['data']! as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<bool> contains(String login) async => (await _db!.query(
    'favorites',
    where: 'login = ?',
    whereArgs: [login],
  )).isNotEmpty;
  Future<void> toggle(GitHubUser user) async {
    if (await contains(user.login)) {
      await _db!.delete(
        'favorites',
        where: 'login = ?',
        whereArgs: [user.login],
      );
    } else {
      await _db!.insert('favorites', {
        'login': user.login,
        'data': jsonEncode(user.toMap()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    notifyListeners();
  }
}
