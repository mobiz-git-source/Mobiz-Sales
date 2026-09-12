import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart'; // Import mobile_scanner package
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/homepage.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'confg/appconfig.dart';
import 'confg/sizeconfig.dart';

class HomeWater extends StatefulWidget {
  static const routeName = "/tststs";
  const HomeWater({super.key});

  @override
  State<HomeWater> createState() => _HomeWaterState();
}

class _HomeWaterState extends State<HomeWater> {
  List<String> scannedCoupons = [];
  TextEditingController couponController = TextEditingController();
  TextEditingController emptyController = TextEditingController();
  List<String> waterReasons = [];
  bool isLoading = true;
  String couponName = '';
  String productImage = '';
  List<int> reasonIds = [];
  int selectedReasonId = 0;
  List<int> productIds = [];

  void scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (result != null && result is String && result.isNotEmpty) {
      final isValid = await validateCoupon(result);
      if (isValid) {
        setState(() {
          scannedCoupons.add(result);
        });
      } else {
        showError('Invalid coupon. Please scan a valid coupon.');
      }
    }
  }

  Future<bool> validateCoupon(String serialNo) async {
    final url = '${RestDatasource().BASE_URL}/api/water-coupon.check';
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({
      'serial_no': serialNo,
      'store_id': AppState().storeId,
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return true;
        }
      }
    } catch (e) {
      print('Error: $e');
      showError('An error occurred while validating the coupon.');
    }
    return false;
  }

  int _count = 0;

  Future<void> fetchWaterReasons() async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get-water-reason?store_id=${AppState().storeId}'));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['success'] == true) {
        print(response.body);
        setState(() {
          waterReasons = List<String>.from(
              data['data'].map((item) => item['reasone'] ?? ''));
          isLoading = false;
          reasonIds =
              List<int>.from(data['data'].map((item) => item['id'] ?? 0));
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load data');
    }
  }

  Future<void> postCoupon(String serialNo) async {
    if (scannedCoupons.contains(serialNo)) {
      showError('This coupon has already been scanned.');
      return;
    }
    final url = '${RestDatasource().BASE_URL}/api/water-coupon.check';
    final headers = {'Content-Type': 'application/json'};
    final body =
        json.encode({'serial_no': serialNo, 'store_id': AppState().storeId});

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final String name = responseData['data']['name'];
          final int id = responseData['data']['id'];
          final String proImage = responseData['data']['pro_image'];

          setState(() {
            productIds.add(id);
            couponName = name;
            productImage = proImage;
            scannedCoupons.add(serialNo);
            _count = scannedCoupons.length;
            print(productIds);
          });
        } else {
          showError('Failed to post the coupon.');
        }
      } else {
        final errorMessage = _getErrorMessage(response.body);
        showError(errorMessage);
      }
    } catch (e) {
      print('Error: $e');
      showError(
          'An error occurred while posting the coupon. Please try again.');
    }
  }

  Future<void> postWaterSale() async {
    if (scannedCoupons.isEmpty || _count.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Please add scanned coupons and specify the number of empty bottles."),
        ),
      );
      return;
    }

    final url = Uri.parse("${RestDatasource().BASE_URL}/api/water-sale.store");

    Map<String, String> body = {
      "store_id": AppState().storeId.toString(),
      "reason_id": selectedReasonId.toString(),
      "van_id": AppState().vanId.toString(),
      "user_id": AppState().userId.toString(),
      "no_of_empty_bottile": _count.toString(),
    };

    for (int i = 0; i < scannedCoupons.length; i++) {
      body['item_id[$i]'] = scannedCoupons[i];
      print(scannedCoupons[i]);
    }

    for (int i = 0; i < productIds.length; i++) {
      body['product_id[$i]'] = productIds[i].toString();
      print(productIds[i].toString());
    }

    // Sending the request
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );
    print(body);
    print(response.body);
    if (response.statusCode == 200) {
      print("Body: $body");
      print(
        _count.toString(),
      );
      print(
        selectedReasonId.toString(),
      );
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Success"),
              content: const Text("Data Inserted Successfully!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                        context, HomeScreen.routeName);
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
        setState(() {
          scannedCoupons.clear();
          _count = 0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'] ?? "Unknown error")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Failed to post data. Status code: ${response.statusCode}")),
      );
    }
  }

  String _getErrorMessage(String responseBody) {
    try {
      final errorData = json.decode(responseBody);
      return errorData['error'] ??
          'Failed to post coupon';
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void initState() {
    super.initState();
    fetchWaterReasons();
    _count = scannedCoupons.length;
    // emptyController.text = _count.toString();
  }

  @override
  void dispose() {
    couponController.dispose();
    emptyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: AppConfig.colorPrimary,
       title: const Text(
  'Water',
  style: AppConfig.pageTitleStyle,
),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20,
            ),
            // Row(
            //   children: [
            //     Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 30),
            //       child: GestureDetector(
            //         onTap: scanBarcode, // Call scanBarcode on icon tap
            //         child: const Icon(Icons.camera_alt_outlined, size: 30),
            //       ),
            //     ),
            //     SizedBox(width: MediaQuery.of(context).size.width * .2),
            //     const Text('Scan Coupon'),
            //   ],
            // ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Coupon Number'),
                ],
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: MediaQuery.of(context).size.width * .65,
              height: 65,
              child: TextFormField(
                controller: couponController,
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  helperText: '',
                  suffixIcon: GestureDetector(
                    onTap: () {
                      scanBarcode();
                    },
                    child: Icon(
                      Icons.barcode_reader, // Replace with the icon you prefer
                      size: 24,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  labelText: '',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (value) {
                  if (value.isNotEmpty) {
                    postCoupon(
                        value); // Call the post function with the coupon data
                    couponController
                        .clear(); // Clear the input after submission
                  }
                },
              ),
            ),
            if (scannedCoupons.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Card(
                  elevation: 3,
                  child: Container(
                    width: SizeConfig.blockSizeHorizontal * 90,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent),
                      color: AppConfig.backgroundColor,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    child: ListTile(
                      leading: Image.network(
                          '${RestDatasource().Product_URL}/uploads/product/$productImage'), // Replace with the correct URL,
                      title: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.start, // Align to start
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // Align vertically if needed
                        children: [
                          Text(
                            "Qty: ${scannedCoupons.length}",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w800),
                          ),
                          // SizedBox(width: 5), // Optional: Space between the texts
                        ],
                      ),
                      trailing: Text(
                        "${couponName}",
                        style: TextStyle(color: Colors.black, fontSize: 15),
                      ), // Removes trailing space
                    ),
                  ),
                ),
              ),
              // Row(
              //   children: [
              //     Image.asset(
              //       'Assets/Images/Water.png',
              //       height: 100,
              //       width: 100,
              //     ),
              //     SizedBox(width: AppConfig.textHeadlineSize),
              //     Text(
              //       "${scannedCoupons.length} ${couponName}",
              //       style: TextStyle(color: Colors.black, fontSize: 30),
              //     ),
              //   ],
              // ),
              SizedBox(
                height: 20,
              ),
              Container(
                height: 20,
                width: 150,
                decoration: BoxDecoration(color: AppConfig.colorPrimary),
                child: const Center(
                  child: Text("Scanned Coupons",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                itemCount: scannedCoupons.length,
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: MediaQuery.of(context).size.width * .65,
                      constraints:
                          const BoxConstraints(minHeight: 60, maxHeight: 200),
                      child: TextFormField(
                        controller:
                            TextEditingController(text: scannedCoupons[index]),
                        maxLines: null,
                        decoration: InputDecoration(
                          helperText: '',
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: AppConfig.colorPrimary),
                          ),
                          labelText: '${index + 1}.',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                scannedCoupons.removeAt(index);
                                _count = scannedCoupons.length;
                              });
                            },
                          ),
                        ),
                        readOnly: true,
                      ),
                    ),
                  );
                },
              ),
            ],

            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Empty bottles collected'),
                ],
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Minus Button
                Container(
                  height: 44,
                  width: 65,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                      backgroundColor:
                          WidgetStateProperty.all(AppConfig.colorPrimary),
                    ),
                    onPressed: () {
                      setState(() {
                        if (_count > 0) {
                          _count--; // Decrement value
                          onCountDecreased();
                          // emptyController.text =
                          //     _count.toString(); // Update controller
                        }
                      });
                      // print(scannedCoupons.length);
                    },
                    child: Icon(CupertinoIcons.minus, color: Colors.white),
                  ),
                ),
                // Counter Display
                Container(
                  width: MediaQuery.of(context).size.width * .12,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: _count.toString()),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppConfig.colorPrimary),
                      ),
                      border: OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.center,
                    readOnly: true,
                    // Prevent direct editing
                  ),
                ),
                // Plus Button
                Container(
                  height: 44,
                  width: 65,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                      backgroundColor:
                          WidgetStateProperty.all(AppConfig.colorPrimary),
                    ),
                    onPressed: () {
                      setState(() {
                        _count++; // Increment value
                        // emptyController.text =
                        //     _count.toString(); // Update controller
                      });
                    },
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            // if (_count != scannedCoupons.length && !isLoading)
            //   Container(
            //     padding: EdgeInsets.symmetric(vertical: 10, horizontal: 80),
            //     child: DropdownButtonFormField<String>(
            //       value: waterReasons.isNotEmpty ? waterReasons[0] : null,
            //       decoration: InputDecoration(
            //         isDense: true,
            //         contentPadding:
            //             EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            //         focusedBorder: OutlineInputBorder(
            //           borderSide: BorderSide(color: AppConfig.colorPrimary),
            //         ),
            //         border: OutlineInputBorder(),
            //       ),
            //       items: waterReasons.map((reason) {
            //         return DropdownMenuItem<String>(
            //           value: reason,
            //           child: Text(reason),
            //         );
            //       }).toList(),
            //       onChanged: (value) {
            //         setState(() {
            //           int selectedIndex = waterReasons.indexOf(value ?? '');
            //           // _count = waterReasons.indexOf(value ?? '') + 1;
            //           _dropdownCount = selectedIndex + 1; // Track dropdown selection
            //           _count = _dropdownCount!;
            //           selectedReasonId = reasonIds[selectedIndex];
            //         });
            //       },
            //     ),
            //   ),
            if (selectedReason != null && selectedReason!.isNotEmpty)
              Text(
                'Reason: $selectedReason',
                style: TextStyle(fontSize: 15),
              ),
            // Show Loading Indicator if data is loading
            if (isLoading) CircularProgressIndicator(),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.colorPrimary,
                fixedSize: const Size(190, 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: () {
                postWaterSale();
              },
              child: Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? selectedReason;
  void onCountDecreased() {
    // Fetch water reasons when the count decreases
    fetchWaterReasons();

    // Here you can trigger your logic for showing the dropdown
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Reason'),
          content: isLoading
              ? CircularProgressIndicator()
              : DropdownButton<String>(
                  value: selectedReason,
                  items: waterReasons.map((String reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedReason = newValue;
                      selectedReasonId = reasonIds[waterReasons
                          .indexOf(newValue!)]; // Update the selected reason ID
                    });
                    Navigator.of(context).pop();
                  },
                  hint: Text('Select a reason'),
                ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _scanned = false; // Flag to prevent multiple pops

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Scan Barcode",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppConfig.colorPrimary,
      ),
      body: MobileScanner(
        onDetect: (barcode) {
          if (!_scanned) {
            final String? code = barcode.barcodes.first.rawValue;
            if (code != null) {
              setState(() {
                _scanned = true; // Prevent further pops
              });
              Navigator.pop(context, code); // Return the scanned code
            }
          }
        },
      ),
    );
  }
}
