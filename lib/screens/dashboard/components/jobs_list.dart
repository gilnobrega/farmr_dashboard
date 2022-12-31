import 'package:farmr_dashboard/responsive.dart';
import 'package:flutter/material.dart';

import 'package:farmr_client/extensions/swarpm.dart';

import '../../../constants.dart';

class JobsList extends StatefulWidget {
  JobsList({Key? key, required this.jobs, required this.harvesterID})
      : super(key: key);

  final List<Job> jobs;
  final String harvesterID;

  @override
  State<StatefulWidget> createState() => JobsListState();
}

class JobsListState extends State<JobsList> {
  List<List<String>> rows = [];
  String? currentHarvesterID; //harvester that's being displayed

  @override
  void initState() {
    _reset();

    super.initState();
  }

  void _reset() {
    if (currentHarvesterID == null ||
        currentHarvesterID != widget.harvesterID) {
      currentHarvesterID = widget.harvesterID;

      //on update clears current rows
      rows = [];
      _loadJobs();
    }
  }

  //lazy loads list of plots
  void _loadJobs() {
    for (int i = 0; i < widget.jobs.length; i++) {
      Job job = widget.jobs[i];
      rows.add([
        job.number,
        job.name,
        job.size,
        job.started,
        job.elapsed,
        job.phase.toString(),
        job.phaseTimes,
        job.percentage,
        job.space
      ]);
    }
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
            "Swar's Chia Plot Manager",
            style: Theme.of(context).textTheme.subtitle1,
          ),
          ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: double.infinity,
                  //scrollable
                  maxHeight: (Responsive.isMobile(context)) ? 300 : 600),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  horizontalMargin: 0,
                  columnSpacing: defaultPadding,
                  columns: [
                    //hides number column in mobile mode
                    if (Responsive.isDesktop(context))
                      DataColumn(
                        label: Text("Number"),
                      ),
                    DataColumn(
                      label: Text("Job"),
                    ),
                    DataColumn(
                      label: Text("Type"),
                    ),
                    //hides start column in mobile mode
                    if (!Responsive.isMobile(context))
                      DataColumn(
                        label: Text("Start"),
                      ),
                    //hides phase times column in mobile mode
                    if (!Responsive.isMobile(context))
                      DataColumn(
                        label: Text("Elapsed"),
                      ),
                    DataColumn(
                      label: Text("Phase"),
                    ),
                    //hides phase times column in mobile mode
                    if (Responsive.isDesktop(context))
                      DataColumn(
                        label: Text("Phase Times"),
                      ),
                    DataColumn(
                      label: Text("Progress"),
                    ),
                    DataColumn(
                      label: Text("Temp Size"),
                    ),
                  ],
                  rows: List.generate(
                    rows.length,
                    (index) => jobsDataRow(rows[index], context),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

DataRow jobsDataRow(List<String> row, var context) {
  return DataRow(
    cells: [
      //hides number
      if (Responsive.isDesktop(context)) DataCell(Text(row[0])),
      DataCell(Text(row[1])),
      DataCell(Text(row[2])),
      //hides start
      if (!Responsive.isMobile(context)) DataCell(Text(row[3])),
      //hides elapsed column in mobile mode
      if (!Responsive.isMobile(context)) DataCell(Text(row[4])),
      DataCell(Text(row[5])),
      //hides phase times
      if (Responsive.isDesktop(context)) DataCell(Text(row[6])),
      DataCell(Text(row[7])),
      DataCell(Text(row[8]))
    ],
  );
}
