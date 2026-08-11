local uv = require("uv")

local SCRIPT_DIR = args[0]:match("(.+)/[^/]+$") or "."
local ROOT_DIR = SCRIPT_DIR .. "/.."
local BACKUP_DIR = ROOT_DIR .. "/sqlbackups"
local CONTAINER = "ducky_postgres"
local KEEP_DAYS = 5

package.path = ROOT_DIR .. "/bot/?.lua;" .. package.path
local SECRETS = require("secrets")
local DB_USER = SECRETS.POSTGRES_USER or "ducky"
local DB_NAME = SECRETS.POSTGRES_DB or "ducky"

os.execute("mkdir -p " .. BACKUP_DIR)

local timestamp = os.date("%Y_%m_%d_%H_%M_%S")
local dest = BACKUP_DIR .. "/" .. timestamp .. ".sql.gz"

local cmd = string.format(
	"docker exec %s pg_dump -U %s -d %s | gzip > %s",
	CONTAINER, DB_USER, DB_NAME, dest
)

local ok = os.execute(cmd)
if not ok then
	os.remove(dest)
	print("[BACKUP] FAILED: pg_dump error")
	os.exit(1)
end

local stat = uv.fs_stat(dest)
if not stat or stat.size == 0 then
	os.remove(dest)
	print("[BACKUP] FAILED: dump was empty")
	os.exit(1)
end

print("[BACKUP] Created: " .. dest)

local cutoff = os.time() - (KEEP_DAYS * 86400)
local scanner = uv.fs_scandir(BACKUP_DIR)
if scanner then
	while true do
		local name, typ = uv.fs_scandir_next(scanner)
		if not name then break end
		if name:match("%.sql%.gz$") then
			local path = BACKUP_DIR .. "/" .. name
			local s = uv.fs_stat(path)
			if s and s.mtime.sec < cutoff then
				os.remove(path)
				print("[BACKUP] Pruned: " .. name)
			end
		end
	end
end

print("[BACKUP] Done.")
