import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import 'package:shimmer/shimmer.dart';

import '../Components/commonwidgets.dart';
import 'Expense_add.dart';
import '../Utilities/rest_ds.dart';
import '../Utilities/date_helper.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';

class Expensespage extends StatefulWidget {
  static const routeName = "/Expensespage";
  @override
  _ExpensespageState createState() => _ExpensespageState();
}

class _ExpensespageState extends State<Expensespage> {
  List<ExpenseDetailsss> _expenses = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  late List<bool> isExpandedList = [];
  final ScrollController _scrollController = ScrollController();
  int _pendingExpensesCount = 0;

  @override
  void initState() {
    super.initState();
    // _fetchPendingExpenses();
    _fetchExpenses();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading &&
          _hasMore) {
        _fetchExpenses();
      }
    });
  }

  Future<void> _fetchExpenses() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    final url =
        "${RestDatasource().BASE_URL}/api/get_expense_detail.api?store_id=${AppState().storeId}&user_id=${AppState().userId}&page=$_currentPage";

    try {
      print("Fetching data for page $_currentPage...");
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.request);
        print(response.body);

        final jsonData = json.decode(response.body);
        final expenseResponse = ExpenseResponse.fromJson(jsonData);
        isExpandedList.addAll(
            List.generate(expenseResponse.data.length, (index) => false));

        setState(() {
          _expenses.addAll(expenseResponse.data);
          _hasMore = _currentPage < expenseResponse.pagination.lastPage;
          if (_hasMore) {
            _currentPage++;
          } else {
            print("No more data to load.");
          }
        });
      } else {
        print("Failed to fetch data: ${response.statusCode}");
        throw Exception("Failed to load data");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Formats a raw amount string using the store's configured number of
  // decimals (AppState().noOfDecimals), same as the Receipt / Sales
  // Invoice screens, instead of the hardcoded 2 decimals that were
  // baked into the API response earlier.
  String _formatAmount(String? value) {
    final double parsed = double.tryParse(value ?? '') ?? 0;
    return parsed.toStringAsFixed(AppState().noOfDecimals ?? 2);
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
          'Expenses',
          style: AppConfig.pageTitleStyle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExpenseAdd()),
                );
              },
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: _expenses.isEmpty && _isLoading
          ? Center(
              child: Shimmer.fromColors(
                baseColor: AppConfig.buttonDeactiveColor.withOpacity(0.1),
                highlightColor: AppConfig.backButtonColor,
                child: ListView.builder(
                  itemCount: 6,
                  itemBuilder: (context, index) =>
                      CommonWidgets.loadingContainers(
                    height: SizeConfig.blockSizeVertical * 10,
                    width: SizeConfig.blockSizeHorizontal * 90,
                  ),
                ),
              ),
            )
          : _expenses.isEmpty
              ? Center(
                  child: Text(
                    'No data found',
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _expenses.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _expenses.length) {
                      return Center(child: CircularProgressIndicator());
                    }
                    var expenseDetail = _expenses[index];

                    // Only build remarks text when there is an actual
                    // reason on record. No placeholder text like "No
                    // rejection reason provided" — if there's nothing to
                    // show, the whole Remarks row is skipped below.
                    String? detailText;
                    if (expenseDetail.status == 'Approved' &&
                        (expenseDetail.approvedReason ?? '').isNotEmpty) {
                      detailText = expenseDetail.approvedReason;
                    } else if (expenseDetail.status == 'Rejected' &&
                        (expenseDetail.rejectedReason ?? '').isNotEmpty) {
                      detailText = expenseDetail.rejectedReason;
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          isExpandedList[index] = !isExpandedList[index];
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppConfig.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            // Was: '${expenseDetail.inDate} | ...'
                                            // Now goes through DateHelper so it
                                            // follows the store's configured
                                            // date_format, same as
                                            // TestInvoice / Attendance /
                                            // Cheque_Receipt / Customerorderdetail.
                                            '${DateHelper.displayDate(expenseDetail.inDate)} | ${expenseDetail.invoiceNo ?? ""}',
                                            style: TextStyle(
                                              fontSize:
                                                  AppConfig.textCaption3Size,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Amount : ${_formatAmount(expenseDetail.amount)}',
                                            style: TextStyle(
                                              fontSize:
                                                  AppConfig.textCaption3Size,
                                            ),
                                          ),
                                          Text(
                                            'Vat Amount : ${_formatAmount(expenseDetail.vatAmount)}',
                                            style: TextStyle(
                                              fontSize:
                                                  AppConfig.textCaption3Size,
                                            ),
                                          ),
                                          Text(
                                            'Total Amount : ${_formatAmount(expenseDetail.totalAmount)}',
                                            style: TextStyle(
                                              fontSize:
                                                  AppConfig.textCaption3Size,
                                            ),
                                          ),
                                          Text(
                                            '${expenseDetail.expense.isNotEmpty ? expenseDetail.expense[0].name : ""} ${expenseDetail.description == '' ? '' : '| ${expenseDetail.description}'}',
                                            style: TextStyle(
                                              fontSize:
                                                  AppConfig.textCaption3Size,
                                            ),
                                          ),
                                          if (detailText != null)
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Remarks: ",
                                                  style: TextStyle(
                                                    fontSize: AppConfig
                                                        .textCaption3Size,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: Text(
                                                      detailText,
                                                      overflow:
                                                          TextOverflow.clip,
                                                      style: TextStyle(
                                                        fontSize: AppConfig
                                                            .textCaption3Size,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      expenseDetail.status,
                                      style: TextStyle(
                                        fontSize: AppConfig.textCaption3Size,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isExpandedList[index])
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Column(
                                      children: [
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: expenseDetail.documents
                                              .map((document) {
                                            return Image.network(
                                              '${RestDatasource().BASE_URL}/uploads/expense/${document.documentName}',
                                              height: 100,
                                              width: 100,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.broken_image,
                                                  size: 100,
                                                  color: Colors.grey,
                                                );
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class ExpenseResponse {
  final bool success;
  final List<ExpenseDetailsss> data;
  final PaginationInfo pagination;

  ExpenseResponse({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory ExpenseResponse.fromJson(Map<String, dynamic> json) {
    return ExpenseResponse(
      success: json['success'],
      data: (json['data']['data'] as List)
          .map((e) => ExpenseDetailsss.fromJson(e))
          .toList(),
      pagination: PaginationInfo.fromJson(json['data']),
    );
  }
}

class ExpenseDetailsss {
  int id;
  String? invoiceNo;
  String inDate;
  String inTime;
  int expenseId;
  String amount; // Changed from int to String
  String vatAmount; // Changed from int to String
  String totalAmount; // Changed from int to String
  String description;
  String status;
  String? rejectedReason;
  String? approvedReason;
  int storeId;
  int vanId;
  int userId;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;
  List<Expense> expense;
  List<Document> documents;

  ExpenseDetailsss({
    required this.id,
    this.invoiceNo,
    required this.inDate,
    required this.inTime,
    required this.expenseId,
    required this.amount,
    required this.totalAmount,
    required this.vatAmount,
    required this.description,
    required this.status,
    this.rejectedReason,
    this.approvedReason,
    required this.storeId,
    required this.vanId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.expense,
    required this.documents,
  });

  factory ExpenseDetailsss.fromJson(Map<String, dynamic> json) {
    return ExpenseDetailsss(
      id: json['id'],
      invoiceNo: json['invoice_no'],
      inDate: json['in_date'],
      inTime: json['in_time'],
      expenseId: json['expense_id'],
      amount: json['amount'], // Keep as String
      vatAmount: json['vat_amount'], // Keep as String
      totalAmount: json['total_amount'], // Keep as String
      description: json['description'] ?? "",
      status: json['status'],
      rejectedReason: json['rejected_reason'],
      approvedReason: json['approved_reason'],
      storeId: json['store_id'],
      vanId: json['van_id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
      expense:
          (json['expense'] as List).map((e) => Expense.fromJson(e)).toList(),
      documents:
          (json['documents'] as List).map((e) => Document.fromJson(e)).toList(),
    );
  }
}

class Expense {
  int id;
  String name;
  String? description;
  int storeId;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;

  Expense({
    required this.id,
    required this.name,
    this.description,
    required this.storeId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      name: json['name'] ?? "",
      description: json['description'],
      storeId: json['store_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
    );
  }
}

class Document {
  int id;
  int expenseDetailId;
  String documentName;
  int storeId;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;

  Document({
    required this.id,
    required this.expenseDetailId,
    required this.documentName,
    required this.storeId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      expenseDetailId: json['expense_detail_id'],
      documentName: json['document_name'],
      storeId: json['store_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final String? nextPageUrl;
  final String? prevPageUrl;

  PaginationInfo({
    required this.currentPage,
    required this.lastPage,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      nextPageUrl: json['next_page_url'],
      prevPageUrl: json['prev_page_url'],
    );
  }
}