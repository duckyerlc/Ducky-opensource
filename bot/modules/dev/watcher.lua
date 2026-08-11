-- watcher.lua

local function debugPrint(...)
    if false then -- debug toggle
        local args = {...}
        local msg = ""
        for i, v in ipairs(args) do
            msg = msg .. ((i > 1 and " ") or "") .. tostring(v)
        end
        prettyLog("WATCHER", "cyan", msg)
    end
end

local watcher = {
	name = "watcher",
	description = "Watches for abusive usage of Ducky.",
}

local Clock = discordia.Clock()
Clock:start()

local connections = {
	Client = {},
	Clock = {},
}

-- [user_id] = {{timestamp, command}, {timestamp, command.name}}

local commandAbuseInterval = 10
local commandAbuseThreshold = 5
local commandHistory = {}

watcher.Start = function()
    debugPrint("Watcher started")

    connections.Client["inGameCommand"] = Client:on("inGameCommand", function(roblox, full, command, message)
        local member = {
            username = "roblox/" .. roblox.name,
            guild = message.guild,
            id = tostring(roblox.id)
        }

        local command =  {
            name = command,
            full = full,
            timestamp = message.createdAt
        }

        Client:emit("commandUsed", member, command)
    end)

    connections.Client["commandUsed"] = Client:on("commandUsed", function(member, command)
        command.timestamp = math.floor(command.timestamp)
        local config = sqldb:get(member.guild.id) or {}

        debugPrint("commandUsed event", member, command)
        prettyLog("LOGS", "blue", "@" .. member.username .. " (" .. member.id .. ") used " .. command.full .. ((command.fail and (" but " .. command.fail)) or ""))

        coroutine.wrap(function()
            utilityChannels.commands:send(emojis.settings .. " **@" .. member.username .. " (`" .. member.id .. "`)** used **`" .. command.full:gsub("`", "") .. "`**" .. ((command.fail and (" but " .. command.fail)) or "") .. "\n-# " .. emojis.guild .. " " .. ((member.guild and member.guild.name) or "N/A") .. " (`" .. member.guild.id .. "`)・" .. emojis.clock .. " <t:" .. command.timestamp .. ":T>", true)
            
            local channel = member.guild:getChannel(command.channel)

            db:send(member.guild, "commandlogschannel", {content = emojis.settings .. " **@" .. member.username .. " (`" .. member.id .. "`)** used **`" .. command.full:gsub("`", "") .. "`**" .. ((command.fail and (" but " .. command.fail)) or "") .. "\n-# " .. emojis.link .. " " .. ((command.message and channel) and (command.message.link .. " (`" .. command.message.id .. "`)") or ((channel and (channel.mentionString .. " (`" .. channel.id .. "`)")) or "N/A")) .. "・" .. emojis.clock .. " <t:" .. command.timestamp .. ":T>"}, true)
        end)()

        commandHistory[member.id] = commandHistory[member.id] or {}
        table.insert(commandHistory[member.id], {
            timestamp = command.timestamp,
            command = command.name
        })
    end)
end

watcher.Stop = function()
    debugPrint("Watcher stopped")
	for event, connection in pairs(connections.Client) do
		Client:removeListener(event, connection)
	end

	for event, connection in pairs(connections.Clock) do
		Clock:removeListener(event, connection)
	end

	Clock:stop()
	commandHistory = nil
    connections = nil
end

return watcher
