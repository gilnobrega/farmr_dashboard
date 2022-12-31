import 'package:farmr_client/hardware.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:intl/intl.dart';
import 'package:proper_filesize/proper_filesize.dart';

import 'dart:math' as Math;

import '../../../constants.dart';

class MemoryChart extends StatelessWidget {
  const MemoryChart({
    Key? key,
    required this.memories,
    required this.harvesterID,
  }) : super(key: key);

  final List<Memory> memories;
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
            "Memory Usage",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          MemoryChartWidget(
            memories: memories,
            harvesterID: harvesterID,
          )
        ],
      ),
    );
  }
}

class MemoryChartWidget extends StatefulWidget {
  MemoryChartWidget({
    required this.memories,
    required this.harvesterID,
  });

  final List<Memory> memories;
  final String harvesterID;

  @override
  MemoryChartWidgetState createState() => MemoryChartWidgetState();
}

class MemoryChartWidgetState extends State<MemoryChartWidget> {
  final double width = 5;

  List<FlSpot> totalMemoryGroup = [];
  List<FlSpot> usedMemoryGroup = [];
  Map<int, Memory> physicalMemories = {};

  List<int> xMinsBlocks = []; //blocks of 10 minutes

  String? currentHarvesterID;

  bool focused = true;

  //blocks of 10 mins
  static const int blockSize = (1000 * 10 * 60);
  static const List<String> titles = ["Total: ", "Used: "];

  @override
  void initState() {
    genChartData();

    super.initState();
  }

  void genChartData() {
    if (currentHarvesterID == null ||
        currentHarvesterID != widget.harvesterID) {
      //blocks of 10 mins last 24 hours
      int dayAgo =
          (DateTime.now().subtract(Duration(hours: 24)).millisecondsSinceEpoch /
                  blockSize)
              .round();

      for (int i = -1; i < 24 * 6; i++)
        xMinsBlocks.add((dayAgo + i) * blockSize);

      for (Memory memory in widget.memories) {
        int? matchingTimestamp;
        try {
          matchingTimestamp = xMinsBlocks
              .firstWhere((e) => (e - memory.timestamp).abs() <= blockSize);
        } catch (err) {}
        if (matchingTimestamp != null && matchingTimestamp != xMinsBlocks.first)
          physicalMemories.update(
              matchingTimestamp, (value) => (value + memory),
              ifAbsent: () => memory);
      }

      xMinsBlocks.removeAt(0);

      for (int i = 0;
          i < ((xMinsBlocks.length == 1) ? 1 : xMinsBlocks.length - 1);
          i++) {
        int xMinsBlock = xMinsBlocks[i];
        //if current block memory is undefined
        //but both previous block and future block memories are defined
        //then it uses previous memory value
        //this smoothens random dips
        Memory prevMemory = ((i - 1 > 0 && i + 1 < (xMinsBlocks.length - 1)) &&
                physicalMemories[xMinsBlocks[i - 1]] != null &&
                physicalMemories[xMinsBlocks[i + 1]] != null)
            ? (physicalMemories[xMinsBlocks[i - 1]] ?? Memory(0, 0, 0, 0))
            : Memory(0, 0, 0, 0);

        if (physicalMemories[xMinsBlock]?.totalMemory != null ||
            totalMemoryGroup.length > 0) {
          totalMemoryGroup.add(FlSpot(
              i.toDouble(),
              physicalMemories[xMinsBlock]?.totalMemory.toDouble() ??
                  prevMemory.totalMemory.toDouble()));
          usedMemoryGroup.add(FlSpot(
              i.toDouble(),
              physicalMemories[xMinsBlock]?.usedMemory.toDouble() ??
                  prevMemory.usedMemory.toDouble()));
        }
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
                        maxY: (physicalMemories.entries.length == 0)
                            ? 0
                            : physicalMemories.entries
                                .map((entry) =>
                                    entry.value.totalVirtualMemory.toDouble())
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
                                    DateTime time =
                                        DateTime.fromMillisecondsSinceEpoch(
                                            xMinsBlocks[barSpot.x.round()]);

                                    return LineTooltipItem(
                                      (barSpot == touchedBarSpots.first)
                                          ? DateFormat("HH:mm").format(time) +
                                              "\n"
                                          : "",
                                      const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: titles[
                                              touchedBarSpots.indexOf(barSpot)],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '${ProperFilesize.generateHumanReadableFilesize(barSpot.y)}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
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
                            spots: totalMemoryGroup,
                            isCurved: false,
                            colors: [
                              Theme.of(context).accentColor.withOpacity(0.3)
                            ],
                            barWidth: 5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: false,
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              colors: [Theme.of(context).accentColor]
                                  .map((color) => color.withOpacity(0.1))
                                  .toList(),
                            ),
                          ),
                          LineChartBarData(
                            spots: usedMemoryGroup,
                            isCurved: false,
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
