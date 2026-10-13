--[[
    Splitscreen Co-op Mod for Garry's Mod
    Shared Configuration & Constants
--]]

Splitscreen = Splitscreen or {}
Splitscreen.Version = "1.0.0"
Splitscreen.MaxSlots = 4

-- Viewport Layout Modes
Splitscreen.LAYOUT_HORIZONTAL   = 1 -- 2 Players: Top / Bottom
Splitscreen.LAYOUT_VERTICAL     = 2 -- 2 Players: Left / Right
Splitscreen.LAYOUT_3P_TOP       = 3 -- 3 Players: 2 Top / 1 Bottom Wide
Splitscreen.LAYOUT_3P_BOTTOM    = 4 -- 3 Players: 1 Top Wide / 2 Bottom
Splitscreen.LAYOUT_GRID         = 5 -- 4 Players: 2x2 Grid (Quad)

-- Slot Colors (Identity Badges & Physgun)
Splitscreen.SlotColors = {
    [1] = Color( 0, 160, 255, 255 ),   -- Cyan / Blue
    [2] = Color( 255, 130, 0, 255 ),   -- Orange
    [3] = Color( 46, 204, 113, 255 ),  -- Emerald Green
    [4] = Color( 175, 75, 255, 255 )   -- Purple
}

Splitscreen.SlotNames = {
    [1] = "Player 1",
    [2] = "Player 2",
    [3] = "Player 3",
    [4] = "Player 4"
}

-- XInput Button Constants (standard Microsoft XInput bitmasks)
Splitscreen.XINPUT_DPAD_UP         = 0x0001
Splitscreen.XINPUT_DPAD_DOWN       = 0x0002
Splitscreen.XINPUT_DPAD_LEFT       = 0x0004
Splitscreen.XINPUT_DPAD_RIGHT      = 0x0008
Splitscreen.XINPUT_START           = 0x0010
Splitscreen.XINPUT_BACK            = 0x0020
Splitscreen.XINPUT_LEFT_THUMB      = 0x0040 -- L3 / Left Stick Click
Splitscreen.XINPUT_RIGHT_THUMB     = 0x0080 -- R3 / Right Stick Click
Splitscreen.XINPUT_LEFT_SHOULDER   = 0x0100 -- LB
Splitscreen.XINPUT_RIGHT_SHOULDER  = 0x0200 -- RB
Splitscreen.XINPUT_A               = 0x1000 -- A
Splitscreen.XINPUT_B               = 0x2000 -- B
Splitscreen.XINPUT_X               = 0x4000 -- X
Splitscreen.XINPUT_Y               = 0x8000 -- Y

-- Standard Playermodels
Splitscreen.PlayerModels = {
    { name = "Male 07 (Citizen)",   model = "models/player/group01/male_07.mdl" },
    { name = "Male 09 (Citizen)",   model = "models/player/group01/male_09.mdl" },
    { name = "Female 02 (Citizen)", model = "models/player/group01/female_02.mdl" },
    { name = "Rebel Male 07",       model = "models/player/group03/male_07.mdl" },
    { name = "Rebel Female 01",     model = "models/player/group03/female_01.mdl" },
    { name = "Medic Male 03",       model = "models/player/group03m/male_03.mdl" },
    { name = "Combine Soldier",     model = "models/player/combine_soldier.mdl" },
    { name = "Combine Prison",      model = "models/player/combine_soldier_prisonguard.mdl" },
    { name = "Combine Elite",       model = "models/player/combine_super_soldier.mdl" },
    { name = "Metrocop (Police)",   model = "models/player/police.mdl" },
    { name = "Barney",              model = "models/player/barney.mdl" },
    { name = "Alyx",                model = "models/player/alyx.mdl" },
    { name = "Dr. Kleiner",         model = "models/player/kleiner.mdl" },
    { name = "Dr. Eli",             model = "models/player/eli.mdl" },
    { name = "G-Man",               model = "models/player/gman_high.mdl" },
    { name = "Chell",               model = "models/player/chell.mdl" },
    { name = "Zombie",              model = "models/player/zombie_classic.mdl" },
    { name = "Fast Zombie",         model = "models/player/zombie_fast.mdl" },
    { name = "Skeleton",            model = "models/player/skeleton.mdl" },
    { name = "Hostage",             model = "models/player/hostage/hostage_04.mdl" }
}

-- Default Sandbox Weapons for Splitscreen Players
Splitscreen.DefaultWeapons = {
    "weapon_crowbar",
    "weapon_physcannon",
    "weapon_physgun",
    "gmod_tool",
    "gmod_camera",
    "weapon_pistol",
    "weapon_357",
    "weapon_smg1",
    "weapon_ar2",
    "weapon_shotgun",
    "weapon_crossbow",
    "weapon_rpg",
    "weapon_frag",
    "weapon_slam"
}

