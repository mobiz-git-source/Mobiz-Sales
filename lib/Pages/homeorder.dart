import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/main.dart';
import 'package:number_to_words/number_to_words.dart';
import 'package:printing/printing.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;

import '../Models/invoicedata.dart' as Invoice;
import '../Models/pdfgenerate.dart';
import '../Models/productquantirydetails.dart' as Qty;
import '../Models/salesdata.dart';
import '../Models/vansaleproduct.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import '../Components/commonwidgets.dart';

class HomeorderScreen extends StatefulWidget {
  static const routeName = "/HomeorderScreen";
  const HomeorderScreen({super.key});

  @override
  State<HomeorderScreen> createState() => _HomeorderScreenState();
}

class _HomeorderScreenState extends State<HomeorderScreen> {
  final TextEditingController _searchController = TextEditingController();
  VanSaleProducts products = VanSaleProducts();
  List<Data> filteredProducts = [];
  bool _initDone = false;
  bool _noData = false;
  List<int> selectedItems = [];
  List<Map<String, dynamic>> items = [];
  bool _isSearching = false;
  int? customerId;

  int? id;
  String? name;

  Qty.ProductQuantityDetails qunatityData = Qty.ProductQuantityDetails();
  List<Qty.ProductQuantityDetails> quantity = [];

