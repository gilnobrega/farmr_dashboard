import 'package:farmr_dashboard/constants.dart';
import 'package:farmr_dashboard/controllers/login_controller.dart';
import 'package:farmr_dashboard/controllers/settings_controller.dart';
import 'package:farmr_dashboard/screens/modals/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class AddDevice extends StatefulWidget {
  AddDevice();

  @override
  AddDeviceState createState() => AddDeviceState();
}

class AddDeviceState extends State<AddDevice> {
  String currentID = "";
  bool valid = false;

  String? validateID(String id) {
    int validLength = 37;

    String firstPart = (id.contains("-") && id.split('-').length == 6)
        ? id.replaceAll(id.split('-')[5], "")
        : id;

    if (firstPart.length == 0) {
      setState(() {
        valid = false;
      });
      return null;
    }
    if (firstPart.length < validLength)
      return "ID is too short";
    else if (firstPart.length > validLength)
      return "ID is too long";
    else if (!firstPart.contains("-"))
      return "Invalid ID format";
    else if (firstPart.split('-').length != 6)
      return "Invalid ID format";
    else {
      setState(() {
        valid = true;
      });
      return null;
    }
  }

  //links id and listens for error
  void submitID() async {
    http.post(
      Uri.parse(mainURL + "/login.php?action=link&id=" + currentID),
      body: {
        'token': await context
            .read<LoginController>()
            .login
            ?.auth
            ?.currentUser
            ?.getIdToken(true),
      },
    ).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Oh no! Something went wrong."),
      ));
    }).then((value) {
      print(value.body);
      if (value.body.trim().contains("success")) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Linked ID with success"),
        ));
        context
            .read<LoginController>()
            .loadHarvesters(context.read<SettingsController>().currentCurrency);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to link ID"),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FarmrTextFormField(
          onChanged: (value) {
            setState(() {
              currentID = value;
            });
          },
          errorText: validateID(currentID),
          labelText: "Device ID",
        ),
        SizedBox(height: defaultPadding),
        IgnorePointer(
            ignoring: !valid,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                        primary: Theme.of(context).accentColor)
                    .copyWith(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ))),
                onPressed: (valid) ? submitID : null,
                child: Text("Add")))
      ],
    );
  }
}
