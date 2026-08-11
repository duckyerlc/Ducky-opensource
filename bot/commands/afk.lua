-- afk.lua
local slashCommand = tools.slashCommand("afk", "Set your AFK status.")
slashCommand = slashCommand:addOption(tools.string("reason", "The reason for your AFK."):setRequired(false))

return {
	name = "afk",
	description = "Set your AFK status.",
	aliases = {
		"awayfromkeyboard",
		"busy",
		"idle",
		"brb",
		"berightback"
	},
	category = "Utility",
	slashCommand = slashCommand,
	requiredPermissions = {
		"SETUP"
	},
	hybridCallback = function(interaction, args, slash, subcmd)
		local reason = (args and args.reason) or (args and args[1] and args[1] ~= "" and args[1] ~= " " and table.concat(args, " "))

        local config = sqldb:get(interaction.guild.id) or {}
		local userSettings = sqldb:getUserSettings(interaction.user.id) or {}

		if userSettings.afk or table.find(config.afks or {}, function(afk)
            return afk.id == interaction.user.id
        end) then
            return interaction:fail("You already have an active AFK.", nil, true)
		end

		if (not reason or reason == "" or reason == " ") and userSettings.defaultafkreason then
			reason = userSettings.defaultafkreason
		end

		if not reason or reason == "" or reason == " " then
			reason = "AFK"
		end

		reason = string.truncate(reason, 300)
		reason = sanitize(reason, interaction.guild)

		local succ, err

		if not userSettings.globalafk then
			local config = sqldb:get(interaction.guild.id) or {}
			config.afks = config.afks or {}

			table.insert(config.afks, {
				id = interaction.user.id,
				timestamp = os.time(),
				reason = reason
			})
			succ, err = sqldb:set(interaction.guild.id, {
				afks = config.afks
			}, "AFK_SET")
		else
			userSettings.afk = {
				id = interaction.user.id,
				timestamp = os.time(),
				reason = reason
			}

			succ, err = sqldb:setUserSettings(interaction.member.id, userSettings)
		end

		if succ then
			interaction:success("I set your " .. ((userSettings.globalafk and "Global ") or "") .. "AFK: " .. reason .. "")
		else
			interaction:fail(err .. "\n-# " .. emojis.right .. " If this error continues, contact us in the [Ducky support server](https://discord.gg/j4w5ZcbRyh).")
		end
	end
}
