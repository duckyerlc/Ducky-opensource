-- donate.lua

local slashCommand = tools.slashCommand("donate", "Donate money to the given user!")
slashCommand = slashCommand:addOption(tools.user("user", "The user to donate to."):setRequired(true))
slashCommand = slashCommand:addOption(tools.integer("amount", "The amount of money to donate."):setRequired(true))

return {
    name = "donate",
    description = "Donate money to the given user!",
    aliases = {"give", "transfer"},
    category = "Economy",
    slashCommand = slashCommand,
    requiredPermissions = {},
    hybridCallback = function(interaction, args, slash, subcmd)
        local reciever = fetchMemberFromInteraction(interaction, args, slash)
        if not reciever then
            return interaction:fail("I could not find that user.", nil, true)
		elseif reciever.user.bot then
			return interaction:fail("You cannot donate to a bot.", nil, true)
        end

        local config = sqldb:get(interaction.guild.id) or {}
		config.economy = config.economy or {}

        if config.economy and config.economy.disabled then
			return interaction:fail("The " .. emojis.quack .. " **Economy** module is not enabled in this server.")
		end

        local account, err = db:ecoFetch(interaction.member)
        if not account then
            return interaction:fail(err, nil, true)
        end

        local recieverAccount, err = db:ecoFetch(reciever)
        if not recieverAccount then
            return interaction:fail(err, nil, true)
        end

        if interaction.member == reciever then
            return interaction:fail("You can not donate to yourself.", nil, true)
        end

        local amount = (slash and args and args.amount) or ((not slash) and args and args[2])
        if tonumber(amount) then
			amount = math.floor(tonumber(amount) + 0.5)
		elseif amount == "all" then
			amount = account.balance.wallet
		elseif amount == "half" then
			amount = math.floor(account.balance.wallet/2)
		else
			amount = nil
		end

        amount = amount and math.abs(amount)

        if not amount then
            return interaction:fail("You did not provide a valid amount of money to donate to " .. getUserString(reciever) .. ".", nil, true)
        elseif account.balance.wallet < amount then
            return interaction:fail("You cannot donate more money then what you have.", nil, true)
        end

        account.balance.wallet = account.balance.wallet - amount
        recieverAccount.balance.wallet = recieverAccount.balance.wallet + amount
        db:ecoBalance(interaction.member, "wallet", account.balance.wallet)
        db:ecoBalance(reciever, "wallet", recieverAccount.balance.wallet)

        return interaction:success("You successfully donated " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(amount) .. "** to " .. getUserString(reciever) .. ".")
    end
}