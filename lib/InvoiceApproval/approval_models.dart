import 'dart:ui';

class ApprovalItem {
  final int id;
  final String invoiceNo;
  final String customer;
  final String createdBy;
  final String sentAt;
  final String reason;
  final String reasonLabel;
  final String state;
  final String? decidedAt;
  final double grandTotal;
  final bool isPos;

  ApprovalItem({
    required this.id,
    required this.invoiceNo,
    required this.customer,
    required this.createdBy,
    required this.sentAt,
    required this.reason,
    required this.reasonLabel,
    required this.state,
    required this.decidedAt,
    required this.grandTotal,
    required this.isPos,
  });

  factory ApprovalItem.fromJson(Map<String, dynamic> j) => ApprovalItem(
        id: int.tryParse('${j['id']}') ?? 0,
        invoiceNo: '${j['invoice_no'] ?? ''}',
        customer: '${j['customer'] ?? ''}',
        createdBy: '${j['created_by'] ?? ''}',
        sentAt: '${j['sent_at'] ?? ''}',
        reason: '${j['reason'] ?? ''}',
        reasonLabel: '${j['reason_label'] ?? ''}',
        state: '${j['state'] ?? 'pending'}',
        decidedAt: j['decided_at']?.toString(),
        grandTotal: double.tryParse('${j['grand_total']}') ?? 0,
        isPos: j['is_pos'] == true,
      );
}

class ApprovalListResult {
  final List<ApprovalItem> items;
  final int decimals;
  final int pendingCount;
  final String? error;

  ApprovalListResult({
    this.items = const [],
    this.decimals = 2,
    this.pendingCount = 0,
    this.error,
  });
}double _num(dynamic v) => double.tryParse('$v') ?? 0;

/// [background, foreground] by reason
List<Color> reasonColors(String reason) {
  switch (reason) {
    case 'credit_limit':
      return [const Color(0xFFFFF1DC), const Color(0xFF9A5B00)];
    case 'cogs_exceeds_revenue':
    case 'credit_limit_cogs':
      return [const Color(0xFFFBE7E9), const Color(0xFFB71C2B)];
    case 'discount_exceeds_vat':
      return [const Color(0xFFE6EEFD), const Color(0xFF2F55B8)];
    default:
      return [const Color(0xFFECEFF1), const Color(0xFF546E7A)];
  }
}

class ApprovalLine {
  final String product;
  final double quantity, rate, revenue, cost, margin;
  final bool isLoss, zeroRevenue;
  ApprovalLine({
    required this.product,
    required this.quantity,
    required this.rate,
    required this.revenue,
    required this.cost,
    required this.margin,
    required this.isLoss,
    required this.zeroRevenue,
  });
  factory ApprovalLine.fromJson(Map<String, dynamic> j) => ApprovalLine(
        product: '${j['product'] ?? ''}',
        quantity: _num(j['quantity']),
        rate: _num(j['rate']),
        revenue: _num(j['revenue']),
        cost: _num(j['cost']),
        margin: _num(j['margin']),
        isLoss: j['is_loss'] == true,
        zeroRevenue: j['zero_revenue'] == true,
      );
}

class AgingBucket {
  final String label;
  final double amount;
  AgingBucket(this.label, this.amount);
}

class OldestOpen {
  final String invoiceNo, date;
  final int ageDays;
  final double open;
  OldestOpen(this.invoiceNo, this.date, this.ageDays, this.open);
}

class ApprovalAging {
  final double creditLimit, totalOutstanding, overdue;
  final int creditDays;
  final List<AgingBucket> buckets;
  final List<OldestOpen> oldestOpen;
  ApprovalAging({
    required this.creditLimit,
    required this.creditDays,
    required this.totalOutstanding,
    required this.overdue,
    required this.buckets,
    required this.oldestOpen,
  });
  factory ApprovalAging.fromJson(Map<String, dynamic> j) => ApprovalAging(
        creditLimit: _num(j['credit_limit']),
        creditDays: int.tryParse('${j['credit_days']}') ?? 0,
        totalOutstanding: _num(j['total_outstanding']),
        overdue: _num(j['overdue']),
        buckets: (j['buckets'] as List? ?? [])
            .map((b) => AgingBucket('${b['label']}', _num(b['amount'])))
            .toList(),
        oldestOpen: (j['oldest_open'] as List? ?? [])
            .map((o) => OldestOpen('${o['invoice_no']}', '${o['date']}',
                int.tryParse('${o['age_days']}') ?? 0, _num(o['open'])))
            .toList(),
      );
}

