import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Pages/loginpage.dart';
import 'package:mobizapp/Pages/Notifications/notifications.dart';
import 'package:mobizapp/main.dart' show navigatorKey;
import 'review_invoice_screen.dart';

class PushRouter {
  static Map<String, dynamic>? _pending;

  
  static final ValueNotifier<int> approvalsChanged = ValueNotifier<int>(0);

  static bool get _loggedIn =>
      AppState().loginState == 'LOGGED_IN' &&
      '${AppState().token ?? ''}'.isNotEmpty;

 
  static Map<String, dynamic> payloadOf(RemoteMessage m) => {
        ...m.data,
        '_title': m.notification?.title ?? '',
        '_body': m.notification?.body ?? '',
      }; 
  static void onForeground() => approvalsChanged.value++;

  static void savePending(Map<String, dynamic> d) => _pending = d;

  static void onLocalTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      onTap(Map<String, dynamic>.from(jsonDecode(payload)));
    } catch (_) {}
  }

  /// User push tap cheythu. coldStart = app close aayirunnu.
  static void onTap(Map<String, dynamic> d, {bool coldStart = false}) {
    if (d.isEmpty) return;
    if (coldStart) {
      _pending = d; 
      return;
    }
    if (!_loggedIn) {
      _pending = d;
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
          LoginScreen.routeName, (_) => false);
      return;
    }
    _open(d);
  }

 
  /// Invoice approve / reject aayaal aa invoice-inte approval notifications read aakkum
  static Future<void> markInvoiceNotificationsRead(int invoiceId) async {
    try {
      final list = await NotificationService.getNotifications();
      for (final e in list) {
        if (e is! Map) continue;
        if (!'${e['type'] ?? ''}'.startsWith('invoice_approval_')) continue;
        final r = e['is_read'];
        if (r == true || r == 1 || r == '1') continue;
        final data = e['data'];
        final inv = int.tryParse('${data is Map ? data['invoice_id'] : ''}');
        if (inv != invoiceId) continue;
        final id = int.tryParse('${e['id']}');
        if (id != null) await NotificationService.markAsRead(id);
      }
    } catch (_) {}
    approvalsChanged.value++; // bell count + list refresh
  }

  static void consumePending() {
    final d = _pending;
    if (d == null || !_loggedIn) return;
    _pending = null;
    _open(d);
  }

  static void _open(Map<String, dynamic> d) {
    final nav = navigatorKey.currentState;
    final ctx = navigatorKey.currentContext;
    if (nav == null || ctx == null) return;

    final type = '${d['type'] ?? ''}';
    final screen = '${d['screen'] ?? ''}';

    final nid = int.tryParse('${d['notification_id']}');
    if (nid != null) NotificationService.markAsRead(nid);


    if (screen == 'invoice_approval' || type.startsWith('invoice_approval_')) {
      final id = int.tryParse('${d['invoice_id']}');
      if (id == null) return;
      nav
          .push<String>(MaterialPageRoute(
              builder: (_) => ReviewInvoiceScreen(invoiceId: id)))
          .then((msg) {
        approvalsChanged.value++;
        final c = navigatorKey.currentContext;
        if (c != null && msg != null && msg.isNotEmpty) {
          ScaffoldMessenger.of(c)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      });
      return;
    }

   
    if (type == 'invoice_approved' || type == 'invoice_rejected') {
      final title = '${d['_title'] ?? ''}'.isNotEmpty
          ? '${d['_title']}'
          : (type == 'invoice_approved'
              ? 'Invoice Approved'
              : 'Invoice Rejected');
      var body = '${d['_body'] ?? ''}';
      final why = '${d['rejection_reason'] ?? ''}';
      if (type == 'invoice_rejected' && why.isNotEmpty && !body.contains(why)) {
        body = '$body\n\nReason: $why';
      }
      showDialog(
        context: ctx,
        builder: (dc) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dc), child: const Text('OK'))
          ],
        ),
      );
    }
  }
}