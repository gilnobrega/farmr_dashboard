import 'package:farmr_dashboard/responsive.dart';
import 'package:flutter/material.dart';

import 'package:proper_filesize/proper_filesize.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../../../constants.dart';

class DrivesList extends StatefulWidget {
  DrivesList({Key? key, required this.drives, required this.harvesterID})
      : super(key: key);

  final List<Disk> drives;
  final String harvesterID;

  @override
  State<StatefulWidget> createState() => DrivesListState();
}

class DrivesListState extends State<DrivesList> {
  List<List<dynamic>> rows = [];
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
          rows.length < widget.drives.length) {
        setState(() {
          _loadDrives();
        });
      }
    });
  }

  void _reset() {
    if (currentHarvesterID == null ||
        currentHarvesterID != widget.harvesterID) {
      currentHarvesterID = widget.harvesterID;

      //on update clears current rows
      rows = [];
      _loadDrives();
    }
  }

  //lazy loads list of plots
  void _loadDrives() {
    int add = 50;
    final int rowsLength = rows.length;
    final int until = rows.length + add;

    for (int i = rowsLength; i < until && i < widget.drives.length; i++) {
      Disk drive = widget.drives[i];
      rows.add([
        drive.devicePath,
        drive.mountPath,
        drive.totalSize.toDouble(),
        drive.usedSpace.toDouble(),
        drive.availableSpace.toDouble(),
        (drive.usedSpace / drive.totalSize) * 100
      ]);
    }
  }

  int? _currentSortColumn = null;
  bool _isAscending = true;

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
            "Drives",
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
                  sortColumnIndex: _currentSortColumn,
                  sortAscending: _isAscending,
                  horizontalMargin: 0,
                  columnSpacing: defaultPadding,
                  columns: [
                    if (!Responsive.isMobile(context))
                      DataColumn(label: Text("Device"), onSort: onSort),
                    DataColumn(label: Text("Mounted"), onSort: onSort),
                    DataColumn(label: Text("Size"), onSort: onSort),
                    if (!Responsive.isMobile(context))
                      DataColumn(label: Text("Used"), onSort: onSort),
                    if (!Responsive.isMobile(context))
                      DataColumn(label: Text("Available"), onSort: onSort),
                    DataColumn(label: Text("Full"), onSort: onSort),
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
      if (!Responsive.isMobile(context)) DataCell(Text(row[0])),
      DataCell(Text(row[1])),
      DataCell(Text(
          ProperFilesize.generateHumanReadableFilesize((row[2] as double)))),
      if (!Responsive.isMobile(context))
        DataCell(Text(
            ProperFilesize.generateHumanReadableFilesize((row[3] as double)))),
      if (!Responsive.isMobile(context))
        DataCell(Text(
            ProperFilesize.generateHumanReadableFilesize((row[4] as double)))),
      DataCell(Text("${(row[5] as double).toStringAsFixed(2)}%")),
    ],
  );
}
