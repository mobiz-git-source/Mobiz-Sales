import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../Utilities/rest_ds.dart';
import '../../confg/appconfig.dart';
import '../../Models/appstate.dart';
import '../../Utilities/date_helper.dart';
import 'ProductSearchPage.dart';

class ProductionOrderForm extends StatefulWidget {
  const ProductionOrderForm({super.key});

  @override
  State<ProductionOrderForm> createState() => _ProductionOrderFormState();
}

class _ProductionOrderFormState extends State<ProductionOrderForm> {
  final TextEditingController dateController = TextEditingController();
  DateTime selectedProductionDate = DateTime.now();
  final TextEditingController productController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController qtyController = TextEditingController(text: "1");

  List<Map<String, dynamic>> locations = [];
  String? selectedLocationName;
  int? selectedProductId;
  int? selectedUnitId;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _setCurrentFormattedDate();
    fetchLocations();
  }

void _setCurrentFormattedDate() {
    final now = DateTime.now();
    selectedProductionDate = now;
    dateController.text = DateHelper.displayFromDateTime(now);
  }

  Future<void> fetchLocations() async {
    setState(() => isLoading = true);

    try {
      final url = Uri.parse("${RestDatasource().BASE_URL}/api/get/production-locations/${AppState().storeId}");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        print(response.request);
        final data = jsonDecode(response.body);

        final list = List<Map<String, dynamic>>.from(data['data']);

        setState(() {
          locations = list;

          if (locations.isNotEmpty) {
            selectedLocationName = locations.first['name'];
          }
        });
      }
    } catch (e) {
      print("Error: $e");
    }

    setState(() => isLoading = false);
  }


  int? getSelectedLocationId() {
    final loc = locations.firstWhere(
          (e) => e['name'] == selectedLocationName,
      orElse: () => {},
    );

    return loc.isNotEmpty ? loc['id'] : null;
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

 if (picked != null) {
      setState(() {
        selectedProductionDate = picked;
        dateController.text = DateHelper.displayFromDateTime(picked);
      });
    }
  }

  Future<void> postProductionOrder() async {
    if (selectedProductId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Select a product")));
      return;
    }

    final locationId = getSelectedLocationId();
    if (locationId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Select a location")));
      return;
    }

    final qty = double.tryParse(qtyController.text) ?? 0;

    final url = Uri.parse("${RestDatasource().BASE_URL}/api/production-orders");
    final nowTime = DateFormat('HH:mm:ss').format(DateTime.now());

  final body = {
      "store_id" : AppState().storeId,
      "product_id": selectedProductId,
      "unit": selectedUnitId,
      "user_id": AppState().userId,
      "quandity": qty,
      "quantity": qty,
      "in_date": DateHelper.apiDate(selectedProductionDate),
      "in_time": nowTime,
      "production_store": locationId
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
print(body);
print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Production Order Saved")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Failed: ${response.body.toString()}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> openProductSearch() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        List products = [];
        List filtered = [];
        bool loading = true;

        // Fetch products when sheet opens
        fetch() async {
          final url = Uri.parse(
              "http://68.183.92.8:3699/api/get-productionorder-products?store_id=${AppState().storeId}");

          final res = await http.get(url);

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            products = data["products"];
            filtered = products;
          }

          loading = false;
        }

        return StatefulBuilder(
          builder: (context, setStateSB) {
            // Load once
            if (loading) {
              fetch().then((_) => setStateSB(() {}));
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Search Product",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Search box
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Type to search...",
                    ),
                    onChanged: (query) {
                      setStateSB(() {
                        filtered = products.where((p) {
                          final name =
                          (p["product_name"] ?? "").toString().toLowerCase();
                          return name.contains(query.toLowerCase());
                        }).toList();
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  loading
                      ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  )
                      : Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final p = filtered[i];

                        return ListTile(
                          title: Text(p["product_name"]),
                          subtitle:
                          Text("Unit: ${p["base_unit_name"] ?? ""}"),
                          onTap: () {
                            Navigator.pop(context, {
                              "id": p["product_id"],
                              "name": p["product_name"],
                              "unit": p["base_unit_name"],
                              "unit_id": p["base_unit_id"],
                            });
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          selectedProductId = result["id"];
          selectedUnitId = result["unit_id"];
          productController.text = result["name"];
          unitController.text = result["unit"];
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimary,
        title: const Text("New Production Order",
            style: AppConfig.pageTitleStyle,),
        iconTheme: const IconThemeData(color: Colors.white),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.search, color: Colors.white),
        //     onPressed: () async {
        //       final result = await Navigator.push(
        //           context,
        //           MaterialPageRoute(
        //               builder: (_) => const ProductSearchPage()));
        //
        //       if (result != null) {
        //         setState(() {
        //           selectedProductId = result["id"];
        //           selectedUnitId = result["unit_id"];
        //           productController.text = result["name"];
        //           unitController.text = result["unit"];
        //         });
        //       }
        //     },
        //   )
        // ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: dateController,
              readOnly: true,
              onTap: pickDate,
              decoration: const InputDecoration(
                labelText: "Date",
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: selectedLocationName,
              items: locations.map((loc) {
                return DropdownMenuItem<String>(
                  value: loc['name'],
                  child: Text(loc['name']),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => selectedLocationName = val);
              },
              decoration: const InputDecoration(labelText: "Location"),
            ),

            const SizedBox(height: 10),
            TextField(
              controller: productController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Product",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductSearchPage()),
                    );
                    if (result != null) {
                      setState(() {
                        selectedProductId = result["id"];
                        selectedUnitId = result["unit_id"];
                        productController.text = result["name"];
                        unitController.text = result["unit"];
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: unitController,
              readOnly: true,
              decoration: const InputDecoration(labelText: "Unit"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Qty"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.colorPrimary),
              onPressed: postProductionOrder,
              child: const Text("Save",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
