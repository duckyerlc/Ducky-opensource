-- modules/giveaways.lua
local giveaways = {
	name = "giveaways",
	description = "Handles all giveaway related interactions."
}

local connections = {}

giveaways.Start = function()
	connections["scheduleGiveaways"] = Client:on("scheduleGiveaways", function(guild, config)
		for id, giveaway in pairs(config.giveaways or {}) do
			if (giveaway.ends and os.time() >= giveaway.ends) and not giveaway.rolled then
				local winners = {}

				math.randomseed(os.time() + math.floor(math.random() * 10000))

				for i = 1, giveaway.winners do
					local attempt = 0
					local winner
					repeat
						winner = giveaway.entries[math.random(1, #giveaway.entries)]
						attempt = attempt + 1
					until (winner and (not table.find(winners, winner))) or attempt >= 5
					
					if winner then
						table.insert(winners, winner)
					end
				end

				giveaway.rolled = true

				local giveawayChannel = guild:getChannel(giveaway.channel)
				local giveawayMessage = giveawayChannel and giveawayChannel:getMessage(giveaway.message)

				if giveawayMessage then
					coroutine.wrap(function()
						if not next(winners) then
							giveawayMessage:reply(emojis.fail .. " There are not any entries in this giveaway, and no winners could be drawn.")
						else
							giveawayMessage:reply(emojis.right .. " *Congratulations, " .. table.concatFn(winners, ", ", function(w) return "<@" .. w .. ">" end) .. "! You won the **" .. giveaway.prize .. "**!*")
						end
						giveawayMessage:update({
							content = giveawayMessage.content,
							embeds = giveawayMessage.embeds,
							components = discordia.Components():button({
								id = "rerollgiveaway_" .. giveaway.id,
								emoji = resolvedEmojis.reload,
								style = "secondary",
								disabled = table.count(giveaway.entries) <= 0
							}):button({
								id = "giveawayentries_" .. giveaway.id,
								emoji = resolvedEmojis.people,
								style = "secondary"
							}):raw()
						})
					end)()
				else
					config.giveaways[id] = nil
				end

				sqldb:set(guild.id, {
					giveaways = config.giveaways
				}, "GIVEAWAY_UPDATE")
			end
		end
	end)
	connections["interactionGiveaways"] = Client:on("interactionGiveaways", function(interaction, config)
		local guild = interaction.guild
		local interactionId = interaction.data.custom_id

		if interactionId:usub(1, 14) == "entergiveaway_" then
			if config.giveaways and config.giveaways[interactionId:usub(15)] then
				local giveaway = config.giveaways[interactionId:usub(15)]
				local requiredServer = giveaway.requiredserver and Client:getGuild(giveaway.requiredserver)
				local requiredRole = giveaway.requiredrole and guild:getRole(giveaway.requiredrole)
				local requiredInGame = giveaway.requiredingame
				local blacklistedRole = config.giveawayblacklist and guild:getRole(config.giveawayblacklist)

				local function updateGiveawayEmbed()
					coroutine.wrap(function()
						interaction.message:update({
							content = interaction.message.content,
							embeds = parseTable(config.giveawayembeds or {
								{
									title = emojis.gift .. " {giveaway.prize} Giveaway",
									description = emojis.right .. " **Host:** {host.mention}\n" .. emojis.right .. " **Prize:** {giveaway.prize}\n" .. emojis.right .. " **Winners:** {giveaway.winners}\n" .. emojis.right .. " **Ends:** <t:{giveaway.ends}> (<t:{giveaway.ends}:R>)\n" .. emojis.right .. " **Entries:** {giveaway.entries}",
									color = colors.info,
									author = {
										name = guild.name,
										icon_url = guild.iconURL
									}
								}
							}, {
								["host.mention"] = giveaway.host.mention,
								["host.name"] = giveaway.host.name,
								["host.username"] = giveaway.host.username,
								["host.id"] = giveaway.host.id,
								["giveaway.id"] = giveaway.id,
								["giveaway.entries"] = #giveaway.entries,
								["giveaway.winners"] = giveaway.winners,
								["giveaway.prize"] = giveaway.prize,
								["giveaway.duration"] = readable(giveaway.duration),
								["giveaway.ends"] = giveaway.ends,
								["requiredserver.name"] = (requiredServer and requiredServer.name) or emojis.fail,
								["requiredserver.id"] = (requiredServer and requiredServer.id) or emojis.fail,
								["requiredrole.name"] = (requiredRole and requiredRole.name) or emojis.fail,
								["requiredrole.mention"] = (requiredRole and requiredRole.mentionString) or emojis.fail,
								["requiredrole.id"] = (requiredRole and requiredRole.id) or emojis.fail,
								["requiredingame"] = (requiredInGame and emojis.success) or emojis.fail
							}),
							components = interaction.message.components
						})
					end)()
				end

				if table.find(giveaway.entries, interaction.user.id) then
					for k, e in pairs(giveaway.entries) do
						if e == interaction.user.id then
							confirm(interaction, "Are you sure you would like to leave this giveaway?", function(confirmed, ria)
								if confirmed then
									table.remove(giveaway.entries, k)
									sqldb:set(guild.id, {
										giveaways = config.giveaways
									}, "GIVEAWAY_LEAVE")
									updateGiveawayEmbed()
									return ria:warning("You have left this giveaway.", nil, true)
								end
							end, true)
						end
					end
				else
					if blacklistedRole then if interaction.member:hasRole(blacklistedRole.id) then return interaction:fail("You are blacklisted from giveaways in this server.", nil, true) end end

					if requiredRole then if not interaction.member:hasRole(requiredRole.id) then return interaction:fail("You must have the required role, " .. requiredRole.mentionString .. ", to enter this giveaway.", nil, true) end end
					if requiredServer then if not requiredServer:getMember(interaction.user.id) then return interaction:fail("You must be in the required server, **" .. requiredServer.name .. "**, to enter this giveaway.", nil, true) end end
					if requiredInGame then
						local link = sqldb:getLink(interaction.user.id)

						if link and link.roblox then
							local server = config.apikey and ERLC:getServer(config.apikey)
							local ingame = table.find(server and server._players or {}, function(p)
								return p.id == link.roblox
							end)
							
							if not ingame then return interaction:fail("You must be in-game to enter this giveaway.", nil, true) end
						else
							return interaction:fail("You must be linked with Ducky in order to meet the in-game requirement to enter this giveaway.", nil, true)
						end
					end

					table.insert(giveaway.entries, interaction.user.id)
					sqldb:set(guild.id, {
						giveaways = config.giveaways
					}, "GIVEAWAY_ENTER")
					updateGiveawayEmbed()
					return interaction:success("You have entered this giveaway.", nil, true)
				end
			else
				return interaction:fail("This giveaway no longer exists.", nil, true)
			end
		elseif interactionId:usub(1, 16) == "giveawayentries_" then
			if config.giveaways and config.giveaways[interactionId:usub(17)] then
				local giveaway = config.giveaways[interactionId:usub(17)]

				if (not giveaway.entries) or (table.count(giveaway.entries) <= 0) then return interaction:fail("No members have entered this giveaway.", nil, true) end

				local pages = {}
				local embed = {
					title = emojis.people .. " Giveaway Entries (" .. table.count(giveaway.entries) .. ")",
					description = "",
					color = colors.info
				}
				local onPage = 0

				for c, id in pairs(giveaway.entries) do
					embed.description = embed.description .. emojis.right .. " <@" .. id .. ">\n"

					onPage = onPage + 1

					if onPage >= 20 or c >= table.count(giveaway.entries) then
						table.insert(pages, embed)
						embed = {
							title = emojis.people .. " Giveaway Entries (" .. table.count(giveaway.entries) .. ")",
							description = "",
							color = colors.info
						}
						onPage = 0
					end
				end

				paginate(interaction, pages, interaction.user, {
					clamp = false,
					ephemeral = true
				})
			else
				return interaction:fail("This giveaway no longer exists.", nil, true)
			end
		elseif interactionId:usub(1, 15) == "rerollgiveaway_" then
			if not hasPermission(interaction.member, "MANAGE_SERVER", config, interaction) then return end

			if config.giveaways and config.giveaways[interactionId:usub(16)] then
				local giveaway = config.giveaways[interactionId:usub(16)]

				local winners = {}

				math.randomseed(os.time() + math.floor(math.random() * 10000))

				for i = 1, giveaway.winners do
					local attempt = 0
					local winner
					repeat
						winner = giveaway.entries[math.random(1, #giveaway.entries)]
						attempt = attempt + 1
					until (winner and (not table.find(winners, winner))) or attempt >= 5
					
					if winner then
						table.insert(winners, winner)
					end
				end

				giveaway.rolled = true

				coroutine.wrap(function()
					if not next(winners) then
						interaction:reply(emojis.fail .. " There are not any entries in this giveaway, and no winners could be drawn.\n-# " .. emojis.reload .. " This giveaway was rerolled by **" .. interaction.member.name .. "**.", false)
					else
						interaction:reply(emojis.right .. " *Congratulations, " .. table.concatFn(winners, ", ", function(w) return "<@" .. w .. ">" end) .. "! You won the **" .. giveaway.prize .. "**!*\n-# " .. emojis.reload .. " This giveaway was rerolled by **" .. interaction.member.name .. "**.", false)
					end
				end)()

				sqldb:set(guild.id, {
					giveaways = config.giveaways
				}, "GIVEAWAY_REROLL")
			else
				return interaction:fail("This giveaway no longer exists.", nil, true)
			end
		end
	end)
end

giveaways.Stop = function()
	for event, connection in pairs(connections) do Client:removeListener(event, connection) end

	connections = nil
end

return giveaways
