import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models.dart';

class LocalProfileStore {
  static const String _stateFileName = 'scrapchef_user_state.json';

  Future<File> _stateFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_stateFileName');
  }

  Future<Map<String, dynamic>> _readState() async {
    final file = await _stateFile();
    if (!await file.exists()) {
      return <String, dynamic>{'sessionEmail': null, 'savedRecipes': <String, dynamic>{}};
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        decoded.putIfAbsent('sessionEmail', () => null);
        decoded.putIfAbsent('savedRecipes', () => <String, dynamic>{});
        return decoded;
      }
    } catch (_) {
      // Fall through to a clean state.
    }

    return <String, dynamic>{'sessionEmail': null, 'savedRecipes': <String, dynamic>{}};
  }

  Future<void> _writeState(Map<String, dynamic> state) async {
    final file = await _stateFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(state));
  }

  Future<String?> loadSessionEmail() async {
    final state = await _readState();
    final email = state['sessionEmail'];
    return email is String && email.trim().isNotEmpty ? email.trim() : null;
  }

  Future<void> saveSessionEmail(String email) async {
    final state = await _readState();
    state['sessionEmail'] = email.trim();
    await _writeState(state);
  }

  Future<void> clearSession() async {
    final state = await _readState();
    state['sessionEmail'] = null;
    await _writeState(state);
  }

  Future<List<SavedRecipeRecord>> loadSavedRecipes(String email) async {
    final state = await _readState();
    final rawRecipes = state['savedRecipes'];
    if (rawRecipes is! Map) {
      return <SavedRecipeRecord>[];
    }

    final userRecipes = rawRecipes[email];
    if (userRecipes is! List) {
      return <SavedRecipeRecord>[];
    }

    return userRecipes
        .whereType<Map>()
        .map((entry) => SavedRecipeRecord.fromJson(Map<String, dynamic>.from(entry)))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> upsertRecipe(String email, SavedRecipeRecord record) async {
    final state = await _readState();
    final savedRecipes = state['savedRecipes'];
    final byUser = savedRecipes is Map ? Map<String, dynamic>.from(savedRecipes) : <String, dynamic>{};
    final userList = (byUser[email] is List ? List<dynamic>.from(byUser[email] as List) : <dynamic>[])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();

    final nextList = <Map<String, dynamic>>[];
    var replaced = false;
    for (final entry in userList) {
      if (entry['recipeId'] == record.recipeId) {
        nextList.add(record.toJson());
        replaced = true;
      } else {
        nextList.add(entry);
      }
    }
    if (!replaced) {
      nextList.add(record.toJson());
    }

    byUser[email] = nextList;
    state['savedRecipes'] = byUser;
    await _writeState(state);
  }

  Future<void> deleteRecipe(String email, String recipeId) async {
    final state = await _readState();
    final savedRecipes = state['savedRecipes'];
    final byUser = savedRecipes is Map ? Map<String, dynamic>.from(savedRecipes) : <String, dynamic>{};
    final userList = (byUser[email] is List ? List<dynamic>.from(byUser[email] as List) : <dynamic>[])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .where((entry) => entry['recipeId'] != recipeId)
        .toList();

    byUser[email] = userList;
    state['savedRecipes'] = byUser;
    await _writeState(state);
  }

  Future<void> updateRecipeNotes(String email, String recipeId, String notes) async {
    final state = await _readState();
    final savedRecipes = state['savedRecipes'];
    final byUser = savedRecipes is Map ? Map<String, dynamic>.from(savedRecipes) : <String, dynamic>{};
    final userList = (byUser[email] is List ? List<dynamic>.from(byUser[email] as List) : <dynamic>[])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();

    final nextList = <Map<String, dynamic>>[];
    for (final entry in userList) {
      if (entry['recipeId'] == recipeId) {
        nextList.add({...entry, 'userNotes': notes});
      } else {
        nextList.add(entry);
      }
    }

    byUser[email] = nextList;
    state['savedRecipes'] = byUser;
    await _writeState(state);
  }
}
