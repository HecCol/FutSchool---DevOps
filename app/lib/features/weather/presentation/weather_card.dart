import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../captain/presentation/captain_design.dart';
import '../data/open_meteo_service.dart';
import '../domain/current_weather.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  static const _sanJuanLatitude = 20.388;
  static const _sanJuanLongitude = -99.996;
  final _weatherService = OpenMeteoService();
  CurrentWeather? _weather;
  bool _loading = false;
  String? _place;
  String? _error;

  Future<void> _fetchWeather({required bool useDeviceLocation}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var latitude = _sanJuanLatitude;
      var longitude = _sanJuanLongitude;
      var place = 'San Juan del Río';

      if (useDeviceLocation) {
        if (kIsWeb &&
            !Uri.base.isScheme('https') &&
            Uri.base.host != 'localhost') {
          throw const _LocationFailure(
            'El navegador requiere HTTPS para compartir ubicación.',
          );
        }
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw const _LocationFailure(
            'Activa el servicio de ubicación o consulta San Juan del Río.',
          );
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw const _LocationFailure(
            'No se concedió ubicación. Puedes consultar el clima de San Juan del Río.',
          );
        }
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 15),
          ),
        );
        latitude = position.latitude;
        longitude = position.longitude;
        place = 'Tu zona aproximada';
      }

      final weather = await _weatherService.fetchCurrent(
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) return;
      setState(() {
        _weather = weather;
        _place = place;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is _LocationFailure
              ? error.message
              : error is OpenMeteoFailure
              ? error.message
              : 'No se pudo consultar el clima. Revisa tu conexión e intenta de nuevo.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => CaptainCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.cloud_outlined, color: captainGreen),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Clima para la jornada',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_weather case final weather?) ...[
          Text(
            _place ?? 'Clima actual',
            style: const TextStyle(color: captainText),
          ),
          const SizedBox(height: 6),
          Text(
            '${weather.temperatureCelsius.round()} °C · ${weather.description}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Lluvia: ${weather.precipitationMm.toStringAsFixed(1)} mm · '
            'Viento: ${weather.windSpeedKmh.round()} km/h · '
            'Humedad: ${weather.relativeHumidity}%',
            style: const TextStyle(color: captainMuted),
          ),
        ] else
          const Text(
            'Consulta condiciones actuales antes de organizar tu partido.',
            style: TextStyle(color: captainText),
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Color(0xFFFFA0A0))),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _loading
                  ? null
                  : () => _fetchWeather(useDeviceLocation: true),
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Usar mi ubicación'),
            ),
            TextButton.icon(
              onPressed: _loading
                  ? null
                  : () => _fetchWeather(useDeviceLocation: false),
              icon: const Icon(Icons.stadium_outlined),
              label: const Text('San Juan del Río'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Al usar GPS se envían coordenadas aproximadas a Open-Meteo para esta consulta; FutSchool no las guarda. Datos: Open-Meteo.',
          style: TextStyle(color: captainMuted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _LocationFailure implements Exception {
  const _LocationFailure(this.message);
  final String message;
}
