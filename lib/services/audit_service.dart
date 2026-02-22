import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/models.dart';

part 'audit_service.g.dart';

@RestApi()
abstract class AuditService {
  factory AuditService(Dio dio, {String baseUrl}) = _AuditService;

  @GET('/api/audit-logs')
  Future<List<AuditLog>> getAuditLogs();
}
