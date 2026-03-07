import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import '../core/network/api_client.dart';
import 'sms_service.dart';

/// Top level function for handling background SMS. It MUST be a top-level function.
@pragma('vm:entry-point')
void backgroudMessageHandler(SmsMessage message) async {
  debugPrint("Background SMS received from: ${message.address}");
  await SmsListenerService.processIncomingSms(message);
}

class SmsListenerService {
  static final Telephony telephony = Telephony.instance;

  static Future<void> initialize() async {
    debugPrint("Initializing SMS Listener...");

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
  }

  static Future<void> processIncomingSms(SmsMessage message) async {
    try {
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
}
