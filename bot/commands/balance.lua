-- balance.lua
local slashCommand = tools.slashCommand("balance", "View your balance.")
slashCommand = slashCommand:addOption(tools.user("user", "View the balance of a specific user."))

return {
	name = "balance",
	description = "Show how many quacks you have.",
	aliases = {
		"bal",
	},
	category = "Economy",
	slashCommand = slashCommand,
	requiredPermissions = {},
	hybridCallback = function(interaction, args, slash)
		local guild = interaction.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		
		if config.economy and config.economy.disabled then
			return interaction:fail("The " .. emojis.quack .. " **Economy** module is not enabled in this server.")
		end

		local member = fetchMemberFromInteraction(interaction, args, slash) or interaction.member
		local identifier = ((member and member.id == interaction.user.id) and "Your") or ((member and member.id ~= interaction.user.id) and getUserString(member.user) .. "'s")

		local account, err = db:ecoFetch(member)
		if not account then
			return interaction:fail(err, nil, true)
		end

		local r = interaction:loading()

		local function updatePanel(ia)
			ia = ia or r
			
			if account then
				return ia:update({
					embed = {
						title = (config.economy.currency or emojis.quack) .. " " .. identifier .. " Balance",
						author = author(member),
						color = colors.info,
						description = emojis.right .. " **Wallet:** " .. (config.economy.currency or emojis.quack) .. " " .. (account.balance and account.balance.wallet and (formatNumber(tonumber(account.balance.wallet)))) .. "\n" .. emojis.right .. " **Bank:** " .. (config.economy.currency or emojis.quack) .. " " .. (account.balance and account.balance.bank and (formatNumber(tonumber(account.balance.bank))))
					},
					components = (hasPermission(interaction.member, "MANAGE_SERVER") == true and discordia.Components():selectMenu({
						id = "actions",
						placeholder = "Manage balance...",
						actionRow = 1,
						options = {
							{
								label = "Edit Balance",
								value = "edit",
								emoji = resolvedEmojis.edit
							},
							{
								label = "Reset Balance",
								value = "reset",
								emoji = resolvedEmojis.delete
							},
							{
								label = "Reset Account",
								value = "resetaccount",
								emoji = resolvedEmojis.delete
							}
						}
					}):raw()) or {}
				})
			else
				return ia:update({
					embed = {
						description = emojis.delete .. " " .. identifier .. " economy data has been wiped.",
						color = colors.fail
					},
					components = {}
				})
			end
		end

		updatePanel()

		onComp(r, nil, nil, interaction.user.id, false, function(ia)
			local id = ia.data.custom_id
			local selections = ia.data.values
			local first = selections and selections[1]

			if first == "edit" then
				prompt(ia, "Edit Balance", {
					{
						question = "Wallet Balance",
						placeholder = "Append +/- before the number to add/subtract balance.",
						style = "short",
						required = false
					},
					{
						question = "Bank Balance",
						placeholder = "Append +/- before the number to add/subtract balance.",
						style = "short",
						required = false
					}
				}, function(mia, responses)
					if mia then
						if responses and (responses["Wallet Balance"] or responses["Bank Balance"]) then
							if responses["Wallet Balance"] then
								if responses["Wallet Balance"]:usub(1, 1) == "+" and tonumber(responses["Wallet Balance"]:usub(2)) then
									local oldBal = account.balance.wallet
									local success, err = db:ecoBalance(member, "wallet", account.balance.wallet + tonumber(responses["Wallet Balance"]:usub(2)))
									if not success then
										mia:fail(err, nil, true)
										return updatePanel()
									end

									db:send(interaction.guild.id, "economylogchannel", {
										embed = {
											title = emojis.edit .. " Account Balance Modified",
											author = author(member),
											color = colors.yellow,
											description = getUserString(member) .. "'s wallet balance was edited by " .. getUserString(interaction.user) .. "." .. "\n" .. 
											  emojis.space .. emojis.right .. " **Previous Balance:** " .. formatNumber(oldBal) .. "\n" ..
											  emojis.space .. emojis.right .. " **New Balance:** " .. formatNumber(oldBal + tonumber(responses["Wallet Balance"])) .. " (+" .. formatNumber(tonumber(responses["Wallet Balance"]:usub(2))) .. ")"
										}
									})

									account = success
								elseif responses["Wallet Balance"]:usub(1, 1) == "-" and tonumber(responses["Wallet Balance"]:usub(2)) then									
									local oldBal = account.balance.wallet
									local success, err = db:ecoBalance(member, "wallet", account.balance.wallet - tonumber(responses["Wallet Balance"]:usub(2)))
									if not success then
										mia:fail(err, nil, true)
										return updatePanel()
									end

									db:send(interaction.guild.id, "economylogchannel", {
										embed = {
											title = emojis.edit .. " Account Balance Modified",
											author = author(member),
											color = colors.yellow,
											description = getUserString(member) .. "'s wallet balance was edited by " .. getUserString(interaction.user) .. "." .. "\n" .. 
											  emojis.space .. emojis.right .. " **Previous Balance:** " .. formatNumber(oldBal) .. "\n" ..
											  emojis.space .. emojis.right .. " **New Balance:** " .. formatNumber(oldBal + tonumber(responses["Wallet Balance"])) .. " (-" .. formatNumber(tonumber(responses["Wallet Balance"]:usub(2))) .. ")"
										}
									})

									account = success
								elseif tonumber(responses["Wallet Balance"]) then
									local oldBal = account.balance.wallet
									local success, err = db:ecoBalance(member, "wallet", tonumber(responses["Wallet Balance"]))
									if not success then
										mia:fail(err, nil, true)
										return updatePanel()
									end

									db:send(interaction.guild.id, "economylogchannel", {
										embed = {
											title = emojis.edit .. " Account Balance Modified",
											author = author(member),
											color = colors.yellow,
											description = getUserString(member) .. "'s wallet balance was edited by " .. getUserString(interaction.user) .. "." .. "\n" .. 
											  emojis.space .. emojis.right .. " **Previous Balance:** " .. formatNumber(oldBal) .. "\n" ..
											  emojis.space .. emojis.right .. " **New Balance:** " .. formatNumber(tonumber(responses["Wallet Balance"]))
										}
									})

									account = success
								else
									return mia:fail("You did not provide a valid wallet balance.", nil, true)
								end
							end

							if responses["Bank Balance"] then
								if responses["Bank Balance"]:usub(1, 1) == "+" and tonumber(responses["Bank Balance"]:usub(2)) then
									local oldBal = account.balance.bank
									local success, err = db:ecoBalance(member, "bank", account.balance.bank + tonumber(responses["Bank Balance"]:usub(2)))
									if not success then
										mia:fail(err, nil, true)
										return updatePanel()
									end

									db:send(interaction.guild.id, "economylogchannel", {
										embed = {
											title = emojis.edit .. " Account Balance Modified",
											author = author(member),
											color = colors.yellow,
											description = getUserString(member) .. "'s bank balance was edited by " .. getUserString(interaction.user) .. "." .. "\n" .. 
											  emojis.space .. emojis.right .. " **Previous Balance:** " .. formatNumber(oldBal) .. "\n" ..
											  emojis.space .. emojis.right .. " **New Balance:** " .. formatNumber(oldBal + tonumber(responses["Bank Balance"])) .. " (+" .. formatNumber(tonumber(responses["Bank Balance"]:usub(2))) .. ")"
										}
									})

									account = success
								elseif responses["Bank Balance"]:usub(1, 1) == "-" and tonumber(responses["Bank Balance"]:usub(2)) then
									local oldBal = account.balance.bank
									local success, err = db:ecoBalance(member, "bank", account.balance.bank - tonumber(responses["Bank Balance"]:usub(2)))
									if not success then
										mia:fail(err, nil, true)
										return updatePanel()
									end

									db:send(interaction.guild.id, "economylogchannel", {
										embed = {
											title = emojis.edit .. " Account Balance Modified",
											author = author(member),
											color = colors.yellow,
											description = getUserString(member) .. "'s bank balance was edited by " .. getUserString(interaction.user) .. "." .. "\n" .. 
											  emojis.space .. emojis.right .. " **Previous Balance:** " .. formatNumber(oldBal) .. "\n" ..
											  emojis.space .. emojis.right .. " **New Balance:** " .. formatNumber(oldBal + tonumber(responses["Bank Balance"])) .. " (-" .. formatNumber(tonumber(responses["Bank Balance"]:usub(2))) .. ")"
										}
									})

									account = success
								elseif tonumber(responses["Bank Balance"]) then
									local oldBal = account.balance.bank
									local success, err = db:ecoBalance(member, "bank", tonumber(responses["Bank Balance"]))
									if not success then
										mia:fail(err, nil, true)
										return updatePanel()
									end

									db:send(interaction.guild.id, "economylogchannel", {
										embed = {
											title = emojis.edit .. " Account Balance Modified",
											author = author(member),
											color = colors.yellow,
											description = getUserString(member) .. "'s bank balance was edited by " .. getUserString(interaction.user) .. "." .. "\n" .. 
											  emojis.space .. emojis.right .. " **Previous Balance:** " .. formatNumber(oldBal) .. "\n" ..
											  emojis.space .. emojis.right .. " **New Balance:** " .. formatNumber(tonumber(responses["Bank Balance"]))
										}
									})

									account = success
								else
									return mia:fail("You did not provide a valid wallet balance.", nil, true)
								end
							end
							
							mia:updateDeferred(true)
							return updatePanel()
						else
							return mia:updateDeferred(true)
						end
					end
				end, false)
			elseif first == "reset" then
				confirm(ia, "Are you sure you want to reset " .. getUserString(member) .. "'s balance?", function(confirm, ria)
					if confirm then
						account.balance.wallet = 0
						account.balance.bank = 0
						local success, err = db:ecoModify(member, {balance = account.balance})
						if not success then
							return ria:fail(err, nil, true)
						end

						db:send(interaction.guild.id, "economylogchannel", {
							embed = {
								title = emojis.delete .. " Economy Balance Reset",
								author = author(member),
								color = colors.fail,
								description = getUserString(member) .. "'s balance has been reset by " .. getUserString(interaction.user) .. "."
							}
						})

						ria:updateDeferred(true)
						return updatePanel(nil, true)
					end
				end, true, 5000)
			elseif first == "resetaccount" then
				confirm(ia, "Are you sure you want to wipe all economy data for " .. getUserString(member) .. "?", function(confirm, ria)
					if confirm then
						local success, err = db:ecoDelete(member)
						if not success then
							return ria:fail(err, nil, true)
						end

						db:send(interaction.guild.id, "economylogchannel", {
							embed = {
								title = emojis.delete .. " Economy Account Deleted",
								author = author(member),
								color = colors.fail,
								description = getUserString(member) .. "'s economy account data has been deleted by " .. getUserString(interaction.user) .. "."
							}
						})

						ria:updateDeferred(true)
						return updatePanel(nil, true)
					end
				end, true, 5000)
			end
		end)
	end
}
