-- lock.lua
local slashCommand = tools.slashCommand("lock", "Lock the current channel.")
slashCommand = slashCommand:addOption(tools.string("reason", "The reason for the channel lock."):setRequired(false))
slashCommand = slashCommand:addOption(tools.channel("channel", "The channel to lock."):setRequired(false))
return {
	name = "lock",
	description = "Lock the current channel.",
	aliases = {},
	category = "Moderation",
	slashCommand = slashCommand,
	requiredPermissions = {
		"ADMIN"
	},
	hybridCallback = function(interaction, args, slash)
		local channel = (slash and args and args.channel) or (not slash and args and args[1] and interaction.guild:getChannel(args[1]:match("%d+"))) or interaction.channel
		local reason = (slash and args and args.reason) or ((not slash) and args and args[1] and not args[1]:match("%d%d%d%d%d+") and table.concat(args, " ") or (not slash) and args and args[2] and table.concat(args, " ", 2))
		reason = (reason ~= "" and reason) or nil

		if channel.type == discordia.enums.channelType.text then
			local everyone = interaction.guild.defaultRole

			local permissionOverwrite = channel:getPermissionOverwriteFor(everyone)
			local locked = permissionOverwrite:getDeniedPermissions():has(discordia.enums.permission.sendMessages)

        if not locked then
			permissionOverwrite:denyPermissions(discordia.enums.permission.sendMessages)

			local config = sqldb:get(interaction.guild.id) or {}

			for _, roleID in ipairs(config.modroles or {}) do
				local role = interaction.guild:getRole(roleID)
				if role then
					channel:getPermissionOverwriteFor(role):allowPermissions(discordia.enums.permission.sendMessages)
				end
			end
			for _, roleID in ipairs(config.adminroles or {}) do
				local role = interaction.guild:getRole(roleID)
				if role then
					channel:getPermissionOverwriteFor(role):allowPermissions(discordia.enums.permission.sendMessages)
				end
			end
		else 
			return interaction:fail("This channel is already locked.", nil, true)
		end
		elseif channel.type == discordia.enums.channelType.publicThread or channel.type == discordia.enums.channelType.privateThread or channel.type == discordia.enums.channelType.forum then
			local succ, err = channel:lock()

			if not succ then
				return interaction:fail("Failed to lock thread: ```" .. err .. "```", nil, true)
			end
		end

		interaction:success(channel.mentionString .. " has been locked" .. ((reason and " for **" .. reason .. "**.") or "."))

		db:send(interaction.guild, "modlogchannel", {
			embed = {
				title = emojis.lock .. " Channel Locked",
				description = "The " .. channel.mentionString .. " channel was locked by " .. getUserString(interaction.user) .. ":\n" .. emojis.right .. " **Reason:** " .. (reason or "N/A") .. "\n" .. emojis.right .. " **Date:** <t:" .. os.time() .. ">",
				color = colors.fail
			}
		})
	end
}
