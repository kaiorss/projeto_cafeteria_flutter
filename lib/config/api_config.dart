class ApiConfig {
  const ApiConfig._();

  static const String _urlDefinidaPorAmbiente = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const String _urlPadrao = 'https://cafeteria-api-h3bm.onrender.com';

  static String get baseUrl {
    final String definida = _urlDefinidaPorAmbiente.trim();
    return normalizar(definida.isEmpty ? _urlPadrao : definida);
  }

  static String normalizar(String url) {
    String normalizada = url.trim();

    while (normalizada.endsWith('/')) {
      normalizada = normalizada.substring(0, normalizada.length - 1);
    }

    if (normalizada.endsWith('/api')) {
      normalizada = normalizada.substring(0, normalizada.length - 4);
    }

    return normalizada;
  }
}
