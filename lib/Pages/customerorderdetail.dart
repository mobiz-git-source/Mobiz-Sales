import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/homeorder.dart';
import 'package:mobizapp/Pages/salesselectproductorder.dart';
import 'package:mobizapp/vanstockselactpro_tst.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Components/commonwidgets.dart';
import '../Models/sales_model.dart';
import 'package:http/http.dart' as http;

import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';

class Customerorderdetail extends StatefulWidget {
  static const routeName = "/Customerorderdetail";
  @override
  _CustomerorderdetailState createState() => _CustomerorderdetailState();
}

int? id;

class _CustomerorderdetailState extends State<Customerorderdetail> {
  var attendanceData;
  List<Map<String, dynamic>> savedProducts = [];
  final TextEditingController _remarksController = TextEditingController();
  bool _isPercentage = false;
  final TextEditingController _discountData = TextEditingController();
  final TextEditingController _roundoff = TextEditingController();
  double totalAmount = 0.0;
  double roundOffValue = 0.0;
  String _remarksText = "";
  List<ProductType> productTypes = [];
  List<ProductType?> selectedProductTypes = [];
  TextEditingController _searchData = TextEditingController();
  bool _search = false;
  int _ifVat = 1;
  bool Status = false;
  String? name;
  bool _isButtonDisabled = false;
  bool _isDialogOpen = false;
  String roundoff = '';
  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadSavedProducts();
    fetchProductTypes();
    fetchCheckInDetail();
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Attendance Required',
            style: TextStyle(color: Colors.red),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Please Check-IN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style:
                  TextButton.styleFrom(backgroundColor: AppConfig.colorPrimary),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onSaveButtonPressed() {
    setState(() {
      _isButtonDisabled = true; // Disable the button after it's pressed
    });
  }

