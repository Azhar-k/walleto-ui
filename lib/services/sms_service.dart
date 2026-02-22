import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'sms_service.g.dart';

@RestApi()
abstract class SmsService {
  factory SmsService(Dio dio, {String baseUrl}) = _SmsService;

  @POST('/api/sms/process-batch')
  Future<dynamic> processBatchSms(@Body() List<dynamic> messages);
}
