import 'dart:async';
import 'dart:ui' as ui;

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:number_to_words/number_to_words.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:convert';
import '../Models/appstate.dart';
import '../Models/invoicedata.dart' as Invoice;
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import '../Components/commonwidgets.dart';
import '../Models/invoicedata.dart';
import '../Models/invoicedata.dart';
import '../Models/pdfgenerate.dart';
import '../Models/productquantirydetails.dart';
import '../Utilities/rest_ds.dart';
import '../Utilities/date_helper.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'SaleInvoiceSearchPage.dart';

class SaleInvoiceScrreen extends StatefulWidget {
  static const routeName = "/SalreInvoice";
  const SaleInvoiceScrreen({super.key});
  @override
  _SaleInvoiceScrreenState createState() => _SaleInvoiceScrreenState();
}

class _SaleInvoiceScrreenState extends State<SaleInvoiceScrreen> {
  List<VanSale> vanSales = [];
  List<VanSale> filteredVanSales = [];
  bool isLoading = false;
  // ── NEW: caches store-logo bytes by filename so repeated PDF views
  // for the same store don't re-download the same image every time ──
  final Map<String, Uint8List> _logoCache = {};
  
  int currentPage = 1; // Track the current page number
  VanSaleResponse products = VanSaleResponse();
  bool hasNextPage = true; // Flag to check if there's another page to load
  final TextEditingController _searchController = TextEditingController();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  bool _initDone = false;
  bool _noData = false;
  bool _isSearching = false;
  Timer? _searchDebounce;
  bool _hasMore = true;
  List<int> selectedItems = [];
  List<Map<String, dynamic>> items = [];
  bool _search = false;
  int? customerId;

  int? id;
  String? name;

  @override
  void initState() {
    super.initState();
    // _fetchVanSales(currentPage);
    _fetchVanSales(currentPage);
    _initPrinter();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _initPrinter() async {
    bool? isConnected = await printer.isConnected;
    if (isConnected!) {
      setState(() {
        _connected = true;
      });
    }
    _getBluetoothDevices();
  }

  void _getBluetoothDevices() async {
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

  void _onSearchChanged(String query) {
    setState(() {
      currentPage = 1;
      _hasMore = true;
      vanSales.clear();
      _isSearching = query.isNotEmpty;
    });

    // Only fetch data if the query is non-empty, otherwise load regular data
    if (query.isEmpty) {
      _fetchVanSales(currentPage); // Regular fetch for all sales
    } else {
      _fetchVanSales(currentPage,
          searchQuery: query); // Fetch with search query
    }
  }

  Future<void> _fetchVanSales(int page, {String? searchQuery}) async {
    if (isLoading || !hasNextPage) return;

    setState(() {
      isLoading = true;
    });

    try {
      final Uri apiUrl;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        apiUrl =
            Uri.parse("${RestDatasource().BASE_URL}/api/vansale.index.search?"
                "store_id=${AppState().storeId}&"
                "van_id=${AppState().vanId}&"
                "user_id=${AppState().userId}&"
                "page=$page&"
                "value=$searchQuery");
      } else {
        apiUrl = Uri.parse("${RestDatasource().BASE_URL}/api/vansale.index?"
            "store_id=${AppState().storeId}&"
            "van_id=${AppState().vanId}&"
            "user_id=${AppState().userId}&"
            "page=$page");
      }

      final http.Response response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        print(response.request);
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final VanSaleResponse vanSaleResponse =
            VanSaleResponse.fromJson(responseData);

        setState(() {
          vanSales.addAll(vanSaleResponse.data!.vanSales);
          _hasMore = vanSaleResponse.data!.nextPageUrl.isNotEmpty;
          if (vanSaleResponse.data!.vanSales.isNotEmpty) {
            currentPage++;
          }
          _initDone = true;
        });
      } else {
        throw Exception("Failed to fetch data");
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
        _initDone = true;
      });
    }
  }

  // Detect when the user scrolls to the bottom
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        notification.metrics.pixels == notification.metrics.maxScrollExtent &&
        !isLoading &&
        _hasMore) {
      _fetchVanSales(
        currentPage,
        searchQuery: _isSearching ? _searchController.text : null,
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      id = params!['customerId'];
      name = params['name'];
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
        title: _isSearching
            ? TextField(
                autofocus: true,
                // controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by invoice or customer...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.white),
                onChanged: (value) {
                  // Cancel any ongoing debounce timer to reset it
                  _searchDebounce?.cancel();

                  // Start a new debounce timer to avoid calling search too often
                  _searchDebounce =
                      Timer(const Duration(milliseconds: 500), () {
                    // Only trigger search if the query is different from the previous one
                    if (value.isNotEmpty) {
                      _onSearchChanged(value);
                    } else {
                      // If the search query is empty, reload all data
                      _onSearchChanged("");
                    }
                  });
                })
            : const Text(
                'Sales Invoice',
                style: AppConfig.pageTitleStyle,
              ),
        backgroundColor: AppConfig.colorPrimary,
        actions: [
          IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _searchController.clear();
                    // _onSearchChanged(); // This will trigger the fetch
                  } else {
                    _isSearching = true;
                  }
                });
              }),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            children: [
              if (_isSearching &&
                  vanSales.isEmpty &&
                  _searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('No results found'),
                ),
              Expanded(
                child: (_initDone && !_noData)
                    ? ListView.separated(
                        separatorBuilder: (BuildContext context, int index) =>
                            const SizedBox(height: 0),
                        itemCount: vanSales.length + (isLoading ? 1 : 0),
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          if (index == vanSales.length) {
                            return isLoading
                                ? const Center(
                                    child: Text(
                                    "Loading...",
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey),
                                  ))
                                : Center(
                                    child: Text(
                                      "That's All",
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey.shade400,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  );
                          }
                          return _productsCard(vanSales[index], index);
                        },
                      )
                    : (_noData && _initDone)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                CommonWidgets.verticalSpace(3),
                                const Center(
                                  child: Text('No Data'),
                                ),
                              ])
                        : Shimmer.fromColors(
                            baseColor:
                                AppConfig.buttonDeactiveColor.withOpacity(0.1),
                            highlightColor: AppConfig.backButtonColor,
                            child: Center(
                              child: Column(
                                children: [
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productsCard(VanSale data, int index) {
    print("Status = ${data.status}");

    print(data.toJson());
    String _formatName(String name) {
      List<String> words = name.split(' '); // Split the name into words
      if (words.length > 5) {
        // Join the first 5 words and place the rest on a new line
        return words.sublist(0, 5).join(' ') +
            '\n' +
            words.sublist(5).join(' ');
      } else {
        // If less than or equal to 5 words, return the name as is
        return name;
      }
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 0),
      child: Container(
        width: SizeConfig.blockSizeHorizontal * 90,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          color: AppConfig.backgroundColor,
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 2.0),
            childrenPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
         trailing: SizedBox(
  // ── FIX: widened to fit the bigger tap targets below without clipping ──
  width: AppState().printer == "Wifi" ? 130 : 90,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // ── FIX: wrapped in InkWell + Padding so the actual tappable
      // area is ~40x40 instead of just the 24x24 icon glyph — the
      // print icon (leftmost, closest to the list-tile edge) was the
      // one most often missed since it had the least room around it. ──
      InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _getInvoiceDataprint(data.id!, false),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.print, color: Colors.blueAccent, size: 26),
        ),
      ),
      if (AppState().printer == "Wifi")
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _getwifiInvoiceData(data.id!, false),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.document_scanner,
              color: Colors.green,
              size: 26,
            ),
          ),
        ),
      InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _getInvoiceData(data.id!, false),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.document_scanner, color: Colors.red, size: 26),
        ),
      ),
    ],
  ),
),
            backgroundColor: AppConfig.backgroundColor,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: data.invoiceNo!,
                  child: Text(
                    '${data.invoiceNo!} | ${DateHelper.displayDate(data.inDate)} ${data.inTime}',
                    style: TextStyle(
                      fontSize: AppConfig.textCaption3Size,
                      height: 1.1,
                    ),
                  ),
                ),
                Text(
                  (data.customer != null && data.customer!.isNotEmpty)
                      ? data.customer![0].name ?? ''
                      : (data.customerdata != null)
                          ? data.customerdata![0].name ?? ''
                          : '',
                  style: TextStyle(
                    fontSize: AppConfig.textCaption3Size,
                    height: 1.15,
                    fontWeight: AppConfig.headLineWeight,
                  ),
                ),
                (data.detail!.isNotEmpty)
                    ? Text(
                        'Total: ${data.total?.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
                        style: TextStyle(
                          fontSize: AppConfig.textCaption3Size,
                          height: 1.15,
                        ),
                      )
                    : Text(
                        'Type: ',
                        style: TextStyle(
                          fontSize: AppConfig.textCaption3Size,
                          height: 1.15,
                        ),
                      ),
                data.discount_type == '0'
                    ? Text(
                        'Discount : ${data.discount?.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
                        style: TextStyle(
                          fontSize: AppConfig.textCaption3Size,
                          height: 1.15,
                        ),
                      )
                    : data.discount_type == '1'
                        ? Text(
                            'Discount(%): ${data.discount?.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
                            style: TextStyle(
                              fontSize: AppConfig.textCaption3Size,
                              height: 1.15,
                            ),
                          )
                        : const SizedBox.shrink(),
                Text(
                  'Round off: ${double.parse(data.roundOff ?? '0').toStringAsFixed(AppState().noOfDecimals ?? 2)}',
                  style: TextStyle(
                    fontSize: AppConfig.textCaption3Size,
                    height: 1.15,
                  ),
                ),
                Text(
                  'Total Vat: ${(data.totalTax?.toStringAsFixed(AppState().noOfDecimals ?? 2)) ?? ''}',
                  style: TextStyle(
                    fontSize: AppConfig.textCaption3Size,
                    height: 1.15,
                  ),
                ),
                Text(
                  'Grand Total: ${data.grandTotal}',
                  style: TextStyle(
                    fontSize: AppConfig.textCaption3Size,
                    height: 1.15,
                    fontWeight: AppConfig.headLineWeight,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Status : ',
                      style: TextStyle(
                        fontSize: AppConfig.textCaption3Size,
                        height: 1.15,
                        fontWeight: AppConfig.headLineWeight,
                      ),
                    ),
                    Text(
                      data.status == 0
                          ? "Cancelled"
                          : (data.status == 1 || data.status == 2)
                              ? "Confirmed"
                              : "Unknown",
                      style: TextStyle(
                        fontSize: AppConfig.textCaption3Size,
                        height: 1.15,
                        fontWeight: AppConfig.headLineWeight,
                        color: data.status == 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonWidgets.verticalSpace(1),
                    Divider(
                        color: AppConfig.buttonDeactiveColor.withOpacity(0.4)),
                    for (int i = 0; i < data.detail!.length; i++)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: SizeConfig.blockSizeHorizontal * 85,
                            child: Text(
                              ('${data.detail![i].code ?? ''} | ${data.detail![i].name ?? ''}')
                                  .toUpperCase(),
                              style: TextStyle(
                                  fontSize: AppConfig.textCaption3Size,
                                  height: 1.15,
                                  fontWeight: AppConfig.headLineWeight),
                            ),
                          ),
                          SizedBox(
                            width: SizeConfig.blockSizeHorizontal * 85,
                            child: Row(
                              children: [
                                Text(
                                  data.detail![i].productType ?? '',
                                  style: TextStyle(
                                    fontSize: AppConfig.textCaption3Size,
                                    height: 1.15,
                                  ),
                                ),
                                const Text(' | '),
                                Text(
                                  data.detail![i].unit ?? '',
                                  style: TextStyle(
                                    fontSize: AppConfig.textCaption3Size,
                                    height: 1.15,
                                  ),
                                ),
                                const Text(' | '),
                                Text(
                                  'Qty: ${data.detail![i].quantity}',
                                  style: TextStyle(
                                    fontSize: AppConfig.textCaption3Size,
                                    height: 1.15,
                                  ),
                                ),
                                const Text(' | '),
                                Text(
                                  'Rate: ${data.detail![i].mrp}',
                                  style: TextStyle(
                                    fontSize: AppConfig.textCaption3Size,
                                    height: 1.15,
                                  ),
                                ),
                                const Text(' | '),
                                Text(
                                  'Amount: ${data.detail![i].taxable?.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
                                  style: TextStyle(
                                    fontSize: AppConfig.textCaption3Size,
                                    height: 1.15,
                                  ),
                                )
                              ],
                            ),
                          ),
                          CommonWidgets.verticalSpace(1),
                          (i == data.detail!.length - 1)
                              ? Container()
                              : Divider(
                                  color: AppConfig.buttonDeactiveColor
                                      .withOpacity(0.4)),
                        ],
                      ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Renders Arabic text to a PNG image so it can be sent to the thermal
  /// printer via printImageBytes(). ESC/POS text commands (printCustom)
  /// only cover the printer's built-in codepage (Latin/ASCII) and can't
  /// shape/join Arabic glyphs, so Arabic must always go through the
  /// printer as a bitmap - same approach already used for the store logo.
  Future<Uint8List> _arabicTextToImageBytes(
    String text, {
    double fontSize = 26,
    double maxWidth = 380,
  }) async {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'NotoNaskhArabic', // ✅ proper Arabic shaping font
        ),
      ),
      textDirection: ui.TextDirection.rtl,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: maxWidth);

