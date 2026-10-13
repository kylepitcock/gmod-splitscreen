--[[
    Splitscreen Co-op Mod for Garry's Mod
    Main Menu Console Lobby System (Menu Realm)
    Allows effortless, console-style 4-player splitscreen setup directly from GMod's Main Menu.
--]]

local HasXInput = false
local ok, _ = pcall( require, "xinput" )
if ( ok and _G.xinput ) then
    HasXInput = true
end

-- Playermodels Catalog for Menu Preview
local MenuModels = {
    { name = "Citizen (Male 07)",   model = "models/player/group01/male_07.mdl" },
    { name = "Citizen (Male 09)",   model = "models/player/group01/male_09.mdl" },
    { name = "Citizen (Female 02)", model = "models/player/group01/female_02.mdl" },
    { name = "Rebel Fighter",       model = "models/player/group03/male_07.mdl" },
    { name = "Combine Soldier",     model = "models/player/combine_soldier.mdl" },
    { name = "Combine Guard",       model = "models/player/combine_soldier_prisonguard.mdl" },
    { name = "Combine Elite",       model = "models/player/combine_super_soldier.mdl" },
    { name = "Metrocop (Police)",   model = "models/player/police.mdl" },
    { name = "Barney",              model = "models/player/barney.mdl" },
    { name = "Alyx",                model = "models/player/alyx.mdl" },
    { name = "Dr. Kleiner",         model = "models/player/kleiner.mdl" },
    { name = "G-Man",               model = "models/player/gman_high.mdl" },
    { name = "Chell",               model = "models/player/chell.mdl" },
    { name = "Zombie",              model = "models/player/zombie_classic.mdl" }
}

local SlotColors = {
    [1] = Color( 0, 160, 255 ),
    [2] = Color( 255, 130, 0 ),
    [3] = Color( 46, 204, 113 ),
    [4] = Color( 175, 75, 255 )
}

-- Load or Create Default Config
local function GetMenuConfig()
    local raw = file.Read( "splitscreen_config.json", "DATA" )
    if ( raw and raw ~= "" ) then
        local t = util.JSONToTable( raw )
        if ( t ) then return t end
    end

    return {
        enabled = true,
        player_count = 2,
        layout = 1, -- Horizontal
        p1_use_gamepad = false,
        deadzone = 0.18,
        look_sensitivity_x = 2.5,
        look_sensitivity_y = 2.0,
        invert_y = false,
        slots = {
            [1] = { active = true,  name = "Player 1", model = "models/player/group01/male_07.mdl", color = Vector( 0.0, 0.6, 1.0 ) },
            [2] = { active = true,  name = "Player 2", model = "models/player/group01/male_09.mdl", color = Vector( 1.0, 0.5, 0.0 ) },
            [3] = { active = false, name = "Player 3", model = "models/player/combine_soldier.mdl", color = Vector( 0.2, 0.8, 0.4 ) },
            [4] = { active = false, name = "Player 4", model = "models/player/police.mdl",          color = Vector( 0.7, 0.3, 1.0 ) }
        }
    }
end

