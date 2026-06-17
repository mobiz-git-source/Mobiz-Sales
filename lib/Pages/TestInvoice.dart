import 'dart:async';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:number_to_words/number_to_words.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:convert';
import '../Models/appstate.dart';
import '../Models/invoicedata.dart' as Invoice;
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import '../Components/commonwidgets.dart';
import '../Models/invoicedata.dart';
import '../Models/invoicedata.dart';
import '../Models/pdfgenerate.dart';
import '../Models/productquantirydetails.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'SaleInvoiceSearchPage.dart';

class SaleInvoiceScrreen extends StatefulWidget {
  static const routeName = "/SalreInvoice";
  const SaleInvoiceScrreen({super.key});
  @override
  _SaleInvoiceScrreenState createState() => _SaleInvoiceScrreenState();
}

class _SaleInvoiceScrreenState extends State<SaleInvoiceScrreen> {
  List<VanSale> vanSales = [];
  List<VanSale> filteredVanSales = [];
  bool isLoading = false;
  int currentPage = 1; // Track the current page number
  VanSaleResponse products = VanSaleResponse();
  bool hasNextPage = true; // Flag to check if there's another page to load
  final TextEditingController _searchController  = TextEditingController();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  bool _initDone = false;
  bool _noData = false;
  bool _isSearching = false;
  Timer? _searchDebounce;
  bool _hasMore = true;
  List<int> selectedItems = [];
  List<Map<String, dynamic>> items = [];
  bool _search = false;
  int? customerId;

  int? id;
  String? name;

  @override
  void initState() {
    super.initState();
    // _fetchVanSales(currentPage);
    _fetchVanSales(currentPage);
    _initPrinter();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text.trim());
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

  // Future<void> _getProducts(int page) async {
  //   if (isLoading || !hasNextPage) return;
  //   RestDatasource api = RestDatasource();
  //   dynamic resJson = await api.getDetails(
  //       '/api/vansale.index?store_id=${AppState().storeId}&van_id=${AppState().vanId}&user_id=${AppState().userId}',
  //       AppState().token); //
  //
  //   if (resJson['data'] != null) {
  //     products = VanSaleResponse.fromJson(resJson);
  //     setState(() {
  //       _initDone = true;
  //       vanSales.addAll(products.data!.vanSales);
  //       currentPage++; // Increment the current page after a successful fetch
  //       hasNextPage = products.data!.nextPageUrl.isNotEmpty; // Check if there's a next page
  //       isLoading = false;
  //     });
  //   } else {
  //     setState(() {
  //       _noData = true;
  //       _initDone = true;
  //       isLoading = false;
  //     });
  //   }
  // }

  // _fetchVanSales(int page) async {
  //   if (isLoading || !hasNextPage)
  //     return; // Prevent duplicate requests and avoid making requests if there's no next page
  //
  //   setState(() {
  //     isLoading = true;
  //   });
  //
  //   final url =
  //       '${RestDatasource().BASE_URL}/api/vansale.index?store_id=${AppState().storeId}&van_id=${AppState().vanId}&user_id=${AppState().userId}&page=$page'; // Use dynamic page number
  //
  //   final response = await http.get(Uri.parse(url));
  //
  //   if (response.statusCode == 200) {
  //     print(response.request);
  //     VanSaleResponse vanSaleResponse =
  //         VanSaleResponse.fromJson(json.decode(response.body));
  //
  //     setState(() {
  //       vanSales.addAll(vanSaleResponse.data!.vanSales);
  //       currentPage++; // Increment the current page after a successful fetch
  //       hasNextPage = vanSaleResponse
  //           .data!.nextPageUrl.isNotEmpty; // Check if there's a next page
  //       isLoading = false;
  //       _initDone = true;
  //     });
  //   } else {
  //     setState(() {
  //       _noData = true;
  //       _initDone = true;
  //       isLoading = false;
  //     });
  //     throw Exception('Failed to load data');
  //   }
  // }

  // Replace your existing search-related methods with these:

  void _onSearchChanged(String query) {
    setState(() {
      currentPage = 1;
      _hasMore = true;
      vanSales.clear();
      _isSearching = query.isNotEmpty;
    });

    // Only fetch data if the query is non-empty, otherwise load regular data
    if (query.isEmpty) {
      _fetchVanSales(currentPage); // Regular fetch for all sales
    } else {
      _fetchVanSales(currentPage, searchQuery: query); // Fetch with search query
    }
  }


