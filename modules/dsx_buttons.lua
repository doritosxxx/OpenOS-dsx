local com = require("component")
local gpu = com.gpu
local event = require("event")

local Buttons = {}

function Buttons:new( workspace )
	local obj = {}
	obj.list = {}
	obj.workspace = workspace

	function obj:register( x, y, width, height, callback)
		table.insert(self.list, {
			x=x,
			y=y,
			width=width,
			height=height,
			callback=callback
		})
		return
	end

	function obj:pull(...)
		local status,_,x,y,_btn,nickname = event.pull(0,"touch")
		if status == nil then
			return nil
		end
		--only for virtual machine
		if nickname == nil then
			nickname = "doritosxxx"
		end
		if self.workspace.focus ~= nil then
			self.workspace.focus:unfocus()
		end
		for i = #self.list, 1,-1 do
			local button = self.list[i]
			if  button.x <= x and x < button.x+button.width and
				button.y <= y and y < button.y+button.height then
				return button.callback(x,y,nickname,_btn,...)
			end
		end
		return nil
	end

	setmetatable(obj, self)
	self.__index = self
	return obj
end

return Buttons