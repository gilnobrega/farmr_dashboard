import 'package:after_layout/after_layout.dart';
import 'package:farmr_dashboard/controllers/login_controller.dart';
import 'package:farmr_dashboard/responsive.dart';
import 'package:farmr_dashboard/screens/dashboard/components/stats_card.dart';
import 'package:farmr_client/stats.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../constants.dart';

class OverviewList extends StatefulWidget {
  OverviewList(
      {Key? key, required this.headFarmersStats, required this.harvesterID})
      : super(key: key);

  final Map<String, Stats> headFarmersStats;
  final String? harvesterID;

  @override
  OverviewListState createState() => OverviewListState();
}

class OverviewListState extends State<OverviewList>
    with AfterLayoutMixin<OverviewList> {
  List<List<dynamic>> rows = [];
  int currentRefreshCount = 0; //harvester that's being displayed
  String? currentHarvesterID;

  @override
  void initState() {
    super.initState();
  }

  void afterFirstLayout(BuildContext context) {
    _reset(context);
  }

  void _reset(BuildContext context) {
    if (context.read<LoginController>().refreshCount == 0 ||
        currentRefreshCount == 0 ||
        currentRefreshCount != context.read<LoginController>().refreshCount ||
        widget.harvesterID == null ||
        currentHarvesterID == null ||
        currentHarvesterID != widget.harvesterID) {
      currentRefreshCount = context.read<LoginController>().refreshCount;
      currentHarvesterID = widget.harvesterID;

      //on update clears current rows
      rows = [];
      _loadBlockchains();
    }
  }

  //lazy loads list of plots
  void _loadBlockchains() {
    var entries = widget.headFarmersStats.entries.toList();

    //pins xch to top then orders the rest
    entries.sort((e1, e2) {
      if (e1.key.toLowerCase() == "xch")
        return -1;
      else
        return e1.key.compareTo(e2.key) + 1;
    });

    for (var entry in entries) {
      String currentSymbol = entry.key;
      Stats headFarmer = entry.value;

      rows.add([
        currentSymbol,
        [
          (Stats.normalStatus.contains(headFarmer.status))
              ? StatsCardStatus.Good.index
              : StatsCardStatus.Bad.index,
          headFarmer.status
        ],
        headFarmer.balance,
        (headFarmer.coldNetBalance > 0)
            ? headFarmer.coldNetBalance
            : headFarmer.walletBalance,
        (headFarmer.syncedBlockHeight > 0)
            ? headFarmer.syncedBlockHeight
            : "N/A",
        headFarmer.numberOfPlots,
        headFarmer.maxTime,
        headFarmer.drivesCount,
        [
          (headFarmer.etw > 1) ? headFarmer.etw : headFarmer.etwHours,
          (headFarmer.etw > 1) ? "days" : "hours",
        ], //shows etw in hours if adequate
        headFarmer.effort,
        headFarmer.edv,
        headFarmer.edvFiat
      ]);
    }
  }

  int? _currentSortColumn = 0;
  bool _isAscending = false;

  void onSort(int columnIndex, bool? onSort) {
    setState(() {
      _currentSortColumn = columnIndex;
      if (_isAscending == true) {
        _isAscending = false;
        // sort the rows ascending
        //compares effort
        if (columnIndex == 8 || columnIndex == 1)
          rows.sort(
              (r1, r2) => r2[columnIndex][0].compareTo(r1[columnIndex][0]));
        else //compares the rest
          rows.sort((r1, r2) => r2[columnIndex].compareTo(r1[columnIndex]));
      } else {
        _isAscending = true;
        // sort the product descending
        //compares effort column
        if (columnIndex == 8 || columnIndex == 1)
          rows.sort(
              (r1, r2) => r1[columnIndex][0].compareTo(r2[columnIndex][0]));
        else //compares the rest
          rows.sort((r1, r2) => r1[columnIndex].compareTo(r2[columnIndex]));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _reset(context);
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
              text: TextSpan(
                  text: "Overview",
                  style: Theme.of(context).textTheme.subtitle1,
                  children: [
                TextSpan(
                    text: "  beta",
                    style: Theme.of(context)
                        .textTheme
                        .caption
                        ?.copyWith(fontSize: 10))
              ])),
          ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: double.infinity,
                  //scrollable
                  maxHeight: (Responsive.isMobile(context)) ? 300 : 400),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  sortColumnIndex: _currentSortColumn,
                  sortAscending: _isAscending,
                  horizontalMargin: 0,
                  columnSpacing: defaultPadding,
                  columns: [
                    DataColumn(label: Text("Symbol"), onSort: onSort),
                    DataColumn(label: Text("Status"), onSort: onSort),
                    DataColumn(label: Text("Farmed"), onSort: onSort),
                    DataColumn(label: Text("Wallet"), onSort: onSort),
                    DataColumn(label: Text("Height"), onSort: onSort),
                    DataColumn(label: Text("Plots"), onSort: onSort),
                    DataColumn(label: Text("Max Resp."), onSort: onSort),
                    DataColumn(label: Text("Drives"), onSort: onSort),
                    DataColumn(label: Text("ETW"), onSort: onSort),
                    DataColumn(label: Text("Effort"), onSort: onSort),
                    DataColumn(label: Text("EDV"), onSort: onSort),
                    DataColumn(label: Text("EDV \$"), onSort: onSort),
                  ],
                  rows: List.generate(
                    rows.length,
                    (index) => drivesDataRow(rows[index], context),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

DataRow drivesDataRow(List<dynamic> row, BuildContext context) {
  return DataRow(
    cells: [
      //blockchain
      DataCell(Text((row[0] as String).toUpperCase())),
      //status
      DataCell(StatusWidget(
        status: StatsCardStatus.values[row[1][0]],
        statusMessage: row[1][1],
      )),
      //farmed balance
      DataCell(Text(((row[2] as double) >= 0)
          ? (row[2] as double).toStringAsFixed(2) + " ${row[0].toUpperCase()}"
          : "N/A")),

      //cold/hot wallet balance
      DataCell(Text(((row[3] as double) >= 0)
          ? (row[3] as double).toStringAsFixed(0) + " ${row[0].toUpperCase()}"
          : "N/A")),
      //height
      DataCell(Text(row[4].toString())),
      //plots length
      DataCell(Text(row[5].toString())),
      //response times
      DataCell(Text((row[6] as double).toStringAsFixed(2) + "s")),
      //drives
      DataCell(Text(row[7].toString())),
      //etw
      DataCell(
          Text((row[8][0] as double).toStringAsFixed(1) + " ${row[8][1]}")),

      //effort
      DataCell(Text(((row[9] as double) >= 0)
          ? (row[9] as double).toStringAsFixed(1) + "%"
          : "N/A")),

      //edv
      DataCell(Text((showPrecisionOrFixed((row[10] as double), 2)) +
          " ${row[0].toUpperCase()}")),
      //edv dollars
      DataCell(Text((row[11] as double).toStringAsFixed(2) + r"$")),
    ],
  );
}

String showPrecisionOrFixed(double input, int digits) {
  if (input > 10)
    return input.toStringAsFixed(digits);
  else
    return input.toStringAsPrecision(digits);
}

class StatusWidget extends StatelessWidget {
  final String? statusMessage;
  final StatsCardStatus status;
  final EdgeInsetsGeometry? margin;

  StatusWidget({this.statusMessage, required this.status, this.margin});
  @override
  Widget build(BuildContext context) {
    final innerContainer = AnimatedContainer(
      duration: animationDuration,
      margin: margin,
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        shape: status == StatsCardStatus.Good
            ? BoxShape.circle
            : BoxShape.rectangle,
        color: status == StatsCardStatus.Good
            ? Colors.lightGreenAccent
            : Colors.red[200],
      ),
    );
    return (statusMessage != null)
        ? Tooltip(message: statusMessage!, child: innerContainer)
        : innerContainer;
  }
}
