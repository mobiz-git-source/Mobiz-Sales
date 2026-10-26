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
import 'package:http/http.dart' as http;
import '../../confg/apptextsizes.dart';
import '../../Components/commonwidgets.dart';
import '../../Models/sales_model.dart';
import '../../Utilities/rest_ds.dart';
import '../../Utilities/date_helper.dart';
import '../../confg/appconfig.dart';
import '../../confg/sizeconfig.dart';
import 'QuotationHome.dart';
import 'QuotationProduct.dart';


class QuotatioCustomerScreen extends StatefulWidget {
  static const routeName = "/QuotatioCustomerScreen";
  @override
  _QuotatioCustomerScreenState createState() => _QuotatioCustomerScreenState();
}

int? id;

class _QuotatioCustomerScreenState extends State<QuotatioCustomerScreen> {
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
  int? customerId;
  int? quotationId;
  String roundoffValueStr = '';
  bool _initDone = true;
 @override
void initState() {
  super.initState();
  AppState().loadTaxName().then((_) {
    if (mounted) setState(() {});
  });
  _loadSavedProducts();
    Future.delayed(Duration.zero, () {
      final Map<String, dynamic>? params =
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (params != null) {
        setState(() {
          customerId = params['customerId'];
          name = params['name'];
          quotationId = params['quotationId'];
        });

        if (quotationId != null) {
          _fetchQuotationItems(quotationId!);
        } else {
          _loadSavedProducts();
        }
      }
    });
    fetchProductTypes();
    fetchCheckInDetail();
  }

