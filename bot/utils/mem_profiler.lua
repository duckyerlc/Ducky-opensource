local MemProfiler = {}

function MemProfiler.snapshot()
    collectgarbage('collect')
    return collectgarbage('count') * 1024
end

function MemProfiler.track_function(func, name)
    return function(...)
        local mem_before = MemProfiler.snapshot()
        local result = {func(...)}
        local mem_after = MemProfiler.snapshot()
        
        local mem_diff = mem_after - mem_before
        if mem_diff > 0 then
            print(string.format("[MemProfile] %s allocated %d bytes", name or "anonymous", mem_diff))
        end
        
        return table.unpack(result)
    end
end

return MemProfiler