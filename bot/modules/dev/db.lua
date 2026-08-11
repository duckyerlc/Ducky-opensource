-- db.lua
local dbModule = {
	name = "db",
	description = "Manages complex database interactions."
}

local snowGen = snowflake.new(1, 2)

dbModule.Start = function()
	local db = {}

	local function dbFail(str)
		coroutine.wrap(function()
			prettyLog("DATABASE", "red", str)

			utilityChannels.database:send("```" .. str .. "```\n-# " .. emojis.clock .. " <t:" .. os.time() .. ":T>")
		end)()
	end

	function db:isDepartment(guild)
		local config = sqldb:get(guild.id) or {}
		local host = config.departmenthost and Client:getGuild(config.departmenthost)
		local hostConfig = host and (sqldb:get(host.id) or {})

		if host and hostConfig and hostConfig.departments and hostConfig.departments[guild.id] then
			return true, host, hostConfig.departments[guild.id]
		else
			return false
		end
	end

	function db:case(member, moderator, type, reason, length, guild)
		if (not reason) or (reason == "") then
			reason = "No reason provided."
		end
		guild = guild or member.guild
		local config = sqldb:get(guild.id) or {}
		config.cases = config.cases or {}

		local caseIDs = {}

		for _, CASE in pairs(config.cases) do
			table.insert(caseIDs, CASE.caseID)
		end

		local caseID = (caseIDs and table.count(caseIDs) > 0 and math.max(table.unpack(caseIDs)) + 1) or 1
		local caseinfo = {
			member = member.id,
			moderator = moderator.id,
			caseID = caseID,
			reason = reason,
			type = type,
			length = length,
			timestamp = os.time()
		}
		config.cases[caseID] = caseinfo
		local succ, c = sqldb:set(guild.id, {
			cases = config.cases
		}, "INSERT_MODERATION_CASE")
		config = c or config
		return config.cases[caseID]
	end

	local auditQueues = {}
	local processing = {}

	local function sendWebhook(ID, TOKEN, payload)
		local url = string.format("https://discord.com/api/v10/webhooks/%s/%s", ID, TOKEN)
		local headers = {
			{
				"Content-Type",
				"application/json"
			}
		}

		local body = json.encode(payload)
		local res, data = http.request("POST", url, headers, body)

		local success, result = pcall(json.decode, data)
		return res, result
	end

	function db:sendAuditLog(guildid, auditType, tosend)
		if not guildid or not tonumber(guildid) then
			return dbFail("db:sendAuditLog received invalid guildID.")
		end

		auditQueues[guildid] = auditQueues[guildid] or {}
		table.insert(auditQueues[guildid], {
			type = auditType,
			data = tosend
		})

		if not processing[guildid] then
			processing[guildid] = true
			coroutine.wrap(function()
				while #auditQueues[guildid] > 0 do
					local payload = table.remove(auditQueues[guildid], 1)
					local config = sqldb:get(guildid) or {}
					local auditType = payload.type
					local tosend = payload.data

					local function getAuditName(value)
						for i, v in pairs(auditTypes) do
							if v.value:lower() == value:lower() then
								return v.emoji.raw .. " " .. v.label
							end
						end
						return ""
					end

					local targetConfig = (config.auditlogchannels and config.auditlogchannels[auditType] and config.auditlogchannels[auditType].webhook and config.auditlogchannels[auditType].channel and config.auditlogchannels[auditType])
					local isPrimary = false
					if not targetConfig then
						targetConfig = config.auditlogchannels and config.auditlogchannels.primary and config.auditlogchannels.primary.webhook and config.auditlogchannels.primary.channel and config.auditlogchannels.primary
						isPrimary = not not targetConfig
					end

					if not targetConfig or not targetConfig.channel or not targetConfig.webhook then
						break
					end

					local ID, TOKEN = targetConfig.webhook.ID, targetConfig.webhook.TOKEN
					if not ID or not TOKEN then
						break
					end

					local res, data = sendWebhook(ID, TOKEN, {
						embeds = {
							tosend.embed
						}
					})

					if res.code == 429 then
						local retry = tonumber(data.retry_after) or 2
						timer.sleep(retry)
						table.insert(auditQueues[guildid], 1, payload)
					elseif res.code == 404 then
						dbFail("db:sendAuditLog webhook not found, disabling auditlog type " .. tostring(auditType) .. " for " .. tostring(guildid))

						config.auditlogchannels[isPrimary and "primary" or auditType] = nil
						sqldb:set(guildid, {
							auditlogchannels = config.auditlogchannels
						}, "AUDIT_LOG_" .. auditType:upper() .. "_WEBHOOK_INVALID")

						local guild = Client:getGuild(guildid)
						local ownerId = guild and guild.ownerId
						local owner = ownerId and guild:getMember(ownerId)
						if owner then
							owner:send({
								content = "# " .. emojis.warning .. " Audit Logs Disabled\n" .. emojis.right .. " The **" .. getAuditName(auditType) .. "** Audit Log in **" .. guild.name .. "** failed to send due to an invalid webhook.\n-# " .. emojis.right .. " The configuration for " .. (isPrimary and "the primary audit logs channel" or "this audit log type") .. " has therefore been removed.",
								components = discordia.Components():button({
									url = "https://discord.gg/w2dNr7vuKP",
									style = "link",
									label = "Ducky's Pond",
									emoji = resolvedEmojis.ducky
								}):raw()
							})
						end
						break
					end

					timer.sleep(500)
				end
				processing[guildid] = false
			end)()
		end
	end

	function db:send(guild, key, tosend, silent, sync)
		guild = (type(guild) == "string" and Client:getGuild(guild)) or guild

		local config = sqldb:get(guild.id)
		if not config or not config[key] then
			return
		end

		local channel = guild:getChannel(config[key])
		if (not channel) or not channel.send then
			return
		end

		if sync then
			return channel:send(tosend, silent)
		else
			coroutine.wrap(function()
				channel:send(tosend, silent)
			end)()
		end
	end

	function db:infract(member, infractionType, reason, issuer, notes, expires, interaction)
		local currentTime = os.time()

		local guild = member.guild or {}
		local config = sqldb:get(guild.id)
		if not config then
			return nil, "This guild's configuration could not be found."
		end

		local roleId = infractionType.role
		local role = guild:getRole(roleId)

		if roleId and not role then
			return nil, "The infraction role no longer exists."
		end

		if roleId and member.guild.ownerId ~= issuer.id then
			local issuerHighestRolePosition = issuer.highestRole and issuer.highestRole.position

			if not issuerHighestRolePosition then
				return nil, "Unable to determine the position of your highest role."
			end

			local rolePosition = role.position

			if not rolePosition then
				return nil, "Unable to determine the position of your highest role."
			end

			if rolePosition >= issuerHighestRolePosition then
				return nil, "The infraction role has a higher or equal position to your highest role."
			end
		end

		config.infractions = config.infractions or {}
		local infractionID = (interaction and interaction.id) or snowGen:next()
		local infractionEntry = {
			user = member.id,
			type = infractionType.name,
			reason = reason,
			timestamp = currentTime,
			issuer = issuer.id,
			id = infractionID,
			notes = notes,
			expires = (expires and (currentTime + expires)) or nil,
			message = nil,
			thread = nil
		}

		local extraNote = ""

		if roleId then
			local succ, result = canManageRole(roleId)

			if succ then
				member:addRole(roleId, "received infraction, ID: " .. infractionID)
			else
				for i, ti in pairs(config.infractiontypes) do
					if ti.name == infractionType.name then
						ti.role = nil
					end
				end

				sqldb:set(guild.id, {
					infractiontypes = config.infractiontypes
				}, "NO_PERMISSIONS_INFRACTION_ROLE")

				NotifyRemoveFromConfig(guild.id, emojis.quickfix .. " Staff Management", infractionType.name .. " Infraction Type Role", result)

				extraNote = "However, I do not have permission to give **" .. member.name .. "** the <@&" .. roleId .. ">. The owner has been notified, and it has been removed from the server configuration."
			end
		end

		coroutine.wrap(function()
			local embeds = config.infractionembeds or {
				{
					author = {
						name = "{issuer.username}",
						icon_url = "{issuer.avatar}"
					},
					thumbnail = {
						url = "{offender.avatar}"
					},
					title = emojis.error .. " Infraction Notice",
					description = emojis.right .. " **Staff Member:** {offender.mention}\n" .. emojis.right .. " **Type:** {infraction.type}\n" .. emojis.right .. " **Reason:** {infraction.reason}\n" .. emojis.right .. " **Notes:** {infraction.notes}\n" .. emojis.right .. " **Expires:** " .. ((expires and ("<t:" .. (currentTime + expires) .. "> (<t:" .. (currentTime + expires) .. ":R>)")) or "N/A") .. "\n" .. emojis.right .. " **Date:** <t:{timestamp}>\n-# " .. emojis.right .. " **Infraction ID:** `{infraction.id}`",
					color = _G.colors.error
				}
			}

			local keys = {
				["issuer.mention"] = issuer.mentionString,
				["issuer.name"] = issuer.name,
				["issuer.username"] = issuer.user.username,
				["issuer.id"] = issuer.id,
				["issuer.avatar"] = issuer.avatarURL,
				["offender.mention"] = member.mentionString,
				["offender.name"] = member.name,
				["offender.username"] = member.user.username,
				["offender.id"] = member.id,
				["offender.avatar"] = member.avatarURL,
				["infraction.type"] = infractionType.name,
				["infraction.reason"] = reason or "N/A",
				["infraction.notes"] = notes or "N/A",
				["infraction.expires"] = (expires and (currentTime + expires)) or "N/A",
				["infraction.id"] = infractionID or "N/A",
				["timestamp"] = tostring(currentTime)
			}

			embeds = parseTable(embeds, keys)

			for _, embed in ipairs(embeds) do
				if embed.description then
					embed.description = embed.description:gsub("<t:([^:>]+):?[a-zA-Z]*>", function(val)
						if not tonumber(val) then
							return "N/A"
						end
						return "<t:" .. val .. ">"
					end)
				end
			end

			local msg = db:send(guild, "infractionschannel", {
				content = "-# " .. _G.emojis.pings .. " " .. member.mentionString,
				embeds = embeds
			}, nil, true)

			local usersettings = sqldb:getUserSettings(member.id)

			if not usersettings or usersettings.infractionnotifications ~= false then
				member:send({
					embeds = embeds,
					components = signature(guild)
				})
			end

			if msg and msg.id then
				infractionEntry.message = msg.id

				if config.infractionthread then
					local defaultThreadName = "Infraction " .. infractionID .. " ・ " .. member.name
					local threadNameTemplate = config.infractionthread or defaultThreadName
					local parsedThreadName, _ = parseTable({
						threadNameTemplate
					}, keys)

					local finalThreadName = parsedThreadName[1] or defaultThreadName

					local truncatedName = string.truncate(finalThreadName, 100)
					local thread = msg.channel:startThread(truncatedName, msg.id)

					if thread then
						infractionEntry.thread = thread.id
					end
				end
			end

			table.insert(config.infractions, infractionEntry)
			sqldb:set(guild.id, {
				infractions = config.infractions
			}, "INFRACTION_ISSUE")
		end)()

		if infractionType.actions and next(infractionType.actions) then
			local r = interaction:reply({
				embed = {
					description = emojis.loading .. " Executing actions...",
					color = colors.blank
				}
			})

			local offenderLink = sqldb:getLink(member.id)
			local offenderRoblox = offenderLink and ropi.GetUser(offenderLink.roblox)

			local issuerLink = sqldb:getLink(issuer.id)
			local issuerRoblox = issuerLink and ropi.GetUser(issuerLink.roblox)

			local variableMap = {
				["offender.discord.mention"] = member.mentionString,
				["offender.discord.name"] = member.name,
				["offender.discord.username"] = member.user.username,
				["offender.discord.id"] = member.id,
				["offender.discord.avatar"] = member.avatarURL,
				["issuer.discord.mention"] = issuer.mentionString,
				["issuer.discord.name"] = issuer.name,
				["issuer.discord.username"] = issuer.user.username,
				["issuer.discord.id"] = issuer.id,
				["issuer.discord.avatar"] = issuer.avatarURL,
				["offender.roblox.display"] = (offenderRoblox and offenderRoblox.displayName) or "N/A",
				["offender.roblox.username"] = (offenderRoblox and offenderRoblox.name) or "N/A",
				["offender.roblox.id"] = (offenderRoblox and offenderRoblox.id) or "N/A",
				["offender.roblox.hyperlink"] = (offenderRoblox and offenderRoblox.hyperlink) or "N/A",
				["issuer.roblox.display"] = (issuerRoblox and issuerRoblox.displayName) or "N/A",
				["issuer.roblox.username"] = (issuerRoblox and issuerRoblox.name) or "N/A",
				["issuer.roblox.id"] = (issuerRoblox and issuerRoblox.id) or "N/A",
				["issuer.roblox.hyperlink"] = (issuerRoblox and issuerRoblox.hyperlink) or "N/A",
				["infraction.type"] = infractionType.name,
				["infraction.reason"] = reason,
				["infraction.notes"] = notes,
				["infraction.id"] = tostring(infractionID) or "N/A",
				["infraction.expires"] = (expires and (currentTime + expires)) or "N/A",
				["timestamp"] = tostring(currentTime)
			}

			local resultEmbed = {
				title = " Infraction Issue Result",
				description = "**" .. member.name .. "** has received an infraction" .. ((expires and (", and it will expire in **" .. readable(expires) .. "** (<t:" .. (os.time() + expires) .. ">). ")) or ". ") .. extraNote .. "\n",
				color = colors.success
			}

			for i, ac in pairs(infractionType.actions) do
				if ac.type == "sendmsg" then
					local targetChannel = guild:getChannel(ac.channel)

					if targetChannel then
						local parsedMessage = parseTable(ac.message, variableMap)

						local s, e = targetChannel:send(parsedMessage)

						if s then
							resultEmbed.description = resultEmbed.description .. "\n" .. emojis.right .. " " .. emojis.success .. " **Send a Message to <#" .. ac.channel .. ">**"
						else
							resultEmbed.description = resultEmbed.description .. "\n" .. emojis.right .. " " .. emojis.fail .. " **Send a Message to <#" .. ac.channel .. ">:** " .. e:usub(20)
						end
					else
						resultEmbed.description = resultEmbed.description .. "\n" .. emojis.right .. " " .. emojis.fail .. " **Send a Message:** Channel not found"
					end
				elseif ac.type == "sendcmd" then
					local parsedCommand = parseTable({
						ac.cmd
					}, variableMap)[1]

					local server = config.apikey and ERLC:getServer(config.apikey)

					if server and #server.players > 0 then
						local success, err = server:execute(parsedCommand)
						if success then
							db:send(guild, "erlccmdschannel", {
								embed = {
									author = {
										name = "@" .. issuer.user.username,
										icon_url = issuer.user.avatarURL
									},
									title = emojis.success .. " Infraction Action Executed",
									description = "> **@" .. member.username .. "** was infracted by **@" .. issuer.name .. "**. Therefore, Ducky has executed the infraction action `" .. ac.cmd .. "`.",
									color = colors.success,
									thumbnail = {
										url = issuer.user.avatarURL
									}
								}
							})

							resultEmbed.description = resultEmbed.description .. "\n" .. emojis.right .. " " .. emojis.success .. " **Send a Command**"
						else
							db:send(guild, "erlccmdschannel", {
								embed = {
									author = {
										name = "@" .. issuer.user.username,
										icon_url = issuer.user.avatarURL
									},
									title = emojis.fail .. " Infraction Action Failed",
									description = "> **@" .. member.username .. "** was infracted by **@" .. issuer.name .. "**. However, Ducky was unable to execute the infraction action `" .. ac.cmd .. "`: ```" .. err .. "```",
									color = colors.fail,
									thumbnail = {
										url = issuer.user.avatarURL
									}
								}
							})

							resultEmbed.description = resultEmbed.description .. "\n" .. emojis.right .. " " .. emojis.fail .. " **Send a Command:** " .. err
						end
					elseif sqldb:plusGuild(guild) then
						local success, err = db:commandQueueInsert(member.guild, parsedCommand)
						if success then
							resultEmbed.description = resultEmbed.description .. "\n" .. emojis.right .. " " .. emojis.loading .. " **Send a Command:** Added to ERLC Command Queue"
						else
							resultEmbed.description = resultEmbed.description .. "\n" .. emojis.right .. " " .. emojis.fail .. " **Send a Command:** " .. tostring(err)
						end
					end
				elseif ac.type == "delay" then
					timer.sleep(ac.delay)
					resultEmbed.description = resultEmbed.description .. "\n" .. emojis.right .. " " .. emojis.success .. " **Wait " .. readable(ac.delay) .. "**"
				end
			end

			if type(r) == "table" then
				r:update({
					embed = resultEmbed
				})
			else
				interaction:reply({
					embed = resultEmbed
				})
			end

			return false
		end

		return true, extraNote
	end

	function db:approveLOA(member)
		local guild = member.guild or {}
		local config = sqldb:get(guild.id)

		if not config then
			return nil, "This guild's configuration could not be found."
		end

		for i, v in pairs(config.loarequests or {}) do
			if v.user == member.id then
				config.loas = config.loas or {}
				table.insert(config.loas, {
					user = member.id,
					starts = os.time(),
					ends = os.time() + v.length,
					reason = v.reason,
					active = true
				})
				table.remove(config.loarequests, i)
				sqldb:set(guild.id, {
					loarequests = config.loarequests,
					loas = config.loas
				}, "LOA_APPROVE")

				if config.loarole then
					local succ, result = canManageRole(config.loarole)

					if succ then
						member:addRole(config.loarole, "LOA approved")
					else
						sqldb:set(guild.id, {
							loarole = "nil"
						}, "NO_PERMISSIONS_LOA_ROLE")

						NotifyRemoveFromConfig(guild.id, emojis.chart .. " Activity Management", "LOA Role", result)
					end
				end

				if config.loanickname then
					member:setNickname(parseTable({
						tostring(config.loanickname)
					}, {
						["member.name"] = member.name,
						["member.username"] = member.username
					})[1]:usub(1, 32))
				end

				member:send({
					embed = {
						description = emojis.success .. " Your LOA in **" .. member.guild.name .. "** has been " .. emojis.success .. " **approved**.\n" ..
							emojis.space .. emojis.right .. " **Length:** " .. readable(v.length) .. "\n" ..
							emojis.space .. emojis.right .. " **Ends:** <t:" .. (os.time() + v.length) .. ">\n" ..
							emojis.space .. emojis.right .. " **Reason:** " .. v.reason,
						color = colors.success
					}
				})
				return true
			end
		end
		return nil, "User does not have a pending LOA request."
	end

	function db:denyLOA(member, reason)
		local guild = member.guild or {}
		local config = sqldb:get(guild.id)
		if not config then
			return nil, "This guild's configuration could not be found."
		end
		for i, v in pairs(config.loarequests or {}) do
			if v.user == member.id then
				table.remove(config.loarequests, i)
				sqldb:set(guild.id, {
					loarequests = config.loarequests
				}, "LOA_DENY")
				coroutine.wrap(function()
					member:send({
						embed = {
							description = emojis.fail .. " Your LOA in **" .. member.guild.name .. "** has been " .. emojis.fail .. " **denied**" .. ((reason and "for **" .. reason .. "**") or "."),
							color = colors.fail
						}
					})
				end)()
				return true
			end
		end
		return nil, "User does not have a pending LOA request."
	end

	function db:endLOA(member, ender, config)
		local guild = member.guild or {}
		local config = config or sqldb:get(guild.id)
		if not config then
			return nil, "This guild's configuration could not be found."
		end

		for i, v in pairs(config.loas or {}) do
			if v.user == member.id and v.active then
				local started = v.starts
				local reason = v.reason
				v.active = false
				v.ends = os.time()
				sqldb:set(guild.id, {
					loas = config.loas
				}, "LOA_END")
				if config.loarole then
					member:removeRole(config.loarole, "LOA ended")
				end
				if config.loanickname then
					local link = sqldb:getLink(member.id)

					if link then
						updateMember(member, "LOA ended (LOA nickname reset)")
					else
						member:setNickname()
					end

				end
				db:send(guild, "loalogschannel", {
					embed = {
						description = emojis.right .. " " .. getUserString(member) .. "'s LOA has " .. ((ender and ("been " .. emojis.clock .. " **ended early** by " .. getUserString(ender) .. ".")) or emojis.warning .. " **expired**.") .. ".\n" ..
							emojis.space .. emojis.right .. " **Started:** <t:" .. started .. ">\n" ..
							emojis.space .. emojis.right .. " **Reason:** " .. reason,
						author = author(member),
						color = colors.fail
					}
				})
				member:send({
					embed = {
						description = emojis.right .. " Your LOA in **" .. member.guild.name .. "** has " .. ((ender and "been " .. emojis.clock .. " **ended early** by " .. getUserString(ender) .. ".") or "**expired**."),
						color = colors.warning
					}
				})
				return true, config
			end
		end
		return nil, "User does not have an active LOA."
	end

	function db:cancelPendingLoa(member, config)
		local guild = member.guild or {}
		local config = config or sqldb:get(guild.id)
		if not config then
			return nil, "This guild's configuration could not be found."
		end

		for i, v in pairs(config.loarequests or {}) do
			if v.user == member.id then
				table.remove(config.loarequests, i)
				sqldb:set(guild.id, {
					loarequests = config.loarequests
				}, "LOA_CANCEL_PENDING")

				db:send(guild, "loalogschannel", {
					embed = {
						description = emojis.warning .. " " .. getUserString(member) .. "'s LOA request has been " .. emojis.fail .. " **canceled**.",
						author = author(member),
						color = colors.warning
					}
				})

				member:send({
					embed = {
						description = emojis.warning .. " Your LOA request in **" .. member.guild.name .. "** has been " .. emojis.fail .. " **canceled**.",
						color = colors.warning
					}
				})

				return true, config
			end
		end
	end

	function db:getActiveLOA(member)
		local guild = member.guild or {}
		local config = sqldb:get(guild.id)
		if not config then
			return nil, "This guild's configuration could not be found."
		end
		for i, v in pairs(config.loas or {}) do
			if v.user == member.id and v.active then
				return v
			end
		end
		return nil, "You do not have an active LOA."
	end

	function db:getPendingLOA(member)
		local guild = member.guild or {}
		local config = sqldb:get(guild.id)
		if not config then
			return nil, "This guild's configuration could not be found."
		end
		for i, v in pairs(config.loarequests or {}) do
			if v.user == member.id then
				return v
			end
		end
		return nil, "You do not have a pending LOA."
	end

	function db:loaHistory(member)
		local guild = member.guild or {}
		local config = sqldb:get(guild.id)
		local loas = {}
		if not config then
			return nil, "This guild's configuration could not be found."
		end
		for i, loa in pairs(config.loas or {}) do
			if loa.user == member.id then
				table.insert(loas, loa)
			end
		end
		if loas and next(loas) then
			return loas
		else
			return nil, "This member has no LOA history."
		end
	end

	function db:loaTotal(member)
		local guild = member.guild or {}
		local config = sqldb:get(guild.id)
		local total = 0
		if not config then
			return total
		end
		for _, loa in pairs(config.loas or {}) do
			if loa.user == member.id then
				local length = loa.ends - loa.starts
				total = total + length
			end
		end
		return total
	end

	--[[

	shift waves are started by ERLC_MANAGERs using the `/shift wave start` command. the wave duration is defined on the Shift Management page, "Shift Wave Duration", but can be ended early via the `/shift wave end` command.

	example shifts table:

	shifts = {
		waves = {
			{ --shift wave object
				id = number (incremental, used to identify waves to avoid index issues),
				started = timestamp,
				ended = timestamp,
				shifts = {
					{ --shift log object
						member = snowflake,
						id = snowflake (used to identify a specific shift),
						type = string,
						started = timestamp,
						pauses = {
							{ --pause object
								started = timestamp,
								ended = timestamp/nil (if nil, still active)
							}
						},
						ended = timestamp/nil (if nil, still active),
						punishments = number,
						commands = number
					}
				}
			}
		},
		types = {
			{ --shift type object
				name = string,
				ondutyrole = snowflake,
				requiredroles = {snowflakes}
				-- other configurable options (i forgot what they were)
			}
		}
	}
	]]

	--- Validate shift type input and return the full shift type object.
	--- @param guild (Guild) The guild to get the shift type from.
	--- @param name (string) The name of the shift type to get. If nil, the first shift type in configuration will be returned unless none are configured.
	--- @return (table/false, string) The shift type object if found, otherwise false and an error message.
	function db:shiftType(guild, name, member)
		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.types = config.shifts.types or {}

		if not next(config.shifts.types) then
			return false, "No shift types have been configured for this server."
		end

		if member and ((not name) or (name == "")) then
			for _, shiftType in pairs(config.shifts.types) do
				if shiftType.requiredrole then
					local role = guild:getRole(shiftType.requiredrole)
					if role and member:hasRole(role.id) then
						return shiftType
					end
				else
					return shiftType
				end
			end
			return false, "You do not have the required role for any available shift type."
		end

		name = name or config.shifts.types[1].name

		for _, shiftType in pairs(config.shifts.types) do
			if table.count(config.shifts.types) == 1 or shiftType.name:lower() == name:lower() then
				if member and shiftType.requiredrole then
					local role = guild:getRole(shiftType.requiredrole)
					if role and not member:hasRole(role.id) then
						return false, "You are missing the " .. role.mentionString .. " role to access the `" .. shiftType.name .. "` shift type.", "You are missing the " .. role.name .. " role to access the '" .. shiftType.name .. "' shift type."
					end
				end
				return shiftType
			end
		end

		return false, "You did not provide a valid shift type."
	end

	--- Get the currently active shift wave, or a specific wave if a wave number is provided.
	--- @param guild (Guild) The guild to get the active shift wave from.
	--- @param waveNumber (number/nil) The specific wave number to get. If nil, the currently active wave will be returned.
	--- @return (table, index/false, string) The active shift wave object and index if found, otherwise false and an error message.
	function db:shiftWave(guild, waveNumber)
		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}

		local waveID = tonumber(waveNumber)

		for _, wave in pairs(config.shifts.waves) do
			if waveID then
				if wave.id == waveID then
					return wave
				end
			elseif (not wave.ended) or (wave.ended > os.time()) then
				return wave
			end
		end

		if waveNumber and ((waveID and waveNumber >= table.count(config.shifts.waves)) or not waveID) then
			return false, "**Wave " .. waveNumber .. "** has not started yet."
		end

		local wave = {
			id = table.count(config.shifts.waves) + 1,
			started = os.time(),
			shifts = {}
		}
		config.shifts.waves[wave.id] = wave
		local success, err = sqldb:set(guild.id, {
			shifts = config.shifts
		}, "SHIFT_WAVE_START")

		if not success then
			return false, "Failed to start a new shift wave: " .. err
		end

		return wave
	end

	--- End the active shift wave.
	--- @param guild (Guild) The guild to end the active shift wave for.
	--- @return (boolean, err) Whether or not the shift wave was ended successfully, otherwise false and an error.
	function db:shiftWaveEnd(guild, member)
		db:shiftEndAll(guild, member, nil, (member and "shift wave ended by " .. getUserString(member)) or "shift wave ended automatically as per configured interval")

		local wave, err = db:shiftWave(guild)
		if not wave then
			return false, err
		end

		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}
		config.shifts.waves[wave.id].ended = os.time()

		local success, err = sqldb:set(guild.id, {
			shifts = config.shifts
		}, "SHIFT_WAVE_END")
		if not success then
			return false, err
		end

		local wave = config.shifts.waves[wave.id]

		if member then
			db:send(guild, "shiftlogschannel", {
				embed = {
					author = author(member),
					title = emojis.cycle .. " Shift Wave Ended",
					description = emojis.right .. " " .. getUserString(member) .. " has ended **Wave " .. wave.id .. "** early.\n" .. emojis.space .. emojis.right .. " **Started:** <t:" .. wave.started .. "> (<t:" .. wave.started .. ":R>)\n" .. emojis.space .. emojis.right .. " **Ended:** <t:" .. wave.ended .. "> (<t:" .. wave.ended .. ":R>)\n" .. emojis.space .. emojis.right .. " **Shifts:** " .. table.count(wave.shifts) .. "\n",
					color = colors.fail
				}
			})
		else
			db:send(guild, "shiftlogschannel", {
				embed = {
					author = author(guild),
					title = emojis.cycle .. " Shift Wave Ended",
					description = emojis.right .. " **Wave " .. wave.id .. "** has been ended as per the configured wave interval.\n" .. emojis.space .. emojis.right .. " **Started:** <t:" .. wave.started .. "> (<t:" .. wave.started .. ":R>)\n" .. emojis.space .. emojis.right .. " **Ended:** <t:" .. wave.ended .. "> (<t:" .. wave.ended .. ":R>)\n" .. emojis.space .. emojis.right .. " **Shifts:** " .. table.count(wave.shifts) .. "\n",
					color = colors.fail
				}
			})
		end

		return true, wave
	end

	--- Merge shifts from other waves into a different wave.
	--- @param guild (Guild) The guild to merge shift waves in.
	--- @param fromWaveNumber (number/nil) The specific wave number to get. If nil, the currently active wave will be returned.
	--- @param toWaveNumber (number/nil) The specific wave number to get. If nil, the currently active wave will be returned.
	--- @return (boolean, err) Whether or not the shift wave was ended successfully, otherwise false and an error.
	function db:shiftWaveMerge(guild, member, fromWaveNumber, toWaveNumber)
		local fromWave, err = db:shiftWave(guild, fromWaveNumber)
		if not fromWave then
			return false, err
		end

		local fromCount = table.count(fromWave.shifts or {})

		local toWave, err = db:shiftWave(guild, toWaveNumber)
		if not toWave then
			return false, err
		end

		if fromWave.id == toWave.id then
			return false, "You cannot merge shifts into the same wave."
		end

		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}

		for i = table.count(fromWave.shifts or {}), 1, -1 do
			local shift = fromWave.shifts[i]

			table.insert(toWave.shifts, shift)
			table.remove(fromWave.shifts, i)
		end

		local success, err = sqldb:set(guild.id, {
			shifts = config.shifts
		}, "SHIFT_WAVE_MERGE")
		if not success then
			return false, err
		end

		local t = os.time()

		db:send(guild, "shiftlogschannel", {
			embed = {
				author = author(guild),
				title = emojis.merge .. " Shift Waves Merged",
				description = emojis.right .. " " .. getUserString(member) .. " has merged all **" .. fromCount .. " shifts** from **Wave " .. fromWave.id .. "** into **Wave " .. toWave.id .. "**.\n" .. emojis.space .. emojis.right .. " **Date:** <t:" .. t .. ">",
				color = colors.fail
			}
		})

		return true, toWave
	end

	--- Fetch the currently active shift for a member, along with a pause object if the shift is currently paused.
	--- @param member (Member) The member to get the active shift for.
	--- @return (table/nil) The active shift object and pause if found, otherwise nil.
	function db:shiftActive(member, guild)
		local guild = member.guild or guild
		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}

		for _, wave in pairs(config.shifts.waves) do
			for _, shift in pairs(wave.shifts) do
				if shift.member == member.id and not shift.ended then
					local pause = false

					for _, p in pairs(shift.pauses) do
						if not p.ended then
							pause = p
						end
					end

					return shift, pause
				end
			end
		end
	end

	--- Fetch a shift by its ID.
	--- @param guild (Guild) The guild to get the shift from.
	--- @param id (string) The ID of the shift to fetch.
	--- @return (table/false, string) The shift object if found, otherwise false and an error message.
	function db:shiftFetch(guild, id)
		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}

		for _, wave in pairs(config.shifts.waves) do
			for _, shift in pairs(wave.shifts) do
				if shift.id == id then
					return shift
				end
			end
		end

		return false, "There is no shift with that ID."
	end

	--- Modify a shift by its ID with the provided changes.
	--- @param guild (Guild) The guild to modify the shift in.
	--- @param id (string) The ID of the shift to modify.
	--- @param changes (table) A table of changes to apply to the shift.
	--- @return (table/false, string) The modified shift object if successful, otherwise false and an error message.
	function db:shiftModify(guild, id, changes)
		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}

		for _, wave in pairs(config.shifts.waves) do
			for _, shift in pairs(wave.shifts) do
				if shift.id == id then
					for k, v in pairs(changes) do
						shift[k] = v
					end

					local success, err = sqldb:set(guild.id, {
						shifts = config.shifts
					}, "SHIFT_MODIFY")

					if not success then
						return false, err
					end

					return shift
				end
			end
		end

		return false, "There is no shift with that ID."
	end

	--- Void a shift by its ID.
	--- @param member (Member) The member who voided the shift.
	--- @param id (string) The ID of the shift to fetch.
	--- @return (table/false, string) The shift object if found, otherwise false and an error message.
	function db:shiftVoid(member, id, wipe)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}

		for wi, wave in pairs(config.shifts.waves) do
			for si, shift in pairs(wave.shifts) do
				if shift.id == id then
					table.remove(config.shifts.waves[wi].shifts, si)

					if not wipe then
						db:send(guild, "shiftlogschannel", {
							embed = {
								author = author(member),
								title = emojis.ban .. " Shift Voided",
								description = emojis.right .. " " .. getUserString(administrator) .. " has voided a shift.\n" .. emojis.space .. emojis.right .. " **ID:** " .. id .. "\n" .. emojis.space .. emojis.right .. " **Date:** <t:" .. os.time() .. ">",
								color = colors.fail
							}
						})
					end

					local success, err = sqldb:set(guild.id, {
						shifts = config.shifts
					}, "SHIFT_VOID_" .. tostring(id))
					if not success then
						return false, err
					end

					return true, "That shift has been successfully voided."
				end
			end
		end

		return false, "There is no shift with that ID."
	end

	function db:shiftWipe(member, administrator)
		local guild = member.guild
		local wave, err = db:shiftWave(guild)
		if not wave then
			return false, err
		end

		for i = table.count(wave.shifts), 1, -1 do
			local shift = wave.shifts[i]
			if shift.member == member.id then
				db:shiftVoid(administrator, shift.id, true)
			end
		end

		db:send(guild, "shiftlogschannel", {
			embed = {
				author = author(member),
				title = emojis.delete .. " Shifts Wiped",
				description = emojis.right .. " " .. getUserString(administrator) .. " has wiped all of " .. getUserString(member) .. "'s shifts within **Wave " .. wave.id .. "**.\n" .. emojis.space .. emojis.right .. " **Date:** <t:" .. os.time() .. ">",
				color = colors.fail
			}
		})

		return true
	end

	function db:shiftInsert(guild, shift, waveNumber)
		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}

		local wave, err = db:shiftWave(guild, waveNumber)
		if not wave then
			return false, err
		end

		table.insert(config.shifts.waves[wave.id].shifts, shift)

		local success, err = sqldb:set(guild.id, {
			shifts = config.shifts
		}, "INSERT_SHIFT")
		if success then
			return true
		else
			return false, err
		end
	end

	function db:shiftTimeAdd(interaction, member, administrator, amount, typeName)
		local guild = member.guild

		local type, err = db:shiftType(guild, typeName, member)
		if not type then
			return false, err
		end

		local success, err = db:shiftInsert(guild, {
			member = member.id,
			id = interaction.id,
			type = type.name,
			started = os.time() - amount,
			pauses = {},
			ended = os.time(),
			punishments = 0,
			commands = 0
		})
		if not success then
			return false, err
		end

		db:send(guild, "shiftlogschannel", {
			embed = {
				author = author(member),
				title = emojis.add .. " Shift Time Added",
				description = emojis.right .. " " .. getUserString(administrator) .. " has added **" .. readable(amount) .. "** to " .. getUserString(member) .. "'s total **" .. type.name .. "** shift time.\n" .. emojis.space .. emojis.right .. " **Date:** <t:" .. os.time() .. ">",
				color = colors.success
			}
		})

		return true
	end

	function db:shiftTimeRemove(interaction, member, administrator, amount, typeName)
		local guild = member.guild

		local type, err = db:shiftType(guild, typeName, member)
		if not type then
			return false, err
		end

		local success, err = db:shiftInsert(guild, {
			member = member.id,
			id = interaction.id,
			type = type.name,
			started = os.time(),
			pauses = {},
			ended = os.time() - amount,
			punishments = 0,
			commands = 0
		})
		if not success then
			return false, err
		end

		db:send(guild, "shiftlogschannel", {
			embed = {
				author = author(member),
				title = emojis.subtract .. " Shift Time Removed",
				description = emojis.right .. " " .. getUserString(administrator) .. " has removed **" .. readable(amount) .. "** from " .. getUserString(member) .. "'s total **" .. type.name .. "** shift time.\n" .. emojis.space .. emojis.right .. " **Date:** <t:" .. os.time() .. ">",
				color = colors.fail
			}
		})

		return true
	end

	local function triggerShiftAutomation(member, shift, state, config)
		if config.automations then
			for _, automation in pairs(config.automations) do
				local splitTrigger = string.split(automation.trigger.value, ":")
				local trigger = splitTrigger[1]
				local value = (splitTrigger[2] and tonumber(splitTrigger[2])) or splitTrigger[2]

				if trigger == "shiftUpdate" and (value == "any" or value == state) then
					local elapsed, paused = db:shiftElapsed(member.guild, shift.id)

					local keys = {
						["shift.status"] = (state == "on" and "Active") or (state == "break" and "Paused") or (state == "off" and "Ended"),
						["shift.started"] = shift.started,
						["shift.ended"] = shift.ended or emojis.fail,
						["shift.elapsed"] = readable(elapsed),
						["shift.punishments"] = shift.punishments,
						["shift.commands"] = shift.commands,
						["shift.pauses"] = table.count(shift.pauses),
						["shift.pausetime"] = readable(paused),
						["shift.type"] = shift.type,
						["timestamp"] = os.time()
					}

					keys = DiscordUserVariables(member, "staff.discord", keys)

					local link = sqldb:getLink(member.id)
					local robloxUser = link and ropi.GetUser(link.roblox)

					keys = RobloxUserVariables(robloxUser, "staff.roblox", keys)

					runAutomation(automation, config, member.guild, nil, keys)
				end
			end
		end
	end

	--- Start a shift for a member of a specified type.
	--- @param interaction (Interaction) The interaction that triggered the shift start. Can also be a table with field `id`, value is used for the shift ID.
	--- @param member (Member) The member to start the shift for.
	--- @param typeName (string) The name of the shift type to start.
	--- @return (boolean, string) True and a success message if the shift was started, otherwise false and an error message.
	function db:shiftStart(interaction, member, typeName, fromGame)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}
		config.shifts.types = config.shifts.types or {}

		if config.shifts.gamelock and config.apikey and (not fromGame) then
			local server = config.apikey and ERLC:getServer(config.apikey)
			local link = sqldb:getLink(member.id)
			if link then
				local ingame = table.find(server and server._players or {}, function(p)
					return p.id == link.roblox
				end)

				if not ingame then
					return false, "You must be in-game to start your shift."
				end
			else
				return false, "You must be in-game to start your shift, however your Roblox account is not linked. Run the **`/link`** command to get started."
			end
		end

		local active, pause = db:shiftActive(member)
		if pause then
			active.pauses[table.count(active.pauses)].ended = os.time()
			db:shiftModify(guild, active.id, active)

			local pause = active.pauses[table.count(active.pauses)]

			db:send(guild, "shiftlogschannel", {
				embed = {
					author = author(member),
					title = emojis.play .. " Shift Resumed",
					description = emojis.right .. " " .. getUserString(member) .. " has resumed their **" .. active.type .. "** shift.\n" .. emojis.space .. emojis.right .. " **Started:** <t:" .. active.started .. ":T> (<t:" .. active.started .. ":R>)\n" .. emojis.space .. emojis.right .. " **Paused:** <t:" .. pause.started .. ":T> (<t:" .. pause.started .. ":R>)\n" .. emojis.space .. emojis.right .. " **Resumed:** <t:" .. pause.ended .. ":T> (<t:" .. pause.ended .. ":R>)\n" .. emojis.space .. emojis.right .. " **Pause Duration:** " .. readable(pause.ended - pause.started) .. "\n" .. emojis.space .. emojis.right .. " **ID:** `" .. active.id .. "`",
					color = colors.success
				}
			})

			coroutine.wrap(triggerShiftAutomation)(member, active, "on", config)

			coroutine.wrap(function()
				local type = db:shiftType(guild, active.type, member)
				if type and type.onshiftrole and not member:hasRole(type.onshiftrole) then
					member:addRole(type.onshiftrole, "resumed " .. type.name .. " shift")
				end
				if type and type.onpauserole and member:hasRole(type.onpauserole) then
					member:removeRole(type.onpauserole, "resumed " .. type.name .. " shift")
				end
				if type and type.nicknameprefix and active.nickname then
					member:setNickname(string.truncate(type.nicknameprefix .. " " .. active.nickname, 32))
				end
			end)()

			return true, "Your " .. active.type .. " shift has been resumed."
		elseif active then
			return false, "Your " .. active.type .. " shift is already active."
		end

		local type, err, igerr = db:shiftType(guild, typeName, member)
		if not type then
			return false, err, igerr
		end

		local wave, err = db:shiftWave(guild)
		if not wave then
			return false, err
		end

		local shift = {
			member = member.id,
			nickname = member.name,
			id = interaction.id,
			type = type.name,
			started = os.time(),
			pauses = {},
			ended = nil,
			punishments = 0,
			commands = 0
		}
		table.insert(config.shifts.waves[wave.id].shifts, shift)

		sqldb:set(guild.id, {
			shifts = config.shifts
		}, "SHIFT_START")

		db:send(guild, "shiftlogschannel", {
			embed = {
				author = author(member),
				title = emojis.play .. " Shift Started",
				description = emojis.right .. " " .. getUserString(member) .. " has started their **" .. shift.type .. "** shift.\n" .. emojis.space .. emojis.right .. " **Started:** <t:" .. shift.started .. ":T> (<t:" .. shift.started .. ":R>)\n" .. emojis.space .. emojis.right .. " **ID:** `" .. shift.id .. "`",
				color = colors.success
			}
		})

		coroutine.wrap(triggerShiftAutomation)(member, shift, "on", config)

		coroutine.wrap(function()
			if type and type.onshiftrole and not member:hasRole(type.onshiftrole) then
				member:addRole(type.onshiftrole, "started " .. type.name .. " shift")
			end
			if type and type.onpauserole and member:hasRole(type.onpauserole) then
				member:removeRole(type.onpauserole, "started " .. type.name .. " shift")
			end
			if type and type.nicknameprefix and shift.nickname then
				member:setNickname(string.truncate(type.nicknameprefix .. " " .. shift.nickname, 32))
			end
		end)()

		return shift, "Your " .. type.name .. " shift has been started."
	end

	--- Pause the currently active shift for a member.
	--- @param member (Member) The member to pause the shift for.
	--- @return (boolean, string) True and a success message if the shift was paused, otherwise false and an error message.
	function db:shiftPause(member)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}

		local active, pause = db:shiftActive(member)

		if not active then
			return false, "You do not have an active shift."
		elseif pause then
			return false, "Your " .. active.type .. " shift is already paused."
		end

		local pause = {
			started = os.time()
		}

		table.insert(active.pauses, pause)
		db:shiftModify(guild, active.id, active)

		db:send(guild, "shiftlogschannel", {
			embed = {
				author = author(member),
				title = emojis.pause .. " Shift Paused",
				description = emojis.right .. " " .. getUserString(member) .. " has paused their **" .. active.type .. "** shift.\n" .. emojis.space .. emojis.right .. " **Started:** <t:" .. active.started .. ":T> (<t:" .. active.started .. ":R>)\n" .. emojis.space .. emojis.right .. " **Paused:** <t:" .. pause.started .. ":T> (<t:" .. pause.started .. ":R>)\n" .. emojis.space .. emojis.right .. " **ID:** `" .. active.id .. "`",
				color = colors.warning
			}
		})

		coroutine.wrap(triggerShiftAutomation)(member, active, "break", config)

		coroutine.wrap(function()
			local type = db:shiftType(guild, active.type, member)
			if type and type.onshiftrole and member:hasRole(type.onshiftrole) then
				member:removeRole(type.onshiftrole, "paused " .. type.name .. " shift")
			end
			if type and type.onpauserole and not member:hasRole(type.onpauserole) then
				member:addRole(type.onpauserole, "paused " .. type.name .. " shift")
			end
			if type and type.nicknameprefix and active.nickname then
				member:setNickname(string.truncate(active.nickname, 32))
			end
		end)()

		return true, "Your " .. active.type .. " shift has been paused."
	end

	--- Ends the currently active shift for a member.
	--- @param member (Member) The member to end the shift for.
	--- @return (boolean, string) True and a success message if the shift was ended, otherwise false and an error message.
	function db:shiftEnd(member, bulk)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}

		local active, pause = db:shiftActive(member)

		if not active then
			return false, "You do not have an active shift."
		elseif pause then
			active.pauses[table.count(active.pauses)].ended = os.time()
		end

		active.ended = os.time()
		db:shiftModify(guild, active.id, active)

		if not bulk then
			local elapsed, paused = db:shiftElapsed(guild, active.id)
			db:send(guild, "shiftlogschannel", {
				embed = {
					author = author(member),
					title = emojis.stop .. " Shift Ended",
					description = emojis.right .. " " .. getUserString(member) .. " has ended their **" .. active.type .. "** shift.\n" .. emojis.space .. emojis.right .. " **Started:** <t:" .. active.started .. ":T> (<t:" .. active.started .. ":R>)\n" .. emojis.space .. emojis.right .. " **Pauses:** " .. table.count(active.pauses) .. " (" .. readable(paused) .. ")\n" .. emojis.space .. emojis.right .. " **Ended:** <t:" .. active.ended .. ":T> (<t:" .. active.ended .. ":R>)\n" .. emojis.space .. emojis.right .. " **Elapsed:** " .. readable(elapsed) .. "\n" .. emojis.space .. emojis.right .. " **Punishments:** " .. active.punishments .. "\n" .. emojis.space .. emojis.right .. " **Commands:** " .. active.commands .. "\n" .. emojis.space .. emojis.right .. " **ID:** `" .. active.id .. "`",
					color = colors.fail
				}
			})
		end

		coroutine.wrap(triggerShiftAutomation)(member, active, "off", config)

		coroutine.wrap(function()
			local type = db:shiftType(guild, active.type, member)
			if type and type.onshiftrole and member:hasRole(type.onshiftrole) then
				member:removeRole(type.onshiftrole, "ended " .. type.name .. " shift")
			end
			if type and type.onpauserole and member:hasRole(type.onpauserole) then
				member:removeRole(type.onpauserole, "ended " .. type.name .. " shift")
			end
			if type and type.nicknameprefix and active.nickname then
				member:setNickname(string.truncate(active.nickname, 32))
			end
		end)()

		return true, "Your " .. active.type .. " shift has been ended."
	end

	--- Ends the currently active shift for a user that is longer in the target guild.
	--- @param user (User) The user to end the shift for.
	--- @return (boolean, string) True and a success message if the shift was ended, otherwise false and an error message.
	function db:shiftForceEnd(user, guild)
		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}

		local active, pause = db:shiftActive(user, guild)

		if not active then
			return false, getUserString(user) .. " does not have an active shift."
		elseif pause then
			active.pauses[table.count(active.pauses)].ended = os.time()
		end

		active.ended = os.time()
		db:shiftModify(guild, active.id, active)

		local elapsed, paused = db:shiftElapsed(guild, active.id)
		db:send(guild, "shiftlogschannel", {
			embed = {
				author = author(user),
				title = emojis.stop .. " Shift Force Ended",
				description = emojis.right .. " " .. getUserString(user) .. "'s **" .. active.type .. "** shift has been forced ended as they are no longer a member of this server.\n" .. emojis.space .. emojis.right .. " **Started:** <t:" .. active.started .. ":T> (<t:" .. active.started .. ":R>)\n" .. emojis.space .. emojis.right .. " **Pauses:** " .. table.count(active.pauses) .. " (" .. readable(paused) .. ")\n" .. emojis.space .. emojis.right .. " **Ended:** <t:" .. active.ended .. ":T> (<t:" .. active.ended .. ":R>)\n" .. emojis.space .. emojis.right .. " **Elapsed:** " .. readable(elapsed) .. "\n" .. emojis.space .. emojis.right .. " **Punishments:** " .. active.punishments .. "\n" .. emojis.space .. emojis.right .. " **Commands:** " .. active.commands .. "\n" .. emojis.space .. emojis.right .. " **ID:** `" .. active.id .. "`",
				color = colors.fail
			}
		})

		return true, getUserString(user) .. "'s " .. active.type .. " shift has been ended by force."
	end

	function db:shiftEndAll(guild, member, type, reason)
		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}

		local wave, err = db:shiftWave(guild)
		if not wave then
			return false, err
		end

		type = db:shiftType(guild, type, nil, true)

		local t = os.time()

		for _, shift in pairs(wave.shifts or {}) do
			if (not shift.ended) and ((type and shift.type == type.name) or (not type)) then
				local member = guild:getMember(shift.member)

				if member then
					db:shiftEnd(member, true)
				end
			end
		end

		if member then
			db:send(guild, "shiftlogschannel", {
				embed = {
					author = author(member),
					title = emojis.stop .. " All Shifts Ended",
					description = emojis.right .. " " .. getUserString(member) .. " has ended all active" .. ((type and (" **" .. type.name .. "**")) or "") .. " shifts.\n" .. emojis.space .. emojis.right .. " **Date:** <t:" .. t .. ">",
					color = colors.fail
				}
			})
		else
			db:send(guild, "shiftlogschannel", {
				embed = {
					title = emojis.stop .. " All Shifts Ended",
					description = emojis.right .. " All active" .. ((type and (" **" .. type.name .. "**")) or "") .. " shifts have been ended.\n" .. emojis.space .. emojis.right .. " **Reason:** " .. (reason or emojis.fail) .. "\n" .. emojis.space .. emojis.right .. " **Date:** <t:" .. t .. ">",
					color = colors.fail
				}
			})
		end

		return true, "All active" .. ((type and type.name and (" **" .. type.name .. "**")) or "") .. " shifts have been ended."
	end

	--- Calculate the total elapsed time for a shift, accounting for pauses.
	--- @param guild (Guild) The guild to get the shift from.
	--- @param id (string) The ID of the shift to calculate elapsed time for.
	--- @return (number) The total elapsed time in seconds.
	function db:shiftElapsed(guild, id)
		local shift = db:shiftFetch(guild, id)

		local elapsed = (shift.ended or os.time()) - shift.started
		local paused = 0

		for _, pause in pairs(shift.pauses) do
			local t = (pause.ended or os.time()) - pause.started
			elapsed = elapsed - t
			paused = paused + t
		end

		return elapsed, paused
	end

	--- Fetch the shift history for a member, optionally filtered by shift type and wave number.
	--- @param member (Member) The member to get the shift history for.
	--- @param typeName (string/nil) The name of the shift type to filter by. If nil, all types are included.
	--- @param waveNumber (number/nil) The wave number to filter by.
	--- @return (table/false, string) A table of shift objects if found, otherwise false and an error message.
	function db:shiftHistory(member, typeName, waveNumber)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}
		config.shifts.types = config.shifts.types or {}

		local type, err = typeName and db:shiftType(guild, typeName)
		if typeName and not type then
			return false, err
		end

		local wave, err = db:shiftWave(guild, waveNumber)
		if not wave then
			return false, err
		end

		local history = {}
		local total = 0

		for _, shift in pairs(wave.shifts) do
			if shift.member == member.id then
				if (type and type.name and shift.type == type.name) or (not type) then
					table.insert(history, shift)
					total = total + db:shiftElapsed(guild, shift.id)
				end
			end
		end

		return history
	end

	--- Calculate the total elapsed time for a member's shifts, optionally filtered by shift type and wave number.
	--- @param member (Member) The member to calculate total shift time for.
	--- @param typeName (string/nil) The name of the shift type to filter by. If nil, all types are included.
	--- @param waveNumber (number/nil) The wave number to filter by.
	function db:shiftTotal(member, typeName, waveNumber, excludeActive)
		local guild = member.guild
		local history, err = db:shiftHistory(member, typeName, waveNumber)
		if not history then
			return false, err
		end

		local total = 0

		for _, shift in pairs(history) do
			if ((not shift.ended) and (not excludeActive)) or shift.ended then
				total = total + db:shiftElapsed(guild, shift.id)
			end
		end

		return total
	end

	--[[

	example config.session value:
		
		{
			status = "active/shutdown/vote/staffvote",
			initiator = "598958193032560642",
			timestamp = 1743195871,
			votes = {},
			votesRequired = 5,
			message = "1355286619372130397"
		}
		
	]]
	--

	function db:sessionStart(initiator)
		local guild = initiator.guild
		local config = sqldb:get(guild and guild.id)
		if not config then
			return false, "This server is not configured."
		end

		local sessionsChannel = config.sessionschannel and guild:getChannel(config.sessionschannel)
		if not sessionsChannel then
			return false, "This server's sessions channel could not be found."
		end

		local server = config.apikey and ERLC:getServer(config.apikey)

		if config.apikey and not server then
			return false, "An unexpected error occurred while fetching server data. Please try again later."
		end

		local session = config.session or {}
		if session.status == "active" then
			return false, "This server's session is already active."
		end

		local tosend = {
			content = (parsePings(parseMentionables(guild, config.sessionmentionables or {}, config.sessionspinghere or false, config.sessionspingeveryone or false)) or "") .. ((session.votes and ("\n-# " .. emojis.people .. " **Voters:** " .. table.concatFn(session.votes, ", ", function(v)
				return "<@" .. v .. ">"
			end))) or ""),
			embeds = parseTable(config.ssuembeds or {
				{
					author = {
						name = guild.name,
						icon_url = guild.iconURL
					},
					title = emojis.game .. " Session Start-Up",
					description = "> The in-game server has started up! Join the server for some great roleplays!\n" .. emojis.game .. " **Server Information**\n" .. emojis.right .. " **Server Name:** {server.name}\n" .. emojis.right .. " **Server Players:** {server.players}/{server.maxplayers}\n" .. emojis.right .. " **Server Code:** [`{server.code}`](https://erlc.gg/join/{server.code})\n" .. emojis.right .. " **Server Owner:** {owner.hyperlink}",
					color = colors.success,
					footer = {
						text = "Session startup by {initiator.name}",
						icon_url = "{initiator.avatar}"
					}
				}
			}, DiscordUserVariables(initiator, "initiator", RobloxUserVariables(ropi.GetUser(server and server.owner), "owner", {
				["server.name"] = (config.serverInfo and config.serverInfo.name) or (server and server.name) or "N/A",
				["server.players"] = (server and tostring(#server.players)) or "N/A",
				["server.maxplayers"] = (config.serverInfo and config.serverInfo.MaxPlayers) or (server and tostring(server.maxPlayercount)) or "N/A",
				["server.code"] = (config.serverInfo and config.serverInfo.JoinKey) or (server and server.joinCode) or "N/A",
				["timestamp"] = tostring(os.time())
			}))),
			components = (((config.serverInfo and config.serverInfo.JoinKey) or (server and server.joinCode)) and discordia.Components():button({
				url = "https://erlc.gg/join/" .. ((config.serverInfo and config.serverInfo.JoinKey) or (server and server.joinCode)),
				label = "Quick Join",
				emoji = resolvedEmojis.game,
				style = "link"
			}):raw())
		}

		local vote = session.status == "vote" and sessionsChannel:getMessage(session.message)

		if vote then
			vote:update({
				content = vote.content,
				embed = vote.embed,
				components = disableComponents(vote.components)
			})
		end

		local message, err = sessionsChannel:send(tosend)

		if message then
			config.session = {
				status = "active",
				initiator = initiator.id,
				timestamp = os.time(),
				message = message.id
			}

			sqldb:set(guild.id, {
				session = config.session
			}, "SESSION_START")

			return message
		else
			return nil, err
		end
	end

	function db:sessionEnd(initiator)
		local guild = initiator.guild
		local config = sqldb:get(guild and guild.id)
		if not config then
			return false, "This server is not configured."
		end

		local sessionsChannel = config.sessionschannel and guild:getChannel(config.sessionschannel)
		if not sessionsChannel then
			return false, "This server's sessions channel could not be found."
		end

		local session = config.session or {}
		if session.status == "shutdown" then
			return false, "This server's session is not active."
		end

		local tosend = {
			embeds = parseTable(config.ssdembeds or {
				{
					author = {
						name = guild.name,
						icon_url = guild.iconURL
					},
					title = emojis.game .. " Session Shutdown",
					description = "> The in-game server has now shutdown. A new session will be initiated by server management at a later time. Thank you for joining!\n> -# " .. emojis.warning .. " Please do not join the in-game server at this time. You may be moderated if you do so.",
					color = colors.fail,
					footer = {
						text = "Session shutdown by {initiator.name}",
						icon_url = "{initiator.avatar}"
					}
				}
			}, DiscordUserVariables(initiator, "initiator", {
				["session.started"] = (session.status == "active" and session.timestamp and tostring(session.timestamp)) or emojis.fail,
				["timestamp"] = tostring(os.time())
			}))
		}

		local vote = session.status == "vote" and sessionsChannel:getMessage(session.message)

		if vote then
			vote:update({
				content = vote.content,
				embed = vote.embed,
				components = disableComponents(vote.components)
			})
		end

		local message, err = sessionsChannel:send(tosend)

		if message then
			config.session = {
				status = "shutdown",
				initiator = initiator.id,
				timestamp = os.time(),
				message = message.id
			}

			sqldb:set(guild.id, {
				session = config.session
			}, "SESSION_SHUTDOWN")

			return message
		else
			return nil, err
		end
	end

	function db:sessionVote(initiator, votesRequired, autoStart)
		local guild = initiator.guild
		local config = sqldb:get(guild and guild.id)
		if not config then
			return false, "This server is not configured."
		end

		local sessionsChannel = config.sessionschannel and guild:getChannel(config.sessionschannel)
		if not sessionsChannel then
			return false, "This server's sessions channel could not be found."
		end

		local session = config.session or {}
		if session.status ~= "shutdown" and session.status ~= "staffvote" and session.status ~= nil then
			return false, "This server's session is not shutdown."
		end

		votesRequired = votesRequired and math.abs(votesRequired)

		local tosend = {
			content = parsePings(parseMentionables(guild, config.sessionmentionables or {}, config.sessionspinghere or false, config.sessionspingeveryone or false)),
			embeds = parseTable(config.voteembeds or {
				{
					author = {
						name = guild.name,
						icon_url = guild.iconURL
					},
					title = emojis.game .. " Session Vote",
					description = "> The in-game server session may be started soon. Press the **Vote** button below to vote for the session. If this vote receives at least **{votes.required} votes**, a session will be started!\n> -# If you vote, you are **required** to join. Failure to do so may result in moderation.",
					color = colors.info,
					footer = {
						text = "Session vote initiated by {initiator.name}",
						icon_url = "{initiator.avatar}"
					}
				}
			}, DiscordUserVariables(initiator, "initiator", {
				["votes.received"] = "0",
				["votes.required"] = tostring(votesRequired),
				["timestamp"] = tostring(os.time())
			})),
			components = discordia.Components():button({
				id = "vote",
				label = "Vote (0/" .. votesRequired .. ")",
				style = "success",
				emoji = resolvedEmojis.yeswhite
			}):button({
				id = "show",
				label = "Voters",
				emoji = resolvedEmojis.people,
				style = "secondary"
			}):raw()
		}

		local staffvote = session.status == "staffvote" and session.channel and guild:getChannel(session.channel) and guild:getChannel(session.channel):getMessage(session.message)

		if staffvote then
			staffvote:update({
				content = staffvote.content,
				embed = staffvote.embed,
				components = disableComponents(staffvote.components)
			})
		end

		local message, err = sessionsChannel:send(tosend)

		if message then
			config.session = {
				status = "vote",
				initiator = initiator.id,
				timestamp = os.time(),
				message = message.id,
				votes = {},
				votesRequired = votesRequired,
				autoStart = autoStart
			}

			sqldb:set(guild.id, {
				session = config.session
			}, "SESSION_VOTE")

			return message
		else
			return nil, err
		end

		return true
	end

	function db:sessionStaffVote(initiator, channel, votesRequired, autoStart, publicVotesRequired)
		local guild = initiator.guild
		local config = sqldb:get(guild and guild.id)
		if not config then
			return false, "This server is not configured."
		end

		local allStaffRoleIDs = {}

		for _, erlcstaffroleID in pairs(config.erlcstaffroles or {}) do
			table.insert(allStaffRoleIDs, erlcstaffroleID)
		end

		for _, erlcadminroleID in pairs(config.erlcadminroles or {}) do
			table.insert(allStaffRoleIDs, erlcadminroleID)
		end

		for _, erlcmanagerroleID in pairs(config.erlcmanagerroles or {}) do
			table.insert(allStaffRoleIDs, erlcmanagerroleID)
		end

		if not next(allStaffRoleIDs) then
			return false, "This server does not have any **ERLC Staff Roles** configured."
		end

		local session = config.session or {}
		if session.status ~= "shutdown" and session.status ~= nil then
			return false, "This server's session is not shutdown."
		end

		votesRequired = votesRequired and math.abs(votesRequired)

		local tosend = {
			content = parsePings(parseMentionables(guild, allStaffRoleIDs)),
			embeds = parseTable(config.staffvoteembeds or {
				{
					author = {
						name = guild.name,
						icon_url = guild.iconURL
					},
					title = emojis.game .. " Session Staff Vote",
					description = "> The in-game server session may be started soon. If you will be able to attend the session, press the **Vote** button below. If this staff vote receives at least **{votes.required} votes**, a **public** session vote will be started!\n> -# If you vote, you are **required** to join. Failure to do so may result in an infraction.",
					color = colors.info,
					footer = {
						text = "Session staff vote initiated by {initiator.name}",
						icon_url = "{initiator.avatar}"
					}
				}
			}, DiscordUserVariables(initiator, "initiator", {
				["votes.received"] = "0",
				["votes.required"] = tostring(votesRequired),
				["timestamp"] = tostring(os.time())
			})),
			components = discordia.Components():button({
				id = "vote",
				label = "Vote (0/" .. votesRequired .. ")",
				style = "success",
				emoji = resolvedEmojis.yeswhite
			}):button({
				id = "show",
				label = "Voters",
				emoji = resolvedEmojis.people,
				style = "secondary"
			}):raw()
		}

		local message, err = channel:send(tosend)

		if message then
			config.session = {
				status = "staffvote",
				initiator = initiator.id,
				timestamp = os.time(),
				message = message.id,
				channel = channel.id,
				votes = {},
				votesRequired = votesRequired,
				autoStart = autoStart,
				publicVotesRequired = publicVotesRequired
			}

			sqldb:set(guild.id, {
				session = config.session
			}, "SESSION_STAFF_VOTE")

			return message
		else
			return nil, err
		end
	end

	function db:sessionLow(initiator)
		local guild = initiator.guild
		local config = sqldb:get(guild and guild.id)
		if not config then
			return false, "This server is not configured."
		end

		local sessionsChannel = config.sessionschannel and guild:getChannel(config.sessionschannel)
		if not sessionsChannel then
			return false, "This server's sessions channel could not be found."
		end

		local server = config.apikey and ERLC:getServer(config.apikey)

		if config.apikey and not server then
			return false, "An unexpected error occurred while fetching server data. Please try again later."
		end

		local session = config.session or {}
		if session.status ~= "active" then
			return false, "This server's session is not active."
		end

		local tosend = {
			content = (parsePings(parseMentionables(guild, config.sessionmentionables or {}, config.sessionspinghere or false, config.sessionspingeveryone or false)) or "") .. ((session.votes and ("\n-# " .. emojis.people .. " **Voters:** " .. table.concatFn(session.votes, ", ", function(v)
				return "<@" .. v .. ">"
			end))) or ""),
			embeds = parseTable(config.lowembeds or {
				{
					author = {
						name = guild.name,
						icon_url = guild.iconURL
					},
					title = emojis.game .. " Session Low",
					description = "> The in-game server is running low on players. Please join for some amazing roleplays!\n" .. emojis.game .. " **Server Information**\n" .. emojis.right .. " **Server Name:** {server.name}\n" .. emojis.right .. " **Server Players:** {server.players}/{server.maxplayers}\n" .. emojis.right .. " **Server Code:** [`{server.code}`](https://erlc.gg/join/{server.code})\n" .. emojis.right .. " **Server Owner:** {owner.hyperlink}",
					color = colors.warning,
					footer = {
						text = "Session low notification initiated by {initiator.name}",
						icon_url = "{initiator.avatar}"
					}
				}
			}, DiscordUserVariables(initiator, "initiator", RobloxUserVariables(ropi.GetUser(server and server.owner), "owner", {
				["server.name"] = (config.serverInfo and config.serverInfo.name) or (server and server.name) or "N/A",
				["server.players"] = (server and tostring(#server.players)) or "N/A",
				["server.maxplayers"] = (config.serverInfo and config.serverInfo.MaxPlayers) or (server and server.maxPlayercount) or "N/A",
				["server.code"] = (config.serverInfo and config.serverInfo.JoinKey) or (server and server.joinCode) or "N/A",
				["timestamp"] = tostring(os.time())
			}))),
			components = (((config.serverInfo and config.serverInfo.JoinKey) or (server and server.joinCode)) and discordia.Components():button({
				url = "https://erlc.gg/join/" .. ((config.serverInfo and config.serverInfo.JoinKey) or (server and server.joinCode)),
				label = "Quick Join",
				emoji = resolvedEmojis.game,
				style = "link"
			}):raw())
		}

		local message, err = sessionsChannel:send(tosend)

		if message then
			return message
		else
			return nil, err
		end
	end

	function db:sessionFull(initiator)
		local guild = initiator.guild
		local config = sqldb:get(guild and guild.id)
		if not config then
			return false, "This server is not configured."
		end

		local sessionsChannel = config.sessionschannel and guild:getChannel(config.sessionschannel)
		if not sessionsChannel then
			return false, "This server's sessions channel could not be found."
		end

		local server = config.apikey and ERLC:getServer(config.apikey)

		if config.apikey and not server then
			return false, "An unexpected error occurred while fetching server data. Please try again later."
		end

		local serverInfo = table.deepcopy(config.serverInfo or {})

		local session = config.session or {}
		if session.status ~= "active" then
			return false, "This server's session is not active."
		end

		local tosend = {
			embeds = parseTable(config.fullembeds or {
				{
					author = {
						name = guild.name,
						icon_url = guild.iconURL
					},
					title = emojis.game .. " Session Full",
					description = "> As of <t:{timestamp}:R>, the in-game server is now **FULL**! Keep trying to join for some amazing roleplays!\n" .. emojis.game .. " **Server Information**\n" .. emojis.right .. " **Server Name:** {server.name}\n" .. emojis.right .. " **Server Players:** {server.players}/{server.maxplayers}\n" .. emojis.right .. " **Server Code:** [`{server.code}`](https://erlc.gg/join/{server.code})\n" .. emojis.right .. " **Server Owner:** {owner.hyperlink}",
					color = colors.warning,
					footer = {
						text = "Session full notification initiated by {initiator.name}",
						icon_url = "{initiator.avatar}"
					}
				}
			}, DiscordUserVariables(initiator, "initiator", RobloxUserVariables(ropi.GetUser(server and server.owner), "owner", {
				["server.name"] = serverInfo.Name or (server and server.name) or "N/A",
				["server.players"] = (server and tostring(#server.players)) or "N/A",
				["server.maxplayers"] = serverInfo.MaxPlayers or (server and tostring(server.maxPlayercount)) or "N/A",
				["server.code"] = serverInfo.JoinKey or (server and server.joinCode) or "N/A",
				["timestamp"] = tostring(os.time())
			}))),
			components = ((serverInfo.JoinKey or (server and server.joinCode)) and discordia.Components():button({
				url = "https://erlc.gg/join/" .. (serverInfo.JoinKey or (server and server.joinCode)),
				label = "Quick Join",
				emoji = resolvedEmojis.game,
				style = "link"
			}):raw())
		}

		local message, err = sessionsChannel:send(tosend)

		if message then
			return message
		else
			return nil, err
		end
	end

	function db:createBOLO(robloxUser, reason, moderator, evidence, config, interaction)
		reason = type(reason) == "string" and reason:trim() or "No reason provided"

		local newBOLO = {
			user = robloxUser.id,
			reason = reason,
			moderator = moderator.id,
			created = os.time(),
			evidence = evidence,
			id = interaction.id
		}

		local guild = moderator.guild or {}
		local config = config or sqldb:get(guild.id)

		if not config then
			return false, "This guild's configuration could not be found."
		end
		if not config.bolologschannel then
			return false, "You have not configured a BOLO logs channel."
		end

		config.bolos = config.bolos or {}

		for i, bolo in pairs(config.bolos) do
			if bolo.user == robloxUser.id then
				return false, "That player already has an active BOLO."
			end
		end

		table.insert(config.bolos, newBOLO)

		sqldb:set(guild.id, {
			bolos = config.bolos
		}, "BOLO_CREATE")

		db:send(moderator.guild, "bolologschannel", {
			content = (parsePings(parseMentionables(guild, config.bolologmentionables or {})) or ""),
			embed = {
				title = emojis.moderate .. " BOLO Created",
				description = "**" .. moderator.name .. "** created a BOLO on [**" .. robloxUser.name .. "**](" .. robloxUser.profile .. ") for **" .. reason .. "**." .. ((newBOLO.evidence and "\n" .. emojis.right .. " **Evidence:** [Attachment](" .. newBOLO.evidence .. ")") or ""),
				color = colors.warning,
				thumbnail = {
					url = robloxUser.avatar
				},
				image = (newBOLO.evidence and {
					url = newBOLO.evidence
				}) or nil
			},
			components = discordia.Components():button({
				id = "approve_" .. newBOLO.id,
				emoji = resolvedEmojis.yeswhite,
				style = "success"
			}):button({
				id = "deny_" .. newBOLO.id,
				emoji = resolvedEmojis.nowhite,
				style = "danger"
			}):raw()
		})

		return newBOLO
	end

	function db:completeBOLO(player, moderator, config, alreadyBanned)
		local guild = moderator.guild
		local config = config or sqldb:get(guild.id) or {}
		config.bolos = config.bolos or {}

		local bolo, i = table.find(config.bolos, function(b)
			return b.user == player.id
		end)
		if not bolo then
			return false, "That player does not have a pending BOLO, or the BOLO has already been completed."
		end

		local creator = bolo.moderator
		local reason = bolo.reason

		table.remove(config.bolos, i)
		db:punishmentCreate({
			id = snowGen:next()
		}, moderator, player, "Ban", reason)
		sqldb:set(guild.id, {
			bolos = config.bolos
		}, "BOLO_COMPLETE")

		db:send(moderator.guild, "bolologschannel", {
			embed = {
				title = emojis.moderate .. " BOLO Completed",
				description = "**" .. moderator.name .. "** completed the BOLO on " .. player.hyperlink .. ".\n" .. emojis.right .. " **BOLO Creator:** <@" .. tostring(creator) .. ">\n" .. emojis.right .. " **BOLO Reason:** " .. tostring(reason or emojis.fail) .. ((bolo.evidence and "\n" .. emojis.space .. emojis.right .. " **Evidence:** [Attachment](" .. bolo.evidence .. ")") or ""),
				color = colors.success,
				thumbnail = {
					url = player.avatar
				},
				image = (bolo.evidence and {
					url = bolo.evidence
				}) or nil
			}
		})

		if not alreadyBanned then
			local server = config.apikey and ERLC:getServer(config.apikey)
			if #server.players > 0 then
				local success, err = server:execute(":ban " .. player.id)
				if not success then
					return true, "The BOLO has been completed, however the player could not be banned: " .. tostring(err), true
				end

				return true, "The BOLO has been completed and the player has been banned in-game."
			else
				local plus = sqldb:plusGuild(guild)
				if plus then
					local success, err = db:commandQueueInsert(guild, ":ban " .. player.id)
					if not success then
						return true, "The BOLO has been completed, however the ban command could not be queued: " .. tostring(err), true
					end
					
					return true, "The BOLO has been completed and the command to ban the player has been queued for when the server is online."
				else
					return true, "The BOLO has been completed, however the server is offline and therefore they could not be banned.", true
				end
			end
		end

		return true, "The BOLO has been completed."
	end

	function db:denyBOLO(robloxUser, moderator, config)
		local guild = moderator.guild or {}
		config = config or sqldb:get(guild.id)

		if not config then
			return false, "This guild's configuration could not be found."
		end

		config.bolos = config.bolos or {}

		for i, bolo in pairs(config.bolos) do
			if bolo.user == robloxUser.id then
				local BOLOCreator = bolo.moderator
				local BOLOReason = bolo.reason
				table.remove(config.bolos, i)
				sqldb:set(guild.id, {
					bolos = config.bolos
				}, "BOLO_DENY")

				db:send(moderator.guild, "bolologschannel", {
					embed = {
						title = emojis.moderate .. " BOLO Denied",
						description = "**" .. moderator.name .. "** denied the BOLO on **" .. robloxUser.hyperlink .. "**.\n" .. emojis.right .. " **BOLO Creator:** <@" .. tostring(BOLOCreator) .. ">\n" .. emojis.right .. " **BOLO Reason:** " .. tostring(BOLOReason or "N/A") .. ((bolo.evidence and "\n" .. emojis.space .. emojis.right .. " **Evidence:** [Attachment](" .. bolo.evidence .. ")") or ""),
						color = colors.fail,
						thumbnail = {
							url = robloxUser.avatar
						},
						image = (bolo.evidence and {
							url = bolo.evidence
						}) or nil
					}
				})

				return true
			end
		end

		return false, "That player does not have a pending BOLO, or the BOLO has already been completed."
	end

	function db:getActiveBOLO(guild, robloxUser, config)
		local config = config or sqldb:get(guild and guild.id)

		if config then
			if config.bolos then
				for i, v in pairs(config.bolos) do
					if v.user == robloxUser.id then
						return v
					end
				end
			end
		end

		return nil
	end

	function db:punishmentCreate(interaction, moderator, player, pType, reason, evidence, expires)
		reason = type(reason) == "string" and reason:trim() or "No reason provided"

		local punishment = {
			player = player.id,
			type = pType,
			reason = reason,
			moderator = moderator.id,
			evidence = evidence,
			expires = expires,
			id = interaction.id,
			timestamp = os.time()
		}

		local guild = moderator.guild
		local config = sqldb:get(guild.id) or {}
		config.punishments = config.punishments or {}
		table.insert(config.punishments, punishment)

		local active = db:shiftActive(moderator)
		if active then
			db:shiftModify(guild, active.id, {
				punishments = active.punishments + 1
			})
		end

		sqldb:set(guild.id, {
			punishments = config.punishments
		}, "PUNISHMENT_CREATE")

		coroutine.wrap(function()
			local link = sqldb:getLink(player.id)
			local mode = "ingame"

			if link then
				local userSettings = sqldb:getUserSettings(link.discord) or {}
				if userSettings and userSettings.punishmentnotifications then
					mode = userSettings.punishmentnotifications
				end
			end

			local server = config.apikey and ERLC:getServer(config.apikey)
			if (mode == "ingame" or mode == "both") and server and (not punishment.type:lower():find("kick")) and (not punishment.type:lower():find("ban")) then
				local plr = table.find(server._players, function(p)
					return tonumber(p.id) == tonumber(player.id)
				end)

				if plr then
					server:execute(":pm " .. plr.name .. " ⚠️・You have been punished with a " .. punishment.type .. " for " .. punishment.reason .. ".", config.apikey)
				end
			end

			if not config.apikey or (mode == "dms" or mode == "both") then
				local member = (link and link.discord and moderator.guild:getMember(link.discord)) or nil

				if member then
					member:send({
						embed = {
							title = emojis.warning .. " Punishment Received",
							description = emojis.right .. " You received a punishment in **" .. guild.name .. "**.\n" .. emojis.space .. emojis.right .. " **Player:** " .. player.hyperlink .. "\n" .. emojis.space .. emojis.right .. " **Type:** " .. punishment.type .. "\n" .. emojis.space .. emojis.right .. " **Reason:** " .. punishment.reason .. ((punishment.evidence and "\n" .. emojis.space .. emojis.right .. " **Evidence:** [Attachment](" .. punishment.evidence .. ")") or "") .. ((punishment.expires and "\n" .. emojis.space .. emojis.right .. " **Expires:** <t:" .. punishment.expires .. "> (<t:" .. punishment.expires .. ":R>)") or "") .. "\n" .. emojis.space .. emojis.right .. " **ID:** `" .. punishment.id .. "`",
							color = colors.warning,
							thumbnail = {
								url = player.avatar
							},
							author = {
								name = guild.name,
								icon_url = guild.iconURL
							},
							image = (punishment.evidence and {
								url = punishment.evidence
							}) or nil
						}
					})
				end
			end

			db:send(guild, "punishmentlogschannel", {
				content = ((not punishment.reason) and ("-# " .. emojis.warning .. " " .. moderator.mentionString .. ", you did not provide a reason for this punishment.")) or nil,
				embed = {
					title = emojis.moderate .. " Punishment Logged",
					description = emojis.right .. " " .. getUserString(moderator) .. " logged a punishment on **" .. player.hyperlink .. "**.\n" .. emojis.space .. emojis.right .. " **Moderator:** " .. moderator.mentionString .. "\n" .. emojis.space .. emojis.right .. " **Player:** " .. player.hyperlink .. "\n" .. emojis.space .. emojis.right .. " **Type:** " .. punishment.type .. "\n" .. emojis.space .. emojis.right .. " **Reason:** " .. punishment.reason .. ((punishment.evidence and "\n" .. emojis.space .. emojis.right .. " **Evidence:** [Attachment](" .. punishment.evidence .. ")") or "") .. ((punishment.expires and "\n" .. emojis.space .. emojis.right .. " **Expires:** <t:" .. punishment.expires .. "> (<t:" .. punishment.expires .. ":R>)") or "") .. "\n" .. emojis.space .. emojis.right .. " **ID:** `" .. punishment.id .. "`",
					color = colors.success,
					thumbnail = player.avatar and {
						url = player.avatar
					},
					author = author(moderator),
					image = (punishment.evidence and {
						url = punishment.evidence
					}) or nil
				},
				components = ((not punishment.reason) and discordia.Components():button({
					id = "editpunishment_" .. punishment.id,
					label = "Edit Reason",
					emoji = resolvedEmojis.edit,
					style = "blurple"
				}) or nil)
			})
		end)()

		return punishment
	end

	function db:punishmentEdit(moderator, id, reason)
		local guild = moderator.guild
		local config = sqldb:get(guild.id) or {}
		local punishments = config.punishments or {}

		for index, punishment in pairs(punishments) do
			if punishment.id == id then
				local player = ropi.GetUser(punishment.player)
				local previous = punishment.reason or "No reason provided."
				punishment.reason = reason
				sqldb:set(guild.id, {
					punishments = punishments
				}, "EDIT_PUNISHMENT")
				db:send(guild, "punishmentlogschannel", {
					embed = {
						title = emojis.edit .. " Punishment Edited",
						description = emojis.right .. " " .. getUserString(moderator) .. " edited a punishment on **" .. player.hyperlink .. "**.\n" .. emojis.space .. emojis.right .. " **Moderator:** " .. moderator.mentionString .. "\n" .. emojis.space .. emojis.right .. " **Player:** " .. player.hyperlink .. "\n" .. emojis.space .. emojis.right .. " **Type:** " .. punishment.type .. "\n" .. emojis.space .. emojis.right .. " **Old Reason:** " .. previous .. "\n" .. emojis.space .. emojis.right .. " **New Reason:** " .. punishment.reason .. ((punishment.evidence and "\n" .. emojis.space .. emojis.right .. " **Evidence:** [Attachment](" .. punishment.evidence .. ")") or "") .. ((punishment.expires and "\n" .. emojis.space .. emojis.right .. " **Expires:** <t:" .. punishment.expires .. "> (<t:" .. punishment.expires .. ":R>)") or "") .. "\n" .. emojis.space .. emojis.right .. " **ID:** `" .. punishment.id .. "`",
						color = colors.warning,
						thumbnail = player.avatar and {
							url = player.avatar
						},
						author = author(moderator),
						image = (punishment.evidence and {
							url = punishment.evidence
						}) or nil
					}
				})
				return punishment
			end
		end

		return false, "That punishment was not found."
	end

	function db:punishmentDelete(moderator, id)
		local guild = moderator.guild
		local config = sqldb:get(guild.id) or {}
		local punishments = config.punishments or {}

		for index, punishment in pairs(punishments) do
			if punishment.id == id then
				local player = ropi.GetUser(punishment.player)
				table.remove(punishments, index)
				sqldb:set(guild.id, {
					punishments = punishments
				}, "DELETE_PUNISHMENT")
				db:send(guild, "punishmentlogschannel", {
					embed = {
						title = emojis.delete .. " Punishment Deleted",
						description = emojis.right .. " " .. getUserString(moderator) .. " deleted a punishment on **" .. player.hyperlink .. "**.\n" .. emojis.space .. emojis.right .. " **Moderator:** " .. moderator.mentionString .. "\n" .. emojis.space .. emojis.right .. " **Player:** " .. player.hyperlink .. "\n" .. emojis.space .. emojis.right .. " **Type:** " .. punishment.type .. "\n" .. emojis.space .. emojis.right .. " **Old Reason:** " .. punishment.reason .. "\n" .. emojis.space .. emojis.right .. " **New Reason:** " .. punishment.reason .. ((punishment.evidence and "\n" .. emojis.space .. emojis.right .. " **Evidence:** [Attachment](" .. punishment.evidence .. ")") or "") .. ((punishment.expires and "\n" .. emojis.space .. emojis.right .. " **Expires:** <t:" .. punishment.expires .. "> (<t:" .. punishment.expires .. ":R>)") or "") .. "\n" .. emojis.space .. emojis.right .. " **ID:** `" .. punishment.id .. "`",
						color = colors.fail,
						thumbnail = player.avatar and {
							url = player.avatar
						},
						author = author(moderator),
						image = (punishment.evidence and {
							url = punishment.evidence
						}) or nil
					}
				})
				return true
			end
		end

		return false, "That punishment was not found."
	end

	--[[
	
	config.economy = {
		currency = string, -- for example if someone wants to set the currency to "USD" or a custom emoji such as "<:robux:id>"
		initial = number, -- initial balance for all users
		multipliers = {
			["Snowflake"] = number -- for example, for 0.5x decrease, set to 0.5, for 2x increase, set to 2; Snowflake should be role ID
		},
		replies = {
			beg = {
				{ -- reply object
					message = string,
					success = boolean
				}
			}
		}
		limits = {
			beg = { -- limit object
				min = number,
				max = number
			},
			work = {
				min = number,
				max = number
			}
		},
		cooldowns = {
			beg = number,
			work = number,
			...etc...
		},
		shop = {
			{ -- item object
				name = string,
				description = ?string, -- optional description
				price = number,
				role = ?Snowflake, -- the optional role to be given on purchase,
				id = Snowflake -- unique identifier for the item
			}
		},
		accounts = {
			{ -- account object
				member = Snowflake, -- user id
				balance = {
					wallet = number,
					bank = number
				},
				inventory = {}, -- store item Snowflake IDs only
				cooldowns = {}, -- store last action timestamps (such as [cooldowns.beg = epoch])
			}
		},
		bounties = {
			{ -- bounty object
				player = number, -- roblox user id
				started = number, -- epoch timestamp
				payments = {
					{ -- payment object
						member = Snowflake, -- discord user id
						amount = number, -- amount paid
						reason = ?string, -- optional reason for paying this amount towards the bounty
						timestamp = number, -- epoch timestamp
					}
				}
			}
		}
	}
	]]

	function db:ecoFetch(member)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.accounts = config.economy.accounts or {}

		for _, account in pairs(config.economy.accounts) do
			if account.member == member.id then
				account.cooldowns = account.cooldowns or {}
				account.balance = account.balance or {
					wallet = 0,
					bank = 0
				}
				account.inventory = account.inventory or {}

				return table.deepcopy(account)
			end
		end

		local account = {
			member = member.id,
			balance = {
				wallet = 0,
				bank = math.round(config.economy.initial or 0)
			},
			inventory = {},
			cooldowns = {},
			keys = {}
		}
		table.insert(config.economy.accounts, account)

		local success, err = sqldb:set(guild.id, {
			economy = config.economy
		}, "ECONOMY_CREATE_ACCOUNT")
		if not success then
			return false, err
		end

		return table.deepcopy(account)
	end

	function db:ecoModify(member, changes)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.accounts = config.economy.accounts or {}

		for i, account in pairs(config.economy.accounts) do
			if account.member == member.id then
				for key, value in pairs(changes) do
					account[key] = value
				end

				local success, err = sqldb:set(guild.id, {
					economy = config.economy
				}, "ECONOMY_MODIFY_ACCOUNT")
				if not success then
					return false, err
				end

				return account
			end
		end

		return false, "That member does not have an account registered."
	end

	function db:ecoDelete(member)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.accounts = config.economy.accounts or {}

		for i, account in pairs(config.economy.accounts) do
			if account.member == member.id then
				table.remove(config.economy.accounts, i)

				local success, err = sqldb:set(guild.id, {
					economy = config.economy
				}, "ECONOMY_DELETE_ACCOUNT")
				if not success then
					return false, err
				end

				return true
			end
		end

		return false, "That member does not have an account registered."
	end

	function db:ecoBalance(member, target, amount)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.accounts = config.economy.accounts or {}

		local account, err = db:ecoFetch(member)
		if not account then
			return false, err
		end

		if type(amount) == "number" and (amount < 0) then
			amount = math.clamp(amount, 0, math.huge)
		elseif type(amount) == "table" then
			amount.wallet = math.clamp(amount.wallet, 0, math.huge)
			amount.bank = math.clamp(amount.bank, 0, math.huge)
		end

		if target and target:lower() == "wallet" then
			account.balance.wallet = math.round(amount)

			local success, err = db:ecoModify(member, {
				balance = account.balance
			})
			if not success then
				return false, err
			end

			return success
		elseif target and target:lower() == "bank" then
			account.balance.bank = math.round(amount)

			local success, err = db:ecoModify(member, {
				balance = account.balance
			})
			if not success then
				return false, err
			end

			return success
		else
			account.balance = amount

			local success, err = db:ecoModify(member, {
				balance = account.balance
			})
			if not success then
				return false, err
			end

			return success
		end

		return false, "You did not provide a valid target."
	end

	function db:ecoDeposit(member, amount)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.accounts = config.economy.accounts or {}
		amount = tonumber(amount)

		local account, err = db:ecoFetch(member)
		if not account then
			return false, err
		end

		if amount <= 0 then
			return false, "The amount must be greater than zero."
		elseif account.balance.wallet < amount then
			return false, "You cannot deposit more money than you have in your wallet."
		end

		account.balance.wallet = account.balance.wallet - amount
		account.balance.bank = account.balance.bank + amount

		local success, err = db:ecoBalance(member, nil, account.balance)
		if not success then
			return false, err
		end

		return true
	end

	function db:ecoWithdraw(member, amount)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.accounts = config.economy.accounts or {}
		amount = tonumber(amount)

		local account, err = db:ecoFetch(member)
		if not account then
			return false, err
		end

		if amount <= 0 then
			return false, "The amount must be greater than zero."
		elseif account.balance.bank < amount then
			return false, "You cannot deposit more money than you have in your bank."
		end

		account.balance.wallet = account.balance.wallet + amount
		account.balance.bank = account.balance.bank - amount

		local success, err = db:ecoBalance(member, nil, account.balance)
		if not success then
			return false, err
		end

		return true
	end

	function db:ecoItem(member, id)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.shop = config.economy.shop or {}
		config.economy.accounts = config.economy.accounts or {}

		local account, err = db:ecoFetch(member)
		if not account then
			return false, err
		end
		account.inventory = account.inventory or {}

		local hasItem = false

		for _, item in pairs(config.economy.shop) do
			if item.id == id then
				if table.find(account.inventory, id) then
					hasItem = true
				end
				return item, hasItem
			end
		end

		return false, "That item does not exist."
	end

	function db:ecoPurchase(member, id)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.shop = config.economy.shop or {}
		config.economy.accounts = config.economy.accounts or {}

		local account, err = db:ecoFetch(member)
		if not account then
			return false, err
		end

		local item, err = db:ecoItem(member, id)
		if not item then
			return false, err
		end

		if account.balance.wallet < item.price then
			return false, "You need " .. (config.economy.currency or emojis.quack) .. "** " .. formatNumber((item.price - account.balance.wallet)) .. "** more money to purchase this item."
		end

		account.balance.wallet = account.balance.wallet - item.price
		table.insert(account.inventory, item.id)

		local success, err = db:ecoModify(member, {
			balance = account.balance,
			inventory = account.inventory
		})
		if not success then
			return false, err
		else
			db:send(guild, "economylogchannel", {
				embed = {
					title = emojis.shop .. " Item Purchased",
					author = author(member),
					color = colors.success,
					description = getUserString(member) .. " has purchased **" .. item.name .. "**:" .. "\n" .. emojis.space .. emojis.right .. " **Price:** " .. (item.price and formatNumber(item.price or 0)) .. "\n" .. emojis.space .. emojis.right .. " **Use on Purchase:** " .. ((item.useonpurchase and emojis.success) or emojis.fail) .. "\n" .. emojis.space .. emojis.right .. " **Item ID:** " .. item.id
				}
			})
		end

		return true
	end

	function db:ecoItemUse(member, id)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.shop = config.economy.shop or {}
		config.economy.accounts = config.economy.accounts or {}

		local account, err = db:ecoFetch(member)
		if not account then
			return false, err
		end

		local hasItem = false
		local index
		for i, itemId in ipairs(account.inventory) do
			if itemId == id then
				hasItem = true
				index = i
				break
			end
		end

		if not hasItem then
			return false, "You do not own this item."
		end

		local item
		for _, shopItem in pairs(config.economy.shop) do
			if shopItem.id == id then
				item = shopItem
				break
			end
		end

		if not item then
			return false, "That item does not exist in the shop."
		end

		local gaveRole = false
		if item.role then
			local role = guild:getRole(item.role)
			if role then
				if not member:hasRole(item.role) then
					member:addRole(item.role)
					gaveRole = true
				end
			end
		end

		table.remove(account.inventory, index)
		local success, err = db:ecoModify(member, {
			inventory = account.inventory
		})
		if not success then
			return false, err
		else
			db:send(guild, "economylogchannel", {
				embed = {
					title = emojis.shop .. " Item Used",
					author = author(member),
					color = colors.success,
					description = getUserString(member) .. " has used **" .. item.name .. "**:" .. "\n" .. emojis.space .. emojis.right .. " **Item Price:** " .. (item.price and formatNumber(item.price or 0)) .. "\n" .. emojis.space .. emojis.right .. " **Gave Role:** " .. ((gaveRole and "<@&" .. item.role .. ">") or emojis.fail) .. "\n" .. emojis.space .. emojis.right .. " **Use on Purchase:** " .. ((item.useonpurchase and emojis.success) or emojis.fail) .. "\n" .. emojis.space .. emojis.right .. " **Item ID:** " .. item.id
				}
			})
		end

		return true, item, gaveRole
	end

	function db:ecoMultiplier(member)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.accounts = config.economy.accounts or {}
		config.economy.multipliers = config.economy.multipliers or {}

		local account, err = db:ecoFetch(member)
		if not account then
			return false, err
		end

		local totalMultiplier = 1
		for roleId, multiplier in pairs(config.economy.multipliers) do
			if member:hasRole(roleId) then
				totalMultiplier = totalMultiplier + (multiplier - 1)
			end
		end

		return tonumber(totalMultiplier) or 1
	end

	function db:ecoBountyFetch(guild, player)
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.bounties = config.economy.bounties or {}

		for i, bounty in pairs(config.economy.bounties) do
			if bounty.player == player.id then
				local total = 0
				local members = {}

				for _, payment in pairs(bounty.payments) do
					total = total + payment.amount

					if not table.find(members, payment.member) then
						table.insert(members, payment.member)
					end
				end

				return bounty, total, members, i
			end
		end
	end

	function db:ecoBountyAdd(member, player, amount, reason)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.accounts = config.economy.accounts or {}
		config.economy.bounties = config.economy.bounties or {}

		local account, err = db:ecoFetch(member)
		if not account then
			return false, err
		end

		if account.balance.wallet < amount then
			return false, "You cannot place a bounty for more money than you have in your wallet."
		elseif amount <= 0 then
			return false, "The amount must be greater than zero."
		end

		account.balance.wallet = account.balance.wallet - amount

		local success, err = db:ecoBalance(member, "wallet", account.balance.wallet)
		if not success then
			return false, err
		end

		local existing, _, _, index = db:ecoBountyFetch(guild, player)
		if existing then
			config.economy.bounties[index].payments = config.economy.bounties[index].payments or {}

			local t = os.time()

			table.insert(config.economy.bounties[index].payments, {
				member = member.id,
				amount = amount,
				reason = reason,
				timestamp = t
			})

			local success, err = sqldb:set(guild.id, {
				economy = config.economy
			}, "ECONOMY_BOUNTY_ADD_PAYMENT")
			if not success then
				return false, err
			end

			db:send(guild.id, "economylogchannel", {
				embed = {
					title = emojis.add .. " Bounty Payment Added",
					author = author(member),
					color = colors.success,
					description = getUserString(member) .. " has added " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(amount) .. "** to **" .. player.hyperlink .. "**'s bounty.\n" .. emojis.right .. " **Reason:** " .. (reason or emojis.fail) .. "\n" .. emojis.right .. " **Date:** <t:" .. t .. ">",
					thumbnail = {
						url = player.avatar
					}
				}
			})

			return config.economy.bounties[index]
		else
			local t = os.time()
			local bounty = {
				player = player.id,
				started = t,
				payments = {
					{
						member = member.id,
						amount = amount,
						reason = reason,
						timestamp = t
					}
				}
			}

			table.insert(config.economy.bounties, bounty)

			local success, err = sqldb:set(guild.id, {
				economy = config.economy
			}, "ECONOMY_BOUNTY_CREATE")
			if not success then
				return false, err
			end

			db:send(guild.id, "economylogchannel", {
				embed = {
					title = emojis.target .. " Bounty Created",
					author = author(member),
					color = colors.yellow,
					description = getUserString(member) .. " has placed a bounty of " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(amount) .. "** on **" .. player.hyperlink .. "**.\n" .. emojis.right .. " **Reason:** " .. (reason or emojis.fail) .. "\n" .. emojis.right .. " **Date:** <t:" .. t .. ">",
					thumbnail = {
						url = player.avatar
					}
				}
			})

			return bounty
		end
	end

	function db:ecoBountyComplete(member, player)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.accounts = config.economy.accounts or {}
		config.economy.bounties = config.economy.bounties or {}

		local bounty, amount, _, index = db:ecoBountyFetch(guild, player)
		if not bounty then
			return false, "That player does not have an active bounty."
		end

		local account, err = db:ecoFetch(member)
		if not account then
			return false, err
		end

		account.balance.wallet = account.balance.wallet + amount
		local success, err = db:ecoBalance(member, "wallet", account.balance.wallet)
		if not success then
			return false, err
		end

		table.remove(config.economy.bounties, index)

		local success, err = sqldb:set(guild.id, {
			economy = config.economy
		}, "ECONOMY_BOUNTY_COMPLETE")
		if not success then
			return false, err
		end

		db:send(guild.id, "economylogchannel", {
			embed = {
				title = emojis.target .. " Bounty Completed",
				author = author(member),
				color = colors.success,
				description = getUserString(member) .. " has completed the " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(amount) .. "** bounty on **" .. player.hyperlink .. "**.\n" .. emojis.right .. " **Date:** <t:" .. os.time() .. ">",
				thumbnail = {
					url = player.avatar
				}
			}
		})

		member:send({
			embed = {
				title = emojis.success .. " Bounty Completed",
				description = "You received " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(amount) .. "** for completing **" .. player.hyperlink .. "**'s bounty.\n" .. emojis.right .. " **Player:** " .. player.hyperlink .. "\n" .. emojis.right .. " **Date:** <t:" .. os.time() .. ">",
				thumbnail = {
					url = player.avatar
				}
			},
			components = signature(guild)
		})

		return true
	end

	function db:ecoBountyRemove(member, player, reason)
		local guild = member.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.accounts = config.economy.accounts or {}
		config.economy.bounties = config.economy.bounties or {}

		local bounty, amount, _, index = db:ecoBountyFetch(guild, player)
		if not bounty then
			return false, "That player does not have an active bounty."
		end

		for _, payment in pairs(bounty.payments) do
			local m = guild:getMember(payment.member)
			local account = m and db:ecoFetch(m)

			if m and account then
				local success, err = db:ecoBalance(m, "wallet", account.balance.wallet + payment.amount)
				if not success then
					return false, "Failed to refund " .. getUserString(m) .. ": " .. err
				end
			end
		end

		table.remove(config.economy.bounties, index)

		local success, err = sqldb:set(guild.id, {
			economy = config.economy
		}, "ECONOMY_BOUNTY_REMOVE")
		if not success then
			return false, err
		end

		db:send(guild.id, "economylogchannel", {
			embed = {
				title = emojis.subtract .. " Bounty Removed",
				author = author(member),
				color = colors.fail,
				description = getUserString(member) .. " has removed the " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(amount) .. "** bounty that was placed on **" .. player.hyperlink .. "**.\n" .. emojis.right .. " **Reason:** " .. (reason or emojis.fail) .. "\n" .. emojis.right .. " **Date:** <t:" .. os.time() .. ">",
				thumbnail = {
					url = player.avatar
				}
			}
		})

		return true
	end

	function db:commandQueueInsert(guild, command, author)
		author = author or Client.user

		local config = sqldb:get(guild.id) or {}
		config.erlccommandqueue = config.erlccommandqueue or {}

		if table.count(config.erlccommandqueue) >= featureLimits.erlcCommandQueueLimit.plus then
			return false, "The command queue for this server is full."
		end

		table.insert(config.erlccommandqueue, {
			command = command,
			author = author.id
		})

		local success, err = sqldb:set(guild.id, {
			erlccommandqueue = config.erlccommandqueue
		}, "ERLC_COMMAND_QUEUE_INSERT")
		if not success then
			return false, err
		end

		db:send(guild.id, "erlccmdschannel", {
			embed = {
				title = emojis.loading .. " Command Queued",
				description = emojis.right .. " The **`" .. command .. "`** command has been queued for execution " .. ((author and "by " .. getUserString(author) .. " ") or "") .. "when the server comes online.",
				author = {
					name = "@" .. author.username,
					icon_url = author.avatarURL
				},
				color = colors.blank
			}
		})

		return true
	end

	function db:commandQueueRemove(guild, index, executed)
		local config = sqldb:get(guild.id) or {}
		config.erlccommandqueue = config.erlccommandqueue or {}

		local command = config.erlccommandqueue[index] and config.erlccommandqueue[index].command
		table.remove(config.erlccommandqueue, index)

		local success, err = sqldb:set(guild.id, {
			erlccommandqueue = config.erlccommandqueue
		}, "ERLC_COMMAND_QUEUE_REMOVE")
		if not success then
			return false, err
		end

		if not executed then
			db:send(guild.id, "erlccmdschannel", {
				embed = {
					title = emojis.fail .. " Command Canceled",
					description = emojis.right .. " The **`" .. command .. "`** command has been removed from the command queue and will no longer be executed.",
					color = colors.fail
				}
			})
		end

		return true
	end

	function db:commandQueueExecute(guild)
		local config = sqldb:get(guild.id) or {}
		config.erlccommandqueue = config.erlccommandqueue or {}

		local entry = config.erlccommandqueue[1]
		if not entry then
			return false, "There are no commands queued."
		elseif not config.apikey then
			return false, "You have not linked your ERLC server."
		end

		local server = ERLC:getServer(config.apikey)
		if not server then
			return false, "An unknown error occurred while fetching the ERLC server data."
		end

		local success, err = server:execute(entry.command)
		if not success then
			return false, err
		end

		db:send(guild.id, "erlccmdschannel", {
			embed = {
				title = emojis.success .. " Command Executed",
				description = emojis.right .. " The **`" .. entry.command .. "`** command has been successfully executed and removed from the command queue.",
				color = colors.success
			}
		})

		return db:commandQueueRemove(guild, 1, true)
	end

	_G.db = db
end

dbModule.Stop = function()
end

return dbModule
