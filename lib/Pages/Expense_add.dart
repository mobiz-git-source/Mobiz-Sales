// import 'dart:nativewrappers/_internal/vm/lib/core_patch.dart';

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/ExpensesPage.dart';
import 'package:mobizapp/Pages/homepage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import '../Components/commonwidgets.dart';
import '../Models/ExpenseDrop_model.dart';
import '../Models/LoginModelClass.dart';
import '../Utilities/rest_ds.dart';
import '../Utilities/date_helper.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import 'homepage_Driver.dart';

class ExpenseAdd extends StatefulWidget {
  static const routeName = "/ExpenseAdd";

  const ExpenseAdd({super.key});

  @override
  State<ExpenseAdd> createState() => _ExpenseAddState();
}

class _ExpenseAddState extends State<ExpenseAdd> {
  late Future<VisitReasonResponse> futureExpenseReason;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _vatAmountController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  List<File> _attachedImages = [];
  Expense? selectedexpense;
  String? _amount;
  String? _vatAmount;
  String? _totalAmount;
  DateTime? _selectedDate = DateTime.now();
  TextEditingController remark = TextEditingController();
  @override
  void initState() {
    super.initState();
    futureExpenseReason = fetchExpenses();
    _amountController.addListener(_calculateTotalAmount);
    _vatAmountController.addListener(_calculateTotalAmount);
  _dateController.text =
        DateHelper.displayFromDateTime(_selectedDate!);
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateTotalAmount);
    _vatAmountController.removeListener(_calculateTotalAmount);
    _amountController.dispose();
    _vatAmountController.dispose();
    _totalAmountController.dispose();
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
  'Expense',
  style: AppConfig.pageTitleStyle,
),
      ),
      body: FutureBuilder(
        future: futureExpenseReason,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Shimmer.fromColors(
              baseColor: AppConfig.buttonDeactiveColor.withOpacity(0.1),
              highlightColor: AppConfig.backButtonColor,
              child: Center(
                child: Column(
                  children: List.generate(
                    6,
                    (index) => CommonWidgets.loadingContainers(
                      height: SizeConfig.blockSizeVertical * 10,
                      width: SizeConfig.blockSizeHorizontal * 90,
                    ),
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'),
            );
          } else if (snapshot.hasData) {
            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 15,
                          ),
                          Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppConfig.colorPrimary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                                child: Text(
                                _selectedDate == null
                                    ? 'Select Date'
                                    : DateHelper.displayFromDateTime(_selectedDate!),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  // fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          TextFormField(
                            keyboardType: TextInputType.number,
                            // inputFormatters: [
                            //   FilteringTextInputFormatter.digitsOnly
                            // ],
                            controller: _amountController,
                            decoration: const InputDecoration(
                              helperText: '',
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppConfig.colorPrimary),
                              ),
                              labelText: 'Amount',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an amount';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            keyboardType: TextInputType.number,
                            // inputFormatters: [
                            //   FilteringTextInputFormatter.digitsOnly
                            // ],
                            controller: _vatAmountController,
                            decoration: const InputDecoration(
                              helperText: '',
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppConfig.colorPrimary),
                              ),
                              labelText: 'Vat Amount',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter vat amount';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            readOnly: true,
                            keyboardType: TextInputType.number,
                            controller: _totalAmountController,
                            decoration: const InputDecoration(
                              helperText: '',
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: AppConfig.colorPrimary),
                              ),
                              labelText: 'Total Amount',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Total amount cannot be empty';
                              }
                              return null;
                            },
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height * .06,
                            width: MediaQuery.of(context).size.width * .92,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(5),
                              // Optionally add border: Border.all(color: Colors.grey), if needed
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButtonFormField<Expense>(
                                  decoration: InputDecoration(
                                    border: InputBorder
                                        .none, // Remove underline here
                                    contentPadding: EdgeInsets
                                        .zero, // Remove default padding
                                  ),
                                  isExpanded: true,
                                  hint: Text(
                                    'Select from list',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w300),
                                  ),
                                  value: selectedexpense,
                                  onChanged: (Expense? newValue) {
                                    setState(() {
                                      selectedexpense = newValue;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select an expense';
                                    }
                                    return null;
                                  },
                                  items: snapshot.data!.data
                                      .map((Expense expense) {
                                    return DropdownMenuItem<Expense>(
                                      value: expense,
                                      child: Center(
                                        child: Text(expense.name),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          SizedBox(
                            child: TextFormField(
                              controller: remark,
                              maxLines: 3,
                              decoration: InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.grey)),
                                  hintText: 'Enter Remarks here',
                                  hintStyle:
                                      TextStyle(fontWeight: FontWeight.w300),
                                  border: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.grey))),
                            ),
                            // height: MediaQuery.of(context).size.height * .2,
                            width: MediaQuery.of(context).size.width * .92,
                          ),
                        ],
                      ),
                    ),
                                      Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                  AppConfig.colorPrimary),
                              shape: WidgetStateProperty.all(
                                  BeveledRectangleBorder()),
                              minimumSize:
                                  WidgetStateProperty.all(Size(70, 30)),
                            ),
                            onPressed: _attachDocuments,
                            child: SizedBox(
                              width: 120,
                              child: Center(
                                child: Text(
                                  "Attach Documents",
                                  style: TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                  AppConfig.colorPrimary),
                              shape: WidgetStateProperty.all(
                                  BeveledRectangleBorder()),
                              minimumSize:
                                  WidgetStateProperty.all(Size(70, 30)),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                postData();
                              }
                            },
                            child: SizedBox(
                              width: 120,
                              child: Center(
                                child: Text(
                                  "Send for Approval",
                                  style: TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    _attachedImages.isEmpty
                        ? Container()
                        : Wrap(
                            children: _attachedImages.map((File file) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.file(
                                  file,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }).toList(),
                          ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            );
          } else {
            return Center(child: Text('No Data Available'));
          }
        },
      ),
    );
  }

  void _attachDocuments() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Photo Library'),
                onTap: () async {
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (pickedFile != null) {
                    final compressedImage =
                        await _compressImage(File(pickedFile.path));
                    setState(() {
                      _attachedImages.add(compressedImage);
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () async {
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (pickedFile != null) {
                    final compressedImage =
                        await _compressImage(File(pickedFile.path));
                    setState(() {
                      _attachedImages.add(compressedImage);
                    });
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<File> _compressImage(File file) async {
    final image = img.decodeImage(file.readAsBytesSync())!;
    final compressedImage = img.copyResize(image, width: 800);
    final compressedBytes =
        img.encodeJpg(compressedImage, quality: 75); // Compress the image

    final tempDir = await getTemporaryDirectory();
    final compressedFile =
        File('${tempDir.path}/compressed_${file.path.split('/').last}');
    await compressedFile.writeAsBytes(compressedBytes);

    print(
        'Compressed image size: ${compressedFile.lengthSync()} bytes'); // Debug statement

    // Check file size and further compress if necessary
    if (compressedFile.lengthSync() > 200 * 1024) {
      final furtherCompressedBytes =
          img.encodeJpg(compressedImage, quality: 65);
      await compressedFile.writeAsBytes(furtherCompressedBytes);
      print(
          'Further compressed image size: ${compressedFile.lengthSync()} bytes'); // Debug statement
    }

    return compressedFile;
  }

  void _calculateTotalAmount() {
    setState(() {
      String amountText = _amountController.text;
      String vatAmountText = _vatAmountController.text;

      if (amountText.isNotEmpty && vatAmountText.isNotEmpty) {
        double? amount = double.tryParse(amountText);
        double? vatAmount = double.tryParse(vatAmountText);

        if (amount != null && vatAmount != null) {
          double totalAmount = amount + vatAmount;
          _totalAmountController.text =
              totalAmount.toStringAsFixed(AppState().noOfDecimals ?? 2); // Format to 2 decimal places
        } else {
          _totalAmountController.clear();
        }
      } else {
        _totalAmountController.clear();
      }
    });
  }

  void postData() async {
    var url = Uri.parse('${RestDatasource().BASE_URL}/api/expense.store');
    var request = http.MultipartRequest('POST', url);

    request.fields['van_id'] = AppState().vanId.toString();
    request.fields['store_id'] = AppState().storeId.toString();
    request.fields['expense_id'] = selectedexpense!.id.toString();
    request.fields['description'] = remark.text;
    request.fields['amount'] = _amountController.text;
    request.fields['in_date'] = DateHelper.apiDate(_selectedDate!);
    request.fields['user_id'] = AppState().userId.toString();
    request.fields['vat_amount'] = _vatAmountController.text;
    request.fields['total_amount'] = _totalAmountController.text;

    for (var file in _attachedImages) {
      request.files.add(await http.MultipartFile.fromPath(
        'document_name[]', // API expects an array of files, adjust as per API documentation
        file.path,
      ));
    }

    // Send the request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    print("FIELDS:");
    request.fields.forEach((key, value) {
      print("$key : $value");
    });

    print("\nFILES:");
    for (var file in _attachedImages) {
      print("upload_document[] : ${file.path}");
    }
    print(response.body);
    print("response.body");
    if (response.statusCode == 200) {
      print(response.body);
      if (mounted) {
        CommonWidgets.showDialogueBox(
          context: context,
          title: "",
          msg: "Data Inserted Successfully",
        ).then((value) {
          if (AppState().rolId == 4) {
            Navigator.pushNamed(context, HomepageDriver.routeName);
          } else {
            Navigator.pushNamed(context, HomeScreen.routeName);
          }
        });
      }
      print('Request successful');
      print('Response: ${response.body}');
    }
    else {
      print('Request failed with status: ${response.statusCode} ${response.body}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to insert data. Please try again. ${response.statusCode} ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static String url =
      '${RestDatasource().BASE_URL}/api/get_expense_master?store_id=${AppState().storeId}';

  static Future<VisitReasonResponse> fetchExpenses() async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return VisitReasonResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load data');
    }
  }
}
