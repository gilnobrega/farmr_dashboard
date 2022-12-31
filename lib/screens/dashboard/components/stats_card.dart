import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:farmr_dashboard/models/stat.dart' as stat;
import 'package:farmr_dashboard/models/stat.dart';
import 'package:farmr_dashboard/screens/overview/overview_list.dart';
import 'package:flutter/material.dart';
import 'package:farmr_dashboard/responsive.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:universal_html/html.dart' as html;
import 'package:farmr_client/stats.dart';

import '../../../constants.dart';

class StatsCard extends StatefulWidget {
  final stat.StatInfo statInfo;
  final bool editable;
  final VoidCallback removeFunction;
  const StatsCard(
      {Key? key,
      required this.statInfo,
      required this.editable,
      required this.removeFunction})
      : super(key: key);

  @override
  _StatsCardState createState() => _StatsCardState();
}

//defines the status light on the corner
enum StatsCardStatus { None, Good, Meh, Bad }

class _StatsCardState extends State<StatsCard>
    with AfterLayoutMixin<StatsCard> {
  bool _hovered = false;
  final userAgent = html.window.navigator.userAgent;
  bool visible = true;
  int statusLightTimeout = 5;

  bool disposed = false;

  late bool isStatusCard;

  @override
  void initState() {
    isStatusCard = widget.statInfo.title == "Status";
    // TODO: implement initState
    super.initState();
  }

  void afterFirstLayout(BuildContext context) {
    //fades out status light after 5 seconds
    //except if stats card is status
    if (!isStatusCard) dismissLightAfterTimeout();
  }

  void dismissLightAfterTimeout() {
    Future.delayed(Duration(seconds: statusLightTimeout)).then((value) {
      if (!disposed)
        setState(() {
          visible = false;
        });
    });
  }

  //cancels future after widget is disposed
  void dispose() {
    disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var titleWidget = Text(
      widget.statInfo.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: Theme.of(context).textTheme.headline1!.color),
    );

    var dataSubString = (int.tryParse(widget.statInfo.data) == null &&
            double.tryParse(widget.statInfo.data) != null &&
            widget.statInfo.data.length > 4 &&
            !_hovered &&
            !widget.editable)
        ? double.parse(
                double.parse(widget.statInfo.data).toStringAsPrecision(4))
            .toString()
        : widget.statInfo.data;

    var dataStyle = TextStyle(
        fontSize: 30.0,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyText1!.color);
    var dataWidget = new TextSpan(
        text: dataSubString +
            (isStatusCard && Stats.normalStatus.contains(widget.statInfo.data)
                ? " "
                : ""),
        style: dataStyle);

    var descriptionStyle = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w100,
        color: Theme.of(context).textTheme.caption!.color);

    var descriptionWidget =
        TextSpan(text: widget.statInfo.description, style: descriptionStyle);

    var autoSizeWidget = AutoSizeText.rich(
      TextSpan(
          style: TextStyle(color: secondaryTextColor),
          children: <TextSpan>[
            dataWidget,
            new TextSpan(text: widget.statInfo.type),
            descriptionWidget
          ]),
      //maxLines: (_hovered || Responsive.isMobile(context)) ? 2 : 1,
      minFontSize: 1,
      stepGranularity: 0.5,
      maxLines:
          (isStatusCard && Stats.normalStatus.contains(widget.statInfo.data))
              ? 1
              : null,
      overflow: TextOverflow.fade,
    );

    var cardWidget = (!isStatusCard)
        ? SingleChildScrollView(child: autoSizeWidget)
        : autoSizeWidget;

    var progressBar = ((widget.statInfo.steps?.length ?? 0) > 0)
        ? ProgressLine(
            steps: widget.statInfo.steps ?? [],
          )
        : Container();

    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      child: Material(
          color: Theme.of(context).canvasColor,
          //borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          child: InkWell(
              onTap: (widget.editable) ? () {} : null,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  GestureDetector(
                      onTap: () {
                        setState(() {
                          _hovered = true;
                          if (!isStatusCard) visible = true;
                        });

                        if (!isStatusCard) dismissLightAfterTimeout();
                      },
                      child: MouseRegion(
                          onEnter: (value) {
                            setState(() {
                              _hovered = true;
                              if (!isStatusCard) visible = true;
                            });
                          },
                          onExit: (value) {
                            setState(() {
                              _hovered = false;
                            });

                            if (!isStatusCard) dismissLightAfterTimeout();
                          },
                          child: AnimatedOpacity(
                              opacity: (_hovered)
                                  ? 1.0
                                  : (!widget.editable)
                                      ? 1.0
                                      : 0.5,
                              duration: animationDuration,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                        child: Container(
                                      padding: EdgeInsets.all(defaultPadding),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          titleWidget,
                                          Container(height: defaultPadding / 2),
                                          Expanded(child: cardWidget)
                                        ],
                                      ),
                                    )),
                                    progressBar
                                  ])))),
                  if (widget.statInfo.status != StatsCardStatus.None)
                    AnimatedOpacity(
                        opacity: (!widget.editable && visible) ? 1.0 : 0,
                        duration: animationDuration,
                        child: StatusWidget(
                          status: widget.statInfo.status,
                          margin: EdgeInsets.all(defaultPadding),
                        )),
                  AnimatedOpacity(
                      opacity: (widget.editable) ? 1.0 : 0,
                      duration: animationDuration,
                      child: IgnorePointer(
                          ignoring: !widget.editable,
                          child: IconButton(
                              tooltip: "Remove card",
                              onPressed: widget.removeFunction,
                              icon: Icon(Icons.close)))),
                ],
              ))),
    );
  }
}

