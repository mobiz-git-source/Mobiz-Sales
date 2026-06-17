// import 'invoicedata.dart';
//
// class ReceiptsData {
//   List<Data>? data;
//   bool? success;
//
//   ReceiptsData({this.data, this.success});
//
//   ReceiptsData.fromJson(Map<String, dynamic> json) {
//     if (json['data'] != null) {
//       data = <Data>[];
//       json['data'].forEach((v) {
//         data!.add(new Data.fromJson(v));
//       });
//     }
//     success = json['success'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.data != null) {
//       data['data'] = this.data!.map((v) => v.toJson()).toList();
//     }
//     data['success'] = this.success;
//     return data;
//   }
// }
//
// class Data {
//   int? id;
//   int? customerId;
//   String? inDate;
//   String? inTime;
//   String? collectionType;
//   String? bank;
//   String? chequeDate;
//   String? chequeNo;
//   int? status;
//   String? voucherNo;
//   String? totalAmount;
//   String? roundoff;
//   int? vanId;
//   int? userId;
//   int? storeId;
//   String? createdAt;
//   String? updatedAt;
//   String? deletedAt;
//   List<Sales>? sales;
//   List<Customer>? customer;
//   List<Van>? van;
//   List<User>? user;
//
//   Data({
//     this.id,
//     this.customerId,
//     this.inDate,
//     this.inTime,
//     this.collectionType,
//     this.bank,
//     this.chequeDate,
//     this.chequeNo,
//     this.status,
//     this.voucherNo,
//     this.totalAmount,
//     this.roundoff,
//     this.vanId,
//     this.userId,
//     this.storeId,
//     this.createdAt,
//     this.updatedAt,
//     this.deletedAt,
//     this.sales,
//     this.customer,
//     this.van,
//     this.user,
//   });
//
//   Data.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     customerId = json['customer_id'];
//     inDate = json['in_date'];
//     inTime = json['in_time'];
//     collectionType = json['collection_type'];
//     bank = json['bank'];
//     chequeDate = json['cheque_date'];
//     chequeNo = json['cheque_no'];
//     status = json['status'];
//     voucherNo = json['voucher_no'];
//     totalAmount = json['total_amount'];
//     roundoff = json['round_off'];
//     vanId = json['van_id'];
//     userId = json['user_id'];
//     storeId = json['store_id'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//     deletedAt = json['deleted_at'];
//     if (json['sales'] != null) {
//       sales = <Sales>[];
//       json['sales'].forEach((v) {
//         sales!.add(new Sales.fromJson(v));
//       });
//     }
//     if (json['customer'] != null) {
//       customer = <Customer>[];
//       json['customer'].forEach((v) {
//         customer!.add(new Customer.fromJson(v));
//       });
//     }
//     if (json['van'] != null) {
//       van = <Van>[];
//       json['van'].forEach((v) {
//         van!.add(Van.fromJson(v));
//       });
//     }
//     if (json['user'] != null) {
//       user = <User>[];
//       json['user'].forEach((v) {
//         user!.add(User.fromJson(v));
//       });
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['customer_id'] = this.customerId;
//     data['in_date'] = this.inDate;
//     data['in_time'] = this.inTime;
//     data['collection_type'] = this.collectionType;
//     data['bank'] = this.bank;
//     data['cheque_date'] = this.chequeDate;
//     data['status'] = this.status;
//     data['cheque_no'] = this.chequeNo;
//     data['voucher_no'] = this.voucherNo;
//     data['total_amount'] = this.totalAmount;
//     data['round_off'] = this.roundoff;
//     data['van_id'] = this.vanId;
//     data['user_id'] = this.userId;
//     data['store_id'] = this.storeId;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     data['deleted_at'] = this.deletedAt;
//     if (this.sales != null) {
//       data['sales'] = this.sales!.map((v) => v.toJson()).toList();
//     }
//     if (this.customer != null) {
//       data['customer'] = this.customer!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }
//
// class Sales {
//   int? id;
//   int? masterId;
//   int? customerId;
//   int? goodsOutId;
//   String? amount;
//   String? inDate;
//   String? inTime;
//   String? collectionType;
//   String? bank;
//   String? chequeDate;
//   String? chequeNo;
//   String? voucherNo;
//   String? invoiceDate;
//   String? invoiceType;
//   String? invoiceNo;
//   int? userId;
//   int? vanId;
//   int? storeId;
//   String? createdAt;
//   String? updatedAt;
//   String? deletedAt;
//
//   Sales({
//     this.id,
//     this.masterId,
//     this.customerId,
//     this.goodsOutId,
//     this.amount,
//     this.inDate,
//     this.inTime,
//     this.collectionType,
//     this.bank,
//     this.chequeDate,
//     this.chequeNo,
//     this.voucherNo,
//     this.invoiceDate,
//     this.invoiceType,
//     this.invoiceNo,
//     this.userId,
//     this.vanId,
//     this.storeId,
//     this.createdAt,
//     this.updatedAt,
//     this.deletedAt,
//   });
//
//   factory Sales.fromJson(Map<String, dynamic> json) {
//     return Sales(
//       id: json['id'],
//       masterId: json['master_id'],
//       customerId: json['customer_id'],
//       goodsOutId: json['goods_out_id'],
//       amount: json['amount'],
//       inDate: json['in_date'],
//       inTime: json['in_time'],
//       collectionType: json['collection_type'],
//       bank: json['bank'],
//       chequeDate: json['cheque_date'],
//       chequeNo: json['cheque_no'],
//       voucherNo: json['voucher_no'],
//       invoiceDate: json['invoice_date'],
//       invoiceType: json['invoice_type'],
//       invoiceNo: json['invoice_no'],
//       userId: json['user_id'],
//       vanId: json['van_id'],
//       storeId: json['store_id'],
//       createdAt: json['created_at'],
//       updatedAt: json['updated_at'],
//       deletedAt: json['deleted_at'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'master_id': masterId,
//       'customer_id': customerId,
//       'goods_out_id': goodsOutId,
//       'amount': amount,
//       'in_date': inDate,
//       'in_time': inTime,
//       'collection_type': collectionType,
//       'bank': bank,
//       'cheque_date': chequeDate,
//       'cheque_no': chequeNo,
//       'voucher_no': voucherNo,
//       'invoice_date': invoiceDate,
//       'invoice_type': invoiceType,
//       'invoice_no': invoiceNo,
//       'user_id': userId,
//       'van_id': vanId,
//       'store_id': storeId,
//       'created_at': createdAt,
//       'updated_at': updatedAt,
//       'deleted_at': deletedAt,
//     };
//   }
// }
//
//
// class Customer {
//   int? id;
//   String? name;
//   String? code;
//   String? address;
//   String? contactNumber;
//   String? whatsappNumber;
//   String? email;
//   String? trn;
//   String? custImage;
//   String? paymentTerms;
//   int? creditLimit;
//   int? creditDays;
//   int? routeId;
//   int? provinceId;
//   int? storeId;
//   int? status;
//   String? createdAt;
//   String? updatedAt;
//   String? deletedAt;
//   String? erpCustomerCode;
//
//   Customer({
//     this.id,
//     this.name,
//     this.code,
//     this.address,
//     this.contactNumber,
//     this.whatsappNumber,
//     this.email,
//     this.trn,
//     this.custImage,
//     this.paymentTerms,
//     this.creditLimit,
//     this.creditDays,
//     this.routeId,
//     this.provinceId,
//     this.storeId,
//     this.status,
//     this.createdAt,
//     this.updatedAt,
//     this.deletedAt,
//     this.erpCustomerCode,
//   });
//
//   Customer.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     name = json['name'];
//     code = json['code'];
//     address = json['address'];
//     contactNumber = json['contact_number'];
//     whatsappNumber = json['whatsapp_number'];
//     email = json['email'];
//     trn = json['trn'];
//     custImage = json['cust_image'];
//     paymentTerms = json['payment_terms'];
//     creditLimit = json['credit_limit'];
//     creditDays = json['credit_days'];
//     routeId = json['route_id'];
//     provinceId = json['province_id'];
//     storeId = json['store_id'];
//     status = json['status'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//     deletedAt = json['deleted_at'];
//     erpCustomerCode = json['erp_customer_code'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['name'] = this.name;
//     data['code'] = this.code;
//     data['address'] = this.address;
//     data['contact_number'] = this.contactNumber;
//     data['whatsapp_number'] = this.whatsappNumber;
//     data['email'] = this.email;
//     data['trn'] = this.trn;
//     data['cust_image'] = this.custImage;
//     data['payment_terms'] = this.paymentTerms;
//     data['credit_limit'] = this.creditLimit;
//     data['credit_days'] = this.creditDays;
//     data['route_id'] = this.routeId;
//     data['province_id'] = this.provinceId;
//     data['store_id'] = this.storeId;
//     data['status'] = this.status;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     data['deleted_at'] = this.deletedAt;
//     data['erp_customer_code'] = this.erpCustomerCode;
//     return data;
//   }
// }
// class Van {
//   int? id;
//   String? code;
//   String? name;
//   String? vanType;
//   String? description;
//   int? status;
//   int? storeId;
//   String? createdAt;
//   String? updatedAt;
//   String? deletedAt;
//
//   Van({
//     this.id,
//     this.code,
//     this.name,
//     this.vanType,
//     this.description,
//     this.status,
//     this.storeId,
//     this.createdAt,
//     this.updatedAt,
//     this.deletedAt,
//   });
//
//   Van.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     code = json['code'];
//     name = json['name'];
//     vanType = json['van_type'];
//     description = json['description'];
//     status = json['status'];
//     storeId = json['store_id'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//     deletedAt = json['deleted_at'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['id'] = this.id;
//     data['code'] = this.code;
//     data['name'] = this.name;
//     data['van_type'] = this.vanType;
//     data['description'] = this.description;
//     data['status'] = this.status;
//     data['store_id'] = this.storeId;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     data['deleted_at'] = this.deletedAt;
//     return data;
//   }
// }
// class User {
//   int? id;
//   String? name;
//   bool? someBooleanField;
//   String? email;
//   bool? isSuperAdmin;
//   bool? isShopAdmin;
//   bool? isStaff;
//   int? departmentId;
//   int? designationId;
//   int? storeId;
//   int? roleId;
//   String? createdAt;
//   String? updatedAt;
//
//   User({
//     this.id,
//     this.name,
//     this.someBooleanField,
//     this.email,
//     this.isSuperAdmin,
//     this.isShopAdmin,
//     this.isStaff,
//     this.departmentId,
//     this.designationId,
//     this.storeId,
//     this.roleId,
//     this.createdAt,
//     this.updatedAt,
//   });
//
//   User.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     name = json['name'];
//     someBooleanField = json['someBooleanField'] is bool ? json['someBooleanField'] : (json['someBooleanField'] == 'true');
//     email = json['email'];
//     isSuperAdmin = json['is_super_admin'] == "1";
//     isShopAdmin = json['is_shop_admin'] == "1";
//     isStaff = json['is_staff'] == "1";
//     departmentId = json['department_id'];
//     designationId = json['designation_id'];
//     storeId = json['store_id'];
//     roleId = json['rol_id'];
//     createdAt = json['created_at'];
//     updatedAt = json['updated_at'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = <String, dynamic>{};
//     data['id'] = this.id;
//     data['name'] = this.name;
//     data['email'] = this.email;
//     data['is_super_admin'] = this.isSuperAdmin;
//     data['is_shop_admin'] = this.isShopAdmin;
//     data['is_staff'] = this.isStaff;
//     data['department_id'] = this.departmentId;
//     data['designation_id'] = this.designationId;
//     data['store_id'] = this.storeId;
//     data['rol_id'] = this.roleId;
//     data['created_at'] = this.createdAt;
//     data['updated_at'] = this.updatedAt;
//     return data;
//   }
// }
//


