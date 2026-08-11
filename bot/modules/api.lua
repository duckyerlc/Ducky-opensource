-- api.lua
local api = {
	name = "api",
	description = "The ultimate Ducky API, https://api.duckybot.xyz."
}

local http = _G.luvithttp
local corohttp = _G.http
local snowGen = snowflake.new(1, 1) -- only API can use 1, 1
local null = json.null

local ROBLOX_CLIENT_ID = SECRETS.ROBLOX_CLIENT_ID
local ROBLOX_CLIENT_SECRET = SECRETS.ROBLOX_CLIENT_SECRET
local DUCKY_CLIENT_ID = Client.user.id
local DUCKY_CLIENT_SECRET = SECRETS.DUCKY_CLIENT_SECRET
local DUCKY_API_KEY = SECRETS.DUCKY_API_KEY

local connection = nil

local host = "0.0.0.0"
local port = 8001

_G.DuckyAPI = _G.DuckyAPI or discordia.Emitter()

local Caches = {
	Team = {},
	Guilds = {}
}

local listeners = {}

local function logAPIUsage(str)
	return prettyLog("API", "purple", str)
end

local function logRequest(req, statusCode)
	local IP = req.headers["X-Real-IP"] or "UNKNOWN"
	local PATH = req.url or "UNKNOWN"

	local logLine = string.format("%s UTC | IP=%s | METHOD=%s | PATH=%s | STATUS=%d | UA=\"%s\"\n", os.date("!%Y-%m-%d %H:%M:%S"), IP, req.method or "UNKNOWN", PATH, statusCode or 0, req.headers["user-agent"] or "unknown")

	prettyLog("API", "purple", logLine)
end

local function getDiscordTokens(discordCode, redirectUri)
	local ok, res, body = pcall(corohttp.request, "POST", "https://discord.com/api/v10/oauth2/token", {
			{ "Content-Type", "application/x-www-form-urlencoded" }
		}, querystring.stringify({
			client_id = DUCKY_CLIENT_ID,
			client_secret = DUCKY_CLIENT_SECRET,
			grant_type = "authorization_code",
			code = discordCode,
			redirect_uri = redirectUri
		}))

	if not ok then
		return ok, res
	end

	body = body and json.decode(body)

	if not res or res.code ~= 200 or not body or not body.access_token then
		local errorMsg = body and body.error_description or "Unknown error"
		return false, "Failed to exchange authorization code for tokens: " .. errorMsg
	end

	local discordToken = body.access_token
	local refreshToken = body.refresh_token

	return discordToken, refreshToken
end

local function discordTokenToID(discordToken)
	local userRes, userBody = corohttp.request("GET", "https://discord.com/api/v10/users/@me", {
		{ "Authorization", "Bearer " .. discordToken }
	})
	userBody = userBody and json.decode(userBody)

	if not userRes or userRes.code ~= 200 or not userBody or not userBody.id then
		local errorMsg = userBody and userBody.message or "Unknown error"
		return false, "Failed to identify user: " .. errorMsg
	end

	return userBody.id
end

local function authSession(discordCode, origin)
	if type(discordCode) ~= "string" then
		return false, "Invalid discordCode provided."
	end

	origin = origin or "duckybot.xyz/login"

	local discordToken, refreshToken = getDiscordTokens(discordCode, origin .. "/login") -- If error: false, error

	if type(discordToken) ~= "string" or type(refreshToken) ~= "string" then
		return discordCode, refreshToken
	end

	local user, err = discordTokenToID(discordToken)
	if type(user) ~= "string" then
		return user, err
	end

	local token, err = generateUUID()
	if not token then
		return false, "Failed to generate UUID: " .. tostring(err)
	end

	return sqldb:authSet(user, token, discordToken, refreshToken)
end

local function getRobloxIDFromCode(code)
	local request_body = querystring.stringify({
		client_id = ROBLOX_CLIENT_ID,
		client_secret = ROBLOX_CLIENT_SECRET,
		grant_type = "authorization_code",
		code = code,
		redirect_uri = "https://duckybot.xyz/link"
	})

	local hdrs = {
		{
			"Content-Type",
			"application/x-www-form-urlencoded"
		}
	}

	local token_res, body = corohttp.request("POST", "https://apis.roblox.com/oauth/v1/token", hdrs, request_body)

	body = json.parse(body)

	local access_token = body.access_token

	if access_token then
		local userinfo_headers = {
			{
				"Authorization",
				"Bearer " .. access_token
			},
			{
				"Content-Type",
				"application/json"
			}
		}

		local userinfo_res, userinfobody = corohttp.request("GET", "https://apis.roblox.com/oauth/v1/userinfo", userinfo_headers)

		userinfobody = json.parse(userinfobody)

		if userinfobody.sub then
			local roblox_id = userinfobody.sub

			if roblox_id and tonumber(roblox_id) then
				return tonumber(roblox_id)
			else
				return nil, {
					code = 503,
					message = "The Roblox API did not provide a user ID."
				}
			end
		else
			return nil, {
				code = 503,
				message = userinfobody.message or "The Roblox API returned an unknown error while attempting to fetch user information."
			}
		end
	else
		return nil, {
			code = 503,
			message = body.message or "The Roblox API returned an unknown error while attempting to fetch user information."
		}
	end
end

local function getGuildInfo(guildId, userId)
	local guild = Client:getGuild(guildId)
	local member = guild and guild:getMember(userId)

	if guild and member then
		local permissions = {}
		local config = sqldb:get(guild.id) or {}
		local active, plus = sqldb:plusGuild(guild)

		for name, has in pairs(perms) do
			permissions[name] = has(member, config) == true
		end

		return {
			name = guild.name,
			id = guild.id,
			icon = guild.iconURL,
			owner = guild.ownerId,
			members = guild.totalMemberCount,
			permissions = permissions,
			role = (guild.ownerId == userId and "Owner") or ((member:hasPermission("manageGuild") == true or permissions["ERLC_MANAGER"] == true) and "Manager") or (permissions["ERLC_ADMIN"] == true and "Administrator") or (permissions["ERLC_STAFF"] == true and "Moderator"),
			ducky = not not guild.me,
			plus = {
				active = active,
				plus = plus
			},
			affiliate = not not sqldb:isAffiliate(guild.id)
		}
	end
end

local function fetchMutualGuilds(DiscordCode, DiscordUser)
	local result, body = corohttp.request("GET", "https://discord.com/api/users/@me/guilds", {
		{
			"Authorization",
			"Bearer " .. DiscordCode
		},
		{
			"Content-Type",
			"application/json"
		}
	})
	body = body and json.decode(body)

	if (not result) or (not body) then
		return {
			code = 504,
			message = "The Discord API failed to respond."
		}
	elseif (result.code ~= 200) then
		return {
			code = 503,
			message = "The Discord API did not return a successful response.",
			data = {
				code = result.code,
				message = result.reason or result.message
			}
		}
	end

	local Guilds = {}

	for _, rawGuild in pairs(body) do
		local guildInfo = Client:getGuild(rawGuild.id) and getGuildInfo(rawGuild.id, DiscordUser.id)

		if guildInfo then
			table.insert(Guilds, guildInfo)
		end
	end

	return Guilds
end

local function fetchLink(ID)
	for _, l in pairs(sqldb:getAllLinks() or {}) do
		if tostring(l.roblox) == tostring(ID) or tostring(l.discord) == tostring(ID) then
			return l
		end
	end
end

local function requestAuthorized(request)
	for _, header in pairs(request.headers or {}) do
		if header[1]:lower() == "authorization" then
			return header[2] == DUCKY_API_KEY
		end
	end

	return false
end

local function realtime()
	local seconds, microseconds = _G.uv.gettimeofday()

	return seconds + (microseconds / 1000000)
