import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sms_service.dart';
import '../services/native_sms_service.dart';
import 'core_providers.dart';

final smsServiceProvider = Provider((ref) {
  return SmsService(ref.watch(coreDioProvider));
});

final nativeSmsServiceProvider = Provider((ref) {
  return NativeSmsService();
});
