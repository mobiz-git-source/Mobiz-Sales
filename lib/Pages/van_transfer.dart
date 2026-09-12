import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Pages/homepage.dart';
import 'package:mobizapp/Pages/vanselectproduct.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../Components/commonwidgets.dart';
import '../Models/VanTransfer.dart';
import '../Models/appstate.dart';
import '../Models/sales_model.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'VanTransferReceive.dart';
import 'VanTransferSend.dart';

class VanTransfer extends StatefulWidget {
  static const routeName = "/VanTransfer";

  const VanTransfer({super.key});

  @override
  State<VanTransfer> createState() => _VanTransferState();
}

class _VanTransferState extends State<VanTransfer> {
  String? selectedVan;
  List<VanData> vans = [];
  List<Product> cartItems = [];
  Map<int, String> amounts = {};
  Map<int, String> qtys = {};
  int? selectedVanId;
  List<ProductType> productTypes = [];
  List<ProductType?> selectedProductTypes = [];
  final TextEditingController _remarksController = TextEditingController();
  String _remarksText = "";
  String amount = '';
  String quantity = '';
  bool _isDialogOpen = false;
  bool _isButtonDisabled = false;

  final TextEditingController amountctrl = TextEditingController();
  List<Map<String, dynamic>> savedProducts = [];
  @override
  void initState() {
    super.initState();
    fetchVans();
    _loadSavedProducts();
    initializeValues();
  }

