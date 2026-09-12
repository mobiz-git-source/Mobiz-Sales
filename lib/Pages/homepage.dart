import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // ── NEW: palette used only for the redesigned UI. Data/API logic below is untouched. ──
  static const Color _screenBg = Color(0xFFF5F6FA);
  static const Color _darkText = Color(0xFF1F1147);
  static const Color _brandColor = AppConfig.colorPrimary;
  // NEW: lets us open the drawer via the custom menu icon now that there's
  // no AppBar auto-generating one.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
  // NEW: unread notification count for the bell badge. No API field for this
  // exists yet in the code you shared, so it defaults to 0 (badge hidden).
  // Wire this to the real unread-count from your notifications API when ready.
  int notificationCount = 0;
  int visit = 0;
  int orders = 0;
  int invoice = 0;
  double collection = 0.0;
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
    print("DASHBOARD API URL: $url");
    try {
      final response = await http.get(Uri.parse(url));
      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            var data = jsonResponse['data'];

            print("Full Dashboard Response: $data");
            print("Cash Sale: ${data['cash_sale']}");
            print("Credit Sale: ${data['credit_sale']}");
            print("Total Sale: ${data['total_sale']}");

            double safeDouble(dynamic val) {
              if (val == null) return 0.0;
              if (val is num) return val.toDouble();
              if (val is String) return double.tryParse(val) ?? 0.0;
              return 0.0;
            }

            int safeInt(dynamic val) {
              if (val == null) return 0;
              if (val is int) return val;
              if (val is String) return int.tryParse(val) ?? 0;
              return (val as num).toInt();
            }

            completedTodaySchedule =
                safeInt(data['todays_schedule']?['completed']);
            totalTodaySchedule = safeInt(data['todays_schedule']?['total']);
            completedEmergencySchedule =
                safeInt(data['emergency_schedule']?['completed']);
            totalEmergencySchedule =
                safeInt(data['emergency_schedule']?['total']);

            couponSale = safeDouble(data['coupon_sale']);
            usedCoupons = safeInt(data['used_coupons']);
            expenses = safeDouble(data['expenses']);
            filledBottle = safeInt(data['filled_bottle']);
            emptyBottle = safeInt(data['empty_bottle']);

            cashInHand = safeDouble(data['cash_in_hand']);
            print("cash_in_hand from API : ${data['cash_in_hand']}");
            cashSale = safeDouble(data['cash_sale']);
            creditSale = safeDouble(data['credit_sale']);
            amountPending = safeDouble(data['amount_pending']);
            amountCollected = safeDouble(data['amount_collected']);
            totalSale = safeDouble(data['total_sale']);
            visit = safeInt(data['visit']);
            orders = safeInt(data['orders']);
            invoice = safeInt(data['invoice']);
            collection = safeDouble(data['collection']);
            print(
                "VISIT: $visit | ORDERS: $orders | INVOICE: $invoice | COLLECTION: $collection");
            dataMap = {
              "Amount Pending": amountPending,
              "Amount Collected": amountCollected,
            };
          });
        }
      }
    } catch (e) {
      print("DASHBOARD EXCEPTION: $e");
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
          final detail = StoreDetail.fromJson(jsonData);

          print("VAT LABEL FROM API: ${detail.vatLabel}");

          AppState().vatLabel = detail.vatLabel ?? "VAT";

          final prefs = await SharedPreferences.getInstance();

          await prefs.setString(
            "vat_label",
            detail.vatLabel ?? "VAT",
          );

          print("Saved VAT LABEL: ${prefs.getString("vat_label")}");

          setState(() {
            storeDetail = detail;
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
        paginatedIcons = _paginateList(appIcons, 16);
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

 @override
Widget build(BuildContext context) {
  final bool isTablet =
      MediaQuery.of(context).size.shortestSide >= 600;

  String currentDate =
      DateFormat('dd-MMM-yyyy').format(DateTime.now());

  return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          // ── NEW: no separate AppBar — the menu/title/bell now live inside
          // the gradient header itself (see _buildDashboardHeader). ──
          key: _scaffoldKey,
          backgroundColor: _screenBg,
          drawer: SizedBox(
            width: SizeConfig.blockSizeHorizontal * 50,
            child: Drawer(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  children: [
                    CommonWidgets.verticalSpace(8),
                    // NEW: plain brand-color avatar — animation removed
                    const CircleAvatar(
                      radius: 45.0,
                      backgroundColor: _brandColor,
                      child: Icon(Icons.person, color: Colors.white, size: 46),
                    ),
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
   body: Column(
  children: [
    isLoading
        ? const SizedBox.shrink()
        : storeDetail == null
            ? const Center(
                child: Text("No data found"),
              )
            : _buildDashboardHeader(),

 Expanded(
  child: Padding(
    padding: EdgeInsets.fromLTRB(
      14,
      0,
      14,
      isTablet ? 10 : 18,
    ),
    child: appIcons.isNotEmpty
        ? PageView.builder(
            itemCount: paginatedIcons.length,
            itemBuilder: (context, pageIndex) {
              final pageData = paginatedIcons[pageIndex];

              return GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 10),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,

                  // Phone = old layout
                  // Tablet = slightly smaller rows so all 16 can fit,
                  // and the page can still scroll if needed.
                  mainAxisSpacing: isTablet ? 8 : 14,

                 childAspectRatio: isTablet ? 1.45 : 0.8,
                ),
                itemCount: pageData.length,
                itemBuilder: (context, index) {
                  final iconData = pageData[index];

                  final iconList =
                      iconData['icon'] as List<dynamic>?;

                  final firstIconObject =
                      iconList != null && iconList.isNotEmpty
                          ? iconList[0]
                          : null;

                  final iconName =
                      firstIconObject?['icon'] as String?;

                  final name =
                      firstIconObject?['name'] as String?;

                  final url =
                      firstIconObject?['url'] as String?;

                  return _iconButtons(
                    title: name ?? 'Unknown',
                    routeName: url ?? '',
                    icon: getIconData(iconName),
                  );
                },
              );
            },
          )
        : const SizedBox.shrink(),
  ),
),
  ],
),
        ),
      ),
    );
  }

  // ── NEW: gradient header (menu / title / bell built in) + single merged white card ──
  Widget _buildDashboardHeader() {
    return Column(children: [
      Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 8,
          20,
          40,
        ),
        decoration: BoxDecoration(
          // NEW: brand-color base + background image with a dark
          // overlay so the white text/icons stay readable
          color: _brandColor,
          image: DecorationImage(
            image: const AssetImage('Assets/Images/dashboard_bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              _brandColor.withOpacity(0.55),
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: const Icon(Icons.menu, color: Colors.white, size: 26),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final companyName = storeDetail?.name ?? 'Mobiz';

                        double titleSize;

                        if (companyName.length <= 20) {
                          titleSize = 24;
                        } else if (companyName.length <= 35) {
                          titleSize = 21;
                        } else if (companyName.length <= 50) {
                          titleSize = 18;
                        } else {
                          titleSize = 16;
                        }

                        return Text(
                          companyName,
                          maxLines: 3,
                          softWrap: true,
                          textAlign: TextAlign.left,
                          style: AppConfig.pageTitleStyle.copyWith(
                            color: Colors.white,
                            fontSize: titleSize,
                            height: 1.15,
                            fontWeight: FontWeight.w400,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, NotificationPage.routeName);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications,
                          color: Colors.white, size: 24),
                      if (notificationCount > 0)
                        Positioned(
                          right: -4,
                          top: -3,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(
                                minWidth: 15, minHeight: 15),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              notificationCount > 9
                                  ? '9+'
                                  : '$notificationCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Hello, ${AppState().name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      // NEW: single merged white card — summary tiles on top, a divider,
      // then the Visits/Orders/Invoices/Collections stat row underneath.
      Transform.translate(
        offset: const Offset(0, -30),
        child: Column(
          children: [
            /// ================= TOP ROW =================
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.blockSizeHorizontal * 3,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _summaryTile(
                          icon: Icons.show_chart_rounded,
                          label: "Today's Sales",
                          amount: totalSale.toStringAsFixed(
                            AppState().noOfDecimals ?? 2,
                          ),
                        ),
                      ),
                      const VerticalDivider(
                        width: 20,
                        thickness: 1,
                        color: Color(0xFFE8E8E8),
                      ),
                      Expanded(
                        child: _summaryTile(
                          icon: Icons.account_balance_wallet_rounded,
                          label: "Cash in Hand",
                          amount: cashInHand.toStringAsFixed(
                            AppState().noOfDecimals ?? 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            /// ================= BOTTOM CARD =================
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: SizeConfig.blockSizeHorizontal * 3,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10, // ← 18-il ninnu 10-akki kurachu
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _statItem(
                        icon: Icons.location_on,
                        label: "Visits",
                        value: "$visit",
                      ),
                    ),
                    const VerticalDivider(
                      thickness: .8,
                      width: 1,
                      color: Color(0xFFE8E8E8),
                    ),
                    Expanded(
                      child: _statItem(
                        icon: Icons.shopping_cart,
                        label: "Orders",
                        value: "$orders",
                      ),
                    ),
                    const VerticalDivider(
                      thickness: .8,
                      width: 1,
                      color: Color(0xFFE8E8E8),
                    ),
                    Expanded(
                      child: _statItem(
                        icon: Icons.receipt_long,
                        label: "Invoices",
                        value: "$invoice",
                      ),
                    ),
                    const VerticalDivider(
                      thickness: .8,
                      width: 1,
                      color: Color(0xFFE8E8E8),
                    ),
                    Expanded(
                      child: _statItem(
                        icon: Icons.account_balance_wallet,
                        label: "Collections",
                        value: collection.toStringAsFixed(
                          AppState().noOfDecimals ?? 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
    ]);
  }

  // ── NEW: top-icon stat item used in the Visits/Orders/Invoices/Collections
  // strip — plain brand-colored icon, no badge (matches the reference).
  // Optional `prefix` (e.g. "AED") renders smaller/lighter in front of value. ──
  Widget _statItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 26, color: _brandColor),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 13, // ✅ uniform size
              fontWeight: FontWeight.w700,
              color: _darkText,
            ),
          ),
        ),
      ],
    );
  }

  // NEW: `amount` is the plain number (e.g. "3,922.00") — "AED" is rendered
  // smaller/lighter in front of it so the value never gets cramped or
  // truncated inside the card.
 Widget _summaryTile({
  required IconData icon,
  required String label,
  required String amount,
}) {
  return Row(                               // ✅ Expanded ഒഴിവാക്കി, Row മാത്രം
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _brandColor,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label (AED)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                maxLines: 1,
                style: const TextStyle(
                  color: _darkText,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );                                        // ✅ Row-ന്റെ closing bracket മാത്രം
}

  // ── NEW: light rounded card with a soft-purple circular icon, same tap logic as before ──
  Widget _iconButtons({
    IconData? icon,
    required String title,
    String? image,
    String? routeName,
  }) {
    void navigateAndRefresh(String route) {
      Navigator.pushNamed(context, route).then((_) {
        fetchDashboardData();
      });
    }

    return GestureDetector(
      onTap: () {
        if (routeName != null) {
          switch (routeName) {
            case 'Expensespage':
              navigateAndRefresh(Expensespage.routeName);
              break;
            case 'SaleInvoiceScrreen':
              navigateAndRefresh(SaleInvoiceScrreen.routeName);
              break;
            case 'ReceiptScreen':
              navigateAndRefresh(ReceiptScreen.receiptScreen);
              break;
            case 'HomereturnScreen':
              navigateAndRefresh(HomereturnScreen.routeName);
              break;
            case 'Dayclose':
              navigateAndRefresh(Dayclose.routeName);
              break;
            case 'PDC':
              navigateAndRefresh(BankReconciliationScreen.routeName);
              break;
            case 'ChequeReceipt':
              navigateAndRefresh(ChequeReceipt.routeName);
              break;
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
            case 'HomeWater':
              Navigator.pushNamed(context, HomeWater.routeName);
              break;
            case 'SchedulePage':
              Navigator.pushNamed(context, SchedulePage.routeName);
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
            case 'DeliveryDetailsDriver':
              Navigator.pushNamed(context, DeliveryDetailsDriver.routeName);
              break;
            case 'Aging':
              Navigator.pushNamed(context, AgeingSummaryScreen.routeName);
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // NEW: rounded-square gradient badge instead of the plain
            // light-purple circle — bolder, more colorful icon container.
            SizedBox(
              width: 44,
              height: 44,
              child: icon != null
                  ? Icon(icon, color: _brandColor, size: 30)
                  : (image != null
                      ? Image.asset(image,
                          width: 26,
                          height: 26,
                          fit: BoxFit.contain,
                          color: _brandColor)
                      : const SizedBox.shrink()),
            ),
            const SizedBox(height: 7),
            SizedBox(
              width: SizeConfig.blockSizeHorizontal * 20,
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.w500,
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
                color: _brandColor),
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
