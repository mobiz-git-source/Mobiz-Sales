import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import '../../confg/appconfig.dart';
import 'PickingScan.dart';

const String _baseUrl = 'http://68.183.92.8:3699';

const Color _kBorder = Color(0xFFD9DCF0);
const Color _kTint = Color(0xFFEEF0FF);
const Color _kNavy = Color(0xFF1B1F3B);
const Color _kGreen = Color(0xFF1E9E6A);
const Color _kBlue = Color(0xFF2F6FED);

class PickingAddPage extends StatefulWidget {
  static const routeName = "/PickingAddPage";
  final int picklistId;
 final List<int> picklistDetailIds;
final List<Map<String, dynamic>> picklistDetails;
const PickingAddPage({
  super.key,
  required this.picklistId,
  required this.picklistDetailIds,
  this.picklistDetails = const [],
});

  @override
  State<PickingAddPage> createState() => _PickingAddPageState();
}

class _PickingAddPageState extends State<PickingAddPage> {
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final FocusNode barcodeFocusNode = FocusNode();

  final List<Map<String, dynamic>> scannedItems = [];
  bool isSubmitting = false;

  // Suggestions (pager)
  List<Map<String, dynamic>> suggestions = [];
  int suggestionIndex = 0;
  bool isSuggestionLoading = false;
  String? suggestionMessage;

  // Locations
  List<Map<String, dynamic>> locations = [];
  String? selectedLocationId;
  bool isLocationLoading = false;
  String? locationError;

  // ---------- helpers ----------
  Map<String, dynamic>? get _currentSuggestion =>
      suggestions.isEmpty ? null : suggestions[suggestionIndex];

   /// true = Purchased, false = other supply type, null = unknown
  bool? _isPurchased(Map<String, dynamic>? s) {
    if (s == null) return null;
    final v = (s['supply_type'] ?? '').toString().toLowerCase();
    if (v.isEmpty) return null;
    return v == 'purchased';
  }

  String _unitLabel() => (_currentSuggestion?["unit_name"] ?? '').toString();

  @override
  void initState() {
    super.initState();
    qtyController.text = '1';
    debugPrint('Picklist ID: ${widget.picklistId}');
    debugPrint('Picklist Detail IDs: ${widget.picklistDetailIds}');
      _fetchLocations();
    _refreshSuggestions();
  }

