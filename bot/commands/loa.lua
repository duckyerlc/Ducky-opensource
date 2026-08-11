-- loa.lua

local slashCommand = tools.slashCommand("loa", "Manage/view staff leave of absences.")
local subcommand = tools.subCommand("request", "Request an LOA.")
subcommand = subcommand:addOption(tools.string("length", "The length of your LOA. (i.e. 14d)"):setRequired(true))
subcommand = subcommand:addOption(tools.string("reason", "The reason for your LOA."):setRequired(true))
slashCommand = slashCommand:addOption(subcommand)
local subcommand = tools.subCommand("view", "View your LOA.")
subcommand = subcommand:addOption(tools.user("member", "View another member's LOA."):setRequired(false))
slashCommand = slashCommand:addOption(subcommand)
local subcommand = tools.subCommand("active", "View all active LOAs.")
slashCommand = slashCommand:addOption(subcommand)
local subcommand = tools.subCommand("history", "View your LOA history.")
subcommand = subcommand:addOption(tools.user("member", "View another member's LOA history."):setRequired(false))
slashCommand = slashCommand:addOption(subcommand)

return {
    name = "loa",
    description = "Manage/view staff leave of absences.",
    aliases = { "leave", "leaveofabsence" },
    category = "Activity Management",
    slashCommand = slashCommand,
    subcommands = {
        "request",
        "view",
        active = {
            "list",
        },
        "history"
    },
    requiredPermissions = { "ERLC_STAFF", "SETUP" },
    hybridCallback = function(interaction, args, slash, subcmd)
        local config = sqldb:get(interaction.guild.id) or {}

        if (not config.loasenabled) or (not config.loalogschannel) then 
            return interaction:fail("LOAs are not enabled in this server.", nil, true)
        end

        local LOAsChannel = config.loalogschannel and interaction.guild:getChannel(config.loalogschannel) and
        interaction.guild:getChannel(config.loalogschannel).send

        if not LOAsChannel then
            return interaction:fail("I could not find the LOA logs channel.", nil, true)
        end

        if (not slash) and subcmd then
            table.remove(args, 1)
        end

        if subcmd == "request" then
            if db:getPendingLOA(interaction.member) then
                return interaction:fail("You already have a pending LOA request. Use `/loa view` to cancel your pending request.", nil, true)
            elseif db:getActiveLOA(interaction.member) then
                return interaction:fail("You already have an active LOA. Use `/loa view` to end your current LOA.", nil,true)
            end

            local length = args.length or args[1]
            local reason = args.reason or (table.remove(args, 1) and table.concat(args, " "))

            if (not length) or (not _G.convert(length)) then
                return interaction:fail("You must provide a valid interval as the LOA length.", nil, true)
            elseif (not reason) or (reason == "") then
                return interaction:fail("You must provide a reason for this LOA.", nil, true)
            end

            length = _G.convert(length)

            if config.loamaxlength and length > config.loamaxlength then
                return interaction:fail("Your LOA length exceeds the maximum allowed (" .. readable(config.loamaxlength) .. ").", nil, true)
            end

            local shiftTime = db:shiftTotal(interaction.member)

            local loaMentionables = config.loamentionables and table.count(config.loamentionables) > 0 and ("-# " .. emojis.pings .. " " .. table.concatFn(config.loamentionables, " ", function(id) return (interaction.guild:getRole(id) and ("<@&" .. id .. ">")) or ("<@" .. id .. ">") end))
            db:send(interaction.guild, "loalogschannel", {
                content = loaMentionables or nil,
                embed = {
                    title = emojis.reminder .. " LOA Request",
                    description = getUserString(interaction.member) .. " is requesting an LOA:\n" .. 
                        emojis.right .. " **Length:** " ..(readable(length) or length) .. "\n" ..
                        emojis.right .. " **Ends:** <t:" .. (os.time() + length) .. ">\n" ..
                        emojis.right .. " **Reason:** " .. reason .. "\n" ..
                        emojis.right .. " **Shift Time:** " .. (shiftTime and readable(shiftTime) or emojis.fail),
                    color = colors.info,
                    author = author(interaction.user)
                },
                components = discordia.Components()
                    :button({
                        id = "approveloa_" .. interaction.member.id,
                        emoji = resolvedEmojis.yeswhite,
                        style = "success"
                    })
                    :button({
                        id = "denyloa_" .. interaction.member.id,
                        emoji = resolvedEmojis.nowhite,
                        style = "danger"
                    })
                    :raw()
            })

            config.loarequests = config.loarequests or {}
            table.insert(config.loarequests, {
                user = interaction.user.id,
                length = length,
                reason = reason,
                sent = os.time()
            })
            sqldb:set(interaction.guild.id, { loarequests = config.loarequests }, "LOA_REQUEST")
            interaction:success("Your LOA request has been sent.", nil, true)
        elseif subcmd == "view" then
            local member = fetchMemberFromInteraction(interaction, args, slash, "member")
            member = ((hasPermission(interaction.member, "ERLC_MANAGER") == true) and member) or interaction.member
            local pendingIdentifier = ((member.id == interaction.member.id) and "You have a") or getUserString(member) .. " has a"
            local activeIdentifier = ((member.id == interaction.member.id) and "You have an") or getUserString(member) .. " has an"

            local pending = db:getPendingLOA(member)
            local active = db:getActiveLOA(member)

            local r
            local doOncomp = false

            if pending then
                local tosend = {
                    embed = {
                        description = emojis.right .. " " .. pendingIdentifier .. " pending LOA request:\n" ..
                            emojis.space .. emojis.right .. " **Sent:** <t:" .. pending.sent .. ">\n" ..
                            emojis.space .. emojis.right .. " **Length:** " .. readable(pending.length) .. "\n" ..
                            emojis.space .. emojis.right .. " **Reason:** " .. pending.reason,
                        color = colors.info
                    },
                }

                if member.id == interaction.member.id then
                    tosend.components = discordia.Components()
                        :button({
                            id = "cancel",
                            label = "Cancel",
                            style = "danger",
                            emoji = resolvedEmojis.nowhite
                        })
                        :raw()

                    doOncomp = true
                else
                    tosend.components = discordia.Components()
                        :button({
                            id = "approveloa_" .. member.id,
                            emoji = resolvedEmojis.yeswhite,
                            label = "Approve",
                            style = "success"
                        })
                        :button({
                            id = "denyloa_" .. member.id,
                            emoji = resolvedEmojis.nowhite,
                            label = "Deny",
                            style = "danger"
                        })
                        :raw()
                end

                r = interaction:reply(tosend)
            elseif active then
                r = interaction:reply({
                    embed = {
                        description = emojis.right .. " " .. activeIdentifier .. " active LOA:\n" ..
                            emojis.space .. emojis.right .. " **Started:** <t:" .. active.starts .. ">\n" ..
                            emojis.space .. emojis.right .. " **Ends:** <t:" .. active.ends .. ">\n" ..
                            emojis.space .. emojis.right .. " **Length:** " .. readable(active.ends - active.starts) .. "\n" ..
                            emojis.space .. emojis.right .. " **Reason:** " .. active.reason,
                        color = colors.info
                    },
                    components = discordia.Components()
                        :button({
                            id = "endearly",
                            label = "End Early",
                            style = "danger",
                            emoji = resolvedEmojis.stop
                        })
                        :raw()
                })

                doOncomp = true
            else
                return interaction:fail("You do not have a pending LOA request or an active LOA.", nil, true)
            end

            if doOncomp then
                onComp(r, nil, nil, interaction.user.id, true, function(ia)
                    local selection = ia.data.custom_id

                    if selection == "endearly" then
                        local s, e = db:endLOA(member, ia.member)

                        if s then
                            ia:update({
                                embed = {
                                    description = emojis.success .. " " .. getUserString(member) .. "'s LOA has been ended early.",
                                    color = colors.success
                                },
                                components = {}
                            })
                        else
                            ia:fail(e or "An unknown error occurred. Please try again later.", nil, true)
                        end
                    elseif selection == "cancel" then
                        local s, e = db:cancelPendingLoa(member)

                        if s then
                            ia:update({
                                embed = {
                                    description = emojis.success .. " " .. getUserString(member) .. "'s LOA request has been canceled.",
                                    color = colors.success
                                },
                                components = {}
                            })
                        else
                            ia:fail(e or "An unknown error occurred. Please try again later.", nil, true)
                        end
                    end
                end)
            end
        elseif subcmd == "active" or subcmd == "list" then
            local loas = config.loas or {}
            local active = {}

            for _, loa in pairs(loas) do
                if loa.active then
                    table.insert(active, loa)
                end
            end

            local pages = {}
            local emb = {
                title = emojis.reminder .. " Active LOAs (" .. table.count(active) .. ")",
                color = colors.info,
                fields = {}
            }

            for i, v in pairs(active) do
                local member = interaction.guild:getMember(v.user) or Client:getUser(v.user)
                table.insert(emb.fields, {
                    name = member.name .. " (`" .. member.id .. "`)",
                    value = emojis.right .. " **Started:** <t:" .. v.starts .. ">\n" ..
                        emojis.right .. " **Ends:** <t:" .. v.ends .. ">\n" ..
                        emojis.right .. " **Length:** " .. readable(v.ends - v.starts) .. "\n" ..
                        emojis.right .. " **Reason:** " .. v.reason
                })

                if table.count(emb.fields) >= 5 or i >= table.count(active) then
                    table.insert(pages, emb)
                    emb = {
                        title = emojis.reminder .. " Active LOAs (" .. table.count(active) .. ")",
                        color = colors.info,
                        fields = {}
                    }
                end
            end

            if not next(active) then
                return interaction:fail("There are no active LOAs in this server.", nil, true)
            end

            return _G.paginate(interaction, pages, interaction.user, { clamp = false, showTotalPages = true })
        elseif subcmd == "history" then
            local member = fetchMemberFromInteraction(interaction, args, slash, "member")
            member = ((hasPermission(interaction.member, "ERLC_MANAGER") == true) and member) or interaction.member
            local identifier = ((member.id ~= interaction.member.id) and (getUserString(member) .. " has")) or "You have"

            local loas = db:loaHistory(member) or {}

            local pages = {
                {
                    title = emojis.reminder .. " LOA History",
                    description = emojis.right .. " " .. identifier .. " had a total of **" .. table.count(loas) .. "** LOAs and accumulated a total of **" .. readable(db:loaTotal(member)) .. "** in LOAs.",
                    color = colors.info
                }
            }
            local emb = {
                title = emojis.reminder .. " LOA History (" .. table.count(loas) .. ")",
                fields = {},
                color = colors.info
            }

            for i, loa in pairs(loas) do
                table.insert(emb.fields, {
                    name = readable(loa.ends - loa.starts),
                    value = emojis.right .. " **Started:** <t:" .. loa.starts .. ">\n" ..
                        emojis.right .. " **Ended:** <t:" .. loa.ends .. ">\n" ..
                        emojis.right .. " **Reason:** " .. loa.reason
                })

                if table.count(emb.fields) >= 5 or i >= table.count(loas) then
                    table.insert(pages, emb)
                    emb = {
                        title = emojis.reminder .. " LOA History (" .. table.count(loas) .. ")",
                        fields = {},
                        color = colors.info
                    }
                end
            end

            return _G.paginate(interaction, pages, interaction.user, { clamp = false, showTotalPages = true })
        end
    end
}