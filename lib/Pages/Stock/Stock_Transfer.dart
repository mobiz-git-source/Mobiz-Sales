import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/Stock/StockTransfer_Page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../Components/commonwidgets.dart';
import '../../confg/appconfig.dart';
import '../../confg/sizeconfig.dart';
import 'Stock_Scanner.dart';

class StocKTransfer_Inner extends StatefulWidget {
  static const routeName = "/StocKTransfer_Inner";
  const StocKTransfer_Inner({super.key});

  @override
  State<StocKTransfer_Inner> createState() => _StocKTransfer_InnerState();
}

class _StocKTransfer_InnerState extends State<StocKTransfer_Inner> {
  List<Map<String, dynamic>> savedProducts = [];
  bool _isSaving = false;
  double totalAmount = 0.0;
  int? dataId;
  bool showLocationFields = false;
  final TextEditingController fromLocationController = TextEditingController();
  final TextEditingController toLocationController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController unitNameController = TextEditingController();
  final FocusNode barcodeFocusNode = FocusNode();

  @override
  void dispose() {
    fromLocationController.dispose();
    toLocationController.dispose();
    barcodeController.dispose();
    productNameController.dispose();
    quantityController.dispose();
    unitNameController.dispose();
    super.dispose();
  }

  Future<void> clearCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_products');
    setState(() {
      savedProducts.clear();
    });
  }

  Future<void> _removeProduct(int index) async {
    setState(() {
      savedProducts.removeAt(index);
      totalAmount = savedProducts.fold(0.0, (sum, product) {
        final quantity =
            double.tryParse(product['quantity']?.toString() ?? '0') ?? 0.0;
        final amount =
            double.tryParse(product['amount']?.toString() ?? '0') ?? 0.0;
        return sum + (quantity * amount);
      });
    });

    final prefs = await SharedPreferences.getInstance();
    final savedProductsStringList =
    savedProducts.map((product) => jsonEncode(product)).toList();
    await prefs.setStringList('selected_products', savedProductsStringList);
  }

  Future<void> postScannedProductImmediately(Map<String, dynamic> product) async {
    try {
      final Map<String, String> requestData = {
        'id': (dataId ?? 0).toString(),
        "store_id": AppState().storeId.toString(),
        "product_id": product["id"].toString(),
        "unit_id": product["unit_id"]?.toString() ?? "",
        "quantity": product["quantity"].toString(),
        'batch_code': product["batch"]?.toString() ?? "",
        'expiry': product["expiry"]?.toString() ?? "",
        "user_id": AppState().userId.toString(),
        "van_id": AppState().vanId.toString(),
        'remarks': remarksController.text.trim(),
      };

      final url = Uri.parse("http://68.183.92.8:3699/api/store-scan");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Accept": "application/json",
        },
        body: requestData,
      );

      print("📤 Immediate Post Response: ${response.body}");
      print("📤 Immediate Post Data: $requestData");

      if (response.statusCode == 201) {
        remarksController.clear();
        print("✅ Product posted successfully: ${product['name']}");
        // Product is already in savedProducts list, no need to add again
      } else {
        print("❌ Failed to post product: ${response.body}");
        // Remove from list if post failed
        setState(() {
          savedProducts.removeWhere((p) => p['id'] == product['id'] && p['batch'] == product['batch']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save ${product['name']}")),
        );
      }
    } catch (e) {
      print("🚨 Error posting product: $e");
      // Remove from list if exception
      setState(() {
        savedProducts.removeWhere((p) => p['id'] == product['id'] && p['batch'] == product['batch']);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving ${product['name']}: $e")),
      );
    }
  }

  void _handleBarcodeScan(String value) async {
    if (value.isEmpty) return;

    try {
      print("🔹 Scanned input: $value");

      // 1. Check if it's QR format (product_id=...;unit=...)
      final parts = value.split(';');
      final Map<String, String> dataMap = {};
      for (var part in parts) {
        final keyValue = part.split('=');
        if (keyValue.length == 2) {
          dataMap[keyValue[0].trim()] = keyValue[1].trim();
        }
      }

      final productId = dataMap['product_id'];
      final unitId = dataMap['unit'];

      Uri url;
      if (productId != null && unitId != null) {
        // Use QR API
        url = Uri.parse("http://68.183.92.8:3699/api/scan-qr?product_id=$productId&unit=$unitId");
      } else {
        // Treat as normal barcode
        url = Uri.parse("http://68.183.92.8:3699/api/stock-transfer/scan-barcode?scanData=$value");
      }

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print("API Response: ${response.body}");
print("Decoded Result: $result");
        if (result["status"] == true) {
          int enteredQty = int.tryParse(quantityController.text.trim()) ?? 1;
          if (enteredQty <= 0) enteredQty = 1;

          final Map<String, dynamic> product = {
            'id': result['product_id'] ?? '',
            'name': result['product_name'] ?? '',
            'unit_name': result['unit_name'] ?? '',
            'unit_id': result['unit'] ?? '',
            'quantity': enteredQty,
            'code': result['product_id'] ?? '',
            'batch': dataMap['batch'] ?? '',
            'expiry': dataMap['expiry'] ?? '',
            'type_name': "Scanned",
            'tax_percentage': result['tax_percentage'] ?? 0,
          };

          setState(() {
            savedProducts.insert(0, product); // Add to top of list
            productNameController.text = result['product_name'] ?? '';
            unitNameController.text = result['unit_name'] ?? '';
          });

          await postScannedProductImmediately(product);

          barcodeController.clear();
          FocusScope.of(context).requestFocus(barcodeFocusNode);

          // Reset quantity for next scan
          Future.delayed(const Duration(milliseconds: 100), () {
            quantityController.text = '1';
          });
        } else {
          _showError(result["message"] ?? "Product not found");
        }
      } else {
        _showError("Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Something went wrong: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _handleQRScannerResult(Map<String, dynamic> result) async {
    // Get quantity (use entered quantity or default to 1)
    int enteredQty = int.tryParse(quantityController.text.trim()) ?? 1;
    if (enteredQty <= 0) enteredQty = 1; // Ensure at least 1

    // Create product object
    final Map<String, dynamic> product = {
      'id': result['product_id'],
      'name': result['product_name'],
      'unit_name': result['unit_name'],
      'unit_id': result['unit'],
      'quantity': enteredQty,
      'code': result['product_id'],
      'batch': result['batch'] ?? '',
      'expiry': result['expiry'] ?? '',
      'type_name': "Scanned",
    };

    // Add to UI list immediately
    setState(() {
      savedProducts.add(product);
      productNameController.text = result['product_name'];
      unitNameController.text = result['unit_name'];
    });

    // Post immediately to API
    await postScannedProductImmediately(product);

    // Clear and reset for next scan
    barcodeController.clear();
    FocusScope.of(context).requestFocus(barcodeFocusNode);

    // Reset quantity to 1 for next scan
    Future.delayed(const Duration(milliseconds: 100), () {
      quantityController.text = '1';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params =
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

      if (params != null) {
        // Case 1: contains id, fromName, and toName → show fields
        if (params.containsKey('id') &&
            params.containsKey('fromName') &&
            params.containsKey('toName')) {
          dataId = params['id'];
          fromLocationController.text = params['fromName'] ?? '';
          toLocationController.text = params['toName'] ?? '';
          showLocationFields = true;
        }
        else if (params.containsKey('id')) {
          dataId = params['id'];
          showLocationFields = false;
        } else {
          showLocationFields = false;
        }
      } else {
        showLocationFields = false;
      }
    } else {
      showLocationFields = false;
    }

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
              clearCart();
            },
            child: const Icon(Icons.arrow_back_rounded)),
        iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
        title: const Text(
          'Stock Transfer',
           style: AppConfig.pageTitleStyle,
        ),
        backgroundColor: AppConfig.colorPrimary,
        actions: [
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScannerScreen()),
              );

              if (result != null && result is Map<String, dynamic>) {
                _handleQRScannerResult(result); // Use the new handler
              }
            },
            child: const Icon(
              Icons.qr_code_scanner,
              size: 30,
              color: AppConfig.backgroundColor,
            ),
          ),

          CommonWidgets.horizontalSpace(3),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showLocationFields) ...[
                TextFormField(
                controller: fromLocationController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "From Location",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: toLocationController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "To Location",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              ],
              TextFormField(
                controller: barcodeController,
                focusNode: barcodeFocusNode, // 👈 Added focus node
                decoration: InputDecoration(
                  labelText: "Scan Barcode",
                  hintText: "Scan the product",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                autofocus: true,
                onFieldSubmitted: _handleBarcodeScan,
              ),
              // SizedBox(height: 20.h),
              // TextFormField(
              //   controller: productNameController,
              //   readOnly: true,
              //   decoration: InputDecoration(
              //     labelText: "Product Name",
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              // ),
              // SizedBox(height: 12.h),
              // TextFormField(
              //   controller: unitNameController,
              //   readOnly: true,
              //   decoration: InputDecoration(
              //     labelText: "Unit",
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              // ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: quantityController,
                // readOnly: true,
                decoration: InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: remarksController,
                // readOnly: true,
                decoration: InputDecoration(
                  labelText: "Remarks",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              savedProducts.isEmpty
                  ? const Center(child: Text('No scanned products'))
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: savedProducts.length,
                itemBuilder: (context, index) {
                  final product = savedProducts[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${product['name'].toString().toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: AppConfig.textCaption3Size,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _removeProduct(index),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            // Text('Type: ${product['type_name']}'),
                            Text('Unit: ${product['unit_name']}'),
                            Text('Qty: ${product['quantity']}'),
                            if (product['batch'] != null && product['batch'].toString().isNotEmpty)
                              Text('Batch: ${product['batch']}'),
                            if (product['expiry'] != null && product['expiry'].toString().isNotEmpty)
                              Text('Expiry: ${product['expiry']}'),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 50,)
            ],
          ),
        ),
      ),

      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: SizedBox(
      //   width: SizeConfig.blockSizeHorizontal * 70,
      //   height: SizeConfig.blockSizeVertical * 7,
      //   child: ElevatedButton(
      //     style: ButtonStyle(
      //       shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      //         RoundedRectangleBorder(
      //           borderRadius: BorderRadius.circular(7.0),
      //         ),
      //       ),
      //       backgroundColor: (savedProducts.isNotEmpty) && !_isSaving
      //           ? const WidgetStatePropertyAll(AppConfig.colorPrimary)
      //           : const WidgetStatePropertyAll(AppConfig.buttonDeactiveColor),
      //     ),
      //     onPressed: (savedProducts.isNotEmpty) && !_isSaving
      //         ? () async {
      //       await saveData();
      //     }
      //         : null,
      //     child: Text(
      //       'SAVE',
      //       style: TextStyle(
      //         fontSize: AppConfig.textCaption3Size,
      //         color: AppConfig.backgroundColor,
      //         fontWeight: AppConfig.headLineWeight,
      //       ),
      //     ),
      //   ),
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: SizeConfig.blockSizeHorizontal * 70,
        height: SizeConfig.blockSizeVertical * 7,
        child: ElevatedButton(
          style: ButtonStyle(
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7.0),
              ),
            ),
            backgroundColor: const WidgetStatePropertyAll(AppConfig.colorPrimary),
          ),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              StockTransferPage.routeName,
                  (route) => false,
            );
          },
          child: Text(
            'DONE',
            style: TextStyle(
              fontSize: AppConfig.textCaption3Size,
              color: AppConfig.backgroundColor,
              fontWeight: AppConfig.headLineWeight,
            ),
          ),
        ),
      ),
    );
  }
}