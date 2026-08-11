-- message.lua

local slashCommand = tools.slashCommand("message", "Open the Message Editor and create a message.")
slashCommand = slashCommand:addOption(tools.string("import", "A Ducky Exportable code to import the message from."):setRequired(false))

return {
    name = "message",
    description = "Open the Message Editor and create a message.",
    aliases = {"msg", "embed", "emb"},
    category = "Utility",
    slashCommand = slashCommand,
    requiredPermissions = {"MANAGE_SERVER"},
	hybridCallback = function(interaction, args, slash)
		local importFrom = (slash and args and args.import) or ((not slash) and args and args[1])
		local default = nil

		if importFrom then
			if importFrom:usub(1,6) ==  "ducky_" then
				local imported, err = import(importFrom, "message", true)
				if not imported then
					return interaction:fail(err, nil, true)
				end

				default = imported.value

				fixCompId(default.components or {}, "custom_id")

				if default.components then
					local removedInfo
					default.components, removedInfo = validateButtons(default.components)

					if removedInfo then
						interaction:warning("The imported message contained invalid buttons which were removed:\n" .. emojis.right .. " " .. removedInfo, nil, true)
					end
				end
			else
				local code = nil

				if importFrom:usub(1,29) == "https://discohook.app/?share=" then code = importFrom:usub(30) else code = importFrom end

				local result, response = http.request("GET", "https://discohook.app/api/v1/share/" .. tostring(code))
				response = response and type(response) == "string" and json.decode(response)

				if result and response and result.code == 200 and response and response.data and response.data.messages and response.data.messages[1] and response.data.messages[1].data then

					if containsComponentsV2(response.data.messages[1].data.components) then
						return interaction:fail("Your Discohook message uses **Components v2**, which is not supported by " .. emojis.ducky .. " **Ducky**.", nil, true)
					end

					sanitizeButtons(response.data.messages[1].data.components)

					local success, err = interaction.channel:send(response.data.messages[1].data)

					if success then
						if response.data.messages[1].data.components then
							return interaction:warning("Your Discohook message has been successfully imported and sent, however components attached to your message will not function as they are not supported.\n-# " .. emojis.right .. " Link buttons will still work.", nil, true)
						else
							return interaction:success("Your Discohook message has been successfully imported and sent.", nil, true)
						end
					else
						return interaction:fail("Your Discohook message could not be sent:\n```\n" .. tostring(err) .. "```")
					end
				else
					return interaction:fail("Your Discohook message could not be imported.")
				end
			end
		end

		messageEditor(interaction, function(builtMessage)
			if builtMessage then
				interaction.channel:send(builtMessage)
			end
		end, nil, default, nil, true)
	end
}