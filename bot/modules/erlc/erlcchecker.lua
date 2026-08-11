-- erlcchecker.lua
local erlcchecker = {
	name = "erlcchecker",
	description = "Powers autoshifts, automations, and more to come."
	-- disabled = true
}

_G.erlcCycleId = (_G.erlcCycleId or 0) + 1
local currentCycleId = _G.erlcCycleId
local erlcCycleMinDelay = 31 -- in sec

local erlcStatusChannelsDebounceTime = 240 * 1000
local erlcStatusChannelsDebounce = {}

local snowGen = snowflake.new(1, 4)
local Clock = discordia.Clock()
Clock:start()

local connections = {
	Clock = {},
	Client = {},
	ERLC = {}
}

local function log(str, color)
	return prettyLog("ERLC", color or "blue", str)
end

local function debug(str)
	if false then -- debug switch
		return prettyLog("ERLC DEBUG", "cyan", str)
	end
end

local automationsrequiringerlcchecker = {
	playercount = true,
	playercountg = true,
	playercountl = true,
	playerjoin = true,
	playerleave = true,
	playerkill = true,
	emergencycall = true,
	modcall = true,
	modcallcount = true,
	vehiclespawn = true,
	liveryused = true,
	team = true,
	Civilian = true,
	Fire = true,
	Sheriff = true,
	Police = true,
	DOT = true,
	Jail = true,
	any = true, -- teamcount for any team
	regionentered = true,
	regionexited = true,
	trollusername = true,
	plate = true,
	callsign = true,
	killedin = true,
}

