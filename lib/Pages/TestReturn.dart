import 'dart:convert';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobizapp/Utilities/cpcl_helper.dart';
import '../Utilities/report_printer.dart';
import '../Reports/home_return_report.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'package:number_to_words/number_to_words.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:image/image.dart' as img;
import '../Models/invoicedata.dart' as Invoice;
import 'dart:typed_data';
import '../Components/commonwidgets.dart';
import '../Models/appstate.dart';
import '../Models/pdfgenerate.dart';
import '../Utilities/date_helper.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';

class HomereturnScreen extends StatefulWidget {
  static const routeName = "/HomereturnScreen";
  const HomereturnScreen({super.key});

  @override
  _HomereturnScreenState createState() => _HomereturnScreenState();
}

class _HomereturnScreenState extends State<HomereturnScreen> {
  List<VanReturn> salesList = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMoreData = true; // Indicates if there's more data to fetch
  bool _initDone = false;
  bool _noData = false;
  final ScrollController _scrollController = ScrollController();
  int? id;
  String? name;
  BluetoothDevice? _selectedDevice;
  List<BluetoothDevice> _devices = [];
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  bool _connected = false;
  List<int> selectedItems = [];
final TextEditingController _searchController = TextEditingController();
String _query = '';
bool _isSearching = false;
List<VanReturn> get _filteredList {
  final q = _query.trim().toLowerCase();
  if (q.isEmpty) return salesList;
  return salesList.where((s) {
    final inv = (s.invoiceNo ?? '').toLowerCase();
    final cust = (s.customer != null && s.customer!.isNotEmpty)
        ? (s.customer![0].name ?? '').toLowerCase()
        : '';
    return inv.contains(q) || cust.contains(q);
  }).toList();
}

// Search only sees loaded pages, so keep loading until enough matches are found
Future<void> _loadMoreForSearch() async {
  while (hasMoreData && !isLoading && _filteredList.length < 10) {
    await fetchVanSales();
  }
}

  Future<void> fetchVanSales() async {
    if (isLoading || !hasMoreData) return;

    setState(() => isLoading = true);

    final url = Uri.parse(
        "${RestDatasource().BASE_URL}/api/vansales_return.index?store_id=${AppState().storeId}&van_id=${AppState().vanId}&user_id=${AppState().userId}&page=$currentPage");
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print(response.request);
       final jsonResponse = json.decode(response.body);

        final vanSalesResponse = VanSalesResponse.fromJson(jsonResponse);

        setState(() {
          salesList.addAll(vanSalesResponse.data.vanSalesList);
          currentPage++;
          _initDone = true;
          isLoading = false;
          hasMoreData = vanSalesResponse
              .data.vanSalesList.isNotEmpty; // Check if there's more data
        });
      } else {
        print("Failed to load data: ${response.statusCode}");
        setState(() => hasMoreData = false);
      }
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() {
        isLoading = false;
        _noData = salesList.isEmpty;
        _initDone = true;
      });
    }
  }
  @override
  void initState() {
    super.initState();
    AppState().loadTaxName().then((_) {
      if (mounted) setState(() {});
    });
    fetchVanSales();
    _initPrinter();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !isLoading &&
          hasMoreData) {
        fetchVanSales();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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
Future<void> _printHomeReturnImage(Invoice.InvoiceData invoice) async {
  final storeList = invoice.data?.store;
  final logoName =
      storeList != null && storeList.isNotEmpty ? storeList.first.logo : null;

  final logo = logoName != null && logoName.isNotEmpty
      ? await loadLogo('$kHomeReturnLogoBaseUrl$logoName')
      : null;

  await printReport(
    printer,
    _selectedDevice,
    (b) => drawHomeReturnReport(b, invoice, logo: logo),
  );
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
          controller: _searchController,
          autofocus: true,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Search invoice no or customer',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (v) {
            setState(() => _query = v);
            _loadMoreForSearch();
          },
        )
      : const Text(
          'Return',
          style: AppConfig.pageTitleStyle,
        ),
  backgroundColor: AppConfig.colorPrimary,
  actions: [
    IconButton(
      icon: Icon(
        _isSearching ? Icons.close : Icons.search,
        color: Colors.white,
      ),
      onPressed: () {
        setState(() {
          if (_isSearching) {
            _searchController.clear();
            _query = '';
          }
          _isSearching = !_isSearching;
        });
      },
    ),
  ],
),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
    child: Column(
  children: [
    CommonWidgets.verticalSpace(1),
    Expanded(
      child: _initDone && !_noData
          ? (_filteredList.isEmpty && !isLoading
              ? const Center(child: Text('No results found'))
              : ListView.separated(
                  controller: _scrollController,
                  separatorBuilder: (context, index) =>
                      CommonWidgets.verticalSpace(1),
                  itemCount: _filteredList.length + 1,
                  itemBuilder: (context, index) {
                    final list = _filteredList;
                    if (index == list.length) {
                      return isLoading
                          ? const Center(
                              child: Text("Loading...",
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey)))
                          : Center(
                              child: Text("That's All",
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.w700)));
                    }
                    return _productsCard(list[index], index);
                  },
                ))
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
                        ),
            ),
          ],
        ),
      ),
    );
  }