  Future<void> _fetchVanSales(int page, {String? searchQuery}) async {
    if (isLoading || !hasNextPage) return;

    setState(() {
      isLoading = true;
    });

    try {
      final Uri apiUrl;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        apiUrl = Uri.parse(
            "${RestDatasource().BASE_URL}/api/vansale.index.search?"
                "store_id=${AppState().storeId}&"
                "van_id=${AppState().vanId}&"
                "user_id=${AppState().userId}&"
                "page=$page&"
                "value=$searchQuery");
      } else {
        apiUrl = Uri.parse(
            "${RestDatasource().BASE_URL}/api/vansale.index?"
                "store_id=${AppState().storeId}&"
                "van_id=${AppState().vanId}&"
                "user_id=${AppState().userId}&"
                "page=$page");
      }

      final http.Response response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        print(response.request);
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final VanSaleResponse vanSaleResponse = VanSaleResponse.fromJson(responseData);

        setState(() {
          vanSales.addAll(vanSaleResponse.data!.vanSales);
          _hasMore = vanSaleResponse.data!.nextPageUrl.isNotEmpty;
          if (vanSaleResponse.data!.vanSales.isNotEmpty) {
            currentPage++;
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
        isLoading = false;
        _initDone = true;
      });
    }
  }

// Remove the _fetchVanSalessearch method completely as it's now merged with _fetchVanSales

