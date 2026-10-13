--[[
    Splitscreen Co-op Mod for Garry's Mod
    Server Spawner & Sandbox Abilities
    Ensures ALL players (Host & Bots) have full Sandbox abilities, undo, and ownership.
--]]

Splitscreen = Splitscreen or {}

-- Calculate crosshair trace for a player
local function GetPlayerEyeTrace( ply )
    local startPos = ply:EyePos()
    local endPos   = startPos + ( ply:EyeAngles():Forward() * 2500 )
    return util.TraceLine( {
        start  = startPos,
        endpos = endPos,
        filter = ply,
        mask   = MASK_SOLID
    } )
end

-- Authoritative Spawn Request Processor
net.Receive( "Splitscreen_Spawn", function( len, sender )
    local slot     = net.ReadUInt( 3 )
    local category = net.ReadString()

    -- Determine which player is issuing the spawn command
    local requestPly = ( slot == 1 ) and sender or Splitscreen.Bots[slot]
    if ( not IsValid( requestPly ) or not requestPly:Alive() ) then return end

    local tr = GetPlayerEyeTrace( requestPly )

    -- 1. PROPS
    if ( category == "props" ) then
        local model = net.ReadString()
        if ( not model or model == "" ) then return end

        local prop = ents.Create( "prop_physics" )
        if ( not IsValid( prop ) ) then return end

        prop:SetModel( model )
        -- Position slightly off the hit surface to prevent getting stuck in walls
        local spawnPos = tr.HitPos + ( tr.HitNormal * 12 )
        prop:SetPos( spawnPos )
        prop:SetAngles( Angle( 0, requestPly:EyeAngles().y, 0 ) )
        prop:Spawn()
        prop:Activate()

        local phys = prop:GetPhysicsObject()
        if ( IsValid( phys ) ) then
            phys:Wake()
        end

        -- CPPI Ownership Support
        if ( prop.CPPISetOwner ) then
            prop:CPPISetOwner( requestPly )
        end

        -- Sandbox Undo Integration
        undo.Create( "Prop" )
            undo.AddEntity( prop )
            undo.SetPlayer( requestPly )
        undo.Finish()

        cleanup.Add( requestPly, "props", prop )
        gamemode.Call( "PlayerSpawnedProp", requestPly, model, prop )

    -- 2. WEAPONS
    elseif ( category == "weapons" ) then
        local wepClass = net.ReadString()
        if ( not wepClass or wepClass == "" ) then return end

        if ( not requestPly:HasWeapon( wepClass ) ) then
            requestPly:Give( wepClass )
        end
        requestPly:SelectWeapon( wepClass )

    -- 3. NPCS
    elseif ( category == "npcs" ) then
        local npcClass = net.ReadString()
        local npcWep   = net.ReadString()
        if ( not npcClass or npcClass == "" ) then return end

        local npc = ents.Create( npcClass )
        if ( not IsValid( npc ) ) then return end

        npc:SetPos( tr.HitPos + Vector( 0, 0, 4 ) )
        npc:SetAngles( Angle( 0, requestPly:EyeAngles().y + 180, 0 ) )

        if ( npcWep and npcWep ~= "" ) then
            npc:SetKeyValue( "additionalequipment", npcWep )
        end

        npc:Spawn()
        npc:Activate()

        if ( npc.CPPISetOwner ) then
            npc:CPPISetOwner( requestPly )
        end

        undo.Create( "NPC" )
            undo.AddEntity( npc )
            undo.SetPlayer( requestPly )
        undo.Finish()

        cleanup.Add( requestPly, "npcs", npc )
        gamemode.Call( "PlayerSpawnedNPC", requestPly, npc )

    -- 4. VEHICLES
    elseif ( category == "vehicles" ) then
        local script = net.ReadString()
        local model  = net.ReadString()

        local veh = ents.Create( "prop_vehicle_airboat" )
        if ( string.find( script, "jeep" ) or string.find( model, "buggy" ) ) then
            veh = ents.Create( "prop_vehicle_jeep" )
        elseif ( string.find( script, "pod" ) or string.find( model, "pod" ) ) then
            veh = ents.Create( "prop_vehicle_prisoner_pod" )
        end

        if ( not IsValid( veh ) ) then return end

        veh:SetModel( model )
        if ( script and script ~= "" ) then
            veh:SetKeyValue( "vehiclescript", script )
        end
        veh:SetPos( tr.HitPos + Vector( 0, 0, 15 ) )
        veh:SetAngles( Angle( 0, requestPly:EyeAngles().y, 0 ) )
        veh:Spawn()
        veh:Activate()

        if ( veh.CPPISetOwner ) then
            veh:CPPISetOwner( requestPly )
        end

        undo.Create( "Vehicle" )
            undo.AddEntity( veh )
            undo.SetPlayer( requestPly )
        undo.Finish()

        cleanup.Add( requestPly, "vehicles", veh )
        gamemode.Call( "PlayerSpawnedVehicle", requestPly, veh )

    -- 5. ENTITIES
    elseif ( category == "entities" ) then
        local entClass = net.ReadString()
        if ( not entClass or entClass == "" ) then return end

        local ent = ents.Create( entClass )
        if ( not IsValid( ent ) ) then return end

        ent:SetPos( tr.HitPos + ( tr.HitNormal * 14 ) )
        ent:SetAngles( Angle( 0, requestPly:EyeAngles().y, 0 ) )
        ent:Spawn()
        ent:Activate()

        if ( ent.CPPISetOwner ) then
            ent:CPPISetOwner( requestPly )
        end

        undo.Create( "SENT" )
            undo.AddEntity( ent )
            undo.SetPlayer( requestPly )
        undo.Finish()

        cleanup.Add( requestPly, "sents", ent )
        gamemode.Call( "PlayerSpawnedSENT", requestPly, ent )

    -- 6. TOOLS
    elseif ( category == "tools" ) then
        local toolMode = net.ReadString()
        if ( not requestPly:HasWeapon( "gmod_tool" ) ) then
            requestPly:Give( "gmod_tool" )
        end
        requestPly:SelectWeapon( "gmod_tool" )

        local tool = requestPly:GetWeapon( "gmod_tool" )
        if ( IsValid( tool ) and tool.SetMode ) then
            tool:SetMode( toolMode )
        end

    -- 7. UNDO
    elseif ( category == "undo" ) then
        undo.Do_Undo( requestPly )

    -- 8. CLEANUP
    elseif ( category == "cleanup" ) then
        cleanup.CC_AdminCleanup( requestPly, "gmod_cleanup", {} )
    end
end )

