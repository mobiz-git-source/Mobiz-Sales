import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/DayReport.dart';
import 'package:mobizapp/Utilities/date_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image/image.dart' as img;

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

  String formattedDate = DateHelper.apiDate(DateTime.now());
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
  List<File> _attachedImages = [];

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

  String _fmt(dynamic value) {
    final n = double.tryParse(value?.toString() ?? '');
    if (n == null) return '';
    return n.toStringAsFixed(AppState().noOfDecimals ?? 2);
  }

  bool isdayclose = false;
  Map<String, dynamic>? Dayclosedata;

  void _attachDocuments() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Photo Library'),
                onTap: () async {
                  final List<XFile>? pickedFiles =
                      await picker.pickMultiImage();
                  if (pickedFiles != null && pickedFiles.isNotEmpty) {
                    for (var xFile in pickedFiles) {
                      final compressedImage =
                          await _compressImage(File(xFile.path));
                      setState(() {
                        _attachedImages.add(compressedImage);
                      });
                    }
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () async {
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (pickedFile != null) {
                    final compressedImage =
                        await _compressImage(File(pickedFile.path));
                    setState(() {
                      _attachedImages.add(compressedImage);
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<File> _compressImage(File file) async {
    final image = img.decodeImage(file.readAsBytesSync())!;
    final compressedImage = img.copyResize(image, width: 800);
    final compressedBytes =
        img.encodeJpg(compressedImage, quality: 75); // Compress the image

    final tempDir = await getTemporaryDirectory();
    final compressedFile =
        File('${tempDir.path}/compressed_${file.path.split('/').last}');
    await compressedFile.writeAsBytes(compressedBytes);

    print(
        'Compressed image size: ${compressedFile.lengthSync()} bytes'); // Debug statement

    // Check file size and further compress if necessary
    if (compressedFile.lengthSync() > 200 * 1024) {
      final furtherCompressedBytes =
          img.encodeJpg(compressedImage, quality: 65);
      await compressedFile.writeAsBytes(furtherCompressedBytes);
      print(
          'Further compressed image size: ${compressedFile.lengthSync()} bytes'); // Debug statement
    }

    return compressedFile;
  }

  Future<bool> fetchPendingStatus() async {
    var apiUrl =
        '${RestDatasource().BASE_URL}/api/get_dayclose_user_pending?user_id=${AppState().userId}&store_id=${AppState().storeId}';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      print(response.request);
      final data = jsonDecode(response.body);
      return data['data'] ==
          'pending'; // Adjust this based on the actual response structure
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
        '${RestDatasource().BASE_URL}/api/get_dayclose_outstanding_by_date?van_id=${AppState().vanId}&store_id=${AppState().storeId}&in_date=${DateHelper.apiDate(selectedDate)}';

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
          title: const Text(
            'Day Close',
            style: AppConfig.pageTitleStyle,
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
                var request = http.MultipartRequest('POST', Uri.parse(url));

                request.fields["expense"] = data['expense'].toString();
                request.fields["petty_cash"] = data['petty_cash'].toString();
                request.fields["in_date"] = DateHelper.apiDate(selectedDate);
                request.fields["store_id"] = AppState().storeId.toString();
                request.fields["van_id"] = AppState().vanId.toString();
                request.fields["user_id"] = AppState().userId.toString();
                request.fields["scheduled"] = data['sheduled'].toString();
                request.fields["visited"] = data['vist_customer'].toString();
                request.fields["not_visited"] =
                    data['non_vist_customer'].toString();
                request.fields["visit_pending"] = data['pending'].toString();
                request.fields["no_of_sales"] = data['no_of_sales'].toString();
                request.fields["amount_of_sales"] =
                    data['amount_of_sales'].toString();
                request.fields["no_of_order"] =
                    data['no_of_sales_order'].toString();
                request.fields["amount_of_order"] =
                    data['amount_of_sales_order'].toString();
                request.fields["no_of_returns"] =
                    data['no_of_sales_return'].toString();
                request.fields["amount_of_returns"] =
                    data['amount_of_sales_return'].toString();
                request.fields["collection_cash_amount"] =
                    data['collection_cash'].toString();
                request.fields["collection_cheque_amount"] =
                    data['collection_cheque'].toString();
                request.fields["last_day_balance_amount"] =
                    data['last_day_balance_amount'].toString();
                request.fields["last_day_balance_no_of_cheque"] =
                    data['last_day_balance_no_of_cheque'].toString();
                request.fields["last_day_balance_cheque_amount"] =
                    data['last_day_balance_cheque_amount'].toString();
                request.fields["cash_deposited"] = cashdeposit;
                request.fields["cash_hand_over"] = cashHanded;
                request.fields["no_of_cheque_deposited"] = Ncheqdepo;
                request.fields["cheque_deposited_amount"] = cheqdepo;
                request.fields["no_of_cheque_hand_over"] = cheqhandedovr;
                request.fields["cheque_hand_over_amount"] = cheqhandedamt;
                request.fields["balance_cash_in_hand"] = balcash;
                request.fields["no_of_cheque_in_hand"] = cheqhand;
                request.fields["cheque_amount_in_hand"] = amtinhand;
                request.fields["collection_no_of_cheque"] =
                    data['collection_no_cheque'].toString();

                for (var file in _attachedImages) {
                  request.files.add(await http.MultipartFile.fromPath(
                    'document_name[]',
                    file.path,
                  ));
                }

                try {
                  var streamedResponse = await request.send();
                  var response =
                      await http.Response.fromStream(streamedResponse);

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
                        _attachedImages = [];

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
                final balance = (((data['collection_cash'] as num).toDouble() +
                        (data['last_day_balance_amount'] as num).toDouble()) -
                    (double.parse(cashdeposit) + double.parse(cashHanded)) -
                    (data['expense'] as num).toDouble());

                balcash = balance.toStringAsFixed(AppState().noOfDecimals ?? 2);
              }
              if (Ncheqdepo.isNotEmpty && cheqhandedovr.isNotEmpty) {
                cheqhand = (((data['collection_no_cheque']) +
                            (data['last_day_balance_no_of_cheque'])) -
                        (double.parse(Ncheqdepo) + double.parse(cheqhandedovr)))
                    .toString();
              }
              if (cheqdepo.isNotEmpty && cheqhandedamt.isNotEmpty) {
                amtinhand = (((data['collection_cheque']) +
                            (data['last_day_balance_cheque_amount'])) -
                        (double.parse(cheqdepo) + double.parse(cheqhandedamt)))
                    .toStringAsFixed(AppState().noOfDecimals ?? 2);
              }
              Future<void> _showDialog(
                TextEditingController control,
                String field,
                String title,
              ) async {
                control.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: control.text.length,
                );

                String? dialogValue = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(title),
                      content: TextField(
                        controller: control,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(
                              '^\\d*\\.?\\d{0,${AppState().noOfDecimals ?? 2}}\$',
                            ),
                          ),
                        ],
                        autofocus: true,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: "Enter Amount",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          style: TextButton.styleFrom(
                            fixedSize: const Size(100, 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                            backgroundColor: AppConfig.colorPrimary,
                          ),
                          onPressed: () {
                            final enteredValue = double.tryParse(control.text);

                            if (enteredValue == null || enteredValue < 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Please enter a valid positive number"),
                                ),
                              );
                              return;
                            }

                            // Cheque deposited amount validation
                            if (field == 'cheqdepoamt') {
                              double amtssinhand = ((data['collection_cheque']
                                              as num)
                                          .toDouble() +
                                      (data['last_day_balance_cheque_amount']
                                              as num)
                                          .toDouble()) -
                                  ((num.tryParse(cheqdepo) ?? 0) +
                                      (num.tryParse(cheqhandedamt) ?? 0));

                              final maxAllowedValue = Dayclosedata != null
                                  ? double.tryParse(
                                          Dayclosedata!['cheque_amount_in_hand']
                                                  ?.toString() ??
                                              '0') ??
                                      0.0
                                  : amtssinhand;

                              if (enteredValue > maxAllowedValue) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Value cannot exceed ${_fmt(maxAllowedValue)}."),
                                  ),
                                );
                                return;
                              }
                            }

                            // Cheque count validation
                            if (field == 'Ncheqdepo' ||
                                field == 'cheqhandedovr') {
                              final chequeInHand = isdayclose == false
                                  ? Dayclosedata == null
                                      ? '0'
                                      : "${Dayclosedata!['no_of_cheque_in_hand']}"
                                  : cheqhand;

                              final chequeInHandValue =
                                  double.tryParse(chequeInHand) ?? 0;

                              double currentDeposited =
                                  double.tryParse(Ncheqdepo) ?? 0;

                              double currentHandedOver =
                                  double.tryParse(cheqhandedovr) ?? 0;

                              if (field == 'Ncheqdepo') {
                                currentDeposited = enteredValue;
                              } else {
                                currentHandedOver = enteredValue;
                              }

                              if ((currentDeposited + currentHandedOver) >
                                  chequeInHandValue) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Total cheques cannot exceed available cheques in hand $chequeInHandValue",
                                    ),
                                  ),
                                );
                                return;
                              }
                            }

                            final formattedValue =
                                (double.tryParse(control.text) ?? 0)
                                    .toStringAsFixed(
                                        AppState().noOfDecimals ?? 2);

                            Navigator.pop(context, formattedValue);
                          },
                          child: Text(
                            "OK",
                            style: TextStyle(color: AppConfig.backgroundColor),
                          ),
                        ),
                      ],
                    );
                  },
                );

                if (dialogValue != null) {
                  setState(() {
                    switch (field) {
                      case 'cashdeposit':
                        cashdeposit = dialogValue;
                        break;
                      case 'cashHanded':
                        cashHanded = dialogValue;
                        break;
                      case 'Ncheqdepo':
                        Ncheqdepo = dialogValue;
                        break;
                      case 'cheqdepoamt':
                        cheqdepo = dialogValue;
                        break;
                      case 'cheqhandedovr':
                        cheqhandedovr = dialogValue;
                        break;
                      case 'cheqhandedamt':
                        cheqhandedamt = dialogValue;
                        break;
                    }
                  });
                }
              }

              print("isdayclose: $isdayclose");
              print("Dayclosedata: ${Dayclosedata?['balance_cash_in_hand']}");
              print("balcash: $balcash");
              return Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
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
                                Text(
                                  'Hello ${AppState().name}',
                                  style: AppConfig.pageTitleStyle,
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        _attachDocuments();
                                      },
                                      child: const Icon(
                                        CupertinoIcons.paperclip,
                                        color: Colors.red,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
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
                                            '${data['no_of_sales']} | ${_fmt(data['amount_of_sales'])}',
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
                                          '${data['no_of_sales_return']} | ${_fmt(data['amount_of_sales_return'])}',
                                    )
                                  ]),
                            ),
                            Text('Collection'),
                            Text(
                              'Cash ${_fmt(data['collection_cash'])}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                                'Cheque ${_fmt(data['collection_cheque'])} | ${data['collection_no_cheque']}',
                                style: TextStyle(color: Colors.grey)),
                            Text('Last Day Balance'),
                            Text(
                              'Cash ${_fmt(data['last_day_balance_amount'])}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                                'Cheque ${data['last_day_balance_no_of_cheque']} | ${_fmt(data['last_day_balance_cheque_amount'])}',
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Petty Cash
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text('Petty Cash'),
                                   Container(
  alignment: Alignment.center,
  width: SizeConfig.safeBlockHorizontal! * 17,
  height: SizeConfig.safeBlockVertical! * 2.6,
  padding: const EdgeInsets.symmetric(horizontal: 4),
  decoration: BoxDecoration(
    color: Colors.grey.shade300,
    borderRadius: BorderRadius.circular(3),
  ),
  child: FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      _fmt(data['petty_cash']),
      textAlign: TextAlign.center,
      strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0),
    ),
  ),
),
                                    ],
                                  ),
                                  Divider(),

                                  // Expense
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text('Expense'),
                                      Container(
                                        alignment: Alignment.center,
                                        width: SizeConfig.safeBlockHorizontal! *
                                            17,
                                        height:
                                            SizeConfig.safeBlockVertical! * 2.6,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),   // Container-ൽ ചേർത്തു

