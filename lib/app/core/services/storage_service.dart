import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/reading_history_model.dart';
import '../constants/app_constants.dart';

class StorageService extends GetxService {
  late final SharedPreferences _prefs;
  late final Directory _annotationsDir;

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize annotations directory
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      _annotationsDir = Directory('${appDocs.path}/pdf_annotations');
      if (!await _annotationsDir.exists()) {
        await _annotationsDir.create(recursive: true);
      }
    } catch (_) {
      _annotationsDir = Directory.systemTemp;
    }

    return this;
  }

  // --- Theme Management ---
  ThemeMode getThemeMode() {
    final themeString = _prefs.getString(AppConstants.keyThemeMode);
    switch (themeString) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await _prefs.setString(AppConstants.keyThemeMode, value);
  }

  // --- Locale Management ---
  Locale getLocale() {
    final languageCode = _prefs.getString(AppConstants.keyLanguageCode);
    final countryCode = _prefs.getString(AppConstants.keyCountryCode);

    if (languageCode != null && countryCode != null) {
      return Locale(languageCode, countryCode);
    }
    return const Locale('bn', 'BD');
  }

  Future<void> saveLocale(Locale locale) async {
    await _prefs.setString(AppConstants.keyLanguageCode, locale.languageCode);
    if (locale.countryCode != null) {
      await _prefs.setString(AppConstants.keyCountryCode, locale.countryCode!);
    }
  }

  // --- Recent Files Management ---
  List<String> getRecentFiles() {
    return _prefs.getStringList(AppConstants.keyRecentFiles) ?? [];
  }

  Future<void> addRecentFile(String path) async {
    final list = getRecentFiles();
    list.remove(path);
    list.insert(0, path);
    if (list.length > 30) {
      list.removeRange(30, list.length);
    }
    await _prefs.setStringList(AppConstants.keyRecentFiles, list);
  }

  Future<void> saveRecentFile(dynamic model) async {
    if (model is String) {
      await addRecentFile(model);
    } else {
      try {
        final path = model.path as String?;
        if (path != null && path.isNotEmpty) {
          await addRecentFile(path);
        }
      } catch (_) {}
    }
  }

  // --- Reading History Management ---
  static const String _keyHistoryPrefix = 'pdf_history_';
  static const String _keyHistoryList = 'pdf_history_keys';

  Future<void> saveReadingPosition({
    required String path,
    required String title,
    required int page,
    required int totalPages,
  }) async {
    if (path.isEmpty) return;

    final history = PdfReadingHistoryModel(
      path: path,
      title: title,
      lastReadPage: page,
      totalPages: totalPages,
      lastReadTime: DateTime.now(),
    );

    final key = '$_keyHistoryPrefix${path.hashCode}';
    await _prefs.setString(key, history.toJson());

    // Update keys index
    final keys = _prefs.getStringList(_keyHistoryList) ?? [];
    keys.remove(key);
    keys.insert(0, key);
    if (keys.length > 50) {
      keys.removeRange(50, keys.length);
    }
    await _prefs.setStringList(_keyHistoryList, keys);

    // Also add to recents
    await addRecentFile(path);
  }

  PdfReadingHistoryModel? getReadingHistory(String path) {
    if (path.isEmpty) return null;
    final key = '$_keyHistoryPrefix${path.hashCode}';
    final jsonStr = _prefs.getString(key);
    if (jsonStr == null) return null;
    try {
      return PdfReadingHistoryModel.fromJson(jsonStr);
    } catch (_) {
      return null;
    }
  }

  List<PdfReadingHistoryModel> getAllReadingHistories() {
    final keys = _prefs.getStringList(_keyHistoryList) ?? [];
    final List<PdfReadingHistoryModel> histories = [];

    for (final key in keys) {
      final jsonStr = _prefs.getString(key);
      if (jsonStr != null) {
        try {
          histories.add(PdfReadingHistoryModel.fromJson(jsonStr));
        } catch (_) {}
      }
    }
    return histories;
  }


  // --- Bookmarked Files Index ---
  static const String _keyBookmarkedFiles = 'pdf_bookmarked_files';

  Set<String> getBookmarkedFiles() {
    final list = _prefs.getStringList(_keyBookmarkedFiles) ?? [];
    return list.toSet();
  }

  Future<void> toggleBookmarkedFile(String path) async {
    final list = _prefs.getStringList(_keyBookmarkedFiles) ?? [];
    if (list.contains(path)) {
      list.remove(path);
    } else {
      list.add(path);
    }
    await _prefs.setStringList(_keyBookmarkedFiles, list);
  }

  // --- Bookmarks Management ---
  static const String _keyBookmarkPrefix = 'pdf_bookmarks_';

  List<int> getDocumentBookmarks(String path) {
    if (path.isEmpty) return [];
    final key = '$_keyBookmarkPrefix${path.hashCode}';
    final strList = _prefs.getStringList(key) ?? [];
    return strList.map((s) => int.tryParse(s) ?? 0).where((p) => p > 0).toList()..sort();
  }

  Future<void> saveDocumentBookmarks(String path, List<int> pages) async {
    if (path.isEmpty) return;
    final key = '$_keyBookmarkPrefix${path.hashCode}';
    final strList = pages.map((p) => p.toString()).toList();
    await _prefs.setStringList(key, strList);
  }

  // --- Annotations / Highlights (XFDF) Management ---
  String _getAnnotationFilePath(String path) {
    return '${_annotationsDir.path}/annot_${path.hashCode}.xfdf';
  }

  Future<void> saveDocumentAnnotations(String path, List<int> xfdfBytes) async {
    if (path.isEmpty || xfdfBytes.isEmpty) return;
    try {
      final file = File(_getAnnotationFilePath(path));
      await file.writeAsBytes(xfdfBytes);
    } catch (e) {
      debugPrint('Error saving annotations: $e');
    }
  }

  Future<List<int>?> getDocumentAnnotations(String path) async {
    if (path.isEmpty) return null;
    try {
      final file = File(_getAnnotationFilePath(path));
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Error loading annotations: $e');
    }
    return null;
  }
}
