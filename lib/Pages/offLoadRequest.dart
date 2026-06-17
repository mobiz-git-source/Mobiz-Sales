import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobizapp/Pages/selectProducts.dart';
import 'package:mobizapp/Pages/newvanstockrequests.dart';
import 'package:mobizapp/Pages/vanstockoff.dart';
import 'package:shimmer/shimmer.dart';

import '../Components/commonwidgets.dart';
import '../Models/appstate.dart';
import '../Models/requestmodelclass.dart';
import '../Models/stockdata.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import 'package:http/http.dart' as http;
import '../confg/sizeconfig.dart';
import 'TestExpensePage.dart';
import '../vanstocktst.dart';

class OffLoadRequestScreen extends StatefulWidget {
  static const routeName = "/OffLoadRequest";
  const OffLoadRequestScreen({super.key});

  @override
  State<OffLoadRequestScreen> createState() => _OffLoadRequestScreenState();
}

class _OffLoadRequestScreenState extends State<OffLoadRequestScreen> {
  bool _initDone = false;
  bool _nodata = false;
  List<Map<String, dynamic>> stocks = [];
  final TextEditingController _searchData = TextEditingController();
  bool _search = false;
  late ScrollController _scrollController;
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMoreData = true;
  List<VanOffloadRequest> request = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _getRequests();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMoreData) {
      _getRequests();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimary,
        iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
        title: Text(
          'Off Load Requests',
          style: TextStyle(color: AppConfig.backgroundColor),
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
                        context, VanStocksoff.routeName);
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
                  controller: _scrollController,
                  separatorBuilder: (BuildContext context, int index) =>
                      CommonWidgets.verticalSpace(1),
                  itemCount: request.length + 1, // Adding 1 to account for the footer
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    if (index < request.length) {
                      return _requestsTab(index, request[index]);
                    } else {
                      if (_isLoading) {
                        return Center(
                          child: Text("Loading...",style: TextStyle(color: Colors.grey.shade400,fontStyle: FontStyle.italic),),
                        );
                      } else if (!_hasMoreData) {
                        return Center(
                          child: Text("That's all",style: TextStyle(color: Colors.grey.shade400,fontStyle: FontStyle.italic,fontWeight: FontWeight.w700),),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    }
                  },
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

  Widget _requestsTab(int index, VanOffloadRequest data) {
    return Card(
      elevation: 3,
      child: Container(
        decoration: const BoxDecoration(
            color: AppConfig.backgroundColor,
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          trailing: Transform.rotate(
            angle: 100,
            child: const Icon(Icons.touch_app, color: Colors.transparent),
          ),
          backgroundColor: AppConfig.backgroundColor,
          title: Row(
            children: [
              CommonWidgets.horizontalSpace(1),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: SizeConfig.blockSizeHorizontal * 65,
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
                        // CommonWidgets.horizontalSpace(12),
                        Spacer(),
                        Text(
                          (data.status == 1)
                              ? 'Pending'
                              : (data.status == 2)
                                  ? 'Approved'
                                  : (data.status == 0)
                                      ? 'Cancelled'
                                      : 'Confirmed',
                          style: TextStyle(
                              fontSize: AppConfig.textCaption3Size,
                              color: (data.status == 1)
                                  ? AppConfig.colorWarning
                                  : (data.status == 2)
                                      ? Colors.orange
                                      : (data.status == 0)
                                          ? Colors.red
                                          : Colors.green,
                              fontWeight: AppConfig.headLineWeight),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    data.inDate!.substring(0, 10),
                    style: TextStyle(
                        fontSize: AppConfig.textCaption3Size * 0.9,
                        fontWeight: AppConfig.headLineWeight),
                  ),
                ],
              ),
            ],
          ),
          children: <Widget>[
            (data.status == 2)
                ? Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonWidgets.verticalSpace(1),
                        Divider(
                          color: AppConfig.buttonDeactiveColor.withOpacity(0.4),
                        ),
                        for (int i = 0; i < data.details!.length; i++)
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Tooltip(
                                  message: (data.details![i].productName ?? '')
                                      .toUpperCase(),
                                  child: SizedBox(
                                    width: SizeConfig.blockSizeHorizontal * 80,
                                    child: Text(
                                      '${data.details![i].productCode ?? ''} | ${(data.details![i].productName ?? '').toUpperCase()}',
                                      style: TextStyle(
                                          fontSize: AppConfig.textCaption3Size,
                                          fontWeight: AppConfig.headLineWeight),
                                    ),
                                  ),
                                ),
                                CommonWidgets.verticalSpace(1),
                                Row(
                                  children: [
                                    Text(
                                      '${data.details![i].unit} : ${data.details![i].approvedQuantity} | ${data.details![i].product_type == null ? 'Normal' : data.details![i].product_type == 'normal' ? 'Normal' : data.details![i].product_type}',
                                      style: TextStyle(
                                          fontSize: AppConfig.textCaption3Size,
                                          fontWeight: AppConfig.headLineWeight),
                                    ),
                                    CommonWidgets.horizontalSpace(2),
                                    Text(
                                      'Requested Qty: ${data.details![i].quantity}',
                                      style: TextStyle(
                                          fontSize: AppConfig.textCaption3Size,
                                          fontWeight: AppConfig.headLineWeight),
                                    ),
                                  ],
                                ),
                                Divider(
                                  color: AppConfig.buttonDeactiveColor
                                      .withOpacity(0.4),
                                ),
                              ],
                            ),
                          ),
                        // Text(
                        //   'RB0002',
                        //   style: TextStyle(
                        //       fontSize: AppConfig.textCaption3Size,
                        //       fontWeight: AppConfig.headLineWeight),
                        // ),
                        // Row(
                        //   children: [
                        //     Text(
                        //       'KELLOGGS KORN FLAKE',
                        //       style: TextStyle(
                        //           fontSize: AppConfig.textCaption3Size,
                        //           fontWeight: AppConfig.headLineWeight),
                        //     ),
                        //     const Spacer(),
                        //     Text(
                        //       'BOX QTY : 10',
                        //       style: TextStyle(
                        //           fontSize: AppConfig.textCaption3Size,
                        //           fontWeight: AppConfig.headLineWeight),
                        //     ),
                        //   ],
                        // ),
                        // const Divider(),
                        // CommonWidgets.verticalSpace(2),
                        // Center(
                        //   child: SizedBox(
                        //     width: SizeConfig.blockSizeHorizontal * 25,
                        //     height: SizeConfig.blockSizeVertical * 5,
                        //     child: ElevatedButton(
                        //       style: ButtonStyle(
                        //         shape: WidgetStateProperty.all<
                        //             RoundedRectangleBorder>(
                        //           RoundedRectangleBorder(
                        //             borderRadius: BorderRadius.circular(20.0),
                        //           ),
                        //         ),
                        //         backgroundColor: const WidgetStatePropertyAll(
                        //             AppConfig.colorPrimary),
                        //       ),
                        //       onPressed: () {
                        //         _conformrequest(data.detail![index].id ?? 0);
                        //       },
                        //       child: Text(
                        //         'Cancel',
                        //         style: TextStyle(
                        //             fontSize: AppConfig.textCaption3Size,
                        //             color: AppConfig.backgroundColor,
                        //             fontWeight: AppConfig.headLineWeight),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        CommonWidgets.verticalSpace(2),
                      ],
                    ),
                  )
                : (data.status == 1)
                    ? Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonWidgets.verticalSpace(1),
                            Divider(
                                color: AppConfig.buttonDeactiveColor
                                    .withOpacity(0.4)),
                            for (int i = 0; i < data.details!.length; i++)
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Tooltip(
                                      message:
                                          (data.details![i].productName ?? '')
                                              .toUpperCase(),
                                      child: SizedBox(
                                        width:
                                            SizeConfig.blockSizeHorizontal * 80,
                                        child: Text(
                                          '${data.details![i].productCode ?? ''} | ${(data.details![i].productName ?? '').toUpperCase()}',
                                          style: TextStyle(
                                              fontSize:
                                                  AppConfig.textCaption3Size,
                                              fontWeight:
                                                  AppConfig.headLineWeight),
                                        ),
                                      ),
                                    ),
                                    CommonWidgets.verticalSpace(1),
                                    Row(
                                      children: [
                                        Text(
                                          (data.status == 3)
                                              ? '${data.details![i].unit}: ${data.details![i].approvedQuantity} | ${data.details![i].product_type == null ? 'Normal' : data.details![i].product_type == 'normal' ? 'Normal' : data.details![i].product_type}'
                                              : '${data.details![i].unit}: ${data.details![i].quantity} | ${data.details![i].product_type == null ? 'Normal' : data.details![i].product_type == 'normal' ? 'Normal' : data.details![i].product_type}',
                                          style: TextStyle(
                                              fontSize:
                                                  AppConfig.textCaption3Size,
                                              fontWeight:
                                                  AppConfig.headLineWeight),
                                        ),
                                        CommonWidgets.horizontalSpace(2),
                                        (data.status == 3)
                                            ? Text(
                                                'Requested Qty: ${data.details![i].quantity}',
                                                style: TextStyle(
                                                    fontSize: AppConfig
                                                        .textCaption3Size,
                                                    fontWeight: AppConfig
                                                        .headLineWeight),
                                              )
                                            : const SizedBox(),
                                      ],
                                    ),
                                    (i == data.details!.length - 1)
                                        ? Container()
                                        : Divider(
                                            color: AppConfig.buttonDeactiveColor
                                                .withOpacity(0.4)),
                                  ],
                                ),
                              ),
                            Center(
                              child: SizedBox(
                                width: SizeConfig.blockSizeHorizontal * 25,
                                height: SizeConfig.blockSizeVertical * 5,
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    shape: WidgetStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                    ),
                                    backgroundColor:
                                        const WidgetStatePropertyAll(
                                            AppConfig.colorPrimary),
                                  ),
                                  onPressed: () {
                                    cancelVanOffloadRequest(data.id ?? 0);
                                    // _conformrequest(
                                    //     data.id ?? 0);
                                    print(data.id);
                                  },
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                        fontSize: AppConfig.textCaption3Size,
                                        color: AppConfig.backgroundColor,
                                        fontWeight: AppConfig.headLineWeight),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonWidgets.verticalSpace(1),
                            Divider(
                                color: AppConfig.buttonDeactiveColor
                                    .withOpacity(0.4)),
                            for (int i = 0; i < data.details!.length; i++)
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Tooltip(
                                      message:
                                          (data.details![i].productName ?? '')
                                              .toUpperCase(),
                                      child: SizedBox(
                                        width:
                                            SizeConfig.blockSizeHorizontal * 80,
                                        child: Text(
                                          '${data.details![i].productCode ?? ''} | ${(data.details![i].productName ?? '').toUpperCase()}',
                                          style: TextStyle(
                                              fontSize:
                                                  AppConfig.textCaption3Size,
                                              fontWeight:
                                                  AppConfig.headLineWeight),
                                        ),
                                      ),
                                    ),
                                    CommonWidgets.verticalSpace(1),
                                    Row(
                                      children: [
                                        Text(
                                          (data.status == 3)
                                              ? '${data.details![i].unit}: ${data.details![i].approvedQuantity} | ${data.details![i].product_type == null ? 'Normal' : data.details![i].product_type == 'normal' ? 'Normal' : data.details![i].product_type}'
                                              : '${data.details![i].unit}: ${data.details![i].quantity} | ${data.details![i].product_type == null ? 'Normal' : data.details![i].product_type == 'normal' ? 'Normal' : data.details![i].product_type}',
                                          style: TextStyle(
                                              fontSize:
                                                  AppConfig.textCaption3Size,
                                              fontWeight:
                                                  AppConfig.headLineWeight),
                                        ),
                                        CommonWidgets.horizontalSpace(2),
                                        (data.status == 3)
                                            ? Text(
                                                'Requested Qty: ${data.details![i].quantity}',
                                                style: TextStyle(
                                                    fontSize: AppConfig
                                                        .textCaption3Size,
                                                    fontWeight: AppConfig
                                                        .headLineWeight),
                                              )
                                            : const SizedBox(),
                                      ],
                                    ),
                                    (i == data.details!.length - 1)
                                        ? Container()
                                        : Divider(
                                            color: AppConfig.buttonDeactiveColor
                                                .withOpacity(0.4)),
                                    // Center(
                                    //   child: SizedBox(
                                    //     width:
                                    //         SizeConfig.blockSizeHorizontal * 25,
                                    //     height:
                                    //         SizeConfig.blockSizeVertical * 5,
                                    //     child: ElevatedButton(
                                    //       style: ButtonStyle(
                                    //         shape: WidgetStateProperty.all<
                                    //             RoundedRectangleBorder>(
                                    //           RoundedRectangleBorder(
                                    //             borderRadius:
                                    //                 BorderRadius.circular(20.0),
                                    //           ),
                                    //         ),
                                    //         backgroundColor:
                                    //             const WidgetStatePropertyAll(
                                    //                 AppConfig.colorPrimary),
                                    //       ),
                                    //       onPressed: () {
                                    //         _conformrequest(
                                    //             data.detail![i].id ?? 0);
                                    //       },
                                    //       child: Text(
                                    //         'Cancel',
                                    //         style: TextStyle(
                                    //             fontSize:
                                    //                 AppConfig.textCaption3Size,
                                    //             color:
                                    //                 AppConfig.backgroundColor,
                                    //             fontWeight:
                                    //                 AppConfig.headLineWeight),
                                    //       ),
                                    //     ),
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Future<void> _getRequests() async {
    // if (_isLoading || !_hasMoreData) return; // Prevent loading if already loading or no more data
    //
    // setState(() {
    //   _isLoading = true;
    // });
    // RestDatasource api = RestDatasource();
    // stocks = await StockHistory.getStockHistory();
    // dynamic resJson = await api.getDetails(
    //     '/api/vanoffloadrequest.index?store_id=${AppState().storeId}&van_id=${AppState().vanId}&page=$_currentPage',
    //     AppState().token);
    // final VanOffloadRequestResponse data =
    // VanOffloadRequestResponse.fromJson(jsonDecode(resJson.body));
    //
    // if (data.success) {
    //   if (resJson['data'] != null) {
    //     if (mounted) {
    //       setState(
    //             () {
    //           _initDone = true;
    //           _currentPage++;
    //           request.addAll(data.data!.data); // Assuming data.data.data is List<VanOffloadRequest>
    //           _hasMoreData = (data.data!.currentPage < data.data!.totalPages);
    //         },
    //       );
    //     }
    //   }
    // }else {
    //   setState(() {
    //     _initDone = true;
    //     _nodata = true;
    //     _hasMoreData = false;
    //   });
    // }
    if (_isLoading || !_hasMoreData)
      return; // Prevent loading if already loading or no more data

    setState(() {
      _isLoading = true;
    });

    final url =
        '${RestDatasource().BASE_URL}/api/vanoffloadrequest.index.api?store_id=${AppState().storeId}&van_id=${AppState().vanId}&page=$_currentPage';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      print(response.request);
      final VanOffloadRequestResponse data =
      VanOffloadRequestResponse.fromJson(jsonDecode(response.body));

      if (data.success) {
        setState(() {
          _initDone=true;
          _currentPage++;
          request.addAll(data.data?.data ?? []);
          _hasMoreData = (data.data!.currentPage < data.data!.totalPages);
        });
      } else {
        setState(() {
          _hasMoreData = false;
          _initDone=true;// No more data if the response is unsuccessful
        });
      }
    } else {
      setState(() {
        _hasMoreData = false;
      });
      throw Exception('Failed to load van offload request data');
    }

    setState(() {
      _isLoading = false;
    });
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
class VanOffloadRequestResponse {
  final bool success;
  final List<String>? messages; // Can be null
  final VanOffloadRequestData? data; // Can be null