// Thermal printers need bitmap width byte-aligned (multiple of 8),
// otherwise printImageBytes can silently fail or corrupt subsequent output.
    double rawWidth = textPainter.width.ceilToDouble();
    final double width = (rawWidth / 8).ceil() * 8;
    final double height = textPainter.height.ceilToDouble();

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width, height),
    );

    // White background - printers invert/ignore transparent pixels.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );
    textPainter.paint(canvas, Offset.zero);

    final ui.Image image = await recorder.endRecording().toImage(
          width.toInt(),
          height.toInt(),
        );
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Loads a bundled Arabic-capable TTF font for the PDF.
  /// PdfStandardFont (Helvetica/base-14 fonts) only supports Latin/WinAnsi
  /// encoding - handing it Arabic Unicode text throws, which is why the
  /// PDF button did nothing after name_ar was added (the exception was
  /// never caught since _createPdf()/_wifiPdf() weren't awaited).
  /// Add a font file (e.g. NotoNaskhArabic-Regular.ttf) under
  /// assets/fonts/ and register it in pubspec.yaml's `assets:` section
  Future<PdfFont> _loadArabicPdfFont(
    double size, {
    PdfFontStyle style = PdfFontStyle.regular,
  }) async {
    // Syncfusion's PdfTrueTypeFont can't parse Variable Fonts (gvar tables) -
    // that's why the PDF button silently did nothing after this line was
    // added. Use the STATIC weight file instead (not the "VariableFont" one).
    final ByteData fontData =
        await rootBundle.load('Assets/fonts/NotoNaskhArabic-Regular.ttf');
    return PdfTrueTypeFont(fontData.buffer.asUint8List(), size, style: style);
  }

  void _print(Invoice.InvoiceData invoice, bool isPrint) async {
    if (_connected) {
      final String? name = invoice.data!.store![0].invoice_heading ?? '';
      String cusAddress = invoice.data!.customer![0].address ?? 'N/A';
      String companyName =
          invoice.data!.store![0].invoice_company_name ?? 'N/A';
      String companyNameAr = invoice.data!.store![0].name_ar ?? ''; // NEW
      String companyAddress = invoice.data!.store![0].address ?? 'N/A';
      String companyMail = invoice.data!.store![0].email ?? 'N/A';
      String companyTRN = "TRN: ${invoice.data!.store![0].trn ?? 'N/A'}";
      String billtype = "$name";
      String customerName = "${invoice.data!.customer![0].name}";
      List<String> nameWords = customerName.split(' ');
      String firstLine = customerName;
      String secondLine = "";
      if (nameWords.length > 7) {
        firstLine = nameWords.sublist(0, 7).join(' ');
        secondLine = nameWords.sublist(7).join(' ');
      }
      String customerEmail = invoice.data!.customer![0].email ?? 'N/A';
      String customerContact =
          invoice.data!.customer![0].contactNumber ?? 'N/A';
      String customerTRN = invoice.data?.customer?.firstOrNull?.trn ?? '';
      num amount = invoice.data!.grandTotal ?? 0.0;
      int wholePart = amount.floor();
      int decimalPart =
          ((amount - wholePart) * 1000).round(); // 3 decimal places
      String invoiceNumber = invoice.data!.invoiceNo ?? 'N/A';
      String invoiceDate = DateHelper.displayDate(invoice.data!.inDate);
      String dueDate = DateHelper.displayDate(invoice.data!.inDate);
      String Total =
          invoice.data!.total?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
              '0.00';
      String tax = invoice.data!.totalTax
              ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
          '0.00';
      String grandTotal = invoice.data!.grandTotal
              ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
          '0.00';
      final remarks = invoice.data?.remarks;
      String Discount;
      if (invoice.data!.discount != null &&
          double.tryParse(invoice.data!.discount!.toString()) != null &&
          double.parse(invoice.data!.discount!.toString()) > 0) {
        Discount =
            "Discount: ${double.parse(invoice.data!.discount!.toString()).toStringAsFixed(AppState().noOfDecimals ?? 2)}";
      } else {
        Discount = '';
      }
      String amountInWords = "Amount in Words: ${AppState().code} "
          "${NumberToWord().convert('en-in', wholePart).toUpperCase()}";

      if (decimalPart > 0) {
        amountInWords +=
            " AND ${NumberToWord().convert('en-in', decimalPart).toUpperCase()} ${AppState().minor}";
      }

      amountInWords += " ONLY";
   String van = invoice.data?.van?.firstOrNull?.name ?? 'N/A';
String salesman = invoice.data?.user?.firstOrNull?.name ?? 'N/A';

      void printAlignedText(String leftText, String rightText) {
        const int maxLineLength =
            68; // Adjust the maximum line length as per your printer's character limit
        int leftTextLength = leftText.length;
        int rightTextLength = rightText.length;

        // Calculate padding to ensure rightText is right-aligned
        int spaceLength = maxLineLength - (leftTextLength + rightTextLength);
        String spaces = ' ' * spaceLength;

        printer.printCustom(
            '$leftText$spaces$rightText', 1, 0); // Print with left-aligned text
      }

      String logoUrl =
          'https://erpadmin.mobiz.ae/uploads/store/${invoice.data!.store![0].logo}';
      if (logoUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          Uint8List imageBytes = response.bodyBytes;

          // Decode image and convert to monochrome bitmap if needed
          img.Image? originalImage = img.decodeImage(imageBytes)!;
          if (originalImage != null) {
            // Resize image to fit thermal printer width (typically 384 or 576 pixels)
            // 200-250px is a safe width for logos on most thermal printers.
            img.Image resizedImage = img.copyResize(originalImage, width: 250);

            // Convert to grayscale
            img.Image monoLogo = img.grayscale(resizedImage);

            // Encode the image to PNG
            Uint8List logoBytes = Uint8List.fromList(img.encodePng(monoLogo));

            // Print the logo image
            await printer.printImageBytes(logoBytes);
            // Small delay to allow printer to process image data
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } else {
          print('Failed to load image: ${response.statusCode}');
        }
      }

// Print company details
      printer.printNewLine();
      printer.printCustom(companyName, 3, 1); // Centered
      if (companyNameAr.trim().isNotEmpty) {
        // Arabic can't go through printCustom (see _arabicTextToImageBytes
        // doc comment above) - render it as a bitmap and print like the logo.
        try {
          final Uint8List arabicNameBytes =
              await _arabicTextToImageBytes(companyNameAr, fontSize: 30);
          await printer.printImageBytes(arabicNameBytes);
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          print('Failed to print Arabic company name: $e');
        }
      }
          printer.printCustom(companyAddress, 1, 1); // Centered
      printer.printCustom(companyMail, 1, 1);
      printer.printNewLine();

      printer.printCustom("TAX INVOICE", 2, 1); // ← Heading, centered (matches PDF)
      printer.printNewLine();

      printer.printCustom("-" * 72, 1, 1); // Centered
      printAlignedText("Invoice No: ${invoiceNumber}", "Date: ${invoiceDate}");
      printAlignedText("", "Time: ${invoice.data!.inTime}");
      printAlignedText("", "${remarks != null ? remarks : ''}");
      // printer.printCustom("Invoice No: ${invoiceNumber} | Date: ${invoiceDate}", 1, 1);
      printer.printNewLine();
      // Print customer details
      printAlignedText("Customer: $firstLine", "");

      if (secondLine.isNotEmpty) {
        printAlignedText("         $secondLine", "");
      }
      printAlignedText("$cusAddress", " ");
      // printAlignedText("Email: $customerEmail", "");
      printAlignedText("Contact No: $customerContact", "");
      printAlignedText(
          "${invoice.data?.store?.firstOrNull?.vat_label}: $customerTRN", " ");
      if (invoice.data!.cashCard != null &&
          invoice.data!.cashCard!.isNotEmpty) {
        printAlignedText("Bill Type: ${invoice.data!.cashCard}", " ");
      }
      printer.printNewLine();

      // Print horizontal line
      printer.printCustom("-" * 70, 1, 1); // Centered

      // Define column widths for table
      const int columnWidth1 = 5; // S.No
      const int columnWidth2 = 20; // Product Description
      const int columnWidth3 = 5; // Unit
      const int columnWidth4 = 6; // Qty
      // const int columnWidth5 = 7; // Type
      const int columnWidth6 = 7; // Rate
      const int columnWidth7 = 7; // Total
      const int columnWidth8 = 6; // Tax
      const int columnWidth9 = 8; // Amount

      // Print table headers
      String headers = "${'S.No'.padRight(columnWidth1)}"
          "${'Product'.padRight(columnWidth2)}"
          "${'Unit'.padRight(columnWidth3)}"
          "${'Qty'.padRight(columnWidth4)}"
          // "${'Type'.padRight(columnWidth5)}"
          "${'Rate'.padRight(columnWidth6)}"
          "${'Amount'.padRight(columnWidth7)}"
          "  ${'Vat'.padRight(columnWidth8)}"
          "${'Total'.padLeft(columnWidth9)}";
      printer.printCustom(headers, 1, 0); // Left aligned

      // Function to split text into lines of a given width
      List<String> splitText(String text, int width) {
        List<String> lines = [];
        while (text.length > width) {
          lines.add(text.substring(0, width));
          text = text.substring(width);
        }
        lines.add(text); // Add remaining part
        return lines;
      }

      // Print all product details
      for (int i = 0; i < invoice.data!.detail!.length; i++) {
        String productDescription = invoice.data!.detail![i].name ?? 'N/A';
        String productUnit = invoice.data!.detail![i].unit ?? 'N/A';
        String productQty =
            invoice.data!.detail![i].quantity?.toString() ?? '0';
        String productType =
            invoice.data!.detail![i].productType?.toString() ?? '0';
        String productRate = invoice.data!.detail![i].mrp
                ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
            '0.00';
        String productTotal = invoice.data!.detail![i].taxable
                ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
            '0.00';
        String productTax = invoice.data!.detail![i].taxAmt
                ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
            '0.00';
        String productAmount = invoice.data!.detail![i].amount
                ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
            '0.00';

        // Split the product description if it exceeds the column width
        List<String> descriptionLines =
            splitText(productDescription, columnWidth2);

        for (int j = 0; j < descriptionLines.length; j++) {
          String line;
          if (j == 0) {
            // For the first line, include all columns
            line = "${(i + 1).toString().padRight(columnWidth1)}"
                "${descriptionLines[j].padRight(columnWidth2)}"
                "${productUnit.padRight(columnWidth3)}"
                "${productQty.padRight(columnWidth4)}"
                // "${productType.padRight(columnWidth5)}"
                " ${productRate.padRight(columnWidth6)}"
                "${productTotal.padRight(columnWidth7)} "
                "${productTax.padRight(columnWidth8)}"
                "${productAmount.padLeft(columnWidth9)}";
          } else {
            // For subsequent lines, only include the description, leaving other columns blank
            line = "${''.padRight(columnWidth1)}"
                "${descriptionLines[j].padRight(columnWidth2)}"
                "${''.padRight(columnWidth3)}"
                "${''.padRight(columnWidth4)}"
                // "${''.padRight(columnWidth5)}"
                "${''.padRight(columnWidth6)}"
                "${''.padRight(columnWidth7)}";
            "${''.padRight(columnWidth8)}";
            "${''.padRight(columnWidth9)}";
          }
          printer.printCustom(line, 1, 0); // Left aligned
        }
      }
      printer.printCustom("-" * 70, 1, 1); // Centered
      double total = (invoice.data!.total ?? 0).toDouble();
      double discount = (invoice.data!.discount ?? 0).toDouble();
      double subTotal = total - discount;
      printAlignedText(
          "", "Total: ${total.toStringAsFixed(AppState().noOfDecimals ?? 2)}");
      if (Discount.isNotEmpty) {
        print(Discount);
        printAlignedText("Van: $van", "$Discount");
      } else {
        printAlignedText("Van: $van", ""); // Skip printing Total
      }
      printAlignedText("Salesman: $salesman",
          "Sub Total: ${subTotal.toStringAsFixed(AppState().noOfDecimals ?? 2)}");
      printAlignedText("", "Vat: $tax");
      printAlignedText("", "Grand Total: $grandTotal"); // Right aligned
      printer.printNewLine();
      printer.printCustom(amountInWords, 1, 0); // Centered

      // Cut the paper
      printer.paperCut();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printer not connected')),
      );
    }
  }

  Future<String> _getImageData(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes.toString();
      } else {
        print("Failed to load image: ${response.statusCode}");
        return '';
      }
    } catch (e) {
      print("Error fetching image: $e");
      return '';
    }
  }

 Future<void> _createPdf(Invoice.InvoiceData invoice, bool isPrint) async {
    PdfDocument document = PdfDocument();
    final page = document.pages.add();
    final Size pageSize = page.getClientSize();
    final double pageWidth = pageSize.width;

    // 👇 MOVED TO TOP — declared before any use, fixes
    // "referenced_before_declaration" error.
    String _sanitizeArabicText(String input) {
      final buffer = StringBuffer();
      for (final rune in input.runes) {
        final isArabic = (rune >= 0x0600 && rune <= 0x06FF) ||
            (rune >= 0x0750 && rune <= 0x077F) ||
            (rune >= 0x08A0 && rune <= 0x08FF) ||
            (rune >= 0xFB50 && rune <= 0xFDFF) ||
            (rune >= 0xFE70 && rune <= 0xFEFF);
        final isBasicLatinPrintable = rune >= 0x0020 && rune <= 0x007E;
        if (isArabic || isBasicLatinPrintable) {
          buffer.writeCharCode(rune);
        }
      }
      return buffer.toString();
    }

    // Strips any character that PdfStandardFont (Helvetica/WinAnsi) can't
    // render - smart quotes, dashes, bullets, or other special characters
    // copy-pasted from Word/WhatsApp into address/footer/remarks fields.
    // Prevents "The character is not supported by the font" crashes.
    String _sanitizeForPdfFont(String? input) {
      if (input == null) return '';
      final buffer = StringBuffer();
      for (final rune in input.runes) {
        if (rune == 0x0A || rune == 0x0D) {
          buffer.writeCharCode(rune);
        } else if (rune >= 0x0020 && rune <= 0x00FF) {
          buffer.writeCharCode(rune);
        } else {
          switch (rune) {
            case 0x2018:
            case 0x2019:
              buffer.write("'");
              break;
            case 0x201C:
            case 0x201D:
              buffer.write('"');
              break;
            case 0x2013:
            case 0x2014:
              buffer.write('-');
              break;
            case 0x2026:
              buffer.write('...');
              break;
            default:
              break;
          }
        }
      }
      return buffer.toString();
    }

    // Load logo (right side)
    final Uint8List? imageData =
        await _readImageData(invoice.data!.store![0].logo);
    if (imageData != null && imageData.isNotEmpty) {
      final PdfBitmap image = PdfBitmap(imageData);
      page.graphics.drawImage(
        image,
        Rect.fromLTWH(pageWidth - 100, 30, 80, 80),
      );
    }

    // Left-aligned company info
    final String companyName = _sanitizeForPdfFont(
        invoice.data!.store![0].invoice_company_name ?? '');

    final String companyNameAr = invoice.data!.store![0].name_ar ?? '';
    final String rawAddress =
        _sanitizeForPdfFont(invoice.data!.store![0].address ?? 'N/A');

    page.graphics.drawString(
  companyName,
  PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
  bounds: Rect.fromLTWH(0, 30, pageWidth - 150, 30),
);
    double currentY = 60;
print('companyNameAr value: "$companyNameAr"');
// AFTER
    if (companyNameAr.trim().isNotEmpty) {
      try {
        final String cleanNameAr = _sanitizeArabicText(companyNameAr);
        final PdfFont arabicFont =
            await _loadArabicPdfFont(14, style: PdfFontStyle.bold);
     // AFTER
page.graphics.drawString(
  cleanNameAr,
  arabicFont,
  brush: PdfSolidBrush(PdfColor(0, 0, 0)),
  bounds: Rect.fromLTWH(0, currentY, pageWidth - 200, 25),
  format: PdfStringFormat(
    alignment: PdfTextAlignment.left,
    textDirection: PdfTextDirection.rightToLeft,
  ),
);
        currentY += 22;
        print('Arabic name drawn: cleanNameAr="$cleanNameAr" length=${cleanNameAr.length}');
      } catch (e) {
        print('Failed to draw Arabic company name in PDF: $e');
      }
    }

  // AFTER
final PdfFont detailsFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
final double addressWidth = pageWidth - 150;

// measureString with a layoutArea tells us the ACTUAL height the text
// will occupy after word-wrap — fixes overlap when address is long.
final Size addressSize = detailsFont.measureString(
  rawAddress,
  layoutArea: Size(addressWidth, 500), // generous max height cap
);

page.graphics.drawString(
  rawAddress,
  detailsFont,
  bounds: Rect.fromLTWH(0, currentY, addressWidth, addressSize.height),
);
currentY += addressSize.height + 5;
   final String? name = invoice.data!.store![0].invoice_heading ?? '';
    final String text = '$name';

    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 15);
    final Size textSize = font.measureString(text);
    String customerTRN =
        invoice.data?.customer?.firstOrNull?.trn ?? '';
    final double xPosition = (pageWidth - textSize.width) / 2;
    // Dynamic instead of fixed 165 - stores with longer addresses (more
    // lines, or with the extra Arabic name line) push currentY further
    // down, and the heading needs to sit below that, not at a fixed spot.
    // 120 is the floor so short-address stores keep the old spacing.
   // AFTER
