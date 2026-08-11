-- blackjack.lua

local slashCommand = tools.slashCommand("blackjack", "Gamble with your money in a game of Blackjack.")
slashCommand = slashCommand:addOption(tools.integer("bet", "The amount of money to bet."):setRequired(true))

local cards = {
    {
        name = "AceOfHearts",
        emoji = emojis.AceOfHearts,
        value = nil
    },
    {
        name = "TwoOfHearts",
        emoji = emojis.TwoOfHearts,
        value = 2
    },
    {
        name = "ThreeOfHearts",
        emoji = emojis.ThreeOfHearts,
        value = 3
    },
    {
        name = "FourOfHearts",
        emoji = emojis.FourOfHearts,
        value = 4
    },
    {
        name = "FiveOfHearts",
        emoji = emojis.FiveOfHearts,
        value = 5
    },
    {
        name = "SixOfHearts",
        emoji = emojis.SixOfHearts,
        value = 6
    },
    {
        name = "SevenOfHearts",
        emoji = emojis.SevenOfHearts,
        value = 7
    },
    {
        name = "EightOfHearts",
        emoji = emojis.EightOfHearts,
        value = 8
    },
    {
        name = "NineOfHearts",
        emoji = emojis.NineOfHearts,
        value = 9
    },
    {
        name = "TenOfHearts",
        emoji = emojis.TenOfHearts,
        value = 10
    },
    {
        name = "JackOfHearts",
        emoji = emojis.JackOfHearts,
        value = 10
    },
    {
        name = "QueenOfHearts",
        emoji = emojis.QueenOfHearts,
        value = 10
    },
    {
        name = "KingOfHearts",
        emoji = emojis.KingOfHearts,
        value = 10
    },
    {
        name = "AceOfDiamonds",
        emoji = emojis.AceOfDiamonds,
        value = nil
    },
    {
        name = "TwoOfDiamonds",
        emoji = emojis.TwoOfDiamonds,
        value = 2
    },
    {
        name = "ThreeOfDiamonds",
        emoji = emojis.ThreeOfDiamonds,
        value = 3
    },
    {
        name = "FourOfDiamonds",
        emoji = emojis.FourOfDiamonds,
        value = 4
    },
    {
        name = "FiveOfDiamonds",
        emoji = emojis.FiveOfDiamonds,
        value = 5
    },
    {
        name = "SixOfDiamonds",
        emoji = emojis.SixOfDiamonds,
        value = 6
    },
    {
        name = "SevenOfDiamonds",
        emoji = emojis.SevenOfDiamonds,
        value = 7
    },
    {
        name = "EightOfDiamonds",
        emoji = emojis.EightOfDiamonds,
        value = 8
    },
    {
        name = "NineOfDiamonds",
        emoji = emojis.NineOfDiamonds,
        value = 9
    },
    {
        name = "TenOfDiamonds",
        emoji = emojis.TenOfDiamonds,
        value = 10
    },
    {
        name = "JackOfDiamonds",
        emoji = emojis.JackOfDiamonds,
        value = 10
    },
    {
        name = "QueenOfDiamonds",
        emoji = emojis.QueenOfDiamonds,
        value = 10
    },
    {
        name = "KingOfDiamonds",
        emoji = emojis.KingOfDiamonds,
        value = 10
    },
    {
        name = "AceOfClubs",
        emoji = emojis.AceOfClubs,
        value = nil
    },
    {
        name = "TwoOfClubs",
        emoji = emojis.TwoOfClubs,
        value = 2
    },
    {
        name = "ThreeOfClubs",
        emoji = emojis.ThreeOfClubs,
        value = 3
    },
    {
        name = "FourOfClubs",
        emoji = emojis.FourOfClubs,
        value = 4
    },
    {
        name = "FiveOfClubs",
        emoji = emojis.FiveOfClubs,
        value = 5
    },
    {
        name = "SixOfClubs",
        emoji = emojis.SixOfClubs,
        value = 6
    },
    {
        name = "SevenOfClubs",
        emoji = emojis.SevenOfClubs,
        value = 7
    },
    {
        name = "EightOfClubs",
        emoji = emojis.EightOfClubs,
        value = 8
    },
    {
        name = "NineOfClubs",
        emoji = emojis.NineOfClubs,
        value = 9
    },
    {
        name = "TenOfClubs",
        emoji = emojis.TenOfClubs,
        value = 10
    },
    {
        name = "JackOfClubs",
        emoji = emojis.JackOfClubs,
        value = 10
    },
    {
        name = "QueenOfClubs",
        emoji = emojis.QueenOfClubs,
        value = 10
    },
    {
        name = "KingOfClubs",
        emoji = emojis.KingOfClubs,
        value = 10
    },
    {
        name = "AceOfSpades",
        emoji = emojis.AceOfSpades,
        value = nil
    },
    {
        name = "TwoOfSpades",
        emoji = emojis.TwoOfSpades,
        value = 2
    },
    {
        name = "ThreeOfSpades",
        emoji = emojis.ThreeOfSpades,
        value = 3
    },
    {
        name = "FourOfSpades",
        emoji = emojis.FourOfSpades,
        value = 4
    },
    {
        name = "FiveOfSpades",
        emoji = emojis.FiveOfSpades,
        value = 5
    },
    {
        name = "SixOfSpades",
        emoji = emojis.SixOfSpades,
        value = 6
    },
    {
        name = "SevenOfSpades",
        emoji = emojis.SevenOfSpades,
        value = 7
    },
    {
        name = "EightOfSpades",
        emoji = emojis.EightOfSpades,
        value = 8
    },
    {
        name = "NineOfSpades",
        emoji = emojis.NineOfSpades,
        value = 9
    },
    {
        name = "TenOfSpades",
        emoji = emojis.TenOfSpades,
        value = 10
    },
    {
        name = "JackOfSpades",
        emoji = emojis.JackOfSpades,
        value = 10
    },
    {
        name = "QueenOfSpades",
        emoji = emojis.QueenOfSpades,
        value = 10
    },
    {
        name = "KingOfSpades",
        emoji = emojis.KingOfSpades,
        value = 10
    },
}

