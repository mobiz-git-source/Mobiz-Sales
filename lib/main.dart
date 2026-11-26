import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobizapp/InvoiceApproval/push_router.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/Attendance.dart';
import 'package:mobizapp/Pages/CustomerStock.dart';
import 'package:mobizapp/Pages/CustomerVisit.dart';
import 'package:mobizapp/Pages/DayClose.dart';
import 'package:mobizapp/Pages/VIsitsPage.dart';
import 'package:mobizapp/Pages/customerdetailscreen.dart';
import 'package:mobizapp/Pages/customerregistration.dart';
import 'package:mobizapp/Pages/customerscreen.dart';
import 'package:mobizapp/Pages/homepage.dart';
import 'package:mobizapp/Pages/loginpage.dart';
import 'package:mobizapp/Pages/offLoadRequest.dart';
import 'package:mobizapp/Pages/paymentcollection.dart';
import 'package:mobizapp/Pages/productspage.dart';
import 'package:mobizapp/Pages/receiptscreen.dart';
import 'package:mobizapp/Pages/salesscreen.dart';
import 'package:mobizapp/Pages/selectProducts.dart';
import 'package:mobizapp/Pages/splashscreen.dart';
import 'package:mobizapp/Pages/newvanstockrequests.dart';
import 'package:mobizapp/Pages/vanselectproduct.dart';
import 'package:mobizapp/Pages/vanstockdata.dart';
import 'package:mobizapp/Pages/vanstockrequest.dart';
import 'package:mobizapp/Utilities/app_info.dart';
import 'package:mobizapp/Water.dart';
import 'package:mobizapp/Pages/TestExpensePage.dart';
import 'package:mobizapp/DashBoardScreen.dart';
import 'package:mobizapp/tsts.dart';
import 'package:mobizapp/vanstocktst.dart';
import 'package:mobizapp/vanstockselactpro_tst.dart';
import 'Pages/AgeingSummary/AgeingSummaryScreen.dart';
import 'Pages/BankReconciliation/BankReconciliationScreen.dart';
import 'Pages/Cheque/Cheque_Colection.dart';
import 'Pages/Cheque_Receipt.dart';
import 'Pages/Copy/Copy.dart';
import 'Pages/Copy/CopySelectProducts.dart';
import 'Pages/CustomeSOA.dart';
import 'Pages/Customer Dues/Customer Dues.dart';
import 'Pages/CustomerWater.dart';
import 'Pages/DayReport.dart';
import 'Pages/Day_closeReport.dart';
import 'Pages/DriverDetailsPage.dart';
import 'Pages/DriverPage.dart';
import 'Pages/Driver_customer_detail_screen.dart';
import 'Pages/Driver_paymentCollection.dart';
import 'Pages/Expense_add.dart';
import 'Pages/Delivery_details_driver.dart';
import 'Pages/Group_Print.dart';
import 'Pages/All Due/OverdueCustomerPage.dart';
import 'Pages/Notifications/notifications.dart';
import 'Pages/Picking/AddPicking.dart';
import 'Pages/Picking/pickingList.dart';
import 'Pages/Production/ProductionOrder.dart';
import 'Pages/WarehouseStockTake/warehouse_stock_take_list.dart'; // NEW
import 'Pages/Quotation/QuotatioCustomerScreen.dart';
import 'Pages/Quotation/QuotationHome.dart';
import 'Pages/Quotation/QuotationProduct.dart';
import 'Pages/SaleInvoiceSearchPage.dart';
import 'Pages/Schedule_page.dart';
import 'Pages/Stock/StockName_RequestScreen.dart';
import 'Pages/Stock/StockTransfer_Page.dart';
import 'Pages/Stock/Stock_Name.dart';
import 'Pages/Stock/Stock_SelectProducts.dart';
import 'Pages/Stock/Stock_Transfer.dart';
import 'Pages/TestInvoice.dart';
import 'Pages/TestReturn.dart';
import 'Pages/Total_sales.dart';
import 'Pages/VanTransferReceive.dart';
import 'Pages/VanTransferSend.dart';
import 'Pages/VanTransfer_option.dart';
import 'Pages/VanTransfetConfirm.dart';
import 'Pages/customerorderdetail.dart';
import 'Pages/customerreturndetails.dart';
import 'Pages/driver_customer_screen.dart';
import 'Pages/error_handling_screen.dart';
import 'Pages/homeorder.dart';
import 'Pages/homepage_Driver.dart';
import 'Pages/salesselectproductorder.dart';
import 'Pages/salesselectproductreturn.dart';
import 'Pages/salesselectproducts.dart';
import 'Pages/schedule_Driver.dart';
import 'Pages/store/StorePage.dart';
import 'Pages/van_transfer.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Utilities/auth_client.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  importance: Importance.max,
);

const AndroidNotificationChannel approvalsChannel = AndroidNotificationChannel(
  'approvals',
  'Invoice Approvals',
  description: 'Invoice approval requests and results',
  importance: Importance.high,
);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Background message: ${message.notification?.title}");
}

