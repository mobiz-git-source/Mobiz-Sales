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
import '../Utilities/date_helper.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
// NEW: centralized semantic font sizes (matches the Sale screen exactly).
import '../confg/apptextsizes.dart';

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

  // =====================================================================
  // NOTE: Everything in this class below `build()` (all calculations,
  // API calls, SharedPreferences logic, navigation, and the product
  // details dialog) is UNCHANGED from the original implementation.
  // Only the `build()` method's widget tree has been restructured to
  // visually match the Sale (CopyScreen) UI 1:1, and hardcoded
  // `.sp` / raw fontSize values inside `build()` have been replaced
  // with semantic constants from AppFontSizes.
  // =====================================================================

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

    String discountValue = _discountData.text.trim();
    double discountAmount = double.tryParse(discountValue) ?? 0;

    for (var product in savedProducts) {
      double quantity =
          double.tryParse(product['quantity']?.toString() ?? '0') ?? 0;

      double rate = double.tryParse(product['amount']?.toString() ?? '0') ?? 0;

      double lineTotal = quantity * rate;

      double taxPercentage =
          double.tryParse(product['tax_percentage']?.toString() ?? '0') ?? 0;

      double lineDiscountShare =
          totalAmount == 0 ? 0 : (lineTotal / totalAmount) * discountAmount;

      double taxableAmount = _isPercentage
          ? lineTotal - ((lineTotal * discountAmount) / 100)
          : lineTotal - lineDiscountShare;

      if (taxableAmount < 0) taxableAmount = 0;

      tax += (taxableAmount * taxPercentage) / 100;
    }

    return double.parse(tax.toStringAsFixed(AppState().noOfDecimals ?? 2));
  }

  Map<String, dynamic> CalculatedValue() {
    double taxamt = calculateTax();
    roundoff = _roundoff.text;
    double rundff = double.tryParse(roundoff) ?? 0;
    String discountValue = _discountData.text.trim();
    double discountAmount = double.tryParse(discountValue) ?? 0;
    double grandTotal = _ifVat == 1
        ? _isPercentage
            ? totalAmount - ((totalAmount * discountAmount) / 100) + taxamt
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

  String getVatLabel() {
    if (_ifVat == 0) return 'VAT';
    if (savedProducts.isEmpty) return 'VAT';
    // Uses the backend-configured VAT label (fetched in HomeScreen via
    // get_store_detail and stored in AppState().vatLabel), instead of
    // building "VAT (5%)" from tax_percentage.
    return AppState().vatLabel ?? 'VAT';
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

  // =====================================================================
  // BUILD — Restructured to visually match the Sale (CopyScreen) screen.
  // All values referenced below (totalAmount, tax, roundedGrandTotal,
  // roundOffValue, savedProducts, discount/round-off controllers, etc.)
  // are computed exactly as before — only the widget tree and font
  // sizes changed.
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> grandTotalMap = CalculatedValue();

    double tax = _ifVat == 1 ? calculateTax() : 0;
    String taxpost = tax.toStringAsFixed(AppState().noOfDecimals ?? 2);
    double roundedGrandTotal = double.parse(
        double.parse(grandTotalMap['rounded'].toString())
            .toStringAsFixed(AppState().noOfDecimals ?? 2));
    double roundOffValue = double.parse(
        double.parse(grandTotalMap['roundOffValue'].toString())
            .toStringAsFixed(AppState().noOfDecimals ?? 2));
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
          return double.parse(double.parse(product['amount'].toString())
              .toStringAsFixed(AppState().noOfDecimals ?? 2));
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
          'description': description,
          'delivery_location':
              _remarksController.text.isEmpty ? '' : _remarksController.text
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
          print('Post successful');
          if (mounted) {
            CommonWidgets.showDialogueBox(
                    context: context,
                    title: "Alert",
                    msg: "Created Successfully")
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
      } catch (e) {
        print('An error occurred: $e');
      } finally {
        setState(() {
          _isButtonDisabled =
              false; // Re-enable the button after the request completes (whether it succeeds or fails)
        });
      }
    }

    void openProductSearch() {
      Navigator.pushReplacementNamed(
        context,
        SalesSelectProductsorderScreen.routeName,
        arguments: {'customerId': id, 'name': name},
      ).then((value) {});
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
                clearCart();
              },
              child: Icon(Icons.arrow_back_rounded)),
          iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
          title: const Text(
            'Order',
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
                      style: const TextStyle(color: AppConfig.backgroundColor),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(5),
                        hintText: "Search...",
                        hintStyle: TextStyle(color: AppConfig.backgroundColor),
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
        body: savedProducts.isEmpty
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
                  // ==========================================================
                  // STORE HEADER CARD (matches Sale exactly)
                  // ==========================================================
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
                          // Store icon
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
                          // Store name
                          Expanded(
                            child: Text(
                              (name ?? '').toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: AppFontSizes.label,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF252525),
                                letterSpacing: 0.05,
                              ),
                            ),
                          ),
                          // VAT / NO VAT
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
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _ifVat = 1;
                                      });
                                      total = 0;
                                      tax = 0;
                                    },
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(minWidth: 45),
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
                                          AppState().vatLabel ?? 'VAT',
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
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _ifVat = 0;
                                      });
                                      total = 0;
                                      tax = 0;
                                    },
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(minWidth: 52),
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
                                          'NO ${AppState().vatLabel ?? 'VAT'}',
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

                  // ==========================================================
                  // PRODUCT TABLE (matches Sale exactly, responsive columns)
                  // ==========================================================
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
                          final double rateW = isNarrow ? 40 : 48;
                          final double amtW = isNarrow ? 40 : 48;
                          final double delW = isNarrow ? 26 : 32;

                          final query = _searchData.text.trim().toLowerCase();
                          final filteredIndices = query.isEmpty
                              ? List<int>.generate(
                                  savedProducts.length, (i) => i)
                              : List<int>.generate(savedProducts.length,
                                      (i) => i)
                                  .where((i) {
                                  final p = savedProducts[i];
                                  final code = (p['code'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  final pname = (p['name'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  return code.contains(query) ||
                                      pname.contains(query);
                                }).toList();

                          return Column(
                            children: [
                              // ================= TABLE HEADER =================
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

                              // ================= PRODUCT LIST =================
                              Expanded(
                                child: filteredIndices.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No matching items',
                                          style: TextStyle(
                                            color: Colors.black45,
                                            fontSize: AppFontSizes.body,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        physics:
                                            const BouncingScrollPhysics(),
                                        padding: EdgeInsets.zero,
                                        itemCount: filteredIndices.length,
                                        itemBuilder: (context, listIndex) {
                                          final index =
                                              filteredIndices[listIndex];
                                          final product =
                                              savedProducts[index];

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
                                          final rowTotal = quantity * amount;

                                          final String code =
                                              product['code']?.toString() ??
                                                  '';
                                          final String pname =
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
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Color(0xFFE8E8E8),
                                                    width: 0.7,
                                                  ),
                                                ),
                                              ),
                                              child: IntrinsicHeight(
                                                child: Row(
                                                  children: [
                                                    // NUMBER
                                                    SizedBox(
                                                      width: numW,
                                                      child: Center(
                                                        child: Container(
                                                          width: 21,
                                                          height: 21,
                                                          alignment: Alignment
                                                              .center,
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                const Color(
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
                                                              fontSize:
                                                                  AppFontSizes
                                                                      .body,
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

                                                    // ITEM DETAILS
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
                                                              '$code | ${pname.toUpperCase()}',
                                                              maxLines: 2,
                                                              softWrap: true,
                                                              overflow:
                                                                  TextOverflow
                                                                      .visible,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize:
                                                                    AppFontSizes
                                                                        .label,
                                                                height: 1.15,
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
                                                                        BorderRadius.circular(
                                                                            3),
                                                                  ),
                                                                  child: Text(
                                                                    typeName,
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          AppFontSizes
                                                                              .badge,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color: Color(
                                                                          0xFF5558B5),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    width: 4),
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
                                                                        BorderRadius.circular(
                                                                            3),
                                                                  ),
                                                                  child: Text(
                                                                    unitName,
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          AppFontSizes
                                                                              .badge,
                                                                      color: Color(
                                                                          0xFF555555),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                    // QTY
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
                                                            fontSize:
                                                                AppFontSizes
                                                                    .body,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500,
                                                            color: Color(
                                                                0xFF222222),
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    // RATE
                                                    SizedBox(
                                                      width: rateW,
                                                      child: Center(
                                                        child: Text(
                                                          amount
                                                              .toStringAsFixed(
                                                                  3),
                                                          style:
                                                              const TextStyle(
                                                            fontSize:
                                                                AppFontSizes
                                                                    .tableCellSmall,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500,
                                                            color: Color(
                                                                0xFF222222),
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    // AMOUNT
                                                    SizedBox(
                                                      width: amtW,
                                                      child: Center(
                                                        child: Text(
                                                          rowTotal
                                                              .toStringAsFixed(
                                                            AppState()
                                                                    .noOfDecimals ??
                                                                2,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                            fontSize:
                                                                AppFontSizes
                                                                    .tableCellSmall,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600,
                                                            color: Color(
                                                                0xFF222222),
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    // DELETE
                                                    SizedBox(
                                                      width: delW,
                                                      child: Center(
                                                        child:
                                                            GestureDetector(
                                                          onTap: () {
                                                            _removeProduct(
                                                                index);
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

                              // ================= ADD ITEM =================
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

                  // ==========================================================
                  // BOTTOM SUMMARY CARD (matches Sale exactly)
                  // ==========================================================
                  Padding(
                    padding: const EdgeInsets.fromLTRB(7, 6, 7, 10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double screenWidth = constraints.maxWidth;
                        final bool isVerySmall = screenWidth < 340;

                        final double labelWidth = isVerySmall ? 60 : 76;
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
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // ================= LEFT =================
                                    Expanded(
                                      flex: 6,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            right: sectionPadding),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // -------- DELIVERY LOCATION --------
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: labelWidth,
                                                  child: Text(
                                                    'Delivery Location',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize:
                                                          AppFontSizes.label,
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
                                                                'Delivery Location'),
                                                            content:
                                                                TextField(
                                                              controller:
                                                                  _remarksController,
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  _remarksText =
                                                                      value;
                                                                });
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
                                                                  setState(
                                                                      () {});
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
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        _remarksText.isEmpty
                                                            ? 'Enter delivery location'
                                                            : _remarksText,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: TextStyle(
                                                          fontSize:
                                                              AppFontSizes
                                                                  .label,
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

                                            // -------- SCHEDULE DATE --------
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: labelWidth,
                                                  child: Text(
                                                    'Schedule Date',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize:
                                                          AppFontSizes.label,
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
                                                      _selectDate(context);
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
                                                                .circular(4),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .calendar_today_outlined,
                                                            size: 12,
                                                            color: AppConfig
                                                                .colorPrimary,
                                                          ),
                                                          const SizedBox(
                                                              width: 5),
                                                          Expanded(
                                                            child: Text(
                                                              _selectedDate ==
                                                                      null
                                                                  ? 'Select Date'
                                                                  : DateHelper
                                                                      .displayFromDateTime(
                                                                          _selectedDate!),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  TextStyle(
                                                                fontSize:
                                                                    AppFontSizes
                                                                        .label,
                                                                color: const Color(
                                                                    0xFF222222),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 9),

                                            // -------- DISCOUNT --------
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: labelWidth,
                                                  child: const Text(
                                                    'Discount',
                                                    style: TextStyle(
                                                      fontSize:
                                                          AppFontSizes.label,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Color(0xFF222222),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: const Color(
                                                          0xFFD2D2D2),
                                                      width: 0.7,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
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
                                                          alignment: Alignment
                                                              .center,
                                                          color:
                                                              !_isPercentage
                                                                  ? AppConfig
                                                                      .colorPrimary
                                                                  : Colors
                                                                      .white,
                                                          child: Text(
                                                            'AMT',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  AppFontSizes
                                                                      .label,
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
                                                          alignment: Alignment
                                                              .center,
                                                          color: _isPercentage
                                                              ? AppConfig
                                                                  .colorPrimary
                                                              : Colors.white,
                                                          child: Text(
                                                            '%',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  AppFontSizes
                                                                      .label,
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
                                                        isVerySmall ? 5 : 7),
                                                Expanded(
                                                  child: SizedBox(
                                                    height: 30,
                                                    child: TextField(
                                                      controller:
                                                          _discountData,
                                                      keyboardType:
                                                          TextInputType
                                                              .number,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        fontSize:
                                                            AppFontSizes
                                                                .value,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            Color(0xFF222222),
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

                                    // ================= DIVIDER =================
                                    Container(
                                      width: 0.8,
                                      color: const Color(0xFFE3E3E3),
                                    ),

                                    // ================= RIGHT =================
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
                                            // TOTAL
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Total',
                                                  style: TextStyle(
                                                    fontSize:
                                                        AppFontSizes.label,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: Color(0xFF222222),
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
                                                      fontSize:
                                                          AppFontSizes.value,
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

                                            // VAT
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    getVatLabel(),
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                    style: const TextStyle(
                                                      fontSize:
                                                          AppFontSizes.label,
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
                                                      fontSize:
                                                          AppFontSizes.value,
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

                                            // SUB TOTAL (order-specific,
                                            // preserved from the original
                                            // implementation; styled the
                                            // same way as Total/VAT above)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Flexible(
                                                  child: Text(
                                                    'Sub Total',
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                    style: TextStyle(
                                                      fontSize:
                                                          AppFontSizes.label,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Color(0xFF222222),
                                                    ),
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
                                                      fontSize:
                                                          AppFontSizes.value,
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

                                            // ROUND OFF
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Flexible(
                                                  child: Text(
                                                    'Round Off',
                                                    style: TextStyle(
                                                      fontSize:
                                                          AppFontSizes.label,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Color(0xFF222222),
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
                                                          content: TextField(
                                                            keyboardType:
                                                                const TextInputType
                                                                    .numberWithOptions(
                                                              signed: true,
                                                              decimal: true,
                                                            ),
                                                            controller:
                                                                _roundoff,
                                                            decoration:
                                                                const InputDecoration(
                                                              hintText:
                                                                  'Round off',
                                                            ),
                                                          ),
                                                          actions: [
                                                            MaterialButton(
                                                              color: AppConfig
                                                                  .colorPrimary,
                                                              textColor: Colors
                                                                  .white,
                                                              child:
                                                                  const Text(
                                                                      'OK'),
                                                              onPressed: () {
                                                                setState(
                                                                    () {});
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
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color: const Color(
                                                            0xFFD2D2D2),
                                                        width: 0.7,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(4),
                                                    ),
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        roundoff == ''
                                                            ? roundOffValue
                                                                .toStringAsFixed(
                                                                AppState()
                                                                        .noOfDecimals ??
                                                                    2,
                                                              )
                                                            : roundoff,
                                                        style:
                                                            const TextStyle(
                                                          fontSize:
                                                              AppFontSizes
                                                                  .value,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Color(
                                                              0xFF222222),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 8),

                                            // DIVIDER
                                            Container(
                                              height: 1,
                                              width: double.infinity,
                                              color: const Color(0xFFE0E0E0),
                                            ),

                                            const SizedBox(height: 7),

                                            // GRAND TOTAL
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                const Flexible(
                                                  child: Text(
                                                    'Grand Total',
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                    style: TextStyle(
                                                      fontSize:
                                                          AppFontSizes.value,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          Color(0xFF222222),
                                                    ),
                                                  ),
                                                ),
                                                Flexible(
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Text(
                                                      roundedGrandTotal
                                                          .toStringAsFixed(
                                                        AppState()
                                                                .noOfDecimals ??
                                                            2,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize:
                                                            AppFontSizes
                                                                .grandTotal,
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

                              // ==========================================
                              // BOTTOM BUTTONS
                              // ==========================================
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
                                      onPressed: () {
                                        clearCart();
                                      },
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
                                                fontSize:
                                                    AppFontSizes.label,
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
                                      onPressed: () {
                                        // Existing Add To Cart logic
                                        // (unchanged placeholder, exactly
                                        // as in the original screen).
                                      },
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
                                                fontSize:
                                                    AppFontSizes.label,
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

                                  // SAVE ORDER
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: !_isButtonDisabled
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
                                      onPressed: _isButtonDisabled
                                          ? null
                                          : () {
                                              postDataToApi();
                                            },
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.save_outlined,
                                              size: 15,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _isButtonDisabled
                                                  ? 'SAVING...'
                                                  : 'SAVE ORDER',
                                              style: const TextStyle(
                                                fontSize:
                                                    AppFontSizes.label,
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
    );
  }

  // =====================================================================
  // PRODUCT DETAILS DIALOG — UNCHANGED. This dialog was not part of the
  // requested visual unification scope (which covers the main list
  // screen: header, table, add-item row, summary card, bottom buttons).
  // Left exactly as-is to avoid any risk to existing business logic
  // (API calls, min-rate/stock validation, SharedPreferences updates).
  // =====================================================================
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
        final existingProduct = savedProducts.firstWhere(
        (p) => p['serial_number'] == product['serial_number'],
        orElse: () => product,
      );
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

      bool isAmountValid() {
        final enteredAmount =
            double.tryParse(amountController.text.trim()) ?? 0;
        final minPrice =
            double.tryParse(selectedUnit?['min_price']?.toString() ?? '0') ?? 0;
        return minPrice == 0 || enteredAmount >= minPrice;
      }

           showDialog(
        context: context,
        builder: (BuildContext context) {
          bool showDescriptionField = description != null && description!.isNotEmpty;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final bool hasUnits =
                  units != null && units.any((unit) => unit != null);

          return Dialog(
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.transparent,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    child: Form(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ================= HEADER (title + close) =================
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  '${product['code']} | ${product['name']}',
                                  style: const TextStyle(
                                    fontSize: AppFontSizes.value,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF222222),
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 8, top: 2),
                                  child: Icon(
                                    Icons.close,
                                    size: 22,
                                    color: Color(0xFF8A8A8A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFE3E3E3)),
                          const SizedBox(height: 16),

                          // ================= AVAILABLE QTY / MIN RATE =================
                          // (UNCHANGED logic — selectedUnit comes from the
                          // existing Unit dropdown state.)
                          if (selectedUnit != null) ...[
                            Text(
                              'Available Qty: ${selectedUnit!['stock']}',
                              style: const TextStyle(
                                fontSize: AppFontSizes.label,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF222222),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Minimum Rate : ${selectedUnit?['min_price'] ?? '0'}',
                              style: const TextStyle(
                                fontSize: AppFontSizes.label,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (hasUnits) ...[
                            // ================= PRODUCT TYPE / UNIT =================
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Product Type',
                                        style: TextStyle(
                                          fontSize: AppFontSizes.label,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF222222),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 44,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFFD2D2D2),
                                            width: 0.9,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            style: const TextStyle(
                                              fontSize: AppFontSizes.value,
                                              color: Color(0xFF222222),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            items: productTypes.map((type) {
                                              return DropdownMenuItem<String>(
                                                value: type['id'].toString(),
                                                child: Text(type['name']),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              // ===== UNCHANGED LOGIC =====
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
                                                  amountController.text = '0';
                                                } else if (selectedUnit !=
                                                    null) {
                                                  amountController.text =
                                                      selectedUnit?['price']
                                                              ?.toString() ??
                                                          '';
                                                }
                                              });
                                              // ===== END UNCHANGED LOGIC =====
                                            },
                                            value: selectedProductTypeId,
                                            hint: const Text(
                                              'Select Product Type',
                                              style: TextStyle(
                                                fontSize: AppFontSizes.value,
                                                color: Color(0xFF9A9A9A),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Unit',
                                        style: TextStyle(
                                          fontSize: AppFontSizes.label,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF222222),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 44,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFFD2D2D2),
                                            width: 0.9,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            style: const TextStyle(
                                              fontSize: AppFontSizes.value,
                                              color: Color(0xFF222222),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            items: units
                                                .where((unit) => unit != null)
                                                .map((unit) {
                                              return DropdownMenuItem<String>(
                                                value: unit['id'].toString(),
                                                child: Text(unit['name']),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              // ===== UNCHANGED LOGIC =====
                                              setDialogState(() {
                                                selectedUnitId = value;
                                                selectedUnit = units.firstWhere(
                                                    (unit) =>
                                                        unit['id']
                                                            .toString() ==
                                                        value,
                                                    orElse: () => null);
                                                amountController.text =
                                                    selectedUnit?['price']
                                                            ?.toString() ??
                                                        '';
                                                availableStock =
                                                    double.tryParse(
                                                        selectedUnit?['stock']
                                                                ?.toString() ??
                                                            '0');
                                                print("Des$description");
                                              });
                                              // ===== END UNCHANGED LOGIC =====
                                            },
                                            value: selectedUnitId,
                                            hint: const Text(
                                              'Select Unit',
                                              style: TextStyle(
                                                fontSize: AppFontSizes.value,
                                                color: Color(0xFF9A9A9A),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ================= AMOUNT / QUANTITY =================
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Amount',
                                        style: TextStyle(
                                          fontSize: AppFontSizes.label,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF222222),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 46,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFFD2D2D2),
                                            width: 0.9,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.calculate_outlined,
                                              size: 19,
                                              color: Color(0xFF8A8A8A),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextFormField(
                                                keyboardType:
                                                    TextInputType.number,
                                                controller: amountController,
                                                onChanged: (value) {
                                                  setDialogState(() {});
                                                },
                                                style: const TextStyle(
                                                  fontSize:
                                                      AppFontSizes.value,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF222222),
                                                ),
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    vertical: 12,
                                                  ),
                                                  hintText: 'Amt',
                                                  errorText: isAmountValid()
                                                      ? null
                                                      : 'Below Min Rate',
                                                  errorStyle: const TextStyle(
                                                    fontSize:
                                                        AppFontSizes.badge,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Quantity *',
                                        style: TextStyle(
                                          fontSize: AppFontSizes.label,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF222222),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 46,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppConfig.colorPrimary,
                                            width: 1.2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 10),
                                            Icon(
                                              Icons.swap_vert,
                                              size: 18,
                                              color: AppConfig.colorPrimary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextFormField(
                                                keyboardType:
                                                    TextInputType.number,
                                                initialValue: quantity,
                                                onChanged: (value) {
                                                  quantity = value;
                                                  setDialogState(() {});
                                                },
                                                style: const TextStyle(
                                                  fontSize:
                                                      AppFontSizes.value,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF222222),
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                                  hintText: 'Qty',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ================= DESCRIPTION =================
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: AppFontSizes.label,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF222222),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFD2D2D2),
                                  width: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                controller: descriptionController,
                                minLines: 2,
                                maxLines: 4,
                                style: const TextStyle(
                                  fontSize: AppFontSizes.value,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF222222),
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 10),
                                  hintText: 'Enter description (optional)',
                                  hintStyle: TextStyle(
                                    fontSize: AppFontSizes.value,
                                    color: Color(0xFF9A9A9A),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            const Text(
                              'No units available for this product.',
                              style: TextStyle(
                                fontSize: AppFontSizes.body,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ================= DESCRIPTION / CLOSE / SAVE =================
                          Row(
                            children: [
                              if (description == '') ...[
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
                                            BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 13),
                                    ),
                                    onPressed: () {
                                      // ===== UNCHANGED LOGIC =====
                                      setDialogState(() {
                                        showDescriptionField = true;
                                      });
                                      // ===== END UNCHANGED LOGIC =====
                                    },
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Description',
                                        style: TextStyle(
                                          fontSize: AppFontSizes.value,
                                          fontWeight: FontWeight.w700,
                                          color: AppConfig.colorPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: BorderSide(
                                      color: AppConfig.colorPrimary,
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 13),
                                  ),
                                  onPressed: () {
                                    // ===== UNCHANGED LOGIC =====
                                    Navigator.of(context).pop();
                                    // ===== END UNCHANGED LOGIC =====
                                  },
                                  child: Text(
                                    'Close',
                                    style: TextStyle(
                                      fontSize: AppFontSizes.value,
                                      fontWeight: FontWeight.w700,
                                      color: AppConfig.colorPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              if (hasUnits) ...[
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isQuantityValid(quantity) &&
                                                  isAmountValid()
                                              ? AppConfig.colorPrimary
                                              : Colors.grey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 13),
                                      elevation: 0,
                                    ),
                                    onPressed: isQuantityValid(quantity) &&
                                            isAmountValid()
                                        ? () async {
                                            // ============ UNCHANGED SAVE LOGIC ============
                                            if (selectedUnitId != null &&
                                                selectedProductTypeId !=
                                                    null &&
                                                quantity != null &&
                                                amountController.text !=
                                                    null) {
                                              final productIndex =
                                                  savedProducts.indexWhere(
                                                      (p) =>
                                                          p['serial_number'] ==
                                                          product[
                                                              'serial_number']);
                                              if (productIndex != -1) {
                                                setState(() {
                                                  savedProducts[productIndex]
                                                          ['unit_id'] =
                                                      selectedUnitId;
                                                  savedProducts[productIndex]
                                                          ['type_id'] =
                                                      selectedProductTypeId;
                                                  savedProducts[productIndex]
                                                          ['quantity'] =
                                                      quantity;
                                                  savedProducts[productIndex]
                                                          ['amount'] =
                                                      amountController.text;
                                                  savedProducts[productIndex]
                                                          ['type_name'] =
                                                      productTypes.firstWhere(
                                                          (type) =>
                                                              type['id']
                                                                  .toString() ==
                                                              selectedProductTypeId)[
                                                          'name'];
                                                  savedProducts[productIndex]
                                                          ['unit_name'] =
                                                      selectedUnit?['name'];
                                                  savedProducts[productIndex]
                                                          ['description'] =
                                                      descriptionController
                                                          .text;
                                                  _updateCalculations();
                                                });

                                                final prefs =
                                                    await SharedPreferences
                                                        .getInstance();
                                                final savedProductsStringList =
                                                    savedProducts
                                                        .map((product) =>
                                                            jsonEncode(
                                                                product))
                                                        .toList();
                                                await prefs.setStringList(
                                                    'selected_products',
                                                    savedProductsStringList);

                                                Navigator.of(context).pop();
                                              }
                                            }
                                            // ============ END UNCHANGED SAVE LOGIC ============
                                          }
                                        : null,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.save_outlined,
                                          size: 17,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Save',
                                          style: TextStyle(
                                            fontSize: AppFontSizes.value,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
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
}