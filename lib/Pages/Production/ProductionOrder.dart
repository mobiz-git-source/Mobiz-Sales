import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/Production/productionModel.dart';

import '../../confg/appconfig.dart';
import 'ProductionAdd.dart';

class Productionorder extends StatefulWidget {
  static const routeName = "/Productionorder";
  const Productionorder({super.key});

  @override
  State<Productionorder> createState() => _ProductionorderState();
}

class _ProductionorderState extends State<Productionorder> {
  List<ProductionOrder> orders = [];
  bool isLoading = true;
  List<bool> expandedStates = [];

  @override
  void initState() {
    super.initState();
    fetchProductionOrders();
  }

  Future<void> fetchProductionOrders() async {
    try {
      final url = Uri.parse(
          'http://68.183.92.8:3699/api/get-production-orders?store_id=${AppState().storeId}');
      final response = await http.get(url);
      print(response.statusCode);
      if (response.statusCode == 200) {
        print(response.request);
        final jsonData = jsonDecode(response.body);
        List<dynamic> data = jsonData['data'];

        setState(() {
          orders = data.map((e) => ProductionOrder.fromJson(e)).toList();
          expandedStates = List<bool>.filled(orders.length, false);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Production Order',
          style: AppConfig.pageTitleStyle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductionOrderForm()),
              ).then((value) {
                if (value == true) {
                  fetchProductionOrders();  // refresh after save
                }
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ExpansionTile(
              title: Text(
                "${order.invoiceNo} | ${order.inDate} | ${order.warehouse?.name ?? ''}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  "${order.product.name}\nQty: ${order.quantity} | Produced: ${order.producedQty}"),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: order.details.map((d) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.producName),
                          Text("Unit: ${d.unit} | Qty: ${d.bomQuantity}"),
                          Divider()
                        ],
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
