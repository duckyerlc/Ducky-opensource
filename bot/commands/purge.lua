-- purge.lua

local slashCommand = tools.slashCommand("purge", "Purge the given amount of messages from the current channel.")
slashCommand = slashCommand:addOption(tools.integer("amount", "The amount of messages to purge."):setRequired(true))

local dangerous = {
    {
        name = "ticket panel",
        danger = function(config, message)
            return (config.panels and config.panels[message.id] and true) or false
        end
    },
    {
        name = "valuable message",
        danger = function(config, message)
            return (config.valuablemessages and table.find(config.valuablemessages, message.channel.id  .. "/" .. message.id) and true) or false
        end
    }
}

return {
    name = "purge",
    description = "Purge the given amount of messages from the current channel.",
    aliases = {"bulkdelete", "bd"},
    category = "Moderation",
    slashCommand = slashCommand,
    requiredPermissions = { "MOD" },
    hybridCallback = function(interaction, args, slash, subcmd)
        local config = sqldb:get(interaction.guild.id) or {}
        local amount = (slash and args and args.amount) or ((not slash) and args and args[1] and tonumber(args[1]))

        if not amount then
            return interaction:fail("You must provide a valid number of messages to purge.", nil, true)
        elseif amount > 1000 or amount <= 0 then
            return interaction:fail("You can only purge between 1 and 1,000 messages.", nil, true)
        end

        if not slash then
            amount = amount + 1
        end

        local count = 0
        local tooOld = 0
        local purgeTranscript = ""
        local batches = {}
        local dangers = {}

        if slash then
            interaction:replyDeferred(true)
        else
            interaction.channel:broadcastTyping()
        end

        fetchBulkMessages(interaction.channel, amount, function(batch)
            for i = #batch, 1, -1 do
                local m =  batch[i]
                if (os.time() - m.createdAt) >= 1209600 then
                    table.remove(batch, i)
                    tooOld = tooOld + 1
                else
                    purgeTranscript = purgeTranscript .. contentString(m, true, true) .. "\n\n"
                end
            end

            count = count + table.count(batch)
            table.insert(batches, batch)
        end)

        local actualAmount = amount - tooOld

        for _, batch in pairs(batches) do
            for _, message in pairs(batch) do
                for _, d in pairs(dangerous) do
                    if d.danger(config, message) then
                        table.insert(dangers, {
                            message = message,
                            danger = d
                        })
                    end
                end
            end
        end

        local function purge()
            if not slash then
                interaction:delete()
            end

            for _, batch in pairs(batches) do
                interaction.channel:bulkDelete(batch)
            end

            db:send(interaction.guild, "modlogchannel", {
                embed = {
                    title = emojis.delete .. " Messages Purged",
                    description = "**" .. interaction.member.name .. "** purged **" .. actualAmount .. " messages** from " .. interaction.channel.mentionString .. ".\n" .. emojis.right .. " **Messages Purged:** " .. actualAmount .. "\n" .. emojis.right .. " **Date:** <t:" .. os.time() .. ">",
                    color = colors.success
                },
                files = {
                    {
                        "purged.txt",
                        purgeTranscript
                    }
                }
            })

            local msg = "**" .. actualAmount .. "** message" .. ((actualAmount ~= 1 and "s have") or " has") ..  " been purged." .. (((tooOld > 0) and ("\n-# " .. emojis.warning .. " **" .. tooOld .. " messages** were more than 2 weeks old, and could not be deleted.")) or "")

            if slash then
                interaction:success(msg, nil, true)
            else
                local r = interaction.channel:success(msg)

                timer.sleep(2500)

                if r then r:delete() end
            end
        end

        if table.count(dangers) > 0 then
            confirm(interaction, "Are you sure you would like to purge your " .. table.concatFn(dangers, ", ", function(d)
                return "**" .. d.danger.name .. "** (" .. d.message.link .. ")"
            end) .. "?", function(result, ria, r)
                if result == true then
                    ria:updateDeferred(true)
                    ria:deleteReply(r.id)
                    purge()
                else
                    ria:update({
                        embed = {
                            description = emojis.fail .. " The purging of **" .. amount .. " messages** has been canceled.",
                            color = colors.fail
                        },
                        components = {}
                    })
                    return
                end
            end)
        else
            purge()
        end
    end
}