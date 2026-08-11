-- about.lua

local slashCommand = tools.slashCommand("about", "View information on Ducky!")

local aboutcomps = discordia.Components()
    :button({
        url = "https://discord.com/oauth2/authorize?client_id=" .. Client.user.id .. "&permissions=8&integration_type=0&scope=bot",
        style = "link",
		emoji = resolvedEmojis.ducky
    })
    :button({
        url = "https://discord.gg/w2dNr7vuKP",
        style = "link",
		emoji = resolvedEmojis.support
    })
    :button({
        url = "https://docs.duckybot.xyz/",
        style = "link",
		emoji = resolvedEmojis.book
    })

return {
    name = "about",
    description = "View information on Ducky!",
    aliases = {"information", "info", "invite", "invitebot", "ducky"},
    category = "General",
    slashCommand = slashCommand,
    requiredPermissions = {},
    hybridCallback = function(interaction, args)
        local allLinks =  sqldb:getAllLinks()

        if not allLinks or type(allLinks) ~= "table" then
            allLinks = {}
        end
        
        local emb = {
            title = emojis.ducky .. " Ducky",
            description = "> " .. emojis.ducky .. " **Ducky** is a multipurpose bot focused on seamlessly integrating Discord and ERLC server automation for effortless management developed by [**Troptop**](https://discord.com/users/598958193032560642) and [**bobbibones**](https://discord.com/users/782235114858872854) with [**Quackscordia**](https://github.com/DuckySupport/Quackscordia), a fork of [**Discordia**](https://github.com/SinisterRectus/Discordia), the Discord API wrapper for **Lua**. If you find a bug, need support, would like to suggest a feature, want to keep up with updates, check out leaks of upcoming updates, view the bot's status, and more, hop into [**Ducky's Pond**](https://discord.gg/w2dNr7vuKP). Make sure to read our [**Terms**](https://duckybot.xyz/legal/terms) and [**Privacy Policy**](https://duckybot.xyz/legal/privacy) before using our service.",
            fields = {
                {
                    name = emojis.chart .. " Statistics",
                    value = emojis.right .. " **Guilds:** " .. formatNumber(table.count(Client.guilds)) .. "\n" .. emojis.right .. " **Users:** " .. formatNumber(getTotalUserCount()) .. "\n" .. emojis.right .. " **Roblox Links:** " .. formatNumber(table.count(allLinks)) .. "\n" .. emojis.right .. " **Version:** " .. _G.version .. "\n" .. emojis.right .. " **Uptime:** " .. readable(os.time() - _G.uptime)
                }
            },
            color =  colors.duckyyellow
        }
        return interaction:reply({
            embed = emb,
			components = aboutcomps:raw()
        })
    end
}