import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Models/customerdetails.dart';
import 'package:mobizapp/Pages/customerdetailscreen.dart';
import 'package:mobizapp/Pages/customerregistration.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import '../Components/commonwidgets.dart';
import '../Models/Store_model.dart';
import '../confg/sizeconfig.dart';
import 'Mapscreen.dart';

class CustomersDataScreen extends StatefulWidget {
  static const routeName = "/CustomersScreen";
  static List<Data> loadedCustomerList = [];
  const CustomersDataScreen({super.key});

  @override
  State<CustomersDataScreen> createState() => _CustomersDataScreenState();
}

class _CustomersDataScreenState extends State<CustomersDataScreen> {
  CustomerData customer = CustomerData();
  bool _initDone = false;
  bool _nodata = false;
  List<Data> filteredCustomers = [];
  String searchQuery = '';
  bool _isSearching = false;
  bool showFields = false;

  @override
  void initState() {
    super.initState();
    getCustomerDetails();
    requestLocationPermission();
    fetchStoreDetail().then((storeDetail) {
      if (storeDetail != null && storeDetail.comapny_id == 5) {
        setState(() {
          showFields = true;
        });
      } else {
        setState(() {
          showFields = false;
        });
      }
    });
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
            : const Text(
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
          onPressed: () async {
  final result = await Navigator.pushNamed(
    context,
    CustomerRegistration.routeName,
    arguments: {
      'customerList': customer.data ?? CustomersDataScreen.loadedCustomerList,
    },
  );
  if (result == true) {
    getCustomerDetails(); // 🆕 CHANGED: list fresh ആയി reload ചെയ്യുന്നു
  }
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
                    shrinkWrap: true,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 2),
                    itemCount: (searchQuery.isEmpty
                            ? customer.data!
                            : filteredCustomers)
                        .length,
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
                            ],
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }
// 🆕 PUTHIYA METHOD - class-il add cheyyuka
Future<String> _loadImage(String img) async {
 
  final cacheBuster = DateTime.now().millisecondsSinceEpoch;
  String productUrl = '${RestDatasource().Product_URL}/uploads/customer/$img?v=$cacheBuster';
  String baseUrl = '${RestDatasource().BASE_URL}/uploads/customer/$img?v=$cacheBuster';
  

  try {
    final response = await http
        .head(Uri.parse(productUrl))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return productUrl;
    }
  } catch (e) {}

  try {
    final response = await http
        .head(Uri.parse(baseUrl))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return baseUrl;
    }
  } catch (e) {}
  throw Exception('Image not found');
}
  Widget _customersCard(Data data) {
    void _openMapScreen() async {
      String coordinates = data.location ?? '';

      if (coordinates.isEmpty) {
        Fluttertoast.showToast(
          msg: "Location are not available",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
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
  onTap: () async {
    final result = await Navigator.of(context).pushNamed(CustomerDetailsScreen.routeName, arguments: {
      'name': data.name!,
      'address': data.address,
      'phone': data.contactNumber,
      'mail': data.email,
      'location': data.location,
      'cust_image': data.img,
      'customerType': '',
      'days': data.creditDays,
      'creditLimit': data.creditLimit,
      'paymentTerms': data.paymentTerms,
      'provinceId': data.provinceId,
      'routeId': data.routeId,
      'price_group_id': data.pricegroupId,
      'trn': data.trn,
      'whatsappNumber': data.whatsappNumber,
      'code': data.code,
      'balance': '',
      'total': '',
      'id': data.id,
    });
    if (result == true) {
      getCustomerDetails(); // 🆕 list fresh ആയി reload ചെയ്യുന്നു
    }
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
  child: (data.img != null && data.img!.isNotEmpty)
    ? FutureBuilder<String>(
        future: _loadImage(data.img!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Image.asset('Assets/Images/no_image.jpg', fit: BoxFit.cover);
          } else {
          return Image.network(
  snapshot.data!,
  fit: BoxFit.cover,
  filterQuality: FilterQuality.high,
  errorBuilder: (context, error, stackTrace) {
    return Image.asset('Assets/Images/no_image.jpg', fit: BoxFit.cover);
  },
);
          }
        },
      )
    : Image.asset('Assets/Images/no_image.jpg', fit: BoxFit.cover),
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
        '/api/get_customer?store_id=${AppState().storeId}&route_id=${AppState().routeId}',
        AppState().token);
    print('Cust $resJson');
    if (resJson['data'] != null && resJson['data'].length > 0) {
      customer = CustomerData.fromJson(resJson);
      CustomersDataScreen.loadedCustomerList = customer.data ?? [];

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
