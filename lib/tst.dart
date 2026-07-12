// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';
// import 'package:image/image.dart' as img;
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:mobizapp/Models/appstate.dart';
// import 'package:mobizapp/confg/appconfig.dart';
// import 'package:number_to_words/number_to_words.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../Models/Group_Model.dart';
// import '../Models/Group_Model.dart' as Invoice;
// // import '../Models/invoicedata.dart' as Invoice;
// // import '../confg/appconfig.dart';
// import 'package:http/http.dart'as http;
//
// class GroupPrint extends StatefulWidget {
//   static const routeName = "/GroupPrint";
//   const GroupPrint({super.key});
//
//   @override
//   State<GroupPrint> createState() => _GroupPrintState();
// }
//
// class _GroupPrintState extends State<GroupPrint> {
//   int? pricegroupId;
//   int? saleId;
//   int? returnId;
//   int? payId;
//   BlueThermalPrinter printer = BlueThermalPrinter.instance;
//   bool _connected = false;
//   BluetoothDevice? _selectedDevice;
//   List<BluetoothDevice> _devices = [];
//   // BlueThermalPrinter printer = BlueThermalPrinter.instance;
//   // bool _connected = false;
//   late Future<SaleReturnCollection> futureData;
//
//   void _getBluetoothDevices() async {
//     List<BluetoothDevice> devices = await printer.getBondedDevices();
//     BluetoothDevice? defaultDevice;
//     final prefs = await SharedPreferences.getInstance();
//     final savedDeviceAddress = prefs.getString('selected_device_address');
//     for (BluetoothDevice device in devices) {
//       if (device.address == savedDeviceAddress) {
//         defaultDevice = device;
//         break;
//       }
//     }
//     setState(() {
//       _devices = devices;
//       _selectedDevice = defaultDevice;
//     });
//   }
//
//   Future<void> _connect() async {
//     if (_selectedDevice != null) {
//       await printer.connect(_selectedDevice!);
//       setState(() {
//         _connected = true;
//       });
//     }
//   }
//
//   // void initState() {
//   //   super.initState();
//   //   fetchData();
//   //   _initPrinter();
//   // }
//
//
//   void _initPrinter() async {
//     bool? isConnected = await printer.isConnected;
//     if (isConnected!) {
//       setState(() {
//         _connected = true;
//       });
//     }
//     _getBluetoothDevices();
//   }
//
//   Future<SaleReturnCollection> fetchData() async {
//     print(saleId);
//     print(returnId);
//     print(payId);
//     print("${AppState().storeId}");
//
//
//     final String url = 'http://68.183.92.8:3699/api/sale_return_collection_print?sales=${saleId}&return=${returnId}&collection=${payId}&store_id=${AppState().storeId}';
//     print(url);
//     final response = await http.get(Uri.parse(url));
//     // final response = await http.get(Uri.parse('http://68.183.92.8:3699/api/sale_return_collection_print?sales=1508&return=391&collection=253&store_id=10'));
//     if (response.statusCode == 200) {
//       print("Sale: $saleId");
//       print("Return: $returnId");
//       print("PAY: $payId");
//       var jsonData = json.decode(response.body);
//       SaleReturnCollection saleReturnData = SaleReturnCollection.fromJson(jsonData);
//
//       // Check if the response body is null or empty
//       if (response.body.isEmpty) {
//         throw Exception('Empty response body');
//       }
//
//       Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
//
//       if (data == null) {
//         throw Exception('Data is null');
//       }
//
//       return SaleReturnCollection.fromJson(data);
//     } else {
//       throw Exception('Failed to load data');
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     // futureData = fetchData();
//     _initPrinter();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // Check if arguments are passed via the ModalRoute and extract them
//       if (ModalRoute.of(context)!.settings.arguments != null) {
//         final Map<String, dynamic>? params =
//         ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
//         pricegroupId = params!['price_group_id'];
//         saleId = params['saleId'];
//         returnId = params['returnId'] ?? 0;
//         payId = params['payId'];
//       }
//       futureData = fetchData();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(title: Text('Sale Return Collection Print',style: TextStyle(color: Colors.white),), backgroundColor: AppConfig.colorPrimary,iconTheme: IconThemeData(color: Colors.white),),
//         body: FutureBuilder<SaleReturnCollection>(
//           future: futureData,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return Center(child: CircularProgressIndicator());
//             } else if (snapshot.hasError) {
//               print(snapshot.error);
//               return Center(child: Text('Error: ${snapshot.error}'));
//             } else if (snapshot.hasData) {
//               final saleReturnData = snapshot.data!;
//               return Center(
//                 child: InkWell(
//                     onTap: () => _print(saleReturnData, true),
//                     child: Icon(Icons.print,size: 100,color: AppConfig.colorPrimary,)),
//               );
//             }
//             return Center(child: Text('No data available'));
//           },
//         )
//
//     );
//   }
//   void _print(Invoice.SaleReturnCollection invoice, bool isPrint) async {
//     if (_connected) {
//       // Company Information
//       String companyName = invoice.sales!.store!.name ?? 'N/A';
//       String companyAddress = invoice.sales!.store!.address ?? 'N/A';
//       String companyMail = invoice.sales!.store!.email??'N/A';
//       String companyTRN = "TRN: ${invoice.sales!.store!.trn ?? 'N/A'}";
//       String billtype = "Tax Invoice";
//       String customerName = "${invoice.sales!.customer!.name}";
//       List<String> nameWords = customerName.split(' ');
//       String firstLine = customerName;
//       String secondLine = "";
//       if (nameWords.length > 7) {
//         firstLine = nameWords.sublist(0, 7).join(' ');
//         secondLine = nameWords.sublist(7).join(' ');
//       }
//       String customerEmail = invoice.sales!.customer!.email ?? 'N/A';
//       String customerContact =
//           invoice.sales!.customer!.contactNumber ?? 'N/A';
//       String customerTRN = invoice.sales!.customer!.trn ?? '';
//       String invoiceNumber = invoice.returnData!.invoiceNo ?? 'N/A';
//       String invoiceDate = DateFormat('dd MMMM yyyy')
//           .format(DateTime.parse(invoice.returnData!.inDate!));
//       String dueDate = DateFormat('dd MMMM yyyy')
//           .format(DateTime.parse(invoice.returnData!.inDate!));
//       String ReturnTotal = invoice.returnData!.total?.toStringAsFixed(AppState().noOfDecimals ?? 2)??'0.00';
//       String SalesTotal = invoice.sales!.total?.toStringAsFixed(AppState().noOfDecimals ?? 2)??'0.00';
//       String tax = invoice.returnData!.totalTax?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//       String vat = invoice.returnData!.totalTax?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//       String ReturngrandTotal = invoice.returnData!.grandTotal?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//       String SalesgrandTotal = invoice.sales!.grandTotal?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//       String Discount;
//       if (invoice.returnData!=null &&invoice.returnData!.discount != null &&
//           double.tryParse(invoice.returnData!.discount!.toString()) != null &&
//           double.parse(invoice.returnData!.discount!.toString()) > 0) {
//         Discount = "Discount: ${double.parse(invoice.returnData!.discount!.toString()).toStringAsFixed(AppState().noOfDecimals ?? 2)}";
//       } else {
//         Discount = '';
//       }
//       String ReturnamountInWords = "Amount in Words: AED ${NumberToWord().convert('en-in', invoice.returnData!.grandTotal?.toInt() ?? 0).toUpperCase()} ONLY";
//       String SalesamountInWords = "Amount in Words: AED ${NumberToWord().convert('en-in', invoice.sales!.grandTotal?.toInt() ?? 0).toUpperCase()} ONLY";
//       String van = invoice.returnData!.van!.name ?? 'N/A';
//       String Returnsalesman = invoice.returnData!.user!.name ?? 'N/A';
//       String Salessalesman = invoice.returnData!.user!.name ?? 'N/A';
//
//
//       void printAlignedText(String leftText, String rightText) {
//         const int maxLineLength =
//         68; // Adjust the maximum line length as per your printer's character limit
//         int leftTextLength = leftText.length;
//         int rightTextLength = rightText.length;
//
//         // Calculate padding to ensure rightText is right-aligned
//         int spaceLength = maxLineLength - (leftTextLength + rightTextLength);
//         String spaces = ' ' * spaceLength;
//
//         printer.printCustom(
//             '$leftText$spaces$rightText', 1, 0); // Print with left-aligned text
//       }
//
//       String logoUrl =
//           'http://68.183.92.8:3697/uploads/store/${invoice.sales!.store!.logo}';
//       if (logoUrl.isNotEmpty) {
//         final response = await http.get(Uri.parse(logoUrl));
//         if (response.statusCode == 200) {
//           Uint8List imageBytes = response.bodyBytes;
//
//           // Decode image and convert to monochrome bitmap if needed
//           img.Image originalImage = img.decodeImage(imageBytes)!;
//           img.Image monoLogo = img.grayscale(originalImage);
//
//           // Encode the image to the required format (e.g., PNG)
//           Uint8List logoBytes = Uint8List.fromList(img.encodePng(monoLogo));
//
//           // Print the logo image
//           printer.printImageBytes(logoBytes);
//         } else {
//           print('Failed to load image: ${response.statusCode}');
//         }
//       }
//       // Print company details
//       printer.printNewLine();
//       printer.printCustom(companyName, 3, 1); // Centered
//       printer.printCustom(companyAddress, 1, 1); // Centered
//       printer.printCustom(companyMail, 1, 1);
//       printer.printCustom(companyTRN, 1, 1); // Centered
//       printer.printCustom(billtype, 1, 1); // Centered
//       printer.printNewLine();
//
//       printer.printCustom("-" * 72, 1, 1); // Centered
//       printAlignedText("Invoice No: ${invoiceNumber}","Date: ${invoiceDate}");
//       // printer.printCustom("Invoice No: ${invoiceNumber} | Date: ${invoiceDate}", 1, 1);
//       printer.printNewLine();
//       // Print customer details
//       printAlignedText("Customer: $firstLine","");
//
//       if (secondLine.isNotEmpty) {
//         printAlignedText("         $secondLine", ""); // Aligns the second line under the first line
//       }
//       // printAlignedText("$cusAddress", " ");
//       // printAlignedText("Email: $customerEmail", "");
//       printAlignedText("Contact No: $customerContact", "");
//       printAlignedText("TRN: $customerTRN", " ");
//       printer.printNewLine();
//       printAlignedText("Sales", " ");
//       printer.printCustom("-" * 70, 1, 1); // Centered
//
//       // Define column widths for table
//       const int columnWidth1 = 5; // S.No
//       const int columnWidth2 = 22; // Product Description
//       const int columnWidth3 = 5; // Unit
//       const int columnWidth4 = 4; // Qty
//       const int columnWidth5 = 7; // Type
//       const int columnWidth6 = 8; // Rate
//       const int columnWidth7 = 8; // Total
//       // const int columnWidth8 = 4; // Tax
//       const int columnWidth9 = 6; // Amount
//
//       // Print table headers
//       String headers = "${'S.No'.padRight(columnWidth1)}"
//           " ${'Product'.padRight(columnWidth2)}"
//           " ${'Unit'.padRight(columnWidth3)}"
//           "${'Qty'.padRight(columnWidth4)}"
//           "${'Type'.padRight(columnWidth5)}"
//           "${'Rate'.padRight(columnWidth6)}"
//           "${'Amount'.padRight(columnWidth7)}"
//       // "${'Vat'.padRight(columnWidth8)}"
//           " ${'Total'.padLeft(columnWidth9)}";
//       printer.printCustom(headers, 1, 0); // Left aligned
//
//       // Function to split text into lines of a given width
//       List<String> splitText(String text, int width) {
//         List<String> lines = [];
//         while (text.length > width) {
//           lines.add(text.substring(0, width));
//           text = text.substring(width);
//         }
//         lines.add(text); // Add remaining part
//         return lines;
//       }
//
//       // Print all product details
//       for (int i = 0; i < invoice.sales!.detail!.length; i++) {
//         String productDescription = invoice.sales!.detail![i].name ?? 'N/A';
//         String productUnit = invoice.sales!.detail![i].unit ?? 'N/A';
//         String productQty = invoice.sales!.detail![i].quantity?.toString() ?? '0';
//         String productType= invoice.sales!.detail![i].productType?.toString()??'0';
//         String productRate = invoice.sales!.detail![i].mrp?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//         String productTotal = invoice.sales!.detail![i].taxable?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//         // String productTax = tax.toString();
//         String productAmount =invoice.sales!.detail![i].amount?.toStringAsFixed(AppState().noOfDecimals ?? 2)??'0.00';
//         // (invoice.data!.detail![i].mrp! * invoice.data!.detail![i].quantity!)
//         //     .toStringAsFixed(AppState().noOfDecimals ?? 2);
//
//         // Split the product description if it exceeds the column width
//         List<String> descriptionLines =
//         splitText(productDescription, columnWidth2);
//
//         for (int j = 0; j < descriptionLines.length; j++) {
//           String line;
//           if (j == 0) {
//             // For the first line, include all columns
//             line = "${(i + 1).toString().padRight(columnWidth1)}"
//                 "${descriptionLines[j].padRight(columnWidth2)}"
//                 "  ${productUnit.padRight(columnWidth3)}"
//                 "${productQty.padRight(columnWidth4)}"
//                 "${productType.padRight(columnWidth5)}"
//                 "${productRate.padRight(columnWidth6)}"
//                 "${productTotal.padRight(columnWidth7)}"
//             // "${productTax.padRight(columnWidth8)}"
//                 "${productAmount.padLeft(columnWidth9)}";
//           } else {
//             // For subsequent lines, only include the description, leaving other columns blank
//             line = "${''.padRight(columnWidth1)}"
//                 "${descriptionLines[j].padRight(columnWidth2)}"
//                 "${''.padRight(columnWidth3)}"
//                 "${''.padRight(columnWidth4)}"
//                 "${''.padRight(columnWidth5)}"
//                 "${''.padRight(columnWidth6)}"
//                 "${''.padRight(columnWidth7)}";
//             // "${''.padRight(columnWidth8)}";
//             "${''.padRight(columnWidth9)}";
//           }
//           printer.printCustom(line, 1, 0); // Left aligned
//         }
//       }
//       printer.printCustom("-" * 70, 1, 1); // Centered
//
//       // Print totals
//       // if (Discount.isNotEmpty) {
//       //   print(Discount);
//       //   printAlignedText("Van: $van", "$Discount");
//       // } else {
//       //   printAlignedText("Van: $van", ""); // Skip printing Total
//       // }
//       printAlignedText("Salesman: $Salessalesman", "Total: $SalesTotal");
//       printer.printCustom("Vat: $vat", 1, 2);
//       printer.printCustom("Grand Total: $SalesgrandTotal", 1, 2); // Right aligned
//       printer.printNewLine();
//       printer.printCustom(SalesamountInWords, 1, 0);
//       printer.printNewLine();
//       printer.printNewLine();
//
//       printAlignedText("Return", " ");
//       printer.printCustom("-" * 70, 1, 1); // Centered
//
//       // Define column widths for table
//       const int columnWidthh1 = 5; // S.No
//       const int columnWidthh2 = 22; // Product Description
//       const int columnWidthh3 = 5; // Unit
//       const int columnWidthh4 = 4; // Qty
//       const int columnWidthh5 = 7; // Type
//       const int columnWidthh6 = 8; // Rate
//       const int columnWidthh7 = 8; // Total
//       // const int columnWidthh8 = 4; // Tax
//       const int columnWidthh9 = 6; // Amount
//
//       // Print table headers
//       String headersh = "${'S.No'.padRight(columnWidthh1)}"
//           " ${'Product'.padRight(columnWidthh2)}"
//           " ${'Unit'.padRight(columnWidthh3)}"
//           "${'Qty'.padRight(columnWidthh4)}"
//           "${'Type'.padRight(columnWidthh5)}"
//           "${'Rate'.padRight(columnWidthh6)}"
//           "${'Amount'.padRight(columnWidthh7)}"
//       // "${'Vat'.padRight(columnWidth8)}"
//           " ${'Total'.padLeft(columnWidth9)}";
//       printer.printCustom(headersh, 1, 0); // Left aligned
//
//       // Function to split text into lines of a given width
//       List<String> splitTexth(String text, int width) {
//         List<String> lines = [];
//         while (text.length > width) {
//           lines.add(text.substring(0, width));
//           text = text.substring(width);
//         }
//         lines.add(text); // Add remaining part
//         return lines;
//       }
//
//       // Print all product details
//       for (int i = 0; i < invoice.returnData!.detail!.length; i++) {
//         String productDescription = invoice.returnData!.detail![i].name ?? 'N/A';
//         String productUnit = invoice.returnData!.detail![i].unit ?? 'N/A';
//         String productQty = invoice.returnData!.detail![i].quantity?.toString() ?? '0';
//         String productType= invoice.returnData!.detail![i].productType?.toString()??'0';
//         String productRate = invoice.returnData!.detail![i].mrp?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//         String productTotal = invoice.returnData!.detail![i].taxable?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//         String productTax = tax.toString();
//         String productAmount =invoice.returnData!.detail![i].amount?.toStringAsFixed(AppState().noOfDecimals ?? 2)??'0.00';
//         // (invoice.data!.detail![i].mrp! * invoice.data!.detail![i].quantity!)
//         //     .toStringAsFixed(AppState().noOfDecimals ?? 2);
//
//         // Split the product description if it exceeds the column width
//         List<String> descriptionLines =
//         splitTexth(productDescription, columnWidth2);
//
//         for (int j = 0; j < descriptionLines.length; j++) {
//           String line;
//           if (j == 0) {
//             // For the first line, include all columns
//             line = "${(i + 1).toString().padRight(columnWidth1)}"
//                 "${descriptionLines[j].padRight(columnWidth2)}"
//                 "  ${productUnit.padRight(columnWidth3)}"
//                 "${productQty.padRight(columnWidth4)}"
//                 "${productType.padRight(columnWidth5)}"
//                 "${productRate.padRight(columnWidth6)}"
//                 "${productTotal.padRight(columnWidth7)}"
//             // "${productTax.padRight(columnWidth8)}"
//                 "${productAmount.padLeft(columnWidth9)}";
//           } else {
//             // For subsequent lines, only include the description, leaving other columns blank
//             line = "${''.padRight(columnWidth1)}"
//                 "${descriptionLines[j].padRight(columnWidth2)}"
//                 "${''.padRight(columnWidth3)}"
//                 "${''.padRight(columnWidth4)}"
//                 "${''.padRight(columnWidth5)}"
//                 "${''.padRight(columnWidth6)}"
//                 "${''.padRight(columnWidth7)}";
//             // "${''.padRight(columnWidth8)}";
//             "${''.padRight(columnWidth9)}";
//           }
//           printer.printCustom(line, 1, 0); // Left aligned
//         }
//       }
//       printer.printCustom("-" * 70, 1, 1); // Centered
//
//       // Print totals
//       if (Discount.isNotEmpty) {
//         print(Discount);
//         printAlignedText("Van: $van", "$Discount");
//       } else {
//         printAlignedText("Van: $van", ""); // Skip printing Total
//       }
//       printAlignedText("Salesman: $Returnsalesman", "Total: $ReturnTotal");
//       printer.printCustom("Vat: $tax", 1, 2);
//       printer.printCustom("Grand Total: $ReturngrandTotal", 1, 2); // Right aligned
//       printer.printNewLine();
//       printer.printCustom(ReturnamountInWords, 1, 0);
//
//       printer.printNewLine();
//       printer.printNewLine();
//       printAlignedText("Collection", " ");
//       printer.printCustom("-" * 72, 1, 1); // Centered
//
//       // Print Sales Details
//       // printer.printLeftRight(
//       //     'Reference:', '${data.sales![0].voucherNo ?? 'N/A'}', 1);
//       // printer.printLeftRight('Date:', '${data.sales![0].inDate}', 1);
//       // printer.printLeftRight('Due Date:', '${data.sales![0].inDate}', 1);
//       // printer.printNewLine();
//
//       // Collection Information
//       if (invoice.collection != null) {
//         // Only print the totalAmount if it is not null
//         if (invoice.collection!.totalAmount != null) {
//           printAlignedText('Amount: ${invoice.collection!.totalAmount}', ' ');
//         } else {
//           printAlignedText('Amount: Not available', ' ');
//         }
//
//         if (invoice.collection!.collectionType == 'Cheque') {
//           printAlignedText('Collection Type: Cheque', ' ');
//           printAlignedText('Bank Name: ${invoice.collection!.bank}', ' ');
//           printAlignedText('Cheque No: ${invoice.collection!.chequeNo}', ' ');
//           printAlignedText('Cheque Date: ${invoice.collection!.chequeDate}', ' ');
//         } else if (invoice.collection!.collectionType == 'Cash') {
//           printAlignedText('Collection Type: Cash', ' '); // Optional
//         }
//       } else {
//         // Handle the case where collection is null
//         printAlignedText('No collection data available', ' ');
//       }
//
//       // printer.printLeftRight('Collection Type:', '${data.collectionType}', 1);
//       // printer.printLeftRight('Bank Name:', '${data.bank}', 1);
//       // printer.printLeftRight('Cheque No:', '${data.chequeNo}', 1);
//       // printer.printLeftRight('Cheque Date:', '${data.chequeDate}', 1);
//       // printer.printLeftRight('Amount:', '${data.totalAmount}', 1);
//       printer.printNewLine();
//       printer.printCustom("-" * 72, 1, 1);
//       const int columnWidthc0 = 4;
//       const int columnWidthc1 = 14; // S.No
//       const int columnWidthc2 = 20; // Product Description
//       const int columnWidthc3 = 14; // Unit
//       const int columnWidthc4 = 5;
//       String line;
//       String headersc = "${''.padRight(columnWidthc0)}"
//           "${'SI.NO'.padRight(columnWidthc1)}"
//           " ${'Reference NO'.padRight(columnWidthc2)}"
//           " ${'Type'.padRight(columnWidthc3)}"
//           "${'Amount'.padRight(columnWidthc4)}";
//       printer.printCustom(headersc, 1, 0);
//       printer.printCustom("-" * 72, 1, 1);
//       // Sales List Header
//       // printer.printCustom('SI NO   Reference No   Type   Amount', 1, 0);
//       // printer.printCustom('---------------------------', 1, 0);
//
//       // Iterate and print each sales item
//
//       String formatInvoiceType(String? invoiceType) {
//         if (invoiceType == null)
//           return 'N/A'; // Return N/A if invoiceType is null
//
//         // Capitalize the first letter and check for specific cases
//         switch (invoiceType.toLowerCase()) {
//           case 'salesreturn':
//             return 'Sales Return';
//           case 'payment_voucher':
//             return 'Payment';
//           default:
//             return invoiceType[0].toUpperCase() +
//                 invoiceType.substring(1).toLowerCase();
//         }
//       }
//
//       for (var i = 0; i < invoice.collection!.sales!.length; i++) {
//         var sale = invoice.collection!.sales![i];
//         line = "${('').padRight(columnWidthc0)}"
//             "${(i + 1).toString().padRight(columnWidthc1)}"
//             " ${sale.invoiceNo?.padRight(columnWidthc2) ?? 'N/A'.padRight(columnWidthc2)}"
//             "${formatInvoiceType(sale.invoiceType)?.padRight(columnWidthc3) ?? 'N/A'.padRight(columnWidthc3)}"
//             "${sale.amount?.padRight(columnWidthc4) ?? 'N/A'.padRight(columnWidthc4)}";
//         printer.printCustom(line, 1, 0);
//       }
//       printer.printNewLine();
//       printer.printCustom("-" * 72, 1, 1);
//       if (invoice.collection!.roundOff != null && double.parse(invoice.collection!.roundOff!) != 0) {
//         printAlignedText('',
//             'Round Off: ${double.parse(invoice.collection!.roundOff!).toStringAsFixed(AppState().noOfDecimals ?? 2)}');
//       }
//       printAlignedText('', 'Total: ${invoice.collection!.totalAmount}');
//       printAlignedText("Van: ${invoice.collection!.van![0].name}", "");
//       printAlignedText("Salesman: ${invoice.collection!.user![0].name}", "");
//       // printer.printLeftRight('Van:', '${data.vanId}', 1);
//       // printer.printLeftRight('Salesman:', 'N/A', 1);
//       printer.printNewLine();
//
//       // Cut the paper
//       printer.paperCut();
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Printer not connected')),
//       );
//     }
//     if (!_connected) {
//       await _connect();
//     }
//   }
// }
//



