-- erlc.lua
local slashCommand = tools.slashCommand("erlc", "Use Ducky's ERLC integration.")
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("players", "View in-game players.")
subcmd = subcmd:addOption(
	tools.string("team", "The team to view players of.")
		:addChoice(tools.choice("Civilian", "Civilian"))
		:addChoice(tools.choice("Police", "Police"))
		:addChoice(tools.choice("Sheriff", "Sheriff"))
		:addChoice(tools.choice("Fire", "Fire"))
		:addChoice(tools.choice("DOT", "DOT"))
		:addChoice(tools.choice("Jail", "Jail"))
		:setRequired(false)
)
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("staff", "Check your ERLC server's staff.")
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("server", "Check your ERLC server.")
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("check", "Show in-game players that are not in the Discord server.")
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("queue", "Show players in the queue.")
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("vehicles", "Show the vehicles that are spawned in-game.")
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("kills", "Show the in-game kill logs.")
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("logs", "Show the in-game command logs.")
subcmd = subcmd:addOption(tools.string("player", "The player to show logs from."):setRequired(false):setAutocomplete(true))
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("panel", "Manage an in-game player.")
subcmd = subcmd:addOption(tools.string("player", "The player to manage."):setRequired(true):setAutocomplete(true))
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("modcalls", "Show the in-game mod call logs.")
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("emergencies", "Show the active in-game emergencies.")
subcmd = subcmd:addOption(
	tools.string("team", "The team to show emergencies for.")
		:addChoice(tools.choice("Police", "Police"))
		:addChoice(tools.choice("Sheriff", "Sheriff"))
		:addChoice(tools.choice("Fire", "Fire"))
		:addChoice(tools.choice("DOT", "DOT"))
		:setRequired(false)
)
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("joins", "Show the join/leave logs in-game.")
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("bans", "Show the in-game bans, and search for a name if specified.")
subcmd = subcmd:addOption(tools.string("query", "The query of the username to search for."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("execute", "Execute a command within the in-game server.")
subcmd = subcmd:addOption(tools.string("command", "The command to send to the in-game server."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("tempban", "Temporarily ban someone in-game.")
subcmd = subcmd:addOption(tools.string("player", "Player to tempban."):setRequired(true))
subcmd = subcmd:addOption(tools.string("duration", "How long to ban the user (m, h, w, y)."):setRequired(true))
subcmd = subcmd:addOption(tools.string("reason", "The reason for the tempban."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("untempban", "Remove an in-game temporarily ban.")
subcmd = subcmd:addOption(tools.string("player", "Player to untempban."):setRequired(true))
subcmd = subcmd:addOption(tools.string("reason", "The reason for the untempban."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("permissions", "View all staff members and their permission levels.")
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("playtime", "View the playtime leaderboard.")
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("locate", "View the location of an in-game player.")
subcmd = subcmd:addOption(tools.string("player", "The player to locate."):setRequired(true):setAutocomplete(true))
slashCommand = slashCommand:addOption(subcmd)
-----------------------------------------------------------------------------------------------------------

local teams = {
	civilian = "Civilian",
	civ = "Civilian",
	police = "Police",
	pd = "Police",
	officers = "Police",
	cops = "Police",
	sheriff = "Sheriff",
	sherrif = "Sheriff",
	fire = "Fire",
	firefighter = "Fire",
	firefighters = "Fire",
	ems = "Fire",
	fd = "Fire",
	dot = "DOT",
	jail = "Jail",
	criminal = "Jail",
	criminals = "Jail"
}

return {
	name = "erlc",
	description = "Use Ducky's ERLC integration.",
	aliases = {
		"emergencyresponselibertycounty",
		"libertycounty",
		"rivercity"
	},
	category = "ERLC",
	slashCommand = slashCommand,
	subcommands = {
		server = {
			"info",
			"information",
		},
		players = {
			"plrs"
		},
		"staff",
		check = {
			"discord"
		},
		vehicles = {
			"cars"
		},
		kills = {
			"kl",
			"killlogs",
			"kls",
			"kill"
		},
		logs = {
			"commands",
			"cmds",
			"cmdlogs"
		},
		joins = {
			"leaves",
			"joinlogs",
			"leavelogs",
			"playerlogs"
		},
		modcalls = {
			"mcs",
			"modcall"
		},
		emergencies = {
			"emgs",
			"emergencycalls",
			"calls"
		},
		permissions = {
			"perms"
		},
		execute = {
			"command",
			"cmd"
		},
		"tempban",
		"untempban",
		"queue",
		"playtime",
		"panel",
		bans = {
			"banlist"
		},
		locate = {
			"location"
		}
	},
	requiredPermissions = {
		"SETUP",
		"ERLC_LINKED"
	},
	autocomplete = function(interaction, command, focused, args)
		local opts = {}
		if focused and (focused.name == "player") then
			local config = sqldb:get(interaction.guild.id)

			if config and config.apikey then
                local server = ERLC:getServer(config.apikey)
                
                if server then
                    for _, player in pairs(server._players) do
                        if (focused.value and player.name:lower():find(focused.value:lower())) or not focused.value or (focused.value == "") then
                            table.insert(opts, {
                                name = player.name,
                                value = player.name
                            })
                        end
                    end
                end
			end
		end

		return interaction:autocomplete(opts)
	end,
	hybridCallback = function(interaction, args, slash, subcmd)
		if not slash then
			table.remove(args, 1)
		end

		if interaction.replyDeferred then
			interaction:replyDeferred()
		end

		local config = sqldb:get(interaction.guild.id) or {}

        local server, err = ERLC:getServer(config.apikey)
        if not server then
            return interaction:fail("Failed to fetch server information: " .. (err or "Unknown"))
        end

		if subcmd == "panel" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then
				return
			elseif not sqldb:plusGuild(interaction.guild) then
				return interaction:fail("This is a " .. emojis.duckyplus .. " **Ducky Plus+** feature!")
			end

			local username = (slash and args and args.player) or ((not slash) and args and args[1] and args[1] ~= "" and args[1])
			if not username then
                return interaction:fail("You did not provide a player.")
            end

            local player = table.find(server.players, function(p)
                return p.name:lower():find(username:lower())
            end)
            if not player then
                return interaction:fail("That player is not in-game.")
            end

			username = player.name

			local roblox = ropi.SearchUser(player.name)
			if not roblox then
				return interaction:fail("That player could not be loaded.", nil, true)
			end

			local link = sqldb:getLink(player.id)
			local member = link and link.discord and interaction.guild:getMember(link.discord)

			local myLink = sqldb:getLink(interaction.user.id)
			local me = myLink and myLink.roblox and table.find(server.players, function(p)
				return p.id == myLink.roblox
			end)

			local panel = interaction:loading()

			local function updatePanel()
				player = table.find(server.players, function(p)
					return p.name:lower() == username:lower()
				end)

				me = myLink and myLink.roblox and table.find(server.players, function(p)
					return p.id == myLink.roblox
				end)
				
				if player then
					local regions = {}

					for _, r in pairs(config.regions or {}) do
						local Region = erlua.Region(r.name, r.points)
						if Region:contains(player.location) then
							table.insert(regions, r.name)
						end
					end
					
					local vehicle = table.find(server.vehicles, function(v)
						return v.owner and v.owner.id == player.id
					end)

					local options = {
						{
							label = "Reload Panel",
							description = "Reload the panel and update the player's information.",
							value = "reload",
							emoji = resolvedEmojis.reload
						},
						{
							label = "Punish",
							description = "Log a punishment on " .. player.name .. ".",
							value = "punish",
							emoji = resolvedEmojis.moderate
						},
						{
							label = "Private Message",
							description = "Send " .. player.name .. " a private message.",
							value = "pm",
							emoji = resolvedEmojis.mail
						},
						{
							label = "Refresh",
							description = "Refresh " .. player.name .. ".",
							value = "refresh",
							emoji = resolvedEmojis.cycle
						},
						{
							label = "Respawn",
							description = "Respawn " .. player.name .. ".",
							value = "respawn",
							emoji = resolvedEmojis.inspiration
						},
						{
							label = "Kill",
							description = "Kill " .. player.name .. ".",
							value = "kill",
							emoji = resolvedEmojis.swords
						}
					}

					if player.team ~= "Civilian" then
						table.insert(options, {
							label = "Teamkick",
							description = "Remove " .. player.name .. " from the " .. player.team .. " team.",
							value = "teamkick",
							emoji = resolvedEmojis.flag
						})
					end

					if me and me.id ~= player.id then
						table.insert(options, {
							label = "Go To",
							description = "Teleport yourself to " .. player.name .. ".",
							value = "to",
							emoji = resolvedEmojis.location
						})

						table.insert(options, {
							label = "Bring",
							description = "Teleport " .. player.name .. " to you.",
							value = "bring",
							emoji = resolvedEmojis.location
						})
					end

					if player.permission == erlua.enums.permission.normal then
						table.insert(options, {
							label = "Kick",
							description = "Kick " .. player.name .. " from the in-game server.",
							value = "kick",
							emoji = resolvedEmojis.warning
						})

						if (me and me.permission >= erlua.enums.permission.administrator) or hasPermission(interaction.member, "ERLC_ADMIN") then
							table.insert(options, {
								label = "Ban",
								description = "Ban " .. player.name .. " from the in-game server.",
								value = "ban",
								emoji = resolvedEmojis.error
							})
						end
					end
					
					return panel:update({
						embed = {
							author = author(interaction.guild),
							title = emojis.person .. " " .. player.name,
							description = emojis.right .. " **Player:** " .. player.hyperlink .. "\n"
							.. emojis.right .. " **Member:** " .. (member and (member.mentionString .. (member.voiceChannel and (" (" .. member.voiceChannel.mentionString .. ")") or "")) or emojis.fail) .. "\n"
							.. emojis.right .. " **Wanted:** " .. starMap[player.wantedStars or 0] .. "\n"
							.. emojis.right .. " **Permission:** " .. player._permission .. "\n"
							.. emojis.right .. " **Team:** " .. player.team .. (player.callsign and (" (`" .. player.callsign .. "`)") or "") .. "\n"
							.. emojis.right .. " **Vehicle:** " .. (vehicle and (vehicle.name .. " (`" .. vehicle.plate .. "`)") or emojis.fail) .. "\n"
							.. ((vehicle and vehicle.color and emojis.space .. emojis.right .. " **Color:** " .. vehicle.color .. "\n") or "")
							.. ((vehicle and player.team ~= "Civilian" and vehicle.livery and emojis.space .. emojis.right .. " **Livery:** " .. vehicle.livery .. "\n") or "")
							.. emojis.right .. " **Location:** " .. tostring(player.location or emojis.fail) .. "\n"
							.. (regions and next(regions) and (emojis.space .. emojis.right .. " **Region:** " .. table.concat(regions, ", ") .. "\n") or ""),
							thumbnail = {
								url = roblox.avatar
							},
							color = colors.yellow
						},
						components = discordia.Components()
							:selectMenu({
								id = "manage",
								placeholder = "Select an action...",
								options = options,
								max_values = 1
							})
							:raw()
					})
				else
					return panel:update({
						embed = {
							description = emojis.fail .. " This player is no longer in-game.",
							color = colors.fail
						},
						components = {}
					})
				end
			end

			updatePanel()

			local function execute(cmd, ia, onlyFail)
				local success, err = server:execute(cmd)
				if not success then
					ia:fail("The command could not be sent to the in-game server: " .. tostring(err), nil, true)
					return false, updatePanel()
				end

				db:send(interaction.guild, "erlccmdschannel", {
					embed = {
						author = author(interaction.user),
						title = emojis.person .. " Player Panel Usage",
						description = emojis.right .. " " .. getUserString(interaction.user) .. " executed the following command on " .. player.hyperlink .. ":\n```" .. cmd .. "```",
						color = colors.info,
						thumbnail = thumbnail(interaction.user)
					}
				})

				if not onlyFail then ia:success("The command has been successfully sent to the in-game server.", nil, true) end
				return true, updatePanel()
			end

			onComp(panel, nil, nil, interaction.user.id, false, function(ia)
				local id = ia.data.custom_id
				local values = ia.data.values
				local action = values and values[1]

				if action == "reload" then
					ia:updateDeferred(true)
					return updatePanel()
				elseif action == "punish" then
					local typeOptions = {}
					for _, type in pairs(config.punishmenttypes) do
						table.insert(typeOptions, {
							label = type,
							value = type,
							emoji = resolvedEmojis.moderate
						})
					end

					prompt(ia, "Punish Player", {
						{
							question = "What type should the punishment be of?",
							component = discordia.SelectMenu({
								id = "punishmenttype",
								placeholder = "Select a punishment type...",
								options = typeOptions,
								max_values = 1,
								required = true
							}):raw()
						},
						{
							question = "What should the punishment's reason be?",
							placeholder = "Enter a reason for the punishment...",
							style = "short",
							required = true
						}
					}, function(mia, responses)
						if mia then
							local type = responses and responses["What type should the punishment be of?"]
							local reason = responses and responses["What should the punishment's reason be?"]

							if (not type) or (type == "") then
								mia:fail("You did not provide a valid type for the punishment.", nil, true)
								return updatePanel()
							elseif (not reason) or (reason == "") then
								mia:fail("You did not provide a reason for the punishment.", nil, true)
								return updatePanel()
							end

							local punishment = db:punishmentCreate(interaction, interaction.member, roblox, type, reason)

							mia:reply({
								embed = {
									title = emojis.success .. " Punishment Logged",
									description = emojis.right .. " You have logged a punishment on **" .. roblox.hyperlink .. "**.\n" .. emojis.space .. emojis.right .. " **Moderator:** <@" .. punishment.moderator .. ">\n" .. emojis.space .. emojis.right .. " **Player:** " .. roblox.hyperlink .. "\n" .. emojis.space .. emojis.right .. " **Type:** " .. punishment.type .. "\n" .. emojis.space .. emojis.right .. " **Reason:** " .. punishment.reason .. ((punishment.evidence and "\n" .. emojis.space .. emojis.right .. " **Evidence:** [Attachment](" .. punishment.evidence .. ")") or "") .. ((punishment.expires and "\n" .. emojis.space .. emojis.right .. " **Expires:** <t:" .. punishment.expires .. "> (<t:" .. punishment.expires .. ":R>)") or "") .. "\n" .. emojis.space .. emojis.right .. " **ID:** `" .. punishment.id .. "`",
									color = colors.success,
									thumbnail = roblox.avatar and {
										url = roblox.avatar
									},
									author = author(interaction.member),
									image = (punishment.evidence and {
										url = punishment.evidence
									}) or nil
								}
							}, true)
							return updatePanel()
						end
					end)
				elseif action == "pm" then
					prompt(ia, "Send Private Message", {
						{
							question = "What should the message say?",
							placeholder = "Enter message content here...",
							style = "paragraph",
							required = true
						}
					}, function(mia, responses)
						if mia then
							local message = responses["What should the message say?"]
							if not message then
								mia:fail("You did not provide a message to send.", nil, true)
								return updatePanel()
							end

							return execute(":pm " .. player.name .. " " .. message, mia)
						end
					end)
				elseif action == "refresh" then
					return execute(":refresh " .. player.name, ia)
				elseif action == "respawn" then
					return execute(":respawn " .. player.name, ia)
				elseif action == "kill" then
					return execute(":kill " .. player.name, ia)
				elseif action == "teamkick" then
					ia:replyDeferred(true)
					if not execute(":wanted " .. player.name, ia, true) then return end
					return execute(":unwanted " .. player.name, ia)
				elseif action == "to" and me then
					return execute(":teleport " .. me.name .. " " .. player.name, ia)
				elseif action == "bring" and me then
					return execute(":teleport " .. player.name .. " " .. me.name, ia)
				elseif action == "kick" then
					prompt(ia, "Kick Player", {
						{
							question = "Why are you kicking this player?",
							placeholder = "Enter a kick reason...",
							style = "short",
							required = false
						}
					}, function(mia, responses)
						if mia then
							local reason = responses["Why are you kicking this player?"]
							if not reason then
								mia:fail("You did not provide a reason for this kick.", nil, true)
								return updatePanel()
							end

							db:punishmentCreate(interaction, interaction.member, roblox, "Kick", reason)
							return execute(":kick " .. player.name .. " " .. reason, mia)
						end
					end)
				elseif action == "ban" then
					prompt(ia, "Ban Player", {
						{
							question = "Why are you banning this player?",
							placeholder = "Enter a ban reason...",
							style = "short",
							required = false
						}
					}, function(mia, responses)
						if mia then
							local reason = responses["Why are you banning this player?"]
							if not reason then
								mia:fail("You did not provide a reason for this ban.", nil, true)
								return updatePanel()
							end

							db:punishmentCreate(interaction, interaction.member, roblox, "Ban", reason)
							return execute(":ban " .. player.name .. " " .. reason, mia)
						end
					end)
				else
					return ia:warning("This feature is still under development. Please check back later.", nil, true)
				end
			end)
		elseif subcmd == "players" or subcmd == "plrs" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end

			local teamQuery = (args and args.team and args.team:lower()) or (args and args[1] and args[1]:lower())
			local team = teamQuery and teams[teamQuery]
			if teamQuery and not team then
				return interaction:fail("The team name you provided is invalid.", nil, true)
			end

			local players = {}
			for _, p in pairs(server.players) do
				if (team and p.team == team) or (not team) then
					table.insert(players, p)
				end
			end

			if #players <= 0 then
				return interaction:fail((team and "There are no players on the **" .. team .. "** team.") or "There are no players in-game.")
			end

			local pages = {}
			local page

			local function resetPage()
				page = {
					author = author(interaction.guild),
					title = emojis.people .. " Server Players (" .. #server.players .. "/" .. server.maxPlayercount .. ")",
					description = "",
					color = colors.yellow,
					onpage = 0
				}
			end

			resetPage()

			table.sort(players, function(a, b)
				return a.permission > b.permission
			end)

			for i, player in pairs(players) do
				local icon = emojis.person
				if player.permission == erlua.enums.permission.owner then
					icon = emojis.executive
				elseif player.permission == erlua.enums.permission.coOwner then
					icon = emojis.settings
				elseif player.permission == erlua.enums.permission.administrator then
					icon = emojis.quickfix
				elseif player.permission == erlua.enums.permission.moderator then
					icon = emojis.moderate
				elseif player.permission == erlua.enums.permission.helper then
					icon = emojis.support
				end
				page.onpage = page.onpage + 1
				page.description = page.description .. icon .. " " .. player.hyperlink .. " ・ " .. player.team .. ((player.callsign and " ・ `" .. player.callsign .. "`") or "") .. "\n"

				if i >= #players or page.onpage >= 30 then
					table.insert(pages, page)
					resetPage()
				end
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		elseif subcmd == "staff" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end

			local staff = {}
			for k, v in pairs(server.players) do
				if v.permission ~= erlua.enums.permission.normal then
					table.insert(staff, v)
				end
			end

			if #staff <= 0 then
				return interaction:fail("There are no staff members in-game.")
			end
			
			local pages = {}
			local page

			local function resetPage()
				page = {
					author = author(interaction.guild),
					title = emojis.people .. " Server Staff (" .. #staff .. ")",
					description = "",
					color = colors.yellow,
					onpage = 0
				}
			end

			resetPage()

			table.sort(staff, function(a, b)
				return a.permission > b.permission
			end)

			for i, player in pairs(staff) do
				local icon = emojis.person
				if player.permission == erlua.enums.permission.owner then
					icon = emojis.executive
				elseif player.permission == erlua.enums.permission.coOwner then
					icon = emojis.settings
				elseif player.permission == erlua.enums.permission.administrator then
					icon = emojis.quickfix
				elseif player.permission == erlua.enums.permission.moderator then
					icon = emojis.moderate
				elseif player.permission == erlua.enums.permission.helper then
					icon = emojis.support
				end
				page.onpage = page.onpage + 1
				page.description = page.description .. icon .. " " .. player.hyperlink .. " ・ " .. player.team .. ((player.callsign and " ・ `" .. player.callsign .. "`") or "") .. "\n"

				if i >= #staff or page.onpage >= 30 then
					table.insert(pages, page)
					resetPage()
				end
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		elseif subcmd == "server" or subcmd == "info" or subcmd == "information" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end
			
			local ids = {}
			table.insert(ids, server.owner)
			for _, id in pairs(server.coOwners) do
				table.insert(ids, id)
			end

			local owners = ropi.GetUsers(ids, {dictionary = true, fillUnknown = true})

			local staff = {}
			for k, v in pairs(server.players) do
				if v.permission ~= erlua.enums.permission.normal then
					table.insert(staff, v)
				end
			end

			return interaction:reply({
				embed = {
					author = author(interaction.guild),
					title = emojis.game .. " " .. server.name,
					description = emojis.settings .. " **Server Information:**\n"
					.. emojis.space .. emojis.right .. " **Join Code:** " .. server.joinCode .. "\n"
					.. emojis.space .. emojis.right .. " **Players:** " .. #server.players .. "/" .. server.maxPlayercount .. " (" .. #server.queue .. " in queue)\n"
					.. emojis.space .. emojis.right .. " **Staff:** " .. #staff .. "\n"
					.. emojis.space .. emojis.right .. " **Vehicles:** " .. #server.vehicles .. "\n"
					.. emojis.executive .. " **Ownership:**\n"
					.. emojis.space .. emojis.right .. " **Owner:** " .. owners[server.owner].hyperlink .. "\n"
					.. emojis.space .. emojis.right .. " **Co-Owners:** " .. ((server.coOwners and next(server.coOwners) and table.concatFn(server.coOwners, ", ", function(id)
						return owners[id] and owners[id].hyperlink or tostring(id)
					end)) or emojis.fail) .. "\n"
					.. emojis.settings .. " **Settings:**\n"
					.. emojis.space .. emojis.right .. " **Team Balance:** " .. (server.teamBalance and emojis.success or emojis.fail) .. "\n"
					.. emojis.space .. emojis.right .. " **Verification Level:** " .. (server.verificationLevel == "Disabled" and emojis.fail or server.verificationLevel) .. "\n"
					.. ((server._last_updated and "-# " .. emojis.clock .. " **Last Updated:** <t:" .. math.round(server._last_updated) .. ":T> (<t:" .. math.round(server._last_updated) .. ":R>)") or ""),
					color = colors.yellow
				},
				components = discordia.Components()
					:button({
						url = "https://erlc.gg/join/" .. server.joinCode,
						style = "link",
						label = "Join Server",
						emoji = resolvedEmojis.game
					})
					:raw()
			})
		elseif subcmd == "check" or subcmd == "discord" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end

			if #server.players <= 0 then
				return interaction:fail("There are no players in-game.")
			end

			loadMembers(interaction.guild)

			for k, v in pairs(server.players) do
				if not v._member then
					local link = sqldb:getLink(v.id)
					local member = link and interaction.guild:getMember(link.discord)
					if not member then
						for _, m in pairs(interaction.guild.members) do
							if m.name:lower():find(v.name:lower()) or m.username:lower():find(v.name:lower()) then
								member = m
								break
							end
						end
					end

					v._link = not not link
					v._member = member
				end
			end

			local pages = {}
			local page

			local function resetPage()
				page = {
					author = author(interaction.guild),
					title = emojis.people .. " Server Players (" .. #server.players .. "/" .. server.maxPlayercount .. ")",
					description = "",
					color = colors.yellow,
					onpage = 0
				}
			end

			resetPage()

			table.sort(server.players, function(a, b)
				return ((a._member and a._member.premiumSince and 3) or (a._member and 2) or 1) > ((b._member and b._member.premiumSince and 3) or (b._member and 2) or 1)
			end)

			for i, player in pairs(server.players) do
				local icon = emojis.fail
				if player._member and player._member.premiumSince then
					icon = emojis.boosting
				elseif player._member then
					icon = emojis.success
				end
				page.onpage = page.onpage + 1
				page.description = page.description .. icon .. " " .. player.hyperlink .. " ・ " .. player.team .. ((player.callsign and " ・ `" .. player.callsign .. "`") or "") .. ((player._member and player._member.voiceChannel and " ・ " .. player._member.voiceChannel.mentionString) or "") .. "\n"

				if i >= #server.players or page.onpage >= 30 then
					table.insert(pages, page)
					resetPage()
				end
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		elseif subcmd == "queue" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end

			if table.count(server.queue) <= 0 then
				return interaction:fail("There are no players in the queue.")
			end

			local pages = {}
			local page

			local function resetPage()
				page = {
					author = author(interaction.guild),
					title = emojis.list .. " Server Queue (" .. table.count(server.queue) .. ")",
					description = "",
					color = colors.yellow,
					onpage = 0
				}
			end

			resetPage()

			local players = ropi.GetUsers(server.queue, {dictionary = true, fillUnknown = true})

			for i, id in pairs(server.queue) do
				local player = players[id]
				page.onpage = page.onpage + 1
				page.description = page.description .. emojis.right .. " **" .. i .. ".** " .. player.hyperlink .. "\n"

				if i >= table.count(server.queue) or page.onpage >= 30 then
					table.insert(pages, page)
					resetPage()
				end
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		elseif subcmd == "vehicles" or subcmd == "cars" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end

			if #server.vehicles <= 0 then
				return interaction:fail("There are no vehicles spawned in the server.")
			end

			local pages = {}
			local page

			local function resetPage()
				page = {
					author = author(interaction.guild),
					title = emojis.vehicle .. " Server Vehicles (" .. #server.vehicles .. ")",
					description = "",
					color = colors.yellow,
					onpage = 0
				}
			end

			resetPage()

			for i, vehicle in pairs(server.vehicles) do
				page.onpage = page.onpage + 1
				page.description = page.description .. emojis.right .. " " .. vehicle.owner.hyperlink .. " ・ " .. vehicle.name .. " (`" .. vehicle.plate .. "`)" .. ((vehicle.color and " ・ " .. vehicle.color) or "") .. ((vehicle.livery and vehicle.owner.team ~= "Civilian" and " ・ " .. vehicle.livery) or "") .. "\n"

				if i >= #server.vehicles or page.onpage >= 15 then
					table.insert(pages, page)
					resetPage()
				end
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		elseif subcmd == "kills" or subcmd == "kl" or subcmd == "killlogs" or subcmd == "kls" or subcmd == "kill" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end

			if #server.killLogs <= 0 then
				return interaction:fail("There are no kill logs in the server.")
			end

			local pages = {}
			local page

			local function resetPage()
				page = {
					author = author(interaction.guild),
					title = emojis.swords .. " Server Kill Logs (" .. #server.killLogs .. ")",
					description = "",
					color = colors.yellow,
					onpage = 0
				}
			end

			resetPage()

			for i, log in pairs(server.killLogs) do
				page.onpage = page.onpage + 1
				page.description = page.description .. emojis.right .. " <t:" .. log.timestamp .. ":T> ・ " .. log.killer.hyperlink .. " killed " .. log.killed.hyperlink .. "\n"

				if i >= #server.killLogs or page.onpage >= 15 then
					table.insert(pages, page)
					resetPage()
				end
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		elseif subcmd == "logs" or subcmd == "commands" or subcmd == "cmds" or subcmd == "cmdlogs" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end

			if #server.commandLogs <= 0 then
				return interaction:fail("There are no command logs in the server.")
			end

			local pages = {}
			local page

			local function resetPage()
				page = {
					author = author(interaction.guild),
					title = emojis.support .. " Server Command Logs (" .. #server.commandLogs .. ")",
					description = "",
					color = colors.yellow,
					onpage = 0
				}
			end

			resetPage()

			for i, log in pairs(server.commandLogs) do
				page.onpage = page.onpage + 1
				page.description = page.description .. emojis.right .. " <t:" .. log.timestamp .. ":T> ・ [" .. log.player.name .. "](" .. (log.player.id == 0 and "https://apidocs.erlc.gg/api-reference/run-a-command-in-game-as-virtual-server-management" or "https://roblox.com/users/" .. log.player.id .. "/profile") .. ") executed `" .. log.command:gsub("`", "\\`") .. "`\n"

				if i >= #server.commandLogs or page.onpage >= 15 then
					table.insert(pages, page)
					resetPage()
				end
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		elseif subcmd == "modcalls" or subcmd == "mcs" or subcmd == "modcall" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end

			if #server.modCalls <= 0 then
				return interaction:fail("There are no mod calls in the server.")
			end

			local pages = {}
			local page

			local function resetPage()
				page = {
					author = author(interaction.guild),
					title = emojis.modcall .. " Server Modcalls (" .. #server.modCalls .. ")",
					description = "",
					color = colors.yellow,
					onpage = 0
				}
			end

			resetPage()

			for i, log in pairs(server.modCalls) do
				page.onpage = page.onpage + 1
				if log.moderator then
					page.description = page.description .. emojis.success .. " <t:" .. log.timestamp .. ":T> ・ " .. log.moderator.hyperlink .. " answered " .. log.caller.hyperlink .. "'s modcall\n"
				else
					page.description = page.description .. (os.time() - log.timestamp <= 900 and emojis.loading or emojis.success) .. " <t:" .. log.timestamp .. ":T> ・ " .. log.caller.hyperlink .. " called !mod\n"
				end

				if i >= #server.modCalls or page.onpage >= 15 then
					table.insert(pages, page)
					resetPage()
				end
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		elseif subcmd == "emergencies" or subcmd == "emgs" or subcmd == "emergencycalls" or subcmd == "calls" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end

			local teamQuery = (args and args.team and args.team:lower()) or (args and args[1] and args[1]:lower())
			local team = teamQuery and teams[teamQuery]
			if teamQuery and not team then
				return interaction:fail("The team name you provided is invalid.", nil, true)
			end

			local calls = {}
			for _, c in pairs(server.emergencyCalls) do
				if (team and c.team == team) or (not team) then
					table.insert(calls, c)
				end
			end

			if #calls <= 0 then
				return interaction:fail((team and "There are no active emergencies for the **" .. team .. "** team.") or "There are no active emergencies.")
			end

			local pages = {}
			local page

			local function resetPage()
				page = {
					author = author(interaction.guild),
					title = emojis.modcall .. " Server Emergencies (" .. #server.emergencyCalls .. ")",
					description = "",
					color = colors.yellow,
					onpage = 0
				}
			end

			resetPage()

			for i, call in pairs(calls) do
				page.onpage = page.onpage + 1
				page.description = page.description .. emojis[call.team or "modcall"] .. " **Call #" .. call.number .. ":** " .. (call.caller and call.caller.hyperlink or "Server") .. " called " .. call.team .. " at <t:" .. call.timestamp .. ":T>: " .. call.description .. "\n" .. ((call.responders and next(call.responders) and "-# " .. emojis.people .. " **Responders:** " .. table.concatFn(call.responders, ", ", function(id)
					local responder = server:getPlayer(id)
					return (responder and responder.callsign and ("[" .. responder.callsign .. "] " .. responder.hyperlink)) or ""
				end) .. "\n") or "")

				if i >= #calls or page.onpage >= 15 then
					table.insert(pages, page)
					resetPage()
				end
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		elseif subcmd == "joins" or subcmd == "leaves" or subcmd == "joinlogs" or subcmd == "leavelogs" or subcmd == "playerlogs" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end

			if #server.joinLogs <= 0 then
				return interaction:fail("There are no join logs in the server.")
			end

			local pages = {}
			local page

			local function resetPage()
				page = {
					author = author(interaction.guild),
					title = emojis.list .. " Server Join Logs (" .. #server.joinLogs .. ")",
					description = "",
					color = colors.yellow,
					onpage = 0
				}
			end

			resetPage()

			for i, log in pairs(server.joinLogs) do
				page.onpage = page.onpage + 1
				page.description = page.description .. (log.type == erlua.enums.joinLogType.join and emojis.add or emojis.subtract) .. " <t:" .. log.timestamp .. ":T> ・ " .. log.player.hyperlink .. " " .. (log.type == erlua.enums.joinLogType.join and "joined" or "left") .. " the server\n"

				if i >= #server.joinLogs or page.onpage >= 30 then
					table.insert(pages, page)
					resetPage()
				end
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		elseif subcmd == "bans" or subcmd == "banlist" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end
			
			local bans, err = ERLC._api:getServerBans(config.apikey) -- TODO: implement properly into erlua Server class
			if not bans then
				return interaction:fail(err, nil, true)
			end

			if table.count(bans) <= 0 then
				return interaction:fail("There are no bans in the server.")
			end

			local pages = {}
			local page

			local function resetPage()
				page = {
					author = author(interaction.guild),
					title = emojis.moderate .. " Server Bans (" .. table.count(bans) .. ")",
					description = "",
					color = colors.yellow,
					onpage = 0
				}
			end

			resetPage()

			local i = 0
			for id, name in pairs(bans) do
				i = i + 1
				page.onpage = page.onpage + 1
				page.description = page.description .. emojis.person .. " [" .. name .. "](https://roblox.com/users/" .. id .. "/profile)\n"

				if i >= table.count(bans) or page.onpage >= 30 then
					table.insert(pages, page)
					resetPage()
				end
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		elseif subcmd == "permissions" or subcmd == "perms" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end

			local permissions = {}

			for category, players in pairs(server.staff) do
				for id, name in pairs(players) do
					table.insert(permissions, {
						permission = (category == "Admins" and erlua.enums.permission.administrator) or (category == "Mods" and erlua.enums.permission.moderator) or (category == "Helpers" and erlua.enums.permission.helper),
						name = name,
						id = id
					})
				end
			end

			local ids = {}
			table.insert(ids, server.owner)
			for _, id in pairs(server.coOwners) do
				table.insert(ids, id)
			end

			local owners = ropi.GetUsers(ids, {dictionary = true, fillUnknown = true})

			for _, owner in pairs(owners) do
				table.insert(permissions, {
					permission = owner.id == server.owner and erlua.enums.permission.owner or erlua.enums.permission.coOwner,
					name = owner.name,
					id = owner.id
				})
			end

			if #permissions <= 0 then
				return interaction:fail("There are no permissions in the server.")
			end

			local pages = {}
			local page

			local function resetPage()
				page = {
					author = author(interaction.guild),
					title = emojis.permission .. " Server Permissions",
					description = "",
					color = colors.yellow,
					onpage = 0
				}
			end

			resetPage()

			table.sort(permissions, function(a, b)
				return a.permission > b.permission
			end)

			for i, player in pairs(permissions) do
				local icon = emojis.support
				if player.permission == erlua.enums.permission.owner then
					icon = emojis.executive
				elseif player.permission == erlua.enums.permission.coOwner then
					icon = emojis.settings
				elseif player.permission == erlua.enums.permission.administrator then
					icon = emojis.quickfix
				elseif player.permission == erlua.enums.permission.moderator then
					icon = emojis.moderate
				end
				
				page.onpage = page.onpage + 1
				page.description = page.description .. icon .. " [" .. player.name .. "](https://roblox.com/users/" .. player.id .. "/profile)\n"

				if i >= #permissions or page.onpage >= 30 then
					table.insert(pages, page)
					resetPage()
				end
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true,
				showTotalPages = true
			})
		elseif subcmd == "execute" or subcmd == "command" or subcmd == "cmd" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end
			if (not config.advancederlccmdperms) and (not hasPermission(interaction.member, "ERLC_MANAGER", config, interaction)) then return end

			local command = (slash and args and args.command) or ((not slash) and args and table.concat(args, " "))
			command = command and (command ~= "") and ":" .. command:gsub("^:", "")
			
			if (not command) or (command == "") then
				return interaction:fail("You did not provide a command to execute.", nil, true)
			elseif not remoteInGameCommands[command:usub(2):split(" ")[1]] then
				return interaction:fail("That command does not exist or cannot be executed by Remote Server Management.", nil, true)
			elseif not hasPermission(interaction.member, remoteInGameCommands[command:usub(2):split(" ")[1]], config, interaction) then
				return
			end

			if #server.players > 0 then
				local success, err = server:execute(command)
				if not success then
					return interaction:fail(err, nil, true)
				end

				db:send(interaction.guild, "erlccmdschannel", {
					embed = {
						author = author(interaction.user),
						title = emojis.settings .. " Remote Command Executed",
						description = emojis.right .. " " .. getUserString(interaction.user) .. " executed the following command via Remote Server Management:\n```" .. command .. "```",
						color = colors.info,
						thumbnail = thumbnail(interaction.user)

					}
				})

				return interaction:success("The **`" .. command .. "`** command has been executed within the in-game server.")
			else
				local plus = sqldb:plusGuild(interaction.guild)
				if not plus then
					return interaction:fail("The in-game server is offline, therefore commands cannot be executed.", nil, true)
				end

				local success, err = db:commandQueueInsert(interaction.guild, command, interaction.member)
				if not success then
					return interaction:fail(err, nil, true)
				end

				return interaction:success("The **`" .. command .. "`** command has been queued for execution when the server comes online.")
			end
		elseif subcmd == "tempban" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end

			local hasERLCADMIN = hasPermission(interaction.member, "ERLC_ADMIN", config, interaction)
			if (not config.tempbantimemods) and (not hasERLCADMIN) then return end

			local username = (slash and args and args.player) or ((not slash) and args and args[1])
			username = username and username ~= "" and username
			if not username then
				return interaction:fail("You did not provide a player to tempban.", nil, true)
			end

			local player = ropi.SearchUser(username)
			if not player then
				return interaction:fail("That player was not found.", nil, true)
			end

			local duration = (slash and args and args.duration) or ((not slash) and args and args[2])
			duration = duration and duration ~= "" and convert(duration, true)
			if not duration then
				return interaction:fail("You did not provide a valid duration for this tempban.", nil, true)
			elseif not hasERLCADMIN and config.tempbantimemods and (duration > config.tempbantimemods) then
				return interaction:fail("You can tempban players for no longer than **" .. readable(config.tempbantimemods) .. "**.", nil, true)
			end

			local expires = duration and (os.time() + duration)

			local reason = (slash and args and args.reason) or ((not slash) and args and table.concat(args, " ", 3))
			reason = reason and reason ~= "" and reason
			if not reason then
				return interaction:fail("You did not provide a reason for this tempban.", nil, true)
			end

			config.erlctempbans = config.erlctempbans or {}

			local existing = config.erlctempbans[tostring(player.id)]
			if existing then
				return interaction:fail("That player is already temporarily banned from the in-game server until <t:" .. existing.expires .. "> (<t:" .. existing.expires .. ":R>).", nil, true)
			end

			if #server.players > 0 then
				local success, err = server:execute(":ban " .. player.id)
				if not success then
					return interaction:fail(err, nil, true)
				end
			else
				local plus = sqldb:plusGuild(interaction.guild)
				if not plus then
					return interaction:fail("The in-game server is offline, therefore commands cannot be executed.", nil, true)
				end

				local success, err = db:commandQueueInsert(interaction.guild, ":ban " .. player.id, interaction.member)
				if not success then
					return interaction:fail(err, nil, true)
				end
			end

			local punishment = db:punishmentCreate(interaction, interaction.member, player, "Tempban", reason, nil, expires)

			if not punishment then
				config.erlctempbans[tostring(player.id)] = {
					expires = expires,
					userid = player.id
				}

				sqldb:set(interaction.guild.id, {
					erlctempbans = config.erlctempbans
				}, "ERLC_TEMPBAN_ADD")

				return interaction:fail("The punishment could not be logged, however the tempban was still successful.", nil, true)
			end

			config.erlctempbans[tostring(player.id)] = {
				expires = expires,
				userid = tostring(player.id),
				punishmentid = punishment.id
			}

			sqldb:set(interaction.guild.id, {
				erlctempbans = config.erlctempbans
			}, "ERLC_TEMPBAN_ADD")

			return interaction:reply({
				embed = {
					author = author(interaction.member),
					title = emojis.success .. " Tempban Logged",
					description = emojis.right .. " You have logged a tempban on **" .. player.hyperlink .. "**.\n"
					.. emojis.space .. emojis.right .. " **Moderator:** " .. interaction.member.mentionString .. "\n"
					.. emojis.space .. emojis.right .. " **Player:** " .. player.hyperlink .. "\n"
					.. emojis.space .. emojis.right .. " **Reason:** " .. reason .. "\n"
					.. emojis.space .. emojis.right .. " **Expires:** <t:" .. expires .. "> (<t:" .. expires .. ":R>)",
					color = colors.success
				}
			})
		elseif subcmd == "untempban" then
			if not hasPermission(interaction.member, "ERLC_ADMIN", config, interaction) then return end

			local username = (slash and args and args.player) or ((not slash) and args and args[1])
			username = username and username ~= "" and username
			if not username then
				return interaction:fail("You did not provide a player to tempban.", nil, true)
			end

			local player = ropi.SearchUser(username)
			if not player then
				return interaction:fail("That player was not found.", nil, true)
			end

			local reason = (slash and args and args.reason) or ((not slash) and args and table.concat(args, " ", 2))
			reason = reason and reason ~= "" and reason
			if not reason then
				return interaction:fail("You did not provide a reason for removing this tempban.", nil, true)
			end

			config.erlctempbans = config.erlctempbans or {}

			local existing = config.erlctempbans[tostring(player.id)]
			if not existing then
				return interaction:fail("That player is not temporarily banned from the in-game server.", nil, true)
			end

			if #server.players > 0 then
				local success, err = server:execute(":unban " .. player.id)
				if not success then
					return interaction:fail(err, nil, true)
				end
			else
				local plus = sqldb:plusGuild(interaction.guild)
				if not plus then
					return interaction:fail("The in-game server is offline, therefore commands cannot be executed.", nil, true)
				end

				local success, err = db:commandQueueInsert(interaction.guild, ":unban " .. player.id, interaction.member)
				if not success then
					return interaction:fail(err, nil, true)
				end
			end

			config.erlctempbans[tostring(player.id)] = nil

			sqldb:set(interaction.guild.id, {
				erlctempbans = config.erlctempbans
			}, "ERLC_TEMPBAN_REMOVE")

			local link = sqldb:getLink(player.id)
			local member = link and interaction.guild:getMember(link.discord)
			if member then
				member:success("Your tempban in **" .. interaction.guild.name .. "** has been removed and you have been unbanned for **" .. reason .. "**.")
			end

			return interaction:success("**" .. player.hyperlink .. "**'s tempban has been removed, and they have been unbanned from the in-game server.")
		elseif subcmd == "playtime" then
			local playtime = {}

			for user, settings in pairs(sqldb.cache and sqldb.cache.user_settings or {}) do
				if settings.trackplaytime ~= false and settings.playsessions then
					for _, playsession in pairs(settings.playsessions) do
						if playsession.discord == interaction.guild.id then
							playtime[user] = playtime[user] or {}
							playtime[user].playtime = (playtime[user].playtime or 0) + ((playsession.ended or os.time()) - playsession.started)
							playtime[user].playsessions = (playtime[user].playsessions or 0) + 1
						end
					end
				end
			end

			if table.count(playtime) <= 0 then
				return interaction:fail("There are no players with playtime in this server.", nil, true)
			end

			local leaderboard = {}

			for id, data in pairs(playtime) do
				local level

				if config.erlcplaytimerewards then
					for _, reward in pairs(config.erlcplaytimerewards) do
						if data.playtime >= reward.playtime and reward.playtime > ((level and level.playtime) or 0) then
							level = {
								role = reward.role,
								playtime = reward.playtime
							}
						end
					end
				end

				table.insert(leaderboard, {
					member = id,
					playtime = data.playtime,
					playsessions = data.playsessions,
					level = level
				})
			end

			table.sort(leaderboard, function(a, b)
				return a.playtime > b.playtime
			end)

			local pages = {}
			local page, onPage

			local function resetPage()
				page = {
					title = emojis.game .. " Playtime Leaderboard",
					description = emojis.right .. " You have accumulated a total of **" .. readable((playtime[interaction.user.id] or {}).playtime or 0) .. "** of playtime on this server.",
					color = colors.yellow,
					author = author(interaction.guild)
				}
				onPage = 0
			end
			
			resetPage()

			for index, data in pairs(leaderboard) do
				onPage = onPage + 1
				page.description = page.description .. "\n**" .. index .. ".** <@" .. data.member .. ">" .. ((data.level and (" (<@&" .. data.level.role .. ">)")) or "") .. "・" .. readable(data.playtime)
				if index >= #leaderboard or onPage >= 25 then
					table.insert(pages, page)
					resetPage()
				end
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				teleport = true
			})
		elseif subcmd == "locate" or subcmd == "location" then
			if not hasPermission(interaction.member, "ERLC_STAFF", config, interaction) then return end

			local username = (slash and args and args.player) or ((not slash) and args and args[1])
			username = username and username ~= "" and username
			if not username then
				return interaction:fail("You did not provide a player to locate.", nil, true)
			end

			local player = (server and table.find(server.players, function(p)
				return p.name:lower():find(username:lower())
			end))
			if not player then
				return interaction:fail("You did not provide a valid player.", nil, true)
			end

			local regions = {}

			for _, r in pairs(config.regions or {}) do
				local Region = erlua.Region(r.name, r.points)
				if Region:contains(player.location) then
					table.insert(regions, r.name)
				end
			end

			return interaction:reply({
				embed = {
					title = emojis.map .. " " .. player.name .. "'s Location",
					description = emojis.right .. " **Postal Code:** " .. player.location.postal .. "\n"
						.. emojis.right .. " **Street Name:** " .. player.location.street .. "\n"
						.. emojis.right .. " **Building Number:** " .. player.location.building .. "\n"
						.. emojis.right .. " **Region:** " .. (regions and next(regions) and table.concat(regions, ", ") or emojis.fail) .. "\n"
						.. "-# " .. emojis.right .. " **Coordinates:** " .. math.round(player.location.x) .. ", " .. math.round(player.location.z),
					color = colors.yellow
				}
			}, true)
		end
	end
}
