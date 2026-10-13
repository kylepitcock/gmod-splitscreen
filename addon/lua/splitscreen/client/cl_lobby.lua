--[[
    Splitscreen Co-op Mod for Garry's Mod
    In-Game Console Splitscreen Manager & Settings Menu
--]]

Splitscreen = Splitscreen or {}
Splitscreen.Config = Splitscreen.LoadConfig()

-- Request to Join a Slot
function Splitscreen.RequestJoinSlot( slot )
    net.Start( "Splitscreen_DropIn" )
        net.WriteUInt( slot, 3 )
        net.WriteBool( true ) -- Join
    net.SendToServer()
end

-- Request to Leave a Slot
function Splitscreen.RequestLeaveSlot( slot )
    net.Start( "Splitscreen_DropIn" )
        net.WriteUInt( slot, 3 )
        net.WriteBool( false ) -- Leave
    net.SendToServer()
end

-- Sync State from Server
net.Receive( "Splitscreen_SyncState", function()
    local count = net.ReadUInt( 3 )
    for i = 1, Splitscreen.MaxSlots do
        Splitscreen.ActiveSlots[i] = false
    end

    for _ = 1, count do
        local slot = net.ReadUInt( 3 )
        Splitscreen.ActiveSlots[slot] = true
    end

    local layout = net.ReadUInt( 3 )
    Splitscreen.Config.layout = layout

    print( "[Splitscreen Co-op] Synced slots with server. Active slots: " .. count )
end )

