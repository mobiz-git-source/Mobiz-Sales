class LoginModel {
  String? status;
  User? user;
  Settings? settings;
  Authorisation? authorisation;
  Currency? currency;
  Store? store;

  LoginModel(
      {this.status,
      this.user,
      this.authorisation,
      this.settings,
      this.currency,
      this.store});

  LoginModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
    settings = json['settings'] != null
        ? new Settings.fromJson(json['settings'])
        : null;
    authorisation = json['authorisation'] != null
        ? new Authorisation.fromJson(json['authorisation'])
        : null;
    currency = json['currency'] != null
        ? new Currency.fromJson(json['currency'])
        : null;
    store = json['store'] != null ? new Store.fromJson(json['store']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    if (this.authorisation != null) {
      data['authorisation'] = this.authorisation!.toJson();
    }
    if (this.currency != null) {
      data['currency'] = this.currency!.toJson();
    }
    return data;
  }
}

class User {
  int? id;
  String? name;
  String? email;
  Null? emailVerifiedAt;
  Null? isSuperAdmin;
  String? isShopAdmin;
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
    // FIXED: backend sends the actual role as 'rol_id', not 'app_rol_id'.
    // 'app_rol_id' was coming back null, which made every login look like
    // an unmapped role and get stuck on the login screen.
    final appRolId = json['app_rol_id'];
    final legacyRolId = json['rol_id'];
    if (appRolId != null && appRolId != 0) {
      rolId = appRolId;
    } else {
      rolId = legacyRolId;
    }
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
    data['rol_id'] = this.rolId;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}

class Store {
  String? allowAccess;
  String? description;

  Store({this.allowAccess, this.description});

  Store.fromJson(Map<String, dynamic> json) {
    allowAccess = json['allow_access'];
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['allow_access'] = this.allowAccess;
    data['description'] = this.description;
    return data;
  }
}

class Settings {
  String? vatState;
  String? discountState;
  String? soValQtyState;
  String? attendanceState;
  String? qtySalesvalidate;
  String? printer;
  String? dateFormat;
  Settings(
      {this.discountState,
      this.soValQtyState,
      this.vatState,
      this.attendanceState,
      this.printer,
      this.qtySalesvalidate,
      this.dateFormat});
  Settings.fromJson(Map<String, dynamic> json) {
    vatState = json['vat_no_vat'];
    soValQtyState = json['validate_qty_in_so'];
    discountState = json['discount'];
    attendanceState = json['attendance'];
    qtySalesvalidate = json['validate_qty_in_sales'];
    printer = json['printer'];
    dateFormat = json['date_format'];
  }
}

class Authorisation {
  String? token;
  String? type;

  Authorisation({this.token, this.type});

  Authorisation.fromJson(Map<String, dynamic> json) {
    token = json['token'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['token'] = this.token;
    data['type'] = this.type;
    return data;
  }
}

class Currency {
  int? id;
  String? code;
  String? minor;
  String? currency;
  String? countryName;
  int? noOfDecimals;

  Currency(
      {this.id,
      this.code,
      this.minor,
      this.currency,
      this.countryName,
      this.noOfDecimals});

  Currency.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    minor = json['minor_unit'];
    currency = json['currency'];
    countryName = json['country_name'];
    noOfDecimals = json['no_of_decimals'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['code'] = this.code;
    data['minor_unit'] = this.minor;
    data['currency'] = this.currency;
    data['country_name'] = this.countryName;
    data['no_of_decimals'] = this.noOfDecimals;
    return data;
  }
}