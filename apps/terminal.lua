local component = require("component")
local Workspace = require("dsx_workspace")
local db = require("dsx_db"):new("pank228") --TODO: убрать

local status, value = pcall(function() return component.me_interface end)
local me
if status then
	me = value
else 
	me = false
end

local currency = {
	name = "minecraft:iron_ingot"
}

local function getCurrencyAmount()
	if me == false then
		return 0 --virtual machine
	end
	local temp = me.getItemsInNetwork(currency)
	if temp.n == 0 then
		return 0
	end
	return temp[1].size
end

local action = {
	exit = 1,
	deposit = 2,
	withdraw = 3
}

local function screen1()
	local ws = Workspace:new(50,25)
	ws:bind(1,1,50,25, 0x222222, function(_,_,nickname)
		return nickname
	end)
	ws:text(7, 13, "Нажмите на экран, чтобы начать работу", 0x222222, 0xeeeeee)
	return ws
end

local function screen2(nickname)
	local ws = Workspace:new(50,25)
	ws:bind(1,1,50,25, 0x222222)
	ws:text(3,2, "Пользователь: " .. nickname, 0x222222, 0xeeeeee)
	ws:text(3,3, "Баланс: " , 0x222222, 0xeeeeee)
	ws:text(3,4, "Доступно на вывод: " , 0x222222, 0xeeeeee)
	ws:bind(3,14,22,7,0xeeeeee, function(x,y,_nickname)
		if nickname == _nickname then
			return action.deposit
		end
		return nil
	end)
	ws:text(9,17,"Пополнить", 0xeeeeee, 0x222222)
	ws:text(8,18,"Комиссия 5%", 0xeeeeee, 0x222222)
	ws:bind(27,14,22,7,0xeeeeee, function(x,y,nickname,user)
		if nickname == user then
			return action.withdraw
		end
		return nil
	end)
	ws:text(34,17,"Снять 64", 0xeeeeee, 0x222222)
	ws:bind(3,22, 46, 3, 0xeeeeee, function() 
		return action.exit
	end)
	ws:text(23,23,"Выйти", 0xeeeeee, 0x222222)
	return ws
end

local function drawCurrency()
	local amount = getCurrencyAmount()
	local ws = Workspace:new()
	ws:bind(22,4, 20, 1, 0x222222)
	ws:text(22,4, tostring(amount) .. " слитков" , 0x222222, 0xeeeeee)
	ws:draw()
end

local function loadingscreen()
	local ws = Workspace:new(50,25)
	ws:bind(1,1,50,25, 0x222222)
	ws:text(20, 12, "Загрузка...", 0x222222, 0xeeeeee)
	return ws
end

local function logic2(nickname) --основное меню
	local ws = screen2(nickname)
	local ws_loading = loadingscreen()
	ws_loading:draw()
	os.sleep(0)
	local balance = db:get(nickname)
	ws:text(11,3, tostring(balance), 0x222222, 0xeeeeee)
	ws:draw()
	while 1 do
		drawCurrency()
		local type = ws.buttons:pull(nickname)
		if type == action.exit then
			return
		elseif type == action.withdraw then
			--TODO
		elseif type == action.deposit then
			--TODO
		end
	end
end

local function logic1() --экран "начать"
	local ws = screen1()
	ws:draw()
	local nickname = nil
	while nickname == nil do
		nickname = ws.buttons:pull()
	end
	logic2(nickname)
end



while true do
	logic1()
	os.sleep(0)
end


