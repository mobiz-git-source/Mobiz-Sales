import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mobizapp/Components/commonwidgets.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/CustomeSOA.dart';
import 'package:mobizapp/Pages/CustomerStock.dart';
import 'package:mobizapp/Pages/CustomerVisit.dart';
import 'package:mobizapp/Pages/Quotation/QuotatioCustomerScreen.dart';
import 'package:mobizapp/Pages/customerorderdetail.dart';
import 'package:mobizapp/Pages/customerregistration.dart';
import 'package:mobizapp/Pages/paymentcollection.dart';
import 'package:mobizapp/Pages/saleinvoices.dart';
import 'package:mobizapp/Pages/salesscreen.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'package:mobizapp/confg/sizeconfig.dart';
import 'package:mobizapp/vanstockselactpro_tst.dart';
import 'package:shimmer/shimmer.dart';

import '../Utilities/rest_ds.dart';
import 'Copy/Copy.dart';
import 'CustomerWater.dart';
import 'Total_sales.dart';
import 'customerreturndetails.dart';

class CustomerDetailsScreen extends StatefulWidget {
  static const routeName = "/customerdetailsscreen";
  const CustomerDetailsScreen({
    super.key,
  });

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  @override
  Timer? _timer;
  bool _isFirstLoad = true;
  bool _isArgsLoaded = false;


