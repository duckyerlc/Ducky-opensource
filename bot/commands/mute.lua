-- mute.lua
local slashCommand = tools.slashCommand("mute", "Mute a user.")
local option = tools.user("user", "The user to mute."):setRequired(true)
slashCommand = slashCommand:addOption(option)
local option = tools.string("duration", "The duration to mute the user for."):setRequired(true)
slashCommand = slashCommand:addOption(option)
local option = tools.string("reason", "The reason for the mute."):setRequired(true)
slashCommand = slashCommand:addOption(option)

return {
    name = "mute",
    description = "Mute a user.",
    aliases = {"timeout"},
    category = "Moderation",
    slashCommand = slashCommand,
    requiredPermissions = {"MOD"},
    hybridCallback = function(interaction, args, slash)
        local member = fetchMemberFromInteraction(interaction, args, slash)

        if not member then
            return interaction:fail("You did not provide a member to mute.")
        end

        local duration = (args and args.duration and convert(args.duration)) or (args and args[2] and convert(args[2]))

        if not duration then
            return interaction:fail("You did not provide a valid duration.")
        elseif duration < 1 then
            return interaction:fail("The duration must be at least 1 second.")
        elseif duration > 2419200 then
            return interaction:fail("The duration must be less than 4 weeks.")
        end

        if not slash then
            table.remove(args, 1)
            table.remove(args, 1)
        end

        local reason = (slash and args and args.reason) or
                           ((not slash) and table.concat(args, " ") ~= "" and table.concat(args, " "))

        if not reason then
            return interaction:fail("You did not provide a reason.")
        end
        
        local config = sqldb:get(interaction.guild.id) or {}

        local moderatable, err = canModerate(interaction.member, member)
        if not moderatable then
            return interaction:fail(err, nil, true)
        end

        local muted, err = member:timeoutFor(duration)

        if (not muted) then
            return interaction:fail("I could not mute that user: " .. err:usub(1, 16))
        end

        local case = db:case(member, interaction.member, "Mute", reason, duration)

        if case then
            interaction:success("**" .. member.name .. "** has been muted for **" .. readable(duration) .. "** for **" .. reason .."**.\n-# " .. emojis.right .. " **Case ID:** `" .. case.caseID .. "`")
        else
            return interaction:fail("An unknown error occurred when trying to mute that user. Please try again later.")
        end

        local appealLink = config.appealLinks and config.appealLinks.mute or nil

        if appealLink then
            member:send({
                embed = {
                    description = emojis.timeout .. " You have been muted in **" .. interaction.guild.name .. "** for " ..
                        readable(duration) .. ": **" .. reason .. "**.",
                    color = colors.fail
                },
                components = discordia.Components():button({
                    url = appealLink,
                    style = "link",
                    label = "Appeal Mute",
                    emoji = resolvedEmojis.link
                }):raw()
            })
        else
            member:fail("You have been muted in **" .. interaction.guild.name .. "** for " .. readable(duration) ..
                            ": **" .. reason .. "**.", emojis.timeout)
        end

        db:send(interaction.guild, "modlogchannel", {
            embed = {
                author = author(interaction.member),
                thumbnail = thumbnail(member),
                title = emojis.timeout .. " Member Muted",
                description = getUserString(member) .. " was muted by " .. getUserString(interaction.member) ..
                    " for **" .. readable(duration) .. "**:\n" .. emojis.right .. " **Expires:** <t:" .. (case.timestamp + duration) .. ":R>\n" .. emojis.right .. " **Reason:** " .. case.reason ..
                    "\n" .. emojis.right .. " **Date:** <t:" .. case.timestamp .. ">\n" ..
                    emojis.right .. " **Case ID:** " .. case.caseID,
                color = colors.fail
            }
        })
    end
}