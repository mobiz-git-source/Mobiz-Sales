import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart'as http;
import '../Components/commonwidgets.dart';
import '../Models/Store_model.dart';
import '../Models/appstate.dart';
import '../Models/customerdetails.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'Mapscreen.dart';
import 'customerdetailscreen.dart';

class SchedulePage extends StatefulWidget {
  static const routeName = "/SchedulePage";

  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  var selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();

  CustomerData customer = CustomerData();
  CustomerData customer1 = CustomerData();
  bool _initDone = false;
  bool _nodata = false;
  bool showFields = false;

  @override
  void initState() {
    super.initState();
    getCustomerDetails();
    getCustomerEmergencyDetails();
    fetchStoreDetail() .then((storeDetail) {
      if (storeDetail != null && storeDetail.comapny_id == 5) {
        setState(() {
          showFields = true; // Show fields for company_id 5
        });
      } else {
        setState(() {
          showFields = false; // Hide fields otherwise
        });
      }
      print("SSSSS${storeDetail!.comapny_id}");
      print("Fields$showFields");
    });
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
          'Schedule',
         style: AppConfig.pageTitleStyle,
        ),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = DateTime.now();
                getCustomerDetails();
                getCustomerEmergencyDetails();
              });
            },
            child: Icon(
              Icons.refresh,
              color: AppConfig.backgroundColor,
            ),
          ),
          SizedBox(
            width: 10,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            GestureDetector(
              onLongPress: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2023, 12, 31),
                  lastDate: DateTime(2028, 1, 31),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary:
                          AppConfig.colorPrimary, // header background color
                          onPrimary: Colors.white, // header text color
                          onSurface: AppConfig.colorPrimary, // body text color
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor:
                            Colors.deepPurple, // button text color
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                    getCustomerDetails();
                    getCustomerEmergencyDetails();
                  });
                }
              },
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TableCalendar(
                    firstDay: DateTime(2023, 12, 31),
                    lastDay: DateTime(2028, 1, 31),
                    focusedDay: focusedDate,
                    selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        selectedDate = selectedDay;
                        focusedDate = focusedDay;
                        getCustomerDetails();
                        getCustomerEmergencyDetails();
                      });
                    },
                    calendarFormat: CalendarFormat.week,
                    availableCalendarFormats: const {
                      CalendarFormat.week: 'Week'
                    },
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: AppConfig.colorPrimary,
                        shape: BoxShape.rectangle, // Use BoxShape.rectangle
                        borderRadius:
                        BorderRadius.circular(7), // Allowed with rectangle
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(.3),
                        shape: BoxShape.rectangle, // Use BoxShape.rectangle
                        borderRadius:
                        BorderRadius.circular(7), // Allowed with rectangle
                      ),
                      selectedTextStyle: const TextStyle(color: Colors.white),
                      todayTextStyle: const TextStyle(color: Colors.white),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        color: AppConfig.colorPrimary,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Colors.deepPurple,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Colors.deepPurple,
                      ),
                    ),
                  )),
            ),
            (_initDone && !_nodata)
                ? SizedBox(
              height: SizeConfig.blockSizeVertical * 78,
              child: ListView.separated(
                separatorBuilder: (BuildContext context, int index) =>
                    CommonWidgets.verticalSpace(1),
                itemCount: (customer.data ?? []).length + (customer1.data ?? []).length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  // Combine the data from both lists
                  final combinedData = [...(customer.data ?? []), ...(customer1.data ?? [])];
                  // Return the customer card for the current index
                  return _customersCard(combinedData[index]);
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
    );
  }

  Widget _customersCard(Data data) {
    void _openGoogleMaps(String data) async {
      if (data.isEmpty) {
        Fluttertoast.showToast(
          msg: "Location are not available",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }
      final String googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1&destination=$data';
      if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
      } else {
        throw 'Could not launch $googleMapsUrl';
      }
    }

    void _openMapScreen() async {
      String coordinates = data.location ?? '';

      if (coordinates.isEmpty) {
        Fluttertoast.showToast(
          msg: "Location are not available",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }
      List<String> latLngStr = coordinates.split(', ');
      double latitude = double.parse(latLngStr[0]);
      double longitude = double.parse(latLngStr[1]);
      LatLng selectedLocation = LatLng(latitude, longitude);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(
            initialLocation: selectedLocation,
          ),
        ),
      );
    }

    bool hasEmergency = customer1.data != null && customer1.data!.isNotEmpty;
    return InkWell(
      onTap: () {
        Navigator.of(context)
            .pushNamed(CustomerDetailsScreen.routeName, arguments: {
          'name': data.name!,
          'address': data.address,
          'phone': data.contactNumber,
          'mail': data.email,
          'location': data.location,
          'customerType': '',
          'days': data.creditDays,
          'creditLimit': data.creditLimit,
          'paymentTerms': data.paymentTerms,
          'provinceId': data.provinceId,
          'routeId': data.routeId,
          'trn': data.trn,
          'whatsappNumber': data.whatsappNumber,
          'code': data.code,
          'balance': '',
          'total': '',
          'id': data.id,
        });
      },
      child: Card(
        elevation: 3,
        child: Container(
          width: SizeConfig.blockSizeHorizontal * 90,
          decoration: const BoxDecoration(
            color: AppConfig.backgroundColor,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: FadeInImage(
                      image: const NetworkImage(
                          'https://www.vecteezy.com/vector-art/5337799-icon-image-not-found-vector'),
                      placeholder:
                      const AssetImage('Assets/Images/no_image.jpg'),
                      imageErrorBuilder: (context, error, stackTrace) {
                        return Image.asset('Assets/Images/no_image.jpg',
                            fit: BoxFit.fitWidth);
                      },
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
                CommonWidgets.horizontalSpace(3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: SizeConfig.blockSizeHorizontal * 80,
                      child: Text(
                        (data.name ?? '').toUpperCase(),
                        style: TextStyle(
                            fontSize: AppConfig.paragraphSize,
                            fontWeight: AppConfig.headLineWeight),
                      ),
                    ),
                    SizedBox(
                      width: SizeConfig.blockSizeHorizontal * 70,
                      child: Row(children: [
                        SizedBox(
                          width: SizeConfig.blockSizeHorizontal * 60,
                          child: Text(
                            'Address:${data.address ?? ''}',
                            style:
                            TextStyle(fontSize: AppConfig.textCaption3Size),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            _openGoogleMaps(data.location ?? '');
                            // print('gggggggggggggggggggggggggggggg');
                            // print(AppState().userId);
                          },
                          // _openMapScreen,
                          child: Image.asset(
                            'Assets/Images/vecteezy_google-maps-icon_16716478.png',
                            fit: BoxFit.cover,
                            height: 30,
                          ),
                        ),
                      ]),
                    ),
                    SizedBox(
                      width: SizeConfig.blockSizeHorizontal * 72,
                      child: Row(
                        children: [
                          Text(
                            'Contact:${data.contactNumber}',
                            style:
                            TextStyle(fontSize: AppConfig.textCaption3Size),
                          ),
                          Spacer(),
                          Text(data.visit ?? '')
                        ],
                      ),
                    ),
                    // Visibility(
                    //   visible: hasEmergency,
                    //   child: SizedBox(
                    //     width: SizeConfig.blockSizeHorizontal * 72,
                    //     child: Text(
                    //       'Emergency',
                    //       overflow: TextOverflow.ellipsis, // Shrink text if needed
                    //       style: TextStyle(fontSize: AppConfig.textCaption3Size),
                    //     ),
                    //   ),
                    // ),
                    Visibility(
                      visible: showFields,
                      child: Column(
                        children: [
                          SizedBox(
                            width: SizeConfig.blockSizeHorizontal * 72,
                            child: Text(
                              'Building: ${data.building ?? 'N/A'}',
                              style: TextStyle(fontSize: AppConfig.textCaption3Size),
                            ),
                          ),
                          SizedBox(
                            width: SizeConfig.blockSizeHorizontal * 72,
                            child: Text(
                              'Flat Number: ${data.flatNo ?? 'N/A'}',
                              style: TextStyle(fontSize: AppConfig.textCaption3Size),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<StoreDetail?> fetchStoreDetail() async {
    final url = Uri.parse('${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // print("data:::${data['company_id']}");
        // print(showFields);
        if (data['company_id'] == 5) {
          setState(() {
            showFields = true;
          });
        } else {
          setState(() {
            showFields = false;
          });
        }
        return StoreDetail.fromJson(data);
      } else {
        // Handle error
        print('Failed to fetch data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<void> getCustomerDetails() async {
    RestDatasource api = RestDatasource();

    dynamic resJson = await api.getDetails(
        '/api/get_scheduled_customer_by_user_with_date?date=${DateFormat('yyyy-MM-dd').format(selectedDate)}&store_id=${AppState().storeId}&user_id=${AppState().userId}',
        AppState().token);
    print('Cust $resJson');
    if (resJson['data'] != null && resJson['data'].length > 0) {
      customer = CustomerData.fromJson(resJson);

      setState(() {
        _initDone = true;
        _nodata = false;
      });
    } else {
      setState(() {
        _nodata = true;
        _initDone = true;
      });
    }
  }

  Future<void> getCustomerEmergencyDetails() async {
    RestDatasource api = RestDatasource();

    dynamic resJson = await api.getDetails(
        '/api/get_emargency_scheduled_customer_by_user_with_date?date=${DateFormat('yyyy-MM-dd').format(selectedDate)}&store_id=${AppState().storeId}&user_id=${AppState().userId}',
        AppState().token);
    print('Cust $resJson');
    if (resJson['data'] != null && resJson['data'].length > 0) {
      customer1 = CustomerData.fromJson(resJson);
      customer1.data![0].defaultValue==1;
      setState(() {
        _initDone = true;
        _nodata = false;
      });
    } else {
      setState(() {
        _nodata = true;
        _initDone = true;
      });
    }
  }
}
