-- warn.lua
local slashCommand = tools.slashCommand("warn", "Warn a user.")
local option = tools.user("user", "The user to warn."):setRequired(true)
slashCommand = slashCommand:addOption(option)
local option = tools.string("reason", "The reason for the warn."):setRequired(true)
slashCommand = slashCommand:addOption(option)

return {
	name = "warn",
	description = "Warn a user.",
	aliases = {},
	category = "Moderation",
	slashCommand = slashCommand,
	requiredPermissions = {
		"MOD"
	},
	hybridCallback = function(interaction, args, slash)
		local member = fetchMemberFromInteraction(interaction, args, slash)

		if not member then
			return interaction:fail("You did not provide a member to warn.")
		end

		local reason = (slash and args and args.reason) or ((not slash) and table.remove(args, 1) and table.concat(args, " ") ~= "" and table.concat(args, " "))

		if not reason then
			return interaction:fail("You did not provide a reason.")
		end

		local config = sqldb:get(interaction.guild.id) or {}

		local moderatable, err = canModerate(interaction.member, member)
        if not moderatable then
            return interaction:fail(err)
        end

		local case = db:case(member, interaction.member, "Warning", reason)

		if case then
			interaction:success(getUserString(member) .. " has been warned for **" .. reason .. "**.\n-# " .. emojis.right .. " **Case ID:** `" .. case.caseID .. "`")
		else
			return interaction:fail("An unknown error occurred when trying to warn that user. Please try again later.")
		end

		local appealLink = config.appealLinks and config.appealLinks.warning or nil

		if appealLink then
			member:send({
				embed = {
					description = emojis.warning .. " You have been warned in **" .. interaction.guild.name .. "** for **" .. reason .. "**.",
					color = colors.warning
				},
				components = discordia.Components():button({
					url = appealLink,
					style = "link",
					label = "Appeal Warning",
					emoji = resolvedEmojis.link
				}):raw()
			})
		else
			member:warning("You have been warned in **" .. interaction.guild.name .. "** for **" .. reason .. "**.")
		end

		db:send(interaction.guild, "modlogchannel", {
			embed = {
				author = author(interaction.member),
				thumbnail = thumbnail(member),
				title = emojis.warning .. " Member Warned",
				description = getUserString(member) .. " was warned by " .. getUserString(interaction.member) .. ":\n" .. emojis.right .. " **Reason:** " .. case.reason .. "\n" .. emojis.right .. " **Date:** <t:" .. case.timestamp .. ">\n" .. emojis.right .. " **Case ID:** " .. case.caseID,
				color = colors.warning
			}
		})
	end
}
