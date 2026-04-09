import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeSmsService {
  static const _channel = MethodChannel('com.walleto.sms/scan');

  Future<List<Map<String, dynamic>>> getRcsMessages({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (!Platform.isAndroid) {
      return [];
    }

    try {
      debugPrint(
        "NativeSmsService: Invoking getRcsMessages for range $startTime to $endTime",
      );
      final List<dynamic>? result = await _channel.invokeMethod('getRcsMessages', {
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
      });

      if (result == null) {
        debugPrint("NativeSmsService: Received null result from native side");
        return [];
      }

      debugPrint(
        "NativeSmsService: Received ${result.length} RCS messages from native side",
      );
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PlatformException catch (e) {
      debugPrint(
        "NativeSmsService: Failed to get RCS messages: '${e.message}'.",
      );
      return [];
    }
  }
}
