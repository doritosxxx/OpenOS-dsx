local fs = require("filesystem")
local gpu = require("component").gpu
local term = require("term")
local event = require("event")
local Element = require("dsx_element")
local Workspace = require("dsx_workspace")
local serialization = require("serialization")

---------------

local tokenpath = "/home/data/token"
local autorunpath = "/home/data/autorun"
local adminspath = "/home/data/admins"
local token = ""
local color = {
	black = 0x222222,
	white = 0xdddddd,
	title = 0xffd700
}

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

function has( haystack, needle )
	for _, elem in ipairs( haystack ) do
		if elem == needle then
			return true
		end
	end
	return false
end


function run( app )
	local path = "/home/apps/" .. app .. ".lua"
	local app = require("dsx_exception"):new(loadfile(path))
	while 1 do
		app:run()
		os.sleep(0)
	end
end

function configure_admins()
	local admins = {}
	local action = {
		continue = 2
	}
	local WIDTH, HEIGHT = gpu.getResolution()
	local ws = Workspace:new()
	:add(
		Element.block( 0, 0, Element.INHERIT, Element.INHERIT, color.black, function(_, _, nickname)
			return nickname
		end)
		:add(
			Element.block( 0, Element.ALIGN_END, Element.INHERIT, 5, color.white, function()
				return action.continue
			end))
			:add(Element.text(Element.ALIGN_CENTER, Element.ALIGN_CENTER, "Продолжить", color.black)
		)
		:add(Element.text(Element.ALIGN_CENTER, 1, 
		"Нажмите на экран, чтобы назначить себя администратором", color.title))
		:add(Element.text(Element.ALIGN_CENTER, 2, "Администраторы:", color.white))
	)
	ws:draw()
	local offset = 4
	while true do
		local status = ws:pull()
		if status == action.continue then
			file_write( adminspath, serialization.serialize(admins) )
			break
		end
		if status ~= nil then
			local nickname = status
			if not has(admins, nickname) then
				table.insert( admins, nickname )
				Workspace:new()
				:add(Element.text(Element.ALIGN_CENTER, offset, nickname, color.white, color.black))
				:draw()
				offset = offset + 1
			end
		end
	end
end

function get_random_token()
	local token = ""
	local symbols = "0123456789qwertyuiopasdfghjklzxcvbnm"
	for i=1,12 do
		local index = math.random( 1, #symbols )
		token = token .. symbols:sub(index, index)
	end
	return token
end

function configure_token()
	local ws = Workspace:new()
	:add(
		Element.block(0,0, Element.INHERIT, Element.INHERIT, color.black)
		:add(Element.text(Element.ALIGN_CENTER, 1, "Введите токен", color.title))
		:add(Element.text(Element.ALIGN_CENTER, 3, "Токен нужен для соединения компьютеров в сеть", color.white))
		:add(Element.text(Element.ALIGN_CENTER, 4, "Введите любую строку, например, " .. get_random_token(), color.white))
	):draw()

	term.setCursor( 4,7 )
	term.write( "Токен: " )
	token = term.read( nil, nil, nil, "*" )

	file_write( tokenpath, token )
end

if not fs.exists("/home/data/") then
	fs.makeDirectory("/home/data/")
end

if not fs.exists(adminspath) then
	configure_admins()
end

if not fs.exists(tokenpath) then
	configure_token()
else 
	token = file_read( tokenpath )
end

local wsclear = Workspace:new()
:add(Element.block(0,0,Element.INHERIT, Element.INHERIT, color.black))
wsclear:draw()

if fs.exists(autorunpath) then
	local autorun = file_read( autorunpath, "r" )
	run(autorun)
	return 
end 

---------------

local apps = {}
local apps_assoc = {}

io.write("Доступные приложения:\n")
for file in fs.list('/home/apps') do
	local name = file:gsub(".lua", "")
	table.insert(apps, name)
end

table.sort(apps)

local i = 1
for j, name in pairs(apps) do
	apps_assoc[name] = j
	local color, mode = gpu.setForeground(0x00ff00)
	io.write(string.format(" [%i] ", i))
	gpu.setForeground(color, mode)
	io.write(name .. "\n")
	i = i+1
end

local color, mode = gpu.setForeground(0x00ff00)
io.write(string.format(" [%i] ", i))
gpu.setForeground(color, mode)
io.write("Перейти в терминал\n")

local id, flag = 0, nil
while 1 do
	io.write("Выберите приложение для установки: ")
	line = io.read()
	local i = 1
	for token in line:gmatch("[^%s]+") do
		if i == 1 then
			id = token
		elseif i == 2 then
			flag = token
		else 
			break
		end
		i = i + 1
	end
	
	if(apps_assoc[id] ~= nil) then
		id = apps_assoc[id]
		break
	end
	id = tonumber(id)
	if id ~= nil and 1 <= id and id <= 1+#apps then
		break
	end
	io.write(string.format("Приложение не найдено. Введите число от 1 до %i или название приложения\n", 1+#apps))
end

if id == 1+#apps then
	return 
end

if flag == "-a" then
	f = io.open( autorunpath, "w" )
	f:write(tostring(apps[id]))
	f:close()
end

run(apps[id])

