import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobizapp/InvoiceApproval/push_router.dart';
import 'package:mobizapp/InvoiceApproval/review_invoice_screen.dart';
import 'package:mobizapp/confg/appconfig.dart';
import 'approval_models.dart';
import 'invoice_approval_service.dart';

class ApprovalListScreen extends StatefulWidget {
  const ApprovalListScreen({super.key});

  @override
  State<ApprovalListScreen> createState() => _ApprovalListScreenState();
}

class _ApprovalListScreenState extends State<ApprovalListScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _navy = AppConfig.colorPrimary; 
  static const Color _red = Color(0xFFE8253A);
  static const Color _bg = Color(0xFFF5F6FA); 
  late final TabController _tabs;
  ApprovalListResult? _pending;
  ApprovalListResult? _done;
  bool _loadingPending = true;
  bool _loadingDone = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
    _load('pending');
    _load('done');
    PushRouter.approvalsChanged.addListener(_refreshBoth);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
 PushRouter.approvalsChanged.removeListener(_refreshBoth); 
    _tabs.dispose();
    super.dispose();
  }
  void _refreshBoth() {
    _load('pending');
    _load('done');
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load('pending');
      _load('done');
    }
  }

  Future<void> _load(String tab) async {
    if (tab == 'pending') {
      setState(() => _loadingPending = true);
    } else {
      setState(() => _loadingDone = true);
    }
    final r = await InvoiceApprovalService.getList(tab);
    if (!mounted) return;
    setState(() {
      if (tab == 'pending') {
        _pending = r;
        _loadingPending = false;
      } else {
        _done = r;
        _loadingDone = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _pending?.pendingCount ?? 0;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
              title: const Text('Invoice Approvals', style: AppConfig.pageTitleStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _load('pending');
              _load('done');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: _navy,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pending'),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: _red,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('$pendingCount',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Done'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildTab('pending', _pending, _loadingPending,
              'No invoices waiting for your approval.'),
          _buildTab('done', _done, _loadingDone, 'Nothing here yet.'),
        ],
      ),
    );
  }

  Widget _buildTab(
      String tab, ApprovalListResult? r, bool loading, String emptyText) {
    if (loading && r == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () => _load(tab),
      child: _tabBody(tab, r, emptyText),
    );
  }

  Widget _tabBody(String tab, ApprovalListResult? r, String emptyText) {
    // ListView, so pull-to-refresh error/empty state-ilum work aakum
    if (r == null || r.error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Center(
              child: Text(r?.error ?? 'Could not load invoices.',
                  textAlign: TextAlign.center)),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
                onPressed: () => _load(tab), child: const Text('Try again')),
          ),
        ],
      );
    }
    if (r.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Center(child: Text(emptyText)),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(14),
      itemCount: r.items.length + 1,
      itemBuilder: (context, i) {
        if (i == r.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text('Pull down to refresh',
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
          );
        }
        return _card(r.items[i], r.decimals);
      },
    );
  }

   String _money(double v, int decimals) => NumberFormat(
          '#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}')
      .format(v);

  Widget _posChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFE0F4EF),
            borderRadius: BorderRadius.circular(10)),
        child: const Text('POS',
            style: TextStyle(
                color: Color(0xFF0E7C66),
                fontSize: 11.5,
                fontWeight: FontWeight.w700)),
      );

  Widget _card(ApprovalItem it, int decimals) {
    final isDone = it.state == 'approved' || it.state == 'rejected';
    final when =
        _fmtWhen(isDone && it.decidedAt != null ? it.decidedAt! : it.sentAt);

    return GestureDetector(
      onTap: () async {
        final msg = await Navigator.push<String>(
          context,
          MaterialPageRoute(
              builder: (_) => ReviewInvoiceScreen(invoiceId: it.id)),
        );
        if (!mounted) return;
        _load('pending');
        _load('done');
        if (msg != null && msg.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(it.invoiceNo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F1147))),
                ),
                const SizedBox(width: 8),
                Text(_money(it.grandTotal, decimals),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F1147))),
              ],
            ),
            const SizedBox(height: 4),
            Text(it.customer, style: const TextStyle(fontSize: 14.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (it.isPos) _posChip(),
                isDone ? _stateChip(it.state) : _reasonChip(it),
                Text(
                  isDone ? when : 'by ${it.createdBy} · $when',
                  style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _reasonChip(ApprovalItem it) {
    Color bg, fg;
    switch (it.reason) {
      case 'credit_limit':
        bg = const Color(0xFFFFF1DC);
        fg = const Color(0xFF9A5B00);
        break;
      case 'cogs_exceeds_revenue':
      case 'credit_limit_cogs':
        bg = const Color(0xFFFBE7E9);
        fg = const Color(0xFFB71C2B);
        break;
      case 'discount_exceeds_vat':
        bg = const Color(0xFFE6EEFD);
        fg = const Color(0xFF2F55B8);
        break;
      default: // scrap_sale, cost_deviation, unknown -> grey
        bg = const Color(0xFFECEFF1);
        fg = const Color(0xFF546E7A);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: fg),
        const SizedBox(width: 6),
        Flexible(
          child: Text(it.reasonLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: fg, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ),
      ]),
    );
  }

  Widget _stateChip(String state) {
    final ok = state == 'approved';
    final fg = ok ? const Color(0xFF0E7C66) : const Color(0xFFB71C2B);
    final bg = ok ? const Color(0xFFE0F4EF) : const Color(0xFFFBE7E9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ok ? Icons.check : Icons.close, size: 14, color: fg),
        const SizedBox(width: 4),
        Text(ok ? 'Approved' : 'Rejected',
            style: TextStyle(
                color: fg, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ]),
    );
  }

  /// innu aanenkil "9:40 AM", allenkil "Yesterday" / "23 Nov"
  String _fmtWhen(String raw) {
    final d = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (d == null) return raw;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return DateFormat('h:mm a').format(d);
    if (diff == 1) return 'Yesterday';
    return DateFormat('d MMM').format(d);
  }
}