class CollectionReport {
  bool? success;
  List<Message>? messages;
  Data? data;

  CollectionReport({this.success, this.messages, this.data});

  factory CollectionReport.fromJson(Map<String, dynamic> json) {
    return CollectionReport(
      success: json['success'],
      messages:
      (json['messages'] as List?)?.map((e) => Message.fromJson(e)).toList(),
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
    );
  }
}

class Data {
  int? currentPage;
  List<ReportData>? reportData;
  String? nextPageUrl;

  Data({this.currentPage, this.reportData, this.nextPageUrl});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      currentPage: json['current_page'],
      reportData:
      (json['data'] as List?)?.map((e) => ReportData.fromJson(e)).toList(),
      nextPageUrl: json['next_page_url'],
    );
  }
}

class ReportData {
  int? id;
  int? customerId;
  String? inDate;
  String? inTime;
  String? collectionType;
  String? bank;
  String? chequeDate;
  String? chequeNo;
  int? status;
  String? voucherNo;
  String? totalAmount;
  String? roundoff;
  int? vanId;
  int? userId;
  int? storeId;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  List<Salesy>? sales;
  List<Customer>? customer;
  List<Customer>? customerdata;
  List<Van>? van;
  List<User>? user;

  ReportData({
    this.id,
    this.customerId,
    this.inDate,
    this.inTime,
    this.collectionType,
    this.bank,
    this.chequeDate,
    this.chequeNo,
    this.status,
    this.voucherNo,
    this.totalAmount,
    this.roundoff,
    this.vanId,
    this.userId,
    this.storeId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.sales,
    this.customer,
    this.customerdata,
    this.van,
    this.user,
  });

