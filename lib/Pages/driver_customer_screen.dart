import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Models/customerdetails.dart';
import 'package:mobizapp/Pages/customerdetailscreen.dart';
import 'package:mobizapp/Pages/customerregistration.dart';
import 'package:mobizapp/Pages/salesscreen.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';

import '../Components/commonwidgets.dart';
import '../confg/sizeconfig.dart';
import 'Driver_customer_detail_screen.dart';
import 'Mapscreen.dart';

class driver_customer_screen extends StatefulWidget {
  static const routeName = "/driver_customer_screen";
  const driver_customer_screen({super.key});

  @override
  State<driver_customer_screen> createState() => _driver_customer_screenState();
}

class _driver_customer_screenState extends State<driver_customer_screen> {
  CustomerData customer = CustomerData();
  bool _initDone = false;
  bool _nodata = false;
  List<Data> filteredCustomers = [];
  String searchQuery = '';
  bool _isSearching = false;
  @override
  void initState() {
    super.initState();
    getCustomerDetails();
    requestLocationPermission();
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      if (await Permission.location.request().isGranted) {
        getCustomerDetails();
      } else {
        Fluttertoast.showToast(
          msg: "Location permission is required to use this feature.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      getCustomerDetails();
    }
  }

  void _searchCustomer(String query) {
    final filteredList = customer.data!.where((customer) {
      final customerName = customer.name?.toLowerCase() ?? '';
      final searchLower = query.toLowerCase();
      return customerName.contains(searchLower);
    }).toList();

    setState(() {
      searchQuery = query;
      filteredCustomers = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimary,
        iconTheme: const IconThemeData(color: AppConfig.backButtonColor),
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  _searchCustomer(query);
                },
                style: const TextStyle(color: Colors.white),
              )
            : const 
           Text(
  'Shops',
  style: AppConfig.pageTitleStyle,
),
        actions: [
          _isSearching
              ? IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      searchQuery = '';
                      filteredCustomers = customer.data!;
                    });
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.search, size: 30),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
          IconButton(
            icon: Icon(
              Icons.add,
              size: 30,
              color: AppConfig.backgroundColor,
            ),
            onPressed: () {
              Navigator.pushNamed(context, CustomerRegistration.routeName);
            },
          ),
          CommonWidgets.horizontalSpace(3),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
          (_initDone && !_nodata)
    ? ListView.separated(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 2),
        itemCount: (searchQuery.isEmpty
                ? customer.data!
                : filteredCustomers)
            .length,
        shrinkWrap: true,
        itemBuilder: (context, index) => _customersCard(
            searchQuery.isEmpty
                ? customer.data![index]
                : filteredCustomers[index]),
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

    return InkWell(
      onTap: () {
        Navigator.of(context)
            .pushNamed(Driver_customer_detail_screen.routeName, arguments: {
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
  margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
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
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(
        width: SizeConfig.blockSizeHorizontal * 60,
        child: Text(
          'Address:${data.address ?? ''}',
          style: TextStyle(fontSize: AppConfig.textCaption3Size),
        ),
      ),
      const Spacer(),
      GestureDetector(
        onTap: _openMapScreen,
        child: Image.asset(
          'Assets/Images/vecteezy_google-maps-icon_16716478.png',
          fit: BoxFit.cover,
          height: 18,
        ),
      )
    ],
  ),
),
                    Text(
                      'Contact:${data.contactNumber}',
                      style: TextStyle(fontSize: AppConfig.textCaption3Size),
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

  Future<void> getCustomerDetails() async {
    RestDatasource api = RestDatasource();

    dynamic resJson = await api.getDetails(
        '/api/get_customer?store_id=${AppState().storeId}&route_id=${AppState().routeId}',
        AppState().token);
    print('Cust $resJson');
    if (resJson['data'] != null && resJson['data'].length > 0) {
      customer = CustomerData.fromJson(resJson);

      setState(() {
        customer = CustomerData.fromJson(resJson);
        filteredCustomers = customer.data!;
        _initDone = true;
      });
    } else {
      setState(() {
        _nodata = true;
        _initDone = true;
      });
    }
  }
}
