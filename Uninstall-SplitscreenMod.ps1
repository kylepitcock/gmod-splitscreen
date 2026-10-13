# ==============================================================================
# Uninstaller for 4-Player Splitscreen Co-op Mod for Garry's Mod
# ==============================================================================

[CmdletBinding()]
param(
    [string]$GModPath = "Y:\SteamLibrary\steamapps\common\GarrysMod"
)

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host "  GARRY'S MOD 4-PLAYER SPLITSCREEN CO-OP MOD UNINSTALLER  " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

$garrysmodSubdir = Join-Path $GModPath "garrysmod"
$addonsTarget    = Join-Path $garrysmodSubdir "addons\splitscreen"
$menuTarget      = Join-Path $garrysmodSubdir "lua\menu"
$menuLuaFile     = Join-Path $menuTarget "menu.lua"
$customMenuFile  = Join-Path $menuTarget "splitscreen_mainmenu.lua"

# 1. Remove Addon
if (Test-Path $addonsTarget) {
    Remove-Item -Recurse -Force $addonsTarget
    Write-Host "[+] Removed addon folder: $addonsTarget" -ForegroundColor Green
}

# 2. Remove Menu Script
if (Test-Path $customMenuFile) {
    Remove-Item -Force $customMenuFile
    Write-Host "[+] Removed menu integration: $customMenuFile" -ForegroundColor Green
}

# 3. Clean up menu.lua include
if (Test-Path $menuLuaFile) {
    $content = Get-Content $menuLuaFile -Raw
    $cleaned = $content -replace "(?m)^\s*include\(\s*[`"']splitscreen_mainmenu\.lua[`"']\s*\)\s*$", ""
    Set-Content -Path $menuLuaFile -Value $cleaned.Trim() -Encoding UTF8
    Write-Host "[+] Cleaned up menu.lua" -ForegroundColor Green
}

Write-Host "[+] Uninstallation completed." -ForegroundColor Green
