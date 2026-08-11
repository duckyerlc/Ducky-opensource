-- lua.lua
local pp = require("deps/pretty-print")

local function prettyLine(...)
	local ret = {}
	for i = 1, select('#', ...) do
		local arg = pp.strip(pp.dump(select(i, ...)))
		table.insert(ret, arg)
	end
	return table.concat(ret, '\t')
end

local function printLine(...)
	local ret = {}
	for i = 1, select('#', ...) do
		local arg = tostring(select(i, ...))
		table.insert(ret, arg)
	end
	return table.concat(ret, '\t')
end

local function code(str) return "```\n" .. str .. "```" end

local snowGen = snowflake.new(1, 3)

return {
	name = "lua",
	description = "Execute lua code.",
	aliases = {
		"luvit"
	},
	category = "Utility",
	slashCommand = nil,
	requiredPermissions = {
		"BOT_DEVELOPER"
	},
	callback = function(message, args)
		local toexec = table.concat(args, " ")
		local msg = message
		if toexec == "" or toexec == " " then return end

		toexec = toexec:gsub("[^\r\n\t%g ]", "")
		toexec = toexec:gsub("“", '"'):gsub("”", '"')
		toexec = toexec:match("^```%s*(.-)%s*```$") or toexec
		toexec = toexec:gsub("^```%a*\n", "")
		toexec = toexec:gsub("\n```$", "")
		toexec = toexec:match("^%s*(.-)%s*$")

		local lines = {}
		local sandbox = {}

		for key, val in pairs(_G) do sandbox[key] = val end

		sandbox.print = function(...) table.insert(lines, printLine(...)) end

		sandbox.p = function(...) table.insert(lines, prettyLine(...)) end

		sandbox.duckysPond = duckysPond
		sandbox.pond = duckysPond
		sandbox.message = msg
		sandbox.msg = msg
		sandbox.client = Client
		sandbox.me = message.member
		sandbox.member = message.member
		sandbox.user = message.user
		sandbox.ducky = message.guild.me
		sandbox.guild = message.guild
		sandbox.channel = message.channel
		sandbox._G = _G
		sandbox.args = args
		sandbox.dia = _G.discordia
		sandbox.discordia = _G.discordia
		sandbox.ropi = _G.ropi
		sandbox.db = _G.db
		sandbox.sqldb = sqldb
		sandbox.config = sqldb:get(message.guild.id) or {}
		sandbox.erlua = _G.erlua
		sandbox.ERLC = _G.ERLC
		sandbox.os = os
		sandbox.io = io
		sandbox.uv = uv
		sandbox.realtime = realtime
		sandbox.timer = _G.timer
		sandbox.coroutine = coroutine
		sandbox.math = math
		sandbox.json = _G.json
		sandbox.string = string
		sandbox.table = table
		sandbox.tostring = tostring
		sandbox.tonumber = tonumber
		sandbox.pairs = pairs
		sandbox.ipairs = ipairs
		sandbox.next = next
		sandbox.select = select
		sandbox.type = type
		sandbox.require = require
		sandbox.paginate = _G.paginate
		sandbox.emojis = _G.emojis
		sandbox.resolvedEmojis = _G.resolvedEmojis
		sandbox.prompt = _G.prompt
		sandbox.colors = _G.colors
		sandbox.junkStr = _G.junkStr
		sandbox.embedEditor = _G.embedEditor
		sandbox.messageEditor = _G.messageEditor
		sandbox.ask = _G.ask
		sandbox.convert = _G.convert
		sandbox.you = message.referencedMessage and message.referencedMessage.member
		sandbox.ref = message.referencedMessage
		sandbox.fs = _G.fs
		sandbox.querystring = _G.querystring
		sandbox.http = _G.http
		sandbox.readable = _G.readable
		sandbox.fetchBulkMessages = _G.fetchBulkMessages
		sandbox.getCommand = _G.getCommand
		sandbox.getModule = _G.getModule
		sandbox.commands = _G.commands
		sandbox.modules = _G.modules
		sandbox.confirm = _G.confirm
		sandbox.parseTable = _G.parseTable
		sandbox.updateActivity = _G.updateActivity
		sandbox.debug = _G.debug
		sandbox.badwords = _G.badwords
		sandbox.generatePhrase = _G.generatePhrase
		sandbox.shell = _G.shell
		sandbox.parseMessageLink = _G.parseMessageLink
		sandbox.sanitizeFileName = _G.sanitizeFileName
		sandbox.fetchSong = _G.fetchSong
		sandbox.durationReadable = _G.durationReadable
		sandbox.accentClean = _G.accentClean
		sandbox.transcribeAudio = _G.transcribeAudio
		sandbox.listen = _G.listen
		sandbox.resolveEmoji = _G.resolveEmoji
		sandbox.urlToImage = _G.urlToImage
		sandbox.intervalParse = _G.intervalParse
		sandbox.intervalNextRun = _G.intervalNextRun
		sandbox.redisplay = function()
			local data = sandbox.parseTable({
				content = sandbox.ref.content,
				embeds = sandbox.ref.embeds,
				components = sandbox.ref.components
			}, sandbox.emojis, ":", ":", nil, true)

			sandbox.channel:send({
				content = data.content,
				embeds = data.embeds,
				components = data.components
			})
			sandbox.message:delete()
			sandbox.console:delete()
		end
		sandbox.syncropi = function()
			local _, body = sandbox.http.request("GET", "https://raw.githubusercontent.com/NickIsADev/ropi/master/init.lua")
			sandbox.fs.writeFileSync("deps/ropi/init.lua", body)

			local _, body = sandbox.http.request("GET", "https://raw.githubusercontent.com/NickIsADev/ropi/master/package.lua")
			sandbox.fs.writeFileSync("deps/ropi/package.lua", body)
		end
		sandbox.syncerlua = function()
			local _, body = sandbox.http.request("GET", "https://raw.githubusercontent.com/NickIsADev/erlua/master/init.lua")
			sandbox.fs.writeFileSync("deps/erlua/init.lua", body)

			local _, body = sandbox.http.request("GET", "https://raw.githubusercontent.com/NickIsADev/erlua/master/package.lua")
			sandbox.fs.writeFileSync("deps/erlua/package.lua", body)
		end
		sandbox.syncquackscordia = function(path)
			if string.endswith(path, "lua") then
				local _, body = sandbox.http.request("GET", "https://raw.githubusercontent.com/DuckySupport/Quackscordia/master/" .. path)
				sandbox.fs.writeFileSync("deps/discordia/" .. path, body)
				sandbox.print("Synced deps/discordia/" .. path)
			else
				local folder = fs.readdirSync("deps/discordia/" .. path)

				for _, file in pairs(folder) do
					if string.endswith(file, "lua") then
						local _, body = sandbox.http.request("GET", "https://raw.githubusercontent.com/DuckySupport/Quackscordia/master/" .. path .. "/" .. file)
						sandbox.fs.writeFileSync("deps/discordia/" .. path .. "/" .. file, body)
						sandbox.print("Synced deps/discordia/" .. path .. "/" .. file)
					else
						local subfolder = fs.readdirSync("deps/discordia/" .. path .. "/" .. file)
						for _, subfile in pairs(subfolder) do
							local _, body = sandbox.http.request("GET", "https://raw.githubusercontent.com/DuckySupport/Quackscordia/master/" .. path .. "/" .. file .. "/" .. subfile)
							sandbox.fs.writeFileSync("deps/discordia/" .. path .. "/" .. file .. "/" .. subfile, body)
							sandbox.print("Synced deps/discordia/" .. path .. "/" .. file .. "/" .. subfile)
						end
					end
				end
			end
		end
		sandbox.allemojis = function()
			local messages = {}
			local message = ""

			local i = 0
			for name, emoji in pairs(emojis) do
				i = i + 1
				message = message .. emoji .. ", "

				if message:len() >= 1500 or i >= table.count(emojis) then
					table.insert(messages, message)
					message = ""
				end
			end

			for _, msg in pairs(messages) do
				sandbox.message:reply(msg)
			end
		end
		sandbox.deepreply = function(content)
			local ref = message.referencedMessage

			if ref then
				sandbox.console:delete()
				msg:delete()
				ref:reply(content, true, true)
			end
		end
		sandbox.updatestats = coroutine.wrap(function()
			local botlists = {
				{
					url = "https://top.gg/api/bots/" .. Client.user.id .. "/stats",
					headers = {
						{
							"Authorization",
							SECRETS.TOP_GG_API_KEY
						},
						{
							"Content-Type",
							"application/json"
						}
					},
					body = json.encode({
						server_count = #Client.guilds
					})
				},
				{
					url = "https://discordbotlist.com/api/v1/bots/" .. Client.user.id .. "/stats",
					headers = {
						{
							"Authorization",
							"Bot " .. SECRETS.DISCORD_BOT_LIST_API_KEY
						},
						{
							"Content-Type",
							"application/json"
						}
					},
					body = json.encode({
						guilds = #Client.guilds,
						users = getTotalUserCount()
					})
				},
				{
					url = "https://discord.bots.gg/api/v1/bots/" .. Client.user.id .. "/stats",
					headers = {
						{
							"Authorization",
							SECRETS.DISCORD_BOTS_GG_API_KEY
						},
						{
							"Content-Type",
							"application/json"
						}
					},
					body = json.encode({
						guildCount = #Client.guilds
					})
				}
			}

			for i, v in pairs(botlists) do local res, body = http.request("POST", v.url, v.headers, v.body, 5000) end

			updateActivity()
		end)
		sandbox.readlog = coroutine.wrap(function(lineCount)
			local filename = "discordia.log"
			lineCount = lineCount or 15
			local lines = {}

			if not fs.existsSync(filename) then return sandbox.print("File does not exist.") end

			local data, err = fs.readFileSync(filename)

			if not data then return sandbox.print("Error reading file: " .. err) end

			for line in data:gmatch("[^\r\n]+") do table.insert(lines, line) end

			local totalLines = #lines

			if totalLines <= lineCount then return sandbox.print(table.concat(lines, "\n")) end

			local lastLines = {}
			for i = totalLines - lineCount + 1, totalLines do table.insert(lastLines, lines[i]) end

			sandbox.print(table.concat(lastLines, "\n"))
		end)
		sandbox.guildDataSearch = coroutine.wrap(function(query)
			local function searchTable(tbl, target, path, results)
				path = path or ""
				results = results or {}

				for key, value in pairs(tbl) do
					local currentPath = path .. "[" .. tostring(key) .. "]"

					if type(key) == "string" and string.match(key, target) then
						table.insert(results, {
							location = currentPath,
							value = value
						})
					end

					if type(value) == "table" then
						searchTable(value, target, currentPath, results)
					elseif type(value) == "string" and string.match(value, target) then
						table.insert(results, {
							location = currentPath,
							value = value
						})
					end
				end

				return results
			end

			local fullResults = {}

			for guildId, config in pairs(sandbox.allConfigs or {}) do
				local results = searchTable(config, query)
				if #results > 0 then fullResults[guildId] = results end
			end

			if next(fullResults) then
				sandbox.print(fullResults)
			else
				sandbox.print("No matches found for: " .. query)
			end
		end)
		sandbox.iatest = function(cb)
			local r = message:reply({
				components = discordia.Components():button({
					id = "test",
					emoji = resolvedEmojis.settings,
					style = "secondary"
				}):raw()
			})

			onComp(r, "button", "test", message.user.id, false, cb)
		end
		sandbox.getUserFromUsername = function(username) for _, u in pairs(Client.users) do if u.username == username then return u end end end
		sandbox.fetchPunishmentsFromERM = function(key)
			sandbox.print("Preparing for awesomeness...")

			loadMembers(message.guild)
			local config = sqldb:get(message.guild.id) or {}

			sandbox.print("Fetching punishments from ERM...")

			local result, response = http.request("GET", "https://core.ermbot.xyz/api/v1/moderations", {
				{
					"Authorization",
					key
				},
				{
					"Guild",
					message.guild.id
				}
			})
			response = response and json.decode(response)

			if result.code == 200 and response and response.data then
				local punishments = response.data
				local cc = 0

				for _, pun in pairs(punishments) do
					local playerID = pun.user_id
					local punishmentType = pun.type_
					local reason = pun.reason
					local moderator = pun.moderator
					if (not playerID) then
						sandbox.print("\n\nFailed to bring punishment from ERM as value 'user_id' was unavailable.")
						sandbox.p(pun, playerID)
					elseif (not punishmentType) then
						sandbox.print("\n\nFailed to bring punishment from ERM as value 'type_' was unavailable.")
						sandbox.p(pun)
					elseif (not reason) then
						sandbox.print("\n\nFailed to bring punishment from ERM as value 'reason' was unavailable.")
						sandbox.p(pun)
					elseif (not moderator) then
						sandbox.print("\n\nFailed to bring punishment from ERM as value moderator was unavailable.")
						sandbox.p(pun, moderator)
					else
						math.randomseed(os.time() + math.floor(math.random() * 10000))

						local newPunishment = {
							player = playerID,
							type = punishmentType,
							reason = reason or "No reason provided.",
							moderator = moderator,
							id = snowGen:next(),
							timestamp = os.time()
						}

						config.punishments = config.punishments or {}
						table.insert(sandbox.config.punishments, newPunishment)

						cc = cc + 1
						sandbox.print("")
					end
				end

				sqldb:set(message.guild.id, {punishments = config.punishments}, "TRANSFER_FROM_ERM")

				sandbox.print(cc .. "/" .. table.count(punishments) .. " punishments were successfully fetched and cloned.")
			elseif response and response.status and response.error_code and response.message then
				sandbox.print("ERM API returned " .. tostring(response.code) .. " " .. tostring(response.error_code) .. " | " .. tostring(response.message))
			else
				sandbox.print("ERM API returned an invalid response.")
				sandbox.p(response)
			end
		end
		sandbox.plusSync = function()
			-- Remove
			local removeCount = 0

			for _, member in pairs(duckysPond:getRole("1267239172444262490").members:toArray()) do
				if member and member.id then
					if not sqldb:plusMember(member) then
						member:removeRole("1267239172444262490", "Ducky Plus+ role synchronization")
						removeCount = removeCount + 1
					end
				end
			end

			-- Add
			local addCount = 0

			for _, member in pairs(duckysPond.members) do
				if member and member.id then
					if sqldb:plusMember(member) and not member:hasRole("1267239172444262490") then
						member:addRole("1267239172444262490", "Ducky Plus+ role synchronization")
						addCount = addCount + 1
					end
				end
			end

			sandbox.print("Removed: " .. removeCount)
			sandbox.print("Added: " .. addCount)
		end
		sandbox.duckyad = function(guildId, channelId, messageId, authorName, authorIcon, emojiId)
			local targetguild = Client:getGuild(guildId)

			if not targetguild then return sandbox.print("Guild not found.") end

			local targetchannel = targetguild:getChannel(channelId)

			if not targetchannel then return sandbox.print("Channel not found.") end

			local targetmessage = targetchannel:getMessage(messageId)

			if messageId ~= "" and not targetmessage then return sandbox.print("Message not found.") end

			local emoji = targetguild:getEmoji(emojiId)

			if not emoji then return sandbox.print("Emoji not found.") end

			local tosend = {
				embed = {
					author = {
						name = authorName .. " & Ducky",
						icon_url = authorIcon
					},
					description = "# " .. emojis.ducky .. " Ducky\n" .. emojis.right .. "*Power your server with " .. emojis.ducky .. " **Ducky**, a multipurpose bot focused on seamlessly integrating Discord and ERLC server automation for effortless management.*\n\n" .. "### " .. emojis.inspiration .. " Key Features\n" .. emojis.automation .. " **Automations**\n" .. emojis.right .. "Seamless ERLC automation with over 30+ triggers, actions, and conditions for effortless management.\n\n" .. emojis.permission .. " **Staff Management**\n" .. emojis.right .. "Manage your staff team with ease using infractions, promotions, LOAs, feedback, and more.\n\n" .. emojis.developer .. " **Multipurpose**\n" .. emojis.right ..
									"Features for every server, such as Discord Moderation, Roblox Verification, Reaction Boards, and more.\n\n" .. "*❤️ Thank you, **" .. emoji.mentionString .. " " .. authorName .. "**, for choosing " .. emojis.ducky .. " **Ducky***.",
					color = colors.yellow,
					image = {
						url = "https://duckybot.xyz/images/banners/footers/Ducky.png"
					}
				},
				components = discordia.Components():button({
					url = "https://discord.gg/w2dNr7vuKP",
					style = "link",
					label = "Ducky's Pond",
					emoji = resolvedEmojis.ducky
				}):button({
					url = "https://discord.com/oauth2/authorize?client_id=" .. Client.user.id,
					style = "link",
					label = "Add Ducky",
					emoji = resolvedEmojis.link
				}):raw()
			}

			if targetmessage then
				local succ, err = targetmessage:update(tosend)

				if succ then
					sandbox.print("Updated target message in " .. targetguild.name .. " -> " .. targetchannel.name .. ".")
				else
					sandbox.print(err)
				end
			else
				local succ, err = targetchannel:send(tosend)

				if succ then
					sandbox.print("Sent in " .. targetguild.name .. " -> " .. targetchannel.name .. ".")
				else
					sandbox.print(err)
				end
			end
		end
		sandbox.sendadwithinvite = function(guildId, guildDisplayName, invite, emojiId, targetChannnelId, messageId)
			local guild = Client:getGuild(guildId)

			if not guild then return sandbox.print("Guild not found.") end

			local emoji = guild:getEmoji(emojiId)

			if not emoji then return sandbox.print("Emoji not found.") end

			local targetChannnel = duckysPond:getChannel(targetChannnelId)

			local message = messageId and targetChannnel:getMessage(messageId)

			if messageId and not message then return sandbox.print("Message not found.") end

			local tosend = {
				embed = sandbox.ref.embeds[1],
				components = discordia.Components():button({
					url = "https://discord.gg/" .. invite,
					style = "link",
					label = guildDisplayName,
					emoji = _G.resolveEmoji(emoji.mentionString)
				}):raw()
			}

			if message then
				local succ, err = message:update(tosend)
				if succ then
					sandbox.print("Updated message for " .. guild.name .. ".")
				else
					sandbox.print(err)
				end
			else
				local succ, err = targetChannnel:send(tosend)
				if succ then
					sandbox.print("Sent message for " .. guild.name .. ".")
				else
					sandbox.print(err)
				end
			end
		end
		sandbox.generatevarsembed = function(keys)
			local description = ""
			local thumbnail_url = nil

			for k, v in pairs(keys) do
				if k:find("%.avatar$") then
					if v and v ~= "" then
						thumbnail_url = v
					end
				else
					description = description .. emojis.right .. " **" .. k .. "** " .. emojis.dot .. " {" .. k .. "}\n"
				end
			end

			local tbl = {
				description = description,
				thumbnail = thumbnail_url and { url = thumbnail_url } or nil
			}

			local success, err = export(tbl, message.user, "embed")
			if success then
				sandbox.print(success)
			else
				sandbox.print(err)
			end
		end

		local response = message:reply({
			embed = {
				description = emojis.loading .. " The following code is being executed...\n```lua\n" .. toexec .. "```",
				color = colors.blank,
				author = {
					name = message.member.name,
					icon_url = message.member.avatarURL
				}
			}
		})

		sandbox.console = response
		sandbox.response = response

		local startExecution = realtime()

		p("executing", toexec)
		local fn, syntaxError = load(toexec, 'Ducky', 't', sandbox)
		if not fn then
			if response then
				response:update({
					embed = {
						description = emojis.warning .. " A syntax error occurred while running this code.",
						fields = {
							{
								name = "Code:",
								value = ">>> ```lua\n" .. toexec .. "```"
							},
							{
								name = "Runtime Error:",
								value = ">>> ```" .. syntaxError .. "```"
							}
						},
						color = colors.warning,
						author = {
							name = message.member.name,
							icon_url = message.member.avatarURL
						}
					}
				})
			end

			return
		end

		local success, runtimeError = pcall(fn)
		if not success then
			if response then
				response:update({
					embed = {
						description = emojis.error .. " A runtime error occurred while running this code.",
						fields = {
							{
								name = "Code:",
								value = ">>> ```lua\n" .. toexec .. "```"
							},
							{
								name = "Runtime Error:",
								value = ">>> ```" .. runtimeError .. "```"
							}
						},
						color = colors.error,
						author = {
							name = message.member.name,
							icon_url = message.member.avatarURL
						}
					}
				})
			end

			return
		end

		local executedIn = readable(tostring(math.round(realtime() - startExecution, 3)))
		local tosendlines = table.concat(lines, '\n')
		local sendasfile = tosendlines:len() > 1900

		if not (message and message.content) then return end

		if #lines ~= 0 then
			if sendasfile then
				if response then
					response:update({
						embed = {
							description = emojis.success .. " This code has been successfully executed in **" .. executedIn .. "**.\n-# " .. emojis.list .. " Output (" .. #lines .. " lines, " .. tosendlines:len() .. " characters):",
							color = colors.success,
							author = {
								name = message.member.name,
								icon_url = message.member.avatarURL
							}
						}
					})
				end

				return message.channel:send({
					files = {
						{
							"output.txt",
							tosendlines
						}
					}
				})
			else
				if response then
					response:update({
						embed = {
							description = emojis.success .. " This code has been successfully executed in **" .. executedIn .. "**.\n-# " .. emojis.list .. " Output (" .. #lines .. " lines, " .. tosendlines:len() .. " characters):\n```\n" .. tosendlines .. "```",
							color = colors.success,
							author = {
								name = message.member.name,
								icon_url = message.member.avatarURL
							}
						}
					})
				end

				return
			end
		else
			if response then
				response:update({
					embed = {
						description = emojis.success .. " This code has been successfully executed in **" .. executedIn .. "**.",
						color = colors.success,
						author = {
							name = message.member.name,
							icon_url = message.member.avatarURL
						}
					}
				})
			end

			return
		end
	end
}