-- Open the In-Game Console Splitscreen Manager
function Splitscreen.OpenManagerMenu()
    if ( IsValid( Splitscreen.ManagerFrame ) ) then
        Splitscreen.ManagerFrame:Remove()
    end

    local cfg = Splitscreen.Config or Splitscreen.GetDefaultConfig()

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( 780, 520 )
    frame:Center()
    frame:SetTitle( "" )
    frame:SetDraggable( true )
    frame:MakePopup()
    Splitscreen.ManagerFrame = frame

    frame.Paint = function( s, w, h )
        draw.RoundedBox( 10, 0, 0, w, h, Color( 20, 23, 29, 252 ) )
        -- Title bar
        draw.RoundedBoxEx( 10, 0, 0, w, 44, Color( 28, 32, 42, 255 ), true, true, false, false )
        draw.RoundedBox( 0, 0, 42, w, 2, Color( 0, 160, 255, 255 ) )

        draw.SimpleText( "🎮 SPLITSCREEN CO-OP MANAGER", "Splitscreen_Badge", 18, 14, color_white )
        draw.SimpleText( "Configure 4-Player Local Splitscreen & Controller Options", "Splitscreen_SmallLabel", 260, 16, Color( 160, 160, 160 ) )
    end

    -- Tab Sheet
    local sheet = vgui.Create( "DPropertySheet", frame )
    sheet:Dock( FILL )
    sheet:DockMargin( 10, 10, 10, 10 )

    -- TAB 1: PLAYER SLOTS (Console Lobby Style)
    local pnlSlots = vgui.Create( "DPanel", sheet )
    pnlSlots.Paint = function() end
    sheet:AddSheet( "Player Slots", pnlSlots, "icon16/group.png" )

    local cardW = 180
    local cardH = 390

    for slot = 1, Splitscreen.MaxSlots do
        local card = vgui.Create( "DPanel", pnlSlots )
        card:SetPos( 10 + ( ( slot - 1 ) * ( cardW + 8 ) ), 10 )
        card:SetSize( cardW, cardH )

        local slotCol = Splitscreen.SlotColors[slot]
        card.Paint = function( s, w, h )
            local isActive = Splitscreen.IsSlotActive( slot )
            local bg = isActive and Color( 26, 30, 38 ) or Color( 18, 20, 25 )
            draw.RoundedBox( 8, 0, 0, w, h, bg )
            -- Header
            draw.RoundedBoxEx( 8, 0, 0, w, 32, isActive and slotCol or Color( 35, 38, 46 ), true, true, false, false )
            draw.SimpleText( "PLAYER " .. slot, "Splitscreen_Badge", w / 2, 8, color_white, TEXT_ALIGN_CENTER )

            -- Status
            local statusStr = isActive and "ACTIVE" or "DISCONNECTED"
            local statusCol = isActive and Color( 46, 204, 113 ) or Color( 140, 140, 140 )
            draw.SimpleText( statusStr, "Splitscreen_SmallLabel", w / 2, 40, statusCol, TEXT_ALIGN_CENTER )

            -- Outline
            surface.SetDrawColor( isActive and slotCol or Color( 45, 48, 56 ) )
            surface.DrawOutlinedRect( 0, 0, w, h, 1 )
        end

        -- 3D Model Preview
        local mdlPanel = vgui.Create( "DModelPanel", card )
        mdlPanel:SetPos( 10, 60 )
        mdlPanel:SetSize( cardW - 20, 160 )
        local slotData = cfg.slots[slot] or {}
        local initialModel = slotData.model or "models/player/group01/male_07.mdl"
        mdlPanel:SetModel( initialModel )
        mdlPanel:SetFOV( 36 )
        function mdlPanel:LayoutEntity( Entity )
            Entity:SetAngles( Angle( 0, CurTime() * 25, 0 ) )
        end

        -- Model Selector Dropdown
        local modelCombo = vgui.Create( "DComboBox", card )
        modelCombo:SetPos( 10, 230 )
        modelCombo:SetSize( cardW - 20, 24 )
        for _, m in ipairs( Splitscreen.PlayerModels ) do
            modelCombo:AddChoice( m.name, m.model )
        end
        modelCombo:SetValue( "Choose Model" )
        modelCombo.OnSelect = function( _, idx, val, data )
            mdlPanel:SetModel( data )
            slotData.model = data
            Splitscreen.SaveConfig( cfg )
        end

        -- Join / Leave Toggle Button
        local btnToggle = vgui.Create( "DButton", card )
        btnToggle:SetPos( 10, 340 )
        btnToggle:SetSize( cardW - 20, 32 )
        btnToggle.UpdateText = function()
            local isActive = Splitscreen.IsSlotActive( slot )
            btnToggle:SetText( isActive and "DROP OUT" or "JOIN CO-OP" )
            btnToggle:SetTextColor( color_white )
        end
        btnToggle:UpdateText()
        btnToggle.Paint = function( s, w, h )
            local isActive = Splitscreen.IsSlotActive( slot )
            local col = isActive and Color( 231, 76, 60 ) or Color( 46, 204, 113 )
            draw.RoundedBox( 6, 0, 0, w, h, col )
        end
        btnToggle.DoClick = function()
            if ( slot == 1 ) then
                chat.AddText( slotCol, "[Splitscreen] Player 1 is the primary host and cannot be removed." )
                return
            end
            if ( Splitscreen.IsSlotActive( slot ) ) then
                Splitscreen.RequestLeaveSlot( slot )
            else
                Splitscreen.RequestJoinSlot( slot )
            end
            timer.Simple( 0.2, btnToggle.UpdateText )
        end
    end

    -- TAB 2: SCREEN LAYOUT & DISPLAY
    local pnlLayout = vgui.Create( "DPanel", sheet )
    pnlLayout.Paint = function() end
    sheet:AddSheet( "Screen Layout", pnlLayout, "icon16/application_double.png" )

    local lblLayout = vgui.Create( "DLabel", pnlLayout )
    lblLayout:SetPos( 20, 20 )
    lblLayout:SetText( "Select 2-Player Screen Split Orientation:" )
    lblLayout:SetFont( "Splitscreen_Badge" )
    lblLayout:SizeToContents()

    local btnHoriz = vgui.Create( "DButton", pnlLayout )
    btnHoriz:SetPos( 20, 50 )
    btnHoriz:SetSize( 220, 44 )
    btnHoriz:SetText( "Top / Bottom (Horizontal)" )
    btnHoriz.DoClick = function()
        cfg.layout = Splitscreen.LAYOUT_HORIZONTAL
        Splitscreen.SaveConfig( cfg )
        chat.AddText( Color( 0, 160, 255 ), "[Splitscreen] Set layout to Horizontal (Top/Bottom)." )
    end

    local btnVert = vgui.Create( "DButton", pnlLayout )
    btnVert:SetPos( 260, 50 )
    btnVert:SetSize( 220, 44 )
    btnVert:SetText( "Left / Right (Vertical)" )
    btnVert.DoClick = function()
        cfg.layout = Splitscreen.LAYOUT_VERTICAL
        Splitscreen.SaveConfig( cfg )
        chat.AddText( Color( 0, 160, 255 ), "[Splitscreen] Set layout to Vertical (Left/Right)." )
    end

    -- TAB 3: CONTROLLER & INPUT SETTINGS
    local pnlInput = vgui.Create( "DPanel", sheet )
    pnlInput.Paint = function() end
    sheet:AddSheet( "Controller Settings", pnlInput, "icon16/controller.png" )

    -- P1 Gamepad Checkbox
    local chkP1Gamepad = vgui.Create( "DCheckBoxLabel", pnlInput )
    chkP1Gamepad:SetPos( 20, 20 )
    chkP1Gamepad:SetText( "Player 1 uses Gamepad (Controller 0) instead of Keyboard & Mouse" )
    chkP1Gamepad:SetValue( cfg.p1_use_gamepad )
    chkP1Gamepad:SizeToContents()
    chkP1Gamepad.OnChange = function( _, val )
        cfg.p1_use_gamepad = val
        Splitscreen.SaveConfig( cfg )
    end

    -- Stick Deadzone Slider
    local sldDeadzone = vgui.Create( "DNumSlider", pnlInput )
    sldDeadzone:SetPos( 20, 60 )
    sldDeadzone:SetSize( 400, 30 )
    sldDeadzone:SetText( "Stick Deadzone" )
    sldDeadzone:SetMin( 0.05 )
    sldDeadzone:SetMax( 0.40 )
    sldDeadzone:SetDecimals( 2 )
    sldDeadzone:SetValue( cfg.deadzone or 0.18 )
    sldDeadzone.OnValueChanged = function( _, val )
        cfg.deadzone = val
        Splitscreen.SaveConfig( cfg )
    end

    -- Look Sensitivity X
    local sldSensX = vgui.Create( "DNumSlider", pnlInput )
    sldSensX:SetPos( 20, 100 )
    sldSensX:SetSize( 400, 30 )
    sldSensX:SetText( "Look Sensitivity (Horizontal)" )
    sldSensX:SetMin( 0.5 )
    sldSensX:SetMax( 6.0 )
    sldSensX:SetDecimals( 1 )
    sldSensX:SetValue( cfg.look_sensitivity_x or 2.5 )
    sldSensX.OnValueChanged = function( _, val )
        cfg.look_sensitivity_x = val
        Splitscreen.SaveConfig( cfg )
    end

    -- Look Sensitivity Y
    local sldSensY = vgui.Create( "DNumSlider", pnlInput )
    sldSensY:SetPos( 20, 140 )
    sldSensY:SetSize( 400, 30 )
    sldSensY:SetText( "Look Sensitivity (Vertical)" )
    sldSensY:SetMin( 0.5 )
    sldSensY:SetMax( 6.0 )
    sldSensY:SetDecimals( 1 )
    sldSensY:SetValue( cfg.look_sensitivity_y or 2.0 )
    sldSensY.OnValueChanged = function( _, val )
        cfg.look_sensitivity_y = val
        Splitscreen.SaveConfig( cfg )
    end

    -- Invert Y Checkbox
    local chkInvert = vgui.Create( "DCheckBoxLabel", pnlInput )
    chkInvert:SetPos( 20, 190 )
    chkInvert:SetText( "Invert Look Y-Axis" )
    chkInvert:SetValue( cfg.invert_y )
    chkInvert:SizeToContents()
    chkInvert.OnChange = function( _, val )
        cfg.invert_y = val
        Splitscreen.SaveConfig( cfg )
    end
end

concommand.Add( "splitscreen_menu", Splitscreen.OpenManagerMenu )

