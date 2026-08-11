-- unmute.lua
local slashCommand = tools.slashCommand("unmute", "Unmute a user.")
local option = tools.user("user", "The user to unmute."):setRequired(true)
slashCommand = slashCommand:addOption(option)
local option = tools.string("reason", "The reason for the unmute."):setRequired(false)
slashCommand = slashCommand:addOption(option)

return {
    name = "unmute",
    description = "Unmute a user.",
    aliases = { "untimeout" },
    category = "Moderation",
    slashCommand = slashCommand,
    requiredPermissions = { "MOD" },
    hybridCallback = function(interaction, args, slash)
        local member = fetchMemberFromInteraction(interaction, args, slash)

        local reason = (args and args.reason) or ((not slash) and table.remove(args, 1) and table.concat(args, " "))

        if reason == "" or reason == " " then
            reason = nil
        end

        if not member then
            return interaction:fail("You did not provide a member to unmute.")
        end

        if not member.timedOut then
            return interaction:fail("**" .. member.name .. "** is not muted.")
        end

        local unmuted, err = member:removeTimeout()

        if (not unmuted) then
            return interaction:fail("I could not unmute that user: " .. tostring(err))
        end

        interaction:success(getUserString(member) ..
        " has been unmuted" .. (reason and " for **" .. reason .. "**" or "") .. ".")
        member:success("You have been unmuted in **" .. interaction.guild.name .. "**" .. (reason and " for **" .. reason .. "**" or "") .. ".")

        db:send(interaction.guild, "modlogchannel", {
            embed = {
                author = author(interaction.member),
                thumbnail = (member.avatarURL and {
                    url = member.avatarURL
                }) or (member.defaultAvatarURL and {
                    url = member.defaultAvatarURL
                }),
                title = emojis.success .. " Member Unmuted",
                description = getUserString(member) .. " was unmuted by " .. getUserString(interaction.member) .. ":\n"
                    .. emojis.right .. " **Reason:** " .. (reason or emojis.fail) .. "\n"
                    .. emojis.right .. " **Date:** <t:" .. os.time() .. ">",
                color = colors.success
            }
        })
    end
}
