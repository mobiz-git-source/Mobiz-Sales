import 'dart:io';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart' as btp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:mobizapp/Utilities/cpcl_helper.dart';

class PrinterTest extends StatefulWidget {
  @override
  _PrinterTestState createState() => _PrinterTestState();
}

class _PrinterTestState extends State<PrinterTest> {
  // Android Printer
  btp.BlueThermalPrinter androidPrinter = btp.BlueThermalPrinter.instance;
  List<btp.BluetoothDevice> _androidDevices = [];
  btp.BluetoothDevice? _selectedAndroidDevice;

  // iOS BLE
  List<ble.BluetoothDevice> _iosDevices = [];
  ble.BluetoothDevice? _selectedIosDevice;

  // Printer type: true = Zebra (CPCL), false = Sewoo (ESC/POS)
  bool _isZebra = false;

   Future<void> _loadPrinterType() async {
    // loadPrinterTypeCache() now derives the type from whichever device
    // is currently saved as selected_device_address, so this reads that
    // same resolved value instead of the legacy global key directly.
    await loadPrinterTypeCache();
    if (mounted) setState(() => _isZebra = getCachedIsZebra());
  }

  @override
  void initState() {
    super.initState();
    _loadPrinterType();
    if (Platform.isAndroid) {
      _loadSelectedAndroidDevice();
      _getAndroidDevices();
    } else if (Platform.isIOS) {
      _getIosDevices();
    }
  }

  // Load selected device for Android
  void _loadSelectedAndroidDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDeviceAddress = prefs.getString('selected_device_address');

    if (savedDeviceAddress != null && savedDeviceAddress.isNotEmpty) {
      List<btp.BluetoothDevice> devices = await androidPrinter.getBondedDevices();
      btp.BluetoothDevice? deviceToSelect;

      for (btp.BluetoothDevice device in devices) {
        if (device.address == savedDeviceAddress) {
          deviceToSelect = device;
          break;
        }
      }

      setState(() {
        _androidDevices = devices;
        _selectedAndroidDevice = deviceToSelect;
      });
    }
  }

  void _getAndroidDevices() async {
    List<btp.BluetoothDevice> devices = await androidPrinter.getBondedDevices();
    setState(() {
      _androidDevices = devices;
    });
  }

  void _getIosDevices() async {
    _iosDevices.clear();
    setState(() {});
    await ble.FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    ble.FlutterBluePlus.scanResults.listen((List<ble.ScanResult> results) {
      setState(() {
        _iosDevices = results.map((r) => r.device).toList();
      });
    });
  }


  // Select device
    // Select device
// Select device
  void _onDeviceSelected(dynamic device) async {
    if (device is btp.BluetoothDevice) {
      // Android device selection
      setState(() {
        _selectedAndroidDevice = device;
      });

      // 1. Connect immediately to the selected device
      try {
        bool? isConnected = await androidPrinter.isConnected;
        if (isConnected != true) {
          await androidPrinter.connect(device);
        }
      } catch (e) {
        print("Bluetooth connection error: $e");
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_device_address', device.address ?? '');

      // Load (or force a choice for) THIS device's printer type
      final savedType = await getSavedPrinterTypeForDevice(device.address ?? '');
      if (savedType != null) {
        setState(() => _isZebra = savedType);
        await savePrinterTypeForDevice(device.address ?? '', savedType);
        await loadPrinterTypeCache(); // Refresh global cache
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Connected: ${device.name} — Type: ${savedType ? "Zebra (CPCL)" : "Sewoo (ESC/POS)"}')),
        );
      } else {
        // First time this device is used — require an explicit choice
        if (!mounted) return;
        final chosen = await _askPrinterTypeForNewDevice(device.name ?? 'this printer');
        if (chosen != null) {
          await savePrinterTypeForDevice(device.address ?? '', chosen);
          await loadPrinterTypeCache(); // Refresh global cache
          if (mounted) setState(() => _isZebra = chosen);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Connected: ${device.name} — Saved as: ${chosen ? "Zebra" : "Sewoo"}')),
          );
        }
      }
    } else if (device is ble.BluetoothDevice) {
      // iOS device selection
      setState(() {
        _selectedIosDevice = device;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected device: ${device.name}')),
      );
    }
  }
  Future<bool?> _askPrinterTypeForNewDevice(String deviceName) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('New printer detected'),
        content: Text(
            'Is "$deviceName" a Zebra or a Sewoo printer? '
            'This is saved specifically for this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Sewoo'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Zebra'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Devices')),
      body: Platform.isAndroid
          ? Column(
              children: [
                // ── Printer type selector ──
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Printer Type',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Sewoo')),
                          ButtonSegment(value: true, label: Text('Zebra')),
                        ],
                        selected: {_isZebra},
                        onSelectionChanged: (s) async {
  final v = s.first;
  final address = _selectedAndroidDevice?.address;
  if (address != null && address.isNotEmpty) {
    await savePrinterTypeForDevice(address, v);
  } else {
    await savePrinterType(v);
  }
  await loadPrinterTypeCache(); 
  if (!mounted) return;
  setState(() => _isZebra = v);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text(v
            ? 'Printer type: Zebra (CPCL)'
            : 'Printer type: Sewoo (ESC/POS)')),
  );
},
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // ── Device list ──
                Expanded(
                  child: _androidDevices.isEmpty
                      ? const Center(child: Text('No Bluetooth devices found'))
                      : ListView.builder(
                          itemCount: _androidDevices.length,
                          itemBuilder: (context, index) {
                            final device = _androidDevices[index];
                            return ListTile(
                              title: Text(device.name ?? 'Unnamed Device'),
                              subtitle: Text(device.address ?? ''),
                              trailing: _selectedAndroidDevice == device
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                              onTap: () => _onDeviceSelected(device),
                            );
                          },
                        ),
                ),
              ],
            )
          : _iosDevices.isEmpty
              ? Center(child: Text('No BLE printers found'))
              : ListView.builder(
                  itemCount: _iosDevices.length,
                  itemBuilder: (context, index) {
                    final device = _iosDevices[index];
                    return ListTile(
                      title: Text(device.name ?? 'Unnamed BLE Device'),
                      trailing: _selectedIosDevice == device
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () => _onDeviceSelected(device),
                    );
                  },
                ),
    );
  }
}
