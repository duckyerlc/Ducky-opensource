-- serverinfo.lua
local slashCommand = tools.slashCommand("serverinfo", "Get the current server's info.")

return {
	name = "serverinfo",
	description = "Get the current server's info.",
	aliases = {
		"guildinfo",
        "si"
	},
	category = "Utility",
	slashCommand = slashCommand,
	requiredPermissions = {},
	hybridCallback = function(interaction, args)
		local r = interaction:reply({
			embed = {
				description = emojis.loading .. " Fetching members...",
				color = colors.blank
			}
		})

		local guild = interaction.guild
		loadMembers(guild)

		local textchannels = guild.textChannels
		local voicechannels = guild.voiceChannels
		local categories = guild.categories
		local roles = guild.roles
		local joinedTimestamp = math.floor(discordia.Date.fromISO(guild.joinedAt or ""):toSeconds())
		local createdTimestamp = math.floor(guild.createdAt)
		local mc = guild.totalMemberCount
		local bc = #guild.bots
		local boosts = guild.premiumSubscriptionCount
		local level = guild.premiumTier
		local systemChannel = guild.systemChannel or (guild.systemChannelId and guild:getChannel(guild.systemChannelId))
		local vanity = guild.vanityCode
		local owner = guild.owner or guild:getMember(guild.ownerId)
		local mfaEnabled = ((guild.mfaLevel == 1) and emojis.success) or emojis.fail
		local vl = guild.verificationLevel
		local wad = getMembersJoinedWithin(guild, 86400)
		local verificationLevel = ""

		if vl == 0 then
			verificationLevel = "None"
		elseif vl == 1 then
			verificationLevel = "Low"
		elseif vl == 2 then
			verificationLevel = "Medium"
		elseif vl == 3 then
			verificationLevel = "High"
		elseif vl == 4 then
			verificationLevel = "Very High"
		end

		local emb = {
			author = {
				name = guild.name,
				icon_url = guild.iconURL
			},
			title = emojis.guild .. " Server Information",
			thumbnail = guild.iconURL and {
				url = guild.iconURL .. "?size=4096"
			},
            image = guild.bannerURL and {
                url = guild.bannerURL .. "?size=4096"
            },
			color = colors.info,
			description = "",
			fields = {}
		}

		local function newval(title, val) emb.description = emb.description .. emojis.right .. " **" .. title .. ":** " .. val .. "\n" end

		if sqldb:isAffiliate(guild.id) then emb.description = emb.description .. "-# " .. emojis.right .. " *This server is an official " .. emojis.affiliate .. " **Ducky Affiliate**.*\n" end
		if sqldb:plusGuild(guild) then emb.description = emb.description .. "-# " .. emojis.right .. " *This server is a " .. emojis.duckyplus .. " **Ducky Plus+** server.*\n" end
		if (guild.description) and (guild.description ~= "") then emb.description = emb.description .. "> *" .. interaction.guild.description .. "*\n\n" end

        emb.description = emb.description .. emojis.settings .. " **General Information**\n"
		newval("Owner", owner.mentionString)
		newval("Guild ID", "`" .. guild.id .. "`")
		newval("Created", string.format("<t:%s> (<t:%s:R>)", tostring(createdTimestamp), tostring(createdTimestamp)))
		newval("Ducky Added", string.format("<t:%s> (<t:%s:R>)", tostring(joinedTimestamp), tostring(joinedTimestamp)))
		newval("System Channel", (systemChannel and systemChannel.mentionString) or "N/A")
		newval("Member Count", mc)
		newval("Bot Count", bc)
		newval("Channels", tostring(#textchannels + #voicechannels + #categories))
		newval("Roles", tostring(#roles))
        newval("Vanity Invite", ((vanity and ("https://discord.gg/" .. vanity)) or emojis.fail))

		table.insert(emb.fields, {
			name = emojis.channel .. " Channels",
			value = emojis.right .. " **Categories:** " .. #categories .. "\n" .. emojis.right .. " **Text Channels:** " .. #textchannels .. "\n" .. emojis.right .. " **Voice Channels:** " .. #voicechannels,
			inline = true
		})

		table.insert(emb.fields, {
			name = emojis.chart .. " Statistics",
			value = "\n" .. emojis.right .. " **Growth:** " .. #wad .. " member" .. (((#wad ~= 1) and "s") or "") .. " joined within the past day\n" .. emojis.right .. " **Bots:** " .. #guild.bots .. "\n" .. emojis.right .. " **Boosts:** " .. boosts .. " (Level " .. level .. ")",
			inline = true
		})

		table.insert(emb.fields, {
			name = emojis.lock .. " Security",
			value = emojis.right .. " **MFA Enabled:** " .. mfaEnabled .. "\n" .. emojis.right .. " **Verification Level:** " .. verificationLevel,
			inline = true
		})

		local e

		if type(r) == "table" then
			_, e = r:setEmbed(emb)
		else
			r, e = interaction:reply({
				embed = emb
			})
		end

		if e then
			local p = {
				embed = {
					title = _G.emojis.warning .. " HTTP Error",
					description = "```" .. e .. "```",
					color = _G.colors.warning
				}
			}

			if type(r) == "table" then
				r:update(p)
			else
				interaction:reply(p, true)
			end
		end
	end
}
