--[[
    Splitscreen Co-op Mod for Garry's Mod
    Gamepad Radial & Grid Spawn Menu System
    Gives ALL 4 players full, independent Sandbox spawning abilities.
--]]

Splitscreen = Splitscreen or {}
Splitscreen.SpawnMenuStates = {}

-- Initialize menu states for each player slot
local categoriesOrder = { "props", "weapons", "npcs", "vehicles", "entities", "tools" }

for slot = 1, Splitscreen.MaxSlots do
    Splitscreen.SpawnMenuStates[slot] = {
        categoryIndex = 1,
        itemIndex = 1,
        lastNavTime = 0,
        page = 1
    }
end

-- Request spawn to server
function Splitscreen.RequestSpawn( slot, category, item )
    if ( not item ) then return end

    net.Start( "Splitscreen_Spawn" )
        net.WriteUInt( slot, 3 )
        net.WriteString( category )

        if ( category == "props" ) then
            net.WriteString( item.model )
        elseif ( category == "weapons" ) then
            net.WriteString( item.class )
        elseif ( category == "npcs" ) then
            net.WriteString( item.class )
            net.WriteString( item.weapon or "" )
        elseif ( category == "vehicles" ) then
            net.WriteString( item.script or "" )
            net.WriteString( item.model or "" )
        elseif ( category == "entities" ) then
            net.WriteString( item.class )
        elseif ( category == "tools" ) then
            net.WriteString( item.mode )
        end
    net.SendToServer()

    surface.PlaySound( "ui/buttonclickrelease.wav" )
end

-- Request Undo to server
function Splitscreen.RequestUndo( slot )
    net.Start( "Splitscreen_Spawn" )
        net.WriteUInt( slot, 3 )
        net.WriteString( "undo" )
        net.WriteString( "" )
    net.SendToServer()

    surface.PlaySound( "buttons/button15.wav" )
end

-- Request Cleanup to server
function Splitscreen.RequestCleanup( slot )
    net.Start( "Splitscreen_Spawn" )
        net.WriteUInt( slot, 3 )
        net.WriteString( "cleanup" )
        net.WriteString( "" )
    net.SendToServer()

    surface.PlaySound( "buttons/button19.wav" )
end

