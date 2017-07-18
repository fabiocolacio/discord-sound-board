Command = {}
Command.__index = Command

function Command:new(action, description)
    assert(type(action) == "function",
           "Command action must be a function")
    assert(type(description) == "string",
           "Command description must be a string")

    local props = {
        action = action,
        description = description
    }

    return setmetatable(props, self)
end

setmetatable(Command, { __call = function(_, ...) return Command:new(...) end })
return Command

