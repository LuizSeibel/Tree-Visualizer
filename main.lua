local AVL = require("avl")

local STEP_TIME = 0.9


-- UI COMPONENTS

local function newUIComponents()
    local input = ""
    local automaticMode = false

    local okCallback = nil
    local nextStepCallback = nil

    return {
        setOnOk = function(callback)
            okCallback = callback
        end,

        setOnNextStep = function(callback)
            nextStepCallback = callback
        end,

        isAutomatic = function()
            return automaticMode
        end,

        textinput = function(text)
            input = input .. text
        end,

        keypressed = function(key)
            if key == "backspace" then
                input = input:sub(1, -2)

            elseif key == "return" then
                local value = tonumber(input)

                if value and okCallback then
                    okCallback(value)
                    input = ""
                end

            elseif key == "space" and not automaticMode then
                if nextStepCallback then
                    nextStepCallback()
                end
            end
        end,

        mousepressed = function(x, y, button)
            if button ~= 1 then
                return
            end

            -- OK
            if x >= 180 and x <= 240
            and y >= 20 and y <= 60 then
                local value = tonumber(input)

                if value and okCallback then
                    okCallback(value)
                    input = ""
                end

                return
            end

            -- toggle automatic
            if x >= 20 and x <= 70
            and y >= 90 and y <= 116 then
                automaticMode = not automaticMode
                return
            end

            -- next step
            if not automaticMode
            and x >= 90 and x <= 190
            and y >= 82 and y <= 122 then
                if nextStepCallback then
                    nextStepCallback()
                end
            end
        end,

        draw = function()
            love.graphics.setColor(1, 1, 1)

            -- text field
            love.graphics.rectangle("line", 20, 20, 150, 40)
            love.graphics.print(input, 30, 30)

            -- OK
            love.graphics.rectangle("line", 180, 20, 60, 40)
            love.graphics.printf("OK", 180, 32, 60, "center")

            -- toggle
            local toggleX = 20
            local toggleY = 90
            local toggleWidth = 50
            local toggleHeight = 26
            local toggleRadius = toggleHeight / 2

            love.graphics.print("Automatic", toggleX, toggleY - 20)

            if automaticMode then
                love.graphics.setColor(0, 0.8, 0.3)
            else
                love.graphics.setColor(0.4, 0.4, 0.4)
            end

            love.graphics.rectangle("fill", toggleX, toggleY, toggleWidth, toggleHeight, toggleRadius, toggleRadius)

            local circleX

            if automaticMode then
                circleX = toggleX + toggleWidth - toggleRadius
            else
                circleX = toggleX + toggleRadius
            end

            love.graphics.setColor(1, 1, 1)
            love.graphics.circle("fill", circleX, toggleY + toggleRadius, toggleRadius - 3)

            -- next step
            if not automaticMode then
                love.graphics.rectangle("line", 90, 82, 100, 40)
                love.graphics.printf("Next step", 90, 94, 100, "center")
            end

            love.graphics.setColor(1, 1, 1)
        end
    }
end


-- AVL VISUALIZER

local function newAVLVisualizer()
    local root = nil

    local insertionCoroutine = nil
    local currentAction = nil

    local timer = 0

    local NODE_RADIUS = 25
    local LEVEL_HEIGHT = 80

    local function drawConnection(x1, y1, x2, y2)
        local dx = x2 - x1
        local dy = y2 - y1

        local distance = math.sqrt(dx * dx + dy * dy)

        local nx = dx / distance
        local ny = dy / distance

        local startX = x1 + nx * NODE_RADIUS
        local startY = y1 + ny * NODE_RADIUS

        local endX = x2 - nx * NODE_RADIUS
        local endY = y2 - ny * NODE_RADIUS

        love.graphics.line(startX, startY, endX, endY)
    end

    local function setNodeColor(node)
        if not currentAction or currentAction.node ~= node then
            love.graphics.setColor(1, 1, 1)
            return
        end

        if currentAction.type == "visit" then
            love.graphics.setColor(1, 1, 0)

        elseif currentAction.type == "insert" then
            love.graphics.setColor(0, 1, 0)

        elseif currentAction.type == "balance" then
            love.graphics.setColor(0, 0.6, 1)

        elseif currentAction.type == "rotate" then
            love.graphics.setColor(1, 0, 0)

        elseif currentAction.type == "rotated" then
            love.graphics.setColor(1, 0, 1)
        end
    end

    local function drawNode(node, x, y, offset)
        if not node then
            return
        end

        local childY = y + LEVEL_HEIGHT

        if node.leftchild then
            local childX = x - offset

            drawConnection(x, y, childX, childY)
            drawNode(node.leftchild, childX, childY, offset / 2)
        end

        if node.rightchild then
            local childX = x + offset

            drawConnection(x, y, childX, childY)
            drawNode(node.rightchild, childX, childY, offset / 2)
        end

        setNodeColor(node)

        love.graphics.circle("line", x, y, NODE_RADIUS)
        love.graphics.printf(tostring(node.key), x - NODE_RADIUS, y - 8, NODE_RADIUS * 2, "center")

        love.graphics.print("b=" .. node:get_balance(), x + 32, y - 8)
        love.graphics.print("h=" .. node.height, x - 12, y + 30)

        love.graphics.setColor(1, 1, 1)
    end

    local function finishInsertion()
        insertionCoroutine = nil
        currentAction = nil
        timer = 0
    end

    local function nextStep()
        if not insertionCoroutine then
            return
        end

        if coroutine.status(insertionCoroutine) == "dead" then
            finishInsertion()
            return
        end

        local success, action = coroutine.resume(insertionCoroutine)

        if not success then
            print(action)
            finishInsertion()
            return
        end

        currentAction = action
    end

    return {
        insert = function(value)
            if insertionCoroutine then
                return
            end

            insertionCoroutine = coroutine.create(function()
                root = AVL.insert(root, value)
            end)

            timer = 0
            nextStep()
        end,

        nextStep = nextStep,

        update = function(dt, automaticMode)
            if not automaticMode then
                return
            end

            if not insertionCoroutine then
                return
            end

            timer = timer + dt

            if timer >= STEP_TIME then
                timer = 0
                nextStep()
            end
        end,

        draw = function()
            if currentAction and currentAction.type == "rotate" then
                local width = love.graphics.getWidth()
                local height = love.graphics.getHeight()

                love.graphics.printf("Case: " .. currentAction.case .. " | Rotation: " .. currentAction.rotation, 0, 150, width, "center")
            end

            if root then
                local width = love.graphics.getWidth()
                drawNode(root, width / 2, 90, width / 4)
            end
        end
    }
end


-- MAIN

local ui
local avlVisualizer

function love.load()
    ui = newUIComponents()
    avlVisualizer = newAVLVisualizer()

    ui.setOnOk(function(value)
        avlVisualizer.insert(value)
    end)

    ui.setOnNextStep(function()
        avlVisualizer.nextStep()
    end)
end

function love.textinput(text)
    ui.textinput(text)
end

function love.keypressed(key)
    ui.keypressed(key)
end

function love.mousepressed(x, y, button)
    ui.mousepressed(x, y, button)
end

function love.update(dt)
    avlVisualizer.update(dt, ui.isAutomatic())
end

function love.draw()
    ui.draw()
    avlVisualizer.draw()
end