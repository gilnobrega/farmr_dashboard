import 'package:farmr_dashboard/controllers/indexes_controller.dart';
import 'package:farmr_dashboard/models/stat.dart' as stat;
import 'package:farmr_dashboard/responsive.dart';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:drag_and_drop_gridview/devdrag.dart';
import 'package:proper_filesize/proper_filesize.dart';
import 'package:provider/provider.dart';

import 'package:farmr_client/stats.dart';

import '../../../constants.dart';
import 'stats_card.dart';

class StatsPanel extends StatelessWidget {
  const StatsPanel(
      {Key? key,
      required this.stats,
      required this.harvesterID,
      required this.isAggregated})
      : super(key: key);

  final Stats stats;
  final String harvesterID;
  final bool isAggregated;

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    return Column(
      children: [
        Responsive(
          //ADJUST THESE VALUES
          mobile: StatsCardGridView(
            isAggregated: isAggregated,
            crossAxisCount: columnNumber(context),
            childAspectRatio: _size.width < 400
                ? 0.9
                : _size.width < 500
                    ? 1
                    : 1.4,
            stats: stats,
            harvesterID: harvesterID,
          ),
          tablet: StatsCardGridView(
            isAggregated: isAggregated,
            stats: stats,
            harvesterID: harvesterID,
          ),
          desktop: StatsCardGridView(
            isAggregated: isAggregated,
            childAspectRatio: _size.width < 1400 ? 1.1 : 1.7,
            stats: stats,
            harvesterID: harvesterID,
          ),
        ),
      ],
    );
  }
}

class StatsCardGridView extends StatefulWidget {
  const StatsCardGridView(
      {Key? key,
      this.crossAxisCount = 4,
      this.childAspectRatio = 1,
      required this.stats,
      required this.harvesterID,
      required this.isAggregated})
      : super(key: key);

  final int crossAxisCount;
  final double childAspectRatio;

  final Stats stats;
  final String harvesterID;
  final bool isAggregated;

  @override
  StatsCardGridViewState createState() => StatsCardGridViewState();
}

class StatsCardGridViewState extends State<StatsCardGridView> {
  List<stat.StatInfo> workingList = [];
  String? currentHarvesterID;
  bool editable = false;

  @override
  void initState() {
    super.initState();

    updateCards();
  }

