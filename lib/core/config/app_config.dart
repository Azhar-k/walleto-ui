import 'dart:convert';
import 'package:flutter/services.dart';

class AppConfig {
  static late String coreBaseUrl;
  static late String userBaseUrl;

  static Future<void> load() async {
    final configString = await rootBundle.loadString('assets/config.json');
    final configData = jsonDecode(configString);

    coreBaseUrl = configData['coreBaseUrl'];
    userBaseUrl = configData['userBaseUrl'];
  }
}
