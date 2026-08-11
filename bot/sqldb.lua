local db_filename = "data.db"
local backup_folder = "sqlbackups"

local function timestamp() -- db gets used before utils are loaded
	return discordia.Date:fromSeconds(os.time()):toString("%x @ %I:%M:%S%p")
end

local function realtime()
	local seconds, microseconds = _G.uv.gettimeofday()

	return seconds + (microseconds / 1000000)
end

local function log(str, mode, context_table)
	if not mode or mode:upper() == "INFO" then return end
	prettyLog("SQLDB", "green", (mode and mode:upper() or "INFO") .. " | " .. str .. (type(context_table) == "table" and  " | " .. table.concat(context_table, ", ") or ""))
end

if not _G.onFlightSQLDBStart then
	-- Create Data Backup --
	os.execute("mkdir -p " .. backup_folder)

	local function getLastBackupTime(folder)
		local latest = 0
		for _, file in ipairs(fs.readdirSync(folder)) do
			if file:match("%.db$") then
				local path = folder .. "/" .. file
				local stat = fs.statSync(path)
				local mtime = stat and stat.mtime
				if type(mtime) == "table" and mtime.sec then
					mtime = mtime.sec
				end
				if type(mtime) == "number" and mtime > latest then
					latest = mtime
				end
			end
		end
		return latest
	end

	local lastBackup = getLastBackupTime(backup_folder)
	local now = os.time()

	if now - lastBackup > 1800 then
		local destination = string.format("%s/%s.db", backup_folder, os.date("%Y_%m_%d_%H_%M_%S"))
		local ok = os.execute(string.format("cp '%s' '%s'", db_filename, destination))
		if ok then
			log("Created sqldb backup successfully.")
		else
			log("Failed to create sqldb backup.", "error")
		end
	else
		log("Skipped sqldb backup (last backup was less than 30 minutes ago).", "warning")
	end
end

-- Delete Data Backups Older Than 5 Days --
os.execute(string.format("find '%s' -type f -mtime +5 -name '*.db' -delete", backup_folder))

-- Start Database --
local conn = sqlite3.open(db_filename)
log("Database connection established", "info", {database_file = db_filename})

-- WAL Mode --
-- This makes it so if 2 writes happen at the same time, it doesn't fail because it's "locked"
conn:exec("PRAGMA journal_mode=WAL;")
conn:exec("PRAGMA journal_size_limit = 10485760;")
conn:exec("PRAGMA wal_autocheckpoint = 1000;")
log("WAL mode configured for database", "info", {journal_mode = "WAL", journal_size_limit_bytes = "10485760", wal_autocheckpoint_pages = "1000"})

--- Data Tables ---
conn:exec([[ 
  CREATE TABLE IF NOT EXISTS guilds (
    guild_id TEXT NOT NULL,
    setting_key TEXT NOT NULL,
    setting_value TEXT,
	setting_type TEXT DEFAULT 'string',
    PRIMARY KEY (guild_id, setting_key)
  );
]])

conn:exec([[ 
  CREATE TABLE IF NOT EXISTS links (
    discord TEXT PRIMARY KEY,
    roblox INTEGER
  );
]])

conn:exec([[ 
  CREATE TABLE IF NOT EXISTS errors (
    id TEXT PRIMARY KEY,
    info TEXT
  );
]])

conn:exec([[ 
  CREATE TABLE IF NOT EXISTS plus (
    userid TEXT PRIMARY KEY,
    slots INTEGER,
    guilds TEXT,
	codes TEXT,
	transactions TEXT
  );
]])

conn:exec([[ 
  CREATE TABLE IF NOT EXISTS blacklists (
    id TEXT PRIMARY KEY,
    reason TEXT
  );
]])

conn:exec([[ 
  CREATE TABLE IF NOT EXISTS affiliates (
    id TEXT PRIMARY KEY
  );
]])

conn:exec([[ 
  CREATE TABLE IF NOT EXISTS exportables (
    id TEXT PRIMARY KEY,
    owner TEXT,
    createdAt INTEGER,
    lastImported INTEGER,
    type TEXT,
    data TEXT,
	name TEXT
  );
]])

conn:exec([[ 
  CREATE TABLE IF NOT EXISTS user_settings (
    id TEXT PRIMARY KEY,
    config TEXT
  );
]])

conn:exec([[ 
  CREATE TABLE IF NOT EXISTS utils (
    key TEXT NOT NULL PRIMARY KEY,
    value TEXT
  );
]])

conn:exec([[ 
  CREATE TABLE IF NOT EXISTS refreshTokens (
    id TEXT PRIMARY KEY,
    refreshToken TEXT
  );
]])

conn:exec([[ 
  CREATE TABLE IF NOT EXISTS auth_sessions (
    user TEXT NOT NULL PRIMARY KEY,
	token TEXT NOT NULL,
    discordToken TEXT NOT NULL,
    refreshToken TEXT NOT NULL
  );
]])

--- End Data Tables ---

local sqldb = {}

sqldb.cache = {
	configs = {},
	blacklists = {},
	user_settings = {},
	linksByDiscord = {},
	linksByRoblox = {},
	plus = {},
	affiliates = {}
}

--- Helper Functions ---
local function makeTickYielder()
    local tick = 0
    return function()
        tick = 1 - tick
        if tick == 0 and coroutine.isyieldable() then
            local ok, err = pcall(function()
				coroutine.yield()
			end )

			if not ok then
				p("makeTickYielder", err)
			end
        end
    end
end

local function encodeTable(data)
	local st = realtime()
    local succ, encoded = pcall(cjson.encode, data)
	local et = realtime()
	local deltat = et - st

	if deltat > 0.2 then
		p("Encoding took longer than 200 ms")
	end

    if succ then
        return encoded
    else
        return nil, encoded
    end
end

local function decodeTable(data)
	local succ, decoded = pcall(cjson.decode, data)
	if succ then
		return decoded
	else
		return nil, decoded
	end
end

local function transformTableRows(input)
	if not input or type(input) ~= "table" then
		return {}
	end

	local result = {}

	local header = input.header
	if not header then
		return {}
	end

	for i, row in ipairs(input) do
		local newRow = {}
		for j, colName in ipairs(header) do
			newRow[colName] = row[j]
		end
		table.insert(result, newRow)
	end

	table.deeppairs(result, function(t, i, v)
		if type(v) == "cdata" then
			return tonumber(v)
		else
			return v
		end
	end)

	return result
end

local function transform_table(input, donotdecode)
	if not input or type(input) ~= "table" then
		return {}
	end

	local result = {}

	local header = input[0]

	for i, key in pairs(header) do
		local data_row = input[i]
		if data_row and #data_row > 0 then
			for i2, value in pairs(data_row) do
				result[i2] = result[i2] or {}
				result[i2][key] = value
			end
		end
	end

	if not donotdecode then
		for i, table in pairs(result) do
			for key, value in pairs(table) do
				if type(value) == "string" then
					if value:usub(1, 1) == "[" or value:usub(1, 1) == "{" then
						if not value:match("^%{%w+[%w%.]*%}$") then
							local ok, decoded = pcall(json.decode, value)
							if ok then
								table[key] = decoded
							end
						end
					end
				end
			end
		end
	end

	table.deeppairs(result, function(t, i, v)
		if type(v) == "cdata" then
			return tonumber(v)
		else
			return v
		end
	end)

	return result
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

--- End Helper Functions ---

--- Query Functions ---
local queryYielder = makeTickYielder()

function sqldb:_queryRun(query)
	coroutine.wrap(function()
		local now = realtime()
		sqldb.queryTimestamps = sqldb.queryTimestamps or {}
		table.insert(sqldb.queryTimestamps, now)

		for i, timestamp in pairs(sqldb.queryTimestamps) do
			if now - timestamp > 1 then
				table.remove(sqldb.queryTimestamps, i)
			end
		end
	end)()

	-- queryYielder()

	local st = realtime()
	local stmt = conn:prepare(query.query)
	if not stmt then
		log("Failed to prepare statement", "error", {query_text = query.query})
		return false, "Failed to prepare statement"
	end

	if query.values then
		local pcallOk, pcallError = pcall(stmt.bind, stmt, table.unpack(query.values))
		if not pcallOk then
			log("Failed to bind statement values", "error", {query_text = query.query, error = tostring(pcallError)})
			stmt:close()
			return false, tostring(pcallError)
		end
	end

	local results = {}
	local pcallOk, result

	repeat
		pcallOk, result = pcall(stmt.step, stmt)
		if not pcallOk then
			log("Failed to step statement", "error", {query_text = query.query, error = tostring(result)})
			stmt:close()
			return false, tostring(result)
		end

		if result then
			table.insert(results, result)
		end
	until not result

	stmt:close()
	local et = realtime()
	local deltat = et - st

	if deltat > 0.2 then
		-- p("query took longer than 200 ms:", string.truncate(query, 100))
	end

	return true, results