// class VanSaleProducts {
//   List<Data>? data;
//   bool? success;
//
//   VanSaleProducts({this.data, this.success});
//
//   VanSaleProducts.fromJson(Map<String, dynamic> json) {
//     if (json['data'] != null) {
//       data = <Data>[];
//       json['data'].forEach((v) {
//         data!.add(new Data.fromJson(v));
//       });
//     }
//     success = json['success'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.data != null) {
//       data['data'] = this.data!.map((v) => v.toJson()).toList();
//     }
//     data['success'] = this.success;
//     return data;
//   }
// }
//
// class Data {
//   int? id;
//   int? customerId;
//   String? billMode;
//   String? inDate;
//   String? inTime;
//   String? invoiceNo;
//   String? deliveryNo;
//   num? otherCharge;
//   num? discount;
//   String? roundOff;
//   String? discount_type;
//   num? total;
//   num? totalTax;
//   num? grandTotal;
//   num? receipt;
//   num? balance;
//   num? orderType;
//   num? ifVat;
//   num? vanId;
//   num? userId;
//   num? storeId;
//   int? status;
//   String? createdAt;
//   String? updatedAt;
//   String? deletedAt;
//   List<Detail>? detail;
//   List<Customer>? customer;
//
//   Data(
//       {this.id,
//         this.customerId,
//         this.billMode,
//         this.inDate,
//         this.inTime,
//         this.invoiceNo,
//         this.discount_type,
//         this.deliveryNo,
//         this.otherCharge,
//         this.discount,
//         this.roundOff,
//         this.total,
//         this.totalTax,
//         this.grandTotal,
//         this.receipt,
//         this.balance,
//         this.orderType,
//         this.ifVat,
//         this.vanId,
//         this.userId,
//         this.storeId,
//         this.status,
//         this.createdAt,
//         this.updatedAt,
//         this.deletedAt,
//         this.detail,
//         this.customer});
//
//   Data.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     customerId = json['customer_id'];
//     billMode = json['bill_mode'] ?? '';
//     inDate = json['in_date'] ?? '';
//     inTime = json['in_time'] ?? '';
//     invoiceNo = json['invoice_no'] ?? '';
//     deliveryNo = json['delivery_no'] ?? '';
//     otherCharge = json['other_charge'] ?? 0;
//     discount = json['discount'] ?? 0;
//     discount_type = json['discount_type'] ?? '';
//     roundOff = json['round_off'] ?? '';
//     total = json['total'] ?? 0;
//     totalTax = json['total_tax'] ?? 0;
//     grandTotal = json['grand_total'] ?? 0;
//     receipt = json['receipt'] ?? 0;
//     balance = json['balance'] ?? 0;
//     orderType = json['order_type'] ?? 0;
//     ifVat = json['if_vat'] ?? 0;
//     vanId = json['van_id'] ?? 0;
//     userId = json['user_id'] ?? 0;
//     storeId = json['store_id'] ?? 0;
//     status = json['status'] ?? 0;
//     createdAt = json['created_at'] ?? '';
//     updatedAt = json['updated_at'] ?? '';
//     deletedAt = json['deleted_at'] ?? '';
//
//     if (json['detail'] != null) {
//       detail = <Detail>[];
//       json['detail'].forEach((v) {
//         detail!.add(Detail.fromJson(v));
//       });
//     }
//
//     if (json['customer'] != null) {
//       customer = <Customer>[];
//       json['customer'].forEach((v) {
//         customer!.add(Customer.fromJson(v));
//       });
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['customer_id'] = this.customerId;
//     data['bill_mode'] = this.billMode;
//     data['in_date'] = this.inDate;
//     data['in_time'] = this.inTime;
//     data['invoice_no'] = this.invoiceNo;
//     data['delivery_no'] = this.deliveryNo;
//     data['other_charge'] = this.otherCharge;
//     data['discount'] = this.discount;
//     data['round_off'] = this.roundOff;
//     data['total'] = this.total;
//     data['total_tax'] = this.totalTax;
//     data['grand_total'] = this.grandTotal;
//     data['receipt'] = this.receipt;
//     data['balance'] = this.balance;
//     data['order_type'] = this.orderType;
//     data['if_vat'] = this.ifVat;
//     data['van_id'] = this.vanId;
//     data['user_id'] = this.userId;
//     data['store_id'] = this.storeId;
//     data['status'] = this.status;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     data['deleted_at'] = this.deletedAt;
//     if (this.detail != null) {
//       data['detail'] = this.detail!.map((v) => v.toJson()).toList();
//     }
//     if (this.customer != null) {
//       data['customer'] = this.customer!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }
//
// class Detail {
//   int? id;
//   int? goodsOutId;
//   int? itemId;
//   String? productType;
//   String? unit;
//   num? convertQty;
//   num? quantity;
//   num? rate;
//   num? prodiscount;
//   num? taxable;
//   num? taxAmt;
//   num? mrp;
//   num? amount;
//   int? vanId;
//   int? userId;
//   int? storeId;
//   int? status;
//   String? createdAt;
//   String? updatedAt;
//   String? deletedAt;
//   String? code;
//   String? name;
//   String? proImage;
//   int? categoryId;
//   int? subCategoryId;
//   int? brandId;
//   int? supplierId;
//   int? taxId;
//   num? taxPercentage;
//   num? taxInclusive;
//   num? price;
//   int? baseUnitId;
//   int? baseUnitQty;
//   String? baseUnitDiscount;
//   String? baseUnitBarcode;
//   num? baseUnitOpStock;
//   String? secondUnitPrice;
//   int? secondUnitId;
//   int? secondUnitQty;
//   String? secondUnitDiscount;
//   String? secondUnitBarcode;
//   String? secondUnitOpStock;
//   String? thirdUnitPrice;
//   int? thirdUnitId;
//   int? thirdUnitQty;
//   String? thirdUnitDiscount;
//   String? thirdUnitBarcode;
//   String? thirdUnitOpStock;
//   String? fourthUnitPrice;
//   int? fourthUnitId;
//   int? fourthUnitQty;
//   String? fourthUnitDiscount;
//   int? isMultipleUnit;
//   String? fourthUnitOpStock;
//   String? description;
//   num? productQty;
//   num? percentage;
//
//   Detail(
//       {this.id,
//         this.goodsOutId,
//         this.itemId,
//         this.productType,
//         this.unit,
//         this.convertQty,
//         this.quantity,
//         this.rate,
//         this.prodiscount,
//         this.taxable,
//         this.taxAmt,
//         this.mrp,
//         this.amount,
//         this.vanId,
//         this.userId,
//         this.storeId,
//         this.status,
//         this.createdAt,
//         this.updatedAt,
//         this.deletedAt,
//         this.code,
//         this.name,
//         this.proImage,
//         this.categoryId,
//         this.subCategoryId,
//         this.brandId,
//         this.supplierId,
//         this.taxId,
//         this.taxPercentage,
//         this.taxInclusive,
//         this.price,
//         this.baseUnitId,
//         this.baseUnitQty,
//         this.baseUnitDiscount,
//         this.baseUnitBarcode,
//         this.baseUnitOpStock,
//         this.secondUnitPrice,
//         this.secondUnitId,
//         this.secondUnitQty,
//         this.secondUnitDiscount,
//         this.secondUnitBarcode,
//         this.secondUnitOpStock,
//         this.thirdUnitPrice,
//         this.thirdUnitId,
//         this.thirdUnitQty,
//         this.thirdUnitDiscount,
//         this.thirdUnitBarcode,
//         this.thirdUnitOpStock,
//         this.fourthUnitPrice,
//         this.fourthUnitId,
//         this.fourthUnitQty,
//         this.fourthUnitDiscount,
//         this.isMultipleUnit,
//         this.fourthUnitOpStock,
//         this.description,
//         this.productQty,
//         this.percentage});
//
//   Detail.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     goodsOutId = json['goods_out_id'];
//     itemId = json['item_id'];
//     productType = json['product_type'] ?? '';
//     unit = json['unit'] ?? '';
//     convertQty = json['convert_qty'] ?? 0;
//     quantity = json['quantity'] ?? 0;
//     rate = json['rate'] ?? 0;
//     prodiscount = json['prodiscount'] ?? 0;
//     taxable = json['taxable'] ?? 0;
//     taxAmt = json['tax_amt'] ?? 0;
//     mrp = json['mrp'] ?? 0;
//     amount = json['amount'] ?? 0;
//     vanId = json['van_id'] ?? 0;
//     userId = json['user_id'] ?? 0;
//     storeId = json['store_id'] ?? 0;
//     status = json['status'] ?? 0;
//     createdAt = json['created_at'] ?? '';
//     updatedAt = json['updated_at'] ?? '';
//     deletedAt = json['deleted_at'] ?? '';
//     code = json['code'] ?? '';
//     name = json['name'] ?? '';
//     proImage = json['pro_image'] ?? '';
//     categoryId = json['category_id'] ?? 0;
//     subCategoryId = json['sub_category_id'] ?? 0;
//     brandId = json['brand_id'] ?? 0;
//     supplierId = json['supplier_id'] ?? 0;
//     taxId = json['tax_id'] ?? 0;
//     taxPercentage = json['tax_percentage'] ?? 0;
//     taxInclusive = json['tax_inclusive'] ?? 0;
//     price = json['price'] ?? 0;
//     baseUnitId = json['base_unit_id'] ?? 0;
//     baseUnitQty = json['base_unit_qty'] ?? 0;
//     baseUnitDiscount = json['base_unit_discount'] ?? '';
//     baseUnitBarcode = json['base_unit_barcode'] ?? '';
//     baseUnitOpStock = json['base_unit_op_stock'] ?? 0;
//     secondUnitPrice = json['second_unit_price'] ?? '';
//     secondUnitId = json['second_unit_id'] ?? 0;
//     secondUnitQty = json['second_unit_qty'] ?? 0;
//     secondUnitDiscount = json['second_unit_discount'] ?? '';
//     secondUnitBarcode = json['second_unit_barcode'] ?? '';
//     secondUnitOpStock = json['second_unit_op_stock'] ?? '';
//     thirdUnitPrice = json['third_unit_price'] ?? '';
//     thirdUnitId = json['third_unit_id'] ?? 0;
//     thirdUnitQty = json['third_unit_qty'] ?? 0;
//     thirdUnitDiscount = json['third_unit_discount'] ?? '';
//     thirdUnitBarcode = json['third_unit_barcode'] ?? '';
//     thirdUnitOpStock = json['third_unit_op_stock'] ?? '';
//     fourthUnitPrice = json['fourth_unit_price'] ?? '';
//     fourthUnitId = json['fourth_unit_id'] ?? 0;
//     fourthUnitQty = json['fourth_unit_qty'] ?? 0;
//     fourthUnitDiscount = json['fourth_unit_discount'] ?? '';
//     isMultipleUnit = json['is_multiple_unit'] ?? 0;
//     fourthUnitOpStock = json['fourth_unit_op_stock'] ?? '';
//     description = json['description'] ?? '';
//     productQty = json['product_qty'] ?? 0;
//     percentage = json['percentage'] ?? 0;
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['goods_out_id'] = this.goodsOutId;
//     data['item_id'] = this.itemId;
//     data['product_type'] = this.productType;
//     data['unit'] = this.unit;
//     data['convert_qty'] = this.convertQty;
//     data['quantity'] = this.quantity;
//     data['rate'] = this.rate;
//     data['prodiscount'] = this.prodiscount;
//     data['taxable'] = this.taxable;
//     data['tax_amt'] = this.taxAmt;
//     data['mrp'] = this.mrp;
//     data['amount'] = this.amount;
//     data['van_id'] = this.vanId;
//     data['user_id'] = this.userId;
//     data['store_id'] = this.storeId;
//     data['status'] = this.status;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     data['deleted_at'] = this.deletedAt;
//     data['code'] = this.code;
//     data['name'] = this.name;
//     data['pro_image'] = this.proImage;
//     data['category_id'] = this.categoryId;
//     data['sub_category_id'] = this.subCategoryId;
//     data['brand_id'] = this.brandId;
//     data['supplier_id'] = this.supplierId;
//     data['tax_id'] = this.taxId;
//     data['tax_percentage'] = this.taxPercentage;
//     data['tax_inclusive'] = this.taxInclusive;
//     data['price'] = this.price;
//     data['base_unit_id'] = this.baseUnitId;
//     data['base_unit_qty'] = this.baseUnitQty;
//     data['base_unit_discount'] = this.baseUnitDiscount;
//     data['base_unit_barcode'] = this.baseUnitBarcode;
//     data['base_unit_op_stock'] = this.baseUnitOpStock;
//     data['second_unit_price'] = this.secondUnitPrice;
//     data['second_unit_id'] = this.secondUnitId;
//     data['second_unit_qty'] = this.secondUnitQty;
//     data['second_unit_discount'] = this.secondUnitDiscount;
//     data['second_unit_barcode'] = this.secondUnitBarcode;
//     data['second_unit_op_stock'] = this.secondUnitOpStock;
//     data['third_unit_price'] = this.thirdUnitPrice;
//     data['third_unit_id'] = this.thirdUnitId;
//     data['third_unit_qty'] = this.thirdUnitQty;
//     data['third_unit_discount'] = this.thirdUnitDiscount;
//     data['third_unit_barcode'] = this.thirdUnitBarcode;
//     data['third_unit_op_stock'] = this.thirdUnitOpStock;
//     data['fourth_unit_price'] = this.fourthUnitPrice;
//     data['fourth_unit_id'] = this.fourthUnitId;
//     data['fourth_unit_qty'] = this.fourthUnitQty;
//     data['fourth_unit_discount'] = this.fourthUnitDiscount;
//     data['is_multiple_unit'] = this.isMultipleUnit;
//     data['fourth_unit_op_stock'] = this.fourthUnitOpStock;
//     data['description'] = this.description;
//     data['product_qty'] = this.productQty;
//     data['percentage'] = this.percentage;
//     return data;
//   }
// }
//
// class Customer {
//   int? id;
//   String? name;
//   String? code;
//   dynamic address;
//   String? contactNumber;
//   String? whatsappNumber;
//   String? email;
//   String? trn;
//   String? custImage;
//   String? paymentTerms;
//   int? creditLimit;
//   int? creditDays;
//   int? routeId;
//   int? provinceId;
//   int? storeId;
//   int? status;
//   String? createdAt;
//   String? updatedAt;
//   String? deletedAt;
//   String? erpCustomerCode;
//
//   Customer(
//       {this.id,
//         this.name,
//         this.code,
//         this.address,
//         this.contactNumber,
//         this.whatsappNumber,
//         this.email,
//         this.trn,
//         this.custImage,
//         this.paymentTerms,
//         this.creditLimit,
//         this.creditDays,
//         this.routeId,
//         this.provinceId,
//         this.storeId,
//         this.status,
//         this.createdAt,
//         this.updatedAt,
//         this.deletedAt,
//         this.erpCustomerCode});
//
//   Customer.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     name = json['name'];
//     code = json['code'];
//     address = json['address'];
//     contactNumber = json['contact_number'];
//     whatsappNumber = json['whatsapp_number'];
//     email = json['email'];
//     trn = json['trn'];
//     custImage = json['cust_image'];
//     paymentTerms = json['payment_terms'];
//     creditLimit = json['credit_limit'];
//     creditDays = json['credit_days'];
//     routeId = json['route_id'];
//     provinceId = json['province_id'];
//     storeId = json['store_id'];
//     status = json['status'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//     deletedAt = json['deleted_at'];
//     erpCustomerCode = json['erp_customer_code'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['name'] = this.name;
//     data['code'] = this.code;
//     data['address'] = this.address;
//     data['contact_number'] = this.contactNumber;
//     data['whatsapp_number'] = this.whatsappNumber;
//     data['email'] = this.email;
//     data['trn'] = this.trn;
//     data['cust_image'] = this.custImage;
//     data['payment_terms'] = this.paymentTerms;
//     data['credit_limit'] = this.creditLimit;
//     data['credit_days'] = this.creditDays;
//     data['route_id'] = this.routeId;
//     data['province_id'] = this.provinceId;
//     data['store_id'] = this.storeId;
//     data['status'] = this.status;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     data['deleted_at'] = this.deletedAt;
//     data['erp_customer_code'] = this.erpCustomerCode;
//     return data;
//   }
// }


