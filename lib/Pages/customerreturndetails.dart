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
import 'TestReturn.dart';
import 'homereturn.dart';

class Customerreturndetail extends StatefulWidget {
  static const routeName = "/Customerreturndetail";

  @override
  _CustomerreturndetailState createState() => _CustomerreturndetailState();
}

int? id;

// int?dataId;
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
  final TextEditingController _roundoff = TextEditingController();
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

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //
  //   // Check if arguments are passed via the ModalRoute and extract them
  //   final Map<String, dynamic>? params = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  //
  //   if (params != null) {
  //     setState(() {
  //       id = params['customerId'];
  //       name = params['name'];
  //       code = params['code'];
  //       payment = params['paymentTerms'];
  //       dataId = params['dataId'];
  //       paydata = params['outstandamt'];
  //     });
  //
  //     // Now that dataId is set, you can call fetchSalesReturnData
  //     fetchSalesReturnData(dataId!);
  //   }
  // }

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

  // Future<void> fetchSalesReturnData() async {
  //   print("DataaIID");
  //   print(dataId);
  //   final url = Uri.parse(
  //       '${RestDatasource().BASE_URL}/api/get-sales-return.empty-product?store_id=${AppState().storeId}&id=$dataId');
  //   final response = await http.get(url);
  //
  //   if (response.statusCode == 200) {
  //     print(response.request);
  //     final data = jsonDecode(response.body);
  //     if (data != null && data['data'] != null) {
  //       if (dataId != null) {
  //         SharedPreferences prefs = await SharedPreferences.getInstance();
  //         await prefs.setString('dataId', dataId.toString());
  //         List<Product> fetchedProducts = [];
  //         if (data['data'] is List) {
  //           fetchedProducts = (data['data'] as List).map((item) {
  //             Product product = Product.fromJson(item);
  //             product.defaultValue = 1;
  //             return product;
  //           }).toList();
  //           cartItems.addAll(fetchedProducts);
  //           for (var product in fetchedProducts) {
  //             await addToCart(product);
  //           }
  //         } else if (data['data'] is Map) {
  //           Product product = Product.fromJson(data['data']);
  //           product.defaultValue = 1;
  //           cartItems.add(product);
  //           await addToCart(product);
  //
  //         }
  //         selectedProductTypes = List.generate(
  //           cartItems.length,
  //           (index) => null,
  //         );
  //         setState(() {
  //           _fetchSalesReturnDataComplete =
  //               true;
  //         });
  //       }
  //     }
  //   } else {
  //     throw Exception('Failed to load sales return data');
  //   }
  // }

  // bool _showButton = false; // Add this flag at the class level.

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
        if (data != null && data['data'] != null) {
          if (dataId != null) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('dataId', dataId.toString());
            List<Product> fetchedProducts = [];
            if (data['data'] is List && data['data'].isNotEmpty) {
              fetchedProducts = (data['data'] as List).map((item) {
                Product product = Product.fromJson(item);
                product.defaultValue = 1;
                return product;
              }).toList();
              cartItems.addAll(fetchedProducts);
              for (var product in fetchedProducts) {
                await addToCart(product);
              }
              _showButton = false; // No need to show the button if data exists.
            } else if (data['data'] is Map) {
              Product product = Product.fromJson(data['data']);
              product.defaultValue = 1;
              cartItems.add(product);
              await addToCart(product);
              _showButton = false; // No need to show the button if data exists.
            } else {
              _showButton = true; // Show button if no data is found.
            }
            selectedProductTypes = List.generate(
              cartItems.length,
              (index) => null,
            );
            setState(() {
              _fetchSalesReturnDataComplete = true;
            });
          }
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
    num taxPercentage = 5;

    if (_isPercentage) {
      // Percentage discount: apply discount first, then calculate tax
      double discountedAmount = totalAmount - (totalAmount * discountAmount / 100);
      return (discountedAmount * taxPercentage) / 100;
    } else {
      // Fixed amount discount: subtract discount, then calculate tax
      double discountedAmount = totalAmount - discountAmount;
      return (discountedAmount * taxPercentage) / 100;
    }
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
    double grandTotal = _ifVat == 1 ? netAmount + taxamt : netAmount;

    // Handle round off
    String roundoffText = _roundoff.text.trim();
    double roundOffInput = double.tryParse(roundoffText) ?? 0.0;

    double roundedGrandTotal;
    double roundOffValue;

    if (roundoffText.isEmpty) {
      // Auto round off
      roundedGrandTotal = customRound(grandTotal).toDouble();
      roundOffValue = roundedGrandTotal - grandTotal;
    } else {
      // Manual round off
      roundedGrandTotal = grandTotal + roundOffInput;
      roundOffValue = roundOffInput;
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

  // Future<void> removeFromCart(int index) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   List<String>? cartItemsJson = prefs.getStringList('cartItemsreturn');
  //
  //   if (cartItemsJson != null) {
  //     List<Product> products = cartItemsJson
  //         .map((json) => Product.fromJson(jsonDecode(json)))
  //         .toList();
  //
  //     products.removeAt(index); // Remove the item at the specific index
  //
  //     List<String> updatedCartItemsJson =
  //         products.map((product) => jsonEncode(product.toJson())).toList();
  //
  //     await prefs.setStringList('cartItemsreturn', updatedCartItemsJson);
  //
  //     fetchCartItems(); // Refresh UI after deletion
  //   }
  // }
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
        await prefs.remove('productTypereturn$index');
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

  // Future<void> initializeValues() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     for (int i = 0; i < cartItems.length; i++) {
  //       qtys[i] = prefs.getString('qtyreturn$i') ?? '1';
  //       amounts[i] =
  //           prefs.getString('amountreturn$i') ?? cartItems[i].price.toString();
  //     }
  //   });
  // }
  Future<void> initializeValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (productTypes.isNotEmpty && cartItems.isNotEmpty) {
      setState(() {
        for (int i = 0; i < cartItems.length; i++) {
          qtys[i] = prefs.getString('qtyreturn$i') ?? '1';
          amounts[i] = prefs.getString('amountreturn$i') ??
              cartItems[i].price.toString();

          if (cartItems[i].units.isNotEmpty) {
            cartItems[i].selectedUnitName =
                prefs.getString('unitNamereturn$i') ??
                    cartItems[i].units.first.name;
          }

          selectedProductTypes[i] = productTypes.firstWhere(
            (type) => type.name == prefs.getString('productTypereturn$i'),
            orElse: () => productTypes.first,
          );
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

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> grandTotalMap = grandTotal();

    double total = calculateTotalRate();
    double tax = _ifVat == 1 ? calculateTax() : 0;
    var roundedGrandTotal =
        grandTotalMap['rounded']?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';

    double roundOffValue = grandTotalMap['roundOffValue'];

    void postDataToApi() async {
      if (!_fetchCartItemsComplete && !_fetchSalesReturnDataComplete) {
        print("Data sources are not fully loaded yet.");
        return;
      }
      setState(() {
        _isButtonDisabled = true; // Disable the button when the request starts
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
                  .firstWhere((unit) => unit.name == selectedUnitName)
                  .unit!
              : cartItems[index].units.first.unit!;

          selectedUnitIds.add(selectedUnitId);
          String? qty = qtys[index];
          double quantity = qty != null ? double.parse(qty) : 1.0;
          quantities.add(quantity);

          ProductType? selectedProductType = selectedProductTypes[index];
          Object productType =
              selectedProductType != null ? selectedProductType.id : 1;
          productTypesList.add(productType);
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
                    return double.parse(value.toStringAsFixed(AppState().noOfDecimals ?? 2));
                  })
                  .toList()
                  .isEmpty
              ? [0.0]
              : amounts.entries.map((entry) {
                  double value = double.tryParse(entry.value) ?? 0.0;
                  print("sdsds$value");
                  return double.parse(value.toStringAsFixed(AppState().noOfDecimals ?? 2));
                }).toList(),
          // 'mrp': amounts.entries.map((entry) {
          //   return double.tryParse(entry.value) ?? 0.0;
          // }).toList().isEmpty ? [0.0] : amounts.entries.map((entry) {
          //   return double.tryParse(entry.value) ?? 0.0;
          // }).toList(),
          'customer_id': id ?? 0,
          'if_vat': _ifVat == 1 ? 1 : 0,
          'product_type': productTypesList,
          'total_tax': tax,
          'discount_type': _isPercentage ? '1' : '0',
          'discount': _discountData.text.isEmpty ? '0' : _discountData.text,
          'total': total,
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
                  HomereturnScreen
                      .routeName, // Replace with the actual route name for HomeReturnPage
                );
              }
            });
          }
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

    // if (ModalRoute.of(context)!.settings.arguments != null) {
    //   final Map<String, dynamic>? params =
    //       ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    //   id = params!['customerId'];
    //   name = params['name'];
    //   code = params!['code'];
    //   payment = params!['paymentTerms'];
    //   dataId = params!['dataId'];
    //   paydata = params!['outstandamt'];
    //
    // }

    return WillPopScope(
      onWillPop: () async {
        // Call your custom function here
        await _onBackPressed();
        // Return true to allow the page to be popped
        // Return false to prevent the page from being popped
        return true;
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          width: 200.w,
          height: 30.h,
          child: _hasData
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                        ),
                        backgroundColor: WidgetStateProperty.all(
                          cartItems.isNotEmpty && !_isButtonDisabled
                              ? AppConfig.colorPrimary
                              : AppConfig.buttonDeactiveColor,
                        ),
                      ),
                      onPressed: _isButtonDisabled || cartItems.isEmpty
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
                    SizedBox(
                      width: 10,
                    ),
                    _showButton
                        ? ElevatedButton(
                            style: ButtonStyle(
                                shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                backgroundColor: WidgetStatePropertyAll(
                                    AppConfig.colorPrimary)),
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                context,
                                PaymentCollectionScreen.routeName,
                                arguments: {
                                  'customerId': id,
                                  'name': name,
                                  'code': code,
                                  'saleId': saleId,
                                  // 'returnId':returnId,
                                  'paymentTerms': payment,
                                  'outstandamt': paydata,
                                  'price_group_id': pricegroupId
                                },
                              );
                            },
                            child: Text(
                              'SKIP',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : SizedBox.shrink(),
                  ],
                )
              : Text('Return Type Not\n      Available'),
        ),
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
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(
                    context, Salesselectproductreturn.routeName,
                    arguments: {
                      'customerId': id,
                      'name': name,
                      'code': code,
                      'saleId': saleId,
                      'paymentTerms': payment,
                      'outstandamt': paydata,
                      'price_group_id': pricegroupId
                      // 'dataId': dataId
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
        body: cartItems.isEmpty
            ? Center(
                child: Text('No items.'),
              )
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
                  SizedBox(
                    height: SizeConfig.blockSizeVertical * 55,
                    child: ListView.builder(
                      physics: BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        List<String> unitNames = cartItems[index]
                            .units
                            .where((unit) => unit.name != null)
                            .map((unit) => unit.name!)
                            .toList();
                        if (unitNames.isEmpty) {
                          return SizedBox.shrink();
                        }
                        String? selectedUnitName =
                            cartItems[index].selectedUnitName ??
                                unitNames.first;
                        String quantity = qtys[index] ?? '1';
                        String rate =
                            amounts[index] ?? cartItems[index].price.toString();
                        double ttlamount =
                            double.parse(quantity) * double.parse(rate);
                        bool isUnitNameDuplicated(String unitName) {
                          // Get the product ID of the current item
                          var currentProductId = cartItems[index].id;

                          // Check for duplicates only within the same product ID
                          for (var item in cartItems) {
                            if (item.id == currentProductId &&
                                item != cartItems[index] &&
                                item.selectedUnitName == unitName) {
                              return true;
                            }
                          }
                          return false;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 2),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // SizedBox(
                                      // width: 50,
                                      // height: 60,
                                      // child: ClipRRect(
                                      //   borderRadius:
                                      //       BorderRadius.circular(10),
                                      //   child: FadeInImage(
                                      //     image: NetworkImage(
                                      //       '${RestDatasource().Product_URL}/uploads/product/${cartItems[index].proImage}',
                                      //     ),
                                      //     placeholder: const AssetImage(
                                      //       'Assets/Images/no_image.jpg',
                                      //     ),
                                      //     imageErrorBuilder:
                                      //         (context, error, stackTrace) {
                                      //       return Image.asset(
                                      //         'Assets/Images/no_image.jpg',
                                      //         fit: BoxFit.fitWidth,
                                      //       );
                                      //     },
                                      //     fit: BoxFit.fitWidth,
                                      //   ),
                                      // ),
                                      // ),
                                      // CommonWidgets.horizontalSpace(1),
                                      Column(
                                        children: [
                                          // CommonWidgets.verticalSpace(1),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // CommonWidgets.horizontalSpace(1),
                                              SizedBox(
                                                width: 245.w,
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      '${cartItems[index].code} | ${cartItems[index].name.toString().toUpperCase()} | ${cartItems[index].defaultValue}',
                                                      style: TextStyle(
                                                        fontSize: AppConfig
                                                            .textCaption3Size,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (cartItems.isNotEmpty &&
                                          cartItems[index].defaultValue == 0)
                                        CircleAvatar(
                                          backgroundColor:
                                              Colors.grey.withOpacity(0.2),
                                          radius: 10,
                                          child: GestureDetector(
                                            onTap: () async {
                                              removeFromCart(index);
                                            },
                                            child: Icon(
                                              Icons.close,
                                              size: 15,
                                              color: Colors.red,
                                            ),
                                          ),
                                        )
                                    ],
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 45.w,
                                        height: 20.h,
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<ProductType>(
                                            alignment: Alignment.center,
                                            isExpanded: true,
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: AppConfig.colorPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            hint: const Center(
                                                child: Text('Select')),
                                            value:
                                                selectedProductTypes[index] ??
                                                    (productTypes.isNotEmpty
                                                        ? productTypes.first
                                                        : null),
                                            onChanged: (ProductType? newValue) {
                                              setState(() {
                                                selectedProductTypes[index] =
                                                    newValue;
                                                saveToSharedPreferences(
                                                    'productTypereturn$index',
                                                    newValue!.name);
                                              });
                                            },
                                            items: productTypes
                                                .map((ProductType productType) {
                                              return DropdownMenuItem<
                                                  ProductType>(
                                                value: productType,
                                                child: Center(
                                                    child: Text(productType
                                                        .name)), // Center align the item text
                                              );
                                            }).toList(),
                                            icon: SizedBox.shrink(),
                                          ),
                                        ),
                                      ),
                                      Text(' | '),
                                      Flexible(
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            isDense: true,
                                            alignment: Alignment.center,
                                            isExpanded: false,
                                            value: selectedUnitName,
                                            items: unitNames
                                                .map<DropdownMenuItem<String>>(
                                                    (String value) {
                                              bool isDuplicated =
                                                  isUnitNameDuplicated(value);
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Center(
                                                  child: Text(
                                                    value,
                                                    style: TextStyle(
                                                      fontSize: 10.sp,
                                                      color: isDuplicated
                                                          ? Colors.red
                                                          : AppConfig
                                                              .colorPrimary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                cartItems[index]
                                                        .selectedUnitName =
                                                    newValue;

                                                // Find the selected unit and update the rate
                                                for (var unit
                                                    in cartItems[index].units) {
                                                  if (unit.name == newValue) {
                                                    amounts[index] =
                                                        unit.price.toString();
                                                    saveToSharedPreferences(
                                                        'amountreturn$index',
                                                        amounts[index]);
                                                    break;
                                                  }
                                                }
                                                saveToSharedPreferences(
                                                    'unitNamereturn$index',
                                                    newValue);
                                              });
                                            },
                                            icon: SizedBox.shrink(),
                                          ),
                                        ),
                                      ),
                                      Text(' | '),
                                      GestureDetector(
                                        onTap: () {
                                          setInitialQty();
                                          String initialQty;
                                          if (dataId != null ||
                                              cartItems[index].defaultValue ==
                                                  1) {
                                            initialQty = cartItems[index]
                                                    .units[0]
                                                    .stock
                                                    ?.toString() ??
                                                '1';
                                          } else {
                                            initialQty = qtys[index] ?? '1';
                                          }

                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              // Use initial quantity as the default text in TextField
                                              TextEditingController
                                                  qtyController =
                                                  TextEditingController(
                                                      text: initialQty);

                                              return AlertDialog(
                                                title: Text('Quantity'),
                                                content: TextField(
                                                  controller: qtyController,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      qtys[index] = value;
                                                      saveToSharedPreferences(
                                                          'qtyreturn$index',
                                                          value);
                                                    });
                                                  },
                                                  keyboardType:
                                                      TextInputType.number,
                                                ),
                                                actions: <Widget>[
                                                  MaterialButton(
                                                    color:
                                                        AppConfig.colorPrimary,
                                                    textColor: Colors.white,
                                                    child: Text('OK'),
                                                    onPressed: () {
                                                      setState(() {
                                                        qtys[index] =
                                                            qtyController.text;
                                                        saveToSharedPreferences(
                                                            'qtyreturn$index',
                                                            qtyController
                                                                .text); // Update qtys w
                                                        print(
                                                            "objectValues"); // ith new value
                                                        print(
                                                            qtyController.text);
                                                      });
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            Text('Qty: '),
                                            Text(
                                              (qtys[index] != null &&
                                                      qtys[index] != '')
                                                  ? qtys[
                                                      index]! // Force unwrap since we check for null already
                                                  : (cartItems[index]
                                                              .defaultValue ==
                                                          1
                                                      ? cartItems[index]
                                                              .units[0]
                                                              .stock
                                                              ?.toString() ??
                                                          '1' // Fallback to '1' if stock is null
                                                      : '1'), // Default to '1' if no quantity is set
                                              style: TextStyle(
                                                color: AppConfig.colorPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(' | '),
                                      GestureDetector(
                                          onTap: () {
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: const Text('Amount'),
                                                    content: TextField(
                                                      controller:
                                                          TextEditingController(
                                                        text:
                                                            '${amounts[index] ?? cartItems[index].price}',
                                                      ),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          amounts[index] =
                                                              value;
                                                          saveToSharedPreferences(
                                                              'amountreturn$index',
                                                              value);
                                                        });
                                                      },
                                                      keyboardType:
                                                          TextInputType.number,
                                                      // controller: _discountData,
                                                    ),
                                                    actions: <Widget>[
                                                      MaterialButton(
                                                        color: AppConfig
                                                            .colorPrimary,
                                                        textColor: Colors.white,
                                                        child: const Text('OK'),
                                                        onPressed: () {
                                                          amount =
                                                              amountctrl.text;
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                      ),
                                                    ],
                                                  );
                                                });
                                          },
                                          child: Row(
                                            children: [
                                              Text('Rate: '),
                                              Text(
                                                '${amounts[index] ?? cartItems[index].price}',
                                                style: TextStyle(
                                                    color:
                                                        AppConfig.colorPrimary,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          )),
                                      Text(' | '),
                                      Text(
                                        'Amt: ${ttlamount.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
                                        style: TextStyle(color: Colors.grey),
                                      )
                                    ],
                                  ),
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
                            // Check conditions safely before rendering the DropdownButton
                            if (cartItems.isNotEmpty &&
                                cartItems[0].defaultValue == 1 &&
                                qtys[specificIndex] != null &&
                                double.parse(qtys[specificIndex]!) <
                                    double.parse(initialQty))
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(width: 5),
                                  DropdownButton<Reason>(
                                    hint: Text('Reason'),
                                    value: _selectedReason,
                                    onChanged: (Reason? newValue) {
                                      setState(() {
                                        _selectedReason = newValue;
                                        if (_selectedReason != null) {
                                          // Print the selected Reason's id
                                          print(_selectedReason!.id);
                                        }
                                      });
                                    },
                                    items: _reasonList
                                        .map<DropdownMenuItem<Reason>>(
                                            (Reason reason) {
                                      return DropdownMenuItem<Reason>(
                                        value: reason,
                                        child: Text(reason
                                            .reason), // Display the reason text (String)
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Remarks",
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
                                      title: const Text('Remarks'),
                                      content: TextField(
                                        controller: _remarksController,
                                        onChanged: (value) {
                                          setState(() {
                                            _remarksText = value;
                                          });
                                        },
                                        keyboardType: TextInputType.text,
                                        decoration: const InputDecoration(
                                          hintText: "Enter your remarks",
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
                                      // fontWeight: FontWeight.bold,
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
                        AppState().discountState == 'Enable'
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
                        Text('Total: ${total.toStringAsFixed(AppState().noOfDecimals ?? 2)}'),
                        Text('Tax: ${tax.toStringAsFixed(AppState().noOfDecimals ?? 2)}'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Round off: '),
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
                        Text('Grand Total: ${roundedGrandTotal}'),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

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