  // Detect when the user scrolls to the bottom
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification &&
        notification.metrics.pixels == notification.metrics.maxScrollExtent &&
        !isLoading &&
        _hasMore) {
      _fetchVanSales(
        currentPage,
        searchQuery: _isSearching ? _searchController.text : null,
      );
    }
    return false;
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
            autofocus: true,
          // controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by invoice or customer...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white),
            onChanged: (value) {
              // Cancel any ongoing debounce timer to reset it
              _searchDebounce?.cancel();

              // Start a new debounce timer to avoid calling search too often
              _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                // Only trigger search if the query is different from the previous one
                if (value.isNotEmpty) {
                  _onSearchChanged(value);
                } else {
                  // If the search query is empty, reload all data
                  _onSearchChanged("");
                }
              });
            }
        )
            : const Text(
          'Sales Invoice',
          style: TextStyle(color: AppConfig.backgroundColor),
        ),
        backgroundColor: AppConfig.colorPrimary,
        actions: [
          IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _searchController.clear();
                    // _onSearchChanged(); // This will trigger the fetch
                  } else {
                    _isSearching = true;
                  }
                });
              }
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            children: [
              if (_isSearching && vanSales.isEmpty && _searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('No results found'),
                ),
              Expanded(
                child: (_initDone && !_noData)
                    ? ListView.separated(
                  separatorBuilder: (BuildContext context, int index) =>
                      CommonWidgets.verticalSpace(1),
                  itemCount: vanSales.length + (isLoading ? 1 : 0),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    if (index == vanSales.length) {
                      return isLoading
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
                    return _productsCard(vanSales[index], index);
                  },
                )
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
                            width:
                            SizeConfig.blockSizeHorizontal * 90),
                        CommonWidgets.loadingContainers(
                            height: SizeConfig.blockSizeVertical * 10,
                            width:
                            SizeConfig.blockSizeHorizontal * 90),
                        CommonWidgets.loadingContainers(
                            height: SizeConfig.blockSizeVertical * 10,
                            width:
                            SizeConfig.blockSizeHorizontal * 90),
                        CommonWidgets.loadingContainers(
                            height: SizeConfig.blockSizeVertical * 10,
                            width:
                            SizeConfig.blockSizeHorizontal * 90),
                        CommonWidgets.loadingContainers(
                            height: SizeConfig.blockSizeVertical * 10,
                            width:
                            SizeConfig.blockSizeHorizontal * 90),
                        CommonWidgets.loadingContainers(
                            height: SizeConfig.blockSizeVertical * 10,
                            width:
                            SizeConfig.blockSizeHorizontal * 90),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productsCard(VanSale data, int index) {
    String _formatName(String name) {
      List<String> words = name.split(' '); // Split the name into words
      if (words.length > 5) {
        // Join the first 5 words and place the rest on a new line
        return words.sublist(0, 5).join(' ') +
            '\n' +
            words.sublist(5).join(' ');
      } else {
        // If less than or equal to 5 words, return the name as is
        return name;
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
            trailing: SizedBox.shrink(),
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
                        SizedBox(
                          width: 14,
                        ),
                        Text(
                          data.status == 0
                              ? "Cancelled"
                              : data.status == 1
                                  ? "Confirmed"
                                  : "",
                          style: TextStyle(
                            fontSize: AppConfig.textCaption3Size,
                            fontWeight: AppConfig.headLineWeight,
                            color: data.status == 0
                                ? Colors.red
                                : data.status == 1
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                        ),
                      ],
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
                (data.detail!.isNotEmpty)
                    // ? Text(
                    //     'Type: ${data.detail![0].productType}',
                    //     style: TextStyle(
                    //       fontSize: AppConfig.textCaption3Size,
                    //     ),
                    //   )

                    ? Text(
                        'Total: ${data.total?.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppConfig.textCaption3Size,
                        ),
                      )
                    : Text(
                        'Type:  ',
                        style: TextStyle(
                          fontSize: AppConfig.textCaption3Size,
                        ),
                      ),
                data.discount_type == '0'
                    ? Text(
                        'Discount : ${data.discount?.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: AppConfig.textCaption3Size,
                        ),
                      )
                    : data.discount_type == '1'
                        ? Text(
                            'Discount(%): ${data.discount?.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: AppConfig.textCaption3Size,
                            ),
                          )
                        : SizedBox.shrink(),
                Row(
                  children: [
                    Text(
                      'Round off:${double.parse(data.roundOff ?? '').toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: AppConfig.textCaption3Size,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        _getInvoiceDataprint(data.id!, false);
                        print(data.id);
                      },
                      child: const Icon(
                        Icons.print,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                    CommonWidgets.horizontalSpace(2),
                    AppState().printer == "Wifi"
                        ? InkWell(
                            onTap: () => _getwifiInvoiceData(data.id!, false),
                            child: const Icon(
                              Icons.document_scanner,
                              color: Colors.green,
                              size: 30,
                            ),
                          )
                        : SizedBox.shrink(),
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
                Text(
                  'Total Vat: ${(data.totalTax?.toStringAsFixed(2)) ?? ''}',
                  style: TextStyle(
                    fontSize: AppConfig.textCaption3Size,
                  ),
                ),
                Text(
                  'Grand Total: ${data.grandTotal?.toStringAsFixed(2)}',
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
                                  'Amount: ${data.detail![i].taxable?.toStringAsFixed(2)}',
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

  void _print(Invoice.InvoiceData invoice, bool isPrint) async {
    if (_connected) {
      final String? name = invoice.data!.store![0].invoice_heading ?? '';
      String cusAddress = invoice.data!.customer![0].address ?? 'N/A';
      String companyName = invoice.data!.store![0].invoice_company_name ?? 'N/A';
      String companyAddress = invoice.data!.store![0].address ?? 'N/A';
      String companyMail = invoice.data!.store![0].email ?? 'N/A';
      String companyTRN = "TRN: ${invoice.data!.store![0].trn ?? 'N/A'}";
      String billtype = "$name";
      String customerName = "${invoice.data!.customer![0].name}";
      List<String> nameWords = customerName.split(' ');
      String firstLine = customerName;
      String secondLine = "";
      if (nameWords.length > 7) {
        firstLine = nameWords.sublist(0, 7).join(' ');
        secondLine = nameWords.sublist(7).join(' ');
      }
      String customerEmail = invoice.data!.customer![0].email ?? 'N/A';
      String customerContact =
          invoice.data!.customer![0].contactNumber ?? 'N/A';
      String customerTRN = invoice.data!.customer![0].trn ?? '';
      String invoiceNumber = invoice.data!.invoiceNo ?? 'N/A';
      String invoiceDate = DateFormat('dd MMMM yyyy')
          .format(DateTime.parse(invoice.data!.inDate!));
      String dueDate = DateFormat('dd MMMM yyyy')
          .format(DateTime.parse(invoice.data!.inDate!));
      String Total = invoice.data!.total?.toStringAsFixed(2) ?? '0.00';
      String tax = invoice.data!.totalTax?.toStringAsFixed(2) ?? '0.00';
      String grandTotal =
          invoice.data!.grandTotal?.toStringAsFixed(2) ?? '0.00';
      final remarks = invoice.data?.remarks;
      String Discount;
      if (invoice.data!.discount != null &&
          double.tryParse(invoice.data!.discount!.toString()) != null &&
          double.parse(invoice.data!.discount!.toString()) > 0) {
        Discount =
            "Discount: ${double.parse(invoice.data!.discount!.toString()).toStringAsFixed(2)}";
      } else {
        Discount = '';
      }
      String amountInWords =
          "Amount in Words: AED ${NumberToWord().convert('en-in', invoice.data!.grandTotal?.toInt() ?? 0).toUpperCase()} ONLY";
      String van = invoice.data!.van![0].name ?? 'N/A';
      String salesman = invoice.data!.user![0].name ?? 'N/A';

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
          'https://erpadmin.mobiz.ae/uploads/store/${invoice.data!.store![0].logo}';
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
      // printer.printCustom(companyTRN, 1, 1); // Centered
      printer.printCustom(billtype, 1, 1); // Centered
      printer.printNewLine();

      printer.printCustom("-" * 72, 1, 1); // Centered
      printAlignedText("Invoice No: ${invoiceNumber}", "Date: ${invoiceDate}");
      printAlignedText("", "${remarks != null ? remarks : ''}");
      // printer.printCustom("Invoice No: ${invoiceNumber} | Date: ${invoiceDate}", 1, 1);
      printer.printNewLine();
      // Print customer details
      printAlignedText("Customer: $firstLine", "");

      if (secondLine.isNotEmpty) {
        printAlignedText("         $secondLine", "");
      }
      printAlignedText("$cusAddress", " ");
      // printAlignedText("Email: $customerEmail", "");
      printAlignedText("Contact No: $customerContact", "");
      printAlignedText("TRN: $customerTRN", " ");
      printer.printNewLine();

      // Print horizontal line
      printer.printCustom("-" * 70, 1, 1); // Centered

      // Define column widths for table
      const int columnWidth1 = 5; // S.No
      const int columnWidth2 = 20; // Product Description
      const int columnWidth3 = 5; // Unit
      const int columnWidth4 = 6; // Qty
      // const int columnWidth5 = 7; // Type
      const int columnWidth6 = 7; // Rate
      const int columnWidth7 = 7; // Total
      const int columnWidth8 = 6; // Tax
      const int columnWidth9 = 8; // Amount

      // Print table headers
      String headers = "${'S.No'.padRight(columnWidth1)}"
          "${'Product'.padRight(columnWidth2)}"
          "${'Unit'.padRight(columnWidth3)}"
          "${'Qty'.padRight(columnWidth4)}"
          // "${'Type'.padRight(columnWidth5)}"
          "${'Rate'.padRight(columnWidth6)}"
          "${'Amount'.padRight(columnWidth7)}"
          "  ${'Vat 5%'.padRight(columnWidth8)}"
          "${'Total'.padLeft(columnWidth9)}";
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
      for (int i = 0; i < invoice.data!.detail!.length; i++) {
        String productDescription = invoice.data!.detail![i].name ?? 'N/A';
        String productUnit = invoice.data!.detail![i].unit ?? 'N/A';
        String productQty =
            invoice.data!.detail![i].quantity?.toString() ?? '0';
        String productType =
            invoice.data!.detail![i].productType?.toString() ?? '0';
        String productRate =
            invoice.data!.detail![i].mrp?.toStringAsFixed(2) ?? '0.00';
        String productTotal =
            invoice.data!.detail![i].taxable?.toStringAsFixed(2) ?? '0.00';
        String productTax = invoice.data!.detail![i].taxAmt?.toStringAsFixed(2) ?? '0.00';
        String productAmount =
            invoice.data!.detail![i].amount?.toStringAsFixed(2) ?? '0.00';
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
                "${productUnit.padRight(columnWidth3)}"
                "${productQty.padRight(columnWidth4)}"
                // "${productType.padRight(columnWidth5)}"
                " ${productRate.padRight(columnWidth6)}"
                "${productTotal.padRight(columnWidth7)} "
                "${productTax.padRight(columnWidth8)}"
                "${productAmount.padLeft(columnWidth9)}";
          } else {
            // For subsequent lines, only include the description, leaving other columns blank
            line = "${''.padRight(columnWidth1)}"
                "${descriptionLines[j].padRight(columnWidth2)}"
                "${''.padRight(columnWidth3)}"
                "${''.padRight(columnWidth4)}"
                // "${''.padRight(columnWidth5)}"
                "${''.padRight(columnWidth6)}"
                "${''.padRight(columnWidth7)}";
            "${''.padRight(columnWidth8)}";
            "${''.padRight(columnWidth9)}";
          }
          printer.printCustom(line, 1, 0); // Left aligned
        }
      }
      printer.printCustom("-" * 70, 1, 1); // Centered
      double total = (invoice.data!.total ?? 0).toDouble();
      double discount = (invoice.data!.discount ?? 0).toDouble();
      double subTotal = total - discount;
      printAlignedText("","Total: ${total.toStringAsFixed(2)}");
      if (Discount.isNotEmpty) {
        print(Discount);
        printAlignedText("Van: $van", "$Discount");
      } else {
        printAlignedText("Van: $van", ""); // Skip printing Total
      }
      printAlignedText("Salesman: $salesman", "Sub Total: ${subTotal.toStringAsFixed(2)}");
      printAlignedText("","Vat 5%: $tax");
      printAlignedText("","Grand Total: $grandTotal"); // Right aligned
      printer.printNewLine();
      printer.printCustom(amountInWords, 1, 0); // Centered

      // Cut the paper
      printer.paperCut();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printer not connected')),
      );
    }
  }

  Future<String> _getImageData(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes.toString();
      } else {
        print("Failed to load image: ${response.statusCode}");
        return '';
      }
    } catch (e) {
      print("Error fetching image: $e");
      return '';
    }
  }

  Future<void> _createPdf(Invoice.InvoiceData invoice, bool isPrint) async {
    PdfDocument document = PdfDocument();
    final page = document.pages.add();
    final Size pageSize = page.getClientSize();
    final double pageWidth = pageSize.width;

    // Load logo (right side)
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
    final String companyName = invoice.data!.store![0].invoice_company_name ?? '';
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
    final String? name = invoice.data!.store![0].invoice_heading ?? '';
    final String text = '$name';

    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 15);
    final Size textSize = font.measureString(text);
    final double xPosition = (pageWidth - textSize.width) / 2;
    final double yPosition =
        165;
    page.graphics.drawString(
      text,
      font,
      bounds:
          Rect.fromLTWH(xPosition, yPosition, textSize.width, textSize.height),
    );

    // Draw a line below the text
    final remarks = invoice.data?.remarks;
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
  Invoice No: ${invoice.data!.invoiceNo!}
  Date: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(invoice.data!.inDate!))}
  Due Date: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(invoice.data!.inDate!))}
  ${remarks != null ? remarks : ''}
  ''';

    page.graphics.drawString(
      address,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(0, 200, pageSize.width / 0, 100),
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
    grid.columns[2].width = 35; // Unit
    grid.columns[3].width = 30; // Rate
    grid.columns[4].width = 35; // Qty
    grid.columns[5].width = 53;
    grid.columns[6].width = 50;
    grid.columns[7].width = 50; // Vat
    grid.columns[8].width = 82;

    // Add headers.
    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'Sl.No';
    headerRow.cells[1].value = 'Product';
    headerRow.cells[2].value = 'Unit';
    headerRow.cells[3].value = 'Qty';
    headerRow.cells[4].value = 'Type';
    headerRow.cells[5].value = 'Rate';
    headerRow.cells[6].value = 'Total';
    headerRow.cells[7].value = 'Vat';
    headerRow.cells[8].value = 'Amount   ';

    for (int k = 0; k < invoice.data!.detail!.length; k++) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = '${k + 1}';
      row.cells[1].value = '${invoice.data!.detail![k].name}';
      row.cells[2].value = '${invoice.data!.detail![k].unit}';
      row.cells[3].value = '${invoice.data!.detail![k].quantity}';
      row.cells[4].value = (invoice.data!.detail![k].productType!
                      .toLowerCase() ==
                  "foc" ||
              invoice.data!.detail![k].productType!.toLowerCase() == "FOC" ||
              invoice.data!.detail![k].productType!.toLowerCase() == "Change")
          ? 'Normal'
          : 'Normal';
      row.cells[5].value =
          '${invoice.data!.detail![k].mrp?.toStringAsFixed(2)}';
      row.cells[6].value =
          '${invoice.data!.detail![k].taxable?.toStringAsFixed(2)}';
      row.cells[7].value =
          '${invoice.data!.detail![k].taxAmt?.toStringAsFixed(2)}';
      row.cells[8].value =
          '${invoice.data!.detail![k].amount?.toStringAsFixed(2)}';
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

    // ${num.parse(invoice.data!.roundOff.toString()) != 0 ? 'Discount: ${invoice.data!.discount?.toStringAsFixed(2)}' : '\t'}

    String bottomInvoiceDetails = '''
    ${invoice.data!.discount != null && invoice.data!.discount! > 0 ? 'Discount: ${invoice.data!.discount!.toStringAsFixed(2)}' : '\t'}
  Sub Total: ${invoice.data!.total ?? ''}
  Vat: ${invoice.data!.totalTax?.toStringAsFixed(2)}
  ${'${invoice.data!.roundOff}' != 0 ? 'Round off:${double.parse(invoice.data!.roundOff ?? '').toStringAsFixed(2)}\nGrand Total: ${invoice.data!.grandTotal?.toStringAsFixed(2)}' : 'Grand Total: ${invoice.data!.grandTotal}'}


  ''';
    print('invoice.data!.discounted_amount');
    print(invoice.data!.discounted_amount);

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
    String numberToWords(int number) {
      if (number == 0) return "zero";

      const List<String> belowTwenty = [
        "",
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine",
        "ten",
        "eleven",
        "twelve",
        "thirteen",
        "fourteen",
        "fifteen",
        "sixteen",
        "seventeen",
        "eighteen",
        "nineteen"
      ];

      const List<String> tens = [
        "",
        "",
        "twenty",
        "thirty",
        "forty",
        "fifty",
        "sixty",
        "seventy",
        "eighty",
        "ninety"
      ];

      const List<String> thousands = ["", "thousand", "million", "billion"];

      String words = "";

      int thousandCounter = 0;

      while (number > 0) {
        int currentPart = number % 1000;

        if (currentPart > 0) {
          String partWords = "";

          if (currentPart >= 100) {
            partWords += belowTwenty[currentPart ~/ 100] + " hundred ";
            currentPart %= 100;
          }

          if (currentPart >= 20) {
            partWords += tens[currentPart ~/ 10] + " ";
            currentPart %= 10;
          }

          if (currentPart > 0) {
            partWords += belowTwenty[currentPart] + " ";
          }

          words = partWords + thousands[thousandCounter] + " " + words;
        }

        number ~/= 1000;
        thousandCounter++;
      }

      return words.trim();
    }

// Usage
// Adjust the vertical position for the van details
    double vanDetailsTop = tableBottom + 20 + 100 + 10;

// Construct the van details string.
    String bottomVanDetails = '''
