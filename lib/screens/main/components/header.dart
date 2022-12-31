import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:farmr_dashboard/controllers/menu_controller.dart';
import 'package:farmr_dashboard/controllers/login_controller.dart';
import 'package:farmr_dashboard/responsive.dart';
import 'package:farmr_dashboard/screens/modals/add_device.dart';
import 'package:farmr_dashboard/screens/modals/header_button.dart';
import 'package:farmr_dashboard/screens/modals/settings.dart';
import 'package:farmr_dashboard/screens/overview/overview_screen.dart';
import 'package:farmr_dashboard/user.dart';
import 'package:farmr_client/harvester/harvester.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:provider/provider.dart';
import 'package:keybinder/keybinder.dart';
import 'package:expandable/expandable.dart';

import 'dart:math' as Math;

import '../../../constants.dart';

class Header extends StatefulWidget {
  const Header(
      {Key? key,
      required this.rotationController,
      required this.updateFunction,
      required this.user,
      required this.logoutFunction,
      required this.toggleAutoUpdate,
      required this.autoUpdate,
      required this.changeLegacyMode,
      required this.legacyMode,
      required this.loggedIn,
      required this.logo,
      required this.hasHarvesters,
      required this.currentHarvester,
      required this.harvesters})
      : super(key: key);

  final User user;
  final AnimationController rotationController;
  final VoidCallback updateFunction;
  final VoidCallback logoutFunction;
  final VoidCallback toggleAutoUpdate;
  final bool autoUpdate;
  final VoidCallback changeLegacyMode;
  final bool legacyMode;
  final bool loggedIn;
  final Widget logo;
  final bool hasHarvesters;
  final Harvester? currentHarvester;
  final Map<String, List<Harvester>> harvesters;

  HeaderState createState() => HeaderState();
}

class HeaderState extends State<Header> {
  late ExpandableController controller;
  void initState() {
    controller = ExpandableController(initialExpanded: false);
    controller
      ..addListener(() {
        setState(() {});
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(defaultPadding),
        child: ExpandablePanel(
          theme: ExpandableThemeData(
            animationDuration: animationDuration,
            useInkWell: false,
            hasIcon: false,
          ),
          collapsed: Container(),
          header: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  if (!Responsive.isDesktop(context))
                    IconButton(
                      icon: Icon(Icons.menu),
                      onPressed: context.read<MenuController>().controlMenu,
                    ),
                  //if (!Responsive.isMobile(context))

                  if (Responsive.isTablet(context)) widget.logo,
                  if (Responsive.isMobile(context))
                    Image.asset(
                      "assets/images/farmr-icon.png",
                      height: 36,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      fit: BoxFit.fitWidth,
                    ),
                  //height: 64,
                ],
              ),
              Flexible(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  //user ID / profile card
                  Flexible(
                      child: ProfileCard(
                    updateFunction: widget.updateFunction,
                    user: widget.user,
                    logoutFunction: widget.logoutFunction,
                    toggleAutoUpdate: widget.toggleAutoUpdate,
                    autoUpdate: widget.autoUpdate,
                    changeLegacyMode: widget.changeLegacyMode,
                    legacyMode: widget.legacyMode,
                    loggedIn: widget.loggedIn,
                  )),
                  if (widget.hasHarvesters)
                    //spacing between profile card and button
                    SizedBox(
                      width: defaultPadding,
                    ),
                  if (widget.hasHarvesters)
                    ModalButton(
                      modalWidth: 1000,
                      icon: Icons.settings,
                      child: Settings(
                        harvester: widget.currentHarvester!,
                        closeFunction: () {},
                        updateFunction: () {},
                      ),
                      windowTitle: "Settings",
                    ),
                  if (widget.loggedIn)
                    SizedBox(
                      width: defaultPadding,
                    ),
                  if (widget.loggedIn)
                    ModalButton(
                      blink: widget.loggedIn && !widget.hasHarvesters,
                      icon: Icons.add,
                      child: AddDevice(),
                      windowTitle: "Add new device",
                    ),
                  if (widget.loggedIn && !Responsive.isMobile(context))
                    SizedBox(
                      width: defaultPadding,
                    ),
                  if (widget.loggedIn && !Responsive.isMobile(context))
                    HeaderButton(
                        title: "Overview Bar",
                        icon: Icons.remove_red_eye,
                        onTapFunction: () {
                          controller.toggle();
                        },
                        color: (controller.expanded)
                            ? Theme.of(context).accentColor
                            : Theme.of(context).canvasColor),
                  SizedBox(
                    width: defaultPadding,
                  ),
                  //refresh / update button
                  RefreshButton(
                    updateFunction: widget.updateFunction,
                    rotationController: widget.rotationController,
                  )
                ],
              )),
            ],
          ),
          expanded: OverviewScreen(
            harvesters: widget.harvesters,
            harvesterID: widget.currentHarvester?.id,
            headFarmersStats: context.read<LoginController>().headFarmersStats,
          ),
          controller: controller,
        ));
  }
}

