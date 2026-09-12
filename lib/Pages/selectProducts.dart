import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/DashBoardScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../Components/commonwidgets.dart';
import '../Models/sales_model.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'newvanstockrequests.dart';

class SelectProductsScreen extends StatefulWidget {
  static const routeName = "/SelectProductScreen";

  @override
  _SelectProductsScreenState createState() => _SelectProductsScreenState();
}

class _SelectProductsScreenState extends State<SelectProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  List<Product> filteredProducts = [];
  int currentPage = 1;
  bool isLoading = false;
  bool _hasMore = true;
  bool _search = true;
  final TextEditingController _searchData = TextEditingController();
  bool _isSearching = false;
  Timer? _debounce;
  int? id;
  String? name;
  String? code;
  String? payment;


  @override
  void initState() {
    super.initState();
    // _debouncer = Debouncer(milliseconds: 300);
    _fetchProducts();

    // _scrollController.addListener(() {
    //   if (_scrollController.position.pixels ==
    //       _scrollController.position.maxScrollExtent &&
    //       _hasMore &&
    //       !isLoading) {
    //     _fetchProducts();
    //   }
    // });
    //
    // _searchData.addListener(() {
    //   _debouncer.run(() {
    //     _searchProducts(_searchData.text);
    //   });
    // });
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final productData = await fetchProducts(currentPage);
      setState(() {
        _products.addAll(productData.data.products);
        filteredProducts = List.from(_products);
        currentPage++;
        _hasMore = currentPage <= productData.data.lastPage;
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _filterProducts(query);
    });
  }

  void _filterProducts(String query) async {
    if (query != _searchData.text) return;

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        filteredProducts = List.from(_products);
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
        print(query);
        final data = jsonDecode(response.body);
        final List<Product> fetchedProducts = (data['data'] as List)
            .map((json) => Product.fromJson(json))
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

  @override
  void dispose() {
    _scrollController.dispose();
    _searchData.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      id = params!['customerId'];
      name = params!['name'];
      code = params!['code'];
      payment = params!['paymentTerms'];
    }
    return Scaffold(
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
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(5),
                        hintText: "Search...",
                        hintStyle: TextStyle(color: AppConfig.backgroundColor),
                        border: InputBorder.none),
                  ),
                )
              : Container(),
          CommonWidgets.horizontalSpace(1),
          GestureDetector(
            onTap: () {
              setState(() {
                _search = !_search;
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
      body: isLoading && _products.isEmpty
          ? Shimmer.fromColors(
              baseColor: AppConfig.buttonDeactiveColor.withOpacity(0.1),
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
          : _products.isEmpty
              ? Center(
                  child: Text(
                      'No products found'), // Show message when no data after loading
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 2),
                      child: Card(
                        elevation: 3,
                        child: InkWell(
                          onTap: () => showProductDetailsDialog(context, product),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Tooltip(
                                        message: product.name!.toUpperCase(),
                                        child: SizedBox(
                                          width:
                                              SizeConfig.blockSizeHorizontal *
                                                  70,
                                          child: Text(
                                            '${product.code} | ${product.name!.toUpperCase()}',
                                            style: TextStyle(
                                                fontSize:
                                                    AppConfig.textCaption2Size),
                                          ),
                                        ),
                                      ),
                                      // Row(
                                      //   children: [
                                      //     Text(
                                      //       product.units != null &&
                                      //               product.units.length > 0
                                      //           ? '${product.units[0].name}:${product.units[0].stock}'
                                      //           : '',
                                      //       style: TextStyle(
                                      //         fontSize:
                                      //             AppConfig.textCaption3Size,
                                      //       ),
                                      //     ),
                                      //     SizedBox(
                                      //       width: 10,
                                      //     ),
                                      //     Text(
                                      //       product.units != null &&
                                      //               product.units.length > 1
                                      //           ? '${product.units[1].name}:${product.units[1].stock}'
                                      //           : '',
                                      //       style: TextStyle(
                                      //         fontSize:
                                      //             AppConfig.textCaption3Size,
                                      //       ),
                                      //     )
                                      //   ],
                                      // )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

void showProductDetailsDialog(BuildContext context, Product product) async {
    int? id;
    final response = await http.get(Uri.parse(
        'http://68.183.92.8:3699/api/get_product_with_units_by_product_without_unit_price?store_id=${AppState().storeId}&id=${product.id}&user_id=${AppState().userId}&van_id=${AppState().vanId}'));
    print(response.request); 
    final typeResponse = await http.get(Uri.parse('${RestDatasource().BASE_URL}/api/get_product_return_type?store_id=${AppState().storeId}'));

    if (response.statusCode == 200 && typeResponse.statusCode == 200) {
      print(response.request);
      final data = jsonDecode(response.body);
      final productData = data['data'];
      final productDetails = productData['product_detail'] as List?;  // New response key
      final typeData = jsonDecode(typeResponse.body);
      final productTypes = typeData['data'] as List;

      String? selectedUnitId;
      // String? selectedProductTypeId;
      String? quantity;

      double? availableStock;
      Map<String, dynamic>? selectedUnit;
      String? name;

      // if (productTypes.isNotEmpty) {
      //   // Look for the product type whose name is 'Normal'
      //   final normalType = productTypes.firstWhere(
      //         (type) => type['name'] == 'Normal',
      //     orElse: () => null, // In case there's no 'Normal' type
      //   );
      //   if (normalType != null) {
      //     // Set selectedProductTypeId to the ID of the 'Normal' type
      //     selectedProductTypeId = normalType['id'].toString();
      //   } else {
      //     // Fallback to the first product type if 'Normal' doesn't exist
      //     selectedProductTypeId = productTypes[0]['id'].toString();
      //   }
      // }

      final amountController = TextEditingController();
      if (productDetails != null && productDetails.isNotEmpty) {
        selectedUnitId = productDetails[0]['id'].toString();
        selectedUnit = productDetails[0];
        amountController.text = selectedUnit?['price']?.toString() ?? '';
        availableStock = double.tryParse(selectedUnit?['stock']?.toString() ?? '0');
      }

      bool isQuantityValid(String? value) {
        return value != null && value.isNotEmpty;
      }

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
                          ],
                        ),
                        SizedBox(height: 5.h),
                        // if (selectedUnit != null) ...[
                        //   Text(
                        //     'Available Qty: ${selectedUnit!['stock']}',
                        //     style: TextStyle(fontWeight: FontWeight.bold),
                        //   ),
                        // ],
                        SizedBox(height: 10.h),
                        // DropdownButtonFormField<String>(
                        //   decoration: InputDecoration(
                        //     labelText: 'Product Type',
                        //     labelStyle: TextStyle(fontWeight: FontWeight.bold),
                        //     contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 10.w),
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
                        //
                        //       final selectedType = productTypes.firstWhere(
                        //             (type) => type['id'].toString() == value,
                        //         orElse: () => null,
                        //       );
                        //
                        //       if (selectedType != null && selectedType['name'] != 'Normal') {
                        //         amountController.text = '0';
                        //       } else if (selectedUnit != null) {
                        //         amountController.text = selectedUnit?['price']?.toString() ?? '';
                        //       }
                        //     });
                        //   },
                        //   value: selectedProductTypeId,
                        //   hint: Text('Select Product Type'),
                        // ),
                        // SizedBox(height: 10.h),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            labelStyle: TextStyle(fontWeight: FontWeight.bold),
                            contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 10.w),
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.grey.shade300,
                          ),
                          items: productDetails?.map((unit) {
                            return DropdownMenuItem<String>(
                              value: unit['id'].toString(),
                              child: Text(unit['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedUnitId = value;
                              selectedUnit = productDetails?.firstWhere(
                                      (unit) => unit['id'].toString() == value,
                                  orElse: () => null);
                              amountController.text = selectedUnit?['price']?.toString() ?? '';
                              availableStock = double.tryParse(selectedUnit?['stock']?.toString() ?? '0');
                            });
                          },
                          value: selectedUnitId,
                          hint: Text('Select Unit'),
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
                              labelStyle: TextStyle(fontWeight: FontWeight.bold),
                              contentPadding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 10.w),
                              hintText: 'Qty',
                              border: OutlineInputBorder(borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey.shade300),
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
                      'Close',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      print("DATAAAA${prefs.getStringList('selected_productss')}");
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
                      final prefs = await SharedPreferences.getInstance();
                      List<String>? selectedProducts = prefs.getStringList('selected_productss');
                      selectedProducts ??= [];
                      final serialNumber = DateTime.now().millisecondsSinceEpoch.toString() +
                          '-' +
                          (1000 + (DateTime.now().microsecond % 9000)).toString();
                      final selectedProduct = {
                        'serial_number': serialNumber,
                        'id': product.id,
                        'code': product.code,
                        'name': product.name,
                        'pro_image': product.proImage,
                        'product_type': 'Expired',
                        // 'type_id': selectedProductTypeId,
                        // 'type_name': productTypes.firstWhere((type) => type['id'].toString() == selectedProductTypeId)['name'],
                        'unit_id': selectedUnitId,
                        'unit_name': selectedUnit?['name'],
                        'quantity': quantity ?? '',
                        'amount': amountController.text ?? '',
                      };
                      selectedProducts.add(jsonEncode(selectedProduct));
                      await prefs.setStringList('selected_productss', selectedProducts);
                      Navigator.pop(context);
                      print("DAta${selectedProduct}");
                      Navigator.pushReplacementNamed(
                          context, VanStocks.routeName, arguments: {
                        'name': name,
                        'customerId': id,
                      });
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


  Future<ProductDataModel> fetchProducts(int page) async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_product_with_van_stock?store_id=${AppState().storeId}&van_id=${AppState().vanId}&page=$page'));
    if (response.statusCode == 200) {
      print(response.request);
      return ProductDataModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load products');
    }
  }
}

class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

