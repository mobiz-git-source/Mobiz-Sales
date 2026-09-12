class ProductDataModel {
  final Data data;
  final bool success;
  final List<dynamic> messages;

  ProductDataModel({
    required this.data,
    required this.success,
    required this.messages,
  });

  factory ProductDataModel.fromJson(Map<String, dynamic> json) {
    return ProductDataModel(
      data: Data.fromJson(json['data']),
      success: json['success'] ?? false,
      messages: List<dynamic>.from(json['messages'] ?? []),
    );
  }
}

class Data {
  final int currentPage;
  final List<Product> products;
  final String firstPageUrl;
  final int from;
  final int lastPage;
  final String lastPageUrl;
  final List<Link> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int to;
  final int total;

  Data({
    required this.currentPage,
    required this.products,
    required this.firstPageUrl,
    required this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    required this.to,
    required this.total,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      currentPage: int.tryParse(json['current_page'].toString()) ?? 0,
      products: List<Product>.from(
        json['data'].map((product) => Product.fromJson(product)),
      ),
      firstPageUrl: json['first_page_url'] ?? '',
      from: int.tryParse(json['from'].toString()) ?? 0,
      lastPage: int.tryParse(json['last_page'].toString()) ?? 0,
      lastPageUrl: json['last_page_url'] ?? '',
      links: List<Link>.from(json['links'].map((link) => Link.fromJson(link))),
      nextPageUrl: json['next_page_url'],
      path: json['path'] ?? '',
      perPage: int.tryParse(json['per_page'].toString()) ?? 0,
      prevPageUrl: json['prev_page_url'],
      to: int.tryParse(json['to'].toString()) ?? 0,
      total: int.tryParse(json['total'].toString()) ?? 0,
    );
  }
}

class Product {
  final String? data;
  final int id;
  final String code;
  final String name;
  final String proImage;
  final int taxPercentage;
  final double price;
  final int? storeId; // Optional
  final int status;
  final List<Units> units;
  String? selectedUnitName;
  int? selectedUnitId;
  bool isSelected;
  int defaultValue;

  Product({
    this.data,
    required this.id,
    required this.code,
    required this.name,
    required this.proImage,
    required this.taxPercentage,
    required this.price,
    this.storeId, // Optional
    required this.status,
    required this.units,
    this.selectedUnitName,
    this.selectedUnitId,
    this.isSelected = false,
    this.defaultValue = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    print('Parsing Product: $json'); // Debugging print
    return Product(
      id: int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      proImage: json['pro_image'] ?? '',
      taxPercentage: int.tryParse(json['tax_percentage'].toString()) ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      storeId: int.tryParse(json['store_id'].toString()) ?? 0,
      status: int.tryParse(json['status'].toString()) ?? 0,
      units: (json['units'] is List)
          ? List<Units>.from(
              json['units'].map((unit) => Units.fromJson(unit)),
            )
          : [],
      defaultValue: json['default_value'] ?? 0,  // Ensure this line is added
    );
  }

  Map<String, dynamic> toJson() {
    // print(object)
    return {
      'id': id,
      'code': code,
      'name': name,
      'pro_image': proImage,
      'tax_percentage': taxPercentage,
      'price': price,
      'store_id': storeId,
      'status': status,
      'units': units.map((unit) => unit.toJson()).toList(),
      'default_value': defaultValue,
    };
  }
}

class Units {
  final int unit;
  final int id;
  final String name;
  final double price;
  final double minPrice;
  final num stock; // Changed to `num` to handle both int and double

  Units({
    required this.unit,
    required this.id,
    required this.name,
    required this.price,
    required this.minPrice,
    required this.stock,
  });

  factory Units.fromJson(Map<String, dynamic> json) {
    return Units(
      unit: int.tryParse(json['unit'].toString()) ?? 0,
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      minPrice: double.tryParse(json['min_price'].toString()) ?? 0.0,
      stock: num.tryParse(json['stock'].toString()) ?? 0, // Handles both int and double
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit': unit,
      'id': id,
      'name': name,
      'price': price.toString(),
      'min_price': minPrice.toString(),
      'stock': stock, // Keeps the original type (int or double)
    };
  }
}


class Link {
  final String? url;
  final String label;
  final bool active;

  Link({
    this.url,
    required this.label,
    required this.active,
  });

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      url: json['url'],
      label: json['label'] ?? '',
      active: json['active'] ?? false,
    );
  }
}

class ProductType {
  final int id;
  final String name;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductType({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductType.fromJson(Map<String, dynamic> json) {
    return ProductType(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      status: int.tryParse(json['status'].toString()) ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? '1970-01-01T00:00:00Z'),
      updatedAt: DateTime.parse(json['updated_at'] ?? '1970-01-01T00:00:00Z'),
    );
  }
}

class Products {
  final int id;
  final String code;
  final String name;
  final String proImage;
  final String serialbarcode_required;
  final num taxPercentage;

  Products({
    required this.id,
    required this.code,
    required this.name,
    required this.proImage,
    required this.serialbarcode_required,
    this.taxPercentage = 0,
  });

  factory Products.fromJson(Map<String, dynamic> json) {
    return Products(
      id: int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      proImage: json['pro_image'] ?? '',
      serialbarcode_required: json['serial_barcode_required'] ?? '',
      taxPercentage: num.tryParse(json['tax_percentage'].toString()) ?? 0,
    );
  }
}
