import 'package:farmr_dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ModalScreen extends StatefulWidget {
  ModalScreen(
      {required this.updateFunction,
      required this.windowTitle,
      required this.child,
      required this.heroTag,
      this.width = 500});

  final VoidCallback updateFunction; //refreshes list of devices
  final String windowTitle;
  final Widget child;
  final double width;
  final String heroTag;

  ModalScreenState createState() => ModalScreenState();
}

class ModalScreenState extends State<ModalScreen> {
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withAlpha(127),
            )),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
            child: Hero(
                tag: widget.heroTag,
                child: Material(
                    elevation: 8,
                    child: SingleChildScrollView(
                      child: Container(
                          width: widget.width,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              //Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                      child: Text(widget.windowTitle,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .caption)),
                                  IconButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(context);
                                      },
                                      icon: Icon(
                                        MdiIcons.close,
                                        color: Theme.of(context)
                                            .textTheme
                                            .caption
                                            ?.color,
                                      ))
                                ],
                              ),

                              Padding(
                                  padding: EdgeInsets.all(defaultPadding),
                                  child: widget.child),
                            ],
                          )),
                    ))),
          ),
        ),
      ],
    );
  }
}
