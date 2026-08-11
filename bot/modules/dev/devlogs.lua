-- devlogs.lua
local devlogs = {
	name = "devlogs",
	description = "Handles some stuff for developers."
}

local Clock = discordia.Clock()
Clock:start()

local connections = {
	Client = {},
	Clock = {}
}

local ADERLC_API_KEY = SECRETS.ADERLC_API_KEY

devlogs.Start = function()
	connections.Client["error"] = Client:on("error", function(err)
		coroutine.wrap(function()
			if err:match("HTTP Error") or err:match("api%.policeroleplay%.community") or err:match("503 Service Unavailable") or err:match("504 Gateway Time-out") or err:match("onComp | No message was provided") or err:match("DEFERRED_UPDATE_MESSAGE") then
				return
			end

			if type(utilityChannels) == "table" and utilityChannels.errors then
				utilityChannels.errors:send("```" .. err .. "```\n-# " .. emojis.clock .. " <t:" .. os.time() .. ":T>")
			end
		end)()
	end)

	connections.Client["guildCreate"] = Client:on("guildCreate", function(guild)
		coroutine.wrap(function()
			updateActivity()

			if (not guild) or not guild.id or not guild.name or not guild.totalMemberCount then
				return
			end
			local config = sqldb:get(guild.id)
			if config and config.removetimestamp then
				sqldb:set(guild.id, {
					removetimestamp = "nil"
				}, "GUILD_REMOVE_REMOVETIMESTAMP")
			end

			pcall(function()
				utilityChannels.guilds:send(emojis.add .. " **" .. Client.user.name .. "** has been added to **" .. guild.name .. "**.\n-# " .. emojis.guild .. " `" .. guild.id .. "`・" .. emojis.person .. " <@" .. guild.ownerId .. ">・" .. emojis.people .. " " .. formatNumber(guild.totalMemberCount) .. "・" .. emojis.chart .. " " .. formatNumber(#Client.guilds))
			end)
		end)()
	end)

	connections.Client["guildDelete"] = Client:on("guildDelete", function(guild)
		updateActivity()

		local config = sqldb:get(guild.id)
		if config then
			sqldb:set(guild.id, {
				removetimestamp = os.time()
			}, "GUILD_ADD_REMOVETIMESTAMP")
		end

		pcall(function()
			utilityChannels.guilds:send(emojis.subtract .. " **" .. Client.user.name .. "** has been removed from **" .. guild.name .. "**.\n-# " .. emojis.guild .. " `" .. guild.id .. "`・" .. emojis.person .. " <@" .. guild.ownerId .. ">・" .. emojis.people .. " " .. formatNumber(guild.totalMemberCount) .. "・" .. emojis.chart .. " " .. formatNumber(#Client.guilds))
		end)
	end)

	local shardHealth = {}
	_G.shardHealth = shardHealth

	local function shardFailure(shard, health, now, reason)
		now = now or os.time()
		shardHealth[shard].failures = shardHealth[shard].failures or {}
		
		local recent = shardHealth[shard].failures[table.count(shardHealth[shard].failures)]
		if recent and now - recent <= 5 then
			return
		end

		table.insert(shardHealth[shard].failures, now)

		for i = #shardHealth[shard].failures, 1, -1 do
			if now - shardHealth[shard].failures[i] > 300 then
				table.remove(shardHealth[shard].failures, i)
			end
		end

		if #shardHealth[shard].failures >= 3 then
			utilityChannels.boots:send(emojis.error .. " **Shard " .. shard .. "** has forced a reboot after 3 reconnection failures.\n-# " .. emojis.clock .. " <t:" .. now .. ":T>・" .. emojis.network .. " " .. ((health.latency and (math.floor(health.latency) .. "ms")) or "N/A") .. "・" .. emojis.cycle .. " " .. readable(now - health.heartbeatSent))
			os.exit(1)
		else
			local s = Client._shards[shard]
			s:disconnect(true)
			utilityChannels.boots:send(emojis.reload .. " **Shard " .. shard .. "** has been reconnected for " .. reason .. ".\n-# " .. emojis.clock .. " <t:" .. now .. ":T>・" .. emojis.network .. " " .. ((health.latency and (math.floor(health.latency) .. "ms")) or "N/A") .. "・" .. emojis.cycle .. " " .. readable(now - health.heartbeatSent))
			shardHealth[shard].heartbeatSent = now
		end
	end

	connections.Client["heartbeatSent"] = Client:on("heartbeatSent", function(shard)
		shardHealth[shard] = shardHealth[shard] or {}

		Client:info("💓 Shard " .. shard .. " sent heartbeat (" .. ((shardHealth[shard].heartbeatSent and ((os.time() - shardHealth[shard].heartbeatSent) .. "s interval")) or "first heartbeat") .. ")")
		
		shardHealth[shard].heartbeatSent = os.time()
	end)

	connections.Client["heartbeatAcknowledged"] = Client:on("heartbeatAcknowledged", function(shard, latency)
		shardHealth[shard] = shardHealth[shard] or {}
		shardHealth[shard].latency = latency

		Client:info("💞 Shard " .. shard .. " heartbeat acknowledged (" .. math.floor(latency) .. "ms)")

		shardHealth[shard].heartbeatAcknowledged = os.time()
		if latency >= 5000 then
			shardFailure(shard, shardHealth[shard], nil, "high latency")
		end
	end)

	connections.Client["heartbeatFailure"] = Client:on("heartbeatFailure", function(shard, err)
		local now = os.time()

		Client:error("💔 Shard " .. shard .. " failed to send a heartbeat (" .. tostring(err) .. ")")
		utilityChannels.shards:send(emojis.warning .. " **Shard " .. shard .. "** failed to send a heartbeat.\n-# " .. emojis.clock .. " <t:" .. now .. ":T>・" .. emojis.edit .. " " .. tostring(err))
		shardFailure(shard, shardHealth[shard], nil, "heartbeat failure")
	end)

	connections.Client["shardReconnectRequest"] = Client:on("shardReconnectRequest", function(shard)
		local now = os.time()

		utilityChannels.shards:send(emojis.transfer .. " **Shard " .. shard .. "** has received a reconnection request.\n-# " .. emojis.clock .. " <t:" .. now .. ":T>")
		shardHealth[shard] = shardHealth[shard] or {}
		shardHealth[shard].heartbeatSent = os.time()
	end)

	connections.Client["shardDisconnect"] = Client:on("shardDisconnect", function(shard)
		local now = os.time()

		utilityChannels.shards:send(emojis.unlink .. " **Shard " .. shard .. "** has been disconnected.\n-# " .. emojis.clock .. " <t:" .. now .. ":T>")
	end)

	connections.Client["shardResumed"] = Client:on("shardResumed", function(shard)
		local now = os.time()

		utilityChannels.shards:send(emojis.play .. " **Shard " .. shard .. "** has been resumed.\n-# " .. emojis.clock .. " <t:" .. now .. ":T>")
		shardHealth[shard] = shardHealth[shard] or {}
		shardHealth[shard].heartbeatSent = os.time()
	end)
	
	local lastCollect = 0
	local lastHealthCheck = 0
	local lastReviewCheck = 0
	local lastBumpCheck = 0

	collectgarbage("setpause", 110)
	collectgarbage("setstepmul", 300)

	connections.Clock["sec"] = Clock:on("sec", function()
		local now = os.time()

		coroutine.wrap(function()
			collectgarbage("step", 1000)
			if now - lastCollect >= 30 then
				collectgarbage("collect")
				lastCollect = now
			end
		end)()

		if now - lastHealthCheck >= 10 then
			lastHealthCheck = now

			for shard, health in pairs(shardHealth) do
				if (now - health.heartbeatSent >= 45) then
					shardFailure(shard, health, now, "heartbeat timeout")
				end
			end
		end

		if now - lastReviewCheck >= 60 and runtime() == "Stable" then
			lastReviewCheck = now

			coroutine.wrap(function()
				local success, result, response = pcall(http.request, "GET", "https://advertisingerlc.xyz/api/listings/221/reviews?limit=50", {
					{"Authorization", "Bearer " .. ADERLC_API_KEY}
				})
				response = response and json.decode(response)

				if success and result and result.code == 200 and response and response.reviews and next(response.reviews) and duckysPond and utilityChannels and utilityChannels.supporters then
					local config = sqldb:get(duckysPond.id) or {}
					local lastReview = config.lastaderlcreview
					if not lastReview then return end

					table.sort(response.reviews, function(a, b)
						a.created_at = type(a.created_at) == "string" and fromISO(a.created_at) or a.created_at
						b.created_at = type(b.created_at) == "string" and fromISO(b.created_at) or b.created_at
						return a.created_at < b.created_at
					end)

					for _, review in pairs(response.reviews) do
						if review.created_at > lastReview and review.score >= 4 then
							utilityChannels.supporters:send({
								content = ":yellow_heart: <@" .. review.user.discord_id .. "> has reviewed " .. emojis.ducky .. " **Ducky** on <:AdvertisingERLC:1489646397002354728> [**AdvertisingERLC**](<https://advertisingerlc.xyz/discovery/221>) with " .. starMap[review.score]
								.. (review.comment and review.comment ~= "" and ":\n" .. emojis.right .. " " .. tostring(review.comment) or "!"),
								allowed_mentions = {
									users = {review.user.discord_id}
								}
							})
						end
					end

					if response.reviews[#response.reviews].created_at > lastReview then
						sqldb:set(duckysPond.id, {
							lastaderlcreview = response.reviews[#response.reviews].created_at
						}, "LAST_ADERLC_REVIEW")
					end
				end
			end)()
		end

		if now - lastBumpCheck >= 60 and runtime() == "Stable" then
			lastBumpCheck = now

			coroutine.wrap(function()
				local success, result, response = pcall(http.request, "GET", "https://advertisingerlc.xyz/api/listings/221/bumps?limit=50", {
					{"Authorization", "Bearer " .. ADERLC_API_KEY}
				})
				response = response and json.decode(response)

				if success and result and result.code == 200 and response and response.bumps and next(response.bumps) and duckysPond and utilityChannels and utilityChannels.supporters then
					local config = sqldb:get(duckysPond.id) or {}
					local lastBump = config.lastaderlcbump
					if not lastBump then return end

					table.sort(response.bumps, function(a, b)
						a.bumped_at = type(a.bumped_at) == "string" and fromISO(a.bumped_at) or a.bumped_at
						b.bumped_at = type(b.bumped_at) == "string" and fromISO(b.bumped_at) or b.bumped_at
						return a.bumped_at < b.bumped_at
					end)

					for _, bump in pairs(response.bumps) do
						if bump.bumped_at > lastBump then
							utilityChannels.supporters:send({
								content = ":yellow_heart: <@" .. bump.user.discord_id .. "> has bumped " .. emojis.ducky .. " **Ducky** on <:AdvertisingERLC:1489646397002354728> [**AdvertisingERLC**](https://advertisingerlc.xyz/discovery/221)!\n"
								.. "-# " .. emojis.right .. " Thank you for your support!"
							})
						end
					end

					if response.bumps[#response.bumps].bumped_at > lastBump then
						sqldb:set(duckysPond.id, {
							lastaderlcbump = response.bumps[#response.bumps].bumped_at
						}, "LAST_ADERLC_BUMP")
					end
				end
			end)()
		end
	end)

	connections.Client.threadCreate = Client:on("threadCreate", function(thread, new)
		coroutine.wrap(function()
			if not thread or not new or not thread.guild or (thread.guild.id ~= duckysPond.id) or not thread.parent or not thread.parent.id or (thread.parent.id ~= "1259521885805351033") then
				return
			end

			thread:applyTag("1279052577157288067")
		end)()
	end)

	connections.Client.messageCreate = Client:on("messageCreate", function(message)
		if message.webhookId == "1355300559392866446" and message.guild and message.guild.id == "1228508072289370172" and message.channel and message.channel.id == "1278154516147208275" then
			if message.embed and message.embed.title and message.embed.title:lower():find("new commit") then
				local branch = message.embed.title:lower():match("%[ducky:(.*)%]")
				local bot = "master"

				if branch == bot then
					if not message.embed.description:lower():find("%?nosync") then
						if (message.embed.author.name == "NickIsADev" or message.embed.author.name == "bobbibones0" or message.embed.author.name == "Lilkidb0k") or (branch ~= "master") then
							getCommand("sync").callback(message, {})
						end
					else
						message:warning("This commit was not pulled as the **`?nosync`** flag was detected.")
					end
				end
			end
		end
	end)
end

devlogs.Stop = function()
	for event, connection in pairs(connections.Client) do
		Client:removeListener(event, connection)
	end

	for event, connection in pairs(connections.Clock) do
		Clock:removeListener(event, connection)
	end

	Clock:stop()
	connections = nil
end

return devlogs
