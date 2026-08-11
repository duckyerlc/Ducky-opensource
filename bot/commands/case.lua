-- case.lua
local slashCommand = tools.slashCommand("case", "View the given case's info.")
slashCommand = slashCommand:addOption(tools.integer("id", "The case ID."):setRequired(true))

local actions = discordia.Components():selectMenu({
    id = "actionSelector",
    placeholder = "Select an action...",
    actionRow = 1,
    options = {{
        label = "Edit Reason",
        value = "editReason",
        emoji = resolvedEmojis.edit
    }, {
        label = "Void Case",
        value = "voidCase",
        emoji = resolvedEmojis.delete
    }}
})

local confirmComps = discordia.Components():button({
    id = "yes",
    emoji = resolvedEmojis.yeswhite,
    style = "success"
}):button({
    id = "no",
    emoji = resolvedEmojis.nowhite,
    style = "danger"
})

return {
    name = "case",
    description = "View the given case's info.",
    aliases = {"caseinfo"},
    category = "Moderation",
    slashCommand = slashCommand,
    requiredPermissions = {"MOD", "SETUP"},
    hybridCallback = function(interaction, args, command)
        local config = sqldb:get(interaction.guild.id) or {}
        local cases = config.cases or {}

        local caseID = (args and args.id and tonumber(args.id)) or (args and args[1] and tonumber(args[1]))

        if not caseID then
            return interaction:fail("You must provide a case ID to view.")
        end

        local case, caseIndex
        for i, v in pairs(cases) do
            if v.caseID == caseID then
                case = v
                caseIndex = i
                break
            end
        end

        if not case then
            return interaction:fail("That case does not exist.")
        end

        local violator = Client:getUser(case.member)
        local moderator = Client:getUser(case.moderator)

        local comps = nil

        if hasPermission(interaction.member, "ADMIN") == true then
            comps = actions:raw()

            if (not command) and (args and args[2] and args[2]:lower() == "void") then
                cases[caseIndex] = nil
                sqldb:set(interaction.guild.id, {
                    cases = cases
                }, "CASE_VOID")
                db:send(interaction.guild, "modlogchannel", {
                    embed = {
                        author = author(interaction.member),
                        thumbnail = (violator and violator.avatarURL and {
                            url = violator.avatarURL
                        }) or (violator and violator.defaultAvatarURL and {
                            url = violator.defaultAvatarURL
                        }),
                        title = emojis.delete .. " Case Voided",
                        description = "**Case " .. caseID .. "** was voided by " .. getUserString(interaction.member) ..
                            ":\n" .. emojis.right .. " **Member:** " .. getUserString(violator) .. "\n" .. emojis.right ..
                            " **Moderator:** " .. getUserString(moderator) .. "\n" .. emojis.right .. " **Type:** " ..
                            case.type .. "\n" .. emojis.right .. " **Reason:** " .. case.reason .. "\n" .. emojis.right ..
                            " **Issued:** <t:" .. case.timestamp .. ">\n" .. emojis.right .. " **Voided:** <t:" .. os.time() ..
                            ">",
                        color = colors.fail
                    }
                })
                return interaction:success("**Case " .. caseID .. "** has been voided.")
            end
        end

        local caseEmbed = {
            author = author(moderator),
            thumbnail = (violator.avatarURL and {
                url = violator.avatarURL
            }) or (violator.defaultAvatarURL and {
                url = violator.defaultAvatarURL
            }),
            title = "Case " .. caseID,
            description = emojis.right .. " **Member:** " .. getUserString(violator) .. "\n" .. emojis.right ..
                " **Moderator:** " .. getUserString(moderator) .. "\n" .. emojis.right .. " **Type:** " .. case.type ..
                ((case.length and (" (" .. readable(case.length) .. ")")) or "") .. "\n" .. emojis.right ..
                " **Reason:** " .. case.reason .. "\n" .. emojis.right .. " **Date:** <t:" .. case.timestamp .. ">",
            color = colors.info
        }

        local reply = interaction:reply({
            embed = caseEmbed,
            components = comps
        })

        local function updateReply()
            caseEmbed.description =
                emojis.right .. " **Member:** " .. getUserString(violator) .. "\n" .. emojis.right .. " **Moderator:** " ..
                    getUserString(moderator) .. "\n" .. emojis.right .. " **Type:** " .. case.type ..
                    ((case.length and (" (" .. readable(case.length) .. ")")) or "") .. "\n" .. emojis.right ..
                    " **Reason:** " .. case.reason .. "\n" .. emojis.right .. " **Date:** <t:" .. case.timestamp .. ">"
            reply:update({
                embed = caseEmbed,
                components = comps
            })
        end

        if comps then
            onComp(reply, "selectMenu", "actionSelector", interaction.user.id, false, function(selectInteraction)
                local selection = selectInteraction.data.values and selectInteraction.data.values[1]

                if not selection then
                    return selectInteraction:fail("You did not make a selection.", nil, true)
                end

                if selection == "editReason" then
                    prompt(selectInteraction, "Case " .. caseID .. " ・ Edit Reason", {
                        {
                            question = "Edit Reason...",
                            placeholder = "The new reason for this case.",
                            style = "short",
                            required = true,
                            default = case.reason,
                        }
                    }, function(mia, responses)
                        local response = responses and responses["Edit Reason..."]

                        if mia and response then
                            case.reason = response
                            sqldb:set(interaction.guild.id, { cases = config.cases}, "CASE_EDIT")

                            db:send(interaction.guild, "modlogchannel", {
                                embed = {
                                    author = author(interaction.member),
                                    thumbnail = (violator.avatarURL and { url = violator.avatarURL })
                                    or (violator.defaultAvatarURL and { url = violator.defaultAvatarURL }),
                                    title = emojis.edit .. " Case Edited",
                                    description = "**Case " .. caseID .. "**'s reason was modified by " ..
                                    getUserString(interaction.member) .. ":\n" ..
                                    emojis.right .. " **New Reason:** " .. response,
                                    color = colors.warning
                                }
                            })
                            mia:success("The reason for this case has been updated to **" .. response .. "**", nil, true)
                            updateReply()
                        else
                            mia:fail("An unknown error occurred while attempting to edit the reason for this case. ", nil, true)
                        end
                    end, true)
                elseif selection == "voidCase" then
                    local confirmation = selectInteraction:reply({
                        embed = {
                            description = emojis.warning .. " Are you sure you would like to void **Case " .. caseID ..
                                "**?",
                            color = colors.warning
                        },
                        components = confirmComps:raw()
                    }, true)

                    if confirmation and type(confirmation) == "table" then
                        onComp(confirmation, "button", nil, selectInteraction.user.id, true, function(buttonInteraction)
                            local buttonId = buttonInteraction.data.custom_id

                            if buttonId == "yes" then
                                selectInteraction:deleteReply(confirmation.id)
                                buttonInteraction:updateDeferred(true)

                                cases[caseIndex] = nil
                                sqldb:set(interaction.guild.id, {
                                    cases = cases
                                }, "CASE_VOID")
                                db:send(interaction.guild, "modlogchannel", {
                                    embed = {
                                        author = author(interaction.member),
                                        thumbnail = (violator.avatarURL and {
                                            url = violator.avatarURL
                                        }) or (violator.defaultAvatarURL and {
                                            url = violator.defaultAvatarURL
                                        }),
                                        title = emojis.delete .. " Case Voided",
                                        description = "**Case " .. caseID .. "** was voided by " ..
                                            getUserString(interaction.member) .. ":\n" .. emojis.right ..
                                            " **Member:** " .. getUserString(violator) .. "\n" .. emojis.right ..
                                            " **Moderator:** " .. getUserString(moderator) .. "\n" .. emojis.right ..
                                            " **Type:** " .. case.type .. "\n" .. emojis.right .. " **Reason:** " ..
                                            case.reason .. "\n" .. emojis.right .. " **Issued:** <t:" .. case.timestamp ..
                                            ">\n" .. emojis.right .. " **Voided:** <t:" .. os.time() .. ">",
                                        color = colors.fail
                                    }
                                })

                                reply:update({
                                    embed = {
                                        description = emojis.delete .. " This case has been voided.",
                                        color = colors.fail
                                    },
                                    components = {}
                                })
                            elseif buttonId == "no" then
                                selectInteraction:deleteReply(confirmation.id)
                                updateReply()
                                buttonInteraction:updateDeferred(true)
                            end
                        end)
                    end
                end
            end)
        end
    end
}