-- automod.lua

local automod = {
	name = "automod",
	description = "Automatic Discord moderation.",
    disabled = true
}

local connections = {}

automod.Start = function()

    connections.autoMod = {"guildAuditLogEntryCreate", Client:on("guildAuditLogEntryCreate", function(LogEntry)
        if LogEntry.action_type == discordia.enums.actionType.autoModMessageBlock or LogEntry.action_type == discordia.enums.actionType.autoModMessageFlag then
            local guildId = LogEntry.guild_id
            local config = sqldb:get(guildId)
            local violatorId = LogEntry.user_id
            local reason = LogEntry.options.auto_moderation_rule_name

            if guildId and violatorId and config and not blacklisted(guildId) and not blacklisted(violatorId) then
                local guild = Client:getGuild(guildId)
                local violator = guild:getMember(violatorId)
                local OfficialDiscordUser = Client:getUser("643945264868098049")

                if guild and violator and not blacklisted(guild.ownerId) then
                    local case = db:case(violator, OfficialDiscordUser, "Warning", reason)

                    if case then
                        violator:warning("You have been warned in **" .. guild.name .. "** for **" .. reason .. "**.")
                        
                        db:send(guild, "modlogchannel", {
                            embed = {
                                title = emojis.warning .. " Member Warned",
                                description = "**" .. violator.name .. "** was warned by **Discord Built-In Moderation**:\n" .. emojis.right .. " **Reason:** " .. case.reason .. "\n" .. emojis.right .. " **Date:** <t:" .. case.timestamp .. ">\n" .. emojis.right .. " **Case ID:** " .. case.caseID,
                                color = colors.warning
                            }
                        })
                    end
                end
            end
        end
    end)}

end -- End start function

automod.Stop = function()
	for _, con in pairs(connections) do
		Client:removeListener(con[1], con[2])
	end

    connections = nil
end

return automod