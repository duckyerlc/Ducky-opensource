-- collect.lua
local slashCommand = tools.slashCommand("collect", "Claim your role collection income.")

return {
    name = "collect",
    description = "Claim your role collection income.",
    category = "Economy",
    slashCommand = slashCommand,
    requiredPermissions = {"SETUP"},
    hybridCallback = function(interaction, args, slash)
        local config = sqldb:get(interaction.guild.id) or {}
        config.economy = config.economy or {}
        config.economy.collectionroles = config.economy.collectionroles or {}

        if config.economy and config.economy.disabled then
			return interaction:fail("The " .. emojis.quack .. " **Economy** module is not enabled in this server.")
		end

        local account, err = db:ecoFetch(interaction.member)
        if not account then
            return interaction:fail(err, nil, true)
        end

        local collectedRoles = {}
        local totalCollected = 0
        local needsCooldownUpdate = false

        for _, v in pairs(config.economy.collectionroles) do
            local role = v.role
            local amount = v.amount
            local target = v.target
            local cooldown = v.cooldown

            if interaction.member:hasRole(role) then

                local last = account.cooldowns[role]
                if not last or not cooldown or not ((os.time() - last) < cooldown) then
                    if cooldown then
                        account.cooldowns[role] = os.time()
                        needsCooldownUpdate = true
                    end

                    account.balance[target] = account.balance[target] + math.round(amount)
                    table.insert(collectedRoles, {role = role, amount = amount, target = target})
                    totalCollected = totalCollected + amount
                end
            end
        end

        local updateData = { balance = account.balance }
        if needsCooldownUpdate then
            updateData.cooldowns = account.cooldowns
        end
        db:ecoModify(interaction.member, updateData)

        if #collectedRoles == 0 then
            return interaction:fail("You do not have any role income to collect.", nil, true)
        end

        local emb = {
            author = author(interaction.member),
            title = emojis.success .. " Role Income Collected",
            description = "",
            color = colors.info
        }

        for i, v in ipairs(collectedRoles) do
            emb.description = emb.description .. emojis.right .. " **" .. i .. ".** <@&" .. v.role .. ">" .. emojis.dot .. (config.economy.currency or emojis.quack) .. " " .. formatNumber(v.amount) .. " (" .. v.target .. ")" .. "\n"
        end

        emb.description = emb.description .. "-# " .. emojis.right .. " **Total:** " .. (config.economy.currency or emojis.quack) .. " " .. formatNumber(totalCollected)

        return interaction:reply({embed = emb})
    end
}