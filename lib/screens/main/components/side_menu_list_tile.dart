import 'package:farmr_dashboard/constants.dart';
import 'package:farmr_dashboard/controllers/login_controller.dart';
import 'package:farmr_dashboard/responsive.dart';
import 'package:farmr_client/config.dart';
import 'package:farmr_client/stats.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class HarvesterPage {
  final String title;
  final VoidCallback press;
  final String status;
  final ClientType? type;
  final String id;
  final String blockchain;

  HarvesterPage(
      {required this.title,
      required this.press,
      required this.status,
      required this.type,
      required this.id,
      required this.blockchain});
}

class DrawerListTile extends StatefulWidget {
  const DrawerListTile({
    Key? key,
    // For selecting those three line once press "Command+D"
    required this.selected,
    required this.iconName,
    required this.updateFunction,
    required this.page,
    required this.showBlockchainHeader,
  }) : super(key: key);

  final String iconName;
  final HarvesterPage page;
  final bool selected;
  final VoidCallback updateFunction;
  final bool showBlockchainHeader;

  @override
  DrawerListTileState createState() => DrawerListTileState();
}

class DrawerListTileState extends State<DrawerListTile> {
  bool isHovered = false;

  int farmersCount = 0;
  int harvestersCount = 0;

  //unlinks id and listens for server response
  void removeDevice(bool button) async {
    http.post(
      Uri.parse(mainURL + "/login.php?action=unlink&id=" + widget.page.id),
      body: {
        'token': await context
            .read<LoginController>()
            .login
            ?.auth
            ?.currentUser
            ?.getIdToken(true),
      },
    ).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Oh no! Something went wrong."),
      ));
    }).then((value) {
      print(value.body);
      if (value.body.trim().contains("success")) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Removed ${widget.page.title} with success"),
        ));

        if (button) widget.updateFunction();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to remove ${widget.page.title}"),
        ));
        if (!button) widget.updateFunction();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showBlockchainHeader) {
      farmersCount = context
              .read<LoginController>()
              .harvesters[widget.page.blockchain]
              ?.where((h) => h.type == ClientType.Farmer)
              .toList()
              .length ??
          0;

      harvestersCount = context
              .read<LoginController>()
              .harvesters[widget.page.blockchain]
              ?.where((h) => h.type == ClientType.Harvester)
              .toList()
              .length ??
          0;
    }

    var blockchainHeader = (widget.showBlockchainHeader)
        ? Container(
            padding: EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                    text: TextSpan(
                        text: widget.page.blockchain.toUpperCase(),
                        style: Theme.of(context).textTheme.caption,
                        children: [
                      TextSpan(
                          text: ((harvestersCount + farmersCount) > 1)
                              ? " - $farmersCount farmer${(farmersCount != 1) ? "s" : ""}, $harvestersCount harvester${(harvestersCount != 1) ? "s" : ""}"
                              : "",
                          style: Theme.of(context).textTheme.caption?.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .caption
                                  ?.color
                                  ?.withAlpha(64)))
                    ])),
                Container(
                    color: Theme.of(context).textTheme.caption!.color,
                    height: 1,
                    width: double.infinity)
              ],
            ))
        : Container();

    bool warning = !(widget.page.title == "Farm" ||
        Stats.normalStatus.contains(widget.page.status));
    Color? selectedColor = (warning)
        ? Colors.red
        : (widget.selected)
            ? Theme.of(context).textTheme.bodyText1!.color
            : Theme.of(context).textTheme.caption!.color;

    return MouseRegion(
        onEnter: (event) {
          setState(() {
            isHovered = true;
          });
        },
        onExit: (event) {
          setState(() {
            isHovered = false;
          });
        },
        child: Dismissible(
            //it is only dismissible
            direction: (widget.page.title != "Farm" &&
                    widget.page.title != "Add device" &&
                    Responsive.isMobile(context))
                ? DismissDirection.endToStart
                : DismissDirection.none,
            key: Key(widget.page.id + widget.page.title),
            background: Container(
                padding: EdgeInsets.all(defaultPadding),
                color: Colors.red,
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Icon(
                    MdiIcons.fromString("close"),
                    size: 16,
                  )
                ])),
            onDismissed: (direction) {
              removeDevice(false);
            },
            child: Material(
                color: Theme.of(context).canvasColor,
                child: Container(
                    margin: EdgeInsets.only(
                        top:
                            (widget.showBlockchainHeader) ? defaultPadding : 0),
                    child: Column(children: [
                      if ((widget.showBlockchainHeader)) blockchainHeader,
                      ListTile(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: defaultPadding),
                        onTap: () {
                          widget.page.press();
                          //only closes drawer if it is in tablet/mobile mode
                          if (!Responsive.isDesktop(context) &&
                              widget.page.title != "Add device")
                            Navigator.pop(context);
                        },
                        horizontalTitleGap: 0.0,
                        leading: Icon(
                          MdiIcons.fromString(widget.iconName),
                          color: selectedColor,
                          size: 16,
                        ),
                        title: Text(
                          widget.page.title +
                              ((warning)
                                  ? "\nStatus: ${widget.page.status}"
                                  : ''),
                          overflow: TextOverflow.clip,
                          maxLines: (!warning) ? 1 : null,
                          style: TextStyle(color: selectedColor),
                        ),
                        trailing: AnimatedSwitcher(
                          duration: animationDuration,
                          child: (isHovered &&
                                  widget.page.title != "Farm" &&
                                  widget.page.title != "Add device")
                              ? Tooltip(
                                  waitDuration: slowAnimationDuration,
                                  //showDuration: Duration(seconds: 2),
                                  message: "Remove ${widget.page.title}",
                                  child: IconButton(
                                      iconSize: 16,
                                      onPressed: () {
                                        removeDevice(true);
                                      },
                                      icon: Icon(
                                        MdiIcons.fromString("close"),
                                        size: 16,
                                        color: selectedColor,
                                      )))
                              : Container(width: 16, height: 16),
                        ),
                      ),
                    ])))));
  }
}