  ReportData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    customerId = json['customer_id'];
    inDate = json['in_date'];
    inTime = json['in_time'];
    collectionType = json['collection_type'];
    bank = json['bank'];
    chequeDate = json['cheque_date'];
    chequeNo = json['cheque_no'];
    status = json['status'];
    voucherNo = json['voucher_no'];
    totalAmount = json['total_amount'];
    roundoff = json['round_off'];
    vanId = json['van_id'];
    userId = json['user_id'];
    storeId = json['store_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    if (json['sales'] != null) {
      sales = <Salesy>[];
      json['sales'].forEach((v) {
        sales!.add(new Salesy.fromJson(v));
      });
    }
    if (json['customer'] != null) {
      customer = <Customer>[];
      json['customer'].forEach((v) {
        customer!.add(new Customer.fromJson(v));
      });
    } else if (json['customerdata'] != null) {
      customer = <Customer>[];
      customer!.add(new Customer.fromJson(json['customerdata']));
    }
    if (json['van'] != null) {
      van = <Van>[];
      json['van'].forEach((v) {
        van!.add(Van.fromJson(v));
      });
    }
    if (json['user'] != null) {
      user = <User>[];
      json['user'].forEach((v) {
        user!.add(User.fromJson(v));
      });
    }
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['customer_id'] = this.customerId;
    data['in_date'] = this.inDate;
    data['in_time'] = this.inTime;
    data['collection_type'] = this.collectionType;
    data['bank'] = this.bank;
    data['cheque_date'] = this.chequeDate;
    data['status'] = this.status;
    data['cheque_no'] = this.chequeNo;
    data['voucher_no'] = this.voucherNo;
    data['total_amount'] = this.totalAmount;
    data['round_off'] = this.roundoff;
    data['van_id'] = this.vanId;
    data['user_id'] = this.userId;
    data['store_id'] = this.storeId;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    if (this.sales != null) {
      data['sales'] = this.sales!.map((v) => v.toJson()).toList();
    }
    if (this.customer != null) {
      data['customer'] = this.customer!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Salesy {
  int? id;
  int? masterId;
  int? customerId;
  int? goodsOutId;
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
  int? userId;
  int? vanId;
  int? storeId;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;

  Salesy({
    this.id,
    this.masterId,
    this.customerId,
    this.goodsOutId,
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
    this.userId,
    this.vanId,
    this.storeId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Salesy.fromJson(Map<String, dynamic> json) {
    return Salesy(
      id: json['id'],
      masterId: json['master_id'],
      customerId: json['customer_id'],
      goodsOutId: json['goods_out_id'],
      amount: json['amount'],
      inDate: json['in_date'],
      inTime: json['in_time'],
      collectionType: json['collection_type'],
      bank: json['bank'],
      chequeDate: json['cheque_date'],
      chequeNo: json['cheque_no'],
      voucherNo: json['voucher_no'],
      invoiceDate: json['invoice_date'],
      invoiceType: json['invoice_type'],
      invoiceNo: json['invoice_no'],
      userId: json['user_id'],
      vanId: json['van_id'],
      storeId: json['store_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      deletedAt: json['deleted_at'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'master_id': masterId,
      'customer_id': customerId,
      'goods_out_id': goodsOutId,
      'amount': amount,
      'in_date': inDate,
      'in_time': inTime,
      'collection_type': collectionType,
      'bank': bank,
      'cheque_date': chequeDate,
      'cheque_no': chequeNo,
      'voucher_no': voucherNo,
      'invoice_date': invoiceDate,
      'invoice_type': invoiceType,
      'invoice_no': invoiceNo,
      'user_id': userId,
      'van_id': vanId,
      'store_id': storeId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
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
    id = json['id'];
    name = json['name'];
    code = json['code'];
    address = json['address'];
    contactNumber = json['contact_number'];
    whatsappNumber = json['whatsapp_number'];
    email = json['email'];
    trn = json['trn'];
    custImage = json['cust_image'];
    paymentTerms = json['payment_terms'];
    creditLimit = json['credit_limit'];
    creditDays = json['credit_days'];
    routeId = json['route_id'];
    provinceId = json['province_id'];
    storeId = json['store_id'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    erpCustomerCode = json['erp_customer_code'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['code'] = this.code;
    data['address'] = this.address;
    data['contact_number'] = this.contactNumber;
    data['whatsapp_number'] = this.whatsappNumber;
    data['email'] = this.email;
    data['trn'] = this.trn;
    data['cust_image'] = this.custImage;
    data['payment_terms'] = this.paymentTerms;
    data['credit_limit'] = this.creditLimit;
    data['credit_days'] = this.creditDays;
    data['route_id'] = this.routeId;
    data['province_id'] = this.provinceId;
    data['store_id'] = this.storeId;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    data['erp_customer_code'] = this.erpCustomerCode;
    return data;
  }
}
class Van {
  int? id;
  String? code;
  String? name;
  String? vanType;
  String? description;
  int? status;
  int? storeId;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;

  Van({
    this.id,
    this.code,
    this.name,
    this.vanType,
    this.description,
    this.status,
    this.storeId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  Van.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    name = json['name'];
    vanType = json['van_type'];
    description = json['description'];
    status = json['status'];
    storeId = json['store_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = this.id;
    data['code'] = this.code;
    data['name'] = this.name;
    data['van_type'] = this.vanType;
    data['description'] = this.description;
    data['status'] = this.status;
    data['store_id'] = this.storeId;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    return data;
  }
}
class User {
  int? id;
  String? name;
  bool? someBooleanField;
  String? email;
  bool? isSuperAdmin;
  bool? isShopAdmin;
  bool? isStaff;
  int? departmentId;
  int? designationId;
  int? storeId;
  int? roleId;
  String? createdAt;
  String? updatedAt;

  User({
    this.id,
    this.name,
    this.someBooleanField,
    this.email,
    this.isSuperAdmin,
    this.isShopAdmin,
    this.isStaff,
    this.departmentId,
    this.designationId,
    this.storeId,
    this.roleId,
    this.createdAt,
    this.updatedAt,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    someBooleanField = json['someBooleanField'] is bool ? json['someBooleanField'] : (json['someBooleanField'] == 'true');
    email = json['email'];
    isSuperAdmin = json['is_super_admin'] == "1";
    isShopAdmin = json['is_shop_admin'] == "1";
    isStaff = json['is_staff'] == "1";
    departmentId = json['department_id'];
    designationId = json['designation_id'];
    storeId = json['store_id'];
    roleId = json['app_rol_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = this.id;
    data['name'] = this.name;
    data['email'] = this.email;
    data['is_super_admin'] = this.isSuperAdmin;
    data['is_shop_admin'] = this.isShopAdmin;
    data['is_staff'] = this.isStaff;
    data['department_id'] = this.departmentId;
    data['designation_id'] = this.designationId;
    data['store_id'] = this.storeId;
    data['app_rol_id'] = this.roleId;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class Message {
  String? message;

  Message({this.message});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      message: json['message'],
    );
  }
}
