-- rob.lua
local slashCommand = tools.slashCommand("rob", "Rob the given user!")
slashCommand = slashCommand:addOption(tools.user("user", "The user to rob."):setRequired(true))

local replies = {
	{
		message = "You robbed {target} for {amount}.",
		success = true
	},
	{
		message = "You tripped and fell while trying to rob {target}.",
		success = false
	},
	{
		message = "You tried to get away but got caught in a traffic jam while trying to rob {target}.",
		success = false
	},
	{
		message = "The police caught you robbing {target}.",
		success = false
	},
	{
		message = "{target} smacked you with their purse.",
		success = false
	},
	{
		message = "A swarm of bees attacked you while you tried to rob {target}.",
		success = false
	},
	{
		message = "You robbed {target} but the wind blew all the money right back into their pocket.",
		success = false
	}
}

return {
    name = "rob",
    description = "Rob the given user!",
    aliases = {},
    category = "Economy",
    slashCommand = slashCommand,
    requiredPermissions = {"SETUP"},
	hybridCallback = function(interaction, args, slash)
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

		local target = fetchMemberFromInteraction(interaction, args, slash)
		if not target then
			return interaction:fail("You must provide a user to rob.", nil, true)
		elseif target.user.bot then
			return interaction:fail("You cannot rob a bot.", nil, true)
		end

		local targetAccount, err = db:ecoFetch(target)
		if not targetAccount then
			return interaction:fail(err, nil, true)
		end

		local last = account.cooldowns and account.cooldowns.rob
		local cooldown = (config.economy.cooldowns and config.economy.cooldowns.rob) or 60

		if last and (os.time() - last) < cooldown then
			return interaction:fail("You are on cooldown. Try again in **" .. readable((last + cooldown) - os.time()) .. "**.")
		else
			account.cooldowns.rob = os.time()
			db:ecoModify(interaction.member, { cooldowns = account.cooldowns })
		end

		math.randomseed(os.time() + math.floor(math.random() * 10000))

		if target.id == interaction.member.id then
			local trolled = math.random(20, 5000)
			account.balance.wallet = account.balance.wallet - trolled
			db:ecoBalance(interaction.member, "wallet", account.balance.wallet)
			return interaction:fail("You robbed yourself...? Welp, there goes " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(trolled) .. "**.")
		end

		local success = math.random(1,5) == 1

		local reps = table.merge(config.economy.replies and config.economy.replies.rob or {}, replies)

		for i = #reps, 1, -1 do
			if reps[i].success ~= success then
				table.remove(reps, i)
			end
		end

		local replynum = math.random(1, #reps)
		local reply = reps[replynum]
		local amount = math.random(1, targetAccount.balance.wallet)

		if success then
			targetAccount.balance.wallet = targetAccount.balance.wallet - amount
			targetAccount.balance.wallet = math.abs(targetAccount.balance.wallet)
			db:ecoBalance(target, "wallet", targetAccount.balance.wallet)

			account.balance.wallet = account.balance.wallet + amount
			db:ecoBalance(interaction.member, "wallet", account.balance.wallet)

			interaction:success(reply.message:gsub("{amount}", (config.economy.currency or emojis.quack) .. " " .. formatNumber(amount)):gsub("{target}", getUserString(target)) .. (((not table.find(replies, reply)) and "\n-# " .. emojis.right .. " Custom Reply #" .. replynum) or ""))
		else
			interaction:fail(reply.message:gsub("{target}", getUserString(target)) .. (((not table.find(replies, reply)) and "\n-# " .. emojis.right .. " Custom Reply #" .. replynum) or ""))
		end
	end
}