  void initState() {
    // TODO: implement initState
    super.initState();
    // fetchData();
    _fetchData();
    fetchCustomerIcons();
    // _timer = Timer.periodic(Duration(seconds: 10), (Timer t) => fetchData());
  }

  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isArgsLoaded) {
      final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        name = args['name'];
        address = args['address'];
        phone = args['phone'];
        location = args['location'];
        whatsappNumber = args['whatsappNumber'];
        customerType = args['customerType'];
        creditDays = args['days'];
        creditBalance = args['balance'];
        totalOutstanding = args['total'];
        trn = args['trn'];
        img = args['cust_image'];
        paymentTerms = args['paymentTerms'];
        provinceId = args['provinceId'];
        routeId = args['routeId'];
        creditLimit = args['creditLimit'];
        email = args['mail'];
        id = args['id']; // ✅ NOW AVAILABLE
        code = args['code'];
        pricegroupId = args['price_group_id'];

        fetchData();          // ✅ SAFE
        fetchCustomerIcons(); // optional
        _fetchData();
        _isArgsLoaded = true;
      }
    }
  }

  bool _showButton = false;
  String _message = "";
  String _data = '';
  String? name;
  String? address;
  String? email;
  String? building;
  String? flat_no;
  String? phone;
  String? whatsappNumber;
  String? customerType;
  String? location;
  int? provinceId;
  int? routeId;
  int? pricegroupId;
  int? id;
  String? img;
  String? code;
  String? trn;
  int? creditDays;
  String? creditBalance;
  String? totalOutstanding;
  String? paymentTerms;
  int? creditLimit;
  List<List<dynamic>> paginatedIcons = [];
  List<dynamic> appIcons = [];

  void _showSnackBar(BuildContext context) {
    final snackBar = SnackBar(
      content: Text(
          'Pending Offload request found, Please cancel or approve to Proceed'),
      action: SnackBarAction(
        label: '',
        onPressed: () {},
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> fetchCustomerIcons() async {
    final response = await http.get(Uri.parse(
        'http://68.183.92.8:3699/api/store_app_icons_customer?store_id=${AppState().storeId}'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        // Extracting the values of the `success` map
        final successData = data['success'] as Map<String, dynamic>? ?? {};

        // Flatten the map into a list of values
        appIcons = successData.values.map((e) => e).toList();

        // Paginate the icons
        paginatedIcons = _paginateList(appIcons, 9);
      });
    } else {
      throw Exception('Failed to load app icons');
    }
  }

  List<List<dynamic>> _paginateList(List<dynamic> list, int chunkSize) {
    List<List<dynamic>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(
        i,
        i + chunkSize > list.length ? list.length : i + chunkSize,
      ));
    }
    return chunks;
  }

  IconData? getIconData(String? iconName) {
    if (iconName == null) return null;

    switch (iconName) {
      case 'person_add':
        return Icons.person_add;
      case 'settings_suggest':
        return Icons.settings_suggest;
      case 'point_of_sale':
        return Icons.point_of_sale;
      case 'point_of_sale_sharp':
        return Icons.point_of_sale_sharp;
      case 'inventory':
        return Icons.inventory;
      case 'payments':
        return Icons.payments;
      case 'storefront_rounded':
        return Icons.storefront_rounded;
      case 'bar_chart':
        return Icons.bar_chart;
      case 'pie_chart':
        return Icons.pie_chart;
      case 'local_mall':
        return Icons.local_mall;
      case 'water_drop':
        return Icons.water_drop;
        case 'quora':
        return Icons.quora;
      default:
        return Icons.help;
    }
  }

  String get formattedOutstanding {
    if (_data == null || _data!.isEmpty || _data == '[]') {
      return '--';
    }

    final value = double.tryParse(_data!);
    if (value == null) {
      return _data!;
    }

    return value.toStringAsFixed(AppState().noOfDecimals ?? 2);
  }

  String get creditBalanceText {
    if (_data == null || _data!.isEmpty || creditLimit == null) {
      return '--';
    }

    final outstanding = double.tryParse(_data!);
    if (outstanding == null) {
      return '--';
    }

    final balance = outstanding - creditLimit!;
    return balance.toStringAsFixed(AppState().noOfDecimals ?? 2);
  }



  @override
  Widget build(BuildContext context) {


    // print("uggug$img");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimary,
        title: const Text(
          'Customers',
          style: TextStyle(color: AppConfig.backgroundColor),
        ),
        iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (name ?? "").toUpperCase(),
                style: TextStyle(
                    fontSize: AppConfig.headLineSize,
                    fontWeight: AppConfig.headLineWeight),
              ),
              Row(
                children: [
                  SizedBox(
                    width: SizeConfig.blockSizeHorizontal * 35,
                    height: SizeConfig.blockSizeVertical * 20,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: FadeInImage(
                        image: NetworkImage(
                            'http://68.183.92.8:3696/uploads/customer/cust_image/$img'),
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
                  CommonWidgets.horizontalSpace(2),
                  Container(
                    constraints: BoxConstraints(
                      minHeight: SizeConfig.blockSizeVertical * 17,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CommonWidgets.verticalSpace(1),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.grey,
                            ),
                            SizedBox(
                                width: SizeConfig.blockSizeHorizontal * 40,
                                child: Text(address ?? '')),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              color: Colors.grey,
                            ),
                            SizedBox(
                              width: SizeConfig.blockSizeHorizontal * 40,
                              child: Text(phone ?? ''),
                            )
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.mail,
                              color: Colors.grey,
                            ),
                            SizedBox(
                              width: SizeConfig.blockSizeHorizontal * 40,
                              child: Text(email ?? ''),
                            )
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
              Row(
                children: [
                  Text(
                    'Customer Type: $paymentTerms',
                    style: TextStyle(
                        fontWeight: AppConfig.headLineWeight,
                        color: Colors.black.withOpacity(0.7)),
                  ),
                  CommonWidgets.horizontalSpace(2),
                  Text(
                    customerType ?? '',
                    style: TextStyle(fontWeight: AppConfig.headLineWeight),
                  ),
                ],
              ),
              CommonWidgets.verticalSpace(2),
              Row(
                children: [
                  Text(
                    'Credit Days:',
                    style: TextStyle(
                        fontWeight: AppConfig.headLineWeight,
                        color: Colors.black.withOpacity(0.7)),
                  ),
                  CommonWidgets.horizontalSpace(2),
                  Text(
                    creditDays.toString(),
                    style: TextStyle(fontWeight: AppConfig.headLineWeight),
                  ),
                ],
              ),
              CommonWidgets.verticalSpace(2),
              Row(
                children: [
                  Text(
                    'Credit Limit:',
                    style: TextStyle(
                        fontWeight: AppConfig.headLineWeight,
                        color: Colors.black.withOpacity(0.7)),
                  ),
                  CommonWidgets.horizontalSpace(2),
                  Text(
                    creditLimit.toString(),
                    style: TextStyle(fontWeight: AppConfig.headLineWeight),
                  ),
                  CommonWidgets.horizontalSpace(2),
                  Text(
                    'Credit Balance: $creditBalanceText',
                    style: TextStyle(
                      fontWeight: AppConfig.headLineWeight,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),

                ],
              ),
              CommonWidgets.verticalSpace(2),
              Row(
                children: [
                  Text(
                    'Total Outstanding: $formattedOutstanding',
                    style: TextStyle(
                      fontWeight: AppConfig.headLineWeight,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),

                  CommonWidgets.horizontalSpace(2),
                  Text(
                    totalOutstanding ?? '',
                    style: TextStyle(fontWeight: AppConfig.headLineWeight),
                  ),
                ],
              ),
              CommonWidgets.verticalSpace(2),
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                child: paginatedIcons.isNotEmpty
                    ? PageView.builder(
                        itemCount: paginatedIcons.length,
                        itemBuilder: (context, pageIndex) {
                          final pageData = paginatedIcons[pageIndex];
                          return SingleChildScrollView(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 13,
                                  childAspectRatio: .95,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: pageData.length,
                                itemBuilder: (context, index) {
                                  final iconData = pageData[index];
                                  final iconList =
                                      iconData['icon'] as List<dynamic>?;
                                  final firstIconObject =
                                      iconList != null && iconList.isNotEmpty
                                          ? iconList[0]
                                          : null;

                                  final iconName = firstIconObject != null
                                      ? firstIconObject['icon'] as String?
                                      : null;
                                  final name = firstIconObject != null
                                      ? firstIconObject['name'] as String?
                                      : 'Unknown';
                                  final url = firstIconObject != null
                                      ? firstIconObject['url'] as String?
                                      : '';

                                  return _iconButtons(
                                    title: name ?? 'Unknown',
                                    routeName: url ?? '',
                                    icon: getIconData(iconName),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(35.0),
                            child: Column(
                              children: [
                                Expanded(
                                  child: GridView.builder(
                                    scrollDirection: Axis.vertical,
                                    shrinkWrap: true,
                                    physics: BouncingScrollPhysics(),
                                    itemCount: 12,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisExtent: 120,
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 30,
                                    ),
                                    itemBuilder: (context, index) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.grey.shade200,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                // PageView(
                //   children:[
                //   Column(
                //     children: [
                //       Row(
                //           mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                //         InkWell(
                //             onTap: () {
                //               Navigator.pushNamed(
                //                   context, CustomerRegistration.routeName,
                //                   arguments: {
                //                     'name': name,
                //                     'address': address,
                //                     'building': building,
                //                     'flat_no': flat_no,
                //                     'phone': phone,
                //                     'whatsappNumber': whatsappNumber,
                //                     'email': email,
                //                     'location': location,
                //                     'payment_terms': customerType,
                //                     'credit_days': creditDays,
                //                     'credit_limit': creditLimit,
                //                     'paymentTerms': paymentTerms,
                //                     'trn': trn,
                //                     'cust_image':img,
                //                     'code': code,
                //                     'provinceId': provinceId,
                //                     'routeId': routeId,
                //                     'id': id,
                //                   });
                //             },
                //             child: _iconButtons(icon: Icons.person_add, title: 'Edit')),
                //         GestureDetector(
                //             onTap: () {
                //               Navigator.pushNamed(context, SOA.routeName, arguments: {
                //                 'customerId': id,
                //                 'name': name,
                //                 'address': address,
                //                 'code': code,
                //                 'paymentTerms': paymentTerms
                //               });
                //             },
                //             child: _iconButtons(
                //                 icon: Icons.settings_suggest, title: 'SOA')),
                //         InkWell(
                //             onTap: () {
                //               _showButton
                //                   ? _showSnackBar(context)
                //                   : Navigator.of(context)
                //                   .pushNamed(CopyScreen.routeName, arguments: {
                //                 'customerId': id,
                //                 'name': name,
                //                 'price_group_id':pricegroupId,
                //                 'code': code,
                //                 'paymentTerms': paymentTerms,
                //                 'outstandamt': _data
                //               });
                //             },
                //             child: _iconButtons(
                //                 icon: Icons.point_of_sale, title: 'Sale')),
                //       ]),
                //       CommonWidgets.verticalSpace(2),
                //       Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                //         InkWell(
                //             onTap: () {
                //               _showButton
                //                   ? _showSnackBar(context)
                //                   : Navigator.of(context)
                //                   .pushNamed(SalesScreen.routeName, arguments: {
                //                 'customerId': id,
                //                 'name': name,
                //               });
                //             },
                //             child: _iconButtons(
                //                 icon: Icons.point_of_sale, title: 'Sales')),
                //         GestureDetector(
                //             onTap: () {
                //               Navigator.pushNamed(
                //                   context, Customerreturndetail.routeName, arguments: {
                //                 'customerId': id,
                //                 'name': name,
                //                 'code': code,
                //                 'paymentTerms': paymentTerms,
                //                 'outstandamt': _data
                //               });
                //             },
                //             child:
                //             _iconButtons(icon: Icons.inventory, title: 'Return')),
                //         InkWell(
                //             onTap: () {
                //               Navigator.pushNamed(
                //                   context, PaymentCollectionScreen.routeName,
                //                   arguments: {
                //                     'customerId': id,
                //                     'name': name,
                //                     'code': code,
                //                     'paymentTerms': paymentTerms,
                //                     'outstandamt': _data
                //                   });
                //
                //               // Navigator.push(
                //               //     context,
                //               //     MaterialPageRoute(
                //               //       builder: (context) => PaymentCollectionScreen(
                //               //         id: 'customer',
                //               //         code: 'code',
                //               //         name: 'name',
                //               //       ),
                //               //     ));
                //             },
                //             child: _iconButtons(
                //                 icon: Icons.payments, title: 'Payment Collection'))
                //       ]),
                //       CommonWidgets.verticalSpace(2),
                //       Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                //         GestureDetector(
                //           onTap: () {
                //             Navigator.pushNamed(context, CustomerStock.routeName,arguments: {
                //               'customerId': id,
                //             });
                //           },
                //           child: _iconButtons(
                //               icon: Icons.storefront_rounded, title: 'Customer Stock'),
                //         ),
                //         GestureDetector(
                //             onTap: () {
                //               Navigator.pushNamed(context, CustomerVisit.routeName,
                //                   arguments: {
                //                     'name': name,
                //                     'code': code,
                //                     'email': email,
                //                     'paymentTerms': paymentTerms,
                //                     'address': address,
                //                     'phone': phone,
                //                     'id': id,
                //                   });
                //             },
                //             child: _iconButtons(icon: Icons.bar_chart, title: 'Visit')),
                //         GestureDetector(
                //             onTap: () {
                //               Navigator.pushNamed(context, TotalSales.routeName,
                //                   arguments: {
                //                     'id': id,
                //                   });
                //             },
                //             child: _iconButtons(
                //                 icon: Icons.pie_chart, title: 'Total Sales'))
                //       ]),
                //     ],
                //   ),
                //
                //     Container(
                //       child: SingleChildScrollView(
                //         child: Row(
                //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //           children: [
                //             GestureDetector(
                //                 onTap: () {
                //                   Navigator.pushNamed(
                //                       context, Customerorderdetail.routeName, arguments: {
                //                     'customerId': id,
                //                     'name': name,
                //                     'code': code,
                //                     'paymentTerms': paymentTerms
                //                   });
                //                 },
                //                 child:
                //                 _iconButtons(icon: Icons.shopping_bag, title: 'Order')),
                //             GestureDetector(
                //               onTap: () {
                //                 Navigator.of(context).pushNamed(
                //                     CustomerWater.routeName,arguments: {'customerId': id,});
                //               },
                //               child: _iconButtons(
                //                   icon: Icons.water_drop,
                //                   title: 'Coupon'),
                //             ),
                //           ],
                //         ),
                //       ),
                //     )
                //           ],
                // ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _iconButtons({required IconData icon, required String title}) {
  //   return Container(
  //     width: SizeConfig.blockSizeHorizontal * 22,
  //     height: SizeConfig.blockSizeVertical * 11,
  //     decoration: const BoxDecoration(
  //         borderRadius: BorderRadius.all(Radius.circular(10)),
  //         color: AppConfig.colorPrimary),
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         Icon(
  //           icon,
  //           color: AppConfig.backgroundColor,
  //           size: 40,
  //         ),
  //         SizedBox(
  //           width: SizeConfig.blockSizeHorizontal * 18,
  //           child: Center(
  //             child: Text(
  //               title,
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                   color: AppConfig.backgroundColor,
  //                   fontSize: AppConfig.textCaption3Size),
  //             ),
  //           ),
  //         )
  //       ],
  //     ),
  //   );
  // }

  Widget _iconButtons({
    IconData? icon,
    required String title,
    String? image,
    String? routeName,
  }) {
    return GestureDetector(
      onTap: () {
        if (routeName != null) {
          switch (routeName) {
            case 'CustomerRegistration':
              Navigator.pushNamed(context, CustomerRegistration.routeName,
                  arguments: {
                    'name': name,
                    'address': address,
                    'building': building,
                    'flat_no': flat_no,
                    'phone': phone,
                    'whatsappNumber': whatsappNumber,
                    'email': email,
                    'location': location,
                    'payment_terms': customerType,
                    'credit_days': creditDays,
                    'credit_limit': creditLimit,
                    'paymentTerms': paymentTerms,
                    'trn': trn,
                    'cust_image': img,
                    'code': code,
                    'provinceId': provinceId,
                    'routeId': routeId,
                    'id': id,
                  });
              break;
            case 'SOA':
              Navigator.pushNamed(context, SOA.routeName, arguments: {
                'customerId': id,
                'name': name,
                'address': address,
                'code': code,
                'paymentTerms': paymentTerms
              });
              break;
            case 'CopyScreen':
              _showButton
                  ? _showSnackBar(context)
                  : Navigator.of(context)
                      .pushNamed(CopyScreen.routeName, arguments: {
                      'customerId': id,
                      'name': name,
                      'price_group_id': pricegroupId,
                      'code': code,
                      'paymentTerms': paymentTerms,
                      'outstandamt': _data
                    });
              break;
            case 'SalesScreen':
              _showButton
                  ? _showSnackBar(context)
                  : Navigator.of(context)
                      .pushNamed(SalesScreen.routeName, arguments: {
                      'customerId': id,
                      'name': name,
                    });
              break;
            case 'Customerreturndetail':
              Navigator.pushNamed(context, Customerreturndetail.routeName,
                  arguments: {
                    'customerId': id,
                    'name': name,
                    'code': code,
                    'paymentTerms': paymentTerms,
                    'outstandamt': _data
                  });
              break;
            case 'PaymentCollectionScreen':
              Navigator.pushNamed(context, PaymentCollectionScreen.routeName,
                  arguments: {
                    'customerId': id,
                    'name': name,
                    'code': code,
                    'paymentTerms': paymentTerms,
                    'outstandamt': _data
                  });
              break;
            case 'CustomerStock':
              Navigator.pushNamed(context, CustomerStock.routeName, arguments: {
                'customerId': id,
              });
              break;
            case 'CustomerVisit':
              Navigator.pushNamed(context, CustomerVisit.routeName, arguments: {
                'name': name,
                'code': code,
                'email': email,
                'paymentTerms': paymentTerms,
                'address': address,
                'phone': phone,
                'id': id,
              });
              break;
            case 'TotalSales':
              Navigator.pushNamed(context, TotalSales.routeName, arguments: {
                'id': id,
              });
              break;
            case 'Customerorderdetail':
              Navigator.pushNamed(context, Customerorderdetail.routeName,
                  arguments: {
                    'customerId': id,
                    'name': name,
                    'code': code,
                    'paymentTerms': paymentTerms
                  });
              break;
            case 'QuotatioCustomerScreen':
              Navigator.pushNamed(context, QuotatioCustomerScreen.routeName,
                  arguments: {
                    'customerId': id,
                    'name': name,
                    'code': code,
                    'paymentTerms': paymentTerms
                  });
              break;
            case 'CustomerWater':
              Navigator.of(context)
                  .pushNamed(CustomerWater.routeName, arguments: {
                'customerId': id,
              });
              break;
            default:
              Navigator.pushNamed(context, routeName);
          }
        }
      },
      child: Container(
        width: SizeConfig.blockSizeHorizontal * 25,
        height: SizeConfig.blockSizeVertical * 12.5,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: AppConfig.colorPrimary,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: AppConfig.backgroundColor,
                size: 40,
              )
            else if (image != null)
              Image.asset(
                image,
                width: 50,
                height: 40,
                fit: BoxFit.contain,
              ),
            SizedBox(
              width: SizeConfig.blockSizeHorizontal * 18,
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppConfig.backgroundColor,
                    fontSize: AppConfig.textCaption3Size,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchData() async {
    final url =
        '${RestDatasource().BASE_URL}/api/vanoffloadrequest.pending?store_id=${AppState().storeId}&van_id=${AppState().vanId}';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print(response.request);
        final data = json.decode(response.body);
        setState(() {
          _showButton = data['success'] ?? false;
          _message = _showButton ? "" : "Button is hidden due to API response.";
        });
      } else {
        // Handle server errors or other HTTP errors
        setState(() {
          _showButton = false;
          _message = "Failed to fetch data.";
        });
      }
    } catch (e) {
      // Handle other errors, such as network issues
      setState(() {
        _showButton = false;
        _message = "An error occurred: $e";
      });
    }
  }

  Future<void> fetchData() async {
    try {
      var response = await http.get(Uri.parse(
          '${RestDatasource().BASE_URL}/api/get_sales_pending_outstanding?customer_id=$id&store_id=${AppState().storeId}'));
      if (response.statusCode == 200) {
        print(response.request);
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        setState(() {
          _data = jsonResponse['data'].toString();
        });
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
