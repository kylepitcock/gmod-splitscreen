--[[
    Splitscreen Co-op Mod for Garry's Mod
    Client Dynamic HUD System (Independent 4-Player Viewport HUDs)
--]]

Splitscreen = Splitscreen or {}

-- Create custom modern HUD fonts
surface.CreateFont( "Splitscreen_Badge", {
    font = "Roboto",
    size = 14,
    weight = 700,
    antialias = true
} )

surface.CreateFont( "Splitscreen_LargeNum", {
    font = "Roboto",
    size = 22,
    weight = 800,
    antialias = true
} )

surface.CreateFont( "Splitscreen_SmallLabel", {
    font = "Roboto",
    size = 11,
    weight = 600,
    antialias = true
} )

surface.CreateFont( "Splitscreen_Weapon", {
    font = "Roboto",
    size = 15,
    weight = 700,
    antialias = true
} )

-- Suppress standard HL2 HUD elements when splitscreen is active
local hiddenHUD = {
    ["CHudHealth"]            = true,
    ["CHudBattery"]           = true,
    ["CHudAmmo"]              = true,
    ["CHudSecondaryAmmo"]     = true,
    ["CHudWeaponSelection"]   = true,
    ["CHudCrosshair"]         = true
}

hook.Add( "HUDShouldDraw", "Splitscreen_HideDefaultHUD", function( name )
    if ( Splitscreen.GetActivePlayerCount() >= 2 or Splitscreen.ForcedSingleSplit ) then
        if ( hiddenHUD[name] ) then
            return false
        end
    end
end )

-- Draw Rounded Card Helper
local function DrawFrostedCard( x, y, w, h, bgCol )
    bgCol = bgCol or Color( 18, 20, 24, 215 )
    draw.RoundedBox( 6, x, y, w, h, bgCol )
    surface.SetDrawColor( 255, 255, 255, 12 )
    surface.DrawOutlinedRect( x, y, w, h, 1 )
end

-- Draw Viewport Crosshair
local function DrawPlayerCrosshair( cx, cy, slotCol, isHitting )
    local chSize = 6
    local chGap = 4
    local col = isHitting and Color( 255, 60, 60, 240 ) or Color( 255, 255, 255, 220 )

    surface.SetDrawColor( col )
    -- Center dot
    surface.DrawRect( cx - 1, cy - 1, 2, 2 )
    -- Top, Bottom, Left, Right ticks
    surface.DrawRect( cx - 1, cy - chGap - chSize, 2, chSize )
    surface.DrawRect( cx - 1, cy + chGap, 2, chSize )
    surface.DrawRect( cx - chGap - chSize, cy - 1, chSize, 2 )
    surface.DrawRect( cx + chGap, cy - 1, chSize, 2 )
end

