import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:mobizapp/Pages/Picking/pickingList.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Models/appstate.dart';
import '../../Utilities/sharepref.dart';
import '../../confg/appconfig.dart';
import '../../confg/sizeconfig.dart';
import '../../Components/commonwidgets.dart';
import '../../selectproduct.dart';
import '../Stock/StockTransfer_Page.dart';
import '../loginpage.dart';

class TransferOptionsPage extends StatefulWidget {
  static const routeName = "/TransferOptionsPage";

  const TransferOptionsPage({Key? key}) : super(key: key);

  @override
  State<TransferOptionsPage> createState() => _TransferOptionsPageState();
}

class _TransferOptionsPageState extends State<TransferOptionsPage> {
  bool isLoading = true;
  List<dynamic> appIcons = [];
  bool noData = false;
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    fetchTransferIcons();
    _fetchAppVersion();
  }

  Future<void> fetchTransferIcons() async {
    try {
      // final response = await http.get(
      //   Uri.parse(
      //       'http://68.183.92.8:3699/api/store_app_icons_store?store_id=9'),
      // );
final response = await http.get(
  Uri.parse(
      'http://68.183.92.8:3699/api/store_app_icons_store?store_id=${AppState().storeId}'),
);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == false) {
          setState(() {
            noData = true;
            isLoading = false;
          });
          return;
        }

        setState(() {
          if (data['success'] is List) {
            appIcons = data['success'];
          } else if (data['success'] is Map) {
            appIcons =
                (data['success'] as Map<String, dynamic>).values.toList();
          } else {
            appIcons = [];
          }

          // Filter only specific icons you want
          appIcons = appIcons.where((iconData) {
            final iconList = iconData['icon'] as List?;
            if (iconList == null || iconList.isEmpty) return false;
            final iconName = iconList[0]['icon'];
            return iconName == 'transfer_within_a_station' ||
                iconName == 'call_missed_outgoing_rounded';
          }).toList();

          isLoading = false;
          if (appIcons.isEmpty) noData = true;
        });
      } else {
        throw Exception('Failed to load app icons');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        noData = true;
      });
      debugPrint('Error fetching icons: $e');
    }
  }

  conformation(BuildContext context) {
    Widget confirmButtons = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        InkWell(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            width: SizeConfig.safeBlockHorizontal! * 30,
            height: SizeConfig.safeBlockVertical! * 5,
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                color: AppConfig.colorSuccess),
            child: Center(
              child: Text(
                'CANCEL',
                style: TextStyle(
                    fontFamily: 'helvetica',
                    letterSpacing: 1,
                    fontSize: AppConfig.captionSize,
                    color: AppConfig.backButtonColor),
              ),
            ),
          ),
        ),
        InkWell(
          onTap: () async {
            SharedPref().clear();
            AppState().loginState = "";
            Navigator.of(context).pushNamedAndRemoveUntil(
                LoginScreen.routeName, (Route<dynamic> route) => false);
          },
          child: Container(
            width: SizeConfig.safeBlockHorizontal! * 30,
            height: SizeConfig.safeBlockVertical! * 5,
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                color: AppConfig.colorPrimary),
            child: Center(
              child: Text(
                'LOG OUT',
                style: TextStyle(
                    fontFamily: 'helvetica',
                    letterSpacing: 1,
                    fontSize: AppConfig.captionSize,
                    color: AppConfig.backgroundColor),
              ),
            ),
          ),
        ),
      ],
    );
    // set up the AlertDialog
    Dialog alert = Dialog(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CommonWidgets.verticalSpace(2),
            Text(
              "Confirm",
              style: TextStyle(
                  fontSize: AppConfig.headLineSize, fontFamily: 'helvetica'),
            ),
            CommonWidgets.verticalSpace(2),
            Text(
              "Are you sure you want to Logout?",
              style: TextStyle(fontSize: AppConfig.captionSize * 1.2),
              textAlign: TextAlign.center,
            ),
            CommonWidgets.verticalSpace(2),
            confirmButtons,
            CommonWidgets.verticalSpace(2),
          ],
        ),
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> _fetchAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> clearSharedPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  IconData? getIconData(String? iconName) {
    switch (iconName) {
      case 'transfer_within_a_station':
        return Icons.transfer_within_a_station;
      case 'call_missed_outgoing_rounded':
        return Icons.call_missed_outgoing_rounded;
      default:
        return Icons.help;
    }
  }

  Widget _iconButtons({
    required String title,
    required String routeName,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        switch (routeName) {
          case 'StockTransferPage':
            Navigator.pushNamed(context, StockTransferPage.routeName);
            break;
          case 'PickingListPage':
            Navigator.pushNamed(context, PickingListPage.routeName);
            break;
          default:
            CommonWidgets.showDialogueBox(
              context: context,
              title: "Alert",
              msg: "Invalid route",
            );
        }
      },
      child: Container(
        width: SizeConfig.blockSizeHorizontal * 25,
        height: SizeConfig.blockSizeVertical * 12.5,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: AppConfig.colorPrimary,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppConfig.backgroundColor, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppConfig.backgroundColor,
                fontSize: AppConfig.textCaption3Size,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
        backgroundColor: AppConfig.colorPrimary,
        titleSpacing: 0,
        title: RichText(
          text: TextSpan(
            text: 'Hello ',
            style: AppConfig.pageTitleStyle,
            children: <TextSpan>[
              TextSpan(
                text: '${AppState().name}',
                style: AppConfig.pageTitleStyle,
              ),
            ],
          ),
        ),
      ),
      drawer: SizedBox(
        width: SizeConfig.blockSizeHorizontal * 50,
        child: Drawer(
          child: Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Column(
              children: [
                CommonWidgets.verticalSpace(8),
                CircleAvatar(
                    radius: 70.0,
                    backgroundColor: Colors.transparent,
                    child: Lottie.asset(
                        'Assets/Images/Animation - 1722081243637.json',
                        fit: BoxFit.cover,
                        width: 70)),
                ListTile(
                  leading: Icon(Icons.drive_file_rename_outline),
                  title: const Text('Edit Profile'),
                  onTap: () {
                    print(AppState().routeId);
                    print(AppState().vanId);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.call),
                  title: const Text('Contact Us'),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.print),
                  title: const Text('Printer'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrinterTest(),
                        ));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Log Out'),
                  onTap: () {
                    conformation(context);
                    clearSharedPreferences();
                  },
                ),
                const Divider(),
                Text('v$_appVersion'),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : noData
              ? const Center(
                  child: Text(
                    "No data found",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 13,
                      childAspectRatio: .95,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: appIcons.length,
                    itemBuilder: (context, index) {
                      final iconData = appIcons[index];
                      final iconList = iconData['icon'] as List<dynamic>? ?? [];
                      final firstIcon =
                          iconList.isNotEmpty ? iconList[0] : null;
                      final iconName = firstIcon?['icon'] as String? ?? '';
                      final name = firstIcon?['name'] as String? ?? 'Unknown';
                      final url = firstIcon?['url'] as String? ?? '';

                      return _iconButtons(
                        title: name,
                        routeName: url,
                        icon: getIconData(iconName)!,
                      );
                    },
                  ),
                ),
    );
  }
}
