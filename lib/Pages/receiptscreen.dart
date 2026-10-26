import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui; // NEW

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:intl/intl.dart';
import 'package:mobizapp/Components/commonwidgets.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:http/http.dart' as http;
import '../Models/Store_model.dart';
import '../Models/receiptdatamodel.dart';
import '../Utilities/date_helper.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import '../Utilities/cpcl_helper.dart';
import '../Utilities/report_printer.dart';
import '../Reports/receipt_report.dart';
import 'TestReceipt.dart';

class ReceiptScreen extends StatefulWidget {
  static const receiptScreen = "/Receipt";
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _initDone = false;
  bool _noData = false;
  bool _connected = false;
  BluetoothDevice? _selectedDevice;
  final ScrollController _scrollController = ScrollController();
  // ReportData receiptsData = ReportData();
  List<ReportData> receiptsData = [];
  List<BluetoothDevice> _devices = [];
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // _getRecentData();
    _fetchData();
    _initPrinter();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoading &&
          _hasMore) {
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
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

  Future<void> _connect() async {
    if (_selectedDevice != null) {
      await printer.connect(_selectedDevice!);
      setState(() {
        _connected = true;
      });
    }
  }
Future<void> _printReceiptImage(ReportData data) async {
  final outstanding = await _getOutstanding(data.customerId);
  final response = await http.get(Uri.parse(
    '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}',
  ));

  if (response.statusCode != 200) {
    throw Exception('Failed to load store details');
  }

  final storeDetail = StoreDetail.fromJson(json.decode(response.body));
  final logoFile = storeDetail.logos;
  final logo = logoFile != null && logoFile.isNotEmpty
      ? await loadLogo('$kStoreLogoBaseUrl$logoFile')
      : null;

  await printReport(
    printer,
    _selectedDevice,
    (b) => drawReceipt(b, data, storeDetail, outstanding, logo: logo),
    widthDots: kLabelWidthDots,
  );
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

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _isSearching = false;
        _currentPage = 1;
        _hasMore = true;
        receiptsData.clear();
      });
      _fetchData();
    } else {
      setState(() {
        _isSearching = true;
        _currentPage = 1;
        _hasMore = true;
        receiptsData.clear();
      });
      _fetchData(searchQuery: _searchController.text);
    }
  }

  Future<void> _fetchData({String? searchQuery}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final Uri apiUrl;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        apiUrl = Uri.parse(
            "${RestDatasource().BASE_URL}/api/get_collection_report_search?"
            "store_id=${AppState().storeId}&"
            "van_id=${AppState().vanId}&"
            "user_id=${AppState().userId}&"
            "page=$_currentPage&"
            "value=$searchQuery");
      } else {
        apiUrl =
            Uri.parse("${RestDatasource().BASE_URL}/api/get_collection_report?"
                "store_id=${AppState().storeId}&"
                "van_id=${AppState().vanId}&"
                "user_id=${AppState().userId}&"
                "page=$_currentPage");
      }

      final http.Response response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        print(response.request);
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final CollectionReport report = CollectionReport.fromJson(responseData);

        setState(() {
          receiptsData.addAll(report.data?.reportData ?? []);
          _hasMore = report.data?.nextPageUrl != null;
          if (report.data?.reportData?.isNotEmpty ?? false) {
            _currentPage++;
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
        _isLoading = false;
        _initDone = true;
      });
    }
  }

  Future<String> _getOutstanding(int? customerId) async {
    if (customerId == null) return '0.00';
    try {
      final response = await http.get(Uri.parse(
          '${RestDatasource().BASE_URL}/api/get_sales_pending_outstanding?store_id=${AppState().storeId}&customer_id=$customerId'));
      if (response.statusCode == 200) {
        print(response.request);
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return responseData['data'].toString();
        }
      }
    } catch (e) {
      print('Error fetching outstanding: $e');
    }
    return '0.00';
  }

  // NEW: Renders Arabic text to a PNG bitmap for thermal printing — same
