class DayCloseOutstandingReport {
  Data? data;
  List<Sale>? sales;
  List<SaleReturn>? salesReturn;
  List<Collection>? collection;
  List<Expense>? expense;
  bool? success;
  List<String>? messages;

  DayCloseOutstandingReport({
    this.data,
    this.sales,
    this.salesReturn,
    this.collection,
    this.expense,
    this.success,
    this.messages,
  });

  factory DayCloseOutstandingReport.fromJson(Map<String, dynamic> json) {
    return DayCloseOutstandingReport(
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
      sales: json['sales'] != null
          ? List<Sale>.from(json['sales'].map((x) => Sale.fromJson(x)))
          : [],
      salesReturn: json['sales_return'] != null
          ? List<SaleReturn>.from(json['sales_return'].map((x) => SaleReturn.fromJson(x)))
          : [],
      collection: json['collection'] != null
          ? List<Collection>.from(json['collection'].map((x) => Collection.fromJson(x)))
          : [],
      expense: json['expense'] != null
          ? List<Expense>.from(json['expense'].map((x) => Expense.fromJson(x)))
          : [],
      success: json['success'],
      messages: json['messages'] != null
          ? List<String>.from(json['messages'].map((x) => x))
          : [],
    );
  }
}

class Data {
  String? van;
  String? user;
  String? date;
  String? time;
  num? pettyCash; // Changed from int? to num?
  num? amountOfSales; // Changed from int? to num?
  num? amountOfSalesReturn; // Changed from int? to num?
  num? amountOfCollectionCash; // Changed from int? to num?
  num? amountOfExpense; // Changed from int? to num?
  int? netCashBalance; // Changed from int? to num?

  Data({
    this.van,
    this.user,
    this.date,
    this.time,
    this.pettyCash,
    this.amountOfSales,
    this.amountOfSalesReturn,
    this.amountOfCollectionCash,
    this.amountOfExpense,
    this.netCashBalance,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      van: json['van'],
      user: json['user'],
      date: json['date'],
      time: json['time'],
      pettyCash: json['petty_cash'],
      amountOfSales: json['amount_of_sales'],
      amountOfSalesReturn: json['amount_of_sales_return'],
      amountOfCollectionCash: json['amount_of_collection_cash'],
      amountOfExpense: json['amount_of_expense'],
      netCashBalance: json['net_cash_balance'] != null
          ? (json['net_cash_balance'] as num).toInt()
          : null,
    );
  }
}

class Sale {
  int? customerId;
  String? invoiceNo;
  num? grandTotal; // Changed from int? to num?
  List<Customer>? customer;

  Sale({
    this.customerId,
    this.invoiceNo,
    this.grandTotal,
    this.customer,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      customerId: json['customer_id'],
      invoiceNo: json['invoice_no'],
      grandTotal: json['grand_total'],
      customer: json['customer'] != null
          ? List<Customer>.from(json['customer'].map((x) => Customer.fromJson(x)))
          : [],
    );
  }
}

class SaleReturn {
  int? customerId;
  String? invoiceNo;
  num? grandTotal; // Changed from int? to num?
  List<Customer>? customer;

  SaleReturn({
    this.customerId,
    this.invoiceNo,
    this.grandTotal,
    this.customer,
  });

  factory SaleReturn.fromJson(Map<String, dynamic> json) {
    return SaleReturn(
      customerId: json['customer_id'],
      invoiceNo: json['invoice_no'],
      grandTotal: json['grand_total'],
      customer: json['customer'] != null
          ? List<Customer>.from(json['customer'].map((x) => Customer.fromJson(x)))
          : [],
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
  String? totalAmount; // If this is a string representation of a number
  List<Customer>? customer;

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
    this.customer,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'],
      customerId: json['customer_id'],
      inDate: json['in_date'],
      inTime: json['in_time'],
      collectionType: json['collection_type'],
      bank: json['bank'],
      chequeDate: json['cheque_date'],
      chequeNo: json['cheque_no'],
      voucherNo: json['voucher_no'],
      totalAmount: json['total_amount'],
      customer: json['customer'] != null
          ? List<Customer>.from(json['customer'].map((x) => Customer.fromJson(x)))
          : [],
    );
  }
}

class Expense {
  int? id;
  String? invoiceNo;
  String? inDate;
  String? inTime;
  int? expenseId;
  String? vatAmount; // Assuming this can be a string
  String? totalAmount; // Assuming this can be a string
  String? amount; // Assuming this can be a string
  String? description;
  String? status;
  List<ExpenseDetails>? expense;

  Expense({
    this.id,
    this.invoiceNo,
    this.inDate,
    this.inTime,
    this.expenseId,
    this.vatAmount,
    this.totalAmount,
    this.amount,
    this.description,
    this.status,
    this.expense,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      invoiceNo: json['invoice_no'],
      inDate: json['in_date'],
      inTime: json['in_time'],
      expenseId: json['expense_id'],
      vatAmount: json['vat_amount'],
      totalAmount: json['total_amount'],
      amount: json['amount'],
      description: json['description'],
      status: json['status'],
      expense: json['expense'] != null
          ? List<ExpenseDetails>.from(json['expense'].map((x) => ExpenseDetails.fromJson(x)))
          : [],
    );
  }
}

class Customer {
  int? id;
  String? name;
  String? contactNumber;
  String? whatsappNumber;
  String? email;

  Customer({
    this.id,
    this.name,
    this.contactNumber,
    this.whatsappNumber,
    this.email,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      contactNumber: json['contact_number'],
      whatsappNumber: json['whatsapp_number'],
      email: json['email'],
    );
  }
}

class ExpenseDetails {
  int? id;
  String? name;

  ExpenseDetails({
    this.id,
    this.name,
  });

  factory ExpenseDetails.fromJson(Map<String, dynamic> json) {
    return ExpenseDetails(
      id: json['id'],
      name: json['name'],
    );
  }
}
