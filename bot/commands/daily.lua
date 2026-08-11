-- daily.lua
local slashCommand = tools.slashCommand("daily", "Claim your daily reward!")

return {
    name = "daily",
    description = "Claim your daily reward!",
    aliases = {},
    category = "Economy",
    slashCommand = slashCommand,
    requiredPermissions = {},
    hybridCallback = function(interaction, args, slash, subcmd)
        local config = sqldb:get(interaction.guild.id) or {}
        config.economy = config.economy or {}
        config.economy.cooldowns = config.economy.cooldowns or {}
        config.economy.limits = config.economy.limits or {}

        if config.economy and config.economy.disabled then
			return interaction:fail("The " .. emojis.quack .. " **Economy** module is not enabled in this server.")
		end

        local account, err = db:ecoFetch(interaction.member)
        if not account then
            return interaction:fail(err, nil, true)
        end

        local last = account.cooldowns.daily
        if last and ((os.time() - last) < 86400) then
            return interaction:fail("You can claim your daily reward again in **" .. readable((last + 86400) - os.time()) .. "**.")
        else
            account.cooldowns.daily = os.time()
            db:ecoModify(interaction.member, {cooldowns = account.cooldowns})
        end

        local amount = math.random(config.economy.limits and config.economy.limits.daily and config.economy.limits.daily.success and config.economy.limits.daily.success.min or 1000, config.economy.limits and config.economy.limits.daily and config.economy.limits.daily.success and config.economy.limits.daily.success.max or 2500)
        account.balance.wallet = account.balance.wallet + amount
        db:ecoBalance(interaction.member, "wallet", account.balance.wallet)

        return interaction:success("You claimed your daily reward of " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(amount) .. "**.")
    end
}