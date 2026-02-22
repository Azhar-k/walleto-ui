import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/models.dart';

part 'account_service.g.dart';

@RestApi()
abstract class AccountService {
  factory AccountService(Dio dio, {String baseUrl}) = _AccountService;

  @GET('/api/accounts')
  Future<List<Account>> getAccounts();

  @GET('/api/accounts/default')
  Future<Account> getDefaultAccount();

  @POST('/api/accounts')
  Future<Account> createAccount(@Body() Account account);

  @PUT('/api/accounts/{id}')
  Future<Account> updateAccount(@Path() int id, @Body() Account account);

  @DELETE('/api/accounts/{id}')
  Future<void> deleteAccount(@Path() int id);

  @PUT('/api/accounts/{id}/default')
  Future<void> setDefaultAccount(@Path() int id);
}
