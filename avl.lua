local AVL = {}
AVL.__index = AVL

function AVL:new(key)
    local newObj = {
        key = key,
        leftchild = nil,
        rightchild = nil,
        height = 1
    }
    return setmetatable(newObj, AVL)
end

-- funcionam com self == nil (chamadas como AVL.get_height(node))
function AVL:get_height()
    return self and self.height or 0
end

function AVL:get_balance()
    if not self then
        return 0
    end
    return AVL.get_height(self.leftchild) - AVL.get_height(self.rightchild)
end

function AVL:update_height()
    self.height = math.max(AVL.get_height(self.leftchild), AVL.get_height(self.rightchild)) + 1
end


-- INSERT

function AVL.insert(node, key, state)
    local isTopLevel = (state == nil)
    state = state or {}

    if node == nil then
        local newNode = AVL:new(key)

        if isTopLevel then
            -- árvore vazia: não há pai para anunciar a inserção
            coroutine.yield({ type = "insert", node = newNode })
        else
            state.insertnode = newNode
        end

        return newNode
    end

    coroutine.yield({ type = "visit", node = node })

    if key > node.key then
        node.rightchild = AVL.insert(node.rightchild, key, state)
    elseif key < node.key then
        node.leftchild = AVL.insert(node.leftchild, key, state)
    else
        error("chave duplicada: " .. key, 0)
    end

    if state.insertnode then
        coroutine.yield({ type = "insert", node = state.insertnode })
        state.insertnode = nil
    end

    return AVL.rebalance(node)
end


-- SEARCH

function AVL:search(key)
    if not self then
        coroutine.yield({ type = "notfound", key = key })
        return nil
    end

    if self.key == key then
        coroutine.yield({ type = "found", node = self })
        return self
    end

    coroutine.yield({ type = "visit", node = self })

    if key < self.key then
        return AVL.search(self.leftchild, key)
    else
        return AVL.search(self.rightchild, key)
    end
end


-- ROTATIONS

--[[
  rotate_left

      10  (self)                            20  (newroot)
     /  \                                  /  \
    A    20  (newroot)      --->   (self) 10   C
        /  \                             /  \
      15    C                           A    15  (newrightchild)
      (newrightchild)
]]
function AVL:rotate_left()
    local newroot = self.rightchild
    local newrightchild = newroot.leftchild

    newroot.leftchild = self
    self.rightchild = newrightchild

    -- ordem importa: self agora é filho de newroot
    self:update_height()
    newroot:update_height()

    return newroot
end

function AVL:rotate_right()
    local newroot = self.leftchild
    local newleftchild = newroot.rightchild

    newroot.rightchild = self
    self.leftchild = newleftchild

    self:update_height()
    newroot:update_height()

    return newroot
end


-- REBALANCE

function AVL:rebalance()
    self:update_height()

    local balance = self:get_balance()

    coroutine.yield({ type = "balance", node = self, balance = balance })

    -- pesado à esquerda
    if balance > 1 then
        local case = "Left-Left"

        if self.leftchild:get_balance() < 0 then
            case = "Left-Right"
            coroutine.yield({ type = "rotate", node = self.leftchild, rotation = "left", case = case })
            self.leftchild = self.leftchild:rotate_left()
        end

        coroutine.yield({ type = "rotate", node = self, rotation = "right", case = case })

        local newroot = self:rotate_right()
        coroutine.yield({ type = "rotated", node = newroot })
        return newroot
    end

    -- pesado à direita
    if balance < -1 then
        local case = "Right-Right"

        if self.rightchild:get_balance() > 0 then
            case = "Right-Left"
            coroutine.yield({ type = "rotate", node = self.rightchild, rotation = "right", case = case })
            self.rightchild = self.rightchild:rotate_right()
        end

        coroutine.yield({ type = "rotate", node = self, rotation = "left", case = case })

        local newroot = self:rotate_left()
        coroutine.yield({ type = "rotated", node = newroot })
        return newroot
    end

    return self
end


-- DELETE

function AVL:min_node()
    local current = self
    while current.leftchild do
        current = current.leftchild
    end
    return current
end

function AVL:delete(key)
    if self == nil then
        error("chave não encontrada: " .. key, 0)
    end

    if key < self.key then
        coroutine.yield({ type = "visit", node = self })
        self.leftchild = AVL.delete(self.leftchild, key)

    elseif key > self.key then
        coroutine.yield({ type = "visit", node = self })
        self.rightchild = AVL.delete(self.rightchild, key)

    else
        coroutine.yield({ type = "delete", node = self })

        -- caso 1: folha
        if not self.leftchild and not self.rightchild then
            return nil

        -- caso 2: só um filho
        elseif not self.leftchild then
            return self.rightchild
        elseif not self.rightchild then
            return self.leftchild
        end

        -- caso 3: dois filhos -> usa o sucessor
        local successor = self.rightchild:min_node()
        coroutine.yield({ type = "successor", node = successor })

        self.key = successor.key
        self.rightchild = AVL.delete(self.rightchild, successor.key)
    end

    return AVL.rebalance(self)
end

return AVL