Future<String> getDeviceId() async {
  final info = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final android = await info.androidInfo;
    return android.id ?? "UNKNOWN";
  }
  if (Platform.isIOS) {
    final ios = await info.iosInfo;
    return ios.identifierForVendor ?? "UNKNOWN";
  }
  return "UNKNOWN";
}

Future<void> sendTokenToBackend(String token) async {
  if (AppState().userId == null) return; 
  final deviceId = await getDeviceId();

  const url = "http://68.183.92.8:3699/api/update-fcm-token";
  final body = {
    "user_id": AppState().userId,
    "fcm_token": token,
    "device_id": deviceId,
  };

  try {
    final res = await http.post(
      Uri.parse(url),
         headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );
    print("✔ Token sent: $body");
    print("🌐 Backend Response: ${res.body}");
  } catch (e) {
    print("❌ Token Send Error: $e");
  }
}
Future<void> _setupFcm() async {
  try {
    if (Platform.isIOS) {
      // APNs token varan kurachu neram edukkum
      String? apns;
      for (var i = 0; i < 10 && apns == null; i++) {
        apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns == null) await Future.delayed(const Duration(seconds: 1));
      }
    }
    final token = await FirebaseMessaging.instance.getToken();
    print("📌 FCM Token: $token");
    if (token != null) sendTokenToBackend(token);

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("♻ Token refreshed: $newToken");
      sendTokenToBackend(newToken);
    });
  } catch (e) {
    print("❌ FCM setup error: $e");
  }
}
void main() {
  http.runWithClient(_appMain, () => AuthClient());
}

Future<void> _appMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Platform.isIOS) {
      await Firebase.initializeApp(); // GoogleService-Info.plist use cheyyum
    } else {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "AIzaSyCdNIIk0gxNgYTbDUWGHKNa4T1nA9vhrXM",
          appId: "1:662520788670:android:968ca037f5ddbe336b50ef",
          messagingSenderId: "662520788670",
          projectId: "mobiz-sales-b54ca",
        ),
      );
    }
    print("🔥 Firebase initialized");
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print("❌ Firebase init error: $e");
  }

  try {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
     await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        PushRouter.onLocalTap(resp.payload);
      },
    );
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(approvalsChannel);
  } catch (e) {
    print("❌ Local notification init error: $e");
  }

   try {
    await AppInfo.init();
  } catch (e) {
    print("❌ AppInfo init error: $e");
  }
  print("Code: ${AppState().minor}");

  await TokenStore.load();

  AuthClient.onSessionExpired = () {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (route) => false,
    );
  };

    _setupFcm();
  runApp(MyApp());
}

Future<void> requestNotificationPermission() async {
  NotificationSettings settings =
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("🔔 Notification permission granted");
  } else if (settings.authorizationStatus ==
      AuthorizationStatus.denied) {
    print("❌ Notification permission denied");
  }
}



