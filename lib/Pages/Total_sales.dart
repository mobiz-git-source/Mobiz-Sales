import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import '../Components/commonwidgets.dart';
import '../Models/Total_salesModel.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'Custom_pieChart.dart';
import 'CustomeSOA.dart';

class TotalSales extends StatefulWidget {
  static const routeName = "/TotalSales";

  const TotalSales({super.key});

  @override
  State<TotalSales> createState() => _TotalSalesState();
}

class _TotalSalesState extends State<TotalSales> {
  late Future<SalesReport> futureSalesReport;

  Future<SalesReport> fetchSalesReport() async {
    final response = await http.get(
      Uri.parse(
          '${RestDatasource().BASE_URL}/api/get_customer_sales_report?customer_id=$id'),
    );

    if (response.statusCode == 200) {
      return SalesReport.fromJson(jsonDecode(response.body)['data']);
    } else {
      throw Exception('Failed to load sales report');
    }
  }

  @override
  void initState() {
    super.initState();
    futureSalesReport = fetchSalesReport();
  }

  @override
  Widget build(BuildContext context) {
    if (ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      id = params!['id'];
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimary,
        title: const Text(
          'Total Sale',
          style: AppConfig.pageTitleStyle,
        ),
        iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
      ),
      body: FutureBuilder<SalesReport>(
        future: futureSalesReport,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Shimmer.fromColors(
              baseColor: AppConfig.buttonDeactiveColor.withOpacity(0.1),
              highlightColor: AppConfig.backButtonColor,
              child: Center(
                child: Column(
                  children: [
                    CommonWidgets.loadingContainers(
                        height: SizeConfig.blockSizeVertical * 10,
                        width: SizeConfig.blockSizeHorizontal * 90),
                    CommonWidgets.loadingContainers(
                        height: SizeConfig.blockSizeVertical * 10,
                        width: SizeConfig.blockSizeHorizontal * 90),
                    CommonWidgets.loadingContainers(
                        height: SizeConfig.blockSizeVertical * 10,
                        width: SizeConfig.blockSizeHorizontal * 90),
                    CommonWidgets.loadingContainers(
                        height: SizeConfig.blockSizeVertical * 10,
                        width: SizeConfig.blockSizeHorizontal * 90),
                    CommonWidgets.loadingContainers(
                        height: SizeConfig.blockSizeVertical * 10,
                        width: SizeConfig.blockSizeHorizontal * 90),
                    CommonWidgets.loadingContainers(
                        height: SizeConfig.blockSizeVertical * 10,
                        width: SizeConfig.blockSizeHorizontal * 90),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          } else if (snapshot.hasData) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 35.0, horizontal: 6),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              CustomPaint(
                                size: Size(200, 200),
                                painter: PieChartPainter(
                                  values: [
                                    snapshot.data!.todaySale.toDouble(),
                                    snapshot.data!.weekSale.toDouble(),
                                    snapshot.data!.monthSale.toDouble(),
                                    snapshot.data!.beforeThisMonthSale
                                        .toDouble(),
                                  ],
                                  colors: [
                                    Colors.lightBlueAccent,
                                    Colors.blueGrey,
                                    Colors.grey,
                                    Colors.blue.shade900,
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color: Colors.lightBlueAccent,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        width: 30,
                                        height: 10,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text('Today',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.lightBlueAccent,
                                          )),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color: Colors.blueGrey,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        width: 30,
                                        height: 10,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text('This Week',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey,
                                          )),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color: Colors.grey,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        width: 30,
                                        height: 10,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text('This Month',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          )),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color: Colors.blue.shade900,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        width: 30,
                                        height: 10,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        'Before',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade900),
                                      ),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.45,
                      height: MediaQuery.of(context).size.height * 0.12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.lightBlueAccent,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Today's Sale",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConfig.backgroundColor),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "${snapshot.data!.todaySale.toDouble()} AED",
                            style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.backgroundColor),
                          )
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.45,
                      height: MediaQuery.of(context).size.height * 0.12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.blueGrey,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "This Week Sales",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConfig.backgroundColor),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "${snapshot.data!.weekSale.toDouble()} AED",
                            style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.backgroundColor),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.45,
                      height: MediaQuery.of(context).size.height * 0.12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "This Month Sales",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConfig.backgroundColor),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "${snapshot.data!.monthSale.toDouble()} AED",
                            style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.backgroundColor),
                          )
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.45,
                      height: MediaQuery.of(context).size.height * 0.12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.blue.shade900,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Before The Month",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConfig.backgroundColor),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "${snapshot.data!.beforeThisMonthSale.toDouble()} AED",
                            style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.backgroundColor),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Total Sales",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppConfig.backgroundColor),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            "${snapshot.data!.totalSale.toDouble()} AED",
                            style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.backgroundColor),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            );
          } else {
            return Text('No data available');
          }
        },
      ),
    );
  }
}
