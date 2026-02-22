import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/models.dart';

part 'category_service.g.dart';

@RestApi()
abstract class CategoryService {
  factory CategoryService(Dio dio, {String baseUrl}) = _CategoryService;

  @GET('/api/categories')
  Future<List<Category>> getCategories();

  @GET('/api/categories/{id}')
  Future<Category> getCategoryById(@Path() int id);

  @POST('/api/categories')
  Future<Category> createCategory(@Body() Category category);

  @PUT('/api/categories/{id}')
  Future<Category> updateCategory(@Path() int id, @Body() Category category);

  @DELETE('/api/categories/{id}')
  Future<void> deleteCategory(@Path() int id);
}
