import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import '../core/network/api_client.dart';
import 'sms_service.dart';
import '../core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top level function for handling background SMS. It MUST be a top-level function.
@pragma('vm:entry-point')
void backgroudMessageHandler(SmsMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  debugPrint("Background SMS received from: ${message.address}");
  await SmsListenerService.processIncomingSms(message);
}

class SmsListenerService {
  static final Telephony telephony = Telephony.instance;

  static Future<void> initialize() async {
    debugPrint("Initializing SMS Listener...");

    if (kIsWeb) {
      debugPrint("SMS Listening is not supported on the Web platform.");
      return;
    }

    // 1. Initialize Standard SMS Telephony Listener
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted == true) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) async {
          debugPrint("Foreground SMS received from: ${message.address}");
          await processIncomingSms(message);
        },
        onBackgroundMessage: backgroudMessageHandler,
      );
    } else {
      debugPrint("SMS Listening Permissions Denied.");
    }

    // 2. Initialize Notification Listener for RCS / other messages
    try {
      bool status = await NotificationListenerService.isPermissionGranted();
      if (!status) {
        debugPrint("Requesting notification listener permission for RCS...");
        status = await NotificationListenerService.requestPermission();
      }

      if (status) {
        debugPrint(
          "Notification listener permission granted. Listening for notifications...",
        );
        NotificationListenerService.notificationsStream.listen((
          ServiceNotificationEvent event,
        ) async {
          if (event.hasRemoved == true) return;

          final String pkg = event.packageName ?? '';
          // Common messaging app packages: Google Messages, Samsung Messages, generic SMS/MMS apps
          if (pkg.contains("messaging") ||
              pkg.contains("mms") ||
              pkg.contains("sms") ||
              pkg.contains("whatsapp")) {
            debugPrint("Incoming message notification detected from $pkg");
            if (event.title != null &&
                event.content != null &&
                event.content!.isNotEmpty) {
              await processIncomingNotification(event);
            }
          }
        });
      } else {
        debugPrint("Notification listener permission denied.");
      }
    } catch (e) {
      debugPrint("Failed to initialize notification listener: $e");
    }
  }

  static Future<void> processIncomingSms(SmsMessage message) async {
    try {
      // Cross-Isolate Lock: Cache the standard SMS body to prevent Notification duplication
      final prefs = await SharedPreferences.getInstance();
      final lastBody = prefs.getString('last_sms_body');
      final lastTime = prefs.getInt('last_sms_time') ?? 0;
      
      // If the exact same text arrived via Notification less than 15 seconds ago, silently drop this!
      if (message.body == lastBody && (DateTime.now().millisecondsSinceEpoch - lastTime) < 15000) {
        debugPrint("Dropping SMS duplicate. Already handled by Notification module.");
        return;
      }

      await prefs.setString('last_sms_body', message.body ?? '');
      await prefs.setInt('last_sms_time', DateTime.now().millisecondsSinceEpoch);

      final dio = ApiClient.getCoreClient();
      final service = SmsService(dio);

      final mappedMessage = {
        "sender": message.address,
        "body": message.body,
        "timestamp": message.date,
      };

      await service.processBatchSms({
        'messages': [mappedMessage],
      });
      debugPrint("Successfully processed incoming SMS from ${message.address}");
    } catch (e) {
      debugPrint("Failed to process incoming SMS: $e");
    }
  }

  static Future<void> processIncomingNotification(
    ServiceNotificationEvent event,
  ) async {
    try {
      // Cross-Isolate Lock: Check if this notification perfectly matches an SMS we literally just processed
      final prefs = await SharedPreferences.getInstance();
      final lastBody = prefs.getString('last_sms_body');
      final lastTime = prefs.getInt('last_sms_time') ?? 0;
      
      // If the exact same text arrived natively less than 15 seconds ago, silently drop this notification!
      if (event.content == lastBody && (DateTime.now().millisecondsSinceEpoch - lastTime) < 15000) {
        debugPrint("Dropping notification duplicate. Handled by native SMS module.");
        return;
      }

      await prefs.setString('last_sms_body', event.content ?? '');
      await prefs.setInt('last_sms_time', DateTime.now().millisecondsSinceEpoch);

      final dio = ApiClient.getCoreClient();
      final service = SmsService(dio);

      final mappedMessage = {
        "sender": event.title,
        "body": event.content,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      };

      await service.processBatchSms({
        'messages': [mappedMessage],
      });
      debugPrint(
        "Successfully processed incoming Notification message from ${event.title}",
      );
    } catch (e) {
      debugPrint("Failed to process incoming Notification: $e");
    }
  }
}
