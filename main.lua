Timer = require('libraries.hump.timer')
Input = require('libraries.boipushy.Input')

FPS = 30 -- frames per second, the general speed of the program
WINDOWWIDTH = 640 -- size of window's width in pixels
WINDOWHEIGHT = 480 -- size of windows' height in pixels
REVEALSPEED = 8 -- speed boxes' sliding reveals and covers
BOXSIZE = 40 -- size of box height & width in pixels
GAPSIZE = 10 -- size of gap between boxes in pixels
BOARDWIDTH = 10 -- number of columns of icons
BOARDHEIGHT = 7 -- number of rows of icons
assert((BOARDWIDTH * BOARDHEIGHT) % 2 == 0, 'Board needs to have an even number of boxes for pairs of matches.')

XMARGIN = 20 
YMARGIN = 20 

--            R    G    B
GRAY     = {.39, .39, .39}--(100, 100, 100)
NAVYBLUE = {.23, .23, .39}--( 60,  60, 100)
WHITE    = {1. ,  1.,  1.}--(255, 255, 255)
RED      = {1. ,   0,   0}--(255,   0,   0)
GREEN    = {0  ,  1.,   0}--(  0, 255,   0)
BLUE     = {0  ,   0,  1.}--(  0,   0, 255)
YELLOW   = {1. ,  1.,   0}--(255, 255,   0)
ORANGE   = {1. , 0.5,  0.}--(255, 128,   0)
PURPLE   = {1. ,   0,  1.}--(255,   0, 255)
CYAN     = {0  ,  1.,  1.}--(  0, 255, 255)


BGCOLOR = NAVYBLUE
LIGHTBGCOLOR = GRAY
BOXCOLOR = WHITE
HIGHLIGHTCOLOR = BLUE

DONUT = 1
SQUARE = 2
DIAMOND = 3
LINES = 4
OVAL = 5