Van: ${invoice.data!.van![0].name}
Salesman: ${invoice.data!.user![0].name}
''';

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

    final PdfStandardFont sfont = PdfStandardFont(PdfFontFamily.helvetica, 12);

// Prepare the text data
    String textData =
        'Amount in Words: AED ${numberToWords(invoice.data!.grandTotal!.toInt()).toUpperCase()} ONLY';
    String? infoot = invoice.data!.store![0].invoice_footer;

// Measure the height of both text strings
    final double textDataHeight = sfont.measureString(textData).height;
    final double infootHeight = sfont.measureString(infoot!).height;

    final double syPosition = pageSize.height -
        textDataHeight -
        infootHeight -
        20; // Adjust the 20 for padding from the bottom

    lastPage.graphics.drawString(
      textData,
      sfont,
      bounds: Rect.fromLTWH(
        0, // X position (left)
        syPosition, // Y position (calculated for bottom)
        pageSize.width, // Width of the bounding box
        textDataHeight, // Height of the bounding box
      ),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.left,
      ),
    );

    lastPage.graphics.drawString(
      infoot!,
      sfont,
      bounds: Rect.fromLTWH(
        0, // X position (left)
        syPosition +
            textDataHeight +
            5, // Y position (just below textData, with a small gap)
        pageSize.width, // Width of the bounding box
        infootHeight, // Height of the bounding box
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

  Future<void> _wifiPdf(Invoice.InvoiceData invoice, bool isPrint) async {
    PdfDocument document = PdfDocument();
    final page = document.pages.add();
    final pageSize = Size(595.0, 842.0);
    // final Size pageSize = page.getClientSize();
    final double pageWidth = page.getClientSize().width;
    final String text = 'TAX INVOICE';
    final PdfFont headfont = PdfStandardFont(
      PdfFontFamily.helvetica,
      15,
    );
    final Size headtextSize = headfont.measureString(text);
    //
    final double headxPosition = (pageWidth - headtextSize.width) / 2.0;
    final double headyPosition = 100;
    page.graphics.drawString(
      text,
      headfont,
      bounds: Rect.fromLTWH(headxPosition, headyPosition, headtextSize.width,
          headtextSize.height),
    );
    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 15);
    final Size textSize = font.measureString(text);
    final double yPosition =
        120; // Adjust this as needed for vertical positioning

    final remarks = invoice.data?.remarks;
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
  Invoice No: ${invoice.data!.invoiceNo!}
  Date: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(invoice.data!.inDate!))}
  ${remarks != null ? remarks : ''}
  ''';

    page.graphics.drawString(
      address,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(0, 160, pageSize.width / 0, 100),
    );

    page.graphics.drawString(
      invoiceDetails,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(pageSize.width / 2.8, 160, pageSize.width / 2, 100),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.right,
      ),
    );

    // Draw a horizontal line.
    page.graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0)),
      const Offset(0, 250),
      Offset(pageSize.width, 250),
    );

    // Create a table without grid lines.
    // Create a table with default grid lines.
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 11);

