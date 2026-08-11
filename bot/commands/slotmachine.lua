-- slotmachine.lua

local slashCommand = tools.slashCommand("slotmachine", "Gamble with your quacks in a slot machine.")
slashCommand = slashCommand:addOption(tools.integer("bet", "The amount of quacks to bet."):setRequired(true))

return {
    name = "slotmachine",
    description = "Gamble with your quacks in a slot machine.",
    aliases = {"slots"},
    category = "Economy",
    slashCommand = slashCommand,
    requiredPermissions = {"SETUP"},
	hybridCallback = function(interaction, args, slash)
		local config = sqldb:get(interaction.guild.id) or {}
        config.economy = config.economy or {}
		config.economy.cooldowns = config.economy.cooldowns or {}

        if config.economy and config.economy.disabled then
			return interaction:fail("The " .. emojis.quack .. " **Economy** module is not enabled in this server.")
		end

        local account, err = db:ecoFetch(interaction.member)
        if not account then
            return interaction:fail(err, nil, true)
        end
        
		local last = account.cooldowns and account.cooldowns.gamble
		local cooldown = (config.economy.cooldowns and config.economy.cooldowns.gamble) or 180
		
		if last and ((os.time() - last) < cooldown) then
			return interaction:fail("You are on cooldown. Try again in **" .. readable((last + cooldown) - os.time()) .. "**.")
        else
            account.cooldowns.gamble = os.time()
			db:ecoModify(interaction.member, { cooldowns = account.cooldowns })
		end

        local bet = (slash and args and args.bet) or ((not slash) and args and args[1])

        if tonumber(bet) then
			bet = math.floor(tonumber(bet) + 0.5)
		elseif bet == "all" then
			bet = account.balance.wallet
		elseif bet == "half" then
			bet = math.floor(account.balance.wallet / 2)
		else
			bet = nil
		end

        if (not bet) then
            return interaction:fail("You did not provide an amount of money to bet.", nil, true)
        elseif (bet < 100) then
            return interaction:fail("Your bet must be at least " .. (config.economy.currency or emojis.quack) .. " **100**.", nil, true)
        elseif (bet > account.balance.wallet) then
            return interaction:fail("You cannot bet more money than you have.", nil, true)
        end

        account.balance.wallet = account.balance.wallet - bet
		db:ecoBalance(interaction.member, "wallet", account.balance.wallet)

		local r = interaction:loading()

        local map = {
            {emojis.smroll, emojis.smroll, emojis.smroll},
            {emojis.smroll, emojis.smroll, emojis.smroll},
            {emojis.smroll, emojis.smroll, emojis.smroll}
        }

        local function updateEmbed(ia, rolling)
            ia = ia or r

            local embed = {
                author = author(interaction.member),
                title = emojis.loading .. " Rolling...",
                description = map[1][1] .. " " .. map[1][2] .. " " .. map[1][3] .. "\n" .. map[2][1] .. " " .. map[2][2] .. " " .. map[2][3] .. " " .. emojis.left .. "\n" .. map[3][1] .. " " .. map[3][2] .. " " .. map[3][3],
                color = colors.blank
            }

            if not rolling then
                if map[2][1] == map[2][2] and map[2][2] == map[2][3] then
                    embed.title = emojis.success .. " Win"
                    embed.description = embed.description .. "\n\nYou rolled 3 " .. map[2][1] .. "'s a row and earned " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(bet) .. "**."
                    embed.color = colors.success

                    account.balance.wallet = account.balance.wallet + (bet * 2)
		            db:ecoBalance(interaction.member, "wallet", account.balance.wallet)
                else
                    embed.title = emojis.fail .. " Loss"
                    embed.description = embed.description .. "\n\nYou did not roll 3 in a row and lost " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(bet) .. "**."
                    embed.color = colors.fail
                end
            end
            
            return ia:update({
                embed = embed
            })
        end

        local function randomItem(used)
            local items = {
                emojis.smducky,
                emojis.smdev,
                emojis.smexperimental,
                emojis.smplus
            }

            local item

            repeat
                item = items[math.random(1,#items)]
            until not table.find(used, item)

            return item
        end

        updateEmbed(nil, true)
		
		timer.sleep(1000)

        for i = 1, 3 do --for every column
            local used = {}

            map[1][i] = randomItem(used)
            table.insert(used, map[1][i])

            map[2][i] = randomItem(used)
            table.insert(used, map[2][i])

            map[3][i] = randomItem(used)
            table.insert(used, map[3][i])
        end

        updateEmbed()
	end
}