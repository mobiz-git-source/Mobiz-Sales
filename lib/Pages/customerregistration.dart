import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobizapp/Components/commonwidgets.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/homepage.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import '../Models/Store_model.dart';
import '../Models/customercodemodel.dart';
import '../Models/provincemodelclass.dart';
import '../Models/routedatamodelclass.dart';
import '../confg/sizeconfig.dart';

class CustomerRegistration extends StatefulWidget {
  static const routeName = "/CustomerRegistartion";
  const CustomerRegistration({super.key});

  @override
  State<CustomerRegistration> createState() => _CustomerRegistrationState();
}

class _CustomerRegistrationState extends State<CustomerRegistration> {
  File? _image;
  bool showFields = false;
  bool _initDone = false;
  int cud = 0;
  bool _isLoading = false;
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<String> _loadImage(String img) async {
    String productUrl = '${RestDatasource().Product_URL}/uploads/customer/$img';
    String baseUrl = '${RestDatasource().BASE_URL}/uploads/customer/$img';

    try {
      final response = await http.head(Uri.parse(productUrl));
      if (response.statusCode == 200) {
        return productUrl;
      }
    } catch (e) {}

    try {
      final response = await http.head(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        return baseUrl;
      }
    } catch (e) {}
    throw Exception('Image not found');
  }