// import 'dart:convert';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:image/image.dart' as img;
//
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/widgets.dart';
// import 'package:intl/intl.dart';
// import 'package:mobizapp/Models/appstate.dart';
// import 'package:number_to_words/number_to_words.dart';
// import 'package:printing/printing.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:shimmer/shimmer.dart';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
// import 'package:http/http.dart' as http;
//
// import '../Models/invoicedata.dart' as Invoice;
// import '../Models/pdfgenerate.dart';
// import '../Models/productquantirydetails.dart' as Qty;
// import '../Models/salesdata.dart';
// import '../Models/vansaleproduct.dart';
// import '../Utilities/rest_ds.dart';
// import '../confg/appconfig.dart';
// import '../confg/sizeconfig.dart';
// import '../Components/commonwidgets.dart';
//
// class SaleInvoiceScrreen extends StatefulWidget {
//   static const routeName = "/SalreInvoice";
//   const SaleInvoiceScrreen({super.key});
//
//   @override
//   State<SaleInvoiceScrreen> createState() => _SaleInvoiceScrreenState();
// }
//
// class _SaleInvoiceScrreenState extends State<SaleInvoiceScrreen> {
//   final TextEditingController _searchData = TextEditingController();
//   List<BluetoothDevice> _devices = [];
//   BluetoothDevice? _selectedDevice;
//   bool _connected = false;
//   VanSaleProducts products = VanSaleProducts();
//   BlueThermalPrinter printer = BlueThermalPrinter.instance;
//   bool _initDone = false;
//   bool _noData = false;
//
//   List<int> selectedItems = [];
//   List<Map<String, dynamic>> items = [];
//   bool _search = false;
//   int? customerId;
//
//   int? id;
//   String? name;
//
//   Qty.ProductQuantityDetails qunatityData = Qty.ProductQuantityDetails();
//   List<Qty.ProductQuantityDetails> quantity = [];
//   @override
//   void initState() {
//     super.initState();
//     _getProducts();
//     _initPrinter();
//   }
//
//   void _initPrinter() async {
//     bool? isConnected = await printer.isConnected;
//     if (isConnected!) {
//       setState(() {
//         _connected = true;
//       });
//     }
//     _getBluetoothDevices();
//   }
//
//   void _getBluetoothDevices() async {
//     List<BluetoothDevice> devices = await printer.getBondedDevices();
//     BluetoothDevice? defaultDevice;
//     final prefs = await SharedPreferences.getInstance();
//     final savedDeviceAddress = prefs.getString('selected_device_address');
//     for (BluetoothDevice device in devices) {
//       if (device.address == savedDeviceAddress) {
//         defaultDevice = device;
//         break;
//       }
//     }
//     setState(() {
//       _devices = devices;
//       _selectedDevice = defaultDevice;
//     });
//   }
//
//   Future<void> _connect() async {
//     if (_selectedDevice != null) {
//       await printer.connect(_selectedDevice!);
//       setState(() {
//         _connected = true;
//       });
//     }
//   }
//
//   // void _print() async {
//   //   if (_connected) {
//   //     Invoice.InvoiceData invoice = Invoice.InvoiceData();
//   //     printer.printNewLine();
//   //     printer.printCustom(_createPdf(invoice, false).toString(), 3, 1);
//   //     printer.printNewLine();
//   //     printer.paperCut();
//   //   } else {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Printer not connected')),
//   //     );
//   //   }
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     if (ModalRoute.of(context)!.settings.arguments != null) {
//       final Map<String, dynamic>? params =
//       ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
//       id = params!['customerId'];
//       name = params['name'];
//     }
//     return Scaffold(
//       appBar: AppBar(
//         iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
//         title: const Text(
//           'Sales Invoice',
//           style: TextStyle(color: AppConfig.backgroundColor),
//         ),
//         backgroundColor: AppConfig.colorPrimary,
//         actions: [],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10.0),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               CommonWidgets.verticalSpace(1),
//               (_initDone && !_noData)
//                   ? SizedBox(
//                 height: SizeConfig.blockSizeVertical * 85,
//                 child: ListView.separated(
//                   separatorBuilder: (BuildContext context, int index) =>
//                       CommonWidgets.verticalSpace(1),
//                   itemCount: products.data!.length,
//                   shrinkWrap: true,
//                   itemBuilder: (context, index) =>
//                       _productsCard(products.data![index], index),
//                 ),
//               )
//                   : (_noData && _initDone)
//                   ? Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CommonWidgets.verticalSpace(3),
//                     const Center(
//                       child: Text('No Data'),
//                     ),
//                   ])
//                   : Shimmer.fromColors(
//                 baseColor:
//                 AppConfig.buttonDeactiveColor.withOpacity(0.1),
//                 highlightColor: AppConfig.backButtonColor,
//                 child: Center(
//                   child: Column(
//                     children: [
//                       CommonWidgets.loadingContainers(
//                           height: SizeConfig.blockSizeVertical * 10,
//                           width: SizeConfig.blockSizeHorizontal * 90),
//                       CommonWidgets.loadingContainers(
//                           height: SizeConfig.blockSizeVertical * 10,
//                           width: SizeConfig.blockSizeHorizontal * 90),
//                       CommonWidgets.loadingContainers(
//                           height: SizeConfig.blockSizeVertical * 10,
//                           width: SizeConfig.blockSizeHorizontal * 90),
//                       CommonWidgets.loadingContainers(
//                           height: SizeConfig.blockSizeVertical * 10,
//                           width: SizeConfig.blockSizeHorizontal * 90),
//                       CommonWidgets.loadingContainers(
//                           height: SizeConfig.blockSizeVertical * 10,
//                           width: SizeConfig.blockSizeHorizontal * 90),
//                       CommonWidgets.loadingContainers(
//                           height: SizeConfig.blockSizeVertical * 10,
//                           width: SizeConfig.blockSizeHorizontal * 90),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _productsCard(Data data, int index) {
//     return Card(
//       elevation: 1,
//       child: Container(
//         width: SizeConfig.blockSizeHorizontal * 90,
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey.withOpacity(0.3)),
//           color: AppConfig.backgroundColor,
//           borderRadius: const BorderRadius.all(
//             Radius.circular(10),
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(5.0),
//           child: ExpansionTile(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             trailing: SizedBox.shrink(),
//             backgroundColor: AppConfig.backgroundColor,
//             title: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Tooltip(
//                   message: data.invoiceNo!,
//                   child: SizedBox(
//                     width: SizeConfig.blockSizeHorizontal * 70,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           '${data.invoiceNo!} | ${DateFormat('dd MMMM yyyy').format(DateTime.parse(data.inDate!))} ${data.inTime}',
//                           style: TextStyle(
//                             fontSize: AppConfig.textCaption3Size,
//                           ),
//                         ),
//                         SizedBox(width: 14,),
//                         Text(
//                           data.status == 0
//                               ? "Cancelled"
//                               : data.status == 1
//                               ? "Confirmed"
//                               : "",
//                           style: TextStyle(
//                             fontSize: AppConfig.textCaption3Size,
//                             fontWeight: AppConfig.headLineWeight,
//                             color: data.status == 0
//                                 ? Colors.red  // Color for Cancelled
//                                 : data.status == 1
//                                 ? Colors.green  // Color for Confirmed
//                                 : Colors.grey,  // Default color for unknown status
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     Text(
//                       (data.customer!.isNotEmpty)
//                           ? data.customer![0].code ?? ''
//                           : '',
//                       style: TextStyle(
//                           fontSize: AppConfig.textCaption3Size,
//                           fontWeight: AppConfig.headLineWeight),
//                     ),
//                     Text(' | '),
//                     Text(
//                       (data.customer!.isNotEmpty)
//                           ? data.customer![0].name ?? ''
//                           : '',
//                       style: TextStyle(
//                           fontSize: AppConfig.textCaption3Size,
//                           fontWeight: AppConfig.headLineWeight),
//                     ),
//                   ],
//                 ),
//                 (data.detail!.isNotEmpty)
//                 // ? Text(
//                 //     'Type: ${data.detail![0].productType}',
//                 //     style: TextStyle(
//                 //       fontSize: AppConfig.textCaption3Size,
//                 //     ),
//                 //   )
//
//                     ? Text(
//                   'Total: ${data.total?.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
//                   style: TextStyle(
//                     fontSize: AppConfig.textCaption3Size,
//                   ),
//                 )
//                     : Text(
//                   'Type:  ',
//                   style: TextStyle(
//                     fontSize: AppConfig.textCaption3Size,
//                   ),
//                 ),
//                 data.discount_type == '0'
//                     ? Text(
//                   'Discount : ${data.discount?.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
//                   style: TextStyle(
//                     fontSize: AppConfig.textCaption3Size,
//                   ),
//                 )
//                     : data.discount_type == '1'
//                     ? Text(
//                   'Discount(%): ${data.discount?.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
//                   style: TextStyle(
//                     fontSize: AppConfig.textCaption3Size,
//                   ),
//                 )
//                     : SizedBox.shrink(),
//                 Row(
//                   children: [
//                     Text(
//                       'Round off:${double.parse(data.roundOff ?? '').toStringAsFixed(AppState().noOfDecimals ?? 2)}',
//                       style: TextStyle(
//                         fontSize: AppConfig.textCaption3Size,
//                       ),
//                     ),
//                     const Spacer(),
//                     InkWell(
//                       onTap: () => _getInvoiceDataprint(data.id!, false),
//                       child: const Icon(
//                         Icons.print,
//                         color: Colors.blue,
//                         size: 30,
//                       ),
//                     ),
//                     CommonWidgets.horizontalSpace(2),
//                     InkWell(
//                       onTap: () => _getInvoiceData(data.id!, false),
//                       child: const Icon(
//                         Icons.document_scanner,
//                         color: Colors.red,
//                         size: 30,
//                       ),
//                     ),
//                   ],
//                 ),
//                 Text(
//                   'Total Vat: ${(data.totalTax?.toStringAsFixed(AppState().noOfDecimals ?? 2)) ?? ''}',
//                   style: TextStyle(
//                     fontSize: AppConfig.textCaption3Size,
//                   ),
//                 ),
//                 Text(
//                   'Grand Total: ${data.grandTotal?.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
//                   style: TextStyle(
//                     fontSize: AppConfig.textCaption3Size,
//                   ),
//                 ),
//               ],
//             ),
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(5.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     CommonWidgets.verticalSpace(1),
//                     Divider(
//                         color: AppConfig.buttonDeactiveColor.withOpacity(0.4)),
//                     for (int i = 0; i < data.detail!.length; i++)
//                       Column(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           SizedBox(
//                             width: SizeConfig.blockSizeHorizontal * 85,
//                             child: Text(
//                               ('${data.detail![i].code ?? ''} | ${data.detail![i].name ?? ''}')
//                                   .toUpperCase(),
//                               style: TextStyle(
//                                   fontSize: AppConfig.textCaption3Size,
//                                   fontWeight: AppConfig.headLineWeight),
//                             ),
//                           ),
//                           SizedBox(
//                             width: SizeConfig.blockSizeHorizontal * 85,
//                             child: Row(
//                               children: [
//                                 Text(
//                                   data.detail![i].productType ?? '',
//                                   style: TextStyle(
//                                     fontSize: AppConfig.textCaption3Size,
//                                   ),
//                                 ),
//                                 const Text(' | '),
//                                 Text(
//                                   data.detail![i].unit ?? '',
//                                   style: TextStyle(
//                                     fontSize: AppConfig.textCaption3Size,
//                                   ),
//                                 ),
//                                 const Text(' | '),
//                                 Text(
//                                   'Qty: ${data.detail![i].quantity}',
//                                   style: TextStyle(
//                                     fontSize: AppConfig.textCaption3Size,
//                                   ),
//                                 ),
//                                 const Text(' | '),
//                                 Text(
//                                   'Rate: ${data.detail![i].mrp}',
//                                   style: TextStyle(
//                                     fontSize: AppConfig.textCaption3Size,
//                                   ),
//                                 ),
//                                 const Text(' | '),
//                                 Text(
//                                   'Amount: ${data.detail![i].taxable?.toStringAsFixed(AppState().noOfDecimals ?? 2)}',
//                                   style: TextStyle(
//                                     fontSize: AppConfig.textCaption3Size,
//                                   ),
//                                 )
//                               ],
//                             ),
//                           ),
//                           CommonWidgets.verticalSpace(1),
//                           (i == data.detail!.length - 1)
//                               ? Container()
//                               : Divider(
//                               color: AppConfig.buttonDeactiveColor
//                                   .withOpacity(0.4)),
//                         ],
//                       ),
//                   ],
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _getProducts() async {
//     try {
//       RestDatasource api = RestDatasource();
//       dynamic resJson = await api.getDetails(
//         '/api/vansale.test.index?store_id=${AppState().storeId}&van_id=${AppState().vanId}&user_id=${AppState().userId}&page=1',
//         AppState().token,
//       );
//
//       if (resJson['data'] != null && resJson['data'] is List && resJson['data'].isNotEmpty) {
//         products = VanSaleProducts.fromJson(resJson);
//         setState(() {
//           _initDone = true;
//           _noData = false; // Ensure noData is false when valid data is received
//         });
//       } else {
//         setState(() {
//           _noData = true;
//           _initDone = true;
//         });
//       }
//     } catch (error) {
//       // Handle exceptions, such as network issues or JSON parsing errors
//       print('Error fetching products: $error');
//       setState(() {
//         _noData = true;
//         _initDone = true;
//       });
//     }
//   }
//
//
//   void _print(Invoice.InvoiceData invoice, bool isPrint) async {
//     if (_connected) {
//       String cusAddress= invoice.data!.customer![0].address ?? 'N/A';
//       String companyName = invoice.data!.store![0].name ?? 'N/A';
//       String companyAddress = invoice.data!.store![0].address ?? 'N/A';
//       String companyMail = invoice.data!.store![0].email??'N/A';
//       String companyTRN = "TRN: ${invoice.data!.store![0].trn ?? 'N/A'}";
//       String billtype = "Tax Invoice";
//       String customerName = "${invoice.data!.customer![0].name}";
//       List<String> nameWords = customerName.split(' ');
//       String firstLine = customerName;
//       String secondLine = "";
//       if (nameWords.length > 7) {
//         firstLine = nameWords.sublist(0, 7).join(' ');
//         secondLine = nameWords.sublist(7).join(' ');
//       }
//       String customerEmail = invoice.data!.customer![0].email ?? 'N/A';
//       String customerContact =
//           invoice.data!.customer![0].contactNumber ?? 'N/A';
//       String customerTRN = invoice.data!.customer![0].trn ?? '';
//       String invoiceNumber = invoice.data!.invoiceNo ?? 'N/A';
//       String invoiceDate = DateFormat('dd MMMM yyyy')
//           .format(DateTime.parse(invoice.data!.inDate!));
//       String dueDate = DateFormat('dd MMMM yyyy')
//           .format(DateTime.parse(invoice.data!.inDate!));
//       String Total = invoice.data!.total?.toStringAsFixed(AppState().noOfDecimals ?? 2)??'0.00';
//       String tax = invoice.data!.totalTax?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//       String grandTotal =
//           invoice.data!.grandTotal?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//       final remarks = invoice.data?.remarks;
//       String Discount;
//       if (invoice.data!.discount != null &&
//           double.tryParse(invoice.data!.discount!.toString()) != null &&
//           double.parse(invoice.data!.discount!.toString()) > 0) {
//
//         Discount = "Discount: ${double.parse(invoice.data!.discount!.toString()).toStringAsFixed(AppState().noOfDecimals ?? 2)}";
//       } else {
//         Discount = '';
//       }
//       String amountInWords =
//           "Amount in Words: AED ${NumberToWord().convert('en-in', invoice.data!.grandTotal?.toInt() ?? 0).toUpperCase()} ONLY";
//       String van = invoice.data!.van![0].name ?? 'N/A';
//       String salesman = invoice.data!.user![0].name ?? 'N/A';
//
//       void printAlignedText(String leftText, String rightText) {
//         const int maxLineLength =
//         68; // Adjust the maximum line length as per your printer's character limit
//         int leftTextLength = leftText.length;
//         int rightTextLength = rightText.length;
//
//         // Calculate padding to ensure rightText is right-aligned
//         int spaceLength = maxLineLength - (leftTextLength + rightTextLength);
//         String spaces = ' ' * spaceLength;
//
//         printer.printCustom(
//             '$leftText$spaces$rightText', 1, 0); // Print with left-aligned text
//       }
//
//       String logoUrl =
//           'http://68.183.92.8:3697/uploads/store/${invoice.data!.store![0].logo}';
//       if (logoUrl.isNotEmpty) {
//         final response = await http.get(Uri.parse(logoUrl));
//         if (response.statusCode == 200) {
//           Uint8List imageBytes = response.bodyBytes;
//
//           // Decode image and convert to monochrome bitmap if needed
//           img.Image originalImage = img.decodeImage(imageBytes)!;
//           img.Image monoLogo = img.grayscale(originalImage);
//
//           // Encode the image to the required format (e.g., PNG)
//           Uint8List logoBytes = Uint8List.fromList(img.encodePng(monoLogo));
//
//           // Print the logo image
//           printer.printImageBytes(logoBytes);
//         } else {
//           print('Failed to load image: ${response.statusCode}');
//         }
//       }
//       // Print company details
//       printer.printNewLine();
//       printer.printCustom(companyName, 3, 1); // Centered
//       printer.printCustom(companyAddress, 1, 1); // Centered
//       printer.printCustom(companyMail, 1, 1);
//       printer.printCustom(companyTRN, 1, 1); // Centered
//       printer.printCustom(billtype, 1, 1); // Centered
//       printer.printNewLine();
//
//       printer.printCustom("-" * 72, 1, 1); // Centered
//       printAlignedText("Invoice No: ${invoiceNumber}","Date: ${invoiceDate}");
//       printAlignedText("","${remarks != null? remarks:''}");
//       // printer.printCustom("Invoice No: ${invoiceNumber} | Date: ${invoiceDate}", 1, 1);
//       printer.printNewLine();
//       // Print customer details
//       printAlignedText("Customer: $firstLine","");
//
//       if (secondLine.isNotEmpty) {
//         printAlignedText("         $secondLine", "");
//       }
//       printAlignedText("$cusAddress", " ");
//       // printAlignedText("Email: $customerEmail", "");
//       printAlignedText("Contact No: $customerContact", "");
//       printAlignedText("TRN: $customerTRN", " ");
//       printer.printNewLine();
//
//       // Print horizontal line
//       printer.printCustom("-" * 70, 1, 1); // Centered
//
//       // Define column widths for table
//       const int columnWidth1 = 5; // S.No
//       const int columnWidth2 = 22; // Product Description
//       const int columnWidth3 = 5; // Unit
//       const int columnWidth4 = 4; // Qty
//       const int columnWidth5 = 7; // Type
//       const int columnWidth6 = 8; // Rate
//       const int columnWidth7 = 8; // Total
//       // const int columnWidth8 = 4; // Tax
//       const int columnWidth9 = 6; // Amount
//
//       // Print table headers
//       String headers = "${'S.No'.padRight(columnWidth1)}"
//           " ${'Product'.padRight(columnWidth2)}"
//           " ${'Unit'.padRight(columnWidth3)}"
//           "${'Qty'.padRight(columnWidth4)}"
//           "${'Type'.padRight(columnWidth5)}"
//           "${'Rate'.padRight(columnWidth6)}"
//           "${'Amount'.padRight(columnWidth7)}"
//       // "${'Vat'.padRight(columnWidth8)}"
//           " ${'Total'.padLeft(columnWidth9)}";
//       printer.printCustom(headers, 1, 0); // Left aligned
//
//       // Function to split text into lines of a given width
//       List<String> splitText(String text, int width) {
//         List<String> lines = [];
//         while (text.length > width) {
//           lines.add(text.substring(0, width));
//           text = text.substring(width);
//         }
//         lines.add(text); // Add remaining part
//         return lines;
//       }
//
//       // Print all product details
//       for (int i = 0; i < invoice.data!.detail!.length; i++) {
//         String productDescription = invoice.data!.detail![i].name ?? 'N/A';
//         String productUnit = invoice.data!.detail![i].unit ?? 'N/A';
//         String productQty = invoice.data!.detail![i].quantity?.toString() ?? '0';
//         String productType= invoice.data!.detail![i].productType?.toString()??'0';
//         String productRate = invoice.data!.detail![i].mrp?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//         String productTotal = invoice.data!.detail![i].taxable?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//         // String productTax = tax.toString();
//         String productAmount =invoice.data!.detail![i].amount?.toStringAsFixed(AppState().noOfDecimals ?? 2)??'0.00';
//         // (invoice.data!.detail![i].mrp! * invoice.data!.detail![i].quantity!)
//         //     .toStringAsFixed(AppState().noOfDecimals ?? 2);
//
//         // Split the product description if it exceeds the column width
//         List<String> descriptionLines =
//         splitText(productDescription, columnWidth2);
//
//         for (int j = 0; j < descriptionLines.length; j++) {
//           String line;
//           if (j == 0) {
//             // For the first line, include all columns
//             line = "${(i + 1).toString().padRight(columnWidth1)}"
//                 "${descriptionLines[j].padRight(columnWidth2)}"
//                 "  ${productUnit.padRight(columnWidth3)}"
//                 "${productQty.padRight(columnWidth4)}"
//                 "${productType.padRight(columnWidth5)}"
//                 "${productRate.padRight(columnWidth6)}"
//                 "${productTotal.padRight(columnWidth7)}"
//             // "${productTax.padRight(columnWidth8)}"
//                 "${productAmount.padLeft(columnWidth9)}";
//           } else {
//             // For subsequent lines, only include the description, leaving other columns blank
//             line = "${''.padRight(columnWidth1)}"
//                 "${descriptionLines[j].padRight(columnWidth2)}"
//                 "${''.padRight(columnWidth3)}"
//                 "${''.padRight(columnWidth4)}"
//                 "${''.padRight(columnWidth5)}"
//                 "${''.padRight(columnWidth6)}"
//                 "${''.padRight(columnWidth7)}";
//             // "${''.padRight(columnWidth8)}";
//             "${''.padRight(columnWidth9)}";
//           }
//           printer.printCustom(line, 1, 0); // Left aligned
//         }
//       }
//       printer.printCustom("-" * 70, 1, 1); // Centered
//
//       // Print totals
//       if (Discount.isNotEmpty) {
//         print(Discount);
//         printAlignedText("Van: $van", "$Discount");
//       } else {
//         printAlignedText("Van: $van", ""); // Skip printing Total
//       }
//       printAlignedText("Salesman: $salesman", "Total: $Total");
//       printer.printCustom("Vat: $tax", 1, 2);
//       printer.printCustom("Grand Total: $grandTotal", 1, 2); // Right aligned
//       printer.printNewLine();
//       printer.printCustom(amountInWords, 1, 0); // Centered
//
//       // Cut the paper
//       printer.paperCut();
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Printer not connected')),
//       );
//     }
//   }
//
//   Future<String> _getImageData(String url) async {
//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         return response.bodyBytes.toString();
//       } else {
//         print("Failed to load image: ${response.statusCode}");
//         return '';
//       }
//     } catch (e) {
//       print("Error fetching image: $e");
//       return '';
//     }
//   }
//
//   Future<void> _createPdf(Invoice.InvoiceData invoice, bool isPrint) async {
//     PdfDocument document = PdfDocument();
//     final page = document.pages.add();
//     final Size pageSize = page.getClientSize();
//
//     // Load the image.
//
//     final Uint8List imageData = await _readImageData(
//         invoice.data!.store![0].logo); //invoice.data!.store![0].logo
//     print(invoice.data!.store![0].logo);
//     if (imageData.isNotEmpty) {
//       final PdfBitmap image = PdfBitmap(imageData);
//
//       // Draw the image.
//       final Rect imageRect = Rect.fromCenter(
//         center: Offset(pageSize.width / 2, 50),
//         width: pageSize.width * 0.2, // Adjust width as per your requirement
//         height: pageSize.height * 0.1, // Adjust height as per your requirement
//       );
//       page.graphics.drawImage(image, imageRect);
//     }
//
//     //content
//     // page.graphics.drawString(
//     //     'TAX INVOICE', PdfStandardFont(PdfFontFamily.helvetica, 30));
//
//     //heading
//     final String head = '${invoice.data!.store![0].name}';
//     // Define the text and font
//     final double pageWidth = page.getClientSize().width;
//
//     final PdfFont headfont = PdfStandardFont(
//       PdfFontFamily.helvetica,
//       25,
//     );
//     final Size headtextSize = headfont.measureString(head);
//
//     final double headxPosition = (pageWidth - headtextSize.width) / 2.0;
//     final double headyPosition = 90;
//     page.graphics.drawString(
//       head,
//       headfont,
//       bounds: Rect.fromLTWH(headxPosition, headyPosition, headtextSize.width,
//           headtextSize.height),
//     );
//
//     final String addresss = '${invoice.data!.store![0].address ?? 'N/A'}';
//     final PdfFont addressfont = PdfStandardFont(PdfFontFamily.helvetica, 12);
//
//     final Size addresstextSize = addressfont.measureString(addresss);
//     final double addressxPosition = (pageWidth - addresstextSize.width) / 2.0;
//     final double addressyPosition = 120;
//
//     page.graphics.drawString(
//       addresss,
//       addressfont,
//       bounds: Rect.fromLTWH(addressxPosition, addressyPosition,
//           addresstextSize.width, addresstextSize.height),
//     );
//
//     final String email = '${invoice.data!.store![0].email ?? 'N/A'}';
//     final PdfFont emailfont = PdfStandardFont(PdfFontFamily.helvetica, 12);
//     final Size emailtextSize= emailfont.measureString(email);
//     final double emailxPosition = (pageWidth - emailtextSize.width) / 2.0;
//     final double emailyposition = 135;
//     page.graphics.drawString(
//       email,
//       emailfont,
//       bounds: Rect.fromLTWH(emailxPosition, emailyposition,
//           emailtextSize.width, emailtextSize.height),
//     );
//
//     final String trn = 'TRN:${invoice.data!.store![0].trn ?? 'N/A'}';
//     final PdfFont trnfont = PdfStandardFont(PdfFontFamily.helvetica, 12);
//
//     final Size trntextSize = trnfont.measureString(trn);
//     final double trnxPosition = (pageWidth - trntextSize.width) / 2.1;
//     final double trnyPosition = 150;
//
//     page.graphics.drawString(
//       trn,
//       trnfont,
//       bounds: Rect.fromLTWH(
//           trnxPosition, trnyPosition, trntextSize.width, trntextSize.height),
//     );
//
//     final String text = 'TAX INVOICE';
//
//     final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 15);
//
//     // Calculate the width of the text
//     final Size textSize = font.measureString(text);
//
//     // Calculate the center position for the text
//     final double xPosition = (pageWidth - textSize.width) / 2;
//     final double yPosition =
//     165; // Adjust this as needed for vertical positioning
//
//     // Draw the centered text
//     page.graphics.drawString(
//       text,
//       font,
//       bounds:
//       Rect.fromLTWH(xPosition, yPosition, textSize.width, textSize.height),
//     );
//
//     // Draw a line below the text
//     final remarks = invoice.data?.remarks;
//     final double lineYPosition =
//         yPosition + textSize.height + 10; // Adjust the gap as needed
//     page.graphics.drawLine(
//       PdfPen(PdfColor(0, 0, 0)), // Black pen
//       Offset(0, lineYPosition),
//       Offset(pageWidth, lineYPosition),
//     );
//
//     String address = '''
//   Customer: ${invoice.data!.customer![0].code} | ${invoice.data!.customer![0].name}
//   Email: ${invoice.data!.customer![0].email}
//   Contact No:  ${invoice.data!.customer![0].contactNumber}
//   TRN:  ${invoice.data!.customer![0].trn ?? ''}
//   ''';
//
//     String invoiceDetails = '''
//   Invoice No: ${invoice.data!.invoiceNo!}
//   Date: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(invoice.data!.inDate!))}
//   Due Date: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(invoice.data!.inDate!))}
//   ${remarks != null? remarks:''}
//   ''';
//
//     page.graphics.drawString(
//       address,
//       PdfStandardFont(PdfFontFamily.helvetica, 12),
//       bounds: Rect.fromLTWH(0, 200, pageSize.width / 0, 100),
//     );
//
//     page.graphics.drawString(
//       invoiceDetails,
//       PdfStandardFont(PdfFontFamily.helvetica, 12),
//       bounds: Rect.fromLTWH(pageSize.width / 2, 200, pageSize.width / 2, 100),
//       format: PdfStringFormat(
//         alignment: PdfTextAlignment.right,
//       ),
//     );
//
//     // Draw a horizontal line.
//     page.graphics.drawLine(
//       PdfPen(PdfColor(0, 0, 0)),
//       const Offset(0, 290),
//       Offset(pageSize.width, 290),
//     );
//
//     // Create a table without grid lines.
//     final PdfGrid grid = PdfGrid();
//     grid.columns.add(count: 9);
//     // Set column widths.
//     grid.columns[0].width = 30; // Sl.No
//     grid.columns[1].width = 180; // Product
//     grid.columns[2].width = 40; // Unit
//     grid.columns[3].width = 40; // Rate
//     grid.columns[4].width = 50; // Qty
//     grid.columns[5].width = 50;
//     grid.columns[6].width = 40;
//     grid.columns[7].width = 50; // Vat
//     grid.columns[8].width = 100;
//
//     // Add headers.
//     final PdfGridRow headerRow = grid.headers.add(1)[0];
//     headerRow.cells[0].value = 'Sl.No';
//     headerRow.cells[1].value = 'Product';
//     headerRow.cells[2].value = 'Unit';
//     headerRow.cells[3].value = 'Qty';
//     headerRow.cells[4].value = 'Type';
//     headerRow.cells[5].value = 'Rate';
//     headerRow.cells[6].value = 'Total';
//     headerRow.cells[7].value = 'Vat';
//     headerRow.cells[8].value = 'Amount';
//
//     for (int k = 0; k < invoice.data!.detail!.length; k++) {
//       final PdfGridRow row = grid.rows.add();
//       row.cells[0].value = '${k + 1}';
//       row.cells[1].value = '${invoice.data!.detail![k].name}';
//       row.cells[2].value = '${invoice.data!.detail![k].unit}';
//       row.cells[3].value = '${invoice.data!.detail![k].quantity}';
//       row.cells[4].value =
//       (invoice.data!.detail![k].productType!.toLowerCase() == "foc" ||
//           invoice.data!.detail![k].productType!.toLowerCase() == "FOC" ||
//           invoice.data!.detail![k].productType!.toLowerCase() == "Change")
//           ? 'Normal' : 'Normal';
//       row.cells[5].value =
//       '${invoice.data!.detail![k].mrp?.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
//       row.cells[6].value =
//       '${invoice.data!.detail![k].taxable?.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
//       row.cells[7].value =
//       '${invoice.data!.detail![k].taxAmt?.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
//       row.cells[8].value =
//       '${invoice.data!.detail![k].amount?.toStringAsFixed(AppState().noOfDecimals ?? 2)}';
//     }
//
//     // Define no border style
//     final PdfBorders noBorder = PdfBorders(
//       left: PdfPen(PdfColor(255, 255, 255), width: 0),
//       top: PdfPen(PdfColor(255, 255, 255), width: 0),
//       right: PdfPen(PdfColor(255, 255, 255), width: 0),
//       bottom: PdfPen(PdfColor(255, 255, 255), width: 0),
//     );
//
//     // Remove borders from all header cells
//     for (int j = 0; j < grid.headers.count; j++) {
//       for (int k = 0; k < grid.headers[j].cells.count; k++) {
//         grid.headers[j].cells[k].style.borders = noBorder;
//       }
//     }
//
//     // Remove borders from all body cells
//     for (int i = 0; i < grid.rows.count; i++) {
//       for (int j = 0; j < grid.columns.count; j++) {
//         grid.rows[i].cells[j].style.borders = noBorder;
//       }
//     }
//
//     // Draw the table.
//     final PdfLayoutResult result = grid.draw(
//       page: page,
//       bounds: Rect.fromLTWH(0, 300, pageSize.width, pageSize.height - 180),
//     )!;
//
//     //   // Calculate the Y position for the line after the first row
//     // final double firstRowHeight = grid.headers[0].height + grid.rows[0].height;
//
//     // // Draw a line after the first row of the grid
//     // page.graphics.drawLine(
//     //   PdfPen(PdfColor(0, 0, 0), width: 1),
//     //   Offset(0, result.bounds.top + firstRowHeight),
//     //   Offset(pageSize.width, result.bounds.top + firstRowHeight),
//     // );
//     // Check if the table extends to the next page
//     PdfPage lastPage = result.page;
//     double tableBottom = result.bounds.bottom;
//
//     if (tableBottom >= pageSize.height) {
//       // Add a new page
//       lastPage = document.pages.add();
//       tableBottom = 0;
//     }
//
//     // Draw a horizontal line after the table.
//     lastPage.graphics.drawLine(
//       PdfPen(PdfColor(0, 0, 0)),
//       Offset(0, tableBottom + 15),
//       Offset(pageSize.width, tableBottom + 15),
//     );
//
//     // Draw invoice details at the bottom right.
//
//     // ${num.parse(invoice.data!.roundOff.toString()) != 0 ? 'Discount: ${invoice.data!.discount?.toStringAsFixed(AppState().noOfDecimals ?? 2)}' : '\t'}
//
//     String bottomInvoiceDetails = '''
//     ${invoice.data!.discount != null && invoice.data!.discount! > 0 ? 'Discount: ${invoice.data!.discount!.toStringAsFixed(AppState().noOfDecimals ?? 2)}' : '\t'}
//   Total: ${invoice.data!.total ?? ''}
//   Vat: ${invoice.data!.totalTax?.toStringAsFixed(AppState().noOfDecimals ?? 2)}
//   ${'${invoice.data!.roundOff}' != 0 ? 'Round off:${double.parse(invoice.data!.roundOff ?? '').toStringAsFixed(AppState().noOfDecimals ?? 2)}\nGrand Total: ${invoice.data!.grandTotal?.toStringAsFixed(AppState().noOfDecimals ?? 2)}' : 'Grand Total: ${invoice.data!.grandTotal}'}
//
//
//   ''';
//     print('invoice.data!.discounted_amount');
//     print(invoice.data!.discounted_amount);
//
//     lastPage.graphics.drawString(
//       bottomInvoiceDetails,
//       PdfStandardFont(PdfFontFamily.helvetica, 12),
//       bounds: Rect.fromLTWH(
//         pageSize.width / 2,
//         tableBottom + 20,
//         pageSize.width / 2,
//         100,
//       ),
//       format: PdfStringFormat(
//         alignment: PdfTextAlignment.right,
//       ),
//     );
//
// // in word
//     String textData =
//         'Amount in Words: AED ${NumberToWord().convert('en-in', invoice.data!.grandTotal!.toInt()).toUpperCase()} ONLY';
//
// // Adjust the vertical position for the van details
//     double vanDetailsTop = tableBottom + 20 + 100 + 10;
//
// // Construct the van details string.
//     String bottomVanDetails = '''
// Van: ${invoice.data!.van![0].name}
// Salesman: ${invoice.data!.user![0].name}
// ''';
//
// // Draw the word text above the van details
//     lastPage.graphics.drawString(
//       textData,
//       PdfStandardFont(PdfFontFamily.helvetica, 12),
//       bounds: Rect.fromLTWH(
//         0,
//         vanDetailsTop -
//             17, // Adjust vertical position to be above the van details
//         pageSize.width,
//         100,
//       ),
//       format: PdfStringFormat(
//         alignment: PdfTextAlignment.left,
//       ),
//     );
// // Draw van details at the bottom left.
//     lastPage.graphics.drawString(
//       bottomVanDetails,
//       PdfStandardFont(PdfFontFamily.helvetica, 12),
//       bounds: Rect.fromLTWH(
//         0,
//         vanDetailsTop,
//         pageSize.width / 2,
//         100,
//       ),
//       format: PdfStringFormat(
//         alignment: PdfTextAlignment.left,
//       ),
//     );
//     List<int> bytes = await document.save();
//     document.dispose();
//
//     String file = await saveAndLaunchFile(
//         bytes, '${invoice.data!.invoiceNo!}.pdf', isPrint);
//   }
//
//   // Future<String> _getImageData(String imageUrl) async {
//   //   http.Response response = await http.get(Uri.parse(imageUrl));
//   //   Uint8List bytes = response.bodyBytes;
//   //   return base64Encode(bytes);
//   // }
//
//   Future<Uint8List> _readImageData(String? image) async {
//     // print(image);
//     // print('jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj');
//     try {
//       final response = await http
//           .get(Uri.parse('${RestDatasource().Image_URL}/uploads/store/$image'));
//
//       print('Response Data $response');
//
//       if (response.statusCode == 200) {
//         return response.bodyBytes;
//       } else {
//         throw Exception('Failed to load image');
//       }
//     } catch (e) {
//       // Log the error and return an empty Uint8List
//       print('Error loading image: $e');
//       return Uint8List(0);
//     }
//   }
//
//   Future<void> _getInvoiceData(int id, bool isPrint) async {
//     Invoice.InvoiceData invoice = Invoice.InvoiceData();
//     RestDatasource api = RestDatasource();
//     dynamic response =
//     await api.getDetails('/api/get_sales_invoice?id=$id', AppState().token);
//     if (response['data'] != null) {
//       print("DDDDDD${id}");
//       invoice = Invoice.InvoiceData.fromJson(response);
//       _createPdf(invoice, isPrint);
//     }
//     // if (_selectedDevice == null) {
//     //   ScaffoldMessenger.of(context).showSnackBar(
//     //     SnackBar(content: Text('Default device not found')),
//     //   );
//     //   return;
//     // }
//     // if (!_connected) {
//     //   await _connect();
//     // }
//     // _print(invoice, isPrint);
//   }
//
//   Future<void> _getInvoiceDataprint(int id, bool isPrint) async {
//     Invoice.InvoiceData invoice = Invoice.InvoiceData();
//     RestDatasource api = RestDatasource();
//     dynamic response =
//     await api.getDetails('/api/get_sales_invoice?id=$id', AppState().token);
//
//     if (response['data'] != null) {
//       invoice = Invoice.InvoiceData.fromJson(response);
//       // _createPdf(invoice, isPrint);
//     }
//     if (_selectedDevice == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Default device not found')),
//       );
//       return;
//     }
//     if (!_connected) {
//       await _connect();
//     }
//     _print(invoice, isPrint);
//   }
// // void _connectAndPrint() async {
// //   if (_selectedDevice == null) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text('Default device not found')),
// //     );
// //     return;
// //   }
// //   if (!_connected) {
// //     await _connect();
// //   }
// //   _print();
// // }
// }






// import 'dart:typed_data';
//
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/widgets.dart';
// import 'package:intl/intl.dart';
// import 'package:mobizapp/Models/appstate.dart';
// import 'package:number_to_words/number_to_words.dart';
// import 'package:printing/printing.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
// import 'package:http/http.dart' as http;
// import 'package:image/image.dart' as img;
// import '../Models/invoicedata.dart' as Invoice;
// import '../Models/pdfgenerate.dart';
// import '../Models/productquantirydetails.dart' as Qty;
// import '../Models/salesdata.dart';
// import '../Models/vansaleproduct.dart';
// import '../Utilities/rest_ds.dart';
// import '../confg/appconfig.dart';
// import '../confg/sizeconfig.dart';
// import '../Components/commonwidgets.dart';
//
// class HomereturnScreen extends StatefulWidget {
//   static const routeName = "/HomereturnScreen";
//   const HomereturnScreen({super.key});
//
//   @override
//   State<HomereturnScreen> createState() => _HomereturnScreenState();
// }
//
// class _HomereturnScreenState extends State<HomereturnScreen> {
//   final TextEditingController _searchData = TextEditingController();
//   VanSaleProducts products = VanSaleProducts();
//   bool _initDone = false;
//   bool _noData = false;
//   BluetoothDevice? _selectedDevice;
//   List<BluetoothDevice> _devices = [];
//   BlueThermalPrinter printer = BlueThermalPrinter.instance;
//   bool _connected = false;
//   List<int> selectedItems = [];
//   List<Map<String, dynamic>> items = [];
//   bool _search = false;
//   int? customerId;
//
//   int? id;
//   String? name;
//
//   Qty.ProductQuantityDetails qunatityData = Qty.ProductQuantityDetails();
//   List<Qty.ProductQuantityDetails> quantity = [];
//   @override
//   void initState() {
//     super.initState();
//     _getProducts();
//     _initPrinter();
//   }
//
//
//   void _initPrinter() async {
//     bool? isConnected = await printer.isConnected;
//     if (isConnected!) {
//       setState(() {
//         _connected = true;
//       });
//     }
//     _getBluetoothDevices();
//   }
//
//
//   void _getBluetoothDevices() async {
//     List<BluetoothDevice> devices = await printer.getBondedDevices();
//     BluetoothDevice? defaultDevice;
//     final prefs = await SharedPreferences.getInstance();
//     final savedDeviceAddress = prefs.getString('selected_device_address');
//     for (BluetoothDevice device in devices) {
//       if (device.address == savedDeviceAddress) {
//         defaultDevice = device;
//         break;
//       }
//     }
//     setState(() {
//       _devices = devices;
//       _selectedDevice = defaultDevice;
//     });
//   }
//
//   Future<void> _connect() async {
//     if (_selectedDevice != null) {
//       await printer.connect(_selectedDevice!);
//       setState(() {
//         _connected = true;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (ModalRoute.of(context)!.settings.arguments != null) {
//       final Map<String, dynamic>? params =
//       ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
//       id = params!['customerId'];
//       name = params!['name'];
//     }
//     return Scaffold(
//       appBar: AppBar(
//         iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
//         title: const Text(
//           'Return',
//           style: TextStyle(color: AppConfig.backgroundColor),
//         ),
//         backgroundColor: AppConfig.colorPrimary,
//         actions: [
//           // (_search)
//           //     ? Container(
//           //         height: SizeConfig.blockSizeVertical * 5,
//           //         width: SizeConfig.blockSizeHorizontal * 76,
//           //         decoration: BoxDecoration(
//           //           color: AppConfig.colorPrimary,
//           //           borderRadius: const BorderRadius.all(
//           //             Radius.circular(10),
//           //           ),
//           //           border: Border.all(color: AppConfig.colorPrimary),
//           //         ),
//           //         child: TextField(
//           //           controller: _searchData,
//           //           decoration: const InputDecoration(
//           //               contentPadding: EdgeInsets.all(5),
//           //               hintText: "Search...",
//           //               hintStyle: TextStyle(color: AppConfig.backgroundColor),
//           //               border: InputBorder.none),
//           //         ),
//           //       )
//           //     : Container(),
//           // CommonWidgets.horizontalSpace(1),
//           // GestureDetector(
//           //   onTap: () {
//           //     setState(() {
//           //       _search = !_search;
//           //     });
//           //   },
//           //   child: Icon(
//           //     (!_search) ? Icons.search : Icons.close,
//           //     size: 30,
//           //     color: AppConfig.backgroundColor,
//           //   ),
//           // ),
//           // CommonWidgets.horizontalSpace(3),
//         ],
//       ),
//       // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//       // floatingActionButton: SizedBox(
//       //   width: SizeConfig.blockSizeHorizontal * 25,
//       //   height: SizeConfig.blockSizeVertical * 5,
//       //   child: ElevatedButton(
//       //     style: ButtonStyle(
//       //       shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//       //         RoundedRectangleBorder(
//       //           borderRadius: BorderRadius.circular(20.0),
//       //         ),
//       //       ),
//       //       backgroundColor:
//       //           const MaterialStatePropertyAll(AppConfig.colorPrimary),
//       //     ),
//       //     onPressed: () async {
//       //       for (var item in items) {
//       //         await StockHistory.addToStockHistory(item);
//       //       }
//       //       if (mounted) {
//       //         Navigator.of(context).pop();
//       //       }
//       //     },
//       //     child: Text(
//       //       'ADD',
//       //       style: TextStyle(
//       //           fontSize: AppConfig.textCaption3Size,
//       //           color: AppConfig.backgroundColor,
//       //           fontWeight: AppConfig.headLineWeight),
//       //     ),
//       //   ),
//       // ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10.0),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               CommonWidgets.verticalSpace(1),
//               (_initDone && !_noData)
//                   ? SizedBox(
//                 height: SizeConfig.blockSizeVertical * 85,
//                 child: ListView.separated(
//                   separatorBuilder: (BuildContext context, int index) =>
//                       CommonWidgets.verticalSpace(1),
//                   itemCount: products.data!.length,
//                   shrinkWrap: true,
//                   itemBuilder: (context, index) =>
//                       _productsCard(products.data![index], index),
//                 ),
//               )
//                   : (_noData && _initDone)
//                   ? Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CommonWidgets.verticalSpace(3),
//                     const Center(
//                       child: Text('No Data'),
//                     ),
//                   ])
//                   : Shimmer.fromColors(
//                 baseColor:
//                 AppConfig.buttonDeactiveColor.withOpacity(0.1),
//                 highlightColor: AppConfig.backButtonColor,
//                 child: Center(
//                   child: Column(
//                     children: [
//                       CommonWidgets.loadingContainers(
//                           height: SizeConfig.blockSizeVertical * 10,
//                           width: SizeConfig.blockSizeHorizontal * 90),
//                       CommonWidgets.loadingContainers(
//                           height: SizeConfig.blockSizeVertical * 10,
//                           width: SizeConfig.blockSizeHorizontal * 90),
//                       CommonWidgets.loadingContainers(
//                           height: SizeConfig.blockSizeVertical * 10,
//                           width: SizeConfig.blockSizeHorizontal * 90),
//                       CommonWidgets.loadingContainers(
//                           height: SizeConfig.blockSizeVertical * 10,
//                           width: SizeConfig.blockSizeHorizontal * 90),
//                       CommonWidgets.loadingContainers(
//                           height: SizeConfig.blockSizeVertical * 10,
//                           width: SizeConfig.blockSizeHorizontal * 90),
//                       CommonWidgets.loadingContainers(
//                           height: SizeConfig.blockSizeVertical * 10,
//                           width: SizeConfig.blockSizeHorizontal * 90),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _productsCard(Data data, int index) {
//     return Card(
//       elevation: 1,
//       child: Container(
//         width: SizeConfig.blockSizeHorizontal * 90,
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.grey.withOpacity(0.3)),
//           color: AppConfig.backgroundColor,
//           borderRadius: const BorderRadius.all(
//             Radius.circular(10),
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(5.0),
//           child: ExpansionTile(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             trailing: Transform.rotate(
//               angle: 100,
//               child: const Icon(Icons.touch_app, color: Colors.transparent),
//             ),
//             backgroundColor: AppConfig.backgroundColor,
//             title: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Tooltip(
//                   message: data.invoiceNo!,
//                   child: SizedBox(
//                     width: SizeConfig.blockSizeHorizontal * 70,
//                     child: Text(
//                       '${data.invoiceNo!} | ${DateFormat('dd MMMM yyyy').format(DateTime.parse(data.inDate!))} ${data.inTime}',
//                       style: TextStyle(
//                         fontSize: AppConfig.textCaption3Size,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     Text(
//                       (data.customer!.isNotEmpty)
//                           ? data.customer![0].code ?? ''
//                           : '',
//                       style: TextStyle(
//                           fontSize: AppConfig.textCaption3Size,
//                           fontWeight: AppConfig.headLineWeight),
//                     ),
//                     Text(' | '),
//                     Text(
//                       (data.customer!.isNotEmpty)
//                           ? data.customer![0].name ?? ''
//                           : '',
//                       style: TextStyle(
//                           fontSize: AppConfig.textCaption3Size,
//                           fontWeight: AppConfig.headLineWeight),
//                     ),
//                   ],
//                 ),
//                 // (data.detail!.isNotEmpty)
//                 // ? Text(
//                 //     'Type: ${data.detail![0].productType}',
//                 //     style: TextStyle(
//                 //       fontSize: AppConfig.textCaption3Size,
//                 //     ),
//                 //   )
//
//                 Text(
//                   'Total: ${data.total}',
//                   style: TextStyle(
//                     fontSize: AppConfig.textCaption3Size,
//                   ),
//                 ),
//                 // : Text(
//                 //     'Type:  ',
//                 //     style: TextStyle(
//                 //       fontSize: AppConfig.textCaption3Size,
//                 //     ),
//                 //   ),
//                 Text(
//                   'Discount(%): ${data.discount}',
//                   style: TextStyle(
//                     fontSize: AppConfig.textCaption3Size,
//                   ),
//                 ),
//                 SizedBox(
//                   width: SizeConfig.blockSizeHorizontal * 90,
//                   child: Row(
//                     children: [
//                       Text(
//                         'Round Off: ${data.roundOff ?? ''}',
//                         style: TextStyle(
//                           fontSize: AppConfig.textCaption3Size,
//                         ),
//                       ),
//                       const Spacer(),
//                       InkWell(
//                         onTap: () => _getInvoicePrint(data.id!, false),
//                         child: const Icon(
//                           Icons.print,
//                           color: Colors.blue,
//                           size: 30,
//                         ),
//                       ),
//                       CommonWidgets.horizontalSpace(2),
//                       InkWell(
//                         onTap: () => _getInvoiceData(data.id!, false),
//                         child: const Icon(
//                           Icons.document_scanner,
//                           color: Colors.red,
//                           size: 30,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Text(
//                   'Total Tax: ${data.totalTax ?? ''}',
//                   style: TextStyle(
//                     fontSize: AppConfig.textCaption3Size,
//                   ),
//                 ),
//                 Text(
//                   'Grand Total: ${data.grandTotal}',
//                   style: TextStyle(
//                     fontSize: AppConfig.textCaption3Size,
//                   ),
//                 ),
//               ],
//             ),
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(5.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     CommonWidgets.verticalSpace(1),
//                     Divider(
//                         color: AppConfig.buttonDeactiveColor.withOpacity(0.4)),
//                     for (int i = 0; i < data.detail!.length; i++)
//                       Column(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           SizedBox(
//                             width: SizeConfig.blockSizeHorizontal * 85,
//                             child: Text(
//                               ('${data.detail![i].code ?? ''} | ${data.detail![i].name ?? ''}')
//                                   .toUpperCase(),
//                               style: TextStyle(
//                                   fontSize: AppConfig.textCaption3Size,
//                                   fontWeight: AppConfig.headLineWeight),
//                             ),
//                           ),
//                           SizedBox(
//                             width: SizeConfig.blockSizeHorizontal * 85,
//                             child: Row(
//                               children: [
//                                 Text(
//                                   data.detail![i].productType ?? '',
//                                   style: TextStyle(
//                                     fontSize: AppConfig.textCaption3Size,
//                                   ),
//                                 ),
//                                 const Text(' | '),
//                                 Text(
//                                   data.detail![i].unit ?? '',
//                                   style: TextStyle(
//                                     fontSize: AppConfig.textCaption3Size,
//                                   ),
//                                 ),
//                                 const Text(' | '),
//                                 Text(
//                                   'Qty: ${data.detail![i].quantity}',
//                                   style: TextStyle(
//                                     fontSize: AppConfig.textCaption3Size,
//                                   ),
//                                 ),
//                                 const Text(' | '),
//                                 Text(
//                                   'Rate: ${data.detail![i].mrp}',
//                                   style: TextStyle(
//                                     fontSize: AppConfig.textCaption3Size,
//                                   ),
//                                 ),
//                                 const Text(' | '),
//                                 Text(
//                                   'Amount: ${data.detail![i].amount}',
//                                   style: TextStyle(
//                                     fontSize: AppConfig.textCaption3Size,
//                                   ),
//                                 )
//                               ],
//                             ),
//                           ),
//                           CommonWidgets.verticalSpace(1),
//                           (i == data.detail!.length - 1)
//                               ? Container()
//                               : Divider(
//                               color: AppConfig.buttonDeactiveColor
//                                   .withOpacity(0.4)),
//                         ],
//                       ),
//                   ],
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _getProducts() async {
//     RestDatasource api = RestDatasource();
//     dynamic resJson = await api.getDetails(
//         '/api/vansales_return.index?store_id=${AppState().storeId}&van_id=${AppState().vanId}&user_id=${AppState().userId}',
//         AppState().token); //
//     if (resJson['data'] != null) {
//       products = VanSaleProducts.fromJson(resJson);
//       print(AppState().storeId);
//       print(AppState().vanId);
//       print('ggggggggggggggggggggggggggggggggggggggggggggg');
//       setState(() {
//         _initDone = true;
//       });
//     } else {
//       setState(() {
//         _noData = true;
//         _initDone = true;
//       });
//     }
//   }
//
//   Future<void> _createPdf(Invoice.InvoiceData invoice, bool isPrint) async {
//     PdfDocument document = PdfDocument();
//     final page = document.pages.add();
//     final Size pageSize = page.getClientSize();
//
//     // Load the image.
//
//     final Uint8List imageData = await _readImageData(
//         invoice.data!.store![0].logo); //invoice.data!.store![0].logo
//     print(invoice.data!.store![0].logo);
//     if (imageData.isNotEmpty) {
//       final PdfBitmap image = PdfBitmap(imageData);
//
//       // Draw the image.
//       final Rect imageRect = Rect.fromCenter(
//         center: Offset(pageSize.width / 2, 50),
//         width: pageSize.width * 0.2, // Adjust width as per your requirement
//         height: pageSize.height * 0.1, // Adjust height as per your requirement
//       );
//       page.graphics.drawImage(image, imageRect);
//     }
//
//     //content
//     // page.graphics.drawString(
//     //     'TAX INVOICE', PdfStandardFont(PdfFontFamily.helvetica, 30));
//
//     //heading
//     final String head = '${invoice.data!.store![0].name}';
//     // Define the text and font
//     final double pageWidth = page.getClientSize().width;
//
//     final PdfFont headfont = PdfStandardFont(
//       PdfFontFamily.helvetica,
//       25,
//     );
//     final Size headtextSize = headfont.measureString(head);
//
//     final double headxPosition = (pageWidth - headtextSize.width) / 2.0;
//     final double headyPosition = 90;
//     page.graphics.drawString(
//       head,
//       headfont,
//       bounds: Rect.fromLTWH(headxPosition, headyPosition, headtextSize.width,
//           headtextSize.height),
//     );
//
//     final String addresss = '${invoice.data!.store![0].address ?? 'N/A'}';
//     final PdfFont addressfont = PdfStandardFont(PdfFontFamily.helvetica, 12);
//
//     final Size addresstextSize = addressfont.measureString(addresss);
//     final double addressxPosition = (pageWidth - addresstextSize.width) / 2.0;
//     final double addressyPosition = 120;
//
//     page.graphics.drawString(
//       addresss,
//       addressfont,
//       bounds: Rect.fromLTWH(addressxPosition, addressyPosition,
//           addresstextSize.width, addresstextSize.height),
//     );
//
//     final String email = '${invoice.data!.store![0].email ?? 'N/A'}';
//     final PdfFont emailfont = PdfStandardFont(PdfFontFamily.helvetica, 12);
//     final Size emailtextSize= emailfont.measureString(email);
//     final double emailxPosition = (pageWidth - emailtextSize.width) / 2.0;
//     final double emailyposition = 135;
//     page.graphics.drawString(
//       email,
//       emailfont,
//       bounds: Rect.fromLTWH(emailxPosition, emailyposition,
//           emailtextSize.width, emailtextSize.height),
//     );
//
//     final String trn = 'TRN:${invoice.data!.customer![0].trn ?? '  null'}';
//     final PdfFont trnfont = PdfStandardFont(PdfFontFamily.helvetica, 12);
//
//     final Size trntextSize = trnfont.measureString(trn);
//     final double trnxPosition = (pageWidth - trntextSize.width) / 2.1;
//     final double trnyPosition = 150;
//
//     page.graphics.drawString(
//       trn,
//       trnfont,
//       bounds: Rect.fromLTWH(
//           trnxPosition, trnyPosition, trntextSize.width, trntextSize.height),
//     );
//
//     final String text = 'TAX CREDIT NOTE';
//
//     final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 15);
//
//     // Calculate the width of the text
//     final Size textSize = font.measureString(text);
//
//     // Calculate the center position for the text
//     final double xPosition = (pageWidth - textSize.width) / 2;
//     final double yPosition = 165;
//
//     // Draw the centered text
//     page.graphics.drawString(
//       text,
//       font,
//       bounds:
//       Rect.fromLTWH(xPosition, yPosition, textSize.width, textSize.height),
//     );
//
//     // Draw a line below the text
//     final double lineYPosition =
//         yPosition + textSize.height + 10; // Adjust the gap as needed
//     page.graphics.drawLine(
//       PdfPen(PdfColor(0, 0, 0)), // Black pen
//       Offset(0, lineYPosition),
//       Offset(pageWidth, lineYPosition),
//     );
//
//     String address = '''
//   Customer: ${invoice.data!.customer![0].code} | ${invoice.data!.customer![0].name}
//   Email: ${invoice.data!.customer![0].email}
//   Contact No:  ${invoice.data!.customer![0].contactNumber}
//   TRN:  ${invoice.data!.customer![0].trn ?? ''}
//   ''';
//
//     String invoiceDetails = '''
//   Reference No: ${invoice.data!.invoiceNo!}
//   Date: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(invoice.data!.inDate!))}
//   Due Date: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(invoice.data!.inDate!))}
//   ''';
//
//     page.graphics.drawString(
//       address,
//       PdfStandardFont(PdfFontFamily.helvetica, 12),
//       bounds: Rect.fromLTWH(0, 200, pageSize.width / 2, 100),
//     );
//
//     page.graphics.drawString(
//       invoiceDetails,
//       PdfStandardFont(PdfFontFamily.helvetica, 12),
//       bounds: Rect.fromLTWH(pageSize.width / 2, 200, pageSize.width / 2, 100),
//       format: PdfStringFormat(
//         alignment: PdfTextAlignment.right,
//       ),
//     );
//
//     // Draw a horizontal line.
//     page.graphics.drawLine(
//       PdfPen(PdfColor(0, 0, 0)),
//       const Offset(0, 290),
//       Offset(pageSize.width, 290),
//     );
//
//     // Create a table without grid lines.
//     final PdfGrid grid = PdfGrid();
//     grid.columns.add(count: 9);
//     // Set column widths.
//     grid.columns[0].width = 30; // Sl.No
//     grid.columns[1].width = 180; // Product
//     grid.columns[2].width = 40; // Unit
//     grid.columns[3].width = 40; // Rate
//     grid.columns[4].width = 50; // Qty
//     grid.columns[5].width = 50; // Foc
//     grid.columns[6].width = 40; // Vat
//     grid.columns[7].width = 50;
//     grid.columns[8].width = 100;
//
//     // Add headers.
//     final PdfGridRow headerRow = grid.headers.add(1)[0];
//     headerRow.cells[0].value = 'Sl.No';
//     headerRow.cells[1].value = 'Product';
//     headerRow.cells[2].value = 'Unit';
//     headerRow.cells[3].value = 'Qty';
//     headerRow.cells[4].value = 'Type';
//     headerRow.cells[5].value = 'Rate';
//     headerRow.cells[6].value = 'Total';
//     headerRow.cells[7].value = 'Vat';
//     headerRow.cells[8].value = 'Amount';
//
//     for (int k = 0; k < invoice.data!.detail!.length; k++) {
//       final PdfGridRow row = grid.rows.add();
//       row.cells[0].value = '${k + 1}';
//       row.cells[1].value = '${invoice.data!.detail![k].name}';
//       row.cells[2].value = '${invoice.data!.detail![k].unit}';
//       row.cells[3].value = '${invoice.data!.detail![k].quantity}';
//       row.cells[4].value =
//       (invoice.data!.detail![k].productType!.toLowerCase() == "foc" ||
//           invoice.data!.detail![k].productType!.toLowerCase() == "FOC" ||
//           invoice.data!.detail![k].productType!.toLowerCase() == "Change")
//           ? 'Normal' : 'Normal';
//       row.cells[5].value = '${invoice.data!.detail![k].mrp}';
//       row.cells[6].value = '${invoice.data!.detail![k].taxable}';
//       row.cells[7].value = '${invoice.data!.detail![k].taxAmt}';
//       row.cells[8].value = '${invoice.data!.detail![k].amount}';
//     }
//
//     // Define no border style
//     final PdfBorders noBorder = PdfBorders(
//       left: PdfPen(PdfColor(255, 255, 255), width: 0),
//       top: PdfPen(PdfColor(255, 255, 255), width: 0),
//       right: PdfPen(PdfColor(255, 255, 255), width: 0),
//       bottom: PdfPen(PdfColor(255, 255, 255), width: 0),
//     );
//
//     // Remove borders from all header cells
//     for (int j = 0; j < grid.headers.count; j++) {
//       for (int k = 0; k < grid.headers[j].cells.count; k++) {
//         grid.headers[j].cells[k].style.borders = noBorder;
//       }
//     }
//
//     // Remove borders from all body cells
//     for (int i = 0; i < grid.rows.count; i++) {
//       for (int j = 0; j < grid.columns.count; j++) {
//         grid.rows[i].cells[j].style.borders = noBorder;
//       }
//     }
//
//     // Draw the table.
//     final PdfLayoutResult result = grid.draw(
//       page: page,
//       bounds: Rect.fromLTWH(0, 300, pageSize.width, pageSize.height - 180),
//     )!;
//
//     //   // Calculate the Y position for the line after the first row
//     // final double firstRowHeight = grid.headers[0].height + grid.rows[0].height;
//
//     // // Draw a line after the first row of the grid
//     // page.graphics.drawLine(
//     //   PdfPen(PdfColor(0, 0, 0), width: 1),
//     //   Offset(0, result.bounds.top + firstRowHeight),
//     //   Offset(pageSize.width, result.bounds.top + firstRowHeight),
//     // );
//     // Check if the table extends to the next page
//     PdfPage lastPage = result.page;
//     double tableBottom = result.bounds.bottom;
//
//     if (tableBottom >= pageSize.height) {
//       // Add a new page
//       lastPage = document.pages.add();
//       tableBottom = 0;
//     }
//
//     // Draw a horizontal line after the table.
//     lastPage.graphics.drawLine(
//       PdfPen(PdfColor(0, 0, 0)),
//       Offset(0, tableBottom + 15),
//       Offset(pageSize.width, tableBottom + 15),
//     );
//
//     // Draw invoice details at the bottom right.
//     // ${num.parse(invoice.data!.roundOff.toString()) != 0 ? 'Discount: ${invoice.data!.discount}' : '\t'}
//     String bottomInvoiceDetails = '''
//   ${invoice.data!.discount != null && invoice.data!.discount! > 0 ? 'Discount: ${invoice.data!.discount!.toStringAsFixed(AppState().noOfDecimals ?? 2)}' : '\t'}
//
//   Total: ${invoice.data!.total}
//   Tax: ${invoice.data!.totalTax}
//   ${num.parse(invoice.data!.roundOff.toString()) != 0 ? 'Round off: ${invoice.data!.roundOff}\nGrand Total: ${invoice.data!.grandTotal}' : 'Grand Total: ${invoice.data!.grandTotal}'}
//
//
//   ''';
//
//     lastPage.graphics.drawString(
//       bottomInvoiceDetails,
//       PdfStandardFont(PdfFontFamily.helvetica, 12),
//       bounds: Rect.fromLTWH(
//         pageSize.width / 2,
//         tableBottom + 20,
//         pageSize.width / 2,
//         100,
//       ),
//       format: PdfStringFormat(
//         alignment: PdfTextAlignment.right,
//       ),
//     );
//
//     String textData =
//         'Amount in Words: ${NumberToWord().convert('en-in', invoice.data!.grandTotal!.toInt()).toUpperCase()}';
//
// // Adjust the vertical position for the van details
//     double vanDetailsTop = tableBottom + 20 + 100 + 10;
//
// // Construct the van details string.
//     String bottomVanDetails = '''
// Van: ${invoice.data!.van![0].name}
// Salesman: ${invoice.data!.user![0].name}
// ''';
//
//     lastPage.graphics.drawString(
//       textData,
//       PdfStandardFont(PdfFontFamily.helvetica, 12),
//       bounds: Rect.fromLTWH(
//         0,
//         vanDetailsTop -
//             20, // Adjust vertical position to be above the van details
//         pageSize.width,
//         100,
//       ),
//       format: PdfStringFormat(
//         alignment: PdfTextAlignment.center,
//       ),
//     );
// // Draw van details at the bottom left.
//     lastPage.graphics.drawString(
//       bottomVanDetails,
//       PdfStandardFont(PdfFontFamily.helvetica, 12),
//       bounds: Rect.fromLTWH(
//         0,
//         vanDetailsTop,
//         pageSize.width / 2,
//         100,
//       ),
//       format: PdfStringFormat(
//         alignment: PdfTextAlignment.left,
//       ),
//     );
//     List<int> bytes = await document.save();
//     document.dispose();
//
//     String file = await saveAndLaunchFile(
//         bytes, '${invoice.data!.invoiceNo!}.pdf', isPrint);
//   }
//
//
//   void _print(Invoice.InvoiceData invoice, bool isPrint) async {
//     if (_connected) {
//       String companyName = invoice.data!.store![0].name ?? 'N/A';
//       String companyAddress = invoice.data!.store![0].address ?? 'N/A';
//       String companyMail = invoice.data!.store![0].email??'N/A';
//       String companyTRN = "TRN: ${invoice.data!.store![0].trn ?? 'N/A'}";
//       String billtype = "TAX CREDIT NOTE";
//       String customerName = "${invoice.data!.customer![0].name}";
//       List<String> nameWords = customerName.split(' ');
//       String firstLine = customerName;
//       String secondLine = "";
//       if (nameWords.length > 4) {
//         firstLine = nameWords.sublist(0, 4).join(' ');
//         secondLine = nameWords.sublist(4).join(' ');
//       }
//       String customerEmail = invoice.data!.customer![0].email ?? 'N/A';
//       String customerContact =
//           invoice.data!.customer![0].contactNumber ?? 'N/A';
//       String customerTRN = invoice.data!.customer![0].trn ?? '';
//       String invoiceNumber = invoice.data!.invoiceNo ?? 'N/A';
//       String invoiceDate = DateFormat('dd MMMM yyyy')
//           .format(DateTime.parse(invoice.data!.inDate!));
//       String dueDate = DateFormat('dd MMMM yyyy')
//           .format(DateTime.parse(invoice.data!.inDate!));
//       String Total = invoice.data!.total?.toStringAsFixed(AppState().noOfDecimals ?? 2)??'0.00';
//       String tax = invoice.data!.totalTax?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//       String grandTotal =
//           invoice.data!.grandTotal?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//       String Discount;
//       if (invoice.data!.discount != null &&
//           double.tryParse(invoice.data!.discount!.toString()) != null &&
//           double.parse(invoice.data!.discount!.toString()) > 0) {
//
//         Discount = "Discount: ${double.parse(invoice.data!.discount!.toString()).toStringAsFixed(AppState().noOfDecimals ?? 2)}";
//       } else {
//         Discount = '';
//       }
//       String amountInWords =
//           "Amount in Words: AED ${NumberToWord().convert('en-in', invoice.data!.grandTotal?.toInt() ?? 0).toUpperCase()} ONLY";
//       String van = invoice.data!.van![0].name ?? 'N/A';
//       String salesman = invoice.data!.user![0].name ?? 'N/A';
//
//       void printAlignedText(String leftText, String rightText) {
//         const int maxLineLength =
//         68; // Adjust the maximum line length as per your printer's character limit
//         int leftTextLength = leftText.length;
//         int rightTextLength = rightText.length;
//
//         // Calculate padding to ensure rightText is right-aligned
//         int spaceLength = maxLineLength - (leftTextLength + rightTextLength);
//         String spaces = ' ' * spaceLength;
//
//         printer.printCustom(
//             '$leftText$spaces$rightText', 1, 0); // Print with left-aligned text
//       }
//
//       String logoUrl =
//           'http://68.183.92.8:3697/uploads/store/${invoice.data!.store![0].logo}';
//       if (logoUrl.isNotEmpty) {
//         final response = await http.get(Uri.parse(logoUrl));
//         if (response.statusCode == 200) {
//           Uint8List imageBytes = response.bodyBytes;
//
//           // Decode image and convert to monochrome bitmap if needed
//           img.Image originalImage = img.decodeImage(imageBytes)!;
//           img.Image monoLogo = img.grayscale(originalImage);
//
//           // Encode the image to the required format (e.g., PNG)
//           Uint8List logoBytes = Uint8List.fromList(img.encodePng(monoLogo));
//
//           // Print the logo image
//           printer.printImageBytes(logoBytes);
//         } else {
//           print('Failed to load image: ${response.statusCode}');
//         }
//       }
//       // Print company details
//       printer.printNewLine();
//       printer.printCustom(companyName, 3, 1); // Centered
//       printer.printCustom(companyAddress, 1, 1); // Centered
//       printer.printCustom(companyMail, 1, 1);
//       printer.printCustom(companyTRN, 1, 1); // Centered
//       printer.printCustom(billtype, 1, 1); // Centered
//       printer.printNewLine();
//
//       // Print horizontal line
//       printer.printCustom("-" * 72, 1, 1); // Centered
//
//       // Print customer details
//       printAlignedText(
//           "Customer: $firstLine", "Reference No: $invoiceNumber      ");
//
//       if (secondLine.isNotEmpty) {
//         printAlignedText("         $secondLine", ""); // Aligns the second line under the first line
//       }
//       printAlignedText("Email: $customerEmail", "Date: $invoiceDate    ");
//       printAlignedText("Contact No: $customerContact", "Due Date: $dueDate");
//       printAlignedText("TRN: $customerTRN", " ");
//       printer.printNewLine();
//
//       // Print horizontal line
//       printer.printCustom("-" * 70, 1, 1); // Centered
//
//       // Define column widths for table
//       const int columnWidth1 = 5; // S.No
//       const int columnWidth2 = 22; // Product Description
//       const int columnWidth3 = 5; // Unit
//       const int columnWidth4 = 4; // Qty
//       const int columnWidth5 = 7; // Type
//       const int columnWidth6 = 8; // Rate
//       const int columnWidth7 = 8; // Total
//       // const int columnWidth8 = 4; // Tax
//       const int columnWidth9 = 6; // Amount
//
//       // Print table headers
//       String headers = "${'S.No'.padRight(columnWidth1)}"
//           " ${'Product'.padRight(columnWidth2)}"
//           " ${'Unit'.padRight(columnWidth3)}"
//           "${'Qty'.padRight(columnWidth4)}"
//           "${'Type'.padRight(columnWidth5)}"
//           "${'Rate'.padRight(columnWidth6)}"
//           "${'Amount'.padRight(columnWidth7)}"
//       // "${'Vat'.padRight(columnWidth8)}"
//           " ${'Total'.padLeft(columnWidth9)}";
//       printer.printCustom(headers, 1, 0); // Left aligned
//
//       // Function to split text into lines of a given width
//       List<String> splitText(String text, int width) {
//         List<String> lines = [];
//         while (text.length > width) {
//           lines.add(text.substring(0, width));
//           text = text.substring(width);
//         }
//         lines.add(text); // Add remaining part
//         return lines;
//       }
//
//       // Print all product details
//       for (int i = 0; i < invoice.data!.detail!.length; i++) {
//         String productDescription = invoice.data!.detail![i].name ?? 'N/A';
//         String productUnit = invoice.data!.detail![i].unit ?? 'N/A';
//         String productQty = invoice.data!.detail![i].quantity?.toString() ?? '0';
//         String productType= invoice.data!.detail![i].productType?.toString()??'0';
//         String productRate = invoice.data!.detail![i].mrp?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//         String productTotal = invoice.data!.detail![i].taxable?.toStringAsFixed(AppState().noOfDecimals ?? 2) ?? '0.00';
//         // String productTax = tax.toString();
//         String productAmount =invoice.data!.detail![i].amount?.toStringAsFixed(AppState().noOfDecimals ?? 2)??'0.00';
//         // (invoice.data!.detail![i].mrp! * invoice.data!.detail![i].quantity!)
//         //     .toStringAsFixed(AppState().noOfDecimals ?? 2);
//
//         // Split the product description if it exceeds the column width
//         List<String> descriptionLines =
//         splitText(productDescription, columnWidth2);
//
//         for (int j = 0; j < descriptionLines.length; j++) {
//           String line;
//           if (j == 0) {
//             // For the first line, include all columns
//             line = "${(i + 1).toString().padRight(columnWidth1)}"
//                 "${descriptionLines[j].padRight(columnWidth2)}"
//                 "  ${productUnit.padRight(columnWidth3)}"
//                 "${productQty.padRight(columnWidth4)}"
//                 "${productType.padRight(columnWidth5)}"
//                 "${productRate.padRight(columnWidth6)}"
//                 "${productTotal.padRight(columnWidth7)}"
//             // "${productTax.padRight(columnWidth8)}"
//                 "${productAmount.padLeft(columnWidth9)}";
//           } else {
//             // For subsequent lines, only include the description, leaving other columns blank
//             line = "${''.padRight(columnWidth1)}"
//                 "${descriptionLines[j].padRight(columnWidth2)}"
//                 "${''.padRight(columnWidth3)}"
//                 "${''.padRight(columnWidth4)}"
//                 "${''.padRight(columnWidth5)}"
//                 "${''.padRight(columnWidth6)}"
//                 "${''.padRight(columnWidth7)}";
//             // "${''.padRight(columnWidth8)}";
//             "${''.padRight(columnWidth9)}";
//           }
//           printer.printCustom(line, 1, 0); // Left aligned
//         }
//       }
//       printer.printCustom("-" * 70, 1, 1); // Centered
//
//       // Print totals
//       if (Discount.isNotEmpty) {
//         print(Discount);
//         printAlignedText("Van: $van", "$Discount");
//       } else {
//         printAlignedText("Van: $van", ""); // Skip printing Total
//       }
//       printAlignedText("Salesman: $salesman", "Total: $Total");
//       printer.printCustom("Tax: $tax", 1, 2);
//       printer.printCustom("Grand Total: $grandTotal", 1, 2); // Right aligned
//       printer.printNewLine();
//       printer.printCustom(amountInWords, 1, 0); // Centered
//
//       // Cut the paper
//       printer.paperCut();
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Printer not connected')),
//       );
//     }
//   }
//
//   Future<Uint8List> _readImageData(String? image) async {
//     try {
//       final response = await http
//           .get(Uri.parse('https://mobiz.yes45.in/uploads/store/$image'));
//
//       print('Response Data $response');
//
//       if (response.statusCode == 200) {
//         return response.bodyBytes;
//       } else {
//         throw Exception('Failed to load image');
//       }
//     } catch (e) {
//       // Log the error and return an empty Uint8List
//       print('Error loading image: $e');
//       return Uint8List(0);
//     }
//   }
//
//   Future<void> _getInvoiceData(int id, bool isPrint) async {
//     Invoice.InvoiceData invoice = Invoice.InvoiceData();
//     RestDatasource api = RestDatasource();
//     dynamic response = await api.getDetails(
//         '/api/get_sales_return_invoice?id=$id', AppState().token);
//
//     if (response['data'] != null) {
//       invoice = Invoice.InvoiceData.fromJson(response);
//       _createPdf(invoice, isPrint);
//     }
//   }
//   Future<void> _getInvoicePrint(int id, bool isPrint) async {
//     Invoice.InvoiceData invoice = Invoice.InvoiceData();
//     RestDatasource api = RestDatasource();
//     dynamic response = await api.getDetails(
//         '/api/get_sales_return_invoice?id=$id', AppState().token);
//
//     if (response['data'] != null) {
//       invoice = Invoice.InvoiceData.fromJson(response);
//       _print(invoice, isPrint);
//     }
//     if (_selectedDevice == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Default device not found')),
//       );
//       return;
//     }
//     if (!_connected) {
//       await _connect();
//     }
//     // _print(invoice, isPrint);
//   }
// }
