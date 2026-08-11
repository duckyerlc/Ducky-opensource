-- scheduler.lua
local scheduler = {
	name = "scheduler",
	description = "Handles scheduled items, including reminders, sessions, giveaways, etc.",
}

local Clock = discordia.Clock()
Clock:start()
local connection = nil

local active = false
local lastCheck = 0
local lastDiscordServerStatusUpdate = {}
local schedulerGuildsActive = {}

scheduler.Start = function()
	connection = Clock:on("sec", function()
		if (not runAutomation) or ((os.time() - lastCheck) < 10) or (active == true) then
			return
		end

		active = true
		lastCheck = os.time()

		local ok, err = pcall(function(...)
			for id, settings in pairs(sqldb.cache.user_settings or {}) do
				local user

				if settings.reminders then
					local modified = false

					for i = #settings.reminders, 1, -1 do
						local reminder = settings.reminders[i]

						if os.time() >= reminder.remind then
							user = user or Client:getUser(id)

							if user then
								user:send({
									embed = {
										description = emojis.pings
											.. " "
											.. getUserString(user)
											.. ", you set a reminder "
											.. readable(os.time() - reminder.timestamp)
											.. " ago: "
											.. tostring(reminder.content),
										color = colors.info,
									},
								})

								modified = true
								table.remove(settings.reminders, i)
							end
						end
					end

					if modified then
						sqldb:setUserSettings(id, settings)
					end
				end
			end

			local allGuilds = sqldb:getAllGuildConfigs()
			if not allGuilds or type(allGuilds) ~= "table" then
				return Client:error("SCHEDULER: getAllGuildConfigs returned invalid response: " .. tostring(allGuilds))
			end

			for guildid, c in pairs(allGuilds) do
				local function debug(str)
					if guildid == "." then
						prettyLog("SCHEDULER", "cyan", str)
					end
				end

				coroutine.wrap(function()
					if schedulerGuildsActive[guildid] then
						if realtime() - schedulerGuildsActive[guildid] >= 30 then
							-- utilityChannels.development:send(guildid .. " scheduler run has been active for 30 seconds")
						end
						return
					end

					schedulerGuildsActive[guildid] = realtime()
					local success, err = pcall(function()
						local config = c

						local guild = Client:getGuild(guildid)
						if guild then
							local function saveConfig(changes, reason)
								local succ, ConfigOrError = sqldb:set(guildid, changes, reason)
								if succ then
									config = ConfigOrError
								else
									return false, ConfigOrError
								end
							end

							debug(1)
							if config.erlcplaytimerewards then
								debug(1.1)
								local channel = config.erlcplaytimechannel
									and guild:getChannel(config.erlcplaytimechannel)
								local playtime = {}

								for user, settings in pairs(sqldb.cache and sqldb.cache.user_settings or {}) do
									for _, playsession in pairs(settings.playsessions or {}) do
										if playsession.discord == guild.id then
											playtime[user] = playtime[user] or {}
											playtime[user].playtime = (playtime[user].playtime or 0)
												+ ((playsession.ended or os.time()) - playsession.started)
											playtime[user].playsessions = (
												playtime[user].playsessions or 0
											) + 1
										end
									end
								end

								debug(1.2)
								for _, reward in pairs(config.erlcplaytimerewards) do
									debug(reward.role .. " " .. 1)
									local role = guild:getRole(reward.role)

									if role then
										debug(reward.role .. " " .. 2)
										for id, data in pairs(playtime) do
											debug(reward.role .. " " .. id .. " " .. 3)
											if data.playtime >= reward.playtime then
												debug(reward.role .. " " .. id .. " " .. 4)
												local member = guild:getMember(id)
												debug(reward.role .. " " .. id .. " " .. 4.1)
												if member and not member:hasRole(role.id) then
													debug(reward.role .. " " .. id .. " " .. 4.2)
													local succ, err = member:addRole(
														role.id,
														"reached " .. readable(reward.playtime) .. " of playtime"
													)

													if succ then
														debug(reward.role .. " " .. id .. " add role succ")
													else
														debug(reward.role .. " " .. id .. " add role fail " .. tostring(err))
													end

													debug(reward.role .. " " .. id .. " " .. 5)

													if channel then
													debug(reward.role .. " " .. id .. " " .. 6)
														channel:send(
															parseTable(
																config.erlcplaytimemessage
																	or {
																		content = "-# "
																			.. emojis.pings
																			.. " {member.mention}",
																		embeds = {
																			{
																				description = emojis.inspiration
																					.. " Congratulations, **{member.name}**! You have leveled up to {reward.mention}.",
																				color = colors.yellow,
																			},
																		},
																	},
																DiscordUserVariables(member, "member", {
																	["member.playtime"] = readable(data.playtime),
																	["reward.name"] = role.name,
																	["reward.id"] = role.id,
																	["reward.mention"] = role.mentionString,
																	["reward.playtime"] = readable(reward.playtime),
																	["timestamp"] = os.time(),
																})
															),
															false
														)
													end
													debug(reward.role .. " " .. id .. " " .. 7)
												end
											end
										end
										debug(reward.role .. " playtime loop done")
									end
								end
								debug(1.3)
							end

							debug(2)
							if config.infractions and table.count(config.infractions) > 0 then
								debug(2.1)
								for i = table.count(config.infractions), 1, -1 do
									local infraction = config.infractions[i]

									if infraction.expires and os.time() >= infraction.expires then
										for _, it in pairs(config.infractiontypes or {}) do
											local member = guild:getMember(infraction.user)
											if
												infraction.type:lower() == it.name:lower()
												and member
											then
												local issuer = guild:getMember(infraction.issuer)
													or Client:getUser(infraction.issuer)

												if it.role then
													if member and member:hasRole(it.role) then
														member:removeRole(it.role, "infraction expired")
													end
												end

												local offenderLink = member and sqldb:getLink(member.id)
												local offenderRoblox = offenderLink
													and ropi.GetUser(offenderLink.roblox)

												local issuerLink = issuer and sqldb:getLink(issuer.id)
												local issuerRoblox = issuerLink and ropi.GetUser(issuerLink.roblox)

												local variableMap = {
													["offender.discord.mention"] = member.mentionString,
													["offender.discord.name"] = member.name,
													["offender.discord.username"] = member.username,
													["offender.discord.id"] = member.id,
													["offender.discord.avatar"] = member.avatarURL,
													["issuer.discord.mention"] = (issuer and issuer.mentionString)
														or ("<@" .. infraction.issuer .. ">"),
													["issuer.discord.name"] = (issuer and issuer.name) or emojis.fail,
													["issuer.discord.username"] = (issuer and issuer.username)
														or emojis.fail,
													["issuer.discord.id"] = infraction.issuer,
													["issuer.discord.avatar"] = (issuer and issuer.avatarURL)
														or emojis.fail,
													["offender.roblox.display"] = (
														offenderRoblox and offenderRoblox.displayName
													) or "N/A",
													["offender.roblox.username"] = (
														offenderRoblox and offenderRoblox.name
													) or "N/A",
													["offender.roblox.id"] = (offenderRoblox and offenderRoblox.id)
														or "N/A",
													["offender.roblox.hyperlink"] = (
														offenderRoblox and offenderRoblox.hyperlink
													) or "N/A",
													["issuer.roblox.display"] = (
														issuerRoblox and issuerRoblox.displayName
													) or "N/A",
													["issuer.roblox.username"] = (issuerRoblox and issuerRoblox.name)
														or "N/A",
													["issuer.roblox.id"] = (issuerRoblox and issuerRoblox.id) or "N/A",
													["issuer.roblox.hyperlink"] = (
														issuerRoblox and issuerRoblox.hyperlink
													) or "N/A",
													["infraction.type"] = it.name,
													["infraction.reason"] = infraction.reason,
													["infraction.notes"] = infraction.notes,
													["infraction.id"] = tostring(infraction.id) or "N/A",
													["infraction.expires"] = infraction.expires or "N/A",
													["timestamp"] = tostring(os.time()),
												}

												if it.actions and it.revertActions then
													for _, ac in pairs(it.actions) do
														if ac.type == "sendcmd" then
															local parsedCommand = parseTable({
																ac.cmd,
															}, variableMap)[1]

															local params = string.split(parsedCommand, " ")
															local cmd

															if
																params[1]:usub(1, 2) == "un"
																and remoteInGameCommands[params[1]:usub(3)]
															then
																cmd = parsedCommand:usub(3)
															elseif remoteInGameCommands["un" .. params[1]] then
																cmd = "un" .. parsedCommand
															end

															local server = config.apikey
																and ERLC:getServer(config.apikey)

															if server and #server.players > 0 then
																local success, err = server:execute(parsedCommand)
																if success then
																	db:send(guild, "erlccmdschannel", {
																		embed = {
																			author = {
																				name = "@" .. issuer.user.username,
																				icon_url = issuer.user.avatarURL,
																			},
																			title = emojis.success
																				.. " Infraction Action Reversion Successful",
																			description = "> **@"
																				.. member.username
																				.. "**'s infraction was revoked by **@"
																				.. issuer.name
																				.. "**. Therefore, Ducky has reverted the infraction action `"
																				.. ac.cmd
																				.. "`.",
																			color = colors.success,
																			thumbnail = {
																				url = issuer.user.avatarURL,
																			},
																		},
																	})
																else
																	db:send(guild, "erlccmdschannel", {
																		embed = {
																			author = {
																				name = "@" .. issuer.user.username,
																				icon_url = issuer.user.avatarURL,
																			},
																			title = emojis.fail
																				.. " Infraction Action Reversion Failed",
																			description = "> **@"
																				.. member.username
																				.. "**'s infraction was revoked by **@"
																				.. issuer.name
																				.. "**. However, Ducky was unable to revert the infraction action `"
																				.. ac.cmd
																				.. "`: ```"
																				.. err
																				.. "```",
																			color = colors.fail,
																			thumbnail = {
																				url = issuer.user.avatarURL,
																			},
																		},
																	})
																end
															elseif sqldb:plusGuild(guild) then
																db:commandQueueInsert(member.guild, parsedCommand)
															end
														end
													end
												end
											end
										end

										table.remove(config.infractions, i)

										local member = guild:getMember(infraction.user)
											or Client:getUser(infraction.user)
										local issuer = guild:getMember(infraction.issuer)
											or Client:getUser(infraction.issuer)

										local embeds = parseTable(config.infractionexpireembeds or {
											{
												author = author(issuer),
												thumbnail = (member.avatarURL and { url = member.avatarURL })
													or (member.defaultAvatarURL and { url = member.defaultAvatarURL }),
												title = emojis.success .. " Infraction Expired",
												description = getUserString(member)
													.. "'s infraction has expired:\n"
													.. emojis.right
													.. " **Type:** "
													.. (infraction.type or "N/A")
													.. "\n"
													.. emojis.right
													.. " **Reason:** "
													.. (infraction.reason or "N/A")
													.. "\n"
													.. emojis.right
													.. " **Notes:** "
													.. (infraction.notes or "N/A")
													.. "\n"
													.. emojis.right
													.. " **Expired:** "
													.. ((infraction.expires and "<t:" .. infraction.expires .. ">") or "N/A")
													.. "\n"
													.. emojis.right
													.. " **Date:** <t:"
													.. (infraction.timestamp or os.time())
													.. ">\n"
													.. emojis.right
													.. " **Infraction ID:** `"
													.. infraction.id
													.. "`",
												color = colors.success,
											},
										}, {
											["issuer.mention"] = issuer.mentionString,
											["issuer.name"] = issuer.name,
											["issuer.username"] = issuer.username,
											["issuer.id"] = issuer.id,
											["issuer.avatar"] = issuer.avatarURL,
											["offender.mention"] = member.mentionString,
											["offender.name"] = member.name,
											["offender.username"] = member.username,
											["offender.id"] = member.id,
											["offender.avatar"] = member.avatarURL,
											["infraction.type"] = infraction.type,
											["infraction.reason"] = infraction.reason or "N/A",
											["infraction.notes"] = infraction.notes or "N/A",
											["infraction.expires"] = (
												infraction.expires and (os.time() + infraction.expires)
											) or "N/A",
											["infraction.id"] = tostring(infraction.id) or "N/A",
											["timestamp"] = tostring(os.time()),
										})

										for _, embed in ipairs(embeds) do
											if embed.description then
												embed.description = embed.description:gsub(
													"<t:([^:>]+):?[a-zA-Z]*>",
													function(val)
														if not tonumber(val) then
															return "N/A"
														end
														return "<t:" .. val .. ">"
													end
												)
											end
										end

										if config.infractionschannel then
											local target = (
												config.infractionthread and guild:getChannel(infraction.thread)
											) or guild:getChannel(config.infractionschannel)

											if target then
												target:send({ embeds = embeds })
											end
										end

										local userSettings = sqldb:getUserSettings(member.id)
										if not userSettings or userSettings.infractionnotifications ~= false then
											local sanitizedGuildName = sanitizeGuildName(guild.name)
											member:send({
												embeds = embeds,
												components = signature(guild),
											})
										end

										saveConfig({
											infractions = config.infractions,
										}, "INFRACTION_EXPIRE")
									end
								end
								debug(2.2)
							end

							debug(3)
							Client:emit("scheduleGiveaways", guild, config)

							Client:emit("scheduleLoas", guild, config)

							Client:emit("scheduleShifts", guild, config)
							debug(3.1)

							debug(4)
							if type(config.transcripts) == "table" and table.count(config.transcripts) > 0 then
								debug(4.1)
								local removedTranscript = false

								for ID, transcript in pairs(config.transcripts) do
									if
										type(transcript) ~= "table"
										or not transcript.generatedTimestamp
										or os.time() - transcript.generatedTimestamp > 2592000
									then
										config.transcripts[ID] = nil
										removedTranscript = true
									end
								end
								debug(4.2)

								if removedTranscript then
									sqldb:set(guild.id, {
										transcripts = config.transcripts,
									}, "REMOVE_EXPIRED_TRANSCRIPTS")
								end
								debug(4.3)
							end

							debug(5)
							if type(config.erlccache) == "table" and (not config.erlccache.lastCacheReset or (realtime() - config.erlccache.lastCacheReset >= 43200)) then
								debug(5.1)
								local server = config.apikey and ERLC:getServer(config.apikey)
								debug(5.2)
								if (not server) or #server.players <= 0 then
									debug(5.3)
									config.erlccache.vehicleHistory = nil
									config.erlccache.liveryHistory = nil
									config.erlccache.trollsHistory = nil
									config.erlccache.killedinHistory = nil
									config.erlccache.lastCacheReset = realtime()

									sqldb:set(guild.id, {
										erlccache = config.erlccache,
									}, "ERLCCACHE_12H_RESET")
									debug(5.4)
								end
							end

							debug(6)
							if
								config.discordserverstatuschannels
								and table.count(config.discordserverstatuschannels) > 0
							then
								debug(6.1)
								local lastUpdate = lastDiscordServerStatusUpdate[guildid] or 0

								if realtime() - lastUpdate > 600 then
									debug(6.2)
									lastDiscordServerStatusUpdate[guildid] = realtime()
									local modified = false

									loadMembers(guild)

									local varKeys = {
										["guild.name"] = guild.name,
										["guild.id"] = guild.id,
										["guild.members"] = formatNumber(tonumber(guild.totalMemberCount)),
										["guild.bots"] = formatNumber(#guild.bots),
										["guild.humans"] = (formatNumber(
											tonumber(guild.totalMemberCount) - #guild.bots
										)),
										["guild.boosts"] = guild.premiumSubscriptionCount,
										["guild.boostlevel"] = guild.premiumTier,
										["guild.roles"] = #guild.roles,
										["guild.textchannels"] = formatNumber(#guild.textChannels),
										["guild.voicechannels"] = formatNumber(#guild.voiceChannels),
										["guild.categories"] = formatNumber(#guild.categories),
									}

									debug(6.3)

									for i, v in pairs(config.discordserverstatuschannels) do
										if not v.locked then
											local voiceChannel = guild:getChannel(v.channel)

											if voiceChannel then
												local newContent, variablesReplaced = parseTable({
													v.content,
												}, varKeys)

												if variablesReplaced > 0 then
													if
														newContent
														and newContent[1]
														and newContent[1]:len() >= 1
														and voiceChannel.name ~= newContent[1]
													then
														voiceChannel:setName(newContent[1]:usub(1, 100))
													end
												end
											else
												table.remove(config.discordserverstatuschannels, i)
												modified = true
											end
										end
									end
									debug(6.4)

									if modified then
										debug(6.5)
										saveConfig({
											discordserverstatuschannels = config.discordserverstatuschannels,
										}, "DISCORD_STATUS_CHANNEL_UPDATE")
									end
									debug(6.6)
								end
							end
						else
							if config.removetimestamp then
								local removetimestamp = config.removetimestamp
								if (os.time() - removetimestamp) >= 604800 then
									sqldb:delete(guildid)

									utilityChannels.database:send(
										emojis.delete
											.. " Data from **`"
											.. guildid
											.. "`** has been deleted, as **"
											.. Client.user.name
											.. "** was removed from it <t:"
											.. removetimestamp
											.. ":R>."
									)
								end
							end
						end
					end)

					schedulerGuildsActive[guildid] = nil
					if not success then
						Client:error("SCHEDULER: Error processing guild " .. tostring(guildid) .. ": " .. tostring(err))
					end
				end)()
			end
		end)

		if not ok then
			Client:error("SCHEDULER: " .. err)
		end

		active = false
	end)
end

scheduler.Stop = function()
	Clock:removeListener("sec", connection)
	Clock:stop()
end

return scheduler