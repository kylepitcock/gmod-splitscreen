--[[
    Splitscreen Co-op Mod for Garry's Mod
    Autorun Entrypoint (Shared)
--]]

Splitscreen = Splitscreen or {}

-- Send files to client
AddCSLuaFile( "splitscreen/shared/sh_config.lua" )
AddCSLuaFile( "splitscreen/client/cl_input.lua" )
AddCSLuaFile( "splitscreen/client/cl_render.lua" )
AddCSLuaFile( "splitscreen/client/cl_hud.lua" )
AddCSLuaFile( "splitscreen/client/cl_spawnmenu.lua" )
AddCSLuaFile( "splitscreen/client/cl_weaponwheel.lua" )
AddCSLuaFile( "splitscreen/client/cl_lobby.lua" )

-- Include shared configuration
include( "splitscreen/shared/sh_config.lua" )

print( "[Splitscreen Co-op] Loaded shared configuration v" .. Splitscreen.Version )
