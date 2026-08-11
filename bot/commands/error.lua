-- error.lua

local function getLine(fileName, lineNumber)
    lineNumber = tonumber(lineNumber)
    local f = io.open(fileName, "r")
    if not f then return "N/A" end

    local line, status, err
    local pcall_status, result = pcall(function()
        local count = 1
        for l in f:lines() do
            if count == lineNumber then
                line = tostring(l)
                break
            end
            count = count + 1
        end
        f:close()
    end)

    if not pcall_status then
        -- error occurred, close the file and return N/A
        f:close()
        return "N/A"
    end

    return line or "N/A"
end

return {
    name = "error",
    description = "Get information on the given error ID.",
    aliases = {"err"},
    category = "Utility",
    slashCommand = nil,
    requiredPermissions = {"SUPPORT"},
    callback = function(interaction, args, slash, subcmd)
        local errors = sqldb:getAllErrors()

        table.remove(args, 1)

        if subcmd == "view" then
            local errorID = args[1]
            local error = errorID and errors[errorID]

            if error then
                local errGuild = (error.guildID and Client:getGuild(error.guildID)) or {}
                local errUser = (error.userID and Client:getUser(error.userID)) or {}

                local r = interaction:reply({
                    embed = {
                        title = ((error.resolved and emojis.success) or emojis.error) .. " Error `" .. errorID .. "`",
                        description = emojis.right .. " **Command:** `" .. error.command .. "`\n" .. emojis.right .. " **Error:** `" .. error.full .. "`\n" .. emojis.right .. " **Location:** `commands/" .. error.command .. ".lua:" .. error.line .. "`\n" .. emojis.right .. " **Line:** `" .. tostring(getLine("commands/" .. error.command .. ".lua", error.line)):gsub("`", "\\`") .. "`\n" .. emojis.right .. " **Guild:** " .. tostring(errGuild.name) .. " (`" .. tostring(errGuild.id) .. "`)\n" .. emojis.right .. " **User:** [@" .. tostring(errUser.username) .. "](https://discord.com/users/" .. tostring(errUser.id) .. ") (`" .. errUser.id .. "`)\n" .. emojis.right .. " **Last Seen:** <t:" .. error.timestamp .. "> (<t:" .. error.timestamp .. ":R>)\n" .. emojis.right .. " **Resolved:** " .. ((error.resolved and emojis.success) or emojis.fail),
                        color = (error.resolved and colors.success) or colors.error
                    },
                    components = (not error.resolved) and discordia.Components()
                        :button({
                            id = "resolve",
                            label = "Mark as Resolved",
                            style = "success",
                            emoji = resolvedEmojis.yeswhite
                        })
                        :raw()
                })
    
                if not error.resolved then
                    onComp(r, "button", "resolve", interaction.user.id, false, function(ia)
                        local errTable = errors[errorID]
                        errTable.resolved = true
                        sqldb:saveError(errorID, errTable)
    
                        ia:update({
                            embed = {
                                title = ((error.resolved and emojis.success) or emojis.error) .. " Error `" .. errorID .. "`",
                                description = emojis.right .. " **Command:** `" .. error.command .. "`\n" .. emojis.right .. " **Error:** `" .. error.full .. "`\n" .. emojis.right .. " **Location:** `commands/" .. error.command .. ".lua:" .. error.line .. "`\n" .. emojis.right .. " **Line:** `" .. tostring(getLine("commands/" .. error.command .. ".lua", error.line)):gsub("`", "\\`") .. "`\n" .. emojis.right .. " **Guild:** " .. tostring(errGuild.name) .. " (`" .. tostring(errGuild.id) .. "`)\n" .. emojis.right .. " **User:** [@" .. tostring(errUser.username) .. "](https://discord.com/users/" .. tostring(errUser.id) .. ") (`" .. errUser.id .. "`)\n" .. emojis.right .. " **Last Seen:** <t:" .. error.timestamp .. "> (<t:" .. error.timestamp .. ":R>)\n" .. emojis.right .. " **Resolved:** " .. ((error.resolved and emojis.success) or emojis.fail),
                                color = (error.resolved and colors.success) or colors.error
                            },
                            components = {}
                        })
                        return true
                    end)
                end
            else
                return interaction:fail("Error `" .. errorID .. "` was not found.", nil, true)
            end
        elseif subcmd == "reference" or subcmd == "extract" or subcmd == "ref" then
            local ref = interaction.referencedMessage
            if not ref then
                return interaction:fail("You did not reply to any message.", nil, true)
            end 

            if (not ref.embed) or (not ref.embed.description) or (not ref.embed.title) or (ref.embed.description == "") or (not ref.embed.title:find("Whoops...")) or (ref.embed.color ~= colors.error) or (ref.author.id ~= Client.user.id) then
                return interaction:fail("The message you replied to is not a valid error message.", nil, true)
            end

            local errorID = ref.embed.description:match("%*%*Error ID:%*%* `(.-)`")

            if (not errorID) or (errorID == "") or (errorID:usub(1,6) ~= "ducky_") then
                return interaction:fail("Failed to extract the error ID from the message you replied to.", nil, true)
            end

            local error = errors[errorID]

            if (not error) then
                return interaction:fail("Error `" .. errorID .. "` was not found.", nil, true)
            end

            local errGuild = (error.guildID and Client:getGuild(error.guildID)) or {}
            local errUser = (error.userID and Client:getUser(error.userID)) or {}

            local r = interaction:reply({
                embed = {
                    title = ((error.resolved and emojis.success) or emojis.error) .. " Error `" .. errorID .. "`",
                    description = emojis.right .. " **Command:** `" .. error.command .. "`\n" .. emojis.right .. " **Error:** `" .. error.full .. "`\n" .. emojis.right .. " **Location:** `commands/" .. error.command .. ".lua:" .. error.line .. "`\n" .. emojis.right .. " **Line:** `" .. tostring(getLine("commands/" .. error.command .. ".lua", error.line)):gsub("`", "\\`") .. "`\n" .. emojis.right .. " **Guild:** " .. tostring(errGuild.name) .. " (`" .. tostring(errGuild.id) .. "`)\n" .. emojis.right .. " **User:** [@" .. tostring(errUser.username) .. "](https://discord.com/users/" .. tostring(errUser.id) .. ")\n" .. emojis.right .. " **Last Seen:** <t:" .. error.timestamp .. "> (<t:" .. error.timestamp .. ":R>)\n" .. emojis.right .. " **Resolved:** " .. ((error.resolved and emojis.success) or emojis.fail),
                    color = (error.resolved and colors.success) or colors.error
                },
                components = (not error.resolved) and discordia.Components()
                    :button({
                        id = "resolve",
                        label = "Mark as Resolved",
                        style = "success",
                        emoji = resolvedEmojis.yeswhite
                    })
                    :raw()
            })

            if not error.resolved then
                onComp(r, "button", "resolve", interaction.user.id, false, function(ia)
                    local errTable = errors[errorID]
                    errTable.resolved = true
                    sqldb:saveError(errorID, errTable)

                    ia:update({
                        embed = {
                            title = ((error.resolved and emojis.success) or emojis.error) .. " Error `" .. errorID .. "`",
                            description = emojis.right .. " **Command:** `" .. error.command .. "`\n" .. emojis.right .. " **Error:** `" .. error.full .. "`\n" .. emojis.right .. " **Location:** `commands/" .. error.command .. ".lua:" .. error.line .. "`\n" .. emojis.right .. " **Line:** `" .. tostring(getLine("commands/" .. error.command .. ".lua", error.line)):gsub("`", "\\`") .. "`\n" .. emojis.right .. " **Guild:** " .. tostring(errGuild.name) .. " (`" .. tostring(errGuild.id) .. "`)\n" .. emojis.right .. " **User:** [@" .. tostring(errUser.username) .. "](https://discord.com/users/" .. tostring(errUser.id) .. ") (`" .. errUser.id .. "`)\n" .. emojis.right .. " **Last Seen:** <t:" .. error.timestamp .. "> (<t:" .. error.timestamp .. ":R>)\n" .. emojis.right .. " **Resolved:** " .. ((error.resolved and emojis.success) or emojis.fail),
                            color = (error.resolved and colors.success) or colors.error
                        },
                        components = {}
                    })
                    return true
                end)
            end
        elseif subcmd == "unresolved" or subcmd == "ur" or subcmd == "active" or subcmd == "list" then
            local unresolved = {}

            for i, v in pairs(errors) do
                if not v.resolved then
                    unresolved[i] = v
                end
            end

            local total = table.count(unresolved)
            
            if total <= 0 then
                return interaction:success("All errors are resolved.", nil, true)
            end

            local pages = {}
            
            local embed = {
                title = emojis.error .. " Unresolved Errors (" .. total .. ")",
                fields = {},
                color = colors.error
            }

            local c = 0

            for id, err in pairs(unresolved) do
                c = c + 1
                table.insert(embed.fields, {
                    name = "Error `" .. id .. "`",
                    value = emojis.right .. " **Command:** " .. err.command .. "\n" .. emojis.right .. " **Location:** `commands/" .. err.command .. ".lua:" .. (err.line or "unknown") .. "`\n" .. emojis.right .. " **Error:** `" .. err.full .. "`\n" .. emojis.right .. " **Last Seen:** <t:" .. err.timestamp .. "> (<t:" .. err.timestamp .. ":R>)"
                })

                if (table.count(embed.fields) >= 5) or c >= total then
                    embed.components = discordia.Components()
                        :button({
                            id = "resolveall",
                            label = "Mark All as Resolved",
                            style = "success",
                            emoji = resolvedEmojis.yeswhite
                        })
                    embed.otherCompCallback = function(ia)
                        if ia.data.custom_id == "resolveall" then
                            local success, msg = sqldb:resolveAllErrors()
                            if success then
                                ia:update({
                                    embed = {
                                        description = emojis.success .. " All errors have been marked as resolved.",
                                        color = colors.success
                                    },
                                    components = {}
                                })
                            else
                                ia:update({
                                    embed = {
                                        description = emojis.fail .. " Failed to resolve all errors: " .. tostring(msg),
                                        color = colors.fail
                                    },
                                    components = {}
                                })
                            end
                            return true
                        end
                    end
                    table.insert(pages, embed)
                    embed = {
                        title = emojis.error .. " Unresolved Errors (" .. total .. ")",
                        fields = {},
                        color = colors.error
                    }
                end
            end

            return _G.paginate(interaction, pages, interaction.user, {teleport = true, clamp = false, showTotalPages = true})
        end
    end
}
