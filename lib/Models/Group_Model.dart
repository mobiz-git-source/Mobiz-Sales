import 'TestMos.dart';

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _toIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

num? _toNumNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

String? _toStringNullable(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

class SaleReturnCollection {
  final SaleReturn? returnData;
  final Sale? sales;
  final Collection? collection;
  final Store? store;

  SaleReturnCollection({
    this.returnData,
    this.sales,
    this.collection,
    this.store,
  });

  factory SaleReturnCollection.fromJson(Map<String, dynamic> json) {
    return SaleReturnCollection(
      returnData: json['return'] != null ? SaleReturn.fromJson(json['return']) : null,
      sales: json['sales'] != null ? Sale.fromJson(json['sales']) : null,
      collection: json['collection'] != null ? Collection.fromJson(json['collection']) : null,
      store: json['store'] != null ? Store.fromJson(json['store']) : null,
    );
  }
}

class SaleReturn {
  final int id;
  final int customerId;
  final String billMode;
  final String inDate;
  final String inTime;
  final String invoiceNo;
  final double total;
  final double grandTotal;
  final double discount;
  final double totalTax;
  final List<Detail> detail;
  final Customer? customer;
  final Store? store;
  final Van? van;
  final User? user;

  SaleReturn({
    required this.id,
    required this.customerId,
    required this.billMode,
    required this.inDate,
    required this.inTime,
    required this.invoiceNo,
    required this.total,
    required this.grandTotal,
    required this.discount,
    required this.totalTax,
    required this.detail,
    this.customer,
    this.store,
    this.van,
    this.user,
  });

  factory SaleReturn.fromJson(Map<String, dynamic> json) {
    var detailList = (json['detail'] as List?)?.map((item) => Detail.fromJson(item)).toList() ?? [];

    return SaleReturn(
      id: _toInt(json['id']),
      customerId: _toInt(json['customer_id']),
      billMode: json['bill_mode']?.toString() ?? '',
      inDate: json['in_date']?.toString() ?? '',
      inTime: json['in_time']?.toString() ?? '',
      invoiceNo: json['invoice_no']?.toString() ?? '',
      total: _toDouble(json['total']),
      grandTotal: _toDouble(json['grand_total']),
      discount: _toDouble(json['discount']),
      totalTax: _toDouble(json['total_tax']),
      detail: detailList,
      customer: json['customer'] != null && (json['customer'] as List).isNotEmpty
          ? Customer.fromJson(json['customer'][0])
          : null,
      store: json['store'] != null && (json['store'] as List).isNotEmpty
          ? Store.fromJson(json['store'][0])
          : null,
      van: json['van'] != null && (json['van'] as List).isNotEmpty
          ? Van.fromJson(json['van'][0])
          : null,
      user: json['user'] != null && (json['user'] as List).isNotEmpty
          ? User.fromJson(json['user'][0])
          : null,
    );
  }
}

class Detail {
  final int id;
  final int goodsOutId;
  final int itemId;
  final String productType;
  final String unit;
  final double quantity;
  final double taxable;
  final double taxAmt;
  final double mrp;
  final double amount;
  final String name;
  final String proImage;

  Detail({
    required this.id,
    required this.goodsOutId,
    required this.itemId,
    required this.productType,
    required this.unit,
    required this.quantity,
    required this.taxable,
    required this.taxAmt,
    required this.mrp,
    required this.amount,
    required this.name,
    required this.proImage,
  });

  factory Detail.fromJson(Map<String, dynamic> json) {
    return Detail(
      id: _toInt(json['id']),
      goodsOutId: _toInt(json['goods_out_id']),
      itemId: _toInt(json['item_id']),
      productType: json['product_type']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      quantity: _toDouble(json['quantity']),
      taxable: _toDouble(json['taxable']),
      taxAmt: _toDouble(json['tax_amt']),
      mrp: _toDouble(json['mrp']),
      amount: _toDouble(json['amount']),
      name: json['name']?.toString() ?? '',
      proImage: json['pro_image']?.toString() ?? '',
    );
  }
}

class Customer {
  int? id;
  String? name;
  String? code;
  String? address;
  String? contactNumber;
  String? whatsappNumber;
  String? email;
  String? trn;
  String? custImage;
  String? paymentTerms;
  int? creditLimit;
  int? creditDays;
  int? routeId;
  int? provinceId;
  int? storeId;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  String? erpCustomerCode;

  Customer({
    this.id,
    this.name,
    this.code,
    this.address,
    this.contactNumber,
    this.whatsappNumber,
    this.email,
    this.trn,
    this.custImage,
    this.paymentTerms,
    this.creditLimit,
    this.creditDays,
    this.routeId,
    this.provinceId,
    this.storeId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.erpCustomerCode,
  });

  Customer.fromJson(Map<String, dynamic> json) {
    id = _toIntNullable(json['id']);
    name = _toStringNullable(json['name']);
    code = _toStringNullable(json['code']);
    address = _toStringNullable(json['address']);
    contactNumber = _toStringNullable(json['contact_number']);
    whatsappNumber = _toStringNullable(json['whatsapp_number']);
    email = _toStringNullable(json['email']);
    trn = _toStringNullable(json['trn']);
    custImage = _toStringNullable(json['cust_image']);
    paymentTerms = _toStringNullable(json['payment_terms']);
    creditLimit = _toIntNullable(json['credit_limit']);
    creditDays = _toIntNullable(json['credit_days']);
    routeId = _toIntNullable(json['route_id']);
    provinceId = _toIntNullable(json['province_id']);
    storeId = _toIntNullable(json['store_id']);
    status = _toIntNullable(json['status']);
    createdAt = _toStringNullable(json['created_at']);
    updatedAt = _toStringNullable(json['updated_at']);
    deletedAt = _toStringNullable(json['deleted_at']);
    erpCustomerCode = _toStringNullable(json['erp_customer_code']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['code'] = code;
    data['address'] = address;
    data['contact_number'] = contactNumber;
    data['whatsapp_number'] = whatsappNumber;
    data['email'] = email;
    data['trn'] = trn;
    data['cust_image'] = custImage;
    data['payment_terms'] = paymentTerms;
    data['credit_limit'] = creditLimit;
    data['credit_days'] = creditDays;
    data['route_id'] = routeId;
    data['province_id'] = provinceId;
    data['store_id'] = storeId;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    data['erp_customer_code'] = erpCustomerCode;
    return data;
  }
}

class Store {
  int? id;
  String? code;
  String? name;
  int? comapnyId;
  String? logo;
  String? address;
  String? emirate;
  String? country;
  String? contactNumber;
  String? whatsappNumber;
  String? email;
  String? username;
  String? password;
  int? noOfUsers;
  String? suscriptionEndDate;
  dynamic bufferDays;
  String? description;
  String? currency;
  num? vatPercentage;
  String? trn;
  String? vatLabel;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;

  Store({
    this.id,
    this.code,
    this.name,
    this.comapnyId,
    this.logo,
    this.address,
    this.emirate,
    this.country,
    this.contactNumber,
    this.whatsappNumber,
    this.email,
    this.username,
    this.password,
    this.noOfUsers,
    this.suscriptionEndDate,
    this.bufferDays,
    this.description,
    this.currency,
    this.vatPercentage,
    this.trn,
    this.vatLabel,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  Store.fromJson(Map<String, dynamic> json) {
    id = _toIntNullable(json['id']);
    code = _toStringNullable(json['code']);
    name = _toStringNullable(json['name']);
    comapnyId = _toIntNullable(json['comapny_id']);
    logo = _toStringNullable(json['logo']);
    address = _toStringNullable(json['address']);
    emirate = _toStringNullable(json['emirate']);
    country = _toStringNullable(json['country']);
    contactNumber = _toStringNullable(json['contact_number']);
    whatsappNumber = _toStringNullable(json['whatsapp_number']);
    email = _toStringNullable(json['email']);
    username = _toStringNullable(json['username']);
    password = _toStringNullable(json['password']);
    noOfUsers = _toIntNullable(json['no_of_users']);
    suscriptionEndDate = _toStringNullable(json['suscription_end_date']);
    bufferDays = json['buffer_days'];
    description = _toStringNullable(json['description']);
    currency = _toStringNullable(json['currency']);
    vatPercentage = _toNumNullable(json['vat_percentage']);
    trn = _toStringNullable(json['trn']);
    vatLabel = _toStringNullable(json['vat_label']);
    status = _toIntNullable(json['status']);
    createdAt = _toStringNullable(json['created_at']);
    updatedAt = _toStringNullable(json['updated_at']);
    deletedAt = _toStringNullable(json['deleted_at']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['code'] = code;
    data['name'] = name;
    data['comapny_id'] = comapnyId;
    data['logo'] = logo;
    data['address'] = address;
    data['emirate'] = emirate;
    data['country'] = country;
    data['contact_number'] = contactNumber;
    data['whatsapp_number'] = whatsappNumber;
    data['email'] = email;
    data['username'] = username;
    data['password'] = password;
    data['no_of_users'] = noOfUsers;
    data['suscription_end_date'] = suscriptionEndDate;
    data['buffer_days'] = bufferDays;
    data['description'] = description;
    data['currency'] = currency;
    data['vat_percentage'] = vatPercentage;
    data['trn'] = trn;
    data['vat_label'] = vatLabel;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    return data;
  }
}

class Van {
  final int id;
  final String name;

  Van({
    required this.id,
    required this.name,
  });

  factory Van.fromJson(Map<String, dynamic> json) {
    return Van(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class Sale {
  final int id;
  final int customerId;
  final String billMode;
  final String inDate;
  final String inTime;
  final double totalTax;
  final String invoiceNo;
  final String cashCard;
  final double total;
  final double grandTotal;
  final List<Detail> detail;
  final Store? store;
  final Customer? customer;
  final Van? van;
  final User? user;

  Sale({
    required this.id,
    required this.customerId,
    required this.billMode,
    required this.inDate,
    required this.inTime,
    required this.totalTax,
    required this.invoiceNo,
    required this.cashCard,
    required this.total,
    required this.grandTotal,
    required this.detail,
    this.store,
    this.customer,
    this.van,
    this.user,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    var detailList = (json['detail'] as List?)?.map((item) => Detail.fromJson(item)).toList() ?? [];
    return Sale(
      id: _toInt(json['id']),
      customerId: _toInt(json['customer_id']),
      billMode: json['bill_mode']?.toString() ?? '',
      inDate: json['in_date']?.toString() ?? '',
      inTime: json['in_time']?.toString() ?? '',
      totalTax: _toDouble(json['total_tax']),
      invoiceNo: json['invoice_no']?.toString() ?? '',
      cashCard: json['cash_card']?.toString() ?? '',
      total: _toDouble(json['total']),
      grandTotal: _toDouble(json['grand_total']),
      detail: detailList,
      store: json['store'] != null && (json['store'] as List).isNotEmpty
          ? Store.fromJson(json['store'][0])
          : null,
      customer: json['customer'] != null && (json['customer'] as List).isNotEmpty
          ? Customer.fromJson(json['customer'][0])
          : null,
      van: json['van'] != null && (json['van'] as List).isNotEmpty
          ? Van.fromJson(json['van'][0])
          : null,
      user: json['user'] != null && (json['user'] as List).isNotEmpty
          ? User.fromJson(json['user'][0])
          : null,
    );
  }
}

class Collection {
  int? id;
  int? customerId;
  String? inDate;
  String? inTime;
  String? collectionType;
  String? bank;
  String? chequeDate;
  String? chequeNo;
  String? voucherNo;
  String? totalAmount;
  int? vanId;
  int? userId;
  int? storeId;
  int? dayClose;
  int? dayCloseId;
  String? roundOff;
  int? status;
  String? createdAt;
  String? updatedAt;
  dynamic deletedAt;
  List<Sales>? sales;
  List<Customer>? customer;
  List<Van>? van;
  List<User>? user;

  Collection({
    this.id,
    this.customerId,
    this.inDate,
    this.inTime,
    this.collectionType,
    this.bank,
    this.chequeDate,
    this.chequeNo,
    this.voucherNo,
    this.totalAmount,
    this.vanId,
    this.userId,
    this.storeId,
    this.dayClose,
    this.dayCloseId,
    this.roundOff,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.sales,
    this.customer,
    this.van,
    this.user,
  });

  Collection.fromJson(dynamic json) {
    id = _toIntNullable(json['id']);
    customerId = _toIntNullable(json['customer_id']);
    inDate = _toStringNullable(json['in_date']);
    inTime = _toStringNullable(json['in_time']);
    collectionType = _toStringNullable(json['collection_type']);
    bank = _toStringNullable(json['bank']);
    chequeDate = _toStringNullable(json['cheque_date']);
    chequeNo = _toStringNullable(json['cheque_no']);
    voucherNo = _toStringNullable(json['voucher_no']);
    totalAmount = _toStringNullable(json['total_amount']);
    vanId = _toIntNullable(json['van_id']);
    userId = _toIntNullable(json['user_id']);
    storeId = _toIntNullable(json['store_id']);
    dayClose = _toIntNullable(json['day_close']);
    dayCloseId = _toIntNullable(json['day_close_id']);
    roundOff = _toStringNullable(json['round_off']);
    status = _toIntNullable(json['status']);
    createdAt = _toStringNullable(json['created_at']);
    updatedAt = _toStringNullable(json['updated_at']);
    deletedAt = json['deleted_at'];
    if (json['sales'] != null && json['sales'] is List) {
      sales = (json['sales'] as List).map((v) => Sales.fromJson(v)).toList();
    }
    if (json['customer'] != null && json['customer'] is List) {
      customer = (json['customer'] as List).map((v) => Customer.fromJson(v)).toList();
    }
    if (json['van'] != null && json['van'] is List) {
      van = (json['van'] as List).map((v) => Van.fromJson(v)).toList();
    }
    if (json['user'] != null && json['user'] is List) {
      user = (json['user'] as List).map((v) => User.fromJson(v)).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['id'] = id;
    map['customer_id'] = customerId;
    map['in_date'] = inDate;
    map['in_time'] = inTime;
    map['collection_type'] = collectionType;
    map['bank'] = bank;
    map['cheque_date'] = chequeDate;
    map['cheque_no'] = chequeNo;
    map['voucher_no'] = voucherNo;
    map['total_amount'] = totalAmount;
    map['van_id'] = vanId;
    map['user_id'] = userId;
    map['store_id'] = storeId;
    map['day_close'] = dayClose;
    map['day_close_id'] = dayCloseId;
    map['round_off'] = roundOff;
    map['status'] = status;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['deleted_at'] = deletedAt;
    if (sales != null) {
      map['sales'] = sales?.map((v) => v.toJson()).toList();
    }
    if (customer != null) {
      map['customer'] = customer?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Sales {
  int? id;
  int? masterId;
  int? customerId;
  int? goodsOutId;
  int? invoiceOutstandingId;
  String? amount;
  String? inDate;
  String? inTime;
  String? collectionType;
  String? bank;
  String? chequeDate;
  String? chequeNo;
  String? voucherNo;
  String? invoiceDate;
  String? invoiceType;
  String? invoiceNo;
  // String? cashCard;
  int? userId;
  int? vanId;
  int? storeId;
  String? createdAt;
  String? updatedAt;
  dynamic deletedAt;

  Sales({
    this.id,
    this.masterId,
    this.customerId,
    this.goodsOutId,
    this.invoiceOutstandingId,
    this.amount,
    this.inDate,
    this.inTime,
    this.collectionType,
    this.bank,
    this.chequeDate,
    this.chequeNo,
    this.voucherNo,
    this.invoiceDate,
    this.invoiceType,
    this.invoiceNo,
    // this.cashCard,
    this.userId,
    this.vanId,
    this.storeId,
    String? createdAt,
    String? updatedAt,
    dynamic deletedAt,
  });

  Sales.fromJson(dynamic json) {
    id = _toIntNullable(json['id']);
    masterId = _toIntNullable(json['master_id']);
    customerId = _toIntNullable(json['customer_id']);
    goodsOutId = _toIntNullable(json['goods_out_id']);
    invoiceOutstandingId = _toIntNullable(json['invoice_outstanding_id']);
    amount = _toStringNullable(json['amount']);
    inDate = _toStringNullable(json['in_date']);
    inTime = _toStringNullable(json['in_time']);
    collectionType = _toStringNullable(json['collection_type']);
    bank = _toStringNullable(json['bank']);
    chequeDate = _toStringNullable(json['cheque_date']);
    chequeNo = _toStringNullable(json['cheque_no']);
    voucherNo = _toStringNullable(json['voucher_no']);
    invoiceDate = _toStringNullable(json['invoice_date']);
    invoiceType = _toStringNullable(json['invoice_type']);
    invoiceNo = _toStringNullable(json['invoice_no']);
    // cashCard = _toStringNullable(json['cash_card']);
    userId = _toIntNullable(json['user_id']);
    vanId = _toIntNullable(json['van_id']);
    storeId = _toIntNullable(json['store_id']);
    createdAt = _toStringNullable(json['created_at']);
    updatedAt = _toStringNullable(json['updated_at']);
    deletedAt = json['deleted_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['id'] = id;
    map['master_id'] = masterId;
    map['customer_id'] = customerId;
    map['goods_out_id'] = goodsOutId;
    map['invoice_outstanding_id'] = invoiceOutstandingId;
    map['amount'] = amount;
    map['in_date'] = inDate;
    map['in_time'] = inTime;
    map['collection_type'] = collectionType;
    map['bank'] = bank;
    map['cheque_date'] = chequeDate;
    map['cheque_no'] = chequeNo;
    map['voucher_no'] = voucherNo;
    map['invoice_date'] = invoiceDate;
    map['invoice_type'] = invoiceType;
    map['invoice_no'] = invoiceNo;
    // map['cash_card'] = cashCard;
    map['user_id'] = userId;
    map['van_id'] = vanId;
    map['store_id'] = storeId;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['deleted_at'] = deletedAt;
    return map;
  }
}
