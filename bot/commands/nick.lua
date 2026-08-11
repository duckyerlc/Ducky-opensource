-- nick.lua

local slashCommand = tools.slashCommand("nick", "Set the nickname of the given user.")
slashCommand = slashCommand:addOption(tools.user("user", "The user to change nickname of."):setRequired(true))
slashCommand = slashCommand:addOption(tools.string("nickname", "The nickname to set the user to have."):setRequired(false))

return {
    name = "nick",
    description = "Set the nickname of the given user.",
    aliases = {"nickname"},
    category = "Server Management",
    slashCommand = slashCommand,
    requiredPermissions = {"MOD"},
    hybridCallback = function(interaction, args, slash)
        local member = fetchMemberFromInteraction(interaction, args, slash)

        if not member then
            return interaction:fail("You did not provide a member to change the nickname of.", nil, true)
        end

        local previous = tostring(member.name) .. ""
        if (not previous) or (previous == "") or (previous == "nil") then
            previous = nil
        end

        local nickname = (slash and args and args.nickname) or ((not slash) and args and table.remove(args, 1) and table.concat(args, " "))

        if nickname == "" then nickname = nil end

        local changed, err = member:setNickname(nickname)

        if changed and nickname then
            interaction:success("**@" .. member.username .. "**'s nickname has been set to **" .. nickname .. "**.")
        elseif changed and (not nickname) then
            interaction:success("**@" .. member.username .. "**'s nickname has been reset to **" .. member.name .. "**.")
        elseif (not changed) then
            local code = err:match("(%d+)")
            return interaction:fail((code and errCodes[tonumber(code)]) or err, nil, true)
        end
 
        db:send(interaction.guild, "modlogchannel", {
            embed = {
                title = emojis.edit .. " Member Nickname Changed",
                description = "**@" .. member.username .. "**'s nickname was " .. ((nickname and "changed") or "reset") .. " by **" .. interaction.member.name .. "**:\n" .. emojis.right .. " **Previous Nickname:** " .. (previous or member.name) .. "\n" .. emojis.right .. " **New Nickname:** " .. (nickname or member.name) .. "\n" .. emojis.right .. " **Date:** <t:" .. os.time() .. ">",
                color = colors.success
            }
        })
    end
}