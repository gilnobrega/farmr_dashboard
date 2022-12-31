import 'package:farmr_dashboard/controllers/login_controller.dart';
import 'package:farmr_dashboard/controllers/settings_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:farmr_dashboard/constants.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';

class Login {
  LoginState state = LoginState.None;
  FirebaseAuth? auth;

  Login();

  Future<void> init(Function(String overrideToken) loadHarvesters) async {
    if (!debug) {
      await Firebase.initializeApp();

      auth = FirebaseAuth.instance;
      /*auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
        user.getIdToken().then((value) {
          token = value;
        });
      }
    });*/

      auth?.authStateChanges().listen((User? user) {
        if (user == null) {
          print('User is currently signed out!');
        } else {
          print('User is signed in!');

          user.getIdToken(false).then((newToken) {
            //loads harvesters after login
            loadHarvesters(newToken);
          });
        }
      });

      /*FirebaseAuth.instance.userChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
        user.getIdToken().then((value) {
          token = value;
        });
      }
    });*/
    }
  }
}

enum LoginState { LoggedIn, None }

class LoginPage extends StatefulWidget {
  LoginPage();

  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  void _launchURL(String url) async =>
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';

  Future<UserCredential> signInWithGoogle() async {
    // Create a new provider
    GoogleAuthProvider googleProvider = GoogleAuthProvider();

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithPopup(googleProvider);

    // Or use signInWithRedirect
    // return await FirebaseAuth.instance.signInWithRedirect(googleProvider);
  }

  final userAgent = html.window.navigator.userAgent.toString().toLowerCase();
  late final isMobile; //always true
  //forces redirect instead of popup

  @override
  void initState() {
    isMobile = userAgent.contains("android") ||
        userAgent.contains("iphone") ||
        userAgent.contains("ipad") ||
        userAgent.contains("mac") ||
        true; //always true
    if (isMobile) {
      loadCustomToken(context);
    }

    super.initState();
  }

  Future<UserCredential> signInWithApple() async {
    // Create and configure an OAuthProvider for Sign In with Apple.
    final provider = OAuthProvider("apple.com")
      ..addScope('email')
      ..addScope('name');

    // Sign in the user with Firebase.
    return await FirebaseAuth.instance.signInWithPopup(provider);
  }

  Future<UserCredential> signInWithGitHub() async {
    // Create a new provider
    GithubAuthProvider githubProvider = GithubAuthProvider();
    githubProvider.addScope('user');

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithPopup(githubProvider);

    // Or use signInWithRedirect
    // return await FirebaseAuth.instance.signInWithRedirect(githubProvider);
  }

  void signInWithDiscord(BuildContext context) async {
    bool hasCustomToken = false;
    if (isMobile) {
      hasCustomToken = await loadCustomToken(context);
    }

    if (!hasCustomToken)
      context
          .read<LoginController>()
          .loadHarvesters(
              context.read<SettingsController>().currentCurrency, true)
          .onError((error, stackTrace) async {
        if (!debug) {
          String loginUrl = mainURL + "/login-discord.php?action=login";

          //if it is on mobile then replaces current window with login site
          //FORCES redirect
          if (isMobile || true) {
            html.window.location.assign(loginUrl);
            //if on desktop then opens new tab
          } else {
            var _window = html.window.open(
              loginUrl,
              "_blank",
              /*"width=800, height=900, scrollbars=no"*/
            ); //uncomment for window instead of tab

            while (_window != null && !(_window.closed ?? false)) {
              await Future<void>.delayed(Duration(milliseconds: 100));
            }

            await loadCustomToken(context);
          }
        }
      });
  }

  Future<bool> loadCustomToken(BuildContext context) async {
    String customToken = (await http.read(
            Uri.parse(mainURL + "/login-discord.php?action=readCustomToken")))
        .trim();

    print("Custom Token $customToken");
    bool success = true;
    if (customToken != "")
      await context
          .read<LoginController>()
          .login
          ?.auth
          ?.signInWithCustomToken(customToken)
          .catchError((error) {
        success = false;
      });

    return success;
  }

  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(defaultPadding).copyWith(top: 0),
        child: Material(
            borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
            child: Container(
                height: double.maxFinite,
                width: double.maxFinite,
                padding: EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      """Welcome to farmr!
this dashboard collects stats through farmr client.
If you're new to farmr, you can learn more about this open-source project in its github page:""",
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: defaultPadding),
                    ElevatedButton.icon(
                        icon: Icon(MdiIcons.fromString("github")),
                        style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.all(defaultPadding),
                                primary: Color(0xFF333333))
                            .copyWith(
                                shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                        ))),
                        onPressed: () {
                          _launchURL(
                              "https://github.com/joaquimguimaraes/chiabot");
                        },
                        label: Text("Farmr GitHub page")),
                    SizedBox(height: defaultPadding),
                    Text(
                        """If you already have it installed in your full-node device (or hpool client) then you can login with your discord account to monitor your farm:"""),
                    SizedBox(height: defaultPadding),
                    Wrap(
                      spacing: defaultPadding,
                      runSpacing: defaultPadding,
                      children: [
                        ElevatedButton.icon(
                            icon: Icon(MdiIcons.fromString("discord")),
                            style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.all(defaultPadding),
                                    primary: Color(0xFF5865F2))
                                .copyWith(
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                            ))),
                            onPressed: () {
                              signInWithDiscord(context);
                            },
                            label: Text("Login with discord")),
                        ElevatedButton.icon(
                            icon: Icon(MdiIcons.fromString("google")),
                            style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.all(defaultPadding),
                                    primary: Color(0xFF4285F4))
                                .copyWith(
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(borderRadius),
                            ))),
                            onPressed: () {
                              signInWithGoogle();
                            },
                            label: Text("Sign in with Google")),
                        /* ElevatedButton.icon(
                              icon: Icon(MdiIcons.fromString("github")),
                              style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.all(defaultPadding),
                                      primary: Color(0xFF000000))
                                  .copyWith(
                                      shape: MaterialStateProperty.all<
                                              RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(borderRadius),
                              ))),
                              onPressed: () {
                                signInWithGitHub();
                              },
                              label: Text("Sign in with GitHub")) */
                      ],
                    )
                  ],
                ))));
  }
}
