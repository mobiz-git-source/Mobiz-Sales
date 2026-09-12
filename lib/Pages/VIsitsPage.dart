import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:shimmer/shimmer.dart';
import '../Components/commonwidgets.dart';
import '../Models/visit_model.dart';
import '../Utilities/rest_ds.dart';
import '../Utilities/date_helper.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';

class Visitspage extends StatefulWidget {
  static const routeName = "/Visitspage";

  @override
  _VisitspageState createState() => _VisitspageState();
}

class _VisitspageState extends State<Visitspage> {
  late Future<List<CustomerVisit>> futureCustomerVisits;

  @override
  void initState() {
    super.initState();
    futureCustomerVisits = fetchCustomerVisits(AppState().storeId!);
  }

  Future<List<CustomerVisit>> fetchCustomerVisits(int storeId) async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_customer_visit?store_id=$storeId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<CustomerVisit> visits = List<CustomerVisit>.from(
          data['data'].map((item) => CustomerVisit.fromJson(item)));
      return visits;
    } else {
      throw Exception('Failed to load customer visits');
    }
  }

  String formatTime(String time) {
    final DateTime dateTime = DateFormat("HH:mm:ss").parse(time);
    return DateFormat("hh:mm a").format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppConfig.colorPrimary,
        title: Text(
          'Visit',
          style: AppConfig.pageTitleStyle,
        ),
      ),
      body: FutureBuilder<List<CustomerVisit>>(
        future: futureCustomerVisits,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Shimmer.fromColors(
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
              ),
            );
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No customer visits found'));
          } else {
            List<CustomerVisit> visits = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: visits.length,
              itemBuilder: (context, index) {
                CustomerVisit visit = visits[index];
                Customer customer = visit.customer[0];
                Reason reason = visit.reason[0];
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Card(
                    elevation: 3,
                    child: Container(
                      width: double.infinity,
                      // height: MediaQuery.of(context).size.height*.15,
                      decoration: BoxDecoration(
                        color: AppConfig.backgroundColor,
                        // border: Border.all(color: Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(8),
                        // boxShadow: [
                        //   BoxShadow(
                        //     // color: Colors.grey.withOpacity(0.2),
                        //     // blurRadius: 4.0,
                        //     // spreadRadius: 1.0,
                        //     // offset: Offset(0, 2),
                        //   ),
                        // ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "${customer.code ?? 'No Code'} | ${customer.name} - ${customer.address}",
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    Text(
                                          "${DateHelper.displayDate(visit.inDate)}   ${formatTime(visit.inTime)}"),
                                      Text("Reason: ${reason.reason}"),
                                      Text("Remarks: ${visit.description}"),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      // BoxShadow(
                                      //   color: Colors.grey.shade300,
                                      //   spreadRadius: 3,
                                      // ),
                                    ],
                                    color: AppConfig.colorPrimary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15.0,
                                      vertical: 5.0,
                                    ),
                                    child: Text(
                                      reason.visitType == 'visit'
                                          ? 'Visit'
                                          : 'Non Visit',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
