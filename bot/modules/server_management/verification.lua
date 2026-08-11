-- verification.lua
local verificationmodule = {
    name = "verificationmodule",
    description = "Processes Roblox verification for Ducky."
}

local connections = {
    Client = {},
    DuckyAPI = {}
}

verificationmodule.Start = function()
    if not DuckyAPI then
        Client:error("DuckyAPI emitter not found; API verification listener is disabled.")
    end

    local words = {"Waddle", "Ducky", "Duck", "Versus", "Geese", "Goose", "Pond", "Water", "Grass", "Rubber", "Bathtub",
                   "Yellow", "Blue"}

    local function generatePhrase(phraseLength, predicate)
        local phrase = ""

        for i = 1, phraseLength do
            phrase = phrase .. words[math.random(1, #words)] .. (((i < phraseLength) and " ") or "")
        end

        local meetspred = predicate and predicate(phrase)

        if not predicate then
            meetspred = true
        end

        return (meetspred and phrase) or generatePhrase(predicate)
    end

    _G.generatePhrase = generatePhrase

    connections.Client.memberJoin = Client:on("memberJoin", function(member)
        if not member or not member.user or not member.guild or blacklisted(member.guild) then
            return
        end

        local usersettings = sqldb:getUserSettings(member.id) or {}
        local guild = member.guild
        local config = sqldb:get(guild.id)
        if not config then
            return
        end

        updateMember(member, "user joined the server")

        local link = sqldb:getLink(member.id)

        if not link then
            if config.bloxlinkServerKey and not usersettings.bloxlinkoptout then
                if guild:getMember("426537812993638400") then
                    local hdrs = {{"Authorization", config.bloxlinkServerKey}}

                    local result, body = _G.http.request("GET", "https://api.blox.link/v4/public/guilds/" ..
                        guild.id .. "/discord-to-roblox/" .. member.id, hdrs)

                    local success, bodyresult = pcall(json.decode, body)
                    body = (body and (type(body) == "string") and success and bodyresult)

                    if type(body) ~= "table" then
                        return
                    end

                    if result.code == 400 then
                        sqldb:set(guild.id, {
                            bloxlinkServerKey = "nil"
                        }, "INVALID_BLOXLINKSERVERKEY")

                        local ownerId = guild.ownerId
                        local owner = ownerId and guild:getMember(ownerId)

                        if owner then
                            owner:send({
                                content = "# " .. emojis.warning ..
                                    " Bloxlink Server Key Removed\nThe Bloxlink Server Key in your server, **" ..
                                    guild.name ..
                                    "**, have been removed, because the Bloxlink API indicated that it is invalid." ..
                                    "\n\n***Here's how you can resolve this:***" .. "\n" .. emojis.right ..
                                    " Go to **https://blox.link/dashboard/user/developer** and make sure you are logged in." ..
                                    "\n" .. emojis.right ..
                                    " Under **Current Server Keys** next to **Need a different server?** you can select your server and click **Add** to create a Server Key." ..
                                    "\n" .. emojis.right ..
                                    " Your server will appear, click **See Key** to get your Bloxlink Server Key." ..
                                    "\n" .. emojis.right .. " Navigate to the " .. emojis.roblox ..
                                    "**Roblox Verification** page in `/setup` and **Toggle Bloxlink Usage**." ..
                                    "\n" .. emojis.right ..
                                    " If you need assistance, contact us in the [support server](https://duckybot.xyz/support)." ..
                                    "\n\n***Information for further reference:***\n" .. emojis.right ..
                                    " Bloxlink returned the following error: ```" .. result.code .. ": " ..
                                    body.error .. "```",

                                components = discordia.Components():button({
                                    url = "https://discord.gg/w2dNr7vuKP",
                                    style = "link",
                                    label = "Ducky's Pond",
                                    emoji = resolvedEmojis.ducky
                                }):raw()
                            })
                        end

                        return
                    end

                    if body.robloxID and tonumber(body.robloxID) then
                        if not sqldb:getLink(body.robloxID) then
                            local robloxUser = ropi.GetUser(body.robloxID)

                            if type(robloxUser) == "table" then
                                local confirmButton = discordia.Button({
                                    id = "confirm",
                                    emoji = resolvedEmojis.yeswhite,
                                    label = "Link",
                                    style = "success"
                                })
                                local denyButton = discordia.Button({
                                    id = "deny",
                                    emoji = resolvedEmojis.nowhite,
                                    label = "Deny",
                                    style = "danger"
                                })
                                local denyAndDontAskButton = discordia.Button({
                                    id = "denyanddontask",
                                    emoji = resolvedEmojis.nowhite,
                                    label = "Deny (and do not ask again)",
                                    style = "danger"
                                })
                                local policyLink = discordia.Button({
                                    style = "link",
                                    url = "https://duckybot.xyz/legal/privacy#discord",
                                    emoji = resolvedEmojis.document,
                                    label = "More Information"
                                })

                                local comps = discordia.Components(
                                    {confirmButton, denyButton, denyAndDontAskButton, policyLink})

                                local confirmationMessage = member:send({
                                    content = emojis.pings .. " Your " .. emojis.roblox .. " **Roblox** profile, **" ..
                                        robloxUser.hyperlink ..
                                        "**, has been fetched from the **Bloxlink API**. Would like to have this profile saved on " ..
                                        emojis.ducky .. " **Ducky** as well?\n-# " .. emojis.right ..
                                        " By denying this request, your profile will not be stored nor processed by " ..
                                        emojis.ducky .. " **Ducky**.",
                                    components = comps:raw()
                                })

                                onComp(confirmationMessage, nil, nil, member.id, true, function(ria)
                                    local id = ria.data.custom_id

                                    local function disableComps()
                                        confirmButton:disable()
                                        denyButton:disable()
                                        denyAndDontAskButton:disable()
                                        confirmationMessage:update({
                                            content = emojis.pings .. " Your " .. emojis.roblox ..
                                                " **Roblox** profile, **" .. robloxUser.hyperlink ..
                                                "**, has been fetched from the **Bloxlink API**. Would like to have this profile saved on " ..
                                                emojis.ducky .. " **Ducky** as well?\n-# " .. emojis.right ..
                                                " By denying this request, your profile will not be stored nor processed by " ..
                                                emojis.ducky .. " **Ducky**.",
                                            components = comps:raw()
                                        })
                                    end

                                    if id == "confirm" then
                                        local succ, err = sqldb:link(member, robloxUser)

                                        if succ then
                                            ria:success(
                                                "You have been successfully linked with **" .. emojis.roblox .. " " ..
                                                    robloxUser.hyperlink ..
                                                    "**. If you would like to unlink this account, you can do so at any time by using **`/link`** and pressing **" ..
                                                    emojis.unlink .. " Unlink**.")
                                            disableComps()
                                            return true
                                        else
                                            ria:fail("Failed to link: ```" .. err .. "```")
                                            disableComps()
                                            return
                                        end
                                    elseif id == "deny" then
                                        ria:fail(
                                            "We will not store nor process this information any further. If you change your mind, you can link your account at any time using **`/link`**.")
                                        disableComps()
                                        return
                                    elseif id == "denyanddontask" then
                                        local usersettings = sqldb:getUserSettings(member.id) or {}
                                        usersettings.bloxlinkoptout = true

                                        local succ, err = sqldb:setUserSettings(member.id, usersettings)

                                        if succ then
                                            ria:fail(
                                                "We will not store nor process this information any further. If you change your mind, you can link your account at any time using **`/link`**. Additionally, we will not ask you this again until you opt back in via **`/usersetings`**.")
                                            disableComps()
                                            return
                                        else
                                            ria:fail("Failed to save usersettings, please try again: ```" .. err ..
                                                            "```")
                                        end
                                    end
                                end)
                            end
                        end
                    end

                    return
                else
                    sqldb:set(guild.id, {
                        bloxlinkServerKey = "nil"
                    }, "BLOXLINK_NOT_IN_SERVER")

                    local ownerId = guild.ownerId
                    local owner = ownerId and guild:getMember(ownerId)

                    if owner then
                        owner:send({
                            content = "# " .. emojis.warning ..
                                " Bloxlink Server Key Removed\nThe Bloxlink Server Key in your server, **" ..
                                guild.name ..
                                "**, have been removed, because the Bloxlink is no longer in your server." ..
                                "\n\n***Here's how you can resolve this:***" .. "\n" .. emojis.right ..
                                " Go to **https://blox.link/invite** and invite Bloxlink to your server." .. "\n" ..
                                emojis.right ..
                                " Go to **https://blox.link/dashboard/user/developer** and make sure you are logged in." ..
                                "\n" .. emojis.right ..
                                " If you already have a server key, skip this. Under **Current Server Keys** next to **Need a different server?** you can select your server and click **Add** to create a Server Key." ..
                                "\n" .. emojis.right ..
                                " Your server will appear, click **See Key** to get your Bloxlink Server Key." ..
                                "\n" .. emojis.right .. " Navigate to the " .. emojis.roblox ..
                                "**Roblox Verification** page in `/setup` and **Toggle Bloxlink Usage**." .. "\n" ..
                                emojis.right ..
                                " If you need assistance, contact us in the [support server](https://duckybot.xyz/support).",

                            components = discordia.Components():button({
                                url = "https://discord.gg/w2dNr7vuKP",
                                style = "link",
                                label = "Ducky's Pond",
                                emoji = resolvedEmojis.ducky
                            }):raw()
                        })
                    end

                    return
                end
            end
        end
    end)

    connections.DuckyAPI.userLinked = DuckyAPI:on("userLinked", function(user, rblx)
        if rblx and rblx.name and rblx.id and user and user.mutualGuilds and #user.mutualGuilds > 0 then
            for _, guild in pairs(user.mutualGuilds) do
                local member = guild:getMember(user.id)

                if member then
                    updateMember(member, "user linked with Ducky")
                end
            end
        end
    end)

    connections.DuckyAPI.userUnlinked = DuckyAPI:on("userUnlinked", function(user)
        if user and user.mutualGuilds and #user.mutualGuilds > 0 then
            for _, guild in pairs(user.mutualGuilds) do
                local member = guild:getMember(user.id)

                if member then
                    updateMember(member, "user unlinked from Ducky")
                end
            end
        end
    end)

    connections.Client.interactionCreate = Client:on("interactionCreate", function(interaction)
        if not interaction.data or not interaction.channel or not interaction.guild or not interaction.user or
            not interaction.member or not interaction.data.custom_id then
            return
        end

        if interaction.data.custom_id == "legacyverification" then
            local link = sqldb:getLink(interaction.member.id)
            local linkedRoblox = link and link.roblox and ropi.GetUser(link.roblox)

            if link and link.discord and link.roblox and linkedRoblox then
                updateMember(interaction.member, "user updated themselves")
                local r = interaction:reply({
                    embed = {
                        title = emojis.roblox .. " Roblox Verification",
                        description = "> " .. emojis.link .. " You are currently linked with **" .. linkedRoblox.name ..
                            "**. If you would like to re-link with a different account, or unlink your Roblox account, press **Unlink** below.",
                        color = colors.info,
                        thumbnail = {
                            url = linkedRoblox.avatar
                        }
                    },
                    components = discordia.Components():button({
                        id = "unlink",
                        label = "Unlink",
                        emoji = resolvedEmojis.unlink,
                        style = "danger"
                    }):raw()
                }, true)

                onComp(r, "button", nil, interaction.user.id, true, function(ia)
                    local id = ia.data.custom_id

                    if id == "unlink" then
                        sqldb:unLink(interaction.member.id)

                        ia:update({
                            embed = {
                                title = emojis.roblox .. " Roblox Verification",
                                description = "> " .. emojis.success .. " You have been successfully unlinked from **" ..
                                    linkedRoblox.name .. "**.",
                                color = colors.success
                            },
                            components = {}
                        })
                        return true
                    end
                end)
                return
            end
            ask(interaction, "Roblox Username", "Enter your Roblox username...", nil, nil, "short", true, nil,
                function(_, mia, response)
                    if mia then
                        if response and response ~= "" then
                            local rblx = ropi.SearchUser(response)

                            if rblx then
                                local phrase = generatePhrase(7)

                                local r = mia:reply({
                                    embed = {
                                        title = emojis.roblox .. " Roblox Verification",
                                        description = "> Alright, **" .. rblx.name ..
                                            "**! Below, I have generated a phrase for you. Please place this phrase somewhere in your Roblox account's description. Once you have placed it into your description, press " ..
                                            emojis.yeswhite .. " **Done** below.\n```\n" .. phrase ..
                                            "```\n-# " .. emojis.right .. " If the phrase gets tagged, press **Regenerate Phrase** below.",
                                        thumbnail = {
                                            url = rblx.avatar
                                        },
                                        color = colors.info
                                    },
                                    components = discordia.Components():button({
                                        id = "done",
                                        label = "Done",
                                        emoji = resolvedEmojis.yeswhite,
                                        style = "success"
                                    }):button({
                                        id = "cancel",
                                        label = "Cancel",
                                        emoji = resolvedEmojis.nowhite,
                                        style = "danger"
                                    }):button({
                                        url = rblx.profile,
                                        label = "Go to Profile",
                                        style = "link",
                                        emoji = resolvedEmojis.roblox
                                    }):button({
                                        id = "regenerate",
                                        label = "Regenerate Phrase",
                                        style = "secondary",
                                        emoji = resolvedEmojis.settings
                                    })
                                }, true)

                                onComp(r, nil, nil, interaction.user.id, false, function(ia)
                                    local id = ia.data.custom_id
                                    if (not rblx) or not phrase then
                                        return
                                    end

                                    if id == "done" then
                                        rblx = ropi.GetUser(rblx.id, true)
                                        local desc = rblx.description or ""

                                        if desc:find(phrase) then
                                            local s, e = sqldb:link(interaction.member, rblx.id)

                                            if s then
                                                ia:update({
                                                    embed = {
                                                        title = emojis.roblox .. " Roblox Verification",
                                                        color = colors.success,
                                                        thumbnail = {
                                                            url = rblx.avatar
                                                        },
                                                        description = "> " .. emojis.success ..
                                                            " You have been successfully linked with **" .. rblx.name ..
                                                            "**."
                                                    },
                                                    components = {}
                                                })
                                                return true
                                            else
                                                ia:fail(e or "An unknown error occurred. Please try again later.", nil,
                                                    true)
                                                return
                                            end
                                        else
                                            ia:fail("It does not look like the phrase is in your description.", nil,
                                                true)
                                            return
                                        end
                                    elseif id == "cancel" then
                                        interaction:deleteReply(r.id)
                                        ia:updateDeferred(true)
                                        return true
                                    elseif id == "regenerate" then
                                        phrase = generatePhrase(7)
                                        ia:update({
                                            embed = {
                                                title = emojis.roblox .. " Roblox Verification",
                                                description = "> Alright, **" .. rblx.name ..
                                                    "**! Below, I have generated a phrase for you. Please place this phrase somewhere in your Roblox account's description. Once you have placed it into your description, press " ..
                                                    emojis.yeswhite .. " **Done** below.\n```\n" .. phrase ..
                                                    "```\n-# " .. emojis.right .. " If the phrase gets tagged, press **Regenerate Phrase** below.",
                                                thumbnail = {
                                                    url = rblx.avatar
                                                },
                                                color = colors.info
                                            },
                                            components = discordia.Components():button({
                                                id = "done",
                                                label = "Done",
                                                emoji = resolvedEmojis.yeswhite,
                                                style = "success"
                                            }):button({
                                                id = "cancel",
                                                label = "Cancel",
                                                emoji = resolvedEmojis.nowhite,
                                                style = "danger"
                                            }):button({
                                                url = rblx.profile,
                                                label = "Go to Profile",
                                                style = "link",
                                                emoji = resolvedEmojis.roblox
                                            }):button({
                                                id = "regenerate",
                                                label = "Regenerate Phrase",
                                                style = "secondary",
                                                emoji = resolvedEmojis.settings
                                            })
                                        })
                                    end
                                end)
                            else
                                mia:fail("I could not find that user.", nil, true)
                                return
                            end
                        else
                            mia:fail("You must provide your Roblox username.", nil, true)
                            return
                        end
                    end
                end)
        elseif interaction.data.custom_id == "verifypanelupdateme" then
            updateMember(interaction.member, "user updated themselves")

            return interaction:success("I have successfully updated you.", nil, true)
        elseif interaction.data.custom_id == "verifypanelbloxlink" then
            local guild = interaction.guild
            local member = interaction.member
            local config = sqldb:get(interaction.guild.id) or {}
            local usersettings = sqldb:getUserSettings(member.id) or {}

            if usersettings.bloxlinkoptout then
                return interaction:fail(
                    "You have opted out of verification through Bloxlink, you can change that in `/usersettings` command.",
                    nil, true)
            end

            if not config.bloxlinkServerKey then
                return interaction:fail("A bloxlink server key has not been configured on this server.", nil, true)
            end

            if not guild:getMember("426537812993638400") then
                return interaction:fail(
                    "The Bloxlink bot was not found in this server, which is required to use their API.", nil, true)
            end

            local hdrs = {{"Authorization", config.bloxlinkServerKey}}

            local result, body = _G.http.request("GET", "https://api.blox.link/v4/public/guilds/" .. guild.id ..
                "/discord-to-roblox/" .. member.id, hdrs)

            local success, bodyresult = pcall(json.decode, body)
            body = (body and (type(body) == "string") and success and bodyresult)

            if type(body) ~= "table" then
                return interaction:fail("The Bloxlink API returned an invalid response.", nil, true)
            end

            if result.code == 400 then
                return interaction:fail("The Bloxlink server key configured in this server is invalid.", nil, true)
            end

            if not body.robloxID or not tonumber(body.robloxID) then
                return interaction:fail("Bloxlink did not return a linked Roblox account, click " .. emojis.link ..
                                            " **Link** to verify.", nil, true)
            end

            body.robloxID = tonumber(body.robloxID)
            local robloxUser = ropi.GetUser(body.robloxID)

            if not robloxUser then
                return interaction:fail("I could not find the Roblox user that Bloxlink returned.", nil, true)
            end

            local existingLink = sqldb:getLink(body.robloxID)
            if existingLink then
                local existingDiscordUser = Client:getUser(existingLink.discord)

                return interaction:fail(getUserString(existingDiscordUser or existingLink.discord) ..
                                            " is already linked with " .. emojis.roblox .. " **" ..
                                            ((robloxUser and robloxUser.hyperlink) or tostring(existingLink.roblox)) ..
                                            "**.", nil, true)
            end

            local succ, err = sqldb:link(member, body.robloxID)

            if succ then
                return interaction:success("You have been successfully linked with " .. emojis.roblox .. " **" ..
                                               robloxUser.hyperlink .. "**.", nil, true)
            else
                return interaction:fail(err, nil, true)
            end
        end
    end)
end

verificationmodule.Stop = function()
    for event, listener in pairs(connections.Client) do
        _G.Client:removeListener(event, listener)
    end

    for event, listener in pairs(connections.DuckyAPI) do
        _G.DuckyAPI:removeListener(event, listener)
    end

    connections = nil
end
return verificationmodule