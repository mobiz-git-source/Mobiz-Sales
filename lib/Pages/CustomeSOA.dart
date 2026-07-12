import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobizapp/Models/appstate.dart';
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

      String addressText = storeDetail.address != null
          ? "Address: ${storeDetail.address}, "
          : "";
      String countryText =
      storeDetail.country != null ? "${storeDetail.country}" : "";

      pdf.addPage(
        pw.MultiPage(
          header: (pw.Context context) {
            if (context.pageNumber == 1) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                storeDetail.name,
                                style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              if (storeDetail.address != null)
                                pw.Text(storeDetail.address!),
                              if (storeDetail.trn != null)
                                pw.Text('TRN: ${storeDetail.trn}'),
                            ]
                        ),
                        pw.Column(
                            children: [
                              pw.Image(
                                pw.MemoryImage(logoBytes),
                                height: 100,
                                width: 150,
                                fit: pw.BoxFit.fitWidth,
                              ),
                            ]
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Text(
                      'Statement of Accounts',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            width: 300,
                            child: pw.Text(
                              overflow: pw.TextOverflow.span,
                              "${name}",
                              style: pw.TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ),
                          pw.SizedBox(
                            width: 300,
                            child: pw.Text(
                              overflow: pw.TextOverflow.span,
                              "$address",
                              style: pw.TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'From Date: ${_selectedDatefrom != null ? DateFormat('dd MMMM yyyy').format(_selectedDatefrom!) : 'Select Date'}',
                            style: pw.TextStyle(
                              fontSize: 15,
                            ),
                          ),
                          pw.Text(
                            'To Date: ${_selectedDateto != null ? DateFormat('dd MMMM yyyy').format(_selectedDateto!) : 'Select Date'}',
                            style: pw.TextStyle(
                              fontSize: 15,
                            ),
                          ),
                          if (storeDetail.currency != null)
                            pw.Text(
                              'Currency: ${storeDetail.currency}',
                              style: pw.TextStyle(fontSize: 15),
                            ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                ],
              );
            } else {
              return pw.Container(); // Empty container for other pages
            }
          },
          build: (pw.Context context) => [
            pw.Table(
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Date',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Reference',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Debit',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Credit',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Balance',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Opening Balance'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(opening.toStringAsFixed(AppState().noOfDecimals ?? 2)),
                    ),
                  ],
                ),
                ...data.asMap().entries.map((entry) {
                  int index = entry.key;
                  var row = entry.value;

                  // Use the balance from API (5th column - index 4)
                  // Make sure to handle null cases
                  double balance = row[4] != null
                      ? double.parse(row[4].toString())
                      : 0.0;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color:
                      index % 2 == 0 ? PdfColors.white : PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(row[0].toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(row[1].toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(row[2] != null
                            ? double.parse(row[2].toString()).toStringAsFixed(AppState().noOfDecimals ?? 2)
                            : "0.00",textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(row[3] != null
                            ? double.parse(row[3].toString()).toStringAsFixed(AppState().noOfDecimals ?? 2)
                            : "0.00",textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding:  pw.EdgeInsets.all(4),
                        child: pw.Text(balance.toStringAsFixed(AppState().noOfDecimals ?? 2),textAlign: pw.TextAlign.right),
                      ),
                    ],
                  );
                }).toList(),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.white),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 20),
                      child: pw.Text('Closing Balance',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 20),
                      child: pw.Text(closing.toStringAsFixed(AppState().noOfDecimals ?? 2),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
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
    } else {
      throw Exception('Failed to load store details');
    }
  }

  void _printSOA(
      StoreDetail store,
      List<List<dynamic>> data,
      double opening,
      double closing,
      ) async {
    if (!_connected) {
      await _connect();
    }

    // 1. Print LOGO
    final logoUrl =
        '${RestDatasource().Image_URL}/uploads/store/${store.logos}';
    final response = await http.get(Uri.parse(logoUrl));

    if (response.statusCode == 200) {
      Uint8List imageBytes = response.bodyBytes;
      img.Image? original = img.decodeImage(imageBytes);
      if (original != null) {
        img.Image mono = img.grayscale(original);
        Uint8List finalLogo = Uint8List.fromList(img.encodePng(mono));
        printer.printImageBytes(finalLogo);
      }
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
        "From: ${DateFormat('dd MMM yyyy').format(_selectedDatefrom!)}", 1, 0);
    printer.printCustom(
        "To     : ${DateFormat('dd MMM yyyy').format(_selectedDateto!)}", 1, 0);

    printer.printCustom("-" * 68, 1, 1);
    const dateHeader = 'Date';
    const refHeader = 'Ref';
    const creditHeader = 'Credit';
    const debitHeader = 'Debit';
    const balHeader = 'Balance';

    printer.printCustom(
        '${dateHeader.padRight(12)}'
            '${refHeader.padRight(8)}'
            '${creditHeader.padLeft(9)}'
            '${debitHeader.padLeft(9)}'
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
      String date = row[0].toString();
      String ref = row[1].toString();
      double amount = row[2] != null ? double.parse(row[2].toString()) : 0.0;
      double payment = row[3] != null ? double.parse(row[3].toString()) : 0.0;
      double balance = row[4] != null ? double.parse(row[4].toString()) : 0.0;

      final dateStr = date.length > 12 ? date.substring(0, 12) : date;
      final refStr = ref.length > 8 ? ref.substring(0, 8) : ref;

      printer.printCustom(
        '${dateStr.padRight(12)}'
            '${refStr.padRight(8)}'
            '${amount.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(9)}'
            '${payment.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(9)}'
            '${balance.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(10)}',
        1,
        0,
      );
    }

    printer.printCustom("-" * 68, 1, 1);

    // 8. CLOSING BALANCE
    printer.printCustom(
        "Closing Balance: ${closing.toStringAsFixed(AppState().noOfDecimals ?? 2)}", 2, 1);

    printer.printNewLine();

    // FINAL CUT
    printer.paperCut();
  }


  _generateAndPrintSOA(List data, double opening, double closing) async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));

    if (response.statusCode == 200) {
      StoreDetail storeDetail =
      StoreDetail.fromJson(json.decode(response.body));

      _printSOA(
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
    _selectedDatefrom = DateTime.now();
    _selectedDateto = DateTime.now();
    _refreshData();
    // _fetchtransactions();
    // futureSOA = fetchSOAData(); // Initial data load
    _selectedDatefrom = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _selectedDateto =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
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
      print(response.request);
      print(id);
      return SOAResponse.fromJson(jsonDecode(response.body));
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
          style: TextStyle(color: AppConfig.backgroundColor),
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
                print(double.tryParse(item[4].toString()));              }
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
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                        maxWidth: 120.0,
                                        minHeight: 25.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOutstandingSelected
                                            ? AppConfig.colorPrimary
                                            : Colors.transparent,
                                        border: Border.all(
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child: Center(
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
                                        maxWidth: 120.0,
                                        minHeight: 25.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: !isOutstandingSelected
                                            ? AppConfig.colorPrimary
                                            : Colors.transparent,
                                        border: Border.all(
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "All Transactions",
                                          style: TextStyle(
                                            color: !isOutstandingSelected
                                                ? Colors.white
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  print("object");
                                  await _generateAndPrintSOA(
                                      data, opening, closing);
                                },
                                child: Icon(
                                  Icons.print,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                              ),
                              SizedBox(width: 20,),
                              GestureDetector(
                                onTap: () async {
                                  await _generateAndPrintPdf(
                                      data, opening, closing);
                                },
                                child: Icon(Icons.document_scanner,
                                    color: Colors.red, size: 30),
                              ),
                              SizedBox(
                                width: 10,
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "From Date",
                            style: TextStyle(fontSize: 15),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Text(
                                _selectedDatefrom == null
                                    ? 'Select Date'
                                    : DateFormat('dd/MM/yyyy')
                                        .format(_selectedDatefrom!),
                              ),
                            ),
                          ),
                          GestureDetector(
                              onTap: () {
                                _selectDatefrom(context);
                              },
                              child: Icon(Icons.calendar_month)),
                          Text(
                            "To Date",
                            style: TextStyle(fontSize: 15),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Text(
                                _selectedDateto == null
                                    ? 'Select Date'
                                    : DateFormat('dd/MM/yyyy')
                                        .format(_selectedDateto!),
                              ),
                            ),
                          ),
                          GestureDetector(
                              onTap: () {
                                _selectDateto(context);
                              },
                              child: Icon(Icons.calendar_month)),
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
                                  0: FlexColumnWidth(),
                                  1: FlexColumnWidth(),
                                  2: FlexColumnWidth(),
                                  3: FlexColumnWidth(),
                                  4: FlexColumnWidth(),
                                },
                                children: const [
                                  TableRow(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12.0, vertical: 8),
                                        child: Text(
                                          "Date",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        "Reference",
                                        maxLines: 1,
                                        style: TextStyle(
                                            overflow: TextOverflow.fade,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        "Debit",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        "Credit",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        "Balance",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
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
                                  // Display opening balance
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
                                              // style: TextStyle(
                                              //   fontSize: 15,
                                              // ),
                                            ),
                                            SizedBox(
                                              width: 3,
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (index == data.length + 1) {
                                  // Display closing balance
                                  double balance = opening;
                                  for (int i = 0; i < data.length; i++) {
                                    double amount = data[i][2] != null
                                        ? double.parse(data[i][2].toString())
                                        : 0.0;
                                    double payment = data[i][3] != null
                                        ? double.parse(data[i][3].toString())
                                        : 0.0;
                                    balance += amount;
                                    balance -= payment;
                                  }
                                } else {
                                  final row = data[index - 1];
                                  double balance = opening;
                                  for (int i = 0; i < index - 1; i++) {
                                    double amount = data[i][2] != null
                                        ? double.parse(data[i][2].toString())
                                        : 0.0;
                                    double payment = data[i][3] != null
                                        ? double.parse(data[i][3].toString())
                                        : 0.0;
                                    balance += amount;
                                    balance -= payment;
                                  }
                                  // Get current row's amount and payment
                                  double amount = row[2] != null
                                      ? double.parse(row[2].toString())
                                      : 0.0;
                                  double payment = row[3] != null
                                      ? double.parse(row[3].toString())
                                      : 0.0;
                                  balance += amount;
                                  balance -= payment;

                                  return Container(
                                    width: double.infinity,
                                    height: 25,
                                    color: index % 2 == 0
                                        ? Colors.grey.shade200
                                        : Colors.white,
                                    child: Table(
                                      defaultVerticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      columnWidths: const {
                                        0: FlexColumnWidth(1.3),
                                        1: FlexColumnWidth(),
                                        2: FlexColumnWidth(),
                                        3: FlexColumnWidth(),
                                        4: FlexColumnWidth(),
                                      },
                                      children: [
                                        TableRow(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Text(
                                                row[0].toString(),
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Text(
                                                row[1].toString(),
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Text(
                                                row[2].toStringAsFixed(AppState().noOfDecimals ?? 2),
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Text(
                                                row[3].toStringAsFixed(AppState().noOfDecimals ?? 2),
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Text(
                                                row[4].toStringAsFixed(AppState().noOfDecimals ?? 2),
                                                style: TextStyle(fontSize: 13),
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
                                  0: FlexColumnWidth(),
                                  1: FlexColumnWidth(),
                                  2: FlexColumnWidth(),
                                  3: FlexColumnWidth(),
                                  4: FlexColumnWidth(),
                                },
                                children: [
                                  const TableRow(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12.0, vertical: 8),
                                        child: Text(
                                          "Date",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        "Reference",
                                        maxLines: 1,
                                        style: TextStyle(
                                            overflow: TextOverflow.fade,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        "Debit",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        "Credit",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        "Balance",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
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
                                  // Display opening balance
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
                                              // style: TextStyle(
                                              //   fontSize: 15,
                                              // ),
                                            ),
                                            SizedBox(
                                              width: 3,
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (index == data.length + 1) {
                                  // Display closing balance
                                  double balance = opening;
                                  for (int i = 0; i < data.length; i++) {
                                    double amount = data[i][2] != null
                                        ? double.parse(data[i][2].toString())
                                        : 0.0;
                                    double payment = data[i][3] != null
                                        ? double.parse(data[i][3].toString())
                                        : 0.0;
                                    // double babalance = data[i][5] != null
                                    //     ? double.parse(data[i][5].toString()):0.0;
                                    balance += amount;
                                    balance -= payment;
                                  }
                                } else {
                                  final row = data[index - 1];
                                  double balance = opening;
                                  for (int i = 0; i < index - 1; i++) {
                                    double amount = data[i][2] != null
                                        ? double.parse(data[i][2].toString())
                                        : 0.0;
                                    double payment = data[i][3] != null
                                        ? double.parse(data[i][3].toString())
                                        : 0.0;
                                    balance += amount;
                                    balance -= payment;
                                  }
                                  double amount = row[2] != null
                                      ? double.parse(row[2].toString())
                                      : 0.0;
                                  double payment = row[3] != null
                                      ? double.parse(row[3].toString())
                                      : 0.0;
                                  balance += amount;
                                  balance -= payment;

                                  return Container(
                                    width: double.infinity,
                                    height: 35,
                                    color: index % 2 == 0
                                        ? Colors.grey.shade200
                                        : Colors.white,
                                    child: Table(
                                      defaultVerticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      columnWidths: const {
                                        0: FlexColumnWidth(1.3),
                                        1: FlexColumnWidth(),
                                        2: FlexColumnWidth(),
                                        3: FlexColumnWidth(),
                                        4: FlexColumnWidth(),
                                      },
                                      children: [
                                        TableRow(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Text(
                                                row[0].toString(),
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Text(
                                                row[1].toString(),
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Text(
                                                row[2].toString(),
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Text(
                                                row[3].toString(),
                                                style: TextStyle(fontSize: 13),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Text(
                                                row[4].toString(),
                                                style: TextStyle(fontSize: 13),
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
