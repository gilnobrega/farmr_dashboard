import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:farmr_dashboard/controllers/login_controller.dart';
import 'package:farmr_dashboard/controllers/settings_controller.dart';
import 'package:farmr_dashboard/constants.dart';
import 'package:farmr_dashboard/responsive.dart';
import 'package:farmr_dashboard/screens/login/login.dart';
import 'package:flutter/material.dart';
import 'package:farmr_dashboard/controllers/menu_controller.dart';
import 'components/side_menu.dart';
import 'components/header.dart';

import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  MainScreen();

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  bool autoUpdate = true;
  bool legacyMode = false;
  String key = "";

  @override
  void initState() {
    context.read<LoginController>()
      ..addListener(() {
        setState(() {});
      });

    //loads theme from local settings
    context.read<SettingsController>().loadTheme().then((currency) {
      setState(() {});
    });

    //loads currency from local settings
    context.read<SettingsController>().loadCurrency().then((currency) {
      //initializes login and firebase api
      context.read<LoginController>().init(currency).then((value) {
        regularRefresh();
      });
    });

    super.initState();

    context.read<LoginController>().rotationController = AnimationController(
        value: 0,
        duration: Duration(seconds: 1),
        vsync: this,
        lowerBound: 0,
        upperBound: 1);
  }

  //Refreshes page every 10 minutes
  Future<void> regularRefresh() async {
    while (autoUpdate) {
      context.read<LoginController>().loadHarvesters(
          context.read<SettingsController>().currentCurrency,
          false,
          await context
              .read<LoginController>()
              .login
              ?.auth
              ?.currentUser
              ?.getIdToken(true));
      await Future<void>.delayed(Duration(minutes: 10));
    }
  }

  static String stringifyCookies(Map<String, String> cookies) =>
      cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  void logout() {
    setState(() {
      context.read<LoginController>().rotationController.repeat();

      //deletes token
      context.read<LoginController>().logout();
    });
  }

  void changeLegacyMode() {
    setState(() {
      legacyMode = !legacyMode;
    });
  }

  void toggleAutoUpdate() {
    setState(() {
      autoUpdate = !autoUpdate;
    });

    if (autoUpdate) regularRefresh();
  }

  @override
  Widget build(BuildContext context) {
    var logo = Image.asset(
      context.read<SettingsController>().currentThemeName.contains("light")
          ? "assets/images/farmr-logo-net-flat-light.png"
          : "assets/images/farmr-logo-net-flat.png",
      height: 36,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      fit: BoxFit.fitWidth,
    );

    key = "Harvester" +
        (context.read<LoginController>().currentHarvester?.id ?? '') +
        "$legacyMode ${context.read<LoginController>().loggedIn}";

    return ThemeSwitchingArea(child: Builder(builder: (context) {
      return Scaffold(
        key: context.read<MenuController>().scaffoldKey,
        drawer: SideMenu(
          logo: logo,
          updateFunction: () {
            context.read<LoginController>().loadHarvesters(
                context.read<SettingsController>().currentCurrency);
          },
          harvesterPages: context.read<LoginController>().harvesterPages,
          harvesterID:
              context.read<LoginController>().currentHarvester?.id ?? '',
        ),
        body: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // We want this side menu only for large screen
              if (Responsive.isDesktop(context))
                Expanded(
                  // default flex = 1
                  // and it takes 1/8 part of the screen
                  child: SideMenu(
                    logo: logo,
                    updateFunction: () {
                      context.read<LoginController>().loadHarvesters(
                          context.read<SettingsController>().currentCurrency);
                    },
                    harvesterPages:
                        context.read<LoginController>().harvesterPages,
                    harvesterID: (!context.read<LoginController>().loggedIn)
                        ? "loggedOut"
                        : (context.read<LoginController>().stats == null)
                            ? "noHarvesters"
                            : context
                                    .read<LoginController>()
                                    .currentHarvester
                                    ?.id ??
                                '',
                  ),
                ),
              Expanded(
                // It takes 7/8 part of the screen
                flex: 7,

                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Header(
                        harvesters: context.read<LoginController>().harvesters,
                        currentHarvester:
                            context.read<LoginController>().currentHarvester,
                        hasHarvesters:
                            context.read<LoginController>().currentHarvester !=
                                null,
                        logo: logo,
                        user: context.read<LoginController>().user ??
                            context.read<LoginController>().defaultUser,
                        rotationController:
                            context.read<LoginController>().rotationController,
                        updateFunction: () {
                          context.read<LoginController>().loadHarvesters(context
                              .read<SettingsController>()
                              .currentCurrency);
                        },
                        logoutFunction: logout,
                        legacyMode: legacyMode,
                        changeLegacyMode: changeLegacyMode,
                        toggleAutoUpdate: toggleAutoUpdate,
                        autoUpdate: autoUpdate,
                        loggedIn: context.read<LoginController>().loggedIn,
                      ),
                      Expanded(
                          child: AnimatedSizeWidget(
                        duration: slowAnimationDuration,
                        child: AnimatedSwitcher(
                            duration: slowAnimationDuration,
                            child: (!context.read<LoginController>().loggedIn &&
                                    context.read<LoginController>().loaded)
                                ? AnimatedOpacity(
                                    duration: slowAnimationDuration,
                                    opacity: (context
                                            .read<LoginController>()
                                            .rotationController
                                            .isAnimating)
                                        ? 0
                                        : 1,
                                    child: LoginPage())
                                : (context.read<LoginController>().stats ==
                                        null)
                                    ? Container()
                                    : (!legacyMode)
                                        ? SingleChildScrollView(
                                            key: Key(key),
                                            child: context
                                                .read<LoginController>()
                                                .dashboard)
                                        : SingleChildScrollView(
                                            key: Key(key),
                                            child: context
                                                .read<LoginController>()
                                                .legacyModeScreen)),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }));
  }
}

//Source
//https://gbaccetta.medium.com/flutter-animatedswitcher-with-animatedsize-using-bloc-architecture-3bba3097a72c
class AnimatedSizeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const AnimatedSizeWidget({
    Key? key,
    required this.child,
    required this.duration,
  }) : super(key: key);

  @override
  _AnimatedSizeWidgetState createState() => _AnimatedSizeWidgetState();
}

class _AnimatedSizeWidgetState extends State<AnimatedSizeWidget>
    with TickerProviderStateMixin {
  Widget build(BuildContext context) {
    return AnimatedSize(
      vsync: this,
      duration: widget.duration,
      child: widget.child,
      curve: Curves.easeInOut,
    );
  }
}
