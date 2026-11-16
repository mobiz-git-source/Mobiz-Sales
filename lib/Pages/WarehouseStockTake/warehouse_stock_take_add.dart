import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import '../../confg/appconfig.dart';
import '../Picking/PickingScan.dart'; // scanner reuse
import 'warehouse_stock_take_list.dart';

const Color _kBorder = Color(0xFFD9DCF0);
const Color _kTint = Color(0xFFEEF0FF);

class WarehouseStockTakeAddPage extends StatefulWidget {
  static const routeName = "/WarehouseStockTakeAddPage";
  final WarehouseStockTake stockTake;
  const WarehouseStockTakeAddPage({super.key, required this.stockTake});

  @override
  State<WarehouseStockTakeAddPage> createState() =>
      _WarehouseStockTakeAddPageState();
}

class _WarehouseStockTakeAddPageState extends State<WarehouseStockTakeAddPage> {
  final barcodeController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  final batchController = TextEditingController();
  final barcodeFocusNode = FocusNode();

  String? expiryDate;      // yyyy-MM-dd
  String? productionDate;  // yyyy-MM-dd

  final List<Map<String, dynamic>> scannedItems = [];
  bool isSubmitting = false;

  // Current selected / scanned product
  Map<String, dynamic>? _current;

  // Purchased mode
  bool _purchasedMode = false;
  bool _loadingPurchased = false;
  List<Map<String, dynamic>> _purchased = [];
  List<Map<String, dynamic>> _units = []; // selected product-nte units

