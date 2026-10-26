// Reports/day_report_report.dart
//
// Day Close report drawn with the shared image pipeline (report_printer.dart /
// image_report_printer.dart), replacing the old manual-padding CpclBuilder
// table layout in DayReport.dart's _printZebra().

import '../Models/appstate.dart';
import '../Models/DayReport.dart';
import '../Utilities/date_helper.dart';
import '../Utilities/report_printer.dart';

void drawDayReport(ImageReportBuilder b, DayCloseOutstandingReport report) {
  final decimals = AppState().noOfDecimals ?? 2;
  String money(num? v) => (v ?? 0).toStringAsFixed(decimals);

  double sumOf(Iterable<num?> values) =>
      values.fold(0.0, (sum, v) => sum + (v ?? 0).toDouble());

  final sales = report.sales ?? [];
  final salesReturn = report.salesReturn ?? [];
  final collections = report.collection ?? [];
  final expenses = report.expense ?? [];

  final totalSales = sumOf(sales.map(
      (s) => double.tryParse(s.grandTotal.toString()) ?? 0.0));
  final totalSalesReturn = sumOf(salesReturn.map(
      (r) => double.tryParse(r.grandTotal.toString()) ?? 0.0));
  final totalCollections = sumOf(collections.map(
      (c) => double.tryParse(c.totalAmount.toString()) ?? 0.0));
  final totalExpenses = sumOf(expenses.map(
      (e) => double.tryParse(e.amount.toString()) ?? 0.0));

  // ---- Header ----
  b.text('DAY CLOSE REPORT', size: 28, bold: true, align: PAlign.center);
  b.divider();

  b.row([
    Col('Salesman: ${report.data?.user ?? 'N/A'}', flex: 3),
    Col(
      'Date: ${report.data?.date != null ? DateHelper.displayDate(report.data!.date) : 'N/A'}',
      flex: 2,
      align: PAlign.right,
    ),
  ], size: 20);

  b.row([
    Col('VAN: ${report.data?.van ?? 'N/A'}', flex: 3),
    Col('Petty Cash: ${report.data?.pettyCash ?? 0}',
        flex: 2, align: PAlign.right),
  ], size: 20);

  b.divider();

  // ---- Sales ----
  if (sales.isNotEmpty) {
    b.text('SALES', size: 24, bold: true, align: PAlign.center);
    b.divider(thickness: 1, spacing: 2);
    b.row([
      Col('#', flex: 1),
      Col('Shop / Invoice', flex: 8),
      Col('Amount', flex: 3, align: PAlign.right),
    ], size: 19, bold: true);
    b.divider(thickness: 1, spacing: 2);

    for (var i = 0; i < sales.length; i++) {
      final sale = sales[i];
      final customerNames =
          sale.customer?.map((c) => c.name).join(', ') ?? 'No Customer';

      b.row([
        Col('${i + 1}', flex: 1),
        Col(customerNames, flex: 8),
        Col(money(sale.grandTotal), flex: 3, align: PAlign.right),
      ], size: 19);
      b.text('[${sale.invoiceNo ?? 'N/A'}]', size: 17);
    }

    b.divider(thickness: 1, spacing: 2);
    b.text('Total Sales: ${money(totalSales)}',
        size: 20, bold: true, align: PAlign.right);
    b.feed(10);
  }

  // ---- Sales Return ----
  if (salesReturn.isNotEmpty) {
    b.text('SALES RETURN', size: 24, bold: true, align: PAlign.center);
    b.divider(thickness: 1, spacing: 2);
    b.row([
      Col('#', flex: 1),
      Col('Shop / Ref', flex: 8),
      Col('Amount', flex: 3, align: PAlign.right),
    ], size: 19, bold: true);
    b.divider(thickness: 1, spacing: 2);

    for (var i = 0; i < salesReturn.length; i++) {
      final ret = salesReturn[i];
      final customerNames =
          ret.customer?.map((c) => c.name).join(', ') ?? 'No Customer';

      b.row([
        Col('${i + 1}', flex: 1),
        Col(customerNames, flex: 8),
        Col(money(ret.grandTotal), flex: 3, align: PAlign.right),
      ], size: 19);
      b.text('[${ret.invoiceNo ?? 'No Ref'}]', size: 17);
    }

    b.divider(thickness: 1, spacing: 2);
    b.text('Total Return: ${money(totalSalesReturn)}',
        size: 20, bold: true, align: PAlign.right);
    b.feed(10);
  }

  // ---- Collection ----
  if (collections.isNotEmpty) {
    b.text('COLLECTION', size: 24, bold: true, align: PAlign.center);
    b.divider(thickness: 1, spacing: 2);
    b.row([
      Col('#', flex: 1),
      Col('Shop / Type', flex: 8),
      Col('Amount', flex: 3, align: PAlign.right),
    ], size: 19, bold: true);
    b.divider(thickness: 1, spacing: 2);

    for (var i = 0; i < collections.length; i++) {
      final col = collections[i];
      final customerNames =
          col.customer?.map((c) => c.name).join(', ') ?? 'No Customer';
      final amount = double.tryParse(col.totalAmount ?? '0') ?? 0;

      b.row([
        Col('${i + 1}', flex: 1),
        Col(customerNames, flex: 8),
        Col(money(amount), flex: 3, align: PAlign.right),
      ], size: 19);
      b.text('Type: ${col.collectionType ?? 'Cash'}', size: 17);
    }

    b.divider(thickness: 1, spacing: 2);
    b.text('Total Collection: ${money(totalCollections)}',
        size: 20, bold: true, align: PAlign.right);
    b.feed(10);
  }

  // ---- Expense ----
  if (expenses.isNotEmpty) {
    b.text('EXPENSE', size: 24, bold: true, align: PAlign.center);
    b.divider(thickness: 1, spacing: 2);
    b.row([
      Col('#', flex: 1),
      Col('Expense / Remarks', flex: 8),
      Col('Amount', flex: 3, align: PAlign.right),
    ], size: 19, bold: true);
    b.divider(thickness: 1, spacing: 2);

    for (var i = 0; i < expenses.length; i++) {
      final exp = expenses[i];
      final expenseName =
          exp.expense?.map((e) => e.name).join(', ') ?? 'Expense';
      final amount = double.tryParse(exp.amount ?? '0') ?? 0;
      final ref = exp.invoiceNo ?? 'N/A';
      final remarks = (exp.description != null && exp.description!.isNotEmpty)
          ? '($ref - ${exp.description})'
          : '($ref)';

      b.row([
        Col('${i + 1}', flex: 1),
        Col(expenseName, flex: 8),
        Col(money(amount), flex: 3, align: PAlign.right),
      ], size: 19);
      b.text(remarks, size: 17);
    }

    b.divider(thickness: 1, spacing: 2);
    b.text('Total Expenses: ${money(totalExpenses)}',
        size: 20, bold: true, align: PAlign.right);
    b.feed(10);
  }

  // ---- Net cash balance ----
  b.divider();
  if (report.data?.netCashBalance != null) {
    b.text(
      'Net Cash Balance: ${money(report.data!.netCashBalance)}',
      size: 24,
      bold: true,
      align: PAlign.center,
    );
  }
  b.feed(10);
  b.text('--- THANK YOU ---', size: 20, align: PAlign.center);
  b.feed(30);
}