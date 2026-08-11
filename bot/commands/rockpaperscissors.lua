-- rockpaperscissors.lua
local slashCommand = tools.slashCommand("rockpaperscissors", "Play a game of Rock, Paper, Scissors.")
slashCommand = slashCommand:addOption(tools.user("member", "Duel a member in a game of Rock, Paper, Scissors."))

return {
	name = "rockpaperscissors",
	description = "Play a game of Rock, Paper, Scissors.",
	aliases = {
		"rps"
	},
	requiredPermissions = {},
	slashCommand = slashCommand,
	category = "Fun",
	hybridCallback = function(interaction, args, slash)
		local member, user = fetchMemberFromInteraction(interaction, args, slash)

		if ((slash and args and args.member) or ((not slash) and args and args[1])) and (not member) then
			return interaction:fail("I could not find that member.", nil, true)
		end

		if member and member.id == interaction.user.id then
			return interaction:fail("You cannot play against yourself.", nil, true)
		elseif member and member.bot then
			if member.id == Client.user.id then
				member = nil
			else
				return interaction:fail("You cannot play against a bot.", nil, true)
			end
		end

		local choices = {
			"rock",
			"paper",
			"scissors"
		}

		local components = discordia.Components():button({
			id = "rock",
			label = "Rock",
			style = "blurple"
		}):button({
			id = "paper",
			label = "Paper",
			style = "blurple"
		}):button({
			id = "scissors",
			label = "Scissors",
			style = "blurple"
		})

		if member then
			local p1 = interaction.user
			local p2 = member
			local p1Choice, p2Choice

			local p1Msg = interaction:reply({
				embed = {
					description = emojis.loading .. " Rock, Paper, Scissors against " .. getUserString(p2) .. "...",
					color = colors.blank,
					author = author(p1)
				},
				components = components:raw()
			})

			local p2Msg = interaction.channel:send({
				embed = {
					description = emojis.loading .. " Rock, Paper, Scissors against " .. getUserString(p1) .. "...",
					color = colors.blank,
					author = author(p2)
				},
				components = components:raw()
			})

			local function checkFinish()
				if p1Choice and p2Choice then
					local p1ResultDesc, p1Color
					local p2ResultDesc, p2Color

					if p1Choice == p2Choice then
						p1ResultDesc = emojis.warning .. " Shoot!\n-# " .. emojis.right .. " It's a draw, You both chose **" .. string.capitalize(p1Choice) .. "**."
						p2ResultDesc = p1ResultDesc
						p1Color, p2Color = colors.warning, colors.warning

					elseif (p1Choice == "rock" and p2Choice == "scissors") or (p1Choice == "paper" and p2Choice == "rock") or (p1Choice == "scissors" and p2Choice == "paper") then
						-- p1 wins
						p1ResultDesc = emojis.success .. " Shoot!\n-# " .. emojis.right .. " You win, your **" .. string.capitalize(p1Choice) .. "** beats " .. getUserString(p2) .. "'s **" .. string.capitalize(p2Choice) .. "**."
						p2ResultDesc = emojis.fail .. " Shoot!\n-# " .. emojis.right .. " You lose, " .. getUserString(p1) .. "'s **" .. string.capitalize(p1Choice) .. "** beats your **" .. string.capitalize(p2Choice) .. "**."
						p1Color, p2Color = colors.success, colors.fail

					else
						-- p2 wins
						p1ResultDesc = emojis.fail .. " Shoot!\n-# " .. emojis.right .. " You lose, " .. getUserString(p2) .. "'s **" .. string.capitalize(p2Choice) .. "** beats your **" .. string.capitalize(p1Choice) .. "**."
						p2ResultDesc = emojis.success .. " Shoot!\n-# " .. emojis.right .. " You win, your **" .. string.capitalize(p2Choice) .. "** beats " .. getUserString(p1) .. "'s **" .. string.capitalize(p1Choice) .. "**."
						p1Color, p2Color = colors.fail, colors.success
					end

					p1Msg:update({
						embed = {
							description = p1ResultDesc,
							color = p1Color,
							author = author(p1)
						},
						components = {}
					})

					p2Msg:update({
						embed = {
							description = p2ResultDesc,
							color = p2Color,
							author = author(p2)
						},
						components = {}
					})
				end
			end

			onComp(p1Msg, "button", nil, p1.id, true, function(ia)
				if p1Choice then
					return
				end
				p1Choice = ia.data.custom_id
				ia:update({
					embed = {
						description = emojis.loading .. " Waiting for " .. getUserString(p2) .. " to choose...",
						color = colors.yellow,
						author = author(p1)
					},
					components = {}
				})
				checkFinish()
			end)

			onComp(p2Msg, "button", nil, p2.id, true, function(ia)
				if p2Choice then
					return
				end
				p2Choice = ia.data.custom_id
				ia:update({
					embed = {
						description = emojis.loading .. " Waiting for " .. getUserString(p1) .. " to choose...",
						color = colors.yellow,
						author = author(p2)
					},
					components = {}
				})
				checkFinish()
			end)

		else
			local msg = interaction:reply({
				embed = {
					description = emojis.loading .. " Rock, Paper, Scissors...",
					color = colors.blank,
					author = author(interaction.user)
				},
				components = components:raw()
			})

			onComp(msg, "button", nil, interaction.user.id, true, function(ia)
				local player = ia.data.custom_id
				local bot = choices[math.random(1, #choices)]

				local desc, color
				if player == bot then
					desc = emojis.warning .. " Shoot!\n-# " .. emojis.right .. " It's a draw, we both chose **" .. string.capitalize(bot) .. "**."
					color = colors.warning
				elseif (player == "rock" and bot == "scissors") or (player == "paper" and bot == "rock") or (player == "scissors" and bot == "paper") then
					desc = emojis.success .. " Shoot!\n-# " .. emojis.right .. " You win, your **" .. string.capitalize(player) .. "** beats my **" .. string.capitalize(bot) .. "**."
					color = colors.success
				else
					desc = emojis.fail .. " Shoot!\n-# " .. emojis.right .. " You lose, my **" .. string.capitalize(bot) .. "** beats your **" .. string.capitalize(player) .. "**."
					color = colors.fail
				end

				ia:update({
					embed = {
						description = desc,
						color = color,
						author = author(interaction.user)
					},
					components = {}
				})
			end)
		end
	end
}
