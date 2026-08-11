-- modules/punishments.lua

local punishments = {
	name = "punishments",
	description = "Handles all punishment related interactions.",
}

local connections = {}

punishments.Start = function()
    connections["interactionPunishments"] = Client:on("interactionPunishments", function(interaction, config)
        local guild = interaction.guild

        if interaction.data.custom_id:usub(1, 15) == "editpunishment_" then
			local pid = interaction.data.custom_id:usub(16)
			local punishment = nil

			for i, v in pairs(config.punishments or {}) do
				if tonumber(v.id) == tonumber(pid) then
					punishment = v
					break
				end
			end

			if not punishment then return interaction:fail("I could not find this punishment.", nil, true) end

			if (interaction.member.id ~= punishment.moderator) and (not hasPermission(interaction.member, "ERLC_ADMIN", config, interaction)) then return end

			prompt(interaction, "Edit Punishment Reason", {
				{
					question = "Edit Punishment Reason",
					placeholder = "Edit punishment reason...",
					style = "short",
					required = false
				}
			}, function(mia, responses)
				local response = responses["Edit Punishment Reason"]

				if response and response ~= "" then
					local config = sqldb:get(guild.id) or {}
					for _, p in pairs(config.punishments or {}) do if p.id == punishment.id then p.reason = response end end
					sqldb:set(guild.id, {
						punishments = config.punishments
					}, "PUNISHMENT_EDIT_REASON")
					mia:updateDeferred(true)
					local moderator = guild:getMember(punishment.moderator)
					local robloxUser = punishment.robloxUser
					local punishmentType = punishment.type
					local reason = response
					local punishmentid = punishment.id

					interaction.message:update({
						embed = {
							title = emojis.moderate .. " Punishment Log",
							description = "**" .. moderator.name .. "** punished [**" .. robloxUser.name .. "**](" .. robloxUser.profile .. ") with a **" .. punishmentType .. "**:\n" .. emojis.right .. " **Player:** [" .. robloxUser.name .. "](" .. robloxUser.profile .. ")\n" .. emojis.right .. " **Reason:** " .. reason .. "\n" .. emojis.right .. " **Date:** <t:" .. os.time() .. ">\n" .. emojis.right .. " **Punishment ID:** `" .. punishmentid .. "`",
							color = colors.success,
							thumbnail = {
								url = robloxUser.avatar
							}
						},
						content = "",
						components = {}
					})
				else
					return mia:fail("You did not enter a new reason.", nil, true)
				end
			end)
		end
    end)

	connections["interactionBolo"] = Client:on("interactionBolo", function(interaction, config)
		local guild = interaction.guild
		local member = interaction.member

		if interaction.data.custom_id:usub(1, 8) == "approve_" then
			if not hasPermission(member, "ERLC_ADMIN", config, interaction) then return end

			local thinking = interaction:replyDeferred(true)

			local boloId = interaction.data.custom_id:usub(9)

			config = config or sqldb:get(guild.id) or {}
			if not config or not config.bolos then return end

			local targetBolo
			for _, bolo in pairs(config.bolos) do
				if tostring(bolo.id) == boloId then
					targetBolo = bolo
					break
				end
			end

			if not targetBolo then 
				interaction.message:delete()
				return interaction:fail("This BOLO no longer exists.", nil, true)
			end

			local robloxUser = ropi.GetUser(targetBolo.user)
			if not robloxUser then return interaction:fail("I could not fetch the Roblox user for this BOLO.", nil, true) end

			local s, e = db:completeBOLO(robloxUser, member)
			if s then
				local desc = emojis.success .. " This BOLO has been **approved**."

				local server, err = ERLC:getServer(config.apikey)
				if server and #server.players > 0 then
					local success, err = server:execute(":ban " .. robloxUser.id)
					if success then
						desc = desc .. "\n" .. emojis.success .. " **" .. robloxUser.name .. "** has also been banned in-game."
					else
						desc = desc .. "\n" .. emojis.fail .. " **" .. robloxUser.name .. "** could not be banned in-game."
					end
				end

				interaction:deleteReply(thinking.id)
				interaction.message:update({
					embed = {
						title = emojis.success .. " " .. robloxUser.name .. " (`" .. robloxUser.id .. "`)",
						description = desc,
						color = colors.success,
						thumbnail = (robloxUser.avatar and { url = robloxUser.avatar }) or nil
					},
					components = {}
				})
			else
				interaction:fail(e or "Failed to approve BOLO.", nil, true)
			end

		elseif interaction.data.custom_id:usub(1, 5) == "deny_" then
			if not hasPermission(member, "ERLC_ADMIN", config, interaction) then return end
			local boloId = interaction.data.custom_id:usub(6)

			config = config or sqldb:get(guild.id) or {}
			if not config or not config.bolos then return end

			local targetBolo
			for _, bolo in pairs(config.bolos) do
				if tostring(bolo.id) == boloId then
					targetBolo = bolo
					break
				end
			end

			if not targetBolo then 
				interaction.message:delete()
				return interaction:fail("This BOLO no longer exists.", nil, true)
			end

			local robloxUser = ropi.GetUser(targetBolo.user)
			if not robloxUser then return interaction:fail("I could not fetch the Roblox user for this BOLO.", nil, true) end

			local s, e = db:denyBOLO(robloxUser, member)
			if s then
				interaction:updateDeferred(true)
				interaction.message:update({
					embed = {
						title = emojis.fail .. " " .. robloxUser.name .. " (`" .. robloxUser.id .. "`)",
						description = emojis.fail .. " This BOLO has been **denied**.",
						color = colors.fail,
						thumbnail = (robloxUser.avatar and { url = robloxUser.avatar }) or nil
					},
					components = {}
				})
			else
				interaction:fail(e or "Failed to deny BOLO.", nil, true)
			end
		end
	end)
end

punishments.Stop = function()
	for event, connection in pairs(connections) do
		Client:removeListener(event, connection)
	end

	connections = nil
end

return punishments