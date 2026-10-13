# ==============================================================================
# Installer for 4-Player Splitscreen Co-op Mod for Garry's Mod
# ==============================================================================

[CmdletBinding()]
param(
    [string]$GModPath = "Y:\SteamLibrary\steamapps\common\GarrysMod"
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  GARRY'S MOD 4-PLAYER SPLITSCREEN CO-OP MOD INSTALLER    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Verify Garry's Mod Path
if (-not (Test-Path $GModPath)) {
    Write-Host "Auto-detecting Garry's Mod from Steam..." -ForegroundColor Yellow
    $steamPath = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -Name "SteamPath" -ErrorAction SilentlyContinue).SteamPath
    if ($steamPath) {
        $candidate = Join-Path $steamPath "steamapps\common\GarrysMod"
        if (Test-Path $candidate) {
            $GModPath = $candidate
        }
    }
}

if (-not (Test-Path $GModPath)) {
    Write-Error "Could not locate Garry's Mod installation at: $GModPath"
    exit 1
}

Write-Host "[+] Found Garry's Mod directory at: $GModPath" -ForegroundColor Green

$projectRoot = $PSScriptRoot
$garrysmodSubdir = Join-Path $GModPath "garrysmod"
$addonsTarget    = Join-Path $garrysmodSubdir "addons\splitscreen"
$binTarget       = Join-Path $garrysmodSubdir "lua\bin"
$menuTarget      = Join-Path $garrysmodSubdir "lua\menu"
$dataTarget      = Join-Path $garrysmodSubdir "data"

# 2. Install Addon
Write-Host "[+] Installing Addon files to $addonsTarget..." -ForegroundColor Cyan
if (Test-Path $addonsTarget) {
    Remove-Item -Recurse -Force $addonsTarget -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Force -Path $addonsTarget | Out-Null
Copy-Item -Recurse -Force "$projectRoot\addon\*" $addonsTarget
Write-Host "    Addon files successfully installed!" -ForegroundColor Green

# 3. Install XInput Binary Modules
Write-Host "[+] Installing XInput binaries to $binTarget..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $binTarget | Out-Null
$dlls = @(
    "gmcl_xinput_win64.dll",
    "gmcl_xinput_win32.dll"
)
foreach ($dll in $dlls) {
    $src = Join-Path "$projectRoot\bin" $dll
    if (Test-Path $src) {
        Copy-Item -Force $src (Join-Path $binTarget $dll)
        # Also copy compatibility variations
        $alias = $dll -replace "^gmcl_", "gm_"
        Copy-Item -Force $src (Join-Path $binTarget $alias)
        $menuAlias = $dll -replace "^gmcl_", "gm_xinput_menu_"
        Copy-Item -Force $src (Join-Path $binTarget $menuAlias)
    }
}
Write-Host "    XInput binaries installed (win64 & win32)!" -ForegroundColor Green

# 4. Install Main Menu Integration
Write-Host "[+] Installing Main Menu console lobby..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $menuTarget | Out-Null
Copy-Item -Force "$projectRoot\menu_integration\splitscreen_mainmenu.lua" (Join-Path $menuTarget "splitscreen_mainmenu.lua")

$menuLuaFile = Join-Path $menuTarget "menu.lua"
if (Test-Path $menuLuaFile) {
    $menuContent = Get-Content $menuLuaFile -Raw
    if ($menuContent -notmatch "splitscreen_mainmenu\.lua") {
        Write-Host "    Hooking splitscreen_mainmenu.lua into menu.lua..." -ForegroundColor Cyan
        Add-Content -Path $menuLuaFile -Value "`ninclude( `"splitscreen_mainmenu.lua`" )`n"
    }
}
Write-Host "    Main Menu console lobby installed!" -ForegroundColor Green

# 5. Default Configuration File
New-Item -ItemType Directory -Force -Path $dataTarget | Out-Null
$cfgFile = Join-Path $dataTarget "splitscreen_config.json"
if (-not (Test-Path $cfgFile)) {
    $defaultConfig = @"
{
    "enabled": true,
    "player_count": 2,
    "layout": 1,
    "p1_use_gamepad": false,
    "deadzone": 0.18,
    "look_sensitivity_x": 2.5,
    "look_sensitivity_y": 2.0,
    "invert_y": false,
    "slots": {
        "1": { "active": true, "name": "Player 1", "model": "models/player/group01/male_07.mdl", "color": [0.0, 0.6, 1.0] },
        "2": { "active": true, "name": "Player 2", "model": "models/player/group01/male_09.mdl", "color": [1.0, 0.5, 0.0] },
        "3": { "active": false, "name": "Player 3", "model": "models/player/combine_soldier.mdl", "color": [0.2, 0.8, 0.4] },
        "4": { "active": false, "name": "Player 4", "model": "models/player/police.mdl", "color": [0.7, 0.3, 1.0] }
    }
}
"@
    Set-Content -Path $cfgFile -Value $defaultConfig -Encoding UTF8
    Write-Host "    Created default data/splitscreen_config.json!" -ForegroundColor Green
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "  INSTALLATION COMPLETED SUCCESSFULLY!                    " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "How to use:" -ForegroundColor Yellow
Write-Host "1. Launch Garry's Mod." -ForegroundColor White
Write-Host "2. On the Main Menu, click the 'SPLITSCREEN CO-OP' button in the top right." -ForegroundColor White
Write-Host "3. Pick 2, 3, or 4 players, plug in your controllers, customize playermodels, and click 'START SPLITSCREEN MATCH'!" -ForegroundColor White
Write-Host "4. Inside the game, each player has full controller support and can hold [BACK] to open their own Gamepad Spawn Menu!" -ForegroundColor White

