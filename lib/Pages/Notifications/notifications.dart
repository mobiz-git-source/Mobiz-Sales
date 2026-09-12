import 'package:flutter/material.dart';
import 'package:mobizapp/Models/appstate.dart';
import 'package:mobizapp/Utilities/rest_ds.dart';
import '../../confg/appconfig.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static Future<List<dynamic>> getNotifications() async {
    final url = Uri.parse("${RestDatasource().BASE_URL}/api/notifications/list/${AppState().userId}");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      return jsonData["notifications"] ?? [];
    } else {
      throw Exception("Failed to load notifications");
    }
  }

  /// POST mark notification as read
  static Future<bool> markAsRead(int notificationId) async {
    final url = Uri.parse("${RestDatasource().BASE_URL}/api/notifications/mark-read");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": AppState().userId,
        "notification_id": notificationId,
      }),
    );

    return response.statusCode == 200;
  }
}

class NotificationPage extends StatefulWidget {
  static const routeName = "/NotificationPage";
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationModel> notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      var list = await NotificationService.getNotifications();

      setState(() {
        notifications =
            list.map((e) => NotificationModel.fromJson(e)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> silentRefresh() async {
    var list = await NotificationService.getNotifications();

    setState(() {
      notifications =
          list.map((e) => NotificationModel.fromJson(e)).toList();
    });
  }

  Future<void> handleTap(int index) async {
    var n = notifications[index];

    if (n.isRead == false) {
      await NotificationService.markAsRead(n.id);

      // Update UI instantly
      setState(() {
        notifications[index] = n.copyWith(isRead: true);
      });

      // Silent refresh in background
      silentRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text("Notifications",  style: AppConfig.pageTitleStyle,),
        backgroundColor: AppConfig.colorPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text("No Notifications Found"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => handleTap(index),
            child: buildCard(notifications[index]),
          );
        },
      ),
    );
  }

  Widget buildCard(NotificationModel n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: n.isRead ? Colors.white : Colors.blue.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!n.isRead)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 12, top: 8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
            ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),

                const SizedBox(height: 6),
                Text(n.body,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black87)),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(n.type.toUpperCase(),
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.blue.shade700)),

                    Text(
                      n.sentAt.replaceAll("T", " ").split(".").first,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String sentAt;
  final Map<String, dynamic> data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.sentAt,
    required this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json["id"],
      userId: json["user_id"],
      title: json["title"],
      body: json["body"],
      type: json["type"],
      isRead: json["is_read"] ?? false,
      sentAt: json["sent_at"] ?? "",
      data: Map<String, dynamic>.from(json["data"] ?? {}),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt,
      data: data,
    );
  }
}

