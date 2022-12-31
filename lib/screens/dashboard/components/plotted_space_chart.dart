import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:farmr_client/plot.dart';
import 'package:proper_filesize/proper_filesize.dart';

import 'dart:math' as Math;

import '../../../constants.dart';

class PlottedSpaceChart extends StatelessWidget {
  const PlottedSpaceChart(
      {Key? key,
      required this.plots,
      required this.currentDay,
      required this.harvesterID,
      required this.farmedDays})
      : super(key: key);

  final List<Plot> plots;
  final DateTime currentDay;
  final String harvesterID;
  final int farmedDays;

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
            "Plotted Space",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          PlottedSpaceChartWidget(
            plots: plots,
            currentDay: currentDay,
            harvesterID: harvesterID,
            farmedDays: farmedDays,
          )
        ],
      ),
    );
  }
}

class PlottedSpaceChartWidget extends StatefulWidget {
  PlottedSpaceChartWidget(
      {required this.plots,
      required this.currentDay,
      required this.harvesterID,
      required this.farmedDays});

  final List<Plot> plots;
  final DateTime currentDay;
  final String harvesterID;
  final int farmedDays;

  @override
  PlottedSpaceChartWidgetState createState() => PlottedSpaceChartWidgetState();
}

class PlottedSpaceChartWidgetState extends State<PlottedSpaceChartWidget> {
  final double width = 5;

  List<FlSpot> showingGroups = [];
  List<FlSpot> nftShowingGroups = [];
  List<FlSpot> ogShowingGroups = [];

  bool showNFTvsOG = false;
  bool onlyNFT = false;
  bool onlyOG = true;

  List<MapEntry<String, List<int>>> workingList = [];

  String? currentHarvesterID;

  bool focused = true;

  @override
  void initState() {
    genChartData();

    super.initState();
  }

  void genChartData() {
    if (currentHarvesterID == null ||
        currentHarvesterID != widget.harvesterID) {
      workingList = [];
      Map<String, List<int>> plottedSpaceDays = {};

      int totalSpace = 0;
      int ogSpace = 0;
      int nftSpace = 0;

      for (int i = widget.farmedDays - 1; i >= 0; i--) {
        String nDaysAgoString =
            dateToString(widget.currentDay.subtract(Duration(days: i)));

        List<Plot> plotsNDaysAgo =
            widget.plots.where((plot) => plot.date == nDaysAgoString).toList();

        for (Plot plot in plotsNDaysAgo) {
          totalSpace += plot.size;

          if (plot.isNFT)
            nftSpace += plot.size;
          else
            ogSpace += plot.size;
        }

        plottedSpaceDays.putIfAbsent(
            nDaysAgoString, () => [totalSpace, ogSpace, nftSpace]);
      }

      if (nftSpace != totalSpace && ogSpace != totalSpace) {
        showNFTvsOG = true;
        onlyOG = false;
      } else if (nftSpace == totalSpace) {
        onlyNFT = true;
        onlyOG = false;
      }

      workingList = plottedSpaceDays.entries.toList();

      showingGroups = [];
      ogShowingGroups = [];
      nftShowingGroups = [];
      for (int i = 0; i < workingList.length; i++) {
        var category = workingList[i];

        showingGroups.add(FlSpot(i.toDouble(), category.value[0].toDouble()));
        ogShowingGroups.add(FlSpot(i.toDouble(), category.value[1].toDouble()));
        nftShowingGroups
            .add(FlSpot(i.toDouble(), category.value[2].toDouble()));
      }

      currentHarvesterID = widget.harvesterID;
    }
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
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: false,
                        ),
                        minY: 0,
                        maxY: (workingList.length == 0)
                            ? 0
                            : workingList
                                .map((entry) => entry.value[0].toDouble())
                                .reduce((entry1, entry2) =>
                                    Math.max(entry1, entry2)),
                        lineTouchData: LineTouchData(
                            handleBuiltInTouches: true,
                            enabled: focused,
                            touchTooltipData: LineTouchTooltipData(
                                tooltipBgColor: bgColor,
                                getTooltipItems:
                                    (List<LineBarSpot> touchedBarSpots) {
                                  return touchedBarSpots.map((barSpot) {
                                    final flSpot = barSpot;
                                    int index = flSpot.barIndex;
                                    List<String> titles = ["All", "OG", "NFT"];

                                    return LineTooltipItem(
                                      '${titles[index]}: ${ProperFilesize.generateHumanReadableFilesize(workingList[flSpot.x.toInt()].value[index].toDouble())} \n',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              workingList[flSpot.x.toInt()].key,
                                          style: TextStyle(
                                            color: Colors.grey[100],
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList();
                                })),
                        titlesData: FlTitlesData(
                          show: false,
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        //
                        // lineGroups: showingBarGroups,

                        lineBarsData: [
                          LineChartBarData(
                            show: (showNFTvsOG),
                            spots: showingGroups,
                            isCurved: true,
                            colors: [Theme.of(context).accentColor],
                            barWidth: 5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: false,
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              colors: [Theme.of(context).accentColor]
                                  .map((color) => color.withOpacity(0.3))
                                  .toList(),
                            ),
                          ),
                          LineChartBarData(
                            show: (showNFTvsOG || onlyOG),
                            spots: ogShowingGroups,
                            isCurved: true,
                            colors: [Theme.of(context).accentColor],
                            barWidth: 5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: false,
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              colors: [Theme.of(context).accentColor]
                                  .map((color) => color.withOpacity(0.3))
                                  .toList(),
                            ),
                          ),
                          LineChartBarData(
                            show: (showNFTvsOG || onlyNFT),
                            spots: nftShowingGroups,
                            isCurved: true,
                            colors: [Theme.of(context).accentColor],
                            barWidth: 5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: false,
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              colors: [Theme.of(context).accentColor]
                                  .map((color) => color.withOpacity(0.3))
                                  .toList(),
                            ),
                          ),
                        ],
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
