import 'dart:io';
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
      print("NativeSmsService: Invoking getRcsMessages for range $startTime to $endTime");
      final List<dynamic>? result = await _channel.invokeMethod('getRcsMessages', {
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
      });

      if (result == null) {
        print("NativeSmsService: Received null result from native side");
        return [];
      }

      print("NativeSmsService: Received ${result.length} RCS messages from native side");
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PlatformException catch (e) {
      print("NativeSmsService: Failed to get RCS messages: '${e.message}'.");
      return [];
    }
  }
}
