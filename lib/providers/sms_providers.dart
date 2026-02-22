import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sms_service.dart';
import 'core_providers.dart';

final smsServiceProvider = Provider((ref) {
  return SmsService(ref.watch(coreDioProvider));
});
