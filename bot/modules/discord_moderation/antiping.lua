-- modules/antiping.lua

local antiping = {
	name = "antiping",
	description = "Handles all antiping related interactions.",
}

local connections = {}

local appause = 12000 -- how long it waits to delete the antiping alert message
local gppause = 12000 -- how long it waits to delete the ghost ping alert message
local apgpcooldown = 4 -- cooldown of anti/ghost ping per channel
local pingsCooldown = {}

antiping.Start = function()
	connections["messageCreateAntiPing"] = Client:on("messageCreateAntiPing", function(message, config)
		local guild = message.guild

		if
			config.antiping
			and config.antipingprotectedroles
			and not message.user.bot
			and message.mentionedUsersIncludingReplies
			and message.mentionedUsersIncludingReplies.first
			and (not message.member:hasPermission("manageGuild"))
			and message.channel
			and not (config.antipingwhitelistedchannels and table.find(config.antipingwhitelistedchannels, message.channel.id))
		then
			if pingsCooldown[message.channel.id] and os.time() - pingsCooldown[message.channel.id] < apgpcooldown then
				return
			end

			pingsCooldown[message.channel.id] = os.time()

			local member = message.member
			local mentions = {}

			for _, v in pairs(message.mentionedUsersIncludingReplies) do
				if (v.id ~= message.user.id) and not v.bot then
					local m = guild:getMember(v.id)
					if m then
						table.insert(mentions, m)
					end
				end
			end

			local protect = config.antipingprotectedroles
			local whitelist = config.antipingwhitelistedroles
			local hierarchy = config.antipinghierarchy

			local function getRoles(ids)
				local roles = {}

				for _, v in pairs(ids or {}) do
					local r = guild:getRole(v)
					roles[v] = r
				end

				return roles
			end

			local protectRoles = getRoles(protect)
			local whitelistRoles = getRoles(whitelist)

			if not protectRoles then
				return
			end

			local function isProtected(m)
				for id, role in pairs(protectRoles) do
					if hierarchy then
						local rolepos = role.position
						local memberhighestpos = m.highestRole and m.highestRole.position
						if (memberhighestpos and rolepos) and (memberhighestpos >= rolepos) then
							return true
						end
					else
						if m:hasRole(id) then
							return true
						end
					end
				end
				return false
			end

			local function isWhitelisted(m)
				local lowestWhitelistedRole = {
					position = -1,
				}
				for id, role in pairs(whitelistRoles) do
					if role.position > lowestWhitelistedRole.position then
						lowestWhitelistedRole = role
					end
				end
				for id, role in pairs(whitelistRoles) do
					if m:hasRole(id) then
						return true
					elseif hierarchy and (m.highestRole.position >= lowestWhitelistedRole.position) then
						return true
					end
				end
				return false
			end

			local alert = false

			if not isWhitelisted(member) then
				for _, mention in pairs(mentions) do
					if isProtected(mention) then
						alert = true
						break
					end
				end
			end

			if alert then
				local embs = config.antipingembeds
					or {{
						title = emojis.warning .. " Anti-Ping Alert",
						description = "",
						color = colors.warning,
					}}

				embs = parseTable(embs, DiscordUserVariables(message.user, "offender"))

				if not config.antipingembeds then
					if hierarchy then
						local lowest = nil
						for _, role in pairs(protectRoles) do
							if not lowest or role.position < lowest.position then
								lowest = role
							end
						end

						lowest = "<@&" .. lowest.id .. ">"
						embs[1].description = "> Do **NOT** mention users with the "
							.. lowest
							.. " role or above! If you continue, you may be moderated."
					else
						local str = ""
						for i, v in pairs(protect) do
							str = str .. "<@&" .. v .. ">" .. (((i == #protect) and "") or ", ")
						end
						embs[1].description = "> Do **NOT** mention users with the "
							.. str
							.. " role"
							.. (((#protect ~= 1) and "s") or "")
							.. "! If you continue, you may be moderated."
					end

					if message.referencedMessage then
						embs[1].description = embs[1].description
							.. "\n> -# "
							.. emojis.right
							.. " View the GIF below to see how to turn off reply mentions."
						embs[1].image = {
							url = "https://duckybot.xyz/images/banners/full/reply.gif",
						}
					end
				end

				local r = message:reply({
					embeds = embs,
				})
				coroutine.wrap(function()
					timer.sleep(appause)
					if r then
						r:delete()
					end
				end)()
			end
		end
	end)

	connections["messageDeleteAntiPing"] = Client:on("messageDeleteAntiPing", function(message, bulk, config)
		if
			(bulk == true)
			or (message.member:hasPermission("manageGuild"))
			or not message.mentionedUsersIncludingReplies
			or not message.mentionedUsersIncludingReplies.first
			or message.mentionedUsersIncludingReplies.first.bot
			or (not message.guild:getMember(message.mentionedUsersIncludingReplies.first.id))
		then
			return
		end

		if pingsCooldown[message.channel.id] and os.time() - pingsCooldown[message.channel.id] < apgpcooldown then
			return
		end

		pingsCooldown[message.channel.id] = os.time()

		if config and config.antiping then
			if message.mentionedUsersIncludingReplies.first.id == message.member.id then
				return
			end

			local memberroles = message.member.roles
			for _, v in pairs(config.antipingwhitelistedroles or {}) do
				for _, r in pairs(memberroles) do
					if r.id == v then
						return
					end
				end
			end

			local embs = config.ghostpingembeds
				or {{
					title = emojis.warning .. " Ghost Ping Alert",
					description = "> Do **NOT** ghost ping users! If you continue, you may be moderated.",
					color = colors.warning,
				}}

			embs = parseTable(embs, DiscordUserVariables(message.user, "offender"))

			local r = message.channel:send({
				content = message.member.mentionString,
				embeds = embs,
			})

			coroutine.wrap(function()
				timer.sleep(gppause)
				if r then
					r:delete()
				end
			end)()
		end
	end)
end

antiping.Stop = function()
	for event, connection in pairs(connections) do
		Client:removeListener(event, connection)
	end

	pingsCooldown = nil
	connections = nil
end

return antiping