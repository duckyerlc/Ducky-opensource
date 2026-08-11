-- exportables.lua

local slashCommand = tools.slashCommand("exportables", "Manage/view Ducky Exportables.")
local subcmd = tools.subCommand("view", "View a Ducky Exportable.")
subcmd = subcmd:addOption(tools.string("code", "The Ducky Exportable code to view."))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("owned", "View your Ducky Exportables.")
slashCommand = slashCommand:addOption(subcmd)

local function export(tbl, owner, exportableType, name)
    local code = "ducky_" .. junkStr(25)

    local value, char, err = json.encode(tbl)
    if not value then
        return nil, err
    end

    local exportables = sqldb:getAllExportables() or {}
    for _, v in pairs(exportables) do
        if v.data == value then
            return v.id
        end
    end

    local succ, err2 = sqldb:addExportable(
        code,
        owner.id,
        os.time(),
        0,
        exportableType,
        value,
        name or emojis.fail
    )

    if succ then
        return code
    else
        return nil, err2
    end
end

_G.export = export

local function import(code, type, full)
    local exportable = sqldb:getExportable(code)
    if not exportable then return nil, "Invalid exportable code." end

    local parse
    if type then
        if type == "panel" and exportable.type ~= "panel" then
            return nil, "The exportable must be a tickets panel."
        elseif type == "automation" and exportable.type ~= "automation" then
            return nil, "The exportable must be an automation."
        elseif type == "message" then
            if exportable.type == "embed" then
                parse = function(value) return {embeds = {value}} end
            elseif exportable.type == "embeds" then
                parse = function(value) return {embeds = value} end
            elseif exportable.type ~= "message" then
                return nil, "The exportable must be a message, embed, or embeds."
            end
        elseif type == "embed" then
            if exportable.type == "message" then
                parse = function(value) return (value.embeds and value.embeds[1]) or value.embed end
            elseif exportable.type == "embeds" then
                parse = function(value) return value[1] end
            elseif exportable.type ~= "embed" then
                return nil, "The exportable must be a message, embed, or embeds."
            end
        elseif type == "embeds" then
            if exportable.type == "message" then
                parse = function(value) return value.embeds or (value.embed and {value.embed}) end
            elseif exportable.type == "embed" then
                parse = function(value) return {value} end
            elseif exportable.type ~= "embeds" then
                return nil, "The exportable must be a message, embed, or embeds."
            end
        end
    end

    local value, char, err = json.decode(exportable.data)
    if not value then
        return nil, "Exportable data could not be decoded."
    end

    exportable.value = value
    exportable.lastImported = os.time()
    sqldb:setExportable(code, exportable)

    if parse then
        local parsedValue = parse(value)
        if not parsedValue then
            return nil, "This exportable does not contain the necessary data to be imported here."
        end
        exportable.value = parsedValue
        value = parsedValue
    end

    if full then
        return exportable
    else
        return value
    end
end

_G.import = import

local colors, emojis, resolvedEmojis = _G.colors, _G.emojis, _G.resolvedEmojis

