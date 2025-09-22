import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Flutter service for integrating with MCP Weather Server
/// This service provides a bridge between Flutter apps and the MCP weather server
class WeatherMcpService {
  Process? _serverProcess;
  bool _isConnected = false;
  int _requestId = 0;

  bool get isConnected => _isConnected;

  /// Start the MCP weather server
  Future<bool> startServer({String? serverPath}) async {
    try {
      // Default path to weather server
      serverPath ??= '../weather/weather.py';

      // Start the Python MCP server process
      _serverProcess = await Process.start(
        'python',
        [serverPath],
        mode: ProcessStartMode.normal,
      );

      // Initialize the MCP connection
      await _initialize();
      _isConnected = true;

      if (kDebugMode) {
        print('Weather MCP server started successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to start weather server: $e');
      }
      return false;
    }
  }

  /// Initialize MCP connection
  Future<void> _initialize() async {
    final initRequest = {
      'jsonrpc': '2.0',
      'id': _getRequestId(),
      'method': 'initialize',
      'params': {
        'protocolVersion': '2024-11-05',
        'capabilities': {'tools': {}},
        'clientInfo': {
          'name': 'flutter-weather-client',
          'version': '1.0.0',
        }
      }
    };

    await _sendRequest(initRequest);

    // Send initialized notification
    final initializedNotification = {
      'jsonrpc': '2.0',
      'method': 'notifications/initialized'
    };

    await _sendNotification(initializedNotification);
  }

  /// Get current weather for a location
  Future<WeatherData?> getCurrentWeather(String location) async {
    if (!_isConnected || _serverProcess == null) {
      throw Exception('MCP server not connected');
    }

    try {
      final request = {
        'jsonrpc': '2.0',
        'id': _getRequestId(),
        'method': 'tools/call',
        'params': {
          'name': 'get_current_weather',
          'arguments': {'location': location}
        }
      };

      final response = await _sendRequest(request);
      final result = response['result'];

      if (result != null && result['content'] != null) {
        final weatherText = result['content'][0]['text'];
        return WeatherData.fromText(weatherText, location);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current weather: $e');
      }
      return null;
    }
  }

  /// Get weather forecast for a location
  Future<WeatherForecast?> getWeatherForecast(String location, {int days = 7}) async {
    if (!_isConnected || _serverProcess == null) {
      throw Exception('MCP server not connected');
    }

    try {
      final request = {
        'jsonrpc': '2.0',
        'id': _getRequestId(),
        'method': 'tools/call',
        'params': {
          'name': 'get_weather_forecast',
          'arguments': {
            'location': location,
            'days': days,
          }
        }
      };

      final response = await _sendRequest(request);
      final result = response['result'];

      if (result != null && result['content'] != null) {
        final forecastText = result['content'][0]['text'];
        return WeatherForecast.fromText(forecastText, location, days);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting weather forecast: $e');
      }
      return null;
    }
  }

  /// Search for location coordinates
  Future<LocationInfo?> searchLocation(String location) async {
    if (!_isConnected || _serverProcess == null) {
      throw Exception('MCP server not connected');
    }

    try {
      final request = {
        'jsonrpc': '2.0',
        'id': _getRequestId(),
        'method': 'tools/call',
        'params': {
          'name': 'search_location',
          'arguments': {'location': location}
        }
      };

      final response = await _sendRequest(request);
      final result = response['result'];

      if (result != null && result['content'] != null) {
        final locationText = result['content'][0]['text'];
        return LocationInfo.fromText(locationText);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching location: $e');
      }
      return null;
    }
  }

  /// Send request to MCP server
  Future<Map<String, dynamic>> _sendRequest(Map<String, dynamic> request) async {
    if (_serverProcess == null) {
      throw Exception('Server process not available');
    }

    // Send request
    final requestJson = '${jsonEncode(request)}\n';
    _serverProcess!.stdin.write(requestJson);
    await _serverProcess!.stdin.flush();

    // Read response
    final responseBytes = await _serverProcess!.stdout.first;
    final responseString = utf8.decode(responseBytes).trim();

    try {
      final response = jsonDecode(responseString) as Map<String, dynamic>;

      if (response.containsKey('error')) {
        throw Exception('Server error: ${response['error']}');
      }

      return response;
    } catch (e) {
      throw Exception('Invalid server response: $e');
    }
  }

  /// Send notification to MCP server
  Future<void> _sendNotification(Map<String, dynamic> notification) async {
    if (_serverProcess == null) {
      throw Exception('Server process not available');
    }

    final notificationJson = '${jsonEncode(notification)}\n';
    _serverProcess!.stdin.write(notificationJson);
    await _serverProcess!.stdin.flush();
  }

  /// Get next request ID
  int _getRequestId() {
    return ++_requestId;
  }

  /// Close the connection and stop the server
  Future<void> close() async {
    if (_serverProcess != null) {
      _serverProcess!.kill();
      await _serverProcess!.exitCode;
      _serverProcess = null;
    }
    _isConnected = false;

    if (kDebugMode) {
      print('Weather MCP server stopped');
    }
  }
}

/// Weather data model
class WeatherData {
  final String location;
  final String temperature;
  final String feelsLike;
  final String humidity;
  final String windSpeed;
  final String pressure;
  final String cloudCover;
  final String precipitation;
  final String timeOfDay;
  final String rawText;

  WeatherData({
    required this.location,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.cloudCover,
    required this.precipitation,
    required this.timeOfDay,
    required this.rawText,
  });