// Set column widths.
    grid.columns[0].width = 35;
    grid.columns[1].width = 125;
    grid.columns[2].width = 28;
    grid.columns[3].width = 24;
    grid.columns[4].width = 37;
    grid.columns[5].width = 40;
    grid.columns[6].width = 48;
    grid.columns[7].width = 50;
    grid.columns[8].width = 27;
    grid.columns[9].width = 50;
    grid.columns[10].width = 50;

// Add headers.
    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'Sl.No';
    headerRow.cells[1].value = 'Product';
    headerRow.cells[2].value = 'Unit';
    headerRow.cells[3].value = 'Qty';
    headerRow.cells[4].value = 'Rate';
    headerRow.cells[5].value = 'Rate\nIncl Vat';
    headerRow.cells[6].value = 'Amount';
    headerRow.cells[7].value = 'Taxable\nAmount';
    headerRow.cells[8].value = 'Vat\nRate';
    headerRow.cells[9].value = 'Vat\nAmount';
    headerRow.cells[10].value = 'Total\nIncl Vat';

// Set header style to make it bold.
    // Apply styles to the header row.
    for (int i = 0; i < headerRow.cells.count; i++) {
      headerRow.cells[i].style = PdfGridCellStyle(
        font: PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
        borders: PdfBorders(
          left: PdfPen(PdfColor(0, 0, 0)),
          top: PdfPen(PdfColor(0, 0, 0)),
          right: PdfPen(PdfColor(0, 0, 0)),
          bottom: PdfPen(PdfColor(0, 0, 0)),
        ),
      );
    }

    for (int k = 0; k < invoice.data!.detail!.length; k++) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = '${k + 1}';
      row.cells[1].value = '${invoice.data!.detail![k].name}';
      row.cells[2].value = '${invoice.data!.detail![k].unit}';
      row.cells[3].value = '${invoice.data!.detail![k].quantity}';
      row.cells[4].value = '${invoice.data!.detail![k].mrp?.toStringAsFixed(2)}';
      row.cells[5].value = '${(invoice.data!.detail![k].mrp! * 1.05).toStringAsFixed(2)}';
      row.cells[6].value = '${invoice.data!.detail![k].taxable?.toStringAsFixed(2)}';
      row.cells[7].value = '${invoice.data!.detail![k].taxable?.toStringAsFixed(2)}';
      row.cells[8].value = '5%';
      row.cells[9].value = '${invoice.data!.detail![k].taxAmt?.toStringAsFixed(2)}';
      row.cells[10].value = '${invoice.data!.detail![k].amount?.toStringAsFixed(2)}';

      final PdfStringFormat centerFormat = PdfStringFormat(
        alignment: PdfTextAlignment.center,
      );

      for (int i = 0; i < row.cells.count; i++) {
        row.cells[i].style = PdfGridCellStyle(
          font: PdfStandardFont(PdfFontFamily.helvetica, 12),
          borders: PdfBorders(
            left: PdfPen(PdfColor(0, 0, 0)), // Keep the vertical line on the left.
            top: PdfPen(PdfColor(255, 255, 255)), // Remove the horizontal line on top.
            right: PdfPen(PdfColor(0, 0, 0)), // Keep the vertical line on the right.
            bottom: PdfPen(PdfColor(255, 255, 255)), // Remove the horizontal line on bottom.
          ),
          format: (i == 1) ? null : centerFormat,
        );
      }
    }