  bool get _isCurrentPurchased => _isPurchased(_currentSuggestion) == true;
double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// scan cheythu, pakshe Save cheyyaatha qty (ee product-inu)
double _pendingQty(Map<String, dynamic> s) {
  final pid = s['product_id']?.toString();
  double sum = 0;
  for (final it in scannedItems) {
    if (it['product_id'].toString() == pid) sum += _num(it['qty']);
  }
  return sum;
  
}bool _qtyAllowed(dynamic productId, double entering) {
  final s = _currentSuggestion;
  if (s == null || s['product_id']?.toString() != productId?.toString()) {
    return true;
  }
  final total = _num(s['qty']);
  final remaining = total - _num(s['picked']) - _pendingQty(s);
  if (entering > remaining) {
    _showMessage(
        'Only ${_fmt(remaining < 0 ? 0 : remaining)} left to pick (Qty: ${_fmt(total)})',
        true);
    return false;
  }
  return true;
}
int? _detailIdFor(dynamic productId) {
  for (final raw in widget.picklistDetails) {
    final p = raw['product'] is Map ? raw['product'] as Map : {};
    final pid = raw['product_id'] ?? p['id'];
    if (pid?.toString() == productId?.toString()) {
      return int.tryParse(raw['id'].toString());
    }
  }
  return null;
}
  // ---------- LOCATIONS ----------
  Future<void> _fetchLocations() async {
    if (!mounted) return;
    setState(() {
      isLocationLoading = true;
      locationError = null;
    });
    try {
      final url = Uri.parse('$_baseUrl/api/pick-locations')
          .replace(queryParameters: {"store_id": '${AppState().storeId}'});
      debugPrint('🔹 LOCATION URL: $url');

      final response = await http.get(
        url,
        headers: {"Accept": "application/json"},
      ).timeout(const Duration(seconds: 20));
      debugPrint('🔹 LOCATION RESPONSE: ${response.statusCode} ${response.body}');

      dynamic result;
      try {
        result = jsonDecode(response.body);
      } catch (_) {}

      if (!mounted) return;

      if (response.statusCode == 200 && result is Map && result["data"] is List) {
        final list = (result["data"] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        setState(() {
          locations = list;
          // keep selection if still valid, else auto-select when only one
          final ids = list.map((e) => e["id"].toString()).toList();
          if (selectedLocationId != null && !ids.contains(selectedLocationId)) {
            selectedLocationId = null;
          }
          if (selectedLocationId == null && list.length == 1) {
            selectedLocationId = list.first["id"].toString();
          }
        });
      } else {
        setState(() => locationError = 'Could not load locations');
      }
    } catch (e) {
      debugPrint('🔹 LOCATION ERROR: $e');
      if (mounted) setState(() => locationError = 'Could not load locations');
    } finally {
      if (mounted) setState(() => isLocationLoading = false);
    }
  }

  String _locationName(Map<String, dynamic> l) =>
      (l["name"] ?? l["location_name"] ?? l["location"] ?? '').toString();

  String _selectedLocationName() {
    for (final l in locations) {
      if (l["id"].toString() == selectedLocationId) return _locationName(l);
    }
    return '';
  }
Future<void> _refreshSuggestions({bool keepPosition = false}) =>
    _fetchSuggestion(keepPosition: keepPosition);
  Future<void> _fetchSuggestion({bool keepPosition = false}) async {
  if (!mounted) return;
 final currentPid =
    keepPosition ? (_currentSuggestion?['product_id'])?.toString() : null;
  setState(() => isSuggestionLoading = true);
  try {
    final url = Uri.parse('$_baseUrl/api/picklist/suggestions/${widget.picklistId}');
    final response = await http.get(url, headers: {"Accept": "application/json"})
        .timeout(const Duration(seconds: 20));
    debugPrint('🔹 SUGGESTION RESPONSE: ${response.statusCode} ${response.body}');

    dynamic result;
    try { result = jsonDecode(response.body); } catch (_) {}
    if (!mounted) return;

    if (response.statusCode == 200 && result is Map && result["status"] == true) {
      final data = result["data"];
      List<Map<String, dynamic>> list = [];
      if (data is List) {
        list = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      } else if (data is Map) {
        list = [Map<String, dynamic>.from(data)];
      }
      var idx = 0;
      if (currentPid != null) {
        final found = list.indexWhere((e) => e['product_id']?.toString() == currentPid);
        if (found >= 0) idx = found;
      }
      setState(() {
        suggestions = list;
        suggestionIndex = idx;
        suggestionMessage = null;
      });
    } else {
      setState(() {
        suggestions = [];
        suggestionIndex = 0;
        suggestionMessage = result is Map ? result["message"]?.toString() : null;
      });
    }
  } catch (e) {
    debugPrint('🔹 SUGGESTION ERROR: $e');
    if (mounted) setState(() { suggestions = []; suggestionIndex = 0; });
  } finally {
    if (mounted) setState(() => isSuggestionLoading = false);
  }
}

  void _moveSuggestion(int step) {
    if (suggestions.length < 2) return;
    setState(() {
      suggestionIndex = (suggestionIndex + step) % suggestions.length;
      if (suggestionIndex < 0) suggestionIndex += suggestions.length;
    });
  }

  Widget _statHalf({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
       child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
                  Text(value,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700, color: _kNavy)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 22, color: _kNavy),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const Text(' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
        ],
      );

  InputDecoration _fieldDecoration({String? hint, Widget? prefix, Widget? suffix}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kBorder),
    );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefix,
      suffixIcon: suffix,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: AppConfig.colorPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Widget _buildSuggestionCard() {
    if (isSuggestionLoading && suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LinearProgressIndicator(),
      );
    }
    final s = _currentSuggestion;
    if (s == null) {
      if (suggestionMessage == null || suggestionMessage!.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(suggestionMessage!,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    final purchased = _isPurchased(s);
    final Color accent = purchased == true
        ? _kGreen
        : purchased == false
            ? _kBlue
            : AppConfig.colorPrimary;
 final total = _num(s["qty"]);
final apiPicked = _num(s["picked"]);
final pending = _pendingQty(s);
final pickedShow = apiPicked + pending;
final balanceShow = (total - pickedShow) < 0 ? 0.0 : (total - pickedShow);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FF),
        border: Border.all(color: _kBorder, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                         InkWell(
                onTap: isSuggestionLoading ? null : () => _refreshSuggestions(),
                child: Icon(Icons.lightbulb_outline,
                    size: 26, color: AppConfig.colorPrimary),
              ),
              const SizedBox(width: 10),
                          Expanded(
                child: Text(
                  (s["picklist_no"] ?? '').toString().isNotEmpty
                      ? 'Picklist ${s["picklist_no"]}'
                      : 'Next Item Suggestion',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppConfig.colorPrimary,
                  ),
                ),
              ),
        Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    if (suggestions.length > 1)
      InkWell(
        onTap: () => _moveSuggestion(-1),
        child: Icon(Icons.chevron_left, color: AppConfig.colorPrimary),
      ),
    Text(
      (s["position_label"] ??
              '${s["position"] ?? suggestionIndex + 1} / ${s["total_details"] ?? suggestions.length}')
          .toString(),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    if (suggestions.length > 1)
      InkWell(
        onTap: () => _moveSuggestion(1),
        child: Icon(Icons.chevron_right, color: AppConfig.colorPrimary),
      ),
  ],
),
            ],
          ),
          const SizedBox(height: 10),
               Text(
  [s["product_code"], s["product_name"]]
      .where((e) => (e ?? '').toString().isNotEmpty)
      .join('  |  '),
  style: const TextStyle(
      fontWeight: FontWeight.w700, fontSize: 16, color: _kNavy),
),

