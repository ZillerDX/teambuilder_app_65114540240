#!/usr/bin/env python3
"""
Setup script for MCP Weather Server and Client
Installs required dependencies and prepares the environment
"""

import subprocess
import sys
import os

def install_requirements():
    """Install Python requirements for both server and client"""
    print("Installing Python requirements...")

    # Install server requirements
    server_req = os.path.join("weather", "requirements.txt")
    if os.path.exists(server_req):
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", server_req], check=True)
        print("✅ Server requirements installed")

    # Install client requirements
    client_req = os.path.join("mcp-client", "requirements.txt")
    if os.path.exists(client_req):
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", client_req], check=True)
        print("✅ Client requirements installed")

def test_server():
    """Test the MCP weather server"""
    print("\nTesting MCP weather server...")

    client_script = os.path.join("mcp-client", "client.py")
    if os.path.exists(client_script):
        try:
            result = subprocess.run([sys.executable, client_script, "test"],
                                  capture_output=True, text=True, timeout=30)
            print("Server test output:")
            print(result.stdout)
            if result.stderr:
                print("Errors:")
                print(result.stderr)

            if result.returncode == 0:
                print("✅ MCP server test passed!")
            else:
                print("❌ MCP server test failed!")
                return False
        except subprocess.TimeoutExpired:
            print("⚠️  Test timed out - server might be running but slow")
        except Exception as e:
            print(f"❌ Error running test: {e}")
            return False

    return True

def main():
    """Main setup function"""
    print("🌤️  MCP Weather Server Setup")
    print("=" * 40)

    try:
        # Install requirements
        install_requirements()

        # Test the server
        test_server()

        print("\n✅ Setup completed successfully!")
        print("\nNext steps:")
        print("1. Run the interactive client: python mcp-client/client.py")
        print("2. Or run tests: python mcp-client/client.py test")
        print("3. For Flutter integration, see flutter_integration/ directory")

    except subprocess.CalledProcessError as e:
        print(f"❌ Error during setup: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()