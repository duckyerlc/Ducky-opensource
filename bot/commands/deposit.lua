-- deposit.lua

local slashCommand = tools.slashCommand("deposit", "Deposit money into your bank!")
slashCommand = slashCommand:addOption(tools.string("amount", "The amount of money to deposit."):setRequired(true))

return {
    name = "deposit",
    description = "Deposit money into your bank!",
    aliases = {"dep"},
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

		local account, err = db:ecoFetch(interaction.member)
        if not account then
            return interaction:fail(err, nil, true)
        end

		local amount = (args and args.amount) or args[1]

		if tonumber(amount) then
			amount = math.floor(tonumber(amount) + 0.5)
		elseif amount == "all" then
			amount = account.balance.wallet
		elseif amount == "half" then
			amount = math.floor(account.balance.wallet / 2)
		else
			amount = nil
		end

		if type(amount) ~= "number" then
			return interaction:fail("You must provide an amount of money to deposit into your bank.", nil, true)
		end

		amount = math.abs(amount)

		if account.balance.wallet < amount then
			return interaction:fail("You cannot deposit more money than you have in your wallet.")
		elseif amount <= 0 then
			return interaction:fail("The amount must be at least " .. (config.economy.currency or emojis.quack) .. " **1**.")
		end

		db:ecoDeposit(interaction.member, amount)

        return interaction:success("You have deposited " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(amount) .. "** into your bank.")
    end
}