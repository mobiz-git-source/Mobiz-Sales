import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import '../../Models/appstate.dart';

class AgeingSummaryScreen extends StatefulWidget {
  static const routeName = "/AgeingSummaryScreen";

  const AgeingSummaryScreen({super.key});

  @override
  State<AgeingSummaryScreen> createState() => _AgeingSummaryScreenState();
}

class _AgeingSummaryScreenState extends State<AgeingSummaryScreen> {
  List<dynamic> customers = [];
  Map<String, dynamic>? apiData;
  Map<String, dynamic>? filteredData;
  double totalOutstanding = 0.0;
  bool isLoading = true;
  String errorMessage = '';
  TextEditingController customerSearchController = TextEditingController();
  DateTime asOnDate = DateTime.now();
  String reportType = 'All';

  @override
  void initState() {
    super.initState();
    _fetchAgeingData();
  }

  Future<void> _fetchAgeingData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://68.183.92.8:3699/api/aging-report?store_id=${AppState().storeId}&user_id=${AppState().userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            apiData = data;
            filteredData = json.decode(json.encode(data)); // Deep copy
            customers = filteredData?['data'] ?? [];
            totalOutstanding = _parseAmount(filteredData?['grand_totals']?['balance'] ?? 0);
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load ageing data');
        }
      } else {
        throw Exception('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void applyFilters() {
    if (apiData == null) return;

    final searchText = customerSearchController.text.toLowerCase();
    final formattedAsOnDate = asOnDate;
    final dataCopy = json.decode(json.encode(apiData)) as Map<String, dynamic>;

    if (dataCopy['data'] != null) {
      dataCopy['data'] = (dataCopy['data'] as List).where((customer) {
        final nameMatches = customer['name']?.toString().toLowerCase().contains(searchText) ?? false;
        final balance = customer['total']?['balance'] as num? ?? 0;

        bool typeMatches = false;
        if (reportType == 'All') {
          typeMatches = true;
        } else if (reportType == 'Receivable') {
          typeMatches = balance > 0;
        } else if (reportType == 'Payable') {
          typeMatches = balance < 0;
        }

        return nameMatches && typeMatches;
      }).toList();

      for (var customer in dataCopy['data']) {
        if (customer['invoices'] != null) {
          customer['invoices'] = (customer['invoices'] as List).where((invoice) {
            try {
              final invoiceDate = DateTime.parse(invoice['invoice_date']);
              return invoiceDate.isBefore(formattedAsOnDate.add(const Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();

          final total = {
            '0_30': 0.0,
            '31_60': 0.0,
            '61_90': 0.0,
            '91_120': 0.0,
            '120_plus': 0.0,
            'balance': 0.0,
          };

          if (customer['invoices'].isNotEmpty) {
            for (var invoice in customer['invoices']) {
              final unpaid = invoice['unpaid'] is num
                  ? (invoice['unpaid'] as num).toDouble()
                  : 0.0;
              final bucket = invoice['bucket']?.toString() ?? '';

              if (bucket == '0_30') total['0_30'] = total['0_30']! + unpaid;
              else if (bucket == '31_60') total['31_60'] = total['31_60']! + unpaid;
              else if (bucket == '61_90') total['61_90'] = total['61_90']! + unpaid;
              else if (bucket == '91_120') total['91_120'] = total['91_120']! + unpaid;
              else if (bucket == '120_plus') total['120_plus'] = total['120_plus']! + unpaid;

              total['balance'] = total['balance']! + unpaid;
            }
          }

          customer['total'] = total;
        }
      }

      // Recalculate grand totals
      final grandTotals = {
        '0_30': 0.0,
        '31_60': 0.0,
        '61_90': 0.0,
        '91_120': 0.0,
        '120_plus': 0.0,
        'balance': 0.0,
      };

      for (var customer in dataCopy['data']) {
        if (customer['total'] != null) {
          grandTotals['0_30'] = grandTotals['0_30']! + (customer['total']['0_30'] as num?)!.toDouble();
          grandTotals['31_60'] = grandTotals['31_60']! + (customer['total']['31_60'] as num?)!.toDouble();
          grandTotals['61_90'] = grandTotals['61_90']! + (customer['total']['61_90'] as num?)!.toDouble();
          grandTotals['91_120'] = grandTotals['91_120']! + (customer['total']['91_120'] as num?)!.toDouble();
          grandTotals['120_plus'] = grandTotals['120_plus']! + (customer['total']['120_plus'] as num?)!.toDouble();
          grandTotals['balance'] = grandTotals['balance']! + (customer['total']['balance'] as num?)!.toDouble();
        }
      }

      dataCopy['grand_totals'] = grandTotals;
    }

    setState(() {
      filteredData = dataCopy;
      customers = filteredData?['data'] ?? [];
      totalOutstanding = _parseAmount(filteredData?['grand_totals']?['balance'] ?? 0);
    });
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return 0.0;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount is num) {
      return amount.toStringAsFixed(AppState().noOfDecimals ?? 2);
    }
    return amount?.toString() ?? '0.00';
  }

  String _formatDisplayDate(String? apiDate) {
    if (apiDate == null) return 'N/A';
    try {
      final parsedDate = DateTime.parse(apiDate);
      return DateFormat('dd MMM yy').format(parsedDate);
    } catch (e) {
      return apiDate;
    }
  }

  Future<void> _generateAndSharePdf() async {
    if (filteredData == null) return;

    final pdf = pw.Document();
    List<pw.TableRow> _buildPdfDataRows() {
      List<pw.TableRow> rows = [];

      if (filteredData == null || filteredData!['data'] == null) return rows;

      for (var customer in filteredData!['data']) {
        rows.add(pw.TableRow(
          children: [
            pw.Padding(
              child: pw.Text(customer['name'] ?? '',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              padding: pw.EdgeInsets.all(4),
            ),
            pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
            pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
            pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
            pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
            pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
            pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
            pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
            pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
            pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
          ],
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
        ));

        // Invoice rows
        if (customer['invoices'] != null) {
          for (var invoice in customer['invoices']) {
            rows.add(pw.TableRow(
              children: [
                pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
                pw.Padding(
                  child: pw.Text(invoice['invoice_no'] ?? ''),
                  padding: pw.EdgeInsets.all(4),
                ),
                pw.Padding(
                  child: pw.Text(_formatDate(invoice['invoice_date'] ?? '')),
                  padding: pw.EdgeInsets.all(4),
                ),
                pw.Padding(
                  child: pw.Text(invoice['days']?.toString() ?? ''),
                  padding: pw.EdgeInsets.all(4),
                ),
                pw.Padding(
                  child: pw.Text(invoice['bucket'] == '0_30'
                      ? _formatAmount(invoice['unpaid'])
                      : ''),
                  padding: pw.EdgeInsets.all(4),
                ),
                pw.Padding(
                  child: pw.Text(invoice['bucket'] == '31_60'
                      ? _formatAmount(invoice['unpaid'])
                      : ''),
                  padding: pw.EdgeInsets.all(4),
                ),
                pw.Padding(
                  child: pw.Text(invoice['bucket'] == '61_90'
                      ? _formatAmount(invoice['unpaid'])
                      : ''),
                  padding: pw.EdgeInsets.all(4),
                ),
                pw.Padding(
                  child: pw.Text(invoice['bucket'] == '91_120'
                      ? _formatAmount(invoice['unpaid'])
                      : ''),
                  padding: pw.EdgeInsets.all(4),
                ),
                pw.Padding(
                  child: pw.Text(invoice['bucket'] == '120_plus'
                      ? _formatAmount(invoice['unpaid'])
                      : ''),
                  padding: pw.EdgeInsets.all(4),
                ),
                pw.Padding(
                  child: pw.Text(_formatAmount(invoice['unpaid'])),
                  padding: pw.EdgeInsets.all(4),
                ),
              ],
            ));
          }
        }

        // Customer total row
        if (customer['total'] != null) {
          rows.add(pw.TableRow(
            children: [
              pw.Padding(
                child: pw.Text('Total for ${customer['name']}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
              pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
              pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
              pw.Padding(
                child: pw.Text(_formatAmount(customer['total']['0_30'])),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text(_formatAmount(customer['total']['31_60'])),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text(_formatAmount(customer['total']['61_90'])),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text(_formatAmount(customer['total']['91_120'])),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text(_formatAmount(customer['total']['120_plus'])),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text(_formatAmount(customer['total']['balance']),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                padding: pw.EdgeInsets.all(4),
              ),
            ],
            decoration: pw.BoxDecoration(color: PdfColors.grey200),
          ));
        }

        // Divider
        rows.add(pw.TableRow(
          children: List.generate(10,
                  (index) => pw.Container(height: 1, color: PdfColors.grey400)),
        ));
      }

      return rows;
    }

    pw.Widget _buildPdfGrandTotals() {
      return pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: {
          0: pw.FlexColumnWidth(3),
          1: pw.FlexColumnWidth(1.5),
          2: pw.FlexColumnWidth(1.5),
          3: pw.FlexColumnWidth(1),
          4: pw.FlexColumnWidth(1.5),
          5: pw.FlexColumnWidth(1.5),
          6: pw.FlexColumnWidth(1.5),
          7: pw.FlexColumnWidth(1.5),
          8: pw.FlexColumnWidth(1.5),
          9: pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                child: pw.Text('Grand Total',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
              pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
              pw.Padding(child: pw.Text(''), padding: pw.EdgeInsets.all(4)),
              pw.Padding(
                child: pw.Text(
                    _formatAmount(filteredData!['grand_totals']['0_30'])),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text(
                    _formatAmount(filteredData!['grand_totals']['31_60'])),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text(
                    _formatAmount(filteredData!['grand_totals']['61_90'])),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text(
                    _formatAmount(filteredData!['grand_totals']['91_120'])),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text(
                    _formatAmount(filteredData!['grand_totals']['120_plus'])),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text(
                    _formatAmount(filteredData!['grand_totals']['balance']),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                padding: pw.EdgeInsets.all(4),
              ),
            ],
            decoration: pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      );
    }

    pw.Widget _buildPdfTable() {
      return pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: {
          0: pw.FlexColumnWidth(3),
          1: pw.FlexColumnWidth(1.5),
          2: pw.FlexColumnWidth(1.6),
          3: pw.FlexColumnWidth(1),
          4: pw.FlexColumnWidth(1.5),
          5: pw.FlexColumnWidth(1.5),
          6: pw.FlexColumnWidth(1.5),
          7: pw.FlexColumnWidth(1.5),
          8: pw.FlexColumnWidth(1.5),
          9: pw.FlexColumnWidth(2),
        },
        children: [
          // Table Header
          pw.TableRow(
            children: [
              pw.Padding(
                child: pw.Text('Customer Name',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text('Invoice No',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text('Invoice Date',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text('Days',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text('0-30',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text('31-60',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text('61-90',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text('91-120',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text('120+',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                padding: pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                child: pw.Text('Balance',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                padding: pw.EdgeInsets.all(4),
              ),
            ],
            decoration: pw.BoxDecoration(color: PdfColors.grey300),
          ),
          ..._buildPdfDataRows(),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Ageing Summary Report',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    'As on: ${asOnDate.day.toString().padLeft(2, '0')}/${asOnDate.month.toString().padLeft(2, '0')}/${asOnDate.year}'),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Text('Report Type: $reportType'),
              // pw.SizedBox(width: 20),
              // if (customerSearchController.text.isNotEmpty)
              //   pw.Text('Search: ${customerSearchController.text}'),
            ],
          ),
          pw.SizedBox(height: 20),
          _buildPdfTable(),
          if (filteredData!['grand_totals'] != null) ...[
            pw.SizedBox(height: 20),
            pw.Text('Grand Totals',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildPdfGrandTotals(),
          ],
        ],
      ),
    );
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Ageing Summary.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(iconTheme: IconThemeData(color: Colors.white),
        title:Text('Ageing Report',style: TextStyle(color: Colors.white),),
        backgroundColor: AppConfig.colorPrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : customers.isEmpty
          ? const Center(child: Text('No customers found'))
          : Column(
        children: [
          // Filter controls
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 300, // Fixed width or use MediaQuery
                    child: TextFormField(
                      controller: customerSearchController,
                      decoration: InputDecoration(
                        labelText: 'Search Customer',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: applyFilters,
                        ),
                      ),
                      onChanged: (value) => applyFilters(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: reportType,
                      items: ['All', 'Receivable', 'Payable']
                          .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          reportType = value!;
                        });
                        applyFilters();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Report Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 200,
                    child: GestureDetector(
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: asOnDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            asOnDate = selectedDate;
                          });
                          applyFilters();
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'As on Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text: '${asOnDate.day.toString().padLeft(2, '0')}/${asOnDate.month.toString().padLeft(2, '0')}/${asOnDate.year}',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total Outstanding ${_formatAmount(totalOutstanding)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                  onPressed: () => _generateAndSharePdf(),
                  icon: Icon(
                    Icons.document_scanner,
                    color: Colors.red,
                  )),
            ],
          ),

          // Customers List
          Expanded(
            child: ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                final invoices = customer['invoices'] as List<dynamic>? ?? [];
                final balance = _parseAmount(customer['total']?['balance'] ?? 0);

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10,),
                  child: Card(
                    color: AppConfig.backgroundColor,
                    child: ExpansionTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: AppConfig.backgroundColor,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer['name'] ?? 'Unknown Customer',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Text(
                          //   '${customer['payment_type'] ?? ''}${customer['credit_days'] != null ? ' | ${customer['credit_days']} Days' : ''}',
                          //   style: TextStyle(
                          //     color: Colors.blue[700],
                          //   ),
                          // ),
                          SizedBox(height: 5,),
                          Text(
                            'Balance ${_formatAmount(balance)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: balance >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            children: [
                              const Divider(),
                              ...List.generate(invoices.length, (index) {
                                final invoice = invoices[index];
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${_formatDisplayDate(invoice['invoice_date'])} | ${invoice['invoice_no'] ?? 'N/A'}',
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Amount ${_formatAmount(_parseAmount(invoice['amount']))}',
                                              ),
                                              Text(
                                                'Days ${invoice['days'] ?? 'N/A'}',
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (index < invoices.length - 1) const Divider(), // 🔹 Add divider except for the last item
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}