const elementSize = 128 / 4 + defaultPadding / 2;

class ProfileCard extends StatefulWidget {
  const ProfileCard(
      {Key? key,
      required this.user,
      required this.logoutFunction,
      required this.toggleAutoUpdate,
      required this.autoUpdate,
      required this.changeLegacyMode,
      required this.legacyMode,
      required this.updateFunction,
      required this.loggedIn})
      : super(key: key);

  final User user;
  final VoidCallback logoutFunction;
  final VoidCallback toggleAutoUpdate;
  final VoidCallback updateFunction;
  final bool autoUpdate;
  final VoidCallback changeLegacyMode;
  final bool legacyMode;
  final bool loggedIn;

  @override
  ProfileCardState createState() => ProfileCardState();
}

class ProfileCardState extends State<ProfileCard>
    with TickerProviderStateMixin {
  bool visible = false;

  late AnimationController controller;
  late Animation animation;

  GlobalKey globalKey = GlobalKey();

  double menuWidth = 0;
  double animatedBorderRadius = borderRadius;
  double animatedRotation = 0;

  @override
  void initState() {
    controller = AnimationController(duration: animationDuration, vsync: this);

    animation = Tween(begin: 0.0, end: 1.0).animate(controller)
      ..addListener(() {
        setState(() {
          animatedBorderRadius = (1 - animation.value) * borderRadius;
          animatedRotation = -Math.pi * animation.value;
        });
      });

    super.initState();
  }

  void toggleVisibility() {
    setState(() {
      //resizes menu width to match profile card's width
      menuWidth = globalKey.currentContext?.size?.width ?? 0;

      visible = !visible;

      if (visible)
        controller.forward();
      else
        controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    var profileWidget =
        ({required Widget menu, Key key = const Key("duplicate")}) {
      return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              IntrinsicHeight(
                  child: Row(
                      key: key,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    ClipRRect(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(animatedBorderRadius),
                            topLeft: Radius.circular(borderRadius)),
                        child: (widget.user.picture != "")
                            ? Image.network(
                                widget.user.picture,
                                scale: 4,
                                fit: BoxFit.fitWidth,
                                isAntiAlias: true,
                              )
                            : AspectRatio(
                                aspectRatio: 1,
                                child: Container(child: Icon(Icons.person)))),
                    if (!Responsive.isMobile(context))
                      Padding(
                        padding: const EdgeInsets.only(
                          left: defaultPadding / 2,
                          right: defaultPadding / 4,
                        ),
                        child: Center(
                            child: Text(
                          widget.user.username,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                        )),
                      ),
                    Material(
                        elevation: 0,
                        child: InkWell(
                            onTap: (widget.loggedIn) ? toggleVisibility : null,
                            child: Padding(
                                padding: const EdgeInsets.only(
                                    left: defaultPadding / 4,
                                    right: defaultPadding / 2,
                                    top: defaultPadding / 2,
                                    bottom: defaultPadding / 2),
                                child: Transform.rotate(
                                    angle: animatedRotation,
                                    child: Icon(Icons.arrow_drop_down,
                                        color: (widget.loggedIn)
                                            ? Theme.of(context)
                                                .textTheme
                                                .bodyText1!
                                                .color
                                            : Theme.of(context)
                                                .textTheme
                                                .caption!
                                                .color))))),
                  ])),
              menu,
            ],
          ),
        )
      ]);
    };

    var logoutButton = Material(
        child: InkWell(
            onTap: () {
              widget.logoutFunction();
              toggleVisibility();
            },
            child: Container(
                width: menuWidth,
                height: animation.value * elementSize,
                child: Padding(
                  padding: EdgeInsets.all(defaultPadding / 2),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Logout"),
                        if (!Responsive.isMobile(context))
                          Icon(Icons.logout,
                              size: (elementSize - defaultPadding) / 2)
                      ]),
                ))));

    var legacySwitch = Material(
        child: InkWell(
            onTap: widget.changeLegacyMode,
            child: Container(
                width: menuWidth,
                height: animation.value * elementSize,
                child: Padding(
                  padding: EdgeInsets.all(defaultPadding / 2),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Legacy",
                          style: (widget.legacyMode)
                              ? Theme.of(context).textTheme.bodyText1!.copyWith(
                                  fontSize: 14, fontWeight: FontWeight.normal)
                              : Theme.of(context).textTheme.caption!.copyWith(
                                  fontSize: 14, fontWeight: FontWeight.normal),
                        ),
                        if (!Responsive.isMobile(context))
                          FittedBox(
                              child: Switch(
                            activeColor: Theme.of(context).accentColor,
                            value: widget.legacyMode,
                            onChanged: (value) {
                              widget.changeLegacyMode();
                            },
                          ))
                      ]),
                ))));

    var autoUpdateSwitch = ThemeSwitcher(builder: (context) {
      return Material(
          child: InkWell(
              onTap: () {
                widget.toggleAutoUpdate();
              },
              child: Container(
                  width: menuWidth,
                  height: animation.value * elementSize,
                  child: Padding(
                    padding: EdgeInsets.all(defaultPadding / 2),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          RichText(
                              text: TextSpan(
                                  style: (widget.autoUpdate)
                                      ? Theme.of(context)
                                          .textTheme
                                          .bodyText1!
                                          .copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.normal)
                                      : Theme.of(context)
                                          .textTheme
                                          .caption!
                                          .copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.normal),
                                  text: "Auto",
                                  children: [
                                WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Icon(Icons.refresh,
                                        size:
                                            (elementSize - defaultPadding) / 2))
                              ])),
                          if (!Responsive.isMobile(context))
                            FittedBox(
                                child: Switch(
                              activeColor: Theme.of(context).accentColor,
                              value: widget.autoUpdate,
                              onChanged: (value) {
                                widget.toggleAutoUpdate();
                              },
                            ))
                        ]),
                  ))));
    });

    var menuWidget = IntrinsicHeight(
      child: IntrinsicWidth(
          child: profileWidget(
              menu: Column(
                  children: [autoUpdateSwitch, legacySwitch, logoutButton]))),
    );

    var clipContainer = (Widget widget) {
      return IntrinsicWidth(
          child: Material(
              borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
              elevation: (animation.value * 8),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
                child: widget,
              )));
    };

    return PortalEntry(
        visible: visible,
        portalAnchor: Alignment.topRight,
        childAnchor: Alignment.topRight,
        closeDuration: slowAnimationDuration,
        //childAnchor: Alignment.bottomCenter,
        portal: clipContainer(menuWidget),
        child: clipContainer(profileWidget(key: globalKey, menu: Container())));
  }
}

