class CurrentWeather {
  const CurrentWeather({
    required this.temperatureCelsius,
    required this.relativeHumidity,
    required this.precipitationMm,
    required this.weatherCode,
    required this.windSpeedKmh,
  });

  final double temperatureCelsius;
  final int relativeHumidity;
  final double precipitationMm;
  final int weatherCode;
  final double windSpeedKmh;

  String get description => switch (weatherCode) {
    0 => 'Despejado',
    1 => 'Mayormente despejado',
    2 => 'Parcialmente nublado',
    3 => 'Nublado',
    45 || 48 => 'Neblina',
    51 || 53 || 55 => 'Llovizna',
    56 || 57 => 'Llovizna helada',
    61 || 63 || 65 => 'Lluvia',
    66 || 67 => 'Lluvia helada',
    71 || 73 || 75 || 77 => 'Nieve',
    80 || 81 || 82 => 'Chubascos',
    85 || 86 => 'Chubascos de nieve',
    95 || 96 || 99 => 'Tormenta',
    _ => 'Condición variable',
  };

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    double number(String key) {
      final value = json[key];
      if (value is num) return value.toDouble();
      throw const FormatException('Respuesta meteorológica incompleta.');
    }

    return CurrentWeather(
      temperatureCelsius: number('temperature_2m'),
      relativeHumidity: number('relative_humidity_2m').round(),
      precipitationMm: number('precipitation'),
      weatherCode: number('weather_code').round(),
      windSpeedKmh: number('wind_speed_10m'),
    );
  }
}
