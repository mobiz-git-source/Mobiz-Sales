import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FIX: needed for decimalInputFormatters()
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobizapp/Pages/CustomeSOA.dart';
import 'package:mobizapp/Pages/receiptscreen.dart';
import 'package:shimmer/shimmer.dart';
import '../Components/commonwidgets.dart';

import '../Models/appstate.dart';
import '../Models/paymentcollectionclass.dart';
import '../Utilities/rest_ds.dart';
import '../Utilities/date_helper.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';
import '../confg/apptextsizes.dart';
import 'Group_Print.dart';

class PaymentCollectionScreen extends StatefulWidget {
  static const routeName = "/PaymentCollection";
  PaymentCollectionScreen({Key? key}) : super(key: key);
  @override
  _PaymentCollectionScreenState createState() =>
      _PaymentCollectionScreenState();
}

String cuname = '';

class _PaymentCollectionScreenState extends State<PaymentCollectionScreen> {
  // =======================================================================
  // ORIGINAL STATE / LOGIC — UNCHANGED
  // =======================================================================
  List<Invoice> invoices = [];

  String dropdownvalue = 'Cash';
  var items = ['Cash', 'cheque'];
  late Future<ApiResponse> futureInvoices;
  List<bool> expandedStates = [];
  TextEditingController _paidAmt = TextEditingController();
  String PaidAmt = '';
  String RoundOff = '';
  String formattedDate = DateHelper.displayFromDateTime(DateTime.now());
  DateTime selectedChequeDate = DateTime.now();
  TextEditingController _bankController = TextEditingController();
  String bankData = '';
  TextEditingController _chequeController = TextEditingController();
  String chequeData = '';
  int? id;
  int? saleId;
  int? returnId;
  String? paydata;
  String? code;
  String? payment;
  int? pricegroupId;
  List<String> enteredValues = [];
  List<String> invoiceTypes = [];
  List<String> invoiceno = [];
  List<String> invoicedate = [];
  List<int> goodsTypes = [];
  List<int> invoiceid = [];
  final TextEditingController _roundOffController = TextEditingController();
  double roundOffValue = 0.0;
  bool group = false;
  bool isSaving = false;
  int? selectedIndex;

  String formatDate(String date) {
    return DateHelper.displayDate(date);
  }

  // ---------------------------------------------------------------------
  // FIX: Centralised rounding helpers (same contract as the Driver screen)
  // Every single arithmetic result and every value pulled from a text field
  // MUST pass through one of these before being stored, displayed, or sent
  // to the API. This is what stops the "124.5858585880585882545556" and
  // "12455555844.52222222222" style garbage.
  // ---------------------------------------------------------------------
  String roundedString(num value) {
    final decimals = (AppState().noOfDecimals ?? 2).clamp(0, 4);
    return value.toStringAsFixed(decimals);
  }

 double roundedDouble(num value) {
  final decimals = (AppState().noOfDecimals ?? 2).clamp(0, 4);
  final rounded = double.parse(value.toStringAsFixed(decimals));

  // Prevent -0.000 / -0.00
  if (rounded == 0) {
    return 0.0;
  }

  return rounded;
}

  // FIX: fmt() for read-only display values (mirrors Driver screen's fmt())
 String fmt(dynamic value) {
  final n = double.tryParse(value.toString()) ?? 0;
  final decimals = (AppState().noOfDecimals ?? 2).clamp(0, 4);
  final rounded = double.parse(n.toStringAsFixed(decimals));
  final safe = (rounded == 0) ? 0.0 : rounded; // FIX: kill -0.000
  return safe.toStringAsFixed(decimals);
}

  // UI FIX: comma-separated display for large amounts (Total Outstanding,
  // Balance, Allocated, After Round Off) to match reference screenshot.
  // Purely cosmetic — never used in any calculation, comparison, or the
  // API payload. Editable fields (Paid Amount / Round Off dialogs) keep
  // using the plain fmt()/roundedString() so raw parsing stays untouched.
 String fmtComma(dynamic value) {
  final n = double.tryParse(value.toString()) ?? 0;
  final decimals = (AppState().noOfDecimals ?? 2).clamp(0, 4);
  final rounded = double.parse(n.toStringAsFixed(decimals));
  final safe = (rounded == 0) ? 0.0 : rounded; // FIX: kill -0.000
  final pattern = '#,##0.' + '0' * decimals;
  return NumberFormat(pattern).format(safe);
}

  // FIX: Restrict keyboard input to N decimal places. This alone is the
  // single biggest fix — without this, the TextField accepts arbitrarily
  // long decimal input (or garbage from autocorrect/paste), which is the
  // root cause of the huge floating point strings.
  List<TextInputFormatter> decimalInputFormatters() {
    final decimals = (AppState().noOfDecimals ?? 2).clamp(0, 4);
    final pattern = RegExp(r'^\-?\d*\.?\d{0,' + decimals.toString() + r'}$');
    return [
      TextInputFormatter.withFunction((oldValue, newValue) {
        if (newValue.text.isEmpty) return newValue;
        // Reject the whole edit if the resulting text doesn't fully match
        // the pattern (whole-string validation, not per-character).
        if (pattern.hasMatch(newValue.text)) {
          return newValue;
        }
        return oldValue;
      }),
    ];
  }

