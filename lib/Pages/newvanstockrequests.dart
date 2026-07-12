import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/selectProducts.dart';
import 'package:mobizapp/selectproduct.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Components/commonwidgets.dart';
import '../Models/sales_model.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'homepage.dart';

class VanStocks extends StatefulWidget {
  static const routeName = "/NewVanStockRequests";

  @override
  _VanStocksState createState() => _VanStocksState();
}

class _VanStocksState extends State<VanStocks> {
  // List<Product> cartItems = [];
  bool _search = false;

  bool _isPercentage = false;
  final TextEditingController _discountData = TextEditingController();
  final TextEditingController amountctrl = TextEditingController();
  final TextEditingController qtysctrl = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  String _remarksText = "";
  Map<int, String> amounts = {};
  Map<int, String> qtys = {};
  TextEditingController _searchData = TextEditingController();
  int? id;
  String? selectedUnitName;
  List<ProductType> productTypes = [];
  List<ProductType?> selectedProductTypes = [];
  bool _isButtonDisabled = false;
  String? name;
  double totalAmount = 0.0;
  List<Map<String, dynamic>> savedProducts = [];
  bool _loaded = false;


  int _ifVat = 1;
  // num tax = 0;

  String amount = '';
  String quantity = '';
  @override
  @override
  void initState() {
    super.initState();
    _loadSavedProducts();
    fetchProductTypes();
    _printLocalStore(); // Call the async function
  }

  Future<void> _printLocalStore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProductsStringList = prefs.getStringList('selected_productss');

