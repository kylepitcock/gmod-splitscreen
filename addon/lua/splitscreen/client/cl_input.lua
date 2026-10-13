--[[
    Splitscreen Co-op Mod for Garry's Mod
    Client Input System (XInput Engine & Multi-Controller Polling)
--]]

Splitscreen = Splitscreen or {}
Splitscreen.InputStates = {}
Splitscreen.HasXInput = false

-- Attempt to load XInput binary module
local ok, err = pcall( require, "xinput" )
if ( ok and _G.xinput ) then
    Splitscreen.HasXInput = true
    print( "[Splitscreen Co-op] XInput binary module detected and loaded successfully!" )
else
    print( "[Splitscreen Co-op] Note: Native xinput module not loaded yet (" .. tostring( err ) .. "). Using fallback input detection." )
end

-- Initialize input slots (1 to 4)
for i = 1, Splitscreen.MaxSlots do
    Splitscreen.InputStates[i] = {
        connected = false,
        buttons = 0,
        prev_buttons = 0,
        pressed = 0,
        released = 0,
        left_stick = { x = 0, y = 0 },
        right_stick = { x = 0, y = 0 },
        left_trigger = 0,
        right_trigger = 0,
        viewangles = Angle( 0, 0, 0 ),
        noclip = false,
        thirdperson = false,
        flashlight = false,
        spawnmenu_open = false,
        weaponwheel_open = false,
        last_input_time = 0,
        selected_weapon = nil
    }
end

-- Get Assigned Gamepad Index (0 to 3) for a given Splitscreen Slot (1 to 4)
function Splitscreen.GetGamepadIndex( slot )
    local cfg = Splitscreen.Config or Splitscreen.GetDefaultConfig()
    if ( cfg.p1_use_gamepad ) then
        return slot - 1 -- P1: 0, P2: 1, P3: 2, P4: 3
    else
        return slot - 2 -- P1: KBM (-1), P2: 0, P3: 1, P4: 2
    end
end

-- Button Query Functions
function Splitscreen.IsButtonDown( slot, btnMask )
    local state = Splitscreen.InputStates[slot]
    if ( not state ) then return false end
    return bit.band( state.buttons, btnMask ) == btnMask
end

function Splitscreen.IsButtonPressed( slot, btnMask )
    local state = Splitscreen.InputStates[slot]
    if ( not state ) then return false end
    return bit.band( state.pressed, btnMask ) == btnMask
end

function Splitscreen.IsButtonReleased( slot, btnMask )
    local state = Splitscreen.InputStates[slot]
    if ( not state ) then return false end
    return bit.band( state.released, btnMask ) == btnMask
end

-- Radial Deadzone calculation
local function ApplyRadialDeadzone( rawX, rawY, deadzone )
    local mag = math.sqrt( rawX * rawX + rawY * rawY )
    if ( mag <= deadzone ) then
        return 0, 0
    end

    local normalizedMag = math.min( 1.0, ( mag - deadzone ) / ( 1.0 - deadzone ) )
    local factor = normalizedMag / mag
    return rawX * factor, rawY * factor
end

-- Poll a specific XInput controller
local function PollControllerHardware( padIndex )
    if ( not Splitscreen.HasXInput or not _G.xinput or padIndex < 0 or padIndex > 3 ) then
        return false, nil
    end

    local state = xinput.getState( padIndex )
    if ( not state ) then
        return false, nil
    end

    local rawButtons = state.wButtons or 0
    local rawLX = ( state.sThumbLX or 0 ) / 32768.0
    local rawLY = ( state.sThumbLY or 0 ) / 32768.0
    local rawRX = ( state.sThumbRX or 0 ) / 32768.0
    local rawRY = ( state.sThumbRY or 0 ) / 32768.0
    local rawLT = ( state.bLeftTrigger or 0 ) / 255.0
    local rawRT = ( state.bRightTrigger or 0 ) / 255.0

    return true, {
        buttons = rawButtons,
        lx = rawLX,
        ly = rawLY,
        rx = rawRX,
        ry = rawRY,
        lt = rawLT,
        rt = rawRT
    }
end

