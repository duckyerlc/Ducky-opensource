-- discount.lua
local slashCommand = tools.slashCommand("discount", "Calculate a discounted price in Robux.")
slashCommand = slashCommand:addOption(tools.integer("robux", "The amount of Robux to take the discount from."):setRequired(true))
slashCommand = slashCommand:addOption(tools.integer("discount", "The percentage to discount."):setRequired(true))

return {
    name = "discount",
    description = "Calculate a discounted price in Robux.",
    aliases = {},
    category = "Roblox",
    slashCommand = slashCommand,
    requiredPermissions = {},
    hybridCallback = function(interaction, args, slash)
		local amount = (slash and args and args.robux) or ((not slash) and args and args[1] and tonumber(args[1]))
		local discount = (slash and args and args.discount) or ((not slash) and args and args[2] and tonumber(args[2]))

		if not amount then
			return interaction:fail("You did not provide a valid amount of Robux to discount from.", nil, true)
		elseif not discount then
			return interaction:fail("You did not provide a valid discount percentage.", nil, true)
		end

		amount = math.round(amount)

		local discounted = math.round(amount - ((discount / 100) * amount))

		return interaction:reply({
			embed = {
				title = emojis.roblox .. " Roblox Discount Calculator",
				description = emojis.right .. " **Subtotal:** " .. emojis.robux .. " " .. formatNumber(amount) .. "\n" .. emojis.right .. " **Discount:** " .. discount .. "% off (" .. emojis.robux .. " " .. formatNumber(math.round((discount / 100) * amount)) .. ")\n" .. emojis.right .. " **Discounted:** " .. emojis.robux .. " " .. formatNumber(discounted),
				color = colors.info,
				author = {
					name = interaction.member.name,
					icon_url = interaction.member.avatarURL
				}
			}
		})
    end
}
