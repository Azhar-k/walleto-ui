import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'sms_service.g.dart';

/// Request body matching BulkSmsDTO: { "messages": [...] }
class BulkSmsRequest {
  final List<Map<String, dynamic>> messages;
  BulkSmsRequest(this.messages);
  Map<String, dynamic> toJson() => {'messages': messages};
}

@RestApi()
abstract class SmsService {
  factory SmsService(Dio dio, {String baseUrl}) = _SmsService;

  /// POST /api/sms/process/bulk
  /// Returns SmsProcessingResultDTO fields:
  ///   createdTransactions, duplicatesIdentified, patternNotMatched, processingError
  @POST('/api/sms/process/bulk')
  Future<dynamic> processBatchSms(@Body() Map<String, dynamic> body);
}
