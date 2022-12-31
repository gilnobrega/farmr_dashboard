import 'package:farmr_dashboard/screens/login/login.dart';
import 'package:farmr_client/config.dart';
import 'package:farmr_client/farmer/farmer.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:farmr_dashboard/screens/main/components/side_menu_list_tile.dart';
import 'package:farmr_client/hpool/hpool.dart';
import 'package:farmr_dashboard/constants.dart';
import 'package:farmr_dashboard/screens/dashboard/dashboard_screen.dart';
import 'package:farmr_dashboard/screens/legacy/legacy_screen.dart';
import 'package:farmr_dashboard/user.dart';

import 'package:http/http.dart' as http;
import 'package:universal_io/io.dart' as io;

import 'package:farmr_client/harvester/harvester.dart';
import 'package:farmr_client/plot.dart';
import 'package:farmr_client/stats.dart';
import 'package:farmr_client/server/price.dart';
import 'package:farmr_client/server/netspace.dart';
import 'package:farmr_client/extensions/swarpm.dart';

class LoginController extends ChangeNotifier {
  Login? login;

  Future<void> init(String savedCurrency) async {
    login = Login();
    await login!.init((String overrideToken) {
      loadHarvesters(savedCurrency, false, overrideToken);
    });
  }

  void logout() {
    rotationController.forward(from: rotationController.value);

    harvesterPages = [];
    user = defaultUser;
    headFarmers = {};
    headFarmersStats = {};
    stats = null;
    loggedIn = false;

    login?.auth?.signOut();
  }

  List<HarvesterPage> harvesterPages = [];

  late Price price;
  late NetSpace netspace;

  //Head Farmer
  Map<String, Harvester> headFarmers = {};
  Map<String, Stats> headFarmersStats = {};

  Harvester? currentHeadFarmer;
  //total list of harvesters
  Map<String, List<Harvester>> harvesters = {"xch": []};

  Stats? stats;
  List<Plot>? plots;
  Map<String, int>? filterCategories;
  List<Job>? jobs;
  Harvester? currentHarvester;
  DateTime? currentDay;
  late Widget dashboard;
  late Widget legacyModeScreen;
  User get defaultUser => User(id: "0", username: "Not logged in");
  User? user;
  bool loggedIn = false;
  bool loaded =
      false; // changes this variable to true after it tries to get harvesters for first time
  bool overview = true;

  void toggleOverview() {
    overview = true;
    notifyListeners();
  }

  //loads with default blockchain as xch
  List<String> get blockchains =>
      (harvesters.entries.length == 0) ? ['xch'] : harvesters.keys.toList();
  int currentBlockchainIndex = 0;

  late AnimationController rotationController;

  int refreshCount = 0;

  //fetches harvesters from server
  Future<void> loadHarvesters(String currentCurrency,
      [bool throwError = false, String? overrideToken]) async {
    refreshCount++;
    //starts rotating refresh button
    stats = null;
    notifyListeners();
    rotationController.repeat();

    try {
      var result = await _getHarvesters(overrideToken ??
          (await login?.auth?.currentUser?.getIdToken()) ??
          null);

      price = result[0];
      netspace = result[1];
      harvesters = result[3];
      headFarmers = result[4];
      headFarmersStats = result[5];

      user = result[2];
      loggedIn = (user?.id ?? "0") != defaultUser.id;
      loaded = true;

      //If it fails to get user data then it launches login page
    } catch (e) {
      loaded = true;
      if (throwError) throw e;
    }

    //does one last turn and then stops
    await rotationController.forward(from: rotationController.value);

    List<HarvesterPage> harvesterPagesTemp = [];

    if (headFarmers[blockchains[currentBlockchainIndex]] != null) {
      selectHarvester(
          headFarmers[blockchains[currentBlockchainIndex]]!, currentCurrency);
      overview = true;

      for (String blockchain in blockchains) {
        //only adds "Farm" tile if there are more than 1 harvesters
        if (harvesters[blockchain]!.length > 1)
          harvesterPagesTemp.add(_createHarvesterPage(
              headFarmers[blockchain]!, true, blockchain, currentCurrency));
        for (Harvester harvester in harvesters[blockchain]!) {
          harvesterPagesTemp.add(_createHarvesterPage(
              harvester, false, blockchain, currentCurrency));
        }
      }

      harvesterPages = harvesterPagesTemp;
    }

    notifyListeners();
  }

