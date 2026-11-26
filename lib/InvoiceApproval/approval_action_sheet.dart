import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'approval_models.dart';
import 'invoice_approval_service.dart';

class ApprovalActionSheet extends StatefulWidget {
  final ApprovalDetail detail;
  final bool approve;
  const ApprovalActionSheet(
      {super.key, required this.detail, required this.approve});

  @override
  State<ApprovalActionSheet> createState() => _ApprovalActionSheetState();
}

class _ApprovalActionSheetState extends State<ApprovalActionSheet> {
  static const Color _red = Color(0xFFE8253A);
  static const Color _teal = Color(0xFF1F9E8C);

  final TextEditingController _ctrl = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _money(double v) {
    final d = widget.detail.decimals;
    final f = NumberFormat('#,##0${d > 0 ? '.${'0' * d}' : ''}');
    return '${AppState().code ?? ''} ${f.format(v)}'.trim();
  }

  Future<void> _submit() async {
    if (_sending) return; // one tap only
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    final id = widget.detail.id;
    final ActionResult r = widget.approve
        ? await InvoiceApprovalService.approve(id, text)
        : await InvoiceApprovalService.reject(id, text);
    if (!mounted) return;

     if (r.ok || r.alreadyHandled || r.statusCode == 401) {
      Navigator.pop(context, r);
      return;
    }
    setState(() {
      _sending = false; // text stays as typed
      _error = r.offline
          ? (widget.approve
              ? 'No connection. Nothing was approved – try again.'
              : 'No connection. Nothing was rejected – try again.')
          : r.message;
    });
  }

 @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final color = widget.approve ? _teal : _red;
    final canSend = !_sending && _ctrl.text.trim().isNotEmpty;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final navBarPadding = MediaQuery.of(context).viewPadding.bottom;

    return PopScope(
      canPop: !_sending, // sheet cannot be closed while sending
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          (bottomInset > 0 ? bottomInset : navBarPadding) + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                      color: const Color(0xFFD5D9E2),
                      borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.approve ? 'Approve invoice?' : 'Reject invoice?',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text.rich(TextSpan(
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                children: [
                  TextSpan(text: '${d.invoiceNo} · ${d.customer} · '),
                  TextSpan(
                      text: _money(d.totals.grandTotal),
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w800)),
                ],
              )),
              const SizedBox(height: 12),
              if (widget.approve)
                Text(d.confirmText,
                    style:
                        TextStyle(color: Colors.grey.shade700, fontSize: 14))
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF6CACF)),
                  ),
                  child: const Text(
                    'The invoice will be cancelled: stock goes back and the sales order lines are released, so a new invoice can be made. This cannot be undone.',
                    style: TextStyle(color: Color(0xFF9C1C2A), fontSize: 14),
                  ),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: _ctrl,
                enabled: !_sending,
                maxLength: 500,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: widget.approve ? 'Remarks' : 'Reason',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
              ),
              Text(
                widget.approve
                    ? 'Remarks are required and are saved on the invoice and in the audit log.'
                    : 'The reason is required and is sent to the salesman.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: const TextStyle(
                        color: _red, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _sending ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canSend ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: color.withOpacity(0.4),
                        disabledForegroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : Text(widget.approve
                              ? 'Approve & post'
                              : 'Reject invoice'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}