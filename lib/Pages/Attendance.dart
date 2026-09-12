import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../Components/commonwidgets.dart';
import '../Models/appstate.dart';
import '../Models/attendance_model.dart';
import '../Utilities/rest_ds.dart';
import '../Utilities/date_helper.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'homepage.dart';

class Attendance extends StatefulWidget {
  static const routeName = "/Attendance";
  const Attendance({super.key});

  @override
  State<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  Map<String, dynamic>? checkInDetails;
  Map<String, dynamic>? odometerData = {};
  bool isLoading = true;
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
 String formattedTime = DateFormat('hh:mm a').format(DateTime.now());
  String formattedDate = DateHelper.displayFromDateTime(DateTime.now());
  late Future<ApiResponse> futureApiResponse;
  String _containerText = '';
  String _containerText1 = '';
  String lastOdometerOut = '';
  bool _isCheckedIn = false;

  @override
  void initState() {
    super.initState();
    fetchData();
    _getOdometerReading();

    futureApiResponse = fetchCheckInOutData(
        AppState().vanId!, AppState().storeId!, AppState().userId!);
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
        formattedTime = DateFormat('hh:mm a').format(_currentTime);
      });
    });
  }

 void fetchData() async {
  try {
    final data = await fetchCheckInDetails();

    setState(() {
      if (data['data'] is List) {
        // No check-in data found
        checkInDetails = null;
      } else {
        checkInDetails = data['data'] as Map<String, dynamic>;
      }
    });
  } catch (e) {
    print('Error fetching data: $e');
    setState(() {
      checkInDetails = null;
    });
  }
}
  TextEditingController remarksController = TextEditingController();

  void _showDialog1() {
    TextEditingController _textFieldController = TextEditingController();
    final double minOdometer =
        double.parse(checkInDetails!['check_in_odometer'] ?? '0');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Text'),
          content: TextField(
            keyboardType: TextInputType.number,
            controller: _textFieldController,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                double enteredValue =
                    double.tryParse(_textFieldController.text) ?? 0.0;
                if (enteredValue < minOdometer) {
                  // Show error message if entered value is less than minOdometer
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Value must be greater than or equal to $minOdometer')),
                  );
                } else {
                  setState(() {
                    _containerText1 = _textFieldController.text;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getOdometerReading() async {
    Map<String, dynamic>? data = await fetchOdometerReading();

    setState(() {
      odometerData = data;
      isLoading = false; // Stop loading after data is fetched
    });

    if (odometerData != null) {
      print('ID: ${odometerData!['id']}');
      print('Last Odometer Reading: ${odometerData!['last_odometer_reading']}');
    } else {
      print('Failed to fetch data.');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
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
      title: const Text(
  'Attendance',
  style: AppConfig.pageTitleStyle,
),
      ),
      body: Center(
        child: FutureBuilder<ApiResponse>(
          future: futureApiResponse,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Shimmer.fromColors(
                baseColor: AppConfig.buttonDeactiveColor.withOpacity(0.1),
                highlightColor: AppConfig.backButtonColor,
                child: Center(
                  child: Column(
                    children: [
                      CommonWidgets.loadingContainers(
                          height: SizeConfig.blockSizeVertical * 30,
                          width: SizeConfig.blockSizeHorizontal * 90),
                      CommonWidgets.loadingContainers(
                          height: SizeConfig.blockSizeVertical * 30,
                          width: SizeConfig.blockSizeHorizontal * 90),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            } else if (snapshot.hasData) {
              void _showDialog() {
                TextEditingController _textFieldController =
                    TextEditingController();

                showDialog(
                  context: context,
                  builder: (context) {
                    final double minOdometer = odometerData != null && odometerData!['last_odometer_reading'] != null
                        ? double.tryParse(odometerData!['last_odometer_reading'].toString()) ?? 0.0
                        : 0.0;


                    // Remove print statement if no longer needed
                    // print(checkInDetails!['last_odometer_out']);

                    return AlertDialog(
                      title: Text('Enter Text'),
                      content: TextField(
                        keyboardType: TextInputType.number,
                        controller: _textFieldController,
                        decoration: InputDecoration(
                          hintText: 'Enter value',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            double enteredValue =
                                double.tryParse(_textFieldController.text) ??
                                    0.0;

                            if (_textFieldController.text.isEmpty ||
                                (enteredValue < minOdometer)) {
                              // Show error message if entered value is less than minOdometer
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Value must be greater than or equal to $minOdometer')),
                              );
                            } else {
                              setState(() {
                                _containerText = _textFieldController.text;
                              });
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }

              Future<void> checkIn() async {
                final url = Uri.parse(
                    '${RestDatasource().BASE_URL}/api/check-in.store');
                final headers = {'Content-Type': 'application/json'};
                final body = jsonEncode({
                  'store_id': AppState().storeId,
                  'van_id': AppState().vanId,
                  'user_id': AppState().userId,
                  'last_odometer_in': snapshot.data!.data.lastOdometerIn,
                  'chek_in_time': formattedTime,
                  'check_in_odometer': _containerText,
                  'remarks': remarksController.text
                });

                final response =
                    await http.post(url, headers: headers, body: body);
                print(jsonEncode(body));
                if (response.statusCode == 200) {
                  await fetchOdometerReading();
                  remarksController.clear();
                  print('Check-in successful!');
                } else {
                  print('Failed to check-in: ${response.statusCode}');
                  print('Response body: ${response.body}');
                }
              }

              Future<void> _checkIn() async {
                await checkIn();
                setState(() {
                  fetchData();
                  _isCheckedIn = true;
                });
              }

              Future<void> checkout() async {
                setState(() {
                  _isCheckedIn = true;
                });
                final url = Uri.parse(
                    '${RestDatasource().BASE_URL}/api/check-out.store');
                final headers = {'Content-Type': 'application/json'};
                final body = jsonEncode({
                  'id': checkInDetails!['id'] ?? '',
                  'sheduled': AppState().storeId,
                  'visited': AppState().vanId,
                  'not_visied': AppState().userId,
                  'visit_pending': snapshot.data!.data.pending,
                  'check_out_time': formattedTime,
                  'check_out_odo_meter': _containerText1,
                  'remarks': remarksController.text
                });

                final response =
                    await http.post(url, headers: headers, body: body);

                if (response.statusCode == 200) {
                  print(jsonEncode(body));
                  if (mounted) {
                    CommonWidgets.showDialogueBox(
                            context: context,
                            title: "",
                            msg: "Data Inserted Successfully")
                        .then((value) =>
                            Navigator.pushNamed(context, HomeScreen.routeName));
                  }
                  remarksController.clear();
                  print('Check-out successful!');
                } else {
                  print('Failed to check-in: ${response.statusCode}');
                  print('Response body: ${response.body}');
                }
              }

              Future<void> _checkOut() async {
                await checkout();
                setState(() {
                  _isCheckedIn = false;
                });
              }

// if(checkInDetails == null){_isCheckedIn = false;}
              // int id = checkInDetails!['id'];
              checkInDetails == null ||
                      checkInDetails != null &&
                          checkInDetails!['check_out'] == 1
                  ? _isCheckedIn = false
                  : _isCheckedIn = true;
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Center(
                      //   child: Container(
                      //     width: 120,
                      //     height: 120,
                      //     child: Image.network(
                      //         'https://static.vecteezy.com/system/resources/previews/005/337/799/original/icon-image-not-found-free-vector.jpg'),
                      //   ),
                      // ),
                      // SizedBox(
                      //   height: 10,
                      // ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Hello, ${AppState().name ?? ''}",
                              style: AppConfig.pageTitleStyle,
                            ),
                          ],
                        ),
                      ),
                      AppState().rolId == 5
                          ? SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(left: 30.0, top: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text("Van",
                                      style:
                                          TextStyle(fontWeight: FontWeight.w500)),
                                  Text(
                                    " ${snapshot.data!.data.van}",
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                      // AppState().rolId == 5
                      //     ? SizedBox.shrink()
                      //     :
                      Padding(
                        padding: const EdgeInsets.only(left: 30.0, top: 12),
                        child:isLoading?
                            CircularProgressIndicator():
                        Row(
                          children: [
                            Text(
                              'Last Odometer Reading: ${odometerData != null ? (odometerData!['last_odometer_reading'] ?? 'N/A') : 'N/A'}',
                            ),
                          ],
                        )
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.only(left: 30.0, top: 12),
                      //   child: Text(
                      //       "Scheduled ${snapshot.data!.data.sheduled} | Visited ${snapshot.data!.data.vistCustomer} | Not Visited ${snapshot.data!.data.nonVistCustomer} | Pending ${snapshot.data!.data.pending}",
                      //       style: TextStyle(fontWeight: FontWeight.w500)),
                      // ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30.0, top: 12),
                        child: Row(
                          children: [
                            Text(
                              "Current Status: ",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              checkInDetails != null &&
                                      checkInDetails!['check_out'] != null &&
                                      checkInDetails!['check_out'] != 1
                                  ? "Check In"
                                  : "Check Out",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 310,
                            height: 50,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppConfig.colorPrimary),
                            child: Center(
                                child: Text(
                              "$formattedDate",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppConfig.backgroundColor),
                            )),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 100,
                            width: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: _isCheckedIn
                                  ? Colors.lightBlueAccent.shade700
                                  : Colors.lightBlueAccent,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text('Check-in'),
                                Text(
                                  _isCheckedIn
                                      ? checkInDetails == null
                                          ? ' '
                                          : '${checkInDetails!['chek_in_time']}'
                                      : formattedTime,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Container(
                            height: 100,
                            width: 150,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: _isCheckedIn
                                    ? Colors.lightBlueAccent
                                    : Colors.lightBlueAccent.shade700),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text('Check-out'),
                                Text(
                                  _isCheckedIn ? formattedTime : '',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      // AppState().rolId == 5
                      //     ? SizedBox.shrink()
                      //     :
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _isCheckedIn ? null : _showDialog();
                            },
                            child: Container(
                              height: 100,
                              width: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: _isCheckedIn
                                    ? Colors.lightBlueAccent.shade700
                                    : Colors.lightBlueAccent,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text('Odometer'),
                                  Container(
                                    width: 80,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _isCheckedIn
                                          ? Colors.lightBlueAccent.shade700
                                          : AppConfig.backgroundColor,
                                      borderRadius: BorderRadius.circular(2),
                                      border: _isCheckedIn ? null : Border.all(),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _isCheckedIn
                                            ? checkInDetails == null
                                                ? ' '
                                                : '${checkInDetails!['check_in_odometer']}'
                                            : _containerText,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              _isCheckedIn ? _showDialog1() : null;
                            },
                            child: Container(
                              height: 100,
                              width: 150,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: _isCheckedIn
                                      ? Colors.lightBlueAccent
                                      : Colors.lightBlueAccent.shade700),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text('Odometer'),
                                  Container(
                                    width: 80,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: _isCheckedIn
                                          ? AppConfig.backgroundColor
                                          : Colors.lightBlueAccent.shade700,
                                      // border:
                                      //     _isCheckedIn ? Border.all() : null,
                                    ),
                                    child: Center(
                                        child: Text(
                                      _containerText1,
                                      style:
                                          TextStyle(fontWeight: FontWeight.bold),
                                    )),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      // AppState().rolId == 5
                      //     ? SizedBox.shrink()
                      //     :
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: TextField(
                          controller: remarksController,
                          decoration: InputDecoration(
                            hintText: 'Add Remarks',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(5))
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed:
                                // AppState().rolId == 5
                                //     ? _isCheckedIn
                                //         ? null
                                //         : _checkIn
                                //     :
                                _containerText == ''
                                    ? null
                                    : _isCheckedIn
                                        ? null
                                        : _checkIn,
                            child: Text(
                              'Check in',
                              style: TextStyle(color: AppConfig.backgroundColor),
                            ),
                            style: ButtonStyle(
                              shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              fixedSize:
                                  const WidgetStatePropertyAll(Size(150, 0)),
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return Colors
                                        .grey; // Color when button is disabled
                                  }
                                  return AppConfig
                                      .colorPrimary; // Color when button is enabled
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          ElevatedButton(
                            onPressed:
                                // AppState().rolId == 5
                                //     ? _isCheckedIn
                                //         ? _checkOut
                                //         : null
                                //     :
                                _containerText1 == ''
                                    ? null
                                    : _isCheckedIn
                                        ? _checkOut
                                        : null,
                            // _isCheckedIn ? _checkOut : null,
                            child: Text(
                              'Check out',
                              style: TextStyle(color: AppConfig.backgroundColor),
                            ),
                            style: ButtonStyle(
                              fixedSize:
                                  const WidgetStatePropertyAll(Size(150, 0)),
                              shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return Colors.grey;
                                  }
                                  return AppConfig.colorPrimary;
                                },
                              ),
                  
                              // Set minimum width and height
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return Text('No data');
            }
          },
        ),
      ),
    );
  }

  Future<ApiResponse> fetchCheckInOutData(
      int vanId, int storeId, int userId) async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_today_check_in_and_out?van_id=$vanId&store_id=$storeId&user_id=$userId'));

    if (response.statusCode == 200) {
      return ApiResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map<String, dynamic>> fetchCheckInDetails() async {
    final response = await http.get(Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_today_check_in_detail?van_id=${AppState().vanId}&store_id=${AppState().storeId}&user_id=${AppState().userId}'));

    if (response.statusCode == 200) {
      print(response.request);
      print(response.body);
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map<String, dynamic>?> fetchOdometerReading() async {
    final String url =
        '${RestDatasource().BASE_URL}/api/getLastOdometerReading?store_id=${AppState().storeId}&user_id=${AppState().userId}&van_id=${AppState().vanId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print(response.request);
        final jsonData = json.decode(response.body);
        // odometerData = json.decode(response.body);
        if (jsonData['success']) {
          setState(() {
            odometerData = jsonData['data'];
          });
          return jsonData['data']; // Return the 'data' map directly
        } else {
          print('Error: ${jsonData['message']}');
          return null;
        }
      } else {
        print('Error: Server responded with ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}