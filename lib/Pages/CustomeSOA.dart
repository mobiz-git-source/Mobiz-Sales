import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Reports/soa_report.dart';
import 'package:mobizapp/Utilities/cpcl_helper.dart';
import 'package:mobizapp/Utilities/report_printer.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../Components/commonwidgets.dart';
import '../Models/Soa_model.dart';
import '../Models/Store_model.dart';
import '../Utilities/rest_ds.dart';
import '../Utilities/date_helper.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';

class SOA extends StatefulWidget {
  static const routeName = "/SOA";

  const SOA({Key? key}) : super(key: key);

  @override
  State<SOA> createState() => _SOAState();
}

int? id;
String? name;
String? address;
String? code;
String? payment;

class _SOAState extends State<SOA> {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  BlueThermalPrinter printer = BlueThermalPrinter.instance;

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

  void sortDataByDate(List<List<dynamic>> data) {
    data.sort((a, b) {
      DateTime dateA = DateTime.parse(a[0]);
      DateTime dateB = DateTime.parse(b[0]);
      return dateA.compareTo(dateB);
    });
  }

  Future<void> _generateAndPrintPdf(
      List data, double opening, double closing) async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load store details');
    }

    StoreDetail storeDetail = StoreDetail.fromJson(json.decode(response.body));
    final pdf = pw.Document();

    final String api =
        '${RestDatasource().Image_URL}/uploads/store/${storeDetail.logos}';
    final logoResponse = await http.get(Uri.parse(api));
    if (logoResponse.statusCode != 200) {
      throw Exception('Failed to load logo image');
    }
    final Uint8List logoBytes = logoResponse.bodyBytes;
    final int decimals = AppState().noOfDecimals ?? 2;

    final textStyle = const pw.TextStyle(fontSize: 10);
    final boldStyle =
        pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);

    pw.Widget buildCell(String text,
        {pw.Alignment alignment = pw.Alignment.centerLeft,
        bool isBold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(3),
        child: pw.Container(
          alignment: alignment,
          child: pw.Text(
            text,
            style: isBold ? boldStyle : textStyle,
            textAlign: alignment == pw.Alignment.centerRight
                ? pw.TextAlign.right
                : pw.TextAlign.left,
          ),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (pw.Context context) {
          if (context.pageNumber != 1) return pw.Container();
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        storeDetail.name,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (storeDetail.address != null)
                        pw.Text(storeDetail.address!,
                            style: const pw.TextStyle(fontSize: 10)),
                      if (storeDetail.trn != null)
                        pw.Text('TRN: ${storeDetail.trn}',
                            style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.Image(
                    pw.MemoryImage(logoBytes),
                    height: 50,
                    width: 100,
                    fit: pw.BoxFit.contain,
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Statement of Accounts',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Customer: $name', style: boldStyle),
                      if (address != null)
                        pw.SizedBox(
                          width: 250,
                          child: pw.Text('Address: $address', style: textStyle),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'From Date: ${_selectedDatefrom != null ? DateHelper.displayFromDateTime(_selectedDatefrom!) : '-'}',
                        style: textStyle,
                      ),
                      pw.Text(
                        'To Date: ${_selectedDateto != null ? DateHelper.displayFromDateTime(_selectedDateto!) : '-'}',
                        style: textStyle,
                      ),
                      if (storeDetail.currency != null)
                        pw.Text('Currency: ${storeDetail.currency}',
                            style: textStyle),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (pw.Context context) => [
          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
            columnWidths: const {
              0: pw.FixedColumnWidth(80), // Date
              1: pw.FixedColumnWidth(150), // Reference
              2: pw.FixedColumnWidth(90), // Debit
              3: pw.FixedColumnWidth(90), // Credit
              4: pw.FixedColumnWidth(100), // Balance
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  buildCell('Date',
                      alignment: pw.Alignment.center, isBold: true),
                  buildCell('Reference', isBold: true),
                  buildCell('Debit',
                      alignment: pw.Alignment.centerRight, isBold: true),
                  buildCell('Credit',
                      alignment: pw.Alignment.centerRight, isBold: true),
                  buildCell('Balance',
                      alignment: pw.Alignment.centerRight, isBold: true),
                ],
              ),
              // Opening Balance Row
              pw.TableRow(
                children: [
                  buildCell(''),
                  buildCell(''),
                  buildCell(''),
                  buildCell('Opening Balance',
                      alignment: pw.Alignment.centerRight, isBold: true),
                  buildCell(opening.toStringAsFixed(decimals),
                      alignment: pw.Alignment.centerRight, isBold: true),
                ],
              ),
              // Transaction Data Rows
              ...data.map((row) {
                final String dateStr =
                    DateHelper.displayDate(row[0]?.toString());
                final String refStr = row[1]?.toString() ?? '';
                final double Debit = row[2] != null
                    ? double.parse(row[2].toString()).abs()
                    : 0.0;
                final double Credit = row[3] != null
                    ? double.parse(row[3].toString()).abs()
                    : 0.0;
                final double balance =
                    row[4] != null ? double.parse(row[4].toString()) : 0.0;

                return pw.TableRow(
                  children: [
                    buildCell(dateStr),
                    buildCell(refStr),
                    buildCell(Debit.toStringAsFixed(decimals),
                        alignment: pw.Alignment.centerRight),
                    buildCell(Credit.toStringAsFixed(decimals),
                        alignment: pw.Alignment.centerRight),
                    buildCell(balance.toStringAsFixed(decimals),
                        alignment: pw.Alignment.centerRight),
                  ],
                );
              }).toList(),
              // Closing Balance Row
              pw.TableRow(
                children: [
                  buildCell(''),
                  buildCell(''),
                  buildCell(''),
                  buildCell('Closing Balance',
                      alignment: pw.Alignment.centerRight, isBold: true),
                  buildCell(closing.toStringAsFixed(decimals),
                      alignment: pw.Alignment.centerRight, isBold: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Custom SOA.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  // void _printSOA(
  //   StoreDetail store,
  //   List<List<dynamic>> data,
  //   double opening,
  //   double closing,
  // ) async {
  //   if (!_connected) {
  //     await _connect();
  //   }

  //   // 1. Print LOGO
  //   final logoUrl =
  //       '${RestDatasource().Image_URL}/uploads/store/${store.logos}';
  //   final response = await http.get(Uri.parse(logoUrl));

  //   if (response.statusCode == 200) {
  //     Uint8List imageBytes = response.bodyBytes;
  //     img.Image? original = img.decodeImage(imageBytes);
  //     if (original != null) {
  //       img.Image mono = img.grayscale(original);
  //       Uint8List finalLogo = Uint8List.fromList(img.encodePng(mono));
  //       printer.printImageBytes(finalLogo);
  //     }
  //   }

  //   printer.printNewLine();

  //   // 2. Company Name + TRN + Address
  //   printer.printCustom(store.name, 3, 1);
  //   if (store.address != null) printer.printCustom(store.address!, 1, 1);
  //   if (store.trn != null) printer.printCustom("TRN: ${store.trn}", 1, 1);

  //   printer.printNewLine();

  //   // 3. Title
  //   printer.printCustom("STATEMENT OF ACCOUNTS", 2, 1);
  //   printer.printCustom("-" * 68, 1, 1);

  //   // 4. Customer + Date Range
  //   printer.printCustom("Customer: $code | $name", 1, 0);
  //   printer.printCustom("Address: $address", 1, 0);
  //   printer.printCustom(
  //       "From: ${DateHelper.displayFromDateTime(_selectedDatefrom!)}", 1, 0);

  //   printer.printCustom(
  //       "To     : ${DateHelper.displayFromDateTime(_selectedDateto!)}", 1, 0);

  //   printer.printCustom("-" * 68, 1, 1);
  //   const dateHeader = 'Date';
  //   const refHeader = 'Ref';
  //   const debitHeader = 'Debit';
  //   const creditHeader = 'Credit';
  //   const balHeader = 'Balance';

  //   printer.printCustom(
  //       '${dateHeader.padRight(12)}'
  //       '${refHeader.padRight(8)}'
  //       '${debitHeader.padLeft(9)}'
  //       '${creditHeader.padLeft(9)}'
  //       '${balHeader.padLeft(10)}',
  //       1,
  //       0);
  //   printer.printCustom("-" * 68, 1, 0);

  //   // 6. OPENING ROW
  //   printer.printCustom(
  //       "${''.padRight(10)} ${''.padRight(30)} ${''.padRight(7)} ${'Opening'.padRight(7)} ${opening.toStringAsFixed(AppState().noOfDecimals ?? 2)}",
  //       1,
  //       0);

  //   // 7. ALL ROWS - Use balance from API (index 4)
  //   for (var row in data) {
  //     String date = DateHelper.displayDate(row[0].toString());
  //     String ref = row[1].toString();
  //     double Debit =
  //         row[2] != null ? double.parse(row[2].toString()).abs() : 0.0;
  //     double Credit =
  //         row[3] != null ? double.parse(row[3].toString()).abs() : 0.0;
  //     double balance = row[4] != null ? double.parse(row[4].toString()) : 0.0;

  //     final dateStr = date.length > 12 ? date.substring(0, 12) : date;
  //     final refStr = ref.length > 8 ? ref.substring(0, 8) : ref;

  //     printer.printCustom(
  //       '${dateStr.padRight(12)}'
  //       '${refStr.padRight(8)}'
  //       '${Debit.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(9)}'
  //       '${Credit.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(9)}'
  //       '${balance.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(10)}',
  //       1,
  //       0,
  //     );
  //   }

  //   printer.printCustom("-" * 68, 1, 1);

  //   // 8. CLOSING BALANCE
  //   printer.printCustom(
  //       "Closing Balance: ${closing.toStringAsFixed(AppState().noOfDecimals ?? 2)}",
  //       2,
  //       1);

  //   printer.printNewLine();

  //   // FINAL CUT
  //   printer.paperCut();
  // }
/// Main Print Dispatcher: Routes automatically to Zebra (CPCL) or Sewoo (ESC/POS)
   /// Main Print Dispatcher: single shared image pipeline, auto-detects
  /// Zebra vs Sewoo internally via printReport().
  Future<void> _printSOA(
    StoreDetail store,
    List<List<dynamic>> data,
    double opening,
    double closing,
    ) async {
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

    if (!_connected) await _connect();
    if (!_connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer not connected')),
      );
      return;
    }
   try {
  if (isZebraPrinter(_selectedDevice)) {
    final logoFile = store.logos;
    final logo = (logoFile != null && logoFile.isNotEmpty)
        ? await loadLogo(
            '${RestDatasource().Image_URL}/uploads/store/$logoFile',
          )
        : null;

    await printReport(
      printer,
      _selectedDevice,
      (b) => drawSoaReport(
        b,
        store,
        data,
        opening,
        closing,
        logo: logo,
        customerCode: code,
        customerName: name,
        customerAddress: address,
        fromDate: _selectedDatefrom,
        toDate: _selectedDateto,
      ),
    );
  } else {
    await _printSewooSOA(store, data, opening, closing);
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
  // 1. ZEBRA ENGINE (CPCL Mode - Clean Layout, No Overlap)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _printZebraSOA(
    StoreDetail store,
    List<List<dynamic>> data,
    double opening,
    double closing,
  ) async {
    final int decimals = AppState().noOfDecimals ?? 2;
    final cpcl = CpclBuilder(kLabelWidthDots);

    // ---- 1. Logo ----
    if (store.logos != null && store.logos!.isNotEmpty) {
      try {
        final logoUrl =
            '${RestDatasource().Image_URL}/uploads/store/${store.logos}';
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          img.Image? original = img.decodeImage(response.bodyBytes);
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
    cpcl.centerText(store.name, font: 5, lineGap: 34);
    if (store.address != null && store.address!.isNotEmpty) {
      cpcl.centerText(store.address!, font: 4, lineGap: 24);
    }
    if (store.trn != null && store.trn!.isNotEmpty) {
      cpcl.centerText("TRN: ${store.trn}", font: 4, lineGap: 24);
    }
    cpcl.hLine();
    cpcl.centerText("STATEMENT OF ACCOUNTS", font: 5, lineGap: 34);
    cpcl.hLine();

    // ---- 3. Customer + date range ----
    cpcl.text("Customer: ${code ?? ''} | ${name ?? ''}");
    if (address != null && address!.isNotEmpty) {
      cpcl.text("Address: $address");
    }
    if (_selectedDatefrom != null) {
      cpcl.twoColumn("From: ${DateHelper.displayFromDateTime(_selectedDatefrom!)}", 
          "To: ${_selectedDateto != null ? DateHelper.displayFromDateTime(_selectedDateto!) : ''}");
    }
    cpcl.hLine();

    // ---- 4. Table Header (Max 42 characters) ----
    // Format: Date (10) | Ref (10) | Debit (7) | Credit (7) | Bal (8) = 42 chars
    cpcl.text("Date       Ref        Debit  Credit   Balance", font: 4, lineGap: 30);
    cpcl.hLine(thickness: 1);

    // ---- 5. Opening balance row ----
    String openAmt = opening.toStringAsFixed(decimals).padLeft(8);
    cpcl.text("                      Opening Balance:$openAmt", font: 4, lineGap: 28);

    // ---- 6. Transaction rows (Clean 42-char alignment) ----
    for (var row in data) {
      String date = DateHelper.displayDate(row[0].toString());
      if (date.length > 10) date = date.substring(0, 10);
      String dateStr = date.padRight(11);

      String ref = row[1]?.toString() ?? '';
      if (ref.length > 10) ref = ref.substring(0, 10);
      String refStr = ref.padRight(11);

      double debit =
          row[2] != null ? double.parse(row[2].toString()).abs() : 0.0;
      double credit =
          row[3] != null ? double.parse(row[3].toString()).abs() : 0.0;
      double balance =
          row[4] != null ? double.parse(row[4].toString()) : 0.0;

      String dStr = debit > 0 ? debit.toStringAsFixed(decimals).padLeft(7) : "       ";
      String cStr = credit > 0 ? credit.toStringAsFixed(decimals).padLeft(7) : "       ";
      String bStr = balance.toStringAsFixed(decimals).padLeft(8);

      cpcl.text('$dateStr$refStr$dStr $cStr $bStr', font: 4, lineGap: 28);
    }
    cpcl.hLine();

    // ---- 7. Closing balance ----
    cpcl.boldText("Closing Balance: ${closing.toStringAsFixed(decimals)}",
        font: 5, x: 180, lineGap: 36);
    cpcl.feed(10);
    cpcl.centerText('--- THANK YOU ---', font: 4, lineGap: 24);
    cpcl.feed(40);

    final bytes = cpcl.build();
    await sendCpcl(printer, bytes);
  }
  // ═══════════════════════════════════════════════════════════════
  // 2. SEWOO ENGINE (Original Exact ESC/POS Size & Formatting)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _printSewooSOA(
    StoreDetail store,
    List<List<dynamic>> data,
    double opening,
    double closing,
  ) async {
    // 1. Print LOGO
      final logoUrl =
        '${RestDatasource().Image_URL}/uploads/store/${store.logos}';
    final logoBytes = await buildSewooLogoBytes(logoUrl);
    if (logoBytes != null) {
      await printer.printImageBytes(logoBytes);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    printer.printNewLine();

    // 2. Company Name + TRN + Address
    printer.printCustom(store.name, 3, 1);
    if (store.address != null) printer.printCustom(store.address!, 1, 1);
    if (store.trn != null) printer.printCustom("TRN: ${store.trn}", 1, 1);

    printer.printNewLine();

    // 3. Title
    printer.printCustom("STATEMENT OF ACCOUNTS", 2, 1);
    printer.printCustom("-" * 68, 1, 1);

    // 4. Customer + Date Range
    printer.printCustom("Customer: $code | $name", 1, 0);
    printer.printCustom("Address: $address", 1, 0);
    printer.printCustom(
        "From: ${DateHelper.displayFromDateTime(_selectedDatefrom!)}", 1, 0);

    printer.printCustom(
        "To     : ${DateHelper.displayFromDateTime(_selectedDateto!)}", 1, 0);

    printer.printCustom("-" * 68, 1, 1);
    const dateHeader = 'Date';
    const refHeader = 'Ref';
    const debitHeader = 'Debit';
    const creditHeader = 'Credit';
    const balHeader = 'Balance';

    printer.printCustom(
        '${dateHeader.padRight(12)}'
        '${refHeader.padRight(8)}'
        '${debitHeader.padLeft(9)}'
        '${creditHeader.padLeft(9)}'
        '${balHeader.padLeft(10)}',
        1,
        0);
    printer.printCustom("-" * 68, 1, 0);

    // 6. OPENING ROW
    printer.printCustom(
        "${''.padRight(10)} ${''.padRight(30)} ${''.padRight(7)} ${'Opening'.padRight(7)} ${opening.toStringAsFixed(AppState().noOfDecimals ?? 2)}",
        1,
        0);

    // 7. ALL ROWS - Use balance from API (index 4)
    for (var row in data) {
      String date = DateHelper.displayDate(row[0].toString());
      String ref = row[1].toString();
      double Debit =
          row[2] != null ? double.parse(row[2].toString()).abs() : 0.0;
      double Credit =
          row[3] != null ? double.parse(row[3].toString()).abs() : 0.0;
      double balance = row[4] != null ? double.parse(row[4].toString()) : 0.0;

      final dateStr = date.length > 12 ? date.substring(0, 12) : date;
      final refStr = ref.length > 8 ? ref.substring(0, 8) : ref;

      printer.printCustom(
        '${dateStr.padRight(12)}'
        '${refStr.padRight(8)}'
        '${Debit.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(9)}'
        '${Credit.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(9)}'
        '${balance.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(10)}',
        1,
        0,
      );
    }

    printer.printCustom("-" * 68, 1, 1);

    // 8. CLOSING BALANCE
    printer.printCustom(
        "Closing Balance: ${closing.toStringAsFixed(AppState().noOfDecimals ?? 2)}",
        2,
        1);

    printer.printNewLine();

    // FINAL CUT
    printer.paperCut();
  }

  Future<void> _generateAndPrintSOA(
      List data, double opening, double closing) async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));

    if (response.statusCode == 200) {
      StoreDetail storeDetail =
          StoreDetail.fromJson(json.decode(response.body));

      await _printSOA(
        storeDetail,
        data.map<List<dynamic>>((e) => List<dynamic>.from(e)).toList(),
        opening,
        closing,
      );
    }
  }

  bool isOutstandingSelected = true;
  List<Transaction> transactions = [];

  void toggleSelection() {
    setState(() {
      isOutstandingSelected = !isOutstandingSelected;
    });
  }

  late Future<SOAResponse> futureSOA;
  DateTime? _selectedDatefrom;
  DateTime? _selectedDateto;

  @override
  void initState() {
    super.initState();
    _initPrinter();
   _selectedDatefrom =
    DateTime(DateTime.now().year, DateTime.now().month, 1);

_selectedDateto =
    DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

_refreshData();
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      id = params!['customerId'];
      name = params['name'];
      address = params['address'];
      code = params['code'];
      payment = params!['paymentTerms'];
    }

    // Fetch customer deliveries here, as the context is now safe to use.
    futureSOA = fetchSOAData();
  }

  void _refreshData() {
    setState(() {
      futureSOA = fetchSOAData();
      // _fetchtransactions();
    });
  }

  Future<SOAResponse> fetchSOAData() async {
    final fromDate = _selectedDatefrom ?? DateTime.now();
    final toDate = _selectedDateto ?? DateTime.now();
    final fromDateString = DateFormat('yyyy-MM-dd').format(fromDate);
    final toDateString = DateFormat('yyyy-MM-dd').format(toDate);

    final String outstand =
        '${RestDatasource().BASE_URL}/api/get_soa_use_outstanding?customer_id=$id&from_date=$fromDateString&to_date=$toDateString';

    final String alltransaction =
        '${RestDatasource().BASE_URL}/api/get_soa_use_alltransaction?customer_id=$id&from_date=$fromDateString&to_date=$toDateString';

    final String url = isOutstandingSelected ? outstand : alltransaction;
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      final soa = SOAResponse.fromJson(json);

      return soa;
    } else {
      throw Exception('Failed to load SOA data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppConfig.colorPrimary,
        title: const Text(
          'Statement Of Accounts',
          style: AppConfig.pageTitleStyle,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => futureSOA,
        child: FutureBuilder<SOAResponse>(
          future: futureSOA,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final data = snapshot.data!.data;
              final opening = snapshot.data!.opening;
              var closing = snapshot.data!.closing;
              double balanceDue = 0;
              for (var item in data) {
                if (item is List && item.length > 4) {
                  balanceDue += double.tryParse(item[4].toString()) ?? 0;
                }
              }
              sortDataByDate(data);

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "$name | $payment",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                                      Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 4.0, 16.0, 4.0),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (!isOutstandingSelected) {
                                    toggleSelection();
                                    setState(() {
                                      _refreshData();
                                    });
                                  }
                                },
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 30.0,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOutstandingSelected
                                        ? AppConfig.colorPrimary
                                        : const Color.fromARGB(
                                            0, 204, 122, 122),
                                    border: Border.all(
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Text(
                                    "Outstanding",
                                    style: TextStyle(
                                      color: isOutstandingSelected
                                          ? Colors.white
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (isOutstandingSelected) {
                                    toggleSelection();
                                    setState(() {
                                      _refreshData();
                                    });
                                  }
                                },
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 30.0,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !isOutstandingSelected
                                        ? AppConfig.colorPrimary
                                        : Colors.transparent,
                                    border: Border.all(
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Text(
                                    "All Transactions",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: !isOutstandingSelected
                                          ? Colors.white
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                                                    Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await _generateAndPrintSOA(
                                      data, opening, closing);
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.print,
                                    color: Colors.blue,
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await _generateAndPrintPdf(
                                      data, opening, closing);
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.document_scanner,
                                    color: Colors.red,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            "From Date",
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              _selectDatefrom(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedDatefrom == null
                                          ? 'Select Date'
                                          : DateHelper.displayFromDateTime(
                                              _selectedDatefrom!),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.calendar_month,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            "To Date",
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              _selectDateto(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedDateto == null
                                          ? 'Select Date'
                                          : DateHelper.displayFromDateTime(
                                              _selectedDateto!),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.calendar_month,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isOutstandingSelected)
                      Container(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              color: Colors.grey,
                              child: Table(
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                columnWidths: const {
                                  0: FlexColumnWidth(1.6), // Date
                                  1: FlexColumnWidth(
                                      1.3), // Reference (widened for full label)
                                  2: FlexColumnWidth(1.1), // Debit
                                  3: FlexColumnWidth(1.1), // Credit
                                  4: FlexColumnWidth(1.2), // Balance
                                },
                                children: const [
                                  TableRow(
                                    children: [
                                      Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(12, 8, 4, 8),
                                        child: Text(
                                          "Date",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 2,
                                            right: 4,
                                            top: 8,
                                            bottom: 8),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            "Reference",
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 2,
                                            right: 18,
                                            top: 8,
                                            bottom: 8),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            "Debit",
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 16,
                                            right: 6,
                                            top: 8,
                                            bottom: 8),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            "Credit",
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                            right: 10, top: 8, bottom: 8),
                                        child: Text(
                                          "Balance",
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemCount: data.length +
                                  2, // increase by 2 to account for opening and closing balance rows
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  // Opening balance row
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text(
                                              "Opening Balance : ${opening.toStringAsFixed(AppState().noOfDecimals ?? 2)}",
                                            ),
                                            const SizedBox(width: 3),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (index == data.length + 1) {
                                  // Closing balance row - nothing to render here, Balance Due already shows it below
                                  return const SizedBox.shrink();
                                } else {
                                  final row = data[index - 1];
                                  return Container(
                                    width: double.infinity,
                                    color: index % 2 == 0
                                        ? Colors.grey.shade200
                                        : Colors.white,
                                    child: Table(
                                      defaultVerticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      columnWidths: const {
                                        0: FlexColumnWidth(1.6), // Date
                                        1: FlexColumnWidth(1.3), // Reference
                                        2: FlexColumnWidth(1.1), // Amount
                                        3: FlexColumnWidth(1.1), // Payment
                                        4: FlexColumnWidth(1.2), // Balance
                                      },
                                      children: [
                                        TableRow(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      12, 6, 4, 6),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  DateHelper.displayDate(
                                                      row[0].toString()),
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 2,
                                                  right: 4,
                                                  top: 6,
                                                  bottom: 6),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  row[1].toString(),
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 2,
                                                  right: 18,
                                                  top: 6,
                                                  bottom: 6),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  (double.tryParse(row[2]
                                                              .toString()) ??
                                                          0.0)
                                                      .toStringAsFixed(AppState()
                                                              .noOfDecimals ??
                                                          2),
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16,
                                                  right: 6,
                                                  top: 6,
                                                  bottom: 6),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  (double.tryParse(row[3]
                                                              .toString()) ??
                                                          0.0)
                                                      .abs()
                                                      .toStringAsFixed(AppState()
                                                              .noOfDecimals ??
                                                          2),
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 10, top: 6, bottom: 6),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  (double.tryParse(row[4]
                                                              .toString()) ??
                                                          0.0)
                                                      .toStringAsFixed(AppState()
                                                              .noOfDecimals ??
                                                          2),
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                            Divider(
                              color: Colors.black38,
                              thickness: 2,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "Balance Due: ${balanceDue.toStringAsFixed(AppState().noOfDecimals ?? 2)}",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              color: Colors.grey,
                              child: Table(
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.middle,
                                columnWidths: const {
                                  0: FlexColumnWidth(1.6), // Date
                                  1: FlexColumnWidth(1.3), // Reference
                                  2: FlexColumnWidth(1.1), // Debit
                                  3: FlexColumnWidth(1.1), // Credit
                                  4: FlexColumnWidth(1.2), // Balance
                                },
                                children: const [
                                  TableRow(
                                    children: [
                                      Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(12, 8, 4, 8),
                                        child: Text(
                                          "Date",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: 2,
                                            right: 4,
                                            top: 8,
                                            bottom: 8),
                                        child: Text(
                                          "Reference",
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 2,
                                            right: 18,
                                            top: 8,
                                            bottom: 8),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            "Debit",
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 16,
                                            right: 6,
                                            top: 8,
                                            bottom: 8),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            "Credit",
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                            right: 10, top: 8, bottom: 8),
                                        child: Text(
                                          "Balance",
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemCount: data.length +
                                  2, // increase by 2 to account for opening and closing balance rows
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  // Opening balance row
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text(
                                              "Opening Balance : ${opening.toStringAsFixed(AppState().noOfDecimals ?? 2)}",
                                            ),
                                            const SizedBox(width: 3),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (index == data.length + 1) {
                                  // Closing balance row - nothing to render here, Balance Due already shows it below
                                  return const SizedBox.shrink();
                                } else {
                                  final row = data[index - 1];
                                  return Container(
                                    width: double.infinity,
                                    color: index % 2 == 0
                                        ? Colors.grey.shade200
                                        : Colors.white,
                                    child: Table(
                                      defaultVerticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      columnWidths: const {
                                        0: FlexColumnWidth(1.6), // Date
                                        1: FlexColumnWidth(1.3), // Reference
                                        2: FlexColumnWidth(1.1), // Amount
                                        3: FlexColumnWidth(1.1), // Payment
                                        4: FlexColumnWidth(1.2), // Balance
                                      },
                                      children: [
                                        TableRow(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      12, 6, 4, 6),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  DateHelper.displayDate(
                                                      row[0].toString()),
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 2,
                                                  right: 4,
                                                  top: 6,
                                                  bottom: 6),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  row[1].toString(),
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 2,
                                                  right: 18,
                                                  top: 6,
                                                  bottom: 6),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  (double.tryParse(row[2]
                                                              .toString()) ??
                                                          0.0)
                                                      .toStringAsFixed(AppState()
                                                              .noOfDecimals ??
                                                          2),
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16,
                                                  right: 6,
                                                  top: 6,
                                                  bottom: 6),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  (double.tryParse(row[3]
                                                              .toString()) ??
                                                          0.0)
                                                      .abs()
                                                      .toStringAsFixed(AppState()
                                                              .noOfDecimals ??
                                                          2),
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 10, top: 6, bottom: 6),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Text(
                                                  (double.tryParse(row[4]
                                                              .toString()) ??
                                                          0.0)
                                                      .toStringAsFixed(AppState()
                                                              .noOfDecimals ??
                                                          2),
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                            const Divider(
                              color: Colors.black38,
                              thickness: 2,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "Balance Due: ${balanceDue.toStringAsFixed(AppState().noOfDecimals ?? 2)}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text("Something went wrong"),
              );
            }

            return Shimmer.fromColors(
              baseColor: AppConfig.buttonDeactiveColor.withOpacity(0.1),
              highlightColor: AppConfig.backButtonColor,
              child: Center(
                child: Column(
                  children: [
                    CommonWidgets.loadingContainers(
                        height: SizeConfig.blockSizeVertical * 10,
                        width: SizeConfig.blockSizeHorizontal * 90),
                    CommonWidgets.loadingContainers(
                        height: SizeConfig.blockSizeVertical * 60,
                        width: SizeConfig.blockSizeHorizontal * 90),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _selectDatefrom(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDatefrom ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDatefrom) {
      setState(() {
        _selectedDatefrom = pickedDate;
      });
      _refreshData(); // Refresh data after selecting from date
    }
  }

// Function to show the date picker
  Future<void> _selectDateto(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateto ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDateto) {
      setState(() {
        _selectedDateto = pickedDate;
      });
      _refreshData(); // Refresh data after selecting to date
    }
  }
}