String _discountText(VanReturn data) {
  final dec = AppState().noOfDecimals ?? 2;
  final String type = (data.discount_type ?? '').trim().toLowerCase();
  final bool isPercentage = type == '1' || type == 'percentage';

  num amount = data.discount_amount ?? 0;

  if (amount == 0 && (data.discount ?? 0) > 0) {
    amount = isPercentage
        ? (data.total ?? 0) * data.discount! / 100
        : data.discount!;
  }

  String label = 'Discount';
  if (isPercentage && (data.discount ?? 0) > 0) {
    final s = data.discount!
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    label = 'Discount ($s%)';
  }
  return '$label: ${amount.toStringAsFixed(dec)}';
}
  Widget _productsCard(VanReturn data, int index) {
    return Card(
      elevation: 1,
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
          padding: const EdgeInsets.all(5.0),
          child: ExpansionTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            trailing: Transform.rotate(
              angle: 100,
              child: const Icon(Icons.touch_app, color: Colors.transparent),
            ),
            backgroundColor: AppConfig.backgroundColor,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: data.invoiceNo!,
                  child: SizedBox(
                    width: SizeConfig.blockSizeHorizontal * 70,
                    child: Text(
                      '${data.invoiceNo!} | ${DateHelper.displayDate(data.inDate)} ${data.inTime}',
                      style: TextStyle(
                        fontSize: AppConfig.textCaption3Size,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    // Text(
                    //   (data.customer!.isNotEmpty)
                    //       ? data.customer![0].code ?? ''
                    //       : '',
                    //   style: TextStyle(
                    //       fontSize: AppConfig.textCaption3Size,
                    //       fontWeight: AppConfig.headLineWeight),
                    // ),
                    // Text(' | '),
                    Text(
                      (data.customer!.isNotEmpty)
                          ? data.customer![0].name ?? ''
                          : '',
                      style: TextStyle(
                          fontSize: AppConfig.textCaption3Size,
                          fontWeight: AppConfig.headLineWeight),
                    ),
                  ],
                ),
                // (data.detail!.isNotEmpty)
                // ? Text(
                //     'Type: ${data.detail![0].productType}',
                //     style: TextStyle(
                //       fontSize: AppConfig.textCaption3Size,
                //     ),
                //   )

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                                       Text(
                      'Total: ${data.total?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? ''}',
                      style: TextStyle(
                        fontSize: AppConfig.textCaption3Size,
                      ),
                    ),
                    Text(
                      "${data.status_text}",
                      style: TextStyle(
                        fontSize: AppConfig.textCaption3Size,
                        fontWeight: FontWeight.w600,
                        color: data.status_text == "Confirm"
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
                // : Text(
                //     'Type:  ',
                //     style: TextStyle(
                //       fontSize: AppConfig.textCaption3Size,
                //     ),
                //   ),
               Text(
  _discountText(data),
  style: TextStyle(
    fontSize: AppConfig.textCaption3Size,
  ),
),
                SizedBox(
                  width: SizeConfig.blockSizeHorizontal * 90,
                  child: Row(
                    children: [
                      Text(
                   'Round Off: ${(double.tryParse(data.roundOff ?? '') ?? 0).toStringAsFixed(AppState().noOfDecimals ?? 2)}',
                        style: TextStyle(
                          fontSize: AppConfig.textCaption3Size,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _getInvoicePrint(data.id!, false),
                        child: const Icon(
                          Icons.print,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                      CommonWidgets.horizontalSpace(4),
                      InkWell(
                        onTap: () => _getInvoiceData(data.id!, false),
                        child: const Icon(
                          Icons.document_scanner,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
                           Text(
  '${AppState().taxLabel}: ${data.totalTax?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? ''}',
                  style: TextStyle(
                    fontSize: AppConfig.textCaption3Size,
                  ),
                ),
                               Text(
                  'Grand Total: ${data.grandTotal?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? ''}',
                  style: TextStyle(
                    fontSize: AppConfig.textCaption3Size,
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(5.0),
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
                                  ),
                                ),
                                const Text(' | '),
                                Text(
                                  data.detail![i].unit ?? '',
                                  style: TextStyle(
                                    fontSize: AppConfig.textCaption3Size,
                                  ),
                                ),
                                const Text(' | '),
                                Text(
                                  'Qty: ${data.detail![i].quantity}',
                                  style: TextStyle(
                                    fontSize: AppConfig.textCaption3Size,
                                  ),
                                ),
                                const Text(' | '),
                                Text(
                                  'Rate: ${data.detail![i].mrp}',
                                  style: TextStyle(
                                    fontSize: AppConfig.textCaption3Size,
                                  ),
                                ),
                                const Text(' | '),
                                Text(
                                  'Amount: ${data.detail![i].amount}',
                                  style: TextStyle(
                                    fontSize: AppConfig.textCaption3Size,
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

  Future<void> _createPdf(Invoice.InvoiceData invoice, bool isPrint) async {
    PdfDocument document = PdfDocument();
    final page = document.pages.add();
    final Size pageSize = page.getClientSize();

    // Load the image.

    // ====== HEADER LAYOUT (LEFT TEXT + RIGHT LOGO) ======

    final double leftX = 20; // Left column start
    final double topY = 20; // Starting Y position
    double currentY = topY;
    final double pageWidth = page.getClientSize().width;

// Load logo
    final Uint8List? imageData =
        await _readImageData(invoice.data!.store![0].logo);
    if (imageData != null && imageData.isNotEmpty) {
      final PdfBitmap image = PdfBitmap(imageData);
      // Position logo at top-right (adjust width/height as needed)
      page.graphics.drawImage(
        image,
        Rect.fromLTWH(
          pageWidth - 100, // Right-aligned with 100px width
          30, // Top margin
          80, // Logo width
          80, // Logo height
        ),
      );
    }

// ----- LEFT COLUMN TEXT -----
// Store Name
    page.graphics.drawString(
      invoice.data!.store![0].name.toString(),
      PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(leftX, currentY, pageSize.width - 160, 25),
    );
    currentY += 22;

// Address
    page.graphics.drawString(
      invoice.data!.store![0].address ?? 'N/A',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(leftX, currentY, pageSize.width - 160, 20),
    );
    currentY += 18;

// Email
    page.graphics.drawString(
      invoice.data!.store![0].email ?? 'N/A',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(leftX, currentY, pageSize.width - 160, 20),
    );
    currentY += 18;

// TRN
    page.graphics.drawString(
        'TRN: ${invoice.data!.store![0].trn ?? 'N/A'}',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(leftX, currentY, pageSize.width - 160, 20),
    );
    currentY += 30;

// ===== TITLE BELOW HEADER =====
    final title = 'TAX CREDIT NOTE';
    final PdfFont titleFont =
        PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
    final Size titleSize = titleFont.measureString(title);

    page.graphics.drawString(
      title,
      titleFont,
      bounds: Rect.fromLTWH(
        (pageSize.width - titleSize.width) / 2,
        currentY,
        titleSize.width,
        titleSize.height,
      ),
    );

    // Draw a line below the text
    final double yPosition = 165;
    // final double pageWidth = page.getClientSize().width;
    final String text = 'TAX CREDIT NOTE';
    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 15);
    final Size textSize = font.measureString(text);
    final double lineYPosition =
        yPosition + textSize.height + 10; // Adjust the gap as needed
    page.graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0)), // Black pen
      Offset(0, lineYPosition),
      Offset(pageWidth, lineYPosition),
    );

  final cust = invoice.data!.customer![0];
final custCode = (cust.code ?? '').toString().trim();
final custEmail = (cust.email ?? '').toString().trim();
final custContact = (cust.contactNumber ?? '').toString().trim();
final custTrn = (cust.trn ?? '').toString().trim();

final addressLines = <String>[
  'Customer: ${custCode.isNotEmpty ? '$custCode | ' : ''}${cust.name ?? ''}',
  if (custEmail.isNotEmpty) 'Email: $custEmail',
  if (custContact.isNotEmpty) 'Contact No: $custContact',
  if (custTrn.isNotEmpty) 'TRN: $custTrn',
];
final String address = addressLines.join('\n');

    String invoiceDetails = '''
  Reference No: ${invoice.data!.invoiceNo!}
  Date: ${DateHelper.displayDate(invoice.data!.inDate)}
  Due Date: ${DateHelper.displayDate(invoice.data!.inDate)}
  ''';

    page.graphics.drawString(
      address,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(0, 200, pageSize.width / 2, 100),
    );

    page.graphics.drawString(
      invoiceDetails,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(pageSize.width / 2, 200, pageSize.width / 2, 100),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.right,
      ),
    );

    // Draw a horizontal line.
    page.graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0)),
      const Offset(0, 290),
      Offset(pageSize.width, 290),
    );

    // Create a table without grid lines.
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 9);
    // Set column widths.
    grid.columns[0].width = 30; // Sl.No
    grid.columns[1].width = 180; // Product
    grid.columns[2].width = 40; // Unit
    grid.columns[3].width = 40; // Rate
    grid.columns[4].width = 50; // Qty
    grid.columns[5].width = 50; // Foc
    grid.columns[6].width = 40; // Vat
    grid.columns[7].width = 50;
    grid.columns[8].width = 100;

    // Add headers.
    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'Sl.No';
    headerRow.cells[1].value = 'Product';
    headerRow.cells[2].value = 'Unit';
    headerRow.cells[3].value = 'Qty';
    headerRow.cells[4].value = 'Type';
    headerRow.cells[5].value = 'Rate';
    headerRow.cells[6].value = 'Total';
       headerRow.cells[7].value = AppState().taxLabel;
    headerRow.cells[8].value = 'Amount';

    for (int k = 0; k < invoice.data!.detail!.length; k++) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = '${k + 1}';
      row.cells[1].value = '${invoice.data!.detail![k].name}';
      row.cells[2].value = '${invoice.data!.detail![k].unit}';
      row.cells[3].value = '${invoice.data!.detail![k].quantity}';
           row.cells[4].value = invoice.data!.detail![k].productType ?? '';
      // row.cells[4].value = (invoice.data!.detail![k].productType!.toLowerCase() == "foc" || invoice.data!.detail![k].productType!.toLowerCase() == "FOC" || invoice.data!.detail![k].productType!.toLowerCase() == "Change") ? 'Normal' : 'Normal';
      row.cells[5].value = '${invoice.data!.detail![k].mrp}';
      row.cells[6].value = '${invoice.data!.detail![k].taxable}';
      row.cells[7].value = '${invoice.data!.detail![k].taxAmt}';
      row.cells[8].value = '${invoice.data!.detail![k].amount}';
    }

    // Define no border style
    final PdfBorders noBorder = PdfBorders(
      left: PdfPen(PdfColor(255, 255, 255), width: 0),
      top: PdfPen(PdfColor(255, 255, 255), width: 0),
      right: PdfPen(PdfColor(255, 255, 255), width: 0),
      bottom: PdfPen(PdfColor(255, 255, 255), width: 0),
    );

    // Remove borders from all header cells
    for (int j = 0; j < grid.headers.count; j++) {
      for (int k = 0; k < grid.headers[j].cells.count; k++) {
        grid.headers[j].cells[k].style.borders = noBorder;
      }
    }

    // Remove borders from all body cells
    for (int i = 0; i < grid.rows.count; i++) {
      for (int j = 0; j < grid.columns.count; j++) {
        grid.rows[i].cells[j].style.borders = noBorder;
      }
    }

    // Draw the table.
    final PdfLayoutResult result = grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 300, pageSize.width, pageSize.height - 180),
    )!;

    //   // Calculate the Y position for the line after the first row
    // final double firstRowHeight = grid.headers[0].height + grid.rows[0].height;

    // // Draw a line after the first row of the grid
    // page.graphics.drawLine(
    //   PdfPen(PdfColor(0, 0, 0), width: 1),
    //   Offset(0, result.bounds.top + firstRowHeight),
    //   Offset(pageSize.width, result.bounds.top + firstRowHeight),
    // );
    // Check if the table extends to the next page
    PdfPage lastPage = result.page;
    double tableBottom = result.bounds.bottom;

    if (tableBottom >= pageSize.height) {
      // Add a new page
      lastPage = document.pages.add();
      tableBottom = 0;
    }

    // Draw a horizontal line after the table.
    lastPage.graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0)),
      Offset(0, tableBottom + 15),
      Offset(pageSize.width, tableBottom + 15),
    );

    // Draw invoice details at the bottom right.
    // ${num.parse(invoice.data!.roundOff.toString()) != 0 ? 'Discount: ${invoice.data!.discount}' : '\t'}
       final dec = AppState().noOfDecimals ?? 2;
    final inv = invoice.data!;
    final roundOffVal = num.tryParse(inv.roundOff?.toString() ?? '') ?? 0;
    final disc = inv.effectiveDiscount;
    final subTotal = (inv.total ?? 0) - disc;

    final totalsLines = <String>[
      'Total: ${(inv.total ?? 0).toStringAsFixed(dec)}',
      if (disc > 0) '${inv.discountLabel}: ${disc.toStringAsFixed(dec)}',
      'Sub Total: ${subTotal.toStringAsFixed(dec)}',
      '${AppState().taxLabel}: ${(inv.totalTax ?? 0).toStringAsFixed(dec)}',
      if (roundOffVal != 0) 'Round off: ${roundOffVal.toStringAsFixed(dec)}',
      'Grand Total: ${(inv.grandTotal ?? 0).toStringAsFixed(dec)}',
    ];
    String bottomInvoiceDetails = totalsLines.join('\n');
    lastPage.graphics.drawString(
      bottomInvoiceDetails,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(
        pageSize.width / 2,
        tableBottom + 20,
        pageSize.width / 2,
        100,
      ),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.right,
      ),
    );