  void _getLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });
    _updateLocationTextField(_latitude!, _longitude!);
  }

  void _updateLocationTextField(double latitude, double longitude) {
    _locationController.text = '$latitude, $longitude';
  }

  double? _latitude;
  double? _longitude;

  bool _isUpdate = false;

  final _formKey = GlobalKey<FormState>();
  var _nameController = TextEditingController();
  var _codeController = TextEditingController();
  var _addressController = TextEditingController();
  var _contactNumberController = TextEditingController();
  var _whatsappNumberController = TextEditingController();
  var _emailController = TextEditingController();
  var _buildingController = TextEditingController();
  var _flatNumberController = TextEditingController();
  var _locationController = TextEditingController();
  final _trnController = TextEditingController();
  final _creditDays = TextEditingController();
  final _creditLimit = TextEditingController();

  late FocusNode namefocus;
  late FocusNode addressfocus;
  late FocusNode contactfocus;
  late FocusNode whatsappfocus;
  late FocusNode emailfocus;
  late FocusNode buildingfocus;
  late FocusNode flatfocus;
  late FocusNode trnfocus;

  String? _selectPaymentTerms;
  String? _customercode;
  String? _location;
  String? img;
  int? id;
  String? _selectedRoute;
  String? _selectCuCode;
  int? _selectedProvinceid;
  int? _selectedrouteid;

  RouteDataModel route = RouteDataModel();
  ProvinceDataModel province = ProvinceDataModel();
  CustomerCodeModel cuCode = CustomerCodeModel();

  final List<String> paymentTerms = ['CASH', 'CREDIT', 'BILLTOBILL'];

  // ✅ Removed hardcoded initial data
  final List<Map<String, dynamic>> routes = [];
  final List<Map<String, dynamic>> provinces = [];
  final List<String> cuCodeData = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Map<String, dynamic>? params =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (params != null) {
        _nameController.text = params['name'] ?? '';
        _customercode = params['code'];
        _addressController.text = params['address'] ?? '';
        _buildingController.text = params['building'] ?? '';
        _flatNumberController.text = params['flat_no'] ?? '';
        _contactNumberController.text = params['phone'] ?? '';
        _whatsappNumberController.text = params['whatsappNumber'] ?? '';
        _trnController.text = params['trn'] ?? '';
        img = params['cust_image'];
        _location = params['location'] ?? 'Click the icon to fetch the data';
        _selectPaymentTerms =
            params['paymentTerms'] == '' ? null : params['paymentTerms'];
        _selectedProvinceid =
            params['provinceId'] == 0 ? null : params['provinceId'];
        _selectedrouteid = params['routeId'];
        id = params['id'];
        if (params['credit_days'] != null && params['credit_days'] != '') {
          _creditDays.text = params['credit_days'].toString();
        }
        if (params['credit_limit'] != null && params['credit_limit'] != '') {
          _creditLimit.text = params['credit_limit'].toString();
        }
        _emailController.text = params['email'] ?? '';
        _isUpdate = true;
      }
    });
    namefocus = FocusNode();
    addressfocus = FocusNode();
    contactfocus = FocusNode();
    whatsappfocus = FocusNode();
    emailfocus = FocusNode();
    buildingfocus = FocusNode();
    flatfocus = FocusNode();
    trnfocus = FocusNode();

    super.initState();
    _getRoutes()
        .then((value) => _getProvince())
        .then((value) => _getCodeData())
        .then((value) => fetchStoreDetail())
        .then((storeDetail) {
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

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    _whatsappNumberController.dispose();
    _emailController.dispose();
    _buildingController.dispose();
    _flatNumberController.dispose();
    _trnController.dispose();
    _creditDays.dispose();
    _creditLimit.dispose();
    trnfocus.dispose();
    buildingfocus.dispose();
    flatfocus.dispose();
    namefocus.dispose();
    contactfocus.dispose();
    addressfocus.dispose();
    emailfocus.dispose();
    whatsappfocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text(
              'Registration',
              style: TextStyle(color: AppConfig.backButtonColor),
            ),
            backgroundColor: AppConfig.colorPrimary,
            iconTheme: const IconThemeData(color: AppConfig.backButtonColor)),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: (!_initDone)
                ? Shimmer.fromColors(
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
                  )
                : Column(
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: SizedBox(
                              width: 150,
                              height: 150,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 2,
                                      ),
                                      image: _image != null
                                          ? DecorationImage(
                                              image: FileImage(_image!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: _image == null
                                        ? (img != null && img!.isNotEmpty)
                                            ? FutureBuilder(
                                                future: _loadImage(img!),
                                                builder: (context, snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const Center(
                                                        child:
                                                            CircularProgressIndicator());
                                                  } else if (snapshot
                                                      .hasError) {
                                                    return const Center(
                                                        child: Text(
                                                            'Select Image'));
                                                  } else {
                                                    return ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      child: Image.network(
                                                        snapshot.data!,
                                                        width: 150,
                                                        height: 150,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return const Center(
                                                              child: Text(
                                                                  'Select Image'));
                                                        },
                                                      ),
                                                    );
                                                  }
                                                },
                                              )
                                            : const Center(
                                                child: Text('Select Image'))
                                        : null,
                                  ),
                                  if (_image != null)
                                    Positioned(
                                      bottom: 5,
                                      right: 5,
                                      child: GestureDetector(
                                        onTap: _pickImage,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  focusNode: namefocus,
                                  onEditingComplete: () {
                                    addressfocus.requestFocus();
                                  },
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppConfig.colorPrimary)),
                                    labelText: 'Name',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      _validateNotEmpty(value, 'Name'),
                                ),
                                CommonWidgets.verticalSpace(2),
                                // TextFormField(
                                //   style: const TextStyle(color: Colors.black),
                                //   enabled: false,
                                //   controller: TextEditingController(
                                //     text: _isUpdate
                                //         ? _customercode
                                //         : cuCodeData.isNotEmpty
                                //             ? cuCodeData.join(', ')
                                //             : '',
                                //   ),
                                //   decoration: const InputDecoration(
                                //     focusedBorder: OutlineInputBorder(
                                //       borderSide: BorderSide(
                                //           color: AppConfig.colorPrimary),
                                //     ),
                                //     disabledBorder: OutlineInputBorder(
                                //         borderSide:
                                //             BorderSide(color: Colors.grey)),
                                //     labelText: 'Code',
                                //     border: OutlineInputBorder(),
                                //     labelStyle: TextStyle(color: Colors.black),
                                //     hintStyle: TextStyle(color: Colors.black),
                                //   ),
                                // ),
                                // CommonWidgets.verticalSpace(2),
                                TextFormField(
                                  focusNode: addressfocus,
                                  onEditingComplete: () {
                                    contactfocus.requestFocus();
                                  },
                                  controller: _addressController,
                                  decoration: const InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppConfig.colorPrimary)),
                                    labelText: 'Address',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      _validateNotEmpty(value, 'Address'),
                                ),
                                CommonWidgets.verticalSpace(2),
                                if (showFields) ...[
                                  TextFormField(
                                    focusNode: buildingfocus,
                                    onEditingComplete: () {
                                      flatfocus.requestFocus();
                                    },
                                    controller: _buildingController,
                                    decoration: const InputDecoration(
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppConfig.colorPrimary)),
                                      labelText: 'Building',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  CommonWidgets.verticalSpace(2),
                                  TextFormField(
                                    focusNode: flatfocus,
                                    onEditingComplete: () {
                                      contactfocus.requestFocus();
                                    },
                                    controller: _flatNumberController,
                                    decoration: const InputDecoration(
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppConfig.colorPrimary)),
                                      labelText: 'Flat Number',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  CommonWidgets.verticalSpace(2),
                                ],
                                TextFormField(
                                  keyboardType: TextInputType.phone,
                                  focusNode: contactfocus,
                                  onEditingComplete: () {
                                    whatsappfocus.requestFocus();
                                  },
                                  controller: _contactNumberController,
                                  decoration: const InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppConfig.colorPrimary)),
                                    labelText: 'Contact Number',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      _validateNumber(value, 'Contact Number'),
                                ),
                                CommonWidgets.verticalSpace(2),
                                TextFormField(
                                  keyboardType: TextInputType.phone,
                                  focusNode: whatsappfocus,
                                  onEditingComplete: () {
                                    emailfocus.requestFocus();
                                  },
                                  controller: _whatsappNumberController,
                                  decoration: const InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppConfig.colorPrimary)),
                                    labelText: 'WhatsApp Number',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => _validateWhatsappNumber(
                                      value, 'WhatsApp Number'),
                                ),
                                CommonWidgets.verticalSpace(2),
                                TextFormField(
                                  onEditingComplete: () {
                                    trnfocus.requestFocus();
                                  },
                                  focusNode: emailfocus,
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppConfig.colorPrimary)),
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: _validateEmail,
                                ),
                                CommonWidgets.verticalSpace(2),
                                TextField(
                                  controller: _locationController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppConfig.colorPrimary)),
                                    focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppConfig.colorPrimary)),
                                    hintText: _location,
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.my_location),
                                      onPressed: _getLocation,
                                    ),
                                  ),
                                ),
                                CommonWidgets.verticalSpace(2),
                                TextFormField(
                                  focusNode: trnfocus,
                                  controller: _trnController,
                                  decoration: const InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppConfig.colorPrimary)),
                                    labelText: 'TRN',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      _validateNotEmpty(value, 'TRN'),
                                ),
                                CommonWidgets.verticalSpace(2),
                                _buildDropdownField(
                                  label: 'Payment Terms',
                                  items: paymentTerms,
                                  value: _selectPaymentTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectPaymentTerms = value;
                                    });
                                  },
                                ),

                                (_selectPaymentTerms == "CREDIT")
                                    ? CommonWidgets.verticalSpace(2)
                                    : Container(),
                                (_selectPaymentTerms == "CREDIT")
                                    ? TextFormField(
                                        controller: _creditLimit,
                                        decoration: const InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color:
                                                      AppConfig.colorPrimary)),
                                          labelText: 'Credit Limit',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) => _validateNotEmpty(
                                            value, 'Credit Limit'),
                                      )
                                    : Container(),
                                (_selectPaymentTerms == "CREDIT")
                                    ? CommonWidgets.verticalSpace(2)
                                    : Container(),
                                (_selectPaymentTerms == "CREDIT")
                                    ? TextFormField(
                                        controller: _creditDays,
                                        decoration: const InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color:
                                                      AppConfig.colorPrimary)),
                                          labelText: 'Credit Days',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) => _validateNotEmpty(
                                            value, 'Credit Days'),
                                      )
                                    : Container(),
                                CommonWidgets.verticalSpace(2),

                                CustomDropdown(
                                  items: routes,
                                  selectedValue: _selectedrouteid != null
                                      ? routes.firstWhere(
                                        (element) => element['id'] == _selectedrouteid,
                                    orElse: () => {}
                                  )
                                      : null,
                                  onChanged: (selectedroute) {
                                    setState(() {
                                      _selectedrouteid = selectedroute?['id'];
                                    });
                                  },
                                  hint: 'Select Routes',
                                  label: 'Route',
                                ),

                                CommonWidgets.verticalSpace(2),
                                CustomDropdown(
                                  items: provinces,
                                  selectedValue: _selectedProvinceid != null
                                      ? provinces.firstWhere(
                                        (element) => element['id'] == _selectedProvinceid,
                                    orElse: () => {},
                                  )
                                      : null,
                                  onChanged: (selectedProvince) {
                                    setState(() {
                                      _selectedProvinceid = selectedProvince?['id'];
                                    });
                                  },
                                  hint: 'Select Province',
                                  label: 'Province',
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: SizeConfig.blockSizeHorizontal * 35,
                                  height: SizeConfig.blockSizeVertical * 5,
                                  child: ElevatedButton(
                                    style: ButtonStyle(
                                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20.0),
                                        ),
                                      ),
                                      backgroundColor: WidgetStatePropertyAll(
                                        _isLoading ? Colors.grey : AppConfig.colorPrimary,
                                      ),
                                    ),
                                    onPressed: _isLoading ? null : _submitForm,
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            _isUpdate ? 'UPDATE' : 'CREATE',
                                            style: TextStyle(
                                              fontSize: AppConfig.textCaption3Size,
                                              color: AppConfig.backgroundColor,
                                              fontWeight: AppConfig.headLineWeight,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ));
  }

  void _submitForm() {
    if (_isLoading) return;
    if (_formKey.currentState!.validate()) {
      _postRecord();
    }
  }

  String? _validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email';
      }
    }
    return null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    final numberRegex = RegExp(r'^\+?[0-9]+$');
    if (!numberRegex.hasMatch(value)) {
      return 'Please enter a valid $fieldName';
    }
    return null;
  }

  String? _validateWhatsappNumber(String? value, String fieldName) {
    if (value != null && value.isNotEmpty) {
      final numberRegex = RegExp(r'^[0-9]+$');
      if (!numberRegex.hasMatch(value)) {
        return 'Please enter a valid $fieldName';
      }
    }
    return null;
  }

  Widget _buildDropdownField(
      {required String label,
      required List<String> items,
      required String? value,
      required void Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppConfig.colorPrimary)),
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      onChanged: onChanged,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      validator: (value) => value == null ? 'Please select $label' : null,
    );
  }

  Future<StoreDetail?> fetchStoreDetail() async {
    final url = Uri.parse(
        '${RestDatasource().BASE_URL}/api/get_store_detail?store_id=${AppState().storeId}');

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

  Future<void> _getRoutes() async {
    RestDatasource api = RestDatasource();
    String endpoint = '/api/get_route?store_id=${AppState().storeId}&user_id=${AppState().userId}';
    print("🔹 Fetching Routes API: ${RestDatasource().BASE_URL}$endpoint");

    dynamic resJson = await api.getDetails(endpoint, AppState().token);
    print("🔹 Routes Response: $resJson");

    route = RouteDataModel.fromJson(resJson);
    routes.clear();
    if (route.data != null) {
      for (var i in route.data!) {
        routes.add({'id': i.id, 'name': i.name});
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _getProvince() async {
    RestDatasource api = RestDatasource();
    String endpoint = '/api/get_province/${AppState().storeId}/';
    print("🔹 Fetching Province API: ${RestDatasource().BASE_URL}$endpoint");

    dynamic resJson = await api.getDetails(endpoint, AppState().token);
    print("🔹 Province Response: $resJson");

    province = ProvinceDataModel.fromJson(resJson);
    provinces.clear();
    if (province.data != null) {
      for (var i in province.data!) {
        provinces.add({'id': i.id, 'name': i.name});
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _getCodeData() async {
    RestDatasource api = RestDatasource();
    dynamic resJson = await api.getDetails(
        '/api/get_customer_code?store_id=${AppState().storeId}',
        AppState().token);
    cuCode = CustomerCodeModel.fromJson(resJson);
    if (cuCode.result!.data != null) {
      cuCodeData.clear();
      cuCodeData.add(cuCode.result!.data!);
    }
    if (mounted) {
      setState(() {
        _initDone = true;
      });
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();

    _nameController.clear();
    _addressController.clear();
    _contactNumberController.clear();
    _whatsappNumberController.clear();
    _emailController.clear();
    _buildingController.clear();
    _flatNumberController.clear();
    _locationController.clear();
    _trnController.clear();
    _creditDays.clear();
    _creditLimit.clear();

    _selectPaymentTerms = null;
    _selectedProvinceid = null;
    _selectedrouteid = null;
    _image = null;
  }

  Future<void> _postRecord() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      RestDatasource api = RestDatasource();

      String codeToPost =
          _customercode ?? (cuCodeData.isNotEmpty ? cuCodeData.join(', ') : '');

      Map<String, dynamic> bodyJson = {
        'id': id,
        'name': _nameController.text,
        'code': codeToPost,
        'address': _addressController.text,
        'contact_number': _contactNumberController.text,
        'whatsapp_number': _whatsappNumberController.text,
        'email': _emailController.text,
        'Building': _buildingController.text,
        'Flat_no': _flatNumberController.text,
        'location': _locationController.text.isNotEmpty
            ? _locationController.text
            : _location,
        'trn': _trnController.text,
        'payment_terms': _selectPaymentTerms,
        'route_id': _selectedrouteid,
        'provience_id': _selectedProvinceid,
        'store_id': AppState().storeId,
        if (_creditLimit.text.isNotEmpty) 'credi_limit': _creditLimit.text,
        if (_creditDays.text.isNotEmpty) 'credi_days': _creditDays.text,
      };

      await api.customerRegister(
        AppState().token,
        bodyJson,
        _image,
        context,
        _isUpdate,
      );

      if (!mounted) return;

      await CommonWidgets.showDialogueBox(
        context: context,
        title: "Success",
        msg: _isUpdate
            ? "Data Updated Successfully"
            : "Data Inserted Successfully",
      );

      _clearForm(); // 🧹 clear everything before navigating

      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    } catch (e) {
      if (!mounted) return;

      await CommonWidgets.showDialogueBox(
        context: context,
        title: "Error",
        msg: "Something went wrong. Please try again.",
      );

      setState(() {
        _isLoading = false; // 🔓 re-enable only on failure
      });
    }
  }

}

class CustomDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? selectedValue;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final String hint;
  final String label;

  CustomDropdown({
    required this.items,
    required this.onChanged,
    this.selectedValue,
    required this.hint,
    required this.label,
  });

  @override
  _CustomDropdownState createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  Map<String, dynamic>? selectedItem;

  @override
  void initState() {
    super.initState();
    selectedItem = widget.selectedValue;
  }

  @override
  void didUpdateWidget(covariant CustomDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != selectedItem) {
      setState(() {
        selectedItem = widget.selectedValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Map<String, dynamic>>(
      hint: Text(widget.hint),
      value: widget.items.contains(selectedItem) ? selectedItem : null,
      onChanged: (Map<String, dynamic>? newValue) {
        setState(() {
          selectedItem = newValue;
        });
        widget.onChanged(newValue);
      },
      items: widget.items.map((item) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: item,
          child: Text(item['name']),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: widget.label,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
      value == null ? 'Please select ${widget.label}' : null,
    );
  }
}
