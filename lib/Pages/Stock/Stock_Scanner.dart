import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobizapp/Models/appstate.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool isLoading = false;
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  // Existing QR Fetching Logic
  Future<void> fetchProduct({
    required String productId,
    required String unit,
    String? batch,
    String? expiry,
  }) async {
    setState(() => isLoading = true);

    final url = Uri.parse(
      "http://68.183.92.8:3699/api/scan-qr?product_id=$productId&unit=$unit",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == true) {
          data["batch"] = batch ?? "";
          data["expiry"] = expiry ?? "";
          if (mounted) Navigator.pop(context, data);
        } else {
          _showError("Invalid product QR code");
        }
      } else {
        _showError("Failed: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchBarcodeProduct(String barcode) async {
    setState(() => isLoading = true);

    final url = Uri.parse(
      "http://68.183.92.8:3699/api/stock-transfer/scan-barcode?scanData=$barcode&store_id=${AppState().storeId}&user_id=${AppState().userId}",
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == true) {
          // Barcodes usually don't have batch/expiry encoded
          data["batch"] = "";
          data["expiry"] = "";
          if (mounted) Navigator.pop(context, data);
        } else {
          _showError("Product not found for barcode: $barcode");
        }
      } else {
        _showError("Failed: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) async {
    _cameraController.stop();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) _cameraController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR / Barcode")),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: MobileScanner(
              controller: _cameraController,
              onDetect: (capture) async {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? code = barcode.rawValue;
                  if (code == null) continue;

                  print("🔹 Scanned Code: $code");

                  // 1. Try to parse as QR format: product_id=10213;unit=149;batch=1;expiry=2025-09-30
                  final parts = code.split(';');
                  final Map<String, String> dataMap = {};

                  for (var part in parts) {
                    final keyValue = part.split('=');
                    if (keyValue.length == 2) {
                      dataMap[keyValue[0].trim()] = keyValue[1].trim();
                    }
                  }

                  final productId = dataMap['product_id'];
                  final unit = dataMap['unit'];

                  if (productId != null && unit != null) {
                    // ✅ Successfully identified as QR format
                    _cameraController.stop();
                    await fetchProduct(
                      productId: productId,
                      unit: unit,
                      batch: dataMap['batch'],
                      expiry: dataMap['expiry'],
                    );
                    break;
                  } else {
                    // 2. Treat as standard Barcode
                    _cameraController.stop();
                    await fetchBarcodeProduct(code);
                    break;
                  }
                }
              },
            ),
          ),
          if (isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Scan a QR code or Barcode to fetch product",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
