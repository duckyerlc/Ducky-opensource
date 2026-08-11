-- tax.lua
local slashCommand = tools.slashCommand("tax", "Calculate tax for Robux.")
slashCommand = slashCommand:addOption(tools.integer("robux", "The amount of robux."):setRequired(true))

return {
	name = "tax",
	description = "Calculate tax for Robux.",
	aliases = {},
	category = "Roblox",
	slashCommand = slashCommand,
	requiredPermissions = {},
	hybridCallback = function(interaction, args, slash)
		local amount = (slash and args and args.robux) or ((not slash) and args and args[1] and tonumber(args[1]))

		if (not amount) then return interaction:fail("You did not provide a valid amount of Robux to calculate tax for.", nil, true) end

		local receive = math.round(math.round(amount) * 0.7)
		local pay = math.round(math.round(amount) * 1.43)

		return interaction:reply({
			embed = {
				title = emojis.roblox .. " Roblox Tax Calculator",
				description = emojis.right .. " To receive " .. emojis.robux .. " **" .. formatNumber(amount) .. "**, you need to be paid " .. emojis.robux .. " **" .. formatNumber(pay) .. "**.\n" .. emojis.right .. " When being paid " .. emojis.robux .. " **" .. formatNumber(amount) .. "**, you will receive " .. emojis.robux .. " **" .. formatNumber(receive) .. "**.",
				color = colors.info,
				author = {
					name = interaction.member.name,
					icon_url = interaction.member.avatarURL
				}
			}
		})
	end
}
