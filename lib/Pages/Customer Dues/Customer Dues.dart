import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart'as http;
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'package:shimmer/shimmer.dart';
class CustomerDues extends StatelessWidget {
  static const routeName = "/UserOverduePage";

  const CustomerDues({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Future<UserOverdue> fetchUserOverdue() async {
      final url = Uri.parse(
          "http://68.183.92.8:3699/api/user_customers_overdue?store_id=${AppState().storeId}&user_id=${AppState().userId}");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        print(response.request);
        final data = json.decode(response.body);
        return UserOverdue.fromJson(data);
      } else {
        throw Exception('Failed to load user overdue amount');
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text('Overdue Amount',style: TextStyle(color: Colors.white),),iconTheme: IconThemeData(color: Colors.white),backgroundColor: AppConfig.colorPrimary,),
      body: FutureBuilder<UserOverdue>(
        future: fetchUserOverdue(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
          else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data found'));
          }
          final userOverdue = snapshot.data!;
          return Center(
            child: Text(
              "Total Overdue Amount: ₹${userOverdue.totalOverdueAmount.toStringAsFixed(AppState().noOfDecimals ?? 2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
class UserOverdue {
  final bool status;
  final double totalOverdueAmount;

  UserOverdue({
    required this.status,
    required this.totalOverdueAmount,
  });

  factory UserOverdue.fromJson(Map<String, dynamic> json) {
    return UserOverdue(
      status: json['status'],
      totalOverdueAmount: (json['total_overdue_amount'] as num).toDouble(),
    );
  }
}
