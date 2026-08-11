-- autoban.lua

local autoban = {
	name = "autoban",
	description = "Auto bans raid bots."
}

local connection = nil

local banlist = {
    "1308195724810391562",
    "1310700026510446674",
    "1310982833837441064",
    "1310127023179431936",
    "1325893885318266911",
    "1327072743199342623",
    "1327081694968418324",
    "1393855985197776957",
    "1394739060207124702"
}

autoban.Start = function()
	connection = Client:on("memberJoin", function(member)
        if (not member) or (not member.guild) then
            return
        end

        local guild = member.guild
        local owner = Client:getUser(guild.ownerId)
        local ownerDM = owner and owner:getPrivateChannel()

        if table.find(banlist, member.id) then
            local success, err = member:ban("This bot is malicious.")

            if success then
                if ownerDM then
                    ownerDM:send("# " .. emojis.protect .. " Server Protected\n\nDucky has automatically banned a raid bot from your server, **" .. guild.name .. "**.\n\nThis bot has been identified as a potential threat, commonly used in raids or server destruction.\nThe details of the bot are as follows:\n" .. emojis.right .. " **Bot Name:** " .. member.name .. "\n" .. emojis.right .. " **Bot ID:** `" .. member.id .. "`\n\nTo investigate further, please review your server's audit logs and filter by **Add Bot** to find who added it.\n-# " .. emojis.warning .. " It’s possible that the person who added this bot was tricked into doing so. Ensure to inform them and remind your community to be cautious when inviting bots.\n\nFor more information about this bot, join our [support server](<https://duckybot.xyz/support/>), and review this message: https://discord.com/channels/1228508072289370172/1258891659874144256/1327051844496785408.\n\n*Thank you for choosing " .. emojis.ducky .. " **Ducky**.*")
                end
            else
                if ownerDM then
                    ownerDM:send(
                        "# " .. emojis.error .. " Action Required\n\n" ..
                        "Ducky attempted to ban a **raid bot** from your server, **" .. guild.name .. "**, but the action failed, likely due to insufficient permissions.\n\n" ..
                        "This bot poses a serious threat as it is commonly used in raids or server destruction.\n" ..
                        "The details of the bot are as follows:\n" ..
                        emojis.right .. " **Bot Name:** " .. member.name .. "\n" ..
                        emojis.right .. " **Bot ID:** `" .. member.id .. "`\n\n" ..
                        "Please manually ban this bot immediately to secure your server.\n\n" ..
                        "Error Details: ```" .. tostring(err) .. "```\n\n" ..
                        "*Thank you for choosing " .. emojis.ducky .. " **Ducky**.*"
                    )
                end
            end
        end
    end)
end

autoban.Stop = function()
	Client:removeListener("memberJoin", connection)
    connection = nil
end

return autoban