  //function that does all the heavy lifting must be static
  static _getHarvesters(String? token) async {
    Price price;
    NetSpace netspace;
    User user;
    //default order of cryptos
    Map<String, List<Harvester>> harvesters = {"xch": [], "xfx": [], "cgn": []};
    Map<String, Harvester> headFarmers = {}; // "head" of farm
    Map<String, Stats> headFarmersStats = {};

    String url = mainURL + "/login.php";
    String netSpaceUrl = mainURL + "/netspace.json";
    String priceUrl = mainURL + "/price.json";

    price = Price.fromJson(jsonDecode(await http.read(Uri.parse(priceUrl))));
    netspace =
        NetSpace.fromJson(jsonDecode(await http.read(Uri.parse(netSpaceUrl))));

    String readUrl = url + "?action=read";

    http.Response response = await http.post(Uri.parse(readUrl),
        body: (token != null) ? {'token': token} : {});

    String contents = (!debug)
        ? response.body.trim()
        : io.File("test.txt").readAsStringSync();

    if (mainURL.contains("dev.farmr.net")) {
      print(contents);
      print("token: " + (token ?? "none"));
    }

    var clientsSerial = jsonDecode(contents);

    user = User(
        id: clientsSerial['user']['id'],
        username: clientsSerial['user']['username'],
        avatar: clientsSerial['user']['avatar']);

    Map<String, int> headFarmerIndex = {};
    String blockchain = "xch";

    //list of harvesters + farmers
    var harvestersDynamic = clientsSerial['harvesters'];

    for (int i = 0; i < harvestersDynamic.length; i++) {
      var clientData = harvestersDynamic[i]['data'];

      final client = (clientData['type'] == 3 ||
              clientData['type'] == 4 ||
              ClientType.values[clientData['type']] == ClientType.Farmer)
          ? Farmer.fromJson(clientData)
          : (ClientType.values[clientData['type']] == ClientType.HPool)
              ? HPool.fromJson(clientData)
              : Harvester.fromJson(clientData);

      blockchain = client.crypto;

      client.id = harvestersDynamic[i]['id'];
      harvesters.update(
        blockchain,
        (array) {
          array.add(client);
          return array;
        },
        ifAbsent: () => [client],
      );

      //If this object is a farmer then adds it to farmers list, if not adds it to harvesters list
      if ((clientData['type'] == 3 || //deprecated foxypool mode
              clientData['type'] == 4 ||
              ClientType.values[clientData['type']] == ClientType.Farmer ||
              //deprecated flexpool mode
              ClientType.values[clientData['type']] == ClientType.HPool) &&
          headFarmers[blockchain] == null) {
        headFarmers.putIfAbsent(
            blockchain,
            () => ((clientData['type'] == 3 ||
                    clientData['type'] == 4 ||
                    ClientType.values[clientData['type']] == ClientType.Farmer))
                ? Farmer.fromJson(clientData)
                : HPool.fromJson(clientData));
        headFarmerIndex.putIfAbsent(
            blockchain, () => harvesters[blockchain]!.indexOf(client));
      }
    }

    List<String> blockchains = harvesters.keys.toList();

    for (String blockchain in blockchains) {
      //sets one harvester as main farmer if there are no farmers
      //obviously it wont show balance
      if (headFarmers[blockchain] == null &&
          harvesters[blockchain]!.length > 0) {
        headFarmers.putIfAbsent(
            blockchain, () => harvesters[blockchain]!.first);
        headFarmerIndex.putIfAbsent(blockchain, () => 0);
      }

      if (harvesters[blockchain]!.length > 0) {
        for (Harvester client in harvesters[blockchain]!) {
          if (harvesters[blockchain]!.indexOf(client) !=
              headFarmerIndex[blockchain]!)
            headFarmers[blockchain]?.addHarvester(client);
        }

        headFarmers[blockchain]?.filterDuplicates(false);

        //orders clients alphabetically
        harvesters[blockchain]!.sort((h1, h2) => h1.name.compareTo(h2.name));

        //orders clients by farmer, harvester, hpool
        harvesters[blockchain]!
            .sort((h1, h2) => h1.type.index.compareTo(h2.type.index));

        //sorts harvesters below anything else
        harvesters[blockchain]!.sort((h1, h2) {
          if (h1.type == ClientType.Harvester &&
              h2.type != ClientType.Harvester)
            return 1;
          else if (h1.type != ClientType.Harvester &&
              h2.type == ClientType.Harvester)
            return -1;
          else
            return 0;
        });
      }
    }

    //removes empty arrays in harvesters
    for (var blockchain in blockchains) {
      if (harvesters[blockchain]!.length == 0)
        harvesters.remove(blockchain);
      //headfarmers id will be the same as harvesters id if only one harvester
      else if (harvesters[blockchain]!.length == 1)
        headFarmers[blockchain]?.id = harvesters[blockchain]![0].id;
    }

    for (var entry in headFarmers.entries) {
      headFarmersStats.putIfAbsent(
          entry.key,
          () => Stats(
              entry.value,
              price.rates["USD"],
              (entry.value.crypto == "xch")
                  ? netspace
                  : (entry.value is Farmer)
                      ? (entry.value as Farmer).netSpace
                      : NetSpace("1 B")));
    }

    return [price, netspace, user, harvesters, headFarmers, headFarmersStats];
  }

