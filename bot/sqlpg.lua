-- The attempt at switching to postgresql

local pg = require("postgres")

local conn

local function timestamp()
	return discordia.Date:fromSeconds(os.time()):toString("%x @ %I:%M:%S%p")
end

local function realtime()
	local seconds, microseconds = _G.uv.gettimeofday()
	return seconds + (microseconds / 1000000)
end

local sqldb = {}

sqldb.cache = {
	configs        = {},
	blacklists     = {},
	user_settings  = {},
	linksByDiscord = {},
	linksByRoblox  = {},
	plus           = {},
	affiliates     = {},
}

sqldb.debugActionsWL = {
	test = true
}

local function encodeTable(data)
	local succ, encoded = pcall(json.encode, data)
	if succ then
		return encoded
	else
		return nil, encoded
	end
end

local function decodeTable(data)
	local succ, decoded = pcall(json.decode, data)
	if succ then
		return decoded
	else
		return nil, decoded
	end
end

local function convertPlaceholders(sql)
	local i = 0
	return (sql:gsub("%?", function()
		i = i + 1
		return "$" .. i
	end))
end

--[[
	Log levels:
		- critical (saves, logs to console and sends webhook message with ping)
		- error (saves, logs to console and sends webhook message without ping)
		- warning (saves and logs to console)
		- info (saves)
		- debug (saves and logs to console when debug switch it enabled)
]]--

local logQueue = {}
local FLUSH_INTERVAL = 2000
local FLUSH_SIZE = 750

local function flushLogs()
	coroutine.wrap(function()
    if #logQueue == 0 then return end

    local batch = logQueue
    logQueue = {}

    local placeholders = {}
    local values = {}
    local i = 1
    for _, entry in ipairs(batch) do
        table.insert(placeholders, string.format("($%d, $%d, $%d)", i, i+1, i+2))
        table.insert(values, entry.level)
        table.insert(values, entry.action)
        table.insert(values, entry.data)
        i = i + 3
    end

    sqldb:_queryRun({
        query = "INSERT INTO logs (level, action, data) VALUES " .. table.concat(placeholders, ","),
        values = values
    })
	end)()
end

local function saveLog(level, action, data)
	-- if level == "debug" and not sqldb.debugActionsWL[action] then
	-- 	return
	-- end

    -- table.insert(logQueue, {
    --     level = level,
    --     action = action,
    --     data = json.encode(data or {})
    -- })

    -- if #logQueue >= FLUSH_SIZE then
    --     flushLogs()
    -- end

	-- if level == "critical" then
	-- 	prettyLog("SQLDB", "darkRed", "CRITICAL ERROR - Action: " .. tostring(action) .. " - Data: " .. json.encode(data or {}))

	-- 	-- local ok, res, err = pcall(http.request, "POST", webhook, {{"Content-Type", "application/json"}}, json.encode{
	-- 	-- 	content = "-# <@&1419398641180737606> \n## 🚨 CRITICAL ALERT\n- **Action:** " .. tostring(action) .. "\n- **Data:** ```" .. json.encode(data or {}) .. "```"
	-- 	-- })

	-- 	-- if not ok then
	-- 	-- 	p(res, err)
	-- 	-- end
	-- elseif level == "error" then
	-- 	prettyLog("SQLDB", "red", "Error - Action: " .. tostring(action) .. " - Data: " .. json.encode(data or {}))

	-- 	-- local ok, res, err = pcall(http.request, "POST", webhook, {{"Content-Type", "application/json"}}, json.encode{
	-- 	-- 	content = "## 🚨 Error\n- **Action:** " .. tostring(action) .. "\n- **Data:** ```" .. json.encode(data or {}) .. "```"
	-- 	-- })

	-- 	-- if not ok then
	-- 	-- 	p(res, err)
	-- 	-- end
	-- elseif level == "warning" then
	-- 	prettyLog("SQLDB", "yellow", "Warning - Action: " .. tostring(action) .. " - Data: " .. json.encode(data or {}))
	-- elseif level == "debug" then
	-- 	prettyLog("SQLDB", "cyan", "Debug - Action: " .. tostring(action) .. " - Data: " .. json.encode(data or {}))
	-- end
end

function sqldb:init()
	local pg_options = {
		host     = SECRETS.POSTGRES_HOST     or "postgres",
		port     = SECRETS.POSTGRES_PORT     or 5432,
		username = SECRETS.POSTGRES_USER     or "ducky",
		database = SECRETS.POSTGRES_DB       or "ducky",
		password = SECRETS.POSTGRES_PASSWORD,
	}

	local connErr
	conn, connErr = pg.connect(pg_options)
	if not conn then
		saveLog("critical", "pg.connect", {error = connErr, status = "disconnected"})
		error("SQLDB: Failed to connect to PostgreSQL: " .. tostring(connErr))
	end
	saveLog("info", "pg.connect", {status = "connected", host = pg_options.host, database = pg_options.database})

	conn.query([[
	  CREATE TABLE IF NOT EXISTS guilds (
	    guild_id       TEXT NOT NULL,
	    setting_key    TEXT NOT NULL,
	    setting_value  TEXT,
	    setting_type   TEXT DEFAULT 'string',
	    PRIMARY KEY (guild_id, setting_key)
	  );
	]])

	conn.query([[
	  CREATE TABLE IF NOT EXISTS links (
	    discord TEXT PRIMARY KEY,
	    roblox  BIGINT
	  );
	]])

	conn.query([[
	  CREATE TABLE IF NOT EXISTS errors (
	    id   TEXT PRIMARY KEY,
	    info TEXT
	  );
	]])

	conn.query([[
	  CREATE TABLE IF NOT EXISTS plus (
	    userid       TEXT PRIMARY KEY,
	    slots        INTEGER,
	    guilds       TEXT,
	    codes        TEXT,
	    transactions TEXT
	  );
	]])

	conn.query([[
	  CREATE TABLE IF NOT EXISTS blacklists (
	    id     TEXT PRIMARY KEY,
	    reason TEXT
	  );
	]])

	conn.query([[
	  CREATE TABLE IF NOT EXISTS affiliates (
	    id TEXT PRIMARY KEY
	  );
	]])

	conn.query([[
	  CREATE TABLE IF NOT EXISTS exportables (
	    id             TEXT PRIMARY KEY,
	    owner          TEXT,
	    "createdAt"    BIGINT,
	    "lastImported" BIGINT,
	    "type"         TEXT,
	    data           TEXT,
	    name           TEXT
	  );
	]])

	conn.query([[
	  CREATE TABLE IF NOT EXISTS user_settings (
	    id     TEXT PRIMARY KEY,
	    config TEXT
	  );
	]])

	conn.query([[
	  CREATE TABLE IF NOT EXISTS utils (
	    key   TEXT NOT NULL PRIMARY KEY,
	    value TEXT
	  );
	]])

	conn.query([[
	  CREATE TABLE IF NOT EXISTS "refreshTokens" (
	    id             TEXT PRIMARY KEY,
	    "refreshToken" TEXT
	  );
	]])

	conn.query([[
	  CREATE TABLE IF NOT EXISTS auth_sessions (
	    "user"         TEXT NOT NULL PRIMARY KEY,
	    token          TEXT NOT NULL,
	    "discordToken" TEXT NOT NULL,
	    "refreshToken" TEXT NOT NULL
	  );
	]])

	conn.query([[
	  CREATE TABLE IF NOT EXISTS logs (
	    id             BIGSERIAL PRIMARY KEY,
	    ts             TIMESTAMPTZ DEFAULT NOW(),
	    level          TEXT,
	    action         TEXT,
		data           JSONB
	  );
	  CREATE INDEX ON logs (ts DESC);
	  CREATE INDEX ON logs (action);
	]]) -- index speeds up filterting by time and action

	saveLog("info", "create tables", {status = "success"})

	sqldb:getAllGuildConfigs(true)
	sqldb:allAffiliates()
	sqldb:plusAll(true)
	sqldb:getAllLinks(true)

	do
		local success, rows = sqldb:_queryRun({
			query = "SELECT id, reason FROM blacklists"
		})
		if success then
			for _, blacklist in pairs(rows) do
				sqldb.cache.blacklists[blacklist.id] = {id = blacklist.id, reason = blacklist.reason}
			end
		else
			saveLog("critical", "init", {status = "blacklist cache failed", error = tostring(rows)})
		end
	end

	do
		sqldb.cache.user_settings = {}
		local success, rows = sqldb:_queryRun({
			query = "SELECT id, config FROM user_settings"
		})
		if success then
			for _, userSetting in pairs(rows) do
				sqldb.cache.user_settings[userSetting.id] = decodeTable(userSetting.config) or {}
			end
		else
			saveLog("critical", "init", {status = "usersettings cache failed", error = tostring(rows)})
		end
	end

	sqldb.logIntervalTimer = timer.setInterval(FLUSH_INTERVAL, flushLogs)
end



local function safeResume(co, ...)
	if type(co) ~= "thread" then return false, "Invalid coroutine" end
	if coroutine.status(co) ~= "suspended" then return false, "Coroutine not suspended" end
	local ok, result = coroutine.resume(co, ...)
	if not ok then
		return false, result
	end
	return true, result
end

