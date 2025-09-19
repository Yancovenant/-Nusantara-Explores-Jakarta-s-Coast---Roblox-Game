-- Logger module lua

local logger = {}

logger.ENABLED = true -- to be put in config later

function logger:_Log(moduleName, funcName, duration)
    print(string.format("[LOGGER: %s<%s>] took %.2fms", moduleName, funcName, duration))
end

function logger:_Track(moduleName, funcName, func)
    return function(...)
        if not self.ENABLED then
            return func(...)
        end
        local startTime = tick()
        local results = table.pack(func(...))
        local duration = (tick() - startTime) * 1000 -- Convert to milliseconds
        if duration > 1 then -- Only log if it takes more than 1ms
            self:_Log(moduleName, funcName, duration)
        end
        return table.unpack(results, 1, results.n)
    end
end

-- ENTRY POINT
function logger:WrapModule(moduleTable, moduleName)
    for k, v in pairs(moduleTable) do
        if type(v) == "function" then
            moduleTable[k] = self:_Track(moduleName, k, v)
        end
    end
end

return logger