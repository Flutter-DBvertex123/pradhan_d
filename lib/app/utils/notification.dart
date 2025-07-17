import 'dart:developer';

import 'package:chunaw/app/service/user_service.dart';
import 'package:chunaw/app/utils/app_pref.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// class NotificationService {
final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
FirebaseMessaging messaging = FirebaseMessaging.instance;

//   /// request a notification permission
Future<void> requestPermissions() async {
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

const AndroidInitializationSettings _androidInitializationSettings =
    AndroidInitializationSettings("@mipmap/ic_launcher");
const DarwinInitializationSettings darwinInitializationSettings =
    DarwinInitializationSettings(
  defaultPresentAlert: false,
  defaultPresentBadge: false,
  defaultPresentSound: false,
);

/// Android notification settings
AndroidNotificationDetails androidNotificationDetails =
    const AndroidNotificationDetails(
  "channelId",
  "channelName",
  playSound: true,
  importance: Importance.max,
  priority: Priority.high,
);

// / IOS notification settings
DarwinNotificationDetails darwinNotificationDetails =
    const DarwinNotificationDetails(
  presentAlert: true,
  presentSound: true,
);

//   /// function for show message
void showFlutterNotification(RemoteMessage message) async {
  RemoteNotification? notification = message.notification;
  // AndroidNotification? android = message.notification?.android;
  if (notification != null) {
    _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      ),
    );
  }
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'my_channel', // id
  'My Channel', // title
// description
  importance: Importance.high,
);

class Notifications {
  static Future init({GlobalKey? key}) async {
    try {
      await requestPermissions();
      await messaging.requestPermission();

      InitializationSettings initializationSettings =
          const InitializationSettings(
        android: _androidInitializationSettings,
        iOS: darwinInitializationSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
      if (getPrefValue(Keys.USERID) != "") {
        String? fcmToken = await messaging.getToken();
        print('FCM Token: $fcmToken');
        UserService.updateFcm(
            userId: getPrefValue(Keys.USERID), fcm: fcmToken ?? "");
      }
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      //   Future.delayed(Duration.zero, () {
      //     showFlutterNotification(message);
      //   });
      // });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // RemoteNotification notification = message.notification!;
        // AndroidNotification android = message.notification!.android!;
        Future.delayed(Duration.zero, () {
          print(message.data["path"]);
          // BlocProvider.of<NotificationBloc>(key.currentContext!).add(
          //   NavigateEvent(int.parse(message.data["path"])),
          // );
          showFlutterNotification(message);
        });
      });
    } catch (e) {
      log(e.toString());
    }
  }
}