function sqldb:_queryRun(query)
	local sql = convertPlaceholders(query.query)
	local values = query.values

	local result, err
	if values and #values > 0 then
		result, err = conn.queryParams(sql, values)
	else
		result, err = conn.query(sql)
	end

	if not result then
		saveLog("error", ((values and #values > 0 and "conn.queryParams") or "conn.query"), {query = tostring(query.query), values = query.values, error = tostring(err)})
		return false, tostring(err)
	end

	return true, result.rows or {}
end

function sqldb:_set_single(guild_id, key, value, reason)
	reason = reason or "no reason provided"
	local setting_type = type(value)

	local value_to_store
	if type(value) == "table" then
		value_to_store = encodeTable(value)
	else
		value_to_store = tostring(value)
	end

	local success, result = sqldb:_queryRun({
		query = [[
			INSERT INTO guilds (guild_id, setting_key, setting_value, setting_type)
			VALUES (?, ?, ?, ?)
			ON CONFLICT (guild_id, setting_key) DO UPDATE SET
				setting_value = EXCLUDED.setting_value,
				setting_type  = EXCLUDED.setting_type
		]],
		values = {guild_id, key, value_to_store, setting_type}
	})

	if success then
		sqldb.cache.configs[guild_id] = sqldb.cache.configs[guild_id] or {}
		sqldb.cache.configs[guild_id][key] = value
		return true
	else
		saveLog("error", "set_single", {key = tostring(key), set_reason = tostring(reason), guild_id = tostring(guild_id), value = value, error = tostring(result)})
		return false, "Failed to write single."
	end
end

function sqldb:_delete_single(guild_id, key, reason)
	reason = reason or "no reason provided"

	local success, result = sqldb:_queryRun({
		query = "DELETE FROM guilds WHERE guild_id = ? AND setting_key = ?",
		values = {guild_id, key}
	})

	if success then
		sqldb.cache.configs[guild_id] = sqldb.cache.configs[guild_id] or {}
		sqldb.cache.configs[guild_id][key] = nil
		return true
	else
		saveLog("error", "delete_single", {key = tostring(key), delete_reason = tostring(reason), guild_id = tostring(guild_id), error = tostring(result)})
		return false, "Failed to delete single."
	end
end

function sqldb:get(guild_id, notCached)
	if not notCached then
		return sqldb.cache.configs[guild_id]
	end

	local success, rows = sqldb:_queryRun({
		query = "SELECT * FROM guilds WHERE guild_id = ?",
		values = {guild_id},
	})

	if not success then
		return nil
	end

	local config = {}
	for _, field in pairs(rows) do
		field.setting_type = field.setting_type or "string"
		if field.setting_type == "boolean" and field.setting_value == "true" then
			field.setting_value = true
		elseif field.setting_type == "boolean" and field.setting_value == "false" then
			field.setting_value = false
		elseif field.setting_type == "number" then
			field.setting_value = tonumber(field.setting_value)
		elseif field.setting_type == "table" then
			local ok, decoded = pcall(json.decode, field.setting_value)
			if ok then
				field.setting_value = decoded
			else
				field.setting_value = {}
			end
		end
		config[field.setting_key] = field.setting_value
	end

	if not next(config) then
		return nil
	end

	sqldb.cache.configs[guild_id] = config
	return config
end

local writeQueue = {}
local writeQueueRunning = false

local function processWriteQueue()
	if writeQueueRunning or #writeQueue == 0 then return end
	writeQueueRunning = true

	local function runNext()
		if #writeQueue == 0 then
			writeQueueRunning = false
			return
		end

		local job = table.remove(writeQueue, 1)

		if job.op == "set" then
			sqldb:_set_single(job.guild_id, job.key, job.value, job.reason)
		elseif job.op == "delete" then
			sqldb:_delete_single(job.guild_id, job.key, job.reason)
		end

		timer.setTimeout(0, function()
			coroutine.wrap(runNext)()
		end)
	end

	runNext()
end

function sqldb:set(guild_id, changes_table, reason, member)
	reason = reason or "no reason provided"
	sqldb.cache.configs = sqldb.cache.configs or {}
	if not guild_id or type(guild_id) ~= "string" or not tonumber(guild_id) then
		saveLog("error", "set", {error = "guild_id is invalid or not provided", guild_id = tostring(guild_id)})
		return false, "guild_id is invalid or not provided"
	end

	if not changes_table or type(changes_table) ~= "table" or table.count(changes_table) < 1 then
		saveLog("error", "set", {error = "changes_table is invalid or not provided", changes_table = (type(changes_table) ~= "table" and tostring(changes_table) or changes_table)})
		return false, "changes_table is invalid or not provided"
	end

	if not reason or type(reason) ~= "string" then
		saveLog("error", "set", {error = "reason is invalid or not provided", reason = tostring(reason)})
		return false, "reason is invalid or not provided"
	end

	sqldb.cache.configs[guild_id] = sqldb.cache.configs[guild_id] or {}
	local config = sqldb.cache.configs[guild_id]
	local changes = ""

	for key, value in pairs(changes_table) do
		local previous = config[key] or "nothing"

		if tostring(value) == "nil" then
			config[key] = nil

			changes = changes .. emojis.space .. emojis.right .. " **`" .. reason .. "`**・"
			changes = changes .. "**Removed `" .. key .. "`:**"
			changes = changes .. "\n"

			table.insert(writeQueue, { op = "delete", guild_id = guild_id, key = key, reason = reason })
		else
			config[key] = value

			changes = changes .. emojis.space .. emojis.right .. " **`" .. reason .. "`**・"

			if type(value) == "table" then
				changes = changes .. "**Modified `" .. key .. "`:**"
			else
				if key == "apikey" or key == "bloxlinkServerKey" then
					changes = changes .. "**Changed `" .. key .. "`:** `" .. tostring(string.truncate(previous, 8)) .. "` " .. emojis.right .. " `" .. tostring(string.truncate(value, 8)) .. "`"
				else
					changes = changes .. "**Changed `" .. key .. "`:** `" .. tostring(previous) .. "` " .. emojis.right .. " `" .. tostring(value) .. "`"
				end
			end

			changes = changes .. "\n"

			table.insert(writeQueue, { op = "set", guild_id = guild_id, key = key, value = value, reason = reason })
		end
	end

	processWriteQueue()

	if db and member and config.configlogchannel then
		db:send(guild_id, "configlogchannel", {
			embed = {
				author = author(member),
				title = emojis.settings .. " Configuration Modified",
				description = "> " .. getUserString(member) .. " has modified this server's configuration.\n\n" .. emojis.edit .. " **Changes:**\n" .. changes,
				color = colors.info
			}
		})
	end

	saveLog("info", "set", {guild_id = tostring(guild_id), changes_table = changes_table, reason = tostring(reason)})

	return true, sqldb.cache.configs[guild_id]
end

function sqldb:getAllGuildConfigs(notCached)
	if not notCached and sqldb.cache.configs then
		return sqldb.cache.configs
	end

	local success, rows = sqldb:_queryRun({
		query = "SELECT * FROM guilds"
	})

	if not success then
		saveLog("error", "getAllGuildConfigs", {error = tostring(rows)})
		return nil, "Failed to fetch all guild configs"
	end

	local guildConfigs = {}
	for _, field in pairs(rows) do
		guildConfigs[field.guild_id] = guildConfigs[field.guild_id] or {}

		field.setting_type = field.setting_type or "string"
		if field.setting_type == "boolean" and field.setting_value == "true" then
			field.setting_value = true
		elseif field.setting_type == "boolean" and field.setting_value == "false" then
			field.setting_value = false
		elseif field.setting_type == "number" then
			field.setting_value = tonumber(field.setting_value)
		elseif field.setting_type == "table" then
			local ok, decoded = pcall(json.decode, field.setting_value)
			if ok then
				field.setting_value = decoded
			else
				field.setting_value = {}
			end
		end

		guildConfigs[field.guild_id][field.setting_key] = field.setting_value
	end

	sqldb.cache.configs = guildConfigs
	return guildConfigs
end

function sqldb:registerGuild(guild_id)
	local config = sqldb:get(guild_id)
	if config then
		return true, config
	end
	config = { prefix = "d!" }
	saveLog("info", "registerGuild", {guild_id = tostring(guild_id)})
	return sqldb:set(guild_id, config, "REGISTER_GUILD")
end

function sqldb:delete(guild_id)
	if not guild_id or type(guild_id) ~= "string" or not tonumber(guild_id) then
		saveLog("error", "delete", {error = "invalid guild_id provided", guild_id = tostring(guild_id)})
		return false, "guild_id was invalid or not provided"
	end

	local success, result = sqldb:_queryRun({
		query = "DELETE FROM guilds WHERE guild_id = ?",
		values = {guild_id},
	})

	if success then
		sqldb.cache.configs[guild_id] = nil
		saveLog("info", "delete", {guild_id = tostring(guild_id)})
		return true
	else
		saveLog("error", "delete", {error = tostring(result), guild_id = tostring(guild_id)})
		return false, "Failed to delete config"
	end
end

function sqldb:setConfigKeyType(key, key_type)
	if type(key) ~= "string" then
		saveLog("error", "setConfigKeyType", {error = "invalid key provided", key = tostring(key), key_type = tostring(key_type)})
		return false, "Invalid key."
	end

	if type(key_type) ~= "string" or (key_type ~= "string" and key_type ~= "number" and key_type ~= "table") then
		saveLog("error", "setConfigKeyType", {error = "invalid key_type provided", key_type = tostring(key_type), key = tostring(key)})
		return false, "Invalid keyType."
	end

	saveLog("info", "setConfigKeyType", {status = "Starting guild config transfer to include setting_type"})

	local success, rows = sqldb:_queryRun({
		query = "SELECT guild_id, setting_key, setting_value FROM guilds"
	})

	if not success then
		saveLog("error", "setConfigKeyType", {error = "failed to fetch guild data for transfer", result = tostring(rows)})
		return false, "Failed to fetch guild data."
	end

	if not rows or #rows == 0 then
		saveLog("error", "setConfigKeyType", {error = "no data to transfer for setting_type", key = tostring(key), key_type = tostring(key_type)})
		return true
	end

	local total = #rows
	saveLog("info", "setConfigKeyType", {status = "found records to process", total = total, key = tostring(key), key_type = (tostring(key_type))})

	local success_count = 0
	local error_count = 0

	conn.query("BEGIN;")

	for i, row in ipairs(rows) do
		if row.setting_key == key then
			local ok, err = sqldb:_queryRun({
				query = "UPDATE guilds SET setting_type = ? WHERE guild_id = ? AND setting_key = ?",
				values = {key_type, row.guild_id, row.setting_key}
			})

			if ok then
				success_count = success_count + 1
			else
				error_count = error_count + 1
				saveLog("error", "setConfigKeyType", {error = "failed to update row", result = tostring(err), guild_id = tostring(row.guild_id), key = tostring(key), key_type = tostring(key_type)})
			end

			if i % 500 == 0 then
				saveLog("info", "setConfigKeyType", {status = "Processing transfer...", count = i, total = total})
			end
		end
	end

	conn.query("COMMIT;")

	saveLog("info", "setConfigKeyType", {status = "transfer complete", key = tostring(key), key_type = tostring(key_type), success_count = success_count, error_count = error_count})
	return true, success_count, error_count
end

function sqldb:plusSet(id, plus)
	if type("id") ~= "string" then
		saveLog("error", "plusSet", {error = "Invalid id provided", user_id = id})
		return false, "Invalid id provided."
	end

	plus.userid = plus.userid or id

	if type(plus) ~= "table" or not plus.userid or type(plus.slots) ~= "number" or type(plus.guilds) ~= "table" or type(plus.transactions) ~= "table" or type(plus.codes) ~= "table" then
		saveLog("error", "plusSet", {error = "Invalid plus table provided", user_id = id, plus_data_type = type(plus)})
		return false, "Invalid plus table."
	end

	local guildsEncoded = encodeTable(plus.guilds)
	if not guildsEncoded then
		saveLog("error", "plusSet", {error = "Failed to encode guilds table for user", user_id = id})
		return false, "Failed to encode guilds table."
	end

	local transactionsEncoded = encodeTable(plus.transactions)
	if not transactionsEncoded then
		saveLog("error", "plusSet", {error = "Failed to encode transactions table for user", user_id = id})
		return false, "Failed to encode transactions table."
	end

	local codesEncoded = encodeTable(plus.codes)
	if not codesEncoded then
		saveLog("error", "plusSet", {error = "Failed to encode codes table for user", user_id = id})
		return false, "Failed to encode codes table."
	end

	p(id, tostring(plus.slots), guildsEncoded, transactionsEncoded, codesEncoded)
	local success, result = sqldb:_queryRun({
		query = [[
			INSERT INTO plus (userid, slots, guilds, transactions, codes)
			VALUES (?, ?, ?, ?, ?)
			ON CONFLICT (userid) DO UPDATE SET
				slots        = EXCLUDED.slots,
				guilds       = EXCLUDED.guilds,
				transactions = EXCLUDED.transactions,
				codes        = EXCLUDED.codes
		]],
		values = {id, plus.slots, guildsEncoded, transactionsEncoded, codesEncoded},
	})

	if success then
		sqldb.cache.plus[id] = plus
		saveLog("info", "plusSet", {status = "Set plus for user successfully", user_id = id, slots = plus.slots, num_guilds = table.count(plus.guilds)})
		return true, plus
	else
		saveLog("error", "plusSet", {error = "Failed to execute query to set plus data for user", user_id = id, query_result = result})
		return false, "Failed to execute query"
	end
end

function sqldb:plusAll(notCached)
	if not notCached then
		return true, sqldb.cache.plus
	end

	local success, rows = sqldb:_queryRun({
		query = "SELECT * FROM plus"
	})

	if not success then
		saveLog("error", "plusAll", {error = "Failed to fetch all plus data from database"})
		return false, "Failed to fetch plusAll"
	end

	local allPlus = {}
	for _, v in pairs(rows) do
		if type(v) == "table" and v.userid then
			if type(v.guilds) == "string" then
				v.guilds = decodeTable(v.guilds) or {}
			end
			if type(v.transactions) == "string" then
				v.transactions = decodeTable(v.transactions) or {}
			end
			if type(v.codes) == "string" then
				v.codes = decodeTable(v.codes) or {}
			end
			allPlus[v.userid] = v
		end
	end

	if type(allPlus) == "table" then
		saveLog("info", "plusAll", {status = "Fetched all plus data from database"})
		sqldb.cache.plus = allPlus
		return true, allPlus
	else
		saveLog("error", "plusAll", {error = "Failed to fetch all plus data from database due to invalid transform result", transform_result_type = type(allPlus)})
		return false, "Failed to fetch plusAll"
	end
end

function sqldb:plusMember(user, notCached)
	if not user then
		saveLog("error", "plusMember", {error = "User not provided for plusMember"})
		return false, "User not provided."
	end

	if type(user) == "table" then
		user = user.id
	end

	local plus

	if not notCached then
		plus = sqldb.cache.plus[user]
	else
		local success, rows = sqldb:_queryRun({
			query = "SELECT * FROM plus WHERE userid = ?",
			values = {user},
		})

		if success and type(rows) == "table" and rows[1] then
			local rawPlus = rows[1]

			if type(rawPlus.guilds) == "string" then
				rawPlus.guilds = decodeTable(rawPlus.guilds) or {}
			end
			if type(rawPlus.transactions) == "string" then
				rawPlus.transactions = decodeTable(rawPlus.transactions) or {}
			end
			if type(rawPlus.codes) == "string" then
				rawPlus.codes = decodeTable(rawPlus.codes) or {}
			end

			plus = rawPlus
		else
			if not success then
				saveLog("error", "plusMember", {error = "Failed to fetch plus data for user from database", user_id = user})
			end
		end
	end

	plus = plus or {}
	plus.slots = plus.slots or 0
	plus.guilds = plus.guilds or {}
	plus.transactions = plus.transactions or {}
	plus.codes = plus.codes or {}

	if plus.slots > 0 or table.count(plus.guilds) > 0 then
		sqldb.cache.plus[user] = plus
		return true, plus
	else
		return false, plus
	end
end

function sqldb:plusGuild(guild, notCached)
	if not guild then
		saveLog("error", "plusGuild", {error = "Guild not provided for plusGuild"})
		return false, "Guild not provided."
	end

	if type(guild) == "table" then
		guild = guild.id
	end

	local succAllPlus, allPlus = sqldb:plusAll(notCached)

	if not succAllPlus then
		saveLog("error", "plusGuild", {error = "Failed to fetch all plus data for plusGuild check", guild_id = tostring(guild)})
		return false, "Failed to fetch plus information."
	end

	for _, plus in pairs(allPlus) do
		if type(plus.guilds) == "table" and table.find(plus.guilds, guild) then
			return true, plus
		end
	end

	if sqldb:isAffiliate(guild) then
		return true, {
			userid = Client.user.id,
			slots = 0,
			guilds = { guild },
		}
	end
	return false
end

function sqldb:plusTransaction(transactionToken)
	local succ, allPlus = sqldb:plusAll()

	if not succ or type(allPlus) ~= "table" then
		saveLog("error", "plusTransaction", {error = "Failed to get all plus data for plusTransaction check", transaction_token = transactionToken})
		return false, "Failed to get all plus data"
	end

	for _, plus in pairs(allPlus) do
		if type(plus.transactions) == "table" and next(plus.transactions) then
			for _, transaction in pairs(plus.transactions) do
				if type(transaction) == "table" then
					if transaction.token == transactionToken then
						saveLog("debug", "plusTransaction", {status = "Plus transaction found", transaction_token = transactionToken, user_id = plus.userid})
						return true, transaction
					end
				end
			end
		end
	end

	saveLog("info", "plusTransaction", {status = "Plus transaction not found", transaction_token = transactionToken})
	return nil, "Transaction not found"
end

function sqldb:plusPurchase(user, slots, discount, paid, roblox, transactionToken, time)
	time = time or os.time()

	if not user then
		saveLog("error", "plusPurchase", {error = "User not provided for plusPurchase"})
		return false, "User not provided."
	end

	if not (type(user) == "table" and (class(user) == "Member" or class(user) == "User")) and not type(user) == "string" then
		saveLog("error", "plusPurchase", {error = "Invalid user provided for plusPurchase", user_id = tostring(user)})
		return false, "Invalid user provided"
	elseif type(user) == "string" then
		user = Client:getUser(user)

		if not user then
			saveLog("error", "plusPurchase", {error = "User not found for plusPurchase", user_id = tostring(user)})
			return false, "User not found"
		end
	end

	if type(paid) ~= "number" then
		saveLog("error", "plusPurchase", {error = "Invalid paid value provided for plusPurchase", paid_value = paid, user_id = tostring(user.id)})
		return false, "Invalid paid value provided"
	end

	if type(roblox) ~= "table" or not roblox.id then
		saveLog("error", "plusPurchase", {error = "Invalid roblox object provided for plusPurchase", roblox_data = tostring(roblox), user_id = tostring(user.id)})
		return false, "Invalid roblox object provided"
	end

	if type(transactionToken) ~= "string" then
		saveLog("error", "plusPurchase", {error = "Invalid transactionToken provided for plusPurchase", transaction_token = transactionToken, user_id = tostring(user.id)})
		return false, "Invalid transactionToken provided"
	end

	local pcallSuccess, functionSuccessOrPcallError, functionResult = pcall(function()
		local claimedTransaction = sqldb:plusTransaction(transactionToken)
		if claimedTransaction == false then
			saveLog("error", "plusPurchase", {error = "Failed to validate transaction for plusPurchase", transaction_token = transactionToken, user_id = tostring(user.id)})
			return false, "Failed to validate transaction"
		elseif claimedTransaction == true then
			saveLog("warning", "plusPurchase", {status = "Plus already claimed for plusPurchase", transaction_token = transactionToken, user_id = tostring(user.id)})
			return false, "Plus already claimed"
		end

		local pond = pondMember(user)

		if pond and not pond:hasRole("1267239172444262490") then
			pond:addRole("1267239172444262490", "purchased Ducky Plus+")
			saveLog("info", "plusPurchase", {status = "Added Ducky Plus+ role to user", user_id = user.id, role_id = "1267239172444262490"})
		end

		local _, plus = sqldb:plusMember(user, true)

		if not plus then
			plus = {
				userid = user.id,
				slots = 0,
				guilds = {},
				transactions = {},
				codes = {}
			}
			saveLog("info", "plusPurchase", {status = "Initialized new plus data for user", user_id = user.id})
		end

		plus.slots = plus.slots + slots
		table.insert(plus.transactions, {
			token = transactionToken,
			timestamp = time,
			discount = discount,
			paid = paid,
			slots = slots,
			roblox = roblox.id
		})

		if discount then
			plus.codes[discount.code] = (plus.codes[discount.code] or 0) + 1
		end

		local succ, errorOrPlus = sqldb:plusSet(user.id, plus)

		if succ then
			utilityChannels.receipts:send({
				embed = {
					author = {
						name = "@" .. user.username .. " (" .. user.id .. ")",
						icon_url = user.avatarURL
					},
					title = emojis.success .. " Purchase Successful",
					description = "> **@" .. user.username .. "** has purchased **" .. slots .. " slot" .. ((slots ~= 1 and "s") or "") .. "** of " .. emojis.duckyplus .. " **Ducky Plus+**!\n\n" .. emojis.document .. " **Purchase Receipt**\n" .. emojis.right .. " **Slots:** " .. slots .. "\n" .. emojis.right .. " **Discount Code:** " .. ((discount and ("`" .. discount.code .. "` (" .. discount.percentage .. "% off)")) or "N/A") .. "\n" .. emojis.right .. " **Total:** " .. emojis.robux .. " " .. formatNumber(paid) .. "\n" .. emojis.right .. " **Date:** <t:" .. os.time() .. ">\n" .. emojis.right .. " **Transaction:** `" .. transactionToken .. "`",
					timestamp = toISO(os.time()),
					color = colors.success,
					thumbnail = thumbnail(user),
					footer = {
						text = (roblox.displayName or roblox.name) .. " (@" .. roblox.name .. ") (" .. roblox.id .. ")",
						icon_url = roblox.avatar
					}
				}
			})
			user:send(emojis.success .. " You have been granted **" .. slots .. " slot" .. ((slots ~= 1 and "s") or "") .. "** of " .. emojis.duckyplus .. " **Ducky Plus+**. Thank you for your support!\n-# " .. emojis.document .. " **Transaction Token:** " .. transactionToken)
			utilityChannels.supporters:send(":heart: " .. user.mentionString .. " has purchased **" .. slots .. " slot" .. ((slots ~= 1 and "s") or "") .. "** of " .. emojis.duckyplus .. " **Ducky Plus+**!\n-# " .. emojis.right .. " Thank you for your support!")

			saveLog("info", "plusPurchase", {status = "User purchased Ducky Plus+ slots successfully", user_id = user.id, slots_purchased = slots, total_slots = plus.slots, transaction_token = transactionToken})
			return true, errorOrPlus
		else
			saveLog("error", "plusPurchase", {error = "Failed to set plus data for user after purchase logic", user_id = user.id, error_message = tostring(errorOrPlus)})
			error("Failed to set plus data: " .. tostring(errorOrPlus))
		end
	end)

	if not pcallSuccess then
		user:send(emojis.fail .. " An unexpected error occurred while attempting to grant you **" .. slots .. " slot" .. ((slots ~= 1 and "s") or "") .. "** of " .. emojis.duckyplus .. " **Ducky Plus+**. Please contact the " .. emojis.support .. " **Ducky Support** team.")
		utilityChannels.receipts:send({
			embed = {
				author = {
					name = "@" .. user.username .. " (" .. user.id .. ")",
					icon_url = user.avatarURL
				},
				title = emojis.fail .. " Purchase Failed",
				description = "> **@" .. user.username .. "** attempted to purchase **" .. slots .. " slot" .. ((slots ~= 1 and "s") or "") .. "** of " .. emojis.duckyplus .. " **Ducky Plus+**.\n\n" .. emojis.document .. " **Purchase Receipt**\n" .. emojis.right .. " **Slots:** " .. slots .. "\n" .. emojis.right .. " **Discount Code:** " .. ((discount and ("`" .. discount.code .. "` (" .. discount.percentage .. "% off)")) or "N/A") .. "\n" .. emojis.right .. " **Total:** " .. emojis.robux .. " " .. formatNumber(paid) .. "\n" .. emojis.right .. " **Date:** <t:" .. time .. ">\n" .. emojis.right .. " **Transaction:** `" .. transactionToken .. "`\n" .. emojis.right .. " **Error:** `" .. tostring(functionSuccessOrPcallError) .. "`",
				timestamp = toISO(os.time()),
				color = colors.fail,
				thumbnail = thumbnail(user),
				footer = {
					text = (roblox.displayName or roblox.name) .. " (@" .. roblox.name .. ") (" .. roblox.id .. ")",
					icon_url = roblox.avatar
				}
			}
		})

		saveLog("critical", "plusPurchase", {error = "plusPurchase logic crashed", user_id = user and user.id, slots_purchased = slots, transaction_token = transactionToken, pcall_error = tostring(functionSuccessOrPcallError)})
		return false, "Logic crashed: " .. tostring(functionSuccessOrPcallError)
	end

	return functionSuccessOrPcallError, functionResult
end

function sqldb:plusUse(user, guild)
	if not user then
		saveLog("error", "plusUse", {error = "User not provided for plusUse"})
		return false, "User not provided."
	end

	if type(user) == "table" then
		user = user.id
	end

	if not guild then
		saveLog("error", "plusUse", {error = "Guild not provided for plusUse"})
		return false, "Guild not provided."
	end

	if type(guild) == "table" then
		guild = guild.id
	end

	local active, plus = sqldb:plusMember(user, true)

	if (not active) or not plus then
		saveLog("error", "plusUse", {error = "User does not have a Ducky Plus+ purchase", user_id = user, guild_id = guild})
		return false, "You do not have a Ducky Plus+ purchase."
	elseif plus.slots < 1 then
		saveLog("error", "plusUse", {error = "User does not have any Ducky Plus+ slots available", user_id = user, guild_id = guild, available_slots = plus.slots})
		return false, "You do not have any Ducky Plus+ slots available."
	end

	plus.slots = plus.slots - 1
	table.insert(plus.guilds, guild)
	saveLog("info", "plusUse", {status = "User used a Ducky Plus+ slot", user_id = user, remaining_slots = plus.slots, guild_added = guild, guild_id = tostring(guild)})

	return sqldb:plusSet(user, plus)
end

function sqldb:plusRefund(user, guild)
	if type(user) == "string" then
		user = Client:getUser(user)
	end

	if class(user) ~= "Member" and class(user) ~= "User" then
		saveLog("error", "plusRefund", {error = "User not provided or not found for plusRefund", user_id = user and user.id})
		return false, "User not provided or not found."
	end

	if class(guild) == "Guild" then
		guild = guild.id
	end

	local Guild = Client:getGuild(guild)

	local active, plus = sqldb:plusMember(user, true)

	if (not active) or not plus then
		saveLog("warning", "plusRefund", {error = "User does not have a Ducky Plus+ purchase to refund", user_id = user.id})
		return false, "You do not have a Ducky Plus+ purchase."
	end

	local plusChanged

	for i, g in pairs(plus.guilds) do
		if g == guild then
			table.remove(plus.guilds, i)
			plus.slots = plus.slots + 1
			plusChanged = true
			saveLog("info", "plusRefund", {status = "Removed guild from plus guilds and refunded slot", user_id = user.id, guild_id = guild, new_slots = plus.slots})
		end
	end

	if not plusChanged then
		saveLog("warning", "plusRefund", {error = "User is not providing Ducky Plus+ to that server for refund", user_id = user.id, guild_id = guild})
		return false, "You are not providing Ducky Plus+ to that server."
	end

	local plusSetSuccess, plusSetError = sqldb:plusSet(user.id, plus)

	if not plusSetSuccess then
		saveLog("error", "plusRefund", {error = "Failed to set plus data after refund attempt", guild_id = guild, error_message = plusSetError, user_id = user.id})
		return false, plusSetError
	end

	local active = sqldb:plusGuild(guild)

	if not active then
		coroutine.wrap(function()
			if Guild then
				Guild:setProfile()
			end
		end)()

		local config = sqldb:get(guild)

		if type(config) == "table" and next(config) then
			local configChanges = {}

			if type(config.automations) == "table" and next(config.automations) then
				local changed
				for i, ams in pairs(config.automations) do
					if i > featureLimits.automations.normal or table.count(ams.actions) > featureLimits.automationActions.normal then
						ams.disabled = true
						changed = true
					end
				end

				if changed then configChanges.automations = config.automations end
			end

			if type(config.autoresponders) == "table" and next(config.autoresponders) then
				local changed
				for i, ar in pairs(config.autoresponders) do
					if i > featureLimits.autoresponders.normal then
						ar.disabled = true
						changed = true
					end
				end

				if changed then configChanges.autoresponders = config.autoresponders end
			end

			if type(config.reactionboards) == "table" and next(config.reactionboards) then
				local changed
				for i, board in pairs(config.reactionboards) do
					if i > featureLimits.reactionboards.normal then
						board.disabled = true
						changed = true
					end
				end

				if changed then configChanges.reactionboards = config.reactionboards end
			end

			if type(config.panels) == "table" and next(config.panels) then
				local changed
				local count = 0
				for i, panel in pairs(config.panels) do
					count = count + 1
					if count > featureLimits.ticketPanels.normal then
						panel.disabled = true
						changed = true
					end
				end

				if changed then configChanges.panels = config.panels end
			end

			if type(config.autodeletechannels) == "table" and next(config.autodeletechannels) then
				local changed
				local count = 0
				for i, deletechannel in pairs(config.autodeletechannels) do
					count = count + 1
					if count > featureLimits.autodeletechannels.normal then
						deletechannel.disabled = true
						changed = true
					end
				end

				if changed then configChanges.autodeletechannels = config.autodeletechannels end
			end

			if type(config.stickymessages) == "table" and next(config.stickymessages) then
				local changed
				for i, stickymessage in pairs(config.stickymessages) do
					if i > featureLimits.stickymessages.normal then
						stickymessage.disabled = true
						changed = true
					end
				end

				if changed then configChanges.stickymessages = config.stickymessages end
			end

			if type(config.erlcserverstatuschannels) == "table" and next(config.erlcserverstatuschannels) then
				local changed
				for i, sh in pairs(config.erlcserverstatuschannels) do
					if i > featureLimits.erlcStatusChannels.normal then
						sh.locked = true
						changed = true

						if Guild then
							coroutine.wrap(function()
								local c = Guild:getChannel(sh.channel)

								if c then
									c:setName("🔒" .. emojis.dot .. c.name)
								end
							end)()
						end
					end
				end

				if changed then configChanges.erlcserverstatuschannels = config.erlcserverstatuschannels end
			end

			if type(config.discordserverstatuschannels) == "table" and next(config.discordserverstatuschannels) then
				local changed
				for i, sh in pairs(config.discordserverstatuschannels) do
					if i > featureLimits.discordStatusChannels.normal then
						sh.locked = true
						changed = true

						if Guild then
							coroutine.wrap(function()
								local c = Guild:getChannel(sh.channel)

								if c then
									c:setName("🔒" .. emojis.dot .. c.name)
								end
							end)()
						end
					end
				end

				if changed then configChanges.discordserverstatuschannels = config.discordserverstatuschannels end
			end

			if next(configChanges) then
				local setSuccess, setError = sqldb:set(guild, configChanges, "PLUS_SLOT_REFUND", user)

				if not setSuccess then
					saveLog("error", "plusRefund", {error = "Failed to disable Ducky Plus+ features after refund", user_id = user.id, error_message = setError, guild_id = guild})
					return false, "Failed to disable Ducky Plus+ features: " .. setError
				end
				saveLog("info", "plusRefund", {status = "Ducky Plus+ features disabled for guild after refund", user_id = user.id, guild_id = guild})
			end
		end
	end

	utilityChannels.receipts:send(emojis.undo .. " **@" .. user.username .. "** (" .. user.id .. ") refunded one of their " .. emojis.duckyplus .. " **Ducky Plus+** slots from **" .. ((Guild and Guild.name) or "*Unknown*") .. "** (" .. guild .. ").")
	saveLog("info", "plusRefund", {status = "success", user_id = tostring(user.id), guild_id = tostring(guild)})
	return true, plus
end

function sqldb:plusGift(user, targetUser)
	if not user then
		saveLog("error", "plusGift", {error = "user not provided"})
		return false, "User not provided."
	end

	if type(user) == "table" then
		user = user.id
	end

	local pondUser = pondMember(user)

	if not targetUser then
		saveLog("error", "plusGift", {error = "targetUser not provided", user_id = user})
		return false, "TargetUser not provided."
	end

	if type(targetUser) == "table" then
		targetUser = targetUser.id
	end

	local pondTarget = pondMember(targetUser)

	if user == targetUser then
		saveLog("warning", "plusGift", {user_id = user, error = "user attempted to gift themselves"})
		return false, "You cannot gift a slot to yourself."
	end

	local userActive, userPlus = sqldb:plusMember(user, true)
	if (not userActive) or not userPlus then
		saveLog("warning", "plusGift", {error = "gifting user does not have a Ducky Plus+ subscription", user_id = user})
		return false, "You do not have a Ducky Plus+ purchase."
	elseif userPlus.slots <= 0 then
		saveLog("warning", "plusGift", {error = "gifting user does not have any Ducky Plus+ slots available", user_id = user, available_slots = userPlus.slots})
		return false, "You do not have any Ducky Plus+ slots available."
	end

	local targetActive, targetPlus = sqldb:plusMember(targetUser, true)
	if (not targetActive) or not targetPlus then
		targetPlus = {
			userid = targetUser,
			slots = 0,
			guilds = {},
			transactions = {},
			codes = {}
		}
		saveLog("info", "plusGift", {info = "Initialized new plus data for target user", target_user_id = targetUser})
	end

	userPlus.slots = userPlus.slots - 1
	targetPlus.slots = targetPlus.slots + 1

	if pondTarget and not pondTarget:hasRole("1267239172444262490") then
		pondTarget:addRole("1267239172444262490", "received gifted Ducky Plus+ slot")
	end
	if userPlus.slots <= 0 and table.count(userPlus.guilds) <= 0 and pondUser and pondUser:hasRole("1267239172444262490") then
		pondUser:removeRole("1267239172444262490", "gifted Ducky Plus+ slot")
	end

	local success, err = sqldb:plusSet(targetUser, targetPlus)
	if not success then
		saveLog("error", "plusGift", {error = "Failed to apply gifted slot to target user", result = tostring(err), gifting_user_id = user, target_user_id = targetUser, error_message = tostring(err)})
		return false, "Failed to apply slot to target: " .. tostring(err)
	end

	local success, err = sqldb:plusSet(user, userPlus)
	if not success then
		saveLog("error", "plusGift", {error = "Failed to remove slot from gifting user", result = tostring(err), gifting_user_id = user, target_user_id = targetUser, error_message = tostring(err)})

		local rollbackSuccess, rollbackErr = sqldb:plusSet(targetUser, {
			userid = targetUser,
			slots = math.max(0, targetPlus.slots - 1),
			guilds = targetPlus.guilds,
		})

		if rollbackSuccess then
			saveLog("info", "plusGift", {status = "Rolled back slot addition to target user", target_user_id = targetUser, rollback_slots = math.max(0, targetPlus.slots - 1)})
		else
			saveLog("error", "plusGift", {error = "Failed to roll back slot addition to target user", target_user_id = targetUser, rollback_error = tostring(rollbackErr)})
		end

		return false, "Failed to remove slot from user: " .. tostring(err)
	end

	saveLog("info", "plusGift", {status = "User gifted a Ducky Plus+ slot to target user successfully", gifting_user_id = user, target_user_id = targetUser, remaining_slots_gifter = userPlus.slots, new_slots_target = targetPlus.slots})
	return true, userPlus
end

function sqldb:plusDelete(user)
	user = (type(user) == "table" and user.id) or user

	local success, _ = self:_queryRun({
		query = "DELETE FROM plus WHERE userid = ?",
		values = { user }
	})

	if success then
		saveLog("info", "plusDelete", {status = "Deleted plus data for user", user_id = user})
		sqldb.cache.plus[user] = nil
		return true
	else
		saveLog("error", "plusDelete", {error = "Failed to delete plus data for user", user_id = user})
		return false, "Failed to delete plus data."
	end
end

function sqldb:plusImportTransactions(sampleTransactions)
	local success, allPlus = sqldb:plusAll()

	if not success or type(allPlus) ~= "table" then
		saveLog("error", "plusImportTransactions", {error = "Failed to get all plus data for transaction import"})
		return false, "Failed to get all plus"
	end

	local existingTransactions = {}

	for _, plus in pairs(allPlus) do
		if type(plus) == "table" and type(plus.transactions) == "table" and next(plus.transactions) then
			for _, transaction in pairs(plus.transactions) do
				if type(transaction) == "table" and transaction.token then
					existingTransactions[transaction.token] = true
				end
			end
		end
	end

	local groupTransactions = sampleTransactions or ropi.GetGroupTransactions(34493757, true)

	if type(groupTransactions) ~= "table" or not next(groupTransactions) then
		saveLog("warning", "plusImportTransactions", {error = "Failed to get group transactions or no transactions to import"})
		return false, "Failed to get group transactions or no group transactions"
	end

	local count = 0

	local ok, err = pcall(function()
		local newUserTransactions = {}

		for _, transaction in pairs(groupTransactions) do
			if type(transaction) == "table" and transaction.token and transaction.user and transaction.user.id and transaction.item and transaction.item.id and (transaction.item.id == tonumber("114637999112749") or transaction.item.id == tonumber("134199688741263")) and not existingTransactions[transaction.token] then
				local link = sqldb:getLink(transaction.user.id)

				if type(link) == "table" and link.discord then
					newUserTransactions[link.discord] = newUserTransactions[link.discord] or {}
					table.insert(newUserTransactions[link.discord], {
						token = transaction.token,
						timestamp = transaction.created,
						paid = transaction.price,
						slots = math.floor(math.max(1, transaction.price / 1000)),
						roblox = transaction.user.id
					})
				else
					saveLog("debug", "plusImportTransactions", {status = "Skipping transaction import: No Discord link found for Roblox user", roblox_user_id = transaction.user.id, transaction_token = transaction.token})
				end
			else
				saveLog("debug", "plusImportTransactions", {status = "Skipping transaction import: Invalid or duplicate transaction data", transaction_data = tostring(transaction.token), is_duplicate = not not existingTransactions[transaction.token]})
			end
		end

		for id, transactions in pairs(newUserTransactions) do
			local isPlus, plus = sqldb:plusMember(id)

			if type(plus) == "table" and type(plus.transactions) == "table" then
				local mergedTransactions = table.merge(plus.transactions, transactions)
				local encodedTransactions = encodeTable(mergedTransactions)

				if encodedTransactions then
					local qOk, qErr = sqldb:_queryRun({
						query = [[
							INSERT INTO plus (userid, transactions)
							VALUES (?, ?)
							ON CONFLICT (userid) DO UPDATE SET transactions = EXCLUDED.transactions
						]],
						values = {id, encodedTransactions}
					})

					if qOk then
						count = count + 1
						saveLog("debug", "plusImportTransactions", {status = "Successfully imported transactions for user", user_id = id, num_transactions_imported = #transactions})
					else
						saveLog("error", "plusImportTransactions", {error = "Failed to update plus data with imported transactions for user", user_id = id, error_message = tostring(qErr)})
					end
				else
					saveLog("error", "plusImportTransactions", {error = "Failed to encode merged transactions for user", user_id = id})
				end
			else
				saveLog("error", "plusImportTransactions", {error = "Invalid plus data for user during transaction import merge", user_id = id, plus_data_type = type(plus)})
			end
		end
	end)

	if not ok then
		saveLog("critical", "plusImportTransactions", {error = "plusImportTransactions pcall failed", pcall_error = tostring(err)})
		return false, "Transaction failed: " .. tostring(err)
	elseif count == 0 then
		saveLog("info", "plusImportTransactions", {status = "plusImportTransactions completed with no changes"})
		return true, "Nothing changed"
	else
		saveLog("info", "plusImportTransactions", {status = "plusImportTransactions completed successfully", transactions_imported = count})
		return true, "Imported " .. tostring(count) .. " transactions"
	end
end

function sqldb:link(member, roblox)
	if not _G.ropi then
		saveLog("error", "link", {error = "ROPI dependency not found for link operation", member_id = member and member.id, roblox_input = tostring(roblox)})
		return false, "The ROPI dependency could not be found."
	end

	if not member or not member.id then
		saveLog("error", "link", {error = "Discord member object invalid for link operation", member_input = tostring(member)})
		return false, "The discord member object is invalid."
	end

	if not roblox then
		saveLog("error", "link", {error = "Roblox object invalid for link operation", discord_id = member.id, roblox_input = tostring(roblox)})
		return false, "The roblox object is invalid."
	end

	local robloxUser = (tonumber(roblox) and _G.ropi.GetUser(tonumber(roblox)))
		or (_G.ropi.SearchUser(tostring(roblox)))
		or (type(roblox) == "table" and roblox.name and roblox.id and roblox)
	if not robloxUser then
		saveLog("error", "link", {error = "Roblox user not found for link operation", discord_id = member.id, roblox_input = tostring(roblox)})
		return false, "That Roblox user does not exist."
	end

	local existingDiscordLink = sqldb:getLink(member.id)
	if existingDiscordLink then
		local roblox = ropi.GetUser(existingDiscordLink.roblox)
		saveLog("warning", "link", {status = "Discord account already linked", discord_id = member.id, roblox_id = roblox.id})
		return false, "Your Discord account, @" .. member.username .. " (" .. member.id .. "), is already linked with Roblox account @" .. roblox.name .. " (" .. roblox.id .. ")."
	end

	local existingRobloxLink = sqldb:getLink(robloxUser.id)
	if existingRobloxLink then
		local discord = Client:getUser(existingRobloxLink.discord)
		saveLog("warning", "link", {status = "Roblox account already linked", discord_id = discord.id, roblox_id = robloxUser.id})
		return false, "Your Roblox account, @" .. robloxUser.name .. " (" .. robloxUser.id .. "), is already linked with Discord account @" .. discord.username .. " (" .. discord.id .. ")."
	end

	local success, result = sqldb:_queryRun({
		query = [[
			INSERT INTO links (discord, roblox) VALUES (?, ?)
			ON CONFLICT (discord) DO UPDATE SET roblox = EXCLUDED.roblox
		]],
		values = {member.id, robloxUser.id},
	})

	if success then
		local link = { discord = member.id, roblox = robloxUser.id }
		sqldb.cache.linksByDiscord[member.id] = link
		sqldb.cache.linksByRoblox[tostring(robloxUser.id)] = link
		DuckyAPI:emit("userLinked", member, robloxUser)

		saveLog("info", "link", {status = "Successfully linked Discord user with Roblox user", discord_id = member.id, roblox_id = robloxUser.id})
		return true, link
	else
		saveLog("error", "link", {error = "Failed to link Discord user with Roblox user", discord_id = member.id, roblox_id = robloxUser.id, query_result = result})
		return false, "Failed to link member and roblox user"
	end
end

function sqldb:getLink(id, notCached)
	if not notCached then
		local link = sqldb.cache.linksByDiscord[tostring(id)] or sqldb.cache.linksByRoblox[tostring(id)]
		if link then
			return link
		end
	end

	local isDiscordID = isDiscordSnowflake(id)
	id = (not isDiscordID and tonumber(id)) or id
	local query

	if isDiscordID then
		query = "SELECT discord, roblox FROM links WHERE discord = ?"
	else
		query = "SELECT discord, roblox FROM links WHERE roblox = ?"
	end

	local success, rows = sqldb:_queryRun({
		query = query,
		values = {id},
	})

	if not success or type(rows) ~= "table" then
		saveLog("error", "getLink", {error = "Failed to fetch link from database", id = id})
		return nil
	end

	return (type(rows) == "table" and rows[1]) or nil
end

function sqldb:unLink(id)
	if type(id) ~= "string" and type(id) ~= "number" then
		saveLog("error", "unLink", {error = "Invalid ID type provided", id = id, id_type = type(id)})
		return false, "Invalid id type"
	end

	local isDiscordID = isDiscordSnowflake(id)
	id = (not isDiscordID and tonumber(id)) or id
	local query

	if isDiscordID then
		query = "DELETE FROM links WHERE discord = ?"
	else
		query = "DELETE FROM links WHERE roblox = ?"
	end

	local success, result = sqldb:_queryRun({
		query = query,
		values = {id},
	})

	if success then
		saveLog("info", "unLink", {status = "Successfully unlinked user with ID", user_id = id})
		local link = sqldb.cache.linksByDiscord[tostring(id)] or sqldb.cache.linksByRoblox[tostring(id)]
		if link then
			sqldb.cache.linksByDiscord[link.discord] = nil
			sqldb.cache.linksByRoblox[tostring(link.roblox)] = nil

			local DiscordUser = Client:getUser(link.discord)
			if DiscordUser then
				DuckyAPI:emit("userUnlinked", DiscordUser)
			end
		end
	else
		saveLog("error", "unLink", {error = "Failed to unlink user with ID", user_id = id, query_result = result})
	end

	return success
end

function sqldb:getAllLinks(notCached)
	if not notCached then
		local links = {}
		for _, link in pairs(sqldb.cache.linksByDiscord) do
			table.insert(links, link)
		end
		saveLog("debug", "getAllLinks", {status = "Returning all links from cache", num_links = #links})
		return links
	end

	local success, rows = sqldb:_queryRun({
		query = "SELECT * FROM links",
	})

	if not success or type(rows) ~= "table" then
		saveLog("error", "getAllLinks", {error = "Failed to fetch all links from database"})
		return {}
	end

	sqldb.cache.linksByDiscord = {}
	sqldb.cache.linksByRoblox = {}
	for _, link in pairs(rows) do
		sqldb.cache.linksByDiscord[link.discord] = link
		sqldb.cache.linksByRoblox[tostring(link.roblox)] = link
	end

	saveLog("info", "getAllLinks", {status = "Fetching all links from database", num_links = #rows})
	return rows
end

function sqldb:saveError(id, info)
	if not id then
		saveLog("error", "saveError", {error = "Error ID not provided"})
		return false, "Id was not provided"
	end

	if not info then
		saveLog("error", "saveError", {error = "Error info not provided or invalid", error_id = id})
		return false, "Info was not provided or is invalid"
	end

	local json_info = encodeTable(info)

	local success, _ = self:_queryRun({
		query = [[
			INSERT INTO errors (id, info) VALUES (?, ?)
			ON CONFLICT (id) DO UPDATE SET info = EXCLUDED.info
		]],
		values = {id, json_info}
	})

	if success then
		saveLog("info", "saveError", {status = "Error saved successfully", error_id = id})
	else
		saveLog("error", "saveError", {error = "Failed to save error", error_id = id})
	end

	return success
end

function sqldb:getError(id)
	saveLog("info", "getError", {status = "Fetching error with ID", error_id = id})

	local success, rows = self:_queryRun({
		query = "SELECT info FROM errors WHERE id = ?",
		values = {tostring(id)}
	})

	if not success then
		saveLog("error", "getError", {error = "Failed to fetch error from database", error_id = id})
		return nil
	end

	if rows and rows[1] and rows[1].info then
		return json.decode(rows[1].info)
	end
	return nil
end

function sqldb:getAllErrors()
	saveLog("info", "getAllErrors", {status = "Fetching all errors from database"})

	local success, rows = self:_queryRun({
		query = "SELECT id, info FROM errors"
	})

	if not success then
		saveLog("error", "getAllErrors", {error = "Failed to fetch all errors from database"})
		return {}
	end

	local errors = {}
	for _, row in ipairs(rows) do
		errors[row.id] = json.decode(row.info)
	end
	return errors
end

function sqldb:deleteError(id)
	local success, _ = self:_queryRun({
		query = "DELETE FROM errors WHERE id = ?",
		values = {tostring(id)}
	})

	if success then
		saveLog("info", "deleteError", {status = "Error deleted successfully", error_id = id})
	else
		saveLog("error", "deleteError", {error = "Failed to delete error", error_id = id})
	end

	return success
end

function sqldb:resolveAllErrors()
	local errors = self:getAllErrors()

	if not errors then
		saveLog("error", "resolveAllErrors", {error = "Failed to retrieve all errors for resolution"})
		return false, "Failed to get all errors"
	end

	saveLog("info", "resolveAllErrors", {status = "Attempting to resolve errors", count = table.count(errors)})

	for id, errTable in pairs(errors) do
		if not errTable.resolved then
			errTable.resolved = true
			local success, err_msg = self:saveError(id, errTable)
			if success then
				saveLog("info", "resolveAllErrors", {status = "Error resolved successfully", error_id = id})
			else
				saveLog("error", "resolveAllErrors", {error = "Failed to save resolved error", error_id = id, error_message = err_msg})
			end
		end
	end

	saveLog("info", "resolveAllErrors", {status = "Resolution process for all errors completed"})
	return true
end

function sqldb:getBlacklist(id, unCached)
	if not id or not tonumber(id) then
		saveLog("warning", "getBlacklist", {error = "Invalid ID provided", id = id})
		return false, "Invalid ID."
	end

	if not unCached then
		return not not sqldb.cache.blacklists[id], sqldb.cache.blacklists[id]
	end

	local success, rows = self:_queryRun({
		query = "SELECT id, reason FROM blacklists WHERE id = ?",
		values = {id}
	})

	if not success then
		saveLog("error", "getBlacklist", {error = "Failed to query blacklist from database", user_id = id})
		return false, "Query failed"
	end

	if rows and rows[1] then
		local bl = rows[1]
		sqldb.cache.blacklists[bl.id] = bl
		return true, bl
	end
	return false
end

function sqldb:addBlacklist(id, reason)
	if not id or not tonumber(id) then
		saveLog("error", "addBlacklist", {error = "Invalid ID provided"})
		return false, "Id not provided or invalid"
	end

	if not reason or reason == "" then
		saveLog("error", "addBlacklist", {error = "Reason not provided or invalid", user_id = id})
		return false, "Reason not provided or invalid"
	end

	local success, _ = self:_queryRun({
		query = [[
			INSERT INTO blacklists (id, reason) VALUES (?, ?)
			ON CONFLICT (id) DO UPDATE SET reason = EXCLUDED.reason
		]],
		values = {id, reason}
	})

	if success then
		sqldb.cache.blacklists = sqldb.cache.blacklists or {}
		sqldb.cache.blacklists[id] = { id = id, reason = reason }
		saveLog("info", "addBlacklist", {status = "User added to blacklist successfully", user_id = id, reason = reason})
		return true, "ID added to blacklist with reason: " .. reason
	else
		saveLog("error", "addBlacklist", {error = "Failed to add user to blacklist", user_id = id, reason = reason})
		return false, "Failed to add ID to blacklist"
	end
end

function sqldb:removeBlacklist(id)
	if not id then
		saveLog("error", "removeBlacklist", {error = "ID not provided"})
		return false, "ID not provided"
	end

	local success, _ = self:_queryRun({
		query = "DELETE FROM blacklists WHERE id = ?",
		values = {id}
	})

	if success then
		sqldb.cache.blacklists[id] = nil
		saveLog("info", "removeBlacklist", {status = "User removed from blacklist successfully", user_id = id})
		return true, "ID removed from blacklist"
	else
		saveLog("error", "removeBlacklist", {error = "Failed to remove user from blacklist", user_id = id})
		return false, "Failed to remove ID from blacklist"
	end
end

function sqldb:addExportable(id, owner, createdAt, lastImported, TYPE, data, name)
	if not id then
		saveLog("error", "addExportable", {error = "Exportable ID not provided"})
		return false, "Id was not provided"
	end
	if not owner then
		saveLog("error", "addExportable", {error = "Owner ID not provided", exportable_id = id})
		return false, "Owner was not provided"
	end
	if not createdAt then
		saveLog("error", "addExportable", {error = "Creation timestamp not provided", exportable_id = id})
		return false, "CreatedAt was not provided"
	end
	if not lastImported then
		saveLog("error", "addExportable", {error = "Last imported timestamp not provided", exportable_id = id})
		return false, "LastImported was not provided"
	end
	if not TYPE then
		saveLog("error", "addExportable", {error = "Type not provided", exportable_id = id})
		return false, "Type was not provided"
	end
	if not data then
		saveLog("error", "addExportable", {error = "Data not provided or invalid", exportable_id = id})
		return false, "Data was not provided or invalid"
	end
	if not name then
		saveLog("error", "addExportable", {error = "Name not provided or invalid", exportable_id = id})
		return false, "Name was not provided or invalid"
	end

	local success, _ = self:_queryRun({
		query = [[
			INSERT INTO exportables (id, owner, "createdAt", "lastImported", "type", data, name)
			VALUES (?, ?, ?, ?, ?, ?, ?)
			ON CONFLICT (id) DO UPDATE SET
				owner          = EXCLUDED.owner,
				"createdAt"    = EXCLUDED."createdAt",
				"lastImported" = EXCLUDED."lastImported",
				"type"         = EXCLUDED."type",
				data           = EXCLUDED.data,
				name           = EXCLUDED.name
		]],
		values = {id, owner, createdAt, lastImported, TYPE, data, name}
	})

	if success then
		saveLog("info", "addExportable", {status = "Exportable added successfully", exportable_id = id, owner_id = owner, type = TYPE, name = name})
		return true, "Exportable added successfully."
	else
		saveLog("error", "addExportable", {error = "Failed to add exportable", exportable_id = id, owner_id = owner, type = TYPE, name = name})
		return false, "Failed to add exportable."
	end
end

function sqldb:setExportable(id, info)
	if not id then
		saveLog("error", "setExportable", {error = "Exportable ID not provided"})
		return false, "Id was not provided"
	end
	if not info then
		saveLog("error", "setExportable", {error = "Exportable info not provided", exportable_id = id})
		return false, "Info was not provided"
	end

	if info and type(info.data) == "table" then
		info.data = encodeTable(info.data)
	end

	local success, _ = self:_queryRun({
		query = [[
			INSERT INTO exportables (id, owner, "createdAt", "lastImported", "type", data, name)
			VALUES (?, ?, ?, ?, ?, ?, ?)
			ON CONFLICT (id) DO UPDATE SET
				owner          = EXCLUDED.owner,
				"createdAt"    = EXCLUDED."createdAt",
				"lastImported" = EXCLUDED."lastImported",
				"type"         = EXCLUDED."type",
				data           = EXCLUDED.data,
				name           = EXCLUDED.name
		]],
		values = {id, info.owner, info.createdAt, info.lastImported, info.type, info.data, info.name}
	})

	if success then
		saveLog("info", "setExportable", {status = "Exportable updated successfully", exportable_id = id, owner_id = info.owner, type = info.type, name = info.name})
		return true, "Exportable updated successfully."
	else
		saveLog("error", "setExportable", {error = "Failed to update exportable", exportable_id = id, owner_id = info.owner, type = info.type, name = info.name})
		return false, "Failed to update exportable."
	end
end

function sqldb:deleteExportable(id)
	if not id then
		saveLog("error", "deleteExportable", {error = "Exportable ID not provided"})
		return false, "Id was not provided"
	end

	local success, result = self:_queryRun({
		query = "DELETE FROM exportables WHERE id = ?",
		values = {id}
	})

	if success then
		saveLog("info", "deleteExportable", {status = "Exportable deleted successfully", exportable_id = id})
		return true, "Exportable deleted successfully."
	else
		saveLog("error", "deleteExportable", {error = "Failed to delete exportable", exportable_id = id, query_result = tostring(result)})
		return false, "Error deleting exportable: " .. tostring(result)
	end
end

function sqldb:getExportable(id)
	if not id then
		saveLog("error", "getExportable", {error = "Exportable ID not provided"})
		return nil
	end

	local success, rows = self:_queryRun({
		query = [[SELECT id, owner, "createdAt", "lastImported", "type", data, name FROM exportables WHERE id = ?]],
		values = {id}
	})

	if not success then
		saveLog("error", "getExportable", {error = "Failed to fetch exportable from database", exportable_id = id})
		return nil
	end

	return rows and rows[1] or nil
end

function sqldb:getAllExportables()
	local success, rows = self:_queryRun({
		query = [[SELECT id, owner, "createdAt", "lastImported", "type", data, name FROM exportables]]
	})

	if not success then
		saveLog("error", "getAllExportables", {error = "Failed to fetch all exportables from database"})
		return {}
	end

	saveLog("info", "getAllExportables", {status = "Fetched all exportables from database", num_exportables = #rows})
	return rows
end

function sqldb:setUserSettings(user_id, config)
	if not user_id or type(user_id) ~= "string" then
		saveLog("error", "setUserSettings", {error = "Invalid user_id or not provided"})
		return false, "user_id is invalid or not provided"
	end

	if not config or type(config) ~= "table" then
		saveLog("error", "setUserSettings", {error = "Config invalid or not provided", user_id = user_id})
		return false, "config is invalid or not provided"
	end

	local json_value = encodeTable(config)

	if not json_value then
		p("setUserSettings nil json_value")
		return false, "nil json_value"
	end

	local success, _ = self:_queryRun({
		query = [[
			INSERT INTO user_settings (id, config) VALUES (?, ?)
			ON CONFLICT (id) DO UPDATE SET config = EXCLUDED.config
		]],
		values = {user_id, json_value}
	})

	if success then
		self.cache.user_settings[user_id] = config
		saveLog("info", "setUserSettings", {status = "User settings saved successfully", user_id = user_id})
		return true, config
	else
		saveLog("error", "setUserSettings", {error = "Failed to save user settings", user_id = user_id})
		return false, "Failed to prepare or execute statement"
	end
end

function sqldb:getUserSettings(user_id, notCached)
	if not user_id or type(user_id) ~= "string" then
		saveLog("error", "getUserSettings", {error = "Invalid user_id or not provided"})
		return false, "user_id invalid or not provided"
	end

	if not notCached and self.cache.user_settings then
		return self.cache.user_settings[user_id]
	end

	local success, rows = self:_queryRun({
		query = "SELECT config FROM user_settings WHERE id = ?",
		values = {user_id}
	})

	if not success then
		saveLog("error", "getUserSettings", {error = "Failed to fetch user settings from database", user_id = user_id})
		return nil
	end

	if rows and rows[1] and rows[1].config then
		local decoded = decodeTable(rows[1].config)
		self.cache.user_settings[user_id] = decoded
		return decoded
	end
	return nil
end

function sqldb:deleteUserSettings(user_id)
	if not user_id or type(user_id) ~= "string" then
		saveLog("error", "deleteUserSettings", {error = "Invalid user_id or not provided"})
		return false, "user_id invalid or not provided"
	end

	local success, err = self:_queryRun({
		query = "DELETE FROM user_settings WHERE id = ?",
		values = {user_id}
	})

	if success then
		self.cache.user_settings[user_id] = nil
		saveLog("info", "deleteUserSettings", {status = "User settings deleted successfully", user_id = user_id})
		return true, "User settings deleted successfully."
	else
		saveLog("error", "deleteUserSettings", {error = "Failed to delete user settings", user_id = user_id, error_message = tostring(err)})
		return false, "Failed to delete user settings: " .. tostring(err)
	end
end

function sqldb:isAffiliate(id, notCached)
	if not id or not tonumber(id) then
		return false, "Invalid ID."
	end

	if not notCached then
		return not not sqldb.cache.affiliates[id]
	end

	local success, rows = self:_queryRun({
		query = "SELECT id FROM affiliates WHERE id = ?",
		values = {id}
	})

	if not success then
		return false
	end

	local is_affiliate = rows and rows[1] and true or false
	if is_affiliate then
		self.cache.affiliates[id] = true
	end
	return is_affiliate
end

function sqldb:addAffiliate(id)
	if not id or not tonumber(id) then
		saveLog("error", "addAffiliate", {error = "Id was not provided or invalid"})
		return false, "Id not provided or invalid"
	end

	local success, _ = self:_queryRun({
		query = [[
			INSERT INTO affiliates (id) VALUES (?)
			ON CONFLICT (id) DO NOTHING
		]],
		values = {id}
	})

	if success then
		self.cache.affiliates[id] = true
		saveLog("info", "addAffiliate", {status = "Added ID to affiliates", id = id})
		return true
	else
		saveLog("error", "addAffiliate", {error = "Failed to add ID to affiliates", id = id})
		return false, "Failed to prepare statement"
	end
end

function sqldb:removeAffiliate(id)
	if not id or not tonumber(id) then
		saveLog("error", "removeAffiliate", {error = "Id was not provided or invalid"})
		return false, "Id not provided or invalid"
	end

	local success, err = self:_queryRun({
		query = "DELETE FROM affiliates WHERE id = ?",
		values = {id}
	})

	if success then
		self.cache.affiliates[id] = nil
		saveLog("info", "removeAffiliate", {status = "Removed ID from affiliates", id = id})
		return true
	else
		saveLog("error", "removeAffiliate", {error = "Failed to remove ID from affiliates", id = id, error_message = tostring(err)})
		return false, "Failed to remove ID from affiliates: " .. tostring(err)
	end
end

function sqldb:allAffiliates()
	local success, rows = sqldb:_queryRun({
		query = "SELECT id FROM affiliates"
	})

	if not success then
		saveLog("error", "allAffiliates", {error = "initAffiliates failed to get all affiliates"})
		return
	end

	for _, affiliate in pairs(rows) do
		sqldb.cache.affiliates[affiliate.id] = true
	end

	return rows
end

function sqldb:getUtils(key)
	if not key or type(key) ~= "string" then
		saveLog("error", "getUtils", {error = "getUtils key invalid or not provided"})
		return false, "Key invalid or not provided"
	end

	saveLog("info", "getUtils", {key = key})

	local success, rows = self:_queryRun({
		query = "SELECT value FROM utils WHERE key = ?",
		values = {key}
	})

	if success and rows and rows[1] then
		return rows[1].value
	end
	return nil
end

function sqldb:setUtils(key, value)
	if not key or type(key) ~= "string" then
		saveLog("error", "setUtils", {error = "Key invalid or not provided"})
		return false, "Key invalid or not provided"
	end

	if value == nil then
		saveLog("error", "setUtils", {error = "Value not provided"})
		return false, "Value not provided"
	end

	saveLog("info", "setUtils", {key = key})

	local success, _ = self:_queryRun({
		query = [[
			INSERT INTO utils (key, value) VALUES (?, ?)
			ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value
		]],
		values = {key, value}
	})

	if not success then
		saveLog("error", "setUtils", {error = "setUtils failed", key = key})
		return false, "Failed to execute statement"
	end

	return true
end

function sqldb:deleteUtils(key)
	if not key or type(key) ~= "string" then
		saveLog("error", "deleteUtils", {error = "Key invalid or not provided"})
		return false, "Key invalid or not provided"
	end

	saveLog("info", "deleteUtils", {key = key})

	local success, _ = self:_queryRun({
		query = "DELETE FROM utils WHERE key = ?",
		values = {key}
	})

	if not success then
		saveLog("error", "deleteUtils", {error = "deleteUtils failed", key = key})
		return false, "Failed to execute statement"
	end

	return true
end

function sqldb:getRefreshToken(id)
	if type(id) ~= "string" then
		saveLog("error", "getRefreshToken", {error = "Invalid id provided"})
		return false, "Invalid id provided"
	end

	local success, rows = self:_queryRun({
		query = [[SELECT "refreshToken" FROM "refreshTokens" WHERE id = ?]],
		values = {id}
	})

	if not success then
		saveLog("error", "getRefreshToken", {error = "Query failed"})
		return false, "Query failed"
	end

	if rows and rows[1] and rows[1].refreshToken then
		return true, rows[1].refreshToken
	else
		return false, "No refresh token found"
	end
end

function sqldb:setRefreshToken(id, refreshToken)
	if type(id) ~= "string" then
		saveLog("error", "setRefreshToken", {error = "Invalid id provided"})
		return false, "Invalid id provided"
	end

	if type(refreshToken) ~= "string" then
		saveLog("error", "setRefreshToken", {error = "Invalid refreshToken provided"})
		return false, "Invalid refreshToken provided"
	end

	local success, _ = self:_queryRun({
		query = [[
			INSERT INTO "refreshTokens" (id, "refreshToken") VALUES (?, ?)
			ON CONFLICT (id) DO UPDATE SET "refreshToken" = EXCLUDED."refreshToken"
		]],
		values = {id, refreshToken}
	})

	if not success then
		saveLog("error", "setRefreshToken", {error = "Query failed"})
	end

	return success
end

function sqldb:deleteRefreshToken(id)
	if type(id) ~= "string" then
		saveLog("error", "deleteRefreshToken", {error = "Invalid id provided"})
		return false, "Invalid id provided"
	end

	local success, _ = self:_queryRun({
		query = [[DELETE FROM "refreshTokens" WHERE id = ?]],
		values = {id}
	})

	if not success then
		saveLog("error", "deleteRefreshToken", {error = "Query failed"})
	end

	return success
end

function sqldb:authUserToToken(user)
	if type(user) ~= "string" then
		return false, "Invalid user ID provided."
	end

	local success, rows = self:_queryRun({
		query = [[SELECT "user", token, "discordToken", "refreshToken" FROM auth_sessions WHERE "user" = ?]],
		values = {user}
	})

	if not success then
		return false, "Query failed: " .. tostring(rows)
	end

	if type(rows) ~= "table" or not rows[1] then
		return false, "Failed to transform raw"
	end

	return success, rows[1]
end

function sqldb:authTokenToUser(token)
	if type(token) ~= "string" then
		return false, "Invalid token provided."
	end

	local success, rows = self:_queryRun({
		query = [[SELECT "user", token, "discordToken", "refreshToken" FROM auth_sessions WHERE token = ?]],
		values = {token}
	})

	if not success then
		return false, "Query failed: " .. tostring(rows)
	end

	if type(rows) ~= "table" or not rows[1] then
		return false, "Failed to transform raw"
	end

	return success, rows[1]
end

function sqldb:authSet(user, token, discordToken, refreshToken)
	if type(user) ~= "string" then
		return false, "Invalid user ID provided."
	end

	if type(token) ~= "string" then
		return false, "Invalid token provided."
	end

	if type(discordToken) ~= "string" then
		return false, "Invalid discordToken provided."
	end

	if type(refreshToken) ~= "string" then
		return false, "Invalid refreshToken provided."
	end

	local success, err = self:_queryRun({
		query = [[
			INSERT INTO auth_sessions ("user", token, "discordToken", "refreshToken")
			VALUES (?, ?, ?, ?)
			ON CONFLICT ("user") DO UPDATE SET
				token          = EXCLUDED.token,
				"discordToken" = EXCLUDED."discordToken",
				"refreshToken" = EXCLUDED."refreshToken"
		]],
		values = {user, token, discordToken, refreshToken}
	})

	if success then
		return success, {user = user, token = token, discordToken = discordToken, refreshToken = refreshToken}
	end

	return success, err
end

function sqldb:authDelete(token)
	if type(token) ~= "string" then
		return false, "Invalid token provided."
	end

	local success, err = self:_queryRun({
		query = "DELETE FROM auth_sessions WHERE token = ?",
		values = {token}
	})

	return success, err
end

local function guildDataSearch(query)
	local function searchTable(tbl, target, path, results)
		path = path or ""
		results = results or {}

		for key, value in pairs(tbl) do
			local currentPath = path .. "[" .. tostring(key) .. "]"

			if type(key) == "string" and string.match(key, target) then
				table.insert(results, { location = currentPath, value = value })
			end

			if type(value) == "table" then
				searchTable(value, target, currentPath, results)
			elseif type(value) == "string" and string.match(value, target) then
				table.insert(results, { location = currentPath, value = value })
			end
		end

		return results
	end

	local fullResults = {}

	for guildId, config in pairs(sqldb:getAllGuildConfigs() or {}) do
		local results = searchTable(config, query)
		if #results > 0 then
			fullResults[guildId] = results
		end
	end

	return fullResults
end

function sqldb:getAllUserData(userId)
	local userData = {}
	local output = {}

	local plusSucc, plusInfo = sqldb:plusMember(userId)
	if plusSucc and plusInfo then
		userData.duckyplus = plusInfo
		table.insert(output, "## **Ducky Plus**")
		table.insert(output, "- Slots: " .. tostring(plusInfo.slots))
		table.insert(output, "- Guilds: " .. table.concat(plusInfo.guilds or {}, ", "))
	end

	local robloxLink = sqldb:getLink(userId)
	if robloxLink then
		userData.link = robloxLink
		table.insert(output, "## **Roblox Link**")
		table.insert(output, "- Roblox ID: " .. robloxLink.roblox)
	end

	local blacklistInfo = sqldb:getBlacklist(userId)
	if blacklistInfo then
		userData.blacklist = blacklistInfo
		table.insert(output, "## **Blacklist**")
		table.insert(output, "- Reason: " .. tostring(blacklistInfo.reason))
	end

	local allExportables = sqldb:getAllExportables()
	for _, exportable in pairs(allExportables or {}) do
		if exportable.owner == userId then
			userData.exportables = userData.exportables or {}
			table.insert(userData.exportables, exportable)

			table.insert(output, "## **Exportable**")
			table.insert(output, "- Type: " .. exportable.type)
			table.insert(output, "- ID: " .. exportable.id)
			table.insert(output, "- Created At: " .. os.date("%Y-%m-%d %H:%M:%S", exportable.createdAt))
		end
	end

	local userSettingsInfo = sqldb:getUserSettings(userId)
	if type(userSettingsInfo) == "table" and table.count(userSettingsInfo) > 0 then
		userData.userSettings = userSettingsInfo
		table.insert(output, "## **User Settings**")

		for key, value in pairs(userSettingsInfo) do
			table.insert(output, "- " .. tostring(key) .. ": " .. tostring(value))
		end
	end

	local serverData = {}
	local totalMatches = 0

	local resultsByGuild = guildDataSearch(userId)
	if type(resultsByGuild) == "table" then
		for guildId, results in pairs(resultsByGuild) do
			serverData[guildId] = #results
			totalMatches = totalMatches + #results
		end
	end

	if totalMatches > 0 then
		table.insert(output, "## **Server Data Search**")
		for guildId, count in pairs(serverData) do
			table.insert(output, "- Guild ID `" .. guildId .. "`: " .. count .. " result(s)")
		end
	end

	userData.serverdata = resultsByGuild

	local readable = (#output > 0 and table.concat(output, "\n")) or "No data found for this user."
	return userData, readable
end

function sqldb:exec(query)
	if not query or type(query) ~= "string" then
		return false, "Query is invalid or not provided"
	end

	local result, err = conn.query(query)
	if not result then
		return nil, err
	end
	return result
end

function sqldb:close()
	conn.close()
end

return sqldb
