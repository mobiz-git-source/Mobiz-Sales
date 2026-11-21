class SOAResponse {
  final List<List<dynamic>> data;
  final double opening;
  final double closing;
  final bool success;
  final List<String> messages;

  SOAResponse({
    required this.data,
    required this.opening,
    required this.closing,
    required this.success,
    required this.messages,
  });

  factory SOAResponse.fromJson(Map<String, dynamic> json) {
    return SOAResponse(
      data: List<List<dynamic>>.from(
          json['data'].map((item) => List<dynamic>.from(item.map((e) => e)))),
      opening: (json['opening'] as num?)?.toDouble() ?? 0,
      closing: (json['closing'] as num?)?.toDouble() ?? 0,
      success: json['success'] as bool,
      messages: List<String>.from(json['messages'].map((x) => x as String)),
    );
  }
}

class SOAData {
  final String date;
  final String reference;
  final String amount;
  final String payment;
  final String balance;

  SOAData({
    required this.date,
    required this.reference,
    required this.amount,
    required this.payment,
    required this.balance,
  });

  factory SOAData.fromJson(Map<String, dynamic> json) {
    return SOAData(
      date: json['date'] ?? '',
      reference: json['reference'] ?? '',
      amount: json['amount'].toString(), // Convert to string
      payment: json['payment'].toString(), // Convert to string
      balance: json['balance'].toString(), // Convert to string
    );
  }
}

class Transaction {
  int id;
  int customerId;
  String? billMode;
  String inDate;
  String inTime;
  String invoiceNo;
  dynamic deliveryNo;
  double otherCharge;
  double discount;
  String roundOff;
  double total;
  double totalTax;
  double grandTotal;
  double receipt;
  double balance;
  int orderType;
  int ifVat;
  int vanId;
  int userId;
  int storeId;
  int status;
  String createdAt;
  String updatedAt;
  dynamic deletedAt;
  double? opening; // Adjusted to be nullable
  List<Collection> collection;

  Transaction({
    required this.id,
    required this.customerId,
    required this.billMode,
    required this.inDate,
    required this.inTime,
    required this.invoiceNo,
    required this.deliveryNo,
    required this.otherCharge,
    required this.discount,
    required this.roundOff,
    required this.total,
    required this.totalTax,
    required this.grandTotal,
    required this.receipt,
    required this.balance,
    required this.orderType,
    required this.ifVat,
    required this.vanId,
    required this.userId,
    required this.storeId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.opening, // Adjusted to be nullable
    required this.collection,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    var collectionList = json['collection'] as List<dynamic>;
    List<Collection> collections =
        collectionList.map((e) => Collection.fromJson(e)).toList();

    return Transaction(
      id: json['id'],
      customerId: json['customer_id'],
      billMode: json['bill_mode'],
      inDate: json['in_date'],
      inTime: json['in_time'],
      invoiceNo: json['invoice_no'],
      deliveryNo: json['delivery_no'],
      otherCharge: json['other_charge']?.toDouble() ?? 0.0,
    discount: double.tryParse(json['discount']?.toString() ?? '') ?? 0.0,
      roundOff: json['round_off'],
      total: json['total']?.toDouble() ?? 0.0,
      totalTax: json['total_tax']?.toDouble() ?? 0.0,
      grandTotal: json['grand_total']?.toDouble() ?? 0.0,
      receipt: json['receipt']?.toDouble() ?? 0.0,
      balance: json['balance']?.toDouble() ?? 0.0,
      orderType: json['order_type'],
      ifVat: json['if_vat'],
      vanId: json['van_id'],
      userId: json['user_id'],
      storeId: json['store_id'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
      opening:
          json['opening']?.toDouble(), // Adjusted to handle nullable double
      collection: collections,
    );
  }
}

class Collection {
  int id;
  int masterId;
  int customerId;
  int goodsOutId;
  String amount;
  String inDate;
  String inTime;
  String collectionType;
  String bank;
  String chequeDate;
  String chequeNo;
  String voucherNo;
  int userId;
  int vanId;
  int storeId;
  String createdAt;
  String updatedAt;
  dynamic deletedAt;

  Collection({
    required this.id,
    required this.masterId,
    required this.customerId,
    required this.goodsOutId,
    required this.amount,
    required this.inDate,
    required this.inTime,
    required this.collectionType,
    required this.bank,
    required this.chequeDate,
    required this.chequeNo,
    required this.voucherNo,
    required this.userId,
    required this.vanId,
    required this.storeId,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'],
      masterId:
          json['master_id'] ?? 0, // Default value or adjust as per your logic
      customerId:
          json['customer_id'] ?? 0, // Default value or adjust as per your logic
      goodsOutId: json['goods_out_id'] ??
          0, // Default value or adjust as per your logic
      amount: json['amount'] ?? '', // Default value or adjust as per your logic
      inDate:
          json['in_date'] ?? '', // Default value or adjust as per your logic
      inTime:
          json['in_time'] ?? '', // Default value or adjust as per your logic
      collectionType: json['collection_type'] ??
          '', // Default value or adjust as per your logic
      bank: json['bank'] ?? '', // Default value or adjust as per your logic
      chequeDate: json['cheque_date'] ??
          '', // Default value or adjust as per your logic
      chequeNo:
          json['cheque_no'] ?? '', // Default value or adjust as per your logic
      voucherNo:
          json['voucher_no'] ?? '', // Default value or adjust as per your logic
      userId: json['user_id'] ?? 0, // Default value or adjust as per your logic
      vanId: json['van_id'] ?? 0, // Default value or adjust as per your logic
      storeId:
          json['store_id'] ?? 0, // Default value or adjust as per your logic
      createdAt:
          json['created_at'] ?? '', // Default value or adjust as per your logic
      updatedAt:
          json['updated_at'] ?? '', // Default value or adjust as per your logic
      deletedAt: json['deleted_at'], // Adjust as per your logic
    );
  }
}