erlcchecker.Start = function()
	local erlcIntentions = {
		ingamerole = function(config)
			return not not config.ingamerole
		end,
		autoshifts = function(config)
			return not not (config.shifts and (config.shifts.gamelock or config.shifts.allowauto))
		end,
		trackmodcalls = function(config)
			return not not config.trackModcalls
		end,
		erlclogs = function(config)
			return not not (type(config.erlclogs) == "table" and next(config.erlclogs))
		end,
		bounties = function(config)
			return not not (type(config.economy) ==  "table" and type(config.economy.bounties) == "table" and next(config.economy.bounties))
		end,
		automations = function(config)
			for aid, automation in pairs(config.automations or {}) do
				local splitTrigger = string.split(automation.trigger.value, ":")
				local trigger = splitTrigger[1]

				if automationsrequiringerlcchecker[trigger] then
					return true
				end
			end
		end,
		statusmessage = function(config)
			return not not config.erlcserverstatusmessage
		end,
		statuschannels = function(config)
			return not not (type(config.erlcserverstatuschannels) == "table" and next(config.erlcserverstatuschannels))
		end,
		tempbans = function(config)
			return not not (type(config.erlctempbans) == "table" and next(config.erlctempbans)) -- doesn't actually need to be in erlcchecker, consider moving for further optimisation
		end,
		regions = function(config)
			return not not table.find(config.regions or {}, function(r)
				return not not r.voiceChannel
			end)
		end
	}

	local function runGuild(id)
		local guild = id and Client:getGuild(id)
		if not guild then
			return false, "A guild was not provided."
		end

		local config = sqldb:get(guild.id) or {}
		if not config.apikey then
			return false, "This guild is not linked with an ERLC server."
		end

		config.erlccache = config.erlccache or {}
		config.erlccache.timestamps = config.erlccache.timestamps or {}
		config.erlccache.old = config.erlccache.old or {}
		config.erlccache.old.server = config.erlccache.old.server or {}
		config.erlccache.old.timestamps = config.erlccache.old.timestamps or {}
		config.erlccache.old.timestamps.erlclogs = config.erlccache.old.timestamps.erlclogs or 0
		config.erlccache.old.automations = config.erlccache.old.automations or {}
		config.erlccache.old.automations.timestamps = config.erlccache.old.automations.timestamps or {}

		local function save(changes, reason)
			local success, err = sqldb:set(id, changes, reason)
			if success then
				for key, value in pairs(changes) do
					if tostring(value) == "nil" then
						config[key] = nil
					else
						config[key] = value
					end
				end
				return true, config
			else
				return false, err
			end
		end

		db:send(guild, "guildcyclednotifychannel", {
			content = emojis.cycle .. " This guild is being cycled...\n" .. "-# " .. emojis.clock .. " <t:" .. os.time() .. ":T>"
		})

		local server, err = ERLC:getServer(config.apikey)
		if not server then
			if err:match("Invalid Server%-Key") then
				save({apikey = "nil"}, "INVALID_SERVER_KEY")
				log("API key for " .. id .. " is invalid and has been removed.")
				return false, "Server key is invalid and has been removed"
			else
				log("Failed to fetch ERLC server for " .. id .. ": " .. tostring(err))
				return false, "Failed to fetch ERLC server: " .. tostring(err)
			end
		end

		local NOW = os.time()
		local PLAYERS = server.players
		local PLAYERCOUNT = #PLAYERS
		local STAFF = {}
		local TROLLUSERNAMES = {}
		local KILLS = server.killLogs
		local VEHICLES = server.vehicles
		local JOINS = server.joinLogs
		local QUEUE = server.queue
		local EMERGENCYCALLS = server.emergencyCalls
		local MODCALLS = server.modCalls
		local UNANSWERED_MODCALLS = 0
		local TEAMS = {
			["Civilian"] = 0,
			["DOT"] = 0,
			["Fire"] = 0,
			["Police"] = 0,
			["Sheriff"] = 0,
			["Jail"] = 0
		}

		local OLDTEAMS = {
			["Civilian"] = 0,
			["DOT"] = 0,
			["Fire"] = 0,
			["Police"] = 0,
			["Sheriff"] = 0,
			["Jail"] = 0
		}

		for _, player in pairs(PLAYERS) do
			if player.permission ~= erlua.enums.permission.normal then
				table.insert(STAFF, player)
			end

			if player.name:usub(1, 3):lower() == "all" or player.name:usub(1, 6):lower() == "others" or select(2, player.name:gsub("[Il][lI]", {})) >= 2 then
				table.insert(TROLLUSERNAMES, player)
			end

			local team = player.team or "Civilian"
			TEAMS[team] = TEAMS[team] + 1
		end

		for _, call in pairs(MODCALLS) do
			if (not call.moderator) then
				UNANSWERED_MODCALLS = UNANSWERED_MODCALLS + 1
			end
		end

		for _, oldPlayer in pairs(config.erlccache.old.server.players or {}) do
			if oldPlayer.team and OLDTEAMS[oldPlayer.team] then
				OLDTEAMS[oldPlayer.team] = OLDTEAMS[oldPlayer.team] + 1
			end
		end

		if config.erlccommandqueue and next(config.erlccommandqueue) and PLAYERCOUNT > 0 then
			local success, err = pcall(function()
				db:commandQueueExecute(guild)
			end)

			if not success then
				log("An error occurred while executing the command queue of " .. id .. ": " .. tostring(err), "red")
			end
		end

		------------------------------------------------------------------------------------------------------------------------------------------------

		if config.ingamerole then
			local success, err = pcall(function()
				loadMembers(guild)

				local role = guild:getRole(config.ingamerole)
				if not role then
					return save({
						ingamerole = "nil"
					}, "INVALID_INGAME_ROLE")
				end

				local success, result = canManageRole(config.ingamerole)
				if not success then
					save({
						ingamerole = "nil"
					}, "NO_PERMISSIONS_INGAME_ROLE")
					return NotifyRemoveFromConfig(guild.id, emojis.game .. " ERLC Integration", "In-Game Role", result)
				end

				for _, member in pairs(role.members) do
					local ingame = false

					for _, player in pairs(PLAYERS) do
						local link = sqldb:getLink(player.id)

						if (member.name:lower():find(player.name:lower()) or member.user.username:lower():find(player.name:lower())) or (link and link.discord == member.id) then
							ingame = true
							break
						end
					end

					if not ingame then
						member:removeRole(config.ingamerole, "linked Roblox account is no longer in-game")
					end
				end

				for _, player in pairs(PLAYERS) do
					local link = sqldb:getLink(player.id)
					local member = (link and guild:getMember(link.discord)) or table.find(guild.members, function(m)
						return m.name:lower():find(player.name:lower()) or m.user.username:lower():find(player.name:lower())
					end)

					if member and not member:hasRole(config.ingamerole) then
						member:addRole(config.ingamerole, "linked Roblox account is in-game")
					end
				end
			end)

			if not success then
				log("An error occurred while managing the in-game role of " .. id .. ": " .. tostring(err), "red")
			end
		end

		------------------------------------------------------------------------------------------------------------------------------------------------

		local success, err = pcall(function()
			for _, player in pairs(PLAYERS) do
				local link = sqldb:getLink(player.id)
				local member = link and link.discord and guild:getMember(link.discord)
				local userSettings = member and sqldb:getUserSettings(member.id) or {}

				if member and userSettings.trackplaytime ~= false and server then
					userSettings.playsessions = userSettings.playsessions or {}
					if not table.find(userSettings.playsessions, function(playsession)
						return playsession.discord == guild.id and not playsession.ended
					end) then
						table.insert(userSettings.playsessions, {
							started = os.time(),
							discord = guild.id
						})
						sqldb:setUserSettings(member.id, userSettings)
					end
				end

				if player.permission ~= erlua.enums.permission.normal and member and hasPermission(member, "ERLC_STAFF") and userSettings.autoshifts and config.shifts and config.shifts.types and next(config.shifts.types) then
					local type
					for _, t in pairs(config.shifts.types) do
						if t.requiredrole then
							if member:hasRole(t.requiredrole) then
								type = t.name
							end
						end
					end
					type = db:shiftType(guild, type, member)

					local active = db:shiftActive(member)
					if (not active) and type then
						local shift, err, igerr = db:shiftStart({
							id = snowGen:next()
						}, member, type.name, true)
						if shift then
							member:success("Your " .. shift.type .. " shift has been automatically started in **" .. member.guild.name .. "**.")
							server:execute(":pm " .. player.name .. " ✅・Ducky has automatically started your " .. type.name .. " shift.")
						else
							member:fail("An error occurred while automatically starting your **" .. type.name .. "** shift in **" .. member.guild.name .. "**:\n" .. emojis.right .. " " .. err)
							server:execute(":pm " .. player.name .. " ❌・" .. (igerr or err))
						end
					end
				end
			end
		end)

		if not success then
			log("An error occurred while iterating players of " .. id .. ": " .. tostring(err), "red")
		end

		local success, err = pcall(function()
			for id, settings in pairs(sqldb.cache and sqldb.cache.user_settings or {}) do
				local modified = false
				if settings.playsessions then
					for _, playsession in pairs(settings.playsessions) do
						if playsession.discord == guild.id and not playsession.ended then
							local member = guild:getMember(id)
							local link = member and sqldb:getLink(member.id)

							if (not member) or (not link) or (not link.roblox) or (not table.find(PLAYERS or {}, function(player)
								return tonumber(player.id) == tonumber(link.roblox)
							end)) then
								playsession.ended = os.time()
								modified = true
							end
						end
					end
				end

				if modified then
					sqldb:setUserSettings(id, settings)
				end
			end
		end)

		if not success then
			log("An error occurred while ending playsessions of " .. id .. ": " .. tostring(err), "red")
		end

		if config.shifts and config.shifts.types and next(config.shifts.types) then
			local success, err = pcall(function()
				local wave, err = db:shiftWave(guild)

				if wave then
					for _, shift in pairs(wave.shifts or {}) do
						if not shift.ended then
							local member = guild:getMember(shift.member)

							if member then
								local us = sqldb:getUserSettings(member.id) or {}

								if us.autoshifts or config.shifts.gamelock then
									local link = sqldb:getLink(member.id)
									local ingame = link and table.find(PLAYERS or {}, function(player)
										return player.permission ~= erlua.enums.permission.normal and tonumber(player.id) == tonumber(link.roblox)
									end) or false

									if not ingame then
										local success, err = db:shiftEnd(member)

										if success then
											member:success("Your **" .. shift.type .. "** shift has been automatically ended in **" .. guild.name .. "**.")
										else
											member:fail("An error occurred while attempting to automatically end your **" .. shift.type .. "** shift in **" .. guild.name .. "**:\n" .. emojis.right .. " " .. err)
										end
									end
								end
							end
						end
					end
				end
			end)

			if not success then
				log("An error occurred while checking autoshifts and gamelock of " .. id .. ": " .. tostring(err), "red")
			end
		end

		------------------------------------------------------------------------------------------------------------------------------------------------

		if config.trackModcalls then
			local success, err = pcall(function()
				config.trackedModcalls = config.trackedModcalls or {}
				local lastTrackedModcallTimestamp = config.erlccache.old.timestamps.trackedModcall or 0
				local newModcalls = {}

				for _, modcall in pairs(MODCALLS) do
					if modcall.timestamp > lastTrackedModcallTimestamp and modcall.moderator then
						lastTrackedModcallTimestamp = modcall.timestamp
						local moderator = modcall.moderator

						local link = sqldb:getLink(moderator.id)

						if link then
							config.trackedModcalls[link.discord] = config.trackedModcalls[link.discord] or {}
							table.insert(config.trackedModcalls[link.discord], modcall.timestamp)
							newModcalls[link.discord] = newModcalls[link.discord] or {}
							table.insert(newModcalls[link.discord], modcall.timestamp)
						end
					end
				end

				for moderatorId, timestamps in pairs(newModcalls) do
					if next(timestamps) then
						local jsonArray = "[" .. table.concat(timestamps, ",") .. "]"
						sqldb:_queryRun({
							query = [[
								UPDATE guilds 
								SET setting_value = json_set(
									COALESCE(setting_value, '{}'),
									'$.' || ?,
									json((
										SELECT json_group_array(value)
										FROM (
											SELECT value FROM json_each(COALESCE(json_extract(setting_value, '$.' || ?), '[]'))
											UNION ALL
											SELECT value FROM json_each(?)
										)
									))
								)
								WHERE guild_id = ? AND setting_key = 'trackedModcalls';
							]],
							values = {moderatorId, moderatorId, jsonArray, guild.id}
						})
					end
				end

				config.erlccache.old.timestamps.trackedModcalls = lastTrackedModcallTimestamp
				sqldb:_queryRun({
					query = [[
						UPDATE guilds 
						SET setting_value = json_set(
							COALESCE(setting_value, '{}'),
							'$.erlccache.old.timestamps.trackedModcall',
							?
						)
						WHERE guild_id = ? AND setting_key = 'erlccache';
					]],
					values = {lastTrackedModcallTimestamp, guild.id}
				})
			end)

			if not success then
				log("An error occurred while tracking modcalls of " .. id .. ": " .. tostring(err), "red")
			end
		end

		------------------------------------------------------------------------------------------------------------------------------------------------

		if type(config.trackedModcalls) == "table" and table.count(config.trackedModcalls) > 0 then
			local success, err = pcall(function()
				local expirationThreshold = NOW - 2592000

				for moderatorID, trackedModcalls in pairs(config.trackedModcalls) do
					local newTable = {}
					for _, modcallTimestamp in ipairs(trackedModcalls) do
						if modcallTimestamp > expirationThreshold then
							table.insert(newTable, modcallTimestamp)
						end
					end

					if #newTable > 0 then
						config.trackedModcalls[moderatorID] = newTable
					else
						config.trackedModcalls[moderatorID] = nil
					end
				end

				sqldb:_queryRun({
					query = [[
						UPDATE guilds
						SET setting_value = (
							SELECT COALESCE(
								'{' || GROUP_CONCAT('"' || mod_id || '":' || ts_array, ',') || '}',
								'{}'
							)
							FROM (
								SELECT
									outer_kv.key AS mod_id,
									json_group_array(inner_ts.value) AS ts_array
								FROM
									json_each(setting_value) AS outer_kv,
									json_each(outer_kv.value) AS inner_ts
								WHERE CAST(inner_ts.value AS INTEGER) > ?
								GROUP BY outer_kv.key
							)
						)
						WHERE guild_id = ?
						AND setting_key = 'trackedModcalls'
						AND setting_value IS NOT NULL;
					]],
					values = {expirationThreshold, guild.id}
				})
			end)

			if not success then
				log("An error occurred while deleting old tracked modcalls of " .. id .. ": " .. tostring(err), "red")
			end
		end

		------------------------------------------------------------------------------------------------------------------------------------------------

		if (PLAYERCOUNT > 0) or (table.count(config.erlccache.old.server.players) > 0) then
			if type(config.erlclogs) == "table" and next(config.erlclogs) then
				local success, err = pcall(function()
					local logs = {}

					if config.erlclogs.playerjoin then
						local info = config.erlclogs.playerjoin
						for _, log in pairs(JOINS) do
							if log.type == erlua.enums.joinLogType.join and log.timestamp > (config.erlccache.old.timestamps.erlclogs or 0) then
								table.insert(logs, {
									log = log,
									type = "playerjoin"
								})
							end
						end
					end

					if config.erlclogs.playerleave then
						local info = config.erlclogs.playerleave
						for _, log in pairs(JOINS) do
							if log.type == erlua.enums.joinLogType.leave and log.timestamp > (config.erlccache.old.timestamps.erlclogs or 0) then
								table.insert(logs, {
									log = log,
									type = "playerleave"
								})
							end
						end
					end

					if config.erlclogs.playerkill then
						local info = config.erlclogs.playerkill
						for _, log in pairs(KILLS) do
							if log.timestamp > (config.erlccache.old.timestamps.erlclogs or 0) then
								table.insert(logs, {
									log = log,
									type = "playerkill"
								})
							end
						end
					end

					if config.erlclogs.modcall then
						local info = config.erlclogs.modcall
						for _, log in pairs(MODCALLS) do
							if log.moderator and log.timestamp > (config.erlccache.old.timestamps.erlclogs or 0) then
								table.insert(logs, {
									log = log,
									type = "modcall"
								})
							end
						end
					end
							
					if config.erlclogs.playerteam then
						local info = config.erlclogs.playerteam
						for _, player in pairs(PLAYERS) do
							local previousPlayer = table.find(config.erlccache.old.server.players or {}, function(p)
								return p.id == player.id
							end)

							if (previousPlayer and previousPlayer.team) ~= player.team then
								table.insert(logs, {
									log = {
										player = player,
										timestamp = NOW
									},
									type = "playerteam"
								})
							end
						end
					end

					table.sort(logs, function(a, b)
						return a.log.timestamp < b.log.timestamp
					end)

					for _, entry in pairs(logs) do
						local info = config.erlclogs[entry.type]
						local log = entry.log
						local keys = {
							["timestamp"] = entry.log.timestamp
						}
						local channel = guild:getChannel(info.channel)

						if channel then
							if entry.type == "playerjoin" or entry.type == "playerleave" then
								if hasKeys(info.tosend, {
									"{player.display}",
									"{player.avatar}",
									"{player.description}",
									"{player.banned}",
									"{player.verified}"
								}) then
									keys = RobloxUserVariables(ropi.GetUser(log.player.id), "player", keys)
								else
									keys["player.name"] = log.player.name
									keys["player.id"] = log.player.id
									keys["player.profile"] = log.player.profile
									keys["player.hyperlink"] = log.player.hyperlink
								end
							elseif entry.type == "playerkill" then
								if hasKeys(info.tosend, {
									"{killer.display}",
									"{killer.avatar}",
									"{killer.description}",
									"{killer.banned}",
									"{killer.verified}"
								}) then
									keys = RobloxUserVariables(ropi.GetUser(log.killer.id), "killer", keys)
								else
									keys["killer.name"] = log.killer.name
									keys["killer.id"] = log.killer.id
									keys["killer.profile"] = log.killer.profile
									keys["killer.hyperlink"] = log.killer.hyperlink
								end

								if hasKeys(info.tosend, {
									"{killed.display}",
									"{killed.avatar}",
									"{killed.description}",
									"{killed.banned}",
									"{killed.verified}"
								}) then
									keys = RobloxUserVariables(ropi.GetUser(log.killed.id), "killed", keys)
								else
									keys["killed.name"] = log.killed.name
									keys["killed.id"] = log.killed.id
									keys["killed.profile"] = log.killed.profile
									keys["killed.hyperlink"] = log.killed.hyperlink
								end
							elseif entry.type == "modcall" then
								if hasKeys(info.tosend, {
									"{caller.display}",
									"{caller.avatar}",
									"{caller.description}",
									"{caller.banned}",
									"{caller.verified}"
								}) then
									keys = RobloxUserVariables(ropi.GetUser(log.caller.id), "caller", keys)
								else
									keys["caller.name"] = log.caller.name
									keys["caller.id"] = log.caller.id
									keys["caller.profile"] = log.caller.profile
									keys["caller.hyperlink"] = log.caller.hyperlink
								end

								if hasKeys(info.tosend, {
									"{moderator.display}",
									"{moderator.avatar}",
									"{moderator.description}",
									"{moderator.banned}",
									"{moderator.verified}"
								}) then
									keys = RobloxUserVariables(ropi.GetUser(log.moderator.id), "moderator", keys)
								else
									keys["moderator.name"] = log.moderator.name
									keys["moderator.id"] = log.moderator.id
									keys["moderator.profile"] = log.moderator.profile
									keys["moderator.hyperlink"] = log.moderator.hyperlink
								end
							elseif entry.type == "playerteam" then
								keys["player.team"] = log.player.team

								if hasKeys(info.tosend, {
									"{player.display}",
									"{player.avatar}",
									"{player.description}",
									"{player.banned}",
									"{player.verified}"
								}) then
									keys = RobloxUserVariables(ropi.GetUser(log.player.id), "player", keys)
								else
									keys["player.name"] = log.player.name
									keys["player.id"] = log.player.id
									keys["player.profile"] = log.player.profile
									keys["player.hyperlink"] = log.player.hyperlink
								end
							end

							local tosend = parseTable(info.tosend, keys)
							coroutine.wrap(function()
								channel:send(tosend)
							end)()
						end

						if entry.type ~= "playerteam" then
							config.erlccache.old.timestamps.erlclogs = log.timestamp
						end
					end

					logs = nil -- cleanup?

					if config.erlccache.old.timestamps.erlclogs then
						sqldb:_queryRun({
							query = [[
								UPDATE guilds 
								SET setting_value = json_set(
									COALESCE(setting_value, '{}'),
									'$.erlccache.old.timestamps.erlclogs',
									?
								)
								WHERE guild_id = ? AND setting_key = 'erlccache';
							]],
							values = {config.erlccache.old.timestamps.erlclogs, guild.id}
						})
					end
				end)

				if not success then
					log("An error occurred while sending erlclogs of " .. id .. ": " .. tostring(err), "red")
				end
			end

			------------------------------------------------------------------------------------------------------------------------------------------------

			if config.regions and next(config.regions) then
				local success, err = pcall(function()
					for i, region in pairs(config.regions) do
						local vc = region.voiceChannel and guild:getChannel(region.voiceChannel)
						if vc then
							local Region = erlua.Region(region.name, region.points)

							for _, player in pairs(PLAYERS) do
								local link = sqldb:getLink(player.id)
								local member = link and guild:getMember(link.discord)

								if member and member.voiceChannel then
									if Region:contains(player.location) then
										if member.voiceChannel.id ~= region.voiceChannel and ((not config.regionwaitingvc) or (member.voiceChannel.id == config.regionwaitingvc)) then
											coroutine.wrap(function()
												member:setVoiceChannel(region.voiceChannel)
											end)()
										end
									elseif config.regionwaitingvc and member.voiceChannel.id == region.voiceChannel then
										coroutine.wrap(function()
											member:setVoiceChannel(config.regionwaitingvc)
										end)()
									end
								end
							end
						end
					end
				end)

				if not success then
					log("An error occurred while managing region VCs for " .. id .. ": " .. tostring(err), "red")
				end
			end

			------------------------------------------------------------------------------------------------------------------------------------------------

			local automationRequiresCaching = {}

			local automationTriggers = {
				playercount = function(automation, value, value2, trigger)
					local recentPlayerCount = table.count(config.erlccache.old.server.players) or -1
					if (PLAYERCOUNT == value) and (recentPlayerCount ~= PLAYERCOUNT) then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS)
					end
				end,
				playercountg = function(automation, value, value2, trigger)
					local recentPlayerCount = table.count(config.erlccache.old.server.players) or -1
					if (PLAYERCOUNT > value) and (not (recentPlayerCount > value)) then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS)
					end
				end,
				playercountl = function(automation, value, value2, trigger)
					local recentPlayerCount = table.count(config.erlccache.old.server.players) or -1
					if (PLAYERCOUNT < value) and (not (recentPlayerCount < value)) then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS)
					end
				end,
				playerjoin = function(automation, value, value2, trigger)
					local lastJoinLogTimestamp = config.erlccache.old.automations.timestamps.joinlog or 0
					local executions = {}

					for _, log in ipairs(JOINS) do
						local timestamp = log.timestamp

						if (log.type == erlua.enums.joinLogType.join and timestamp > lastJoinLogTimestamp) then
							local keys = {
								["player.name"] = log.player.name,
								["player.id"] = log.player.id,
								["player.profile"] = log.player.profile,
								["player.hyperlink"] = log.player.hyperlink,
								["timestamp"] = timestamp
							}

							table.insert(executions, keys)
						end
					end

					if table.count(executions) > 0 then
						automationRequiresCaching.joins = true
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end,
				playerleave = function(automation, value, value2, trigger)
					local lastLeaveLogTimestamp = config.erlccache.old.automations.timestamps.joinlog or 0
					local executions = {}

					for _, log in ipairs(JOINS) do
						local timestamp = log.timestamp

						if (log.type == erlua.enums.joinLogType.leave and timestamp > lastLeaveLogTimestamp) then
							local keys = {
								["player.name"] = log.player.name,
								["player.id"] = log.player.id,
								["player.profile"] = log.player.profile,
								["player.hyperlink"] = log.player.hyperlink,
								["timestamp"] = timestamp
							}

							table.insert(executions, keys)
						end
					end

					if table.count(executions) > 0 then
						automationRequiresCaching.joins = true
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end,
				playerkill = function(automation, value, value2, trigger)
					local lastKillLogTimestamp = config.erlccache.old.automations.timestamps.kill or 0

					local executions = {}

					for _, kill in ipairs(KILLS) do
						local timestamp = kill.timestamp

						if lastKillLogTimestamp < timestamp then
							local keys = {
								["killer.name"] = kill.killer.name,
								["killer.id"] = kill.killer.id,
								["killer.profile"] = kill.killer.profile,
								["killer.hyperlink"] = kill.killer.hyperlink,
								["killed.name"] = kill.killed.name,
								["killed.id"] = kill.killed.id,
								["killed.profile"] = kill.killed.profile,
								["killed.hyperlink"] = kill.killed.hyperlink,
								["timestamp"] = timestamp
							}

							table.insert(executions, keys)
						end
					end

					if table.count(executions) > 0 then
						automationRequiresCaching.kills = true
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end,
				emergencycall = function(automation, value, value2, trigger)
					local lastEmergencyCallTimestamp = config.erlccache.old.automations.timestamps.emergencycall or 0

					local executions = {}

					for _, call in ipairs(EMERGENCYCALLS) do
						local timestamp = call.timestamp

						if (lastEmergencyCallTimestamp < timestamp) then
							local keys = {
								["call.team"] = call.team,
								["call.number"] = tostring(call.number),
								["call.description"] = call.description or emojis.fail,
								["call.position.x"] = call.position.x,
								["call.position.z"] = call.position.z,
								["call.position.descriptor"] = call.positionDescriptor or emojis.fail,
								["caller.name"] = call.caller and call.caller.name or emojis.fail,
								["caller.id"] = call.caller and call.caller.id or emojis.fail,
								["caller.profile"] = call.caller and call.caller.profile or emojis.fail,
								["caller.hyperlink"] = call.caller and call.caller.hyperlink or emojis.fail,
								["timestamp"] = timestamp
							}

							table.insert(executions, keys)
						end
					end

					if table.count(executions) > 0 then
						automationRequiresCaching.emergencycalls = true
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end,
				modcall = function(automation, value, value2, trigger)
					local lastModcallLogTimestamp = config.erlccache.old.automations.timestamps.modcall or 0

					local executions = {}

					for _, call in ipairs(MODCALLS) do
						local timestamp = call.timestamp

						if (lastModcallLogTimestamp < timestamp) and call.moderator then
							local keys = {
								["caller.name"] = call.caller.name,
								["caller.id"] = call.caller.id,
								["caller.profile"] = call.caller.profile,
								["caller.hyperlink"] = call.caller.hyperlink,
								["moderator.name"] = call.moderator.name,
								["moderator.id"] = call.moderator.id,
								["moderator.profile"] = call.moderator.profile,
								["moderator.hyperlink"] = call.moderator.hyperlink,
								["timestamp"] = timestamp
							}

							table.insert(executions, keys)
						end
					end

					if table.count(executions) > 0 then
						automationRequiresCaching.modcalls = true
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end,
				modcallcount = function(automation, value, value2, trigger)
					local oldUnansweredModcallCount = 0

					for _, modcall in pairs((config.erlccache.old.server and config.erlccache.old.server.modCalls) or {}) do
						if not modcall.moderator then
							oldUnansweredModcallCount = oldUnansweredModcallCount + 1
						end
					end

					if (UNANSWERED_MODCALLS >= value) and (not (oldUnansweredModcallCount >= UNANSWERED_MODCALLS)) then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS)
					end
				end,
				vehiclespawn = function(automation, value, value2, trigger)
					local executions = {}

					local bannedVehicles = {}
					for name in value:gmatch("[^,]+") do
						bannedVehicles[name:lower():match("^%s*(.-)%s*$")] = true
					end

					for _, v in pairs(VEHICLES) do
						local ingamePlayer = v.owner.team and v.owner

						if ingamePlayer then
							local lastVehicle = table.find(config.erlccache.old.server.vehicles or {}, function(p)
								return p.owner and p.owner.id == ingamePlayer.id
							end)

							if ((not lastVehicle) or (lastVehicle.name ~= v.name) or (lastVehicle.livery ~= v.livery)) and (v and bannedVehicles[v.name:lower()]) then
								local keys = {
									["player.name"] = ingamePlayer.name,
									["player.id"] = tostring(ingamePlayer.id),
									["player.profile"] = ingamePlayer.profile,
									["player.hyperlink"] = ingamePlayer.hyperlink,
									["vehicle.name"] = v.name,
									["vehicle.make"] = v.make or emojis.fail,
									["vehicle.model"] = v.model or emojis.fail,
									["vehicle.year"] = v.year or emojis.fail,
									["vehicle.plate"] = v.plate or emojis.fail,
									["vehicle.livery"] = v.livery or emojis.fail,
									["vehicle.color"] = v.color or emojis.fail,
									["timestamp"] = NOW
								}

								table.insert(executions, keys)
							end
						end
					end

					if table.count(executions) > 0 then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end,
				regionentered = function(automation, value, value2, trigger)
					local executions = {}

					local region = table.find(config.regions or {}, function(r)
						return r.name:lower() == value:lower()
					end)
					if region then
						local Region = erlua.Region(region.name, region.points)

						for _, player in pairs(PLAYERS or {}) do
							local previousPlayer = table.find(config.erlccache.old.server.players or {}, function(p)
								return p.id == player.id
							end)

							if not (previousPlayer and Region:contains(previousPlayer.location)) and Region:contains(player.location) then
								local keys = {
									["player.name"] = player.name,
									["player.id"] = tostring(player.id),
									["player.profile"] = player.profile,
									["player.hyperlink"] = player.hyperlink,
									["region.name"] = region.team,
									["region.area"] = Region.area,
									["region.points"] = #region.points,
									["timestamp"] = NOW
								}

								table.insert(executions, keys)
							end
						end
					end

					if table.count(executions) > 0 then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end,
				regionexited = function(automation, value, value2, trigger)
					local executions = {}

					local region = table.find(config.regions or {}, function(r)
						return r.name:lower() == value:lower()
					end)
					if region then
						local Region = erlua.Region(region.name, region.points)

						for _, player in pairs(PLAYERS or {}) do
							local previousPlayer = table.find(config.erlccache.old.server.players or {}, function(p)
								return p.id == player.id
							end)

							if (previousPlayer and Region:contains(previousPlayer.location)) and not Region:contains(player.location) then
								local keys = {
									["player.name"] = player.name,
									["player.id"] = tostring(player.id),
									["player.profile"] = player.profile,
									["player.hyperlink"] = player.hyperlink,
									["region.name"] = region.team,
									["region.area"] = Region.area,
									["region.points"] = #region.points,
									["timestamp"] = NOW
								}

								table.insert(executions, keys)
							end
						end
					end

					if table.count(executions) > 0 then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end,
				liveryused = function(automation, value, value2, trigger)
					local executions = {}

					for _, v in pairs(VEHICLES) do
						if v.livery then
							if v.livery:lower() == value:lower() then
								local ingamePlayer = v.owner.team and v.owner

								if ingamePlayer then
									local lastVehicle = table.find(config.erlccache.old.server.vehicles or {}, function(p)
										return p.owner and p.owner.id == ingamePlayer.id
									end)

									if (v.livery:lower() ~= "standard" or ingamePlayer.team ~= "Civilian") and ((not lastVehicle) or (lastVehicle.name ~= v.name) or (lastVehicle.livery ~= v.livery)) then
										local keys = {
											["player.name"] = ingamePlayer.name,
											["player.id"] = tostring(ingamePlayer.id),
											["player.profile"] = ingamePlayer.profile,
											["player.hyperlink"] = ingamePlayer.hyperlink,
											["vehicle.name"] = v.name,
											["vehicle.make"] = v.make or emojis.fail,
											["vehicle.model"] = v.model or emojis.fail,
											["vehicle.year"] = v.year or emojis.fail,
											["vehicle.plate"] = v.plate or emojis.fail,
											["vehicle.livery"] = v.livery or emojis.fail,
											["vehicle.color"] = v.color or emojis.fail,
											["timestamp"] = NOW
										}

										table.insert(executions, keys)
									end
								end
							end
						end
					end

					if table.count(executions) > 0 then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end,
				team = function(automation, value, value2, trigger)
					local executions = {}

					for _, player in pairs(PLAYERS or {}) do
						local previousPlayer = table.find(config.erlccache.old.server.players or {}, function(p)
							return p.id == player.id
						end)

						if ((player.team:lower() == value:lower()) or (not value) or (value == "any")) and (not previousPlayer or previousPlayer.team ~= player.team) then
							local keys = {
								["player.name"] = player.name,
								["player.id"] = tostring(player.id),
								["player.profile"] = player.profile,
								["player.hyperlink"] = player.hyperlink,
								["player.team"] = player.team,
								["timestamp"] = NOW
							}

							table.insert(executions, keys)
						end
					end

					if table.count(executions) > 0 then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end,
				Civilian = function(automation, value, value2, trigger)
					local team = "Civilian"
					local amount = value
					local lastPlayerCountForTeam = OLDTEAMS[team] or -1

					if ((TEAMS[team] >= amount) and (not (lastPlayerCountForTeam >= TEAMS[team]))) then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, {
							{
								["team"] = team,
								["timestamp"] = NOW
							}
						})
					end
				end,
				Fire = function(automation, value, value2, trigger)
					local team = "Fire"
					local amount = value
					local lastPlayerCountForTeam = OLDTEAMS[team] or -1

					if ((TEAMS[team] >= amount) and (not (lastPlayerCountForTeam >= TEAMS[team]))) then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, {
							{
								["team"] = team,
								["timestamp"] = NOW
							}
						})
					end
				end,
				Sheriff = function(automation, value, value2, trigger)
					local team = "Sheriff"
					local amount = value
					local lastPlayerCountForTeam = OLDTEAMS[team] or -1

					if ((TEAMS[team] >= amount) and (not (lastPlayerCountForTeam >= TEAMS[team]))) then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, {
							{
								["team"] = team,
								["timestamp"] = NOW
							}
						})
					end
				end,
				Police = function(automation, value, value2, trigger)
					local team = "Police"
					local amount = value
					local lastPlayerCountForTeam = OLDTEAMS[team] or -1

					if ((TEAMS[team] >= amount) and (not (lastPlayerCountForTeam >= TEAMS[team]))) then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, {
							{
								["team"] = team,
								["timestamp"] = NOW
							}
						})
					end
				end,
				DOT = function(automation, value, value2, trigger)
					local team = "DOT"
					local amount = value
					local lastPlayerCountForTeam = OLDTEAMS[team] or -1

					if ((TEAMS[team] >= amount) and (not (lastPlayerCountForTeam >= TEAMS[team]))) then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, {
							{
								["team"] = team,
								["timestamp"] = NOW
							}
						})
					end
				end,
				Jail = function(automation, value, value2, trigger)
					local team = "Jail"
					local amount = value
					local lastPlayerCountForTeam = OLDTEAMS[team] or -1

					if ((TEAMS[team] >= amount) and (not (lastPlayerCountForTeam >= TEAMS[team]))) then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, {
							{
								["team"] = team,
								["timestamp"] = NOW
							}
						})
					end
				end,
				any = function(automation, value, value2, trigger)
					local executions = {}

					for name, count in pairs(TEAMS) do
						local old = OLDTEAMS[name] or -1
						if count >= value and not (old >= count) then
							local keys = {
								["team"] = name,
								["timestamp"] = NOW
							}

							table.insert(executions, keys)
						end
					end

					if table.count(executions) > 0 then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end,
				trollusername = function(automation, value, value2, trigger)
					local trolls = TROLLUSERNAMES or {}
					local previousPlayers = config.erlccache.old.server.players or {}
					local executions = {}

					for i, player in pairs(trolls) do
						local alreadyTriggered = table.find(previousPlayers, function(p)
							return p.name == player.name or p.id == player.id
						end)

						if not alreadyTriggered then
							local keys = {
								["player.name"] = player.name,
								["player.id"] = player.id,
								["player.profile"] = player.profile,
								["player.hyperlink"] = player.hyperlink,
								["timestamp"] = NOW
							}

							table.insert(executions, keys)
						end
					end

					if table.count(executions) > 0 then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end,
				plate = function(automation, value, value2, trigger)
					value = tostring(value)

					local executions = {}

					for _, vehicle in pairs(VEHICLES or {}) do
						local previousVehicle = table.find(config.erlccache.old.server.vehicles or {}, function(v)
							return vehicle.name == v.name and vehicle.owner and v.owner and vehicle.owner.id == v.owner.id
						end)

						if vehicle and (not previousVehicle or previousVehicle.plate ~= vehicle.plate) then
							local pass = true

							for i = 1, value:len() do
								local char = vehicle.plate:usub(i, i):lower()
								local pattern = value:usub(i, i):lower()

								if (pattern == "@" and not char:match("%a")) or (pattern == "#" and not char:match("%d")) or (pattern ~= "*" and pattern ~= "@" and pattern ~= "#" and char ~= pattern) then
									pass = false
								end
							end

							if pass then
								local keys = {
									["vehicle.name"] = vehicle.name,
									["vehicle.make"] = vehicle.make or emojis.fail,
									["vehicle.model"] = vehicle.model or emojis.fail,
									["vehicle.year"] = vehicle.year or emojis.fail,
									["vehicle.plate"] = vehicle.plate or emojis.fail,
									["vehicle.livery"] = vehicle.livery or emojis.fail,
									["vehicle.color"] = vehicle.livery or emojis.fail,
									["player.name"] = vehicle.owner.name,
									["player.id"] = vehicle.owner.id,
									["player.profile"] = vehicle.owner.profile,
									["player.hyperlink"] = vehicle.owner.hyperlink,
									["player.team"] = vehicle.owner.team,
									["player.callsign"] = vehicle.owner.callsign,
									["timestamp"] = NOW
								}

								table.insert(executions, keys)
							end
						end
					end

					if table.count(executions) > 0 then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end,
				callsign = function(automation, value, value2, trigger)
					value = tostring(value)

					local executions = {}

					for _, player in pairs(PLAYERS or {}) do
						local previousPlayer = table.find(config.erlccache.old.server.players or {}, function(p)
							return p.id == player.id
						end)

						if player.callsign and (not previousPlayer.callsign or previousPlayer.callsign ~= player.callsign) then
							local pass = true

							for i = 1, value:len() do
								local char = player.callsign:usub(i, i)
								local pattern = value:usub(i, i)

								if (pattern == "@" and not char:match("%a")) or (pattern == "#" and not char:match("%d")) or (pattern ~= "*" and pattern ~= "@" and pattern ~= "#" and char ~= pattern) then
									pass = false
								end
							end

							if pass then
								local keys = {
									["player.name"] = player.name,
									["player.id"] = player.id,
									["player.profile"] = player.profile,
									["player.hyperlink"] = player.hyperlink,
									["player.team"] = player.team,
									["player.callsign"] = player.callsign,
									["timestamp"] = NOW
								}

								table.insert(executions, keys)
							end
						end
					end

					if table.count(executions) > 0 then
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end,
				killedin = function(automation, value, value2, trigger)
					local killedinHistory = config.erlccache.old.killedin or {}
					local executions = {}

					local PlayerKills = {}

					for _, kill in pairs(KILLS) do
						if not killedinHistory[kill.killer.id] or not table.find(killedinHistory[kill.killer.id], kill.timestamp) then
							PlayerKills[kill.killer.id] = PlayerKills[kill.killer.id] or {}
							table.insert(PlayerKills[kill.killer.id], kill.timestamp)
						end
					end

					local function killStreak(timestamps)
						table.sort(timestamps)

						local requiredKills = value
						local timeWindow = value2

						for i = 1, #timestamps - requiredKills + 1 do
							local startTime = timestamps[i]
							local endTime = timestamps[i + requiredKills - 1]
							if (endTime - startTime) <= timeWindow then
								return true
							end
						end
						return false
					end

					for killerID, timestamps in pairs(PlayerKills) do
						if killStreak(timestamps) then
							local ingamePlayer = table.find(PLAYERS, function(p)
								return p.id == killerID
							end)

							if ingamePlayer then
								local keys = {
									["killer.name"] = ingamePlayer.name,
									["killer.id"] = ingamePlayer.id,
									["killer.profile"] = ingamePlayer.profile,
									["killer.hyperlink"] = ingamePlayer.hyperlink,
									["timestamp"] = NOW
								}

								table.insert(executions, keys)
							end
						end
					end

					if table.count(executions) > 0 then
						automationRequiresCaching.killedin = PlayerKills
						p("running ts automation", PlayerKills)
						coroutine.wrap(runAutomation)(automation, config, guild, PLAYERS, nil, executions)
					end
				end
			}

			for aid, automation in pairs(config.automations or {}) do
				local splitTrigger = string.split(automation.trigger.value, ":")
				local trigger = splitTrigger[1]
				local value = (splitTrigger[2] and tonumber(splitTrigger[2])) or splitTrigger[2]
				local value2 = (splitTrigger[3] and tonumber(splitTrigger[3])) or splitTrigger[3]

				if automationTriggers[trigger] then
					local success, err = pcall(function()
						automationTriggers[trigger](automation, value, value2, trigger)
					end)

					if not success then
						log("An error occurred while executing an automation " .. aid .. " with trigger '" .. trigger .. "' in " .. id .. ": " .. tostring(err), "red")
					end
				end
			end

			if type(automationRequiresCaching) == "table" then
				local placeholders = {}
				local params = {}
				local hasChanges = false

				local function addNumeric(path, value)
					table.insert(placeholders, "?, ?")
					table.insert(params, path)
					table.insert(params, value)
					hasChanges = true
				end

				local function addJson(path, value)
					table.insert(placeholders, "?, json(?)")
					table.insert(params, path)
					table.insert(params, value)
					hasChanges = true
				end

				for trigger, cache in pairs(automationRequiresCaching) do
					if cache then
						if trigger == "joins" then
							local max_ts = config.erlccache.old.automations.timestamps.joinlog or 0
							for _, log in pairs(JOINS) do max_ts = math.max(log.timestamp, max_ts) end
							if max_ts > (config.erlccache.old.automations.timestamps.joinlog or 0) then
								config.erlccache.old.automations.timestamps.joinlog = max_ts
								addNumeric("$.old.automations.timestamps.joinlog", max_ts)
							end
						elseif trigger == "kills" then
							local max_ts = config.erlccache.old.automations.timestamps.kill or 0
							for _, log in pairs(KILLS) do max_ts = math.max(log.timestamp, max_ts) end
							if max_ts > (config.erlccache.old.automations.timestamps.kill or 0) then
								config.erlccache.old.automations.timestamps.kill = max_ts
								addNumeric("$.old.automations.timestamps.kill", max_ts)
							end
						elseif trigger == "modcalls" then
							local max_ts = config.erlccache.old.automations.timestamps.modcall or 0
							for _, log in pairs(MODCALLS) do max_ts = math.max(log.timestamp, max_ts) end
							if max_ts > (config.erlccache.old.automations.timestamps.modcall or 0) then
								config.erlccache.old.automations.timestamps.modcall = max_ts
								addNumeric("$.old.automations.timestamps.modcall", max_ts)
							end
						elseif trigger == "emergencycalls" then
							local max_ts = config.erlccache.old.automations.timestamps.emergencycall or 0
							for _, log in pairs(EMERGENCYCALLS) do max_ts = math.max(log.timestamp, max_ts) end
							if max_ts > (config.erlccache.old.automations.timestamps.emergencycall or 0) then
								config.erlccache.old.automations.timestamps.emergencycall = max_ts
								addNumeric("$.old.automations.timestamps.emergencycall", max_ts)
							end
						elseif trigger == "killedin" then
							for killerID, timestamps in pairs(cache) do
								local existing = config.erlccache.old.killedin[killerID] or {}
								local addedAny = false
								for _, ts in pairs(timestamps) do
									if not table.find(existing, ts) then
										table.insert(existing, ts)
										addedAny = true
									end
								end
								if addedAny then
									config.erlccache.old.killedin[killerID] = existing
									addJson("$.old.killedin." .. killerID, json.encode(existing))
								end
							end
						end
					end
				end

				if hasChanges then
					table.insert(params, guild.id)

					sqldb:_queryRun({
						query = "UPDATE guilds SET setting_value = json_set(COALESCE(setting_value, '{}'), "
							.. table.concat(placeholders, ", ")
							.. ") WHERE guild_id = ? AND setting_key = 'erlccache'",
						values = params
					})
				end
			end

			if config.erlcserverstatusmessage or (config.erlcserverstatuschannels and table.count(config.erlcserverstatuschannels) > 0) then
				local success, err = pcall(function()
					local owner = ropi.GetUser(server.owner)

					local queuecount = type(QUEUE) == "table" and table.count(QUEUE)

					local statusmsgKeys = {
						["server.name"] = server.name or emojis.fail,
						["server.players"] = PLAYERCOUNT or emojis.fail,
						["server.maxplayers"] = server.maxPlayercount or emojis.fail,
						["server.staff"] = table.count(STAFF) or emojis.fail,
						["server.queue"] = queuecount or emojis.fail,
						["server.code"] = server.joinCode or emojis.fail,
						["owner.name"] = (owner and owner.name) or emojis.fail,
						["owner.display"] = (owner and owner.displayName) or emojis.fail,
						["owner.id"] = (owner and owner.id) or emojis.fail,
						["owner.profile"] = (owner and owner.profile) or emojis.fail,
						["owner.hyperlink"] = (owner and owner.hyperlink) or emojis.fail,
						["team.dot"] = TEAMS["DOT"] or emojis.fail,
						["team.fire"] = TEAMS["Fire"] or emojis.fail,
						["team.police"] = TEAMS["Police"] or emojis.fail,
						["team.sheriff"] = TEAMS["Sheriff"] or emojis.fail,
						["team.jail"] = TEAMS["Jail"] or emojis.fail,
						["team.civilian"] = TEAMS["Civilian"] or emojis.fail,
						["timestamp"] = NOW
					}

					if config.erlcserverstatusmessage then
						local statuschannel = guild:getChannel(config.erlcserverstatusmessage.channel)

						if statuschannel then
							local statusmsg = statuschannel:getMessage(config.erlcserverstatusmessage.message)

							if statusmsg then
								local newToSend, variablesReplaced = parseTable(config.erlcserverstatusmessage.tosend, statusmsgKeys, nil, nil, {
									"timestamp"
								})

								if variablesReplaced > 0 then
									statusmsg:update(newToSend)
								end
							else
								sqldb:set(guild.id, {
									erlcserverstatusmessage = {
										tosend = config.erlcserverstatusmessage.tosend
									}
								}, "INVALID_STATUS_MESSAGE_MISSING_MESSAGE_" .. guild.id)
							end
						else
							sqldb:set(guild.id, {
								erlcserverstatusmessage = {
									tosend = config.erlcserverstatusmessage.tosend
								}
							}, "INVALID_STATUS_MESSAGE_MISSING_CHANNEL_" ..guild.id)
						end
					end

					if config.erlcserverstatuschannels and table.count(config.erlcserverstatuschannels) > 0 then
						local modified = false

						for i, v in pairs(config.erlcserverstatuschannels) do
							if not v.locked and (not erlcStatusChannelsDebounce[v.channel] or (realtime() - erlcStatusChannelsDebounce[v.channel] >= erlcStatusChannelsDebounceTime)) then
								local voiceChannel = guild:getChannel(v.channel)

								if voiceChannel then
									local newContent, variablesReplaced = parseTable({
										v.content
									}, statusmsgKeys, nil, nil, {
										"timestamp"
									})

									if variablesReplaced > 0 then
										newContent[1] = newContent[1]:gsub(emojis.fail, "❌")

										if newContent and newContent[1] and newContent[1]:len() >= 1 and voiceChannel.name ~= newContent[1] then
											coroutine.wrap(function()
												voiceChannel:setName(newContent[1]:usub(1, 100))
											end)()
										end
									end
								else
									table.remove(config.erlcserverstatuschannels, i)
									modified = true
								end
							end
						end

						if modified then
							sqldb:set(guild.id, {
								erlcserverstatuschannels = config.erlcserverstatuschannels
							}, "INVALID_STATUS_CHANNEL")
						end
					end
				end)

				if not success then
					log("An error occurred while updating ERLC server status messages/channels for " .. id .. ": " .. tostring(err), "red")
				end
			end

			------------------------------------------------------------------------------------------------------------------------------------------------

			if type(config.economy) == "table" and type(config.economy.bounties) == "table" and next(config.economy.bounties) then
				local success, err = pcall(function()
					for _, kill in ipairs(KILLS) do
						if kill.timestamp > (config.economy.lastbountycheck or 0) then
							local link = sqldb:getLink(tonumber(kill.killer.id))

							if link and link.discord then
								local member = guild:getMember(link.discord)

								if member then
									local killed = ropi.GetUser(kill.killed.id)

									local bounty = db:ecoBountyFetch(guild, killed)

									if bounty then
										db:ecoBountyComplete(member, killed)
									end
								end
							end
						end

						config.economy.lastbountycheck = os.time()
						sqldb:_queryRun({
							query = [[
								UPDATE guilds 
								SET setting_value = json_set(
									COALESCE(setting_value, '{}'),
									'$.economy.lastbountycheck',
									?
								)
								WHERE guild_id = ? AND setting_key = 'erlccache';
							]],
							values = {config.economy.lastbountycheck, guild.id}
						})
					end
				end)

				if not success then
					log("An error occurred while checking bounties of " .. id .. ": " .. tostring(err), "red")
				end
			end

			------------------------------------------------------------------------------------------------------------------------------------------------

			if config.erlctempbans then
				local success, err = pcall(function()
					for i, tempban in pairs(config.erlctempbans) do
						if tempban and tempban.expires <= NOW then
							local success, err = server:execute(":unban " .. tempban.userid)

							if success then
								config.erlctempbans[i] = nil
								save({
									erlctempbans = config.erlctempbans
								}, "ERLCUPDATE_erlctempbans")

								local player = ropi.GetUser(tempban.userid)
								local link = sqldb:getLink(player.id)
								local member = link and guild:getMember(link.discord)
								return member:reply({
									embed = {
										title = emojis.success .. " Tempban Expired",
										description = emojis.right .. " Your tempban in **" .. guild.name .. "** has expired:\n" .. emojis.space .. emojis.right .. " **Player:** " .. player.hyperlink .. "\n" .. emojis.space .. emojis.right .. " **Expired:** <t:" .. tempban.expires .. "> (<t:" .. tempban.expires .. ":R>)",
										components = signature(guild)
									}
								})
							end
						end
					end
				end)

				if not success then
					log("An error occurred while expiring tempbans for " .. id .. ": " .. tostring(err), "red")
				end
			end
		end

		------------------------------------------------------------------------------------------------------------------------------------------------

		local serverRaw = server:raw()
		local encodedServer = json.encode(serverRaw)

		config.erlccache.old.server = serverRaw
		sqldb:_queryRun({
			query = [[
				UPDATE guilds 
				SET setting_value = json_set(
					COALESCE(setting_value, '{}'), 
					'$.old.server', 
					json(?)
				) 
				WHERE guild_id = ? AND setting_key = 'erlccache';
			]],
			values = {encodedServer, guild.id}
		})

		return true
	end

	_G.runGuild = runGuild

	local erlcCycle = coroutine.create(function()
		log("Starting erlc cycle with ID " .. currentCycleId)
		local fullCycleCount = 0

		local ok, err = pcall(function()
			while currentCycleId == _G.erlcCycleId do
				fullCycleCount = fullCycleCount + 1
				debug("erlc cycle with ID " .. currentCycleId .. " starting new full guild cycle...")
				local startT = realtime()
				local guildokcount = 0

				local allGuildConfigs = sqldb:getAllGuildConfigs()
				if allGuildConfigs then
					local plusGuilds, regularGuilds = {}, {}
					for guildid, config in pairs(allGuildConfigs) do
						if config.apikey then
							if sqldb:plusGuild(guildid) then
								table.insert(plusGuilds, guildid)
							else
								table.insert(regularGuilds, guildid)
							end
						end
					end

					local orderedGuilds = {}
					for _, g in ipairs(plusGuilds) do
						table.insert(orderedGuilds, g)
					end
					for _, g in ipairs(regularGuilds) do
						table.insert(orderedGuilds, g)
					end

					for _, guildid in ipairs(orderedGuilds) do
						if currentCycleId ~= _G.erlcCycleId then
							return log("erlcCycle with ID " .. currentCycleId .. " stopping due to new cycle with ID " .. _G.erlcCycleId)
						end

						local guild = Client:getGuild(guildid)
						local config = allGuildConfigs[guildid]
						local erlcratelimits = (ERLC._api and ERLC._api._buckets["global"]) or { reset = realtime(), remaining = 0 } -- this will make it not wait for the first request
						erlcratelimits.remaining = math.max(erlcratelimits.remaining - 12, 0)

						if not guild or not config or not erlcratelimits then
							debug("Skipping " .. guildid .. " because of invalid guild, config or erlcratelimits. Guild: " .. tostring(not not guild) .. " Config: " .. tostring(not not config) .. " Erlcratelimits: " .. tostring(not not erlcratelimits))
							goto skip
						end

						local wasEmpty = true
						if config.erlccache and config.erlccache.old and config.erlccache.old.server and config.erlccache.old.server.players then
							if table.count(config.erlccache.old.server.players) > 0 then
								wasEmpty = false
							end
						else
							wasEmpty = false
						end

						if wasEmpty then
							local idNum = tonumber(guildid:usub(-4)) or 0
							if (fullCycleCount + idNum) % 2 == 0 then
								debug("Skipping empty server cycle for " .. guildid)
								goto skip
							end
						end

						local hasIntentions = false
						for intent, check in pairs(erlcIntentions) do
							local ok, result = pcall(check, config)

							if not ok then
								log("erlcintention " .. intent .. "  crashed: " .. tostring(result))
							else
								debug("Intention " .. intent .. " returned " .. tostring(result) .. " for " .. guildid)

								if result == true then
									hasIntentions = true
								end
							end
						end

						if not hasIntentions then
							debug("Skipping " .. guildid .. " for having no intents")
							goto skip
						end

						if erlcCycleRunningGuilds[guildid] then -- yes also here to prevent sleeping for no reason
							debug("Skipping " .. guildid .. " because it's already running")
						end

						local ratelimitdelay = math.round(math.max(0, erlcratelimits.reset - realtime()) / math.max(1, erlcratelimits.remaining), 2) * 1000
						debug("Sleeping " .. tostring(ratelimitdelay) .. "ms for " .. guildid)
						timer.sleep(ratelimitdelay)

						if erlcCycleRunningGuilds[guildid] then -- yes twice to prevent race condition with the sleeping
							debug("Skipping " .. guildid .. " because it's already running")
						end

						erlcCycleRunningGuilds[guildid] =  true
						coroutine.wrap(function()
							local noCrash, ok, response = pcall(runGuild, guildid)
							erlcCycleRunningGuilds[guildid] = nil

							if noCrash then
								if not ok then
									log("runGuild returned not ok for " .. guildid .. ": " .. tostring(response))
								else
									guildokcount = guildokcount + 1
									debug("runGuild returned ok for " .. guildid)
								end
							else
								log("runGuild crashed for " .. guildid .. ": " .. tostring(ok))
							end
						end)()

						::skip::
					end

					local endT = realtime()

					if endT - startT < erlcCycleMinDelay then
						local delay = (erlcCycleMinDelay - (endT - startT)) * 1000
						timer.sleep(delay)

						debug("erlc cycle with ID " .. currentCycleId .. " waiting " .. tostring(erlcCycleMinDelay) .. "ms to reach min delay")
					end

					log("erlc cycle with ID " .. currentCycleId .. " completed full guild cycle of " ..tostring(guildokcount) .. " guilds")
				end
			end
		end)

		if not ok then
			log("while loop of erlc cycle with ID " .. currentCycleId .. " crashed: " .. tostring(err))
		end
	end)

	coroutine.resume(erlcCycle)
	_G.erlcCycle = erlcCycle

	connections.Client.messageCreate = Client:on("messageCreate", function(message)
		if (not message) or (not message.guild) or (not message.guild.id) or (blacklisted(message.guild)) then
			return
		end

		local config = sqldb:get(message.guild.id) or {}

		local function save(changes, reason)
			local success, err = sqldb:set(id, changes, reason)
			if success then
				for key, value in pairs(changes) do
					if tostring(value) == "nil" then
						config[key] = nil
					else
						config[key] = value
					end
				end
				return true, config
			else
				return false, err
			end
		end

		if not message.guild or not message.webhookId or not message.embed or not message.embed.description or (not config.erlccmdschannel and not config.erlckickbanchannel and not (message.channel.id == config.erlccmdschannel or message.channel.id == config.erlckickbanchannel)) then
			return
		end

		local success, err = pcall(function()
			if message.embed.title == "Command Usage" then
				local full = message.embed.description:match("used the command: `(.+)`$")
				if not full then
					return
				end

				local args = string.split(full, " ")
				local command = args[1]:usub(2)
				local subcmd = args[2]
				table.remove(args, 1)

				local id = message.embed.description:match("/users/(%d+)/")
				id = id and tonumber(id)
				if id == 0 or not id then
					return
				end

				local player = ropi.GetUser(id)
				if not player then
					return
				end

				local link = sqldb:getLink(id)
				local member = link and message.guild:getMember(link.discord)

				for id, automation in pairs(config.automations or {}) do
					local splitTrigger = string.split(automation.trigger.value, ":")
					local trigger = splitTrigger[1]
					local value = (splitTrigger[2] and tonumber(splitTrigger[2])) or splitTrigger[2]
					local value2 = (splitTrigger[3] and tonumber(splitTrigger[3])) or splitTrigger[3]

					if trigger == "cmdused" and value == command then
						local keys = {
							["staff.name"] = player.name,
							["staff.id"] = tostring(player.id),
							["staff.profile"] = player.profile,
							["staff.hyperlink"] = player.hyperlink,
							["fullcmd"] = full,
							["timestamp"] = os.time()
						}

						coroutine.wrap(runAutomation)(automation, config, message.guild, nil, keys)
					end
				end

				if member then
					local active, pause = db:shiftActive(member)

					if active and not pause then
						db:shiftModify(message.guild, active.id, {
							commands = (active.commands or 0) + 1
						})
					end
				end

				local validCommands = {
					[":log ping"] = true,
					[":log punish"] = true,
					[":log bolo"] = true,
					[":log automations"] = true,
					[":log automation"] = true,
					[":log ams"] = true,
					[":log shift"] = true,
					[":log duty"] = true,
					[":log vehicle"] = true,
					[":log car"] = true,
					[":log plate"] = true,
					[":log reg"] = true,
					[":log registration"] = true,
					[":log message"] = true,
					[":log msg"] = true,
					[":log tempban"] = true,
					[":log untempban"] = true,
					[":log session"] = true,
				}

				if command == "unban" then
					local violator = args[1] ~= "" and args[1] and ropi.SearchUser(args[1])
					if violator then
						return Client:emit("erlcWebhookErlcbansync", "unban", member or message.guild.me, violator, config)
					end
				end

				if not validCommands[":" .. tostring(command) .. " " .. tostring(subcmd)] then
					return
				end

				local server = config.apikey and ERLC:getServer(config.apikey)
				local ingamePlayer = server and player and server:getPlayer(player.id)

				local function success(content, discordContent)
					message:removeReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.loading.hash) or "⌛")
					message:addReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.success.hash) or "✅")

					if server then
						server:execute("pm " .. player.name .. " ✅・" .. content)
					end

					if member and discordContent then
						member:send((type(discordContent) == "table" and discordContent) or {
							embed = {
								description = emojis.success .. " " .. (discordContent or content),
								color = colors.success
							},
							components = signature(message.guild)
						})
					end
				end

				local function fail(content, discordContent)
					message:removeReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.loading.hash) or "⌛")
					message:addReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.fail.hash) or "❌")

					if server then
						server:execute("pm " .. player.name .. " ❌・" .. content)
					end

					if member and discordContent then
						member:send((type(discordContent) == "table" and discordContent) or {
							embed = {
								description = emojis.fail .. " " .. (discordContent or content),
								color = colors.fail
							},
							components = signature(message.guild)
						})
					end
				end

				message:addReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.loading.hash) or "⌛")

				Client:emit("inGameCommand", player, full, command, message)

				if not member then
					return fail("You are not linked with Ducky.", "You must use the **`/link`** command to link your Roblox account with Ducky in order to use in-game commands.")
				end

				table.remove(args, 1)

				if subcmd == "ping" then
					return success("Pong!")
				elseif subcmd == "punish" then
					if (not config.punishmenttypes) or not next(config.punishmenttypes) then
						return fail("No punishment types have been configured for this server.")
					end

					local username = args[1] ~= "" and args[1]
					if not username then
						return fail("You did not provide a player.")
					end

					local violator = (server and table.find(server._players, function(p)
						return p.name:lower():find(username:lower())
					end)) or ropi.SearchUser(username)
					violator = (violator and violator.avatar and violator) or ropi.SearchUser(violator.name)
					if not violator then
						return fail("You did not provide a valid player.")
					end

					local typeQuery = args[2] ~= "" and args[2]
					if not typeQuery then
						return fail("You did not provide a punishment type.")
					end

					local type

					for _, t in pairs(config.punishmenttypes) do
						if t:lower() == typeQuery:lower() then
							type = t
							break
						end
					end

					if not type then
						return fail("You did not provide a valid punishment type.")
					end

					local reason = args[3] ~= "" and args[3] and table.concat(args, " ", 3)
					if not reason then
						return fail("You did not provide a reason.")
					end

					local punishment = db:punishmentCreate(message, member, violator, type, reason)
					if not punishment then
						return fail("An unexpected error occurred while creating the punishment.")
					end

					return success("That player has received a " .. type .. ".", {
						embed = {
							title = emojis.success .. " Punishment Logged",
							description = emojis.right .. " You have logged a punishment on **" .. violator.hyperlink .. "**.\n" .. emojis.space .. emojis.right .. " **Moderator:** <@" .. punishment.moderator .. ">\n" .. emojis.space .. emojis.right .. " **Player:** " .. violator.hyperlink .. "\n" .. emojis.space .. emojis.right .. " **Type:** " .. punishment.type .. "\n" .. emojis.space .. emojis.right .. " **Reason:** " .. punishment.reason .. ((punishment.evidence and "\n" .. emojis.space .. emojis.right .. " **Evidence:** [Attachment](" .. punishment.evidence .. ")") or "") .. ((punishment.expires and "\n" .. emojis.space .. emojis.right .. " **Expires:** <t:" .. punishment.expires .. "> (<t:" .. punishment.expires .. ":R>)") or "") .. "\n" .. emojis.space .. emojis.right .. " **ID:** `" .. punishment.id .. "`",
							color = colors.success,
							thumbnail = violator.avatar and {
								url = violator.avatar
							},
							author = author(member),
							image = (punishment.evidence and {
								url = punishment.evidence
							}) or nil
						},
						components = signature(message.guild)
					})
				elseif subcmd == "bolo" then
					local username = args[1] ~= "" and args[1]
					if not username then
						return fail("You did not provide a player.")
					end

					local violator = (server and table.find(server._players, function(p)
						return p.name:lower():find(username:lower())
					end)) or ropi.SearchUser(username)
					violator = (violator and violator.avatar and violator) or ropi.SearchUser(violator.name)
					if not violator then
						return fail("You did not provide a valid player.")
					end

					local reason = args[2] ~= "" and args[2] and table.concat(args, " ", 2)
					if not reason then
						return fail("You did not provide a reason.")
					end

					local bolo, err = db:createBOLO(violator, reason, member, nil, nil, message)
					if not bolo then
						return fail(tostring(err))
					end

					return success("That player has received a BOLO.", "**" .. violator.hyperlink .. "** has received a BOLO.")
				elseif subcmd == "automations" or subcmd == "automation" or subcmd == "ams" then
					if args[1] == "run" or args[1] == "execute" or args[1] == "exec" then
						local query = args[2] ~= "" and args[2]
						if not query then
							return fail("You did not provide an automation.")
						end

						local automation = table.find(config.automations or {}, function(am)
							return am.id == tonumber(query) or am.name:lower() == query:lower()
						end)
						if not automation then
							return fail("You did not provide a valid automation.")
						elseif automation.trigger.value ~= "manual" and automation.trigger.value ~= "interval" then
							return fail("That automation's trigger is not manual or interval.", "That automation's trigger is not " .. emojis.support .. " **Manual** or " .. emojis.clock .. " **Interval**.")
						elseif automation.disabled then
							return fail("That automation is disabled.")
						elseif not hasPermission(member, "MANAGE_SERVER") and (automation.customization and automation.customization.requiredRole and not member:hasRole(automation.customization.requiredRole)) then
							return fail("You do not have permissions to use this automation.")
						end

						local keys = {}

						if automation.customization and automation.customization.customArgs then
							for i = 1, 5 do
								local argument = automation.customization.customArgs["arg" .. i]
								if not argument then
									break
								end

								local name = argument.name
								if name then
									if not args[i] and argument.required then
										return fail("The " .. ordinal(i) .. " argument, {" .. name .. "}, is required.")
									end

									keys[name] = args[i]
								end
							end
						end

						success("The '" .. automation.name .. "' automation is being executed...", "The " .. emojis.automation .. " **" .. automation.name .. "** automation is being executed...")

						local resultsTable, resultsEmbeds = runAutomation(automation, config, member.guild, nil, keys, nil, nil, member)
						if (not resultsTable) or (not next(resultsTable)) then
							return fail("An unexpected error occurred while executing that automation.")
						end

						return success("The '" .. automation.name .. "' automation has been executed.", {
							embeds = resultsEmbeds,
							components = signature(message.guild)
						})
					end
				elseif subcmd == "shift" or subcmd == "duty" then
					local action = args[1] ~= "" and args[1]:lower()
					local type, err = db:shiftType(message.guild, args[2], member)

					if not action then
						return fail("You did not provide an action.")
					elseif not type then
						return fail(err)
					end

					if action == "start" then
						local succ, response, gameResponse = db:shiftStart(message, member, type.name, true)
						if not succ then
							return fail(gameResponse or response, response)
						end

						return success(gameResponse or response, response)
					elseif action == "pause" then
						local succ, response, gameResponse = db:shiftPause(member)
						if not succ then
							return fail(gameResponse or response, response)
						end

						return success(gameResponse or response, response)
					elseif action == "end" then
						local succ, response, gameResponse = db:shiftEnd(member)
						if not succ then
							return fail(gameResponse or response, response)
						end

						return success(gameResponse or response, response)
					elseif action == "time" then
						local active = db:shiftActive(member)
						if not active then
							return fail("You do not have an active shift.")
						end

						local elapsed = db:shiftElapsed(message.guild, active.id)
						return success("Your shift has been active for " .. readable(elapsed) .. ".", "Your shift has been active for **" .. readable(elapsed) .. "**.")
					end
				elseif subcmd == "vehicle" or subcmd == "car" or subcmd == "plate" or subcmd == "reg" or subcmd == "registration" then
					if not server then
						return fail("This feature requires the ERLC server to be linked.")
					elseif not hasPermission(member, "ERLC_STAFF") then
						return fail("You do not have permissions to use this command.")
					end

					local query = args[1] ~= "" and args[1] and table.concat(args):lower()
					if not query then
						return fail("You did not provide a query.")
					end

					local possibilities = {}
					for _, v in pairs(server.vehicles) do
						local distance = ingamePlayer and ingamePlayer.location and v.owner and v.owner.location and v.owner.location:distance(ingamePlayer.location) or math.huge
						local isPlate = not not query:match("%-")
						local vehiclePlate = v.plate:lower():gsub("%W", "")
						query = query:gsub("%W", "")

						if vehiclePlate == query or vehiclePlate:find(query) or string.levenshtein(vehiclePlate, query) <= 3 then
							table.insert(possibilities, {
								vehicle = v,
								rank = string.levenshtein(vehiclePlate, query) - (isPlate and 5 or 0), -- bias: if hyphen is used, then the player is likely searching by plate
								type = "plate",
								distance = distance
							})
						end

						local vehicleName = v.name:lower():gsub("%W", "")

						if vehicleName == query or vehicleName:find(query) or string.levenshtein(vehicleName, query) <= 3 then
							table.insert(possibilities, {
								vehicle = v,
								rank = string.levenshtein(vehicleName, query) - 3, -- bias: more likely to know vehicle name than color name (although in the future perhaps a group map i.e. "yellow" also works for cashmere)
								type = "name",
								distance = distance
							})
						end

						local vehicleColor = v.color:lower():gsub("%W", "")

						if vehicleColor == query or vehicleColor:find(query) or string.levenshtein(vehicleColor, query) <= 3 then
							table.insert(possibilities, {
								vehicle = v,
								rank = string.levenshtein(vehicleName, query),
								type = "color",
								distance = distance
							})
						end
					end

					table.sort(possibilities, function(a, b)
						return a.rank < b.rank
					end)

					local seen = {names = {}, ranks = {}}
					for i = #possibilities, 1, -1 do
						local p = possibilities[i]
						if seen.names[tostring(p.vehicle)] then
							table.remove(possibilities, i)
							seen[tostring(p.vehicle)] = true
						elseif seen.ranks[tostring(p.rank)] and seen.ranks[tostring(p.rank)] ~= p.type then
							table.remove(possibilities, i)
							seen[tostring(p.rank)] = p.type
						end
					end

					table.sort(possibilities, function(a, b)
						return a.distance < b.distance
					end)

					local vehicle = possibilities[1] and possibilities[1].vehicle
					if not vehicle then
						return fail("No vehicle was found matching that query.")
					end

					return success("That vehicle is owned by " .. (vehicle.owner and vehicle.owner.name or "Unknown") .. ".")
				elseif subcmd == "message" or subcmd == "msg" then
					if not server then
						return fail("This feature requires the ERLC server to be linked.")
					elseif not hasPermission(member, "ERLC_ADMIN") then
						return fail("You do not have permissions to use this command.")
					end

					local type = args[1] ~= "" and args[1] and args[1]:lower()
					if not type then
						return fail("You did not provide a message type.")
					end

					local content = args[2] ~= "" and args[2] and table.concat(args, " ", 2)
					if not content then
						return fail("You did not provide content for this message.")
					end

					loadMembers(message.guild)

					if type == "staff" then
						local targets = {}
						for _, p in pairs(server.players) do
							if p then
								if p.permission ~= erlua.enums.permission.normal then
									table.insert(targets, p.name)
								end
							end
						end

						if #targets == 0 then
							return fail("There are no staff to message.")
						end

						local succ, err
						if #targets > 0 then
							succ, err = server:execute(":pm " .. table.concat(targets, ",") .. " " .. content)
						end
						if not succ then
							return fail("An unexpected error occurred while messaging those players.", "An unexpected error occurred while message those players: " .. tostring(err))
						end

						db:send(message.guild, "erlccmdschannel", {
							embed = {
								title = emojis.chat .. " Players Messaged",
								description = emojis.right .. " " .. getUserString(member) .. " privately messaged all in-game staff members:\n```\n" .. content .. "```",
								color = colors.info,
								author = author(member),
								thumbnail = thumbnail(member),
								footer = {
									text = player.name,
									icon_url = player.avatar
								}
							}
						})

						return success("Those players have been messaged successfully.")
					elseif type == "notindiscord" or type == "nid" then
						local targets = {}
						for _, p in pairs(server.players) do
							if p then
								inDiscord(p, message.guild)
								if not inDiscord(p, message.guild) then
									table.insert(targets, p.name)
								end
							end
						end

						if #targets == 0 then
							return fail("There are no players to message.")
						end

						local succ, err
						if #targets > 0 then
							succ, err = server:execute(":pm " .. table.concat(targets, ",") .. " " .. content)
						end
						if not succ then
							return fail("An unexpected error occurred while messaging those players.", "An unexpected error occurred while message those players: " .. tostring(err))
						end

						db:send(message.guild, "erlccmdschannel", {
							embed = {
								title = emojis.chat .. " Players Messaged",
								description = emojis.right .. " " .. getUserString(member) .. " privately messaged all in-game players that are not in the Discord server:\n```\n" .. content .. "```",
								color = colors.info,
								author = author(member),
								thumbnail = thumbnail(member),
								footer = {
									text = player.name,
									icon_url = player.avatar
								}
							}
						})

						return success("Those players have been messaged successfully.")
					elseif type == "onshift" or type == "onshiftstaff" or type == "onduty" or type == "ondutystaff" or type == "activeshift" then
						local targets = {}
						for _, p in pairs(server.players) do
							if p then
								local member = inDiscord(p, message.guild)
								if member and p.permission ~= erlua.enums.permission.normal then
									local active, pause = db:shiftActive(member)
									if active and not pause then
										table.insert(targets, p.name)
									end
								end
							end
						end

						if #targets == 0 then
							return fail("There are no staff on duty to message.")
						end

						local succ, err
						if #targets > 0 then
							succ, err = server:execute(":pm " .. table.concat(targets, ",") .. " " .. content)
						end
						if not succ then
							return fail("An unexpected error occurred while messaging those players.", "An unexpected error occurred while message those players: " .. tostring(err))
						end

						db:send(message.guild, "erlccmdschannel", {
							embed = {
								title = emojis.chat .. " Players Messaged",
								description = emojis.right .. " " .. getUserString(member) .. " privately messaged all in-game staff members that are on shift:\n```\n" .. content .. "```",
								color = colors.info,
								author = author(member),
								thumbnail = thumbnail(member),
								footer = {
									text = player.name,
									icon_url = player.avatar
								}
							}
						})

						return success("Those players have been messaged successfully.")
					elseif type == "onpause" or type == "onbreak" or type == "onpausestaff" or type == "onbreakstaff" or type == "inactivestaff" then
						local targets = {}
						for _, p in pairs(server.players) do
							if p then
								local member = inDiscord(p, message.guild)
								if member and p.permission ~= erlua.enums.permission.normal then
									local active, pause = db:shiftActive(member)
									if active and pause then
										table.insert(targets, p.name)
									end
								end
							end
						end

						if #targets == 0 then
							return fail("There are no staff on break to message.")
						end

						local succ, err
						if #targets > 0 then
							succ, err = server:execute(":pm " .. table.concat(targets, ",") .. " " .. content)
						end
						if not succ then
							return fail("An unexpected error occurred while messaging those players.", "An unexpected error occurred while message those players: " .. tostring(err))
						end

						db:send(message.guild, "erlccmdschannel", {
							embed = {
								title = emojis.chat .. " Players Messaged",
								description = emojis.right .. " " .. getUserString(member) .. " privately messaged all in-game staff members that are on pause:\n```\n" .. content .. "```",
								color = colors.info,
								author = author(member),
								thumbnail = thumbnail(member),
								footer = {
									text = player.name,
									icon_url = player.avatar
								}
							}
						})

						return success("Those players have been messaged successfully.")
					elseif type == "offshift" or type == "offduty" or type == "offshiftstaff" or type == "offdutystaff" then
						local targets = {}
						for _, p in pairs(server.players) do
							if p then
								local member = inDiscord(p, message.guild)
								if member and p.permission ~= erlua.enums.permission.normal then
									local active, pause = db:shiftActive(member)
									if not active then
										table.insert(targets, p.name)
									end
								end
							end
						end

						if #targets == 0 then
							return fail("There are no staff off duty to message.")
						end

						local succ, err
						if #targets > 0 then
							succ, err = server:execute(":pm " .. table.concat(targets, ",") .. " " .. content)
						end
						if not succ then
							return fail("An unexpected error occurred while messaging those players.", "An unexpected error occurred while message those players: " .. tostring(err))
						end

						db:send(message.guild, "erlccmdschannel", {
							embed = {
								title = emojis.chat .. " Players Messaged",
								description = emojis.right .. " " .. getUserString(member) .. " privately messaged all in-game staff members that are not on shift:\n```\n" .. content .. "```",
								color = colors.info,
								author = author(member),
								thumbnail = thumbnail(member),
								footer = {
									text = player.name,
									icon_url = player.avatar
								}
							}
						})

						return success("Those players have been messaged successfully.")
					elseif type == "police" or type == "pd" then
						local targets = {}
						for _, p in pairs(server.players) do
							if p and p.team == "Police" then
								table.insert(targets, p.name)
							end
						end

						if #targets == 0 then
							return fail("There are no police to message.")
						end

						local succ, err
						if #targets > 0 then
							succ, err = server:execute(":pm " .. table.concat(targets, ",") .. " " .. content)
						end
						if not succ then
							return fail("An unexpected error occurred while messaging those players.", "An unexpected error occurred while message those players: " .. tostring(err))
						end

						db:send(message.guild, "erlccmdschannel", {
							embed = {
								title = emojis.chat .. " Players Messaged",
								description = emojis.right .. " " .. getUserString(member) .. " privately messaged all in-game players on the Police team:\n```\n" .. content .. "```",
								color = colors.info,
								author = author(member),
								thumbnail = thumbnail(member),
								footer = {
									text = player.name,
									icon_url = player.avatar
								}
							}
						})

						return success("Those players have been messaged successfully.")
					elseif type == "sheriff" or type == "sheriffs" then
						local targets = {}
						for _, p in pairs(server.players) do
							if p and p.team == "Sheriff" then
								table.insert(targets, p.name)
							end
						end

						if #targets == 0 then
							return fail("There are no sheriffs to message.")
						end

						local succ, err
						if #targets > 0 then
							succ, err = server:execute(":pm " .. table.concat(targets, ",") .. " " .. content)
						end
						if not succ then
							return fail("An unexpected error occurred while messaging those players.", "An unexpected error occurred while message those players: " .. tostring(err))
						end

						db:send(message.guild, "erlccmdschannel", {
							embed = {
								title = emojis.chat .. " Players Messaged",
								description = emojis.right .. " " .. getUserString(member) .. " privately messaged all in-game players on the Sheriff team:\n```\n" .. content .. "```",
								color = colors.info,
								author = author(member),
								thumbnail = thumbnail(member),
								footer = {
									text = player.name,
									icon_url = player.avatar
								}
							}
						})

						return success("Those players have been messaged successfully.")
					elseif type == "fire" or type == "fd" or type == "firefighter" or type == "firefighters" or type == "ems" or type == "medics" then
						local targets = {}
						for _, p in pairs(server.players) do
							if p and p.team == "Fire" then
								table.insert(targets, p.name)
							end
						end

						if #targets == 0 then
							return fail("There are no firefighters to message.")
						end

						local succ, err
						if #targets > 0 then
							succ, err = server:execute(":pm " .. table.concat(targets, ",") .. " " .. content)
						end
						if not succ then
							return fail("An unexpected error occurred while messaging those players.", "An unexpected error occurred while message those players: " .. tostring(err))
						end

						db:send(message.guild, "erlccmdschannel", {
							embed = {
								title = emojis.chat .. " Players Messaged",
								description = emojis.right .. " " .. getUserString(member) .. " privately messaged all in-game players on the Fire team:\n```\n" .. content .. "```",
								color = colors.info,
								author = author(member),
								thumbnail = thumbnail(member),
								footer = {
									text = player.name,
									icon_url = player.avatar
								}
							}
						})

						return success("Those players have been messaged successfully.")
					elseif type == "dot" then
						local targets = {}
						for _, p in pairs(server.players) do
							if p and p.team == "DOT" then
								table.insert(targets, p.name)
							end
						end

						if #targets == 0 then
							return fail("There are no DOT to message.")
						end

						local succ, err
						if #targets > 0 then
							succ, err = server:execute(":pm " .. table.concat(targets, ",") .. " " .. content)
						end
						if not succ then
							return fail("An unexpected error occurred while messaging those players.", "An unexpected error occurred while message those players: " .. tostring(err))
						end

						db:send(message.guild, "erlccmdschannel", {
							embed = {
								title = emojis.chat .. " Players Messaged",
								description = emojis.right .. " " .. getUserString(member) .. " privately messaged all in-game players on the DOT team:\n```\n" .. content .. "```",
								color = colors.info,
								author = author(member),
								thumbnail = thumbnail(member),
								footer = {
									text = player.name,
									icon_url = player.avatar
								}
							}
						})

						return success("Those players have been messaged successfully.")
					elseif type == "civilian" or type == "civilians" or type == "civ" then
						local targets = {}
						for _, p in pairs(server.players) do
							if p and p.team == "Civilian" then
								table.insert(targets, p.name)
							end
						end

						if #targets == 0 then
							return fail("There are no civilians to message.")
						end

						local succ, err
						if #targets > 0 then
							succ, err = server:execute(":pm " .. table.concat(targets, ",") .. " " .. content)
						end
						if not succ then
							return fail("An unexpected error occurred while messaging those players.", "An unexpected error occurred while message those players: " .. tostring(err))
						end

						db:send(message.guild, "erlccmdschannel", {
							embed = {
								title = emojis.chat .. " Players Messaged",
								description = emojis.right .. " " .. getUserString(member) .. " privately messaged all in-game players on the Civlian team:\n```\n" .. content .. "```",
								color = colors.info,
								author = author(member),
								thumbnail = thumbnail(member),
								footer = {
									text = player.name,
									icon_url = player.avatar
								}
							}
						})

						return success("Those players have been messaged successfully.")
					elseif type == "jail" or type == "jailed" or type == "prisoners" then
						local targets = {}
						for _, p in pairs(server.players) do
							if p and p.team == "Jail" then
								table.insert(targets, p.name)
							end
						end

						if #targets == 0 then
							return fail("There are players jailed to message.")
						end

						local succ, err
						if #targets > 0 then
							succ, err = server:execute(":pm " .. table.concat(targets, ",") .. " " .. content)
						end
						if not succ then
							return fail("An unexpected error occurred while messaging those players.", "An unexpected error occurred while message those players: " .. tostring(err))
						end

						db:send(message.guild, "erlccmdschannel", {
							embed = {
								title = emojis.chat .. " Players Messaged",
								description = emojis.right .. " " .. getUserString(member) .. " privately messaged all in-game players on the Jail team:\n```\n" .. content .. "```",
								color = colors.info,
								author = author(member),
								thumbnail = thumbnail(member),
								footer = {
									text = player.name,
									icon_url = player.avatar
								}
							}
						})

						return success("Those players have been messaged successfully.")
					elseif type == "wanted" then
						local targets = {}
						for _, p in pairs(server.players) do
							if p and p.wantedStars > 0 then
								table.insert(targets, p.name)
							end
						end

						if #targets == 0 then
							return fail("There are no wanted players to message.")
						end

						local succ, err
						if #targets > 0 then
							succ, err = server:execute(":pm " .. table.concat(targets, ",") .. " " .. content)
						end
						if not succ then
							return fail("An unexpected error occurred while messaging those players.", "An unexpected error occurred while message those players: " .. tostring(err))
						end

						db:send(message.guild, "erlccmdschannel", {
							embed = {
								title = emojis.chat .. " Players Messaged",
								description = emojis.right .. " " .. getUserString(member) .. " privately messaged all in-game players that are wanted:\n```\n" .. content .. "```",
								color = colors.info,
								author = author(member),
								thumbnail = thumbnail(member),
								footer = {
									text = player.name,
									icon_url = player.avatar
								}
							}
						})

						return success("Those players have been messaged successfully.")
					end
				elseif subcmd == "tempban" then
					if (not config.tempbantimemods) and (not hasPermission(member, "ERLC_ADMIN")) then
						return fail("You do not have permission to use this command.")
					end

					local username = args[1] ~= "" and args[1]
					if not username then
						return fail("You did not provide a player.")
					end

					local violator = (server and table.find(server._players, function(p)
						return p.name:lower():find(username:lower())
					end)) or ropi.SearchUser(username)
					violator = (violator and violator.avatar and violator) or ropi.SearchUser(violator.name)
					if not violator then
						return fail("You did not provide a valid player.")
					end

					local duration = args[2] ~= "" and args[2] and convert(args[2], true)
					if not duration then
						return fail("You did not provide a valid duration.")
					elseif config.tempbantimemods and (duration > config.tempbantimemods) then
						return fail("You can tempban players for no longer than " .. readable(config.tempbantimemods) .. ".", "You can tempban players for no longer than **" .. readable(config.tempbantimemods) .. "**.")
					end

					local expires = duration and (os.time() + duration)

					local reason = args[3] ~= "" and args[3] and table.concat(args, " ", 3)
					if not reason then
						return fail("You did not provide a reason.")
					end

					config.erlctempbans = config.erlctempbans or {}

					local existing = config.erlctempbans[tostring(violator.id)]
					if existing then
						return fail("That player is already temporarily banned from the in-game server.", "That player is already temporarily banned from the in-game server until <t:" .. existing.expires .. "> (<t:" .. existing.expires .. ":R>).")
					end

					local succ, err = server:execute(":ban " .. violator.id)
					if not succ then
						return fail(err)
					end

					local punishment = db:punishmentCreate(message, member, violator, "Tempban", reason, nil, expires)
					if not punishment then
						config.erlctempbans[tostring(violator.id)] = {
							expires = expires,
							userid = violator.id
						}

						sqldb:set(message.guild.id, {
							erlctempbans = config.erlctempbans
						}, "ERLC_TEMPBAN_ADD")

						return fail("The punishment could not be logged, however the tempban was still successful.")
					end

					config.erlctempbans[tostring(violator.id)] = {
						expires = expires,
						userid = tostring(violator.id),
						punishmentid = punishment.id
					}

					sqldb:set(message.guild.id, {
						erlctempbans = config.erlctempbans
					}, "ERLC_TEMPBAN_ADD")

					return success("That player has been tempbanned for " .. readable(duration) .. ".", {
						embed = {
							author = author(member),
							title = emojis.success .. " Tempban Logged",
							description = emojis.right .. " You have logged a tempban on **" .. violator.hyperlink .. "**.\n" .. emojis.space .. emojis.right .. " **Moderator:** " .. member.mentionString .. "\n" .. emojis.space .. emojis.right .. " **Player:** " .. violator.hyperlink .. "\n" .. emojis.space .. emojis.right .. " **Reason:** " .. reason .. "\n" .. emojis.space .. emojis.right .. " **Expires:** <t:" .. expires .. "> (<t:" .. expires .. ":R>)",
							color = colors.success
						},
						components = signature(message.guild)
					})
				elseif subcmd == "untempban" then
					if not hasPermission(member, "ERLC_ADMIN") then
						return fail("You do not have permission to use this command.")
					end

					local username = args[1] ~= "" and args[1]
					if not username then
						return fail("You did not provide a player.")
					end

					local violator = (server and table.find(server._players, function(p)
						return p.name:lower():find(username:lower())
					end)) or ropi.SearchUser(username)
					if not violator then
						return fail("You did not provide a valid player.")
					end

					local reason = args[3] ~= "" and args[3] and table.concat(args, " ", 3)
					if not reason then
						return fail("You did not provide a reason.")
					end

					config.erlctempbans = config.erlctempbans or {}

					local existing = config.erlctempbans[tostring(violator.id)]
					if not existing then
						return fail("That player is not temporarily banned from the in-game server.")
					end

					local succ, err = server:execute(":unban " .. violator.id)
					if not succ then
						return fail(err)
					end

					config.erlctempbans[tostring(violator.id)] = nil

					sqldb:set(message.guild.id, {
						erlctempbans = config.erlctempbans
					}, "ERLC_TEMPBAN_REMOVE")

					local link = sqldb:getLink(violator.id)
					local member = link and message.guild:getMember(link.discord)
					if member then
						member:success("Your tempban in **" .. message.guild.name .. "** has been removed and you have been unbanned for **" .. reason .. "**.")
					end

					return success(violator.hyperlink .. "'s tempban has been removed, and they have been unbanned from the in-game server.", "**" .. violator.hyperlink .. "**'s tempban has been removed, and they have been unbanned from the in-game server.")
				end

				message:removeReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.loading.hash) or "⌛")
			elseif message.embed.title == "Players Kicked" then
				local full = message.embed.description:match("kicked `(.+)`$")
				if (not full) or (not config.apikey) then
					return
				end

				full = full and full:gsub(" %- Player Not In Game$", "")
				local names, reason = full:match("^(.+,%s*[^%s]+)%s*(.*)")
				if not names then
					names, reason = full:match("^([^%s]+)%s*(.*)")
				end

				local id = message.embed.description:match("/users/(%d+)/")
				id = id and tonumber(id)
				if id == 0 or not id then
					return
				end

				local player = ropi.GetUser(id)
				if not player then
					return
				end

				local server = ERLC:getServer(config.apikey)
				if not server then
					return
				end

				local affected = {}
				for _, name in pairs(string.split(names, ", ")) do
					local plr = table.find(server._players, function(p)
						return p.name:lower() == name:lower()
					end) or ropi.SearchUser(name)

					if plr then
						table.insert(affected, plr)
					end
				end

				for _, automation in pairs(config.automations or {}) do
					local splitTrigger = string.split(automation.trigger.value, ":")
					local trigger = splitTrigger[1]

					if trigger == "kickall" and #affected >= #server.players * 0.33 then
						local keys = {
							["staff.id"] = player.id,
							["staff.name"] = player.name,
							["staff.profile"] = player.profile,
							["staff.hyperlink"] = player.hyperlink,
							["kickedUsers.names"] = table.concatFn(affected, ",", function(a)
								return a.name
							end),
							["kickedUsers.ids"] = table.concatFn(affected, ",", function(a)
								return a.id
							end),
							["timestamp"] = math.floor(message.createdAt)
						}

						coroutine.wrap(runAutomation)(automation, config, message.guild, server._players, keys)
					end
				end
			elseif message.embed.title == "Players Banned" then
				local full = message.embed.description:match("banned `(.+)`$")
				if (not full) or (not config.apikey) then
					return
				end

				full = full and full:gsub(" %- Player Not In Game", "")
				local names, reason = full:match("^(.+,%s*[^%s]+)%s*(.*)")
				if not names then
					names, reason = full:match("^([^%s]+)%s*(.*)")
				end

				local id = message.embed.description:match("/users/(%d+)/")
				id = id and tonumber(id)
				if id == 0 or not id then
					return
				end

				local player = ropi.GetUser(id)
				if not player then
					return
				end

				local server = ERLC:getServer(config.apikey)
				if not server then
					return
				end

				local affected = {}
				for _, name in pairs(string.split(names, ", ")) do
					local plr = table.find(server._players, function(p)
						return p.name:lower() == name:lower()
					end) or ropi.SearchUser(name)

					if plr then
						table.insert(affected, plr)
					end
				end

				for _, automation in pairs(config.automations or {}) do
					local splitTrigger = string.split(automation.trigger.value, ":")
					local trigger = splitTrigger[1]

					if trigger == "banall" and #affected >= #server.players * 0.33 then
						local keys = {
							["staff.id"] = player.id,
							["staff.name"] = player.name,
							["staff.profile"] = player.profile,
							["staff.hyperlink"] = player.hyperlink,
							["bannedUsers.names"] = table.concatFn(affected, ",", function(a)
								return a.name
							end),
							["bannedUsers.ids"] = table.concatFn(affected, ",", function(a)
								return a.id
							end),
							["timestamp"] = math.floor(message.createdAt)
						}

						coroutine.wrap(runAutomation)(automation, config, message.guild, server._players, keys)
					end
				end
			elseif message.embed.title == "Player Kicked" and config.erlcautologkickbolo then
				local full = message.embed.description:match("kicked `(.+)`$")
				if (not full) or (not config.apikey) then
					return
				end

				full = full and full:gsub(" %- Player Not In Game", "")
				local names, reason = full:match("^(.+,%s*[^%s]+)%s*(.*)")
				if not names then
					names, reason = full:match("^([^%s]+)%s*(.*)")
				end

				local id = message.embed.description:match("/users/(%d+)/")
				id = id and tonumber(id)
				if id == 0 or not id then
					return
				end

				local player = ropi.GetUser(id)
				if not player then
					return
				end

				local link = sqldb:getLink(id)
				local member = link and message.guild:getMember(link.discord)
				if not member then
					return
				end

				local server = ERLC:getServer(config.apikey)
				if not server then
					return
				end

				local violator = ropi.SearchUser(names)
				if not violator then
					return
				end

				reason = reason or "No reason provided."

				if table.find(server._players, function(p)
					return p.name:lower() == violator.name:lower() and p.permission ~= erlua.enums.permission.normal
				end) then
					return
				end

				local function success(content, discordContent)
					message:removeReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.loading.hash) or "⌛")
					message:addReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.success.hash) or "✅")

					if server then
						server:execute(":pm " .. player.name .. " ✅・" .. content)
					end

					if member and discordContent then
						member:send((type(discordContent) == "table" and discordContent) or {
							embed = {
								description = emojis.success .. " " .. (discordContent or content),
								color = colors.success
							},
							components = signature(message.guild)
						})
					end
				end

				local function fail(content, discordContent)
					message:removeReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.loading.hash) or "⌛")
					message:addReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.fail.hash) or "❌")

					if server then
						server:execute(":pm " .. player.name .. " ❌・" .. content)
					end

					if member and discordContent then
						member:send((type(discordContent) == "table" and discordContent) or {
							embed = {
								description = emojis.fail .. " " .. (discordContent or content),
								color = colors.fail
							},
							components = signature(message.guild)
						})
					end
				end

				message:addReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.loading.hash) or "⌛")

				if reason:match("%?bolo") then
					reason = reason:gsub("%?bolo", "")
					local bolo, err = db:createBOLO(violator, reason, member, nil, nil, message)
					if not bolo then
						return fail(tostring(err))
					end

					return success("That player has received a BOLO.", "**" .. violator.hyperlink .. "** has received a BOLO.")
				end

				local punishment = db:punishmentCreate(message, member, violator, "Kick", reason)
				if not punishment then
					return fail("An unexpected error occurred while creating the punishment.")
				end

				return success("That player has received a Kick.", {
					embed = {
						title = emojis.success .. " Punishment Logged",
						description = emojis.right .. " You have logged a punishment on **" .. violator.hyperlink .. "**.\n" .. emojis.space .. emojis.right .. " **Moderator:** <@" .. punishment.moderator .. ">\n" .. emojis.space .. emojis.right .. " **Player:** " .. violator.hyperlink .. "\n" .. emojis.space .. emojis.right .. " **Type:** " .. punishment.type .. "\n" .. emojis.space .. emojis.right .. " **Reason:** " .. punishment.reason .. ((punishment.evidence and "\n" .. emojis.space .. emojis.right .. " **Evidence:** [Attachment](" .. punishment.evidence .. ")") or "") .. ((punishment.expires and "\n" .. emojis.space .. emojis.right .. " **Expires:** <t:" .. punishment.expires .. "> (<t:" .. punishment.expires .. ":R>)") or "") .. "\n" .. emojis.space .. emojis.right .. " **ID:** `" .. punishment.id .. "`",
						color = colors.success,
						thumbnail = violator.avatar and {
							url = violator.avatar
						},
						author = author(member),
						image = (punishment.evidence and {
							url = punishment.evidence
						}) or nil
					},
					components = signature(message.guild)
				})
			elseif message.embed.title == "Player Banned" and config.erlcautologkickbolo then
				local full = message.embed.description:match("banned `(.+)`$")
				if (not full) or (not config.apikey) then
					return
				end

				full = full and full:gsub(" %- Player Not In Game", "")
				local names, reason = full:match("^(.+,%s*[^%s]+)%s*(.*)")
				if not names then
					names, reason = full:match("^([^%s]+)%s*(.*)")
				end

				local id = message.embed.description:match("/users/(%d+)/")
				id = id and tonumber(id)

				local player = ropi.GetUser(id)

				local link = sqldb:getLink(id)
				local member = link and message.guild:getMember(link.discord)

				local server = ERLC:getServer(config.apikey)
				if not server then
					return
				end

				local violator = ropi.SearchUser(names)
				if not violator then
					return
				end

				reason = reason or "No reason provided."

				if table.find(server._players, function(p)
					return p.name:lower() == violator.name:lower() and p.permission ~= erlua.enums.permission.normal
				end) then
					return
				end

				Client:emit("erlcWebhookErlcbansync", "ban", member or message.guild.me, violator, config)
				if (id == 0 or not id) or (not player) or (not member) then
					return
				end

				local function success(content, discordContent)
					message:removeReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.loading.hash) or "⌛")
					message:addReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.success.hash) or "✅")

					if server then
						server:execute(":pm " .. player.name .. " ✅・" .. content)
					end

					if member and discordContent then
						member:send((type(discordContent) == "table" and discordContent) or {
							embed = {
								description = emojis.success .. " " .. (discordContent or content),
								color = colors.success
							},
							components = signature(message.guild)
						})
					end
				end

				local function fail(content, discordContent)
					message:removeReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.loading.hash) or "⌛")
					message:addReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.fail.hash) or "❌")

					if server then
						server:execute(":pm " .. player.name .. " ❌・" .. content)
					end

					if member and discordContent then
						member:send((type(discordContent) == "table" and discordContent) or {
							embed = {
								description = emojis.fail .. " " .. (discordContent or content),
								color = colors.fail
							},
							components = signature(message.guild)
						})
					end
				end

				message:addReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.loading.hash) or "⌛")

				local succ, err = db:completeBOLO(violator, member, nil, true)
				if not succ then
					return message:addReaction((Client.user.id == "1257389588910182411" and resolvedEmojis.loading.hash) or "⌛")
				end

				return success("That player's BOLO has been successfully marked as complete.")
			end
		end)

		if not success then
			return log("An unexpected error occurred while processing a webhook message for " .. message.guild.id .. ": " .. tostring(err), "red")
		end
	end)
	
	connections.ERLC.raw = ERLC:on("raw", function(data)
		p("raw", data)
	end)

	connections.ERLC.probe = ERLC:on("probe", function()
		log("The webhook event listener has been probed by PRC.")
	end)

	connections.ERLC.command = ERLC:on("command", function(server, player, command, args)
		if not server or not player or not command or not args then return end
		log("Received command event for " .. tostring(server) .. " by " .. tostring(player) .. " : " .. tostring(command) .. " : " .. tostring(args), "cyan")

		if command:lower() == "ping" then
			return server:execute(":pm " .. player.name .. " Pong!")
		end
	end)

	connections.ERLC.commandUncached = ERLC:on("commandUncached", function(serverId, playerId, command, args)
		if not serverId or not playerId or not command or not args then return end
		log("Received commandUncached event for " .. tostring(serverId) .. " by " .. tostring(playerId) .. " : " .. tostring(command) .. " : " .. tostring(args), "cyan")

		-- what does prc expect us to do with this if we don't have its api key..
	end)
end

erlcchecker.Stop = function()
	for event, listener in pairs(connections.Clock) do
		Clock:removeListener(event, listener)
	end

	for event, listener in pairs(connections.Client) do
		Client:removeListener(event, listener)
	end

	for event, listener in pairs(connections.ERLC) do
		ERLC:removeListener(event, listener)
	end

	Clock:stop()
	connections = nil
end

return erlcchecker
