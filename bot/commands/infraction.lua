-- infraction.lua

local slashCommand = tools.slashCommand("infraction", "Use Ducky's infraction system.")
local subCommand = tools.subCommand("issue", "Issue an infraction.")
subCommand = subCommand:addOption(tools.user("user", "The user to infract."):setRequired(true))
subCommand = subCommand:addOption(tools.string("type", "The infraction type."):setRequired(true):setAutocomplete(true))
subCommand = subCommand:addOption(tools.string("reason", "The reason for this infraction."):setRequired(true))
subCommand = subCommand:addOption(tools.string("notes", "Additional notes for this infraction."):setRequired(false))
subCommand = subCommand:addOption(tools.string("expires", "Expiration time for this infraction. (3d, 1w, 4w)"):setRequired(false))
slashCommand = slashCommand:addOption(subCommand)
local subCommand = tools.subCommand("list", "List all infractions on a user.")
subCommand = subCommand:addOption(tools.user("user", "The user list infractions on."):setRequired(true))
slashCommand = slashCommand:addOption(subCommand)
local subCommand = tools.subCommand("revoke", "Revoke an infraction.")
subCommand = subCommand:addOption(tools.string("id", "The infraction ID to revoke."):setRequired(true))
slashCommand = slashCommand:addOption(subCommand)
local subCommand = tools.subCommand("manage", "Manage an infraction.")
subCommand = subCommand:addOption(tools.string("id", "The infraction ID to manage."):setRequired(true))
slashCommand = slashCommand:addOption(subCommand)

