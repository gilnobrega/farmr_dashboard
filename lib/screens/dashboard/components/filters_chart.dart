import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'dart:math' as Math;

import '../../../constants.dart';

class FiltersChart extends StatelessWidget {
  const FiltersChart(
      {Key? key, required this.filterCategories, required this.harvesterID})
      : super(key: key);

  final Map<String, int> filterCategories;
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
            "Filters",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          FiltersChartWidget(
            filterCategories: filterCategories,
            harvesterID: harvesterID,
          )
        ],
      ),
    );
  }
}

class FiltersChartWidget extends StatefulWidget {
  FiltersChartWidget(
      {required this.filterCategories, required this.harvesterID});

  final Map<String, int> filterCategories;
  final String harvesterID;

  @override
  State<StatefulWidget> createState() => FiltersChartWidgetState();
}

class FiltersChartWidgetState extends State<FiltersChartWidget> {
  final double width = 5;

  List<MapEntry<String, int>> workingList = [];
  Map<int, double> xy = {};
  double maxValue = 0;
  bool focused = true;

  String? currentHarvesterID;
  String? currentTheme;

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

      workingList = widget.filterCategories.entries.toList();

      //orders entries by doubles in ranges
      workingList.sort((entry1, entry2) =>
          double.parse(entry1.key.split('-')[0])
              .compareTo(double.parse(entry2.key.split('-')[0])));

      for (int i = 0; i < workingList.length; i++) {
        //hand wavy exponential representation to avoid log(0), log(1)
        //shows 1 as log(2)
        //shows 0 as log(2)/2
        var category = workingList[i];
        double log = Math.log(category.value.toDouble() + 1);
        if (log == 0) log = Math.log(1 + 1) / 2;

        maxValue = (maxValue > log) ? maxValue : log;

        xy.putIfAbsent(i, () => log);
      }

      currentHarvesterID = widget.harvesterID;
    }
  }

  genBarGroups() {
    List<BarChartGroupData> items = [];

    for (var entry in xy.entries) {
      items.add(BarChartGroupData(barsSpace: 1, x: entry.key, barRods: [
        BarChartRodData(
          y: entry.value,
          colors: [Theme.of(context).accentColor],
          width: width,
        ),
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
                        maxY: maxValue,
                        barTouchData: BarTouchData(
                            enabled: focused,
                            touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: bgColor,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    workingList[groupIndex].key + 's: ',
                                    TextStyle(color: primaryTextColor),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: workingList[groupIndex]
                                                .value
                                                .toString() +
                                            " filters",
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
