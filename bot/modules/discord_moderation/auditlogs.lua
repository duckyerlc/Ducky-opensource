-- auditlogs.lua
local auditlogs = {
	name = "auditlogs",
	description = "Manages the Audit Logging module & Ducky's guild logs."
}

local connections = {}

local auditQueue = {}
local timeoutTime = 20

local function auditTypeEnabled(auditType, guildID)
	local config = sqldb:get(guildID)
	if not config or not config.audittypes or not table.find(config.audittypes, auditType) then
		return false
	end

	local hasChannel = (config.auditlogchannels
		and ((config.auditlogchannels[auditType] and config.auditlogchannels[auditType].channel)
		or (config.auditlogchannels.primary and config.auditlogchannels.primary.channel)))

	return hasChannel
end

local function queueAuditRequest(guildID)
	auditQueue[guildID] = auditQueue[guildID] or {}

	local requestKey = junkStr(5)

	if table.find(auditQueue[guildID], requestKey) then
		return false
	end

	table.insert(auditQueue[guildID], requestKey)

	local startTime = os.time()

	repeat
		timer.sleep(20)
	until (auditQueue[guildID][1] == requestKey) or os.time() - startTime >= timeoutTime

	local hits = 0

	for _, v in pairs(auditQueue[guildID]) do
		if v == requestKey then
			hits = hits + 1
		end
	end

	if hits >= 2 then
		return false
	end

	if os.time() - startTime >= timeoutTime then
		for i, req in ipairs(auditQueue[guildID]) do
			if req == requestKey then
				table.remove(auditQueue[guildID], i)
				break
			end
		end

		return false
	end

	coroutine.wrap(function()
		timer.sleep(500)

		if type(auditQueue) == "table" then
			table.remove(auditQueue[guildID], 1)
		end
	end)()

	return true
end

