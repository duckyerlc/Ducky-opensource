-- work.lua

local slashCommand = tools.slashCommand("work", "Work to make some quacks!")

local replies = {
	{
		message = "You sold some NFTs and earned {amount}.",
		success = true
	},
	{
		message = "You sold a car at a dealership and earned {amount}.",
		success = true
	},
	{
		message = "You cleaned a school and earned {amount}.",
		success = true
	},
	{
		message = "You opened a lemonade stand and earned {amount}.",
		success = true
	},
	{
		message = "You worked at the register at 7-Eleven and earned {amount}.",
		success = true
	},
	{
		message = "You repaired a computer and earned {amount}.",
		success = true
	},
	{
		message = "You lockpicked a door for someone and earned {amount}.",
		success = true
	},
	{
		message = "You caught some fish and earned {amount}.",
		success = true
	},
	{
		message = "You delivered some packages and earned {amount}.",
		success = true
	},
	{
		message = "You walked someone's dog and earned {amount}.",
		success = true
	},
	{
		message = "You mowed a lawn and earned {amount}.",
		success = true
	},
	{
		message = "You washed some cars and earned {amount}.",
		success = true
	},
	{
		message = "You babysat a kid and earned {amount}.",
		success = true
	},
	{
		message = "You worked as a bartender and earned {amount}.",
		success = true
	},
	{
		message = "You taught some kids how to code and earned {amount}.",
		success = true
	}
}

return {
    name = "work",
    description = "Work to make some quacks!",
    aliases = {},
    category = "Economy",
    slashCommand = slashCommand,
    requiredPermissions = {"SETUP"},
	hybridCallback = function(interaction, args, command)
		local config = sqldb:get(interaction.guild.id) or {}
		config.economy = config.economy or {}
		config.economy.cooldowns = config.economy.cooldowns or {}
		config.economy.replies = config.economy.replies or {}
		config.economy.limits = config.economy.limits or {}
		config.economy.multipliers = config.economy.multipliers or {}

		if config.economy and config.economy.disabled then
			return interaction:fail("The " .. emojis.quack .. " **Economy** module is not enabled in this server.")
		end

		local account, err = db:ecoFetch(interaction.member)
		if not account then
			return interaction:fail(err, nil, true)
		end

		local last = account.cooldowns and account.cooldowns.work
		local cooldown = (config.economy.cooldowns and config.economy.cooldowns.work) or 30

		if last and (os.time() - last) < cooldown then
			return interaction:fail("You are on cooldown. Try again in **" .. readable((last + cooldown) - os.time()) .. "**.")
		else
			account.cooldowns.work = os.time()
			db:ecoModify(interaction.member, { cooldowns = account.cooldowns })
		end
		
		local reps = table.merge(config.economy.replies and config.economy.replies.work or {}, replies)
		local reply = reps[math.random(1, #reps)]

		math.randomseed(os.time() + math.floor(math.random() * 10000))
		local amount = math.random(config.economy.limits and config.economy.limits.work and config.economy.limits.work.success and config.economy.limits.work.success.min or 100, config.economy.limits and config.economy.limits.work and config.economy.limits.work.success and config.economy.limits.work.success.max or 300)

		amount = amount * db:ecoMultiplier(interaction.member)

		account.balance.wallet = account.balance.wallet + amount
		db:ecoBalance(interaction.member, "wallet", account.balance.wallet)
		
		return interaction:success(reply.message:gsub("{amount}", (config.economy.currency or emojis.quack) .. " **" .. formatNumber(amount) .. "**"))
	end
}