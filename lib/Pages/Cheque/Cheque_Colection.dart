import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/homepage.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/confg/sizeconfig.dart';
import 'package:mobizapp/Utilities/date_helper.dart';

class ChequeCollectionPage extends StatefulWidget {
  static const routeName = "/ChequeCollection";
  @override
  State<ChequeCollectionPage> createState() => _ChequeCollectionPageState();
}

class _ChequeCollectionPageState extends State<ChequeCollectionPage> {
  List<String> groupNames = [];
  List<String> customerNames = [];
  String? selectedGroup;
  String? selectedCustomer;
  int? selectedId;
  List<int> groupIds = [];
  List<int> customerIds = [];
 String selectedDate = DateHelper.displayFromDateTime(DateTime.now());
  String collectionType = 'Cheque';
  TextEditingController bankController = TextEditingController();
  TextEditingController chequeNoController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  bool isSavingCheque = false;
  bool isGroupCustomer = true; // Toggle between Customer and Group Customer

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  if (pickedDate != null) {
      setState(() {
        selectedDate = DateHelper.displayFromDateTime(pickedDate);
      });
    }
  }

  Future<void> fetchGroups() async {
    final url = Uri.parse('${RestDatasource().BASE_URL}/api/get_group?store_id=${AppState().storeId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            groupIds = List<int>.from(data['data'].map((group) => group['id']));
            groupNames = List<String>.from(data['data'].map((group) => group['name']));
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchCustomers() async {
    final url = Uri.parse('${RestDatasource().BASE_URL}/api/get_customer?store_id=${AppState().storeId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        print(response.request);
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            customerIds = List<int>.from(data['data'].map((customer) => customer['id']));
            customerNames = List<String>.from(data['data'].map((customer) => customer['name']));
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> saveChequeCollection() async {
    if (isSavingCheque) return;
    setState(() => isSavingCheque = true);

    if (selectedId == null || bankController.text.isEmpty || chequeNoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      setState(() => isSavingCheque = false);
      return;
    }

    final url = Uri.parse('${RestDatasource().BASE_URL}/api/check_group_post');
    final body = {
      "customer_group_id": selectedId,
      "payment_type": isGroupCustomer ? "Group" : "Individual",
      "collection_type": "Cheque",
      "cheque_date": selectedDate,
      "bank": bankController.text,
      "amount": amountController.text,
      "cheque_no": chequeNoController.text,
      "description": descriptionController.text,
      "van_id": AppState().vanId,
      "store_id": AppState().storeId,
      "user_id": AppState().userId,
    };

    try {
      print("Sending request to: ${url.toString()}");
      print("Request body: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");
      print("body: $body");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Success'),
                content: const Text('Cheque collection saved successfully!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Something went wrong')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save cheque collection. Status: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print("Error saving cheque collection: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isSavingCheque = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cheque Collection',
          style: AppConfig.pageTitleStyle,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: AppConfig.colorPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle between Customer and Group Customer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ToggleButtons(
                    isSelected: [isGroupCustomer, !isGroupCustomer],
                    onPressed: (int index) {
                      setState(() {
                        isGroupCustomer = index == 0;
                        selectedId = null;
                        selectedGroup = null;
                        selectedCustomer = null;
                      });
                      if (!isGroupCustomer) {
                        fetchCustomers();
                      }
                    },
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Group Customer'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Customer'),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(8),
                    borderColor: Colors.grey,
                    selectedBorderColor: AppConfig.colorPrimary,
                    selectedColor: Colors.white,
                    fillColor: AppConfig.colorPrimary,
                    constraints: BoxConstraints(
                      minHeight: 36,
                      minWidth: 120,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Customer/Group Customer Dropdown
              Text(
                isGroupCustomer ? 'Group Customer' : 'Customer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              DropdownSearch<String>(
                items: isGroupCustomer ? groupNames : customerNames,
                selectedItem: isGroupCustomer ? selectedGroup : selectedCustomer,
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: isGroupCustomer ? "Select Group Customer Name" : "Select Customer Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    if (isGroupCustomer) {
                      selectedGroup = value!;
                      selectedId = groupIds[groupNames.indexOf(value)];
                    } else {
                      selectedCustomer = value!;
                      selectedId = customerIds[customerNames.indexOf(value)];
                    }
                  });
                },
                popupProps: PopupProps.dialog(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      labelText: "Search...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8.0),
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount
                  Text(
                    'Amount',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  SizedBox(
                    width: SizeConfig.blockSizeHorizontal * 40,
                    child: TextField(
                      controller: amountController,
                      readOnly: true,
                      onTap: () async {
                        String? result = await showDialog<String>(
                          context: context,
                          builder: (BuildContext context) {
                            String tempValue = amountController.text;
                            return AlertDialog(
                              title: const Text('Enter Amount'),
                              content: TextField(
                                keyboardType: TextInputType.number,
                                controller: TextEditingController(text: tempValue),
                                onChanged: (value) {
                                  tempValue = value;
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter amount',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(null),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(tempValue),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                        if (result != null && result.isNotEmpty) {
                          setState(() {
                            amountController.text = result;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        isDense: true,
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Cheque Date
                  Text(
                    'Cheque Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  SizedBox(
                    width: 120,
                    height: 35,
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(selectedDate),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Bank
                  Text(
                    'Bank',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: bankController,
                      readOnly: true,
                      onTap: () async {
                        String? result = await showDialog<String>(
                          context: context,
                          builder: (BuildContext context) {
                            String tempValue = bankController.text;
                            return AlertDialog(
                              title: const Text('Enter Bank Name'),
                              content: TextField(
                                controller: TextEditingController(text: tempValue),
                                onChanged: (value) {
                                  tempValue = value;
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter bank name',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(null),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(tempValue),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                        if (result != null && result.isNotEmpty) {
                          setState(() {
                            bankController.text = result;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        isDense: true,
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Cheque No
                  Text(
                    'Cheque No',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: chequeNoController,
                      readOnly: true,
                      onTap: () async {
                        String? result = await showDialog<String>(
                          context: context,
                          builder: (BuildContext context) {
                            String tempValue = chequeNoController.text;
                            return AlertDialog(
                              title: const Text('Enter Cheque No'),
                              content: TextField(
                                keyboardType: TextInputType.number,
                                controller: TextEditingController(text: tempValue),
                                onChanged: (value) {
                                  tempValue = value;
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Enter cheque number',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(null),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(tempValue),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                        if (result != null && result.isNotEmpty) {
                          setState(() {
                            chequeNoController.text = result;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
              Text(
                'Remarks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(10.0),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: SizedBox(
                  child: ElevatedButton(
                    onPressed: isSavingCheque ? null : saveChequeCollection,
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(150, 50),
                      backgroundColor: isSavingCheque ? Colors.grey : AppConfig.colorPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}