final double yPosition =
    currentY + 15 > 150 ? currentY + 15 : 150.0;
    page.graphics.drawString(
      text,
      font,
      bounds:
          Rect.fromLTWH(xPosition, yPosition, textSize.width, textSize.height),
    );

  // AFTER
final remarks = invoice.data?.remarks;
final double lineYPosition = yPosition + textSize.height + 10;
page.graphics.drawLine(
  PdfPen(PdfColor(0, 0, 0)),
  Offset(0, lineYPosition),
  Offset(pageWidth, lineYPosition),
);

// ✅ wrapped with _sanitizeForPdfFont
String address = _sanitizeForPdfFont('''
Customer: ${invoice.data!.customer![0].code} | ${invoice.data!.customer![0].name}
Email: ${invoice.data!.customer![0].email}
Contact No: ${invoice.data!.customer![0].contactNumber}
${invoice.data?.store?.firstOrNull?.vat_label}: $customerTRN
${invoice.data!.cashCard != null && invoice.data!.cashCard!.isNotEmpty ? 'Bill Type: ${invoice.data!.cashCard}' : ''}
''');

// ✅ wrapped with _sanitizeForPdfFont
String invoiceDetails = _sanitizeForPdfFont('''
  Invoice No: ${invoice.data!.invoiceNo!}
  Date: ${DateHelper.displayDate(invoice.data!.inDate)}
  Due Date: ${DateHelper.displayDate(invoice.data!.inDate)}
  Time: ${invoice.data!.inTime}
  ${remarks != null ? remarks : ''}
  ''');

