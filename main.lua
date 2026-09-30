local AVL = require("avl")

local STEP_TIME = 0.9


-- UI COMPONENTS

local function newUIComponents()
    local input = ""
    local automaticMode = false

    -- callbacks por evento: "insert", "delete", "search", "nextStep"
    local callbacks = {}

    local buttons = {
        { label = "Insert", action = "insert", x = 180, y = 20, w = 70, h = 40 },
        { label = "Delete", action = "delete", x = 260, y = 20, w = 70, h = 40 },
        { label = "Search", action = "search", x = 340, y = 20, w = 70, h = 40 },
    }

    local toggle = { x = 20, y = 90, w = 50, h = 26 }
    local nextButton = { x = 90, y = 82, w = 100, h = 40 }

    local function inside(x, y, r)
        return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
    end

    local function submit(action)
        local value = tonumber(input)
        if value and callbacks[action] then
            callbacks[action](value)
            input = ""
        end
    end

    local function nextStep()
        if not automaticMode and callbacks.nextStep then
            callbacks.nextStep()
        end
    end

    return {
        on = function(event, callback)
            callbacks[event] = callback
        end,

        isAutomatic = function()
            return automaticMode
        end,

        textinput = function(text)
            -- só aceita caracteres de número (evita o espaço do "next step" entrar no campo)
            if text:match("^[%d%.%-]$") then
                input = input .. text
            end
        end,

        keypressed = function(key)
            if key == "backspace" then
                input = input:sub(1, -2)
            elseif key == "return" or key == "kpenter" then
                submit("insert")
            elseif key == "delete" then
                submit("delete")
            elseif key == "f" then
                submit("search")
            elseif key == "space" then
                nextStep()
            elseif key == "a" then
                automaticMode = not automaticMode
            end
        end,

        mousepressed = function(x, y, button)
            if button ~= 1 then
                return
            end

            for _, b in ipairs(buttons) do
                if inside(x, y, b) then
                    submit(b.action)
                    return
                end
            end

            if inside(x, y, toggle) then
                automaticMode = not automaticMode
                return
            end

            if inside(x, y, nextButton) then
                nextStep()
            end
        end,

        draw = function()
            love.graphics.setColor(1, 1, 1)

            -- text field
            love.graphics.rectangle("line", 20, 20, 150, 40)
            love.graphics.print(input, 30, 30)

            -- botões de operação
            for _, b in ipairs(buttons) do
                love.graphics.rectangle("line", b.x, b.y, b.w, b.h)
                love.graphics.printf(b.label, b.x, b.y + 12, b.w, "center")
            end

            -- toggle
            local radius = toggle.h / 2

            love.graphics.print("Automatic", toggle.x, toggle.y - 20)

            if automaticMode then
                love.graphics.setColor(0, 0.8, 0.3)
            else
                love.graphics.setColor(0.4, 0.4, 0.4)
            end

            love.graphics.rectangle("fill", toggle.x, toggle.y, toggle.w, toggle.h, radius, radius)

            local circleX = automaticMode and (toggle.x + toggle.w - radius) or (toggle.x + radius)

            love.graphics.setColor(1, 1, 1)
            love.graphics.circle("fill", circleX, toggle.y + radius, radius - 3)

            -- next step
            if not automaticMode then
                love.graphics.rectangle("line", nextButton.x, nextButton.y, nextButton.w, nextButton.h)
                love.graphics.printf("Next step", nextButton.x, nextButton.y + 12, nextButton.w, "center")
            end
        end
    }
end


-- AVL VISUALIZER

local function newAVLVisualizer()
    local root = nil

    local operationCoroutine = nil
    local currentAction = nil
    local message = ""

    local timer = 0

    local NODE_RADIUS = 25
    local LEVEL_HEIGHT = 80
    local ROOT_Y = 200

    local COLORS = {
        visit     = { 1, 1, 0 },
        insert    = { 0, 1, 0 },
        balance   = { 0, 0.6, 1 },
        rotate    = { 1, 0, 0 },
        rotated   = { 1, 0, 1 },
        delete    = { 1, 0.3, 0.3 },
        successor = { 1, 0.6, 0 },
        found     = { 0, 1, 0.6 },
    }

    local function describe(action)
        local t = action.type
        local k = action.node and action.node.key

        if t == "visit" then      return "Visitando " .. k
        elseif t == "insert" then return "Inserido " .. k
        elseif t == "balance" then return "Nó " .. k .. ": balanço = " .. action.balance
        elseif t == "rotate" then
            return "Caso " .. action.case .. " | rotação à " ..
                (action.rotation == "left" and "esquerda" or "direita") .. " em " .. k
        elseif t == "rotated" then   return "Nova raiz da subárvore: " .. k
        elseif t == "delete" then    return "Removendo " .. k
        elseif t == "successor" then return "Sucessor: " .. k .. " (menor da subárvore direita)"
        elseif t == "found" then     return "Encontrado: " .. k
        elseif t == "notfound" then  return "Chave " .. action.key .. " não encontrada"
        end

        return ""
    end

    local function drawConnection(x1, y1, x2, y2)
        local dx = x2 - x1
        local dy = y2 - y1

        local distance = math.sqrt(dx * dx + dy * dy)

        local nx = dx / distance
        local ny = dy / distance

        love.graphics.line(
            x1 + nx * NODE_RADIUS, y1 + ny * NODE_RADIUS,
            x2 - nx * NODE_RADIUS, y2 - ny * NODE_RADIUS
        )
    end

    local function setNodeColor(node)
        if currentAction and currentAction.node == node and COLORS[currentAction.type] then
            love.graphics.setColor(COLORS[currentAction.type])
        else
            love.graphics.setColor(1, 1, 1)
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

    local function finishOperation()
        operationCoroutine = nil
        currentAction = nil
        timer = 0
    end

    local function nextStep()
        if not operationCoroutine then
            return
        end

        local success, action = coroutine.resume(operationCoroutine)

        if not success then
            message = "Erro: " .. tostring(action)
            finishOperation()
            return
        end

        -- a função terminou: mostra a árvore final sem destaque
        if coroutine.status(operationCoroutine) == "dead" then
            finishOperation()
            return
        end

        currentAction = action
        message = describe(action)
    end

    -- definida depois de nextStep, para poder chamá-la
    local function startOperation(label, fn)
        if operationCoroutine then
            message = "Termine a operação atual primeiro"
            return
        end

        message = label
        operationCoroutine = coroutine.create(fn)
        timer = 0
        nextStep()
    end

    return {
        insert = function(value)
            startOperation("Inserindo " .. value, function()
                root = AVL.insert(root, value)
            end)
        end,

        delete = function(value)
            startOperation("Removendo " .. value, function()
                root = AVL.delete(root, value)
            end)
        end,

        search = function(value)
            startOperation("Buscando " .. value, function()
                AVL.search(root, value)
            end)
        end,

        nextStep = nextStep,

        update = function(dt, automaticMode)
            if not automaticMode or not operationCoroutine then
                return
            end

            timer = timer + dt

            if timer >= STEP_TIME then
                timer = 0
                nextStep()
            end
        end,

        draw = function()
            local width = love.graphics.getWidth()

            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(message, 0, 140, width, "center")

            if root then
                drawNode(root, width / 2, ROOT_Y, width / 4)
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

    ui.on("insert", avlVisualizer.insert)
    ui.on("delete", avlVisualizer.delete)
    ui.on("search", avlVisualizer.search)
    ui.on("nextStep", avlVisualizer.nextStep)
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
