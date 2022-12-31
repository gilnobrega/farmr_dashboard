import 'package:farmr_dashboard/responsive.dart';
import 'package:farmr_dashboard/screens/dashboard/components/connections_list.dart';
import 'package:farmr_dashboard/screens/dashboard/components/memory_chart.dart';
import 'package:farmr_dashboard/screens/dashboard/components/winner_plots_list.dart';
import 'package:farmr_client/block.dart';
import 'package:farmr_client/farmer/connections.dart';
import 'package:farmr_client/hardware.dart';
import 'package:flutter/material.dart';
import 'package:universal_disk_space/universal_disk_space.dart';

import '../../constants.dart';

import 'components/drives_list.dart';
import 'components/stats_panel.dart';
import 'components/plots_list.dart';
import 'components/jobs_list.dart';
import 'components/filters_chart.dart';
import 'components/plots_chart.dart';
import 'components/plotted_space_chart.dart';

import 'package:farmr_client/stats.dart';
import 'package:farmr_client/plot.dart';
import 'package:farmr_client/extensions/swarpm.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen(
      {required this.key,
      required this.stats,
      required this.plots,
      required this.winnerPlots,
      required this.filterCategories,
      required this.jobs,
      required this.memories,
      required this.harvesterID,
      required this.currentDay,
      required this.isAggregated,
      required this.drives,
      required this.connections,
      required this.winnerBlocks});

  @override
  final Key key;

  final Stats stats;

  final List<Disk> drives;
  final List<Plot> plots;
  final List<Plot> winnerPlots;
  final List<Block> winnerBlocks;

  final List<Memory> memories;
  final List<Job> jobs;
  final List<CountryCount> connections;

  final DateTime currentDay;
  final Map<String, int> filterCategories;
  final String harvesterID;
  final bool isAggregated;

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    List<Widget> charts = [];

    if (widget.stats.numberFilters > 0) {
      charts.addAll([
        FiltersChart(
          filterCategories: widget.filterCategories,
          harvesterID: widget.harvesterID,
        ),
      ]);
    }

    if (widget.plots.length > 0) {
      charts.addAll([
        if (widget.stats.numberFilters > 0) SizedBox(height: defaultPadding),
        PlotsChart(
          plots: widget.plots,
          currentDay: widget.currentDay,
          harvesterID: widget.harvesterID,
        ),
        SizedBox(height: defaultPadding),
        PlottedSpaceChart(
          plots: widget.plots,
          currentDay: widget.currentDay,
          harvesterID: widget.harvesterID,
          farmedDays: widget.stats.farmedDays.ceil(),
        )
      ]);
    }

    //needs at least 1 hour of memory data
    if (widget.memories.length > 6) {
      charts.addAll([
        if (widget.plots.length > 0) SizedBox(height: defaultPadding),
        MemoryChart(
          memories: widget.memories,
          harvesterID: widget.harvesterID,
        )
      ]);
    }

    return Container(
        padding: EdgeInsets.symmetric(horizontal: defaultPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  StatsPanel(
                    isAggregated: widget.isAggregated,
                    stats: widget.stats,
                    harvesterID: widget.harvesterID,
                  ),
                  if (widget.plots.length > 0) SizedBox(height: defaultPadding),
                  if (widget.plots.length > 0)
                    PlotsList(
                      plots: widget.plots,
                      harvesterID: widget.harvesterID,
                    ),
                  if (widget.winnerPlots.length > 0)
                    SizedBox(height: defaultPadding),
                  if (widget.winnerPlots.length > 0)
                    WinnerPlotsList(
                      winnerBlocks: widget.winnerBlocks,
                      winnerPlots: widget.winnerPlots,
                      harvesterID: widget.harvesterID,
                    ),
                  if (widget.drives.length > 0)
                    SizedBox(height: defaultPadding),
                  if (widget.drives.length > 0)
                    DrivesList(
                      drives: widget.drives,
                      harvesterID: widget.harvesterID,
                    ),
                  if (widget.jobs.length > 0) SizedBox(height: defaultPadding),
                  if (widget.jobs.length > 0)
                    JobsList(
                      jobs: widget.jobs,
                      harvesterID: widget.harvesterID,
                    ),
                  if (widget.connections.length > 0)
                    SizedBox(height: defaultPadding),
                  if (widget.connections.length > 0)
                    ConnectionsList(
                      countries: widget.connections,
                      harvesterID: widget.harvesterID,
                    ),
                  if (Responsive.isMobile(context))
                    SizedBox(height: defaultPadding),
                  if (Responsive.isMobile(context)) Column(children: charts),
                  Container(
                    height: defaultPadding,
                  ),
                ],
              ),
            ),
            if (!Responsive.isMobile(context)) SizedBox(width: defaultPadding),
            // On Mobile means if the screen is less than 850 we dont want to show it
            if (!Responsive.isMobile(context))
              Expanded(
                  flex: 2,
                  child: Column(
                      children: (charts + [SizedBox(height: defaultPadding)]))),
          ],
        ));
  }
}
