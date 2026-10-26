import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mobizapp/Pages/salesscreen.dart';
import 'package:mobizapp/DashBoardScreen.dart';
import 'package:mobizapp/Utilities/date_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../Components/commonwidgets.dart';
import '../Models/appstate.dart';
import '../Models/sales_model.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';

class SalesSelectProductsScreen extends StatefulWidget {
  static const routeName = "/SalesSelectProductsScreen";
  @override
  _SalesSelectProductsScreenState createState() =>
      _SalesSelectProductsScreenState();
}

String? name;
int? pricegroupId;

class _SalesSelectProductsScreenState extends State<SalesSelectProductsScreen> {
  List<Products> products = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMoreProducts = true;
  bool _search = true;
  List<Products> filteredProducts = [];
  bool _isDialogOpen = false;
  bool isAvailable = true;
  final TextEditingController _searchData = TextEditingController();
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchProducts(currentPage); // Initial fetch
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
    if (isLoading || _isSearching)
      return; // <- strictly prevents background loading

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          '${RestDatasource().BASE_URL}/api/get_product_with_van_stock_and_sales?store_id=${AppState().storeId}&page=$page'));
      print("===== FULL PRODUCT LIST WITH STOCK =====");
      print(response.body);
      print("==========================================");

      if (!_isSearching && response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Products> fetchedProducts = (data['data'] as List)
            .map((json) => Products.fromJson(json))
            .toList();
        final pagination = data['pagination'];

        setState(() {
          products.addAll(fetchedProducts);
          filteredProducts = List.from(products);
          currentPage++;
          hasMoreProducts = currentPage <= pagination['last_page'];
        });
      }
    } catch (e) {
      print('Error loading products: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
    print('Back button pressed');
  }

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      name = params!['name'];
      id = params['customerId'];
      if (params.containsKey('price_group_id')) {
        pricegroupId = params['price_group_id'];
      }
    }

    return WillPopScope(
      onWillPop: () async {
        await _onBackPressed();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back)),
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
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      border: Border.all(color: AppConfig.colorPrimary),
                    ),
                    child: TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
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
                  _isSearching = false;
                  _searchData.clear();
                  filteredProducts = List.from(products);
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
                        child: Column(
                          children: List.generate(
                              5,
                              (index) => CommonWidgets.loadingContainers(
                                  height: SizeConfig.blockSizeVertical * 10,
                                  width: SizeConfig.blockSizeHorizontal * 90)),
                        ),
                      )
                    : const Text('No products found'))
            : NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!_isSearching &&
                      !isLoading &&
                      hasMoreProducts &&
                      scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent) {
                    fetchProducts(currentPage);
                  }
                  return false;
                },
                child: ListView.builder(
                  itemCount: filteredProducts.length + (_isSearching ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (!_isSearching && index == filteredProducts.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text("That's All",
                              style: TextStyle(color: Colors.grey)),
                        ),
                      );
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
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
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
    // Outer (screen) context — used to show the SnackBar AFTER the dialog
    // closes, so the alert is fully visible instead of hidden behind the
    // modal dialog.
    final BuildContext screenContext = context;

    List<TextEditingController> serialTextControllers = [];
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_product_with_units_by_products?store_id=${AppState().storeId}&van_id=${AppState().vanId}&id=${product.id}&customer_id=$id'));
    final typeResponse = await http
        .get(Uri.parse('${RestDatasource().BASE_URL}/api/get_product_type'));

    if (response.statusCode == 200 && typeResponse.statusCode == 200) {
      print(response.request);
      print(product.id);
      print(id);
      final data = jsonDecode(response.body);
final rawData = data['data'];
final List<dynamic> units = rawData is List
    ? rawData
    : rawData is Map
        ? rawData.values.toList()
        : [];
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

final typeData = jsonDecode(typeResponse.body);
final rawTypeData = typeData['data'];
final List<dynamic> productTypes = rawTypeData is List
    ? rawTypeData
    : rawTypeData is Map
        ? rawTypeData.values.toList()
        : [];

      String? selectedUnitId;
      String? selectedProductTypeId;
      String? quantity;
      String? amount;
      double? availableStock;
      bool priceMatrixExpanded = true;
      Map<String, dynamic>? selectedUnit;
      List<Map<String, double>> rateMatrix = [];
      String? name;
      String? paydata;
      if (productTypes.isNotEmpty) {
        selectedProductTypeId = productTypes[0]['id'].toString();
      }

    final amountController = TextEditingController();
final FocusNode rateFocusNode = FocusNode();
bool rateFocusListenerAdded = false;
if (units.isNotEmpty) {
  selectedUnitId = units[0]['id'].toString();
  selectedUnit = units[0];
  amountController.text = formatRate(selectedUnit?['price']);
  final double _rawStock0 =
      double.tryParse(selectedUnit?['stock']?.toString() ?? '0') ?? 0.0;
  final double _inCart0 = alreadyInCartQtyForUnit(selectedUnitId);
  availableStock = (_rawStock0 - _inCart0) < 0 ? 0 : (_rawStock0 - _inCart0);
  rateMatrix = parseRateMatrix(selectedUnit?['minimum_rate_matrix']);
}
      bool isQuantityValid(String? value) {
        final quantityValue = double.tryParse(value ?? '') ?? 0;
        return value != null &&
                value.isNotEmpty &&
                quantityValue > 0 &&
                AppState().validate_qtySales == 'Yes'
            ? quantityValue <= (availableStock ?? 0)
            : quantityValue > 0;
      }

      bool isAmountValid() {
        final enteredAmount =
            double.tryParse(amountController.text.trim()) ?? 0;
        final fallbackMinPrice = double.tryParse(
                selectedUnit?['min_price']?.toString() ?? '0') ??
            0;
        final enteredQty = double.tryParse(quantity ?? '0') ?? 0;
        final applicableMin = rateMatrix.isNotEmpty
            ? getApplicableRate(rateMatrix, enteredQty, fallbackMinPrice)
            : fallbackMinPrice;
        return applicableMin == 0 || enteredAmount >= applicableMin;
      }

      if (ModalRoute.of(context)!.settings.arguments != null) {
        final Map<String, dynamic>? params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        name = params!['name'];
        id = params!['customerId'];
      }
      void onSerialNumberChanged(int index) async {
        setState(() {
          serialTextControllers[index].clear();
        });
      }

      const Color kPrimary = AppConfig.colorPrimary;
      final Color kPrimarySoft = AppConfig.colorPrimary.withOpacity(0.08);
      const Color kGreen = Color(0xFF1E9E5A);
      final Color kGreenSoft = const Color(0xFF1E9E5A).withOpacity(0.08);
      const Color kBorder = Color(0xFFE7E4F2);
      const Color kTextMuted = Color(0xFF7A7A8C);

      Widget sectionLabel(String text) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          );

     // AFTER: Full width SizedBox + softWrap: false + scaleDown guarantees clean single-line date on all screens.

Widget infoCard({
  required IconData icon,
  required String label,
  required String value,
  double valueFontSize = 10.5, // ✅ Slightly reduced base size for responsive fit
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: kBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: kPrimarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13, color: kPrimary),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9.5, color: kTextMuted),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: double.infinity, // ✅ Stretches to full card width so FittedBox can scale down
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false, // ✅ Guarantees single-line display without wrapping
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.55),
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<bool> checkSerialNumber(String serialNumber) async {
                const String apiUrl =
                    'http://68.183.92.8:3699/api/cash_sale_serial_checking';
                try {
                  final response = await http.post(
                    Uri.parse(apiUrl),
                    body: {
                      'store_id': AppState().storeId.toString(),
                      'product_serial': serialNumber,
                    },
                  );

                  if (response.statusCode != 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid Serial Number')),
                    );
                  }
                  if (response.statusCode == 200) {
                    setDialogState(() {
                      isAvailable = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Serial Number Available')),
                    );
                    final data = json.decode(response.body);

                    if (data.containsKey('is_valid') &&
                        data['is_valid'] == true) {
                      return true;
                    } else {
                      return false;
                    }
                  } else {
                    return false;
                  }
                } catch (e) {
                  print("Error checking serial number: $e");
                  return false;
                }
              }

              if (!rateFocusListenerAdded) {
                rateFocusListenerAdded = true;
                rateFocusNode.addListener(() {
                  if (!rateFocusNode.hasFocus) {
                    setDialogState(() {
                      amountController.text =
                          formatRate(amountController.text);
                    });
                  }
                });
              }

              final double enteredQtyForHeader =
                  double.tryParse(quantity ?? '0') ?? 0;
              final double amt = double.tryParse(amountController.text) ?? 0;
              final double lineAmount = enteredQtyForHeader * amt;
              final double fallbackMinRateForInfo = double.tryParse(
                      selectedUnit?['min_price']?.toString() ?? '0') ??
                  0;
           final double applicableMinRate = getApplicableRate(
  rateMatrix,
  enteredQtyForHeader,
  fallbackMinRateForInfo,
);

