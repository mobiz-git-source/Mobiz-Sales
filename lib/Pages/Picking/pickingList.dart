import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import '../../confg/appconfig.dart';
import 'AddPicking.dart';

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return double.tryParse(v.toString())?.toInt() ?? 0;
}

String _toStr(dynamic v) => v?.toString() ?? '';

List<PickList> _parsePickLists(String body) {
  final data = json.decode(body);
  final out = <PickList>[];
  if (data['status'] == true && data['data'] != null) {
    for (final e in data['data'] as List) {
      try {
        out.add(PickList.fromJson(e));
      } catch (err) {
        debugPrint('PARSE ERROR id=${e['id']}: $err');
      }
    }
  }
  return out;
}

class PickingListPage extends StatefulWidget {
  static const routeName = "/PickingListPage";
  const PickingListPage({super.key});

  @override
  State<PickingListPage> createState() => _PickingListPageState();
}

class _PickingListPageState extends State<PickingListPage> {
  bool isLoading = false;
  List<PickList> pickLists = [];
  int? expandedId;
  String? loadError;
  Map<int, List<PickingDetail>> pickingDetails = {};
  final Set<int> completingIds = {};
  final Set<int> deletingIds = {};

   // SEARCH
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  bool isSearching = false;

  List<PickList> get _filteredPickLists {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return pickLists;
    return pickLists.where((p) {
      final userName = p.user.isNotEmpty ? p.user.first.name : '';

      return p.invoiceNo.toLowerCase().contains(q) ||
      p.picklistDetail
    .fold<int>(0, (s, i) => s + i.quantity)
   .toString().contains(q) ||
          p.customer_name.toLowerCase().contains(q) ||
          userName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    fetchPickLists();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

   Future<void> fetchPickLists({bool silent = false}) async {
    if (!mounted) return;
    setState(() {
      if (!silent) isLoading = true;
      loadError = null;
    });

    final storeId = AppState().storeId;
    final url = Uri.parse(
        'http://68.183.92.8:3699/api/picklists-pending?store_id=$storeId');
    debugPrint('REQUEST URL: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 90));
      debugPrint('STATUS: ${response.statusCode}, '
      
          'SIZE: ${(response.bodyBytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(2)} MB');

      if (response.statusCode == 200) {
        final list = await compute(_parsePickLists, response.body);
        debugPrint('PARSED COUNT: ${list.length}');
        if (mounted) setState(() => pickLists = list);
      } else {
        debugPrint('Failed: ${response.statusCode}');
        if (mounted) {
          setState(() => loadError = 'Server error (${response.statusCode})');
        }
      }
    } catch (e, st) {
      debugPrint('Error fetching data: $e\n$st');
      if (mounted) {
        setState(() => loadError = 'Network error. Please check connection.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
 Future<void> fetchPickingDetail(int picklistId) async {
  final url = Uri.parse(
      'http://68.183.92.8:3699/api/get-picklist-picking-detail?store_id=${AppState().storeId}&picklist_id=$picklistId');
  debugPrint('>>> DETAIL REQUEST: $url');

  try {
    final response = await http.get(url).timeout(const Duration(seconds: 30));
    debugPrint('>>> DETAIL STATUS: ${response.statusCode} id=$picklistId');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == true && data['data'] != null) {
        if (!mounted) return;
        setState(() {
          pickingDetails[picklistId] = (data['data'] as List)
              .map((e) => PickingDetail.fromJson(e))
              .toList();
        });
      } else {
        debugPrint('>>> DETAIL status false: ${response.body}');
        if (mounted) setState(() => pickingDetails[picklistId] = []);
      }
    } else {
      debugPrint('>>> DETAIL FAILED ${response.statusCode}');
      if (mounted) setState(() => pickingDetails[picklistId] = []);
    }
  } catch (e) {
    debugPrint('>>> DETAIL ERROR: $e');
    if (mounted) setState(() => pickingDetails[picklistId] = []);
  }
}
  // Change this only when the backend confirms the correct endpoint
static const String _completePicklistPath = '/api/complete-picklist';

Future<String?> completePicklist(int picklistId) async {
  // null = success, else error message
  final url = Uri.parse('http://68.183.92.8:3699$_completePicklistPath');
  try {
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'store_id': AppState().storeId,
            'picklist_id': picklistId,
          }),
        )
        .timeout(const Duration(seconds: 30));

    debugPrint('>>> COMPLETE ${response.statusCode}: ${response.body}');

    // Endpoint missing on the server
    if (response.statusCode == 404) {
      return 'Complete service is not available on the server yet. '
          'Please contact support.';
    }

    dynamic data;
    try {
      data = json.decode(response.body);
    } catch (_) {}

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data is Map &&
        data['status'] == true) {
      return null;
    }
    if (data is Map && data['message'] != null) {
      return '(${response.statusCode}) ${data['message']}';
    }
     return 'HTTP ${response.statusCode}: ${response.body}';
  } catch (e) {
    return 'Error: $e';
  }
}

// ---------- DELETE PICKED ITEM ----------
static const String _deletePickingPath = '/api/picklist-picking-detail/delete';

Future<String?> deletePickingDetail(int pickingDetailId, int picklistId) async {
  // null = success, else error message
  final url = Uri.parse('http://68.183.92.8:3699$_deletePickingPath');
  try {
    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'id': pickingDetailId,
            'picklist_id': picklistId,
            'store_id': AppState().storeId,
          }),
        )
        .timeout(const Duration(seconds: 30));

