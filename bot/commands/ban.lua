-- ban.lua
local slashCommand = tools.slashCommand("ban", "Ban a user.")
local option = tools.user("user", "The user to ban."):setRequired(true)
slashCommand = slashCommand:addOption(option)
local option = tools.string("reason", "The reason for the ban."):setRequired(true)
slashCommand = slashCommand:addOption(option)
local option = tools.boolean("departmental",
    "Whether or not to ban this user from all of this server's departments as well."):setRequired(false)
slashCommand = slashCommand:addOption(option)

local function banMember(guild, violatorMember, violator, moderator, reason, nocase, seconds)
    if violatorMember and violatorMember.highestRole and moderator.highestRole and
        (violatorMember.highestRole.position >= moderator.highestRole.position) then
        return nil, "That user has a role equal to or higher than you."
    end

    local config = sqldb:get(guild.id) or {}

    if violatorMember then
        local moderatable, err = canModerate(moderator, violatorMember)
        if not moderatable then
            return false, err
        end
    end

    local deleteSeconds = (seconds and tonumber(seconds) and math.min(tonumber(seconds), 604800)) or 0

    local success, err = guild:banUser(violator.id, reason, deleteSeconds)
    if not success then
        return nil, "Failed to ban " .. getUserString(violator) .. ": " .. tostring(err):usub(20)
    end

    if not nocase then
        local case = db:case(violator, moderator, "Ban", reason, nil, guild)

        if case then
            local config = sqldb:get(guild.id) or {}

            local appealLink = config.appealLinks and config.appealLinks.ban or nil

            if appealLink and violatorMember then
                violator:send({
                    embed = {
                        description = emojis.ban .. " You have been banned from **" .. guild.name .. "** for **" ..
                            reason .. "**.",
                        color = colors.heavyred
                    },
                    components = discordia.Components():button({
                        url = appealLink,
                        style = "link",
                        label = "Appeal Ban",
                        emoji = resolvedEmojis.link
                    }):raw()
                })
            elseif violatorMember then
                violator:heavyred("You have been banned from **" .. guild.name .. "** for **" .. reason .. "**.",
                    emojis.ban)
            end

            db:send(guild, "modlogchannel", {
                embed = {
                    author = author(moderator),
                    thumbnail = thumbnail(violator),
                    title = emojis.ban .. " Member Banned",
                    description = getUserString(violator) .. " was banned by " .. getUserString(moderator) .. ":\n" ..
                        emojis.right .. " **Reason:** " .. case.reason .. "\n" .. emojis.right .. " **Date:** <t:" ..
                        case.timestamp .. ">\n" .. emojis.right .. " **Case ID:** " .. case.caseID,
                    color = colors.heavyred
                }
            })

            return true, getUserString(violator) .. " has been banned for **" .. reason .. "**.\n-# " .. emojis.right .. " **Case ID:** `" .. case.caseID .. "`"
        else
            return false, getUserString(violator) .. " has been successfully banned, however a case could not be created."
        end
    else
        local success, err = guild:banUser(violator.id, reason, deleteSeconds)

        if not success then
            return nil, "Failed to ban " .. getUserString(violator) .. ": " .. tostring(err):usub(20)
        end

        return true, "" .. getUserString(violator) .. " has been banned for **" .. reason .. "**."
    end
end

_G.banMember = banMember

return {
    name = "ban",
    description = "Ban a user.",
    aliases = {},
    category = "Moderation",
    slashCommand = slashCommand,
    requiredPermissions = {"ADMIN"},
    hybridCallback = function(interaction, args, slash)
        local config = sqldb:get(interaction.guild.id) or {}
        local member, user = fetchMemberFromInteraction(interaction, args, slash)
        local reason = (slash and args and args.reason) or
                           ((not slash) and table.remove(args, 1) and table.concat(args, " ") ~= "" and
                               table.concat(args, " "))
        local departmental = (slash and args and args.departmental == true) or false

        if not user then
            return interaction:fail("You did not provide a user to ban.", nil, true)
        elseif not reason then
            return interaction:fail("You did not provide a reason for this ban.", nil, true)
        end

        if member and member.highestRole and interaction.member.highestRole and
            (member.highestRole.position >= interaction.member.highestRole.position) then
            return interaction:fail("That user has a role equal to or higher than you.", nil, true)
        end

        if member then
            local moderatable, err = canModerate(interaction.member, member)
            if not moderatable then
                return interaction:fail(err, nil, true)
            end
        end

        if departmental and (not config.departments or table.count(config.departments) <= 0) then
            return interaction:fail("This server does not host any departments.", nil, true)
        end

        if departmental then
            local succ, result = banMember(interaction.guild, member, user, interaction.member, reason)

            if not succ then
                return interaction:fail(result, nil, true)
            end

            local results = {
                [interaction.guild.id] = {
                    name = interaction.guild.name,
                    success = succ,
                    error = nil
                }
            }
            local departments = config.departments or {}

            for id, _ in pairs(departments) do
                local department = Client:getGuild(id)

                if department then
                    local s, e = department:banUser(user.id, reason)

                    results[id] = {
                        name = department.name,
                        success = s,
                        error = e
                    }
                end
            end

            return interaction:reply({
                embed = {
                    title = emojis.guild .. " Departmental Ban Results",
                    description = ">>> " .. getUserString(user) .. " has been banned from the following servers:\n" ..
                        emojis.right .. " " .. table.concatFn(results, "\n" .. emojis.right .. " ", function(result, id)
                        return
                            ((result.success and emojis.success) or emojis.fail) .. " " .. result.name .. " (`" .. id ..
                                "`)" .. ((result.error and (": `" .. result.error .. "`")) or "")
                    end),
                    color = colors.info
                }
            })
        else
            local succ, result = banMember(interaction.guild, member, user, interaction.member, reason)

            if succ then
                return interaction:success(result)
            elseif succ == false then
                return interaction:warning(result)
            else
                return interaction:fail(result, nil, true)
            end
        end
    end
}