class ProgressLine extends StatefulWidget {
  const ProgressLine({Key? key, required this.steps}) : super(key: key);
  final List<stat.Step> steps;

  @override
  _ProgressLineState createState() => _ProgressLineState();
}

class _ProgressLineState extends State<ProgressLine> {
  bool isActive = false;

  final maxHeight = 15.0;
  final minHeight = 5.0;

  @override
  Widget build(BuildContext context) {
    List<Widget> bars = [];

    var backgroundBar = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).accentColor.withOpacity(0.1),
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(borderRadius)),
      ),
    );

    bars.add(backgroundBar);

    widget.steps
        .sort((step1, step2) => step2.percentage.compareTo(step1.percentage));

    for (int i = 0; i < widget.steps.length; i++) {
      var bar = StepWidget(
          step: widget.steps[i], index: i, steps: widget.steps.length);
      bars.add(bar);
    }

    return MouseRegion(
        onEnter: (value) {
          setState(() {
            isActive = true;
          });
        },
        onExit: (value) {
          setState(() {
            isActive = false;
          });
        },
        child: AnimatedContainer(
            duration: animationDuration,
            margin:
                EdgeInsets.only(top: (isActive) ? 0 : (maxHeight - minHeight)),
            height: (isActive || (Responsive.isMobile(context)))
                ? maxHeight
                : minHeight,
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: bars,
            )));
  }
}

class StepWidget extends StatefulWidget {
  const StepWidget(
      {Key? key, required this.step, required this.index, required this.steps})
      : super(key: key);

  final stat.Step step;
  final int index;
  final int steps;

  @override
  _StepWidgetState createState() => _StepWidgetState();
}

class _StepWidgetState extends State<StepWidget> {
  bool isActive = false;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => PortalEntry(
          visible: isActive,
          portalAnchor: Alignment.bottomLeft,
          childAnchor: Alignment.bottomLeft,
          closeDuration: animationDuration,
          child: MouseRegion(
              onEnter: (value) {
                setState(() {
                  isActive = true;
                });
              },
              onExit: (value) {
                setState(() {
                  isActive = false;
                });
              },
              child: AnimatedContainer(
                duration: animationDuration,
                width: constraints.maxWidth * (widget.step.percentage),
                height: constraints.maxHeight,
                child: Container(),
                decoration: BoxDecoration(
                  color: (widget.step.color ?? Theme.of(context).accentColor)
                      .withOpacity(
                          0.5 + (0.4) * ((widget.index + 1) / widget.steps)),
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(borderRadius),
                      bottomRight: Radius.circular(borderRadius),
                      topRight: Radius.circular(
                          (!isActive && !(Responsive.isMobile(context)))
                              ? 0
                              : borderRadius)),
                ),
              )),
          portal: IgnorePointer(
            child: Container(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                child: AnimatedOpacity(
                    opacity: (isActive) ? 1 : 0,
                    duration: animationDuration,
                    child: Text(
                      widget.step.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .caption
                          ?.copyWith(fontSize: 11.0, color: primaryTextColor),
                    ))),
          )),
    );
  }
}

class LastUpdatedStatsCard extends StatefulWidget {
  final int lastUpdatedTimestamp;
  final bool editable;
  final VoidCallback removeFunction;
  final String title;
  final MapEntry<String, int>? additionalTimeStamp;

  LastUpdatedStatsCard(
      {required this.lastUpdatedTimestamp,
      required this.editable,
      required this.removeFunction,
      required this.title,
      this.additionalTimeStamp});
  LastUpdatedStatsCardState createState() => LastUpdatedStatsCardState();
}

class LastUpdatedStatsCardState extends State<LastUpdatedStatsCard> {
  String timeSince = "0 seconds";
  String additionalTimeSince = "0 seconds";
  StatsCardStatus status = StatsCardStatus.None;

  late Timer timer;
  @override
  void initState() {
    calculateTimeSince();
    timer = Timer.periodic(
        (timeSince.contains("minutes"))
            ? Duration(minutes: 1)
            : Duration(seconds: 1),
        (Timer t) => setState(() {
              calculateTimeSince();
            }));
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void calculateTimeSince() {
    status = StatsCardStatus.Good;

    int timeSinceInt = DateTime.now()
        .difference(
            DateTime.fromMillisecondsSinceEpoch(widget.lastUpdatedTimestamp))
        .inSeconds;
    String units = "seconds";

    if (timeSinceInt > 60) {
      timeSinceInt = timeSinceInt ~/ 60;
      units = "minutes";
      if (timeSinceInt > 30)
        status = StatsCardStatus.Bad;
      else if (timeSinceInt > 20) status = StatsCardStatus.Meh;
    }

    timeSince = "$timeSinceInt $units";

    if (widget.additionalTimeStamp != null) {
      int additionalTimeSinceInt = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(
              widget.additionalTimeStamp!.value))
          .inSeconds;
      String additionalUnits = "seconds";

      if (additionalTimeSinceInt > 60) {
        additionalTimeSinceInt = additionalTimeSinceInt ~/ 60;
        additionalUnits = "minutes";
        if (additionalTimeSinceInt > 30)
          status = StatsCardStatus.Bad;
        else if (timeSinceInt > 20) status = StatsCardStatus.Meh;
      }

      additionalTimeSince = "$additionalTimeSinceInt $additionalUnits";
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatsCard(
      statInfo: StatInfo(
          title: widget.title,
          data: timeSince.split(" ")[0],
          type: " " + timeSince.split(" ")[1] + " ago",
          description: (widget.additionalTimeStamp != null)
              ? "\n${widget.additionalTimeStamp!.key}: $additionalTimeSince ago"
              : "",
          status: status),
      editable: widget.editable,
      removeFunction: widget.removeFunction,
    );
  }
}