class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground: ${message.notification?.title}");
      PushRouter.onForeground(); // badge/list refresh

      final isInvoice =
          '${message.data['type'] ?? ''}'.startsWith('invoice_');
      final ch = isInvoice ? approvalsChannel : channel;

      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title ?? "No Title",
        message.notification?.body ?? "No Message",
        NotificationDetails(
          android: AndroidNotificationDetails(
            ch.id,
            ch.name,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(PushRouter.payloadOf(message)),
      );
    });

   
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      PushRouter.onTap(PushRouter.payloadOf(message));
    });

   
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        PushRouter.onTap(PushRouter.payloadOf(message), coldStart: true);
      }
    });

    // When app is opened by tapping notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("📬 Notification clicked!");
    });
  }

  @override
  Widget build(BuildContext context) {
       return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
                builder: (context, child) => MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
      builder: (context, widget) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: mq.textScaler.clamp(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.15,
                ),
              ),
              child: widget!,
            );
          },
          initialRoute: SplashScreen.routeName,
          routes: {
            // '/': (context) => Home(),
            LoginScreen.routeName: (context) => const LoginScreen(),
            Driver_PaymentCollectionScreen.routeName: (context) =>
                Driver_PaymentCollectionScreen(),
            TotalSales.routeName: (context) => const TotalSales(),
            VantransferOption.routeName: (context) => const VantransferOption(),
            driver_customer_screen.routeName: (context) =>
                const driver_customer_screen(),
            HomeScreen.routeName: (context) => const HomeScreen(),
            DeliveryDetailsDriver.routeName: (context) =>
                const DeliveryDetailsDriver(),
            Driver_customer_detail_screen.routeName: (context) =>
                const Driver_customer_detail_screen(),
            HomepageDriver.routeName: (context) => const HomepageDriver(),
            ProductsScreen.routeName: (context) => ProductsScreen(),
            ErrorHandlingScreen.routeName: (context) =>
                const ErrorHandlingScreen(),
            VanStockRequestsScreen.routeName: (context) =>
                const VanStockRequestsScreen(),
            VanStocks.routeName: (context) => VanStocks(),
            SplashScreen.routeName: (context) => const SplashScreen(),
            SelectProductsScreen.routeName: (context) => SelectProductsScreen(),
            CustomersDataScreen.routeName: (context) =>
                const CustomersDataScreen(),
            SalesScreen.routeName: (context) => SalesScreen(),
            VanStockScreen.routeName: (context) => VanStockScreen(),
            SchedulePage.routeName: (context) => const SchedulePage(),
            CustomerDetailsScreen.routeName: (context) =>
                const CustomerDetailsScreen(),
            SalesSelectProductsScreen.routeName: (context) =>
                SalesSelectProductsScreen(),
            SaleInvoiceScrreen.routeName: (context) =>
                const SaleInvoiceScrreen(),
            DaycloseReport.routeName: (context) => const DaycloseReport(),
            SalesSelectProductsorderScreen.routeName: (context) =>
                SalesSelectProductsorderScreen(),
            Salesselectproductreturn.routeName: (context) =>
                Salesselectproductreturn(),
            PaymentCollectionScreen.routeName: (context) =>
                PaymentCollectionScreen(),
            CustomerRegistration.routeName: (context) =>
                const CustomerRegistration(),
            ReceiptScreen.receiptScreen: (context) => const ReceiptScreen(),
            HomeorderScreen.routeName: (context) => HomeorderScreen(),
            VanTransfer.routeName: (context) => VanTransfer(),
            HomereturnScreen.routeName: (context) => HomereturnScreen(),
            Customerorderdetail.routeName: (context) => Customerorderdetail(),
            Customerreturndetail.routeName: (context) => Customerreturndetail(),
            Visitspage.routeName: (context) => Visitspage(),
            Expensespage.routeName: (context) => Expensespage(),
            Dayclose.routeName: (context) => Dayclose(),
            Attendance.routeName: (context) => Attendance(),
            SOA.routeName: (context) => SOA(),
            CustomerVisit.routeName: (context) => CustomerVisit(),
            ExpenseAdd.routeName: (context) => ExpenseAdd(),
            OffLoadRequestScreen.routeName: (context) => OffLoadRequestScreen(),
            VanStocksoff.routeName: (context) => VanStocksoff(),
            SelectProductsScreenoff.routeName: (context) => SelectProductsScreenoff(),
            HomeWater.routeName: (context) => HomeWater(),
            CustomerStock.routeName: (context) => CustomerStock(),
            DayReport.routeName: (context) => DayReport(),
            Vanselectproducts.routeName: (context) => Vanselectproducts(),
            VanTransferSend.routeName: (context) => VanTransferSend(),
            VanTransferConfirm.routeName: (context) => VanTransferConfirm(),
            VanStockReceive.routeName: (context) => VanStockReceive(),
            ScheduleDriver.routeName: (context) => ScheduleDriver(),
            DriverPage.routeName: (context) => DriverPage(),
            DriverDetails.routeName: (context) => DriverDetails(),
            CopyScreen.routeName: (context) => CopyScreen(),
            CopySelectProduct.routeName: (context) => CopySelectProduct(),
            StockName_RequestScreen.routeName: (context) => StockName_RequestScreen(),
            Stock_Name.routeName: (context) => Stock_Name(),
            Stock_SelectProducts.routeName: (context) => Stock_SelectProducts(),
            ChequeCollectionPage.routeName: (context) => ChequeCollectionPage(),
            GroupPrint.routeName: (context) => GroupPrint(),
            ChequeReceipt.routeName: (context) => ChequeReceipt(),
            CustomerWater.routeName: (context) => CustomerWater(),
            DashboardScreen.routeName: (context) => DashboardScreen(),
            AgeingSummaryScreen.routeName: (context) => AgeingSummaryScreen(),
            BankReconciliationScreen .routeName: (context) => BankReconciliationScreen(),
            OverdueCustomerPage .routeName: (context) => OverdueCustomerPage(),
            CustomerDues.routeName: (context) => CustomerDues(),
            StockTransferPage.routeName: (context) => StockTransferPage(),
            StocKTransfer_Inner.routeName: (context) => StocKTransfer_Inner(),
            PickingListPage.routeName: (context) => PickingListPage(),
            TransferOptionsPage.routeName: (context) => TransferOptionsPage(),
            Productionorder.routeName: (context) => Productionorder(),
            NotificationPage.routeName: (context) => NotificationPage(),
            QuotatioCustomerScreen.routeName: (context) => QuotatioCustomerScreen(),
            QuotationProduct.routeName: (context) => QuotationProduct(),
                QuotationHome.routeName: (context) => QuotationHome(),
            WarehouseStockTakeListPage.routeName: (context) =>
                const WarehouseStockTakeListPage(), // NEW
            // PickingAddPage.routeName: (context) => PickingAddPage(),
            // SaleInvoiceSearchPage.routeName: (context) => SaleInvoiceSearchPage(),
          }),
    );
  }
}