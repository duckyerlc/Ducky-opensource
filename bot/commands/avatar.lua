-- avatar.lua


local slashCommand = tools.slashCommand("avatar", "Get the avatar of the given user.")
slashCommand = slashCommand:addOption(tools.user("user", "The user to view their avatar on."):setRequired(false))

return {
	name = "avatar",
	description = "Get the avatar of the given user.",
	aliases = {
		"av",
        "pfp"
	},
	category = "Utility",
	slashCommand = slashCommand,
	requiredPermissions = {},
	hybridCallback = function(interaction, args, slash, subcmd)
        if (not slash) and (args) and (args[1]) and (args[1]:lower() == "guild" or args[1]:lower() == "server") then
            return interaction:reply({
                embed = {
                    author = author(interaction.guild),
                    image = {
                        url = (tostring(interaction.guild.iconURL) .. "?size=4096") or "https://duckybot.xyz/images/misc/defaultpfp.webp"
                    },
                    color = colors.yellow
                }
            })
        end
        
		local member = fetchMemberFromInteraction(interaction, args, slash) or interaction.member
        
		return interaction:reply({
			embed = {
                author = {
                    name = member.name .. "'s avatar",
                    icon_url = member.avatarURL or member.defaultAvatarURL or "https://duckybot.xyz/images/misc/defaultpfp.webp"
                },
                image = {
                    url = (tostring(member.avatarURL or member.defaultAvatarURL) .. "?size=4096") or "https://duckybot.xyz/images/misc/defaultpfp.webp"
                },
                color = colors.yellow
            }
		})
	end
}
