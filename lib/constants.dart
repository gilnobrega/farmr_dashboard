import 'package:farmr_dashboard/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const String mainURL = "https://dev.farmr.net";
const debug = false;

const bgColor = Color(0xFF1B2128);

const accentColor = Color(0xFFFFb335);

const primaryTextColor = Color(0xFFFFFFFF);
const secondaryTextColor = Color.fromARGB(255, 200, 200, 200);

const defaultPadding = 16.0;

const animationDuration = Duration(milliseconds: 150);
const slowAnimationDuration = Duration(milliseconds: 400);

const double borderRadius = 10;

ThemeData selectTheme(
    BuildContext context, SimpleTheme simpleTheme, bool light) {
  return (light ? ThemeData.light() : ThemeData.dark()).copyWith(
      scaffoldBackgroundColor: simpleTheme.backgroundColor,
      accentColor: simpleTheme.accentColor,
      focusColor: simpleTheme.accentColor,
      cursorColor: simpleTheme.accentColor,
      hintColor: simpleTheme.textColor,
      textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
          .apply(
              bodyColor: simpleTheme.textColor,
              displayColor: simpleTheme.textColor.withAlpha(127)),
      canvasColor: simpleTheme.canvasColor
      //canvasColor: Colors.black12,
      );
}