  DateTime? _selectedDate;
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate)
      setState(() {
        _selectedDate = pickedDate;
      });
  }

  Future<void> _removeProduct(int index) async {
    setState(() {
      savedProducts.removeAt(index);
      // Recalculate total amount
      totalAmount = savedProducts.fold(0.0, (sum, product) {
        final quantity =
            double.tryParse(product['quantity']?.toString() ?? '0') ?? 0.0;
        final amount =
            double.tryParse(product['amount']?.toString() ?? '0') ?? 0.0;
        return sum + (quantity * amount);
      });
    });

    final prefs = await SharedPreferences.getInstance();
    final savedProductsStringList =
        savedProducts.map((product) => jsonEncode(product)).toList();
    await prefs.setStringList('selected_products', savedProductsStringList);
  }

  double calculateTax() {
    double tax = 0;
    for (int index = 0; index < savedProducts.length; index++) {
      String discountValue = _discountData.text.trim();
      double discountAmount = double.tryParse(discountValue) ?? 0;
      double amt = totalAmount - discountAmount;
      double discountfrtax = (totalAmount * discountAmount) / 100;
      double netTotal = totalAmount - discountfrtax;
      num taxPercentage = 5;
      double Tax = _isPercentage
          ? ((netTotal * taxPercentage) / 100)
          : (amt * taxPercentage) / 100;
      tax = Tax;
    }
    return double.parse(tax.toStringAsFixed(AppState().noOfDecimals ?? 2));
  }



  Map<String, dynamic> CalculatedValue() {
    double taxamt = calculateTax();
    roundoff = _roundoff.text;
    double rundff = double.tryParse(roundoff) ?? 0;
    String discountValue = _discountData.text.trim();
    double discountAmount = double.tryParse(discountValue) ?? 0;
    double totalTax = 5;
    double discountinpercent = (totalAmount * discountAmount) / 100;
    double nettotal = totalAmount - discountinpercent;
    double taxamtperc = (nettotal * totalTax) / 100;
    double grandTotal = _ifVat == 1
        ? _isPercentage
            ? totalAmount - ((totalAmount * discountAmount) / 100) + taxamtperc
            : (totalAmount - discountAmount) + taxamt
        : _isPercentage
            ? totalAmount - (totalAmount * discountAmount) / 100
            : totalAmount - discountAmount;
    num roundedGrandTotal1 =
        roundoff == '' ? customRound(grandTotal) : grandTotal + rundff;
    double roundOffValue = roundedGrandTotal1 - grandTotal;
    return {
      'rounded': roundedGrandTotal1,
      'roundOffValue': roundOffValue,
    };
  }

  Future<void> _loadSavedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedProductsStringList =
        prefs.getStringList('selected_products');

    if (savedProductsStringList != null) {
      setState(() {
        savedProducts = savedProductsStringList
            .map((productString) =>
                jsonDecode(productString) as Map<String, dynamic>)
            .toList();

        // Calculate total amount
        totalAmount = savedProducts.fold(0.0, (sum, product) {
          final quantity =
              double.tryParse(product['quantity']?.toString() ?? '0') ?? 0.0;
          final amount =
              double.tryParse(product['amount']?.toString() ?? '0') ?? 0.0;
          return sum + (quantity * amount);
        });
      });
    }
  }

  Future<void> clearCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_products');
    setState(() {
      savedProducts.clear();
    });
  }

  void _updateCalculations() {
    setState(() {
      totalAmount = savedProducts.fold(0.0, (sum, product) {
        final quantity =
            double.tryParse(product['quantity']?.toString() ?? '0') ?? 0.0;
        final amount =
            double.tryParse(product['amount']?.toString() ?? '0') ?? 0.0;
        return sum + (quantity * amount);
      });
      // Update other relevant state variables or perform additional actions
    });
  }

  Future<void> fetchProductTypes() async {
    try {
      final response = await http
          .get(Uri.parse('${RestDatasource().BASE_URL}/api/get_product_type'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<ProductType> loadedProductTypes = [];

        for (var item in data['data']) {
          loadedProductTypes.add(ProductType.fromJson(item));
        }

        setState(() {
          productTypes = loadedProductTypes;
        });
      } else {
        throw Exception('Failed to load product types');
      }
    } catch (e) {
      print('Error fetching product types: $e');
    }
  }

  int customRound(double value) {
    double fractionalPart = value - value.toInt();

    if (fractionalPart >= 0.5) {
      return value.ceil();
    } else {
      return value.floor();
    }
  }

  Future<void> fetchCheckInDetail() async {
    final String url =
        '${RestDatasource().BASE_URL}/api/get_today_check_in_detail?van_id=${AppState().vanId}&store_id=${AppState().storeId}&user_id=${AppState().userId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          attendanceData = json.decode(response.body);
          Status = data['success'] == true;
          AppState().attendanceState == 'Required'
              ? Status &&
                      attendanceData != null &&
                      attendanceData['data']['check_out'] == 0
                  ? SizedBox.shrink()
                  : WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showWelcomeDialog();
                    })
              : SizedBox.shrink();
        });
      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _onBackPressed() async {
    clearCart();
    // Your custom function logic here
    print('Back button pressed');
    // You can also show a dialog, navigate to another page, etc.
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> grandTotalMap = CalculatedValue();

    double tax = _ifVat == 1 ? calculateTax() : 0;
    String taxpost = tax.toStringAsFixed(AppState().noOfDecimals ?? 2);
    double roundedGrandTotal = double.parse(double.parse(grandTotalMap['rounded'].toString()).toStringAsFixed(AppState().noOfDecimals ?? 2));
    double roundOffValue = double.parse(double.parse(grandTotalMap['roundOffValue'].toString()).toStringAsFixed(AppState().noOfDecimals ?? 2));
    double total;
    if (ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      id = params!['customerId'];
      name = params['name'];
    }
    void postDataToApi() async {
      setState(() {
        _isButtonDisabled = true;
      });

      try {
        var url =
        Uri.parse('${RestDatasource().BASE_URL}/api/vansales_order.store');

        List<int> productIds = savedProducts.map<int>((product) {
          return product['id'];
        }).toList();
        List<int> unitIds = savedProducts.map<int>((product) {
          // Assuming product['unit_id'] already contains the selected unit ID
          return int.parse(product['unit_id']);
        }).toList();
        List<double> amounts = savedProducts.map<double>((product) {
          return double.parse(
              double.parse(product['amount'].toString()).toStringAsFixed(AppState().noOfDecimals ?? 2));
        }).toList();
        List<double> quantity = savedProducts.map<double>((product) {
          return double.parse(product['quantity'].toString());
        }).toList();
        List<String> description = savedProducts.map<String>((product) {
          return product['description'].toString();
        }).toList();
        List<int> productTypes = savedProducts.map<int>((product) {
          return int.parse(product['type_id']);
        }).toList();
        var data = {
          'van_id': AppState().vanId,
          'store_id': AppState().storeId,
          'user_id': AppState().userId,
          'item_id': productIds,
          'quantity': quantity,
          'unit': unitIds,
          'mrp': amounts,
          'discount_type': _isPercentage ? 'percentage' : 'amount',
          'customer_id': id,
          'if_vat': _ifVat == 1 ? 1 : 0,
          'product_type': productTypes,
          'total_tax': taxpost,
          "discount": _discountData.text.isEmpty ? '0' : _discountData.text,
          "total": totalAmount,
          "round_off": roundOffValue,
          "grand_total": roundedGrandTotal,
          'remarks': _remarksText,
          'scheduled_date': _selectedDate.toString(),
          'description':description,
          'delivery_location':_remarksController.text.isEmpty?'':_remarksController.text
        };
        var body = json.encode(data);

        var response = await http.post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: body,
        );

        if (response.statusCode == 200) {
          print("Description $description");
          print("Details: $data");
          print("amountsToPost: $amounts");
          print("roundedGrandTotal: $roundedGrandTotal");
          print("roundOffValueToPost: $roundOffValue");
          print("taxpost: $taxpost");
          print("Details: $_ifVat");
          print("_remarksText: $_remarksText");
          // print(_isPercentage ? '1' : '0');
          // print('fjnvjksdnvsbjvnsjkvhSDhv');
          // print(cartItems.map((item) => item.price).toList());
          // print(AppState().storeId);
          print('Post successful');
          if (mounted) {
            CommonWidgets.showDialogueBox(
                context: context, title: "Alert", msg: "Created Successfully")
                .then(
                  (value) {
                clearCart();
                Navigator.pushReplacementNamed(
                  context,
                  HomeorderScreen.routeName,
                );
              },
            );
          }
          print(response.body);
        } else {
          print('Post failed with status: ${response.statusCode}');
          print(response.body);
        }
      }catch (e) {
        print('An error occurred: $e');
      } finally {
        setState(() {
          _isButtonDisabled = false;  // Re-enable the button after the request completes (whether it succeeds or fails)
        });
      }
    }
    return WillPopScope(
      onWillPop: () async {
        // Call your custom function here
        await _onBackPressed();
        // Return true to allow the page to be popped
        // Return false to prevent the page from being popped
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                // clearSharedPreferences();
                clearCart();
              },
              child: Icon(Icons.arrow_back_rounded)),
          iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
          title: const Text(
            'Order',
            style: TextStyle(color: AppConfig.backgroundColor),
          ),
          backgroundColor: AppConfig.colorPrimary,
          actions: [
            (_search)
                ? Container(
                    height: SizeConfig.blockSizeVertical * 5,
                    width: SizeConfig.blockSizeHorizontal * 76,
                    decoration: BoxDecoration(
                      color: AppConfig.colorPrimary,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10),
                      ),
                      border: Border.all(color: AppConfig.colorPrimary),
                    ),
                    child: TextField(
                      controller: _searchData,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(5),
                        hintText: "Search...",
                        hintStyle: TextStyle(color: AppConfig.backgroundColor),
                        border: InputBorder.none,
                      ),
                    ),
                  )
                : Container(),
            CommonWidgets.horizontalSpace(1),
            // AppState().rolId == 5
            //     ? GestureDetector(
            //         onTap: () {
            //           Navigator.pushReplacementNamed(
            //                   context, SalesSelectProductsorderScreen.routeName,
            //                   arguments: {'customerId': id, 'name': name})
            //               .then((value) {
            //             // _initDone = false;
            //             // _getTypes();
            //           });
            //         },
            //         child: Icon(
            //           _search ? Icons.close : Icons.search,
            //           size: 30,
            //           color: AppConfig.backgroundColor,
            //         ),
            //       )
            //     :
            AppState().attendanceState == 'Required'
                    ? Status &&
                            attendanceData != null &&
                            attendanceData['data']['check_out'] == 0
                        ? GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context,
                                  SalesSelectProductsorderScreen.routeName,
                                  arguments: {
                                    'customerId': id,
                                    'name': name
                                  }).then((value) {
                                // _initDone = false;
                                // _getTypes();
                              });
                            },
                            child: Icon(
                              _search ? Icons.close : Icons.search,
                              size: 30,
                              color: AppConfig.backgroundColor,
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              _showWelcomeDialog();
                            },
                            child: Text(
                              'Attendance Req...',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                    : GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                              context, SalesSelectProductsorderScreen.routeName,
                              arguments: {
                                'customerId': id,
                                'name': name
                              }).then((value) {
                            // _initDone = false;
                            // _getTypes();
                          });
                        },
                        child: Icon(
                          _search ? Icons.close : Icons.search,
                          size: 30,
                          color: AppConfig.backgroundColor,
                        ),
                      ),
            CommonWidgets.horizontalSpace(3),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          width: 100.w,
          height: 30.h,
          child: ElevatedButton(
            style: ButtonStyle(
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7.0),
                ),
              ),
              backgroundColor: WidgetStateProperty.all(
                savedProducts.isNotEmpty && !_isButtonDisabled
                    ? AppConfig.colorPrimary
                    : AppConfig.buttonDeactiveColor,
              ),
            ),
            onPressed: _isButtonDisabled || savedProducts.isEmpty
                ? null
                : () async {
              postDataToApi();
            },
            child: Text(
              'SAVE',
              style: TextStyle(
                  fontSize: AppConfig.textCaption3Size,
                  color: AppConfig.backgroundColor,
                  fontWeight: AppConfig.headLineWeight),
            ),
          ),
        ),
        body: savedProducts.isEmpty
            ? Center(child: Text('No saved products'))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Text(
                          (name ?? '').toUpperCase(),
                          style: TextStyle(
                            fontSize: AppConfig.textCaption3Size,
                            color: AppConfig.buttonDeactiveColor,
                          ),
                        ),
                        const Spacer(),
                        AppState().vatState != 'Disable'
                            ? Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _ifVat = 1;
                                      });
                                      total = 0;
                                      tax = 0;
                                      // _calculateTotal();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.black),
                                          color: (_ifVat == 1)
                                              ? AppConfig.colorPrimary
                                              : AppConfig.backButtonColor,
                                          borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(3),
                                              bottomLeft: Radius.circular(3))),
                                      width:
                                          SizeConfig.blockSizeHorizontal * 13,
                                      height: SizeConfig.blockSizeVertical * 3,
                                      child: Center(
                                        child: Text(
                                          'VAT',
                                          style: TextStyle(
                                            fontSize:
                                                AppConfig.textCaption3Size,
                                            color: (_ifVat == 1)
                                                ? AppConfig.backButtonColor
                                                : AppConfig.textBlack,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _ifVat = 0;
                                      });
                                      total = 0;
                                      tax = 0;
                                      // _calculateTotal();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.black),
                                          color: (_ifVat == 0)
                                              ? AppConfig.colorPrimary
                                              : AppConfig.backButtonColor,
                                          borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(3),
                                              bottomRight: Radius.circular(3))),
                                      width:
                                          SizeConfig.blockSizeHorizontal * 13,
                                      height: SizeConfig.blockSizeVertical * 3,
                                      child: Center(
                                        child: Text(
                                          'NO VAT',
                                          style: TextStyle(
                                            fontSize:
                                                AppConfig.textCaption3Size,
                                            color: (_ifVat == 0)
                                                ? AppConfig.backButtonColor
                                                : AppConfig.textBlack,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox.shrink()
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.0.w),
                    child: Row(
                      children: [
                        Text('Schedule Date'),
                        SizedBox(
                          width: 10,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2.0),
                              child: Text(
                                _selectedDate == null
                                    ? 'Select Date'
                                    : DateFormat('dd/MM/yyyy')
                                        .format(_selectedDate!),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                            onPressed: () {
                              _selectDate(context);
                            },
                            icon: Icon(CupertinoIcons.calendar_today))
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * .550,
                    child: ListView.builder(
                      physics: BouncingScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: savedProducts.length,
                      itemBuilder: (context, index) {
                        final product = savedProducts[index];
                        final quantity = double.tryParse(
                                product['quantity']?.toString() ?? '0') ??
                            0.0;
                        final amount = double.tryParse(
                                product['amount']?.toString() ?? '0') ??
                            0.0;

                        final total = quantity * amount;
                        return InkWell(
                          onTap: _isDialogOpen
                              ? null
                              : () {
                                  setState(() {
                                    _isDialogOpen = true;
                                  });
                                  showProductDetailsDialog(context, product);
                                },
                          child: Card(
                            elevation: 1,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              width: SizeConfig.blockSizeHorizontal * 90,
                              decoration: BoxDecoration(
                                color: AppConfig.backgroundColor,
                                border: Border.all(
                                  color: AppConfig.buttonDeactiveColor
                                      .withOpacity(0.5),
                                ),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(10)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // SizedBox(
                                      //   width: 50,
                                      //   height: 60,
                                      //   child: ClipRRect(
                                      //     borderRadius: BorderRadius.circular(10),
                                      //     child: FadeInImage(
                                      //       image: NetworkImage(
                                      //         '${RestDatasource().Product_URL}/uploads/product/${product['proImage']}',
                                      //       ),
                                      //       placeholder: const AssetImage(
                                      //           'Assets/Images/no_image.jpg'),
                                      //       imageErrorBuilder:
                                      //           (context, error, stackTrace) {
                                      //         return Image.asset(
                                      //           'Assets/Images/no_image.jpg',
                                      //           fit: BoxFit.fitWidth,
                                      //         );
                                      //       },
                                      //       fit: BoxFit.fitWidth,
                                      //     ),
                                      //   ),
                                      // ),
                                      // CommonWidgets.horizontalSpace(1),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${product['code']} | ${product['name'].toString().toUpperCase()}',
                                              style: TextStyle(
                                                  fontSize: AppConfig
                                                      .textCaption3Size,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      CircleAvatar(
                                        backgroundColor:
                                            Colors.grey.withOpacity(0.2),
                                        radius: 10,
                                        child: GestureDetector(
                                          onTap: () => _removeProduct(index),
                                          child: const Icon(
                                            Icons.close,
                                            size: 15,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5.h),
                                  Row(
                                    children: [
                                      Text(product['type_name']),
                                      Text(' | '),
                                      Text(product['unit_name']),
                                      Text(' | '),
                                      Text('Qty: ${product['quantity']}'),
                                      Text(' | '),
                                      Text('Rate: ${product['amount']}'),
                                      Text(' | '),
                                      Text('Amt: ${total.toStringAsFixed(AppState().noOfDecimals ?? 2)}')
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 18.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Delivery Location",
                              style: TextStyle(
                                fontSize: AppConfig.textCaption3Size,
                              ),
                            ),
                            SizedBox(
                              width: 2,
                            ),
                            InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Delivery Location'),
                                      content: TextField(
                                        controller: _remarksController,
                                        onChanged: (value) {
                                          setState(() {
                                            _remarksText = value;
                                          });
                                        },
                                        keyboardType: TextInputType.text,
                                        decoration: const InputDecoration(
                                          hintText: "Enter your location",
                                        ),
                                      ),
                                      actions: <Widget>[
                                        MaterialButton(
                                          color: AppConfig.colorPrimary,
                                          textColor: Colors.white,
                                          child: const Text('OK'),
                                          onPressed: () {
                                            setState(() {
                                              _remarksText =
                                                  _remarksController.text;
                                            });
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.67,
                                // padding: EdgeInsets.symmetric(
                                //     horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppConfig.buttonDeactiveColor),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(5)),
                                ),
                                child: Center(
                                  child: Text(
                                    _remarksText,
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        AppState().discountState != 'Disable'
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Discount ',
                                    style: TextStyle(
                                      fontSize: AppConfig.textCaption3Size,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => setState(() {
                                      _isPercentage = !_isPercentage;
                                    }),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.black),
                                          color: (!_isPercentage)
                                              ? AppConfig.colorPrimary
                                              : AppConfig.backButtonColor,
                                          borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(3),
                                              bottomLeft: Radius.circular(3))),
                                      width:
                                          SizeConfig.blockSizeHorizontal * 24,
                                      height: SizeConfig.blockSizeVertical * 3,
                                      child: Center(
                                        child: Text(
                                          'AMOUNT',
                                          style: TextStyle(
                                            fontSize:
                                                AppConfig.textCaption3Size,
                                            color: (!_isPercentage)
                                                ? AppConfig.backButtonColor
                                                : AppConfig.textBlack,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => setState(() {
                                      _isPercentage = !_isPercentage;
                                    }),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.black),
                                          color: (_isPercentage)
                                              ? AppConfig.colorPrimary
                                              : AppConfig.backButtonColor,
                                          borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(3),
                                              bottomRight: Radius.circular(3))),
                                      width:
                                          SizeConfig.blockSizeHorizontal * 24,
                                      height: SizeConfig.blockSizeVertical * 3,
                                      child: Center(
                                          child: Text(
                                        'PERCENTAGE',
                                        style: TextStyle(
                                          fontSize: AppConfig.textCaption3Size,
                                          color: (_isPercentage)
                                              ? AppConfig.backButtonColor
                                              : AppConfig.textBlack,
                                        ),
                                      )),
                                    ),
                                  ),
                                  CommonWidgets.horizontalSpace(2),
                                  InkWell(
                                    onTap: () {
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text('Discount'),
                                              content: TextField(
                                                keyboardType:
                                                    TextInputType.number,
                                                controller: _discountData,
                                                decoration:
                                                    const InputDecoration(
                                                        hintText: "Discount"),
                                              ),
                                              actions: <Widget>[
                                                MaterialButton(
                                                  color: AppConfig.colorPrimary,
                                                  textColor: Colors.white,
                                                  child: const Text('OK'),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ],
                                            );
                                          });
                                    },
                                    child: Container(
                                        width:
                                            SizeConfig.blockSizeHorizontal * 17,
                                        height:
                                            SizeConfig.blockSizeVertical * 3,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: AppConfig
                                                    .buttonDeactiveColor),
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(5))),
                                        child: Center(
                                          child: Text(_discountData.text.isEmpty
                                              ? ''
                                              : _discountData.text),
                                        )),
                                  ),
                                ],
                              )
                            : SizedBox.shrink(),
                        Text('Total: ${totalAmount.toStringAsFixed(AppState().noOfDecimals ?? 2)}'),
                        Text('Tax: ${tax.toStringAsFixed(AppState().noOfDecimals ?? 2)}'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Round off:'),
                            InkWell(
                              onTap: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Round off'),
                                        content: TextField(
                                          keyboardType: TextInputType.number,
                                          controller: _roundoff,
                                          decoration: const InputDecoration(
                                              hintText: "Round off"),
                                        ),
                                        actions: <Widget>[
                                          MaterialButton(
                                            color: AppConfig.colorPrimary,
                                            textColor: Colors.white,
                                            child: const Text('OK'),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      );
                                    });
                              },
                              child: Container(
                                  width: SizeConfig.blockSizeHorizontal * 17,
                                  height: SizeConfig.blockSizeVertical * 3,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppConfig.buttonDeactiveColor),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(5))),
                                  child: Center(
                                    child: Text(''
                                        '${roundoff == '' ? roundOffValue.toStringAsFixed(AppState().noOfDecimals ?? 2) : roundoff}'),
                                  )),
                            ),
                          ],
                        ),
                        Text('Grand Total: '
                            '${roundedGrandTotal.toStringAsFixed(AppState().noOfDecimals ?? 2)}'
                            ''),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void showProductDetailsDialog(
      BuildContext context, Map<String, dynamic> product) async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_product_with_units_for_order?store_id=${AppState().storeId}&van_id=${AppState().vanId}&id=${product['id']}'));
    final typeResponse = await http
        .get(Uri.parse('${RestDatasource().BASE_URL}/api/get_product_type'));

    if (response.statusCode == 200 && typeResponse.statusCode == 200) {
      final data = jsonDecode(response.body);
      final units = data['data'] as List?;
      final lastsale = data['lastsale'];
      final typeData = jsonDecode(typeResponse.body);
      final productTypes = typeData['data'] as List;
      final amountController = TextEditingController();
      final descriptionController = TextEditingController();
      final existingProduct = savedProducts
          .firstWhere((p) => p['serial_number'] == product['serial_number']);
      String? amount = existingProduct['amount'];
      String? description = existingProduct['description'];
      double? availableStock;
      if (amount != null && amount.isNotEmpty) {
        amountController.text = amount;
      }
      if (description != null && description.isNotEmpty) {
        descriptionController.text = description;
      }
      String? selectedUnitId = existingProduct['unit_id'];
      String? selectedProductTypeId = existingProduct['type_id'];
      String? quantity = existingProduct['quantity'];
      bool isQuantityValid(String? value) {
        final quantityValue = double.tryParse(value ?? '') ?? 0;
        return value != null &&
                value.isNotEmpty &&
                quantityValue > 0 &&
                AppState().validate_qtySO == 'Yes'
            ? quantityValue <= (availableStock ?? 0)
            : quantityValue > 0;
      }

      Map<String, dynamic>? selectedUnit;

      if (selectedUnitId != null && units != null) {
        selectedUnit = units.firstWhere(
            (unit) => unit['id'].toString() == selectedUnitId,
            orElse: () => null);
        availableStock =
            double.tryParse(selectedUnit?['stock']?.toString() ?? '0');
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          bool showDescriptionField = false;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('${product['code']} | ${product['name']}'),
                content: SingleChildScrollView(
                  child: Form(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Image.network(
                              '${RestDatasource().Product_URL}/uploads/product/${product['proImage']}',
                              height: 100,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset('Assets/Images/no_image.jpg',
                                    height: 100);
                              },
                            ),
                            lastsale == null || lastsale.isEmpty
                                ? Text('No last records found')
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Last Sale:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text('Date: ${lastsale['date']}'),
                                      Text('Unit: ${lastsale['unit']}'),
                                      Text('Price: ${lastsale['price']}'),
                                    ],
                                  ),
                          ],
                        ),
                        SizedBox(height: 5.h),
                        if (selectedUnit != null) ...[
                          Text(
                            'Available Qty: ${selectedUnit!['stock']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                        if (units != null &&
                            units.any((unit) => unit != null)) ...[
                          SizedBox(height: 10.h),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Product Type',
                              labelStyle:
                                  TextStyle(fontWeight: FontWeight.bold),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 2.h, horizontal: 10.w),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                            ),
                            items: productTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type['id'].toString(),
                                child: Text(type['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedProductTypeId = value;

                                // Check if the selected product type is not "Normal"
                                final selectedType = productTypes.firstWhere(
                                  (type) => type['id'].toString() == value,
                                  orElse: () => null,
                                );

                                if (selectedType != null &&
                                    selectedType['name'] != 'Normal') {
                                  // Set amount to 0 if type is not "Normal"
                                  amountController.text = '0';
                                } else if (selectedUnit != null) {
                                  // Set amount to the selected unit's price if type is "Normal"
                                  amountController.text =
                                      selectedUnit?['price']?.toString() ?? '';
                                }
                              });
                            },
                            value: selectedProductTypeId,
                            hint: Text('Select Product Type'),
                          ),
                          SizedBox(height: 10.h),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              labelStyle:
                                  TextStyle(fontWeight: FontWeight.bold),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 2.h, horizontal: 10.w),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                            ),
                            items:
                                units.where((unit) => unit != null).map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit['id'].toString(),
                                child: Text(unit['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedUnitId = value;
                                selectedUnit = units.firstWhere(
                                    (unit) => unit['id'].toString() == value,
                                    orElse: () => null);
                                amountController.text =
                                    selectedUnit?['price']?.toString() ?? '';
                                availableStock = double.tryParse(
                                    selectedUnit?['stock']?.toString() ?? '0');
                                print("Des$description");
                              });
                            },
                            value: selectedUnitId,
                            hint: Text('Select Unit'),
                          ),
                          SizedBox(height: 10.h),
                          TextFormField(
                            keyboardType: TextInputType.number,
                            // initialValue: amount,
                            controller: amountController,
                            // onChanged: (value) {
                            //   amount = amount;
                            // },
                            decoration: InputDecoration(
                                labelText: 'Amount',
                                labelStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 2.h, horizontal: 10.w),
                                hintText: 'Amt',
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none),
                                filled: true,
                                fillColor: Colors.grey.shade300),
                          ),
                          SizedBox(height: 10.h),
                          TextFormField(
                            keyboardType: TextInputType.number,
                            initialValue: quantity,
                            onChanged: (value) {
                              quantity = value;
                              setDialogState(() {});
                            },
                            decoration: InputDecoration(
                                labelText: 'Quantity',
                                labelStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 2.h, horizontal: 10.w),
                                hintText: 'Qty',
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none),
                                filled: true,
                                fillColor: Colors.grey.shade300),
                          ),
                          SizedBox(height: 10),
                          // if (showDescriptionField && description == '')
                          TextFormField(
                            controller: descriptionController,
                            decoration: InputDecoration(
                                labelText: 'Description',
                                labelStyle:
                                TextStyle(fontWeight: FontWeight.bold),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 2.h, horizontal: 10.w),
                                hintText: 'desc',
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none),
                                filled: true,
                                fillColor: Colors.grey.shade300),
                          ),
                          SizedBox(height: 10),
                        ] else ...[
                          Text('No units available for this product.'),
                        ],
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  if(description == '')
                  TextButton(
                  style: TextButton.styleFrom(
                      backgroundColor: AppConfig.colorPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r))),
                  child: Text(
                    'Description',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    setDialogState(() {
                      showDescriptionField = true; // Show text field when tapped
                    });
                  },
                ),
                  TextButton(
                    style: TextButton.styleFrom(
                        backgroundColor: AppConfig.colorPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.r))),
                    child: Text(
                      'Close',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  if (units != null && units.any((unit) => unit != null)) ...[
                    TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: isQuantityValid(quantity)
                              ? AppConfig.colorPrimary
                              : Colors.grey,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.r))),
                      child: Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: isQuantityValid(quantity)
                          ? () async {
                              if (selectedUnitId != null &&
                                  selectedProductTypeId != null &&
                                  quantity != null &&
                                  amountController.text != null) {
                                final productIndex = savedProducts.indexWhere(
                                    (p) =>
                                        p['serial_number'] ==
                                        product['serial_number']);
                                if (productIndex != -1) {
                                  setState(() {
                                    savedProducts[productIndex]['unit_id'] =
                                        selectedUnitId;
                                    savedProducts[productIndex]['type_id'] =
                                        selectedProductTypeId;
                                    savedProducts[productIndex]['quantity'] =
                                        quantity;
                                    savedProducts[productIndex]['amount'] =
                                        amountController.text;
                                    savedProducts[productIndex]['type_name'] =
                                        productTypes.firstWhere((type) =>
                                            type['id'].toString() ==
                                            selectedProductTypeId)['name'];
                                    savedProducts[productIndex]['unit_name'] =
                                        selectedUnit?['name'];
                                    savedProducts[productIndex]['description'] = descriptionController.text;
                                    _updateCalculations();
                                  });

                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final savedProductsStringList = savedProducts
                                      .map((product) => jsonEncode(product))
                                      .toList();
                                  await prefs.setStringList('selected_products',
                                      savedProductsStringList);

                                  Navigator.of(context).pop();
                                }
                              }
                            }
                          : null,
                    ),
                  ],
                ],
              );
            },
          );
        },
      ).then((_) {
        _isDialogOpen =
            false; // Reset the flag if the dialog is dismissed by other means
      });
    }
  }
}
