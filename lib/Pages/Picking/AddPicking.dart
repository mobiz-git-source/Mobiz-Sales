import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import '../../confg/appconfig.dart';
import 'PickingScan.dart';

class PickingAddPage extends StatefulWidget {
  static const routeName = "/PickingAddPage";
  final int picklistId;
  final List<int> picklistDetailIds;

  const PickingAddPage({
    super.key,
    required this.picklistId,
    required this.picklistDetailIds,
  });

  @override
  State<PickingAddPage> createState() => _PickingAddPageState();
}

class _PickingAddPageState extends State<PickingAddPage> {
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final FocusNode barcodeFocusNode = FocusNode();
  int currentDetailIndex = 0;
  final List<Map<String, dynamic>> scannedItems = [];

  @override
  void initState() {
    super.initState();
    qtyController.text = '1';
    Future.delayed(const Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(barcodeFocusNode);
    });
    print(widget.picklistId);
    print(widget.picklistDetailIds);
  }

  Future<void> _onBarcodeSubmit(String value) async {
    if (value.isEmpty) return;

    try {
      print("🔹 Scanned input: $value");

      final url = Uri.parse(
        "http://68.183.92.8:3699/api/scan-qr-barcode?scanData=$value",
      );

      final response = await http.get(url);
      print("🔹 API Response: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result["status"] == true) {
          setState(() {
            int enteredQty = int.tryParse(qtyController.text.trim()) ?? 1;

            scannedItems.add({
              "product_id": result["product_id"] ?? "",
              "unit_id": result["unit"] ?? "",
              "product_name": result["product_name"] ?? "Unknown Product",
              "qty": enteredQty,
              "unit_name": result["unit_name"] ?? "",
              "batch": result["batch"] ?? "",
              "expiry": result["expire"] ?? "",
            });

            barcodeController.clear();
            qtyController.text = '1';
          });

          FocusScope.of(context).requestFocus(barcodeFocusNode);
        } else {
          _showMessage(result["message"] ?? "Invalid scan data", true);
        }
      } else {
        _showMessage("Error: ${response.statusCode}", true);
      }
    } catch (e) {
      _showMessage("Something went wrong: $e", true);
    }
  }


  Future<void> _openScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PickingScannerScreen()),
    );

    if (result == null) return;

    try {
      if (result is Map<String, dynamic>) {
        final data = result['data'] ?? result;
        if (data != null && data is Map<String, dynamic>) {
          int enteredQty = int.tryParse(qtyController.text.trim()) ?? 1;

          setState(() {
            scannedItems.add({
              "product_id": data["product_id"] ?? "",
              // ✅ Use correct unit_id (prefer API’s if present)
              "unit_id": data["unit_id"] ?? data["unit"] ?? "",
              "product_name": data["product_name"] ?? "Unknown Product",
              "qty": enteredQty,
              "unit_name": data["unit_name"] ?? "",
              "batch": data["batch"] ?? "",
              "expiry": data["expiry"] ?? "",
            });
            qtyController.text = '1';
          });
        }
      } else if (result is List) {
        for (var item in result) {
          if (item is Map<String, dynamic>) {
            int enteredQty = int.tryParse(qtyController.text.trim()) ?? 1;

            scannedItems.add({
              "product_id": item["product_id"] ?? "",
              // ✅ Use correct unit_id (prefer API’s if present)
              "unit_id": item["unit_id"] ?? item["unit"] ?? "",
              "product_name": item["product_name"] ?? "Unknown Product",
              "qty": enteredQty,
              "unit_name": item["unit_name"] ?? "",
              "batch": item["batch"] ?? "",
              "expiry": item["expiry"] ?? "",
            });
          }
        }
        setState(() {});
      } else {
        _showMessage("Invalid scan data received", true);
      }
    } catch (e) {
      _showMessage("Error reading scan: $e", true);
    }
  }

  Future<void> _submitPicking() async {
    if (scannedItems.isEmpty) {
      _showMessage("No items scanned", true);
      return;
    }

    try {
      for (var item in scannedItems) {
        final picklistDetailId = widget.picklistDetailIds.isNotEmpty
            ? widget.picklistDetailIds[currentDetailIndex % widget.picklistDetailIds.length]
            : null;
        final body = {
          "picklist_id": widget.picklistId,
          "picklist_detail_id": picklistDetailId,
          "product_id": int.tryParse(item["product_id"].toString()) ?? 0,
          "unit_id": int.tryParse(item["unit_id"].toString()) ?? 0,
          "qty": item["qty"],
          "expiry": item["expiry"],
          "batch": item["batch"],
          "user_id": AppState().userId,
          "store_id": AppState().storeId,
        };

        print("🔹 Posting body: $body");

        final url = Uri.parse('http://68.183.92.8:3699/api/picklist-picking-detail');
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        );

        final result = jsonDecode(response.body);
        print("🔹 API Response: $result");

        if (response.statusCode != 201 || result["status"] != true) {
          _showMessage("Failed to post item: ${item["product_name"]}", true);
          return;
        }
      }
      _showMessage("All items posted successfully!");
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage("Error: $e", true);
    }
  }

  void _showMessage(String msg, [bool isError = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Widget _buildScannedList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: scannedItems.length,
        itemBuilder: (context, index) {
          final item = scannedItems[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: index == scannedItems.length - 1
                      ? Colors.transparent
                      : Colors.grey.shade300,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["product_name"],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(flex: 1, child: Text("Qty: ${item["qty"]}", style: const TextStyle(fontSize: 13))),
                    Expanded(flex: 1, child: Text("Unit: ${item["unit_name"]}", style: const TextStyle(fontSize: 13))),
                    Expanded(flex: 1, child: Text("Batch: ${item["batch"]}", style: const TextStyle(fontSize: 13))),
                    Expanded(flex: 1, child: Text("Expiry: ${item["expiry"]}", style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    barcodeController.dispose();
    qtyController.dispose();
    barcodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Picking - Add', style: AppConfig.pageTitleStyle,),
        backgroundColor: AppConfig.colorPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.white),
            onPressed: _openScanner,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Scan Barcode'),
            const SizedBox(height: 5),
            TextFormField(
              controller: barcodeController,
              focusNode: barcodeFocusNode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Scan or Enter Barcode",
              ),
              autofocus: true,
              onFieldSubmitted: _onBarcodeSubmit,
            ),
            const SizedBox(height: 20),
            const Text('Qty'),
            const SizedBox(height: 5),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            if (scannedItems.isNotEmpty) ...[
              const Text('Scanned Items'),
              const SizedBox(height: 8),
              _buildScannedList(),
            ],
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _submitPicking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.colorPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