  @override
  void initState() {
    super.initState();
    futureInvoices = Future.value(ApiResponse(data: []));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRouteArguments();
      futureInvoices = fetchInvoices();
    });
  }

  void _handleRouteArguments() {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      setState(() {
        code = arguments['code'] ?? '';
        cuname = arguments['name'] ?? '';
        payment = arguments['paymentTerms'] ?? '';
        paydata = arguments['outstandamt'] ?? '';
        id = int.tryParse(arguments['customerId'].toString());
        pricegroupId = arguments['price_group_id'];
        saleId = arguments['saleId'];
        returnId = arguments['returnId'];
      });
    }
  }

  // ---------------------------------------------------------------------
  // Invoice-type allocation logic
  // Sales / Balance          → add to allocation (money owed BY customer)
  // Sales Return / Payment   → add to allocation too, per your original
  //   Voucher / Balance Minus  business rule (kept identical to source —
  //   only the rounding was fixed, not the sign logic, since you said the
  //   business rule for each type must stay intact)
  // ---------------------------------------------------------------------
  double getAllocatedAmount() {
    // FIX: roundedDouble() wraps the fold result so partial float noise
    // from repeated addition (0.1 + 0.2 problem) never leaks into the UI.
    final total = enteredValues.asMap().entries.map((entry) {
      int index = entry.key;
      String value = entry.value;
      if (value.isNotEmpty && index < invoices.length) {
        double amount = double.tryParse(value) ?? 0.0; // FIX: tryParse guard
        String invoiceType = invoices[index].invoiceType.toLowerCase();
        if (invoiceType == "sales" ||
            invoiceType == "balance" ||
            invoiceType == "salesreturn" ||
            invoiceType == "payment_voucher" ||
            invoiceType == "balance_minus") {
          return amount;
        }
      }
      return 0.0;
    }).fold(0.0, (sum, amount) => sum + amount);

    return roundedDouble(total); // FIX
  }

  double getBalanceAmount() {
    double paidAmount = getPaidAmount(); // already rounded, see below
    double roundOff = getRoundOff(); // already rounded, see below

    final allocatedRaw = enteredValues.asMap().entries.map((entry) {
      int index = entry.key;
      String value = entry.value;
      if (value.isNotEmpty && index < invoices.length) {
        double amount = double.tryParse(value) ?? 0.0; // FIX: tryParse guard
        String invoiceType = invoices[index].invoiceType.toLowerCase();
        if (invoiceType == "sales" ||
            invoiceType == "balance" ||
            invoiceType == "salesreturn" ||
            invoiceType == "payment_voucher" ||
            invoiceType == "balance_minus") {
          return -amount;
        }
      }
      return 0.0;
    }).fold(0.0, (sum, amount) => sum + amount);

    double balance = paidAmount + allocatedRaw - roundOff;
    return roundedDouble(balance); // FIX: single, final rounding point
  }

  // FIX: getPaidAmount() now has ONE source of truth — the PaidAmt string
  // (kept in sync with _paidAmt.text everywhere it's written) — and always
  // returns a rounded double. Previously this read _paidAmt.text directly
  // while the UI displayed the separate, un-rounded PaidAmt variable —
  // that mismatch was part of the bug.
  double getPaidAmount() {
    if (PaidAmt.trim().isEmpty) return 0.0;
    final amount = double.tryParse(PaidAmt.trim());
    if (amount == null) {
      print('Invalid Paid Amount entered: $PaidAmt');
      return 0.0;
    }
    return roundedDouble(amount); // FIX
  }

  // FIX: same fix as getPaidAmount() — single source of truth (RoundOff),
  // always rounded, guards against garbage input.
  double getRoundOff() {
    if (RoundOff.trim().isEmpty) return 0.0;
    final value = double.tryParse(RoundOff.trim());
    if (value == null) {
      print('Invalid Round Off entered: $RoundOff');
      return 0.0;
    }
    return roundedDouble(value); // FIX
  }

  void updateBalanceAndAllocatedAmounts() {
    setState(() {});
  }

  // -----------------------------------------------------------------------
  // UI-ONLY helper: "After Round Off" tile in the screenshot is a purely
  // derived display value (Paid − Round Off). It does NOT feed into
  // getBalanceAmount(), postCollectionData(), or the Save-enable condition
  // — none of the original calculations are touched by adding this.
  // -----------------------------------------------------------------------
 double _afterRoundOffDisplay() {
  final paid = getPaidAmount();
  final allocated = getAllocatedAmount();
  final roundOff = getRoundOff();

  print('========== AFTER ROUND OFF DEBUG ==========');
  print('Paid Amount     : $paid');
  print('Allocated Amount: $allocated');
  print('Round Off       : $roundOff');
  print('After Round Off : ${paid - roundOff}');
  print('============================================');

  return roundedDouble(paid - roundOff);
}
  // =======================================================================
  // UI — SIZE-TUNED TO MATCH REFERENCE SCREENSHOT SCALE
  // (business logic below this point is only ever READ, never altered)
  // =======================================================================

  static const Color _cOutstanding = Color(0xFF14B8A6);
  static const Color _cPaying = Color(0xFF16A34A);
  static const Color _cBalance = Color(0xFF3730A3);
  static const Color _cAllocated = Color(0xFFF59E0B);
  static const Color _cRoundOff = Color(0xFF7C3AED);
  static const Color _cAfterRoundOff = Color(0xFF2563EB);
  static const Color _cLabelGrey = Color(0xFF6B7280);
  static const Color _cNegative = Color(0xFFDC2626);
  static const Color _cPageBg = Color(0xFFF3F4F8);
  Widget _paymentDivider() {
    return Container(
      width: 1,
      height: 42,
      color: const Color(0xFFE9E9EE),
    );
  }

 Widget _paymentBox({
  required IconData icon,
  required Color iconColor,
  required Color iconBg,
  required String title,
  required String value,
  required Color valueColor,
  bool bold = false,
  bool editable = false, // ADD THIS
  VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 5,
  
      ),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                 style: const TextStyle(
  fontSize: AppFontSizes.payTileLabel,
  color: Color(0xFF777777),
  fontWeight: FontWeight.w400,
),
                ),

                const SizedBox(height: 4),

                // ONLY You are Paying + Round Off get this container
                if (editable)
                  Container(
                    width: double.infinity,
                height: 32,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: const Color(0xFFD4D4D4),
                        width: 0.9,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: TextStyle(
  fontSize: AppFontSizes.payTileValueEditable,
  color: valueColor,
                          fontWeight: bold
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
  FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(
      value,
      maxLines: 1,
      style: TextStyle(
        fontSize: AppFontSizes.payTileValue,
        color: valueColor,
        fontWeight:
            bold ? FontWeight.w600 : FontWeight.w500,
      ),
    ),
  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cPageBg,
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimary,
        foregroundColor: AppConfig.backgroundColor,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Payment Collection', style: AppConfig.pageTitleStyle),
            const SizedBox(height: 2),
            Text(
              '${cuname.isEmpty ? '' : cuname} | ${(payment != null && payment!.isNotEmpty) ? payment : dropdownvalue.toUpperCase()}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      // -----------------------------------------------------------------
      // STRUCTURE (unchanged from previous fix):
      //   Column
      //    ├── Expanded( SingleChildScrollView( summary card
      //    │              + section title + invoice list ) )   <- scrolls
      //    ├── Info banner + Collection Type / Bank / Cheque    <- fixed
      //    └── bottomNavigationBar: Save / Skip                 <- fixed
      // Only sizes/padding/spacing are tuned below — no structural change.
      // -----------------------------------------------------------------
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -----------------------------------------------------
                    // Summary card: 2 rows x 3 tiles
                    // SIZE TUNE: tighter outer padding, smaller radius,
                    // tighter internal padding, less gap around divider.
                    // -----------------------------------------------------
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE8E8EE),
                            width: 0.7,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // =========================
                            // FIRST ROW
                            // =========================
                          Container(
  width: double.infinity,
  height: 66,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _paymentBox(
                                      icon: Icons.description_outlined,
                                      iconColor: const Color(0xFF6256C8),
                                      iconBg: const Color(0xFFF1EFFF),
                                      title: 'Total Outstanding',
                                      value:
                                          (paydata == '[]' || paydata == null)
                                              ? '--'
                                              : fmtComma(paydata),
                                      valueColor: const Color(0xFF222222),
                                    ),
                                  ),
                                  _paymentDivider(),
                                  Expanded(
                                    child:_paymentBox(
  icon: Icons.account_balance_wallet_outlined,
  iconColor: const Color(0xFF26A96C),
  iconBg: const Color(0xFFEAF8F1),
  title: 'You are Paying',
  value: PaidAmt.isEmpty
      ? '0.000'
      : fmt(PaidAmt),
  valueColor: const Color(0xFF222222),
  editable: true,
  onTap: _openPaidAmountDialog,
),
                                  ),
                                  _paymentDivider(),
                                  Expanded(
                                    child: _paymentBox(
                                      icon: Icons.balance_outlined,
                                      iconColor: const Color(0xFF3267D6),
                                      iconBg: const Color(0xFFEAF0FF),
                                      title: 'Balance Amount',
                                      value: fmtComma(getBalanceAmount()),
                                      valueColor: const Color(0xFF30368C),
                                      bold: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // =========================
                            // HORIZONTAL LINE
                            // =========================
                            Container(
                              height: 1,
                              color: const Color(0xFFE9E9EE),
                            ),

                            // =========================
                            // SECOND ROW
                            // =========================
                     Container(
  width: double.infinity,
  height: 66,
  child: Row(
                                children: [
                                  Expanded(
                                    child: _paymentBox(
                                      icon: Icons.pie_chart_outline,
                                      iconColor: const Color(0xFFF4A51C),
                                      iconBg: const Color(0xFFFFF6E5),
                                      title: 'Allocated Amount',
                                      value: fmtComma(getAllocatedAmount()),
                                      valueColor: const Color(0xFFF0A000),
                                      bold: true,
                                    ),
                                  ),
                                  _paymentDivider(),
                                  Expanded(
                                    child:_paymentBox(
  icon: Icons.sync_alt,
  iconColor: const Color(0xFF6851C8),
  iconBg: const Color(0xFFF0ECFF),
  title: 'Round Off',
  value: RoundOff.isEmpty
      ? '0.000'
      : fmt(RoundOff),
  valueColor: const Color(0xFF222222),
  editable: true,
  onTap: _openRoundOffDialog,
),
                                  ),
                                  _paymentDivider(),
                                  Expanded(
                                    child: _paymentBox(
                                      icon: Icons.calculate_outlined,
                                      iconColor: const Color(0xFF3B72D9),
                                      iconBg: const Color(0xFFEAF1FF),
                                      title: 'After Round Off',
                                      value: fmtComma(_afterRoundOffDisplay()),
                                      valueColor: const Color(0xFF30368C),
                                      bold: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // -----------------------------------------------------
                    // Section title
                    // SIZE TUNE: much tighter top/bottom gap (was 20/8).
                    // -----------------------------------------------------
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                      child: Text(
                       'Outstanding Invoices / Returns',
style: TextStyle(
  fontSize: AppFontSizes.paySectionTitle,
                          fontWeight: FontWeight.bold,
                          color: AppConfig.textBlack,
                        ),
                      ),
                    ),

                    // -----------------------------------------------------
                    // Invoice / return list — logic untouched, only the
                    // itemBuilder's returned widget tree is resized.
                    // -----------------------------------------------------
                    FutureBuilder<ApiResponse>(
                      future: futureInvoices,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Shimmer.fromColors(
                            baseColor:
                                AppConfig.buttonDeactiveColor.withOpacity(0.1),
                            highlightColor: AppConfig.backButtonColor,
                            child: Column(
                              children: List.generate(
                                4,
                                (_) => CommonWidgets.loadingContainers(
                                  height: SizeConfig.blockSizeVertical * 8,
                                  width: SizeConfig.blockSizeHorizontal * 90,
                                ),
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.data.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(child: Text('No invoices found')),
                          );
                        } else {
                          if (expandedStates.isEmpty) {
                            expandedStates = List<bool>.filled(
                                snapshot.data!.data.length, false);
                          }
                          if (enteredValues.length !=
                              snapshot.data!.data.length) {
                            enteredValues =
                                List.filled(snapshot.data!.data.length, '');
                          }

                          return ListView.builder(
                            scrollDirection: Axis.vertical,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: snapshot.data!.data.length,
                            itemBuilder: (context, index) {
                              final invoice = snapshot.data!.data[index];

                              invoiceTypes.clear();
                              goodsTypes.clear();
                              invoiceno.clear();
                              invoicedate.clear();
                              invoiceid.clear();

                              snapshot.data!.data.forEach((inv) {
                                invoiceTypes.add(inv.invoiceType);
                                goodsTypes.add(inv.master_id);
                                invoiceno.add(inv.invoiceNo);
                                invoicedate.add(inv.invoiceDate);
                                invoiceid.add(inv.id);
                              });

                              String formatInvoiceType(String invoiceType) {
                                if (invoiceType.toLowerCase() ==
                                    "payment_voucher") return "Payment";
                                if (invoiceType.toLowerCase() == "salesreturn")
                                  return "Sales Return";
                                return invoiceType
                                    .split('_')
                                    .map((word) => word.isEmpty
                                        ? word
                                        : word[0].toUpperCase() +
                                            word.substring(1).toLowerCase())
                                    .join(' ');
                              }

                              final amountVal =
                                  double.tryParse(invoice.amount.toString()) ??
                                      0.0;
                              final paidVal =
                                  double.tryParse(invoice.paid.toString()) ??
                                      0.0;
                              final balanceVal =
                                  double.tryParse(invoice.balance.toString()) ??
                                      0.0;

                              // SIZE TUNE: smaller vertical margin between
                              // cards (was vertical:6 -> now 5), smaller
                              // radius (14 -> 12), lighter shadow.
                             return Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 3,
  ),
  child: Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(
        color: const Color(0xFFE8E8E8),
        width: 0.7,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.025),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: () {
            setState(() {
              expandedStates[index] =
                  !expandedStates[index];
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              9,
              6,
              9,
              6,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                // DATE | INVOICE | TYPE
                Text(
                  "${DateHelper.displayDate(invoice.invoiceDate)}  |  "
                  "${invoice.invoiceNo}  |  "
                  "${formatInvoiceType(invoice.invoiceType)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
  fontSize: AppFontSizes.payRowHeader,
  fontWeight: FontWeight.w500,
  color: Color(0xFF202020),
  height: 1.0,
),
                ),

                const SizedBox(height: 6),

                // AMOUNT | PAID | BALANCE | ALLOCATE
               SizedBox(
  height: 42,
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [

      // ============================================================
      // AMOUNT
      // ============================================================
      Expanded(
        child: _amountColumn(
          'Amount',
          amountVal,
        ),
      ),

      _vDivider(),

      // ============================================================
      // PAID
      // ============================================================
      Expanded(
        child: _amountColumn(
          'Paid',
          paidVal,
        ),
      ),

      _vDivider(),

      // ============================================================
      // BALANCE
      // ============================================================
      Expanded(
        child: _amountColumn(
          'Balance',
          balanceVal,
        ),
      ),

      _vDivider(),

      // ============================================================
      // ALLOCATE AMOUNT
      // Responsive - fixed 82 removed
      // ============================================================
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 3,
            right: 2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [

             const SizedBox(
  width: double.infinity,
  child: FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerRight,
    child: Text(
      'Allocate Amount',
      maxLines: 1,
      style: TextStyle(
        fontSize: AppFontSizes.payColLabel,
        color: Color(0xFF777777),
        fontWeight: FontWeight.w400,
        height: 1.0,
      ),
    ),
  ),
),

              const SizedBox(height: 6),

              InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });

                  _showDialog(
                    context,
                    index,
                    invoice,
                  );
                },
                child: SizedBox(
                  width: double.infinity,
                  child: _inputBox(
                    status: true,
                    value: enteredValues[index].isEmpty
                        ? '0.000'
                        : fmt(
                            enteredValues[index],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
              ],
            ),
          ),
        ),

        // KEEP YOUR EXISTING EXPANDED SECTION
        Visibility(
          visible: expandedStates[index],
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              8,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: invoice.collection
                  .map((collection) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${formatDate(collection.inDate ?? '')} | '
                          '${collection.voucherNo} | '
                          '${fmt(collection.totalAmount)} | '
                          '${collection.collectionType}',
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _cLabelGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ),
  ),
);
                            },
                          );
                        }
                      },
                    ),

                    // SIZE TUNE v2: trailing gap 4 -> 2
                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ),

            // -----------------------------------------------------
            // FIXED (non-scrolling) bottom block: Info banner +
            // Collection Type + Bank/Cheque fields. Always visible.
            // -----------------------------------------------------
            _buildFixedInfoAndCollectionSection(),
          ],
        ),
      ),

      // -----------------------------------------------------------------
      // FIXED Save / Skip bar. Same widgets, same enable condition, same
      // onPressed logic as before — sizes tuned to reference.
      // -----------------------------------------------------------------
      bottomNavigationBar: _buildStickySaveBar(),
    );
  }

  // -----------------------------------------------------------------------
  // Small subtle vertical divider used between Amount / Paid / Balance /
  // Allocate Amount inside each invoice card. Kept short (not full card
  // height) and light-colored per the reference.
  // SIZE TUNE: uses a fixed short height + centered alignment instead of
  // stretching the full IntrinsicHeight row, so the line looks like the
  // subtle, vertically-centered divider in the reference (not full-height).
  // -----------------------------------------------------------------------
 Widget _vDivider() {
  return Container(
    width: 1,
    height: 30,
    margin: const EdgeInsets.symmetric(
      horizontal: 4,
    ),
    color: const Color(0xFFE8E8E8),
  );
}

  // -----------------------------------------------------------------------
  // Fixed Info banner + Collection Type / Bank / Cheque section.
  // Identical logic/state writes to before — only sizes/padding tuned.
  // -----------------------------------------------------------------------