auditlogs.Start = function()
	connections.messageEdit = { "messageUpdate", Client:on("messageUpdate", function(message)
		if not message then
			return
		end

		local previousContent

		if not message.user then
			return
		elseif not message.channel then
			return
		elseif not message.content then
			return
		elseif not message.editedTimestamp then
			return
		elseif message.user.bot then
			return
		end

		if message.oldContent and message.oldContent[message.editedTimestamp] then
			previousContent = message.oldContent[message.editedTimestamp]
		else
			previousContent = "[CACHED] - Content not Available"
		end

		if (not previousContent) or (previousContent == message.content) then
			return
		end

		if blacklisted(message.user) or blacklisted(message.guild) then -- Member blacklist check required because people need to be able to opt-out of message tracking
			return
		end

		local guild = message.channel.guild

		if not auditTypeEnabled("msgedit", guild.id) then
			return
		end

		if previousContent:len() >= 500 then
			previousContent = previousContent:usub(1, 497) .. "..."
		end

		local newContent = message.content

		if newContent:len() >= 500 then
			newContent = newContent:usub(1, 497) .. "..."
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(message.guild.id, "msgedit", {
			embed = {
				title = emojis.edit .. " Message Edited [Cached]",
				description = "A [message](" ..
							message.link ..
							") by " .. getUserString(message.author) .. ", was edited in " .. message.channel.mentionString .. " by " .. getUserString(message.user) .. ":",
				fields = {
					{
						name = "Previous Content",
						value = "```" .. previousContent .. "```"
					},
					{
						name = "New Content",
						value = "```" .. newContent .. "```"
					}
				},
				author = author(message.user),
				color = colors.warning,
				timestamp = toISO(os.time())
			}
		})
	end, "auditlogs_messageUpdate") }

	connections.messageEditUncached = { "messageUpdateUncached", Client:on("messageUpdateUncached", function(channel, messageID)

		local message = channel:getMessage(messageID)
		if not message then
			return
		end

		local previousContent

		if not message.user then
			return
		elseif not message.channel then
			return
		elseif not message.content then
			return
		elseif not message.editedTimestamp then
			return
		elseif message.user.bot then
			return
		end

		if message.oldContent and message.oldContent[message.editedTimestamp] then
			previousContent = message.oldContent[message.editedTimestamp]
		else
			previousContent = "[UNCACHED] - Content not Available"
		end

		if (not previousContent) or (previousContent == message.content) then
			return
		end

		if blacklisted(message.user) or blacklisted(message.guild) then -- Member blacklist check required because people need to be able to opt-out of message tracking
			return
		end

		local guild = message.channel.guild

		if (not guild) or (not auditTypeEnabled("msgedit", guild.id)) then
			return
		end

		if previousContent:len() >= 500 then
			previousContent = previousContent:usub(1, 497) .. "..."
		end

		local newContent = message.content

		if newContent:len() >= 500 then
			newContent = newContent:usub(1, 497) .. "..."
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(message.guild.id, "msgedit", {
			embed = {
				title = emojis.edit .. " Message Edited [Uncached]",
				description = "A [message](" ..
							message.link ..
							") by " .. getUserString(message.author) .. ", was edited in " .. message.channel.mentionString .. " by " .. getUserString(message.user) .. ":",
				fields = {
					{
						name = "Previous Content",
						value = "```" .. previousContent .. "```"
					},
					{
						name = "New Content",
						value = "```" .. newContent .. "```"
					}
				},
				author = author(message.user),
				color = colors.warning,
				timestamp = toISO(os.time())
			}
		})
	end, "auditlogs_messageUpdateUncached") }

	connections.messageDelete = { "messageDelete", Client:on("messageDelete", function(message, bd)
		if bd == true or not message or not message.user or not message.member or not message.channel or (message._flags and bit64.tonumber(message._flags) == 64) then return end

		if blacklisted(message.member) or blacklisted(message.guild) then -- Member blacklist check required because people need to be able to opt-out of message tracking
			return
		end

		local member = message.member
		local guild = member.guild

		if not auditTypeEnabled("msgdelete", guild.id) then
			return
		end

		local auditSuccess, entryInfo = Client:waitFor("guildAuditLogEntryCreate", 5000, function(entry)
			return (entry.action_type == discordia.enums.actionType.messageDelete) and (message.channel and entry.options and entry.options.channel_id == message.channel.id) and (entry.target_id == message.user.id) and entry.user_id
		end)
		local deleter = nil

		if auditSuccess and entryInfo.target_id == message.user.id and entryInfo.user_id then
			deleter = Client:getUser(entryInfo.user_id)
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(message.guild.id, "msgdelete", {
			embed = {
				title = emojis.delete .. " Message Deleted",
				description = "A message written by " ..
							getUserString(message.author) .. " was deleted in " .. message.channel.mentionString .. ":",
				fields = {
					{
						name = "Message Content:",
						value = "```" .. string.truncate(contentString(message), 500) .. "```"
					}
				},
				author = author(deleter or message.user),
				image = message.sticker and { url = message.sticker.url },
				color = colors.fail,
				timestamp = toISO(os.time())
			}
		})
	end, "auditlogs_messageDelete") }

	connections.memberJoin = { "memberJoin", Client:on("memberJoin", function(member)
		if not member or not member.guild then
			return
		end

		local guild = member.guild

		if blacklisted(guild) then
			return
		end

		if not auditTypeEnabled("memberjoin", guild.id) then
			return
		end

		local roleobjs = member.roles
		local roles = ""

		for _, role in pairs(roleobjs) do
			roles = roles .. role.mentionString .. " "
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		loadMembers(guild)

		db:sendAuditLog(member.guild.id, "memberjoin", {
			embed = {
				title = emojis.add .. " Member Joined",
				description = emojis.right .. " " .. getUserString(member.user) .. " has joined the server!\n" ..
				emojis.space .. emojis.right .. " **User ID:** `" .. member.user.id .. "`\n" ..
				emojis.space .. emojis.right .. " **Account Created:** <t:" .. math.floor(member.user.createdAt) .. ">\n" ..
				emojis.space .. emojis.right .. " **Membercount:** " .. formatNumber(guild.totalMemberCount),
				author = author(member.user),
				color = colors.success,
				timestamp = toISO(os.time())
			}
		})
	end, "auditlogs_memberJoin") }

	connections.memberLeave = { "memberLeave", Client:on("memberLeave", function(member)
		if not member or not member.guild then
			return
		end

		local guild = member.guild

		if blacklisted(guild.id) then
			return
		end

		if not auditTypeEnabled("memberleave", guild.id) then
			return
		end

		local roles = ""

		for role in (member.roles and member.roles:iter()) do
			roles = roles ..  emojis.space .. emojis.space .. emojis.right .. " " .. role.mentionString .. "\n"
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		loadMembers(guild)

		db:sendAuditLog(member.guild.id, "memberleave", {
			embed = {
				title = emojis.subtract .. " Member Left",
				description = emojis.right .. " " .. getUserString(member.user) .. " has left the server.\n" ..
				emojis.space .. emojis.right .. " **User ID:** `" .. member.user.id .. "`\n" ..
				emojis.space .. emojis.right .. " **Account Created:** <t:" .. math.floor(member.user.createdAt) .. ">\n" ..
				emojis.space .. emojis.right .. " **Joined:** <t:" .. fromISO(member.joinedAt) .. ">\n" ..
				emojis.space .. emojis.right .. " **Membercount:** " .. formatNumber(guild.totalMemberCount) .. "\n" ..
				emojis.space .. emojis.right .. " **Previous Roles:**\n" ..
					(roles ~= "" and roles or (emojis.space .. emojis.space .. emojis.right .. "*User did not have any roles.*")),
				author = author(member.user),
				color = colors.fail,
				timestamp = toISO(os.time())
			}
		})
	end, "auditlogs_memberLeave") }

	connections.memberUpdate = { "guildAuditLogEntryCreate", Client:on("guildAuditLogEntryCreate", function(entryInfo)
		if entryInfo.action_type ~= discordia.enums.actionType.memberUpdate then
			return
		end

		local guildId = entryInfo.guild_id
		local guild = Client:getGuild(guildId)

		if not guild or blacklisted(guildId) then
			return
		end

		if not auditTypeEnabled("memberupdate", guild.id) then
			return
		end

		local targetMemberId = entryInfo.target_id
		local targetMember = guild:getMember(targetMemberId)

		if not targetMember then
			return
		end

		local creatorMemberId = entryInfo.user_id
		local creatorMember = guild:getMember(creatorMemberId)

		if not creatorMember then
			return
		end

		local emb = {
			title = emojis.edit .. " Member Updated",
			description = emojis.right .. " The member " .. getUserString(targetMember) .. " was changed by " .. getUserString(creatorMember.user) .. ":",
			color = colors.warning,
			author = author(creatorMember.user),
			timestamp = toISO(os.time())
		}

		for i, v in pairs(entryInfo.changes) do
			if (v.new_value) or (v.old_value) then
				if v.key:lower() == "communication_disabled_until" then
					emb.description = emb.description ..
									"\n" .. emojis.space .. emojis.right .. " **" .. "Timed-out for" ..
										":** " .. readable(fromISO(v.new_value) - os.time()) .. " (<t:" .. fromISO(v.new_value) .. ":R>)"
				else
					emb.description = emb.description ..
									"\n" .. emojis.space .. emojis.right .. " **" .. string.capitalize(v.key or "Unknown") .. ":** " ..
											((v.old_value and tostring(v.old_value)) or "*Nothing*") .. " " ..  emojis.right .. " " .. ((v.new_value and tostring(v.new_value)) or "*Nothing*")
					end
			else
				emb.description = emb.description ..
									"\n" .. emojis.space .. emojis.right .. " **" .. string.capitalize(v.key or "Unknown") .. ":** *Failed to fetch changes*"
			end
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(guild.id, "memberupdate", {
			embed = emb
		})
	end, "auditlogs_memberUpdate") }

	connections.memberRoleUpdate = { "guildAuditLogEntryCreate", Client:on("guildAuditLogEntryCreate", function(entryInfo)
		if entryInfo.action_type ~= discordia.enums.actionType.memberRoleUpdate then
			return
		end

		local guildId = entryInfo.guild_id
		local guild = Client:getGuild(guildId)

		if not guild or blacklisted(guildId) then
			return
		end

		if not auditTypeEnabled("memberupdate", guild.id) then
			return
		end

		local targetMemberId = entryInfo.target_id
		local targetMember = guild:getMember(targetMemberId)

		if not targetMember then
			return
		end

		local creatorMemberId = entryInfo.user_id
		local creatorMember = guild:getMember(creatorMemberId)

		if not creatorMember then
			return
		end

		local emb = {
			title = emojis.edit .. " Member Role Updated",
			description = emojis.right .. " The roles of " .. getUserString(targetMember) .. " were changed by " .. getUserString(creatorMember.user) .. ":",
			color = colors.warning,
			author = author(creatorMember.user),
			timestamp = toISO(os.time())
		}

		for _, v in pairs(entryInfo.changes) do
			if not v.new_value then return end

			for _, role in pairs(v.new_value) do
				if v.key == "$remove" then
					emb.description = emb.description .. "\n" .. emojis.space .. " " .. emojis.subtract ..  " <@&" .. role.id .. "> (`" .. role.id .. "`)"
				elseif v.key == "$add" then
					emb.description = emb.description .. "\n" .. emojis.space .. " " .. emojis.add .. " <@&" .. role.id .. "> (`" .. role.id .. "`)"
				end
			end
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(guild.id, "memberupdate", {
			embed = emb
		})
	end, "auditlogs_memberRoleUpdate") }

	connections.channelCreate = { "guildAuditLogEntryCreate", Client:on("guildAuditLogEntryCreate", function(entryInfo)
		if entryInfo.action_type ~= discordia.enums.actionType.channelCreate then
			return
		end

		local guildId = entryInfo.guild_id
		local guild = Client:getGuild(guildId)

		if not guild or blacklisted(guildId) then
			return
		end

		if not auditTypeEnabled("channelcreate", guild.id) then
			return
		end

		local creatorMemberId = entryInfo.user_id
		local creatorMember = guild:getMember(creatorMemberId)

		if not creatorMember then
			return
		end

		local targetChannelId = entryInfo.target_id
		local targetChannel = guild:getChannel(targetChannelId)

		if not targetChannel then
			return
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(targetChannel.guild.id, "channelcreate", {
			embed = {
				title = emojis.add .. " Channel Created",
				description = emojis.right .. " The " .. targetChannel.mentionString .. " channel was created by " .. getUserString(creatorMember) .. ":\n"
				.. emojis.space .. emojis.right .. " **Channel Name:** " .. targetChannel.name .. "\n"
				.. emojis.space .. emojis.right .. " **Channel ID:** `" .. targetChannel.id .. "`",
				author = author(creatorMember.user),
				color = colors.success,
				timestamp = toISO(os.time())
			}
		})
	end, "auditlogs_channelCreate") }

	connections.channelUpdate = { "guildAuditLogEntryCreate", Client:on("guildAuditLogEntryCreate", function(entryInfo)
		if entryInfo.action_type ~= discordia.enums.actionType.channelUpdate then
			return
		end

		local guildId = entryInfo.guild_id
		local guild = Client:getGuild(guildId)

		if not guild or blacklisted(guildId) then
			return
		end

		if not auditTypeEnabled("channelupdate", guild.id) then
			return
		end

		local creatorMemberId = entryInfo.user_id
		local creatorMember = guild:getMember(creatorMemberId)

		if not creatorMember then
			return
		end

		local targetChannelId = entryInfo.target_id
		local targetChannel = guild:getChannel(targetChannelId)

		if not targetChannel then
			return
		end

		local emb = {
			title = emojis.edit .. " Channel Updated",
			description = emojis.right .. " The " .. targetChannel.mentionString .. " channel was updated by " .. getUserString(creatorMember) .. ":",
			author = author(creatorMember.user),
			color = colors.warning,
			timestamp = toISO(os.time())
		}

		for i, v in pairs(entryInfo.changes) do
			if (v.new_value) or (v.old_value) then
				emb.description = emb.description ..
							"\n" .. emojis.space .. emojis.right .. " **" .. string.capitalize(v.key or "Unknown") .. ":** " ..
										((v.old_value and tostring(v.old_value)) or "*Nothing*") .. " " ..
												emojis.right .. " " .. ((v.new_value and tostring(v.new_value)) or "*Nothing*")
				else
					emb.description = emb.description ..
									"\n" .. emojis.space .. emojis.right .. " **" .. string.capitalize(v.key or "Unknown") .. ":** *Failed to fetch changes*"
			end
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(guild.id, "channelupdate", {
			embed = emb
		})
	end, "auditlogs_channelUpdate") }

	connections.channelDelete = { "guildAuditLogEntryCreate", Client:on("guildAuditLogEntryCreate", function(entryInfo)
		if entryInfo.action_type ~= discordia.enums.actionType.channelDelete then
			return
		end

		local guildId = entryInfo.guild_id
		local guild = Client:getGuild(guildId)

		if not guild or blacklisted(guildId) then
			return
		end

		if not auditTypeEnabled("channeldelete", guild.id) then
			return
		end

		local creatorMemberId = entryInfo.user_id
		local creatorMember = guild:getMember(creatorMemberId)

		if not creatorMember then
			return
		end

		local targetChannelId = entryInfo.target_id
		local targetChannelName = "Unknown"

		for _, v in pairs(entryInfo.changes) do
			if v.key == "name" then
				targetChannelName = v.old_value
			end
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(guild.id, "channeldelete", {
			embed = {
				title = emojis.subtract .. " Channel Delete",
				description = emojis.right .. " The **#" .. targetChannelName .. "** channel was deleted by " .. getUserString(creatorMember) .. ":\n"
				.. emojis.space .. emojis.right .. " **Channel Name:** " .. targetChannelName .. "\n"
				.. emojis.space .. emojis.right .. " **Channel ID:** `" .. targetChannelId .. "`",
				author = author(creatorMember.user),
				color = colors.fail,
				timestamp = toISO(os.time())
			}
		})
	end, "auditlogs_channelDelete") }

	connections.reactionAdd = { "reactionAdd", Client:on("reactionAdd", function(reaction, userID)
		if (not reaction) or (not userID) or (not reaction.message) or (not reaction.message.channel) or (not reaction.message.guild) then
			return
		end

		local message = reaction.message
		local guild = message.guild

		if blacklisted(guild.id) then
			return
		end

		if not auditTypeEnabled("reactionadd", guild.id) then
			return
		end

		local creator = reaction.message.guild:getMember(userID)

		if (not creator) or (not creator.id) then return end

		local content = ((reaction.message.content ~= "") and reaction.message.content) or
				(reaction.message.sticker and "Sticker: [" .. reaction.message.sticker.name .. "](" .. reaction.message.sticker.url .. ")") or
				(reaction.message.embeds and reaction.message.embeds[1] and "[EMBED]")

		if not content then return end

		if content:len() >= 500 then
			content = content:usub(1, 497) .. "..."
		end

		db:sendAuditLog(reaction.message.guild.id, "reactionadd", {
			embed = {
				title = emojis.add .. " Reaction Added",
				description = emojis.right .. " " .. getUserString(creator.user) .. "  added a reaction to [a message](" .. reaction.message.link .. "),\n"
				.. emojis.space .. emojis.right .. " **Reaction:** " .. (reaction.emojiId and ((reaction.emojiAnimated and "<a:" or "<:") .. (reaction.emojiName or "emoji") .. ":" .. reaction.emojiId .. ">") or (reaction.emojiName or reaction.emojiHash or "Unknown Emoji")) .. "\n"
				.. emojis.space .. emojis.right .. " **Channel:** " .. reaction.message.channel.mentionString .. "\n"
				.. emojis.space .. emojis.right .. " **Message Content:**\n ```" .. contentString(message) .. "```",
				author = author(creator.user),
				color = colors.success,
				timestamp = toISO(os.time())
			}
		})
	end, "auditlogs_reactionAdd") }

	connections.reactionAddUncached = { "reactionAddUncached", Client:on("reactionAddUncached", function(channel, messageId, hash, userID)
		if (not userID) or (not messageId) or (not channel) or (not hash) or (not channel.guild) then
			return
		end

		local message = channel:getMessage(messageId)

		if not message then
			return
		end

		local guild = channel.guild

		if blacklisted(guild.id) then
			return
		end

		if not auditTypeEnabled("reactionadd", guild.id) then
			return
		end

		local creator = channel.guild:getMember(userID)

		if (not creator) or (not creator.id) then return end

		local content = ((message.content ~= "") and message.content) or
				(message.sticker and "Sticker: [" .. message.sticker.name .. "](" .. message.sticker.url .. ")") or
				(message.embeds and message.embeds[1] and "[EMBED]")

		if not content then return end

		if content:len() >= 500 then
			content = content:usub(1, 497) .. "..."
		end

		db:sendAuditLog(channel.guild.id, "reactionadd", {
			embed = {
				title = emojis.add .. " Reaction Added",
				description = emojis.right .. " " .. getUserString(creator.user) .. " added a reaction to [a message](https://discord.com/channels/" .. channel.guild.id .. "/" .. channel.id .. "/" .. messageId .. "):\n"
				.. emojis.space .. emojis.right .. " **Reaction:** " .. hash .. "\n"
				.. emojis.space .. emojis.right .. " **Channel:** " .. channel.mentionString .. "\n"
				.. emojis.space .. emojis.right .. " **Message Content:**\n ```" .. contentString(message) .. "```",
				author = author(creator.user),
				color = colors.success,
				timestamp = toISO(os.time())
			}
		})
	end, "auditlogs_reactionAddUncached") }

	connections.reactionRemove = { "reactionRemove", Client:on("reactionRemove", function(reaction, userID)
		if (not reaction) or (not userID) or (not reaction.message) or (not reaction.message.channel) or (not reaction.message.guild) then
			return
		end

		local message = reaction.message
		local guild = message.guild

		if blacklisted(guild.id) then
			return
		end

		if not auditTypeEnabled("reactionremove", guild.id) then
			return
		end

		local creator = reaction.message.guild:getMember(userID)

		if (not creator) or (not creator.id) then return end

		local content = ((reaction.message.content ~= "") and reaction.message.content) or
				(reaction.message.sticker and "Sticker: [" .. reaction.message.sticker.name .. "](" .. reaction.message.sticker.url .. ")") or
				(reaction.message.embeds and reaction.message.embeds[1] and "[EMBED]")

		if not content then return end

		if content:len() >= 500 then
			content = content:usub(1, 497) .. "..."
		end

		db:sendAuditLog(reaction.message.guild.id, "reactionremove", {
			embed = {
				title = emojis.subtract .. " Reaction Removed",
				description = emojis.right .. " " .. getUserString(guild:getMember(userID)) .. " removed a reaction from [a message](" .. reaction.message.link .. "),\n"
				.. emojis.space .. emojis.right .. " **Reaction:** " .. (reaction.emojiId and ((reaction.emojiAnimated and "<a:" or "<:") .. (reaction.emojiName or "emoji") .. ":" .. reaction.emojiId .. ">") or (reaction.emojiName or reaction.emojiHash or "Unknown Emoji")) .. "\n"
				.. emojis.space .. emojis.right .. " **Channel:** " .. reaction.message.channel.mentionString .. "\n"
				.. emojis.space .. emojis.right .. " **Message Content:**\n ```" .. contentString(message) .. "```",
				author = author(creator.user),
				color = colors.fail,
				timestamp = toISO(os.time())
			}
		})
	end, "auditlogs_reactionRemove") }

	connections.reactionRemoveUncached = { "reactionRemoveUncached", Client:on("reactionRemoveUncached", function(channel, messageId, hash, userID)
		if (not userID) or (not messageId) or (not channel) or (not hash) or (not channel.guild) then
			return
		end

		local message = channel:getMessage(messageId)

		if not message then
			return
		end

		local guild = channel.guild

		if blacklisted(guild.id) then
			return
		end

		if not auditTypeEnabled("reactionremove", guild.id) then
			return
		end

		local creator = channel.guild:getMember(userID)

		if (not creator) or (not creator.id) then return end

		local content = ((message.content ~= "") and message.content) or
				(message.sticker and "Sticker: [" .. message.sticker.name .. "](" .. message.sticker.url .. ")") or
				(message.embeds and message.embeds[1] and "[EMBED]")

		if not content then return end

		if content:len() >= 500 then
			content = content:usub(1, 497) .. "..."
		end

		db:sendAuditLog(channel.guild.id, "reactionremove", {
			embed = {
				title = emojis.subtract .. " Reaction Removed",
				description = emojis.right .. " " .. getUserString(guild:getMember(userID)) .. " removed a reaction from [a message](https://discord.com/channels/" .. channel.guild.id .. "/" .. channel.id .. "/" .. messageId .. "):\n"
				.. emojis.space .. emojis.right .. " **Reaction:** " .. hash .. "\n"
				.. emojis.space .. emojis.right .. " **Channel:** " .. channel.mentionString .. "\n"
				.. emojis.space .. emojis.right .. " **Message Content:**\n ```" .. contentString(message) .. "```",
				author = author(creator.user),
				color = colors.fail,
				timestamp = toISO(os.time())
			}
		})
	end, "auditlogs_reactionRemoveUncached") }

	connections.roleCreate = { "guildAuditLogEntryCreate", Client:on("guildAuditLogEntryCreate", function(entryInfo)
		if entryInfo.action_type ~= discordia.enums.actionType.roleCreate then
			return
		end

		local guildId = entryInfo.guild_id
		local guild = Client:getGuild(guildId)

		if not guild or blacklisted(guildId) then
			return
		end

		if not auditTypeEnabled("rolecreate", guild.id) then
			return
		end

		local creatorMemberId = entryInfo.user_id
		local creatorMember = guild:getMember(creatorMemberId)

		if not creatorMember then
			return
		end

		local targetRoleId = entryInfo.target_id
		local targetRole = guild:getRole(targetRoleId)

		if not targetRole then
			return
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(guild.id, "rolecreate", {
			embed = {
				title = emojis.add .. " Role Created",
				description = emojis.right .." The " .. targetRole.mentionString .. " role was created by " .. getUserString(creatorMember.user) .. ":\n"
				.. emojis.space .. emojis.right .. " **Role Name:** " .. targetRole.name .. "\n"
				.. emojis.space .. emojis.right .. " **Role Color:** " .. discordia.Color(targetRole.color):toHex() .. "\n"
				.. emojis.space .. emojis.right .. " **Hoisted:** " .. ((targetRole.hoisted and emojis.success) or emojis.fail) .. "\n"
				.. emojis.space .. emojis.right .. " **Position:** " .. targetRole.position,
				color = colors.success,
				author = author(creatorMember.user),
				timestamp = toISO(os.time())
			}
		})
	end, "auditlogs_roleCreate") }

	connections.roleUpdate = { "guildAuditLogEntryCreate", Client:on("guildAuditLogEntryCreate", function(entryInfo)
		if entryInfo.action_type ~= discordia.enums.actionType.roleUpdate then
			return
		end

		local guildId = entryInfo.guild_id
		local guild = Client:getGuild(guildId)

		if not guild or blacklisted(guildId) then
			return
		end

		if not auditTypeEnabled("roleupdate", guild.id) then
			return
		end

		local creatorMemberId = entryInfo.user_id
		local creatorMember = guild:getMember(creatorMemberId)

		if not creatorMember then
			return
		end

		local targetRoleId = entryInfo.target_id
		local targetRole = guild:getRole(targetRoleId)

		if not targetRole then
			return
		end

		local emb = {
			title = emojis.edit .. " Role Updated",
			description = emojis.right .. " The " .. targetRole.mentionString .. " role was changed by " .. getUserString(creatorMember.user) .. ":",
			color = colors.warning,
			author = author(creatorMember.user),
			timestamp = toISO(os.time())
		}

		for i, v in pairs(entryInfo.changes) do
			if (v.new_value) or (v.old_value) then
				if v.key == "color" then
					v.new_value = v.new_value and discordia.Color(v.new_value):toHex()
					v.old_value = v.old_value and discordia.Color(v.old_value):toHex()
					
					emb.description = emb.description ..
									"\n" .. emojis.space .. emojis.right .. " **" ..
										string.capitalize(v.key or "Unknown") .. ":** " .. ((v.old_value and tostring(v.old_value)) or "*Nothing*") .. " " .. emojis.right .. " " ..  ((v.new_value and tostring(v.new_value)) or "*Nothing*")
				elseif v.key:lower() == "colors" then
					-- filter grr
				else
					emb.description = emb.description ..
									"\n" .. emojis.space .. emojis.right .. " **" ..
										string.capitalize(v.key or "Unknown") .. ":** " .. ((v.old_value and tostring(v.old_value)) or "*Nothing*") .. " " .. emojis.right .. " " .. ((v.new_value and tostring(v.new_value)) or "*Nothing*")
				end
			else
				emb.description = emb.description ..
									"\n" .. emojis.space .. emojis.right .. "**" .. string.capitalize(v.key or "Unknown") .. ":** *Failed to fetch changes*"
			end
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(guild.id, "roleupdate", {
			embed = emb
		})
	end, "auditlogs_roleUpdate") }

	connections.roleDelete = { "guildAuditLogEntryCreate", Client:on("guildAuditLogEntryCreate", function(entryInfo)
		if entryInfo.action_type ~= discordia.enums.actionType.roleDelete then
			return
		end

		local guildId = entryInfo.guild_id
		local guild = Client:getGuild(guildId)

		if not guild or blacklisted(guildId) then
			return
		end

		if not auditTypeEnabled("roledelete", guild.id) then
			return
		end

		local creatorMemberId = entryInfo.user_id
		local creatorMember = guild:getMember(creatorMemberId)

		if not creatorMember then
			return
		end

		local targetRoleName = "Unknown"
		local targetRoleColor = 0
		local targetRoleHoist = false

		for _, v in pairs(entryInfo.changes) do
			if v.key == "name" then
				targetRoleName = v.old_value
			elseif v.key == "color" then
				targetRoleColor = v.old_value
			elseif v.key == "hoist" then
				targetRoleHoist = v.old_value
			end
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(guild.id, "roledelete", {
			embed = {
				title = emojis.subtract .. " Role Deleted",
				description = emojis.right .. " The **@" .. targetRoleName .. "** role was deleted by " .. getUserString(creatorMember.user) .. ":\n"
				.. emojis.space .. emojis.right .. " **Role Name:** " .. targetRoleName .. "\n"
				.. emojis.space .. emojis.right .. " **Role Color:** " .. discordia.Color(targetRoleColor):toHex() .. "\n"
				.. emojis.space .. emojis.right .. " **Hoisted:** " .. ((targetRoleHoist and emojis.success) or emojis.fail),
				color = colors.fail,
				author = author(creatorMember.user),
				timestamp = toISO(os.time())
			}
		})
	end, "auditlogs_roleDelete") }

	connections.guildUpdate = { "guildAuditLogEntryCreate", Client:on("guildAuditLogEntryCreate", function(entryInfo)
		if entryInfo.action_type ~= discordia.enums.actionType.guildUpdate then
			return
		end

		local guildId = entryInfo.guild_id
		local guild = Client:getGuild(guildId)

		if not guild or blacklisted(guildId) then
			return
		end

		if not auditTypeEnabled("guildupdate", guild.id) then
			return
		end

		local creatorMemberId = entryInfo.user_id
		local creatorMember = guild:getMember(creatorMemberId)

		if not creatorMember then
			return
		end

		local emb = {
			title = emojis.guild .. " Server Updated",
			description = emojis.right .. " The server updated by " .. getUserString(creatorMember.user) .. ":",
			color = colors.warning,
			author = author(creatorMember.user),
			timestamp = toISO(os.time())
		}

		for i, v in pairs(entryInfo.changes) do
			if (v.new_value) or (v.old_value) then
				emb.description = emb.description ..
							"\n" .. emojis.space .. emojis.right .. " **"
								.. string.capitalize(v.key or "Unknown") .. ":** " .. ((v.old_value and tostring(v.old_value)) or "*Nothing*") .. " " .. emojis.right .. " " .. ((v.new_value and tostring(v.new_value)) or "*Nothing*")
				else
					emb.description = emb.description ..
									"\n" .. emojis.space .. emojis.right .. " **" .. string.capitalize(v.key or "Unknown") .. ":** *Failed to fetch changes*"
			end
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(guild.id, "guildupdate", {
			embed = emb
		})
	end, "auditlogs_guildUpdate") }

	connections.pinsUpdate = { "guildAuditLogEntryCreate", Client:on("guildAuditLogEntryCreate", function(entryInfo)
		if entryInfo.action_type ~= discordia.enums.actionType.messagePin and entryInfo.action_type ~= discordia.enums.actionType.messageUnpin then
			return
		end

		if not entryInfo.options then
			return
		end

		local guildId = entryInfo.guild_id
		local guild = Client:getGuild(guildId)

		if not guild or blacklisted(guildId) then
			return
		end

		if not auditTypeEnabled("msgpin", guild.id) then
			return
		end

		local creatorMemberId = entryInfo.user_id
		local creatorMember = guild:getMember(creatorMemberId)

		if not creatorMember then
			return
		end

		local channelId = entryInfo.options.channel_id
		local channel = guild:getChannel(channelId)

		if not channel then
			return
		end

		local messageId = entryInfo.options.message_id
		local message = channel:getMessage(messageId)

		if not message then
			return
		end

		local content = ((message.content ~= "") and message.content) or
				(message.sticker and "Sticker: [" .. message.sticker.name .. "](" .. message.sticker.url .. ")") or
				(message.embeds and message.embeds[1] and "[EMBED]")

		if not content then return end

		if content:len() >= 500 then
			content = content:usub(1, 497) .. "..."
		end

		local emb = {}

		if entryInfo.action_type == discordia.enums.actionType.messagePin then
			emb = {
				title = emojis.pin .. " Message Pinned",
				description = emojis.right .. " A [message](" .. message.link .. "), was pinned by " .. getUserString(creatorMember.user) .. ":\n"
				.. emojis.space .. emojis.right .. " **Channel:** " .. channel.mentionString .. "\n"
				.. emojis.space .. emojis.right .. " **Message Content:**\n ```" .. content .. "```",
				color = colors.success,
				author = author(creatorMember.user),
				timestamp = toISO(os.time())
			}
		elseif entryInfo.action_type == discordia.enums.actionType.messageUnpin then
			emb = {
				title = emojis.pin .. " Message Unpinned",
				description = emojis.right .. " A [message](" .. message.link .. "), was unpinned by " .. getUserString(creatorMember.user) .. ":\n"
				.. emojis.space .. emojis.right .. " **Channel:** " .. channel.mentionString .. "\n"
				.. emojis.space .. emojis.right .. " **Message Content:**\n ```" .. content .. "```",
				color = colors.fail,
				author = author(creatorMember.user),
				timestamp = toISO(os.time())
			}
		else
			return
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(channel.guild.id, "msgpin", {
			embed = emb
		})
	end, "auditlogs_pinsUpdate") }

	connections.emojisUpdate = { "guildAuditLogEntryCreate", Client:on("guildAuditLogEntryCreate", function(entryInfo)
		if entryInfo.action_type ~= discordia.enums.actionType.emojiUpdate then
			return
		end

		local guildId = entryInfo.guild_id
		local guild = Client:getGuild(guildId)

		if not guild or blacklisted(guildId) then
			return
		end

		if not auditTypeEnabled("emojiupdate", guild.id) then
			return
		end

		local creatorMemberId = entryInfo.user_id
		local creatorMember = guild:getMember(creatorMemberId)

		if not creatorMember then
			return
		end

		local emb = {
			title = emojis.emoji .. " Server Emojis Updated",
			description = emojis.right .. " The emojis on this server were updated by " .. getUserString(creatorMember.user) .. ":",
			color = colors.warning,
			author = author(creatorMember.user),
			timestamp = toISO(os.time())
		}

		for i, v in pairs(entryInfo.changes) do
			if (not v.old_value) or (not v.new_value) then
				return
			end

			emb.description = emb.description ..
				"\n" .. emojis.space .. emojis.right .. " **[ <:" .. v.new_value .. ":" .. entryInfo.target_id .. ">] " .. string.capitalize(v.key) .. ":** " .. v.old_value .. " " .. emojis.right .. " " .. v.new_value
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(guild.id, "emojiupdate", {
			embed = emb
		})
	end, "auditlogs_emojisUpdate") }

	connections.emojiCreate = { "guildAuditLogEntryCreate", Client:on("guildAuditLogEntryCreate", function(entryInfo)
		if entryInfo.action_type ~= discordia.enums.actionType.emojiCreate then
			return
		end

		local guildId = entryInfo.guild_id
		local guild = Client:getGuild(guildId)

		if not guild or blacklisted(guildId) then
			return
		end

		if not auditTypeEnabled("emojiupdate", guild.id) then
			return
		end

		local creatorMemberId = entryInfo.user_id
		local creatorMember = guild:getMember(creatorMemberId)

		if not creatorMember then
			return
		end

		local emb = {
			title = emojis.emoji .. " Emoji Added",
			description = emojis.right .. " An emoji has been uploaded to the server by " .. getUserString(creatorMember.user) .. ":",
			color = colors.success,
			author = author(creatorMember.user),
			timestamp = toISO(os.time())
		}

		for i, v in pairs(entryInfo.changes) do
			emb.description = emb.description ..
						"\n" .. emojis.space .. emojis.right .. " **[ <:" .. v.new_value .. ":" .. entryInfo.target_id .. ">] " .. string.capitalize(v.key) .. ":** " .. v.new_value
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(guild.id, "emojiupdate", {
			embed = emb
		})
	end, "auditlogs_emojiCreate") }

	connections.emojiDelete = { "guildAuditLogEntryCreate", Client:on("guildAuditLogEntryCreate", function(entryInfo)
		if entryInfo.action_type ~= discordia.enums.actionType.emojiDelete then
			return
		end

		local guildId = entryInfo.guild_id
		local guild = Client:getGuild(guildId)

		if not guild or blacklisted(guildId) then
			return
		end

		if not auditTypeEnabled("emojiupdate", guild.id) then
			return
		end

		local creatorMemberId = entryInfo.user_id
		local creatorMember = guild:getMember(creatorMemberId)

		if not creatorMember then
			return
		end

		local emb = {
			title = emojis.emoji .. " Emoji Removed",
			description = emojis.right .. " An emoji has been removed from to the server by " .. getUserString(creatorMember.user) .. ":",
			color = colors.fail,
			author = author(creatorMember.user),
			timestamp = toISO(os.time())
		}

		for i, v in pairs(entryInfo.changes) do
			emb.description = emb.description .. "\n" .. emojis.space .. emojis.right .. " " .. string.capitalize(v.key) .. ": " .. v.old_value
		end

		local result = queueAuditRequest(guild.id)

		if not result then
			return
		end

		db:sendAuditLog(guild.id, "emojiupdate", {
			embed = emb
		})
	end, "auditlogs_emojiDelete") }
end -- End start function

auditlogs.Stop = function()
	for _, con in pairs(connections) do
		Client:removeListener(con[1], con[2])
	end

	connections = nil
	auditQueue = nil
end

return auditlogs