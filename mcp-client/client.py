#!/usr/bin/env python3
"""
MCP Client for Weather Server
Connects to weather MCP server and provides a simple interface
"""

import asyncio
import json
import subprocess
import sys
from typing import Any, Dict, List, Optional
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MCPClient:
    """MCP Client for communicating with MCP servers"""

    def __init__(self, server_path: str):
        self.server_path = server_path
        self.process = None
        self.request_id = 0

    async def start_server(self):
        """Start the MCP server process"""
        try:
            self.process = await asyncio.create_subprocess_exec(
                sys.executable, self.server_path,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            logger.info(f"Started MCP server: {self.server_path}")

            # Send initialization request
            await self.initialize()

        except Exception as e:
            logger.error(f"Failed to start server: {e}")
            raise

    async def initialize(self):
        """Initialize the MCP connection"""
        init_request = {
            "jsonrpc": "2.0",
            "id": self._get_request_id(),
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {}
                },
                "clientInfo": {
                    "name": "weather-client",
                    "version": "1.0.0"
                }
            }
        }

        response = await self._send_request(init_request)
        logger.info("MCP client initialized")

        # Send initialized notification
        initialized_notification = {
            "jsonrpc": "2.0",
            "method": "notifications/initialized"
        }

        await self._send_notification(initialized_notification)

    async def list_tools(self) -> List[Dict[str, Any]]:
        """List available tools from the server"""
        request = {
            "jsonrpc": "2.0",
            "id": self._get_request_id(),
            "method": "tools/list"
        }

        response = await self._send_request(request)
        return response.get("result", {}).get("tools", [])

    async def call_tool(self, name: str, arguments: Dict[str, Any]) -> Any:
        """Call a tool on the server"""
        request = {
            "jsonrpc": "2.0",
            "id": self._get_request_id(),
            "method": "tools/call",
            "params": {
                "name": name,
                "arguments": arguments
            }
        }

        response = await self._send_request(request)
        return response.get("result")

    async def _send_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Send a request to the server and wait for response"""
        if not self.process:
            raise RuntimeError("Server not started")

        # Send request
        request_json = json.dumps(request) + "\n"
        self.process.stdin.write(request_json.encode())
        await self.process.stdin.drain()

        # Read response
        response_line = await self.process.stdout.readline()
        if not response_line:
            raise RuntimeError("Server closed connection")

        try:
            response = json.loads(response_line.decode().strip())

            if "error" in response:
                raise RuntimeError(f"Server error: {response['error']}")

            return response
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON response: {response_line}")
            raise RuntimeError(f"Invalid server response: {e}")

    async def _send_notification(self, notification: Dict[str, Any]):
        """Send a notification to the server (no response expected)"""
        if not self.process:
            raise RuntimeError("Server not started")

        notification_json = json.dumps(notification) + "\n"
        self.process.stdin.write(notification_json.encode())
        await self.process.stdin.drain()

    def _get_request_id(self) -> int:
        """Get next request ID"""
        self.request_id += 1
        return self.request_id

    async def close(self):
        """Close the connection and terminate the server"""
        if self.process:
            self.process.terminate()
            await self.process.wait()
            logger.info("MCP server terminated")

class WeatherClient:
    """High-level weather client using MCP"""

    def __init__(self, server_path: str = "../weather/weather.py"):
        self.client = MCPClient(server_path)

    async def start(self):
        """Start the weather client"""
        await self.client.start_server()

    async def get_current_weather(self, location: str) -> str:
        """Get current weather for a location"""
        try:
            result = await self.client.call_tool("get_current_weather", {"location": location})

            if result and "content" in result:
                return result["content"][0]["text"]
            else:
                return f"No weather data available for {location}"

        except Exception as e:
            return f"Error getting weather for {location}: {str(e)}"

    async def get_weather_forecast(self, location: str, days: int = 7) -> str:
        """Get weather forecast for a location"""
        try:
            result = await self.client.call_tool("get_weather_forecast", {
                "location": location,
                "days": days
            })

            if result and "content" in result:
                return result["content"][0]["text"]
            else:
                return f"No forecast data available for {location}"

        except Exception as e:
            return f"Error getting forecast for {location}: {str(e)}"

    async def search_location(self, location: str) -> str:
        """Search for location coordinates"""
        try:
            result = await self.client.call_tool("search_location", {"location": location})

            if result and "content" in result:
                return result["content"][0]["text"]
            else:
                return f"Location '{location}' not found"

        except Exception as e:
            return f"Error searching for {location}: {str(e)}"

    async def list_available_tools(self) -> List[str]:
        """List available weather tools"""
        try:
            tools = await self.client.list_tools()
            return [tool["name"] for tool in tools]
        except Exception as e:
            logger.error(f"Error listing tools: {e}")
            return []

    async def close(self):
        """Close the weather client"""
        await self.client.close()

async def interactive_demo():
    """Interactive demo of the weather client"""
    print("🌤️  Weather MCP Client Demo")
    print("=" * 40)

    # Initialize client
    client = WeatherClient()

    try:
        print("Starting weather server...")
        await client.start()

        print("✅ Connected to weather server!")

        # List available tools
        tools = await client.list_available_tools()
        print(f"Available tools: {', '.join(tools)}")
        print()

        while True:
            print("\nWeather Client Commands:")
            print("1. Get current weather")
            print("2. Get weather forecast")
            print("3. Search location")
            print("4. Exit")

            choice = input("\nEnter your choice (1-4): ").strip()

            if choice == "1":
                location = input("Enter location: ").strip()
                if location:
                    print("\nGetting current weather...")
                    weather = await client.get_current_weather(location)
                    print(weather)

            elif choice == "2":
                location = input("Enter location: ").strip()
                if location:
                    try:
                        days = int(input("Enter number of days (1-16, default 7): ").strip() or "7")
                        days = max(1, min(16, days))  # Clamp to valid range
                    except ValueError:
                        days = 7

                    print(f"\nGetting {days}-day forecast...")
                    forecast = await client.get_weather_forecast(location, days)
                    print(forecast)

            elif choice == "3":
                location = input("Enter location to search: ").strip()
                if location:
                    print("\nSearching location...")
                    result = await client.search_location(location)
                    print(result)

            elif choice == "4":
                print("Goodbye! 👋")
                break

            else:
                print("Invalid choice. Please try again.")

    except KeyboardInterrupt:
        print("\n\nShutting down...")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        await client.close()

async def test_client():
    """Test the weather client with example calls"""
    print("🧪 Testing Weather MCP Client")
    print("=" * 40)

    client = WeatherClient()

    try:
        print("Starting weather server...")
        await client.start()
        print("✅ Server started successfully!")

        # Test current weather
        print("\n📍 Testing current weather for Bangkok...")
        weather = await client.get_current_weather("Bangkok, Thailand")
        print(weather)

        # Test forecast
        print("\n📅 Testing 3-day forecast for New York...")
        forecast = await client.get_weather_forecast("New York", 3)
        print(forecast)

        # Test location search
        print("\n🔍 Testing location search for Tokyo...")
        location = await client.search_location("Tokyo")
        print(location)

        print("\n✅ All tests completed successfully!")

    except Exception as e:
        print(f"❌ Test failed: {e}")
    finally:
        await client.close()

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        # Run tests
        asyncio.run(test_client())
    else:
        # Run interactive demo
        asyncio.run(interactive_demo())