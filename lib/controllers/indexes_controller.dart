import 'dart:convert';

import 'package:farmr_dashboard/models/stat.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IndexesController extends ChangeNotifier {
  List<StatInfo> originalList = [];
  Map<String, dynamic> _originalIndexes = {};
  Map<String, dynamic> _indexes = {};

  bool get modified => _originalIndexes.toString() != _indexes.toString();

  Future<List<StatInfo>> loadIndexes(List<StatInfo> workingList) async {
    if (_originalIndexes.entries.length == 0) {
      _genOriginalIndexes(workingList);
      for (var card in workingList) originalList.add(card);
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _indexes = jsonDecode((prefs.getString('indexes') ?? '{"test":-1}'));

    //removes cards with negative indexes
    workingList
        .removeWhere((card) => ((_indexes[card.title] ?? 999) as int) == -1);

    workingList.sort((w1, w2) => ((_indexes[w1.title] ?? 999) as int)
        .compareTo((_indexes[w2.title] ?? 999) as int));

    _genIndexes(workingList);

    return workingList;
  }

  void _genIndexes(List<StatInfo> workingList) {
    //indexes = {};

    for (StatInfo card in workingList)
      _indexes.update(card.title, (value) => workingList.indexOf(card),
          ifAbsent: () => workingList.indexOf(card));
  }

  Future<void> removeCard(List<StatInfo> workingList, int index) async {
    _indexes.update(workingList[index].title, (value) => -1,
        ifAbsent: () => -1);

    workingList.remove(workingList[index]);
    await saveIndexes(workingList);
  }

  void _genOriginalIndexes(List<StatInfo> workingList) {
    //indexes = {};

    for (StatInfo card in workingList)
      _originalIndexes.update(card.title, (value) => workingList.indexOf(card),
          ifAbsent: () => workingList.indexOf(card));
  }

  Future<void> saveIndexes(List<StatInfo> workingList) async {
    _genIndexes(workingList);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("indexes", jsonEncode(_indexes));
  }

  Future<void> resetIndexes() async {
    _indexes = _originalIndexes;
    await saveIndexes([]);
  }
}
