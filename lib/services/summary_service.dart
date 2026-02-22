import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/models.dart';

part 'summary_service.g.dart';

@RestApi()
abstract class SummaryService {
  factory SummaryService(Dio dio, {String baseUrl}) = _SummaryService;

  @GET('/api/summary/monthly')
  Future<MonthlySummary> getMonthlySummary(
    @Query('year') int year,
    @Query('month') int month,
    @Query('accountId') int? accountId,
  );
  
  @GET('/api/balances/net')
  Future<double> getNetBalance();
}