-- Check if any controller is pressing START or A (for drop-in joins)
function Splitscreen.CheckDropInRequests()
    if ( not Splitscreen.HasXInput or not _G.xinput ) then return end

    for pad = 0, 3 do
        local connected, data = PollControllerHardware( pad )
        if ( connected and data ) then
            local isStart = bit.band( data.buttons, Splitscreen.XINPUT_START ) ~= 0
            local isA     = bit.band( data.buttons, Splitscreen.XINPUT_A ) ~= 0

            if ( isStart or isA ) then
                -- Determine which slot this pad belongs to
                local cfg = Splitscreen.Config or Splitscreen.GetDefaultConfig()
                local targetSlot = cfg.p1_use_gamepad and ( pad + 1 ) or ( pad + 2 )

                if ( targetSlot <= Splitscreen.MaxSlots and not Splitscreen.IsSlotActive( targetSlot ) ) then
                    print( "[Splitscreen Co-op] Drop-in detected from Gamepad #" .. pad .. " for Slot " .. targetSlot )
                    Splitscreen.RequestJoinSlot( targetSlot )
                end
            end
        end
    end
end

-- Main Input Polling Routine
local lastNetSend = 0
hook.Add( "Think", "Splitscreen_InputPolling", function()
    local cfg = Splitscreen.Config or Splitscreen.GetDefaultConfig()
    local dt = FrameTime()
    if ( dt <= 0 or dt > 0.1 ) then dt = 0.016 end

    local deadzone = cfg.deadzone or 0.18
    local sensX = ( cfg.look_sensitivity_x or 2.5 ) * 90.0
    local sensY = ( cfg.look_sensitivity_y or 2.0 ) * 90.0
    local invertY = cfg.invert_y or false

    -- Check for drop-in controller requests
    Splitscreen.CheckDropInRequests()

    for slot = 1, Splitscreen.MaxSlots do
        local state = Splitscreen.InputStates[slot]
        local padIndex = Splitscreen.GetGamepadIndex( slot )

        if ( padIndex >= 0 and padIndex <= 3 ) then
            local connected, raw = PollControllerHardware( padIndex )
            state.connected = connected

            if ( connected and raw ) then
                -- Button transitions
                local curr = raw.buttons
                state.pressed = bit.band( curr, bit.bnot( state.buttons ) )
                state.released = bit.band( bit.bnot( curr ), state.buttons )
                state.prev_buttons = state.buttons
                state.buttons = curr

                -- Trigger deadzones
                state.left_trigger = ( raw.lt > 0.1 ) and raw.lt or 0
                state.right_trigger = ( raw.rt > 0.1 ) and raw.rt or 0

                -- Analog sticks with radial deadzones
                local lx, ly = ApplyRadialDeadzone( raw.lx, raw.ly, deadzone )
                local rx, ry = ApplyRadialDeadzone( raw.rx, raw.ry, deadzone )

                state.left_stick.x = lx
                state.left_stick.y = ly
                state.right_stick.x = rx
                state.right_stick.y = ry

                -- Look angle accumulation for bot players (or P1 if on gamepad)
                if ( math.abs( rx ) > 0.001 or math.abs( ry ) > 0.001 ) then
                    local dyaw = -rx * sensX * dt
                    local dpitch = ( invertY and 1 or -1 ) * ry * sensY * dt

                    local ang = state.viewangles
                    ang.y = math.NormalizeAngle( ang.y + dyaw )
                    ang.p = math.Clamp( ang.p + dpitch, -89, 89 )
                    state.viewangles = ang
                end

                -- Toggle Actions on Button Press
                -- D-Pad Down: Thirdperson toggle
                if ( bit.band( state.pressed, Splitscreen.XINPUT_DPAD_DOWN ) ~= 0 or
                     bit.band( state.pressed, Splitscreen.XINPUT_RIGHT_THUMB ) ~= 0 ) then
                    state.thirdperson = not state.thirdperson
                    surface.PlaySound( "garrysmod/ui_click.wav" )
                end

                -- D-Pad Up: Noclip toggle
                if ( bit.band( state.pressed, Splitscreen.XINPUT_DPAD_UP ) ~= 0 ) then
                    state.noclip = not state.noclip
                    surface.PlaySound( "garrysmod/ui_hover.wav" )
                end

                -- Y Button: Flashlight toggle
                if ( bit.band( state.pressed, Splitscreen.XINPUT_Y ) ~= 0 ) then
                    state.flashlight = not state.flashlight
                    surface.PlaySound( "items/flashlight1.wav" )
                end

                -- D-Pad Left: Undo last action
                if ( bit.band( state.pressed, Splitscreen.XINPUT_DPAD_LEFT ) ~= 0 ) then
                    Splitscreen.RequestUndo( slot )
                end

                -- BACK Button: Spawn Menu Toggle/Hold
                state.spawnmenu_open = ( bit.band( state.buttons, Splitscreen.XINPUT_BACK ) ~= 0 )

                -- RB Button Hold: Weapon Wheel
                state.weaponwheel_open = ( bit.band( state.buttons, Splitscreen.XINPUT_RIGHT_SHOULDER ) ~= 0 )
            else
                state.buttons = 0
                state.pressed = 0
                state.released = 0
                state.left_stick = { x = 0, y = 0 }
                state.right_stick = { x = 0, y = 0 }
                state.left_trigger = 0
                state.right_trigger = 0
            end
        elseif ( slot == 1 ) then
            -- Player 1 is on Keyboard & Mouse: Viewangles sync with LocalPlayer()
            if ( IsValid( LocalPlayer() ) ) then
                state.viewangles = LocalPlayer():EyeAngles()
                state.connected = true
            end
        end
    end

    -- Send network inputs for active bot players (slots 2..4) at ~60 Hz
    if ( CurTime() - lastNetSend >= 0.016 ) then
        lastNetSend = CurTime()
        for slot = 2, Splitscreen.MaxSlots do
            if ( Splitscreen.IsSlotActive( slot ) ) then
                Splitscreen.SendSlotInput( slot )
            end
        end
    end
end )

