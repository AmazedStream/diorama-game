local Window = require ("resources/_scripts/utils/window")

--------------------------------------------------
local instance = nil

--------------------------------------------------
local function renderBg (self)
    dio.drawing.font.drawBox (0, 0, self.w, self.h, 0x0000080);
end

--------------------------------------------------
local function renderPlayerList (self)

    local drawString = dio.drawing.font.drawString

    local y = self.h - self.heightPerLine

    drawString (1, y, "Clients Connected", 0xffffffff)
    y = y - self.heightPerLine

    for idx, client in ipairs (self.clients) do
        y = y - self.heightPerLine
        drawString (1, y, client.accountId, 0x00ffffff)
    end
end

--------------------------------------------------
local function onEarlyRender (self)

    if self.isDirty then

        dio.drawing.setRenderToTexture (self.renderToTexture)
        renderBg (self)
        renderPlayerList (self)
        dio.drawing.setRenderToTexture (nil)
        self.isDirty = false
    end
end

--------------------------------------------------
local function onLateRender (self)

    if self.isVisible then
        local windowW, windowH = dio.drawing.getWindowSize ()
        local scale = Window.calcBestFitScale (self.w, self.h, windowW, windowH)
        local x = (windowW - self.w * scale) * 0.5
        local y = (windowH - self.h * scale) * 0.5
        dio.drawing.drawTexture (self.renderToTexture, x, y, self.w * scale, self.h * scale, 0xffffffff)
    end
end

--------------------------------------------------
local function onKeyClicked (keyCode, keyCharacter, keyModifiers)

    local self = instance

    if keyCode == self.appearKeyCode then
        self.isVisible = not self.isVisible
        return true
    end

    return false
end

--------------------------------------------------
local function onClientConnected (event)
    local self = instance
    table.insert (self.clients, {accountId = event.accountId})
    self.isDirty = true
end

--------------------------------------------------
local function onClientDisconnected (event)
    local self = instance
    for idx, client in ipairs (self.clients) do
        if client.accountId == event.accountId then
            table.remove (self.clients, idx)
            self.isDirty = true
            return
        end
    end
end

--------------------------------------------------
local function onClientWindowFocusLost ()

    local self = instance
    self.isVisible = false
end

--------------------------------------------------
local function onLoadSuccessful ()

    instance = 
    {
        w = 128, 
        h = 256,
        heightPerLine = 14,
        clients = {},
        isDirty = true,
        isVisible = false,
        appearKeyCode = dio.inputs.keyCodes.TAB,
    }

    instance.renderToTexture = dio.drawing.createRenderToTexture (instance.w, instance.h)
    dio.drawing.addRenderPassBefore (1.0, function () onEarlyRender (instance) end)
    dio.drawing.addRenderPassAfter (1.0, function () onLateRender (instance) end)

    local types = dio.events.types
    dio.events.addListener (types.CLIENT_CLIENT_CONNECTED, onClientConnected)
    dio.events.addListener (types.CLIENT_CLIENT_DISCONNECTED, onClientDisconnected)
    dio.events.addListener (types.CLIENT_WINDOW_FOCUS_LOST, onClientWindowFocusLost)
    dio.events.addListener (types.CLIENT_KEY_CLICKED, onKeyClicked)
end

--------------------------------------------------
local modSettings = 
{
    name = "PLayer List",

    description = "Shows all connected players",

    permissionsRequired = 
    {
        drawing = true,
        player = true,
        input = true,
    },
}

--------------------------------------------------
return modSettings, onLoadSuccessful
