// import 'dart:convert';
// import 'dart:typed_data';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:mobizapp/Models/appstate.dart';
// import 'package:mobizapp/confg/appconfig.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:open_file/open_file.dart';
// import '../Components/commonwidgets.dart';
// import '../Models/Day_close.dart';
// import '../Models/Store_model.dart';
// import '../Utilities/rest_ds.dart';
// import '../confg/sizeconfig.dart';
//
// class Dayexpanding extends StatefulWidget {
//   final int id;
//   final String invoiceNo;
//
//   const Dayexpanding({Key? key, required this.id, required this.invoiceNo})
//       : super(key: key);
//
//   @override
//   State<Dayexpanding> createState() => _DayexpandingState();
// }
//
// class _DayexpandingState extends State<Dayexpanding> {
//   late Future<DataResponse> futureDayCloseData;
//
//   @override
//   void initState() {
//     super.initState();
//     futureDayCloseData = fetchDayCloseData(widget.id);
//   }
//
//   Future<DataResponse> fetchDayCloseData(int id) async {
//     final response = await http.get(Uri.parse(
//         '${RestDatasource().BASE_URL}/api/get_dayclose_by_id?van_id=${AppState().vanId}&store_id=${AppState().storeId}&id=$id'));
//
//     if (response.statusCode == 200) {
//       return DataResponse.fromJson(json.decode(response.body));
//     } else {
//       throw Exception('Failed to load data');
//     }
//   }
//
//   Future<void> generatePdf(Data dayClose) async {
//     final response = await http.get(Uri.parse(
//         '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
//     if (response.statusCode == 200) {
//
//       // Parse JSON response into StoreDetail object
//       StoreDetail storeDetail =
//           StoreDetail.fromJson(json.decode(response.body));
//
//       final pdf = pw.Document();
//       // double balance = opening;
//       final String api =
//           '${RestDatasource().Image_URL}/uploads/store/${storeDetail.logos}';
//       final logoResponse = await http.get(Uri.parse(api));
//       if (logoResponse.statusCode != 200) {
//         // print(api);
//         // print('kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk');
//         throw Exception('Failed to load logo image');
//       }
//       final Uint8List logoBytes = logoResponse.bodyBytes;
//
//       String addressText = storeDetail.address != null
//           ? "Address: ${storeDetail.address}, "
//           : "";
//       String countryText =
//           storeDetail.country != null ? "${storeDetail.country}" : "";
//
//       String finalText = "";
//
//       pdf.addPage(
//         pw.MultiPage(
//           build: (pw.Context context) => [
//             pw.Column(
//               mainAxisAlignment: pw.MainAxisAlignment.start,
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Center(
//                   child: pw.Column(
//                     children: [
//                       pw.Center(
//                         child: pw.Image(
//                           pw.MemoryImage(logoBytes),
//                           height: 100,
//                           width: 100,
//                           fit: pw.BoxFit.cover,
//                         ),
//                       ),
//                       pw.Text(
//                         storeDetail.name,
//                         style: pw.TextStyle(
//                           fontSize: 18,
//                           fontWeight: pw.FontWeight.bold,
//                         ),
//                       ),
//                       if (storeDetail.address != null)
//                         pw.Text(storeDetail.address!),
//                       if (storeDetail.trn != null)
//                         pw.Text('TRN: ${storeDetail.trn}'),
//                       pw.Text('Reports', style: pw.TextStyle(fontSize: 24)),
//                     ],
//                   ),
//                 ),
//                 pw.SizedBox(height: 20),
//                 pw.Divider(color: PdfColors.grey, height: 1, thickness: 1),
//                 pw.SizedBox(height: 20),
//                 pw.Text('Hello ${AppState().name}',
//                     style: pw.TextStyle(
//                         fontSize: 21, fontWeight: pw.FontWeight.bold)),
//                 pw.SizedBox(height: 7),
//                 pw.Text('Van: ${dayClose.vanId}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 3),
//                 pw.Text(
//                     'Sales: ${dayClose.noOfSales} | ${dayClose.amountOfSales}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 3),
//                 // pw.Text(
//                 //     'Orders: ${dayClose.noOfOrder} | ${dayClose.amountOfOrder}',
//                 //     style: pw.TextStyle(fontSize: 15)),
//                 // pw.SizedBox(height: 3),
//                 pw.Text(
//                     'Returns: ${dayClose.noOfReturns} | ${dayClose.amountOfReturns}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 10),
//                 pw.Text('Collection:', style: pw.TextStyle(fontSize: 18)),
//                 pw.SizedBox(height: 5),
//                 pw.Text('Cash: ${dayClose.collectionCashAmount}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 3),
//                 pw.Text(
//                     'Cheque: ${dayClose.collectionChequeAmount} | ${dayClose.collectionNoOfCheque}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 10),
//                 pw.Text('Last Day Balance:', style: pw.TextStyle(fontSize: 18)),
//                 pw.SizedBox(height: 5),
//                 pw.Text('Cash: ${dayClose.lastDayBalanceAmount}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 3),
//                 pw.Text(
//                     'Cheque: ${dayClose.lastDayBalanceNoOfCheque} | ${dayClose.lastDayBalanceChequeAmount}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 15),
//                 pw.Divider(color: PdfColors.grey, height: 1, thickness: 1),
//                 pw.SizedBox(height: 25),
//                 pw.Text('Cash Deposited: ${dayClose.cashDeposited}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 3),
//                 pw.Text('Cash Handed Over: ${dayClose.cashHandOver}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 3),
//                 pw.Text(
//                     'No of Cheque Deposited: ${dayClose.noOfChequeDeposited}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 3),
//                 pw.Text(
//                     'Cheque Deposited Amount: ${dayClose.chequeDepositedAmount}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 3),
//                 pw.Text(
//                     'No of Cheque Handed Over: ${dayClose.noOfChequeHandOver}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 3),
//                 pw.Text(
//                     'Cheque Handed Over Amount: ${dayClose.chequeHandOverAmount}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 3),
//                 pw.Text('Balance Cash in Hand: ${dayClose.balanceCashInHand}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 3),
//                 pw.Text('No of Cheque in Hand: ${dayClose.noOfChequeInHand}',
//                     style: pw.TextStyle(fontSize: 15)),
//                 pw.SizedBox(height: 3),
//                 pw.Text('Cheque Amount in Hand: ${dayClose.chequeAmountInHand}',
//                     style: pw.TextStyle(fontSize: 15)),
//               ],
//             ),
//           ],
//         ),
//       );
//
//       final output = await getTemporaryDirectory();
//       final file = File('${output.path}/day_close_report.pdf');
//       await file.writeAsBytes(await pdf.save());
//       await OpenFile.open(file.path);
//     } else {
//       throw Exception('Failed to load store details');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppConfig.backgroundColor,
//       appBar: AppBar(
//         iconTheme: IconThemeData(color: Colors.white),
//         backgroundColor: AppConfig.colorPrimary,
//         title: Text(
//           'Reports',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: FutureBuilder<DataResponse>(
//         future: futureDayCloseData,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Shimmer.fromColors(
//               baseColor: AppConfig.buttonDeactiveColor.withOpacity(0.1),
//               highlightColor: AppConfig.backButtonColor,
//               child: Center(
//                 child: Column(
//                   children: [
//                     CommonWidgets.loadingContainers(
//                         height: SizeConfig.blockSizeVertical * 10,
//                         width: SizeConfig.blockSizeHorizontal * 90),
//                     CommonWidgets.loadingContainers(
//                         height: SizeConfig.blockSizeVertical * 10,
//                         width: SizeConfig.blockSizeHorizontal * 90),
//                     CommonWidgets.loadingContainers(
//                         height: SizeConfig.blockSizeVertical * 10,
//                         width: SizeConfig.blockSizeHorizontal * 90),
//                     CommonWidgets.loadingContainers(
//                         height: SizeConfig.blockSizeVertical * 10,
//                         width: SizeConfig.blockSizeHorizontal * 90),
//                     CommonWidgets.loadingContainers(
//                         height: SizeConfig.blockSizeVertical * 10,
//                         width: SizeConfig.blockSizeHorizontal * 90),
//                   ],
//                 ),
//               ),
//             );
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData) {
//             return Center(child: Text('No data available'));
//           } else {
//             Data dayClose = snapshot.data!.data;
//             return ListView(
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 30, vertical: 10),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           Icon(Icons.print, color: Colors.blueAccent),
//                           SizedBox(width: 10),
//                           InkWell(
//                             onTap: () => generatePdf(dayClose),
//                             child:
//                                 Icon(Icons.document_scanner, color: Colors.red),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 15.0, vertical: 0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('Hello ${AppState().name}'),
//                           RichText(
//                             text: TextSpan(
//                               text: 'Van  ',
//                               style: TextStyle(color: Colors.black),
//                               children: [
//                                 TextSpan(
//                                   text: ' ${dayClose.vanId}',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           RichText(
//                             text: TextSpan(
//                               text: 'Sales  ',
//                               style: TextStyle(color: Colors.black),
//                               children: [
//                                 TextSpan(
//                                   text:
//                                       '${dayClose.noOfSales} | ${dayClose.amountOfSales}',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           // RichText(
//                           //   text: TextSpan(
//                           //     text: 'Orders  ',
//                           //     style: TextStyle(color: Colors.black),
//                           //     children: [
//                           //       TextSpan(
//                           //         text:
//                           //             '${dayClose.noOfOrder} | ${dayClose.amountOfOrder}',
//                           //         style: TextStyle(color: Colors.grey),
//                           //       ),
//                           //     ],
//                           //   ),
//                           // ),
//                           RichText(
//                             text: TextSpan(
//                               text: 'Returns  ',
//                               style: TextStyle(color: Colors.black),
//                               children: [
//                                 TextSpan(
//                                   text:
//                                       '${dayClose.noOfReturns} | ${dayClose.amountOfReturns}',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Text('Collection'),
//                           Text(
//                             'Cash ${dayClose.collectionCashAmount}',
//                             style: TextStyle(color: Colors.grey),
//                           ),
//                           Text(
//                             'Cheque ${dayClose.collectionChequeAmount} | ${dayClose.collectionNoOfCheque}',
//                             style: TextStyle(color: Colors.grey),
//                           ),
//                           Text('Last Day Balance'),
//                           Text(
//                             'Cash ${dayClose.lastDayBalanceAmount}',
//                             style: TextStyle(color: Colors.grey),
//                           ),
//                           Text(
//                             'Cheque ${dayClose.lastDayBalanceNoOfCheque} | ${dayClose.lastDayBalanceChequeAmount}',
//                             style: TextStyle(color: Colors.grey),
//                           ),
//                           // Text(dayClose.sales != null && dayClose.sales!.isNotEmpty
//                           //     ? '${dayClose.sales![0]}'
//                           //     : 'No sales data available'),
//
//                         ],
//                       ),
//                     ),
//                     // Divider(color: Colors.grey),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 15.0, vertical: 0),
//                       child: Column(),
//                     ),
//                     Divider(color: Colors.grey),
//                     SizedBox(height: 20),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 15.0, vertical: 0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           RichText(
//                             text: TextSpan(
//                               text: 'Expense  ',
//                               style: TextStyle(color: Colors.black),
//                               children: [
//                                 TextSpan(
//                                   text: '${dayClose.expense}',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           RichText(
//                             text: TextSpan(
//                               text: 'Cash Deposited  ',
//                               style: TextStyle(color: Colors.black),
//                               children: [
//                                 TextSpan(
//                                   text: '${dayClose.cashDeposited}',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           RichText(
//                             text: TextSpan(
//                               text: 'Cash Handed Over  ',
//                               style: TextStyle(color: Colors.black),
//                               children: [
//                                 TextSpan(
//                                   text: '${dayClose.cashHandOver}',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           RichText(
//                             text: TextSpan(
//                               text: 'No of Cheque Deposited  ',
//                               style: TextStyle(color: Colors.black),
//                               children: [
//                                 TextSpan(
//                                   text: '${dayClose.noOfChequeDeposited}',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           RichText(
//                             text: TextSpan(
//                               text: 'Cheque Deposited Amount  ',
//                               style: TextStyle(color: Colors.black),
//                               children: [
//                                 TextSpan(
//                                   text: '${dayClose.chequeDepositedAmount}',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           RichText(
//                             text: TextSpan(
//                               text: 'No of Cheque Handed Over  ',
//                               style: TextStyle(color: Colors.black),
//                               children: [
//                                 TextSpan(
//                                   text: '${dayClose.noOfChequeHandOver}',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           RichText(
//                             text: TextSpan(
//                               text: 'Cheque Handed Over Amount  ',
//                               style: TextStyle(color: Colors.black),
//                               children: [
//                                 TextSpan(
//                                   text: '${dayClose.chequeHandOverAmount}',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           RichText(
//                             text: TextSpan(
//                               text: 'Balance Cash in Hand  ',
//                               style: TextStyle(color: Colors.black),
//                               children: [
//                                 TextSpan(
//                                   text: '${dayClose.balanceCashInHand}',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           RichText(
//                             text: TextSpan(
//                               text: 'No of Cheque in Hand  ',
//                               style: TextStyle(color: Colors.black),
//                               children: [
//                                 TextSpan(
//                                   text: '${dayClose.noOfChequeInHand}',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           RichText(
//                             text: TextSpan(
//                               text: 'Cheque Amount in Hand  ',
//                               style: TextStyle(color: Colors.black),
//                               children: [
//                                 TextSpan(
//                                   text: '${dayClose.chequeAmountInHand}',
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             );
//           }
//         },
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Utilities/cpcl_helper.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import '../Models/DayReport.dart';
import '../Models/Store_model.dart';
import '../Utilities/date_helper.dart';
import '../Utilities/report_printer.dart';
import '../Reports/day_close_summary_report.dart';
import '../Models/routedatamodelclass.dart';
import '../confg/appconfig.dart';

