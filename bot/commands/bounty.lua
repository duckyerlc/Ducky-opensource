-- bounty.lua
local slashCommand = tools.slashCommand("bounty", "Place bounties on players within the ERLC private server.")
local subcmd = tools.subCommand("add", "Add a bounty on a player.")
subcmd = subcmd:addOption(tools.string("player", "The player to add the bounty to."):setRequired(true):setAutocomplete(true))
subcmd = subcmd:addOption(tools.integer("amount", "The amount of money to add to this player's bounty."):setRequired(true))
subcmd = subcmd:addOption(tools.string("reason", "The reason for this bounty payment."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("remove", "Remove a player's bounty.")
subcmd = subcmd:addOption(tools.string("player", "The player to add the bounty to."):setRequired(true):setAutocomplete(true))
subcmd = subcmd:addOption(tools.string("reason", "The reason for the removal of this bounty."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("view", "View an active bounty on a player.")
subcmd = subcmd:addOption(tools.string("player", "The player to view the bounty of."):setRequired(true):setAutocomplete(true))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("list", "View all active bounties.")
slashCommand = slashCommand:addOption(subcmd)

return {
    name = "bounty",
    description = "Place bounties on players within the ERLC private server.",
    aliases = {},
    category = "Economy",
    slashCommand = slashCommand,
    requiredPermissions = {"ERLC_LINKED"},
    subcommands = {
        add = {
            "create",
            "pay"
        },
        "remove",
        "view",
        "list"
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

        local config = sqldb:get(interaction.guild.id) or {}
        config.economy = config.economy or {}
        config.economy.bounties = config.economy.bounties or {}

        if config.economy and config.economy.disabled then
			return interaction:fail("The " .. emojis.quack .. " **Economy** module is not enabled in this server.")
		end

        if subcmd == "add" or subcmd == "create" or subcmd == "pay" then
            local player = (slash and args and args.player) or ((not slash) and args and args[1]) or nil
			player = ((player and player ~= "") and ropi.SearchUser(player)) or nil
            local amount = (slash and args and args.amount) or ((not slash) and args and args[2] and tonumber(args[2])) or nil
            local reason = (slash and args and args.reason) or ((not slash) and args and table.concat(args, " ", 3)) or nil
            reason = (reason and reason ~= "" and reason) or nil

            if not player then
                return interaction:fail("You did not provide a player to add this bounty to.", nil, true)
            elseif not amount then
                return interaction:fail("You did not provide an amount to add to this player's bounty.", nil, true)
            end

            local bounty, err = db:ecoBountyAdd(interaction.member, player, amount, reason)
            if not bounty then
                return interaction:fail(err, nil, true)
            end

            return interaction:success("You have added " .. ((config.economy and config.economy.currency) or emojis.quack) .. " **" .. formatNumber(amount) .. "** to **" .. player.hyperlink .. "**'s bounty.")
        elseif subcmd == "remove" then
            if not hasPermission(interaction.member, "MANAGE_SERVER", nil, interaction) then
                return
            end

            local player = (slash and args and args.player) or ((not slash) and args and args[1]) or nil
			player = ((player and player ~= "") and ropi.SearchUser(player)) or nil
            local reason = (slash and args and args.reason) or ((not slash) and args and table.concat(args, " ", 2)) or nil
            reason = (reason and reason ~= "" and reason) or nil

            if not player then
                return interaction:fail("You did not provide a player to remove the bounty from.", nil, true)
            end

            local success, err = db:ecoBountyRemove(interaction.member, player, reason)
            if not success then
                return interaction:fail(err, nil, true)
            end

            return interaction:success("**" .. player.hyperlink .. "**'s bounty has been removed, and all members that added payments to it have been refunded.")
        elseif subcmd == "view" then
            local player = (slash and args and args.player) or ((not slash) and args and args[1]) or nil
			player = ((player and player ~= "") and ropi.SearchUser(player)) or nil

            if not player then
                return interaction:fail("You did not provide a player to view the bounty of.", nil, true)
            end

            local bounty, amount, members = db:ecoBountyFetch(interaction.guild, player)
            if (not bounty) or (not bounty.payments) or (table.count(bounty.payments) <= 0) or (amount <= 0) then
                return interaction:fail("**" .. player.hyperlink .. "** does not have an active bounty on them.", nil, true)
            end

            local pages = {
                {
                    title = emojis.target .. " **" .. player.name .. "**'s Bounty",
                    description = emojis.right .. " **" .. player.hyperlink .. "** has an active bounty of " .. (config.economy.currency or emojis.quack) .. " **" .. formatNumber(amount) .. "** funded by **" .. table.count(members) .. " members**.",
                    color = colors.yellow,
                    thumbnail = {
                        url = player.avatar
                    },
                    identifier = {
                        emoji = resolvedEmojis.target,
                        text = player.name .. "'s Bounty"
                    }
                }
            }
            local page = {}

            local function resetPage()
                page = {
                    title = emojis.target .. " **" .. player.name .. "**'s Bounty",
                    fields = {},
                    color = colors.yellow,
                    thumbnail = {
                        url = player.avatar
                    }
                }
            end

            resetPage()

            for i, payment in pairs(bounty.payments) do
                table.insert(page.fields, {
                    name = emojis.target .. " Payment " .. i, -- wallet emoji would be better but its not in emojis table :boom:
                    value = emojis.right .. " **Member:** <@" .. payment.member .. ">\n"
                        .. emojis.right .. " **Amount:** " .. (config.economy.currency or emojis.quack) .. " " .. formatNumber(payment.amount) .. "\n"
                        .. emojis.right .. " **Reason:** " .. (payment.reason or emojis.fail) .. "\n"
                        .. emojis.right .. " **Date:** <t:" .. payment.timestamp .. ">"
                })

                if table.count(page.fields) >= 5 or i >= table.count(bounty.payments) then
                    table.insert(pages, page)
                    resetPage()
                end
            end

            return paginate(interaction, pages, interaction.user, {
                clamp = false,
                showTotalPages = true,
                teleport = true
            })
        elseif subcmd == "list" then
            if table.count(config.economy.bounties) <= 0 then
                return interaction:fail("There are no active bounties in this server.", nil, true)
            end
            
            local pages = {}
            local page = {}

            local function resetPage()
                page = {
                    title = emojis.target .. " Active Bounties",
                    color = colors.yellow,
                    fields = {}
                }
            end

            resetPage()

            for i, bounty in pairs(config.economy.bounties) do
                local player = ropi.GetUser(bounty.player)
                local bounty, amount = db:ecoBountyFetch(interaction.guild, player)

                table.insert(page.fields, {
                    name = emojis.target .. " " .. player.name,
                    value = emojis.right .. " **Amount:** " .. (config.economy.currency or emojis.quack) .. " " .. formatNumber(amount) .. "\n"
                        .. emojis.right .. " **Reasons:** " .. table.concatFn(bounty.payments, ", ", function(payment)
                            return payment.reason or "N/A"
                        end) .. "\n"
                        .. emojis.right .. " **Date:** <t:" .. bounty.started .. ">"
                })

                if table.count(page.fields) >= 5 or i >= table.count(config.economy.bounties) then
                    table.insert(pages, page)
                    resetPage()
                end
            end

            return paginate(interaction, pages, interaction.user, {
                clamp = false,
                showTotalPages = true,
                teleport = true
            })
        end
    end
}