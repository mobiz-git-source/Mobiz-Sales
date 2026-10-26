import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Utilities/cpcl_helper.dart';
import '../Utilities/report_printer.dart';
import '../Reports/sales_order_report.dart';

import '../Models/invoicedata.dart' as Invoice;
import '../Models/pdfgenerate.dart';
import '../Models/productquantirydetails.dart' as Qty;
import '../Models/salesdata.dart';
import '../Models/vansaleproduct.dart';
import '../Utilities/rest_ds.dart';
import '../Utilities/date_helper.dart';
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

  BluetoothDevice? _selectedDevice;
  List<BluetoothDevice> _devices = [];
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  bool _connected = false;

 @override
void initState() {
  super.initState();
  AppState().loadTaxName().then((_) {
    if (mounted) setState(() {});
  });
  _initPrinter();
}

bool _listInit = false;
String _listType = 'sales'; // 'sales' | 'proforma' | 'merchandise'

List<Map<String, dynamic>> merchList = [];
List<Map<String, dynamic>> filteredMerch = [];
bool get _isMerch => _listType == 'merchandise';

String get _listPath => _listType == 'proforma'
    ? '/api/proforma_order.index'
    : _isMerch
        ? '/api/merchandise.index'
        : '/api/vansales_order.index';

String get _statusPath => _listType == 'proforma'
    ? '/api/proforma_order.status'
    : _isMerch
        ? '/api/merchandise.status'
        : '/api/vansales_order.status';

