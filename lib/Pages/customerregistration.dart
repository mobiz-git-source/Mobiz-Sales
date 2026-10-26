import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobizapp/Components/commonwidgets.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/customerscreen.dart';
import 'package:mobizapp/Pages/homepage.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String vatLabel = "VAT";

  Future<void> loadVatLabel() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      vatLabel = prefs.getString("vat_label") ?? "VAT";
    });

    print("Loaded VAT LABEL: $vatLabel");
  }

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
  List<dynamic>? _passedCustomerList;
  bool _isDuplicateError = false;
  final ScrollController _scrollController = ScrollController();

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

  final List<Map<String, dynamic>> routes = [];
  final List<Map<String, dynamic>> provinces = [];
  final List<String> cuCodeData = [];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Map<String, dynamic>? params =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (params != null) {
        if (params['customerList'] != null && params['customerList'] is List) {
          _passedCustomerList = params['customerList'];
        }
        if (params['id'] != null || (params['name'] != null && params['name'].toString().isNotEmpty)) {
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
    loadVatLabel();
    _loadInitialData();
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
            style: AppConfig.pageTitleStyle,
          ),
          backgroundColor: AppConfig.colorPrimary,
          iconTheme: const IconThemeData(color: AppConfig.backButtonColor),
        ),
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
                             // AFTER
                                    child: _image == null
                                        ? (img != null && img!.isNotEmpty)
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(20),
                                              child: Image.network(
                                                '${RestDatasource().Product_URL}/uploads/customer/$img',
                                                width: 150,
                                                height: 150,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Image.network(
                                                    '${RestDatasource().BASE_URL}/uploads/customer/$img',
                                                    width: 150,
                                                    height: 150,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Center(child: Text('Select Image'));
                                                    },
                                                  );
                                                },
                                              ),
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
                          controller: _scrollController,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  focusNode: namefocus,
                                  onEditingComplete: () {
                                    addressfocus.requestFocus();
                                  },
                                  onChanged: (val) {
                                    if (_isDuplicateError) {
                                      setState(() {
                                        _isDuplicateError = false;
                                      });
                                    }
                                  },
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _isDuplicateError
                                            ? Colors.black
                                            : AppConfig.colorPrimary,
                                        width: _isDuplicateError ? 2.0 : 1.0,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _isDuplicateError
                                            ? Colors.black
                                            : Colors.grey,
                                        width: _isDuplicateError ? 2.0 : 1.0,
                                      ),
                                    ),
                                    labelText: 'Name',
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) =>
                                      _validateNotEmpty(value, 'Name'),
                                ),
                                if (_isDuplicateError) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10.0),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      border: Border.all(color: Colors.red.shade300),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Duplicate record exists. Do you want to proceed?',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppConfig.colorPrimary,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 16, vertical: 8),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _isDuplicateError = false;
                                                });
                                                _postRecord();
                                              },
                                              child: const Text('YES',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppConfig.colorPrimary,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 16, vertical: 8),
                                              ),
                                              onPressed: () {
                                                FocusScope.of(context)
                                                    .requestFocus(namefocus);
                                              },
                                              child: const Text('NO',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                CommonWidgets.verticalSpace(2),
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
                                      borderSide: BorderSide(color: AppConfig.colorPrimary),
                                    ),
                                    labelText: 'Email',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return null; // Email is optional
                                    }

                                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                    if (!emailRegex.hasMatch(value.trim())) {
                                      return 'Please enter a valid email';
                                    }

                                    return null;
                                  },
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
                                  decoration: InputDecoration(
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(color: AppConfig.colorPrimary),
                                    ),
                                    labelText: (AppState().vatLabel != null &&
                                            AppState().vatLabel!.trim().isNotEmpty)
                                        ? AppState().vatLabel!
                                        : "VAT",
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (value) => _validateNotEmpty(
                                    value,
                                    (AppState().vatLabel != null &&
                                            AppState().vatLabel!.trim().isNotEmpty)
                                        ? AppState().vatLabel!
                                        : "VAT",
                                  ),
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

  bool _checkDuplicateInLoadedList(String name) {
    final cleanInput = name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (cleanInput.isEmpty) return false;

    List<dynamic> listToCheck = [];
    if (_passedCustomerList != null && _passedCustomerList!.isNotEmpty) {
      listToCheck = _passedCustomerList!;
    } else if (CustomersDataScreen.loadedCustomerList.isNotEmpty) {
      listToCheck = CustomersDataScreen.loadedCustomerList;
    }

    for (var item in listToCheck) {
      String? existingName;
      if (item is Map) {
        existingName = item['name']?.toString();
      } else {
        try {
          existingName = (item as dynamic).name?.toString();
        } catch (_) {}
      }

      if (existingName != null) {
        final cleanExisting = existingName.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
        if (cleanExisting == cleanInput) {
          return true;
        }
      }
    }
    return false;
  }

  void _submitForm() async {
    if (_isLoading) return;
    if (_formKey.currentState!.validate()) {
      if (!_isUpdate) {
        if (_checkDuplicateInLoadedList(_nameController.text)) {
          setState(() {
            _isDuplicateError = true;
          });
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
          FocusScope.of(context).requestFocus(namefocus);
          return; // Stay on Registration screen with inline warning, do NOT call create API
        }
      }
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
// ADD (new method — not present before)
Future<void> _loadInitialData() async {
  try {
    await _getRoutes();
    await _getProvince();
    await _getCodeData();
    final storeDetail = await fetchStoreDetail();
    if (mounted) {
      setState(() {
        showFields = (storeDetail != null && storeDetail.comapny_id == 5);
        _initDone = true;
      });
    }
  } catch (e) {
    print('Registration load error: $e');
    if (mounted) {
      setState(() {
        _initDone = true;
      });
    }
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

    
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

   await CommonWidgets.showDialogueBox(
  context: context,
  title: "Success",
  msg: _isUpdate
      ? "Data Updated Successfully"
      : "Data Inserted Successfully",
);

_clearForm();


Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      await CommonWidgets.showDialogueBox(
        context: context,
        title: "Error",
        msg: "Something went wrong. Please try again.",
      );

      setState(() {
        _isLoading = false;
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

  const CustomDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.selectedValue,
    required this.hint,
    required this.label,
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  Map<String, dynamic>? _selected;
  List<Map<String, dynamic>> _filteredItems = [];

  static const Map<String, dynamic> _notFoundItem = {
    'id': '__not_found__',
    'name': 'Result not found',
  };

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedValue;
    _controller = TextEditingController(text: _selected?['name'] ?? '');
    _filteredItems = widget.items;

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _filterItems(_controller.text);
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

 @override
void didUpdateWidget(covariant CustomDropdown oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.selectedValue != oldWidget.selectedValue) {
    _selected = widget.selectedValue;
    final newText = _selected?['name'] ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.text = newText;   // ✅ build finish ആയ ശേഷം next frame-ൽ set ചെയ്യുന്നു
      }
    });
  }
}

  void _filterItems(String query) {
    if (query.isEmpty) {
      _filteredItems = widget.items;
    } else {
      final q = query.toLowerCase().trim();

      final startsWithMatches = widget.items.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final words = name.split(RegExp(r'\s+'));
        return words.any((word) => word.startsWith(q));
      }).toList();

      final containsMatches = widget.items.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final words = name.split(RegExp(r'\s+'));
        final alreadyMatched = words.any((word) => word.startsWith(q));
        return !alreadyMatched && name.contains(q);
      }).toList();

      final filtered = [...startsWithMatches, ...containsMatches];
      _filteredItems = filtered.isEmpty ? [_notFoundItem] : filtered;
    }
    _overlayEntry?.markNeedsBuild();
  }

  void _selectItem(Map<String, dynamic> item) {
    if (item['id'] == '__not_found__') return;
    setState(() {
      _selected = item;
      _controller.text = item['name']?.toString() ?? '';
    });
    widget.onChanged(item);
    _focusNode.unfocus();
  }

  void _clearSelection() {
    setState(() {
      _selected = null;
      _controller.clear();
    });
    widget.onChanged(null);
    _filterItems('');
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        final RenderBox? fieldBox =
            _fieldKey.currentContext?.findRenderObject() as RenderBox?;
        if (fieldBox == null) return const SizedBox.shrink();

        final fieldSize = fieldBox.size;
        final fieldPosition = fieldBox.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(context).size.height;
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        final visibleBottom = screenHeight - keyboardHeight;

        final double spaceBelow =
            visibleBottom - (fieldPosition.dy + fieldSize.height) - 8;
        final double spaceAbove = fieldPosition.dy - 8;

        final bool openAbove = spaceBelow < 150 && spaceAbove > spaceBelow;

        final double maxListHeight =
            (openAbove ? spaceAbove : spaceBelow).clamp(120, 260);

        return Positioned(
          width: fieldSize.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: openAbove ? Alignment.topLeft : Alignment.bottomLeft,
            followerAnchor: openAbove ? Alignment.bottomLeft : Alignment.topLeft,
            offset: Offset(0, openAbove ? -6 : 6),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(maxHeight: maxListHeight),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Scrollbar(
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _filteredItems.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade200,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isNotFound = item['id'] == '__not_found__';
                        final isSelected = !isNotFound &&
                            _selected != null &&
                            _selected!['id'] == item['id'];

                        return InkWell(
                          onTap: isNotFound ? null : () => _selectItem(item),
                          child: Container(
                            color: isSelected
                                ? Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.08)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['name']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isNotFound
                                          ? Colors.grey
                                          : (isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.black87),
                                      fontStyle: isNotFound
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check,
                                      size: 18,
                                      color: Theme.of(context).primaryColor),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        key: _fieldKey,
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          border: const OutlineInputBorder(),
          suffixIcon: _selected != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSelection,
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        onChanged: (text) {
          if (_selected != null && text != _selected!['name']) {
            _selected = null;
            widget.onChanged(null);
          }
          _filterItems(text);
        },
        validator: (value) {
          if (_selected == null) {
            return 'Please select ${widget.label}';
          }
          return null;
        },
      ),
    );
  }
}
