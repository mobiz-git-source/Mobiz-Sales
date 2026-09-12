import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mobizapp/Pages/salesscreen.dart';
import 'package:mobizapp/DashBoardScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../Components/commonwidgets.dart';
import '../Models/appstate.dart';
import '../Models/sales_model.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';

class Vanselectproducts extends StatefulWidget {
  static const routeName = "/Vanselectproducts";
  @override
  _VanselectproductsState createState() => _VanselectproductsState();
}

// String? name;
class _VanselectproductsState extends State<Vanselectproducts> {
  List<Products> products = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMoreProducts = true;
  bool _search = true;
  List<Products> filteredProducts = [];
  bool _isDialogOpen = false;
  final TextEditingController _searchData = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchProducts(currentPage); // Initial fetch
    _searchData.addListener(() {
      _filterProducts(_searchData.text);
    });
  }

  Future<void> fetchProducts(int page) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_product_with_van_stock_and_sales?store_id=${AppState().storeId}&page=$page'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<Products> fetchedProducts = (data['data'] as List)
          .map((json) => Products.fromJson(json))
          .toList();
      final pagination = data['pagination'];

      setState(() {
        isLoading = false;
        products.addAll(fetchedProducts);
        filteredProducts = List.from(products); // Update filtered products
        currentPage++;
        hasMoreProducts = currentPage <= pagination['last_page'];
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load products');
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProducts = List.from(products);
      } else {
        filteredProducts = products
            .where((product) =>
                product.name!.toLowerCase().contains(query.toLowerCase()) ||
                product.code!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> clearCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_products');
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
          iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
          title: const Text(
            'Select Products',
            style: AppConfig.pageTitleStyle,
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
                      autofocus: true,
                      style: TextStyle(color: Colors.white),
                      controller: _searchData,
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(5),
                          hintText: "Search...",
                          hintStyle:
                              TextStyle(color: AppConfig.backgroundColor),
                          border: InputBorder.none),
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
                (!_search) ? Icons.search : Icons.close,
                size: 30,
                color: AppConfig.backgroundColor,
              ),
            ),
            CommonWidgets.horizontalSpace(3),
          ],
        ),
        body: filteredProducts.isEmpty
            ? Center(
                child: isLoading
                    ? Shimmer.fromColors(
                        baseColor:
                            AppConfig.buttonDeactiveColor.withOpacity(0.1),
                        highlightColor: AppConfig.backButtonColor,
                        child: Center(
                          child: Column(
                            children: [
                              CommonWidgets.loadingContainers(
                                  height: SizeConfig.blockSizeVertical * 10,
                                  width: SizeConfig.blockSizeHorizontal * 90),
                              CommonWidgets.loadingContainers(
                                  height: SizeConfig.blockSizeVertical * 10,
                                  width: SizeConfig.blockSizeHorizontal * 90),
                              CommonWidgets.loadingContainers(
                                  height: SizeConfig.blockSizeVertical * 10,
                                  width: SizeConfig.blockSizeHorizontal * 90),
                              CommonWidgets.loadingContainers(
                                  height: SizeConfig.blockSizeVertical * 10,
                                  width: SizeConfig.blockSizeHorizontal * 90),
                              CommonWidgets.loadingContainers(
                                  height: SizeConfig.blockSizeVertical * 10,
                                  width: SizeConfig.blockSizeHorizontal * 90),
                            ],
                          ),
                        ),
                      )
                    : Text('No products found'))
            : NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!isLoading &&
                      hasMoreProducts &&
                      scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent) {
                    fetchProducts(currentPage);
                  }
                  return false;
                },
                child: ListView.builder(
                  itemCount:
                      filteredProducts.length + (hasMoreProducts ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredProducts.length) {
                      return Center(
                          child: Column(
                        children: [
                          SizedBox(
                            height: 10.h,
                          ),
                          Text(
                            "That's All",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ));
                    }

                    final product = filteredProducts[index];
                    return Card(
                      elevation: 3,
                      child: InkWell(
                        onTap: _isDialogOpen
                            ? null
                            : () {
                                setState(() {
                                  _isDialogOpen = true;
                                });
                                showProductDetailsDialog(context, product);
                              },
                        child: Container(
                          width: SizeConfig.blockSizeHorizontal * 90,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.transparent),
                            color: AppConfig.backgroundColor,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15.0),
                                    child: FadeInImage(
                                      image: NetworkImage(
                                          '${RestDatasource().Product_URL}/uploads/product/${product.proImage}'),
                                      placeholder: const AssetImage(
                                          'Assets/Images/no_image.jpg'),
                                      imageErrorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.asset(
                                            'Assets/Images/no_image.jpg',
                                            fit: BoxFit.fitWidth);
                                      },
                                      fit: BoxFit.fitWidth,
                                    ),
                                  ),
                                ),
                                CommonWidgets.horizontalSpace(3),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Tooltip(
                                      message: product.name!.toUpperCase(),
                                      child: SizedBox(
                                        width:
                                            SizeConfig.blockSizeHorizontal * 70,
                                        child: Text(
                                          '${product.code} | ${product.name!.toUpperCase()}',
                                          style: TextStyle(
                                              fontSize:
                                                  AppConfig.textCaption2Size),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  void showProductDetailsDialog(BuildContext context, Products product) async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_product_with_units_by_products?store_id=${AppState().storeId}&van_id=${AppState().vanId}&id=${product.id}&customer_id=$id'));
    final typeResponse = await http
        .get(Uri.parse('${RestDatasource().BASE_URL}/api/get_product_type'));

    if (response.statusCode == 200 && typeResponse.statusCode == 200) {
      final data = jsonDecode(response.body);
      final units = data['data'] as List?;
      final lastsale = data['lastsale'];
      final typeData = jsonDecode(typeResponse.body);
      final productTypes = typeData['data'] as List;

      String? selectedUnitId;
      String? selectedProductTypeId;
      String? quantity;
      String? amount;
      double? availableStock;
      Map<String, dynamic>? selectedUnit;
      String? name;
      if (productTypes.isNotEmpty) {
        selectedProductTypeId = productTypes[0]['id'].toString();
      }

      final amountController = TextEditingController();
      if (units != null && units.any((unit) => unit != null)) {
        selectedUnitId = units[0]['id'].toString();
        selectedUnit = units[0];
        amountController.text = selectedUnit?['price']?.toString() ?? '';
        availableStock =
            double.tryParse(selectedUnit?['stock']?.toString() ?? '0');
      }
   bool isQuantityValid(String? value) {
        final quantityValue = double.tryParse(value ?? '') ?? 0;
        return value != null && value.isNotEmpty && quantityValue > 0;
        // && quantityValue <= (availableStock ?? 0);
      }

                                                                          // ✅ ADDED

      if (ModalRoute.of(context)!.settings.arguments != null) {
        final Map<String, dynamic>? params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        name = params!['name'];
        id = params!['customerId'];
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  '${product.code} | ${product.name!}',
                  // overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.sp),
                ),
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
                              '${RestDatasource().Product_URL}/uploads/product/${product.proImage}',
                              height: 50.h,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset('Assets/Images/no_image.jpg',
                                    height: 50.h);
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
  controller: amountController,
  decoration: InputDecoration(
      labelText: 'Amount',
      labelStyle: TextStyle(fontWeight: FontWeight.bold),
      contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 10.w),
      hintText: 'Amt',
      border: OutlineInputBorder(borderSide: BorderSide.none),
      filled: true,
      fillColor: Colors.grey.shade300),
),
                          SizedBox(height: 10.h),
                          TextFormField(
                            autofocus: true,
                            keyboardType: TextInputType.number,
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
                        SizedBox(height: 10.h),
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
          final prefs =
              await SharedPreferences.getInstance();
          List<String>? selectedProducts =
              prefs.getStringList('selected_products');
          selectedProducts ??= [];
          final serialNumber = DateTime.now()
                  .millisecondsSinceEpoch
                  .toString() +
              '-' +
              (1000 + (DateTime.now().microsecond % 9000))
                  .toString();
          final selectedProduct = {
            'serial_number': serialNumber,
            'id': product.id,
            'code': product.code,
            'name': product.name,
            'pro_image': product.proImage,
            'type_id': selectedProductTypeId,
            'type_name': productTypes.firstWhere((type) =>
                type['id'].toString() ==
                selectedProductTypeId)['name'],
            'unit_id': selectedUnitId,
            'unit_name': selectedUnit?['name'],
            'quantity': quantity ?? '',
            'amount': amountController.text ?? '',
          };
          selectedProducts.add(jsonEncode(selectedProduct));
          await prefs.setStringList(
              'selected_products', selectedProducts);
          Navigator.pop(context);
          Navigator.pushReplacementNamed(
              context, '/VanTransfer', arguments: {
            'name': name,
            'customerId': id
          }).then((value) {
            // _initDone = false;
            // _getTypes();
          });
        }
      : null,
),
                  ] else ...[
                    SizedBox.shrink(),
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
