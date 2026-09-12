import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import '../../confg/appconfig.dart';
import 'AddPicking.dart';

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
  Map<int, List<PickingDetail>> pickingDetails = {};

  @override
  void initState() {
    super.initState();
    fetchPickLists();
  }

  Future<void> fetchPickLists() async {
    setState(() => isLoading = true);

    final url = Uri.parse('http://68.183.92.8:3699/api/picklists-pending?store_id=${AppState().storeId}');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print(response.request);
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            pickLists = (data['data'] as List)
                .map((e) => PickList.fromJson(e))
                .toList();
          });
        }
      } else {
        debugPrint('Failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchPickingDetail(int picklistId) async {
    final url = Uri.parse(
        'http://68.183.92.8:3699/api/get-picklist-picking-detail?store_id=${AppState().storeId}&picklist_id=$picklistId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['data'] != null) {
          setState(() {
            pickingDetails[picklistId] = (data['data'] as List)
                .map((e) => PickingDetail.fromJson(e))
                .toList();
          });
        }
      } else {
        debugPrint('Failed to fetch picking details');
      }
    } catch (e) {
      debugPrint('Error fetching picking details: $e');
    }
  }

  List<int> getPicklistDetailIds(int picklistId) {
    if (pickingDetails.containsKey(picklistId)) {
      return pickingDetails[picklistId]!
          .map((detail) => detail.picklistId)
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Picking',
           style: AppConfig.pageTitleStyle,
        ),
        backgroundColor: AppConfig.colorPrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pickLists.isEmpty
          ? const Center(child: Text('No pending picklists found.'))
          : Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView.builder(
          itemCount: pickLists.length,
          itemBuilder: (context, index) {
            final pick = pickLists[index];
            final totalQty = pick.picklistDetail.fold<int>(
                0, (sum, item) => sum + item.quantity);

            final isExpanded = expandedId == pick.id;

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
                      Text('Qty : $totalQty | Picked Qty : 0'),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("${item.product!.name}",style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                          Text(
                                            '${item.unit!.name} | ${item.qty} | ${item.batch} | ${item.expiry} ',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          Divider(),
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
                                    final detailIds = getPicklistDetailIds(pick.id);
                                    if (detailIds.isEmpty) {
                                      fetchPickingDetail(pick.id).then((_) {
                                        final updatedDetailIds = getPicklistDetailIds(pick.id);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PickingAddPage(
                                              picklistId: pick.id,
                                              picklistDetailIds: updatedDetailIds,
                                            ),
                                          ),
                                        );
                                      });
                                    } else {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PickingAddPage(
                                            picklistId: pick.id,
                                            picklistDetailIds: detailIds,
                                          ),
                                        ),
                                      );

// ✅ If PickingAddPage returns true (successful post)
                                      if (result == true) {
                                        await fetchPickingDetail(pick.id); // refresh only that picklist’s data
                                        setState(() {}); // redraw UI but keep expandedId, scroll, etc.
                                      }
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
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConfig.colorPrimary,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: const Text('Complete',
                                      style: TextStyle(color: Colors.white)),
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
      id: json['id'] ?? 0,
      invoiceNo: json['invoice_no'] ?? '',
      saReference: json['sa_reference'] ?? '',
      customer_name: json['customer_name'] ?? '',
      van: (json['van'] as List?)?.map((e) => Van.fromJson(e)).toList() ?? [],
      user: (json['user'] as List?)?.map((e) => User.fromJson(e)).toList() ?? [],
      picklistDetail: (json['picklistdetail'] as List?)
          ?.map((e) => PickListDetail.fromJson(e))
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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class PickListDetail {
  final int id;
  final int quantity;

  PickListDetail({
    required this.id,
    required this.quantity,
  });

  factory PickListDetail.fromJson(Map<String, dynamic> json) {
    return PickListDetail(
      id: json['id'] ?? 0,
      quantity: json['quantity'] ?? 0,
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
  final Unit unit; // Changed from String to Unit
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
    required this.unit, // Changed from String to Unit
    required this.qty,
    required this.expiry,
    required this.batch,
    required this.userId,
    required this.storeId,
    this.product,
  });

  factory PickingDetail.fromJson(Map<String, dynamic> json) {
    return PickingDetail(
      id: json['id'] ?? 0,
      picklistId: json['picklist_id'] ?? 0,
      picklistDetailId: json['picklist_detail_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      unitId: json['unit_id'] ?? 0,
      qty: json['qty']?.toString() ?? '0',
      unit: Unit.fromJson(json['unit'] ?? {}), // Parse unit object
      expiry: json['expiry'] ?? '',
      batch: json['batch'] ?? '',
      userId: json['user_id'] ?? 0,
      storeId: json['store_id'] ?? 0,
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : null,
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