-- Network transmission of bot inputs to the server
function Splitscreen.SendSlotInput( slot )
    local state = Splitscreen.InputStates[slot]
    if ( not state ) then return end

    -- Convert controller state into Source Engine movement & buttons
    local forward = state.left_stick.y * 400
    local side    = state.left_stick.x * 400
    local up      = 0

    local inButtons = 0
    -- Primary Attack (RT)
    if ( state.right_trigger > 0.25 ) then
        inButtons = bit.bor( inButtons, IN_ATTACK )
    end
    -- Secondary Attack (LT)
    if ( state.left_trigger > 0.25 ) then
        inButtons = bit.bor( inButtons, IN_ATTACK2 )
    end
    -- Jump (A)
    if ( bit.band( state.buttons, Splitscreen.XINPUT_A ) ~= 0 ) then
        inButtons = bit.bor( inButtons, IN_JUMP )
        up = 250
    end
    -- Crouch (B)
    if ( bit.band( state.buttons, Splitscreen.XINPUT_B ) ~= 0 ) then
        inButtons = bit.bor( inButtons, IN_DUCK )
        up = -250
    end
    -- Use / Interact (X)
    if ( bit.band( state.buttons, Splitscreen.XINPUT_X ) ~= 0 ) then
        inButtons = bit.bor( inButtons, IN_USE )
    end
    -- Sprint (LB or L3)
    if ( bit.band( state.buttons, Splitscreen.XINPUT_LEFT_SHOULDER ) ~= 0 or
         bit.band( state.buttons, Splitscreen.XINPUT_LEFT_THUMB ) ~= 0 ) then
        inButtons = bit.bor( inButtons, IN_SPEED )
        forward = forward * 1.6
        side = side * 1.6
    end
    -- Reload (tap X)
    if ( bit.band( state.pressed, Splitscreen.XINPUT_X ) ~= 0 ) then
        inButtons = bit.bor( inButtons, IN_RELOAD )
    end

    net.Start( "Splitscreen_Input" )
        net.WriteUInt( slot, 3 )
        net.WriteFloat( forward )
        net.WriteFloat( side )
        net.WriteFloat( up )
        net.WriteUInt( inButtons, 32 )
        net.WriteAngle( state.viewangles )
        net.WriteBool( state.noclip )
        net.WriteBool( state.flashlight )
        net.WriteString( state.selected_weapon or "" )
    net.SendToServer()

    -- Reset one-shot weapon selection
    state.selected_weapon = nil
end