end

--- End Query Functions ---

--- Guild Functions ---
---@param guild_id string The ID of the guild.
---@param key string The key of the setting.
---@param value any The value of the setting.
---@return boolean, string|nil True on success, false and an error message on failure.
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
			INSERT OR REPLACE INTO guilds (guild_id, setting_key, setting_value, setting_type)
			VALUES (?, ?, ?, ?)
		]],
		values = {guild_id, key, value_to_store, setting_type}
	})

	if success then
		sqldb.cache.configs[guild_id] = sqldb.cache.configs[guild_id] or {}
		sqldb.cache.configs[guild_id][key] = value

		return true
	else
		log("Failed to set single for key '" .. key .. "' with reason '" .. reason .. "'", "error", {key=key, reason=reason, guild_id = tostring(guild_id)})
		return false, "Failed to write single."
	end
end

---@param guild_id string The ID of the guild.
---@param key string The key of the setting to delete.
---@return boolean, string|nil True on success, false and an error message on failure.
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
		log("Failed to delete single for key '" .. key .. "' with reason '" .. reason .. "'", "error", {key=key, reason=reason, guild_id = tostring(guild_id)})
		return false, "Failed to delete single."
	end
end

---@param guild_id string The ID of the guild
---@param notCached boolean|nil If it should NOT get it from cache
---@return table|nil
function sqldb:get(guild_id, notCached)
	if not notCached then
		return sqldb.cache.configs[guild_id]
	end

	local function transform(res)
		res.header = {"guild_id", "setting_key", "setting_value", "setting_type"}
		local rawConfig = transformTableRows(res)
		local config = {}

		for _, field in pairs(rawConfig) do
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

		return config
	end

	local success, result = sqldb:_queryRun({
		query = "SELECT * FROM guilds WHERE guild_id = ?",
		values = {guild_id},
	})

	if not success then
		return nil
	end

	local config = (type(result) == "table" and transform(result)) or {}

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

		timer.setTimeout(0, runNext)
	end

	runNext()
end

sqldb.set_keys = {}

---@param guild_id string The ID of the guild
---@param changes_table table A dictionary with the changes
---@param reason string The reason for the change
---@param member table|nil (Optional) A member object of who triggered the change
---@return boolean, table|string Returns true or false and the config or the error
function sqldb:set(guild_id, changes_table, reason, member)
	reason = reason or "no reason provided"
	sqldb.cache.configs = sqldb.cache.configs or {}
	if not guild_id or type(guild_id) ~= "string" or not tonumber(guild_id) then
		log("set received invalid guild_id", "error")
		return false, "guild_id was invalid or not provided"
	end

	if not changes_table or type(changes_table) ~= "table" or table.count(changes_table) < 1 then
		log("set changes_table was invalid or not provided", "error", {changes_table_count = table.count(changes_table) or 0, guild_id = tostring(guild_id)})
		return false, "changes_table was invalid or not provided"
	end

	if not reason or type(reason) ~= "string" then
		log("set reason was invalid or not provided", "error", {guild_id = tostring(guild_id)})
		return false, "reason was invalid or not provided"
	end

	sqldb.cache.configs[guild_id] = sqldb.cache.configs[guild_id] or {}
	local config = sqldb.cache.configs[guild_id]
	local changes = ""

	for key, value in pairs(changes_table) do
		coroutine.wrap(function()
			key = tostring(key)
			if key then
				sqldb.set_keys[key] = sqldb.set_keys[key] or 0
				sqldb.set_keys[key] = sqldb.set_keys[key] + 1
			end
		end)()
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

	local keys = {}
	for key, _ in pairs(changes_table) do
		table.insert(keys, key)
	end
	local keysChanged = table.concat(keys, ", ")

	if reason ~= "ERLCCACHE_UPDATE_ALL" and reason ~= "SET_AUTOMATION_LAST_TRIGGERED" and reason ~= "UPDATE_TRACKED_MODCALLS" then
		log("CHANGED " .. keysChanged .. " FOR " .. reason, "info", {guild_id = tostring(guild_id)})
	end

	return true, sqldb.cache.configs[guild_id]
end

---@return table|nil, string|nil A table of all guild configs or an error message.
function sqldb:getAllGuildConfigs(notCached)
	if not notCached and sqldb.cache.configs then
		return sqldb.cache.configs
	end

	local success, result = sqldb:_queryRun({
		query = "SELECT * FROM guilds"
	})

	local function transform(res)
		res.header = {"guild_id", "setting_key", "setting_value", "setting_type"}
		local rawGuildsConfig = transformTableRows(res)
		local guildConfigs = {}

		for _, field in pairs(rawGuildsConfig) do
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

	if not success then
		log("Failed to fetch all guild configs from database", "error")
		return nil, "Failed to fetch all guild configs"
	end

	return (type(result) == "table" and transform(result)) or {}
end

---@param guild_id string The ID of the guild to register.
---@return boolean, table|string True and the config on success, false and an error message on failure.
function sqldb:registerGuild(guild_id)
	local config = sqldb:get(guild_id)
	if config then
		return true, config
	end
	config = { prefix = "d!" }
	log("Registering new guild config", "info", {guild_id = tostring(guild_id)})
	return sqldb:set(guild_id, config, "REGISTER_GUILD")
end

---@param guild_id string The ID of the guild to delete.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:delete(guild_id)
	if not guild_id or type(guild_id) ~= "string" or not tonumber(guild_id) then
		log("Invalid guild_id provided for deletion", "error", {guild_id = guild_id})
		return false, "guild_id was invalid or not provided"
	end

	local success, result = sqldb:_queryRun({
		query = "DELETE FROM guilds WHERE guild_id = ?",
		values = {guild_id},
	})

	if success then
		sqldb.cache.configs[guild_id] = nil
		log("Successfully deleted config for guild", "info", {guild_id = tostring(guild_id)})
		return true
	else
		log("Failed to delete config for guild", "error", {guild_id = tostring(guild_id)})
		return false, "Failed to delete config"
	end
end

---@param guild_id string The ID of the guild.
---@param backupFile string The name of the backup file.
---@return boolean, table|string True and the restored config on success, false and an error message on failure.
function sqldb:loadGuildConfigFromBackup(guild_id, backupFile, push)
	if not guild_id or type(guild_id) ~= "string" then
		log("guild_id not provided or invalid for backup load", "error", {guild_id = guild_id, backup_file = backupFile})
		return false, "guild_id not provided or invalid"
	end
	if not backupFile or type(backupFile) ~= "string" then
		log("Backup file path not provided or invalid for backup load", "error", {backup_file = backupFile, guild_id = tostring(guild_id)})
		return false, "Backup file path not provided or invalid"
	end

	backupFile = "sqlbackups/".. backupFile

	if not string.match(backupFile, "%.db$") then
		log("Backup file must be a .db file", "error", {backup_file = backupFile, guild_id = tostring(guild_id)})
		return false, "Backup file must be a .db file"
	end

	local backupConn = sqlite3.open(backupFile)
	if not backupConn then
		log("Failed to open backup file", "error", {backup_file = backupFile, guild_id = tostring(guild_id)})
		return false, "Failed to open backup file"
	end

	local query = "SELECT setting_key, setting_value FROM guilds WHERE guild_id = '" .. guild_id .. "';"
	local result = backupConn:exec(query)
	backupConn:close()

	if result then
		local transformedResult = transform_table(result)
		local config = {}

		for _, field in pairs(transformedResult) do
			config[field.setting_key] = field.setting_value
		end

		if push then
			log("Restored config from backup", "info", {backup_file = backupFile, guild_id = tostring(guild_id)})
			return sqldb:set(guild_id, config, "RESTORE_FROM_BACKUP")
		else
			log("Fetched config from backup without pushing to active config", "info", {backup_file = backupFile, guild_id = tostring(guild_id)})
			return config
		end
	else
		log("No config found for guild_id in backup file", "warning", {backup_file = backupFile, guild_id = tostring(guild_id)})
		return false, "No config found for guild_id: " .. guild_id .. " in backup file."
	end
end