-- Open the Console Splitscreen Lobby Window
function OpenSplitscreenLobby()
    if ( IsValid( pnlSplitscreenLobby ) ) then
        pnlSplitscreenLobby:Remove()
    end

    local cfg = GetMenuConfig()

    local frame = vgui.Create( "DFrame" )
    frame:SetSize( math.min( 1100, ScrW() - 40 ), math.min( 720, ScrH() - 40 ) )
    frame:Center()
    frame:SetTitle( "" )
    frame:MakePopup()
    pnlSplitscreenLobby = frame

    frame.Paint = function( s, w, h )
        -- Dark console aesthetic background
        draw.RoundedBox( 12, 0, 0, w, h, Color( 18, 20, 26, 253 ) )

        -- Header
        draw.RoundedBoxEx( 12, 0, 0, w, 56, Color( 25, 29, 38, 255 ), true, true, false, false )
        draw.RoundedBox( 0, 0, 54, w, 2, Color( 0, 160, 255, 255 ) )

        draw.SimpleText( "🎮 SPLITSCREEN CO-OP LOBBY", "DermaLarge", 24, 12, color_white )
        draw.SimpleText( "Up to 4 Players on One Screen • Full Gamepad Support • Equal Abilities", "DermaDefault", 480, 22, Color( 160, 160, 160 ) )
    end

    local pnlContent = vgui.Create( "DPanel", frame )
    pnlContent:Dock( FILL )
    pnlContent:DockMargin( 14, 14, 14, 14 )
    pnlContent.Paint = function() end

    -- 4 Player Cards Container
    local pnlCards = vgui.Create( "DPanel", pnlContent )
    pnlCards:Dock( TOP )
    pnlCards:SetTall( 420 )
    pnlCards.Paint = function() end

    local cardW = math.floor( ( frame:GetWide() - 68 ) / 4 )
    local cardH = 410

    local slotCards = {}

    for slot = 1, 4 do
        local slotData = cfg.slots[slot] or { active = ( slot <= 2 ), name = "Player " .. slot, model = MenuModels[1].model }
        local slotCol = SlotColors[slot]

        local card = vgui.Create( "DPanel", pnlCards )
        card:SetPos( ( slot - 1 ) * ( cardW + 10 ), 0 )
        card:SetSize( cardW, cardH )
        slotCards[slot] = card

        card.Paint = function( s, w, h )
            local isActive = slotData.active
            local bg = isActive and Color( 26, 30, 40 ) or Color( 16, 18, 24 )
            draw.RoundedBox( 10, 0, 0, w, h, bg )

            -- Slot Header Banner
            draw.RoundedBoxEx( 10, 0, 0, w, 36, isActive and slotCol or Color( 35, 38, 48 ), true, true, false, false )
            draw.SimpleText( "PLAYER " .. slot, "DermaDefaultBold", w / 2, 9, color_white, TEXT_ALIGN_CENTER )

            -- Status Banner
            local statusText = isActive and "READY TO PLAY" or "PRESS [A] OR CLICK TO JOIN"
            local statusCol = isActive and Color( 46, 204, 113 ) or Color( 130, 130, 130 )
            draw.SimpleText( statusText, "DermaDefault", w / 2, 44, statusCol, TEXT_ALIGN_CENTER )

            -- Controller device label
            local devText = ( slot == 1 and not cfg.p1_use_gamepad ) and "Keyboard & Mouse" or ( "Gamepad #" .. ( cfg.p1_use_gamepad and ( slot - 1 ) or ( slot - 2 ) ) )
            draw.SimpleText( devText, "DermaDefault", w / 2, 60, Color( 180, 180, 180 ), TEXT_ALIGN_CENTER )

            surface.SetDrawColor( isActive and slotCol or Color( 40, 44, 54 ) )
            surface.DrawOutlinedRect( 0, 0, w, h, 1 )
        end

        -- 3D Interactive Model Preview
        local mdl = vgui.Create( "DModelPanel", card )
        mdl:SetPos( 10, 80 )
        mdl:SetSize( cardW - 20, 190 )
        mdl:SetModel( slotData.model or MenuModels[1].model )
        mdl:SetFOV( 34 )
        function mdl:LayoutEntity( ent )
            ent:SetAngles( Angle( 0, CurTime() * 20, 0 ) )
        end

        -- Nickname Entry
        local txtNick = vgui.Create( "DTextEntry", card )
        txtNick:SetPos( 10, 280 )
        txtNick:SetSize( cardW - 20, 24 )
        txtNick:SetText( slotData.name or ( "Player " .. slot ) )
        txtNick.OnChange = function( s )
            slotData.name = s:GetText()
        end

        -- Model Selector Dropdown
        local cmbModel = vgui.Create( "DComboBox", card )
        cmbModel:SetPos( 10, 312 )
        cmbModel:SetSize( cardW - 20, 24 )
        for _, m in ipairs( MenuModels ) do
            cmbModel:AddChoice( m.name, m.model )
        end
        cmbModel:SetValue( "Change Playermodel" )
        cmbModel.OnSelect = function( _, idx, val, data )
            mdl:SetModel( data )
            slotData.model = data
        end

        -- Toggle Join / Leave Button
        local btnJoin = vgui.Create( "DButton", card )
        btnJoin:SetPos( 10, 350 )
        btnJoin:SetSize( cardW - 20, 42 )
        btnJoin.UpdateText = function()
            btnJoin:SetText( slotData.active and "LEAVE SLOT" or "JOIN MATCH" )
            btnJoin:SetTextColor( color_white )
        end
        btnJoin:UpdateText()
        btnJoin.Paint = function( s, w, h )
            local col = slotData.active and Color( 231, 76, 60 ) or Color( 46, 204, 113 )
            draw.RoundedBox( 6, 0, 0, w, h, col )
        end
        btnJoin.DoClick = function()
            if ( slot == 1 ) then
                surface.PlaySound( "buttons/button10.wav" )
                return
            end
            slotData.active = not slotData.active
            btnJoin:UpdateText()
            surface.PlaySound( "garrysmod/ui_click.wav" )
        end
    end

    -- Bottom Controls & Match Options
    local pnlBottom = vgui.Create( "DPanel", pnlContent )
    pnlBottom:Dock( BOTTOM )
    pnlBottom:SetTall( 140 )
    pnlBottom.Paint = function() end

    -- Map Selection
    local lblMap = vgui.Create( "DLabel", pnlBottom )
    lblMap:SetPos( 10, 10 )
    lblMap:SetText( "Select Sandbox Map:" )
    lblMap:SetFont( "DermaDefaultBold" )
    lblMap:SizeToContents()

    local cmbMap = vgui.Create( "DComboBox", pnlBottom )
    cmbMap:SetPos( 10, 32 )
    cmbMap:SetSize( 260, 30 )

    -- Populate installed maps
    local maps = file.Find( "maps/*.bsp", "GAME" )
    local foundDefault = false
    for _, mapFile in ipairs( maps ) do
        local mapName = string.StripExtension( mapFile )
        cmbMap:AddChoice( mapName, mapName )
        if ( mapName == "gm_construct" ) then foundDefault = true end
    end
    cmbMap:SetValue( foundDefault and "gm_construct" or ( maps[1] and string.StripExtension( maps[1] ) or "gm_flatgrass" ) )

    -- Screen Split Layout Dropdown
    local lblLayout = vgui.Create( "DLabel", pnlBottom )
    lblLayout:SetPos( 290, 10 )
    lblLayout:SetText( "2-Player Split Orientation:" )
    lblLayout:SetFont( "DermaDefaultBold" )
    lblLayout:SizeToContents()

    local cmbLayout = vgui.Create( "DComboBox", pnlBottom )
    cmbLayout:SetPos( 290, 32 )
    cmbLayout:SetSize( 240, 30 )
    cmbLayout:AddChoice( "Top / Bottom (Horizontal)", 1 )
    cmbLayout:AddChoice( "Left / Right (Vertical)", 2 )
    cmbLayout:SetValue( cfg.layout == 2 and "Left / Right (Vertical)" or "Top / Bottom (Horizontal)" )
    cmbLayout.OnSelect = function( _, idx, val, data )
        cfg.layout = data
    end

    -- P1 Gamepad Checkbox
    local chkP1 = vgui.Create( "DCheckBoxLabel", pnlBottom )
    chkP1:SetPos( 10, 78 )
    chkP1:SetText( "Player 1 uses Gamepad (Controller 0) instead of Keyboard & Mouse" )
    chkP1:SetValue( cfg.p1_use_gamepad )
    chkP1:SizeToContents()
    chkP1.OnChange = function( _, val )
        cfg.p1_use_gamepad = val
    end

    -- Launch Match Button (Console-style Big Green Button)
    local btnLaunch = vgui.Create( "DButton", pnlBottom )
    btnLaunch:SetPos( pnlBottom:GetWide() - 320, 20 )
    btnLaunch:Dock( RIGHT )
    btnLaunch:SetWide( 280 )
    btnLaunch:SetText( "▶ START SPLITSCREEN MATCH" )
    btnLaunch:SetFont( "DermaLarge" )
    btnLaunch:SetTextColor( color_white )
    btnLaunch.Paint = function( s, w, h )
        local pulse = math.abs( math.sin( CurTime() * 4 ) ) * 20
        draw.RoundedBox( 8, 0, 0, w, h, Color( 39 + pulse, 174, 96 + pulse ) )
    end
    btnLaunch.DoClick = function()
        -- Count active players
        local count = 0
        for s = 1, 4 do
            if ( cfg.slots[s].active ) then
                count = count + 1
            end
        end
        cfg.player_count = math.max( 2, count )
        cfg.enabled = true

        -- Save configuration to data/splitscreen_config.json
        local json = util.TableToJSON( cfg, true )
        file.Write( "splitscreen_config.json", json )

        local selectedMap = cmbMap:GetSelected() or "gm_construct"

        surface.PlaySound( "ui/buttonclick.wav" )
        frame:Remove()

        -- Launch GMod Listen Server with configured player slots!
        print( "[Splitscreen Co-op] Starting local session on " .. selectedMap .. " with " .. cfg.player_count .. " slots..." )
        RunConsoleCommand( "maxplayers", tostring( math.max( 4, cfg.player_count ) ) )
        RunConsoleCommand( "sv_lan", "1" )
        RunConsoleCommand( "p2p_enabled", "0" )
        RunConsoleCommand( "map", selectedMap )
    end
