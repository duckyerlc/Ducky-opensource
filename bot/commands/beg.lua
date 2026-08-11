-- beg.lua
local slashCommand = tools.slashCommand("beg", "Beg for money.")

local replies = {
	{
		message = "You found {amount} on the sidewalk.",
		success = true
	},
	{
		message = "You begged a jewelry store and they gave you {amount}.",
		success = true
	},
	{
		message = "You grabbed some cans from the trash can and sold them for {amount}.",
		success = true
	},
	{
		message = "You found {amount} on the sidewalk.",
		success = true
	},
	{
		message = "A stranger blessed you and provided you with {amount}.",
		success = true
	},
	{
		message = "You asked strangers for money but they ignored you.",
		success = false
	},
	{
		message = "You begged your parents but they told you to go get a job.",
		success = false
	},
	{
		message = "You searched the sewers but got flushed away.",
		success = false
	}
}

return {
    name = "beg",
    description = "Beg for money.",
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

		if config.economy and config.economy.disabled then
			return interaction:fail("The " .. emojis.quack .. " **Economy** module is not enabled in this server.")
		end

		local account, err = db:ecoFetch(interaction.member)
		if not account then
			return interaction:fail(err, nil, true)
		end

		local last = account.cooldowns and account.cooldowns.beg
		local cooldown = (config.economy.cooldowns and config.economy.cooldowns.beg) or 60

		if last and (os.time() - last) < cooldown then
			return interaction:fail("You are on cooldown. Try again in **" .. readable((last + cooldown) - os.time()) .. "**.")
		else
			account.cooldowns.beg = os.time()
			db:ecoModify(interaction.member, { cooldowns = account.cooldowns })
		end
		
		math.randomseed(os.time() + math.floor(math.random() * 10000))
		local success = math.random(1,2) == 1

		local amount = math.random(config.economy.limits and config.economy.limits.beg and config.economy.limits.beg.success and config.economy.limits.beg.success.min or 25, config.economy.limits and config.economy.limits.beg and config.economy.limits.beg.success and config.economy.limits.beg.success.max or 100)
		local reps = table.merge(config.economy.replies and config.economy.replies.beg or {}, replies)

		amount = amount * db:ecoMultiplier(interaction.member)

		for i = #reps, 1, -1 do
			if reps[i].success ~= success then
				table.remove(reps, i)
			end
		end

		local reply = reps[math.random(1, #reps)]

		if success then
			account.balance.wallet = account.balance.wallet + amount
			db:ecoBalance(interaction.member, "wallet", account.balance.wallet)

			return interaction:success(reply.message:gsub("{amount}", (config.economy.currency or emojis.quack) .. " **" .. formatNumber(amount) .. "**"))
		else
			return interaction:fail(reply.message:gsub("{amount}", (config.economy.currency or emojis.quack) .. " **" .. formatNumber(amount) .. "**"))
		end
	end
}