  updateCards() {
    if (currentHarvesterID == null ||
        currentHarvesterID != widget.harvesterID) {
      List<stat.StatInfo> statsCards = [];

      bool parseLogsEnabled = (widget.stats.numberFilters > 0 ||
          widget.stats.missedChallenges > 0 ||
          widget.stats.shortSyncNumber > 0 ||
          widget.stats.completeSubSlots > 0);

      //status card
      statsCards.add(stat.StatInfo(
          title: "Status",
          data: widget.stats.status,
          type: "",
          description: "",
          status: Stats.normalStatus.contains(widget.stats.status)
              ? StatsCardStatus.Good
              : (widget.stats.status == "Syncing")
                  ? StatsCardStatus.Meh
                  : StatsCardStatus.Bad));

      //Farmed Balance
      if (widget.stats.balance >= 0.0) {
        statsCards.add(stat.StatInfo(
            title: "Farmed Balance",
            data: widget.stats.balance.toString(),
            type: " ${widget.stats.crypto.toUpperCase()}",
            description:
                "\n${widget.stats.balanceFiat.toStringAsFixed(2)} ${widget.stats.currency}"));
      }

      //Wallet Balance
      if (widget.stats.walletBalance >= 0.0) {
        statsCards.add(stat.StatInfo(
            title: "Wallet Balance",
            data: widget.stats.walletBalance.toString(),
            type: " ${widget.stats.crypto.toUpperCase()}",
            description:
                "\n${widget.stats.walletBalanceFiat.toStringAsFixed(2)} ${widget.stats.currency}"));
      }

      //Cold Wallet Balance
      if (widget.stats.coldNetBalance >= 0.0) {
        statsCards.add(stat.StatInfo(
            title: "Cold Wallet Balance",
            data: widget.stats.coldNetBalance.toString(),
            type: " ${widget.stats.crypto.toUpperCase()}",
            description:
                "\n${widget.stats.coldNetBalanceFiat.toStringAsFixed(2)} ${widget.stats.currency}"));
      }

      //Unsettled Balance (HPool Only)
      if (widget.stats.undistributedBalance >= 0.0) {
        statsCards.add(stat.StatInfo(
            title: "Unsettled Balance",
            data: widget.stats.undistributedBalance.toString(),
            type: " ${widget.stats.crypto.toUpperCase()}",
            description:
                "\n${widget.stats.undistributedBalanceFiat.toStringAsFixed(2)} ${widget.stats.currency}"));
      }

      //Pending Balance (FoxyPoolOG/FlexPool Only)
      if (widget.stats.pendingBalance >= 0.0) {
        statsCards.add(stat.StatInfo(
            title: "Pending Balance",
            data: widget.stats.pendingBalance.toString(),
            type: " ${widget.stats.crypto.toUpperCase()}",
            description:
                "\n${widget.stats.pendingBalanceFiat.toStringAsFixed(2)} ${widget.stats.currency}"));
      }

      //Collateral Balance (FoxyPoolOG Only)
      if (widget.stats.collateralBalance >= 0.0) {
        statsCards.add(stat.StatInfo(
            title: "Collateral Balance",
            data: widget.stats.collateralBalance.toString(),
            type: " ${widget.stats.crypto.toUpperCase()}",
            description:
                "\n${widget.stats.collateralBalanceFiat.toStringAsFixed(2)} ${widget.stats.currency}"));
      }

      //paid balance
      if (widget.stats.paidBalance >= 0.0) {
        statsCards.add(stat.StatInfo(
            title: "Paid Balance",
            data: widget.stats.paidBalance.toString(),
            type: " ${widget.stats.crypto.toUpperCase()}",
            description:
                "\n${widget.stats.paidBalanceFiat.toStringAsFixed(2)} ${widget.stats.currency}"));
      }
      //pool current/total points
      if (widget.stats.currentPoints >= 0) {
        statsCards.add(stat.StatInfo(
            title: "Pool Points",
            data: widget.stats.currentPoints.toString(),
            type: " points",
            description: (widget.stats.totalPoints >= 0)
                ? "\nTotal: ${widget.stats.totalPoints} points"
                : ""));
      }

      //pool effective capacity
      if (widget.stats.capacity >= 0) {
        statsCards.add(stat.StatInfo(
            title: "Effective Capacity",
            data: ProperFilesize.generateHumanReadableFilesize(
                    widget.stats.capacity.toDouble())
                .split(' ')[0],
            type: " " +
                ProperFilesize.generateHumanReadableFilesize(
                        widget.stats.capacity.toDouble())
                    .split(' ')[1],
            description: (widget.stats.difficulty >= 0)
                ? "\nDifficulty ${widget.stats.difficulty}"
                : ""));
      }

      if (widget.stats.lastPartial != null) {
        statsCards.add(stat.StatInfo(
          title: "Last Partial",
          data: widget.stats.lastPartial!.millisecondsSinceEpoch.toString(),
          statInfoType: stat.StatInfoType.LastUpdated,
          type: "",
        ));
      }

      List<stat.Step> typeSteps = [];
      var entries = widget.stats.typeCount.entries.toList();
      entries.sort((entry1, entry2) => entry1.value.compareTo(entry2.value));

      double total = 0;

      for (var type in widget.stats.typeCount.entries) {
        double ratio = type.value / widget.stats.numberOfPlots;
        total += ratio;
        typeSteps.add(stat.Step(total, null, '${type.value} ${type.key}'));
      }

      statsCards.add(stat.StatInfo(
          title: "Number of Plots",
          data: widget.stats.numberOfPlots.toString(),
          type: " plots",
          description: "\nfarmed for ${widget.stats.farmedDays.round()} days",
          steps: typeSteps));

      if (widget.stats.supportDiskSpace) {
        var ratio = widget.stats.plotsSize / widget.stats.totalSize;
        String outOfSpaceString = (widget.stats.outOfSpaceString != "")
            ? "\nout of space in ${widget.stats.outOfSpaceString}"
            : '';

        statsCards.add(stat.StatInfo(
            title: "Plotted Space",
            data: widget.stats.plottedSpace.split(' ')[0],
            type: "", // + stats.plottedSpace.split(' ')[1], //units
            description:
                " ${(widget.stats.plottedSpace.split(' ')[1] != widget.stats.totalSpace.split(' ')[1]) ? widget.stats.plottedSpace.split(' ')[1] : ''} / ${widget.stats.totalSpace}$outOfSpaceString",
            steps: [
              stat.Step(
                  ratio, null, "${(ratio * 100).toStringAsFixed(1)}% full"),
            ]));
      } else {
        statsCards.add(stat.StatInfo(
            title: "Plotted Space",
            data: widget.stats.plottedSpace.split(' ')[0],
            type: " " + widget.stats.plottedSpace.split(' ')[1]));
      }

      //OG VS NFT PLOTS
      if (widget.stats.numberOfNFTPlots > 0 &&
          widget.stats.numberOfOGPlots > 0 &&
          widget.stats.numberOfNFTPlots != widget.stats.numberOfOGPlots) {
        statsCards.add(stat.StatInfo(
          title: "OG Plots",
          data: widget.stats.numberOfOGPlots.toString(),
          type: " plots",
          description: "\nfarmed for ${widget.stats.ogFarmedDays.round()} days",
        ));
        statsCards.add(stat.StatInfo(
            title: "OG Plotted Space",
            data: widget.stats.ogPlottedSpace.split(' ')[0],
            type: " " + widget.stats.ogPlottedSpace.split(' ')[1]));

        statsCards.add(stat.StatInfo(
          title: "NFT Plots",
          data: widget.stats.numberOfNFTPlots.toString(),
          type: " plots",
          description:
              "\nfarmed for ${widget.stats.nftFarmedDays.round()} days",
        ));
        statsCards.add(stat.StatInfo(
            title: "NFT Plotted Space",
            data: widget.stats.nftPlottedSpace.split(' ')[0],
            type: " " + widget.stats.nftPlottedSpace.split(' ')[1]));
      }

      //FAILED PLOTS
      if (widget.stats.numberOfFailedPlots > 0) {
        statsCards.add(stat.StatInfo(
            title: "Failed to load",
            data: widget.stats.numberOfFailedPlots.toString(),
            type: " plots",
            description: "",
            status: StatsCardStatus.Bad));
      }

      //hides network size, etw, etc. if netspace is invalid
      if (widget.stats.netSpaceSize > 1) {
        statsCards.add(stat.StatInfo(
            title: "Network Size",
            data: widget.stats.netSpace.split(' ')[0],
            type: " " +
                widget.stats.netSpace.split(
                    ' ')[1], // + stats.plottedSpace.split(' ')[1], //units
            description: (widget.stats.netSpaceGrowth != "")
                ? "\n${widget.stats.netSpaceGrowth} over 24h"
                : ""));

        if (widget.stats.netSpaceSize > 1 && widget.stats.crypto == "xch")
          statsCards.add(stat.StatInfo(
              title: "Network Growth",
              data: (widget.stats.numberOfPlotsToKeepUpWithNetspaceGrowth > 0)
                  ? widget.stats.numberOfPlotsToKeepUpWithNetspaceGrowth
                      .toString()
                  : "0",
              type:
                  " plots per day", // + stats.plottedSpace.split(' ')[1], //units
              description: "\nto keep up with network growth"));

        statsCards.add(stat.StatInfo(
            title: "Expected time to win",
            data: (widget.stats.etw > 1)
                ? widget.stats.etw.toStringAsFixed(0)
                : widget.stats.etwHours.toStringAsFixed(0),
            type: (widget.stats.etw > 1) ? " days" : " hours",
            description: (widget.stats.daysSinceLastBlock >
                        widget.stats.farmedDays ||
                    widget.stats.daysSinceLastBlock < 0)
                ? "\nbegan farming ${widget.stats.farmedDays.toStringAsFixed(1)} days ago"
                : "\nlast block " +
                    ((widget.stats.daysSinceLastBlock > 1)
                        ? "${widget.stats.daysSinceLastBlock} days ago"
                        : "${widget.stats.hoursSinceLastBlock.toStringAsFixed(0)} hours ago"),
            steps: [
              stat.Step(
                  widget.stats.effort / 100,
                  (widget.stats.effort <= 100)
                      ? null
                      : (widget.stats.effort >= 300)
                          ? Colors.red
                          : Colors.yellow,
                  "effort: ${widget.stats.effort.toStringAsFixed(0)}%")
            ]));

        statsCards.add(stat.StatInfo(
            title: "Estimated Daily Earnings",
            data: widget.stats.edv.toStringAsPrecision(2),
            type: " ${widget.stats.crypto.toUpperCase()} per day",
            description:
                "\n${widget.stats.edvFiat.toStringAsFixed(2)} ${widget.stats.currency} per day"));

        statsCards.add(stat.StatInfo(
            title: "Estimated Weekly Earnings",
            data: widget.stats.ewv.toStringAsPrecision(2),
            type: " ${widget.stats.crypto.toUpperCase()} per week",
            description:
                "\n${widget.stats.ewvFiat.toStringAsFixed(2)} ${widget.stats.currency} per week"));

        statsCards.add(stat.StatInfo(
            title: "Estimated Monthly Earnings",
            data: widget.stats.emv.toStringAsPrecision(2),
            type: " ${widget.stats.crypto.toUpperCase()} per month",
            description:
                "\n${widget.stats.emvFiat.toStringAsFixed(2)} ${widget.stats.currency} per month"));
      } else
        statsCards
            .add(stat.StatInfo(title: "Network Size", data: "ERROR", type: ""));

      if (parseLogsEnabled)
        statsCards.add(stat.StatInfo(
            title: "Efficiency",
            data: widget.stats.efficiency,
            type: "%",
            description:
                "\n${widget.stats.eligiblePlots} plots passed ${widget.stats.numberFilters} filters"));

      if (parseLogsEnabled)
        statsCards.add(stat.StatInfo(
            title: "Longest Response",
            data: widget.stats.maxTime.toString(),
            type: " seconds",
            description:
                "\n${widget.stats.minTime}s min${(widget.stats.avgTime > 0) ? ', ' + widget.stats.avgTime.toStringAsPrecision(2) + 's avg' : ''} ${(widget.stats.medianTime > 0) ? ', ' + widget.stats.medianTime.toStringAsPrecision(2) + 's median' : ''}",
            status: (widget.stats.maxTime > 30)
                ? StatsCardStatus.Bad
                : (widget.stats.maxTime > 5)
                    ? StatsCardStatus.Meh
                    : StatsCardStatus.Good));

      if (parseLogsEnabled)
        statsCards.add(stat.StatInfo(
            title: "Missed Challenges",
            data: widget.stats.missedChallenges.toString(),
            type: " challenges",
            status: (widget.stats.missedChallenges > 5)
                ? StatsCardStatus.Bad
                : (widget.stats.missedChallenges > 0)
                    ? StatsCardStatus.Meh
                    : StatsCardStatus.Good));

      if (widget.stats.fullNodesConnected > 0.0) {
        if (parseLogsEnabled)
          statsCards.add(stat.StatInfo(
              title: "Complete Sub Slots",
              data: widget.stats.completeSubSlots.toString(),
              type: " sub slots",
              description: "",
              steps: [
                stat.Step(widget.stats.orderedRatio, null,
                    "${(widget.stats.orderedPercentage)}% ordered signage points"),
              ]));

        if (parseLogsEnabled)
          statsCards.add(stat.StatInfo(
              title: "Skipped Blocks",
              data: widget.stats.shortSyncSkippedBlocks.toString(),
              type: " blocks",
              description: (widget.stats.shortSyncSkippedBlocks > 0)
                  ? "\nin ${widget.stats.shortSyncNumber} loss of sync events"
                  : "",
              status: (widget.stats.shortSyncSkippedBlocks > 100)
                  ? StatsCardStatus.Bad
                  : (widget.stats.shortSyncSkippedBlocks > 0)
                      ? StatsCardStatus.Meh
                      : StatsCardStatus.Good));

        if (widget.stats.numberOfNFTPlots > 0 && widget.stats.poolErrors >= 0)
          statsCards.add(stat.StatInfo(
              title: "Pool errors",
              data: widget.stats.poolErrors.toString(),
              type: " errors",
              description: (widget.stats.poolErrors > 0)
                  ? "\n'Error sending partial'"
                  : "",
              status: (widget.stats.poolErrors > 0)
                  ? StatsCardStatus.Bad
                  : StatsCardStatus.Good));

        if (widget.stats.harvesterErrors >= 0)
          statsCards.add(stat.StatInfo(
              title: "Harvester errors",
              data: widget.stats.harvesterErrors.toString(),
              type: " errors",
              description: (widget.stats.harvesterErrors > 0)
                  ? "\n'Harvester did not respond'"
                  : "",
              status: (widget.stats.harvesterErrors > 0)
                  ? StatsCardStatus.Bad
                  : StatsCardStatus.Good));

        statsCards.add(stat.StatInfo(
            title: "Connected to",
            data: widget.stats.fullNodesConnected.toString(),
            type: " nodes",
            status: (widget.stats.fullNodesConnected > 20)
                ? StatsCardStatus.Good
                : (widget.stats.fullNodesConnected > 7)
                    ? StatsCardStatus.Meh
                    : StatsCardStatus.Bad));

        if (widget.stats.syncedBlockHeight > 0)
          statsCards.add(stat.StatInfo(
              title: "Synced Height",
              data: "${widget.stats.syncedBlockHeight}",
              type: " blocks",
              description: ((widget.stats.walletHeight > 0)
                      ? "\nWallet - ${widget.stats.walletHeight}"
                      : "") +
                  ((widget.stats.peakBlockHeight > 0)
                      ? ",  Peak - ~${widget.stats.peakBlockHeight}"
                      : ""),
              status: (widget.stats.peakBlockHeight > 0 &&
                      widget.stats.syncedBlockHeight > 0 &&
                      widget.stats.peakBlockHeight -
                              widget.stats.syncedBlockHeight >
                          50)
                  ? StatsCardStatus.Bad
                  : StatsCardStatus.None));
      }

      if (widget.stats.supportDiskSpace) {
        statsCards.add(stat.StatInfo(
          title: "Drives",
          data: widget.stats.drivesCount.toString(),
          type: " drives",
          description: "\ntotal of ${widget.stats.totalDriveSpace}",
        ));
      }

      if (widget.stats.totalMemory > 0) {
        statsCards.add(stat.StatInfo(
            title: "Memory Usage",
            data: widget.stats.usedMemoryString.split(' ')[0],
            type: "", // + stats.plottedSpace.split(' ')[1], //units
            description:
                "${(widget.stats.usedMemoryString.split(' ')[1] != widget.stats.totalMemoryString.split(' ')[1]) ? widget.stats.usedMemoryString.split(' ')[1] : ''} / ${widget.stats.totalMemoryString}",
            steps: [
              stat.Step(widget.stats.usedMemoryRatio, null,
                  "${widget.stats.usedMemoryPercentage}% full"),
            ]));
      }

      if (widget.stats.cpuName != "") {
        statsCards.add(stat.StatInfo(
          title: "CPU",
          data: widget.stats.cpuThreads.toString(),
          type: " threads", // + stats.plottedSpace.split(' ')[1], //units
          description: "\n" + widget.stats.cpuName,
        ));
      }

      if (widget.stats.blockchainVersion != "") {
        statsCards.add(stat.StatInfo(
          title: "Blockchain Version",
          data: widget.stats.blockchainVersion,
          type: "",
        ));
      }

      if (widget.stats.version != "") {
        statsCards.add(stat.StatInfo(
          title: "farmr Version",
          data: widget.stats.version,
          type: "",
        ));
      }

      statsCards.add(stat.StatInfo(
          title: "Last Updated",
          data: widget.stats.lastUpdated.millisecondsSinceEpoch.toString(),
          statInfoType: stat.StatInfoType.LastUpdated,
          type: "",
          additionalTimeStamps: (widget.stats.oldestUpdated != null)
              ? {
                  "Oldest Report":
                      widget.stats.oldestUpdated!.millisecondsSinceEpoch
                }.entries.first
              : null));

      setState(() {
        workingList = statsCards;
      });

      currentHarvesterID = widget.harvesterID;
    }

    //loads user's order of stats card
    context.read<IndexesController>().loadIndexes(workingList).then((value) {
      setState(() {});
    });
  }