    debugPrint('>>> DELETE ${response.statusCode}: ${response.body}');

    dynamic data;
    try {
      data = json.decode(response.body);
    } catch (_) {}

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data is Map &&
        data['status'] == true) {
      return null;
    }
    if (data is Map && data['message'] != null) {
      return '(${response.statusCode}) ${data['message']}';
    }
    return 'HTTP ${response.statusCode}: ${response.body}';
  } catch (e) {
    return 'Error: $e';
  }
}

Future<void> _confirmAndDelete(PickingDetail item, int picklistId) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete item?'),
      content: Text(
          'Do you want to delete ${item.product?.name ?? 'this item'} (${item.qty})?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ),
  );
  if (confirm != true) return;

  setState(() => deletingIds.add(item.id));
  final err = await deletePickingDetail(item.id, picklistId);
  if (!mounted) return;
  setState(() => deletingIds.remove(item.id));

  final ok = err == null;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(ok ? 'Item deleted' : 'Failed: $err'),
    backgroundColor: ok ? Colors.green : Colors.redAccent,
    duration: Duration(seconds: ok ? 2 : 6),
  ));

  if (ok) await fetchPickingDetail(picklistId); // refresh -> Picked Qty update aakum
}
  // List<int> getPicklistDetailIds(int picklistId) {
  //   if (pickingDetails.containsKey(picklistId)) {
  //     return pickingDetails[picklistId]!
  //         .map((detail) => detail.picklistId)
  //         .toList();
  //   }
  //   return [];
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
  title: isSearching
      ? TextField(
          controller: searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => searchQuery = v),
        )
      : const Text(
          'Picking',
          style: AppConfig.pageTitleStyle,
        ),
  backgroundColor: AppConfig.colorPrimary,
  iconTheme: const IconThemeData(color: Colors.white),
  actions: [
    IconButton(
      icon: Icon(
        isSearching ? Icons.close : Icons.search,
        color: Colors.white,
      ),
      onPressed: () {
        setState(() {
          if (isSearching) {
            searchController.clear();
            searchQuery = '';
          }
          isSearching = !isSearching;
        });
      },
    ),
  ],
),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
               : pickLists.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loadError ?? 'No pending picklists found.'),
                  if (loadError != null)
                    TextButton(
                      onPressed: fetchPickLists,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            )
                  : Padding(
        padding: const EdgeInsets.all(10.0),
           child: Column(
          children: [
            Expanded(
              child: _filteredPickLists.isEmpty
                  ? const Center(child: Text('No matching picklists found.'))
                  : ListView.builder(
          itemCount: _filteredPickLists.length,
          itemBuilder: (context, index) {
            final pick = _filteredPickLists[index];
            final totalQty = pick.picklistDetail.fold<int>(
                0, (sum, item) => sum + item.quantity);

            final isExpanded = expandedId == pick.id;
            final pickedQty = (pickingDetails[pick.id] ?? []).fold<double>(
                0, (sum, d) => sum + (double.tryParse(d.qty) ?? 0));
            final pickedText = pickedQty == pickedQty.roundToDouble()
                ? pickedQty.toInt().toString()
                : pickedQty.toString();
            return GestureDetector(
              onTap: () async {
                setState(() {
                  if (expandedId == pick.id) {
                    expandedId = null; // collapse
                  } else {
                    expandedId = pick.id; // expand new
                  }
                });

                if (!pickingDetails.containsKey(pick.id)) {
                  await fetchPickingDetail(pick.id);
                }
              },
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${pick.invoiceNo} | ${pick.customer_name} | ${pick.user.isNotEmpty ? pick.user.first.name : 'N/A'}'),
                      const SizedBox(height: 5),
            Text('Qty : $totalQty | Picked Qty : $pickedText'),
                      if (isExpanded)
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: pickingDetails[pick.id] == null
                                  ? const Center(
                                child:
                                CircularProgressIndicator(),
                              )
                                  : pickingDetails[pick.id]!.isEmpty
                                  ? const Text('No picking details found.')
                                  : Container(
                                // decoration: BoxDecoration(
                                //   border: Border.all(color: Colors.grey),
                                //   borderRadius: BorderRadius.circular(4),
                                // ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: pickingDetails[pick.id]!.length,
                               itemBuilder: (context, i) {
  final item = pickingDetails[pick.id]![i];
  return Padding(
    padding: const EdgeInsets.all(6.0),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product?.name ?? 'Unknown product',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${item.unit.name} | ${item.qty} | ${item.batch} | ${item.expiry}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            deletingIds.contains(item.id)
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () => _confirmAndDelete(item, pick.id),
                  ),
          ],
        ),
        const Divider(),
      ],
    ),
  );
},
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                                           ElevatedButton(
                                  onPressed: () async {
                                    final detailIds = pick.picklistDetail
                                        .map((d) => d.id)
                                        .toList();

                                    if (detailIds.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              "No picklist detail found for this pick"),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                      return;
                                    }

                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                    builder: (_) => PickingAddPage(
  picklistId: pick.id,
  picklistDetailIds: detailIds,
  picklistDetails: pick.picklistDetail.map((d) => d.raw).toList(),
),
                                      ),
                                    );

                                    // ✅ If PickingAddPage returns true (successful post)
                                    if (result == true) {
                                      await fetchPickingDetail(pick.id); // refresh only that picklist's data
                                      setState(() {}); // redraw UI but keep expandedId, scroll, etc.
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConfig.colorPrimary,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: const Text('Add',
                                      style: TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 10),
                           ElevatedButton(
  onPressed: completingIds.contains(pick.id)
      ? null
      : () async {
          debugPrint('>>> COMPLETE TAPPED: picklistId=${pick.id}, invoice=${pick.invoiceNo}');

          final details = pickingDetails[pick.id];
          if (details == null || details.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No picked items. Add items before completing.'),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }

          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Complete picking?'),
           content: Text('Do you want to complete picklist ${pick.invoiceNo}?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Yes')),
              ],
            ),
          );
          if (confirm != true) return;

          setState(() => completingIds.add(pick.id));
       final err = await completePicklist(pick.id);
final ok = err == null;
if (!mounted) return;
setState(() => completingIds.remove(pick.id));

ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  content: Text(ok ? 'Picklist completed' : 'Failed: $err'),
  backgroundColor: ok ? Colors.green : Colors.redAccent,
  duration: Duration(seconds: ok ? 2 : 6),
));