  VanOffloadRequestResponse({
    required this.success,
    this.messages,
    this.data,
  });

  factory VanOffloadRequestResponse.fromJson(Map<String, dynamic> json) {
    return VanOffloadRequestResponse(
      success: json['success'] ?? false, // If null, default to false
      messages:
      json['messages'] != null ? List<String>.from(json['messages']) : null,
      data: json['data'] != null
          ? VanOffloadRequestData.fromJson(json['data'])
          : null,
    );
  }
}

// VanOffloadRequestData Model
class VanOffloadRequestData {
  final int currentPage;
  final List<VanOffloadRequest> data;
  final int totalPages;
  final int totalRecords;
  final String firstPageUrl;
  final String lastPageUrl;
  final List<PageLink> links;
  final String nextPageUrl;
  final String path;
  final int perPage;

  VanOffloadRequestData({
    required this.currentPage,
    required this.data,
    required this.totalPages,
    required this.totalRecords,
    required this.firstPageUrl,
    required this.lastPageUrl,
    required this.links,
    required this.nextPageUrl,
    required this.path,
    required this.perPage,
  });

  factory VanOffloadRequestData.fromJson(Map<String, dynamic> json) {
    return VanOffloadRequestData(
      currentPage: json['current_page'] ?? 1, // Default to 1 if null
      data: json['data'] != null
          ? List<VanOffloadRequest>.from(
          json['data'].map((x) => VanOffloadRequest.fromJson(x)))
          : [],
      totalPages: json['last_page'] ?? 0, // Default to 0 if null
      totalRecords: json['total'] ?? 0, // Default to 0 if null
      firstPageUrl:
      json['first_page_url'] ?? '', // Default to empty string if null
      lastPageUrl:
      json['last_page_url'] ?? '', // Default to empty string if null
      links: json['links'] != null
          ? List<PageLink>.from(json['links'].map((x) => PageLink.fromJson(x)))
          : [],
      nextPageUrl:
      json['next_page_url'] ?? '', // Default to empty string if null
      path: json['path'] ?? '', // Default to empty string if null
      perPage: json['per_page'] ?? 0, // Default to 0 if null
    );
  }
}