function sqldb:setConfigKeyType(key, keyType)
	if type(key) ~= "string" then
		log("Invalid key provided for setConfigKeyType", "error", {key = key, key_type = keyType})
		return false, "Invalid key."
	end

	if type(keyType) ~= "string" or (keyType ~= "string" and keyType ~= "number" and keyType ~= "table") then
		log("Invalid keyType provided for setConfigKeyType", "error", {key = key, key_type = keyType})
		return false, "Invalid keyType."
	end

    log("Starting guild config transfer to include setting_type.", "info")
    local query = "SELECT guild_id, setting_key, setting_value FROM guilds;"

    local all_guild_data = conn:exec(query)

    if not all_guild_data then
        log("Failed to fetch guild data for transfer.", "error")
        return false, "Failed to fetch guild data."
    end

    local transformed_data = transform_table(all_guild_data, true)
    if not transformed_data or #transformed_data == 0 then
        log("No data to transfer for setting_type.", "warning")
        return true
    end

    local total = #transformed_data
    log("Found " .. total .. " records to process for setting_type transfer.", "warning", {total_records = total})

    local success_count = 0
    local error_count = 0

    local stmt = conn:prepare("UPDATE guilds SET setting_type = ? WHERE guild_id = ? AND setting_key = ?;")
    if not stmt then
        log("Failed to prepare update statement for setting_type transfer.", "error")
        return false, "Failed to prepare update statement."
    end

    conn:exec("BEGIN TRANSACTION;")
    log("Beginning transaction for setConfigKeyType", "debug")

    for i, row in ipairs(transformed_data) do
		if row.setting_key == key then
			stmt:reset()
			stmt:bind(keyType, row.guild_id, row.setting_key)
			local step_res = stmt:step()

			if step_res == sqlite3.DONE then
				success_count = success_count + 1
			else
				error_count = error_count + 1
				log("Failed to update row for guild and key during setting_type transfer", "error", {key = row.setting_key, error_message = step_res, guild_id = tostring(row.guild_id)})
			end

			if i % 500 == 0 then
				log(string.format("Processing setConfigKeyType... %d/%d", i, total), "warning", {processed_count = i, total_records = total})
			end
		end
    end

    stmt:close()
    conn:exec("COMMIT;")
    log("Committing transaction for setConfigKeyType", "debug")

    log("Setting_type transfer complete.", "warning", {success_count = success_count, error_count = error_count})
    return true, success_count, error_count
end

sqldb:getAllGuildConfigs(true)

--- End Guild Functions ---

--- Plus Functions ---

function sqldb:plusSet(id, plus)
	if type(id) ~= "string" then
		log("Invalid id provided for plusSet", "error", {user_id = id})
		return false, "Invalid id provided."
	end

	plus.userid = plus.userid or id

	if type(plus) ~= "table" or not plus.userid or type(plus.slots) ~= "number" or type(plus.guilds) ~= "table" or type(plus.transactions) ~= "table" or type(plus.codes) ~= "table" then
		log("Invalid plus table provided", "error", {user_id = id, plus_data_type = type(plus)})
		return false, "Invalid plus table."
	end

	local guildsEncoded = encodeTable(plus.guilds)
	if not guildsEncoded then
		log("Failed to encode guilds table for user", "error", {user_id = id})
		return false, "Failed to encode guilds table."
	end

	local transactionsEncoded = encodeTable(plus.transactions)
	if not transactionsEncoded then
		log("Failed to encode transactions table for user", "error", {user_id = id})
		return false, "Failed to encode transactions table."
	end

	local codesEncoded = encodeTable(plus.codes)
	if not codesEncoded then
		log("Failed to encode codes table for user", "error", {user_id = id})
		return false, "Failed to encode codes table."
	end

	p(id, tostring(plus.slots), guildsEncoded, transactionsEncoded, codesEncoded)
	local success, result = sqldb:_queryRun({
		query = "INSERT OR REPLACE INTO plus (userid, slots, guilds, transactions, codes) VALUES (?, ?, ?, ?, ?)",
		values = {id, plus.slots, guildsEncoded, transactionsEncoded, codesEncoded},
	})

	if success then
		sqldb.cache.plus[id] = plus
		log("Set plus for user successfully", "info", {user_id = id, slots = plus.slots, num_guilds = table.count(plus.guilds)})
		return true, plus
	else
		log("Failed to execute query to set plus data for user", "error", {user_id = id, query_result = result})
		return false, "Failed to execute query"
	end
end

---@param notCached boolean|nil If true, fetches from the database instead of the cache.
---@return boolean, table|string True and a table of all plus data on success, false and an error message on failure.
function sqldb:plusAll(notCached)
	if not notCached then
		return true, sqldb.cache.plus
	end

	local success, result = sqldb:_queryRun({
		query = "SELECT * FROM plus"
	})

	local function transform(res)
		res.header = {"userid", "slots", "guilds", "codes", "transactions"}
		local t = transformTableRows(res)
		local allPlus = {}

		for _, v in pairs(t) do
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

		return allPlus
	end

	if not success then
		log("Failed to fetch all plus data from database", "error")
		return false, "Failed to fetch plusAll"
	end

	local allPlus = transform(result)

	if type(allPlus) == "table" then
		log("Fetched all plus data from database", "info")
		sqldb.cache.plus = allPlus
		return true, allPlus
	else
		log("Failed to fetch all plus data from database due to invalid transform result", "error", {transform_result_type = type(allPlus)})
		return false, "Failed to fetch plusAll"
	end
end

---@param user table|string The user object or ID.
---@param notCached boolean|nil If true, fetches from the database instead of the cache.
---@return boolean|nil, table|string|nil True and the plus data if the user has plus, false otherwise.
function sqldb:plusMember(user, notCached)
	if not user then
		log("User not provided for plusMember", "error")
		return false, "User not provided."
	end

	if type(user) == "table" then
		user = user.id
	end

	local plus

	if not notCached then
		plus = sqldb.cache.plus[user]
	else
		local success, result = sqldb:_queryRun({
			query = "SELECT * FROM plus WHERE userid = ?",
			values = {user},
		})

		if success and type(result) == "table" then
			result.header = {"userid", "slots", "guilds", "codes", "transactions"}

			local resultTransformed = transformTableRows(result)

			if type(resultTransformed) == "table" and type(resultTransformed[1]) == "table" then
				local rawPlus = resultTransformed[1]

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
                log("Failed to transform plus data from database", "warning", {user_id = user, raw_result_type = type(resultTransformed)})
			end
		else
            log("Failed to fetch plus data for user from database", "error", {user_id = user})
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

---@param guild table|string The guild object or ID.
---@param notCached boolean|nil If true, fetches from the database instead of the cache.
---@return boolean, table|string True and the plus data if the guild has plus, false otherwise.
function sqldb:plusGuild(guild, notCached)
	if not guild then
		log("Guild not provided for plusGuild", "error")
		return false, "Guild not provided."
	end

	if type(guild) == "table" then
		guild = guild.id
	end

	local succAllPlus, allPlus = sqldb:plusAll(notCached)

	if not succAllPlus then
		log("Failed to fetch all plus data for plusGuild check", "error", {guild_id = tostring(guild)})
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

---@param transactionToken string The token of the transaction
---@return boolean|nil, table|string Returns true if it was found, false if it failed, nil if it was not found. Returns transaction or error message as second value.
function sqldb:plusTransaction(transactionToken)
	local succ, allPlus = sqldb:plusAll()

	if not succ or type(allPlus) ~= "table" then
		log("Failed to get all plus data for plusTransaction check", "error", {transaction_token = transactionToken})
		return false, "Failed to get all plus data"
	end

	for _, plus in pairs(allPlus) do
		if type(plus.transactions) == "table" and next(plus.transactions) then
			for _, transaction in pairs(plus.transactions) do
				if type(transaction) == "table" then
					if transaction.token == transactionToken then
                        log("Plus transaction found", "debug", {transaction_token = transactionToken, user_id = plus.userid})
						return true, transaction
					end
				end
			end
		end
	end

	log("Plus transaction not found", "info", {transaction_token = transactionToken})
	return nil, "Transaction not found"
end

local function debug(str)
    if true then
        utilityChannels.development:send(str)
    end
end

