-- note that if any of these are missing, it may just crash

return {
	TOKEN = "DISCORD_BOT_TOKEN",
	DEV_ACCESS_IDS = {"DISCORD_USER_ID_OF_DEVELOPER"}, -- ids of people to give dev access
	DUCKY_CLIENT_SECRET = "DISCORD_CLIENT_SECRET",
    ROBLOX_CLIENT_ID = "ROBLOX_CLIENT_ID",
    ROBLOX_CLIENT_SECRET = "ROBLOX_CLIENT_SECRET",
    DUCKY_API_KEY = "RANDOM_STRING_FOR_PROTECTED_API_ENDPOINT_ACCESS",
	ERLC_GLOBAL_API_KEY = "ERLC_GLOBAL_API_KEY",
	ROBLOSECURITY = ".ROBLOSECURITY_COOKIE", -- for getting roblox group transactions (ducky plus)
	TOP_GG_VOTE_AUTH = "TOP_GG_VOTE_WEBHOOK_AUTH", -- for vote webhook
	TOP_GG_API_KEY = "TOP_GG_API_KEY", -- for updating stats
	DISCORD_BOT_LIST_API_KEY = "DISCORD_BOT_LIST_API_KEY", -- for updating stats
	DISCORD_BOTS_GG_API_KEY = "DISCORD_BOTS_GG_API_KEY", -- for updating stats
	ADERLC_API_KEY = "ADERLC_API_KEY", -- for aderlc votes
	-- these are only used in sqlpg.lua, but sqldb.lua is used by default
	POSTGRES_HOST = "POSTGRES_HOST",
	POSTGRES_PORT = 0000,
	POSTGRES_USER = "POSTGRES_USER",
	POSTGRES_DB = "POSTGRES_DB",
	POSTGRES_PASSWORD = "POSTGRES_PASSWORD",
}
