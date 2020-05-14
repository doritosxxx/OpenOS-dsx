local gpu = require("component").gpu
local unicode = require("unicode")
local term = require("term")

local color = {
	white = 0xdddddd,
	black = 0x222222
}

local function get_contrast( col )
	local b = col % 0xff
	col = math.floor( col / 0xff )
	local g = col % 0xff
	col = math.floor( col / 0xff )
	local r = col
	local dist = math.floor(math.sqrt( r*r + g*g + b*b ))
	if dist <= 0xff then
		return color.black
	end
	return color.white
end

local Element = {
	INHERIT = nil,
	ALIGN_START = -2,
	ALIGN_CENTER = -3,
	ALIGN_END = -4,
	TRANSPARENT = -5,
	focus = nil
}

local Block = {}
function Block:new( x, y, width, height, background, callback )
	-- assuming x,y are offsetx, offsety
	local obj = {
		x = x,
		y = y,
		width = width,
		height = height,
		background = background,
		callback = callback,
		elements = {},
		computed = {}
	}

	function obj:compute()
		local computed = self.computed
		self.root = self.parent.root
		self.parent = self.parent.computed
		local parent = self.parent

		if self.width == Element.INHERIT then
			computed.width = parent.width
		else 
			computed.width = self.width
		end

		if computed.width == nil then
			error("width is not specified")
		end

		if self.height == Element.INHERIT then
			computed.height = parent.height
		else 
			computed.height = self.height
		end

		if computed.height == nil then
			error("height is not specified")
		end
		
		if self.background == Element.INHERIT or self.background == Element.TRANSPARENT then
			computed.background = parent.background
		else 
			computed.background = self.background
		end
		if computed.background == nil then
			error("background is not specified")
		end

		--horizontal alignment
		if self.x == Element.ALIGN_START or self.width == Element.INHERIT then
			computed.x = parent.x
		elseif self.x == Element.ALIGN_CENTER then
			computed.x = parent.x + math.floor((parent.width - computed.width + 1)/2)
		elseif self.x == Element.ALIGN_END then
			computed.x = parent.x + parent.width - computed.width
		else 
			if self.x == nil then
				error("x is not specified")
			end
			computed.x = self.x + parent.x
		end
		

		--vertical alignment
		if self.y == Element.ALIGN_START or self.height == Element.INHERIT then
			computed.y = parent.y
		elseif self.y == Element.ALIGN_CENTER then
			computed.y = parent.y + math.floor((parent.height - computed.height + 1)/2)
		elseif self.y == Element.ALIGN_END then
			computed.y = parent.y + parent.height - computed.height
		else 
			if self.y == nil then
				error("y is not specified")
			end
			computed.y = self.y + parent.x
		end
		

		if self.callback ~= nil and computed.x ~= nil and computed.y ~= nil and
			computed.width ~= nil and computed.height ~= nil then
			self.root.buttons:register(computed.x, computed.y, computed.width, computed.height, self.callback)
		end

		for _, element in ipairs(self.elements) do
			element.parent = self
			element:compute()
		end
	end
	---debug function 
	--[[
	function obj:get_computed()
		local _return = ""
		local properties = {'x', 'y', 'width', 'height', 'background'}
		for _,key in ipairs(properties) do
			_return = _return .. key .. ": " .. tostring(self.computed[key]) .. ", "
		end
		return _return
	end
	]]--

	function obj:draw()
		local computed = self.computed
		local parent = self.parent

		if parent == nil then
			error("Element must be connected to workspace")
		end

		if self.background ~= Element.TRANSPARENT then
			gpu.setBackground( computed.background )
			gpu.fill( computed.x, computed.y, computed.width, computed.height, " " )
		end

		for _, element in pairs(self.elements) do
			element:draw()
		end
	end

	function obj:add(element)
		element.parent = self
		table.insert(self.elements, element)
		if self.root ~= nil then
			element:compute()
		end
		return self
	end

	setmetatable(obj, self)
	self.__index = self
	return obj
end

