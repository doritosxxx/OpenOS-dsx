local CONFIG = {
	name = "dsx template project"
}

local modules = {
	"dsx_buttons", "dsx_exception", "dsx_workspace", "event", "dsx_element"
}
local apps = {
	"reinstall","server"
}
local github = "https://raw.githubusercontent.com/doritosxxx/OpenOS-dsx/master"

local component = require("component")
if not component.isAvailable("internet") then
    io.stderr:write("An internet card is required!")
    return
end
local computer = require("computer")
local shell = require("shell")
local fs = require("filesystem")


local function load_modules()
	print("Загрузка модулей")
	for i = 1, #modules do
		local module = modules[i]
		print("Загрузка модуля " .. module)
		shell.execute(string.format(
			"wget -fq %s/modules/%s.lua /lib/%s.lua",
			github,
			module,
			module
		))
	end
    print("Модули загружены")
end

local function load_apps()
	print("Загрузка приложений")
	
	if not fs.isDirectory("/home/apps/") then
		fs.makeDirectory("/home/apps/")
	end

	for key, name in pairs(apps) do
		print("Загрузка приложения " .. name)
		
		shell.execute(string.format(
			"wget -fq %s/apps/%s.lua /home/apps/%s.lua",
			github,
			name,
			name
		))
	end
	print("Приложения загружены")
end

local function load_launcher()
	print("Настройка автозапуска")
	shell.execute(string.format(
		"wget -fq %s/launcher.lua /home/launcher.lua",
		github
	))
	shell.execute(string.format(
		"wget -fq %s/deployer.lua /home/deployer.lua",
		github
	))
	local shrc = io.open("/home/.shrc", "w")
	shrc:write("/home/launcher.lua\n")
	shrc:close()
	print("Автозапуск настроен")
end

local function deploy()
    print(string.format("Установка \"%s\"", CONFIG.name))
	load_modules()
	load_apps()
	load_launcher()
    print('Application successfully deployed.')
end

deploy()
print("Press ENTER to restart...")
io.read()