// approach as the invoice screen's _arabicTextToImageBytes(). ESC/POS
// text commands only cover Latin/ASCII, so Arabic must go as an image.
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
          fontFamily: 'NotoNaskhArabic',
        ),
      ),
      textDirection: ui.TextDirection.rtl,
      textAlign: TextAlign.center,
    );
    textPainter.layout(maxWidth: maxWidth);

    // Thermal printers need bitmap width byte-aligned (multiple of 8).
    double rawWidth = textPainter.width.ceilToDouble();
    final double width = (rawWidth / 8).ceil() * 8;
    final double height = textPainter.height.ceilToDouble();

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width, height),
    );

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

  Future<pw.Font> _loadArabicPwFont() async {
    final fontData =
        await rootBundle.load('Assets/fonts/NotoNaskhArabic-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  Future<void> generatePdf(ReportData data) async {
    String outstanding = await _getOutstanding(data.customerId);
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
    if (response.statusCode == 200) {
      StoreDetail storeDetail =
          StoreDetail.fromJson(json.decode(response.body));

      final pdf = pw.Document();
      final String api =
          '${RestDatasource().Image_URL}/uploads/store/${storeDetail.logos}';
      final logoResponse = await http.get(Uri.parse(api));
      if (logoResponse.statusCode != 200) {
        throw Exception('Failed to load logo image');
      }
      final Uint8List logoBytes = logoResponse.bodyBytes;

      // NEW: load Arabic font ONCE, before build() — build() is sync,
      // so the font can't be awaited inside it.
      final pw.Font? arabicFont = (storeDetail.name_ar != null &&
              storeDetail.name_ar!.trim().isNotEmpty)
          ? await _loadArabicPwFont()
          : null;

      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(height: 10),
                            pw.Text(
                              storeDetail.name,
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 3),
// NEW: Arabic company name — same size/weight/color as English name
                            if (arabicFont != null)
                              pw.Text(
                                storeDetail.name_ar!,
                                textDirection: pw.TextDirection.rtl,
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                  font: arabicFont,
                                  fontSize:
                                      18, // was 14 → now matches English name's 18
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors
                                      .black, // was default grey → now solid black
                                ),
                              ),
                            pw.SizedBox(height: 3),
                            pw.Text('${storeDetail.address ?? 'N/A'}'),
                            pw.SizedBox(height: 3),
                            pw.Text('TRN: ${storeDetail.trn ?? 'N/A'}'),
                            pw.SizedBox(height: 3),
                          ]),
                      pw.Image(
                        pw.MemoryImage(logoBytes),
                        height: 100,
                        width: 100,
                        fit: pw.BoxFit.fitWidth,
                      ),
                    ]),
                pw.Center(
                  child: pw.Text(
                    'RECEIPT VOUCHER',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.grey, height: 1, thickness: 1),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Customer:',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          (data.customer!.isNotEmpty)
                              ? data.customer![0].code ?? ''
                              : '',
                          style: pw.TextStyle(
                            fontSize: AppConfig.textCaption3Size,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text('${data.customer![0].name}'),
                        // pw.SizedBox(height: 3),
                        // pw.Text('Market: ${data.customer![0].address}'),
                        pw.SizedBox(height: 3),
                        pw.Text(
                            '${data.store![0].vatLabel}: ${data.customer![0].trn}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Reference: ${data.sales![0].voucherNo ?? 'N/A'}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                            'Date: ${DateHelper.displayDate(data.sales![0].inDate)}'),
                        pw.Text('Time: ${data.sales![0].inTime}'),
                        pw.Text(
                            'Due Date: ${DateHelper.displayDate(data.sales![0].inDate)}'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: PdfColors.grey, height: 1, thickness: .5),
                pw.SizedBox(height: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if ((data.collectionType ?? '').toLowerCase() ==
                        'cheque') ...[
                      pw.Text('Collection Type: Cheque'),
                      pw.Text('Bank Name: ${data.bank ?? 'N/A'}'),
                      pw.Text('Cheque No: ${data.chequeNo ?? 'N/A'}'),
                      pw.Text(
                          'Cheque Date: ${data.chequeDate != null ? DateHelper.displayDate(data.chequeDate) : 'N/A'}'),
                    ] else ...[
                      pw.Text(
                          'Collection Type: ${data.collectionType ?? 'Cash'}'),
                    ]
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.SizedBox(height: 10),
              ],
            ),
            _buildSalesTable(data.sales!),
            pw.SizedBox(height: 20),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Text((data.roundoff != null &&
                      double.parse(data.roundoff!) != 0)
                  ? 'Round Off: ${double.parse(data.roundoff!).toStringAsFixed(AppState().noOfDecimals ?? 2)}'
                  : ''),
            ]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Text('Total: ${data.totalAmount ?? 'N/A'}'),
            ]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Text('Total Outstanding: $outstanding'),
            ]),
            pw.SizedBox(height: 20),
            pw.Text('Van: ${data.van![0].name ?? 'N/A'}'),
            pw.SizedBox(width: 20),
            pw.Text('Salesman: ${data.user![0].name ?? 'N/A'}'),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/receipt_report.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } else {
      throw Exception('Failed to load store details');
    }
  }

  Future<void> generateWifiPdf(ReportData data) async {
    String outstanding = await _getOutstanding(data.customerId);
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
    if (response.statusCode == 200) {
      StoreDetail storeDetail =
          StoreDetail.fromJson(json.decode(response.body));

      final pdf = pw.Document();
      final String api =
          '${RestDatasource().Image_URL}/uploads/store/${storeDetail.logos}';
      final logoResponse = await http.get(Uri.parse(api));
      if (logoResponse.statusCode != 200) {
        throw Exception('Failed to load logo image');
      }
      final Uint8List logoBytes = logoResponse.bodyBytes;

      // NEW: same as generatePdf()
      final pw.Font? arabicFont = (storeDetail.name_ar != null &&
              storeDetail.name_ar!.trim().isNotEmpty)
          ? await _loadArabicPwFont()
          : null;

      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // pw.Center(
                //   child: pw.Column(
                //     children: [
                //       pw.Image(
                //         pw.MemoryImage(logoBytes),
                //         height: 100,
                //         width: 100,
                //         fit: pw.BoxFit.cover,
                //       ),
                //       pw.SizedBox(height: 10),
                //       pw.Text(
                //         storeDetail.name,
                //         style: pw.TextStyle(
                //           fontSize: 18,
                //           fontWeight: pw.FontWeight.bold,
                //         ),
                //       ),
                //       pw.SizedBox(height: 3),
                //       pw.Text('${storeDetail.address ?? 'N/A'}'),
                //       pw.SizedBox(height: 3),
                //       pw.Text('TRN: ${storeDetail.trn ?? 'N/A'}'),
                //       pw.SizedBox(height: 3),
                //       pw.Text(
                //         'RECEIPT VOUCHER',
                //         style: pw.TextStyle(
                //           fontSize: 16,
                //           fontWeight: pw.FontWeight.bold,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                pw.Center(
                  child: pw.Text(
                    'RECEIPT VOUCHER',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.grey, height: 1, thickness: 1),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Customer:',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          (data.customer!.isNotEmpty)
                              ? data.customer![0].code ?? ''
                              : '',
                          style: pw.TextStyle(
                            fontSize: AppConfig.textCaption3Size,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text('${data.customer![0].name}'),
                        // pw.SizedBox(height: 3),
                        // pw.Text('Market: ${data.customer![0].address}'),
                        pw.SizedBox(height: 3),
                        pw.Text(
                            '${data.store![0].vatLabel}: ${data.customer![0].trn}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Reference: ${data.sales![0].voucherNo ?? 'N/A'}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                            'Date: ${DateHelper.displayDate(data.sales![0].inDate)}'),
                        pw.Text(
                            'Due Date: ${DateHelper.displayDate(data.sales![0].inDate)}'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: PdfColors.grey, height: 1, thickness: .5),
                pw.SizedBox(height: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if ((data.collectionType ?? '').toLowerCase() ==
                        'cheque') ...[
                      pw.Text('Collection Type: Cheque'),
                      pw.Text('Bank Name: ${data.bank ?? 'N/A'}'),
                      pw.Text('Cheque No: ${data.chequeNo ?? 'N/A'}'),
                      pw.Text(
                          'Cheque Date: ${data.chequeDate != null ? DateHelper.displayDate(data.chequeDate) : 'N/A'}'),
                    ] else ...[
                      pw.Text(
                          'Collection Type: ${data.collectionType ?? 'Cash'}'),
                    ]
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.SizedBox(height: 10),
              ],
            ),
            _buildSalesTable(data.sales!),
            pw.SizedBox(height: 20),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Text((data.roundoff != null &&
                      double.parse(data.roundoff!) != 0)
                  ? 'Round Off: ${double.parse(data.roundoff!).toStringAsFixed(AppState().noOfDecimals ?? 2)}'
                  : ''),
            ]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Text('Total: ${data.totalAmount ?? 'N/A'}'),
            ]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Text('Total Outstanding: $outstanding'),
            ]),
            pw.SizedBox(height: 20),
            pw.Text('Van: ${data.van![0].name ?? 'N/A'}'),
            pw.SizedBox(width: 20),
            pw.Text('Salesman: ${data.user![0].name ?? 'N/A'}'),
            pw.SizedBox(height: 20),
            pw.Text("${storeDetail.invoice_footer}"),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/receipt_report.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } else {
      throw Exception('Failed to load store details');
    }
  }

  String formatInvoiceType(String? invoiceType) {
    if (invoiceType == null) return 'N/A'; // Return N/A if invoiceType is null

    // Capitalize the first letter and check for specific cases
    switch (invoiceType.toLowerCase()) {
      case 'salesreturn':
        return 'Sales Return';
      case 'payment_voucher':
        return 'Payment';
      default:
        return invoiceType[0].toUpperCase() +
            invoiceType.substring(1).toLowerCase();
    }
  }

