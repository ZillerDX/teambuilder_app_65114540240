# MCP Weather Server & Flutter Integration Implementation

A complete practical implementation of Model Context Protocol (MCP) weather server with Flutter client integration using free APIs.

Created by **Tanathon Chanapha 6511454**

## Overview

This project demonstrates how to build and integrate MCP (Model Context Protocol) services with Flutter applications. It includes:

- **Weather MCP Server**: Python-based server using Open-Meteo free API
- **MCP Client**: Python client for server communication
- **Flutter Integration**: Dart service and UI components for Flutter apps

## Features

### Weather MCP Server
- Current weather conditions for any location
- Multi-day weather forecasts (up to 16 days)
- Location search and coordinate lookup
- No API key required (uses Open-Meteo free service)
- Full MCP protocol compliance

### Flutter Integration
- Complete Flutter service for MCP communication
- Pre-built UI components and examples
- Error handling and loading states
- Cross-platform compatibility

### Free API Integration
- **Open-Meteo API**: No API key required, high-quality weather data
- Worldwide coverage with hourly updates
- Historical and forecast data support

## Project Structure

```
mcp_workspace/
├── weather/                    # MCP Weather Server
│   ├── weather.py             # Main server implementation
│   └── requirements.txt       # Python dependencies
├── mcp-client/                # MCP Client
│   ├── client.py              # Client implementation with demo
│   └── requirements.txt       # Python dependencies
├── flutter_integration/       # Flutter Integration
│   ├── weather_mcp_service.dart    # Flutter MCP service
│   └── weather_app_example.dart    # Example Flutter app
├── setup.py                   # Setup and test script
├── README_MCP.md              # MCP theoretical documentation
└── README_IMPLEMENTATION.md   # This practical guide
```

## Quick Start

### 1. Setup Environment

```bash
# Install Python dependencies
python setup.py

# Or manually:
pip install -r weather/requirements.txt
pip install -r mcp-client/requirements.txt
```

### 2. Test MCP Server

```bash
# Run interactive client demo
python mcp-client/client.py

# Or run automated tests
python mcp-client/client.py test
```

### 3. Flutter Integration

```dart
// Add to your Flutter project
import 'flutter_integration/weather_mcp_service.dart';

// Initialize service
final weatherService = WeatherMcpService();
await weatherService.startServer();

// Get current weather
final weather = await weatherService.getCurrentWeather('Bangkok, Thailand');
```

## MCP Server API

### Available Tools

#### 1. get_current_weather
Get current weather conditions for a location.

**Parameters:**
- `location` (string): City name (e.g., "Bangkok, Thailand")

**Example:**
```json
{
  "name": "get_current_weather",
  "arguments": {
    "location": "Bangkok, Thailand"
  }
}
```

#### 2. get_weather_forecast
Get weather forecast for a location.

**Parameters:**
- `location` (string): City name
- `days` (integer): Number of forecast days (1-16, default: 7)

**Example:**
```json
{
  "name": "get_weather_forecast",
  "arguments": {
    "location": "New York",
    "days": 5
  }
}
```

#### 3. search_location
Search for location coordinates.

**Parameters:**
- `location` (string): Location name to search

**Example:**
```json
{
  "name": "search_location",
  "arguments": {
    "location": "Tokyo"
  }
}
```

## Flutter Integration Guide

