--[[
    Splitscreen Co-op Mod for Garry's Mod
    Gamepad Radial Weapon Wheel & Quick Switch
--]]

Splitscreen = Splitscreen or {}
Splitscreen.SelectedWheelIndex = {}

for slot = 1, Splitscreen.MaxSlots do
    Splitscreen.SelectedWheelIndex[slot] = 1
end

-- Render and handle weapon wheel for a player slot
function Splitscreen.DrawSlotWeaponWheel( slot, vp )
    local ply = Splitscreen.GetSlotEntity( slot )
    if ( not IsValid( ply ) or not ply:Alive() ) then return end

    local weps = ply:GetWeapons()
    local wepCount = #weps
    if ( wepCount <= 0 ) then return end

    local input = Splitscreen.InputStates[slot]
    local slotCol = Splitscreen.SlotColors[slot] or Color( 0, 160, 255 )

    local cx = vp.x + math.floor( vp.w / 2 )
    local cy = vp.y + math.floor( vp.h / 2 )
    local radius = math.Clamp( math.min( vp.w, vp.h ) * 0.28, 80, 160 )

    -- Darkened background circle
    draw.RoundedBox( 0, vp.x, vp.y, vp.w, vp.h, Color( 10, 12, 16, 170 ) )

    -- Analog stick angle calculation (using Right stick or Left stick)
    local stickX = input.right_stick.x
    local stickY = input.right_stick.y
    if ( math.abs( stickX ) < 0.2 and math.abs( stickY ) < 0.2 ) then
        stickX = input.left_stick.x
        stickY = input.left_stick.y
    end

    local angleStep = ( 2 * math.pi ) / wepCount
    local selectedIdx = Splitscreen.SelectedWheelIndex[slot] or 1

    if ( math.abs( stickX ) > 0.3 or math.abs( stickY ) > 0.3 ) then
        local stickAngle = math.atan2( -stickY, stickX ) -- Invert Y for screen space
        if ( stickAngle < 0 ) then stickAngle = stickAngle + ( 2 * math.pi ) end

        -- Offset by half step so top aligns with 0
        local shifted = ( stickAngle + ( angleStep / 2 ) ) % ( 2 * math.pi )
        selectedIdx = math.floor( shifted / angleStep ) + 1
        selectedIdx = math.Clamp( selectedIdx, 1, wepCount )
        Splitscreen.SelectedWheelIndex[slot] = selectedIdx
    end

    -- Draw weapon wedges / nodes
    for i, wep in ipairs( weps ) do
        local ang = ( i - 1 ) * angleStep - ( math.pi / 2 )
        local wx = cx + math.cos( ang ) * radius
        local wy = cy + math.sin( ang ) * radius

        local isSelected = ( i == selectedIdx )
        local nodeSize = isSelected and 70 or 52
        local nodeBg = isSelected and slotCol or Color( 30, 34, 42, 220 )

        DrawFrostedCard( wx - ( nodeSize / 2 ), wy - ( nodeSize / 2 ), nodeSize, nodeSize, nodeBg )

        local wepName = wep:GetPrintName() or wep:GetClass()
        wepName = string.sub( wepName, 1, 12 )
        draw.SimpleText( wepName, "Splitscreen_SmallLabel", wx, wy, isSelected and color_white or Color( 200, 200, 200 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    -- Center Information Box
    local centerW = 160
    local centerH = 48
    DrawFrostedCard( cx - ( centerW / 2 ), cy - ( centerH / 2 ), centerW, centerH, Color( 20, 24, 30, 240 ) )

    local activeWep = weps[selectedIdx]
    if ( IsValid( activeWep ) ) then
        local fullName = activeWep:GetPrintName() or activeWep:GetClass()
        draw.SimpleText( fullName, "Splitscreen_Badge", cx, cy - 8, color_white, TEXT_ALIGN_CENTER )
        draw.SimpleText( "RELEASE [RB] TO EQUIP", "Splitscreen_SmallLabel", cx, cy + 10, slotCol, TEXT_ALIGN_CENTER )
    end
end

-- Weapon Wheel release detector
hook.Add( "Think", "Splitscreen_WeaponWheelSelection", function()
    for slot = 1, Splitscreen.MaxSlots do
        local state = Splitscreen.InputStates[slot]
        if ( state ) then
            -- Check if RB was just released
            if ( bit.band( state.released, Splitscreen.XINPUT_RIGHT_SHOULDER ) ~= 0 ) then
                local ply = Splitscreen.GetSlotEntity( slot )
                if ( IsValid( ply ) ) then
                    local weps = ply:GetWeapons()
                    local idx = Splitscreen.SelectedWheelIndex[slot] or 1
                    local chosenWep = weps[idx]

                    if ( IsValid( chosenWep ) ) then
                        local wepClass = chosenWep:GetClass()
                        if ( slot == 1 ) then
                            LocalPlayer():SelectWeapon( wepClass )
                        else
                            state.selected_weapon = wepClass
                        end
                        surface.PlaySound( "weapons/weapon_select.wav" )
                    end
                end
            end
        end
    end
end )

-- Render Weapon Wheels in HUDPaint
hook.Add( "HUDPaint", "Splitscreen_RenderWeaponWheels", function()
    for slot = 1, Splitscreen.MaxSlots do
        local state = Splitscreen.InputStates[slot]
        if ( state and state.weaponwheel_open and Splitscreen.IsSlotActive( slot ) ) then
            local vp = Splitscreen.CachedViewports[slot] or Splitscreen.CalculateViewport( slot, Splitscreen.GetActivePlayerCount(), Splitscreen.LAYOUT_GRID )
            Splitscreen.DrawSlotWeaponWheel( slot, vp )
        end
    end
end )
