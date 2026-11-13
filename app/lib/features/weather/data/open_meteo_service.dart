import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/current_weather.dart';

class OpenMeteoService {
  OpenMeteoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<CurrentWeather> fetchCurrent({
    required double latitude,
    required double longitude,
  }) async {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw const FormatException('La ubicación no es válida.');
    }

    // Weather is returned for a model grid cell; two decimals avoid sending
    // more precise coordinates than the service needs.
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toStringAsFixed(2),
      'longitude': longitude.toStringAsFixed(2),
      'current': 'temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m',
      'temperature_unit': 'celsius',
      'wind_speed_unit': 'kmh',
      'timezone': 'auto',
    });

    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw const OpenMeteoFailure('El servicio del clima no está disponible.');
    }
    try {
      final root = jsonDecode(response.body);
      if (root is! Map<String, dynamic> ||
          root['current'] is! Map<String, dynamic>) {
        throw const FormatException();
      }
      return CurrentWeather.fromJson(root['current'] as Map<String, dynamic>);
    } on FormatException {
      throw const OpenMeteoFailure('No se pudo interpretar el clima recibido.');
    }
  }
}

class OpenMeteoFailure implements Exception {
  const OpenMeteoFailure(this.message);
  final String message;
}
