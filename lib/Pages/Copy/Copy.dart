import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/Copy/CopySelectProducts.dart';
import 'package:mobizapp/Pages/saleinvoices.dart';
import 'package:mobizapp/Pages/salesselectproductorder.dart';
import 'package:mobizapp/Pages/salesselectproducts.dart';
import 'package:mobizapp/Utilities/date_helper.dart';
import 'package:mobizapp/vanstockselactpro_tst.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Models/sales_model.dart';
import '../../Components/commonwidgets.dart';
import '../../Utilities/rest_ds.dart';
import '../../confg/appconfig.dart';
import '../../confg/sizeconfig.dart';
import '../../confg/apptextsizes.dart';
import 'package:http/http.dart' as http;

import '../customerreturndetails.dart';

class CopyScreen extends StatefulWidget {
  static const routeName = "/CopyScreen";
  @override
  _CopyScreenState createState() => _CopyScreenState();
}

int? id;

class _CopyScreenState extends State<CopyScreen> {
  List<Map<String, dynamic>> savedProducts = [];
  final TextEditingController _remarksController = TextEditingController();
  bool _isPercentage = false;
  final TextEditingController _discountData = TextEditingController();
  final TextEditingController _roundoff = TextEditingController();
  double totalAmount = 0.0;
  double roundOffValue = 0.0;
  bool _isDialogOpen = false;
  bool _isButtonDisabled = false;
  String _remarksText = "";
  List<ProductType> productTypes = [];
  List<ProductType?> selectedProductTypes = [];
  TextEditingController _searchData = TextEditingController();
  bool _search = false;
  int _ifVat = 1;
  String? name;
  String? code;
  String? paymentTerms;
  String? paydata;
  int? pricegroupId;
  bool Status = false;
  bool isAvailable = false;
  var attendanceData;