String textData = _pdfSafe(_amountInWords(invoice.data!.grandTotal ?? 0));

final vanName = (invoice.data!.van != null && invoice.data!.van!.isNotEmpty)
    ? invoice.data!.van![0].name ?? ''
    : '';
final salesmanName =
    (invoice.data!.user != null && invoice.data!.user!.isNotEmpty)
        ? invoice.data!.user![0].name ?? ''
        : '';
final String bottomVanDetails = '''
Van: $vanName
Salesman: $salesmanName
''';

// Wrapped, centered amount in words (grows in height as needed)
final PdfLayoutResult wordsResult = PdfTextElement(
  text: textData,
  font: PdfStandardFont(PdfFontFamily.helvetica, 12),
  format: PdfStringFormat(
    alignment: PdfTextAlignment.center,
    wordWrap: PdfWordWrapType.word,
  ),
).draw(
  page: lastPage,
  bounds: Rect.fromLTWH(20, tableBottom + 130, pageSize.width - 40, 0),
)!;

// Van details sit below the amount in words
final double vanDetailsTop = wordsResult.bounds.bottom + 15;
lastPage.graphics.drawString(
  bottomVanDetails,
  PdfStandardFont(PdfFontFamily.helvetica, 12),
  bounds: Rect.fromLTWH(0, vanDetailsTop, pageSize.width / 2, 100),
  format: PdfStringFormat(alignment: PdfTextAlignment.left),
);
    List<int> bytes = await document.save();
    document.dispose();

    String file = await saveAndLaunchFile(
        bytes, '${invoice.data!.invoiceNo!}.pdf', isPrint);
  }
