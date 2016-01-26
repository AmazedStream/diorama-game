local Window = require ("resources/scripts/utils/window")

--------------------------------------------------
local blocks =
{
	"grass",
	"mud",
	"granite",
	"water",
	"sand",
	"snowy grass",
	"brick",
	"tnt",
	"pumpkin",
}

--------------------------------------------------
local instance = nil

--------------------------------------------------
local function renderBg (self)
	dio.drawing.font.drawBox (0, 0, self.w, self.h, 0x000000b0);
end

--------------------------------------------------
local function renderText (self)

	local font = dio.drawing.font

	local x = 5
	local y = 1
	for idx = self.lowestBlockId, self.highestBlockId do
		local text = "[" .. tostring (idx) .. ":" .. blocks [idx] .. "]"
		local colour = idx == self.currentBlockId and 0xffffffff or 0x000000ff 
		font.drawString (x, y, text, colour)
		x = x + font.measureString (text);
	end
end

--------------------------------------------------
local function onEarlyRender (self)

	if self.isDirty then
		dio.drawing.setRenderToTexture (self.renderToTexture)
		renderBg (self)
		renderText (self)
		dio.drawing.setRenderToTexture (nil)
		self.isDirty = false
	end
end

--------------------------------------------------
local function onLateRender (self)

	local scale = Window.calcBestFitScale (self.w, self.h)
	local windowW = dio.drawing.getWindowSize ()
	local x = (windowW - (self.w * scale)) * 0.5
	local y = self.y
	dio.drawing.drawTexture (self.renderToTexture, x, y, self.w * scale, self.h * scale, 0xffffffff)
end

--------------------------------------------------
local function onKeyClicked (keyCode, keyCharacter, keyModifiers)

	local keyCodes = dio.inputs.keyCodes

	local self = instance

	if keyCode >= keyCodes ["1"] and keyCode <= keyCodes ["9"] then
		self.currentBlockId = keyCode - keyCodes ["1"] + 1
		dio.inputs.setPlayerBlockId (1, self.currentBlockId)
		self.isDirty = true
		return true
	end

	return false
end

--------------------------------------------------
local function onLoadSuccessful ()

	instance = 
	{
		lowestBlockId = 1,
		highestBlockId = 9,
		currentBlockId = 7,
		isDirty = true,

		x = 20,
		y = 0,
		w = 440,
		h = 12,
	}

	instance.renderToTexture = dio.drawing.createRenderToTexture (instance.w, instance.h)

	dio.drawing.addRenderPassBefore (function () onEarlyRender (instance) end)
	dio.drawing.addRenderPassAfter (function () onLateRender (instance) end)

	local types = dio.events.types
	dio.events.addListener (types.CLIENT_KEY_CLICKED, onKeyClicked)

	dio.inputs.setPlayerBlockId (1, instance.currentBlockId)

end

--------------------------------------------------
local modSettings = 
{
	name = "Inventory",

	description = "Allows players to change the blocks they are placing",

	permissionsRequired = 
	{
		client = true,
		player = true,
	},
}

--------------------------------------------------
return modSettings, onLoadSuccessful