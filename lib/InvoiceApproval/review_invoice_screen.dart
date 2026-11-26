import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobizapp/InvoiceApproval/push_router.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/loginpage.dart';
import 'package:mobizapp/Utilities/auth_client.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'approval_action_sheet.dart';
import 'approval_models.dart';
import 'invoice_approval_service.dart';

class ReviewInvoiceScreen extends StatefulWidget {
  final int invoiceId;
  const ReviewInvoiceScreen({super.key, required this.invoiceId});

  @override
  State<ReviewInvoiceScreen> createState() => _ReviewInvoiceScreenState();
}

class _ReviewInvoiceScreenState extends State<ReviewInvoiceScreen> {
    static const Color _navy = AppConfig.colorPrimary;
  static const Color _red = Color(0xFFE8253A);
  static const Color _teal = Color(0xFF1F9E8C);
  static const Color _bg = Color(0xFFF5F6FA);
  DetailResult? _res;
  bool _loading = true;
  bool _alreadyHandled = false;
  bool _showOldest = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await InvoiceApprovalService.getDetail(widget.invoiceId);
    if (!mounted) return;
    setState(() {
      _res = r;
      _loading = false;
    });
  }

  String _fmt(double v, int dec) =>
      NumberFormat('#,##0${dec > 0 ? '.${'0' * dec}' : ''}').format(v);

  String _signed(double v, int dec) =>
      '${v < 0 ? '−' : '+'}${_fmt(v.abs(), dec)}';

  String _qty(double q) => q == q.roundToDouble() ? '${q.toInt()}' : '$q';

  String _date(String raw) {
    final d = DateTime.tryParse(raw);
    return d == null ? raw : DateFormat('d MMM yyyy').format(d);
  }

  Future<void> _openSheet(ApprovalDetail d, bool approve) async {
    final r = await showModalBottomSheet<ActionResult>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ApprovalActionSheet(detail: d, approve: approve),
    );
    if (r == null || !mounted) return;
    if (r.ok) {
      PushRouter.markInvoiceNotificationsRead(widget.invoiceId);
      Navigator.pop(context, r.message);
    } else if (r.alreadyHandled) {
      PushRouter.markInvoiceNotificationsRead(widget.invoiceId);
      setState(() => _alreadyHandled = true);
    } else if (r.statusCode == 401) {
      _goToLogin();
    }
  }
  Future<void> _goToLogin() async {
    PushRouter.savePending({
      'screen': 'invoice_approval',
      'invoice_id': '${widget.invoiceId}',
    });
    await TokenStore.clear();
    AppState().loginState = "";
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
        LoginScreen.routeName, (_) => false);
  }
  @override
  Widget build(BuildContext context) {
    final d = _res?.detail;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text(d?.invoiceNo ?? 'Invoice',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        bottom: d == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${d.customer} · ${_date(d.date)} · by ${d.createdBy}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
              ),
      ),
      body: _body(),
      bottomNavigationBar:
          (d != null && d.state == 'pending' && !_alreadyHandled)
              ? _bottomBar(d)
              : null,
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final r = _res;
    if (r == null) return const SizedBox.shrink();

    if (r.notFound) {
      return _messageView(Icons.lock_outline, 'Not available',
          'This invoice is not one of your approvals.', 'Back to list',
          () => Navigator.pop(context));
    }
     if (r.unauthorized) {
      return _messageView(Icons.lock_outline, 'Session expired',
          r.error ?? 'Please login again.', 'Log in', _goToLogin);
    }
    if (r.detail == null) {
      return _messageView(Icons.cloud_off, 'Could not load',
          r.error ?? 'Something went wrong.', 'Try again', _load);
    }
    if (_alreadyHandled) {
      return _messageView(
          Icons.priority_high,
          'Already handled',
          'This invoice is not awaiting approval any more (already approved or rejected).',
          'Back to list',
          () => Navigator.pop(context));
    }
    return _content(r.detail!);
  }

  Widget _messageView(IconData icon, String title, String text, String btn,
      VoidCallback onTap) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE3E8EC)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0xFFFFF1DC),
              child: Icon(icon, size: 34, color: const Color(0xFF9A5B00)),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(btn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(ApprovalDetail d) {
    final dec = d.decimals;
    final c = reasonColors(d.reason);
    final t = d.totals;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (d.state != 'pending') _stateBanner(d.state),

        // Reason box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c[0],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c[1].withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.reasonLabel,
                  style: TextStyle(
                      color: c[1], fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(d.reasonText, style: const TextStyle(fontSize: 14.5)),
            ],
          ),
        ),

        if (d.aging != null) ...[
          _section('CUSTOMER CREDIT'),
          _creditCard(d),
        ],

        _section('TOTALS (${AppState().code ?? ''})'),
        Row(
          children: [
            _tile('Net sales', _fmt(t.netSales, dec), null),
            const SizedBox(width: 10),
            _tile('Cost', _fmt(t.cost, dec), null),
            const SizedBox(width: 10),
            _tile('Margin', _fmt(t.margin, dec),
                t.margin < 0 ? _red : null),
          ],
        ),
        if (t.discount != 0 || t.vat != 0)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              [
                if (t.discount != 0) 'Discount ${_fmt(t.discount, dec)}',
                           if (t.vat != 0) 'VAT ${_fmt(t.vat, dec)}',
              ].join('   ·   '),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),

        _section('LINES (${d.lines.length})'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3E8EC)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < d.lines.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: Color(0xFFE3E8EC)),
                _line(d.lines[i], dec),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8, left: 2),
        child: Text(text,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                fontSize: 13)),
      );

  Widget _tile(String label, String value, Color? valueColor) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3E8EC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: valueColor)),
              ),
            ],
          ),
        ),
      );

  Widget _line(ApprovalLine l, int dec) {
    final loss = l.isLoss;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: loss ? const Color(0xFFFFEEEE) : Colors.white,
        border: Border(
          left: BorderSide(
              color: loss ? _red : Colors.transparent, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.product,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800)),
              ),
              Text(_fmt(l.revenue, dec),
                  style: const TextStyle(fontSize: 15.5)),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_qty(l.quantity)} × ${_fmt(l.rate, dec)}'
                  '${loss ? ' · cost ${_fmt(l.quantity == 0 ? l.cost : l.cost / l.quantity, dec)}' : ''}',
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13.5),
                ),
              ),
              Text(_signed(l.margin, dec),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: loss ? _red : Colors.grey.shade600)),
            ],
          ),
          if (l.zeroRevenue)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Rate 0 – cannot be posted',
                  style: TextStyle(
                      color: _red,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _creditCard(ApprovalDetail d) {
    final a = d.aging!;
    final dec = d.decimals;
    final over = a.totalOutstanding > a.creditLimit;
    const barColors = [
      Color(0xFF1F9E8C),
      Color(0xFF7CC4AB),
      Color(0xFFF1B443),
      Color(0xFFEB8A3E),
      Color(0xFFE8253A),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Credit limit · days',
              '${_fmt(a.creditLimit, dec)} · ${a.creditDays}', null),
          const SizedBox(height: 8),
          _kv('Outstanding incl. this', _fmt(a.totalOutstanding, dec),
              over ? _red : null),
          const SizedBox(height: 12),
          if (a.buckets.isNotEmpty) ...[
            Row(
              children: [
                for (int i = 0; i < a.buckets.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                    flex: (a.buckets[i].amount / 100).round().clamp(1, 100000),
                    child: Container(
                      height: 9,
                      decoration: BoxDecoration(
                        color: barColors[i % barColors.length],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                for (int i = 0; i < a.buckets.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle,
                          size: 8, color: barColors[i % barColors.length]),
                      const SizedBox(width: 4),
                      Text(
                          '${a.buckets[i].label}  ${_fmt(a.buckets[i].amount, dec)}',
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ],
          if (d.creditNote != null && d.creditNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 18, color: Color(0xFF9A5B00)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(d.creditNote!,
                      style: const TextStyle(
                          color: Color(0xFF9A5B00),
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5)),
                ),
              ],
            ),
          ],
          if (a.oldestOpen.isNotEmpty) ...[
            InkWell(
              onTap: () => setState(() => _showOldest = !_showOldest),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Text(
                        _showOldest
                            ? 'Hide oldest open invoices'
                            : 'Show oldest open invoices',
                        style: const TextStyle(
                            color: _teal, fontWeight: FontWeight.w700)),
                    Icon(_showOldest ? Icons.expand_less : Icons.expand_more,
                        color: _teal),
                  ],
                ),
              ),
            ),
            if (_showOldest)
              for (final o in a.oldestOpen.take(8))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(
                              '${o.invoiceNo} · ${_date(o.date)} · ${o.ageDays} days',
                              style: const TextStyle(fontSize: 13))),
                      Text(_fmt(o.open, dec),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v, Color? vColor) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(color: Colors.grey.shade600)),
          Text(v,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16, color: vColor)),
        ],
      );

  Widget _stateBanner(String state) {
    final ok = state == 'approved';
    final fg = ok ? const Color(0xFF0E7C66) : const Color(0xFFB71C2B);
    final bg = ok ? const Color(0xFFE0F4EF) : const Color(0xFFFBE7E9);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel, color: fg),
          const SizedBox(width: 8),
          Text(ok ? 'This invoice was approved.' : 'This invoice was rejected.',
              style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _bottomBar(ApprovalDetail d) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3E8EC))),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!d.canApprove &&
                (d.approveBlockedReason ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(d.approveBlockedReason!,
                    style: const TextStyle(
                        color: _red, fontWeight: FontWeight.w600)),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: d.canReject ? () => _openSheet(d, false) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: const BorderSide(color: _red, width: 1.5),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Reject',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: d.canApprove ? () => _openSheet(d, true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _teal.withOpacity(0.35),
                      disabledForegroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Approve',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}