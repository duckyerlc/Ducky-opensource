-- usersettings.lua
local slashCommand = tools.slashCommand("usersettings", "Modify/view your user settings.")

local function findSimilarTimezones(input)
	input = input:lower()

	local suggestions = {}

	for _, tz in pairs(timezones) do
		local abrvLower = tz.abrv:lower()
		local nameLower = tz.name:lower()

		if abrvLower:find(input) or nameLower:find(input) then
			table.insert(suggestions, tz)
		elseif string.levenshtein(input, abrvLower) <= 1 then
			table.insert(suggestions, tz)
		end
	end

	return suggestions
end

return {
	name = "usersettings",
	description = "Modify/view your user settings.",
	aliases = {
		"mysettings",
		"us",
		"usettings"
	},
	category = "Configuration",
	slashCommand = slashCommand,
	requiredPermissions = {},
	hybridCallback = function(interaction, args)
		local settings = sqldb:getUserSettings(interaction.user.id) or {}

		local settingsMenu = interaction:reply({
			embed = {
				description = emojis.loading,
				color = colors.blank
			}
		})

		if settings.infractionnotifications == nil then
			settings.infractionnotifications = true
			sqldb:setUserSettings(interaction.user.id, settings)
		end

		if settings.ticketnotifications == nil then
			settings.ticketnotifications = true
			sqldb:setUserSettings(interaction.user.id, settings)
		end

		if settings.trackplaytime == nil then
			settings.trackplaytime = true
			sqldb:setUserSettings(interaction.user.id, settings)
		end

		local function updateMenu(ia)
			local toupd = ia or settingsMenu
			return toupd:update({
				embed = {
					author = {
						name = "@" .. interaction.user.username,
						icon_url = interaction.user.avatarURL
					},
					title = emojis.settings .. " User Settings",
					description = emojis.right .. " **AutoShifts:** " .. ((settings.autoshifts and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Default AFK:** " .. (settings.defaultafkreason or emojis.fail) .. "\n" .. emojis.right .. " **Global AFK:** " .. ((settings.globalafk and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Timezone:** " .. ((settings.timezone and (settings.timezone.name .. " (`" .. settings.timezone.abrv .. "`)")) or emojis.fail) .. "\n" .. emojis.right .. " **Infraction Notifications:** " .. ((settings.infractionnotifications and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Ticket Notifications:** " .. ((settings.ticketnotifications and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Punishment Notifications:** " .. ((settings.punishmentnotifications == "dms" and "Discord DMs") or (settings.punishmentnotifications == "both" and "Both") or (settings.punishmentnotifications == "none" and emojis.fail) or "In-Game PMs") .. "\n" .. emojis.right .. " **Track Playtime:** " .. ((settings.trackplaytime and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **[Use Bloxlink API](https://duckybot.xyz/legal/privacy#discord):** " .. ((settings.bloxlinkoptout and emojis.fail) or emojis.success),
					color = colors.info
				},
				components = discordia.Components():selectMenu({
					id = "edit",
					placeholder = "Edit settings...",
					actionRow = 1,
					emoji = emojis.settings,
					options = {
						{
							label = "Toggle AutoShifts",
							description = "Automatically manage your shift based on in-game status",
							value = "autoshifts",
							emoji = resolvedEmojis.clock
						},
                        {
							label = "Edit Default AFK",
							description = "The default AFK message to use if none is provided",
							value = "defaultafkreason",
							emoji = resolvedEmojis.edit
						},
						{
							label = "Toggle Global AFK",
							description = "Set your AFK status in every server",
							value = "globalafk",
							emoji = resolvedEmojis.cloud
						},
						{
							label = "Toggle Infraction Notifications",
							description = "Receive notifications for infraction edits, removals, or expirations",
							value = "infractionnotifications",
							emoji = resolvedEmojis.quickfix
						},
						{
							label = "Toggle Ticket Notifications",
							description = "Receive notifications for ticket transcripts",
							value = "ticketnotifications",
							emoji = resolvedEmojis.ticket
						},
						{
							label = "Edit Timezone",
							description = "Set your publicly-shared timezone",
							value = "timezone",
							emoji = resolvedEmojis.web
						},
						{
							label = "Edit Punishment Notifications",
							description = "Receive notifications for ERLC moderations",
							value = "punishmentnotifications",
							emoji = resolvedEmojis.moderate
						},
						{
							label = "Toggle Track Playtime",
							description = "Track your playtime across all ERLC servers linked with Ducky",
							value = "trackplaytime",
							emoji = resolvedEmojis.game
						},
						{
							label = "Toggle Bloxlink Opt-out",
							description = "Opt-out of using the Bloxlink API",
							value = "bloxlinkoptout",
							emoji = resolvedEmojis.Bloxlink
						}
					}
				}):raw()
			})
		end

		updateMenu()

		onComp(settingsMenu, nil, nil, interaction.user.id, false, function(ia)
			local id = ia.data.custom_id
			local selection = ia.data.values and ia.data.values[1]

			if id == "edit" then
				if selection == "autoshifts" then
					settings.autoshifts = not settings.autoshifts
					sqldb:setUserSettings(interaction.user.id, settings)
					updateMenu(ia)
                elseif selection == "defaultafkreason" then
                    prompt(ia, "Edit Default AFK Message", {
                        {
                            question = "Default AFK Message",
                            placeholder = "Enter your default AFK message...",
                            required = false,
                            max = 300,
                            style = "short"
                        }
                    }, function(mia, responses)
                        local message = responses and responses["Default AFK Message"] and responses["Default AFK Message"] ~= "" and responses["Default AFK Message"] ~= " " and sanitize(string.truncate(responses["Default AFK Message"], 300), interaction.guild) or nil
                        if mia and responses and message then
                            settings.defaultafkreason = message
                            sqldb:setUserSettings(interaction.user.id, settings)
                            updateMenu()
                            mia:updateDeferred(true)
                        else
                            settings.defaultafkreason = nil
                            sqldb:setUserSettings(interaction.user.id, settings)
                            updateMenu()
                            mia:updateDeferred(true)
                        end
                    end)
				elseif selection == "globalafk" then
					settings.globalafk = not settings.globalafk
					sqldb:setUserSettings(interaction.user.id, settings)
					updateMenu(ia)
				elseif selection == "infractionnotifications" then
					settings.infractionnotifications = not settings.infractionnotifications
					sqldb:setUserSettings(interaction.user.id, settings)
					updateMenu(ia)
				elseif selection == "ticketnotifications" then
					settings.ticketnotifications = not settings.ticketnotifications
					sqldb:setUserSettings(interaction.user.id, settings)
					updateMenu(ia)
				elseif selection == "trackplaytime" then
					settings.trackplaytime = not settings.trackplaytime
					sqldb:setUserSettings(interaction.user.id, settings)
					updateMenu(ia)
				elseif selection == "punishmentnotifications" then
					optionsSelect(ia, "Select a notification type...", function(opt)
						settings.punishmentnotifications = opt
						sqldb:setUserSettings(interaction.user.id, settings)
						updateMenu()
					end, true, {
						{
							label = "In-Game PMs",
							description = "Use the in-game :pm command",
							value = "ingame",
							emoji = resolvedEmojis.game
						},
						{
							label = "Discord DMs",
							description = "Use your Discord DMs",
							value = "dms",
							emoji = resolvedEmojis.chat
						},
						{
							label = "Both",
							description = "Use both Discord DMs and in-game PMs",
							value = "both",
							emoji = resolvedEmojis.transfer
						},
						{
							label = "None",
							description = "Do not notify in any way",
							value = "none",
							emoji = resolvedEmojis.nowhite
						}
					}, 1, nil, true)
				elseif selection == "bloxlinkoptout" then
					settings.bloxlinkoptout = not settings.bloxlinkoptout
					sqldb:setUserSettings(interaction.user.id, settings)
					updateMenu(ia)
				elseif selection == "timezone" then
					prompt(ia, "Edit Timezone", {
						{
							question = "Your Timezone",
							placeholder = "Enter your timezone's abbrevation... (e.g. EST, CST, UTC-6, GMT+3)",
							required = false,
							max = 6,
							style = "short"
						}
					}, function(mia, responses)
						if mia and responses and responses["Your Timezone"] then
							local full = responses["Your Timezone"]:upper()

							local signIndex = full:find("[%+%-]")

							local abrv = signIndex and full:usub(1, signIndex - 1) or full
							local sign = signIndex and full:usub(signIndex, signIndex) or nil
							local offset = sign and tonumber(full:usub(signIndex)) or nil

							local timezone = nil

							for _, tz in pairs(timezones) do
								if tz.abrv == abrv then
									timezone = table.deepcopy(tz)
								end
							end

							if timezone and offset then
								timezone = {
									abrv = timezone.abrv .. sign .. math.abs(offset),
									name = timezone.name .. " " .. sign .. " " .. math.abs(offset) .. " hours",
									offset = timezone.offset + offset,
									twelvehourclock = timezone.twelvehourclock
								}
							end

							if timezone then
								settings.timezone = timezone
								sqldb:setUserSettings(interaction.user.id, settings)
								updateMenu()
								mia:updateDeferred(true)
							else
								return mia:fail("That timezone was not found. Run `/time zonelist` for a full list of available timezones.", nil, true)
							end
						else
							settings.timezone = nil
							sqldb:setUserSettings(interaction.user.id, settings)
							updateMenu()
							mia:updateDeferred(true)
						end
					end)
				end
			end
		end)
	end
}
