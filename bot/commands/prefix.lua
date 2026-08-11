-- prefix.lua

local slashCommand = tools.slashCommand("prefix",
    "Get the current server text command prefix, and change it if a new one is provided.")
slashCommand = slashCommand:addOption(tools.string("new", "The new prefix for the server."):setRequired(false))

return {
    name = "prefix",
    description = "Get the current server text command prefix, and change it if a new one is provided.",
    aliases = {},
    category = "Configuration",
    slashCommand = slashCommand,
    requiredPermissions = {},
    hybridCallback = function(interaction, args, slash, subcmd)
        local config = sqldb:get(interaction.guild.id)

        if not config then
            return interaction:reply({
                embed = {
                    description = _G.emojis.fail ..
                    " Ducky is not setup in this server. Run the `/setup` command to setup Ducky.",
                    color = _G.colors.fail
                }
            })
        end

        local prefix = config.prefix or "d!"
        local newPrefix = args and hasPermission(interaction.member, "MANAGE_SERVER") == true and ((slash and args.new) or args[1])

        if newPrefix then
            if newPrefix:len() > 5 then
                return interaction:reply({
                    embed = {
                        description = _G.emojis.fail .. " Prefixes can be set to a maximum of 5 characters in length.",
                        color = _G.colors.fail
                    }
                })
            else
                config.prefix = newPrefix
                sqldb:set(interaction.guild.id, { prefix = config.prefix }, "EDIT_PREFIX")

                return interaction:reply({
                    embed = {
                        description = _G.emojis.success ..
                        " The prefix for this server has been set to `" .. newPrefix .. "`.",
                        color = _G.colors.success
                    }
                })
            end
        else
            return interaction:reply({
                embed = {
                    description = "The prefix for this server is set to `" .. prefix .. "`.",
                    color = _G.colors.blank
                }
            })
        end
    end
}