class ApprovalTotals {
  final double sales, discount, netSales, cost, margin, vat, grandTotal;
  ApprovalTotals({
    required this.sales,
    required this.discount,
    required this.netSales,
    required this.cost,
    required this.margin,
    required this.vat,
    required this.grandTotal,
  });
  factory ApprovalTotals.fromJson(Map<String, dynamic> j) => ApprovalTotals(
        sales: _num(j['sales']),
        discount: _num(j['discount']),
        netSales: _num(j['net_sales']),
        cost: _num(j['cost']),
        margin: _num(j['margin']),
        vat: _num(j['vat']),
        grandTotal: _num(j['grand_total']),
      );
}

class ApprovalDetail {
  final int id, decimals;
  final String invoiceNo, date, state, customer, createdBy;
  final String reason, reasonLabel, reasonText, confirmText;
  final String? creditNote, approveBlockedReason;
  final bool isPos, canApprove, canReject;
  final ApprovalAging? aging;
  final List<ApprovalLine> lines;
  final ApprovalTotals totals;

  ApprovalDetail({
    required this.id,
    required this.decimals,
    required this.invoiceNo,
    required this.date,
    required this.state,
    required this.customer,
    required this.createdBy,
    required this.reason,
    required this.reasonLabel,
    required this.reasonText,
    required this.confirmText,
    required this.creditNote,
    required this.approveBlockedReason,
    required this.isPos,
    required this.canApprove,
    required this.canReject,
    required this.aging,
    required this.lines,
    required this.totals,
  });

  factory ApprovalDetail.fromJson(Map<String, dynamic> d) => ApprovalDetail(
        id: int.tryParse('${d['id']}') ?? 0,
        decimals: int.tryParse('${d['currency_decimals']}') ?? 2,
        invoiceNo: '${d['invoice_no'] ?? ''}',
        date: '${d['date'] ?? ''}',
        state: '${d['state'] ?? 'pending'}',
        customer: '${(d['customer'] as Map?)?['name'] ?? ''}',
        createdBy: '${d['created_by'] ?? ''}',
        reason: '${d['reason'] ?? ''}',
        reasonLabel: '${d['reason_label'] ?? ''}',
        reasonText: '${d['reason_text'] ?? ''}',
        confirmText: '${d['confirm_text'] ?? ''}',
        creditNote: d['credit_note']?.toString(),
        approveBlockedReason: d['approve_blocked_reason']?.toString(),
        isPos: d['is_pos'] == true,
        canApprove: d['can_approve'] == true,
        canReject: d['can_reject'] == true,
        aging: d['aging'] == null
            ? null
            : ApprovalAging.fromJson(Map<String, dynamic>.from(d['aging'])),
        lines: (d['lines'] as List? ?? [])
            .map((e) => ApprovalLine.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        totals:
            ApprovalTotals.fromJson(Map<String, dynamic>.from(d['totals'] ?? {})),
      );
}

class DetailResult {
  final ApprovalDetail? detail;
  final String? error;
  final bool notFound;
  final bool unauthorized;
  DetailResult(
      {this.detail, this.error, this.notFound = false, this.unauthorized = false});
}

class ActionResult {
  final bool ok;
  final int? statusCode;
  final String message;
  final bool offline;
  ActionResult(
      {required this.ok,
      this.statusCode,
      required this.message,
      this.offline = false});

  bool get alreadyHandled =>
      !ok && message.toLowerCase().contains('not awaiting approval');
}