ALL_Y = {0, 1, 2, 3, 4, 5, 6}
ALL_X = {0, 1, 2, 3, 4}
ANIM_TIME = 0.25
assert(#ALL_Y * #ALL_X * 2 >= BOARDWIDTH * BOARDHEIGHT, 'Board is too big for the number of shapes/colors defined.')

local EASING_TYPE = 'in-out-quad'

activeTiles = {pos = {}, x = -1, y = -1, coveredRectW = BOXSIZE, index = 1, activated = false}
isHighlighted = false
highlightedBoxX = 0
highlightedBoxY = 0
helpTile = {x = 0, y = 0}

GAME_FONT = love.graphics.newFont('assets/fonts/Early GameBoy.ttf', 30)
moveCounter = 0

function love.load()
    love.window.setTitle("LOVE Memory Puzzle")
    love.window.setMode( WINDOWWIDTH, WINDOWHEIGHT )
    mainBoard = getRandomizedBoard()
    revealedBoxes = generateRevealedBoxesData(false)
    mousePos = {x = 0, y = 0}
    firstSelection = nil
    timer = Timer()
    input = Input()
    input:bind('mouse1', 'leftButton')
    input:bind('escape', 'quit')
    love.graphics.setBackgroundColor( BGCOLOR )
    startGameAnimation()

    local img_size = 40;
    ITEMS_PNG = love.graphics.newImage('assets/sprites/items.png')
    Items = {}

    for x = 0, 4 do
        for y = 0, 6 do
            local structure = {x = x, y = y, image = love.graphics.newQuad(x * img_size, y * img_size, img_size, img_size, ITEMS_PNG) }
            table.insert(Items, structure)
        end
    end

    local cursorImage = love.mouse.newCursor('assets/sprites/cursor.png')
    love.mouse.setCursor(cursorImage, 0, 0)

    sounds = {}
    sounds.pickUpSFX = love.audio.newSource("assets/sounds/pick_up.ogg", "static")
    sounds.pickUpSFX:setVolume(0.5)

    --printBoard()
end

function love.update(dt)
    local mouseClicked = false
    timer:update(dt)
    if input:released('quit') then
        love.event.quit()
    elseif input:released('leftButton') and not activeTiles.activated then
        local x, y = love.mouse.getPosition()
        mousePos.x = x
        mousePos.y = y
        mouseClicked = true
    end

    local boxx, boxy = getBoxAtPixel()
    if boxx ~= nil and boxy ~= nil then
        if not revealedBoxes[boxx][boxy] then
            isHighlighted = true
            highlightedBoxX = boxx
            highlightedBoxY = boxy
        end
        if not revealedBoxes[boxx][boxy] and mouseClicked then
            revealedBoxes[boxx][boxy] = true -- set the box as "revealed"
            moveCounter = moveCounter + 1
            if firstSelection == nil then -- the current box was the first box clicked
                firstSelection = {boxx, boxy}
            else
                icon1shape, icon1color = getShapeAndColor(firstSelection[1], firstSelection[2])
                icon2shape, icon2color = getShapeAndColor(boxx, boxy)
                if icon1shape ~= icon2shape or icon1color ~= icon2color then
                    activeTiles.activated = true
                    helpTile.x = firstSelection[1]
                    helpTile.y = firstSelection[2]
                    timer:after(0.5, function()
                        revealedBoxes[helpTile.x][helpTile.y] = false
                        revealedBoxes[boxx][boxy] = false
                        activeTiles.activated = false
                        firstSelection = nil
                    end)
                else
                    sounds.pickUpSFX:play()
                end
                firstSelection = nil
            end
        end
    else
        isHighlighted = false
    end
end

function love.draw()
    if isHighlighted then
        drawHighlightBox()
    end
    drawBoard()
    drawTitle()
    drawMovementText()
end

function drawBoard()
    -- Draws all of the boxes in their covered or revealed state.
    for boxx = 1, BOARDWIDTH do
        for boxy = 1, BOARDHEIGHT do
            local left, top = leftTopCoordsOfBox(boxx, boxy)
            if isInAnimTiles(boxx, boxy) or (activeTiles.x == boxx and activeTiles.y == boxy) then
                -- Draw the (revealed) icon.
                local shape, color = getShapeAndColor(boxx, boxy)
                drawIcon(shape, color, boxx, boxy)
                local left, top = leftTopCoordsOfBox(boxx, boxy)
                love.graphics.rectangle("fill", left, top, activeTiles.coveredRectW, BOXSIZE)
            elseif not revealedBoxes[boxx][boxy] then
                -- Draw a covered box.
                love.graphics.setColor(BOXCOLOR)
                love.graphics.rectangle("fill", left, top, BOXSIZE, BOXSIZE)
            elseif true then
                -- Draw the (revealed) icon.
                local shape, color = getShapeAndColor(boxx, boxy)
                drawIcon(shape, color, boxx, boxy)
            end
        end
    end
    love.graphics.setColor(1, 1, 1)
end

function drawHighlightBox()
    local left, top = leftTopCoordsOfBox(highlightedBoxX, highlightedBoxY)
    love.graphics.setColor(HIGHLIGHTCOLOR)
    love.graphics.rectangle('line', left - 5, top - 5, BOXSIZE + 10, BOXSIZE + 10, 4, 4)
    love.graphics.setColor(1, 1, 1)
end

function drawIcon(shape, color, boxx, boxy)
    local left, top = leftTopCoordsOfBox(boxx, boxy)
    for _, structure in pairs(Items) do
        if structure.x == shape and structure.y == color then
            love.graphics.draw(ITEMS_PNG, structure.image, left, top)
        end
    end
    love.graphics.setColor(1,1,1)
end

function drawMovementText()
    love.graphics.setFont(GAME_FONT)
    love.graphics.setColor(WHITE)
    local text = "Movements : "..tostring(moveCounter)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, WINDOWWIDTH/2, WINDOWHEIGHT - textHeight, 0, 1, 1, textWidth/2, 0)
    love.graphics.setColor(1,1,1)
end

function drawTitle()
    love.graphics.setFont(GAME_FONT)
    love.graphics.setColor(WHITE)
    local text = "Memory Puzzle"
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, WINDOWWIDTH/2, 0, 0, 1, 1, textWidth/2, 0)
    love.graphics.setColor(1,1,1)
end

function isInAnimTiles(boxx, boxy)
    if activeTiles.index <= 0 then
        return false
    end
    for _, box in ipairs(activeTiles.pos[activeTiles.index]) do
        local x, y = unpack(box)
        if x == boxx and y == boxy then
            return true
        end
    end
    return false
end

