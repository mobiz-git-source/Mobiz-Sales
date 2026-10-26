import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mobizapp/Pages/store/StorePage.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'package:mobizapp/DashBoardScreen.dart';

import '../Components/commonwidgets.dart';
import '../Models/LoginModelClass.dart';
import '../Utilities/rest_ds.dart';
import '../Utilities/sharepref.dart';
import '../confg/sizeconfig.dart';
import '../Models/appstate.dart';
import '../Pages/homepage.dart';
import '../Pages/error_handling_screen.dart';
import 'homepage_Driver.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = "/LoginScreen";

  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final SharedPref sharedPref = SharedPref();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: const Color(0xffFFFBFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: SizeConfig.screenHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: SizeConfig.blockSizeVertical * 45,
                    decoration: BoxDecoration(
                      color: AppConfig.colorPrimary,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(0),
                        topRight: const Radius.circular(0),
                        bottomLeft: const Radius.circular(0),
                        bottomRight: Radius.elliptical(
                          MediaQuery.of(context).size.width,
                          160.0,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: SizeConfig.blockSizeVertical * 13,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 18.0),
                      child: Text(
                        'Mobiz',
                        style: TextStyle(
                            fontSize: AppConfig.headLineSize * 2,
                            color: AppConfig.backgroundColor,
                            fontWeight: AppConfig.headLineWeight),
                      ),
                    ),
                  ),
                  Positioned(
                    top: SizeConfig.blockSizeVertical * 18,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 18.0),
                      child: Text(
                        'Sales',
                        style: TextStyle(
                          fontSize: AppConfig.headLineSize * 1.5,
                          color: AppConfig.backgroundColor,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: SizeConfig.blockSizeVertical * 30,
                    left: SizeConfig.blockSizeHorizontal * 10,
                    child: Card(
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      elevation: 3,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        width: SizeConfig.blockSizeHorizontal * 80,
                        height: SizeConfig.blockSizeVertical * 50,
                        decoration: const BoxDecoration(
                            color: AppConfig.backgroundColor,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonWidgets.verticalSpace(2),
                            Text(
                              'Log In',
                              style: TextStyle(
                                  fontSize: AppConfig.headLineSize * 1.2,
                                  fontWeight: AppConfig.headLineWeight),
                            ),
                            const Text('Please sign in with your details'),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _username,
                              decoration: InputDecoration(
                                labelText: "Username",
                                labelStyle: const TextStyle(
                                    color: AppConfig.colorPrimary),
                                prefixIcon: const Icon(Icons.person),
                                border: myinputborder(),
                                enabledBorder: myinputborder(),
                                focusedBorder: myfocusborder(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock),
                                labelText: "Password",
                                labelStyle: const TextStyle(
                                    color: AppConfig.colorPrimary),
                                enabledBorder: myinputborder(),
                                focusedBorder: myfocusborder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            CommonWidgets.verticalSpace(5),
                            Center(
                              child: CommonWidgets.button(
                                bgColor: AppConfig.colorPrimary,
                                textColor: AppConfig.backgroundColor,
                                function: () {
                                  if (_username.text.isEmpty) {
                                    CommonWidgets.showDialogueBox(
                                        context: context,
                                        title: 'Error',
                                        msg: "Please enter a valid username ");
                                  } else if (_password.text.isEmpty) {
                                    CommonWidgets.showDialogueBox(
                                        context: context,
                                        title: 'Error',
                                        msg: "Please enter a valid password");
                                  } else {
                                    _login();
                                  }
                                },
                                height: SizeConfig.blockSizeVertical * 7,
                                width: SizeConfig.blockSizeHorizontal * 67,
                                radius: 10,
                                title: 'Log In',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder myinputborder() {
    return const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(
        color: Colors.grey,
        width: 3,
      ),
    );
  }

  OutlineInputBorder myfocusborder() {
    return const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(
        color: AppConfig.colorPrimary,
        width: 3,
      ),
    );
  }

  Future<String> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Unique device ID
    } else {
      var iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "";
    }
  }

  void printFullText(String text) {
    final pattern = RegExp('.{1,800}');
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }

  Future<void> _login() async {
    AppState appState = AppState();
    RestDatasource api = RestDatasource();

    try {
      // Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print("FCM TOKEN LOGIN: $fcmToken");

      // Get Device ID
      final deviceId = await getDeviceId();
      print("DEVICE ID LOGIN: $deviceId");

      Map<String, String> bodyJson = {
        "email": _username.text,
        "password": _password.text,
        "fcm_token": fcmToken ?? "",
        "device_id": deviceId,
      };

      print("Request bodyJson: $bodyJson");

      dynamic resJson = await api.sendData(
        '/api/login',
        null,
        jsonEncode(bodyJson),
      );
      print("FULL RESPONSE:");
      print(jsonEncode(resJson));

      print("Status: ${resJson['status']}");
      print("Status Code: ${resJson['status_code']}");
      print("Allow Access: ${resJson['allow_access']}");
      print("Store: ${resJson['store']}");
      printFullText(jsonEncode(resJson));
      print("Allow Access : ${resJson['allow_access']}");
      print("Description : ${resJson['description']}");

      if (resJson == null || resJson.isEmpty) {
        if (mounted) {
          CommonWidgets.showDialogueBox(
              context: context,
              title: "Error",
              msg: "Server connection failed.");
        }
        return;
      }

      // handle 403 - access restricted response from backend
      if (resJson['status_code'] == 403) {
        if (mounted) {
          CommonWidgets.showDialogueBox(
            context: context,
            title: "Access Restricted",
            msg: resJson['description'] ??
                resJson['message'] ??
                "Your account access has been restricted. Please contact support.",
          );
        }
        return;
      }

      if (resJson['allow_access']?.toString().toLowerCase() == "no") {
        if (mounted) {
          CommonWidgets.showDialogueBox(
            context: context,
            title: "Access Restricted",
            msg: resJson['description'] ?? "Login access has been restricted.",
          );
        }
        return;
      }

      LoginModel loginResp = LoginModel.fromJson(resJson);
      print("Role ID: ${loginResp.user?.rolId}");
      if (loginResp.status == "success") {
        // restrict access if store access is disabled
        if (loginResp.store != null && loginResp.store!.allowAccess == 'No') {
          if (mounted) {
            CommonWidgets.showDialogueBox(
                context: context,
                title: "Access Restricted",
                msg: loginResp.store!.description ??
                    "Access to this store has been restricted.");
          }
          return;
        }

        if (loginResp.user != null &&
            loginResp.authorisation != null &&
            loginResp.settings != null) {
          appState.token = loginResp.authorisation!.token;
          appState.storeId = loginResp.user!.storeId;
          appState.rolId = loginResp.user!.rolId;
          appState.name = loginResp.user!.name;
          appState.userId = loginResp.user!.id;
          appState.email = loginResp.user!.email;
          appState.vatState = loginResp.settings?.vatState ?? '';
          appState.discountState = loginResp.settings?.discountState ?? '';
          appState.validate_qtySO = loginResp.settings?.soValQtyState ?? '';
          appState.validate_qtySales =
              loginResp.settings?.qtySalesvalidate ?? '';
          appState.attendanceState = loginResp.settings?.attendanceState ?? '';
          appState.printer = loginResp.settings?.printer ?? '';
          appState.dateFormat = loginResp.settings?.dateFormat ?? 'd-M-Y';
          print("Date Format from API: ${AppState().dateFormat}");
          print(
              "Settings object dateFormat = ${loginResp.settings?.dateFormat}");
          print("AppState dateFormat = ${appState.dateFormat}");
 appState.noOfDecimals = loginResp.currency?.noOfDecimals;
appState.taxName = loginResp.tax?.name?.trim();
appState.code = loginResp.currency?.code;
appState.minor = loginResp.currency?.minor;
appState.loginState = 'LOGGED_IN';

// Round off cap - parse from system_setup array in raw response
try {
  final systemSetup = resJson['system_setup'] as List?;
  if (systemSetup != null) {
    for (var item in systemSetup) {
      if (item['key'] == 'positive_roundoff') {
        appState.roundOffPositive =
            double.tryParse(item['number_value']?.toString() ?? '0') ?? 0;
      } else if (item['key'] == 'negative_roundoff') {
        appState.roundOffNegative =
            double.tryParse(item['number_value']?.toString() ?? '0') ?? 0;
      } else if (item['key'] == 'roundoff_alllowed_in_invoice') {
        appState.roundOffAllowedInInvoice =
            item['flag_value']?.toString().toLowerCase() != 'no';
        print("Round off allowed: ${appState.roundOffAllowedInInvoice}");
      }
    }
  }
} catch (e) {
  print("Round off parse failed (non-blocking): $e");
  appState.roundOffPositive = 0;
  appState.roundOffNegative = 0;
  appState.roundOffAllowedInInvoice = true;
}

// Pazhaya session clear cheythu, pinne ONNU thavana mathram save
await sharedPref.removeAll();
await sharedPref.save("app_state", appState);
await appState.saveTaxName(); // removeAll-inu SESHAM thanne venam

   if (mounted) {
  final rolId = loginResp.user!.rolId;
  print("Navigating with Role ID: $rolId");

  if (rolId == 2 || rolId == 5 || rolId == 29) {
    Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
  } else if (rolId == 4) {
    Navigator.of(context).pushReplacementNamed(HomepageDriver.routeName);
  } else if (rolId == 3) {
    Navigator.of(context).pushReplacementNamed(TransferOptionsPage.routeName);
  } else if (rolId == 7) {
    Navigator.of(context).pushReplacementNamed(DashboardScreen.routeName);
  } else {
    // unsupported role: don't leave the user "logged in"
    appState.loginState = 'LOGGED_OUT';
    await sharedPref.removeAll();

    CommonWidgets.showDialogueBox(
      context: context,
      title: "Unsupported Role",
      msg: "This app does not support role ID: $rolId. Please contact support.",
    );
  }
}
        } else {
          if (mounted) {
            CommonWidgets.showDialogueBox(
                context: context,
                title: "Error",
                msg: "Invalid server response data.");
          }
        }
      } else {
        if (mounted) {
          CommonWidgets.showDialogueBox(
              context: context, title: "Error", msg: "Invalid Email/Password");
        }
      }
    } catch (e) {
      print("LOGIN EXCEPTION: $e");
      if (mounted) {
        CommonWidgets.showDialogueBox(
            context: context, title: "Error", msg: "An error occurred: $e");
      }
    }
  }
}
