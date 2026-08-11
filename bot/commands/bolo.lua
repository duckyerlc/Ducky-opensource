-- bolo.lua
local slashCommand = tools.slashCommand("bolo", "Manage BOLOs/ban requests.")
local subCommand = tools.subCommand("create", "Create a new BOLO.")
subCommand = subCommand:addOption(tools.string("username", "The username of the Roblox user you are BOLOing."):setRequired(true))
subCommand = subCommand:addOption(tools.string("reason", "The reason for this BOLO."):setRequired(true))
subCommand = subCommand:addOption(tools.string("evidence_url", "A URL link to use as evidence for this BOLO."):setRequired(false))
subCommand = subCommand:addOption(tools.attachment("evidence_attachment", "An attachment to use as evidence for this BOLO."):setRequired(false))

slashCommand = slashCommand:addOption(subCommand)
local subCommand = tools.subCommand("pending", "View and approve/deny pending BOLO requests.")
slashCommand = slashCommand:addOption(subCommand)

return {
	name = "bolo",
	description = "Manage BOLOs/ban requests.",
	aliases = {
		"banrequests"
	},
	category = "Roblox",
	slashCommand = slashCommand,
	subcommands = {
		"create",
		pending = {
			"active"
		}
	},
	requiredPermissions = {
		"ERLC_STAFF",
		"SETUP"
	},
	hybridCallback = function(interaction, args, slash, subcmd)
		if (not slash) then
			table.remove(args, 1)
		end

		local config = sqldb:get(interaction.guild.id) or {}

		if subcmd == "create" then
			local username = (slash and args and args.username) or ((not slash) and args and args[1] and args[1] ~= "" and args[1])
			local evidence = (slash and args and args.evidence_attachment and args.evidence_attachment.url) or (slash and args and args.evidence_url) or nil
			local reason = (slash and args and args.reason) or ((not slash) and args and args[2] and args[2] ~= "" and table.concat(args, " ", 2))

			if not username then
				return interaction:fail("You did not provide a player.", nil, true)
			elseif not reason then
				return interaction:fail("You did not provide a reason.", nil, true)
			elseif not isURL(evidence) then
				evidence = nil
			end

			local player = ropi.SearchUser(username)
			if not player then
				return interaction:fail("That player was not found.", nil, true)
			end

			local success, err = db:createBOLO(player, reason, interaction.member, evidence, nil, interaction)
			if not success then
				return interaction:fail(err, nil, true)
			end

			return interaction:reply({
				embed = {
					title = emojis.success .. " BOLO Created",
					description = "> " .. player.hyperlink .. " has received a **BOLO** for **" .. reason .. "** and is awaiting approval." .. ((evidence and "\n" .. emojis.right .. " **Evidence:** [Attachment](" .. evidence .. ")") or ""),
					thumbnail = (player.avatar and {
						url = player.avatar
					}) or nil,
					color = colors.success,
					image = (evidence and {
						url = evidence
					}) or nil
				}
			})
		elseif subcmd == "pending" or subcmd == "active" then
			if not hasPermission(interaction.member, "ERLC_ADMIN", config, interaction) then return end
			local pages = {}

			local pagination = nil

			local userIds = {}

			for i, bolo in pairs(config.bolos or {}) do
				table.insert(userIds, bolo.user)
			end

			local users, error = ropi.GetUsers(userIds, {avatars = true, dictionary = true, fillUnknown = true})

			if type(users) ~= "table" or error then
				return interaction:fail("Failed to get Roblox user data: " .. (error or "no error provided."), nil, true)
			end

			for i, bolo in pairs(config.bolos or {}) do
				local robloxUser = users[bolo.user]

				table.insert(pages, {
					title = emojis.moderate .. " " .. robloxUser.name .. " (`" .. robloxUser.id .. "`)",
					description = emojis.right .. " **Moderator:** <@" .. bolo.moderator .. ">\n" .. emojis.right .. " **Reason:** " .. bolo.reason .. "\n" .. emojis.right .. " **Date:** <t:" .. bolo.created .. ">" .. ((bolo.evidence and "\n" .. emojis.right .. " **Evidence:** [Attachment](" .. bolo.evidence .. ")") or ""),
					color = colors.info,
					thumbnail = (robloxUser.avatar and {
						url = robloxUser.avatar
					}) or nil,
					image = (bolo.evidence and {
						url = bolo.evidence
					}) or nil,
					components = discordia.Components():button({
						id = "approve",
						emoji = resolvedEmojis.yeswhite,
						style = "success"
					}):button({
						id = "deny",
						emoji = resolvedEmojis.nowhite,
						style = "danger"
					}),
					otherCompCallback = function(ia)
						local id = ia.data.custom_id

						if id == "approve" then
							local success, response, warn = db:completeBOLO(robloxUser, ia.member)
							if not success then
								return ia:fail(response, nil, true)
							end
							if warn then
								ia:warning(response, nil, true)
							else
								ia:success(response, nil, true)
							end

							pages[i].components = nil
							pages[i].title = robloxUser.name .. " (`" .. robloxUser.id .. "`)"
							pages[i].description = emojis.success .. " This BOLO has been completed."
							pages[i].color = colors.success
							local cs = pagination.components
							table.remove(cs, 1)

							pagination:update({
								embed = {
									title = emojis.success .. " " .. robloxUser.name .. " (`" .. robloxUser.id .. "`)",
									description = emojis.success .. " This BOLO has been completed.",
									color = colors.success,
									thumbnail = (robloxUser.avatar and {
										url = robloxUser.avatar
									}) or nil
								},
								components = cs
							})
						elseif id == "deny" then
							local s, e = db:denyBOLO(robloxUser, ia.member)
							if s then
								pages[i].components = nil
								pages[i].title = robloxUser.name .. " (`" .. robloxUser.id .. "`)"
								pages[i].description = emojis.fail .. " This BOLO has been denied."
								pages[i].color = colors.fail
								local cs = pagination.components
								table.remove(cs, 1)
								ia:update({
									embed = {
										title = emojis.fail .. " " .. robloxUser.name .. " (`" .. robloxUser.id .. "`)",
										description = emojis.fail .. " This BOLO has been denied.",
										color = colors.fail,
										thumbnail = {
											url = robloxUser.avatar
										}
									},
									components = cs
								})
							else
								ia:fail(e, nil, true)
							end
						end
					end
				})
			end

			if not next(config.bolos or {}) then
				return interaction:fail("There are no active BOLOs.", nil, true)
			end

			pagination = _G.paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		end
	end
}
