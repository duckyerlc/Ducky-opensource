-- say.lua

local slashCommand = tools.slashCommand("say", "Say a message with Ducky.")
slashCommand = slashCommand:addOption(tools.string("message", "The message to say."):setRequired(true))

return {
    name = "say",
    description = "Say something with Ducky!",
    aliases = {},
    category = "Fun",
    slashCommand = slashCommand,
    requiredPermissions = {},
    hybridCallback = function(interaction, args, slash)
        local content = (slash and args and args.message) or ((not slash) and args and table.concat(args, " "))

        if not content or content == "" or content == " " then
            return interaction:fail("You must provide something to say.", nil, true)
        end

        local cleaned, violate = content, false

        if not hasPermission(interaction.member, "MANAGE_SERVER") then
            cleaned, violate = sanitize(content, interaction.guild)
        end

        if cleaned == "" and violate then
            return interaction:fail("Your message was fully sanitized. Consider removing inappropriate or potentially harmful words/phrases.", nil, true)
        end

        local tosend = {
            content = cleaned,
        }

        local repliedMessage = (not slash and interaction.referencedMessage)

        if (not (interaction.guild.id == duckysPond.id and sqldb:plusMember(interaction.member))) and (not hasPermission(interaction.member, "MANAGE_SERVER")) and (not hasPermission(interaction.member, "BOT_DEVELOPER")) then
            tosend.components = discordia.Components()
                :button({
                    style = "link",
                    url = "https://discord.com/users/" .. interaction.user.id,
                    label = "Sent by " .. string.truncate(interaction.user.username, 30) .. " (" .. interaction.user.id .. ")",
                    emoji = resolvedEmojis.send
                })
                :raw()
        end

		if repliedMessage then
			repliedMessage:reply(tosend)
		else
        	interaction.channel:send(tosend)
		end

        if interaction.updateDeferred then
            interaction:success("Your message has been sent." .. ((violate and ("\n-# " .. emojis.warning .. " Sanitization occurred, meaning one or more words have been removed.")) or ""), nil, true)
        else
            interaction:delete()
        end
    end
}
