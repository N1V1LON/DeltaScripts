#!/usr/bin/env bash
# Roblox UI to WebUI Engine Launcher for Linux (Ubuntu / Termux / Android) and macOS (AMD64 / ARM)

set -e

echo "=========================================================="
echo " Starting Roblox UI to WebUI Engine (AMD64 / ARM) "
echo "=========================================================="

if ! command -v node &> /dev/null; then
    echo "[ERROR] Node.js is not installed."
    echo "Please install Node.js using your package manager:"
    echo "  Ubuntu/Debian: sudo apt install nodejs npm"
    echo "  Termux (Android): pkg install nodejs"
    exit 1
fi

if [ ! -d "node_modules" ]; then
    echo "[INFO] Installing dependencies..."
    npm install
fi

echo "[INFO] Starting WebUI Server on http://localhost:3000..."
node src/server.js