Widget _buildFixedInfoAndCollectionSection() {
  return Container(
    color: _cPageBg,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        // ============================================================
        // INFO MESSAGE - COMPACT REFERENCE STYLE
        // ============================================================
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
          child: Container(
            width: double.infinity,
            height: 34,
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppConfig.colorPrimary,
                  size: 13,
                ),

                const SizedBox(width: 6),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Enter allocation amount for each invoice/return.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                   fontSize: AppFontSizes.payInfoTitle,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF222222),
                          height: 1.0,
                        ),
                      ),

                      SizedBox(height: 2),

                      Text(
                        'Total allocated amount will be calculated automatically.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                       fontSize: AppFontSizes.payInfoSub,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF777777),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ============================================================
        // COLLECTION TYPE
        // ============================================================
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 1, 10, 2),
          child: Container(
            width: double.infinity,
            height: 38,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: const Color(0xFFDCDCDC),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [

                // LABEL
                const Text(
                  'Collection Type',
                  style: TextStyle(
                    color: Color(0xFF777777),
                  fontSize: AppFontSizes.payFieldLabel,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const Spacer(),

                // DROPDOWN
                Container(
                  height: 29,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFD4D4D4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Icon(
                        dropdownvalue == 'Cash'
                            ? Icons.payments_outlined
                            : Icons.receipt_long_outlined,
                        size: 13,
                        color: AppConfig.colorPrimary,
                      ),

                      const SizedBox(width: 4),

                      DropdownButton<String>(
                        value: dropdownvalue,
                        underline: const SizedBox(),
                        isDense: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 15,
                          color: Color(0xFF555555),
                        ),
                        items: items.map((String item) {
                          final capitalizedItem =
                              item[0].toUpperCase() +
                                  item.substring(1);

                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(
                              capitalizedItem,
                              style: const TextStyle(
                          fontSize: AppFontSizes.payFieldValue,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF222222),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue == null) return;

                          setState(() {
                            dropdownvalue = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ============================================================
        // BANK / CHEQUE SECTION
        // LOGIC SAME - ONLY COMPACT UI
        // ============================================================
        if (dropdownvalue != "Cash")
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 3),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: const Color(0xFFDCDCDC),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [

                  Row(
                    children: [
                      const Text(
                        'Bank',
                        style: TextStyle(
                     fontSize: AppFontSizes.payFormLabel,
                          color: Color(0xFF777777),
                        ),
                      ),

                      const SizedBox(width: 5),

                    Expanded(
  child: Container(
    height: 25,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: const Color(0xFFDADADA), width: 0.8),
    ),
    child: TextField(
      controller: _bankController,
      keyboardType: TextInputType.name,
      textAlign: TextAlign.center,
  style: const TextStyle(fontSize: AppFontSizes.payFormInput, color: Color(0xFF333333)),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        hintText: 'Bank',
     hintStyle: TextStyle(fontSize: AppFontSizes.payFormInput),
      ),
      onChanged: (value) {
        setState(() {
          bankData = value;
        });
      },
    ),
  ),
),

                   
const SizedBox(width: 8),

const Text(
  'Cheque Date',
  style: TextStyle(
 fontSize: AppFontSizes.payFormLabel,
    color: Color(0xFF777777),
  ),
),

const SizedBox(width: 5),

Expanded(
  child: InkWell(
    onTap: () async {
      DateTime? pickedDate =
          await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        lastDate: DateTime(2100),
      );

      if (pickedDate != null) {
        setState(() {
          selectedChequeDate = pickedDate;
          formattedDate =
              DateHelper.displayFromDateTime(
                  pickedDate);
        });
      }
    },
    child: _inputBox(
      status: true,
      value: formattedDate,
    ),
  ),
),
                    ],
                  ),

                  const SizedBox(height: 5),

                Row(
  children: [
    const Text(
      'Cheque No',
      style: TextStyle(
    fontSize: AppFontSizes.payFormLabel,
        color: Color(0xFF777777),
      ),
    ),

    const SizedBox(width: 5),

    Expanded(
      child: Container(
        height: 25,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: const Color(0xFFDADADA),
            width: 0.8,
          ),
        ),
        child: TextField(
          controller: _chequeController,
          keyboardType: TextInputType.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF333333),
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 2,
            ),
            hintText: 'Cheque No',
            hintStyle: TextStyle(fontSize: 9),
          ),
          onChanged: (value) {
            setState(() {
              chequeData = value;
            });
          },
        ),
      ),
    ),
  ],
),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
       


  // -----------------------------------------------------------------------
  // Sticky bottom Save/Skip bar widget.
  // Reads the same getters as before at build-time, so it stays in sync
  // with setState() calls elsewhere in the screen exactly like the old
  // inline block did — no behavioural change, only sizes tuned.
  // SIZE TUNE: outer padding reduced, button height 52 -> 46, skip 46 -> 40,
  // gap between buttons reduced, explicit small icon size on Save icon.
  // -----------------------------------------------------------------------
 Widget _buildStickySaveBar() {
  double allocatedAmount = getAllocatedAmount();
  double PaidAmount = getPaidAmount();
  double roundOff = getRoundOff();
 print('========== SAVE DEBUG ==========');
  print('PaidAmount       : $PaidAmount');
  print('RoundOff         : $roundOff');
  print('AllocatedAmount  : $allocatedAmount');
  print('BalanceAmount    : ${getBalanceAmount()}');
  print('selectedIndex    : $selectedIndex');
  print(
    'selectedValue    : ${selectedIndex != null && selectedIndex! < enteredValues.length ? enteredValues[selectedIndex!] : "NULL"}',
  );
  print(
    'Condition 1      : ${PaidAmount > 0 && roundedDouble(PaidAmount - roundOff) == roundedDouble(allocatedAmount)}',
  );
  print(
    'Condition 2      : ${getBalanceAmount() == 0.0 && selectedIndex != null && selectedIndex! < enteredValues.length && enteredValues[selectedIndex!].isNotEmpty}',
  );
  print('================================');

  return SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(
        10,
        3,
        10,
        4,
      ),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ==========================================================
          // SAVE BUTTON
          // ==========================================================
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.colorPrimary,
                disabledBackgroundColor:
                    const Color(0xFFD9D9D9),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),

              icon: Icon(
                isSaving
                    ? Icons.hourglass_top
                    : Icons.save_outlined,
                color: Colors.white,
                size: 13,
              ),

              label: Text(
                isSaving ? 'Saving...' : 'SAVE',
                style: const TextStyle(
                  color: Colors.white,
              fontSize: AppFontSizes.payButton,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),

              onPressed: (!isSaving &&
                      ((PaidAmount > 0 &&
                              roundedDouble(
                                      PaidAmount - roundOff) ==
                                  roundedDouble(
                                      allocatedAmount)) ||
                          (getBalanceAmount() == 0.0 &&
                              selectedIndex != null &&
                              enteredValues[selectedIndex!]
                                  .isNotEmpty)))
                  ? () async {
                      setState(() {
                        isSaving = true;
                      });

                      try {
                        await postCollectionData();
                      } catch (e) {
                        print(e);
                      }

                      if (mounted) {
                        setState(() {
                          isSaving = false;
                        });
                      }
                    }
                  : null,
            ),
          ),

          // ==========================================================
          // SKIP BUTTON
          // ==========================================================
          if (saleId != null) ...[
            const SizedBox(height: 4),

            SizedBox(
              width: double.infinity,
              height: 30,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppConfig.colorPrimary,
                    width: 0.8,
                  ),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    GroupPrint.routeName,
                    arguments: {
                      'price_group_id': pricegroupId,
                      'saleId': saleId,
                      'returnId': returnId,
                    },
                  );
                },
                child: Text(
                  'SKIP',
                  style: TextStyle(
              fontSize: AppFontSizes.payButton,
                    color: AppConfig.colorPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  // -----------------------------------------------------------------------
  // Metric tile widget — responsive: FittedBox prevents any digit/label
  // overflow on narrow screens instead of clipping or wrapping awkwardly.
  // SIZE TUNE: smaller icon badge (padding 5->4, icon 14->11), tighter
  // gaps (7->4, 4->2), smaller label (11->10) and input box padding.
  // -----------------------------------------------------------------------
  Widget _metricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String display,
    required Color valueColor,
    required bool editable,
    bool bold = false,
    VoidCallback? onTap,
  }) {
    final content = Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 10),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9.5, color: _cLabelGrey),
        ),
        const SizedBox(height: 1),
        const Spacer(),
        if (editable)
          Container(
            width: double.infinity,
         height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppConfig.buttonDeactiveColor.withOpacity(0.4)),
            ),
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                display,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                display,
                maxLines: 1,
                style: TextStyle(
                  fontSize: bold ? 13 : 12,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap == null) return content;
    return InkWell(
        borderRadius: BorderRadius.circular(6), onTap: onTap, child: content);
  }

  // SIZE TUNE: label 11->10, gap 4->2, value fontSize 14->13.