    if (savedProductsStringList != null) {
      print("Local store: $savedProductsStringList");
      for (var product in savedProductsStringList) {
        print(jsonDecode(product));
      }
    } else {
      print("No products saved in local store.");
    }
  }


  Future<void> _loadSavedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedProductsStringList =
    prefs.getStringList('selected_productss');

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
    await prefs.setStringList('selected_productss', savedProductsStringList);
  }

  Future<void> clearCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_productss');
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

  @override
  Widget build(BuildContext context) {
    void postDataToApi() async {
      if (_isButtonDisabled) {
        print('Button is disabled. Cannot post data.');
        return;
      }

      setState(() {
        _isButtonDisabled =
            true; // Disable the button while the API call is in progress
      });

      var url = Uri.parse('${RestDatasource().BASE_URL}/api/vanrequest.store');
      List<double> quantities = [];
      List<int> selectedUnitIds = [];

      for (int i = 0; i < savedProducts.length; i++) {
        final product = savedProducts[i];

        double quantity = double.tryParse(product['quantity']?.toString() ?? '0') ?? 0.0;
        int selectedUnitId = int.tryParse(product['unit_id']?.toString() ?? '0') ?? 0;

        quantities.add(quantity);
        selectedUnitIds.add(selectedUnitId);
      }


      var data = {
        'van_id': AppState().vanId,
        'store_id': AppState().storeId,
        'user_id': AppState().userId,
        'item_id': savedProducts.map((item) => item['id']).toList(),
        'quantity': quantities,
        'unit': selectedUnitIds,
      };

      var body = json.encode(data);

      try {
        var response = await http.post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: body,
        );
        print("BBddy$body");
        if (response.statusCode == 200) {
          print(response.body);
          print(body);
          if (mounted) {
            // Show the dialog box
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Alert"),
                  content: Text("Added Successfully"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: Text("OK"),
                    ),
                  ],
                );
              },
            );
            Navigator.of(context).pushNamed(HomeScreen.routeName);
            clearCart();
          }
        } else {
          print('Post failed with status: ${response.statusCode}');
          print(response.body);
          setState(() {
            _isButtonDisabled = false; // Re-enable the button on failure
          });
        }
      } catch (e) {
        print('An error occurred: $e');
        setState(() {
          _isButtonDisabled = false; // Re-enable the button on error
        });
      }
    }

    if (ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      id = params!['customerId'];
      name = params['name'];
    }

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: SizeConfig.blockSizeHorizontal * 35,
        height: SizeConfig.blockSizeVertical * 5,
        child: ElevatedButton(
          style: ButtonStyle(
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7.0),
              ),
            ),
            backgroundColor: (_isButtonDisabled)
                ? const WidgetStatePropertyAll(
                    Colors.grey) // Disabled button color
                : (savedProducts.isNotEmpty)
                    ? const WidgetStatePropertyAll(
                        AppConfig.colorPrimary) // Active button color
                    : const WidgetStatePropertyAll(
                        AppConfig.buttonDeactiveColor), // Inactive button color
          ),
          onPressed: (savedProducts.isNotEmpty &&
                  !_isButtonDisabled) // Ensure the button is not disabled
              ? () async {
                  postDataToApi();
                  setState(() {
                    _isButtonDisabled = true;
                  });
                }
              : null, // Disable the button if conditions are not met

          child: Text(
            'SAVE',
            style: TextStyle(
                fontSize: AppConfig.textCaption3Size,
                color: AppConfig.backgroundColor,
                fontWeight: AppConfig.headLineWeight),
          ),
        ),
      ),
      appBar: AppBar(
        leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
              clearCart();
            },
            child: Icon(Icons.arrow_back_rounded)),
        iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
        title: const Text(
          'Van Stocks Requests',
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
                context,
                SelectProductsScreen.routeName,
              );
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
              child: Text('No items.'),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  ListView.builder(
                    physics: BouncingScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: savedProducts.length,
                    itemBuilder: (context, index) {
                      _loaded = true;
                      final product = savedProducts[index];
                      final quantity = double.tryParse(
                          product['quantity']?.toString() ?? '0') ??
                          0.0;
                      final amount = double.tryParse(
                          product['amount']?.toString() ?? '0') ??
                          0.0;

                      final total = quantity * amount;
                      return InkWell(
                        onTap: () =>
                            showProductDetailsDialog(context, product),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0.w, vertical: 2.h),
                          child: Card(
                            elevation: 1,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              width: SizeConfig.blockSizeHorizontal * 90,
                              // height: 50.h,
                              decoration: BoxDecoration(
                                color: AppConfig.backgroundColor,
                                border: Border.all(
                                  color: AppConfig.buttonDeactiveColor
                                      .withOpacity(0.5),
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(10)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
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
                                                    fontWeight:
                                                    FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        CircleAvatar(
                                          backgroundColor: Colors.grey
                                              .withOpacity(0.2),
                                          radius: 10,
                                          child: GestureDetector(
                                            onTap: () =>
                                                _removeProduct(index),
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
                                        // Text(product['type_name']),
                                        // Text(' | '),
                                        Text(product['unit_name']??'N/A'),
                                        Text(' | '),
                                        Text(
                                            'Qty: ${product['quantity']}'),
                                        // Text(' | '),
                                        // Text('Rate: ${product['amount']}'),
                                        // Text(' | '),
                                        // Text(
                                        //     'Amt: ${total.toStringAsFixed(AppState().noOfDecimals ?? 2)}')
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
  void showProductDetailsDialog(
      BuildContext context, Map<String, dynamic> product) async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_product_with_units_by_product_without_unit_price?store_id=${AppState().storeId}&id=${product['id']}&user_id=${AppState().userId}&van_id=${AppState().vanId}'));

    final typeResponse = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_product_return_type?store_id=${AppState().storeId}'));

    if (response.statusCode == 200 && typeResponse.statusCode == 200) {
      final productData = jsonDecode(response.body)['data'];
      final typeData = jsonDecode(typeResponse.body);
      final productTypes = typeData['data'] as List;
      final amountController = TextEditingController();

      // Get the existing product details
      final existingProduct = savedProducts.firstWhere(
              (p) => p['serial_number'] == product['serial_number']);

      // Initialize controllers and values from existing product
      String? amount = existingProduct['amount'];
      if (amount != null && amount.isNotEmpty) {
        amountController.text = amount;
      }

      String? selectedProductTypeId = existingProduct['type_id'];
      String? quantity = existingProduct['quantity'];

      // Get the units list
      final units = productData['product_detail'] as List;

      // Initialize the selected unit with the one from local storage
      Map<String, dynamic>? selectedUnit;
      if (existingProduct['unit_id'] != null) {
        selectedUnit = units.firstWhere(
              (unit) => unit['id'].toString() == existingProduct['unit_id'].toString(),
          orElse: () => null,
        );
      }

      bool isQuantityValid(String? value) {
        final quantityValue = double.tryParse(value ?? '') ?? 0;
        return value != null && value.isNotEmpty && quantityValue > 0;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('${productData['code']} | ${productData['name']}'),
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
                              '${RestDatasource().Product_URL}/uploads/product/${productData['pro_image']}',
                              height: 100,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset('Assets/Images/no_image.jpg',
                                    height: 100);
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        // DropdownButtonFormField<String>(
                        //   decoration: InputDecoration(
                        //     labelText: 'Product Type',
                        //     labelStyle: TextStyle(fontWeight: FontWeight.bold),
                        //     contentPadding: EdgeInsets.symmetric(
                        //         vertical: 2.h, horizontal: 10.w),
                        //     border: OutlineInputBorder(borderSide: BorderSide.none),
                        //     filled: true,
                        //     fillColor: Colors.grey.shade300,
                        //   ),
                        //   items: productTypes.map((type) {
                        //     return DropdownMenuItem<String>(
                        //       value: type['id'].toString(),
                        //       child: Text(type['name']),
                        //     );
                        //   }).toList(),
                        //   onChanged: (value) {
                        //     setDialogState(() {
                        //       selectedProductTypeId = value;
                        //       final selectedType = productTypes.firstWhere(
                        //               (type) => type['id'].toString() == value,
                        //           orElse: () => null);
                        //
                        //       if (selectedType != null &&
                        //           selectedType['name'] != 'Normal') {
                        //         amountController.text = '0';
                        //       } else {
                        //         amountController.text =
                        //             productData['price'].toString();
                        //       }
                        //     });
                        //   },
                        //   value: selectedProductTypeId,
                        //   hint: Text('Select Product Type'),
                        // ),
                        SizedBox(height: 10.h),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            labelStyle: TextStyle(fontWeight: FontWeight.bold),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 2.h, horizontal: 10.w),
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.grey.shade300,
                          ),
                          items: units.map((unit) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: unit,
                              child: Text(unit['unit_name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedUnit = value;
                              amountController.text = selectedUnit != null
                                  ? selectedUnit!['price'].toString()
                                  : '';
                            });
                          },
                          value: selectedUnit, // This shows the currently selected unit
                          hint: Text('Select Unit'),
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
                              labelStyle: TextStyle(fontWeight: FontWeight.bold),
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 2.h, horizontal: 10.w),
                              hintText: 'Qty',
                              border: OutlineInputBorder(borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey.shade300),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
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
                      if (
                      quantity != null &&
                          amountController.text.isNotEmpty) {
                        final productIndex = savedProducts.indexWhere(
                                (p) => p['serial_number'] == product['serial_number']);

                        if (productIndex != -1) {
                          setState(() {
                            // savedProducts[productIndex]['type_id'] = selectedProductTypeId;
                            savedProducts[productIndex]['quantity'] = quantity;
                            savedProducts[productIndex]['amount'] = amountController.text;
                            // savedProducts[productIndex]['type_name'] = productTypes.firstWhere(
                            //         (type) => type['id'].toString() == selectedProductTypeId)['name'];

                            // Update the unit information
                            if (selectedUnit != null) {
                              savedProducts[productIndex]['unit_id'] = selectedUnit!['id'].toString();
                              savedProducts[productIndex]['unit_name'] = selectedUnit!['unit_name'];
                            }
                          });

                          final prefs = await SharedPreferences.getInstance();
                          final savedProductsStringList = savedProducts
                              .map((product) => jsonEncode(product))
                              .toList();
                          await prefs.setStringList(
                              'selected_productss',
                              savedProductsStringList);

                          Navigator.of(context).pop();
                          _updateCalculations(); // Refresh the UI
                        }
                      }
                    }
                        : null,
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  Future<void> fetchProductTypes() async {
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
  }
}