class RefreshButton extends StatefulWidget {
  const RefreshButton(
      {Key? key,
      required this.rotationController,
      required this.updateFunction})
      : super(key: key);

  final AnimationController rotationController;
  final VoidCallback updateFunction;

  @override
  _RefreshButtonState createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<RefreshButton> {
  late Animation<double> _animation;
  double rotationAngle = 0;

  @override
  void initState() {
    _animation = CurvedAnimation(
        parent: widget.rotationController, curve: Curves.easeInOut);

    /// A keybinding associated with the `R` and `F5` keys.
    //final keybinding = Keybinding.from({LogicalKeyboardKey.keyR});
    final keybinding2 = Keybinding.from({LogicalKeyboardKey.f5});

    /// Binds all three callbacks above to the `R` and `F5` keys.
    // Keybinder.bind(keybinding, widget.updateFunction);
    Keybinder.bind(keybinding2, widget.updateFunction);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(borderRadius)),
          onTap: widget.updateFunction,
          child: AnimatedBuilder(
              animation: widget.rotationController,
              builder: (_, child) {
                return Transform.rotate(
                    angle: 2 * Math.pi * _animation.value,
                    child: Container(
                        padding: EdgeInsets.all(defaultPadding * 0.5),
                        child: IntrinsicHeight(
                            child: AspectRatio(
                          aspectRatio: 1,
                          child: Icon(
                            Icons.refresh,
                            size: 24,
                            color: Theme.of(context).textTheme.bodyText1!.color,
                          ),
                        ))));
              }),
        ));
  }
}
