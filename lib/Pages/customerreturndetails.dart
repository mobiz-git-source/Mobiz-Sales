import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/paymentcollection.dart';
import 'package:mobizapp/Pages/salesselectproductreturn.dart';
import 'package:mobizapp/selectproduct.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Components/commonwidgets.dart';
import '../Models/sales_model.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
// NEW: centralized semantic font sizes (matches the Sale screen exactly).
import '../confg/apptextsizes.dart';
import 'TestReturn.dart';
import 'homereturn.dart';

class Customerreturndetail extends StatefulWidget {
  static const routeName = "/Customerreturndetail";

  @override
  _CustomerreturndetailState createState() => _CustomerreturndetailState();
}

int? id;

// =====================================================================
// NOTE: Everything below `build()` (all calculations, API calls,
// SharedPreferences logic, navigation, and the item-details dialog) is
// UNCHANGED from the original implementation. Only `build()`'s widget
// tree has been restructured to visually match the Sale (CopyScreen)
// screen, and hardcoded `.sp`/raw fontSize values inside `build()` have
// been replaced with semantic constants from AppFontSizes.
// =====================================================================
class _CustomerreturndetailState extends State<Customerreturndetail> {
  late String initialQty;
  int specificIndex = 0;
  List<Product> cartItems = [];
  bool _search = false;
  Reason? _selectedReason;
  List<Reason> _reasonList = [];
  bool _isPercentage = false;
  final TextEditingController _discountData = TextEditingController();
  final TextEditingController amountctrl = TextEditingController();
  final TextEditingController qtysctrl = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  String _remarksText = "";
  Map<int, String> amounts = {};
  final TextEditingController _roundoff = TextEditingController(text: '0');
  Map<int, String> qtys = {};
  TextEditingController _searchData = TextEditingController();
  String? selectedUnitName;
  List<ProductType> productTypes = [];
  List<ProductType?> selectedProductTypes =
      []; // List to store selected product types
  String? name;
  // String? code;
  String? paymentTerms;
  String? paydata;
  int _ifVat = 1;
  String roundoff = '';
  // num tax = 0;
  String? code;
  int? dataId;
  int? saleId;
  int? pricegroupId;
  String? payment;
  String amount = '';
  String quantity = '';
  bool _isButtonDisabled = false;
  bool _hasData = false;
  bool _fetchCartItemsComplete = false;
  bool _fetchSalesReturnDataComplete = false;
  bool _showButton = false;

