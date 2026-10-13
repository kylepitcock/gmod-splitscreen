--[[
    Splitscreen Co-op Mod for Garry's Mod
    Server Manager (Bot Lifecycle, Drop-in/Drop-out, Sync & Loadout)
--]]

Splitscreen = Splitscreen or {}
Splitscreen.Bots = {}

-- Register Network Strings
util.AddNetworkString( "Splitscreen_Input" )
util.AddNetworkString( "Splitscreen_Spawn" )
util.AddNetworkString( "Splitscreen_SyncState" )
util.AddNetworkString( "Splitscreen_DropIn" )
util.AddNetworkString( "Splitscreen_Feedback" )

-- Broadcast Active Slots to Clients
function Splitscreen.BroadcastSyncState()
    local activeSlots = { 1 } -- Slot 1 is always active (LocalPlayer / Host)
    for slot = 2, Splitscreen.MaxSlots do
        if ( IsValid( Splitscreen.Bots[slot] ) ) then
            table.insert( activeSlots, slot )
        end
    end

    local cfg = Splitscreen.LoadConfig()
    net.Start( "Splitscreen_SyncState" )
        net.WriteUInt( #activeSlots, 3 )
        for _, slot in ipairs( activeSlots ) do
            net.WriteUInt( slot, 3 )
        end
        net.WriteUInt( cfg.layout or Splitscreen.LAYOUT_GRID, 3 )
    net.Broadcast()
end

-- Give Full Sandbox Loadout to Player / Bot
function Splitscreen.EquipLoadout( ply, slot )
    if ( not IsValid( ply ) ) then return end

    -- Give standard sandbox weapons
    for _, wep in ipairs( Splitscreen.DefaultWeapons ) do
        if ( not ply:HasWeapon( wep ) ) then
            ply:Give( wep )
        end
    end

    -- Maximize ammo for all primary & secondary weapons
    ply:GiveAmmo( 255, "Pistol", true )
    ply:GiveAmmo( 255, "357", true )
    ply:GiveAmmo( 255, "SMG1", true )
    ply:GiveAmmo( 5,   "SMG1_Grenade", true )
    ply:GiveAmmo( 255, "AR2", true )
    ply:GiveAmmo( 3,   "AR2AltFire", true )
    ply:GiveAmmo( 64,  "Buckshot", true )
    ply:GiveAmmo( 32,  "XBowBolt", true )
    ply:GiveAmmo( 6,   "RPG_Round", true )
    ply:GiveAmmo( 5,   "Grenade", true )
    ply:GiveAmmo( 6,   "slam", true )

    -- Select Physics Gun as default initial weapon
    timer.Simple( 0.2, function()
        if ( IsValid( ply ) ) then
            ply:SelectWeapon( "weapon_physgun" )
        end
    end )
end

-- Spawn a Splitscreen Bot for a given slot
function Splitscreen.SpawnBotForSlot( slot )
    if ( slot < 2 or slot > Splitscreen.MaxSlots ) then return nil end
    if ( IsValid( Splitscreen.Bots[slot] ) ) then return Splitscreen.Bots[slot] end

    local cfg = Splitscreen.LoadConfig()
    local slotData = cfg.slots[slot] or {}
    local botNick = slotData.name or ( "Player " .. slot )

    local bot = player.CreateNextBot( botNick )
    if ( not IsValid( bot ) ) then
        print( "[Splitscreen Co-op] Warning: Failed to create nextbot for Slot " .. slot .. ". Ensure maxplayers >= " .. slot )
        return nil
    end

    bot:SetNWInt( "SplitscreenSlot", slot )
    Splitscreen.Bots[slot] = bot

    -- Set Playermodel & Colors
    local mdl = slotData.model or "models/player/group01/male_07.mdl"
    bot:SetModel( mdl )

    local plyCol = slotData.color or Vector( 1, 0.5, 0 )
    bot:SetPlayerColor( plyCol )

    local slotColor = Splitscreen.SlotColors[slot]
    if ( slotColor ) then
        bot:SetWeaponColor( Vector( slotColor.r / 255, slotColor.g / 255, slotColor.b / 255 ) )
    end

    -- Equip Weapons
    Splitscreen.EquipLoadout( bot, slot )

    print( "[Splitscreen Co-op] Successfully created Splitscreen Player for Slot " .. slot .. " (" .. bot:Nick() .. ")" )
    Splitscreen.BroadcastSyncState()

    return bot
end

-- Remove / Kick a Splitscreen Bot
function Splitscreen.RemoveBotForSlot( slot )
    local bot = Splitscreen.Bots[slot]
    if ( IsValid( bot ) ) then
        bot:Kick( "Splitscreen player dropped out." )
        Splitscreen.Bots[slot] = nil
        print( "[Splitscreen Co-op] Removed Splitscreen Player for Slot " .. slot )
        Splitscreen.BroadcastSyncState()
    end
end

-- Handle Drop-in / Drop-out Requests
net.Receive( "Splitscreen_DropIn", function( len, ply )
    local slot = net.ReadUInt( 3 )
    local join = net.ReadBool()

    if ( join ) then
        Splitscreen.SpawnBotForSlot( slot )
    else
        Splitscreen.RemoveBotForSlot( slot )
    end
end )

-- Auto-Respawn Bots on Death
hook.Add( "PlayerDeath", "Splitscreen_AutoRespawnBots", function( victim, inflictor, attacker )
    local slot = victim:GetNWInt( "SplitscreenSlot", 0 )
    if ( slot >= 2 and slot <= Splitscreen.MaxSlots ) then
        timer.Simple( 1.5, function()
            if ( IsValid( victim ) and not victim:Alive() ) then
                victim:Spawn()
                Splitscreen.EquipLoadout( victim, slot )
            end
        end )
    end
end )

-- Auto-equip on normal player initial spawn
hook.Add( "PlayerSpawn", "Splitscreen_PlayerSpawnHandler", function( ply )
    local slot = ply:GetNWInt( "SplitscreenSlot", 0 )
    if ( slot >= 2 and slot <= Splitscreen.MaxSlots ) then
        timer.Simple( 0.1, function()
            if ( IsValid( ply ) ) then
                local cfg = Splitscreen.LoadConfig()
                local slotData = cfg.slots[slot] or {}
                if ( slotData.model ) then ply:SetModel( slotData.model ) end
                if ( slotData.color ) then ply:SetPlayerColor( slotData.color ) end
                Splitscreen.EquipLoadout( ply, slot )
            end
        end )
    end
end )

-- Initial Post-Entity Setup: Auto-spawn bots based on saved configuration
hook.Add( "InitPostEntity", "Splitscreen_AutoSpawnConfiguredPlayers", function()
    local cfg = Splitscreen.LoadConfig()
    local count = cfg.player_count or 2

    timer.Simple( 1.0, function()
        for slot = 2, count do
            Splitscreen.SpawnBotForSlot( slot )
        end
    end )
end )

-- Clean up bots on map change / shutdown
hook.Add( "ShutDown", "Splitscreen_CleanUpBots", function()
    for slot = 2, Splitscreen.MaxSlots do
        Splitscreen.RemoveBotForSlot( slot )
    end
end )
