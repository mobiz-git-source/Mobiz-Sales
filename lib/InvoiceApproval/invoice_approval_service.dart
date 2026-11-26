import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import 'approval_models.dart';

class InvoiceApprovalService {
    static const bool useMock =
      bool.fromEnvironment('APPROVAL_MOCK', defaultValue: false);

  static String get _base => '${RestDatasource().BASE_URL}/api';

  static Map<String, String> _headers() => {
        'Authorization': 'Bearer ${AppState().token ?? ''}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  /// {'is_approver': bool, 'pending_count': int}
  static Future<Map<String, dynamic>> getSummary() async {
    if (useMock) return {'is_approver': true, 'pending_count': 3};

    final token = AppState().token?.toString() ?? '';
    if (token.isEmpty) return {'is_approver': false, 'pending_count': 0};
    try {
      final response = await http.get(
          Uri.parse('$_base/invoice-approvals/summary'),
          headers: _headers());
      debugPrint('APPROVAL SUMMARY ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          return {
            'is_approver': json['data']['is_approver'] == true,
            'pending_count':
                int.tryParse('${json['data']['pending_count']}') ?? 0,
          };
        }
      }
    } catch (e) {
      debugPrint('APPROVAL SUMMARY ERROR: $e');
    }
    return {'is_approver': false, 'pending_count': 0};
  }

  /// tab = 'pending' | 'done'
  static Future<ApprovalListResult> getList(String tab) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _parseList(_mockList(tab));
    }
    try {
      final response = await http.get(
          Uri.parse('$_base/invoice-approvals?tab=$tab'),
          headers: _headers());
      debugPrint('APPROVAL LIST($tab) ${response.statusCode}');

      Map<String, dynamic> json = {};
      try {
        json = jsonDecode(response.body);
      } catch (_) {}

      if (response.statusCode == 200 && json['success'] == true) {
        return _parseList(json);
      }
      if (response.statusCode == 401) {
        return ApprovalListResult(error: 'Session expired. Please login again.');
      }
      final msgs = json['messages'];
      final msg = (msgs is List && msgs.isNotEmpty)
          ? '${msgs[0]}'
          : 'Could not load invoices.';
      return ApprovalListResult(error: msg);
    } catch (e) {
      debugPrint('APPROVAL LIST ERROR: $e');
      return ApprovalListResult(error: 'No connection. Please try again.');
    }
  }

  static ApprovalListResult _parseList(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final list = (data['invoices'] as List? ?? [])
        .map((e) => ApprovalItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return ApprovalListResult(
      items: list,
      decimals: int.tryParse('${data['currency_decimals']}') ?? 2,
      pendingCount: int.tryParse('${data['pending_count']}') ?? 0,
    );
  }
  static final Set<int> _mockHandled = {};

  static Future<DetailResult> getDetail(int id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return DetailResult(
          detail: ApprovalDetail.fromJson(
              Map<String, dynamic>.from(_mockDetail(id)['data'])));
    }
    try {
      final response = await http.get(
          Uri.parse('$_base/invoice-approvals/$id'),
          headers: _headers());
      debugPrint('APPROVAL DETAIL($id) ${response.statusCode}');
      Map<String, dynamic> json = {};
      try {
        json = jsonDecode(response.body);
      } catch (_) {}

      if (response.statusCode == 200 && json['success'] == true) {
        return DetailResult(
            detail: ApprovalDetail.fromJson(
                Map<String, dynamic>.from(json['data'])));
      }
      if (response.statusCode == 404) return DetailResult(notFound: true);
      if (response.statusCode == 401) {
        return DetailResult(
            unauthorized: true, error: 'Session expired. Please login again.');
      }
      return DetailResult(error: _firstMessage(json, 'Could not load invoice.'));
    } catch (e) {
      debugPrint('APPROVAL DETAIL ERROR: $e');
      return DetailResult(error: 'No connection. Please try again.');
    }
  }

  static Future<ActionResult> approve(int id, String remarks) =>
      _post(id, 'approve', {'remarks': remarks},
          'Invoice approved and posted.');

  static Future<ActionResult> reject(int id, String reason) =>
      _post(id, 'reject', {'reason': reason}, 'Sale cancelled successfully.');

  static Future<ActionResult> _post(
      int id, String action, Map<String, String> body, String mockMsg) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 900));
      _mockHandled.add(id);
      return ActionResult(ok: true, statusCode: 200, message: mockMsg);
    }
    try {
      final response = await http.post(
        Uri.parse('$_base/invoice-approvals/$id/$action'),
        headers: _headers(),
        body: jsonEncode(body),
      );
      debugPrint('APPROVAL $action($id) ${response.statusCode}');
      Map<String, dynamic> json = {};
      try {
        json = jsonDecode(response.body);
      } catch (_) {}
      final msg = _firstMessage(json, 'Something went wrong. Please try again.');
      final ok = response.statusCode == 200 && json['success'] == true;
      return ActionResult(
          ok: ok, statusCode: response.statusCode, message: msg);
    } catch (e) {
      debugPrint('APPROVAL $action ERROR: $e');
      // nothing was sent / no reply: never treat as success
      return ActionResult(
          ok: false, message: 'No connection.', offline: true);
    }
  }

  static String _firstMessage(Map<String, dynamic> json, String fallback) {
    final m = json['messages'];
    if (m is List && m.isNotEmpty) return '${m[0]}';
    return fallback;
  }

  static Map<String, dynamic> _mockDetail(int id) {
    final isPos = id == 731;
    final isCredit = id == 48812;
    final no = isPos
        ? 'POS-16-000731'
        : (isCredit ? 'INV-16-004812' : 'INV-16-004809');
    final cust = isPos
        ? 'Walk-in · Sharjah Branch'
        : (isCredit ? 'Al Noor Trading LLC' : 'Gulf Fresh LLC');
    final reason = isPos
        ? 'discount_exceeds_vat'
        : (isCredit ? 'credit_limit' : 'cogs_exceeds_revenue');
    final label = isPos
        ? 'Discount above VAT'
        : (isCredit ? 'Credit limit / days' : 'Cost above sale price');
    return {
      'data': {
        'id': id,
        'invoice_no': no,
        'date': '2026-11-24',
        'is_pos': isPos,
        'state': 'pending',
        'customer': {'id': 912, 'name': cust, 'code': 'C-0412'},
        'created_by': isPos ? 'Faisal' : (isCredit ? 'Rashid' : 'Anil'),
        'reason': reason,
        'reason_label': label,
        'reason_text': isCredit
            ? 'The customer is over the credit limit or has an invoice older than the credit days. Approving posts the invoice and its outstanding.'
            : 'Sent for approval. Loss-making lines are marked.',
        'confirm_text': isCredit
            ? 'This posts the invoice and its outstanding even though the customer is over the credit limit / credit days.'
            : 'This posts the invoice.',
        'credit_note': isCredit
            ? 'Outstanding 58,920.00 is over the credit limit 50,000.00.'
            : null,
        'aging': isCredit
            ? {
                'credit_limit': 50000.00,
                'credit_days': 60,
                'total_outstanding': 58920.00,
                'overdue': 9150.00,
                'buckets': [
                  {'label': '0-30 days', 'amount': 23500.00},
                  {'label': '31-60 days', 'amount': 12960.00},
                  {'label': '61-90 days', 'amount': 10610.00},
                  {'label': '91-120 days', 'amount': 7060.00},
                  {'label': '120+ days', 'amount': 4790.00},
                ],
                'oldest_open': [
                  {
                    'invoice_no': 'INV-16-003120',
                    'date': '2026-06-02',
                    'age_days': 174,
                    'open': 4790.00
                  }
                ],
              }
            : null,
        'lines': [
          {'product': 'Basmati Rice 5kg', 'quantity': 120, 'rate': 38.50,
           'revenue': 4620.00, 'cost': 3807.60, 'margin': 812.40,
           'is_loss': false, 'zero_revenue': false},
          {'product': 'Sunflower Oil 1.8L', 'quantity': 60, 'rate': 17.00,
           'revenue': 1020.00, 'cost': 1086.00, 'margin': -66.00,
           'is_loss': true, 'zero_revenue': false},
          {'product': 'Sugar 2kg', 'quantity': 200, 'rate': 9.75,
           'revenue': 1950.00, 'cost': 1736.00, 'margin': 214.00,
           'is_loss': false, 'zero_revenue': false},
          if (isPos)
            {'product': 'Free sample pack', 'quantity': 10, 'rate': 0,
             'revenue': 0, 'cost': 45.00, 'margin': -45.00,
             'is_loss': true, 'zero_revenue': true},
        ],
        'totals': {
          'sales': 12638.00, 'discount': 600.00, 'net_sales': 12038.00,
          'cost': 10412.00, 'margin': 1626.00, 'vat': 601.90,
          'grand_total': 12640.00
        },
        'currency_decimals': 2,
        'can_approve': !isPos,
        'can_reject': true,
        'approve_blocked_reason': isPos
            ? 'A line has rate 0, so this invoice cannot be posted. You can only reject it.'
            : null,
      },
      'messages': [],
    };
  }
 
  static Map<String, dynamic> _mockList(String tab) {
    if (tab == 'done') {
      return {
        'data': {
          'tab': 'done',
          'pending_count': 3,
          'currency_decimals': 2,
          'invoices': [
            {'id': 48812, 'invoice_no': 'INV-16-004812', 'sent_at': '2026-11-23 09:40',
             'customer': 'Al Noor Trading LLC', 'created_by': 'Rashid', 'grand_total': 12640.00,
             'is_pos': false, 'reason': 'credit_limit', 'reason_label': 'Credit limit / days',
             'state': 'approved', 'decided_at': '2026-11-23 09:43'},
            {'id': 48790, 'invoice_no': 'INV-16-004790', 'sent_at': '2026-11-22 16:10',
             'customer': 'Blue Bay Supermarket', 'created_by': 'Anil', 'grand_total': 2205.00,
             'is_pos': false, 'reason': 'cogs_exceeds_revenue', 'reason_label': 'Cost above sale price',
             'state': 'rejected', 'decided_at': '2026-11-22 16:30'},
          ],
        }
      };
    }
    return {
      'data': {
        'tab': 'pending',
        'pending_count': 3 - _mockHandled.length,
        'currency_decimals': 2,
        'invoices': [
          {'id': 48812, 'invoice_no': 'INV-16-004812', 'sent_at': '2026-11-24 09:40',
           'customer': 'Al Noor Trading LLC', 'created_by': 'Rashid', 'grand_total': 12640.00,
           'is_pos': false, 'reason': 'credit_limit', 'reason_label': 'Credit limit / days',
           'state': 'pending', 'decided_at': null},
          {'id': 48809, 'invoice_no': 'INV-16-004809', 'sent_at': '2026-11-24 09:28',
           'customer': 'Gulf Fresh LLC', 'created_by': 'Anil', 'grand_total': 3180.50,
           'is_pos': false, 'reason': 'cogs_exceeds_revenue', 'reason_label': 'Cost above sale price',
           'state': 'pending', 'decided_at': null},
          {'id': 731, 'invoice_no': 'POS-16-000731', 'sent_at': '2026-11-23 17:05',
           'customer': 'Walk-in · Sharjah Branch', 'created_by': 'Faisal', 'grand_total': 845.00,
           'is_pos': true, 'reason': 'discount_exceeds_vat', 'reason_label': 'Discount above VAT',
           'state': 'pending', 'decided_at': null},
        ],
      }
    };
  }
}