import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  //////// Login Information
  /// Login state : LOGGED_IN , LOGGED_OUT
  String? loginState;
  bool? isExistingUser;
  String? token;
  String? userType;
  String? name;
  String? email;
  String? vatState;
  String? vatLabel;
  String? validate_qtySO;
  String? validate_qtySales;
  String? discountState;
  String? attendanceState;
  String? printer;
  int? userId;
  int? vanId;
  int? storeId;
  int? routeId;
  int? rolId;
  int? noOfDecimals;
  String? dateFormat;
  double? roundOffPositive;
  double? roundOffNegative;
  bool roundOffAllowedInInvoice = true;
  String? code;
  String? minor;
  String? appVersion;
  String? buildNumber;
  String? osType;
  String? imageUrl;
  String? minorVersion;
  String? username;
  Map? devices;
  bool? initialConsent;
  String? country;
  bool? isEmailVerified;
  bool? isMobileVerified;
  bool? isTwoFactorEnabled;
  //// Make it as singleton class
  static final AppState _appState = new AppState._internal();

  AppState._internal() {
    loginState = "LOGGED_OUT";
    isExistingUser = false;
    token = "";
    userType = "";
    name = "";
    email = "";
    userId;
    rolId;
    storeId;
    vatState;
    vatLabel = "VAT";
    validate_qtySO;
    validate_qtySales;
    discountState;
    attendanceState;
    printer = "";
    routeId;
    vanId;
    noOfDecimals;
    code = "";
    minor = "";
    appVersion = "";
    buildNumber = "";
    osType = "";
    imageUrl = "";
    minorVersion = "";
    username = "";
    devices = {};
    initialConsent = false;
    country = "";
    isEmailVerified = false;
    isMobileVerified = false;
    isTwoFactorEnabled = false;
    dateFormat = "dd-MM-yyyy";
    roundOffPositive = 0;
    roundOffNegative = 0;
  }

 factory AppState() {
  return _appState;
}

AppState.fromJson(Map<String, dynamic> json) {
  print("FULL API RESPONSE JSON: $json");
  print("Date Format from API: ${json['date_format']}");
  loginState = json['login_state'];
    isExistingUser = json['is_existing_user'];
    token = json['token'];
    storeId = json['store_id'];
    vatState = json['vat_no_vat'];
    vatLabel = json['vat_label'];
    validate_qtySO = json['validate_qty_in_so'];
    validate_qtySales = json['validate_qty_in_sales'];
    discountState = json['discount'];
    attendanceState = json['attendance'];
    printer = json['printer'];
    routeId = json['route_id'];
    userType = json['user_type'];
    // userType = json['rol_id'];
    name = json['name'];
    rolId = json['app_rol_id'];
    email = json['email'];
    noOfDecimals = json['no_of_decimals'];

    code = json['code'];
    minor = json['minor_unit'];
    appVersion = json['app_version'];
    buildNumber = json['build_number'];
    userId = json['id'];
    osType = json['os_type'];
    imageUrl = json['image_url'];
    minorVersion = json['minor_version'];
    username = json["username"];
    devices = json["devices"];
    initialConsent = json['initial_consent'];
    country = json['country'];
    isMobileVerified = json['is_mobile_verified'];
    isEmailVerified = json['is_email_verified'];
    isTwoFactorEnabled = json["is_two_factor_enabled"];
    vanId = json["van_id"];
    dateFormat = json['date_format'] ?? "dd-MM-yyyy";
    print("AppState dateFormat: $dateFormat");
    roundOffPositive =
      double.tryParse(json['round_off_positive']?.toString() ?? '0') ?? 0;
  roundOffNegative =
      double.tryParse(json['round_off_negative']?.toString() ?? '0') ?? 0;
}


void updateFromJson(Map<String, dynamic> json) {
  loginState = json['login_state'];
  isExistingUser = json['is_existing_user'];
  token = json['token'];
  storeId = json['store_id'];
  vatState = json['vat_no_vat'];
  vatLabel = json['vat_label'];
  validate_qtySO = json['validate_qty_in_so'];
  validate_qtySales = json['validate_qty_in_sales'];
  discountState = json['discount'];
  attendanceState = json['attendance'];
  printer = json['printer'];
  routeId = json['route_id'];
  userType = json['user_type'];
  name = json['name'];
  rolId = json['app_rol_id'];
  email = json['email'];
  noOfDecimals = json['no_of_decimals'];
  code = json['code'];
  minor = json['minor_unit'];
  appVersion = json['app_version'];
  buildNumber = json['build_number'];
  userId = json['id'];
  osType = json['os_type'];
  imageUrl = json['image_url'];
  minorVersion = json['minor_version'];
  username = json["username"];
  devices = json["devices"];
  initialConsent = json['initial_consent'];
  country = json['country'];
  isMobileVerified = json['is_mobile_verified'];
  isEmailVerified = json['is_email_verified'];
  isTwoFactorEnabled = json["is_two_factor_enabled"];
  vanId = json["van_id"];

  dateFormat = json['date_format'] ?? "dd-MM-yyyy";

  roundOffPositive =
      double.tryParse(json['round_off_positive']?.toString() ?? '0') ?? 0;

  roundOffNegative =
      double.tryParse(json['round_off_negative']?.toString() ?? '0') ?? 0;

  roundOffAllowedInInvoice =
      json['roundoff_alllowed_in_invoice']
          ?.toString()
          .toLowerCase() != 'no';
}
Map<String, dynamic> toJson() {
  final Map<String, dynamic> data = Map<String, dynamic>();

  data['login_state'] = loginState;
  data['is_existing_user'] = isExistingUser;
  data['token'] = token;
  data['user_type'] = userType;
  data['id'] = userId;
  data['app_rol_id'] = rolId;
  data['name'] = name;
  data['email'] = email;
  data['store_id'] = storeId;
  data['vat_no_vat'] = vatState;
  data['vat_label'] = vatLabel;
  data['validate_qty_in_so'] = validate_qtySO;
  data['validate_qty_in_sales'] = validate_qtySales;
  data['discount'] = discountState;
  data['attendance'] = attendanceState;
  data['printer'] = printer;
  data['route_id'] = routeId;
  data['no_of_decimals'] = noOfDecimals;
  data['date_format'] = dateFormat;

  data['round_off_positive'] = roundOffPositive;
  data['round_off_negative'] = roundOffNegative;
  data['roundoff_alllowed_in_invoice'] =
      roundOffAllowedInInvoice ? 'yes' : 'no';

  data['code'] = code;
  data['minor_unit'] = minor;
  data['app_version'] = appVersion;
  data['build_number'] = buildNumber;
  data['os_type'] = osType;
  data['image_url'] = imageUrl;
  data['minor_version'] = minorVersion;
  data["username"] = username;
  data["devices"] = devices;
  data['initial_consent'] = initialConsent;
  data['country'] = country;
  data['is_mobile_verified'] = isMobileVerified;
  data['is_email_verified'] = isEmailVerified;
  data["is_two_factor_enabled"] = isTwoFactorEnabled;
  data['van_id'] = vanId;

  return data;
}
  // Future<void> _loadPrinter() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   printer = prefs.getString('printer') ?? "Wifi"; // Default to "Wifi"
  // }
  //
  // Future<void> savePrinter(String value) async {
  //   printer = value;
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('printer', value);
  // }
}
