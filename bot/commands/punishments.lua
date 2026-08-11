-- punishments.lua
local slashCommand = tools.slashCommand("punishments", "Manage Roblox punishment logs.")
local subcmd = tools.subCommand("create", "Create a new punishment log on a player.")
subcmd = subcmd:addOption(tools.string("player", "The Roblox player's username."):setRequired(true):setAutocomplete(true))
subcmd = subcmd:addOption(tools.string("type", "The punishment type to log."):setRequired(true):setAutocomplete(true))
subcmd = subcmd:addOption(tools.string("reason", "The reason for this punishment."):setRequired(true))
subcmd = subcmd:addOption(tools.string("evidence_url", "A URL link to use as evidence for this punishment."):setRequired(false))
subcmd = subcmd:addOption(tools.attachment("evidence_attachment", "An attachment to use as evidence for this punishment."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("view", "View a player's logged punishments.")
subcmd = subcmd:addOption(tools.string("player", "The Roblox player's username."):setRequired(true):setAutocomplete(true))
subcmd = subcmd:addOption(tools.string("type", "The punishment type to use to filter results."):setRequired(false):setAutocomplete(true))
subcmd = subcmd:addOption(tools.string("reason", "The punishment reason to use to filter results."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("manage", "Manage a specific punishment.")
subcmd = subcmd:addOption(tools.string("id", "The punishment's ID."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)

return {
	name = "punishments",
	description = "Manage Roblox punishment logs.",
	aliases = {
		"logs",
		"punishment",
		create = {
			"punish",
			"p"
		}
	},
	category = "Roblox",
	slashCommand = slashCommand,
	requiredPermissions = {
		"SETUP"
	},
	subcommands = {
		create = {
			"new",
			"log"
		},
		view = {
			"list",
			"search"
		},
		manage = {
			"edit",
			"delete",
			"modify"
		}
	},
	autocomplete = function(interaction, command, focused, args)
		local opts = {}
		if (focused) and (focused.name == "type") then
			local config = sqldb:get(interaction.guild.id)

			if config and config.punishmenttypes then
				for i, v in pairs(config.punishmenttypes) do
					if (focused.value and v:lower():find(focused.value:lower())) or (not focused.value) or (focused.value == "") then
						table.insert(opts, {
							name = v,
							value = v
						})
					end
				end
			end
		elseif focused and (focused.name == "player") then
			local config = sqldb:get(interaction.guild.id)

			if config and config.apikey then
                local server = ERLC:getServer(config.apikey)
                
                if server then
                    for _, player in pairs(server._players) do
                        if (focused.value and player.name:lower():find(focused.value:lower())) or not focused.value or (focused.value == "") then
                            table.insert(opts, {
                                name = player.name,
                                value = player.name
                            })
                        end
                    end
                end
			end
		end

		return interaction:autocomplete(opts)
	end,
	hybridCallback = function(interaction, args, slash, subcmd)
		if (not slash) and subcmd then
			table.remove(args, 1)
		end

		local config = sqldb:get(interaction.guild.id) or {}

		if subcmd == "create" or subcmd == "new" or subcmd == "log" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then
				return
			end

			local player = (slash and args and args.player) or ((not slash) and args and args[1]) or nil
			player = ((player and player ~= "") and ropi.SearchUser(player)) or nil
			local pType = (slash and args and args.type) or ((not slash) and args and args[2]) or nil
			pType = pType and table.find(config.punishmenttypes or {}, function(t)
				return t:lower() == pType:lower()
			end)
			local reason = (slash and args and args.reason) or ((not slash) and args and table.concat(table.after(args, 3), " ")) or nil
			local evidence = (slash and args and args.evidence_attachment and args.evidence_attachment.url) or (slash and args and args.evidence_url) or nil

			if not player then
				return interaction:fail("You did not provide a valid player to log this punishment on.", nil, true)
			elseif (not pType) then
				return interaction:fail("You did not provide a valid punishment type.", nil, true)
			elseif (not reason) or (reason == "") then
				return interaction:fail("You did not provide a reason for this punishment.", nil, true)
			elseif not isURL(evidence) then
				evidence = nil
			end

			local punishment = db:punishmentCreate(interaction, interaction.member, player, pType, reason, evidence)

			return interaction:reply({
				embed = {
					title = emojis.success .. " Punishment Logged",
					description = emojis.right .. " You have logged a punishment on **" .. player.hyperlink .. "**.\n" .. emojis.space .. emojis.right .. " **Moderator:** <@" .. punishment.moderator .. ">\n" .. emojis.space .. emojis.right .. " **Player:** " .. player.hyperlink .. "\n" .. emojis.space .. emojis.right .. " **Type:** " .. punishment.type .. "\n" .. emojis.space .. emojis.right .. " **Reason:** " .. punishment.reason .. ((punishment.evidence and "\n" .. emojis.space .. emojis.right .. " **Evidence:** [Attachment](" .. punishment.evidence .. ")") or "") .. ((punishment.expires and "\n" .. emojis.space .. emojis.right .. " **Expires:** <t:" .. punishment.expires .. "> (<t:" .. punishment.expires .. ":R>)") or "") .. "\n" .. emojis.space .. emojis.right .. " **ID:** `" .. punishment.id .. "`",
					color = colors.success,
					thumbnail = player.avatar and {
						url = player.avatar
					},
					author = author(interaction.member),
					image = (punishment.evidence and {
						url = punishment.evidence
					}) or nil
				}
			})
		elseif subcmd == "view" or subcmd == "list" or subcmd == "search" then
			local punishments = config.punishments or {}

			local player = (slash and args and args.player) or ((not slash) and args and args[1]) or nil
			player = ((player and player ~= "") and ropi.SearchUser(player)) or nil
			local pType = (slash and args and args.type) or ((not slash) and args and args[2]) or nil
			pType = pType and table.find(config.punishmenttypes or {}, function(t)
				return t:lower() == pType:lower()
			end)
			local reason = (slash and args and args.reason) or nil

			if not player then
				return interaction:fail("You did not provide a valid player to view punishments for.", nil, true)
			end

			if not hasPermission(interaction.member, "ERLC_STAFF", config) then
				local link = sqldb:getLink(interaction.member.id)
				if not (link and link.roblox and player.id == link.roblox) then
					return hasPermission(interaction.member, "ERLC_STAFF", config, interaction)
				end
			end

			local display = {}

			for _, punishment in pairs(punishments) do
				if punishment.player == player.id then
					local show = true

					if pType and punishment.type ~= pType then
						show = false
					end
					if reason and (not punishment.reason:lower():find(reason:lower())) then
						show = false
					end

					if show then
						table.insert(display, punishment)
					end
				end
			end

			local pages = {}
			local embed

			local function resetEmbed()
				embed = {
					title = emojis.roblox .. " **@" .. player.name .. "**'s Punishments",
					color = colors.info,
					author = {
						name = player.name,
						icon_url = player.avatar
					},
					thumbnail = player.avatar and {
						url = player.avatar
					}
				}
			end

			resetEmbed()

			for i, punishment in pairs(display) do
				embed.fields = embed.fields or {}

				table.insert(embed.fields, {
					name = emojis.moderate .. " Punishment " .. punishment.id,
					value = emojis.right .. " **Moderator:** <@" .. punishment.moderator .. ">\n" .. emojis.right .. " **Player:** " .. player.hyperlink .. "\n" .. emojis.right .. " **Type:** " .. punishment.type .. "\n" .. emojis.right .. " **Reason:** " .. punishment.reason .. ((punishment.evidence and "\n" .. emojis.right .. " **Evidence:** [Attachment](" .. punishment.evidence .. ")") or "") .. "\n" .. emojis.right .. " **Date:** <t:" .. punishment.timestamp .. "> (<t:" .. punishment.timestamp .. ":R>)" .. ((punishment.expires and "\n" .. emojis.right .. " **Expires:** <t:" .. punishment.expires .. "> (<t:" .. punishment.expires .. ":R>)") or "")
				})

				if (#embed.fields > 5) or (i >= #display) then
					table.insert(pages, embed)
					resetEmbed()
				end
			end

			if not next(pages) then
				embed.description = emojis.right .. " No punishments found."
				table.insert(pages, embed)
			end

			return paginate(interaction, pages, interaction.user, {
				teleport = true,
				clamp = false
			})
		elseif subcmd == "manage" or subcmd == "edit" or subcmd == "delete" or subcmd == "modify" then
			if not hasPermission(interaction.member, "ERLC_ADMIN", config, interaction) then
				return
			end

			local punishments = config.punishments or {}

			local punishment = (slash and args and args.id) or ((not slash) and args and args[1]) or nil
			punishment = punishment and table.find(punishments, function(p)
				return p.id == punishment
			end)

			if not punishment then
				return interaction:fail("You did not provide a punishment to manage.", nil, true)
			end

			local player = ropi.GetUser(punishment.player)

			local r = interaction:loading()

			local function updateEmbed()
				if punishment then
					r:update({
						embed = {
							title = emojis.moderate .. " Punishment " .. punishment.id,
							description = emojis.right .. " **Moderator:** <@" .. punishment.moderator .. ">\n" .. emojis.right .. " **Player:** " .. player.hyperlink .. "\n" .. emojis.right .. " **Type:** " .. punishment.type .. "\n" .. emojis.right .. " **Reason:** " .. punishment.reason .. ((punishment.evidence and "\n" .. emojis.right .. " **Evidence:** [Attachment](" .. punishment.evidence .. ")") or "") .. ((punishment.expires and "\n" .. emojis.right .. " **Expires:** <t:" .. punishment.expires .. "> (<t:" .. punishment.expires .. ":R>)") or ""),
							color = colors.info,
							thumbnail = player.avatar and {
								url = player.avatar
							}
						},
						components = discordia.Components():selectMenu({
							placeholder = "Edit this punishment...",
							id = "edit",
							options = {
								{
									label = "Edit Reason",
									value = "reason",
									emoji = resolvedEmojis.edit
								},
								{
									label = "Delete Punishment",
									value = "delete",
									emoji = resolvedEmojis.delete
								}
							},
							actionRow = 1
						})
					})
				else
					r:update({
						embed = {
							description = emojis.delete .. " This punishment has been deleted.",
							color = colors.fail
						},
						components = {}
					})
				end
			end

			updateEmbed()

			onComp(r, nil, nil, interaction.user.id, false, function(ia)
				local id = ia.data.custom_id
				local selections = ia.data.values
				local first = selections and selections[1]

				if id == "edit" then
					if first == "reason" then
						prompt(ia, "Edit Reason", {
							{
								question = "New Reason",
								placeholder = "Enter a new reason for this punishment.",
								default = punishment.reason,
								required = true
							}
						}, function(mia, responses)
							if mia then
								local new = responses and responses["New Reason"]

								if new and new ~= "" and new ~= " " then
									local success, err = db:punishmentEdit(ia.member, punishment.id, new)

									if success then
										punishment = success
										mia:updateDeferred(true)
										updateEmbed()
										return true
									else
										return mia:fail(err, nil, true)
									end
								else
									return mia:fail("You did not provide a reason for this punishment.", nil, true)
								end
							end
						end, false)
					elseif first == "delete" then
						local success, err = db:punishmentDelete(ia.member, punishment.id)

						if success then
							punishment = nil
							updateEmbed()
							return true
						else
							return ia:fail(err, nil, true)
						end
					end
				end
			end)
		end
	end
}
