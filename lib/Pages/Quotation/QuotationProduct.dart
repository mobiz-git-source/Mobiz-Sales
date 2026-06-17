import 'dart:async';
import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../Components/commonwidgets.dart';
import '../../Models/appstate.dart';
import '../../Models/sales_model1.dart';
import '../../Utilities/rest_ds.dart';
import '../../confg/appconfig.dart';
import '../../confg/sizeconfig.dart';
import '../../vanstocktst.dart';
import 'QuotatioCustomerScreen.dart';

class QuotationProduct extends StatefulWidget {
  static const routeName = "/QuotationProduct";
  @override
  _QuotationProductState createState() =>
      _QuotationProductState();
}

int? id;
String? name;

class _QuotationProductState
    extends State<QuotationProduct> {
  List<Products> products = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMoreProducts = true;
  bool _isDialogOpen = false;
  bool _search = true;
  List<Products> filteredProducts = [];
  bool _isSearching = false;
  Timer? _debounce;

  final TextEditingController _searchData = TextEditingController();
  @override
  void initState() {
    super.initState();
    // _searchData.addListener(() {
    //   if (_searchData.text.isEmpty) {
    //     products.clear();
    //     currentPage = 1;
    //     hasMoreProducts = true;
    //     fetchProducts(currentPage);
    //   } else {
    //     _filterProducts(_searchData.text);
    //   }
    // });
    fetchProducts(currentPage);
  }

  @override
  void dispose() {
    _searchData.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterProducts(query);
    });
  }

  Future<void> fetchProducts(int page) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });
    // get_product_with_warehouse_stock_for_order
    final String url =
        '${RestDatasource().BASE_URL}/api/get_product_for_order?store_id=${AppState().storeId}&customer_id=$id&page=$page';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print(response.request);
      final data = jsonDecode(response.body);
      final List<Products> fetchedProducts = (data['data']['data'] as List)
          .map((json) => Products.fromJson(json))
          .toList();
      final pagination = data['data'];
      setState(() {
        isLoading = false;
        if (_searchData.text.isEmpty) {
          products.addAll(fetchedProducts);
          filteredProducts = List.from(products);
        }
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

  void _filterProducts(String query) async {
    if (query != _searchData.text) return;

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        filteredProducts = List.from(products);
      });
      return;
    }

    setState(() {
      _isSearching = true;
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          '${RestDatasource().BASE_URL}/api/get_product_with_van_stock_for_search?store_id=${AppState().storeId}&value=$query'));

      if (_isSearching && response.statusCode == 200) {
        print(response.request);
        print(query);
        final data = jsonDecode(response.body);
        final List<Products> fetchedProducts = (data['data'] as List)
            .map((json) => Products.fromJson(json))
            .toList();

        if (mounted && query == _searchData.text) {
          setState(() {
            filteredProducts = fetchedProducts;
          });
        }
      }
    } catch (e) {
      print('Error fetching search results: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
    if (ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params =
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      name = params!['name'];
      id = params!['customerId'];
    }
    print("id$id");

    return WillPopScope(
      onWillPop: () async {
        await _onBackPressed();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Navigator.pushReplacementNamed(
                    context, QuotatioCustomerScreen.routeName,
                    arguments: {'name': name, 'customerId': id});
              },
              icon: Icon(Icons.arrow_back)),
          iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
          title: const Text(
            'Select Products',
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
                autofocus: true,
                style: TextStyle(color: Colors.white),
                controller: _searchData,
                onChanged:_onSearchChanged,
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
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${product.code} | ${product.name!.toUpperCase()}',
                                        style: TextStyle(
                                            fontSize: AppConfig
                                                .textCaption2Size),
                                      ),
                                      // Row(
                                      //   children: [
                                      //     // for (int i = data.productDetail!.length - 1;
                                      //     //     i >= 0;
                                      //     //     i--)
                                      //     Text(
                                      //       product.units != null &&
                                      //               product.units.length >
                                      //                   0
                                      //           ? '${product.units[0].name}:${product.units[0].stock}'
                                      //           : '',
                                      //       style: TextStyle(
                                      //         fontSize: AppConfig
                                      //             .textCaption3Size,
                                      //       ),
                                      //     ),
                                      //     SizedBox(
                                      //       width: 10,
                                      //     ),
                                      //     Text(
                                      //       product.units != null &&
                                      //               product.units.length >
                                      //                   1
                                      //           ? '${product.units[1].name}:${product.units[1].stock}'
                                      //           : '',
                                      //       style: TextStyle(
                                      //         fontSize: AppConfig
                                      //             .textCaption3Size,
                                      //       ),
                                      //     ),
                                      //     SizedBox(
                                      //       width: 10,
                                      //     ),
                                      //     Text(
                                      //       product.units != null &&
                                      //               product.units.length >
                                      //                   2
                                      //           ? '${product.units[2].name}:${product.units[2].stock}'
                                      //           : '',
                                      //       style: TextStyle(
                                      //         fontSize: AppConfig
                                      //             .textCaption3Size,
                                      //       ),
                                      //     ),
                                      //   ],
                                      // ),
                                      // if (product.lastdate != '' &&
                                      //     product.lastUnit != '' &&
                                      //     product.lastPrice != '')
                                      //   Text('Last Sale:'),
                                      if (product.lastdate != '' &&
                                          product.lastUnit != '' &&
                                          product.lastPrice != '')
                                        Text(
                                          'Last Sale: ${product.lastdate} | ${product.lastUnit} | ${product.lastPrice}',
                                          style: TextStyle(
                                              fontSize: AppConfig
                                                  .textCaption2Size,
                                              overflow:
                                              TextOverflow.fade),
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void showProductDetailsDialog(BuildContext context, Products product) async {
    // int? id;
    final String url =
        '${RestDatasource().BASE_URL}/api/get_product_with_units_for_order?store_id=${AppState().storeId}&van_id=${AppState().vanId}&id=${product.id}&customer_id=$id';
    final response = await http.get(Uri.parse(url));
    final typeResponse = await http
        .get(Uri.parse('${RestDatasource().BASE_URL}/api/get_product_type'));

    if (response.statusCode == 200 && typeResponse.statusCode == 200) {
      print(response.request);
      final data = jsonDecode(response.body);
      final units = data['data'] as List?;
      final lastsale = data['lastsale'];
      final typeData = jsonDecode(typeResponse.body);
      final productTypes = typeData['data'] as List;

      String? selectedUnitId;
      String? selectedProductTypeId;
      String? quantity;
      String? amount;
      Map<String, dynamic>? selectedUnit;
      String? name;
      double? availableStock;
      if (productTypes.isNotEmpty) {
        selectedProductTypeId = productTypes[0]['id'].toString();
      }

      final amountController = TextEditingController();
      final descriptionController = TextEditingController();
      if (units != null && units.any((unit) => unit != null)) {
        selectedUnitId = units[0]['id'].toString();
        selectedUnit = units[0];
        amountController.text = selectedUnit?['price']?.toString() ?? '';
        availableStock =
            double.tryParse(selectedUnit?['stock']?.toString() ?? '0');
      }
      bool isQuantityValid(String? value) {
        final quantityValue = double.tryParse(value ?? '') ?? 0;
        return value != null &&
            value.isNotEmpty &&
            quantityValue > 0 &&
            AppState().validate_qtySO == 'Yes'
            ? quantityValue <= (availableStock ?? 0)
            : quantityValue > 0;
      }

      final uniqueUnits = {
        for (var unit in units!) unit['id'].toString(): unit
      }.values.toList();

      if (ModalRoute.of(context)!.settings.arguments != null) {
        final Map<String, dynamic>? params =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        name = params!['name'];
        id = params!['customerId'];
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          bool showDescriptionField = false;
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
                              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                              contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 10.w),
                              border: const OutlineInputBorder(borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey.shade300,
                            ),
                            items: uniqueUnits
                                .map((unit) => DropdownMenuItem<String>(
                              value: unit['id'].toString(),
                              child: Text(unit['name']),
                            ))
                                .toList(),
                            value: units.any((u) => u['id'].toString() == selectedUnitId)
                                ? selectedUnitId
                                : null,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedUnitId = value;

                                selectedUnit = units.firstWhere(
                                      (unit) => unit['id'].toString() == value,
                                );

                                amountController.text =
                                    selectedUnit?['price']?.toString() ?? '';

                                availableStock = double.tryParse(
                                    selectedUnit?['stock']?.toString() ?? '0');
                              });
                            },
                            hint: const Text('Select Unit'),
                          ),
                          SizedBox(height: 10.h),
                          TextFormField(
                            keyboardType: TextInputType.number,
                            controller: amountController,
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
                        // SizedBox(height: 10.h),
                        if (showDescriptionField)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            child: TextFormField(
                              controller: descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 2.h, horizontal: 10.w),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none),
                                filled: true,
                                fillColor: Colors.grey.shade300,
                              ),
                            ),
                          ),
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
                          'description':descriptionController.text??'',
                        };
                        selectedProducts.add(jsonEncode(selectedProduct));
                        await prefs.setStringList(
                            'selected_products', selectedProducts);
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(
                            context, QuotatioCustomerScreen.routeName,
                            arguments: {
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
