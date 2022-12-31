import 'dart:convert';

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:farmr_dashboard/constants.dart';
import 'package:farmr_dashboard/controllers/login_controller.dart';
import 'package:farmr_dashboard/controllers/settings_controller.dart';
import 'package:farmr_dashboard/responsive.dart';
import 'package:farmr_client/blockchain.dart';
import 'package:farmr_client/config.dart';
import 'package:farmr_client/harvester/harvester.dart';
import 'package:farmr_client/server/price.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:group_button/group_button.dart';

class Settings extends StatefulWidget {
  Settings(
      {required this.updateFunction,
      required this.closeFunction,
      required this.harvester});

  final VoidCallback updateFunction;
  final VoidCallback closeFunction;
  final Harvester harvester;

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: defaultPadding,
      spacing: defaultPadding,
      children: [
            Text("Dashboard Settings"),
            ThemeSelector(),
            CurrenciesDropDownButton(),
          ] +
          //only shows config menu if harvester is not a head harvester/farmer
          //and if it has chosen to load online config
          ((!widget.harvester.isAggregate && widget.harvester.onlineConfig)
              ? [
                  Text("${widget.harvester.name} Settings"),
                  ConfigForm(harvester: widget.harvester)
                ]
              : []),
    );
  }
}

class ThemeSelector extends StatefulWidget {
  ThemeSelector();
  ThemeSelectorState createState() => ThemeSelectorState();
}

class ThemeSelectorState extends State<ThemeSelector> {
  Widget build(BuildContext context) {
    var list = SettingsController.availableThemes.entries.toList();
    list.sort((l1, l2) {
      if (l1.key.contains("light") && l2.key.contains("light"))
        return 0;
      else if (l1.key.contains("light")) {
        return 1;
      }
      return -1;
    });
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: list
          .indexOf(list.firstWhere((element) => element.key.contains("light"))),
      mainAxisSpacing: defaultPadding,
      crossAxisSpacing: defaultPadding,
      childAspectRatio: 2,
      children: list
          .map((t) => IntrinsicHeight(
                  child: ThemeButton(
                theme: t.value,
                name: t.key,
              )))
          .toList(),
    );
  }
}

class ThemeButton extends StatelessWidget {
  final SimpleTheme theme;
  final String name;
  ThemeButton({required this.theme, required this.name});

  Widget build(BuildContext context) {
    return Container(child: ThemeSwitcher(builder: (context) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
            color: theme.backgroundColor,
            child: InkWell(
              hoverColor: theme.canvasColor,
              onTap: () {
                context.read<SettingsController>().setTheme(name, context);
              },
              child: AnimatedContainer(
                duration: animationDuration,
                decoration: BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: theme.accentColor, width: 5))),
                child: Container(
                  alignment: Alignment.center,
                  child: AutoSizeText(
                    " $name ",
                    style: TextStyle(color: theme.textColor, fontSize: 12),
                    minFontSize: 4,
                    stepGranularity: 0.1,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )),
      );
    }));
  }
}

class ConfigForm extends StatefulWidget {
  final Harvester harvester;

  ConfigForm({required this.harvester});

  @override
  ConfigFormState createState() => ConfigFormState();
}

class ConfigFormState extends State<ConfigForm> {
  Config? config;
  Map<String, dynamic> configMap = {};
  String previousID = "";
  Map<String, dynamic> defaultMap = {};

  @override
  void initState() {
    super.initState();
  }

  void loadConfig() async {
    try {
      print(widget.harvester.id);
      String contents = await http.read(Uri.parse(
          mainURL + "/login.php?action=readconfig&id=" + widget.harvester.id));
      print(contents);
      configMap = jsonDecode(contents.trim());
    } catch (error) {
      print(error.toString());
    }

    config = Config.fromJson(configMap,
        Blockchain.fromSymbol(widget.harvester.crypto), widget.harvester.type);
    setState(() {
      configMap = config!.genConfigMap();
    });
  }