local loadingMessages = {
    "Counting how much money you lost...",
    "Ensuring the house always wins...",
    "Burning some cards... hold on.",
    "Preparing your financial ruin...",
    "Calculating your bad decisions...",
    "Reminding the dealer to smirk...",
    "Stacking the deck... allegedly...",
    "Notifying your bank account...",
    "Laughing at your hand...",
    "Polishing the house's trophy...",
    "Are you SHOO-uh... (the dealer is British)",
    "Telling the dealer you're an easy target...",
}

return {
    name = "blackjack",
    description = "Gamble with your money in a game of Blackjack.",
    aliases = {"bj", "bjack"},
    category = "Economy",
    slashCommand = slashCommand,
    requiredPermissions = {"SETUP"},
	hybridCallback = function(interaction, args, slash)
		local config = sqldb:get(interaction.guild.id) or {}
        config.economy = config.economy or {}
        config.economy.accounts = config.economy.accounts or {}
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

		if last and (os.time() - last) < cooldown then
			return interaction:fail("You are on cooldown. Try again in **" .. readable((last + cooldown) - os.time()) .. "**.")
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
        account.cooldowns.gamble = os.time()
		db:ecoModify(interaction.member, {
            balance = account.balance,
            cooldowns = account.cooldowns
        })

		local hand = {}
		local dealersHand = {}

        local stood = false
        local doubledown = false
        local hitBlackjack = false
        local push = false

		local function getValue(dealer)
			local value = 0
			local soft = false
            local amountOfAces = 0

			for _, card in pairs((dealer and dealersHand) or hand) do -- Not Aces
				if card.value then
					value = value + card.value
                else
                    amountOfAces = amountOfAces + 1
				end
			end

			for _, card in pairs((dealer and dealersHand) or hand) do -- Aces
				if not card.value then
					if (value + 11) > 21 then
						value = value + 1

                        if soft and value == 22 and amountOfAces > 1 then -- If first ace makes value 21 (soft) and there are more than 2 aces it needs to be corrected
                            value = value - 10
                            soft = false
                        end
					else
						soft = true
						value = value + 11
					end
				end
			end

			return value, soft
		end


        local function checkResult()
            local player = getValue()
            local dealer = getValue(true)
            local totalBet = (doubledown and bet * 2) or bet

            if player > 21 then
                return false, colors.fail, "You busted and gave up " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(totalBet) .. "**."
            elseif dealer > 21 then
                return true, colors.success, "The dealer busted and you earned " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(totalBet) .. "**."
            elseif player == 21 and #hand == 2 then
                hitBlackjack = true
                return true, colors.success, "You hit blackjack and you earned " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(bet + math.floor(bet * 1.5)) .. "**."
            elseif player == 21 then
                return true, colors.success, "You hit 21 and you earned " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(bet) .. "**."
            elseif dealer == 21 then
                return false, colors.fail, "The dealer hit blackjack and you gave up " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(bet) .. "**."
            elseif stood and player == dealer then
                push = true
                return false, colors.warning, "It's a push, your " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(totalBet) .. "** returns to your pocket."
            elseif stood and math.abs(player - 21) < math.abs(dealer - 21) then
                return true, colors.success, "You won and earned " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(totalBet) .. "**."
            elseif stood and math.abs(dealer - 21) < math.abs(player - 21) then
                return false, colors.fail, "You lost and gave up " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(totalBet) .. "**."
            end
        end

		local function hit(dealer)
            for i, c in pairs((dealer and dealersHand) or hand) do
                if c.name == "CardBack" then
                    table.remove((dealer and dealersHand) or hand, i)
                    break
                end
            end

			local card = cards[math.random(1, #cards)]
            table.insert((dealer and dealersHand) or hand, card)
			return card
		end

        local function stand()
            local val, soft
            repeat
                hit(true)
                val, soft = getValue(true)
            until val >= 17

            stood = true
        end

		local function getHand(dealer)
			local str = ""
			local value, soft = getValue(dealer)

			for _, card in pairs((dealer and dealersHand) or hand) do
				str = str .. card.emoji .. " "
			end

			return str, (soft and ("Soft " .. value)) or value
		end

        local r

        local function updateEmbed(ia)
            ia = ia or r

            local handString, val = getHand()
            local dealersHandString, dealersVal = getHand(true)
            local win, color, reason = checkResult()
            local totalBet = (doubledown and bet * 2) or bet
            local winnings = (doubledown and bet * 2) or bet
            local totalReturn = winnings + totalBet

            local toupd = {
                embed = {
                    author = author(interaction.member),
                    title = emojis.CardBack .. " Blackjack",
                    description = emojis.person .. " **Your Hand:** " .. val .. "\n" .. emojis.right .. " " .. handString .. "\n\n" .. emojis.person .. " **Dealer's Hand:** " .. dealersVal .. "\n" .. emojis.right .. " " .. dealersHandString,
                    color = colors.info
                },
                components = discordia.Components()
                    :button({ id = "hit", label = "Hit", style = "blurple", disabled = win ~= nil or doubledown })
                    :button({ id = "stand", label = "Stand", style = "blurple", disabled = win ~= nil or doubledown })
                    :button({ id = "doubledown", label = "Double Down", style = "secondary", disabled = (win ~= nil) or (account.balance.wallet < bet) or (#hand > 2) or doubledown })
                    :raw()
            }

            if win == true then
                toupd.embed.color = color
                toupd.embed.description = toupd.embed.description .. "\n\n" .. reason .. (doubledown and " (Double Down)" or "")
                if hitBlackjack and #hand == 2 then
                    account.balance.wallet = account.balance.wallet + (bet + math.floor(bet * 1.5))
                    db:ecoBalance(interaction.member, "wallet", account.balance.wallet)
                else
                    account.balance.wallet = account.balance.wallet + totalReturn
                    db:ecoBalance(interaction.member, "wallet", account.balance.wallet)
                end
            elseif win == false then
                toupd.embed.color = color
                toupd.embed.description = toupd.embed.description .. "\n\n" .. reason
                if push then
                    account.balance.wallet = account.balance.wallet + totalBet
                    db:ecoBalance(interaction.member, "wallet", account.balance.wallet)
                end
            else
                toupd.embed.description = toupd.embed.description .. "\n\n" .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(totalBet) .. "** is on the line..."
            end

            if type(ia) == "table" then
                return ia:update(toupd)
            else
                r = interaction:reply(toupd)
            end
        end

		hit()
		hit()
        hit(true)
        table.insert(dealersHand, {
            name = "CardBack",
            emoji = emojis.CardBack,
            value = 0
        })

		updateEmbed()

		onComp(r, nil, nil, interaction.user.id, false, function(ia)
			local id = ia.data.custom_id

            local lm = ia:loading(loadingMessages[math.random(1, #loadingMessages)], true)

            if type(lm) ~= "table" then
                return ia:fail("Something went wrong, try again.", nil, true)
            end

			if id == "hit" then
				hit()
				updateEmbed()
                ia:deleteReply(lm.id)
            elseif id == "stand" then
				stand()
                updateEmbed()
                ia:deleteReply(lm.id)
            elseif id == "doubledown" then
                if account.balance.wallet < bet then
                    ia:deleteReply(lm.id)
                    return ia:fail("You do not have enough money to double down.", nil, true)
                end
                account.balance.wallet = account.balance.wallet - bet
                db:ecoBalance(interaction.member, "wallet", account.balance.wallet)
                doubledown = true
                hit()
                stand()
                updateEmbed()
                ia:deleteReply(lm.id)
			end
		end)
	end
}