  @override
  void initState() {
    super.initState();
    _getProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> fetchUpdatedStatus(int id) async {
    final url = Uri.parse('http://68.183.92.8:3699/api/vansales_order.status?id=$id');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final data = VanSalesOrderStatusResponse.fromJson(jsonResponse);
        if (data.data.isNotEmpty) {
          return data.data.first.status; // e.g., "Pending"
        }
      }
    } catch (e) {
      debugPrint("Error fetching status: $e");
    }
    return null;
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredProducts = products.data ?? [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      filteredProducts = (products.data ?? []).where((product) {
        final invoiceNo = product.invoiceNo?.toLowerCase() ?? '';
        final customerName = product.customer?.isNotEmpty == true
            ? product.customer![0].name?.toLowerCase() ?? ''
            : '';
        final customerCode = product.customer?.isNotEmpty == true
            ? product.customer![0].code?.toLowerCase() ?? ''
            : '';
        final date = product.inDate?.toLowerCase() ?? '';
        final total = product.total?.toString().toLowerCase() ?? '';

        return invoiceNo.contains(query.toLowerCase()) ||
            customerName.contains(query.toLowerCase()) ||
            customerCode.contains(query.toLowerCase()) ||
            date.contains(query.toLowerCase()) ||
            total.contains(query.toLowerCase());
      }).toList();
    });
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search by invoice, customer, date...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppConfig.backgroundColor.withOpacity(0.7)),
      ),
      style: TextStyle(color: AppConfig.backgroundColor, fontSize: 16),
      onChanged: _filterProducts,
    );
  }

  List<Widget> _buildActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: Icon(Icons.clear, color: AppConfig.backgroundColor),
          onPressed: () {
            setState(() {
              _searchController.clear();
              _isSearching = false;
              filteredProducts = products.data ?? [];
            });
          },
        ),
      ];
    } else {
      return [
        IconButton(
          icon: Icon(Icons.search, color: AppConfig.backgroundColor),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params =
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      id = params!['customerId'];
      name = params!['name'];
    }

    String getStatusText(int status, int convertToSales) {
      if (convertToSales == 1) {
        return "Invoiced";
      } else {
        switch (status) {
          case 0:
            return "Cancelled";
          case 1:
            return "Pending";
          default:
            return "Confirmed";
        }
      }
    }

    final displayProducts = _isSearching ? filteredProducts : products.data;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
        title: _isSearching ? _buildSearchField() : const Text(
          'Sales Order',
          style: TextStyle(color: AppConfig.backgroundColor),
        ),
        backgroundColor: AppConfig.colorPrimary,
        actions: _buildActions(),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              CommonWidgets.verticalSpace(1),
              (_initDone && !_noData)
                  ? SizedBox(
                  height: SizeConfig.blockSizeVertical * 85,
                  child: displayProducts != null && displayProducts.isNotEmpty
                      ? ListView.separated(
                    separatorBuilder: (BuildContext context, int index) =>
                        CommonWidgets.verticalSpace(1),
                    itemCount: displayProducts.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) =>
                        _productsCard(displayProducts[index], index),
                  )
                      : _isSearching
                      ? Center(child: Text('No results found'))
                      : Center(child: Text('No data available')))
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
        ),
      ),
    );
  }

  Widget _productsCard(Data data, int index) {
    return FutureBuilder<String?>(
        future: fetchUpdatedStatus(data.id!),
        builder: (context, snapshot) {
          String status = "Loading...";
          Color statusColor = Colors.grey;

          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              status = snapshot.data!;
              switch (status) {
                case "Pending":
                  statusColor = Colors.orange;
                  break;
                case "Cancelled":
                  statusColor = Colors.red;
                  break;
                case "Confirmed":
                  statusColor = Colors.green;
                  break;
                case "Invoiced":
                  statusColor = Colors.blue;
                  break;
                default:
                  statusColor = Colors.grey;
              }
            } else {
              status = "Unavailable";
              statusColor = Colors.black;
            }
          }
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${data.invoiceNo!} | ${DateFormat('dd MMMM yyyy').format(DateTime.parse(data.inDate!))} ${data.inTime}',
                                style: TextStyle(
                                  fontSize: AppConfig.textCaption3Size,
                                ),
                              ),
                              SizedBox(width: 40),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: AppConfig.textCaption3Size,
                                  fontWeight: AppConfig.headLineWeight,
                                  color: statusColor,
                                ),
                              ),
                            ],
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
                          // ),Text(' | '),
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
                      Text(
                        'Total: ${data.total}',
                        style: TextStyle(
                          fontSize: AppConfig.textCaption3Size,
                        ),
                      ),
                      Text(
                        'Discount(%): ${data.discount}',
                        style: TextStyle(
                          fontSize: AppConfig.textCaption3Size,
                        ),
                      ),
                      SizedBox(
                        width: SizeConfig.blockSizeHorizontal * 90,
                        child: Row(
                          children: [
                            Text(
                              'Round Off: ${(double.tryParse(data.roundOff ?? '0')?.toStringAsFixed(AppState().noOfDecimals ?? 2)) ?? ''}',
                              style: TextStyle(
                                fontSize: AppConfig.textCaption3Size,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                print(data.id);
                                print("Convert${data.convert_to_sale}");
                                print("status${data.status}");
                              },
                              child: const Icon(
                                Icons.print,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                            CommonWidgets.horizontalSpace(2),
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
                        'Total Vat: ${data.totalTax?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? ''}',
                        style: TextStyle(
                          fontSize: AppConfig.textCaption3Size,
                        ),
                      ),
                      Text(
                        'Grand Total: ${data.grandTotal}',
                        style: TextStyle(
                          fontSize: AppConfig.textCaption3Size,
                        ),
                      ),
                      data.deliverlocation != null && data.deliverlocation!.isNotEmpty
                          ? Text(
                        'Delivery Location: ${data.deliverlocation}',
                        style: TextStyle(
                          fontSize: AppConfig.textCaption3Size,
                        ),
                      )
                          : SizedBox.shrink(),

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
                                        'Amount: ${data.detail![i].amount?.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
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
    );
  }

  Future<void> _getProducts() async {
    RestDatasource api = RestDatasource();
    dynamic resJson = await api.getDetails(
        '/api/vansales_order.index?store_id=${AppState().storeId}&van_id=${AppState().vanId}&user_id=${AppState().userId}',
        AppState().token); //
    if (resJson['data'] != null) {
      products = VanSaleProducts.fromJson(resJson);
      filteredProducts = products.data ?? [];
      setState(() {
        _initDone = true;
      });
    } else {
      setState(() {
        _noData = true;
        _initDone = true;
      });
    }
  }

  Future<void> _createPdf(Invoice.InvoiceData invoice, bool isPrint) async {

    PdfDocument document = PdfDocument();
    final page = document.pages.add();
    final Size pageSize = page.getClientSize();

    final double pageWidth = pageSize.width;
    final Uint8List? imageData = await _readImageData(invoice.data!.store![0].logo);
    if (imageData != null && imageData.isNotEmpty) {
      final PdfBitmap image = PdfBitmap(imageData);
      // Position logo at top-right (adjust width/height as needed)
      page.graphics.drawImage(
        image,
        Rect.fromLTWH(
          pageWidth - 100, // Right-aligned with 100px width
          30,             // Top margin
          80,             // Logo width
          80,             // Logo height
        ),
      );
    }

    // Left-aligned company info
    final String companyName = '${invoice.data!.store![0].name}';
    final String rawAddress = invoice.data!.store![0].address ?? 'N/A';

// Draw company name (bold, left-aligned)
    page.graphics.drawString(
      companyName,
      PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(30, 30, pageWidth - 150, 30),
    );

// Draw each line of the address separately
    double currentY = 60; // Start below company name
    final PdfFont detailsFont = PdfStandardFont(PdfFontFamily.helvetica, 10);

// Split the address by newlines and draw each line
    for (final line in rawAddress.split('\n')) {
      if (line.trim().isNotEmpty) { // Skip empty lines
        page.graphics.drawString(
          line.trim(),
          detailsFont,
          bounds: Rect.fromLTWH(30, currentY, pageWidth - 150, 15),
        );
        currentY += 15; // Move down for next line
      }
    }

    final String? name = "SALES ORDER";
    final String text = '$name';

    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 15);

    // Calculate the width of the text
    final Size textSize = font.measureString(text);

    // Calculate the center position for the text
    final double xPosition = (pageWidth - textSize.width) / 2;
    final double yPosition =
    165; // Adjust this as needed for vertical positioning

    // Draw the centered text
    page.graphics.drawString(
      text,
      font,
      bounds:
      Rect.fromLTWH(xPosition, yPosition, textSize.width, textSize.height),
    );

    // Draw a line below the text
    final double lineYPosition =
        yPosition + textSize.height + 10; // Adjust the gap as needed
    page.graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0)), // Black pen
      Offset(0, lineYPosition),
      Offset(pageWidth, lineYPosition),
    );

    String address = '''
  Customer: ${invoice.data!.customer![0].code} | ${invoice.data!.customer![0].name}
  Email: ${invoice.data!.customer![0].email}
  Contact No:  ${invoice.data!.customer![0].contactNumber}
  TRN:  ${invoice.data!.customer![0].trn ?? ''}
  ''';

    String invoiceDetails = '''
  Order No: ${invoice.data!.invoiceNo!}
  Date: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(invoice.data!.inDate!))}
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
    grid.columns.add(count: 8);
    // Set column widths.
    grid.columns[0].width = 30; // Sl.No
    grid.columns[1].width = 180; // Product
    grid.columns[2].width = 60; // Unit
    grid.columns[3].width = 60; // Rate
    grid.columns[4].width = 40; // Qty
    grid.columns[5].width = 40; // Foc
    grid.columns[6].width = 50; // Vat
    grid.columns[7].width = 60;

    // Add headers.
    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'Sl.No';
    headerRow.cells[1].value = 'Product';
    headerRow.cells[2].value = 'Unit';
    headerRow.cells[3].value = 'Rate';
    headerRow.cells[4].value = 'Qty';
    headerRow.cells[5].value = 'Foc';
    headerRow.cells[6].value = 'Vat';
    headerRow.cells[7].value = 'Amount';

    for (int k = 0; k < invoice.data!.detail!.length; k++) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = '${k + 1}';
      row.cells[1].value = '${invoice.data!.detail![k].name}';
      row.cells[2].value = '${invoice.data!.detail![k].unit}';
      row.cells[3].value = '${invoice.data!.detail![k].mrp}';
      row.cells[4].value = '${invoice.data!.detail![k].quantity}';
      row.cells[5].value =
      (invoice.data!.detail![k].productType!.toLowerCase() == "foc")
          ? '1'
          : '0';
      row.cells[6].value = '${invoice.data!.detail![k].taxAmt!.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
      row.cells[7].value = '${invoice.data!.detail![k].amount!.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
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
    String bottomInvoiceDetails = '''
  ${num.parse(invoice.data!.roundOff.toString()) != 0 ? 'Discount: ${invoice.data!.discount}' : '\t'}
  Total: ${invoice.data!.total}
  Vat: ${invoice.data!.totalTax!.toStringAsFixed(AppState().noOfDecimals ?? 2)}
