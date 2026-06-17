import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:mobizapp/Components/commonwidgets.dart';
import 'package:mobizapp/Pages/AgeingSummary/AgeingSummaryScreen.dart';
import 'package:mobizapp/Pages/Attendance.dart';
import 'package:mobizapp/Pages/BankReconciliation/BankReconciliationScreen.dart';
import 'package:mobizapp/Pages/DayClose.dart';
import 'package:mobizapp/Pages/ExpensesPage.dart';
import 'package:mobizapp/Pages/Group_Print.dart';
import 'package:mobizapp/Pages/Notifications/notifications.dart';
import 'package:mobizapp/Pages/Stock/StockName_RequestScreen.dart';
import 'package:mobizapp/Pages/VIsitsPage.dart';
import 'package:mobizapp/Pages/customerscreen.dart';
import 'package:mobizapp/Pages/loginpage.dart';
import 'package:mobizapp/Pages/productspage.dart';
import 'package:mobizapp/Pages/receiptscreen.dart';
import 'package:mobizapp/Pages/schedule_Driver.dart';
import 'package:mobizapp/Pages/selectProducts.dart';
import 'package:mobizapp/Pages/newvanstockrequests.dart';
import 'package:mobizapp/Pages/van_transfer.dart';
import 'package:mobizapp/Pages/vanstockdata.dart';
import 'package:mobizapp/Pages/vanstockrequest.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'package:mobizapp/Utilities/sharepref.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'package:mobizapp/confg/sizeconfig.dart';
import 'package:mobizapp/Water.dart';
import 'package:mobizapp/Models/VanStockDataModel.dart';
import 'package:mobizapp/confg/textconfig.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../Models/Store_model.dart';
import '../Models/appstate.dart';
import '../Models/userDetails.dart';
import '../selectproduct.dart';
import 'Customer Dues/Customer Dues.dart';
import 'Picking/pickingList.dart';
import 'Production/ProductionOrder.dart';
import 'Quotation/QuotationHome.dart';
import 'Stock/StockTransfer_Page.dart';
import 'TestExpensePage.dart';
import 'Cheque/Cheque_Colection.dart';
import 'Cheque_Receipt.dart';
import 'Delivery_details_driver.dart';
import 'Schedule_page.dart';
import 'TestInvoice.dart';
import 'TestReturn.dart';
import 'VanTransfer_option.dart';
import 'homeorder.dart';
import 'homereturn.dart';
import 'offLoadRequest.dart';
import 'saleinvoices.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = "/HomeScreen";
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> savedCartItems = [];
  bool _restrict = false;
  bool isLoading = true;
  String _appVersion = 'Loading...';
  var selectedDate = DateTime.now();
  List<dynamic> appIcons = [];
  List<List<dynamic>> paginatedIcons = [];
  List<dynamic> IconDatas = [];
  int completedTodaySchedule = 0;
  int totalTodaySchedule = 0;
  int completedEmergencySchedule = 0;
  int totalEmergencySchedule = 0;
  double couponSale = 0.0;
  int usedCoupons = 0;
  double expenses = 0.0;
  int filledBottle = 0;
  int emptyBottle = 0;
  double cashInHand = 0.0;
  double cashSale = 0.0;
  double creditSale = 0.0;
  double amountPending = 0.0;
  double amountCollected = 0.0;
  double totalSale = 0.0;
  StoreDetail? storeDetail;

  bool performLogout() {
    try {
      SharedPref().clear();
      AppState().loginState = "";
      return true;
    } catch (e) {
      print('Logout failed: $e');
      return false;
    }
  }

  Future<void> clearSharedPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserDetails();
      fetchStoreDetail();
      _fetchAppVersion();
      fetchDashboardData();
      fetchAppIcons();
    });
    print("Validate qty${AppState().validate_qtySales}");
    print("Validate salesoo${AppState().validate_qtySO}");
  }

  Map<String, double> dataMap = {};
  Future<void> fetchDashboardData() async {
    final String url =
        '${RestDatasource().BASE_URL}/api/second_dashbord?store_id=${AppState().storeId}&date=${DateFormat('yyyy-MM-dd').format(selectedDate)}&user_id=${AppState().userId}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print(response.request);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      if (jsonResponse['success']) {
        setState(() {
          var data = jsonResponse['data'];
          completedTodaySchedule = data['todays_schedule']['completed'] ?? 0;
          totalTodaySchedule = data['todays_schedule']['total'] ?? 0;
          completedEmergencySchedule =
              data['emergency_schedule']['completed'] ?? 0;
          totalEmergencySchedule = data['emergency_schedule']['total'] ?? 0;
          couponSale =
              (data['coupon_sale'] ?? 0).toDouble(); // Ensure it's a double
          usedCoupons = data['used_coupons'] ?? 0;
          expenses = (data['expenses'] ?? 0).toDouble(); // Ensure it's a double
          filledBottle = data['filled_bottle'] ?? 0;
          emptyBottle = data['empty_bottle'] ?? 0;
          cashInHand =
              (data['cash_in_hand'] ?? 0).toDouble(); // Ensure it's a double
          cashSale =
              (data['cash_sale'] ?? 0).toDouble(); // Ensure it's a double
          creditSale =
              (data['credit_sale'] ?? 0).toDouble(); // Ensure it's a double
          amountPending =
              (data['amount_pending'] ?? 0).toDouble(); // Ensure it's a double
          amountCollected = (data['amount_collected'] ?? 0)
              .toDouble(); // Ensure it's a double
          totalSale =
              (data['total_sale'] ?? 0).toDouble(); // Ensure it's a double
          dataMap = {
            "Amount Pending": amountPending,
            "Amount Collected": amountCollected,
            // "Total Sale": totalSale,
          };
        });
      }
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }

  Future<void> fetchStoreDetail() async {
    final url = Uri.parse(
        "${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          setState(() {
            storeDetail = StoreDetail.fromJson(jsonData);
            isLoading = false;
          });
        } else {
          print("Error: ${jsonData['messages']}");
          setState(() => isLoading = false);
        }
      } else {
        print("Failed to load data: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Exception: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchAppIcons() async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/store_app_icons?store_id=${AppState().storeId}'));

    if (response.statusCode == 200) {
      print(response.request);
      final data = json.decode(response.body);
      setState(() {
        if (data['success'] == null) {
          appIcons = [];
        } else if (data['success'] is List) {
          appIcons = data['success'];
        } else if (data['success'] is Map) {
          appIcons = (data['success'] as Map<String, dynamic>).values.toList();
        } else {
          appIcons = [];
        }
        paginatedIcons = _paginateList(appIcons, 15);
      });
    } else {
      throw Exception('Failed to load app icons');
    }
  }

  Future<void> _fetchAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  List<List<dynamic>> _paginateList(List<dynamic> list, int chunkSize) {
    List<List<dynamic>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(
        i,
        i + chunkSize > list.length ? list.length : i + chunkSize,
      ));
    }
    return chunks;
  }

  IconData? getIconData(String? iconName) {
    if (iconName == null) return null;

    switch (iconName) {
      case 'Icons.directions_bus':
        return Icons.directions_bus;
      case 'people':
        return Icons.people;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'menu_book':
        return Icons.menu_book;
      case 'water_drop':
        return Icons.water_drop;
      case 'document_scanner':
        return Icons.document_scanner;
      case 'receipt':
        return Icons.receipt;
      case 'inventory':
        return Icons.inventory;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'groups':
        return Icons.groups;
      case 'question_answer':
        return Icons.question_answer;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'handshake':
        return Icons.handshake;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'free_cancellation':
        return Icons.free_cancellation;
      case 'local_mall':
        return Icons.local_mall;
      case 'credit_card_sharp':
        return Icons.credit_card_sharp;
      case 'insert_drive_file_rounded':
        return Icons.insert_drive_file_rounded;
      case 'real_estate_agent':
        return Icons.real_estate_agent;
      case 'wallet_travel_outlined':
        return Icons.wallet_travel_outlined;
      case 'money':
        return Icons.money;
        case 'call_missed_outgoing_rounded':
        return Icons.call_missed_outgoing_rounded;
      case 'transfer_within_a_station':
        return Icons.transfer_within_a_station;
        case 'production_quantity_limits_outlined':
        return Icons.production_quantity_limits_outlined;
        case 'quora':
        return Icons.quora;
      default:
        return Icons.help;
    }
  }

  List<Color> colorList = [
    Colors.green.shade300,
    Colors.blue,
    Colors.white,
  ];

  // List<_SalesData> data = [
  //   _SalesData('Irfan', 20),
  //   _SalesData('Ahmed', 28),
  //   _SalesData('Yasir', 34),
  //   _SalesData('Rouf', 48),
  //   _SalesData('Imran', 40),
  //   _SalesData('Prabhu', 30),
  //   _SalesData('Sudeer', 20),
  //   _SalesData('Mahesh', 15),
  // ];

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat('dd-MMM-yyyy').format(DateTime.now());
    // final paginatedIcons = paginateIcons(appIcons, 15);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 40,
          centerTitle: false,
          iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
          backgroundColor: AppConfig.colorPrimary,
          titleSpacing: 0,
          title: RichText(
            text: TextSpan(
              text: 'Hello ',
              style: TextStyle(
                  color: AppConfig.backgroundColor,
                  fontSize: AppConfig.textSubtitle3Size),
              children: <TextSpan>[
                TextSpan(
                  text: '${AppState().name}',
                  style: TextStyle(
                      color: AppConfig.backgroundColor,
                      fontSize: AppConfig.textSubtitle3Size),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: InkWell(onTap: () {
                Navigator.pushNamed(context, NotificationPage.routeName);
              },child: Icon(Icons.notifications)),
            )
          ],
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
        body: Container(
          height: MediaQuery.of(context).size.height * 1,
          child: PageView(
            children: [
              Container(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CommonWidgets.verticalSpace(2),
                      isLoading
                          ? Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.blockSizeHorizontal * 3,
                                  vertical: SizeConfig.blockSizeVertical * 1),
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: SizeConfig.safeBlockHorizontal! * 30,
                                      height: SizeConfig.safeBlockVertical! * 5,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : storeDetail == null
                              ? const Center(child: Text("No data found"))
                              : Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal:
                                            SizeConfig.blockSizeHorizontal * 3,
                                        vertical:
                                            SizeConfig.blockSizeVertical * 1),
                                    child: Text(
                                      "${storeDetail!.name}",
                                      style: TextStyle(
                                          fontSize: AppConfig.textCaptionSize,
                                          fontWeight: FontWeight.w900,
                                          color: AppConfig.colorPrimary),
                                    ),
                                  ),
                                ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            // CommonWidgets.verticalSpace(2),
                            Center(
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'Assets/Images/main logo.png',
                                      fit: BoxFit.cover,
                                      width: SizeConfig.blockSizeHorizontal * 18,
                                      height: SizeConfig.blockSizeVertical * 8,
                                    ),
                                  ]),
                            ),
                            CommonWidgets.verticalSpace(3.8),
                            Container(
                              height: MediaQuery.of(context).size.height * 0.68,
                              child: paginatedIcons.isNotEmpty
                                  ? PageView.builder(
                                      itemCount: paginatedIcons.length,
                                      itemBuilder: (context, pageIndex) {
                                        final pageData =
                                            paginatedIcons[pageIndex];
                                        return SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 15),
                                            child: GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  NeverScrollableScrollPhysics(),
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 3,
                                                crossAxisSpacing: 13,
                                                childAspectRatio: .95,
                                                mainAxisSpacing: 10,
                                              ),
                                              itemCount: pageData.length,
                                              itemBuilder: (context, index) {
                                                final iconData = pageData[index];
                                                final iconList = iconData['icon']
                                                    as List<dynamic>?;
                                                final firstIconObject =
                                                    iconList != null &&
                                                            iconList.isNotEmpty
                                                        ? iconList[0]
                                                        : null;

                                                final iconName =
                                                    firstIconObject != null
                                                        ? firstIconObject['icon']
                                                            as String?
                                                        : null;
                                                final name =
                                                    firstIconObject != null
                                                        ? firstIconObject['name']
                                                            as String?
                                                        : 'Unknown';
                                                final url =
                                                    firstIconObject != null
                                                        ? firstIconObject['url']
                                                            as String?
                                                        : '';

                                                return _iconButtons(
                                                  title: name ?? 'Unknown',
                                                  routeName: url ?? '',
                                                  icon: getIconData(iconName),
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Center(
                                      child: Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.white,
                                        child: Padding(
                                          padding: const EdgeInsets.all(35.0),
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: GridView.builder(
                                                  scrollDirection: Axis.vertical,
                                                  shrinkWrap: true,
                                                  physics:
                                                      BouncingScrollPhysics(),
                                                  itemCount: 12,
                                                  gridDelegate:
                                                      SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 3,
                                                    mainAxisExtent: 120,
                                                    crossAxisSpacing: 20,
                                                    mainAxisSpacing: 30,
                                                  ),
                                                  itemBuilder: (context, index) {
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                10),
                                                        color:
                                                            Colors.grey.shade200,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
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
              ),
              Container(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: SizeConfig.safeBlockVertical! * 7,
                      ),
                      Container(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.blockSizeHorizontal * 3),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    height: SizeConfig.safeBlockVertical! * 22,
                                    width: SizeConfig.blockSizeHorizontal * 45,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: AppConfig.colorPrimary,
                                    ),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height:
                                              SizeConfig.safeBlockVertical! * 2.5,
                                        ),
                                        Text(
                                          'TODAY\'S SCHEDULE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            // fontWeight: FontWeight.w700
                                          ),
                                        ),
                                        SizedBox(
                                          height:
                                              SizeConfig.safeBlockVertical! * 2.5,
                                        ),
                                        CircularPercentIndicator(
                                          radius: 50.0,
                                          lineWidth: 10.0,
                                          percent: completedTodaySchedule /
                                              totalTodaySchedule,
                                          center: Text(
                                            "$completedTodaySchedule/$totalTodaySchedule", // Text inside the circle
                                            style: TextStyle(
                                                fontSize:
                                                    AppConfig.textSubtitle3Size,
                                                color: Colors.white),
                                          ),
                                          progressColor: Colors
                                              .green, // Color of the progress line
                                          backgroundColor: Colors
                                              .blueAccent, // Background color of the circle
                                          circularStrokeCap: CircularStrokeCap
                                              .round, // Rounded edges of the stroke
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: SizeConfig.safeBlockVertical! * 22,
                                    width: SizeConfig.blockSizeHorizontal * 45,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: AppConfig.colorPrimary,
                                    ),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height:
                                              SizeConfig.safeBlockVertical! * 2.5,
                                        ),
                                        Text(
                                          'EMERGENCY SCHEDULE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            // fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(
                                          height:
                                              SizeConfig.safeBlockVertical! * 2.5,
                                        ),
                                        CircularPercentIndicator(
                                          radius: 50.0, // Size of the circle
                                          lineWidth:
                                              10.0, // Width of the circle's stroke
                                          percent: completedEmergencySchedule /
                                              totalEmergencySchedule, // Progress percentage (2 out of 70)
                                          center: Text(
                                            "$completedEmergencySchedule/$totalEmergencySchedule", // Text inside the circle
                                            style: TextStyle(
                                                fontSize:
                                                    AppConfig.textSubtitle3Size,
                                                color: Colors.white),
                                          ),
                                          progressColor: Colors
                                              .green, // Color of the progress line
                                          backgroundColor: Colors
                                              .blueAccent, // Background color of the circle
                                          circularStrokeCap: CircularStrokeCap
                                              .round, // Rounded edges of the stroke
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: SizeConfig.safeBlockVertical! * 3,
                              ),
                              Row(
                                children: [
                                  Container(
                                    height: SizeConfig.safeBlockVertical! * 7,
                                    width:
                                        SizeConfig.safeBlockHorizontal! * 30.52,
                                    decoration: BoxDecoration(
                                        color: AppConfig.colorPrimary,
                                        borderRadius: BorderRadius.circular(5)),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 7,
                                        ),
                                        Text(
                                          'COUPON SALE',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize:
                                                  AppConfig.textCaption3Size),
                                        ),
                                        Text(
                                          couponSale.toStringAsFixed(
                                              2), // Converts double to a string with 2 decimal places
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: AppConfig.textCaption2Size,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Container(
                                    height: SizeConfig.safeBlockVertical! * 7,
                                    width:
                                        SizeConfig.safeBlockHorizontal! * 30.52,
                                    decoration: BoxDecoration(
                                        color: AppConfig.colorPrimary,
                                        borderRadius: BorderRadius.circular(5)),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 7,
                                        ),
                                        Text(
                                          'USED COUPONS',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize:
                                                  AppConfig.textCaption3Size),
                                        ),
                                        Text(
                                          usedCoupons
                                              .toString(), // Converts double to a string with 2 decimal places
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: AppConfig.textCaption2Size,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Container(
                                    height: SizeConfig.safeBlockVertical! * 7,
                                    width:
                                        SizeConfig.safeBlockHorizontal! * 30.52,
                                    decoration: BoxDecoration(
                                        color: AppConfig.colorPrimary,
                                        borderRadius: BorderRadius.circular(5)),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 7,
                                        ),
                                        Text(
                                          'EXPENSES',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize:
                                                  AppConfig.textCaption3Size),
                                        ),
                                        Text(expenses.toStringAsFixed(2),
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize:
                                                    AppConfig.textCaption2Size))
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                  height: SizeConfig.safeBlockVertical! * 1.5),
                              Row(
                                children: [
                                  Container(
                                    height: SizeConfig.safeBlockVertical! * 7,
                                    width:
                                        SizeConfig.safeBlockHorizontal! * 30.52,
                                    decoration: BoxDecoration(
                                        color: AppConfig.colorPrimary,
                                        borderRadius: BorderRadius.circular(5)),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 7,
                                        ),
                                        Text(
                                          'FILLED BOTTLE',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize:
                                                  AppConfig.textCaption3Size),
                                        ),
                                        Text(filledBottle.toString(),
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize:
                                                    AppConfig.textCaption2Size))
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Container(
                                    height: SizeConfig.safeBlockVertical! * 7,
                                    width:
                                        SizeConfig.safeBlockHorizontal! * 30.52,
                                    decoration: BoxDecoration(
                                        color: AppConfig.colorPrimary,
                                        borderRadius: BorderRadius.circular(5)),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 7,
                                        ),
                                        Text(
                                          'EMPTY BOTTLE',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize:
                                                  AppConfig.textCaption3Size),
                                        ),
                                        Text(emptyBottle.toString(),
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize:
                                                    AppConfig.textCaption2Size))
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Container(
                                    height: SizeConfig.safeBlockVertical! * 7,
                                    width:
                                        SizeConfig.safeBlockHorizontal! * 30.52,
                                    decoration: BoxDecoration(
                                        color: AppConfig.colorPrimary,
                                        borderRadius: BorderRadius.circular(5)),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 7,
                                        ),
                                        Text(
                                          'CASH IN HAND',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize:
                                                  AppConfig.textCaption3Size),
                                        ),
                                        Text(cashInHand.toStringAsFixed(2),
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize:
                                                    AppConfig.textCaption2Size))
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: SizeConfig.safeBlockVertical! * 3,
                              ),
                              Container(
                                height: SizeConfig.safeBlockVertical! * 37,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: AppConfig.colorPrimary,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: SizeConfig
                                                        .safeBlockVertical! *
                                                    2,
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: SizeConfig
                                                            .blockSizeHorizontal! *
                                                        8,
                                                    vertical: SizeConfig
                                                            .blockSizeVertical! *
                                                        1.2),
                                                decoration: BoxDecoration(
                                                  color: Colors.indigo.shade300,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'CASH SALES', // Show the current date
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 15,
                                              ),
                                              dataMap.isEmpty
                                                  ? const Center(child: CircularProgressIndicator())
                                              :Container(
                                                height: SizeConfig
                                                        .safeBlockVertical! *
                                                    24,
                                                width: SizeConfig
                                                        .safeBlockHorizontal! *
                                                    50,
                                                child: PieChart(
                                                  dataMap: dataMap,
                                                  colorList: colorList,
                                                  chartRadius:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          .5,
                                                  centerText: "",
                                                  chartValuesOptions:
                                                      ChartValuesOptions(
                                                    showChartValues: true,
                                                    showChartValuesInPercentage:
                                                        false,
                                                    showChartValuesOutside: false,
                                                    chartValueStyle: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  ringStrokeWidth: 30,
                                                  legendOptions: LegendOptions(
                                                      showLegends: false),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // SizedBox(height: 10,),
                                            Text(
                                              'CREDIT SALES',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.w900),
                                            ),
                                            SizedBox(
                                              height: 110,
                                            ),
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius:
                                                      10, // Size of the circle
                                                  backgroundColor: Colors
                                                      .greenAccent, // Green color for "Amount Pending"
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  'AMOUNT PENDING',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                                height: 15), // Space between rows

                                            // Amount Collected
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius:
                                                      10, // Size of the circle
                                                  backgroundColor: Colors
                                                      .blue, // Blue color for "Amount Collected"
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  'AMOUNT COLLECTED',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                                height: 15), // Space between rows

                                            // Total Sales
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius:
                                                      10, // Size of the circle
                                                  backgroundColor: Colors
                                                      .white, // White color for "Total Sales"
                                                ),
                                                SizedBox(width: 10),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Total Sales: ',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12),
                                                    ),
                                                    Text(
                                                      totalSale
                                                          .toStringAsFixed(2),
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    )
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButtons({
    IconData? icon,
    required String title,
    String? image,
    String? routeName,
  }) {
    return GestureDetector(
      onTap: () {
        if (routeName != null) {
          switch (routeName) {
            case 'VanStockScreen':
              if (_restrict) {
                CommonWidgets.showDialogueBox(
                    context: context,
                    title: "Alert",
                    msg: "Van not allocated to this user");
              } else {
                Navigator.pushNamed(context, VanStockScreen.routeName);
              }
              break;
            case 'CustomersDataScreen':
              if (_restrict) {
                CommonWidgets.showDialogueBox(
                    context: context,
                    title: "Alert",
                    msg: "Van not allocated to this user");
              } else {
                Navigator.pushNamed(context, CustomersDataScreen.routeName);
              }
              break;
            case 'ProductsScreen':
              if (_restrict) {
                CommonWidgets.showDialogueBox(
                    context: context,
                    title: "Alert",
                    msg: "Van not allocated to this user");
              } else {
                Navigator.pushNamed(context, ProductsScreen.routeName);
              }
              break;
            case 'Expensespage':
              Navigator.pushNamed(context, Expensespage.routeName);
              break;
            case 'HomeWater':
              Navigator.pushNamed(context, HomeWater.routeName);
              break;
            case 'SaleInvoiceScrreen':
              Navigator.pushNamed(context, SaleInvoiceScrreen.routeName);
              break;
            case 'ReceiptScreen':
              Navigator.pushNamed(context, ReceiptScreen.receiptScreen);
              break;
            case 'HomereturnScreen':
              Navigator.pushNamed(context, HomereturnScreen.routeName);
              break;
            case 'SchedulePage':
              Navigator.pushNamed(context, SchedulePage.routeName);
              // Navigator.pushNamed(context, Productionorder.routeName);
              break;
            case 'ScheduleDriver':
              Navigator.pushNamed(context, ScheduleDriver.routeName);
              break;
            case 'Attendance':
              Navigator.pushNamed(context, Attendance.routeName);
              break;
            case 'VanStockRequestsScreen':
              Navigator.pushNamed(context, VanStockRequestsScreen.routeName);
              break;
            case 'OffLoadRequestScreen':
              Navigator.pushNamed(context, OffLoadRequestScreen.routeName);
              break;
            case 'Visitspage':
              Navigator.pushNamed(context, Visitspage.routeName);
              break;
            case 'VantransferOption':
              Navigator.pushNamed(context, VantransferOption.routeName);
              break;
            case 'Dayclose':
              Navigator.pushNamed(context, Dayclose.routeName);
              break;
            case 'HomeorderScreen':
              Navigator.pushNamed(context, HomeorderScreen.routeName);
              break;
              case 'QuotationHome':
              Navigator.pushNamed(context, QuotationHome.routeName);
              break;
            case 'StockName_RequestScreen':
              Navigator.pushNamed(context, StockName_RequestScreen.routeName);
              break;
            case 'StockTransferPage':
              Navigator.pushNamed(context, StockTransferPage.routeName);
              break;
            case 'ChequeReceipt':
              Navigator.pushNamed(context, ChequeReceipt.routeName);
              break;
            case 'DeliveryDetailsDriver':
              Navigator.pushNamed(context, DeliveryDetailsDriver.routeName);
              break;
            case 'Aging':
              Navigator.pushNamed(context, AgeingSummaryScreen.routeName);
              break;
            case 'PDC':
              Navigator.pushNamed(context, BankReconciliationScreen.routeName);
              break;
              case 'PickingListPage':
              Navigator.pushNamed(context, PickingListPage.routeName);
              break;
            case 'DUE':
              Navigator.pushNamed(context, CustomerDues.routeName);
              break;
            case 'Productionorder':
              Navigator.pushNamed(context, Productionorder.routeName);
              break;
            default:
              Navigator.pushNamed(context, routeName);
          }
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: AppConfig.backgroundColor,
                size: 40,
              )
            else if (image != null)
              Image.asset(
                image,
                width: 50,
                height: 40,
                fit: BoxFit.contain,
              ),
            SizedBox(
              width: SizeConfig.blockSizeHorizontal * 18,
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppConfig.backgroundColor,
                    fontSize: AppConfig.textCaption3Size,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _getUserDetails() async {
    RestDatasource api = RestDatasource();
    UserDetailsModel userData = UserDetailsModel();
    String subUrl = "/api/get_user_detail?user_id=${AppState().userId}";
    dynamic resJson = await api.getDetails(subUrl, AppState().token);
    if (resJson['data'] != null) {
      userData = UserDetailsModel.fromJson(resJson);
      AppState().vanId = userData.data![0].vanId;
      AppState().routeId = userData.data![0].routeId;
      // print('userData.data![0].vanId');
      // print(userData.data![0].vanId);
    } else {
      if (mounted) {
        _restrict = true;
        CommonWidgets.showDialogueBox(
            context: context,
            title: "Alert",
            msg: "Van not allocated to this user");
      }
    }
  }
  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit App'),
        content: Text('Are you sure you want to exit the app?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('NO'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('YES'),
          ),
        ],
      ),
    )) ??
        false;
  }
}

class _SalesData {
  _SalesData(this.year, this.sales);

  final String year;
  final double sales;
}