final PdfFont detailsBlockFont = PdfStandardFont(PdfFontFamily.helvetica, 12);

// Starting Y for Customer/Invoice block is now BELOW the heading line,
// not a fixed 200 — fixes overlap when address/heading pushed down.
final double detailsBlockY = lineYPosition + 10;

final Size addressBlockSize = detailsBlockFont.measureString(
  address,
  layoutArea: Size(pageWidth / 2 - 10, 300),
);
final Size invoiceDetailsBlockSize = detailsBlockFont.measureString(
  invoiceDetails,
  layoutArea: Size(pageWidth / 2, 300),
);

page.graphics.drawString(
  address,
  detailsBlockFont,
  bounds: Rect.fromLTWH(0, detailsBlockY, pageWidth / 2, addressBlockSize.height),
);

page.graphics.drawString(
  invoiceDetails,
  detailsBlockFont,
  bounds: Rect.fromLTWH(pageWidth / 2, detailsBlockY, pageWidth / 2, invoiceDetailsBlockSize.height),
  format: PdfStringFormat(alignment: PdfTextAlignment.right),
);

// Second separator line now sits below whichever block (address or
// invoice details) is taller — dynamic instead of fixed 290.
final double secondLineY = detailsBlockY +
    (addressBlockSize.height > invoiceDetailsBlockSize.height
        ? addressBlockSize.height
        : invoiceDetailsBlockSize.height) +
    10;

page.graphics.drawLine(
  PdfPen(PdfColor(0, 0, 0)),
  Offset(0, secondLineY),
  Offset(pageWidth, secondLineY),
);

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 9);
    grid.columns[0].width = 30;
    grid.columns[1].width = 180;
    grid.columns[2].width = 35;
    grid.columns[3].width = 30;
    grid.columns[4].width = 35;
    grid.columns[5].width = 53;
    grid.columns[6].width = 50;
    grid.columns[7].width = 50;
    grid.columns[8].width = 82;

    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'Sl.No';
    headerRow.cells[1].value = 'Product';
    headerRow.cells[2].value = 'Unit';
    headerRow.cells[3].value = 'Qty';
    headerRow.cells[4].value = 'Type';
    headerRow.cells[5].value = 'Rate';
    headerRow.cells[6].value = 'Total';
    headerRow.cells[7].value = 'Vat';
    headerRow.cells[8].value = 'Amount   ';
// AFTER
for (int k = 0; k < invoice.data!.detail!.length; k++) {
  final PdfGridRow row = grid.rows.add();
  row.cells[0].value = '${k + 1}';
  row.cells[1].value = _sanitizeForPdfFont('${invoice.data!.detail![k].name}');
  row.cells[2].value = _sanitizeForPdfFont('${invoice.data!.detail![k].unit}');
  row.cells[3].value = '${invoice.data!.detail![k].quantity}';
  row.cells[4].value = (invoice.data!.detail![k].productType!
                      .toLowerCase() ==
                  "foc" ||
          invoice.data!.detail![k].productType!.toLowerCase() == "FOC" ||
          invoice.data!.detail![k].productType!.toLowerCase() == "Change")
      ? 'Normal'
      : 'Normal';
  row.cells[5].value =
      '${invoice.data!.detail![k].mrp?.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
  row.cells[6].value =
      '${invoice.data!.detail![k].taxable?.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
  row.cells[7].value =
      '${invoice.data!.detail![k].taxAmt?.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
  row.cells[8].value =
      '${invoice.data!.detail![k].amount?.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
}

    final PdfBorders noBorder = PdfBorders(
      left: PdfPen(PdfColor(255, 255, 255), width: 0),
      top: PdfPen(PdfColor(255, 255, 255), width: 0),
      right: PdfPen(PdfColor(255, 255, 255), width: 0),
      bottom: PdfPen(PdfColor(255, 255, 255), width: 0),
    );

    for (int j = 0; j < grid.headers.count; j++) {
      for (int k = 0; k < grid.headers[j].cells.count; k++) {
        grid.headers[j].cells[k].style.borders = noBorder;
      }
    }

    for (int i = 0; i < grid.rows.count; i++) {
      for (int j = 0; j < grid.columns.count; j++) {
        grid.rows[i].cells[j].style.borders = noBorder;
      }
    }

