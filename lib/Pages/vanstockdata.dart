import 'dart:convert';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;
import 'package:mobizapp/Utilities/cpcl_helper.dart';
import '../Utilities/report_printer.dart';
import '../Reports/van_stock_report.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import '../Models/Store_model.dart';
import '../Models/appstate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../Pages/vanstockdata.dart' as Invoice;
import '../Models/vanstockquandity.dart' as Qty;
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import '../Components/commonwidgets.dart';
import '../Models/VanStockDataModel.dart';

class VanStockScreen extends StatefulWidget {
  static const routeName = "/VanStockScreen";
  const VanStockScreen({super.key});

  @override
  State<VanStockScreen> createState() => _VanStockScreenState();
}

class _VanStockScreenState extends State<VanStockScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchData = TextEditingController();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Product12> _products1 = [];
  List<Product12> _filteredProducts1 = [];
  String productUnit = '';
  String productQty = '';
  late TabController _tabController;
  Qty.VanStockQuandity qunatityData = Qty.VanStockQuandity();

  bool _search = false;

  final ScrollController _scrollControllerProducts = ScrollController();
  // final ScrollController _scrollControllerReturns = ScrollController();

  int _currentPageProducts = 1;
  bool _isLoadingProducts = false;
  bool _hasMoreProducts = true;

  int _currentPageReturns = 1;
  bool _isLoadingReturns = false;
  bool _hasMoreReturns = true;
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchReturns();
    _initPrinter();
    _scrollControllerProducts.addListener(() {
      if (_scrollControllerProducts.position.pixels ==
              _scrollControllerProducts.position.maxScrollExtent &&
          _hasMoreProducts &&
          !_isLoadingProducts) {
        _fetchProducts();
      }
    });

    // _scrollControllerReturns.addListener(() {
    //   if (_scrollControllerReturns.position.pixels ==
    //           _scrollControllerReturns.position.maxScrollExtent &&
    //       _hasMoreReturns &&
    //       !_isLoadingReturns) {
    //     _fetchReturns();
    //   }
    // });

    _tabController = TabController(length: 2, vsync: this);
    _searchData.addListener(() {
      _searchProducts(_searchData.text);
    });
  }

  void _initPrinter() async {
    await loadPrinterTypeCache();
    bool? isConnected = await printer.isConnected;
    if (isConnected!) {
      setState(() {
        _connected = true;
      });
    }
    _getBluetoothDevices();
  }

  Future<void> _getBluetoothDevices() async {
    List<BluetoothDevice> devices = await printer.getBondedDevices();
    BluetoothDevice? defaultDevice;
    final prefs = await SharedPreferences.getInstance();
    final savedDeviceAddress = prefs.getString('selected_device_address');
    for (BluetoothDevice device in devices) {
      if (device.address == savedDeviceAddress) {
        defaultDevice = device;
        break;
      }
    }
    setState(() {
      _devices = devices;
      _selectedDevice = defaultDevice;
    });
  }

  Future<void> _connect() async {
    if (_selectedDevice != null) {
      await printer.connect(_selectedDevice!);
      setState(() {
        _connected = true;
      });
    }
  }

  // Future<void> _fetchProducts() async {
  //   setState(() {
  //     _isLoadingProducts = true;
  //   });
  //
  //   try {
  //     // Fetch all products in one call
  //     final productData = await _getProducts();
  //
  //     // Filter products with non-zero stock
  //     final filteredProducts = productData.data
  //         .where((product) =>
  //     product.units.isNotEmpty && product.units[0].stock > 0)
  //         .toList();
  //
  //     // Set the products once
  //     setState(() {
  //       _products = filteredProducts;
  //       _filteredProducts = List.from(_products); // Update filtered products list
  //     });
  //   } catch (e) {
  //     print('Error: $e');
  //   } finally {
  //     setState(() {
  //       _isLoadingProducts = false;
  //     });
  //   }
  // }
  //
  //
  // Future<void> _fetchReturns() async {
  //   setState(() {
  //     _isLoadingReturns = true;
  //   });
  //
  //   try {
  //     final productData = await _getReturns();
  //     final filteredProducts1 = productData.products
  //         .where((product) =>
  //     product.units.isNotEmpty && product.units[0].stock > 0)
  //         .toList();
  //     setState(() {
  //       _products1=filteredProducts1;
  //       _filteredProducts1= List.from(_products1);
  //     });
  //   } catch (e) {
  //     print('Error: $e');
  //   } finally {
  //     setState(() {
  //       _isLoadingReturns = false;
  //     });
  //   }
  // }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final productData = await _getProducts();
      final filteredProducts = productData.data
          .map((product) {
            final filteredUnits =
                product.units.where((unit) => unit.stock > 0).toList();

            return filteredUnits.isNotEmpty
                ? product.copyWith(units: filteredUnits)
                : null;
          })
          .where((product) => product != null)
          .toList();

      setState(() {
        _products =
            filteredProducts.cast<Product>(); // Cast to the correct type
        _filteredProducts =
            List.from(_products);
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _fetchReturns() async {
    setState(() {
      _isLoadingReturns = true;
    });

    try {
      final productData = await _getReturns();
      final filteredProducts1 = productData.products
          .where((product) => product.units.any((unit) => unit.stock > 0))
          .toList();
      setState(() {
        _products1 = filteredProducts1;
        _filteredProducts1 = List.from(_products1);
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isLoadingReturns = false;
      });
    }
  }

  Future<void> _searchProducts(String query) async {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products
            .where((product) =>
                product.units.isNotEmpty && product.units[0].stock > 0)
            .toList();
      } else {
        _filteredProducts = _products
            .where((product) =>
                (product.name!.toLowerCase().contains(query.toLowerCase()) ||
                    product.code!
                        .toLowerCase()
                        .contains(query.toLowerCase())) &&
                product.units.isNotEmpty &&
                product.units[0].stock > 0)
            .toList();
      }
      if (query.isEmpty) {
        _filteredProducts1 = List.from(_products1);
      } else {
        _filteredProducts1 = _products1
            .where((product) =>
                product.name!.toLowerCase().contains(query.toLowerCase()) ||
                product.code!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollControllerProducts.dispose();
    // _scrollControllerReturns.dispose();
    _searchData.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
          title: const Text(
            'Van Stocks',
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
        // floatingActionButton: FloatingActionButton(backgroundColor: AppConfig.colorPrimary,onPressed: () {},child: Icon(Icons.print,color: Colors.white,),),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            children: [
              TabBar(
                labelStyle: TextStyle(
                    color: AppConfig.backgroundColor,
                    fontWeight: FontWeight.bold),
                padding: EdgeInsets.all(8),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(10),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppConfig.colorPrimary,
                ),
                controller: _tabController,
                tabs: [
                  Tab(text: 'Stock'),
                  Tab(text: 'Return'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Stack(
                      children: [
                        Container(
                          child: Column(
                            children: [
                              _isLoadingProducts
                                  ? Shimmer.fromColors(
                                      baseColor: AppConfig.buttonDeactiveColor
                                          .withOpacity(0.1),
                                      highlightColor: AppConfig.backButtonColor,
                                      child: Center(
                                        child: Column(
                                          children: [
                                            CommonWidgets.loadingContainers(
                                                height: SizeConfig
                                                        .blockSizeVertical *
                                                    10,
                                                width: SizeConfig
                                                        .blockSizeHorizontal *
                                                    90),
                                            CommonWidgets.loadingContainers(
                                                height: SizeConfig
                                                        .blockSizeVertical *
                                                    10,
                                                width: SizeConfig
                                                        .blockSizeHorizontal *
                                                    90),
                                            CommonWidgets.loadingContainers(
                                                height: SizeConfig
                                                        .blockSizeVertical *
                                                    10,
                                                width: SizeConfig
                                                        .blockSizeHorizontal *
                                                    90),
                                          ],
                                        ),
                                      ),
                                    )
                                  : _products.isEmpty
                                      ? Center(
                                          child: Text('No products found'),
                                        )
                                      : Expanded(
                                          child: ListView.builder(
                                            itemCount: _filteredProducts.length,
                                            itemBuilder: (context, index) {
                                              if (index ==
                                                  _filteredProducts.length) {
                                                return SizedBox.shrink();
                                              }
                                              final product =
                                                  _filteredProducts[index];
                                              return Card(
                                                elevation: 3,
                                                child: Container(
                                                  width: SizeConfig
                                                          .blockSizeHorizontal *
                                                      90,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color:
                                                            Colors.transparent),
                                                    color: AppConfig
                                                        .backgroundColor,
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                      Radius.circular(10),
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 50,
                                                          height: 50,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        15.0),
                                                            child: FadeInImage(
                                                              image: NetworkImage(
                                                                  '${RestDatasource().Product_URL}/uploads/product/${product.proImage}'),
                                                              placeholder:
                                                                  const AssetImage(
                                                                      'Assets/Images/no_image.jpg'),
                                                              imageErrorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Image.asset(
                                                                    'Assets/Images/no_image.jpg',
                                                                    fit: BoxFit
                                                                        .fitWidth);
                                                              },
                                                              fit: BoxFit
                                                                  .fitWidth,
                                                            ),
                                                          ),
                                                        ),
                                                        CommonWidgets
                                                            .horizontalSpace(3),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Tooltip(
                                                              message: product
                                                                  .name!
                                                                  .toUpperCase(),
                                                              child: SizedBox(
                                                                width: SizeConfig
                                                                        .blockSizeHorizontal *
                                                                    70,
                                                                child: Text(
  '${product.code} | ${product.name!.toUpperCase()}',
  style: TextStyle(fontSize: AppConfig.textCaption2Size.sp),
),
                                                              ),
                                                            ),
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  product.units !=
                                                                              null &&
                                                                          product.units.length >
                                                                              0
                                                                      ? '${product.units[0].name}:${product.units[0].stock}'
                                                                      : '',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        AppConfig
                                                                            .textCaption3Size,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width: 10),
                                                                Text(
                                                                  product.units !=
                                                                              null &&
                                                                          product.units.length >
                                                                              1
                                                                      ? '${product.units[1].name}:${product.units[1].stock}'
                                                                      : '',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        AppConfig
                                                                            .textCaption3Size,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width: 10),
                                                                Text(
                                                                  product.units !=
                                                                      null &&
                                                                      product.units.length >
                                                                          2
                                                                      ? '${product.units[2].name}:${product.units[2].stock}'
                                                                      : '',
                                                                  style:
                                                                  TextStyle(
                                                                    fontSize:
                                                                    AppConfig
                                                                        .textCaption3Size,
                                                                  ),
                                                                )
                                                              ],
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
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 16.0,
                          right: 16.0,
                          child: FloatingActionButton(
                            backgroundColor: AppConfig.colorPrimary,
                            onPressed: () => _printStock(),
                            child: Icon(
                              Icons.print,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        Container(
                          child: Column(
                            children: [
                              _isLoadingReturns
                                  ? Shimmer.fromColors(
                                      baseColor: AppConfig.buttonDeactiveColor
                                          .withOpacity(0.1),
                                      highlightColor: AppConfig.backButtonColor,
                                      child: Center(
                                        child: Column(
                                          children: [
                                            CommonWidgets.loadingContainers(
                                                height: SizeConfig
                                                        .blockSizeVertical *
                                                    10,
                                                width: SizeConfig
                                                        .blockSizeHorizontal *
                                                    90),
                                            CommonWidgets.loadingContainers(
                                                height: SizeConfig
                                                        .blockSizeVertical *
                                                    10,
                                                width: SizeConfig
                                                        .blockSizeHorizontal *
                                                    90),
                                            CommonWidgets.loadingContainers(
                                                height: SizeConfig
                                                        .blockSizeVertical *
                                                    10,
                                                width: SizeConfig
                                                        .blockSizeHorizontal *
                                                    90),
                                          ],
                                        ),
                                      ),
                                    )
                                  : _filteredProducts1.isEmpty
                                      ? Center(
                                          child: Text(_products1.isEmpty
                                              ? 'No products found'
                                              : 'No stock found'),
                                        )
                                      : Expanded(
                                          child: ListView.builder(
                                            scrollDirection: Axis.vertical,
                                            itemCount:
                                                _filteredProducts1.length,
                                            itemBuilder: (context, index) {
                                              if (index ==
                                                  _filteredProducts1.length) {
                                                return SizedBox.shrink();
                                              }
                                              final product =
                                                  _filteredProducts1[index];
                                              return Card(
                                                elevation: 3,
                                                child: Container(
                                                  width: SizeConfig
                                                          .blockSizeHorizontal *
                                                      90,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: Colors.transparent,
                                                    ),
                                                    color: AppConfig
                                                        .backgroundColor,
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                      Radius.circular(10),
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 50,
                                                          height: 50,
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        15.0),
                                                            child: FadeInImage(
                                                              image: NetworkImage(
                                                                  '${RestDatasource().Product_URL}/uploads/product/${product.proImage}'),
                                                              placeholder:
                                                                  const AssetImage(
                                                                      'Assets/Images/no_image.jpg'),
                                                              imageErrorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Image.asset(
                                                                    'Assets/Images/no_image.jpg',
                                                                    fit: BoxFit
                                                                        .fitWidth);
                                                              },
                                                              fit: BoxFit
                                                                  .fitWidth,
                                                            ),
                                                          ),
                                                        ),
                                                        CommonWidgets
                                                            .horizontalSpace(3),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Tooltip(
                                                              message: product
                                                                  .name
                                                                  .toUpperCase(),
                                                              child: SizedBox(
                                                                width: SizeConfig
                                                                        .blockSizeHorizontal *
                                                                    70,
                                                                child: Text(
                                                                  '${product.code} | ${product.name.toUpperCase()}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          AppConfig
                                                                              .textCaption2Size),
                                                                ),
                                                              ),
                                                            ),
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  product.units
                                                                          .isNotEmpty
                                                                      ? '${product.units[0].name}:${product.units[0].stock}'
                                                                      : '',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        AppConfig
                                                                            .textCaption3Size,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width: 10),
                                                                Text(
                                                                  product.units
                                                                              .length >
                                                                          1
                                                                      ? '${product.units[1].name}:${product.units[1].stock}'
                                                                      : '',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        AppConfig
                                                                            .textCaption3Size,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
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
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 16.0,
                          right: 16.0,
                          child: FloatingActionButton(
                            backgroundColor: AppConfig.colorPrimary,
                            onPressed: () => _printReturn(),
                            child: Icon(
                              Icons.print,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ));
  }
Future<void> _printVanStockAsImage({
  required String title,
  required List<VanStockPrintProduct> products,
}) async {
  final response = await http.get(Uri.parse(
    '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}',
  ));

  if (response.statusCode != 200) {
    throw Exception('Failed to load store details');
  }

  final storeDetail = StoreDetail.fromJson(json.decode(response.body));
  final logoName = storeDetail.logos;
  final logo = logoName != null && logoName.isNotEmpty
      ? await loadLogo('https://erpadmin.mobiz.ae/uploads/store/$logoName')
      : null;

  await printReport(
    printer,
    _selectedDevice,
    (builder) => drawVanStockReport(
      builder,
      companyName: '${storeDetail.name}',
      title: title,
      products: products,
      logo: logo,
    ),
    widthDots: kLabelWidthDots,
  );
}

Future<void> _printImageVanStock() async {
  final seenProducts = <String>{};
  final products = <VanStockPrintProduct>[];

  for (final product in _filteredProducts) {
    if (product.code.isEmpty || !seenProducts.add(product.code)) continue;

    final seenUnits = <String>{};
    final units = <VanStockPrintUnit>[];
    for (final unit in product.units) {
      final key = '${unit.name}-${unit.stock}';
      if (seenUnits.add(key)) {
        units.add(VanStockPrintUnit(
          name: unit.name,
          quantity: unit.stock.toString(),
        ));
      }
    }

    products.add(VanStockPrintProduct(
      name: product.name,
      code: product.code,
      units: units,
    ));
  }

  await _printVanStockAsImage(title: 'Van Stock', products: products);
}

Future<void> _printImageVanReturn() async {
  final products = _filteredProducts1.map((product) {
    return VanStockPrintProduct(
      name: product.name.toUpperCase(),
      code: product.code,
      units: product.units
          .map((unit) => VanStockPrintUnit(
                name: unit.name,
                quantity: unit.stock.toString(),
              ))
          .toList(),
    );
  }).toList();

  await _printVanStockAsImage(title: 'Van Return', products: products);
}
  // Future<void> _printReturn() async {
  //   if (_connected) {
  //     // Print the top separator line
  //     final response = await http.get(Uri.parse(
  //         '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
  //     if (response.statusCode == 200) {
  //       // Parse JSON response into StoreDetail object
  //       StoreDetail storeDetail =
  //           StoreDetail.fromJson(json.decode(response.body));
  //       final String api =
  //           '${RestDatasource().Image_URL}/uploads/store/${storeDetail.logos}';
  //       final logoResponse = await http.get(Uri.parse(api));
  //       if (logoResponse.statusCode != 200) {
  //         throw Exception('Failed to load logo image');
  //       }
  //       String logoUrl =
  //           'http://erpadmin.mobiz.ae/uploads/store/${storeDetail.logos}';
  //       if (logoUrl.isNotEmpty) {
  //         final response = await http.get(Uri.parse(logoUrl));
  //         if (response.statusCode == 200) {
  //           Uint8List imageBytes = response.bodyBytes;

  //           // Decode image and convert to monochrome bitmap if needed
  //           img.Image originalImage = img.decodeImage(imageBytes)!;
  //           img.Image monoLogo = img.grayscale(originalImage);

  //           // Encode the image to the required format (e.g., PNG)
  //           Uint8List logoBytes = Uint8List.fromList(img.encodePng(monoLogo));

  //           // Print the logo image
  //           printer.printImageBytes(logoBytes);
  //         } else {
  //           print('Failed to load image: ${response.statusCode}');
  //         }
  //       }
  //       printer.printNewLine();
  //       String companyName = '${storeDetail.name}';
  //       printer.printCustom(companyName, 3, 1);
  //       printer.printNewLine();
  //       printer.printCustom("Van Return", 3, 1);
  //       printer.printNewLine();
  //       printer.printCustom("-" * 70, 1, 1); // Centered

  //       // Define column widths for table
  //       const int columnWidth1 = 5; // S.No
  //       const int columnWidth2 = 30; // Product Description
  //       const int columnWidth3 = 13; // Code
  //       const int columnWidth4 = 10; // Unit
  //       const int columnWidth5 = 10; // Qty

  //       // Print table headers
  //       String headers = "${'S.No'.padRight(columnWidth1)}"
  //           " ${'Product'.padRight(columnWidth2)}"
  //           " ${'Code'.padRight(columnWidth3)}"
  //           " ${'Unit'.padRight(columnWidth4)}"
  //           "${'Qty'.padRight(columnWidth5)}";
  //       printer.printCustom(headers, 1, 0); // Left aligned

  //       // Function to split text into lines of a given width
  //       List<String> splitText(String text, int width) {
  //         List<String> lines = [];
  //         while (text.length > width) {
  //           lines.add(text.substring(0, width));
  //           text = text.substring(width);
  //         }
  //         lines.add(text);
  //         return lines;
  //       }

  //       printer.printNewLine();

  //       int serialNumber = 1; // Initialize serial number counter

  //       for (int i = 0; i < _filteredProducts1.length; i++) {
  //         var product = _filteredProducts1[i];
  //         String productName = "${product.name!.toUpperCase()}";
  //         String productCode = "${product.code}";

  //         // Check if there are units available
  //         if (product.units.isNotEmpty) {
  //           for (var unit in product.units) {
  //             String productUnit = "${unit.name}"; // Access the unit name
  //             String productQty = "${unit.stock}"; // Access the unit stock

  //             List<String> descriptionLines =
  //                 splitText(productName, columnWidth2);

  //             for (int j = 0; j < descriptionLines.length; j++) {
  //               String line;
  //               if (j == 0) {
  //                 // For the first line, include all columns
  //                 line = "${serialNumber.toString().padRight(columnWidth1)}"
  //                     "${descriptionLines[j].padRight(columnWidth2)}"
  //                     "  ${productCode.padRight(columnWidth3)}"
  //                     "${productUnit.padRight(columnWidth4)}"
  //                     "${productQty.padRight(columnWidth5)}";
  //               } else {
  //                 line = "${''.padRight(columnWidth1)}"
  //                     "${descriptionLines[j].padRight(columnWidth2)}"
  //                     "${''.padRight(columnWidth3)}"
  //                     "${''.padRight(columnWidth4)}"
  //                     "${''.padRight(columnWidth5)}";
  //               }
  //               printer.printCustom(line, 1, 0); // Left aligned
  //             }
  //             serialNumber++; // Increment the serial number for each unit printed
  //           }
  //         } else {
  //           // Handle case where no units are available
  //           String productUnit = "No units available";
  //           String productQty = "N/A"; // Or any default value

  //           List<String> descriptionLines =
  //               splitText(productName, columnWidth2);
  //           for (int j = 0; j < descriptionLines.length; j++) {
  //             String line;
  //             if (j == 0) {
  //               line = "${serialNumber.toString().padRight(columnWidth1)}"
  //                   "${descriptionLines[j].padRight(columnWidth2)}"
  //                   "  ${productCode.padRight(columnWidth3)}"
  //                   "${productUnit.padRight(columnWidth4)}"
  //                   "${productQty.padRight(columnWidth5)}";
  //             } else {
  //               line = "${''.padRight(columnWidth1)}"
  //                   "${descriptionLines[j].padRight(columnWidth2)}"
  //                   "${''.padRight(columnWidth3)}"
  //                   "${''.padRight(columnWidth4)}"
  //                   "${''.padRight(columnWidth5)}";
  //             }
  //             printer.printCustom(line, 1, 0); // Left aligned
  //           }
  //         }
  //       }

  //       // Print the bottom separator line
  //       printer.printCustom("-" * 70, 1, 1); // Centered
  //       printer.printNewLine();
  //       printer.paperCut();
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Printer not connected')),
  //       );
  //     }
  //   }
  //   if (!_connected) {
  //     await _connect();
  //   }
  // }

  // Future<void> _printStock() async {
  //   if (_connected) {
  //     final response = await http.get(Uri.parse(
  //         '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));

  //     if (response.statusCode == 200) {
  //       StoreDetail storeDetail =
  //       StoreDetail.fromJson(json.decode(response.body));
  //       final String api =
  //           '${RestDatasource().Image_URL}/uploads/store/${storeDetail.logos}';
  //       final logoResponse = await http.get(Uri.parse(api));
  //       if (logoResponse.statusCode != 200) {
  //         throw Exception('Failed to load logo image');
  //       }
  //       Uint8List imageBytes = logoResponse.bodyBytes;
  //       img.Image originalImage = img.decodeImage(imageBytes)!;
  //       img.Image monoLogo = img.grayscale(originalImage);
  //       Uint8List logoBytes = Uint8List.fromList(img.encodePng(monoLogo));
  //       printer.printImageBytes(logoBytes);

  //       printer.printNewLine();
  //       printer.printCustom(storeDetail.name, 3, 1);
  //       printer.printNewLine();
  //       printer.printCustom("Van Stock", 3, 1);
  //       printer.printNewLine();
  //       printer.printCustom("-" * 70, 1, 1);

  //       const int columnWidth1 = 5;
  //       const int columnWidth2 = 30;
  //       const int columnWidth3 = 13;
  //       const int columnWidth4 = 10;
  //       const int columnWidth5 = 10;
  //       String headers = "${'S.No'.padRight(columnWidth1)}"
  //           " ${'Product'.padRight(columnWidth2)}"
  //           " ${'Code'.padRight(columnWidth3)}"
  //           " ${'Unit'.padRight(columnWidth4)}"
  //           "${'Qty'.padRight(columnWidth5)}";
  //       printer.printCustom(headers, 1, 0);

  //       List<String> splitText(String text, int width) {
  //         List<String> lines = [];
  //         while (text.length > width) {
  //           lines.add(text.substring(0, width));
  //           text = text.substring(width);
  //         }
  //         lines.add(text);
  //         return lines;
  //       }

  //       printer.printNewLine();
  //       int serialNumber = 1;

  //       final uniqueProducts = <String, dynamic>{};
  //       for (var product in _filteredProducts) {
  //         uniqueProducts[product.code!] = product;
  //       }

  //       for (var product in uniqueProducts.values) {
  //         final uniqueUnits = <String, dynamic>{};
  //         for (var unit in product.units) {
  //           final key = '${unit.name}-${unit.stock}';
  //           uniqueUnits[key] = unit;
  //         }

  //         if (uniqueUnits.isNotEmpty) {
  //           for (var unit in uniqueUnits.values) {
  //             String productName = "${product.name!.toUpperCase()}";
  //             String productCode = "${product.code}";
  //             String productUnit = "${unit.name}";
  //             String productQty = "${unit.stock}";

  //             List<String> descriptionLines =
  //             splitText(productName, columnWidth2);

  //             for (int j = 0; j < descriptionLines.length; j++) {
  //               String line;
  //               if (j == 0) {
  //                 line = "${serialNumber.toString().padRight(columnWidth1)}"
  //                     "${descriptionLines[j].padRight(columnWidth2)}"
  //                     "  ${productCode.padRight(columnWidth3)}"
  //                     "${productUnit.padRight(columnWidth4)}"
  //                     "${productQty.padRight(columnWidth5)}";
  //               } else {
  //                 line = "${''.padRight(columnWidth1)}"
  //                     "${descriptionLines[j].padRight(columnWidth2)}"
  //                     "${''.padRight(columnWidth3)}"
  //                     "${''.padRight(columnWidth4)}"
  //                     "${''.padRight(columnWidth5)}";
  //               }
  //               printer.printCustom(line, 1, 0);
  //             }
  //             serialNumber++;
  //           }
  //         } else {
  //           // No units available
  //           String productName = "${product.name!.toUpperCase()}";
  //           String productCode = "${product.code}";
  //           String productUnit = "No units available";
  //           String productQty = "N/A";

  //           List<String> descriptionLines =
  //           splitText(productName, columnWidth2);
  //           for (int j = 0; j < descriptionLines.length; j++) {
  //             String line;
  //             if (j == 0) {
  //               line = "${serialNumber.toString().padRight(columnWidth1)}"
  //                   "${descriptionLines[j].padRight(columnWidth2)}"
  //                   "  ${productCode.padRight(columnWidth3)}"
  //                   "${productUnit.padRight(columnWidth4)}"
  //                   "${productQty.padRight(columnWidth5)}";
  //             } else {
  //               line = "${''.padRight(columnWidth1)}"
  //                   "${descriptionLines[j].padRight(columnWidth2)}"
  //                   "${''.padRight(columnWidth3)}"
  //                   "${''.padRight(columnWidth4)}"
  //                   "${''.padRight(columnWidth5)}";
  //             }
  //             printer.printCustom(line, 1, 0);
  //           }
  //           serialNumber++;
  //         }
  //       }

  //       printer.printCustom("-" * 70, 1, 1);
  //       printer.printNewLine();
  //       printer.paperCut();
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Printer not connected')),
  //       );
  //     }
  //   }
  //   if (_selectedDevice == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Default device not found')),
  //     );
  //     return;
  //   }
  //   if (!_connected) {
  //     await _connect();
  //   }
  // }
// ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════
  // VAN RETURN PRINT ROUTER
  // ═══════════════════════════════════════════════════════════════
  Future<void> _printReturn() async {
    // Printer must be known BEFORE choosing Zebra/Sewoo
    if (_selectedDevice == null) await _getBluetoothDevices();
    if (_selectedDevice == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default printer not found')),
        );
      }
      return;
    }
    print('PRINT route: zebra=${isZebraPrinter(_selectedDevice)} '
        'name=${_selectedDevice?.name} addr=${_selectedDevice?.address}');

    final bool? isActuallyConnected = await printer.isConnected;
    if (isActuallyConnected != true) {
      _connected = false;
      await _connect();
    }

    if (!_connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer not connected')),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    try {
    if (isZebraPrinter(_selectedDevice)) {
  await _printImageVanReturn();
} else {
  await _printSewooReturn();
}
    } catch (e, st) {
      print('Print error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // VAN STOCK PRINT ROUTER
  // ═══════════════════════════════════════════════════════════════
  Future<void> _printStock() async {
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default device not found')),
      );
      return;
    }

    final bool? isActuallyConnected = await printer.isConnected;
    if (isActuallyConnected != true) {
      _connected = false;
      await _connect();
    }

    if (!_connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer not connected')),
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    try {
     if (isZebraPrinter(_selectedDevice)) {
  await _printImageVanStock();
} else {
  await _printSewooStock();
}
    } catch (e, st) {
      print('Print error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  // ───────────────────────────────────────────────────────────────
  // 1. ZEBRA ENGINE - VAN RETURN (CPCL)
  // ───────────────────────────────────────────────────────────────
  Future<void> _printZebraReturn() async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load store details')));
      return;
    }
    StoreDetail storeDetail = StoreDetail.fromJson(json.decode(response.body));

    final cpcl = CpclBuilder(kLabelWidthDots);

    if (storeDetail.logos != null && storeDetail.logos!.isNotEmpty) {
      try {
        String logoUrl =
            'https://erpadmin.mobiz.ae/uploads/store/${storeDetail.logos}';
        final logoResp = await http.get(Uri.parse(logoUrl));
        if (logoResp.statusCode == 200) {
          img.Image? original = img.decodeImage(logoResp.bodyBytes);
          if (original != null) {
            img.Image resized = img.copyResize(original, width: kLogoWidthPx);
            final bytesPerRow = (resized.width / 8).ceil();
            final packed = imageTo1BitCpcl(resized, invert: kInvertLogoBits);
            cpcl.addLogo(packed, bytesPerRow, resized.height);
          }
        }
      } catch (e) {
        print('Logo error: $e');
      }
    }

    cpcl.centerText('${storeDetail.name}', font: 5, lineGap: 34);
    cpcl.centerText("Van Return", font: 5, lineGap: 34);
    cpcl.hLine();

    cpcl.text("S.No Product                   Unit      Qty", font: 4, lineGap: 30);
    cpcl.hLine(thickness: 1);

    int serialNumber = 1;
    for (int i = 0; i < _filteredProducts1.length; i++) {
      var product = _filteredProducts1[i];
      if (product.units.isNotEmpty) {
        for (var unit in product.units) {
          String sNo = serialNumber.toString().padRight(4);
          String name = product.name.toUpperCase();
          if (name.length > 38) name = name.substring(0, 38);
          String unitName = unit.name.toString().padLeft(6);
          String qty = unit.stock.toString().padLeft(8);

          cpcl.text('$sNo$name', font: 4, lineGap: 28);
          String details = '     [${product.code}]'.padRight(25) + '$unitName  $qty';
          cpcl.text(details, font: 4, lineGap: 30);

          serialNumber++;
        }
      } else {
        String sNo = serialNumber.toString().padRight(4);
        String name = product.name.toUpperCase();
        if (name.length > 38) name = name.substring(0, 38);
        cpcl.text('$sNo$name', font: 4, lineGap: 28);
        String details = '     [${product.code}]'.padRight(25) + '   N/A       0';
        cpcl.text(details, font: 4, lineGap: 30);
        serialNumber++;
      }
    }

    cpcl.hLine();
    cpcl.centerText('Total Items: ${serialNumber - 1}', font: 4, lineGap: 30);
    cpcl.feed(40);

    final bytes = cpcl.build();
    await sendCpcl(printer, bytes);
  }

  // ───────────────────────────────────────────────────────────────
  // 2. SEWOO ENGINE - VAN RETURN (ESC/POS)
  // ───────────────────────────────────────────────────────────────
  Future<void> _printSewooReturn() async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
    if (response.statusCode == 200) {
      StoreDetail storeDetail =
          StoreDetail.fromJson(json.decode(response.body));

      String logoUrl =
          'http://erpadmin.mobiz.ae/uploads/store/${storeDetail.logos}';
      if (logoUrl.isNotEmpty) {
        try {
          final logoBytes = await buildSewooLogoBytes(logoUrl);
          if (logoBytes != null) {
            await printer.printImageBytes(logoBytes);
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          print('Failed to load logo: $e');
        }
      }

      printer.printNewLine();
      String companyName = '${storeDetail.name}';
      printer.printCustom(companyName, 3, 1);
      printer.printNewLine();
      printer.printCustom("Van Return", 3, 1);
      printer.printNewLine();
      printer.printCustom("-" * 70, 1, 1);

      const int columnWidth1 = 5;
      const int columnWidth2 = 30;
      const int columnWidth3 = 13;
      const int columnWidth4 = 10;
      const int columnWidth5 = 10;

     String headers = "${'#'.padRight(columnWidth1)}"
    "${'Product'.padRight(columnWidth2)} "
    "${'Unit'.padRight(columnWidth3)}"
          "${'Qty'.padRight(columnWidth5)}";
      printer.printCustom(headers, 1, 0);
      printer.printNewLine();

      int serialNumber = 1;
      for (int i = 0; i < _filteredProducts1.length; i++) {
        var product = _filteredProducts1[i];
        String productName = "${product.name.toUpperCase()}";
        String productCode = "${product.code}";

        if (product.units.isNotEmpty) {
          for (var unit in product.units) {
            String productUnit = "${unit.name}";
            String productQty = "${unit.stock}";
            List<String> descriptionLines = _splitText(productName, columnWidth2);

            for (int j = 0; j < descriptionLines.length; j++) {
              String line = j == 0
                  ? "${serialNumber.toString().padRight(columnWidth1)}"
                      "${descriptionLines[j].padRight(columnWidth2)}"
                      "  ${productCode.padRight(columnWidth3)}"
                      "${productUnit.padRight(columnWidth4)}"
                      "${productQty.padRight(columnWidth5)}"
                  : "${''.padRight(columnWidth1)}"
                      "${descriptionLines[j].padRight(columnWidth2)}"
                      "${''.padRight(columnWidth3)}"
                      "${''.padRight(columnWidth4)}"
                      "${''.padRight(columnWidth5)}";
              printer.printCustom(line, 1, 0);
            }
            serialNumber++;
          }
        } else {
          String productUnit = "No units available";
          String productQty = "N/A";
          List<String> descriptionLines = _splitText(productName, columnWidth2);

          for (int j = 0; j < descriptionLines.length; j++) {
            String line = j == 0
                ? "${serialNumber.toString().padRight(columnWidth1)}"
                    "${descriptionLines[j].padRight(columnWidth2)}"
                    "  ${productCode.padRight(columnWidth3)}"
                    "${productUnit.padRight(columnWidth4)}"
                    "${productQty.padRight(columnWidth5)}"
                : "${''.padRight(columnWidth1)}"
                    "${descriptionLines[j].padRight(columnWidth2)}"
                    "${''.padRight(columnWidth3)}"
                    "${''.padRight(columnWidth4)}"
                    "${''.padRight(columnWidth5)}";
            printer.printCustom(line, 1, 0);
          }
          serialNumber++;
        }
      }

      printer.printCustom("-" * 70, 1, 1);
      printer.printNewLine();
      printer.paperCut();
    }
  }

  // ───────────────────────────────────────────────────────────────
  // 3. ZEBRA ENGINE - VAN STOCK (CPCL)
  // ───────────────────────────────────────────────────────────────
  Future<void> _printZebraStock() async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load store details')));
      return;
    }
    StoreDetail storeDetail = StoreDetail.fromJson(json.decode(response.body));

    final cpcl = CpclBuilder(kLabelWidthDots);

    if (storeDetail.logos != null && storeDetail.logos!.isNotEmpty) {
      try {
        final String api =
            '${RestDatasource().Image_URL}/uploads/store/${storeDetail.logos}';
        final logoResponse = await http.get(Uri.parse(api));
        if (logoResponse.statusCode == 200) {
          img.Image? original = img.decodeImage(logoResponse.bodyBytes);
          if (original != null) {
            img.Image resized = img.copyResize(original, width: kLogoWidthPx);
            final bytesPerRow = (resized.width / 8).ceil();
            final packed = imageTo1BitCpcl(resized, invert: kInvertLogoBits);
            cpcl.addLogo(packed, bytesPerRow, resized.height);
          }
        }
      } catch (e) {
        print('Logo error: $e');
      }
    }

    cpcl.centerText(storeDetail.name, font: 5, lineGap: 34);
    cpcl.centerText("Van Stock", font: 5, lineGap: 34);
    cpcl.hLine();

    cpcl.text("S.No Product                   Unit      Qty", font: 4, lineGap: 30);
    cpcl.hLine(thickness: 1);

    int serialNumber = 1;
    final uniqueProducts = <String, dynamic>{};
    for (var product in _filteredProducts) {
      if (product.code.isNotEmpty) {
        uniqueProducts[product.code] = product;
      }
    }

    for (var product in uniqueProducts.values) {
      final uniqueUnits = <String, dynamic>{};
      for (var unit in product.units) {
        final key = '${unit.name}-${unit.stock}';
        uniqueUnits[key] = unit;
      }

      if (uniqueUnits.isNotEmpty) {
        for (var unit in uniqueUnits.values) {
          String sNo = serialNumber.toString().padRight(4);
          String name = product.name.toUpperCase();
          if (name.length > 38) name = name.substring(0, 38);
          String unitName = unit.name.toString().padLeft(6);
          String qty = unit.stock.toString().padLeft(8);

          cpcl.text('$sNo$name', font: 4, lineGap: 28);
          String details = '     [${product.code}]'.padRight(25) + '$unitName  $qty';
          cpcl.text(details, font: 4, lineGap: 30);

          serialNumber++;
        }
      } else {
        String sNo = serialNumber.toString().padRight(4);
        String name = product.name.toUpperCase();
        if (name.length > 38) name = name.substring(0, 38);
        cpcl.text('$sNo$name', font: 4, lineGap: 28);
        String details = '     [${product.code}]'.padRight(25) + '   N/A       0';
        cpcl.text(details, font: 4, lineGap: 30);
        serialNumber++;
      }
    }

    cpcl.hLine();
    cpcl.centerText('Total Items: ${serialNumber - 1}', font: 4, lineGap: 30);
    cpcl.feed(40);

    final bytes = cpcl.build();
    await sendCpcl(printer, bytes);
  }

  // ───────────────────────────────────────────────────────────────
  // 4. SEWOO ENGINE - VAN STOCK (ESC/POS)
  // ───────────────────────────────────────────────────────────────
  Future<void> _printSewooStock() async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));

    if (response.statusCode == 200) {
      StoreDetail storeDetail =
          StoreDetail.fromJson(json.decode(response.body));

      try {
        final String api =
            '${RestDatasource().Image_URL}/uploads/store/${storeDetail.logos}';
        final logoBytes = await buildSewooLogoBytes(api);
        if (logoBytes != null) {
          await printer.printImageBytes(logoBytes);
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        print('Logo load error: $e');
      }
      printer.printNewLine();
      printer.printCustom(storeDetail.name, 3, 1);
      printer.printNewLine();
      printer.printCustom("Van Stock", 3, 1);
      printer.printNewLine();
      printer.printCustom("-" * 70, 1, 1);

      const int columnWidth1 = 5;
      const int columnWidth2 = 30;
      const int columnWidth3 = 13;
      const int columnWidth4 = 10;
      const int columnWidth5 = 10;

      String headers = "${'S.No'.padRight(columnWidth1)}"
          " ${'Product'.padRight(columnWidth2)}"
          " ${'Code'.padRight(columnWidth3)}"
          " ${'Unit'.padRight(columnWidth4)}"
          "${'Qty'.padRight(columnWidth5)}";
      printer.printCustom(headers, 1, 0);
      printer.printNewLine();

      int serialNumber = 1;
      final uniqueProducts = <String, dynamic>{};
      for (var product in _filteredProducts) {
        if (product.code.isNotEmpty) {
          uniqueProducts[product.code] = product;
        }
      }

      for (var product in uniqueProducts.values) {
        final uniqueUnits = <String, dynamic>{};
        for (var unit in product.units) {
          final key = '${unit.name}-${unit.stock}';
          uniqueUnits[key] = unit;
        }

        if (uniqueUnits.isNotEmpty) {
          for (var unit in uniqueUnits.values) {
            String productName = "${product.name.toUpperCase()}";
            String productCode = "${product.code}";
            String productUnit = "${unit.name}";
            String productQty = "${unit.stock}";
            List<String> descriptionLines = _splitText(productName, columnWidth2);

            for (int j = 0; j < descriptionLines.length; j++) {
              String line = j == 0
                  ? "${serialNumber.toString().padRight(columnWidth1)}"
                      "${descriptionLines[j].padRight(columnWidth2)}"
                      "  ${productCode.padRight(columnWidth3)}"
                      "${productUnit.padRight(columnWidth4)}"
                      "${productQty.padRight(columnWidth5)}"
                  : "${''.padRight(columnWidth1)}"
                      "${descriptionLines[j].padRight(columnWidth2)}"
                      "${''.padRight(columnWidth3)}"
                      "${''.padRight(columnWidth4)}"
                      "${''.padRight(columnWidth5)}";
              printer.printCustom(line, 1, 0);
            }
            serialNumber++;
          }
        } else {
          String productName = "${product.name.toUpperCase()}";
          String productCode = "${product.code}";
          String productUnit = "No units available";
          String productQty = "N/A";
          List<String> descriptionLines = _splitText(productName, columnWidth2);

          for (int j = 0; j < descriptionLines.length; j++) {
            String line = j == 0
                ? "${serialNumber.toString().padRight(columnWidth1)}"
                    "${descriptionLines[j].padRight(columnWidth2)}"
                    "  ${productCode.padRight(columnWidth3)}"
                    "${productUnit.padRight(columnWidth4)}"
                    "${productQty.padRight(columnWidth5)}"
                : "${''.padRight(columnWidth1)}"
                    "${descriptionLines[j].padRight(columnWidth2)}"
                    "${''.padRight(columnWidth3)}"
                    "${''.padRight(columnWidth4)}"
                    "${''.padRight(columnWidth5)}";
            printer.printCustom(line, 1, 0);
          }
          serialNumber++;
        }
      }

      printer.printCustom("-" * 70, 1, 1);
      printer.printNewLine();
      printer.paperCut();
    }
  }

  List<String> _splitText(String text, int width) {
    List<String> lines = [];
    while (text.length > width) {
      lines.add(text.substring(0, width));
      text = text.substring(width);
    }
    lines.add(text);
    return lines;
  }
  // Widget _buildListItem(Product product) {
  //   // Implement the widget to build the list item for each product
  //   return ListTile(
  //     title: Text(product.name ?? ''),
  //     subtitle: Text('Code: ${product.code}'),
  //     trailing: Text(
  //         'Stock: ${product.units.isNotEmpty ? product.units[0].stock.toString() : '0'}'),
  //   );
  // }

  Future<ApiResponse> _getProducts() async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_van_stock?store_id=${AppState().storeId}&van_id=${AppState().vanId}'));
print(response.request);
    if (response.statusCode == 200) {
      print(response.request);
      final data = json.decode(response.body);
      ApiResponse apiResponse = ApiResponse.fromJson(data);
      apiResponse.data = apiResponse.data.where((product) {
        return product.units.any((unit) => unit.stock > 0);
      }).toList();

      return apiResponse;
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<VanStockReturnResponse> _getReturns() async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_van_stock_return?store_id=${AppState().storeId}&van_id=${AppState().vanId}'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      VanStockReturnResponse apiResponse =
          VanStockReturnResponse.fromJson(data);
      // Return products without filtering (filtering is handled in _fetchReturns)
      return apiResponse;
    } else {
      throw Exception('Failed to load products');
    }
  }
}

class ApiResponse {
  List<Product> data;
  bool success;
  List<String> messages;

  ApiResponse({
    required this.data,
    required this.success,
    required this.messages,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      // Correctly mapping the data to a List<Product>
      data: List<Product>.from(
          json['data'].map((x) => Product.fromJson(x)).toList()),
      success: json['success'],
      messages: List<String>.from(json['messages']),
    );
  }
}

class Product {
  final int id;
  final String code;
  final String name;
  final String proImage;
  final double taxPercentage;
  final double price;
  final int storeId;
  final int status;
  final List<Unit> units;

  Product({
    required this.id,
    required this.code,
    required this.name,
    required this.proImage,
    required this.taxPercentage,
    required this.price,
    required this.storeId,
    required this.status,
    required this.units,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      code: json['code'] ?? '', // ✅ NULL SAFE
      name: json['name'] ?? '',
      proImage: json['pro_image'] ?? '',
      taxPercentage: (json['tax_percentage'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      storeId: json['store_id'] ?? 0,
      status: json['status'] ?? 0,
      units: (json['units'] as List?)
          ?.map((x) => Unit.fromJson(x))
          .toList() ??
          [],
    );
  }
  Product copyWith({List<Unit>? units}) {
    return Product(
      id: this.id,
      code: this.code,
      name: this.name,
      proImage: this.proImage,
      taxPercentage: this.taxPercentage,
      price: this.price,
      storeId: this.storeId,
      status: this.status,
      units: units ?? this.units,
    );
  }
}


class Unit {
  int unit;
  int id;
  String name;
  double price;
  double minPrice;
  double stock;

  Unit({
    required this.unit,
    required this.id,
    required this.name,
    required this.price,
    required this.minPrice,
    required this.stock,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      unit: json['unit'] ?? 0, // Default to 0 if null
      id: json['id'] ?? 0, // Default to 0 if null
      name: json['name'] ?? '', // Default to empty string if null
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0, // Fallback to 0.0
      minPrice: double.tryParse(json['min_price']?.toString() ?? '') ?? 0.0, // Fallback to 0.0
      stock: (json['stock'] as num?)?.toDouble() ?? 0.0, // Safely convert to double
    );
  }
}