import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mime/mime.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../Components/commonwidgets.dart';
import '../Models/appstate.dart';
import 'network_util.dart';

class RestDatasource {
  final NetworkUtil _netUtil = NetworkUtil();
  final AppState _appState = AppState();

  late String BASE_URL;
  late String Image_URL;
  late String Product_URL;

  RestDatasource() {
    BASE_URL = "http://68.183.92.8:3699";
    Image_URL = "https://erpadmin.mobiz.ae";
    Product_URL = "http://68.183.92.8:3696";
  }

  Future<String> _timeZone() async {
    String timeZone = await FlutterTimezone.getLocalTimezone();
    return timeZone;
  }

  Future<Map<String, String>> getHeader() async {
    String appVersion;
    String buildNumber;
    String osType = Platform.operatingSystem;
    String timeZone = await FlutterTimezone.getLocalTimezone();
    Map<String, String> header;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    buildNumber = packageInfo.buildNumber;
    appVersion = packageInfo.version;

    header = {
      //'${HttpHeaders.authorizationHeader}': "",
      'Content-Type': 'application/json; charset=UTF-8',
      'Os_Type': osType,
      'App_Version': appVersion,
      'Build_Number': buildNumber,
      'Time_zone': timeZone,
    };

    return header;
  }

  Future<dynamic> getDetails(String url, String? token) async {
    var header;
    var extradetails = await getHeader();
    if (token == null) {
      header = {
        'Content-Type': 'application/json; charset=UTF-8',
      };
    } else {
      print("token a ${_appState.token}");
      header = {
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: "token $token"
      };
    }

    final DETAILS_URL = (url.contains("?") == true)
        ? BASE_URL +
            url +
            "&timeZone=${extradetails["Time_zone"]}&appVersion=${extradetails["App_Version"]}"
        : BASE_URL +
            url +
            "?timeZone=${extradetails["Time_zone"]}&appVersion=${extradetails["App_Version"]}";
    print("Get_URL   $DETAILS_URL");
    try {
      // Removed unreliable internet check
      return _netUtil
          .get(
        DETAILS_URL,
        header: header,
      )
          .then((Map<String, dynamic> resJson) {
        return resJson;
      });
    } catch (e) {
      print('Get Details Error: $e');
      Fluttertoast.showToast(
          msg: "No Internet Connection", backgroundColor: Colors.black);
      return {};
    }
  }

  Future<Map<String, dynamic>> sendData(
      String subUrl, String? token, dynamic bodyJson) async {
    var extradetails = await getHeader();
    var header;
    if (token == null) {
      header = {
        'Content-Type': 'application/json; charset=UTF-8',
      };
    } else {
      header = {
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: "bearer $token"
      };
    }

    print("Header $header");
    final SIGN_UP_URL = (subUrl.contains("?") == true)
        ? BASE_URL +
            subUrl +
            "&timeZone=${extradetails["Time_zone"]}&appVersion=${extradetails["App_Version"]}"
        : BASE_URL +
            subUrl +
            "?timeZone=${extradetails["Time_zone"]}&appVersion=${extradetails["App_Version"]}";
    print("$SIGN_UP_URL");
    try {
      // Removed unreliable internet check
      if (bodyJson != null) {
        print("then $bodyJson");
        return _netUtil
            .post(SIGN_UP_URL, headers: header, body: bodyJson)
            .then((Map<String, dynamic> resJson) {
          return resJson;
        });
      } else {
        return _netUtil
            .post(SIGN_UP_URL, headers: header)
            .then((Map<String, dynamic> resJson) {
          return resJson;
        });
      }
    } catch (e) {
      print('SendData Error: $e');
      Fluttertoast.showToast(
          msg: "Connection Error", backgroundColor: Colors.black);
      return {};
    }
  }

