-- modstats.lua
local slashCommand = tools.slashCommand("modstats", "View staff information.")
local subCommand = tools.subCommand("view", "View the moderation statistics of a staff member.")
subCommand = subCommand:addOption(tools.user("user", "The user to view information on."):setRequired(false))
slashCommand = slashCommand:addOption(subCommand)

local subCommand = tools.subCommand("leaderboard", "View the top moderators by statistics.")
subCommand = subCommand:addOption(tools.string("range", "Time range (24h/week/month/total)"):setRequired(false))
slashCommand = slashCommand:addOption(subCommand)

return {
    name = "modstats",
    description = "View staff information.",
    aliases = {"ms"},
    category = "ERLC",
    slashCommand = slashCommand,
    requiredPermissions = {"SETUP", "ERLC_STAFF"},
    subcommands = {
        "view",
        leaderboard = {
            "lb"
        }
    },
    hybridCallback = function(interaction, args, slash, subcmd)
        local guild = interaction.guild
        local config = sqldb:get(guild.id) or {}

        if subcmd == "leaderboard" or subcmd == "lb" then
            local range = args.range and args.range:lower() or "total"
            local tracked = config.trackedModcalls or {}
            local currentTime = os.time()

            -- if not config.apiKey then
            --     return interaction:fail("This feature requires you to link your ERLC API key with Ducky via the " ..
            --                                 emojis.game .. " **ERLC Integration** page in `/setup`.", nil, true)
            -- end

            local rangeSeconds = {
                ["24h"] = 86400,
                ["week"] = 604800,
                ["month"] = 2592000
            }

            local leaderboard = {}

            for moderatorID, timestamps in pairs(tracked) do
                local count = 0
                for _, t in pairs(timestamps) do
                    if rangeSeconds[range] then
                        if (currentTime - t) <= rangeSeconds[range] then
                            count = count + 1
                        end
                    else
                        count = count + 1
                    end
                end
                table.insert(leaderboard, {
                    id = moderatorID,
                    count = count
                })
            end

            table.sort(leaderboard, function(a, b)
                return a.count > b.count
            end)

            local desc = ""
            for i, data in ipairs(leaderboard) do
                if i > 10 then
                    break
                end
                local user = guild:getMember(data.id)
                desc = desc .. "`#" .. i .. "` " .. getUserString(user) .. emojis.dot .. data.count .. " modcalls\n"
            end

            if desc == "" then
                desc = emojis.right .. " No modcalls recorded yet for this time range."
            end

            local embed = {
                title = emojis.modcall .. " Modcall Leaderboard",
                description = desc .. ((rangeSeconds[range] and "\n-# " .. emojis.right .. " Only showing data from the past " .. range:capitalize() .. ".") or ""),
                color = colors.info,
            }

            return interaction:reply({
                embed = embed
            })
        elseif subcmd == "view" then
            local member = (hasPermission(interaction.member, "ERLC_MANAGER") == true and
                               fetchMemberFromInteraction(interaction, args, slash)) or interaction.member

            if hasPermission(member, "ERLC_STAFF") ~= true then
                return interaction:fail("That user does not have ERLC Staff permissions.")
            end

            local currentTime = os.time()

            local shiftTimeTotal, shiftAmountTotal = 0, 0
            local shiftTimeLast24h, shiftAmountLast24h = 0, 0
            local shiftTimeLastWeek, shiftAmountLastWeek = 0, 0
            local shiftTimeLast30d, shiftAmountLast30d = 0, 0
            local firstShiftTimestamp = currentTime
            local punishmentsOnShift = 0

            local wave, err = db:shiftWave(guild)

            if not wave then
                return interaction:fail(err or " Failed to get shift information.", nil, true)
            end

            for _, v in pairs(wave.shifts or {}) do
                if v.member == member.id and v.ended then
                    local timeDiff = currentTime - v.ended
                    local elapsed = v.ended - v.started

                    for _, pause in pairs(v.pauses or {}) do
                        if pause.started and pause.ended then
                            elapsed = elapsed - (pause.ended - pause.started)
                        end
                    end

                    shiftAmountTotal = shiftAmountTotal + 1
                    shiftTimeTotal = shiftTimeTotal + elapsed
                    punishmentsOnShift = punishmentsOnShift + v.punishments

                    if timeDiff <= 86400 then
                        shiftAmountLast24h = shiftAmountLast24h + 1
                        shiftTimeLast24h = shiftTimeLast24h + elapsed
                    end
                    if timeDiff <= 604800 then
                        shiftAmountLastWeek = shiftAmountLastWeek + 1
                        shiftTimeLastWeek = shiftTimeLastWeek + elapsed
                    end
                    if timeDiff <= 2592000 then
                        shiftAmountLast30d = shiftAmountLast30d + 1
                        shiftTimeLast30d = shiftTimeLast30d + elapsed
                    end

                    if v.ended < firstShiftTimestamp then
                        firstShiftTimestamp = v.ended
                    end
                end
            end

            local punishmentsTotal, punishmentsLast24h, punishmentsLastWeek, punishmentsLast30d = 0, 0, 0, 0

            for _, punishment in pairs(config.punishments or {}) do
                if punishment and punishment.moderator == member.id then
                    local timeDiff = currentTime - punishment.timestamp
                    punishmentsTotal = punishmentsTotal + 1

                    if timeDiff <= 86400 then
                        punishmentsLast24h = punishmentsLast24h + 1
                    end
                    if timeDiff <= 604800 then
                        punishmentsLastWeek = punishmentsLastWeek + 1
                    end
                    if timeDiff <= 2592000 then
                        punishmentsLast30d = punishmentsLast30d + 1
                    end
                end
            end

            local modcallsTotal, modcallsLast24h, modcallsLastWeek, modcallsLast30d = 0, 0, 0, 0

            if config.trackModcalls and type(config.trackedModcalls) == "table" then
                for moderatorID, trackedModcalls in pairs(config.trackedModcalls) do
                    if moderatorID == member.id then
                        for _, modcallTimestamp in pairs(trackedModcalls) do
                            local timeDiff = currentTime - modcallTimestamp
                            modcallsTotal = modcallsTotal + 1

                            if timeDiff <= 86400 then
                                modcallsLast24h = modcallsLast24h + 1
                            end
                            if timeDiff <= 604800 then
                                modcallsLastWeek = modcallsLastWeek + 1
                            end
                            if timeDiff <= 2592000 then
                                modcallsLast30d = modcallsLast30d + 1
                            end
                        end
                    end
                end
            end

            local daysTracked = (shiftAmountTotal > 0) and
                                    math.max(1, math.floor((currentTime - firstShiftTimestamp) / 86400)) or 0
            local avgShiftPerDay = (shiftAmountTotal > 0 and daysTracked > 0) and
                                       math.ceil(shiftAmountTotal / daysTracked) or 0
            local avgShiftTimePerDay = (shiftTimeTotal > 0 and daysTracked > 0) and
                                           math.ceil(shiftTimeTotal / daysTracked) or 0
            local avgShiftLength = (shiftTimeTotal > 0) and (math.ceil(shiftTimeTotal / shiftAmountTotal)) or 0

            local avgPunishmentsPerShift =
                (shiftAmountTotal > 0) and (math.ceil(punishmentsOnShift / shiftAmountTotal)) or 0
            local avgPunishmentsPerDay = (punishmentsTotal > 0 and daysTracked > 0) and
                                             math.ceil(punishmentsTotal / daysTracked) or 0

            local avgModcallsPerShift = (shiftAmountTotal > 0) and (math.ceil(modcallsTotal / shiftAmountTotal)) or 0
            local avgModcallsPerDay = (modcallsLast30d > 0 and daysTracked > 0) and
                                          math.ceil(modcallsLast30d / daysTracked) or 0

            local pages = {{
                author = author(member),
                title = emojis.clock .. " Shifts",
                color = colors.info,
                description = emojis.right .. " **Shift Times**\n" .. emojis.space .. emojis.right .. " **" ..
                    readable(shiftTimeLast24h) .. " shift time** logged within the past day.\n" .. emojis.space ..
                    emojis.right .. " **" .. readable(shiftTimeLastWeek) ..
                    " shift time** logged within the past week.\n" .. emojis.space .. emojis.right .. " **" ..
                    readable(shiftTimeLast30d) .. " shift time** logged within the past month.\n" .. emojis.space ..
                    emojis.right .. " **" .. readable(shiftTimeTotal) .. " shift time** logged in total.\n" ..
                    emojis.right .. " **Shift Amounts**\n" .. emojis.space .. emojis.right .. " **" ..
                    shiftAmountLast24h .. " shifts** logged within the past day.\n" .. emojis.space .. emojis.right ..
                    " **" .. shiftAmountLastWeek .. " shifts** logged within the past week.\n" .. emojis.space ..
                    emojis.right .. " **" .. shiftAmountLast30d .. " shifts** logged within the past month.\n" ..
                    emojis.space .. emojis.right .. " **" .. shiftAmountTotal .. " shifts** logged in total.\n" ..
                    emojis.right .. " **Shift Averages**\n" .. emojis.space .. emojis.right .. " **" ..
                    readable(avgShiftLength) .. " average length** of a shift.\n" .. emojis.space .. emojis.right ..
                    " **" .. avgShiftPerDay .. " average shifts** per day.\n" .. emojis.space .. emojis.right .. " **" ..
                    readable(avgShiftTimePerDay) .. " average shift time** per day.\n",
                identifier = {
                    text = "Shifts",
                    emoji = resolvedEmojis.clock
                }
            }, {
                author = author(member),
                title = emojis.moderate .. " Punishments",
                color = colors.info,
                description = emojis.right .. " **Punishment Amounts**\n" .. emojis.space .. emojis.right .. " **" ..
                    punishmentsOnShift .. " punishments** logged while being on shift.\n" .. emojis.space ..
                    emojis.right .. " **" .. punishmentsLast24h .. " punishments** logged within the past day.\n" ..
                    emojis.space .. emojis.right .. " **" .. punishmentsLastWeek ..
                    " punishments** logged within the past week.\n" .. emojis.space .. emojis.right .. " **" ..
                    punishmentsLast30d .. " punishments** logged within the past month.\n" .. emojis.space ..
                    emojis.right .. " **" .. punishmentsTotal .. " punishments** logged in total.\n" .. emojis.right ..
                    " **Punishment Averages**\n" .. emojis.space .. emojis.right .. " **" .. avgPunishmentsPerShift ..
                    " punishments per shift** on average.\n" .. emojis.space .. emojis.right .. " **" ..
                    avgPunishmentsPerDay .. " average punishments** per day.\n",
                identifier = {
                    text = "Punishments",
                    emoji = resolvedEmojis.moderate
                }
            }, {
                author = author(member),
                title = emojis.modcall .. " Modcalls",
                color = colors.info,
                description = ((config.trackModcalls and emojis.right .. " **Modcall Amounts**\n" .. emojis.space ..
                    emojis.right .. " **" .. modcallsLast24h .. " modcalls** answered within the past day.\n" ..
                    emojis.space .. emojis.right .. " **" .. modcallsLastWeek ..
                    " modcalls** answered within the past week.\n" .. emojis.space .. emojis.right .. " **" ..
                    modcallsLast30d .. " modcalls** answered within the past month.\n" .. emojis.right ..
                    " **Modcall Averages**\n" .. emojis.space .. emojis.right .. " **" .. avgModcallsPerShift ..
                    " modcalls per shift** on average.\n" .. emojis.space .. emojis.right .. " **" .. avgModcallsPerDay ..
                    " average modcalls** per day.\n") or emojis.right ..
                    " Modcall tracking is disabled in this server. You must run the **`/setup`** command and navigate to the " ..
                    emojis.chart .. " **Activity Management** page to enable it."),
                identifier = {
                    text = "Modcalls",
                    emoji = resolvedEmojis.modcall
                }
            }}

            _G.paginate(interaction, pages, interaction.user, {
                teleport = true,
                clamp = false,
                startPage = 1
            })
        end
    end
}