-- Render HUD for a specific player slot inside their viewport
function Splitscreen.DrawSlotHUD( slot, vp )
    local ply = Splitscreen.GetSlotEntity( slot )
    local slotCol = Splitscreen.SlotColors[slot] or Color( 0, 160, 255 )
    local state = Splitscreen.InputStates[slot]

    -- 1. Slot Identity Badge (Top-Left)
    local badgeX = vp.x + 12
    local badgeY = vp.y + 12
    local nick = IsValid( ply ) and ply:Nick() or ( "Player " .. slot )
    local badgeText = "P" .. slot .. ": " .. nick
    surface.SetFont( "Splitscreen_Badge" )
    local bw, bh = surface.GetTextSize( badgeText )

    DrawFrostedCard( badgeX, badgeY, bw + 24, 26, Color( 15, 17, 20, 210 ) )
    -- Color stripe
    draw.RoundedBoxEx( 4, badgeX, badgeY, 5, 26, slotCol, true, false, true, false )
    -- Text
    draw.SimpleText( badgeText, "Splitscreen_Badge", badgeX + 14, badgeY + 6, Color( 240, 240, 240 ), TEXT_ALIGN_LEFT )

    -- Sub-badges for Noclip / Thirdperson
    local subX = badgeX + bw + 30
    if ( state and state.noclip ) then
        DrawFrostedCard( subX, badgeY, 60, 26, Color( 230, 126, 34, 200 ) )
        draw.SimpleText( "NOCLIP", "Splitscreen_SmallLabel", subX + 30, badgeY + 7, color_white, TEXT_ALIGN_CENTER )
        subX = subX + 66
    end
    if ( state and state.thirdperson ) then
        DrawFrostedCard( subX, badgeY, 50, 26, Color( 52, 152, 219, 200 ) )
        draw.SimpleText( "3RD", "Splitscreen_SmallLabel", subX + 25, badgeY + 7, color_white, TEXT_ALIGN_CENTER )
    end

    if ( not IsValid( ply ) or not ply:Alive() ) then
        -- Respawn / Dead status overlay
        local cardW, cardH = 200, 60
        local cx = vp.x + ( vp.w - cardW ) / 2
        local cy = vp.y + ( vp.h - cardH ) / 2
        DrawFrostedCard( cx, cy, cardW, cardH, Color( 180, 40, 40, 210 ) )
        draw.SimpleText( "RESPAWNING...", "Splitscreen_Badge", cx + cardW / 2, cy + 18, color_white, TEXT_ALIGN_CENTER )
        return
    end

    -- 2. Crosshair (Centered in Viewport)
    local cx = vp.x + math.floor( vp.w / 2 )
    local cy = vp.y + math.floor( vp.h / 2 )
    DrawPlayerCrosshair( cx, cy, slotCol, false )

    -- 3. Health & Armor Bar (Bottom-Left)
    local cardW = math.Clamp( vp.w * 0.35, 170, 220 )
    local cardH = 54
    local cardX = vp.x + 12
    local cardY = vp.y + vp.h - cardH - 12
    DrawFrostedCard( cardX, cardY, cardW, cardH )

    local hp = math.max( 0, ply:Health() )
    local maxHP = math.max( 100, ply:GetMaxHealth() )
    local armor = math.max( 0, ply:Armor() )

    -- HP Bar Color: Green -> Orange -> Pulsing Red
    local hpCol = Color( 46, 204, 113 )
    if ( hp < 25 ) then
        local pulse = math.abs( math.sin( CurTime() * 6 ) )
        hpCol = Color( 231 + pulse * 24, 76, 60 )
    elseif ( hp < 50 ) then
        hpCol = Color( 243, 156, 18 )
    end

    -- Health Row
    local barW = cardW - 60
    draw.SimpleText( "HP", "Splitscreen_SmallLabel", cardX + 10, cardY + 8, Color( 180, 180, 180 ) )
    draw.SimpleText( tostring( hp ), "Splitscreen_LargeNum", cardX + 45, cardY + 4, hpCol, TEXT_ALIGN_RIGHT )
    -- HP Bar Background & Fill
    draw.RoundedBox( 3, cardX + 52, cardY + 11, barW, 9, Color( 35, 38, 45 ) )
    local fillW = math.Clamp( ( hp / maxHP ) * barW, 0, barW )
    if ( fillW > 0 ) then
        draw.RoundedBox( 3, cardX + 52, cardY + 11, fillW, 9, hpCol )
    end

    -- Armor Row
    draw.SimpleText( "AP", "Splitscreen_SmallLabel", cardX + 10, cardY + 32, Color( 180, 180, 180 ) )
    draw.SimpleText( tostring( armor ), "Splitscreen_Badge", cardX + 45, cardY + 31, Color( 52, 152, 219 ), TEXT_ALIGN_RIGHT )
    draw.RoundedBox( 3, cardX + 52, cardY + 34, barW, 7, Color( 35, 38, 45 ) )
    local armorFillW = math.Clamp( ( armor / 100 ) * barW, 0, barW )
    if ( armorFillW > 0 ) then
        draw.RoundedBox( 3, cardX + 52, cardY + 34, armorFillW, 7, Color( 52, 152, 219 ) )
    end

    -- 4. Ammo & Weapon Info (Bottom-Right)
    local wep = ply:GetActiveWeapon()
    if ( IsValid( wep ) ) then
        local wepCardW = math.Clamp( vp.w * 0.35, 170, 220 )
        local wepCardH = 54
        local wepCardX = vp.x + vp.w - wepCardW - 12
        local wepCardY = vp.y + vp.h - wepCardH - 12
        DrawFrostedCard( wepCardX, wepCardY, wepCardW, wepCardH )

        local wepName = wep:GetPrintName() or wep:GetClass()
        draw.SimpleText( wepName, "Splitscreen_Weapon", wepCardX + 10, wepCardY + 8, Color( 240, 240, 240 ) )

        local clip = wep:Clip1()
        local ammoType = wep:GetPrimaryAmmoType()
        local reserve = ( ammoType > 0 ) and ply:GetAmmoCount( ammoType ) or -1

        if ( clip >= 0 ) then
            local ammoStr = tostring( clip ) .. " / " .. ( ( reserve >= 0 ) and tostring( reserve ) or "∞" )
            draw.SimpleText( ammoStr, "Splitscreen_LargeNum", wepCardX + wepCardW - 12, wepCardY + 26, Color( 255, 204, 0 ), TEXT_ALIGN_RIGHT )
        elseif ( reserve >= 0 ) then
            draw.SimpleText( tostring( reserve ), "Splitscreen_LargeNum", wepCardX + wepCardW - 12, wepCardY + 26, Color( 255, 204, 0 ), TEXT_ALIGN_RIGHT )
        else
            draw.SimpleText( "READY", "Splitscreen_Badge", wepCardX + wepCardW - 12, wepCardY + 28, Color( 120, 220, 120 ), TEXT_ALIGN_RIGHT )
        end
    end

    -- 5. Bottom Gamepad Legend Prompt
    local hintText = "[BACK] Spawn Menu   [RB] Weapons   [Y] Light   [R3] 3rd Person"
    draw.SimpleText( hintText, "Splitscreen_SmallLabel", vp.x + vp.w / 2, vp.y + vp.h - 10, Color( 200, 200, 200, 130 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM )
end

-- Render Prompt for an Inactive Slot in Quadrant View
local function DrawEmptySlotPrompt( slot, vp )
    local promptW, promptH = 260, 80
    local px = vp.x + ( vp.w - promptW ) / 2
    local py = vp.y + ( vp.h - promptH ) / 2

    DrawFrostedCard( px, py, promptW, promptH, Color( 20, 22, 28, 190 ) )
    local col = Splitscreen.SlotColors[slot] or color_white
    draw.RoundedBoxEx( 4, px, py, 6, promptH, col, true, false, true, false )

    draw.SimpleText( "SLOT " .. slot .. " AVAILABLE", "Splitscreen_Badge", px + 18, py + 16, col )
    draw.SimpleText( "PRESS [A] OR [START] TO JOIN", "Splitscreen_SmallLabel", px + 18, py + 38, Color( 230, 230, 230 ) )
    draw.SimpleText( "Gamepad Co-op", "Splitscreen_SmallLabel", px + 18, py + 54, Color( 150, 150, 150 ) )
end

-- Main HUD Paint Hook
hook.Add( "HUDPaint", "Splitscreen_MasterHUDPaint", function()
    local activeCount = Splitscreen.GetActivePlayerCount()
    if ( activeCount <= 1 and not Splitscreen.ForcedSingleSplit ) then
        return
    end

    local cfg = Splitscreen.Config or Splitscreen.GetDefaultConfig()
    local layout = cfg.layout or Splitscreen.LAYOUT_GRID

    -- Draw HUD for each quadrant / viewport
    for slot = 1, Splitscreen.MaxSlots do
        local vp = Splitscreen.CachedViewports[slot] or Splitscreen.CalculateViewport( slot, activeCount, layout )
        if ( Splitscreen.IsSlotActive( slot ) ) then
            Splitscreen.DrawSlotHUD( slot, vp )
        elseif ( activeCount >= 3 and layout == Splitscreen.LAYOUT_GRID ) then
            -- In 4-grid mode with empty slots, show join prompt
            DrawEmptySlotPrompt( slot, vp )
        end
    end
end )