  Future<Response> customerRegister(String? token, dynamic bodyJson,
      [File? imageFile, BuildContext? context, bool? isUpdate = false]) async {
    var extradetails = await getHeader();

    String url = (isUpdate!) ? "/api/customer.edit" : "/api/customer.post";

    final SIGNUP__URL = BASE_URL +
        url +
        "?timeZone=${extradetails["Time_zone"]}&appVersion=${extradetails["App_Version"]}";

    FormData data = FormData.fromMap({
      'name': bodyJson['name'],
      'code': bodyJson['code'],
      'address': bodyJson['address'],
      'contact_number': bodyJson['contact_number'],
      'location': bodyJson['location'],
      'whatsapp_number': bodyJson['whatsapp_number'],
      'email': bodyJson['email'],
      'Building': bodyJson['Building'],
      'Flat_no': bodyJson['Flat_no'],
      'trn': bodyJson['trn'],
      'route_id': bodyJson['route_id'],
      'id': bodyJson['id'],
      'province_id': bodyJson['provience_id'],
      'store_id': bodyJson['store_id'],
      'payment_terms': bodyJson['payment_terms'],
      if (bodyJson['credi_limit'] != null && bodyJson['credi_limit'].isNotEmpty)
        'credi_limit': bodyJson['credi_limit'],
      if (bodyJson['credi_days'] != null && bodyJson['credi_days'].isNotEmpty)
        'credi_days': bodyJson['credi_days'],
    });

    if (imageFile != null) {
      try {
        String fileName = imageFile.path.split('/').last;
        final detectedMime = lookupMimeType(imageFile.path) ?? 'image/jpeg';
        final mimeParts = detectedMime.split('/');
        print("Detected MIME type: $detectedMime");

        data.files.add(
          MapEntry(
            "cust_image",
            await MultipartFile.fromFile(
              imageFile.path,
              filename: fileName,
              contentType: MediaType(mimeParts[0], mimeParts[1]),
            ),
          ),
        );
      } catch (e) {
        print("Error adding image file: $e");
        if (context != null) {
          CommonWidgets.showDialogueBox(
            context: context,
            title: "Error",
            msg: "Unable to add the selected image. Please try again.",
          );
        }
        throw e;
      }
    }

    Dio dio = Dio();

    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 413) {
          if (context != null) {
            CommonWidgets.showDialogueBox(
              context: context,
              title: 'Alert',
              msg:
                  "Please decrease the image size. Maximum allowed size is 10MB.",
            );
          }
        } else if (e.response?.statusCode == 500 ||
            e.response?.statusCode == 502) {
          print('Server error: ${e.response?.statusCode}');
        }
        return handler.next(e);
      },
    ));

    Options options = Options(
      headers: token != null
          ? {HttpHeaders.authorizationHeader: "bearer $token"}
          : null,
    );

    print("========== CUSTOMER UPDATE ==========");
    print("URL: $SIGNUP__URL");
    print("Customer ID: ${bodyJson['id']}");
    print("Image path: ${imageFile?.path}");
    print(
        "Image exists: ${imageFile != null ? await imageFile.exists() : false}");
    print("Image size: ${imageFile != null ? await imageFile.length() : 0}");
    print("FormData fields: ${data.fields}");
    print("FormData files: ${data.files}");
    print("Token present: ${token != null}");
    if (data.files.isNotEmpty) {
      final multipartFile = data.files.first.value;
      print(
          "Multipart file length (bytes dio will send): ${multipartFile.length}");
      print("Multipart file filename: ${multipartFile.filename}");
      print("Multipart file contentType: ${multipartFile.contentType}");
    }
    print("=====================================");
    try {
      Response response =
          await dio.post(SIGNUP__URL, data: data, options: options);
      print("STATUS: ${response.statusCode}");
      print("RESPONSE HEADERS: ${response.headers}");
      print("BODY: ${response.data}");
      print("Response: $response");
      print("bodyJson$imageFile");
      return response;
    } catch (e) {
      print("Error posting data: $e");
      rethrow;
    }
  }
}