// FOC products don't need min-rate enforcement — rate is
// always 0 by design for this product type.
final String? selectedTypeName = productTypes.firstWhere(
  (type) => type['id'].toString() == selectedProductTypeId,
  orElse: () => null,
)?['name']?.toString();
final bool isFOC =
    (selectedTypeName?.toUpperCase() == 'FOC');

Map<String, double>? matchedSlab;
              for (var slab in rateMatrix) {
                if (enteredQtyForHeader >= slab['qty']!) {
                  matchedSlab = slab;
                }
              }

           final bool canSave = isQuantityValid(quantity) &&
    isAvailable &&
    (isFOC || isAmountValid());
              final int? _pgId = pricegroupId is int
                  ? pricegroupId
                  : int.tryParse(pricegroupId?.toString() ?? '');

              final screenSize = MediaQuery.of(context).size;
              final double rawWidth = screenSize.width * 0.92;
              final double dialogWidth =
                  rawWidth > 480 ? 480 : rawWidth;
              final double dialogMaxHeight = screenSize.height * 0.85;
              final double horizontalInset =
                  (screenSize.width - dialogWidth) / 2;

              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                insetPadding: EdgeInsets.symmetric(
                  horizontal: horizontalInset,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: dialogWidth,
                    maxHeight: dialogMaxHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ============= FIXED HEADER =============
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${product.code} | ${product.name!.toUpperCase()}',
                                softWrap: true,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  height: 1.25,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (selectedUnit != null)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kGreenSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.inventory_2_rounded,
                                            size: 11, color: kGreen),
                                        SizedBox(width: 3),
                                        Text(
                                          'Avail. Qty',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            color: kGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                                                      const SizedBox(height: 1),
                                    Text(
                                      '${(availableStock ?? 0) % 1 == 0 ? (availableStock ?? 0).toInt().toString() : (availableStock ?? 0).toString()}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: kGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.close,
                                  size: 20, color: Colors.black45),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: kBorder),

                      // ============= SCROLLABLE BODY =============
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // -------- Last Sale Rate / Unit / Last Sold Date --------
                            // ✅ Card 1 displays 'Last Sale' (rate), Card 2 displays 'Unit', Card 3 displays 'Last Sold' (date).

Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // 1. LAST SALE RATE
    Expanded(
      child: infoCard(
        icon: Icons.sell_outlined,
        label: 'Last Sale',
        value: (lastsale != null && lastsale.isNotEmpty)
            ? formatRate(lastsale['price']) // Displays previous rate (e.g. 9.000)
            : '—',
      ),
    ),
    const SizedBox(width: 6),

    // 2. UNIT
    Expanded(
      child: infoCard(
        icon: Icons.inventory_2_outlined,
        label: 'Unit',
        value: selectedUnit?['name']?.toString() ?? '—',
      ),
    ),
    const SizedBox(width: 6),

    // 3. LAST SOLD DATE
    Expanded(
      child: infoCard(
        icon: Icons.calendar_today_outlined,
        label: 'Last Sold',
        value: (lastsale != null && lastsale.isNotEmpty)
            ? DateHelper.displayDate(lastsale['date']) // Displays previous date (e.g. 06-Aug-2026)
            : '—',
        valueFontSize: 10.5,
      ),
    ),
  ],
),
                              if (lastsale == null || lastsale.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    'No last sale record',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: kTextMuted,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),

                              const SizedBox(height: 10),

                              // -------- PRICE MATRIX --------
                              if (selectedUnit != null &&
                                  rateMatrix.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: BoxDecoration(
                                              color: kPrimarySoft,
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                            ),
                                            child: const Icon(
                                              Icons.bar_chart_rounded,
                                              size: 14,
                                              color: kPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              onTap: () {
                                                setDialogState(() {
                                                  priceMatrixExpanded =
                                                      !priceMatrixExpanded;
                                                });
                                              },
                                              child: const Padding(
                                                padding:
                                                    EdgeInsets.symmetric(
                                                        vertical: 4),
                                                child: Text(
                                                  'PRICE MATRIX',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: kPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              setDialogState(() {
                                                priceMatrixExpanded =
                                                    !priceMatrixExpanded;
                                              });
                                            },
                                            icon: Icon(
                                              priceMatrixExpanded
                                                  ? Icons
                                                      .keyboard_arrow_up_rounded
                                                  : Icons
                                                      .keyboard_arrow_down_rounded,
                                              color: kPrimary,
                                              size: 24,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            splashRadius: 18,
                                          ),
                                        ],
                                      ),
                                      if (priceMatrixExpanded) ...[
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Rate will be applied based on the quantity.',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: kTextMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 7),

                                        Column(
                                          children: [
                                            // ---- HEADER ----
                                         // AFTER: Balanced flex (3:2:3:3), zero awkward gap, perfect right alignment.

Container(
  padding: const EdgeInsets.symmetric(
    vertical: 7,
    horizontal: 8, // ✅ Standardized padding matching data rows
  ),
  decoration: BoxDecoration(
    color: kPrimarySoft,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(8),
      topRight: Radius.circular(8),
    ),
  ),
  child: Row(
    children: [
      // Unit -> LEFT aligned
      Expanded(
        flex: 3,
        child: Text(
          'Unit',
          textAlign: TextAlign.left,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10.5,
            color: kPrimary,
          ),
        ),
      ),
      // Qty -> RIGHT aligned
      Expanded(
        flex: 2, // ✅ Balanced compact flex
        child: Text(
          'Qty',
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10.5,
            color: kPrimary,
          ),
        ),
      ),
      // Rate -> RIGHT aligned
      Expanded(
        flex: 3,
        child: Text(
          'Rate',
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10.5,
            color: kPrimary,
          ),
        ),
      ),
      // Min Rate -> RIGHT aligned
      Expanded(
        flex: 3, // ✅ Changed from 5 to 3 to eliminate empty space
        child: Text(
          'Min Rate',
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10.5,
            color: kPrimary,
          ),
        ),
      ),
    ],
  ),
),
                                            // ---- ROWS ----
                                           // AFTER: Right aligned Qty, Rate, and Min Rate with matching flex (3:2:3:3) and horizontal padding (8)

