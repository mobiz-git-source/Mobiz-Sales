import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobizapp/Pages/CustomeSOA.dart';
import 'package:shimmer/shimmer.dart';
import '../Components/commonwidgets.dart';

import '../Models/appstate.dart';
import '../Models/paymentcollectionclass.dart';
import '../Utilities/rest_ds.dart';
import '../Utilities/date_helper.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';

class Driver_PaymentCollectionScreen extends StatefulWidget {
  static const routeName = "/Driver_PaymentCollectionScreen";
  // final String? id;
  // final String? code;
  // final String? name;
  Driver_PaymentCollectionScreen({
    Key? key,
  }) : super(key: key);
  @override
  _Driver_PaymentCollectionScreenState createState() =>
      _Driver_PaymentCollectionScreenState();
}

int cuId = 0;
String cuname = '';
String cucode = '';
String cupay = '';
String cuoutstand = '';

class _Driver_PaymentCollectionScreenState
    extends State<Driver_PaymentCollectionScreen> {
  List<Invoice> invoices = [];

  String dropdownvalue = 'Cash';
  var items = ['Cash', 'cheque'];
  late Future<ApiResponse> futureInvoices;
  List<bool> expandedStates = [];
  TextEditingController _paidAmt = TextEditingController();
  String PaidAmt = '';
  String formattedDate = DateHelper.displayFromDateTime(DateTime.now());
  DateTime selectedChequeDate = DateTime.now();
  TextEditingController _bankController = TextEditingController();
  String bankData = '';
  TextEditingController _chequeController = TextEditingController();
  String chequeData = '';
  List<String> enteredValues = [];
  List<String> invoiceTypes = [];
  List<String> invoiceno = [];
  List<String> invoicedate = [];
  List<int> goodsTypes = [];
  List<int> invoiceid = [];

  String formatDate(String date) {
    return DateHelper.displayDate(date);
  }

  String fmt(dynamic value) {
    final n = double.tryParse(value.toString()) ?? 0;
    return n.toStringAsFixed(AppState().noOfDecimals ?? 3);
  }

// NEW: rounds a value to the app's configured decimal places
// and returns a clean numeric string (no long float tails).
  String roundedString(dynamic value) {
    final n = double.tryParse(value.toString()) ?? 0;
    final decimals = AppState().noOfDecimals ?? 3;
    return n.toStringAsFixed(decimals);
  }

// NEW: restricts typed input to N decimal places
  List<TextInputFormatter> decimalInputFormatters() {
    final decimals = AppState().noOfDecimals ?? 3;
    return [
      FilteringTextInputFormatter.allow(
        RegExp(r'^\d*\.?\d{0,' + decimals.toString() + r'}'),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    futureInvoices = fetchInvoices();
  }

  double getAllocatedAmount() {
    return enteredValues.asMap().entries.map((entry) {
      int index = entry.key;
      String value = entry.value;
      if (value.isNotEmpty) {
        double amount = double.parse(value);
        String invoiceType = invoices[index].invoiceType.toLowerCase();
        if (invoiceType == "sales") {
          return amount;
        } else if (invoiceType == "salesreturn" ||
            invoiceType == "payment_voucher") {
          return -amount;
        }
      }
      return 0.0;
    }).fold(0.0, (sum, amount) => sum + amount);
  }

  double getBalanceAmount() {
    double paidAmount = PaidAmt.isNotEmpty ? double.parse(PaidAmt) : 0;

    double allocatedAmount = enteredValues.asMap().entries.map((entry) {
      int index = entry.key;
      String value = entry.value;
      if (value.isNotEmpty) {
        double amount = double.parse(value);
        String invoiceType = invoices[index].invoiceType.toLowerCase();
        if (invoiceType == "sales") {
          return -amount;
        } else if (invoiceType == "salesreturn" ||
            invoiceType == "payment_voucher") {
          return amount;
        }
      }
      return 0.0;
    }).fold(0.0, (sum, amount) => sum + amount);

    return paidAmount + allocatedAmount;
  }

  void updateBalanceAndAllocatedAmounts() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      cuId = params!['customer'];
      cucode = params!['code'];
      cuname = params!['name'];
      cupay = params!['paymentTerms'];
      cuoutstand = params!['outstandamt'];
    }

   
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimary,
        foregroundColor: AppConfig.backgroundColor,
        title: const Text('Payment Collection'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cucode ?? ''} | ${cuname ?? ''} | ${cupay ?? ''}',
                    style:
                        const TextStyle(color: AppConfig.buttonDeactiveColor),
                  ),
                  CommonWidgets.verticalSpace(2),
                  Row(
                    children: [
                      const Text(
                        'Total outstanding',
                        style: TextStyle(color: AppConfig.buttonDeactiveColor),
                      ),
                      CommonWidgets.horizontalSpace(1),
                      _inputBox(
                          status: false,
                          value: cuoutstand == '[]' ? '' : fmt(cuoutstand)),
                      // ${_data == '[]' ? '' : _data}
                      const Spacer(),
                      const Text(
                        'Paid Amount',
                        style: TextStyle(color: AppConfig.buttonDeactiveColor),
                      ),
                      CommonWidgets.horizontalSpace(1),
                      InkWell(
                       onTap: () {

 _paidAmt.text =
    PaidAmt.isEmpty ? '' : roundedString(PaidAmt);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Paid Amount"),
        content: TextField(
          controller: _paidAmt,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: decimalInputFormatters(),
                                  onChanged: (value) {
                                    setState(() {
                                      PaidAmt = roundedString(value);
                                      updateBalanceAndAllocatedAmounts();
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    hintText: "Paid Amount",
                                  ),
                                ),
                                actions: [
                                  MaterialButton(
                                    color: AppConfig.colorPrimary,
                                    textColor: Colors.white,
                                    child: const Text("OK"),
                                   onPressed: () {
  setState(() {
    PaidAmt = roundedString(_paidAmt.text);
    _paidAmt.text = PaidAmt;
    updateBalanceAndAllocatedAmounts();
  });

  Navigator.pop(context);
}
                                  ),
                                ],
                              );
                            },
                          ).then((_) => setState(() {}));
                        },
                        child: _inputBox(
                          status: true,
                          value: PaidAmt.isEmpty ? '' : fmt(PaidAmt),
                        ),
                      ),
                    ],
                  ),
                  CommonWidgets.verticalSpace(1),
                  Row(
                    children: [
                      const Text(
                        'Allocated Amount',
                        style: TextStyle(color: AppConfig.buttonDeactiveColor),
                      ),
                      CommonWidgets.horizontalSpace(1),
                      _inputBox(
                        status: false,
                        value: fmt(getAllocatedAmount()),
                      ),
                      const Spacer(),
                      const Text(
                        'Balance Amount',
                        style: TextStyle(color: AppConfig.buttonDeactiveColor),
                      ),
                      CommonWidgets.horizontalSpace(1),
                      _inputBox(
                        status: false,
                        value: fmt(getBalanceAmount()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * .5,
              width: double.infinity,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    FutureBuilder<ApiResponse>(
                      future: futureInvoices,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Shimmer.fromColors(
                            baseColor:
                                AppConfig.buttonDeactiveColor.withOpacity(0.1),
                            highlightColor: AppConfig.backButtonColor,
                            child: Center(
                              child: Column(
                                children: [
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                ],
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.data.isEmpty) {
                          return Center(child: Text('No invoices found'));
                        } else {
                          // Initialize the expanded states
                          if (expandedStates.isEmpty) {
                            expandedStates = List<bool>.filled(
                                snapshot.data!.data.length, false);
                          }
                          if (enteredValues.length !=
                              snapshot.data!.data.length) {
                            enteredValues =
                                List.filled(snapshot.data!.data.length, '');
                          }
                          return ListView.builder(
                            scrollDirection: Axis.vertical,
                            physics: BouncingScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: snapshot.data!.data.length,
                            itemBuilder: (context, index) {
                              // Inside the itemBuilder

                              final invoice = snapshot.data!.data[index];
                              // if (invoiceTypes.contains(invoice.invoiceType)) {
                              invoiceTypes.clear();
                              goodsTypes.clear();
                              invoiceno.clear();
                              invoicedate.clear();
                              invoiceid.clear();

                              // Add the data to the lists
                              snapshot.data!.data.forEach((invoice) {
                                invoiceTypes.add(invoice.invoiceType);
                                goodsTypes.add(invoice.master_id);
                                invoiceno.add(invoice.invoiceNo);
                                invoicedate.add(invoice.invoiceDate);
                                invoiceid.add(invoice.id);
                              });
                              // }
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Card(
                                  color: AppConfig.backgroundColor,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              expandedStates[index] =
                                                  !expandedStates[index];
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(16.0),
                                            child: Column(
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        "${formatDate(invoice.invoiceDate)} | ${invoice.invoiceNo} | ${invoice.invoiceType}",
                                                        maxLines:
                                                            2, // <-- 1 alla, 2 aakku
                                                        overflow: TextOverflow
                                                            .visible,
                                                        softWrap: true,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    SizedBox(
                                                      width: 70,
                                                      child: InkWell(
                                                        onTap: () {
                                                          _showDialog(context,
                                                              index, invoice);
                                                        },
                                                        child: _inputBox(
                                                          status: false,
                                                          value: enteredValues[
                                                                      index]
                                                                  .isEmpty
                                                              ? ''
                                                              : fmt(
                                                                  enteredValues[
                                                                      index]),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Amount: ${fmt(invoice.amount)}',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey.shade600),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        'Paid: ${fmt(invoice.paid)}',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey.shade600),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        'Balance: ${fmt(invoice.balance)}',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey.shade600),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Visibility(
                                          visible: expandedStates[index],
                                          child: Container(
                                            padding: EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Column(
                                                  children: invoice.collection
                                                      .map((collection) {
                                                    return Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 18.0,
                                                          vertical: 10),
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                              '${formatDate(collection.inDate ?? '')} | ${collection.voucherNo} | ${fmt(collection.totalAmount)} | ${collection.collectionType}')
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
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
                            },
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    border: Border.all(color: AppConfig.buttonDeactiveColor)),
                width: SizeConfig.screenWidth,
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Collection Type',
                              style: TextStyle(
                                  color: AppConfig.buttonDeactiveColor),
                            ),
                            CommonWidgets.horizontalSpace(1),
                            Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: AppConfig.buttonDeactiveColor,
                                  )),
                              constraints: BoxConstraints(
                                minWidth: SizeConfig.blockSizeHorizontal * 13,
                              ),
                              height: SizeConfig.blockSizeVertical * 4,
                              child: DropdownButton(
                                alignment: Alignment.center,
                                value: dropdownvalue,
                                icon: const SizedBox(),
                                underline: const SizedBox(),
                                items: items.map((String items) {
                                  return DropdownMenuItem(
                                    value: items,
                                    child: Text(items),
                                  );
                                }).toList(),
                                // After selecting the desired option,it will
                                // change button value to selected value
                                onChanged: (String? newValue) {
                                  setState(() {
                                    dropdownvalue = newValue!;
                                  });
                                },
                              ),
                            ),
                            // _inputBox(
                            //     status: true, value: "Cheque"),
                            (dropdownvalue != "Cash")
                                ? const Spacer()
                                : Container(),
                            (dropdownvalue != "Cash")
                                ? const Text(
                                    'Bank',
                                    style: TextStyle(
                                        color: AppConfig.buttonDeactiveColor),
                                  )
                                : Container(),
                            (dropdownvalue != "Cash")
                                ? CommonWidgets.horizontalSpace(1)
                                : Container(),
                            (dropdownvalue != "Cash")
                                ? InkWell(
                                    onTap: () {
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Bank'),
                                            content: TextField(
                                              controller: _bankController,
                                              keyboardType: TextInputType.name,
                                              decoration: const InputDecoration(
                                                hintText: "Bank",
                                              ),
                                            ),
                                            actions: <Widget>[
                                              MaterialButton(
                                                color: AppConfig.colorPrimary,
                                                textColor: Colors.white,
                                                child: const Text('OK'),
                                                onPressed: () {
                                                  setState(() {
                                                    bankData =
                                                        _bankController.text;
                                                  });
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: _inputBox(
                                        status: true, value: bankData),
                                  )
                                : Container(),
                          ],
                        ),
                        CommonWidgets.verticalSpace(1),
                        (dropdownvalue != "Cash")
                            ? Row(
                                children: [
                                  const Text(
                                    'Cheque Date',
                                    style: TextStyle(
                                        color: AppConfig.buttonDeactiveColor),
                                  ),
                                  CommonWidgets.horizontalSpace(1),
                                  InkWell(
                                    onTap: () async {
                                      DateTime? pickedDate =
                                          await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime(1950),
                                              lastDate: DateTime(2100));

                                      if (pickedDate != null) {
                                        setState(() {
                                          selectedChequeDate = pickedDate;
                                          formattedDate =
                                              DateHelper.displayFromDateTime(
                                                  pickedDate);
                                        });
                                      }
                                    },
                                    child: _inputBox(
                                        status: true, value: "$formattedDate"),
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'Cheque No',
                                    style: TextStyle(
                                        color: AppConfig.buttonDeactiveColor),
                                  ),
                                  CommonWidgets.horizontalSpace(1),
                                  InkWell(
                                    onTap: () {
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Cheque No'),
                                            content: TextField(
                                              controller: _chequeController,
                                              keyboardType: TextInputType.name,
                                              decoration: const InputDecoration(
                                                hintText: "Cheque No",
                                              ),
                                            ),
                                            actions: <Widget>[
                                              MaterialButton(
                                                color: AppConfig.colorPrimary,
                                                textColor: Colors.white,
                                                child: const Text('OK'),
                                                onPressed: () {
                                                  setState(() {
                                                    chequeData =
                                                        _chequeController.text;
                                                  });
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: _inputBox(
                                        status: true, value: chequeData),
                                  ),
                                ],
                              )
                            : Container(),
                      ],
                    )),
              ),
            ),
            CommonWidgets.verticalSpace(1),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.colorPrimary, // Background color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3), // Rectangle shape
                  ),
                ),
                onPressed: () {
                  postCollectionData();
                },
                child: Text("Save", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDialog(BuildContext context, int index, Invoice invoice) {
    double invoiceBalance = invoice.balance;

    TextEditingController _amountController = TextEditingController(
      text: fmt(invoiceBalance),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Amount'),
          content: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: decimalInputFormatters(), // NEW
            controller: _amountController,
            onChanged: (value) {
              setState(() {
                if (invoice.invoiceType.toLowerCase() == 'sales') {
                  // Subtract entered amount from balance if invoice type is 'sales'
                  enteredValues[index] = value;
                } else {
                  // Add entered amount to balance if invoice type is not 'sales'
                  double currentBalance = double.parse(value) +
                      double.parse(PaidAmt.isEmpty
                          ? '0'
                          : PaidAmt) - // NEW: guard empty PaidAmt
                      getAllocatedAmount();
                  enteredValues[index] = roundedString(
                      currentBalance); // CHANGED: was currentBalance.toString()
                }
              });
            },
            decoration: InputDecoration(hintText: "Enter amount"),
          ),
          actions: <Widget>[
            MaterialButton(
              color: AppConfig.colorPrimary,
              textColor: Colors.white,
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  enteredValues[index] = roundedString(_amountController
                      .text); // CHANGED: was _amountController.text
                  updateBalanceAndAllocatedAmounts();
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _inputBox({
    required String value,
    required bool status,
  }) {
    return Container(
      width: 70, // <-- add this
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: AppConfig.buttonDeactiveColor,
        ),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Future<ApiResponse> fetchInvoices() async {
    final String url =
        '${RestDatasource().BASE_URL}/api/get_invoice_outstanding_detail?customer_id=$id';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // print('llllllllllllllllllllllllll');
      // print(id);
      ApiResponse apiResponse = ApiResponse.fromJson(jsonDecode(response.body));
      invoices = apiResponse.data;
      // Initialize enteredValues list with the length of fetched invoices
      enteredValues = List.filled(invoices.length, '');
      return apiResponse;
    } else {
      throw Exception('Failed to load invoices');
    }
  }

  Future<void> postCollectionData() async {
    final url = '${RestDatasource().BASE_URL}/api/collection.post';
    List<Map<String, dynamic>> collectionDetails = [];
    for (int i = 0; i < invoices.length; i++) {
      if (enteredValues[i].isNotEmpty) {
        collectionDetails.add({
          'InvoiceId': invoices[i].invoiceNo,
          'Amount': double.parse(enteredValues[i]),
        });
      }
    }
    List<double> processedValues = enteredValues.map((value) {
      return value.isEmpty ? 0.0 : double.parse(value);
    }).toList();
    final body = {
      'van_id': AppState().vanId,
      'store_id': AppState().storeId,
      'user_id': AppState().userId,
      'goods_out_id': goodsTypes,
      'amount': processedValues,
      'customer_id': cuId,
      'invoice_type': invoiceTypes,
      'collection_type': dropdownvalue,
      'bank': _bankController.text,
      'cheque_no': _chequeController.text,
      'cheque_date': DateHelper.apiDate(selectedChequeDate),
      'invoice_no': invoiceno,
      'invoice_date': invoicedate,
      'invoice_id': invoiceid
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      print(response.body);
      print(processedValues);
      print('dddddddddddddddd');
      // Handle success response
      print('Data posted successfully');
      if (mounted) {
        CommonWidgets.showDialogueBox(
                context: context, title: "Alert", msg: "Transaction Successful")
            .then(
          (value) {
            Navigator.pop(context);
          },
        );
      }
    } else {
      // Handle error response
      print('Failed to post data: ${response.statusCode}');
    }
  }
}

class ApiResponse {
  final List<Invoice> data;

  ApiResponse({required this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      data: List<Invoice>.from(
          json['data'].map((item) => Invoice.fromJson(item))),
    );
  }
}