  HarvesterPage _createHarvesterPage(Harvester harvester, bool isHeadFarmer,
      String blockchain, String currentCurrency) {
    return HarvesterPage(
        id: harvester.id,
        type: harvester.type,
        title: (isHeadFarmer) ? "Farm" : harvester.name,
        status: harvester.status,
        blockchain: blockchain,
        press: () {
          selectHarvester(harvester, currentCurrency);
          overview = false;

          notifyListeners();
        });
  }

  void selectHarvester(Harvester harvester, String currentCurrency) {
    plots = harvester.allPlots;
    filterCategories = harvester.filterCategories;
    jobs = harvester.swarPM.jobs;
    harvester.currency = currentCurrency;
    stats = Stats(
        harvester,
        price.rates[currentCurrency],
        (harvester.crypto == "xch")
            ? netspace
            : (headFarmers[harvester.crypto] is Farmer)
                ? (headFarmers[harvester.crypto] as Farmer).netSpace
                : NetSpace("1 B"));
    currentDay = stats?.currentDay;

    currentHarvester = harvester;

    dashboard = DashboardScreen(
      key: Key("Harvester" + harvester.id + harvester.name),
      isAggregated: harvester.isAggregate,
      stats: stats!,
      plots: plots!,
      winnerPlots: harvester.winnerPlots,
      winnerBlocks: harvester.winnerBlocks,
      drives: harvester.drives,
      filterCategories: filterCategories!,
      jobs: jobs!,
      currentDay: currentDay!,
      harvesterID: harvester.id,
      memories: harvester.hardware?.memories ?? [],
      connections: (harvester is Farmer) ? harvester.countriesConnected : [],
    );

    legacyModeScreen = LegacySceen(
        key: Key("Legacy Harvester" + harvester.id),
        harvester: harvester,
        stats: stats!,
        netspace: netspace,
        rate: price.rates[harvester.currency]!);
  }
}