-- Handle Gamepad Navigation for a slot's spawn menu
local function HandleMenuInput( slot )
    local input = Splitscreen.InputStates[slot]
    local mState = Splitscreen.SpawnMenuStates[slot]
    local now = CurTime()
    if ( now - mState.lastNavTime < 0.18 ) then return end

    local currentCatKey = categoriesOrder[mState.categoryIndex]
    local currentCatData = Splitscreen.SpawnCatalog[currentCatKey]
    local items = currentCatData and currentCatData.items or {}
    local itemCount = #items

    -- 1. Tab Switching (Bumpers: LB / RB)
    if ( Splitscreen.IsButtonPressed( slot, Splitscreen.XINPUT_RIGHT_SHOULDER ) ) then
        mState.categoryIndex = ( mState.categoryIndex % #categoriesOrder ) + 1
        mState.itemIndex = 1
        mState.lastNavTime = now
        surface.PlaySound( "garrysmod/ui_hover.wav" )
        return
    elseif ( Splitscreen.IsButtonPressed( slot, Splitscreen.XINPUT_LEFT_SHOULDER ) ) then
        mState.categoryIndex = ( mState.categoryIndex - 2 + #categoriesOrder ) % #categoriesOrder + 1
        mState.itemIndex = 1
        mState.lastNavTime = now
        surface.PlaySound( "garrysmod/ui_hover.wav" )
        return
    end

    -- 2. Item Grid Navigation (Left Stick or D-Pad)
    local navX = 0
    local navY = 0

    if ( input.left_stick.x > 0.5 or bit.band( input.pressed, Splitscreen.XINPUT_DPAD_RIGHT ) ~= 0 ) then
        navX = 1
    elseif ( input.left_stick.x < -0.5 or bit.band( input.pressed, Splitscreen.XINPUT_DPAD_LEFT ) ~= 0 ) then
        navX = -1
    end

    if ( input.left_stick.y > 0.5 or bit.band( input.pressed, Splitscreen.XINPUT_DPAD_UP ) ~= 0 ) then
        navY = -1 -- Move Up in list
    elseif ( input.left_stick.y < -0.5 or bit.band( input.pressed, Splitscreen.XINPUT_DPAD_DOWN ) ~= 0 ) then
        navY = 1 -- Move Down in list
    end

    if ( navX ~= 0 or navY ~= 0 ) then
        local cols = 3
        local newIndex = mState.itemIndex + navX + ( navY * cols )
        newIndex = math.Clamp( newIndex, 1, itemCount )
        if ( newIndex ~= mState.itemIndex ) then
            mState.itemIndex = newIndex
            mState.lastNavTime = now
            surface.PlaySound( "garrysmod/ui_hover.wav" )
        end
    end

    -- 3. Confirm / Spawn (A Button)
    if ( Splitscreen.IsButtonPressed( slot, Splitscreen.XINPUT_A ) ) then
        local selectedItem = items[mState.itemIndex]
        if ( selectedItem ) then
            Splitscreen.RequestSpawn( slot, currentCatKey, selectedItem )
            mState.lastNavTime = now + 0.1
        end
    end

    -- 4. Undo Shortcut inside Menu (X Button)
    if ( Splitscreen.IsButtonPressed( slot, Splitscreen.XINPUT_X ) ) then
        Splitscreen.RequestUndo( slot )
        mState.lastNavTime = now + 0.1
    end

    -- 5. Cleanup Shortcut inside Menu (Y Button)
    if ( Splitscreen.IsButtonPressed( slot, Splitscreen.XINPUT_Y ) ) then
        Splitscreen.RequestCleanup( slot )
        mState.lastNavTime = now + 0.1
    end
end

-- Render the Gamepad Spawn Menu inside a specific player's viewport
function Splitscreen.DrawSlotSpawnMenu( slot, vp )
    local mState = Splitscreen.SpawnMenuStates[slot]
    local slotCol = Splitscreen.SlotColors[slot] or Color( 0, 160, 255 )

    -- Process gamepad navigation
    HandleMenuInput( slot )

    -- Darkened overlay for this player's viewport
    draw.RoundedBox( 0, vp.x, vp.y, vp.w, vp.h, Color( 12, 14, 18, 235 ) )

    -- Outer Window Box
    local winMargin = 20
    local winW = vp.w - ( winMargin * 2 )
    local winH = vp.h - ( winMargin * 2 )
    local winX = vp.x + winMargin
    local winY = vp.y + winMargin

    draw.RoundedBox( 8, winX, winY, winW, winH, Color( 22, 25, 32, 255 ) )
    surface.SetDrawColor( 255, 255, 255, 15 )
    surface.DrawOutlinedRect( winX, winY, winW, winH, 1 )

    -- Title Bar
    local titleH = 40
    draw.RoundedBoxEx( 8, winX, winY, winW, titleH, Color( 30, 34, 44, 255 ), true, true, false, false )
    draw.RoundedBox( 0, winX, winY + titleH - 2, winW, 2, slotCol )

    local titleText = "SPAWN MENU — PLAYER " .. slot
    draw.SimpleText( titleText, "Splitscreen_Badge", winX + 16, winY + 12, color_white )
    draw.SimpleText( "[LB/RB] Category   [A] Spawn   [X] Undo   [B/BACK] Close", "Splitscreen_SmallLabel", winX + winW - 16, winY + 14, Color( 180, 180, 180 ), TEXT_ALIGN_RIGHT )

    -- Category Tabs
    local tabY = winY + titleH + 10
    local tabCount = #categoriesOrder
    local tabW = math.floor( ( winW - 20 ) / tabCount )
    local tabH = 32

    for i, catKey in ipairs( categoriesOrder ) do
        local catData = Splitscreen.SpawnCatalog[catKey]
        local isSelected = ( i == mState.categoryIndex )
        local tx = winX + 10 + ( ( i - 1 ) * tabW )

        local tabBg = isSelected and slotCol or Color( 32, 36, 46 )
        draw.RoundedBox( 4, tx + 2, tabY, tabW - 4, tabH, tabBg )
        local tabTextCol = isSelected and Color( 255, 255, 255 ) or Color( 160, 160, 160 )
        draw.SimpleText( string.upper( catData.name ), "Splitscreen_SmallLabel", tx + ( tabW / 2 ), tabY + 9, tabTextCol, TEXT_ALIGN_CENTER )
    end

    -- Item Grid
    local currentCatKey = categoriesOrder[mState.categoryIndex]
    local currentCatData = Splitscreen.SpawnCatalog[currentCatKey]
    local items = currentCatData and currentCatData.items or {}

    local gridX = winX + 14
    local gridY = tabY + tabH + 14
    local gridW = winW - 28
    local gridH = winH - ( gridY - winY ) - 44

    local cols = 3
    local itemCardW = math.floor( ( gridW - ( ( cols - 1 ) * 10 ) ) / cols )
    local itemCardH = 46

    for i, item in ipairs( items ) do
        local col = ( ( i - 1 ) % cols )
        local row = math.floor( ( i - 1 ) / cols )
        local ix = gridX + ( col * ( itemCardW + 10 ) )
        local iy = gridY + ( row * ( itemCardH + 8 ) )

        if ( iy + itemCardH <= winY + winH - 40 ) then
            local isItemSel = ( i == mState.itemIndex )
            local cardBg = isItemSel and Color( 45, 52, 68 ) or Color( 28, 32, 40 )
            draw.RoundedBox( 6, ix, iy, itemCardW, itemCardH, cardBg )

            if ( isItemSel ) then
                surface.SetDrawColor( slotCol )
                surface.DrawOutlinedRect( ix, iy, itemCardW, itemCardH, 2 )
            end

            -- Item Text
            draw.SimpleText( item.name, "Splitscreen_Badge", ix + 12, iy + 14, isItemSel and color_white or Color( 200, 200, 200 ) )
        end
    end

    -- Bottom Action Bar
    local botY = winY + winH - 32
    draw.SimpleText( "PRO TIP: Hold [BACK] to keep menu open. Release to play immediately.", "Splitscreen_SmallLabel", winX + 16, botY, Color( 140, 140, 140 ) )
end

-- Render Spawn Menu in HUDPaint if active for that slot
hook.Add( "HUDPaint", "Splitscreen_RenderSpawnMenus", function()
    for slot = 1, Splitscreen.MaxSlots do
        local state = Splitscreen.InputStates[slot]
        if ( state and state.spawnmenu_open and Splitscreen.IsSlotActive( slot ) ) then
            local vp = Splitscreen.CachedViewports[slot] or Splitscreen.CalculateViewport( slot, Splitscreen.GetActivePlayerCount(), Splitscreen.LAYOUT_GRID )
            Splitscreen.DrawSlotSpawnMenu( slot, vp )
        end
    end
end )

