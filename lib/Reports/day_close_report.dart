// Reports/day_close_report.dart
//
// Day Close Outstanding Report, drawn once for every printer.
// Replaces _printZebra() / _printSewoo() in DayReport.dart.
// No store logo involved here — this is a text-only summary report.

import '../Models/appstate.dart';
import '../Models/DayReport.dart';
import '../Utilities/date_helper.dart';
import '../Utilities/report_printer.dart';

void drawDayCloseReport(ImageReportBuilder b, DayCloseOutstandingReport report) {
  final dec = AppState().noOfDecimals ?? 2;
  final bool wide = b.widthDots >= 800;
  final double normal = wide ? 24 : 22;
  final double large = wide ? 32 : 28;

  double totalSales = report.sales != null && report.sales!.isNotEmpty
      ? report.sales!
          .map((s) => double.tryParse(s.grandTotal.toString()) ?? 0.0)
          .reduce((a, c) => a + c)
      : 0.0;

  double totalSalesreturn = report.salesReturn != null && report.salesReturn!.isNotEmpty
      ? report.salesReturn!
          .map((r) => double.tryParse(r.grandTotal.toString()) ?? 0.0)
          .reduce((a, c) => a + c)
      : 0.0;

  double totalCollections = report.collection != null && report.collection!.isNotEmpty
      ? report.collection!
          .map((c) => double.tryParse(c.totalAmount.toString()) ?? 0.0)
          .reduce((a, c) => a + c)
      : 0.0;

  double totalExpenses = report.expense != null && report.expense!.isNotEmpty
      ? report.expense!
          .map((e) => double.tryParse(e.amount.toString()) ?? 0.0)
          .reduce((a, c) => a + c)
      : 0.0;

  // ---- 1. Header info ----
  b.text('DAY CLOSE REPORT', size: large - 2, bold: true, align: PAlign.center);
  b.divider();
  b.row([
    Col('Salesman: ${report.data?.user ?? "N/A"}', flex: 3),
    Col(
      'Date: ${report.data?.date != null ? DateHelper.displayDate(report.data!.date) : "No Date"}',
      flex: 2,
      align: PAlign.right,
    ),
  ], size: normal);
  b.row([
    Col('VAN: ${report.data?.van ?? "N/A"}', flex: 3),
    Col('Petty Cash: ${report.data?.pettyCash ?? 0}', flex: 2, align: PAlign.right),
  ], size: normal);
  b.divider();

  // ---- Shared 4-column section builder ----
  void section(
    String title,
    List items, {
    required String Function(dynamic) shopName,
    required String Function(dynamic) refOrType,
    required num Function(dynamic) amount,
    required String totalLabel,
    required double total,
  }) {
    if (items.isEmpty) return;
    b.text(title, size: large - 4, bold: true);
    b.divider(thickness: 1, spacing: 2);
    b.row([
      Col('Sl', flex: 2),
      Col('Shop Name / Ref', flex: 9),
      Col('Amount', flex: 4, align: PAlign.right),
    ], size: normal - 2, bold: true);
    b.divider(thickness: 1, spacing: 2);
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      b.row([Col('${i + 1}', flex: 2), Col(shopName(it), flex: 13)], size: normal - 2, bold: true);
      b.row([
        Col('', flex: 2),
        Col(refOrType(it), flex: 9),
        Col(amount(it).toStringAsFixed(dec), flex: 4, align: PAlign.right),
      ], size: normal - 2);
    }
    b.divider();
    b.row([
      Col('', flex: 3),
      Col('$totalLabel: ${total.toStringAsFixed(dec)}', flex: 2, align: PAlign.right),
    ], size: normal, bold: true);
    b.feed(10);
  }

  // ---- 2. Sales ----
  section(
    'SALES',
    report.sales ?? [],
    shopName: (s) => s.customer?.map((c) => c.name).join(", ") ?? 'No Customer',
    refOrType: (s) => '[${s.invoiceNo ?? 'N/A'}]',
    amount: (s) => s.grandTotal ?? 0,
    totalLabel: 'Total Sales',
    total: totalSales,
  );

  // ---- 3. Sales Return ----
  section(
    'SALES RETURN',
    report.salesReturn ?? [],
    shopName: (r) => r.customer?.map((c) => c.name).join(", ") ?? 'No Customer',
    refOrType: (r) => '[${r.invoiceNo ?? 'No Ref'}]',
    amount: (r) => r.grandTotal ?? 0,
    totalLabel: 'Total Return',
    total: totalSalesreturn,
  );

  // ---- 4. Collection ----
  section(
    'COLLECTION',
    report.collection ?? [],
    shopName: (c) => c.customer?.map((cu) => cu.name).join(", ") ?? 'No Customer',
    refOrType: (c) => 'Type: ${c.collectionType ?? 'Cash'}',
    amount: (c) => double.tryParse(c.totalAmount ?? '0') ?? 0,
    totalLabel: 'Total Collection',
    total: totalCollections,
  );

  // ---- 5. Expense ----
  if ((report.expense ?? []).isNotEmpty) {
    b.text('EXPENSE', size: large - 4, bold: true);
    b.divider(thickness: 1, spacing: 2);
    b.row([
      Col('Sl', flex: 2),
      Col('Expense / Remarks', flex: 9),
      Col('Amount', flex: 4, align: PAlign.right),
    ], size: normal - 2, bold: true);
    b.divider(thickness: 1, spacing: 2);
    for (int i = 0; i < report.expense!.length; i++) {
      final e = report.expense![i];
      final expenseName = e.expense?.map((x) => x.name).join(", ") ?? 'Expense';
      final ref = e.invoiceNo ?? 'N/A';
      final remarks = (e.description != null && e.description!.isNotEmpty)
          ? '($ref - ${e.description})'
          : '($ref)';
      final amt = double.tryParse(e.amount ?? '0') ?? 0;
      b.row([Col('${i + 1}', flex: 2), Col(expenseName, flex: 13)], size: normal - 2, bold: true);
      b.row([
        Col('', flex: 2),
        Col(remarks, flex: 9),
        Col(amt.toStringAsFixed(dec), flex: 4, align: PAlign.right),
      ], size: normal - 2);
    }
    b.divider();
    b.row([
      Col('', flex: 3),
      Col('Total Expenses: ${totalExpenses.toStringAsFixed(dec)}', flex: 2, align: PAlign.right),
    ], size: normal, bold: true);
    b.feed(10);
  }

  // ---- 6. Net cash balance ----
  if (report.data?.netCashBalance != null) {
    b.text(
      'Net Cash Balance: ${report.data!.netCashBalance!.toStringAsFixed(dec)}',
      size: large - 2,
      bold: true,
    );
  }
  b.feed(10);
  b.text('--- THANK YOU ---', size: normal, align: PAlign.center);
  b.feed(30);
}