child: FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    _fmt(data['expense']),
    textAlign: TextAlign.center,
    strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0),
  ),
),
                                      ),
                                    ],
                                  ),
                                  Divider(),

                                  // Cash Deposited
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text('Cash Deposited'),
                                      GestureDetector(
                                        onTap: isdayclose == false
                                            ? null
                                            : () {
                                                _showDialog(
                                                    CashDepositedcontrol,
                                                    'cashdeposit',
                                                    'Cash Deposited');
                                              },
                                        child: Container(
                                          alignment: Alignment.center,
                                          width:
                                              SizeConfig.safeBlockHorizontal! *
                                                  17,
                                          height:
                                              SizeConfig.safeBlockVertical! *
                                                  2.6,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            border:
                                                Border.all(color: Colors.grey),
                                          ),
                                        padding: const EdgeInsets.symmetric(horizontal: 4),   // Container-ൽ ചേർത്തു

child: FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    isdayclose == false
        ? Dayclosedata == null ? '' : _fmt(Dayclosedata!['cash_deposited'])
        : _fmt(cashdeposit),
    textAlign: TextAlign.center,
    strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0),
  ),
),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(),

                                  // Cash Handed Over
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text('Cash Handed Over'),
                                      GestureDetector(
                                        onTap: isdayclose == false
                                            ? null
                                            : () {
                                                _showDialog(
                                                    CashHandedOvercontrol,
                                                    'cashHanded',
                                                    'Cash Handed Over');
                                              },
                                        child: Container(
                                          alignment: Alignment.center,
                                          width:
                                              SizeConfig.safeBlockHorizontal! *
                                                  17,
                                          height:
                                              SizeConfig.safeBlockVertical! *
                                                  2.6,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              border: Border.all(
                                                  color: Colors.grey)),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),   // Container-ൽ ചേർത്തു