/// Main Print Dispatcher: Routes automatically to Zebra (CPCL) or Sewoo (ESC/POS)
 Future<void> _print(Invoice.InvoiceData invoice, bool isPrint) async {
  final bool? isActuallyConnected = await printer.isConnected;

   if (isActuallyConnected != true) {
    _connected = false;
    try {
      await _connect();
    } catch (e) {
      print('Connect error: $e');
    }
  }
  if (!_connected) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printer not connected')),
    );
    return;
  }

  try {
  if (isZebraPrinter(_selectedDevice)) {
  await _printHomeReturnImage(invoice);
} else {
  await _printSewoo(invoice, isPrint);
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
  // 1. ZEBRA ENGINE (CPCL Mode)
  // ═══════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════
  // 1. ZEBRA ENGINE (CPCL Mode - Clean 2-Line Layout, No Overlap)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _printZebra(Invoice.InvoiceData invoice, bool isPrint) async {
    String companyName = invoice.data!.store![0].name ?? 'N/A';
    String companyAddress = invoice.data!.store![0].address ?? 'N/A';
    String companyMail = invoice.data!.store![0].email ?? 'N/A';
    String companyTRN = "TRN: ${invoice.data!.store![0].trn ?? 'N/A'}";
    String billtype = "TAX CREDIT NOTE";
    String customerName = "${invoice.data!.customer![0].name}";
    List<String> nameWords = customerName.split(' ');
    String firstLine = customerName;
    String secondLine = "";
    if (nameWords.length > 4) {
      firstLine = nameWords.sublist(0, 4).join(' ');
      secondLine = nameWords.sublist(4).join(' ');
    }
    String customerEmail = invoice.data!.customer![0].email ?? 'N/A';
    String customerContact = invoice.data!.customer![0].contactNumber ?? 'N/A';
    String customerTRN = invoice.data!.customer![0].trn ?? '';
    String invoiceNumber = invoice.data!.invoiceNo ?? 'N/A';
    String invoiceDate = DateHelper.displayDate(invoice.data!.inDate);
    String dueDate = DateHelper.displayDate(invoice.data!.inDate);
    String total =
        invoice.data!.total?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
            '0.00';
    String tax = invoice.data!.totalTax
            ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
        '0.00';
    String grandTotal = invoice.data!.grandTotal
            ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
        '0.00';
    String discount = '';
    if (invoice.data!.effectiveDiscount > 0) {
      discount =
          "Discount: ${invoice.data!.effectiveDiscount.toStringAsFixed(AppState().noOfDecimals ?? 2)}";
    }
    String amountInWords =
        "Amount in Words: ${AppState().code} ${NumberToWord().convert('en-in', invoice.data!.grandTotal?.toInt() ?? 0).toUpperCase()} ONLY";
    String van = (invoice.data!.van != null && invoice.data!.van!.isNotEmpty)
        ? (invoice.data!.van![0].name ?? 'N/A')
        : 'N/A';
    String salesman = (invoice.data!.user != null && invoice.data!.user!.isNotEmpty)
        ? (invoice.data!.user![0].name ?? 'N/A')
        : 'N/A';

    final cpcl = CpclBuilder(kLabelWidthDots);

    // ---- 1. Logo ----
    if (invoice.data!.store != null &&
        invoice.data!.store!.isNotEmpty &&
        invoice.data!.store![0].logo != null &&
        invoice.data!.store![0].logo!.isNotEmpty) {
      try {
        String logoUrl =
            'https://erpadmin.mobiz.ae/uploads/store/${invoice.data!.store![0].logo}';
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

    // ---- 2. Company header ----
    cpcl.centerText(companyName, font: 5, lineGap: 34);
    if (companyAddress != 'N/A') cpcl.centerText(companyAddress, font: 4, lineGap: 24);
    if (companyMail != 'N/A') cpcl.centerText(companyMail, font: 4, lineGap: 24);
    if (companyTRN != 'TRN: N/A') cpcl.centerText(companyTRN, font: 4, lineGap: 24);
    cpcl.hLine();
    cpcl.centerText(billtype, font: 5, lineGap: 34);
    cpcl.hLine();

    // ---- 3. Customer / invoice info ----
    cpcl.twoColumn("Customer: $firstLine", "Ref: $invoiceNumber");
    if (secondLine.isNotEmpty) {
      cpcl.text("         $secondLine");
    }
    if (customerEmail != 'N/A' && customerEmail.isNotEmpty) {
      cpcl.text("Email: $customerEmail");
    }
    cpcl.twoColumn("Contact: $customerContact", "Date: $invoiceDate");
    if (customerTRN.isNotEmpty) {
      cpcl.twoColumn("TRN: $customerTRN", "Due: $dueDate");
    } else {
      cpcl.text("Due Date: $dueDate");
    }
    cpcl.hLine();

    // ---- 4. Table Header (Max 42 chars - fits 576 dots perfectly) ----
    // Format: S.No (4) | Description (18) | Qty (6) | Rate (7) | Total (7)
    cpcl.text("S.No Product             Qty    Rate   Total", font: 4, lineGap: 30);
    cpcl.hLine(thickness: 1);

    for (int i = 0; i < (invoice.data!.detail?.length ?? 0); i++) {
      var d = invoice.data!.detail![i];
      String sNo = (i + 1).toString().padRight(4);
      String name = (d.name ?? 'N/A').toUpperCase();
      if (name.length > 38) name = name.substring(0, 38);

      String qty = "${d.quantity ?? 0} ${d.unit ?? ''}".trim().padLeft(6);
      String rate = (d.mrp?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00').padLeft(7);
      String itemTotal = (d.amount?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00').padLeft(8);

      // Line 1: S.No + Product Name
      cpcl.text('$sNo$name', font: 4, lineGap: 28);
      // Line 2: Details right-aligned (Never overlaps!)
      String details = '     Type:${d.productType ?? "Normal"}'.padRight(21) + '$qty $rate $itemTotal';
      cpcl.text(details, font: 4, lineGap: 30);
    }
    cpcl.hLine(thickness: 1);

    // ---- 5. Totals Section ----
    if (discount.isNotEmpty) {
      cpcl.twoColumn("Van: $van", discount);
    } else {
      cpcl.twoColumn("Van: $van", "");
    }
    cpcl.twoColumn("Salesman: $salesman", "Total: $total");
     cpcl.twoColumn("", "${AppState().taxLabel}: $tax");
    cpcl.boldText("Grand Total: $grandTotal", font: 5, x: 220, lineGap: 36);

    cpcl.feed(10);
    for (final line in _splitText(amountInWords, 44)) {
      cpcl.text(line, font: 4, lineGap: 26);
    }
    cpcl.feed(40);

    final bytes = cpcl.build();
    await sendCpcl(printer, bytes);
  }
  // ═══════════════════════════════════════════════════════════════
  // 2. SEWOO ENGINE (Original ESC/POS Mode - Your exact old code)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _printSewoo(Invoice.InvoiceData invoice, bool isPrint) async {
    String companyName = invoice.data!.store![0].name ?? 'N/A';
    String companyAddress = invoice.data!.store![0].address ?? 'N/A';
    String companyMail = invoice.data!.store![0].email ?? 'N/A';
    String companyTRN = "TRN: ${invoice.data!.store![0].trn ?? 'N/A'}";
    String billtype = "TAX CREDIT NOTE";
    String customerName = "${invoice.data!.customer![0].name}";
    List<String> nameWords = customerName.split(' ');
    String firstLine = customerName;
    String secondLine = "";
    if (nameWords.length > 4) {
      firstLine = nameWords.sublist(0, 4).join(' ');
      secondLine = nameWords.sublist(4).join(' ');
    }
    String customerEmail = invoice.data!.customer![0].email ?? 'N/A';
    String customerContact = invoice.data!.customer![0].contactNumber ?? 'N/A';
    String customerTRN = invoice.data!.customer![0].trn ?? '';
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
        final String Discount = invoice.data!.effectiveDiscount > 0
        ? "${invoice.data!.discountLabel}: ${invoice.data!.effectiveDiscount.toStringAsFixed(AppState().noOfDecimals ?? 2)}"
        : '';
       final amountInWords = _amountInWords(invoice.data!.grandTotal ?? 0);
    String van = invoice.data!.van?.firstOrNull?.name ?? 'N/A';
    String salesman = invoice.data!.user?.firstOrNull?.name ?? 'N/A';

    void printAlignedText(String leftText, String rightText) {
      const int maxLineLength = 68;
      int leftTextLength = leftText.length;
      int rightTextLength = rightText.length;

      int spaceLength = maxLineLength - (leftTextLength + rightTextLength);
      if (spaceLength < 1) spaceLength = 1;
      String spaces = ' ' * spaceLength;

      printer.printCustom('$leftText$spaces$rightText', 1, 0);
    }

     String logoUrl =
        'https://erpadmin.mobiz.ae/uploads/store/${invoice.data!.store![0].logo}';
    if (logoUrl.isNotEmpty) {
      try {
        final logoBytes = await buildSewooLogoBytes(logoUrl);
        if (logoBytes != null) {
          await printer.printImageBytes(logoBytes);
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        print('Sewoo logo error: $e');
      }
    }

    printer.printNewLine();
    printer.printCustom(companyName, 3, 1);
    printer.printCustom(companyAddress, 1, 1);
    printer.printCustom(companyMail, 1, 1);
    printer.printCustom(companyTRN, 1, 1);
    printer.printCustom(billtype, 1, 1);
    printer.printNewLine();

    printer.printCustom("-" * 72, 1, 1);
    printAlignedText(
        "Customer: $firstLine", "Reference No: $invoiceNumber      ");

    if (secondLine.isNotEmpty) {
      printAlignedText("         $secondLine", "");
    }
    printAlignedText("Email: $customerEmail", "Date: $invoiceDate    ");
    printAlignedText("Contact No: $customerContact", "Due Date: $dueDate");
    printAlignedText("TRN: $customerTRN", " ");
    printer.printNewLine();

    printer.printCustom("-" * 70, 1, 1);

  const int columnWidth1 = 3; // #
    const int columnWidth2 = 16; // Product
    const int columnWidth3 = 4; // Unit
    const int columnWidth4 = 4; // Qty
    const int columnWidth5 = 7; // Type
    const int columnWidth6 = 8; // Rate
    const int columnWidth7 = 8; // Amount
    const int columnWidth8 = 8; // Vat
    const int columnWidth9 = 8; // Total

    final String vatHeader = AppState().taxLabel.isNotEmpty ? AppState().taxLabel : 'VAT 5%';

    String headers = "${'#'.padRight(columnWidth1)}"
        "${'Product'.padRight(columnWidth2)} "
        "${'Unit'.padRight(columnWidth3)}"
        "${'Qty'.padLeft(columnWidth4)}"
        "${'Type'.padLeft(columnWidth5)}"
        "${'Rate'.padLeft(columnWidth6)}"
        "${'Amount'.padLeft(columnWidth7)}"
        "${vatHeader.padLeft(columnWidth8)}"
        "${'Total'.padLeft(columnWidth9)}";
    printer.printCustom(headers, 1, 0);
    for (int i = 0; i < (invoice.data!.detail?.length ?? 0); i++) {
      String productDescription = invoice.data!.detail![i].name ?? 'N/A';
      String productUnit = invoice.data!.detail![i].unit ?? 'N/A';
      String productQty = invoice.data!.detail![i].quantity?.toString() ?? '0';
      String productType = invoice.data!.detail![i].productType?.toString() ?? '';
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

       List<String> descriptionLines =
          _wrapWords(productDescription, columnWidth2);

      for (int j = 0; j < descriptionLines.length; j++) {
        String line = j == 0
            ? "${(i + 1).toString().padRight(columnWidth1)}"
                "${descriptionLines[j].padRight(columnWidth2)} "
                "${productUnit.padRight(columnWidth3)}"
                "${productQty.padLeft(columnWidth4)}"
                "${productType.padLeft(columnWidth5)}"
                "${productRate.padLeft(columnWidth6)}"
                "${productTotal.padLeft(columnWidth7)}"
                "${productTax.padLeft(columnWidth8)}"
                "${productAmount.padLeft(columnWidth9)}"
            : "${''.padRight(columnWidth1)}"
                "${descriptionLines[j].padRight(columnWidth2)}";
        printer.printCustom(line, 1, 0);
      }
    }
    printer.printCustom("-" * 70, 1, 1);

    final subTotalVal =
        (invoice.data!.total ?? 0) - invoice.data!.effectiveDiscount;
    final subTotal =
        subTotalVal.toStringAsFixed(AppState().noOfDecimals ?? 2);

    printAlignedText("Van      : $van", "Total: $Total");
    if (Discount.isNotEmpty) {
      printAlignedText("Salesman : $salesman", "$Discount");
    } else {
      printAlignedText("Salesman : $salesman", "");
    }
    printAlignedText("", "Sub Total: $subTotal");
    printAlignedText("", "${AppState().taxLabel}: $tax");
    printAlignedText("", "Grand Total: $grandTotal");
    printer.printNewLine();
  for (final line in _wrapWords(amountInWords, 48)) {
  printer.printCustom(line, 1, 0);
}

    printer.paperCut();
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

  List<String> _wrapWords(String text, int width) {
    final lines = <String>[];
    var current = '';
    for (final word in text.trim().split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      if (word.length > width) {
        if (current.isNotEmpty) {
          lines.add(current);
          current = '';
        }
        var w = word;
        while (w.length > width) {
          lines.add(w.substring(0, width));
          w = w.substring(width);
        }
        current = w;
      } else if (current.isEmpty) {
        current = word;
      } else if (current.length + 1 + word.length <= width) {
        current = '$current $word';
      } else {
        lines.add(current);
        current = word;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines.isEmpty ? [''] : lines;
  }
// Helvetica can't draw non-Latin characters, so strip them to avoid cut-off text
String _pdfSafe(String s) => s
    .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
 String _amountInWords(num amount) {
  print('CURRENCY: ${AppState().code} / ${AppState().minor} / ${AppState().noOfDecimals}');
  final dec = AppState().noOfDecimals ?? 2;
  final parts = amount.toStringAsFixed(dec).split('.');
    final whole = int.parse(parts[0]);
    final minor = parts.length > 1 ? int.parse(parts[1]) : 0;

    var words = "Amount in Words: ${AppState().code} "
        "${NumberToWord().convert('en-in', whole).toUpperCase()}";

    if (minor > 0) {
      words += " AND ${NumberToWord().convert('en-in', minor).toUpperCase()} "
          "${AppState().minor}";
    }

    return "$words ONLY";
  }
  // void _print(Invoice.InvoiceData invoice, bool isPrint) async {
  // void _print(Invoice.InvoiceData invoice, bool isPrint) async {
  //   if (_connected) {
  //     String companyName = invoice.data!.store![0].name ?? 'N/A';
  //     String companyAddress = invoice.data!.store![0].address ?? 'N/A';
  //     String companyMail = invoice.data!.store![0].email ?? 'N/A';
  //     String companyTRN = "TRN: ${invoice.data!.store![0].trn ?? 'N/A'}";
  //     String billtype = "TAX CREDIT NOTE";
  //     String customerName = "${invoice.data!.customer![0].name}";
  //     List<String> nameWords = customerName.split(' ');
  //     String firstLine = customerName;
  //     String secondLine = "";
  //     if (nameWords.length > 4) {
  //       firstLine = nameWords.sublist(0, 4).join(' ');
  //       secondLine = nameWords.sublist(4).join(' ');
  //     }
  //     String customerEmail = invoice.data!.customer![0].email ?? 'N/A';
  //     String customerContact =
  //         invoice.data!.customer![0].contactNumber ?? 'N/A';
  //     String customerTRN = invoice.data!.customer![0].trn ?? '';
  //     String invoiceNumber = invoice.data!.invoiceNo ?? 'N/A';
  //     String invoiceDate = DateHelper.displayDate(invoice.data!.inDate);
  //     String dueDate = DateHelper.displayDate(invoice.data!.inDate);
  //     String Total =
  //         invoice.data!.total?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
  //             '0.00';
  //     String tax = invoice.data!.totalTax
  //             ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
  //         '0.00';
  //     String grandTotal = invoice.data!.grandTotal
  //             ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
  //         '0.00';
  //     String Discount;
  //     if (invoice.data!.discount != null &&
  //         double.tryParse(invoice.data!.discount!.toString()) != null &&
  //         double.parse(invoice.data!.discount!.toString()) > 0) {
  //       Discount =
  //           "Discount: ${double.parse(invoice.data!.discount!.toString()).toStringAsFixed(AppState().noOfDecimals ?? 2)}";
  //     } else {
  //       Discount = '';
  //     }
  //     String amountInWords =
  //         "Amount in Words: AED ${NumberToWord().convert('en-in', invoice.data!.grandTotal?.toInt() ?? 0).toUpperCase()} ONLY";
  //     String van = invoice.data!.van![0].name ?? 'N/A';
  //     String salesman = invoice.data!.user![0].name ?? 'N/A';

  //     void printAlignedText(String leftText, String rightText) {
  //       const int maxLineLength =
  //           68; // Adjust the maximum line length as per your printer's character limit
  //       int leftTextLength = leftText.length;
  //       int rightTextLength = rightText.length;

  //       // Calculate padding to ensure rightText is right-aligned
  //       int spaceLength = maxLineLength - (leftTextLength + rightTextLength);
  //       String spaces = ' ' * spaceLength;

  //       printer.printCustom(
  //           '$leftText$spaces$rightText', 1, 0); // Print with left-aligned text
  //     }

  //     String logoUrl =
  //         'https://erpadmin.mobiz.ae/uploads/store/${invoice.data!.store![0].logo}';
  //     if (logoUrl.isNotEmpty) {
  //       final response = await http.get(Uri.parse(logoUrl));
  //       if (response.statusCode == 200) {
  //         Uint8List imageBytes = response.bodyBytes;

  //         // Decode image and convert to monochrome bitmap if needed
  //         img.Image originalImage = img.decodeImage(imageBytes)!;
  //         img.Image monoLogo = img.grayscale(originalImage);

  //         // Encode the image to the required format (e.g., PNG)
  //         Uint8List logoBytes = Uint8List.fromList(img.encodePng(monoLogo));

  //         // Print the logo image
  //         printer.printImageBytes(logoBytes);
  //       } else {
  //         print('Failed to load image: ${response.statusCode}');
  //       }
  //     }
  //     // Print company details
  //     printer.printNewLine();
  //     printer.printCustom(companyName, 3, 1); // Centered
  //     printer.printCustom(companyAddress, 1, 1); // Centered
  //     printer.printCustom(companyMail, 1, 1);
  //     printer.printCustom(companyTRN, 1, 1); // Centered
  //     printer.printCustom(billtype, 1, 1); // Centered
  //     printer.printNewLine();

  //     // Print horizontal line
  //     printer.printCustom("-" * 72, 1, 1); // Centered

  //     // Print customer details
  //     printAlignedText(
  //         "Customer: $firstLine", "Reference No: $invoiceNumber      ");

  //     if (secondLine.isNotEmpty) {
  //       printAlignedText("         $secondLine",
  //           ""); // Aligns the second line under the first line
  //     }
  //     printAlignedText("Email: $customerEmail", "Date: $invoiceDate    ");
  //     printAlignedText("Contact No: $customerContact", "Due Date: $dueDate");
  //     printAlignedText("TRN: $customerTRN", " ");
  //     printer.printNewLine();

  //     // Print horizontal line
  //     printer.printCustom("-" * 70, 1, 1); // Centered

  //     // Define column widths for table
  //     const int columnWidth1 = 5; // S.No
  //     const int columnWidth2 = 22; // Product Description
  //     const int columnWidth3 = 5; // Unit
  //     const int columnWidth4 = 4; // Qty
  //     const int columnWidth5 = 7; // Type
  //     const int columnWidth6 = 8; // Rate
  //     const int columnWidth7 = 8; // Total
  //     // const int columnWidth8 = 4; // Tax
  //     const int columnWidth9 = 6; // Amount

  //     // Print table headers
  //     String headers = "${'S.No'.padRight(columnWidth1)}"
  //         " ${'Product'.padRight(columnWidth2)}"
  //         " ${'Unit'.padRight(columnWidth3)}"
  //         "${'Qty'.padRight(columnWidth4)}"
  //         "${'Type'.padRight(columnWidth5)}"
  //         "${'Rate'.padRight(columnWidth6)}"
  //         "${'Amount'.padRight(columnWidth7)}"
  //         // "${'Vat'.padRight(columnWidth8)}"
  //         " ${'Total'.padLeft(columnWidth9)}";
  //     printer.printCustom(headers, 1, 0); // Left aligned

  //     // Function to split text into lines of a given width
  //     List<String> splitText(String text, int width) {
  //       List<String> lines = [];
  //       while (text.length > width) {
  //         lines.add(text.substring(0, width));
  //         text = text.substring(width);
  //       }
  //       lines.add(text); // Add remaining part
  //       return lines;
  //     }

  //     // Print all product details
  //     for (int i = 0; i < invoice.data!.detail!.length; i++) {
  //       String productDescription = invoice.data!.detail![i].name ?? 'N/A';
  //       String productUnit = invoice.data!.detail![i].unit ?? 'N/A';
  //       String productQty =
  //           invoice.data!.detail![i].quantity?.toString() ?? '0';
  //       String productType =
  //           invoice.data!.detail![i].productType?.toString() ?? '0';
  //       String productRate = invoice.data!.detail![i].mrp
  //               ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
  //           '0.00';
  //       String productTotal = invoice.data!.detail![i].taxable
  //               ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
  //           '0.00';
  //       // String productTax = tax.toString();
  //       String productAmount = invoice.data!.detail![i].amount
  //               ?.toStringAsFixed(AppState().noOfDecimals ?? 2) ??
  //           '0.00';
  //       // (invoice.data!.detail![i].mrp! * invoice.data!.detail![i].quantity!)
  //       //     .toStringAsFixed(AppState().noOfDecimals ?? 2);

  //       // Split the product description if it exceeds the column width
  //       List<String> descriptionLines =
  //           splitText(productDescription, columnWidth2);

  //       for (int j = 0; j < descriptionLines.length; j++) {
  //         String line;
  //         if (j == 0) {
  //           // For the first line, include all columns
  //           line = "${(i + 1).toString().padRight(columnWidth1)}"
  //               "${descriptionLines[j].padRight(columnWidth2)}"
  //               "  ${productUnit.padRight(columnWidth3)}"
  //               "${productQty.padRight(columnWidth4)}"
  //               "${productType.padRight(columnWidth5)}"
  //               "${productRate.padRight(columnWidth6)}"
  //               "${productTotal.padRight(columnWidth7)}"
  //               // "${productTax.padRight(columnWidth8)}"
  //               "${productAmount.padLeft(columnWidth9)}";
  //         } else {
  //           // For subsequent lines, only include the description, leaving other columns blank
  //           line = "${''.padRight(columnWidth1)}"
  //               "${descriptionLines[j].padRight(columnWidth2)}"
  //               "${''.padRight(columnWidth3)}"
  //               "${''.padRight(columnWidth4)}"
  //               "${''.padRight(columnWidth5)}"
  //               "${''.padRight(columnWidth6)}"
  //               "${''.padRight(columnWidth7)}";
  //           // "${''.padRight(columnWidth8)}";
  //           "${''.padRight(columnWidth9)}";
  //         }
  //         printer.printCustom(line, 1, 0); // Left aligned
  //       }
  //     }
  //     printer.printCustom("-" * 70, 1, 1); // Centered

  //     // Print totals
  //     if (Discount.isNotEmpty) {
  //       print(Discount);
  //       printAlignedText("Van: $van", "$Discount");
  //     } else {
  //       printAlignedText("Van: $van", ""); // Skip printing Total
  //     }
  //     printAlignedText("Salesman: $salesman", "Total: $Total");
  //     printer.printCustom(
  //       "${AppState().vatLabel ?? 'Tax'}: $tax",
  //       1,
  //       2,
  //     );
  //     printer.printCustom("Grand Total: $grandTotal", 1, 2); // Right aligned
  //     printer.printNewLine();
  //     printer.printCustom(amountInWords, 1, 0); // Centered

  //     // Cut the paper
  //     printer.paperCut();
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Printer not connected')),
  //     );
  //   }
  // }

  Future<Uint8List> _readImageData(String? image) async {
    try {
      final response = await http
          .get(Uri.parse('${RestDatasource().Image_URL}/uploads/store/$image'));

      print('Response Data $response');

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to load image');
      }
    } catch (e) {
      // Log the error and return an empty Uint8List
      print('Error loading image: $e');
      return Uint8List(0);
    }
  }

   Future<void> _getInvoiceData(int id, bool isPrint) async {
    try {
      await AppState().loadTaxName();
      Invoice.InvoiceData invoice = Invoice.InvoiceData();
      RestDatasource api = RestDatasource();
      dynamic response = await api.getDetails(
          '/api/get_sales_return_invoice?id=$id', AppState().token);

      if (response['data'] != null) {
        invoice = Invoice.InvoiceData.fromJson(response);
        await _createPdf(invoice, isPrint);
      }
    } catch (e, st) {
      print('Return PDF error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

   Future<void> _getInvoicePrint(int id, bool isPrint) async {
    if (_selectedDevice == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default device not found')),
        );
      }
      return;
    }

    try {
      await AppState().loadTaxName();
      Invoice.InvoiceData invoice = Invoice.InvoiceData();
      RestDatasource api = RestDatasource();
      dynamic response = await api.getDetails(
          '/api/get_sales_return_invoice?id=$id', AppState().token);

      if (response['data'] != null) {
        invoice = Invoice.InvoiceData.fromJson(response);
        await _print(invoice, isPrint);
      }
    } catch (e, st) {
      print('Return print error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing return: $e')),
        );
      }
    }
  }
}

class VanSalesResponse {
  final Data data;
  final bool success;
  final List<dynamic> messages;

  VanSalesResponse(
      {required this.data, required this.success, required this.messages});

  factory VanSalesResponse.fromJson(Map<String, dynamic> json) {
    return VanSalesResponse(
      data: Data.fromJson(json['data']),
      success: json['success'],
      messages: json['messages'],
    );
  }
}

class Data {
  final int currentPage;
  final List<VanReturn> vanSalesList;
  final int totalPages;
  final String? nextPageUrl;

  Data({
    required this.currentPage,
    required this.vanSalesList,
    required this.totalPages,
    this.nextPageUrl,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      currentPage: json['current_page'],
      vanSalesList:
          (json['data'] as List).map((e) => VanReturn.fromJson(e)).toList(),
      totalPages: json['last_page'],
      nextPageUrl: json['next_page_url'],
    );
  }
}

class VanReturn {
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
   String? status_text;
  String? discount_type;
  num? discount_amount;
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

  VanReturn(
      {this.id,
      this.customerId,
      this.billMode,
      this.inDate,
      this.inTime,
      this.invoiceNo,
           this.discount_type,
      this.discount_amount,
      this.deliveryNo,
      this.otherCharge,
      this.discount,
      this.roundOff,
      this.status_text,
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
      this.customer});

  VanReturn.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    customerId = json['customer_id'];
    billMode = json['bill_mode'] ?? '';
    inDate = json['in_date'] ?? '';
    inTime = json['in_time'] ?? '';
    invoiceNo = json['invoice_no'] ?? '';
    deliveryNo = json['delivery_no'] ?? '';
    otherCharge = json['other_charge'] ?? 0;
    discount = json['discount'] ?? 0;
     discount_type = json['discount_type']?.toString() ?? '';
    discount_amount =
        num.tryParse(json['discount_amount']?.toString() ?? '') ?? 0;
    roundOff = json['round_off'] ?? '';
    status_text = json['status_text'] ?? '';
       total = num.tryParse(json['total']?.toString() ?? '') ?? 0;
    totalTax = num.tryParse(json['total_tax']?.toString() ?? '') ?? 0;
    grandTotal = num.tryParse(json['grand_total']?.toString() ?? '') ?? 0;
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
        customer!.add(Customer.fromJson(v));
      });
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
