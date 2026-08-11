-- modules/welcome.lua
local welcome = {
	name = "welcome",
	description = "Handles all welcome related interactions."
}

local connections = {}

welcome.Start = function()
	connections["memberJoinWelcome"] = Client:on("memberJoinWelcome", function(member, config)
		local guild = member.guild
		
		if config.joingatethreshold and member.user.createdAt and guild then
			local created = member.user.createdAt and math.round(member.user.createdAt)
			if (realtime() - created) < config.joingatethreshold then
				member:kick("does not meet joingate threshold of " .. readable(config.joingatethreshold))

				db:send(guild, "modlogchannel", {
					embed = {
						author = author(member),
                		thumbnail = thumbnail(member),
						title = emojis.kick .. " Joingate Triggered",
						color = colors.fail,
						description = getUserString(member.user) .. " has been kicked for not meeting the account age threshold of **" .. readable(config.joingatethreshold) .. "**:\n"
							.. emojis.right .. " **Account Created:** <t:" .. created .. "> (<t:" .. created .. ":R>)\n"
							.. emojis.right .. " **Joined:** " .. "<t:" .. os.time() .. "> (<t:" .. os.time() .. ":R>)\n"
					}
				})

				return member:warning("You have been automatically kicked from **" .. guild.name .. "** for not meeting the joingate threshold. Your account must be at least **" .. readable(config.joingatethreshold) .. "** old in order to join this server.", emojis.kick)
			end
		end

		if (config.joinmessage and config.joinchannel) or (config.dmjoin and config.dmjoinmessage) then
			local ch = member.guild:getChannel(config.joinchannel)
			if ch then
				local tosend = config.joinmessage

				local m = member
				local g = member.guild

				local keys = {
					["member.mention"] = m.mentionString,
					["member.name"] = m.name or m.user.globalName or m.user.username,
					["member.username"] = m.user.username,
					["member.id"] = m.id,
					["guild.name"] = g.name,
					["guild.id"] = g.id,
					["guild.membercount"] = formatNumber(g.totalMemberCount),
					["guild.membercount.raw"] = g.totalMemberCount,
					["guild.membercount.suffix"] = ordinal(g.totalMemberCount)
				}

				tosend = (tosend and parseTable(tosend, keys)) or nil

				local roleButton

				if hasPermission(m, "BOT_DEVELOPER") then
					roleButton = {
						type = 2,
						style = 5,
						url = "https://duckybot.xyz/support",
						label = "Ducky Developer",
						emoji = resolvedEmojis.developer
					}
				elseif hasPermission(m, "WEB_DEVELOPER") then
					roleButton = {
						type = 2,
						style = 5,
						url = "https://duckybot.xyz/support",
						label = "Ducky Web Developer",
						emoji = resolvedEmojis.web
					}
				elseif hasPermission(m, "EXECUTIVE") then
					roleButton = {
						type = 2,
						style = 5,
						url = "https://duckybot.xyz/support",
						label = "Ducky Executive",
						emoji = resolvedEmojis.executive
					}
				elseif hasPermission(m, "MANAGEMENT") then
					roleButton = {
						type = 2,
						style = 5,
						url = "https://duckybot.xyz/support",
						label = "Ducky Management",
						emoji = resolvedEmojis.settings
					}
				elseif hasPermission(m, "SUPPORT") then
					roleButton = {
						type = 2,
						style = 5,
						url = "https://duckybot.xyz/support",
						label = "Ducky Support",
						emoji = resolvedEmojis.support
					}
				elseif hasPermission(m, "DUCKY_STAFF") then
					roleButton = {
						type = 2,
						style = 5,
						url = "https://duckybot.xyz/support",
						label = "Ducky Staff",
						emoji = resolvedEmojis.permission
					}
				elseif hasPermission(m, "QUALITY_ASSURANCE") then
					roleButton = {
						type = 2,
						style = 5,
						url = "https://duckybot.xyz/support",
						label = "Ducky Quality Assurance",
						emoji = resolvedEmojis.qa
					}
				elseif hasPermission(m, "DOCWRITER") then
					roleButton = {
						type = 2,
						style = 5,
						url = "https://duckybot.xyz/support",
						label = "Ducky Docwriter",
						emoji = resolvedEmojis.edit
					}
				end

				if roleButton then
					tosend.components = tosend.components or {}

					if #tosend.components < 5 then
						table.insert(tosend.components, {
							type = 1,
							components = { roleButton }
						})
					end
				end

				tosend.allowedMentions = {
					users = {
						m.id
					}
				}

				if tosend.components then
					for _, row in ipairs(tosend.components) do
						if row.components then
							for _, component in ipairs(row.components) do
								if component.label and type(component.label) == "string" then
									component.label = string.truncate(component.label, 80)
								end
							end
						end
					end
				end

				fixCompId(tosend.components, "custom_id", true)

				local msg, err = ch:send(tosend)

				if config.joinmessagedelete then
					coroutine.wrap(function()
						timer.sleep(config.joinmessagedelete * 1000)
						
						if msg then
							msg:delete()
						end
					end)()
				end
			end

			local tosendDM = config.dmjoinmessage

			local m = member
			local g = member.guild

			local keys = {
				["member.mention"] = m.mentionString,
				["member.name"] = m.name or m.user.globalName or m.user.username,
				["member.username"] = m.user.username,
				["member.id"] = m.id,
				["guild.name"] = g.name,
				["guild.id"] = g.id,
				["guild.membercount"] = formatNumber(g.totalMemberCount),
				["guild.membercount.raw"] = g.totalMemberCount,
				["guild.membercount.suffix"] = ordinal(g.totalMemberCount)
			}

			tosendDM = (tosendDM and parseTable(tosendDM, keys)) or nil
			if tosendDM then
				tosendDM.components = signature(g)
			end

			if tosendDM then
				m.user:send(tosendDM)
			end
		end
	end)
end

welcome.Stop = function()
	for event, connection in pairs(connections) do
		Client:removeListener(event, connection)
	end

	connections = nil
end

return welcome
