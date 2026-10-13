--[[
    Splitscreen Co-op Mod for Garry's Mod
    Client Viewport Renderer (Multi-Player Camera & Screen Splitting)
--]]

Splitscreen = Splitscreen or {}
Splitscreen.SlotEntities = {}
Splitscreen.ActiveSlots = { [1] = true, [2] = false, [3] = false, [4] = false }
Splitscreen.CachedViewports = {}

-- Check if a specific slot is active
function Splitscreen.IsSlotActive( slot )
    return Splitscreen.ActiveSlots[slot] == true
end

-- Get Count of currently active player slots
function Splitscreen.GetActivePlayerCount()
    local count = 0
    for i = 1, Splitscreen.MaxSlots do
        if ( Splitscreen.ActiveSlots[i] ) then
            count = count + 1
        end
    end
    return math.max( 1, count )
end

-- Get Player Entity associated with a slot
function Splitscreen.GetSlotEntity( slot )
    if ( slot == 1 ) then
        return LocalPlayer()
    end
    return Splitscreen.SlotEntities[slot]
end

-- Synchronize Slot Entities by NWInt
function Splitscreen.UpdateSlotEntities()
    local players = player.GetAll()
    for _, ply in ipairs( players ) do
        local slot = ply:GetNWInt( "SplitscreenSlot", 0 )
        if ( slot >= 2 and slot <= Splitscreen.MaxSlots ) then
            Splitscreen.SlotEntities[slot] = ply
        end
    end
end
hook.Add( "Think", "Splitscreen_SyncEntities", Splitscreen.UpdateSlotEntities )

-- Calculate Viewport Bounds for a slot based on active count and layout
function Splitscreen.CalculateViewport( slot, activeCount, layout )
    local sw = ScrW()
    local sh = ScrH()

    if ( activeCount == 1 ) then
        return { x = 0, y = 0, w = sw, h = sh }
    elseif ( activeCount == 2 ) then
        if ( layout == Splitscreen.LAYOUT_VERTICAL ) then
            -- Left / Right split
            local halfW = math.floor( sw / 2 )
            if ( slot == 1 ) then
                return { x = 0, y = 0, w = halfW, h = sh }
            else
                return { x = halfW, y = 0, w = sw - halfW, h = sh }
            end
        else
            -- Top / Bottom split (default)
            local halfH = math.floor( sh / 2 )
            if ( slot == 1 ) then
                return { x = 0, y = 0, w = sw, h = halfH }
            else
                return { x = 0, y = halfH, w = sw, h = sh - halfH }
            end
        end
    elseif ( activeCount == 3 ) then
        local halfW = math.floor( sw / 2 )
        local halfH = math.floor( sh / 2 )
        if ( layout == Splitscreen.LAYOUT_3P_BOTTOM ) then
            -- P1 Top Full, P2 Bottom Left, P3 Bottom Right
            if ( slot == 1 ) then
                return { x = 0, y = 0, w = sw, h = halfH }
            elseif ( slot == 2 ) then
                return { x = 0, y = halfH, w = halfW, h = sh - halfH }
            else
                return { x = halfW, y = halfH, w = sw - halfW, h = sh - halfH }
            end
        else
            -- P1 Top Left, P2 Top Right, P3 Bottom Full
            if ( slot == 1 ) then
                return { x = 0, y = 0, w = halfW, h = halfH }
            elseif ( slot == 2 ) then
                return { x = halfW, y = 0, w = sw - halfW, h = halfH }
            else
                return { x = 0, y = halfH, w = sw, h = sh - halfH }
            end
        end
    else
        -- 4 Players: 2x2 Quadrant Grid
        local halfW = math.floor( sw / 2 )
        local halfH = math.floor( sh / 2 )
        if ( slot == 1 ) then
            return { x = 0, y = 0, w = halfW, h = halfH }
        elseif ( slot == 2 ) then
            return { x = halfW, y = 0, w = sw - halfW, h = halfH }
        elseif ( slot == 3 ) then
            return { x = 0, y = halfH, w = halfW, h = sh - halfH }
        else
            return { x = halfW, y = halfH, w = sw - halfW, h = sh - halfH }
        end
    end
end

