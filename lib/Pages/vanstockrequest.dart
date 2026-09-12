import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobizapp/Pages/homepage.dart';
import 'package:mobizapp/Pages/selectProducts.dart';
import 'package:mobizapp/Pages/newvanstockrequests.dart';
import 'package:mobizapp/Utilities/date_helper.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import '../Components/commonwidgets.dart';
import '../Models/appstate.dart';
import '../Models/requestmodelclass.dart';
import '../Models/stockdata.dart';
import '../Utilities/rest_ds.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';

class VanStockRequestsScreen extends StatefulWidget {
  static const routeName = "/vanstockrequests";
  const VanStockRequestsScreen({super.key});

  @override
  State<VanStockRequestsScreen> createState() => _VanStockRequestsScreenState();
}

class _VanStockRequestsScreenState extends State<VanStockRequestsScreen> {
  bool _initDone = false;
  bool _nodata = false;
  List<VanRequest> request = [];
  List<Map<String, dynamic>> stocks = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Timer? _searchDebounce;
  bool _isButtonDisabled = false;
  bool _isLoading = false;
  int _page = 1;
  bool _hasMore = true;
  late ScrollController _scrollController;
  @override
  void initState() {
    super.initState();
    _getRequests();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMore) {
      _getRequests();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _isSearching = false;
        _page = 1;
        _hasMore = true;
        request.clear();
      });
      _getRequests();
    } else {
      setState(() {
        _isSearching = true;
        _page = 1;
        _hasMore = true;
        request.clear();
      });
      _searchRequests(_searchController.text);
    }
  }

  Future<void> _searchRequests(String searchValue) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String apiUrl =
          "${RestDatasource().BASE_URL}/api/vanrequest.index.search?store_id=${AppState().storeId}&van_id=${AppState().vanId}&user_id=${AppState().userId}&page=$_page&value=$searchValue";

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final newRequests = VanRequestModel.fromJson(jsonData).data.vanRequests;

        setState(() {
          if (newRequests.isNotEmpty) {
            request.addAll(newRequests);
            _initDone = true;
            _nodata = false;
            _page++;
          } else {
            _nodata = true;
          }
        });
      } else {
        print("Error: Failed to load data (${response.statusCode})");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimary,
        iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search requests...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  _searchDebounce?.cancel();
                  _searchDebounce =
                      Timer(const Duration(milliseconds: 500), () {
                    _onSearchChanged();
                  });
                },
              )
            : const Text(
                'Van Stock Requests',
                style: AppConfig.pageTitleStyle,
              ),
        actions: [
          if (!_isSearching)
            GestureDetector(
              onTap: () async {
                Navigator.pushReplacementNamed(context, VanStocks.routeName);
              },
              child: const Icon(
                Icons.add,
                size: 30,
                color: AppConfig.backgroundColor,
              ),
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _onSearchChanged();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 18.0, left: 18, right: 18),
        child: Column(
          children: [
            if (_isSearching &&
                request.isEmpty &&
                _searchController.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No results found'),
              ),
            (_initDone && !_nodata)
                ? Expanded(
                    child: ListView.separated(
                      controller: _scrollController,
                      separatorBuilder: (BuildContext context, int index) =>
                          CommonWidgets.verticalSpace(1),
                      itemCount: request.length + (_isLoading ? 1 : 0),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        if (index < request.length) {
                          return _requestsTab(index, request[index]);
                        } else {
                          if (_isLoading) {
                            return Center(
                              child: Text(
                                "Loading...",
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontStyle: FontStyle.italic),
                              ),
                            );
                          } else if (!_hasMore) {
                            return Center(
                              child: Text(
                                "That's all",
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w700),
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }
                      },
                    ),
                  )
                : (_nodata && _initDone)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            CommonWidgets.verticalSpace(3),
                            const Center(
                              child: Text('No Data'),
                            ),
                          ])
                    : Shimmer.fromColors(
                        baseColor:
                            AppConfig.buttonDeactiveColor.withOpacity(0.1),
                        highlightColor: AppConfig.backButtonColor,
                        child: Center(
                          child: Column(
                            children: [
                              CommonWidgets.loadingContainers(
                                  height: SizeConfig.blockSizeVertical * 10,
                                  width: SizeConfig.blockSizeHorizontal * 90),
                              CommonWidgets.loadingContainers(
                                  height: SizeConfig.blockSizeVertical * 10,
                                  width: SizeConfig.blockSizeHorizontal * 90),
                              CommonWidgets.loadingContainers(
                                  height: SizeConfig.blockSizeVertical * 10,
                                  width: SizeConfig.blockSizeHorizontal * 90),
                              CommonWidgets.loadingContainers(
                                  height: SizeConfig.blockSizeVertical * 10,
                                  width: SizeConfig.blockSizeHorizontal * 90),
                              CommonWidgets.loadingContainers(
                                  height: SizeConfig.blockSizeVertical * 10,
                                  width: SizeConfig.blockSizeHorizontal * 90),
                              CommonWidgets.loadingContainers(
                                  height: SizeConfig.blockSizeVertical * 10,
                                  width: SizeConfig.blockSizeHorizontal * 90),
                            ],
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _requestsTab(int index, VanRequest data) {
    return Card(
      elevation: 3,
      child: Container(
        decoration: const BoxDecoration(
            color: AppConfig.backgroundColor,
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          trailing: Transform.rotate(
            angle: 100,
            child: const Icon(Icons.touch_app, color: Colors.transparent),
          ),
          backgroundColor: AppConfig.backgroundColor,
          title: Row(
            children: [
              CommonWidgets.horizontalSpace(1),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: SizeConfig.blockSizeHorizontal * 65,
                    child: Row(
                      children: [
                        Tooltip(
                          message: '${data.invoiceNo}',
                          child: SizedBox(
                            width: SizeConfig.blockSizeHorizontal * 30,
                            child: Text(
                              (data.invoiceNo!.length > 15)
                                  ? '${data.invoiceNo!.substring(0, 15)}...'
                                  : '${data.invoiceNo}',
                              style: TextStyle(
                                  fontWeight: AppConfig.headLineWeight),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          (data.status == 0)
                              ? 'Cancelled'
                              : (data.status == 1)
                                  ? 'Pending'
                                  : (data.status == 2)
                                      ? 'Approved'
                                      : (data.status == 3)
                                          ? 'Confirmed'
                                          : '',
                          style: TextStyle(
                            fontSize: AppConfig.textCaption3Size,
                            color: (data.status == 0)
                                ? Colors.red
                                : (data.status == 1)
                                    ? AppConfig.colorWarning
                                    : (data.status == 2)
                                        ? Colors.orange
                                        : (data.status == 3)
                                            ? Colors.green
                                            : Colors.grey,
                            fontWeight: AppConfig.headLineWeight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateHelper.displayDate(data.inDate),
                    style: TextStyle(
                      fontSize: AppConfig.textCaption3Size * 0.9,
                      fontWeight: AppConfig.headLineWeight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: <Widget>[
            (data.status == 2)
                ? Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonWidgets.verticalSpace(1),
                        Divider(
                          color: AppConfig.buttonDeactiveColor.withOpacity(0.4),
                        ),
                        for (int i = 0; i < data.detail!.length; i++)
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Tooltip(
                                  message: (data.detail![i].productName ?? '')
                                      .toUpperCase(),
                                  child: SizedBox(
                                    width: SizeConfig.blockSizeHorizontal * 80,
                                    child: Text(
                                      '${data.detail![i].productCode ?? ''} | ${(data.detail![i].productName ?? '').toUpperCase()}',
                                      style: TextStyle(
                                          fontSize: AppConfig.textCaption3Size,
                                          fontWeight: AppConfig.headLineWeight),
                                    ),
                                  ),
                                ),
                                CommonWidgets.verticalSpace(1),
                                Row(
                                  children: [
                                    Text(
                                      '${data.detail![i].unit} : ${data.detail![i].approvedQuantity}',
                                      style: TextStyle(
                                          fontSize: AppConfig.textCaption3Size,
                                          fontWeight: AppConfig.headLineWeight),
                                    ),
                                    CommonWidgets.horizontalSpace(2),
                                    Text(
                                      'Requested Qty: ${data.detail![i].quantity}',
                                      style: TextStyle(
                                          fontSize: AppConfig.textCaption3Size,
                                          fontWeight: AppConfig.headLineWeight),
                                    ),
                                  ],
                                ),
                                Divider(
                                  color: AppConfig.textBlack.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        Center(
                          child: SizedBox(
                            height: SizeConfig.blockSizeVertical * 5,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                ),
                                backgroundColor: WidgetStateProperty.all(
                                  _isButtonDisabled
                                      ? Colors.grey
                                      : AppConfig.colorPrimary,
                                ),
                              ),
                              onPressed: _isButtonDisabled
                                  ? null
                                  : () {
                                      _conformrequest(data.id!);
                                    },
                              child: _isButtonDisabled
                                  ? const SizedBox(
                                      height: 15,
                                      width: 15,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Confirm',
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.visible,
                                      style: TextStyle(
                                        fontSize: AppConfig.textCaption3Size,
                                        color: AppConfig.backgroundColor,
                                        fontWeight: AppConfig.headLineWeight,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        CommonWidgets.verticalSpace(2),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonWidgets.verticalSpace(1),
                        Divider(
                            color:
                                AppConfig.buttonDeactiveColor.withOpacity(0.4)),
                        for (int i = 0; i < data.detail!.length; i++)
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Tooltip(
                                  message: (data.detail![i].productName ?? '')
                                      .toUpperCase(),
                                  child: SizedBox(
                                    width: SizeConfig.blockSizeHorizontal * 80,
                                    child: Text(
                                      '${data.detail![i].productCode ?? ''} | ${(data.detail![i].productName ?? '').toUpperCase()}',
                                      style: TextStyle(
                                          fontSize: AppConfig.textCaption3Size,
                                          fontWeight: AppConfig.headLineWeight),
                                    ),
                                  ),
                                ),
                                CommonWidgets.verticalSpace(1),
                                Row(
                                  children: [
                                    Text(
                                      (data.status == 3)
                                          ? '${data.detail![i].unit}: ${data.detail![i].approvedQuantity}'
                                          : '${data.detail![i].unit}: ${data.detail![i].quantity}',
                                      style: TextStyle(
                                          fontSize: AppConfig.textCaption3Size,
                                          fontWeight: AppConfig.headLineWeight),
                                    ),
                                    CommonWidgets.horizontalSpace(2),
                                    (data.status == 3)
                                        ? Text(
                                            'Requested Qty: ${data.detail![i].quantity}',
                                            style: TextStyle(
                                                fontSize:
                                                    AppConfig.textCaption3Size,
                                                fontWeight:
                                                    AppConfig.headLineWeight),
                                          )
                                        : const SizedBox(),
                                  ],
                                ),
                                (i == data.detail!.length - 1)
                                    ? Container()
                                    : Divider(
                                        color: AppConfig.buttonDeactiveColor
                                            .withOpacity(0.4)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _getRequests() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String apiUrl;

      if (_isSearching && _searchController.text.isNotEmpty) {
        apiUrl =
            "${RestDatasource().BASE_URL}/api/vanrequest.index.search?store_id=${AppState().storeId}&van_id=${AppState().vanId}&user_id=${AppState().userId}&page=$_page&value=${_searchController.text}";
      } else {
        apiUrl =
            "${RestDatasource().BASE_URL}/api/vanrequest.index.api?store_id=${AppState().storeId}&van_id=${AppState().vanId}&page=$_page";
      }

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final newRequests = VanRequestModel.fromJson(jsonData).data.vanRequests;

        setState(() {
          if (newRequests.isNotEmpty) {
            request.addAll(newRequests);
            _initDone = true;
            _page++;
          } else {
            _initDone = true;
            _hasMore = false;
          }
        });
      } else {
        print("Error: Failed to load data (${response.statusCode})");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _conformrequest(int id) async {
    if (_isButtonDisabled) return;

    setState(() {
      _isButtonDisabled = true;
    });

    RestDatasource api = RestDatasource();
    dynamic bodyJson = {"id": id};

    try {
      dynamic resJson = await api.sendData(
          '/api/vanrequest.confirm', AppState().token, jsonEncode(bodyJson));

      if (resJson['success'] == true) {
        if (mounted) {
          await CommonWidgets.showDialogueBox(
              context: context,
              title: "Success",
              msg: "Request Confirmed Successfully");

          setState(() {
            request.clear();
            _page = 1;
            _initDone = false;
            _hasMore = true;
          });
          _getRequests();
        }
      } else {
        if (mounted) {
          CommonWidgets.showDialogueBox(
              context: context,
              title: "Alert",
              msg: resJson['messages']?.toString() ??
                  "Failed to confirm request");
        }
      }
    } catch (e) {
      print("Error while processing request: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isButtonDisabled = false;
        });
      }
    }
  }
}

class VanRequestModel {
  final bool success;
  final Data data;
  final List<dynamic> messages;

  VanRequestModel({
    required this.success,
    required this.data,
    required this.messages,
  });

  factory VanRequestModel.fromJson(Map<String, dynamic> json) {
    return VanRequestModel(
      success: json['success'] ?? false,
      data: json['data'] != null ? Data.fromJson(json['data']) : Data.empty(),
      messages: json['messages'] ?? [],
    );
  }
}

class Data {
  final int currentPage;
  final List<VanRequest> vanRequests;
  final String firstPageUrl;
  final int from;
  final int lastPage;
  final String lastPageUrl;
  final List<PageLink> links;
  final String? nextPageUrl;
  final int perPage;
  final int to;
  final int total;

  Data({
    required this.currentPage,
    required this.vanRequests,
    required this.firstPageUrl,
    required this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    required this.nextPageUrl,
    required this.perPage,
    required this.to,
    required this.total,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      currentPage: json['current_page'] ?? 0,
      vanRequests: (json['data'] as List?)
              ?.map((e) => VanRequest.fromJson(e))
              .toList() ??
          [],
      firstPageUrl: json['first_page_url'] ?? '',
      from: json['from'] ?? 0,
      lastPage: json['last_page'] ?? 0,
      lastPageUrl: json['last_page_url'] ?? '',
      links:
          (json['links'] as List?)?.map((e) => PageLink.fromJson(e)).toList() ??
              [],
      nextPageUrl: json['next_page_url'],
      perPage: json['per_page'] ?? 0,
      to: json['to'] ?? 0,
      total: json['total'] ?? 0,
    );
  }

  factory Data.empty() {
    return Data(
      currentPage: 0,
      vanRequests: [],
      firstPageUrl: '',
      from: 0,
      lastPage: 0,
      lastPageUrl: '',
      links: [],
      nextPageUrl: null,
      perPage: 0,
      to: 0,
      total: 0,
    );
  }
}

class VanRequest {
  int? id;
  int? vanId;
  int? userId;
  String? inDate;
  String? inTime;
  String? invoiceNo;
  String? approvedDate;
  String? approvedTime;
  int? approvedUser;
  int? storeId;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  List<VanDetail>? detail;

  VanRequest(
      {this.id,
      this.vanId,
      this.userId,
      this.inDate,
      this.inTime,
      this.invoiceNo,
      this.approvedDate,
      this.approvedTime,
      this.approvedUser,
      this.storeId,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.deletedAt,
      this.detail});

  VanRequest.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vanId = json['van_id'];
    userId = json['user_id'];
    inDate = json['in_date'];
    inTime = json['in_time'];
    invoiceNo = json['invoice_no'];
    approvedDate = json['approved_date'];
    approvedTime = json['approved_time'];
    approvedUser = json['approved_user'];
    storeId = json['store_id'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    if (json['detail'] != null) {
      detail = <VanDetail>[];
      json['detail'].forEach((v) {
        detail!.add(new VanDetail.fromJson(v));
      });
    }
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['van_id'] = this.vanId;
    data['user_id'] = this.userId;
    data['in_date'] = this.inDate;
    data['in_time'] = this.inTime;
    data['invoice_no'] = this.invoiceNo;
    data['approved_date'] = this.approvedDate;
    data['approved_time'] = this.approvedTime;
    data['approved_user'] = this.approvedUser;
    data['store_id'] = this.storeId;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    if (this.detail != null) {
      data['detail'] = this.detail!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class VanDetail {
  int? id;
  int? vanRequestId;
  int? itemId;
  String? unit;
  String? product_type;
  String? name;
  double? quantity;
  int? editedQuantity;
  String? approvedQuantity;
  int? convertQty;
  int? vanId;
  int? userId;
  int? storeId;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  int? productId;
  String? productName;
  String? productCode;

  VanDetail(
      {this.id,
      this.vanRequestId,
      this.product_type,
      this.name,
      this.itemId,
      this.unit,
      this.quantity,
      this.editedQuantity,
      this.approvedQuantity,
      this.convertQty,
      this.vanId,
      this.userId,
      this.storeId,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.deletedAt,
      this.productId,
      this.productCode,
      this.productName});

  VanDetail.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vanRequestId = json['van_request_id'];
    product_type = json['product_type'];
    name = json['name'];
    itemId = json['item_id'];
    unit = json['unit'];
    quantity = (json['quantity'] as num?)?.toDouble();
    approvedQuantity = json['approved_quantity'];
    convertQty = json['convert_qty'];
    vanId = json['van_id'];
    userId = json['user_id'];
    storeId = json['store_id'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    productId = json['product_id'];
    productName = json['product_name'];
    productCode = json['product_code'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['van_request_id'] = this.vanRequestId;
    data['item_id'] = this.itemId;
    data['unit'] = this.unit;
    data['quantity'] = this.quantity;
    data['approved_quantity'] = this.approvedQuantity;
    data['convert_qty'] = this.convertQty;
    data['van_id'] = this.vanId;
    data['user_id'] = this.userId;
    data['store_id'] = this.storeId;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['deleted_at'] = this.deletedAt;
    data['product_id'] = this.productId;
    data['product_name'] = this.productName;
    data['product_code'] = this.productCode;
    return data;
  }
}

class PageLink {
  final String? url;
  final String label;
  final bool active;

  PageLink({
    required this.url,
    required this.label,
    required this.active,
  });

  factory PageLink.fromJson(Map<String, dynamic> json) {
    return PageLink(
      url: json['url'],
      label: json['label'] ?? '',
      active: json['active'] ?? false,
    );
  }
}
