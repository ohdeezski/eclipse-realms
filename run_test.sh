#!/bin/bash
# Test script to run WebSocket connection test with Godot headless

set -e

PROJECT_DIR="/home/ssmartnycbase/Desktop/StreetSmartNYC-BusinessBase/Obsidian-Vault/game-projects-(to monetize)/project-eclipse-realms/client"
GODOT_BIN="godot"

# Check if godot is available
if ! command -v $GODOT_BIN &> /dev/null; then
    echo "Error: godot not found in PATH"
    exit 1
fi

echo "========================================"
echo "Eclipse Realms - WebSocket Connection Test"
echo "========================================"
echo "Project: $PROJECT_DIR"
echo ""

# Run the test in headless mode
cd "$PROJECT_DIR"
$GODOT_BIN --headless --script res://tests/test_websocket_connection.gd --test

echo ""
echo "Test completed."