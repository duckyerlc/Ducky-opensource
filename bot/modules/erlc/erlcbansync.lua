-- modules/erlcbansync.lua
local erlcbansync = {
	name = "erlcbansync",
	description = "Handles all erlcbansync related interactions."
}

local connections = {}

erlcbansync.Start = function()
	connections["userBanErlcbansync"] = Client:on("userBanErlcbansync", function(user, guild, config)
		if config.erlcbansync and (config.erlcbansync == "dctoerlc" or config.erlcbansync == "both") then
			local link = sqldb:getLink(user.id)

			if link then
				local cmd = ":ban " .. link.roblox .. " Ducky Ban Syncing"

				local moderator

				local s, d = Client:waitFor("guildAuditLogEntryCreate", 30000, function(d)
					if (d.guild_id == guild.id) and (d.action_type == discordia.enums.actionType.memberBanAdd) then
						return true
					end
				end)

				if s then
					moderator = guild:getMember(d.user_id)
				end

				if not moderator then
					return
				end

				local violator = ropi.GetUser(link.roblox)

				if not violator then
					return
				end

				timer.sleep(5000) -- ERLC API is slow so if no sleep it would trigger itself in Both syncing mode

				local server, err = ERLC:getServer(config.apikey)
				if not server then
					return
				end

				local erlcBans, err = ERLC._api:getServerBans(config.apikey) -- TODO: implement properly into erlua Server class
				if not erlcBans then
					return
				end

				for robloxID, robloxUser in pairs(erlcBans) do
					if robloxID == tostring(link.roblox) then
						return
					end
				end

				if #server.players <= 0 and sqldb:plusGuild(guild) then
					local success, err = db:commandQueueInsert(guild, cmd)
					if success then
						db:send(guild, "erlccmdschannel", {
							embed = {
								author = author(moderator),
								thumbnail = thumbnail(user),
								title = emojis.success .. " Ban Syncing Successful",
								description = "> " .. getUserString(moderator) .. " banned " .. getUserString(user) .. " in Discord. Therefore, Ducky has queued the ban of **" .. violator.hyperlink .. "** in the in-game server.",
								color = colors.success
							}
						})
					end
				else
					local success, err = server:execute(cmd)
					if success then
						db:send(guild, "erlckickbanchannel", {
							embed = {
								author = author(moderator),
								thumbnail = thumbnail(user),
								title = emojis.success .. " Ban Syncing Successful",
								description = "> " .. getUserString(moderator) .. " banned " .. getUserString(user) .. " in Discord. Therefore, Ducky has banned **" .. violator.hyperlink .. "** from the in-game server.",
								color = colors.success
							}
						})
					else
						db:send(guild, "erlckickbanchannel", {
							embed = {
								author = author(moderator),
								thumbnail = thumbnail(user),
								title = emojis.fail .. " Ban Syncing Failed",
								description = "> " .. getUserString(moderator) .. " banned " .. getUserString(user) .. " in Discord. However, Ducky was unable to ban **" .. violator.hyperlink .. "** from the in-game server: ```" .. err .. "```",
								color = colors.fail
							}
						})
					end
				end
			end
		end
	end)

	connections["userUnbanErlcbansync"] = Client:on("userUnbanErlcbansync", function(user, guild, config)
		if config.erlcbansync and (config.erlcbansync == "dctoerlc" or config.erlcbansync == "both") then
			local link = sqldb:getLink(user.id)

			if link then
				local cmd = ":unban " .. link.roblox

				local moderator

				local s, d = Client:waitFor("guildAuditLogEntryCreate", 30000, function(d)
					if (d.guild_id == guild.id) and (d.action_type == discordia.enums.actionType.memberBanRemove) then
						return true
					end
				end)

				if s then
					moderator = guild:getMember(d.user_id)
				end

				if not moderator then
					return
				end

				local violator = ropi.GetUser(link.roblox)

				if not violator then
					return
				end

				timer.sleep(5000) -- ERLC API is slow so if no sleep it would trigger itself in Both syncing mode

				local server, err = ERLC:getServer(config.apikey)
				if not server then
					return
				end

				local erlcBans, err = ERLC._api:getServerBans(config.apikey) -- TODO: implement properly into erlua Server class
				if not erlcBans then
					return
				end

				local banned = false

				for robloxID, robloxUser in pairs(erlcBans) do
					if robloxID == tostring(link.roblox) then
						banned = true
					end
				end

				if not banned then
					return
				end

				if #server.players <= 0 and sqldb:plusGuild(guild) then
					local success, err = db:commandQueueInsert(guild, cmd)
					if success then
						db:send(guild, "erlccmdschannel", {
							embed = {
								author = author(moderator),
								thumbnail = thumbnail(user),
								title = emojis.success .. " Ban Syncing Successful",
								description = "> " .. getUserString(moderator) .. " unbanned " .. getUserString(user) .. " in Discord. Therefore, Ducky has queued the unban of **" .. violator.hyperlink .. "** in the in-game server.",
								color = colors.success
							}
						})
					end
				else
					local success, err = server:execute(cmd)
					if success then
						db:send(guild, "erlckickbanchannel", {
							embed = {
								author = author(moderator),
								thumbnail = thumbnail(user),
								title = emojis.success .. " Ban Syncing Successful",
								description = "> " .. getUserString(moderator) .. " unbanned " .. getUserString(user) .. " in Discord. Therefore, Ducky has unbanned **" .. violator.hyperlink .. "** from the in-game server.",
								color = colors.success
							}
						})
					else
						db:send(guild, "erlckickbanchannel", {
							embed = {
								author = author(moderator),
								thumbnail = thumbnail(user),
								title = emojis.fail .. " Ban Syncing Failed",
								description = "> " .. getUserString(moderator) .. " unbanned " .. getUserString(user) .. " in Discord. However, Ducky was unable to unban **" .. violator.hyperlink .. "** from the in-game server: ```" .. err .. "```",
								color = colors.fail
							}
						})
					end
				end
			end
		end
	end)

	connections["memberJoinErlcbansync"] = Client:on("memberJoinErlcbansync", function(member, config)
		if config.apikey and config.erlcbansync and (config.erlcbansync == "erlctodc" or config.erlcbansync == "both") then
			local link = sqldb:getLink(member.id)

			if link then
				local robloxID = tostring(link.roblox)
				local moderator = member.guild.me
				if not moderator then return end

				local bans, err = ERLC._api:getServerBans(config.apikey) -- TODO: implement properly into erlua Server class
				if not bans then return end

				for id, name in pairs(bans) do
					if id == robloxID then
						banMember(member.guild, member, member.user, moderator, "Ducky Ban Syncing")
					end
				end
			end
		end
	end)

	connections["erlcWebhookErlcbansync"] = Client:on("erlcWebhookErlcbansync", function(type, moderator, violator, config)
		if
			(not type) or
			(not moderator) or
			(not moderator.guild) or
			(not violator) or
			(not config) or
			(not (config.erlcbansync == "erlctodc" or config.erlcbansync == "both"))
		then return end
		
		local guild = moderator.guild
		
		if type == "ban" then
			local violatorLink = sqldb:getLink(violator.id)
			local violatorUser = violatorLink and Client:getUser(violatorLink.discord)
			local violatorMember = violatorLink and guild:getMember(violatorLink.discord)
			if (not violatorUser) or guild:getBan(violatorUser.id) then
				return
			end

			local success, result = banMember(guild, violatorMember, violatorUser, moderator, "banned from the in-game server (ban syncing)")

			if success then
				db:send(guild, "erlckickbanchannel", {
					embed = {
						author = author(moderator),
						thumbnail = thumbnail(violatorUser),
						title = emojis.success .. " Ban Syncing Successful",
						description = "> " .. getUserString(moderator) .. " banned **" .. violator.hyperlink .. "** in-game. Therefore, Ducky has banned " .. getUserString(violatorUser) .. " from the Discord server.",
						color = colors.success
					}
				})
			else
				db:send(guild, "erlckickbanchannel", {
					embed = {
						author = author(moderator),
						thumbnail = thumbnail(violatorUser),
						title = emojis.fail .. " Ban Syncing Failed",
						description = "> " .. getUserString(moderator) .. " banned **" .. violator.hyperlink .. "** in-game. However, Ducky was unable to ban " .. getUserString(violatorUser) .. " from the Discord server: ```" .. result .. "```",
						color = colors.fail
					}
				})
			end
		elseif type == "unban" then
			local violatorLink = sqldb:getLink(violator.id)
			local violatorUser = violatorLink and Client:getUser(violatorLink.discord)
			local violatorMember = violatorLink and guild:getMember(violatorLink.discord)
			if (not violatorUser) or (not guild:getBan(violatorUser.id)) then
				return
			end

			local success, result = guild:unbanUser(violatorUser.id, "unbanned from the in-game server (ban syncing)")

			if success then
				violatorUser:success("You have been unbanned from **" .. guild.name .. "**.")

				db:send(guild, "modlogchannel", {
					embed = {
						author = author(moderator),
						thumbnail = thumbnail(violatorUser),
						title = emojis.success .. " Member Unbanned",
						description = getUserString(violatorUser) .. " was unbanned by " .. getUserString(moderator) .. ":" .. "\n" .. emojis.right .. " **Reason:** unbanned from the in-game server (ban syncing)" .. "\n" .. emojis.right .. " **Date:** <t:" .. os.time() .. ">",
						color = colors.success
					}
				})

				db:send(guild, "erlccmdschannel", {
					embed = {
						author = author(moderator),
						thumbnail = thumbnail(violatorUser),
						title = emojis.success .. " Ban Syncing Successful",
						description = "> " .. getUserString(moderator) .. " unbanned **" .. violator.hyperlink .. "** in-game. Therefore, Ducky has unbanned " .. getUserString(violatorUser) .. " from the Discord server.",
						color = colors.success
					}
				})
			else
				db:send(guild, "erlccmdschannel", {
					embed = {
						author = author(moderator),
						thumbnail = thumbnail(violatorUser),
						title = emojis.fail .. " Ban Syncing Failed",
						description = "> " .. getUserString(moderator) .. " unbanned **" .. violator.hyperlink .. "** in-game. However, Ducky was unable to unban " .. getUserString(violatorUser) .. " from the Discord server: ```" .. (result or "Unknown Error") .. "```",
						color = colors.fail
					}
				})
			end
		end
	end)
end

erlcbansync.Stop = function()
	for event, connection in pairs(connections) do
		Client:removeListener(event, connection)
	end

	connections = nil
end

return erlcbansync
