-- feedback.lua
local slashCommand = tools.slashCommand("feedback", "Use the feedback module.")
local subcmd = tools.subCommand("submit", "Give feedback on a staff member.")
subcmd = subcmd:addOption(tools.user("staff", "The staff member to give feedback to."):setRequired(true))
subcmd = subcmd:addOption(tools.string("rating", "The rating for the staff member."):addChoice(tools.choice("⭐", "1")):addChoice(tools.choice("⭐⭐", "2")):addChoice(tools.choice("⭐⭐⭐", "3")):addChoice(tools.choice("⭐⭐⭐⭐", "4")):addChoice(tools.choice("⭐⭐⭐⭐⭐", "5")):setRequired(true))
subcmd = subcmd:addOption(tools.string("feedback", "Why are you giving this rating?"):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("delete", "Delete a feedback via ID.")
subcmd = subcmd:addOption(tools.string("id", "The feedback ID."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("view", "View feedback on a staff member.")
subcmd = subcmd:addOption(tools.user("staff", "The staff member to give feedback to."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)

return {
	name = "feedback",
	description = "Use the feedback module.",
	aliases = {
		"review"
	},
	category = "Staff Management",
	slashCommand = slashCommand,
	subcommands = {
		submit = {
			"rate"
		},
		"view",
		"delete"
	},
	requiredPermissions = {
		"SETUP"
	},
	hybridCallback = function(interaction, args, slash, subcmd)
		if not slash then
			table.remove(args, 1)
		end

		local config = sqldb:get(interaction.guild.id) or {}
		local feedbackChannel = config.feedbackchannel and interaction.guild:getChannel(config.feedbackchannel)

		if (not feedbackChannel) then
			return interaction:fail("Feedback is not enabled in this server.", nil, true)
		end

		if subcmd == "submit" or subcmd == "rate" then
			local staff = fetchMemberFromInteraction(interaction, args, slash, "staff")
			local rating = (slash and args and args.rating) or ((not slash) and args and args[2])
			local feedback = (slash and args and args.feedback) or ((not slash) and args and table.remove(args, 1) and table.remove(args, 1) and table.concat(args, " "))

			if (not staff) then
				return interaction:fail("You did not provide a valid staff member to give feedback on.", nil, true)
			elseif staff.id == interaction.user.id then
				return interaction:fail("You cannot submit feedback on yourself.", nil, true)
			elseif (not rating) or (not tonumber(rating)) or (not starMap[math.floor(tonumber(rating))]) then
				return interaction:fail("You did not provide a valid rating 1-5 for **" .. staff.name .. "**.", nil, true)
			end

			if (not feedback) or (feedback == "") then
				feedback = "N/A"
			end

			local embs = config.feedbackembeds or {
				{
					author = author(interaction.member),
					title = emojis.star .. " Staff Feedback",
					description = emojis.right .. " **Staff Member:** {staff.mention}\n" .. emojis.right .. " **Rating:** {rating.stars}\n" .. emojis.right .. " **Feedback:** {review.feedback}",
					color = colors.info
				}
			}

			embs = parseTable(embs, {
				["submitter.name"] = interaction.member.name,
				["submitter.username"] = interaction.member.username,
				["submitter.id"] = interaction.member.id,
				["submitter.mention"] = interaction.member.mentionString,
				["submitter.avatar"] = interaction.member.avatarURL,
				["staff.name"] = staff.name,
				["staff.username"] = staff.username,
				["staff.id"] = staff.id,
				["staff.mention"] = staff.mentionString,
				["staff.avatar"] = staff.avatarURL,
				["rating.stars"] = starMap[math.floor(tonumber(rating))],
				["rating.number"] = math.floor(tonumber(rating)) .. "/5",
				["review.feedback"] = feedback,
				["timestamp"] = os.time()
			})

			local s, e = feedbackChannel:send({
				content = "-# " .. emojis.pings .. " " .. staff.mentionString,
				embeds = embs
			})

			if s then
				config.feedback = config.feedback or {}

				table.insert(config.feedback, {
					submitter = interaction.user.id,
					staff = staff.id,
					rating = math.floor(tonumber(rating)),
					feedback = feedback,
					id = s.id,
					timestamp = os.time()
				})

				sqldb:set(interaction.guild.id, {
					feedback = config.feedback
				}, "FEEDBACK_SUBMIT")

				return interaction:success("Your feedback on **" .. staff.name .. "** has been submitted successfully.", nil, true)
			else
				return interaction:fail("An error occurred while attempting to submit your feedback. Check Ducky's permissions and try again.\n-# " .. emojis.right .. " " .. e, nil, true)
			end
		elseif subcmd == "view" then
			local staff = fetchMemberFromInteraction(interaction, args, slash, "staff")

			if (not staff) then
				return interaction:fail("You did not provide a valid staff member to view feedback for.", nil, true)
			end

			local allFeedback = config.feedback or {}
			local feedback = {}

			for _, f in pairs(allFeedback) do
				if f.staff == staff.id then
					table.insert(feedback, f)
				end
			end

			table.sort(feedback, function(a, b)
				return a.timestamp > b.timestamp
			end)

			if #feedback <= 0 then
				return interaction:fail(getUserString(staff) .. " has not received any feedback.")
			end

			local average = 0
			for _, f in pairs(feedback) do
				average = average + f.rating
			end
			average = math.round(average / #feedback, 2)

			local pages = {}

			table.insert(pages, {
				title = emojis.star .. " **" .. staff.name .. "**'s Feedback",
				description = emojis.right .. " " .. getUserString(staff) .. " has received a total of **" .. #feedback .. "** ratings with an average rating of " .. emojis.star .. " **" .. average .. "**.",
				color = colors.info,
				author = author(staff)
			})

			local embed = {
				title = emojis.star .. " **" .. staff.name .. "**'s Feedback",
				color = colors.info,
				author = author(staff),
				fields = {}
			}

			for i, f in pairs(feedback) do
				table.insert(embed.fields, {
					name = emojis.star .. " " .. f.rating .. "/5",
					value = emojis.right .. " **Submitter:** <@" .. f.submitter .. ">\n" .. emojis.right .. " **Feedback:** " .. string.truncate(f.feedback, 750) .. "\n" .. emojis.right .. " **Date:** <t:" .. f.timestamp .. ">\n-# " .. emojis.right .. " **ID:** `" .. f.id .. "`",
				})

				if (#embed.fields >= 5) or (i >= #feedback) then
					table.insert(pages, embed)
					embed = {
						title = emojis.star .. " **" .. staff.name .. "**'s Feedback",
						color = colors.info,
						author = author(staff),
						fields = {}
					}
				end
			end

			return paginate(interaction, pages, interaction.user, {
				teleport = true,
				clamp = false
			})
		elseif subcmd == "delete" then
			if not hasPermission(interaction.member, "ERLC_MANAGER", config, interaction) then
				return
			end

			local id = (slash and args and args.id) or ((not slash) and args and args[1])

			if (not id) then
				return interaction:fail("You did not provide a feedback ID to delete.", nil, true)
			end

			local feedbackMessage = feedbackChannel:getMessage(id)
			if feedbackMessage then
				feedbackMessage:delete()
			end

			for i, f in pairs(config.feedback or {}) do
				if f.id == id then
					table.remove(config.feedback, i)
					sqldb:set(interaction.guild.id, {
						feedback = config.feedback
					}, "FEEDBACK_DELETE")
					return interaction:success("That feedback has been successfully deleted.", nil, true)
				end
			end

			return interaction:fail("No feedback was found with that ID.", nil, true)
		end
	end
}
