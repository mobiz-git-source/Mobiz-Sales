import 'dart:convert';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'package:number_to_words/number_to_words.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/Group_Model.dart';
import '../Models/Group_Model.dart' as Invoice;
import 'package:http/http.dart' as http;
import 'package:mobizapp/Utilities/rest_ds.dart';

class GroupPrint extends StatefulWidget {
  static const routeName = "/GroupPrint";
  const GroupPrint({super.key});

  @override
  State<GroupPrint> createState() => _GroupPrintState();
}

class _GroupPrintState extends State<GroupPrint> {
  int? pricegroupId;
  int? saleId;
  int? returnId;
  int? payId;
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  bool _connected = false;
  BluetoothDevice? _selectedDevice;
  List<BluetoothDevice> _devices = [];
  late Future<SaleReturnCollection> futureData;

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
      try {
        await printer.connect(_selectedDevice!);
        setState(() {
          _connected = true;
        });
      } catch (e) {
        print("Error connecting to printer: $e");
      }
    }
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

  Future<SaleReturnCollection> fetchData() async {
    final String url =
        '${RestDatasource().BASE_URL}/api/sale_return_collection_print?sales=${saleId}&return=${returnId}&collection=${payId}&store_id=${AppState().storeId}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      print(response.request);
      var jsonData = json.decode(response.body);
      return SaleReturnCollection.fromJson(jsonData);
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    super.initState();
    _initPrinter();
    futureData = fetchData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)!.settings.arguments != null) {
        final Map<String, dynamic>? params =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        pricegroupId = params!['price_group_id'];
        saleId = params['saleId'];
        returnId = params['returnId'] ?? 0;
        payId = params['payId'];
        setState(() {
          futureData = fetchData();
        });
        print("sales:$saleId");
        print("sales:$returnId");
        print("sales:$payId");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Return Collection Print',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppConfig.colorPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<SaleReturnCollection>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final saleReturnData = snapshot.data!;
            return Center(
              child: InkWell(
                onTap: () {
                  _print(saleReturnData, true);
                },
                child: Icon(
                  Icons.print,
                  size: 100,
                  color: AppConfig.colorPrimary,
                ),
              ),
            );
          }
          return const Center(child: Text('No data available'));
        },
      ),
    );
  }

  void _print(Invoice.SaleReturnCollection invoice, bool isPrint) async {
    if (!_connected) {
      await _connect();
    }

    if (_connected) {
      var store = invoice.store ??
          invoice.sales?.store ??
          invoice.returnData?.store;
      
      var customer = invoice.sales?.customer ??
          invoice.returnData?.customer ??
          (invoice.collection?.customer != null &&
                  invoice.collection!.customer!.isNotEmpty
              ? invoice.collection!.customer!.first
              : null);

      if (store == null) return;

      String companyName = store.name ?? 'N/A';
      String companyAddress = store.address ?? 'N/A';
      String companyMail = store.email ?? 'N/A';
      String companyTRN = "TRN: ${store.trn ?? 'N/A'}";
      String billtype = "Tax Invoice";

      String customerName = customer?.name ?? 'N/A';
      List<String> nameWords = customerName.split(' ');
      String firstLine = customerName;
      String secondLine = "";
      if (nameWords.length > 7) {
        firstLine = nameWords.sublist(0, 7).join(' ');
        secondLine = nameWords.sublist(7).join(' ');
      }
      String customerContact = customer?.contactNumber ?? 'N/A';
      String customerTRN = customer?.trn ?? '';
      String billType = invoice.sales?.cashCard ?? 'N/A';
      String invoiceNumber =
          invoice.sales?.invoiceNo ?? invoice.returnData?.invoiceNo ?? 'N/A';
      String? rawDate = invoice.sales?.inDate ?? invoice.returnData?.inDate;
      String? rawTime = invoice.sales?.inTime ?? invoice.returnData?.inTime;
      String invoiceDate = rawDate != null && rawDate.isNotEmpty
          ? DateFormat('dd MMMM yyyy').format(DateTime.parse(rawDate))
          : 'N/A';

      void printAlignedText(String leftText, String rightText) {
        const int maxLineLength = 68;
        int leftTextLength = leftText.length;
        int rightTextLength = rightText.length;
        int spaceLength = maxLineLength - (leftTextLength + rightTextLength);
        if (spaceLength < 0) spaceLength = 1;
        String spaces = ' ' * spaceLength;
        printer.printCustom('$leftText$spaces$rightText', 1, 0);
      }

      if (store.logo != null && store.logo!.isNotEmpty) {
        try {
          String logoUrl =
              'https://erpadmin.mobiz.ae/uploads/store/${store.logo}';
          final response = await http.get(Uri.parse(logoUrl));
          if (response.statusCode == 200) {
            Uint8List imageBytes = response.bodyBytes;

            // Decode image
            img.Image? originalImage = img.decodeImage(imageBytes);
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
        } catch (e) {
          print('Error printing logo: $e');
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
      printAlignedText("Invoice No: $invoiceNumber", "Date: $invoiceDate");
      printAlignedText("", "Time: $rawTime");
      printer.printNewLine();

      printAlignedText("Customer: $firstLine", "");
      if (secondLine.isNotEmpty) {
        printAlignedText("         $secondLine", "");
      }
      printAlignedText("Contact No: $customerContact", "");
      printAlignedText("${store.vatLabel ?? 'VAT'}: $customerTRN", " ");
      printAlignedText("Bill Type: $billType"," ");
      printer.printNewLine();

      // Sales Section
      if (invoice.sales != null && invoice.sales!.detail.isNotEmpty) {
        String salesTotal =
            invoice.sales!.total.toStringAsFixed(AppState().noOfDecimals ?? 2);
        String salesVat = invoice.sales!.totalTax
            .toStringAsFixed(AppState().noOfDecimals ?? 2);
        String salesGrandTotal = invoice.sales!.grandTotal
            .toStringAsFixed(AppState().noOfDecimals ?? 2);
        String salesAmountInWords = _getAmountInWords(invoice.sales!.grandTotal);
        String salesman = invoice.sales!.user?.name ?? 'N/A';

        printAlignedText("Sales", " ");
        printer.printCustom("-" * 70, 1, 1);

        const int col1 = 5,
            col2 = 22,
            col3 = 5,
            col4 = 4,
            col5 = 7,
            col6 = 8,
            col7 = 8,
            col9 = 6;
        String headers =
            "${'S.No'.padRight(col1)} ${'Product'.padRight(col2)} ${'Unit'.padRight(col3)}${'Qty'.padRight(col4)}${'Type'.padRight(col5)}${'Rate'.padRight(col6)}${'Amount'.padRight(col7)} ${'Total'.padLeft(col9)}";
        printer.printCustom(headers, 1, 0);

        for (int i = 0; i < invoice.sales!.detail.length; i++) {
          var d = invoice.sales!.detail[i];
          List<String> descLines = splitText(d.name, col2);
          for (int j = 0; j < descLines.length; j++) {
            String line = j == 0
                ? "${(i + 1).toString().padRight(col1)}${descLines[j].padRight(col2)}  ${d.unit.padRight(col3)}${d.quantity.toString().padRight(col4)}${d.productType.padRight(col5)}${d.mrp.toStringAsFixed(AppState().noOfDecimals ?? 2).padRight(col6)}${d.taxable.toStringAsFixed(AppState().noOfDecimals ?? 2).padRight(col7)}${d.amount.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(col9)}"
                : "${''.padRight(col1)}${descLines[j].padRight(col2)}${''.padRight(col3)}${''.padRight(col4)}${''.padRight(col5)}${''.padRight(col6)}${''.padRight(col7)}${''.padRight(col9)}";
            printer.printCustom(line, 1, 0);
          }
        }
        printer.printCustom("-" * 70, 1, 1);
        printAlignedText("Salesman: $salesman", "Total: $salesTotal");
        printer.printCustom("Vat: $salesVat", 1, 2);
        printer.printCustom("Grand Total: $salesGrandTotal", 1, 2);
        printer.printNewLine();
        printer.printCustom(salesAmountInWords, 1, 0);
        printer.printNewLine();
        printer.printNewLine();
      }

      // Return Section
      if (invoice.returnData != null && invoice.returnData!.detail.isNotEmpty) {
        String returnTotal = invoice.returnData!.total
            .toStringAsFixed(AppState().noOfDecimals ?? 2);
        String returnVat = invoice.returnData!.totalTax
            .toStringAsFixed(AppState().noOfDecimals ?? 2);
        String returnGrandTotal = invoice.returnData!.grandTotal
            .toStringAsFixed(AppState().noOfDecimals ?? 2);
        String returnAmountInWords = _getAmountInWords(invoice.returnData!.grandTotal);
        String salesman = invoice.returnData!.user?.name ?? 'N/A';
        String van = invoice.returnData!.van?.name ?? invoice.sales?.van?.name ?? 'N/A';

        String discountStr = '';
        if (invoice.returnData!.discount > 0) {
          discountStr =
              "Discount: ${invoice.returnData!.discount.toStringAsFixed(AppState().noOfDecimals ?? 2)}";
        }

        printAlignedText("Return", " ");
        printer.printCustom("-" * 70, 1, 1);

        const int col1 = 5,
            col2 = 22,
            col3 = 5,
            col4 = 4,
            col5 = 7,
            col6 = 8,
            col7 = 8,
            col9 = 6;
        String headers =
            "${'S.No'.padRight(col1)} ${'Product'.padRight(col2)} ${'Unit'.padRight(col3)}${'Qty'.padRight(col4)}${'Type'.padRight(col5)}${'Rate'.padRight(col6)}${'Amount'.padRight(col7)} ${'Total'.padLeft(col9)}";
        printer.printCustom(headers, 1, 0);

        for (int i = 0; i < invoice.returnData!.detail.length; i++) {
          var d = invoice.returnData!.detail[i];
          List<String> descLines = splitText(d.name, col2);
          for (int j = 0; j < descLines.length; j++) {
            String line = j == 0
                ? "${(i + 1).toString().padRight(col1)}${descLines[j].padRight(col2)}  ${d.unit.padRight(col3)}${d.quantity.toString().padRight(col4)}${d.productType.padRight(col5)}${d.mrp.toStringAsFixed(AppState().noOfDecimals ?? 2).padRight(col6)}${d.taxable.toStringAsFixed(AppState().noOfDecimals ?? 2).padRight(col7)}${d.amount.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(col9)}"
                : "${''.padRight(col1)}${descLines[j].padRight(col2)}${''.padRight(col3)}${''.padRight(col4)}${''.padRight(col5)}${''.padRight(col6)}${''.padRight(col7)}${''.padRight(col9)}";
            printer.printCustom(line, 1, 0);
          }
        }
        printer.printCustom("-" * 70, 1, 1);
        if (discountStr.isNotEmpty) {
          printAlignedText("Van: $van", discountStr);
        } else {
          printAlignedText("Van: $van", "");
        }
        printAlignedText("Salesman: $salesman", "Total: $returnTotal");
        printer.printCustom("Vat: $returnVat", 1, 2);
        printer.printCustom("Grand Total: $returnGrandTotal", 1, 2);
        printer.printNewLine();
        printer.printCustom(returnAmountInWords, 1, 0);
        printer.printNewLine();
        printer.printNewLine();
      }

      // Collection Section
      if (invoice.collection != null &&
          ((invoice.collection!.sales != null &&
                  invoice.collection!.sales!.isNotEmpty) ||
              (double.tryParse(invoice.collection!.totalAmount ?? '0') ?? 0) !=
                  0)) {
        printAlignedText("Collection", " ");
        printer.printCustom("-" * 72, 1, 1);

        if (invoice.collection!.totalAmount != null) {
          double amt = double.tryParse(invoice.collection!.totalAmount!) ?? 0;
          printAlignedText('Amount: ${amt.toStringAsFixed(AppState().noOfDecimals ?? 2)}', ' ');
        }
        if (invoice.collection!.collectionType == 'Cheque') {
          printAlignedText('Collection Type: Cheque', ' ');
          printAlignedText('Bank Name: ${invoice.collection!.bank}', ' ');
          printAlignedText('Cheque No: ${invoice.collection!.chequeNo}', ' ');
          printAlignedText(
              'Cheque Date: ${invoice.collection!.chequeDate}', ' ');
        } else if (invoice.collection!.collectionType == 'Cash') {
          printAlignedText('Collection Type: Cash', ' ');
        }

        if (invoice.collection!.sales != null &&
            invoice.collection!.sales!.isNotEmpty) {
          printer.printNewLine();
          printer.printCustom("-" * 72, 1, 1);
          const int colc0 = 4, colc1 = 14, colc2 = 20, colc3 = 14, colc4 = 8;
          String headersc =
              "${''.padRight(colc0)}${'SI.NO'.padRight(colc1)} ${'Reference NO'.padRight(colc2)} ${'Type'.padRight(colc3)}${'Amount'.padLeft(colc4)}";
          printer.printCustom(headersc, 1, 0);
          printer.printCustom("-" * 72, 1, 1);

          for (var i = 0; i < invoice.collection!.sales!.length; i++) {
            var sale = invoice.collection!.sales![i];
            double saleAmount = double.tryParse(sale.amount ?? '0') ?? 0;
            String line =
                "${('').padRight(colc0)}${(i + 1).toString().padRight(colc1)} ${sale.invoiceNo?.padRight(colc2) ?? 'N/A'.padRight(colc2)}${formatInvoiceType(sale.invoiceType).padRight(colc3)}${saleAmount.toStringAsFixed(AppState().noOfDecimals ?? 2).padLeft(colc4)}";
            printer.printCustom(line, 1, 0);
          }
          printer.printNewLine();
          printer.printCustom("-" * 72, 1, 1);
        }

        if (invoice.collection!.roundOff != null &&
            (double.tryParse(invoice.collection!.roundOff!) ?? 0) != 0) {
          printAlignedText('',
              'Round Off: ${double.parse(invoice.collection!.roundOff!).toStringAsFixed(AppState().noOfDecimals ?? 2)}');
        }
        double totalCollAmt = double.tryParse(invoice.collection!.totalAmount ?? '0') ?? 0;
        printAlignedText('', 'Total: ${totalCollAmt.toStringAsFixed(AppState().noOfDecimals ?? 2)}');
        if (invoice.collection!.van != null &&
            invoice.collection!.van!.isNotEmpty) {
          printAlignedText("Van: ${invoice.collection!.van![0].name}", "");
        }
        if (invoice.collection!.user != null &&
            invoice.collection!.user!.isNotEmpty) {
          printAlignedText("Salesman: ${invoice.collection!.user![0].name}", "");
        }
        printer.printNewLine();
      }

      printer.paperCut();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer not connected')));
    }
  }

  List<String> splitText(String text, int width) {
    List<String> lines = [];
    while (text.length > width) {
      lines.add(text.substring(0, width));
      text = text.substring(width);
    }
    lines.add(text);
    return lines;
  }

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

  String _getAmountInWords(double amount) {
    int wholePart = amount.toInt();
    int decimalPart = ((amount - wholePart).abs() * 100).round();

    String wholePartWords =
        NumberToWord().convert('en-in', wholePart).toUpperCase();
    String amountInWords = "${AppState().code} $wholePartWords";

    if (decimalPart > 0) {
      String decimalPartWords =
          NumberToWord().convert('en-in', decimalPart).toUpperCase();
      amountInWords += " AND ${AppState().minor ?? 'FILS'} $decimalPartWords";
    }

    return "Amount in Words: $amountInWords ONLY";
  }
}
