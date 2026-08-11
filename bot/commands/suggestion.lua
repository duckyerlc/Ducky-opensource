-- suggestion.lua

local slashCommand = tools.slashCommand("suggestion", "Submit and manage suggestions for the current server.")

local subcmd = tools.subCommand("submit", "Submit a suggestion.")
subcmd = subcmd:addOption(tools.string("suggestion", "Your suggestion."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)

local subcmd = tools.subCommand("approve", "Approve a suggestion.")
subcmd = subcmd:addOption(tools.string("id", "The ID of the suggestion."):setRequired(true))
subcmd = subcmd:addOption(tools.string("reason", "The approval reason."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)

local subcmd = tools.subCommand("deny", "Deny a suggestion.")
subcmd = subcmd:addOption(tools.string("id", "The ID of the suggestion."):setRequired(true))
subcmd = subcmd:addOption(tools.string("reason", "The denial reason."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)

local subcmd = tools.subCommand("view", "View a suggestion.")
subcmd = subcmd:addOption(tools.string("id", "The ID of the suggestion."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)

local subcmd = tools.subCommand("list", "List all suggestions.")
slashCommand = slashCommand:addOption(subcmd)

return {
    name = "suggestion",
    description = "Submit and manage suggestions for the current server.",
    aliases = {"suggest", "suggestions"},
    category = "Server Management",
    slashCommand = slashCommand,
    requiredPermissions = {"SETUP"},
	subcommands = {
		"submit",
		"approve",
		"deny",
		"view",
		list = {
			"active",
			"all"
		}
	},
	hybridCallback = function(interaction, args, slash, subcmd)
		local config = sqldb:get(interaction.guild.id) or {}

		if subcmd == "submit" then
			local suggestionText = (slash and args and sanitize(args.suggestion, interaction.guild))
    			or ((not slash) and args and  table.remove(args, 1) and sanitize(table.concat(args, " "), interaction.guild))

			if not config or not config.suggestchannel then
				return interaction:fail("The suggestions channel has not been set in this server.", nil, true)
			elseif (not suggestionText) or (suggestionText == "") then
				return interaction:fail("You must provide a suggestion to submit.", nil, true)
			end

			local suggestchannel = interaction.guild:getChannel(config.suggestchannel)
			if (not suggestchannel) or (not suggestchannel.send) then
				return interaction:fail("The suggestions channel for this server is invalid.", nil, true)
			end

			local suggester = interaction.member
			local suggestionid = interaction.id

			local suggestion = {
				id = suggestionid,
				suggestion = suggestionText,
				upvotes = {},
				downvotes = {},
				submitter = suggester.id,
				approved = nil
			}

			config.suggestions = config.suggestions or {}
			table.insert(config.suggestions, suggestion)
			sqldb:set(interaction.guild.id, { suggestions = config.suggestions }, "SUGGESTION_CREATE")

			local keys = {
				["submitter.name"] = suggester and suggester.name or "N/A",
				["submitter.username"] = suggester and suggester.username or "N/A",
				["submitter.id"] = suggester.id,
				["submitter.mention"] = suggester and suggester.mentionString or ("<@" .. suggester.id .. ">"),
				["submitter.avatar"] = suggester and suggester.avatarURL or "",
				["suggestion.suggestion"] = suggestion.suggestion,
				["suggestion.upvotes"] = tostring(#suggestion.upvotes),
				["suggestion.downvotes"] = tostring(#suggestion.downvotes),
				["suggestion.id"] = tostring(suggestion.id),
			}

			local embeds
			if config.suggestionsubmittedembeds then
				embeds = parseTable(config.suggestionsubmittedembeds, keys)
			else
				embeds = {
					{
						title = emojis.suggestion .. " Suggestion Submitted",
						description = emojis.right ..
							" **Submitter:** " .. suggester.mentionString .. "\n" ..
							emojis.right ..
							" **Suggestion:** " .. suggestion.suggestion .. "\n" ..
							emojis.right ..
							" **Upvotes:** " .. emojis.success .. " " .. tostring(#suggestion.upvotes) .. "\n" ..
							emojis.right ..
							" **Downvotes:** " .. emojis.fail .. " " .. tostring(#suggestion.downvotes) .. "\n" ..
							emojis.right ..
							" **ID:** `" .. suggestion.id .. "`",
						color = colors.info,
						thumbnail = suggester.avatarURL and {
							url = suggester.avatarURL
						} or nil,
						author = {
							name = "@" .. suggester.username,
							icon_url = suggester.avatarURL
						},
					}
				}
			end

			local submitted, e = suggestchannel:send({
				embeds = embeds,
				components = discordia.Components()
					:button({
						id = "upvote_" .. suggestionid,
						emoji = resolvedEmojis.yeswhite,
						style = "success"
					})
					:button({
						id = "downvote_" .. suggestionid,
						emoji = resolvedEmojis.nowhite,
						style = "danger"
					}):raw()
			})

			if submitted then
				interaction:success("Your suggestion has been submitted.\n-# " .. emojis.right .. " " .. submitted.link, nil, true)
				suggestion.message = submitted.id

				if config.suggestionthread then
                    local defaultThreadName = "Suggestion " .. suggestionid .. " ・ " .. suggester.username
					local threadNameTemplate = config.suggestionthread or defaultThreadName
					local parsedThreadName, _ = parseTable({ threadNameTemplate }, keys)

					local finalThreadName = parsedThreadName[1] or defaultThreadName

					local truncatedName = string.truncate(finalThreadName, 100)
					local thread = submitted.channel:startThread(truncatedName, submitted.id)
                end
			else
				interaction:fail("An error occurred while attempting to submit your suggestion. Please try again later.\n-# " .. e:usub(1,16), nil, true)
			end

		elseif subcmd == "approve" then
			if not hasPermission(interaction.member, "MANAGE_SERVER", config, interaction) then
				return
			end

			local suggestionid = ((slash and args and args.id) or args and args[2])
			if not suggestionid then
				return interaction:fail("You must provide a valid suggestion ID.", nil, true)
			end

			if not config.suggestions or #config.suggestions == 0 then
				return interaction:fail("No suggestions exist for this server.", nil, true)
			end

			local suggestion
			for _, s in ipairs(config.suggestions) do
				if tostring(s.id) == suggestionid then
					suggestion = s
					break
				end
			end

			if not suggestion then
				return interaction:fail("No suggestion with that ID could be found.", nil, true)
			end

			if suggestion.approved ~= nil then
				return interaction:fail("This suggestion has already been " .. (suggestion.approved and "approved" or "denied") .. ".", nil, true)
			end

			suggestion.approved = true
			suggestion.approverId = interaction.member.id
			suggestion.approvereason = (slash and args and (args.reason or "No reason provided"))
    			or ((not slash) and args and  (#args > 0 and table.remove(args, 1) and table.remove(args, 1) and table.concat(args, " ") or "No reason provided"))

			local suggester = interaction.guild:getMember(suggestion.submitter)
			local approver = interaction.member

			local keys = {
				["submitter.name"] = suggester and suggester.name or "N/A",
				["submitter.username"] = suggester and suggester.user.username or "N/A",
				["submitter.id"] = suggestion.submitter,
				["submitter.mention"] = suggester and suggester.mentionString or ("<@" .. suggestion.submitter .. ">"),
				["submitter.avatar"] = suggester and suggester.user.avatarURL or "",

				["approver.name"] = approver and approver.name or "N/A",
				["approver.username"] = approver and approver.user.username or "N/A",
				["approver.id"] = approver and approver.id or "N/A",
				["approver.mention"] = approver and approver.mentionString or ("<@" .. approver.id .. ">"),
				["approver.avatar"] = approver and approver.user.avatarURL or "",

				["suggestion.suggestion"] = suggestion.suggestion,
				["suggestion.upvotes"] = tostring(#suggestion.upvotes),
				["suggestion.downvotes"] = tostring(#suggestion.downvotes),
				["suggestion.id"] = tostring(suggestion.id),
				["suggestion.approvereason"] = suggestion.approvereason,
			}

			local embeds
			if config.suggestionapproveembeds then
				embeds = parseTable(config.suggestionapproveembeds, keys)
			else
				embeds = {
					{
						title = emojis.success .. " Suggestion Approved",
						description = emojis.right ..
							" **Submitter:** " .. suggester.mentionString .. "\n" ..
							emojis.right ..
							" **Suggestion:** " .. suggestion.suggestion .. "\n" ..
							emojis.right ..
							" **Upvotes:** " .. emojis.success .. " " .. tostring(#suggestion.upvotes) .. "\n" ..
							emojis.right ..
							" **Downvotes:** " .. emojis.fail .. " " .. tostring(#suggestion.downvotes) .. "\n" ..
							emojis.right .. 
							" **Reason:** " .. suggestion.approvereason .. "\n",
						color = colors.success,
						thumbnail = suggester.avatarURL and {
							url = suggester.avatarURL
						} or nil,
						author = {
							name = "@" .. suggester.username,
							icon_url = suggester.avatarURL
						},
					}
				}
			end

			local suggestchannel = interaction.guild:getChannel(config.suggestchannel)
			if suggestchannel then
				local ok, msg = pcall(function()
					return suggestchannel:getMessage(suggestion.message)
				end)
				if ok and msg then
					msg:update({ embeds = embeds })
				end
			end

			for i, s in ipairs(config.suggestions) do
				if s.id == suggestion.id then
					table.remove(config.suggestions, i)
					break
				end
			end
			sqldb:set(interaction.guild.id, { suggestions = config.suggestions }, "SUGGESTION_APPROVE")
			return interaction:success("Suggestion `" .. suggestion.id .. "` has been approved.", nil, true)

		elseif subcmd == "deny" then
			if not hasPermission(interaction.member, "MANAGE_SERVER", config, interaction) then
				return
			end

			local suggestionid = ((slash and args and  args.id) or args and  args[2])
			if not suggestionid then
				return interaction:fail("You must provide a valid suggestion ID.", nil, true)
			end

			if not config.suggestions or #config.suggestions == 0 then
				return interaction:fail("No suggestions exist for this server.", nil, true)
			end

			local suggestion
			for _, s in ipairs(config.suggestions) do
				if tostring(s.id) == suggestionid then
					suggestion = s
					break
				end
			end

			if not suggestion then
				return interaction:fail("No suggestion with that ID could be found.", nil, true)
			end

			if suggestion.approved ~= nil then
				return interaction:fail("This suggestion has already been " .. (suggestion.approved and "approved" or "denied") .. ".", nil, true)
			end

			suggestion.approved = false
			suggestion.approverId = interaction.member.id
			suggestion.denyreason = (slash and args and  	(args.reason or "No reason provided"))
				or ((not slash) and args and (#args > 0 and table.remove(args, 1) and table.remove(args, 1) and table.concat(args, " ") or "No reason provided"))

			local suggester = interaction.guild:getMember(suggestion.submitter)
			local approver = interaction.member

			local keys = {
				["submitter.name"] = suggester and suggester.name or "N/A",
				["submitter.username"] = suggester and suggester.user.username or "N/A",
				["submitter.id"] = suggestion.submitter,
				["submitter.mention"] = suggester and suggester.mentionString or ("<@" .. suggestion.submitter .. ">"),
				["submitter.avatar"] = suggester and suggester.user.avatarURL or "",

				["denier.name"] = approver and approver.name or "N/A",
				["denier.username"] = approver and approver.user.username or "N/A",
				["denier.id"] = approver and approver.id or "N/A",
				["denier.mention"] = approver and approver.mentionString or ("<@" .. approver.id .. ">"),
				["denier.avatar"] = approver and approver.user.avatarURL or "",

				["suggestion.suggestion"] = suggestion.suggestion,
				["suggestion.upvotes"] = tostring(#suggestion.upvotes),
				["suggestion.downvotes"] = tostring(#suggestion.downvotes),
				["suggestion.id"] = tostring(suggestion.id),
				["suggestion.denyreason"] = suggestion.denyreason,
			}

			local embeds
			if config.suggestiondenyembeds then
				embeds = parseTable(config.suggestiondenyembeds, keys)
			else
				embeds = {
					{
						title = emojis.fail .. " Suggestion Denied",
						description = emojis.right ..
							" **Submitter:** " .. suggester.mentionString .. "\n" ..
							emojis.right ..
							" **Suggestion:** " .. suggestion.suggestion .. "\n" ..
							emojis.right ..
							" **Upvotes:** " .. emojis.success .. " " .. tostring(#suggestion.upvotes) .. "\n" ..
							emojis.right ..
							" **Downvotes:** " .. emojis.fail .. " " .. tostring(#suggestion.downvotes) .. "\n" ..
							emojis.right .. 
							" **Reason:** " .. suggestion.denyreason .. "\n",
						color = colors.fail,
						thumbnail = suggester.avatarURL and {
							url = suggester.avatarURL
						} or nil,
						author = {
							name = "@" .. suggester.username,
							icon_url = suggester.avatarURL
						},
					}
				}
			end

			local suggestchannel = interaction.guild:getChannel(config.suggestchannel)
			if suggestchannel then
				local ok, msg = pcall(function()
					return suggestchannel:getMessage(suggestion.message)
				end)
				if ok and msg then
					msg:update({ embeds = embeds })
				end
			end

			for i, s in ipairs(config.suggestions) do
				if s.id == suggestion.id then
					table.remove(config.suggestions, i)
					break
				end
			end
			sqldb:set(interaction.guild.id, { suggestions = config.suggestions }, "SUGGESTION_DENY")

			return interaction:success("Suggestion `" .. suggestion.id .. "` has been denied.", nil, true)

		elseif subcmd == "view" then
			local suggestionid = ((slash and args and  args.id) or args and  args[2])
			if not suggestionid then
				return interaction:fail("You must provide a valid suggestion ID.", nil, true)
			end

			if not config.suggestions or #config.suggestions == 0 then
				return interaction:fail("No suggestions exist for this server.", nil, true)
			end

			local suggestchannel = interaction.guild:getChannel(config.suggestchannel)
			if (not suggestchannel) or (not suggestchannel.send) then
				return interaction:fail("The suggestions channel for this server is invalid.", nil, true)
			end

			local suggestion
			for _, s in ipairs(config.suggestions) do
				if tostring(s.id) == suggestionid then
					suggestion = s
					break
				end
			end

			if not suggestion or not suggestion.message then
				return interaction:fail("No suggestion with that ID could be found.", nil, true)
			end

			local suggestionLink = "https://discord.com/channels/" .. interaction.guild.id .. "/" .. suggestchannel.id .. "/" .. suggestion.message

			local r = interaction:reply({
				embed = {
					title = emojis.suggestion .. " Suggestion " .. suggestion.id,
					description = emojis.right .. "**Suggestion:** " .. suggestion.suggestion .. "\n" ..
						emojis.right .. " **Suggester:** <@" .. suggestion.submitter .. ">" .. "\n" ..
						emojis.right .. " **Upvotes:** " .. emojis.success .. " " .. #suggestion.upvotes .. "\n" ..
						emojis.right .. " **Downvotes:** " .. emojis.fail .. " " .. #suggestion.downvotes .. "\n" ..
						emojis.right .. " **Suggestion Link:** " .. suggestionLink,
					color = colors.info
				},
				components = discordia.Components()
				:button({
					id = "upvoters",
					label = "Upvoters",
					style = "secondary",
					emoji = resolvedEmojis.success
				})
				:button({
					id = "downvoters",
					label = "Downvoters",
					style = "secondary",
					emoji = resolvedEmojis.fail
				})
				:raw()
			})

			onComp(r, "button", nil, interaction.user.id, false, function(ia)
				local id = ia.data.custom_id

				if id == "upvoters" then
					local upvoters = emojis.right .. " Nobody has voted on this suggestion."

					if suggestion.upvotes and #suggestion.upvotes > 0 then
						local lines = {}
						for _, userId in ipairs(suggestion.upvotes) do
							table.insert(lines, emojis.right .. " <@" .. userId .. ">")
						end
						upvoters = table.concat(lines, "\n")
					end

					ia:reply({
						embed = {
							title = emojis.success .. " Suggestion Upvoters",
							description = upvoters,
							color = colors.success
						}
					}, true)

				elseif id == "downvoters" then
					local downvoters = emojis.right .. " Nobody has voted on this suggestion."

					if suggestion.downvotes and #suggestion.downvotes > 0 then
						local lines = {}
						for _, userId in ipairs(suggestion.downvotes) do
							table.insert(lines, emojis.right .. " <@" .. userId .. ">")
						end
						downvoters = table.concat(lines, "\n")
					end

					ia:reply({
						embed = {
							title = emojis.fail .. " Suggestion Downvoters",
							description = downvoters,
							color = colors.fail
						}
					}, true)
				end
			end)

		elseif subcmd == "list" or subcmd == "active" or subcmd == "all" then
			if not config.suggestions or #config.suggestions == 0 then
				return interaction:fail("No suggestions exist for this server.", nil, true)
			end

			local suggestchannel = interaction.guild:getChannel(config.suggestchannel)
			if (not suggestchannel) or (not suggestchannel.send) then
				return interaction:fail("The suggestions channel for this server is invalid.", nil, true)
			end

			local total = #config.suggestions
			local pages = {}

			local embed = {
				title = emojis.suggestion .. " Suggestions (" .. total .. ")",
				fields = {},
				color = colors.info
			}

			local c = 0
			for _, s in ipairs(config.suggestions) do
				c = c + 1
				local suggestionLink = "https://discord.com/channels/" .. interaction.guild.id .. "/" .. suggestchannel.id .. "/" .. s.id

				table.insert(embed.fields, {
					name = emojis.right .. " **Suggestion " .. s.id .. "**",
					value =
						emojis.space .. emojis.right .. " **Suggestion:** " .. s.suggestion .. "\n" ..
						emojis.space .. emojis.right .. " **Upvotes:** " .. emojis.success .. " " .. #s.upvotes .. "\n" ..
						emojis.space .. emojis.right .. " **Downvotes:** " .. emojis.fail .. " " .. #s.downvotes .. "\n" ..
						emojis.space .. emojis.right .. " **Suggestion Link:** " .. suggestionLink
				})

				if #embed.fields >= 5 or c >= total then
					table.insert(pages, embed)
					embed = {
						title = emojis.suggestion .. " Suggestions (" .. total .. ")",
						fields = {},
						color = colors.info
					}
				end
			end

			return _G.paginate(interaction, pages, interaction.user, {
				teleport = true,
				clamp = false,
				showTotalPages = true
			})
		end
	end
}
