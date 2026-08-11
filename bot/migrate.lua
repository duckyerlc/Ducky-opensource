local uv  = require("uv")
package.loaded['coro-net'] = require('coro-net')
package.loaded['coro-wrapper'] = require('coro-wrapper')
package.loaded['postgres-codec'] = require('postgres-codec')
package.loaded['md5'] = require('md5')
package.loaded['mutex-wrapper'] = require('mutex-wrapper')
local pg  = require("postgres")

local sqlite3 = require("sqlite3")

local function log(msg)
	print("[MIGRATE] " .. msg)
end

local SQLITE_FILE = "data.db"
local sqliteConn = sqlite3.open(SQLITE_FILE)
if not sqliteConn then
	error("Could not open SQLite database: " .. SQLITE_FILE)
end
log("Opened SQLite database: " .. SQLITE_FILE)

local SECRETS = require("secrets")
local pgConn, pgErr = pg.connect({
	host     = SECRETS.POSTGRES_HOST     or "localhost",
	port     = SECRETS.POSTGRES_PORT     or 5432,
	username = SECRETS.POSTGRES_USER     or "ducky",
	database = SECRETS.POSTGRES_DB       or "ducky",
	password = SECRETS.POSTGRES_PASSWORD,
})
if not pgConn then
	error("Could not connect to PostgreSQL: " .. tostring(pgErr))
end
log("Connected to PostgreSQL")

local ddl = {
	[[CREATE TABLE IF NOT EXISTS guilds (
		guild_id TEXT NOT NULL, setting_key TEXT NOT NULL,
		setting_value TEXT, setting_type TEXT DEFAULT 'string',
		PRIMARY KEY (guild_id, setting_key)
	)]],
	[[CREATE TABLE IF NOT EXISTS links (
		discord TEXT PRIMARY KEY, roblox BIGINT
	)]],
	[[CREATE TABLE IF NOT EXISTS errors (
		id TEXT PRIMARY KEY, info TEXT
	)]],
	[[CREATE TABLE IF NOT EXISTS plus (
		userid TEXT PRIMARY KEY, slots INTEGER,
		guilds TEXT, codes TEXT, transactions TEXT
	)]],
	[[CREATE TABLE IF NOT EXISTS blacklists (
		id TEXT PRIMARY KEY, reason TEXT
	)]],
	[[CREATE TABLE IF NOT EXISTS affiliates (
		id TEXT PRIMARY KEY
	)]],
	[[CREATE TABLE IF NOT EXISTS exportables (
		id TEXT PRIMARY KEY, owner TEXT,
		"createdAt" BIGINT, "lastImported" BIGINT,
		"type" TEXT, data TEXT, name TEXT
	)]],
	[[CREATE TABLE IF NOT EXISTS user_settings (
		id TEXT PRIMARY KEY, config TEXT
	)]],
	[[CREATE TABLE IF NOT EXISTS utils (
		key TEXT NOT NULL PRIMARY KEY, value TEXT
	)]],
	[[CREATE TABLE IF NOT EXISTS "refreshTokens" (
		id TEXT PRIMARY KEY, "refreshToken" TEXT
	)]],
	[[CREATE TABLE IF NOT EXISTS auth_sessions (
		"user" TEXT NOT NULL PRIMARY KEY, token TEXT NOT NULL,
		"discordToken" TEXT NOT NULL, "refreshToken" TEXT NOT NULL
	)]],
}

for _, sql in ipairs(ddl) do
	local ok, err = pgConn.query(sql)
	if not ok then
		log("DDL warning: " .. tostring(err))
	end
end
log("Tables created / verified")

