import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobizapp/Pages/homepage.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;

import '../../Components/commonwidgets.dart';
import '../../Models/appstate.dart';
import '../../Models/requestmodelclass.dart';
import '../../Models/stockData.dart';
import '../../Utilities/rest_ds.dart';
import '../../Utilities/date_helper.dart';
import '../../confg/appconfig.dart';
import '../../confg/sizeconfig.dart';
import '../../vanstocktst.dart';
import 'Model/Stock_Model.dart';
import 'Stock_Name.dart';

class StockName_RequestScreen extends StatefulWidget {
  static const routeName = "/StockRequest";
  const StockName_RequestScreen({super.key});

  @override
  State<StockName_RequestScreen> createState() =>
      _StockName_RequestScreenState();
}

class _StockName_RequestScreenState extends State<StockName_RequestScreen> {
  bool _initDone = false;
  bool _nodata = false;
  StockResponse request = StockResponse();
  List<Map<String, dynamic>> stocks = [];
  final TextEditingController _searchData = TextEditingController();
  int? dataId;
  bool _search = false;
  bool isExpanded = false;
  int? expandedItemId;
  @override
  void initState() {
    super.initState();
    _getRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: SizedBox(
      //   width: SizeConfig.blockSizeHorizontal * 70,
      //   height: SizeConfig.blockSizeVertical * 7,
      //   child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      //     // First Button
      //     SizedBox(
      //       width: SizeConfig.blockSizeHorizontal * 30,
      //       child: ElevatedButton(
      //         style: ButtonStyle(
      //           shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      //             RoundedRectangleBorder(
      //               borderRadius: BorderRadius.circular(7.0),
      //             ),
      //           ),
      //           backgroundColor:WidgetStatePropertyAll(
      //                       AppConfig.colorPrimary),
      //         ),
      //         onPressed: () {
      //           Navigator.pushNamed(context, Stock_Name.routeName);
      //         },
      //         child: Text(
      //           'NEW',
      //           style: TextStyle(
      //             fontSize: AppConfig.textCaption3Size,
      //             color: AppConfig.backgroundColor,
      //             fontWeight: AppConfig.headLineWeight,
      //           ),
      //         ),
      //       ),
      //     ),
      //   ]),
      // ),
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimary,
        // iconTheme: IconThemeData(color: AppConfig.backgroundColor),
        leading: GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, HomeScreen.routeName);
          },
            child: Icon(Icons.arrow_back,color: Colors.white,)),
        title: const Text(
          'Stock Take Requests',
          style: AppConfig.pageTitleStyle,
        ),
        actions: [
          (_search)
              ? Container(
                  height: SizeConfig.blockSizeVertical * 5,
                  width: SizeConfig.blockSizeHorizontal * 76,
                  decoration: BoxDecoration(
                    color: AppConfig.colorPrimary,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                    border: Border.all(color: AppConfig.colorPrimary),
                  ),
                  child: TextField(
                    controller: _searchData,
                    decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(5),
                        hintText: "Search...",
                        hintStyle: TextStyle(color: AppConfig.backgroundColor),
                        border: InputBorder.none),
                  ),
                )
              : Container(),
          CommonWidgets.horizontalSpace(1),
          (!_search)
              ? GestureDetector(
                  onTap: () async {
                    // if (stocks.isEmpty) {
                    //   Navigator.pushReplacementNamed(
                    //       context, SelectProductsScreen.routeName);
                    // } else {
                    Navigator.pushReplacementNamed(
                        context, Stock_Name.routeName);
                    // }
                  },
                  child: const Icon(
                    Icons.add,
                    size: 30,
                    color: AppConfig.backgroundColor,
                  ),
                )
              : Container(),
          CommonWidgets.horizontalSpace(1),
          GestureDetector(
            onTap: () {
              setState(() {
                _search = !_search;
              });
            },
            child: Icon(
              (!_search) ? Icons.search : Icons.close,
              size: 30,
              color: AppConfig.backgroundColor,
            ),
          ),
          CommonWidgets.horizontalSpace(3),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 18.0, left: 18, right: 18),
        child: SingleChildScrollView(
          child: Column(
            children: [
              (_initDone && !_nodata)
                  ? SizedBox(
                      height: SizeConfig.blockSizeVertical * 85,
                      child: ListView.separated(
                        separatorBuilder: (BuildContext context, int index) =>
                            CommonWidgets.verticalSpace(1),
                        itemCount: request.data!.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) =>
                            _requestsTab(index, request.data![index]),
                      ),
                    )
                  : (_nodata && _initDone)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              CommonWidgets.verticalSpace(3),
                              const Center(
                                child: Text('No Data'),
                              ),
                            ])
                      : Shimmer.fromColors(
                          baseColor:
                              AppConfig.buttonDeactiveColor.withOpacity(0.1),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _requestsTab(int index, StockData data) {
    Future<void> saveCompleteData() async {
      final url = Uri.parse('${RestDatasource().BASE_URL}/api/stock-take.complete');
      final headers = {"Content-Type": "application/json"};

      final body = jsonEncode({
        'id': data.id,
        'store_id': AppState().storeId
      });

      try {
        final response = await http.post(url, headers: headers, body: body);
        print(dataId);

        if (response.statusCode == 200) {
          print(response.body);
          print(body);

          // Refresh the data after successful completion
          await _getRequests();

          if (mounted) {
            // Option 1: Show a snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Completed successfully')),
            );

            // Option 2: Or show a dialog (choose one)
            // CommonWidgets.showDialogueBox(
            //   context: context,
            //   title: "Success",
            //   msg: "Completed successfully",
            // );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to complete: ${response.body}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
    return Card(
      elevation: 3,
      child: Container(
        decoration: const BoxDecoration(
          color: AppConfig.backgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(
          children: [
            ListTile(
              title: Row(
                children: [
                  CommonWidgets.horizontalSpace(1),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: SizeConfig.blockSizeHorizontal * 45,
                        child: Row(
                          children: [
                            Tooltip(
                              message: '${data.invoiceNo}',
                              child: SizedBox(
                                width: SizeConfig.blockSizeHorizontal * 30,
                                child: Text(
                                  (data.invoiceNo!.length > 15)
                                      ? '${data.invoiceNo!.substring(0, 15)}...'
                                      : '${data.invoiceNo}',
                                  style: TextStyle(
                                      fontWeight: AppConfig.headLineWeight),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
  DateHelper.displayDate(data.inDate),
  style: TextStyle(
    fontSize: AppConfig.textCaption3Size * 0.9,
    fontWeight: AppConfig.headLineWeight,
  ),
),
                    ],
                  ),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(AppConfig.colorPrimary),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        Stock_Name.routeName,
                        arguments: {'id': data.id},
                      );
                      print("DATAA${data.id}");
                    },
                    child: Text(
                      "Add",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      expandedItemId == data.id
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppConfig.colorPrimary,
                    ),
                    onPressed: () {
                      setState(() {
                        if (expandedItemId == data.id) {
                          expandedItemId = null;
                        } else {
                          expandedItemId = data.id;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            if (expandedItemId == data.id)
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonWidgets.verticalSpace(1),
                    Divider(
                      color: AppConfig.buttonDeactiveColor.withOpacity(0.4),
                    ),
                    for (int i = 0; i < data.detail!.length; i++)
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Tooltip(
                              message: (data.detail![i].productName ?? '')
                                  .toUpperCase(),
                              child: SizedBox(
                                width: SizeConfig.blockSizeHorizontal * 80,
                                child: Text(
                                  '${data.detail![i].productCode ?? ''} | ${(data.detail![i].productName ?? '').toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: AppConfig.textCaption3Size,
                                    fontWeight: AppConfig.headLineWeight,
                                  ),
                                ),
                              ),
                            ),
                            CommonWidgets.verticalSpace(1),
                            Row(
                              children: [
                                Text(
                                  '${data.detail![i].unit}: ${data.detail![i].quantity} | ${data.detail![i].productType == null ? 'Normal' : data.detail![i].productType}',
                                  style: TextStyle(
                                    fontSize: AppConfig.textCaption3Size,
                                    fontWeight: AppConfig.headLineWeight,
                                  ),
                                ),
                                CommonWidgets.horizontalSpace(2),
                                // Text(
                                //   'Requested Qty: ${data.detail![i].quantity}',
                                //   style: TextStyle(
                                //     fontSize: AppConfig.textCaption3Size,
                                //     fontWeight: AppConfig.headLineWeight,
                                //   ),
                                // ),
                              ],
                            ),
                            Divider(
                              color: AppConfig.buttonDeactiveColor
                                  .withOpacity(0.4),
                            ),
                          ],
                        ),
                      ),
                    Center(
                        child: ElevatedButton(
                            style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                    AppConfig.colorPrimary),
                                shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                fixedSize: WidgetStatePropertyAll(Size(
                                    SizeConfig.blockSizeHorizontal * 30,
                                    SizeConfig.blockSizeVertical * 3))),
                            onPressed: () {
                              saveCompleteData();
                            },
                            child: Text(
                              'Complete',
                              style: TextStyle(color: Colors.white),
                            )))
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _getRequests() async {
    RestDatasource api = RestDatasource();
    stocks = await StockHistory.getStockHistory();
    dynamic resJson = await api.getDetails(
        '/api/stock-take.index?store_id=${AppState().storeId}&van_id=${AppState().vanId}',
        AppState().token);

    if (resJson['data'] != null) {
      print(request);
      request = StockResponse.fromJson(resJson);
      if (mounted) {
        setState(
          () {
            _initDone = true;
          },
        );
      }
    } else {
      setState(() {
        _initDone = true;
        _nodata = true;
      });
    }
  }

  Future<void> cancelVanOffloadRequest(int id) async {
    // The URL to which the POST request will be made
    final url = '${RestDatasource().BASE_URL}/api/vanoffloadrequest.cancel';

    // Create the body of the request
    final body = jsonEncode({'id': id});

    try {
      // Make the POST request
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: body,
      );

      // Check the status code for success or failure
      if (response.statusCode == 200) {
        // Successful response
        setState(() {
          _getRequests();
        });
        print('Request was successful');
        print('Response body: ${response.body}');
      } else {
        // Failed response
        print('Failed to cancel request');
        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      // Handle any exceptions
      print('Error occurred: $e');
    }
  }
}