  String roundoff = '';
  double _r(double v) {
  final int dec = AppState().noOfDecimals ?? 2;
  double f = 1;
  for (int i = 0; i < dec; i++) f *= 10;
  final double sign = v < 0 ? -1 : 1;
  return sign * ((v.abs() * f) + 1e-9).roundToDouble() / f;
}

double _vatRound(double v) {
  final double sign = v < 0 ? -1 : 1;
  return sign * ((v.abs() * 100) + 1e-9).roundToDouble() / 100;
}
  String _billType = 'Cash';
  @override
  void initState() {
    super.initState();
    AppState().loadTaxName().then((_) {
      if (mounted) setState(() {});
    });
    _loadSavedProducts();
    fetchProductTypes();
    fetchCheckInDetail();
    print(
        "Round off positive: ${AppState().roundOffPositive}, negative: ${AppState().roundOffNegative}");
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

  List<Map<String, dynamic>> get _filteredSavedProducts {
    final query = _searchData.text.trim().toLowerCase();
    if (query.isEmpty) return savedProducts;
    return savedProducts.where((product) {
      final code = (product['code'] ?? '').toString().toLowerCase();
      final name = (product['name'] ?? '').toString().toLowerCase();
      return code.contains(query) || name.contains(query);
    }).toList();
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

    String discountValue = _discountData.text.trim();
    double discountAmount = double.tryParse(discountValue) ?? 0;

    for (int index = 0; index < savedProducts.length; index++) {
      final product = savedProducts[index];

      double quantity =
          double.tryParse(product['quantity']?.toString() ?? '0') ?? 0;

      double rate = double.tryParse(product['amount']?.toString() ?? '0') ?? 0;

      double lineTotal = quantity * rate;

      num taxPercentage =
          num.tryParse(product['tax_percentage']?.toString() ?? '0') ?? 0;
      print("========== VAT DEBUG ==========");
      print("Product ID: ${product['id']}");
      print("Product Name: ${product['name']}");
      print("Tax Percentage: ${product['tax_percentage']}");
      print("Quantity: ${product['quantity']}");
      print("Rate: ${product['amount']}");
      print("================================");
      double lineDiscountAmount = _isPercentage
          ? (lineTotal * discountAmount) / 100
          : (totalAmount == 0 ? 0 : (lineTotal / totalAmount) * discountAmount);

      double taxableAmount = lineTotal - lineDiscountAmount;

      tax += (taxableAmount * taxPercentage) / 100;
    }

     return _vatRound(tax);
  }

   Map<String, dynamic> CalculatedValue() {
    final double taxamt = _ifVat == 1 ? calculateTax() : 0;
    roundoff = _roundoff.text.trim();
    final double rundff = AppState().roundOffAllowedInInvoice == false
        ? 0
        : (double.tryParse(roundoff) ?? 0);
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

  Future<void> fetchCheckInDetail() async {
    final String url =
        '${RestDatasource().BASE_URL}/api/get_today_check_in_detail?van_id=${AppState().vanId}&store_id=${AppState().storeId}&user_id=${AppState().userId}';

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      print("FULL RESPONSE: ${response.body}");
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

  List<Map<String, double>> parseRateMatrix(dynamic matrixValue) {
    if (matrixValue == null) return [];
    String matrixStr = matrixValue.toString().trim();
    if (matrixStr.isEmpty) return [];
    List<Map<String, double>> slabs = [];

    final separator = matrixStr.contains('|') ? '|' : ',';

    for (var pair in matrixStr.split(separator)) {
      final parts = pair.trim().split(':');
      if (parts.length == 2) {
        final qty = double.tryParse(parts[0].trim());
        final rate = double.tryParse(parts[1].trim());
        if (qty != null && rate != null) {
          slabs.add({'qty': qty, 'rate': rate});
        }
      }
    }
    slabs.sort((a, b) => a['qty']!.compareTo(b['qty']!));
    return slabs;
  }

  double getApplicableRate(List<Map<String, double>> slabs, double enteredQty,
      double fallbackMinPrice) {
    if (slabs.isEmpty) return fallbackMinPrice;
    double applicable = slabs.first['rate']!;
    for (var slab in slabs) {
      if (enteredQty >= slab['qty']!) {
        applicable = slab['rate']!;
      } else {
        break;
      }
    }
    return applicable;
  }

  // ---- Rate formatter (reused by the dialog below) — always exactly 3
  // decimal places for display; the underlying numeric value used for
  // calculations is unaffected.
  String formatRate(dynamic value) {
    if (value == null) return '0.000';
    final number = double.tryParse(value.toString()) ?? 0.0;
    return number.toStringAsFixed(3);
  }

  Future<void> _onBackPressed() async {
    clearCart();
    print('Back button pressed');
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
    });
  }

  bool _validateMinRates() {
    for (var product in savedProducts) {
      final String typeName =
          (product['type_name'] ?? '').toString().toUpperCase();
      if (typeName == 'FOC') continue; // FOC: no min-rate enforcement

      final rate = double.tryParse(product['amount']?.toString() ?? '0') ?? 0;

      final quantity =
          double.tryParse(product['quantity']?.toString() ?? '0') ?? 0;

      final fallbackMinRate =
          double.tryParse(product['min_price']?.toString() ?? '0') ?? 0;

      final matrix = parseRateMatrix(
        product['minimum_rate_matrix'],
      );

      final minimumRate = getApplicableRate(
        matrix,
        quantity,
        fallbackMinRate,
      );

      if (rate < minimumRate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${product['name']}: Amount cannot be less than Minimum Rate "
              "(${minimumRate.toStringAsFixed(AppState().noOfDecimals ?? 2)})",
            ),
            backgroundColor: Colors.red,
          ),
        );

        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> grandTotalMap = CalculatedValue();

    double tax = _ifVat == 1 ? calculateTax() : 0;
      final double roundedGrandTotal = grandTotalMap['rounded'];
    final double roundOffValue = grandTotalMap['roundOffValue'];
    double total;
    if (ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      id = params!['customerId'];
      name = params['name'];
      pricegroupId = params['price_group_id'];
      code = params['code'];
      paymentTerms = params['paymentTerms'];
      paydata = params['outstandamt'];
    }
    void postDataToApi() async {
      setState(() {
        _isButtonDisabled = true;
      });

      try {
        var url = Uri.parse('${RestDatasource().BASE_URL}/api/vansale.store');
        List<int> productIds = savedProducts.map<int>((product) {
          return product['id'];
        }).toList();
        List<int> unitIds = savedProducts.map<int>((product) {
          return int.parse(product['unit_id']);
        }).toList();
        List<double> amounts = savedProducts.map<double>((product) {
          return double.parse(double.parse(product['amount'].toString())
              .toStringAsFixed(AppState().noOfDecimals ?? 2));
        }).toList();

        List<double> quantity = savedProducts.map<double>((product) {
          return double.parse(product['quantity'].toString());
        }).toList();

        List<int> productTypes = savedProducts.map<int>((product) {
          return int.parse(product['type_id']);
        }).toList();

        List<List<String>> serialNumbers =
            savedProducts.map<List<String>>((product) {
          return product['serial_numbers'] != null &&
                  product['serial_numbers'] is List
              ? List<String>.from(product['serial_numbers'])
              : [];
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
          'total_tax': tax,
          "discount": _discountData.text.isEmpty ? '0' : _discountData.text,
      "total": _r(totalAmount),
          "round_off": roundOffValue,
          "grand_total": roundedGrandTotal,
          'remarks': _remarksText,
          'serial_numbers': serialNumbers,
          'cash_card': _billType
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
          var responseBody = json.decode(response.body);
          int dataId = responseBody['data']['id'];
          int saleId = responseBody['data']['id'];
          if (mounted) {
            CommonWidgets.showDialogueBox(
                    context: context,
                    title: "Alert",
                    msg: "Created Successfully")
                .then(
              (value) {
                clearCart();
                Navigator.pushReplacementNamed(
                    context, Customerreturndetail.routeName,
                    arguments: {
                      'name': name,
                      'dataId': dataId,
                      'saleId': saleId,
                      'customerId': id,
                      'code': code,
                      'paymentTerms': paymentTerms,
                      'outstandamt': paydata,
                      'price_group_id': pricegroupId
                    });
              },
            );
          }
        } else {
          print('Post failed with status: ${response.statusCode}');
          print('Post failed body: ${response.body}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Save failed (${response.statusCode}): ${response.body}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('An error occurred: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() {
          _isButtonDisabled = false;
        });
      }
    }

    void addToCart() {
      setState(() {
        isAvailable = true;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('Saved to cart.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }

    // ------------------------------------------------------------------
    // Opens the existing CopySelectProduct search/selection screen and
    // reuses its product API, product model, search logic, selection
    // logic and callbacks exactly as-is (same call already used by the
    // AppBar search icon below). No new product-selection logic is
    // introduced here — this simply routes "Add Item" to the same place.
    // ------------------------------------------------------------------
    void openProductSearch() {
      Navigator.pushReplacementNamed(context, CopySelectProduct.routeName,
          arguments: {
            'customerId': id,
            'name': name,
            'price_group_id': pricegroupId,
            'outstandamt': paydata,
            'code': code,
            'paymentTerms': paymentTerms,
          }).then((value) {});
    }

    return WillPopScope(
        onWillPop: () async {
          await _onBackPressed();
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            leading: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  if (!isAvailable) {
                    clearCart();
                  }
                },
                child: Icon(Icons.arrow_back_rounded)),
            iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
            title: const Text(
              'Sale',
              style: AppConfig.pageTitleStyle,
            ),
            backgroundColor: AppConfig.colorPrimary,
            actions: [
              (_search)
                  ? Container(
                      height: SizeConfig.blockSizeVertical * 5,
                      width: (MediaQuery.of(context).size.width * 0.76)
                          .clamp(160.0, 280.0),
                      decoration: BoxDecoration(
                        color: AppConfig.colorPrimary,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                        border: Border.all(color: AppConfig.colorPrimary),
                      ),
                      child: TextField(
                        controller: _searchData,
                        autofocus: true,
                        style: const TextStyle(
                            color: AppConfig
                                .backgroundColor), // 👈 ADD THIS ONE LINE
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(5),
                          hintText: "Search...",
                          hintStyle:
                              TextStyle(color: AppConfig.backgroundColor),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    )
                  : Container(),
              CommonWidgets.horizontalSpace(1),
              AppState().attendanceState == 'Required'
                  ? Status &&
                          attendanceData != null &&
                          attendanceData['data']['check_out'] == 0
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _search = !_search;
                              if (!_search) {
                                _searchData.clear();
                              }
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
                        setState(() {
                          _search = !_search;
                          if (!_search) {
                            _searchData.clear();
                          }
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
          body: SafeArea(
            top: false,
            bottom: true,
            child: savedProducts.isEmpty
                ? Center(
                    child: InkWell(
                      onTap: openProductSearch,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_shopping_cart,
                              size: 34,
                              color: AppConfig.colorPrimary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No saved products',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to Add Item',
                              style: TextStyle(
                                color: AppConfig.colorPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 0.7,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Store Icon
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F4FF),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Icon(
                                  Icons.storefront_outlined,
                                  size: 19,
                                  color: AppConfig.colorPrimary,
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Store Name
                              Expanded(
                                child: Text(
                                  (name ?? '').toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                fontSize: AppFontSizes.label,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF252525),
                                    letterSpacing: 0.05,
                                  ),
                                ),
                              ),

                              // ------------------------------------------------------------
                              // VAT / NO VAT
                              // ------------------------------------------------------------
                              if (AppState().vatState != 'Disable') ...[
                                const SizedBox(width: 5),
                                Container(
                                  height: 22,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                      color: const Color(0xFFD5D5D5),
                                      width: 0.7,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // ================= VAT =================
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _ifVat = 1;
                                          });

                                          total = 0;
                                          tax = 0;
                                        },
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 45,
                                          ),
                                          height: 22,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          alignment: Alignment.center,
                                          color: (_ifVat == 1)
                                              ? AppConfig.colorPrimary
                                              : const Color(0xFFF7F7F7),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                          child: Text(
  AppState().taxLabel,
  maxLines: 1,
                                              style: TextStyle(
                                           fontSize: AppFontSizes.body,

                                                fontWeight: FontWeight.w600,
                                                color: (_ifVat == 1)
                                                    ? Colors.white
                                                    : const Color(0xFF333333),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // ================= NO VAT =================
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _ifVat = 0;
                                          });

                                          total = 0;
                                          tax = 0;
                                        },
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 52,
                                          ),
                                          height: 22,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          alignment: Alignment.center,
                                          color: (_ifVat == 0)
                                              ? AppConfig.colorPrimary
                                              : const Color(0xFFF7F7F7),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                           child: Text(
  'NO ${AppState().taxLabel}',
  maxLines: 1,
                                              style: TextStyle(
                                         fontSize: AppFontSizes.body,

                                                fontWeight: FontWeight.w600,
                                                color: (_ifVat == 0)
                                                    ? Colors.white
                                                    : const Color(0xFF333333),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFDCDCDC),
                              width: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: LayoutBuilder(
                            builder: (context, tableConstraints) {
                              final double tw = tableConstraints.maxWidth;
                              final bool isNarrow = tw < 340;
                              final double numW = isNarrow ? 26 : 35;
                              final double qtyW = isNarrow ? 26 : 34;
                              final double rateW = isNarrow ? 44 : 52;
                              final double amtW = isNarrow ? 44 : 52;
                              final double delW = isNarrow ? 26 : 32;

                              return Column(
                                children: [
                                  // ============================================================
                                  // TABLE HEADER
                                  // ============================================================
                                  Container(
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFAFAFC),
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFE2E2E2),
                                          width: 0.8,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // #
                                        SizedBox(
                                          width: numW,
                                          child: Center(
                                            child: Text(
                                              '#',
                                              style: TextStyle(
                                             fontSize: AppFontSizes.value,
                                                fontWeight: FontWeight.w700,
                                                color: AppConfig.colorPrimary,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // ITEM DETAILS
                                        Expanded(
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(left: 2),
                                            child: Text(
                                              'Item Details',
                                              style: TextStyle(
                                           fontSize: AppFontSizes.value,
                                                fontWeight: FontWeight.w700,
                                                color: AppConfig.colorPrimary,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // QTY
                                        SizedBox(
                                          width: qtyW,
                                          child: Center(
                                            child: Text(
                                              'Qty',
                                              style: TextStyle(
                                           fontSize: AppFontSizes.label,
                                                fontWeight: FontWeight.w700,
                                                color: AppConfig.colorPrimary,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // RATE
                                        SizedBox(
                                          width: rateW,
                                          child: Center(
                                            child: Text(
                                              'Rate',
                                              style: TextStyle(
                                         fontSize: AppFontSizes.label,
                                                fontWeight: FontWeight.w700,
                                                color: AppConfig.colorPrimary,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // AMOUNT
                                        SizedBox(
                                          width: amtW,
                                          child: Center(
                                            child: Text(
                                              'Amt',
                                              style: TextStyle(
                                          fontSize: AppFontSizes.label,
                                                fontWeight: FontWeight.w700,
                                                color: AppConfig.colorPrimary,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // DELETE
                                        SizedBox(
                                          width: delW,
                                          child: Center(
                                            child: Icon(
                                              Icons.delete_outline,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ============================================================
                                  // PRODUCT LIST
                                  // ============================================================
                                  Expanded(
                                    child: _filteredSavedProducts.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No matching items',
                                              style: TextStyle(
                                                  color: Colors.black45,
                                                  fontSize: 12),
                                            ),
                                          )
                                        : ListView.builder(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            padding: EdgeInsets.zero,
                                            itemCount:
                                                _filteredSavedProducts.length,
                                            itemBuilder: (context, index) {
                                              final product =
                                                  _filteredSavedProducts[index];

                                              final quantity = double.tryParse(
                                                    product['quantity']
                                                            ?.toString() ??
                                                        '0',
                                                  ) ??
                                                  0.0;

                                              final amount = double.tryParse(
                                                    product['amount']
                                                            ?.toString() ??
                                                        '0',
                                                  ) ??
                                                  0.0;

                                              final total = quantity * amount;

                                              final String code =
                                                  product['code']?.toString() ??
                                                      '';

                                              final String name =
                                                  product['name']?.toString() ??
                                                      '';

                                              final String typeName =
                                                  product['type_name']
                                                          ?.toString() ??
                                                      'Normal';

                                              final String unitName =
                                                  product['unit_name']
                                                          ?.toString() ??
                                                      'PCS';

                                              return InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                                onTap: _isDialogOpen
                                                    ? null
                                                    : () {
                                                        setState(() {
                                                          _isDialogOpen = true;
                                                        });

                                                        showProductDetailsDialog(
                                                          context,
                                                          product,
                                                        );
                                                      },
                                                child: Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                          minHeight: 64),
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.white,
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color:
                                                            Color(0xFFE8E8E8),
                                                        width: 0.7,
                                                      ),
                                                    ),
                                                  ),
                                                  child: IntrinsicHeight(
                                                    child: Row(
                                                      children: [
                                                        // ==================================================
                                                        // NUMBER
                                                        // ==================================================
                                                        SizedBox(
                                                          width: numW,
                                                          child: Center(
                                                            child: Container(
                                                              width: 21,
                                                              height: 21,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                    0xFFF2F3FF),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4),
                                                                border:
                                                                    Border.all(
                                                                  color: const Color(
                                                                      0xFFDDE0F5),
                                                                  width: 0.6,
                                                                ),
                                                              ),
                                                              child: Text(
                                                                '${index + 1}',
                                                                style:
                                                                    const TextStyle(
                                                              fontSize: AppFontSizes.body,

                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Color(
                                                                      0xFF555EA0),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                        // ==================================================
                                                        // ITEM DETAILS
                                                        // ==================================================
                                                        Expanded(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                              left: 3,
                                                              right: 3,
                                                              top: 5,
                                                              bottom: 5,
                                                            ),
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  '$code | ${name.toUpperCase()}',
                                                                  maxLines: 2,
                                                                  softWrap:
                                                                      true,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .visible,
                                                                  style:
                                                                      const TextStyle(
                                                                   fontSize: AppFontSizes.label,
                                                                    height:
                                                                        1.15,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Color(
                                                                        0xFF222222),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 4),
                                                                Row(
                                                                  children: [
                                                                    Container(
                                                                      padding:
                                                                          const EdgeInsets
                                                                              .symmetric(
                                                                        horizontal:
                                                                            5,
                                                                        vertical:
                                                                            2,
                                                                      ),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: const Color(
                                                                            0xFFF0F0FF),
                                                                        borderRadius:
                                                                            BorderRadius.circular(3),
                                                                      ),
                                                                      child:
                                                                          Text(
                                                                        typeName,
                                                                        style:
                                                                            const TextStyle(
    fontSize: AppFontSizes.badge,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                          color:
                                                                              Color(0xFF5558B5),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            4),
                                                                    Container(
                                                                      padding:
                                                                          const EdgeInsets
                                                                              .symmetric(
                                                                        horizontal:
                                                                            5,
                                                                        vertical:
                                                                            2,
                                                                      ),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: const Color(
                                                                            0xFFF3F3F3),
                                                                        borderRadius:
                                                                            BorderRadius.circular(3),
                                                                      ),
                                                                      child:
                                                                          Text(
                                                                        unitName,
                                                                        style:
                                                                            const TextStyle(
                                                                           fontSize: AppFontSizes.badge,
                                                                          color:
                                                                              Color(0xFF555555),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),

                                                        // ==================================================
                                                        // QTY
                                                        // ==================================================
                                                        SizedBox(
                                                          width: qtyW,
                                                          child: Center(
                                                            child: Text(
                                                              quantity % 1 == 0
                                                                  ? quantity
                                                                      .toInt()
                                                                      .toString()
                                                                  : quantity
                                                                      .toString(),
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: AppFontSizes.body,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Color(
                                                                    0xFF222222),
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                        // ==================================================
                                                        // RATE
                                                        // ==================================================
                                                        SizedBox(
                                                          width: rateW,
                                                          child: Center(
                                                            child: Text(
                                                              amount
                                                                  .toStringAsFixed(
                                                                      3),
                                                              style:
                                                                  const TextStyle(
                                                          fontSize: AppFontSizes.tableCellSmall,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Color(
                                                                    0xFF222222),
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                        // ==================================================
                                                        // AMOUNT
                                                        // ==================================================
                                                        SizedBox(
                                                          width: amtW,
                                                          child: Center(
                                                            child: Text(
                                                              total
                                                                  .toStringAsFixed(
                                                                AppState()
                                                                        .noOfDecimals ??
                                                                    2,
                                                              ),
                                                              style:
                                                                  const TextStyle(
                                                            fontSize: AppFontSizes.tableCellSmall,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Color(
                                                                    0xFF222222),
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                        // ==================================================
                                                        // DELETE
                                                        // ==================================================
                                                        SizedBox(
                                                          width: delW,
                                                          child: Center(
                                                            child:
                                                                GestureDetector(
                                                              onTap: () {
                                                                _removeProduct(
                                                                    savedProducts
                                                                        .indexOf(
                                                                            product));
                                                              },
                                                              child: const Icon(
                                                                Icons
                                                                    .delete_outline,
                                                                size: 16,
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),

                                  // ============================================================
                                  // ADD ITEM
                                  // ============================================================
                                  InkWell(
                                    onTap: openProductSearch,
                                    child: Container(
                                      height: 28,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAFAFC),
                                        border: Border(
                                          top: BorderSide(
                                            color: const Color(0xFFDCDCDC),
                                            width: 0.8,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add_circle_outline,
                                              size: 13,
                                              color: AppConfig.colorPrimary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Add Item',
                                              style: TextStyle(
                                          fontSize: AppFontSizes.body,

                                                fontWeight: FontWeight.w600,
                                                color: AppConfig.colorPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(7, 6, 7, 10),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double screenWidth = constraints.maxWidth;

                            // Responsive values
                            final bool isVerySmall = screenWidth < 340;
                            final bool isSmall = screenWidth < 380;

                    final double labelWidth = isVerySmall ? 52 : 60;
                            final double sectionGap = isVerySmall ? 8 : 14;
                            final double sectionPadding = isVerySmall ? 8 : 14;

                            return Container(
                              padding: EdgeInsets.fromLTRB(
                                isVerySmall ? 9 : 13,
                                10,
                                isVerySmall ? 9 : 13,
                                10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE1E1E1),
                                  width: 0.7,
                                ),
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
                                  // ============================================================
                                  // TOP BILL SUMMARY
                                  // ============================================================
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // ========================================================
                                        // LEFT SECTION
                                        // ========================================================
                                        Expanded(
                                          flex: 6,
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                                right: sectionPadding),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // ================= BILL TYPE =================
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: labelWidth,
                                                      child: const Text(
                                                        'Bill Type',
                                                        style: TextStyle(
                                                    fontSize: AppFontSizes.label,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Color(0xFF222222),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        height: 30,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                            color: const Color(
                                                                0xFFD2D2D2),
                                                            width: 0.7,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        clipBehavior:
                                                            Clip.antiAlias,
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: InkWell(
                                                                onTap: () {
                                                                  setState(() {
                                                                    _billType =
                                                                        'Cash';
                                                                  });
                                                                },
                                                                child:
                                                                    Container(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  color: _billType ==
                                                                          'Cash'
                                                                      ? AppConfig
                                                                          .colorPrimary
                                                                      : Colors
                                                                          .white,
                                                                  child:
                                                                      FittedBox(
                                                                    fit: BoxFit
                                                                        .scaleDown,
                                                                    child: Text(
                                                                      'CASH',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            8.5,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color: _billType ==
                                                                                'Cash'
                                                                            ? Colors.white
                                                                            : const Color(0xFF222222),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: InkWell(
                                                                onTap: () {
                                                                  setState(() {
                                                                    _billType =
                                                                        'Credit';
                                                                  });
                                                                },
                                                                child:
                                                                    Container(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  color: _billType ==
                                                                          'Credit'
                                                                      ? AppConfig
                                                                          .colorPrimary
                                                                      : Colors
                                                                          .white,
                                                                  child:
                                                                      FittedBox(
                                                                    fit: BoxFit
                                                                        .scaleDown,
                                                                    child: Text(
                                                                      'CREDIT',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            8.5,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        color: _billType ==
                                                                                'Credit'
                                                                            ? Colors.white
                                                                            : const Color(0xFF222222),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 9),

                                                // ================= REMARKS =================
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: labelWidth,
                                                      child: const Text(
                                                        'Remarks',
                                                        style: TextStyle(
                                                     fontSize: AppFontSizes.label,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Color(0xFF222222),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: InkWell(
                                                        onTap: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return AlertDialog(
                                                                title: const Text(
                                                                    'Remarks'),
                                                                content:
                                                                    TextField(
                                                                  controller:
                                                                      _remarksController,
                                                                  onChanged:
                                                                      (value) {
                                                                    setState(
                                                                        () {
                                                                      _remarksText =
                                                                          value;
                                                                    });
                                                                  },
                                                                  decoration:
                                                                      const InputDecoration(
                                                                    hintText:
                                                                        'Enter your remarks',
                                                                  ),
                                                                ),
                                                                actions: [
                                                                  MaterialButton(
                                                                    color: AppConfig
                                                                        .colorPrimary,
                                                                    textColor:
                                                                        Colors
                                                                            .white,
                                                                    child:
                                                                        const Text(
                                                                            'OK'),
                                                                    onPressed:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        _remarksText =
                                                                            _remarksController.text;
                                                                      });
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                        child: Container(
                                                          height: 30,
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 9,
                                                          ),
                                                          alignment: Alignment
                                                              .centerLeft,
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border.all(
                                                              color: const Color(
                                                                  0xFFD2D2D2),
                                                              width: 0.7,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                          ),
                                                          child: Text(
                                                            _remarksText.isEmpty
                                                                ? 'Enter remarks (optional)'
                                                                : _remarksText,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                        fontSize: AppFontSizes.label,
                                                              color: _remarksText
                                                                      .isEmpty
                                                                  ? const Color(
                                                                      0xFF9A9A9A)
                                                                  : const Color(
                                                                      0xFF222222),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 9),

                                                // ================= DISCOUNT =================
                                                if (AppState().discountState ==
                                                    'Enable')
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        width: labelWidth,
                                                        child: const Text(
                                                          'Discount',
                                                          style: TextStyle(
                                                          fontSize: AppFontSizes.label,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Color(
                                                                0xFF222222),
                                                          ),
                                                        ),
                                                      ),

                                                      // Responsive discount selector
                                                      // Compact discount toggle (AMT / %)
                                                      Container(
                                                        height: 30,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                            color: const Color(
                                                                0xFFD2D2D2),
                                                            width: 0.7,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        clipBehavior:
                                                            Clip.antiAlias,
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  _isPercentage =
                                                                      false;
                                                                });
                                                              },
                                                              child: Container(
                                                                width: 42,
                                                                height: 30,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                color: !_isPercentage
                                                                    ? AppConfig
                                                                        .colorPrimary
                                                                    : Colors
                                                                        .white,
                                                                child: Text(
                                                                  'AMT',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        8.5,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: !_isPercentage
                                                                        ? Colors
                                                                            .white
                                                                        : const Color(
                                                                            0xFF222222),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  _isPercentage =
                                                                      true;
                                                                });
                                                              },
                                                              child: Container(
                                                                width: 34,
                                                                height: 30,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                color: _isPercentage
                                                                    ? AppConfig
                                                                        .colorPrimary
                                                                    : Colors
                                                                        .white,
                                                                child: Text(
                                                                  '%',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        8.5,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: _isPercentage
                                                                        ? Colors
                                                                            .white
                                                                        : const Color(
                                                                            0xFF222222),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),

                                                      SizedBox(
                                                        width:
                                                            isVerySmall ? 5 : 7,
                                                      ),

                                                      // Discount input (now takes remaining space)
                                                      Expanded(
                                                        child: SizedBox(
                                                          height: 30,
                                                          child: TextField(
                                                            controller:
                                                                _discountData,
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style:
                                                                const TextStyle(
                                                         fontSize: AppFontSizes.value,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: Color(
                                                                  0xFF222222),
                                                            ),
                                                            decoration:
                                                                InputDecoration(
                                                              contentPadding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 2,
                                                                vertical: 6,
                                                              ),
                                                              border:
                                                                  OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4),
                                                                borderSide:
                                                                    const BorderSide(
                                                                  color: Color(
                                                                      0xFFD2D2D2),
                                                                  width: 0.7,
                                                                ),
                                                              ),
                                                              enabledBorder:
                                                                  OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4),
                                                                borderSide:
                                                                    const BorderSide(
                                                                  color: Color(
                                                                      0xFFD2D2D2),
                                                                  width: 0.7,
                                                                ),
                                                              ),
                                                            ),
                                                            onChanged: (_) {
                                                              setState(() {});
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // ========================================================
                                        // VERTICAL DIVIDER
                                        // ========================================================
                                        Container(
                                          width: 0.8,
                                          color: const Color(0xFFE3E3E3),
                                        ),

                                        // ========================================================
                                        // RIGHT SECTION
                                        // ========================================================
                                        Expanded(
                                          flex: 4,
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              left: sectionPadding,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                // ================= TOTAL =================
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Total',
                                                      style: TextStyle(
                                                    fontSize: AppFontSizes.label,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Color(0xFF222222),
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        totalAmount
                                                            .toStringAsFixed(
                                                          AppState()
                                                                  .noOfDecimals ??
                                                              2,
                                                        ),
                                                        textAlign:
                                                            TextAlign.right,
                                                        style: const TextStyle(
                                                     fontSize: AppFontSizes.value,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Color(0xFF222222),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 9),

                                                // ================= VAT =================
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                   Flexible(
  child: Text(
    AppState().taxLabel,
    maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                      fontSize: AppFontSizes.label,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Color(0xFF222222),
                                                        ),
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        tax.toStringAsFixed(
                                                          AppState()
                                                                  .noOfDecimals ??
                                                              2,
                                                        ),
                                                        textAlign:
                                                            TextAlign.right,
                                                        style: const TextStyle(
                                                      fontSize: AppFontSizes.value,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Color(0xFF222222),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                // ================= ROUND OFF =================
                                                if (AppState()
                                                    .roundOffAllowedInInvoice) ...[
                                                  const SizedBox(height: 9),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      const Flexible(
                                                        child: Text(
                                                          'Round Off',
                                                          style: TextStyle(
                                                      fontSize: AppFontSizes.label,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Color(
                                                                0xFF222222),
                                                          ),
                                                        ),
                                                      ),
                                                      InkWell(
                                                        onTap: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return AlertDialog(
                                                                title: const Text(
                                                                    'Round off'),
                                                                content:
                                                                    TextField(
                                                                  keyboardType:
                                                                      const TextInputType
                                                                          .numberWithOptions(
                                                                    signed:
                                                                        true,
                                                                    decimal:
                                                                        true,
                                                                  ),
                                                                  controller:
                                                                      _roundoff,
                                                                  decoration:
                                                                      const InputDecoration(
                                                                    hintText:
                                                                        'Round off',
                                                                  ),
                                                                  onChanged:
                                                                      (value) {
                                                                    final entered =
                                                                        double.tryParse(
                                                                              value,
                                                                            ) ??
                                                                            0;

                                                                    final posLimit =
                                                                        AppState().roundOffPositive ??
                                                                            0;

                                                                    final negLimit =
                                                                        AppState().roundOffNegative ??
                                                                            0;

                                                                    if (entered > 0 &&
                                                                        posLimit >
                                                                            0 &&
                                                                        entered >
                                                                            posLimit) {
                                                                      _roundoff
                                                                              .text =
                                                                          posLimit
                                                                              .toString();

                                                                      _roundoff
                                                                              .selection =
                                                                          TextSelection
                                                                              .fromPosition(
                                                                        TextPosition(
                                                                          offset: _roundoff
                                                                              .text
                                                                              .length,
                                                                        ),
                                                                      );
                                                                    } else if (entered < 0 &&
                                                                        negLimit >
                                                                            0 &&
                                                                        entered <
                                                                            -negLimit) {
                                                                      _roundoff
                                                                              .text =
                                                                          (-negLimit)
                                                                              .toString();

                                                                      _roundoff
                                                                              .selection =
                                                                          TextSelection
                                                                              .fromPosition(
                                                                        TextPosition(
                                                                          offset: _roundoff
                                                                              .text
                                                                              .length,
                                                                        ),
                                                                      );
                                                                    }
                                                                  },
                                                                ),
                                                                actions: [
                                                                  MaterialButton(
                                                                    color: AppConfig
                                                                        .colorPrimary,
                                                                    textColor:
                                                                        Colors
                                                                            .white,
                                                                    child:
                                                                        const Text(
                                                                            'OK'),
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                        child: Container(
                                                          width: isVerySmall
                                                              ? 55
                                                              : 65,
                                                          height: 30,
                                                          alignment:
                                                              Alignment.center,
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border.all(
                                                              color: const Color(
                                                                  0xFFD2D2D2),
                                                              width: 0.7,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                          ),
                                                          child: FittedBox(
                                                            fit: BoxFit
                                                                .scaleDown,
                                                            child: Text(
                                                          roundOffValue.toStringAsFixed(AppState().noOfDecimals ?? 2),
                                                              style:
                                                                  const TextStyle(
                                                            fontSize: AppFontSizes.value,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Color(
                                                                    0xFF222222),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],

                                                const SizedBox(height: 8),

                                                // ================= DIVIDER =================
                                                Container(
                                                  height: 1,
                                                  width: double.infinity,
                                                  color:
                                                      const Color(0xFFE0E0E0),
                                                ),

                                                const SizedBox(height: 7),

                                                // ================= GRAND TOTAL =================
                                              Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    const Text(
      'Grand Total',
      style: TextStyle(
        fontSize: AppFontSizes.label,
        fontWeight: FontWeight.w700,
        color: Color(0xFF222222),
      ),
    ),
    const SizedBox(width: 4),
    Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          roundedGrandTotal
                                                              .toStringAsFixed(
                                                            AppState()
                                                                    .noOfDecimals ??
                                                                2,
                                                          ),
                                                          style: TextStyle(
                                                    fontSize: AppFontSizes.grandTotal,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppConfig
                                                                .colorPrimary,
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

                                  // ============================================================
                                  // BOTTOM BUTTONS
                                  // ============================================================
                                  Row(
                                    children: [
                                      // CLEAR ALL
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            side: const BorderSide(
                                              color: Colors.red,
                                              width: 1.2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: isVerySmall ? 10 : 11,
                                            ),
                                          ),
                                          onPressed: clearCart,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(
                                                  Icons.delete_outline,
                                                  size: 15,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'CLEAR ALL',
                                                  style: TextStyle(
                                            fontSize: AppFontSizes.label,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      // ADD TO CART
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            side: BorderSide(
                                              color: AppConfig.colorPrimary,
                                              width: 1.2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: isVerySmall ? 10 : 11,
                                            ),
                                          ),
                                          onPressed: addToCart,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.add_shopping_cart,
                                                  size: 15,
                                                  color: AppConfig.colorPrimary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'ADD TO CART',
                                                  style: TextStyle(
                                             fontSize: AppFontSizes.label,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppConfig.colorPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      // SAVE SALE
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: savedProducts
                                                        .isNotEmpty &&
                                                    !_isButtonDisabled
                                                ? AppConfig.colorPrimary
                                                : AppConfig.buttonDeactiveColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: isVerySmall ? 10 : 11,
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: (_isButtonDisabled ||
                                                  savedProducts.isEmpty)
                                              ? null
                                              : () async {
                                                  if (!_validateMinRates()) {
                                                    return;
                                                  }

                                                  postDataToApi();
                                                },
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(
                                                  Icons.save_outlined,
                                                  size: 15,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'SAVE SALE',
                                                  style: TextStyle(
                                                fontSize: AppFontSizes.label,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
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
        ));
  }

  // =====================================================================
  // PRODUCT DETAILS MODAL DIALOG — COMPACT UI (matches CopySelectProduct)
  //
  // This dialog has been aligned with the fixed CopySelectProduct dialog:
  //  - Price Matrix no longer scrolls horizontally. All four columns
  //    (Unit, Qty ≥, Rate, Min Rate) always fit using Expanded/flex, and
  //    the "Min Rate" header is wrapped in FittedBox so it can never clip.
  //  - The Rate field loads/reloads through formatRate() (exactly 3
  //    decimal places) and is normalized to 3 decimals only when the
  //    field loses focus/is submitted — never on every keystroke, so the
  //    cursor never jumps while typing.
  //  - "Minimum allowed rate" / below-minimum warning show 3 decimals.
  //  - Existing per-file business logic is preserved unchanged:
  //    isRateEditable (price-group driven), the editing of an existing
  //    saved-cart product, the Save button's price-matrix aware
  //    validation (getApplicableRate()), and updating savedProducts /
  //    SharedPreferences on Save.
  // =====================================================================
  void showProductDetailsDialog(
      BuildContext context, Map<String, dynamic> product) async {
    String url =
        '${RestDatasource().BASE_URL}/api/get_product_with_units_by_products?store_id=${AppState().storeId}&van_id=${AppState().vanId}&id=${product['id']}';

    final response = await http.get(Uri.parse(url));

    final typeResponse = await http.get(
      Uri.parse('${RestDatasource().BASE_URL}/api/get_product_type'),
    );

    if (response.statusCode == 200 && typeResponse.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("========== PRODUCT DETAILS API ==========");
      print(response.body);
      print("========================================");
      final rawData = data['data'];
      final List<dynamic> units = rawData is List
          ? rawData
          : rawData is Map
              ? rawData.values.toList()
              : [];
      final lastsale = data['lastsale'];

      final typeData = jsonDecode(typeResponse.body);
      final rawTypeData = typeData['data'];
      final List<dynamic> productTypes = rawTypeData is List
          ? rawTypeData
          : rawTypeData is Map
              ? rawTypeData.values.toList()
              : [];
      final amountController = TextEditingController();
      // Focus node for the Rate field: normalizes the value to exactly 3
      // decimals only when the user leaves the field, instead of on
      // every keystroke (avoids cursor jumping while typing).
      final FocusNode rateFocusNode = FocusNode();
      bool rateFocusListenerAdded = false;
      final existingProduct = savedProducts.firstWhere(
        (p) => p['serial_number'] == product['serial_number'],
        orElse: () => product,
      );
      double? availableStock;
      bool priceMatrixExpanded = true;
      String? selectedUnitId = existingProduct['unit_id'];
      String? selectedProductTypeId = existingProduct['type_id'];
      String? quantity = existingProduct['quantity'];
      bool isQuantityValid(String? value) {
        final quantityValue = double.tryParse(value ?? '') ?? 0;

        return value != null &&
            value.isNotEmpty &&
            quantityValue > 0 &&
            quantityValue <= (availableStock ?? 0);
      }

      Map<String, dynamic>? selectedUnit;

      List<Map<String, double>> rateMatrix = [];

      if (selectedUnitId != null && units.isNotEmpty) {
        selectedUnit = units.firstWhere(
            (unit) => unit['id'].toString() == selectedUnitId,
            orElse: () => null);

        availableStock =
            double.tryParse(selectedUnit?['stock']?.toString() ?? '0');

        rateMatrix = parseRateMatrix(selectedUnit?['minimum_rate_matrix']);
      }

      // Determine if the saved product type is FOC (rate legitimately 0).
      final String? existingTypeName = productTypes
          .firstWhere(
            (type) => type['id'].toString() == selectedProductTypeId,
            orElse: () => null,
          )?['name']
          ?.toString();
      final bool existingIsFOC = (existingTypeName?.toUpperCase() == 'FOC');

      final String? savedAmount = existingProduct['amount'];
      final double savedAmountValue = double.tryParse(savedAmount ?? '0') ?? 0;

      if (!existingIsFOC && savedAmountValue <= 0 && selectedUnit != null) {
        // Stale zero rate (e.g. product was FOC before, now Normal) —
        // fall back to the unit's standard price instead of showing 0.
        amountController.text = formatRate(selectedUnit['price']);
      } else if (savedAmount != null && savedAmount.isNotEmpty) {
        amountController.text = formatRate(savedAmount);
      }

      List<String> serialNumbers =
          product['serial_numbers'] != null && product['serial_numbers'] is List
              ? List<String>.from(product['serial_numbers'])
              : [];

      // ---- design tokens (UI-only, compact variant — same as CopySelectProduct) ----
      const Color kPrimary = AppConfig.colorPrimary;
      final Color kPrimarySoft = AppConfig.colorPrimary.withOpacity(0.08);
      const Color kGreen = Color(0xFF1E9E5A);
      final Color kGreenSoft = const Color(0xFF1E9E5A).withOpacity(0.08);
      const Color kBorder = Color(0xFFE7E4F2);
      const Color kTextMuted = Color(0xFF7A7A8C);

      Widget sectionLabel(String text) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              text,
              style: const TextStyle(
             fontSize: AppFontSizes.value,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          );

      // AFTER: Full width SizedBox + softWrap: false + scaleDown guarantees clean single-line date on all screens.

      Widget infoCard({
        required IconData icon,
        required String label,
        required String value,
        double valueFontSize =
            10.5, // ✅ Slightly reduced base size for responsive fit
      }) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: kPrimarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 13, color: kPrimary),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9.5, color: kTextMuted),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: double
                    .infinity, // ✅ Stretches to full card width so FittedBox can scale down
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap:
                        false, // ✅ Guarantees single-line display without wrapping
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.55),
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              // Normalize the Rate field to 3 decimals only when the user
              // leaves the field — never on every keystroke, so the cursor
              // doesn't jump while typing. Listener is attached once.
              if (!rateFocusListenerAdded) {
                rateFocusListenerAdded = true;
                rateFocusNode.addListener(() {
                  if (!rateFocusNode.hasFocus) {
                    setDialogState(() {
                      amountController.text = formatRate(amountController.text);
                    });
                  }
                });
              }

              final double enteredQtyForHeader =
                  double.tryParse(quantity ?? '0') ?? 0;
              final double amt = double.tryParse(amountController.text) ?? 0;
              final double lineAmount = enteredQtyForHeader * amt;
              final double fallbackMinRateForInfo = double.tryParse(
                      selectedUnit?['min_price']?.toString() ?? '0') ??
                  0;
              final double applicableMinRate = getApplicableRate(
                rateMatrix,
                enteredQtyForHeader,
                fallbackMinRateForInfo,
              );

// FOC products don't need min-rate enforcement — rate is
// always 0 by design for this product type.
              final String? selectedTypeName = productTypes
                  .firstWhere(
                    (type) => type['id'].toString() == selectedProductTypeId,
                    orElse: () => null,
                  )?['name']
                  ?.toString();
              final bool isFOC = (selectedTypeName?.toUpperCase() == 'FOC');

              Map<String, double>? matchedSlab;
              for (var slab in rateMatrix) {
                if (enteredQtyForHeader >= slab['qty']!) {
                  matchedSlab = slab;
                }
              }

              // ---- Rate field editability: single source of truth so the
              // label and the actual field state can never disagree.
              // (Existing per-file logic — unchanged.) ----
              final bool isRateEditable = true;
              // ---- Responsive sizing: ~92% width, capped for tablets ----
              final screenSize = MediaQuery.of(context).size;
              final double rawWidth = screenSize.width * 0.92;
              final double dialogWidth =
                  rawWidth > 480 ? 480 : rawWidth; // cap for large screens
              final double dialogMaxHeight = screenSize.height * 0.85;
              final double horizontalInset =
                  (screenSize.width - dialogWidth) / 2;

              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                insetPadding: EdgeInsets.symmetric(
                  horizontal: horizontalInset,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: dialogWidth,
                    maxHeight: dialogMaxHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ============= FIXED HEADER (compact) =============
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${product['code']} | ${product['name'].toString().toUpperCase()}',
                                softWrap: true,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  height: 1.25,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (selectedUnit != null)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kGreenSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.inventory_2_rounded,
                                            size: 11, color: kGreen),
                                        const SizedBox(width: 3),
                                        const Text(
                                          'Avail. Qty',
                                          style: TextStyle(
                                      fontSize: AppFontSizes.label,
                                            color: kGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '${selectedUnit!['stock'] ?? '0'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: kGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.close,
                                  size: 20, color: Colors.black45),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: kBorder),

                      // ============= SCROLLABLE BODY (compact) =============
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // -------- Last Sale Rate / Unit / Last Sold Date (compact) --------
                              // ✅ Card 1 displays 'Last Sale' (rate), Card 2 displays 'Unit', Card 3 displays 'Last Sold' (date).

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. LAST SALE RATE
                                  Expanded(
                                    child: infoCard(
                                      icon: Icons.sell_outlined,
                                      label: 'Last Sale',
                                      value: (lastsale != null &&
                                              lastsale.isNotEmpty)
                                          ? formatRate(lastsale[
                                              'price']) // Displays previous rate (e.g. 9.000)
                                          : '—',
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  // 2. UNIT
                                  Expanded(
                                    child: infoCard(
                                      icon: Icons.inventory_2_outlined,
                                      label: 'Unit',
                                      value:
                                          selectedUnit?['name']?.toString() ??
                                              '—',
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  // 3. LAST SOLD DATE
                                  Expanded(
                                    child: infoCard(
                                      icon: Icons.calendar_today_outlined,
                                      label: 'Last Sold',
                                      value: (lastsale != null &&
                                              lastsale.isNotEmpty)
                                          ? DateHelper.displayDate(lastsale[
                                              'date']) // Displays previous date (e.g. 06-Aug-2026)
                                          : '—',
                                      valueFontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                              if (lastsale == null || lastsale.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'No last sale record',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: kTextMuted,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),

                              const SizedBox(height: 10),

                              // -------- PRICE MATRIX (Unit, Qty ≥, Rate, Min Rate) — compact --------
                              // No horizontal scrolling: the table always
                              // fits the dialog width using Expanded/flex
                              // columns for all four columns.
                              if (selectedUnit != null &&
                                  rateMatrix.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: kPrimarySoft,
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                            ),
                                            child: Icon(
                                              Icons.bar_chart_rounded,
                                              size: 14,
                                              color: kPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () {
                                                setDialogState(() {
                                                  priceMatrixExpanded =
                                                      !priceMatrixExpanded;
                                                });
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4),
                                                child: Text(
                                                  'PRICE MATRIX',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: kPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              setDialogState(() {
                                                priceMatrixExpanded =
                                                    !priceMatrixExpanded;
                                              });
                                            },
                                            icon: Icon(
                                              priceMatrixExpanded
                                                  ? Icons
                                                      .keyboard_arrow_up_rounded
                                                  : Icons
                                                      .keyboard_arrow_down_rounded,
                                              color: kPrimary,
                                              size: 24,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            splashRadius: 18,
                                          ),
                                        ],
                                      ),
                                      if (priceMatrixExpanded) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Rate will be applied based on the quantity.',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: kTextMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 7),

                                        // Fixed-width table — no horizontal
                                        // scrolling. All four columns use
                                        // Expanded/flex so they always fit
                                        // the dialog width.
                                        Column(
                                          children: [
                                            // ---- HEADER ----
                                            // AFTER: Balanced flex (3:2:3:3), zero awkward gap, perfect right alignment.

                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 7,
                                                horizontal:
                                                    8, // ✅ Standardized padding matching data rows
                                              ),
                                              decoration: BoxDecoration(
                                                color: kPrimarySoft,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(8),
                                                  topRight: Radius.circular(8),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  // Unit -> LEFT aligned
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text(
                                                      'Unit',
                                                      textAlign: TextAlign.left,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 10.5,
                                                        color: kPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  // Qty -> RIGHT aligned
                                                  Expanded(
                                                    flex:
                                                        2, // ✅ Balanced compact flex
                                                    child: Text(
                                                      'Qty',
                                                      textAlign:
                                                          TextAlign.right,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 10.5,
                                                        color: kPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  // Rate -> RIGHT aligned
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text(
                                                      'Rate',
                                                      textAlign:
                                                          TextAlign.right,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 10.5,
                                                        color: kPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  // Min Rate -> RIGHT aligned
                                                  Expanded(
                                                    flex:
                                                        3, // ✅ Changed from 5 to 3 to eliminate empty space
                                                    child: Text(
                                                      'Min Rate',
                                                      textAlign:
                                                          TextAlign.right,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 10.5,
                                                        color: kPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // ---- ROWS ----
                                            // AFTER: Right aligned Qty, Rate, and Min Rate with matching flex (3:2:3:3) and horizontal padding (8)

                                            ...rateMatrix
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              final index = entry.key;
                                              final slab = entry.value;
                                              final enteredQty =
                                                  double.tryParse(
                                                          quantity ?? '0') ??
                                                      0;
                                              final currentQty =
                                                  slab['qty'] ?? 0;
                                              final nextQty = index <
                                                      rateMatrix.length - 1
                                                  ? rateMatrix[index + 1]['qty']
                                                  : null;
                                              final isApplicable =
                                                  enteredQty >= currentQty &&
                                                      (nextQty == null ||
                                                          enteredQty < nextQty);
                                              final unitName =
                                                  selectedUnit?['name']
                                                          ?.toString() ??
                                                      '';
                                              final minRate = slab['rate'] ?? 0;

                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 8,
                                                  horizontal:
                                                      8, // ✅ Matches header padding
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isApplicable
                                                      ? kPrimarySoft
                                                      : Colors.white,
                                                  border: Border(
                                                    left: BorderSide(
                                                        color: kBorder),
                                                    right: BorderSide(
                                                        color: kBorder),
                                                    bottom: BorderSide(
                                                        color: kBorder),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // Unit -> LEFT aligned
                                                    Expanded(
                                                      flex: 3,
                                                      child: Text(
                                                        unitName,
                                                        textAlign:
                                                            TextAlign.left,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              isApplicable
                                                                  ? FontWeight
                                                                      .bold
                                                                  : FontWeight
                                                                      .normal,
                                                          fontSize: 11.5,
                                                        ),
                                                      ),
                                                    ),
                                                    // Qty -> RIGHT aligned
                                                    Expanded(
                                                      flex:
                                                          2, // ✅ Flex 2 matches header
                                                      child: Text(
                                                        currentQty
                                                            .toStringAsFixed(0),
                                                        textAlign: TextAlign
                                                            .right, // ✅ Explicit Right alignment
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              isApplicable
                                                                  ? FontWeight
                                                                      .bold
                                                                  : FontWeight
                                                                      .normal,
                                                          fontSize: 11.5,
                                                        ),
                                                      ),
                                                    ),
                                                    // Rate -> RIGHT aligned
                                                    Expanded(
                                                      flex:
                                                          3, // ✅ Flex 3 matches header
                                                      child: Text(
                                                        (slab['rate'] ?? 0)
                                                            .toStringAsFixed(2),
                                                        textAlign: TextAlign
                                                            .right, // ✅ Explicit Right alignment
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              isApplicable
                                                                  ? FontWeight
                                                                      .bold
                                                                  : FontWeight
                                                                      .normal,
                                                          fontSize: 11.5,
                                                        ),
                                                      ),
                                                    ),
                                                    // Min Rate -> RIGHT aligned
                                                    Expanded(
                                                      flex:
                                                          3, // ✅ Flex 3 matches header
                                                      child: minRate > 0
                                                          ? Text(
                                                              minRate
                                                                  .toStringAsFixed(
                                                                      2),
                                                              textAlign: TextAlign
                                                                  .right, // ✅ Explicit Right alignment
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1,
                                                              style: TextStyle(
                                                                fontWeight: isApplicable
                                                                    ? FontWeight
                                                                        .bold
                                                                    : FontWeight
                                                                        .normal,
                                                                fontSize: 11.5,
                                                              ),
                                                            )
                                                          : Text(
                                                              'No limit',
                                                              textAlign: TextAlign
                                                                  .right, // ✅ Explicit Right alignment
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1,
                                                              style: TextStyle(
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                                color:
                                                                    kTextMuted,
                                                                fontSize: 10.5,
                                                              ),
                                                            ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                            // ---- INFO MESSAGE ----
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 7,
                                                horizontal: 7,
                                              ),
                                              decoration: BoxDecoration(
                                                color: kPrimarySoft,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(8),
                                                  bottomRight:
                                                      Radius.circular(8),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.info_outline_rounded,
                                                    size: 13,
                                                    color: kPrimary,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Expanded(
                                                    child: Text(
                                                      'Highlighted row shows the pricing level applicable for the entered quantity.',
                                                      softWrap: true,
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        color: kPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ] else if (selectedUnit != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: Colors.red.shade100),
                                  ),
                                  child: Text(
                                    "Minimum Rate : ${selectedUnit?['min_price'] ?? '0'}",
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],

                              // -------- Product Type + Unit (always side by side) --------
                              if (units.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          sectionLabel('Product Type'),
                                          _buildDropdown<String>(
                                            value: selectedProductTypeId,
                                            hint: 'Select Product Type',
                                            items: productTypes.map(
                                              (type) {
                                                return DropdownMenuItem<String>(
                                                  value: type['id'].toString(),
                                                  child: Text(type['name']),
                                                );
                                              },
                                            ).toList(),
                                            onChanged: (value) {
                                              setDialogState(() {
                                                selectedProductTypeId = value;
                                                final selectedType =
                                                    productTypes.firstWhere(
                                                  (type) =>
                                                      type['id'].toString() ==
                                                      value,
                                                  orElse: () => null,
                                                );
                                                if (selectedType != null &&
                                                    selectedType['name'] !=
                                                        'Normal') {
                                                  amountController.text =
                                                      formatRate(0);
                                                } else if (selectedUnit !=
                                                    null) {
                                                  amountController.text =
                                                      formatRate(selectedUnit?[
                                                          'price']);
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          sectionLabel('Unit'),
                                          _buildDropdown<String>(
                                            value: selectedUnitId,
                                            hint: 'Select Unit',
                                            items: units
                                                .where((unit) => unit != null)
                                                .map((unit) {
                                              return DropdownMenuItem<String>(
                                                value: unit['id'].toString(),
                                                child: Text(unit['name']),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setDialogState(() {
                                                selectedUnitId = value;
                                                selectedUnit = units.firstWhere(
                                                  (unit) =>
                                                      unit['id'].toString() ==
                                                      value,
                                                  orElse: () => null,
                                                );
                                                amountController.text =
                                                    formatRate(
                                                        selectedUnit?['price']);
                                                availableStock =
                                                    double.tryParse(
                                                  selectedUnit?['stock']
                                                          ?.toString() ??
                                                      '0',
                                                );
                                                rateMatrix = parseRateMatrix(
                                                  selectedUnit?[
                                                      'minimum_rate_matrix'],
                                                );
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // -------- Quantity + Rate (always side by side) --------
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          sectionLabel('Quantity *'),
                                          _buildTextField(
                                            initialValue: quantity,
                                            keyboardType: TextInputType.number,
                                            icon: Icons.swap_vert_rounded,
                                            autofocus: true, // 👈 new
                                            onChanged: (value) {
                                              quantity = value;
                                              setDialogState(() {});
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Label always matches the field's
                                          // actual editability
                                          // (isRateEditable is the single
                                          // source of truth for both).
                                          // Existing per-file business logic
                                          // — unchanged.
                                          sectionLabel('Rate *'),
                                          _buildTextField(
                                            controller: amountController,
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                                decimal: true),
                                            readOnly: false,
                                            focusNode: rateFocusNode,
                                            suffixIcon: Icons.edit_outlined,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'^\d*\.?\d{0,3}'),
                                              ),
                                            ],
                                            onChanged: (_) {
                                              setDialogState(() {});
                                            },
                                            onFieldSubmitted: (_) {
                                              setDialogState(() {
                                                amountController.text =
                                                    formatRate(
                                                        amountController.text);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                if (selectedUnit != null && !isFOC)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'Minimum allowed rate: '
                                      '${applicableMinRate.toStringAsFixed(3)}',
                                      style: TextStyle(
                                        color: amt < applicableMinRate
                                            ? Colors.red
                                            : kGreen,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),

                                if (!isFOC &&
                                    amountController.text.isNotEmpty &&
                                    amt < applicableMinRate)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      'Amount cannot be less than Minimum Rate '
                                      '(${applicableMinRate.toStringAsFixed(3)})',
                                      style: const TextStyle(
                                        color: Colors.red,
                                      fontSize: AppFontSizes.label,
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 10),

                                // -------- Amount (compact) --------
                                sectionLabel('Amount'),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calculate_outlined,
                                          size: 16, color: kTextMuted),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          lineAmount.toStringAsFixed(
                                              AppState().noOfDecimals ?? 2),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: kPrimarySoft,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Calculated',
                                          style: TextStyle(
                                         fontSize: AppFontSizes.body,
                                            color: kPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // -------- Price Source (compact) --------
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: kGreenSoft,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: kGreen.withOpacity(0.25)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          size: 16, color: kGreen),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rateMatrix.isNotEmpty &&
                                                      matchedSlab != null
                                                  ? 'Price Source: Qty ${quantity ?? 0} matched Price Matrix Level (Min Qty ${matchedSlab['qty']!.toStringAsFixed(0)})'
                                                  : 'Price Source: Standard Unit Price',
                                              softWrap: true,
                                              style: const TextStyle(
                                             fontSize: AppFontSizes.label,
                                                fontWeight: FontWeight.w600,
                                                color: kGreen,
                                              ),
                                            ),
                                            if (rateMatrix.isNotEmpty &&
                                                matchedSlab != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Rate: ${matchedSlab['rate']!.toStringAsFixed(2)}  |  Min Allowed Rate: ${applicableMinRate.toStringAsFixed(2)}',
                                                softWrap: true,
                                                style: const TextStyle(
                                             fontSize: AppFontSizes.label,
                                                  color: kGreen,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (serialNumbers.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  sectionLabel('Serial Numbers'),
                                  ...serialNumbers.map((serialNumber) {
                                    int index =
                                        serialNumbers.indexOf(serialNumber);
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: _buildTextField(
                                        initialValue: serialNumber,
                                        hintText: 'Serial Number ${index + 1}',
                                        icon:
                                            Icons.confirmation_number_outlined,
                                        onChanged: (value) {
                                          serialNumbers[index] = value;
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ] else ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                      'No units available for this product.',
                                      style: TextStyle(fontSize: 12.5)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const Divider(height: 1, color: kBorder),

                      // ============= FIXED FOOTER: Cancel / Save (compact) =============
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                      color: kPrimary, width: 1.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 11),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      color: kPrimary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            if (units.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: Builder(builder: (_) {
                                  final double enteredRate =
                                      double.tryParse(amountController.text) ??
                                          0;
                                  final double enteredQtyCheck =
                                      double.tryParse(quantity ?? '0') ?? 0;
                                  final double minimumRateCheck =
                                      getApplicableRate(
                                          rateMatrix,
                                          enteredQtyCheck,
                                          double.tryParse(
                                                  selectedUnit?['min_price']
                                                          ?.toString() ??
                                                      '0') ??
                                              0);
                                  final bool isAmountOk =
                                      isFOC || enteredRate >= minimumRateCheck;
                                  final bool canSave =
                                      isQuantityValid(quantity) && isAmountOk;

                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          canSave ? kPrimary : Colors.grey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 11),
                                      elevation: 0,
                                    ),
                                    onPressed: canSave
                                        ? () async {
                                            // Ensure the value stored is the
                                            // normalized 3-decimal string,
                                            // even if Save is tapped while
                                            // the field still has focus.
                                            amountController.text = formatRate(
                                                amountController.text);
                                            final double finalRate =
                                                double.tryParse(amountController
                                                        .text) ??
                                                    0;
                                            if (!isFOC &&
                                                finalRate < minimumRateCheck) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "Amount cannot be less than Minimum Rate (${minimumRateCheck.toStringAsFixed(3)})",
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            if (selectedUnitId != null &&
                                                selectedProductTypeId != null &&
                                                quantity != null &&
                                                amountController.text != null) {
                                              final productIndex = savedProducts
                                                  .indexWhere((p) =>
                                                      p['serial_number'] ==
                                                      product['serial_number']);
                                              if (productIndex != -1) {
                                                setState(() {
                                                  savedProducts[productIndex]
                                                          ['unit_id'] =
                                                      selectedUnitId;
                                                  savedProducts[productIndex]
                                                          ['type_id'] =
                                                      selectedProductTypeId;
                                                  savedProducts[productIndex]
                                                      ['quantity'] = quantity;
                                                  savedProducts[productIndex]
                                                          ['amount'] =
                                                      amountController.text;
                                                  savedProducts[productIndex]
                                                          ['min_price'] =
                                                      selectedUnit?['min_price']
                                                              ?.toString() ??
                                                          '0';
                                                  savedProducts[productIndex][
                                                          'minimum_rate_matrix'] =
                                                      selectedUnit?[
                                                                  'minimum_rate_matrix']
                                                              ?.toString() ??
                                                          '';
                                                  savedProducts[productIndex]
                                                          ['type_name'] =
                                                      productTypes.firstWhere(
                                                    (type) =>
                                                        type['id'].toString() ==
                                                        selectedProductTypeId,
                                                    orElse: () => {'name': ''},
                                                  )['name'];
                                                  savedProducts[productIndex]
                                                          ['unit_name'] =
                                                      selectedUnit?['name'];
                                                  _updateCalculations();
                                                });
                                                final prefs =
                                                    await SharedPreferences
                                                        .getInstance();
                                                final savedProductsStringList =
                                                    savedProducts
                                                        .map((product) =>
                                                            jsonEncode(product))
                                                        .toList();
                                                await prefs.setStringList(
                                                    'selected_products',
                                                    savedProductsStringList);

                                                Navigator.of(context).pop();
                                              }
                                            }
                                          }
                                        : null,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.save_outlined,
                                            color: Colors.white, size: 16),
                                        SizedBox(width: 5),
                                        Text(
                                          'Save',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ).then((_) {
        _isDialogOpen = false;
      });
    }
  }

  // ---- Display-only date formatter (UI formatting only, no logic change) ----
  // Converts an ISO-ish date string (e.g. "2026-08-06") to "06 Aug 2026".
  // Falls back to the original raw value if it can't be parsed.

  // ---- small reusable UI builders for the redesigned dialog (compact, UI-only) ----
  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    const Color kBorder = Color(0xFFE7E4F2);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: kBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<T>(
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 9),
          ),
          items: items,
          onChanged: onChanged,
          value: value,
          hint: Text(hint,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis),
          isExpanded: true,
          style: const TextStyle(fontSize: 12.5, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? initialValue,
    String? hintText,
    TextInputType? keyboardType,
    bool readOnly = false,
    bool autofocus = false, // 👈 new
    IconData? icon,
    IconData? suffixIcon,
    FocusNode? focusNode,
    List<TextInputFormatter>? inputFormatters,
    required void Function(String) onChanged,
    void Function(String)? onFieldSubmitted,
  }) {
    const Color kBorder = Color(0xFFE7E4F2);
    const Color kPrimary = AppConfig.colorPrimary;

    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      keyboardType: keyboardType,
      readOnly: readOnly,
      autofocus: autofocus, // 👈 new
      focusNode: focusNode,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,

      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 12),
        prefixIcon:
            icon != null ? Icon(icon, size: 16, color: Colors.black45) : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 0),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: 15, color: kPrimary)
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF4F3FA) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: kPrimary, width: 1.3),
        ),
      ),
    );
  }
}
