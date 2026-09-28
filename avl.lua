AVL = {}

function AVL:new(key)
    local newObj = {
    key = key,
    leftchild = nil,
    rightchild = nil,
    height = 1
}
    self.__index = self
    return setmetatable(newObj, self)
end

function AVL:get_height()
    return self and self.height or 0
end

function AVL:get_balance()
    return self and self.get_height(self.leftchild) - self.get_height(self.rightchild) or 0
end

function AVL:update_height()
    self.height = math.max(AVL.get_height(self.leftchild), AVL.get_height(self.rightchild)) + 1
end

function AVL.insert(node, key, state)
    state = state or {}

    if node == nil then
        local newNode = AVL:new(key)
        state.insertnode = newNode
        return newNode
    end

    coroutine.yield({
        type = "visit",
        node = node
    })
    
    if key > node.key then
        node.rightchild = AVL.insert(node.rightchild, key, state)
    elseif key < node.key then
        node.leftchild = AVL.insert(node.leftchild, key, state)
    else
        error("chave duplicada: " .. key, 0)
    end

    if state.insertnode then 
        coroutine.yield({
            type = "insert",
            node = state.insertnode
        })
        state.insertnode = nil
    end

    return AVL.rebalance(node)
end
  
function AVL:search(root, id)
    if not root or root.key == id then
        return root
    end
    if id < root.id then
        return search(root.left, id)
    else
        return search(root.right, id)
    end
end

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
  
    -- roda
    newroot.leftchild = self
    self.rightchild = newrightchild
  
    -- atualiza alturas
    self:update_height()
    newroot.height = math.max(AVL.get_height(newroot.leftchild), AVL.get_height(newroot.rightchild)) + 1
    -- newrightchild não precisa ser recalculado
  
  return newroot
end

function AVL:rotate_right()
    local newroot = self.leftchild
    local newleftchild = newroot.rightchild
  
    -- roda
    newroot.rightchild = self
    self.leftchild = newleftchild
  
    -- atualiza alturas
    self:update_height()
    newroot.height = math.max(AVL.get_height(newroot.leftchild), AVL.get_height(newroot.rightchild)) + 1
    -- newleftchild não precisa ser recalculado
  
  return newroot
end


function AVL:rebalance()
    self:update_height()

    local balance = self:get_balance()

    coroutine.yield({
        type = "balance",
        node = self,
        balance = balance
    })

    -- esquerda
    if balance > 1 then
        
        -- left - right
        if self.leftchild:get_balance() < 0 then
            coroutine.yield({
                type = "rotate",
                node = self.leftchild,
                rotation = "left",
                case = "Left-Right"
            })
            self.leftchild = self.leftchild:rotate_left()
        end

        coroutine.yield({
            type = "rotate",
            node = self,
            rotation = "right",
            case = "Left-Left"
        })

        -- left - left
        local newroot = self:rotate_right()

        coroutine.yield({
            type = "rotated",
            node = newroot
        })

        return newroot
    end

    -- direita
    if balance < -1 then

        -- right left
        if self.rightchild:get_balance() > 0 then
            coroutine.yield({
                type = "rotate",
                node = self.rightchild,
                rotation = "right",
                case = "Right-Left"
            })
            self.rightchild = self.rightchild:rotate_right()
        end

        coroutine.yield({
            type = "rotate",
            node = self,
            rotation = "left",
            case = "Right-Right"
        })
        
        -- right - right
        local newroot = self:rotate_left()

        coroutine.yield({
            type = "rotated",
            node = newroot
        })

        return newroot
    end

    return self
end

function AVL:delete(value)
return nil
end

return AVL