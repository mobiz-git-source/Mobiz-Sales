import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  importance: Importance.max,
);

// Background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Background message: ${message.notification?.title}");
}

// -----------------------------------------------------------------------------
// DEVICE + TOKEN
// -----------------------------------------------------------------------------
Future<String> getDeviceId() async {
  final info = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final android = await info.androidInfo;
    return android.id ?? "UNKNOWN";
  }
  return "UNKNOWN";
}

Future<void> sendTokenToBackend(String token) async {
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
      headers: {"Accept": "application/json"},
      body: jsonEncode(body),
    );
    print("✔ Token sent: $body");
    print("🌐 Backend Response: ${res.body}");
  } catch (e) {
    print("❌ Token Send Error: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyCdNIIk0gxNgYTbDUWGHKNa4T1nA9vhrXM",
        appId: "1:662520788670:android:968ca037f5ddbe336b50ef",
        messagingSenderId: "662520788670",
        projectId: "mobiz-sales-b54ca",
      ),
    );

    print("🔥 Firebase initialized");
  } catch (e) {
    print("❌ Firebase init error: $e");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  String? token = await FirebaseMessaging.instance.getToken();
  print("📌 FCM Token: $token");

  if (token != null) sendTokenToBackend(token);

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    print("♻ Token refreshed: $newToken");
    sendTokenToBackend(newToken);
  });
print("Code: ${AppState().minor}");
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

      // Display notification
      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title ?? "No Title",
        message.notification?.body ?? "No Message",
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
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
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          // home: DashboardScreen(),
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
            // PickingAddPage.routeName: (context) => PickingAddPage(),
            // SaleInvoiceSearchPage.routeName: (context) => SaleInvoiceSearchPage(),
          }),
    );
  }
}