-- Draw dividing borders between player viewports
local function DrawViewportDividers( activeCount, layout )
    local sw = ScrW()
    local sh = ScrH()
    local borderColor = Color( 25, 25, 30, 255 )
    local accentColor = Color( 0, 160, 255, 180 )
    local borderThickness = 3

    surface.SetDrawColor( borderColor )

    if ( activeCount == 2 ) then
        if ( layout == Splitscreen.LAYOUT_VERTICAL ) then
            local midX = math.floor( sw / 2 )
            surface.DrawRect( midX - 1, 0, borderThickness, sh )
        else
            local midY = math.floor( sh / 2 )
            surface.DrawRect( 0, midY - 1, sw, borderThickness )
        end
    elseif ( activeCount == 3 ) then
        local halfH = math.floor( sh / 2 )
        local halfW = math.floor( sw / 2 )
        -- Horizontal divider
        surface.DrawRect( 0, halfH - 1, sw, borderThickness )
        -- Vertical divider
        if ( layout == Splitscreen.LAYOUT_3P_BOTTOM ) then
            surface.DrawRect( halfW - 1, halfH, borderThickness, sh - halfH )
        else
            surface.DrawRect( halfW - 1, 0, borderThickness, halfH )
        end
    elseif ( activeCount >= 4 ) then
        local halfW = math.floor( sw / 2 )
        local halfH = math.floor( sh / 2 )
        surface.DrawRect( 0, halfH - 1, sw, borderThickness )
        surface.DrawRect( halfW - 1, 0, borderThickness, sh )
    end
end

-- Main Render Scene Hook
hook.Add( "RenderScene", "Splitscreen_MasterRenderer", function( origin, angles, fov )
    local activeCount = Splitscreen.GetActivePlayerCount()

    -- If only 1 player is active and no co-op is enabled, let engine handle rendering normally
    if ( activeCount <= 1 and not Splitscreen.ForcedSingleSplit ) then
        return false
    end

    local cfg = Splitscreen.Config or Splitscreen.GetDefaultConfig()
    local layout = cfg.layout or Splitscreen.LAYOUT_GRID

    -- Render each active player's viewport
    for slot = 1, Splitscreen.MaxSlots do
        if ( Splitscreen.IsSlotActive( slot ) ) then
            local ply = Splitscreen.GetSlotEntity( slot )
            local vp = Splitscreen.CalculateViewport( slot, activeCount, layout )
            Splitscreen.CachedViewports[slot] = vp

            if ( IsValid( ply ) and ply:Alive() ) then
                local camOrigin = ply:EyePos()
                local camAngles = ( slot == 1 ) and ply:EyeAngles() or Splitscreen.InputStates[slot].viewangles
                local isThirdperson = Splitscreen.InputStates[slot].thirdperson

                -- Thirdperson Camera Calculation
                if ( isThirdperson ) then
                    local targetDist = 90
                    local camOffset = -camAngles:Forward() * targetDist + camAngles:Right() * 20 + Vector( 0, 0, 10 )
                    local tr = util.TraceHull( {
                        start = camOrigin,
                        endpos = camOrigin + camOffset,
                        filter = ply,
                        mins = Vector( -6, -6, -6 ),
                        maxs = Vector( 6, 6, 6 ),
                        mask = MASK_SOLID_BRUSHONLY
                    } )
                    camOrigin = tr.HitPos + tr.HitNormal * 4
                end

                -- Call render.RenderView for this player's quadrant
                render.RenderView( {
                    origin          = camOrigin,
                    angles          = camAngles,
                    x               = vp.x,
                    y               = vp.y,
                    w               = vp.w,
                    h               = vp.h,
                    fov             = fov or 90,
                    aspectratio     = vp.w / vp.h,
                    drawhud         = false,
                    drawviewmodel   = ( slot == 1 and not isThirdperson )
                } )
            else
                -- Death or Spectating View
                local specPos = IsValid( ply ) and ( ply:GetPos() + Vector( 0, 0, 100 ) ) or ( origin or Vector( 0, 0, 100 ) )
                local specAng = Angle( 35, CurTime() * 10, 0 )
                render.RenderView( {
                    origin          = specPos,
                    angles          = specAng,
                    x               = vp.x,
                    y               = vp.y,
                    w               = vp.w,
                    h               = vp.h,
                    fov             = 90,
                    aspectratio     = vp.w / vp.h,
                    drawhud         = false,
                    drawviewmodel   = false
                } )
            end
        end
    end

    -- Draw dividing lines
    cam.Start2D()
        DrawViewportDividers( activeCount, layout )
    cam.End2D()

    -- Returning true overrides standard single-camera rendering
    return true
end )