// AFTER
final PdfLayoutResult result = grid.draw(
  page: page,
  bounds: Rect.fromLTWH(0, secondLineY + 10, pageSize.width, pageSize.height - (secondLineY + 10) - 20),
)!;
    PdfPage lastPage = result.page;
    double tableBottom = result.bounds.bottom;

    if (tableBottom >= pageSize.height) {
      lastPage = document.pages.add();
      tableBottom = 0;
    }

    lastPage.graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0)),
      Offset(0, tableBottom + 15),
      Offset(pageSize.width, tableBottom + 15),
    );

    // ✅ wrapped with _sanitizeForPdfFont
    String bottomInvoiceDetails = _sanitizeForPdfFont('''
    ${invoice.data!.discount != null && invoice.data!.discount! > 0 ? 'Discount: ${invoice.data!.discount!.toStringAsFixed(AppState().noOfDecimals ?? 2)}' : '\t'}
  Sub Total: ${invoice.data!.total ?? ''}
  Vat: ${invoice.data!.totalTax?.toStringAsFixed(AppState().noOfDecimals ?? 2)}
  ${'${invoice.data!.roundOff}' != 0 ? 'Round off:${double.parse(invoice.data!.roundOff ?? '').toStringAsFixed(AppState().noOfDecimals ?? 2)}\nGrand Total: ${invoice.data!.grandTotal?.toStringAsFixed(AppState().noOfDecimals ?? 2)}' : 'Grand Total: ${invoice.data!.grandTotal}'}


  ''');
    print('invoice.data!.discounted_amount');
    print(invoice.data!.discounted_amount);

    lastPage.graphics.drawString(
      bottomInvoiceDetails,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(
        pageSize.width / 2,
        tableBottom + 20,
        pageSize.width / 2,
        100,
      ),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );

    String numberToWords(int number) {
      if (number == 0) return "zero";
      const List<String> belowTwenty = [
        "", "one", "two", "three", "four", "five", "six", "seven", "eight",
        "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
        "sixteen", "seventeen", "eighteen", "nineteen"
      ];
      const List<String> tens = [
        "", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy",
        "eighty", "ninety"
      ];
      const List<String> thousands = ["", "thousand", "million", "billion"];
      String words = "";
      int thousandCounter = 0;
      while (number > 0) {
        int currentPart = number % 1000;
        if (currentPart > 0) {
          String partWords = "";
          if (currentPart >= 100) {
            partWords += belowTwenty[currentPart ~/ 100] + " hundred ";
            currentPart %= 100;
          }
          if (currentPart >= 20) {
            partWords += tens[currentPart ~/ 10] + " ";
            currentPart %= 10;
          }
          if (currentPart > 0) {
            partWords += belowTwenty[currentPart] + " ";
          }
          words = partWords + thousands[thousandCounter] + " " + words;
        }
        number ~/= 1000;
        thousandCounter++;
      }
      return words.trim();
    }

    String amountToWords(double amount) {
      int wholePart = amount.floor();
      int decimalPart = ((amount - wholePart) * 1000).round();
      String words = numberToWords(wholePart).toUpperCase();
      if (decimalPart > 0) {
        words += " POINT ${numberToWords(decimalPart).toUpperCase()}";
      }
      return words;
    }

    double vanDetailsTop = tableBottom + 20 + 100 + 10;

    // ✅ wrapped with _sanitizeForPdfFont
   String vanName = invoice.data?.van?.firstOrNull?.name ?? 'N/A';
String salesmanName = invoice.data?.user?.firstOrNull?.name ?? 'N/A';
String bottomVanDetails = _sanitizeForPdfFont('''
Van: $vanName
Salesman: $salesmanName
''');

    lastPage.graphics.drawString(
      bottomVanDetails,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(0, vanDetailsTop, pageSize.width / 2, 100),
      format: PdfStringFormat(alignment: PdfTextAlignment.left),
    );

    final PdfStandardFont sfont = PdfStandardFont(PdfFontFamily.helvetica, 12);

    // ✅ wrapped with _sanitizeForPdfFont
    String textData = _sanitizeForPdfFont('Amount in Words: ${AppState().code} '
        '${amountToWords(invoice.data!.grandTotal!.toDouble())} ONLY');
    String? infoot = _sanitizeForPdfFont(invoice.data!.store![0].invoice_footer);

    final double textDataHeight = sfont.measureString(textData).height;
    final double infootHeight = sfont.measureString(infoot).height;

    final double syPosition =
        pageSize.height - textDataHeight - infootHeight - 20;

    lastPage.graphics.drawString(
      textData,
      sfont,
      bounds: Rect.fromLTWH(0, syPosition, pageSize.width, textDataHeight),
      format: PdfStringFormat(alignment: PdfTextAlignment.left),
    );

    lastPage.graphics.drawString(
      infoot,
      sfont,
      bounds: Rect.fromLTWH(
        0,
        syPosition + textDataHeight + 5,
        pageSize.width,
        infootHeight,
      ),
      format: PdfStringFormat(alignment: PdfTextAlignment.left),
    );
    List<int> bytes = await document.save();
    document.dispose();

  // AFTER (temporary test only)
String file = await saveAndLaunchFile(
    bytes, '${invoice.data!.invoiceNo!}_${DateTime.now().millisecondsSinceEpoch}.pdf', isPrint);
  }
Future<void> _wifiPdf(Invoice.InvoiceData invoice, bool isPrint) async {
    // Same guard as _createPdf() - strips characters PdfStandardFont can't
    // render. Declared here at the top since _wifiPdf() has its own scope.
    String _sanitizeForPdfFont(String? input) {
      if (input == null) return '';
      final buffer = StringBuffer();
      for (final rune in input.runes) {
        if (rune == 0x0A || rune == 0x0D) {
          buffer.writeCharCode(rune);
        } else if (rune >= 0x0020 && rune <= 0x00FF) {
          buffer.writeCharCode(rune);
        } else {
          switch (rune) {
            case 0x2018:
            case 0x2019:
              buffer.write("'");
              break;
            case 0x201C:
            case 0x201D:
              buffer.write('"');
              break;
            case 0x2013:
            case 0x2014:
              buffer.write('-');
              break;
            case 0x2026:
              buffer.write('...');
              break;
            default:
              break;
          }
        }
      }
      return buffer.toString();
    }

    PdfDocument document = PdfDocument();
    final page = document.pages.add();
    final pageSize = Size(595.0, 842.0);
    final double pageWidth = page.getClientSize().width;
    final String text = 'TAX INVOICE';
    final PdfFont headfont = PdfStandardFont(PdfFontFamily.helvetica, 15);
    final Size headtextSize = headfont.measureString(text);
    final double headxPosition = (pageWidth - headtextSize.width) / 2.0;
    final double headyPosition = 100;
    page.graphics.drawString(
      text,
      headfont,
      bounds: Rect.fromLTWH(headxPosition, headyPosition, headtextSize.width,
          headtextSize.height),
    );
    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 15);
    final Size textSize = font.measureString(text);
    final double yPosition = 120;

    final remarks = invoice.data?.remarks;
    final double lineYPosition = yPosition + textSize.height + 10;
    page.graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0)),
      Offset(0, lineYPosition),
      Offset(pageWidth, lineYPosition),
    );

    // ✅ wrapped with _sanitizeForPdfFont
    String address = _sanitizeForPdfFont('''
  Customer: ${invoice.data!.customer![0].code} | ${invoice.data!.customer![0].name}
  Email: ${invoice.data!.customer![0].email}
  Contact No:  ${invoice.data!.customer![0].contactNumber}
  VAT Label:  ${invoice.data!.customer![0].trn ?? ''}
  ''');

    // ✅ wrapped with _sanitizeForPdfFont
    String invoiceDetails = _sanitizeForPdfFont('''
  Invoice No: ${invoice.data!.invoiceNo!}
  Date: ${DateHelper.displayDate(invoice.data!.inDate)}
  ${remarks != null ? remarks : ''}
  ''');
    page.graphics.drawString(
      address,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
     bounds: Rect.fromLTWH(0, 160, pageSize.width / 2, 100),
    );

    page.graphics.drawString(
      invoiceDetails,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(pageSize.width / 2.8, 160, pageSize.width / 2, 100),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );

    page.graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0)),
      const Offset(0, 250),
      Offset(pageSize.width, 250),
    );

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 11);
    grid.columns[0].width = 35;
    grid.columns[1].width = 125;
    grid.columns[2].width = 28;
    grid.columns[3].width = 24;
    grid.columns[4].width = 37;
    grid.columns[5].width = 40;
    grid.columns[6].width = 48;
    grid.columns[7].width = 50;
    grid.columns[8].width = 27;
    grid.columns[9].width = 50;
    grid.columns[10].width = 50;

    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'Sl.No';
    headerRow.cells[1].value = 'Product';
    headerRow.cells[2].value = 'Unit';
    headerRow.cells[3].value = 'Qty';
    headerRow.cells[4].value = 'Rate';
    headerRow.cells[5].value = 'Rate\nIncl Vat';
    headerRow.cells[6].value = 'Amount';
    headerRow.cells[7].value = 'Taxable\nAmount';
    headerRow.cells[8].value = 'Vat\nRate';
    headerRow.cells[9].value = 'Vat\nAmount';
    headerRow.cells[10].value = 'Total\nIncl Vat';

    for (int i = 0; i < headerRow.cells.count; i++) {
      headerRow.cells[i].style = PdfGridCellStyle(
        font: PdfStandardFont(PdfFontFamily.helvetica, 12,
            style: PdfFontStyle.bold),
        borders: PdfBorders(
          left: PdfPen(PdfColor(0, 0, 0)),
          top: PdfPen(PdfColor(0, 0, 0)),
          right: PdfPen(PdfColor(0, 0, 0)),
          bottom: PdfPen(PdfColor(0, 0, 0)),
        ),
      );
    }

    for (int k = 0; k < invoice.data!.detail!.length; k++) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = '${k + 1}';
     // AFTER