if (ok) {
            setState(() => expandedId = null);
            await fetchPickLists();
          }
        },
  style: ElevatedButton.styleFrom(
    backgroundColor: AppConfig.colorPrimary,
    padding: const EdgeInsets.symmetric(horizontal: 16),
  ),
  child: completingIds.contains(pick.id)
      ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
      : const Text('Complete', style: TextStyle(color: Colors.white)),
),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
                  );
          },
        ),
            ),
          ],
        ),
      ),
    );
  }
}

class PickList {
  final int id;
  final String invoiceNo;
  final String saReference;
  final String customer_name;
  final List<Van> van;
  final List<User> user;
  final List<PickListDetail> picklistDetail;

  PickList({
    required this.id,
    required this.invoiceNo,
    required this.saReference,
    required this.customer_name,
    required this.van,
    required this.user,
    required this.picklistDetail,
  });

  factory PickList.fromJson(Map<String, dynamic> json) {
    return PickList(
      id: _toInt(json['id']),
      invoiceNo: _toStr(json['invoice_no']),
      saReference: _toStr(json['sa_reference']),
      customer_name: _toStr(json['customer_name']),
      van: (json['van'] as List?)
              ?.map((e) => Van.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      user: (json['user'] as List?)
              ?.map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      picklistDetail: (json['picklistdetail'] as List?)
              ?.map((e) => PickListDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Van {
  final int id;
  final String name;

  Van({required this.id, required this.name});

  factory Van.fromJson(Map<String, dynamic> json) {
    return Van(
      id: _toInt(json['id']),
      name: _toStr(json['name']),
    );
  }
}

class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _toInt(json['id']),
      name: _toStr(json['name']),
    );
  }
}

class PickListDetail {
  final int id;
  final int quantity;
  final Map<String, dynamic> raw;
  PickListDetail({required this.id, required this.quantity, required this.raw});

    factory PickListDetail.fromJson(Map<String, dynamic> json) {
    return PickListDetail(
      id: _toInt(json['id']),
      quantity: _toInt(json['quantity']),
      raw: json,
    );
  }
}

class Unit {
  final int id;
  final String name;

  Unit({
    required this.id,
    required this.name,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class PickingDetail {
  final int id;
  final int picklistId;
  final int picklistDetailId;
  final int productId;
  final int unitId;
  final String qty;
  final Unit unit;
  final String expiry;
  final String batch;
  final int userId;
  final int storeId;
  final Product? product;

  PickingDetail({
    required this.id,
    required this.picklistId,
    required this.picklistDetailId,
    required this.productId,
    required this.unitId,
    required this.unit,
    required this.qty,
    required this.expiry,
    required this.batch,
    required this.userId,
    required this.storeId,
    this.product,
  });

  factory PickingDetail.fromJson(Map<String, dynamic> json) {
    return PickingDetail(
      id: _toInt(json['id']),
      picklistId: _toInt(json['picklist_id']),
      picklistDetailId: _toInt(json['picklist_detail_id']),
      productId: _toInt(json['product_id']),
      unitId: _toInt(json['unit_id']),
      qty: json['qty']?.toString() ?? '0',
      unit: Unit.fromJson(json['unit'] ?? {}),
      expiry: _toStr(json['expiry']),
      batch: _toStr(json['batch']),
      userId: _toInt(json['user_id']),
      storeId: _toInt(json['store_id']),
      product:
          json['product'] != null ? Product.fromJson(json['product']) : null,
    );
  }
}

class Product {
  final int id;
  final String name;
  final String? code;

  Product({
    required this.id,
    required this.name,
    this.code,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
    );
  }
}