---@param user table|string The user object or ID.
---@param slots number The amount of plus slots to purchase.
---@param discount table|nil ?The discount in table as {code = code, percentage = percentage}
---@param paid number The amount that was paid
---@param roblox table The roblox object of the buyer
---@param transactionToken string The token of the transaction
---@param time number|nil ?The time it was bought
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:plusPurchase(user, slots, discount, paid, roblox, transactionToken, time)
	time = time or os.time()

	if not user then
		log("User not provided for plusPurchase", "error")
		return false, "User not provided."
	end

	if not (type(user) == "table" and (class(user) == "Member" or class(user) == "User")) and not type(user) == "string" then
		log("Invalid user provided for plusPurchase", "error", {user_id = tostring(user)})
		return false, "Invalid user provided"
	elseif type(user) == "string" then
		user = Client:getUser(user)

		if not user then
			log("User not found for plusPurchase", "error", {user_id = tostring(user)})
			return false, "User not found"
		end
	end

	if type(paid) ~= "number" then
		log("Invalid paid value provided for plusPurchase", "error", {paid_value = paid, user_id = tostring(user.id)})
		return false, "Invalid paid value provided"
	end

	if type(roblox) ~= "table" or not roblox.id then
		log("Invalid roblox object provided for plusPurchase", "error", {roblox_data = tostring(roblox), user_id = tostring(user.id)})
		return false, "Invalid roblox object provided"
	end

	if type(transactionToken) ~= "string" then
		log("Invalid transactionToken provided for plusPurchase", "error", {transaction_token = transactionToken, user_id = tostring(user.id)})
		return false, "Invalid transactionToken provided"
	end

	local function notifyFailure(err)
		pcall(function()
			user:send(emojis.fail .. " An unexpected error occurred while attempting to grant you **" .. slots .. " slot" .. ((slots ~= 1 and "s") or "") .. "** of " .. emojis.duckyplus .. " **Ducky Plus+**. Please contact the " .. emojis.support .. " **Ducky Support** team.")
		end)
		pcall(function()
			utilityChannels.receipts:send({
				embed = {
					author = {
						name = "@" .. user.username .. " (" .. user.id .. ")",
						icon_url = user.avatarURL
					},
					title = emojis.fail .. " Purchase Failed",
					description = "> **@" .. user.username .. "** attempted to purchase **" .. slots .. " slot" .. ((slots ~= 1 and "s") or "") .. "** of " .. emojis.duckyplus .. " **Ducky Plus+**.\n\n" .. emojis.document .. " **Purchase Receipt**\n" .. emojis.right .. " **Slots:** " .. slots .. "\n" .. emojis.right .. " **Discount Code:** " .. ((discount and ("`" .. discount.code .. "` (" .. discount.percentage .. "% off)")) or "N/A") .. "\n" .. emojis.right .. " **Total:** " .. emojis.robux .. " " .. formatNumber(paid) .. "\n" .. emojis.right .. " **Date:** <t:" .. time .. ">\n" .. emojis.right .. " **Transaction:** `" .. transactionToken .. "`\n" .. emojis.right .. " **Error:** `" .. tostring(err) .. "`",
					timestamp = toISO(os.time()),
					color = colors.fail,
					thumbnail = thumbnail(user),
					footer = {
						text = (roblox.displayName or roblox.name) .. " (@" .. roblox.name .. ") (" .. roblox.id .. ")",
						icon_url = roblox.avatar
					}
				}
			})
		end)
	end

	local claimedTransaction = sqldb:plusTransaction(transactionToken)
	if claimedTransaction == false then
		log("Failed to validate transaction for plusPurchase", "error", {transaction_token = transactionToken, user_id = tostring(user.id)})
		notifyFailure("Failed to validate transaction")
		return false, "Failed to validate transaction"
	elseif claimedTransaction == true then
		log("Plus already claimed for plusPurchase", "warning", {transaction_token = transactionToken, user_id = tostring(user.id)})
		return false, "Plus already claimed"
	end

	local pond = pondMember(user)
	if pond and not pond:hasRole("1267239172444262490") then
		pond:addRole("1267239172444262490", "purchased Ducky Plus+")
		log("Added Ducky Plus+ role to user", "info", {user_id = user.id, role_id = "1267239172444262490"})
	end
	debug("Plus purchase (ID = " .. user.id .. "): Gave role")

	debug("Plus purchase (ID = " .. user.id .. "): Calling plusMember...")
	local _, plus = sqldb:plusMember(user)
	debug("Plus purchase (ID = " .. user.id .. "): Got plusMember: ```" .. encodeTable(plus) .. "```")

	if not plus then
		plus = {
			userid = user.id,
			slots = 0,
			guilds = {},
			transactions = {},
			codes = {}
		}
		log("Initialized new plus data for user", "info", {user_id = user.id})
	end

	plus.slots = plus.slots + slots
	debug("Plus purchase (ID = " .. user.id .. "): Added slots")

	table.insert(plus.transactions, {
		token = transactionToken,
		timestamp = time,
		discount = discount,
		paid = paid,
		slots = slots,
		roblox = roblox.id
	})
	debug("Plus purchase (ID = " .. user.id .. "): Inserted transaction")

	if discount then
		plus.codes[discount.code] = (plus.codes[discount.code] or 0) + 1
	end
	debug("Plus purchase (ID = " .. user.id .. "): Inserted discount")

	local succ, errorOrPlus = sqldb:plusSet(user.id, plus)
	if succ then
		debug("Plus purchase (ID = " .. user.id .. "): plusSet returned: " .. tostring(succ) .. " - " .. encodeTable(errorOrPlus))
	else
		debug("Plus purchase (ID = " .. user.id .. "): plusSet returned: " .. tostring(succ) .. " - " .. tostring(errorOrPlus))
	end
	debug("Plus purchase (ID = " .. user.id .. "): passed plusSet call... continuing")

	if not succ then
		log("Failed to set plus data for user after purchase logic", "error", {user_id = user.id, error_message = tostring(errorOrPlus)})
		notifyFailure("Failed to set plus data: " .. tostring(errorOrPlus))
		return false, "Failed to set plus data: " .. tostring(errorOrPlus)
	end

	debug("Plus purchase (ID = " .. user.id .. "): sending receipt")

	pcall(function()
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
	end)

	debug("Plus purchase (ID = " .. user.id .. "): receipt sent")
	debug("Plus purchase (ID = " .. user.id .. "): sending user confirmation")

	pcall(function()
		user:send(emojis.success .. " You have been granted **" .. slots .. " slot" .. ((slots ~= 1 and "s") or "") .. "** of " .. emojis.duckyplus .. " **Ducky Plus+**. Thank you for your support!\n-# " .. emojis.document .. " **Transaction Token:** " .. transactionToken)
	end)

	debug("Plus purchase (ID = " .. user.id .. "): user confirmation sent")
	debug("Plus purchase (ID = " .. user.id .. "): sending supporters")

	pcall(function()
		utilityChannels.supporters:send(":heart: " .. user.mentionString .. " has purchased **" .. slots .. " slot" .. ((slots ~= 1 and "s") or "") .. "** of " .. emojis.duckyplus .. " **Ducky Plus+**!\n-# " .. emojis.right .. " Thank you for your support!")
	end)

	debug("Plus purchase (ID = " .. user.id .. "): supporters sent")

	log("User purchased Ducky Plus+ slots successfully", "info", {user_id = user.id, slots_purchased = slots, total_slots = plus.slots, transaction_token = transactionToken})
	return true, errorOrPlus
end

---@param user table|string The user object or ID.
---@param guild table|string The guild object or ID.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:plusUse(user, guild)
	if not user then
		log("User not provided for plusUse", "error")
		return false, "User not provided."
	end

	if type(user) == "table" then
		user = user.id
	end

	if not guild then
		log("Guild not provided for plusUse", "error")
		return false, "Guild not provided."
	end

	if type(guild) == "table" then
		guild = guild.id
	end

	local active, plus = sqldb:plusMember(user, true)

	if (not active) or not plus then
		log("User does not have a Ducky Plus+ purchase", "error", {user_id = user, guild_id = guild})
		return false, "You do not have a Ducky Plus+ purchase."
	elseif plus.slots < 1 then
		log("User does not have any Ducky Plus+ slots available", "error", {user_id = user, guild_id = guild, available_slots = plus.slots})
		return false, "You do not have any Ducky Plus+ slots available."
	end

	plus.slots = plus.slots - 1
	table.insert(plus.guilds, guild)
    log("User used a Ducky Plus+ slot", "info", {user_id = user, remaining_slots = plus.slots, guild_added = guild, guild_id = tostring(guild)})

	return sqldb:plusSet(user, plus)
end

---@param user table|string The user object or ID.
---@param guild table|string The guild object or ID.
---@return boolean, table|string|nil True and plus data on success, false and an error message on failure.
function sqldb:plusRefund(user, guild)
	if type(user) == "string" then
		user = Client:getUser(user)
	end

	if class(user) ~= "Member" and class(user) ~= "User" then
		log("User not provided or not found for plusRefund", "error", {user_id = user and user.id})
		return false, "User not provided or not found."
	end

	if class(guild) == "Guild" then
		guild = guild.id
	end

	local Guild = Client:getGuild(guild)

	local active, plus = sqldb:plusMember(user, true)

	if (not active) or not plus then
		log("User does not have a Ducky Plus+ purchase to refund", "warning", {user_id = user.id})
		return false, "You do not have a Ducky Plus+ purchase."
	end

	local plusChanged

	for i, g in pairs(plus.guilds) do
		if g == guild then
			table.remove(plus.guilds, i)
			plus.slots = plus.slots + 1
			plusChanged = true
            log("Removed guild from plus guilds and refunded slot", "info", {user_id = user.id, guild_id = guild, new_slots = plus.slots})
		end
	end

	if not plusChanged then
		log("User is not providing Ducky Plus+ to that server for refund", "warning", {user_id = user.id, guild_id = guild})
		return false, "You are not providing Ducky Plus+ to that server."
	end

	local plusSetSuccess, plusSetError = sqldb:plusSet(user.id, plus)

	if not plusSetSuccess then
		log("Failed to set plus data after refund attempt", "error", {guild_id = guild, error_message = plusSetError, user_id = user.id})
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
					log("Failed to disable Ducky Plus+ features after refund", "error", {user_id = user.id, error_message = setError, guild_id = guild})
					return false, "Failed to disable Ducky Plus+ features: " .. setError
				end
                log("Ducky Plus+ features disabled for guild after refund", "info", {user_id = user.id, guild_id = guild})
			end
		end
	end

	utilityChannels.receipts:send(emojis.undo .. " **@" .. user.username .. "** (" .. user.id .. ") refunded one of their " .. emojis.duckyplus .. " **Ducky Plus+** slots from **" .. ((Guild and Guild.name) or "*Unknown*") .. "** (" .. guild .. ").")
	log("Ducky Plus+ slot refunded successfully", "info", {user_id = user.id, guild_id = guild})
	return true, plus
