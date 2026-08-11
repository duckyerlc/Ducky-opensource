-- promotion.lua
local slashCommand = tools.slashCommand("promotion", "Manage a staff member's promotions.")

local subcmd = tools.subCommand("issue", "Issue a promotion.")
subcmd = subcmd:addOption(tools.user("user", "The user to promote."):setRequired(true))
subcmd = subcmd:addOption(tools.role("rank", "The new role/rank for the user."):setRequired(true))
subcmd = subcmd:addOption(tools.string("reason", "The reason for this promotion."):setRequired(true))
subcmd = subcmd:addOption(tools.string("notes", "Notes for this promotion."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)

local subcmd = tools.subCommand("list", "View the promotion list of a user.")
subcmd = subcmd:addOption(tools.user("user", "The user to view the promotion list of."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)

return {
	name = "promotion",
	description = "Manage a staff member's promotions.",
	aliases = {
		"promotion",
		"promotions"
	},
	category = "Staff Management",
	slashCommand = slashCommand,
	requiredPermissions = {
		"ERLC_MANAGER"
	},
	subcommands = {
		"issue",
		"list"
	},
	hybridCallback = function(interaction, args, slash, subcmd)
		if (not slash) and subcmd then
			table.remove(args, 1)
		end
		local config = sqldb:get(interaction.guild.id) or {}

		if subcmd == "issue" then
			local receiver = args.user or fetchMemberFromInteraction(interaction, args, slash)
			local promoter = interaction.member
			local notes = args.notes or "N/A"

			local newrankArg = (slash and args.rank) or args[2]
			if not newrankArg then
				return interaction:fail("You must provide a new rank.", nil, true)
			end

			local newrank
			if slash then
				newrank = newrankArg
			else
				local inputId = newrankArg:match("<@&(%d+)>") or newrankArg:match("^(%d+)$")

				if inputId then
					newrank = interaction.guild:getRole(inputId)
				else
					for _, role in pairs(interaction.guild.roles) do
						if role.name:lower() == newrankArg:lower() then
							newrank = role
							break
						end
					end

					if not newrank then
						for _, role in pairs(interaction.guild.roles) do
							if role.name:lower():find(newrankArg:lower(), 1, true) then
								newrank = role
								break
							end
						end
					end
				end
			end

			local reason = (slash and args.reason) or ((not slash) and table.remove(args, 1) and table.remove(args, 1) and table.concat(args, " "))

			if not receiver or class(receiver) ~= "Member" then
				return interaction:fail("You did not provide a member to promote.", nil, true)
			elseif not newrank or class(newrank) ~= "Role" then
				return interaction:fail("I could not find that rank.", nil, true)
			elseif (not reason) or (reason == "") then
				return interaction:fail("You must provide a reason for this promotion.", nil, true)
			elseif newrank.position >= interaction.member.highestRole.position then
				return interaction:fail("You cannot promote someone to a rank higher than or equal to your highest role.", nil, true)
			end

			local promotion = {
				id = table.count(config.promotions or {}) + 1,
				user = receiver.id,
				rank = newrank.id,
				reason = reason,
				notes = notes,
				promoter = promoter.id,
				timestamp = os.time(),
				msg = nil,
				thread = nil
			}

			local succ, result = canManageRole(newrank)
			if succ then
				if class(receiver) == "Member" and receiver.addRole then
					receiver:addRole(newrank.id, "received promotion, ID: " .. tostring(promotion.id))
				end
			else
				return interaction:fail(result or "I cannot manage that role.", nil, true)
			end

			config.promotions = config.promotions or {}

			local keys = {
				["receiver.mention"] = receiver.mentionString,
				["receiver.name"] = receiver.name,
				["receiver.username"] = receiver.username,
				["receiver.id"] = receiver.id,
				["receiver.avatar"] = receiver.avatarURL,
				["promoter.mention"] = promoter.mentionString,
				["promoter.name"] = promoter.name,
				["promoter.username"] = promoter.username,
				["promoter.id"] = promoter.id,
				["promoter.avatar"] = promoter.avatarURL,
				["newrank.name"] = newrank.name,
				["newrank.id"] = newrank.id,
				["newrank.mention"] = newrank.mentionString,
				["promotion.reason"] = reason,
				["promotion.notes"] = notes,
				["timestamp"] = tostring(os.time())
			}

			local tosend = parseTable({
				content = "-# " .. emojis.pings .. " " .. receiver.mentionString,
				embeds = config.promotionembeds or {
					{
						title = "Staff Promotion",
						description = emojis.right .. " **Staff Member:** {receiver.mention}\n" .. emojis.right .. " **New Rank:** {newrank.mention}\n" .. emojis.right .. " **Reason:** {promotion.reason}\n" .. emojis.right .. " **Notes:** {promotion.notes}",
						color = colors.yellow
					}
				}
			}, keys)

			local msg = db:send(interaction.guild.id, "promotionschannel", tosend, nil, true)

			if msg and msg.id then
				promotion.msg = msg.id

				if config.promotionsthread then
					local threadNameTemplate = config.promotionsthread
					local parsedThreadName, _ = parseTable({ threadNameTemplate }, keys)

					local finalThreadName = parsedThreadName[1]

					local truncatedName = string.truncate(finalThreadName, 100)
					local thread = msg.channel:startThread(truncatedName, msg.id)

					promotion.thread = thread.id
				end
			end

			table.insert(config.promotions, promotion)
			sqldb:set(interaction.guild.id, {promotions = config.promotions}, "PROMOTION_ISSUE")

			return interaction:success("**" .. receiver.name .. "** has been promoted to " .. newrank.mentionString .. ".")
		elseif subcmd == "list" then
			local member = args.user or interaction.member
			local promotions = {}

			for _, v in pairs(config.promotions or {}) do
				if v.user == member.id then
					table.insert(promotions, v)
				end
			end

			if table.count(promotions) <= 0 then
				return interaction:fail("**" .. member.name .. "** has no promotions.", nil, true)
			end

			table.sort(promotions, function(a, b)
				return a.timestamp > b.timestamp
			end)

			local pages = {}
			local emb = {
				author = {
					name = "@" .. member.user.username,
					icon_url = member.user.avatarURL
				},
				title = member.name .. "'s Promotions",
				color = colors.yellow,
				fields = {}
			}

			for i, promotion in pairs(promotions) do
				local rank = interaction.guild:getRole(promotion.rank)
				table.insert(emb.fields, {
					name = "Promotion #" .. promotion.id,
					value = emojis.right .. " **Promoter:** <@" .. promotion.promoter .. ">\n" .. emojis.right .. " **New Rank:** " .. (rank and rank.mentionString or "`Unknown Role`") .. "\n" .. emojis.right .. " **Reason:** " .. promotion.reason .. "\n" .. emojis.right .. " **Notes:** " .. promotion.notes .. "\n" .. emojis.right .. " **Date:** <t:" .. promotion.timestamp .. ":f>"
				})

				if table.count(emb.fields) == 5 or i == table.count(promotions) then
					table.insert(pages, emb)
					emb = {
						author = {
							name = "@" .. member.user.username,
							icon_url = member.user.avatarURL
						},
						title = member.name .. "'s Promotions",
						color = colors.yellow,
						fields = {}
					}
				end
			end

			return paginate(interaction, pages, interaction.user, {
				teleport = true,
				showTotalPages = true,
				clamp = false
			})
		end
	end
}
