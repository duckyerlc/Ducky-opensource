-- membercount.lua

local slashCommand = tools.slashCommand("membercount", "Get the server's membercount.")
slashCommand = slashCommand:addOption(tools.integer("goal", "The membercount goal to view."):setRequired(false))

return {
    name = "membercount",
    description = "Get the server's membercount.",
    aliases = {"mc", "members"},
    category = "Utility",
    slashCommand = slashCommand,
    requiredPermissions = {},
    hybridCallback = function(interaction, args, slash, subcmd)
        local r = interaction:reply({embed = {
            description = emojis.loading .. " Fetching members...",
            color = colors.blank
        }})

        local guild = interaction.guild

        loadMembers(guild)

        local online = guild.onlineMembers
		local mc = guild.totalMemberCount
        local wad = table.count(getMembersJoinedWithin(guild, 86400) or {})
        local waw = table.count(getMembersJoinedWithin(guild, 604800) or {})
        local wam = table.count(getMembersJoinedWithin(guild, 2629746) or {})
        local goal = (slash and args and args.goal) or ((not slash) and args and args[1] and tonumber(args[1]))

        local emb = {
            author = {
                name = guild.name,
                icon_url = guild.iconURL
            },
            title = emojis.people .. " Members",
            description = emojis.right .. " **Total Members:** " .. formatNumber(mc) .. "\n" .. emojis.right .. " **Members:** " .. formatNumber(mc - #guild.bots) .. "\n" .. emojis.right .. " **Bots:** " .. formatNumber(#guild.bots) .. "\n" .. emojis.right .. " **Growth:**\n" .. emojis.space .. emojis.right .. " " .. formatNumber(wad) .. " members joined within the past day\n" .. emojis.space .. emojis.right .. " " .. formatNumber(waw) .. " members joined within the past week\n" .. emojis.space .. emojis.right .. " " .. formatNumber(wam) .. " members joined within the past month",
            color = colors.info
        }

        if args and args[1] and args[1]:lower() == "cached" then
            emb.description = emb.description .. "\n-# " .. emojis.right .. " **Cached Members:** " .. formatNumber(#guild.members)
        elseif goal and goal > guild.totalMemberCount then
            local mps = wam / 2629746
            local distance = goal - guild.totalMemberCount
            local projected = os.time() + math.floor(distance / mps)
            emb.description = emb.description .. "\n-# " .. emojis.target .. " **Goal:** " .. formatNumber(goal) .. " (projected to reach <t:" .. projected .. ":R>)"
        end

        if type(r) == "table" then
            r:update({
                embed = emb
            })
        else
            interaction:reply({
                embed = emb
            })
        end
    end
}