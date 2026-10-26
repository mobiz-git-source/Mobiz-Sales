// Reports/day_close_summary_report.dart
//
// Day-close summary report for DayClosePagessss (DayCloseResponse123 model).
// Separate from day_close_report.dart, which serves DayReport.dart's
// DayCloseOutstandingReport model — same name/shape but different types,
// so kept as distinct functions.

import 'package:mobizapp/Pages/Day_expand.dart';

import '../Models/appstate.dart';
import '../Utilities/report_printer.dart';
import '../Utilities/date_helper.dart';


void drawDayCloseSummaryReport(
  ImageReportBuilder b,
  DayCloseResponse123 report, {
  String? routeName,
}) {
  final dec = AppState().noOfDecimals ?? 2;
  String money(num? v) => (v ?? 0).toStringAsFixed(dec);
  final data = report.data;
  final vanName = data.van.isNotEmpty ? data.van[0].name : 'N/A';

  double totalSales = report.sales.isNotEmpty
      ? report.sales.map((s) => double.tryParse(s.grandTotal.toString()) ?? 0.0).reduce((a, c) => a + c)
      : 0.0;
  double totalReturns = report.salesReturn.isNotEmpty
      ? report.salesReturn.map((r) => double.tryParse(r.grandTotal.toString()) ?? 0.0).reduce((a, c) => a + c)
      : 0.0;
  double totalCollections = report.collection.isNotEmpty
      ? report.collection.map((c) => double.tryParse(c.totalAmount.toString()) ?? 0.0).reduce((a, c) => a + c)
      : 0.0;
  double totalExpenses = report.expense.isNotEmpty
      ? report.expense.map((e) => double.tryParse(e.totalAmount.toString()) ?? 0.0).reduce((a, c) => a + c)
      : 0.0;

  // ---- Header ----
  b.text('DAY CLOSE REPORT', size: 30, bold: true, align: PAlign.center);
  b.divider();
  b.row([Col('Date: ${DateHelper.displayDate(data.inDate)}'), Col('Time: ${data.inTime}', align: PAlign.right)]);
  b.row([Col('Salesman: ${AppState().name}'), Col('Van: $vanName', align: PAlign.right)]);
  if (routeName != null && routeName.isNotEmpty) b.text('Route: $routeName');
  b.row([Col('Invoice: ${data.invoiceNo}'), Col('Petty Cash: ${data.pettyCash}', align: PAlign.right)]);
  b.divider();

  // ---- Summary tiles ----
  b.row([Col('Sales (${data.noOfSales})'), Col(money(data.amountOfSales), align: PAlign.right)]);
  b.row([Col('Returns (${data.noOfReturns})'), Col(money(data.amountOfReturns), align: PAlign.right)]);
  b.row([Col('Cash Collection'), Col(money(data.collectionCashAmount), align: PAlign.right)]);
  b.row([Col('Cheque Collection (${data.collectionNoOfCheque})'), Col(money(data.collectionChequeAmount), align: PAlign.right)]);
  b.row([Col('Last Day Cash'), Col(money(data.lastDayBalanceAmount), align: PAlign.right)]);
  b.row([Col('Last Day Cheque (${data.lastDayBalanceNoOfCheque})'), Col(money(data.lastDayBalanceChequeAmount), align: PAlign.right)]);
  b.divider();

  // ---- Sales ----
  if (report.sales.isNotEmpty) {
    b.text('SALES', size: 26, bold: true);
    b.divider(dashed: true);
    b.row([Col('#', flex: 1), Col('Shop', flex: 6), Col('Invoice', flex: 3), Col('Amount', flex: 3, align: PAlign.right)], bold: true);
    for (int i = 0; i < report.sales.length; i++) {
      final s = report.sales[i];
      final names = s.customer.map((c) => c.name).join(', ');
      b.row([Col('${i + 1}', flex: 1), Col(names, flex: 6), Col(s.invoiceNo, flex: 3), Col(money(s.grandTotal), flex: 3, align: PAlign.right)]);
    }
    b.divider();
    b.row([Col('', flex: 8), Col('Total: ${money(totalSales)}', flex: 3, align: PAlign.right, bold: true)]);
    b.feed(10);
  }

  // ---- Sales Return ----
  if (report.salesReturn.isNotEmpty) {
    b.text('SALES RETURN', size: 26, bold: true);
    b.divider(dashed: true);
    b.row([Col('#', flex: 1), Col('Shop', flex: 6), Col('Ref', flex: 3), Col('Amount', flex: 3, align: PAlign.right)], bold: true);
    for (int i = 0; i < report.salesReturn.length; i++) {
      final r = report.salesReturn[i];
      final names = r.customer?.map((c) => c.name).join(', ') ?? '';
      b.row([Col('${i + 1}', flex: 1), Col(names, flex: 6), Col(r.invoiceNo ?? '', flex: 3), Col(money(r.grandTotal), flex: 3, align: PAlign.right)]);
    }
    b.divider();
    b.row([Col('', flex: 8), Col('Total: ${money(totalReturns)}', flex: 3, align: PAlign.right, bold: true)]);
    b.feed(10);
  }

  // ---- Collection ----
  if (report.collection.isNotEmpty) {
    b.text('COLLECTION', size: 26, bold: true);
    b.divider(dashed: true);
    b.row([Col('#', flex: 1), Col('Shop', flex: 6), Col('Type', flex: 3), Col('Amount', flex: 3, align: PAlign.right)], bold: true);
    for (int i = 0; i < report.collection.length; i++) {
      final c = report.collection[i];
      final names = c.customer?.map((cu) => cu.name).join(', ') ?? '';
      final amt = double.tryParse(c.totalAmount ?? '0') ?? 0;
      b.row([Col('${i + 1}', flex: 1), Col(names, flex: 6), Col(c.collectionType ?? '', flex: 3), Col(money(amt), flex: 3, align: PAlign.right)]);
    }
    b.divider();
    b.row([Col('', flex: 8), Col('Total: ${money(totalCollections)}', flex: 3, align: PAlign.right, bold: true)]);
    b.feed(10);
  }

  // ---- Expense ----
  if (report.expense.isNotEmpty) {
    b.text('EXPENSE', size: 26, bold: true);
    b.divider(dashed: true);
    b.row([Col('#', flex: 1), Col('Reference', flex: 3), Col('Expense', flex: 4), Col('Amount', flex: 3, align: PAlign.right)], bold: true);
    for (int i = 0; i < report.expense.length; i++) {
      final e = report.expense[i];
      final name = e.expense?.map((x) => x.name).join(', ') ?? '';
      final amt = double.tryParse(e.amount ?? '0') ?? 0;
      b.row([Col('${i + 1}', flex: 1), Col(e.invoiceNo ?? '', flex: 3), Col(name, flex: 4), Col(money(amt), flex: 3, align: PAlign.right)]);
      if ((e.description ?? '').isNotEmpty) b.text('   ${e.description}', size: 20);
    }
    b.divider();
    b.row([Col('', flex: 8), Col('Total: ${money(totalExpenses)}', flex: 3, align: PAlign.right, bold: true)]);
    b.feed(10);
  }

  // ---- Summary ----
  b.text('SUMMARY DETAILS', size: 26, bold: true);
  b.divider();
  b.row([Col('Expense Total'), Col(money(data.expense), align: PAlign.right)]);
  b.row([Col('Cash Deposited'), Col(money(data.cashDeposited), align: PAlign.right)]);
  b.row([Col('Cash Handed Over'), Col(money(data.cashHandOver), align: PAlign.right)]);
  b.row([Col('Cheque Deposited (${data.noOfChequeDeposited})'), Col(money(data.chequeDepositedAmount), align: PAlign.right)]);
  b.row([Col('Cheque Handed Over (${data.noOfChequeHandOver})'), Col(money(data.chequeHandOverAmount), align: PAlign.right)]);
  b.row([Col('Balance Cash in Hand'), Col(money(data.balanceCashInHand), align: PAlign.right)]);
  b.row([Col('Balance Cheque (${data.noOfChequeInHand})'), Col(money(data.chequeAmountInHand), align: PAlign.right)]);
  b.divider();
  b.text('--- THANK YOU ---', align: PAlign.center);
  b.feed(30);
}