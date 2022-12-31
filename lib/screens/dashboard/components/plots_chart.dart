import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:farmr_client/plot.dart';

import 'dart:math' as Math;

import '../../../constants.dart';

class PlotsChart extends StatelessWidget {
  const PlotsChart(
      {Key? key,
      required this.plots,
      required this.currentDay,
      required this.harvesterID})
      : super(key: key);

  final List<Plot> plots;
  final DateTime currentDay;
  final String harvesterID;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Plot History",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          PlotsChartWidget(
            plots: plots,
            currentDay: currentDay,
            harvesterID: harvesterID,
          )
        ],
      ),
    );
  }
}

class PlotsChartWidget extends StatefulWidget {
  PlotsChartWidget(
      {required this.plots,
      required this.currentDay,
      required this.harvesterID});

  final List<Plot> plots;
  final DateTime currentDay;
  final String harvesterID;

  @override
  State<StatefulWidget> createState() => PlotsChartWidgetState();
}

class PlotsChartWidgetState extends State<PlotsChartWidget> {
  final double width = 5;

  List<MapEntry<String, List<int>>> workingList = [];
  Map<int, List<int>> xy = {};

  bool nftVsOg = false;
  bool nftOnly = false;
  bool ogOnly = true;

  int maxDays = 30;
  bool focused = true;

  String? currentHarvesterID;

  @override
  void initState() {
    genChartData();

    super.initState();
  }

  void genChartData() {
    bool newHarvester = (currentHarvesterID == null ||
        currentHarvesterID != widget.harvesterID);

    if (newHarvester) {
      xy = {};
      workingList = [];
      Map<String, List<int>> plotDays = {};

      int totalPlotCount = 0;
      int totalOGPlotCount = 0;
      int totalNFTPlotCount = 0;
      for (int i = maxDays - 1; i >= 0; i--) {
        String nDaysAgoString =
            dateToString(widget.currentDay.subtract(Duration(days: i)));

        int plotCount =
            widget.plots.where((plot) => plot.date == nDaysAgoString).length;
        int ogPlotCount = widget.plots
            .where((plot) => plot.date == nDaysAgoString && !plot.isNFT)
            .length;
        int nftPlotCount = widget.plots
            .where((plot) => plot.date == nDaysAgoString && plot.isNFT)
            .length;

        plotDays.putIfAbsent(
            nDaysAgoString, () => [plotCount, ogPlotCount, nftPlotCount]);

        totalPlotCount += plotCount;
        totalOGPlotCount += totalOGPlotCount;
        totalNFTPlotCount += totalNFTPlotCount;
      }

      if (totalPlotCount != totalOGPlotCount &&
          totalPlotCount != totalNFTPlotCount) {
        nftVsOg = true;
        ogOnly = false;
      } else if (totalNFTPlotCount == totalPlotCount) {
        nftOnly = true;
        ogOnly = false;
      }

      workingList = plotDays.entries.toList();

      for (int i = 0; i < workingList.length; i++) {
        var category = workingList[i];

        xy.putIfAbsent(i, () => category.value);
      }

      currentHarvesterID = widget.harvesterID;
    }
  }

  genBarGroups() {
    List<BarChartGroupData> items = [];

    for (var entry in xy.entries) {
      items.add(BarChartGroupData(barsSpace: 1, x: entry.key, barRods: [
        BarChartRodData(
            y: entry.value[0].toDouble(),
            colors: [Theme.of(context).accentColor],
            width: width,
            rodStackItems: (nftVsOg)
                ? [
                    BarChartRodStackItem(0, entry.value[1].toDouble(),
                        Theme.of(context).accentColor),
                    BarChartRodStackItem(
                        entry.value[1].toDouble(),
                        entry.value[0].toDouble(),
                        Theme.of(context).accentColor.withAlpha(127)),
                  ]
                : null),
      ]));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            const SizedBox(
              height: 38,
            ),
            Expanded(
              child: MouseRegion(
                  onEnter: (e) {
                    setState(() {
                      focused = true;
                    });
                  },
                  onExit: (e) {
                    setState(() {
                      focused = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: BarChart(
                      BarChartData(
                        maxY: (workingList == [])
                            ? 0
                            : workingList
                                .map((entry) => entry.value[0].toDouble())
                                .reduce((entry1, entry2) =>
                                    Math.max(entry1, entry2)),
                        barTouchData: BarTouchData(
                            enabled: focused,
                            touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: bgColor,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    (groupIndex == maxDays - 1)
                                        ? "Today\n"
                                        : workingList[groupIndex].key,
                                    TextStyle(color: primaryTextColor),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: "\n" +
                                            ((ogOnly)
                                                ? "OG"
                                                : (nftOnly)
                                                    ? "NFT"
                                                    : "All") +
                                            ": ${rod.y.round()} plots",
                                      ),
                                      if (nftVsOg)
                                        TextSpan(
                                          text:
                                              "\nOG: ${rod.rodStackItems[0].toY.round()} plots",
                                        ),
                                      if (nftVsOg)
                                        TextSpan(
                                          text:
                                              "\nNFT: ${rod.rodStackItems[1].toY.round() - rod.rodStackItems[1].fromY.round()} plots",
                                        )
                                    ],
                                  );
                                })),
                        titlesData: FlTitlesData(
                          show: false,
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        barGroups: genBarGroups(),
                      ),
                    ),
                  )),
            ),
            const SizedBox(
              height: 12,
            ),
          ],
        ),
      ),
    );
  }
}