local Text = {}
function Text:new( offsetx, offsety, text, foreground, background )
	local obj = {
		offsetx = offsetx,
		offsety = offsety,
		text = text,
		background = background,
		foreground = foreground,
		computed = {}
	}

	function obj:wrap()
		if unicode.len(self.text) > 8000 then
			error( "String is too long" )
		end
		local chunks = {}
		local chunk = ""
		for token in self.text:gmatch("[^%s]+") do
			if unicode.len(chunk) + 1 + unicode.len(token) <= self.parent.width then
				if chunk ~= "" then
					chunk = chunk .. " "
				end
				chunk = chunk .. token
			else 
				table.insert( chunks, chunk )
				chunk = token
			end
		end
		if chunk ~= "" then
			table.insert( chunks, chunk )
		end
		self.computed.chunks = chunks
	end

	function obj:compute()

		local computed = self.computed
		self.parent = self.parent.computed
		local parent = self.parent

		if self.background == Element.INHERIT then
			computed.background = parent.background
		else 
			computed.background = self.background
		end

		if computed.background == nil then
			error("background is not specified")
		end

		self:wrap()

		if self.foreground == Element.INHERIT then
			computed.foreground = parent.foreground
		else 
			computed.foreground = self.foreground
		end

		if computed.foreground == nil then
			error("foreground is not specified")
		end

		--vertical alignment
		if self.offsety == Element.ALIGN_START then
			computed.y = parent.y
		elseif self.offsety == Element.ALIGN_CENTER then
			computed.y = parent.y + math.floor((parent.height - #computed.chunks + 1)/2)
		elseif self.offsety == Element.ALIGN_END then
			computed.y = parent.y + parent.height - #computed.chunks
		else 
			if self.offsety == nil then
				error("y is not specified")
			end
			computed.y = self.offsety + parent.y
		end	

	end

	function obj:draw()

		local computed = self.computed
		local parent = self.parent

		local y = computed.y
		for _, chunk in ipairs(computed.chunks) do
			local length = unicode.len(chunk)
			--horizontal alignment
			local x 
			if self.offsetx == Element.ALIGN_CENTER then
				x = parent.x + math.floor((parent.width - length + 1)/2)
			elseif self.offsetx == Element.ALIGN_END then
				x = parent.x + parent.width - length
			elseif self.offsetx == Element.ALIGN_START then
				x = parent.x
			else 
				x = self.offsetx + parent.x
			end

			gpu.setBackground( computed.background )
			gpu.setForeground( computed.foreground )
			gpu.set( x, y, chunk)

			y = y + 1
		end
		
	end

	setmetatable(obj, self)
	self.__index = self
	return obj
end

local Input = {}
function Input:new( x, y, width, height, params )
	--[[
		params supported fields
		type [ (text) / number / password ]
		placeholder ("")
		value ("")
		background = 0x222222
		foreground = 0xdddddd
	]]--

	local obj = {
		x = x,
		y = y,
		width = width,
		height = height,
		params = params,
		elements = {},
		computed = {params = {}}
	}

	function obj:compute()
		local computed = self.computed
		self.root = self.parent.root
		self.parent = self.parent.computed
		local parent = self.parent
		local params = self.params

		--params
		if params == nil then
			params = {}
		end
		if params.type == nil then
			computed.params.type = "text"
		else 
			computed.params.type = params.type
		end

		computed.params.placeholder = params.placeholder

		if params.value == nil then 
			computed.params.value = ""
		else 
			computed.params.value = params.value
		end

		if self.width == Element.INHERIT then
			computed.width = parent.width
		else 
			computed.width = self.width
		end
		if computed.width == nil then
			error("width is not specified")
		end

		if self.height == Element.INHERIT then
			computed.height = parent.height
		else 
			computed.height = self.height
		end
		if computed.height == nil then
			error("height is not specified")
		end
		
		if params.background == nil then
			computed.background = 0x222222
		elseif params.background == Element.TRANSPARENT then
			computed.background = parent.background
		else 
			computed.background = params.background
		end

		if params.foreground == nil then
			computed.foreground = 0xdddddd
		else 
			computed.foreground = params.foreground
		end

		--horizontal alignment
		if self.x == Element.ALIGN_START or self.width == Element.INHERIT then
			computed.x = parent.x
		elseif self.x == Element.ALIGN_CENTER then
			computed.x = parent.x + math.floor((parent.width - computed.width + 1)/2)
		elseif self.x == Element.ALIGN_END then
			computed.x = parent.x + parent.width - computed.width
		else 
			if self.x == nil then
				error("x is not specified")
			end
			computed.x = self.x + parent.x
		end

		--vertical alignment
		if self.y == Element.ALIGN_START or self.height == Element.INHERIT then
			computed.y = parent.y
		elseif self.y == Element.ALIGN_CENTER then
			computed.y = parent.y + math.floor((parent.height - computed.height + 1)/2)
		elseif self.y == Element.ALIGN_END then
			computed.y = parent.y + parent.height - computed.height
		else 
			if self.y == nil then
				error("y is not specified")
			end
			computed.y = self.y + parent.x
		end

		self.root.buttons:register(
			computed.x,
			computed.y,
			computed.width,
			computed.height,
			function( x,y )
				self:focus( x,y )
			end
		)

	end

	--- only for debug
	--[[
	function obj:get_computed()
		local _return = ""
		local properties = {'x', 'y', 'width', 'height', 'background'}
		for _,key in ipairs(properties) do
			_return = _return .. key .. ": " .. tostring(self.computed[key]) .. ", "
		end
		return _return
	end
	]]--

	function obj:unfocus()
		local computed = self.computed
		self.root.focus = nil
		term.setCursorBlink(false)
		local foreground = get_contrast( computed.background )
		if computed.params.value == "" and computed.params.placeholder ~= nil then
			gpu.setForeground(foreground)
			gpu.set(computed.x, computed.y, computed.params.placeholder)
		end
	end

	function obj:focus( x, y )
		local computed = self.computed
		self.root.focus = self
		if computed.params.placeholder ~= nil then
			gpu.setBackground(computed.background)
			gpu.fill(computed.x, computed.y, computed.width, computed.height, " ")
		end
		term.setCursor( x, y )
		term.setCursorBlink(true)
	end

	function obj:draw()
		local computed = self.computed
		local parent = self.parent

		if parent == nil then
			error("Element must be connected to workspace")
		end

		gpu.setForeground( computed.foreground )

		if self.params.background ~= Element.TRANSPARENT then
			gpu.setBackground( computed.background )
			gpu.fill( computed.x, computed.y, computed.width, computed.height, " " )
		end

		if computed.params.value ~= "" then
			gpu.set(computed.x, computed.y, computed.params.value)
		end

		self:unfocus()

	end

	setmetatable(obj, self)
	self.__index = self
	return obj
end

function Element.block( ... )
	return Block:new( ... )
end

function Element.text( ... )
	return Text:new( ... )
end

function Element.input( ... )
	return Input:new( ... )
end

return Element