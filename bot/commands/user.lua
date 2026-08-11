-- user.lua
local slashCommand = tools.slashCommand("user", "View a user's info.")
local subcmd = tools.subCommand("discord", "View a Discord user's info.")
subcmd = subcmd:addOption(tools.user("user", "The Discord user to view information on."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("roblox", "View a Roblox player's info.")
subcmd = subcmd:addOption(tools.string("username", "The Roblox player's username."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)

local flags = {
    ["1268775237105881149"] = emojis.founder .. " Founder",
    ["1419398641180737606"] = emojis.developer .. " Developer",
    ["1289287278639841395"] = emojis.developer .. " Development Alt",
    ["1268775087650111500"] = emojis.executive .. " Executive",
    ["1286472622984400946"] = emojis.web .. " Web Developer",
    ["1260949789319626795"] = emojis.inspiration .. " Inspiration",
    ["1267455598413217883"] = emojis.settings .. " Community Manager",
    ["1268774900735148135"] = emojis.settings .. " Manager",
    ["1259747747091972116"] = emojis.support .. " Support",
    ["1259747827337396265"] = emojis.quickfix .. " Administrator",
    ["1259747806697099285"] = emojis.moderate .. " Moderator",
    ["1311330617824378940"] = emojis.edit .. " Docwriter",
    ["1275953925429788672"] = emojis.o7 .. " Retired Staff",
    ["1457476467213467872"] = emojis.qa .. " Head of Quality Assurance",
    ["1260070830180667402"] = emojis.qa .. " Quality Assurance",
    ["1329078327071342624"] = emojis.vertuo .. " Vertuo Hosting",
    ["1314612434467688531"] = emojis.affiliate .. " Affiliate",
    ["1266790522371182642"] = emojis.partner .. " Partner",
    ["1387788499016482876"] = emojis.link .. " Contributor",
    ["1391386174244913222"] = emojis.inspiration .. " Elite Quacker",
    ["1279781412156735591"] = emojis.star .. " Elite Donator",
    ["1282277290868477963"] = emojis.donation .. " Donator",
    ["1267239172444262490"] = emojis.duckyplus .. " Ducky Plus+ Member",
    ["1281961357658292294"] = emojis.goose .. " Goose",
    ["1265695370693050515"] = emojis.bughunter .. " Bug Hunter",
    ["1266499891488882760"] = emojis.suggester .. " Suggester",
    ["1257408154195464224"] = emojis.ducky .. " Ducky",
    ["1388261712574021786"] = emojis.duckyplus .. " Ducky Plus+",
    ["1307670808260513899"] = emojis.duckyoutline .. " Ducky Dev",
    ["1305166985352708158"] = emojis.duckyexperimental .. " Ducky Experimental"
}

local function getFlags(user)
    local f = {}
    local duckyMember = duckysPond:getMember(user.id)

    if duckyMember then
        local roles = table.values(duckyMember.roles:toArray())

        table.sort(roles, function(a,b)
            return a.position > b.position
        end)

        for i, role in pairs(roles) do
            if flags[role.id] then
                table.insert(f, flags[role.id])
            end
        end
    end

    return f
end

return {
    name = "user",
    description = "View a user's info.",
    aliases = {
        discord = {
            "whois",
            "wi",
            "ud"
        },
        roblox = {
            "search",
            "s",
            "roblox",
            "ur"
        }
    },
    category = "Utility",
    slashCommand = slashCommand,
    requiredPermissions = {},
    subcommands = {
        "discord",
        "roblox"
    },
    hybridCallback = function(interaction, args, slash, subcmd)
        if (not slash) and subcmd then
            table.remove(args, 1)
        end

        if subcmd == "discord" then
            local member, user = fetchMemberFromInteraction(interaction, args, slash)

            if not user then
                if ((not slash) and (args and args[1])) or (slash and args and args.user) then
                    return interaction:fail("That user could not be found.", nil, true)
                else
                    user = interaction.user
                    member = interaction.member
                end
            end

            local settings = sqldb:getUserSettings(user.id) or {}

            local embed = {
                description = emojis.person .." **User Information:**\n" .. emojis.right .. " **Name:** " .. (user.globalName or user.username) .. " (@" .. user.username .. ")\n" .. emojis.right .. " **ID:** `" .. user.id .. "`\n" .. emojis.right .. " **Mention:** " .. user.mentionString .. "\n" .. emojis.right .. " **Created:** <t:" .. math.floor(user.createdAt) .. ">\n",
                color = colors.yellow,
                thumbnail = user.avatarURL and {
                    url = user.avatarURL
                },
                author = author(user)
            }

            if settings then
                embed.description = embed.description .. "\n" .. emojis.settings .. " **User Settings:**\n" .. emojis.right .. " **Timezone:** " .. ((settings.timezone and (settings.timezone.name .. " (`" .. settings.timezone.abrv .. "`)")) or emojis.fail) .. "\n"
            end

            if member then
                local rolesstr = ""
                local roles = table.values(member.roles)

                table.sort(roles, function(a,b)
                    return a.position > b.position
                end)

                for i, v in pairs(roles) do
                    rolesstr = rolesstr .. "\n" .. emojis.space .. emojis.right .. " " .. v.mentionString

                    if i > 10 then
                        rolesstr = rolesstr .. "\n-# " .. emojis.space .. emojis.right .. " *and " .. (table.count(roles) - 10) .. " more...*"
                        break
                    end
                end

                if not next(roles) then
                    rolesstr = "None"
                end

                embed.description = embed.description .. "\n" .. emojis.guild .. " **Member Information:**\n" .. emojis.right .. " **Nickname:** " .. (member.name or "N/A") .. "\n" .. emojis.right .. " **Joined:** <t:" .. math.floor(discordia.Date.fromISO(member.joinedAt):toSeconds()) .. ">\n" .. emojis.right .. " **Roles:** " .. rolesstr .. "\n"
            end

            local link = sqldb:getLink(user.id)

            if link then
                local roblox = ropi.GetUser(link.roblox)
                if roblox then
                    embed.description = embed.description .. "\n" .. emojis.roblox .. " **Roblox Information:**\n" .. emojis.right .. " **Name:** [" .. (roblox.displayName or roblox.name) .. " (@" .. roblox.name .. ")](" .. roblox.profile .. ")\n" .. emojis.right .. " **ID:** `" .. roblox.id .. "`\n"
                end
            end

            local userFlags = getFlags(user)

            if userFlags and table.count(userFlags) > 0 then
                embed.description = embed.description .. "\n" .. emojis.flag .. " **Flags:**\n" .. emojis.right .. " " .. table.concat(userFlags, "\n" .. emojis.right .. " ") .. "\n"
            end

            if member and member.timedOutUntil then
                local expires = fromISO(member.timedOutUntil)

                if expires and realtime() < expires then
                    expires = math.floor(expires)

                    embed.description = embed.description .. "\n-# " .. emojis.timeout .. " This user is **timed out** until <t:" .. expires .. "> (<t:" .. expires .. ":R>)."
                end
            end

            if interaction.guild:getBan(user.id) then
                embed.description = embed.description .. "\n-# " .. emojis.ban .. " This user is **banned** from this server."
            end

            if blacklisted(user) then
                local _, blacklist = sqldb:getBlacklist(user.id)
                embed.description = embed.description .. "\n-# " .. emojis.ban .. " This user is **blacklisted** from " .. emojis.ducky .. " **Ducky**" .. ((hasPermission(interaction.member, "DUCKY_STAFF") and blacklist and blacklist.reason and (" for **" .. blacklist.reason .. "**")) or "") .. "."
            end

            interaction:reply({
                embed = embed
            })
        elseif subcmd == "roblox" then
            local username = (slash and args and args.username) or ((not slash) and args and args[1])

            if not username then
                return interaction:fail("You did not provide a Roblox username.", nil, true)
            end

            local player

            if interaction.mentionedUsers and interaction.mentionedUsers.first then
                local link = sqldb:getLink(interaction.mentionedUsers.first.id)

                if link then
                    local roblox = ropi.GetUser(link.roblox)

                    if roblox then
                        player = roblox
                    else
                        return interaction:fail(getUserString(interaction.mentionedUsers.first) .. " is linked with Ducky, but their Roblox account could not be found.", nil, true)
                    end
                else
                    return interaction:fail(getUserString(interaction.mentionedUsers.first) .. " is not linked with Ducky.", nil, true)
                end
            end

            player = player or ropi.SearchUser(username:lower())

            if not player then
                return interaction:fail("No Roblox player was found with the query **`" .. username .. "`**.", nil, true)
            end

            local embed = {
                title = emojis.roblox .. " " .. player.name .. ((player.verified and " " .. emojis.verified) or ""),
                description = emojis.right .. " **Name:** [" .. player.displayName .. " (@" .. player.name .. ")](" .. player.profile .. ")\n" .. emojis.right .. " **ID:** `" .. player.id .. "`\n" .. emojis.right .. " **Description:** " .. player.description .. "\n" .. emojis.right .. " **Created:** <t:" .. math.floor(player.created or 0) .. "> (<t:" .. math.floor(player.created or 0) .. ":R>)",
                thumbnail = (player.avatar and {
                    url = player.avatar
                }) or nil,
                color = colors.info
            }

            local link = sqldb:getLink(player.id)
            local discord = link and Client:getUser(link.discord)

            if discord then
                embed.description = embed.description .. "\n\n" .. emojis.discord .. " **Linked Discord Account**" .. "\n" .. emojis.space .. emojis.right .. " **Name:** " .. discord.name .. " (@" .. discord.username .. ")\n" .. emojis.space .. emojis.right .. " **Mention:** " .. discord.mentionString .. "\n" .. emojis.space .. emojis.right .. " **ID:** `" .. discord.id .. "`"
            end

            return interaction:reply({
                embed = embed
            })
        end
    end
}