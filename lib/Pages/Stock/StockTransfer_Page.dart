import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/Stock/Stock_Transfer.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:mobizapp/Pages/homepage_Driver.dart';
import 'package:mobizapp/Pages/store/StorePage.dart';
import '../../Components/commonwidgets.dart';
import '../../Utilities/date_helper.dart';
import '../../confg/appconfig.dart';
import '../../confg/sizeconfig.dart';
import '../homepage.dart';

class StockTransferPage extends StatefulWidget {
  static const routeName = "/StockTransferPage";
  @override
  _StockTransferPageState createState() => _StockTransferPageState();
}

class _StockTransferPageState extends State<StockTransferPage> {
  int? expandedItemId;
  bool _search = false;
  final TextEditingController _searchData = TextEditingController();
  late Future<List<StockTransfer>> futureTransfers;

  @override
  void initState() {
    super.initState();
    futureTransfers = fetchStockTransfers();
  }

  static Future<List<StockTransfer>> fetchStockTransfers() async {
    final response = await http.get(Uri.parse(
        "http://68.183.92.8:3699/api/stock-transfer.index?store_id=${AppState().storeId}&van_id=${AppState().vanId}"));
    if (response.statusCode == 200) {
      print(response.request);
      final jsonData = json.decode(response.body);
      StockTransferResponse stockResponse =
          StockTransferResponse.fromJson(jsonData);
      return stockResponse.data;
    } else {
      throw Exception("Failed to fetch stock transfers");
    }
  }