end

---@param user table|string The user object or ID of the gifter.
---@param targetUser table|string The user object or ID of the recipient.
---@return boolean, string|table True and the updated plus data on success, false and an error message on failure.
function sqldb:plusGift(user, targetUser)
	if not user then
		log("User not provided for plusGift", "error")
		return false, "User not provided."
	end

	if type(user) == "table" then
		user = user.id
	end

	local pondUser = pondMember(user)

	if not targetUser then
		log("TargetUser not provided for plusGift", "error", {user_id = user})
		return false, "TargetUser not provided."
	end

	if type(targetUser) == "table" then
		targetUser = targetUser.id
	end

	local pondTarget = pondMember(targetUser)

	if user == targetUser then
		log("User attempted to gift a slot to themselves", "warning", {user_id = user})
		return false, "You cannot gift a slot to yourself."
	end

	local userActive, userPlus = sqldb:plusMember(user, true)
	if (not userActive) or not userPlus then
		log("Gifting user does not have a Ducky Plus+ purchase", "warning", {user_id = user})
		return false, "You do not have a Ducky Plus+ purchase."
	elseif userPlus.slots <= 0 then
		log("Gifting user does not have any Ducky Plus+ slots available", "warning", {user_id = user, available_slots = userPlus.slots})
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
        log("Initialized new plus data for target user in plusGift", "info", {target_user_id = targetUser})
	end

	userPlus.slots = userPlus.slots - 1
	targetPlus.slots = targetPlus.slots + 1

	if pondTarget and not pondTarget:hasRole("1267239172444262490") then
		pondTarget:addRole("1267239172444262490", "received gifted Ducky Plus+ slot")
        log("Added Ducky Plus+ role to target user after gift", "info", {target_user_id = targetUser, role_id = "1267239172444262490"})
	end
	if userPlus.slots <= 0 and table.count(userPlus.guilds) <= 0 and pondUser and pondUser:hasRole("1267239172444262490") then
		pondUser:removeRole("1267239172444262490", "gifted Ducky Plus+ slot")
        log("Removed Ducky Plus+ role from gifting user as slots are now zero", "info", {user_id = user})
	end

	-- Save target first
	local success, err = sqldb:plusSet(targetUser, targetPlus)
	if not success then
		log("Failed to apply gifted slot to target user", "error", {gifting_user_id = user, target_user_id = targetUser, error_message = tostring(err)})
		return false, "Failed to apply slot to target: " .. tostring(err)
	end

	local success, err = sqldb:plusSet(user, userPlus)
	if not success then
		log("Failed to remove slot from gifting user", "error", {gifting_user_id = user, target_user_id = targetUser, error_message = tostring(err)})

		local rollbackSuccess, rollbackErr = sqldb:plusSet(targetUser, {
			userid = targetUser,
			slots = math.max(0, targetPlus.slots - 1),
			guilds = targetPlus.guilds,
		})

		if rollbackSuccess then
			log("Rolled back slot addition to target user", "info", {target_user_id = targetUser, rollback_slots = math.max(0, targetPlus.slots - 1)})
		else
			log("Failed to roll back slot addition to target user", "error", {target_user_id = targetUser, rollback_error = tostring(rollbackErr)})
		end

		return false, "Failed to remove slot from user: " .. tostring(err)
	end

	log("User gifted a Ducky Plus+ slot to target user successfully", "info", {gifting_user_id = user, target_user_id = targetUser, remaining_slots_gifter = userPlus.slots, new_slots_target = targetPlus.slots})
	return true, userPlus
end

---@param user table|string The user object or ID.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:plusDelete(user)
	user = (type(user) == "table" and user.id) or user

	local success, _ = self:_queryRun({
		query = "DELETE FROM plus WHERE userid = ?",
		values = { user }
	})

	if success then
		log("Deleted plus data for user", "info", {user_id = user})
		sqldb.cache.plus[user] = nil
		return true
	else
		log("Failed to delete plus data for user", "error", {user_id = user})
		return false, "Failed to delete plus data."
	end
end

