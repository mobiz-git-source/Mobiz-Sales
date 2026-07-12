import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/DayReport.dart';
import 'package:shimmer/shimmer.dart';

import '../Components/commonwidgets.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'Day_closeReport.dart';
import 'homepage.dart';

class Dayclose extends StatefulWidget {
  static const routeName = "/Dayclose";
  const Dayclose({super.key});

  @override
  State<Dayclose> createState() => _DaycloseState();
}

TextEditingController CashDepositedcontrol = TextEditingController();
TextEditingController CashHandedOvercontrol = TextEditingController();
TextEditingController NoofChequeDepositedcontrol = TextEditingController();
TextEditingController ChequeDepositedAmountcontrol = TextEditingController();
TextEditingController NoofChequeHandedOvercontrol = TextEditingController();
TextEditingController ChequeHandedOverAmountcontrol = TextEditingController();

class _DaycloseState extends State<Dayclose> {
  late Future<Map<String, dynamic>> futureData;
  String formattedDate = DateFormat('dd/MM/yyyy', 'en_US').format(DateTime.now());
  String cashdeposit = '0';
  String cashHanded = '0';
  String Ncheqdepo = '0';
  String cheqdepo = '0';
  String cheqhandedovr = '0';
  String cheqhandedamt = '0';
  String cheqhand = '';
  String balcash = '';
  String amtinhand = '';
  // var selectedDate = DateTime.now();
  var selectedDate = DateTime.now();
  bool isPending = false;
  bool _isPosting = false;
  int _pendingExpensesCount = 0;