function generateRevealedBoxesData(val)
    local revealedBoxes = {}
    for i = 1, BOARDWIDTH do
        local column = {}
        for j = 1, BOARDHEIGHT do
           table.insert(column, val) 
        end
        table.insert(revealedBoxes, column)
    end

    return revealedBoxes
end

function getBoxAtPixel()
    for boxx = 1, BOARDWIDTH do
        for boxy = 1, BOARDHEIGHT do
            local left, top = leftTopCoordsOfBox(boxx, boxy)
            if mousePos.x > left and mousePos.x < left + BOXSIZE and mousePos.y > top and mousePos.y < top + BOXSIZE then
                return boxx, boxy
            end
        end
    end

    return nil, nil 
end

function getRandomizedBoard()
    local icons = {}
    for _, color in pairs(ALL_Y) do
        for _, shape in pairs(ALL_X) do
            table.insert(icons, {shape, color})
        end
    end

    for i = #icons, 2, -1 do
        local j = love.math.random(i)
        icons[i], icons[j] = icons[j], icons[i]
    end

    local numIconsUsed = math.floor(BOARDWIDTH * BOARDHEIGHT / 2)
    local iconPairs = {}
    for i = 1, numIconsUsed do
        table.insert(iconPairs, icons[i])
        table.insert(iconPairs, icons[i])
    end

    -- Randomize the order of the icon pairs list
    for i = #iconPairs, 2, -1 do
        local j = love.math.random(i)
        iconPairs[i], iconPairs[j] = iconPairs[j], iconPairs[i]
    end
    
    -- Create the board data structure with randomly placed icon pairs
    local board = {}
    for x = 1, BOARDWIDTH do
        local column = {}
        for y = 1, BOARDHEIGHT do
            table.insert(column, iconPairs[1])
            table.remove(iconPairs, 1)
        end
        table.insert(board, column)
    end
    
        return board
end

function getShapeAndColor(boxx, boxy)
    -- shape value for x, y spot is stored in board[x][y][0]
    -- color value for x, y spot is stored in board[x][y][1]
    return mainBoard[boxx][boxy][1], mainBoard[boxx][boxy][2]
end

function leftTopCoordsOfBox(boxx, boxy)
    -- Convert board coordinates to pixel coordinates
    left = boxx * (BOXSIZE + GAPSIZE) + XMARGIN
    top = boxy * (BOXSIZE + GAPSIZE) + YMARGIN
    return left, top
end

function startGameAnimation()
    local coveredBoxes = generateRevealedBoxesData(false)
    local boxes = {}
    for x = 1, BOARDWIDTH do
        for y = 1, BOARDHEIGHT do
            table.insert(boxes, {x, y})
        end
    end

    for i = #boxes, 2, -1 do
        local j = love.math.random(i)
        boxes[i], boxes[j] = boxes[j], boxes[i]
    end

    local groupSize = 7
    local index = 1
    local animElements = (BOARDWIDTH*BOARDHEIGHT)/groupSize
    activeTiles.pos = {}
    
    for i = 1, animElements do
        table.insert(activeTiles.pos, {})
    end 

    for i = 1, #boxes-1 do
        if (i % groupSize) == 0 then
            index = index + 1
        end
        table.insert(activeTiles.pos[index], boxes[i]) 
    end

    activeTiles.activated = true
    for i = 1, animElements do
        timer:after(ANIM_TIME*i, function()
            timer:tween(ANIM_TIME, activeTiles, { coveredRectW = 0}, EASING_TYPE)
        end)
        timer:after(2*ANIM_TIME*i, function() 
            timer:tween(ANIM_TIME/2, activeTiles, { coveredRectW = BOXSIZE}, EASING_TYPE, function() activeTiles.index = activeTiles.index + 1 end)
        end)
    end

    timer:after(2*ANIM_TIME*animElements+ANIM_TIME/2, function() activeTiles.index = -1 activeTiles.pos = nil activeTiles.activated = false end)
end

function printBoard()
    for x = 1, BOARDWIDTH do
        local text = ''
        for y = 1, BOARDHEIGHT do
            text = text..' ('..tostring(x)..','..tostring(y)..')=>['..tostring(mainBoard[x][y][1])..','..tostring(mainBoard[x][y][2])..'] '
        end
        print(text)
    end
end