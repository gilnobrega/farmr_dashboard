import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:farmr_dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  String currentThemeName = "farmr";
  String currentCurrency = "USD";

  static Map<String, SimpleTheme> availableThemes = {
    "farmr": SimpleTheme(
        backgroundColor: Color(0xFF1a1c30),
        canvasColor: Color(0xFF26263c),
        textColor: Color(0xFFFFFFFF),
        accentColor: Color(0xFFFFb335)),
    "farmr light": SimpleTheme(
        backgroundColor: Colors.grey[100]!,
        canvasColor: Colors.white,
        textColor: Color(0xFF000000),
        accentColor: Color(0xFFffa004)),
    "mint": SimpleTheme(
        backgroundColor: Color(0xFF1B2128),
        canvasColor: Color(0xFF273038),
        textColor: Color(0xFFFFFFFF),
        accentColor: Color(0xFF50cb7b)),
    "mint light": SimpleTheme(
        backgroundColor: Colors.grey[100]!,
        canvasColor: Colors.white,
        textColor: Color(0xFF000000),
        accentColor: Color(0xFF50cb7b)),
    "oceanic": SimpleTheme(
        backgroundColor: Color(0xFF002147),
        canvasColor: Color(0xFF023047),
        textColor: Color(0xFFFFFFFF),
        accentColor: Color(0xFF8ecae6)),
    "oceanic light": SimpleTheme(
        backgroundColor: Colors.grey[100]!,
        canvasColor: Colors.white,
        textColor: Color(0xFF000000),
        accentColor: Color(0xFF1E88E5)),
    "palenight": SimpleTheme(
        backgroundColor: Color(0xFF202331),
        canvasColor: Color(0xFF2b2a3e),
        textColor: Color(0xFFFFFFFF),
        accentColor: Color(0xFFC792EA)),
  };

  void setTheme(String newThemeName, BuildContext context) {
    currentThemeName = newThemeName;
    ThemeSwitcher.of(context)?.changeTheme(
        theme: selectTheme(
            context,
            availableThemes[currentThemeName] ??
                availableThemes.entries.first.value,
            currentThemeName.contains("light")));
    saveTheme();
  }

  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentThemeName =
        prefs.getString("theme") ?? availableThemes.entries.first.key;
  }

  Future<void> saveTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("theme", currentThemeName);
  }

  void setCurrency(String newCurrency) {
    currentCurrency = newCurrency;

    saveCurrency();
  }

  Future<String> loadCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentCurrency = prefs.getString("currency") ?? "USD";

    return currentCurrency;
  }

  Future<void> saveCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("currency", currentCurrency);
  }
}

class SimpleTheme {
  final Color backgroundColor, canvasColor, textColor, accentColor;

  SimpleTheme(
      {required this.backgroundColor,
      required this.canvasColor,
      required this.textColor,
      required this.accentColor});
}
