import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import 'warehouse_stock_take_add.dart'; // NEW
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'package:mobizapp/confg/appconfig.dart';

// ───────────────── Models ─────────────────
class WarehouseStockTake {
  final int id;
  final String invoiceNo;
  final String inDate;
  final String warehouseName;
  final String userName;
  final String status;
  final List<WarehouseStockTakeDetail> details;

  WarehouseStockTake({
    required this.id,
    required this.invoiceNo,
    required this.inDate,
    required this.warehouseName,
    required this.userName,
    required this.status,
    required this.details,
  });

  factory WarehouseStockTake.fromJson(Map<String, dynamic> j) {
    return WarehouseStockTake(
      id: j['id'] ?? 0,
      invoiceNo: (j['invoice_no'] ?? '').toString(),
      inDate: (j['in_date'] ?? '').toString(),
      warehouseName: (j['warehouse_name'] ?? '').toString(),
      userName: (j['user_name'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      details: ((j['details'] as List?) ?? [])
          .map((e) => WarehouseStockTakeDetail.fromJson(e))
          .toList(),
    );
  }
}

class WarehouseStockTakeDetail {
  final int id;
  final int itemId;
  final String productName;
  final String productCode;
  final int unitId;
  final String unitName;
  final String? batch;
  final String? expiry;
  final double quantity;

  WarehouseStockTakeDetail({
    required this.id,
    required this.itemId,
    required this.productName,
    required this.productCode,
    required this.unitId,
    required this.unitName,
    this.batch,
    this.expiry,
    required this.quantity,
  });

  factory WarehouseStockTakeDetail.fromJson(Map<String, dynamic> j) {
    final product = (j['product'] as Map?) ?? {};
    final unit = (j['unit'] as Map?) ?? {};
    return WarehouseStockTakeDetail(
      id: j['id'] ?? 0,
      itemId: j['item_id'] ?? 0,
      productName: (product['name'] ?? '').toString(),
      productCode: (product['code'] ?? '').toString(),
      unitId: unit['id'] ?? 0,
      unitName: (unit['name'] ?? '').toString(),
      batch: j['batch']?.toString(),
      expiry: j['expiry']?.toString(),
      quantity: double.tryParse('${j['quantity'] ?? 0}') ?? 0,
    );
  }
}
class WarehouseScan {
  final int id;
  final String productName;
  final String unitName;
  final String qty;
  final String batchNo;
  final String expiryDate;
  final String productionDate;

  WarehouseScan({
    required this.id,
    required this.productName,
    required this.unitName,
    required this.qty,
    required this.batchNo,
    required this.expiryDate,
    required this.productionDate,
  });

  factory WarehouseScan.fromJson(Map<String, dynamic> j) {
    final product = (j['product'] as Map?) ?? {};
    final unit = (j['unit'] as Map?) ?? {};
    return WarehouseScan(
      id: j['id'] ?? 0,
      productName: (product['name'] ?? '').toString(),
      unitName: (unit['name'] ?? '').toString(),
      qty: (j['qty'] ?? '0').toString(),
      batchNo: (j['batch_no'] ?? '').toString(),
      expiryDate: (j['expiry_date'] ?? '').toString(),
      productionDate: (j['production_date'] ?? '').toString(),
    );
  }
}
// ───────────────── Screen ─────────────────
class WarehouseStockTakeListPage extends StatefulWidget {
  static const routeName = "/WarehouseStockTakeListPage";
  const WarehouseStockTakeListPage({super.key});

  @override
  State<WarehouseStockTakeListPage> createState() =>
      _WarehouseStockTakeListPageState();
}

class _WarehouseStockTakeListPageState
    extends State<WarehouseStockTakeListPage> {
  bool _loading = true;
  String? _error;
  List<WarehouseStockTake> _list = [];

  int? _expandedId;
  final Map<int, List<WarehouseScan>> _scans = {};
  final Set<int> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
    
      final subUrl =
          "/api/warehouse-stock-takes/pending?store_id=${AppState().storeId}&user_id=${AppState().userId}";
           debugPrint('WST PENDING URL: ${RestDatasource().BASE_URL}$subUrl');
      final res = await RestDatasource().getDetails(subUrl, AppState().token);
      debugPrint('WST PENDING RESP: $res');

   if (res != null && res['status'] == true) {
        final data = (res['data'] as List?) ?? [];
        _list = data
            .map((e) => WarehouseStockTake.fromJson(e))
            .toList()
            .reversed
            .toList();
      }else {
        _error = (res?['message'] ?? 'Failed to load').toString();
      }
    } catch (e) {
      _error = 'Error: $e';
    }
    if (mounted) setState(() => _loading = false);
  }
 
  static const String _completePath = '/api/warehouse-stock-takes/complete';
  final Set<int> _completingIds = {};

