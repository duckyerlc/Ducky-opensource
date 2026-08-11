-- updatemembers.lua

local slashCommand = tools.slashCommand("updatemembers", "Update all members to your configuration, including verification and autoroles.")
local option = tools.user("user", "Provide if you want to update 1 user."):setRequired(false)
slashCommand = slashCommand:addOption(option)

local function debug(text)
    if true then
        prettyLog("UM", "purple", text)
    end
end

local cooldown = {}
local rateLimitTracker = {}

local function getRateLimitDelay(guildId, plus)
    local tracker = rateLimitTracker[guildId]
    if not tracker then
        rateLimitTracker[guildId] = {
            requests = 0,
            lastReset = os.time(),
            currentDelay = plus and 200 or 700
        }
        tracker = rateLimitTracker[guildId]
    end

    if os.time() - tracker.lastReset >= 60 then
        tracker.requests = 0
        tracker.lastReset = os.time()
        tracker.currentDelay = plus and 200 or 700
    end

    tracker.requests = tracker.requests + 1

    if tracker.requests > (plus and 50 or 20) then
        tracker.currentDelay = math.min(tracker.currentDelay * 1.5, plus and 1000 or 2000)
    elseif tracker.requests < (plus and 20 or 10) then
        tracker.currentDelay = math.max(tracker.currentDelay * 0.9, plus and 100 or 500)
    end

    return tracker.currentDelay
end


return {
    name = "updatemembers",
    description = "Update all members to your configuration, including verification and autoroles.",
    aliases = {"syncmembers", "um", "sm"},
    category = "Roblox",
    slashCommand = slashCommand,
    requiredPermissions = {"MANAGE_SERVER", "SETUP"},
    hybridCallback = function(interaction, args, slash, subcmd)
        local guild = interaction.guild
        debug("updatemembers command initiated in guild " .. guild.id .. " by " .. interaction.member.id)

        local config = sqldb:get(guild.id) or {}

        if (not config.verifiedroles) and (not config.verifiednickname) and (not config.unverifiedroles) and (not config.joinroles) then
            return interaction:fail("Roblox verification or autoroles are not configured in this server.")
        end

        if cooldown[guild.id] and cooldown[guild.id] == 0 then
            return interaction:fail("I'm currently already updating members in this server.")
        end

        if args and ((slash and args.user) or args[1]) then
            local member = fetchMemberFromInteraction(interaction, args, slash)
            debug("Single member update requested for: " .. (member and member.id or "not found"))

            if not member then
                return interaction:fail("I could not find that member.")
            end

            if member.user.bot then
                return interaction:fail("Bots are excluded from Roblox Verification and autoroles.")
            end

            local r = interaction:reply({embed = {
                description = emojis.loading .." Updating Member...",
                color = colors.blank
            }})

            local success, opCount = updateMember(member, "/updatemembers command used by @" .. interaction.member.username)
            local statusMsg = success and "Successfully updated" or "Updated with some issues"

            if type(r) == "table" then
                r:update({embed = {
                    description = emojis.success .. " " .. statusMsg .. " **@" .. member.name .. "** (" .. opCount .. " operations).",
                    color = success and colors.success or colors.warning
                }})
            else
                interaction:success(statusMsg .. " **@" .. member.name .. "** (" .. opCount .. " operations).")
            end
        else
            debug("Full server update requested.")
            local plus = sqldb:plusGuild(guild)
            local cooldownTime = (plus and 1800) or 3600

            if cooldown[guild.id] and (os.time() - cooldown[guild.id] <= cooldownTime) then
                local remainingTime = cooldownTime - (os.time() - cooldown[guild.id])
                return interaction:fail("Please wait **" .. readable(remainingTime) .. "** before using this command again.")
            end

            cooldown[guild.id] = 0

            local r = interaction:reply({embed = {
                description = emojis.loading .. " Fetching members...",
                color = colors.blank
            }})

            loadMembers(guild)
            debug("Fetched " .. #guild.members .. " members for update.")

            local membercount = #guild.members
            local completedCount = 0
            local successfulCount = 0
            local totalOperations = 0

            local updateThreshold = math.ceil(membercount * 0.1)
            local nextUpdateAt = updateThreshold

            local function updateMessage()
                local remainingCount = membercount - completedCount
                local currentDelay = getRateLimitDelay(guild.id, plus)
                local estimatedTime = math.ceil(remainingCount * (currentDelay / 1000))
                local timeString = readable(estimatedTime)
                local successRate = completedCount > 0 and math.floor((successfulCount / completedCount) * 100) or 100

                local embed = {
                    title = emojis.loading .. " Updating Members...",
                    description = 
                    emojis.right .. " **Progress:** " .. completedCount .. "/" .. membercount .. " members (" .. successRate .. "% success rate)\n" ..
                    emojis.right .. " **Operations:** " .. totalOperations .. " role changes executed\n" ..
                    "-# " .. emojis.right .. emojis.clock .. " **Estimated Time Remaining:** " .. timeString .. "\n" ..
                    "-# " .. emojis.right .. emojis.timeout .. " **Current Delay:** " .. math.floor(currentDelay) .. "ms",
                    color = colors.blank
                }

                if type(r) == "table" then
                    r:update({embed = embed})
                else
                    r = interaction:reply({embed = embed})
                end
            end

            updateMessage()
            local starttime = os.time()

            for _, member in pairs(guild.members) do
                local success, opCount = updateMember(member, "/updatemembers command used by @" .. interaction.member.username)

                completedCount = completedCount + 1

                if success then
                    successfulCount = successfulCount + 1
                    totalOperations = totalOperations + ((type(opCount) == "number" and opCount) or 0)
                end

                if completedCount >= nextUpdateAt or completedCount == membercount then
                    updateMessage()
                    nextUpdateAt = nextUpdateAt + updateThreshold
                end
            end

            local elapsedTime = os.time() - starttime
            local endTime = readable(elapsedTime)
            local finalSuccessRate = math.floor((successfulCount / membercount) * 100)

            cooldown[guild.id] = os.time()

            rateLimitTracker[guild.id] = nil

            local finalEmbed = {
                title = emojis.success .. " Members Update Complete",
                description = 
                emojis.right .. "**Processed:** " .. membercount .. " members\n" ..
                emojis.right .. "**Success Rate:** " .. finalSuccessRate .. "% (" .. successfulCount .. "/" .. membercount .. ")\n" ..
                emojis.right .. "**Total Operations:** " .. totalOperations .. " role changes\n" ..
                 "-# " .. emojis.right .. emojis.clock .. " **Total Time:** " .. endTime,
                color = finalSuccessRate >= 100 and colors.success or colors.warning
            }

            if finalSuccessRate < 100 then
                finalEmbed.description = finalEmbed.description .. "\n-# " .. emojis.right .. " Some members were not fully updated due to permission conflicts or ratelimits."
            end

            if type(r) == "table" then
                r:update({embed = finalEmbed})
            else
                interaction:reply({embed = finalEmbed})
            end
        end
    end
}