local Queue = {}
Queue.__index = Queue

function Queue:new()
    return setmetatable({}, self)
end

function Queue:enqueue(...)
    local arg = {...}
    for index, val in ipairs(arg) do
        table.insert(self, val)
    end
end

function Queue:dequeue()
    if #self > 0 then
        return table.remove(self, 1)
    end
end

function Queue:next()
    return self[1]
end

function Queue:isEmpty()
    if self[1] then
        return false
    else
        return true
    end
end

function Queue:clear()
    while #self > 0 do
        self:dequeue()
    end
end

function Queue:iter()
    return ipairs(self)
end

setmetatable(Queue, { __call = function(_, ...) return Queue:new(...) end })
return Queue