  //removes card at index
  removeFunction(int index) {
    context
        .read<IndexesController>()
        .removeCard(workingList, index)
        .then((value) {
      //loads user's order of stats card
      context.read<IndexesController>().loadIndexes(workingList).then((value) {
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var reorderable = DragAndDropGridView(
      physics: NeverScrollableScrollPhysics(),
      //shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
        childAspectRatio: widget.childAspectRatio,
      ),
      //padding: EdgeInsets.all(20),
      itemBuilder: (context, index) => AnimationConfiguration.staggeredGrid(
          position: index,
          duration: slowAnimationDuration,
          delay: animationDuration,
          columnCount: widget.crossAxisCount,
          child: ScaleAnimation(
              child: FadeInAnimation(
                  child: GestureDetector(
                      onLongPress: (editable) ? null : () {},
                      child: Container(
                        height: 150,
                        width: widget.childAspectRatio * 150,
                        child: (workingList[index].statInfoType ==
                                stat.StatInfoType.LastUpdated)
                            ? LastUpdatedStatsCard(
                                title: workingList[index].title,
                                lastUpdatedTimestamp:
                                    int.parse(workingList[index].data),
                                editable: editable,
                                removeFunction: () => removeFunction(index),
                                additionalTimeStamp:
                                    workingList[index].additionalTimeStamps,
                              )
                            : StatsCard(
                                editable: editable,
                                statInfo: workingList[index],
                                removeFunction: () => removeFunction(index),
                              ),
                      ))))),
      itemCount: workingList.length,
      onWillAccept: (oldIndex, newIndex) {
        return editable; // If you want to accept the child return true or else return false
      },
      onReorder: (oldIndex, newIndex) {
        List<stat.StatInfo> newList = [];
        bool beforeCondition(i) {
          return (oldIndex < newIndex) ? i <= newIndex : i < newIndex;
        }

        bool afterCondition(i) {
          return (oldIndex < newIndex) ? i > newIndex : i >= newIndex;
        }

        for (int i = 0; i < workingList.length; i++) {
          if (i != oldIndex && beforeCondition(i)) newList.add(workingList[i]);
        }
        for (int i = 0; i < workingList.length; i++) {
          if (i == oldIndex) newList.add(workingList[i]);
        }
        for (int i = 0; i < workingList.length; i++) {
          if (i != oldIndex && afterCondition(i)) newList.add(workingList[i]);
        }

        workingList = newList;

        //saves user's order of stats card
        context
            .read<IndexesController>()
            .saveIndexes(workingList)
            .then((value) {
          setState(() {});
        });
      },
    );

    var buttons = Padding(
      padding: EdgeInsets.only(top: defaultPadding / 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        if (editable) Text("You may now drag and drop cards"),
        if (editable && context.read<IndexesController>().modified)
          IconButton(
            icon: Icon(Icons.restore_rounded),
            tooltip: "Reset order",
            onPressed: () {
              context.read<IndexesController>().resetIndexes().then((value) {
                //loads user's order of stats card
                context
                    .read<IndexesController>()
                    .loadIndexes(context.read<IndexesController>().originalList)
                    .then((originalList) {
                  setState(() {
                    workingList = originalList;
                  });
                });
              });
            },
          ),
        SizedBox(width: defaultPadding / 2),
        IconButton(
          tooltip: "Edit order",
          icon: Icon(
            Icons.edit,
            color: Theme.of(context).textTheme.caption?.color,
          ),
          onPressed: () {
            setState(() {
              editable = !editable;
            });
          },
        )
      ]),
    );

    return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [AnimationLimiter(child: reorderable), buttons]);
  }
}

int columnNumber(BuildContext context) {
  return MediaQuery.of(context).size.width < 650 ? 2 : 4;
}