-- Spawn Menu Categories & Catalog
Splitscreen.SpawnCatalog = {
    props = {
        name = "Props",
        icon = "icon16/box.png",
        items = {
            { name = "Wooden Crate",       model = "models/props_junk/wood_crate001a.mdl" },
            { name = "Metal Explosive",    model = "models/props_c17/oildrum001_explosive.mdl" },
            { name = "Blast Door",         model = "models/props_lab/blastdoor001c.mdl" },
            { name = "Steel Plate 4x4",    model = "models/hunter/plates/plate2x2.mdl" },
            { name = "Steel Plate 8x8",    model = "models/hunter/plates/plate4x4.mdl" },
            { name = "Concrete Block",     model = "models/props_debris/concrete_block001a.mdl" },
            { name = "Plastic Barrel",     model = "models/props_borealis/bluebarrel001.mdl" },
            { name = "Office Chair",       model = "models/props_c17/FurnitureChair001a.mdl" },
            { name = "Couch",              model = "models/props_c17/FurnitureCouch001a.mdl" },
            { name = "Traffic Cone",       model = "models/props_junk/TrafficCone001a.mdl" },
            { name = "Watermelon",         model = "models/props_junk/watermelon01.mdl" },
            { name = "Car Chassis",        model = "models/props_vehicles/car002b.mdl" }
        }
    },
    weapons = {
        name = "Weapons",
        icon = "icon16/bomb.png",
        items = {
            { name = "Physics Gun",        class = "weapon_physgun" },
            { name = "Tool Gun",           class = "gmod_tool" },
            { name = "Gravity Gun",        class = "weapon_physcannon" },
            { name = "Crowbar",            class = "weapon_crowbar" },
            { name = "9mm Pistol",         class = "weapon_pistol" },
            { name = ".357 Magnum",        class = "weapon_357" },
            { name = "SMG1",               class = "weapon_smg1" },
            { name = "Shotgun",            class = "weapon_shotgun" },
            { name = "Pulse Rifle AR2",    class = "weapon_ar2" },
            { name = "Crossbow",           class = "weapon_crossbow" },
            { name = "RPG Rocket Launcher",class = "weapon_rpg" },
            { name = "Frag Grenade",       class = "weapon_frag" },
            { name = "SLAM Mine",          class = "weapon_slam" }
        }
    },
    npcs = {
        name = "NPCs",
        icon = "icon16/user.png",
        items = {
            { name = "Rebel Fighter",      class = "npc_citizen", weapon = "weapon_smg1" },
            { name = "Combine Soldier",    class = "npc_combine_s", weapon = "weapon_ar2" },
            { name = "Metrocop",           class = "npc_metropolice", weapon = "weapon_pistol" },
            { name = "Zombie",             class = "npc_zombie" },
            { name = "Fast Zombie",        class = "npc_fastzombie" },
            { name = "Headcrab",           class = "npc_headcrab" },
            { name = "Antlion",            class = "npc_antlion" },
            { name = "G-Man",              class = "npc_gman" },
            { name = "Dr. Kleiner",        class = "npc_kleiner" },
            { name = "Alyx Vance",         class = "npc_alyx", weapon = "weapon_smg1" }
        }
    },
    vehicles = {
        name = "Vehicles",
        icon = "icon16/car.png",
        items = {
            { name = "Airboat",            script = "scripts/vehicles/airboat.txt", model = "models/airboat.mdl" },
            { name = "Jeep",               script = "scripts/vehicles/jeep.txt",    model = "models/buggy.mdl" },
            { name = "Pod / Seat",         script = "scripts/vehicles/pod.txt",     model = "models/vehicles/prisoner_pod_inner.mdl" }
        }
    },
    entities = {
        name = "Entities",
        icon = "icon16/cog.png",
        items = {
            { name = "Bouncy Ball",        class = "sent_ball" },
            { name = "Light / Lamp",       class = "gmod_light" },
            { name = "Wheel",              class = "gmod_wheel" },
            { name = "Thruster",           class = "gmod_thruster" },
            { name = "Button",             class = "gmod_button" }
        }
    },
    tools = {
        name = "Tools",
        icon = "icon16/wrench.png",
        items = {
            { name = "Remover",            mode = "remover" },
            { name = "Weld",               mode = "weld" },
            { name = "Rope",               mode = "rope" },
            { name = "Elastic",            mode = "elastic" },
            { name = "No-Collide",         mode = "nocollide" },
            { name = "Color",              mode = "colour" },
            { name = "Material",           mode = "material" },
            { name = "Wheel",              mode = "wheel" },
            { name = "Thruster",           mode = "thruster" },
            { name = "Axis",               mode = "axis" }
        }
    }
}

-- Default Configuration Table
function Splitscreen.GetDefaultConfig()
    return {
        enabled = false,
        player_count = 2,
        layout = Splitscreen.LAYOUT_HORIZONTAL,
        p1_use_gamepad = false, -- If true, P1 uses Gamepad 0. If false, P1 uses KBM and P2 uses Gamepad 0.
        deadzone = 0.18,
        look_sensitivity_x = 2.5,
        look_sensitivity_y = 2.0,
        invert_y = false,
        thirdperson = { [1] = false, [2] = false, [3] = false, [4] = false },
        slots = {
            [1] = { active = true,  name = "Player 1", model = "models/player/group01/male_07.mdl", color = Vector( 0.0, 0.6, 1.0 ) },
            [2] = { active = true,  name = "Player 2", model = "models/player/group01/male_09.mdl", color = Vector( 1.0, 0.5, 0.0 ) },
            [3] = { active = false, name = "Player 3", model = "models/player/combine_soldier.mdl", color = Vector( 0.2, 0.8, 0.4 ) },
            [4] = { active = false, name = "Player 4", model = "models/player/police.mdl",          color = Vector( 0.7, 0.3, 1.0 ) }
        }
    }
end

-- Save Configuration to JSON
function Splitscreen.SaveConfig( tbl )
    local json = util.TableToJSON( tbl, true )
    if ( not json ) then return false end
    file.Write( "splitscreen_config.json", json )
    return true
end

-- Load Configuration from JSON
function Splitscreen.LoadConfig()
    if ( not file.Exists( "splitscreen_config.json", "DATA" ) ) then
        local def = Splitscreen.GetDefaultConfig()
        Splitscreen.SaveConfig( def )
        return def
    end

    local raw = file.Read( "splitscreen_config.json", "DATA" )
    if ( not raw or raw == "" ) then
        return Splitscreen.GetDefaultConfig()
    end

    local tbl = util.JSONToTable( raw )
    if ( not tbl ) then
        return Splitscreen.GetDefaultConfig()
    end

    return tbl
end