end

-- Create the Prominent "4-PLAYER SPLITSCREEN" Button on Garry's Mod Main Menu
local function CreateMainMenuSplitscreenButton()
    if ( IsValid( pnlMenuSplitscreenButton ) ) then return end

    local btn = vgui.Create( "DButton" )
    btn:SetSize( 280, 50 )
    -- Position near top right of main menu screen
    btn:SetPos( ScrW() - 310, 30 )
    btn:SetText( "🎮 SPLITSCREEN CO-OP" )
    btn:SetFont( "DermaDefaultBold" )
    btn:SetTextColor( color_white )
    pnlMenuSplitscreenButton = btn

    btn.Paint = function( s, w, h )
        local hover = s:IsHovered()
        local bg = hover and Color( 0, 180, 255, 240 ) or Color( 22, 26, 34, 230 )
        draw.RoundedBox( 8, 0, 0, w, h, bg )
        draw.RoundedBox( 8, 0, h - 3, w, 3, Color( 0, 160, 255 ) )
        surface.SetDrawColor( 255, 255, 255, hover and 60 or 20 )
        surface.DrawOutlinedRect( 0, 0, w, h, 1 )
    end

    btn.DoClick = function()
        surface.PlaySound( "garrysmod/ui_click.wav" )
        OpenSplitscreenLobby()
    end
end

-- Hook into Menu Draw & Initialization
hook.Add( "DrawOverlay", "Splitscreen_MenuButtonDrawer", function()
    if ( not IsValid( pnlMenuSplitscreenButton ) ) then
        CreateMainMenuSplitscreenButton()
    end
end )

print( "[Splitscreen Co-op] Main Menu Integration loaded successfully." )
