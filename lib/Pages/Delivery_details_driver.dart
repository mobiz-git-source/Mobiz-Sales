import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import '../Components/commonwidgets.dart';
import '../Models/DriverDetailsModel.dart';
import '../Models/appstate.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';

class DeliveryDetailsDriver extends StatefulWidget {
  static const routeName = "/ProductDetailsDriver";

  const DeliveryDetailsDriver({super.key});

  @override
  State<DeliveryDetailsDriver> createState() => _DeliveryDetailsDriverState();
}

class _DeliveryDetailsDriverState extends State<DeliveryDetailsDriver>
    with SingleTickerProviderStateMixin {
  List<bool> isSelected = [true, false, false];
  bool _isButtonDisabled = false;
  // void _onContainerTap(int index) {
  //   setState(() {
  //     for (int i = 0; i < isSelected.length; i++) {
  //       if (i == index) {
  //         isSelected[i] = true;
  //       } else {
  //         isSelected[i] = false;
  //       }
  //     }
  //     futureDeliveries = fetchDeliverstatus(txt[index].toLowerCase());
  //   });
  // }

  late TabController _tabController;

  List<bool> expandedStates = [];
  List<bool> expandedStates1 = [];
  List<bool> expandedStates2 = [];
  List<bool> expandedStates3 = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    futureLoading = fetchDeliverLoadingPending();
    futurePending = fetchDeliverstatusPending();
    futureDelivered = fetchDeliverstatusDelivered();
    futureAll = fetchDeliverstatusAll();
  }

  late Future<List<CustomerDelivery>> futureLoading;
  late Future<List<CustomerDelivery>> futurePending;
  late Future<List<CustomerDelivery>> futureDelivered;
  late Future<List<CustomerDelivery>> futureAll;

  Future<List<CustomerDelivery>> fetchDeliverLoadingPending() async {
    final String uri =
        '${RestDatasource().BASE_URL}/api/delivery_loading_pending?store_id=${AppState().storeId}&user_id=${AppState().userId}';
    final response = await http.get(Uri.parse(uri));
    print(uri);
    if (response.statusCode == 200) {
      // print(AppState().storeId);
      // print(AppState().userId);

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success']) {
        final deliveries = List<CustomerDelivery>.from(jsonResponse['data']
            .map((delivery) => CustomerDelivery.fromJson(delivery)));
        setState(() {
          expandedStates3 = List<bool>.filled(deliveries.length, false);
        });

        return deliveries;
      } else {
        throw Exception('Failed to load data');
      }
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> postDeliveryDriverConfirm(int id) async {
    // Disable the button
    setState(() {
      _isButtonDisabled = true;
    });

    // Define the URL of the API
    final url = Uri.parse(
        '${RestDatasource().BASE_URL}/api/delivery_driver_confirm?id=$id');

    // Define the headers
    final headers = {
      'Content-Type': 'application/json',
    };

    try {
      // Send the POST request
      final response = await http.post(
        url,
        headers: headers,
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Successfully received response
        print('Success: ${response.body}');
        print("sjdbjsbdjsbds");
        futureLoading = fetchDeliverLoadingPending();
        futurePending = fetchDeliverstatusPending();
        futureDelivered = fetchDeliverstatusDelivered();
        futureAll = fetchDeliverstatusAll();
      } else {
        // Something went wrong
        print('Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // Handle any errors that occur
      print('Exception: $e');
    } finally {
      // Re-enable the button regardless of the outcome
      setState(() {
        _isButtonDisabled = false;
      });
    }
  }

  Future<List<CustomerDelivery>> fetchDeliverstatusPending() async {
    final String uri =
        '${RestDatasource().BASE_URL}/api/get_scheduled_delivery_by_driver_pending?store_id=${AppState().storeId}&user_id=${AppState().userId}';
    final response = await http.get(Uri.parse(uri));
    print(uri);
    if (response.statusCode == 200) {
      // print(AppState().storeId);
      // print(AppState().userId);

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success']) {
        final deliveries = List<CustomerDelivery>.from(jsonResponse['data']
            .map((delivery) => CustomerDelivery.fromJson(delivery)));

        // Reset expandedStates to match the length of the new deliveries
        setState(() {
          expandedStates = List<bool>.filled(deliveries.length, false);
        });

        return deliveries;
      } else {
        throw Exception('Failed to load data');
      }
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<List<CustomerDelivery>> fetchDeliverstatusDelivered() async {
    final String uri =
        '${RestDatasource().BASE_URL}/api/get_scheduled_delivery_by_driver_delivered?store_id=${AppState().storeId}&user_id=${AppState().userId}';
    final response = await http.get(Uri.parse(uri));
    print(uri);
    if (response.statusCode == 200) {
      // print(AppState().storeId);
      // print(AppState().userId);

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success']) {
        final deliveries = List<CustomerDelivery>.from(jsonResponse['data']
            .map((delivery) => CustomerDelivery.fromJson(delivery)));

        // Reset expandedStates to match the length of the new deliveries
        setState(() {
          expandedStates1 = List<bool>.filled(deliveries.length, false);
        });

        return deliveries;
      } else {
        throw Exception('Failed to load data');
      }
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<List<CustomerDelivery>> fetchDeliverstatusAll() async {
    final String uri =
        '${RestDatasource().BASE_URL}/api/get_scheduled_delivery_by_driver_all?store_id=${AppState().storeId}&user_id=${AppState().userId}';
    final response = await http.get(Uri.parse(uri));
    print(uri);
    if (response.statusCode == 200) {
      // print(AppState().storeId);
      // print(AppState().userId);

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success']) {
        final deliveries = List<CustomerDelivery>.from(jsonResponse['data']
            .map((delivery) => CustomerDelivery.fromJson(delivery)));

        // Reset expandedStates to match the length of the new deliveries
        setState(() {
          expandedStates2 = List<bool>.filled(deliveries.length, false);
        });

        return deliveries;
      } else {
        throw Exception('Failed to load data');
      }
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  late String name;
  late String address;
  late String code;
  List<String> txt = ['Pending', 'Delivered', 'All'];
  @override
  Widget build(BuildContext context) {
    // if (ModalRoute.of(context)!.settings.arguments != null) {
    //   final Map<String, dynamic>? params =
    //       ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    //   name = params!['name'];
    //   address = params['address'];
    //   phone = params!['phone'];
    //   location = params['location'];
    //   whatsappNumber = params['whatsappNumber'];
    //   customerType = params!['customerType'];
    //   creditDays = params['days'];
    //   creditBalance = params['balance'];
    //   totalOutstanding = params['total'];
    //   trn = params['trn'];
    //   paymentTerms = params['paymentTerms'];
    //   provinceId = params['provinceId'];
    //   routeId = params['routeId'];
    //   creditLimit = params!['creditLimit'];
    //   email = params!['mail'];
    //   id = params['id'];
    //   code = params['code'];
    // }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimary,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
            // print(AppState().storeId);
            // print(AppState().userId);
          },
          child: Icon(
            Icons.arrow_back,
            color: AppConfig.backgroundColor,
          ),
        ),
        title: Text(
          'Delivery',
         style: AppConfig.pageTitleStyle,
        ),
      ),
      body: Column(
        children: [
          TabBar(
            labelStyle: TextStyle(
                color: AppConfig.backgroundColor, fontWeight: FontWeight.bold),
            padding: EdgeInsets.all(8),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            splashBorderRadius: BorderRadius.circular(10),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppConfig.colorPrimary,
            ),
            controller: _tabController,
            tabs: [
              Tab(text: 'Loading\nPending'),
              Tab(text: 'Delivery\nPending'),
              Tab(text: 'Delivered'),
              Tab(text: 'All'),
            ],
          ),
          SizedBox(
            height: 10.h,
          ),
          // Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceAround,
          //     children: List.generate(3, (index) {
          //       return GestureDetector(
          //         onTap: () => _onContainerTap(index),
          //         child: Container(
          //           decoration: BoxDecoration(
          //               color: isSelected[index]
          //                   ? AppConfig.colorPrimary
          //                   : AppConfig.backgroundColor,
          //               border: Border.all(
          //                   color: AppConfig.colorPrimary, width: 1.w)),
          //           width: 100.w,
          //           height: 30.h,
          //           child: Center(
          //               child: Text(
          //             txt[index],
          //             style: TextStyle(
          //                 color: isSelected[index]
          //                     ? AppConfig.backgroundColor
          //                     : AppConfig.colorPrimary,
          //                 fontWeight: FontWeight.bold),
          //           )),
          //         ),
          //       );
          //     })),
          Expanded(
              child: TabBarView(controller: _tabController, children: [
            Container(
              child: Column(
                children: [
                  FutureBuilder<List<CustomerDelivery>>(
                      future: futureLoading,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Shimmer.fromColors(
                            baseColor:
                                AppConfig.buttonDeactiveColor.withOpacity(0.1),
                            highlightColor: AppConfig.backButtonColor,
                            child: Center(
                              child: Column(
                                children: [
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                ],
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          print('Error: ${snapshot.error}');
                          return Center(child: Text('No data'));
                        } else {
                          if (expandedStates3.isEmpty) {
                            expandedStates3 =
                                List<bool>.filled(snapshot.data!.length, false);
                          }
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(
                                child: ListView.builder(
                                  scrollDirection: Axis.vertical,
                                  shrinkWrap: true,
                                  physics: BouncingScrollPhysics(),
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    final delivery = snapshot.data![index];
                                    // final isSelected =
                                    // selectedDeliveries.contains(delivery);
                                    return Card(
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppConfig.backgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Tooltip(
                                                    message: delivery.invoiceNo,
                                                    child: Text(
                                                      '${delivery.invoiceNo}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: AppConfig
                                                            .textCaption3Size,
                                                        color: Colors.black87,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  IconButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          expandedStates3[
                                                                  index] =
                                                              !expandedStates3[
                                                                  index];
                                                        });
                                                      },
                                                      icon: Icon(Icons
                                                          .arrow_drop_down_circle))
                                                ],
                                              ),
                                              Visibility(
                                                  visible:
                                                      expandedStates3[index],
                                                  child: Container(
                                                    child: Column(
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: delivery
                                                              .details
                                                              .map((Details) {
                                                            return Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'Prd: ${Details.name}',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        AppConfig
                                                                            .textCaption3Size,
                                                                    color: Colors
                                                                        .black54,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  'Qty: ${Details.quantity}',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        AppConfig
                                                                            .textCaption3Size,
                                                                    color: Colors
                                                                        .black54,
                                                                  ),
                                                                ),
                                                                Divider(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade300,
                                                                )
                                                              ],
                                                            );
                                                          }).toList(),
                                                        ),
                                                        IntrinsicWidth(
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor:
          _isButtonDisabled ? Colors.grey : AppConfig.colorPrimary,
      minimumSize: Size(0, 40.h),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    onPressed: _isButtonDisabled
        ? null
        : () {
            postDeliveryDriverConfirm(delivery.id);
          },
    child: Text(
      'Confirm',
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: TextStyle(
        color: Colors.white,
      ),
    ),
  ),
)
                                                      ],
                                                    ),
                                                  ))
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        }
                      })
                ],
              ),
            ),
            Container(
              child: Column(
                children: [
                  FutureBuilder<List<CustomerDelivery>>(
                      future: futurePending,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Shimmer.fromColors(
                            baseColor:
                                AppConfig.buttonDeactiveColor.withOpacity(0.1),
                            highlightColor: AppConfig.backButtonColor,
                            child: Center(
                              child: Column(
                                children: [
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                ],
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          print('Error: ${snapshot.error}');
                          return Center(child: Text('No data'));
                        } else {
                          if (expandedStates.isEmpty) {
                            expandedStates =
                                List<bool>.filled(snapshot.data!.length, false);
                          }
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(
                                child: ListView.builder(
                                  scrollDirection: Axis.vertical,
                                  shrinkWrap: true,
                                  physics: BouncingScrollPhysics(),
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    final delivery = snapshot.data![index];
                                    // final isSelected =
                                    // selectedDeliveries.contains(delivery);
                                    return Card(
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppConfig.backgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Tooltip(
                                                    message: delivery.invoiceNo,
                                                    child: Text(
                                                      '${delivery.invoiceNo}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: AppConfig
                                                            .textCaption3Size,
                                                        color: Colors.black87,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  IconButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          expandedStates[
                                                                  index] =
                                                              !expandedStates[
                                                                  index];
                                                        });
                                                      },
                                                      icon: Icon(Icons
                                                          .arrow_drop_down_circle))
                                                ],
                                              ),
                                              Visibility(
                                                  visible:
                                                      expandedStates[index],
                                                  child: Container(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: delivery.details
                                                          .map((Details) {
                                                        return Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Prd: ${Details.name}',
                                                              style: TextStyle(
                                                                fontSize: AppConfig
                                                                    .textCaption3Size,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                            ),
                                                            Text(
                                                              'Qty: ${Details.quantity}',
                                                              style: TextStyle(
                                                                fontSize: AppConfig
                                                                    .textCaption3Size,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                            ),
                                                            Divider(
                                                              color: Colors.grey
                                                                  .shade300,
                                                            )
                                                          ],
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ))
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        }
                      })
                ],
              ),
            ),
            Container(
              child: Column(
                children: [
                  FutureBuilder<List<CustomerDelivery>>(
                      future: futureDelivered,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Shimmer.fromColors(
                            baseColor:
                                AppConfig.buttonDeactiveColor.withOpacity(0.1),
                            highlightColor: AppConfig.backButtonColor,
                            child: Center(
                              child: Column(
                                children: [
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                ],
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          print('Error: ${snapshot.error}');
                          return Center(child: Text('No data'));
                        } else {
                          if (expandedStates1.isEmpty) {
                            expandedStates1 =
                                List<bool>.filled(snapshot.data!.length, false);
                          }
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(
                                child: ListView.builder(
                                  scrollDirection: Axis.vertical,
                                  shrinkWrap: true,
                                  physics: BouncingScrollPhysics(),
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    final delivery = snapshot.data![index];
                                    // final isSelected =
                                    // selectedDeliveries.contains(delivery);
                                    return Card(
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppConfig.backgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Tooltip(
                                                    message: delivery.invoiceNo,
                                                    child: Text(
                                                      '${delivery.invoiceNo}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: AppConfig
                                                            .textCaption3Size,
                                                        color: Colors.black87,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  IconButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          expandedStates1[
                                                                  index] =
                                                              !expandedStates1[
                                                                  index];
                                                        });
                                                      },
                                                      icon: Icon(Icons
                                                          .arrow_drop_down_circle))
                                                ],
                                              ),
                                              Visibility(
                                                  visible:
                                                      expandedStates1[index],
                                                  child: Container(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: delivery.details
                                                          .map((Details) {
                                                        return Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Prd: ${Details.name}',
                                                              style: TextStyle(
                                                                fontSize: AppConfig
                                                                    .textCaption3Size,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                            ),
                                                            Text(
                                                              'Qty: ${Details.quantity}',
                                                              style: TextStyle(
                                                                fontSize: AppConfig
                                                                    .textCaption3Size,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                            ),
                                                            Divider(
                                                              color: Colors.grey
                                                                  .shade300,
                                                            )
                                                          ],
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ))
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        }
                      })
                ],
              ),
            ),
            Container(
              child: Column(
                children: [
                  FutureBuilder<List<CustomerDelivery>>(
                      future: futureAll,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Shimmer.fromColors(
                            baseColor:
                                AppConfig.buttonDeactiveColor.withOpacity(0.1),
                            highlightColor: AppConfig.backButtonColor,
                            child: Center(
                              child: Column(
                                children: [
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                  CommonWidgets.loadingContainers(
                                      height: SizeConfig.blockSizeVertical * 10,
                                      width:
                                          SizeConfig.blockSizeHorizontal * 90),
                                ],
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          print('Error: ${snapshot.error}');
                          return Center(child: Text('No data'));
                        } else {
                          if (expandedStates2.isEmpty) {
                            expandedStates2 =
                                List<bool>.filled(snapshot.data!.length, false);
                          }
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(
                                child: ListView.builder(
                                  scrollDirection: Axis.vertical,
                                  shrinkWrap: true,
                                  physics: BouncingScrollPhysics(),
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    final delivery = snapshot.data![index];
                                    // final isSelected =
                                    // selectedDeliveries.contains(delivery);
                                    return Card(
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppConfig.backgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Tooltip(
                                                    message: delivery.invoiceNo,
                                                    child: Text(
                                                      '${delivery.invoiceNo}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: AppConfig
                                                            .textCaption3Size,
                                                        color: Colors.black87,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  IconButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          expandedStates2[
                                                                  index] =
                                                              !expandedStates2[
                                                                  index];
                                                        });
                                                      },
                                                      icon: Icon(Icons
                                                          .arrow_drop_down_circle))
                                                ],
                                              ),
                                              Visibility(
                                                  visible:
                                                      expandedStates2[index],
                                                  child: Container(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: delivery.details
                                                          .map((Details) {
                                                        return Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Prd: ${Details.name}',
                                                              style: TextStyle(
                                                                fontSize: AppConfig
                                                                    .textCaption3Size,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                            ),
                                                            Text(
                                                              'Qty: ${Details.quantity}',
                                                              style: TextStyle(
                                                                fontSize: AppConfig
                                                                    .textCaption3Size,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                            ),
                                                            Divider(
                                                              color: Colors.grey
                                                                  .shade300,
                                                            )
                                                          ],
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ))
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        }
                      })
                ],
              ),
            ),
          ]))
        ],
      ),
    );
  }
}
