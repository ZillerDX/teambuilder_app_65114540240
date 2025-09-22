#!/usr/bin/env python3
"""
Weather MCP Server using Open-Meteo API
Provides weather information through MCP protocol
No API key required - uses free Open-Meteo service
"""

import asyncio
import json
import sys
from typing import Any, Dict, List
import aiohttp
from mcp.server import Server
from mcp.server.models import InitializationOptions
import mcp.server.stdio
import mcp.types as types

# Initialize MCP server
server = Server("weather-server")

class WeatherService:
    """Weather service using Open-Meteo API"""

    BASE_URL = "https://api.open-meteo.com/v1/forecast"
    GEOCODING_URL = "https://geocoding-api.open-meteo.com/v1/search"

    async def get_coordinates(self, location: str) -> Dict[str, float]:
        """Get latitude and longitude for a location"""
        async with aiohttp.ClientSession() as session:
            params = {
                "name": location,
                "count": 1,
                "language": "en",
                "format": "json"
            }

            async with session.get(self.GEOCODING_URL, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    if data.get("results"):
                        result = data["results"][0]
                        return {
                            "latitude": result["latitude"],
                            "longitude": result["longitude"],
                            "name": result.get("name", location),
                            "country": result.get("country", "")
                        }
                raise ValueError(f"Location '{location}' not found")

    async def get_current_weather(self, latitude: float, longitude: float) -> Dict[str, Any]:
        """Get current weather for coordinates"""
        async with aiohttp.ClientSession() as session:
            params = {
                "latitude": latitude,
                "longitude": longitude,
                "current": "temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,showers,snowfall,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m",
                "timezone": "auto"
            }

            async with session.get(self.BASE_URL, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    return data
                raise ValueError(f"Failed to fetch weather data: {response.status}")

    async def get_forecast(self, latitude: float, longitude: float, days: int = 7) -> Dict[str, Any]:
        """Get weather forecast for coordinates"""
        async with aiohttp.ClientSession() as session:
            params = {
                "latitude": latitude,
                "longitude": longitude,
                "daily": "weather_code,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,precipitation_sum,rain_sum,showers_sum,snowfall_sum,precipitation_hours,wind_speed_10m_max,wind_gusts_10m_max,wind_direction_10m_dominant",
                "timezone": "auto",
                "forecast_days": min(days, 16)  # Open-Meteo supports up to 16 days
            }

            async with session.get(self.BASE_URL, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    return data
                raise ValueError(f"Failed to fetch forecast data: {response.status}")

# Initialize weather service
weather_service = WeatherService()

@server.list_tools()
async def handle_list_tools() -> List[types.Tool]:
    """List available weather tools"""
    return [
        types.Tool(
            name="get_current_weather",
            description="Get current weather conditions for a location",
            inputSchema={
                "type": "object",
                "properties": {
                    "location": {
                        "type": "string",
                        "description": "City name, e.g., 'Bangkok, Thailand' or 'New York'"
                    }
                },
                "required": ["location"]
            }
        ),
        types.Tool(
            name="get_weather_forecast",
            description="Get weather forecast for a location",
            inputSchema={
                "type": "object",
                "properties": {
                    "location": {
                        "type": "string",
                        "description": "City name, e.g., 'Bangkok, Thailand' or 'New York'"
                    },
                    "days": {
                        "type": "integer",
                        "description": "Number of forecast days (1-16)",
                        "default": 7,
                        "minimum": 1,
                        "maximum": 16
                    }
                },
                "required": ["location"]
            }
        ),
        types.Tool(
            name="search_location",
            description="Search for location coordinates",
            inputSchema={
                "type": "object",
                "properties": {
                    "location": {
                        "type": "string",
                        "description": "Location name to search for"
                    }
                },
                "required": ["location"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: Dict[str, Any]) -> List[types.TextContent]:
    """Handle tool calls"""

    if name == "get_current_weather":
        location = arguments.get("location")
        if not location:
            return [types.TextContent(type="text", text="Error: Location is required")]

        try:
            # Get coordinates for location
            coords = await weather_service.get_coordinates(location)

            # Get current weather
            weather_data = await weather_service.get_current_weather(
                coords["latitude"], coords["longitude"]
            )

            current = weather_data["current"]
            current_units = weather_data["current_units"]

            # Format weather response
            result = {
                "location": f"{coords['name']}, {coords['country']}",
                "coordinates": {
                    "latitude": coords["latitude"],
                    "longitude": coords["longitude"]
                },
                "current_weather": {
                    "time": current["time"],
                    "temperature": f"{current['temperature_2m']}{current_units['temperature_2m']}",
                    "feels_like": f"{current['apparent_temperature']}{current_units['apparent_temperature']}",
                    "humidity": f"{current['relative_humidity_2m']}{current_units['relative_humidity_2m']}",
                    "precipitation": f"{current['precipitation']}{current_units['precipitation']}",
                    "wind_speed": f"{current['wind_speed_10m']}{current_units['wind_speed_10m']}",
                    "wind_direction": f"{current['wind_direction_10m']}{current_units['wind_direction_10m']}",
                    "pressure": f"{current['pressure_msl']}{current_units['pressure_msl']}",
                    "cloud_cover": f"{current['cloud_cover']}{current_units['cloud_cover']}",
                    "is_day": "Day" if current["is_day"] else "Night"
                }
            }

            return [types.TextContent(
                type="text",
                text=f"Current weather for {result['location']}:\n" +
                     f"Temperature: {result['current_weather']['temperature']} (feels like {result['current_weather']['feels_like']})\n" +
                     f"Humidity: {result['current_weather']['humidity']}\n" +
                     f"Wind: {result['current_weather']['wind_speed']} at {result['current_weather']['wind_direction']}°\n" +
                     f"Pressure: {result['current_weather']['pressure']}\n" +
                     f"Cloud Cover: {result['current_weather']['cloud_cover']}\n" +
                     f"Precipitation: {result['current_weather']['precipitation']}\n" +
                     f"Time of Day: {result['current_weather']['is_day']}\n\n" +
                     f"Data from Open-Meteo API"
            )]

        except Exception as e:
            return [types.TextContent(type="text", text=f"Error getting weather: {str(e)}")]

    elif name == "get_weather_forecast":
        location = arguments.get("location")
        days = arguments.get("days", 7)

        if not location:
            return [types.TextContent(type="text", text="Error: Location is required")]

        try:
            # Get coordinates for location
            coords = await weather_service.get_coordinates(location)

            # Get forecast
            forecast_data = await weather_service.get_forecast(
                coords["latitude"], coords["longitude"], days
            )

            daily = forecast_data["daily"]
            daily_units = forecast_data["daily_units"]

            # Format forecast response
            forecast_text = f"Weather forecast for {coords['name']}, {coords['country']} ({days} days):\n\n"

            for i in range(len(daily["time"])):
                date = daily["time"][i]
                max_temp = daily["temperature_2m_max"][i]
                min_temp = daily["temperature_2m_min"][i]
                precipitation = daily["precipitation_sum"][i]
                wind_speed = daily["wind_speed_10m_max"][i]

                forecast_text += f"📅 {date}:\n"
                forecast_text += f"  🌡️  High: {max_temp}{daily_units['temperature_2m_max']}, Low: {min_temp}{daily_units['temperature_2m_min']}\n"
                forecast_text += f"  🌧️  Precipitation: {precipitation}{daily_units['precipitation_sum']}\n"
                forecast_text += f"  💨 Max Wind: {wind_speed}{daily_units['wind_speed_10m_max']}\n\n"

            forecast_text += "Data from Open-Meteo API"

            return [types.TextContent(type="text", text=forecast_text)]

        except Exception as e:
            return [types.TextContent(type="text", text=f"Error getting forecast: {str(e)}")]

    elif name == "search_location":
        location = arguments.get("location")
        if not location:
            return [types.TextContent(type="text", text="Error: Location is required")]

        try:
            coords = await weather_service.get_coordinates(location)
            result_text = f"Location: {coords['name']}, {coords['country']}\n"
            result_text += f"Coordinates: {coords['latitude']}, {coords['longitude']}"

            return [types.TextContent(type="text", text=result_text)]

        except Exception as e:
            return [types.TextContent(type="text", text=f"Error searching location: {str(e)}")]

    else:
        return [types.TextContent(type="text", text=f"Unknown tool: {name}")]

async def main():
    """Main server function"""
    # Run the server using stdio
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="weather-server",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=None,
                    experimental_capabilities=None,
                ),
            ),
        )

if __name__ == "__main__":
    asyncio.run(main())