### 1. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  # Add other dependencies as needed
```

### 2. Initialize Weather Service

```dart
class WeatherApp extends StatefulWidget {
  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  final WeatherMcpService _weatherService = WeatherMcpService();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    final success = await _weatherService.startServer();
    setState(() {
      _isConnected = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
        actions: [
          Icon(
            _isConnected ? Icons.cloud_done : Icons.cloud_off,
            color: _isConnected ? Colors.green : Colors.red,
          ),
        ],
      ),
      body: _isConnected ? WeatherContent() : LoadingScreen(),
    );
  }

  @override
  void dispose() {
    _weatherService.close();
    super.dispose();
  }
}
```

### 3. Get Weather Data

```dart
Future<void> _getCurrentWeather(String location) async {
  try {
    final weather = await _weatherService.getCurrentWeather(location);
    if (weather != null) {
      setState(() {
        _currentWeather = weather;
      });
    }
  } catch (e) {
    // Handle error
    print('Error getting weather: $e');
  }
}
```

## Technical Details

### MCP Protocol Implementation

The server implements the full MCP specification:

- **Initialization**: Proper handshake and capability negotiation
- **Tool Listing**: Dynamic tool discovery
- **Tool Execution**: Secure tool invocation with parameter validation
- **Error Handling**: Comprehensive error responses

### Open-Meteo API Integration

Benefits of using Open-Meteo:

- **No API Key Required**: Start using immediately
- **High Quality Data**: Based on national weather services
- **Global Coverage**: Worldwide weather data
- **High Resolution**: 1-11 km resolution forecasts
- **Free for Non-Commercial**: Perfect for development and testing

### Security Considerations

- Server runs in isolated subprocess
- Input validation for all parameters
- Error handling prevents information leakage
- No sensitive data exposure

## Examples

### Python Client Usage

```python
import asyncio
from mcp_client.client import WeatherClient

async def main():
    client = WeatherClient()
    await client.start()

    # Get current weather
    weather = await client.get_current_weather("Bangkok, Thailand")
    print(weather)

    # Get forecast
    forecast = await client.get_weather_forecast("New York", days=5)
    print(forecast)

    await client.close()

asyncio.run(main())
```

### Flutter Usage

```dart
class WeatherWidget extends StatelessWidget {
  final WeatherData weather;

  const WeatherWidget({Key? key, required this.weather}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weather.location,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.thermostat),
                SizedBox(width: 8),
                Text('${weather.temperature} (feels like ${weather.feelsLike})'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.water_drop),
                SizedBox(width: 8),
                Text('Humidity: ${weather.humidity}'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.air),
                SizedBox(width: 8),
                Text('Wind: ${weather.windSpeed}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## Troubleshooting

### Common Issues

**Server won't start:**
- Check Python installation and dependencies
- Ensure no firewall blocking
- Verify Open-Meteo API accessibility

**Flutter integration fails:**
- Ensure Python is in system PATH
- Check subprocess permissions
- Verify server script path

**Weather data unavailable:**
- Check internet connection
- Verify location spelling
- Try different location format

### Debug Mode

Enable debug logging:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

```dart
import 'package:flutter/foundation.dart';
// Debug prints automatically work in debug mode
```

## Development

### Adding New Tools

1. Add tool definition in `weather.py`:

```python
@server.list_tools()
async def handle_list_tools() -> List[types.Tool]:
    return [
        # existing tools...
        types.Tool(
            name="new_tool",
            description="Description of new tool",
            inputSchema={
                "type": "object",
                "properties": {
                    "param": {"type": "string", "description": "Parameter description"}
                },
                "required": ["param"]
            }
        )
    ]
```

2. Implement tool handler:

```python
@server.call_tool()
async def handle_call_tool(name: str, arguments: Dict[str, Any]) -> List[types.TextContent]:
    if name == "new_tool":
        # Implementation here
        return [types.TextContent(type="text", text="Result")]
```

3. Add client method in Flutter service:

```dart
Future<String> callNewTool(String param) async {
    // Implementation here
}
```

### Testing

Run comprehensive tests:

```bash
python setup.py  # Includes test execution
python mcp-client/client.py test  # Direct test
```

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes following existing patterns
4. Add tests for new functionality
5. Submit pull request

## License

This project is open source and available under the MIT License.

## Resources

- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Open-Meteo API Documentation](https://open-meteo.com/)
- [Flutter Documentation](https://docs.flutter.dev/)

---

**Created by Tanathon Chanapha 6511454**