  String get _base => RestDatasource().BASE_URL;
  // ---------- helpers ----------
  Future<void> _pickDate(bool isExpiry) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    final s = DateFormat('yyyy-MM-dd').format(d);
    setState(() => isExpiry ? expiryDate = s : productionDate = s);
  }

  void _showMessage(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      duration: Duration(seconds: isError ? 6 : 2),
    ));
  }

    void _applyProduct(Map<String, dynamic> data) {
    setState(() {
      _units = [];
      _current = {
        'product_id': data['product_id'],
        'unit_id': data['unit_id'] ?? data['unit'],
        'product_name': data['product_name'] ?? 'Unknown Product',
        'unit_name': data['unit_name'] ?? '',
      };
      if ((data['batch'] ?? '').toString().isNotEmpty) {
        batchController.text = data['batch'].toString();
      }
      final exp = (data['expire'] ?? data['expiry'] ?? '').toString();
      if (exp.isNotEmpty) expiryDate = exp;
    });
  }

  Future<void> _onBarcodeSubmit(String value) async {
    final code = value.trim();
    if (code.isEmpty) return;
    try {
      final url = Uri.parse("$_base/api/scan-qr-barcode")
          .replace(queryParameters: {"scanData": code});
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result["status"] == true) {
          _applyProduct(Map<String, dynamic>.from(result));
        } else {
          _showMessage(result["message"] ?? "Invalid scan data", true);
        }
      } else {
        _showMessage("Error: ${response.statusCode}", true);
      }
    } catch (e) {
      _showMessage("Something went wrong: $e", true);
    }
    barcodeController.clear();
    FocusScope.of(context).requestFocus(barcodeFocusNode);
  }

  Future<void> _openScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PickingScannerScreen()),
    );
    if (result is Map && result['data'] is Map) {
      _applyProduct(Map<String, dynamic>.from(result['data']));
    }
  }

    // ---------- Purchased items ----------
  Future<void> _loadPurchased() async {
    if (_purchased.isNotEmpty || _loadingPurchased) return;
    setState(() => _loadingPurchased = true);
    try {
      // NOTE: path/params Arya-yodu confirm cheyyuka
      final res = await RestDatasource().getDetails(
          "/api/products/purchased?store_id=${AppState().storeId}",
          AppState().token);
      debugPrint('PURCHASED RESP: $res');
      dynamic raw = res;
      if (res is Map) {
        raw = res['data'] ?? res['success'] ?? res['products'] ?? [];
      }
      _purchased = (raw as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      _showMessage('Could not load purchased items: $e', true);
    }
    if (mounted) setState(() => _loadingPurchased = false);
  }

  void _applyPurchased(Map<String, dynamic> p) {
    final details = ((p['product_details'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final units = details.map((d) {
      final rel = (d['unit_relation'] as Map?) ?? {};
      return {'id': d['unit'], 'name': (rel['name'] ?? '').toString()};
    }).toList();
    final base = (p['baseunit'] as Map?) ?? {};
    setState(() {
      _units = units;
      _current = {
        'product_id': p['id'],
        'unit_id': p['base_unit_id'] ?? base['id'],
        'product_name': p['name'] ?? 'Unknown Product',
        'unit_name': (base['name'] ?? '').toString(),
      };
    });
  }

  Future<void> _selectManually() async {
    await _loadPurchased();
    if (_purchased.isEmpty) {
      _showMessage('No purchased items found', true);
      return;
    }
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        String q = '';
        return StatefulBuilder(builder: (ctx, setSheet) {
          final list = _purchased
              .where((p) => (p['name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(q.toLowerCase()))
              .toList();
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      decoration: _dec(
                          hint: 'Search product',
                          prefix: const Icon(Icons.search)),
                      onChanged: (v) => setSheet(() => q = v),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text((list[i]['name'] ?? '').toString()),
                        onTap: () => Navigator.pop(ctx, list[i]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
    if (picked != null) _applyPurchased(picked);
  }
  // ---------- add to list ----------
  void _addToList() {
    if (_current == null) {
      _showMessage('Scan or select a product first', true);
      return;
    }
    final qty = double.tryParse(qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      _showMessage('Enter a valid quantity', true);
      return;
    }
    setState(() {
      scannedItems.add({
        ..._current!,
        'qty': qty,
        'batch_no': batchController.text.trim(),
        'expiry_date': expiryDate ?? '',
               'production_date': productionDate ?? '',
      });
          _current = null;
      _units = [];
      qtyController.text = '1';
      batchController.clear();
      expiryDate = null;
      productionDate = null;
    });
  }

  // ---------- save ----------
  Future<void> _submit() async {
    if (scannedItems.isEmpty) {
      _showMessage('No items scanned', true);
      return;
    }
    if (isSubmitting) return;
    setState(() => isSubmitting = true);

    final failed = <Map<String, dynamic>>[];
    String lastError = '';
    final url = Uri.parse('$_base/api/warehouse-stock-takes/scan');

    for (final item in scannedItems) {
      final body = {
        // TODO: key names Arya-yodu confirm cheyyuka (response-il ninnu guess)
             "stock_take_id": widget.stockTake.id,
        "product_id": int.tryParse(item["product_id"].toString()) ?? 0,
        "unit_id": int.tryParse(item["unit_id"].toString()) ?? 0,
           "qty": (item["qty"] as num) == (item["qty"] as num).roundToDouble()
            ? (item["qty"] as num).toInt()
            : item["qty"],
        "expiry_date": item["expiry_date"],
        "batch_no": item["batch_no"],
        "production_date": item["production_date"],
        "user_id": AppState().userId,
        "store_id": AppState().storeId,
      };
      debugPrint('WST POST: ${jsonEncode(body)}');
      try {
        final r = await http
            .post(url,
                headers: {
                  "Content-Type": "application/json",
                  "Accept": "application/json",
                },
                body: jsonEncode(body))
            .timeout(const Duration(seconds: 30));
        debugPrint('WST RESP: ${r.statusCode} ${r.body}');
        dynamic d;
        try { d = jsonDecode(r.body); } catch (_) {}
        final ok = (r.statusCode == 200 || r.statusCode == 201) &&
            d is Map && d['status'] == true;
        if (!ok) {
          failed.add(item);
          lastError = (d is Map && d['message'] != null)
              ? d['message'].toString()
              : 'HTTP ${r.statusCode}: ${r.body}';
        }
      } catch (e) {
        failed.add(item);
        lastError = 'Network error: $e';
      }
    }

    if (!mounted) return;
    setState(() {
      scannedItems..clear()..addAll(failed);
      isSubmitting = false;
    });

    if (failed.isEmpty) {
      _showMessage('All items saved successfully!');
      Navigator.pop(context, true);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Failed to Save', style: TextStyle(color: Colors.red)),
          content: Text('$lastError\n\n${failed.length} item(s) remain for retry.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    }
  }

  // ---------- UI ----------
  InputDecoration _dec({String? hint, Widget? prefix, Widget? suffix}) {
    final b = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kBorder),
    );
    return InputDecoration(
      hintText: hint, filled: true, fillColor: Colors.white,
      prefixIcon: prefix, suffixIcon: suffix,
      border: b, enabledBorder: b, focusedBorder: b,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Widget _dateField(String label, String? value, bool isExpiry) {
    return InkWell(
      onTap: () => _pickDate(isExpiry),
      child: InputDecorator(
        decoration: _dec(prefix: const Icon(Icons.calendar_today, size: 18)),
        child: Text(value ?? label,
            style: TextStyle(color: value == null ? Colors.grey : Colors.black)),
      ),
    );
  }

  @override
  void dispose() {
    barcodeController.dispose();
    qtyController.dispose();
    batchController.dispose();
    barcodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(widget.stockTake.invoiceNo,
            style: AppConfig.pageTitleStyle.copyWith(color: Colors.white)),
        backgroundColor: AppConfig.colorPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.white),
                 onPressed: (isSubmitting || _purchasedMode) ? null : _openScanner,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
                // Mode toggle
          Row(
            children: [
              ChoiceChip(
                label: const Text('Scan'),
                selected: !_purchasedMode,
                onSelected: (_) => setState(() {
                  _purchasedMode = false;
                  _current = null;
                  _units = [];
                }),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Purchased'),
                selected: _purchasedMode,
                onSelected: (_) => setState(() {
                  _purchasedMode = true;
                  _current = null;
                  _units = [];
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!_purchasedMode)
            TextFormField(
              controller: barcodeController,
              focusNode: barcodeFocusNode,
              decoration: _dec(
                hint: 'Scan or Enter Barcode',
                prefix: const Icon(Icons.center_focus_strong_outlined),
                suffix: IconButton(
                  icon: Icon(Icons.qr_code_scanner,
                      color: AppConfig.colorPrimary),
                  onPressed: isSubmitting ? null : _openScanner,
                ),
              ),
              onFieldSubmitted: _onBarcodeSubmit,
            )
          else
            OutlinedButton.icon(
              onPressed:
                  (isSubmitting || _loadingPurchased) ? null : _selectManually,
              icon: _loadingPurchased
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search),
              label: const Text('Select Product Manually'),
            ),
          const SizedBox(height: 16),

          // Selected product
          if (_current != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kTint,
                border: Border.all(color: _kBorder),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_current!['product_name']}  (${_current!['unit_name']})',
                            style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          if (_current != null && _units.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: DropdownButtonFormField<String>(
                value: _units.any((u) =>
                        u['id'].toString() == _current!['unit_id']?.toString())
                    ? _current!['unit_id'].toString()
                    : null,
                decoration: _dec(hint: 'Unit'),
                items: _units
                    .map((u) => DropdownMenuItem<String>(
                          value: u['id'].toString(),
                          child: Text(u['name'].toString()),
                        ))
                    .toList(),
                onChanged: (v) {
                  final u = _units.firstWhere((e) => e['id'].toString() == v);
                  setState(() {
                    _current!['unit_id'] = u['id'];
                    _current!['unit_name'] = u['name'];
                  });
                },
              ),
            ),
          const SizedBox(height: 16),

          TextField(
            controller: qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec(hint: 'Quantity', prefix: const Icon(Icons.inventory_2)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: batchController,
            decoration: _dec(hint: 'Batch No', prefix: const Icon(Icons.numbers)),
          ),
          const SizedBox(height: 12),
          _dateField('Production Date', productionDate, false),
          const SizedBox(height: 12),
          _dateField('Expiry Date', expiryDate, true),
          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : _addToList,
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.colorPrimary),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add to list', style: TextStyle(color: Colors.white)),
            ),
          ),

          // Scanned list
          if (scannedItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Scanned Items', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...List.generate(scannedItems.length, (i) {
              final it = scannedItems[i];
              return Card(
                child: ListTile(
                  title: Text(it['product_name'].toString()),
                  subtitle: Text(
                      'Qty: ${it['qty']} | ${it['unit_name']} | Batch: ${it['batch_no']}\n'
                      'Prod: ${it['production_date']} | Exp: ${it['expiry_date']}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: isSubmitting
                        ? null
                        : () => setState(() => scannedItems.removeAt(i)),
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.colorPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text('Save',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}