row.cells[1].value = _sanitizeForPdfFont('${invoice.data!.detail![k].name}');
row.cells[2].value = _sanitizeForPdfFont('${invoice.data!.detail![k].unit}');
      row.cells[3].value = '${invoice.data!.detail![k].quantity}';
      row.cells[4].value =
          '${invoice.data!.detail![k].mrp?.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
      num lineTaxPercentK = invoice.data!.detail![k].taxPercentage ?? 0;
      row.cells[5].value =
          '${(invoice.data!.detail![k].mrp! * (1 + (lineTaxPercentK / 100))).toStringAsFixed(AppState().noOfDecimals ?? 2)}';
      row.cells[6].value =
          '${invoice.data!.detail![k].taxable?.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
      row.cells[7].value =
          '${invoice.data!.detail![k].taxable?.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
      row.cells[8].value = '${invoice.data!.detail![k].taxPercentage ?? 0}%';
      row.cells[9].value =
          '${invoice.data!.detail![k].taxAmt?.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
      row.cells[10].value =
          '${invoice.data!.detail![k].amount?.toStringAsFixed(AppState().noOfDecimals ?? 2)}';

      final PdfStringFormat centerFormat = PdfStringFormat(
        alignment: PdfTextAlignment.center,
      );

      for (int i = 0; i < row.cells.count; i++) {
        row.cells[i].style = PdfGridCellStyle(
          font: PdfStandardFont(PdfFontFamily.helvetica, 12),
          borders: PdfBorders(
            left: PdfPen(PdfColor(0, 0, 0)),
            top: PdfPen(PdfColor(255, 255, 255)),
            right: PdfPen(PdfColor(0, 0, 0)),
            bottom: PdfPen(PdfColor(255, 255, 255)),
          ),
          format: (i == 1) ? null : centerFormat,
        );
      }
    }

  // AFTER
// AFTER
final PdfLayoutResult result = grid.draw(
  page: page,
  bounds: Rect.fromLTWH(0, 270, pageSize.width, pageSize.height - 270 - 20),
)!;

    PdfPage lastPage = result.page;
    double tableBottom = result.bounds.bottom;

    lastPage.graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0)),
      Offset(0, tableBottom + 5),
      Offset(pageSize.width, tableBottom + 5),
    );

    if (tableBottom >= pageSize.height) {
      lastPage = document.pages.add();
      tableBottom = 0;
    }

    double total = (invoice.data!.total ?? 0).toDouble();
    double discount = (invoice.data!.discount ?? 0).toDouble();
    double subTotal = total - discount;

    // ✅ wrapped with _sanitizeForPdfFont
    String bottomInvoiceDetails = _sanitizeForPdfFont('''
Total: ${total.toStringAsFixed(AppState().noOfDecimals ?? 2)}    
${(invoice.data!.discount ?? 0) > 0 ? 'Discount: ${(invoice.data!.discount ?? 0).toStringAsFixed(AppState().noOfDecimals ?? 2)}' : '\t'}
Sub Total: ${subTotal.toStringAsFixed(AppState().noOfDecimals ?? 2)}
Vat: ${invoice.data!.totalTax?.toStringAsFixed(AppState().noOfDecimals ?? 2)}
${'${invoice.data!.roundOff}' != '0' ? 'Round off: ${double.parse(invoice.data!.roundOff ?? '0').toStringAsFixed(AppState().noOfDecimals ?? 2)}\nGrand Total: ${invoice.data!.grandTotal?.toStringAsFixed(AppState().noOfDecimals ?? 2)}' : 'Grand Total: ${invoice.data!.grandTotal}'}
''');

    lastPage.graphics.drawString(
      bottomInvoiceDetails,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(
        pageSize.width / 2,
        tableBottom + 20,
        pageSize.width / 2.8,
        100,
      ),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );

    double vanDetailsTop = tableBottom + 20 + 100 + 10;

    // ✅ wrapped with _sanitizeForPdfFont
    String bottomVanDetails = _sanitizeForPdfFont('''
Van: ${invoice.data!.van![0].name}
Salesman: ${invoice.data!.user![0].name}
''');

    lastPage.graphics.drawString(
      bottomVanDetails,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(0, vanDetailsTop, pageSize.width / 2, 100),
      format: PdfStringFormat(alignment: PdfTextAlignment.left),
    );

    String numberToWords(int number) {
      if (number == 0) return "zero";
      const List<String> belowTwenty = [
        "", "one", "two", "three", "four", "five", "six", "seven", "eight",
        "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
        "sixteen", "seventeen", "eighteen", "nineteen"
      ];
      const List<String> tens = [
        "", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy",
        "eighty", "ninety"
      ];
      const List<String> thousands = ["", "thousand", "million", "billion"];
      String words = "";
      int thousandCounter = 0;
      while (number > 0) {
        int currentPart = number % 1000;
        if (currentPart > 0) {
          String partWords = "";
          if (currentPart >= 100) {
            partWords += belowTwenty[currentPart ~/ 100] + " hundred ";
            currentPart %= 100;
          }
          if (currentPart >= 20) {
            partWords += tens[currentPart ~/ 10] + " ";
            currentPart %= 10;
          }
          if (currentPart > 0) {
            partWords += belowTwenty[currentPart] + " ";
          }
          words = partWords + thousands[thousandCounter] + " " + words;
        }
        number ~/= 1000;
        thousandCounter++;
      }
      return words.trim();
    }

    final PdfStandardFont sfont = PdfStandardFont(PdfFontFamily.helvetica, 12);

    // ✅ wrapped with _sanitizeForPdfFont
    String textData = _sanitizeForPdfFont(
        'Amount in Words: ${AppState().code} ${numberToWords(invoice.data!.grandTotal!.toInt()).toUpperCase()} ONLY');
    String? infoot = _sanitizeForPdfFont(invoice.data!.store![0].invoice_footer);

    final double textDataHeight = sfont.measureString(textData).height;
    final double infootHeight = sfont.measureString(infoot).height;

    final double syPosition =
        pageSize.height - textDataHeight - infootHeight - 100;

    lastPage.graphics.drawString(
      textData,
      sfont,
      bounds: Rect.fromLTWH(0, syPosition, pageSize.width, textDataHeight),
      format: PdfStringFormat(alignment: PdfTextAlignment.left),
    );

    lastPage.graphics.drawString(
      infoot,
      sfont,
      bounds: Rect.fromLTWH(
        0,
        syPosition + textDataHeight + 5,
        pageSize.width,
        infootHeight,
      ),
      format: PdfStringFormat(alignment: PdfTextAlignment.left),
    );

    List<int> bytes = await document.save();
    document.dispose();

    String file = await saveAndLaunchFile(
        bytes, '${invoice.data!.invoiceNo!}.pdf', isPrint);
  }
 Future<Uint8List> _readImageData(String? image) async {
  if (image == null || image.isEmpty) return Uint8List(0);

  // ── NEW: serve from cache if we've already downloaded this logo,
  // instead of hitting the network again on every PDF tap ──
  if (_logoCache.containsKey(image)) {
    return _logoCache[image]!;
  }

  try {
    final response = await http
        .get(Uri.parse('${RestDatasource().Image_URL}/uploads/store/$image'));

    print('Response Data $response');

    if (response.statusCode == 200) {
      _logoCache[image] = response.bodyBytes; // ── NEW: store in cache ──
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image');
    }
  } catch (e) {
    print('Error loading image: $e');
    return Uint8List(0);
  }
}
  Future<void> _getInvoiceData(int id, bool isPrint) async {
  // ── NEW: immediate feedback the moment the icon is tapped, so the
  // network fetch + PDF build time doesn't feel like the app froze ──
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    Invoice.InvoiceData invoice = Invoice.InvoiceData();
    RestDatasource api = RestDatasource();
    dynamic response = await api.getDetails(
        '/api/get_sales_invoice?id=$id', AppState().token);
    print("IIDD$id");
    debugPrint(jsonEncode(response));
    if (response['data'] != null) {
      print("DDDDDD${id}");
      invoice = Invoice.InvoiceData.fromJson(response);
        print('VAN LIST LENGTH: ${invoice.data?.van?.length}');
  print('VAN LIST: ${invoice.data?.van}');
      await _createPdf(invoice, isPrint);
    }
  } catch (e, st) {
    print('Error generating PDF: $e');
    print(st);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  } finally {
    // ── NEW: always close the spinner, success or failure ──
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

Future<void> _getwifiInvoiceData(int id, bool isPrint) async {
  // ── NEW: same spinner pattern as _getInvoiceData ──
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    Invoice.InvoiceData invoice = Invoice.InvoiceData();
    RestDatasource api = RestDatasource();
    dynamic response = await api.getDetails(
        '/api/get_sales_invoice?id=$id', AppState().token);
    if (response['data'] != null) {
      print("DDDDDD${id}");
      invoice = Invoice.InvoiceData.fromJson(response);
      await _wifiPdf(invoice, isPrint);
    }
  } catch (e, st) {
    print('Error generating WiFi PDF: $e');
    print(st);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  } finally {
    // ── NEW: always close the spinner, success or failure ──
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

  Future<void> _getInvoiceDataprint(int id, bool isPrint) async {
    try {
      Invoice.InvoiceData invoice = Invoice.InvoiceData();
      RestDatasource api = RestDatasource();
      dynamic response = await api.getDetails(
          '/api/get_sales_invoice?id=$id', AppState().token);
      print("IIDD$id");
      if (response['data'] != null) {
        print("IIDD$id");
        invoice = Invoice.InvoiceData.fromJson(response);
      }
      if (_selectedDevice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Default device not found')),
        );
        return;
      }
      if (!_connected) {
        await _connect();
      }
      _print(invoice, isPrint);
    } catch (e, st) {
      print('Error printing invoice: $e');
      print(st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing invoice: $e')),
        );
      }
    }
  }
}

