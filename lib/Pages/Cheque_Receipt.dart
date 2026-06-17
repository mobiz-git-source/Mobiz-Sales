import 'dart:convert';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/Cheque/Cheque_Colection.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'package:mobizapp/confg/sizeconfig.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Models/Store_model.dart';

class ChequeReceipt extends StatefulWidget {
  static const routeName = "/Cheque receipt";

  const ChequeReceipt({super.key});

  @override
  State<ChequeReceipt> createState() => _ChequeReceiptState();
}

class _ChequeReceiptState extends State<ChequeReceipt> {
  List<Data> chequeList = [];
  bool isLoading = true;
  bool _connected = false;
  BluetoothDevice? _selectedDevice;
  List<BluetoothDevice> _devices = [];
  BlueThermalPrinter printer = BlueThermalPrinter.instance;

  @override
  void initState() {
    super.initState();
    fetchChequeCollection();
    _initPrinter();
  }

  void _initPrinter() async {
    try {
      bool? isConnected = await printer.isConnected;
      if (isConnected ?? false) {
        setState(() => _connected = true);
      }
      await _getBluetoothDevices();
    } catch (e) {
      print('Printer init error: $e');
    }
  }

  Future<void> _getBluetoothDevices() async {
    try {
      List<BluetoothDevice> devices = await printer.getBondedDevices();
      final prefs = await SharedPreferences.getInstance();
      final savedDeviceAddress = prefs.getString('selected_device_address');

      setState(() {
        _devices = devices;
        _selectedDevice = devices.firstWhere(
              (device) => device.address == savedDeviceAddress,
          orElse: () => devices.first,
        );
      });
    } catch (e) {
      print('Error getting devices: $e');
    }
  }

