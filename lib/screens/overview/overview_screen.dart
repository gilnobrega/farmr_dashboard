import 'package:auto_size_text/auto_size_text.dart';
import 'package:farmr_dashboard/constants.dart';
import 'package:farmr_dashboard/screens/overview/overview_list.dart';
import 'package:farmr_client/harvester/harvester.dart';
import 'package:farmr_client/stats.dart';
import 'package:farmr_client/wallets/coldWallets/coldwallet.dart';
import 'package:farmr_client/wallets/localWallets/localWalletJS.dart'
    if (dart.library.io) 'package:farmr_client/wallets/localWallets/localWalletIO.dart';
import 'package:farmr_client/wallets/poolWallets/genericPoolWallet.dart';
import 'package:farmr_client/wallets/wallet.dart';
import 'package:flutter/material.dart';

class OverviewScreen extends StatefulWidget {
  final Map<String, List<Harvester>> harvesters;
  final Map<String, Stats> headFarmersStats;
  final String? harvesterID;

  OverviewScreen(
      {required this.harvesters,
      required this.headFarmersStats,
      required this.harvesterID});

  OverviewScreenState createState() => OverviewScreenState();
}

class OverviewScreenState extends State<OverviewScreen> {
  Widget build(BuildContext context) {
    List<List<Harvester>> listOfListOfHarvesters =
        widget.harvesters.entries.map((e) => e.value).toList();

    List<Widget> rows = [];

    for (var list in listOfListOfHarvesters) {
      if (list.isNotEmpty) rows.add(BlockchainRow(harvesters: list));
    }
    return SingleChildScrollView(
        child: Column(
      children: [
        SizedBox(height: defaultPadding),
        OverviewList(
          headFarmersStats: widget.headFarmersStats,
          harvesterID: widget.harvesterID,
        ),
        // SizedBox(height: defaultPadding),
        // Wrap(
        //    spacing: defaultPadding, runSpacing: defaultPadding, children: rows)
      ],
    ));
  }
}

class BlockchainRow extends StatelessWidget {
  final List<Harvester> harvesters;
  BlockchainRow({required this.harvesters});

  Widget build(BuildContext context) {
    List<Widget> children = [];
    List<Widget> wallets = [];

    for (var harvester in harvesters) {
      children.add(BlockchainCard(harvester: harvester));
    }

    for (var harvester in harvesters) {
      for (var wallet in harvester.wallets)
        wallets.add(BlockchainWallet(
          wallet: wallet,
          currencySymbol: harvester.crypto,
        ));
    }
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText.rich(TextSpan(
              text: "${harvesters.first.crypto.toUpperCase()}",
              children: [
                TextSpan(
                    text:
                        " - ${harvesters.length} device${(harvesters.length > 1) ? "s" : ""} connected",
                    style: TextStyle(
                        color: Theme.of(context).textTheme.caption?.color))
              ])),
          Material(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                            spacing: defaultPadding,
                            runSpacing: defaultPadding,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            children: children),
                        Wrap(
                            spacing: defaultPadding,
                            runSpacing: defaultPadding,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            children: wallets)
                      ]))),
        ]);
  }
}

class BlockchainCard extends StatelessWidget {
  final Harvester harvester;
  BlockchainCard({required this.harvester});

  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AutoSizeText.rich(
            TextSpan(children: [
              TextSpan(
                  text: "${harvester.name}",
                  style: TextStyle(
                      color: Theme.of(context).textTheme.caption?.color)),
              TextSpan(
                  text: "\n${harvester.status}",
                  style: TextStyle(
                      color: (Stats.normalStatus.contains(harvester.status))
                          ? Theme.of(context).textTheme.bodyText1?.color
                          : Colors.red[400],
                      fontSize: 18))
            ]),
            style: TextStyle(),
          )
        ],
      ),
    );
  }
}

class BlockchainWallet extends StatelessWidget {
  final Wallet wallet;
  final String currencySymbol;
  BlockchainWallet({required this.wallet, required this.currencySymbol});

  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Column(
        children: [
          AutoSizeText.rich(
            TextSpan(children: [
              TextSpan(
                  text: "${wallet.name}",
                  style: TextStyle(
                      color: Theme.of(context).textTheme.caption?.color,
                      fontSize:
                          Theme.of(context).textTheme.bodyText1?.fontSize)),
              if (wallet.daysSinceLastBlock >= 0)
                TextSpan(
                    text: "\nLast block ${wallet.daysSinceLastBlock} days ago"),
              if (wallet is LocalWallet &&
                  (wallet as LocalWallet).confirmedBalance >= 0)
                TextSpan(
                    text:
                        "\nConfirmed Balance: ${(wallet as LocalWallet).confirmedBalanceMajor} ${currencySymbol.toUpperCase()}"),
              if (wallet is LocalWallet &&
                  (wallet as LocalWallet).unconfirmedBalance >= 0)
                TextSpan(
                    text:
                        "\nUnconfirmed Balance: ${(wallet as LocalWallet).unconfirmedBalanceMajor} ${currencySymbol.toUpperCase()}"),
              if (wallet is ColdWallet &&
                  (wallet as ColdWallet).netBalance >= 0)
                TextSpan(
                    text:
                        "\nNet Balance: ${(wallet as ColdWallet).netBalanceMajor} ${currencySymbol.toUpperCase()}"),
              if (wallet is ColdWallet &&
                  (wallet as ColdWallet).grossBalance >= 0)
                TextSpan(
                    text:
                        "\nGross Balance: ${(wallet as ColdWallet).grossBalanceMajor} ${currencySymbol.toUpperCase()}"),
              if (wallet is ColdWallet &&
                  (wallet as ColdWallet).farmedBalance >= 0)
                TextSpan(
                    text:
                        "\nFarmed Balance: ${(wallet as ColdWallet).farmedBalanceMajor} ${currencySymbol.toUpperCase()}"),
              if (wallet is GenericPoolWallet &&
                  (wallet as GenericPoolWallet).pendingBalance >= 0)
                TextSpan(
                    text:
                        "\nPending Balance: ${(wallet as GenericPoolWallet).pendingBalanceMajor} ${currencySymbol.toUpperCase()}"),
              if (wallet is GenericPoolWallet &&
                  (wallet as GenericPoolWallet).collateralBalance >= 0)
                TextSpan(
                    text:
                        "\nCollateral Balance: ${(wallet as GenericPoolWallet).collateralBalanceMajor} ${currencySymbol.toUpperCase()}"),
            ]),
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyText1?.color,
                fontSize: 12),
          )
        ],
      ),
    );
  }
}