  //links id and listens for error
  void submitConfig() async {
    defaultMap = Config.fromJson({},
            Blockchain.fromSymbol(widget.harvester.crypto),
            widget.harvester.type)
        .genConfigMap();

    //saves user's currency to config file
    configMap.update("Currency",
        (value) => context.read<SettingsController>().currentCurrency,
        ifAbsent: () => context.read<SettingsController>().currentCurrency);

    Map<String, dynamic> newMap = {};

    //removes entries which are equal to default values
    //wont submit entries which are equal to default
    // TEMPORARILY DISABLED DUE TO ISSUES
    for (var entry in defaultMap.entries)
      if (configMap[entry.key] !=
          null /* && configMap[entry.key] != entry.value*/)
        newMap.putIfAbsent(entry.key, () => configMap[entry.key]);

    http.post(
        Uri.parse(
            mainURL + "/login.php?action=saveconfig&id=" + widget.harvester.id),
        body: {
          'data': jsonEncode(newMap),
          'token': await context
              .read<LoginController>()
              .login
              ?.auth
              ?.currentUser
              ?.getIdToken(true),
        }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Oh no! Something went wrong."),
      ));
    }).then((value) {
      print(value.body);
      if (value.body.trim().contains("success")) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Saved config with success."),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to save config"),
        ));
      }
    });

    setState(() {
      //changes harvester name
      widget.harvester.name = configMap['Name'];
    });

    //reloads harvesters
    /*context
        .read<LoginController>()
        .loadHarvesters(context.read<SettingsController>().currentCurrency);*/
  }

  Widget build(BuildContext context) {
    if (previousID != widget.harvester.id) {
      previousID = widget.harvester.id;
      loadConfig();
    }

    List<Widget> switches = [];
    List<Widget> notificationSwitches = [];

    List<Widget> fields = [];

    for (var configObject in configMap.entries) {
      if (configObject.value is bool) {
        (!(configObject.key.toLowerCase().contains("notifications"))
                ? switches
                : notificationSwitches)
            .add(FarmrSwitch(
                text: configObject.key,
                value: configMap[configObject.key],
                onChanged: (value) {
                  setState(() {
                    configMap[configObject.key] = value;
                  });
                }));
      } else if (configObject.value is String) {
        if (configObject.key != "Currency")
          fields.add(FarmrTextFormField(
              key: configMap[configObject.key].isEmpty
                  ? Key(configObject.key)
                  : Key(configMap[configObject.key]),
              labelText: configObject.key,
              initialValue: configMap[configObject.key],
              onChanged: (value) {
                configMap[configObject.key] = value;
              }));
      } else if (configObject.value is Iterable<String>) {
        fields.add(FarmrTextFormField(
            key: configMap[configObject.key].isEmpty
                ? Key(configObject.key)
                : Key(configMap[configObject.key]),
            labelText: configObject.key,
            initialValue: configMap[configObject.key].join(","),
            onChanged: (value) {
              configMap[configObject.key] = value.split(",");

              //if array is [""] then it clears the empty string
              if (configMap[configObject.key].length == 1 &&
                  configMap[configObject.key][0] == "")
                configMap[configObject.key] = <String>[];
            }));
      }
    }
    return Container(
      child: Form(
          key: Key("Config Form" + widget.harvester.id),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: (<Widget>[
                  SwitchGrid(
                    children: notificationSwitches,
                    mobile: Responsive.isMobile(context),
                  ),
                  SizedBox(height: defaultPadding),
                  SwitchGrid(
                    children: switches,
                    mobile: Responsive.isMobile(context),
                  ),
                ]) +
                fields +
                [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                              primary: Theme.of(context).accentColor)
                          .copyWith(
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ))),
                      onPressed: submitConfig,
                      child: Text("Save"))
                ],
          )),
    );
  }
}

class FarmrSwitch extends StatelessWidget {
  final String text;
  final Function(bool)? onChanged;
  final bool value;
  FarmrSwitch({required this.text, this.onChanged, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).accentColor,
        ),
        Text(text),
      ],
    );
  }
}

class FarmrTextFormField extends StatelessWidget {
  FarmrTextFormField(
      {required this.onChanged,
      this.errorText,
      this.hintText,
      this.labelText,
      this.initialValue,
      this.key});
  final Function(String)? onChanged;
  final String? errorText, hintText, labelText, initialValue;
  final Key? key;

  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: defaultPadding),
      child: TextFormField(
          key: key,
          initialValue: initialValue,
          cursorColor: Theme.of(context).accentColor,
          onChanged: onChanged,
          decoration: InputDecoration(
              focusedBorder: new UnderlineInputBorder(
                  borderSide:
                      new BorderSide(color: Theme.of(context).accentColor)),
              labelStyle:
                  TextStyle(color: Theme.of(context).textTheme.caption!.color),
              errorText: errorText,
              labelText: labelText,
              hintText: hintText)),
    );
  }
}

class SwitchGrid extends StatelessWidget {
  final List<Widget> children;
  final bool mobile;
  SwitchGrid({required this.children, required this.mobile});

  //two columns if desktop/tablet
  //only one column if mobile
  Widget build(BuildContext context) {
    List<Widget> list1 = [];
    List<Widget> list2 = [];
    for (int i = 0; i < children.length; i++) {
      if (i < children.length / 2 || mobile)
        list1.add(children[i]);
      else
        list2.add(children[i]);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Wrap(direction: Axis.vertical, children: list1)),
        if (!mobile)
          Expanded(
              child: Wrap(
            direction: Axis.vertical,
            children: list2,
          ))
      ],
    );
  }
}

class CurrenciesDropDownButton extends StatelessWidget {
  CurrenciesDropDownButton();

  int currentIndex(BuildContext context) {
    var currencies = Price.currencies.entries.toList();
    for (int i = 0; i < currencies.length; i++) {
      if (currencies[i].key ==
          context.read<SettingsController>().currentCurrency) return i;
    }
    return 0;
  }

  Widget build(BuildContext context) {
    return GroupButton(
      isRadio: true,
      spacing: defaultPadding,
      onSelected: (index, isSelected) {
        context
            .read<SettingsController>()
            .setCurrency(Price.currencies.entries.elementAt(index).key);

        context
            .read<LoginController>()
            .loadHarvesters(Price.currencies.entries.elementAt(index).key);
      },
      buttons: Price.currencies.entries
          .map<String>((entry) =>
              "${entry.key} ${(entry.key != entry.value) ? entry.value : ""}")
          .toList(),
      selectedButton: currentIndex(context),
      selectedColor: Theme.of(context).accentColor,
      unselectedColor: Theme.of(context).canvasColor,
      selectedShadow: [],
      unselectedShadow: [],
      unselectedTextStyle:
          TextStyle(color: Theme.of(context).textTheme.caption!.color),
      borderRadius: BorderRadius.circular(borderRadius),
      //selectedTextStyle:
      // TextStyle(color: Theme.of(context).textTheme.caption!.color),
    );
  }
}
