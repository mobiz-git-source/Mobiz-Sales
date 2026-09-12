import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'package:mobizapp/confg/appconfigjc.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../Models/appstate.dart';
import '../../Utilities/date_helper.dart';
class BankReconciliationScreen extends StatefulWidget {
  static const routeName = "/BankReconciliation";

  const BankReconciliationScreen({super.key});

  @override
  State<BankReconciliationScreen> createState() => _BankReconciliationScreenState();
}

class _BankReconciliationScreenState extends State<BankReconciliationScreen> {
  List<dynamic> payments = [];
  List<dynamic> receipts = [];
  bool isLoading = true;
  String errorMessage = '';
  TextEditingController _searchController = TextEditingController();
  List<dynamic> filteredReceipts = [];
  bool _isSearching = false;
  DateTime fromDate = DateTime.now().subtract(Duration(days: 30));
  DateTime toDate = DateTime.now();
  Map<String, dynamic>? apiData;




  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://68.183.92.8:3699/api/bank-reconciliation?store_id=${AppState().storeId}&user_id=${AppState().userId}'),
      );

      if (response.statusCode == 200) {
        apiData = json.decode(response.body);
        setState(() {
          payments = apiData!['payments'] ?? [];
          receipts = [
            ...apiData!['receipt_collection'] ?? [],
            ...apiData!['receipt_collection_group'] ?? [],
            ...apiData!['receipt_collection_individual'] ?? [],
          ];
          filteredReceipts = receipts;
          isLoading = false;
        });

      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

 String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    return DateHelper.displayDate(dateString);
  }

  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    if (amount is num) return amount.toStringAsFixed(AppState().noOfDecimals ?? 2);
    if (amount is String) {
      try {
        return double.parse(amount).toStringAsFixed(AppState().noOfDecimals ?? 2);
      } catch (e) {
        return amount;
      }
    }
    return amount.toString();
  }

  Future<void> _generateReceiptsPdf(List<dynamic> receiptsToPrint) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Bank Reconciliation Report - ${_searchController.text.isNotEmpty ? 'Search Results' : 'All Receipts'}',
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildReceiptsPdfTable(receiptsToPrint),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName = _searchController.text.isNotEmpty
        ? "Bank Reconciliation - Search Results.pdf"
        : "Bank Reconciliation - All Receipts.pdf";
    final file = File("${output.path}/$fileName");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  Future<void> _generateAndSharePdf() async {
    await _generateReceiptsPdf(receipts);
  }
  Future<void> _generateFilteredPdf() async {
    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please perform a search first'))
      );
      return;
    }

    await _generateReceiptsPdf(filteredReceipts);
  }

  pw.Widget _buildReceiptsPdfTable(List<dynamic> receiptsToPrint) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(2),
        5: pw.FlexColumnWidth(2),
        6: pw.FlexColumnWidth(1.5),
        7: pw.FlexColumnWidth(1.8),
      },
      children: [
        // Table Header
        pw.TableRow(
          children: [
            pw.Padding(
              child: pw.Text('From',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              padding: pw.EdgeInsets.all(4),
            ),
            pw.Padding(
              child: pw.Text('To',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              padding: pw.EdgeInsets.all(4),
            ),
            pw.Padding(
              child: pw.Text('Type',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              padding: pw.EdgeInsets.all(4),
            ),
            pw.Padding(
              child: pw.Text('Date',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              padding: pw.EdgeInsets.all(4),
            ),
            pw.Padding(
              child: pw.Text('Reference',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              padding: pw.EdgeInsets.all(4),
            ),
            pw.Padding(
              child: pw.Text('Amount',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              padding: pw.EdgeInsets.all(4),
            ),
            pw.Padding(
              child: pw.Text('Cheque No',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              padding: pw.EdgeInsets.all(4),
            ),
            pw.Padding(
              child: pw.Text('Cheque Date',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              padding: pw.EdgeInsets.all(4),
            ),
          ],
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
        ),
        // Data Rows
        ...(receipts ?? []).map((receipt) => pw.TableRow(
          children: [
            pw.Padding(
              child: pw.Text(receipt['customer']?['name']?.toString() ??
                  receipt['group']?['name']?.toString() ?? 'N/A'),
              padding: pw.EdgeInsets.all(4),
            ),
            pw.Padding(
              child: pw.Text(receipt['to_type']?.toString() ?? 'N/A'),
              padding: pw.EdgeInsets.all(4),
            ),
            pw.Padding(
              child: pw.Text(receipt['payment_type']?.toString() ?? 'N/A'),
              padding: pw.EdgeInsets.all(4),
            ),
            pw.Padding(
              child: pw.Text(_formatDate(receipt['in_date'] ?? 'N/A')),
              padding: pw.EdgeInsets.all(4),
            ),
            pw.Padding(
              child: pw.Text(receipt['reference_no']?.toString() ?? 'N/A'),
              padding: pw.EdgeInsets.all(4),
            ),
            pw.Padding(
              child: pw.Text(_formatAmount(receipt['amount'])),
              padding: pw.EdgeInsets.all(4),
            ),
            pw.Padding(
              child: pw.Text(receipt['cheque_no']?.toString() ?? 'N/A'),
              padding: pw.EdgeInsets.all(4),
            ),
         pw.Padding(
              child: pw.Text(DateHelper.displayDate(receipt['cheque_date']?.toString())),
              padding: pw.EdgeInsets.all(4),
            ),
          ],
        )).toList(),
      ],
    );
  }

  void _filterReceipts(String query) {
    setState(() {
      filteredReceipts = receipts.where((receipt) {
        final customerName = receipt['customer']?['name']?.toLowerCase() ?? '';
        final reference = receipt['reference_no']?.toLowerCase() ?? '';
        return customerName.contains(query.toLowerCase()) ||
            reference.contains(query.toLowerCase());
      }).toList();
    });
  }

  void applyFilters() {
    if (apiData == null) return;

    final searchText = _searchController.text.toLowerCase();
    final formattedFromDate = fromDate;
    final formattedToDate = toDate;

    // // Filter payments
    // if (apiData?['payments'] != null) {
    //   paymentsData = (apiData?['payments'] as List).where((payment) {
    //     final matchesSearch = payment['reference_no']?.toString().toLowerCase().contains(searchText) ?? false;
    //     final paymentDate = DateTime.tryParse(payment['in_date'] ?? '');
    //
    //     bool dateInRange = true;
    //     if (paymentDate != null) {
    //       dateInRange = (paymentDate.isAfter(formattedFromDate.subtract(Duration(days: 1))) &&
    //           paymentDate.isBefore(formattedToDate.add(Duration(days: 1))));
    //     }
    //
    //     return matchesSearch && dateInRange;
    //   }).toList();
    // }

    // Filter receipts
    receipts = [
      ...(apiData?['receipt_collection'] ?? []).where((receipt) {
        final matchesSearch = receipt['reference_no']?.toString().toLowerCase().contains(searchText) ?? false;
        final receiptDate = DateTime.tryParse(receipt['in_date'] ?? '');

        bool dateInRange = true;
        if (receiptDate != null) {
          dateInRange = (receiptDate.isAfter(formattedFromDate.subtract(Duration(days: 1))) &&
              receiptDate.isBefore(formattedToDate.add(Duration(days: 1))));
        }

        return matchesSearch && dateInRange;
      }).toList(),
      ...(apiData?['receipt_collection_group'] ?? []).where((receipt) {
        final matchesSearch = receipt['reference_no']?.toString().toLowerCase().contains(searchText) ?? false;
        final receiptDate = DateTime.tryParse(receipt['in_date'] ?? '');

        bool dateInRange = true;
        if (receiptDate != null) {
          dateInRange = (receiptDate.isAfter(formattedFromDate.subtract(Duration(days: 1))) &&
              receiptDate.isBefore(formattedToDate.add(Duration(days: 1))));
        }

        return matchesSearch && dateInRange;
      }).toList(),
      ...(apiData?['receipt_collection_individual'] ?? []).where((receipt) {
        final matchesSearch = receipt['reference_no']?.toString().toLowerCase().contains(searchText) ?? false;
        final receiptDate = DateTime.tryParse(receipt['in_date'] ?? '');

        bool dateInRange = true;
        if (receiptDate != null) {
          dateInRange = (receiptDate.isAfter(formattedFromDate.subtract(Duration(days: 1))) &&
              receiptDate.isBefore(formattedToDate.add(Duration(days: 1))));
        }

        return matchesSearch && dateInRange;
      }).toList(),
    ];

    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppConfig.colorPrimary,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by name or reference...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white60),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _filterReceipts,
        )
            : const Text('PDC', style: AppConfig.pageTitleStyle,),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  filteredReceipts = receipts;
                }
              });
            },
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : SingleChildScrollView(
        child: Column(
          children: [
            // Payments Section
            if (payments.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Payments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ...payments.map((payment) => _buildPDCCard(payment, 'Payment')),
              const Divider(),
            ],

            // Receipts Section
            if (receipts.isNotEmpty) ...[
               Padding(
                padding: EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Receipts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _searchController.text.isNotEmpty ?
                        IconButton(
                          icon: Icon(Icons.document_scanner, color: Colors.blue),
                          onPressed: _generateFilteredPdf,
                          tooltip: 'Export search results',
                        ):
                      IconButton(
                        icon: Icon(Icons.document_scanner, color: Colors.red),
                        onPressed: _generateAndSharePdf,
                        tooltip: 'Export all receipts',
                      ),
                    ],
                  ),
                ),
              ),
              ...filteredReceipts.map((receipt) => _buildPDCCard(receipt, 'Receipt')),
            ],

            if (payments.isEmpty && receipts.isEmpty)
              const Center(child: Text('No PDC records found')),
          ],
        ),
      ),
    );
  }

  Widget _buildPDCCard(Map<String, dynamic> item, String type) {
    final customerName = item['customer']?['name'] ?? item['group']?['name'] ?? 'N/A';
    final bank = item['bank'] ?? 'N/A';
    final amount = _formatAmount(item['amount']);
    final referenceNo = item['reference_no'] ?? 'N/A';
    final chequeNo = item['cheque_no'] ?? 'N/A';
    final chequeDate = _formatDate(item['cheque_date']);
    final inDate = _formatDate(item['in_date']);
    final inTime = _formatTime(item['created_at']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header line
                Text(
                  '$referenceNo | $inDate  $inTime',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),

                // Customer name
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Bank
                Text(
                  bank,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Amount
                Text(
                  'Amount $amount',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Cheque details
                Text(
                  '$chequeNo | $chequeDate',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: type == 'Payment' ? Colors.red : Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}