--[[
    Splitscreen Co-op Mod for Garry's Mod
    Server Input Translation & Command Execution (GM:StartCommand)
--]]

Splitscreen = Splitscreen or {}
Splitscreen.PendingInputs = {}

for slot = 2, Splitscreen.MaxSlots do
    Splitscreen.PendingInputs[slot] = {
        forward = 0,
        side = 0,
        up = 0,
        buttons = 0,
        angles = Angle( 0, 0, 0 ),
        noclip = false,
        flashlight = false,
        selectedWeapon = nil,
        lastReceived = 0
    }
end

-- Receive Networked Inputs for Splitscreen Bots
net.Receive( "Splitscreen_Input", function( len, ply )
    local slot = net.ReadUInt( 3 )
    if ( slot < 2 or slot > Splitscreen.MaxSlots ) then return end

    local forward = net.ReadFloat()
    local side    = net.ReadFloat()
    local up      = net.ReadFloat()
    local buttons = net.ReadUInt( 32 )
    local angles  = net.ReadAngle()
    local noclip  = net.ReadBool()
    local fl      = net.ReadBool()
    local wep     = net.ReadString()

    local entry = Splitscreen.PendingInputs[slot]
    entry.forward        = forward
    entry.side           = side
    entry.up             = up
    entry.buttons        = buttons
    entry.angles         = angles
    entry.noclip         = noclip
    entry.flashlight     = fl
    if ( wep and wep ~= "" ) then
        entry.selectedWeapon = wep
    end
    entry.lastReceived   = CurTime()
end )

-- StartCommand hook: authoritative injection of movement, aiming, and weapon firing
hook.Add( "StartCommand", "Splitscreen_BotCommandProcessing", function( ply, ucmd )
    local slot = ply:GetNWInt( "SplitscreenSlot", 0 )
    if ( slot < 2 or slot > Splitscreen.MaxSlots ) then return end

    local data = Splitscreen.PendingInputs[slot]
    if ( not data ) then return end

    -- Check if input is recent (within 0.5s) to prevent frozen bot walking
    if ( CurTime() - data.lastReceived > 0.5 ) then
        ucmd:ClearMovement()
        ucmd:SetButtons( 0 )
        return
    end

    -- Inject Movement
    ucmd:SetForwardMove( data.forward )
    ucmd:SetSideMove( data.side )
    ucmd:SetUpMove( data.up )

    -- Inject Button Flags (IN_ATTACK, IN_ATTACK2, IN_JUMP, IN_DUCK, IN_SPEED, IN_USE, etc.)
    ucmd:SetButtons( data.buttons )

    -- Inject View Angles
    ucmd:SetViewAngles( data.angles )
    ply:SetEyeAngles( data.angles )

    -- Weapon Switching
    if ( data.selectedWeapon ) then
        local targetWep = ply:GetWeapon( data.selectedWeapon )
        if ( IsValid( targetWep ) ) then
            ucmd:SelectWeapon( targetWep )
        end
        data.selectedWeapon = nil
    end

    -- Noclip Toggle Handling
    local currentMoveType = ply:GetMoveType()
    if ( data.noclip and currentMoveType ~= MOVETYPE_NOCLIP ) then
        ply:SetMoveType( MOVETYPE_NOCLIP )
    elseif ( not data.noclip and currentMoveType == MOVETYPE_NOCLIP ) then
        ply:SetMoveType( MOVETYPE_WALK )
    end

    -- Flashlight Toggle Handling
    if ( data.flashlight ~= ply:FlashlightIsOn() ) then
        ply:Flashlight( data.flashlight )
    end
end )
