import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'package:mobizapp/main.dart';
import 'dart:convert';

import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';

class CustomerStock extends StatefulWidget {
  static const routeName = "/Stock";

  @override
  State<CustomerStock> createState() => _CustomerStockState();
}

class _CustomerStockState extends State<CustomerStock> {
  int? id;
  String? name;
  CustomerStockDataResponse? customerStockData;

  @override
  void initState() {
    super.initState();
    // Fetch data when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (id != null) {
        fetchCustomerStock(id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if arguments were passed and update id if null
    if (id == null && ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      id = params!['customerId'];
      name = params['name'];

      // Call the API once id is set
      if (id != null) {
        fetchCustomerStock(id!);
      }
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
        title: const Text(
          'Customer Stock',
           style: AppConfig.pageTitleStyle,
        ),
        backgroundColor: AppConfig.colorPrimary,
      ),
      body: customerStockData == null
          ? Center(child: CircularProgressIndicator()) // Show loader if data is null
          : customerStockData!.stock.isEmpty
          ? Center(child: Text("No stock data available")) // Message if no stock data
          : SingleChildScrollView(
            child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    ListView.builder(
            shrinkWrap: true,
             scrollDirection: Axis.vertical,
            physics: BouncingScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: customerStockData!.stock.length,
            itemBuilder: (context, index) {
              final item = customerStockData!.stock[index];
            
              return Card(
                elevation: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    color: AppConfig.backgroundColor,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: ExpansionTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Name: ${item.productSerial}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${item.status}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    trailing: SizedBox.shrink(), // Removes the default dropdown icon
                    children: [
                      Divider(),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text("Quantity: ${item.noOfCoupons}"),
                            SizedBox(height: 10),
            
                            // Display each coupon detail
                            ListView.builder(
                              physics: NeverScrollableScrollPhysics(), // Prevent scrolling inside ExpansionTile
                              shrinkWrap: true, // Fit content in ExpansionTile
                              itemCount: item.couponDetails.length,
                              itemBuilder: (context, couponIndex) {
                                final coupon = item.couponDetails[couponIndex];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Serial No: ${coupon.serialNo}"),
                                      Text("Status: ${coupon.status}"),
                                      Text("Coupon Type: ${coupon.coupenType}"),
                                      // Text("Value: ${coupon.value}"),
                                      SizedBox(height: 10),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
                    ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bottle Stock: ${customerStockData!.data.stock}',style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),),
                  Text('Deposit: ${customerStockData!.data.deposit}',style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500))
                ],
              ),
            ),
                      SizedBox(height:20)
                  ],
            ),
          ),
    );
  }


  Future<void> fetchCustomerStock(int customerId) async {
    final url = Uri.parse("${RestDatasource().BASE_URL}/api/get-customer-stock?customer_id=$customerId");
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print("ID:$customerId");
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          // Make sure to parse the whole response correctly
          customerStockData = CustomerStockDataResponse.fromJson(responseData);
        });
      } else {
        print("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching customer stock: $e");
    }
  }
}

class CustomerStockDataResponse {
  final CustomerData data;
  final List<CustomerStockData> stock;
  final bool success;
  final List<String> messages;

  CustomerStockDataResponse({
    required this.data,
    required this.stock,
    required this.success,
    required this.messages,
  });

  factory CustomerStockDataResponse.fromJson(Map<String, dynamic> json) {
    return CustomerStockDataResponse(
      data: json['data'] != null ? CustomerData.fromJson(json['data']) : CustomerData.defaultData(),
      stock: (json['stock'] as List?)?.map((item) => CustomerStockData.fromJson(item)).toList() ?? [],
      success: json['success'] ?? false,
      messages: List<String>.from(json['messages'] ?? []),
    );
  }

}

class CustomerData {
  final int id;
  final int customerId;
  final String stock;
  final String deposit;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  CustomerData({
    required this.id,
    required this.customerId,
    required this.stock,
    required this.deposit,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // Default constructor for null safety
  factory CustomerData.defaultData() {
    return CustomerData(
      id: 0,
      customerId: 0,
      stock: '0.00',
      deposit: '0.000',
      createdAt: '',
      updatedAt: '',
      deletedAt: null,
    );
  }

  factory CustomerData.fromJson(Map<String, dynamic> json) {
    return CustomerData(
      id: json['id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      stock: json['stock'] ?? '0.00',
      deposit: json['deposit'] ?? '0.000',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'], // Nullable
    );
  }
}

class CustomerStockData {
  final int id;
  final int productId;
  final String productSerial;
  final int noOfFreeCoupons;
  final String startSerial;
  final int noOfCoupons;
  final int storeId;
  final int customerId;
  final int goodsOutId;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String status;
  final List<CouponDetail> couponDetails;

  CustomerStockData({
    required this.id,
    required this.productId,
    required this.productSerial,
    required this.noOfFreeCoupons,
    required this.startSerial,
    required this.noOfCoupons,
    required this.storeId,
    required this.customerId,
    required this.goodsOutId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.status,
    required this.couponDetails,
  });

  factory CustomerStockData.fromJson(Map<String, dynamic> json) {
    return CustomerStockData(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productSerial: json['product_serial'] ?? '',
      noOfFreeCoupons: json['no_of_free_coupons'] ?? 0,
      startSerial: json['start_serial'] ?? '',
      noOfCoupons: json['no_of_coupons'] ?? 0,
      storeId: json['store_id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      goodsOutId: json['goods_out_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'], // Nullable
      status: json['status'] ?? '',
      couponDetails: (json['coupon_details'] as List?)
          ?.map((item) => CouponDetail.fromJson(item))
          .toList() ?? [],
    );
  }
}

class CouponDetail {
  final int id;
  final int couponMasterId;
  final String serialNo;
  final String barcode;
  final String value;
  final String status;
  final String coupenType;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final int customerId;
  final int goodsOutId;

  CouponDetail({
    required this.id,
    required this.couponMasterId,
    required this.serialNo,
    required this.barcode,
    required this.value,
    required this.status,
    required this.coupenType,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.customerId,
    required this.goodsOutId,
  });

  factory CouponDetail.fromJson(Map<String, dynamic> json) {
    return CouponDetail(
      id: json['id'] ?? 0,
      couponMasterId: json['coupon_master_id'] ?? 0,
      serialNo: json['serial_no'] ?? '',
      barcode: json['barcode'] ?? '',
      value: json['value'] ?? '',
      status: json['status'] ?? '',
      coupenType: json['coupen_type'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'], // Nullable
      customerId: json['customer_id'] ?? 0,
      goodsOutId: json['goods_out_id'] ?? 0,
    );
  }
}

