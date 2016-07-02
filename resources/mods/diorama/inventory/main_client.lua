local BlockDefinitions = require ("resources/mods/diorama/blocks/block_definitions")
local Window = require ("resources/_scripts/utils/window")

--------------------------------------------------
local blocks = BlockDefinitions.blocks
local tiles = BlockDefinitions.tiles

--------------------------------------------------
local entities =
{
    SIGN =
    {
        type = "SIGN",
        text = "Placeholder Text",
    }
}

--------------------------------------------------
local instance = nil

--------------------------------------------------
local function testIdBounds (self)
    if self.currentBlockId > self.highestBlockId then
        self.currentBlockId = self.highestBlockId
    end

    if self.currentBlockId < self.lowestBlockId then
        self.currentBlockId = self.lowestBlockId
    end
end

--------------------------------------------------
local function renderBg (self)
    dio.drawing.font.drawBox (0, 0, self.w, self.iconHeight, 0x000000b0)
end

--------------------------------------------------
local function renderSelectedBlock (self, idx, x, y)

    dio.drawing.font.drawBox (x - 1, y - 1, 18, 18, 0xffffffff)
    
    local block = blocks [self.currentBlockId]
    local width = dio.drawing.font.measureString (block.name)
    x = (idx * 17 - 7) - (width * 0.5)
    x = x < 1 and 1 or x
    x = x + width >= self.w and self.w - width or x

    dio.drawing.font.drawBox (x - 1, self.iconHeight, width + 1, self.h - self.iconHeight, 0x000000b0)
    dio.drawing.font.drawString (x, self.iconHeight, block.name, 0xffffffff)
end

--------------------------------------------------
local function getBlockUV (block_id)
    local block = blocks [block_id]
    
    if block ~= nil then
        if block.uvs ~= nil then
          return block.uvs [1], block.uvs [2]
          
        elseif block.tiles ~= nil then
            local tile = tiles [block.tiles [1]]
            
            if tile ~= nil then
                return tile.uvs [1], tile.uvs [2]
            end
        
        end
    end
    
    return nil, nil
end

--------------------------------------------------
local function renderBlocks (self)

    local x = 1
    local y = 1
    for idx = 1, self.blocksPerPage do
        local block_id = idx + self.currentPage * self.blocksPerPage
        
        if blocks [block_id] ~= nil then
            local u, v = getBlockUV (block_id)
            
            if u ~= nil then                
                if block_id == self.currentBlockId then
                    renderSelectedBlock (self, idx, x, y)
                end
                
                dio.drawing.drawTextureRegion (self.blockTexture, x, y, u * 16, v * 16, 16, 16)
                
            end
            
            x = x + 17;
        end
    end
end

--------------------------------------------------
local function setInventoryItem (id)
    local blockName = blocks [id].name

    local entity = entities [blockName]
    if entity then
        dio.inputs.setPlayerEntityId (1, id, entity.text)
    else
        dio.inputs.setPlayerBlockId (1, id)
    end

end

--------------------------------------------------
local function onUpdate (self)

    local scrollWheel = dio.inputs.mouse.getScrollWheelDelta ()

    if scrollWheel ~= 0 then
        if scrollWheel > 0 then
            self.currentBlockId = self.currentBlockId - 1
        else
            self.currentBlockId = self.currentBlockId + 1
        end

        if self.currentBlockId > self.blocksPerPage + self.currentPage * self.blocksPerPage or self.currentBlockId > self.highestBlockId then
            self.currentPage = self.currentPage + 1

            if self.currentPage > self.pages then
                self.currentPage = 0
            end

            self.currentBlockId = 1 + self.currentPage * self.blocksPerPage

        elseif self.currentBlockId < 1 + self.currentPage * self.blocksPerPage then
            self.currentPage = self.currentPage - 1

            if self.currentPage < 0 then
                self.currentPage = self.pages
            end

            if self.blocksPerPage + self.currentPage * self.blocksPerPage > self.highestBlockId then
                self.currentBlockId = self.highestBlockId
            else
                self.currentBlockId = self.blocksPerPage + self.currentPage * self.blocksPerPage
            end

        end

        setInventoryItem (self.currentBlockId)
        self.isDirty = true
    end

end

--------------------------------------------------
local function onEarlyRender (self)
    -- Not the most ideal way to call onUpdate
    onUpdate (self)

    if self.isDirty then
        dio.drawing.setRenderToTexture (self.renderToTexture)
        renderBg (self)
        renderBlocks (self)
        dio.drawing.setRenderToTexture (nil)
        self.isDirty = false
    end

end

--------------------------------------------------
local function onLateRender (self)

    -- fake double width to prevent the inventory being all up in yo face (magnavode)
    local scale = Window.calcBestFitScale (self.w * 2, self.h)
    local windowW, windowH = dio.drawing.getWindowSize ()
    local x = (windowW - (self.w * scale)) * 0.5
    local y = self.y
    dio.drawing.drawTexture (self.renderToTexture, x, y, self.w * scale, self.h * scale, 0xffffffff)

    local params = dio.drawing.getTextureParams (self.crosshairTexture)
    params.width = params.width * 3
    params.height = params.height * 3
    dio.drawing.drawTexture2 (
            self.crosshairTexture, 
            (windowW - params.width) * 0.5, 
            (windowH - params.height) * 0.5,
            params.width,
            params.height)