child: FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    isdayclose == false
        ? Dayclosedata == null ? '' : _fmt(Dayclosedata!['cash_hand_over'])
        : _fmt(cashHanded),
    textAlign: TextAlign.center,
    strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0),
  ),
),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
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
                                                          Dayclosedata?[
                                                                      'cheque_amount_in_hand']
                                                                  ?.toString() ??
                                                              '0') ??
                                                      0.0);
                                                },
                                          child: Container(
                                            alignment: Alignment.center,
                                            width: SizeConfig
                                                    .safeBlockHorizontal! *
                                                17,
                                            height:
                                                SizeConfig.safeBlockVertical! *
                                                    2.6,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                                border: Border.all(
                                                    color: Colors.grey)),
                                          padding: const EdgeInsets.symmetric(horizontal: 4),   // Container-ൽ ചേർത്തു

child: FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    isdayclose == false
        ? Dayclosedata == null ? '' : _fmt(Dayclosedata!['cheque_deposited_amount'])
        : _fmt(cheqdepo),
    textAlign: TextAlign.center,
    strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0),
  ),
),
                                          ),
                                        )
                                      ]),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                          alignment: Alignment.center,
                                          width:
                                              SizeConfig.safeBlockHorizontal! *
                                                  17,
                                          height:
                                              SizeConfig.safeBlockVertical! *
                                                  2.6,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                              border: Border.all(
                                                  color: Colors.grey)),
                                         padding: const EdgeInsets.symmetric(horizontal: 4),   // Container-ൽ ചേർത്തു

