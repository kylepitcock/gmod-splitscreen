# 4-Player Splitscreen Co-op for Garry's Mod (Single Instance)

A complete local couch co-op modification for **Garry's Mod** that delivers native **4-player splitscreen multiplayer in a single game instance**, featuring full independent controller support, console-style main menu configuration, and 100% gameplay parity across all players (including spawn menus, physics gun, tool gun, weapons, and undo).

---

## 🎮 Highlights & Key Features

* **True Single-Instance Couch Co-op**:
  * Runs entirely within **one instance of `gmod.exe`**.
  * No external tools (Nucleus Co-op, Universal Split Screen), no multiple window instances, and no sandboxing required.
* **Console-Style Main Menu Integration**:
  * Dedicated **"🎮 SPLITSCREEN CO-OP"** button added directly to Garry's Mod's Main Menu.
  * Real-time lobby screen with 4 player cards, interactive 3D playermodel preview, color picker, map selector, and controller auto-detection.
  * Launches into local multiplayer with 1 click.
* **Independent 4-Controller Support**:
  * Direct integration with Microsoft **XInput** (`gmcl_xinput_win64.dll` & `win32`).
  * Up to 4 controllers simultaneously without input bleeding, trigger merging, or axis conflicts.
  * Support for Player 1 playing on Keyboard & Mouse while Players 2–4 use Gamepads 1–3, or all 4 players using Gamepads 0–3.
  * Radial stick deadzone calibration and look sensitivity controls to eliminate drift.
* **Equal Gameplay Abilities & Gamepad Spawn Menus**:
  * Every player has their own independent **Gamepad Spawn Menu** accessible by holding `[BACK]` / `[VIEW]`.
  * Spawns props, weapons, NPCs, vehicles, entities, and toolgun tools into their own viewports without blocking or pausing other players.
  * Full server-side **Undo** (`[X]` or `D-Pad Left`) and **Cleanup** support for each player.
  * Full Physics Gun (`weapon_physgun`) and Tool Gun (`gmod_tool`) functionality for all players.
* **Flexible Screen Split Layouts**:
  * **2 Players**: Horizontal (Top / Bottom) or Vertical (Left / Right).
  * **3 Players**: 3-Way Top or 3-Way Bottom wide layout.
  * **4 Players**: 2x2 Quadrant Grid.
* **Dynamic Independent HUDs**:
  * Individual frosted-glass HUD cards rendered inside each player's viewport showing HP, Armor, Ammo, active weapon, crosshair, and player identity badges.
* **Drop-in / Drop-out Co-op**:
  * Any player can pick up a controller and press `[A]` or `[START]` to join dynamically during gameplay.

---

## 📁 Project Architecture

```
gmod splitscreen/
├── bin/                                                # Pre-compiled XInput binary modules
│   ├── gmcl_xinput_win64.dll                           # 64-bit client binary module
│   └── gmcl_xinput_win32.dll                           # 32-bit client binary module
├── addon/                                              # Garry's Mod addon directory
│   ├── addon.json
│   └── lua/
│       ├── autorun/
│       │   ├── splitscreen_init.lua                    # Shared autorun entrypoint
│       │   ├── client/
│       │   │   └── cl_splitscreen_loader.lua           # Client-side module loader
│       │   └── server/
│       │       └── sv_splitscreen_loader.lua           # Server-side module loader
│       └── splitscreen/
│           ├── shared/
│           │   └── sh_config.lua                       # Constants, layouts, models, catalog
│           ├── client/
│           │   ├── cl_input.lua                        # Multi-controller polling & deadzone
│           │   ├── cl_render.lua                       # 4-player viewport renderer & cameras
│           │   ├── cl_hud.lua                          # Dynamic per-viewport HUDs
│           │   ├── cl_spawnmenu.lua                    # Gamepad radial & category spawn menu
│           │   ├── cl_weaponwheel.lua                  # Gamepad radial weapon wheel
│           │   └── cl_lobby.lua                        # In-game pause & manager menu
│           └── server/
│               ├── sv_manager.lua                      # Bot player lifecycle & loadouts
│               ├── sv_commands.lua                     # GM:StartCommand authoritative injection
│               └── sv_spawner.lua                      # Authoritative prop/SWEP/NPC/undo spawner
├── menu_integration/
│   └── splitscreen_mainmenu.lua                        # Main Menu console lobby (menu realm)
├── Install-SplitscreenMod.ps1                          # Automated one-click installer
└── Uninstall-SplitscreenMod.ps1                        # Automated uninstaller
```

---

## 🕹️ Controller Layout (Default Gamepad Preset)

| Button / Control | In-Game Action | Spawn Menu Action |
| :--- | :--- | :--- |
| **Left Thumbstick** | Move forward / back / strafe | Navigate Item Grid |
| **Right Thumbstick** | Aim / Look (Pitch & Yaw) | Navigate Item Grid |
| **A Button** | Jump (`IN_JUMP`) | Spawn / Select Item |
| **B Button** | Crouch (`IN_DUCK`) | Close Spawn Menu |
| **X Button** | Use / Interact (`IN_USE`) / Reload (tap) | Undo Last Spawned Item |
| **Y Button** | Toggle Flashlight | Clean Up Player Props |
| **Right Trigger (RT)** | Primary Attack / Physgun Grab | Confirm Spawn |
| **Left Trigger (LT)** | Secondary Attack / Physgun Freeze | N/A |
| **Left Bumper (LB)** | Sprint (`IN_SPEED`) | Previous Category Tab |
| **Right Bumper (RB)** | Hold for Weapon Wheel | Next Category Tab |
| **Right Stick Click (R3)** | Toggle 1st Person / 3rd Person | N/A |
| **Left Stick Click (L3)** | Sprint Toggle | N/A |
| **D-Pad Up** | Toggle Noclip | Navigate Up |
| **D-Pad Down** | Toggle 1st / 3rd Person Camera | Navigate Down |
| **D-Pad Left** | Undo Last Spawned Item | Navigate Left |
| **D-Pad Right** | Toggle Flashlight | Navigate Right |
| **Back / View** | **Hold for Gamepad Spawn Menu** | Close Menu |
| **Start / Menu** | In-Game Splitscreen Manager Menu | Close Menu |

---

## 🚀 Installation & Setup

### Automated Installation (Already applied to your local GMod)

Run the included installer script in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\Install-SplitscreenMod.ps1
```

The script automatically:
1. Deploys the addon to `garrysmod/addons/splitscreen/`.
2. Installs the XInput 64-bit and 32-bit binary modules to `garrysmod/lua/bin/`.
3. Hooks the console lobby into `garrysmod/lua/menu/menu.lua`.
4. Creates the default configuration in `garrysmod/data/splitscreen_config.json`.

---

## 🎮 How to Play

1. **Launch Garry's Mod**.
2. On the **Main Menu**, click the green **"🎮 SPLITSCREEN CO-OP"** button in the upper right.
3. In the **Splitscreen Lobby**:
   * Connect your gamepads (Xbox, PlayStation, or generic controllers).
   * Controllers pressing `[A]` or `[START]` will claim slots 2, 3, or 4.
   * Pick your sandbox map (e.g., `gm_construct` or `gm_flatgrass`).
   * Select your preferred 2-player split (Horizontal or Vertical) or 4-player grid.
   * Customize each player's playermodel.
4. Click **"▶ START SPLITSCREEN MATCH"**.
5. All 4 players spawn in immediately with full sandbox loadouts, independent viewports, custom HUDs, and full controller functionality!

