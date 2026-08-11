-- slowmode.lua

local slashCommand = tools.slashCommand("slowmode", "Put a slowmode on a channel.")
slashCommand = slashCommand:addOption(tools.string("time", "How long the slowmode is (0s to 6h)."):setRequired(true))
slashCommand = slashCommand:addOption(tools.channel("channel", "The channel to put a slowmode on (empty for current)."):setRequired(false))

return {
    name = "slowmode",
    description = "Put a slowmode on a channel.",
    aliases = {"ratelimit", "rn", "sm", "slow"},
    category = "Moderation",
    slashCommand = slashCommand,
    requiredPermissions = {"MOD"},
    hybridCallback = function(interaction, args, slash)
        local timeInput = (slash and args.time) or args[1]
        local time = (timeInput and convert(timeInput)) or 0

        if not time or time > 21600 then
            return interaction:fail("You must provide a time between **0 seconds** and **6 hours**.", nil, true)
        end
        
        local channel = (slash and args.channel) or (fetchChannelFromInteraction(interaction, args[2])) or interaction.channel

        local succ, err = channel:setRateLimit(time)

        if succ then
            if time == 0 then
                return interaction:success("The slowmode of this channel has been reset.")
            else
                return interaction:success("The slowmode of this channel has been set to **" .. readable(time) .. "**.")
            end
        else
            return interaction:fail("An unexpected error occurred while attempting to modify the slowmode of this channel.\n```\n" .. tostring(err) .. "```")
        end
    end
}