  Future<String?> _complete(int id) async {
    final url = Uri.parse('${RestDatasource().BASE_URL}$_completePath');
    try {
      final r = await http
          .post(url,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
                          body: jsonEncode({
                'stock_take_id': id,
              }))
          .timeout(const Duration(seconds: 30));
      if (r.statusCode == 404) return 'Complete service is not available yet.';
      dynamic d;
      try { d = jsonDecode(r.body); } catch (_) {}
      if ((r.statusCode == 200 || r.statusCode == 201) &&
          d is Map && d['status'] == true) return null;
      if (d is Map && d['message'] != null) return d['message'].toString();
      return 'HTTP ${r.statusCode}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<void> _onComplete(WarehouseStockTake st) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete stock take?'),
        content: Text('Do you want to complete ${st.invoiceNo}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    if (yes != true) return;

    setState(() => _completingIds.add(st.id));
    final err = await _complete(st.id);
    if (!mounted) return;
    setState(() => _completingIds.remove(st.id));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err == null ? 'Stock take completed' : 'Failed: $err'),
      backgroundColor: err == null ? Colors.green : Colors.redAccent,
    ));
    if (err == null) _fetchPending();
  }
  Future<void> _fetchScans(int stockTakeId) async {
    try {
      final res = await RestDatasource().getDetails(
          "/api/warehouse-stock-takes/scans?stock_take_id=$stockTakeId",
          AppState().token);
      debugPrint('WST SCANS RESP: $res');
      final list = (res != null && res['status'] == true)
          ? ((res['data'] as List?) ?? [])
              .whereType<Map>()
              .map((e) => WarehouseScan.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <WarehouseScan>[];
      if (mounted) setState(() => _scans[stockTakeId] = list);
    } catch (e) {
      debugPrint('WST SCANS ERROR: $e');
      if (mounted) setState(() => _scans[stockTakeId] = []);
    }
  }

  static const String _deleteScanPath = '/api/warehouse-stock-takes/scans/delete';

  Future<String?> _deleteScan(int scanId) async {
    final url = Uri.parse('${RestDatasource().BASE_URL}$_deleteScanPath');
    try {
      final r = await http
          .post(url,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({'id': scanId}))
          .timeout(const Duration(seconds: 30));
      debugPrint('WST DELETE ${r.statusCode}: ${r.body}');
      dynamic d;
      try { d = jsonDecode(r.body); } catch (_) {}
      if ((r.statusCode == 200 || r.statusCode == 201) &&
          d is Map && d['status'] == true) return null;
      if (d is Map && d['message'] != null) return d['message'].toString();
      return 'HTTP ${r.statusCode}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<void> _confirmDelete(WarehouseScan s, int stockTakeId) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Do you want to delete ${s.productName} (${s.qty})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (yes != true) return;

    setState(() => _deletingIds.add(s.id));
    final err = await _deleteScan(s.id);
    if (!mounted) return;
    setState(() => _deletingIds.remove(s.id));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err == null ? 'Item deleted' : 'Failed: $err'),
      backgroundColor: err == null ? Colors.green : Colors.redAccent,
    ));
    if (err == null) await _fetchScans(stockTakeId);
  }
  Future<void> _openAdd(WarehouseStockTake st) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WarehouseStockTakeAddPage(stockTake: st)),
    );
        if (res == true) {
      await _fetchScans(st.id);
      if (mounted) setState(() => _expandedId = st.id);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
        title: Text(
          'Warehouse Stock Take',
          style: AppConfig.pageTitleStyle.copyWith(color: Colors.white), 
        ),
        backgroundColor: AppConfig.colorPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _list.isEmpty
                  ? const Center(child: Text('No pending stock takes'))
                  : RefreshIndicator(
                      onRefresh: _fetchPending,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _list.length,
                        itemBuilder: (_, i) => _card(_list[i]),
                      ),
                    ),
    );
  }

   Widget _card(WarehouseStockTake st) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          setState(() => _expandedId = _expandedId == st.id ? null : st.id);
          if (_expandedId == st.id && !_scans.containsKey(st.id)) {
            await _fetchScans(st.id);
          }
        },
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(st.invoiceNo,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(st.status,
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${st.warehouseName}  •  ${st.inDate}'),
            if (_expandedId == st.id) ...[
              const Divider(height: 20),
              if (_scans[st.id] == null)
                const Center(child: CircularProgressIndicator())
              else if (_scans[st.id]!.isEmpty)
                const Text('No scanned items yet.')
              else
                ..._scans[st.id]!.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('${s.unitName} | ${s.qty} | ${s.batchNo} | ${s.expiryDate}',
                                    style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          _deletingIds.contains(s.id)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _confirmDelete(s, st.id),
                                ),
                        ],
                      ),
                    )),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _openAdd(st),
                  style: ElevatedButton.styleFrom(backgroundColor: AppConfig.colorPrimary),
                  child: const Text('Add', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _completingIds.contains(st.id) ? null : () => _onComplete(st),
                  style: ElevatedButton.styleFrom(backgroundColor: AppConfig.colorPrimary),
                  child: _completingIds.contains(st.id)
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Complete', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
                 ],
        ),
      ),
      ),
    );
  }
}