// Draw the table.
    final PdfLayoutResult result = grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 270, pageSize.width, pageSize.height - 180),
    )!;

// Capture the last page and position of the table.
    PdfPage lastPage = result.page;
    double tableBottom = result.bounds.bottom;

// Add a horizontal line under the last product.
    lastPage.graphics.drawLine(
      PdfPen(PdfColor(0, 0, 0)), // Black line
      Offset(0, tableBottom + 5), // Slight gap after the last row
      Offset(pageSize.width, tableBottom + 5),
    );

    if (tableBottom >= pageSize.height) {
      lastPage = document.pages.add();
      tableBottom = 0;
    }

    double total = (invoice.data!.total ?? 0).toDouble();
    double discount = (invoice.data!.discount ?? 0).toDouble();
    double subTotal = total - discount;

    String bottomInvoiceDetails = '''
Total: ${total.toStringAsFixed(2)}    
${(invoice.data!.discount ?? 0) > 0 ? 'Discount: ${(invoice.data!.discount ?? 0).toStringAsFixed(2)}' : '\t'}
Sub Total: ${subTotal.toStringAsFixed(2)}
Vat: ${invoice.data!.totalTax?.toStringAsFixed(2)}
${'${invoice.data!.roundOff}' != '0' ? 'Round off: ${double.parse(invoice.data!.roundOff ?? '0').toStringAsFixed(2)}\nGrand Total: ${invoice.data!.grandTotal?.toStringAsFixed(2)}' : 'Grand Total: ${invoice.data!.grandTotal}'}
''';


    lastPage.graphics.drawString(
      bottomInvoiceDetails,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(
        pageSize.width / 2,
        tableBottom + 20,
        pageSize.width / 2.8,
        100,
      ),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.right,
      ),
    );


    double vanDetailsTop = tableBottom + 20 + 100 + 10;

    String bottomVanDetails = '''
Van: ${invoice.data!.van![0].name}
Salesman: ${invoice.data!.user![0].name}
''';

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

    String numberToWords(int number) {
      if (number == 0) return "zero";

      const List<String> belowTwenty = [
        "",
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine",
        "ten",
        "eleven",
        "twelve",
        "thirteen",
        "fourteen",
        "fifteen",
        "sixteen",
        "seventeen",
        "eighteen",
        "nineteen"
      ];

      const List<String> tens = [
        "",
        "",
        "twenty",
        "thirty",
        "forty",
        "fifty",
        "sixty",
        "seventy",
        "eighty",
        "ninety"
      ];

      const List<String> thousands = ["", "thousand", "million", "billion"];

      String words = "";

      int thousandCounter = 0;

      while (number > 0) {
        int currentPart = number % 1000;

        if (currentPart > 0) {
          String partWords = "";

          if (currentPart >= 100) {
            partWords += belowTwenty[currentPart ~/ 100] + " hundred ";
            currentPart %= 100;
          }

          if (currentPart >= 20) {
            partWords += tens[currentPart ~/ 10] + " ";
            currentPart %= 10;
          }

          if (currentPart > 0) {
            partWords += belowTwenty[currentPart] + " ";
          }

          words = partWords + thousands[thousandCounter] + " " + words;
        }

        number ~/= 1000;
        thousandCounter++;
      }

      return words.trim();
    }

    // Define the font
    final PdfStandardFont sfont = PdfStandardFont(PdfFontFamily.helvetica, 12);

