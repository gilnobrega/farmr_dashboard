import 'package:farmr_dashboard/responsive.dart';
import 'package:flutter/material.dart';

import 'package:farmr_client/plot.dart';
import 'package:clipboard/clipboard.dart';

import '../../../constants.dart';

class PlotsList extends StatefulWidget {
  PlotsList({Key? key, required this.plots, required this.harvesterID})
      : super(key: key);

  final List<Plot> plots;
  final String harvesterID;

  @override
  State<StatefulWidget> createState() => PlotsListState();
}

class PlotsListState extends State<PlotsList> {
  List<List<String>> rows = [];
  ScrollController _controller = ScrollController();
  String? currentHarvesterID; //harvester that's being displayed
  @override
  void initState() {
    super.initState();

    _reset();

    //listens if max of scrollable part was reached
    _controller.addListener(() {
      if (_controller.position.pixels >=
              _controller.position.maxScrollExtent / 2 &&
          rows.length < widget.plots.length) {
        setState(() {
          _loadPlots();
        });
      }
    });
  }

  void _reset() {
    if (currentHarvesterID == null ||
        currentHarvesterID != widget.harvesterID) {
      currentHarvesterID = widget.harvesterID;

      //sorts plot from newest to oldest
      widget.plots.sort((plot2, plot1) => plot1.begin.compareTo(plot2.begin));

      //on update clears current rows
      rows = [];
      _loadPlots();
    }
  }

  //lazy loads list of plots
  void _loadPlots() {
    int add = 50;
    final int rowsLength = rows.length;
    final int until = rows.length + add;

    for (int i = rowsLength; i < until && i < widget.plots.length; i++) {
      Plot plot = widget.plots[i];
      rows.add([
        plot.id,
        genPlotType(plot),
        plot.plotSize,
        plot.humanReadableFinishedAgo,
        plot.humanReadableDuration,
        plot.humanReadableSize
      ]);
    }
  }

  String genPlotType(Plot plot) {
    if (!plot.complete) return "Incomplete";
    if (plot.failed)
      return "Failed";
    else if (plot.isNFT)
      return "NFT";
    else
      return "OG";
  }

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
            "Plots",
            style: Theme.of(context).textTheme.subtitle1,
          ),
          ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: double.infinity,
                  //scrollable
                  maxHeight: (Responsive.isMobile(context)) ? 300 : 400),
              child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.vertical,
                child: DataTable(
                  horizontalMargin: 0,
                  columnSpacing: defaultPadding,
                  columns: [
                    DataColumn(label: Text("Type")),
                    DataColumn(label: Text("Size")),
                    DataColumn(label: Text("Completed")),
                    DataColumn(label: Text("Length")),
                    DataColumn(label: Text("Filesize")),
                  ],
                  rows: List.generate(
                    rows.length,
                    (index) => plotsDataRow(rows[index], context),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

DataRow plotsDataRow(List<String> row, BuildContext context) {
  copyID() {
    FlutterClipboard.copy(row[0]).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copied plot id ${row[0]} to clipboard')));
    });
  }

  return DataRow(
    cells: [
      DataCell(Text(row[1]), onLongPress: copyID),
      DataCell(Text(row[2])),
      DataCell(Text(row[3])),
      DataCell(Text(row[4])),
      DataCell(Text(row[5])),
    ],
  );
}