  Future<void> _removeProduct(int index) async {
    setState(() {
      savedProducts.removeAt(index);
      // Recalculate total amount
      // totalAmount = savedProducts.fold(0.0, (sum, product) {
      //   final quantity =
      //       double.tryParse(product['quantity']?.toString() ?? '0') ?? 0.0;
      //   final amount =
      //       double.tryParse(product['amount']?.toString() ?? '0') ?? 0.0;
      //   return sum + (quantity * amount);
      // });
    });

    final prefs = await SharedPreferences.getInstance();
    final savedProductsStringList =
        savedProducts.map((product) => jsonEncode(product)).toList();
    await prefs.setStringList('selected_products', savedProductsStringList);
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
        // totalAmount = savedProducts.fold(0.0, (sum, product) {
        //   final quantity =
        //       double.tryParse(product['quantity']?.toString() ?? '0') ?? 0.0;
        //   final amount =
        //       double.tryParse(product['amount']?.toString() ?? '0') ?? 0.0;
        //   return sum + (quantity * amount);
        // });
      });
    }
  }

  Future<void> clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> fetchVans() async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_van_by_store?store_id=${AppState().storeId}&van_id=${AppState().vanId}'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body)['data'];
      setState(() {
        vans = jsonResponse.map((van) => VanData.fromJson(van)).toList();
        // initializeValues();
      });
    } else {
      throw Exception('Failed to load vans');
    }
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
    setState(() {
      selectedVan = prefs.getString('selectedVan');
      selectedVanId = prefs.getInt('selectedVanId');
      // for (int i = 0; i < cartItems.length; i++) {
      //   qtys[i] = prefs.getString('qtyvan$i') ?? '1';
      //   amounts[i] =
      //       prefs.getString('amountvan$i') ?? cartItems[i].price.toString();
      //
      //   if (cartItems[i].units.isNotEmpty) {
      //     cartItems[i].selectedUnitName = prefs.getString('unitNamevan$i') ??
      //         cartItems[i].units.first.name;
      //   }
      // }
    });
  }

  Future<void> _onBackPressed() async {
    clearCart();
    // Your custom function logic here
    print('Back button pressed');
    // You can also show a dialog, navigate to another page, etc.
  }

  @override
  Widget build(BuildContext context) {
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
              clearSharedPreferences();
            },
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppConfig.colorPrimary,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Van Transfer Request',
                style: AppConfig.pageTitleStyle,
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(
                          context, VanTransferSend.routeName);
                    },
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(
                          context, VanTransferSend.routeName);
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                            context, VanStockReceive.routeName);
                      },
                      child: Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.deepPurple.shade100,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Transform.flip(
                              flipX: true,
                              child: Image.asset(
                                'Assets/Images/van stock.png',
                                width: 60,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'D 87550',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConfig.colorPrimary,
                              ),
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.person,
                              size: 30,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              ' ${AppState().name}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConfig.colorPrimary,
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      CupertinoIcons.arrow_right_arrow_left,
                      color: AppConfig.backgroundColor,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: AppConfig.colorPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 30),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                .47,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                .03,
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "Select Van to Transfer",
                                            style: TextStyle(
                                              color: AppConfig.colorPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                .32,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                .03,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade400,
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            isDense: true,
                                            isExpanded: true,
                                            style: TextStyle(),
                                            value: selectedVan,
                                            hint: Center(
                                              child: Text(
                                                'Select here',
                                              ),
                                            ),
                                            items: vans.map((VanData van) {
                                              return DropdownMenuItem<String>(
                                                value: van.name,
                                                child: Center(
                                                  child: Text(
                                                    van.name ?? '',
                                                    style: TextStyle(
                                                        color: Colors.black),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged:
                                                (String? newValue) async {
                                              setState(() {
                                                selectedVan = newValue;
                                                selectedVanId = vans
                                                    .firstWhere((van) =>
                                                        van.name == newValue)
                                                    .id;
                                              });
                                              await saveToSharedPreferences(
                                                  'selectedVan', newValue);
                                              await saveToSharedPreferences(
                                                  'selectedVanId',
                                                  selectedVanId);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'Assets/Images/van stock.png',
                                  width: 60,
                                  color: Colors.black,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    selectedVan ?? 'Van no:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppConfig.colorPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.person,
                                  size: 30,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'User',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppConfig.colorPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock Detail',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                // onTap: () {
                //   transferData();
                // },
                child: Container(
                    height: SizeConfig.blockSizeVertical * 58,
                    color: Colors.grey.shade300,
                    child: Scrollbar(
                      thickness: 10,
                      thumbVisibility: false,
                      radius: Radius.circular(5),
                      child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      Vanselectproducts.routeName,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                        color: AppConfig.colorPrimary,
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        )),
                                  ),
                                ),
                              ),
                            ),
                            savedProducts.isEmpty
                                ? Center(child: Text('No saved products'))
                                : ListView.builder(
                                    physics: BouncingScrollPhysics(),
                                    scrollDirection: Axis.vertical,
                                    shrinkWrap: true,
                                    itemCount: savedProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = savedProducts[index];
                                      final quantity = double.tryParse(
                                              product['quantity']?.toString() ??
                                                  '0') ??
                                          0.0;
                                      final amount = double.tryParse(
                                              product['amount']?.toString() ??
                                                  '0') ??
                                          0.0;

                                      final total = quantity * amount;
                                      return InkWell(
                                        onTap:
                                            // _isDialogOpen
                                            //     ? null
                                            //     :
                                            () {
                                          // setState(() {
                                          //   _isDialogOpen = true;
                                          // });
                                          showProductDetailsDialog(
                                              context, product);
                                        },
                                        child: Card(
                                          elevation: 1,
                                          child: Container(
                                            padding: const EdgeInsets.all(5),
                                            width:
                                                SizeConfig.blockSizeHorizontal *
                                                    90,
                                            decoration: BoxDecoration(
                                              color: AppConfig.backgroundColor,
                                              border: Border.all(
                                                color: AppConfig
                                                    .buttonDeactiveColor
                                                    .withOpacity(0.5),
                                              ),
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(10)),
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
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            '${product['code']} | ${product['name'].toString().toUpperCase()}',
                                                            style: TextStyle(
                                                                fontSize: AppConfig
                                                                    .textCaption3Size,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    CircleAvatar(
                                                      backgroundColor: Colors
                                                          .grey
                                                          .withOpacity(0.2),
                                                      radius: 10,
                                                      child: GestureDetector(
                                                        onTap: () =>
                                                            _removeProduct(
                                                                index),
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
                                                    Text(
                                                        'Qty: ${product['quantity']}'),
                                                    Text(' | '),
                                                    Text(
                                                        'Rate: ${product['amount']}'),
                                                    Text(' | '),
                                                    Text(
                                                        'Amt: ${total.toStringAsFixed(AppState().noOfDecimals ?? 2)}')
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    )),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Remarks",
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
                              title: Text('Remarks'),
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
                                      _remarksText = _remarksController.text;
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
                        height: MediaQuery.of(context).size.height * 0.05,
                        width: MediaQuery.of(context).size.width * 0.9,
                        // padding: EdgeInsets.symmetric(
                        //     horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: AppConfig.buttonDeactiveColor),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5)),
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
              ),
              SizedBox(
                height: 20,
              ),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _isButtonDisabled
                          ? Colors.grey
                          : AppConfig.colorPrimary),
                  onPressed: (savedProducts.isNotEmpty && !_isButtonDisabled)
                      ? () async {
                          postDataToApi();
                        }
                      : null,
                  child: Text(
                    'TRANSFER',
                    style: TextStyle(color: AppConfig.backgroundColor),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void postDataToApi() async {
    setState(() {
      _isButtonDisabled = true;
    });
    var url = Uri.parse('${RestDatasource().BASE_URL}/api/vantransfar.store');
    List<int> unitIds = savedProducts.map<int>((product) {
      // Assuming product['unit_id'] already contains the selected unit ID
      return int.parse(product['unit_id']);
    }).toList();
    List<int> productIds = savedProducts.map<int>((product) {
      return product['id'];
    }).toList();
    List<double> amounts = savedProducts.map<double>((product) {
      return double.parse(product['amount'].toString());
    }).toList();
    List<double> quantity = savedProducts.map<double>((product) {
      return double.parse(product['quantity'].toString());
    }).toList();
    var data = {
      'from_van_id': AppState().vanId,
      'store_id': AppState().storeId,
      'user_id': AppState().userId,
      'to_van_id': selectedVanId,
      'item_id': productIds,
      'quantity': quantity,
      'unit': unitIds,
      'mrp': amounts,
      'remarks': _remarksText
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

      if (response.statusCode == 200) {
        print('Post successful');
        if (mounted) {
          await CommonWidgets.showDialogueBox(
            context: context,
            title: "Alert",
            msg: "Created Successfully",
          );
          clearCart();
          Navigator.pushReplacementNamed(
            context,
            HomeScreen.routeName,
          );
        }
      } else {
        print('Post failed with status: ${response.statusCode}');
        print(response.body);
      }
    } catch (e) {
      print('An error occurred: $e');
    } finally {
      // Re-enable the button after the API call completes
      setState(() {
        _isButtonDisabled = false;
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

  void showProductDetailsDialog(
      BuildContext context, Map<String, dynamic> product) async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_product_with_units_by_products?store_id=${AppState().storeId}&van_id=${AppState().vanId}&id=${product['id']}'));
    final typeResponse = await http
        .get(Uri.parse('${RestDatasource().BASE_URL}/api/get_product_type'));

    if (response.statusCode == 200 && typeResponse.statusCode == 200) {
      final data = jsonDecode(response.body);
      final units = data['data'] as List?;
      final lastsale = data['lastsale'];
      final typeData = jsonDecode(typeResponse.body);
      final productTypes = typeData['data'] as List;
      final amountController = TextEditingController();
      final existingProduct = savedProducts
          .firstWhere((p) => p['serial_number'] == product['serial_number']);
      String? amount = existingProduct['amount'];
      if (amount != null && amount.isNotEmpty) {
        amountController.text = amount;
      }
      double? availableStock;
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
                          SizedBox(height: 8),
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
                        ] else ...[
                          Text('No units available for this product.'),
                        ],
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
                                    // _updateCalculations();
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
