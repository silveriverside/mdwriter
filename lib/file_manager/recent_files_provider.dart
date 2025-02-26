import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RecentFilesProvider with ChangeNotifier {
  List<String> _recentFiles = [];

  List<String> get recentFiles => _recentFiles;

  RecentFilesProvider() {
    _loadRecentFiles();
  }

  Future<void> _loadRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final recentFilesJson = prefs.getStringList('recentFiles');
    if (recentFilesJson != null) {
      _recentFiles = recentFilesJson.map((e) => e).toList();
      notifyListeners();
    }
  }

  Future<void> addRecentFile(String filePath) async {
    if (_recentFiles.contains(filePath)) {
      return;
    }
    _recentFiles.insert(0, filePath);
    if (_recentFiles.length > 5) {
      _recentFiles.removeLast();
    }
    notifyListeners();
    await _saveRecentFiles();
  }

  Future<void> _saveRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recentFiles', _recentFiles);
  }
}