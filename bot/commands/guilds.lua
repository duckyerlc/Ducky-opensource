-- guilds.lua
return {
    name = "guilds",
    description = "Get the servers that Ducky is in.",
    aliases = {"servers"},
    category = "Utility",
    slashCommand = nil,
    requiredPermissions = {"SUPPORT"},
	hybridCallback = function(interaction, args)
		local sortby = (args[1] and args[1]:lower() and (args[1]:lower() == "members" or args[1]:lower() == "joined" or args[1]:lower() == "duckyplus" or args[1]:lower() == "abc" or args[1]:lower() == "notconfigured") and args[1]:lower())
		local footer = ""

		local pagination, updatePagination, currentPage

		local guilds = {}

		local configs = sqldb:getAllGuildConfigs()

		for _, g in pairs(Client.guilds) do
			if not g.unavailable then
				if sortby == "duckyplus" then
					if sqldb:plusGuild(g) then
						table.insert(guilds, g)
					end
				elseif sortby == "notconfigured" then
					if not configs[g.id] then
						table.insert(guilds, g)
					end
				else
					table.insert(guilds, g)
				end
			end
		end

		table.sort(guilds, function(a,b)
			if (not sortby) or sortby == "members" then
				footer = "Guilds are sorted by membercount, greatest to least."
				return a.totalMemberCount > b.totalMemberCount
			elseif sortby == "joined" then
				footer = "Guilds are sorted based on when Ducky joined, most recent to oldest."
				return discordia.Date.fromISO(a.joinedAt):toSeconds() > discordia.Date.fromISO(b.joinedAt):toSeconds()
			elseif sortby == "abc" then
				footer = "Guilds are sorted in alphabetical order."
				return a.name:lower() < b.name:lower()
			elseif sortby == "duckyplus" then
				footer = "Only guilds with " .. emojis.duckyplus .. " **Ducky Plus+** are shown."
				return a.totalMemberCount > b.totalMemberCount
			elseif sortby == "notconfigured" then
				footer = "Only guilds that are not configured are shown."
				return a.totalMemberCount > b.totalMemberCount
			else
				footer = "Guilds are not sorted in any way."
				return true
			end
		end)
		
		local pages = {
			{
				title = emojis.guild .. " Guilds",
				description = "> Ducky is in **" .. #Client.guilds .. "** guilds.\n> -# " .. emojis.filter .. " " .. footer,
				color = colors.info,
				identifier = {
					text = "Guilds",
					description = footer,
					emoji = resolvedEmojis.guild
				}
			}
		}

		local options = {
			{
				label = "Generate Support Invite",
				value = "invite",
				description = "Generate an invite to the server.",
				emoji = resolvedEmojis.support
			}
		}

		if hasPermission(interaction.member, "BOT_DEVELOPER") then
			table.insert(options, {
				label = "Notify Owner",
				value = "notify",
				description = "Send a notification to the server's owner.",
				emoji = resolvedEmojis.pings
			})

			table.insert(options, {
				label = "Remove Ducky",
				value = "remove",
				description = "Remove Ducky from the server.",
				emoji = resolvedEmojis.kick
			})
		end

		for _, guild in pairs(guilds) do
			local plus = sqldb:plusGuild(guild)
			local sanitizedGuildName = sanitizeGuildName(guild.name)

			table.insert(pages, {
				author = {
					name = guild.name,
					icon_url = guild.iconURL
				},
				title = emojis.guild .. " " .. guild.name,
				description = emojis.right .. " **Guild ID:** `" .. guild.id .. "`\n" .. emojis.right .. " **Members:** " .. guild.totalMemberCount .. "\n" .. emojis.right .. " **Owner:** <@" .. tostring(guild.ownerId) .. ">\n" .. emojis.right .. " **Joined:** <t:" .. fromISO(guild.joinedAt) .. ">\n" .. emojis.right .. " **Configured:** " .. ((configs[guild.id] and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Shard:** " .. guild.shardId,
				thumbnail = guild.iconURL and {
					url = guild.iconURL
				},
				color = colors.info,
				identifier = {
					text = string.truncate(sanitizedGuildName, 80),
					description = guild.totalMemberCount .. " members・" .. (table.count(configs[guild.id] or {})) .. " keys configured",
					emoji = (plus and resolvedEmojis.duckyplus) or (configs[guild.id] and resolvedEmojis.success) or resolvedEmojis.fail
				},
				guild = {
					name = sanitizedGuildName,
					id = guild.id
				},
				components = discordia.Components()
					:selectMenu({
						id = "actions",
						placeholder = "Select an action...",
						min_values = 0,
						max_values = 1,
						options = options
					}),
				otherCompCallback = function(ia)
					local id = ia.data.custom_id
					local selections = ia.data.values
					local first = selections and selections[1]

					if id == "actions" then
						ia:replyDeferred(true)
						if first == "invite" then
							if guild.vanityCode and guild.vanityCode ~=	"" then
								return ia:success("**" .. guild.name .. "** has a vanity invite.\n-# " .. emojis.right .. " https://discord.com/invite/" .. guild.vanityCode, nil, true)
							end

							local textChannel = guild.textChannels and guild.textChannels:toArray()[1]

							if textChannel then
								local invite = textChannel:createInvite({
									max_uses = 1,
									unique = true
								})

								if invite and invite.code and invite.code ~= "" then
									return ia:success("A support invite has been created for **" .. guild.name .. "**.\n-# " .. emojis.right .. " https://discord.com/invite/" .. invite.code, nil, true)
								else
									return ia:fail("The invite could not be created.", nil, true)
								end
							else
								return ia:fail("**" .. guild.name .. "** does not have any text channels.", nil, true)
							end
						elseif first == "notify" then
							local dms = guild.owner and guild.owner:getPrivateChannel()

							if dms then
								prompt(ia, "Notify Owner", {
									{
										question = "Notification Text",
										placeholder = "Hi there, {owner.mention}!",
										style = "paragraph",
										required = true
									}
								}, function(mia, responses)
									if mia then
										if responses and responses["Notification Text"] and responses["Notification Text"] ~= "" then
											local success, err = dms:send(parseTable({responses["Notification Text"]}, {
												["owner.name"] = guild.owner.name,
												["owner.username"] = guild.owner.username,
												["owner.id"] = guild.owner.id,
												["owner.mention"] = guild.owner.mentionString,
												["guild.name"] = guild.name,
												["guild.id"] = guild.id,
												["guild.members"] = formatNumber(guild.totalMemberCount)
											})[1])

											if success then
												return mia:success("The owner of **" .. guild.name .. "**, <@" .. tostring(guild.ownerId) .. ">, has been notified.", nil, true)
											else
												return mia:fail("The notificaton could not be sent.", nil, true)
											end
										else
											return mia:fail("You did not provide a notification to send to the owner of **" .. guild.name .. "**, <@" .. tostring(guild.ownerId) .. ">.", nil, true)
										end
									end
								end, true)
							else
								return ia:fail("The owner of **" .. guild.name .. "**, <@" .. tostring(guild.ownerId) .. ">, has their DMs disabled.", nil, true)
							end
						elseif first == "remove" then
							confirm(ia, "Are you sure you would like to remove Ducky from **" .. guild.name .. "**?", function(result, ria, r)
								if result == true then
									local n = guild.name
									guild:leave()
									ria:updateDeferred(true)
									ia:editReply({
										embed = {
											description = emojis.success .. " Ducky has been removed from **" .. n .. "**.",
											color = colors.success
										},
										components = {}
									}, r.id)
									local _, pageNum = currentPage()
									table.remove(pages, pageNum)
									updatePagination(1)
									return true
								else
									ria:updateDeferred(true)
									ia:deleteReply(r.id)
									return true
								end
							end)
						else
							ia:updateDeferred(true)
						end
					end
				end
			})
		end
		
		local options = {clamp = false, teleport = true}

		local query = (sortby and table.remove(args, 1) and table.concat(args, " ")) or table.concat(args, " ")
		
		if query:lower() == "this" then
			query = interaction.guild.id
		elseif query == "" then
			query = nil
		end

		if query then
			for num, page in pairs(pages) do
				if page.guild then
					if page.guild.id == query or page.guild.name:lower():find(query:lower()) then
						options.startPage = num
						break
					end
				end
			end
		end
		
		pagination, updatePagination, currentPage = paginate(interaction, pages, interaction.user, options)
	end
}
