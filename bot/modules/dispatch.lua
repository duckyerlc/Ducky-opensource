-- modules/dispatch.lua
local dispatch = {
	name = "dispatch",
	description = "Distributes Client events to all modules."
}

local connections = {}

dispatch.Start = function()
	connections["messageCommand"] = Client:on("messageCommand", function(interaction, command, message)
		coroutine.wrap(function()
			if not interaction or not interaction.guild or not interaction.reply or not interaction.member or not interaction.user or not message or not command or not command.name or not message.guild or not message.channel or (blacklisted(interaction.member)) then
				return
			end

			if command.name == "Export Message" then
				if not sqldb:plusGuild(interaction.guild) then
					return interaction:fail("This is a " .. emojis.duckyplus .. " **Ducky Plus+** feature.", nil, true)
				elseif not (message.content or (message.embeds and message.embeds[1]) or message.embed) then
					return interaction:fail("This message does not have content nor embeds.", nil, true)
				end

				local data = {
					content = message.content,
					embeds = message.embeds or (message.embed and {message.embed})
				}

				prompt(interaction, "Exportable Name", {
					{
						question = "What should this exportable be named?",
						placeholder = "Enter a name for this exportable...",
						style = "short",
						max = 100
					}
				}, function(mia, responses)
					local exported, err = export(data, mia.user, "message", responses["What should this exportable be named?"])

					if exported then
						return mia:success("This message has been exported successfully! Here's your exportable code: ```\n" .. exported .. "```\n-# " .. emojis.right .. " You can share this code with other people for them to import this message.", nil, true)
					else
						return mia:fail("An unexpected error occurred while exporting this message: " .. tostring(err), nil, true)
					end
				end, true)
			elseif command.name == "Export Embed" then
				if not sqldb:plusMember(interaction.member) then
					return interaction:fail("This is a " .. emojis.duckyplus .. " **Ducky Plus+** feature.", nil, true)
				end

				if message.embeds and table.count(message.embeds) > 0 and message.embeds[1] then
					if table.count(message.embeds) > 1 then
						local selmenuopts = {}

						for c, emb in pairs(message.embeds) do
							table.insert(selmenuopts, {
								label = "Embed " .. c,
								value = tostring(c),
								description = emb.title and emb.title ~= "" and emb.title,
								emoji = resolvedEmojis.export
							})
						end

						local r = interaction:reply({
							components = discordia.Components():selectMenu({
								id = "embselect",
								placeholder = "Select an embed to export...",
								options = selmenuopts,
								actionRow = 1
							})
						}, true)

						onComp(r, "selectMenu", "embselect", interaction.user.id, false, function(ia)
							local selection = ia.data.values and ia.data.values[1]

							if selection then
								local embed = message.embeds[tonumber(selection)]

								if embed then
									prompt(interaction, "Exportable Name", {
										{
											question = "What should this exportable be named?",
											placeholder = "Enter a name for this exportable...",
											style = "short",
											max = 100
										}
									}, function(mia, responses)
										local exported, err = export(embed, ia.user, "embed", responses["What should this exportable be named?"])

										if exported then
											mia:updateDeferred(true)
											ia:update({
												embed = {
													description = emojis.success .. " Your embed has been exported successfully! Here's your exportable code: ```\n" .. exported .. "```\n-# " .. emojis.right .. " You can share this code with other people for them to import your embed.",
													color = colors.success
												},
												components = {}
											})
										else
											mia:updateDeferred(true)
											ia:update({
												embed = {
													description = emojis.fail .. " " .. err,
													color = colors.fail
												},
												components = {}
											})
										end
										return true
									end, true)
								else
									ia:fail("That embed could not be found.", nil, true)
									return
								end
							else
								ia:fail("You did not select an embed to export.", nil, true)
								return
							end
						end)
					elseif table.count(message.embeds) == 1 then
						local embed = message.embeds[1]

						prompt(interaction, "Exportable Name", {
							{
								question = "What should this exportable be named?",
								placeholder = "Enter a name for this exportable...",
								style = "short",
								max = 100
							}
						}, function(mia, responses)
							local exported, err = export(embed, mia.user, "embed", responses["What should this exportable be named?"])

							if exported then
								return mia:success("This message has been exported successfully! Here's your exportable code: ```\n" .. exported .. "```\n-# " .. emojis.right .. " You can share this code with other people for them to import this message.", nil, true)
							else
								return mia:fail("An unexpected error occurred while exporting this message: " .. tostring(err), nil, true)
							end
						end, true)
					end
				else
					return interaction:fail("That message does not have any embeds.", nil, true)
				end
			elseif command.name == "Send to Reaction Board" then
				local config = sqldb:get(interaction.guild.id) or {}

				if not hasPermission(interaction.member, "MANAGE_SERVER", config, interaction) then
					return
				end

				local opts = {}

				for id, board in pairs(config.reactionboards or {}) do
					if not board.disabled then
						local channel = interaction.guild:getChannel(board.channel)

						if channel then
							table.insert(opts, {
								label = string.truncate("Send to #" .. channel.name, 100),
								value = tostring(id),
								emoji = resolvedEmojis.send
							})
						end
					end
				end

				if table.count(opts) > 0 then
					local r = interaction:reply({
						components = discordia.Components():selectMenu({
							id = "boardselect",
							placeholder = "Select a reaction board...",
							min_values = 1,
							max_values = 1,
							options = opts
						}):raw()
					}, true)

					onComp(r, nil, nil, interaction.user.id, false, function(ia)
						local id = ia.data.custom_id
						local selections = ia.data.values
						local first = selections and selections[1]

						if id == "boardselect" then
							local board = config.reactionboards[tonumber(first)]

							if board then
								local channel = interaction.guild:getChannel(board.channel)

								if channel then
									message:addReaction(board.reaction)

									channel:send({
										content = "-# " .. emojis.right .. " " .. message.link,
										embed = {
											author = author(message.member),
											description = contentString(message),
											image = (message.attachment and {
												url = message.attachment.url
											}) or (message.embed and message.embed.image) or (message.embed and message.embed.thumbnail),
											color = colors.info,
											timestamp = toISO(os.time()),
											footer = {
												text = "Sent to reaction board by " .. interaction.member.name,
												icon_url = interaction.member.avatarURL
											}
										}
									})

									ia:update({
										embed = {
											description = emojis.success .. " This message has been successfully sent to " .. channel.mentionString .. ".",
											color = colors.success
										},
										components = {}
									})
									return true
								else
									return ia:fail("That reaction board's channel no longer exists.", nil, true)
								end
							else
								return ia:fail("You did not select a valid reaction board.", nil, true)
							end
						end
					end)
				else
					return interaction:fail("This server does not have any reaction boards configured/enabled.", nil, true)
				end
			elseif command.name == "Mark as Valuable" then
				local config = sqldb:get(interaction.guild.id) or {}

				if not hasPermission(interaction.member, "MANAGE_SERVER", config, interaction) then
					return
				end

				config.valuablemessages = config.valuablemessages or {}

				if not table.find(config.valuablemessages, message.channel.id .. "/" .. message.id) then
					table.insert(config.valuablemessages, message.channel.id .. "/" .. message.id)
					sqldb:set(interaction.guild.id, {
						valuablemessages = config.valuablemessages
					}, "MARK_VALUABLE_MESSAGE", interaction.user)
					return interaction:success("This message has been marked as valuable, and will require confirmation to purge.", nil, true)
				else
					table.delete(config.valuablemessages, message.channel.id .. "/" .. message.id)
					sqldb:set(interaction.guild.id, {
						valuablemessages = config.valuablemessages
					}, "UNMARK_VALUABLE_MESSAGE", interaction.user)
					return interaction:warning("This message has been unmarked as valuable.", nil, true)
				end
			end
		end)()
	end)

	connections["interactionCreate"] = Client:on("interactionCreate", function(interaction)
		if not interaction.id or not interaction.guild or not interaction.channel or not interaction.message or not interaction.data or not interaction.data.custom_id or not interaction.user or not interaction.member or interaction.user.bot or (blacklisted(interaction.member, interaction)) or (blacklisted(interaction.guild, interaction)) then
			return
		end

		local guild = interaction.guild
		local config = sqldb:get(guild.id)

		if not config then
			return
		end

		Client:emit("interactionGiveaways", interaction, config)

		Client:emit("interactionLoas", interaction, config)

		Client:emit("interactionSessions", interaction, config)

		Client:emit("interactionFeedback", interaction, config)

		Client:emit("interactionPunishments", interaction, config)

		Client:emit("interactionBolo", interaction, config)

		Client:emit("interactionMessageMgmt", interaction, config)
	end)

	connections["reactionAddAny"] = Client:on("reactionAddAny", function(channel, messageId, hash, userId)
		coroutine.wrap(function()
			if not channel or not channel.guild or not messageId or (not channel:getMessage(messageId)) or not hash or not userId or (userId == Client.user.id) then
				return
			end

			local guild = channel.guild
			local message = channel:getMessage(messageId)

			if (not message) or not message.member or not message.user then
				return
			end

			local config = sqldb:get(guild.id)

			if (not config) or not config.reactionboards or (table.count(config.reactionboards) <= 0) then
				return
			end

			local board = nil

			for bi, b in pairs(config.reactionboards) do
				if not b.disabled and b.reaction:find(hash) then
					board = b
					break
				end
			end

			if not board or (not guild:getChannel(board.channel)) or ((table.count(board.whitelistedChannels or {}) > 0) and (not table.find(board.whitelistedChannels, channel.id))) then
				return
			end

			local reaction = nil

			for _, r in pairs(message.reactions) do
				if r.emojiHash:find(hash) then
					reaction = r
					break
				end
			end

			if (not reaction) or reaction.me then
				return
			end

			local reactionUsers = reaction:getUsers()

			if not reactionUsers or not board or not board.reactionsneeded or (#reactionUsers < board.reactionsneeded) then
				return
			end

			message:addReaction(reaction.emojiHash)
			

			guild:getChannel(board.channel):send({
				content = "-# " .. emojis.right .. " " .. message.link,
				embed = {
					author = {
						name = message.member.name,
						icon_url = message.member.avatarURL
					},
					description = contentString(message),
					image = (message.attachment and {
						url = message.attachment.url
					}) or (message.embed and message.embed.image) or (message.embed and message.embed.thumbnail),
					color = colors.info,
					timestamp = toISO(os.time())
				}
			})
		end)()
	end)

	connections["memberJoin"] = Client:on("memberJoin", function(member)
		if (not member) or (not member.guild) or (not member.user) or (member.user.bot) or blacklisted(member.guild) then
			return
		end

		local config = sqldb:get(member.guild.id)
		if not config then
			return
		end

		Client:emit("memberJoinWelcome", member, config)
		Client:emit("memberDepartments", member, config) -- not memberJoin bc it does the same for memberUpdate
		Client:emit("memberJoinErlcbansync", member, config)
	end)

	connections["userBan"] = Client:on("userBan", function(user, guild)
		if not user or user.bot or not guild or blacklisted(guild) then
			return
		end

		local config = sqldb:get(guild.id)
		if not config then
			return
		end

		Client:emit("userBanErlcbansync", user, guild, config)
	end)

	connections["userUnban"] = Client:on("userUnban", function(user, guild)
		if not user or user.bot or not guild or blacklisted(guild) then
			return
		end

		local config = sqldb:get(guild.id)
		if not config then
			return
		end

		Client:emit("userUnbanErlcbansync", user, guild, config)
	end)

	connections["memberUpdate"] = Client:on("memberUpdate", function(member)
		if (not member) or (not member.guild) or blacklisted(member.guild) then
			return
		end

		local config = sqldb:get(member.guild.id)
		if not config then return end

		Client:emit("memberDepartments", member, config) -- not memberUpdate bc it does the same for memberJoin
	end)

	connections["messageCreate"] = Client:on("messageCreate", function(message)
		if not message or not message.id or not message.guild or not message.channel or blacklisted(message.guild) then
			return
		end

		local guild = message.guild
		local config = sqldb:get(guild.id)

		if not config then
			return
		end

		Client:emit("messageCreateMessageMgmt", message, config)
		
		if message.user and message.member and not message.user.bot then
			Client:emit("messageCreateAntiPing", message, config)
			Client:emit("messageCreateAfk", message, config)
			Client:emit("messageCreateAutoresponders", message, config)
		end

		--[[
		if not message.user.bot and message.user and message.member and message.user and config.countingchannel and message.channel.id == config.countingchannel then
			local function checkCounting()
				-- db:send(guild, "countingchannel", {
				-- 	embed = {
				-- 		description = emojis.fail ..
				-- 			" Unfortunately, we have decided to discontinue the counting module. This is due to it using a lot of recourses, and we want to focus on our best features.\n-# This message will not be sent again.",
				-- 		color = colors.fail
				-- 	}
				-- })

				-- sqldb:set(guild.id, { countingchannel = "nil" }, "REMOVE_COUNTINGCHANNEL")

				local currentnumber = config.countingcurrentnumber or 0
				local allowdoublecounting = config.allowdoublecounting
				local allowtalking = config.countingallowtalking
				local previouscounter = config.previouscounter

				function eval(str)
					str = str:gsub("true", "1")
					str = str:gsub("false", "0")
					str = str:gsub("x", "*")
					str = str:gsub("%a", "")
					str = str:gsub("×", "*")
					str = str:gsub("÷", "/")
					str = str:gsub("−", "%-")
					str = str:gsub("%[", "%(")
					str = str:gsub("]", "%)")
					str = str:gsub("|(-?%d+)|", "math.abs(%1)")

					local loaded, err = load("return " .. str)

					if loaded then
						local s, num = pcall(loaded)
						if s then return tonumber(num) end
					end
				end

				local evaluated = eval(message.content)

				if allowtalking and not evaluated then return end

				if (not allowdoublecounting) and (message.user.id == previouscounter) then
					message:addReaction(resolvedEmojis.fail.hash)
					sqldb:set(guild.id, {
						countingcurrentnumber = 0,
						previouscounter = "nil"
					}, "COUNTING_RESET")
					return message:fail("You failed at **" .. currentnumber .. "**! The next number is now 1.\n-# You cannot count twice.")
				end

				if not evaluated then
					message:addReaction(resolvedEmojis.fail.hash)
					sqldb:set(guild.id, {
						countingcurrentnumber = 0,
						previouscounter = "nil"
					}, "COUNTING_RESET")
					return message:fail("You failed at **" .. currentnumber .. "**! The next number is now 1.\n-# Talking is disabled.")
				end

				if evaluated ~= currentnumber + 1 then
					if currentnumber == 0 then
						message:addReaction(resolvedEmojis.warning.hash)
						return message:warning("The next number is " .. (currentnumber + 1) .. ".")
					else
						message:addReaction(resolvedEmojis.fail.hash)
						sqldb:set(guild.id, {
							countingcurrentnumber = 0,
							previouscounter = "nil"
						}, "COUNTING_RESET")
						return message:fail("You failed at **" .. currentnumber .. "**! The next number is now 1.\n-# The previous number was " .. currentnumber .. ((previouscounter and message.guild:getMember(previouscounter) and ", counted by **" .. message.guild:getMember(previouscounter).name .. "**.") or "."))
					end
				end

				sqldb:set(guild.id, {
					countingcurrentnumber = currentnumber + 1,
					previouscounter = message.user.id
				}, "COUNTING_ADD")

				message:addReaction(resolvedEmojis.success.hash)
			end
			-- checkCounting()
		end
		]] --
	end)

	connections["messageDelete"] = Client:on("messageDelete", function(message, bulk)
		if not message or not message.id or not message.member or not message.user or message.user.bot or not message.guild or not message.channel or blacklisted(message.guild) then
			return
		end

		local guild = message.guild
		local config = sqldb:get(guild.id)

		Client:emit("messageDeleteAntiPing", message, bulk, config)
	end)
end

dispatch.Stop = function()
	for event, connection in pairs(connections) do
		Client:removeListener(event, connection)
	end

	connections = nil
end
return dispatch
