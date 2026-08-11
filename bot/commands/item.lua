-- item.lua
local slashCommand = tools.slashCommand("item", "Use Ducky's shop module.")

local subcmd = tools.subCommand("shop", "View the item shop.")
slashCommand = slashCommand:addOption(subcmd)

local subcmd = tools.subCommand("buy", "Buy an item from the item shop.")
subcmd = subcmd:addOption(tools.string("item", "The item to buy."):setRequired(true):setAutocomplete(true))
slashCommand = slashCommand:addOption(subcmd)

local subcmd = tools.subCommand("use", "Use an item from your inventory.")
subcmd = subcmd:addOption(tools.string("item", "The item to use."):setRequired(true):setAutocomplete(true))
slashCommand = slashCommand:addOption(subcmd)

local subcmd = tools.subCommand("inventory", "View your inventory.")
slashCommand = slashCommand:addOption(subcmd)

local subcmd = tools.subCommand("info", "View information about a specific item.")
subcmd = subcmd:addOption(tools.string("item", "The item to view."):setRequired(true):setAutocomplete(true))
slashCommand = slashCommand:addOption(subcmd)

return {
    name = "item",
    description = "Use Ducky's shop module.",
    category = "Economy",
    subcommands = {
        "shop",
        "buy",
        "use",
        "inventory",
        "info"
    },
    aliases = {},
    slashCommand = slashCommand,
    autocomplete = function(interaction, command, focused, args)
        local guild = interaction.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.shop = config.economy.shop or {}

        if config.economy and config.economy.disabled then
			return interaction:fail("The " .. emojis.quack .. " **Economy** module is not enabled in this server.")
		end

        local subcmd
        for k, v in pairs(args) do
            if type(v) == "table" then
                subcmd = k
                break
            end
        end

        if focused and subcmd == "buy" and focused.name == "item" then
            local opts = {}
            local query = (focused.value and focused.value:lower()) or ""

            for _, shopItem in ipairs(config.economy.shop) do
                if not query or shopItem.name:lower():find(query, 1, true) then
                    table.insert(opts, {
                        name = shopItem.name,
                        value = shopItem.id
                    })
                end
            end

            return interaction:autocomplete(opts)

        elseif focused and subcmd == "info" and focused.name == "item" then
            local opts = {}
            local query = (focused.value and focused.value:lower()) or ""

            for _, shopItem in ipairs(config.economy.shop) do
                if not query or shopItem.name:lower():find(query, 1, true) then
                    table.insert(opts, {
                        name = shopItem.name,
                        value = shopItem.id
                    })
                end
            end

            return interaction:autocomplete(opts)

        elseif focused and subcmd == "use" and focused.name == "item" then
            local opts = {}
            local query = (focused.value and focused.value:lower()) or ""

            for _, shopItem in ipairs(config.economy.shop) do
                local item, hasItem = db:ecoItem(interaction.member, shopItem.id)
                if item and hasItem then
                    if shopItem.name:lower():find(query, 1, true) then
                        table.insert(opts, {
                            name = shopItem.name,
                            value = shopItem.id
                        })
                    end
                end
            end

		    return interaction:autocomplete(opts)
        end
    end,
    hybridCallback = function(interaction, args, slash, subcmd)
        local guild = interaction.guild
		local config = sqldb:get(guild.id) or {}
		config.economy = config.economy or {}
		config.economy.shop = config.economy.shop or {}

        if subcmd == "shop" then
            if not config.economy.shop or (not next(config.economy.shop)) then
                return interaction:fail("No items have been configured in the shop.", nil, true)
            end
            local emb = {
                title = emojis.shop .. " Shop",
                color = colors.info,
                fields = {}
            }
            local pages = {}
            
            for c, item in pairs(config.economy.shop) do
                table.insert(emb.fields, {
                    name = item.name,
                    value = emojis.right .. " **Description:** " .. (item.description or emojis.fail) .. "\n" ..
                        emojis.right .. " **Price:** " .. (config.economy.currency or emojis.quack) .. " " .. formatNumber(tonumber(item.price)) .. "\n" ..
                        emojis.right .. " **Role:** " .. ((item.role and "<@&" .. item.role .. ">") or emojis.fail) .. "\n" ..
                        emojis.right .. " **Use on Purchase:** " .. ((item.useonpurchase and emojis.success) or emojis.fail)
                })

                if c >= 4 or c == #config.economy.shop then
                    table.insert(pages, emb)
                    emb = {
                        title = emojis.shop .. " Shop",
                        color = colors.info,
                        fields = {}
                    }
                end
            end
            
            return _G.paginate(interaction, pages, interaction.user, {teleport = true})

        elseif subcmd == "buy" then
            local account, err = db:ecoFetch(interaction.member)
            if not account then
                return interaction:fail(err, nil, true)
            end

            local item

            if slash then
                local itemId = args.item
                item = db:ecoItem(interaction.member, itemId)
            else
                local name = table.remove(args, 1) and table.concat(args, " ")
                for _, v in pairs(config.economy.shop) do
                    if v.name:lower() == name:lower() then
                        item = v
                        break
                    end
                end

                if not item then
                    local possible = {}
                    for _, v in pairs(config.economy.shop) do
                        if string.levenshtein(v.name:lower(), name:lower()) < 4 then
                            table.insert(possible, v.name)
                        end
                    end

                    if #possible > 0 then
                        local possibleemb = {
                            description = emojis.fail .. " I could not find that item. Did you mean...",
                            color = colors.fail
                        }

                        for _, p in pairs(possible) do
                            possibleemb.description = possibleemb.description .. "\n" .. emojis.right .. " " .. p
                        end

                        return interaction:reply({
                            embed = possibleemb
                        }, true)
                    end

                    return interaction:reply({
                        embed = {
                            description = emojis.fail .. " I could not find that item.",
                            color = colors.fail
                        }
                    }, true)
                end
            end

            if not item then
                return interaction:fail("You did not provide a valid item.", nil, true)
            end

            local success, err = db:ecoPurchase(interaction.member, item.id)
            if not success then
                return interaction:fail(err, nil, true)
            end

            if item.useonpurchase then
                local success, err, gaveRole = db:ecoItemUse(interaction.member, item.id)
                if not success then
                    return interaction:fail(err, nil, true)
                end

                local parsed = nil
                if item.message and item.message ~= "" then
                    local replaced = parseTable({ message = item.message }, {
                        ["item.name"] = (item.name and item.name ~= "" and item.name) or "N/A",
                        ["item.id"] = (item.id and item.id ~= "" and item.id) or "N/A",
                        ["item.price"] = (item.price and item.price ~= "" and formatNumber(tonumber(item.price))) or "N/A",
                        ["economy.currency"] = (config.economy and config.economy.currency) or emojis.quack,
                        ["user.name"] = interaction.user.name,
                        ["user.username"] = interaction.user.username,
                        ["user.id"] = interaction.user.id,
                        ["user.mention"] = "<@" .. interaction.user.id .. ">",
                        ["timestamp"] = tostring(os.time())
                    })
                    parsed = replaced and replaced.message
                end

                if parsed then
                    return interaction:reply({
                        embed = {
                            description = parsed,
                            color = colors.success
                        },
                    })
                end

                if gaveRole then
                    return interaction:success("You purchased **" .. item.name .. "** and have been given <@&" .. item.role .. ">.")
                else
                    return interaction:success("You purchased **" .. item.name .. "** and it was used directly.")
                end
            end

            return interaction:success("You have purchased **" .. item.name .. "**.")

        elseif subcmd == "use" then
            local account, err = db:ecoFetch(interaction.member)
            if not account then
                return interaction:fail(err, nil, true)
            end

            local item

            if slash then
                local itemId = args.item
                item = db:ecoItem(interaction.member, itemId)
            else
                local name = table.remove(args, 1) and table.concat(args, " ")
                for _, v in pairs(config.economy.shop) do
                    if v.name:lower() == name:lower() then
                        item = v
                        break
                    end
                end

                if not item then
                    local possible = {}
                    for _, v in pairs(config.economy.shop) do
                        if string.levenshtein(v.name:lower(), name:lower()) < 4 then
                            table.insert(possible, v.name)
                        end
                    end

                    if #possible > 0 then
                        local possibleemb = {
                            description = emojis.fail .. " I could not find that item. Did you mean...",
                            color = colors.fail
                        }

                        for _, p in pairs(possible) do
                            possibleemb.description = possibleemb.description .. "\n" .. emojis.right .. " " .. p
                        end

                        return interaction:reply({
                            embed = possibleemb
                        }, true)
                    end

                    return interaction:reply({
                        embed = {
                            description = emojis.fail .. " I could not find that item.",
                            color = colors.fail
                        }
                    }, true)
                end
            end

            if not item then
                return interaction:fail("You did not provide a valid item.", nil, true)
            end

            local success, err, gaveRole = db:ecoItemUse(interaction.member, item.id)
            if not success then
                return interaction:fail(err, nil, true)
            end

            local parsed = nil
            if item.message and item.message ~= "" then
                local replaced = parseTable({ message = item.message }, {
                    ["item.name"] = (item.name and item.name ~= "" and item.name) or "N/A",
                    ["item.id"] = (item.id and item.id ~= "" and item.id) or "N/A",
                    ["item.price"] = (item.price and item.price ~= "" and formatNumber(tonumber(item.price))) or "N/A",
                    ["economy.currency"] = (config.economy and config.economy.currency) or emojis.quack,
                    ["user.name"] = interaction.user.name,
                    ["user.username"] = interaction.user.username,
                    ["user.id"] = interaction.user.id,
                    ["user.mention"] = "<@" .. interaction.user.id .. ">",
                    ["timestamp"] = tostring(os.time())
                })
                parsed = replaced and replaced.message
            end

            if parsed then
                return interaction:reply({
                    embed = {
                        description = parsed,
                        color = colors.success
                    },
                })
            end

            if gaveRole then
                return interaction:success("You used **" .. item.name .. "** and have been given <@&" .. item.role .. ">.")
            else
                return interaction:success("You used **" .. item.name .. "**.")
            end

        elseif subcmd == "inventory" then
            local member = fetchMemberFromInteraction(interaction, args, slash) or interaction.member
            local identifier = ((member and member.id == interaction.user.id) and "Your") or ((member and member.id ~= interaction.user.id) and getUserString(member.user) .. "'s")

            local account, err = db:ecoFetch(member)
            if not account then
                return interaction:fail(err, nil, true)
            end
            account.inventory = account.inventory or {}

            local inventoryCount = {}
            local updatedInventory = {}

            for _, itemId in ipairs(account.inventory) do
                local _, hasItem = db:ecoItem(member, itemId)
                if hasItem then
                    inventoryCount[itemId] = (inventoryCount[itemId] or 0) + 1
                    table.insert(updatedInventory, itemId)
                end
            end

            if #updatedInventory ~= #account.inventory then
                account.inventory = updatedInventory
                db:ecoModify(member, { inventory = account.inventory })
            end

            if not next(inventoryCount) then
                return interaction:fail(identifier .. " inventory is empty")
            end

            local emb = {
                author = author(member),
                title = emojis.backpack .. " " .. identifier .. " Inventory",
                color = colors.info,
                fields = {}
            }

            for itemId, qty in pairs(inventoryCount) do
                local itemData = db:ecoItem(member, itemId)
                local itemName = itemData and itemData.name or "Unknown Item"
                local itemDescription = (itemData and itemData.description ~= "" and itemData.description) or "No description provided."

                table.insert(emb.fields, {
                    name = "**" .. itemName .. " **x" .. qty,
                    value = emojis.right .. " " .. itemDescription,
                    inline = false
                })
            end

            return interaction:reply({ embed = emb })

        elseif subcmd == "info" then
            local item
            if slash then
                local itemId = args.item
                item = db:ecoItem(interaction.member, itemId)
            else
                local name = table.remove(args, 1) and table.concat(args, " ")
                for _, v in pairs(config.economy.shop) do
                    if v.name:lower() == name:lower() then
                        item = v
                        break
                    end
                end

                if not item then
                    local possible = {}
                    for _, v in pairs(config.economy.shop) do
                        if string.levenshtein(v.name:lower(), name:lower()) < 4 then
                            table.insert(possible, v.name)
                        end
                    end

                    if #possible > 0 then
                        local possibleemb = {
                            description = emojis.fail .. " I could not find that item. Did you mean...",
                            color = colors.fail
                        }

                        for _, p in pairs(possible) do
                            possibleemb.description = possibleemb.description .. "\n" .. emojis.right .. " " .. p
                        end

                        return interaction:reply({
                            embed = possibleemb
                        }, true)
                    end

                    return interaction:reply({
                        embed = {
                            description = emojis.fail .. " I could not find that item.",
                            color = colors.fail
                        }
                    }, true)
                end
            end

            if not item then
                return interaction:fail("You did not provide a valid item.", nil, true)
            end

            return interaction:reply({
                embed = {
                    title = emojis.shop .. " " .. item.name,
                    author = author(guild),
                    color = colors.info,
                    description = emojis.right .. " **Item Description:** " .. (item.description or emojis.fail) .. "\n" ..
                        emojis.right .. " **Item Price:** " .. (config.economy.currency or emojis.quack) .. " " .. formatNumber(tonumber(item.price)) .. "\n" ..
                        emojis.right .. " **Item ID:** `" .. item.id .. "`\n" ..
                        emojis.right .. " **Use on Purchase:** " .. ((item.useonpurchase and emojis.success) or emojis.fail) .. "\n" ..
                        emojis.right .. " **Custom Message:** " .. ((item.message and emojis.success) or emojis.fail)
                }
            })
        end
    end
}