// Prepare the text data
    String textData =
        'Amount in Words: AED ${numberToWords(invoice.data!.grandTotal!.toInt()).toUpperCase()} ONLY';
    String? infoot = invoice.data!.store![0].invoice_footer;

// Measure the height of both text strings
    final double textDataHeight = sfont.measureString(textData).height;
    final double infootHeight = sfont.measureString(infoot!).height;

// Calculate the Y position for the bottom left corner
    final double syPosition = pageSize.height -
        textDataHeight -
        infootHeight -
        100; // Adjust the 20 for padding from the bottom

// Draw the textData in the bottom left corner
    lastPage.graphics.drawString(
      textData,
      sfont,
      bounds: Rect.fromLTWH(
        0, // X position (left)
        syPosition, // Y position (calculated for bottom)
        pageSize.width, // Width of the bounding box
        textDataHeight, // Height of the bounding box
      ),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.left,
      ),
    );

// Draw the infoot in the bottom left corner, just below textData
    lastPage.graphics.drawString(
      infoot!,
      sfont,
      bounds: Rect.fromLTWH(
        0, // X position (left)
        syPosition
            +
            textDataHeight +
            5,
        pageSize.width, // Width of the bounding box
        infootHeight, // Height of the bounding box
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

  // Future<String> _getImageData(String imageUrl) async {
  //   http.Response response = await http.get(Uri.parse(imageUrl));
  //   Uint8List bytes = response.bodyBytes;
  //   return base64Encode(bytes);
  // }

  Future<Uint8List> _readImageData(String? image) async {
    // print(image);
    // print('jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj');
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
    dynamic response =
        await api.getDetails('/api/get_sales_invoice?id=$id', AppState().token);
    print("IIDD$id");
    if (response['data'] != null) {
      print("DDDDDD${id}");
      invoice = Invoice.InvoiceData.fromJson(response);
      _createPdf(invoice, isPrint);
    }
    // if (_selectedDevice == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Default device not found')),
    //   );
    //   return;
    // }
    // if (!_connected) {
    //   await _connect();
    // }
    // _print(invoice, isPrint);
  }

  Future<void> _getwifiInvoiceData(int id, bool isPrint) async {
    Invoice.InvoiceData invoice = Invoice.InvoiceData();
    RestDatasource api = RestDatasource();
    dynamic response =
        await api.getDetails('/api/get_sales_invoice?id=$id', AppState().token);
    if (response['data'] != null) {
      print("DDDDDD${id}");
      invoice = Invoice.InvoiceData.fromJson(response);
      _wifiPdf(invoice, isPrint);
    }
    // if (_selectedDevice == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Default device not found')),
    //   );
    //   return;
    // }
    // if (!_connected) {
    //   await _connect();
    // }
    // _print(invoice, isPrint);
  }

  Future<void> _getInvoiceDataprint(int id, bool isPrint) async {
    Invoice.InvoiceData invoice = Invoice.InvoiceData();
    RestDatasource api = RestDatasource();
    dynamic response =
        await api.getDetails('/api/get_sales_invoice?id=$id', AppState().token);
    print("IIDD$id");
    if (response['data'] != null) {
      print("IIDD$id");
      invoice = Invoice.InvoiceData.fromJson(response);
      // _createPdf(invoice, isPrint);
    }
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Default device not found')),
      );
      return;
    }
    if (!_connected) {
      await _connect();
    }
    _print(invoice, isPrint);
  }
}

