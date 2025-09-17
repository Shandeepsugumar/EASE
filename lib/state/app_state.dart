import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _loadInitialState();
  }

  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.light;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  Locale? get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  Future<void> _loadInitialState() async {
    // Load persisted theme
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? themePref = prefs.getString('theme_mode');
    if (themePref == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themePref == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }

    // Attach listener to user language preference
    final User? user = FirebaseAuth.instance.currentUser;
    _userSub?.cancel();
    if (user != null) {
      _userSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        final data = snapshot.data();
        if (data != null && data['language'] is String) {
          setLocaleByName(data['language'] as String, persist: false);
        }
      });
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'theme_mode', mode == ThemeMode.dark ? 'dark' : mode == ThemeMode.system ? 'system' : 'light');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  void setLocale(Locale locale, {bool persist = true}) {
    _locale = locale;
    notifyListeners();
  }

  // Map human-readable names to locales used in the app
  void setLocaleByName(String name, {bool persist = true}) {
    switch (name) {
      case 'Tamil':
        setLocale(const Locale('ta', 'IN'), persist: persist);
        break;
      case 'Hindi':
        setLocale(const Locale('hi', 'IN'), persist: persist);
        break;
      case 'English':
      default:
        setLocale(const Locale('en', 'US'), persist: persist);
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}