${invoice.data?.roundOff != null && double.tryParse(invoice.data!.roundOff.toString()) != 0
        ? 'Round off: ${double.tryParse(invoice.data!.roundOff.toString())?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00'}\nGrand Total: ${invoice.data!.grandTotal!.toStringAsFixed(AppState().noOfDecimals ?? 2)}'
        : 'Grand Total: ${invoice.data!.grandTotal!.toStringAsFixed(AppState().noOfDecimals ?? 2)}'}


  ''';

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

// in word
    String textData =
        'Amount in Words: AED ${NumberToWord().convert('en-in', invoice.data!.grandTotal!.toInt()).toUpperCase()} ONLY';

// Adjust the vertical position for the van details
    double vanDetailsTop = tableBottom + 20 + 100 + 10;

// Construct the van details string.
    String bottomVanDetails = '''
Van: ${invoice.data!.van![0].name}
Salesman: ${invoice.data!.user![0].name}
''';

// Draw the word text above the van details
    lastPage.graphics.drawString(
      textData,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(
        0,
        vanDetailsTop -
            30, // Adjust vertical position to be above the van details
        pageSize.width,
        100,
      ),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
      ),
    );
// Draw van details at the bottom left.
    lastPage.graphics.drawString(
      bottomVanDetails,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(
        0,
        vanDetailsTop,
        pageSize.width / 2,
        100,
      ),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.left,
      ),
    );
    List<int> bytes = await document.save();
    document.dispose();

    String file = await saveAndLaunchFile(
        bytes, '${invoice.data!.invoiceNo!}.pdf', isPrint);
  }

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
    Invoice.InvoiceData invoice = Invoice.InvoiceData();
    RestDatasource api = RestDatasource();
    dynamic response = await api.getDetails(
        '/api/get_sales_order_invoice?id=$id', AppState().token);
    print("ssdsdsdssds${id}");
    if (response['data'] != null) {
      invoice = Invoice.InvoiceData.fromJson(response);
      _createPdf(invoice, isPrint);
    }
  }
}

class VanSalesOrderStatusResponse {
  final List<VanSalesOrderStatusData> data;
  final bool success;
  final List<String> messages;

  VanSalesOrderStatusResponse({
    required this.data,
    required this.success,
    required this.messages,
  });

  factory VanSalesOrderStatusResponse.fromJson(Map<String, dynamic> json) {
    return VanSalesOrderStatusResponse(
      data: List<VanSalesOrderStatusData>.from(
          json['data'].map((x) => VanSalesOrderStatusData.fromJson(x))),
      success: json['success'],
      messages: List<String>.from(json['messages']),
    );
  }
}

class VanSalesOrderStatusData {
  final String invoiceNo;
  final int id;
  final String status;

  VanSalesOrderStatusData({
    required this.invoiceNo,
    required this.id,
    required this.status,
  });

  factory VanSalesOrderStatusData.fromJson(Map<String, dynamic> json) {
    return VanSalesOrderStatusData(
      invoiceNo: json['invoice_no'],
      id: json['id'],
      status: json['status'],
    );
  }
}