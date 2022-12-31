import 'package:farmr_dashboard/constants.dart';
import 'package:farmr_dashboard/controllers/menu_controller.dart';
import 'package:farmr_dashboard/controllers/indexes_controller.dart';
import 'package:farmr_dashboard/controllers/login_controller.dart';
import 'package:farmr_dashboard/controllers/settings_controller.dart';
import 'package:farmr_dashboard/screens/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:provider/provider.dart';

import 'package:provider/single_child_widget.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp();
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String? initThemeName;

  @override
  void initState() {
    SharedPreferences.getInstance().then((value) {
      SharedPreferences prefs = value;

      setState(() {
        try {
          initThemeName = prefs.getString("theme") ?? "farmr";
        } catch (error) {
          initThemeName = "farmr";
        }
      });
    });

    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    List<SingleChildWidget> providers = [
      ChangeNotifierProvider(
        create: (context) => MenuController(),
      ),
      ChangeNotifierProvider(
        create: (context) => IndexesController(),
      ),
      ChangeNotifierProvider(
        create: (context) => SettingsController(),
      ),
      ChangeNotifierProvider(
        create: (context) => LoginController(),
      ),
    ];

    return (initThemeName == null)
        ? MaterialApp()
        : MultiProvider(
            providers: providers,
            child: Portal(
              child: ThemeProvider(
                  initTheme: selectTheme(
                      context,
                      SettingsController.availableThemes[initThemeName] ??
                          SettingsController
                              .availableThemes.entries.first.value,
                      initThemeName?.contains("light") ?? false),
                  builder: (context, myTheme) {
                    return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      title: 'farmr',
                      theme: myTheme,
                      home: MainScreen(),
                    );
                  }),
            ),
          );
  }
}