// Separate function to build the sales table with proper pagination
  pw.Widget _buildSalesTable(List<Salesy> sales) {
    return pw.Table.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.white),
      headers: ['SI NO', 'Reference No', 'Type', 'Amount'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.center,
      columnWidths: {
        0: pw.FractionColumnWidth(0.1),
        1: pw.FractionColumnWidth(0.2),
        2: pw.FractionColumnWidth(0.2),
        3: pw.FractionColumnWidth(0.2),
      },
      data: sales.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final sale = entry.value;
        return [
          '$index',
          sale.invoiceNo ?? 'N/A',
          formatInvoiceType(sale.invoiceType),
          sale.amount?.toString() ?? 'N/A',
        ];
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by voucher or customer...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  // Cancel previous debounce timer
                  _searchDebounce?.cancel();

                  // Start new debounce timer
                  _searchDebounce =
                      Timer(const Duration(milliseconds: 500), () {
                    _onSearchChanged();
                  });
                },
              )
            : const Text(
                'Receipts',
                style: AppConfig.pageTitleStyle,
              ),
        backgroundColor: AppConfig.colorPrimary,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  // Clear search
                  _searchController.clear();
                  _onSearchChanged();
                } else {
                  // Start searching
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching &&
              receiptsData.isEmpty &&
              _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('No results found'),
            ),
          CommonWidgets.verticalSpace(1),
          (_initDone && !_noData)
              ? Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 0),
                    itemCount: receiptsData.length + (_isLoading ? 1 : 0),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      // Check if this is the loading indicator
                      if (_isLoading && index == receiptsData.length) {
                        return _isLoading
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

                      final data = receiptsData[index];
                      return _productsCard(data);
                    },
                  ),
                )
              : _noData && _initDone
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CommonWidgets.verticalSpace(3),
                        const Center(
                          child: Text('No Data'),
                        ),
                      ],
                    )
                  : Shimmer.fromColors(
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
                            CommonWidgets.loadingContainers(
                                height: SizeConfig.blockSizeVertical * 10,
                                width: SizeConfig.blockSizeHorizontal * 90),
                          ],
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _productsCard(ReportData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                spreadRadius: 2,
                blurRadius: 2,
                blurStyle: BlurStyle.inner,
                color: Colors.grey.shade200)
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          color: AppConfig.backgroundColor,
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 1,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 2.0),
            childrenPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            // trailing icons kept ONLY here, not duplicated inside title Row.
            // This is what was forcing the extra vertical gap around
            // "Round Off" — the title Column was being stretched by a
            // sibling Row(spaceBetween) that wrapped the trailing icons.
            // ── FIX: same pattern as Sale Invoice screen — widened tap targets
