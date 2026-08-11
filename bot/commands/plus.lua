-- plus.lua
local slashCommand = tools.slashCommand("plus", "Manage your Ducky Plus+ subscription.")
local subcmd = tools.subCommand("manage", "Manage your Ducky Plus+ subscription.")
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("profile", "Modify Ducky's profile within your server.")
subcmd = subcmd:addOption(tools.string("nickname", "The nickname that Ducky should appear as within your server."):setRequired(false))
subcmd = subcmd:addOption(tools.string("bio", "The bio that Ducky should use on its profile within your server."):setRequired(false))
subcmd = subcmd:addOption(tools.attachment("avatar", "The avatar that Ducky should use on its profile within your server."):setRequired(false))
subcmd = subcmd:addOption(tools.attachment("banner", "The banner that Ducky should use on its profile within your server."):setRequired(false))
local option = tools.string("preset", "The profile preset to use."):setRequired(false)

local profilePresets = {
    ducky = {
        name = "Ducky",
        -- profile = {
        --     nick = "Ducky",
        --     bio = nil,
        --     avatar = "images/avatars/Ducky.png",
        --     banner = "images/banners/Ducky.png"
        -- }
        profile = {}
    },
    plus = {
        name = "Ducky Plus+",
        profile = {
            nick = "Ducky Plus+",
            bio = emojis.right .. " The " .. emojis.duckyplus .. " **Plus+** version of " .. emojis.ducky .. " **Ducky**.\n\n" .. emojis.web .. " https://duckybot.xyz/",
            avatar = "images/avatars/Plus.png",
            banner = "images/banners/Plus.png"
        }
    },
    frankenduck = {
        name = "Frankenduck (2025 Halloween Logo)",
        profile = {
            nick = "Ducky",
            bio = nil,
            avatar = "images/avatars/Frankenduck.png",
            banner = "images/banners/Frankenduck.png"
        }
    },
    skeleduck = {
        name = "Skeleduck (2025 Halloween Logo #2)",
        profile = {
            nick = "Ducky",
            bio = nil,
            avatar = "images/avatars/Skeleduck.png",
            banner = "images/banners/Skeleduck.png"
        }
    },
    cozyducky = {
        name = "Cozy Ducky (2025 Christmas Logo)",
        profile = {
            nick = "Cozy Ducky",
            bio = nil,
            avatar = "images/avatars/CozyDucky.png",
            banner = "images/banners/CozyDucky.png"
        }
    }
}

for i, preset in pairs(profilePresets) do
    option = option:addChoice(tools.choice(preset.name, tostring(i)))
end

subcmd = subcmd:addOption(option)
slashCommand = slashCommand:addOption(subcmd)

local discountCodes = {
    ["dev"] = {
        discount = 99,
        verify = function(user)
            return hasPermission(user, "BOT_DEVELOPER")
        end
    },
    ["TENTHOUSAND"] = {
        discount = 30,
        expires = 1769630400
    }
}

local function debug(str)
    if true then
        utilityChannels.development:send(str)
    end
end

local lastUsed = {}
local checkPurchaseCooldowns = {}
local groupTransactionsCache = nil
local lastGroupTransactionsUpdate = 0
local DEBOUNCE_DURATION = 300
local checkPurchaseCooldown = 60

local function checkTransaction(robloxID, assetID, assetPrice)
    if (assetPrice <= 0) or (robloxID == 1038671897) then return {
        price = 0,
        token = "free"
    } end

    local now = os.time()
    if not groupTransactionsCache or (now - lastGroupTransactionsUpdate) >= 30 then
        local success, transactions = pcall(ropi.GetGroupTransactions, 34493757)
        if success and transactions then
            groupTransactionsCache = transactions
            lastGroupTransactionsUpdate = now
        end
    end

    local transactions = groupTransactionsCache
    if not transactions then return nil end

    for i, transaction in pairs(transactions) do
        if transaction and transaction.user and transaction.item and transaction.created and transaction.user.id == robloxID and transaction.price == assetPrice and sqldb:plusTransaction(transaction.token) == nil then
            return transaction
        end
    end
end

_G.checkTransaction = checkTransaction

local function calculateTotal(slots, code)
    local total = slots * 1000
    local discount = (code and discountCodes[code] and (discountCodes[code].discount / 100) and (discountCodes[code].discount / 100) * total) or 0

    return total - discount
