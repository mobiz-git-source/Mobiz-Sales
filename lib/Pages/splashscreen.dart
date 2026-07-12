import 'package:flutter/material.dart';
import 'package:mobizapp/Pages/homepage.dart';
import 'package:mobizapp/Pages/loginpage.dart';

import '../Models/appstate.dart';
import '../Utilities/sharepref.dart';
import '../confg/appconfig.dart';
import '../confg/appconfigjc.dart';
import '../confg/sizeconfig.dart';
import '../confg/textconfig.dart';
import 'error_handling_screen.dart';
import 'homepage_Driver.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = "/SplashScreen";
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AppConfigJC appConfig = AppConfigJC();
  bool _initDone = false;
  bool callAppConfig = false;
  AppState appState = AppState();
  String? appVersion;
  String? buildNumber;

  // PermissionStatus _permissionStatus = PermissionStatus.undetermined;
  String? planName;
  bool initDone = false;

  String? majorVersion;
  String? minorVersion;
  String? patchVersion;
  bool showMajorRelease = false;
  bool showMinorRelease = false;

  @override
  void dispose() {
    super.dispose();
  }

  _getAppStateDetails(Map<String, dynamic> json) {
    appState.loginState = json['login_state'];
    appState.isExistingUser = json['is_existing_user'];
    appState.token = json['token'];
    appState.userType = json['user_type'];
    appState.name = json['name'];
    appState.appVersion = json['app_version'];
    appState.buildNumber = json['build_number'];
    appState.userId = json['id'];
    appState.storeId = json['store_id'];
    appState.vatState = json['vat_no_vat'];
    appState.discountState = json['discount'];
    appState.validate_qtySO = json['validate_qty_in_so'];
    appState.validate_qtySales = json['validate_qty_in_sales'];
    appState.rolId = json['app_rol_id'];
    appState.email = json['email'];
    appState.osType = json['os_type'];
    appState.imageUrl = json['image_url'];
    appState.minorVersion = json['minor_version'];
    appState.username = json['username'];
    appState.attendanceState = json['attendance'];
    appState.printer = json['printer'];
    appState.noOfDecimals = json['no_of_decimals'];
    appState.code = json['code'];
    appState.devices = json['devices'];
    appState.initialConsent = json['initial_consent'];
    appState.country = json['country'];
    appState.isEmailVerified = json['is_email_verified'];
    appState.isMobileVerified = json['is_mobile_verified'];
  }

  _initAppState() async {
    setState(() {
      _initDone = true;
    });
    SharedPref sharedPref = SharedPref();
    bool appStateRetrieved = false;
    appStateRetrieved = await sharedPref.containsKey('app_state');
    if (appStateRetrieved == true) {
      Map<String, dynamic> resp = await sharedPref.read("app_state");
      _getAppStateDetails(resp);
      appState.appVersion = appVersion;
      appState.buildNumber = buildNumber;

      if (appState.loginState == 'LOGGED_IN') {
        if (mounted)
          Navigator.of(context)
              .pushReplacementNamed(ErrorHandlingScreen.routeName);
      } else {
        if (mounted)
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    } else {
      if (mounted)
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    if (_initDone == false) {
      _initAppState();
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(TextConfig.logo),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              "Initializing..Please wait",
              style: TextStyle(
                  fontSize: AppConfig.textCaptionSize,
                  fontWeight: AppConfig.textCaptionWeight,
                  color: AppConfig.textColorHint),
            ),
          ],
        ),
      ),
    );
  }
}
