import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

class OverdueCustomerPage extends StatefulWidget {
  static const routeName = "/OverdueCustomer";
  const OverdueCustomerPage({super.key});

  @override
  State<OverdueCustomerPage> createState() => _OverdueCustomerPageState();
}

class _OverdueCustomerPageState extends State<OverdueCustomerPage> {
  late Future<List<Salesman>> _salesmenFuture;
  Map<String, List<CustomerOverdue>> _expandedSalesmen = {};

  @override
  void initState() {
    super.initState();
    _salesmenFuture = fetchOverdueCustomers();
  }

  Future<List<Salesman>> fetchOverdueCustomers() async {
    try {
      final response = await http.get(
        Uri.parse("http://68.183.92.8:3699/api/users_customers_overdue?store_id=${AppState().storeId}"),
      );

      if (response.statusCode == 200) {
        print(response.request);
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          // Process API response to match our data structure
          return _parseApiResponse(data['data']);
        } else {
          throw Exception('Invalid response format or status false');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  List<Salesman> _parseApiResponse(dynamic apiData) {
    // Assuming apiData is a List of salesmen with their customers
    // You'll need to adjust this based on your actual API response structure
    List<Salesman> salesmen = [];

    // Group customers by salesman first
    Map<String, List<CustomerOverdue>> customersBySalesman = {};
    Map<String, Map<String, dynamic>> salesmanTotals = {};

    // First pass to organize data
    for (var item in apiData) {
      String salesmanName = item['user_name'] ?? 'Unknown';
      double balance = double.tryParse(item['balance_amount']?.toString() ?? '0') ?? 0;
      double overdue = double.tryParse(item['overdue_amount']?.toString() ?? '0') ?? 0;

      // Initialize salesman totals if not exists
      if (!salesmanTotals.containsKey(salesmanName)) {
        salesmanTotals[salesmanName] = {
          'balance': 0.0,
          'overdue': 0.0,
          'customers': [],
        };
      }

      // Update totals
      salesmanTotals[salesmanName]!['balance'] += balance;
      salesmanTotals[salesmanName]!['overdue'] += overdue;

      // Create customer
      var customer = CustomerOverdue(
        customerName: item['customer_name'] ?? 'Unknown Customer',
        type: item['payment_type'],
        creditDays: item['credit_days'] != null ? int.tryParse(item['credit_days'].toString()) : null,
        balance: balance,
        invoices: [
          Invoice(
            date: item['invoice_date'] ?? 'N/A',
            number: item['invoice_number'] ?? 'N/A',
            amount: double.tryParse(item['invoice_amount']?.toString() ?? '0') ?? 0,
            daysOverdue: item['days_overdue'] != null ? int.tryParse(item['days_overdue'].toString()) ?? 0 : 0,
          ),
        ],
      );

      // Add customer to salesman's list
      if (!customersBySalesman.containsKey(salesmanName)) {
        customersBySalesman[salesmanName] = [];
      }
      customersBySalesman[salesmanName]!.add(customer);
    }

    // Create Salesman objects
    salesmanTotals.forEach((name, totals) {
      salesmen.add(Salesman(
        name: name,
        balance: totals['balance'],
        overdue: totals['overdue'],
        customers: customersBySalesman[name] ?? [],
      ));
    });

    return salesmen;
  }

  void _toggleSalesmanExpansion(String salesmanName) {
    setState(() {
      if (_expandedSalesmen.containsKey(salesmanName)) {
        _expandedSalesmen.remove(salesmanName);
      } else {
        // This will show the customers we already have in the data
        _expandedSalesmen[salesmanName] = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Dues', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppConfig.colorPrimary, // Replace with AppConfig.colorPrimary
      ),
      body: FutureBuilder<List<Salesman>>(
        future: _salesmenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingShimmer();
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data found'));
          }

          final salesmen = snapshot.data!;
          double totalBalance = salesmen.fold(0, (sum, salesman) => sum + salesman.balance);
          double totalOverdue = salesmen.fold(0, (sum, salesman) => sum + salesman.overdue);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Summary Table
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Table(
                    border: TableBorder.all(color: Colors.grey),
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Colors.grey),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Salesman', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Over Due', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      ...salesmen.map((salesman) => TableRow(
                        children: [
                          InkWell(
                            // onTap: () => _toggleSalesmanExpansion(salesman.name),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                salesman.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(_formatCurrency(salesman.balance),textAlign: TextAlign.right,),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _formatCurrency(salesman.overdue),
          textAlign: TextAlign.right,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      )),
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[200]),
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _formatCurrency(totalBalance),textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _formatCurrency(totalOverdue),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Expanded customer details
                ..._buildCustomerDetails(salesmen),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCustomerDetails(List<Salesman> salesmen) {
    List<Widget> widgets = [];

    for (var salesman in salesmen) {
      if (_expandedSalesmen.containsKey(salesman.name)) {
        widgets.addAll([
          const Divider(thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              salesman.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ]);

        if (salesman.customers.isEmpty) {
          widgets.add(const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No customer details available'),
          ));
        } else {
          widgets.addAll(salesman.customers.map((customer) => _buildCustomerCard(customer)));
        }
      }
    }

    return widgets;
  }

  Widget _buildCustomerCard(CustomerOverdue customer) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  customer.customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (customer.type != null)
                  Text(
                    customer.type! + (customer.creditDays != null ? " | ${customer.creditDays} Days" : ""),
                    style: TextStyle(color: Colors.blue),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Balance ${_formatCurrency(customer.balance)}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            ...customer.invoices.map((invoice) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${invoice.date} | ${invoice.number}"),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Amount ${_formatCurrency(invoice.amount)}"),
                      Text("Days ${invoice.daysOverdue}", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Please wait while loading...",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return "${amount.toStringAsFixed(AppState().noOfDecimals ?? 2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    )}";
  }
}

class Salesman {
  final String name;
  final double balance;
  final double overdue;
  final List<CustomerOverdue> customers;

  Salesman({
    required this.name,
    required this.balance,
    required this.overdue,
    required this.customers,
  });
}

class CustomerOverdue {
  final String customerName;
  final String? type;
  final int? creditDays;
  final double balance;
  final List<Invoice> invoices;

  CustomerOverdue({
    required this.customerName,
    this.type,
    this.creditDays,
    required this.balance,
    required this.invoices,
  });
}

class Invoice {
  final String date;
  final String number;
  final double amount;
  final int daysOverdue;

  Invoice({
    required this.date,
    required this.number,
    required this.amount,
    required this.daysOverdue,
  });
}