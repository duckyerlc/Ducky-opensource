-- modules/shifts.lua

local shifts = {
	name = "shifts",
	description = "Powers shift waves."
}

local connections = {}

shifts.Start = function()
    connections["scheduleShifts"] = Client:on("scheduleShifts", function(guild, config)
        if config.shifts and config.shifts.waveinterval then
            local now = realtime()
            local nextRun = intervalNextRun(config.shifts.waveinterval, now)

            if nextRun - now <= 20 then
                local currentWave = db:shiftWave(guild)

                if now - currentWave.started > 500 then
                    db:shiftWaveEnd(guild)
                end
            end
        end
    end)
end

shifts.Stop = function()
	for event, connection in pairs(connections) do
		Client:removeListener(event, connection)
	end

    connections = nil
end

return shifts
