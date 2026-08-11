-- shift.lua
local slashCommand = tools.slashCommand("shift", "Manage your shift.")
----------------------------------------------------------------------------------------------
local subcmdGroup = tools.subCommandGroup("wave", "Manage the shift wave.")
local subcmd = tools.subCommand("view", "View the current shift wave.")
subcmd = subcmd:addOption(tools.integer("wave", "View a previous shift wave."):setRequired(false))
subcmd = subcmd:addOption(tools.string("type", "View a specific shift type."):setRequired(false):setAutocomplete(true))
subcmdGroup:addOption(subcmd)
local subcmd = tools.subCommand("merge", "Merge all shifts from a shift wave into another.")
subcmd = subcmd:addOption(tools.integer("from", "The wave to merge shifts from."):setRequired(true))
subcmd = subcmd:addOption(tools.integer("to", "The wave to merge shifts into."):setRequired(true))
subcmdGroup:addOption(subcmd)
local subcmd = tools.subCommand("end", "End the current shift wave and start the next one.")
subcmdGroup:addOption(subcmd)
slashCommand:addOption(subcmdGroup)
----------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("manage", "Manage your shift.")
subcmd = subcmd:addOption(tools.string("type", "The shift type to use."):setRequired(false):setAutocomplete(true))
slashCommand:addOption(subcmd)
----------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("admin", "Administrate another member's shift.")
subcmd = subcmd:addOption(tools.user("member", "The member to administrate."):setRequired(true))
subcmd = subcmd:addOption(tools.string("type", "View a specific shift type."):setRequired(false):setAutocomplete(true))
slashCommand:addOption(subcmd)
----------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("history", "View your shift history.")
subcmd = subcmd:addOption(tools.user("member", "View another member's shift history."):setRequired(false))
subcmd = subcmd:addOption(tools.integer("wave", "View a previous shift wave."):setRequired(false))
slashCommand:addOption(subcmd)
----------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("active", "View active shifts.")
subcmd = subcmd:addOption(tools.string("type", "View a specific shift type."):setRequired(false):setAutocomplete(true))
slashCommand:addOption(subcmd)
----------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("void", "Void a shift by its ID.")
subcmd = subcmd:addOption(tools.string("id", "The ID of the shift to void."):setRequired(true))
slashCommand:addOption(subcmd)