return {
    name = "exportables",
    description = "Manage/view Ducky Exportables.",
    aliases = {
        "exports",
        "exps",
        "exp",
        "duckyexportables"
    },
    category = "Utility",
    slashCommand = slashCommand,
    requiredPermissions = {},
    subcommands = {
        "view",
        mine = {
            "owned",
            "own"
        }
    },
	hybridCallback = function(interaction, args, slash, subcmd)
		if subcmd == "view" then
            local code = (slash and args and args.code) or ((not slash) and args and args[2])

            if code then
                local imported, err = import(code, nil, true)

                if imported then
                    local comps = discordia.Components()
                    :button({
                        id = "expShow",
                        label = "View",
                        style = "secondary",
                        actionRow = 1,
                        emoji = resolvedEmojis.eye
                    })
                    :button({
                        id = "json",
                        label = "View JSON",
                        style = "secondary",
                        actionRow = 1,
                        emoji = resolvedEmojis.json
                    }):raw()

                    if imported.owner == interaction.member.id then
                        comps = discordia.Components()
                        :button({
                            id = "expShow",
                            label = "View",
                            style = "secondary",
                            actionRow = 1,
                            emoji = resolvedEmojis.eye
                        })
                        :button({
                            id = "json",
                            label = "View JSON",
                            style = "secondary",
                            actionRow = 1,
                            emoji = resolvedEmojis.json
                        })
                        :button({
                            id = "editName",
                            label = "Edit Name",
                            style = "secondary",
                            actionRow = 1,
                            emoji = resolvedEmojis.edit
                        })
                        :button({
                            id = "delete",
                            label = "Delete",
                            style = "danger",
                            actionRow = 1,
                            emoji = resolvedEmojis.delete
                        })
                        :raw()
                    end

                    local r = interaction:reply({
                        embed = {
                            title = emojis.export .. " Ducky Exportable",
                            description = emojis.right .. " **Code:** `" .. code .. "`\n" .. emojis.right .. " **Name:** " .. (imported.name or emojis.fail) .. "\n" .. emojis.right .. " **Type:** " .. ((imported.type and string.capitalize(imported.type)) or "N/A") .. "\n" .. emojis.right .. " **Owner:** " .. ((imported.owner and Client:getUser(imported.owner) and "@" .. Client:getUser(imported.owner).username) or "Unknown") .. "\n" .. emojis.right .. " **Created:** <t:" .. imported.createdAt .. ">\n" .. emojis.right .. " **Last Imported:** " .. ((imported.lastImported and "<t:" .. imported.lastImported .. ">") or "Never"),
                            color = colors.info,
                        },
                        components = comps
                    })

                    if not r then return end

                    onComp(r, nil, nil, interaction.user.id, false, function(ia)
                        local id = ia.data.custom_id

                        if id == "expShow" then
                            if (imported.type ~= "embed") and (imported.type ~= "message") and (imported.type ~= "embeds") then
                                return ia:fail("This is only supported for embeds and messages.", nil, true)
                            end

                            local exp, err = import(code, imported.type)

                            if not exp then
                                return ia:fail("Failed to import exportable: ```" .. err .. "```", nil, true)
                            end

                            if imported.type == "embed" then
                                ia:reply({embed = exp}, true)
                            elseif imported.type == "message" then
                                fixCompId(exp.components or {}, "custom_id", true)
                                local s, e = ia:reply(exp, true)
                                if not s then
                                    utilityChannels.development:send(tostring(e))
                                end
                            elseif imported.type == "embeds" then
                                ia:reply({embeds = exp}, true)
                            else
                                ia:fail("An unknown error occurred. Please try again later.", nil, true)
                            end
                        elseif id == "json" then
                                local dataToEncode

                                if type(imported.data) == "string" then
                                    local ok, decoded = pcall(json.decode, imported.data)
                                    if ok and decoded then
                                        dataToEncode = decoded
                                    else
                                        dataToEncode = imported.data
                                    end
                                else
                                    dataToEncode = imported.data
                                end

                                ia:reply({
                                    files = {
                                        {
                                            code .. ".json",
                                            json.encode(dataToEncode)
                                        }
                                    }
                                }, true)
                        elseif id == "delete" then
                            if r then
                                if sqldb:getExportable(code) then
                                    local succ, err = sqldb:deleteExportable(code)

                                    if succ then
                                        r:setEmbed({
                                            description = emojis.success .. " Successfully deleted exportable.",
                                            color = colors.success
                                        })
                                        r:setComponents()

                                        return ia:updateDeferred(true)
                                    else
                                        ia:fail("Failed to delete exportable: " .. err, nil, true)
                                    end
                                else
                                    return ia:fail("That exportable no longer exists.", nil, true)
                                end
                            end
                        elseif id == "editName" then
                            local exp, err = import(code, imported.type, true)

                            if not exp then
                                return ia:fail("Failed to import exportable: ```" .. err .. "```", nil, true)
                            end

                            prompt(ia, "Exportable Name", {
                                {
                                    question = "What should this exportable be named?",
                                    placeholder = "Enter a name for this exportable...",
                                    style = "short",
                                    max = 100
                                }
                            }, function(mia, responses)
                                if not mia then return end

                                local newName = responses["What should this exportable be named?"]

                                if newName and newName ~= "" then
                                    exp.name = newName
                                else
                                    exp.name = nil
                                end

                                exp.lastImported = os.time()

                                local success, err = sqldb:setExportable(code, exp)
                                if not success then
                                    return mia:fail("Failed to save exportable: " .. tostring(err), nil, true)
                                end

                                mia:updateDeferred(true)

                                r:update({
                                    embed = {
                                        title = emojis.export .. " Ducky Exportable",
                                        description = emojis.right .. " **Code:** `" .. code .. "`\n" .. emojis.right .. " **Name:** " .. (newName or emojis.fail) .. "\n" .. emojis.right .. " **Type:** " .. ((imported.type and string.capitalize(imported.type)) or "N/A") .. "\n" .. emojis.right .. " **Owner:** " .. ((imported.owner and Client:getUser(imported.owner) and "@" .. Client:getUser(imported.owner).username) or "Unknown") .. "\n" .. emojis.right .. " **Created:** <t:" .. imported.createdAt .. ">\n" .. emojis.right .. " **Last Imported:** " .. ((imported.lastImported and "<t:" .. imported.lastImported .. ">") or "Never"),
                                        color = colors.info,
                                    },
                                    components = comps
                                })
                            end, true)
                        end
                    end)
                else
                    return interaction:fail("Failed to import code: " .. tostring(err), nil, true)
                end
            else
                return interaction:fail("You must provide an exportable code to view.", nil, true)
            end
        elseif subcmd == "mine" or subcmd == "owned" or subcmd == "own" then
            local exportables = {}

            local allExportables = sqldb:getAllExportables()

            if not allExportables or not type(allExportables) == "table"then
                return interaction:fail("Failed to get exportables data. If this error continues, contact us in the [Ducky support server](https://discord.gg/j4w5ZcbRyh).", nil, true)
            end

            for i, v in pairs(allExportables) do
                if v.owner == interaction.user.id then
                    table.insert(exportables, v)
                end
            end

            table.sort(allExportables, function(a, b)
				if (not a.createdAt) or not b.createdAt then
					return false
				else
					return a.createdAt > b.createdAt
				end
			end)

            if not next(exportables) then
                return interaction:fail("You have not created any exportables.", nil, true)
            else
                local pages = {}

                for _, exportable in pairs(exportables) do

                    local code = exportable.id
                    local emb = {
                        title = emojis.export .. " Your Exportables (" .. table.count(exportables) .. ")",
                        color = colors.info,
                        description = emojis.right .. " **Code:** `" .. code .. "`\n" .. emojis.right .. " **Type:** " .. string.capitalize(exportable.type or "Exportable") .. "\n" .. emojis.right .. " **Name:** " .. (exportable.name or emojis.fail) .. "\n" .. emojis.right .. " **Created:** <t:" .. exportable.createdAt .. ">\n" .. emojis.right .. " **Last Imported:** " .. ((exportable.lastImported and exportable.lastImported ~= 0 and "<t:" .. exportable.lastImported .. ">") or "Never"),
                        components = discordia.Components()
                            :button({
                                id = "expShow",
                                label = "View",
                                style = "secondary",
                                actionRow = 1,
                                emoji = resolvedEmojis.eye
                            })
                            :button({
                                id = "delete",
                                label = "Delete",
                                style = "danger",
                                actionRow = 1,
                                emoji = resolvedEmojis.delete
                            })
                    }

                    emb.otherCompCallback = function(ia)
                        local id = ia.data.custom_id

                        if id == "expShow" then
                            if (exportable.type ~= "embed") and (exportable.type ~= "message") then
                                return ia:fail("This is only supported for embeds and messages.", nil, true)
                            end

                            local exp, err = import(code, exportable.type)

                            if not exp then
                                return ia:fail("Failed to import exportable: ```" .. err .. "```", nil, true)
                            end

                            if exportable.type == "embed" then
                                ia:reply({embed = exp}, true)
                            elseif exportable.type == "message" then
                                fixCompId(exp.components or {}, "custom_id", true)
                                ia:reply(exp, true)
                            else
                                ia:fail("An unknown error occurred. Please try again later.", nil, true)
                            end
                        elseif id == "delete" then
                            if sqldb:getExportable(code) then
                                local succ, err = sqldb:deleteExportable(code)

                                if succ then
                                    return ia:success("Successfully deleted exportable.", nil, true)
                                else
                                    ia:fail("Failed to delete exportable: " .. err, nil, true)
                                end
                            else
                                return ia:fail("That exportable no longer exists.", nil, true)
                            end
                        end
                    end

                    emb.identifier = {
                        text = (exportable.name and (exportable.name .. " " .. emojis.dot .. " ") or "") .. string.capitalize(exportable.type),
                        description = exportable.id,
                        emoji = resolveEmoji(emojis.edit)
                    }

                    table.insert(pages, emb)
                end

                return _G.paginate(interaction, pages, interaction.user, {showTotalPages = true, clamp = false})
            end
        end
	end
}