import 'package:clipboard/clipboard.dart';
import 'package:farmr_dashboard/responsive.dart';
import 'package:farmr_client/farmer/connections.dart';
import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import 'package:proper_filesize/proper_filesize.dart';

import '../../../constants.dart';

class ConnectionsList extends StatefulWidget {
  ConnectionsList(
      {Key? key, required this.countries, required this.harvesterID})
      : super(key: key);

  final List<CountryCount> countries;
  final String harvesterID;

  @override
  ConnectionsListState createState() => ConnectionsListState();
}

class ConnectionsListState extends State<ConnectionsList> {
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

      widget.countries.sort((c2, c1) =>
          c1.count.compareTo(c2.count)); //sorts columns by ips length
      //on update clears current rows
      rows = [];
      _loadConnections();
    }
  }

  //lazy loads list of plots
  void _loadConnections() {
    for (int i = 0; i < widget.countries.length; i++) {
      CountryCount country = widget.countries[i];
      rows.add([
        country.code,
        country.name,
        country.ips.length,
        country.bytesRead,
        country.bytesWritten,
        "${country.ips}"
      ]);
    }
  }

  int? _currentSortColumn = 2; //sorts columns by ips length
  bool _isAscending = false;

  void onSort(int columnIndex, bool? onSort) {
    setState(() {
      _currentSortColumn = columnIndex;
      if (_isAscending == true) {
        _isAscending = false;
        // sort the rows ascending
        rows.sort((r1, r2) => r2[columnIndex].compareTo(r1[columnIndex]));
      } else {
        _isAscending = true;
        // sort the product descending
        rows.sort((r1, r2) => r1[columnIndex].compareTo(r2[columnIndex]));
      }
    });
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
            "Connections",
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
                  sortColumnIndex: _currentSortColumn,
                  sortAscending: _isAscending,
                  horizontalMargin: 0,
                  columnSpacing: defaultPadding,
                  columns: [
                    DataColumn(label: Text("Flag"), onSort: null),
                    DataColumn(label: Text("Country"), onSort: onSort),
                    DataColumn(label: Text("Nodes"), onSort: onSort),
                    if (!Responsive.isMobile(context))
                      DataColumn(label: Text("Received"), onSort: onSort),
                    if (!Responsive.isMobile(context))
                      DataColumn(label: Text("Sent"), onSort: onSort),
                  ],
                  rows: List.generate(
                    rows.length,
                    (index) => connectionsDataRow(rows[index], context),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

DataRow connectionsDataRow(List<dynamic> row, BuildContext context) {
  copyListOfIPs() {
    FlutterClipboard.copy(row[5]).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Copied list of IPs from ${row[1]} to clipboard')));
    });
  }

  return DataRow(
    cells: [
      DataCell(Flag.fromString(row[0], height: 32, width: 32)),
      DataCell(Text(row[1])),
      DataCell(Text("${row[2]}"), onTap: copyListOfIPs),
      if (!Responsive.isMobile(context))
        DataCell(
            Text("${ProperFilesize.generateHumanReadableFilesize(row[3])}")),
      if (!Responsive.isMobile(context))
        DataCell(
            Text("${ProperFilesize.generateHumanReadableFilesize(row[4])}")),
    ],
  );
}