  Random random = Random();
  @override
  void initState() {
    super.initState();
    _fetchPendingExpenses();
    fetchData();
    futureData = fetchDayCloseOutstanding();
    fetchPendingStatus().then((status) {
      setState(() {
        isPending = status;
      });
      if (isPending && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pending approvals found'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  bool isdayclose = false;
  Map<String, dynamic>? Dayclosedata;


  Future<bool> fetchPendingStatus() async {
    var apiUrl = '${RestDatasource().BASE_URL}/api/get_dayclose_user_pending?user_id=${AppState().userId}&store_id=${AppState().storeId}';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      print(response.request);
      final data = jsonDecode(response.body);
      return data['data'] == 'pending'; // Adjust this based on the actual response structure
    } else {
      throw Exception('Failed to load pending status');
    }
  }

  void fetchData() async {
    try {
      final data = await fetchDayclose();
      setState(() {
        Dayclosedata = data['data'];
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<Map<String, dynamic>> fetchDayclose() async {
    var apiUrl =
        // '${RestDatasource().BASE_URL}/api/get_dayclose_outstanding_by_date?van_id=${AppState().vanId}&store_id=${AppState().storeId}&in_date=${DateFormat('dd/MM/yyyy').format(selectedDate)}&user_id=${AppState().userId}';
        '${RestDatasource().BASE_URL}/api/get_dayclose_outstanding_by_date?van_id=${AppState().vanId}&store_id=${AppState().storeId}&in_date=$formattedDate';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      print(response.request);
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    Dayclosedata == null ? isdayclose = true : isdayclose = false;
    return Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppConfig.colorPrimary,
          title: Text(
            'Day Close',
            style: TextStyle(color: AppConfig.backgroundColor),
          ),
          actions: [
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(
                  context,
                  DaycloseReport.routeName,
                );
              },
              child: Icon(
                Icons.report_gmailerrorred_outlined,
                color: AppConfig.backgroundColor,
              ),
            ),
            SizedBox(
              width: 10,
            )
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Shimmer.fromColors(
                baseColor: AppConfig.buttonDeactiveColor.withOpacity(0.1),
                highlightColor: AppConfig.backButtonColor,
                child: ListView.builder(
                  itemCount: 3,
                  itemBuilder: (context, index) =>
                      CommonWidgets.loadingContainers(
                    height: SizeConfig.blockSizeVertical * 40,
                    width: SizeConfig.blockSizeHorizontal * 40,
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              final data = snapshot.data!['data'];
              Future<bool> postData() async {
                var url = '${RestDatasource().BASE_URL}/api/dayclose.store';

                var Data = {
                  "expense": data['expense'],
                  "petty_cash": data['petty_cash'],
                  "in_date": formattedDate,
                  "store_id": AppState().storeId,
                  "van_id": AppState().vanId,
                  "user_id": AppState().userId,
                  "scheduled": data['sheduled'],
                  "visited": data['vist_customer'],
                  "not_visited": data['non_vist_customer'],
                  "visit_pending": data['pending'],
                  "no_of_sales": data['no_of_sales'],
                  "amount_of_sales": data['amount_of_sales'],
                  "no_of_order": data['no_of_sales_order'],
                  "amount_of_order": data['amount_of_sales_order'],
                  "no_of_returns": data['no_of_sales_return'],
                  "amount_of_returns": data['amount_of_sales_return'],
                  "collection_cash_amount": data['collection_cash'],
                  "collection_cheque_amount": data['collection_cheque'],
                  "last_day_balance_amount": data['last_day_balance_amount'],
                  "last_day_balance_no_of_cheque": data['last_day_balance_no_of_cheque'],
                  "last_day_balance_cheque_amount": data['last_day_balance_cheque_amount'],
                  "cash_deposited": cashdeposit,
                  "cash_hand_over": cashHanded,
                  "no_of_cheque_deposited": Ncheqdepo,
                  "cheque_deposited_amount": cheqdepo,
                  "no_of_cheque_hand_over": cheqhandedovr,
                  "cheque_hand_over_amount": cheqhandedamt,
                  "balance_cash_in_hand": balcash,
                  "no_of_cheque_in_hand": cheqhand,
                  "cheque_amount_in_hand": amtinhand,
                  "collection_no_of_cheque": data['collection_no_cheque']
                };
                try {
                  var response = await http.post(
                    Uri.parse(url),
                    headers: <String, String>{
                      'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: jsonEncode(Data),
                  );

                  if (response.statusCode == 200) {
                    print('Data posted successfully');
                    if (mounted) {
                      await CommonWidgets.showDialogueBox(
                        context: context,
                        title: "",
                        msg: "Data Inserted Successfully",
                      );

                      setState(() {
                        // clear input values
                        cashdeposit = '';
                        cashHanded = '';
                        Ncheqdepo = '';
                        cheqdepo = '';
                        cheqhandedovr = '';
                        cheqhandedamt = '';

                        CashDepositedcontrol.clear();
                        CashHandedOvercontrol.clear();
                        NoofChequeDepositedcontrol.clear();
                        ChequeDepositedAmountcontrol.clear();
                        NoofChequeHandedOvercontrol.clear();
                        ChequeHandedOverAmountcontrol.clear();
                      });

                      Navigator.pushNamed(context, HomeScreen.routeName);
                    }
                    return true; // ✅ success
                  } else {
                    print('Failed to post data');
                    print('Response status: ${response.statusCode}');
                    print('Response body: ${response.body}');
                    return false; // ❌ fail
                  }
                } catch (e) {
                  print("Error: $e");
                  if (mounted) {
                    CommonWidgets.showDialogueBox(
                      context: context,
                      title: "Error",
                      msg: "Something went wrong. Please try again.",
                    );
                  }
                  return false; // ❌ fail
                }
              }
              if (cashdeposit.isNotEmpty && cashHanded.isNotEmpty) {
                balcash = ((((data['collection_cash']) +
                    (data['last_day_balance_amount'])) -
                    (double.parse(cashdeposit) +
                        double.parse(cashHanded))) -
                    data['expense'])
                    .toString();
              }
              if (cashdeposit.isNotEmpty && cashHanded.isNotEmpty) {
                balcash = ((((data['collection_cash']) +
                    (data['last_day_balance_amount'])) -
                    (double.parse(cashdeposit) +
                        double.parse(cashHanded))) -
                    data['expense'])
                    .toString();
              }
              if (Ncheqdepo.isNotEmpty && cheqhandedovr.isNotEmpty) {
                cheqhand = (((data['collection_no_cheque']) +
                    (data['last_day_balance_no_of_cheque'])) -
                    (double.parse(Ncheqdepo) +
                        double.parse(cheqhandedovr)))
                    .toString();
              }
              if (cheqdepo.isNotEmpty && cheqhandedovr.isNotEmpty) {
                amtinhand = (((data['collection_cheque']) +
                    (data['last_day_balance_cheque_amount'])) -
                    (double.parse(cheqdepo) +
                        double.parse(cheqhandedamt)))
                    .toString();
              }
              Future<void> _showDialog(TextEditingController control, String field,String title) async {
                String? dialogValue = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('$title'),
                      content: TextField(
                        keyboardType: TextInputType.number,
                        controller: control,
                        decoration: const InputDecoration(hintText: "Enter here"),
                      ),
                      actions: <Widget>[
                        TextButton(
                          style: TextButton.styleFrom(
                            fixedSize: const Size(100, 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                            backgroundColor: AppConfig.colorPrimary,
                          ),
                          onPressed: () {
                            // Validate input first
                            final enteredValue = double.tryParse(control.text);

                            if (enteredValue == null || enteredValue < 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter a valid positive number"),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            // Field-specific validations
                            if (field == 'cheqdepoamt') {
                              double amtssinhand = ((data['collection_cheque'] as num).toDouble() +
                                  (data['last_day_balance_cheque_amount'] as num).toDouble()) -
                                  ((num.tryParse(cheqdepo) ?? 0) + (num.tryParse(cheqhandedamt) ?? 0));

                              final maxAllowedValue = Dayclosedata != null
                                  ? double.tryParse(Dayclosedata!['cheque_amount_in_hand']?.toString() ?? '0') ?? 0.0
                                  : amtssinhand;

                              if (enteredValue > maxAllowedValue) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Value cannot exceed $maxAllowedValue."),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                            }

                            // Cheque count validation
                            if (field == 'Ncheqdepo' || field == 'cheqhandedovr') {
                              final chequeInHand = isdayclose == false
                                  ? Dayclosedata == null
                                  ? '0'
                                  : "${Dayclosedata!['no_of_cheque_in_hand']}"
                                  : cheqhand;

                              final chequeInHandValue = double.tryParse(chequeInHand) ?? 0;
                              double currentDeposited = double.tryParse(Ncheqdepo) ?? 0;
                              double currentHandedOver = double.tryParse(cheqhandedovr) ?? 0;

                              if (field == 'Ncheqdepo') {
                                currentDeposited = enteredValue;
                              } else if (field == 'cheqhandedovr') {
                                currentHandedOver = enteredValue;
                              }

                              if ((currentDeposited + currentHandedOver) > chequeInHandValue) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Total cheques cannot exceed available cheques in hand $chequeInHandValue"),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }
                            }

                            Navigator.of(context).pop(control.text);
                          },
                          child: Text('OK', style: TextStyle(color: AppConfig.backgroundColor)),
                        ),
                      ],
                    );
                  },
                );

                // Update state if value entered
                if (dialogValue != null) {
                  setState(() {
                    switch (field) {
                      case 'cashdeposit': cashdeposit = dialogValue; break;
                      case 'cashHanded': cashHanded = dialogValue; break;
                      case 'Ncheqdepo': Ncheqdepo = dialogValue; break;
                      case 'cheqdepoamt': cheqdepo = dialogValue; break;
                      case 'cheqhandedovr': cheqhandedovr = dialogValue; break;
                      case 'cheqhandedamt': cheqhandedamt = dialogValue; break;
                    }

                    if (field == 'Ncheqdepo' || field == 'cheqhandedovr') {
                      final collectionCheque = double.tryParse(Dayclosedata?['collection_no_cheque']?.toString() ?? '0') ?? 0;
                      final lastDayBalanceCheque = double.tryParse(Dayclosedata?['last_day_balance_no_of_cheque']?.toString() ?? '0') ?? 0;
                      final deposited = double.tryParse(Ncheqdepo) ?? 0;
                      final handed = double.tryParse(cheqhandedovr) ?? 0;

                      cheqhand = (collectionCheque + lastDayBalanceCheque - deposited - handed).toString();
                    }
                  });
                }
              }



              return Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15.0, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Hello ${AppState().name}'),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, DayReport.routeName);
                                  },
                                  child: Icon(
                                    CupertinoIcons.doc_plaintext,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            RichText(
                              text: TextSpan(
                                  text: 'Van  ',
                                  style: TextStyle(color: Colors.black),
                                  children: [
                                    TextSpan(
                                        text: ' ${data['van']}',
                                        style: TextStyle(color: Colors.grey))
                                  ]),
                            ),
                            // Text(
                            //     'Scheduled ${data['sheduled']} | Visited  ${data['vist_customer']} | Not Visited ${data['non_vist_customer']} | Pending ${data['pending']}'),
                            RichText(
                              text: TextSpan(
                                  text: 'Sales  ',
                                  style: TextStyle(color: Colors.black),
                                  children: [
                                    TextSpan(
                                        text:
                                            '${data['no_of_sales']} | ${data['amount_of_sales'].toStringAsFixed(AppState().noOfDecimals ?? 2)}',
                                        style: TextStyle(color: Colors.grey))
                                  ]),
                            ),
                            RichText(
                              text: TextSpan(
                                  text: 'Returns  ',
                                  style: TextStyle(color: Colors.black),
                                  children: [
                                    TextSpan(
                                        text:
                                            '${data['no_of_sales_return']} | ${data['amount_of_sales_return']}',
                                        style: TextStyle(color: Colors.grey))
                                  ]),
                            ),
                            Text('Collection'),
                            Text(
                              'Cash ${data['collection_cash']}',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                                'Cheque ${data['collection_cheque']} | ${data['collection_no_cheque']}',
                                style: TextStyle(color: Colors.grey)),
                            Text('Last Day Balance'),
                            Text('Cash ${data['last_day_balance_amount']}',
                                style: TextStyle(color: Colors.grey)),
                            Text(
                                'Cheque ${data['last_day_balance_no_of_cheque']} | ${data['last_day_balance_cheque_amount']}',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Divider(
                        color: Colors.grey.shade300,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Petty Cash
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Petty Cash'),
                                      Container(
                                        child: Center(child: Text("${data['petty_cash']}")),
                                        width: SizeConfig.safeBlockHorizontal! * 17,
                                        height: SizeConfig.safeBlockVertical! * 2.4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(),

                                  // Expense
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Expense'),
                                      Container(
                                        child: Center(child: Text("${data['expense']}")),
                                        width: SizeConfig.safeBlockHorizontal! * 17,
                                        height: SizeConfig.safeBlockVertical! * 2.4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(),

                                  // Cash Deposited
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Cash Deposited'),
                                      GestureDetector(
                                        onTap: isdayclose == false
                                            ? null
                                            : () {
                                          _showDialog(CashDepositedcontrol,
                                              'cashdeposit', 'Cash Deposited');
                                        },
                                        child: Container(
                                          child: Center(
                                              child: Text(isdayclose == false
                                                  ? Dayclosedata == null
                                                  ? ''
                                                  : Dayclosedata!['cash_deposited']
                                                  : cashdeposit)),
                                          width: SizeConfig.safeBlockHorizontal! * 17,
                                          height: SizeConfig.safeBlockVertical! * 2.4,
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(3),
                                              border: Border.all(color: Colors.grey)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(),

                                  // Cash Handed Over
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Cash Handed Over'),
                                      GestureDetector(
                                        onTap: isdayclose == false
                                            ? null
                                            : () {
                                          _showDialog(CashHandedOvercontrol,
                                              'cashHanded', 'Cash Handed Over');
                                        },
                                        child: Container(
                                          child: Center(
                                              child: Text(isdayclose == false
                                                  ? Dayclosedata == null
                                                  ? ''
                                                  : Dayclosedata!['cash_hand_over']
                                                  : cashHanded)),
                                          width: SizeConfig.safeBlockHorizontal! * 17,
                                          height: SizeConfig.safeBlockVertical! * 2.4,
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(3),
                                              border: Border.all(color: Colors.grey)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(),

                                  // No of Cheque Deposited (commented out, kept as-is)
                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //   children: [
                                  //     Text('No of Cheque Deposited'),
                                  //     GestureDetector(
                                  //       onTap: isdayclose == false
                                  //           ? null
                                  //           : () {
                                  //               print("Ncheqdepo$Ncheqdepo");
                                  //               _showDialog(NoofChequeDepositedcontrol, 'Ncheqdepo');
                                  //               print(Ncheqdepo);
                                  //             },
                                  //       child: Container(
                                  //         child: Center(
                                  //             child: Text(isdayclose == false
                                  //                 ? Dayclosedata == null
                                  //                     ? ''
                                  //                     : "${Dayclosedata!['no_of_cheque_deposited']}"
                                  //                 : Ncheqdepo)),
                                  //         width: SizeConfig.safeBlockHorizontal! * 17,
                                  //         height: SizeConfig.safeBlockVertical! * 2.4,
                                  //         decoration: BoxDecoration(
                                  //             borderRadius: BorderRadius.circular(3),
                                  //             border: Border.all(color: Colors.grey)),
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  // Divider(),

                                  // Cheque Deposited Amount
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Cheque Deposited Amount'),
                                      GestureDetector(
                                        onTap: isdayclose == false
                                            ? null
                                            : () {
                                          _showDialog(
                                              ChequeDepositedAmountcontrol,
                                              'cheqdepoamt',
                                              'Cheque Deposited Amount');
                                          print(double.tryParse(
                                              Dayclosedata?['cheque_amount_in_hand']
                                                  ?.toString() ??
                                                  '0') ??
                                              0.0);
                                        },
                                        child: Container(
                                          child: Center(
                                              child: Text(isdayclose == false
                                                  ? Dayclosedata == null
                                                  ? ''
                                                  : Dayclosedata!['cheque_deposited_amount']
                                                  : cheqdepo)),
                                          width: SizeConfig.safeBlockHorizontal! * 17,
                                          height: SizeConfig.safeBlockVertical! * 2.4,
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(3),
                                              border: Border.all(color: Colors.grey)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(),

                                  // No of Cheque Handed Over (commented out, kept as-is)
                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //   children: [
                                  //     Text('No of Cheque Handed Over'),
                                  //     GestureDetector(
                                  //       onTap: isdayclose == false
                                  //           ? null
                                  //           : () {
                                  //               _showDialog(NoofChequeHandedOvercontrol, 'cheqhandedovr');
                                  //             },
                                  //       child: Container(
                                  //         child: Center(
                                  //             child: Text(isdayclose == false
                                  //                 ? Dayclosedata == null
                                  //                     ? ''
                                  //                     : "${Dayclosedata!['no_of_cheque_hand_over']}"
                                  //                 : cheqhandedovr)),
                                  //         width: SizeConfig.safeBlockHorizontal! * 17,
                                  //         height: SizeConfig.safeBlockVertical! * 2.4,
                                  //         decoration: BoxDecoration(
                                  //             borderRadius: BorderRadius.circular(3),
                                  //             border: Border.all(color: Colors.grey)),
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  // Divider(),

                                  // Cheque Handed Over Amount
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Cheque Handed Over Amount'),
                                      GestureDetector(
                                        onTap: isdayclose == false
                                            ? null
                                            : () {
                                          _showDialog(
                                              ChequeHandedOverAmountcontrol,
                                              'cheqhandedamt',
                                              'Cheque Handed Over Amount');
                                        },
                                        child: Container(
                                          child: Center(
                                              child: Text(isdayclose == false
                                                  ? Dayclosedata == null
                                                  ? ''
                                                  : Dayclosedata!['cheque_hand_over_amount']
                                                  : cheqhandedamt)),
                                          width: SizeConfig.safeBlockHorizontal! * 17,
                                          height: SizeConfig.safeBlockVertical! * 2.4,
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(3),
                                              border: Border.all(color: Colors.grey)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(),

                                  // Balance Cash in Hand
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Balance Cash in Hand'),
                                      Container(
                                        child: Center(
                                            child: Text(isdayclose == false
                                                ? Dayclosedata == null
                                                ? ''
                                                : "${Dayclosedata!['balance_cash_in_hand']}"
                                                : balcash)),
                                        width: SizeConfig.safeBlockHorizontal! * 17,
                                        height: SizeConfig.safeBlockVertical! * 2.4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(),

                                  // No of Cheque in Hand (commented out, kept as-is)
                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //   children: [
                                  //     Text('No of Cheque in Hand'),
                                  //     GestureDetector(
                                  //       onTap: () {
                                  //         print("isdayclose$isdayclose");
                                  //         print("Dayclosedata${Dayclosedata == null ? '' : Dayclosedata!['no_of_cheque_in_hand']}");
                                  //         print("cheqhand$cheqhand");
                                  //       },
                                  //       child: Container(
                                  //         child: Center(
                                  //           child: Text(isdayclose == false
                                  //               ? Dayclosedata == null
                                  //                   ? ''
                                  //                   : "${Dayclosedata!['no_of_cheque_in_hand']}"
                                  //               : cheqhand),
                                  //         ),
                                  //         width: SizeConfig.safeBlockHorizontal! * 17,
                                  //         height: SizeConfig.safeBlockVertical! * 2.4,
                                  //         decoration: BoxDecoration(
                                  //           color: Colors.grey.shade300,
                                  //           borderRadius: BorderRadius.circular(3),
                                  //         ),
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  // Divider(),

                                  // Cheque Amount in Hand (last item — no trailing divider)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Cheque Amount in Hand'),
                                      Container(
                                        child: Center(
                                          child: Text(isdayclose == false
                                              ? Dayclosedata == null
                                              ? ''
                                              : "${Dayclosedata!['cheque_amount_in_hand']}"
                                              : amtinhand),
                                        ),
                                        width: SizeConfig.safeBlockHorizontal! * 17,
                                        height: SizeConfig.safeBlockVertical! * 2.4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: SizeConfig.safeBlockHorizontal! * 2),
                          Container(
                              decoration: BoxDecoration(
                                  color: AppConfig.colorPrimary,
                                  borderRadius: BorderRadius.circular(50)),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.upload,
                                  size: 35,
                                  color: Colors.white,
                                ),
                              )),
                        ],
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (isPending || _pendingExpensesCount != 0 || _isPosting)
                                  ? Colors.grey
                                  : AppConfig.colorPrimary,
                              minimumSize: Size(SizeConfig.safeBlockHorizontal! * 40, 40), // Wider min size
                              shape: BeveledRectangleBorder(),
                            ),
                            onPressed: (isPending || _pendingExpensesCount != 0 || _isPosting)
                                ? null
                                : () async {
                              setState(() => _isPosting = true);
                              bool success = await postData();
                              if (!success && mounted) {
                                setState(() => _isPosting = false);
                              }
                            },
                            child: _isPosting
                                ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                                : FittedBox(
                              child: Text("Send for Approval", style: TextStyle(color: Colors.white)),
                            ),
                          ),


                        ],
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Text('No data available');
            }
          },
        ));
  }

  Future<void> _fetchPendingExpenses() async {
    final url = "${RestDatasource().BASE_URL}/api/get_pending_expense?store_id=${AppState().storeId}&user_id=${AppState().userId}";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.request);
        final jsonData = json.decode(response.body);
        final pendingExpenses = jsonData['data'] as int;

        setState(() {
          _pendingExpensesCount = pendingExpenses;
        });

        if (_pendingExpensesCount != 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "$_pendingExpensesCount number of expenses are pending to be approved"),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          throw Exception("Failed to load pending expenses");
        }
      }
    } catch (e) {
      print("Error fetching pending expenses: $e");
    }
  }

  Future<Map<String, dynamic>> fetchDayCloseOutstanding() async {
    final response = await http.get(Uri.parse(
        // '${RestDatasource().BASE_URL}/api/get_dayclose_outstanding?van_id=${AppState().vanId}&store_id=${AppState().storeId}&in_date=${DateFormat('dd/MM/yyyy').format(selectedDate)}'
        '${RestDatasource().BASE_URL}/api/get_dayclose_outstanding?van_id=${AppState().vanId}&store_id=${AppState().storeId}&in_date=$formattedDate&user_id=${AppState().userId}'));

    if (response.statusCode == 200) {
      print(response.request);
      print(response.body);
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }
}