// Data models (VanSaleResponse, VanSale, etc.) remain unchanged.

class VanSaleResponse {
  bool? success;
  VanSaleData? data;
  List<String>? messages;

  VanSaleResponse({this.success, this.data, this.messages});

  factory VanSaleResponse.fromJson(Map<String, dynamic> json) {
    return VanSaleResponse(
      success: json['success'],
      data: VanSaleData.fromJson(json['data']), // Handle 'data' as an object
      messages: List<String>.from(
          json['messages'] ?? []), // Ensure messages is not null
    );
  }
}

class VanSaleData {
  final int currentPage;
  final List<VanSale> vanSales;
  final String firstPageUrl;
  final String lastPageUrl;
  final String nextPageUrl;
  final String prevPageUrl;
  final int total;
  final int perPage;
  final int lastPage;

  VanSaleData({
    required this.currentPage,
    required this.vanSales,
    required this.firstPageUrl,
    required this.lastPageUrl,
    required this.nextPageUrl,
    required this.prevPageUrl,
    required this.total,
    required this.perPage,
    required this.lastPage,
  });

  factory VanSaleData.fromJson(Map<String, dynamic> json) {
    return VanSaleData(
      currentPage: json['current_page'],
      vanSales: (json['data'] as List).map((e) => VanSale.fromJson(e)).toList(),
      firstPageUrl: json['first_page_url'],
      lastPageUrl: json['last_page_url'],
      nextPageUrl: json['next_page_url'] ?? '',
      prevPageUrl: json['prev_page_url'] ?? '',
      total: json['total'],
      perPage: json['per_page'],
      lastPage: json['last_page'],
    );
  }
}

class VanSale {
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
  String? discount_type;
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
  List<Customer>? customerdata;

  VanSale(
      {this.id,
      this.customerId,
      this.billMode,
      this.inDate,
      this.inTime,
      this.invoiceNo,
      this.discount_type,
      this.deliveryNo,
      this.otherCharge,
      this.discount,
      this.roundOff,
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
      this.customer,
      this.customerdata
      });

  VanSale.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    customerId = json['customer_id'];
    billMode = json['bill_mode'] ?? '';
    inDate = json['in_date'] ?? '';
    inTime = json['in_time'] ?? '';
    invoiceNo = json['invoice_no'] ?? '';
    deliveryNo = json['delivery_no'] ?? '';
    otherCharge = json['other_charge'] ?? 0;
    discount = json['discount'] ?? 0;
    discount_type = json['discount_type'] ?? '';
    roundOff = json['round_off'] ?? '';
    total = json['total'] ?? 0;
    totalTax = json['total_tax'] ?? 0;
    grandTotal = json['grand_total'] ?? 0;
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
        customer!.add(new Customer.fromJson(v));
      });
    } else if (json['customerdata'] != null) {
      customer = <Customer>[];
      customer!.add(new Customer.fromJson(json['customerdata']));
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
