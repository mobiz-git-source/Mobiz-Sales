class StoreDetail {
  final int id;
  final int comapny_id;
  final String code;
  final String name;
  final String? name_ar;   // NEW: Arabic company name
  final String email;
  final String? address;
  final String? vatLabel;
  final String? emirate;
  final String? country;
  final String? contactNumber;
  final String? whatsappNumber;
  final String? trn;
  final String? invoice_footer;
  final String? subscriptionEndDate;
  final String? createdAt;
  final String? updatedAt;
  final String? currency;
  final String? logos; // List of image URLs

  StoreDetail({
    required this.id,
    required this.comapny_id,
    required this.code,
    required this.name,
    this.name_ar,   // NEW
    required this.email,
    this.address,
    this.vatLabel,
    this.emirate,
    this.country,
    this.contactNumber,
    this.whatsappNumber,
    this.trn,
    this.invoice_footer,
    this.subscriptionEndDate,
    this.createdAt,
    this.updatedAt,
    this.currency,
    this.logos,
  });

  factory StoreDetail.fromJson(Map<String, dynamic> json) {
    return StoreDetail(
      id: json['data']['id'],
      comapny_id: json['data']['comapny_id'],
      code: json['data']['code'],
      name: json['data']['name'],
      name_ar: json['data']['name_ar'],   // NEW
      email: json['data']['email'],
      address: json['data']['address'],
      vatLabel: json['data']['vat_label'],
      emirate: json['data']['emirate'],
      country: json['data']['country'],
      contactNumber: json['data']['contact_number'],
      whatsappNumber: json['data']['whatsapp_number'],
      trn: json['data']['trn'],
      invoice_footer: json['data']['invoice_footer'],
      subscriptionEndDate: json['data']['subscription_end_date'],
      createdAt: json['data']['created_at'],
      updatedAt: json['data']['updated_at'],
      currency: json['data']['currency'],
      logos: json['data']['logo'],
    );
  }
}