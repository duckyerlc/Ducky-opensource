-- modules/autoresponders.lua

local autoresponders = {
	name = "autoresponders",
	description = "Handles all autoresponders related interactions.",
}

local connections = {}

local mapause = 3 -- Minimum autoresponder cooldown (seconds)

autoresponders.Start = function()
	connections["messageCreateAutoresponders"] = Client:on("messageCreateAutoresponders", function(message, config)
		local guild = message.guild

		if config.autoresponders and (table.count(config.autoresponders) > 0) then
			local autoresponder = nil

			for i, ar in pairs(config.autoresponders) do
				if not ar.disabled and (not ar.requiredrole or message.member:hasRole(ar.requiredrole)) then -- skip this autoresponder if it's disabled or the member does not have the required role, if one exists
					local sent = tostring(message.content)
					local trigger = tostring(ar.trigger)

					if not ar.casesensitive then
						sent = sent:lower()
						trigger = trigger:lower()
					end

					if (ar.matchexact and sent == trigger) or ((not ar.matchexact) and sent:find(trigger)) then
						autoresponder = ar
						break
					end
				end
			end

			if autoresponder then
                local lastTriggered = autoresponder.lastTriggered or 0

                autoresponder.cooldown = (autoresponder.cooldown >= mapause and autoresponder.cooldown) or mapause
                if (os.time() - lastTriggered) < autoresponder.cooldown then
                    message:addReaction(resolvedEmojis.clock.hash)
                    return
                end

				if autoresponder.deletetrigger then
					if message.referencedMessage then
						message.referencedMessage:reply(autoresponder.response, nil, nil, true)
					else
						message.channel:send(autoresponder.response)
					end

					message:delete()
				else
					message:reply(autoresponder.response, nil, nil, true)
				end

				if autoresponder.cooldown then
					for _, ar in pairs(config.autoresponders) do
						if ar.name == autoresponder.name then
							ar.lastTriggered = os.time()
							sqldb:set(guild.id, {
								autoresponders = config.autoresponders,
							}, "AUTORESPONDER_LAST_TRIGGER")
						end
					end
				end
			end
		end
	end)
end

autoresponders.Stop = function()
	for event, connection in pairs(connections) do
		Client:removeListener(event, connection)
	end

	connections = nil
end

return autoresponders