import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/models.dart';

part 'additional_services.g.dart';

@RestApi()
abstract class TransferService {
  factory TransferService(Dio dio, {String baseUrl}) = _TransferService;

  @POST('/api/transfers')
  Future<void> transferFunds(@Body() Map<String, dynamic> request);
}

@RestApi()
abstract class RecurringPaymentService {
  factory RecurringPaymentService(Dio dio, {String baseUrl}) = _RecurringPaymentService;

  @GET('/api/recurring-payments')
  Future<List<RecurringPayment>> getRecurringPayments();

  @GET('/api/recurring-payments/{id}')
  Future<RecurringPayment> getRecurringPaymentById(@Path() int id);

  @POST('/api/recurring-payments')
  Future<RecurringPayment> createRecurringPayment(@Body() RecurringPayment payment);

  @PUT('/api/recurring-payments/{id}')
  Future<RecurringPayment> updateRecurringPayment(@Path() int id, @Body() RecurringPayment payment);

  @DELETE('/api/recurring-payments/{id}')
  Future<void> deleteRecurringPayment(@Path() int id);

  @PUT('/api/recurring-payments/{id}/complete')
  Future<void> completeRecurringPayment(@Path() int id);
  
  @PUT('/api/recurring-payments/toggle-all')
  Future<void> toggleAll(@Body() Map<String, dynamic> request);
}

@RestApi()
abstract class RegexService {
  factory RegexService(Dio dio, {String baseUrl}) = _RegexService;

  @GET('/api/regex')
  Future<List<RegexPattern>> getRegexPatterns();

  @GET('/api/regex/{id}')
  Future<RegexPattern> getRegexPatternById(@Path() int id);

  @POST('/api/regex')
  Future<RegexPattern> createRegexPattern(@Body() RegexPattern pattern);

  @PUT('/api/regex/{id}')
  Future<RegexPattern> updateRegexPattern(@Path() int id, @Body() RegexPattern pattern);

  @DELETE('/api/regex/{id}')
  Future<void> deleteRegexPattern(@Path() int id);
}