local function sqliteReadAll(tableName, columns)
	local colStr = table.concat(columns, ", ")
	local raw = sqliteConn:exec("SELECT " .. colStr .. " FROM " .. tableName .. ";")
	if not raw then return {} end

	local rows = {}
	local nRows = 0
	for _, colname in ipairs(columns) do
		local vals = raw[colname]
		if vals then
			nRows = math.max(nRows, #vals)
		end
	end

	for i = 1, nRows do
		local row = {}
		for _, colname in ipairs(columns) do
			local vals = raw[colname]
			row[colname] = vals and vals[i] or nil
		end
		rows[#rows + 1] = row
	end

	return rows
end

local function esc(v)
	if v == nil then return "NULL" end
	local s = tostring(v)
	s = s:gsub("LL$", "")
	s = s:gsub("ULL$", "")
	return "'" .. s:gsub("'", "''") .. "'"
end

local function migrateTable(tableName, columns, pgColumns)
	pgColumns = pgColumns or columns
	local rows = sqliteReadAll(tableName, columns)
	if #rows == 0 then
		log(tableName .. ": 0 rows (skipped)")
		return
	end

	local pgColStr = table.concat(pgColumns, ", ")

	pgConn.query("BEGIN;")

	local inserted = 0
	for _, row in ipairs(rows) do
		local vals = {}
		for i, col in ipairs(columns) do
			vals[i] = esc(row[col])
		end

		local conflictCol = pgColumns[1]
		local sql = string.format(
			"INSERT INTO %s (%s) VALUES (%s) ON CONFLICT DO NOTHING;",
			tableName, pgColStr, table.concat(vals, ", ")
		)

		pgConn.query("SAVEPOINT sp;")
		local ok, err = pgConn.query(sql)
		if ok then
			inserted = inserted + 1
			pgConn.query("RELEASE SAVEPOINT sp;")
		else
			log(tableName .. " INSERT error: " .. tostring(err))
			pgConn.query("ROLLBACK TO SAVEPOINT sp;")
		end
	end

	pgConn.query("COMMIT;")
	log(tableName .. ": " .. inserted .. "/" .. #rows .. " rows migrated")
end

migrateTable("guilds",
	{"guild_id", "setting_key", "setting_value", "setting_type"},
	{"guild_id", "setting_key", "setting_value", "setting_type"}
)

migrateTable("links",
	{"discord", "roblox"},
	{"discord", "roblox"}
)

migrateTable("errors",
	{"id", "info"},
	{"id", "info"}
)

migrateTable("plus",
	{"userid", "slots", "guilds", "codes", "transactions"},
	{"userid", "slots", "guilds", "codes", "transactions"}
)

migrateTable("blacklists",
	{"id", "reason"},
	{"id", "reason"}
)

migrateTable("affiliates",
	{"id"},
	{"id"}
)

do
	local rows = sqliteReadAll("exportables", {"id", "owner", "createdAt", "lastImported", "type", "data", "name"})
	if #rows > 0 then
		pgConn.query("BEGIN;")
		local inserted = 0
		for _, row in ipairs(rows) do
			local sql = string.format(
				[[INSERT INTO exportables (id, owner, "createdAt", "lastImported", "type", data, name) VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING;]],
				esc(row.id), esc(row.owner), esc(row.createdAt), esc(row.lastImported),
				esc(row.type), esc(row.data), esc(row.name)
			)
			pgConn.query("SAVEPOINT sp;")
			local ok, err = pgConn.query(sql)
			if ok then inserted = inserted + 1
				pgConn.query("RELEASE SAVEPOINT sp;")
			else log("exportables INSERT error: " .. tostring(err))
				pgConn.query("ROLLBACK TO SAVEPOINT sp;")
			end
		end
		pgConn.query("COMMIT;")
		log("exportables: " .. inserted .. "/" .. #rows .. " rows migrated")
	else
		log("exportables: 0 rows (skipped)")
	end
end

migrateTable("user_settings",
	{"id", "config"},
	{"id", "config"}
)

migrateTable("utils",
	{"key", "value"},
	{"key", "value"}
)

do
	local rows = sqliteReadAll("refreshTokens", {"id", "refreshToken"})
	if #rows > 0 then
		pgConn.query("BEGIN;")
		local inserted = 0
		for _, row in ipairs(rows) do
			local sql = string.format(
				[[INSERT INTO "refreshTokens" (id, "refreshToken") VALUES (%s, %s) ON CONFLICT DO NOTHING;]],
				esc(row.id), esc(row.refreshToken)
			)
			pgConn.query("SAVEPOINT sp;")
			local ok, err = pgConn.query(sql)
			if ok then inserted = inserted + 1
				pgConn.query("RELEASE SAVEPOINT sp;")
			else log("refreshTokens INSERT error: " .. tostring(err))
				pgConn.query("ROLLBACK TO SAVEPOINT sp;")
			end
		end
		pgConn.query("COMMIT;")
		log("refreshTokens: " .. inserted .. "/" .. #rows .. " rows migrated")
	else
		log("refreshTokens: 0 rows (skipped)")
	end
end

do
	local rows = sqliteReadAll("auth_sessions", {"user", "token", "discordToken", "refreshToken"})
	if #rows > 0 then
		pgConn.query("BEGIN;")
		local inserted = 0
		for _, row in ipairs(rows) do
			local sql = string.format(
				[[INSERT INTO auth_sessions ("user", token, "discordToken", "refreshToken") VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING;]],
				esc(row.user), esc(row.token), esc(row.discordToken), esc(row.refreshToken)
			)
			pgConn.query("SAVEPOINT sp;")
			local ok, err = pgConn.query(sql)
			if ok then inserted = inserted + 1
				pgConn.query("RELEASE SAVEPOINT sp;")
			else log("auth_sessions INSERT error: " .. tostring(err))
				pgConn.query("ROLLBACK TO SAVEPOINT sp;")
			end
		end
		pgConn.query("COMMIT;")
		log("auth_sessions: " .. inserted .. "/" .. #rows .. " rows migrated")
	else
		log("auth_sessions: 0 rows (skipped)")
	end
end

sqliteConn:close()
pgConn.close()
log("Migration complete! The old data.db has been preserved.")
log("You can now switch main.lua to require('sqlpg') and restart.")
