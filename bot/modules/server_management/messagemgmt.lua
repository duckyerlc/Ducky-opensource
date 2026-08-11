-- modules/messagemgmt.lua

local messagemgmt = {
	name = "messagemgmt",
	description = "Handles all messagemgmt related interactions.",
}

local connections = {}

local stickyDebounceCounters = {}

messagemgmt.Start = function()
	connections["messageCreateMessageMgmt"] = Client:on("messageCreateMessageMgmt", function(message, config)
		if
			config.stickymessages
			and table.count(config.stickymessages) > 0
			and (not message._flags or bit64.tonumber(message._flags) ~= 64)
		then
			for smi, stickyMessage in pairs(config.stickymessages or {}) do
				if type(stickyMessage) == "table" then
					if stickyMessage.channel == message.channel.id and message.user then
						stickyDebounceCounters[smi] = (stickyDebounceCounters[smi] or 0) + 1
						local myCount = stickyDebounceCounters[smi]

						coroutine.wrap(function()
							timer.sleep(2000)

							config = sqldb:get(message.guild.id) or {}
							if not config.stickymessages or not config.stickymessages[smi] then return end

							stickyMessage = config.stickymessages[smi]

							if type(stickyMessage) == "table" then
								if
									stickyDebounceCounters[smi] == myCount
									and (not stickyMessage.activeMessage or stickyMessage.activeMessage ~= message.id)
								then
									local activeMessage = stickyMessage.activeMessage
										and message.channel:getMessage(stickyMessage.activeMessage)
									if activeMessage then
										activeMessage:delete()
									end

									local s, e = message.channel:send(stickyMessage)
									if config.stickymessages and config.stickymessages[smi] and s and s.id then
										config.stickymessages[smi].activeMessage = s.id
										sqldb:set(message.guild.id, {
											stickymessages = config.stickymessages,
										}, "STICKY_MESSAGE_SET_ACTIVE")
									end
								end
							end
						end)()
					end
				end
			end
		end

		if config.autodeletechannels and table.count(config.autodeletechannels) > 0 then
			coroutine.wrap(function()
				for _, ad in pairs(config.autodeletechannels or {}) do
					if not ad.disabled and message.channel.id == ad.channel and ((not message.author.bot) or ad.botdelete) then
						timer.sleep(ad.delay * 1000)
						message:delete()
						break
					end
				end
			end)()
		end

		if config.autoreactchannels and table.count(config.autoreactchannels) > 0 then
			coroutine.wrap(function()
				for _, arChan in ipairs(config.autoreactchannels or {}) do
					if message.channel.id == arChan.channel and (((not message.author.bot) or arChan.botreact)) then
						message:addReaction(arChan.reaction)
						timer.sleep(5000)
					end
				end
			end)()
		end
	end)

	connections["interactionMessageMgmt"] = Client:on("interactionMessageMgmt", function(interaction, config)
		if not interaction.data.custom_id:match("^compbuilder_") then
			return
		end

		if interaction.data.component_type == discordia.enums.componentType.button then
			local exportableId = interaction.data.custom_id:match("compbuilder_(.*)")

			local exportable = exportableId and import(exportableId, "message")

			if exportable then
				fixCompId(exportable.components or {}, "custom_id")
				interaction:reply(exportable, true)
			else
				interaction:fail("Whoops... It looks like this exportable was not found.\n-# " .. emojis.right .. " Exportable ID: **`" .. (exportableId or "UNKNOWN") .. "`**", nil, true)
			end
		elseif interaction.data.component_type == discordia.enums.componentType.selectMenu then
			local selection = interaction.data and interaction.data.values and interaction.data.values[1]
			local exportableId = selection and selection:match("compbuilder_(.*)")
			local exportable = exportableId and import(exportableId, "message")

			if exportable then
				fixCompId(exportable.components or {}, "custom_id")
				interaction:reply(exportable, true)
				interaction:update({
					embeds = interaction.embeds,
					content = interaction.content,
					components = interaction.message.components
				})
			else
				interaction:fail("Whoops... It looks like this exportable was not found.\n-# " .. emojis.right .. " Exportable ID: **`" .. (exportableId or "UNKNOWN") .. "`**", nil, true)
			end
		end
	end)
end

messagemgmt.Stop = function()
	for event, connection in pairs(connections) do
		Client:removeListener(event, connection)
	end

	connections = nil
end

return messagemgmt
