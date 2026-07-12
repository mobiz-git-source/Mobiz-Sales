import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobizapp/Pages/CustomeSOA.dart';
import 'package:mobizapp/Pages/receiptscreen.dart';
import 'package:shimmer/shimmer.dart';
import '../Components/commonwidgets.dart';

import '../Models/appstate.dart';
import '../Models/paymentcollectionclass.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'Group_Print.dart';

class PaymentCollectionScreen extends StatefulWidget {
  static const routeName = "/PaymentCollection";
  // final String? id;
  // final String? code;
  // final String? name;
  PaymentCollectionScreen({
    Key? key,
  }) : super(key: key);
  @override
  _PaymentCollectionScreenState createState() =>
      _PaymentCollectionScreenState();
}

// int? cuId;
String cuname = '';
// String cucode = '';
// String cupay = '';
// String cuoutstand = '';

class _PaymentCollectionScreenState extends State<PaymentCollectionScreen> {
  List<Invoice> invoices = [];

  String dropdownvalue = 'Cash';
  var items = ['Cash', 'cheque'];
  late Future<ApiResponse> futureInvoices;
  List<bool> expandedStates = [];
  TextEditingController _paidAmt = TextEditingController();
  String PaidAmt = '';
  String RoundOff = '';
  String formattedDate = DateFormat('dd-MMM-yyyy').format(DateTime.now());
  TextEditingController _bankController = TextEditingController();
  String bankData = '';
  TextEditingController _chequeController = TextEditingController();
  String chequeData = '';
  int? id;
  int? saleId;
  int? returnId;
  String? paydata;
  String? code;
  String? payment;
  int? pricegroupId;
  List<String> enteredValues = [];
  List<String> invoiceTypes = [];
  List<String> invoiceno = [];
  List<String> invoicedate = [];
  List<int> goodsTypes = [];
  List<int> invoiceid = [];
  final TextEditingController _roundOffController = TextEditingController();
  double roundOffValue = 0.0;
  bool group = false;
  bool isSaving = false;
  int? selectedIndex;

