class InvoiceData {
  Data? data;
  bool? success;

  InvoiceData({this.data, this.success});

  InvoiceData.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['success'] = this.success;
    return data;
  }
}

class Data {
  int? id;
  int? customerId;
  String? billMode;
  String? cashCard;
  String? inDate;
  String? inTime;
  String? invoiceNo;
  dynamic deliveryNo;
  num? otherCharge;
  num? discount;
  String? roundOff;
  num? total;
  num? totalTax;
  num? grandTotal;
  int? receipt;
  num? balance;
  int? orderType;
  int? ifVat;
  int? vanId;
  int? userId;
  int? storeId;
  int? status;
  String? createdAt;
  String? discounted_amount;
  String? remarks;
  String? updatedAt;
  String? deletedAt;
  List<Store>? store;
  List<Detail>? detail;
  List<Customer>? customer;
  List<Van>? van;
  List<User>? user;

  Data(
      {this.id,
      this.customerId,
      this.billMode,
      this.cashCard,
      this.inDate,
      this.inTime,
      this.invoiceNo,
      this.deliveryNo,
      this.otherCharge,
      this.discount,
      this.roundOff,
      this.total,
      this.totalTax,
      this.grandTotal,
      this.receipt,
      this.balance,
      this.orderType,
      this.ifVat,
      this.vanId,
      this.userId,
      this.storeId,
      this.status,
      this.createdAt,
      this.discounted_amount,
      this.remarks,
      this.updatedAt,
      this.deletedAt,
      this.store,
      this.detail,
      this.customer,
      this.van,
      this.user});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    customerId = json['customer_id'];
    billMode = json['bill_mode'];
    cashCard = json['cash_card'];
    inDate = json['in_date'];
    inTime = json['in_time'];
    invoiceNo = json['invoice_no'];
    deliveryNo = json['delivery_no'];
    otherCharge = json['other_charge'];
    discount = json['discount'];
    roundOff = json['round_off'];
    total = json['total'];
    totalTax = json['total_tax'];
    grandTotal = json['grand_total'];
    receipt = (json['receipt'] is double) ? json['receipt'].toInt() : json['receipt'];
    balance = json['balance'];
    orderType = json['order_type'];
    ifVat = json['if_vat'];
    vanId = json['van_id'];
    userId = json['user_id'];
    storeId = json['store_id'];
    status = json['status'];
    createdAt = json['created_at'];
    discounted_amount = json['discounted_amount'];
    remarks = json['remarks'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    if (json['store'] != null) {
      store = <Store>[];
      json['store'].forEach((v) {
        store!.add(new Store.fromJson(v));
      });
    }
    if (json['detail'] != null) {
      detail = <Detail>[];
      json['detail'].forEach((v) {
        detail!.add(new Detail.fromJson(v));
      });
    }
    if (json['customer'] != null) {
      customer = <Customer>[];
      json['customer'].forEach((v) {
        customer!.add(new Customer.fromJson(v));
      });
    }
    if (json['van'] != null) {
      van = <Van>[];
      json['van'].forEach((v) {
        van!.add(new Van.fromJson(v));
      });
    }
    if (json['user'] != null) {
      user = <User>[];
      json['user'].forEach((v) {
        user!.add(new User.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['customer_id'] = this.customerId;
    data['bill_mode'] = this.billMode;
    data['cash_card'] = this.cashCard;
    data['in_date'] = this.inDate;
    data['in_time'] = this.inTime;
    data['invoice_no'] = this.invoiceNo;
    data['delivery_no'] = this.deliveryNo;
    data['other_charge'] = this.otherCharge;
    data['discount'] = this.discount;
    data['round_off'] = this.roundOff;
    data['total'] = this.total;
    data['total_tax'] = this.totalTax;
    data['grand_total'] = this.grandTotal;
    data['receipt'] = this.receipt;
    data['balance'] = this.balance;
    data['order_type'] = this.orderType;
    data['if_vat'] = this.ifVat;
    data['van_id'] = this.vanId;
    data['user_id'] = this.userId;
    data['store_id'] = this.storeId;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    if (this.store != null) {
      data['store'] = this.store!.map((v) => v.toJson()).toList();
    }
    if (this.detail != null) {
      data['detail'] = this.detail!.map((v) => v.toJson()).toList();
    }
    if (this.customer != null) {
      data['customer'] = this.customer!.map((v) => v.toJson()).toList();
    }
    if (this.van != null) {
      data['van'] = this.van!.map((v) => v.toJson()).toList();
    }
    if (this.user != null) {
      data['user'] = this.user!.map((v) => v.toJson()).toList();
    }
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
  String? vat_label;
  String? invoice_footer;
  String? invoice_heading;
  String? invoice_company_name;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;

  Store(
      {this.id,
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
      this.vat_label,
      this.invoice_footer,
      this.invoice_heading,
      this.invoice_company_name,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.deletedAt});

  Store.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    name = json['name'];
    comapnyId = json['comapny_id'];
    logo = json['logo'];
    address = json['address'];
    emirate = json['emirate'];
    country = json['country'];
    contactNumber = json['contact_number'];
    whatsappNumber = json['whatsapp_number'];
    email = json['email'];
    username = json['username'];
    password = json['password'];
    noOfUsers = json['no_of_users'];
    suscriptionEndDate = json['suscription_end_date'];
    bufferDays = json['buffer_days'];
    description = json['description'];
    currency = json['currency'];
    vatPercentage = json['vat_percentage'] == null
        ? null
        : num.tryParse(json['vat_percentage'].toString());
    trn = json['trn'];
    vat_label = json['vat_label'];
    invoice_footer = json['invoice_footer']??'';
    invoice_heading = json['invoice_heading']??'';
    invoice_company_name = json['invoice_company_name'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['code'] = this.code;
    data['name'] = this.name;
    data['comapny_id'] = this.comapnyId;
    data['logo'] = this.logo;
    data['address'] = this.address;
    data['emirate'] = this.emirate;
    data['country'] = this.country;
    data['contact_number'] = this.contactNumber;
    data['whatsapp_number'] = this.whatsappNumber;
    data['email'] = this.email;
    data['username'] = this.username;
    data['password'] = this.password;
    data['no_of_users'] = this.noOfUsers;
    data['suscription_end_date'] = this.suscriptionEndDate;
    data['buffer_days'] = this.bufferDays;
    data['description'] = this.description;
    data['currency'] = this.currency;
    data['vat_percentage'] = this.vatPercentage;
    data['trn'] = this.trn;
    data['vat_label'] = this.vat_label;
    data['invoice_footer'] = this.invoice_footer;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    return data;
  }
}

class Detail {
  int? id;
  int? goodsOutId;
  int? itemId;
  String? productType;
  String? unit;
  num? convertQty;
  num? quantity;
  num? rate;
  num? prodiscount;
  num? taxable;
  num? taxAmt;
  num? mrp;
  num? amount;
  int? vanId;
  int? userId;
  int? storeId;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  String? code;
  String? name;
  String? proImage;
  int? categoryId;
  int? subCategoryId;
  int? brandId;
  int? supplierId;
  int? taxId;
  num? taxPercentage;
  num? taxInclusive;
  num? price;
  num? baseUnitId;
  num? baseUnitQty;
  String? baseUnitDiscount;
  dynamic baseUnitBarcode;
  int? baseUnitOpStock;
  String? secondUnitPrice;
  num? secondUnitId;
  num? secondUnitQty;
  String? secondUnitDiscount;
  dynamic secondUnitBarcode;
  String? secondUnitOpStock;
  String? thirdUnitPrice;
  int? thirdUnitId;
  num? thirdUnitQty;
  String? thirdUnitDiscount;
  String? thirdUnitBarcode;
  String? thirdUnitOpStock;
  String? fourthUnitPrice;
  int? fourthUnitId;
  num? fourthUnitQty;
  String? fourthUnitDiscount;
  int? isMultipleUnit;
  String? fourthUnitOpStock;
  String? description;
  num? productQty;
  num? percentage;

  Detail(
      {this.id,
      this.goodsOutId,
      this.itemId,
      this.productType,
      this.unit,
      this.convertQty,
      this.quantity,
      this.rate,
      this.prodiscount,
      this.taxable,
      this.taxAmt,
      this.mrp,
      this.amount,
      this.vanId,
      this.userId,
      this.storeId,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.deletedAt,
      this.code,
      this.name,
      this.proImage,
      this.categoryId,
      this.subCategoryId,
      this.brandId,
      this.supplierId,
      this.taxId,
      this.taxPercentage,
      this.taxInclusive,
      this.price,
      this.baseUnitId,
      this.baseUnitQty,
      this.baseUnitDiscount,
      this.baseUnitBarcode,
      this.baseUnitOpStock,
      this.secondUnitPrice,
      this.secondUnitId,
      this.secondUnitQty,
      this.secondUnitDiscount,
      this.secondUnitBarcode,
      this.secondUnitOpStock,
      this.thirdUnitPrice,
      this.thirdUnitId,
      this.thirdUnitQty,
      this.thirdUnitDiscount,
      this.thirdUnitBarcode,
      this.thirdUnitOpStock,
      this.fourthUnitPrice,
      this.fourthUnitId,
      this.fourthUnitQty,
      this.fourthUnitDiscount,
      this.isMultipleUnit,
      this.fourthUnitOpStock,
      this.description,
      this.productQty,
      this.percentage});

  Detail.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    goodsOutId = json['goods_out_id'];
    itemId = json['item_id'];
    productType = json['product_type'];
    unit = json['unit'];
    convertQty = json['convert_qty'];
    quantity = json['quantity'];
    rate = json['rate'];
    prodiscount = json['prodiscount'];
    taxable = json['taxable'];
    taxAmt = json['tax_amt'];
    mrp = json['mrp'];
    amount = json['amount'];
    vanId = json['van_id'];
    userId = json['user_id'];
    storeId = json['store_id'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    code = json['code'];
    name = json['name'];
    proImage = json['pro_image'];
    categoryId = json['category_id'];
    subCategoryId = json['sub_category_id'];
    brandId = json['brand_id'];
    supplierId = json['supplier_id'];
    taxId = json['tax_id'];
    taxPercentage = json['tax_percentage'];
    taxInclusive = json['tax_inclusive'];
    price = json['price'];
    baseUnitId = json['base_unit_id'];
    baseUnitQty = json['base_unit_qty'];
    baseUnitDiscount = json['base_unit_discount'];
    baseUnitBarcode = json['base_unit_barcode'];
    baseUnitOpStock = json['base_unit_op_stock'];
    secondUnitPrice = json['second_unit_price'];
    secondUnitId = json['second_unit_id'];
    secondUnitQty = json['second_unit_qty'];
    secondUnitDiscount = json['second_unit_discount'];
    secondUnitBarcode = json['second_unit_barcode'];
    secondUnitOpStock = json['second_unit_op_stock'];
    thirdUnitPrice = json['third_unit_price'];
    thirdUnitId = json['third_unit_id'];
    thirdUnitQty = json['third_unit_qty'];
    thirdUnitDiscount = json['third_unit_discount'];
    thirdUnitBarcode = json['third_unit_barcode'];
    thirdUnitOpStock = json['third_unit_op_stock'];
    fourthUnitPrice = json['fourth_unit_price'];
    fourthUnitId = json['fourth_unit_id'];
    fourthUnitQty = json['fourth_unit_qty'];
    fourthUnitDiscount = json['fourth_unit_discount'];
    isMultipleUnit = json['is_multiple_unit'];
    fourthUnitOpStock = json['fourth_unit_op_stock'];
    description = json['description'];
    productQty = json['product_qty'];
    percentage = json['percentage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['goods_out_id'] = this.goodsOutId;
    data['item_id'] = this.itemId;
    data['product_type'] = this.productType;
    data['unit'] = this.unit;
    data['convert_qty'] = this.convertQty;
    data['quantity'] = this.quantity;
    data['rate'] = this.rate;
    data['prodiscount'] = this.prodiscount;
    data['taxable'] = this.taxable;
    data['tax_amt'] = this.taxAmt;
    data['mrp'] = this.mrp;
    data['amount'] = this.amount;
    data['van_id'] = this.vanId;
    data['user_id'] = this.userId;
    data['store_id'] = this.storeId;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    data['code'] = this.code;
    data['name'] = this.name;
    data['pro_image'] = this.proImage;
    data['category_id'] = this.categoryId;
    data['sub_category_id'] = this.subCategoryId;
    data['brand_id'] = this.brandId;
    data['supplier_id'] = this.supplierId;
    data['tax_id'] = this.taxId;
    data['tax_percentage'] = this.taxPercentage;
    data['tax_inclusive'] = this.taxInclusive;
    data['price'] = this.price;
    data['base_unit_id'] = this.baseUnitId;
    data['base_unit_qty'] = this.baseUnitQty;
    data['base_unit_discount'] = this.baseUnitDiscount;
    data['base_unit_barcode'] = this.baseUnitBarcode;
    data['base_unit_op_stock'] = this.baseUnitOpStock;
    data['second_unit_price'] = this.secondUnitPrice;
    data['second_unit_id'] = this.secondUnitId;
    data['second_unit_qty'] = this.secondUnitQty;
    data['second_unit_discount'] = this.secondUnitDiscount;
    data['second_unit_barcode'] = this.secondUnitBarcode;
    data['second_unit_op_stock'] = this.secondUnitOpStock;
    data['third_unit_price'] = this.thirdUnitPrice;
    data['third_unit_id'] = this.thirdUnitId;
    data['third_unit_qty'] = this.thirdUnitQty;
    data['third_unit_discount'] = this.thirdUnitDiscount;
    data['third_unit_barcode'] = this.thirdUnitBarcode;
    data['third_unit_op_stock'] = this.thirdUnitOpStock;
    data['fourth_unit_price'] = this.fourthUnitPrice;
    data['fourth_unit_id'] = this.fourthUnitId;
    data['fourth_unit_qty'] = this.fourthUnitQty;
    data['fourth_unit_discount'] = this.fourthUnitDiscount;
    data['is_multiple_unit'] = this.isMultipleUnit;
    data['fourth_unit_op_stock'] = this.fourthUnitOpStock;
    data['description'] = this.description;
    data['product_qty'] = this.productQty;
    data['percentage'] = this.percentage;
    return data;
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

  Customer(
      {this.id,
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
      this.erpCustomerCode});

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
  String? description;
  int? status;
  int? storeId;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;

  Van(
      {this.id,
      this.code,
      this.name,
      this.description,
      this.status,
      this.storeId,
      this.createdAt,
      this.updatedAt,
      this.deletedAt});

  Van.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    name = json['name'];
    description = json['description'];
    status = json['status'];
    storeId = json['store_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['code'] = this.code;
    data['name'] = this.name;
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
  String? email;
  String? emailVerifiedAt;
  dynamic isSuperAdmin;
  dynamic isShopAdmin;
  String? isStaff;
  int? departmentId;
  int? designationId;
  int? storeId;
  int? rolId;
  String? createdAt;
  String? updatedAt;

  User(
      {this.id,
      this.name,
      this.email,
      this.emailVerifiedAt,
      this.isSuperAdmin,
      this.isShopAdmin,
      this.isStaff,
      this.departmentId,
      this.designationId,
      this.storeId,
      this.rolId,
      this.createdAt,
      this.updatedAt});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    emailVerifiedAt = json['email_verified_at'];
    isSuperAdmin = json['is_super_admin'];
    isShopAdmin = json['is_shop_admin'];
    isStaff = json['is_staff'];
    departmentId = json['department_id'];
    designationId = json['designation_id'];
    storeId = json['store_id'];
    rolId = json['app_rol_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['email'] = this.email;
    data['email_verified_at'] = this.emailVerifiedAt;
    data['is_super_admin'] = this.isSuperAdmin;
    data['is_shop_admin'] = this.isShopAdmin;
    data['is_staff'] = this.isStaff;
    data['department_id'] = this.departmentId;
    data['designation_id'] = this.designationId;
    data['store_id'] = this.storeId;
    data['app_rol_id'] = this.rolId;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
