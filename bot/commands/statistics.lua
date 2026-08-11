-- statistics.lua

return {
	name = "statistics",
	description = "Statistical data for the Development team.",
	aliases = { "stats" },
	category = "Utility",
	requiredPermissions = { "BOT_DEVELOPER" },
	hybridCallback = function(interaction, args, slash, subcmd)
		local now = realtime()
		local pages = {}

		-- Ducky Plus+
		local succ, allPlus = sqldb:plusAll()

		if not succ then
			return interaction:fail("Failed to get " .. emojis.duckyplus .. " **Ducky Plus+** data.")
		end

		local plusSalesInRobux = {
			week = 0,
			month = 0,
			quarter = 0,
			all = 0,
		}

		for _, plus in pairs(allPlus) do
			if type(plus) == "table" and type(plus.transactions) == "table" and next(plus.transactions) then
				for _, transaction in pairs(plus.transactions) do
					plusSalesInRobux.all = plusSalesInRobux.all + transaction.paid
					if now - transaction.timestamp <= 60 * 60 * 24 * 7 then
						plusSalesInRobux.week = plusSalesInRobux.week + transaction.paid
					end
					if now - transaction.timestamp <= 60 * 60 * 24 * 30 then
						plusSalesInRobux.month = plusSalesInRobux.month + transaction.paid
					end
					if now - transaction.timestamp <= 60 * 60 * 24 * 30 * 3 then
						plusSalesInRobux.quarter = plusSalesInRobux.quarter + transaction.paid
					end
				end
			end
		end

		local plusSalesInRobuxTaxed = {
			week = math.round(plusSalesInRobux.week * 0.7),
			month = math.round(plusSalesInRobux.month * 0.7),
			quarter = math.round(plusSalesInRobux.quarter * 0.7),
			all = math.round(plusSalesInRobux.all * 0.7),
		}

		local euroPerRobuxDevExRate = 0.003262
		local dollarPerRobuxDevExRate = 0.0038

		local plusSalesInDevEx = {
			usd = {
				week = string.format("%.2f", math.round(plusSalesInRobuxTaxed.week * dollarPerRobuxDevExRate, 2)),
				month = string.format("%.2f", math.round(plusSalesInRobuxTaxed.month * dollarPerRobuxDevExRate, 2)),
				quarter = string.format("%.2f", math.round(plusSalesInRobuxTaxed.quarter * dollarPerRobuxDevExRate, 2)),
				all = string.format("%.2f", math.round(plusSalesInRobuxTaxed.all * dollarPerRobuxDevExRate, 2)),
			},
			euro = {
				week = string.format("%.2f", math.round(plusSalesInRobuxTaxed.week * euroPerRobuxDevExRate, 2)),
				month = string.format("%.2f", math.round(plusSalesInRobuxTaxed.month * euroPerRobuxDevExRate, 2)),
				quarter = string.format("%.2f", math.round(plusSalesInRobuxTaxed.quarter * euroPerRobuxDevExRate, 2)),
				all = string.format("%.2f", math.round(plusSalesInRobuxTaxed.all * euroPerRobuxDevExRate, 2)),
			},
		}

		local total_shares = 1000
		local monthly_costs = 14.5
		local year_value = (plusSalesInRobuxTaxed.quarter * euroPerRobuxDevExRate * 4) - (monthly_costs * 12)
		local market_value = year_value * 1.5
		local share_value = market_value / total_shares

		table.insert(pages, {
			title = emojis.duckyplus .. " **Ducky Plus+** Revenue",
			color = colors.yellow,
			description = emojis.right
				.. " **Last 7 Days**\n"
				.. emojis.space
				.. emojis.right
				.. " "
				.. emojis.robux
				.. " **"
				.. formatNumber(plusSalesInRobuxTaxed.week)
				.. "** ("
				.. emojis.robux
				.. " **"
				.. formatNumber(plusSalesInRobux.week)
				.. "** before tax)\n"
				.. emojis.space
				.. emojis.right
				.. " "
				.. " **$"
				.. formatNumber(plusSalesInDevEx.usd.week)
				.. "** (DevEx USD)\n"
				.. emojis.space
				.. emojis.right
				.. " "
				.. " **€"
				.. formatNumber(plusSalesInDevEx.euro.week)
				.. "** (DevEx Euro)\n\n"
				.. emojis.right
				.. " **Last 30 Days**\n"
				.. emojis.space
				.. emojis.right
				.. " "
				.. emojis.robux
				.. " **"
				.. formatNumber(plusSalesInRobuxTaxed.month)
				.. "** ("
				.. emojis.robux
				.. " **"
				.. formatNumber(plusSalesInRobux.month)
				.. "** before tax)\n"
				.. emojis.space
				.. emojis.right
				.. " "
				.. " **$"
				.. formatNumber(plusSalesInDevEx.usd.month)
				.. "** (DevEx USD)\n"
				.. emojis.space
				.. emojis.right
				.. " "
				.. " **€"
				.. formatNumber(plusSalesInDevEx.euro.month)
				.. "** (DevEx Euro)\n\n"
				.. emojis.right
				.. " **Last 90 Days**\n"
				.. emojis.space
				.. emojis.right
				.. " "
				.. emojis.robux
				.. " **"
				.. formatNumber(plusSalesInRobuxTaxed.quarter)
				.. "** ("
				.. emojis.robux
				.. " **"
				.. formatNumber(plusSalesInRobux.quarter)
				.. "** before tax)\n"
				.. emojis.space
				.. emojis.right
				.. " "
				.. " **$"
				.. formatNumber(plusSalesInDevEx.usd.quarter)
				.. "** (DevEx USD)\n"
				.. emojis.space
				.. emojis.right
				.. " "
				.. " **€"
				.. formatNumber(plusSalesInDevEx.euro.quarter)
				.. "** (DevEx Euro)\n\n"
				.. emojis.right
				.. " **All Time**\n"
				.. emojis.space
				.. emojis.right
				.. " "
				.. emojis.robux
				.. " **"
				.. formatNumber(plusSalesInRobuxTaxed.all)
				.. "** ("
				.. emojis.robux
				.. " **"
				.. formatNumber(plusSalesInRobux.all)
				.. "** before tax)\n"
				.. emojis.space
				.. emojis.right
				.. " "
				.. " **$"
				.. formatNumber(plusSalesInDevEx.usd.all)
				.. "** (DevEx USD)\n"
				.. emojis.space
				.. emojis.right
				.. " "
				.. " **€"
				.. formatNumber(plusSalesInDevEx.euro.all)
				.. "** (DevEx Euro)\n"
				.. emojis.right .. " **Stonks**\n"
				.. "-# " .. emojis.space .. emojis.right .. " ***Total shares: " .. total_shares .. "***\n"
				.. emojis.space .. emojis.right .. " **Market value: €" .. formatNumber(market_value) .. "**\n"
				.. emojis.space .. emojis.right .. " **Share value: €" .. formatNumber(share_value) .. "**",
			identifier = {
				text = "Ducky Plus+ Revenue",
				emoji = resolvedEmojis.duckyplus,
			},
		})

		-- Guilds
		local newGuilds = {
			week = 0,
			prevWeek = 0,
			month = 0,
			prevMonth = 0,
			quarter = 0,
			prevQuarter = 0,
			all = table.count(Client.guilds:toArray()),
		}

		local SECONDS_WEEK = 60 * 60 * 24 * 7
		local SECONDS_MONTH = 60 * 60 * 24 * 30
		local SECONDS_QUARTER = SECONDS_MONTH * 3

		for guild in Client.guilds:iter() do
			local joinedAt = guild.joinedAt and discordia.Date.fromISO(guild.joinedAt):toSeconds() or 0
			local age = now - joinedAt

			if age <= SECONDS_WEEK then
				newGuilds.week = newGuilds.week + 1
			end
			if age <= SECONDS_MONTH then
				newGuilds.month = newGuilds.month + 1
			end
			if age <= SECONDS_QUARTER then
				newGuilds.quarter = newGuilds.quarter + 1
			end

			if age > SECONDS_WEEK and age <= (SECONDS_WEEK * 2) then
				newGuilds.prevWeek = newGuilds.prevWeek + 1
			end
			if age > SECONDS_MONTH and age <= (SECONDS_MONTH * 2) then
				newGuilds.prevMonth = newGuilds.prevMonth + 1
			end
			if age > SECONDS_QUARTER and age <= (SECONDS_QUARTER * 2) then
				newGuilds.prevQuarter = newGuilds.prevQuarter + 1
			end
		end

		local function getGrowth(new, prev)
			if prev == 0 then
				return new > 0 and 100 or 0
			end
			return math.round(((new - prev) / prev) * 100)
		end

		newGuilds.diffWeek = getGrowth(newGuilds.week, newGuilds.prevWeek)
		newGuilds.diffMonth = getGrowth(newGuilds.month, newGuilds.prevMonth)
		newGuilds.diffQuarter = getGrowth(newGuilds.quarter, newGuilds.prevQuarter)

		table.insert(pages, {
			title = emojis.guild .. " **Guilds** Growth",
			color = colors.yellow,
			description = emojis.right
				.. " **Last 7 Days:** "
				.. formatNumber(newGuilds.week)
				.. "\n"
				.. emojis.space
				.. emojis.right
				.. " That is **"
				.. indicateNumber(newGuilds.diffWeek)
				.. "%** compared to last week."
				.. "\n"
				.. emojis.right
				.. " **Last 30 Days:** "
				.. formatNumber(newGuilds.month)
				.. "\n"
				.. emojis.space
				.. emojis.right
				.. " That is **"
				.. indicateNumber(newGuilds.diffMonth)
				.. "%** compared to last month."
				.. "\n"
				.. emojis.right
				.. " **Last 90 Days:** "
				.. formatNumber(newGuilds.quarter)
				.. "\n"
				.. emojis.space
				.. emojis.right
				.. " That is **"
				.. indicateNumber(newGuilds.diffQuarter)
				.. "%** compared to last quarter."
				.. "\n"
				.. emojis.right
				.. " **All Time:** "
				.. formatNumber(newGuilds.all),
			identifier = {
				text = "Guilds Growth",
				emoji = resolvedEmojis.guild,
			},
		})

		paginate(interaction, pages, interaction.user, {
			teleport = true,
			clamp = false,
			startPage = 1,
		})
	end,
}
