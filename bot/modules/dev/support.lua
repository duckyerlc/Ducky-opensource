-- support.lua
local support = {
	name = "support",
	description = "Powers Ducky's community support system."
}

local connections = {
	Client = {}
}

local tags = {
	PENDING 	= "1330949117098201228",
	PRIORITY 	= "1320447146775805962",
	RESOLVED 	= "1320376164451225670",
	DEVELOPER 	= "1320376230897254500",
	VIOLATE 	= "1320376319158124554",
	MOVED 		= "1320968738257895504",
	BUG 		= "1320968884651692032",
	INACTIVE 	= "1435456873280307330"
}

support.Start = function()
	connections.Client.threadCreate = Client:on("threadCreate", function(thread, new)
		coroutine.wrap(function()
			if (not thread) or (not new) or (not thread.guild) or (thread.guild.id ~= duckysPond.id) or (not thread.parent) or (not thread.parent.id) or (thread.parent.id ~= "1320375826851565689") or (not thread.ownerId) or (not thread:getThreadOwner()) or (not thread:getThreadOwner():getGuildMember()) or (not thread:getThreadOwner():getGuildMember().id) then
				return
			end

			local threadOwner = thread:getThreadOwner() and thread:getThreadOwner():getGuildMember()

			if not threadOwner then
				return
			end

			local isPlus = sqldb:plusMember(threadOwner)

			timer.sleep(800)

			local greetMessage, err = thread:send({
				content = threadOwner.id ~= "598958193032560642" and "-# " .. emojis.pings .. " " .. threadOwner.mentionString .. ((isPlus and "・<@&1259747747091972116>") or "") or nil,
				embed = {
					title = emojis.hiya .. " Hiya, **" .. threadOwner.name .. "**!",
					description = ">>> Thank you for contacting Ducky Support. One of our <@&1259747747091972116> members will arrive shortly to assist you. Additionally, a member of the community may be able to assist you as well.\n\nIn the meantime, please provide the necessary details, such as your server's invite, and further elaborate on your request if needed.\n\n-# " .. emojis.warning .. " ***Do not give potentially harmful roles in your server to users without the <@&1259747747091972116> role.***",
					image = {
						url = "https://media.discordapp.net/attachments/1278154516147208275/1330938255318978592/support_1.png?ex=678fcc57&is=678e7ad7&hm=dc161906ffa89dd8daefc0f0706588324311aeb7215ab9be97b97b03730b90a7&=&format=webp&quality=lossless&width=1649&height=123"
					},
					color = colors.yellow
				},
				components = discordia.Components():selectMenu({
					placeholder = "Select an action...",
					id = "managethread",
					actionRow = 1,
					min_values = 0,
					options = {
						{
							label = "Mark as Resolved",
							value = "resolvethread",
							description = "Mark this thread as resolved.",
							emoji = resolvedEmojis.success
						},
						{
							label = "Mark as Inactive",
							value = "inactivethread",
							description = "Mark this thread as inactive, and remind the thread owner.",
							emoji = resolvedEmojis.warning
						},
						{
							label = "Violates Guidelines",
							value = "violatethread",
							description = "Close this thread for violating the Support Thread guidelines.",
							emoji = resolvedEmojis.error
						},
						{
							label = "Mark as Bug",
							value = "bugthread",
							description = "Mark this thread as a bug.",
							emoji = resolvedEmojis.bughunter
						},
						{
							label = "Request Developer",
							value = "developerthread",
							description = "Escalate this thread to the Development team.",
							emoji = resolvedEmojis.developer
						},
						{
							label = "Move to Ticket",
							value = "movedthread",
							description = "Move this thread to a Private Support ticket.",
							emoji = resolvedEmojis.ticket
						}
					}
				}):raw()
			})

			if not greetMessage then
				return thread:fail("An unexpected error occurred while attempting to process this support thread:\n```\n" .. tostring(err) .. "```")
			end

			greetMessage:pin()

			thread:setTags((isPlus and {
				tags.PENDING,
				tags.PRIORITY
			}) or {
				tags.PENDING
			})

			local name = thread.name:split("・")
			name = name[2] or name[1]
			thread:_modify({
				name = "⏱️・" .. string.truncate(name, 97)
			})
		end)()
	end)

	connections.Client.interactionCreate = Client:on("interactionCreate", function(ia)
		local id = ia.data.custom_id
		local selection = ia.data.values and ia.data.values[1]
		local thread = ia.channel and ia.channel.isThread == true and ia.channel

		if (not thread) or (not thread.parent) or (not thread.parent.id) or (thread.parent.id ~= "1320375826851565689") then
			return
		end

		local threadOwner = thread:getThreadOwner() and thread:getThreadOwner():getGuildMember()

		if (threadOwner and ia.member.id == threadOwner.id) or hasPermission(ia.member, "SUPPORT") then
			if id == "managethread" then
				if selection == "resolvethread" then
					if not thread:hasTag(tags.RESOLVED) then
						confirm(ia, "Are you sure you would like to mark this post as **resolved**?", function(confirmed, cia)
							if confirmed then
								coroutine.wrap(function()
									thread:send({
										content = "-# " .. emojis.pings .. " <@" .. thread.ownerId .. ">",
										embed = {
											title = emojis.success .. " Marked as Resolved",
											description = ">>> Thank you for contacting Ducky Support. This post has been marked as resolved by **" .. ia.member.name .. "**. If you require additional assistance, please feel free to create a new post, and we'll help you out as fast as we can.\n-# " .. emojis.star .. " Consider leaving a review on the support members who assisted you within this thread via <#1261046113218068590>.",
											image = {
												url = "https://duckybot.xyz/images/banners/footers/success.png"
											},
											color = colors.success
										}
									})

									thread:setTags({
										tags.RESOLVED
									})

									local name = thread.name:split("・")
									name = name[2] or name[1]
									thread:_modify({
										name = "✅・" .. string.truncate(name, 97),
										locked = true,
										archived = (threadOwner and ia.member.id == threadOwner.id) or false
									})
								end)()

								cia:updateDeferred(true)
							end
						end, true)
					else
						ia:fail("This post is already marked as resolved.", nil, true)
					end
				elseif selection == "developerthread" then
					if hasPermission(ia.member, "SUPPORT") then
						if not thread:hasTag(tags.DEVELOPER) then
							coroutine.wrap(function()
								thread:send({
									content = "-# " .. emojis.pings .. " <@&1419398641180737606>",
									embed = {
										title = emojis.developer .. " Developer Requested",
										description = ">>> A developer has been requested by **" .. ia.member.name .. "** to assist with this ticket. Please be patient while they arrive. While you wait, provide necessary information in order to fulfill our issue. This would usually include your server's ID, what you are trying to do, etc.",
										image = {
											url = "https://duckybot.xyz/images/banners/footers/support.png"
										},
										color = colors.info
									}
								})

								thread:applyTag(tags.DEVELOPER)

								local name = thread.name:split("・")
								name = name[2] or name[1]
								thread:_modify({
									name = "💻・" .. string.truncate(name, 97)
								})
							end)()

							ia:updateDeferred(true)
						else
							ia:fail("A developer has already been requested.", nil, true)
						end
					else
						ia:fail("You do not have permission to use this.", nil, true)
					end
				elseif selection == "violatethread" then
					if hasPermission(ia.member, "SUPPORT") then
						if not thread:hasTag(tags.VIOLATE) then
							prompt(ia, "Mark as Violates Guidelines", {
								{
									question = "Reason",
									placeholder = "Why does it violate the guidelines?",
									style = "short"
								}
							}, function(mia, responses)
								if responses and responses["Reason"] then
									coroutine.wrap(function()
										thread:send({
											content = "-# " .. emojis.pings .. " <@" .. thread.ownerId .. ">",
											embed = {
												title = emojis.error .. " Guidelines Violated",
												description = ">>> Your post has been closed by **" .. ia.member.name .. "** as it violates the Support Guidelines for the following reason: **" .. responses["Reason"] .. "**. If you still need assistance, please submit a new post, and be sure to follow the Support Guidelines.",
												image = {
													url = "https://duckybot.xyz/images/banners/footers/error.png"
												},
												color = colors.heavyred
											}
										})

										thread:setTags({
											tags.VIOLATE
										})

										local name = thread.name:split("・")
										name = name[2] or name[1]
										thread:_modify({
											name = "❌・" .. string.truncate(name, 97),
											locked = true
										})
									end)()
								end
							end, true)
						else
							ia:fail("This post has already been marked as " .. emojis.error .. " **Violates Guidelines**.")
						end
					else
						ia:fail("You do not have permission to use this.", nil, true)
					end
				elseif selection == "movedthread" then
					if hasPermission(ia.member, "SUPPORT") then
						if not thread:hasTag(tags.MOVED) then
							coroutine.wrap(function()
								thread:send({
									content = "-# " .. emojis.pings .. " <@" .. thread.ownerId .. ">",
									embed = {
										title = emojis.ticket .. " Moved to a Ticket",
										description = ">>> **" .. ia.member.name .. "** has requested for you to make a ticket for further assistance. Please create a " .. emojis.support .. " **Private Support** ticket in <#1261005301021278321>. Please be sure to provide the thread link in the ticket:```https://discord.com/channels/" .. thread._parent_id .. "/" .. thread.id .. "```",
										image = {
											url = "https://duckybot.xyz/images/banners/footers/support.png"
										},
										color = colors.info
									}
								})

								thread:setTags({
									tags.MOVED
								})

								local name = thread.name:split("・")
								name = name[2] or name[1]
								thread:_modify({
									name = "🎟️・" .. string.truncate(name, 97),
									locked = true
								})
							end)()

							ia:updateDeferred(true)
						else
							ia:fail("This post has already been moved to a ticket.", nil, true)
						end
					else
						ia:fail("You do not have permission to use this.", nil, true)
					end
				elseif selection == "bugthread" then
					if hasPermission(ia.member, "BOT_DEVELOPER") then
						if not thread:hasTag(tags.BUG) then
							coroutine.wrap(function()
								thread:send({
									embed = {
										title = emojis.bughunter .. " Marked as a Bug",
										description = ">>> This post has been marked as a bug by **" .. ia.member.name .. "**. This should be resolved soon. Please be patient, and provide necessary information when requested to.",
										image = {
											url = "https://duckybot.xyz/images/banners/footers/warning.png"
										},
										color = colors.warning
									}
								})
								
								thread:setTags({
									tags.BUG,
									tags.DEVELOPER
								})

								local name = thread.name:split("・")
								name = name[2] or name[1]
								thread:_modify({
									name = "🐛・" .. string.truncate(name, 97)
								})
							end)()

							ia:updateDeferred(true)
						else
							ia:fail("This post has already marked as a bug.", nil, true)
						end
					else
						ia:fail("Only members of the " .. emojis.developer .. " **Ducky Development** team can do this.", nil, true)
					end
				elseif selection == "inactivethread" then
					if hasPermission(ia.member, "SUPPORT") then
						coroutine.wrap(function()
							thread:send({
								content = "-# " .. emojis.pings .. " <@" .. thread.ownerId .. ">",
								embed = {
									title = emojis.warning .. " Inactivity Reminder",
									description = ">>> This post has been marked as inactive by **" .. ia.member.name .. "**. Be sure to respond to our support team so we can assist you further. If your issue is resolved, please press " .. emojis.success .. " **Mark as Resolved** via the [thread panel](" .. ia.message.link .. ").",
									image = {
										url = "https://duckybot.xyz/images/banners/footers/warning.png"
									},
									color = colors.warning
								}
							})
							
							thread:setTags({
								tags.PENDING,
								tags.INACTIVE
							})

							local name = thread.name:split("・")
							name = name[2] or name[1]
							thread:_modify({
								name = "⚠️・" .. string.truncate(name, 97)
							})
						end)()

						ia:updateDeferred(true)
					else
						ia:fail("Only members of the " .. emojis.support .. " **Ducky Support** team can do this.", nil, true)
					end
				else
					ia:updateDeferred(true)
				end
			end
		elseif id == "managethread" then
			ia:fail("Only <@" .. tostring(thread.ownerId) .. "> and " .. emojis.support .. " **Ducky Support** members can use this.", nil, true)
		end
	end)
end

support.Stop = function()
	for event, listener in pairs(connections.Client) do
		Client:removeListener(event, listener)
	end

	connections = nil
end

return support