end

local function updateLinkedRoleMetadata(discordCode, userId, redirectUri)
	local accessToken
	local refreshToken

	if not userId then
		if not discordCode then
			return false, "Either a discordCode or userId must be provided"
		end

		local res, body = corohttp.request("POST", "https://discord.com/api/v10/oauth2/token", {
			{ "Content-Type", "application/x-www-form-urlencoded" }
		}, querystring.stringify({
			client_id = DUCKY_CLIENT_ID,
			client_secret = DUCKY_CLIENT_SECRET,
			grant_type = "authorization_code",
			code = discordCode,
			redirect_uri = redirectUri
		}))

		body = body and json.decode(body)

		if not res or res.code ~= 200 or not body or not body.access_token then
			local errorMsg = body and body.error_description or "Unknown error"
			return false, "Failed to exchange authorization code for tokens: " .. errorMsg
		end

		accessToken = body.access_token
		refreshToken = body.refresh_token

		local userRes, userBody = corohttp.request("GET", "https://discord.com/api/v10/users/@me", {
			{ "Authorization", "Bearer " .. accessToken }
		})
		userBody = userBody and json.decode(userBody)

		if not userRes or userRes.code ~= 200 or not userBody or not userBody.id then
			local errorMsg = userBody and userBody.message or "Unknown error"
			return false, "Failed to identify user: " .. errorMsg
		end

		userId = userBody.id
	else
		if discordCode then
			local res, body = corohttp.request("POST", "https://discord.com/api/v10/oauth2/token", {
				{ "Content-Type", "application/x-www-form-urlencoded" }
			}, querystring.stringify({
				client_id = DUCKY_CLIENT_ID,
				client_secret = DUCKY_CLIENT_SECRET,
				grant_type = "authorization_code",
				code = discordCode,
				redirect_uri = redirectUri
			}))

			body = body and json.decode(body)

			if not res or res.code ~= 200 or not body or not body.access_token then
				local errorMsg = body and body.error_description or "Unknown error"
				return false, "Failed to exchange authorization code for tokens: " .. errorMsg
			end

			accessToken = body.access_token
			refreshToken = body.refresh_token
		else
			local success, token = sqldb:getRefreshToken(userId)

			if not success or not token then
				return false, "No refresh token found for user '" .. userId .. "'"
			end

			local res, body = corohttp.request("POST", "https://discord.com/api/v10/oauth2/token", {
				{ "Content-Type", "application/x-www-form-urlencoded" }
			}, querystring.stringify({
				client_id = DUCKY_CLIENT_ID,
				client_secret = DUCKY_CLIENT_SECRET,
				grant_type = "refresh_token",
				refresh_token = token
			}))

			body = body and json.decode(body)

			if not res or res.code ~= 200 or not body or not body.access_token then
				local errorMsg = body and body.error_description or "Unknown error"
				return false, "Failed to refresh access token: " .. errorMsg
			end

			accessToken = body.access_token
			if body.refresh_token then
				refreshToken = body.refresh_token
			end
		end
	end

	local member = userId and pondMember(userId)

	if not member then
		return false, "You are not a member of Ducky's Pond."
	end

	if refreshToken then
		sqldb:setRefreshToken(userId, refreshToken)
	end

	local metadata = {
		dev = (hasPermission(member, "BOT_DEVELOPER") and 1) or 0,
		mgmt = (hasPermission(member, "MANAGEMENT") and 1) or 0,
		admin = (member:hasRole("1259747827337396265") and 1) or 0,
		support = (hasPermission(member, "SUPPORT") and 1) or 0,
		qa = (hasPermission(member, "QUALITY_ASSURANCE") and 1) or 0
	}


	local metadataRes, metadataBody = corohttp.request("PUT", "https://discord.com/api/v10/users/@me/applications/" .. Client.user.id .. "/role-connection", {
		{ "Authorization", "Bearer " .. accessToken },
		{ "Content-Type", "application/json" }
	}, json.encode({
		platform_name = "Ducky Dev",
		metadata = metadata
	}))

	metadataBody = metadataBody and json.decode(metadataBody)

	if not metadataRes or metadataRes.code ~= 200 then
		local errorMsg = metadataBody and metadataBody.message or "Unknown error"
		return false, "Failed to update metadata: " .. errorMsg
	end

	return true
end

