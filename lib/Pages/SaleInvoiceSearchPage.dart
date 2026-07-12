// import 'dart:convert';
// import '../Models/invoicedata.dart' as Invoice;
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart'as http;
// import 'package:intl/intl.dart';
// import 'package:shimmer/shimmer.dart';
// import '../Components/commonwidgets.dart';
// import '../Models/appstate.dart';
// import '../Utilities/rest_ds.dart';
// import '../confg/appconfig.dart';
// import '../confg/sizeconfig.dart';
// import 'TestInvoice.dart';
//
// class SaleInvoiceSearchPage extends StatefulWidget {
//   static const routeName = "/SaleInvoiceSearch";
//   const SaleInvoiceSearchPage({super.key});
//
//   @override
//   _SaleInvoiceSearchPageState createState() => _SaleInvoiceSearchPageState();
// }
//
// class _SaleInvoiceSearchPageState extends State<SaleInvoiceSearchPage> {
//   List<VanSale> searchResults = [];
//   bool isLoading = false;
//   int currentPage = 1;
//   bool hasNextPage = true;
//   final TextEditingController _searchController = TextEditingController();
//   bool _noData = false;
//   bool _initDone = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(_onSearchChanged);
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void _onSearchChanged() {
//     if (_searchController.text.isEmpty) {
//       setState(() {
//         searchResults.clear();
//       });
//     } else {
//       _fetchSearchResults(_searchController.text, 1);
//     }
//   }
//
//   Future<void> _fetchSearchResults(String query, int page) async {
//     if (isLoading || !hasNextPage) return;
//
//     setState(() {
//       if (page == 1) {
//         searchResults.clear();
//       }
//       isLoading = true;
//     });
//
//     final url = '${RestDatasource().BASE_URL}/api/vansale.index.search?'
//         'store_id=${AppState().storeId}&'
//         'van_id=${AppState().vanId}&'
//         'user_id=${AppState().userId}&'
//         'page=$page&'
//         'value=$query';
//
//     try {
//       final response = await http.get(Uri.parse(url));
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final vanSaleResponse = VanSaleResponse.fromJson(data);
//
//         setState(() {
//           searchResults.addAll(vanSaleResponse.data!.vanSales);
//           currentPage = page + 1;
//           hasNextPage = vanSaleResponse.data!.nextPageUrl.isNotEmpty;
//           isLoading = false;
//           _initDone = true;
//         });
//       } else {
//         setState(() {
//           _noData = true;
//           _initDone = true;
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _noData = true;
//         _initDone = true;
//         isLoading = false;
//       });
//     }
//   }
//
//   bool _onScrollNotification(ScrollNotification notification) {
//     if (notification is ScrollEndNotification &&
//         notification.metrics.pixels == notification.metrics.maxScrollExtent &&
//         _searchController.text.isNotEmpty) {
//       _fetchSearchResults(_searchController.text, currentPage);
//     }
//     return false;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: TextField(
//           controller: _searchController,
//           autofocus: true,
//           decoration: InputDecoration(
//             hintText: 'Search by invoice or customer...',
//             border: InputBorder.none,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.close),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ],
//       ),
//       body: NotificationListener<ScrollNotification>(
//         onNotification: _onScrollNotification,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 10.0),
//           child: Column(
//             children: [
//               if (_initDone && searchResults.isEmpty && _searchController.text.isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Text('No results found'),
//                 ),
//               Expanded(
//                 child: (_initDone && !_noData)
//                     ? ListView.separated(
//                   separatorBuilder: (BuildContext context, int index) =>
//                       CommonWidgets.verticalSpace(1),
//                   itemCount: searchResults.length + (isLoading ? 1 : 0),
//                   shrinkWrap: true,
//                   itemBuilder: (context, index) {
//                     if (index == searchResults.length) {
//                       return isLoading
//                           ? const Center(
//                           child: Text(
//                             "Loading...",
//                             style: TextStyle(
//                                 fontStyle: FontStyle.italic,
//                                 color: Colors.grey),
//                           ))
//                           : Center(
//                         child: Text(
//                           "That's All",
//                           style: TextStyle(
//                               fontStyle: FontStyle.italic,
//                               color: Colors.grey.shade400,
//                               fontWeight: FontWeight.w700),
//                         ),
//                       );
//                     }
//                     return _productsCard(searchResults[index], index);
//                   },
//                 )
//                     : (_noData && _initDone)
//                     ? Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       CommonWidgets.verticalSpace(3),
//                       const Center(
//                         child: Text('No Data'),
//                       ),
//                     ])
//                     : Shimmer.fromColors(
//                   baseColor:
//                   AppConfig.buttonDeactiveColor.withOpacity(0.1),
//                   highlightColor: AppConfig.backButtonColor,
//                   child: Center(
//                     child: Column(
//                       children: [
//                         CommonWidgets.loadingContainers(
//                             height: SizeConfig.blockSizeVertical * 10,
//                             width:
//                             SizeConfig.blockSizeHorizontal * 90),
//                         CommonWidgets.loadingContainers(
//                             height: SizeConfig.blockSizeVertical * 10,
//                             width:
//                             SizeConfig.blockSizeHorizontal * 90),
//                       ],
//                     ),
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
//   Widget _productsCard(VanSale data, int index) {
//     String _formatName(String name) {
//       List<String> words = name.split(' '); // Split the name into words
//       if (words.length > 5) {
//         // Join the first 5 words and place the rest on a new line
//         return words.sublist(0, 5).join(' ') +
//             '\n' +
//             words.sublist(5).join(' ');
//       } else {
//         // If less than or equal to 5 words, return the name as is
//         return name;
//       }
//     }
//
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
//                         SizedBox(
//                           width: 14,
//                         ),
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
//                                 ? Colors.red // Color for Cancelled
//                                 : data.status == 1
//                                 ? Colors.green // Color for Confirmed
//                                 : Colors
//                                 .grey, // Default color for unknown status
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     Text(
//                       (data.customer != null && data.customer!.isNotEmpty)
//                           ? data.customer![0].code ?? ''
//                           : '',
//                       style: TextStyle(
//                         fontSize: AppConfig.textCaption3Size,
//                         fontWeight: AppConfig.headLineWeight,
//                       ),
//                     ),
//                     Text(' | '),
//                     Text(
//                       (data.customer != null && data.customer!.isNotEmpty)
//                           ? _formatName(data.customer![0].name ?? '')
//                           : '',
//                       style: TextStyle(
//                         fontSize: AppConfig.textCaption3Size,
//                         fontWeight: AppConfig.headLineWeight,
//                       ),
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
//                     // const Spacer(),
//                     // InkWell(
//                     //   onTap: () {
//                     //     _getInvoiceDataprint(data.id!, false);
//                     //     print(data.id);
//                     //   },
//                     //   child: const Icon(
//                     //     Icons.print,
//                     //     color: Colors.blue,
//                     //     size: 30,
//                     //   ),
//                     // ),
//                     // CommonWidgets.horizontalSpace(2),
//                     // AppState().printer == "Wifi"
//                     //     ? InkWell(
//                     //   onTap: () => _getwifiInvoiceData(data.id!, false),
//                     //   child: const Icon(
//                     //     Icons.document_scanner,
//                     //     color: Colors.green,
//                     //     size: 30,
//                     //   ),
//                     // )
//                     //     : SizedBox.shrink(),
//                     // CommonWidgets.horizontalSpace(2),
//                     // InkWell(
//                     //   onTap: () => _getInvoiceData(data.id!, false),
//                     //   child: const Icon(
//                     //     Icons.document_scanner,
//                     //     color: Colors.red,
//                     //     size: 30,
//                     //   ),
//                     // ),
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
//   // Future<void> _getInvoiceData(int id, bool isPrint) async {
//   //   Invoice.InvoiceData invoice = Invoice.InvoiceData();
//   //   RestDatasource api = RestDatasource();
//   //   dynamic response =
//   //   await api.getDetails('/api/get_sales_invoice?id=$id', AppState().token);
//   //   if (response['data'] != null) {
//   //     print("DDDDDD${id}");
//   //     invoice = Invoice.InvoiceData.fromJson(response);
//   //     _createPdf(invoice, isPrint);
//   //   }
//   //   // if (_selectedDevice == null) {
//   //   //   ScaffoldMessenger.of(context).showSnackBar(
//   //   //     SnackBar(content: Text('Default device not found')),
//   //   //   );
//   //   //   return;
//   //   // }
//   //   // if (!_connected) {
//   //   //   await _connect();
//   //   // }
//   //   // _print(invoice, isPrint);
//   // }
//
//   // Future<void> _getwifiInvoiceData(int id, bool isPrint) async {
//   //   Invoice.InvoiceData invoice = Invoice.InvoiceData();
//   //   RestDatasource api = RestDatasource();
//   //   dynamic response =
//   //   await api.getDetails('/api/get_sales_invoice?id=$id', AppState().token);
//   //   if (response['data'] != null) {
//   //     print("DDDDDD${id}");
//   //     invoice = Invoice.InvoiceData.fromJson(response);
//   //     _wifiPdf(invoice, isPrint);
//   //   }
//   //   // if (_selectedDevice == null) {
//   //   //   ScaffoldMessenger.of(context).showSnackBar(
//   //   //     SnackBar(content: Text('Default device not found')),
//   //   //   );
//   //   //   return;
//   //   // }
//   //   // if (!_connected) {
//   //   //   await _connect();
//   //   // }
//   //   // _print(invoice, isPrint);
//   // }
//
//   // Future<void> _getInvoiceDataprint(int id, bool isPrint) async {
//   //   Invoice.InvoiceData invoice = Invoice.InvoiceData();
//   //   RestDatasource api = RestDatasource();
//   //   dynamic response =
//   //   await api.getDetails('/api/get_sales_invoice?id=$id', AppState().token);
//   //
//   //   if (response['data'] != null) {
//   //     print("IIDD$id");
//   //     invoice = Invoice.InvoiceData.fromJson(response);
//   //     // _createPdf(invoice, isPrint);
//   //   }
//   //   if (_selectedDevice == null) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Default device not found')),
//   //     );
//   //     return;
//   //   }
//   //   if (!_connected) {
//   //     await _connect();
//   //   }
//   //   _print(invoice, isPrint);
//   // }
// }