class DayCloseResponse123 {
  final DayCloseData123 data;
  final List<Sale123> sales;
  final List<SaleReturn> salesReturn;
  final List<Collection> collection;
  final List<Expense> expense;
  final bool success;
  final List<String> messages;

  DayCloseResponse123({
    required this.data,
    required this.sales,
    required this.salesReturn,
    required this.collection,
    required this.expense,
    required this.success,
    required this.messages,
  });

  factory DayCloseResponse123.fromJson(Map<String, dynamic> json) {
    return DayCloseResponse123(
      data: DayCloseData123.fromJson(json['data']),
      sales: (json['sales'] as List).map((i) => Sale123.fromJson(i)).toList(),
      salesReturn: (json['sales_return'] as List)
          .map((i) => SaleReturn.fromJson(i))
          .toList(),
      collection: (json['collection'] as List)
          .map((i) => Collection.fromJson(i))
          .toList(),
      expense:
          (json['expense'] as List).map((i) => Expense.fromJson(i)).toList(),
      success: json['success'],
      messages: List<String>.from(json['messages']),
    );
  }
}

class DayCloseData123 {
  final int id;
  final String inDate;
  final String inTime;
  final int storeId;
  final int vanId;
  final int userId;
  final int scheduled;
  final int visited;
  final int notVisited;
  final int visitPending;
  final int noOfSales;
  final double amountOfSales;
  final int noOfOrder;
  final double amountOfOrder;
  final int noOfReturns;
  final double amountOfReturns;
  final double collectionCashAmount;
  final int collectionNoOfCheque;
  final double collectionChequeAmount;
  final double lastDayBalanceAmount;
  final int lastDayBalanceNoOfCheque;
  final double lastDayBalanceChequeAmount;
  final double expense;
  final double cashDeposited;
  final double cashHandOver;
  final int noOfChequeDeposited;
  final double chequeDepositedAmount;
  final int noOfChequeHandOver;
  final double chequeHandOverAmount;
  final double balanceCashInHand;
  final int noOfChequeInHand;
  final double chequeAmountInHand;
  final int approvel;
  final int pettyCash;
  final String invoiceNo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Van> van;

  DayCloseData123({
    required this.id,
    required this.inDate,
    required this.inTime,
    required this.storeId,
    required this.vanId,
    required this.userId,
    required this.scheduled,
    required this.visited,
    required this.notVisited,
    required this.visitPending,
    required this.noOfSales,
    required this.amountOfSales,
    required this.noOfOrder,
    required this.amountOfOrder,
    required this.noOfReturns,
    required this.amountOfReturns,
    required this.collectionCashAmount,
    required this.collectionNoOfCheque,
    required this.collectionChequeAmount,
    required this.lastDayBalanceAmount,
    required this.lastDayBalanceNoOfCheque,
    required this.lastDayBalanceChequeAmount,
    required this.expense,
    required this.cashDeposited,
    required this.cashHandOver,
    required this.noOfChequeDeposited,
    required this.chequeDepositedAmount,
    required this.noOfChequeHandOver,
    required this.chequeHandOverAmount,
    required this.balanceCashInHand,
    required this.noOfChequeInHand,
    required this.chequeAmountInHand,
    required this.approvel,
    required this.pettyCash,
    required this.invoiceNo,
    required this.createdAt,
    required this.updatedAt,
    required this.van,
  });

