-- leaderboard.lua
local slashCommand = tools.slashCommand("leaderboard", "Show your server's economy leaderboard!")
slashCommand = slashCommand:addOption(tools.string("type", "The type of leaderboard.")
    :addChoice(tools.choice("All", "All"))
    :addChoice(tools.choice("Wallet", "Wallet"))
    :addChoice(tools.choice("Bank", "Bank"))
:setRequired(true))

return {
    name = "leaderboard",
    description = "Show your server's economy leaderboard!",
    aliases = {"lb"},
    category = "Economy",
    slashCommand = slashCommand,
    requiredPermissions = {},
    hybridCallback = function(interaction, args, slash, subcmd)
        local config = sqldb:get(interaction.guild.id) or {}
        config.economy = config.economy or {}
        config.economy.accounts = config.economy.accounts or {}

        if config.economy and config.economy.disabled then
			return interaction:fail("The " .. emojis.quack .. " **Economy** module is not enabled in this server.")
		end

        local type = "all"
        local input = (slash and args and args.type and string.lower(args.type)) or ((not slash) and args and args[1] and string.lower(args[1]))
        if input == "bank" then
            type = "bank"
        elseif input == "wallet" then
            type = "wallet"
        else
            type = "all"
        end

        local tosend = {
            author = author(interaction.guild),
            title = (config.economy.currency or emojis.quack) .. " Economy Leaderboard",
            color = colors.info
        }

        table.sort(config.economy.accounts or {}, function(a, b)
            a.balance = a.balance or {}
            a.balance.bank = a.balance.bank or 0
            a.balance.wallet = a.balance.wallet or 0

            b.balance = b.balance or {}
            b.balance.bank = b.balance.bank or 0
            b.balance.wallet = b.balance.wallet or 0

			if type == "wallet" then
				return a.balance.wallet > b.balance.wallet
			elseif type == "bank" then
				return a.balance.bank > b.balance.bank
			elseif type == "all" then
				return (a.balance.wallet + a.balance.bank) > (b.balance.wallet + b.balance.bank)
			end
        end)

        local pages = {}

        local total = #config.economy.accounts or 0
        if total == 0 then
            tosend.description = emojis.right .. " No members are registered in this server's economy."
            return interaction:reply({
                embed = tosend
            })
        end

        local c = 0
        local i = 0
        tosend.description = ""
        for _, account in pairs(config.economy.accounts or {}) do
            c = c + 1
            i = i + 1
            local b = (type == "bank" and account.balance.bank)
                or (type == "wallet" and account.balance.wallet)
                or (account.balance.wallet + account.balance.bank)
            tosend.description = tosend.description .. emojis.right .. " **" .. i .. ".** <@" .. account.member .. ">・" .. (config.economy.currency or emojis.quack) .. " " .. formatNumber(b) .. "\n"

            if c >= 10 or i == total then
                c = 0
                tosend.description = tosend.description .. "-# This leaderboard is sorted by **" .. type .. "** balance."
                table.insert(pages, tosend)
                tosend = {
                    author = author(interaction.guild),
                    title = (config.economy.currency or emojis.quack) .. " Economy Leaderboard",
                    description = "",
                    color = colors.info
                }
            end
        end

        return _G.paginate(interaction, pages, interaction.user, {teleport = true})
    end
}