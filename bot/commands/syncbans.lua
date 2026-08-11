-- syncbans.lua
local slashCommand = tools.slashCommand("syncbans", "Synchronize bans according to the server's ban syncing mode.")

local cooldown = {}

return {
	name = "syncbans",
	description = "Synchronize bans according to the server's ban syncing mode.",
	aliases = {
		"sb",
		"bansync",
		"bansyncing"
	},
	category = "ERLC",
	slashCommand = slashCommand,
	requiredPermissions = {
		"MANAGE_SERVER"
	},
	hybridCallback = function(interaction, args)
		local guild = interaction.guild

		local config = sqldb:get(guild.id) or {}

		if not config.apikey then
			return interaction:fail("You must link an ERLC server to use this feature.", nil, true)
		end

		if not config.erlcbansync then
			return interaction:fail("Ban Syncing is not enabled in this server. You can enable it on the " .. emojis.game .. " **ERLC Integration** page in `/setup`.", nil, true)
		end

		if cooldown[guild.id] then
			if cooldown[guild.id] == 0 then
				return interaction:fail("I'm currently already syncing bans in this server.", nil, true)
			end

			local plus = sqldb:plusGuild(guild)
			local cooldownTime = (plus and 1800) or 3600

			if os.time() - cooldown[guild.id] <= cooldownTime then
				return interaction:fail()
			end
		end

		local discordBans, dcErr = guild:getBans()
		if not discordBans then
			return interaction:fail("Failed to fetch Discord bans: ```" .. (dcErr or "Unknown Error") .. "```", nil, true)
		end

		local server, err = ERLC:getServer(config.apikey)
		if not server then
			return interaction:fail("The server could not be fetched: " .. tostring(err), nil, true)
		end

		local erlcBans, err = ERLC._api:getServerBans(config.apikey) -- TODO: implement properly into erlua Server class
		if not erlcBans then
			return interaction:fail("The in-game bans could not be fetched: " .. tostring(err), nil, true)
		end

		if config.erlcbansync == "dctoerlc" then
			if #server.players <= 0 then
				return interaction:fail("The Discord to ERLC Ban Syncing Mode requires the ERLC server to be online.", nil, true)
			end

			local r = interaction:reply({
				embed = {
					description = emojis.loading .. " Fetching users to ban...",
					color = colors.blank
				}
			})

			if type(r) ~= "table" then
				return interaction:fail("Failed to send loading message, please try again.", nil, true)
			end

			cooldown[guild.id] = 0

			local usersToBan = {}

			for _, ban in pairs(discordBans) do
				local link = sqldb:getLink(ban.user.id)

				if link then
					local alreadyBanned = false

					for robloxID, robloxName in pairs(erlcBans) do
						if robloxID == tostring(link.roblox) then
							alreadyBanned = true
						end
					end

					if not alreadyBanned then
						table.insert(usersToBan, link.roblox)
					end
				end
			end

			if table.count(usersToBan) < 1 then
				cooldown[guild.id] = os.time()
				return r:update({
					embed = {
						description = emojis.success .. " No users found to ban.",
						color = colors.success
					}
				})
			end

			r:update({
				embed = {
					description = emojis.loading .. " Banning users...\n-# " .. emojis.right .. " This can take a while due to ratelimits.",
					color = colors.blank
				}
			})

			local bannedUsers = 0
			local failedUsers = 0

			for _, robloxID in pairs(usersToBan) do
				local succ, err = server:execute(":ban " .. tostring(robloxID))

				if succ then
					bannedUsers = bannedUsers + 1
				else
					failedUsers = failedUsers + 1
				end

				timer.sleep(500)
			end

			return r:update({
				embed = {
					description = emojis.success .. " Synced **" .. tostring(bannedUsers) .. " ban" .. ((bannedUsers > 1 and "s") or "") .. "** from Discord to ERLC." .. ((failedUsers > 0 and "\n-# " .. emojis.fail .. " Failed to ban " .. tostring(failedUsers) .. " users.") or ""),
					color = colors.success
				}
			})
		elseif config.erlcbansync == "erlctodc" then
			local r = interaction:reply({
				embed = {
					description = emojis.loading .. " Fetching users to ban...",
					color = colors.blank
				}
			})

			if type(r) ~= "table" then
				return interaction:fail("Failed to send loading message, please try again.", nil, true)
			end

			local usersToBan = {}

			for _, ban in pairs(discordBans) do
				if ban and ban.user then
					local link
					sqldb:getLink(ban.user.id)

					if link then
						local alreadyBanned = false

						for robloxID, robloxName in pairs(erlcBans) do
							if robloxID == tostring(link.roblox) then
								alreadyBanned = true
							end
						end

						if not alreadyBanned then
							table.insert(usersToBan, link.roblox)
						end
					end
				end
			end

			for robloxID, robloxName in pairs(erlcBans) do
				local link = sqldb:getLink(robloxID)

				if link then
					if link then
						local alreadyBanned = false

						for _, ban in pairs(discordBans) do
							if ban.user.id == link.discord then
								alreadyBanned = true
							end
						end

						if not alreadyBanned then
							table.insert(usersToBan, link.discord)
						end
					end
				end
			end

			if table.count(usersToBan) < 1 then
				cooldown[guild.id] = os.time()
				return r:update({
					embed = {
						description = emojis.success .. " No users found to ban.",
						color = colors.success
					}
				})
			end

			r:update({
				embed = {
					description = emojis.loading .. " Banning users...\n-# " .. emojis.right .. " This can take a while due to ratelimits.",
					color = colors.blank
				}
			})

			local bannedUsers = 0
			local failedUsers = 0

			for _, discordID in pairs(usersToBan) do
				local violatorMember = guild:getMember(discordID)
				local violator = Client:getUser(discordID)

				local succ, err = banMember(guild, violatorMember, violator, interaction.member, "Ducky Ban Syncing")

				if succ then
					bannedUsers = bannedUsers + 1
				else
					failedUsers = failedUsers + 1
				end

				timer.sleep(500)
			end

			return r:update({
				embed = {
					description = emojis.success .. " Synced **" .. tostring(bannedUsers) .. " ban" .. ((bannedUsers > 1 and "s") or "") .. "** from ERLC to Discord." .. ((failedUsers > 0 and "\n-# " .. emojis.fail .. " Failed to ban " .. tostring(failedUsers) .. " users.") or ""),
					color = colors.success
				}
			})
		elseif config.erlcbansync == "both" then
			if #server.players <= 0 then
				return interaction:fail("The Both Ban Syncing Mode requires the ERLC server to be online.")
			end

			local r = interaction:reply({
				embed = {
					description = emojis.loading .. " Fetching users to ban...",
					color = colors.blank
				}
			})

			if type(r) ~= "table" then
				return interaction:fail("Failed to send loading message, please try again.", nil, true)
			end

			local erlcUsersToBan = {}
			local discordUsersToBan = {}

			for _, ban in pairs(discordBans) do
				local link
				sqldb:getLink(ban.user.id)

				if link then
					local alreadyBanned = false

					for robloxID, robloxName in pairs(erlcBans) do
						if robloxID == tostring(link.roblox) then
							alreadyBanned = true
						end
					end

					if not alreadyBanned then
						table.insert(erlcUsersToBan, link.roblox)
					end
				end
			end

			for robloxID, robloxName in pairs(erlcBans) do
				local link = sqldb:getLink(robloxID)

				if link then
					if link then
						local alreadyBanned = false

						for _, ban in pairs(discordBans) do
							if ban.user.id == link.discord then
								alreadyBanned = true
							end
						end

						if not alreadyBanned then
							table.insert(discordUsersToBan, link.discord)
						end
					end
				end
			end

			if table.count(erlcUsersToBan) < 1 and table.count(discordUsersToBan) < 1 then
				cooldown[guild.id] = os.time()
				return r:update({
					embed = {
						description = emojis.success .. " No users found to ban.",
						color = colors.success
					}
				})
			end

			r:update({
				embed = {
					description = emojis.loading .. " Banning users...\n-# " .. emojis.right .. " This can take a while due to ratelimits.",
					color = colors.blank
				}
			})

			local bannedUsers = 0
			local failedUsers = 0

			for _, robloxID in pairs(erlcUsersToBan) do
				local succ = server:execute(":ban " .. tostring(robloxID))

				if succ then
					bannedUsers = bannedUsers + 1
				else
					failedUsers = failedUsers + 1
				end

				timer.sleep(500)
			end

			for _, discordID in pairs(discordUsersToBan) do
				local violatorMember = guild:getMember(discordID)
				local violator = Client:getUser(discordID)

				local succ, err = banMember(guild, violatorMember, violator, interaction.member, "Ducky Ban Syncing")

				if succ then
					bannedUsers = bannedUsers + 1
				else
					failedUsers = failedUsers + 1
				end

				timer.sleep(500)
			end

			return r:update({
				embed = {
					description = emojis.success .. " Synced **" .. tostring(bannedUsers) .. " ban" .. ((bannedUsers > 1 and "s") or "") .. "** from Discord to ERLC." .. ((failedUsers > 0 and "\n-# " .. emojis.fail .. " Failed to ban " .. tostring(failedUsers) .. " users.") or ""),
					color = colors.success
				}
			})
		end
	end
}