return {
	name = "shift",
	description = "Manage your shift.",
	aliases = {
		"duty"
	},
	category = "Shifts",
	slashCommand = slashCommand,
	subcommands = {
		["wave view"] = {
			"leaderboard",
			"lb"
		},
		"wave merge",
		"wave end",
		manage = {
			"panel",
			"admin",
			"administrate"
		},
		"admin",
		history = {
			"time"
		},
		active = {
			"online"
		},
		void = {
			"delete",
			"remove"
		}
	},
	requiredPermissions = {
		"ERLC_STAFF"
	},
	autocomplete = function(interaction, command, focused, args)
		local opts = {}
		if focused and (focused.name == "type") then
			local config = sqldb:get(interaction.guild.id)

			if config and config.shifts and config.shifts.types then
				for i, v in pairs(config.shifts.types) do
					if (focused.value and v.name:lower():find(focused.value:lower())) or not focused.value or (focused.value == "") then
						table.insert(opts, {
							name = v.name,
							value = v.name
						})
					end
				end
			end
		end

		return interaction:autocomplete(opts)
	end,
	hybridCallback = function(interaction, args, slash, subcmd)
		if (not slash) and subcmd then
			table.remove(args, 1)
		end

		if (subcmd == "leaderboard") or (subcmd == "lb") or (subcmd == "wave view") or (subcmd == "wave" and args and args[1] == "view") then
			if subcmd ~= "leaderboard" and subcmd ~= "lb" then table.remove(args, 1) end
			local guild = interaction.guild

			local waveNumber = (slash and args and args.wave) or ((not slash) and args and args[1] and tonumber(args[1]))
			local wave, err = db:shiftWave(guild, waveNumber)
			if not wave then
				return interaction:fail(err, nil, true)
			end

			local typeName = (slash and args and args.type) or ((not slash) and args and table.remove(args, 1) and table.concat(args, " "))
			local type = typeName and db:shiftType(guild, typeName) or nil

			local r = interaction:loading()

			loadMembers(guild)
			local members = {}
			for _, member in pairs(guild.members) do
				if type and type.requiredrole then
					if member:hasRole(type.requiredrole) then
						table.insert(members, {
							member = member,
							time = db:shiftTotal(member, (type and type.name) or nil, wave.id)
						})
					end
				elseif (hasPermission(member, "ERLC_STAFF") == true) and (not member.user.bot) then
					table.insert(members, {
						member = member,
						time = db:shiftTotal(member, (type and type.name) or nil, wave.id)
					})
				end
			end
			table.sort(members, function(a, b)
				return a.time > b.time
			end)

			local waveTotal = 0

			for _, shift in pairs(wave.shifts) do
				waveTotal = waveTotal + ((shift.ended or os.time()) - shift.started)
			end

			local pages = {
				{
					author = author(guild),
					title = emojis.list .. " Shift Wave #" .. wave.id,
					description = emojis.right .. " **Started:** <t:" .. wave.started .. "> (<t:" .. wave.started .. ":R>)\n" .. emojis.right .. " **Ended:** " .. (wave.ended and ("<t:" .. wave.ended .. "> (<t:" .. wave.ended .. ":R>)") or "Active") .. "\n" .. emojis.right .. " **Total:** " .. table.count(wave.shifts) .. " shifts (" .. readable(waveTotal) .. " total elapsed time)" .. ((type and ("\n-# " .. emojis.right .. " Only showing **" .. type.name .. "** shift time")) or ""),
					color = wave.ended and colors.warning or colors.info,
					identifier = {
						emoji = resolvedEmojis.list,
						text = "Wave Overview"
					}
				}
			}

			local embed = {}
			local function resetEmbed()
				embed = {
					author = author(guild),
					title = emojis.list .. " Shift Wave #" .. wave.id,
					description = "",
					color = wave.ended and colors.warning or colors.info,
					count = 0
				}
			end
			resetEmbed()

			for i, member in pairs(members) do
				local emoji = emojis.right

				if type and type.quota then
					if member.time > type.quota then
						emoji = emojis.success
					else
						emoji = emojis.fail
					end
				end

				if db:getActiveLOA(member.member) then
					emoji = emojis.reminder
				end

				embed.description = embed.description .. emoji .. " " .. member.member.mentionString .. "・" .. readable(member.time) .. "\n"
				embed.count = embed.count + 1

				if embed.count >= 20 or i >= #members then
					if type then
						embed.description = embed.description .. "-# " .. emojis.right .. " Only showing **" .. type.name .. "** shift time" .. ((type.quota and (" (" .. readable(type.quota) .. " quota)")) or "")
					else
						embed.description = embed.description .. "-# " .. emojis.right .. " Showing all shift types・To see quotas, provide a specific shift type"
					end
					table.insert(pages, embed)
					resetEmbed()
				end
			end

			return paginate(r, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true,
				startPage = ((subcmd == "leaderboard" or subcmd == "lb") and pages[2] and 2) or 1
			})
		elseif (subcmd == "wave merge") or (subcmd == "wave" and args and args[1] == "merge") then
			if not hasPermission(interaction.member, "ERLC_MANAGER", nil, interaction) then
				return
			end

			if not slash then
				table.remove(args, 1)
			end

			local guild = interaction.guild

			local fromWaveNumber = (slash and args and args.from) or ((not slash) and args and args[1] and tonumber(args[1]))

			if not fromWaveNumber then
				return interaction:fail("You must provide a wave to merge from.", nil, true)
			end

			local fromWave, err = db:shiftWave(guild, fromWaveNumber)
			if not fromWave then
				return interaction:fail(err, nil, true)
			end

			local fromCount = table.count(fromWave.shifts or {})

			local toWaveNumber = (slash and args and args.to) or ((not slash) and args and args[2] and tonumber(args[2]))

			if not toWaveNumber then
				return interaction:fail("You must provide a wave to merge into.", nil, true)
			end

			local toWave, err = db:shiftWave(guild, toWaveNumber)
			if not toWave then
				return interaction:fail(err, nil, true)
			end

			confirm(interaction, "Are you sure you want to merge all **" .. fromCount .. " shifts** from **Wave " .. fromWave.id .. "** into **Wave " .. toWave.id .. "**?", function(confirmed, ria)
				if confirmed then
					local success, err = db:shiftWaveMerge(guild, interaction.member, fromWave.id, toWave.id)

					if success then
						return ria:success("All **" .. fromCount .. " shifts** from **Wave " .. fromWave.id .. "** have been merged into **Wave " .. toWave.id .. "**.", nil, true)
					else
						return ria:fail(err, nil, true)
					end
				end
			end, true, 10 * 1000)
		elseif (subcmd == "wave end") or (subcmd == "wave" and args and args[1] == "end") then
			if not hasPermission(interaction.member, "ERLC_MANAGER", nil, interaction) then
				return
			end

			local guild = interaction.guild
			local success, wave = db:shiftWaveEnd(guild, interaction.member)

			if success then
				return interaction:success("**Wave " .. wave.id .. "** has been ended.")
			else
				return interaction:fail(wave, nil, true)
			end
		elseif subcmd == "manage" or subcmd == "panel" or subcmd == "admin" or subcmd == "administrate" then
			local guild = interaction.guild
			local member = interaction.member
			local identifier = "Your"
			local admin = false
			local self = true

			if (subcmd == "admin" or subcmd == "administrate") and hasPermission(member, "ERLC_MANAGER", nil, interaction) then
				local m, s = fetchMemberFromInteraction(interaction, args, slash, "member")

				if s and not m and db:shiftActive(s, guild) then
					return confirm(interaction, getUserString(s) .. " is no longer a member of this server. Would you like to end their shift?", function(confirm, cia, r)
						if confirm then
							local succ, result = db:shiftForceEnd(s, guild)

							if succ then
								if interaction.editReply then
									interaction:editReply({embed = {color = colors.success, description = emojis.success .. " " .. result}, components = {}}, r.id)
								else
									r:update({embed = {color = colors.success, description = emojis.success .. " " .. result}})
								end
							else
								if interaction.editReply then
									interaction:editReply({embed = {color = colors.fail, description = emojis.fail .. " " .. result}, components = {}}, r.id)
								else
									r:update({embed = {color = colors.fail, description = emojis.fail .. " " .. result}})
								end
							end
						else
							if interaction.deleteReply then
								interaction:deleteReply(r.id)
							else
								r:update({embed = {color = colors.fail, description = emojis.fail .. " Canceled."}})
							end
						end
					end)
				end

				member = m or interaction.member
				identifier = ((member.id ~= interaction.member.id) and (getUserString(member) .. "'s")) or "Your"
				admin = true
				self = member.id == interaction.member.id

				if not slash then
					table.remove(args, 1)
				end
			end

			local typeName = (slash and args and args.type) or ((not slash) and args and table.concat(args, " "))
			local active = db:shiftActive(member)
			if active then
				typeName = active.type
			end
			typeName = (typeName ~= "" and typeName) or nil
			local type, err = db:shiftType(guild, typeName, interaction.member)
			if not type then
				return interaction:fail(err, nil, true)
			end

			local r = interaction:loading()

			local panel = {
				embed = {
					author = author(member),
					title = emojis.clock .. " Shift Panel"
				}
			}

			local function updatePanel(ia)
				ia = ia or r

				local active, pause = db:shiftActive(member)

				panel.components = discordia.Components()

				if admin then
					local opts = {
						{
							label = "Manage Shift Time",
							description = "Add or remove shift time from this member.",
							emoji = resolvedEmojis.clock,
							value = "time"
						}
					}

					if active then
						table.insert(opts, {
							label = "Void Active Shift",
							description = "Void this member's active shift.",
							emoji = resolvedEmojis.ban,
							value = "void",
							disabled = not active
						})
					end

					table.insert(opts, {
						label = "Wipe Shifts",
						description = "Wipe this member's shift history.",
						emoji = resolvedEmojis.delete,
						value = "wipe"
					})

					panel.components:selectMenu({
						id = "admin",
						placeholder = "Administrate shift...",
						options = opts,
						actionRow = 1
					})
				end

				if active then
					local elapsed, paused = db:shiftElapsed(interaction.guild, active.id)

					if pause then
						panel.embed.description = emojis.right .. " " .. identifier .. " **" .. type.name .. "** shift has been paused for **" .. readable(paused or 0) .. "**.\n" .. emojis.right .. " **Started:** <t:" .. active.started .. ":T> (<t:" .. active.started .. ":R>)\n" .. emojis.right .. " **Pause:** \n" .. emojis.space .. emojis.right .. " **Started:** <t:" .. pause.started .. ":T> (<t:" .. pause.started .. ":R>)\n" .. emojis.right .. " **Punishments:** " .. active.punishments .. "\n" .. emojis.right .. " **Commands:** " .. active.commands
						panel.embed.color = colors.warning
						panel.components:button({
							id = "start",
							label = "Resume",
							emoji = resolvedEmojis.play,
							style = "success",
							actionRow = admin and 2 or 1
						}):button({
							id = "pause",
							label = "Pause",
							emoji = resolvedEmojis.pause,
							style = "blurple",
							disabled = true,
							actionRow = admin and 2 or 1
						}):button({
							id = "end",
							label = "End",
							emoji = resolvedEmojis.stop,
							style = "danger",
							actionRow = admin and 2 or 1
						})
					else
						panel.embed.description = emojis.right .. " " .. identifier .. " **" .. type.name .. "** shift has been active for **" .. readable(elapsed) .. "**.\n" .. emojis.right .. " **Started:** <t:" .. active.started .. ":T> (<t:" .. active.started .. ":R>)\n" .. emojis.right .. " **Pauses:** " .. table.count(active.pauses) .. " (" .. readable(paused) .. ")\n" .. emojis.right .. " **Punishments:** " .. active.punishments .. "\n" .. emojis.right .. " **Commands:** " .. active.commands
						panel.embed.color = colors.success
						panel.components:button({
							id = "start",
							label = "Start",
							emoji = resolvedEmojis.play,
							style = "success",
							disabled = true,
							actionRow = admin and 2 or 1
						}):button({
							id = "pause",
							label = "Pause",
							emoji = resolvedEmojis.pause,
							style = "blurple",
							actionRow = admin and 2 or 1
						}):button({
							id = "end",
							label = "End",
							emoji = resolvedEmojis.stop,
							style = "danger",
							actionRow = admin and 2 or 1
						})
					end
				else
					panel.embed.description = emojis.right .. " " .. identifier .. " **" .. type.name .. "** shift is not active."
					panel.embed.color = colors.fail
					panel.components:button({
						id = "start",
						label = "Start",
						emoji = resolvedEmojis.play,
						style = "success",
						actionRow = admin and 2 or 1
					}):button({
						id = "pause",
						label = "Pause",
						emoji = resolvedEmojis.pause,
						style = "blurple",
						disabled = true,
						actionRow = admin and 2 or 1
					}):button({
						id = "end",
						label = "End",
						emoji = resolvedEmojis.stop,
						style = "danger",
						disabled = true,
						actionRow = admin and 2 or 1
					})
				end

				panel.components = panel.components:raw()

				local success, err = ia:update(panel)
				if not success then
					interaction.channel:send(err)
				end
			end

			updatePanel()

			onComp(r, nil, nil, interaction.user.id, false, function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				if id == "start" then
					local success, err = db:shiftStart(ia, member, type.name)

					if success then
						updatePanel(ia)
					else
						ia:fail(err, nil, true)
					end
				elseif id == "pause" then
					local success, err = db:shiftPause(member)

					if success then
						updatePanel(ia)
					else
						ia:fail(err, nil, true)
					end
				elseif id == "end" then
					local success, err = db:shiftEnd(member)

					if success then
						updatePanel(ia)
					else
						ia:fail(err, nil, true)
					end
				elseif id == "admin" then
					if selection == "time" then
						prompt(ia, "Manage Shift Time", {
							{
								question = "Shift Time",
								placeholder = "Append +/- before the time input to add/subtract shift time.",
								required = true,
								style = "short"
							},
							{
								question = "Shift Type",
								placeholder = "What shift type should this time apply to?",
								required = false,
								style = "short"
							}
						}, function(mia, responses)
							if mia then
								local amount = responses and responses["Shift Time"]
								local operation = amount:usub(1, 1)
								amount = convert(amount:usub(2))
								if (not amount) or (amount <= 0) then
									return mia:fail("You did not provide a valid amount of time.", nil, true)
								end

								local typeName = responses and responses["Shift Type"]
								local type, err = db:shiftType(interaction.guild, typeName, member)
								if not type then
									return mia:fail(err, nil, true)
								end

								if operation == "+" then
									local success, err = db:shiftTimeAdd(mia, member, interaction.member, amount, type.name)
									if success then
										mia:success("**" .. readable(amount) .. "** has been added to " .. ((self and "your") or getUserString(member) .. "'s") .. " **" .. type.name .. "** shift time.", nil, true)
										updatePanel()
									else
										mia:fail(err, nil, true)
									end
								elseif operation == "-" then
									local success, err = db:shiftTimeRemove(mia, member, interaction.member, amount, type.name)
									if success then
										mia:success("**" .. readable(amount) .. "** has been removed from " .. ((self and "your") or getUserString(member) .. "'s") .. " **" .. type.name .. "** shift time.", nil, true)
										updatePanel()
									else
										mia:fail(err, nil, true)
									end
								else
									mia:fail("You did not specify whether to add or remove shift time.", nil, true)
								end
							end
						end)
					elseif selection == "void" then
						local active = db:shiftActive(member)

						if active then
							confirm(ia, "Are you sure you would like to void " .. ((self and "your") or getUserString(member) .. "'s") .. " active shift?", function(confirmed, ria)
								if confirmed then
									local success, err = db:shiftVoid(member, active.id)
									if success then
										updatePanel()
									else
										ria:fail(err, nil, true)
									end
								end
							end, true, 5000)
						else
							updatePanel()
							ia:fail(((self and "You do") or getUserString(member) .. " does") .. " not have an active shift.", nil, true)
						end
					elseif selection == "wipe" then
						local wave, err = db:shiftWave(interaction.guild)

						if wave then
							confirm(ia, "Are you sure you would like to wipe **all** of " .. ((self and "your") or getUserString(member) .. "'s") .. " shifts within **Wave " .. wave.id .. "**?", function(confirmed, ria)
								if confirmed then
									local success, err = db:shiftWipe(member, interaction.member)
									if success then
										updatePanel()
									else
										ria:fail(err, nil, true)
									end
								end
							end, true, 5000)
						else
							updatePanel()
							ia:fail(err, nil, true)
						end
					end
				end
			end)
		elseif subcmd == "history" or subcmd == "time" then
			local guild = interaction.guild

			local member = fetchMemberFromInteraction(interaction, args, slash, "member") or interaction.member
			local identifier = ((member.id ~= interaction.member.id) and (getUserString(member) .. " has")) or "You have"
			local waveNumber = (slash and args and args.wave) or ((not slash) and args and args[1] and table.remove(args, 1) and tonumber(args[1]))
			local wave, err = db:shiftWave(guild, waveNumber)
			if not wave then
				return interaction:fail(err, nil, true)
			end

			local r = interaction:loading()

			local all = db:shiftHistory(member, nil, wave.id)
			local history = {}

			for _, shift in pairs(all) do
				if shift.ended then
					table.insert(history, shift)
				end
			end

			table.sort(history, function(a, b)
				return db:shiftElapsed(guild, a.id) > db:shiftElapsed(guild, b.id)
			end)

			local pages = {
				{
					author = author(member),
					title = emojis.list .. " Shift History",
					description = emojis.right .. " " .. identifier .. " completed a total of **" .. table.count(history) .. " shifts** in **Wave " .. wave.id .. "** and accumulated a total of **" .. readable(db:shiftTotal(member, nil, wave.id, true)) .. "** in shift time.",
					color = colors.info
				}
			}
			local embed = {}
			local function resetEmbed()
				embed = {
					author = author(member),
					title = emojis.list .. " Shift History",
					fields = {},
					color = colors.info,
					count = 0
				}
			end
			resetEmbed()

			for i, shift in pairs(history) do
				local elapsed, paused = db:shiftElapsed(guild, shift.id)
				table.insert(embed.fields, {
					name = "Shift " .. shift.id,
					value = emojis.right .. " **Type:** " .. shift.type .. "\n" .. emojis.right .. " **Started:** <t:" .. shift.started .. "> (<t:" .. shift.started .. ":R>)\n" .. emojis.right .. " **Pauses:** " .. table.count(shift.pauses) .. " (" .. readable(paused) .. ")\n" .. emojis.right .. " **Ended:** <t:" .. shift.ended .. "> (<t:" .. shift.ended .. ":R>)\n" .. emojis.right .. " **Elapsed:** " .. readable(elapsed) .. "\n" .. emojis.right .. " **Punishments:** " .. shift.punishments .. "\n" .. emojis.right .. " **Commands:** " .. shift.commands
				})

				if table.count(embed.fields) >= 5 or i >= #history then
					table.insert(pages, embed)
					resetEmbed()
				end
			end

			return paginate(r, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		elseif subcmd == "active" or subcmd == "online" then
			local guild = interaction.guild

			local wave, err = db:shiftWave(guild)
			if not wave then
				return interaction:fail(err, nil, true)
			end

			local typeName = (slash and args and args.type) or ((not slash) and args and table.concat(args, " "))
			local type = typeName and typeName ~= "" and db:shiftType(guild, typeName)

			table.sort(wave.shifts, function(a, b)
				return db:shiftElapsed(guild, a.id) > db:shiftElapsed(guild, b.id)
			end)

			local pages = {}
			local embed = {}
			local function resetEmbed()
				embed = {
					author = author(guild),
					title = emojis.clock .. " Active Shifts",
					description = "",
					color = colors.info,
					count = 0
				}
			end
			resetEmbed()

			local active = {}

			for i, shift in pairs(wave.shifts) do
				if (not shift.ended) and ((type and shift.type == type.name) or (not type)) then
					table.insert(active, shift)
				end
			end

			for i, shift in pairs(active) do
				embed.description = embed.description .. emojis.right .. " <@" .. shift.member .. "> (**" .. shift.type .. "**)・" .. readable(db:shiftElapsed(guild, shift.id)) .. "\n"
				embed.count = embed.count + 1

				if embed.count >= 20 or i >= #active then
					table.insert(pages, embed)
					resetEmbed()
				end
			end

			if not next(active) then
				return interaction:fail("There are no active" .. ((type and (" **" .. type.name .. "**")) or "") .. " shifts.")
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		elseif subcmd == "void" or subcmd == "delete" or subcmd == "remove" then
			if not hasPermission(interaction.member, "ERLC_MANAGER", nil, interaction) then
				return
			end

			local guild = interaction.guild
			local id = (slash and args and args.id) or ((not slash) and args and args[1])
			if not id then
				return interaction:fail("You did not provide the ID of the shift to void.", nil, true)
			end

			local success, message = db:shiftVoid(interaction.member, id)
			if success then
				return interaction:success(message)
			else
				return interaction:fail(message, nil, true)
			end
		end
	end
}
