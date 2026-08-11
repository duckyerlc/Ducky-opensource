-- modules/afk.lua

local afk = {
	name = "afk",
	description = "Handles all afk related interactions.",
}

local connections = {}

afk.Start = function()
    connections["messageCreateAfk"] = Client:on("messageCreateAfk", function(message, config)
        local guild = message.guild

        local userSettings = sqldb:getUserSettings(message.member.id) or {}

        local afk, afkNumber

        if userSettings.afk then
            afk = userSettings.afk
        else
            for i, v in pairs(config.afks or {}) do if v.id == message.member.id then afk, afkNumber = v, i end end
        end

        if afk and ((os.time() - afk.timestamp) >= 2) and message.content:usub(1, 3) ~= "-# " then
            afk = table.deepcopy(afk)

            if not userSettings.afk and afkNumber then
                config.afks[afkNumber] = nil
                sqldb:set(guild.id, {
                    afks = config.afks
                }, "AFK_REMOVE")
            elseif userSettings.afk then
                userSettings.afk = nil
                sqldb:setUserSettings(message.member.id, userSettings)
            end
            
            local elapsed = readable(os.time() - afk.timestamp)
            table.sort(afk.mentions or {}, function(a,b)
                return a.timestamp < b.timestamp
            end)
            local mentionStrings = ""

            for i, mention in pairs(afk.mentions or {}) do
                local mentionGuild = Client:getGuild(mention.guild)
                local mentionMember = mentionGuild and mentionGuild:getMember(mention.author)
                local mentionChannel = mentionGuild and mentionGuild:getChannel(mention.channel)
                local mentionMessage = mentionChannel and mentionChannel:getMessage(mention.message)

                if mentionMessage then
                    mentionStrings = mentionStrings .. "\n-# " .. emojis.pings .. " **@" .. ((mentionMember and mentionMember.username) or "<@" .. mention.author .. ">") .. "** mentioned you <t:" .. mention.timestamp .. ":R>: " .. mentionMessage.link
                else
                    mentionStrings = mentionStrings .. "\n-# " .. emojis.pings .. " **@" .. ((mentionMember and mentionMember.username) or "<@" .. mention.author .. ">") .. "** deleted a message that mentioned you <t:" .. mention.timestamp .. ":R> in <#" .. mention.channel .. ">." 
                end

                if i >= 10 then
                    mentionStrings = mentionStrings .. "\n-# " .. emojis.right .. " and " .. (#afk.mentions - 10) .. " more..."
                    break
                end
            end

            local r = message:reply(emojis.wave .. " Welcome back, **@" .. message.member.username .. "**!\n-# " .. emojis.right .. " You were AFK for **" .. elapsed .. "**." .. mentionStrings, true)

            local delay = ((table.count(afk.mentions or {}) > 0) and (10000 * table.count(afk.mentions or {}))) or 5000

            coroutine.wrap(function()
                timer.sleep(delay)
                if r then
                    r:delete()
                end
            end)()
        end

        if type(message.mentionedUsersIncludingReplies) == "table" then
            for _, mentionedUser in pairs(message.mentionedUsersIncludingReplies) do
                local userSettings = sqldb:getUserSettings(mentionedUser.id) or {}

                local afk = userSettings.afk or table.find(config.afks or {}, function(v, i)
                    return v.id == mentionedUser.id
                end)

                if afk then
                    afk.mentions = afk.mentions or {}
                    table.insert(afk.mentions, {
                        guild = message.guild.id,
                        channel = message.channel.id,
                        message = message.id,
                        author = message.user.id,
                        timestamp = math.floor(message.createdAt)
                    })
                    if userSettings.afk then
                        sqldb:setUserSettings(mentionedUser.id, userSettings)
                    else
                        sqldb:set(guild.id, {
                            afks = config.afks
                        }, "SET_AFK_MENTIONS")
                    end
                    local member = message.guild:getMember(mentionedUser.id)
                    if member then
                        local r = message:reply(emojis.pings .. " **@" .. member.username .. "** is AFK: " .. afk.reason .. "\n-# " .. emojis.right .. " AFK since <t:" .. afk.timestamp .. "> (<t:" .. afk.timestamp .. ":R>)", true)
                        coroutine.wrap(function()
                            timer.sleep(5000)
                            if r then r:delete() end
                        end)()
                    end
                end
            end
        end
    end)
end

afk.Stop = function()
	for event, connection in pairs(connections) do
		Client:removeListener(event, connection)
	end

	connections = nil
end

return afk