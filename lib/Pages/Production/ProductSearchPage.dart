import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../Models/appstate.dart';
import '../../confg/appconfig.dart';

class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({super.key});

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  List products = [];
  List filteredProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final url = Uri.parse(
        "http://68.183.92.8:3699/api/get-productionorder-products?store_id=${AppState().storeId}");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          products = data["products"];
          filteredProducts = products;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  void filterSearch(String query) {
    setState(() {
      filteredProducts = products.where((p) {
        final name = (p["product_name"] ?? "").toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: AppConfig.colorPrimary,
        title: const Text("Select Product", style: AppConfig.pageTitleStyle,),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterSearch,
              decoration: const InputDecoration(
                labelText: "Search Product",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Product List
          Expanded(
            child: ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final p = filteredProducts[index];

                final String name = p["product_name"] ?? "";
                final String unitName = p["base_unit_name"] ?? "";
                final int unitId = p["base_unit_id"] ?? 0;
                final String code =
                p["product_id"] != null ? p["product_id"].toString() : "";

                return Card(
                  color: Colors.white,
                  elevation: 3,
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text("Unit: $unitName"),
                    // trailing: Text(code),
                    onTap: () {
                      Navigator.pop(context, {
                        "id": p["product_id"],
                        "name": name,
                        "unit": unitName,
                        "unit_id": unitId,
                        "boms": p["boms"], // if needed later
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
