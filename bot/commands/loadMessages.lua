-- loadMessages.lua

local running

return {
    name = "loadMessages",
    description = "Emits messages the last 100 messages from a channel, useful for after downtime.",
    aliases = {},
    category = "Utility",
    requiredPermissions = {"SETUP", "BOT_DEVELOPER"},
    callback = function(message, args)
        if true then
            return message:fail("This command is currently not enabled by the " .. emojis.developer .. " **Developers**.")
        end

        if running then
            return
        end

        running = true

        local channel = message.channel
        local messages

        if args[1] and args[2] then
            if args[1] == "after" then
                messages = channel:getMessagesAfter(args[2], 100)
            elseif args[1] == "before" then
                messages = channel:getMessagesBefore(args[2], 100)
            end

            if not messages then
                return message:fail("I could not fetch those messages.")
            end
        end

        messages = messages or channel:getMessagesBefore(message.id, 100)

        channel:broadcastTyping()

        local result = ""
        for _, msg in pairs(messages) do
            if msg.id ~= message.id then
                Client:emit("messageCreate", msg)
                result = result .. "\n" .. emojis.right .. " Emitted " .. message.link

                timer.sleep(2000)
            end
        end

        if result:len() > 0 then
            message:reply(result)
        else
            message:fail("No messages found to emit.")
        end

        running = false
    end,
    slashCallback = function(interaction)
        local config = sqldb:get(interaction.guild.id) or {}
        local prefix = config.prefix or "d!"

        return interaction:fail("This command can only be used by prefix, `" .. prefix .. "loadMessages`.", nil, true)
    end
}