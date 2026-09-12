import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/DashBoardScreen.dart';
import 'package:mobizapp/confg/apptextsizes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../Components/commonwidgets.dart';
import '../Models/sales_model.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'customerreturndetails.dart';

class Salesselectproductreturn extends StatefulWidget {
  static const routeName = "/Salesselectproductreturn";

  @override
  _SalesselectproductreturnState createState() =>
      _SalesselectproductreturnState();
}

class _SalesselectproductreturnState extends State<Salesselectproductreturn> {
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  int _currentPage = 1;
  int?pricegroupId;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _search = false;
  final TextEditingController _searchData = TextEditingController();
  int? id;
  int? saleId;
  String? name;
  String? code;
  String? payment;
  String? paydata;
  List<ProductType> productTypes = [];
  // int? dataId;
      Future<bool> addToCart(
        Product product, String qty, String rate, String? typeName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartItems = prefs.getStringList('cartItemsreturn') ?? [];

    // Count how many instances of the product are already in the cart
    int productCount = cartItems.fold(0, (count, item) {
      Map<String, dynamic> itemMap = jsonDecode(item);
      return itemMap['id'] == product.id ? count + 1 : count;
    });

    // Restriction logic based on the number of units
    if (product.units.length == 1 && productCount >= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} is already in the cart')),
      );
      return false;
    } else if (product.units.length == 2 && productCount >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only 2 ${product.name} can be added')),
      );
      return false;
    }

    // Index this new item will occupy — so the qty/rate the user entered
    // lands on the correct cartItemsreturn row.
    int newIndex = cartItems.length;
    cartItems.add(jsonEncode(product.toJson()));
    await prefs.setStringList('cartItemsreturn', cartItems);
      await prefs.setString('qtyreturn$newIndex', qty);
    await prefs.setString('amountreturn$newIndex', rate);
    if (typeName != null) {
      await prefs.setString('productTypereturn$newIndex', typeName);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added')),
    );
    return true;
  }
    @override
  void initState() {
    super.initState();
    _fetchProducts();
    fetchProductTypes();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          _hasMore &&
          !_isLoading) {
        _fetchProducts();
      }
    });
    _searchData.addListener(() {
      _searchProducts(_searchData.text);
    });
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productData = await fetchProducts(_currentPage);
      setState(() {
        _products.addAll(productData.data.products);
        _filteredProducts = List.from(_products);
        _currentPage++;
        _hasMore = _currentPage <= productData.data.lastPage;
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Product>> fetchSearchedProducts(String query) async {
    final response = await http.get(
      Uri.parse(
          '${RestDatasource().BASE_URL}/api/get_product_with_van_stock_for_search?store_id=${AppState().storeId}&value=$query'),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return (jsonResponse['data'] as List)
          .map((productJson) => Product.fromJson(productJson))
          .toList();
    } else {
      throw Exception('Failed to load search results');
    }
  }

  Future<void> _searchProducts(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (query.isEmpty) {
        // If the search query is empty, reset to show all products.
        _filteredProducts = List.from(_products);
      } else {
        // Call the search API with the query
        final searchResults = await fetchSearchedProducts(query);

        // Update the filtered products with search results
        setState(() {
          _filteredProducts = searchResults;
          _hasMore = false; // Assume search doesn't need pagination
        });
      }
    } catch (e) {
      print('Error searching products: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      paydata = params!['outstandamt'];
      pricegroupId = params!['price_group_id'];
      saleId = params!['saleId'];
      print(saleId);
      // dataId = params!['dataId'];
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
      body: _isLoading && _products.isEmpty
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
          : _filteredProducts.isEmpty
              ? Center(
                  child: Text(
                      'No products found'), // Show message when no data after loading
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _filteredProducts.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _filteredProducts.length) {
                      return SizedBox.shrink();
                    }
                    final product = _filteredProducts[index];
                                    return GestureDetector(
                      onTap: () {
                        showAddQuantityDialog(product);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15.0, vertical: 2),
                        child: Card(
                          elevation: 3,
                          child: Container(
                            width: SizeConfig.blockSizeHorizontal * 90,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color:
                                      // selectedItems.contains(index)
                                      //     ? AppConfig.colorPrimary
                                      //     :
                                      Colors.transparent),
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
                                      Row(
                                        children: [
                                          // for (int i = data.productDetail!.length - 1;
                                          //     i >= 0;
                                          //     i--)
                                          Text(
                                            product.units != null &&
                                                    product.units.length > 0
                                                ? '${product.units[0].name}:${product.units[0].stock}'
                                                : '',
                                            style: TextStyle(
                                              fontSize:
                                                  AppConfig.textCaption3Size,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            product.units != null &&
                                                    product.units.length > 1
                                                ? '${product.units[1].name}:${product.units[1].stock}'
                                                : '',
                                            style: TextStyle(
                                              fontSize:
                                                  AppConfig.textCaption3Size,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            product.units != null &&
                                                    product.units.length > 2
                                                ? '${product.units[2].name}:${product.units[2].stock}'
                                                : '',
                                            style: TextStyle(
                                              fontSize:
                                                  AppConfig.textCaption3Size,
                                            ),
                                          ),
                                        ],
                                      )
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
   void showAddQuantityDialog(Product product) {
  final qtyController = TextEditingController(text: '1');
  final rateController =
      TextEditingController(text: product.price.toString());

  String? selectedUnitName =
      product.units.isNotEmpty ? product.units.first.name : null;

  ProductType? selectedType =
      productTypes.isNotEmpty ? productTypes.first : null;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          // Existing preview calculation — display only.
          double previewQty =
              double.tryParse(qtyController.text) ?? 0;

          double previewRate =
              double.tryParse(rateController.text) ?? 0;

          double previewAmount =
              previewQty * previewRate;

       return Dialog(
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.white,
  shadowColor: Colors.black26,
  insetPadding: const EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 22,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24),
  ),
  child: Container(
    color: Colors.white,
  child: Container(
  color: Colors.white,
  child: ConstrainedBox(
    constraints: const BoxConstraints(
      maxWidth: 520,
    ),
    child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  20,
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
                              fontSize: AppFontSizes.dialogTitle,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF222222),
                              height: 1.25,
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
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 28,
                              color: Color(0xFF777777),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE3E3E3),
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
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Product Type',
                                style: TextStyle(
                                  fontSize:
                                      AppFontSizes.dialogLabel,
                                  fontWeight:
                                      FontWeight.w700,
                                  color: Color(0xFF222222),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Container(
                                height: 52,
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        const Color(0xFFDCDCE3),
                                    width: 1,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(11),
                                ),
                                child:
                                    DropdownButtonHideUnderline(
                                  child:
                                      DropdownButtonFormField<
                                          ProductType>(
                                    isExpanded: true,
                                    decoration:
                                        const InputDecoration(
                                      border:
                                          InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          EdgeInsets.zero,
                                    ),
                                    icon: const Icon(
                                      Icons
                                          .keyboard_arrow_down_rounded,
                                      size: 24,
                                      color:
                                          Color(0xFF6F727A),
                                    ),
                                    style: const TextStyle(
                                      fontSize:
                                          AppFontSizes.dialogInput,
                                      color:
                                          Color(0xFF222222),
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                    value: selectedType,
                                    hint: const Text(
                                      'Normal',
                                      style: TextStyle(
                                        fontSize:
                                            AppFontSizes
                                                .dialogInput,
                                        color:
                                            Color(0xFF999999),
                                      ),
                                    ),
                                    items: productTypes
                                        .map((type) {
                                      return DropdownMenuItem<
                                          ProductType>(
                                        value: type,
                                        child: Text(
                                          type.name,
                                        ),
                                      );
                                    }).toList(),
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

                        const SizedBox(width: 16),

                        // UNIT
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Unit',
                                style: TextStyle(
                                  fontSize:
                                      AppFontSizes.dialogLabel,
                                  fontWeight:
                                      FontWeight.w700,
                                  color: Color(0xFF222222),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Container(
                                height: 52,
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        const Color(0xFFDCDCE3),
                                    width: 1,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(11),
                                ),
                                child: product.units.length > 1
                                    ? DropdownButtonHideUnderline(
                                        child:
                                            DropdownButtonFormField<
                                                String>(
                                          isExpanded: true,
                                          decoration:
                                              const InputDecoration(
                                            border:
                                                InputBorder.none,
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.zero,
                                          ),
                                          icon: const Icon(
                                            Icons
                                                .keyboard_arrow_down_rounded,
                                            size: 24,
                                            color:
                                                Color(0xFF6F727A),
                                          ),
                                          style: const TextStyle(
                                            fontSize:
                                                AppFontSizes
                                                    .dialogInput,
                                            color:
                                                Color(0xFF222222),
                                            fontWeight:
                                                FontWeight.w500,
                                          ),
                                          value:
                                              selectedUnitName,
                                          items: product.units
                                              .where((u) =>
                                                  u.name != null)
                                              .map(
                                                (u) =>
                                                    DropdownMenuItem<
                                                        String>(
                                                  value: u.name,
                                                  child: Text(
                                                    u.name!,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) {
                                            setDialogState(() {
                                              selectedUnitName =
                                                  value;
                                            });
                                          },
                                        ),
                                      )
                                    : Align(
                                        alignment:
                                            Alignment.centerLeft,
                                        child: Text(
                                          selectedUnitName ?? '',
                                          style: const TextStyle(
                                            fontSize:
                                                AppFontSizes
                                                    .dialogInput,
                                            color:
                                                Color(0xFF222222),
                                            fontWeight:
                                                FontWeight.w500,
                                          ),
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
                    // QUANTITY + RATE
                    // =========================================================

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // QUANTITY
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quantity *',
                                style: TextStyle(
                                  fontSize:
                                      AppFontSizes.dialogLabel,
                                  fontWeight:
                                      FontWeight.w700,
                                  color: Color(0xFF222222),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        AppConfig.colorPrimary,
                                    width: 1.5,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(11),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 12),

                                    Icon(
                                      Icons.swap_vert,
                                      size: 21,
                                      color:
                                          AppConfig.colorPrimary,
                                    ),

                                    const SizedBox(width: 8),

                                    Expanded(
                                      child: TextField(
                                        controller:
                                            qtyController,
                                        autofocus: true,
                                        keyboardType:
                                            TextInputType.number,
                                        style: const TextStyle(
                                          fontSize:
                                              AppFontSizes.dialogInput,
                                          fontWeight:
                                              FontWeight.w600,
                                          color:
                                              Color(0xFF222222),
                                        ),
                                        decoration:
                                            const InputDecoration(
                                          border:
                                              InputBorder.none,
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

                                    const SizedBox(width: 10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // RATE
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rate *',
                                style: TextStyle(
                                  fontSize:
                                      AppFontSizes.dialogLabel,
                                  fontWeight:
                                      FontWeight.w700,
                                  color: Color(0xFF222222),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color:
                                        const Color(0xFFDCDCE3),
                                    width: 1,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(11),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 14),

                                    Expanded(
                                      child: TextField(
                                        controller:
                                            rateController,
                                        keyboardType:
                                            const TextInputType
                                                .numberWithOptions(
                                          decimal: true,
                                        ),
                                        style: const TextStyle(
                                          fontSize:
                                              AppFontSizes.dialogInput,
                                          fontWeight:
                                              FontWeight.w600,
                                          color:
                                              Color(0xFF222222),
                                        ),
                                        decoration:
                                            const InputDecoration(
                                          border:
                                              InputBorder.none,
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

                                    const Icon(
                                      Icons.edit,
                                      size: 21,
                                      color:
                                          AppConfig.colorPrimary,
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

                    const SizedBox(height: 20),

                    // =========================================================
                    // AMOUNT
                    // =========================================================

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFDCDCE3),
                          width: 1,
                        ),
                        borderRadius:
                            BorderRadius.circular(11),
                      ),
                      child: Row(
                        children: [

                          const Icon(
                            Icons.calculate_outlined,
                            size: 22,
                            color: Color(0xFF8A8D98),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              previewAmount.toStringAsFixed(3),
                              style: const TextStyle(
                                fontSize:
                                    AppFontSizes.dialogInput,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF222222),
                              ),
                            ),
                          ),

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDEDFB),
                              borderRadius:
                                  BorderRadius.circular(18),
                            ),
                            child: Text(
                              'Calculated',
                              style: TextStyle(
                                fontSize:
                                    AppFontSizes.dialogBody,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    AppConfig.colorPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // =========================================================
                    // BOTTOM BUTTONS
                    // =========================================================

                    Row(
                      children: [

                        // CANCEL
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color:
                                    AppConfig.colorPrimary,
                                width: 1.5,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize:
                                    AppFontSizes.dialogInput,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    AppConfig.colorPrimary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // ADD
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppConfig.colorPrimary,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                          

                              if (selectedUnitName != null) {
                                product.selectedUnitName =
                                    selectedUnitName;
                              }

                              await addToCart(
                                product,
                                qtyController.text.isEmpty
                                    ? '1'
                                    : qtyController.text,
                                rateController.text,
                                selectedType?.name,
                              );

                              Navigator.pop(context);

                              Navigator.pushReplacementNamed(
                                context,
                                Customerreturndetail.routeName,
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
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_shopping_cart,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Add',
                                  style: const TextStyle(
                                    fontSize:
                                        AppFontSizes.dialogInput,
                                    fontWeight:
                                        FontWeight.w700,
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
              ),
            ),
          );
        },
      );
    },
  );
}
   Future<ProductDataModel> fetchProducts(int page) async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_product_with_van_stock?store_id=${AppState().storeId}&van_id=${AppState().vanId}&page=$page'));

    if (response.statusCode == 200) {
      return ProductDataModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load products');
    }
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
      });
    }
  }
}
