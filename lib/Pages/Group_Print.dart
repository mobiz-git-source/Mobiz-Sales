import 'dart:convert';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'package:number_to_words/number_to_words.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/Group_Model.dart';
import '../Models/Group_Model.dart' as Invoice;
// import '../Models/invoicedata.dart' as Invoice;
// import '../confg/appconfig.dart';
import 'package:http/http.dart'as http;

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
      await printer.connect(_selectedDevice!);
      setState(() {
        _connected = true;
      });
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
    print(saleId);
    print(returnId);
    print(payId);
    print("${AppState().storeId}");

    final String url = 'http://68.183.92.8:3699/api/sale_return_collection_print?sales=${saleId}&return=${returnId}&collection=${payId}&store_id=${AppState().storeId}';
    print(url);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      print("Sale: $saleId");
      print("Return: $returnId");
      print("PAY: $payId");
      var jsonData = json.decode(response.body);
      SaleReturnCollection saleReturnData = SaleReturnCollection.fromJson(jsonData);

      if (response.body.isEmpty) {
        throw Exception('Empty response body');
      }

      Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data == null) {
        throw Exception('Data is null');
      }

      return SaleReturnCollection.fromJson(data);
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    super.initState();
    _initPrinter();
    futureData = fetchData(); // Initialize futureData here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)!.settings.arguments != null) {
        final Map<String, dynamic>? params =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        pricegroupId = params!['price_group_id'];
        saleId = params['saleId'];
        returnId = params['returnId'] ?? 0;
        payId = params['payId'];
        futureData = fetchData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sale Return Collection Print', style: TextStyle(color: Colors.white)),
        backgroundColor: AppConfig.colorPrimary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<SaleReturnCollection>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final saleReturnData = snapshot.data!;
            return Center(
              child: InkWell(
                onTap: () {
                  if (saleReturnData != null) {
                    _print(saleReturnData, true);
                  } else {
                    print("Sale return data is null");
                  }
                },
                child: Icon(
                  Icons.print,
                  size: 100,
                  color: AppConfig.colorPrimary,
                ),
              ),
            );
          }
          return Center(child: Text('No data available'));
        },
      ),
    );
  }
  void _print(Invoice.SaleReturnCollection invoice, bool isPrint) async {
    if (_connected) {
      // Company Information
      String companyName = invoice.sales!.store!.name ?? 'N/A';
      String companyAddress = invoice.sales!.store!.address ?? 'N/A';
      String companyMail = invoice.sales!.store!.email??'N/A';
      String companyTRN = "TRN: ${invoice.sales!.store!.trn ?? 'N/A'}";
      String billtype = "Tax Invoice";
      String customerName = "${invoice.sales!.customer!.name}";
      List<String> nameWords = customerName.split(' ');
      String firstLine = customerName;
      String secondLine = "";
      if (nameWords.length > 7) {
        firstLine = nameWords.sublist(0, 7).join(' ');
        secondLine = nameWords.sublist(7).join(' ');
      }
      String customerEmail = invoice.sales!.customer!.email ?? 'N/A';
      String customerContact =
          invoice.sales!.customer!.contactNumber ?? 'N/A';
      String customerTRN = invoice.sales!.customer!.trn ?? '';
      String invoiceNumber = invoice.returnData?.invoiceNo ?? 'N/A';
      String invoiceDate = invoice.returnData?.inDate != null
          ? DateFormat('dd MMMM yyyy').format(DateTime.parse(invoice.returnData!.inDate!))
          : 'N/A';

      // String dueDate = DateFormat('dd MMMM yyyy')
      //     .format(DateTime.parse(invoice.returnData!.inDate!));
      String ReturnTotal = invoice.returnData?.total?.toStringAsFixed(2) ?? '0.00';
      String SalesTotal = invoice.sales?.total?.toStringAsFixed(2) ?? '0.00';
      String tax = invoice.returnData?.totalTax?.toStringAsFixed(2) ?? '0.00';
      String vat = invoice.returnData?.totalTax?.toStringAsFixed(2) ?? '0.00';
      String ReturngrandTotal = invoice.returnData?.grandTotal?.toStringAsFixed(2) ?? '0.00';
      String SalesgrandTotal = invoice.sales?.grandTotal?.toStringAsFixed(2) ?? '0.00';

      String Discount;
      if (invoice.returnData != null && invoice.returnData!.discount != null &&
          double.tryParse(invoice.returnData!.discount!.toString()) != null &&
          double.parse(invoice.returnData!.discount!.toString()) > 0) {
        Discount = "Discount: ${double.parse(invoice.returnData!.discount!.toString()).toStringAsFixed(2)}";
      } else {
        Discount = '';
      }

      String ReturnamountInWords = "Amount in Words: AED ${NumberToWord().convert('en-in', invoice.returnData?.grandTotal?.toInt() ?? 0).toUpperCase()} ONLY";
      String SalesamountInWords = "Amount in Words: AED ${NumberToWord().convert('en-in', invoice.sales?.grandTotal?.toInt() ?? 0).toUpperCase()} ONLY";

      String van = invoice.sales?.van?.name ?? 'N/A';
      String Returnsalesman = invoice.returnData?.user?.name ?? 'N/A';
      String Salessalesman = invoice.sales?.user?.name ?? 'N/A';



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
          'https://erpadmin.mobiz.ae/uploads/store/${invoice.sales!.store!.logo}';
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
      // Print company details
      printer.printNewLine();
      printer.printCustom(companyName, 3, 1); // Centered
      printer.printCustom(companyAddress, 1, 1); // Centered
      printer.printCustom(companyMail, 1, 1);
      printer.printCustom(companyTRN, 1, 1); // Centered
      printer.printCustom(billtype, 1, 1); // Centered
      printer.printNewLine();

      printer.printCustom("-" * 72, 1, 1); // Centered
      printAlignedText("Invoice No: ${invoiceNumber}","Date: ${invoiceDate}");
      // printer.printCustom("Invoice No: ${invoiceNumber} | Date: ${invoiceDate}", 1, 1);
      printer.printNewLine();
      // Print customer details
      printAlignedText("Customer: $firstLine","");

      if (secondLine.isNotEmpty) {
        printAlignedText("         $secondLine", ""); // Aligns the second line under the first line
      }
      // printAlignedText("$cusAddress", " ");
      // printAlignedText("Email: $customerEmail", "");
      printAlignedText("Contact No: $customerContact", "");
      printAlignedText("TRN: $customerTRN", " ");
      printer.printNewLine();
      printAlignedText("Sales", " ");
      printer.printCustom("-" * 70, 1, 1); // Centered

      // Define column widths for table
      const int columnWidth1 = 5; // S.No
      const int columnWidth2 = 22; // Product Description
      const int columnWidth3 = 5; // Unit
      const int columnWidth4 = 4; // Qty
      const int columnWidth5 = 7; // Type
      const int columnWidth6 = 8; // Rate
      const int columnWidth7 = 8; // Total
      // const int columnWidth8 = 4; // Tax
      const int columnWidth9 = 6; // Amount

      // Print table headers
      String headers = "${'S.No'.padRight(columnWidth1)}"
          " ${'Product'.padRight(columnWidth2)}"
          " ${'Unit'.padRight(columnWidth3)}"
          "${'Qty'.padRight(columnWidth4)}"
          "${'Type'.padRight(columnWidth5)}"
          "${'Rate'.padRight(columnWidth6)}"
          "${'Amount'.padRight(columnWidth7)}"
      // "${'Vat'.padRight(columnWidth8)}"
          " ${'Total'.padLeft(columnWidth9)}";
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
      for (int i = 0; i < invoice.sales!.detail!.length; i++) {
        String productDescription = invoice.sales!.detail![i].name ?? 'N/A';
        String productUnit = invoice.sales!.detail![i].unit ?? 'N/A';
        String productQty = invoice.sales!.detail![i].quantity?.toString() ?? '0';
        String productType= invoice.sales!.detail![i].productType?.toString()??'0';
        String productRate = invoice.sales!.detail![i].mrp?.toStringAsFixed(2) ?? '0.00';
        String productTotal = invoice.sales!.detail![i].taxable?.toStringAsFixed(2) ?? '0.00';
        // String productTax = tax.toString();
        String productAmount =invoice.sales!.detail![i].amount?.toStringAsFixed(2)??'0.00';
        // (invoice.data!.detail![i].mrp! * invoice.data!.detail![i].quantity!)
        //     .toStringAsFixed(2);

        // Split the product description if it exceeds the column width
        List<String> descriptionLines =
        splitText(productDescription, columnWidth2);

        for (int j = 0; j < descriptionLines.length; j++) {
          String line;
          if (j == 0) {
            // For the first line, include all columns
            line = "${(i + 1).toString().padRight(columnWidth1)}"
                "${descriptionLines[j].padRight(columnWidth2)}"
                "  ${productUnit.padRight(columnWidth3)}"
                "${productQty.padRight(columnWidth4)}"
                "${productType.padRight(columnWidth5)}"
                "${productRate.padRight(columnWidth6)}"
                "${productTotal.padRight(columnWidth7)}"
            // "${productTax.padRight(columnWidth8)}"
                "${productAmount.padLeft(columnWidth9)}";
          } else {
            // For subsequent lines, only include the description, leaving other columns blank
            line = "${''.padRight(columnWidth1)}"
                "${descriptionLines[j].padRight(columnWidth2)}"
                "${''.padRight(columnWidth3)}"
                "${''.padRight(columnWidth4)}"
                "${''.padRight(columnWidth5)}"
                "${''.padRight(columnWidth6)}"
                "${''.padRight(columnWidth7)}";
            // "${''.padRight(columnWidth8)}";
            "${''.padRight(columnWidth9)}";
          }
          printer.printCustom(line, 1, 0); // Left aligned
        }
      }
      printer.printCustom("-" * 70, 1, 1); // Centered

      // Print totals
      // if (Discount.isNotEmpty) {
      //   print(Discount);
      //   printAlignedText("Van: $van", "$Discount");
      // } else {
      //   printAlignedText("Van: $van", ""); // Skip printing Total
      // }
      printAlignedText("Salesman: $Salessalesman", "Total: $SalesTotal");
      printer.printCustom("Vat: $vat", 1, 2);
      printer.printCustom("Grand Total: $SalesgrandTotal", 1, 2); // Right aligned
      printer.printNewLine();
      printer.printCustom(SalesamountInWords, 1, 0);
      printer.printNewLine();
      printer.printNewLine();

      printAlignedText("Return", " ");
      printer.printCustom("-" * 70, 1, 1); // Centered

      // Define column widths for table
      const int columnWidthh1 = 5; // S.No
      const int columnWidthh2 = 22; // Product Description
      const int columnWidthh3 = 5; // Unit
      const int columnWidthh4 = 4; // Qty
      const int columnWidthh5 = 7; // Type
      const int columnWidthh6 = 8; // Rate
      const int columnWidthh7 = 8; // Total
      // const int columnWidthh8 = 4; // Tax
      const int columnWidthh9 = 6; // Amount

      // Print table headers
      String headersh = "${'S.No'.padRight(columnWidthh1)}"
          " ${'Product'.padRight(columnWidthh2)}"
          " ${'Unit'.padRight(columnWidthh3)}"
          "${'Qty'.padRight(columnWidthh4)}"
          "${'Type'.padRight(columnWidthh5)}"
          "${'Rate'.padRight(columnWidthh6)}"
          "${'Amount'.padRight(columnWidthh7)}"
      // "${'Vat'.padRight(columnWidth8)}"
          " ${'Total'.padLeft(columnWidth9)}";
      printer.printCustom(headersh, 1, 0); // Left aligned

      // Function to split text into lines of a given width
      List<String> splitTexth(String text, int width) {
        List<String> lines = [];
        while (text.length > width) {
          lines.add(text.substring(0, width));
          text = text.substring(width);
        }
        lines.add(text); // Add remaining part
        return lines;
      }

      // Print all product details
      for (int i = 0; i < (invoice.returnData?.detail?.length ?? 0); i++) {
          String productDescription = invoice.returnData!.detail![i].name ?? 'N/A';
          String productUnit = invoice.returnData!.detail![i].unit ?? 'N/A';
          String productQty = invoice.returnData!.detail![i].quantity?.toString() ?? '0';
          String productType= invoice.returnData!.detail![i].productType?.toString()??'0';
          String productRate = invoice.returnData!.detail![i].mrp?.toStringAsFixed(2) ?? '0.00';
          String productTotal = invoice.returnData!.detail![i].taxable?.toStringAsFixed(2) ?? '0.00';
          String productTax = tax.toString();
          String productAmount =invoice.returnData!.detail![i].amount?.toStringAsFixed(2)??'0.00';
          // (invoice.data!.detail![i].mrp! * invoice.data!.detail![i].quantity!)
          //     .toStringAsFixed(2);

          // Split the product description if it exceeds the column width
          List<String> descriptionLines =
          splitTexth(productDescription, columnWidth2);

          for (int j = 0; j < descriptionLines.length; j++) {
            String line;
            if (j == 0) {
              // For the first line, include all columns
              line = "${(i + 1).toString().padRight(columnWidth1)}"
                  "${descriptionLines[j].padRight(columnWidth2)}"
                  "  ${productUnit.padRight(columnWidth3)}"
                  "${productQty.padRight(columnWidth4)}"
                  "${productType.padRight(columnWidth5)}"
                  "${productRate.padRight(columnWidth6)}"
                  "${productTotal.padRight(columnWidth7)}"
              // "${productTax.padRight(columnWidth8)}"
                  "${productAmount.padLeft(columnWidth9)}";
            } else {
              // For subsequent lines, only include the description, leaving other columns blank
              line = "${''.padRight(columnWidth1)}"
                  "${descriptionLines[j].padRight(columnWidth2)}"
                  "${''.padRight(columnWidth3)}"
                  "${''.padRight(columnWidth4)}"
                  "${''.padRight(columnWidth5)}"
                  "${''.padRight(columnWidth6)}"
                  "${''.padRight(columnWidth7)}";
              // "${''.padRight(columnWidth8)}";
              "${''.padRight(columnWidth9)}";
            }
            printer.printCustom(line, 1, 0); // Left aligned
          }
        }
        printer.printCustom("-" * 70, 1, 1); // Centered

      // Print totals
      if (Discount.isNotEmpty) {
        print(Discount);
        printAlignedText("Van: $van", "$Discount");
      } else {
        printAlignedText("Van: $van", ""); // Skip printing Total
      }
      printAlignedText("Salesman: $Returnsalesman", "Total: $ReturnTotal");
      printer.printCustom("Vat: $tax", 1, 2);
      printer.printCustom("Grand Total: $ReturngrandTotal", 1, 2); // Right aligned
      printer.printNewLine();
      printer.printCustom(ReturnamountInWords, 1, 0);

      printer.printNewLine();
      printer.printNewLine();
      printAlignedText("Collection", " ");
      printer.printCustom("-" * 72, 1, 1); // Centered

      // Print Sales Details
      // printer.printLeftRight(
      //     'Reference:', '${data.sales![0].voucherNo ?? 'N/A'}', 1);
      // printer.printLeftRight('Date:', '${data.sales![0].inDate}', 1);
      // printer.printLeftRight('Due Date:', '${data.sales![0].inDate}', 1);
      // printer.printNewLine();

      // Collection Information
      if (invoice.collection != null) {
        // Only print the totalAmount if it is not null
        if (invoice.collection!.totalAmount != null) {
          printAlignedText('Amount: ${invoice.collection!.totalAmount}', ' ');
        } else {
          printAlignedText('Amount: Not available', ' ');
        }

        if (invoice.collection!.collectionType == 'Cheque') {
          printAlignedText('Collection Type: Cheque', ' ');
          printAlignedText('Bank Name: ${invoice.collection!.bank}', ' ');
          printAlignedText('Cheque No: ${invoice.collection!.chequeNo}', ' ');
          printAlignedText('Cheque Date: ${invoice.collection!.chequeDate}', ' ');
        } else if (invoice.collection!.collectionType == 'Cash') {
          printAlignedText('Collection Type: Cash', ' '); // Optional
        }
      } else {
        // Handle the case where collection is null
        printAlignedText('No collection data available', ' ');
      }

      // printer.printLeftRight('Collection Type:', '${data.collectionType}', 1);
      // printer.printLeftRight('Bank Name:', '${data.bank}', 1);
      // printer.printLeftRight('Cheque No:', '${data.chequeNo}', 1);
      // printer.printLeftRight('Cheque Date:', '${data.chequeDate}', 1);
      // printer.printLeftRight('Amount:', '${data.totalAmount}', 1);
      printer.printNewLine();
      printer.printCustom("-" * 72, 1, 1);
      const int columnWidthc0 = 4;
      const int columnWidthc1 = 14; // S.No
      const int columnWidthc2 = 20; // Product Description
      const int columnWidthc3 = 14; // Unit
      const int columnWidthc4 = 5;
      String line;
      String headersc = "${''.padRight(columnWidthc0)}"
          "${'SI.NO'.padRight(columnWidthc1)}"
          " ${'Reference NO'.padRight(columnWidthc2)}"
          " ${'Type'.padRight(columnWidthc3)}"
          "${'Amount'.padRight(columnWidthc4)}";
      printer.printCustom(headersc, 1, 0);
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

      if (invoice.collection?.sales != null && invoice.collection!.sales!.isNotEmpty) {
        for (var i = 0; i < invoice.collection!.sales!.length; i++) {
          var sale = invoice.collection!.sales![i];
          line = "${('').padRight(columnWidthc0)}"
              "${(i + 1).toString().padRight(columnWidthc1)}"
              " ${sale.invoiceNo?.padRight(columnWidthc2) ?? 'N/A'.padRight(columnWidthc2)}"
              "${formatInvoiceType(sale.invoiceType)?.padRight(columnWidthc3) ?? 'N/A'.padRight(columnWidthc3)}"
              "${sale.amount?.padRight(columnWidthc4) ?? 'N/A'.padRight(columnWidthc4)}";
          printer.printCustom(line, 1, 0);
        }
      } else {
        printAlignedText('No sales data available', ' ');
      }

      printer.printNewLine();
      printer.printCustom("-" * 72, 1, 1);
      if (invoice.collection!.roundOff != null && double.parse(invoice.collection!.roundOff!) != 0) {
        printAlignedText('',
            'Round Off: ${double.parse(invoice.collection!.roundOff!).toStringAsFixed(2)}');
      }
      printAlignedText('', 'Total: ${invoice.collection!.totalAmount}');
      printAlignedText("Van: ${invoice.collection!.van![0].name}", "");
      printAlignedText("Salesman: ${invoice.collection!.user![0].name}", "");
      printer.printNewLine();

      // Cut the paper
      printer.paperCut();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printer not connected')),
      );
    }
    if (!_connected) {
      await _connect();
    }
  }
}