// Data models (VanSaleResponse, VanSale, etc.) remain unchanged.

class VanSaleResponse {
  bool? success;
  VanSaleData? data;
  List<String>? messages;

  VanSaleResponse({this.success, this.data, this.messages});

  factory VanSaleResponse.fromJson(Map<String, dynamic> json) {
    return VanSaleResponse(
      success: json['success'],
      data: VanSaleData.fromJson(json['data']), // Handle 'data' as an object
      messages: List<String>.from(
          json['messages'] ?? []), // Ensure messages is not null
    );
  }
}

class VanSaleData {
  final int currentPage;
  final List<VanSale> vanSales;
  final String firstPageUrl;
  final String lastPageUrl;
  final String nextPageUrl;
  final String prevPageUrl;
  final int total;
  final int perPage;
  final int lastPage;

  VanSaleData({
    required this.currentPage,
    required this.vanSales,
    required this.firstPageUrl,
    required this.lastPageUrl,
    required this.nextPageUrl,
    required this.prevPageUrl,
    required this.total,
    required this.perPage,
    required this.lastPage,
  });

  factory VanSaleData.fromJson(Map<String, dynamic> json) {
    return VanSaleData(
      currentPage: json['current_page'],
      vanSales: (json['data'] as List).map((e) => VanSale.fromJson(e)).toList(),
      firstPageUrl: json['first_page_url'],
      lastPageUrl: json['last_page_url'],
      nextPageUrl: json['next_page_url'] ?? '',
      prevPageUrl: json['prev_page_url'] ?? '',
      total: json['total'],
      perPage: json['per_page'],
      lastPage: json['last_page'],
    );
  }
}

class VanSale {
  int? id;
  int? customerId;
  String? billMode;
  String? inDate;
  String? inTime;
  String? invoiceNo;
  String? deliveryNo;
  num? otherCharge;
  num? discount;
  String? roundOff;
  String? discount_type;
  num? total;
  num? totalTax;
  num? grandTotal;
  num? receipt;
  num? balance;
  num? orderType;
  num? ifVat;
  num? vanId;
  num? userId;
  num? storeId;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  List<Detail>? detail;
  List<Customer>? customer;
  List<Customer>? customerdata;

  VanSale(
      {this.id,
      this.customerId,
      this.billMode,
      this.inDate,
      this.inTime,
      this.invoiceNo,
      this.discount_type,
      this.deliveryNo,
      this.otherCharge,
      this.discount,
      this.roundOff,
      this.total,
      this.totalTax,
      this.grandTotal,
      this.receipt,
      this.balance,
      this.orderType,
      this.ifVat,
      this.vanId,
      this.userId,
      this.storeId,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.deletedAt,
      this.detail,
      this.customer,
      this.customerdata});

  VanSale.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    customerId = json['customer_id'];
    billMode = json['bill_mode'] ?? '';
    inDate = json['in_date'] ?? '';
    inTime = json['in_time'] ?? '';
    invoiceNo = json['invoice_no'] ?? '';
    deliveryNo = json['delivery_no'] ?? '';
    otherCharge = json['other_charge'] ?? 0;
    discount = json['discount'] ?? 0;
    discount_type = json['discount_type'] ?? '';
    roundOff = json['round_off'] ?? '';
    total = json['total'] ?? 0;
    totalTax = json['total_tax'] ?? 0;
    grandTotal = json['grand_total'] ?? 0;
    receipt = json['receipt'] ?? 0;
    balance = json['balance'] ?? 0;
    orderType = json['order_type'] ?? 0;
    ifVat = json['if_vat'] ?? 0;
    vanId = json['van_id'] ?? 0;
    userId = json['user_id'] ?? 0;
    storeId = json['store_id'] ?? 0;
    status = json['status'] ?? 0;
    createdAt = json['created_at'] ?? '';
    updatedAt = json['updated_at'] ?? '';
    deletedAt = json['deleted_at'] ?? '';

    if (json['detail'] != null) {
      detail = <Detail>[];
      json['detail'].forEach((v) {
        detail!.add(Detail.fromJson(v));
      });
    }

