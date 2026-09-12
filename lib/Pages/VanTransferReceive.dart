import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobizapp/Pages/selectProducts.dart';
import 'package:mobizapp/Pages/newvanstockrequests.dart';
import 'package:shimmer/shimmer.dart';

import '../Components/commonwidgets.dart';
import '../Models/appstate.dart';
import '../Models/requestmodelclass.dart';
import '../Models/stockdata.dart';
import '../Utilities/rest_ds.dart';
import '../Utilities/date_helper.dart';
import '../confg/appconfig.dart';
import '../confg/sizeconfig.dart';

class VanStockReceive extends StatefulWidget {
  static const routeName = "/VanStockReceive";
  const VanStockReceive({super.key});

  @override
  State<VanStockReceive> createState() => _VanStockReceiveState();
}

class _VanStockReceiveState extends State<VanStockReceive> {
  bool _initDone = false;
  bool _nodata = false;
  RequestModel request = RequestModel();
  List<Map<String, dynamic>> stocks = [];
  final TextEditingController _searchData = TextEditingController();
  bool _search = false;
  @override
  void initState() {
    super.initState();
    _getRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimary,
        iconTheme: const IconThemeData(color: AppConfig.backgroundColor),
        title: const Text(
          'Van Transfer Receive',
          style: AppConfig.pageTitleStyle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 18.0, left: 18, right: 18),
        child: SingleChildScrollView(
          child: Column(
            children: [
              (_initDone && !_nodata)
                  ? SizedBox(
                      height: SizeConfig.blockSizeVertical * 85,
                      child: ListView.separated(
                        separatorBuilder: (BuildContext context, int index) =>
                            CommonWidgets.verticalSpace(1),
                        itemCount: request.data!.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) =>
                            _requestsTab(index, request.data![index]),
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
      ),
    );
  }

  Widget _requestsTab(int index, Data data) {
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
                        // CommonWidgets.horizontalSpace(12),
                        Spacer(),
                        Text(
                          (data.status == 1)
                              ? 'Pending'
                              : (data.status == 2)
                                  ? 'Approved'
                                  : 'Confirmed',
                          style: TextStyle(
                              fontSize: AppConfig.textCaption3Size,
                              color: (data.status == 1)
                                  ? AppConfig.colorWarning
                                  : (data.status == 2)
                                      ? Colors.orange
                                      : Colors.green,
                              fontWeight: AppConfig.headLineWeight),
                        ),
                      ],
                    ),
                  ),
                Text(
  DateHelper.displayDate(data.inDate),
  style: TextStyle(
      fontSize: AppConfig.textCaption3Size * 0.9,
      fontWeight: AppConfig.headLineWeight),
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
                        // Text(
                        //   'RB0002',
                        //   style: TextStyle(
                        //       fontSize: AppConfig.textCaption3Size,
                        //       fontWeight: AppConfig.headLineWeight),
                        // ),
                        // Row(
                        //   children: [
                        //     Text(
                        //       'KELLOGGS KORN FLAKE',
                        //       style: TextStyle(
                        //           fontSize: AppConfig.textCaption3Size,
                        //           fontWeight: AppConfig.headLineWeight),
                        //     ),
                        //     const Spacer(),
                        //     Text(
                        //       'BOX QTY : 10',
                        //       style: TextStyle(
                        //           fontSize: AppConfig.textCaption3Size,
                        //           fontWeight: AppConfig.headLineWeight),
                        //     ),
                        //   ],
                        // ),
                        // const Divider(),
                        // CommonWidgets.verticalSpace(2),
                       Center(
  child: SizedBox(
    height: SizeConfig.blockSizeVertical * 5,
    child: ElevatedButton(
      style: ButtonStyle(
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        backgroundColor: const MaterialStatePropertyAll(
          AppConfig.colorPrimary,
        ),
      ),
      onPressed: () {
        _conformrequest(data.id!);
      },
      child: Text(
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
    RestDatasource api = RestDatasource();
    stocks = await StockHistory.getStockHistory();
    dynamic resJson = await api.getDetails(
        '/api/vantransfar.receive.index?store_id=${AppState().storeId}&van_id=${AppState().vanId}',
        AppState().token);

    if (resJson['data'] != null) {
      request = RequestModel.fromJson(resJson);
      if (mounted) {
        setState(
          () {
            _initDone = true;
          },
        );
      }
    } else {
      setState(() {
        _initDone = true;
        _nodata = true;
      });
    }
  }

  Future<void> _conformrequest(int id) async {
    RestDatasource api = RestDatasource();

    dynamic bodyJson = {
      "id": id,
    };
    try {
      dynamic resJson = await api.sendData(
          '/api/vantransfar.confirm', AppState().token, jsonEncode(bodyJson));
    } catch (e) {
      if (mounted) {
        CommonWidgets.showDialogueBox(
            context: context,
            title: "Alert",
            msg: "Requset Added Successfully");
        setState(() {
          _initDone = false;
        });
        _getRequests();
      }
    }
  }
}
