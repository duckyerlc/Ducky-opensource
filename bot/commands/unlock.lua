-- unlock.lua
local slashCommand = tools.slashCommand("unlock", "Unlock the current channel.")
slashCommand = slashCommand:addOption(tools.string("reason", "The reason for the channel unlock."):setRequired(false))
slashCommand = slashCommand:addOption(tools.channel("channel", "The channel to unlock."):setRequired(false))

return {
	name = "unlock",
	description = "Unlock the current channel.",
	aliases = {},
	category = "Moderation",
	slashCommand = slashCommand,
	requiredPermissions = {
		"ADMIN"
	},
	hybridCallback = function(interaction, args, slash)
		local channel = (slash and args and args.channel) or (not slash and args and args[1] and interaction.guild:getChannel(args[1]:match("%d+"))) or interaction.channel

	    local reason = (slash and args.reason) or ((not slash) and args and args[1] and not args[1]:match("%d%d%d%d%d+") and table.concat(args, " ") or (not slash) and args and args[2] and table.concat(args, " ", 2))
		reason = (reason ~= "" and reason) or nil


		if channel.type == discordia.enums.channelType.text then
			local everyone = interaction.guild.defaultRole

			local permissionOverwrite = channel:getPermissionOverwriteFor(everyone)
			local locked = permissionOverwrite:getDeniedPermissions():has(discordia.enums.permission.sendMessages)

        if locked then
			permissionOverwrite:allowPermissions(discordia.enums.permission.sendMessages)

			local config = sqldb:get(interaction.guild.id) or {}
			local function clearRole(roleID)
				local role = interaction.guild:getRole(roleID)
				if role then
					local overwrite = channel:getPermissionOverwriteFor(role)
					if overwrite then overwrite:delete() end
				end 	
			end
			for _, roleID in ipairs(config.modroles or {}) do clearRole(roleID) end
			for _, roleID in ipairs(config.adminroles or {}) do clearRole(roleID)end
		else
			return interaction:fail("This channel is not locked.", nil, true)
		end
		elseif channel.type == discordia.enums.channelType.publicThread or channel.type == discordia.enums.channelType.privateThread or channel.type == discordia.enums.channelType.forum then
			local succ, err = channel:unlock()

			if not succ then
				return interaction:fail("Failed to unlock thread: ```" .. err .. "```", nil, true)
			end
		end

		interaction:success(channel.mentionString .. " has been unlocked" .. ((reason and " for **" .. reason .. "**.") or "."))

		
		db:send(interaction.guild, "modlogchannel", {
			embed = {
				title = emojis.unlock .. " Channel Unlocked",
				description = "The " .. channel.mentionString .. " channel was unlocked by " .. getUserString(interaction.user) .. ":\n" .. emojis.right .. " **Reason:** " .. (reason or "N/A") .. "\n" .. emojis.right .. " **Date:** <t:" .. os.time() .. ">",
				color = colors.success
			}
		})
	end
}