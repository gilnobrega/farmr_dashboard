import 'package:farmr_dashboard/constants.dart';
import 'package:flutter/material.dart';

import 'package:farmr_client/harvester/harvester.dart';
import 'package:farmr_client/stats.dart';
import 'package:farmr_client/server/netspace.dart';
import 'package:farmr_client/server/price.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class LegacySceen extends StatelessWidget {
  @override
  final Key key;
  final Harvester harvester;
  final Stats stats;
  final NetSpace netspace;
  final Rate rate;

  LegacySceen(
      {required this.key,
      required this.harvester,
      required this.stats,
      required this.netspace,
      required this.rate})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String output = Stats.showHarvester(
        harvester, 0, 0, netspace, true, true, rate, true, true);
    return Container(
        padding: EdgeInsets.all(defaultPadding),
        child: Material(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          child: Container(
              padding: EdgeInsets.all(defaultPadding),
              width: double.maxFinite,
              child: Center(
                  child: MarkdownBody(data: output.replaceAll("\n", "\n\n")))),
        ));
  }
}