...rateMatrix.asMap().entries.map((entry) {
  final index = entry.key;
  final slab = entry.value;
  final enteredQty = double.tryParse(quantity ?? '0') ?? 0;
  final currentQty = slab['qty'] ?? 0;
  final nextQty = index < rateMatrix.length - 1 ? rateMatrix[index + 1]['qty'] : null;
  final isApplicable = enteredQty >= currentQty && (nextQty == null || enteredQty < nextQty);
  final unitName = selectedUnit?['name']?.toString() ?? '';
  final minRate = slab['rate'] ?? 0;

  return Container(
    padding: const EdgeInsets.symmetric(
      vertical: 8,
      horizontal: 8, // ✅ Matches header padding
    ),
    decoration: BoxDecoration(
      color: isApplicable ? kPrimarySoft : Colors.white,
      border: Border(
        left: BorderSide(color: kBorder),
        right: BorderSide(color: kBorder),
        bottom: BorderSide(color: kBorder),
      ),
    ),
    child: Row(
      children: [
        // Unit -> LEFT aligned
        Expanded(
          flex: 3,
          child: Text(
            unitName,
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontWeight: isApplicable ? FontWeight.bold : FontWeight.normal,
              fontSize: 11.5,
            ),
          ),
        ),
        // Qty -> RIGHT aligned
        Expanded(
          flex: 2, // ✅ Flex 2 matches header
          child: Text(
            currentQty.toStringAsFixed(0),
            textAlign: TextAlign.right, // ✅ Explicit Right alignment
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontWeight: isApplicable ? FontWeight.bold : FontWeight.normal,
              fontSize: 11.5,
            ),
          ),
        ),
        // Rate -> RIGHT aligned
        Expanded(
          flex: 3, // ✅ Flex 3 matches header
          child: Text(
            (slab['rate'] ?? 0).toStringAsFixed(2),
            textAlign: TextAlign.right, // ✅ Explicit Right alignment
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontWeight: isApplicable ? FontWeight.bold : FontWeight.normal,
              fontSize: 11.5,
            ),
          ),
        ),
        // Min Rate -> RIGHT aligned
        Expanded(
          flex: 3, // ✅ Flex 3 matches header
          child: minRate > 0
              ? Text(
                  minRate.toStringAsFixed(2),
                  textAlign: TextAlign.right, // ✅ Explicit Right alignment
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: isApplicable ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11.5,
                  ),
                )
              : Text(
                  'No limit',
                  textAlign: TextAlign.right, // ✅ Explicit Right alignment
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: kTextMuted,
                    fontSize: 10.5,
                  ),
                ),
        ),
      ],
    ),
  );
}).toList(),

                                            // ---- INFO MESSAGE ----
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 7,
                                                horizontal: 7,
                                              ),
                                              decoration: BoxDecoration(
                                                color: kPrimarySoft,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(8),
                                                  bottomRight:
                                                      Radius.circular(8),
                                                ),
                                              ),
                                              child: Row(
                                                children: const [
                                                  Icon(
                                                    Icons
                                                        .info_outline_rounded,
                                                    size: 13,
                                                    color: kPrimary,
                                                  ),
                                                  SizedBox(width: 5),
                                                  Expanded(
                                                    child: Text(
                                                      'Highlighted row shows the pricing level applicable for the entered quantity.',
                                                      softWrap: true,
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        color: kPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ] else if (selectedUnit != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: Colors.red.shade100),
                                  ),
                                  child: Text(
                                    "Minimum Rate : ${selectedUnit?['min_price'] ?? '0'}",
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],

                              // -------- Product Type + Unit --------
                          if (units.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          sectionLabel('Product Type'),
                                          _buildDropdown<String>(
                                            value: selectedProductTypeId,
                                            hint: 'Select Product Type',
                                            items: productTypes.map(
                                              (type) {
                                                return DropdownMenuItem<String>(
                                                  value: type['id'].toString(),
                                                  child: Text(type['name']),
                                                );
                                              },
                                            ).toList(),
                                            onChanged: (value) {
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
                                                  amountController.text =
                                                      formatRate(0);
                                                } else if (selectedUnit !=
                                                    null) {
                                                  amountController.text =
                                                      formatRate(
                                                          selectedUnit?[
                                                              'price']);
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          sectionLabel('Unit'),
                                          _buildDropdown<String>(
                                            value: selectedUnitId,
                                            hint: 'Select Unit',
                                            items: units
                                                .where((unit) => unit != null)
                                                .map((unit) {
                                              return DropdownMenuItem<String>(
                                                value: unit['id'].toString(),
                                                child: Text(unit['name']),
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
                                                    formatRate(
                                                        selectedUnit?[
                                                            'price']);
                                                final double _rawStock =
                                                    double.tryParse(
                                                  selectedUnit?['stock']
                                                          ?.toString() ??
                                                      '0',
                                                ) ?? 0.0;
                                                final double _inCart =
                                                    alreadyInCartQtyForUnit(
                                                        selectedUnitId);
                                                availableStock =
                                                    (_rawStock - _inCart) < 0
                                                        ? 0
                                                        : (_rawStock - _inCart);
                                                rateMatrix = parseRateMatrix(
                                                  selectedUnit?[
                                                      'minimum_rate_matrix'],
                                                );
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // -------- Quantity + Rate --------
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                    sectionLabel('Quantity *'),
                                          _buildTextField(
                                            initialValue: quantity,
                                            keyboardType: TextInputType.number,
                                            icon: Icons.swap_vert_rounded,
                                            textAlign: TextAlign.right,
                                            onChanged: (value) {
                                              quantity = value;
                                              setDialogState(() {
                                                int qty =
                                                    int.tryParse(value) ?? 0;
                                                serialTextControllers =
                                                    List.generate(
                                                  qty,
                                                  (index) =>
                                                      TextEditingController(),
                                                );
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          sectionLabel('Rate *'),
                                        _buildTextField(
  controller: amountController,
  keyboardType: const TextInputType.numberWithOptions(
    decimal: true,
  ),
  readOnly: false,
  focusNode: rateFocusNode,
  suffixIcon: Icons.edit_outlined,
  textAlign: TextAlign.right,
  inputFormatters: [                                   // ✅ added
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'^\d*\.?\d{0,3}'),
                                              ),
                                            ],
                                            onChanged: (_) {
                                              setDialogState(() {});
                                            },
                                            onFieldSubmitted: (_) {
                                              setDialogState(() {
                                                amountController.text =
                                                    formatRate(
                                                        amountController.text);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                             if (selectedUnit != null && !isFOC)
  Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      'Minimum allowed rate: '
      '${applicableMinRate.toStringAsFixed(3)}',
      style: TextStyle(
        color: amt < applicableMinRate
            ? Colors.red
            : kGreen,
        fontWeight: FontWeight.w600,
        fontSize: 11.5,
      ),
    ),
  ),

if (!isFOC &&
    amountController.text.isNotEmpty &&
    amt < applicableMinRate)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      'Amount cannot be less than Minimum Rate '
                                      '(${applicableMinRate.toStringAsFixed(3)})',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 10),

                                // -------- Amount --------
                                sectionLabel('Amount'),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calculate_outlined,
                                          size: 16, color: kTextMuted),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          lineAmount.toStringAsFixed(
                                              AppState().noOfDecimals ?? 2),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: kPrimarySoft,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Calculated',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: kPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // -------- Price Source --------
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: kGreenSoft,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: kGreen.withOpacity(0.25)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          size: 16, color: kGreen),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rateMatrix.isNotEmpty &&
                                                      matchedSlab != null
                                                  ? 'Price Source: Qty ${quantity ?? 0} matched Price Matrix Level (Min Qty ${matchedSlab['qty']!.toStringAsFixed(0)})'
                                                  : 'Price Source: Standard Unit Price',
                                              softWrap: true,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: kGreen,
                                              ),
                                            ),
                                            if (rateMatrix.isNotEmpty &&
                                                matchedSlab != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'Rate: ${matchedSlab['rate']!.toStringAsFixed(2)}  |  Min Allowed Rate: ${applicableMinRate.toStringAsFixed(2)}',
                                                softWrap: true,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: kGreen,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (product.serialbarcode_required ==
                                    'YES') ...[
                                  const SizedBox(height: 10),
                                  sectionLabel('Serial Numbers'),
                                  ...serialTextControllers
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    int i = entry.key;
                                    TextEditingController controller =
                                        entry.value;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: _buildTextField(
                                        controller: controller,
                                        hintText: 'Serial No: ${i + 1}',
                                        icon:
                                            Icons.confirmation_number_outlined,
                                        onChanged: (value) {
                                          setDialogState(() {
                                            isAvailable = false;
                                          });
                                        },
                                        onFieldSubmitted: (value) async {
                                          await checkSerialNumber(value);
                                          if (!isAvailable) {
                                            onSerialNumberChanged(i);
                                          }
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ] else ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                      'No units available for this product.',
                                      style: TextStyle(fontSize: 12.5)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const Divider(height: 1, color: kBorder),

                      // ============= FIXED FOOTER: Cancel / Save =============
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                      color: kPrimary, width: 1.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 11),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      color: kPrimary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                           if (units.isNotEmpty) ...[
  const SizedBox(width: 10),
  Expanded(
    child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        canSave ? kPrimary : Colors.grey,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 11),
                                    elevation: 0,
                                  ),
                                                                   onPressed: canSave
                                      ? () async {
                                          final prefs = await SharedPreferences
                                              .getInstance();
                                          List<String>? selectedProducts =
                                              prefs.getStringList(
                                                  'selected_products');
                                          selectedProducts ??= [];

                                          // ---- Duplicate check (Safest Version) ----
                                          bool alreadyExists = false;
                                          try {
                                            alreadyExists =
                                                selectedProducts.any((item) {
                                              final decoded =
                                                  jsonDecode(item);
                                              return decoded['id']
                                                          .toString() ==
                                                      product.id.toString() &&
                                                  decoded['unit_id']
                                                          .toString() ==
                                                      selectedUnitId
                                                          .toString();
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

                                          final serialNumber = DateTime.now()
                                                  .millisecondsSinceEpoch
                                                  .toString() +
                                              '-' +
                                              (1000 +
                                                      (DateTime.now()
                                                              .microsecond %
                                                          9000))
                                                  .toString();
                                          List<String> serialNumbers =
                                              serialTextControllers
                                                  .map((controller) =>
                                                      controller.text)
                                                  .where(
                                                      (text) => text.isNotEmpty)
                                                  .toList();
                                          final selectedProduct = {
                                            'serial_number': serialNumber,
                                            'id': product.id,
                                            'code': product.code,
                                            'name': product.name,
                                            'pro_image': product.proImage,
                                            'type_id': selectedProductTypeId,
                                            'type_name': productTypes
                                                    .firstWhere((type) =>
                                                        type['id'].toString() ==
                                                        selectedProductTypeId)[
                                                'name'],
                                            'unit_id': selectedUnitId,
                                            'unit_name': selectedUnit?['name'],
                                            'quantity': quantity ?? '',
                                            'amount':
                                                amountController.text ?? '',
                                            'min_price':
                                                selectedUnit?['min_price']
                                                        ?.toString() ??
                                                    '0',
                                            'minimum_rate_matrix': selectedUnit?[
                                                        'minimum_rate_matrix']
                                                    ?.toString() ??
                                                '',
                                            'serial_numbers': serialNumbers,
                                            'tax_percentage':
                                                product.taxPercentage ?? 0,
                                          };
                                          selectedProducts
                                              .add(jsonEncode(selectedProduct));
                                          await prefs.setStringList(
                                              'selected_products',
                                              selectedProducts);
                                          Navigator.pop(context);
                                          Navigator.pushReplacementNamed(
                                              context, SalesScreen.routeName,
                                              arguments: {
                                                'name': name,
                                                'customerId': id,
                                              });
                                        }
                                      : null,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.save_outlined,
                                          color: Colors.white, size: 16),
                                      SizedBox(width: 5),
                                      Text(
                                        'Save',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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

  // ---- Price Matrix helpers ----
  List<Map<String, double>> parseRateMatrix(dynamic matrixValue) {
    if (matrixValue == null) return [];
    String matrixStr = matrixValue.toString().trim();
    if (matrixStr.isEmpty) return [];
    List<Map<String, double>> slabs = [];

    final separator = matrixStr.contains('|') ? '|' : ',';

    for (var pair in matrixStr.split(separator)) {
      final parts = pair.trim().split(':');
      if (parts.length == 2) {
        final qty = double.tryParse(parts[0].trim());
        final rate = double.tryParse(parts[1].trim());
        if (qty != null && rate != null) {
          slabs.add({'qty': qty, 'rate': rate});
        }
      }
    }
    slabs.sort((a, b) => a['qty']!.compareTo(b['qty']!));
    return slabs;
  }

  String formatRate(dynamic value) {
    if (value == null) return '0.000';

    final number = double.tryParse(value.toString()) ?? 0.0;
    return number.toStringAsFixed(3);
  }

  double getApplicableRate(
    List<Map<String, double>> slabs,
    double enteredQty,
    double fallbackMinPrice,
  ) {
    if (slabs.isEmpty) return fallbackMinPrice;

    double applicable = slabs.first['rate']!;

    for (var slab in slabs) {
      if (enteredQty >= slab['qty']!) {
        applicable = slab['rate']!;
      } else {
        break;
      }
    }

    return applicable;
  }

  // ---- small reusable UI builders for the dialog ----
  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    const Color kBorder = Color(0xFFE7E4F2);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: kBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<T>(
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 9),
          ),
          items: items,
          onChanged: onChanged,
          value: value,
          hint: Text(hint,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis),
          isExpanded: true,
          style: const TextStyle(fontSize: 12.5, color: Colors.black87),
        ),
      ),
    );
  }

 Widget _buildTextField({
  TextEditingController? controller,
  String? initialValue,
  String? hintText,
  TextInputType? keyboardType,
  bool readOnly = false,
  IconData? icon,
  IconData? suffixIcon,
  FocusNode? focusNode,
  List<TextInputFormatter>? inputFormatters,   // ✅ added
  TextAlign textAlign = TextAlign.left,        // ✅ added
  required void Function(String) onChanged,
  void Function(String)? onFieldSubmitted,
}) {
  const Color kBorder = Color(0xFFE7E4F2);
  const Color kPrimary = AppConfig.colorPrimary;
  return TextFormField(
    controller: controller,
    initialValue: controller == null ? initialValue : null,
    keyboardType: keyboardType,
    readOnly: readOnly,
    focusNode: focusNode,
    inputFormatters: inputFormatters,           // ✅ added
    textAlign: textAlign,                       // ✅ added
    onChanged: onChanged,
    onFieldSubmitted: onFieldSubmitted,
    
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 12),
        prefixIcon:
            icon != null ? Icon(icon, size: 16, color: Colors.black45) : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 0),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: 15, color: kPrimary)
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 0),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF4F3FA) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: kPrimary, width: 1.3),
        ),
      ),
    );
  }
}