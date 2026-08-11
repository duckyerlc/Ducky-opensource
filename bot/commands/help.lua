-- help.lua
local slashCommand = tools.slashCommand("help", "View the Ducky Help menu.")
slashCommand = slashCommand:addOption(tools.string("category", "Jump to a specific category."):setRequired(false):setAutocomplete(true))

return {
	name = "help",
	description = "View the Ducky help menu.",
	aliases = { "cmds", "commands", "support", "assistance", "helpme" },
	slashCommand = slashCommand,
	requiredPermissions = {},
	category = "General",
	autocomplete = function(interaction, command, focused, args)
		local opts = {}

		if focused and focused.name == "category" then
			local categories = {}

			for _, cmd in pairs(_G.commands) do
				if not table.find(cmd.requiredPermissions or {}, "BOT_DEVELOPER")
				and not table.find(cmd.requiredPermissions or {}, "SUPPORT")
				and cmd.category then
					categories[cmd.category] = true
				end
			end

			categories["In-Game Commands"] = true

			local query = focused.value and focused.value:lower() or ""

			for catName in pairs(categories) do
				if query == "" or catName:lower():find(query, 1, true) then
					table.insert(opts, {
						name = catName,
						value = catName
					})
				end
			end
		end

		return interaction:autocomplete(opts)
	end,
    hybridCallback = function(interaction, args, slash, subcmd)
        local commands = {}
		local config = sqldb:get(interaction.guild.id) or {}
		local query = args and args[1] or args and args.category

        for i, v in pairs(_G.commands) do
			if (not table.find(v.requiredPermissions or {}, "BOT_DEVELOPER")) and (not table.find(v.requiredPermissions or {}, "SUPPORT")) then
				table.insert(commands, v)
			end
		end

		local categories = {
			["In-Game Commands"] = {
				description = "You can use these commands from your in-game private server. You must have your ERLC API key linked and the ERLC Commands Webhook Channel set.",
				[":log"] = {
					name = "log",
					description = "Use the available in-game commands.",
					subcommands = {
						"ping",
						"punish <username> <type> <reason>",
						"bolo <username> <reason>",
						"automations run <automationName/automationId>",
						"shift start <?type>",
						"shift pause",
						"shift end",
						"shift time",
						"message <staff/notindiscord/onshift/onpause/offshift/police/sheriff/fire/dot/civilian/wanted> <message>",
						"vehicle <vehicleName/vehiclePlate/vehicleColor>",
						"tempban <username> <duration> <reason>",
						"untempban <username> <reason>",
					}
				}
			}
		}

        for _, cmd in pairs(commands) do
			if not categories[cmd.category] then
				categories[cmd.category] = {}
				categories[cmd.category]["/" .. cmd.name] = cmd
			else
				categories[cmd.category]["/" .. cmd.name] = cmd
			end
		end

        for _, cmd in pairs(_G.commands) do
            if (table.find(cmd.requiredPermissions or {}, "BOT_DEVELOPER") and hasPermission(interaction.member, "BOT_DEVELOPER")) then
                if not categories["Developer"] then
                    categories["Developer"] = {}
                end
                categories["Developer"]["/" .. cmd.name] = cmd
            elseif (table.find(cmd.requiredPermissions or {}, "SUPPORT") and hasPermission(interaction.member, "SUPPORT")) then
                if not categories["Support"] then
                    categories["Support"] = {}
                end
                categories["Support"]["/" .. cmd.name] = cmd
            end
        end

        local function buildCategorySelector(showBack)
			local selector = discordia.SelectMenu({
				id = "categoryselect",
				placeholder = "Select a category...",
				actionRow = 1
			})

			for catName in pairs(categories) do
				selector:option(catName, catName, nil, nil, resolvedEmojis.folder)
			end

			if showBack then
				selector:option("Back", "back", nil, nil, resolvedEmojis.left)
			end

			return selector
		end

        local helpMenu = {
            embed = {
                title = emojis.ducky .. " Ducky's Commands",
                description = emojis.right .. " Welcome to " .. emojis.ducky .. " **Ducky's Help Menu**, view more information on commands below, or join our **[Ducky's Pond](https://duckybot.xyz/support)** for further assistance.",
                color = colors.duckyyellow
            },
            components = discordia.Components({
                buildCategorySelector(false)
                })
                :button({
                    url = 'https://discord.gg/w2dNr7vuKP',
                    style  = 'link',
                    label = 'Support Server',
                    emoji = resolvedEmojis.support

                })
                :button({
                    url = 'https://docs.duckybot.xyz/',
                    style = 'link',
                    label = 'Documentation',
                    emoji = resolvedEmojis.edit

                })
                :raw()
        }

        local initialMenu, initialCategory = nil, nil
        if query then
            local queryLower = tostring(query):lower()

            for catName, catData in pairs(categories) do
                if catName:lower() == queryLower then
                    initialCategory = catData
                    query = catName
                    break
                end
            end

            if not initialCategory then
                for catName, catData in pairs(categories) do
                    if catName:lower():find(queryLower, 1, true) then
                        initialCategory = catData
                        query = catName
                        break
                    end
                end
            end

            if not initialCategory then
                for catName, catData in pairs(categories) do
                    for cmdName, cmdData in pairs(catData) do
                        if type(cmdData) == "table" then
                            local cleanName = cmdName:gsub("^/", ""):lower()
                            
                            local match = cleanName:find(queryLower, 1, true)
                            
                            if not match and cmdData.aliases then
                                for _, alias in pairs(cmdData.aliases) do
                                    if tostring(alias):lower():find(queryLower, 1, true) then
                                        match = true
                                        break
                                    end
                                end
                            end

                            if match then
                                initialCategory = catData
                                query = catName
                                break
                            end
                        end
                    end
                    if initialCategory then break end
                end
            end
        end

        local function fetchDescription(data)
            local lines = {}
            if not categories[data] then 
                return emojis.right .. " " .. emojis.error .. " An unexpected error occurred while fetching command information."
            end

            for name, cmd in pairs(categories[data]) do
                if name ~= "description" then
                    local aliasList = ""
                    if cmd.aliases and next(cmd.aliases) then
                        local formatted = table.concatFn(cmd.aliases, ", ", function(a) 
                            return "`" .. (config.prefix or "d!") .. (type(a) == "table" and a[1] or a) .. "`" 
                        end)
                        aliasList = " (" .. formatted .. ")"
                    end

                    local str = emojis.right .. " **`" .. name .. "`**" .. aliasList .. ": " .. (cmd.description or emojis.fail)
                    
                    if cmd.subcommands then
                        local subLines = {}
                        for subKey, subVal in pairs(cmd.subcommands) do
                            local mainSub, aliases = "", {}

                            if type(subVal) == "table" then
                                mainSub = subKey
                                for _, v in ipairs(subVal) do
                                    table.insert(aliases, "`" .. v .. "`")
                                end
                            else
                                mainSub = subVal
                            end

                            local subAliases = #aliases > 0 and (" (" .. table.concat(aliases, ", ") .. ")") or ""
                            table.insert(subLines, emojis.space .. emojis.right .. " **`" .. name .. " " .. mainSub .. "`**" .. subAliases)
                        end
                        str = str .. "\n" .. table.concat(subLines, "\n")
                    end
                    
                    table.insert(lines, str)
                end
            end
            return table.concat(lines, "\n")
        end

        if initialCategory then
            initialMenu = {
                embeds = {{
                    title = emojis.folder .. " " .. query,
                    description = fetchDescription(query),
                    color = colors.duckyyellow
                }},
                components = discordia.Components({buildCategorySelector(true)}):raw()
            }
        else
            initialMenu = helpMenu
        end

        local menu = interaction:reply(initialMenu)

        onComp(menu, nil, nil, interaction.user.id, false, function(ia)
            local id = ia.data.custom_id
            local selection = ia.data.values and ia.data.values[1]

            if id == "categoryselect" then
                if selection == "back" then
					ia:update(helpMenu)
				else
                    ia:update({
                        embed = {
                            title = emojis.folder .. " " .. selection,
                            description = fetchDescription(selection),
                            color = colors.duckyyellow
                        }
                    })
                end
            end
        end)
    end
}