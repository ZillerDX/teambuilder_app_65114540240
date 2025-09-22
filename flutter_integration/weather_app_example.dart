import 'package:flutter/material.dart';
import 'weather_mcp_service.dart';

/// Example Flutter app demonstrating MCP Weather integration
class WeatherMcpApp extends StatelessWidget {
  const WeatherMcpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather MCP Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final WeatherMcpService _weatherService = WeatherMcpService();
  final TextEditingController _locationController = TextEditingController();

  WeatherData? _currentWeather;
  WeatherForecast? _forecast;
  LocationInfo? _locationInfo;

  bool _isLoading = false;
  bool _isServerConnected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeServer();
  }

  Future<void> _initializeServer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _weatherService.startServer();
      setState(() {
        _isServerConnected = success;
        if (!success) {
          _errorMessage = 'Failed to start MCP weather server';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error starting server: $e';
        _isServerConnected = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentWeather() async {
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      _showSnackBar('Please enter a location');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weather = await _weatherService.getCurrentWeather(location);
      setState(() {
        _currentWeather = weather;
        if (weather == null) {
          _errorMessage = 'No weather data found for $location';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting weather: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getForecast({int days = 5}) async {
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      _showSnackBar('Please enter a location');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final forecast = await _weatherService.getWeatherForecast(location, days: days);
      setState(() {
        _forecast = forecast;
        if (forecast == null) {
          _errorMessage = 'No forecast data found for $location';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting forecast: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchLocation() async {
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      _showSnackBar('Please enter a location');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locationInfo = await _weatherService.searchLocation(location);
      setState(() {
        _locationInfo = locationInfo;
        if (locationInfo == null) {
          _errorMessage = 'Location not found: $location';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching location: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather MCP Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Icon(
            _isServerConnected ? Icons.cloud_done : Icons.cloud_off,
            color: _isServerConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Server Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isServerConnected ? Icons.check_circle : Icons.error,
                      color: _isServerConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isServerConnected
                          ? 'MCP Weather Server Connected'
                          : 'MCP Server Disconnected',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location Input
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Enter city name (e.g., Bangkok, Thailand)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              onSubmitted: (_) => _getCurrentWeather(),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isServerConnected && !_isLoading
                        ? _getCurrentWeather
                        : null,
                    icon: const Icon(Icons.wb_sunny),
                    label: const Text('Current Weather'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isServerConnected && !_isLoading
                        ? _getForecast
                        : null,
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('5-Day Forecast'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isServerConnected && !_isLoading
                  ? _searchLocation
                  : null,
              icon: const Icon(Icons.search),
              label: const Text('Search Location'),
            ),

            const SizedBox(height: 16),

            // Loading Indicator
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),

            // Error Message
            if (_errorMessage != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Current Weather Display
            if (_currentWeather != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Weather',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Divider(),
                      _buildWeatherInfo('Location', _currentWeather!.location),
                      _buildWeatherInfo('Temperature', _currentWeather!.temperature),
                      _buildWeatherInfo('Feels Like', _currentWeather!.feelsLike),
                      _buildWeatherInfo('Humidity', _currentWeather!.humidity),
                      _buildWeatherInfo('Wind', _currentWeather!.windSpeed),
                      _buildWeatherInfo('Pressure', _currentWeather!.pressure),
                      _buildWeatherInfo('Cloud Cover', _currentWeather!.cloudCover),
                      _buildWeatherInfo('Precipitation', _currentWeather!.precipitation),
                      _buildWeatherInfo('Time of Day', _currentWeather!.timeOfDay),
                    ],
                  ),
                ),
              ),
            ],

            // Forecast Display
            if (_forecast != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_forecast!.days}-Day Forecast',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        _forecast!.location,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Divider(),
                      ...(_forecast!.dailyForecasts.map((daily) =>
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                daily.date,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (daily.temperature != null)
                                Text('  ${daily.temperature}'),
                              if (daily.precipitation != null)
                                Text('  ${daily.precipitation}'),
                              if (daily.wind != null)
                                Text('  ${daily.wind}'),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],

            // Location Info Display
            if (_locationInfo != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Divider(),
                      _buildWeatherInfo('Name', _locationInfo!.name),
                      _buildWeatherInfo('Country', _locationInfo!.country),
                      _buildWeatherInfo('Latitude', _locationInfo!.latitude.toString()),
                      _buildWeatherInfo('Longitude', _locationInfo!.longitude.toString()),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _weatherService.close();
    _locationController.dispose();
    super.dispose();
  }
}

/// Example usage in main.dart:
///
/// void main() {
///   runApp(const WeatherMcpApp());
/// }