  static Future<void> completeStockTransfer(int id) async {
    final url =
        Uri.parse("http://68.183.92.8:3699/api/stock-transfer.complete");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "store_id": AppState().storeId,
        "id": id,
      }),
    );
    print(id);
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      print("✅ Complete success: ${response.body}");
    } else {
      throw Exception("❌ Failed to complete transfer: ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchLocations() async {
    try {
      final response = await http.get(
        Uri.parse(
            "http://68.183.92.8:3699/api/get/locations/${AppState().storeId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List locations = data['data'];
        return List<Map<String, dynamic>>.from(locations);
      } else {
        print("❌ Failed to fetch locations: ${response.body}");
        return [];
      }
    } catch (e) {
      print("⚠️ Exception fetching locations: $e");
      return [];
    }
  }

  Future<void> _showLocationDialog() async {
    List<Map<String, dynamic>> locations = [];
    Map<String, dynamic>? fromLocation;
    Map<String, dynamic>? toLocation;
    bool isLoading = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          if (isLoading) {
            fetchLocations().then((data) {
              setState(() {
                locations = data;
                isLoading = false;
              });
            }).catchError((error) {
              setState(() => isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Failed to load locations: $error")),
              );
            });
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text("Select Locations"),
            content: isLoading
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownSearch<Map<String, dynamic>>(
                          items: locations,
                          itemAsString: (item) => item['name'],
                          popupProps: const PopupProps.menu(
                            showSearchBox: true,
                            searchDelay:
                                Duration(milliseconds: 100), // 👈 debounce
                          ),
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: "From Location",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => fromLocation = value);
                          },
                          selectedItem: fromLocation,
                        ),
                        const SizedBox(height: 15),
                        DropdownSearch<Map<String, dynamic>>(
                          items: locations
                              .where((e) => e['id'] != fromLocation?['id'])
                              .toList(),
                          itemAsString: (item) => item['name'],
                          popupProps: const PopupProps.menu(
                            showSearchBox: true,
                            searchDelay:
                                Duration(milliseconds: 100), // 👈 debounce
                          ),
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: "To Location",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => toLocation = value);
                          },
                          selectedItem: toLocation,
                        ),
                      ],
                    ),
                  ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.colorPrimary,
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (fromLocation == null || toLocation == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Please select both locations")),
                          );
                          return;
                        }

                        Navigator.pop(context);
                        await _createStockTransfer(
                          fromLocation!['id'], toLocation!['id'],
                          fromLocation!['name'], // 👈 pass from name
                          toLocation!['name'],
                        );
                      },
                child: const Text("Continue",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _createStockTransfer(
      int fromId, int toId, String fromName, String toName) async {
    final url = Uri.parse("http://68.183.92.8:3699/api/store-scan-master");

    final body = {
      "select_from_location": fromId,
      "select_to_location": toId,
      "user_id": AppState().userId,
      "store_id": AppState().storeId,
    };

    print("📦 Sending Payload: $body");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("📡 Response Code: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        var dataId = result['data']['id'];
        if (result["status"] == true || result["success"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result["message"] ?? "Stock Transfer Created")),
          );

          Navigator.pushReplacementNamed(
            context,
            StocKTransfer_Inner.routeName,
            arguments: {"fromName": fromName, "toName": toName, "id": dataId},
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text("Server error: ${result["message"] ?? "Failed"}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("HTTP ${response.statusCode}: ${response.body}")),
        );
      }
    } catch (e) {
      print("🚨 Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong: $e")),
      );
    }
  }

  void saveCompleteData() {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Completed!")));
  }

  Future<bool> _onWillPop() async {
    Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    return false; // Return false to prevent default back behavior
  }

  Future<bool> _onWillDriver() async {
    Navigator.pushReplacementNamed(context, HomepageDriver.routeName);
    return false; // Return false to prevent default back behavior
  }

  Future<bool> _onWillStore() async {
    Navigator.pushReplacementNamed(context, TransferOptionsPage.routeName);
    return false; // Return false to prevent default back behavior
  }

  void _navigateBack() {
    final rolId = AppState().rolId;
    if (rolId == 4) {
      Navigator.pushReplacementNamed(context, HomepageDriver.routeName);
    } else if (rolId == 3) {
      Navigator.pushReplacementNamed(context, TransferOptionsPage.routeName);
    } else {
      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _navigateBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppConfig.colorPrimary,
          // iconTheme: IconThemeData(color: AppConfig.backgroundColor),
          leading: GestureDetector(
              onTap: _navigateBack,
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
              )),
          title: const Text(
            'Stock Transfer Requests',
            style: AppConfig.pageTitleStyle,
          ),
          actions: [
            (_search)
                ? Container(
                    height: SizeConfig.blockSizeVertical * 5,
                    width: SizeConfig.blockSizeHorizontal * 76,
                    decoration: BoxDecoration(
                      color: AppConfig.colorPrimary,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(10),
                      ),
                      border: Border.all(color: AppConfig.colorPrimary),
                    ),
                    child: TextField(
                      controller: _searchData,
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(5),
                          hintText: "Search...",
                          hintStyle:
                              TextStyle(color: AppConfig.backgroundColor),
                          border: InputBorder.none),
                    ),
                  )
                : Container(),
            CommonWidgets.horizontalSpace(1),
            (!_search)
                ? GestureDetector(
                    onTap: _showLocationDialog,
                    child: const Icon(
                      Icons.add,
                      size: 30,
                      color: AppConfig.backgroundColor,
                    ),
                  )
                : Container(),
            CommonWidgets.horizontalSpace(1),
            GestureDetector(
              onTap: () {
                setState(() {
                  _search = !_search;
                });
              },
              child: Icon(
                (!_search) ? Icons.search : Icons.close,
                size: 30,
                color: AppConfig.backgroundColor,
              ),
            ),
            CommonWidgets.horizontalSpace(3),
          ],
        ),
        body: FutureBuilder<List<StockTransfer>>(
          future: futureTransfers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            final transfers = snapshot.data ?? [];

            return ListView.builder(
              itemCount: transfers.length,
              itemBuilder: (context, index) {
                final data = transfers[index];
                return Card(
                  elevation: 3,
                  color: Colors.white,
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        data.invoiceNo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateHelper.displayDate(data.inDate),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      // Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                                      // const SizedBox(width: 4),
                                      Text(
                                        'From: ${data.fromLocation.name.isNotEmpty ? data.fromLocation.name : 'N/A'}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.arrow_forward,
                                          size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'To: ${data.toLocation.name.isNotEmpty ? data.toLocation.name : 'N/A'}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                expandedItemId == data.id
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              onPressed: () {
                                setState(() {
                                  expandedItemId = expandedItemId == data.id
                                      ? null
                                      : data.id;
                                });
                              },
                            )
                          ],
                        ),
                      ),
                      if (expandedItemId == data.id)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              for (var detail in data.detail)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (detail.productName ?? '').toUpperCase(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${detail.unit} | Qty ${detail.quantity} | ${detail.batch_code != null ? detail.batch_code : 'N/A'} | ${detail.expiry != null ? detail.expiry : 'N/A'}",
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll(
                                            AppConfig.colorPrimary),
                                        shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5)))),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        StocKTransfer_Inner.routeName,
                                        arguments: {'id': data.id},
                                      );
                                      print("DATAA${data.id}");
                                    },
                                    child: const Text(
                                      "Add",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll(
                                            AppConfig.colorPrimary),
                                        shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5)))),
                                    onPressed: () async {
                                      try {
                                        await completeStockTransfer(data.id);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "Stock Transfer Completed!")),
                                        );

                                        // ✅ Refresh list after completion
                                        setState(() {
                                          futureTransfers =
                                              fetchStockTransfers();
                                        });
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text("Error: $e")),
                                        );
                                      }
                                    },
                                    child: const Text("Complete",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class StockTransferResponse {
  final List<StockTransfer> data;
  final bool success;

  StockTransferResponse({required this.data, required this.success});

  factory StockTransferResponse.fromJson(Map<String, dynamic> json) {
    return StockTransferResponse(
      data:
          (json['data'] as List).map((e) => StockTransfer.fromJson(e)).toList(),
      success: json['success'],
    );
  }
}

class StockTransfer {
  final int id;
  final String invoiceNo;
  final String inDate;
  final String status;
  final List<StockDetail> detail;
  final Location fromLocation; // Add this
  final Location toLocation; // Add this

  StockTransfer({
    required this.id,
    required this.invoiceNo,
    required this.inDate,
    required this.status,
    required this.detail,
    required this.fromLocation,
    required this.toLocation,
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) {
    return StockTransfer(
      id: json['id'],
      invoiceNo: json['invoice_no'] ?? '',
      inDate: json['in_date'] ?? '',
      status: json['status'] ?? '',
      detail:
          (json['detail'] as List).map((e) => StockDetail.fromJson(e)).toList(),
      fromLocation: json['from_location'] != null
          ? Location.fromJson(json['from_location'])
          : Location.fromJson({}), // Empty location
      toLocation: json['to_location'] != null
          ? Location.fromJson(json['to_location'])
          : Location.fromJson({}), // Empty location
    );
  }
}

class StockDetail {
  final int id;
  final String? unit;
  final String? expiry;
  final String? batch_code;
  final String? quantity;
  final String? productName;

  StockDetail({
    required this.id,
    this.unit,
    this.expiry,
    this.batch_code,
    this.quantity,
    this.productName,
  });

  factory StockDetail.fromJson(Map<String, dynamic> json) {
    return StockDetail(
      id: json['id'],
      unit: json['unit'],
      expiry: json['expiry'] ?? '',
      batch_code: json['batch_code'] ?? '',
      quantity: json['quantity'],
      productName: json['producName'],
    );
  }
}

class Location {
  final int id;
  final String name;
  final String location;
  final String type;
  final String isDefault;
  final int storeId;
  final String storageType;
  final int status;
  final int parentId;

  Location({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.isDefault,
    required this.storeId,
    required this.storageType,
    required this.status,
    required this.parentId,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      type: json['type'] ?? '',
      isDefault: json['is_default'] ?? '',
      storeId: json['store_id'] ?? 0,
      storageType: json['storage_type'] ?? '',
      status: json['status'] ?? 0,
      parentId: json['parent_id'] ?? 0,
    );
  }
}