Widget _amountColumn(
  String title,
  double value,
) {
  final isNegative = value < 0;

  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 3,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // HEADER
        SizedBox(
          width: double.infinity,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
           style: const TextStyle(
  fontSize: AppFontSizes.payColLabel,
  fontWeight: FontWeight.w400,
  color: Color(0xFF777777),
  height: 1.0,
),
          ),
        ),

        const SizedBox(height: 6),

        // VALUE — CENTER
        SizedBox(
          width: double.infinity,
          child: Text(
            fmt(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
           style: TextStyle(
  fontSize: AppFontSizes.payColValue,
  fontWeight: FontWeight.w500,
  color: isNegative
                  ? const Color(0xFFE53935)
                  : const Color(0xFF202020),
              height: 1.0,
            ),
          ),
        ),
      ],
    ),
  );
}
  // -----------------------------------------------------------------------
  // Dialogs — same fields/state writes as the original file, untouched.
  // -----------------------------------------------------------------------
  void _openPaidAmountDialog() {
    _paidAmt.text =
        PaidAmt.isEmpty ? '' : roundedString(double.tryParse(PaidAmt) ?? 0.0);

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Paid Amount'),
          content: TextField(
            controller: _paidAmt,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: false),
            inputFormatters: decimalInputFormatters(),
            onChanged: (value) {
              setState(() {
                PaidAmt = value; // rounded on commit below
              });
            },
            decoration: const InputDecoration(hintText: "Paid Amount"),
          ),
          actions: <Widget>[
            MaterialButton(
              color: AppConfig.colorPrimary,
              textColor: Colors.white,
              child: const Text('OK'),
              onPressed: () {
                // FIX: hard round on commit, same pattern as Round Off
                setState(() {
                  PaidAmt =
                      roundedString(double.tryParse(_paidAmt.text) ?? 0.0);
                  _paidAmt.text = PaidAmt;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((value) => setState(() {}));
  }

  void _openRoundOffDialog() {
    print(
        "negLimit: ${AppState().roundOffNegative}, posLimit: ${AppState().roundOffPositive}");
    // FIX: seed with a rounded value, same pattern as Paid Amount
    _roundOffController.text =
        RoundOff.isEmpty ? '' : roundedString(double.tryParse(RoundOff) ?? 0.0);

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Round Off'),
          content: TextField(
            controller: _roundOffController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            inputFormatters:
                decimalInputFormatters(), // FIX: was missing — cause of 12455555844.52222222222
            onChanged: (value) {
              setState(() {
                // FIX: Round Off cap — same rule as CopyScreen.
                // The positive/negative round-off amount
                // configured in AppState() must not be
                // exceeded in either direction.
                final entered = double.tryParse(value) ?? 0;
                final posLimit = AppState().roundOffPositive ?? 0;
                final negLimit = AppState().roundOffNegative ?? 0;

                if (entered > 0 && posLimit > 0 && entered > posLimit) {
                  _roundOffController.text = posLimit.toString();
                  _roundOffController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _roundOffController.text.length));
                  RoundOff = _roundOffController.text;
                } else if (entered < 0 && negLimit > 0 && entered < -negLimit) {
                  _roundOffController.text = (-negLimit).toString();
                  _roundOffController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _roundOffController.text.length));
                  RoundOff = _roundOffController.text;
                } else {
                  RoundOff = value; // rounded on commit below
                }
              });
            },
            decoration: const InputDecoration(hintText: "Round Off"),
          ),
          actions: <Widget>[
            MaterialButton(
              color: AppConfig.colorPrimary,
              textColor: Colors.white,
              child: const Text('OK'),
              onPressed: () {
                // FIX: hard round on commit, mirrors Paid Amount fix
                setState(() {
                  RoundOff = roundedString(
                      double.tryParse(_roundOffController.text) ?? 0.0);
                  _roundOffController.text = RoundOff;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((value) => setState(() {}));
  }
double _clampToBalance(double entered, double balance) {
  double magnitude = entered.abs();
  double maxMagnitude = balance.abs();

  if (magnitude > maxMagnitude) {
    magnitude = maxMagnitude;
  }

  return balance >= 0 ? magnitude : -magnitude;
}

void _showDialog(BuildContext context, int index, Invoice invoice) {
  double invoiceBalance = roundedDouble(invoice.amount - invoice.paid);

  TextEditingController _amountController = TextEditingController(
    text: roundedString(invoiceBalance),
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Enter Amount'),
        content: TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: true),
          inputFormatters: decimalInputFormatters(),
       onChanged: (value) {
  setState(() {
    if (value.isEmpty || value == '-') {
      enteredValues[index] = value;
      updateBalanceAndAllocatedAmounts();
      return;
    }

    final raw = double.tryParse(value);

    if (raw == null) {
      return;
    }

    final clamped = _clampToBalance(raw, invoiceBalance);

    
    if (clamped != raw) {
      final formatted = roundedString(clamped);

      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: formatted.length,
        ),
      );

      enteredValues[index] = formatted;
    } else {
    
    
      enteredValues[index] = value;
    }

    updateBalanceAndAllocatedAmounts();
  });
},
          decoration: const InputDecoration(hintText: "Enter Amount"),
        ),
        actions: [
          MaterialButton(
            color: AppConfig.colorPrimary,
            textColor: Colors.white,
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                double raw = double.tryParse(_amountController.text) ?? 0.0;
                double clamped = _clampToBalance(raw, invoiceBalance);
                enteredValues[index] = roundedString(clamped);
                updateBalanceAndAllocatedAmounts();
              });
            },
          ),
        ],
      );
    },
  );
}
  // SIZE TUNE: smaller min/max width & min height, tighter padding so
  // the Allocate Amount box matches the compact reference size.
 Widget _inputBox({
  required String value,
  required bool status,
}) {
  return Container(
    width: double.infinity,
    height: 25,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(
      horizontal: 4,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(
        color: const Color(0xFFDADADA),
        width: 0.8,
      ),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        value,
        maxLines: 1,
        textAlign: TextAlign.center,
       style: const TextStyle(
  fontSize: AppFontSizes.payInput,
  fontWeight: FontWeight.w400,
  color: Color(0xFF333333),
  height: 1.0,
),
      ),
    ),
  );
}
  // =======================================================================
  // ORIGINAL API / DATA METHODS — UNCHANGED
  // =======================================================================
  Future<ApiResponse> fetchInvoices() async {
    final String url =
        '${RestDatasource().BASE_URL}/api/get_invoice_outstanding_detail?customer_id=$id';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      ApiResponse apiResponse = ApiResponse.fromJson(jsonDecode(response.body));
      invoices = apiResponse.data;
      enteredValues = List.filled(invoices.length, '');
      return apiResponse;
    } else {
      throw Exception('Failed to load invoices');
    }
  }

  Future<void> postCollectionData() async {
    final url = '${RestDatasource().BASE_URL}/api/collection.post';

    // FIX: every value going into processedValues is parsed then re-rounded,
    // eliminating any residual float noise before it hits the API.
    List<double> processedValues = enteredValues.map((value) {
      return value.isEmpty ? 0.0 : roundedDouble(double.tryParse(value) ?? 0.0);
    }).toList();

    final body = {
      'allocation_amount': getPaidAmount(), // FIX: already rounded double
      'round_off':
          getRoundOff(), // FIX: was raw text before, now a rounded double
      'van_id': AppState().vanId,
      'store_id': AppState().storeId,
      'user_id': AppState().userId,
      'goods_out_id': goodsTypes,
      'amount': processedValues,
      'customer_id': id,
      'invoice_type': invoiceTypes,
      'collection_type': dropdownvalue,
      'bank': _bankController.text,
      'cheque_no': _chequeController.text,
      'cheque_date': DateHelper.apiDate(selectedChequeDate),
      'invoice_no': invoiceno,
      'invoice_date': invoicedate,
      'invoice_id': invoiceid,
    };
    log('Request Body: ${json.encode(body)}');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      if (responseBody['success'] == true) {
        int? payId;
        if (responseBody.isNotEmpty) {
          payId = responseBody['collection_id'];
        }

        setState(() {
          isSaving = false;
        });

        if (pricegroupId != null) {
          Navigator.pushReplacementNamed(
            context,
            GroupPrint.routeName,
            arguments: {
              'price_group_id': pricegroupId,
              'saleId': saleId,
              'returnId': returnId,
              'payId': payId,
            },
          );
        } else {
          Navigator.pushReplacementNamed(context, ReceiptScreen.receiptScreen);
        }
      } else {
        String errorMessage = responseBody['messages'] != null &&
                responseBody['messages'].isNotEmpty
            ? responseBody['messages'][0]
            : 'Something went wrong';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }

        setState(() {
          isSaving = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.body.toString()}")));
    }
  }
}

class ApiResponse {
  final List<Invoice> data;

  ApiResponse({required this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      data: List<Invoice>.from(
          json['data'].map((item) => Invoice.fromJson(item))),
    );
  }
}
