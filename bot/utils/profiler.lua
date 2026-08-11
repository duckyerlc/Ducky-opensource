-- utils/profiler.lua
local uv = require("uv")

local Profiler = {}
Profiler.__index = Profiler

-- interval: check drift every ms
-- threshold: warn if drift exceeds this many ms
-- sample_rate: VM instruction count between hook samples
function Profiler.new(interval, threshold, sample_rate)
	local self = setmetatable({}, Profiler)
	self.interval = interval or 100
	self.threshold = threshold or 50
	self.sample_rate = sample_rate or 50000 -- adjust for performance vs detail
	self.timer = uv.new_timer()
	self.running = false
	self.samples = {}
	return self
end

function Profiler:start()
	if self.running then
		return
	end
	self.running = true
	local last = uv.now()

	-- Hook that samples the current executing location
	debug.sethook(function()
		local info = debug.getinfo(2, "Sl")
		if info and info.short_src then
			local key = info.short_src .. ":" .. (info.currentline or "?")
			self.samples[key] = (self.samples[key] or 0) + 1
		end
	end, "", self.sample_rate)

	self.timer:start(self.interval, self.interval, function()
		local now = uv.now()
		local drift = now - last - self.interval
		if drift > self.threshold then
			print(string.format("[Profiler] Main thread blocked for ~%dms", drift))
			-- Print the hottest locations seen recently
			local hot = {}
			for k, v in pairs(self.samples) do
				table.insert(hot, {
					k,
					v
				})
			end
			table.sort(hot, function(a, b)
				return a[2] > b[2]
			end)
			for i = 1, math.min(10, #hot) do
				print(string.format("  %s (%d hits)", hot[i][1], hot[i][2]))
			end
			-- reset counts for next period
			self.samples = {}
		end
		last = now
	end)
end

function Profiler:stop()
	if not self.running then
		return
	end
	self.running = false
	self.timer:stop()
	debug.sethook() -- remove hook
end

return Profiler
