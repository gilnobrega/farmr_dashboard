import 'package:farmr_dashboard/screens/dashboard/components/stats_card.dart';
import 'package:flutter/material.dart';

enum StatInfoType { Regular, LastUpdated }

class StatInfo {
  final String title;
  final String data;
  final String type;
  final String description;
  final List<Step>? steps;
  final StatsCardStatus status;
  final StatInfoType statInfoType;
  final MapEntry<String, int>? additionalTimeStamps;

  StatInfo(
      {required this.title,
      required this.data,
      required this.type,
      this.statInfoType = StatInfoType.Regular,
      this.description = '',
      this.steps,
      this.status = StatsCardStatus.None,
      this.additionalTimeStamps});
}

class Step {
  double percentage;
  Color? color;
  String title;

  Step(this.percentage, this.color, this.title);
}