function sqldb:plusImportTransactions(sampleTransactions)
	local success, allPlus = sqldb:plusAll()

	if not success or type(allPlus) ~= "table" then
		log("Failed to get all plus data for transaction import", "error")
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
		log("Failed to get group transactions or no transactions to import", "warning")
		return false, "Failed to get group transactions or no group transactions"
	end

	local count = 0

	local ok, err = pcall(function()
		local stmt = conn:prepare([[
			INSERT INTO plus (userid, transactions)
			VALUES (?, ?)
			ON CONFLICT(userid) DO UPDATE SET transactions = excluded.transactions;
		]])

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
                    log("Skipping transaction import: No Discord link found for Roblox user", "debug", {roblox_user_id = transaction.user.id, transaction_token = transaction.token})
				end
			else
                log("Skipping transaction import: Invalid or duplicate transaction data", "debug", {transaction_data = tostring(transaction.token), is_duplicate = not not existingTransactions[transaction.token]})
			end
		end

		for id, transactions in pairs(newUserTransactions) do
			local isPlus, plus = sqldb:plusMember(id)

			if type(plus) == "table" and type(plus.transactions) == "table" then
				local mergedTransactions = table.merge(plus.transactions, transactions)
				local encodedTransactions = encodeTable(mergedTransactions)

				if encodedTransactions then
					local ok, err, err2 = pcall(function()
						stmt:bind(id, encodedTransactions)
						return stmt:step()
					end)

					stmt:reset()

					if ok then
						count = count + 1
                        log("Successfully imported transactions for user", "debug", {user_id = id, num_transactions_imported = #transactions})
					else
                        log("Failed to update plus data with imported transactions for user", "error", {user_id = id, error_message = tostring(err)})
					end
				else
                    log("Failed to encode merged transactions for user", "error", {user_id = id})
				end
			else
                log("Invalid plus data for user during transaction import merge", "error", {user_id = id, plus_data_type = type(plus)})
			end
		end

		stmt:close()
	end)

	if not ok then
		log("plusImportTransactions pcall failed", "critical", {pcall_error = tostring(err)})
		return false, "Transaction failed: " .. tostring(err)
	elseif count == 0 then
		log("plusImportTransactions completed with no changes", "info")
		return true, "Nothing changed"
	else
		log("plusImportTransactions completed successfully", "info", {transactions_imported = count})
		return true, "Imported " .. tostring(count) .. " transactions"
	end
end

sqldb.plusAll(sqldb, true)

--- End Plus Functions ---

--- Link Functions ---
---@param member table The discord member object.
---@param roblox table|string|number The roblox user object, ID, or name.
---@return boolean, table|string True and the link data on success, false and an error message on failure.
function sqldb:link(member, roblox)
	if not _G.ropi then
		log("ROPI dependency not found for link operation", "error", {member_id = member and member.id, roblox_input = tostring(roblox)})
		return false, "The ROPI dependency could not be found."
	end

	if not member or not member.id then
		log("Discord member object invalid for link operation", "error", {member_input = tostring(member)})
		return false, "The discord member object is invalid."
	end

	if not roblox then
		log("Roblox object invalid for link operation", "error", member.id, {roblox_input = tostring(roblox)})
		return false, "The roblox object is invalid."
	end

	local robloxUser = (tonumber(roblox) and _G.ropi.GetUser(tonumber(roblox)))
		or (_G.ropi.SearchUser(tostring(roblox)))
		or (type(roblox) == "table" and roblox.name and roblox.id and roblox)
	if not robloxUser then
		log("Roblox user not found for link operation", "error", member.id, {roblox_input = tostring(roblox)})
		return false, "That Roblox user does not exist."
	end

	local existingDiscordLink = sqldb:getLink(member.id)
	if existingDiscordLink then
		local roblox = ropi.GetUser(existingDiscordLink.roblox)
		log("Discord account already linked", "warning", member.id, {discord_id = member.id, roblox_id = roblox.id})
		return false, "Your Discord account, @" .. member.username .. " (" .. member.id .. "), is already linked with Roblox account @" .. roblox.name .. " (" .. roblox.id .. ")."
	end

	local existingRobloxLink = sqldb:getLink(robloxUser.id)
	if existingRobloxLink then
		local discord = Client:getUser(existingRobloxLink.discord)
		log("Roblox account already linked", "warning", member.id, {discord_id = discord.id, roblox_id = robloxUser.id})
		return false, "Your Roblox account, @" .. robloxUser.name .. " (" .. robloxUser.id .. "), is already linked with Discord account @" .. discord.username .. " (" .. discord.id .. ")."
	end

	local success, result = sqldb:_queryRun({
		query = "INSERT OR REPLACE INTO links (discord, roblox) VALUES (?, ?)",
		values = {member.id, robloxUser.id},
	})

	if success then
		local link = { discord = member.id, roblox = robloxUser.id }
		sqldb.cache.linksByDiscord[member.id] = link
		sqldb.cache.linksByRoblox[tostring(robloxUser.id)] = link
		DuckyAPI:emit("userLinked", member, robloxUser)

		log("Successfully linked Discord user with Roblox user", "info", member.id, {discord_id = member.id, roblox_id = robloxUser.id})
		return true, link
	else
		log("Failed to link Discord user with Roblox user", "error", member.id, {discord_id = member.id, roblox_id = robloxUser.id, query_result = result})
		return false, "Failed to link member and roblox user"
	end
end

---@param id string|number The Discord or Roblox ID.
---@param notCached boolean|nil If true, fetches from the database instead of the cache.
---@return table|nil The link data if found.
function sqldb:getLink(id, notCached)
	if not notCached then
		local link = sqldb.cache.linksByDiscord[tostring(id)] or sqldb.cache.linksByRoblox[tostring(id)]
		if link then
			return link
		end
	end

	local success, result = sqldb:_queryRun({
		query = "SELECT discord, roblox FROM links WHERE (discord = ? OR roblox = ?)",
		values = {tostring(id), tonumber(id)},
	})

	if not success or type(result) ~= "table" then
        log("Failed to fetch link from database", "error", {id = id})
		return nil
	end

	result.header = {"discord", "roblox"}
	local resultTransformed = transformTableRows(result)
	return (type(resultTransformed) == "table" and resultTransformed[1]) or nil
end

---@param id string|number The Discord or Roblox ID to unlink.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:unLink(id)
	if type(id) ~= "string" and type(id) ~= "number" then
		log("Invalid ID type provided for unLink", "error", {id = id, id_type = type(id)})
		return false, "Invalid id type"
	end

	local success, result = sqldb:_queryRun({
		query = "DELETE FROM links WHERE (discord = ? OR roblox = ?)",
		values = {tostring(id), tonumber(id)},
	})

	if success then
		log("Successfully unlinked user with ID", "info", {user_id = id})
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
        log("Failed to unlink user with ID", "error", {user_id = id, query_result = result})
	end

	return success
end

---@param notCached boolean|nil If true, fetches from the database instead of the cache.
---@return table A table of all links.
function sqldb:getAllLinks(notCached)
	if not notCached then
		local links = {}
		for _, link in pairs(sqldb.cache.linksByDiscord) do
			table.insert(links, link)
		end
        log("Returning all links from cache", "debug", {num_links = #links})
		return links
	end

	local success, result = sqldb:_queryRun({
		query = "SELECT * FROM links",
	})

	if not success or type(result) ~= "table" then
        log("Failed to fetch all links from database", "error")
		return {}
	end

	result.header = {"discord", "roblox"}
	local allLinks = transformTableRows(result)
	
	sqldb.cache.linksByDiscord = {}
	sqldb.cache.linksByRoblox = {}
	for _, link in pairs(allLinks) do
		sqldb.cache.linksByDiscord[link.discord] = link
		sqldb.cache.linksByRoblox[tostring(link.roblox)] = link
	end

	log("Fetching all links from database", "info", {num_links = #allLinks})
	return allLinks
end

sqldb.getAllLinks(sqldb, true)

--- End Link Functions ---

--- Error Functions ---
---@param id string The ID of the error.
---@param info table The error information.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:saveError(id, info)
	if not id then
		log("Error ID not provided for saveError", "error")
		return false, "Id was not provided"
	end

	if not info then
		log("Error info not provided or invalid for saveError", "error", {error_id = id})
		return false, "Info was not provided or is invalid"
	end

	local json_info = encodeTable(info)

	local success, _ = self:_queryRun({
		query = "INSERT OR REPLACE INTO errors (id, info) VALUES (?, ?)",
		values = {id, json_info}
	})

	if success then
		log("Error saved successfully", "info", {error_id = id})
	else
		log("Failed to save error", "error", {error_id = id})
	end

	return success
end

---@param id string The ID of the error.
---@return table|nil The error information.
function sqldb:getError(id)
	local function transform(res)
		if res and res[1] and res[1][1] then
			return json.decode(res[1][1])
		else
			return nil
		end
	end

	log("Fetching error with ID", "info", {error_id = id})

	local success, result = self:_queryRun({
		query = "SELECT info FROM errors WHERE id = ?",
		values = {tostring(id)}
	})

	if not success then
        log("Failed to fetch error from database", "error", {error_id = id})
		return nil
	end

	return transform(result)
end

---@return table A table of all errors.
function sqldb:getAllErrors()
	local function transform(res)
		res.header = {"id", "info"}
		local transformed = transformTableRows(res)
		local errors = {}
		for _, row in ipairs(transformed) do
			errors[row.id] = json.decode(row.info)
		end
		return errors
	end

	log("Fetching all errors from database", "info")

	local success, result = self:_queryRun({
		query = "SELECT id, info FROM errors"
	})

	if not success then
        log("Failed to fetch all errors from database", "error")
		return {}
	end

	return transform(result)
end

---@param id string The ID of the error to delete.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:deleteError(id)
	local success, _ = self:_queryRun({
		query = "DELETE FROM errors WHERE id = ?",
		values = {tostring(id)}
	})

	if success then
		log("Error deleted successfully", "info", {error_id = id})
	else
		log("Failed to delete error", "error", {error_id = id})
	end

	return success
end

---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:resolveAllErrors()
	local errors = self:getAllErrors()

	if not errors then
		log("Failed to retrieve all errors for resolution", "error")
		return false, "Failed to get all errors"
	end

    log(string.format("Attempting to resolve %d errors", table.count(errors)), "info")

	for id, errTable in pairs(errors) do
		if not errTable.resolved then
			errTable.resolved = true
			local success, err_msg = self:saveError(id, errTable)
            if success then
                log("Error resolved successfully", "info", {error_id = id})
            else
                log("Failed to save resolved error", "error", {error_id = id, error_message = err_msg})
            end
		end
	end

    log("Resolution process for all errors completed", "info")
	return true
end

--- End Error Functions ---

-- Blacklist Functions ---

	local success, result = sqldb:_queryRun({
		query = "SELECT id, reason FROM blacklists"
	})

	if not success then
		return
	end

	result.header = {"id", "reason"}
	local rawBlacklists = transformTableRows(result)

	for _, blacklist in pairs(rawBlacklists) do
		sqldb.cache.blacklists[blacklist.id] = {id = blacklist.id, reason = blacklist.reason}
	end

	log("Initiated blacklist cache.")

---@param id string The ID to check.
---@param unCached boolean|nil If true, fetches from the database instead of the cache.
---@return boolean, table|string|nil True and the blacklist data if blacklisted, false and optionally an error message otherwise.
function sqldb:getBlacklist(id, unCached)
	if not id or not tonumber(id) then
		log("Invalid ID provided for getBlacklist", "warning", {id = id})
		return false, "Invalid ID."
	end

	if not unCached then
		return not not sqldb.cache.blacklists[id], sqldb.cache.blacklists[id]
	end

	local success, result = self:_queryRun({
		query = "SELECT id, reason FROM blacklists WHERE id = ?",
		values = {id}
	})

	if not success then
		log("Failed to query blacklist from database", "error", {user_id = id, query_result = result})
		return false, "Query failed"
	end

	return transform(result)
end

---@param id string The ID to blacklist.
---@param reason string The reason for the blacklist.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:addBlacklist(id, reason)
	if not id or not tonumber(id) then
		log("Invalid ID provided for addBlacklist", "error")
		return false, "Id not provided or invalid"
	end

	if not reason or reason == "" then
		log("Reason not provided or invalid for addBlacklist", "error", {user_id = id})
		return false, "Reason not provided or invalid"
	end

	local success, _ = self:_queryRun({
		query = "INSERT OR REPLACE INTO blacklists (id, reason) VALUES (?, ?)",
		values = {id, reason}
	})

	if success then
		sqldb.cache.blacklists = sqldb.cache.blacklists or {}
		sqldb.cache.blacklists[id] = { id = id, reason = reason }
		log("User added to blacklist successfully", "info", {user_id = id, reason = reason})
		return true, "ID added to blacklist with reason: " .. reason
	else
		log("Failed to add user to blacklist", "error", {user_id = id, reason = reason})
		return false, "Failed to add ID to blacklist"
	end
end

---@param id string The ID to remove from the blacklist.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:removeBlacklist(id)
	if not id then
		log("ID not provided for removeBlacklist", "error")
		return false, "ID not provided"
	end

	local success, _ = self:_queryRun({
		query = "DELETE FROM blacklists WHERE id = ?",
		values = {id}
	})

	if success then
		sqldb.cache.blacklists[id] = nil
		log("User removed from blacklist successfully", "info", {user_id = id})
		return true, "ID removed from blacklist"
	else
		log("Failed to remove user from blacklist", "error", {user_id = id})
		return false, "Failed to remove ID from blacklist"
	end
end

--- End Blacklist Functions ---

--- Exportables Functions ---
---@param id string The ID of the exportable.
---@param owner string The ID of the owner.
---@param createdAt number The creation timestamp.
---@param lastImported number The last import timestamp.
---@param TYPE string The type of the exportable.
---@param data string The data of the exportable.
---@param name string The name of the exportable.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:addExportable(id, owner, createdAt, lastImported, TYPE, data, name)
	if not id then
		log("Exportable ID not provided for addExportable", "error")
		return false, "Id was not provided"
	end
	if not owner then
		log("Owner ID not provided for addExportable", "error", {exportable_id = id})
		return false, "Owner was not provided"
	end
	if not createdAt then
		log("Creation timestamp not provided for addExportable", "error", {exportable_id = id})
		return false, "CreatedAt was not provided"
	end
	if not lastImported then
		log("Last imported timestamp not provided for addExportable", "error", {exportable_id = id})
		return false, "LastImported was not provided"
	end
	if not TYPE then
		log("Type not provided for addExportable", "error", {exportable_id = id})
		return false, "Type was not provided"
	end
	if not data then
		log("Data not provided or invalid for addExportable", "error", {exportable_id = id})
		return false, "Data was not provided or invalid"
	end
	if not name then
		log("Name not provided or invalid for addExportable", "error", {exportable_id = id})
		return false, "Name was not provided or invalid"
	end

	local success, _ = self:_queryRun({
		query = "INSERT OR REPLACE INTO exportables (id, owner, createdAt, lastImported, type, data, name) VALUES (?, ?, ?, ?, ?, ?, ?)",
		values = {id, owner, createdAt, lastImported, TYPE, data, name}
	})

	if success then
		log("Exportable added successfully", "info", {exportable_id = id, owner_id = owner, type = TYPE, name = name})
		return true, "Exportable added successfully."
	else
		log("Failed to add exportable", "error", {exportable_id = id, owner_id = owner, type = TYPE, name = name})
		return false, "Failed to add exportable."
	end
end

---@param id string The ID of the exportable.
---@param info table The new information for the exportable.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:setExportable(id, info)
	if not id then
		log("Exportable ID not provided for setExportable", "error")
		return false, "Id was not provided"
	end
	if not info then
		log("Exportable info not provided for setExportable", "error", {exportable_id = id})
		return false, "Info was not provided"
	end

	if info and type(info.data) == "table" then
		info.data = encodeTable(info.data)
	end

	local success, _ = self:_queryRun({
		query = "INSERT OR REPLACE INTO exportables (id, owner, createdAt, lastImported, type, data, name) VALUES (?, ?, ?, ?, ?, ?, ?)",
		values = {id, info.owner, info.createdAt, info.lastImported, info.type, info.data, info.name}
	})

	if success then
		log("Exportable updated successfully", "info", {exportable_id = id, owner_id = info.owner, type = info.type, name = info.name})
		return true, "Exportable updated successfully."
	else
		log("Failed to update exportable", "error", {exportable_id = id, owner_id = info.owner, type = info.type, name = info.name})
		return false, "Failed to update exportable."
	end
end

---@param id string The ID of the exportable to delete.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:deleteExportable(id)
	if not id then
		log("Exportable ID not provided for deleteExportable", "error")
		return false, "Id was not provided"
	end

	local success, result = self:_queryRun({
		query = "DELETE FROM exportables WHERE id = ?",
		values = {id}
	})

	if success then
		log("Exportable deleted successfully", "info", {exportable_id = id})
		return true, "Exportable deleted successfully."
	else
		log("Failed to delete exportable", "error", {exportable_id = id, query_result = tostring(result)})
		return false, "Error deleting exportable: " .. tostring(result)
	end
end

---@param id string The ID of the exportable to get.
---@return table|nil The exportable data.
function sqldb:getExportable(id)
	if not id then
		log("Exportable ID not provided for getExportable", "error")
		return nil
	end

	local function transform(res)
		res.header = {"id", "owner", "createdAt", "lastImported", "type", "data", "name"}
		local exportable = transformTableRows(res)
		if exportable and exportable[1] then
			return exportable[1]
		else
			return nil
		end
	end

	local success, result = self:_queryRun({
		query = "SELECT * FROM exportables WHERE id = ?",
		values = {id}
	})

	if not success then
		log("Failed to fetch exportable from database", "error", {exportable_id = id, query_result = tostring(result)})
		return nil
	end

	local exportable_data = transform(result)
	return exportable_data
end

---@return table A table of all exportables.
function sqldb:getAllExportables()
	local function transform(res)
		res.header = {"id", "owner", "createdAt", "lastImported", "type", "data", "name"}
		local exportables = transformTableRows(res)
		return exportables
	end

	local success, result = self:_queryRun({
		query = "SELECT * FROM exportables"
	})

	if not success then
		log("Failed to fetch all exportables from database", "error")
		return {}
	end

    local all_exportables = transform(result)
    log("Fetched all exportables from database", "info", {num_exportables = #all_exportables})
	return all_exportables
end

--- End Exportables Functions ---

--- Usersettings Functions ---
	sqldb.cache.user_settings = {}

	local success, result = sqldb:_queryRun({
		query = "SELECT id, config FROM user_settings"
	})

	if not success then
		return log("initUserSettings failed to get all user_settings", "error")
	end

	result.header = {"id", "config"}
	local allUserSettings = transformTableRows(result)

	for _, userSetting in pairs(allUserSettings) do
		sqldb.cache.user_settings[userSetting.id] = decodeTable(userSetting.config) or {}
	end

	log("Initiated user_settings cache.")

---@param user_id string The ID of the user.
---@param config table The new settings for the user.
---@return boolean, table|string True and the new settings on success, false and an error message on failure.
function sqldb:setUserSettings(user_id, config)
	if not user_id or type(user_id) ~= "string" then
		log("Invalid user_id or not provided for setUserSettings", "error")
		return false, "user_id is invalid or not provided"
	end

	if not config or type(config) ~= "table" then
		log("Config invalid or not provided for setUserSettings", "error", {user_id = user_id})
		return false, "config is invalid or not provided"
	end

	local json_value = encodeTable(config)

	local success, _ = self:_queryRun({
		query = "INSERT OR REPLACE INTO user_settings (id, config) VALUES (?, ?)",
		values = {user_id, json_value}
	})

	if success then
		self.cache.user_settings[user_id] = config
		log("User settings saved successfully", "info", {user_id = user_id})
		return true, config
	else
		log("Failed to save user settings", "error", {user_id = user_id})
		return false, "Failed to prepare or execute statement"
	end
end

---@param user_id string The ID of the user.
---@param notCached boolean|nil If true, fetches from the database instead of the cache.
---@return table|boolean|nil, string|nil The user settings, or false and an error message on failure.
function sqldb:getUserSettings(user_id, notCached)
	if not user_id or type(user_id) ~= "string" then
		log("Invalid user_id or not provided for getUserSettings", "error")
		return false, "user_id invalid or not provided"
	end

	if not notCached and self.cache.user_settings then
		return self.cache.user_settings[user_id]
	end

	local function transform(res)
        res.header = {"config"}
		local transformed = transformTableRows(res)
		if transformed and transformed[1] and transformed[1].config then
			local decoded = decodeTable(transformed[1].config)
			self.cache.user_settings[user_id] = decoded

			return decoded
		else
			return nil
		end
	end

	local success, result = self:_queryRun({
		query = "SELECT config FROM user_settings WHERE id = ?",
		values = {user_id}
	})

    if not success then
        log("Failed to fetch user settings from database", "error", {user_id = user_id})
        return nil
    end

    return transform(result)
end

---@param user_id string The ID of the user to delete settings for.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:deleteUserSettings(user_id)
	if not user_id or type(user_id) ~= "string" then
		log("Invalid user_id or not provided for deleteUserSettings", "error")
		return false, "user_id invalid or not provided"
	end

	local success, err = self:_queryRun({
        query = "DELETE FROM user_settings WHERE id = ?",
        values = {user_id}
    })

	if success then
		self.cache.user_settings[user_id] = nil
		log("User settings deleted successfully", "info", {user_id = user_id})
		return true, "User settings deleted successfully."
	else
		log("Failed to delete user settings", "error", {user_id = user_id, error_message = tostring(err)})
		return false, "Failed to delete user settings: " .. tostring(err)
	end
end

--- End Usersettings Functions ---

--- Affiliates Functions ---
---@param id string The ID to check.
---@return boolean, string|nil True if the ID is an affiliate, false otherwise.
function sqldb:isAffiliate(id, notCached)
	if not id or not tonumber(id) then
		return false, "Invalid ID."
	end

	if not notCached then
		return not not sqldb.cache.affiliates[id]
	end

	local function transform(res)
		res.header = {"id"}
		local transformed = transformTableRows(res)
		local is_affiliate = transformed and transformed[1] and true or false
		if is_affiliate then
			self.cache.affiliates[id] = true
		end
		return is_affiliate
	end

	local success, result = self:_queryRun({
		query = "SELECT id FROM affiliates WHERE id = ?",
		values = {id}
	})

	if not success then
		return false
	end

	return transform(result)
end

---@param id string The ID to add as an affiliate.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:addAffiliate(id)
	if not id or not tonumber(id) then
		log("Id was not provided or invalid", "error")
		return false, "Id not provided or invalid"
	end

	local success, _ = self:_queryRun({
		query = "INSERT OR REPLACE INTO affiliates (id) VALUES (?)",
		values = {id}
	})

	if success then
		self.cache.affiliates[id] = true
		log("Added ID " .. id .. " to affiliates", "info")
		return true
	else
		log("Failed to add ID " .. id .. " to affiliates", "error")
		return false, "Failed to prepare statement"
	end
end

---@param id string The ID to remove as an affiliate.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:removeAffiliate(id)
	if not id or not tonumber(id) then
		log("Id was not provided or invalid", "error")
		return false, "Id not provided or invalid"
	end

	local success, err = self:_queryRun({
		query = "DELETE FROM affiliates WHERE id = ?",
		values = {id}
	})

	if success then
		self.cache.affiliates[id] = nil
		log("Removed ID " .. id .. " from affiliates", "info")
		return true
	else
		log("Failed to remove ID " .. id .. " from affiliates: " .. tostring(err), "error")
		return false, "Failed to remove ID from affiliates: " .. tostring(err)
	end
end

function sqldb:allAffiliates()
	local success, result = sqldb:_queryRun({
		query = "SELECT id FROM affiliates"
	})

	if not success then
		return log("initAffiliates failed to get all affiliates", "error")
	end

	result.header = {"id"}
	local rawAffiliates = transformTableRows(result)

	for _, affiliate in pairs(rawAffiliates) do
		sqldb.cache.affiliates[affiliate.id] = true
	end

	return rawAffiliates
end

sqldb:allAffiliates()
log("Initiated affiliates cache.")
--- End Affiliates Functions ---

--- Start Utils Functions ---

---@param key string The key to get.
---@return any, string|nil The value associated with the key.
function sqldb:getUtils(key)
    if not key or type(key) ~= "string" then
		log("getUtils key invalid or not provided", "error")
        return false, "Key invalid or not provided"
    end

    log("getUtils (" .. key .. ") [Synchronous]")

    local stmt = conn:prepare("SELECT value FROM utils WHERE key = ?")
    if not stmt then
        log("getUtils (" .. key .. ") failed to prepare statement", "error")
        return nil
    end

    stmt:bind(key)
    local result = stmt:step()
    stmt:close()

    if result and result[1] then
        return result[1]
    else
        return nil
    end
end

---@param key string The key to set.
---@param value any The value to set.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:setUtils(key, value)
    if not key or type(key) ~= "string" then
		log("Key invalid or not provided", "error")
        return false, "Key invalid or not provided"
    end

    if value == nil then
		log("Value not provided", "error")
        return false, "Value not provided"
    end

    log("setUtils (" .. key .. ") [Synchronous]")

    local stmt = conn:prepare("INSERT OR REPLACE INTO utils (key, value) VALUES (?, ?)")
    if not stmt then
        log("setUtils (" .. key .. ") failed to prepare statement", "error")
        return false, "Failed to prepare statement"
    end

    stmt:bind(key, value)
    stmt:step()
    stmt:close()

    return true
end

---@param key string The key to delete.
---@return boolean, string|nil True on success, false and an error message on failure.
function sqldb:deleteUtils(key)
    if not key or type(key) ~= "string" then
		log("Key invalid or not provided", "error")
        return false, "Key invalid or not provided"
    end

    log("deleteUtils (" .. key .. ") [Synchronous]")

    local stmt = conn:prepare("DELETE FROM utils WHERE key = ?")
    if not stmt then
        log("deleteUtils (" .. key .. ") failed to prepare statement", "error")
        return false, "Failed to prepare statement"
    end

    stmt:bind(key)
    stmt:step()
    stmt:close()

    return true
end
--- End Utils Functions ---

--- Start refreshTokens Functions ---
function sqldb:getRefreshToken(id)
    if type(id) ~= "string" then
        log("getRefreshToken: Invalid id provided", "error")
        return false, "Invalid id provided"
    end

    local success, result = self:_queryRun({
        query = "SELECT refreshToken FROM refreshTokens WHERE id = ?",
        values = {id}
    })

    if not success then
        log("getRefreshToken: Query failed", "error")
        return false, "Query failed"
    end

    if result and result[1] and result[1][1] then
        return true, result[1][1]
    else
        return false, "No refresh token found"
    end
end

function sqldb:setRefreshToken(id, refreshToken)
	if type(id) ~= "string" then
        log("setRefreshToken: Invalid id provided", "error")
		return false, "Invalid id provided"
	end

	if type(refreshToken) ~= "string" then
        log("setRefreshToken: Invalid refreshToken provided", "error")
		return false, "Invalid refreshToken provided"
	end

	local success, _ = self:_queryRun({
        query = "INSERT OR REPLACE INTO refreshTokens (id, refreshToken) VALUES (?, ?)",
        values = {id, refreshToken}
    })

    if not success then
        log("setRefreshToken: Query failed", "error")
    end

	return success
end

function sqldb:deleteRefreshToken(id)
    if type(id) ~= "string" then
        log("deleteRefreshToken: Invalid id provided", "error")
        return false, "Invalid id provided"
    end

    local success, _ = self:_queryRun({
        query = "DELETE FROM refreshTokens WHERE id = ?",
        values = {id}
    })

    if not success then
        log("deleteRefreshToken: Query failed", "error")
    end

    return success
end
--- End refreshTokens Functions ---

--- Auth Session Functions ---
function sqldb:authUserToToken(user)
	if type(user) ~= "string" then
		return false, "Invalid user ID provided."
	end

	local success, raw = self:_queryRun({
        query = "SELECT * FROM auth_sessions WHERE user = ?",
        values = {user}
    })

	if not success then
		return false, "Query failed: " .. tostring(raw)
	end

	raw.header = {"user", "token", "discordToken", "refreshToken"}
	local result = transformTableRows(raw)

	if type(result) ~= "table" or not result[1] then
		return false, "Failed to transform raw"
	end

	return success, result[1]
end

function sqldb:authTokenToUser(token)
	if type(token) ~= "string" then
		return false, "Invalid token provided."
	end

	local success, raw = self:_queryRun({
        query = "SELECT * FROM auth_sessions WHERE token = ?",
        values = {token}
    })

	if not success then
		return false, "Query failed: " .. tostring(raw)
	end

	raw.header = {"user", "token", "discordToken", "refreshToken"}
	local result = transformTableRows(raw)

	if type(result) ~= "table" or not result[1] then
		return false, "Failed to transform raw"
	end

	return success, result[1]
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
		query = "INSERT OR REPLACE INTO auth_sessions (user, token, discordToken, refreshToken) VALUES (?, ?, ?, ?)",
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

--- Additional Functions ---

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

---@param userId string The ID of the user.
---@return table, string A table containing all user data and a readable version as a string.
function sqldb:getAllUserData(userId)
	local userData = {}
	local output = {}

	-- Ducky Plus
	local plusSucc, plusInfo = sqldb:plusMember(userId)
	if plusSucc and plusInfo then
		userData.duckyplus = plusInfo
		table.insert(output, "## **Ducky Plus**")
		table.insert(output, "- Slots: " .. tostring(plusInfo.slots))
		table.insert(output, "- Guilds: " .. table.concat(plusInfo.guilds or {}, ", "))
	end

	-- Roblox Link
	local robloxLink = sqldb:getLink(userId)
	if robloxLink then
		userData.link = robloxLink
		table.insert(output, "## **Roblox Link**")
		table.insert(output, "- Roblox ID: " .. robloxLink.roblox)
	end

	-- Blacklist
	local blacklistInfo = sqldb:getBlacklist(userId)
	if blacklistInfo then
		userData.blacklist = blacklistInfo
		table.insert(output, "## **Blacklist**")
		table.insert(output, "- Reason: " .. tostring(blacklistInfo.reason))
	end

	-- Exportables
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

	-- User Settings
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

	return conn:exec(query)
end

function sqldb:close()
	conn:close()
end

return sqldb
