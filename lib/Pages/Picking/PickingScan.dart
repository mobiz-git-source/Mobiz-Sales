import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

class PickingScannerScreen extends StatefulWidget {
  static const routeName = "/PickingScannerScreen";
  const PickingScannerScreen({super.key});

  @override
  State<PickingScannerScreen> createState() => _PickingScannerScreenState();
}

class _PickingScannerScreenState extends State<PickingScannerScreen> {
  bool isLoading = false;
  bool _isFetching = false; // prevent multiple triggers

  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  @override
  void initState() {
    super.initState();
    _cameraController.start();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> fetchProduct({required String scanData}) async {
    if (_isFetching) return;
    _isFetching = true;

    setState(() => isLoading = true);

    final url = Uri.parse(
      "http://68.183.92.8:3699/api/scan-qr-barcode?scanData=$scanData",
    );

    try {
      final response = await http.get(url);
      print("🔹 API Response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["status"] == true) {
          final Map<String, dynamic> productData = {
            "product_id": decoded["product_id"],
            "product_name": decoded["product_name"],
            "unit": decoded["unit"],
            "unit_name": decoded["unit_name"],
            "quantity": decoded["quantity"],
            "batch": decoded["batch"] ?? "",
            "expiry": decoded["expire"] ?? "",
          };

          Navigator.pop(context, {"data": productData});
        } else {
          _showError("Invalid product data");
        }
      } else {
        _showError("Failed: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
        _isFetching = false;
      });
      // 🔹 Restart the camera feed after every scan (unless popped)
      if (mounted) {
        _cameraController.start();
      }
    }
  }

  void _showError(String message) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR / Barcode",)),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _cameraController,
                  onDetect: (capture) async {
                    if (_isFetching) return;

                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final String? code = barcode.rawValue;
                      if (code == null) continue;
                      print("Scanned Code: $code");
                      _cameraController.stop();
                      await fetchProduct(scanData: code);
                      break;
                    }
                  },
                ),
                if (isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text("Scan a QR or Barcode to fetch product"),
            ),
          ),
        ],
      ),
    );
  }
}