   @override
  void initState() {
    super.initState();
     AppState().loadTaxName().then((_) {
      if (mounted) setState(() {});
    });
    fetchCartItems();
    fetchProductTypes();
    initializeValues();
    fetchReasons();
    setInitialQty();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if arguments are passed via the ModalRoute and extract them
      if (ModalRoute.of(context)!.settings.arguments != null) {
        final Map<String, dynamic>? params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        id = params!['customerId'];
        name = params['name'];
        code = params!['code'];
        payment = params!['paymentTerms'];
        dataId = params!['dataId'];
        saleId = params!['saleId'];
        paydata = params!['outstandamt'];
        pricegroupId = params!['price_group_id'];
        print("OutStand:$saleId");
      }
      fetchSalesReturnData();
    });
  }

  Future<void> addToCart(Product product) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItems = prefs.getStringList('cartItemsreturn') ?? [];

    // Count how many instances of the product are already in the cart
    int productCount = cartItems.fold(0, (count, item) {
      Map<String, dynamic> itemMap = jsonDecode(item);
      return itemMap['id'] == product.id ? count + 1 : count;
    });

    // Restriction logic based on the number of units
    if (product.units.length == 1) {
      if (productCount >= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} is already in the cart')),
        );
        return;
      }
    } else if (product.units.length == 2) {
      if (productCount >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only 2 ${product.name} can be added')),
        );
        return;
      }
    }

    // Add product to cart
    cartItems.add(jsonEncode(product.toJson()));
    await prefs.setStringList('cartItemsreturn', cartItems);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added')),
    );
  }

  Future<void> fetchSalesReturnData() async {
    try {
      print("DataaIID");
      print(dataId);
      final url = Uri.parse(
          '${RestDatasource().BASE_URL}/api/get-sales-return.empty-product?store_id=${AppState().storeId}&id=$dataId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print(response.request);
        final data = jsonDecode(response.body);
        print("========== RETURN API FULL RESPONSE ==========");
        print(response.body);
        print("================================================");
        if (data != null && data['data'] != null) {
          List<Product> fetchedProducts = [];

          if (data['data'] is List && data['data'].isNotEmpty) {
            fetchedProducts = (data['data'] as List).map((item) {
              print("========== VAT API DEBUG ==========");
              print("Product ID       : ${item['id']}");
              print("Product Name     : ${item['name']}");
              print("Tax              : ${item['tax']}");
              print("Tax Percentage   : ${item['tax_percentage']}");
              print("VAT Label        : ${item['vat_label']}");
              print("VAT              : ${item['vat']}");
              print("Tax Label        : ${item['tax_label']}");
              print("ALL KEYS         : ${item.keys.toList()}");
              print("FULL ITEM        : $item");
              print("===================================");

              Product product = Product.fromJson(item);
              product.defaultValue = 1;
              return product;
            }).toList();
            cartItems.addAll(fetchedProducts);
            for (var product in fetchedProducts) {
              await addToCart(product);
            }
            _showButton = false; // No need to show the button if data exists.
          } else if (data['data'] is Map && (data['data'] as Map).isNotEmpty) {
            // ============ NEW: single-item key check ============
            print("---------- SINGLE ITEM KEYS ----------");
            print((data['data'] as Map).keys.toList());
            print("stock: ${data['data']['stock']}");
            print("min_price: ${data['data']['min_price']}");
            print(
                "minimum_rate_matrix: ${data['data']['minimum_rate_matrix']}");
            print("units: ${data['data']['units']}");
            print("---------------------------------------");
            // ====================================================
            Product product = Product.fromJson(data['data']);
            product.defaultValue = 1;
            cartItems.add(product);
            await addToCart(product);
            _showButton =
                false; // No need to show the button if data exists (matches old code behavior).
          } else {
            _showButton =
                true; // Show button if no data is found (empty list/map).
          }

          if (dataId != null) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('dataId', dataId.toString());
          }

          selectedProductTypes = List.generate(
            cartItems.length,
            (index) => null,
          );
          setState(() {
            _fetchSalesReturnDataComplete = true;
          });
          await initializeValues();
        } else {
          _showButton = true; // Show button if no data is found.
        }
      } else {
        throw Exception('Failed to load sales return data');
      }
    } catch (e) {
      _showButton = true; // Show button in case of error.
      print(e);
    } finally {
      if (mounted) {
        setState(() {}); // Update the UI if the widget is still mounted.
      }
    }
  }

  Future<void> fetchCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItemsJson = prefs.getStringList('cartItemsreturn');

    if (cartItemsJson != null) {
      // Clear cartItems to avoid duplicates
      cartItems.clear();

      // Convert JSON strings to Product objects
      List<Product> products = cartItemsJson
          .map((json) => Product.fromJson(jsonDecode(json)))
          .toList();

      cartItems.sort((a, b) {
        return a.isSelected ? -1 : (b.isSelected ? 1 : 0);
      });
      setState(() {
        cartItems.addAll(products);
        selectedProductTypes = List.generate(
          cartItems.length,
          (index) => null,
        );
        _fetchCartItemsComplete = true;
      });
      await initializeValues();
    }
    print('cartItemsJson');
    print(cartItemsJson);
  }

  void setInitialQty() {
    if (cartItems.isNotEmpty && cartItems[specificIndex].units.isNotEmpty) {
      initialQty = cartItems[specificIndex].units[0].stock?.toString() ?? '1';
    } else {
      initialQty = '1'; // Fallback value if cartItems or units is empty
    }
  }

  Future<void> fetchReasons() async {
    final response = await http.get(Uri.parse(
        'http://68.183.92.8:3699/api/get-water-reason?store_id=${AppState().storeId}'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['data'] != null) {
        setState(() {
          _reasonList = (data['data'] as List)
              .map((item) => Reason.fromJson(item))
              .toList();
        });
      } else {
        throw Exception('Reasons not found in the response');
      }
    } else {
      throw Exception('Failed to load reasons');
    }
  }

  double calculateTotalRate() {
    double total = 0;
    for (int index = 0; index < cartItems.length; index++) {
      double rate = double.tryParse(
              amounts[index] ?? cartItems[index].price.toString()) ??
          0;
      // FIX: Use double.tryParse instead of int.tryParse for quantity
      double quantity = double.tryParse(qtys[index] ?? '1') ?? 1.0;
      total += rate * quantity;
    }
    return total;
  }

  double calculateTax() {
    double totalAmount = calculateTotalRate();
    String discountValue = _discountData.text.trim();
    double discountAmount = double.tryParse(discountValue) ?? 0;
    double tax = 0;

    for (int index = 0; index < cartItems.length; index++) {
      double rate = double.tryParse(
              amounts[index] ?? cartItems[index].price.toString()) ??
          0;
      double quantity = double.tryParse(qtys[index] ?? '1') ?? 1.0;
      double lineTotal = rate * quantity;
      num taxPercentage = cartItems[index].taxPercentage;

      double lineDiscountShare =
          totalAmount == 0 ? 0 : (lineTotal / totalAmount) * discountAmount;

      double taxableAmount = _isPercentage
          ? lineTotal - ((lineTotal * discountAmount) / 100)
          : lineTotal - lineDiscountShare;

      if (taxableAmount < 0) taxableAmount = 0;

      tax += (taxableAmount * taxPercentage) / 100;
    }

    return _vatRound(tax);
  }