child: FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    isdayclose == false
        ? Dayclosedata == null ? '' : _fmt(Dayclosedata!['cheque_hand_over_amount'])
        : _fmt(cheqhandedamt),
    textAlign: TextAlign.center,
    strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0),
  ),
),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(),

                                  // Balance Cash in Hand
                                  // Balance Cash in Hand
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text('Balance Cash in Hand'),
                                      Container(
                                        alignment: Alignment.center,
                                        width: SizeConfig.safeBlockHorizontal! *
                                            17,
                                        height:
                                            SizeConfig.safeBlockVertical! * 2.6,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                     padding: const EdgeInsets.symmetric(horizontal: 4),   // Container-ൽ ചേർത്തു

child: FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    isdayclose == false
        ? Dayclosedata == null ? '' : _fmt(Dayclosedata!['balance_cash_in_hand'])
        : _fmt(balcash),
    textAlign: TextAlign.center,
    strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0),
  ),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text('Cheque Amount in Hand'),
                                      Container(
                                        alignment: Alignment.center,
                                        width: SizeConfig.safeBlockHorizontal! *
                                            17,
                                        height:
                                            SizeConfig.safeBlockVertical! * 2.6,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 4),   // Container-ൽ ചേർത്തു

child: FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    isdayclose == false
        ? Dayclosedata == null ? '' : _fmt(Dayclosedata!['cheque_amount_in_hand'])
        : _fmt(amtinhand),
    textAlign: TextAlign.center,
    strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0),
  ),
),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // SizedBox(width: SizeConfig.safeBlockHorizontal! * 2),
                          // Container(
                          //     decoration: BoxDecoration(
                          //         color: AppConfig.colorPrimary,
                          //         borderRadius: BorderRadius.circular(50)),
                          //     child: Padding(
                          //       padding: const EdgeInsets.all(8.0),
                          //       child: Icon(
                          //         Icons.upload,
                          //         size: 35,
                          //         color: Colors.white,
                          //       ),
                          //     )),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      _attachedImages.isEmpty
                          ? Container()
                          : Wrap(
                              children: _attachedImages.map((File file) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Stack(
                                    children: [
                                      Image.file(
                                        file,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _attachedImages.remove(file);
                                            });
                                          },
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.red,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                      SizedBox(
                        height: 30,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (isPending ||
                                      _pendingExpensesCount != 0 ||
                                      _isPosting)
                                  ? Colors.grey
                                  : AppConfig.colorPrimary,
                              minimumSize: Size(
                                  SizeConfig.safeBlockHorizontal! * 40,
                                  40), // Wider min size
                              shape: BeveledRectangleBorder(),
                            ),
                            onPressed: (isPending ||
                                    _pendingExpensesCount != 0 ||
                                    _isPosting)
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : FittedBox(
                                    child: Text("Send for Approval",
                                        style: TextStyle(color: Colors.white)),
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
    final url =
        "${RestDatasource().BASE_URL}/api/get_pending_expense?store_id=${AppState().storeId}&user_id=${AppState().userId}";

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
