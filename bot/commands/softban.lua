-- softban.lua
local slashCommand = tools.slashCommand("softban", "Softban a member.")
slashCommand = slashCommand:addOption(tools.user("member", "The member to softban."):setRequired(true))
slashCommand = slashCommand:addOption(tools.string("reason", "The reason for the softban."):setRequired(true))
slashCommand = slashCommand:addOption(tools.string("duration", "How far back should the member's messages be deleted?"):setRequired(false))

return {
    name = "softban",
    description = "Softban",
    category = "Moderation",
    slashCommand = slashCommand,
    requiredPermissions = {"ADMIN"},
    hybridCallback = function(interaction, args, slash)
        local member, user = fetchMemberFromInteraction(interaction, args, slash)
        local duration = (slash and args and args.duration and convert(args.duration)) or ((not slash) and args and args[1] and convert(args[1])) or 604800
        local reason = (slash and args and args.reason) or ((not slash) and table.concat(args, " ", 2))

        if (not member) or (not user) then
            return interaction:fail("You did not provide a valid member to softban.", nil, true)
        elseif (not reason) or (reason == "") then
            return interaction:fail("You did not provide a reason for this softban.", nil, true)
        end

        if member and member.highestRole and interaction.member.highestRole and
            (member.highestRole.position >= interaction.member.highestRole.position) then
            return interaction:fail("That user has a role equal to or higher than you.", nil, true)
        end

        local config = sqldb:get(interaction.guild.id) or {}

        if member then
            local moderatable, err = canModerate(interaction.member, member)
            if not moderatable then
                return interaction:fail(err, nil, true)
            end
        end

        local success, err = banMember(interaction.guild, member, user, interaction.member, "softban: " .. reason, true, duration)

        if success then
            local success, err = interaction.guild:unbanUser(user.id, "softbanned")

            if success then
                local violator = member
                local moderator = interaction.member

                local case = db:case(violator, moderator, "Softban", reason, nil, interaction.guild)

                if case then
                    db:send(interaction.guild, "modlogchannel", {
                        embed = {
                            author = author(moderator),
                            thumbnail = thumbnail(violator),
                            title = emojis.ban .. " Member Softbanned",
                            description = getUserString(violator) .. " was softbanned by " .. getUserString(moderator) .. ":\n" ..
                                emojis.right .. " **Reason:** " .. case.reason .. "\n" .. emojis.right .. " **Date:** <t:" .. case.timestamp .. ">\n" ..
                                emojis.right .. " **Messages Deleted:** " .. readable(duration) .. "\n" ..
                                emojis.right .. " **Case ID:** " .. case.caseID,
                            color = colors.fail
                    }
                    })

                    violator:fail("You have been softbanned from **" .. interaction.guild.name .. "** for **" .. reason .. "**.", emojis.ban)
                end

                return interaction:success(getUserString(member) .. " has been softbanned for **" .. reason .. "**.\n-# " .. emojis.right .. " Their messages from the past **" .. readable(duration) .. "** have been purged.\n-# " .. emojis.right .. " **Case ID:** `" .. case.caseID .. "`")
            else
                return interaction:warning(getUserString(member) .. " has been banned and their messages have been deleted, however they were unable to be unbanned.")
            end
        else
            return interaction:fail(err or "An unknown error occurred. Please try again later.", nil, true)
        end
    end
}