-- diagnose.lua
local slashCommand = tools.slashCommand("diagnose", "Ensure that Ducky is properly configured to work as intended.")

return {
    name = "diagnose",
    description = "Ensure that Ducky is properly configured to work as intended.",
    aliases = {"diagnosis", "dg"},
    category = "Configuration",
    slashCommand = slashCommand,
    requiredPermissions = {},
    hybridCallback = function(interaction, args, slash, subcmd)
        local permissions = diagnose(interaction.guild)
        local denied = 0

        for _, p in pairs(permissions) do
            if not p.enabled then
                denied = denied + 1
            end
        end

        local embed = {
            author = author(interaction.guild),
            title = (denied <= 0 and (emojis.success .. " Good to Go")) or emojis.warning .. " Missing Permissions",
            description = emojis.right .. " " .. table.concatFn(permissions, "\n" .. emojis.right .. " ", function(permission)
                return "**" .. permission.name .. "**: " .. ((permission.enabled and emojis.success) or emojis.fail)
            end),
            color = (denied <= 0 and colors.success) or colors.warning
        }

        if interaction.guild.me:hasPermission(interaction.channel, "embedLinks") then
            return interaction:reply({embed = embed})
        else
            return interaction:reply("## " .. embed.title .. "\n" .. embed.description)
        end
    end
}