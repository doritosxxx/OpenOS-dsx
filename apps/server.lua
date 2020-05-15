-- настройки --
local port --= 6204
local server_port --= 6205
local wakemessage --= "server_wake81301287"
-----------------------------------
local component = require("component")
local event = require("event")
local modem = component.modem
local serialization = require("serialization")
local fs = require("filesystem")

function file_read( path )
	local file = io.open( path, "r" )
	local data = file:read()
	file:close()
	return data
end
	
function file_write( path, data )
	local file, reason = io.open( path, "w" )
	if file == nil then
		error(reason)
	end
	file:write( data )
	file:close()
end

local index = "/home/db/"
if not fs.exists( index ) then
	fs.makeDirectory( index )
end

local token = file_read("/home/token")
modem.open( port )
modem.open( server_port )

local Server = {}
function Server:new( )
	local obj = {}

	function obj:query( type, params )
		if params.token ~= token then
			return "error"
		--elseif type == "" then
		--	return self:<type>( params )
		end

		return "error"
	end

	setmetatable(obj, self)
	self.__index = self
	return obj
end

modem.broadcast( server_port, wakemessage )

local server = Server:new()

while true do 
	local _, _, from, port, _, type, params = event.pullFiltered(function( name, _, _, _port )
		return name == "modem_message" and ( _port == port or _port == server_port )
	end)
	if port == server_port then
		io.write(string.format( "from %s: connection request\n\n", from ))
		modem.send( from, server_port, "server_connect" )
	else 
		unserialized = serialization.unserialize( params )
		io.write(string.format( "from %s: %s\nparams: %s\n", from, type, params ))
		local response = server:query( type, unserialized )
		io.write(string.format( "response: %s\n\n", response ))
		modem.send( from, port, tostring(response))
	end
end