  String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('dd MMM yyyy').format(parsedDate);
  }

  // @override
  // void initState() {
  //   super.initState();
  //   // futureInvoices = fetchInvoices();
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _handleRouteArguments();
  //     futureInvoices = fetchInvoices();
  //   });
  // }

  @override
  void initState() {
    super.initState();
    futureInvoices =
        Future.value(ApiResponse(data: [])); // Initialize with an empty future
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRouteArguments();
      futureInvoices =
          fetchInvoices(); // Update it after handling the route arguments
    });
  }

  void _handleRouteArguments() {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      setState(() {
        // cuId = arguments['customerId'];
        code = arguments['code'] ?? '';
        cuname = arguments['name'] ?? '';
        payment = arguments['paymentTerms'] ?? '';
        // cuoutstand = arguments['outstandamt'] ?? '';
        paydata = arguments!['outstandamt'] ?? '';
        id = int.tryParse(arguments['customerId'].toString());
        pricegroupId = arguments!['price_group_id'];
        saleId = arguments!['saleId'];
        returnId = arguments!['returnId'];
        print("pricegroupId ${saleId}");
        print("returnId ${returnId}");
      });
    }
  }

  double getAllocatedAmount() {
    return enteredValues.asMap().entries.map((entry) {
      int index = entry.key;
      String value = entry.value;
      if (value.isNotEmpty) {
        double amount = double.parse(value);
        String invoiceType = invoices[index].invoiceType.toLowerCase();
        if (invoiceType == "sales" || invoiceType == "balance"||invoiceType == "salesreturn" ||
            invoiceType == "payment_voucher" ||
            invoiceType == "balance_minus") {
          return amount;
        }
        // else if (invoiceType == "salesreturn" ||
        //     invoiceType == "payment_voucher" ||
        //     invoiceType == "balance_minus") {
        //   return -amount;
        // }
      }
      return 0.0;
    }).fold(0.0, (sum, amount) => sum + amount);
  }

  // double getBalanceAmount() {
  //   double paidAmount = PaidAmt.isNotEmpty ? double.parse(PaidAmt) : 0;
  //   double roundOff = RoundOff.isNotEmpty ? double.parse(RoundOff) : 0;
  //   double allocatedAmount = enteredValues.asMap().entries.map((entry) {
  //     int index = entry.key;
  //     String value = entry.value;
  //     if (value.isNotEmpty) {
  //       double amount = double.parse(value);
  //       String invoiceType = invoices[index].invoiceType.toLowerCase();
  //       if (invoiceType == "sales" || invoiceType == "balance") {
  //         return -amount;
  //       } else if (invoiceType == "salesreturn" ||
  //           invoiceType == "payment_voucher" ||
  //           invoiceType == "balance_minus") {
  //         return amount;
  //       }
  //     }
  //     return 0.0;
  //   }).fold(0.0, (sum, amount) => sum + amount);
  //   print("BAL${paidAmount + allocatedAmount - roundOff}");
  //   print("PAy$paidAmount");
  //   print("allocated$allocatedAmount");
  //   print("roud$roundOff");
  //
  //   return paidAmount + allocatedAmount - roundOff;
  // }

  double getBalanceAmount() {
    double paidAmount = getPaidAmount();
    double roundOff = RoundOff.isNotEmpty ? double.parse(RoundOff) : 0;
    double allocatedAmount = enteredValues.asMap().entries.map((entry) {
      int index = entry.key;
      String value = entry.value;
      if (value.isNotEmpty) {
        double amount = double.parse(value);
        String invoiceType = invoices[index].invoiceType.toLowerCase();
        if (invoiceType == "sales" || invoiceType == "balance"||invoiceType == "salesreturn" ||
            invoiceType == "payment_voucher" ||
            invoiceType == "balance_minus") {
          return -amount;
        }
        // else if (invoiceType == "salesreturn" ||
        //     invoiceType == "payment_voucher" ||
        //     invoiceType == "balance_minus") {
        //   return amount;
        // }
      }
      return 0.0;
    }).fold(0.0, (sum, amount) => sum + amount);

    double balance = paidAmount + allocatedAmount - roundOff;

    // Truncate the balance to two decimal places
    balance = double.parse(balance.toStringAsFixed(AppState().noOfDecimals ?? 2));
    print("BAL $balance");
    print("PAy $paidAmount");
    print("allocated $allocatedAmount");
    print("roud $roundOff");

    return balance;
  }

  // double getPaidAmount() {
  //   String text = _paidAmt.text.trim(); // Trim whitespace
  //
  //   if (text.isEmpty) {
  //     return 0.0; // Return 0 if the input is empty
  //   }
  //
  //   // Check if the input is a valid double
  //   if (double.tryParse(text) == null) {
  //     print('Invalid number entered: $text');
  //     return 0.0;
  //   }
  //
  //   return double.parse(text);
  // }

  double getPaidAmount() {
    String text = _paidAmt.text.trim(); // Trim whitespace

    if (text.isEmpty) {
      return 0.0; // Return 0 if the input is empty
    }

    // Check if the input is a valid double
    double? amount = double.tryParse(text);
    if (amount == null) {
      print('Invalid number entered: $text');
      return 0.0; // Return 0 for invalid input
    }

    return amount; // Return the actual amount, including negatives
  }


  void updateBalanceAndAllocatedAmounts() {
    setState(() {});
  }

  double getRoundOff() {
    String text = _roundOffController.text;

    if (text.isEmpty) {
      return 0.0; // or handle the empty case as needed
    }

    try {
      return double.parse(text);
    } catch (e) {
      // Handle the error (e.g., show a message to the user)
      print('Error parsing double: $e');
      return 0.0; // or handle the invalid number case as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (ModalRoute.of(context)!.settings.arguments != null) {
    //   final Map<String, dynamic>? params =
    //       ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    //   cuId = params!['customerId'];
    //   cucode = params!['code'];
    //   cuname = params!['name'];
    //   cupay = params!['paymentTerms'];
    //   cuoutstand = params!['outstandamt'];
    //   futureInvoices = fetchInvoices();
    // }
    double allocatedAmount = getAllocatedAmount();
    double PaidAmount = getPaidAmount();
    double roundOff = getRoundOff();
    PaidAmt = _paidAmt.text;
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
                    // '${code ?? ''} | '
                        '${cuname ?? ''} | ${payment ?? ''}',
                    style:
                        const TextStyle(color: AppConfig.buttonDeactiveColor),
                  ),
                  CommonWidgets.verticalSpace(2),
                  Row(
                    children: [
                      const Text(
                        'Total Outstanding',
                        style: TextStyle(color: AppConfig.buttonDeactiveColor),
                      ),
                      CommonWidgets.horizontalSpace(1),
                      _inputBox(
                        status: false,
                        value:
                        "${paydata == '[]' || paydata == null ? '' : (double.tryParse(paydata!)?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '')}"
                      ),

                      // ${_data == '[]' ? '' : _data}
                      const Spacer(),
                      const Text(
                        'Paid Amount',
                        style: TextStyle(color: AppConfig.buttonDeactiveColor),
                      ),
                      CommonWidgets.horizontalSpace(1),
                      InkWell(
                        onTap: () {
                          showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Paid Amount'),
                                  content: TextField(
                                    onChanged: (value) {
                                      setState(() {
                                        PaidAmt = value;
                                        updateBalanceAndAllocatedAmounts();
                                      });
                                    },
                                    keyboardType: TextInputType.number,
                                    controller: _paidAmt,
                                    decoration: const InputDecoration(
                                        hintText: "Paid Amount"),
                                  ),
                                  actions: <Widget>[
                                    MaterialButton(
                                      color: AppConfig.colorPrimary,
                                      textColor: Colors.white,
                                      child: const Text('OK'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        setState(() {
                                          updateBalanceAndAllocatedAmounts();
                                        });
                                      },
                                    ),
                                  ],
                                );
                              }).then((value) => setState(() {}));
                        },
                        child: _inputBox(status: true, value: (PaidAmt ?? '')),
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
                          value: getAllocatedAmount().toStringAsFixed(AppState().noOfDecimals ?? 2)),
                      const Spacer(),
                      const Text(
                        'Balance Amount',
                        style: TextStyle(color: AppConfig.buttonDeactiveColor),
                      ),
                      CommonWidgets.horizontalSpace(1),
                      _inputBox(
                          status: false, value: getBalanceAmount().toString()),
                    ],
                  ),
                  CommonWidgets.verticalSpace(1),
                  Row(
                    children: [
                      Text(
                        'Round Off',
                        style: TextStyle(color: AppConfig.buttonDeactiveColor),
                      ),
                      CommonWidgets.horizontalSpace(1),
                      // Editable input for Round Off
                      InkWell(
                        onTap: () {
                          showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Round Off'),
                                  content: TextField(
                                    onChanged: (value) {
                                      setState(() {
                                        RoundOff = value;
                                        getRoundOff();
                                      });
                                    },
                                    keyboardType: TextInputType.number,
                                    controller: _roundOffController,
                                    decoration: const InputDecoration(
                                        hintText: "Round Off"),
                                  ),
                                  actions: <Widget>[
                                    MaterialButton(
                                      color: AppConfig.colorPrimary,
                                      textColor: Colors.white,
                                      child: const Text('OK'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        setState(() {
                                          getRoundOff();
                                        });
                                      },
                                    ),
                                  ],
                                );
                              }).then((value) => setState(() {}));
                        },
                        child: _inputBox(status: true, value: (RoundOff ?? '')),
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

                              String formatInvoiceType(String invoiceType) {
                                if (invoiceType.toLowerCase() ==
                                    "payment_voucher") {
                                  return "Payment";
                                }
                                if (invoiceType.toLowerCase() ==
                                    "salesreturn") {
                                  return "Sales Return";
                                }
                                return invoiceType
                                    .split(
                                        '_') // Split by underscore if the type uses underscores (e.g., "sales_invoice")
                                    .map((word) =>
                                        word[0].toUpperCase() +
                                        word
                                            .substring(1)
                                            .toLowerCase()) // Capitalize first letter
                                    .join(' ');
                              }

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
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                        "${(invoice.invoiceDate)} | ${invoice.invoiceNo} | ${formatInvoiceType(invoice.invoiceType)}"),
                                                    InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          selectedIndex =
                                                              index; // Track the selected index
                                                        });
                                                        _showDialog(context,
                                                            index, invoice);
                                                      },
                                                      child: _inputBox(
                                                        status: false,
                                                        value: enteredValues[
                                                            index],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        'Amount: ${invoice.amount} | Paid: ${invoice.paid} | Balance: ${invoice.amount - invoice.paid}',
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
                                                              '${formatDate(collection.inDate)} | ${collection.voucherNo} | ${collection.amount} | ${collection.collectionType}')
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
                                items: items.map((String item) {
                                  String capitalizedItem =
                                      item[0].toUpperCase() + item.substring(1);
                                  return DropdownMenuItem(
                                    value: item,
                                    child: Text(capitalizedItem),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    dropdownvalue = newValue!;
                                  });
                                },
                              ),
                            ),
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
                                        formattedDate = DateFormat('dd-MM-yyyy')
                                            .format(pickedDate);
                                      } else {}
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.colorPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  onPressed: (!isSaving &&
                      (
                          (PaidAmount > 0 && (PaidAmount - roundOff == allocatedAmount)) ||
                              (getBalanceAmount() == 0.0 &&
                                  selectedIndex != null &&
                                  enteredValues[selectedIndex!].isNotEmpty)
                      ))
                      ? () async {
                    setState(() {
                      isSaving = true;
                    });

                    try {
                      await postCollectionData();
                    } catch (e) {
                      print(e);
                    }

                    if (mounted) {
                      setState(() {
                        isSaving = false;
                      });
                    }
                  }
                      : null,
                  child: Text(
                    isSaving ? "Saving..." : "Save",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                saleId != null
                    ?
                ElevatedButton(
                  style: ButtonStyle(
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                      backgroundColor:
                          WidgetStatePropertyAll(AppConfig.colorPrimary)),
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      GroupPrint.routeName, // Replace with the actual route name
                      arguments: {
                        'price_group_id': pricegroupId,
                        'saleId': saleId,
                        'returnId': returnId,
                        // 'payId': payId;
                      },
                    );
                  },
                  child: Text(
                          "SKIP",
                          style: TextStyle(color: Colors.white),
                        )
                ):SizedBox.shrink()
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDialog(BuildContext context, int index, Invoice invoice) {
    double invoiceBalance = invoice.amount - invoice.paid;

    TextEditingController _amountController = TextEditingController(
      text: invoiceBalance.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Amount'),
          content: TextField(
            keyboardType: TextInputType.number,
            controller: _amountController,
            onChanged: (value) {
              setState(() {
                if (invoice.invoiceType.toLowerCase() == 'sales') {
                  enteredValues[index] = value;
                } else {
                  double parsedValue = double.tryParse(value) ?? 0.0;
                  double parsedPaidAmt = double.tryParse(PaidAmt) ?? 0.0;
                  double currentBalance = parsedValue + parsedPaidAmt - getAllocatedAmount();
                  enteredValues[index] = currentBalance.toStringAsFixed(AppState().noOfDecimals ?? 2);
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
                  enteredValues[index] = _amountController.text;
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
      // padding: EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: AppConfig.buttonDeactiveColor,
        ),
      ),
      constraints: BoxConstraints(
        minWidth: SizeConfig.blockSizeHorizontal * 13,
        minHeight: SizeConfig.blockSizeVertical * 3,
      ),
      child: Text(
        textAlign: TextAlign.center,
        value,
        style: TextStyle(
          color: status ? AppConfig.textBlack : AppConfig.buttonDeactiveColor,
        ),
      ),
    );
  }

  Future<ApiResponse> fetchInvoices() async {
    final String url =
        '${RestDatasource().BASE_URL}/api/get_invoice_outstanding_detail?customer_id=$id';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print(response.request);
      print("objectIIDD");
      print(id.toString());
      ApiResponse apiResponse = ApiResponse.fromJson(jsonDecode(response.body));
      invoices = apiResponse.data;
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
      return value.isEmpty
          ? 0.0
          : double.parse(double.parse(value).toStringAsFixed(AppState().noOfDecimals ?? 2));
    }).toList();

    final body = {
      'allocation_amount': getPaidAmount(),
      'round_off': _roundOffController.text,
      'van_id': AppState().vanId,
      'store_id': AppState().storeId,
      'user_id': AppState().userId,
      'goods_out_id': goodsTypes,
      'amount': processedValues,
      'customer_id': id,
      'invoice_type': invoiceTypes,
      'collection_type': dropdownvalue,
      'bank': _bankController.text,
      'cheque_no': _chequeController.text,
      'cheque_date': formattedDate,
      'invoice_no': invoiceno,
      'invoice_date': invoicedate,
      'invoice_id': invoiceid,
    };
    log('Request Body: ${json.encode(body)}');
    print('processedValues');
    print(processedValues);

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
print(response.body);
print(AppState().storeId);
    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      if (responseBody['success'] == true) {
        print('Data posted successfully');

        int? payId;
        if (responseBody['data'].isNotEmpty) {
          payId = responseBody['data'][0]['id'];
        }

        setState(() {
          isSaving = false;
        });

        if (pricegroupId != null) {
          Navigator.pushReplacementNamed(
            context,
            GroupPrint.routeName,
            arguments: {
              'price_group_id': pricegroupId,
              'saleId': saleId,
              'returnId': returnId,
              'payId': payId,
            },
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            ReceiptScreen.receiptScreen,
          );
        }
      } else {
        print('Failed: success is false');
        // ✅ Show SnackBar with API error message
        String errorMessage = responseBody['messages'] != null &&
            responseBody['messages'].isNotEmpty
            ? responseBody['messages'][0]
            : 'Something went wrong';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }

        setState(() {
          isSaving = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed: ${response.body.toString()}")));
    }
  }


// Future<void> postCollectionData() async {
  //   final url = '${RestDatasource().BASE_URL}/api/collection.post';
  //   List<Map<String, dynamic>> collectionDetails = [];
  //   for (int i = 0; i < invoices.length; i++) {
  //     if (enteredValues[i].isNotEmpty) {
  //       collectionDetails.add({
  //         'InvoiceId': invoices[i].invoiceNo,
  //         'Amount': double.parse(enteredValues[i]),
  //       });
  //     }
  //   }
  //   List<double> processedValues = enteredValues.map((value) {
  //     return value.isEmpty
  //         ? 0.0
  //         : double.parse(double.parse(value).toStringAsFixed(AppState().noOfDecimals ?? 2));
  //   }).toList();
  //
  //   final body = {
  //     'allocation_amount': getPaidAmount(),
  //     'round_off': _roundOffController.text,
  //     'van_id': AppState().vanId,
  //     'store_id': AppState().storeId,
  //     'user_id': AppState().userId,
  //     'goods_out_id': goodsTypes,
  //     'amount': processedValues,
  //     'customer_id': id,
  //     'invoice_type': invoiceTypes,
  //     'collection_type': dropdownvalue,
  //     'bank': _bankController.text,
  //     'cheque_no': _chequeController.text,
  //     'cheque_date': formattedDate,
  //     'invoice_no': invoiceno,
  //     'invoice_date': invoicedate,
  //     'invoice_id': invoiceid
  //   };
  //   print('Request Body: ${json.encode(body)}');
  //   print('processedValues');
  //   print(processedValues);
  //   final response = await http.post(
  //     Uri.parse(url),
  //     headers: {
  //       'Content-Type': 'application/json',
  //     },
  //     body: json.encode(body),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     print(response.body);
  //     print("SSDSDS$processedValues");
  //     var responseBody = json.decode(response.body);
  //     int payId = responseBody['data'][0]['id'];
  //     print('Data posted successfully');
  //     if (mounted) {
  //       setState(() {
  //         isSaving = false;
  //       });
  //       Future.delayed(Duration(milliseconds: 100), () {
  //         CommonWidgets.showDialogueBox(
  //                 context: context,
  //                 title: "Alert",
  //                 msg: "Transaction Successful")
  //             .then((value) {
  //           if (pricegroupId != null) {
  //             Navigator.pushReplacementNamed(
  //               context,
  //               GroupPrint.routeName, // Replace with the actual route name
  //               arguments: {
  //                 'price_group_id': pricegroupId,
  //                 'saleId': saleId,
  //                 'returnId': returnId,
  //                 'payId': payId
  //               },
  //             );
  //           } else {
  //             Navigator.pushReplacementNamed(
  //               context,
  //               ReceiptScreen.receiptScreen,
  //             );
  //           }
  //         });
  //       });
  //     }
  //   } else {
  //     print('Failed to post data: ${response.statusCode}');
  //   }
  // }
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