// Half-up rounding (0.215 -> 0.22), matches backend
// Half-up rounding (0.215 -> 0.22), matches backend
  double _r(double v) {
    final int dec = AppState().noOfDecimals ?? 2;
    double f = 1;
    for (int i = 0; i < dec; i++) {
      f *= 10;
    }
    final double sign = v < 0 ? -1 : 1;
    return sign * ((v.abs() * f) + 1e-9).roundToDouble() / f;
  }

  // VAT backend-pole 2 decimal-il half-up round cheyyan
  double _vatRound(double v) {
    final double sign = v < 0 ? -1 : 1;
    return sign * ((v.abs() * 100) + 1e-9).roundToDouble() / 100;
  }

  Map<String, dynamic> grandTotal() {
    double totalAmount = calculateTotalRate();
    double taxamt = calculateTax();
    String discountValue = _discountData.text.trim();
    double discountAmount = double.tryParse(discountValue) ?? 0;

    // Calculate net amount after discount
    double netAmount;
    if (_isPercentage) {
      netAmount = totalAmount - (totalAmount * discountAmount / 100);
    } else {
      netAmount = totalAmount - discountAmount;
    }

    // Calculate grand total
    double grandTotal = _r(_ifVat == 1 ? netAmount + taxamt : netAmount);

    // Handle round off
    String roundoffText = _roundoff.text.trim();
    double roundOffInput = double.tryParse(roundoffText) ?? 0.0;

    double roundedGrandTotal;
    double roundOffValue;

    if (roundoffText.isEmpty) {
      // Auto round off
      roundedGrandTotal = customRound(grandTotal).toDouble();
      roundOffValue = _r(roundedGrandTotal - grandTotal);
    } else {
      // Manual round off
      roundOffValue = _r(roundOffInput);
      roundedGrandTotal = _r(grandTotal + roundOffValue);
    }
    return {
      'rounded': roundedGrandTotal,
      'roundOffValue': roundOffValue,
    };
  }

  double customRound(double value) {
    double fractionalPart = value - value.floorToDouble();

    if (fractionalPart >= 0.5) {
      return value.ceilToDouble();
    } else {
      return value.floorToDouble();
    }
  }

  Future<void> removeFromCart(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItemsJson = prefs.getStringList('cartItemsreturn');

    if (cartItemsJson != null) {
      // Decode the JSON strings to Product objects
      List<Product> products = cartItemsJson
          .map((json) => Product.fromJson(jsonDecode(json)))
          .toList();

      // Validate index and remove product
      if (index >= 0 && index < products.length) {
        products.removeAt(index);

        // Encode the updated list back to JSON and save it
        List<String> updatedCartItemsJson =
            products.map((product) => jsonEncode(product.toJson())).toList();
        await prefs.setStringList('cartItemsreturn', updatedCartItemsJson);

        // Remove item-specific shared preferences entries for this index
        await prefs.remove(_productTypeKey(index));
        await prefs.remove('unitNamereturn$index');
        await prefs.remove('qtyreturn$index');
        await prefs.remove('amountreturn$index');

        // Refresh cartItems list in UI
        fetchCartItems();
      }
    }
  }

  Future<void> clearCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('cartItemsreturn');
    setState(() {
      cartItems.clear();
    });
  }

  Future<void> saveToSharedPreferences(String key, dynamic value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
  }

  Future<void> initializeValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (productTypes.isNotEmpty && cartItems.isNotEmpty) {
      setState(() {
        for (int i = 0; i < cartItems.length; i++) {
          qtys[i] = prefs.getString('qtyreturn$i') ?? '1';
          amounts[i] = prefs.getString('amountreturn$i') ??
              cartItems[i].price.toString();

          if (cartItems[i].units.isNotEmpty) {
            final savedUnit = prefs.getString('unitNamereturn$i');
            final bool validUnit = savedUnit != null &&
                cartItems[i].units.any((u) => u.name == savedUnit);
            cartItems[i].selectedUnitName =
                validUnit ? savedUnit : cartItems[i].units.first.name;
          }

          if (i < selectedProductTypes.length) {
            final savedType = prefs.getString(_productTypeKey(i));
            ProductType? match;
            for (final t in productTypes) {
              if (savedType != null && t.name == savedType) {
                match = t;
                break;
              }
            }
            selectedProductTypes[i] = match;
          }
        }
      });
    }
  }

  Future<void> clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> _onBackPressed() async {
    clearSharedPreferences();
    // Your custom function logic here
    print('Back button pressed');
    // You can also show a dialog, navigate to another page, etc.
  }

  // =====================================================================
  // BUILD — Restructured to visually match the Sale (CopyScreen) screen.
  // All values referenced below (totals, tax, roundedGrandTotal,
  // roundOffValue, cartItems, qtys/amounts maps, discount/round-off
  // controllers, the Reason dropdown, etc.) are computed exactly as
  // before — only the widget tree and font sizes changed.
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> grandTotalMap = grandTotal();

    double total = calculateTotalRate();
    double tax = _ifVat == 1 ? calculateTax() : 0;
    var roundedGrandTotal = grandTotalMap['rounded']
            ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
        '0.00';

    double roundOffValue = grandTotalMap['roundOffValue'];

    void postDataToApi() async {
      if (!_fetchCartItemsComplete && !_fetchSalesReturnDataComplete) {
        print("Data sources are not fully loaded yet.");
        return;
      }

      // Product types load aayittillenkil
      if (productTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Product types loading. Please try again.')),
        );
        fetchProductTypes().catchError((_) {});
        return;
      }

      // Ellaa item-num type select cheythittundo
      for (int i = 0; i < cartItems.length; i++) {
        if (i >= selectedProductTypes.length ||
            selectedProductTypes[i] == null ||
            !productTypes.any((p) => p.id == selectedProductTypes[i]!.id)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Please select product type for item ${i + 1}')),
          );
          return;
        }
      }

      setState(() {
        _isButtonDisabled = true;
      });
      try {
        var url =
            Uri.parse('${RestDatasource().BASE_URL}/api/vansales_return.store');
        List<double> quantities = [];
        List<Object> productTypesList = [];
        List<int> selectedUnitIds = [];

        for (int index = 0; index < cartItems.length; index++) {
          String? selectedUnitName = cartItems[index].selectedUnitName;
          int selectedUnitId = selectedUnitName != null
              ? cartItems[index]
                  .units
                  .firstWhere(
                    (unit) => unit.name == selectedUnitName,
                    orElse: () => cartItems[index].units.first,
                  )
                  .unit!
              : cartItems[index].units.first.unit!;

          selectedUnitIds.add(selectedUnitId);
          String? qty = qtys[index];
          double quantity = qty != null ? double.parse(qty) : 1.0;
          quantities.add(quantity);

          productTypesList.add(selectedProductTypes[index]!.id);
        }

        var data = {
          'van_id': AppState().vanId ?? 0,
          'store_id': AppState().storeId ?? 0,
          'user_id': AppState().userId ?? 0,
          'item_id': cartItems.map((item) => item.id ?? 0).toList(),
          'quantity': quantities,
          'unit': selectedUnitIds,
          'mrp': amounts.entries
                  .map((entry) {
                    double value = double.tryParse(entry.value) ?? 0.0;
                    return double.parse(
                        value.toStringAsFixed(AppState().noOfDecimals ?? 2));
                  })
                  .toList()
                  .isEmpty
              ? [0.0]
              : amounts.entries.map((entry) {
                  double value = double.tryParse(entry.value) ?? 0.0;
                  print("sdsds$value");
                  return double.parse(
                      value.toStringAsFixed(AppState().noOfDecimals ?? 2));
                }).toList(),
          'customer_id': id ?? 0,
          'if_vat': _ifVat == 1 ? 1 : 0,
          'product_type': productTypesList,
          'total_tax': tax,
          'discount_type': _isPercentage ? '1' : '0',
          'discount': _discountData.text.isEmpty ? '0' : _discountData.text,
          'total': _r(total),
          'round_off': roundOffValue,
          'grand_total': roundedGrandTotal,
          'reason_id': _selectedReason?.id ?? 0,
          'remarks': _remarksText,
          'payment_terms': payment ?? 'N/A',
        };

        var response = await http.post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: json.encode(data),
        );

        if (response.statusCode == 200) {
          print(data);
          print('Post successful');
          var responseBody = json.decode(response.body);
          int returnId = responseBody['data']['id'];
          print(id.toString());
          if (mounted) {
            CommonWidgets.showDialogueBox(
              context: context,
              title: "Alert",
              msg: "Created Successfully",
            ).then((value) {
              clearCart();
              if (pricegroupId != null) {
                Navigator.pushReplacementNamed(
                  context,
                  PaymentCollectionScreen.routeName,
                  arguments: {
                    'customerId': id,
                    'name': name,
                    'code': code,
                    'saleId': saleId,
                    'returnId': returnId,
                    'paymentTerms': payment,
                    'outstandamt': paydata,
                    'price_group_id': pricegroupId
                  },
                );
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  HomereturnScreen.routeName,
                );
              }
            });
          }
        } else {
          print('Post failed with status: ${response.statusCode}');
          print(response.body);
        }
      } catch (e, st) {
        print('An error occurred: $e');
        print(st);
      } finally {
        setState(() {
          _isButtonDisabled = false;
        });
      }
    }

    return WillPopScope(
        onWillPop: () async {
          await _onBackPressed();
          return true;
        },
        child: Scaffold(
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: cartItems.isEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.buttonDeactiveColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 11,
                        ),
                      ),
                      onPressed: null,
                      child: const Text(
                        'SAVE',
                        style: TextStyle(
                          fontSize: AppFontSizes.label,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_showButton) ...[
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.colorPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 11,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            PaymentCollectionScreen.routeName,
                            arguments: {
                              'customerId': id,
                              'name': name,
                              'code': code,
                              'saleId': saleId,
                              'paymentTerms': payment,
                              'outstandamt': paydata,
                              'price_group_id': pricegroupId,
                            },
                          );
                        },
                        child: const Text(
                          'SKIP',
                          style: TextStyle(
                            fontSize: AppFontSizes.label,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              : null,
          appBar: AppBar(
            leading: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  clearSharedPreferences();
                },
                child: Icon(Icons.arrow_back_rounded)),
            iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
            title: const Text(
              'Return',
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
                        onChanged: (value) {
                          setState(() {});
                        },
                        style: TextStyle(color: AppConfig.backgroundColor),
                        cursorColor: AppConfig.backgroundColor,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(5),
                          hintText: "Search...",
                          hintStyle:
                              TextStyle(color: AppConfig.backgroundColor),
                          border: InputBorder.none,
                        ),
                      ),
                    )
                  : Container(),
              CommonWidgets.horizontalSpace(1),
              GestureDetector(
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
            child: cartItems.isEmpty
                ? Center(
                    child: InkWell(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                          context,
                          Salesselectproductreturn.routeName,
                          arguments: {
                            'customerId': id,
                            'name': name,
                            'code': code,
                            'saleId': saleId,
                            'paymentTerms': payment,
                            'outstandamt': paydata,
                            'price_group_id': pricegroupId,
                          },
                        );
                      },
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
                              // VAT IN / NO VAT (content unchanged, styled like Sale)
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
                                        },
                                        child: Container(
                                          constraints: const BoxConstraints(
                                              minWidth: 45),
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
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _ifVat = 0;
                                          });
                                        },
                                        child: Container(
                                          constraints: const BoxConstraints(
                                              minWidth: 52),
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
                              final double rateW = isNarrow ? 44 : 52;
                              final double amtW = isNarrow ? 44 : 52;
                              final double delW = isNarrow ? 26 : 32;

                              final query =
                                  _searchData.text.trim().toLowerCase();
                              final filteredIndices = query.isEmpty
                                  ? List<int>.generate(
                                      cartItems.length, (i) => i)
                                  : List<int>.generate(
                                      cartItems.length, (i) => i).where((i) {
                                      final code = (cartItems[i].code ?? '')
                                          .toString()
                                          .toLowerCase();
                                      final pname = (cartItems[i].name ?? '')
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
                                            padding: EdgeInsets.zero,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemCount: filteredIndices.length,
                                            itemBuilder: (context, listIndex) {
                                              final index =
                                                  filteredIndices[listIndex];

                                              List<String> unitNames =
                                                  cartItems[index]
                                                      .units
                                                      .where((unit) =>
                                                          unit.name != null)
                                                      .map((unit) => unit.name!)
                                                      .toList();

                                              if (unitNames.isEmpty) {
                                                return const SizedBox.shrink();
                                              }

                                              final String selectedUnitName =
                                                  cartItems[index]
                                                          .selectedUnitName ??
                                                      unitNames.first;

                                              final String quantity =
                                                  qtys[index] ?? '1';
                                              final String rate =
                                                  amounts[index] ??
                                                      cartItems[index]
                                                          .price
                                                          .toString();
                                              final double qtyVal =
                                                  double.tryParse(quantity) ??
                                                      0;
                                              final double rateVal =
                                                  double.tryParse(rate) ?? 0;
                                              final double rowTotal =
                                                  qtyVal * rateVal;
                                              final String typeName = (index <
                                                          selectedProductTypes
                                                              .length
                                                      ? selectedProductTypes[
                                                              index]
                                                          ?.name
                                                      : null) ??
                                                  'Select type';

                                              return InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                                onTap: () =>
                                                    showItemDetailsDialog(
                                                        index),
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
                                                        // NUMBER
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
                                                                  '${cartItems[index].code} | ${(cartItems[index].name ?? '').toString().toUpperCase()}',
                                                                  maxLines: 2,
                                                                  softWrap:
                                                                      true,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .visible,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        AppFontSizes
                                                                            .label,
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
                                                                          fontSize:
                                                                              AppFontSizes.badge,
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
                                                                        selectedUnitName,
                                                                        style:
                                                                            const TextStyle(
                                                                          fontSize:
                                                                              AppFontSizes.badge,
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

                                                        // QTY
                                                        SizedBox(
                                                          width: qtyW,
                                                          child: Center(
                                                            child: Text(
                                                              quantity.isNotEmpty
                                                                  ? quantity
                                                                  : '1',
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
                                                              rateVal
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
                                                                removeFromCart(
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
                                    onTap: () {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        Salesselectproductreturn.routeName,
                                        arguments: {
                                          'customerId': id,
                                          'name': name,
                                          'code': code,
                                          'saleId': saleId,
                                          'paymentTerms': payment,
                                          'outstandamt': paydata,
                                          'price_group_id': pricegroupId,
                                        },
                                      );
                                    },
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
                      // REASON (Return-specific; kept exactly as before, just
                      // given consistent horizontal padding)
                      // ==========================================================
                      if (cartItems.isNotEmpty &&
                          cartItems[0].defaultValue == 1 &&
                          qtys[specificIndex] != null &&
                          double.parse(qtys[specificIndex]!) !=
                              double.parse(initialQty))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: DropdownButton<Reason>(
                              hint: Text(
                                'Reason',
                                style: TextStyle(fontSize: AppFontSizes.body),
                              ),
                              value: _selectedReason,
                              onChanged: (Reason? newValue) {
                                setState(() {
                                  _selectedReason = newValue;
                                });
                              },
                              items: _reasonList.map<DropdownMenuItem<Reason>>(
                                  (Reason reason) {
                                return DropdownMenuItem<Reason>(
                                  value: reason,
                                  child: Text(
                                    reason.reason,
                                    style:
                                        TextStyle(fontSize: AppFontSizes.body),
                                  ),
                                );
                              }).toList(),
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

                            final double labelWidth = isVerySmall ? 52 : 60;
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
                                                // -------- REMARKS --------
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: labelWidth,
                                                      child: const Text(
                                                        'Remarks',
                                                        style: TextStyle(
                                                          fontSize: AppFontSizes
                                                              .label,
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
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .text,
                                                                  decoration:
                                                                      const InputDecoration(
                                                                    hintText:
                                                                        "Enter your remarks",
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
                                                                ? 'Enter remarks'
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

                                                // -------- DISCOUNT --------
                                                // (visibility gated by
                                                // AppState().discountState,
                                                // exactly as before)
                                                if (AppState().discountState ==
                                                    'Enable')
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        width: labelWidth,
                                                        child: const Text(
                                                          'Discount',
                                                          style: TextStyle(
                                                            fontSize:
                                                                AppFontSizes
                                                                    .label,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Color(
                                                                0xFF222222),
                                                          ),
                                                        ),
                                                      ),
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
                                                      const SizedBox(width: 7),
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
                                                              fontSize:
                                                                  AppFontSizes
                                                                      .value,
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
                                                        color:
                                                            Color(0xFF222222),
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        total.toStringAsFixed(
                                                          AppState()
                                                                  .noOfDecimals ??
                                                              2,
                                                        ),
                                                        textAlign:
                                                            TextAlign.right,
                                                        style: const TextStyle(
                                                          fontSize: AppFontSizes
                                                              .value,
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
                                                          fontSize: AppFontSizes
                                                              .label,
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
                                                          fontSize: AppFontSizes
                                                              .value,
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

                                                // SUB TOTAL (preserved from the
                                                // original implementation:
                                                // total + tax)
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
                                                          fontSize: AppFontSizes
                                                              .label,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Color(0xFF222222),
                                                        ),
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        (total + tax)
                                                            .toStringAsFixed(
                                                          AppState()
                                                                  .noOfDecimals ??
                                                              2,
                                                        ),
                                                        textAlign:
                                                            TextAlign.right,
                                                        style: const TextStyle(
                                                          fontSize: AppFontSizes
                                                              .value,
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
                                                          fontSize: AppFontSizes
                                                              .label,
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
                                                              content:
                                                                  TextField(
                                                                keyboardType:
                                                                    TextInputType
                                                                        .number,
                                                                controller:
                                                                    _roundoff,
                                                                decoration:
                                                                    const InputDecoration(
                                                                  hintText:
                                                                      "Round off",
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
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text(
                                                            roundOffValue
                                                                .toStringAsFixed(
                                                              AppState()
                                                                      .noOfDecimals ??
                                                                  2,
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                              fontSize:
                                                                  AppFontSizes
                                                                      .value,
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

                                                const SizedBox(height: 8),

                                                // DIVIDER
                                                Container(
                                                  height: 1,
                                                  width: double.infinity,
                                                  color:
                                                      const Color(0xFFE0E0E0),
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
                                                    const Text(
                                                      'Grand Total',
                                                      style: TextStyle(
                                                        fontSize:
                                                            AppFontSizes.label,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Color(0xFF222222),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: Text(
                                                          roundedGrandTotal,
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
                                  // (Clear All / [Add To Cart] / Save Order /
                                  // [Skip] — the bracketed two only show when
                                  // _showButton is true, exactly as before)
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
                                              vertical: isVerySmall ? 9 : 10,
                                              horizontal: 2,
                                            ),
                                          ),
                                          onPressed: () async {
                                            await clearCart();
                                          },
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'CLEAR ALL',
                                              style: TextStyle(
                                                fontSize: AppFontSizes.badge,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      if (_showButton) ...[
                                        const SizedBox(width: 6),
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
                                                vertical: isVerySmall ? 9 : 10,
                                                horizontal: 2,
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.pushReplacementNamed(
                                                context,
                                                Salesselectproductreturn
                                                    .routeName,
                                                arguments: {
                                                  'customerId': id,
                                                  'name': name,
                                                  'code': code,
                                                  'saleId': saleId,
                                                  'paymentTerms': payment,
                                                  'outstandamt': paydata,
                                                  'price_group_id':
                                                      pricegroupId,
                                                },
                                              );
                                            },
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                'ADD TO CART',
                                                style: TextStyle(
                                                  fontSize: AppFontSizes.badge,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppConfig.colorPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],

                                      const SizedBox(width: 6),

                                      // SAVE ORDER
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: cartItems
                                                        .isNotEmpty &&
                                                    !_isButtonDisabled
                                                ? AppConfig.colorPrimary
                                                : AppConfig.buttonDeactiveColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: isVerySmall ? 9 : 10,
                                              horizontal: 2,
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: cartItems.isNotEmpty &&
                                                  !_isButtonDisabled
                                              ? () {
                                                  postDataToApi();
                                                }
                                              : null,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              _isButtonDisabled
                                                  ? 'SAVING...'
                                                  : 'SAVE',
                                              style: const TextStyle(
                                                fontSize: AppFontSizes.badge,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      if (_showButton) ...[
                                        const SizedBox(width: 6),
                                        // SKIP
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppConfig.colorPrimary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: isVerySmall ? 9 : 10,
                                                horizontal: 2,
                                              ),
                                              elevation: 0,
                                            ),
                                            onPressed: () {
                                              Navigator.pushReplacementNamed(
                                                context,
                                                PaymentCollectionScreen
                                                    .routeName,
                                                arguments: {
                                                  'customerId': id,
                                                  'name': name,
                                                  'code': code,
                                                  'saleId': saleId,
                                                  'paymentTerms': payment,
                                                  'outstandamt': paydata,
                                                  'price_group_id':
                                                      pricegroupId,
                                                },
                                              );
                                            },
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                'SKIP',
                                                style: TextStyle(
                                                  fontSize: AppFontSizes.badge,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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

  String getVatLabel() {
    return AppState().taxLabel;
  }

  // =====================================================================
  // ITEM DETAILS DIALOG — UNCHANGED. Not part of the requested visual
  // unification scope (which covers the main list screen). Left exactly
  // as-is to avoid any risk to existing business logic.
  // =====================================================================
  void showItemDetailsDialog(int index) {
    final product = cartItems[index];
    print("========== SHOW ITEM DIALOG DEBUG ==========");
    print("Product toJson: ${product.toJson()}");
    print("Units: ${product.units.map((u) => u.toJson()).toList()}");
    print("=============================================");
    List<String> unitNames = product.units
        .where((unit) => unit.name != null)
        .map((unit) => unit.name!)
        .toList();
    String? selectedUnitName = product.selectedUnitName ??
        (unitNames.isNotEmpty ? unitNames.first : null);
    ProductType? selectedType = index < selectedProductTypes.length
        ? selectedProductTypes[index]
        : null;
    final qtyController = TextEditingController(text: qtys[index] ?? '1');
    final rateController =
        TextEditingController(text: amounts[index] ?? product.price.toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double previewQty = double.tryParse(qtyController.text) ?? 0;
            double previewRate = double.tryParse(rateController.text) ?? 0;
            double previewAmount = previewQty * previewRate;

            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 620,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    22,
                    22,
                    18,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =========================================================
                      // HEADER
                      // =========================================================
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${product.code} | ${product.name}',
                              style: const TextStyle(
                                fontSize: AppFontSizes.dialogTitle, // 13.5
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF222222),
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.only(
                                top: 2,
                                right: 2,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 28,
                                color: Color(0xFF7C7C86),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE3E3E8),
                      ),

                      const SizedBox(height: 24),

                      // =========================================================
                      // PRODUCT TYPE + UNIT
                      // =========================================================
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PRODUCT TYPE
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Product Type',
                                  style: TextStyle(
                                    fontSize: AppFontSizes.label,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF171717),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFD2D2D2),
                                      width: 0.9,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButtonFormField<ProductType>(
                                      value: _matchType(selectedType),
                                      isExpanded: true,
                                      alignment: Alignment.center,

                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),

                                      // SELECTED VALUE → CENTER + BLACK
                                      selectedItemBuilder: (context) {
                                        return productTypes.map((type) {
                                          return Center(
                                            child: Text(
                                              type.name,
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: AppFontSizes.value,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }).toList();
                                      },

                                      // DROPDOWN LIST
                                      items: productTypes.map((type) {
                                        return DropdownMenuItem<ProductType>(
                                          value: type,
                                          child: Center(
                                            child: Text(
                                              type.name,
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: AppFontSizes.value,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),

                                      // DEFAULT VALUE → CENTER + BLACK
                                      hint: const Center(
                                        child: Text(
                                          'Select type',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: AppFontSizes.value,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),

                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 22,
                                        color: Color(0xFF6E6E78),
                                      ),

                                      onChanged: (value) {
                                        setDialogState(() {
                                          selectedType = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 18),

                          // UNIT
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Unit',
                                  style: TextStyle(
                                    fontSize: AppFontSizes.label,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF171717),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFFD9D9E2),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: unitNames.length > 1
                                      ? DropdownButtonHideUnderline(
                                          child:
                                              DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            value: selectedUnitName,
                                            style: const TextStyle(
                                              fontSize: AppFontSizes.value,
                                              color: Color(0xFF25252A),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            icon: const Icon(
                                              Icons.keyboard_arrow_down,
                                              size: 22,
                                              color: Color(0xFF6E6E78),
                                            ),
                                            items: unitNames.map((u) {
                                              return DropdownMenuItem<String>(
                                                value: u,
                                                child: Text(u),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setDialogState(() {
                                                selectedUnitName = value;
                                              });
                                            },
                                          ),
                                        )
                                      : Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            selectedUnitName ?? '',
                                            style: const TextStyle(
                                              fontSize: AppFontSizes.value,
                                              color: Color(0xFF25252A),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // =========================================================
                      // QUANTITY + RATE
                      // =========================================================
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // QUANTITY
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quantity *',
                                  style: TextStyle(
                                    fontSize: AppFontSizes.label,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF171717),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: AppConfig.colorPrimary,
                                      width: 1.4,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.swap_vert,
                                        size: 21,
                                        color: AppConfig.colorPrimary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: qtyController,
                                          autofocus: true,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                            fontSize: AppFontSizes.value,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF222222),
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                          onChanged: (_) {
                                            setDialogState(() {});
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 18),

                          // RATE
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Rate *',
                                  style: TextStyle(
                                    fontSize: AppFontSizes.label,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF171717),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFFD9D9E2),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: TextField(
                                          controller: rateController,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                            fontSize: AppFontSizes.value,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF222222),
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                          ),
                                          onChanged: (_) {
                                            setDialogState(() {});
                                          },
                                        ),
                                      ),
                                      Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: AppConfig.colorPrimary,
                                      ),
                                      const SizedBox(width: 14),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // =========================================================
                      // AMOUNT
                      // =========================================================
                      const Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: AppFontSizes.label,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171717),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFD9D9E2),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calculate_outlined,
                              size: 21,
                              color: Color(0xFF8A8A96),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                previewAmount.toStringAsFixed(3),
                                style: const TextStyle(
                                  fontSize: AppFontSizes.value,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF222222),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDEDFB),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Calculated',
                                style: TextStyle(
                                  fontSize: AppFontSizes.badge,
                                  fontWeight: FontWeight.w700,
                                  color: AppConfig.colorPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      // =========================================================
                      // BOTTOM BUTTONS
                      // =========================================================
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: AppConfig.colorPrimary,
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: AppFontSizes.value,
                                  fontWeight: FontWeight.w700,
                                  color: AppConfig.colorPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConfig.colorPrimary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              onPressed: () {
                                // =================================================
                                // EXISTING SAVE LOGIC - UNCHANGED
                                // =================================================
                                setState(() {
                                  qtys[index] = qtyController.text;

                                  amounts[index] = rateController.text;

                                  saveToSharedPreferences(
                                    'qtyreturn$index',
                                    qtyController.text,
                                  );

                                  saveToSharedPreferences(
                                    'amountreturn$index',
                                    rateController.text,
                                  );

                                  if (selectedUnitName != null) {
                                    cartItems[index].selectedUnitName =
                                        selectedUnitName;

                                    saveToSharedPreferences(
                                      'unitNamereturn$index',
                                      selectedUnitName!,
                                    );
                                  }

                                  if (selectedType != null) {
                                    selectedProductTypes[index] = selectedType;
                                    saveToSharedPreferences(
                                      _productTypeKey(index),
                                      selectedType!.name,
                                    );
                                  }
                                });

                                Navigator.pop(context);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.save_outlined,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    'Save',
                                    style: const TextStyle(
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
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

// Store-wise list-il ninnu default type (Normal, illenkil first)
  ProductType? get defaultType {
    if (productTypes.isEmpty) return null;
    for (final t in productTypes) {
      if (t.name.toLowerCase() == 'normal') return t;
    }
    return productTypes.first;
  }

// Row-nte type: select cheythath, illenkil default. Range error varilla.
  ProductType? _typeAt(int i) {
    final ProductType? picked = (i >= 0 && i < selectedProductTypes.length)
        ? selectedProductTypes[i]
        : null;
    return picked ?? defaultType;
  }

// Dropdown value, items list-ile same item aayi match cheyyan (id vechu)
  ProductType? _matchType(ProductType? t) {
    if (t == null) return null;
    for (final p in productTypes) {
      if (p.id == t.id) return p;
    }
    return null;
  }

  String _productTypeKey(int index) =>
      'productTypereturn_store${AppState().storeId ?? 0}_$index';
  Future<void> fetchProductTypes() async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_product_return_type?store_id=${AppState().storeId}'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<ProductType> loadedProductTypes = [];

      for (var item in data['data']) {
        loadedProductTypes.add(ProductType.fromJson(item));
      }
      setState(() {
        productTypes = loadedProductTypes;
        initializeValues();
        _hasData = data['data'].isNotEmpty;
      });
    } else {
      throw Exception('Failed to load product types');
    }
  }
}

class Reason {
  final int id;
  final String reason;

  Reason({required this.id, required this.reason});

  factory Reason.fromJson(Map<String, dynamic> json) {
    return Reason(
      id: json['id'],
      reason: json['reasone'],
    );
  }
}
