import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const String _urlDefinidaPorAmbiente = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_urlDefinidaPorAmbiente.isNotEmpty) {
      return _urlDefinidaPorAmbiente;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }
}
