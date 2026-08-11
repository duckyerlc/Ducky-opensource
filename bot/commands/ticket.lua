-- ticket.lua
local slashCommand = tools.slashCommand("ticket", "Use Ducky's ticket system.")
local subcmd = tools.subCommand("manage", "Manage the current ticket.")
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("claim", "Claim the current ticket.")
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("unclaim", "Unclaim the current ticket.")
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("add", "Add a user to the current ticket.")
subcmd:addOption(tools.user("member", "The member to add to this ticket."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("remove", "Remove a user from the current ticket.")
subcmd:addOption(tools.user("member", "The member to remove from this ticket."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("close", "Close the current ticket.")
subcmd = subcmd:addOption(tools.string("reason", "The reason for closing."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("closerequest", "Make a close request on the current ticket.")
subcmd = subcmd:addOption(tools.string("reason", "The reason for closing."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("rename", "Rename the current ticket.")
subcmd:addOption(tools.string("name", "The new name for this ticket."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)

local requestActions = discordia.Components():button({
	id = "yes",
	emoji = resolvedEmojis.yeswhite,
	style = "success"
}):button({
	id = "no",
	emoji = resolvedEmojis.nowhite,
	style = "danger"
})

local closedActions = discordia.Components():button({
	id = "tickettranscript",
	label = "Transcript",
	style = "blurple",
	emoji = resolvedEmojis.document
}):button({
	id = "ticketdelete",
	label = "Delete",
	style = "danger",
	emoji = resolvedEmojis.delete
})

return {
	name = "ticket",
	description = "Use Ducky's ticket system.",
	aliases = {},
	category = "Tickets",
	slashCommand = slashCommand,
	subcommands = {
		"claim",
		"unclaim",
		"add",
		"remove",
		"rename",
		"close",
		"closerequest",
		"manage"
	},
	requiredPermissions = {
		"SETUP"
	},
	hybridCallback = function(interaction, args, slash, subcmd)
		local panel = nil
		local panelindex = nil
		local subject = nil
		local subjectindex = nil
		local ticket = nil
		local ticketindex = nil

		local config = sqldb:get(interaction.guild.id) or {}

		for pi, p in pairs(config.panels or {}) do
			for si, s in pairs(p.subjects or {}) do
				for ti, t in pairs(s.tickets or {}) do
					if t.channel == interaction.channel.id then
						panel = p
						panelindex = pi
						subject = s
						subjectindex = si
						ticket = t
						ticketindex = ti
					end
				end
			end
		end

		if panel and subject and ticket then
			if not _G.isSubjectSupport(interaction.member, subject) then
				return interaction:fail("You do not have permissions to use this.", nil, true)
			else
				local ticketOwner = interaction.guild:getMember(ticket.owner) or Client:getUser(ticket.owner)
				local ticketClaimer = (ticket.claimer and (interaction.guild:getMember(ticket.claimer) or Client:getUser(ticket.claimer))) or nil
				if subcmd == "manage" then
					if not hasPermission(interaction.member, "MANAGE_SERVER", config, interaction) then
						return
					end

					local ticketManager = interaction:reply({
						embed = {
							description = emojis.loading,
							color = colors.blank 
						}
					})

					local function updateManager()
						return ticketManager:update({
							embed = {
								title = emojis.ticket .. " Ticket " .. tostring(ticket.id),
								description = emojis.right .. " **Subject:** " .. subject.name .. "\n" .. emojis.right .. " **Ticket Opener:** <@" .. ticket.owner .. ">" .. "\n" .. emojis.right .. " **Ticket Claimer:** " .. ((ticketClaimer and ticketClaimer.mentionString) or emojis.fail) .. "\n-# " .. emojis.right .. " **Ticket ID:** " .. interaction.guild.id .. "." .. panelindex .. "." .. subjectindex .. "." .. ticketindex,
								color = colors.info,
								footer = ticketOwner and {
									text = "Ticket opened by @" .. ticketOwner.username,
									icon_url = ticketOwner.avatarURL
								}
							},
							components = discordia.Components():selectMenu({
								id = "actions",
								placeholder = "Manage this ticket...",
								actionRow = 1,
								options = {
									{
										label = "Move Ticket",
										description = "Move this ticket to a different subject.",
										value = "move",
										emoji = resolvedEmojis.ticket
									},
									{
										label = "Force Unclaim",
										description = "Forcefully remove this ticket's claimer.",
										value = "unclaim",
										emoji = resolvedEmojis.unlock
									},
									{
										label = "Force Close",
										description = "Forcefully close this ticket.",
										value = "delete",
										emoji = resolvedEmojis.delete
									}
								}
							}):raw()
						})
					end

					updateManager()

					onComp(ticketManager, nil, nil, interaction.user.id, false, function(ia)
						local id = ia.data.custom_id
						local first = ia.data.values and ia.data.values[1]

						if id == "actions" then
							if first == "move" then
								local subjs = {}

								for sbjid, sbj in pairs(panel.subjects) do
									table.insert(subjs, {
										label = sbj.name,
										emoji = sbj.emoji and _G.resolveEmoji(sbj.emoji),
										description = sbj.description,
										value = tostring(sbjid)
									})
								end
								optionsSelect(ia, "Select a subject...", function(subjectID, oia, optionSelector)
									if not subjectID then
										return oia:fail("You did not select a subject.", nil, true)
									end

									local newSubject = panel.subjects[tonumber(subjectID)]

									if not newSubject then
										return oia:fail("The subject you selected was invalid.", nil, true)
									end

									oia:updateDeferred(true)
									ia:deleteReply(optionSelector.id)

									local ticketData = table.deepcopy(subject.tickets[ticketindex])
									ticketData.claimer = nil

									for tid, t in pairs(subject.tickets) do
										if t.channel == interaction.channel.id then
											table.remove(subject.tickets, tid)
											break
										end
									end

									coroutine.wrap(function()
										for _, v in pairs(subject.support) do
											local overwrite = interaction.channel:getPermissionOverwriteFor(interaction.guild:getRole(v))
											if overwrite then
												overwrite:delete()
											end
										end

										for _, v in pairs(newSubject.support) do
											local overwrite = interaction.channel:getPermissionOverwriteFor(interaction.guild:getRole(v))
											if overwrite then
												overwrite:allowPermissions(discordia.enums.permission.readMessages, discordia.enums.permission.sendMessages, discordia.enums.permission.addReactions, discordia.enums.permission.embedLinks, discordia.enums.permission.attachFiles)
											end
										end
									end)()

									interaction.channel:setCategory(newSubject.category)

									table.insert(newSubject.tickets, ticketData)
									subject = newSubject
									subjectindex = subjectID
									ticket = ticketData
									ticketindex = table.count(newSubject.tickets)
									sqldb:set(interaction.guild.id, {
										panels = config.panels
									}, "TICKET_UPDATE")
									updateManager()
								end, false, subjs, 1, nil, true)
							elseif first == "unclaim" then
								if not ticket.claimer then
									ia:fail("This ticket is not claimed.", nil, true)
									updateManager()
									return
								end
								coroutine.wrap(function()
									pcall(function()
										local currentClaimerOverwrite = interaction.channel:getPermissionOverwriteFor(interaction.guild:getMember(interaction.member.id))
										if currentClaimerOverwrite then
											currentClaimerOverwrite:delete()
										end
										for i, v in pairs(subject.support) do
											local overwrite = interaction.channel:getPermissionOverwriteFor(interaction.guild:getRole(v))
											if overwrite then
												overwrite:allowPermissions(discordia.enums.permission.readMessages, discordia.enums.permission.sendMessages, discordia.enums.permission.addReactions, discordia.enums.permission.embedLinks, discordia.enums.permission.attachFiles)
											end
										end
									end)
								end)()
								config = sqldb:get(interaction.guild.id) or {}
								config.panels[panelindex].subjects[subjectindex].tickets[ticketindex].claimer = nil
								sqldb:set(interaction.guild.id, {
									panels = config.panels
								}, "TICKET_FORCE_UNCLAIM")
								ia:updateDeferred(true)
								updateManager()
							elseif first == "delete" then
								local r = ia:loading("Generating transcript...", true)
								local transcript, webTranscriptLink = transcriptChannel(interaction.channel)
								coroutine.wrap(function()
									local embed = {
										title = emojis.document .. " Ticket Transcript",
										description = emojis.right .. " **Ticket ID:** `" .. (ticket.id or 0) .. "`\n" .. emojis.right .. " **Ticket Subject:** " .. subject.name .. "\n" .. emojis.right .. " **Ticket Opener:** <@" .. ticket.owner .. ">\n" .. emojis.right .. " **Ticket Claimer:** " .. ((ticketClaimer and ticketClaimer.mentionString) or "N/A") .. "\n" .. emojis.right .. " **Ticket Closer:** " .. interaction.user.mentionString .. "\n" .. emojis.right .. " **Ticket Close Reason:** " .. emojis.fail,
										color = colors.info
									}

									local comps = discordia.Components():button({
										url = webTranscriptLink,
										style = "link",
										label = "Web Transcript",
										emoji = resolvedEmojis.web
									})

									local settings = sqldb:getUserSettings(ticket.owner)
									if settings and settings.ticketnotifications ~= false then
										Client:getUser(ticket.owner):send({
											embed = embed,
											files = {
												{
													"transcript.txt",
													tostring(transcript)
												}
											},
											components = comps:raw()
										})
									end

                                    p("tschannel")
									if subject.transcriptschannel then
                                        p("finding", subject.transcriptschannel)
										local ts = interaction.guild:getChannel(subject.transcriptschannel)
										if ts then
                                            p("found, sending")
											local s, e = ts:send({
												embed = embed,
												files = {
													{
														"transcript.txt",
														tostring(transcript)
													}
												},
												components = comps:raw()
											})
                                            p(not not s, e)
										end
									end
								end)()
								if interaction.channel._delete_protection then
									return r:update({
                                        embed = {
                                            description = emojis.fail .. " Another operation that generates a transcript is already occurring on this ticket. Please try again in a few seconds.",
                                            color = colors.fail
                                        }
                                    })
								end

								config = sqldb:get(interaction.guild.id) or {}
								table.remove(config.panels[panelindex].subjects[subjectindex].tickets, ticketindex)
								sqldb:set(interaction.guild.id, {
									panels = config.panels
								}, "TICKET_FORCE_DELETE")
								interaction.channel:delete()
								return true
							end
						end
					end)
				elseif subcmd == "add" then
					local member = nil

					if slash then
						member = args and args.member and args.member.id and interaction.guild:getMember(args.member.id)
					else
						member = interaction.mentionedUsers and interaction.mentionedUsers.first

						if (not member) and args[2] then
							interaction.guild:requestMembers()

							for i, v in pairs(interaction.guild.members) do
								if v.name:lower():find(args[2]:lower()) or v.user.username:lower():find(args[2]:lower()) then
									member = v
									break
								end
							end
						end
					end

					if member then
						local overwrite = interaction.channel:getPermissionOverwriteFor(member)
						if overwrite then
							overwrite:allowPermissions(discordia.enums.permission.readMessages, discordia.enums.permission.sendMessages, discordia.enums.permission.addReactions, discordia.enums.permission.embedLinks, discordia.enums.permission.attachFiles)
						end
						return interaction:success("**" .. member.name .. "** has been added to this ticket.")
					else
						return interaction:fail("You did not provide a member to add to this ticket.", nil, true)
					end
				elseif subcmd == "remove" then
					local member = nil

					if slash then
						member = args and args.member and args.member.id and interaction.guild:getMember(args.member.id)
					else
						member = interaction.mentionedUsers and interaction.mentionedUsers.first

						if (not member) and args[2] then
							interaction.guild:requestMembers()

							for i, v in pairs(interaction.guild.members) do
								if v.name:lower():find(args[2]:lower()) or v.user.username:lower():find(args[2]:lower()) then
									member = v
									break
								end
							end
						end
					end

					if member then
						local overwrite = interaction.channel:getPermissionOverwriteFor(member)
						if overwrite then
							overwrite:denyPermissions(discordia.enums.permission.readMessages, discordia.enums.permission.sendMessages)
						end
						return interaction:success("**" .. member.name .. "** has been removed from this ticket.")
					else
						return interaction:fail("You did not provide a member to remove from this ticket.", nil, true)
					end
				elseif subcmd == "claim" then
					if (not ticket.claimer) then
						config = sqldb:get(interaction.guild.id) or {}
						config.panels[panelindex].subjects[subjectindex].tickets[ticketindex].claimer = interaction.user.id
						sqldb:set(interaction.guild.id, {
							panels = config.panels
						}, "TICKET_CLAIM")

						interaction:success("You have successfully claimed this ticket.", nil, true)

						interaction.channel:send({
							embeds = _G.parseTable(subject.embeds.claim, {
								["claimer.mention"] = interaction.member.mentionString,
								["claimer.id"] = interaction.member.id,
								["claimer.name"] = interaction.member.name,
								["claimer.username"] = interaction.user.username,
								["owner.mention"] = (ticketOwner and ticketOwner.mentionString) or emojis.fail,
								["owner.id"] = (ticketOwner and ticketOwner.id) or emojis.fail,
								["owner.name"] = (ticketOwner and ticketOwner.name) or emojis.fail,
								["owner.username"] = (ticketOwner and ticketOwner.username) or emojis.fail,
								["timestamp"] = tostring(os.time())
							})
						})

						if subject.claimedticketname then
							interaction.channel:setName(_G.parseTable({
								subject.claimedticketname
							}, {
								["claimer.name"] = interaction.member.name,
								["claimer.username"] = interaction.user.username,
								["claimer.id"] = interaction.user.id,
								["member.name"] = (ticketOwner and ticketOwner.name) or "0",
								["member.username"] = (ticketOwner and ticketOwner.username) or "0",
								["member.id"] = (ticketOwner and ticketOwner.id) or "0",
								["ticket.id"] = ticket.id or "0"
							})[1])
						end

						coroutine.wrap(function()
							local claimerOverwrite = interaction.channel:getPermissionOverwriteFor(interaction.guild:getMember(interaction.member.id))
							if claimerOverwrite then
								claimerOverwrite:allowPermissions(discordia.enums.permission.readMessages, discordia.enums.permission.sendMessages, discordia.enums.permission.addReactions, discordia.enums.permission.embedLinks, discordia.enums.permission.attachFiles)
							end
							if (not subject.ticketclaimmode) or subject.ticketclaimmode == "hide" then
								for i, v in pairs(subject.support) do
									local overwrite = interaction.channel:getPermissionOverwriteFor(interaction.guild:getRole(v))
									if overwrite then
										overwrite:denyPermissions(discordia.enums.permission.readMessages)
									end
								end
							elseif subject.ticketclaimmode == "lock" then
								for i, v in pairs(subject.support) do
									local overwrite = interaction.channel:getPermissionOverwriteFor(interaction.guild:getRole(v))
									if overwrite then
										overwrite:setPermissions(discordia.enums.permission.readMessages, discordia.enums.permission.sendMessages)
									end
								end
							end
						end)()
					elseif ticket.claimer ~= interaction.user.id then
						interaction:fail("This ticket has already been claimed by <@" .. tostring(ticket.claimer) .. ">.", nil, true)
					elseif ticket.claimer == interaction.user.id then
						interaction:warning("You have already claimed this ticket.\n-# " .. emojis.right .. " You can unclaim this ticket with `/ticket unclaim`.", nil, true)
					end
				elseif subcmd == "unclaim" then
					if ticket.claimer == interaction.user.id then
						config = sqldb:get(interaction.guild.id) or {}
						config.panels[panelindex].subjects[subjectindex].tickets[ticketindex].claimer = nil
						sqldb:set(interaction.guild.id, {
							panels = config.panels
						}, "TICKET_UNCLAIM")

						interaction:success("You have successfully unclaimed this ticket.", nil, true)

						interaction.channel:send({
							embeds = _G.parseTable(subject.embeds.unclaim, {
								["unclaimer.mention"] = interaction.member.mentionString,
								["unclaimer.id"] = interaction.member.id,
								["unclaimer.name"] = interaction.member.name,
								["unclaimer.username"] = interaction.user.username,
								["owner.mention"] = (ticketOwner and ticketOwner.mentionString) or emojis.fail,
								["owner.id"] = (ticketOwner and ticketOwner.id) or emojis.fail,
								["owner.name"] = (ticketOwner and ticketOwner.name) or emojis.fail,
								["owner.username"] = (ticketOwner and ticketOwner.username) or emojis.fail,
								["timestamp"] = tostring(os.time())
							})
						})

						interaction.channel:setName(_G.parseTable({
							subject.ticketname
						}, {
							["member.name"] = (ticketOwner and ticketOwner.name) or "0",
							["member.username"] = (ticketOwner and ticketOwner.username) or "0",
							["member.id"] = (ticketOwner and ticketOwner.id) or "0",
							["ticket.id"] = ticket.id or "0"
						})[1])

						coroutine.wrap(function()
							local unclaimerOverwrite = interaction.channel:getPermissionOverwriteFor(interaction.guild:getMember(interaction.member.id))
							if unclaimerOverwrite then
								unclaimerOverwrite:delete()
							end
							for i, v in pairs(subject.support) do
								local overwrite = interaction.channel:getPermissionOverwriteFor(interaction.guild:getRole(v))
								if overwrite then
									overwrite:allowPermissions(discordia.enums.permission.readMessages, discordia.enums.permission.sendMessages, discordia.enums.permission.addReactions, discordia.enums.permission.embedLinks, discordia.enums.permission.attachFiles)
								end
							end
						end)()
					else
						interaction:fail("You have not claimed this ticket.", nil, true)
					end
				elseif subcmd == "close" then
					interaction.channel._delete_protection = true
					local reason = (slash and args and args.reason) or ((not slash) and table.remove(args, 1) and table.concat(args, " "))

					reason = (reason and string.truncate(reason, 500)) or nil

					config = sqldb:get(interaction.guild.id) or {}
					table.remove(config.panels[panelindex].subjects[subjectindex].tickets, ticketindex)
					sqldb:set(interaction.guild.id, {
						panels = config.panels
					}, "TICKET_CLOSE")

					if slash then
						interaction:success("This ticket has been successfully closed.", nil, true)
					else
						interaction:delete()
					end

					interaction.channel:send({
						embeds = _G.parseTable(subject.embeds.close, {
							["closer.mention"] = interaction.member.mentionString,
							["closer.id"] = interaction.member.id,
							["closer.name"] = interaction.member.name,
							["closer.username"] = interaction.user.username,
							["owner.mention"] = (ticketOwner and ticketOwner.mentionString) or emojis.fail,
							["owner.id"] = (ticketOwner and ticketOwner.id) or emojis.fail,
							["owner.name"] = (ticketOwner and ticketOwner.name) or emojis.fail,
							["owner.username"] = (ticketOwner and ticketOwner.username) or emojis.fail,
							["timestamp"] = tostring(os.time()),
							["reason"] = (reason or "N/A")
						}),
						components = closedActions:raw()
					})

					coroutine.wrap(function()
						local ownerOverwrite = interaction.channel:getPermissionOverwriteFor(interaction.guild:getMember(ticket.owner))
						if ownerOverwrite then
							ownerOverwrite:denyPermissions(discordia.enums.permission.readMessages)
						end
						for i, v in pairs(subject.support) do
							local overwrite = interaction.channel:getPermissionOverwriteFor(interaction.guild:getRole(v))
							if overwrite then
								overwrite:denyPermissions(discordia.enums.permission.sendMessages)
							end
						end

						local transcript, webTranscriptLink = transcriptChannel(interaction.channel)
						local embed = {
							title = emojis.document .. " Ticket Transcript",
							description = emojis.right .. " **Ticket ID:** `" .. (ticket.id or 0) .. "`\n" .. emojis.right .. " **Ticket Subject:** " .. subject.name .. "\n" .. emojis.right .. " **Ticket Opener:** <@" .. ticket.owner .. ">\n" .. emojis.right .. " **Ticket Claimer:** " .. ((ticketClaimer and ticketClaimer.mentionString) or "N/A") .. "\n" .. emojis.right .. " **Ticket Closer:** " .. interaction.user.mentionString .. "\n" .. emojis.right .. " **Ticket Close Reason:** " .. (reason or emojis.fail),
							color = colors.info
						}
						local comps = discordia.Components():button({
							url = webTranscriptLink,
							style = "link",
							label = "Web Transcript",
							emoji = resolvedEmojis.web
						})
						local settings = sqldb:getUserSettings(ticket.owner)
						if settings and settings.ticketnotifications ~= false then
							Client:getUser(ticket.owner):send({
								embed = embed,
								files = {
									{
										"transcript.txt",
										tostring(transcript)
									}
								},
								components = comps:raw()
							})
						end

						if subject.transcriptschannel then
							local ts = interaction.guild:getChannel(subject.transcriptschannel)
							if ts then
								ts:send({
									embed = embed,
									files = {
										{
											"transcript.txt",
											tostring(transcript)
										}
									},
									components = comps:raw()
								})
							end
						end
					end)()
				elseif subcmd == "closerequest" then
					local reason = (slash and args and args.reason) or ((not slash) and table.remove(args, 1) and table.concat(args, " "))

					reason = (reason and string.truncate(reason, 500)) or nil

					local request = interaction.channel:send({
						content = "-# " .. emojis.pings .. " " .. ticketOwner.mentionString,
						embeds = _G.parseTable(subject.embeds.request, {
							["requester.mention"] = interaction.member.mentionString,
							["requester.id"] = interaction.member.id,
							["requester.name"] = interaction.member.name,
							["requester.username"] = interaction.user.username,
							["owner.mention"] = (ticketOwner and ticketOwner.mentionString) or emojis.fail,
							["owner.id"] = (ticketOwner and ticketOwner.id) or emojis.fail,
							["owner.name"] = (ticketOwner and ticketOwner.name) or emojis.fail,
							["owner.username"] = (ticketOwner and ticketOwner.username) or emojis.fail,
							["timestamp"] = tostring(os.time()),
							["reason"] = (reason or "N/A")
						}),
						components = requestActions:raw()
					})

					onComp(request, nil, nil, ticket.owner, true, function(ia)
						local id = ia.data.custom_id

						if id == "yes" then
							interaction.channel._delete_protection = true
							config = sqldb:get(interaction.guild.id) or {}
							table.remove(config.panels[panelindex].subjects[subjectindex].tickets, ticketindex)
							sqldb:set(interaction.guild.id, {
								panels = config.panels
							}, "TICKET_CLOSE")

							ia:updateDeferred(true)
							request:delete()

							interaction.channel:send({
								embeds = _G.parseTable(subject.embeds.close, {
									["closer.mention"] = ia.member.mentionString,
									["closer.id"] = ia.member.id,
									["closer.name"] = ia.member.name,
									["closer.username"] = ia.user.username,
									["owner.mention"] = (ticketOwner and ticketOwner.mentionString) or emojis.fail,
									["owner.id"] = (ticketOwner and ticketOwner.id) or emojis.fail,
									["owner.name"] = (ticketOwner and ticketOwner.name) or emojis.fail,
									["owner.username"] = (ticketOwner and ticketOwner.username) or emojis.fail,
									["timestamp"] = tostring(os.time()),
									["reason"] = (reason or "N/A")
								}),
								components = closedActions:raw()
							})

							coroutine.wrap(function()
								local ownerOverwrite = interaction.channel:getPermissionOverwriteFor(interaction.guild:getMember(ticket.owner))
								if ownerOverwrite then
									ownerOverwrite:denyPermissions(discordia.enums.permission.readMessages)
								end
								for i, v in pairs(subject.support) do
									local overwrite = interaction.channel:getPermissionOverwriteFor(interaction.guild:getRole(v))
									if overwrite then
										overwrite:denyPermissions(discordia.enums.permission.sendMessages)
									end
								end

								if subject.transcriptschannel then
									local ts = interaction.guild:getChannel(subject.transcriptschannel)
									local transcript, webTranscriptLink = transcriptChannel(interaction.channel)

									if ts then
										ts:send({
											embed = {
												title = emojis.document .. " Ticket Transcript",
												description = emojis.right .. " **Ticket ID:** `" .. (ticket.id or 0) .. "`\n" .. emojis.right .. " **Ticket Subject:** " .. subject.name .. "\n" .. emojis.right .. " **Ticket Opener:** <@" .. ticket.owner .. ">\n" .. emojis.right .. " **Ticket Claimer:** " .. ((ticketClaimer and ticketClaimer.mentionString) or "N/A") .. "\n" .. emojis.right .. " **Ticket Closer:** " .. interaction.user.mentionString .. "\n" .. emojis.right .. " **Ticket Close Reason:** " .. (reason or "N/A"),
												color = colors.info
											},
											files = {
												{
													"transcript.txt",
													tostring(transcript)
												}
											},
											components = discordia.Components():button({
												url = webTranscriptLink,
												style = "link",
												label = "Web Transcript",
												emoji = resolvedEmojis.web
											}):raw()
										})
									end
								end
							end)()
						elseif id == "no" then
							request:delete()
							ia:updateDeferred(true)
						end
					end)

					if slash then
						interaction:success("The close request has been sent.", nil, true)
					else
						interaction:delete()
					end
				elseif subcmd == "rename" then
					local newName = (slash and args and args.name) or ((not slash) and args and table.remove(args, 1) and table.concat(args, " "))

					if newName then
						local s, e = interaction.channel:setName(newName)
						if s then
							if slash then
								interaction:success("Successfully renamed ticket.")
							else
								interaction:delete()
							end
						else
							return interaction:fail("Failed to rename ticket, this is likely due to ratelimits.\n-# " .. e:usub(1, 16))
						end
					else
						return interaction:fail("You must provide a new name for this ticket.", nil, true)
					end
				end
			end
		else
			return interaction:fail("This channel is not a ticket.", nil, true)
		end
	end
}