// PageLink Model
class PageLink {
  final String? url;
  final String label;
  final bool active;

  PageLink({
    this.url,
    required this.label,
    required this.active,
  });

  factory PageLink.fromJson(Map<String, dynamic> json) {
    return PageLink(
      url: json['url'], // Can be null
      label: json['label'] ?? '', // Default to empty string if null
      active: json['active'] ?? false, // Default to false if null
    );
  }
}

// VanOffloadRequest Model
class VanOffloadRequest {
  int? id;
  int? vanId;
  int? userId;
  String? inDate;
  String? inTime;
  String? invoiceNo;
  String? approvedDate;
  String? approvedTime;
  int? approvedUser;
  int? storeId;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  List<VanOffloadDetail>? details;

  VanOffloadRequest(
      {this.id,
        this.vanId,
        this.userId,
        this.inDate,
        this.inTime,
        this.invoiceNo,
        this.approvedDate,
        this.approvedTime,
        this.approvedUser,
        this.storeId,
        this.status,
        this.createdAt,
        this.updatedAt,
        this.deletedAt,
        this.details});

  VanOffloadRequest.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vanId = json['van_id'];
    userId = json['user_id'];
    inDate = json['in_date'];
    inTime = json['in_time'];
    invoiceNo = json['invoice_no'];
    approvedDate = json['approved_date'];
    approvedTime = json['approved_time'];
    approvedUser = json['approved_user'];
    storeId = json['store_id'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    if (json['detail'] != null) {
      details = <VanOffloadDetail>[];
      json['detail'].forEach((v) {
        details!.add(new VanOffloadDetail.fromJson(v));
      });
    }
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['van_id'] = this.vanId;
    data['user_id'] = this.userId;
    data['in_date'] = this.inDate;
    data['in_time'] = this.inTime;
    data['invoice_no'] = this.invoiceNo;
    data['approved_date'] = this.approvedDate;
    data['approved_time'] = this.approvedTime;
    data['approved_user'] = this.approvedUser;
    data['store_id'] = this.storeId;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    if (this.details != null) {
      data['detail'] = this.details!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VanOffloadDetail {
  int? id;
  int? vanRequestId;
  int? itemId;
  String? unit;
  String? product_type;
  String? name;
  double? quantity;
  int? editedQuantity;
  String? approvedQuantity;
  int? convertQty;
  int? vanId;
  int? userId;
  int? storeId;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  int? productId;
  String? productName;
  String? productCode;

  VanOffloadDetail(
      {this.id,
        this.vanRequestId,
        this.product_type,
        this.name,
        this.itemId,
        this.unit,
        this.quantity,
        this.editedQuantity,
        this.approvedQuantity,
        this.convertQty,
        this.vanId,
        this.userId,
        this.storeId,
        this.status,
        this.createdAt,
        this.updatedAt,
        this.deletedAt,
        this.productId,
        this.productCode,
        this.productName});

  VanOffloadDetail.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vanRequestId = json['van_request_id'];
    product_type = json['product_type'];
    name = json['name'];
    itemId = json['item_id'];
    unit = json['unit'];
    quantity = (json['quantity'] as num?)?.toDouble();
    approvedQuantity = json['approved_quantity'];
    convertQty = json['convert_qty'] == null
        ? null
        : int.tryParse(json['convert_qty'].toString());
    vanId = json['van_id'];
    userId = json['user_id'];
    storeId = json['store_id'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    productId = json['product_id'];
    productName = json['product_name'];
    productCode = json['product_code'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['van_request_id'] = this.vanRequestId;
    data['item_id'] = this.itemId;
    data['unit'] = this.unit;
    data['quantity'] = this.quantity;
    data['approved_quantity'] = this.approvedQuantity;
    data['convert_qty'] = this.convertQty;
    data['van_id'] = this.vanId;
    data['user_id'] = this.userId;
    data['store_id'] = this.storeId;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    data['product_id'] = this.productId;
    data['product_name'] = this.productName;
    data['product_code'] = this.productCode;
    return data;
  }
}
