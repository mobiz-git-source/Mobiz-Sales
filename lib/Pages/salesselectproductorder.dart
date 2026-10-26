import 'dart:async';
import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mobizapp/Pages/customerorderdetail.dart';
import 'package:mobizapp/DashBoardScreen.dart';
import 'package:mobizapp/confg/apptextsizes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../Components/commonwidgets.dart';
import '../Models/appstate.dart';
import '../Models/sales_model1.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';

class SalesSelectProductsorderScreen extends StatefulWidget {
  static const routeName = "/SalesSelectProductsorderScreen";
  @override
  _SalesSelectProductsorderScreenState createState() =>
      _SalesSelectProductsorderScreenState();
}

// int? id;
String? name;

class _SalesSelectProductsorderScreenState
    extends State<SalesSelectProductsorderScreen> {
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
    print("PRODUCT DETAILS API RESPONSE:");
    print(response.body);
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
                    context, Customerorderdetail.routeName,
                    arguments: {'name': name, 'customerId': id});
              },
              icon: Icon(Icons.arrow_back)),
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
    // Outer (screen) context — used to show the SnackBar AFTER the dialog
    // closes, so the alert is fully visible instead of hidden behind the
    // modal dialog.
    final BuildContext screenContext = context;

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

      // ---- Already-in-cart quantity (for this product), per unit ----
      final prefsForStock = await SharedPreferences.getInstance();
      final List<String> cartItemsForStock =
          prefsForStock.getStringList('selected_products') ?? [];
      double alreadyInCartQtyForUnit(String? unitId) {
        double total = 0.0;
        for (var item in cartItemsForStock) {
          try {
            final decoded = jsonDecode(item);
            if (decoded['id'].toString() == product.id.toString() &&
                decoded['unit_id'].toString() == (unitId ?? '')) {
              total +=
                  double.tryParse(decoded['quantity']?.toString() ?? '0') ??
                      0.0;
            }
          } catch (_) {}
        }
        return total;
      }
      // ---- end already-in-cart helper ----
double roundQty(double v) => double.parse(v.toStringAsFixed(3));
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
        final double _rawStock0 =
            double.tryParse(selectedUnit?['stock']?.toString() ?? '0') ??
                0.0;
         final double _inCart0 = alreadyInCartQtyForUnit(selectedUnitId);
        final double _remaining0 = _rawStock0 - _inCart0;
        availableStock = _remaining0 < 0 ? 0 : roundQty(_remaining0);
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

 
bool isFocSelected() {
  try {
    final t = productTypes.firstWhere(
      (t) => t['id'].toString() == selectedProductTypeId,
      orElse: () => null,
    );
    return t != null && t['is_foc'].toString() == '1';
  } catch (_) {
    return false;
  }
}