return {
    name = "infraction",
    description = "Use Ducky's infraction system.",
    aliases = {"infract", "infractions"},
    category = "Staff Management",
    slashCommand = slashCommand,
    requiredPermissions = {"ERLC_MANAGER", "SETUP"},
    subcommands = {
        "issue",
        "list",
        "revoke",
        "manage"
    },
    autocomplete = function(interaction, command, focused, args)
		local opts = {}
		if (focused) and (focused.name == "type") then
			local config = sqldb:get(interaction.guild.id)

			if config and config.infractiontypes then
				for i, v in ipairs(config.infractiontypes) do
                    if (focused.value and v.name:lower():find(focused.value:lower())) or (not focused.value) or (focused.value == "") then
                        table.insert(opts, {
                            name = v.name,
                            value = tostring(i)
                        })
                    end
                end
			end
		end

		return interaction:autocomplete(opts)
	end,
    hybridCallback = function(interaction, args, slash, subcmd)
        local guild = interaction.guild

        if (not slash) and subcmd then
            table.remove(args, 1)
        end

        if interaction.replyDeferred then interaction:replyDeferred(false) end

        local config = sqldb:get(guild.id) or {}

        if subcmd == "issue" then
            if not next(config.infractiontypes or {}) then
                return interaction:fail("No infraction types have been configured for this server.", nil, true)
            end

            local member = fetchMemberFromInteraction(interaction, args, slash)

            if not member then
                return interaction:fail("You must provide a staff member to infract.", nil, true)
            end

            local infractionTypeInput = (slash and args.type) or args[2]
            if not infractionTypeInput then
                return interaction:fail("You must provide an infraction type.", nil, true)
            end

            local infractionType
            local inputNumber = tonumber(infractionTypeInput)
            for i, it in ipairs(config.infractiontypes) do
                if inputNumber and inputNumber == i then
                    infractionType = it
                    break
                elseif not inputNumber and it.name:lower():find(infractionTypeInput:lower()) then
                    infractionType = it
                end
            end

            if not infractionType then
                return interaction:fail("I could not find that infraction type.", nil, true)
            end

            local reason = (slash and args.reason) or ((not slash) and table.remove(args, 1) and table.remove(args, 1) and table.concat(args, " "))

            if (not reason) or (reason == "") then
                return interaction:fail("You must provide a reason for this infraction.", nil, true)
            end

            local notes = (slash and args.notes)
            local expires = (slash and args.expires and convert(args.expires))

            local s, e = db:infract(member, infractionType, reason, interaction.member, notes, expires, interaction)

            if s then
                return interaction:success("**" .. member.name .. "** has received an infraction" .. ((expires and (", and it will expire in **" .. readable(expires) .. "** (<t:" .. (os.time() + expires) .. ">). ")) or ". ") .. e, nil, true)
            elseif s == nil then
                return interaction:fail(e or "An unknown error occurred. Please try again later.", nil, true)
            end
        elseif subcmd == "list" then
            local member = fetchMemberFromInteraction(interaction, args, slash)

            member = member or interaction.member

            local infractions = {}

            for i, v in pairs(config.infractions or {}) do
                if v.user == member.id then
                    table.insert(infractions, v)
                end
            end

            local pages = {}

            local emb = {
                author = {
                    name = "@" .. member.user.username,
                    icon_url = member.user.avatarURL
                },
                title = member.name .. "'s Infractions",
                color = colors.info,
                fields = {}
            }

            if #infractions <= 0 then
                return interaction:fail("**" .. member.name .. "** has no infractions.", nil, true)
            end

            table.sort(infractions, function(a, b)
                return a.timestamp > b.timestamp
            end)

            for i, infraction in pairs(infractions) do
                table.insert(emb.fields, {
                    name = infraction.type,
                    value = emojis.right .. " **Issuer:** <@" .. infraction.issuer .. ">\n" .. emojis.right .. " **Reason:** " .. ((infraction.reason and string.truncate(infraction.reason, 500)) or emojis.fail) .. "\n" .. emojis.right .. " **Notes:** " .. ((infraction.notes and string.truncate(infraction.notes, 500)) or emojis.fail) .. "\n" .. emojis.right .. " **Expires:** " .. ((infraction.expires and ("<t:" .. infraction.expires .. ">")) or emojis.fail) .. "\n" .. emojis.right .. " **Date:** <t:" .. infraction.timestamp .. ">\n-# " .. emojis.right .. " **Infraction ID:** `" .. infraction.id .. "`"
                })

                if #emb.fields >= 5 or i >= #infractions then
                    table.insert(pages, emb)
                    emb = {
                        author = {
                            name = "@" .. member.user.username,
                            icon_url = member.user.avatarURL
                        },
                        title = member.name .. "'s Infractions",
                        description = "",
                        color = colors.info,
                        fields = {}
                    }
                end
            end

            return _G.paginate(interaction, pages, interaction.user, {teleport = true, showTotalPages = true, clamp = false})

        elseif subcmd == "revoke" then
            local infractionID = (slash and args and args.id and args.id) or ((not slash) and args[1] and args[1])
            if not infractionID then
                return interaction:fail("You must provide the ID of the infraction to revoke.", nil, true)
            end

            local infractions = config.infractions or {}
            local targetIndex
            local targetInfraction

            for i, infraction in ipairs(infractions) do
                if tostring(infraction.id) == tostring(infractionID) then
                    targetIndex = i
                    targetInfraction = infraction
                    break
                end
            end

            if not targetInfraction then
                return interaction:fail("An infraction with the ID of `" .. infractionID .. "` was not found.", nil, true)
            end

            table.remove(config.infractions, targetIndex)
            sqldb:set(guild.id, {infractions = config.infractions}, "INFRACTION_REVOKE")

            local member = guild:getMember(targetInfraction.user) or Client:getUser(targetInfraction.user)
            local issuer = guild:getMember(targetInfraction.issuer) or Client:getUser(targetInfraction.issuer)
            local expires = targetInfraction.expires

            local infractionsChannel = guild:getChannel(sqldb:get(guild.id).infractionschannel)

            local embeds = parseTable(config.infractionrevokeembeds or {
                {
                    author = author(interaction.member),
                    thumbnail = (member.avatarURL and { url = member.avatarURL }) or (member.defaultAvatarURL and { url = member.defaultAvatarURL }),
                    title = emojis.success .. " Infraction Revoked",
                    description = getUserString(member) .. "'s infraction has been revoked by " .. getUserString(interaction.member) .. ":\n"
                        .. emojis.right .. " **Type:** " .. (targetInfraction.type or emojis.fail) .. "\n"
                        .. emojis.right .. " **Reason:** " .. (targetInfraction.reason or emojis.fail) .. "\n"
                        .. emojis.right .. " **Notes:** " .. (targetInfraction.notes or emojis.fail) .. "\n"
                        .. emojis.right .. " **Expires:** " .. ((expires and ("<t:" .. (os.time() + expires) .. "> (<t:" .. (os.time() + expires) .. ":R>)")) or emojis.fail) .. "\n"
                        .. emojis.right .. " **Date:** <t:" .. (targetInfraction.timestamp or os.time()) .. ">\n"
                        .. emojis.right .. " **Infraction ID:** `" .. targetInfraction.id .. "`",
                    color = colors.success
                }
            }, {
				["issuer.mention"] = issuer.mentionString,
				["issuer.name"] = issuer.name,
				["issuer.username"] = issuer.username,
				["issuer.id"] = issuer.id,
				["issuer.avatar"] = issuer.avatarURL,
				["offender.mention"] = member.mentionString,
				["offender.name"] = member.name,
				["offender.username"] = member.username,
				["offender.id"] = member.id,
				["offender.avatar"] = member.avatarURL,
				["infraction.type"] = targetInfraction.type,
				["infraction.reason"] = targetInfraction.reason or emojis.fail,
				["infraction.notes"] = targetInfraction.notes or emojis.fail,
				["infraction.expires"] = (expires and (os.time() + expires)) or emojis.fail,
				["infraction.id"] = tostring(targetInfraction.id) or emojis.fail,
				["timestamp"] = tostring(os.time())
			})

            for _, embed in ipairs(embeds) do
				if embed.description then
					embed.description = embed.description:gsub(
						"<t:([^:>]+):?[a-zA-Z]*>",
						function(val)
							if not tonumber(val) then
								return "N/A"
							end
							return "<t:" .. val .. ">"
						end
					)
				end
			end

            if sqldb:get(guild.id).infractionthread then
                (guild:getChannel(targetInfraction.thread) or infractionsChannel):send({ embeds = embeds })
            end

            local us = sqldb:getUserSettings(member.id) or {}
            if us.infractionnotifications then
                member:send({
                    embeds = embeds,
                    components = signature(guild)
                })
            end

            for _, it in pairs(config.infractiontypes) do
                if it.name == targetInfraction.type then
                    local member = guild:getMember(targetInfraction.user) or Client:getUser(targetInfraction.user)
                    local issuer = guild:getMember(targetInfraction.issuer) or Client:getUser(targetInfraction.issuer)

                    if it.role then
                        if member and member.guild and member:hasRole(it.role) then
                            member:removeRole(it.role, "infraction revoked by @" .. interaction.member.username)
                        end
                    end

                    local offenderLink = sqldb:getLink(member.id or targetInfraction.user)
                    local offenderRoblox = offenderLink and ropi.GetUser(offenderLink.roblox)

                    local issuerLink = sqldb:getLink(issuer.id)
                    local issuerRoblox = issuerLink and ropi.GetUser(issuerLink.roblox)

                    local variableMap = {
                        ["offender.discord.mention"] = (member and member.mentionString) or "N/A",
                        ["offender.discord.name"] = (member and member.name) or "N/A",
                        ["offender.discord.username"] = ((member and member.guild and member.user.username) or (member and member.username)) or "N/A",
                        ["offender.discord.id"] = targetInfraction.user,
                        ["offender.discord.avatar"] = (member and member.avatarURL) or "N/A",
                        ["issuer.discord.mention"] = (issuer and issuer.mentionString) or "N/A",
                        ["issuer.discord.name"] = (issuer and issuer.name) or "N/A",
                        ["issuer.discord.username"] = ((issuer and issuer.guild and issuer.user.username) or (issuer and issuer.username)) or "N/A",
                        ["issuer.discord.id"] = targetInfraction.issuer,
                        ["issuer.discord.avatar"] = (issuer and issuer.avatarURL) or "N/A",
                        ["offender.roblox.display"] = (offenderRoblox and offenderRoblox.displayName) or "N/A",
                        ["offender.roblox.username"] = (offenderRoblox and offenderRoblox.name) or "N/A",
                        ["offender.roblox.id"] = (offenderRoblox and offenderRoblox.id) or "N/A",
                        ["offender.roblox.hyperlink"] = (offenderRoblox and offenderRoblox.hyperlink) or "N/A",
                        ["issuer.roblox.display"] = (issuerRoblox and issuerRoblox.displayName) or "N/A",
                        ["issuer.roblox.username"] = (issuerRoblox and issuerRoblox.name) or "N/A",
                        ["issuer.roblox.id"] = (issuerRoblox and issuerRoblox.id) or "N/A",
                        ["issuer.roblox.hyperlink"] = (issuerRoblox and issuerRoblox.hyperlink) or "N/A",
                        ["infraction.type"] = it.name,
                        ["infraction.reason"] = targetInfraction.reason,
                        ["infraction.notes"] = targetInfraction.notes,
                        ["infraction.id"] = tostring(targetInfraction.id) or "N/A",
                        ["infraction.expires"] = targetInfraction.expires or "N/A",
                        ["timestamp"] = tostring(os.time())
                    }
                    
                    
                    if it.actions and it.revertActions then
                        local useCustomResultEmbed
                        local resultEmbed = {
                            title = " Infraction Revoke Result",
                            description = "That infraction has been successfully revoked." .. "\n",
                            color = colors.success
                        }

                        for _, ac in pairs(it.actions) do
                            if ac.type == "sendcmd" then
                                useCustomResultEmbed = true
                                local parsedCommand = parseTable({ ac.cmd }, variableMap)[1]

                                local params = string.split(parsedCommand, " ")
                                local cmd

                                if params[1]:usub(1, 2) == "un" and remoteInGameCommands[params[1]:usub(3)] then
                                    cmd = parsedCommand:usub(3)
                                elseif remoteInGameCommands["un" .. params[1]] then
                                    cmd = "un" .. parsedCommand
                                end

                                local server = config.apikey and ERLC:getServer(config.apikey)

                                if server and #server.players > 0 then
                                    local success, err = server:execute(parsedCommand)
                                    if success then
                                        db:send(guild, "erlccmdschannel", {
                                            embed = {
                                                author = {
                                                    name = "@" .. issuer.user.username,
                                                    icon_url = issuer.user.avatarURL
                                                },
                                                title = emojis.success .. " Infraction Action Reversion Successful",
                                                description = "> **@" .. member.username .. "**'s infraction was revoked by **@" .. issuer.name .. "**. Therefore, Ducky has reverted the infraction action `" .. ac.cmd .. "`.",
                                                color = colors.success,
                                                thumbnail = {
                                                    url = issuer.user.avatarURL
                                                }
                                            }
                                        })

                                        resultEmbed.description = resultEmbed.description .. "\n" .. emojis.right .. " " .. emojis.success .. " **Send a Command**"
                                    else
                                        db:send(guild, "erlccmdschannel", {
                                            embed = {
                                                author = {
                                                    name = "@" .. issuer.user.username,
                                                    icon_url = issuer.user.avatarURL
                                                },
                                                title = emojis.fail .. " Infraction Action Reversion Failed",
                                                description = "> **@" .. member.username .. "**'s infraction was revoked by **@" .. issuer.name .. "**. However, Ducky was unable to revert the infraction action `" .. ac.cmd .. "`: ```" .. err .. "```",
                                                color = colors.fail,
                                                thumbnail = {
                                                    url = issuer.user.avatarURL
                                                }
                                            }
                                        })

                                        resultEmbed.description = resultEmbed.description .. "\n" .. emojis.right .. " " .. emojis.fail .. " **Send a Command:** " .. err
                                    end
                                elseif sqldb:plusGuild(guild) then
                                    local success, err = db:commandQueueInsert(member.guild, parsedCommand)
                                    if success then
                                        resultEmbed.description = resultEmbed.description .. "\n" .. emojis.right .. " " .. emojis.loading .. " **Send a Command:** Added to ERLC Command Queue"
                                    else
                                        resultEmbed.description = resultEmbed.description .. "\n" .. emojis.right .. " " .. emojis.fail .. " **Send a Command:** " .. tostring(err)
                                    end
                                end
                            end
                        end

                        if useCustomResultEmbed then
                            return interaction:reply({embed = resultEmbed})
                        end
                    end
                end
            end
 
            return interaction:success("That infraction has been successfully revoked.")
        elseif subcmd == "manage" then
            local infractionID = (slash and args and args.id and args.id) or ((not slash) and args[1] and args[1])

            if not infractionID then
                return interaction:fail("You must provide the ID of the infraction to manage.", nil, true)
            end

            local infractions = config.infractions or {}
            local targetInfraction

            for _, inf in ipairs(infractions) do
                if tostring(inf.id) == tostring(infractionID) then
                    targetInfraction = inf
                    break
                end
            end

            if not targetInfraction then
                return interaction:fail("You did not provide a valid infraction to manage.", nil, true)
            end

            local comps = discordia.Components()
                :selectMenu({
                    id = "infraction_manage",
                    placeholder = "Manage this infraction...",
                    actionRow = 1,
                    max_values = 1,
                    min_values = 0,
                    options = {
                        { label = "Edit Type", value = "editType", emoji = resolvedEmojis.edit },
                        { label = "Edit Reason", value = "editReason", emoji = resolvedEmojis.edit },
                        { label = "Edit Notes", value = "editNotes", emoji = resolvedEmojis.edit },
                        { label = "Edit Expiration Time", value = "editExpires", emoji = resolvedEmojis.edit }
                    }
                })

            local issuer = Client:getUser(targetInfraction.issuer)
            local receiver = Client:getUser(targetInfraction.user)

            local r

            local function updatePanel(ia)
                ia = ia or r

                local msg = {
                    embed = {
                        author = (issuer and author(issuer)),
                        thumbnail = thumbnail(receiver),
                        color = colors.info,
                        title = emojis.quickfix .. " Infraction " .. targetInfraction.id,
                        description =
                            emojis.right .. " **Issuer:** <@" .. targetInfraction.issuer .. ">\n"
                            .. emojis.right .. " **Receiver:** <@" .. targetInfraction.user .. ">\n"
                            .. emojis.right .. " **Type:** " .. targetInfraction.type .. "\n"
                            .. emojis.right .. " **Reason:** " .. targetInfraction.reason .. "\n"
                            .. emojis.right .. " **Notes:** " .. (targetInfraction.notes or emojis.fail) .. "\n"
                            .. emojis.right .. " **Expires:** " .. ((targetInfraction.expires and ("<t:" .. targetInfraction.expires .. "> (<t:" .. targetInfraction.expires .. ":R>)")) or emojis.fail) .. "\n"
                            .. emojis.right .. " **Date:** <t:" .. targetInfraction.timestamp .. "> (<t:" .. targetInfraction.timestamp .. ":R>)"
                    },
                    components = comps:raw()
                }

                if type(ia) == "table" then
                    ia:update(msg)
                else
                    r = interaction:reply(msg)
                end
            end

            updatePanel()

            local function notifyUser(oldData, newData)
                local member = guild:getMember(targetInfraction.user)
                if not member then return end

                local issuer = guild:getMember(targetInfraction.issuer)
                if not issuer then return end

                local infractionsChannelId = sqldb:get(guild.id).infractionschannel
                local infractionsChannel = guild:getChannel(infractionsChannelId)
                if not infractionsChannel then return end

                local changes = {}

                if oldData.reason ~= newData.reason then
                    table.insert(changes, emojis.right .. " **Reason:** " ..
                        (oldData.reason or emojis.fail) .. " " .. emojis.right .. " " .. (newData.reason or emojis.fail))
                end

                if oldData.type ~= newData.type then
                    table.insert(changes, emojis.right .. " **Type:** " ..
                        (oldData.type or emojis.fail) .. " " .. emojis.right .. " " .. (newData.type or emojis.fail))
                end

                if oldData.notes ~= newData.notes then
                    table.insert(changes, emojis.right .. " **Notes:** " ..
                        (oldData.notes or emojis.fail) .. " " .. emojis.right .. " " .. (newData.notes or emojis.fail))
                end

                if oldData.expires ~= newData.expires then
                    table.insert(changes, emojis.right .. " **Expires:** " ..
                        (oldData.expires and "<t:" .. oldData.expires .. ">" or emojis.fail) ..
                        " " .. emojis.right .. " " ..
                        (newData.expires and "<t:" .. newData.expires .. "> (<t:" .. newData.expires .. ":R>)" or emojis.fail))
                end

                if #changes == 0 then return end

                local description = getUserString(member) .. "'s infraction updated by " .. getUserString(interaction.member) .. ":\n"
                    .. table.concat(changes, "\n")
                    .. "\n" .. emojis.right .. " **Date:** <t:" .. (targetInfraction.timestamp or os.time()) .. ">\n"
                    .. emojis.right .. " **Infraction ID:** `" .. targetInfraction.id .. "`"

                local embeds = parseTable(config.infractioneditembeds or {{
                    author = author(interaction.member),
                    thumbnail = (member.avatarURL and { url = member.avatarURL }) or (member.defaultAvatarURL and { url = member.defaultAvatarURL }),
                    title = emojis.edit .. " Infraction Edited",
                    description = description,
                    color = colors.warning
                }}, {
                    ["issuer.mention"] = issuer.mentionString,
                    ["issuer.name"] = issuer.name,
                    ["issuer.username"] = issuer.user.username,
                    ["issuer.id"] = issuer.id,
                    ["issuer.avatar"] = issuer.avatarURL,
                    ["offender.mention"] = member.mentionString,
                    ["offender.name"] = member.name,
                    ["offender.username"] = member.user.username,
                    ["offender.id"] = member.id,
                    ["offender.avatar"] = member.avatarURL,
                    ["infraction.type"] = targetInfraction.type,
                    ["infraction.reason"] = targetInfraction.reason or emojis.fail,
                    ["infraction.notes"] = targetInfraction.notes or emojis.fail,
                    ["infraction.expires"] = targetInfraction.expires or emojis.fail,
                    ["infraction.id"] = tostring(targetInfraction.id) or emojis.fail,
                    ["timestamp"] = tostring(os.time())
                })

                if sqldb:get(guild.id).infractionthread then
                    (guild:getChannel(targetInfraction.thread) or infractionsChannel):send({ embeds = embeds })
                end

                local us = sqldb:getUserSettings(targetInfraction.user) or {}
                if us.infractionnotifications then
                    member:send({
                        embeds = embeds,
                        components = signature(guild)
                    })
                end
            end

            onComp(r, nil, nil, interaction.user.id, false, function(ia)
                if ia.data.custom_id ~= "infraction_manage" then return end
                local selected = ia.data.values and ia.data.values[1]
                local oldData = {
                    reason = targetInfraction.reason,
                    type = targetInfraction.type,
                    notes = targetInfraction.notes,
                    expires = targetInfraction.expires
                }

                if selected == "editReason" then
                    prompt(ia, "Edit Reason", {
                        { question = "New Reason", placeholder = "Enter the new reason...", required = false, style = "paragraph" }
                    }, function(mia, responses)
                        local newReason = responses["New Reason"]
                        if newReason and #newReason > 0 then
                            local infractions = (sqldb:get(guild.id) or {}).infractions or {}
                            for _, inf in ipairs(infractions) do
                                if inf.id == targetInfraction.id then inf.reason = newReason break end
                            end
                            sqldb:set(guild.id, {infractions = infractions}, "INFRACTION_UPDATE_REASON")
                            targetInfraction.reason = newReason
                            notifyUser(oldData, targetInfraction)

                            return updatePanel(mia)
                        else
                            updatePanel()
                            return mia:fail("You must provide a new reason to update.", nil, true)
                        end
                    end)

                elseif selected == "editType" then
                    local config = sqldb:get(interaction.guild.id) or {}
                    local opts = {}
                    if config.infractiontypes then
                        for i, v in ipairs(config.infractiontypes) do
                            if v.name ~= targetInfraction.type then
                                table.insert(opts, { label = v.name, value = tostring(i) })
                            end
                        end
                    end

                    if table.count(opts) < 2 then
                        updatePanel()
                        return ia:fail("There is only 1 infraction type available.", nil, true)
                    end

                    optionsSelect(ia, "Select an infraction type...", function(opt)
                        local chosenIndex = tonumber(opt)
                        if chosenIndex and config.infractiontypes[chosenIndex] then
                            local newType = config.infractiontypes[chosenIndex]
                            local infractions = config.infractions or {}
                            for _, inf in ipairs(infractions) do
                                if inf.id == targetInfraction.id then
                                    inf.type = newType.name
                                    break
                                end
                            end
                            sqldb:set(interaction.guild.id, {infractions = infractions}, "INFRACTION_UPDATE_TYPE")
                            targetInfraction.type = newType.name
                            notifyUser(oldData, targetInfraction)

                            return updatePanel()
                        else
                            updatePanel()
                            return ia:fail("Invalid infraction type selected.", nil, true)
                        end
                    end, true, opts, 1, nil, true)

                elseif selected == "editNotes" then
                    prompt(ia, "Edit Notes", {
                        { question = "New Notes", placeholder = "Enter the new notes...", required = false, style = "paragraph" }
                    }, function(mia, responses)
                        local newNotes = responses["New Notes"]
                        if newNotes and #newNotes > 0 then
                            local infractions = (sqldb:get(guild.id) or {}).infractions or {}
                            for _, inf in ipairs(infractions) do
                                if inf.id == targetInfraction.id then inf.notes = newNotes break end
                            end
                            sqldb:set(guild.id, {infractions = infractions}, "INFRACTION_UPDATE_NOTES")
                            targetInfraction.notes = newNotes
                            notifyUser(oldData, targetInfraction)

                            return updatePanel(mia)
                        else
                            updatePanel()
                            return mia:fail("You must provide new notes to update.", nil, true)
                        end
                    end)

                elseif selected == "editExpires" then
                    prompt(ia, "Edit Expiration Time", {
                        { question = "New Expiration Time", placeholder = "E.g. 1d, 2h, 5m", required = false, style = "short" }
                    }, function(mia, responses)
                        local newExpiration = responses["New Expiration Time"] and convert(responses["New Expiration Time"])
                        if newExpiration and newExpiration > 0 then
                            local infractions = (sqldb:get(guild.id) or {}).infractions or {}
                            local expiresTimestamp = os.time() + newExpiration

                            for _, inf in ipairs(infractions) do
                                if inf.id == targetInfraction.id then inf.expires = expiresTimestamp break end
                            end
                            sqldb:set(guild.id, {infractions = infractions}, "INFRACTION_UPDATE_EXPIRES")
                            targetInfraction.expires = expiresTimestamp
                            notifyUser(oldData, targetInfraction)

                            return updatePanel(mia)
                        else
                            local infractions = (sqldb:get(guild.id) or {}).infractions or {}

                            for _, inf in ipairs(infractions) do
                                if inf.id == targetInfraction.id then inf.expires = nil break end
                            end

                            sqldb:set(guild.id, {infractions = infractions}, "INFRACTION_UPDATE_EXPIRES")
                            targetInfraction.expires = nil
                            notifyUser(oldData, targetInfraction)

                            return updatePanel(mia)
                        end
                    end)
                else
                    ia:updateDeferred(true)
                end
            end)
        end
    end
}
