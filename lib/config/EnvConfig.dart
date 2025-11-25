import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get ENVIRONMENT => dotenv.env['ENVIRONMENT'] ?? 'LOCAL';
  static String get BASE_URL    => dotenv.env['BASE_URL']    ?? 'http://172.30.1.94:8083';
}