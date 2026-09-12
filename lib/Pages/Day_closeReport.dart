import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'package:shimmer/shimmer.dart';
import '../Components/commonwidgets.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'Day_expand.dart';

class DaycloseReport extends StatefulWidget {
  static const routeName = "/DaycloseReport";

  const DaycloseReport({Key? key}) : super(key: key);

  @override
  State<DaycloseReport> createState() => _DaycloseReportState();
}

class _DaycloseReportState extends State<DaycloseReport> {
  late Future<DayCloseResponse> futureDayCloseData1;
  final ScrollController _scrollController = ScrollController();

  List<DayClose> dayCloseList = [];
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    futureDayCloseData1 = fetchDayCloseData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent &&
          !isLoading &&
          currentPage <= totalPages) {
        fetchDayCloseData();
      }
    });
  }

  Future<DayCloseResponse> fetchDayCloseData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final String url =
          '${RestDatasource().BASE_URL}/api/get_dayclose.api?van_id=${AppState().vanId}&store_id=${AppState().storeId}&user_id=${AppState().userId}&page=$currentPage';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print(response.request);
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final dayCloseResponse = DayCloseResponse.fromJson(jsonData);

        setState(() {
          currentPage++;
          totalPages = dayCloseResponse.data.lastPage ?? 1;
          dayCloseList.addAll(dayCloseResponse.data.dayCloseList);
          isLoading = false;
        });

        return dayCloseResponse;
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
          'Day Close Report',
          style: AppConfig.pageTitleStyle,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<DayCloseResponse>(
              future: futureDayCloseData1,
              builder: (context, snapshot1) {
                if (snapshot1.connectionState == ConnectionState.waiting) {
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
                        ],
                      ),
                    ),
                  );
                } else if (snapshot1.hasError) {
                  return Center(
                      child: Text(
                          'Failed to load data from API. Please try again later.'));
                } else if (!snapshot1.hasData || snapshot1.data!.data.dayCloseList.isEmpty) {
                  return Center(child: Text('No data available'));
                } else {
                  return ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: dayCloseList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == dayCloseList.length) {
                        if (!isLoading) return SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      DayClose dayClose1 = dayCloseList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListTile(
                              trailing: Text(
                                '${dayClose1.approval == 1 ? 'Approved' : dayClose1.approval == 0 ? 'Waiting for\nApproval' : dayClose1.approval == 2 ? 'Cancelled' : ''}',
                                style: TextStyle(
                                  color: dayClose1.approval == 1
                                      ? Colors.green     // Approved -> Green
                                      : dayClose1.approval == 0
                                      ? Colors.orange  // Waiting for Approval -> Orange
                                      : dayClose1.approval == 2
                                      ? Colors.red    // Cancelled -> Red
                                      : Colors.black,  // Default color if no condition matches
                                ),
                              ),
                                title: Text('Invoice ID: ${dayClose1.invoiceNo}'),
                              subtitle: Text('Date: ${dayClose1.inDate}'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DayClosePagessss(
                                      id: dayClose1.id,
                                      invoiceNo: dayClose1.invoiceNo,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildLoadingIndicator() {
  //   if (!isLoading) return SizedBox.shrink();
  //
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 20),
  //     child: Center(
  //       child: CircularProgressIndicator(),
  //     ),
  //   );
  // }
}
class DayCloseResponse {
  final bool success;
  final String? message;
  final Data data;

  DayCloseResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory DayCloseResponse.fromJson(Map<String, dynamic> json) {
    return DayCloseResponse(
      success: json['success'] ?? false, // Handle null or missing 'success' field
      message: json['messages'] != null && json['messages'].isNotEmpty
          ? json['messages']?.first
          : null, // Null check for 'messages'
      data: Data.fromJson(json['data'] ?? {}), // Null check for 'data'
    );
  }
}

class Data {
  final int currentPage;
  final List<DayClose> dayCloseList;
  final String? firstPageUrl;
  final int? lastPage;
  final String? lastPageUrl;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final int? total;

  Data({
    required this.currentPage,
    required this.dayCloseList,
    this.firstPageUrl,
    this.lastPage,
    this.lastPageUrl,
    this.nextPageUrl,
    this.prevPageUrl,
    this.total,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      currentPage: json['current_page'] ?? 1, // Default to 1 if 'current_page' is null
      dayCloseList: json['data'] != null
          ? (json['data'] as List)
          .map((item) => DayClose.fromJson(item))
          .toList()
          : [], // Null check for 'data'
      firstPageUrl: json['first_page_url'],
      lastPage: json['last_page'],
      lastPageUrl: json['last_page_url'],
      nextPageUrl: json['next_page_url'],
      prevPageUrl: json['prev_page_url'],
      total: json['total'],
    );
  }
}

class DayClose {
  final int id;
  final String inDate;
  final String invoiceNo;
  final int approval;

  DayClose({
    required this.id,
    required this.inDate,
    required this.invoiceNo,
    required this.approval,
  });

  factory DayClose.fromJson(Map<String, dynamic> json) {
    return DayClose(
      id: json['id'] ?? 0, // Default to 0 if 'id' is null
      inDate: json['in_date'] ?? '', // Default to empty string if 'in_date' is null
      invoiceNo: json['invoice_no'] ?? '', // Default to empty string if 'invoice_no' is null
      approval: json['approvel'] ?? 0, // Default to 0 if 'approvel' is null
    );
  }
}
