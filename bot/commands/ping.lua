-- ping.lua
local slashCommand = tools.slashCommand("ping", "View shard health, uptime, and bot latency.")

return {
	name = "ping",
	description = "View shard health, uptime, and bot latency.",
	aliases = {
		"health",
		"uptime",
		"latency",
		"pingpong",
		"pong",
		"shard"
	},
	category = "General",
	slashCommand = slashCommand,
	requiredPermissions = {},
	hybridCallback = function(interaction, args, slash, subcmd)
		if (not slash) and subcmd then
			table.remove(args, 1)
		end

		local latency = {
			websocket = math.floor((realtime() - interaction.createdAt) * 1000)
		}
		
		local presend = realtime()
		local r = interaction:loading()
		latency.response = math.floor((r.createdAt - interaction.createdAt) * 1000)
		latency.api = math.floor((r.createdAt - presend) * 1000)

		local guild = interaction.guild
		local shard = shardHealth and shardHealth[guild.shardId]
		latency.shard = shard and shard.latency and math.floor(shard.latency)

		if subcmd == "shards" or subcmd == "shard" or subcmd == "health" then
			local pages = {}

			for i = 0, Client.totalShardCount - 1 do
				local shard = Client._shards[i]
				local health = shardHealth and shardHealth[i]
				local guilds = 0
				local emoji = (health and health.latency and math.floor(health.latency) >= 1000 and "warning") or (health and health.heartbeatSent and (health.heartbeatSent > (health.heartbeatAcknowledged or 0)) and "error") or (guild.shardId == i and "guild") or "network"

				for _, guild in pairs(Client.guilds) do
					if guild.shardId == i then
						guilds = guilds + 1
					end
				end

				table.insert(pages, {
					title = emojis[emoji] .. " Shard " .. i,
					description = emojis.right .. " **Guilds:** " .. formatNumber(guilds) .. "\n" .. emojis.right .. " **Last Heartbeat:**\n" .. emojis.space .. emojis.right .. " **Sent:** " .. ((health and health.heartbeatSent and ("<t:" .. health.heartbeatSent .. ":T> (<t:" .. health.heartbeatSent .. ":R>)")) or emojis.fail) .. "\n" .. emojis.space .. emojis.right .. " **Acknowledged:** " .. ((health and health.heartbeatAcknowledged and ("<t:" .. health.heartbeatAcknowledged .. ":T> (<t:" .. health.heartbeatAcknowledged .. ":R>)")) or emojis.fail) .. "\n" .. emojis.right .. " **Latency:** " .. ((health and health.latency and (math.floor(health.latency) .. "ms")) or emojis.fail) .. ((guild.shardId == i and ("\n-# " .. emojis.right .. " This guild is running on this shard.")) or ""),
					color = colors.yellow,
					identifier = {
						emoji = resolvedEmojis[emoji],
						text = "Shard " .. i,
						description = formatNumber(guilds) .. " guilds・" .. ((health and health.latency and (math.floor(health.latency) .. "ms")) or "N/A") .. " latency"
					}
				})
			end

			return paginate(r, pages, interaction.user, {
				teleport = true,
				clamp = false,
				startPage = (args and args[1] and tonumber(args[1]) and pages[tonumber(args[1]) + 1] and (tonumber(args[1]) + 1)) or (guild.shardId + 1)
			})
		elseif subcmd == "debug" or subcmd == "dbg" then
			local config = sqldb:get(guild.id) or {}

			return r:update({
				embed = {
					title = emojis.folder .. " Debug",
					description = 
						emojis.right .. " **ERLua:** " .. emojis.success .. "\n"
						.. emojis.right .. " **RoPI:** " .. table.count(ropi.Requests.users) .. " user requests queued\n"
						.. emojis.right .. " **Memory:** " ..
						math.round(process.memoryUsage().rss / 1048576, 2) .. "MB",
					color = colors.yellow
				}
			})
		else
			return r:update({
				embed = {
					title = emojis.pong .. " Pong!",
					description = emojis.right .. " **Latency:**\n"
					.. emojis.space .. emojis.right .. " **Round-Trip:** " .. latency.response .. "ms\n"
					.. emojis.space .. emojis.right .. " **API:** " .. latency.api .. "ms\n"
					.. emojis.space .. emojis.right .. " **Websocket:** " .. latency.websocket .. "ms\n"
					.. emojis.space .. emojis.right .. " **Shard:** " .. ((latency.shard and (latency.shard .. "ms")) or "Not yet calculated") .. "\n"
					.. emojis.right .. " **Uptime:** " .. readable(os.time() - uptime) .. "\n"
					.. emojis.right .. " **Version:** " .. version .. "\n"
					.. emojis.right .. " **Shard:** " .. guild.shardId,
					color = colors.yellow
				},
				components = discordia.Components():button({
					style = "link",
					url = "https://duckybot.xyz/support",
					label = "Support",
					emoji = resolvedEmojis.support
				}):button({
					style = "link",
					url = "https://status.duckybot.xyz",
					label = "Status",
					emoji = resolvedEmojis.chart
				}):raw()
			})
		end
	end
}