  factory DayCloseData123.fromJson(Map<String, dynamic> json) {
    return DayCloseData123(
      id: json['id'] ?? 0,
      inDate: json['in_date'] ?? '',
      inTime: json['in_time'] ?? '',
      storeId: json['store_id'] ?? 0,
      vanId: json['van_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      scheduled: json['scheduled'] ?? 0,
      visited: json['visited'] ?? 0,
      notVisited: json['not_visited'] ?? 0,
      visitPending: json['visit_pending'] ?? 0,
      noOfSales: json['no_of_sales'] ?? 0,
      amountOfSales: (json['amount_of_sales'] ?? 0).toDouble(),
      noOfOrder: json['no_of_order'] ?? 0,
      amountOfOrder: double.tryParse(json['amount_of_order'] ?? '0.0') ?? 0.0,
      noOfReturns: json['no_of_returns'] ?? 0,
      amountOfReturns:
          double.tryParse(json['amount_of_returns'] ?? '0.0') ?? 0.0,
      collectionCashAmount:
          double.tryParse(json['collection_cash_amount'] ?? '0.0') ?? 0.0,
      collectionNoOfCheque: json['collection_no_of_cheque'] ?? 0,
      collectionChequeAmount:
          double.tryParse(json['collection_cheque_amount'] ?? '0.0') ?? 0.0,
      lastDayBalanceAmount:
          double.tryParse(json['last_day_balance_amount'] ?? '0.0') ?? 0.0,
      lastDayBalanceNoOfCheque:
          int.tryParse(json['last_day_balance_no_of_cheque'] ?? '0') ?? 0,
      lastDayBalanceChequeAmount:
          double.tryParse(json['last_day_balance_cheque_amount'] ?? '0.0') ??
              0.0,
      expense: double.tryParse(json['expense'] ?? '0.0') ?? 0.0,
      cashDeposited: double.tryParse(json['cash_deposited'] ?? '0.0') ?? 0.0,
      cashHandOver: double.tryParse(json['cash_hand_over'] ?? '0.0') ?? 0.0,
      noOfChequeDeposited: json['no_of_cheque_deposited'] ?? 0,
      chequeDepositedAmount:
          double.tryParse(json['cheque_deposited_amount'] ?? '0.0') ?? 0.0,
      noOfChequeHandOver: json['no_of_cheque_hand_over'] ?? 0,
      chequeHandOverAmount:
          double.tryParse(json['cheque_hand_over_amount'] ?? '0.0') ?? 0.0,
      balanceCashInHand:
          double.tryParse(json['balance_cash_in_hand'] ?? '0.0') ?? 0.0,
      noOfChequeInHand: json['no_of_cheque_in_hand'] ?? 0,
      chequeAmountInHand:
          double.tryParse(json['cheque_amount_in_hand'] ?? '0.0') ?? 0.0,
      approvel: json['approvel'] ?? 0,
      pettyCash: json['petty_cash'] ?? 0,
      invoiceNo: json['invoice_no'] ?? '',
      createdAt:
          DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      updatedAt:
          DateTime.parse(json['updated_at'] ?? DateTime.now().toString()),
      van: (json['van'] as List<dynamic>?)
              ?.map((item) => Van.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class Van {
  final int id;
  final String? code;
  final String name;
  final String vanType;
  final String? description;
  final int status;
  final int storeId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Van({
    required this.id,
    this.code,
    required this.name,
    required this.vanType,
    this.description,
    required this.status,
    required this.storeId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Van.fromJson(Map<String, dynamic> json) {
    return Van(
      id: json['id'] ?? 0,
      code: json['code'],
      name: json['name'] ?? '',
      vanType: json['van_type'] ?? '',
      description: json['description'],
      status: json['status'] ?? 0,
      storeId: json['store_id'] ?? 0,
      createdAt:
          DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      updatedAt:
          DateTime.parse(json['updated_at'] ?? DateTime.now().toString()),
    );
  }
}

class Customer123 {
  final int id;
  final String name;
  final String code;
  final String address;
  final String contactNumber;
  final String whatsappNumber;
  final String email;
  final String trn;
  final String custImage;
  final String paymentTerms;
  final double creditLimit;
  final int creditDays;
  final String location;
  final int routeId;
  final int provinceId;
  final int storeId;
  final int status;

  Customer123({
    required this.id,
    required this.name,
    required this.code,
    required this.address,
    required this.contactNumber,
    required this.whatsappNumber,
    required this.email,
    required this.trn,
    required this.custImage,
    required this.paymentTerms,
    required this.creditLimit,
    required this.creditDays,
    required this.location,
    required this.routeId,
    required this.provinceId,
    required this.storeId,
    required this.status,
  });

  factory Customer123.fromJson(Map<String, dynamic> json) {
    return Customer123(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      code: json['code'] ?? 'N/A',
      address: json['address'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      whatsappNumber: json['whatsapp_number'] ?? '',
      email: json['email'] ?? '',
      trn: json['trn'] ?? '',
      custImage: json['cust_image'] ?? '',
      paymentTerms: json['payment_terms'] ?? '',
      creditLimit: (json['credit_limit'] ?? 0).toDouble(),
      creditDays: json['credit_days'] ?? 0,
      location: json['location'] ?? '',
      routeId: json['route_id'] ?? 0,
      provinceId: json['province_id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      status: json['status'] ?? 0,
    );
  }
}

class Sale123 {
  final int customerId;
  final String invoiceNo;
  final double grandTotal;
  final List<Customer123> customer;

  Sale123({
    required this.customerId,
    required this.invoiceNo,
    required this.grandTotal,
    required this.customer,
  });

  factory Sale123.fromJson(Map<String, dynamic> json) {
    return Sale123(
      customerId: json['customer_id'],
      invoiceNo: json['invoice_no'],
      grandTotal: json['grand_total'].toDouble(),
      customer: (json['customer'] as List)
          .map((e) => Customer123.fromJson(e))
          .toList(), // Handle list of customers
    );
  }
}

class SaleReturn {
  int? customerId;
  String? invoiceNo;
  num? grandTotal; // Changed from int? to num?
  List<Customer123>? customer;

  SaleReturn({
    this.customerId,
    this.invoiceNo,
    this.grandTotal,
    this.customer,
  });

  factory SaleReturn.fromJson(Map<String, dynamic> json) {
    return SaleReturn(
      customerId: json['customer_id'],
      invoiceNo: json['invoice_no'],
      grandTotal: json['grand_total'],
      customer: json['customer'] != null
          ? List<Customer123>.from(
              json['customer'].map((x) => Customer123.fromJson(x)))
          : [],
    );
  }
}

class Collection {
  int? id;
  int? customerId;
  String? inDate;
  String? inTime;
  String? collectionType;
  String? bank;
  String? chequeDate;
  String? chequeNo;
  String? voucherNo;
  String? totalAmount; // If this is a string representation of a number
  List<Customer123>? customer;
  List<CollectionSale>? sales;

  Collection(
      {this.id,
      this.customerId,
      this.inDate,
      this.inTime,
      this.collectionType,
      this.bank,
      this.chequeDate,
      this.chequeNo,
      this.voucherNo,
      this.totalAmount,
      this.customer,
      this.sales});

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'],
      customerId: json['customer_id'],
      inDate: json['in_date'],
      inTime: json['in_time'],
      collectionType: json['collection_type'],
      bank: json['bank'],
      chequeDate: json['cheque_date'],
      chequeNo: json['cheque_no'],
      voucherNo: json['voucher_no'],
      totalAmount: json['total_amount'],
      customer: json['customer'] != null
          ? List<Customer123>.from(
              json['customer'].map((x) => Customer123.fromJson(x)))
          : [],
      sales: (json['sales'] as List<dynamic>)
          .map((saleJson) => CollectionSale.fromJson(saleJson))
          .toList(),
    );
  }
}

class CollectionSale {
  final String invoiceNo;
  final String voucherNo;
  final String amount;

  CollectionSale({
    required this.invoiceNo,
    required this.voucherNo,
    required this.amount,
  });

  factory CollectionSale.fromJson(Map<String, dynamic> json) {
    return CollectionSale(
      invoiceNo: json['invoice_no']?.toString() ?? '',
      voucherNo: json['voucher_no']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
    );
  }
}

class Expense {
  int? id;
  String? invoiceNo;
  String? inDate;
  String? inTime;
  int? expenseId;
  String? vatAmount; // Assuming this can be a string
  String? totalAmount;
  String? amount;
  String? description;
  String? status;
  List<ExpenseDetails>? expense;

  Expense({
    this.id,
    this.invoiceNo,
    this.inDate,
    this.inTime,
    this.expenseId,
    this.vatAmount,
    this.totalAmount,
    this.amount,
    this.description,
    this.status,
    this.expense,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      invoiceNo: json['invoice_no'],
      inDate: json['in_date'],
      inTime: json['in_time'],
      expenseId: json['expense_id'],
      vatAmount: json['vat_amount'],
      totalAmount: json['total_amount'],
      amount: json['amount'],
      description: json['description'],
      status: json['status'],
      expense: json['expense'] != null
          ? List<ExpenseDetails>.from(
              json['expense'].map((x) => ExpenseDetails.fromJson(x)))
          : [],
    );
  }
}

class ExpenseDetails {
  int? id;
  String? name;

  ExpenseDetails({
    this.id,
    this.name,
  });

  factory ExpenseDetails.fromJson(Map<String, dynamic> json) {
    return ExpenseDetails(
      id: json['id'],
      name: json['name'],
    );
  }
}

// Main Page Widget
class DayClosePagessss extends StatefulWidget {
  final int id;
  final String invoiceNo;

  const DayClosePagessss({Key? key, required this.id, required this.invoiceNo})
      : super(key: key);
  @override
  _DayClosePagessssState createState() => _DayClosePagessssState();
}

class _DayClosePagessssState extends State<DayClosePagessss> {
  late Future<DayCloseResponse123> futureDayCloseData;
  String? routeName;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  bool _initDone = false;
  bool _noData = false;

  void _initPrinter() async {
    await loadPrinterTypeCache();
    bool? isConnected = await printer.isConnected;
    if (isConnected!) {
      setState(() {
        _connected = true;
      });
    }
    _getBluetoothDevices();
  }

  void _getBluetoothDevices() async {
    List<BluetoothDevice> devices = await printer.getBondedDevices();
    BluetoothDevice? defaultDevice;
    final prefs = await SharedPreferences.getInstance();
    final savedDeviceAddress = prefs.getString('selected_device_address');
    for (BluetoothDevice device in devices) {
      if (device.address == savedDeviceAddress) {
        defaultDevice = device;
        break;
      }
    }
    setState(() {
      _devices = devices;
      _selectedDevice = defaultDevice;
    });
  }

  Future<void> _connect() async {
    if (_selectedDevice != null) {
      await printer.connect(_selectedDevice!);
      setState(() {
        _connected = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    futureDayCloseData = fetchDayCloseData(widget.id);
    _initPrinter();
    _getRouteName();
  }

  Future<void> _getRouteName() async {
    try {
      RestDatasource api = RestDatasource();
      String endpoint =
          '/api/get_route?store_id=${AppState().storeId}&user_id=${AppState().userId}';
      dynamic resJson = await api.getDetails(endpoint, AppState().token);
      RouteDataModel routeModel = RouteDataModel.fromJson(resJson);

      if (routeModel.data != null && routeModel.data!.isNotEmpty) {
        final matches =
            routeModel.data!.where((r) => r.id == AppState().routeId);
        final match = matches.isNotEmpty ? matches.first : null;
        if (match != null && mounted) {
          setState(() {
            routeName = match.name;
          });
        }
      }
    } catch (e) {
      print('Error fetching route name: $e');
    }
  }

  Future<DayCloseResponse123> fetchDayCloseData(int id) async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_dayclose_by_id?store_id=${AppState().storeId}&van_id=${AppState().vanId}&id=$id&user_id=${AppState().userId}'));

    if (response.statusCode == 200) {
      print(response.request);
      print(id);
      return DayCloseResponse123.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> generatePdf(DayCloseResponse123 dayClose) async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
    if (response.statusCode == 200) {
      StoreDetail storeDetail =
          StoreDetail.fromJson(json.decode(response.body));
      final pdf = pw.Document();
      final String api =
          '${RestDatasource().Image_URL}/uploads/store/${storeDetail.logos}';
      final logoResponse = await http.get(Uri.parse(api));
      if (logoResponse.statusCode != 200) {
        throw Exception('Failed to load logo image');
      }
      final Uint8List logoBytes = logoResponse.bodyBytes;

      // Compact header style
      pdf.addPage(
        pw.MultiPage(
          // pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          pageFormat: PdfPageFormat.a4.copyWith(
            marginLeft: 36,
            marginRight: 36,
            marginTop: 36,
            marginBottom: 36,
          ),
          build: (pw.Context context) {
            List<pw.Widget> pageContent = [];

            pageContent.add(
              pw.Column(
                children: [
                  // pw.Row(
                  //   mainAxisAlignment: pw.MainAxisAlignment.center,
                  //   children: [
                  //     pw.Image(
                  //       pw.MemoryImage(logoBytes),
                  //       height: 60,
                  //       width: 60,
                  //       fit: pw.BoxFit.contain,
                  //     ),
                  //     pw.SizedBox(width: 10),
                  //     pw.Column(
                  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
                  //       children: [
                  //         pw.Text(
                  //           storeDetail.name,
                  //           style: pw.TextStyle(
                  //             fontSize: 14,
                  //             fontWeight: pw.FontWeight.bold,
                  //           ),
                  //         ),
                  //         if (storeDetail.address != null)
                  //           pw.Text(
                  //             storeDetail.address!,
                  //             style: pw.TextStyle(fontSize: 10),
                  //           ),
                  //         if (storeDetail.trn != null)
                  //           pw.Text(
                  //             'TRN: ${storeDetail.trn}',
                  //             style: pw.TextStyle(fontSize: 10),
                  //           ),
                  //       ],
                  //     ),
                  //   ],
                  // ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Day Close Report',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'SalesMan: ${AppState().name!.toUpperCase()}', // Added .toUpperCase()
                              style: pw.TextStyle(
                                  fontSize: 12, fontWeight: pw.FontWeight.bold),
                            ),
                            if (routeName != null && routeName!.isNotEmpty)
                              pw.Text(
                                'Route: $routeName',
                                style: pw.TextStyle(fontSize: 10),
                              ),
                          ],
                        ),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text("${dayClose.data!.invoiceNo}"),
                              pw.Text(
                                '${DateHelper.displayDate(dayClose.data!.inDate)}   ${dayClose.data!.inTime}',
                                style: pw.TextStyle(fontSize: 9),
                                softWrap: false,
                                maxLines: 1,
                              ),
                            ])
                      ]),
                  pw.SizedBox(height: 10),
                  pw.Divider(height: 1, thickness: 0.5),
                  pw.SizedBox(height: 20),
                ],
              ),
            );

            // Helper function for compact tables
            pw.Table buildCompactTable({
              required List<String> headers,
              required List<List<String>> rows,
              required List<double> columnWidths,
              List<pw.TextAlign>? alignments,
            }) {
              return pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  for (var i = 0; i < columnWidths.length; i++)
                    i: pw.FixedColumnWidth(columnWidths[i]),
                },
                children: [
                  pw.TableRow(
                    children: headers.asMap().entries.map((entry) {
                      return pw.Padding(
                        padding: pw.EdgeInsets.all(2),
                        child: pw.Text(
                          entry.value,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign:
                              alignments?[entry.key] ?? pw.TextAlign.left,
                        ),
                      );
                    }).toList(),
                  ),
                  ...rows.map((row) {
                    return pw.TableRow(
                      children: row.asMap().entries.map((entry) {
                        return pw.Padding(
                          padding: pw.EdgeInsets.all(2),
                          child: pw.Text(
                            entry.value,
                            style: pw.TextStyle(fontSize: 10),
                            textAlign:
                                alignments?[entry.key] ?? pw.TextAlign.left,
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ],
              );
            }

            // SALES SECTION
            if (dayClose.sales != null && dayClose.sales!.isNotEmpty) {
              double totalSales = dayClose.sales!.fold(0, (sum, sale) {
                return sum + (double.tryParse(sale.grandTotal.toString()) ?? 0);
              });

              pageContent.add(pw.Text(
                'SALES',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ));

              var salesRows = dayClose.sales!.asMap().entries.map((entry) {
                var sale = entry.value;
                String customerNames =
                    sale.customer!.map((customer) => customer.name).join(", ");
                String formatCustomerName(String name) {
                  const maxLineLength = 52;
                  if (name.length <= maxLineLength) return name;
                  List<String> lines = [];
                  String remaining = name;
                  while (remaining.length > maxLineLength) {
                    int breakPoint = remaining.lastIndexOf(' ', maxLineLength);
                    if (breakPoint < 0) {
                      lines
                          .add('${remaining.substring(0, maxLineLength - 1)}-');
                      remaining = remaining.substring(maxLineLength - 1);
                    } else {
                      lines.add(remaining.substring(0, breakPoint));
                      remaining = remaining.substring(breakPoint + 1);
                    }
                  }
                  if (remaining.isNotEmpty) {
                    lines.add(remaining);
                  }
                  return lines.join('\n');
                }

                return [
                  '${entry.key + 1}',
                  formatCustomerName(customerNames),
                  sale.invoiceNo ?? '',
                  sale.grandTotal
                          ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
                      '0.00',
                ];
              }).toList();

              salesRows.add([
                '',
                '',
                'Total:',
                totalSales.toStringAsFixed(AppState().noOfDecimals ?? 2)
              ]);

              pageContent.add(buildCompactTable(
                headers: ['SI NO', 'SHOP NAME', 'INVOICE NO', 'Amount'],
                rows: salesRows,
                columnWidths: [20, 130, 50, 50],
                alignments: [
                  pw.TextAlign.center,
                  pw.TextAlign.left,
                  pw.TextAlign.left,
                  pw.TextAlign.right,
                ],
              ));

              pageContent.add(pw.SizedBox(height: 5));
            }

            // SALES RETURN SECTION
            if (dayClose.salesReturn != null &&
                dayClose.salesReturn!.isNotEmpty) {
              double totalReturns = dayClose.salesReturn!.fold(0, (sum, ret) {
                return sum + (double.tryParse(ret.grandTotal.toString()) ?? 0);
              });

              pageContent.add(pw.Text(
                'SALES RETURNS',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ));

              var returnRows =
                  dayClose.salesReturn!.asMap().entries.map((entry) {
                var ret = entry.value;
                String customerNames =
                    ret.customer!.map((customer) => customer.name).join(", ");
                String formatCustomerName(String name) {
                  const maxLineLength = 52;
                  if (name.length <= maxLineLength) return name;
                  List<String> lines = [];
                  String remaining = name;
                  while (remaining.length > maxLineLength) {
                    int breakPoint = remaining.lastIndexOf(' ', maxLineLength);
                    if (breakPoint < 0) {
                      lines
                          .add('${remaining.substring(0, maxLineLength - 1)}-');
                      remaining = remaining.substring(maxLineLength - 1);
                    } else {
                      lines.add(remaining.substring(0, breakPoint));
                      remaining = remaining.substring(breakPoint + 1);
                    }
                  }
                  if (remaining.isNotEmpty) {
                    lines.add(remaining);
                  }
                  return lines.join('\n');
                }

                return [
                  '${entry.key + 1}',
                  formatCustomerName(customerNames),
                  ret.invoiceNo ?? '',
                  ret.grandTotal
                          ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
                      '0.00',
                ];
              }).toList();

              // Add total row
              returnRows.add([
                '',
                '',
                'Total:',
                totalReturns.toStringAsFixed(AppState().noOfDecimals ?? 2)
              ]);

              pageContent.add(buildCompactTable(
                headers: ['SI NO', 'SHOP NAME', 'Reference', 'Amount'],
                rows: returnRows,
                columnWidths: [20, 130, 50, 50],
                alignments: [
                  pw.TextAlign.center,
                  pw.TextAlign.left,
                  pw.TextAlign.left,
                  pw.TextAlign.right,
                ],
              ));

              pageContent.add(pw.SizedBox(height: 5));
            }

            // COLLECTIONS SECTION
            if (dayClose.collection != null &&
                dayClose.collection!.isNotEmpty) {
              double totalCollections =
                  dayClose.collection!.fold(0, (sum, col) {
                return sum + (double.tryParse(col.totalAmount.toString()) ?? 0);
              });

              pageContent.add(pw.Text(
                'COLLECTIONS',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ));
              String formatReferenceTextSmart(
                  List<Map<String, dynamic>> sales) {
                const maxLineLength = 50;
                List<String> lines = [];
                String currentLine = '';

                for (var sale in sales) {
                  String saleText = '${sale['invoiceNo']} : ${sale['amount']}';
                  if (currentLine.isEmpty) {
                    currentLine = saleText;
                  } else if ((currentLine + ', ' + saleText).length <=
                      maxLineLength) {
                    currentLine += ', $saleText';
                  } else {
                    lines.add(currentLine);
                    currentLine = saleText;
                  }
                }

                if (currentLine.isNotEmpty) {
                  lines.add(currentLine);
                }

                return lines.join('\n');
              }

              var collectionRows =
                  dayClose.collection!.asMap().entries.map((entry) {
                var col = entry.value;

                String customerNames =
                    col.customer!.map((customer) => customer.name).join(", ");

                String formatCustomerName(String name) {
                  const maxLineLength = 42;
                  if (name.length <= maxLineLength) return name;
                  List<String> lines = [];
                  String remaining = name;
                  while (remaining.length > maxLineLength) {
                    int breakPoint = remaining.lastIndexOf(' ', maxLineLength);
                    if (breakPoint < 0) {
                      lines
                          .add('${remaining.substring(0, maxLineLength - 1)}-');
                      remaining = remaining.substring(maxLineLength - 1);
                    } else {
                      lines.add(remaining.substring(0, breakPoint));
                      remaining = remaining.substring(breakPoint + 1);
                    }
                  }
                  if (remaining.isNotEmpty) {
                    lines.add(remaining);
                  }
                  return lines.join('\n');
                }

                String referenceText = '';
                if (col.sales != null && col.sales!.isNotEmpty) {
                  referenceText = formatReferenceTextSmart(col.sales!
                      .map((sale) => {
                            'invoiceNo': sale.invoiceNo,
                            'amount': sale.amount,
                          })
                      .toList());
                }

                return [
                  '${entry.key + 1}',
                  formatCustomerName(customerNames),
                  col.collectionType ?? '',
                  col.totalAmount ?? '0.00',
                  "${col.voucherNo ?? ''} | $referenceText",
                ];
              }).toList();

              // Add total row
              collectionRows.add([
                '',
                '',
                'Total:',
                totalCollections.toStringAsFixed(AppState().noOfDecimals ?? 2)
              ]);

              pageContent.add(buildCompactTable(
                headers: ['SI NO', 'SHOP NAME', 'TYPE', 'Amount', 'Reference'],
                rows: collectionRows,
                columnWidths: [20, 100, 20, 30, 80],
                alignments: [
                  pw.TextAlign.center,
                  pw.TextAlign.left,
                  pw.TextAlign.left,
                  pw.TextAlign.right,
                  pw.TextAlign.left,
                ],
              ));

              pageContent.add(pw.SizedBox(height: 5));
            }

            // EXPENSES SECTION
            // EXPENSES SECTION
            if (dayClose.expense != null && dayClose.expense!.isNotEmpty) {
              double totalExpenses = dayClose.expense!.fold(0, (sum, exp) {
                return sum + (double.tryParse(exp.amount.toString()) ?? 0);
              });

              pageContent.add(
                pw.Text(
                  'EXPENSES',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              );

              var expenseRows = dayClose.expense!.asMap().entries.map((entry) {
                var exp = entry.value;

                return [
                  '${entry.key + 1}',

                  // Reference
                  exp.invoiceNo ?? '',
                  // Expense Name
                  exp.expense != null && exp.expense!.isNotEmpty
                      ? exp.expense![0].name ?? ''
                      : '',

                  // Remarks
                  exp.description ?? '',

                  // Amount
                  exp.amount ?? '0.00',
                ];
              }).toList();

              expenseRows.add([
                '',
                '',
                '',
                'Total:',
                totalExpenses.toStringAsFixed(AppState().noOfDecimals ?? 2),
              ]);

              pageContent.add(
                buildCompactTable(
                  headers: [
                    'SI NO',
                    'REFERENCE',
                    'EXPENSE NAME',
                    'REMARKS',
                    'AMOUNT',
                  ],
                  rows: expenseRows,
                  columnWidths: [
                    20,
                    45,
                    60,
                    60,
                    35,
                  ],
                  alignments: [
                    pw.TextAlign.center,
                    pw.TextAlign.left,
                    pw.TextAlign.left,
                    pw.TextAlign.left,
                    pw.TextAlign.right,
                  ],
                ),
              );

              pageContent.add(pw.SizedBox(height: 5));
            }

            double totalCollections = dayClose.collection != null &&
                    dayClose.collection!.isNotEmpty
                ? dayClose.collection!.map((collection) {
                    return double.tryParse(collection.totalAmount.toString()) ??
                        0.0;
                  }).reduce((a, b) => a + b)
                : 0.0; // Default to 0 if the list is empty

            double totalExpenses = dayClose.expense != null &&
                    dayClose.expense!.isNotEmpty
                ? dayClose.expense!.map((expense) {
                    return double.tryParse(expense.amount.toString()) ?? 0.0;
                  }).reduce((a, b) => a + b)
                : 0.0;
            pageContent.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Divider(height: 1, thickness: 0.5),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'SUMMARY',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Net Cash Balance: ${(totalCollections - totalExpenses).toStringAsFixed(AppState().noOfDecimals ?? 2)}',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Divider(),
                  pw.SizedBox(height: 5),
                  pw.Text('Expense ${dayClose.data!.expense}',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.Text('Cash Deposited: ${dayClose.data!.cashDeposited}',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 3),
                  pw.Text('Cash Handed Over: ${dayClose.data!.cashHandOver}',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                      'No of Cheque Deposited: ${dayClose.data!.noOfChequeDeposited}',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                      'Cheque Deposited Amount: ${dayClose.data!.chequeDepositedAmount}',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                      'No of Cheque Handed Over: ${dayClose.data!.noOfChequeHandOver}',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                      'Cheque Handed Over Amount: ${dayClose.data!.chequeHandOverAmount}',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                      'Balance Cash in Hand: ${dayClose.data!.balanceCashInHand}',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                      'No of Cheque in Hand: ${dayClose.data!.noOfChequeInHand}',
                      style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                      'Cheque Amount in Hand: ${dayClose.data!.chequeAmountInHand}',
                      style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            );

            return pageContent;
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/day_close_report.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } else {
      throw Exception('Failed to load store details');
    }
  }

  // void _print(DayCloseResponse123 report) async {
  //   if (_connected) {
  //     double totalSales = report.sales != null && report.sales!.isNotEmpty
  //         ? report.sales!.map((sales) {
  //             return double.tryParse(sales.grandTotal.toString()) ?? 0.0;
  //           }).reduce((a, b) => a + b)
  //         : 0.0;

  //     double totalSalesreturn = report.salesReturn != null &&
  //             report.salesReturn!.isNotEmpty
  //         ? report.salesReturn!.map((salesReturn) {
  //             return double.tryParse(salesReturn.grandTotal.toString()) ?? 0.0;
  //           }).reduce((a, b) => a + b)
  //         : 0.0;

  //     double totalCollections = report.collection != null &&
  //             report.collection!.isNotEmpty
  //         ? report.collection!.map((collection) {
  //             return double.tryParse(collection.totalAmount.toString()) ?? 0.0;
  //           }).reduce((a, b) => a + b)
  //         : 0.0;

  //     double totalExpenses =
  //         report.expense != null && report.expense!.isNotEmpty
  //             ? report.expense!.map((expense) {
  //                 return double.tryParse(expense.totalAmount.toString()) ?? 0.0;
  //               }).reduce((a, b) => a + b)
  //             : 0.0;

  //     final vanName = (report.data!.van != null && report.data!.van.isNotEmpty)
  //         ? report.data!.van[0].name
  //         : 'N/A';

  //     // Printing section headers and key info
  //     // printer.printCustom('Salesman: ${report.data!.user}', 1, 0);
  //     // printer.printCustom(
  //     //     'Date: ${report.data?.inDate != null ? DateFormat('dd-MMM-yyyy').format(DateTime.parse(report.data!.inDate!)) : 'No Date'}',
  //     //     1,
  //     //     0);
  //     printer.printCustom(
  //         'Date ${DateHelper.displayDate(report.data!.inDate)}', 1, 0);
  //     printer.printCustom('Time ${report.data!.inTime}', 1, 0);
  //     printer.printCustom('SalesMan: ${AppState().name}', 1, 0);
  //     if (routeName != null && routeName!.isNotEmpty) {
  //       printer.printCustom('Route: $routeName', 1, 0);
  //     }
  //     printer.printCustom('VAN:$vanName', 1, 0);
  //     printer.printCustom('Petty Cash:${report.data!.pettyCash}', 1, 0);
  //     printer.printCustom('Invoice No: ${report.data!.invoiceNo}', 1, 0);
  //     printer.printCustom(
  //         'Sales: ${report.data!.noOfSales} | ${report.data!.amountOfSales.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
  //         1,
  //         0);
  //     printer.printCustom(
  //         'Returns: ${report.data!.noOfReturns} | ${report.data!.amountOfReturns}',
  //         1,
  //         0);
  //     printer.printCustom('Collection', 1, 0);
  //     printer.printCustom('Cash: ${report.data!.collectionCashAmount}', 1, 0);
  //     printer.printCustom(
  //         'Cheque: ${report.data!.collectionChequeAmount} | ${report.data!.collectionNoOfCheque}',
  //         1,
  //         0);
  //     printer.printCustom('Last Day Balance', 1, 0);
  //     printer.printCustom('Cash: ${report.data!.lastDayBalanceAmount}', 1, 0);
  //     printer.printCustom(
  //         'Cheque: ${report.data!.lastDayBalanceChequeAmount} | ${report.data!.lastDayBalanceNoOfCheque}',
  //         1,
  //         0);
  //     printer.printNewLine();
  //     void printAlignedText(String leftText, String rightText) {
  //       const int maxLineLength =
  //           68; // Adjust the maximum line length as per your printer's character limit
  //       int leftTextLength = leftText.length;
  //       int rightTextLength = rightText.length;

  //       // Calculate padding to ensure rightText is right-aligned
  //       int spaceLength = maxLineLength - (leftTextLength + rightTextLength);
  //       String spaces = ' ' * spaceLength;

  //       printer.printCustom(
  //           '$leftText$spaces$rightText', 1, 0); // Print with left-aligned text
  //     }

  //     // Printing Sales Section
  //     if (report.sales != null && report.sales!.isNotEmpty) {
  //       // Define column widths
  //       const int columnWidth1 = 10; // S.No
  //       const int columnWidth2 = 30; // Shop Name
  //       const int columnWidth3 = 12; // Invoice No
  //       const int columnWidth4 = 8; // Amount

  //       // Print the table header
  //       String headers = "${'SI NO'.padRight(columnWidth1)}"
  //           "${'SHOP NAME'.padRight(columnWidth2)}"
  //           "${'INVOICE NO'.padRight(columnWidth3)}"
  //           "${'Amount'.padLeft(columnWidth4)}";
  //       printer.printCustom('Sales', 1, 0); // Section title
  //       printer.printCustom(headers, 1, 0); // Print table headers

  //       // Helper function to split text by word count
  //       List<String> splitByWords(String text, int maxWords) {
  //         List<String> words = text.split(' ');
  //         List<String> lines = [];
  //         for (int i = 0; i < words.length; i += maxWords) {
  //           lines.add(words
  //               .sublist(i,
  //                   i + maxWords > words.length ? words.length : i + maxWords)
  //               .join(' '));
  //         }
  //         return lines;
  //       }

  //       // Print each sale row
  //       for (var sale in report.sales!) {
  //         String customerNames =
  //             sale.customer!.map((customer) => customer.name).join(", ");

  //         List<String> customerNameLines = splitByWords(customerNames, 4);
  //         String firstLine =
  //             "${(report.sales!.indexOf(sale) + 1).toString().padRight(columnWidth1)}"
  //             "${customerNameLines[0].padRight(columnWidth2)}"
  //             "${sale.invoiceNo!.padRight(columnWidth3)}"
  //             "${sale.grandTotal!.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(columnWidth4)}";

  //         printer.printCustom(firstLine, 1, 0);

  //         for (int i = 1; i < customerNameLines.length; i++) {
  //           String subsequentLine =
  //               "${''.padRight(columnWidth1)}" // Empty space for SI NO
  //               "${customerNameLines[i].padRight(columnWidth2)}"; // Print remaining shop name lines
  //           printer.printCustom(subsequentLine, 1, 0);
  //         }
  //       }
  //       printer.printNewLine();
  //       printAlignedText('',
  //           'Total Sales: ${totalSales.toStringAsFixed(AppState().noOfDecimals ?? 2)}');
  //       printer.printNewLine();
  //     }

  //     // Printing Return Section
  //     if (report.salesReturn != null && report.salesReturn!.isNotEmpty) {
  //       const int columnWidth1 = 10; // S.No
  //       const int columnWidth2 = 30; // Shop Name
  //       const int columnWidth3 = 12; // Invoice No
  //       const int columnWidth4 = 8; // Amount

  //       // Print the table header
  //       String headers = "${'SI NO'.padRight(columnWidth1)}"
  //           "${'SHOP NAME'.padRight(columnWidth2)}"
  //           "${'TYPE'.padRight(columnWidth3)}"
  //           "${'Amount'.padLeft(columnWidth4)}";
  //       printer.printCustom('Sales Return', 1, 0); // Section title
  //       printer.printCustom(headers, 1, 0); // Print table headers

  //       // Helper function to split text by word count
  //       List<String> splitByWords(String text, int maxWords) {
  //         List<String> words = text.split(' ');
  //         List<String> lines = [];
  //         for (int i = 0; i < words.length; i += maxWords) {
  //           lines.add(words
  //               .sublist(i,
  //                   i + maxWords > words.length ? words.length : i + maxWords)
  //               .join(' '));
  //         }
  //         return lines;
  //       }

  //       for (var salesReturn in report.salesReturn!) {
  //         String customerNames =
  //             salesReturn.customer!.map((customer) => customer.name).join(", ");
  //         List<String> customerNameLines = splitByWords(customerNames, 4);
  //         String firstLine =
  //             "${(report.salesReturn!.indexOf(salesReturn) + 1).toString().padRight(columnWidth1)}"
  //             "${customerNameLines[0].padRight(columnWidth2)}"
  //             "${(salesReturn.invoiceNo ?? 'No Type').padRight(columnWidth3)}"
  //             "${salesReturn.grandTotal!.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(columnWidth4)}";

  //         printer.printCustom(firstLine, 1, 0);
  //         for (int i = 1; i < customerNameLines.length; i++) {
  //           String subsequentLine = "${''.padRight(columnWidth1)}"
  //               "${customerNameLines[i].padRight(columnWidth2)}";
  //           printer.printCustom(subsequentLine, 1, 0);
  //         }
  //       }
  //       printer.printNewLine();
  //       printAlignedText('',
  //           'Total Sales Return: ${totalSalesreturn.toStringAsFixed(AppState().noOfDecimals ?? 2)}');
  //       // printer.printCustom('Total Collections: $totalCollections', 1, 0);
  //       printer.printNewLine();
  //       // printer.printCustom('Return', 1, 0);
  //       // printer.printCustom('SI NO  SHOP NAME        Reference    Amount', 1, 0);
  //       // for (var returns in report.salesReturn!) {
  //       //   String customerNames = returns.customer!.map((customer) => customer.name).join(", ");
  //       //   String formattedShopName = customerNames.length > 12
  //       //       ? '${customerNames.substring(0, 12)}...' // Shorten long names
  //       //       : customerNames;
  //       //   printer.printCustom(
  //       //       '${(report.salesReturn!.indexOf(returns) + 1).toString().padRight(6)}'
  //       //           '${formattedShopName.padRight(16)}'
  //       //           '${returns.invoiceNo?.padRight(12) ?? 'No Invoice'.padRight(12)}'
  //       //           '${returns.grandTotal.toString().padLeft(8)}',
  //       //       1, 0);
  //       // }
  //       // printer.printCustom('Total Sales Return: $totalSalesreturn', 1, 0);
  //       // printer.printNewLine();
  //     }

  //     // Printing Collection Section
  //     if (report.collection != null && report.collection!.isNotEmpty) {
  //       // Define column widths
  //       const int columnWidth1 = 10; // S.No
  //       const int columnWidth2 = 30; // Shop Name
  //       const int columnWidth3 = 12; // Invoice No
  //       const int columnWidth4 = 8; // Amount

  //       // Print the table header
  //       String headers = "${'SI NO'.padRight(columnWidth1)}"
  //           "${'SHOP NAME'.padRight(columnWidth2)}"
  //           "${'TYPE'.padRight(columnWidth3)}"
  //           "${'Amount'.padLeft(columnWidth4)}";
  //       printer.printCustom('Collection', 1, 0); // Section title
  //       printer.printCustom(headers, 1, 0); // Print table headers

  //       // Helper function to split text by word count
  //       List<String> splitByWords(String text, int maxWords) {
  //         List<String> words = text.split(' ');
  //         List<String> lines = [];
  //         for (int i = 0; i < words.length; i += maxWords) {
  //           lines.add(words
  //               .sublist(i,
  //                   i + maxWords > words.length ? words.length : i + maxWords)
  //               .join(' '));
  //         }
  //         return lines;
  //       }

  //       // Print each collection row
  //       for (var collection in report.collection!) {
  //         String customerNames =
  //             collection.customer!.map((customer) => customer.name).join(", ");
  //         List<String> customerNameLines = splitByWords(customerNames, 4);
  //         String firstLine =
  //             "${(report.collection!.indexOf(collection) + 1).toString().padRight(columnWidth1)}"
  //             "${customerNameLines[0].padRight(columnWidth2)}"
  //             "${(collection.collectionType ?? 'No Type').padRight(columnWidth3)}"
  //             "${(double.tryParse(collection.totalAmount ?? '0')?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00').padLeft(columnWidth4)}";

  //         printer.printCustom(firstLine, 1, 0);
  //         for (int i = 1; i < customerNameLines.length; i++) {
  //           String subsequentLine = "${''.padRight(columnWidth1)}"
  //               "${customerNameLines[i].padRight(columnWidth2)}";
  //           printer.printCustom(subsequentLine, 1, 0);
  //         }
  //       }
  //       printer.printNewLine();
  //       printAlignedText('',
  //           'Total Collections: ${totalCollections.toStringAsFixed(AppState().noOfDecimals ?? 2)}');
  //       // printer.printCustom('Total Collections: $totalCollections', 1, 0);
  //       printer.printNewLine();
  //     }

  //     // Printing Expense Section
  //     // Printing Expense Section
  //     if (report.expense != null && report.expense!.isNotEmpty) {
  //       const int columnWidth1 = 6; // SI NO
  //       const int columnWidth2 = 11; // REFERENCE
  //       const int columnWidth3 = 12; // EXP.NAME
  //       const int columnWidth4 = 11; // REMARKS
  //       const int columnWidth5 = 8; // AMOUNT
  //       // total = 42, and every header label is now SHORTER than its column
  //       // width (so padRight actually adds a visible gap before the next column)

  //       String headers = "${'SI NO'.padRight(columnWidth1)}"
  //           "${'REFERENCE'.padRight(columnWidth2)}"
  //           "${'EXP.NAME'.padRight(columnWidth3)}"
  //           "${'REMARKS'.padRight(columnWidth4)}"
  //           "${'AMOUNT'.padLeft(columnWidth5)}";
  //       printer.printCustom('Expense', 1, 0);
  //       printer.printCustom(headers, 1, 0);

  //       List<String> splitByWords(String text, int maxWords) {
  //         List<String> words = text.split(' ');
  //         List<String> lines = [];
  //         for (int i = 0; i < words.length; i += maxWords) {
  //           lines.add(
  //             words
  //                 .sublist(i,
  //                     i + maxWords > words.length ? words.length : i + maxWords)
  //                 .join(' '),
  //           );
  //         }
  //         return lines;
  //       }

  //       for (var expense in report.expense!) {
  //         String expenseName = expense.expense!.map((e) => e.name).join(", ");
  //         List<String> expenseNameLines = splitByWords(expenseName, 2);
  //         String remarks = expense.description ?? '';
  //         List<String> remarkLines = splitByWords(remarks, 2);

  //         String firstLine =
  //             "${(report.expense!.indexOf(expense) + 1).toString().padRight(columnWidth1)}"
  //             "${(expense.invoiceNo ?? '').padRight(columnWidth2)}"
  //             "${expenseNameLines[0].padRight(columnWidth3)}"
  //             "${(remarkLines.isNotEmpty ? remarkLines[0] : '').padRight(columnWidth4)}"
  //             "${(double.tryParse(expense.amount ?? '0')?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00').padLeft(columnWidth5)}";

  //         printer.printCustom(firstLine, 1, 0);

  //         int maxLines = expenseNameLines.length > remarkLines.length
  //             ? expenseNameLines.length
  //             : remarkLines.length;

  //         for (int i = 1; i < maxLines; i++) {
  //           String nextLine = "${''.padRight(columnWidth1)}"
  //               "${''.padRight(columnWidth2)}"
  //               "${(i < expenseNameLines.length ? expenseNameLines[i] : '').padRight(columnWidth3)}"
  //               "${(i < remarkLines.length ? remarkLines[i] : '').padRight(columnWidth4)}";
  //           printer.printCustom(nextLine, 1, 0);
  //         }
  //       }

  //       printer.printNewLine();
  //       printAlignedText(
  //         '',
  //         'Total Expenses: ${totalExpenses.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
  //       );
  //       printer.printNewLine();
  //     }
  //     printer.printCustom('Expense ${report.data!.expense}', 1, 0);
  //     printer.printCustom('Cash Deposited ${report.data!.cashDeposited}', 1, 0);
  //     printer.printCustom(
  //         'Cash Handed Over ${report.data!.cashHandOver}', 1, 0);
  //     printer.printCustom(
  //         'No of Cheque Deposited ${report.data!.noOfChequeDeposited}', 1, 0);
  //     printer.printCustom(
  //         'Cheque Deposited Amount ${report.data!.chequeDepositedAmount}',
  //         1,
  //         0);
  //     printer.printCustom(
  //         'No of Cheque Handed Over ${report.data!.noOfChequeHandOver}', 1, 0);
  //     printer.printCustom(
  //         'Cheque Handed Over Amount ${report.data!.chequeHandOverAmount}',
  //         1,
  //         0);
  //     printer.printCustom(
  //         'Balance Cash in Hand ${report.data!.balanceCashInHand}', 1, 0);
  //     printer.printCustom(
  //         'No of Cheque in Hand ${report.data!.noOfChequeInHand}', 1, 0);
  //     printer.printCustom(
  //         'Cheque Amount in Hand ${report.data!.chequeAmountInHand}', 1, 0);
  //     printer.printNewLine();

  //     printer.printCustom('Thank you', 1, 1);
  //     printer.paperCut();
  //   }
  //   if (!_connected) {
  //     await _connect();
  //   }
  // }
/// Main Print Dispatcher: Routes automatically to Zebra (CPCL) or Sewoo (ESC/POS)
  /// Main Print Dispatcher: single shared image pipeline, auto-detects
  /// Zebra vs Sewoo internally via printReport().
  Future<void> _print(DayCloseResponse123 report) async {
    if (!_connected) {
      await _connect();
    }
    if (!_connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer not connected')),
      );
      return;
    }

    try {
  if (isZebraPrinter(_selectedDevice)) {
    await printReport(
      printer,
      _selectedDevice,
      (b) => drawDayCloseSummaryReport(b, report, routeName: routeName),
    );
  } else {
    await _printSewoo(report);
  }
} catch (e, st) {
      print('Print error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }
  // ═══════════════════════════════════════════════════════════════
  // 1. ZEBRA ENGINE (CPCL Mode)
// ═══════════════════════════════════════════════════════════════
  // 1. ZEBRA ENGINE (CPCL Mode - Clean Layout, No Overlap)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _printZebra(DayCloseResponse123 report) async {
    final int decimals = AppState().noOfDecimals ?? 2;

    double totalSales = report.sales.isNotEmpty
        ? report.sales
            .map((sales) => double.tryParse(sales.grandTotal.toString()) ?? 0.0)
            .reduce((a, b) => a + b)
        : 0.0;

    double totalSalesreturn = report.salesReturn.isNotEmpty
        ? report.salesReturn
            .map((r) => double.tryParse(r.grandTotal.toString()) ?? 0.0)
            .reduce((a, b) => a + b)
        : 0.0;

    double totalCollections = report.collection.isNotEmpty
        ? report.collection
            .map((c) => double.tryParse(c.totalAmount.toString()) ?? 0.0)
            .reduce((a, b) => a + b)
        : 0.0;

    double totalExpenses = report.expense.isNotEmpty
        ? report.expense
            .map((e) => double.tryParse(e.totalAmount.toString()) ?? 0.0)
            .reduce((a, b) => a + b)
        : 0.0;

    final vanName = (report.data.van.isNotEmpty)
        ? report.data.van[0].name
        : 'N/A';

    final cpcl = CpclBuilder(kLabelWidthDots);

    // ---- Header info ----
    cpcl.boldText("DAY CLOSE REPORT", font: 5, lineGap: 34);
    cpcl.hLine();
    cpcl.twoColumn("Date: ${DateHelper.displayDate(report.data.inDate)}", "Time: ${report.data.inTime}");
    cpcl.twoColumn("Salesman: ${AppState().name}", "VAN: $vanName");
    if (routeName != null && routeName!.isNotEmpty) {
      cpcl.text('Route: $routeName');
    }
    cpcl.twoColumn("Inv: ${report.data.invoiceNo}", "Petty: ${report.data.pettyCash}");
    cpcl.hLine();

    // Summary tiles at the top
    cpcl.twoColumn("Sales (${report.data.noOfSales})", report.data.amountOfSales.toStringAsFixed(decimals));
    cpcl.twoColumn("Returns (${report.data.noOfReturns})", report.data.amountOfReturns.toStringAsFixed(decimals));
    cpcl.twoColumn("Cash Coll", report.data.collectionCashAmount.toStringAsFixed(decimals));
    cpcl.twoColumn("Cheque Coll (${report.data.collectionNoOfCheque})", report.data.collectionChequeAmount.toStringAsFixed(decimals));
    cpcl.twoColumn("Last Day Cash", report.data.lastDayBalanceAmount.toStringAsFixed(decimals));
    cpcl.twoColumn("Last Day Cheque (${report.data.lastDayBalanceNoOfCheque})", report.data.lastDayBalanceChequeAmount.toStringAsFixed(decimals));
    cpcl.hLine();

    // ---- Sales section ----
    if (report.sales.isNotEmpty) {
      cpcl.boldText("SALES", font: 5, lineGap: 30);
      cpcl.hLine(thickness: 1);
      cpcl.text("Sl   Shop Name / Invoice           Amount", font: 4, lineGap: 30);
      cpcl.hLine(thickness: 1);

      for (int i = 0; i < report.sales.length; i++) {
        var sale = report.sales[i];
        String sNo = (i + 1).toString().padRight(4);
        String customerNames =
            sale.customer.map((customer) => customer.name).join(", ");
        if (customerNames.length > 36) customerNames = customerNames.substring(0, 36);

        String inv = sale.invoiceNo.isNotEmpty ? sale.invoiceNo : 'N/A';
        String amt = sale.grandTotal.toStringAsFixed(decimals).padLeft(10);

        // Line 1: Sl + Shop Name
        cpcl.text('$sNo$customerNames', font: 4, lineGap: 28);
        // Line 2: Invoice No + Amount
        String details = '     [$inv]'.padRight(32) + amt;
        cpcl.text(details, font: 4, lineGap: 30);
      }
      cpcl.hLine(thickness: 1);
      cpcl.twoColumn('', 'Total Sales: ${totalSales.toStringAsFixed(decimals)}');
      cpcl.feed(14);
    }

    // ---- Sales Return section ----
    if (report.salesReturn.isNotEmpty) {
      cpcl.boldText("SALES RETURN", font: 5, lineGap: 30);
      cpcl.hLine(thickness: 1);
      cpcl.text("Sl   Shop Name / Ref               Amount", font: 4, lineGap: 30);
      cpcl.hLine(thickness: 1);

      for (int i = 0; i < report.salesReturn.length; i++) {
        var salesReturn = report.salesReturn[i];
        String sNo = (i + 1).toString().padRight(4);
        String customerNames =
            salesReturn.customer?.map((customer) => customer.name).join(", ") ?? '';
        if (customerNames.length > 36) customerNames = customerNames.substring(0, 36);

        String ref = salesReturn.invoiceNo ?? 'No Ref';
        String amt = (salesReturn.grandTotal ?? 0).toDouble().toStringAsFixed(decimals).padLeft(10);

        // Line 1: Sl + Shop Name
        cpcl.text('$sNo$customerNames', font: 4, lineGap: 28);
        // Line 2: Ref + Amount
        String details = '     [$ref]'.padRight(32) + amt;
        cpcl.text(details, font: 4, lineGap: 30);
      }
      cpcl.hLine(thickness: 1);
      cpcl.twoColumn('', 'Total Return: ${totalSalesreturn.toStringAsFixed(decimals)}');
      cpcl.feed(14);
    }

    // ---- Collection section ----
    if (report.collection.isNotEmpty) {
      cpcl.boldText("COLLECTION", font: 5, lineGap: 30);
      cpcl.hLine(thickness: 1);
      cpcl.text("Sl   Shop Name / Type              Amount", font: 4, lineGap: 30);
      cpcl.hLine(thickness: 1);

      for (int i = 0; i < report.collection.length; i++) {
        var collection = report.collection[i];
        String sNo = (i + 1).toString().padRight(4);
        String customerNames =
            collection.customer?.map((customer) => customer.name).join(", ") ?? '';
        if (customerNames.length > 36) customerNames = customerNames.substring(0, 36);

        String type = collection.collectionType ?? 'Cash';
        double parsedAmt = double.tryParse(collection.totalAmount ?? '0') ?? 0;
        String amt = parsedAmt.toStringAsFixed(decimals).padLeft(10);

        // Line 1: Sl + Shop Name
        cpcl.text('$sNo$customerNames', font: 4, lineGap: 28);
        // Line 2: Type + Amount
        String details = '     Type: $type'.padRight(32) + amt;
        cpcl.text(details, font: 4, lineGap: 30);
      }
      cpcl.hLine(thickness: 1);
      cpcl.twoColumn('', 'Total Collection: ${totalCollections.toStringAsFixed(decimals)}');
      cpcl.feed(14);
    }

    // ---- Expense section ----
    if (report.expense.isNotEmpty) {
      cpcl.boldText("EXPENSE", font: 5, lineGap: 30);
      cpcl.hLine(thickness: 1);
      cpcl.text("Sl   Reference / Expense           Amount", font: 4, lineGap: 30);
      cpcl.hLine(thickness: 1);

      for (int i = 0; i < report.expense.length; i++) {
        var expense = report.expense[i];
        String sNo = (i + 1).toString().padRight(4);
        String expenseName = expense.expense?.map((e) => e.name).join(", ") ?? "Expense";
        if (expenseName.length > 36) expenseName = expenseName.substring(0, 36);

        String ref = expense.invoiceNo ?? 'N/A';
        double parsedAmt = double.tryParse(expense.amount ?? '0') ?? 0;
        String amt = parsedAmt.toStringAsFixed(decimals).padLeft(10);

        // Line 1: Sl + Expense Name
        cpcl.text('$sNo$expenseName', font: 4, lineGap: 28);
        // Line 2: Ref + Amount
        String remarks = (expense.description != null && expense.description!.isNotEmpty) 
            ? '($ref - ${expense.description})' 
            : '($ref)';
        if (remarks.length > 25) remarks = remarks.substring(0, 25);
        String details = '     $remarks'.padRight(32) + amt;
        cpcl.text(details, font: 4, lineGap: 30);
      }
      cpcl.hLine(thickness: 1);
      cpcl.twoColumn('', 'Total Expenses: ${totalExpenses.toStringAsFixed(decimals)}');
      cpcl.feed(14);
    }

    // ---- Day-close summary ----
    cpcl.boldText("SUMMARY DETAILS", font: 5, lineGap: 30);
    cpcl.hLine(thickness: 1);
    cpcl.twoColumn('Expense Total', report.data.expense.toString());
    cpcl.twoColumn('Cash Deposited', report.data.cashDeposited.toString());
    cpcl.twoColumn('Cash Handed Over', report.data.cashHandOver.toString());
    cpcl.twoColumn('Cheque Deposited (${report.data.noOfChequeDeposited})', report.data.chequeDepositedAmount.toString());
    cpcl.twoColumn('Cheque Handed Over (${report.data.noOfChequeHandOver})', report.data.chequeHandOverAmount.toString());
    cpcl.twoColumn('Balance Cash in Hand', report.data.balanceCashInHand.toString());
    cpcl.twoColumn('Balance Cheque (${report.data.noOfChequeInHand})', report.data.chequeAmountInHand.toString());
    cpcl.hLine();
    cpcl.feed(10);
    cpcl.centerText('--- THANK YOU ---', font: 4, lineGap: 24);
    cpcl.feed(40);

    final bytes = cpcl.build();
    await sendCpcl(printer, bytes);
  }
  // ═══════════════════════════════════════════════════════════════
  // 2. SEWOO ENGINE (Exact Old ESC/POS Sizes & Alignments)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _printSewoo(DayCloseResponse123 report) async {
    double totalSales = report.sales.isNotEmpty
        ? report.sales.map((sales) {
            return double.tryParse(sales.grandTotal.toString()) ?? 0.0;
          }).reduce((a, b) => a + b)
        : 0.0;

    double totalSalesreturn = report.salesReturn.isNotEmpty
        ? report.salesReturn.map((salesReturn) {
            return double.tryParse(salesReturn.grandTotal.toString()) ?? 0.0;
          }).reduce((a, b) => a + b)
        : 0.0;

    double totalCollections = report.collection.isNotEmpty
        ? report.collection.map((collection) {
            return double.tryParse(collection.totalAmount.toString()) ?? 0.0;
          }).reduce((a, b) => a + b)
        : 0.0;

    double totalExpenses = report.expense.isNotEmpty
        ? report.expense.map((expense) {
            return double.tryParse(expense.totalAmount.toString()) ?? 0.0;
          }).reduce((a, b) => a + b)
        : 0.0;

    final vanName = (report.data.van.isNotEmpty)
        ? report.data.van[0].name
        : 'N/A';

    printer.printCustom(
        'Date ${DateHelper.displayDate(report.data.inDate)}', 1, 0);
    printer.printCustom('Time ${report.data.inTime}', 1, 0);
    printer.printCustom('SalesMan: ${AppState().name}', 1, 0);
    if (routeName != null && routeName!.isNotEmpty) {
      printer.printCustom('Route: $routeName', 1, 0);
    }
    printer.printCustom('VAN:$vanName', 1, 0);
    printer.printCustom('Petty Cash:${report.data.pettyCash}', 1, 0);
    printer.printCustom('Invoice No: ${report.data.invoiceNo}', 1, 0);
    printer.printCustom(
        'Sales: ${report.data.noOfSales} | ${report.data.amountOfSales.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
        1,
        0);
    printer.printCustom(
        'Returns: ${report.data.noOfReturns} | ${report.data.amountOfReturns}',
        1,
        0);
    printer.printCustom('Collection', 1, 0);
    printer.printCustom('Cash: ${report.data.collectionCashAmount}', 1, 0);
    printer.printCustom(
        'Cheque: ${report.data.collectionChequeAmount} | ${report.data.collectionNoOfCheque}',
        1,
        0);
    printer.printCustom('Last Day Balance', 1, 0);
    printer.printCustom('Cash: ${report.data.lastDayBalanceAmount}', 1, 0);
    printer.printCustom(
        'Cheque: ${report.data.lastDayBalanceChequeAmount} | ${report.data.lastDayBalanceNoOfCheque}',
        1,
        0);
    printer.printNewLine();

    void printAlignedText(String leftText, String rightText) {
      const int maxLineLength = 68;
      int leftTextLength = leftText.length;
      int rightTextLength = rightText.length;

      int spaceLength = maxLineLength - (leftTextLength + rightTextLength);
      String spaces = ' ' * spaceLength;

      printer.printCustom('$leftText$spaces$rightText', 1, 0);
    }

    List<String> splitByWords(String text, int maxWords) {
      List<String> words = text.split(' ');
      List<String> lines = [];
      for (int i = 0; i < words.length; i += maxWords) {
        lines.add(words
            .sublist(i,
                i + maxWords > words.length ? words.length : i + maxWords)
            .join(' '));
      }
      return lines;
    }

    // Printing Sales Section
    if (report.sales.isNotEmpty) {
      const int columnWidth1 = 10; // S.No
      const int columnWidth2 = 30; // Shop Name
      const int columnWidth3 = 12; // Invoice No
      const int columnWidth4 = 8; // Amount

      String headers = "${'SI NO'.padRight(columnWidth1)}"
          "${'SHOP NAME'.padRight(columnWidth2)}"
          "${'INVOICE NO'.padRight(columnWidth3)}"
          "${'Amount'.padLeft(columnWidth4)}";
      printer.printCustom('Sales', 1, 0);
      printer.printCustom(headers, 1, 0);

      for (var sale in report.sales) {
        String customerNames =
            sale.customer.map((customer) => customer.name).join(", ");

        List<String> customerNameLines = splitByWords(customerNames, 4);
        String firstLine =
            "${(report.sales.indexOf(sale) + 1).toString().padRight(columnWidth1)}"
            "${customerNameLines[0].padRight(columnWidth2)}"
            "${sale.invoiceNo.padRight(columnWidth3)}"
            "${sale.grandTotal.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(columnWidth4)}";

        printer.printCustom(firstLine, 1, 0);

        for (int i = 1; i < customerNameLines.length; i++) {
          String subsequentLine =
              "${''.padRight(columnWidth1)}"
              "${customerNameLines[i].padRight(columnWidth2)}";
          printer.printCustom(subsequentLine, 1, 0);
        }
      }
      printer.printNewLine();
      printAlignedText('',
          'Total Sales: ${totalSales.toStringAsFixed(AppState().noOfDecimals ?? 2)}');
      printer.printNewLine();
    }

    // Printing Return Section
    if (report.salesReturn.isNotEmpty) {
      const int columnWidth1 = 10;
      const int columnWidth2 = 30;
      const int columnWidth3 = 12;
      const int columnWidth4 = 8;

      String headers = "${'SI NO'.padRight(columnWidth1)}"
          "${'SHOP NAME'.padRight(columnWidth2)}"
          "${'TYPE'.padRight(columnWidth3)}"
          "${'Amount'.padLeft(columnWidth4)}";
      printer.printCustom('Sales Return', 1, 0);
      printer.printCustom(headers, 1, 0);

      for (var salesReturn in report.salesReturn) {
        String customerNames =
            salesReturn.customer?.map((customer) => customer.name).join(", ") ?? '';
        List<String> customerNameLines = splitByWords(customerNames, 4);
        String firstLine =
            "${(report.salesReturn.indexOf(salesReturn) + 1).toString().padRight(columnWidth1)}"
            "${(customerNameLines.isNotEmpty ? customerNameLines[0] : '').padRight(columnWidth2)}"
            "${(salesReturn.invoiceNo ?? 'No Type').padRight(columnWidth3)}"
            "${(salesReturn.grandTotal ?? 0).toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(columnWidth4)}";

        printer.printCustom(firstLine, 1, 0);
        for (int i = 1; i < customerNameLines.length; i++) {
          String subsequentLine = "${''.padRight(columnWidth1)}"
              "${customerNameLines[i].padRight(columnWidth2)}";
          printer.printCustom(subsequentLine, 1, 0);
        }
      }
      printer.printNewLine();
      printAlignedText('',
          'Total Sales Return: ${totalSalesreturn.toStringAsFixed(AppState().noOfDecimals ?? 2)}');
      printer.printNewLine();
    }

    // Printing Collection Section
    if (report.collection.isNotEmpty) {
      const int columnWidth1 = 10;
      const int columnWidth2 = 30;
      const int columnWidth3 = 12;
      const int columnWidth4 = 8;

      String headers = "${'SI NO'.padRight(columnWidth1)}"
          "${'SHOP NAME'.padRight(columnWidth2)}"
          "${'TYPE'.padRight(columnWidth3)}"
          "${'Amount'.padLeft(columnWidth4)}";
      printer.printCustom('Collection', 1, 0);
      printer.printCustom(headers, 1, 0);

      for (var collection in report.collection) {
        String customerNames =
            collection.customer?.map((customer) => customer.name).join(", ") ?? '';
        List<String> customerNameLines = splitByWords(customerNames, 4);
        String firstLine =
            "${(report.collection.indexOf(collection) + 1).toString().padRight(columnWidth1)}"
            "${(customerNameLines.isNotEmpty ? customerNameLines[0] : '').padRight(columnWidth2)}"
            "${(collection.collectionType ?? 'No Type').padRight(columnWidth3)}"
            "${(double.tryParse(collection.totalAmount ?? '0')?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00').padLeft(columnWidth4)}";

        printer.printCustom(firstLine, 1, 0);
        for (int i = 1; i < customerNameLines.length; i++) {
          String subsequentLine = "${''.padRight(columnWidth1)}"
              "${customerNameLines[i].padRight(columnWidth2)}";
          printer.printCustom(subsequentLine, 1, 0);
        }
      }
      printer.printNewLine();
      printAlignedText('',
          'Total Collections: ${totalCollections.toStringAsFixed(AppState().noOfDecimals ?? 2)}');
      printer.printNewLine();
    }

    // Printing Expense Section
    if (report.expense.isNotEmpty) {
      const int columnWidth1 = 6; // SI NO
      const int columnWidth2 = 11; // REFERENCE
      const int columnWidth3 = 12; // EXP.NAME
      const int columnWidth4 = 11; // REMARKS
      const int columnWidth5 = 8; // AMOUNT

      String headers = "${'SI NO'.padRight(columnWidth1)}"
          "${'REFERENCE'.padRight(columnWidth2)}"
          "${'EXP.NAME'.padRight(columnWidth3)}"
          "${'REMARKS'.padRight(columnWidth4)}"
          "${'AMOUNT'.padLeft(columnWidth5)}";
      printer.printCustom('Expense', 1, 0);
      printer.printCustom(headers, 1, 0);

      for (var expense in report.expense) {
        String expenseName = expense.expense?.map((e) => e.name).join(", ") ?? "";
        List<String> expenseNameLines = splitByWords(expenseName, 2);
        String remarks = expense.description ?? '';
        List<String> remarkLines = splitByWords(remarks, 2);

        String firstLine =
            "${(report.expense.indexOf(expense) + 1).toString().padRight(columnWidth1)}"
            "${(expense.invoiceNo ?? '').padRight(columnWidth2)}"
            "${(expenseNameLines.isNotEmpty ? expenseNameLines[0] : '').padRight(columnWidth3)}"
            "${(remarkLines.isNotEmpty ? remarkLines[0] : '').padRight(columnWidth4)}"
            "${(double.tryParse(expense.amount ?? '0')?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00').padLeft(columnWidth5)}";

        printer.printCustom(firstLine, 1, 0);

        int maxLines = expenseNameLines.length > remarkLines.length
            ? expenseNameLines.length
            : remarkLines.length;

        for (int i = 1; i < maxLines; i++) {
          String nextLine = "${''.padRight(columnWidth1)}"
              "${''.padRight(columnWidth2)}"
              "${(i < expenseNameLines.length ? expenseNameLines[i] : '').padRight(columnWidth3)}"
              "${(i < remarkLines.length ? remarkLines[i] : '').padRight(columnWidth4)}";
          printer.printCustom(nextLine, 1, 0);
        }
      }

      printer.printNewLine();
      printAlignedText(
        '',
        'Total Expenses: ${totalExpenses.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
      );
      printer.printNewLine();
    }

    printer.printCustom('Expense ${report.data.expense}', 1, 0);
    printer.printCustom('Cash Deposited ${report.data.cashDeposited}', 1, 0);
    printer.printCustom('Cash Handed Over ${report.data.cashHandOver}', 1, 0);
    printer.printCustom(
        'No of Cheque Deposited ${report.data.noOfChequeDeposited}', 1, 0);
    printer.printCustom(
        'Cheque Deposited Amount ${report.data.chequeDepositedAmount}', 1, 0);
    printer.printCustom(
        'No of Cheque Handed Over ${report.data.noOfChequeHandOver}', 1, 0);
    printer.printCustom(
        'Cheque Handed Over Amount ${report.data.chequeHandOverAmount}', 1, 0);
    printer.printCustom(
        'Balance Cash in Hand ${report.data.balanceCashInHand}', 1, 0);
    printer.printCustom(
        'No of Cheque in Hand ${report.data.noOfChequeInHand}', 1, 0);
    printer.printCustom(
        'Cheque Amount in Hand ${report.data.chequeAmountInHand}', 1, 0);
    printer.printNewLine();

    printer.printCustom('Thank you', 1, 1);
    printer.paperCut();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: AppConfig.colorPrimary,
        title: Text(
          'Reports',
          style: AppConfig.pageTitleStyle,
        ),
      ),
      body: FutureBuilder<DayCloseResponse123>(
        future: futureDayCloseData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || !snapshot.data!.success) {
            return Center(child: Text('No data available.'));
          }

          final dayCloseResponse = snapshot.data!;
          final dayClose = dayCloseResponse.data;
          final sales = dayCloseResponse.sales ?? [];
          final salesReturns = dayCloseResponse.salesReturn ?? [];
          final collections = dayCloseResponse.collection ?? [];
          final expenses = dayCloseResponse.expense ?? [];
          double totalSale = sales.fold(0.0, (sum, returns) {
            return sum +
                (double.tryParse(returns.grandTotal!
                        .toStringAsFixed(AppState().noOfDecimals ?? 2)) ??
                    0.0);
          });

          double totalSum = salesReturns.fold(0.0, (sum, returns) {
            return sum +
                (double.tryParse(returns.grandTotal!
                        .toStringAsFixed(AppState().noOfDecimals ?? 2)) ??
                    0.0);
          });

          double totalCollections = collections.fold(0.0, (sum, returns) {
            return sum +
                (double.tryParse(returns.totalAmount.toString()) ?? 0.0);
          });

          String totalCollectionsFormatted =
              totalCollections.toStringAsFixed(AppState().noOfDecimals ?? 2);
          double totalExpenses = expenses.fold(0.0, (sum, returns) {
            return sum + (double.tryParse(returns.amount.toString()) ?? 0.0);
          });

          String totalExpenseFormated =
              totalExpenses.toStringAsFixed(AppState().noOfDecimals ?? 2);

          final vanName = (dayCloseResponse.data!.van != null &&
                  dayCloseResponse.data!.van.isNotEmpty)
              ? dayCloseResponse.data!.van[0].name
              : 'N/A';

          return ListView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                            onTap: () => _print(dayCloseResponse),
                            child: Icon(Icons.print, color: Colors.blueAccent)),
                        SizedBox(width: 10),
                        InkWell(
                          onTap: () => generatePdf(dayCloseResponse),
                          child:
                              Icon(Icons.document_scanner, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Date: ${DateHelper.displayDate(dayCloseResponse.data!.inDate)}'),
                        Text('Hello ${AppState().name}'),
                        RichText(
                          text: TextSpan(
                            text: 'Van  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: '$vanName',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'Petty Cash  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: '${dayCloseResponse.data!.pettyCash}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'Invoice No  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: '${dayCloseResponse.data!.invoiceNo}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'Sales  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text:
                                    '${dayCloseResponse.data!.noOfSales} | ${dayCloseResponse.data!.amountOfSales.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        // RichText(
                        //   text: TextSpan(
                        //     text: 'Orders  ',
                        //     style: TextStyle(color: Colors.black),
                        //     children: [
                        //       TextSpan(
                        //         text:
                        //             '${dayClose.noOfOrder} | ${dayClose.amountOfOrder}',
                        //         style: TextStyle(color: Colors.grey),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        RichText(
                          text: TextSpan(
                            text: 'Returns  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text:
                                    '${dayCloseResponse.data!.noOfReturns} | ${dayCloseResponse.data!.amountOfReturns}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text('Collection'),
                        Text(
                          'Cash ${dayCloseResponse.data!.collectionCashAmount}',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Cheque ${dayCloseResponse.data!.collectionChequeAmount} | ${dayCloseResponse.data!.collectionNoOfCheque}',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text('Last Day Balance'),
                        Text(
                          'Cash ${dayCloseResponse.data!.lastDayBalanceAmount}',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Cheque ${dayCloseResponse.data!.lastDayBalanceChequeAmount} | ${dayCloseResponse.data!.lastDayBalanceNoOfCheque}',
                          style: TextStyle(color: Colors.grey),
                        ),
                        // Text(dayClose.sales != null && dayClose.sales!.isNotEmpty
                        //     ? '${dayClose.sales![0]}'
                        //     : 'No sales data available'),
                      ],
                    ),
                  ),
                  // Divider(color: Colors.grey),
                  Divider(color: Colors.grey),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (sales.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: AppConfig
                                        .textSubTitleSize, // Fixed width for SI NO
                                    child: Text(
                                      'SI NO',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: AppConfig.text3Sizepre),
                                    ),
                                  ),
                                  Flexible(
                                    flex: 5, // Fixed width for SHOP NAME
                                    child: Text(
                                      'SHOP NAME',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: AppConfig.text3Sizepre),
                                    ),
                                  ),
                                  Flexible(
                                    flex: 11, // Less space for INVOICE NO
                                    child: Text(
                                      'INVOICE NO',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: AppConfig.text3Sizepre),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3, // More space for Amount
                                    child: Text(
                                      'Amount',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: AppConfig.text3Sizepre),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                  height: 8), // Space between header and list

                              // ListView for sales data
                              ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                physics: BouncingScrollPhysics(),
                                itemCount: sales.length,
                                itemBuilder: (context, index) {
                                  final sale = sales[index];
                                  double totalAmountsss = double.tryParse(
                                          sale.grandTotal.toString()) ??
                                      0.0;
                                  String shopName =
                                      '${sale.customer?.map((customer) => customer.name).join(", ") ?? 'No Customer'}';
                                  List<String> words = shopName.split(' ');
                                  String formattedShopName = words.length > 4
                                      ? '${words.take(4).join(' ')}\n${words.skip(4).join(' ')}'
                                      : shopName;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0), // Padding between rows
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        SizedBox(
                                          width: AppConfig.textSubTitleSize,
                                          child: Text(
                                            '${index + 1}', // SI NO
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        Flexible(
                                          flex: 6,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              formattedShopName,
                                              textAlign: TextAlign.left,
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          flex: 5, // Less space for INVOICE NO
                                          child: Text(
                                            '${sale.invoiceNo ?? 'No Invoice'}', // INVOICE NO
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3, // More space for Amount
                                          child: Text(
                                            '${sale.grandTotal?.toStringAsFixed(AppState().noOfDecimals ?? 2)}', // Amount
                                            textAlign: TextAlign
                                                .right, // Align amount to the right
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total: ${totalSale.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Text('No Sales Available'),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Return',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (salesReturns.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: AppConfig
                                          .textSubTitleSize, // Fixed width for SI NO
                                      child: Text(
                                        'SI NO',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: AppConfig.text3Sizepre),
                                      ),
                                    ),
                                    Flexible(
                                      flex: 5, // Fixed width for SHOP NAME
                                      child: Text(
                                        'SHOP NAME',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: AppConfig.text3Sizepre),
                                      ),
                                    ),
                                    Flexible(
                                      flex: 11, // Less space for Reference
                                      child: Text(
                                        'Reference',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: AppConfig.text3Sizepre),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3, // More space for Amount
                                      child: Text(
                                        'Amount',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: AppConfig.text3Sizepre),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    height: 8), // Space between header and list
                                ListView.builder(
                                  scrollDirection: Axis.vertical,
                                  shrinkWrap: true,
                                  physics: BouncingScrollPhysics(),
                                  itemCount: salesReturns.length,
                                  itemBuilder: (context, index) {
                                    final returns = salesReturns[index];
                                    String shopName =
                                        '${returns.customer?.map((customer) => customer.name).join(", ") ?? 'No Customer'}';
                                    List<String> words = shopName.split(' ');
                                    String formattedShopName = words.length > 4
                                        ? '${words.take(4).join(' ')}\n${words.skip(4).join(' ')}'
                                        : shopName;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical:
                                              4.0), // Padding between rows
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(
                                            width: AppConfig
                                                .textSubTitleSize, // Fixed width for SI NO
                                            child: Text('${index + 1}',
                                                textAlign:
                                                    TextAlign.left), // SI NO
                                          ),
                                          Flexible(
                                            flex: 6,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                formattedShopName,
                                                textAlign: TextAlign.left,
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            flex: 5, // Less space for Reference
                                            child: Text(
                                                '${returns.invoiceNo ?? 'No Invoice'}',
                                                textAlign: TextAlign
                                                    .left), // Reference
                                          ),
                                          Expanded(
                                            flex: 3, // More space for Amount
                                            child: Text(
                                                '${returns.grandTotal!.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
                                                textAlign:
                                                    TextAlign.right), // Amount
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                // Total Row
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Total: ${totalSum.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text('No Returns Available'),
                        SizedBox(
                          height: 20,
                        ),
                        Text('Collection',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        if (collections.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: AppConfig
                                        .textSubTitleSize, // Fixed width for SI NO
                                    child: Text(
                                      'SI NO',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: AppConfig.text3Sizepre),
                                    ),
                                  ),
                                  Flexible(
                                    flex: 5, // Fixed width for SHOP NAME
                                    child: Text(
                                      'SHOP NAME',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: AppConfig.text3Sizepre),
                                    ),
                                  ),
                                  Flexible(
                                    flex: 15, // Less space for Reference
                                    child: Text(
                                      'TYPE',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: AppConfig.text3Sizepre),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3, // More space for Amount
                                    child: Text(
                                      'Amount',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: AppConfig.text3Sizepre),
                                    ),
                                  ),
                                ],
                              ),
                              // ListView for collections data
                              ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                physics: BouncingScrollPhysics(),
                                itemCount: collections.length,
                                itemBuilder: (context, index) {
                                  final collection = collections[index];
                                  double totalAmountsss = double.tryParse(
                                          collection.totalAmount.toString()) ??
                                      0.0;
                                  final returns = collections[index];
                                  String shopName =
                                      '${returns.customer?.map((customer) => customer.name).join(", ") ?? 'No Customer'}';
                                  List<String> words = shopName.split(' ');
                                  String formattedShopName = words.length > 4
                                      ? '${words.take(4).join(' ')}\n${words.skip(4).join(' ')}'
                                      : shopName;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        SizedBox(
                                          width: AppConfig
                                              .textSubTitleSize, // Fixed width for SI NO
                                          child: Text('${index + 1}',
                                              textAlign:
                                                  TextAlign.left), // SI NO
                                        ),
                                        Flexible(
                                          flex: 5,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              formattedShopName,
                                              textAlign: TextAlign.left,
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          flex: 5, // Less space for Reference
                                          child: Text(
                                              '${collection.collectionType ?? 'No Type'}'), // Reference
                                        ),
                                        Expanded(
                                          flex: 2, // More space for Amount
                                          child: Text(
                                              '${collection.totalAmount.toString()}'), // Amount
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              // Total Row
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total: ${totalCollectionsFormatted}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Text('No Collections Available'),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Expense',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (expenses.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
// ---------- EXPENSE HEADER ----------
// ---------- EXPENSE HEADER ----------
                              // HEADER
// ---------- EXPENSE HEADER ----------
// ---------- EXPENSE HEADER ----------
                              Row(
                                children: [
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      'SI NO',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: AppConfig.text3Sizepre,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                      width:
                                          10), // CHANGED: 6 -> 10, more even gap

                                  Expanded(
                                    flex: 3,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'REFERENCE',
                                        maxLines: 1,
                                        softWrap: false,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: AppConfig.text3Sizepre,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10), // CHANGED: 6 -> 10

                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      'EXPENSE NAME',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: AppConfig.text3Sizepre,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10), // CHANGED: 6 -> 10

                                  Expanded(
                                    flex:
                                        2, // CHANGED: 4 -> 2, shrinks the column so leftover whitespace
                                    // after short text like "test" doesn't pile up before AMOUNT
                                    child: Text(
                                      'REMARKS',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: AppConfig.text3Sizepre,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10), // CHANGED: 6 -> 10

                                  SizedBox(
                                    width: 65,
                                    child: Text(
                                      'AMOUNT',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: AppConfig.text3Sizepre,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

// ---------- EXPENSE LIST ----------
                              ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: expenses.length,
                                itemBuilder: (context, index) {
                                  final expense = expenses[index];
                                  String expenseName = expense.expense
                                          ?.map((exp) => exp.name)
                                          .join(", ") ??
                                      'No Expense';
                                  String amount = (double.tryParse(
                                              expense.amount ?? '0')
                                          ?.toStringAsFixed(
                                              AppState().noOfDecimals ?? 2)) ??
                                      '0.00';
                                  String remarks = expense.description ??
                                      ''; // unchanged - same data source

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 30,
                                          child: Text(
                                            '${index + 1}',
                                            textAlign: TextAlign.left,
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                10), // CHANGED: matches header gap (10)

                                        Expanded(
                                          flex: 3,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              expense.invoiceNo ??
                                                  '', // unchanged - same data mapping
                                              textAlign: TextAlign.left,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                10), // CHANGED: matches header gap (10)

                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            expenseName, // unchanged - same data mapping
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                10), // CHANGED: matches header gap (10)

                                        Expanded(
                                          flex:
                                              2, // CHANGED: matches header REMARKS flex (2)
                                          child: Text(
                                            remarks, // unchanged - same data mapping, same source
                                            textAlign: TextAlign.left,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        const SizedBox(
                                            width:
                                                10), // CHANGED: matches header gap (10)

                                        SizedBox(
                                          width: 65,
                                          child: Text(
                                            amount, // unchanged - same data mapping
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              // Total Row
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total: ${dayCloseResponse.expense.fold<double>(
                                            0.0,
                                            (sum, e) =>
                                                sum +
                                                (double.tryParse(
                                                        e.totalAmount ?? '0') ??
                                                    0.0),
                                          ).toStringAsFixed(AppState().noOfDecimals ?? 2)}', // Optional: Format as currency or 2 decimal places
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Text('No Expense Available'),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: 'Expense  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: '${dayCloseResponse.data!.expense}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'Cash Deposited  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: '${dayCloseResponse.data!.cashDeposited}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'Cash Handed Over  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: '${dayCloseResponse.data!.cashHandOver}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'No of Cheque Deposited  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text:
                                    '${dayCloseResponse.data!.noOfChequeDeposited}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'Cheque Deposited Amount  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text:
                                    '${dayCloseResponse.data!.chequeDepositedAmount}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'No of Cheque Handed Over  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text:
                                    '${dayCloseResponse.data!.noOfChequeHandOver}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'Cheque Handed Over Amount  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text:
                                    '${dayCloseResponse.data!.chequeHandOverAmount}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'Balance Cash in Hand  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text:
                                    '${dayCloseResponse.data!.balanceCashInHand}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'No of Cheque in Hand  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text:
                                    '${dayCloseResponse.data!.noOfChequeInHand}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'Cheque Amount in Hand  ',
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text:
                                    '${dayCloseResponse.data!.chequeAmountInHand}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