String get _screenTitle => _listType == 'proforma'
    ? 'Proforma Orders'
    : _isMerch
        ? 'Merchandise Orders'
        : 'Sales Order';

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (_listInit) return;
  _listInit = true;
  final args = ModalRoute.of(context)?.settings.arguments;
  if (args is Map && args['listType'] != null) {
    _listType = args['listType'].toString();
  }
  _getProducts();
}

  void _initPrinter() async {
    await loadPrinterTypeCache();
    bool? isConnected = await printer.isConnected;
    if (isConnected == true && mounted) {
      setState(() => _connected = true);
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
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _selectedDevice = defaultDevice;
    });
  }

  Future<void> _connect() async {
    if (_selectedDevice != null) {
      await printer.connect(_selectedDevice!);
      if (!mounted) return;
      setState(() => _connected = true);
    }
  }

  Future<void> _print(Invoice.InvoiceData invoice) async {
    await AppState().loadTaxName();

    final bool? live = await printer.isConnected;
    if (live != true) {
      _connected = false;
      await _connect();
    }
    if (!_connected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer not connected')),
        );
      }
      return;
    }

      try {
      if (isZebraPrinter(_selectedDevice)) {
        // ZEBRA: image print (Arabic support)
        final logoFile = invoice.data?.store?.firstOrNull?.logo;
        final logo = (logoFile != null && logoFile.isNotEmpty)
            ? await loadLogo('$kOrderLogoBaseUrl$logoFile')
            : null;

        await printReport(
          printer,
          _selectedDevice,
          (b) => drawSalesOrder(b, invoice, logo: logo),
        );
      } else {
        // SEWOO: pazhaya text print, invoice pole
        await _printSewoo(invoice);
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

  Future<void> _getInvoicePrint(int id) async {
    try {
      if (_selectedDevice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default device not found')),
        );
        return;
      }
      RestDatasource api = RestDatasource();
    dynamic response = await api.getDetails(
    '/api/get_sales_order_invoice?id=$id${_listType == 'proforma' ? '&type=proforma' : ''}',
    AppState().token);
         debugPrint('PRINT RESPONSE (id=$id, type=$_listType): $response');
      if (response['data'] != null) {
        final invoice = Invoice.InvoiceData.fromJson(response);
        await _print(invoice);
      }
    } catch (e, st) {
      print('Error printing order: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error printing order: $e')),
        );
      }
    }
  }
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

    final double rawWidth = textPainter.width.ceilToDouble();
    final double width = (rawWidth / 8).ceil() * 8;
    final double height = textPainter.height.ceilToDouble();

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );
    textPainter.paint(canvas, Offset.zero);

    final ui.Image image =
        await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
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

  String _amountInWords(num amount) {
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

  Future<void> _printSewoo(Invoice.InvoiceData invoice) async {
       final d = invoice.data!;
    if (d.store == null || d.store!.isEmpty) {
      throw Exception('Server returned no store details for this order');
    }
    if (d.customer == null || d.customer!.isEmpty) {
      throw Exception('Server returned no customer details for this order');
    }
    final store = d.store![0];
    final cust = d.customer![0];
    final decimals = AppState().noOfDecimals ?? 2;

    String companyName = store.invoice_company_name ?? store.name ?? 'N/A';
    String companyNameAr = store.name_ar ?? '';
    String companyAddress = store.address ?? 'N/A';
    String companyMail = store.email ?? 'N/A';
    String companyTRN = "TRN: ${store.trn ?? 'N/A'}";

    String customerName = "${cust.name}";
    List<String> nameWords = customerName.split(' ');
    String firstLine = customerName;
    String secondLine = "";
    if (nameWords.length > 7) {
      firstLine = nameWords.sublist(0, 7).join(' ');
      secondLine = nameWords.sublist(7).join(' ');
    }
    String cusAddress = cust.address?.toString() ?? '';
    String customerContact = cust.contactNumber ?? 'N/A';
    String customerTRN = cust.trn ?? '';

    final orderNumber = d.invoiceNo ?? 'N/A';
    final orderDate = DateHelper.displayDate(d.inDate);
    final remarks = d.remarks;

    final amountInWords = _amountInWords(d.grandTotal ?? 0);
    String van = d.van?.firstOrNull?.name ?? 'N/A';
    String salesman = d.user?.firstOrNull?.name ?? 'N/A';

    void printAlignedText(String leftText, String rightText) {
      const int maxLineLength = 68;
      int spaceLength = maxLineLength - (leftText.length + rightText.length);
      String spaces = ' ' * (spaceLength > 0 ? spaceLength : 1);
      printer.printCustom('$leftText$spaces$rightText', 1, 0);
    }

    // Logo
    String logoUrl = '$kOrderLogoBaseUrl${store.logo}';
    if (store.logo != null && store.logo!.isNotEmpty) {
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

    // Company details
    printer.printNewLine();
    printer.printCustom(companyName, 3, 1);
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
    printer.printCustom(companyAddress, 1, 1);
    printer.printCustom(companyMail, 1, 1);
    printer.printCustom(companyTRN, 1, 1);
    printer.printNewLine();

       printer.printCustom(_listType == 'proforma' ? "PROFORMA ORDER" : "SALES ORDER", 2, 1);
    printer.printNewLine();

    printer.printCustom("-" * 72, 1, 1);
    printAlignedText("Order No: $orderNumber", "Date: $orderDate");
    printAlignedText("", "Time: ${d.inTime ?? ''}");
    if (remarks != null && remarks.toString().isNotEmpty) {
      printAlignedText("Remarks: $remarks", "");
    }
    printer.printNewLine();

    // Customer
    printAlignedText("Customer: $firstLine", "");
    if (secondLine.isNotEmpty) {
      printAlignedText("         $secondLine", "");
    }
    if (cusAddress.isNotEmpty && cusAddress != 'null') {
      printAlignedText(cusAddress, " ");
    }
    printAlignedText("Contact No: $customerContact", "");
    printAlignedText("${store.vat_label ?? 'TRN'}: $customerTRN", " ");
    printer.printNewLine();

    printer.printCustom("-" * 70, 1, 1);

    const int columnWidth1 = 3; // #
    const int columnWidth2 = 19; // Product
    const int columnWidth3 = 4; // Unit
    const int columnWidth4 = 5; // Qty
    const int columnWidth6 = 9; // Rate
    const int columnWidth7 = 9; // Amount
    const int columnWidth8 = 8; // Tax
    const int columnWidth9 = 9; // Total

    String headers = "${'#'.padRight(columnWidth1)}"
        "${'Product'.padRight(columnWidth2)} "
        "${'Unit'.padRight(columnWidth3)}"
        "${'Qty'.padLeft(columnWidth4)}"
        "${'Rate'.padLeft(columnWidth6)}"
        "${'Amount'.padLeft(columnWidth7)}"
        "${AppState().taxLabel.padLeft(columnWidth8)}"
        "${'Total'.padLeft(columnWidth9)}";
    printer.printCustom(headers, 1, 0);

    for (int i = 0; i < d.detail!.length; i++) {
      final it = d.detail![i];
      String productDescription = it.name ?? 'N/A';
      String productUnit = '${it.unit ?? 'N/A'}';
      String productQty = it.quantity?.toString() ?? '0';
      String productRate = it.mrp?.toStringAsFixed(decimals) ?? '0.00';
      String productTotal = it.taxable?.toStringAsFixed(decimals) ?? '0.00';
      String productTax = it.taxAmt?.toStringAsFixed(decimals) ?? '0.00';
      String productAmount = it.amount?.toStringAsFixed(decimals) ?? '0.00';

      List<String> descriptionLines =
          _wrapWords(productDescription, columnWidth2);

      for (int j = 0; j < descriptionLines.length; j++) {
        String line;
        if (j == 0) {
          line = "${(i + 1).toString().padRight(columnWidth1)}"
              "${descriptionLines[j].padRight(columnWidth2)} "
              "${productUnit.padRight(columnWidth3)}"
              "${productQty.padLeft(columnWidth4)}"
              "${productRate.padLeft(columnWidth6)}"
              "${productTotal.padLeft(columnWidth7)}"
              "${productTax.padLeft(columnWidth8)}"
              "${productAmount.padLeft(columnWidth9)}";
        } else {
          line = "${''.padRight(columnWidth1)}"
              "${descriptionLines[j].padRight(columnWidth2)}";
        }
        printer.printCustom(line, 1, 0);
      }
    }
    printer.printCustom("-" * 70, 1, 1);

    // Totals
    final total = (d.total ?? 0).toDouble();
    final double discount = d.effectiveDiscount.toDouble();
    final subTotal = total - discount;
    final tax = (d.totalTax ?? 0).toStringAsFixed(decimals);
    final grandTotal = (d.grandTotal ?? 0).toStringAsFixed(decimals);

    printAlignedText(
        "Van      : $van", "Total: ${total.toStringAsFixed(decimals)}");
    if (discount > 0) {
          printAlignedText("Salesman : $salesman",
          "${d.discountLabel}: ${discount.toStringAsFixed(decimals)}");
    } else {
      printAlignedText("Salesman : $salesman", "");
    }
    printAlignedText(
        "", "Sub Total: ${subTotal.toStringAsFixed(decimals)}");
    printAlignedText("", "${AppState().taxLabel}: $tax");
    printAlignedText("", "Grand Total: $grandTotal");
    printer.printNewLine();
    printer.printCustom(amountInWords, 1, 0);

    printer.paperCut();
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> fetchUpdatedStatus(int id) async {
 final url = Uri.parse('http://68.183.92.8:3699$_statusPath?id=$id');
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
    if (_isMerch) {
      final q = query.toLowerCase();
      setState(() {
        _isSearching = query.isNotEmpty;
        filteredMerch = q.isEmpty
            ? merchList
            : merchList.where((m) {
                final c = (m['customer']?['name'] ?? '').toString().toLowerCase();
                         return (m['invoice_no'] ?? '').toString().toLowerCase().contains(q) ||
                    c.contains(q) ||
                    (m['in_date'] ?? '').toString().contains(q);
              }).toList();
      });
      return;
    }

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
              filteredMerch = merchList;
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
  final routeArgs = ModalRoute.of(context)?.settings.arguments;
if (routeArgs is Map) {
  id = routeArgs['customerId'] as int?;
  name = routeArgs['name']?.toString();
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
      title: _isSearching ? _buildSearchField() : Text(
  _screenTitle,
  style: AppConfig.pageTitleStyle,
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
               child: (_isMerch
        ? (_isSearching ? filteredMerch : merchList).isNotEmpty
        : displayProducts != null && displayProducts.isNotEmpty)
    ? ListView.separated(
  separatorBuilder: (BuildContext context, int index) =>
      CommonWidgets.verticalSpace(1),
  itemCount: _isMerch
      ? (_isSearching ? filteredMerch : merchList).length
      : displayProducts!.length,
  shrinkWrap: true,
  itemBuilder: (context, index) => _isMerch
      ? _merchCard((_isSearching ? filteredMerch : merchList)[index])
      : _productsCard(displayProducts![index], index),
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
String _discountText(Data data) {
  final String type = (data.discount_type ?? '').trim().toLowerCase();
  final bool isPercentage = type == '1' || type == 'percentage';
  final num pct = data.discount ?? 0;
  num amount = data.discount_amount ?? 0;

  if (amount == 0 && pct > 0) {
    amount = isPercentage ? (data.total ?? 0) * pct / 100 : pct;
  }

  String label = 'Discount';
  if (isPercentage && pct > 0) {
    final s = pct.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    label = 'Discount ($s%)';
  }
  return '$label: ${amount.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
}Widget _merchCard(Map<String, dynamic> m) {
  final int id = m['id'];
  final cust = (m['customer'] ?? {}) as Map;
   final details = (m['detail'] as List?) ?? [];

  return FutureBuilder<String?>(
    future: fetchUpdatedStatus(id),
    builder: (context, snap) {
      String status = 'Loading...';
      Color sc = Colors.grey;
      if (snap.connectionState == ConnectionState.done) {
        status = snap.data ?? 'Unavailable';
        sc = status == 'Pending' ? Colors.orange
           : status == 'Cancelled' ? Colors.red
           : status == 'Confirmed' ? Colors.green
           : status == 'Invoiced' ? Colors.blue : Colors.grey;
      }
      final fs = TextStyle(fontSize: AppConfig.textCaption3Size);
      return Card(
        elevation: 1,
        child: ExpansionTile(
          trailing: const SizedBox.shrink(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    '${m['invoice_no']} | ${DateHelper.displayDate(m['in_date'])} ${m['in_time'] ?? ''}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: fs),
                ),
                Text(status, style: TextStyle(
                    fontSize: AppConfig.textCaption3Size,
                    fontWeight: AppConfig.headLineWeight, color: sc)),
              ]),
                     Text('${cust['name'] ?? ''}', style: TextStyle(
                  fontSize: AppConfig.textCaption3Size,
                  fontWeight: AppConfig.headLineWeight)),
              Row(children: [
                const Spacer(),
                InkWell(
                  onTap: () => _printMerch(id),
                  child: const Icon(Icons.print, color: Colors.blue, size: 30)),
                CommonWidgets.horizontalSpace(2),
                InkWell(
                  onTap: () => _pdfMerch(id),
                  child: const Icon(Icons.document_scanner, color: Colors.red, size: 30)),
              ]),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final d in details) ...[
                 Text(
  (((d['product_code'] ?? '').toString().isNotEmpty
          ? '${d['product_code']} | '
          : '') +
      '${d['product_name'] ?? ''}')
      .toUpperCase(),
                        style: TextStyle(fontSize: AppConfig.textCaption3Size,
                            fontWeight: AppConfig.headLineWeight)),
                    Text('${d['product_type_name'] ?? ''} | ${d['unit_name'] ?? ''} | Qty: ${d['quantity']}',
                        style: fs),
                    if ((d['description'] ?? '').toString().isNotEmpty)
                      Text('Description: ${d['description']}', style: fs),
                    const Divider(),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
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
  child: Row(
    children: [
      Expanded(
        child: Text(
          '${data.invoiceNo!} | ${DateHelper.displayDate(data.inDate)} ${data.inTime}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: AppConfig.textCaption3Size,
          ),
        ),
      ),
      const SizedBox(width: 8),
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
                              'Round Off: ${(double.tryParse(data.roundOff ?? '0')?.toStringAsFixed(AppState().noOfDecimals ?? 2)) ?? ''}',
                              style: TextStyle(
                                fontSize: AppConfig.textCaption3Size,
                              ),
                            ),
                            const Spacer(),
                                                       InkWell(
                              onTap: () => _getInvoicePrint(data.id!),
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
                      '${AppState().taxLabel}: ${data.totalTax?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? ''}',
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
    '$_listPath?store_id=${AppState().storeId}&van_id=${AppState().vanId}&user_id=${AppState().userId}',
    AppState().token);
debugPrint('LIST RESPONSE ($_listType): $resJson');
if (resJson['data'] != null) {
  if (_isMerch) {
    merchList = (resJson['data'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    filteredMerch = merchList;
  } else {
    products = VanSaleProducts.fromJson(resJson);
    filteredProducts = products.data ?? [];
  }
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
  final Uint8List? imageData =
    await _readImageData(invoice.data!.store?.firstOrNull?.logo);
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
 final String companyName = '${invoice.data!.store?.firstOrNull?.name ?? ''}';
final String rawAddress = invoice.data!.store?.firstOrNull?.address ?? 'N/A';

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

        final String? name = _listType == 'proforma' ? "PROFORMA ORDER" : "SALES ORDER";
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
final custList = invoice.data!.customer;
if (custList == null || custList.isEmpty) {
  throw Exception('Server returned no customer details for this order');
}
final cust = custList[0];
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
  Order No: ${invoice.data!.invoiceNo!}
  Date: ${DateHelper.displayDate(invoice.data!.inDate)}
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
    headerRow.cells[6].value = AppState().taxLabel;
    headerRow.cells[7].value = 'Amount';

    for (int k = 0; k < invoice.data!.detail!.length; k++) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = '${k + 1}';
      row.cells[1].value = '${invoice.data!.detail![k].name}';
      row.cells[2].value = '${invoice.data!.detail![k].unit}';
      row.cells[3].value = '${invoice.data!.detail![k].mrp}';
      row.cells[4].value = '${invoice.data!.detail![k].quantity}';
       row.cells[5].value =
      ((invoice.data!.detail![k].productType ?? '').toLowerCase() == "foc")
          ? '1'
          : '0';
      row.cells[6].value = (invoice.data!.detail![k].taxAmt ?? 0)
          .toStringAsFixed(AppState().noOfDecimals ?? 2);
      row.cells[7].value = (invoice.data!.detail![k].amount ?? 0)
          .toStringAsFixed(AppState().noOfDecimals ?? 2);
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
  ${invoice.data!.effectiveDiscount > 0 ? '${invoice.data!.discountLabel}: ${invoice.data!.effectiveDiscount.toStringAsFixed(AppState().noOfDecimals ?? 2)}' : '\t'}
  Total: ${invoice.data!.total}
   ${AppState().taxLabel}: ${(invoice.data!.totalTax ?? 0).toStringAsFixed(AppState().noOfDecimals ?? 2)}
${invoice.data?.roundOff != null && double.tryParse(invoice.data!.roundOff.toString()) != 0
        ? 'Round off: ${double.tryParse(invoice.data!.roundOff.toString())?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00'}\nGrand Total: ${(invoice.data!.grandTotal ?? 0).toStringAsFixed(AppState().noOfDecimals ?? 2)}'
        : 'Grand Total: ${(invoice.data!.grandTotal ?? 0).toStringAsFixed(AppState().noOfDecimals ?? 2)}'}


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
      String textData = _amountInWords(invoice.data!.grandTotal ?? 0);

// Adjust the vertical position for the van details
    double vanDetailsTop = tableBottom + 20 + 100 + 10;

// Construct the van details string.
    String bottomVanDetails = '''
Van: ${invoice.data!.van?.firstOrNull?.name ?? ''}
Salesman: ${invoice.data!.user?.firstOrNull?.name ?? ''}
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
    if (_isMerch) return _pdfMerch(id);
    try {
      RestDatasource api = RestDatasource();
      dynamic response = await api.getDetails(
          '/api/get_sales_order_invoice?id=$id', AppState().token);
      debugPrint('PDF RESPONSE (id=$id, type=$_listType): $response');

      if (response['data'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data returned for this order')),
          );
        }
        return;
      }
      final invoice = Invoice.InvoiceData.fromJson(response);
      await _createPdf(invoice, isPrint);
    } catch (e, st) {
      debugPrint('PDF error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF failed: $e')),
        );
      }
    }
  }
  Future<Map<String, dynamic>?> _fetchMerchPrint(int id) async {
  final res = await RestDatasource()
      .getDetails('/api/get_merchandise_print?id=$id', AppState().token);
  if (res['data'] != null) return Map<String, dynamic>.from(res['data']);
  return null;
}

Future<void> _printMerch(int id) async {
  try {
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default device not found')));
      return;
    }
    final bool? live = await printer.isConnected;
    if (live != true) await _connect();
    if (!_connected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Printer not connected')));
      }
      return;
    }
    if (isZebraPrinter(_selectedDevice)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Zebra print for Merchandise not added yet')));
      }
      return;
    }
    final d = await _fetchMerchPrint(id);
    if (d == null) return;
    final store = (d['store'] ?? {}) as Map;
    final cust = (d['customer'] ?? {}) as Map;
    final details = (d['detail'] as List?) ?? [];

    void line(String l, [String r = '']) {
      final sp = 68 - (l.length + r.length);
      printer.printCustom('$l${' ' * (sp > 0 ? sp : 1)}$r', 1, 0);
    }

    printer.printNewLine();
    printer.printCustom('${store['invoice_company_name'] ?? store['name'] ?? ''}', 3, 1);
    printer.printCustom('${store['address'] ?? ''}', 1, 1);
    printer.printCustom('${store['email'] ?? ''}', 1, 1);
    printer.printCustom('TRN: ${store['trn'] ?? ''}', 1, 1);
    printer.printNewLine();
    printer.printCustom('MERCHANDISE ORDER', 2, 1);
    printer.printNewLine();
    printer.printCustom('-' * 70, 1, 1);
    line('Order No: ${d['invoice_no'] ?? ''}',
        'Date: ${DateHelper.displayDate(d['in_date'])}');
    line('', 'Time: ${d['in_time'] ?? ''}');
    printer.printNewLine();
    line('Customer: ${cust['name'] ?? ''}');
    if ((cust['contact_number'] ?? '').toString().isNotEmpty) {
      line('Contact No: ${cust['contact_number']}');
    }
    printer.printCustom('-' * 70, 1, 1);
    printer.printCustom(
        '${'#'.padRight(3)}${'Product'.padRight(34)} ${'Unit'.padRight(8)}${'Qty'.padLeft(8)}', 1, 0);
    for (int i = 0; i < details.length; i++) {
      final it = details[i];
      final lines = _wrapWords('${it['product_name'] ?? ''}', 34);
      for (int j = 0; j < lines.length; j++) {
        printer.printCustom(
            j == 0
                ? '${(i + 1).toString().padRight(3)}${lines[j].padRight(34)} ${'${it['unit_name'] ?? ''}'.padRight(8)}${'${it['quantity']}'.padLeft(8)}'
                : '${''.padRight(3)}${lines[j]}',
            1, 0);
      }
    }
    printer.printCustom('-' * 70, 1, 1);
    line('Van      : ${(d['van'] ?? {})['name'] ?? ''}');
    line('Salesman : ${(d['user'] ?? {})['name'] ?? ''}');
    printer.paperCut();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Print failed: $e')));
    }
  }
}

Future<void> _pdfMerch(int id) async {
  final d = await _fetchMerchPrint(id);
  if (d == null) return;
  final store = (d['store'] ?? {}) as Map;
  final cust = (d['customer'] ?? {}) as Map;
  final details = (d['detail'] as List?) ?? [];

  final document = PdfDocument();
  final page = document.pages.add();
  final Size ps = page.getClientSize();

  final img = await _readImageData(store['logo']?.toString());
  if (img.isNotEmpty) {
    page.graphics.drawImage(PdfBitmap(img),
        Rect.fromLTWH(ps.width - 100, 30, 80, 80));
  }
  page.graphics.drawString('${store['name'] ?? ''}',
      PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(30, 30, ps.width - 150, 30));
  page.graphics.drawString('${store['address'] ?? ''}',
      PdfStandardFont(PdfFontFamily.helvetica, 10),
      bounds: Rect.fromLTWH(30, 60, ps.width - 150, 40));

  final f15 = PdfStandardFont(PdfFontFamily.helvetica, 15);
  const title = 'MERCHANDISE ORDER';
  final tw = f15.measureString(title);
  page.graphics.drawString(title, f15,
      bounds: Rect.fromLTWH((ps.width - tw.width) / 2, 165, tw.width, tw.height));
  page.graphics.drawLine(PdfPen(PdfColor(0, 0, 0)),
      Offset(0, 195), Offset(ps.width, 195));

   final left = [
    'Customer: ${cust['code'] ?? ''} | ${cust['name'] ?? ''}',
    if ((cust['contact_number'] ?? '').toString().isNotEmpty)
      'Contact No: ${cust['contact_number']}',
  ].join('\n');
  final right = [
    'Order No: ${d['invoice_no'] ?? ''}',
    'Date: ${DateHelper.displayDate(d['in_date'])}',
  ].join('\n');
  final f12 = PdfStandardFont(PdfFontFamily.helvetica, 12);
  page.graphics.drawString(left, f12,
      bounds: Rect.fromLTWH(0, 205, ps.width / 2, 80));
  page.graphics.drawString(right, f12,
      bounds: Rect.fromLTWH(ps.width / 2, 205, ps.width / 2, 80),
      format: PdfStringFormat(alignment: PdfTextAlignment.right));

  final grid = PdfGrid();
  grid.columns.add(count: 5);
  grid.columns[0].width = 30;
  grid.columns[1].width = 240;
  grid.columns[2].width = 80;
  grid.columns[3].width = 70;
  grid.columns[4].width = 60;
  final h = grid.headers.add(1)[0];
  h.cells[0].value = 'Sl.No';
  h.cells[1].value = 'Product';
  h.cells[2].value = 'Type';
  h.cells[3].value = 'Unit';
  h.cells[4].value = 'Qty';
  for (int k = 0; k < details.length; k++) {
    final it = details[k];
    final r = grid.rows.add();
    r.cells[0].value = '${k + 1}';
    r.cells[1].value = '${it['product_name'] ?? ''}';
    r.cells[2].value = '${it['product_type_name'] ?? ''}';
    r.cells[3].value = '${it['unit_name'] ?? ''}';
    r.cells[4].value = '${it['quantity']}';
  }
  final res = grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 300, ps.width, ps.height - 380))!;

  final last = res.page;
  final bottom = res.bounds.bottom;
  last.graphics.drawString(
      'Van: ${(d['van'] ?? {})['name'] ?? ''}\nSalesman: ${(d['user'] ?? {})['name'] ?? ''}',
      f12,
      bounds: Rect.fromLTWH(0, bottom + 20, ps.width / 2, 60));

  final bytes = await document.save();
  document.dispose();
  await saveAndLaunchFile(bytes, '${d['invoice_no']}.pdf', false);
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