if ((s["supply_type"] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
    s["supply_type"].toString(),
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: accent),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text('Unit: ${s["unit_name"] ?? ""}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF444444))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
                       child: Row(
              children: [
                _statHalf(
                    icon: Icons.format_list_numbered,
                    label: 'Qty',
                    value: _fmt(total),
                    color: accent),
                Container(width: 1, height: 38, color: Colors.black12),
                _statHalf(
                    icon: Icons.check_circle,
                    label: 'Picked Qty',
                    value: _fmt(pickedShow),
                    color: accent),
                Container(width: 1, height: 38, color: Colors.black12),
                _statHalf(
                    icon: Icons.inventory_2_outlined,
                    label: 'Balance',
                    value: _fmt(balanceShow),
                    color: accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- LOCATION UI ----------
  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(Icons.location_on, 'Location'),
        const SizedBox(height: 8),
        if (isLocationLoading)
          const LinearProgressIndicator()
        else if (locationError != null)
          Row(
            children: [
              Expanded(
                child: Text(locationError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
              TextButton(onPressed: _fetchLocations, child: const Text('Retry')),
            ],
          )
        else
          DropdownButtonFormField<String>(
            value: selectedLocationId,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down),
            hint: const Text('Select location'),
            decoration: _fieldDecoration(
              prefix: const Icon(Icons.home_work_outlined, color: _kNavy),
            ),
            items: locations
                .map((l) => DropdownMenuItem<String>(
                      value: l["id"].toString(),
                      child: Text(_locationName(l), overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => selectedLocationId = v),
          ),
      ],
    );
  }

  bool _requireLocation() {
    if (selectedLocationId == null) {
      _showMessage("Please select a location", true);
      return false;
    }
    return true;
  }

   // ---------- ADD ITEM ----------
  bool _addItem(Map<String, dynamic> data, {int? qty}) {
    final enteredQty = qty ?? int.tryParse(qtyController.text.trim()) ?? 1;
    if (!_qtyAllowed(data["product_id"], enteredQty.toDouble())) return false;

    scannedItems.add({
      "product_id": data["product_id"] ?? "",
      "unit_id": data["unit_id"] ?? data["unit"] ?? "",
      "product_name": data["product_name"] ?? "Unknown Product",
      "qty": enteredQty,
      "unit_name": data["unit_name"] ?? "",
      "batch": data["batch"] ?? "",
      "expiry": data["expire"] ?? data["expiry"] ?? "",
      "location_id": selectedLocationId,
      "location_name": _selectedLocationName(),
      "picklist_detail_id": data["picklist_detail_id"],
    });
    return true;
  }

  Future<void> _onBarcodeSubmit(String value) async {
    final code = value.trim();
    if (code.isEmpty) return;
    if (!_requireLocation()) return;

    try {
      debugPrint("🔹 Scanned input: $code");
      final url = Uri.parse("$_baseUrl/api/scan-qr-barcode")
          .replace(queryParameters: {"scanData": code});

      final response = await http.get(url);
      debugPrint("🔹 API Response: ${response.body}");

      if (response.statusCode == 200) {
         final result = jsonDecode(response.body);
        if (result["status"] == true) {
         
       setState(() {
  if (_addItem(Map<String, dynamic>.from(result))) {
    barcodeController.clear();
    qtyController.text = '1';
  }
});
                 FocusScope.of(context).requestFocus(barcodeFocusNode);
          _refreshSuggestions(keepPosition: true);
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
    if (!_requireLocation()) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PickingScannerScreen()),
    );
    if (result == null) return;

    try {
      if (result is Map<String, dynamic>) {
         final data = result['data'] ?? result;
        if (data is Map<String, dynamic>) {
         
        setState(() {
  if (_addItem(data)) qtyController.text = '1';
});
          _refreshSuggestions(keepPosition: true);
        }
      } else if (result is List) {
        for (final item in result) {
          if (item is Map<String, dynamic>) {
           
            _addItem(item);
          }
        }
        setState(() {});
        _refreshSuggestions(keepPosition: true);
      } else {
        _showMessage("Invalid scan data received", true);
      }
    } catch (e) {
      _showMessage("Error reading scan: $e", true);
    }
  }
Widget _buildManualSelect() {
  final s = _currentSuggestion;
  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: (s == null || isSubmitting)
        ? null
        : () {
            if (!_requireLocation()) return;
          setState(() {
  if (_addItem({
    'product_id': s['product_id'],
    'unit_id': s['unit_id'],
    'product_name': s['product_name'],
    'unit_name': s['unit_name'],
    'picklist_detail_id': s['picklist_detail_id'],
  })) {
    qtyController.text = '1';
  }
});
            _refreshSuggestions(keepPosition: true);
          },
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kTint,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppConfig.colorPrimary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Select Product Manually *',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}
  Widget _buildBarcodeField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(Icons.view_week_outlined, 'Scan Barcode'),
          const SizedBox(height: 8),
          TextFormField(
            controller: barcodeController,
            focusNode: barcodeFocusNode,
            decoration: _fieldDecoration(
              hint: 'Scan or Enter Barcode',
              prefix: const Icon(Icons.center_focus_strong_outlined, color: _kNavy),
              suffix: Padding(
                padding: const EdgeInsets.all(6),
                child: Material(
                  color: _kTint,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: isSubmitting ? null : _openScanner,
                    child: Icon(Icons.qr_code_scanner,
                        color: AppConfig.colorPrimary, size: 24),
                  ),
                ),
              ),
            ),
            onFieldSubmitted: _onBarcodeSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildQtyField(String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(Icons.inventory_2, 'Quantity'),
        const SizedBox(height: 8),
        TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          decoration: _fieldDecoration(
            suffix: unit.isEmpty
                ? null
                : Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _kTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(unit,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF444444))),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ---------- SUBMIT ----------
  String _extractError(dynamic result, http.Response response) {
    if (result is Map) {
      if (result["errors"] is Map) {
        final list = <String>[];
        (result["errors"] as Map).forEach((key, val) {
          if (val is List) {
            list.addAll(val.map((e) => "$key: $e"));
          } else {
            list.add("$key: $val");
          }
        });
        if (list.isNotEmpty) return list.join("\n");
      }
      if (result["message"] != null) return result["message"].toString();
      if (result["error"] != null) return result["error"].toString();
    }
    return response.body.isNotEmpty ? response.body : "No response";
  }

  Future<void> _submitPicking() async {
    if (scannedItems.isEmpty) {
      _showMessage("No items scanned", true);
      return;
    }
    if (isSubmitting) return;

    setState(() => isSubmitting = true);

    final List<Map<String, dynamic>> failedItems = [];
    String lastErrorMessage = "";

    try {
      final url = Uri.parse('$_baseUrl/api/picklist-picking-detail');

      for (var i = 0; i < scannedItems.length; i++) {
        final item = scannedItems[i];

               final picklistDetailId =
            int.tryParse('${item["picklist_detail_id"] ?? ""}') ??
            _detailIdFor(item["product_id"]) ??
            (widget.picklistDetailIds.isNotEmpty
                ? widget.picklistDetailIds[i % widget.picklistDetailIds.length]
                : null);

        final body = {
          "picklist_id": widget.picklistId,
          "picklist_detail_id": picklistDetailId,
          "product_id": int.tryParse(item["product_id"].toString()) ?? 0,
          "unit_id": int.tryParse(item["unit_id"].toString()) ?? 0,
          "qty": item["qty"],
          "expiry": item["expiry"],
          "batch": item["batch"],
          // TODO: confirm the key name with backend (location_id / pick_location_id)
          "location_id": int.tryParse(item["location_id"].toString()) ?? 0,
          "user_id": AppState().userId,
          "store_id": AppState().storeId,
        };

        debugPrint("🔹 POSTING URL: $url");
        debugPrint("🔹 POSTING BODY: ${jsonEncode(body)}");

        http.Response response;
        try {
          response = await http
              .post(
                url,
                headers: {
                  "Content-Type": "application/json",
                  "Accept": "application/json",
                },
                body: jsonEncode(body),
              )
              .timeout(const Duration(seconds: 30));
        } catch (e) {
          failedItems.add(item);
          lastErrorMessage = "Network error: $e";
          continue;
        }
        debugPrint('POST STATUS: ${response.statusCode}');
        debugPrint('POST RESPONSE BODY: ${response.body}');

        dynamic result;
        try {
          result = jsonDecode(response.body);
        } catch (_) {}

        final ok = (response.statusCode == 200 || response.statusCode == 201) &&
            result is Map &&
            result["status"] == true;

        if (!ok) {
          failedItems.add(item);
          final err = _extractError(result, response);
          lastErrorMessage = err;
          debugPrint("❌ ERROR on ${item["product_name"]}: $err");
        }
      }

      setState(() {
        scannedItems
          ..clear()
          ..addAll(failedItems);
      });
       _refreshSuggestions(); // refresh picked qty / balance after every save

      if (failedItems.isEmpty) {
        _showMessage("All items posted successfully!");
        if (mounted) Navigator.pop(context, true);
      } else if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Failed to Post", style: TextStyle(color: Colors.red)),
            content: SingleChildScrollView(
              child: Text(
                "Error Details:\n\n$lastErrorMessage\n\n${failedItems.length} item(s) remain in the list for retry.",
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
            ],
          ),
        );
      }
    } catch (e) {
      _showMessage("Error: $e", true);
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showMessage(String msg, [bool isError = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: Duration(seconds: isError ? 6 : 2),
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["product_name"],
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: Text("Qty: ${item["qty"]}", style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text("Unit: ${item["unit_name"]}", style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text("Batch: ${item["batch"]}", style: const TextStyle(fontSize: 13))),
                          Expanded(child: Text("Expiry: ${item["expiry"]}", style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                      if ((item["location_name"] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text("Location: ${item["location_name"]}",
                              style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onPressed: isSubmitting
                      ? null
                      : () => setState(() => scannedItems.removeAt(index)),
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
    final unit = _unitLabel();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: const Text('Picking - Add', style: AppConfig.pageTitleStyle),
        backgroundColor: AppConfig.colorPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, color: Colors.white),
              onPressed: (isSubmitting || _isCurrentPurchased) ? null : _openScanner,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSuggestionCard(),
            _buildLocationField(),
            const SizedBox(height: 20),
         _isCurrentPurchased ? _buildManualSelect() : _buildBarcodeField(),
            const SizedBox(height: 20),
            _buildQtyField(unit),
            const SizedBox(height: 20),
            if (scannedItems.isNotEmpty) ...[
              const Text('Scanned Items',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildScannedList(),
            ],
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: isSubmitting ? null : _submitPicking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.colorPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                icon: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined, color: Colors.white, size: 22),
                label: const Text('Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}