// (~40x40 via InkWell + Padding) instead of just the bare icon glyph,
// and widened the SizedBox to fit them without clipping. ──
            trailing: SizedBox(
              width: AppState().printer == "Wifi" ? 130 : 90,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _print(data),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child:
                          Icon(Icons.print, color: Colors.blueAccent, size: 26),
                    ),
                  ),
                  if (AppState().printer == "Wifi")
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => generateWifiPdf(data),
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
                    onTap: () => generatePdf(data),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.document_scanner,
                          color: Colors.red, size: 26),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: AppConfig.backgroundColor,
            // title is now just the Column directly — no wrapping Row that
            // used to be forced to spaceBetween against the trailing icons.
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  child: Text(
                    '${DateHelper.displayDate(data.inDate)} ${data.inTime} | ${data.voucherNo}',
                    style: TextStyle(
                      fontSize: AppConfig.textCaption3Size,
                      height: 1.15,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      overflow: TextOverflow.fade,
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
                  ],
                ),
                Text(
                  'Amount: ${data.totalAmount}',
                  style: TextStyle(
                    fontSize: AppConfig.textCaption3Size,
                  ),
                ),
                Text(
                  'Round Off: ${data.roundoff ?? '0.00'}',
                  style: TextStyle(
                    fontSize: AppConfig.textCaption3Size,
                    height: 1.15,
                  ),
                ),
                Text(
                  'Type:  ${(data.collectionType ?? '').toLowerCase() == 'cheque' ? 'Cheque | ${data.bank} | ${data.chequeNo} \nCheque Date: ${DateHelper.displayDate(data.chequeDate)}' : (data.collectionType ?? 'Cash')}',
                  style: TextStyle(
                    fontSize: AppConfig.textCaption3Size,
                    height: 1.15,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: TextStyle(
                        fontSize: AppConfig.textCaption3Size,
                        height: 1.15,
                      ),
                    ),
                    Text(
                      // Receipt screen: status 2 = Confirmed only.
                      // There is no "Approved" status for receipts.
                      data.status == 0
                          ? 'Cancelled'
                          : data.status == 2
                              ? 'Confirmed'
                              : '',
                      style: TextStyle(
                        fontSize: AppConfig.textCaption3Size,
                        height: 1.15,
                        color: data.status == 0 ? Colors.red : Colors.green,
                        fontWeight: AppConfig.headLineWeight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              Wrap(
                children: List.generate(data.sales?.length ?? 0, (index) {
                  final sale = data.sales![index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(height: 12),
                        Text(
                          'Reference No: ${sale.invoiceNo ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: AppConfig.textCaption3Size,
                            height: 1.15,
                          ),
                        ),
                        Text(
                          'Reference Type: ${sale.invoiceType == 'salesreturn' ? 'Sales Return' : sale.invoiceType == 'sales' ? 'Sales' : sale.invoiceType == 'paymentvoucher' ? 'Payment Voucher' : 'N/A'}',
                          style: TextStyle(
                            fontSize: AppConfig.textCaption3Size,
                          ),
                        ),
                        Text(
                          'Amount: ${sale.amount ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: AppConfig.textCaption3Size,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              )
            ],
          ),
        ),
      ),
    );
  }

  
void _print(ReportData data) async {
  // Printer must be known BEFORE choosing Zebra/Sewoo
  if (_selectedDevice == null) await _getBluetoothDevices();
  if (_selectedDevice == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default printer not found')),
    );
    return;
  }
  await loadPrinterTypeCache();
  final bool zebra = isZebraPrinter(_selectedDevice);
  print('PRINT route: zebra=$zebra name=${_selectedDevice?.name} '
      'addr=${_selectedDevice?.address}');

  if (!_connected) await _connect();
  if (!_connected) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printer not connected')),
    );
    return;
  }

  try {
    if (zebra) {
      await _printReceiptImage(data);
    } else {
      await _printSewoo(data);
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
  // 1. SEWOO (ESC/POS)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _printSewoo(ReportData data) async { 
    String outstanding = await _getOutstanding(data.customerId);
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
    if (response.statusCode == 200) {
      StoreDetail storeDetail =
          StoreDetail.fromJson(json.decode(response.body));
      final String api =
          '${RestDatasource().Image_URL}/uploads/store/${storeDetail.logos}';
      final logoResponse = await http.get(Uri.parse(api));
      if (logoResponse.statusCode != 200) {
        throw Exception('Failed to load logo image');
      }

      void printAlignedText(String leftText, String rightText) {
        const int maxLineLength = 68;
        int leftTextLength = leftText.length;
        int rightTextLength = rightText.length;

        int spaceLength = maxLineLength - (leftTextLength + rightTextLength);
        String spaces = ' ' * (spaceLength > 0 ? spaceLength : 1);

        printer.printCustom('$leftText$spaces$rightText', 1, 0);
      }

         String logoUrl =
          'https://erpadmin.mobiz.ae/uploads/store/${storeDetail.logos}';
      if (logoUrl.isNotEmpty) {
        final logoBytes = await buildSewooLogoBytes(logoUrl);
        if (logoBytes != null) {
          await printer.printImageBytes(logoBytes);
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      printer.printNewLine();
      String companyName = '${storeDetail.name}';
      printer.printCustom(companyName, 3, 1);

      String companyNameAr = storeDetail.name_ar ?? '';
      if (companyNameAr.trim().isNotEmpty) {
        try {
          final Uint8List arabicNameBytes =
              await _arabicTextToImageBytes(companyNameAr, fontSize: 30);
          await printer.printImageBytes(arabicNameBytes);
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          print('Failed to print Arabic company name: $e');
        }
      }

      printer.printNewLine();
      printer.printCustom("${storeDetail.address ?? 'N/A'}", 1, 1);
      printer.printCustom("RECEIPT VOUCHER", 3, 1);
      printer.printNewLine();
      printer.printCustom("-" * 72, 1, 1);

      // Customer Details
      if (data.customer != null && data.customer!.isNotEmpty) {
        printAlignedText('Customer: ${data.customer![0].name}',
            'Reference: ${data.sales![0].voucherNo ?? 'N/A'}');
        printAlignedText(
            '',
            'Date: ${DateHelper.displayDate(data.sales![0].inDate)}');
        printAlignedText(
            '',
            'Time: ${data.sales![0].inTime}');
        printAlignedText(
          (data.customer![0].trn != null && data.customer![0].trn!.isNotEmpty)
              ? '${data.store![0].vatLabel}: ${data.customer![0].trn}'
              : '',
          'Due Date: ${DateHelper.displayDate(data.sales![0].inDate)}',
        );
      }
      printer.printNewLine();
      printer.printCustom("-" * 72, 1, 1);

      // Collection Information
      if ((data.collectionType ?? '').toLowerCase() == 'cheque') {
        printAlignedText('Collection Type: Cheque', ' ');
        printAlignedText('Bank Name: ${data.bank}', ' ');
        printAlignedText('Cheque No: ${data.chequeNo}', ' ');
        printAlignedText(
          'Cheque Date: ${data.chequeDate != null ? DateHelper.displayDate(data.chequeDate) : 'N/A'}',
          ' ',
        );
      } else {
        printAlignedText(
            'Collection Type: ${data.collectionType ?? 'Cash'}', ' ');
      }
      printAlignedText('Amount: ${data.totalAmount}', ' ');
      printer.printNewLine();
      printer.printCustom("-" * 72, 1, 1);

      const int columnWidth0 = 4;
      const int columnWidth1 = 14;
      const int columnWidth2 = 20;
      const int columnWidth3 = 14;
      const int columnWidth4 = 5;

      String headers = "${''.padRight(columnWidth0)}"
          "${'SI.NO'.padRight(columnWidth1)}"
          " ${'Reference NO'.padRight(columnWidth2)}"
          " ${'Type'.padRight(columnWidth3)}"
          "${'Amount'.padRight(columnWidth4)}";
      printer.printCustom(headers, 1, 0);
      printer.printCustom("-" * 72, 1, 1);

      String formatInvoiceType(String? invoiceType) {
        if (invoiceType == null) return 'N/A';
        switch (invoiceType.toLowerCase()) {
          case 'salesreturn':
            return 'Sales Return';
          case 'payment_voucher':
            return 'Payment';
          default:
            return invoiceType[0].toUpperCase() +
                invoiceType.substring(1).toLowerCase();
        }
      }

      for (var i = 0; i < data.sales!.length; i++) {
        var sale = data.sales![i];
        String line = "${('').padRight(columnWidth0)}"
            "${(i + 1).toString().padRight(columnWidth1)}"
            " ${sale.invoiceNo?.padRight(columnWidth2) ?? 'N/A'.padRight(columnWidth2)}"
            "${formatInvoiceType(sale.invoiceType)?.padRight(columnWidth3) ?? 'N/A'.padRight(columnWidth3)}"
            "${sale.amount?.padRight(columnWidth4) ?? 'N/A'.padRight(columnWidth4)}";
        printer.printCustom(line, 1, 0);
      }
      printer.printNewLine();
      printer.printCustom("-" * 72, 1, 1);
      if (data.roundoff != null && (double.tryParse(data.roundoff!) ?? 0) != 0) {
        printAlignedText('',
            'Round Off: ${double.parse(data.roundoff!).toStringAsFixed(AppState().noOfDecimals ?? 2)}');
      }
      printAlignedText('', 'Total: ${data.totalAmount}');
      printAlignedText('', 'Total Outstanding: $outstanding');
      printAlignedText(
          "Van: ${(data.van != null && data.van!.isNotEmpty) ? data.van![0].name : 'N/A'}",
          "");
      printAlignedText(
          "Salesman: ${(data.user != null && data.user!.isNotEmpty) ? data.user![0].name : 'N/A'}",
          "");
      printer.printNewLine();

      printer.paperCut();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. ZEBRA (CPCL)
  // ═══════════════════════════════════════════════════════════════
 // ═══════════════════════════════════════════════════════════════
  // 2. ZEBRA (CPCL - Clean Alignment, No Overlap)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _printZebra(ReportData data) async {
    String outstanding = await _getOutstanding(data.customerId);
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
    if (response.statusCode != 200) return;
    StoreDetail storeDetail = StoreDetail.fromJson(json.decode(response.body));

    final cpcl = CpclBuilder(kLabelWidthDots);

    // ---- 1. Logo ----
    if (storeDetail.logos != null && storeDetail.logos!.isNotEmpty) {
      try {
        final logoUrl =
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

    // ---- 2. Company name ----
    cpcl.centerText(storeDetail.name ?? '', font: 5, lineGap: 34);

    // ---- 3. Arabic company name (as bitmap) ----
    String companyNameAr = storeDetail.name_ar ?? '';
    if (companyNameAr.trim().isNotEmpty) {
      try {
        final Uint8List arPng =
            await _arabicTextToImageBytes(companyNameAr, fontSize: 26);
        img.Image? arImg = img.decodeImage(arPng);
        if (arImg != null) {
          final bytesPerRow = (arImg.width / 8).ceil();
          final packed = imageTo1BitCpcl(arImg);
          // cpcl.addLogo(packed, bytesPerRow, arImg.height);
        }
      } catch (e) {
        print('Arabic name print error: $e');
      }
    }

    if (storeDetail.address != null && storeDetail.address != 'N/A') {
      cpcl.centerText(storeDetail.address!, font: 4, lineGap: 24);
    }
    if (storeDetail.trn != null && storeDetail.trn!.isNotEmpty && storeDetail.trn != 'N/A') {
      cpcl.centerText('TRN: ${storeDetail.trn}', font: 4, lineGap: 24);
    }
    cpcl.hLine();
    cpcl.centerText('RECEIPT VOUCHER', font: 5, lineGap: 34);
    cpcl.hLine();

    // ---- 4. Customer info block ----
    String voucherNo = (data.sales != null && data.sales!.isNotEmpty)
        ? (data.sales![0].voucherNo ?? 'N/A')
        : 'N/A';
    String inDate = (data.sales != null && data.sales!.isNotEmpty)
        ? DateHelper.displayDate(data.sales![0].inDate)
        : 'N/A';
    String inTime = (data.sales != null && data.sales!.isNotEmpty)
        ? (data.sales![0].inTime ?? '')
        : '';

    if (data.customer != null && data.customer!.isNotEmpty) {
      String custName = data.customer![0].name ?? '';
      List<String> nameParts = _splitText(custName, 36);
      cpcl.text('Customer: ${nameParts.isNotEmpty ? nameParts[0] : ""}');
      for (int i = 1; i < nameParts.length; i++) {
        cpcl.text('          ${nameParts[i]}');
      }
    }
    cpcl.twoColumn("Voucher: $voucherNo", "Date: $inDate");
    if (inTime.isNotEmpty) {
      cpcl.twoColumn("", "Time: $inTime");
    }

    if (data.customer != null && data.customer!.isNotEmpty) {
      final trn = data.customer![0].trn;
      if (trn != null && trn.isNotEmpty) {
        String vatLabel = (data.store != null && data.store!.isNotEmpty)
            ? (data.store![0].vatLabel ?? 'VAT')
            : 'VAT';
        cpcl.text('$vatLabel: $trn');
      }
    }
    cpcl.hLine();

    // ---- 5. Collection info ----
    if ((data.collectionType ?? '').toLowerCase() == 'cheque') {
      cpcl.twoColumn("Type: Cheque", "Bank: ${data.bank ?? 'N/A'}");
      cpcl.twoColumn("Cheque No: ${data.chequeNo ?? 'N/A'}", 
          "Date: ${data.chequeDate != null ? DateHelper.displayDate(data.chequeDate) : 'N/A'}");
    } else {
      cpcl.twoColumn("Type: ${data.collectionType ?? 'Cash'}", "");
    }
    cpcl.twoColumn("Amount: ${data.totalAmount ?? '0.00'}", "");
    cpcl.hLine();

    // ---- 6. Sales table Header (Max 42 characters) ----
    // Format: Sl (4) | Reference No (16) | Type (12) | Amount (8)
    cpcl.text("Sl   Reference No     Type           Amount", font: 4, lineGap: 30);
    cpcl.hLine(thickness: 1);

    String formatInvoiceType(String? t) {
      if (t == null) return 'N/A';
      switch (t.toLowerCase()) {
        case 'salesreturn':
          return 'Sales Return';
        case 'payment_voucher':
        case 'paymentvoucher':
          return 'Payment';
        case 'sales':
          return 'Sales';
        default:
          return t.length > 12 ? t.substring(0, 12) : t;
      }
    }

    for (int i = 0; i < (data.sales?.length ?? 0); i++) {
      var sale = data.sales![i];
      String sno = (i + 1).toString().padRight(4);
      String ref = (sale.invoiceNo ?? 'N/A').padRight(16);
      if (ref.length > 16) ref = ref.substring(0, 16);
      String type = formatInvoiceType(sale.invoiceType).padRight(13);
      String amt = (sale.amount?.toString() ?? '0.00').padLeft(8);

      cpcl.text('$sno$ref$type$amt', font: 4, lineGap: 28);
    }
    cpcl.hLine();

    // ---- 7. Totals ----
    if (data.roundoff != null && (double.tryParse(data.roundoff!) ?? 0) != 0) {
      cpcl.twoColumn('',
          'Round Off: ${double.parse(data.roundoff!).toStringAsFixed(AppState().noOfDecimals ?? 2)}');
    }
    cpcl.twoColumn('', 'Total: ${data.totalAmount ?? "0.00"}');
    cpcl.twoColumn('', 'Total Outstanding: $outstanding');
    cpcl.feed(10);
    cpcl.twoColumn(
        'Van: ${(data.van != null && data.van!.isNotEmpty) ? data.van![0].name : 'N/A'}',
        'Salesman: ${(data.user != null && data.user!.isNotEmpty) ? data.user![0].name : 'N/A'}');
    cpcl.feed(40);

    final bytes = cpcl.build();
    await sendCpcl(printer, bytes);
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
  // Future _getRecentData() async {
  //   RestDatasource api = RestDatasource();
  //   Map<String, dynamic> response = await api.getDetails(
  //       '/api/get_collection_report?store_id=${AppState().storeId}&van_id=${AppState().vanId}&user_id=${AppState().userId}',
  //       AppState().token);
  //
  //   receiptsData = ReportData.fromJson(response);
  //   if (response['data'] != null) {
  //     setState(() {
  //       _initDone = true;
  //     });
  //   }
  //   if (_selectedDevice == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Default device not found')),
  //     );
  //     return;
  //   }
  //   if (!_connected) {
  //     await _connect();
  //   } else {
  //     setState(() {
  //       _initDone = true;
  //       _noData = true;
  //     });
  //   }
  //   print('Response Data $response');
  // }
  // Future<void> _fetchData() async {
  //   setState(() {
  //     _isLoading = true;
  //   });
  //
  //   try {
  //     // final String baseUrl =
  //     //     "http://68.183.92.8:3699/api/get_collection_test_report";
  //
  //     // Build the API URL with query parameters
  //     final Uri apiUrl = Uri.parse(
  //         "${RestDatasource().BASE_URL}/api/get_collection_report?store_id=${AppState().storeId}&van_id=${AppState().vanId}&user_id=${AppState().userId}&page=$_currentPage");
  //
  //     // Fetch the data from the API
  //     final http.Response response = await http.get(apiUrl);
  //
  //     if (response.statusCode == 200) {
  //       print(response.request);
  //       // Parse the JSON response
  //       final Map<String, dynamic> responseData = jsonDecode(response.body);
  //
  //       // Convert the JSON into the CollectionReport model
  //       final CollectionReport report = CollectionReport.fromJson(responseData);
  //
  //       // Update the state with the fetched data
  //       setState(() {
  //         receiptsData.addAll(report.data?.reportData ?? []);
  //         _hasMore = report.data?.nextPageUrl != null;
  //         _currentPage++;
  //         _initDone = true;
  //       });
  //     } else {
  //       throw Exception("Failed to fetch data");
  //     }
  //   } catch (e) {
  //     print(e);
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //       _initDone = true;
  //       // _noData = true;
  //     });
  //   }
  // }
}
