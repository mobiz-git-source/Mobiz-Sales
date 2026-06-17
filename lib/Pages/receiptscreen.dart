import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
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
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
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
        apiUrl = Uri.parse(
            "${RestDatasource().BASE_URL}/api/get_collection_report?"
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

  Future<void> generatePdf(ReportData data) async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
    if (response.statusCode == 200) {
      // Parse JSON response into StoreDetail object
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
                        pw.Text('${storeDetail.address ?? 'N/A'}'),
                        pw.SizedBox(height: 3),
                        pw.Text('TRN: ${storeDetail.trn ?? 'N/A'}'),
                        pw.SizedBox(height: 3),
                      ]
                    ),
                    pw.Image(
                      pw.MemoryImage(logoBytes),
                      height: 100,
                      width: 100,
                      fit: pw.BoxFit.fitWidth,
                    ),
                  ]
                ),
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
                        pw.Text('TRN: ${data.customer![0].trn}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Reference: ${data.sales![0].voucherNo ?? 'N/A'}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Date: ${data.sales![0].inDate}'),
                        pw.Text('Due Date: ${data.sales![0].inDate}'),
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
                    if (data.collectionType == 'Cheque') ...[
                      pw.Text('Collection Type: Cheque'),
                      pw.Text('Bank Name: ${data.bank ?? 'N/A'}'),
                      pw.Text('Cheque No: ${data.chequeNo ?? 'N/A'}'),
                      pw.Text('Cheque Date: ${data.chequeDate ?? 'N/A'}'),
                    ] else if (data.collectionType == 'Cash') ...[
                      // Add any text or elements specific to Cash collection type if needed
                      // For example:
                      pw.Text('Collection Type: Cash'),
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
                  ? 'Round Off: ${double.parse(data.roundoff!).toStringAsFixed(2)}'
                  : ''),
            ]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Text('Total: ${data.totalAmount ?? 'N/A'}'),
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
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
    if (response.statusCode == 200) {
      // Parse JSON response into StoreDetail object
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
                 child:  pw.Text(
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
                        pw.Text('TRN: ${data.customer![0].trn}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Reference: ${data.sales![0].voucherNo ?? 'N/A'}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Date: ${data.sales![0].inDate}'),
                        pw.Text('Due Date: ${data.sales![0].inDate}'),
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
                    if (data.collectionType == 'Cheque') ...[
                      pw.Text('Collection Type: Cheque'),
                      pw.Text('Bank Name: ${data.bank ?? 'N/A'}'),
                      pw.Text('Cheque No: ${data.chequeNo ?? 'N/A'}'),
                      pw.Text('Cheque Date: ${data.chequeDate ?? 'N/A'}'),
                    ] else if (data.collectionType == 'Cash') ...[
                      // Add any text or elements specific to Cash collection type if needed
                      // For example:
                      pw.Text('Collection Type: Cash'),
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
                  ? 'Round Off: ${double.parse(data.roundoff!).toStringAsFixed(2)}'
                  : ''),
            ]),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Text('Total: ${data.totalAmount ?? 'N/A'}'),
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
            _searchDebounce = Timer(const Duration(milliseconds: 500), () {
              _onSearchChanged();
            });
          },
        )
            : const Text(
          'Receipts',
          style: TextStyle(color: AppConfig.backgroundColor),
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
          if (_isSearching && receiptsData.isEmpty && _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('No results found'),
            ),

          CommonWidgets.verticalSpace(1),
          (_initDone && !_noData)
              ? SizedBox(
                  height: SizeConfig.blockSizeVertical * 85,
                  child: ListView.separated(
                    controller: _scrollController,
                    separatorBuilder: (BuildContext context, int index) =>
                        CommonWidgets.verticalSpace(1),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Container(
        // width: SizeConfig.blockSizeHorizontal * 90,
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
          padding: const EdgeInsets.all(5.0),
          child: ExpansionTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            trailing: SizedBox(
              width: AppState().printer == "Wifi" ? 92 : 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                      onTap: () => _print(data),
                      child: Icon(Icons.print, color: Colors.blueAccent)),
                  SizedBox(width: 10),
                  if(AppState().printer=="Wifi")...[
                    InkWell(
                      onTap: () =>generateWifiPdf(data),
                      child: const Icon(
                        Icons.document_scanner,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 10),
                  ],
                  GestureDetector(
                    onTap: () => generatePdf(data),
                    child: Icon(Icons.document_scanner, color: Colors.red),
                  ),
                ],
              ),
            ),
            backgroundColor: AppConfig.backgroundColor,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      // width: SizeConfig.blockSizeHorizontal * 70,
                      child: Text(
                        '${DateFormat('dd MMMM yyyy').format(DateTime.parse(data.inDate!))} ${data.inTime} | ${data.voucherNo}',
                        style: TextStyle(
                          fontSize: AppConfig.textCaption3Size,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Text(
                        //   (data.customer != null && data.customer!.isNotEmpty)
                        //       ? data.customer![0].code ?? ''
                        //       : (data.customerdata != null)
                        //       ? data.customerdata![0].code ?? ''
                        //       : '',
                        //   style: TextStyle(
                        //     fontSize: AppConfig.textCaption3Size,
                        //     fontWeight: AppConfig.headLineWeight,
                        //   ),
                        // ),
                        // Text(' | '),
                        Text(
                          overflow: TextOverflow.fade,
                          (data.customer != null && data.customer!.isNotEmpty)
                              ? data.customer![0].name ?? ''
                              : (data.customerdata != null)
                              ? data.customerdata![0].name ?? ''
                              : '',
                          style: TextStyle(
                            fontSize: AppConfig.textCaption3Size,
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
                      ),
                    ),
                    Text(
                      'Type:  ${data.collectionType == 'cheque' ? 'Cheque | ${data.bank} | ${data.chequeNo} \nCheque Date: ${data.chequeDate}' : data.collectionType}',
                      style: TextStyle(
                        fontSize: AppConfig.textCaption3Size,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Status: ',
                          style: TextStyle(
                            fontSize: AppConfig.textCaption3Size,
                          ),
                        ),
                        Text(
                          (data.status == 0)
                              ? 'Cancelled'
                              : (data.status == 1)
                                  ? 'Confirmed'
                                  : 'Approved',
                          style: TextStyle(
                              fontSize: AppConfig.textCaption3Size,
                              color: (data.status == 0)
                                  ? Colors.red
                                  : (data.status == 1)
                                      ? Colors.green
                                      : Colors.orange,
                              fontWeight: AppConfig.headLineWeight),
                        ),
                      ],
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
                        horizontal: 8.0, vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(),
                        Text(
                          'Reference No: ${sale.invoiceNo ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: AppConfig.textCaption3Size,
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
    if (_connected) {
      // Print Store Details Header
      // String logoUrl =`
      //     '${RestDatasource().Image_URL}/uploads/store/${storeDetail.logos}';
      // if (logoUrl.isNotEmpty) {
      //   final response = await http.get(Uri.parse(logoUrl));
      //   if (response.statusCode == 200) {
      //     Uint8List imageBytes = response.bodyBytes;
      //
      //     // Decode image and convert to monochrome bitmap if needed
      //     img.Image originalImage = img.decodeImage(imageBytes)!;
      //     img.Image monoLogo = img.grayscale(originalImage);
      //
      //     // Encode the image to the required format (e.g., PNG)
      //     Uint8List logoBytes = Uint8List.fromList(img.encodePng(monoLogo));
      //
      //     // Print the logo image
      //     printer.printImageBytes(logoBytes);
      //   } else {
      //     print('Failed to load image: ${response.statusCode}');
      //   }
      // }
      final response = await http.get(Uri.parse(
          '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
      if (response.statusCode == 200) {
        // Parse JSON response into StoreDetail object
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

          // Calculate padding to ensure rightText is right-aligned
          int spaceLength = maxLineLength - (leftTextLength + rightTextLength);
          String spaces = ' ' * spaceLength;

          printer.printCustom('$leftText$spaces$rightText', 1,
              0); // Print with left-aligned text
        }

        String logoUrl =
            'https://erpadmin.mobiz.ae/uploads/store/${storeDetail.logos}';
        if (logoUrl.isNotEmpty) {
          final response = await http.get(Uri.parse(logoUrl));
          if (response.statusCode == 200) {
            Uint8List imageBytes = response.bodyBytes;

            // Decode image and convert to monochrome bitmap if needed
            img.Image originalImage = img.decodeImage(imageBytes)!;
            img.Image monoLogo = img.grayscale(originalImage);

            // Encode the image to the required format (e.g., PNG)
            Uint8List logoBytes = Uint8List.fromList(img.encodePng(monoLogo));

            // Print the logo image
            printer.printImageBytes(logoBytes);
          } else {
            print('Failed to load image: ${response.statusCode}');
          }
        }

        printer.printNewLine();
        String companyName = '${storeDetail.name}';
        printer.printCustom(companyName, 3, 1);
        printer.printNewLine();

        printer.printCustom("${storeDetail.address ?? 'N/A'}", 1, 1);
        printer.printCustom("RECEIPT VOUCHER", 3, 1);
        printer.printNewLine();
        printer.printCustom("-" * 72, 1, 1);

        // Print Customer Details
        if (data.customer != null && data.customer!.isNotEmpty) {
          printAlignedText('Customer: ${data.customer![0].name}',
              'Reference: ${data.sales![0].voucherNo ?? 'N/A'}');
          // printer.printLeftRight('Customer: ${data.customer![0].name}', '', 1);
          printAlignedText(
              // 'Market:  ${data.customer![0].address}',
              '',
              'Date: ${data.sales![0].inDate}');
          // printer.printLeftRight('Market: ${data.customer![0].address}', '', 1);
          printAlignedText('TRN: ${data.customer![0].trn}',
              'Due Date: ${data.sales![0].inDate}');
          // printer.printLeftRight('TRN: ${data.customer![0].trn}', '', 1);
        }
        printer.printNewLine();
        printer.printCustom("-" * 72, 1, 1); // Centered

        // Print Sales Details
        // printer.printLeftRight(
        //     'Reference:', '${data.sales![0].voucherNo ?? 'N/A'}', 1);
        // printer.printLeftRight('Date:', '${data.sales![0].inDate}', 1);
        // printer.printLeftRight('Due Date:', '${data.sales![0].inDate}', 1);
        // printer.printNewLine();

        // Collection Information
        if (data.collectionType == 'Cheque') {
          printAlignedText('Collection Type: Cheque', ' ');
          printAlignedText('Bank Name: ${data.bank}', ' ');
          printAlignedText('Cheque No: ${data.chequeNo}', ' ');
          printAlignedText('Cheque Date: ${data.chequeDate}', ' ');
        } else if (data.collectionType == 'Cash') {
          // Optional: Print something specific for cash or leave it out
          printAlignedText('Collection Type: Cash', ' '); // Uncomment if needed
        }
        printAlignedText('Amount: ${data.totalAmount}', ' ');
        // printer.printLeftRight('Collection Type:', '${data.collectionType}', 1);
        // printer.printLeftRight('Bank Name:', '${data.bank}', 1);
        // printer.printLeftRight('Cheque No:', '${data.chequeNo}', 1);
        // printer.printLeftRight('Cheque Date:', '${data.chequeDate}', 1);
        // printer.printLeftRight('Amount:', '${data.totalAmount}', 1);
        printer.printNewLine();
        printer.printCustom("-" * 72, 1, 1);
        const int columnWidth0 = 4;
        const int columnWidth1 = 14; // S.No
        const int columnWidth2 = 20; // Product Description
        const int columnWidth3 = 14; // Unit
        const int columnWidth4 = 5;
        String line;
        String headers = "${''.padRight(columnWidth0)}"
            "${'SI.NO'.padRight(columnWidth1)}"
            " ${'Reference NO'.padRight(columnWidth2)}"
            " ${'Type'.padRight(columnWidth3)}"
            "${'Amount'.padRight(columnWidth4)}";
        printer.printCustom(headers, 1, 0);
        printer.printCustom("-" * 72, 1, 1);
        // Sales List Header
        // printer.printCustom('SI NO   Reference No   Type   Amount', 1, 0);
        // printer.printCustom('---------------------------', 1, 0);

        // Iterate and print each sales item

        String formatInvoiceType(String? invoiceType) {
          if (invoiceType == null)
            return 'N/A'; // Return N/A if invoiceType is null

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

        for (var i = 0; i < data.sales!.length; i++) {
          var sale = data.sales![i];
          line = "${('').padRight(columnWidth0)}"
              "${(i + 1).toString().padRight(columnWidth1)}"
              " ${sale.invoiceNo?.padRight(columnWidth2) ?? 'N/A'.padRight(columnWidth2)}"
              "${formatInvoiceType(sale.invoiceType)?.padRight(columnWidth3) ?? 'N/A'.padRight(columnWidth3)}"
              "${sale.amount?.padRight(columnWidth4) ?? 'N/A'.padRight(columnWidth4)}";
          printer.printCustom(line, 1, 0);
        }
        printer.printNewLine();
        printer.printCustom("-" * 72, 1, 1);
        if (data.roundoff != null && double.parse(data.roundoff!) != 0) {
          printAlignedText('',
              'Round Off: ${double.parse(data.roundoff!).toStringAsFixed(2)}');
        }
        printAlignedText('', 'Total: ${data.totalAmount}');
        printAlignedText("Van: ${data.van![0].name}", "");
        printAlignedText("Salesman: ${data.user![0].name}", "");
        // printer.printLeftRight('Van:', '${data.vanId}', 1);
        // printer.printLeftRight('Salesman:', 'N/A', 1);
        printer.printNewLine();

        printer.paperCut();
      } // Cut paper after printing
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printer not connected')),
      );
    }
    if (!_connected) {
      await _connect();
    }
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