end

local function calculateSlots(paid, code, slots)
    if paid <= 0 then
        return slots
    end

    local discountMultiplier = 1

    if code and discountCodes[code] then
        discountMultiplier = 1 - (discountCodes[code].discount / 100)
    end

    local slotPrice = 1000 * discountMultiplier
    slots = math.clamp(math.floor(paid / slotPrice), 1, 10)

    return slots
end

local function getAsset()
    for _, asset in pairs(duckyplusassets) do
        if not asset.using then
            asset.using = true
            return asset
        end
    end
end

local function unuseAsset(asset)
    if not asset then return end

    for _, a in pairs(duckyplusassets) do
        if a.id == asset.id then
            a.using = false
        end
    end
end

return {
    name = "plus",
    description = "Manage your Ducky Plus+ subscription.",
    aliases = { "duckyplus", "dp", "subscription", "+" },
    subcommands = {
        profile = {
            "custom",
            "customize",
            "whitelabel"
        },
        "manage"
    },
    category = "Ducky Plus+",
    slashCommand = slashCommand,
    requiredPermissions = {},
    hybridCallback = function(interaction, args, slash, subcmd)
        if (not slash) and subcmd then
            table.remove(args, 1)
        end

        if subcmd == "manage" then
            local r = interaction:loading("Fetching " .. emojis.duckyplus .. " **Ducky Plus+** data...")
            local loadingMessage = nil

            if type(r) ~= "table" then
                interaction:fail("Something went wrong, **please try again**.", nil, true)
            end

            local active, plus = sqldb:plusMember(interaction.member)
            local link = sqldb:getLink(interaction.user.id)
            local roblox = link and link.roblox and ropi.GetUser(link.roblox)
            local activeTransaction = nil

            local function updateEmbed(ia)
                if ia and loadingMessage then
                    ia:deleteReply(loadingMessage.id)
                    loadingMessage = nil
                elseif ia then
                    coroutine.wrap(function()
                        ia:updateDeferred(true)
                    end)()
                end

                local comps = discordia.Components()
                local embed = {
                    title = emojis.duckyplus .. " Ducky Plus+",
                    author = {
                        name = interaction.member.name,
                        icon_url = interaction.member.avatarURL
                    },
                    image = { url = "https://duckybot.xyz/images/banners/footers/plus.png" },
                    thumbnail = { url = resolvedEmojis.duckyplus.image }
                }

                if not activeTransaction then
                    comps:button({
                        id = "purchaseslot",
                        label = "Purchase Slot",
                        style = "success",
                        emoji = resolvedEmojis.plus
                    })

                    if active and plus and (plus.slots > 0 or table.count(plus.guilds) > 0) then
                        embed.description = "You are a " .. emojis.duckyplus .. " **Ducky Plus+** member. Thank you for your support!\n\n" .. emojis.right .. " **Slots:** " .. plus.slots .. "\n" .. emojis.right .. " **Guilds:**\n" .. emojis.space .. emojis.right .. " " .. (table.count(plus.guilds) > 0 and table.concatFn(plus.guilds, "\n" .. emojis.space .. emojis.right, function(g)
                            local guild = Client:getGuild(g)

                            if guild then
                                return guild.name .. " (`" .. guild.id .. "`)"
                            else
                                return emojis.error .. " Removed (`" .. g .. "`)"
                            end
                        end) or "None") .. "\n-# " .. emojis.right .. " " .. emojis.duckyplus .. " **Ducky Plus+** is a one-time purchase of " .. emojis.robux .. " **1,000** per guild."

                        embed.color = colors.success

                        if table.count(plus.guilds) > 0 then
                            comps:button({
                                id = "refundslot",
                                style = "danger",
                                label = "Refund Slot",
                                emoji = resolvedEmojis.undo
                            })
                        end
                        
                        if plus.slots > 0 then
                            comps:button({
                                id = "useslot",
                                style = "primary",
                                label = "Use Slot",
                                emoji = resolvedEmojis.guild
                            })

                            comps:button({
                                id = "giftslot",
                                style = "primary",
                                label = "Gift Slot",
                                emoji = resolvedEmojis.gift
                            })
                        end
                    else
                        embed.description = emojis.right .. " You are not a **Ducky Plus+** member. To get started, press " .. emojis.plus .. " **Purchase Slot** below.\n-# " .. emojis.right .. " " .. emojis.duckyplus .. " **Ducky Plus+** is a one-time purchase of " .. emojis.robux .. " **1,000** per guild."
                        embed.color = colors.fail
                    end

                    comps:button({
                        style = "link",
                        url = "https://duckybot.xyz/legal/terms",
                        emoji = resolvedEmojis.book
                    })
                elseif activeTransaction and (not activeTransaction.start) then
                    embed.color = colors.info
                    embed.description = "You have initiated a transaction. Please review the details below and confirm them by pressing " .. emojis.yeswhite .. " **Confirm**. Press " .. emojis.nowhite .. " **Cancel** to cancel this transaction. If you have a discount code, apply it now by pressing " .. emojis.sale .. " **Apply Discount Code**. To add or remove the amount of slots you are purchasing, use the " .. emojis.plus .. " **/** " .. emojis.minus .. " buttons.\n\n" .. emojis.right .. " **Roblox Account:** " .. roblox.hyperlink .. "\n" .. emojis.right .. " **Discount Code:** " .. ((activeTransaction.code and ("`" .. activeTransaction.code .. "` (" .. discountCodes[activeTransaction.code].discount .. "% off)")) or "N/A") .. "\n" .. emojis.right .. " **Slots:** +" .. activeTransaction.slots .. "\n" .. emojis.right .. " **Total:** " .. emojis.robux .. " " .. formatNumber(calculateTotal(activeTransaction.slots, activeTransaction.code))

                    comps:button({
                        style = "success",
                        label = "Confirm",
                        emoji = resolvedEmojis.yeswhite,
                        id = "confirm"
                    })

                    comps:button({
                        style = "danger",
                        emoji = resolvedEmojis.nowhite,
                        id = "cancel"
                    })

                    comps:button({
                        style = "blurple",
                        emoji = resolvedEmojis.sale,
                        id = "applycode"
                    })

                    comps:button({
                        style = "secondary",
                        emoji = resolvedEmojis.plus,
                        id = "addslot",
                        disabled = activeTransaction.slots >= 10
                    })

                    comps:button({
                        style = "secondary",
                        emoji = resolvedEmojis.minus,
                        id = "subtractslot",
                        disabled = activeTransaction.slots <= 1
                    })
                elseif activeTransaction.start then
                    embed.color = colors.info
                    embed.description = "To complete your transaction, press the " .. emojis.roblox .. " **Asset** link to be taken to the Roblox asset. Once you purchase it, you will automatically receive your slots.\n-# " .. emojis.warning .. " If you do not receive your slots automatically, press " .. emojis.reload .. " **Check Purchase**. Please be patient and **do not spam our systems**, it can take a while to process your transaction.\n\n" .. emojis.right .. " **Roblox Account:** " .. roblox.hyperlink .. "\n" .. emojis.right .. " **Discount Code:** " .. ((activeTransaction.code and ("`" .. activeTransaction.code .. "` (" .. discountCodes[activeTransaction.code].discount .. "% off)")) or "N/A") .. "\n" .. emojis.right .. " **Slots:** +" .. activeTransaction.slots .. "\n" .. emojis.right .. " **Total:** " .. emojis.robux .. " " .. formatNumber(calculateTotal(activeTransaction.slots, activeTransaction.code))

                    activeTransaction.check = function()
                        if (not activeTransaction) or (activeTransaction.checking) then return end
                        activeTransaction.checking = true

                        debug("Plus transaction check (ID = " .. interaction.user.id .. "): Start")

                        local price = calculateTotal(activeTransaction.slots, activeTransaction.code)
                        debug("Plus transaction check (ID = " .. interaction.user.id .. "): Calculated slots")
                        local transaction = checkTransaction(roblox.id, activeTransaction.asset and activeTransaction.asset.id, price)
                        debug("Plus transaction check (ID = " .. interaction.user.id .. "): Checked transaction")

                        if transaction then
                            debug("Plus transaction check (ID = " .. interaction.user.id .. "): Found transaction")
                            unuseAsset(activeTransaction.asset)
                            debug("Plus transaction check (ID = " .. interaction.user.id .. "): Unused asset")

                            local success, err = sqldb:plusPurchase(interaction.user, calculateSlots(transaction.price, activeTransaction.code, activeTransaction.slots), activeTransaction.code and {
                                code = activeTransaction.code,
                                percentage = discountCodes[activeTransaction.code].discount
                            } or nil, price, roblox, transaction.token)
                            debug("Plus transaction check (ID = " .. interaction.user.id .. "): plusPurchase done")

                            if success then
                                active = true
                                plus = err

                                activeTransaction = nil
                                pcall(updateEmbed)
                                return true
                            else
                                activeTransaction = nil
                                pcall(updateEmbed)
                                return false, tostring(err)
                            end
                        else
                            debug("Plus transaction check (ID = " .. interaction.user.id .. "): No transaction found")
                        end

                        if activeTransaction then
                            activeTransaction.checking = false
                        end

                        return false, "No transaction found."
                    end

                    comps:button({
                        style = "link",
                        url = "https://www.roblox.com/catalog/" .. ((activeTransaction.asset and activeTransaction.asset.id) or 0) .. "/Ducky-Plus",
                        emoji = resolvedEmojis.roblox,
                        label = "Asset"
                    })

                    comps:button({
                        style = "secondary",
                        emoji = resolvedEmojis.reload,
                        id = "checkpurchase"
                    })

                    comps:button({
                        style = "danger",
                        emoji = resolvedEmojis.nowhite,
                        id = "cancel"
                    })

                    coroutine.wrap(function()
                        local loopStart = os.time()
                        repeat
                            timer.sleep(31000)
                            if (os.time() - loopStart) >= 360 then break end
                            if activeTransaction and not activeTransaction.checking then
                                if activeTransaction.check() then
                                    break
                                end
                            end
                        until (not activeTransaction) or (not activeTransaction.asset) or ((os.time() - activeTransaction.start) >= 300)

                        if activeTransaction and activeTransaction.start and ((os.time() - activeTransaction.start) >= 300) then
                            local t = activeTransaction
                            activeTransaction = nil
                            unuseAsset(t.asset)
                            pcall(updateEmbed)
                            interaction.user:send(emojis.error .. " Your " .. emojis.duckyplus .. " **Ducky Plus+** transaction timed out.")
                        end
                    end)()
                end

                r:update({
                    embed = embed,
                    components = comps:raw()
                })
            end

            updateEmbed()

            onComp(r, nil, nil, interaction.user.id, false, function(ia)
                local id = ia.data.custom_id

                if id == "purchaseslot" then
                    loadingMessage = ia:loading("Doing duck stuff...", true)

                    if type(loadingMessage) ~= "table" then
                        return ia:fail("Something went wrong, **please try again**.", nil, true)
                    end

                    local now = os.time()
                    local userSettings = sqldb:getUserSettings(interaction.user.id) or {}
                    local lastTime = userSettings.lastPlusTransaction or 0

                    if lastTime and (now - lastTime) < DEBOUNCE_DURATION then
                        ia:deleteReply(loadingMessage.id)
                        return ia:fail("You recently initiated a transaction. You can initiate another transaction <t:" .. (lastTime + DEBOUNCE_DURATION) .. ":R>.", nil, true)
                    end

                    if roblox then
                        userSettings.lastPlusTransaction = now
                        sqldb:setUserSettings(interaction.user.id, userSettings)

                        activeTransaction = {
                            slots = 1,
                            start = nil,
                            code = nil,
                            asset = nil,
                            total = 1000
                        }
                    
                        updateEmbed(ia)
                    else
                        ia:deleteReply(loadingMessage.id)
                        return ia:fail("You do not have your Roblox account linked. Run `/link` to get started.", nil, true)
                    end
                elseif id == "refundslot" then
                    prompt(ia, "Refund Slot", {
                        {
                            question = "Guild ID",
                            placeholder = "Enter the guild's ID...",
                            style = "short",
                            required = false
                        }
                    }, function(mia, responses)
                        if mia then
                            if responses and responses["Guild ID"] then
                                local id = responses["Guild ID"]
                                local guildObject = Client:getGuild(id)
                                local guildDisplay = (guildObject and guildObject.name) or id
                                local guildActive, guildPlus = sqldb:plusGuild(id)

                                if (guildActive) and (guildPlus) and (guildPlus.userid == interaction.user.id) then
                                    mia:updateDeferred(true)

                                    confirm(ia, "Are you sure you would like to refund your " .. emojis.duckyplus .. " **Ducky Plus+** slot from **" .. guildDisplay .. "**?\n" .. emojis.error .. " ***This will disable features that were enabled using increased limits.***", function(result, ria, r)
                                        if result == true then
                                            ria:updateDeferred(true)
                                            ria:editReply({
                                                embed = {
                                                    description = emojis.loading,
                                                    color = colors.blank
                                                },
                                                components = {}
                                            }, r.id)

                                            local success, err = sqldb:plusRefund(interaction.user, id)

                                            if success then
                                                active = true
                                                plus = err

                                                ria:editReply({
                                                    embed = {
                                                        description = emojis.success .. " Your " .. emojis.duckyplus .. " **Ducky Plus+** slot has been refunded from **" .. guildDisplay .. "**.",
                                                        color = colors.success
                                                    },
                                                    components = {}
                                                }, r.id)
                                                updateEmbed()
                                            else
                                                ria:editReply({
                                                    embed = {
                                                        description = emojis.fail .. " " .. tostring(err),
                                                        color = colors.fail
                                                    },
                                                    components = {}
                                                }, r.id)
                                            end
                                        elseif result == false then
                                            ria:updateDeferred(true)
                                            ria:deleteReply(r.id)
                                        end
                                    end, nil, 10000)
                                else
                                    mia:fail("You are not providing " .. emojis.duckyplus .. " **Ducky Plus+** for **" .. guildDisplay .. "**.", nil, true)
                                end
                            else
                                mia:updateDeferred(true)
                            end
                        end
                    end)
                elseif id == "useslot" then
                    prompt(ia, "Use Slot", {
                        {
                            question = "Guild ID",
                            placeholder = "Enter the guild's ID...",
                            style = "short",
                            required = false
                        }
                    }, function(mia, responses)
                        if mia then
                            if responses and responses["Guild ID"] then
                                local id = responses["Guild ID"]
                                local guild = Client:getGuild(id)

                                if guild then
                                    local guildActive, guildPlus = sqldb:plusGuild(guild)

                                    if (not guildActive) and (not guildPlus) then
                                        local success, err = sqldb:plusUse(interaction.user, guild)
                                        guild:setProfile(profilePresets.plus.profile)

                                        if success then
                                            active = true
                                            plus = err

                                            mia:success("One of your " .. emojis.duckyplus .. " **Ducky Plus+** slots has been applied to **" .. guild.name .. "**.", nil, true)
                                            utilityChannels.receipts:send(emojis.guild .. " **@" .. interaction.user.username .. "** (" .. interaction.user.id .. ") has applied one of their " .. emojis.duckyplus .. " **Ducky Plus+** slots to **" .. guild.name .. "** (" .. guild.id .. ").")
                                            updateEmbed()
                                        else
                                            mia:fail(err, nil, true)
                                        end
                                    else
                                        local provider = Client:getUser(guildPlus.userid)
                                        mia:fail("**@" .. provider.username .. "** is already providing " .. emojis.duckyplus .. " **Ducky Plus+** for **" .. guild.name .. "**.", nil, true)
                                    end
                                else
                                    mia:fail("That guild was not found.", nil, true)
                                end
                            else
                                mia:updateDeferred(true)
                            end
                        end
                    end)
                elseif id == "giftslot" then
                    prompt(ia, "Gift Slot", {
                        {
                            question = "User ID",
                            placeholder = "Enter the target user's ID...",
                            style = "short",
                            required = false
                        }
                    }, function(mia, responses)
                        if mia then
                            if responses and responses["User ID"] then
                                local id = responses["User ID"]
                                local target = Client:getUser(id)

                                if target then
                                    local success, err = sqldb:plusGift(interaction.user, target)

                                    if success then
                                        active = true
                                        plus = err

                                        mia:success("**@" .. target.username .. "** has received one of your " .. emojis.duckyplus .. " **Ducky Plus+** slots.", nil, true)
                                        target:send(emojis.gift .. " **@" .. interaction.user.username .. "** (" .. interaction.user.id .. ") has gifted you one of their " .. emojis.duckyplus .. " **Ducky Plus+** slots.")
                                        utilityChannels.receipts:send(emojis.gift .. " **@" .. interaction.user.username .. "** (" .. interaction.user.id .. ") gifted a " .. emojis.duckyplus .. " **Ducky Plus+** slot to **@" .. target.username .. "** (" .. target.id .. ").")
                                        updateEmbed()
                                    else
                                        mia:fail(err, nil, true)
                                        updateEmbed()
                                    end
                                else
                                    mia:fail("That user was not found.", nil, true) 
                                    updateEmbed()
                                end
                            else
                                mia:updateDeferred(true)
                            end
                        end
                    end)
                elseif id == "confirm" then
                    if not activeTransaction then return ia:fail("No active transaction found.", nil, true) end
                    if calculateTotal(activeTransaction.slots, activeTransaction.code) <= 0 then
                        activeTransaction.start = os.time()
                        updateEmbed(ia)
                        utilityChannels.receipts:send(emojis.loading .. " **@" .. interaction.user.username .. "** initiated a transaction.\n-# " .. emojis.guild .. " " .. activeTransaction.slots .. "・" .. emojis.sale .. " `" .. (activeTransaction.code or "N/A") .. "`・" .. emojis.robux .. " " .. calculateTotal(activeTransaction.slots, activeTransaction.code) .. "・" .. emojis.roblox .. " " .. roblox.hyperlink)
                    else
                        loadingMessage = ia:loading("Doing duck stuff...", true)

                        if type(loadingMessage) ~= "table" then
                            return ia:fail("Something went wrong, **please try again**.", nil, true)
                        end

                        activeTransaction.asset = getAsset()

                        if activeTransaction.asset then
                            local success, err = ropi.SetAssetPrice(activeTransaction.asset.collectible, calculateTotal(activeTransaction.slots, activeTransaction.code))

                            if success then
                                activeTransaction.start = os.time()
                                updateEmbed(ia)
                                utilityChannels.receipts:send(emojis.loading .. " **@" .. interaction.user.username .. "** initiated a transaction.\n-# " .. emojis.guild .. " " .. activeTransaction.slots .. "・" .. emojis.sale .. " `" .. (activeTransaction.code or "N/A") .. "`・" .. emojis.robux .. " " .. calculateTotal(activeTransaction.slots, activeTransaction.code) .. "・" .. emojis.roblox .. " " .. roblox.hyperlink)
                            else
                                unuseAsset(activeTransaction.asset)
                                activeTransaction.asset = nil

                                utilityChannels.development:send("Epic asset price change fail: ```" .. cjson.encode(err) .. "```")

                                ia:deleteReply(loadingMessage.id)
                                ia:fail("An unexpected error occurred while attempting to set the asset's price: ```" .. tostring(err) .. "```", nil, true)
                            end
                        else
                            ia:deleteReply(loadingMessage.id)
                            ia:fail("There are too many active transactions. Please try again in a few minutes.", nil, true)
                        end
                    end
                elseif id == "cancel" then
                    if not activeTransaction then return ia:updateDeferred(true) end
                    unuseAsset(activeTransaction.asset)
                    activeTransaction = nil
                    updateEmbed(ia)
                elseif id == "applycode" then
                    prompt(ia, "Apply Discount Code", {
                        {
                            question = "Discount Code",
                            placeholder = "Enter your discount code here... (case-sensitive!)",
                            style = "short",
                            required = false
                        }
                    }, function(mia, responses)
                        if mia and responses then
                            local code = responses["Discount Code"] ~= "" and responses["Discount Code"]
                            if discountCodes[code] then
                                if discountCodes[code].verify and not discountCodes[code].verify(interaction.user) then
                                    mia:fail("You are not permitted to use this discount code.", nil, true)
                                    return updateEmbed()
                                elseif discountCodes[code].expires and (os.time() >= discountCodes[code].expires) then
                                    mia:fail("This discount code has expired.", nil, true)
                                    return updateEmbed()
                                elseif discountCodes[code].maxUses and plus and plus.codes and plus.codes[code] and plus.codes[code] >= discountCodes[code].maxUses then
                                    mia:fail("You have already used this discount code " .. plus.codes[code] .. "/" .. discountCodes[code].maxUses .. " times.", nil, true)
                                    return updateEmbed()
                                end
                                activeTransaction.code = code
                                mia:updateDeferred(true)
                            else
                                mia:fail("That code is invalid or expired.", nil, true)
                                updateEmbed()
                            end
                            mia:updateDeferred(true)
                            updateEmbed()
                        else
                            mia:updateDeferred(true)
                        end
                    end)
                elseif id == "addslot" then
                    if not activeTransaction then return ia:updateDeferred(true) end
                    activeTransaction.slots = math.clamp(activeTransaction.slots + 1, 1, 10)
                    updateEmbed(ia)
                elseif id == "subtractslot" then
                    if not activeTransaction then return ia:updateDeferred(true) end
                    activeTransaction.slots = math.clamp(activeTransaction.slots - 1, 1, 10)
                    updateEmbed(ia)
                elseif id == "checkpurchase" and activeTransaction and activeTransaction.check then
                    local now = os.time()
                    local lastCheck = checkPurchaseCooldowns[interaction.user.id] or 0
                    if (now - lastCheck) < checkPurchaseCooldown then
                        return ia:fail("Please wait at least **" .. (checkPurchaseCooldown - (now - lastCheck)) .. " seconds** before checking again. Roblox can take up to a minute to process transactions.", nil, true)
                    end
                    checkPurchaseCooldowns[interaction.user.id] = now
                    if activeTransaction and activeTransaction.check and not activeTransaction.checking then
                        loadingMessage = ia:loading("Doing duck stuff...", true)

                        if type(loadingMessage) ~= "table" then
                            return ia:fail("Something went wrong, **please try again**.", nil, true)
                        end

                        local pcallok, resultorpcallerr, err = pcall(activeTransaction.check)

                        if not pcallok then
                            ia:fail("An unexpected error occurred whuke trying to check your purchase: ```" .. tostring(resultorpcallerr) .. "```", nil, true)
                        elseif not resultorpcallerr then
                            ia:fail("Something went wrong while trying to check your purchase: ```" .. tostring(err) .. "```", nil, true)
                        else
                            ia:updateDeferred(true)
                        end
                    end
                end
            end)
        elseif subcmd == "profile" or subcmd == "custom" or subcmd == "customize" or subcmd == "whitelabel" then
            if (not hasPermission(interaction.member, "MANAGE_SERVER", nil, interaction)) or (not hasPermission(interaction.member, "DUCKY_PLUS_GUILD", nil, interaction)) then return end

            if lastUsed[interaction.guild.id] and ((os.time() - lastUsed[interaction.guild.id]) <= 300) then
                return interaction:fail("You must wait **" .. readable((lastUsed[interaction.guild.id] + 300) - os.time()) .. "** before updating Ducky's profile within this server again.", nil, true)
            end

            local r = interaction:loading()

            local function success(str)
                if type(r) == "table" then
                    r:update({embed = {description = emojis.success .. " " .. str, color = colors.success}})
                else
                    r = interaction:success(str)
                end
            end

            local function fail(str)
                if type(r) == "table" then
                    r:update({embed = {description = emojis.fail .. " " .. str,color = colors.fail}})
                else
                    r = interaction:fail(str)
                end
            end

            local nickname = (slash and args and args.nickname) or ((not slash) and args and table.concat(args)) or nil
            local bio = (slash and args and args.bio) or nil
            local avatar = (slash and args and args.avatar and urlToImage(args.avatar.url)) or nil
            local banner = (slash and args and args.banner and urlToImage(args.banner.url)) or nil

            local profile = (slash and args and args.preset and profilePresets[args.preset] and profilePresets[args.preset].profile) or {
                nick = nickname or profilePresets.plus.profile.nick,
                bio = bio or profilePresets.plus.profile.bio,
                avatar = avatar or profilePresets.plus.profile.avatar,
                banner = banner or profilePresets.plus.profile.banner
            }

            local succ, err = interaction.guild:setProfile(profile)

            if succ then
                lastUsed[interaction.guild.id] = os.time()

                return success("Ducky's profile within this server has been successfully " .. (((nickname or bio or avatar or banner or args.preset) and "updated") or "reset") .. ".")
            else
                return fail("An error occurred while attempting to update Ducky's profile within this server. Please try again in a few minutes. ```" .. err .. "```")
            end
        end
    end
}
