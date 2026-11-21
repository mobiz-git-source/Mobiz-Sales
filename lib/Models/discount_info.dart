class DiscountInfo {
  final String? type; // 'percent' | 'amount' | null
  final num? percent;
  final num amount;
  final String text;
  final String label;

  const DiscountInfo({
    this.type,
    this.percent,
    this.amount = 0,
    this.text = '',
    this.label = 'Discount',
  });

  static num? _n(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  factory DiscountInfo.fromJson(Map<String, dynamic> j) => DiscountInfo(
        type: j['type']?.toString(),
        percent: _n(j['percent']),
        amount: _n(j['amount']) ?? 0,
        text: j['text']?.toString() ?? '',
        label: j['label']?.toString() ?? 'Discount',
      );

  static DiscountInfo? tryParse(dynamic v) =>
      v is Map ? DiscountInfo.fromJson(Map<String, dynamic>.from(v)) : null;

  bool get hasDiscount => amount > 0;

  Map<String, dynamic> toJson() => {
        'type': type,
        'percent': percent,
        'amount': amount,
        'text': text,
        'label': label,
      };
}