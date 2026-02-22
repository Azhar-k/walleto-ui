import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/models.dart';

part 'transaction_service.g.dart';

@RestApi()
abstract class TransactionService {
  factory TransactionService(Dio dio, {String baseUrl}) = _TransactionService;

  @POST('/api/transactions/search')
  Future<List<Transaction>> searchTransactions(@Body() Map<String, dynamic> criteria);

  @GET('/api/transactions/{id}')
  Future<Transaction> getTransactionById(@Path() int id);

  @POST('/api/transactions')
  Future<Transaction> createTransaction(@Body() Transaction transaction);

  @PUT('/api/transactions/{id}')
  Future<Transaction> updateTransaction(@Path() int id, @Body() Transaction transaction);

  @DELETE('/api/transactions/{id}')
  Future<void> deleteTransaction(@Path() int id);
}
