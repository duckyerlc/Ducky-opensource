-- giveaway.lua

local slashCommand = tools.slashCommand("giveaway", "Use Ducky's giveaway module.")
local subcmd = tools.subCommand("create", "Create a giveaway.")
subcmd = subcmd:addOption(tools.string("duration", "The duration of the giveaway (i.e. 1d, 6h, 30m)."):setRequired(true))
subcmd = subcmd:addOption(tools.string("prize", "The prize of the giveaway."):setRequired(true))
subcmd = subcmd:addOption(tools.integer("winners", "The amount of winners."):setRequired(false))
subcmd = subcmd:addOption(tools.mentionable("ping", "The giveaway ping."):setRequired(false))
subcmd = subcmd:addOption(tools.role("required_role", "The role that users must have to enter this giveaway."):setRequired(false))
subcmd = subcmd:addOption(tools.boolean("required_ingame", "Whether or not users must be in-game to join this giveaway."):setRequired(false))
subcmd = subcmd:addOption(tools.string("required_server", "The ID of the server that users must be in to enter this giveaway."):setRequired(false))
-- subcmd = subcmd:addOption(tools.string("required_group", "The ID of the Roblox Community that users must be in to enter this giveaway."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("end", "End a giveaway early.")
subcmd = subcmd:addOption(tools.string("giveaway", "The giveaway ID or the message ID/link of the giveaway message."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)
subcmd = tools.subCommand("cancel", "Cancel a giveaway.")
subcmd = subcmd:addOption(tools.string("giveaway", "The giveaway ID or the message ID/link of the giveaway message."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)

return {
    name = "giveaway",
    description = "Use Ducky's giveaway module!",
    aliases = {},
    category = "Giveaway",
    slashCommand = slashCommand,
    subcommands = {
		"create",
		"end",
		"cancel"
	},
    requiredPermissions = {"MANAGE_SERVER", "SETUP"},
    hybridCallback = function(interaction, args, slash, subcmd)
		local guild = interaction.guild
		local config = sqldb:get(guild.id) or {}
		local plusGuild = sqldb:plusGuild(guild)

		if (not slash) and subcmd then
			table.remove(args, 1)
		end

		if subcmd == "create" then
			local duration = (slash and args and args.duration and convert(args.duration)) or ((not slash) and args and args[1] and convert(args[1]))
			
			if not duration then
				return interaction:fail("You did not provide a valid duration for this giveaway.", nil, true)
			elseif duration <= 0 then
				return interaction:fail("The duration must be at least 1 second.", nil, true)
			end

			local prize = (slash and args and args.prize) or ((not slash) and args and table.remove(args, 1) and table.concat(args, " "))

			if (not prize) or (prize == "") then
				return interaction:fail("You did not provide a prize for this giveaway.", nil, true)
			end

			local winners = (slash and args and args.winners and tonumber(args.winners)) or 1

			if winners <= 0 then
				return interaction:fail("There must be at least one winner.", nil, true)
			end

			local ping = fetchMentionable(slash and args and args.ping, guild)
			local requiredRole = (slash and args and args.required_role)
			local requiredServerID = (slash and args and args.required_server)
			local requiredServer = plusGuild and requiredServerID and Client:getGuild(requiredServerID)
            local requiredInGame = not not (slash and args and args.required_ingame)
			local requiredGroupID = (slash and args and args.required_group)
			local requiredGroup = plusGuild and requiredGroupID and ropi.GetGroup(requiredGroupID)
			
			if requiredRole and (not plusGuild) then
				return interaction:fail("Required roles on giveaways is a " .. emojis.duckyplus .. " **Ducky Plus+** feature.", nil, true)
            elseif requiredServerID and (not plusGuild) then
				return interaction:fail("Required servers on giveaways is a " .. emojis.duckyplus .. " **Ducky Plus+** feature.", nil, true)
            elseif requiredInGame and (not plusGuild) then
                return interaction:fail("Required in-game on giveaways is a " .. emojis.duckyplus .. " **Ducky Plus+** feature.", nil, true)
			elseif requiredGroupID and (not plusGuild) then
                return interaction:fail("Required Roblox Community on giveaways is a " .. emojis.duckyplus .. " **Ducky Plus+** feature.", nil, true)
			elseif requiredServerID and (not requiredServer) then
				return interaction:fail("Ducky must be in the required server.", nil, true)
            elseif requiredInGame and (not config.apikey) then
                return interaction:fail("This server does not have an ERLC server linked, and therefore cannot use the in-game requirement feature.", nil, true)
			elseif requiredGroupID and not requiredGroup then
				return interaction:fail("I could not find that Roblox Community.", nil, true)
			end

			local giveawayID = interaction.id

			local giveawayMessage, e = interaction.channel:send({
				content = ping and "-# " .. emojis.pings .. " " .. ping,
				embeds = parseTable(config.giveawayembeds or {
					{
						title = emojis.gift .. " {giveaway.prize} Giveaway",
						description = emojis.right .. " **Host:** {host.mention}\n" .. emojis.right .. " **Prize:** {giveaway.prize}\n" .. emojis.right .. " **Winners:** {giveaway.winners}\n" .. emojis.right .. " **Ends:** <t:{giveaway.ends}> (<t:{giveaway.ends}:R>)\n" .. emojis.right .. " **Entries:** {giveaway.entries}",
						color = colors.info,
						author = author(guild)
					}
				}, {
					["host.mention"] = interaction.member.mentionString,
					["host.name"] = interaction.member.name,
					["host.username"] = interaction.user.username,
					["host.id"] = interaction.user.id,
					["giveaway.id"] = giveawayID,
					["giveaway.entries"] = 0,
					["giveaway.winners"] = winners,
					["giveaway.prize"] = prize,
					["giveaway.duration"] = readable(duration),
					["giveaway.ends"] = os.time() + duration,
					["requiredserver.name"] = (requiredServer and requiredServer.name) or emojis.fail,
					["requiredserver.id"] = (requiredServer and requiredServer.id) or emojis.fail,
					["requiredrole.name"] = (requiredRole and requiredRole.name) or emojis.fail,
					["requiredrole.mention"] = (requiredRole and requiredRole.mentionString) or emojis.fail,
					["requiredrole.id"] = (requiredRole and requiredRole.id) or emojis.fail,
                    ["requiredingame"] = (requiredInGame and emojis.success) or emojis.fail,
					["requiredgroup.name"] = (requiredGroup and requiredGroup.name) or emojis.fail,
					["requiredgroup.id"] = (requiredGroup and requiredGroup.id) or emojis.fail,
					["requiredgroup.link"] = (requiredGroup and requiredGroup.link) or emojis.fail,
					["requiredgroup.hyperlink"] = (requiredGroup and requiredGroup.hyperlink) or emojis.fail
				}),
				components = discordia.Components()
					:button({
						id = "entergiveaway_" .. giveawayID,
						emoji = resolvedEmojis.gift,
						style = "blurple"
					})
					:button({
						id = "giveawayentries_" .. giveawayID,
						emoji = resolvedEmojis.people,
						style = "secondary"
					})
					:raw()
			})

			if giveawayMessage then
				local newGiveawayObject = {
					channel = interaction.channel.id,
					message = giveawayMessage.id,
					id = giveawayID,
					entries = {},
					winners = winners,
					prize = prize,
					duration = duration,
					ends = os.time() + duration,
					started = os.time(),
					requiredserver = requiredServerID or nil,
					requiredrole = (requiredRole and requiredRole.id) or nil,
                    requiredingame = requiredInGame,
					requiredgroup = requiredGroupID or nil,
					host = {name = interaction.member.name, username = interaction.user.username, mention = interaction.member.mentionString, id = interaction.member.id}
				}

				config.giveaways = config.giveaways or {}
				config.giveaways[giveawayID] = newGiveawayObject

				sqldb:set(guild.id, {giveaways = config.giveaways}, "GIVEAWAY_CREATE")

				return interaction:success("Your giveaway has been created!\n-# " .. emojis.right .. " " .. giveawayMessage.link, nil, true)
			else
				return interaction:fail("Failed to send the giveaway message:\n>>> " .. e)
			end

		elseif subcmd == "end" then
			local giveawayID = (slash and args and args.giveaway) or ((not slash) and args and args[1])

			if not giveawayID then
				return interaction:fail("You must provide a giveaway to end.", nil, true)
			end

			giveawayID = giveawayID:match("(%d+)$") -- gets message id out of message link but changes nothing if just an id was provided

			local config = sqldb:get(guild.id) or {}
			local giveaway

			for id, info in pairs(config.giveaways) do
				if id == giveawayID or info.message == giveawayID then
					giveaway = info
					break
				end
			end

			if not giveaway then
				return interaction:fail("I could not find that giveaway.", nil, true)
			end

			if giveaway.rolled then
				return interaction:fail("That giveaway has already ended.", nil, true)
			end

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
						giveawayMessage:reply(emojis.fail .. " There are not any entries in this giveaway, and no winners could be drawn.\n-# " .. emojis.reminder .. " This giveaway was ended early by " .. getUserString(interaction.member) .. ".")
					else
						giveawayMessage:reply(emojis.right .. " *Congratulations, " .. table.concatFn(winners, ", ", function(w) return "<@" .. w .. ">" end) .. "! You won the **" .. giveaway.prize .. "**!*\n-# " .. emojis.reminder .. " This giveaway was ended early by " .. getUserString(interaction.member) .. ".")
					end
					giveawayMessage:update({
						embed = giveawayMessage.embeds and giveawayMessage.embeds[1],
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
				config.giveaways[giveawayID] = nil
			end

			sqldb:set(guild.id, {
				giveaways = config.giveaways
			}, "GIVEAWAY_UPDATE")

			return interaction:success("I have ended that giveaway.", nil, true)
		elseif subcmd == "cancel" then
			local giveawayID = (slash and args and args.giveaway) or ((not slash) and args and args[1])

			if not giveawayID then
				return interaction:fail("You must provide a giveaway to end.", nil, true)
			end

			giveawayID = giveawayID:match("(%d+)$") -- gets message id out of message link but changes nothing if just an id was provided

			local config = sqldb:get(guild.id) or {}
			config.giveaways = config.giveaways or {}
			
			local giveaway

			for id, info in pairs(config.giveaways) do
				if id == giveawayID or info.message == giveawayID then
					giveaway = info
					break
				end
			end

			if not giveaway then
				return interaction:fail("I could not find that giveaway.", nil, true)
			end

			if giveaway.rolled then
				return interaction:fail("That giveaway has already ended.", nil, true)
			end

			local giveawayChannel = guild:getChannel(giveaway.channel)
			local giveawayMessage = giveawayChannel and giveawayChannel:getMessage(giveaway.message)

			if giveawayMessage then
				giveawayMessage:reply(emojis.delete .. " This giveaway has been canceled by " .. getUserString(interaction.member) .. ".")
				giveawayMessage:update({
					embed = giveawayMessage.embeds[1],
					components = discordia.Components():button({
						id = "giveawayentries_" .. giveaway.id,
						emoji = resolvedEmojis.people,
						style = "secondary"
					}):raw()
				})
			end

			config.giveaways[giveawayID] = nil
			sqldb:set(guild.id, {giveaways = config.giveaways}, "GIVEAWAY_CANCEL")

			return interaction:success("I have canceled that giveaway.", nil, true)
		end
	end
}
