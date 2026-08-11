-- modlogs.lua

local useroption = tools.user("user", "The user to view modlogs for."):setRequired(false)
local slashCommand = tools.slashCommand("modlogs", "View the modlogs for the given user.")
slashCommand = slashCommand:addOption(useroption)

local actions = discordia.Components():selectMenu({
    id = "actionSelector",
    placeholder = "Select an action...",
	min_values = 0,
	max_values = 1,
    actionRow = 1,
    options = {
		{
			label = "Void All Cases",
			value = "voidCases",
			emoji = resolvedEmojis.delete
    	},
	}
})

return {
    name = "modlogs",
    description = "View the modlogs for the given user.",
    aliases = {"cases", "ml"},
    category = "Moderation",
	requiredPermissions = {"MOD", "SETUP"},
    slashCommand = slashCommand,
    hybridCallback = function(interaction, args, slash)
		local member, user = fetchMemberFromInteraction(interaction, args, slash)
		local config = sqldb:get(interaction.guild.id) or {}
		local modlogs = table.values(config.cases or {})

		table.sort(modlogs, function(a, b)
			return a.timestamp > b.timestamp
		end)
		
		if user then
			local cases = {}

			for _, modlog in pairs(modlogs) do
				if modlog.member == user.id then
					table.insert(cases, modlog)
				end
			end
			
			if #cases <= 0 then
				return interaction:fail("**" .. user.name .. "** has no modlogs.")
			end

			local pages = {
				{
					title = emojis.moderate .. " " ..  user.name .. "'s Modlogs",
					description = "> **@" .. user.username ..  "** has a total of **" .. #cases .. " " .. ((#cases > 1 and "modlogs**") or "modlog**") .. ".",
					color = colors.info,
					author = author(user),
					components = actions,
					otherCompCallback = function(ia)
						local id = ia.data.custom_id
						local selections = ia.data.values
						local first = selections and selections[1]

						if id == "actionSelector" then
							if first == "voidCases" then
								confirm(ia, "Are you sure you want to void all cases for " .. getUserString(member) .. "?", function(confirm, ria)
									if confirm then
										for caseID, modlog in pairs(modlogs) do
											if modlog.member == user.id then
												modlogs[caseID] = nil
											end
										end

										local succ, err = pcall(function()
											sqldb:set(interaction.guild.id, {
												cases = modlogs
											}, "VOID_CASES")
										end)

										if succ then
											db:send(interaction.guild, "modlogchannel", {
												embed = {
													title = emojis.delete .. " Cases Voided",
													description = "All modlogs for " .. getUserString(user) .. " have been voided by " .. getUserString(interaction.user) .. ".",
													color = colors.fail,
												}
											})

											ria:success("Successfully voided all cases for " .. getUserString(user) .. ".", nil, true)
										else
											ria:fail((type(err) == "string" and err) or "An unknown error occurred while voiding cases.", nil, true)
										end
									end
								end, true, false)
							else
								ia:updateDeferred(true)
							end
						end
					end
				}
			}
			local emb = {
				title = emojis.moderate .. " " .. user.name .. "'s Modlogs (" .. #cases .. ")",
				color = colors.info,
				fields = {},
				author = author(user)
			}
			
			for i, modlog in pairs(cases) do
				table.insert(emb.fields, {
					name = "Case " .. modlog.caseID,
					value = emojis.right .. " **Moderator:** <@" .. modlog.moderator .. ">\n" .. emojis.right .. " **Type:** " .. modlog.type .. ((modlog.length and (" (" .. readable(modlog.length) .. ")")) or "") .. "\n" .. emojis.right .. " **Reason:** " .. modlog.reason .. "\n" .. emojis.right .. " **Date:** <t:" .. modlog.timestamp .. ">"
				})
				
				if #emb.fields >= 3 or i >= #cases then
					table.insert(pages, emb)
					emb = {
						title = emojis.moderate .. " " .. user.name .. "'s Modlogs (" .. #cases .. ")",
						color = colors.info,
						fields = {},
						author = author(user)
					}
				end
			end
			
			return _G.paginate(interaction, pages, interaction.user, {clamp = false, teleport = true})
		elseif (not slash) and (args and args[1]) then
			interaction:fail("I could not find that user.")
		else
			if #modlogs <= 0 then
				return interaction:fail("This server has no modlogs.")
			end

			local pages = {}
			local emb = {
				title = "All Modlogs (" .. #modlogs .. ")",
				color = colors.info,
				fields = {},
				author = author(interaction.guild)
			}
			
			for i, modlog in pairs(modlogs) do
				table.insert(emb.fields, {
					name = "Case " .. modlog.caseID,
					value = emojis.right .. " **Member:** <@" .. modlog.member .. ">\n" .. emojis.right .. " **Moderator:** <@" .. modlog.moderator .. ">\n" .. emojis.right .. " **Type:** " .. modlog.type .. ((modlog.length and (" (" .. readable(modlog.length) .. ")")) or "") .. "\n" .. emojis.right .. " **Reason:** " .. modlog.reason .. "\n" .. emojis.right .. " **Date:** <t:" .. modlog.timestamp .. ">"
				})
				
				if #emb.fields >= 3 then
					table.insert(pages, emb)
					emb = {
						title = "All Modlogs (" .. #modlogs .. ")",
						color = colors.info,
						fields = {},
						author = author(interaction.guild)
					}
				elseif i >= #modlogs then
					table.insert(pages, emb)
				end
			end
			
			return _G.paginate(interaction, pages, interaction.user, {clamp = false, teleport = true})
		end
	end
}