  Future<void> _fetchQuotationItems(int qId) async {
    setState(() => _initDone = false);
    final url = Uri.parse('${RestDatasource().BASE_URL}/api/sales-quotation/$qId/items?store_id=${AppState().storeId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print(response.request);
        final data = json.decode(response.body);
        final summary = data['data']['summary'];
        final items = data['data']['items'] as List;

        List<Map<String, dynamic>> fetchedProducts = [];
        for (var item in items) {
          fetchedProducts.add({
            'serial_number': DateTime.now().millisecondsSinceEpoch + items.indexOf(item),
            'id': item['item_id'],
            'code': item['product_code'],
            'name': item['product_name'],
            'unit_id': item['unit_id'].toString(),
            'unit_name': item['unit_name'],
            'type_id': item['product_type_id'].toString(),
            'type_name': item['product_type_name'],
            'quantity': item['quantity'].toString(),
            'amount': item['mrp'].toString(),
            'description': item['product_description'] ?? '',
            'tax_percentage': item['tax_percentage'] ?? item['tax_percent'] ?? 0,
            'proImage': 'defalut.jpg',
          });
        }

        setState(() {
          savedProducts = fetchedProducts;
          _discountData.text = summary['discount'].toString();
          _ifVat = summary['if_vat'] ?? 1;
          _remarksText = summary['delivery_location'] ?? '';
          _remarksController.text = _remarksText;
          _updateCalculations();
          _initDone = true;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('selected_products', savedProducts.map((p) => jsonEncode(p)).toList());
      }
    } catch (e) {
      print('Error fetching quotation items: $e');
      setState(() => _initDone = true);
    }
  }

  Future<void> _removeProduct(int index) async {
    setState(() {
      savedProducts.removeAt(index);
      _updateCalculations();
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_products', savedProducts.map((p) => jsonEncode(p)).toList());
  }

  Future<void> clearCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_products');
    setState(() {
      savedProducts.clear();
    });
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

  // Future<void> _removeProduct(int index) async {
  //   setState(() {
  //     savedProducts.removeAt(index);
  //     // Recalculate total amount
  //     totalAmount = savedProducts.fold(0.0, (sum, product) {
  //       final quantity =
  //           double.tryParse(product['quantity']?.toString() ?? '0') ?? 0.0;
  //       final amount =
  //           double.tryParse(product['amount']?.toString() ?? '0') ?? 0.0;
  //       return sum + (quantity * amount);
  //     });
  //   });
  //
  //   final prefs = await SharedPreferences.getInstance();
  //   final savedProductsStringList =
  //   savedProducts.map((product) => jsonEncode(product)).toList();
  //   await prefs.setStringList('selected_products', savedProductsStringList);
  // }

  double _vatRound(double v) {
    final double sign = v < 0 ? -1 : 1;
    return sign * ((v.abs() * 100) + 1e-9).roundToDouble() / 100;
  }

  double _r(double v) {
    final int dec = AppState().noOfDecimals ?? 2;
    double f = 1;
    for (int i = 0; i < dec; i++) f *= 10;
    final double sign = v < 0 ? -1 : 1;
    return sign * ((v.abs() * f) + 1e-9).roundToDouble() / f;
  }

  double calculateTax() {
    double tax = 0;
    final double discountAmount =
        double.tryParse(_discountData.text.trim()) ?? 0;

    for (final product in savedProducts) {
      final double quantity =
          double.tryParse(product['quantity']?.toString() ?? '0') ?? 0;
      final double rate =
          double.tryParse(product['amount']?.toString() ?? '0') ?? 0;
      final double lineTotal = quantity * rate;
      final num taxPercentage =
          num.tryParse(product['tax_percentage']?.toString() ?? '0') ?? 0;

      final double lineDiscountAmount = _isPercentage
          ? (lineTotal * discountAmount) / 100
          : (totalAmount == 0 ? 0 : (lineTotal / totalAmount) * discountAmount);

      final double taxableAmount = lineTotal - lineDiscountAmount;
      tax += (taxableAmount * taxPercentage) / 100;
    }
    return _vatRound(tax);
  }



  Map<String, dynamic> CalculatedValue() {
    final double taxamt = _ifVat == 1 ? calculateTax() : 0;
    roundoff = _roundoff.text.trim();
    final double rundff = double.tryParse(roundoff) ?? 0;
    final double discountAmount =
        double.tryParse(_discountData.text.trim()) ?? 0;

    final double netAmount = _isPercentage
        ? totalAmount - (totalAmount * discountAmount / 100)
        : totalAmount - discountAmount;

    final double grandTotal = _r(netAmount + taxamt);

    final double roundOffValue = roundoff.isEmpty ? 0.0 : _r(rundff);
    final double roundedGrandTotal = _r(grandTotal + roundOffValue);

    return {
      'rounded': roundedGrandTotal,
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

  // Future<void> clearCart() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('selected_products');
  //   setState(() {
  //     savedProducts.clear();
  //   });
  // }

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
            // _showWelcomeDialog();
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
        final int dec = AppState().noOfDecimals ?? 2;
    final double _d = double.tryParse(_discountData.text.trim()) ?? 0;
    final double _discAmt = _isPercentage ? totalAmount * _d / 100 : _d;
    final double subTotal = totalAmount - _discAmt;
    double total;
    if (ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params =
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      id = params!['customerId'];
      name = params['name'];
    }
    void postDataToApi() async {
      setState(() => _isButtonDisabled = true);

      try {
        final discount = double.tryParse(_discountData.text) ?? 0;
        final tax = _ifVat == 1 ? calculateTax() : 0;
        final grandTotalMap = CalculatedValue();
        final roundedGrandTotal = double.parse(double.parse(grandTotalMap['rounded'].toString()).toStringAsFixed(AppState().noOfDecimals ?? 2));

        late http.Response response;

        if (quotationId != null) {
          // PUT request for updating existing quotation
          final url = Uri.parse('${RestDatasource().BASE_URL}/api/sales-quotation/$quotationId');

          final data = {
            'customer_id': customerId,
            'store_id': AppState().storeId,
            'user_id': AppState().userId,
            'van_id': AppState().vanId,
            'discount_type': _isPercentage ? 'percentage' : 'amount',
            'discount': discount,
            'discount_percentage': _isPercentage ? discount : 0,
            'if_vat': _ifVat,
            'remarks': _remarksText,
            'warehouse_id': 1,
            'so_reference': "SO-QN-${DateFormat('yyyyMMdd').format(DateTime.now())}",
            'bill_type': "quotation",
            'narration': "Updated via App",
            'currency_id': 1,
            'other_charge': 0,
            'round_off': roundOffValue,
            'items': savedProducts.map((p) => {
              'item_id': p['id'],
              'product_description': p['description'] ?? '',
              'product_type': int.tryParse(p['type_id'].toString()) ?? 1,
              'unit': int.tryParse(p['unit_id'].toString()) ?? 1,
              'quantity': double.tryParse(p['quantity'].toString()) ?? 0,
              'rate': double.tryParse(p['amount'].toString()) ?? 0,
              'mrp': double.tryParse(p['amount'].toString()) ?? 0,
              'prodiscount': 0,
              'convert_qty': 1,
              'foc_approval': 0
            }).toList(),
          };

          response = await http.put(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: json.encode(data),
          );
        } else {
          // POST request for creating new quotation
          final url = Uri.parse('${RestDatasource().BASE_URL}/api/sales_quotation.store');

          final data = {
            'van_id': AppState().vanId,
            'store_id': AppState().storeId,
            'user_id': AppState().userId,
            'item_id': savedProducts.map((p) => p['id']).toList(),
            'quantity': savedProducts.map((p) => double.parse(p['quantity'].toString())).toList(),
            'unit': savedProducts.map((p) => int.parse(p['unit_id'].toString())).toList(),
            'mrp': savedProducts.map((p) => double.parse(p['amount'].toString())).toList(),
            'discount_type': _isPercentage ? 'percentage' : 'amount',
            'customer_id': customerId,
            'if_vat': _ifVat,
            'product_type': savedProducts.map((p) => int.parse(p['type_id'].toString())).toList(),
            'total_tax': tax.toStringAsFixed(AppState().noOfDecimals ?? 2),
            "discount": _discountData.text.isEmpty ? '0' : _discountData.text,
            "total": totalAmount,
            "round_off": roundOffValue.toStringAsFixed(AppState().noOfDecimals ?? 2),
            "grand_total": roundedGrandTotal,
            'remarks': _remarksText,
            'scheduled_date': _selectedDate.toString(),
            'description': savedProducts.map((p) => p['description'].toString()).toList(),
            'delivery_location': _remarksText
          };

          response = await http.post(
            url,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: json.encode(data),
          );
          print('data: ${json.encode(data)}');
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('Response data: ${response.body}');
          if (mounted) {
            CommonWidgets.showDialogueBox(
                context: context,
                title: "Success",
                msg: quotationId != null ? "Updated Successfully" : "Created Successfully"
            ).then((value) {
              clearCart();
              Navigator.pushReplacementNamed(context, QuotationHome.routeName);
            });
          }
        } else {
          print('Request failed: ${response.statusCode}');
          print('Response body: ${response.body}');
          if (mounted) {
            CommonWidgets.showDialogueBox(
                context: context,
                title: "Error",
                msg: "Failed to ${quotationId != null ? 'update' : 'create'} quotation. Status: ${response.statusCode}"
            );
          }
        }
      } catch (e) {
        print('An error occurred: $e');
        if (mounted) {
          CommonWidgets.showDialogueBox(
              context: context,
              title: "Error",
              msg: "An error occurred: ${e.toString()}"
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isButtonDisabled = false);
        }
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
            'Quotation',
            style: AppConfig.pageTitleStyle,
          ),
          backgroundColor: AppConfig.colorPrimary,
        
        ),
              body: SafeArea(
          top: false,
          child: savedProducts.isEmpty
              ? Center(
                  child: InkWell(
                    onTap: _openProductSearch,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_shopping_cart,
                              size: 34, color: AppConfig.colorPrimary),
                          const SizedBox(height: 8),
                          const Text('No saved products',
                              style: TextStyle(color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text('Tap to Add Item',
                              style: TextStyle(
                                  color: AppConfig.colorPrimary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    // ===== customer + VAT + date =====
                    Padding(
                      padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.7),
                        ),
                       child: Row(
  children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4FC),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(
        Icons.storefront_outlined,
        size: 22,
        color: AppConfig.colorPrimary,
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: Text(
        (name ?? '').toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  if (AppState().vatState != 'Disable') ...[
  _vatBtn(AppState().taxLabel, 1),
  _vatBtn('NO ${AppState().taxLabel}', 0),
],
  ],
),
                      ),
                    ),

                    // ===== items table =====
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFDCDCDC), width: 0.8),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 34,
                              color: const Color(0xFFFAFAFC),
                              child: Row(
                                children: [
                                  SizedBox(width: 32, child: Center(child: _hd('#'))),
                                  Expanded(child: _hd('Item Details')),
                                  SizedBox(width: 34, child: Center(child: _hd('Qty'))),
                                  SizedBox(width: 52, child: Center(child: _hd('Rate'))),
                                  SizedBox(width: 52, child: Center(child: _hd('Amt'))),
                                  const SizedBox(
                                      width: 32,
                                      child: Icon(Icons.delete_outline,
                                          size: 16, color: Colors.red)),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                             child: ListView.builder(
  physics: const BouncingScrollPhysics(),
  padding: EdgeInsets.zero,
  itemCount: savedProducts.length,
  itemBuilder: (context, index) {
                                  final p = savedProducts[index];
                                  final qty = double.tryParse(p['quantity']?.toString() ?? '0') ?? 0.0;
                                  final rate = double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0;
                                  final dec = AppState().noOfDecimals ?? 2;
                                  return InkWell(
                                    onTap: _isDialogOpen
                                        ? null
                                        : () {
                                            setState(() => _isDialogOpen = true);
                                            showProductDetailsDialog(context, p);
                                          },
                               child: Container(
  constraints: const BoxConstraints(minHeight: 76),
  decoration: const BoxDecoration(
    color: Colors.white,
    border: Border(
      bottom: BorderSide(color: Color(0xFFE8E8E8), width: 0.7),
    ),
  ),
  child: Row(
                                        children: [
                                         SizedBox(
  width: 32,
  child: Center(
    child: Container(
      width: 21,
      height: 21,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDDE0F5), width: 0.6),
      ),
      child: Text('${index + 1}',
          style: const TextStyle(
            fontSize: AppFontSizes.body,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555EA0),
          )),
    ),
  ),
),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 5),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                            Text(
  '${p['code']} | ${p['name'].toString().toUpperCase()}',
  maxLines: 2,
  softWrap: true,
  overflow: TextOverflow.visible,
  style: const TextStyle(
    fontSize: AppFontSizes.label,
    height: 1.15,
    fontWeight: FontWeight.w600,
    color: Color(0xFF222222),
  ),
),
const SizedBox(height: 4),
Row(
  children: [
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFFA),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${p['type_name']}',
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF5558B5),
        ),
      ),
    ),
    const SizedBox(width: 5),
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${p['unit_name']}',
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF555555),
        ),
      ),
    ),
  ],
),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                              width: 34,
                                              child: Center(
                                                  child: Text(
                                                      qty % 1 == 0 ? qty.toInt().toString() : qty.toString(),
                                                      style: const TextStyle(fontSize: 10)))),
                                          SizedBox(
                                              width: 52,
                                              child: Center(
                                                  child: Text(rate.toStringAsFixed(dec),
                                                      style: const TextStyle(fontSize: 10)))),
                                          SizedBox(
                                              width: 52,
                                              child: Center(
                                                  child: Text((qty * rate).toStringAsFixed(dec),
                                                      style: const TextStyle(
                                                          fontSize: 10, fontWeight: FontWeight.w600)))),
                                          SizedBox(
                                            width: 32,
                                            child: GestureDetector(
                                              onTap: () => _removeProduct(index),
                                              child: const Icon(Icons.delete_outline,
                                                  size: 16, color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            InkWell(
                              onTap: _openProductSearch,
                           child: Container(
  constraints: const BoxConstraints(minHeight: 64),
  decoration: const BoxDecoration(
    color: Colors.white,
    border: Border(
      bottom: BorderSide(color: Color(0xFFE8E8E8), width: 0.7),
    ),
  ),
  child: IntrinsicHeight(
    child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle_outline,
                                        size: 13, color: AppConfig.colorPrimary),
                                    const SizedBox(width: 4),
                                    Text('Add Item',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppConfig.colorPrimary)),
                                  ],
                                ),
                              ),
                            ),
                        )  ],                        ),
                      ),
                    ),

                    // ===== summary + buttons =====
                   Padding(
  padding: const EdgeInsets.fromLTRB(7, 6, 7, 10),
  child: LayoutBuilder(
    builder: (context, constraints) {
      final bool isVerySmall = constraints.maxWidth < 340;
      final double discountLabelWidth = isVerySmall ? 52 : 60;
      final double sectionPadding = isVerySmall ? 8 : 14;

      Widget label(String t) => Text(t,
          style: const TextStyle(
              fontSize: AppFontSizes.label,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222)));

      Widget discBtn(String t, bool pct, double w) => InkWell(
            onTap: () => setState(() => _isPercentage = pct),
            child: Container(
              width: w,
              height: 30,
              alignment: Alignment.center,
              color: _isPercentage == pct
                  ? AppConfig.colorPrimary
                  : Colors.white,
              child: Text(t,
                  style: TextStyle(
                      fontSize: AppFontSizes.label,
                      fontWeight: FontWeight.w600,
                      color: _isPercentage == pct
                          ? Colors.white
                          : const Color(0xFF222222))),
            ),
          );

      Widget sumRow(String t, double v) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(t,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: AppFontSizes.label,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222))),
              ),
              Flexible(
                child: Text(v.toStringAsFixed(dec),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: AppFontSizes.value,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222))),
              ),
            ],
          );

      return Container(
        padding: EdgeInsets.fromLTRB(
            isVerySmall ? 9 : 13, 10, isVerySmall ? 9 : 13, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE1E1E1), width: 0.7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ================= LEFT =================
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: EdgeInsets.only(right: sectionPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('Delivery Location'),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: _editDeliveryLocation,
                            child: Container(
                              width: double.infinity,
                              height: 30,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 9),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFFD2D2D2),
                                    width: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _remarksText.isEmpty
                                    ? 'Enter delivery location'
                                    : _remarksText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppFontSizes.label,
                                  color: _remarksText.isEmpty
                                      ? const Color(0xFF9A9A9A)
                                      : const Color(0xFF222222),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 9),
                          label('Schedule Date'),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              width: double.infinity,
                              height: 30,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 9),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFFD2D2D2),
                                    width: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined,
                                      size: 12,
                                      color: AppConfig.colorPrimary),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      _selectedDate == null
                                          ? 'Select Date'
                                          : DateHelper.displayFromDateTime(
                                              _selectedDate!),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: AppFontSizes.label,
                                        color: Color(0xFF222222),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (AppState().discountState != 'Disable') ...[
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                SizedBox(
                                    width: discountLabelWidth,
                                    child: label('Discount')),
                                Container(
                                  height: 30,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color(0xFFD2D2D2),
                                        width: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      discBtn('AMT', false, 42),
                                      discBtn('%', true, 34),
                                    ],
                                  ),
                                ),
                                SizedBox(width: isVerySmall ? 5 : 7),
                                Expanded(
                                  child: SizedBox(
                                    height: 30,
                                    child: TextField(
                                      controller: _discountData,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: AppFontSizes.value,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF222222),
                                      ),
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 2, vertical: 6),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          borderSide: const BorderSide(
                                              color: Color(0xFFD2D2D2),
                                              width: 0.7),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          borderSide: const BorderSide(
                                              color: Color(0xFFD2D2D2),
                                              width: 0.7),
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  Container(width: 0.8, color: const Color(0xFFE3E3E3)),

                  // ================= RIGHT =================
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: EdgeInsets.only(left: sectionPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          sumRow('Total', subTotal),
                          const SizedBox(height: 9),
                          sumRow(AppState().taxLabel, tax),
                          const SizedBox(height: 9),
                          sumRow('Sub Total', totalAmount),
                          const SizedBox(height: 9),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Flexible(
                                child: Text('Round Off',
                                    style: TextStyle(
                                        fontSize: AppFontSizes.label,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF222222))),
                              ),
                              InkWell(
                                onTap: _editRoundOff,
                                child: Container(
                                  width: isVerySmall ? 55 : 65,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color(0xFFD2D2D2),
                                        width: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      roundOffValue.toStringAsFixed(dec),
                                      style: const TextStyle(
                                        fontSize: AppFontSizes.value,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF222222),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                              height: 1,
                              width: double.infinity,
                              color: const Color(0xFFE0E0E0)),
                          const SizedBox(height: 7),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('Grand Total',
                                  style: TextStyle(
                                      fontSize: AppFontSizes.label,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF222222))),
                              const SizedBox(width: 4),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    roundedGrandTotal.toStringAsFixed(dec),
                                    style: TextStyle(
                                      fontSize: AppFontSizes.grandTotal,
                                      fontWeight: FontWeight.w700,
                                      color: AppConfig.colorPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),

            // ================= BUTTONS =================
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.red, width: 1.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      padding:
                          EdgeInsets.symmetric(vertical: isVerySmall ? 10 : 11),
                    ),
                    onPressed: clearCart,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.delete_outline,
                              size: 15, color: Colors.red),
                          SizedBox(width: 4),
                          Text('CLEAR ALL',
                              style: TextStyle(
                                  fontSize: AppFontSizes.label,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isButtonDisabled
                          ? AppConfig.colorPrimary
                          : AppConfig.buttonDeactiveColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      padding:
                          EdgeInsets.symmetric(vertical: isVerySmall ? 10 : 11),
                      elevation: 0,
                    ),
                    onPressed: _isButtonDisabled ? null : postDataToApi,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.save_outlined,
                              size: 15, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            _isButtonDisabled
                                ? 'SAVING...'
                                : (quotationId == null ? 'SAVE' : 'UPDATE'),
                            style: const TextStyle(
                                fontSize: AppFontSizes.label,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  ),
),
                  ],
                ),
        ),
      ),
    );
  }

  // ---------- small UI helpers ----------
  Widget _hd(String t) => Text(t,
      style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: AppConfig.colorPrimary));

 Widget _vatBtn(String label, int value) => InkWell(
      onTap: () => setState(() => _ifVat = value),
      child: Container(
        constraints: BoxConstraints(minWidth: value == 1 ? 45 : 52),
        height: 22,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: _ifVat == value ? AppConfig.colorPrimary : const Color(0xFFF7F7F7),
          border: Border.all(color: const Color(0xFFD5D5D5), width: 0.7),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              maxLines: 1,
              style: TextStyle(
                  fontSize: AppFontSizes.body,
                  fontWeight: FontWeight.w600,
                  color: _ifVat == value ? Colors.white : const Color(0xFF333333))),
        ),
      ),
    );

  Widget _discBtn(String label, bool pct, double w) => InkWell(
        onTap: () => setState(() => _isPercentage = pct),
        child: Container(
          width: w,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isPercentage == pct ? AppConfig.colorPrimary : Colors.white,
            border: Border.all(color: const Color(0xFFD2D2D2), width: 0.7),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _isPercentage == pct ? Colors.white : const Color(0xFF222222))),
        ),
      );

  Widget _sumRow(String label, double v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          Text(v.toStringAsFixed(AppState().noOfDecimals ?? 2),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      );

  void _editDeliveryLocation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery Location'),
        content: TextField(
          controller: _remarksController,
          decoration: const InputDecoration(hintText: 'Enter your location'),
        ),
        actions: [
          MaterialButton(
            color: AppConfig.colorPrimary,
            textColor: Colors.white,
            child: const Text('OK'),
            onPressed: () {
              setState(() => _remarksText = _remarksController.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _editRoundOff() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Round off'),
        content: TextField(
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          controller: _roundoff,
          decoration: const InputDecoration(hintText: 'Round off'),
        ),
        actions: [
          MaterialButton(
            color: AppConfig.colorPrimary,
            textColor: Colors.white,
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
  void _openProductSearch() {
    Navigator.pushReplacementNamed(context, QuotationProduct.routeName,
        arguments: {
          'customerId': customerId ?? id,
          'name': name,
          'quotationId': quotationId,
        });
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

      final uniqueUnits = {
        for (var unit in units!.where((unit) => unit != null))
          unit['id'].toString(): unit
      }.values.toList();

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
                              Text('Date: ${DateHelper.displayDate(lastsale['date'])}'),
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
                          ),SizedBox(height: 8),



SizedBox(height: 10),
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
                            items: uniqueUnits.map((unit) {
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
                            value: selectedUnitId != null &&
                                uniqueUnits.any((unit) => unit['id'].toString() == selectedUnitId)
                                ? selectedUnitId
                                : null,
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
                          }
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