bool isAmountValid() {
  if (isFocSelected()) return true; // is_foc = 1 aanenkil 0 allow
  final enteredAmount = double.tryParse(amountController.text.trim()) ?? 0;
  final minPrice =
      double.tryParse(selectedUnit?['min_price']?.toString() ?? '0') ?? 0;
  return minPrice == 0 || enteredAmount >= minPrice;
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
          bool showDescriptionField = false;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      22,
                      20,
                      22,
                      0,
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
                                  fontSize: AppFontSizes.dialogTitle,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF222222),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(3),
                                child: Icon(
                                  Icons.close,
                                  size: 30,
                                  color: Color(0xFF77798A),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE3E3E3),
                        ),

                        const SizedBox(height: 22),

                        // =========================================================
                        // AVAILABLE QTY
                        // =========================================================

                                             if (selectedUnit != null) ...[
                          Text(
                            'Available Qty: ${(availableStock ?? 0) % 1 == 0 ? (availableStock ?? 0).toInt().toString() : (availableStock ?? 0).toString()}',
                            style: const TextStyle(
                              fontSize: AppFontSizes.dialogHighlight,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF222222),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Minimum Rate : ${selectedUnit?['min_price'] ?? '0'}',
                            style: const TextStyle(
                              fontSize: AppFontSizes.dialogHighlight,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

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
                                      fontSize: AppFontSizes.dialogLabel,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 52,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFFDCDCE3),
                                      ),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        value: selectedProductTypeId,
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 24,
                                          color: Color(0xFF77798A),
                                        ),
                                        style: const TextStyle(
                                          fontSize: AppFontSizes.dialogInput,
                                          color: Color(0xFF222222),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        items: productTypes.map((type) {
                                          return DropdownMenuItem<String>(
                                            value: type['id'].toString(),
                                            child: Text(
                                              type['name'],
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setDialogState(() {
                                            selectedProductTypeId = value;

                                            final selectedType =
                                                productTypes.firstWhere(
                                              (type) =>
                                                  type['id'].toString() ==
                                                  value,
                                              orElse: () => {},
                                            );

                                            if (selectedType.isNotEmpty &&
                                                selectedType['name'] !=
                                                    'Normal') {
                                              amountController.text = '0';
                                            } else if (selectedUnit != null) {
                                              amountController.text =
                                                  selectedUnit?['price']
                                                          ?.toString() ??
                                                      '';
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // UNIT
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Unit',
                                    style: TextStyle(
                                      fontSize: AppFontSizes.dialogLabel,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 52,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFFDCDCE3),
                                      ),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        value: selectedUnitId,
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 24,
                                          color: Color(0xFF77798A),
                                        ),
                                        style: const TextStyle(
                                          fontSize: AppFontSizes.dialogInput,
                                          color: Color(0xFF222222),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        items: units!
                                            .where((unit) => unit != null)
                                            .map((unit) {
                                          return DropdownMenuItem<String>(
                                            value: unit['id'].toString(),
                                            child: Text(
                                              unit['name'],
                                              overflow: TextOverflow.ellipsis,
                                            ),
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
                                                selectedUnit?['price']
                                                        ?.toString() ??
                                                    '';

                                            final double _rawStock =
                                                double.tryParse(
                                              selectedUnit?['stock']
                                                      ?.toString() ??
                                                  '0',
                                            ) ??
                                                0.0;
                                                                                final double _inCart =
                                                alreadyInCartQtyForUnit(
                                                    selectedUnitId);
                                            final double _remaining =
                                                _rawStock - _inCart;
                                            availableStock = _remaining < 0
                                                ? 0
                                                : roundQty(_remaining);
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // =========================================================
                        // AMOUNT + QUANTITY
                        // =========================================================

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // AMOUNT
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Amount',
                                    style: TextStyle(
                                      fontSize: AppFontSizes.dialogLabel,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFFDCDCE3),
                                      ),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 14),
                                        const Icon(
                                          Icons.calculate_outlined,
                                          size: 22,
                                          color: Color(0xFF77798A),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextFormField(
                                            controller: amountController,
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                              decimal: true,
                                            ),
                                            style: const TextStyle(
                                              fontSize:
                                                  AppFontSizes.dialogInput,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF222222),
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            onChanged: (_) {
                                              setDialogState(() {});
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                    ),
                                  ),
                                  if (!isAmountValid())
                                    const Padding(
                                      padding: EdgeInsets.only(top: 5),
                                      child: Text(
                                        'Amount cannot be below Minimum Rate',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // QUANTITY
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Quantity *',
                                    style: TextStyle(
                                      fontSize: AppFontSizes.dialogLabel,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: AppConfig.colorPrimary,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(11),
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
                                          child: TextFormField(
                                            autofocus: true,
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              quantity = value;
                                              setDialogState(() {});
                                            },
                                            style: const TextStyle(
                                              fontSize:
                                                  AppFontSizes.dialogInput,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF222222),
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                              hintText: 'Qty',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // =========================================================
                        // DESCRIPTION
                        // =========================================================

                        if (showDescriptionField) ...[
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: AppFontSizes.dialogLabel,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF222222),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFDCDCE3),
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: TextFormField(
                              controller: descriptionController,
                              maxLines: 4,
                              style: const TextStyle(
                                fontSize: AppFontSizes.dialogInput,
                                color: Color(0xFF222222),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(14),
                                hintText: 'Enter description (optional)',
                                hintStyle: TextStyle(
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // =========================================================
                        // BUTTONS
                        // =========================================================

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: AppConfig.colorPrimary,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    showDescriptionField = true;
                                  });
                                },
                                child: Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: AppFontSizes.dialogInput,
                                    fontWeight: FontWeight.w700,
                                    color: AppConfig.colorPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: AppConfig.colorPrimary,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  'Close',
                                  style: TextStyle(
                                    fontSize: AppFontSizes.dialogInput,
                                    fontWeight: FontWeight.w700,
                                    color: AppConfig.colorPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConfig.colorPrimary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                                             onPressed: isQuantityValid(quantity) &&
                                        isAmountValid()
                                    ? () async {
                                        final prefsCheck =
                                            await SharedPreferences
                                                .getInstance();
                                        final existingCheckList =
                                            prefsCheck.getStringList(
                                                    'selected_products') ??
                                                [];

                                        // ---- Duplicate check (Safest Version) ----
                                        bool alreadyExists = false;
                                        try {
                                          alreadyExists =
                                              existingCheckList.any((item) {
                                            final decoded = jsonDecode(item);
                                            return decoded['id'].toString() ==
                                                    product.id.toString() &&
                                                decoded['unit_id']
                                                        .toString() ==
                                                    selectedUnitId.toString();
                                          });
                                        } catch (e) {
                                          alreadyExists = false;
                                        }

                                        if (alreadyExists) {
                                          Navigator.of(context)
                                              .pop(); // close the product dialog first
                                          if (screenContext.mounted) {
                                            ScaffoldMessenger.of(
                                                    screenContext)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'This product is already in the cart. Please edit it from the cart.'),
                                                backgroundColor:
                                                    Colors.orange,
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                        // ---- end duplicate check ----

                                      final newProduct = {
  'id': product.id,
  'serial_number': DateTime.now()
      .millisecondsSinceEpoch
      .toString(),
  'code': product.code,
  'name': product.name,
  'unit_id': selectedUnitId,
  'unit_name': selectedUnit?['name'],
  'type_id': selectedProductTypeId,
  'type_name': productTypes.firstWhere(
    (type) =>
        type['id'].toString() ==
        selectedProductTypeId,
  )['name'],
  'quantity': quantity,
  'amount': amountController.text,
  'description':
      descriptionController.text,
  'tax_percentage': product.taxPercentage,
};

                                        final prefs = await SharedPreferences
                                            .getInstance();

                                        final existingList =
                                            prefs.getStringList(
                                                    'selected_products') ??
                                                [];

                                        existingList
                                            .add(jsonEncode(newProduct));

                                        await prefs.setStringList(
                                          'selected_products',
                                          existingList,
                                        );

// Directly go to Order page
                                     Navigator.pushReplacementNamed(
                                          context,
                                          Customerorderdetail.routeName,
                                          arguments: {
                                            'customerId': id,
                                            'name': name,
                                          },
                                        );
                                      }
                                    : null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                        fontSize: AppFontSizes.dialogInput,
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

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
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
