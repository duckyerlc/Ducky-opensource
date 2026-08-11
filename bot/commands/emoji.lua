-- emoji.lua

local slashCommand = tools.slashCommand("emoji", "Clone or view an emoji.")
local subcmd = tools.subCommand("clone", "Clone an emoji.")
subcmd = subcmd:addOption(tools.string("emoji", "The emoji to clone."):setRequired(true))
subcmd = subcmd:addOption(tools.string("name", "The name to give the cloned emoji. Default to the cloned emoji's name."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("view", "View an emoji.")
subcmd = subcmd:addOption(tools.string("emoji", "The emoji to view."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)

return {
    name = "emoji",
    description = "Clone or view an emoji.",
    aliases = {"emj", "expression"},
    category = "Server Management",
    subcommands = {
        clone = {
            "copy"
        },
        "view"
    },
    slashCommand = slashCommand,
	requiredPermissions = {},
    hybridCallback = function(interaction, args, slash, subcmd)
        if not slash then
            table.remove(args, 1)
        end

		if subcmd == "clone" or subcmd == "copy" then
            if not hasPermission(interaction.member, "MANAGE_SERVER", nil, interaction) then
                return
            end
            
            local emojiString = (slash and args and args.emoji) or ((not slash) and args and args[1])
            local emojiName = (slash and args and args.name) or ((not slash) and args and args[2])
            local resolved = resolveEmoji(emojiString)

            if not resolved then
                return interaction:fail("You did not provide a valid emoji.", nil, true)
            end

            local image = urlToImage(resolved.image)
            
            local emoji, err = interaction.guild:createEmoji(emojiName or resolved.name, image)

            if emoji then
                return interaction:success("This emoji has been successfully cloned: " .. emoji.mentionString)
            else
                return interaction:fail("Failed to upload emoji:```\n" .. tostring(err) .. "```", nil, true)
            end
        elseif subcmd == "view" then
            local emojiString = (slash and args and args.emoji) or ((not slash) and args and args[1])
            local resolved = resolveEmoji(emojiString)

            if not resolved then
                return interaction:fail("You did not provide a valid emoji.", nil, true)
            end

            local markdown = "<:" .. resolved.name ..  ":" .. resolved.id .. ">"

            return interaction:reply({
                embed = {
                    title = "Viewing Emoji " .. resolved.raw,
                    description = emojis.right .. " **Name:** " .. resolved.name .. "\n" .. emojis.right .. " **ID:** `" .. resolved.id .. "`\n" .. emojis.right ..  " **Markdown:** `" .. markdown .. "` \n" .. emojis.right .. " **Animated:** " .. ((resolved.animated and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **URL:** `" .. resolved.image .. "`",
                    color = colors.info,
                    thumbnail = {
                        url = resolved.image
                    }
                }
            })
        end
    end
}
