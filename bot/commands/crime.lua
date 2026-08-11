-- crime.lua

local slashCommand = tools.slashCommand("crime", "Commit a crime!")

local replies = {
	{
		message = "You performed a heist on the Bank of America and stole {amount}.",
		success = true
	},
	{
		message = "You stole a car and sold it for {amount}.",
		success = true
	},
	{
		message = "Your spaghetti legs made you trip and you lost {fine}.",
		success = false
	},
	{
		message = "You shoplifted electronics from Best Buy and you stole {amount}.",
		success = true
	},
	{
		message = "A swarm of bees attacked you and you lost {fine}.",
		success = false
	},
	{
		message = "The police cought you red-handed and they fined you {fine}.",
		success = false
	}
}

return {
    name = "crime",
    description = "Commit a crime!",
    aliases = {},
    category = "Economy",
    slashCommand = slashCommand,
    requiredPermissions = {"SETUP"},
	hybridCallback = function(interaction, args, command)
		local config = sqldb:get(interaction.guild.id) or {}
		config.economy = config.economy or {}
		config.economy.replies = config.economy.replies or {}
		config.economy.cooldowns = config.economy.cooldowns or {}
		config.economy.limits = config.economy.limits or {}

		if config.economy and config.economy.disabled then
			return interaction:fail("The " .. emojis.quack .. " **Economy** module is not enabled in this server.")
		end

		local account, err = db:ecoFetch(interaction.member)
		if not account then
			return interaction:fail(err, nil, true)
		end

		local last = account.cooldowns and account.cooldowns.crime
		local cooldown = (config.economy.cooldowns and config.economy.cooldowns.crime) or 120
		
		if last and ((os.time() - last) < cooldown) then
			return interaction:fail("You are on cooldown. Try again in **" .. readable((last + cooldown) - os.time()) .. "**.")
		else
			account.cooldowns.crime = os.time()
			db:ecoModify(interaction.member, {cooldowns = account.cooldowns})
		end
		
		math.randomseed(os.time() + math.floor(math.random() * 10000))
		
		local success = math.random(1,5) == 1
		
		local reps = table.merge(config.economy.replies and config.economy.replies.crime or {}, replies)

		for i = #reps, 1, -1 do
			if reps[i].success ~= success then
				table.remove(reps, i)
			end
		end
		
		local replynum = math.random(1, #reps)
		local reply = reps[replynum]
		local amount = math.random(config.economy.limits and config.economy.limits.crime and config.economy.limits.crime.success and config.economy.limits.crime.success.min or 1, config.economy.limits and config.economy.limits.crime and config.economy.limits.crime.success and config.economy.limits.crime.success.max or 750)
		local fine = math.floor(account.balance.wallet * ((config.economy.limits and config.economy.limits.crime and config.economy.limits.crime.fail) or 0.75))
		
		amount = amount * db:ecoMultiplier(interaction.member)

		if success then
			account.balance.wallet = account.balance.wallet + amount
			db:ecoBalance(interaction.member, "wallet", account.balance.wallet)
			interaction:success(reply.message:gsub("{amount}", (config.economy.currency or emojis.quack) .. " **" .. formatNumber(amount) .. "**") .. (((not table.find(replies, reply)) and "\n-# " .. emojis.right .. " Custom Reply #" .. replynum) or ""))
		else
			account.balance.wallet = account.balance.wallet - fine
			db:ecoBalance(interaction.member, "wallet", account.balance.wallet)
			interaction:fail(reply.message:gsub("{fine}", (config.economy.currency or emojis.quack) .. " **" .. formatNumber(fine) .. "**") .. (((not table.find(replies, reply)) and "\n-# " .. emojis.right .. " Custom Reply #" .. replynum) or ""))
		end
	end
}