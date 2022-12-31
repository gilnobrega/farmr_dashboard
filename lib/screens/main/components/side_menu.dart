import 'package:farmr_dashboard/screens/dashboard/components/sponsor.dart';
import 'package:farmr_dashboard/screens/main/components/side_menu_list_tile.dart';
import 'package:farmr_client/config.dart';
import 'package:flutter/material.dart';

import 'package:farmr_dashboard/constants.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SideMenu extends StatefulWidget {
  const SideMenu(
      {Key? key,
      required this.harvesterPages,
      required this.updateFunction,
      required this.harvesterID,
      required this.logo})
      : super(key: key);

  final List<HarvesterPage> harvesterPages;
  final VoidCallback updateFunction; //function that refreshes page
  final String harvesterID;
  final Widget logo;

  @override
  SideMenuState createState() => SideMenuState();
}

class SideMenuState extends State<SideMenu> {
  String? currentHarvesterID;
  List<Widget> drawers = [];
  int currentRefresh = 0;
  bool addVisible = false;

  String filter = "";

  @override
  void initState() {
    super.initState();
  }

  loadDrawers([bool forceRefresh = false]) {
    if (currentHarvesterID == null ||
        currentHarvesterID != widget.harvesterID ||
        forceRefresh) {
      List<Widget> tempDrawers = [];

      var harvesterPages = widget.harvesterPages;

      if (filter != "")
        harvesterPages = harvesterPages
            .where((element) =>
                element.title.toLowerCase().startsWith(filter.toLowerCase()) ||
                element.blockchain
                    .toLowerCase()
                    .startsWith(filter.toLowerCase()))
            .toList();

      for (HarvesterPage page in harvesterPages) {
        //icon name varies with client type
        var iconName = (page.title == "Farm")
            ? "barn"
            : (page.type == ClientType.Farmer)
                ? "tractor"
                : (page.type == ClientType.Harvester)
                    ? "sprout"
                    : "alpha-${(page.type.toString().split('.')[1] as String).characters.first}-circle";

        tempDrawers.add(DrawerListTile(
            showBlockchainHeader: widget.harvesterPages
                        .where(
                            (element) => element.blockchain == page.blockchain)
                        .length ==
                    1 ||
                page.title == "Farm",
            updateFunction: widget.updateFunction,
            key: Key(page.id.toString() + page.title),
            //different icon for main farm tile
            iconName: iconName,
            page: page,
            selected: page.id == widget.harvesterID));
      }

      //updates menu (slide in/fade out effect)
      if (drawers.length != tempDrawers.length) {
        setState(() {
          currentRefresh++;
        });
      }

      setState(() {
        drawers = tempDrawers;
        currentHarvesterID = widget.harvesterID;
      });
    }
  }

  ClipRect transitionBuilder(Widget child, Animation<double> animation) {
    final inAnimation =
        Tween<Offset>(begin: Offset(-1.0, 0.0), end: Offset(0.0, 0.0))
            .animate(animation);
    final outAnimation = Tween<double>(begin: 1, end: 0).animate(animation);

    if (child.key == ValueKey("Drawer" + currentRefresh.toString())) {
      return ClipRect(
        child: SlideTransition(
          position: inAnimation,
          child: child,
        ),
      );
    } else {
      return ClipRect(
        child: FadeTransition(
          opacity: outAnimation,
          child: child,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    loadDrawers();

    var searchWidget = Padding(
        padding: EdgeInsets.symmetric(
            vertical: defaultPadding / 2, horizontal: defaultPadding),
        child: TextField(
          cursorColor: Theme.of(context).accentColor,
          onChanged: (newFilter) {
            filter = newFilter;
            loadDrawers(true);
          },
          decoration: InputDecoration(
              isDense: true,
              labelText: 'Search',
              focusedBorder: new UnderlineInputBorder(
                  borderSide: new BorderSide(
                      width: 1, color: Theme.of(context).accentColor)),
              enabledBorder: InputBorder.none,
              border: InputBorder.none,
              labelStyle: TextStyle(
                  color: Theme.of(context).textTheme.caption!.color,
                  fontWeight: FontWeight.w300),
              focusColor: Theme.of(context).accentColor,
              hoverColor: Theme.of(context).accentColor,
              fillColor: Theme.of(context).textTheme.caption?.color),
        ));

    //source https://medium.com/flutter-community/what-do-you-know-about-aniamtedswitcher-53cc3a4bebb8
    //animation which slides in and fades out
    return Drawer(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Expanded(
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                Container(
                    child: widget.logo,
                    padding: EdgeInsets.symmetric(
                        horizontal: defaultPadding / 2,
                        vertical: defaultPadding)),
                if (widget.harvesterPages.length > 3) searchWidget,

                AnimatedSwitcher(
                    duration: slowAnimationDuration,
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: transitionBuilder,
                    //child: SingleChildScrollView(
                    // it enables scrolling
                    child: (drawers.length == 0 ||
                            currentHarvesterID == "loggedOut" ||
                            currentHarvesterID == "noHarvesters")
                        ? Container()
                        : Column(
                            key: Key("Drawer" + currentRefresh.toString()),
                            children: drawers,
                          )),

                //),
              ]))),
          MenuFooter(),
        ]));
  }
}

class MenuFooter extends StatelessWidget {
  MenuFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //adsenseAdsView(), ENABLE ADS
            MenuFooterSponsor(
                imgUrl: "https://i.ibb.co/C1Pbyx3/advert.png",
                url: "mailto:contact@farmr.net",
                name: "YOU!"),
            SizedBox(height: defaultPadding * 2),
            Container(
                height: 1,
                color:
                    Theme.of(context).textTheme.caption?.color?.withAlpha(128)),
            SizedBox(height: defaultPadding),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              MenuFooterIcon(
                  message: "Visit project's GitHub page",
                  url: "https://github.com/joaquimguimaraes/chiabot",
                  iconName: "github"),
              MenuFooterIcon(
                  message: "Support this project",
                  url: "https://github.com/joaquimguimaraes/chiabot#donate",
                  iconName: "hand-heart"),
              MenuFooterIcon(
                  message: "Join our discord community",
                  url: "https://discord.gg/fghFbffYsC",
                  iconName: "discord")
            ]),
          ],
        ));
  }
}

class MenuFooterIcon extends StatelessWidget {
  MenuFooterIcon(
      {required this.url, required this.iconName, required this.message});
  final String iconName;
  final String url;
  final String message;

  void _launchURL() async =>
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';

  @override
  Widget build(BuildContext context) {
    return IconButton(
        tooltip: message,
        // Use the string name to access icons.
        icon: new Icon(
          MdiIcons.fromString(iconName),
          color: Theme.of(context).textTheme.caption?.color,
        ),
        onPressed: _launchURL);
  }
}