  Future<bool> _connect() async {
    try {
      if (_selectedDevice == null) {
        if (_devices.isNotEmpty) {
          setState(() => _selectedDevice = _devices.first);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No printer devices available')),
          );
          return false;
        }
      }

      await printer.connect(_selectedDevice!);
      setState(() => _connected = true);
      return true;
    } catch (e) {
      print('Connection error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to printer: $e')),
      );
      return false;
    }
  }

  Future<void> fetchChequeCollection() async {
    String url = '${RestDatasource().BASE_URL}/api/cheque_collection_index?store_id=${AppState().storeId}';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        // Check if data exists and is a list
        if (jsonData['data'] != null && jsonData['data'] is List) {
          setState(() {
            chequeList = (jsonData['data'] as List)
                .map((item) => Data.fromJson(item))
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            chequeList = [];
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        chequeList = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Cheque Receipt",
              style: TextStyle(color: Colors.white),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, ChequeCollectionPage.routeName);
              },
              child: Icon(Icons.add, size: SizeConfig.blockSizeVertical * 4),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : chequeList.isEmpty
          ? const Center(child: Text('No data available'))
          : ListView.builder(
        itemCount: chequeList.length,
        itemBuilder: (context, index) {
          final data = chequeList[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 2,
                    blurRadius: 2,
                    blurStyle: BlurStyle.inner,
                    color: Colors.grey.shade200,
                  ),
                ],
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                color: AppConfig.backgroundColor,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: ListTile(
                trailing: SizedBox(
                  width: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                      onTap: () => _print(data),
                        child: const Icon(Icons.print, color: Colors.blueAccent),
                      ),
                      // const SizedBox(width: 10),
                      // GestureDetector(
                        // onTap: () => generatePdf(data),
                        // child: const Icon(Icons.document_scanner, color: Colors.red),
                      // ),
                    ],
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.chequeDate??'',
                          style: TextStyle(
                            fontSize: AppConfig.textCaption3Size,
                          ),
                        ),
                        Text(
                          "Receipt No: ${data.invoiceNo}",
                          style: TextStyle(
                            fontSize: AppConfig.textCaption3Size,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              data.bank??'',
                              style: TextStyle(
                                fontSize: AppConfig.textCaption3Size,
                                fontWeight: AppConfig.headLineWeight,
                              ),
                            ),
                            const Text(' | '),
                            Text(
                              "${data.chequeNo}",
                              style: TextStyle(
                                fontSize: AppConfig.textCaption3Size,
                                fontWeight: AppConfig.headLineWeight,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Amount: ${data.amount}',
                          style: TextStyle(
                            fontSize: AppConfig.textCaption3Size,
                          ),
                        ),
                        Row(
                          children: [
                            Text('Status: ',
                                style: TextStyle(
                                  fontSize: AppConfig.textCaption3Size,
                                )),
                            Text(
                              data.status == 1
                                  ? 'Pending'
                                  : data.status == 0
                                  ? 'Cancelled'
                                  : 'Completed',
                              style: TextStyle(
                                fontSize: AppConfig.textCaption3Size,
                                color: data.status == 1
                                    ? Colors.orange
                                    : data.status == 0
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: AppConfig.headLineWeight,
                              ),
                            ),

                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _print(Data data) async {
    try {
      if (!_connected) {
        bool connected = await _connect();
        if (!connected) return;
      }
      final response = await http.get(Uri.parse(
          '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}'));
      if (response.statusCode != 200) {
        print(response.body);
        throw Exception('Failed to load store details');
      }
      StoreDetail storeDetail = StoreDetail.fromJson(json.decode(response.body));
      try {
        final String logoUrl = '${RestDatasource().Image_URL}/uploads/store/${storeDetail.logos}';
        if (logoUrl.isNotEmpty) {
          final logoResponse = await http.get(Uri.parse(logoUrl));
          if (logoResponse.statusCode == 200) {
            Uint8List imageBytes = logoResponse.bodyBytes;
            img.Image originalImage = img.decodeImage(imageBytes)!;
            img.Image monoLogo = img.grayscale(originalImage);
            Uint8List logoBytes = Uint8List.fromList(img.encodePng(monoLogo));
            await printer.printImageBytes(logoBytes);
          }
        }
      } catch (e) {
        print('Error printing logo: $e');
      }
      void printAlignedText(String leftText, String rightText) {
        const int maxLineLength = 68;
        int leftTextLength = leftText.length;
        int rightTextLength = rightText.length;

        int spaceLength = maxLineLength - (leftTextLength + rightTextLength);
        String spaces = ' ' * spaceLength;
        printer.printCustom('$leftText$spaces$rightText', 1,
            0); // Print with left-aligned text
      }
      String formatDate(String date) {
        DateTime parsedDate = DateTime.parse(date);
        return DateFormat('dd-MM-yyyy').format(parsedDate);
      }
      printer.printNewLine();
      String companyName =
          '${storeDetail.name}';
      printer.printCustom(companyName, 3, 1);
      printer.printCustom("Address: ${data.store!.address}", 1, 1);
      printer.printCustom("TRN: ${data.store!.trn}", 1, 1);
      printer.printCustom("CHEQUE RECEIPT", 1, 1);
      printer.printNewLine();
      printer.printCustom("-" * 72, 1, 1);
      printAlignedText('Customer: ${data.paymentType == "Individual" ? data.customer[0].name  : data.customerGroup[0].name}', '',);
      printAlignedText('', 'Date: ${formatDate(data.inDate)}');
      printer.printNewLine();
      printer.printCustom("-" * 72, 1, 1); // Centered
      if (data.collectionType == 'Cheque') {
        printAlignedText('Collection Type: Cheque', 'Cheque No: ${data.chequeNo}');
        printAlignedText('Bank Name: ${data.bank}', 'Cheque Date: ${data.chequeDate}');
      } else if (data.collectionType == 'Cash') {
        printAlignedText('Collection Type: Cash', ' '); // Uncomment if needed
      }
      printAlignedText('Amount: ${data.amount}', ' ');
      printer.printNewLine();
      printer.printCustom("-" * 72, 1, 1);
      printAlignedText("Van: ${data.vanId}", "");
      printAlignedText("Salesman: ${data.user!.name}", "");
      printer.printNewLine();

      printer.paperCut();

    } catch (e) {
      print('Printing error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printing failed: $e')),
      );
    }
  }
}


class CollectionResponse {
  final List<Data> data;
  final bool success;
  final List<dynamic> messages;

  CollectionResponse({
    required this.data,
    required this.success,
    required this.messages,
  });

  factory CollectionResponse.fromJson(Map<String, dynamic> json) {
    return CollectionResponse(
      data: (json['data'] as List?)?.map((e) => Data.fromJson(e)).toList() ?? [],
      success: json['success'] ?? false,
      messages: json['messages'] ?? [],
    );
  }
}

class Data {
  final int id;
  final String? invoiceNo;
  final String inDate;
  final String inTime;
  final int customerGroupId;
  final String collectionType;
  final String? paymentType;
  final double amount;
  final String? chequeDate;
  final String? bank;
  final String? chequeNo;
  final String? description;
  final int vanId;
  final int userId;
  final int storeId;
  final int dayClose;
  final int status;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final Store? store;
  final User? user;
  final List<CustomerGroup> customerGroup;
  final List<Customer> customer;
  final Van? van;

  Data({
    required this.id,
    this.invoiceNo,
    required this.inDate,
    required this.inTime,
    required this.customerGroupId,
    required this.collectionType,
    this.paymentType,
    required this.amount,
    this.chequeDate,
    this.bank,
    this.chequeNo,
    this.description,
    required this.vanId,
    required this.userId,
    required this.storeId,
    required this.dayClose,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.store,
    this.user,
    required this.customerGroup,
    required this.customer,
    this.van,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      id: json['id'] ?? 0,
      invoiceNo: json['invoice_no'],
      inDate: json['in_date'] ?? '',
      inTime: json['in_time'] ?? '',
      customerGroupId: json['customer_group_id'] ?? 0,
      collectionType: json['collection_type'] ?? '',
      paymentType: json['payment_type'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      chequeDate: json['cheque_date'],
      bank: json['bank'],
      chequeNo: json['cheque_no'],
      description: json['description'],
      vanId: json['van_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      dayClose: json['day_close'] ?? 0,
      status: json['status'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      store: json['store'] != null && (json['store'] as List).isNotEmpty
          ? Store.fromJson(json['store'][0])
          : null,
      user: json['user'] != null && (json['user'] as List).isNotEmpty
          ? User.fromJson(json['user'][0])
          : null,
      customerGroup: (json['customergroup'] as List?)?.map((e) => CustomerGroup.fromJson(e)).toList() ?? [],
      customer: (json['customer'] as List?)?.map((e) => Customer.fromJson(e)).toList() ?? [],
      van: json['van'] != null && (json['van'] as List).isNotEmpty
          ? Van.fromJson(json['van'][0])
          : null,
    );
  }
}

class Store {
  final int id;
  final String code;
  final String name;
  final int companyId;
  final String logo;
  final String emirate;
  final String address;
  final String country;
  final String contactNumber;
  final String? whatsappNumber;
  final String email;
  final String username;
  final String password;
  final int noOfUsers;
  final String subscriptionEndDate;
  final String bufferDays;
  final String allowAccess;
  final String? description;
  final String? currency;
  final String? vatPercentage;
  final String? trn;
  final String? invoiceHeading;
  final String? invoiceCompanyName;
  final String? invoiceFooter;
  final String displayStoreName;
  final int status;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  Store({
    required this.id,
    required this.code,
    required this.name,
    required this.companyId,
    required this.logo,
    required this.emirate,
    required this.address,
    required this.country,
    required this.contactNumber,
    this.whatsappNumber,
    required this.email,
    required this.username,
    required this.password,
    required this.noOfUsers,
    required this.subscriptionEndDate,
    required this.bufferDays,
    required this.allowAccess,
    this.description,
    this.currency,
    this.vatPercentage,
    this.trn,
    this.invoiceHeading,
    this.invoiceCompanyName,
    this.invoiceFooter,
    required this.displayStoreName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      companyId: json['comapny_id'] ?? 0,
      logo: json['logo'] ?? '',
      emirate: json['emirate'] ?? '',
      address: json['address'] ?? '',
      country: json['country'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      whatsappNumber: json['whatsapp_number'],
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      noOfUsers: json['no_of_users'] ?? 0,
      subscriptionEndDate: json['suscription_end_date'] ?? '',
      bufferDays: json['buffer_days'] ?? '',
      allowAccess: json['allow_access'] ?? '',
      description: json['description'],
      currency: json['currency'],
      vatPercentage: json['vat_percentage'],
      trn: json['trn'],
      invoiceHeading: json['invoice_heading'],
      invoiceCompanyName: json['invoice_company_name'],
      invoiceFooter: json['invoice_footer'],
      displayStoreName: json['display_store_name'] ?? '',
      status: json['status'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final bool? isSuperAdmin;
  final bool isShopAdmin;
  final bool isStaff;
  final int departmentId;
  final int designationId;
  final int storeId;
  final int rolId;
  final dynamic productionStore;
  final dynamic glId;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.isSuperAdmin,
    required this.isShopAdmin,
    required this.isStaff,
    required this.departmentId,
    required this.designationId,
    required this.storeId,
    required this.rolId,
    this.productionStore,
    this.glId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) return value == '1' || value.toLowerCase() == 'true';
      if (value is int) return value == 1;
      return false;
    }

    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      emailVerifiedAt: json['email_verified_at'],
      isSuperAdmin: json['is_super_admin'] == null ? null : parseBool(json['is_super_admin']),
      isShopAdmin: parseBool(json['is_shop_admin']),
      isStaff: parseBool(json['is_staff']),
      departmentId: json['department_id'] ?? 0,
      designationId: json['designation_id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      rolId: json['app_rol_id'] ?? 0,
      productionStore: json['production_store'],
      glId: json['gl_id'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class CustomerGroup {
  final int id;
  final String name;
  final String? description;
  final int storeId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  CustomerGroup({
    required this.id,
    required this.name,
    this.description,
    required this.storeId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory CustomerGroup.fromJson(Map<String, dynamic> json) {
    return CustomerGroup(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      storeId: json['store_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
    );
  }
}

class Customer {
  final int id;
  final String name;
  final String? code;
  final String address;
  final String building;
  final String flatNo;
  final String contactNumber;
  final String? whatsappNumber;
  final String email;
  final String trn;
  final String? custImage;
  final String paymentTerms;
  final int creditLimit;
  final int creditDays;
  final String location;
  final int routeId;
  final int provinceId;
  final int storeId;
  final int status;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String? erpCustomerCode;
  final int priceGroupId;
  final int? accountId;
  final String isCustomer;
  final String isSupplier;
  final dynamic receivableGlId;
  final dynamic payableGlId;

  Customer({
    required this.id,
    required this.name,
    this.code,
    required this.address,
    required this.building,
    required this.flatNo,
    required this.contactNumber,
    this.whatsappNumber,
    required this.email,
    required this.trn,
    this.custImage,
    required this.paymentTerms,
    required this.creditLimit,
    required this.creditDays,
    required this.location,
    required this.routeId,
    required this.provinceId,
    required this.storeId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.erpCustomerCode,
    required this.priceGroupId,
    this.accountId,
    required this.isCustomer,
    required this.isSupplier,
    this.receivableGlId,
    this.payableGlId,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
      address: json['address'] ?? '',
      building: json['building'] ?? '',
      flatNo: json['flat_no'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      whatsappNumber: json['whatsapp_number'],
      email: json['email'] ?? '',
      trn: json['trn'] ?? '',
      custImage: json['cust_image'],
      paymentTerms: json['payment_terms'] ?? '',
      creditLimit: json['credit_limit'] ?? 0,
      creditDays: json['credit_days'] ?? 0,
      location: json['location'] ?? '',
      routeId: json['route_id'] ?? 0,
      provinceId: json['province_id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      status: json['status'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'],
      erpCustomerCode: json['erp_customer_code'],
      priceGroupId: json['price_group_id'] ?? 0,
      accountId: json['account_id'],
      isCustomer: json['is_customer'] ?? '',
      isSupplier: json['is_supplier'] ?? '',
      receivableGlId: json['receivable_gl_id'],
      payableGlId: json['payable_gl_id'],
    );
  }
}

class Van {
  final int id;
  final String name;
  final String? description;

  Van({
    required this.id,
    required this.name,
    this.description,
  });

  factory Van.fromJson(Map<String, dynamic> json) {
    return Van(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}
