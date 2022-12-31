import 'package:farmr_dashboard/responsive.dart';
import 'package:farmr_client/block.dart';
import 'package:flutter/material.dart';

import 'package:farmr_client/plot.dart';
import 'package:clipboard/clipboard.dart';
import 'package:intl/intl.dart';
import 'package:proper_filesize/proper_filesize.dart';

import '../../../constants.dart';

class WinnerPlotsList extends StatefulWidget {
  WinnerPlotsList(
      {Key? key,
      required this.winnerPlots,
      required this.harvesterID,
      required this.winnerBlocks})
      : super(key: key);

  final List<Plot> winnerPlots;
  final List<Block> winnerBlocks;
  final String harvesterID;

  @override
  State<StatefulWidget> createState() => WinnerPlotsListState();
}

class WinnerPlotsListState extends State<WinnerPlotsList> {
  List<List<dynamic>> rows = [];
  String? currentHarvesterID; //harvester that's being displayed
  @override
  void initState() {
    super.initState();

    _reset();
  }

  void _reset() {
    if (currentHarvesterID == null ||
        currentHarvesterID != widget.harvesterID) {
      currentHarvesterID = widget.harvesterID;

      //sorts plot from newest to oldest
      widget.winnerPlots
          .sort((plot2, plot1) => plot1.begin.compareTo(plot2.begin));

      //on update clears current rows
      rows = [];
      _loadPlots();
    }
  }

  int? _currentSortColumn = 4;
  bool _isAscending = true;

  void onSort(int columnIndex, bool? onSort) {
    setState(() {
      _currentSortColumn = columnIndex;
      if (_isAscending == true) {
        _isAscending = false;
        // sort the rows ascending
        rows.sort(
            (r1, r2) => r2[columnIndex + 1].compareTo(r1[columnIndex + 1]));
      } else {
        _isAscending = true;
        // sort the product descending
        rows.sort(
            (r1, r2) => r1[columnIndex + 1].compareTo(r2[columnIndex + 1]));
      }
    });
  }

  //lazy loads list of plots
  void _loadPlots() {
    for (int i = 0; i < widget.winnerPlots.length; i++) {
      Plot plot = widget.winnerPlots[i];

      Block? block;
      try {
        block = widget.winnerBlocks
            .firstWhere((element) => element.plotPublicKey == plot.id);
      } catch (error) {}

      rows.add([
        plot.id,
        genPlotType(plot),
        plot.plotSizeInt,
        plot.end,
        block?.timestamp,
        block?.height,
        plot.size,
        plot.drive?.mountPath ?? "N/A"
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
            "Winner Plots",
            style: Theme.of(context).textTheme.subtitle1,
          ),
          ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: double.infinity,
                  //scrollable
                  maxHeight: (Responsive.isMobile(context)) ? 300 : 400),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  horizontalMargin: 0,
                  columnSpacing: defaultPadding,
                  columns: [
                    DataColumn(label: Text("Type"), onSort: onSort),
                    DataColumn(label: Text("Size"), onSort: onSort),
                    DataColumn(label: Text("Completed"), onSort: onSort),
                    DataColumn(label: Text("Farmed"), onSort: onSort),
                    DataColumn(label: Text("Height"), onSort: onSort),
                    DataColumn(label: Text("Filesize"), onSort: onSort),
                    if (Responsive.isDesktop(context))
                      DataColumn(label: Text("Drive"), onSort: onSort),
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

DataRow plotsDataRow(List<dynamic> row, BuildContext context) {
  copyID() {
    FlutterClipboard.copy(row[0]).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copied plot id ${row[0]} to clipboard')));
    });
  }

  return DataRow(
    cells: [
      DataCell(Text(row[1]), onLongPress: copyID),
      DataCell(Text("k${row[2]}")),
      DataCell(Text(DateFormat('y/MM/dd HH:mm').format(row[3]))),
      DataCell(Text(
        (row[4] != null)
            ? DateFormat('y/MM/dd HH:mm')
                .format(DateTime.fromMillisecondsSinceEpoch(row[4]! * 1000))
            : "N/A",
      )),
      DataCell(Text("${row[5]}")),
      DataCell(Text(
          ProperFilesize.generateHumanReadableFilesize(row[6], decimals: 1))),
      if (Responsive.isDesktop(context)) DataCell(Text(row[7])),
    ],
  );
}
