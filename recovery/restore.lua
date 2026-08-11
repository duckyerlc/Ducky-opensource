local uv = require("uv")

local SCRIPT_DIR = args[0]:match("(.+)/[^/]+$") or "."
local ROOT_DIR = SCRIPT_DIR .. "/.."
local BACKUP_DIR = ROOT_DIR .. "/sqlbackups"
local CONTAINER = "ducky_postgres"

package.path = ROOT_DIR .. "/bot/?.lua;" .. package.path
local SECRETS = require("secrets")
local DB_USER = SECRETS.POSTGRES_USER or "ducky"
local DB_NAME = SECRETS.POSTGRES_DB or "ducky"

local file = args[1]

if not file then
	local latest_time = 0
	local latest_name
	local scanner = uv.fs_scandir(BACKUP_DIR)
	if scanner then
		while true do
			local name = uv.fs_scandir_next(scanner)
			if not name then break end
			if name:match("%.sql%.gz$") then
				local s = uv.fs_stat(BACKUP_DIR .. "/" .. name)
				if s and s.mtime.sec > latest_time then
					latest_time = s.mtime.sec
					latest_name = name
				end
			end
		end
	end
	if not latest_name then
		print("[RESTORE] No backups found in " .. BACKUP_DIR)
		os.exit(1)
	end
	file = BACKUP_DIR .. "/" .. latest_name
	print("[RESTORE] No file specified, using latest: " .. file)
end

local stat = uv.fs_stat(file)
if not stat then
	print("[RESTORE] File not found: " .. file)
	os.exit(1)
end

print("[RESTORE] Restoring from: " .. file)
io.write("[RESTORE] This will overwrite existing data. Continue? (y/N) ")
local confirm = io.read("*l")
if confirm ~= "y" and confirm ~= "Y" then
	print("[RESTORE] Aborted.")
	os.exit(0)
end

local cmd = string.format(
	"gunzip -c %s | docker exec -i %s psql -U %s -d %s -q",
	file, CONTAINER, DB_USER, DB_NAME
)

local ok = os.execute(cmd)
if ok then
	print("[RESTORE] Done.")
else
	print("[RESTORE] FAILED")
	os.exit(1)
end
