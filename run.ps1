# Roblox UI to WebUI Engine Launcher for Windows PowerShell (AMD64 / ARM)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Starting Roblox UI to WebUI Engine (AMD64 / ARM) " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Node.js is not installed." -ForegroundColor Red
    Write-Host "Please download and install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path "node_modules")) {
    Write-Host "[INFO] Installing dependencies..." -ForegroundColor Yellow
    npm install
}

Write-Host "[INFO] Starting WebUI Server on http://localhost:3000..." -ForegroundColor Green
node src/server.js
