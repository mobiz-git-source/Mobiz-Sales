import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Pages/homepage.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

import '../Components/commonwidgets.dart';
import '../Models/DriverDetailsModel.dart';
import '../Models/appstate.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'homepage_Driver.dart';

class DriverDetails extends StatefulWidget {
  static const routeName = "/DriverDetails";
  const DriverDetails({super.key});

  @override
  State<DriverDetails> createState() => _DriverDetailsState();
}

int? id;
String? name;
String? address;
String? code;

class _DriverDetailsState extends State<DriverDetails> {
  // late Future<ApiResponse> _futureData;
  late Future<List<CustomerDelivery>> futureDeliveries;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  List<bool> expandedStates = [];
  @override
  void initState() {
    super.initState();

    futureDeliveries = fetchCustomerDeliveries();
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)!.settings.arguments != null) {
      final Map<String, dynamic>? params =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      id = params!['customer'];
      name = params['name'];
      address = params['address'];
      code = params['code'];
    }

    // Fetch customer deliveries here, as the context is now safe to use.
    futureDeliveries = fetchCustomerDeliveries();
  }

  // Future<ApiResponse> fetchData() async {
  //   final response = await http.get(Uri.parse(
  //       '${RestDatasource().BASE_URL}/api/get_customer_delivery_by_driver?store_id=${AppState().storeId}&user_id=${AppState().userId}'));
  //
  //   if (response.statusCode == 200) {
  //     final jsonResponse = json.decode(response.body);
  //     return ApiResponse.fromJson(jsonResponse);
  //   } else {
  //     throw Exception('Failed to load data');
  //   }
  // }
  void _toggleSelection(CustomerDelivery delivery) {
    setState(() {
      if (selectedDeliveries.contains(delivery)) {
        selectedDeliveries.remove(delivery);
      } else {
        selectedDeliveries.add(delivery);
      }
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  List<CustomerDelivery> selectedDeliveries = [];
  final TextEditingController _RecieveController = TextEditingController();
  final TextEditingController _RmarksController = TextEditingController();

  Future<File> _convertUiImageToFile(ui.Image signatureImage) async {
    // Convert ui.Image to ByteData
    ByteData? byteData =
        await signatureImage.toByteData(format: ui.ImageByteFormat.png);

    // Check if byteData is null
    if (byteData == null) {
      throw Exception("Failed to convert signature to image");
    }

    // Convert ByteData to Uint8List
    Uint8List imageData = byteData.buffer.asUint8List();

    // Get temporary directory
    final directory = await getTemporaryDirectory();

    // Create a file in the temporary directory
    final file = File('${directory.path}/signature.png');

    // Write the image data to the file
    await file.writeAsBytes(imageData);

    return file;
  }

  @override
  Widget build(BuildContext context) {
    // if (ModalRoute.of(context)!.settings.arguments != null) {
    //   final Map<String, dynamic>? params =
    //       ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    //   id = params!['customer'];
    //   name = params['name'];
    //   address = params['address'];
    //   code = params['code'];
    // }

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
        title: const Text(
          'Driver Details',
          style: AppConfig.pageTitleStyle,
        ),
        backgroundColor: AppConfig.colorPrimary,
      ),
      body: FutureBuilder<List<CustomerDelivery>>(
        future: futureDeliveries,
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
            print('Error: ${snapshot.error}');
            return Center(child: Text('No data'));
          } else if (snapshot.hasError) {
            return Center(child: Text('No data available'));
          } else {
            // final List<Data> data = snapshot.data!.data;

            Future<void> postData() async {
              ui.Image? signatureImage = await _signatureController.toImage();

              if (signatureImage == null) {
                print("Failed to capture signature image");
                return;
              }

              File signatureFile;
              try {
                signatureFile = await _convertUiImageToFile(signatureImage);
              } catch (e) {
                print(e.toString());
                return;
              }
              List<String> invoiceNos = [];
              List<int> goodsOutIds = [];

              for (var delivery in selectedDeliveries) {
                invoiceNos.add(delivery.invoiceNo);
                goodsOutIds.add(delivery.id);
              }
              final url = Uri.parse(
                  '${RestDatasource().BASE_URL}/api/customer-delivery.store');
              final headers = {"Content-Type": "application/json"};
              final body = jsonEncode({
                "customer_id": id,
                "store_id": AppState().storeId.toString(),
                "user_id": AppState().userId.toString(),
                "invoice_no": invoiceNos,
                "goods_out_id": goodsOutIds,
                "received_by": _RecieveController.text,
                "remarks": _RmarksController.text
              });
              var request = http.MultipartRequest(
                  'POST',
                  Uri.parse(
                      '${RestDatasource().BASE_URL}/api/customer-delivery.store'));
              request.files.add(
                await http.MultipartFile.fromPath(
                  'signature',
                  signatureFile.path,
                  contentType: MediaType('image', 'png'),
                ),
              );
              final response =
                  await http.post(url, headers: headers, body: body);

              if (response.statusCode == 200) {
                if (mounted) {
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Alert"),
                        content: Text("Created Successfully"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed(
                                  HomeScreen.routeName);
                            },
                            child: Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                }
                print('Data posted successfully!');
                print('Response body: ${response.body}');
              } else {
                print(
                    'Failed to post data. Status code: ${response.statusCode}');
                print('Response body: ${response.body}');
              }
            }

            if (expandedStates.isEmpty) {
              expandedStates = List<bool>.filled(snapshot.data!.length, false);
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '$name | $code | $address',
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final delivery = snapshot.data![index];

                        final isSelected =
                            selectedDeliveries.contains(delivery);
                        return GestureDetector(
                          onTap: () => _toggleSelection(delivery),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.green.shade300
                                    : AppConfig.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Tooltip(
                                          message: delivery.invoiceNo,
                                          child: Text(
                                            '${delivery.invoiceNo}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  AppConfig.textCaption3Size,
                                              color: Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Spacer(),
                                        IconButton(
                                            onPressed: () {
                                              setState(() {
                                                expandedStates[index] =
                                                    !expandedStates[index];
                                              });
                                            },
                                            icon: Icon(
                                                Icons.arrow_drop_down_circle))
                                      ],
                                    ),
                                    // const SizedBox(height: 8.0),
                                    // Column(
                                    //   crossAxisAlignment:
                                    //       CrossAxisAlignment.start,
                                    //   children: [
                                    //     Text(
                                    //       '${delivery.details[0].name}',
                                    //       style: TextStyle(
                                    //         fontSize:
                                    //             AppConfig.textCaption3Size,
                                    //         color: Colors.black54,
                                    //       ),
                                    //     ),
                                    //     const SizedBox(height: 4.0),
                                    //     Text(
                                    //       'Qty: ${delivery.details[0].quantity}',
                                    //       style: TextStyle(
                                    //         fontSize:
                                    //             AppConfig.textCaption3Size,
                                    //         color: Colors.black54,
                                    //       ),
                                    //     ),
                                    //   ],
                                    // ),
                                    Visibility(
                                        visible: expandedStates[index],
                                        child: Container(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children:
                                                delivery.details.map((Details) {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Prd: ${Details.name}',
                                                    style: TextStyle(
                                                      fontSize: AppConfig
                                                          .textCaption3Size,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Qty: ${Details.quantity}',
                                                    style: TextStyle(
                                                      fontSize: AppConfig
                                                          .textCaption3Size,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                  Divider(
                                                    color: Colors.grey.shade300,
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
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Received in Good Condition',
                          style: TextStyle(fontSize: 15),
                        ),
                        SizedBox(
                          height: 10.h,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            // textAlign: TextAlign.center,
                            controller: _RecieveController,
                            decoration: InputDecoration(
                              filled: true, fillColor: Colors.white,
                              labelText: 'Received By',
                              labelStyle: TextStyle(fontSize: 14),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide.none),
                              isDense: true,
                              // contentPadding:
                              //     EdgeInsets.symmetric(vertical: 10),
                            ),
                            // style: TextStyle(fontSize: 10),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            // textAlign: TextAlign.center,
                            controller: _RmarksController,
                            decoration: InputDecoration(
                              filled: true, fillColor: Colors.white,
                              labelText: 'Remarks If Any',
                              labelStyle: TextStyle(fontSize: 14),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide.none),
                              isDense: true,
                              // contentPadding:
                              //     EdgeInsets.symmetric(vertical: 10),
                            ),
                            // style: TextStyle(fontSize: 10),
                          ),
                        ),
                        // Row(
                        //   children: [
                        //     Text('Received By'),
                        //     SizedBox(width: 30),
                        //     Expanded(
                        //       child: Padding(
                        //         padding: const EdgeInsets.all(8.0),
                        //         child: TextField(
                        //           textAlign: TextAlign.center,
                        //           controller: _nameController,
                        //           decoration: InputDecoration(
                        //               border: OutlineInputBorder(
                        //                   borderSide: BorderSide()),
                        //               isDense: true,
                        //               contentPadding:
                        //                   EdgeInsets.symmetric(vertical: 10)),
                        //           style: TextStyle(fontSize: 14),
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Signature'),
                                ),
                                Signature(
                                  width: double.infinity,
                                  height: 200,
                                  controller: _signatureController,
                                  backgroundColor: AppConfig.backgroundColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Row(
                        //   crossAxisAlignment: CrossAxisAlignment.start,
                        //   children: [
                        //     Text('Signature'),
                        //     SizedBox(width: 53),
                        //     Column(
                        //       crossAxisAlignment: CrossAxisAlignment.start,
                        //       children: [
                        //         Container(
                        //           decoration: BoxDecoration(
                        //             border: Border.all(),
                        //           ),
                        //           child: Signature(
                        //             width:
                        //                 MediaQuery.of(context).size.width * .64,
                        //             height: MediaQuery.of(context).size.height *
                        //                 .17,
                        //             controller: _signatureController,
                        //             backgroundColor: AppConfig.backgroundColor,
                        //           ),
                        //         ),
                        //         ElevatedButton(
                        //           style: ButtonStyle(
                        //             backgroundColor: WidgetStateProperty.all(
                        //                 AppConfig.colorPrimary),
                        //           ),
                        //           onPressed: () {
                        //             _signatureController.clear();
                        //           },
                        //           child: Icon(
                        //             Icons.refresh,
                        //             color: Colors.white,
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                  // SizedBox(height: 20.h,),
                  GestureDetector(
                    onTap: () {
                      _signatureController.clear();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.refresh,
                          color: AppConfig.colorPrimary,
                          size: 40.sp,
                        ),
                        SizedBox(
                          width: 20.w,
                        )
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all( selectedDeliveries.isEmpty? Colors.grey : AppConfig.colorPrimary),
                          fixedSize: WidgetStateProperty.all(Size(150, 20)),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                        onPressed: selectedDeliveries.isEmpty
                            ? null
                            : () async {
                                postData();
                                // print(AppState().routeId);
                              },
                        child: Text(
                          'SAVE',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Future<List<CustomerDelivery>> fetchCustomerDeliveries() async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_customer_delivery_by_driver?store_id=${AppState().storeId}&user_id=${AppState().userId}&customer_id=$id'));

    if (response.statusCode == 200) {
      // print(AppState().storeId);
      print(id);
      // print(id);

      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success']) {
        return List<CustomerDelivery>.from(jsonResponse['data']
            .map((delivery) => CustomerDelivery.fromJson(delivery)));
      } else {
        throw Exception('Failed to load data');
      }
    } else {
      throw Exception('Failed to load data');
    }
  }
}