  factory WeatherData.fromText(String text, String requestedLocation) {
    // Parse the weather text response
    // This is a simple parser - you might want to use regex for more robust parsing
    final lines = text.split('\n');

    String location = requestedLocation;
    String temperature = 'N/A';
    String feelsLike = 'N/A';
    String humidity = 'N/A';
    String windSpeed = 'N/A';
    String pressure = 'N/A';
    String cloudCover = 'N/A';
    String precipitation = 'N/A';
    String timeOfDay = 'N/A';

    for (final line in lines) {
      if (line.contains('Current weather for')) {
        location = line.replaceFirst('Current weather for ', '').replaceFirst(':', '');
      } else if (line.contains('Temperature:')) {
        final parts = line.split('(feels like ');
        temperature = parts[0].replaceFirst('Temperature: ', '').trim();
        if (parts.length > 1) {
          feelsLike = parts[1].replaceFirst(')', '').trim();
        }
      } else if (line.contains('Humidity:')) {
        humidity = line.replaceFirst('Humidity: ', '').trim();
      } else if (line.contains('Wind:')) {
        windSpeed = line.replaceFirst('Wind: ', '').trim();
      } else if (line.contains('Pressure:')) {
        pressure = line.replaceFirst('Pressure: ', '').trim();
      } else if (line.contains('Cloud Cover:')) {
        cloudCover = line.replaceFirst('Cloud Cover: ', '').trim();
      } else if (line.contains('Precipitation:')) {
        precipitation = line.replaceFirst('Precipitation: ', '').trim();
      } else if (line.contains('Time of Day:')) {
        timeOfDay = line.replaceFirst('Time of Day: ', '').trim();
      }
    }

    return WeatherData(
      location: location,
      temperature: temperature,
      feelsLike: feelsLike,
      humidity: humidity,
      windSpeed: windSpeed,
      pressure: pressure,
      cloudCover: cloudCover,
      precipitation: precipitation,
      timeOfDay: timeOfDay,
      rawText: text,
    );
  }
}

/// Weather forecast model
class WeatherForecast {
  final String location;
  final int days;
  final List<DailyForecast> dailyForecasts;
  final String rawText;

  WeatherForecast({
    required this.location,
    required this.days,
    required this.dailyForecasts,
    required this.rawText,
  });

  factory WeatherForecast.fromText(String text, String requestedLocation, int days) {
    final lines = text.split('\n');
    final List<DailyForecast> forecasts = [];

    String location = requestedLocation;
    DailyForecast? currentForecast;

    for (final line in lines) {
      if (line.contains('Weather forecast for')) {
        location = line.split(' (')[0].replaceFirst('Weather forecast for ', '');
      } else if (line.contains('📅')) {
        // Save previous forecast if exists
        if (currentForecast != null) {
          forecasts.add(currentForecast);
        }
        // Start new forecast
        final date = line.replaceFirst('📅 ', '').replaceFirst(':', '').trim();
        currentForecast = DailyForecast(date: date);
      } else if (line.contains('🌡️') && currentForecast != null) {
        final tempPart = line.replaceFirst('  🌡️  ', '').trim();
        currentForecast = currentForecast.copyWith(temperature: tempPart);
      } else if (line.contains('🌧️') && currentForecast != null) {
        final precipPart = line.replaceFirst('  🌧️  ', '').trim();
        currentForecast = currentForecast.copyWith(precipitation: precipPart);
      } else if (line.contains('💨') && currentForecast != null) {
        final windPart = line.replaceFirst('  💨 ', '').trim();
        currentForecast = currentForecast.copyWith(wind: windPart);
      }
    }

    // Don't forget the last forecast
    if (currentForecast != null) {
      forecasts.add(currentForecast);
    }

    return WeatherForecast(
      location: location,
      days: days,
      dailyForecasts: forecasts,
      rawText: text,
    );
  }
}

/// Daily forecast model
class DailyForecast {
  final String date;
  final String? temperature;
  final String? precipitation;
  final String? wind;

  DailyForecast({
    required this.date,
    this.temperature,
    this.precipitation,
    this.wind,
  });

  DailyForecast copyWith({
    String? date,
    String? temperature,
    String? precipitation,
    String? wind,
  }) {
    return DailyForecast(
      date: date ?? this.date,
      temperature: temperature ?? this.temperature,
      precipitation: precipitation ?? this.precipitation,
      wind: wind ?? this.wind,
    );
  }
}

/// Location information model
class LocationInfo {
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final String rawText;

  LocationInfo({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.rawText,
  });

  factory LocationInfo.fromText(String text) {
    final lines = text.split('\n');

    String name = '';
    String country = '';
    double latitude = 0.0;
    double longitude = 0.0;

    for (final line in lines) {
      if (line.contains('Location:')) {
        final locationPart = line.replaceFirst('Location: ', '').trim();
        final parts = locationPart.split(', ');
        if (parts.length >= 2) {
          name = parts[0];
          country = parts[1];
        } else {
          name = locationPart;
        }
      } else if (line.contains('Coordinates:')) {
        final coordsPart = line.replaceFirst('Coordinates: ', '').trim();
        final coords = coordsPart.split(', ');
        if (coords.length >= 2) {
          latitude = double.tryParse(coords[0]) ?? 0.0;
          longitude = double.tryParse(coords[1]) ?? 0.0;
        }
      }
    }

    return LocationInfo(
      name: name,
      country: country,
      latitude: latitude,
      longitude: longitude,
      rawText: text,
    );
  }
}