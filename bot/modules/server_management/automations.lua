-- modules/automations.lua
local automations = {
    name = "automations",
    description = "Powers interval automations."
}

local Clock = discordia.Clock()
Clock:start()
local connection = nil

local active = false
local lastCheck = 0

automations.Start = function()
    connection = Clock:on("sec", function()
        if (not runAutomation) or ((os.time() - lastCheck) < 10) or (active == true) then
            return
        end

        active = true
        lastCheck = os.time()

        local success, err = pcall(function()
            local allGuilds = sqldb:getAllGuildConfigs()
            if not allGuilds or type(allGuilds) ~= "table" then
                return Client:error("AUTOMATIONS: getAllGuildConfigs returned invalid response: " .. tostring(allGuilds))
            end

            for guildid, config in pairs(allGuilds) do
                local success, err = pcall(function()
                    local guild = Client:getGuild(guildid)
                    if guild then
                        for _, automation in pairs(config.automations or {}) do
                            if automation.trigger.value == "interval" and automation.trigger.interval and not automation.disabled then
                                local interval = automation.trigger.interval
                                local now = realtime()
                                local lastTriggered = automation.lastTriggered or 0
                                local nextRun = (interval.type == "interval" and lastTriggered + interval.seconds) or intervalNextRun(automation.trigger.interval)

                                if (interval.type == "interval" and now >= nextRun) or (interval.type ~= "interval" and nextRun - now <= 20 and now - lastTriggered > 40) then
                                    coroutine.wrap(runAutomation)(automation, config, guild, nil, nil, nil, nextRun)
                                end
                            end
                        end
                    end
                end)
                if not success then
                    Client:error("AUTOMATIONS: Error processing automation for " .. tostring(guildid) .. ": " .. tostring(err))
                end
            end
        end)

        if not success then
            Client:error("AUTOMATIONS: Outer loop error: " .. tostring(err))
        end

        active = false
    end)
end

automations.Stop = function()
    Clock:removeListener("sec", connection)
    Clock:stop()
end

return automations