    if (json['customer'] != null) {
      customer = <Customer>[];
      json['customer'].forEach((v) {
        customer!.add(new Customer.fromJson(v));
      });
    } else if (json['customerdata'] != null) {
      customer = <Customer>[];
      customer!.add(new Customer.fromJson(json['customerdata']));
    }
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['customer_id'] = this.customerId;
    data['bill_mode'] = this.billMode;
    data['in_date'] = this.inDate;
    data['in_time'] = this.inTime;
    data['invoice_no'] = this.invoiceNo;
    data['delivery_no'] = this.deliveryNo;
    data['other_charge'] = this.otherCharge;
    data['discount'] = this.discount;
    data['round_off'] = this.roundOff;
    data['total'] = this.total;
    data['total_tax'] = this.totalTax;
    data['grand_total'] = this.grandTotal;
    data['receipt'] = this.receipt;
    data['balance'] = this.balance;
    data['order_type'] = this.orderType;
    data['if_vat'] = this.ifVat;
    data['van_id'] = this.vanId;
    data['user_id'] = this.userId;
    data['store_id'] = this.storeId;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    if (this.detail != null) {
      data['detail'] = this.detail!.map((v) => v.toJson()).toList();
    }
    if (this.customer != null) {
      data['customer'] = this.customer!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Detail {
  int? id;
  int? goodsOutId;
  int? itemId;
  String? productType;
  String? unit;
  num? convertQty;
  num? quantity;
  num? rate;
  num? prodiscount;
  num? taxable;
  num? taxAmt;
  num? mrp;
  num? amount;
  int? vanId;
  int? userId;
  int? storeId;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  String? code;
  String? name;
  String? proImage;
  int? categoryId;
  int? subCategoryId;
  int? brandId;
  int? supplierId;
  int? taxId;
  num? taxPercentage;
  num? taxInclusive;
  num? price;
  int? baseUnitId;
  int? baseUnitQty;
  String? baseUnitDiscount;
  String? baseUnitBarcode;
  num? baseUnitOpStock;
  String? secondUnitPrice;
  int? secondUnitId;
  int? secondUnitQty;
  String? secondUnitDiscount;
  String? secondUnitBarcode;
  String? secondUnitOpStock;
  String? thirdUnitPrice;
  int? thirdUnitId;
  int? thirdUnitQty;
  String? thirdUnitDiscount;
  String? thirdUnitBarcode;
  String? thirdUnitOpStock;
  String? fourthUnitPrice;
  int? fourthUnitId;
  int? fourthUnitQty;
  String? fourthUnitDiscount;
  int? isMultipleUnit;
  String? fourthUnitOpStock;
  String? description;
  num? productQty;
  num? percentage;

  Detail(
      {this.id,
      this.goodsOutId,
      this.itemId,
      this.productType,
      this.unit,
      this.convertQty,
      this.quantity,
      this.rate,
      this.prodiscount,
      this.taxable,
      this.taxAmt,
      this.mrp,
      this.amount,
      this.vanId,
      this.userId,
      this.storeId,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.deletedAt,
      this.code,
      this.name,
      this.proImage,
      this.categoryId,
      this.subCategoryId,
      this.brandId,
      this.supplierId,
      this.taxId,
      this.taxPercentage,
      this.taxInclusive,
      this.price,
      this.baseUnitId,
      this.baseUnitQty,
      this.baseUnitDiscount,
      this.baseUnitBarcode,
      this.baseUnitOpStock,
      this.secondUnitPrice,
      this.secondUnitId,
      this.secondUnitQty,
      this.secondUnitDiscount,
      this.secondUnitBarcode,
      this.secondUnitOpStock,
      this.thirdUnitPrice,
      this.thirdUnitId,
      this.thirdUnitQty,
      this.thirdUnitDiscount,
      this.thirdUnitBarcode,
      this.thirdUnitOpStock,
      this.fourthUnitPrice,
      this.fourthUnitId,
      this.fourthUnitQty,
      this.fourthUnitDiscount,
      this.isMultipleUnit,
      this.fourthUnitOpStock,
      this.description,
      this.productQty,
      this.percentage});

  Detail.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    goodsOutId = json['goods_out_id'];
    itemId = json['item_id'];
    productType = json['product_type'] ?? '';
    unit = json['unit'] ?? '';
    convertQty = json['convert_qty'] ?? 0;
    quantity = json['quantity'] ?? 0;
    rate = json['rate'] ?? 0;
    prodiscount = json['prodiscount'] ?? 0;
    taxable = json['taxable'] ?? 0;
    taxAmt = json['tax_amt'] ?? 0;
    mrp = json['mrp'] ?? 0;
    amount = json['amount'] ?? 0;
    vanId = json['van_id'] ?? 0;
    userId = json['user_id'] ?? 0;
    storeId = json['store_id'] ?? 0;
    status = json['status'] ?? 0;
    createdAt = json['created_at'] ?? '';
    updatedAt = json['updated_at'] ?? '';
    deletedAt = json['deleted_at'] ?? '';
    code = json['code'] ?? '';
    name = json['name'] ?? '';
    proImage = json['pro_image'] ?? '';
    categoryId = json['category_id'] ?? 0;
    subCategoryId = json['sub_category_id'] ?? 0;
    brandId = json['brand_id'] ?? 0;
    supplierId = json['supplier_id'] ?? 0;
    taxId = json['tax_id'] ?? 0;
    taxPercentage = json['tax_percentage'] ?? 0;
    taxInclusive = json['tax_inclusive'] ?? 0;
    price = json['price'] ?? 0;
    baseUnitId = json['base_unit_id'] ?? 0;
    baseUnitQty = json['base_unit_qty'] ?? 0;
    baseUnitDiscount = json['base_unit_discount'] ?? '';
    baseUnitBarcode = json['base_unit_barcode'] ?? '';
    baseUnitOpStock = json['base_unit_op_stock'] ?? 0;
    secondUnitPrice = json['second_unit_price'] ?? '';
    secondUnitId = json['second_unit_id'] ?? 0;
    secondUnitQty = json['second_unit_qty'] ?? 0;
    secondUnitDiscount = json['second_unit_discount'] ?? '';
    secondUnitBarcode = json['second_unit_barcode'] ?? '';
    secondUnitOpStock = json['second_unit_op_stock'] ?? '';
    thirdUnitPrice = json['third_unit_price'] ?? '';
    thirdUnitId = json['third_unit_id'] ?? 0;
    thirdUnitQty = json['third_unit_qty'] ?? 0;
    thirdUnitDiscount = json['third_unit_discount'] ?? '';
    thirdUnitBarcode = json['third_unit_barcode'] ?? '';
    thirdUnitOpStock = json['third_unit_op_stock'] ?? '';
    fourthUnitPrice = json['fourth_unit_price'] ?? '';
    fourthUnitId = json['fourth_unit_id'] ?? 0;
    fourthUnitQty = json['fourth_unit_qty'] ?? 0;
    fourthUnitDiscount = json['fourth_unit_discount'] ?? '';
    isMultipleUnit = json['is_multiple_unit'] ?? 0;
    fourthUnitOpStock = json['fourth_unit_op_stock'] ?? '';
    description = json['description'] ?? '';
    productQty = json['product_qty'] ?? 0;
    percentage = json['percentage'] ?? 0;
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['goods_out_id'] = this.goodsOutId;
    data['item_id'] = this.itemId;
    data['product_type'] = this.productType;
    data['unit'] = this.unit;
    data['convert_qty'] = this.convertQty;
    data['quantity'] = this.quantity;
    data['rate'] = this.rate;
    data['prodiscount'] = this.prodiscount;
    data['taxable'] = this.taxable;
    data['tax_amt'] = this.taxAmt;
    data['mrp'] = this.mrp;
    data['amount'] = this.amount;
    data['van_id'] = this.vanId;
    data['user_id'] = this.userId;
    data['store_id'] = this.storeId;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    data['code'] = this.code;
    data['name'] = this.name;
    data['pro_image'] = this.proImage;
    data['category_id'] = this.categoryId;
    data['sub_category_id'] = this.subCategoryId;
    data['brand_id'] = this.brandId;
    data['supplier_id'] = this.supplierId;
    data['tax_id'] = this.taxId;
    data['tax_percentage'] = this.taxPercentage;
    data['tax_inclusive'] = this.taxInclusive;
    data['price'] = this.price;
    data['base_unit_id'] = this.baseUnitId;
    data['base_unit_qty'] = this.baseUnitQty;
    data['base_unit_discount'] = this.baseUnitDiscount;
    data['base_unit_barcode'] = this.baseUnitBarcode;
    data['base_unit_op_stock'] = this.baseUnitOpStock;
    data['second_unit_price'] = this.secondUnitPrice;
    data['second_unit_id'] = this.secondUnitId;
    data['second_unit_qty'] = this.secondUnitQty;
    data['second_unit_discount'] = this.secondUnitDiscount;
    data['second_unit_barcode'] = this.secondUnitBarcode;
    data['second_unit_op_stock'] = this.secondUnitOpStock;
    data['third_unit_price'] = this.thirdUnitPrice;
    data['third_unit_id'] = this.thirdUnitId;
    data['third_unit_qty'] = this.thirdUnitQty;
    data['third_unit_discount'] = this.thirdUnitDiscount;
    data['third_unit_barcode'] = this.thirdUnitBarcode;
    data['third_unit_op_stock'] = this.thirdUnitOpStock;
    data['fourth_unit_price'] = this.fourthUnitPrice;
    data['fourth_unit_id'] = this.fourthUnitId;
    data['fourth_unit_qty'] = this.fourthUnitQty;
    data['fourth_unit_discount'] = this.fourthUnitDiscount;
    data['is_multiple_unit'] = this.isMultipleUnit;
    data['fourth_unit_op_stock'] = this.fourthUnitOpStock;
    data['description'] = this.description;
    data['product_qty'] = this.productQty;
    data['percentage'] = this.percentage;
    return data;
  }
}

class Customer {
  int? id;
  String? name;
  String? code;
  dynamic address;
  String? contactNumber;
  String? whatsappNumber;
  String? email;
  String? trn;
  String? custImage;
  String? paymentTerms;
  int? creditLimit;
  int? creditDays;
  int? routeId;
  int? provinceId;
  int? storeId;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  String? erpCustomerCode;

  Customer(
      {this.id,
      this.name,
      this.code,
      this.address,
      this.contactNumber,
      this.whatsappNumber,
      this.email,
      this.trn,
      this.custImage,
      this.paymentTerms,
      this.creditLimit,
      this.creditDays,
      this.routeId,
      this.provinceId,
      this.storeId,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.deletedAt,
      this.erpCustomerCode});

  Customer.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    code = json['code'];
    address = json['address'];
    contactNumber = json['contact_number'];
    whatsappNumber = json['whatsapp_number'];
    email = json['email'];
    trn = json['trn'];
    custImage = json['cust_image'];
    paymentTerms = json['payment_terms'];
    creditLimit = json['credit_limit'];
    creditDays = json['credit_days'];
    routeId = json['route_id'];
    provinceId = json['province_id'];
    storeId = json['store_id'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    erpCustomerCode = json['erp_customer_code'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['code'] = this.code;
    data['address'] = this.address;
    data['contact_number'] = this.contactNumber;
    data['whatsapp_number'] = this.whatsappNumber;
    data['email'] = this.email;
    data['trn'] = this.trn;
    data['cust_image'] = this.custImage;
    data['payment_terms'] = this.paymentTerms;
    data['credit_limit'] = this.creditLimit;
    data['credit_days'] = this.creditDays;
    data['route_id'] = this.routeId;
    data['province_id'] = this.provinceId;
    data['store_id'] = this.storeId;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    data['erp_customer_code'] = this.erpCustomerCode;
    return data;
  }
}