end

--------------------------------------------------
local function onKeyClicked (keyCode, keyCharacter, keyModifiers)

    local keyCodes = dio.inputs.keyCodes

    local self = instance

    if keyCode >= keyCodes ["1"] and keyCode <= keyCodes ["9"] then
        if blocks [ (keyCode - keyCodes ["1"] + 1) + self.currentPage * self.blocksPerPage] ~= nil then
            self.currentBlockId = (keyCode - keyCodes ["1"] + 1) + self.currentPage * self.blocksPerPage
            setInventoryItem (self.currentBlockId)
            self.isDirty = true
            return true
        end

    elseif keyCode >= keyCodes.F1 and keyCode <= keyCodes.F12 then
        if keyCode - keyCodes.F1 >= 0 and keyCode - keyCodes.F1    <= self.pages then
            local oldPage = self.currentPage
            self.currentPage = (keyCode - keyCodes.F1)
            self.currentBlockId = self.currentBlockId + (self.currentPage - oldPage) * self.blocksPerPage
            testIdBounds (self)
            self.isDirty = true
        end

    elseif keyCode == keyCodes.RIGHT then
        self.currentPage = self.currentPage + 1

        if self.currentPage > self.pages then
            self.currentPage = 0
            self.currentBlockId = self.currentBlockId - self.blocksPerPage * self.pages
            testIdBounds (self)

        else
            self.currentBlockId = self.currentBlockId + self.blocksPerPage
            testIdBounds (self)

        end

        setInventoryItem (self.currentBlockId)
        self.isDirty = true
        return true

    elseif keyCode == keyCodes.LEFT then
        self.currentPage = self.currentPage - 1

        if self.currentPage < 0 then
            self.currentPage = self.pages
            self.currentBlockId = self.currentBlockId + self.blocksPerPage * self.pages
            testIdBounds (self)

        else
            self.currentBlockId = self.currentBlockId - self.blocksPerPage
            testIdBounds (self)

        end

        setInventoryItem (self.currentBlockId)
        self.isDirty = true
        return true

    -- hijack inventory to add temporary gravity changing buttons
    elseif keyCode == keyCodes.INSERT then
        dio.inputs.setMyGravity (dio.inputs.gravityDirections.UP)
        return true

    elseif keyCode == keyCodes.PAGE_UP then
        dio.inputs.setMyGravity (dio.inputs.gravityDirections.DOWN)
        return true

    elseif keyCode == keyCodes.HOME then
        dio.inputs.setMyGravity (dio.inputs.gravityDirections.NORTH)
        return true

    elseif keyCode == keyCodes.END then
        dio.inputs.setMyGravity (dio.inputs.gravityDirections.SOUTH)
        return true

    elseif keyCode == keyCodes.DELETE then
        dio.inputs.setMyGravity (dio.inputs.gravityDirections.WEST)
        return true

    elseif keyCode == keyCodes.PAGE_DOWN then
        dio.inputs.setMyGravity (dio.inputs.gravityDirections.EAST)
        return true

    end

    setInventoryItem (self.currentBlockId)
    return false
end

--------------------------------------------------
local function onChatMessagePreSent (text)

    local command = ".setSign "
    local compare = text:sub (1, command:len ())

    if compare == command then
        local message = text:sub (command:len () + 1)
        entities.sign.text = message
        return true
    end

    return false
end

--------------------------------------------------
local function onLoadSuccessful ()
    instance =
    {
        lowestBlockId = 1,
        highestBlockId = #blocks,
        currentBlockId = 7,
        currentPage = 0,
        blocksPerPage = 9,
        pages = 0, -- 0 indexed
        isDirty = true,

        x = 20,
        y = 0,
        h = 18 + 10,
        iconHeight = 18,

        crosshairTexture = dio.drawing.loadTexture ("resources/textures/crosshair.png"),
        blockTexture = dio.drawing.loadTexture ("resources/textures/diorama_terrain_harter_00.png"),
    }
    
    instance.w = 17 * instance.blocksPerPage + 1

    instance.renderToTexture = dio.drawing.createRenderToTexture (instance.w, instance.h)
    instance.pages = math.ceil (instance.highestBlockId / instance.blocksPerPage) - 1

    dio.drawing.addRenderPassBefore (1, function () onEarlyRender (instance) end)
    dio.drawing.addRenderPassAfter (1, function () onLateRender (instance) end)

    local types = dio.events.types
    dio.events.addListener (types.CLIENT_KEY_CLICKED, onKeyClicked)
    dio.events.addListener (types.CLIENT_CHAT_MESSAGE_PRE_SENT, onChatMessagePreSent)

    setInventoryItem (instance.currentBlockId)

end

--------------------------------------------------
local modSettings =
{
    name = "Inventory",

    description = "Allows players to change the blocks they are placing",

    permissionsRequired =
    {
        drawing = true,
        player = true,
        input = true,
    },
}

--------------------------------------------------
return modSettings, onLoadSuccessful