_G.endpoints = {
	["/"] = {
		methods = {
			["GET"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local requestReceived = realtime()
					local requestSent = headers and headers["sent-epoch"] and tonumber(headers["sent-epoch"])
					local responseLatency = (requestReceived and requestSent and ((requestReceived - requestSent) * 1000)) or null

					local _, output = shell([[echo "$(git rev-parse --abbrev-ref HEAD)|$(git rev-parse HEAD)|$(git log -1 --pretty=format:"%s|%al|%ct")"]])
					local versionData = (output and output:split("|")) or {}

					return finish({
						code = 200,
						message = "The Ducky API is online.",
						data = {
							version = {
								name = version,
								branch = versionData[1] or null,
								commit = {
									sha = versionData[2] or null,
									message = versionData[3] or null,
									author = versionData[4] and (versionData[4]:split("%+") or {})[2] or null,
									timestamp = (versionData[5] and tonumber(versionData[5])) or null
								}
							},
							health = {
								api = {
									latency = {
										process = (realtime() - request.receivedAt) * 1000,
										response = responseLatency
									}
								},
								bot = {
									shards = shardHealth,
									uptime = {
										epoch = uptime,
										readable = readable(requestReceived - uptime, true)
									}
								}
							},
							resources = {
								memory = math.round(process.memoryUsage().rss / 1000000, 2)
							}
						}
					})
				end
			}
		}
	},
	["/statistics"] = {
		methods = {
			["GET"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local guildCount = #Client.guilds
					local userCount = getTotalUserCount()
					local linkCount = table.count(sqldb:getAllLinks() or {})

					return finish({
						code = 200,
						message = "Bot statistics were fetched successfully.",
						data = {
							guilds = guildCount,
							users = userCount,
							links = linkCount
						}
					})
				end
			}
		}
	},
	["/team"] = {
		methods = {
			["GET"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local allDuckyTeamMembers = (next(Caches.Team) and Caches.Team) or {}

					if not next(allDuckyTeamMembers) then
						local dictionaryTeamMembers = {}
						local allDuckyTeamRoles = {
							{
								category = "docwriter",
								roles = {
									{
										id = "1311330617824378940",
										position = 1
									}
								}
							},
							{
								category = "qa",
								roles = {
									{
										id = "1260070830180667402",
										position = 1
									}
								}
							},
							{
								category = "mod",
								roles = {
									{
										id = "1259747806697099285",
										position = 2
									},
									{
										id = "1268884117026771005",
										position = 1
									}
								}
							},
							{
								category = "support",
								roles = {
									{
										id = "1259747747091972116",
										position = 2
									},
									{
										id = "1268331755245404202",
										position = 1
									},
									{
										id = "1307699685200498779",
										position = 3
									}
								}
							},
							{
								category = "admin",
								roles = {
									{
										id = "1259747827337396265",
										position = 1
									}
								}
							},
							{
								category = "mgmt",
								roles = {
									{
										id = "1268774900735148135",
										position = 1
									},
									{
										id = "1500147632318709830",
										position = 2
									},
									{
										id = "1476300937369878578",
										position = 3
									}
								}
							},
							{
								category = "dev",
								roles = {
									{
										id = "1286472622984400946",
										position = 1
									},
									{
										id = "1264291121312432280",
										position = 2
									},
									{
										id = "1419398641180737606",
										position = 3
									},
									{
										id = "1307699534343700540",
										position = 4
									},
									{
										id = "1421893961584480316",
										position = 5
									}
								}
							}
						}

						loadMembers(duckysPond)

						for _, entry in ipairs(allDuckyTeamRoles) do
							local category = entry.category
							for _, roleData in ipairs(entry.roles) do
								local role = duckysPond:getRole(roleData.id)

								for _, member in pairs(role.members) do
									dictionaryTeamMembers[member.id] = {
										name = member.name,
										username = member.user.username,
										discord_id = member.id,
										avatar = member.user.avatarURL,
										role = role.name,
										color = role:getColor():toHex(),
										category = category,
										position = roleData.position
									}
								end
							end
						end

						for ID, info in pairs(dictionaryTeamMembers) do
							table.insert(allDuckyTeamMembers, info)
						end

						Caches.Team = allDuckyTeamMembers
					end

					return finish({
						code = 200,
						message = "All Ducky Team members have been successfully fetched.",
						data = allDuckyTeamMembers
					})
				end
			}
		}
	},
	["/users"] = {
		additionalURLParameters = true,
		methods = {
			["GET"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local ID = parameters[1]
					local me = ID == "@me"
					local Token = headers["token"]

					if me then
						if Token then
							local success, result = sqldb:authTokenToUser(Token)

							if not success or type(result) ~= "table" then
								return finish({
									code = 401,
									message = "Provided token was not found in the database."
								})
							end

							ID = result.user

							if blacklisted(ID) then
								return finish({
									code = 403,
									message = "You are blacklisted from Ducky."
								})
							end
						else
							return finish({
								code = 400,
								message = "Header 'Token' was not provided."
							})
						end
					end

					if (not ID) or (ID == "") then
						return finish({
							code = 400,
							message = "An invalid ID was provided."
						})
					end

					local DiscordUser = Client:getUser(ID)
					local RobloxUser = ((not DiscordUser) and ropi.SearchUser(ID)) or nil

					if DiscordUser then
						return finish({
							code = 200,
							message = "A Discord user was found with that ID.",
							data = DiscordUserObject(DiscordUser)
						})
					elseif RobloxUser then
						return finish({
							code = 200,
							message = "A Roblox user was found with that ID.",
							data = RobloxUser
						})
					else
						return finish({
							code = 404,
							message = "A Discord or Roblox user was not found with the ID of '" .. ID .. "'."
						})
					end
				end
			}
		}
	},
	["/feedback"] = {
		methods = {
			["GET"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local config = sqldb:get(duckysPond.id) or {}
					local feedback = table.deepcopy(config.duckyfeedback or {})
					local filtered = {}

					feedback = table.shuffle(feedback)
					for _, review in pairs(feedback) do
						if table.count(filtered) >= 10 then break end
						local user = Client:getUser(review.submitter)
						if user and review.rating >= 4 then
							review.submitter = DiscordUserObject(user)
							table.insert(filtered, review)
						end
					end

					return finish({
						code = 200,
						message = "Feedback fetched successfully.",
						data = filtered
					})
				end
			}
		}
	},
	["/links"] = {
		additionalURLParameters = true,
		methods = {
			["GET"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					if request.method == "GET" then
						local ID = parameters[1] and parameters[1]:lower()

						if (not ID) or (ID == "") or (not tonumber(ID) and not tostring(ID)) then
							return finish({
								code = 400,
								message = "An invalid ID or Roblox username was provided."
							})
						end

						if tostring(ID) then
							local RobloxUser = ropi.SearchUser(ID)

							if RobloxUser then
								ID = RobloxUser.id
							end
						end

						if not tonumber(ID) then
							return finish({
								code = 400,
								message = "An invalid Roblox username was provided."
							})
						end

						local link = sqldb:getLink(ID)

						if (link) and (link.discord) and (link.roblox) then
							local DiscordUser = Client:getUser(link.discord)
							local RobloxUser = ropi.GetUser(link.roblox)

							if (not DiscordUser) or (DiscordUser.id ~= link.discord) then
								return finish({
									code = 404,
									message = "Discord user " .. tostring(link.discord) .. " could not be found."
								})
							elseif not RobloxUser or (RobloxUser.id ~= link.roblox) then
								return finish({
									code = 404,
									message = "Roblox user " .. tostring(link.roblox) .. " could not be found."
								})
							else
								return finish({
									code = 200,
									message = "Link fetched successfully.",
									data = {
										discord = DiscordUserObject(DiscordUser),
										roblox = RobloxUser
									}
								})
							end
						else
							return finish({
								code = 404,
								message = "Link not found."
							})
						end

					end
				end
			},
			["POST"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local Token = headers["token"]
					local RobloxCode = headers["roblox-code"]

					if (not Token) or (Token == "") then
						return finish({
							code = 400,
							message = "Header 'Token' was not provided."
						})
					elseif (not RobloxCode) or (RobloxCode == "") then
						return finish({
							code = 400,
							message = "Header 'Roblox-Code' was not provided."
						})
					end

					local success, result = sqldb:authTokenToUser(Token)

					if not success or type(result) ~= "table" then
						return finish({
							code = 401,
							message = "Provided token was not found in the database."
						})
					end

					local DiscordID = result.user

					if DiscordID then
						if blacklisted(DiscordID) then
							return finish({
								code = 403,
								message = "You are blacklisted from Ducky."
							})
						end

						local RobloxID, err = getRobloxIDFromCode(RobloxCode)

						if RobloxID then
							local DiscordUser = Client:getUser(DiscordID)
							local RobloxUser = ropi.GetUser(tonumber(RobloxID))

							if (not DiscordUser) then
								return finish({
									code = 404,
									message = "Discord user '" .. DiscordID .. "' was not found."
								})
							elseif (not RobloxUser) then
								return finish({
									code = 404,
									message = "Roblox user '" .. RobloxID .. "' was not found."
								})
							else
								local success, err = sqldb:link(DiscordUser, RobloxUser)

								if success then
									return finish({
										code = 200,
										message = "Discord user '@" .. DiscordUser.username .. "' successfully linked with Roblox user '@" .. RobloxUser.name .. "'.",
										data = {
											discord = DiscordUserObject(DiscordUser),
											roblox = RobloxUser
										}
									})
								else
									return finish({
										code = (tostring(err):find("already") and 409) or 500,
										message = tostring(err)
									})
								end
							end
						else
							return finish(err)
						end
					else
						return finish(err)
					end
				end
			},
			["DELETE"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local Token = headers["token"]
					local RobloxCode = headers["roblox-code"]

					if RobloxCode and RobloxCode ~= "" then
						local RobloxID, err = getRobloxIDFromCode(RobloxCode)

						if RobloxID then
							if not sqldb:getLink(RobloxID) then
								return finish({
									code = 404,
									message = "No link was found for Roblox user with ID '" .. tostring(RobloxID) .. "'."
								})
							end

							sqldb:unLink(RobloxID)

							return finish({
								code = 200,
								message = "Roblox user has been successfully unlinked."
							})
						else
							return finish(err)
						end
					elseif Token and Token ~= "" then
						if (not Token) or (Token == "") then
							return finish({
								code = 400,
								message = "Header 'Token' was not provided."
							})
						end

						local success, result = sqldb:authTokenToUser(Token)

						if not success or type(result) ~= "table" then
							return finish({
								code = 401,
								message = "Provided token was not found in the database."
							})
						end

						local DiscordID = result.user

						if DiscordID then
							if not sqldb:getLink(DiscordID) then
								return finish({
									code = 404,
									message = "No link was found for Discord user with ID '" .. DiscordID .. "'."
								})
							end

							local DiscordUser = Client:getUser(DiscordID)

							if (not DiscordUser) then
								return finish({
									code = 404,
									message = "Discord user '" .. DiscordID .. "' was not found."
								})
							else
								sqldb:unLink(DiscordUser.id)

								return finish({
									code = 200,
									message = "Discord user '@" .. DiscordUser.username .. "' has been successfully unlinked."
								})
							end
						else
							return finish(err)
						end
					else
						return finish({
							code = 400,
							message = "No Discord or Roblox code was provided."
						})
					end
				end
			}
		}
	},
	["/auth"] = {
		methods = {
			["POST"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local DiscordCode = headers and headers["discord-code"]

					if (not DiscordCode) or (DiscordCode == "") then
						return finish({
							code = 401,
							message = "Header 'Discord-Code' was not provided."
						})
					end

					local succ, result = authSession(DiscordCode, headers and headers["origin"])

					if succ and type(result) == "table" then
						local user = result.user and Client:getUser(result.user)

						if user then
							return finish({
								code = 200,
								message = "Session has been successfully authorized.",
								data = {
									token = result.token,
									user = DiscordUserObject(user)
								}
							})
						else
							return finish({
								code = 404,
								message = "Unable to find user with ID '" .. result.user .. "'."
							})
						end
					else
						return finish({
							code = 500,
							message = "An error occurred while trying to create a session: " .. tostring(result)
						})
					end
				end
			},
			["DELETE"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local token = headers and headers["token"]

					if (not token) or (token == "") then
						return finish({
							code = 401,
							message = "Header 'token' was not provided."
						})
					end

					local succ, err = sqldb:authDelete(token)

					if succ then
						return finish({
							code = 200,
							message = "Successfully deleted auth information for token '" .. token .. "'."
						})
					else
						return finish({
							code = 500,
							message = "Failed to delete auth information: " .. tostring(err)
						})
					end
				end
			}
		}
	},
	["/guilds"] = {
		additionalURLParameters = true,
		methods = {
			["ANY"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local GuildID = (parameters[1] and parameters[1] ~= "" and parameters[1]) or nil
					local Action = (parameters[2] and parameters[2] ~= "" and parameters[2]:lower()) or nil
					local SubAction = (parameters[3] and parameters[3] ~= "" and parameters[3]:lower()) or nil
					local Token = headers and headers["token"]

					if (not Token) or (Token == "") then
						return finish({
							code = 401,
							message = "Header 'Token' was not provided."
						})
					elseif (GuildID and GuildID ~= "") and ((not Action) or (Action == "")) then
						return finish({
							code = 400,
							message = "No action was provided."
						})
					end

					local success, result = sqldb:authTokenToUser(Token)

					if not success and type(result) == "table" then
						return finish({
							code = 401,
							message = "Provided token was not found in the database."
						})
					end

					local DiscordID = result.user

					if DiscordID then
						if blacklisted(DiscordID) then
							return finish({
								code = 403,
								message = "You are blacklisted from Ducky."
							})
						end

						local User = Client:getUser(DiscordID)

						if not User then
							return finish({
								code = 404,
								message = "User with ID '" .. DiscordID .. "' not found."
							})
						end

						if Action ~= "transcripts" and hasPermission(User, "QUALITY_ASSURANCE") ~= true and (type(GuildID) == "string" and not sqldb:isAffiliate(GuildID)) then
							return finish({
								code = 403,
								message = "The modpanel is currently only available to Quality Assurance members and official Affiliates."
							})
						end

						if GuildID then
							local Guild = Client:getGuild(GuildID)

							if Guild then
								if blacklisted(Guild) then
									return finish({
										code = 403,
										message = "The target guild is blacklisted from Ducky."
									})
								end

								local config = sqldb:get(GuildID) or {}
								local Member = Guild:getMember(DiscordID)

								if not Member then
									return finish({
										code = 403,
										message = "You are not a member of the target guild."
									})
								end

								local ERLC_STAFF = (hasPermission(Member, "ERLC_STAFF", config) == true) or false
								local ERLC_ADMIN = (hasPermission(Member, "ERLC_ADMIN", config) == true) or false
								local ERLC_MANAGER = (hasPermission(Member, "ERLC_MANAGER", config) == true) or false
								local MANAGE_SERVER = (hasPermission(Member, "MANAGE_SERVER", config) == true) or false

								if Action == "panel" and request.method == "GET" and ERLC_STAFF then
									local data = {}

									-- // ERLC Data
									if config.apikey then
										local server, err = ERLC:getServer(config.apikey)

										if server then
											local raw = server:raw()

											local ids = {}
											for _, player in pairs(raw.players) do
												table.insert(ids, player.id)
											end

											local users, error = ropi.GetUsers(ids, {avatars = true, dictionary = true, fillUnknown = true})

											if type(users) == "table" and not error then
												for _, player in pairs(raw.players) do
													player.roblox = users[tonumber(player.id)]
												end
											end

											data.erlc = raw
										end
									end

									-- // Shift Data
									if config.shifts then
										data.shifts = {}

										local availableTypes = {}

										for _, v in pairs(config.shifts.types or {}) do
											local shiftType = db:shiftType(Guild, v.name, Member)

											if shiftType then
												table.insert(availableTypes, shiftType)
											end
										end

										if next(availableTypes) then
											data.shifts.types = availableTypes

											local wave = db:shiftWave(Guild)

											if wave then
												data.shifts.me = {}

												local active, pause = db:shiftActive(Member)

												if active then
													data.shifts.me.active = active
													data.shifts.me.active.paused = pause
													data.shifts.me.active.elapsed, data.shifts.me.active.pausetime = db:shiftElapsed(Guild, active.id)
												end

												local history = db:shiftHistory(Member)

												if history then
													for i, v in pairs(history) do
														history[i].elapsed, history[i].pausetime = db:shiftElapsed(Guild, v.id)
													end

													data.shifts.me.history = history
												end
											end
										end
									end

									--// Punishments Data
									data.punishmentTypes = config.punishmenttypes
									data.bolos = {}

									local bolos = config.bolos and table.deepcopy(config.bolos) or {}
									local count = 0

									for _, bolo in pairs(bolos) do
										if count < 25 then
											bolo.user = ropi.GetUser(bolo.user)
											bolo.moderator = Client:getUser(bolo.moderator) and DiscordUserObject(Client:getUser(bolo.moderator)) or {
												id = bolo.moderator,
												username = "Unknown"
											}
											table.insert(data.bolos, bolo)
											count = count + 1
										end
									end

									return finish({
										code = 200,
										message = "Panel data for '" .. Guild.name .. "' fetched successfully.",
										data = data
									})
								elseif Action == "erlc" and SubAction == "data" and request.method == "GET" and ERLC_STAFF then
									if (not config) or (not config.apikey) then
										return finish({
											code = 404,
											message = "No ERLC server found."
										})
									end

									local server, err = ERLC:getServer(config.apikey)
									if not server then
										return finish({
											code = 401,
											message = err
										})
									end

									server = server:raw()

									if next(server.players) then
										for _, player in pairs(server.players) do
											player.roblox = ropi.GetUser(player.id) -- ropi caching 🥱
										end
									end

									return finish({
										code = 200,
										message = "ERLC server information for '" .. Guild.name .. "' fetched successfully.",
										data = server
									})
								elseif Action == "erlc" and SubAction == "execute" and request.method == "POST" and ERLC_MANAGER then
									if (not config) or (not config.apikey) then
										return finish({
											code = 404,
											message = "No ERLC server found."
										})
									elseif (not body) or (not body.command) then
										return finish({
											code = 400,
											message = "Body field 'command' not provided."
										})
									end

									local server, err = ERLC:getServer(config.apikey)
									if not server then
										return finish({
											code = 401,
											message = err
										})
									end

									local succ, err = server:execute(body.command)
									if not succ then
										return finish({
											code = 401,
											message = err
										})
									end

									return finish({
										code = 200,
										message = "The command has been successfully executed within the in-game server."
									})
								elseif Action == "erlc" and SubAction == "check" and request.method == "GET" and ERLC_STAFF then
									if (not config) or (not config.apikey) then
										return finish({
											code = 404,
											message = "No ERLC server found."
										})
									end

									local results = {}

									local server, err = ERLC:getServer(config.apikey)
									if not server then
										return finish({
											code = 500,
											message = "The PRC API returned an error: " .. tostring(err)
										})
									end

									for _, v in pairs(server.players) do
										local link = fetchLink(v.id)

										if link and link.discord and Guild:getMember(link.discord) then
											local linkedMember = Guild:getMember(link.discord)

											table.insert(results, {
												pass = true,
												roblox = ropi.GetUser(v.id),
												discord = DiscordUserObject(linkedMember)
											})
										else
											table.insert(results, {
												pass = false,
												roblox = ropi.GetUser(v.id)
											})
										end
									end

									return finish({
										code = 200,
										message = "An ERLC Discord check has been executed for '" .. Guild.name .. "' successfully.",
										data = results
									})
								elseif Action == "bolos" and request.method == "GET" and ERLC_STAFF then
									local player = SubAction
									local bolos = config.bolos and table.deepcopy(config.bolos) or {}

									table.sort(bolos, function(a, b)
										return a.created > b.created
									end)

									if type(player) == "string" and player ~= "" then
										for _, bolo in pairs(bolos) do
											if tostring(bolo.user) == player then
												bolo.user = ropi.GetUser(bolo.user)
												bolo.moderator = Client:getUser(bolo.moderator) and DiscordUserObject(Client:getUser(bolo.moderator)) or {
													id = bolo.moderator,
													username = "Unknown"
												}

												return finish({
													code = 200,
													message = "BOLO for '" .. player .. "' in '" .. Guild.name .. "' fetched successfully.",
													data = bolo
												})
											end
										end
									else
										local results = {}
										local count = 0

										for _, bolo in pairs(bolos) do
											if count < 25 then
												bolo.user = ropi.GetUser(bolo.user)
												bolo.moderator = Client:getUser(bolo.moderator) and DiscordUserObject(Client:getUser(bolo.moderator)) or {
													id = bolo.moderator,
													username = "Unknown"
												}
												table.insert(results, bolo)
												count = count + 1
											end
										end

										return finish({
											code = 200,
											message = "BOLOs for '" .. Guild.name .. "' fetched successfully.",
											data = results
										})
									end
								elseif Action == "bolos" and (not SubAction) and request.method == "POST" and ERLC_STAFF then
									local username = body.username
									local reason = body.reason

									if (not username) or (username == "") then
										return finish({
											code = 400,
											message = "Body field 'username' was not provided."
										})
									elseif (not reason) or (reason == "") then
										return finish({
											code = 400,
											message = "Body field 'reason' was not provided."
										})
									end

									local RobloxUser = ropi.SearchUser(username)

									if RobloxUser then
										local bolo, err = db:createBOLO(RobloxUser, reason, Member, nil, config, {id = snowGen:next()})

										if bolo then
											return finish({
												code = 200,
												message = "A BOLO has been created on '" .. RobloxUser.name .. "' in '" .. Guild.name .. "' successfully.",
												data = bolo
											})
										else
											return finish({
												code = 400,
												message = err
											})
										end
									else
										return finish({
											code = 404,
											message = "Roblox user '" .. username .. "' was not found."
										})
									end
								elseif Action == "bolos" and request.method == "POST" and ERLC_ADMIN then
									local BoloID = SubAction

									local RobloxUser = ropi.SearchUser(BoloID)

									if RobloxUser then
										local success, err, inGameBanned, inGameError = db:completeBOLO(RobloxUser, Member, config)

										if success then
											return finish({
												code = 200,
												message = "The BOLO on '" .. RobloxUser.name .. "' has been successfully marked as complete in " .. Guild.name .. "." .. ((inGameBanned and " They have also been banned form the in-game server.") or (inGameError and "An error occurred while attempting to ban '" .. RobloxUser.name .. "' from the in-game server. The BOLO has still been marked as completed. Error: '" .. inGameError .. "'"))
											})
										else
											return finish({
												code = 400,
												message = err
											})
										end
									else
										return finish({
											code = 404,
											message = "Roblox user '" .. BoloID .. "' was not found."
										})
									end
								elseif Action == "bolos" and request.method == "DELETE" and ERLC_ADMIN then
									local BoloID = SubAction

									local RobloxUser = ropi.SearchUser(BoloID)

									if RobloxUser then
										local success, err = db:denyBOLO(RobloxUser, Member, config)

										if success then
											return finish({
												code = 200,
												message = "The BOLO on '" .. RobloxUser.name .. "' has been successfully denied in " .. Guild.name .. "."
											})
										else
											return finish({
												code = 400,
												message = err
											})
										end
									else
										return finish({
											code = 404,
											message = "Roblox user '" .. BoloID .. "' was not found."
										})
									end
								elseif Action == "tempbans" and request.method == "POST" and ERLC_STAFF then
									local username = body.username
									local reason = body.reason
									local duration = body.duration
									local evidence = body.evidence

									if not config.apikey then
										return finish({
											code = 400,
											message = "An ERLC API key has not been configuered."
										})
									end

									if (not username) or (username == "") then
										return finish({
											code = 400,
											message = "Body field 'username' was not provided."
										})
									elseif (not reason) or (reason == "") then
										return finish({
											code = 400,
											message = "Body field 'reason' was not provided."
										})
									elseif (not duration) or (not tonumber(duration)) then
										return finish({
											code = 400,
											message = "Body field 'duration' was not provided or is invalid."
										})
									end

									duration = tonumber(duration)
									local expires = math.round(realtime() + duration)

									if (not config.tempbantimemods or not tonumber(config.tempbantimemods)) and (not ERLC_ADMIN) then
										return finish({
											code = 403,
											message = "Only staff with ERLC Admin permissions can tempban on this server."
										})
									end

									if not ERLC_ADMIN and config.tempbantimemods and tonumber(config.tempbantimemods) < duration then
										return finish({
											code = 403,
											message = "ERLC Staff can tempban for a maximum of " .. readable(duration, true) .. "."
										})
									end

									local player = ropi.SearchUser(username)

									if not player then
										return finish({
											code = 404,
											message = "Roblox user '" .. username .. "' was not found."
										})
									end

									config.erlctempbans = config.erlctempbans or {}

									if config.erlctempbans[tostring(player.id)] then
										return finish({
											code = 409,
											message = "Roblox user '" .. username .. "' already has an active tempban."
										})
									end

									local plus = sqldb:plusGuild(GuildID)
									local cmd = ":ban " .. tostring(player.id)

									local server, err = config.apikey and ERLC:getServer(config.apikey)
									if not server then
										return finish({
											code = 500,
											message = "The PRC API returned an error: " .. tostring(err)
										})
									end

									if plus and (#server.players <= 0) then
										local succ, err = db:commandQueueInsert(Guild)
										if table.count(config.erlccommandqueue) >= featureLimits.erlcCommandQueueLimit.plus then
											return finish({
												code = 409,
												message = "This server's ERLC Command Queue is full, and the ERLC server is offline."
											})
										else
											inqueue = true
										end
									else
										local server, err = ERLC:getServer(config.apikey)
										if not server then
											return finish({
												code = 401,
												message = err
											})
										end

										local succ, err = server:execute(cmd)
										if not succ then
											return finish({
												code = 500,
												message = err
											})
										end

									end

									config.erlctempbans[tostring(player.id)] = {
										expires = expires,
										userid = player.id
									}

									local saved = sqldb:set(GuildID, {
										erlctempbans = config.erlctempbans
									}, "ERLC_TEMPBAN_ADD")

									if not saved then
										return finish({
											code = 500,
											message = "Failed to save tempban to database."
										})
									end

									local punishment = db:punishmentCreate({
										id = snowGen:next()
									}, Member, player, "Tempban", reason, evidence, expires)

									if not punishment then
										return finish({
											code = 500,
											message = "Failed to save punishment, the player will still be unbanned when the tempban expires."
										})
									end

									return finish({
										code = 200,
										message = "A tempban for " .. readable(duration, true) .. " has been logged on '" .. player.name .. "' in '" .. Guild.name .. "' successfully." .. ((inqueue and "Since the ERLC server is offline, the player will be banned once the server is online.") or "")
									})
								elseif Action == "punishments" and request.method == "GET" and ERLC_STAFF then
									local player = headers and headers["player"]
									local moderator = headers and headers["moderator"]
									local punishments = table.deepcopy(config.punishments or {})
									local results = {}

									table.sort(punishments, function(a, b)
										return a.timestamp > b.timestamp
									end)

									if (type(player) == "string" and player ~= "") or (type(moderator) == "string" and moderator ~= "") then
										for _, punishment in pairs(punishments) do
											if tostring(punishment.player) == tostring(player) or tostring(punishment.moderator) == tostring(moderator) then
												punishment.player = ropi.GetUser(punishment.player) or {
													id = punishment.player,
													name = "Unknown"
												}
												punishment.moderator = Client:getUser(punishment.moderator) and DiscordUserObject(Client:getUser(punishment.moderator)) or {
													id = punishment.moderator,
													username = "Unknown"
												}
												table.insert(results, punishment)
											end
										end
									else
										local count = 0

										for _, punishment in pairs(punishments) do
											if count < 25 then
												punishment.player = ropi.GetUser(punishment.player) or {
													id = punishment.player,
													name = "Unknown"
												}
												punishment.moderator = Client:getUser(punishment.moderator) and DiscordUserObject(Client:getUser(punishment.moderator)) or {
													id = punishment.moderator,
													username = "Unknown"
												}
												table.insert(results, punishment)
												count = count + 1
											end
										end
									end

									return finish({
										code = 200,
										message = "Punishments for '" .. Guild.name .. "' fetched successfully.",
										data = {
											punishments = results
										}
									})
								elseif Action == "punishments" and request.method == "POST" and ERLC_STAFF then
									local username = body.username
									local pType = body.type
									local reason = body.reason
									local evidence = body.evidence
									local duration = (body.duration and tonumber(body.duration)) or nil
									local expires = duration and math.round(realtime() + duration)

									if (not username) or (username == "") then
										return finish({
											code = 400,
											message = "Body field 'username' was not provided."
										})
									elseif (not pType) or (pType == "") then
										return finish({
											code = 400,
											message = "Body field 'type' was not provided."
										})
									elseif (not reason) or (reason == "") then
										return finish({
											code = 400,
											message = "Body field 'reason' was not provided."
										})
									end

									local player = ropi.SearchUser(username)

									if player then
										local punishment = db:punishmentCreate({
											id = snowGen:next()
										}, Member, player, pType, reason, evidence, expires)

										return finish({
											code = 200,
											message = "A punishment has been logged on '" .. player.name .. "' in '" .. Guild.name .. "' successfully.",
											data = punishment
										})
									else
										return finish({
											code = 404,
											message = "Roblox user '" .. username .. "' was not found."
										})
									end
								elseif Action == "punishments" and request.method == "PATCH" and ERLC_STAFF then
									local PunishmentID = SubAction
									local newReason = body.reason

									if type(newReason) ~= "string" or newReason == "" then
										return finish({
											code = 400,
											message = "Body field 'reason' was not provided."
										})
									end

									for index, punishment in pairs(config.punishments) do
										if tonumber(punishment.id) == tonumber(PunishmentID) then
											if Member.id == punishment.moderator or ERLC_ADMIN then
												config.punishments[index].reason = newReason
												sqldb:set(GuildID, {
													punishments = config.punishments
												}, "PUNISHMENT_EDIT")

												return finish({
													code = 200,
													message = "Punishment '" .. PunishmentID .. "' has been successfully edited."
												})
											else
												return finish({
													code = 403,
													message = "You do not have permission to edit that punishment."
												})
											end
										end
									end

									return finish({
										code = 404,
										message = "That punishment was not found."
									})
								elseif Action == "punishments" and request.method == "DELETE" and ERLC_STAFF then
									local PunishmentID = SubAction

									for index, punishment in pairs(config.punishments) do
										if tonumber(punishment.id) == tonumber(PunishmentID) then
											if Member.id == punishment.moderator or ERLC_ADMIN then
												table.remove(config.punishments, index)
												sqldb:set(GuildID, {
													punishments = config.punishments
												}, "PUNISHMENT_DELETE")

												return finish({
													code = 200,
													message = "Punishment '" .. PunishmentID .. "' has been successfully deleted."
												})
											else
												return finish({
													code = 403,
													message = "You do not have permission to delete that punishment."
												})
											end
										end
									end

									return finish({
										code = 404,
										message = "That punishment was not found."
									})
								elseif Action == "shifts" and request.method == "GET" and ERLC_STAFF then
									return finish({
										code = 200,
										message = "Shifts for '" .. Guild.name .. "' fetched successfully.",
										data = config.shifts or {}
									})
								elseif Action == "shifts" and SubAction == "start" and request.method == "POST" and ERLC_STAFF then
									if not body or not body.type then
										return finish({
											code = 400,
											message = "Body field 'type' was not provided."
										})
									end

									local success, message = db:shiftStart({
										id = snowGen:next()
									}, Member, body and body.type)

									local shifts = {}

									if config.shifts then
										local availableTypes = {}

										for _, v in pairs(config.shifts.types or {}) do
											local shiftType = db:shiftType(Guild, v.name, Member)

											if shiftType then
												table.insert(availableTypes, shiftType)
											end
										end

										if next(availableTypes) then
											shifts.types = availableTypes

											local wave = db:shiftWave(Guild)

											if wave then
												shifts.me = {}

												local active, pause = db:shiftActive(Member)

												if active then
													shifts.me.active = active
													shifts.me.active.paused = pause
													shifts.me.active.elapsed, shifts.me.active.pausetime = db:shiftElapsed(Guild, active.id)
												end

												local history = db:shiftHistory(Member)

												if history then
													for i, v in pairs(history) do
														history[i].elapsed, history[i].pausetime = db:shiftElapsed(Guild, v.id)
													end

													shifts.me.history = history
												end
											end
										end
									end

									if success then
										return finish({
											code = 200,
											message = message,
											data = shifts
										})
									else
										return finish({
											code = 400,
											message = message
										})
									end
								elseif Action == "shifts" and SubAction == "pause" and request.method == "POST" and ERLC_STAFF then
									local success, message = db:shiftPause(Member)

									local shifts = {}

									if config.shifts then
										local availableTypes = {}

										for _, v in pairs(config.shifts.types or {}) do
											local shiftType = db:shiftType(Guild, v.name, Member)

											if shiftType then
												table.insert(availableTypes, shiftType)
											end
										end

										if next(availableTypes) then
											shifts.types = availableTypes

											local wave = db:shiftWave(Guild)

											if wave then
												shifts.me = {}

												local active, pause = db:shiftActive(Member)

												if active then
													shifts.me.active = active
													shifts.me.active.paused = pause
													shifts.me.active.elapsed, shifts.me.active.pausetime = db:shiftElapsed(Guild, active.id)
												end

												local history = db:shiftHistory(Member)

												if history then
													for i, v in pairs(history) do
														history[i].elapsed, history[i].pausetime = db:shiftElapsed(Guild, v.id)
													end

													shifts.me.history = history
												end
											end
										end
									end

									if success then
										return finish({
											code = 200,
											message = message,
											data = shifts
										})
									else
										return finish({
											code = 400,
											message = message
										})
									end
								elseif Action == "shifts" and SubAction == "end" and request.method == "POST" and ERLC_STAFF then
									local success, message = db:shiftEnd(Member)

									local shifts = {}

									if config.shifts then
										local availableTypes = {}

										for _, v in pairs(config.shifts.types or {}) do
											local shiftType = db:shiftType(Guild, v.name, Member)

											if shiftType then
												table.insert(availableTypes, shiftType)
											end
										end

										if next(availableTypes) then
											shifts.types = availableTypes

											local wave = db:shiftWave(Guild)

											if wave then
												shifts.me = {}

												local active, pause = db:shiftActive(Member)

												if active then
													shifts.me.active = active
													shifts.me.active.paused = pause
													shifts.me.active.elapsed, shifts.me.active.pausetime = db:shiftElapsed(Guild, active.id)
												end

												local history = db:shiftHistory(Member)

												if history then
													for i, v in pairs(history) do
														history[i].elapsed, history[i].pausetime = db:shiftElapsed(Guild, v.id)
													end

													shifts.me.history = history
												end
											end
										end
									end

									if success then
										return finish({
											code = 200,
											message = message,
											data = shifts
										})
									else
										return finish({
											code = 400,
											message = message
										})
									end
								elseif Action == "transcripts" and request.method == "GET" then
									local ChannelID = SubAction

									if (not ChannelID) or (ChannelID == "") or (not tonumber(ChannelID)) then
										return finish({
											code = 400,
											message = "An invalid ticket channel ID was provided."
										})
									end

									if (not config) or (not config.transcripts) then
										return finish({
											code = 404,
											message = "No ticket transcripts found."
										})
									end

									local transcript = config.transcripts[tostring(ChannelID)]

									if (not transcript) then
										return finish({
											code = 404,
											message = "The transcript for ticket channel '" .. ChannelID .. "' was not found."
										})
									end

									return finish({
										code = 200,
										message = "Transcript for ticket channel '" .. ChannelID .. "' fetched successfully.",
										data = transcript
									})
								elseif Action == "config" and request.method == "GET" and MANAGE_SERVER then
									local config = sqldb:get(GuildID) or {}

									if config.apikey or config.bloxlinkServerKey then
										config = table.deepcopy(config)
										config.apikey = nil
										config.bloxlinkServerKey = nil
									end

									return finish({
										code = 200,
										message = "The configuration for guild '" .. GuildID .. "' has been successfully fetched.",
										data = config
									})
								elseif Action == "modify" and request.method == "POST" and authorized then
									if type(body) ~= "table" or not next(body) then
										return finish({
											code = 400,
											message = "A body must be provided."
										})
									end

									local changes = body.changes

									if (type(changes) ~= "table") or (table.count(changes) <= 0) then
										return finish({
											code = 400,
											message = "Body field 'changes' was not provided or was empty."
										})
									end

									local success, err = sqldb:set(GuildID, changes, "API_CONFIG_MODIFY", Member)

									if success then
										return finish({
											code = 200,
											message = "The configuration for guild '" .. GuildID .. "' has been successfully updated."
										})
									else
										return finish({
											code = 500,
											message = "An internal database error occurred while attempting to modify the configuration for guild '" .. tostring(Guild.id) .. "': " .. tostring(err)
										})
									end
								elseif Action == "info" and request.method == "GET" and ERLC_STAFF then
									local guildInfo = getGuildInfo(GuildID, Member.id)

									if type(guildInfo) ~= "table" then
										return finish({
											code = 500,
											message = "An unknown error occurred. Please try again later."
										})
									end

									return finish({
										code = 200,
										message = "Successfully loaded info for guild '" .. GuildID .. "'.",
										data = guildInfo
									})
								else
									return finish({
										code = 403,
										message = "You do not have permission to use this action."
									})
								end
							else
								return finish({
									code = 404,
									message = "Guild '" .. GuildID .. "' was not found, or is inaccessible by Ducky."
								})
							end
						else
							local guilds = Caches.Guilds[DiscordID] and (os.time() - Caches.Guilds[DiscordID].fetched <= 60) and Caches.Guilds[DiscordID].data
							if not guilds then
								guilds = fetchMutualGuilds(result.discordToken, Client:getUser(DiscordID))
								Caches.Guilds[DiscordID] = {
									data = guilds,
									fetched = os.time()
								}
							end

							return finish({
								code = 200,
								message = "Guilds for '" .. DiscordID .. "' fetched successfully.",
								data = guilds
							})
						end
					else
						return finish({
							code = 500,
							message = tostring(result)
						})
					end
				end
			}
		}
	},
	["/plus"] = {
		additionalURLParameters = true,
		methods = {
			["GET"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local ID = parameters[1]

					if (not ID) or (ID == "") or (not tonumber(ID)) then
						return finish({
							code = 400,
							message = "An invalid Discord user ID was provided."
						})
					end

					local user = Client:getUser(ID)

					if not user then
						return finish({
							code = 404,
							message = "A Discord user with that ID was not found."
						})
					end

					local active, plus = sqldb:plusMember(user)

					return finish({
						code = 200,
						message = "Fetched subscription data successfully.",
						data = {
							active = active,
							plus = plus
						}
					})
				end
			}
		}
	},
	["/linked-roles"] = {
		additionalURLParameters = true,
		methods = {
			["POST"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local Action = (parameters[1] and parameters[1] ~= "" and parameters[1]) or nil

					if Action == "update" then
						local DiscordCode = headers and headers["discord-code"]

						if not DiscordCode or DiscordCode == "" then
							return finish({
								code = 400,
								message = "Header 'Discord-Code' was not provided."
							})
						end

						local redirectUri = headers["origin"] and headers["origin"] .. "/linked-roles"

						if not redirectUri then
							return finish({
								code = 400,
								message = "Invalid origin"
							})
						end

						local ok, err = updateLinkedRoleMetadata(DiscordCode, nil, redirectUri)

						if ok then
							return finish({
								code = 200,
								message = "Successfully updated linked roles metadata."
							})
						else
							return finish({
								code = 500,
								message = "Failed to update linked roles metadata: " .. tostring(err)
							})
						end
					elseif Action == "force-update" and authorized then
						local UserID = (parameters[2] and parameters[2] ~= "" and parameters[2]) or nil

						if type(UserID) ~= "string" then
							return finish({
								code = 400,
								message = "Invalid UserID provided."
							})
						end

						local ok, err = updateLinkedRoleMetadata(nil, UserID)

						if ok then
							return finish({
								code = 200,
								message = "Successfully updated linked roles metadata for '" .. UserID .. "'."
							})
						else
							return finish({
								code = 500,
								message = "Failed to update linked roles metadata: " .. tostring(err)
							})
						end
					else
						return finish({
							code = 403,
							message = "You do not have permission to perform that action."
						})
					end
				end
			}
		}
	},
	["/editor"] = {
		additionalURLParameters = true,
		methods = {
			["GET"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local code = parameters[1] and parameters[1] ~= "" and parameters[1] or nil

					if not code then
						return finish({
							code = 400,
							message = "An editor session code was not provided."
						})
					end

					local session = table.find(webEditorSessions or {}, function(s)
						return code == s.code
					end)

					if session then
						return finish({
							code = 200,
							message = "That editor session was found.",
							data = {
								guild = session.guild,
								author = session.author,
								type = session.type,
								created = session.created,
								expires = session.expires,
								plus = session.plus
							}
						})
					else
						return finish({
							code = 404,
							message = "An editor session with that code was not found."
						})
					end
				end
			},
			["POST"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local code = parameters[1] and parameters[1] ~= "" and parameters[1] or nil

					if not code then
						return finish({
							code = 400,
							message = "An editor session code was not provided."
						})
					end

					local session = table.find(webEditorSessions or {}, function(s)
						return code == s.code
					end)

					if session then
						if session.type == body.type then
							local success, message = session.callback(body.data)
							if success then
								for i, s in pairs(webEditorSessions) do
									if s.code == code then
										table.remove(webEditorSessions, i)
										break
									end
								end

								return finish({
									code = 200,
									message = message
								})
							else
								return finish({
									code = 400,
									message = tostring(message)
								})
							end
						else
							return finish({
								code = 400,
								message = "The provided data does not match the editor session type."
							})
						end
					else
						return finish({
							code = 404,
							message = "An editor session with that code was not found."
						})
					end
				end
			}
		}
	},
	["/erlc"] = {
		additionalURLParameters = true,
		methods = {
			["POST"] = {
				preserveBody = true,
				callback = function(request, response, headers, parameters, body, finish, authorized)
					local signature = headers and headers["x-signature-ed25519"]
					local timestamp = headers and headers["x-signature-timestamp"]
					if (not signature) or (not timestamp) then
						return finish({
							code = 401,
							message = "The webhook event was not signed properly."
						})
					end

					local success, code, message = ERLC:handleWebhook(body, signature, timestamp)
					return finish({
						code = code,
						message = message
					})
				end
			}
		}
	},
	["/vote"] = {
		methods = {
			["ANY"] = {
				callback = function(request, response, headers, parameters, body, finish, authorized)
					if (not headers) or (headers.authorization ~= SECRETS.TOP_GG_VOTE_AUTH) then
						return finish({
							code = 401,
							message = "This request is not signed by top.gg."
						})
					end

					local user = body.user and Client:getUser(body.user)
					if not user then
						return finish({
							code = 400,
							message = "The user ID provided is invalid."
						})
					end

					utilityChannels.supporters:send({
						content = "💛 " .. user.mentionString .. " has voted for " .. emojis.ducky .. " **Ducky** on [top.gg](https://top.gg/bot/" .. Client.user.id .. "/vote)!\n"
						.. "-# " .. emojis.right .. " Thank you for your support!"
					})

					return finish({
						code = 200,
						message = "The vote message has been sent to the supporters channel. Thank you for your support!"
					})
				end
			},
		}
	}
}

api.Start = function()
	connection = http.createServer(function(request, response)
		local success, err = pcall(coroutine.wrap(function()
			request.headers["X-Real-IP"] = request.headers["X-Real-IP"] or request.headers["X-Forwarded-For"]

			if not request.headers["X-Real-IP"] then
				request.headers["X-Real-IP"] = "IP Unknown"
			end

			logAPIUsage("Received " .. request.method .. " " .. request.url .. " from " .. (request.headers["X-Real-IP"]))
			DuckyAPI:emit("requestReceived", request)

			request.receivedAt = realtime()

			response:setHeader("Access-Control-Allow-Origin", "*")
			response:setHeader("Access-Control-Allow-Methods", "*")
			response:setHeader("Access-Control-Allow-Headers", "*")

			local function finish(result, raw)
				if not raw then
					response:setHeader("Content-Type", "application/json")
					response:writeHead(result.code)
					response:finish(json.encode(result))
				else
					response:setHeader("Content-Type", "text/plain")
					response:writeHead(200)
					response:finish(result)
				end

				logRequest(request, result.code)
			end

			local url = request.url
			local headers = {}
			local body = ""
			local authorized = requestAuthorized(request)

			for _, header in pairs(request.headers) do
				headers[header[1]:lower()] = header[2]
			end

			local endpoint = endpoints[url]
			local endpointName = (endpoint and url) or nil

			if not endpoint then
				for ep, epo in pairs(endpoints) do
					if (epo.additionalURLParameters == true) and (url:usub(1, ep:len()):lower() == ep:lower()) then
						endpoint = epo
						endpointName = ep
					end
				end
			end

			if endpoint and endpointName then
				local urlParameters = string.split(url:usub(endpointName:len() + 2), "/")

				if endpoint.methods[request.method] or endpoint.methods["ANY"] then
					if ((endpoint.methods[request.method] and endpoint.methods[request.method].requireAuthorization == true) or (endpoint.methods["ANY"] and endpoint.methods["ANY"].requireAuthorization == true)) and (not authorized) then
						return finish({
							code = 401,
							message = "Method " .. request.method .. " on endpoint " .. tostring(url) .. " requires authorization to access."
						})
					elseif request.method == "POST" or request.method == "PATCH" then
						request:on("data", function(chunk)
							body = body .. chunk
						end)

						return request:on("end", function()
							local _, finishedBody, _, error = nil, body, nil, nil

							if (not (endpoint.methods[request.method] and endpoint.methods[request.method].preserveBody)) and body:len() > 0 then
								_, finishedBody, _, error = pcall(json.decode, body)
							end

							if body:len() == 0 or not error then
								local cbSuccess, cbError = pcall(coroutine.wrap((endpoint.methods[request.method] and endpoint.methods[request.method].callback) or (endpoint.methods["ANY"] and endpoint.methods["ANY"].callback)), request, response, headers, urlParameters, finishedBody, finish, authorized)

								if not cbSuccess then
									Client:error("Ducky API encountered an error upon processing request " .. tostring(request.method) .. " " .. tostring(request.url) .. ":\n    " .. tostring(cbError))

									return finish({
										code = 500,
										message = "An internal error occurred while processing this request. Please try again later."
									})
								end
							else
								finish({
									code = 400,
									message = "Invalid JSON body provided: " .. error
								})
							end
						end)
					elseif request.method == "OPTIONS" then
						return finish({
							code = 204,
							message = "This request is good to go."
						})
					else
						local cbSuccess, cbError = pcall(coroutine.wrap((endpoint.methods[request.method] and endpoint.methods[request.method].callback) or (endpoint.methods["ANY"] and endpoint.methods["ANY"].callback)), request, response, headers, urlParameters, nil, finish, authorized)

						if not cbSuccess then
							Client:error("Ducky API encountered an error upon processing request " .. tostring(request.method) .. " " .. tostring(request.url) .. ":\n    " .. tostring(cbError))
							return finish({
								code = 500,
								message = "An internal error occurred while processing this request. Please try again later."
							})
						end
					end
				else
					return finish({
						code = 405,
						message = "Method " .. tostring(request.method) .. " is not supported on endpoint " .. tostring(url) .. "."
					})
				end
			else
				return finish({
					code = 404,
					message = "Endpoint " .. url .. " was not found."
				})
			end
		end))

		if not success then
			Client:error("Ducky API encountered an error upon processing request " .. tostring(request.method or "unknown method") .. " " .. tostring(request.url or "unknown url") .. ":\n    " .. tostring(err or "unknown error"))
		end
	end)

	connection:listen(port, host, function()
		logAPIUsage("Listening at https://api.duckybot.xyz/ globally and https://" .. host .. ":" .. port .. " locally.")
	end)
end

api.Stop = function()
	for event, listener in pairs(listeners) do
		DuckyAPI:removeListener(event, listener)
	end
	if connection then
		connection:close(function(...)
			logAPIUsage("The Ducky API has been successfully disconnected.")
		end)
	else
		logAPIUsage("No Ducky API connection was found.")
	end
	Caches.Team = {}
end

return api
