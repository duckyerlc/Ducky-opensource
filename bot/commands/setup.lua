-- setup.lua
local slashCommand = tools.slashCommand("setup", "Setup/configure Ducky for your server's needs.")
slashCommand = slashCommand:addOption(tools.string("page", "Give a page to directly teleport to."):setRequired(false):setAutocomplete(true))
local function question(intr, q, ph, cb, style, min, max, required)
	return ask(intr, q, ph, nil, nil, style, required, nil, cb, min, max)
end

local snowGen = snowflake.new(1, 5)

-- [[ Subject Builder ]]--

local subjectBuilderComps = discordia.Components()

local editSubjectSelect = discordia.SelectMenu({
	id = "editproperty",
	min_values = 1,
	max_values = 1,
	actionRow = 1,
	placeholder = "Edit subject...",
	options = {
		{
			label = "Edit Name",
			value = "name",
			emoji = resolvedEmojis.text
		},
		{
			label = "Edit Description",
			value = "description",
			emoji = resolvedEmojis.text
		},
		{
			label = "Edit Emoji",
			value = "emoji",
			emoji = resolvedEmojis.emoji
		},
		{
			label = "Edit Category",
			value = "category",
			emoji = resolvedEmojis.folder
		},
		{
			label = "Edit Transcripts Channel",
			value = "transcriptschannel",
			emoji = resolvedEmojis.document
		},
		{
			label = "Edit Unclaimed Ticket Name",
			value = "ticketname",
			emoji = resolvedEmojis.ticket
		},
		{
			label = "Edit Claimed Ticket Name",
			value = "claimedticketname",
			emoji = resolvedEmojis.ticket
		},
		{
			label = "Edit Ticket Claim Mode",
			value = "ticketclaimmode",
			emoji = resolvedEmojis.edit
		},
		{
			label = "Add Form Question",
			value = "addformquestion",
			emoji = resolvedEmojis.draft
		},
		{
			label = "Remove Form Question",
			value = "removeformquestion",
			emoji = resolvedEmojis.draft
		},
		{
			label = "Edit Support Roles",
			value = "support",
			emoji = resolvedEmojis.support
		},
		{
			label = "Edit Mentionables",
			value = "mentionables",
			emoji = resolvedEmojis.pings
		},
		{
			label = "Edit Blacklisted Roles",
			value = "blacklistedroles",
			emoji = resolvedEmojis.nowhite
		},
		{
			label = "Edit Open Embeds",
			value = "openembed",
			emoji = resolvedEmojis.art
		},
		{
			label = "Edit Close Embeds",
			value = "closeembed",
			emoji = resolvedEmojis.art
		},
		{
			label = "Edit Claim Embeds",
			value = "claimembed",
			emoji = resolvedEmojis.art
		},
		{
			label = "Edit Unclaim Embeds",
			value = "unclaimembed",
			emoji = resolvedEmojis.art
		},
		{
			label = "Edit Close Request Embeds",
			value = "requestembed",
			emoji = resolvedEmojis.art
		},
		{
			label = "View Variables",
			value = "variables",
			emoji = resolvedEmojis.json
		}
	}
})

subjectBuilderComps:selectMenu(editSubjectSelect)

local finishSubjectButton = discordia.Button({
	id = "finish",
	label = "Finish",
	style = "success",
	emoji = resolvedEmojis.yeswhite,
	actionRow = 2
})

subjectBuilderComps:button(finishSubjectButton)

local cancelSubjectButton = discordia.Button({
	id = "cancel",
	label = "Cancel",
	style = "danger",
	emoji = resolvedEmojis.nowhite,
	actionRow = 2
})

subjectBuilderComps:button(cancelSubjectButton)

local allPages = {
	welcome = {
		name = "Welcome to Ducky",
		value = "Welcome to Ducky",
		number = 1
	},
	dcmod = {
		name = "Discord Moderation",
		value = "Discord Moderation",
		number = 2
	},
	audit = {
		name = "Audit Logging",
		value = "Audit Logging",
		number = 3
	},
	erlc = {
		name = "ERLC Integration",
		value = "ERLC Integration",
		number = 4
	},
	erlcRegions = {
		name = "ERLC Regions",
		value = "ERLC Regions",
		number = 5
	},
	erlcStatus = {
		name = "ERLC Server Status",
		value = "ERLC Server Status",
		number = 6
	},
	erlcLog = {
		name = "ERLC Server Logs",
		value = "ERLC Server Logs",
		number = 7
	},
	discordStatistics = {
		name = "Discord Server Statistics",
		value = "Discord Server Statistics",
		number = 8
	},
	join = {
		name = "Welcome/Autoroles",
		value = "Welcome/Autoroles",
		number = 9
	},
	sessions = {
		name = "Sessions",
		value = "Sessions",
		number = 10
	},
	staff = {
		name = "Staff Management",
		value = "Staff Management",
		number = 11
	},
	punish = {
		name = "Roblox Punishments",
		value = "Roblox Punishments",
		number = 12
	},
	verify = {
		name = "Roblox Verification",
		value = "Roblox Verification",
		number = 13
	},
	pings = {
		name = "Discord Pings",
		value = "Discord Pings",
		number = 14
	},
	suggestions = {
		name = "Suggestions",
		value = "Suggestions",
		number = 15
	},
	shift = {
		name = "Shift Management",
		value = "Shift Management",
		number = 16
	},
	activity = {
		name = "Activity Management",
		value = "Activity Management",
		number = 17
	},
	economy = {
		name = "Server Economy",
		value = "Server Economy",
		number = 18
	},
	tickets = {
		name = "Tickets",
		value = "Tickets",
		number = 19
	},
	responders = {
		name = "Autoresponders",
		value = "Autoresponders",
		number = 20
	},
	giveaways = {
		name = "Giveaways",
		value = "Giveaways",
		number = 21
	},
	boards = {
		name = "Reaction Boards",
		value = "Reaction Boards",
		number = 22
	},
	messages = {
		name = "Message Management",
		value = "Message Management",
		number = 23
	},
	departments = {
		name = "Departments",
		value = "Departments",
		number = 24
	}
}

--------------------------------------------------------

return {
	name = "setup",
	description = "Setup/configure Ducky for your server's needs.",
	aliases = {
		"config",
		"cfg",
		"configure",
		"configuration",
		"settings"
	},
	category = "Configuration",
	slashCommand = slashCommand,
	requiredPermissions = {
		"MANAGE_SERVER"
	},
	autocomplete = function(interaction, command, focused, args)
		local opts = {}

		if focused and focused.name == "page" then
			local sortedPages = {}

			for _, page in pairs(allPages) do
				if (focused.value and page.name:lower():find(focused.value:lower())) or (not focused.value) or (focused.value == "") then
					table.insert(sortedPages, page)
				end
			end

			table.sort(sortedPages, function(a, b)
				return a.number < b.number
			end)

			opts = sortedPages
		end

		return interaction:autocomplete(opts)
	end,
	hybridCallback = function(interaction, args, slash)
		if interaction.replyDeferred then
			interaction:replyDeferred()
		end

		local pages = {}

		local pagination, updatePagination = nil, nil

		local succ, config = sqldb:registerGuild(interaction.guild.id)

		if not succ then
			return interaction:fail("Failed to initialize configuration for your server. Please try again, and contact [Ducky Support](https://discord.gg/j4w5ZcbRyh) if this error persists.", nil, true)
		end

		local isPlusGuild = sqldb:plusGuild(interaction.guild)

		local function modifyKey(key, val)
			if val == nil then
				val = "nil"
			end

			local succ, c = sqldb:set(interaction.guild.id, {
				[key] = val
			}, "SETUP_MODIFY_" .. string.upper(tostring(key)), interaction.member)
			if succ then
				config = c
				return true, c
			end
		end

		local function insertInto(key, val)
			local existing = (config[key] and table.deepcopy(config[key])) or {}
			table.insert(existing, val)
			return modifyKey(key, existing)
		end

		local function setValue(tbl, key, val)
			local existing = (config[tbl] and table.deepcopy(config[tbl])) or {}
			existing[key] = val
			return modifyKey(tbl, existing)
		end

		local function removeFrom(key, val, deepval, index)
			local existing = (config[key] and table.deepcopy(config[key])) or {}
			for i, v in pairs(existing) do
				if (v == val) or ((deepval) and v[deepval] and v[deepval] == val) or (index and tonumber(val) and i == tonumber(val)) then
					table.remove(existing, i)
					return modifyKey(key, existing)
				end
			end

			return false
		end

		local function getAuditName(value)
			for i, v in pairs(auditTypes) do
				if v.value:lower() == value:lower() then
					return emojis.space .. emojis.right .. " " .. v.emoji.raw .. " " .. v.label
				end
			end
			return ""
		end

		local function getAuditString()
			local str = ""

			for _, v in pairs(config.audittypes or {}) do
				local channelId = config.auditlogchannels and config.auditlogchannels[v] and config.auditlogchannels[v].channel
				local channelDisplay = channelId and (" ( <#" .. channelId .. "> )") or ""
				str = str .. getAuditName(v) .. channelDisplay .. "\n"
			end

			return str
		end

		local function demoteEnabled(demoteType)
			local demotetypes = config.erlcdemotetypes
			for _, t in pairs(demotetypes or {}) do
				if t == demoteType then
					return true
				end
			end

			return false
		end

		local appealOptions = {
			{
				label = "Warning",
				value = "warning",
				description = "The appeal link for warnings with Ducky.",
				emoji = resolvedEmojis.warning
			},
			{
				label = "Mute",
				value = "mute",
				description = "The appeal link for time-outs with Ducky.",
				emoji = resolvedEmojis.timeout
			},
			{
				label = "Ban",
				value = "ban",
				description = "The appeal link for bans with Ducky.",
				emoji = resolvedEmojis.ban
			}
		}

		local banSyncingOptions = {
			{
				label = "Discord to ERLC",
				value = "dctoerlc",
				description = "Users banned in Discord will be banned in ERLC.",
				emoji = resolvedEmojis.game
			},
			{
				label = "ERLC to Discord",
				value = "erlctodc",
				description = "Users banned in ERLC will be banned in Discord.",
				emoji = resolvedEmojis.discordStaff
			},
			{
				label = "Both",
				value = "both",
				description = "Users will be banned in both directions.",
				emoji = resolvedEmojis.link
			},
			{
				label = "Disable",
				value = "disable",
				description = "Disable Ban Syncing.",
				emoji = resolvedEmojis.ban
			}
		}

		local ActionOptions = {
			{
				label = "View Variables",
				value = "vars",
				description = "View the available variables.",
				emoji = resolvedEmojis.json
			},
			{
				label = "Send a Message",
				value = "sendmsg",
				description = "Send a message/embed to a channel.",
				emoji = resolvedEmojis.chat
			},
			{
				label = "Send a Command",
				value = "sendcmd",
				description = "Send a command to your in-game server.",
				emoji = resolvedEmojis.settings
			},
			{
				label = "Delay",
				value = "delay",
				description = "Wait the specified amount of seconds before continuing.",
				emoji = resolvedEmojis.clock
			}
			-- {
			-- 	label = "Send a DM",
			-- 	value = "senddm",
			-- 	description = "Send a message/embed in direct messages to someone.",
			-- 	emoji = resolvedEmojis.mail
			-- }
		}

		----------------------------------------------------------------------------------------------

		local basicActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Edit Prefix",
					value = "prefix",
					emoji = resolvedEmojis.text
				},
				{
					label = "Edit Disabled Commands",
					value = "disabledcommands",
					emoji = resolvedEmojis.settings
				},
				{
					label = "Edit Command Blacklists",
					value = "commandblacklists",
					emoji = resolvedEmojis.settings
				},
				{
					label = "Edit Permissions",
					value = "editpermissions",
					emoji = resolvedEmojis.lock
				},
				{
					label = "Edit Config Log Channel",
					value = "configlogchannel",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Edit Command Logs Channel",
					value = "commandlogschannel",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Wipe Configuration",
					value = "wipeconfiguration",
					emoji = resolvedEmojis.delete
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local discordModerationActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Edit Modlogs Channel",
					value = "modlogchannel",
					emoji = resolvedEmojis.document
				},
				{
					label = "Edit Appeal Links",
					value = "appealLinks",
					emoji = resolvedEmojis.link
				},
				{
					label = "Toggle Staff Immunity",
					value = "discordstaffimmunity",
					emoji = resolvedEmojis.protect
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local auditLogActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Edit Primary Audit Logs Channel",
					value = "primaryauditlogchannel",
					emoji = resolvedEmojis.log
				},
				{
					label = "Edit Audit Log Channels",
					value = "auditlogchannels",
					emoji = resolvedEmojis.log
				},
				{
					label = "Edit Audit Log Types",
					value = "audittypes",
					emoji = resolvedEmojis.edit
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local erlcActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Edit In-Game Role",
					value = "ingamerole",
					emoji = resolvedEmojis.link
				},
				{
					label = "Edit ERLC API Key",
					value = "apikey",
					emoji = resolvedEmojis.key
				},
				{
					label = "Toggle Advanced Remote Execution Permissions",
					value = "advancederlccmdperms",
					emoji = resolvedEmojis.contributor
				},
				{
					label = "Edit Command Logs Channel",
					value = "erlccmdschannel",
					emoji = resolvedEmojis.channel
				},
				{
					label = "Edit Kick/Ban Logs Channel",
					value = "erlckickbanchannel",
					emoji = resolvedEmojis.channel
				},
				{
					label = "Toggle Auto Log Kicks/BOLOs",
					value = "erlcautologkickbolo",
					emoji = resolvedEmojis.log
				},
				{
					label = "Edit Ban Syncing Mode",
					value = "erlcbansync",
					emoji = resolvedEmojis.ban
				},
				{
					label = "Add Playtime Reward",
					value = "addplaytimereward",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Remove Playtime Reward",
					value = "removeplaytimereward",
					emoji = resolvedEmojis.minus
				},
				{
					label = "Edit Reward Announcements Channel",
					value = "playtimechannel",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Edit Reward Announcement Message",
					value = "playtimemessage",
					emoji = resolvedEmojis.edit
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local erlcRegionsActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Create Region",
					value = "createregion",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Delete Region",
					value = "deleteregion",
					emoji = resolvedEmojis.delete
				},
				{
					label = "Link Voice Channel",
					value = "linkvc",
					emoji = resolvedEmojis.link
				},
				{
					label = "Unlink Voice Channel",
					value = "unlinkvc",
					emoji = resolvedEmojis.unlink
				},
				{
					label = "Edit Waiting Voice Channel",
					value = "regionwaitingvc",
					emoji = resolvedEmojis.edit
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local erlcStatusActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Variables",
					value = "erlcserverstatusvars",
					emoji = resolvedEmojis.json
				},
				{
					label = "Edit Server Status Message",
					value = "statusmessage",
					emoji = resolvedEmojis.chat
				},
				{
					label = "Create Server Status Channel",
					value = "createstatuschannel",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Edit Server Status Channel",
					value = "editstatuschannel",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Remove Server Status Channel",
					value = "removestatuschannel",
					emoji = resolvedEmojis.delete
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local discordStatisticsActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Create Statistics Channel",
					value = "createstatisticschannel",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Edit Statistics Channel",
					value = "editstatisticschannel",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Remove Statistics Channel",
					value = "removestatisticschannel",
					emoji = resolvedEmojis.delete
				},
				{
					label = "Variables",
					value = "discordserverstatisticsvars",
					emoji = resolvedEmojis.json
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local erlcLogActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Edit Player Join Log",
					value = "playerjoin",
					emoji = resolvedEmojis.add
				},
				{
					label = "Edit Player Leave Log",
					value = "playerleave",
					emoji = resolvedEmojis.subtract
				},
				{
					label = "Edit Player Team Log",
					value = "playerteam",
					emoji = resolvedEmojis.flag
				},
				{
					label = "Edit Player Kill Log",
					value = "playerkill",
					emoji = resolvedEmojis.swords
				},
				{
					label = "Edit Modcall Log",
					value = "modcall",
					emoji = resolvedEmojis.modcall
				},
				(hasPermission(interaction.member, "BOT_DEVELOPER") and {
					label = "Edit Guild Cycle Notify Channel",
					value = "guildcyclednotifychannel",
					emoji = resolvedEmojis.channel
				}) or nil
			}
		})

		----------------------------------------------------------------------------------------------

		local joinActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Edit Autoroles",
					value = "joinroles",
					emoji = resolvedEmojis.role
				},
				{
					label = "Edit Welcome Channel",
					value = "joinchannel",
					emoji = resolvedEmojis.wave
				},
				{
					label = "Edit Welcome Message",
					value = "joinmessage",
					emoji = resolvedEmojis.chat
				},
				{
					label = "Edit Welcome Message Delete Delay",
					value = "joinmessagedelete",
					emoji = resolvedEmojis.clock
				},
				{
					label = "Test Welcome Message",
					value = "testjm",
					emoji = resolvedEmojis.support
				},
				{
					label = "Toggle DM Member",
					value = "toggledmjoin",
					emoji = resolvedEmojis.member
				},
				{
					label = "Edit DM Welcome Message",
					value = "dmjoinmessage",
					emoji = resolvedEmojis.chat
				},
				{
					label = "Edit Joingate Threshold",
					value = "joingatethreshold",
					emoji = resolvedEmojis.reminder
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local sessionActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Edit Sessions Channel",
					value = "sessionschannel",
					emoji = resolvedEmojis.channel
				},
				{
					label = "Edit Session Mentionables",
					value = "sessionmentionables",
					emoji = resolvedEmojis.pings
				},
				{
					label = "Toggle Ping Here",
					value = "sessionspinghere",
					emoji = resolvedEmojis.pings
				},
				{
					label = "Toggle Ping Everyone",
					value = "sessionspingeveryone",
					emoji = resolvedEmojis.role
				},
				{
					label = "Edit Server Information",
					value = "serverinformation",
					emoji = resolvedEmojis.game
				},
				{
					label = "Edit SSU Embeds",
					value = "ssuembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit Vote Embeds",
					value = "voteembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit Staff Vote Embeds",
					value = "staffvoteembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit SSD Embeds",
					value = "ssdembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit Low Embeds",
					value = "lowembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit Full Embeds",
					value = "fullembeds",
					emoji = resolvedEmojis.art
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local staffManagementActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Edit Infractions Channel",
					value = "infractionschannel",
					emoji = resolvedEmojis.channel
				},
				{
					label = "Edit Promotions Channel",
					value = "promotionschannel",
					emoji = resolvedEmojis.channel
				},
				{
					label = "Edit Feedback Channel",
					value = "feedbackchannel",
					emoji = resolvedEmojis.channel
				},
				{
					label = "Edit Infraction Thread",
					value = "editinfractionthread",
					emoji = resolvedEmojis.thread
				},
				{
					label = "Edit Promotion Thread",
					value = "editpromotionsthread",
					emoji = resolvedEmojis.thread
				},
				{
					label = "Create Infraction Type",
					value = "addtype",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Edit Infraction Type",
					value = "edittype",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Remove Infraction Type",
					value = "removetype",
					emoji = resolvedEmojis.minus
				},
				{
					label = "Edit Promotion Embeds",
					value = "promotionembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit Feedback Embeds",
					value = "feedbackembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit Infraction Issue Embeds",
					value = "infractionembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit Infraction Revoke Embeds",
					value = "infractionrevokeembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit Infraction Expire Embeds",
					value = "infractionexpireembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit Infraction Edit Embeds",
					value = "infractioneditembeds",
					emoji = resolvedEmojis.art
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local punishmentActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Edit Punishment Logs Channel",
					value = "punishmentlogschannel",
					emoji = resolvedEmojis.document
				},
				{
					label = "Edit BOLO Logs Channel",
					value = "bolologschannel",
					emoji = resolvedEmojis.document
				},
				{
					label = "Edit BOLO Log Mentionables",
					value = "bolologmentionables",
					emoji = resolvedEmojis.pings
				},
				{
					label = "Add Punishment Type",
					value = "addtype",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Remove Punishment Type",
					value = "removetype",
					emoji = resolvedEmojis.minus
				},
				{
					label = "Edit Tempban Time For Mods",
					value = "tempbantimemods",
					emoji = resolvedEmojis.clock
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local verificationActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Edit Verified Roles",
					value = "verifiedroles",
					emoji = resolvedEmojis.lock
				},
				{
					label = "Edit Unverified Roles",
					value = "unverifiedroles",
					emoji = resolvedEmojis.unlock
				},
				{
					label = "Edit Verified Nickname",
					value = "verifiednickname",
					emoji = resolvedEmojis.text
				},
				{
					label = "Edit Verification Channel",
					value = "verificationchannel",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Create Verification Panel",
					value = "verificationpanel",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Toggle Bloxlink Usage",
					value = "useBloxlink",
					emoji = resolvedEmojis.Bloxlink
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local antipingActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Toggle Module",
					value = "antiping",
					emoji = resolvedEmojis.settings
				},
				{
					label = "Edit Protected Roles",
					value = "antipingprotectedroles",
					emoji = resolvedEmojis.role
				},
				{
					label = "Edit Whitelisted Roles",
					value = "antipingwhitelistedroles",
					emoji = resolvedEmojis.role
				},
				{
					label = "Toggle Hierarchy",
					value = "antipinghierarchy",
					emoji = resolvedEmojis.role
				},
				{
					label = "Edit Anti Ping Embeds",
					value = "antipingembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit Anti Ghost Ping Embeds",
					value = "ghostpingembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit Whitelisted Channels",
					value = "antipingwhitelistedchannels",
					emoji = resolvedEmojis.edit
				}
			}
		})

		----------------------------------------------------------------------------------------------

		--[[
		local feedbackActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Edit Suggestions Channel",
					value = "suggestchannel",
					emoji = resolvedEmojis.suggestion
				},
				{
					label = "Edit Feedback Channel",
					value = "feedbackchannel",
					emoji = resolvedEmojis.star
				},
				{
					label = "Edit Feedback Embed",
					value = "feedbackembeds",
					emoji = resolvedEmojis.art
				}
			}
		})
		--]]

		----------------------------------------------------------------------------------------------

		local suggestionsActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Edit Suggestions Channel",
					value = "suggestchannel",
					emoji = resolvedEmojis.suggestion
				},
				{
					label = "Edit Max Upvotes",
					value = "maxupvotes",
					emoji = resolvedEmojis.counting
				},
				{
					label = "Edit Max Downvotes",
					value = "maxdownvotes",
					emoji = resolvedEmojis.counting
				},
				{
					label = "Edit Suggestion Thread",
					value = "suggestionthread",
					emoji = resolvedEmojis.thread
				},
				{
					label = "Edit Suggestion Submit Embeds",
					value = "suggestionsubmittedembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit Suggestion Approve Embeds",
					value = "suggestionapproveembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit Suggestion Deny Embeds",
					value = "suggestiondenyembeds",
					emoji = resolvedEmojis.art
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local shiftActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Edit Shift Logs Channel",
					value = "shiftlogschannel",
					emoji = resolvedEmojis.document
				},
				{
					label = "Toggle GameLock",
					value = "gamelock",
					emoji = resolvedEmojis.game
				},
				{
					label = "Add Shift Type",
					value = "addtype",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Edit Shift Type",
					value = "edittype",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Remove Shift Type",
					value = "removetype",
					emoji = resolvedEmojis.minus
				},
				{
					label = "Edit Wave Interval",
					value = "waveinterval",
					emoji = resolvedEmojis.reload
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local activityActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Toggle LOAs",
					value = "loasenabled",
					emoji = resolvedEmojis.settings
				},
				{
					label = "Edit LOA Logs Channel",
					value = "loalogschannel",
					emoji = resolvedEmojis.document
				},
				{
					label = "Edit LOA Role",
					value = "loarole",
					emoji = resolvedEmojis.role
				},
				{
					label = "Edit Max LOA Length",
					value = "loamaxlength",
					emoji = resolvedEmojis.clock

				},
				{
					label = "Edit LOA Nickname",
					value = "loanickname",
					emoji = resolvedEmojis.rename
				},
				{
					label = "View LOA Nickname Variables",
					value = "loanickvars",
					emoji = resolvedEmojis.json
				},
				{
					label = "Toggle Tracking Modcalls",
					value = "trackmodcalls",
					emoji = resolvedEmojis.modcall
				},
				{
					label = "Edit LOA Mentionables",
					value = "loamentionables",
					emoji = resolvedEmojis.pings
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local economyActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = (config.economy and config.economy.disabled and "Enable Economy") or "Disable Economy",
					value = "toggle",
					emoji = (config.economy and config.economy.disabled and resolvedEmojis.off) or resolvedEmojis.on
				},
				{
					label = "Edit Currency",
					value = "currency",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Edit Initial Amount",
					value = "initial",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Edit Amounts",
					value = "limits",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Edit Cooldowns",
					value = "cooldowns",
					emoji = resolvedEmojis.clock
				},
				{
					label = "Edit Economy Log Channel",
					value = "economylogchannel",
					emoji = resolvedEmojis.channel
				},
				{
					label = "Edit Blacklisted Roles",
					value = "blacklistedroles",
					emoji = resolvedEmojis.role
				},
				{
					label = "Create Collection Role",
					value = "createcollectionrole",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Edit Collection Role",
					value = "editcollectionrole",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Delete Collection Role",
					value = "deletecollectionrole",
					emoji = resolvedEmojis.minus
				},
				{
					label = "Create Reply",
					value = "createreply",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Edit Reply",
					value = "editreply",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Delete Reply",
					value = "deletereply",
					emoji = resolvedEmojis.minus
				},
				{
					label = "Create Shop Item",
					value = "createshopitem",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Edit Shop Item",
					value = "editshopitem",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Delete Shop Item",
					value = "deleteshopitem",
					emoji = resolvedEmojis.minus
				},
				{
					label = "Create Multiplier Role",
					value = "createmultiplier",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Delete Multiplier Role",
					value = "deletemultiplier",
					emoji = resolvedEmojis.minus
				},
				{
					label = "Reset Economy",
					value = "reseteconomy",
					emoji = resolvedEmojis.settings
				},
				{
					label = "Reset Balances",
					value = "resetbalances",
					emoji = resolvedEmojis.settings
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local ticketsActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Create Panel",
					value = "create",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Edit Panel",
					value = "edit",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Delete Panel",
					value = "delete",
					emoji = resolvedEmojis.delete
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local autorespondersActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Create New Autoresponder",
					value = "create",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Edit Autoresponder",
					value = "edit",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Delete Autoresponder",
					value = "delete",
					emoji = resolvedEmojis.delete
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local giveawaysActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Edit Giveaway Embeds",
					value = "giveawayembeds",
					emoji = resolvedEmojis.art
				},
				{
					label = "Edit Giveaway Blacklist Role",
					value = "giveawayblacklist",
					emoji = resolvedEmojis.nowhite
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local reactionboardActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Create Reaction Board",
					value = "create",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Edit Reaction Board",
					value = "edit",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Delete Reaction Board",
					value = "delete",
					emoji = resolvedEmojis.delete
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local messageManagementActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Create Sticky Message",
					value = "stickyCreate",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Edit Sticky Message",
					value = "stickyEdit",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Remove Sticky Message",
					value = "stickyDelete",
					emoji = resolvedEmojis.minus
				},
				{
					label = "Create Autodelete Channel",
					value = "autoDeleteCreate",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Edit Autodelete Channel",
					value = "autoDeleteEdit",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Remove Autodelete Channel",
					value = "autoDeleteDelete",
					emoji = resolvedEmojis.minus
				},
				{
					label = "Create Valuable Message",
					value = "valuableMessageCreate",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Edit Valuable Message",
					value = "valuableMessageEdit",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Remove Valuable Message",
					value = "valuableMessageDelete",
					emoji = resolvedEmojis.minus
				},
				{
					label = "Create Autoreact Channel",
					value = "createautoreactchannel",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Edit Autoreact Channel",
					value = "editautoreactchannel",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Remove Autoreact Channel",
					value = "removeautoreactchannel",
					emoji = resolvedEmojis.minus
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local departmentsActions = discordia.SelectMenu({
			id = "actions",
			placeholder = "Edit configuration...",
			min_values = 0,
			max_values = 1,
			actionRow = 1,
			options = {
				{
					label = "Link Department",
					value = "linknew",
					emoji = resolvedEmojis.guild
				},
				{
					label = "Unlink Department",
					value = "unlink",
					emoji = resolvedEmojis.unlink
				},
				{
					label = "Create Linked Role",
					value = "createlinkedrole",
					emoji = resolvedEmojis.plus
				},
				{
					label = "Remove Linked Role",
					value = "removelinkedrole",
					emoji = resolvedEmojis.minus
				},
				{
					label = "Toggle Sync Nicknames",
					value = "togglesyncnicknames",
					emoji = resolvedEmojis.rename
				}
			}
		})

		----------------------------------------------------------------------------------------------

		local function getcomps(pagenum)
			if pagenum == allPages.welcome.number then
				return discordia.Components({
					basicActions
				})
			elseif pagenum == allPages.dcmod.number then
				return discordia.Components({
					discordModerationActions
				})
			elseif pagenum == allPages.audit.number then
				return discordia.Components({
					auditLogActions
				})
			elseif pagenum == allPages.erlc.number then
				return discordia.Components({
					erlcActions
				})
			elseif pagenum == allPages.erlcRegions.number then
				return discordia.Components({
					erlcRegionsActions
				})
			elseif pagenum == allPages.erlcStatus.number then
				return discordia.Components({
					erlcStatusActions
				})
			elseif pagenum == allPages.erlcLog.number then
				return discordia.Components({
					erlcLogActions
				})
			elseif pagenum == allPages.discordStatistics.number then
				return discordia.Components({
					discordStatisticsActions
				})
			elseif pagenum == allPages.join.number then
				return discordia.Components({
					joinActions
				})
			elseif pagenum == allPages.sessions.number then
				return discordia.Components({
					sessionActions
				})
			elseif pagenum == allPages.staff.number then
				return discordia.Components({
					staffManagementActions
				})
			elseif pagenum == allPages.punish.number then
				return discordia.Components({
					punishmentActions
				})
			elseif pagenum == allPages.verify.number then
				return discordia.Components({
					verificationActions
				})
			elseif pagenum == allPages.pings.number then
				return discordia.Components({
					antipingActions
				})
				--[[
			elseif pagenum == allPages.feedback.number then
				return discordia.Components({
					feedbackActions
				})
			--]]
			elseif pagenum == allPages.suggestions.number then
				return discordia.Components({
					suggestionsActions
				})
			elseif pagenum == allPages.shift.number then
				return discordia.Components({
					shiftActions
				})
			elseif pagenum == allPages.activity.number then
				return discordia.Components({
					activityActions
				})
			elseif pagenum == allPages.economy.number then
				return discordia.Components({
					economyActions
				})
			elseif pagenum == allPages.tickets.number then
				return discordia.Components({
					ticketsActions
				})
			elseif pagenum == allPages.responders.number then
				return discordia.Components({
					autorespondersActions
				})
			elseif pagenum == allPages.giveaways.number then
				return discordia.Components({
					giveawaysActions
				})
			elseif pagenum == allPages.boards.number then
				return discordia.Components({
					reactionboardActions
				})
			elseif pagenum == allPages.messages.number then
				return discordia.Components({
					messageManagementActions
				})
			elseif pagenum == allPages.departments.number then
				return discordia.Components({
					departmentsActions
				})
			end
		end

		local function setDefault(selmenu, val, pagenum)
			if selmenu.type == 6 then
				if type(val) == "table" then
					local newdefs = {}
					for _, v in pairs(val) do
						table.insert(newdefs, {
							id = v,
							type = "role"
						})
					end
					selmenu:defaultValues(newdefs)

					pages[pagenum].components = getcomps(pagenum)
				else
					selmenu:defaultValues({
						{
							id = val,
							type = "role"
						}
					})

					pages[pagenum].components = getcomps(pagenum)
				end
			elseif selmenu.type == 8 then
				if type(val) == "table" then
					local newdefs = {}
					for _, v in pairs(val) do
						table.insert(newdefs, {
							id = v,
							type = "channel"
						})
					end
					selmenu:defaultValues(newdefs)

					pages[pagenum].components = getcomps(pagenum)
				else
					selmenu:defaultValues({
						{
							id = val,
							type = "channel"
						}
					})

					pages[pagenum].components = getcomps(pagenum)
				end
			elseif selmenu.type == 3 then
				local opts = table.deepcopy(selmenu:raw().options)
				for _, v in pairs(opts) do
					if table.search(val, v.value) then
						v.default = true
					else
						v.default = false
					end
				end

				selmenu:options(opts)

				pages[pagenum].components = getcomps(pagenum)
			end
		end

		local ERLCServer = config.apikey and ERLC:getServer(config.apikey)

		local function getEmbedDescription(pagenum)
			if pagenum == allPages.welcome.number then
				return "## " .. emojis.ducky .. " Welcome to Ducky\n" .. emojis.hiya .. " **Hiya,** and thank you for choosing " .. emojis.ducky .. " **Ducky**, a multipurpose bot focused on seamlessly integrating Discord and ERLC server automation for effortless management. This configuration menu allows you to configure Ducky to fit your server's needs. On this page, you can find basic configuration to get you started quickly. If you require assistance, check out our [documentation (work-in-progress)](https://docs.duckybot.xyz/) or contact our " .. emojis.support .. " **Support** team via the [support server](https://duckybot.xyz/support).\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Prefix:** " .. (config.prefix or emojis.fail) .. "\n" .. emojis.right .. " **Disabled Commands:**\n" .. emojis.space .. emojis.right .. " " .. ((config.disabledcommands and table.count(config.disabledcommands) > 0) and table.concatFn(config.disabledcommands, "\n" .. emojis.space .. emojis.right .. " ", function(v)
					return "`/" .. v .. "`"
				end) or "None") .. "\n" .. emojis.right .. " **Command Blacklists:**\n" .. emojis.space .. emojis.right .. " " .. ((config.commandblacklists and ((type(config.commandblacklists.channels) == "table" and #config.commandblacklists.channels > 0) or (type(config.commandblacklists.roles) == "table" and #config.commandblacklists.roles > 0))) and table.concat((function()
					local lines = {}
					for i, v in ipairs(config.commandblacklists.channels or {}) do
						if i > 5 then
							break
						end
						table.insert(lines, "<#" .. v .. ">")
					end
					for i, v in ipairs(config.commandblacklists.roles or {}) do
						if i > 5 then
							break
						end
						table.insert(lines, "<@&" .. v .. ">")
					end
					if #config.commandblacklists.channels > 5 then
						table.insert(lines, "...and " .. (#config.commandblacklists.channels - 5) .. " more channel" .. ((#config.commandblacklists.channels - 5 > 1) and "s" or ""))
					end
					if #config.commandblacklists.roles > 5 then
						table.insert(lines, "...and " .. (#config.commandblacklists.roles - 5) .. " more role" .. ((#config.commandblacklists.roles - 5 > 1) and "s" or ""))
					end

					table.insert(lines, " **Manage Server Bypass:** " .. ((config.commandblacklists.manageserverbypass and emojis.success) or emojis.fail))
					return lines
				end)(), "\n" .. emojis.space .. emojis.right .. " ") or "None") .. "\n"
				.. emojis.right .. " **Command Logs Channel:** " .. ((config.commandlogschannel and "<#" .. config.commandlogschannel .. ">") or emojis.fail) .. "\n"
				.. emojis.right .. " **Permissions:**\n" .. emojis.space .. emojis.right .. " **Discord Moderator Roles:** " .. (config.modroles and ("\n" .. emojis.space .. emojis.space .. emojis.right .. " " .. table.concatFn(config.modroles, "\n" .. emojis.space .. emojis.space .. emojis.right .. " ", function(r)
					return "<@&" .. r .. ">"
				end)) or emojis.fail) .. "\n" .. emojis.space .. emojis.right .. " **Discord Administrator Roles:** " .. (config.adminroles and ("\n" .. emojis.space .. emojis.space .. emojis.right .. " " .. table.concatFn(config.adminroles, "\n" .. emojis.space .. emojis.space .. emojis.right .. " ", function(r)
					return "<@&" .. r .. ">"
				end)) or emojis.fail) .. "\n" .. emojis.space .. emojis.right .. " **ERLC Staff Roles:** " .. (config.erlcstaffroles and ("\n" .. emojis.space .. emojis.space .. emojis.right .. " " .. table.concatFn(config.erlcstaffroles, "\n" .. emojis.space .. emojis.space .. emojis.right .. " ", function(r)
					return "<@&" .. r .. ">"
				end)) or emojis.fail) .. "\n" .. emojis.space .. emojis.right .. " **ERLC Administrator Roles:** " .. (config.erlcadminroles and ("\n" .. emojis.space .. emojis.space .. emojis.right .. " " .. table.concatFn(config.erlcadminroles, "\n" .. emojis.space .. emojis.space .. emojis.right .. " ", function(r)
					return "<@&" .. r .. ">"
				end)) or emojis.fail) .. "\n" .. emojis.space .. emojis.right .. " **ERLC Manager Roles:** " .. (config.erlcmanagerroles and ("\n" .. emojis.space .. emojis.space .. emojis.right .. " " .. table.concatFn(config.erlcmanagerroles, "\n" .. emojis.space .. emojis.space .. emojis.right .. " ", function(r)
					return "<@&" .. r .. ">"
				end)) or emojis.fail) .. "\n" .. emojis.space .. emojis.right .. " **Session Starter Roles:** " .. (config.sessionstarterroles and ("\n" .. emojis.space .. emojis.space .. emojis.right .. " " .. table.concatFn(config.sessionstarterroles, "\n" .. emojis.space .. emojis.space .. emojis.right .. " ", function(r)
					return "<@&" .. r .. ">"
				end)) or emojis.fail) .. "\n" .. emojis.right .. " **Configuration Log Channel:** " .. ((config.configlogchannel and ("<#" .. config.configlogchannel .. ">")) or emojis.fail)
			elseif pagenum == allPages.dcmod.number then
				return "## " .. emojis.moderate .. " Discord Moderation\n" .. emojis.right .. " Ducky's " .. emojis.moderate .. " **Discord Moderation** module allows for you to moderate your Discord server with ease.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Modlogs Channel:** " .. ((config.modlogchannel and "<#" .. config.modlogchannel .. ">") or emojis.fail) .. "\n" .. emojis.right .. " **Appeal Links:**\n" .. emojis.space .. emojis.right .. " " .. (config.appealLinks and table.count(config.appealLinks) > 0 and (table.concatFn(config.appealLinks, "\n" .. emojis.space .. emojis.right .. " ", function(link, type)
					return string.capitalize(type) .. ": " .. link
				end)) or "None") .. "\n" .. emojis.right .. " **Staff Immunity:** " .. ((config.discordstaffimmunity and emojis.success) or emojis.fail)
			elseif pagenum == allPages.audit.number then
				local changed = false
				local primary = config.auditlogchannels and config.auditlogchannels.primary

				if config.auditlogchannels and primary and primary.channel then
					for _, v in pairs(config.audittypes or {}) do
						local type = config.auditlogchannels[v]

						if type and type.channel and type.channel == primary.channel then
							if type.webhook and type.webhook.ID then
								local webhook = Client:getWebhook(type.webhook.ID)
								if webhook then webhook:delete() end
							end

							config.auditlogchannels[v] = nil
							changed = true
						end
					end
				end

				if changed then
					modifyKey("auditlogchannels", config.auditlogchannels)
				end

				return "## " .. emojis.log .. " Audit Logging\n" .. emojis.right .. " Ducky's " .. emojis.log .. " **Audit Logging** module allows for you to see what changes occur in your server.\n### " .. emojis.settings .. " Configuration\n"
					.. emojis.right .. " **Primary Audit Logs Channel:** " .. ((config.auditlogchannels and config.auditlogchannels.primary and config.auditlogchannels.primary.channel and "<#" .. config.auditlogchannels.primary.channel .. ">") or emojis.fail)
					.. "\n" .. emojis.right .. " **Audit Log Types:**\n"
						.. ((config.audittypes and table.count(config.audittypes) > 0 and getAuditString()) or emojis.space .. emojis.right .. " None")
			elseif pagenum == allPages.erlc.number then
				if config.erlcplaytimerewards then
					table.sort(config.erlcplaytimerewards, function(a, b)
						return a.playtime < b.playtime
					end)
				end

				return "## " .. emojis.game .. " ERLC Integration\n"
				.. emojis.right .. " Ducky's " .. emojis.game .. " **ERLC Integration** module allows for you to manage and view your ERLC server without having to go in-game.\n" ..
				"### " .. emojis.settings .. " Configuration" .. "\n"
				.. emojis.right .. " **In-Game Role:** " .. ((config.ingamerole and "<@&" .. config.ingamerole .. ">") or emojis.fail) .. "\n"
				.. emojis.right .. " **ERLC Server:** " .. ((ERLCServer and ERLCServer.name and ERLCServer.joinCode and ERLCServer.name .. " (`" .. ERLCServer.joinCode .. "`)") or emojis.fail) .. "\n"
				.. emojis.right .. " **Advanced Remote Execution Permissions:** " .. ((config.advancederlccmdperms and emojis.success) or emojis.fail) .. "\n"
				.. emojis.right .. " **ERLC Command Logs Channel:** " .. ((config.erlccmdschannel and "<#" .. config.erlccmdschannel .. ">") or emojis.fail) .. "\n"
				.. emojis.right .. " **ERLC Kick/Ban Logs Channel:** " .. ((config.erlckickbanchannel and "<#" .. config.erlckickbanchannel .. ">") or emojis.fail) .. "\n"
				.. emojis.right .. " **Auto Log Kicks/BOLOs:** " .. ((config.erlcautologkickban and emojis.success) or emojis.fail) .. "\n"
				.. emojis.right .. " **Ban Syncing Mode:** " .. (function()
					if not config.erlcbansync then
						return emojis.fail
					end

					local modes = {
						erlctodc = "ERLC" .. emojis.right .. "Discord",
						dctoerlc = "Discord" .. emojis.right .. "ERLC",
						both = "ERLC " .. emojis.link .. " Discord"
					}

					return modes[config.erlcbansync] or emojis.fail
				end)() .. "\n"
				.. emojis.right .. " **Playtime Rewards:** " .. (config.erlcplaytimerewards and next(config.erlcplaytimerewards) and "\n" .. emojis.space .. emojis.right .. " " .. table.concatFn(config.erlcplaytimerewards, "\n" .. emojis.space .. emojis.right .. " ", function(reward)
					return "**" .. readable(reward.playtime) .. ":** <@&" .. reward.role .. ">"
				end) or emojis.fail) .. "\n"
				.. emojis.right .. " **Playtime Reward Announcements Channel:** " .. ((config.erlcplaytimechannel and "<#" .. config.erlcplaytimechannel .. ">") or emojis.fail)
			elseif pagenum == allPages.erlcRegions.number then
				return "## " .. emojis.map .. " ERLC Regions\n"
				.. emojis.right .. " Ducky's " .. emojis.map .. " **ERLC Regions** module allows for you to seamlessly automate and manage players based on their locations on the map. These regions can be used across Ducky for features such as Linked VCs, Automations, and more.\n" ..
				"### " .. emojis.settings .. " Configuration" .. "\n"
				.. emojis.right .. " **Regions:** " .. (config.regions and next(config.regions) and "\n" .. emojis.space .. emojis.right .. " " .. table.concatFn(config.regions, "\n" .. emojis.space .. emojis.right .. " ", function(region)
					local Region = erlua.Region(region.name, region.points)
					return "**" .. Region.name .. ":** " .. formatNumber(Region.area) .. " studs², " .. #region.points .. " points" .. ((region.voiceChannel and (" " .. emojis.dot .. " <#" .. region.voiceChannel .. ">")) or "")
				end) or emojis.fail)
				.. "\n" .. emojis.right .. " **Waiting Voice Channel:** " .. ((config.regionwaitingvc and ("<#" .. config.regionwaitingvc .. ">")) or emojis.fail) .. (((table.find(config.regions, function(r)
					return r.voiceChannel
				end) or config.regionwaitingvc) and ("\n-# " .. emojis.warning .. " Linked VCs is a " .. emojis.beta .. " feature and may not function as expected.")) or "")
			elseif pagenum == allPages.erlcStatus.number then
				if type(config.erlcserverstatuschannels) == "table" and next(config.erlcserverstatuschannels) then
					local changed
					for i, channel in pairs(config.erlcserverstatuschannels) do
						if channel.locked and (isPlusGuild or i <= featureLimits.erlcStatusChannels.normal) then
							channel.locked = false
							changed = true
						end
					end

					if changed then modifyKey("erlcserverstatuschannels", config.erlcserverstatuschannels) end
				end

				return "## " .. emojis.network .. " ERLC Server Status\n" .. emojis.right .. " Ducky's " .. emojis.network .. " **ERLC Server Status** module allows you to display live statistics from your ERLC server in your discord server.\n### " .. emojis.settings .. " Configuration" .. "\n" .. emojis.right .. " **Server Status Message:** " .. "\n" .. emojis.space .. emojis.right .. " **Channel:** " .. ((config.erlcserverstatusmessage and config.erlcserverstatusmessage.channel and ("<#" .. config.erlcserverstatusmessage.channel .. ">")) or emojis.fail) .. "\n" .. emojis.space .. emojis.right .. " **Link:** " .. ((config.erlcserverstatusmessage and config.erlcserverstatusmessage.channel and config.erlcserverstatusmessage.message and ("https://discord.com/channels/" .. interaction.guild.id .. "/" .. config.erlcserverstatusmessage.channel .. "/" .. config.erlcserverstatusmessage.message)) or emojis.fail) .. "\n" .. emojis.space .. emojis.right .. " **Content:** " .. ((config.erlcserverstatusmessage and config.erlcserverstatusmessage.tosend and "Custom") or emojis.fail) .. "\n" .. emojis.right .. " **Server Status Channels:** \n" .. emojis.space .. emojis.right .. " " .. ((config.erlcserverstatuschannels and (table.count(config.erlcserverstatuschannels) > 0) and table.concatFn(config.erlcserverstatuschannels, "\n" .. emojis.space .. emojis.right .. " ", function(sh)
					local channel = interaction.guild:getChannel(sh.channel)

					if channel then
						return ((sh.locked and emojis.lock .. emojis.dot) or "") .. channel.mentionString
					else
						return "Unknown Channel"
					end
				end)) or "None")
			elseif pagenum == allPages.discordStatistics.number then
				if type(config.discordserverstatuschannels) == "table" and next(config.discordserverstatuschannels) then
					local changed
					for i, channel in pairs(config.discordserverstatuschannels) do
						if channel.locked and (isPlusGuild or i <= featureLimits.discordStatusChannels.normal) then
							channel.locked = false
							changed = true
						end
					end

					if changed then modifyKey("discordserverstatuschannels", config.discordserverstatuschannels) end
				end

				return "## " .. emojis.chart .. " Discord Server Statistics\n" .. emojis.right .. " Ducky's " .. emojis.chart .. " **Discord Server Statistics** module allows you to display live statistics from your Discord server.\n### " .. emojis.settings .. " Configuration" .. "\n" .. emojis.right .. " **Current Statistics Channels:** \n" .. emojis.space .. emojis.right .. " " .. ((config.discordserverstatuschannels and (table.count(config.discordserverstatuschannels) > 0) and table.concatFn(config.discordserverstatuschannels, "\n" .. emojis.space .. emojis.right .. " ", function(sh)
					local channel = interaction.guild:getChannel(sh.channel)

					if channel then
						return ((sh.locked and emojis.lock .. emojis.dot) or "") .. channel.mentionString
					else
						return "Unknown Channel"
					end
				end)) or "None")
			elseif pagenum == allPages.erlcLog.number then
				return "## " .. emojis.search .. " ERLC Server Logs\n" .. emojis.right .. " Ducky's " .. emojis.search .. " **ERLC Server Logs** module allows you to keep track of in-game activity, with a simple setup and fully customizable messages.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Player Join Logs:** " .. (config.erlclogs and config.erlclogs.playerjoin and "<#" .. config.erlclogs.playerjoin.channel .. ">" or emojis.fail) .. "\n" .. emojis.right .. " **Player Leave Logs:** " .. (config.erlclogs and config.erlclogs.playerleave and "<#" .. config.erlclogs.playerleave.channel .. ">" or emojis.fail) .. "\n" .. emojis.right .. " **Player Team Logs:** " .. (config.erlclogs and config.erlclogs.playerteam and "<#" .. config.erlclogs.playerteam.channel .. ">" or emojis.fail) .. "\n" .. emojis.right .. " **Player Kill Logs:** " .. (config.erlclogs and config.erlclogs.playerkill and "<#" .. config.erlclogs.playerkill.channel .. ">" or emojis.fail) .. "\n" .. emojis.right .. " **Modcall Logs:** " .. (config.erlclogs and config.erlclogs.modcall and "<#" .. config.erlclogs.modcall.channel .. ">" or emojis.fail) .. "\n\n-# *" .. emojis.right .. " Looking for more customization? Use " .. emojis.automation .. " **Automations** with `/automations create`.*"
			elseif pagenum == allPages.join.number then
				return "## " .. emojis.wave .. " Welcome/Autoroles\n" .. emojis.right .. " Ducky's " .. emojis.wave .. " **Welcome/Autoroles** module allows for you to send a message to welcome your users in the specified channel, as well as give them up to 5 roles automatically.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Autoroles:** " .. ((config.joinroles and (table.count(config.joinroles) > 0) and ("\n" .. emojis.space .. emojis.right .. table.concatFn(config.joinroles, "\n" .. emojis.space .. emojis.right .. " ", function(jr)
					return "<@&" .. tostring(jr) .. ">"
				end))) or emojis.fail) .. "\n" .. emojis.right .. " **Welcome Channel:** " .. ((config.joinchannel and "<#" .. config.joinchannel .. ">") or emojis.fail) .. "\n" .. emojis.right .. " **Autodelete Delay:** " .. ((config.joinmessagedelete and readable(config.joinmessagedelete)) or emojis.fail) .. "\n" .. emojis.right .. " **DM Member:** " .. ((config.dmjoin and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Joingate Threshold:** " .. ((config.joingatethreshold and readable(config.joingatethreshold)) or emojis.fail)
			elseif pagenum == allPages.sessions.number then
				return "## " .. emojis.game .. " Sessions\n" .. emojis.right .. " Ducky's " .. emojis.game .. " **Sessions** module allows for you to manage your sessions easily.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Sessions Channel:** " .. ((config.sessionschannel and "<#" .. config.sessionschannel .. ">") or emojis.fail) .. "\n" .. emojis.right .. " **Session Mentionables:**\n" .. emojis.space .. emojis.right .. " " .. ((config.sessionmentionables and table.count(config.sessionmentionables) > 0 and table.concatFn(config.sessionmentionables, "\n" .. emojis.space .. emojis.right .. " ", function(sm)
					return (interaction.guild:getRole(sm) and ("<@&" .. sm .. ">")) or ("<@" .. sm .. ">")
				end)) or "None") .. "\n" .. emojis.right .. " **Ping Here:** " .. ((config.sessionspinghere and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Ping Everyone:** " .. ((config.sessionspingeveryone and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Server Information:** " .. ((config.serverInfo and "\n" .. emojis.space .. emojis.right .. " **Server Name:** " .. (config.serverInfo.Name or emojis.fail) .. "\n" .. emojis.space .. emojis.right .. " **Server Max Players:** " .. (config.serverInfo.MaxPlayers or emojis.fail) .. "\n" .. emojis.space .. emojis.right .. " **Server Join Code:** " .. (config.serverInfo.JoinKey or emojis.fail)) or ((config.apikey and emojis.key .. " Fetched with API Key") or emojis.fail))
			elseif pagenum == allPages.staff.number then
				return "## " .. emojis.quickfix .. " Staff Management\n" .. emojis.right .. " Ducky's " .. emojis.quickfix .. " **Staff Management** module allows for you to infract and promote your staff members.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Infractions Channel:** " .. ((config.infractionschannel and "<#" .. config.infractionschannel .. ">") or emojis.fail) .. "\n" .. emojis.right .. " **Infraction Thread:** " .. ((config.infractionthread and string.truncate(config.infractionthread, 100)) or emojis.fail) .. "\n" .. emojis.right .. " **Infraction Types:**\n" .. emojis.space .. emojis.right .. " " .. ((config.infractiontypes and table.count(config.infractiontypes) > 0 and table.concatFn(config.infractiontypes, "\n" .. emojis.space .. emojis.right .. " ", function(it)
					return it.name
				end)) or "None") .. "\n" .. emojis.right .. " **Promotions Channel:** " .. ((config.promotionschannel and "<#" .. config.promotionschannel .. ">") or emojis.fail) .. "\n" .. emojis.right .. " **Promotion Thread:** " .. ((config.promotionsthread and string.truncate(config.promotionsthread, 100)) or emojis.fail) .. "\n" .. emojis.right .. " **Feedback Channel:** " .. ((config.feedbackchannel and "<#" .. config.feedbackchannel .. ">") or emojis.fail)
			elseif pagenum == allPages.punish.number then
				return "## " .. emojis.roblox .. " Roblox Punishments\n" .. emojis.right .. " Ducky's " .. emojis.roblox .. " **Roblox Punishments** module allows for you to manage and log punishments for your ERLC server.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Roblox Punishment Logs Channel:** " .. ((config.punishmentlogschannel and "<#" .. config.punishmentlogschannel .. ">") or emojis.fail) .. "\n" .. emojis.right .. " **BOLO Logs Channel:** " .. ((config.bolologschannel and "<#" .. config.bolologschannel .. ">") or emojis.fail) .. "\n" .. emojis.right .. " **BOLO Log Mentionables:**\n" .. emojis.space .. emojis.right .. " " .. ((config.bolologmentionables and table.count(config.bolologmentionables) > 0 and table.concatFn(config.bolologmentionables, "\n" .. emojis.space .. emojis.right .. " ", function(bm)
					return (interaction.guild:getRole(bm) and ("<@&" .. bm .. ">")) or ("<@" .. bm .. ">")
				end)) or "None") .. "\n" .. emojis.right .. " **Roblox Punishment Types:**\n" .. emojis.space .. emojis.right .. " " .. ((config.punishmenttypes and table.count(config.punishmenttypes) > 0 and table.concat(config.punishmenttypes, "\n" .. emojis.space .. emojis.right .. " ")) or "None") .. "\n" .. emojis.right .. " **Tempban for Moderators:** " .. ((config.tempbantimemods and tonumber(config.tempbantimemods) and readable(config.tempbantimemods)) or emojis.fail)
			elseif pagenum == allPages.verify.number then
				return "## " .. emojis.roblox .. " Roblox Verification\n" .. emojis.right .. " Ducky's " .. emojis.roblox .. " **Roblox Verification** module allows for you to add a layer of security to your server.\n\n**Verified Nickname Variables**\n" .. emojis.right .. " **`{roblox.username}`:** The member's Roblox username.\n" .. emojis.right .. " **`{roblox.display}`:** The member's Roblox display name.\n" .. emojis.right .. " **`{roblox.id}`:** The member's Roblox ID.\n" .. emojis.right .. " **`{discord.username}`:** The member's Discord username.\n" .. emojis.right .. " **`{discord.name}`:** The member's Discord display name.\n" .. emojis.right .. " **`{discord.id}`:** The member's Discord ID.\n### " .. emojis.settings .. " Configuration" .. "\n" .. emojis.right .. " **Verified Nickname:** " .. ((config.verifiednickname) or emojis.fail) .. "\n" .. emojis.right .. " **Verified Roles:**\n" .. emojis.space .. emojis.right .. " " .. ((config.verifiedroles and table.count(config.verifiedroles) > 0 and table.concatFn(config.verifiedroles, "\n" .. emojis.space .. emojis.right .. " ", function(r)
					return "<@&" .. r .. ">"
				end)) or "None") .. "\n" .. emojis.right .. " **Unverified Roles:**\n" .. emojis.space .. emojis.right .. " " .. ((config.unverifiedroles and table.count(config.unverifiedroles) > 0 and table.concatFn(config.unverifiedroles, "\n" .. emojis.space .. emojis.right .. " ", function(r)
					return "<@&" .. r .. ">"
				end)) or "None") .. "\n" .. emojis.right .. " **Verification Channel:** " .. ((config.verificationchannel and "<#" .. config.verificationchannel .. ">") or emojis.fail) .. "\n" .. emojis.right .. " **Use Bloxlink:** " .. ((config.bloxlinkServerKey and emojis.success) or emojis.fail)
			elseif pagenum == allPages.pings.number then
				return "## " .. emojis.pings .. " Discord Pings\n" .. emojis.right .. " Ducky's " .. emojis.pings .. " **Discord Pings** module spares you from unnecessary pings and ghost pings.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Module Enabled:** " .. ((config.antiping and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Protected Roles:**\n" .. emojis.space .. emojis.right .. " " .. ((config.antipingprotectedroles and table.count(config.antipingprotectedroles) > 0 and table.concatFn(config.antipingprotectedroles, "\n" .. emojis.space .. emojis.right .. " ", function(r)
					return "<@&" .. r .. ">"
				end)) or "None") .. "\n" .. emojis.right .. " **Whitelisted Roles:**\n" .. emojis.space .. emojis.right .. " " .. ((config.antipingwhitelistedroles and table.count(config.antipingwhitelistedroles) > 0 and table.concatFn(config.antipingwhitelistedroles, "\n" .. emojis.space .. emojis.right .. " ", function(r)
					return "<@&" .. r .. ">"
				end)) or "None") .. "\n" .. emojis.right .. " **Hierarchy Enabled:** " .. ((config.antipinghierarchy and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Whitelisted Channels:** " .. (config.antipingwhitelistedchannels and next(config.antipingwhitelistedchannels) and ("\n" .. emojis.space .. emojis.right .. " " .. table.concatFn(config.antipingwhitelistedchannels, "\n" .. emojis.space .. emojis.right .. " ", function(c)
					return "<#" .. c .. ">"
				end)) or emojis.fail)
			elseif pagenum == allPages.suggestions.number then
				return "## " .. emojis.suggestion .. " Suggestions\n" .. emojis.right .. " Ducky's " .. emojis.suggestion .. " **Suggestions** module allows you to smoothly collect feedback from community members through suggestions.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Suggestions Channel:** " .. ((config.suggestchannel and "<#" .. config.suggestchannel .. ">") or emojis.fail) .. "\n" .. emojis.right .. " **Max Upvotes:** " .. (config.suggestionsmaxupvotes or emojis.fail) .. "\n" .. emojis.right .. " **Max Downvotes:** " .. (config.suggestionsmaxdownvotes or emojis.fail) .. "\n" .. emojis.right .. " **Suggestion Thread:** " .. (config.suggestionthread or emojis.fail)
			elseif pagenum == allPages.shift.number then
				return "## " .. emojis.clock .. " Shift Management\n" .. emojis.right .. " Ducky's " .. emojis.clock .. " **Shift Management** module allows your staff to manage their shifts with ease. You can view shift statistics, administrate a shift, use GameLock to ensure staff are in-game before starting their shift, and more.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Shift Logs Channel:** " .. ((config.shiftlogschannel and "<#" .. config.shiftlogschannel .. ">") or emojis.fail) .. "\n" .. emojis.right .. " **GameLock Enabled:** " .. ((config.shifts and config.shifts.gamelock and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Shift Types:**\n" .. emojis.space .. emojis.right .. " " .. ((config.shifts and config.shifts.types and table.count(config.shifts.types) > 0 and table.concatFn(config.shifts.types, "\n" .. emojis.space .. emojis.right .. " ", function(st)
					return st.name
				end)) or "None") .. "\n" .. emojis.right .. " **Wave Interval:** " .. ((config.shifts and config.shifts.waveinterval and readable(config.shifts.waveinterval)) or emojis.fail)
			elseif pagenum == allPages.activity.number then
				return "## " .. emojis.chart .. " Activity Management\n" .. emojis.right .. " Ducky's " .. emojis.chart .. " **Activity Management** module allows your staff to request LOAs, and allows for you to ensure your staff's activity.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **LOAs Enabled:** " .. ((config.loasenabled and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **LOA Logs Channel:** " .. ((config.loalogschannel and "<#" .. config.loalogschannel .. ">") or emojis.fail) .. "\n" .. emojis.right .. " **LOA Mentionables:** " .. ((config.loamentionables and next(config.loamentionables) and "\n" .. emojis.space .. emojis.right .. " " .. table.concatFn(config.loamentionables, "\n" .. emojis.space .. emojis.right .. " ", function(sm) return (interaction.guild:getRole(sm) and ("<@&" .. sm .. ">")) or ("<@" .. sm .. ">") end)) or emojis.fail) .. "\n" .. emojis.right .. " **LOA Role:** " .. ((config.loarole and "<@&" .. config.loarole .. ">") or emojis.fail) .. "\n" .. emojis.right .. " **LOA Nickname:** " .. ((config.loanickname and ("`" .. config.loanickname .. "`")) or emojis.fail) .. "\n" .. emojis.right .. " **Max LOA Length:** " .. ((config.loamaxlength and readable(config.loamaxlength)) or emojis.fail) .. "\n" .. emojis.right .. " **Track Modcalls:** " .. ((config.trackModcalls and emojis.success) or emojis.fail)
			elseif pagenum == allPages.economy.number then
				config.economy = config.economy or {}
				
				local amounts = ""
				config.economy.limits = config.economy.limits or {}
				if config.economy and config.economy.limits and next(config.economy.limits) then
					for name, data in pairs(config.economy.limits) do
						amounts = amounts .. emojis.space .. emojis.right .. " **" .. string.capitalize(name) .. "**\n"
						amounts = amounts .. emojis.space .. emojis.space .. emojis.right .. " " .. emojis.success .. " " .. formatNumber(data.success.min) .. " " .. emojis.transfer .. " " .. formatNumber(data.success.max) .. "\n"
						if data.fail then
							local failValue = data.fail
							local isPercent = false
							if failValue < 1 then
								failValue = math.floor(failValue * 100)
								isPercent = true
							end
							amounts = amounts .. emojis.space .. emojis.space .. emojis.right .. " " .. emojis.fail .. " " .. formatNumber(failValue) .. (isPercent and "%" or "") .. "\n"
						end
					end
				else
					amounts = emojis.fail
				end

				local replies = ""
				config.economy.replies = config.economy.replies or {}
				if config.economy and config.economy.replies and next(config.economy.replies) then
					for action, messages in pairs(config.economy.replies) do
						replies = replies .. emojis.space .. emojis.right .. " **" .. string.capitalize(action) .. "**\n"
						for _, msgData in ipairs(messages) do
							replies = replies .. emojis.space .. emojis.space .. emojis.right .. " " .. ((msgData.success == true) and emojis.success or emojis.fail) .. " " .. msgData.message .. "\n"
						end
					end
				else
					replies = emojis.fail
				end

				local cooldowns = ""
				config.economy.cooldowns = config.economy.cooldowns or {}
				if config.economy and config.economy.cooldowns and next(config.economy.cooldowns) then
					for action, cooldown in pairs(config.economy.cooldowns) do
						cooldowns = cooldowns .. emojis.space .. emojis.right .. " **" .. string.capitalize(action) .. "**: " .. readable(cooldown) .. "\n"
					end
				else
					cooldowns = emojis.fail
				end

				local collectionRoles = ""
				config.economy.collectionroles = config.economy.collectionroles or {}
				if config.economy and config.economy.collectionroles and next(config.economy.collectionroles) then
					for _, data in ipairs(config.economy.collectionroles) do
						collectionRoles = collectionRoles .. emojis.space .. emojis.right .. " <@&" .. (data and data.role) .. ">" .. "\n" ..
						emojis.space .. emojis.space .. emojis.right .. " **Amount:** " .. formatNumber((data and data.amount and tonumber(data.amount))) .. "\n" ..
						emojis.space .. emojis.space .. emojis.right .. " **Cooldown:** " ..
						(
							(data and data.cooldown and data.cooldown > 0)
								and readable(data.cooldown) or emojis.fail
						)
						.. "\n" ..
						emojis.space .. emojis.space .. emojis.right .. " **Target:** " .. string.capitalize((data and data.target)) .. "\n"
					end
				else
					collectionRoles = emojis.fail
				end

				local multipliers = ""
				config.economy.multipliers = config.economy.multipliers or {}
				if config.economy and config.economy.multipliers and next(config.economy.multipliers) then
					for id, multiplier in pairs(config.economy.multipliers) do
						multipliers = multipliers .. emojis.space .. emojis.right .. " **<@&" .. (id) .. ">:** " .. multiplier .. "x income multiplier" .. "\n"
					end
				else
					multipliers = emojis.fail
				end

				local blacklistedRoles = ""
				config.economy.blacklistedroles = config.economy.blacklistedroles or {}
				if config.economy and config.economy.blacklistedroles and next(config.economy.blacklistedroles) then
					for _, role in pairs(config.economy.blacklistedroles) do
						blacklistedRoles = blacklistedRoles .. " " .. emojis.space .. emojis.right .. " <@&" .. role .. ">" .. "\n"
					end
				else
					blacklistedRoles = emojis.fail
				end

				return "## " .. emojis.quack .. " Server Economy\n" .. emojis.right .. " Ducky's " .. emojis.quack .. " **Server Economy** module allows for your members to have fun by collecting " .. emojis.quack .. " **Money**.\n### " .. emojis.settings .. " Configuration\n" ..
					emojis.right .. " **Module Enabled:** " .. ((config.economy and config.economy.disabled and emojis.fail) or emojis.success) .. "\n" ..
					emojis.right .. " **Currency:** " .. (config.economy and config.economy.currency or emojis.quack) .. "\n" ..
					emojis.right .. " **Initial Amount:** " .. (config.economy and formatNumber(tonumber(config.economy.initial or 0))) .. "\n" ..
					emojis.right .. " **Economy Log Channel:** " .. ((config.economylogchannel and "<#" .. config.economylogchannel .. ">") or emojis.fail) .. "\n" ..
					emojis.right .. " **Shop:** " .. (config.economy and ((config.economy.shop and next(config.economy.shop)) and emojis.success .. " (" .. #config.economy.shop .. " Items)") or emojis.fail) .. "\n" ..
					emojis.right .. " **Blacklisted Roles:** " .. (blacklistedRoles ~= emojis.fail and "\n" .. blacklistedRoles or " " .. emojis.fail .. "\n") ..
					emojis.right .. " **Custom Amounts:** " .. (amounts ~= emojis.fail and "\n" .. amounts or " " .. emojis.fail .. "\n") ..
					emojis.right .. " **Custom Replies:** " .. (replies ~= emojis.fail and "\n" .. replies or " " .. emojis.fail .. "\n") ..
					emojis.right .. " **Custom Cooldowns:** " .. (cooldowns ~= emojis.fail and "\n" .. cooldowns or " " .. emojis.fail .. "\n") ..
					emojis.right .. " **Collection Roles:** " .. (collectionRoles ~= emojis.fail and "\n" .. collectionRoles or " " .. emojis.fail .. "\n") ..
					emojis.right .. " **Multipliers:** " .. (multipliers ~= emojis.fail and "\n" .. multipliers or " " .. emojis.fail .. "\n")
			elseif pagenum == allPages.tickets.number then
				return "## " .. emojis.ticket .. " Tickets\n" .. emojis.right .. " Ducky's " .. emojis.ticket .. " **Tickets** module allows your community to create tickets for assistance.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Panels:**\n" .. emojis.space .. emojis.right .. " " .. ((config.panels and table.count(config.panels) > 0 and table.concatFn(config.panels, "\n" .. emojis.space .. emojis.right .. " ", function(p, id)
					return (p.disabled and emojis.power .. emojis.dot or "") .. "https://discord.com/channels/" .. interaction.guild.id .. "/" .. p.channel .. "/" .. id .. " (`" .. id .. "`)"
				end)) or "None")
			elseif pagenum == allPages.responders.number then
				--for _, ar in pairs(config.autoresponders or {}) do
				--	ar.response = sanitizeUTF8(ar.response)
				--end

				return "## " .. emojis.chat .. " Autoresponders\n" .. emojis.right .. " Ducky's " .. emojis.chat .. " **Autoresponders** module allows you to have Ducky automatically respond to certain keyphrases.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Autoresponders:**\n" .. emojis.space .. emojis.right .. " " .. ((config.autoresponders and table.count(config.autoresponders) > 0 and table.concatFn(config.autoresponders, "\n" .. emojis.space .. emojis.right .. " ", function(ar)
					return 
					ar.name .. " " .. ((ar.casesensitive and emojis.casesensitive) or "") .. (((not ar.matchexact) and emojis.search) or "")
					.. "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Trigger:** " .. ar.trigger
					.. "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Response:** " .. string.truncate(ar.response, 25)
					.. "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Delete Trigger:** " .. ((ar.deletetrigger and emojis.success) or emojis.fail)
					.. ((ar.cooldown and ar.cooldown > 0 and "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Cooldown:** " .. ((ar.cooldown and (ar.cooldown > 0) and readable(ar.cooldown)) or emojis.fail)) or "")
					.. ((ar.requiredrole and "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Required Role:** " .. ((ar.requiredrole and ("<@&" .. ar.requiredrole .. ">")) or emojis.fail)) or "")
					.. "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Enabled:** " .. ((ar.disabled and emojis.fail) or emojis.success)
				end)) or "None")
			elseif pagenum == allPages.giveaways.number then
				return "## " .. emojis.gift .. " Giveaways\n" .. emojis.right .. " Ducky's " .. emojis.gift .. " **Giveaways** module allows you to interact with your community and giveaway prizes.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Giveaway Embed:** " .. ((config.giveawayembeds and "Custom") or "Default") .. "\n" .. emojis.right .. " **Giveaway Blacklist Role:** " .. ((config.giveawayblacklist and "<@&" .. config.giveawayblacklist .. ">") or emojis.fail)
			elseif pagenum == allPages.boards.number then
				return "## " .. emojis.board .. " Reaction Boards\n" .. emojis.right .. " Ducky's " .. emojis.board .. " **Reaction Boards** module allows you to have customized starboards, which allow users to essentially vote to pin a message, but instead of pinning the message, it sends it to your board channel.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Reaction Boards:**\n" .. emojis.space .. emojis.right .. " " .. ((config.reactionboards and table.count(config.reactionboards) > 0 and table.concatFn(config.reactionboards, "\n" .. emojis.space .. emojis.right .. " ", function(board)
					return
					("<#" .. board.channel .. ">\n" 
					.. emojis.space .. emojis.space .. emojis.right .. " **Reaction:** `" .. board.reaction .. "`"
					.. "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Reactions Needed:** " .. board.reactionsneeded
					.. "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Enabled:** " .. ((board.disabled and emojis.fail) or emojis.success)
					.. "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Whitelisted Channels:** " .. ((board.whitelistedChannels and table.count(board.whitelistedChannels) > 0 and (table.concatFn(board.whitelistedChannels, ", ", function(c)
						return "<#" .. c .. ">"
					end))) or "All"))
				end)) or "None")
			elseif pagenum == allPages.messages.number then
				local autoReactChannels = ""
				if config.autoreactchannels and next(config.autoreactchannels) then
					for _, channel in ipairs(config.autoreactchannels) do
						autoReactChannels = autoReactChannels .. emojis.space .. emojis.right .. " <#" .. channel.channel .. ">" .. "\n" ..
							emojis.space .. emojis.space .. emojis.right .. " **Reaction:** " .. channel.reaction .. "\n" ..
							emojis.space .. emojis.space .. emojis.right .. " **React to Bots:** " .. ((channel.botreact and emojis.success) or emojis.fail) .. "\n"
					end
				else
					autoReactChannels = emojis.fail
				end

				return "## " .. emojis.send .. " Message Management\n" .. emojis.right .. " Ducky's " .. emojis.send .. " **Message Management** module allow you to create sticky messages, auto delete channels, and make your valuable messages require confirmation to purge. " .. "\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Sticky Messages:**\n" .. emojis.space .. emojis.right .. " " .. ((config.stickymessages and table.count(config.stickymessages) > 0 and table.concatFn(config.stickymessages, "\n" .. emojis.space .. emojis.right .. " ", function(sm)
					return
					("<#" .. sm.channel .. ">\n"
					.. emojis.space .. emojis.space .. emojis.right .. " **Content:** `" .. string.truncate(sm.content or emojis.fail, 50) .. "`\n"
					.. emojis.space .. emojis.space .. emojis.right .. " **Message:** https://discord.com/channels/" .. interaction.guild.id .. "/" .. sm.channel .. "/" .. (sm.activeMessage or ""))
				end)) or "None") .. "\n" .. emojis.right .. " **Autodelete Channels:**\n" .. emojis.space .. emojis.right .. " " .. ((config.autodeletechannels and table.count(config.autodeletechannels) > 0 and table.concatFn(config.autodeletechannels, "\n" .. emojis.space .. emojis.right .. " ", function(ad)
					return
					("<#" .. ad.channel .. ">\n"
					.. emojis.space .. emojis.space .. emojis.right .. " **Delay:** " .. readable(ad.delay)
					.. "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Enabled:** " .. ((ad.disabled and emojis.fail) or emojis.success)
					.. "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Delete Bot Messages:** " .. ((ad.botdelete and emojis.success) or emojis.fail)
					)
				end)) or "None") 
				.. "\n" .. emojis.right .. " **Autoreact Channels:** " .. (autoReactChannels ~= emojis.fail and "\n" .. autoReactChannels or " " .. emojis.fail .. "\n")
				.. emojis.right .. " **Valuable Messages:**\n" .. emojis.space .. emojis.right .. " " .. ((config.valuablemessages and table.count(config.valuablemessages) > 0 and table.concatFn(config.valuablemessages, "\n" .. emojis.space .. emojis.right .. " ", function(message)
					return ("https://discord.com/channels/" .. interaction.guild.id .. "/" .. message)
				end)) or "None")
			elseif pagenum == allPages.departments.number then
				local isDep, host = db:isDepartment(interaction.guild)
				return "## " .. emojis.guild .. " Departments\n" .. emojis.right .. " Ducky's " .. emojis.guild .. " **Departments** module allows you to manage departmental servers with ease.\n### " .. emojis.settings .. " Configuration\n" .. emojis.right .. " **Departments:**\n" .. emojis.space .. emojis.right .. " " .. ((config.departments and table.count(config.departments) > 0 and table.concatFn(config.departments, "\n" .. emojis.space .. emojis.right .. " ", function(depConfig, did)
					depConfig = depConfig or {}
					local d = Client:getGuild(did)

					if d then
						local append = d.name .. " (`" .. d.id .. "`)"

						for i, link in pairs(depConfig.linkedroles or {}) do
							if i == 1 then
								append = append .. "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Linked Roles:**"
							end

							local hostRole = interaction.guild:getRole(link.host)
							local departmentRole = d:getRole(link.department)

							append = append .. "\n" .. emojis.space .. emojis.space .. emojis.space .. " " .. emojis.right .. " " .. ((hostRole and hostRole.name) or ("*" .. emojis.error .. " Deleted Role*")) .. " (`" .. link.host .. "`) " .. emojis.link .. " " .. ((departmentRole and departmentRole.name) or ("*" .. emojis.error .. " Deleted Role*")) .. " (`" .. link.department .. "`)"
						end

						append = append .. "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Sync Nicknames:** " .. ((depConfig.syncnicknames and emojis.success) or emojis.fail)

						return append
					else
						return "*Unknown Guild (" .. did .. ")*"
					end
				end)) or "None") .. "\n" .. emojis.right .. " **Host Server:** " .. ((isDep and host and (host.name .. " (`" .. host.id .. "`)")) or emojis.fail)
			end
		end

		local function updatePage(pagenum, embed)
			if not embed then
				embed = {
					description = getEmbedDescription(pagenum)
				}
			end

			pages[pagenum].title = embed.title or pages[pagenum].title
			pages[pagenum].description = embed.description or pages[pagenum].description
			pages[pagenum].image = embed.image or pages[pagenum].image
			pages[pagenum].thumbnail = embed.thumbnail or pages[pagenum].thumbnail
			pages[pagenum].author = embed.author or pages[pagenum].author
			pages[pagenum].footer = embed.footer or pages[pagenum].footer
			pages[pagenum].color = embed.color or pages[pagenum].color

			updatePagination()
		end

		table.insert(pages, {
			description = getEmbedDescription(allPages.welcome.number),
			color = colors.info,
			components = getcomps(allPages.welcome.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selections = ia.data.values
				local first = selections and selections[1]

				if id == "actions" then
					if first == "prefix" then
						prompt(ia, "Edit Prefix", {
							{
								question = "What should Ducky's prefix be?",
								style = "short",
								required = false,
								min = 0,
								max = 5,
								default = config.prefix or "d!"
							}
						}, function(mia, responses)
							if mia then
								local response = (responses and responses["What should Ducky's prefix be?"] ~= "" and responses["What should Ducky's prefix be?"]) or "d!"

								modifyKey("prefix", response)
								mia:updateDeferred(true)
								updatePage(allPages.welcome.number)
							end
						end)
					elseif first == "disabledcommands" then
						prompt(ia, "Disable Commands", {
							{
								question = "What commands should be disabled?",
								placeholder = "Enter commands to disable, seperated by a comma. (i.e. \"say, feedback\")",
								required = false,
								style = "paragraph",
								default = ((config.disabledcommands and table.count(config.disabledcommands) > 0 and table.concat(config.disabledcommands, ", ") or ""))
							}
						}, function(mia, responses)
							if not mia then return end
							if not responses or not responses["What commands should be disabled?"] or responses["What commands should be disabled?"] == "" then
								modifyKey("disabledcommands", {})
								mia:updateDeferred(true)
								updatePage(allPages.welcome.number)
								return
							end

							local response = responses["What commands should be disabled?"]

							local queries = string.split(response:gsub(" *, *", ","), ",")
							local disabledcommands = {}

							for _, query in pairs(queries or {}) do
								query = query:lower():gsub("^%s*(.-)%s*$", "%1")

								if query ~= "" then
									local args = string.split(query, " ")
									local baseName = args[1]
									local subPath = table.concat(args, " ", 2)

									local command
									for _, c in pairs(_G.commands) do
										if c.name:lower() == baseName or table.find(c.aliases or {}, baseName) then
											command = c
											break
										end
									end

									if not command then
										mia:fail("Command `" .. baseName .. "` was not found.", nil, true)
										updatePage(allPages.welcome.number)
										return

									elseif command.name == "setup" then
										mia:fail("The `/setup` command cannot be disabled.", nil, true)
										updatePage(allPages.welcome.number)
										return

									elseif table.find(command.requiredPermissions, "BOT_DEVELOPER") then
										mia:fail("The `/" .. command.name .. "` command is locked to the " .. emojis.developer .. " **Ducky Development** team and cannot be disabled.", nil, true)
										updatePage(allPages.welcome.number)
										return

									elseif table.find(command.requiredPermissions, "SUPPORT") then
										mia:fail("The `/" .. command.name .. "` command is locked to the " .. emojis.support .. " **Ducky Support** team and cannot be disabled.", nil, true)
										updatePage(allPages.welcome.number)
										return
									end

									if subPath ~= "" then
										local valid = false
										local normalizedSub = subPath

										if command.subcommands then
											for key, value in pairs(command.subcommands) do
												if type(value) == "string" and value:lower() == subPath then
													valid = true
													break
												elseif type(key) == "string" then
													if key:lower() == subPath then
														valid = true
														break
													elseif type(value) == "table" and value.aliases then
														for _, alias in ipairs(value.aliases) do
															if alias:lower() == subPath then
																valid = true
																normalizedSub = key
																break
															end
														end
													end
												end
												if valid then break end
											end
										end

										if valid then
											table.insert(disabledcommands, command.name .. " " .. normalizedSub)
										else
											mia:fail("Subcommand `/" .. command.name .. " " .. subPath .. "` does not exist.", nil, true)
											updatePage(allPages.welcome.number)
											return
										end
									else
										table.insert(disabledcommands, command.name)
										end
									end
								end

								modifyKey("disabledcommands", disabledcommands)
								mia:updateDeferred(true)
								updatePage(allPages.welcome.number)
							end)
					elseif first == "commandblacklists" then
						config.commandblacklists = config.commandblacklists or {}
						config.commandblacklists.channels = config.commandblacklists.channels or {}
						config.commandblacklists.roles = config.commandblacklists.roles or {}

						optionsSelect(ia, "Select an option to edit...", function(opt)
							if opt == "channels" then
								channelSelect(ia, "Select channels to blacklist...", function(selectedIds)
									config.commandblacklists.channels = selectedIds or {}

									modifyKey("commandblacklists", config.commandblacklists)
									updatePage(allPages.welcome.number)
								end, true, 0, 25, config.commandblacklists.channels)

							elseif opt == "roles" then
								roleSelect(ia, "Select roles to blacklist...", function(selectedIds)
									config.commandblacklists.roles = selectedIds or {}

									modifyKey("commandblacklists", config.commandblacklists)
									updatePage(allPages.welcome.number)
								end, true, 0, 25, config.commandblacklists.roles)

							elseif opt == "bypasstoggle" then
								config.commandblacklists.manageserverbypass = not config.commandblacklists.manageserverbypass
								modifyKey("commandblacklists", config.commandblacklists)
								updatePage(allPages.welcome.number)
							end
						end, true, {
							{
								label = "Blacklisted Channels",
								value = "channels",
								emoji = resolvedEmojis.channel
							},
							{
								label = "Blacklisted Roles",
								value = "roles",
								emoji = resolvedEmojis.role
							},
							{
								label = (config.commandblacklists.manageserverbypass and "Disable Manage Server Bypass") or "Enable Manage Server Bypass",
								value = "bypasstoggle",
								emoji = (config.commandblacklists.manageserverbypass and resolvedEmojis.on) or resolvedEmojis.off
							}
						}, 1, nil, true)
					elseif first == "commandlogschannel" then
						channelSelect(ia, "Select a channel...", function(id)
							modifyKey("commandlogschannel", id)
							updatePage(allPages.welcome.number)
						end, true, 0, 1, config.commandlogschannel)
					elseif first == "editpermissions" then
						local comps = discordia.Components():selectMenu({
							id = "permissionselector",
							placeholder = "Select a permission...",
							options = {
								{
									label = "Edit Moderator Roles",
									value = "modroles",
									emoji = resolvedEmojis.moderate
								},
								{
									label = "Edit Administrator Roles",
									value = "adminroles",
									emoji = resolvedEmojis.quickfix
								},
								{
									label = "Edit ERLC Staff Roles",
									value = "erlcstaffroles",
									emoji = resolvedEmojis.moderate
								},
								{
									label = "Edit ERLC Administrator Roles",
									value = "erlcadminroles",
									emoji = resolvedEmojis.quickfix
								},
								{
									label = "Edit ERLC Manager Roles",
									value = "erlcmanagerroles",
									emoji = resolvedEmojis.settings
								},
								{
									label = "Edit Session Starter Roles",
									value = "sessionstarterroles",
									emoji = resolvedEmojis.game
								}
							}
						}):raw()

						local r = ia:reply({
							components = comps
						}, true)

						onComp(r, nil, nil, ia.user.id, false, function(ria)
							local id = ria.data.custom_id
							local selections = ria.data.values
							local first = selections and selections[1]

							if id == "permissionselector" then
								if first then
									roleSelect(ria, "Select roles for this permission...", function(roles)
										modifyKey(first, roles)

										ia:editReply({
											components = comps
										}, r.id)
										updatePage(allPages.welcome.number)
									end, true, 0, 5, config[first], true)
								else
									ria:updateDeferred(true)
								end
							end
						end)
					elseif first == "configlogchannel" then
						channelSelect(ia, "Select a channel...", function(id)
							modifyKey("configlogchannel", id)
							updatePage(allPages.welcome.number)
						end, true, 0, 1, config.configlogchannel)
					elseif first == "wipeconfiguration" then
						if ia.user.id == interaction.guild.ownerId then
							confirm(ia, "Are you sure you would like to wipe **" .. interaction.guild.name .. "**'s configuration?", function(result, ria, r)
								if result == true then
									local success, err = sqldb:delete(interaction.guild.id)

									if success then
										utilityChannels.database:send(emojis.delete .. " **@" .. interaction.user.username .. "** has wiped **" .. interaction.guild.name .. "**'s configuration.\n-# " .. emojis.clock .. " <t:" .. os.time() .. ":T>・" .. emojis.guild .. " `" .. interaction.guild.id .. "`・" .. emojis.edit .. " Manually wiped.")
										ria:updateDeferred(true)
										pagination:update({
											embed = {
												description = emojis.success .. " This server's configuration has been successfully wiped.",
												color = colors.success
											},
											components = {}
										})
										return
									else
										ria:fail(tostring(err), nil, true)
									end
								else
									ria:deleteReply(r.id)
									return ria:updateDeferred(true)
								end
							end, false, 10000)
						else
							return ia:fail("Only the server's owner, <@" .. interaction.guild.ownerId .. ">, can wipe **" .. interaction.guild.name .. "**'s configuration.")
						end
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Welcome to Ducky",
				emoji = resolveEmoji(emojis.ducky)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.dcmod.number),
			color = colors.info,
			components = getcomps(allPages.dcmod.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				if id == "actions" then
					if selection == "modlogchannel" then
						channelSelect(ia, "Select a modlogs channel...", function(channel)
							modifyKey("modlogchannel", channel)
							updatePage(allPages.dcmod.number)
						end, true, nil, nil, config.modlogchannel)
					elseif selection == "appealLinks" then
						optionsSelect(ia, "Select Type...", function(opt, cia)
							local question = opt .. " Appeal Link"

							prompt(cia, "Appeal Link", {
								{
									question = question,
									placeholder = "https://appeal.gg",
									style = "short",
									required = false
								}
							}, function(mia, response)
								if mia then
									config.appealLinks = config.appealLinks or {}
									if response and type(response[question]) == "string" and response[question]:len() > 10 and (select(2, response[question]:gsub("https?://[%w-_%.%?%.:/]+", ""))) > 0 then
										config.appealLinks[opt] = response[question]
										modifyKey("appealLinks", config.appealLinks)
										updatePage(allPages.dcmod.number)
									elseif config.appealLinks[opt] then
										config.appealLinks[opt] = nil
										modifyKey("appealLinks", config.appealLinks)
										updatePage(allPages.dcmod.number)
									else
										updatePage(allPages.dcmod.number)
										return mia:fail("Please provide a valid URL.", nil, true)
									end
								end
							end, true)
						end, true, appealOptions, 1, nil, true)
					elseif selection == "discordstaffimmunity" then
						modifyKey("discordstaffimmunity", not config.discordstaffimmunity)
						ia:updateDeferred(true)
						updatePage(allPages.dcmod.number)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Discord Moderation",
				emoji = resolveEmoji(emojis.moderate)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.audit.number),
			color = colors.info,
			components = getcomps(allPages.audit.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				if id == "actions" then
					if selection == "primaryauditlogchannel" then
						channelSelect(ia, "Select a primary log channel...", function(channelID, r)
							ia:deleteReply(r.id)

							config.auditlogchannels = config.auditlogchannels or {}
							config.auditlogchannels.primary = config.auditlogchannels.primary or {}

							local function createPrimaryWebhook(channel)
								local existingWebhookData = config.auditlogchannels.primary.webhook
								local existingWebhook = existingWebhookData and Client:getWebhook(existingWebhookData.ID)

								if existingWebhook and existingWebhook.channelId ~= channel.id then
									existingWebhook:delete()
								end

								local webhook, err = channel:createWebhook("Ducky", "for Ducky's audit logging module")
								if not webhook then
									return ia:fail("Failed to create a webhook.\n-# " .. emojis.right .. " Make sure Ducky has the right permissions, and contact our [support server](https://duckybot.xyz/support) for assistance.", nil, true)
								end

								webhook:setAvatar("./images/avatars/Ducky.png")
								config.auditlogchannels.primary.webhook = { ID = webhook.id, TOKEN = webhook.token }
							end

							if channelID then
								local channel = interaction.guild:getChannel(channelID)
								if not channel then
									return ia:fail("That channel does not exist or Ducky does not have permission to view it.\n-# " .. emojis.right .. " Contact our [support server](https://duckybot.xyz/support) if you need assistance.", nil, true)
								end
								createPrimaryWebhook(channel)
							else
								local existingWebhookData = config.auditlogchannels.primary.webhook
								local existingWebhook = existingWebhookData and Client:getWebhook(existingWebhookData.ID)
								if existingWebhook then existingWebhook:delete() end
								config.auditlogchannels.primary.webhook = nil
							end

							config.auditlogchannels.primary.channel = channelID
							if next(config.auditlogchannels.primary) == nil then
								config.auditlogchannels.primary = nil
							end
							modifyKey("auditlogchannels", config.auditlogchannels)
							updatePage(allPages.audit.number)
						end, true, nil, 1, config.auditlogchannels and config.auditlogchannels.primary and config.auditlogchannels.primary.channel)

					elseif selection == "auditlogchannels" then
						optionsSelect(ia, "Select an audit type...", function(selected, oia)
							local auditlabel
							local auditString
							for _, audit in ipairs(auditTypes) do
								if audit.value == selected then
									auditlabel = audit.label
									auditString = audit.emoji.raw .. " " .. audit.label
									break
								end
							end

							if config.audittypes and (not table.find(config.audittypes, selected)) then
								return oia:fail("You have not enabled the **" .. auditString .. "** audit type.", nil, true)
							end
							channelSelect(oia, "Select channel for the " .. auditlabel .. " audit...", function(channelID, r)
								oia:deleteReply(r.id)

								config.auditlogchannels = config.auditlogchannels or {}
								config.auditlogchannels[selected] = config.auditlogchannels[selected] or {}

								if channelID then
									local channel = oia.guild:getChannel(channelID)
									if not channel then
										return oia:fail("That channel does not exist or Ducky doesn’t have permission to view it.\n-# " .. emojis.right .. " Contact our [support server](https://duckybot.xyz/support) if you need assistance.", nil, true)
									end

									local existingWebhook
									for _, data in pairs(config.auditlogchannels) do
										if data.webhook and data.channel == channelID then
											existingWebhook = Client:getWebhook(data.webhook.ID)
											if existingWebhook then break end
										end
									end

									if not existingWebhook then
										local webhook, err = channel:createWebhook("Ducky", "for Ducky's audit logging module (" .. auditlabel .. ")")
										if not webhook then
											return oia:fail("Failed to create a webhook.\n-# " .. emojis.right .. " Make sure Ducky has the right permissions, and contact our [support server](https://duckybot.xyz/support) for assistance.", nil, true)
										end
										webhook:setAvatar("./images/avatars/Ducky.png")
										existingWebhook = webhook
									end

									config.auditlogchannels[selected].webhook = { ID = existingWebhook.id, TOKEN = existingWebhook.token }
									config.auditlogchannels[selected].channel = channelID

								else
									local existingWebhook = config.auditlogchannels[selected].webhook and Client:getWebhook(config.auditlogchannels[selected].webhook.ID)

									local stillUsed = false
									if existingWebhook then
										for key, data in pairs(config.auditlogchannels) do
											if key ~= selected and data.webhook and data.webhook.ID == existingWebhook.id then
												stillUsed = true
												break
											end
										end
										if not stillUsed then existingWebhook:delete() end
									end

									config.auditlogchannels[selected] = nil
								end

								modifyKey("auditlogchannels", config.auditlogchannels)
								updatePage(allPages.audit.number)
							end, true, 0, 1, config.auditlogchannels and config.auditlogchannels[selected] and config.auditlogchannels[selected].channel)
						end, true, auditTypes, 1, nil, true)
					elseif selection == "audittypes" then
						optionsSelect(ia, "Select audit types...", function(selections)
							modifyKey("audittypes", selections)
							updatePage(allPages.audit.number)
						end, true, auditTypes, nil, config.audittypes)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Audit Logging",
				emoji = resolveEmoji(emojis.log)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.erlc.number),
			color = colors.info,
			components = getcomps(allPages.erlc.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				if id == "actions" then
					if selection == "ingamerole" then
						roleSelect(ia, "Select a role for in-game users...", function(role)
							modifyKey("ingamerole", role)
							updatePage(allPages.erlc.number)
						end, true, nil, nil, config.ingamerole)
					elseif selection == "erlccmdschannel" then
						channelSelect(ia, "Select the commands webhook channel...", function(c)
							modifyKey("erlccmdschannel", c)
							updatePage(allPages.erlc.number)
						end, true, nil, nil, config.erlccmdschannel)
					elseif selection == "erlckickbanchannel" then
						channelSelect(ia, "Select the kick/bans webhook channel...", function(c)
							modifyKey("erlckickbanchannel", c)
							updatePage(allPages.erlc.number)
						end, true, nil, nil, config.erlckickbanchannel)
					elseif selection == "erlcautologkickbolo" then
						if config.erlckickbanchannel then
							modifyKey("erlcautologkickban", not config.erlcautologkickban)
							ia:updateDeferred(true)
							updatePage(allPages.erlc.number)
						else
							ia:fail("You must first set a **ERLC Kick/Ban Logs Channel**.", nil, true)
						end
					elseif selection == "erlcbansync" then
						if not config.apikey then
							updatePage(allPages.erlc.number)
							return ia:fail("You must first link your ERLC server.", nil, true)
						end

						if not config.erlckickbanchannel then
							updatePage(allPages.erlc.number)
							return ia:fail("You must first set a **ERLC Kick/Ban Logs Channel**.", nil, true)
						end

						if not config.erlccmdschannel then
							updatePage(allPages.erlc.number)
							return ia:fail("You must first set a **ERLC Command Logs Channel**.", nil, true)
						end

						optionsSelect(ia, "Select a Ban Syncing Mode...", function(opt)
							if opt == "disable" then
								modifyKey("erlcbansync")
							else
								modifyKey("erlcbansync", opt)
							end

							updatePage(allPages.erlc.number)
						end, true, banSyncingOptions, 1, nil, true)
					elseif selection == "apikey" then
						prompt(ia, "Link ERLC Server", {
							{
								question = "What is your server's ERLC API key?",
								placeholder = "Enter it here...",
								style = "short",
								required = false,
							}
						}, function(mia, responses)
							local key = responses and responses["What is your server's ERLC API key?"]

							local server = key and ERLC:getServer(key)

							if server then
								modifyKey("apikey", key)
								ERLCServer = server
								updatePage(allPages.erlc.number)
							elseif key then
								mia:fail("You provided an invalid API key.", nil, true)
								updatePage(allPages.erlc.number)
							else
								modifyKey("apikey", nil)
								modifyKey("erlccache", nil)
								ERLCServer = nil
								updatePage(allPages.erlc.number)
							end
						end, true)
					elseif selection == "advancederlccmdperms" then
						modifyKey("advancederlccmdperms", not config.advancederlccmdperms)
						ia:updateDeferred(true)
						updatePage(allPages.erlc.number)
					elseif selection == "addplaytimereward" then
						prompt(ia, "Add Playtime Reward", {
							{
								question = "How much time is required for this reward?",
								placeholder = "Enter a valid amount of time...",
								required = true,
								style = "short",
								validate = function(response)
									local playtime = response and convert(response)
									
									if not playtime then
										return false, "You did not provide a valid amount of time required for this playtime reward."
									elseif table.find(config.erlcplaytimerewards or {}, function(reward)
										return reward.playtime == playtime
									end) then
										return false, "There is already a reward for this amount of playtime."
									end
									
									return playtime
								end
							},
							{
								question = "Which role should be rewarded?",
								component = discordia.SelectMenu({
									id = "rewardrole",
									placeholder = "Select a rewarded role...",
									min_values = 1,
									max_values = 1,
									type = "role"
								}):raw()
							}
						}, function(mia, responses)
							if mia then
								local playtime = responses and responses["How much time is required for this reward?"]
								local role = responses and responses["Which role should be rewarded?"]
								
								config.erlcplaytimerewards = config.erlcplaytimerewards or {}
								table.insert(config.erlcplaytimerewards, {
									playtime = playtime,
									role = role
								})
								modifyKey("erlcplaytimerewards", config.erlcplaytimerewards)
								updatePage(allPages.erlc.number)
							end
						end, true)
					elseif selection == "removeplaytimereward" then
						if not (config.erlcplaytimerewards and next(config.erlcplaytimerewards)) then
							return ia:fail("You have not added any playtime rewards.", nil, true)
						end

						local options = {}
						for i, reward in pairs(config.erlcplaytimerewards) do
							local role = interaction.guild:getRole(reward.role)

							table.insert(options, {
								label = string.truncate(role and role.name or reward.role, 100),
								description = readable(reward.playtime) .. " of playtime required",
								value = i,
								emoji = resolvedEmojis.delete
							})
						end


						optionsSelect(ia, "Select a playtime reward...", function(opt)
							table.remove(config.erlcplaytimerewards, tonumber(opt))
							modifyKey("erlcplaytimerewards", config.erlcplaytimerewards)
							updatePage(allPages.erlc.number)
						end, true, options, 1, nil, true)
					elseif selection == "playtimechannel" then  
						channelSelect(ia, "Select a channel to announce rewards...", function(channel)
							modifyKey("erlcplaytimechannel", channel)
							updatePage(allPages.erlc.number)
						end, true, 0, 1, config.erlcplaytimechannel)
					elseif selection == "playtimemessage" then
						messageEditor(ia, function(message)
							modifyKey("erlcplaytimemessage", message)
							updatePage(allPages.erlc.number)
						end, emojis.right .. " **`{member.mention}`:** The mention of the member that received the reward.\n" .. emojis.right .. " **`{member.name}`:** The name of the member that received the reward.\n" .. emojis.right .. "**`{member.username}`:** The username of the member that received the reward.\n" .. emojis.right .. " **`{member.id}`:** The ID of the member that received the reward.\n" .. emojis.right .. " **`{member.username}`:** The username of the member that received the reward.\n" .. emojis.right .. " **`{member.playtime}`:** The amount of playtime the member has.\n" .. emojis.right .. " **`{reward.mention}`:** The mention of the reward.\n" .. emojis.right .. " **`{reward.name}`:** The name of the reward.\n" .. emojis.right .. " **`{reward.id}`:** The ID of the reward.\n" .. emojis.right .. " **`{reward.playtime}`:** The amount of playtime required for this reward.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The current Unix Epoch timestamp.", config.erlcplaytimemessage)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "ERLC Integration",
				emoji = resolveEmoji(emojis.game)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.erlcRegions.number),
			color = colors.info,
			components = getcomps(allPages.erlcRegions.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				config.regions = config.regions or {}

				if id == "actions" then
					if selection == "createregion" then
						local regionLimit = isPlusGuild and featureLimits.regions.plus or featureLimits.regions.normal
						local pointLimit = isPlusGuild and featureLimits.regionPoints.plus or featureLimits.regionPoints.normal
						if table.count(config.regions or {}) >= regionLimit then
							return ia:fail("You have already created " .. table.count(config.regions) .. "/" .. regionLimit .. " regions for this server.", nil, true)
						end

						local r
						local session = webEditor(interaction.member, "region", os.time() + convert("15m"), function(data)
							local name = data.name and data.name ~= "" and data.name or nil
							
							if not name then
								return false, "A name was not provided for this region."
							elseif not data.points or #data.points < 3 then
								return false, "At least 3 points are required to create a region."
							elseif #data.points > pointLimit then
								return false, "The region must be composed of no more than " .. pointLimit .. " points."
							elseif table.count(config.regions or {}) >= regionLimit then
								return false, "You have already created " .. table.count(config.regions) .. "/" .. regionLimit .. " regions for this server."
							elseif table.find(config.regions or {}, function(reg)
								return reg.name:gsub("%s+", ""):lower() == data.name:gsub("%s+", ""):lower()
							end) then
								return false, "A region already exists with that name."
							end

							table.sort(data.points, function(a, b)
								return a.index > b.index
							end)

							local Region = erlua.Region(data.name, data.points)
							if not Region then
								return false, "An unexpected error occurred while attempting to create the region."
							end

							local config = sqldb:get(interaction.guild.id) or {}
							config.regions = config.regions or {}
							table.insert(config.regions, data)
							modifyKey("regions", config.regions)
							updatePage(allPages.erlcRegions.number)

							if r then
								ia:editReply({
									embed = {
										description = emojis.success .. " You have successfully created the **" .. data.name .. "** region.",
										color = colors.success
									},
									components = {}
								}, r.id)
							end

							return true
						end)

						if session then
							r = ia:reply({
								embed = {
									description = emojis.edit .. " You may use the following web editor session to create a region:",
									color = colors.yellow
								},
								components = discordia.Components()
									:button({
										style = "link",
										url = session.url,
										label = "Create Region",
										emoji = resolvedEmojis.map
									})
									:raw()
							}, true)
						else
							return ia:fail("An unexpected error occurred while attempting to create your web editor session: " .. tostring(err), nil, true)
						end
					elseif selection == "deleteregion" then
						if (not config.regions) or (table.count(config.regions) <= 0) then
							return ia:fail("You have not created any regions.", nil, true)
						end

						local options = {}

						for i, region in pairs(config.regions) do
							local Region = erlua.Region(region.name, region.points)
							table.insert(options, {
								label = Region.name,
								description = formatNumber(Region.area) .. " studs², " .. #region.points .. " points",
								emoji = resolvedEmojis.delete,
								value = tostring(i)
							})
						end

						optionsSelect(ia, "Select a region to delete...", function(index)
							table.remove(config.regions, tonumber(index))
							modifyKey("regions", config.regions)
							updatePage(allPages.erlcRegions.number)
						end, true, options, 1, nil, true)
					elseif selection == "linkvc" then
						local options = {}

						for i, region in pairs(config.regions) do
							local Region = erlua.Region(region.name, region.points)
							table.insert(options, {
								label = Region.name,
								description = formatNumber(Region.area) .. " studs², " .. #region.points .. " points",
								emoji = resolvedEmojis.map,
								value = tostring(i)
							})
						end

						if table.count(options) <= 0 then
							return ia:fail("You have not created any regions yet.", nil, true)
						elseif #interaction.guild.voiceChannels <= 0 then
							return ia:fail("There are no voice channels in this server.", nil, true)
						end

						prompt(ia, "Link Voice Channel to Region", {
							{
								question = "Which region should be linked?",
								component = discordia.SelectMenu({
									id = "region",
									placeholder = "Select a region...",
									options = options,
									max_values = 1,
									required = true
								}):raw()
							},
							{
								question = "Which voice channel should be linked?",
								component = discordia.SelectMenu({
									id = "voicechannel",
									placeholder = "Select a voice channel...",
									type = "channel",
									channel_types = {2},
									max_values = 1,
									required = true
								}):raw()
							}
						}, function(mia, responses)
							if mia then
								local region = responses and responses["Which region should be linked?"] and tonumber(responses["Which region should be linked?"])
								local channel = responses and responses["Which voice channel should be linked?"] and interaction.guild:getChannel(responses["Which voice channel should be linked?"])

								if (not region) or (not config.regions[region]) then
									mia:fail("You did not select a region.", nil, true)
									return updatePage(allPages.erlcRegions.number)
								elseif not channel then
									mia:fail("You did not select a voice channel.", nil, true)
									return updatePage(allPages.erlcRegions.number)
								end

								config.regions[region].voiceChannel = channel.id
								modifyKey("regions", config.regions)

								mia:updateDeferred(true)
								return updatePage(allPages.erlcRegions.number)
							end
						end)
					elseif selection == "unlinkvc" then
						local options = {}

						for i, region in pairs(config.regions) do
							if region.voiceChannel then
								local Region = erlua.Region(region.name, region.points)
								table.insert(options, {
									label = Region.name,
									description = formatNumber(Region.area) .. " studs², " .. #region.points .. " points",
									emoji = resolvedEmojis.map,
									value = tostring(i)
								})
							end
						end

						if table.count(config.regions) <= 0 then
							return ia:fail("You have not created any regions yet.", nil, true)
						elseif table.count(options) <= 0 then
							return ia:fail("You have not linked any regions to a voice channel yet.", nil, true)
						end

						optionsSelect(ia, "Select a region to unlink...", function(index)
							config.regions[tonumber(index)].voiceChannel = nil
							modifyKey("regions", config.regions)
							updatePage(allPages.erlcRegions.number)
						end, true, options, 1, nil, true)
					elseif selection == "regionwaitingvc" then
						channelSelect(ia, "Select a voice channel...", function(vc)
							modifyKey("regionwaitingvc", vc)
							updatePage(allPages.erlcRegions.number)
						end, true, 0, 1, config.regionwaitingvc, {2})
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "ERLC Regions",
				emoji = resolveEmoji(emojis.map)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.erlcStatus.number),
			color = colors.info,
			components = getcomps(allPages.erlcStatus.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				local vars = emojis.right .. " **`{server.name}`:** The in-game server's name.\n" .. emojis.right .. " **`{server.players}`:** The in-game server's current playercount.\n" .. emojis.right .. " **`{server.maxplayers}`:** The in-game server's maximum playercount.\n" .. emojis.right .. " **`{server.staff}`:** The in-game server's current staff count.\n" .. emojis.right .. " **`{server.queue}`:** The in-game server's current queue count.\n" .. emojis.right .. " **`{server.code}`:** The in-game server's join code.\n" .. emojis.right .. " **`{owner.name}`:** The in-game server owner's username.\n" .. emojis.right .. " **`{owner.display}`:** The in-game server owner's display name.\n" .. emojis.right .. " **`{owner.id}`:** The in-game server owner's ID.\n" .. emojis.right .. " **`{owner.profile}`:** The link to the in-game server owner's profile.\n" .. emojis.right .. " **`{owner.hyperlink}`:** The in-game server owner's username hyperlinked to their profile.\n" .. emojis.right .. " **`{team.civilian}`:** The current amount of players on the Civilian team.\n" .. emojis.right .. " **`{team.sheriff}`:** The current amount of players on the Sheriff team.\n" .. emojis.right .. " **`{team.fire}`:** The current amount of players on the Firefighter team.\n" .. emojis.right .. " **`{team.police}`:** The current amount of players on the Police team.\n" .. emojis.right .. " **`{team.dot}`:** The current amount of players on the DOT team.\n" .. emojis.right ..
					             " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of which the server status message was last updated."
				local statusmsgKeys = {
					["server.name"] = emojis.loading,
					["server.players"] = emojis.loading,
					["server.staff"] = emojis.loading,
					["server.maxplayers"] = emojis.loading,
					["server.queue"] = emojis.loading,
					["server.code"] = emojis.loading,
					["owner.name"] = emojis.loading,
					["owner.display"] = emojis.loading,
					["owner.id"] = emojis.loading,
					["owner.profile"] = emojis.loading,
					["owner.hyperlink"] = emojis.loading,
					["team.dot"] = emojis.loading,
					["team.fire"] = emojis.loading,
					["team.police"] = emojis.loading,
					["team.sheriff"] = emojis.loading,
					["team.jail"] = emojis.loading,
					["team.civilian"] = emojis.loading,
					["timestamp"] = os.time()
				}

				if id == "actions" then
					if selection == "statusmessage" then
						local default = (config.erlcserverstatusmessage and config.erlcserverstatusmessage.tosend) or nil

						if default and default.embed and not default.embeds then
							default.embeds = {
								default.embed
							}
							default.embed = nil
						end

						messageEditor(ia, function(builtMsg)
							if not builtMsg then
								return
							end

							local statusChannel = interaction.guild:getChannel(builtMsg.channel)

							if statusChannel then
								local statusMessage, e = statusChannel:send(parseTable({
									content = builtMsg.content,
									embeds = builtMsg.embeds
								}, statusmsgKeys))

								if statusMessage then
									modifyKey("erlcserverstatusmessage", {
										channel = builtMsg.channel,
										message = statusMessage.id,
										tosend = {
											content = builtMsg.content,
											embeds = builtMsg.embeds
										}
									})

									updatePage(allPages.erlcStatus.number)
								else
									ia:fail("Failed to send message: ```" .. e .. "```", nil, true)
								end
							else
								ia:fail("Failed to find channel, please make sure Ducky has permissions to view the channel.", nil, true)
							end
						end, vars, default, true)
					elseif selection == "erlcserverstatusvars" then
						ia:reply({
							embed = {
								title = emojis.json .. " Variables",
								description = vars,
								color = colors.blank
							}
						}, true)

						updatePage(allPages.erlcStatus.number)
					elseif selection == "createstatuschannel" then
						if checkLimit(ia, "status channels", isPlusGuild, config.erlcserverstatuschannels, "erlcStatusChannels") then
							return
						end

						prompt(ia, "ERLC Server Status Channel", {
							{
								question = "Channel Name",
								placeholder = "Go back to view variables.",
								style = "short",
								required = true
							}
						}, function(mia, response)
							if mia and response and response["Channel Name"] and response["Channel Name"] ~= "" then
								local name = response["Channel Name"]

								if name:len() < 1 or name:len() > 100 then
									updatePage(allPages.erlcStatus.number)
									return mia:fail("You must provide a name between 1 and 100 characters.", nil, true)
								end

								local new, replaced = parseTable({
									name
								}, statusmsgKeys)

								if replaced < 1 then
									updatePage(allPages.erlcStatus.number)
									return mia:fail("You need to use at least 1 variable.", nil, true)
								end

								if new and new[1] then
									new[1] = new[1]:gsub(emojis.loading, "⏳")

									local voiceChannel, err = interaction.guild:createVoiceChannel(new[1])

									if type(voiceChannel) == "table" then
										coroutine.wrap(function()
											local overwrite = voiceChannel:getPermissionOverwriteFor(interaction.guild.defaultRole)
											if overwrite then
												overwrite:setPermissions({
													discordia.enums.readMessages
												}, {
													discordia.enums.permission.sendMessages,
													discordia.enums.permission.connect,
													discordia.enums.permission.speak
												})
											end
										end)()
										config.erlcserverstatuschannels = config.erlcserverstatuschannels or {}
										table.insert(config.erlcserverstatuschannels, {
											channel = voiceChannel.id,
											content = name
										})

										modifyKey("erlcserverstatuschannels", config.erlcserverstatuschannels)
									else
										mia:fail("Failed to create voice channel: ```" .. err .. "```", nil, true)
									end
								else
									mia:fail("Something went wrong, please try again or contact [Ducky Support](https://discord.gg/j4w5ZcbRyh).", nil, true)
								end

								updatePage(allPages.erlcStatus.number)
							end
						end, true)
					elseif selection == "editstatuschannel" then
						if not config.erlcserverstatuschannels or table.count(config.erlcserverstatuschannels) < 1 then
							updatePage(allPages.erlcStatus.number)
							return ia:fail("You have not created any ERLC server status channels.", nil, true)
						end

						if checkLimit(ia, "status channels", isPlusGuild, config.erlcserverstatuschannels, "erlcStatusChannels", true) then
							return
						end

						local options = {}

						local modified = false

						for i, v in pairs(config.erlcserverstatuschannels) do
							local channel = interaction.guild:getChannel(v.channel)

							if channel then
								table.insert(options, {
									label = "#" .. tostring(i),
									description = string.truncate(channel.name, 100),
									value = tostring(i) .. ":" .. v.channel,
									emoji = resolvedEmojis.channel
								})
							else
								table.remove(config.erlcserverstatuschannels, i)
								modified = true
							end
						end

						if modified then
							modifyKey("erlcserverstatuschannels", config.erlcserverstatuschannels)
						end

						if table.count(options) < 1 then
							return ia:fail("You have not created any ERLC server status channels.", nil, true)
						end

						optionsSelect(ia, "Select status channel...", function(selection, cia)
							local splitSelection = string.split(selection, ":")
							local i = splitSelection[1]
							local channelID = splitSelection[2]

							local voiceChannel = interaction.guild:getChannel(channelID)

							if voiceChannel then
								prompt(cia, "ERLC Server Status Channel", {
									{
										question = "Channel Name",
										placeholder = "Go back to view variables.",
										default = config.erlcserverstatuschannels[tonumber(i)].content,
										style = "short",
										required = true
									}
								}, function(mia, response)
									if mia and response and response["Channel Name"] and response["Channel Name"] ~= "" then
										local name = response["Channel Name"]

										if name:len() < 1 or name:len() > 100 then
											updatePage(allPages.erlcStatus.number)
											return mia:fail("You must provide a name between 1 and 100 characters.", nil, true)
										end

										local new, replaced = parseTable({
											name
										}, statusmsgKeys)

										if replaced < 1 then
											updatePage(allPages.erlcStatus.number)
											return mia:fail("You need to use at least 1 variable.", nil, true)
										end

										if new and new[1] then
											new[1] = new[1]:gsub(emojis.loading, "⏳")

											voiceChannel:setName(new[1])

											config.erlcserverstatuschannels = config.erlcserverstatuschannels or {}
											config.erlcserverstatuschannels[tonumber(i)] = {
												channel = voiceChannel.id,
												content = name
											}

											modifyKey("erlcserverstatuschannels", config.erlcserverstatuschannels)
										else
											mia:fail("Something went wrong, please try again or contact [Ducky Support](https://discord.gg/j4w5ZcbRyh).", nil, true)
										end

										updatePage(allPages.erlcStatus.number)
									end
								end, true)
							else
								return cia:fail("I could not find that channel.")
							end
						end, true, options, 1, nil, true)
					elseif selection == "removestatuschannel" then
						if not config.erlcserverstatuschannels or table.count(config.erlcserverstatuschannels) < 1 then
							updatePage(allPages.erlcStatus.number)
							return ia:fail("You have not created any ERLC server status channels.", nil, true)
						end

						local options = {}

						local modified = false

						for i, v in pairs(config.erlcserverstatuschannels) do
							local channel = interaction.guild:getChannel(v.channel)

							if channel then
								table.insert(options, {
									label = "#" .. tostring(i),
									value = tostring(i) .. ":" .. v.channel,
									description = string.truncate(channel.name, 100),
									emoji = resolvedEmojis.channel
								})
							else
								table.remove(config.erlcserverstatuschannels, i)
								modified = true
							end
						end

						if modified then
							modifyKey("erlcserverstatuschannels", config.erlcserverstatuschannels)
						end

						if table.count(options) < 1 then
							return ia:fail("You have not created any ERLC server status channels.", nil, true)
						end

						optionsSelect(ia, "Select status channel...", function(selection, cia)
							local splitSelection = string.split(selection, ":")
							local i = splitSelection[1]
							local channelID = splitSelection[2]

							local voiceChannel = interaction.guild:getChannel(channelID)

							if voiceChannel then
								voiceChannel:delete()
								config.erlcserverstatuschannels[tonumber(i)] = nil
								modifyKey("erlcserverstatuschannels", config.erlcserverstatuschannels)

								updatePage(allPages.erlcStatus.number)
							else
								return cia:fail("I could not find that channel.")
							end
						end, true, options, 1, nil, true)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "ERLC Server Status",
				emoji = resolveEmoji(emojis.network)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.erlcLog.number),
			color = colors.info,
			components = getcomps(allPages.erlcLog.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				if id == "actions" then
					if not config.apikey then
						return ia:fail("This feature requires for you to link your ERLC API Key with Ducky via the " .. emojis.game .. " **ERLC Integration** page in `/setup`.", nil, true)
					end

					if config.erlclogs and next(config.erlclogs) then
						for i, log in pairs(config.erlclogs) do
							if log.tosend then
								if log.tosend.embed and not log.tosend.embeds then
									config.erlclogs[i].tosend.embeds = {
										log.tosend.embed
									}
									config.erlclogs[i].tosend.embed = nil
								end
							end
						end
					end

					if selection == "playerjoin" then
						local vars = emojis.right .. " **`{player.name}`:** The name of the player that joined.\n" .. emojis.right .. " **`{player.id}`:** The ID of the player that joined.\n" .. emojis.right .. " **`{player.profile}`:** The link to the player's profile that joined.\n" .. emojis.right .. " **`{player.hyperlink}`:** The hyperlink to the player's profile that joined.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the player joined."

						messageEditor(ia, function(builtMsg)
							if builtMsg then
								config.erlclogs = config.erlclogs or {}
								config.erlclogs.playerjoin = {
									channel = builtMsg.channel,
									tosend = {
										content = builtMsg.content,
										embeds = builtMsg.embeds
									}
								}
							elseif config.erlclogs and config.erlclogs.playerjoin then
								config.erlclogs.playerjoin = nil
							end

							modifyKey("erlclogs", config.erlclogs)
							updatePage(allPages.erlcLog.number)
						end, vars, (config.erlclogs and config.erlclogs.playerjoin and config.erlclogs.playerjoin.tosend) or {
							content = emojis.add .. " **<t:{timestamp}:T>**・{player.hyperlink} joined the server."
						}, true)
					elseif selection == "playerleave" then
						local vars = emojis.right .. " **`{player.name}`:** The name of the player that left.\n" .. emojis.right .. " **`{player.id}`:** The ID of the player that left.\n" .. emojis.right .. " **`{player.profile}`:** The link to the player's profile that left.\n" .. emojis.right .. " **`{player.hyperlink}`:** The hyperlink to the player's profile that left.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the player left."

						messageEditor(ia, function(builtMsg)
							if builtMsg then
								config.erlclogs = config.erlclogs or {}
								config.erlclogs.playerleave = {
									channel = builtMsg.channel,
									tosend = {
										content = builtMsg.content,
										embeds = builtMsg.embeds
									}
								}
							elseif config.erlclogs and config.erlclogs.playerleave then
								config.erlclogs.playerleave = nil
							end

							modifyKey("erlclogs", config.erlclogs)
							updatePage(allPages.erlcLog.number)
						end, vars, (config.erlclogs and config.erlclogs.playerleave and config.erlclogs.playerleave.tosend) or {
							content = emojis.subtract .. " **<t:{timestamp}:T>**・{player.hyperlink} left the server."
						}, true)
					elseif selection == "playerteam" then
						local vars = emojis.right .. " **`{player.name}`:** The name of the player that joined the team.\n" .. emojis.right .. " **`{player.id}`:** The ID of the player that joined the team.\n" .. emojis.right .. " **`{player.profile}`:** The link to the player's profile that joined the team.\n" .. emojis.right .. " **`{player.hyperlink}`:** The hyperlink to the player's profile that joined the team.\n" .. emojis.right .. " **`{player.team}`:** The team that the player joined.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the player joined the team."

						messageEditor(ia, function(builtMsg)
							if builtMsg then
								config.erlclogs = config.erlclogs or {}
								config.erlclogs.playerteam = {
									channel = builtMsg.channel,
									tosend = {
										content = builtMsg.content,
										embeds = builtMsg.embeds
									}
								}
							elseif config.erlclogs and config.erlclogs.playerteam then
								config.erlclogs.playerteam = nil
							end

							modifyKey("erlclogs", config.erlclogs)
							updatePage(allPages.erlcLog.number)
						end, vars, (config.erlclogs and config.erlclogs.playerteam and config.erlclogs.playerteam.tosend) or {
							content = emojis.right .. " **<t:{timestamp}:T>**・{player.hyperlink} joined the **{player.team}** team."
						}, true)
					elseif selection == "playerkill" then
						local vars = emojis.right .. " **`{killed.name}`:** The name of the player that got killed.\n" .. emojis.right .. " **`{killed.id}`:** The ID of the player that got killed.\n" .. emojis.right .. " **`{killed.profile}`:** The profile link to the killed player's profile.\n" .. emojis.right .. " **`{killed.hyperlink}`:** The hyperlink to the killed player's profile.\n" .. emojis.right .. " **`{killer.name}`:** The name of the killer.\n" .. emojis.right .. " **`{killer.id}`:** The ID of the killer.\n" .. emojis.right .. " **`{killer.profile}`:** The profile link to the killer's profile.\n" .. emojis.right .. " **`{killer.hyperlink}`:** The hyperlink to the killer's profile.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the player was killed."

						messageEditor(ia, function(builtMsg)
							if builtMsg then
								config.erlclogs = config.erlclogs or {}
								config.erlclogs.playerkill = {
									channel = builtMsg.channel,
									tosend = {
										content = builtMsg.content,
										embeds = builtMsg.embeds
									}
								}
							elseif config.erlclogs and config.erlclogs.playerkill then
								config.erlclogs.playerkill = nil
							end

							modifyKey("erlclogs", config.erlclogs)
							updatePage(allPages.erlcLog.number)
						end, vars, (config.erlclogs and config.erlclogs.playerkill and config.erlclogs.playerkill.tosend) or {
							content = emojis.swords .. " **<t:{timestamp}:T>**・{killer.hyperlink} killed {killed.hyperlink}."
						}, true)
					elseif selection == "modcall" then
						local vars = emojis.right .. " **`{caller.name}`:** The name of the player who called !mod.\n" .. emojis.right .. " **`{caller.id}`:** The ID of the player who called !mod.\n" .. emojis.right .. " **`{caller.profile}`:** The link to the player's profile that called !mod.\n" .. emojis.right .. " **`{caller.hyperlink}`:** The hyperlink to the player who called !mod's profile.\n" .. emojis.right .. " **`{moderator.name}`:** The name of the moderator who answered the modcall.\n" .. emojis.right .. " **`{moderator.id}`:** The ID of the moderator who answered the modcall.\n" .. emojis.right .. " **`{moderator.profile}`:** The profile link of the moderator who answered the mod call.\n" .. emojis.right .. " **`{moderator.hyperlink}`:** The hyperlink to the killer's profile.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the modcall was answered."

						messageEditor(ia, function(builtMsg)
							if builtMsg then
								config.erlclogs = config.erlclogs or {}
								config.erlclogs.modcall = {
									channel = builtMsg.channel,
									tosend = {
										content = builtMsg.content,
										embeds = builtMsg.embeds
									}
								}
							elseif config.erlclogs and config.erlclogs.modcall then
								config.erlclogs.modcall = nil
							end

							modifyKey("erlclogs", config.erlclogs)
							updatePage(allPages.erlcLog.number)
						end, vars, (config.erlclogs and config.erlclogs.modcall and config.erlclogs.modcall.tosend) or {
							content = emojis.modcall .. " **<t:{timestamp}:T>**・{moderator.hyperlink} answered {caller.hyperlink}'s modcall."
						}, true)
					elseif selection == "guildcyclednotifychannel" then
						channelSelect(ia, "Select a channel...", function(channel)
							modifyKey("guildcyclednotifychannel", channel)
							updatePage(allPages.erlc.number)
						end, true, 0, 1, config.guildcyclednotifychannel)
					else
						ia:updateDeferred(true)
						updatePage(allPages.erlcLog.number)
					end
				else
					ia:updateDeferred(true)
					updatePage(allPages.erlcLog.number)
				end
			end,
			identifier = {
				text = "ERLC Server Logs",
				emoji = resolveEmoji(emojis.search)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.discordStatistics.number),
			color = colors.info,
			components = getcomps(allPages.discordStatistics.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]
				local guild = interaction.guild

				local vars = emojis.right .. " **`{guild.name}`:** The Discord server's name.\n" .. emojis.right .. " **`{guild.id}`:** The Discord server's ID.\n" .. emojis.right .. " **`{guild.members}`:** The total member count of the server.\n" .. emojis.right .. " **`{guild.bots}`:** The number of bots in the server.\n" .. emojis.right .. " **`{guild.humans}`:** The number of human (non-bot) members in the server.\n" .. emojis.right .. " **`{guild.boosts}`:** The number of server boosts.\n" .. emojis.right .. " **`{guild.boostlevel}`:** The server's boost level.\n" .. emojis.right .. " **`{guild.roles}`:** The number of roles in the server.\n" .. emojis.right .. " **`{guild.textchannels}`:** The total number of text channels in the server.\n" .. emojis.right .. " **`{guild.voicechannels}`:** The total number of voice channels in the server.\n" .. emojis.right .. " **`{guild.categories}`:** The total number of categories in the server."

				loadMembers(guild)

				local varKeys = {
					["guild.name"] = guild.name,
					["guild.id"] = guild.id,
					["guild.members"] = formatNumber(guild.totalMemberCount),
					["guild.bots"] = formatNumber(#guild.bots),
					["guild.humans"] = (formatNumber(tonumber(guild.totalMemberCount) - #guild.bots)),
					["guild.boosts"] = guild.premiumSubscriptionCount,
					["guild.boostlevel"] = guild.premiumTier,
					["guild.roles"] = #guild.roles,
					["guild.textchannels"] = formatNumber(#guild.textChannels),
					["guild.voicechannels"] = formatNumber(#guild.voiceChannels),
					["guild.categories"] = formatNumber(#guild.categories)
				}

				if id == "actions" then
					if selection == "discordserverstatisticsvars" then
						ia:reply({
							embed = {
								title = emojis.json .. " Variables",
								description = vars,
								color = colors.blank
							}
						}, true)

						updatePage(allPages.discordStatistics.number)
					elseif selection == "createstatisticschannel" then
						if checkLimit(ia, "status channels", isPlusGuild, config.discordserverstatuschannels, "discordStatusChannels") then
							return
						end

						prompt(ia, "Discord Server Statistics Channel", {
							{
								question = "Channel Name",
								placeholder = "Go back to view variables.",
								style = "short",
								required = true
							}
						}, function(mia, response)
							if mia and response and response["Channel Name"] and response["Channel Name"] ~= "" then
								local name = response["Channel Name"]

								if name:len() < 1 or name:len() > 100 then
									updatePage(allPages.discordStatistics.number)
									return mia:fail("You must provide a name between 1 and 100 characters.", nil, true)
								end

								local new, replaced = parseTable({
									name
								}, varKeys)

								if replaced < 1 then
									updatePage(allPages.discordStatistics.number)
									return mia:fail("You need to use at least 1 variable.", nil, true)
								end

								if new and new[1] then
									local voiceChannel, err = interaction.guild:createVoiceChannel(new[1])

									if type(voiceChannel) == "table" then
										coroutine.wrap(function()
											local overwrite = voiceChannel:getPermissionOverwriteFor(interaction.guild.defaultRole)

										local success, err = overwrite:setPermissions(
											{
												discordia.enums.permission.readMessages
											},
											{
												discordia.enums.permission.sendMessages,
												discordia.enums.permission.connect,
												discordia.enums.permission.speak
											}
										)

										if not success then
											Client:error("Failed to set channel permissions: " .. tostring(err))
										end
										end)()
										config.discordserverstatuschannels = config.discordserverstatuschannels or {}
										table.insert(config.discordserverstatuschannels, {
											channel = voiceChannel.id,
											content = name
										})

										modifyKey("discordserverstatuschannels", config.discordserverstatuschannels)
									else
										mia:fail("Failed to create voice channel: ```" .. err .. "```", nil, true)
									end
								else
									mia:fail("Something went wrong, please try again or contact [Ducky Support](https://discord.gg/j4w5ZcbRyh).", nil, true)
								end

								updatePage(allPages.discordStatistics.number)
							end
						end, true)
					elseif selection == "editstatisticschannel" then
						if not config.discordserverstatuschannels or table.count(config.discordserverstatuschannels) < 1 then
							updatePage(allPages.discordStatistics.number)
							return ia:fail("You have not created any Discord server statistics channels.", nil, true)
						end

						local options = {}

						local modified = false

						for i, v in pairs(config.discordserverstatuschannels) do
							local channel = interaction.guild:getChannel(v.channel)

							if channel then
								table.insert(options, {
									label = "#" .. tostring(i),
									description = string.truncate(channel.name, 100),
									value = tostring(i) .. ":" .. v.channel,
									emoji = resolvedEmojis.channel
								})
							else
								table.remove(config.discordserverstatuschannels, i)
								modified = true
							end
						end

						if modified then
							modifyKey("discordserverstatuschannels", config.discordserverstatuschannels)
						end

						if table.count(options) < 1 then
							return ia:fail("You have not created any Discord server statistics channels.", nil, true)
						end

						optionsSelect(ia, "Select statistics channel...", function(selection, cia)
							local splitSelection = string.split(selection, ":")
							local i = splitSelection[1]
							local channelID = splitSelection[2]

							local voiceChannel = interaction.guild:getChannel(channelID)

							if voiceChannel then
								prompt(cia, "Discord Server Status Channel", {
									{
										question = "Channel Name",
										placeholder = "Go back to view variables.",
										default = config.discordserverstatuschannels[tonumber(i)].content,
										style = "short",
										required = true
									}
								}, function(mia, response)
									if mia and response and response["Channel Name"] and response["Channel Name"] ~= "" then
										local name = response["Channel Name"]

										if name:len() < 1 or name:len() > 100 then
											updatePage(allPages.discordStatistics.number)
											return mia:fail("You must provide a name between 1 and 100 characters.", nil, true)
										end

										local new, replaced = parseTable({
											name
										}, varKeys)

										if replaced < 1 then
											updatePage(allPages.discordStatistics.number)
											return mia:fail("You need to use at least 1 variable.", nil, true)
										end

										if new and new[1] then
											voiceChannel:setName(new[1])

											config.discordserverstatuschannels = config.discordserverstatuschannels or {}
											config.discordserverstatuschannels[tonumber(i)] = {
												channel = voiceChannel.id,
												content = name
											}

											modifyKey("discordserverstatuschannels", config.discordserverstatuschannels)
										else
											mia:fail("Something went wrong, please try again or contact [Ducky Support](https://discord.gg/j4w5ZcbRyh).", nil, true)
										end

										updatePage(allPages.discordStatistics.number)
									end
								end, true)
							else
								return cia:fail("I could not find that channel.")
							end
						end, true, options, 1, nil, true)
					elseif selection == "removestatisticschannel" then
						if not config.discordserverstatuschannels or table.count(config.discordserverstatuschannels) < 1 then
							updatePage(allPages.discordStatistics.number)
							return ia:fail("You have not created any Discord server statistics channels.", nil, true)
						end

						local options = {}

						local modified = false

						for i, v in pairs(config.discordserverstatuschannels) do
							local channel = interaction.guild:getChannel(v.channel)

							if channel then
								table.insert(options, {
									label = "#" .. tostring(i),
									description = string.truncate(channel.name, 100),
									value = tostring(i) .. ":" .. v.channel,
									emoji = resolvedEmojis.channel
								})
							else
								table.remove(config.discordserverstatuschannels, i)
								modified = true
							end
						end

						if modified then
							modifyKey("discordserverstatuschannels", config.discordserverstatuschannels)
						end

						if table.count(options) < 1 then
							return ia:fail("You have not created any Discord server statistics channels.", nil, true)
						end

						optionsSelect(ia, "Select statistics channel...", function(selection, cia)
							local splitSelection = string.split(selection, ":")
							local i = splitSelection[1]
							local channelID = splitSelection[2]

							local voiceChannel = interaction.guild:getChannel(channelID)

							if voiceChannel then
								voiceChannel:delete()
								config.discordserverstatuschannels[tonumber(i)] = nil
								modifyKey("discordserverstatuschannels", config.discordserverstatuschannels)

								updatePage(allPages.discordStatistics.number)
							else
								return cia:fail("I could not find that channel.")
							end
						end, true, options, 1, nil, true)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Discord Server Statistics",
				emoji = resolveEmoji(emojis.chart)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.join.number),
			color = colors.info,
			components = getcomps(allPages.join.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				if id == "actions" then
					if selection == "joinroles" then
						roleSelect(ia, "Select autoroles...", function(roles)
							modifyKey("joinroles", roles)
							updatePage(allPages.join.number)
						end, true, 0, 5, config.joinroles)
					elseif selection == "joinchannel" then
						channelSelect(ia, "Select a welcome channel...", function(channel)
							modifyKey("joinchannel", channel)
							updatePage(allPages.join.number)
						end, true, nil, nil, config.joinchannel)
					elseif selection == "joinmessage" then
						messageEditor(ia, function(message)
							modifyKey("joinmessage", message)
							updatePage(allPages.join.number)
						end, emojis.right .. " **`{member.mention}`:** The mention of the member that joined.\n" .. emojis.right .. " **`{member.name}`:** The name of the member that joined.\n" .. emojis.right .. " **`{member.username}`:** The username of the member that joined.\n" .. emojis.right .. " **`{member.id}`:** The ID of the member that joined.\n" .. emojis.right .. " **`{guild.name}`:** The server's name.\n" .. emojis.right .. " **`{guild.id}`:** The server's ID.\n" .. emojis.right .. " **`{guild.membercount}`:** The server's membercount.\n" .. emojis.right .. " **`{guild.membercount.raw}`:** The server's membercount unformatted.\n" .. emojis.right .. " **`{guild.membercount.suffix}`:** The server's membercount formatted with a suffix.", config.joinmessage, nil, true)
					elseif selection == "joinmessagedelete" then
						prompt(ia, "Welcome Message Delete Delay", {
							{
								question = "Edit Delay",
								placeholder = "Example: 30s, 5m, 2h...",
								style = "short",
								required = false,
								default = (config.joinmessagedelete and readable(config.joinmessagedelete)) or ""
							}
						}, function(mia, responses)
							if mia then
								modifyKey("joinmessagedelete", convert(responses["Edit Delay"]))
								updatePage(allPages.join.number)
							end
						end, true)
					elseif selection == "toggledmjoin" then
						modifyKey("dmjoin", not config.dmjoin)
						ia:updateDeferred(true)
						updatePage(allPages.join.number)
					elseif selection == "dmjoinmessage" then
						messageEditor(ia, function(message)
							modifyKey("dmjoinmessage", message)
							updatePage(allPages.join.number)
						end, emojis.right .. " **`{member.mention}`:** The mention of the member that joined.\n" .. emojis.right .. " **`{member.name}`:** The name of the member that joined.\n" .. emojis.right .. " **`{member.username}`:** The username of the member that joined.\n" .. emojis.right .. " **`{member.id}`:** The ID of the member that joined.\n" .. emojis.right .. " **`{guild.name}`:** The server's name.\n" .. emojis.right .. " **`{guild.id}`:** The server's ID.\n" .. emojis.right .. " **`{guild.membercount}`:** The server's membercount.\n" .. emojis.right .. " **`{guild.membercount.raw}`:** The server's membercount unformatted.\n" .. emojis.right .. " **`{guild.membercount.suffix}`:** The server's membercount formatted with a suffix.", config.dmjoinmessage)
					elseif selection == "testjm" then
						local tosend = config.joinmessage

						local tosendDM

						local m = interaction.member
						local g = interaction.guild

						if config and (config.dmjoin) and (config.dmjoinmessage) then
							tosendDM = config.dmjoinmessage
						end

						local keys = {
							["member.mention"] = m.mentionString,
							["member.name"] = m.name or m.user.globalName or m.user.username,
							["member.username"] = m.user.username,
							["member.id"] = m.id,
							["guild.name"] = g.name,
							["guild.id"] = g.id,
							["guild.membercount"] = formatNumber(g.totalMemberCount),
							["guild.membercount.raw"] = g.totalMemberCount,
							["guild.membercount.suffix"] = ordinal(g.totalMemberCount)
						}

						tosend = (tosend and parseTable(tosend, keys)) or nil
						if tosendDM then
							tosendDM = (tosendDM and parseTable(tosendDM, keys)) or nil
						end

						if tosend or tosendDM then
							local roleButton

							if hasPermission(m, "BOT_DEVELOPER") then
								roleButton = {
									type = 2,
									style = 5,
									url = "https://duckybot.xyz/support",
									label = "Ducky Developer",
									emoji = resolvedEmojis.developer
								}
							elseif hasPermission(m, "WEB_DEVELOPER") then
								roleButton = {
									type = 2,
									style = 5,
									url = "https://duckybot.xyz/support",
									label = "Ducky Web Developer",
									emoji = resolvedEmojis.web
								}
							elseif hasPermission(m, "EXECUTIVE") then
								roleButton = {
									type = 2,
									style = 5,
									url = "https://duckybot.xyz/support",
									label = "Ducky Executive",
									emoji = resolvedEmojis.executive
								}
							elseif hasPermission(m, "MANAGEMENT") then
								roleButton = {
									type = 2,
									style = 5,
									url = "https://duckybot.xyz/support",
									label = "Ducky Management",
									emoji = resolvedEmojis.settings
								}
							elseif hasPermission(m, "SUPPORT") then
								roleButton = {
									type = 2,
									style = 5,
									url = "https://duckybot.xyz/support",
									label = "Ducky Support",
									emoji = resolvedEmojis.support
								}
							elseif hasPermission(m, "DUCKY_STAFF") then
								roleButton = {
									type = 2,
									style = 5,
									url = "https://duckybot.xyz/support",
									label = "Ducky Staff",
									emoji = resolvedEmojis.permission
								}
							elseif hasPermission(m, "QUALITY_ASSURANCE") then
								roleButton = {
									type = 2,
									style = 5,
									url = "https://duckybot.xyz/support",
									label = "Ducky Quality Assurance",
									emoji = resolvedEmojis.qa
								}
							elseif hasPermission(m, "DOCWRITER") then
								roleButton = {
									type = 2,
									style = 5,
									url = "https://duckybot.xyz/support",
									label = "Ducky Docwriter",
									emoji = resolvedEmojis.edit
								}
							end

							if roleButton then
								tosend.components = tosend.components or {}

								if #tosend.components < 5 then
									table.insert(tosend.components, {
										type = 1,
										components = { roleButton }
									})
								end
							end

							tosend.allowedMentions = {
								users = {
									m.id
								}
							}

							if tosendDM then
								tosendDM.components = signature(g)
							end

							local welcomechannel = config.joinchannel and interaction.guild:getChannel(config.joinchannel)
							if welcomechannel then
								local s, e = welcomechannel:send(tosend)
								if s then
									ia:success("Your test welcome message has been successfully sent to " .. welcomechannel.mentionString .. "!", nil, true)
								else
									ia:fail("The test welcome message failed to send:\n>>> ```\n" .. tostring(e) .. "```", nil, true)
								end
							else
								ia:fail("You have not set a welcome channel.", nil, true)
							end

							if (config.dmjoin) and (config.dmjoinmessage) then
								local success, err = m.user:send(tosendDM)
								if not success then
									ia:fail("The test DM welcome message failed to send to " .. getUserString(m) .. ":\n>>> ```\n" .. tostring(err) .. "```", nil, true)
								end
							end
						else
							ia:fail("You have not set a welcome message.", nil, true)
						end

						updatePage(allPages.join.number)
					elseif selection == "joingatethreshold" then
						prompt(ia, "Edit Joingate Threshold", {
							{
								question = "How long must an account exist before being allowed to join?",
								placeholder = "Enter a valid amount of time... (i.e. 7d, 14d, 30d)",
								style = "short",
								required = false
							}
						}, function(mia, responses)
							if mia then
								local response = responses["How long must an account exist before being allowed to join?"]
								response = response and convert(response)

								modifyKey("joingatethreshold", (response ~= "" and response) or nil)
								return updatePage(allPages.join.number)
							end
						end, true)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Welcome/Autoroles",
				emoji = resolveEmoji(emojis.wave)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.sessions.number),
			color = colors.info,
			components = getcomps(allPages.sessions.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				local sessionVars = emojis.right .. " **`{initiator.mention}`:** The initiator's mention.\n" .. emojis.right .. " **`{initiator.name}`:** The initiator's name/nickname.\n" .. emojis.right .. " **`{initiator.username}`:** The initiator's username.\n" .. emojis.right .. " **`{initiator.id}`:** The initiator's user ID.\n" .. emojis.right .. " **`{initiator.avatar}`:** The initiator's avatar URL.\n" .. emojis.right .. " **`{server.name}`:** The name of the ERLC server.\n" .. emojis.right .. " **`{server.players}`:** The amount of players currently in-game.\n" .. emojis.right .. " **`{server.maxplayers}`:** The maximum amount of in-game players.\n" .. emojis.right .. " **`{server.code}`:** The join code of the ERLC server.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The current Unix Epoch timestamp."

				if id == "actions" then
					if selection == "sessionschannel" then
						channelSelect(ia, "Select sessions channel...", function(ch)
							modifyKey("sessionschannel", ch)
							updatePage(allPages.sessions.number)
						end, true, nil, nil, config.sessionschannel)
					elseif selection == "sessionmentionables" then
						mentionableSelect(ia, "Select session mentionables...", function(ms)
							modifyKey("sessionmentionables", ms)
							updatePage(allPages.sessions.number)
						end, true, 0, 5, config.sessionmentionables)
					elseif selection == "sessionspinghere" then
						modifyKey("sessionspinghere", not config.sessionspinghere)
						ia:updateDeferred(true)
						updatePage(allPages.sessions.number)
					elseif selection == "sessionspingeveryone" then
						modifyKey("sessionspingeveryone", not config.sessionspingeveryone)
						ia:updateDeferred(true)
						updatePage(allPages.sessions.number)
					elseif selection == "serverinformation" then
						local function openModal(ia)
							prompt(ia, "Server Information", {
								{
									question = "Server Name",
									placeholder = "What's the name of your in-game server?",
									style = "short",
									required = false,
									max = 50,
									default = (config.serverInfo and config.serverInfo.Name) or nil
								},
								{
									question = "Max Players",
									placeholder = "What's the max amount of players that can join your in-game server?",
									style = "short",
									required = false,
									max = 2,
									default = (config.serverInfo and config.serverInfo.MaxPlayers) or nil
								},
								{
									question = "Join Code",
									placeholder = "What's the code to join your in-game server?",
									style = "short",
									required = false,
									max = 10,
									default = (config.serverInfo and config.serverInfo.JoinKey) or nil
								}
							}, function(mia, responses)
								if mia then
									if responses["Join Code"] and responses["Join Code"]:match("%W") then
										updatePage(allPages.sessions.number)
										return ia:fail("The server join code may not include any non-alphabetic characters.", nil, true)
									end

									config.serverInfo = config.serverInfo or {}
									config.serverInfo.Name = responses["Server Name"]
									config.serverInfo.MaxPlayers = responses["Max Players"]
									config.serverInfo.JoinKey = responses["Join Code"]

									if not config.serverInfo.Name and not config.serverInfo.MaxPlayers and not config.serverInfo.JoinKey then
										config.serverInfo = "nil"
									end

									modifyKey("serverInfo", config.serverInfo)
									updatePage(allPages.sessions.number)
								end
							end, true)
						end

						if config.apikey then
							confirm(ia, "Are you sure you would like to overwrite fetched server info?\n-# " .. emojis.right .. " You will have to manually update this if you change your server.", function(confirmed, ria)
								if confirmed then
									openModal(ria)
								end
							end, true)
						else
							openModal(ia)
						end
					elseif selection == "ssuembeds" then
						multiEmbedEditor(ia, function(new)
							modifyKey("ssuembeds", new)
							updatePage(allPages.sessions.number)
						end, sessionVars, config.ssuembeds)
					elseif selection == "voteembeds" then
						multiEmbedEditor(ia, function(new)
							modifyKey("voteembeds", new)
							updatePage(allPages.sessions.number)
						end, emojis.right .. " **`{initiator.mention}`:** The initiator's mention.\n" .. emojis.right .. " **`{initiator.name}`:** The initiator's name/nickname.\n" .. emojis.right .. " **`{initiator.username}`:** The initiator's username.\n" .. emojis.right .. " **`{initiator.id}`:** The initiator's user ID.\n" .. emojis.right .. " **`{initiator.avatar}`:** The initiator's avatar URL.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The current Unix Epoch timestamp.\n" .. emojis.right .. " **`{votes.required}`:** The amount of votes needed to start the session.", config.voteembeds)
					elseif selection == "staffvoteembeds" then
						multiEmbedEditor(ia, function(new)
							modifyKey("staffvoteembeds", new)
							updatePage(allPages.sessions.number)
						end, emojis.right .. " **`{initiator.mention}`:** The initiator's mention.\n" .. emojis.right .. " **`{initiator.name}`:** The initiator's name/nickname.\n" .. emojis.right .. " **`{initiator.username}`:** The initiator's username.\n" .. emojis.right .. " **`{initiator.id}`:** The initiator's user ID.\n" .. emojis.right .. " **`{initiator.avatar}`:** The initiator's avatar URL.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The current Unix Epoch timestamp.\n" .. emojis.right .. " **`{votes.required}`:** The amount of votes needed to start the session.", config.staffvoteembeds)
					elseif selection == "ssdembeds" then
						multiEmbedEditor(ia, function(new)
							modifyKey("ssdembeds", new)
							updatePage(allPages.sessions.number)
						end, emojis.right .. " **`{initiator.mention}`:** The initiator's mention.\n" .. emojis.right .. " **`{initiator.name}`:** The initiator's name/nickname.\n" .. emojis.right .. " **`{initiator.username}`:** The initiator's username.\n" .. emojis.right .. " **`{initiator.id}`:** The initiator's user ID.\n" .. emojis.right .. " **`{initiator.avatar}`:** The initiator's avatar URL.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The current Unix Epoch timestamp.", config.ssdembeds)
					elseif selection == "lowembeds" then
						multiEmbedEditor(ia, function(new)
							modifyKey("lowembeds", new)
							updatePage(allPages.sessions.number)
						end, sessionVars, config.lowembeds)
					elseif selection == "fullembeds" then
						multiEmbedEditor(ia, function(new)
							modifyKey("fullembeds", new)
							updatePage(allPages.sessions.number)
						end, sessionVars, config.fullembeds)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Sessions",
				emoji = resolveEmoji(emojis.game)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.staff.number),
			color = colors.info,
			components = getcomps(allPages.staff.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				if id == "actions" then
					if selection == "infractionschannel" then
						channelSelect(ia, "Select an infractions channel...", function(c)
							modifyKey("infractionschannel", c)
							updatePage(allPages.staff.number)
						end, true, nil, nil, config.infractionschannel)
					elseif selection == "promotionschannel" then
						channelSelect(ia, "Select a promotions channel...", function(c)
							modifyKey("promotionschannel", c)
							updatePage(allPages.staff.number)
						end, true, nil, nil, config.promotionschannel)
					elseif selection == "infractionembeds" then
						multiEmbedEditor(ia, function(new)
							modifyKey("infractionembeds", new)
							updatePage(allPages.staff.number)
						end, emojis.right .. " **`{offender.mention}`:** The offender's mention.\n" .. emojis.right .. " **`{offender.name}`:** The offender's name/nickname.\n" .. emojis.right .. " **`{offender.username}`:** The offender's username.\n" .. emojis.right .. " **`{offender.id}`:** The offender's user ID.\n" .. emojis.right .. " **`{offender.avatar}`:** The offender's avatar.\n" .. emojis.right .. " **`{issuer.mention}`:** The issuer's mention.\n" .. emojis.right .. " **`{issuer.name}`:** The issuer's name/nickname.\n" .. emojis.right .. " **`{issuer.username}`:** The issuer's username.\n" .. emojis.right .. " **`{issuer.id}`:** The issuer's user ID.\n" .. emojis.right .. " **`{issuer.avatar}`:** The issuer's avatar.\n" .. emojis.right .. " **`{infraction.type}`:** The infraction type.\n" .. emojis.right .. " **`{infraction.reason}`:** The infraction reason.\n" .. emojis.right .. " **`{infraction.notes}`:** The infraction notes.\n" .. emojis.right .. " **`{infraction.id}`:** The infraction ID.\n" .. emojis.right .. " **`{infraction.expires}`:** The infraction's expiration timestamp.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The current Unix Epoch timestamp.", config.infractionembeds)
					elseif selection == "promotionembeds" then
						multiEmbedEditor(ia, function(new)
							modifyKey("promotionembeds", new)
							updatePage(allPages.staff.number)
						end, emojis.right .. " **`{receiver.mention}`:** The receiver's mention.\n" .. emojis.right .. " **`{receiver.name}`:** The receiver's name/nickname.\n" .. emojis.right .. " **`{receiver.username}`:** The receiver's username.\n" .. emojis.right .. " **`{receiver.id}`:** The receiver's user ID.\n" .. emojis.right .. " **`{receiver.avatar}`:** The receiver's avatar.\n" .. emojis.right .. " **`{promoter.mention}`:** The promoter's mention.\n" .. emojis.right .. " **`{promoter.name}`:** The promoter's name/nickname.\n" .. emojis.right .. " **`{promoter.username}`:** The promoter's username.\n" .. emojis.right .. " **`{promoter.id}`:** The promoter's user ID.\n" .. emojis.right .. " **`{promoter.avatar}`:** The promoter's avatar.\n" .. emojis.right .. " **`{newrank.mention}`:** The new rank's mention.\n" .. emojis.right .. " **`{newrank.name}`:** The new rank's name.\n" .. emojis.right .. " **`{newrank.id}`:** The new rank's Role ID.\n" .. emojis.right .. " **`{promotion.reason}`:** The promotion reason.\n" .. emojis.right .. " **`{promotion.notes}`:** The promotion notes.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The current Unix Epoch timestamp.", config.promotionembeds)
					elseif selection == "removetype" then
						if type(config.infractiontypes) ~= "table" or table.count(config.infractiontypes) < 1 then
							updatePage(allPages.staff.number)
							return ia:fail("You have not created any infraction types.", nil, true)
						end

						local options = {}

						for i, it in ipairs(config.infractiontypes) do
							table.insert(options, {
								label = string.truncate(it.name, 100),
								value = i,
								emoji = resolvedEmojis.delete
							})
						end

						optionsSelect(ia, "Select an infraction type...", function(opt)
							table.remove(config.infractiontypes, tonumber(opt))
							modifyKey("infractiontypes", config.infractiontypes)
							updatePage(allPages.staff.number)
						end, true, options, 1, nil, true)
					elseif selection == "addtype" or selection == "edittype" then
						local newType = {
							name = nil,
							role = nil,
							revertActions = nil,
							actions = {}
						}

						local infractionTypeIndex

						local function startBuilder()
							local comps = discordia.Components():selectMenu({
								id = "edit",
								placeholder = "Edit infraction type...",
								min_values = 0,
								max_values = 1,
								options = {
									{
										label = "Edit Name",
										emoji = resolvedEmojis.edit,
										value = "name"
									},
									{
										label = "Edit Role",
										emoji = resolvedEmojis.role,
										value = "role"
									},
									{
										label = "Toggle Revert Actions",
										emoji = resolvedEmojis.reload,
										value = "revertactions"
									},
									{
										label = "Add Action",
										emoji = resolvedEmojis.plus,
										value = "addaction"
									},
									{
										label = "Remove Action",
										emoji = resolvedEmojis.minus,
										value = "removeaction"
									}
								}
							}):button({
								id = "create",
								label = "Save",
								style = "success",
								emoji = resolvedEmojis.yeswhite,
								actionRow = 2
							}):button({
								id = "cancel",
								label = "Cancel",
								style = "danger",
								emoji = resolvedEmojis.nowhite,
								actionRow = 2
							}):raw()

							local builder = nil

							local function updateBuilder()
								if type(builder) == "table" then
									return ia:editReply({
										embed = {
											title = emojis.moderate .. " Infraction Type Builder",
											description = emojis.right .. " **Name:** " .. (newType.name or "N/A") .. "\n" .. emojis.right .. " **Role:** " .. ((newType.role and "<@&" .. newType.role .. ">") or "N/A") .. "\n" .. emojis.right .. " **Revert Actions:** " .. ((newType.revertActions and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Actions:** \n" .. emojis.space .. emojis.right .. " " .. ((newType.actions and table.count(newType.actions) > 0 and table.concatFn(newType.actions, "\n" .. emojis.space .. emojis.right .. " ", function(ac)
												local text

												if ac.type == "sendmsg" then
													text = "Send a message to <#" .. ac.channel .. ">"
												elseif ac.type == "sendcmd" then
													text = "Send the `:" .. string.truncate(ac.cmd, 50) .. "` command to the in-game server"
												elseif ac.type == "delay" then
													text = "Wait " .. readable(ac.delay)
												end

												return text
											end)) or "None"),
											color = colors.info
										},
										components = comps
									}, builder.id)
								else
									builder = ia:reply({
										embed = {
											title = emojis.moderate .. " Infraction Type Builder",
											description = emojis.right .. " **Name:** " .. (newType.name or "N/A") .. "\n" .. emojis.right .. " **Role:** " .. ((newType.role and "<@&" .. newType.role .. ">") or "N/A") .. "\n" .. emojis.right .. " **Revert Actions:** " .. ((newType.revertActions and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Actions:** \n" .. emojis.space .. emojis.right .. " " .. ((newType.actions and table.count(newType.actions) > 0 and table.concatFn(newType.actions, "\n" .. emojis.space .. emojis.right .. " ", function(ac)
												local text

												if ac.type == "sendmsg" then
													text = "Send a message to <#" .. ac.channel .. ">"
												elseif ac.type == "sendcmd" then
													text = "Send the `:" .. string.truncate(ac.cmd, 50) .. "` command to the in-game server"
												elseif ac.type == "delay" then
													text = "Wait " .. readable(ac.delay)
												end

												return text
											end)) or "None"),
											color = colors.info
										},
										components = comps
									}, true)
								end
							end

							updateBuilder()

							local variables = emojis.right .. " **`{offender.discord.mention}`:** The offender's Discord mention.\n" .. emojis.right .. " **`{offender.discord.name}`:** The offender's Discord name/nickname.\n" .. emojis.right .. " **`{offender.discord.username}`:** The offender's Discord username.\n" .. emojis.right .. " **`{offender.discord.id}`:** The offender's Discord ID.\n" .. emojis.right .. " **`{offender.discord.avatar}`:** The offender's Discord avatar.\n" .. emojis.right .. " **`{issuer.discord.mention}`:** The issuer's Discord mention.\n" .. emojis.right .. " **`{issuer.discord.name}`:** The issuer's Discord name/nickname.\n" .. emojis.right .. " **`{issuer.discord.username}`:** The issuer's Discord username.\n" .. emojis.right .. " **`{issuer.discord.id}`:** The issuer's Discord ID.\n" .. emojis.right .. " **`{issuer.discord.avatar}`:** The issuer's Discord avatar.\n" .. emojis.right .. " **`{offender.roblox.display}`:** The offender's Roblox displayname.\n" .. emojis.right .. " **`{offender.roblox.username}`:** The offender's Roblox username.\n" .. emojis.right .. " **`{offender.roblox.id}`:** The offender's Roblox ID.\n" .. emojis.right .. " **`{offender.roblox.hyperlink}`:** The offender's hyperlink to their Roblox profile.\n" .. emojis.right .. " **`{issuer.roblox.display}`:** The issuer's Roblox displayname.\n" .. emojis.right .. " **`{issuer.roblox.username}`:** The issuer's Roblox username.\n" .. emojis.right .. " **`{issuer.roblox.id}`:** The issuer's Roblox ID.\n" .. emojis.right .. " **`{issuer.roblox.hyperlink}`:** The issuer's hyperlink to their Roblox profile.\n" .. emojis.right .. " **`{infraction.type}`:** The infraction type.\n" .. emojis.right .. " **`{infraction.reason}`:** The infraction reason.\n" .. emojis.right .. " **`{infraction.notes}`:** The infraction notes.\n" .. emojis.right .. " **`{infraction.id}`:** The infraction ID.\n" .. emojis.right .. " **`{infraction.expires}`:** The infraction's expiration timestamp.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The current Unix Epoch timestamp."

							onComp(builder, nil, nil, ia.user.id, false, function(bia)
								local id = bia.data.custom_id
								local property = bia.data.values and bia.data.values[1]

								if id == "create" then
									if newType.name then
										local finishedInfractionType = {
											name = newType.name,
											role = newType.role,
											revertActions = newType.revertActions,
											actions = ((table.count(newType.actions) > 0 and newType.actions) or nil)
										}

										if selection == "addtype" and not checkLimit(bia, "infraction types", nil, table.count(config.infractiontypes), "infractionTypes") then
											insertInto("infractiontypes", finishedInfractionType)
										elseif selection == "edittype" then
											table.remove(config.infractiontypes, infractionTypeIndex)
											table.insert(config.infractiontypes, finishedInfractionType)
											modifyKey("infractiontypes", config.infractiontypes)
										end

										bia:updateDeferred(true)
										ia:deleteReply(builder.id)
										updatePage(allPages.staff.number)
										return true
									else
										bia:fail("You must set a name for this infraction type.", nil, true)
									end
								elseif id == "cancel" then
									bia:updateDeferred(true)
									ia:deleteReply(builder.id)
									updatePage(allPages.staff.number)
									return true
								elseif property == "role" then
									roleSelect(bia, "Edit assigned infraction role...", function(role)
										newType.role = role
										updateBuilder()
									end, true, 0, 1, nil, true)
								elseif property == "name" then
									ask(bia, "Edit Infraction Type Name", "Enter a name for this infraction type...", nil, nil, "short", true, newType.name, function(_, mia, response)
										if mia then
											if response and response ~= "" then
												newType.name = response
												mia:updateDeferred(true)
												updateBuilder()
											else
												return mia:fail("You must set a name for this infraction type.", nil, true)
											end
										end
									end, 0, 25)
								elseif property == "revertactions" then
									newType.revertActions = not newType.revertActions
									bia:updateDeferred(true)
									updateBuilder()
								elseif property == "addaction" then
									if checkLimit(bia, "actions", isPlusGuild, table.count(newType.actions), "infractionActions") then
										return
									end

									optionsSelect(bia, "Select an action...", function(opt, cia)
										if opt == "sendmsg" then
											messageEditor(cia, function(builtMsg)
												table.insert(newType.actions, {
													type = "sendmsg",
													channel = builtMsg.channel,
													message = {
														content = builtMsg.content,
														embeds = builtMsg.embeds
													}
												})

												updateBuilder()
											end, variables, nil, true)
										elseif opt == "sendcmd" then
											local qst = "Input an in-game command."

											prompt(cia, "Send a command...", {
												{
													question = qst,
													placeholder = "Cancel to view the variables.",
													style = "short",
													required = true,
													max = 250
												}
											}, function(mia, tableResponse)
												if mia then
													local response = type(tableResponse) == "table" and tableResponse[qst]

													if response and type(response) == "string" then
														if response:usub(1, 1) == ":" then
															response = response:usub(2)
														end
														local params = string.split(response, " ")

														if not remoteInGameCommands[params[1]:lower()] then
															updateBuilder()
															return mia:fail("That is not a valid command.", nil, true)
														end

														table.insert(newType.actions, {
															type = "sendcmd",
															cmd = response
														})

														updateBuilder()
													end
												end
											end, true)
										elseif opt == "delay" then
											prompt(cia, "Wait...", {
												{
													question = "Delay Length",
													placeholder = "How long should the delay be? (i.e. 30s, 1m, 5m)",
													style = "short",
													required = false
												}
											}, function(mia, responses)
												if mia then
													local length = (responses and responses["Delay Length"]) or nil

													if length then
														local converted = convert(length)

														if converted then
															table.insert(newType.actions, {
																type = "delay",
																delay = converted
															})
															mia:updateDeferred(true)
															updateBuilder()
														else
															return mia:fail("The response must be a interval of time.", nil, true)
														end
													end
												end
											end)
										elseif opt == "vars" then
											cia:reply({
												embed = {
													title = emojis.json .. " Variables",
													description = variables,
													color = colors.blank
												}
											}, true)
											updateBuilder()
										end
									end, true, ActionOptions, 1, nil, true)
								elseif property == "removeaction" then
									if not newType.actions or table.count(newType.actions) < 1 then
										return ia:fail("You have not added any actions.", nil, true)
									end

									local actionSelectOptions = {}

									for i, ac in pairs(newType.actions) do
										local option = {}

										if ac.type == "sendmsg" then
											option = {
												label = "Send a Message",
												value = i,
												description = "#" .. tostring(i),
												emoji = resolvedEmojis.chat
											}
										elseif ac.type == "sendcmd" then
											option = {
												label = "Send a command to the in-game server.",
												value = i,
												description = "#" .. tostring(i),
												emoji = resolvedEmojis.settings
											}
										elseif ac.type == "delay" then
											option = {
												label = "Wait " .. readable(ac.delay),
												value = i,
												description = "#" .. tostring(i),
												emoji = resolvedEmojis.clock
											}
										end

										table.insert(actionSelectOptions, option)
									end

									optionsSelect(bia, "Select an action...", function(opt)
										table.remove(newType.actions, opt)
										updateBuilder()
									end, true, actionSelectOptions, 1, nil, true)
								end
							end)
						end

						if selection == "edittype" then
							if type(config.infractiontypes) ~= "table" or table.count(config.infractiontypes) < 1 then
								updatePage(allPages.staff.number)
								return ia:fail("You have not created any infraction types.", nil, true)
							end

							local options = {}

							for i, it in ipairs(config.infractiontypes) do
								table.insert(options, {
									label = string.truncate(it.name, 100),
									value = i,
									emoji = resolvedEmojis.edit
								})
							end

							optionsSelect(ia, "Select an infraction type...", function(opt)
								newType = config.infractiontypes[tonumber(opt)]
								newType.actions = newType.actions or {}
								infractionTypeIndex = tonumber(opt)
								startBuilder()
							end, true, options, 1, nil, true)
						else
							if type(config.infractiontypes) == "table" and checkLimit(ia, "infraction types", nil, table.count(config.infractiontypes), "infractionTypes") then
								return
							end

							startBuilder()
						end

					elseif selection == "editinfractionthread" then
						prompt(ia, "Infraction Thread", {
							{
								question = "What should the name be of the thread?",
								placeholder = "You can use the same variables as in the infraction embed.",
								style = "short",
								max = 300,
								required = false,
								default = config.infractionthread
							}
						}, function(mia, responses)
							if mia then
								local threadName = responses["What should the name be of the thread?"]
								mia:updateDeferred(true)
								modifyKey("infractionthread", threadName)
								updatePage(allPages.staff.number)
							end
						end)
					elseif selection == "editpromotionsthread" then
						prompt(ia, "Promotion Thread", {
							{
								question = "What should the name be of the thread?",
								placeholder = "You can use the same variables as in the promotion embed.",
								style = "short",
								max = 300,
								required = false,
								default = config.promotionsthread
							}
						}, function(mia, responses)
							if mia then
								local threadName = responses["What should the name be of the thread?"]
								mia:updateDeferred(true)
								modifyKey("promotionsthread", threadName)
								updatePage(allPages.staff.number)
							end
						end)
					elseif selection == "infractionrevokeembeds" then
						multiEmbedEditor(ia, function(new)
							modifyKey("infractionrevokeembeds", new)
							updatePage(allPages.staff.number)
						end, emojis.right .. " **`{offender.mention}`:** The offender's mention.\n" .. emojis.right .. " **`{offender.name}`:** The offender's name/nickname.\n" .. emojis.right .. " **`{offender.username}`:** The offender's username.\n" .. emojis.right .. " **`{offender.id}`:** The offender's user ID.\n" .. emojis.right .. " **`{offender.avatar}`:** The offender's avatar.\n" .. emojis.right .. " **`{issuer.mention}`:** The issuer's mention.\n" .. emojis.right .. " **`{issuer.name}`:** The issuer's name/nickname.\n" .. emojis.right .. " **`{issuer.username}`:** The issuer's username.\n" .. emojis.right .. " **`{issuer.id}`:** The issuer's user ID.\n" .. emojis.right .. " **`{issuer.avatar}`:** The issuer's avatar.\n" .. emojis.right .. " **`{infraction.type}`:** The infraction type.\n" .. emojis.right .. " **`{infraction.reason}`:** The infraction reason.\n" .. emojis.right .. " **`{infraction.notes}`:** The infraction notes.\n" .. emojis.right .. " **`{infraction.id}`:** The infraction ID.\n" .. emojis.right .. " **`{infraction.expires}`:** The infraction's expiration timestamp.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The current Unix Epoch timestamp.", config.infractionrevokeembeds)
					elseif selection == "infractioneditembeds" then
						multiEmbedEditor(ia, function(new)
							modifyKey("infractioneditembeds", new)
							updatePage(allPages.staff.number)
						end, emojis.right .. " **`{offender.mention}`:** The offender's mention.\n" .. emojis.right .. " **`{offender.name}`:** The offender's name/nickname.\n" .. emojis.right .. " **`{offender.username}`:** The offender's username.\n" .. emojis.right .. " **`{offender.id}`:** The offender's user ID.\n" .. emojis.right .. " **`{offender.avatar}`:** The offender's avatar.\n" .. emojis.right .. " **`{issuer.mention}`:** The issuer's mention.\n" .. emojis.right .. " **`{issuer.name}`:** The issuer's name/nickname.\n" .. emojis.right .. " **`{issuer.username}`:** The issuer's username.\n" .. emojis.right .. " **`{issuer.id}`:** The issuer's user ID.\n" .. emojis.right .. " **`{issuer.avatar}`:** The issuer's avatar.\n" .. emojis.right .. " **`{infraction.type}`:** The infraction type.\n" .. emojis.right .. " **`{infraction.reason}`:** The infraction reason.\n" .. emojis.right .. " **`{infraction.notes}`:** The infraction notes.\n" .. emojis.right .. " **`{infraction.id}`:** The infraction ID.\n" .. emojis.right .. " **`{infraction.expires}`:** The infraction's expiration timestamp.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The current Unix Epoch timestamp.", config.infractioneditembeds)
					elseif selection == "infractionexpireembeds" then
						multiEmbedEditor(ia, function(new)
							modifyKey("infractionexpireembeds", new)
							updatePage(allPages.staff.number)
						end, emojis.right .. " **`{offender.mention}`:** The offender's mention.\n" .. emojis.right .. " **`{offender.name}`:** The offender's name/nickname.\n" .. emojis.right .. " **`{offender.username}`:** The offender's username.\n" .. emojis.right .. " **`{offender.id}`:** The offender's user ID.\n" .. emojis.right .. " **`{offender.avatar}`:** The offender's avatar.\n" .. emojis.right .. " **`{issuer.mention}`:** The issuer's mention.\n" .. emojis.right .. " **`{issuer.name}`:** The issuer's name/nickname.\n" .. emojis.right .. " **`{issuer.username}`:** The issuer's username.\n" .. emojis.right .. " **`{issuer.id}`:** The issuer's user ID.\n" .. emojis.right .. " **`{issuer.avatar}`:** The issuer's avatar.\n" .. emojis.right .. " **`{infraction.type}`:** The infraction type.\n" .. emojis.right .. " **`{infraction.reason}`:** The infraction reason.\n" .. emojis.right .. " **`{infraction.notes}`:** The infraction notes.\n" .. emojis.right .. " **`{infraction.id}`:** The infraction ID.\n" .. emojis.right .. " **`{infraction.expires}`:** The infraction's expiration timestamp.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The current Unix Epoch timestamp.", config.infractionexpireembeds)

					elseif selection == "feedbackchannel" then
						channelSelect(ia, "Select a feedback channel...", function(c)
							modifyKey("feedbackchannel", c)
							updatePage(allPages.staff.number)

						end, true, nil, nil, config.feedbackchannel)
					elseif selection == "feedbackembeds" then
						multiEmbedEditor(ia, function(embs)
							modifyKey("feedbackembeds", embs)
							updatePage(allPages.staff.number)
						end, emojis.right .. " **`{submitter.name}`:** The name of the submitter.\n" .. emojis.right .. " **`{submitter.username}`:** The username of the submitter.\n" .. emojis.right .. " **`{submitter.id}`:** The ID of the submitter.\n" .. emojis.right .. " **`{submitter.mention}`:** The mention of the submitter.\n" .. emojis.right .. " **`{submitter.avatar}`:** The avatar URL of the submitter.\n" .. emojis.right .. " **`{staff.name}`:** The name of the staff member.\n" .. emojis.right .. " **`{staff.username}`:** The username of the staff member.\n" .. emojis.right .. " **`{staff.id}`:** The ID of the staff member.\n" .. emojis.right .. " **`{staff.mention}`:** The mention of the staff member.\n" .. emojis.right .. " **`{staff.avatar}`:** The avatar URL of the staff member.\n" .. emojis.right .. " **`{rating.stars}`:** The staff member's rating shown with stars.\n" .. emojis.right .. " **`{rating.number}`:** The staff member's rating shown as a number out of 5.\n" .. emojis.right .. " **`{review.feedback}`:** The feedback provided.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The current timestamp of which the feedback was sent.", config.feedbackembeds)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Staff Management",
				emoji = resolveEmoji(emojis.quickfix)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.punish.number),
			color = colors.info,
			components = getcomps(allPages.punish.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				if id == "actions" then
					if selection == "punishmentlogschannel" then
						channelSelect(ia, "Select a punishment logs channel...", function(c)
							modifyKey("punishmentlogschannel", c)
							updatePage(allPages.punish.number)
						end, true, nil, nil, config.punishmentlogschannel)
					elseif selection == "bolologschannel" then
						channelSelect(ia, "Select a BOLO logs channel...", function(c)
							modifyKey("bolologschannel", c)
							updatePage(allPages.punish.number)
						end, true, nil, nil, config.bolologschannel)
					elseif selection == "bolologmentionables" then
						mentionableSelect(ia, "Select BOLO log mentionables...", function(ms)
							modifyKey("bolologmentionables", ms)
							updatePage(allPages.punish.number)
						end, true, 0, 5, config.bolologmentionables)
					elseif selection == "addtype" then
						ask(ia, "Add New Punishment Type", "Enter a name for this punishment type...", nil, nil, "short", true, nil, function(_, mia, response)
							if mia then
								if response and response ~= "" then
									local pts = table.deepcopy(config.punishmenttypes or {})
									for i, v in pairs(pts) do
										if v:lower() == response:lower() then
											return mia:fail("A punishment type already exists with that name.", nil, true)
										end
									end

									table.insert(pts, response)
									modifyKey("punishmenttypes", pts)
									updatePage(allPages.punish.number)
									mia:updateDeferred(true)
								else
									return mia:fail("You must provide a name for this punishment type.", nil, true)
								end
							end
						end, 0, 25)
					elseif selection == "removetype" then
						ask(ia, "Remove Punishment Type", "Enter the name of the type you wish to remove...", nil, nil, "short", true, nil, function(_, mia, response)
							if mia then
								if response and response ~= "" then
									local pts = table.deepcopy(config.punishmenttypes or {})
									for i, v in pairs(pts) do
										if v:lower() == response:lower() then
											table.remove(pts, i)
											break
										end
									end
									modifyKey("punishmenttypes", pts)
									updatePage(allPages.punish.number)
									mia:updateDeferred(true)
								else
									return mia:fail("You must provide the name of the punishment type you wish to remove.", nil, true)
								end
							end
						end, 0, 25)
					elseif selection == "tempbantimemods" then
						prompt(ia, "Edit Tempban Time for Mods", {
							{
								question = "For how long can mods tempban someone?",
								placeholder = "Example: 30m, 1h, 7d. Leave this empty to disallow.",
								style = "short",
								required = false
							}
						}, function(mia, responses)
							if responses and responses["For how long can mods tempban someone?"] and responses["For how long can mods tempban someone?"] ~= "" then
								local sec = convert(responses["For how long can mods tempban someone?"], true)

								if sec then
									modifyKey("tempbantimemods", sec)
									updatePage(allPages.punish.number)
								else
									mia:fail("You must provide a valid time.", nil, true)
								end
							else
								modifyKey("tempbantimemods", nil)
								updatePage(allPages.punish.number)
							end
						end, true)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Roblox Punishments",
				emoji = resolveEmoji(emojis.roblox)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.verify.number),
			color = colors.info,
			components = getcomps(allPages.verify.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				if id == "actions" then
					if selection == "verificationchannel" then
						channelSelect(ia, "Select a verification channel...", function(channel)
							modifyKey("verificationchannel", channel)
							updatePage(allPages.verify.number)
						end, true, 0, 1, config.verificationchannel)
					elseif selection == "verificationpanel" then
						local channel = config.verificationchannel and interaction.guild:getChannel(config.verificationchannel)
						if not channel then
							return ia:fail("You have not configured a verification channel.", nil, true)
						end
						
						messageEditor(ia, function(message)
							local components = discordia.Components():button({
								url = "https://duckybot.xyz/link",
								label = "Link",
								style = "link",
								emoji = resolvedEmojis.link
							}):button({
								id = "legacyverification",
								label = "Legacy Verification",
								style = "secondary",
								emoji = resolvedEmojis.roblox
							}):button({
								id = "verifypanelupdateme",
								label = "Update me",
								style = "secondary",
								emoji = resolvedEmojis.reload
							})

							if config.bloxlinkServerKey then
								components:button({
									id = "verifypanelbloxlink",
									label = "Bloxlink",
									style = "secondary",
									emoji = resolvedEmojis.Bloxlink
								})
							end

							message.components = components:raw()

							channel:send(message)

							modifyKey("verificationpanel", message)
							updatePage(allPages.verify.number)
						end, nil, config.verificationpanel)
					elseif selection == "verifiedroles" then
						roleSelect(ia, "Select verified roles...", function(rs)
							p(rs)
							modifyKey("verifiedroles", rs)
							updatePage(allPages.verify.number)
						end, true, 0, 2, config.verifiedroles)
					elseif selection == "unverifiedroles" then
						roleSelect(ia, "Select Unverified roles...", function(rs)
							modifyKey("unverifiedroles", rs)
							updatePage(allPages.verify.number)
						end, true, 0, 2, config.unverifiedroles)
					elseif selection == "verifiednickname" then
						ask(ia, "Edit Verified Nickname", "Edit verified nickname...", nil, nil, "short", false, config.verifiednickname, function(_, mia, response)
							if mia then
								if response and (response ~= "") then
									modifyKey("verifiednickname", response)
									mia:updateDeferred(true)
								else
									modifyKey("verifiednickname", nil)
									mia:updateDeferred(true)
								end
							end
							updatePage(allPages.verify.number)
						end)
					elseif selection == "useBloxlink" then
						if not config.bloxlinkServerKey then
							local Bloxlink = interaction.guild:getMember("426537812993638400")

							if Bloxlink then
								_G.confirm(ia, "You need to create a Bloxlink Server Key to use this feature. To create one, follow these steps:" .. "\n" .. emojis.right .. " Head over to **https://blox.link/dashboard/user/developer** and ensure you are logged in." .. "\n" .. emojis.right .. " Under **Current Server Keys**, next to **Need a different server?**, select your server." .. "\n" .. emojis.right .. " Press **Add** to create a Server Key." .. "\n" .. emojis.right .. " Your server will appear, press **See Key** to get your Bloxlink Server Key.", function(confirmed, cia, cr)
									if confirmed then
										prompt(cia, "Bloxlink Server Key", {
											{
												question = "Please provide your Bloxlink Server Key.",
												placeholder = "If you need help find it, cancel to view the instructions.",
												style = "short"
											}
										}, function(mia, responses)
											if responses and responses["Please provide your Bloxlink Server Key."] then
												local bloxlinkServerKey = responses["Please provide your Bloxlink Server Key."]

												local hdrs = {
													{
														"Authorization",
														bloxlinkServerKey
													}
												}

												local result, body = _G.http.request("GET", "https://api.blox.link/v4/public/guilds/" .. interaction.guild.id .. "/discord-to-roblox/" .. interaction.member.id, hdrs)
												body = (body and (type(body) == "string") and json.decode(body)) or {}

												if result.code == 400 then
													ia:deleteReply(cr.id)
													mia:fail("That Server Key seems to be invalid, Bloxlink returned the following error: ```" .. (body.error or "Unknown Error") .. "```", nil, true)
													updatePage(allPages.verify.number)
												else
													mia:updateDeferred(true)
													ia:deleteReply(cr.id)
													modifyKey("bloxlinkServerKey", bloxlinkServerKey)
													updatePage(allPages.verify.number)
												end
											end
										end, true)
									else
										cia:updateDeferred(true)
										updatePage(allPages.verify.number)
									end
								end)
							else
								ia:fail("Bloxlink must be in your server for this feature to work, you can invite at **https://blox.link/invite**.", nil, true)
								updatePage(allPages.verify.number)
							end
						else
							modifyKey("bloxlinkServerKey", nil)

							ia:updateDeferred(true)
							updatePage(allPages.verify.number)
						end
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Roblox Verification",
				emoji = resolveEmoji(emojis.roblox)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.pings.number),
			color = colors.info,
			components = getcomps(allPages.pings.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				if id == "actions" then
					if selection == "antiping" then
						modifyKey("antiping", not config.antiping)
						ia:updateDeferred(true)
						updatePage(allPages.pings.number)
					elseif selection == "antipingprotectedroles" then
						roleSelect(ia, "Select protected roles...", function(r)
							modifyKey("antipingprotectedroles", r)
							updatePage(allPages.pings.number)
						end, true, 0, 5, config.antipingprotectedroles, true)
					elseif selection == "antipingwhitelistedroles" then
						roleSelect(ia, "Select whitelisted roles...", function(r)
							modifyKey("antipingwhitelistedroles", r)
							updatePage(allPages.pings.number)
						end, true, 0, 5, config.antipingwhitelistedroles, true)
					elseif selection == "antipinghierarchy" then
						modifyKey("antipinghierarchy", not config.antipinghierarchy)
						ia:updateDeferred(true)
						updatePage(allPages.pings.number)
					elseif selection == "antipingembeds" then
						multiEmbedEditor(ia, function(embs)
							modifyKey("antipingembeds", embs)
							updatePage(allPages.pings.number)
						end, emojis.right .. " **`{offender.mention}`:** The offender's mention.\n" .. emojis.right .. " **`{offender.name}`:** The offender's name/nickname.\n" .. emojis.right .. " **`{offender.username}`:** The offender's username.\n" .. emojis.right .. " **`{offender.id}`:** The offender's user ID.\n" .. emojis.right .. " **`{offender.avatar}`:** The offender's avatar.", config.antipingembeds)
					elseif selection == "ghostpingembeds" then
						multiEmbedEditor(ia, function(embs)
							modifyKey("ghostpingembeds", embs)
							updatePage(allPages.pings.number)
						end, emojis.right .. " **`{offender.mention}`:** The offender's mention.\n" .. emojis.right .. " **`{offender.name}`:** The offender's name/nickname.\n" .. emojis.right .. " **`{offender.username}`:** The offender's username.\n" .. emojis.right .. " **`{offender.id}`:** The offender's user ID.\n" .. emojis.right .. " **`{offender.avatar}`:** The offender's avatar.", config.ghostpingembeds)
					elseif selection == "antipingwhitelistedchannels" then
						channelSelect(ia, "Select whitelisted channels...", function(channels)
							modifyKey("antipingwhitelistedchannels", channels)
							updatePage(allPages.pings.number)
						end, true, 0, 5, config.antipingwhitelistedchannels)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Discord Pings",
				emoji = resolveEmoji(emojis.pings)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.suggestions.number),
			color = colors.info,
			components = getcomps(allPages.suggestions.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				if id == "actions" then
					if selection == "suggestchannel" then
						channelSelect(ia, "Select a suggestions channel...", function(c)
							modifyKey("suggestchannel", c)
							ia:updateDeferred(true)
							updatePage(allPages.suggestions.number)
						end, true, nil, nil, config.suggestchannel)
					elseif selection == "maxupvotes" then
						prompt(ia, "Edit Max Upvotes", {
							{
								question = "Max Upvotes",
								placeholder = "Enter max upvotes...",
								style = "short",
								max = 2,
								required = false
							}
						}, function(mia, responses)
							if mia then
								local response = responses["Max Upvotes"] and tonumber(responses["Max Upvotes"])
								modifyKey("suggestionsmaxupvotes", response)
								updatePage(allPages.suggestions.number)
							end
						end, true)
					elseif selection == "maxdownvotes" then
						prompt(ia, "Edit Max Downvotes", {
							{
								question = "Max Downvotes",
								placeholder = "Enter max downvotes...",
								style = "short",
								max = 2,
								required = false
							}
						}, function(mia, responses)
							if mia then
								local response = responses["Max Downvotes"] and tonumber(responses["Max Downvotes"])
								modifyKey("suggestionsmaxdownvotes", response)
								updatePage(allPages.suggestions.number)
							end
						end, true)
					elseif selection == "suggestionthread" then
						prompt(ia, "Suggestion Thread", {
							{
								question = "What should the thread be named?",
								placeholder = "You can use the same variables as in the suggestion submit embed.",
								style = "short",
								max = 200,
								required = false,
								default = config.suggestionthread
							}
						}, function(mia, responses)
							if mia then
								local response = responses and responses["What should the thread be named?"]
								modifyKey("suggestionthread", response)
								updatePage(allPages.suggestions.number)
							end
						end, true)
					elseif selection == "suggestionsubmittedembeds" then
						multiEmbedEditor(ia, function(embs)
							modifyKey("suggestionsubmittedembeds", embs)
							updatePage(allPages.suggestions.number)
						end, emojis.right .. " **`{submitter.name}`:** The name of the submitter.\n" .. emojis.right .. " **`{submitter.username}`:** The username of the submitter.\n" .. emojis.right .. " **`{submitter.id}`:** The ID of the submitter.\n" .. emojis.right .. " **`{submitter.mention}`:** The mention of the submitter.\n" .. emojis.right .. " **`{submitter.avatar}`:** The avatar URL of the submitter.\n" .. emojis.right .. " **`{suggestion.suggestion}`:** The suggestion that was submitted.\n" .. emojis.right .. " **`{suggestion.upvotes}`:** The number of upvotes on the suggestion.\n" .. emojis.right .. " **`{suggestion.downvotes}`:** The number of downvotes on the suggestion.\n" .. emojis.right .. " **`{suggestion.id}`:** The suggestion ID.\n", config.suggestionsubmittedembeds)
					elseif selection == "suggestionapproveembeds" then
						multiEmbedEditor(ia, function(embs)
							modifyKey("suggestionapproveembeds", embs)
							updatePage(allPages.suggestions.number)
						end, emojis.right .. " **`{submitter.name}`:** The name of the submitter.\n" .. emojis.right .. " **`{submitter.username}`:** The username of the submitter.\n" .. emojis.right .. " **`{submitter.id}`:** The ID of the submitter.\n" .. emojis.right .. " **`{submitter.mention}`:** The mention of the submitter.\n" .. emojis.right .. " **`{submitter.avatar}`:** The avatar URL of the submitter.\n" .. emojis.right .. " **`{approver.name}`:** The name of the approver.\n" .. emojis.right .. " **`{approver.username}`:** The username of the approver.\n" .. emojis.right .. " **`{approver.id}`:** The ID of the approver.\n" .. emojis.right .. " **`{approver.mention}`:** The mention of the approver.\n" .. emojis.right .. " **`{approver.avatar}`:** The avatar URL of the approver.\n" .. emojis.right .. " **`{suggestion.suggestion}`:** The suggestion that was submitted.\n" .. emojis.right .. " **`{suggestion.upvotes}`:** The number of upvotes on the suggestion.\n" .. emojis.right .. " **`{suggestion.downvotes}`:** The number of downvotes on the suggestion.\n" .. emojis.right .. " **`{suggestion.id}`:** The suggestion ID.\n" .. emojis.right .. " **`{suggestion.approvereason}`:** The reason the suggestion was approved.", config.suggestionapproveembeds)
					elseif selection == "suggestiondenyembeds" then
						multiEmbedEditor(ia, function(embs)
							modifyKey("suggestiondenyembeds", embs)
							updatePage(allPages.suggestions.number)
						end, emojis.right .. " **`{submitter.name}`:** The name of the submitter.\n" .. emojis.right .. " **`{submitter.username}`:** The username of the submitter.\n" .. emojis.right .. " **`{submitter.id}`:** The ID of the submitter.\n" .. emojis.right .. " **`{submitter.mention}`:** The mention of the submitter.\n" .. emojis.right .. " **`{submitter.avatar}`:** The avatar URL of the submitter.\n" .. emojis.right .. " **`{denier.name}`:** The name of the denier.\n" .. emojis.right .. " **`{denier.username}`:** The username of the denier.\n" .. emojis.right .. " **`{denier.id}`:** The ID of the denier.\n" .. emojis.right .. " **`{denier.mention}`:** The mention of the denier.\n" .. emojis.right .. " **`{denier.avatar}`:** The avatar URL of the denier.\n" .. emojis.right .. " **`{suggestion.suggestion}`:** The suggestion that was submitted.\n" .. emojis.right .. " **`{suggestion.upvotes}`:** The number of upvotes on the suggestion.\n" .. emojis.right .. " **`{suggestion.downvotes}`:** The number of downvotes on the suggestion.\n" .. emojis.right .. " **`{suggestion.id}`:** The suggestion ID.\n" .. emojis.right .. " **`{suggestion.denyreason}`:** The reason the suggestion was denied.", config.suggestiondenyembeds)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Suggestions",
				emoji = resolveEmoji(emojis.suggestion)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.shift.number),
			color = colors.info,
			components = getcomps(allPages.shift.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				config.shifts = config.shifts or {}

				if id == "actions" then
					if selection == "shiftlogschannel" then
						channelSelect(ia, "Select a logging channel...", function(c)
							modifyKey("shiftlogschannel", c)
							updatePage(allPages.shift.number)
						end, true, nil, nil, config.shiftlogschannel)
					elseif selection == "gamelock" then
						if config.apikey then
							config.shifts = config.shifts or {}
							config.shifts.gamelock = not config.shifts.gamelock
							modifyKey("shifts", config.shifts)
							ia:updateDeferred(true)
							updatePage(allPages.shift.number)
						else
							ia:fail("You must have an ERLC API key linked in order to use this feature.", nil, true)
							updatePage(allPages.shift.number)
						end
					elseif selection == "addtype" or selection == "edittype" then
						config.shifts = config.shifts or {}
						config.shifts.types = config.shifts.types or {}

						if checkLimit(ia, "shift types", isPlusGuild, config.shifts and config.shifts.types, "shiftTypes") then
							return
						end


						local newShiftType = {
							name = nil,
							onshiftrole = nil,
							quota = nil
						}

						local shiftTypeNumber

						local builder

						local function updateBuilder()
							if type(builder) == "table" then
								return ia:editReply({
									embed = {
										title = emojis.clock .. " Shift Type Builder",
										description = emojis.right .. " **Name:** " .. (newShiftType.name or emojis.fail) .. "\n" .. emojis.right .. " **On-Shift Role:** " .. ((newShiftType.onshiftrole and ("<@&" .. newShiftType.onshiftrole .. ">")) or emojis.fail) .. "\n" .. emojis.right .. " **On-Pause Role:** " .. ((newShiftType.onpauserole and ("<@&" .. newShiftType.onpauserole .. ">")) or emojis.fail) .. "\n" .. emojis.right .. " **Quota:** " .. ((newShiftType.quota and readable(newShiftType.quota)) or emojis.fail) .. "\n" .. emojis.right .. " **Required Role:** " .. ((newShiftType.requiredrole and ("<@&" .. newShiftType.requiredrole .. ">")) or emojis.fail) .. "\n" .. emojis.right .. " **Nickname Prefix:** " .. (newShiftType.nicknameprefix or emojis.fail),
										color = colors.info
									},
									components = discordia.Components():selectMenu({
										id = "edit",
										placeholder = "Edit shift type...",
										options = {
											{
												label = "Edit Name",
												emoji = resolvedEmojis.edit,
												value = "name"
											},
											{
												label = "Edit On-Shift Role",
												emoji = resolvedEmojis.role,
												value = "onshiftrole"
											},
											{
												label = "Edit On-Pause Role",
												emoji = resolvedEmojis.role,
												value = "onpauserole"
											},
											{
												label = "Edit Quota",
												emoji = resolvedEmojis.clock,
												value = "quota"
											},
											{
												label = "Edit Required Role",
												emoji = resolvedEmojis.lock,
												value = "requiredrole"
											},
											{
												label = "Edit Nickname Prefix",
												emoji = resolvedEmojis.rename,
												value = "nicknameprefix"
											}
										}
									}):button({
										id = "create",
										label = (selection == "edittype" and "Save") or "Create",
										style = "success",
										emoji = resolvedEmojis.yeswhite,
										actionRow = 2
									}):button({
										id = "cancel",
										label = "Cancel",
										style = "danger",
										emoji = resolvedEmojis.nowhite,
										actionRow = 2
									}):raw()
								}, builder.id)
							else
								builder = ia:reply({
									embed = {
										title = emojis.clock .. " Shift Type Builder",
										description = emojis.right .. " **Name:** " .. (newShiftType.name or emojis.fail) .. "\n" .. emojis.right .. " **On-Shift Role:** " .. ((newShiftType.onshiftrole and ("<@&" .. newShiftType.onshiftrole .. ">")) or emojis.fail) .. "\n" .. emojis.right .. " **On-Pause Role:** " .. ((newShiftType.onpauserole and ("<@&" .. newShiftType.onpauserole .. ">")) or emojis.fail) .. "\n" .. emojis.right .. " **Quota:** " .. ((newShiftType.quota and readable(newShiftType.quota)) or emojis.fail) .. "\n" .. emojis.right .. " **Required Role:** " .. ((newShiftType.requiredrole and ("<@&" .. newShiftType.requiredrole .. ">")) or emojis.fail) .. "\n" .. emojis.right .. " **Nickname Prefix:** " .. (newShiftType.nicknameprefix or emojis.fail),
										color = colors.info
									},
									components = discordia.Components():selectMenu({
										id = "edit",
										placeholder = "Edit shift type...",
										options = {
											{
												label = "Edit Name",
												emoji = resolvedEmojis.edit,
												value = "name"
											},
											{
												label = "Edit On-Shift Role",
												emoji = resolvedEmojis.role,
												value = "onshiftrole"
											},
											{
												label = "Edit On-Pause Role",
												emoji = resolvedEmojis.role,
												value = "onpauserole"
											},
											{
												label = "Edit Quota",
												emoji = resolvedEmojis.clock,
												value = "quota"
											},
											{
												label = "Edit Required Role",
												emoji = resolvedEmojis.lock,
												value = "requiredrole"
											},
											{
												label = "Edit Nickname Prefix",
												emoji = resolvedEmojis.rename,
												value = "nicknameprefix"
											}
										}
									}):button({
										id = "create",
										label = (selection == "edittype" and "Save") or "Create",
										style = "success",
										emoji = resolvedEmojis.yeswhite,
										actionRow = 2
									}):button({
										id = "cancel",
										label = "Cancel",
										style = "danger",
										emoji = resolvedEmojis.nowhite,
										actionRow = 2
									}):raw()
								}, true)

								return
							end
						end

						local function openBuilder()
							updateBuilder()

							onComp(builder, nil, nil, ia.user.id, false, function(bia)
								local id = bia.data.custom_id
								local property = bia.data.values and bia.data.values[1]

								if id == "cancel" then
									bia:updateDeferred(true)
									ia:deleteReply(builder.id)
									updatePage(allPages.shift.number)
									return true
								elseif id == "create" then
									if (not newShiftType.name) or (newShiftType.name == "") then
										bia:fail("You have not set a name for this shift type.", nil, true)
										return
									elseif checkLimit(bia, "shift types", isPlusGuild, config.shifts and config.shifts.types, "shiftTypes") then
										return
									end

									if selection == "addtype" then
										for i, v in pairs(config.shifts and config.shifts.types or {}) do
											if v.name:lower() == newShiftType.name:lower() then
												bia:fail("There is already an existing shift type with that name.", nil, true)
												return
											end
										end

										table.insert(config.shifts.types, newShiftType)
										modifyKey("shifts", config.shifts)

										ia:deleteReply(builder.id)
									else
										config.shifts.types[shiftTypeNumber] = newShiftType
										modifyKey("shifts", config.shifts)

										bia:update({
											embed = {
												description = emojis.success .. " This shift type has been successfully edited.",
												color = colors.success
											},
											components = {}
										})
									end

									updatePage(allPages.shift.number)

									return true
								elseif property == "name" then
									prompt(bia, "Edit Shift Type", {
										{
											question = "Shift type name",
											placeholder = "Enter a name for your shift type...",
											style = "short",
											required = false,
											max = 45,
											default = newShiftType.name
										}
									}, function(mia, response)
										if mia then
											local newName = response["Shift type name"]

											if newName and newName ~= "" then
												newShiftType.name = newName
												mia:updateDeferred(true)
											else
												mia:fail("You did not provide a name for this shift type.", nil, true)
											end

											updateBuilder()
										end
									end, true)
								elseif property == "onshiftrole" then
									roleSelect(bia, "Select an on-shift role...", function(onshiftrole)
										newShiftType.onshiftrole = onshiftrole
										updateBuilder()
									end, true, nil, nil, newShiftType.onshiftrole)
								elseif property == "onpauserole" then
									roleSelect(bia, "Select an on-pause role...", function(onpauserole)
										newShiftType.onpauserole = onpauserole
										updateBuilder()
									end, true, nil, nil, newShiftType.onpauserole)
								elseif property == "quota" then
									ask(bia, "Edit Shift Type Quota", "Enter a valid interval... (i.e. 2h, 3h, 30m)", nil, nil, "short", true, newShiftType.quota, function(_, mia, response)
										if mia then
											local converted = _G.convert(response or "")
											if (converted) and (converted <= 0) then
												converted = nil
											end
											if converted then
												newShiftType.quota = converted
												mia:updateDeferred(true)
											else
												mia:fail("You did not provide a valid interval.", nil, true)
											end
											updateBuilder()
										end
									end)
								elseif property == "requiredrole" then
									roleSelect(bia, "Select a required role...", function(requiredrole)
										newShiftType.requiredrole = requiredrole
										updateBuilder()
									end, true, nil, nil, newShiftType.requiredrole)
								elseif property == "nicknameprefix" then
									prompt(bia, "Edit Nickname Prefix", {
										{
											question = "Nickname Prefix",
											placeholder = "Enter a nickname prefix for members who are on shift",
											required = false,
											style = "short"
										}
									}, function(mia, responses)
										if mia then
											local prefix = responses and responses["Nickname Prefix"]

											if prefix and prefix ~= "" then
												if prefix:len() > 15 then
													updateBuilder()
													return mia:fail("The nickname prefix cannot be longer than 15 characters.", nil, true)
												end

												newShiftType.nicknameprefix = prefix
												mia:updateDeferred(true)
												return updateBuilder()
											else
												newShiftType.nicknameprefix = nil
												updateBuilder()
											end
										end
									end, false)
								end
							end)
						end

						if selection == "edittype" then
							if type(config.shifts.types) ~= "table" or table.count(config.shifts.types) <= 0 then
								updatePage(allPages.shift.number)
								return ia:fail("You have not created any shift types.", nil, true)
							end

							local options = {}

							for i, st in ipairs(config.shifts.types) do
								table.insert(options, {
									label = string.truncate(st.name, 100),
									value = i,
									emoji = resolvedEmojis.edit
								})
							end

							optionsSelect(ia, "Select a shift type...", function(opt)
								opt = tonumber(opt)

								newShiftType = config.shifts.types[opt]
								shiftTypeNumber = opt

								openBuilder()
							end, true, options, 1, nil, true)
						else
							openBuilder()
						end
					elseif selection == "removetype" then
						config.shifts = config.shifts or {}
						config.shifts.types = config.shifts.types or {}

						if (not config.shifts.types) or table.count(config.shifts.types) <= 0 then
							ia:fail("No shift types are configured in this server.", nil, true)
							return
						end

						local sts = {}

						for sti, st in pairs(config.shifts.types) do
							table.insert(sts, {
								label = st.name,
								value = tostring(sti),
								emoji = resolvedEmojis.delete
							})
						end

						optionsSelect(ia, "Select a shift type to delete...", function(opt)
							table.remove(config.shifts.types, tonumber(opt))
							modifyKey("shifts", config.shifts)
							updatePage(allPages.shift.number)
						end, true, sts, nil, nil, true)
					elseif selection == "waveinterval" then
						prompt(ia, "Edit Wave Interval", {
							{
								question = "Wave Interval",
								placeholder = "i.e. 'every day at 16:00 EDT', 'every sunday at 12:00 CEST'",
								style = "short",
								required = false
							}
						}, function(mia, responses)
							if mia then
								local response = responses and responses["Wave Interval"]

								if response then
									local interval, err = intervalParse(response)

									if interval then
										if interval.type == "daily" or interval.type == "weekly" then
											local nextRun = intervalNextRun(interval)

											confirm(mia, "Shift waves will end " .. readable(interval) .. ", meaning the current wave will end at <t:" .. nextRun .. ":F>. Is this correct?", function(result, ria, r)
												if result == true then
													config.shifts = config.shifts or {}
													config.shifts.waveinterval = interval
													modifyKey("shifts", config.shifts)
												end

												updatePage(allPages.shift.number)
											end, true)

										else
											updatePage(allPages.shift.number)
											mia:fail("Wave interval only supports daily/weekly.", nil, true)
										end
									else
										updatePage(allPages.shift.number)
										mia:fail(err, nil, true)
									end
								else
									config.shifts.waveinterval = nil
									modifyKey("shifts", config.shifts)
									updatePage(allPages.shift.number)
									mia:updateDeferred(true)
								end
							end
						end)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Shift Management",
				emoji = resolveEmoji(emojis.clock)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.activity.number),
			color = colors.info,
			components = getcomps(allPages.activity.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				if id == "actions" then
					if selection == "loalogschannel" then
						channelSelect(ia, "Select a logging channel...", function(c)
							modifyKey("loalogschannel", c)
							updatePage(allPages.activity.number)
						end, true, nil, nil, config.loalogschannel)
					elseif selection == "loasenabled" then
						modifyKey("loasenabled", not config.loasenabled)
						ia:updateDeferred(true)
						updatePage(allPages.activity.number)
					elseif selection == "loarole" then
						roleSelect(ia, "Select an LOA role...", function(r)
							modifyKey("loarole", r)
							updatePage(allPages.activity.number)
						end, true, nil, nil, config.loarole)
					elseif selection == "loanickname" then
						prompt(ia, "Edit LOA Nickname", {
							{
								question = "LOA Nickname",
								placeholder = "Click `View LOA Nickname Variables` to see all variables.",
								style = "short"
							}
						}, function(mia, responses)
							if responses and responses["LOA Nickname"] then
								modifyKey("loanickname", responses["LOA Nickname"])
								updatePage(allPages.activity.number)
							end
						end, true)
					elseif selection == "loanickvars" then
						ia:reply({
							embed = {
								title = emojis.json .. " Variables",
								description = emojis.right .. " **`{member.name}`:** The name of the member on LOA.\n" .. emojis.right .. " **`{member.username}`:** The username of the member on LOA.",
								color = colors.blank
							}
						}, true)
					elseif selection == "loamaxlength" then
						prompt(ia, "Edit Max LOA Length", {
							{
								question = "What is the maximum allowed LOA length?",
								placeholder = "Example: 14d, 30d, 3m",
								style = "short",
								required = true
							}
						}, function(mia, responses)
							if mia and responses then
								local response = (responses and responses["What is the maximum allowed LOA length?"] and convert(responses["What is the maximum allowed LOA length?"])) or nil

								if response then
									modifyKey("loamaxlength", response)
									updatePage(allPages.activity.number)
								end
							end
						end, true)
					elseif selection == "trackmodcalls" then
						if not config.apikey then
							return ia:fail("You must have an ERLC API key linked in order to use this feature.", nil, true)
						end

						modifyKey("trackModcalls", not config.trackModcalls)
						ia:updateDeferred(true)
						updatePage(allPages.activity.number)
					elseif selection == "loamentionables" then
						mentionableSelect(ia, "Select mentionables to ping for LOA requests...", function(ms)
							modifyKey("loamentionables", ms)
							updatePage(allPages.activity.number)
						end, true, 0, 5, config.loamentionables)
					end

				end
			end,
			identifier = {
				text = "Activity Management",
				emoji = resolveEmoji(emojis.chart)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.economy.number),
			color = colors.info,
			components = getcomps(allPages.economy.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selections = ia.data.values
				local first = selections and selections[1]

				if id == "actions" then
					if first == "toggle" then
						config.economy.disabled = not config.economy.disabled
						modifyKey("economy", config.economy)
						ia:updateDeferred(true)
						updatePage(allPages.economy.number)
					elseif first == "currency" then
						prompt(ia, "Edit Currency", {
							{
								question = "Edit Currency",
								placeholder = "Enter the new currency...",
								default = ((config.economy.currency or ""):match("^<a?:[%w_]+:%d+>$") and "\\" .. config.economy.currency or config.economy.currency),
								max = 35,
								required = false
							}
						}, function(mia, responses)
							if mia then
								config.economy.currency = responses["Edit Currency"]
								modifyKey("economy", config.economy)
								updatePage(allPages.economy.number)
							end
						end, true)
					elseif first == "initial" then
						prompt(ia, "Edit Initial Amount", {
							{
								question = "Edit Initial Amount",
								placeholder = "Example: 1000, 500, 25000...",
								default = (config.economy.initial and tonumber(config.economy.initial) and (config.economy.initial ~= 0) and config.economy.initial) or "",
								required = false
							}
						}, function(mia, responses)
							if mia then
								config.economy.initial = (responses["Edit Initial Amount"] and tonumber(responses["Edit Initial Amount"])) or nil
								modifyKey("economy", config.economy)
								updatePage(allPages.economy.number)
							end
						end, true)
					elseif first == "economylogchannel" then
						channelSelect(ia, "Select a channel...", function(id)
							modifyKey("economylogchannel", id)
							updatePage(allPages.economy.number)
						end, true, 0, 1, config.economylogchannel)
					elseif first == "limits" then
						optionsSelect(ia, "Select an action to edit amounts...", function(selected, oia)
							config.economy.limits = config.economy.limits or {}

							if selected == "crime" then
								prompt(oia, "Edit Crime Amounts", {
									{
										question = "Success Minimum Amount",
										placeholder = "Minimum amount for a successful crime...",
										default = config.economy.limits and config.economy.limits.crime and config.economy.limits.crime.success and config.economy.limits.crime.success.min,
										required = false
									},
									{
										question = "Success Maximum Amount",
										placeholder = "Maximum amount for a successful crime...",
										default = config.economy.limits and config.economy.limits.crime and config.economy.limits.crime.success and config.economy.limits.crime.success.max,
										required = false
									},
									{
										question = "Fail Percentage",
										placeholder = "Percentage lost from wallet for a unsuccessful crime...",
										default = config.economy.limits and config.economy.limits.crime and config.economy.limits.crime.fail and (config.economy.limits.crime.fail < 1 and (config.economy.limits.crime.fail * 100)),
										required = false
									},
								}, function(mia, responses)
									if mia and responses then
										config.economy.limits.crime = config.economy.limits.crime or {}
										config.economy.limits.crime.success = config.economy.limits.crime.success or {}

										local minVal = tonumber(responses["Success Minimum Amount"])
										local maxVal = tonumber(responses["Success Maximum Amount"])
										local failVal = tonumber(responses["Fail Percentage"])

										if minVal then
											config.economy.limits.crime.success.min = minVal
										else
											config.economy.limits.crime.success.min = nil
										end

										if maxVal then
											config.economy.limits.crime.success.max = maxVal
										else
											config.economy.limits.crime.success.max = nil
										end

										if failVal then
											config.economy.limits.crime.fail = failVal > 1 and failVal / 100 or failVal
										else
											config.economy.limits.crime.fail = nil
										end

										modifyKey("economy", config.economy)
										updatePage(allPages.economy.number)
									end
								end, true)
							elseif selected == "work" then
								prompt(oia, "Edit Work Amounts", {
									{
										question = "Success Minimum Amount",
										placeholder = "Minimum amount for successfully work...",
										default = config.economy.limits and config.economy.limits.work and config.economy.limits.work.success and config.economy.limits.work.success.min,
										required = false
									},
									{
										question = "Success Maximum Amount",
										placeholder = "Maximum amount for successfully work...",
										default = config.economy.limits and config.economy.limits.work and config.economy.limits.work.success and config.economy.limits.work.success.max,
										required = false
									},
								}, function(mia, responses)
									if mia and responses then
										config.economy.limits.work = config.economy.limits.work or {}
										config.economy.limits.work.success = config.economy.limits.work.success or {}

										local minVal = tonumber(responses["Success Minimum Amount"])
										local maxVal = tonumber(responses["Success Maximum Amount"])

										config.economy.limits.work.success.min = minVal or nil
										config.economy.limits.work.success.max = maxVal or nil

										modifyKey("economy", config.economy)
										updatePage(allPages.economy.number)
									end
								end, true)

							elseif selected == "beg" then
								prompt(oia, "Edit Beg Amounts", {
									{
										question = "Success Minimum Amount",
										placeholder = "Minimum amount for successfully begging...",
										default = config.economy.limits and config.economy.limits.beg and config.economy.limits.beg.success and config.economy.limits.beg.success.min,
										required = false
									},
									{
										question = "Success Maximum Amount",
										placeholder = "Maximum amount for successfully begging...",
										default = config.economy.limits and config.economy.limits.beg and config.economy.limits.beg.success and config.economy.limits.beg.success.max,
										required = false
									},
								}, function(mia, responses)
									if mia and responses then
										config.economy.limits.beg = config.economy.limits.beg or {}
										config.economy.limits.beg.success = config.economy.limits.beg.success or {}

										local minVal = tonumber(responses["Success Minimum Amount"])
										local maxVal = tonumber(responses["Success Maximum Amount"])

										config.economy.limits.beg.success.min = minVal or nil
										config.economy.limits.beg.success.max = maxVal or nil

										modifyKey("economy", config.economy)
										updatePage(allPages.economy.number)
									end
								end, true)

							elseif selected == "daily" then
								prompt(oia, "Edit Daily Amounts", {
									{
										question = "Success Minimum Amount",
										placeholder = "Minimum amount for a successful daily...",
										default = config.economy.limits and config.economy.limits.daily and config.economy.limits.daily.success and config.economy.limits.daily.success.min,
										required = false
									},
									{
										question = "Success Maximum Amount",
										placeholder = "Maximum amount for a successful daily...",
										default = config.economy.limits and config.economy.limits.daily and config.economy.limits.daily.success and config.economy.limits.daily.success.max,
										required = false
									},
								}, function(mia, responses)
									if mia and responses then
										config.economy.limits.daily = config.economy.limits.daily or {}
										config.economy.limits.daily.success = config.economy.limits.daily.success or {}

										local minVal = tonumber(responses["Success Minimum Amount"])
										local maxVal = tonumber(responses["Success Maximum Amount"])

										config.economy.limits.daily.success.min = minVal or nil
										config.economy.limits.daily.success.max = maxVal or nil

										modifyKey("economy", config.economy)
										updatePage(allPages.economy.number)
									end
								end, true)
							end
						end, true, {
							{
								label = "Crime",
								value = "crime",
								emoji = resolvedEmojis.edit
							},
							{
								label = "Work",
								value = "work",
								emoji = resolvedEmojis.edit
							},
							{
								label = "Beg",
								value = "beg",
								emoji = resolvedEmojis.edit
							},
							{
								label = "Daily",
								value = "daily",
								emoji = resolvedEmojis.edit
							}
						}, 1, nil, true)
					elseif first == "blacklistedroles" then
						roleSelect(ia, "Select blacklisted roles...", function(roles)
							config.economy.blacklistedroles = roles or {}
							modifyKey("economy", config.economy)
							updatePage(allPages.economy.number)
						end, true, nil, 5, config.economy.blacklistedroles or nil)
					elseif first == "createreply" then
						if first == "createreply" and checkLimit(ia, "custom replies", isPlusGuild, config.economy.replies, "economyReplies") then
							updatePage(allPages.economy.number)
							return
						end
						optionsSelect(ia, "Select an action to edit replies...", function(selected, oia)
							if selected then
								local fields = {
									{
										question = "Message",
										placeholder = "Enter the reply message...",
										required = true,
										style = "paragraph"
									}
								}

								if selected == "crime" then
									table.insert(fields, {
										question = "Success (Y/N)",
										placeholder = "Is this reply triggered on a successful action?",
										required = true,
										max = 1
									})
								end

								prompt(oia, "Edit Reply for " .. string.capitalize(selected), fields, function(mia, responses)
									if mia and responses then
										local message = responses["Message"]
										local isSuccess = nil

										if selected == "crime" then
											local successInput = (responses["Success (Y/N)"] or ""):upper()
											isSuccess = successInput == "Y"
										end

										config.economy.replies = config.economy.replies or {}
										config.economy.replies[selected] = config.economy.replies[selected] or {}

										table.insert(config.economy.replies[selected], {
											message = message,
											success = isSuccess
										})

										modifyKey("economy", config.economy)
										updatePage(allPages.economy.number)
									end
								end, true)
							end
						end, true, {
							{
								label = "Crime",
								value = "crime",
								emoji = resolvedEmojis.edit
							},
							{
								label = "Work",
								value = "work",
								emoji = resolvedEmojis.edit
							},
							{
								label = "Rob",
								value = "rob",
								emoji = resolvedEmojis.edit
							},
							{
								label = "Beg",
								value = "beg",
								emoji = resolvedEmojis.edit
							}
						}, 1, nil, true)
					elseif first == "editreply" or first == "deletereply" then
						if first == "editreply" and checkLimit(ia, "custom replies", isPlusGuild, config.economy.replies, "economyReplies", true) then
							updatePage(allPages.economy.number)
							return
						end
						optionsSelect(ia, "Select an action...", function(selected, oia)
							if selected and config.economy.replies[selected] and #config.economy.replies[selected] > 0 then
								local opts = {}
								for i, replyData in ipairs(config.economy.replies[selected]) do
									table.insert(opts, {
										label = "Custom " .. string.capitalize(selected) .. " Reply #" .. i,
										value = i,
										description = string.truncate(replyData.message, 30),
										emoji = ((replyData.success and resolvedEmojis.success) or resolvedEmojis.fail)
									})
								end

								optionsSelect(oia, "Select a reply to " .. (first == "editreply" and "edit" or "delete") .. "...", function(index, oia)
									if index then
										if first == "editreply" then
											local replyData = config.economy.replies[selected][tonumber(index)]
											prompt(oia, "Edit Reply", {
												{
													question = "Message",
													placeholder = "Enter the reply message...",
													default = replyData.message,
													required = true,
													style = "paragraph"
												},
												{
													question = "Success (Y/N)",
													placeholder = "Is this reply triggered on a successful action?",
													default = replyData.success and "Y" or "N",
													required = true,
													max = 1
												}
											}, function(mia, responses)
												if mia and responses then
													local message = responses["Message"]
													local successInput = responses["Success (Y/N)"]:upper()
													local isSuccess = successInput == "Y"

													config.economy.replies[selected][tonumber(index)].message = message
													config.economy.replies[selected][tonumber(index)].success = isSuccess

													modifyKey("economy", config.economy)
													updatePage(allPages.economy.number)
												end
											end, true)

										elseif first == "deletereply" then
											table.remove(config.economy.replies[selected], tonumber(index))
											if (config.economy.replies[selected] and (not next(config.economy.replies[selected]))) then
												config.economy.replies[selected] = nil
											end
											modifyKey("economy", config.economy)
											updatePage(allPages.economy.number)
										end
									end
								end, true, opts, 1, nil, true)
							else
								oia:fail("No custom replies exist for that action.", nil, true)
							end
						end, true, {
							{
								label = "Crime",
								value = "crime",
								emoji = resolvedEmojis.edit
							},
							{
								label = "Work",
								value = "work",
								emoji = resolvedEmojis.edit
							},
							{
								label = "Rob",
								value = "rob",
								emoji = resolvedEmojis.edit
							},
							{
								label = "Beg",
								value = "beg",
								emoji = resolvedEmojis.edit
							}
						}, 1, nil, true)
					elseif first == "cooldowns" then
						optionsSelect(ia, "Select an action...", function(selected, oia)
							prompt(oia, "Edit " .. string.capitalize(selected) .. " Cooldown", {
								{
									question = "Edit Cooldown",
									placeholder = "Example: 20s, 1m, 5h",
									default = (config.economy.cooldowns and config.economy.cooldowns[selected] and readable(config.economy.cooldowns[selected])) or "",
									required = false
								}
							}, function(mia, responses)
								if mia then
									local response = (responses and responses["Edit Cooldown"] and convert(responses["Edit Cooldown"])) or nil
									config.economy.cooldowns = config.economy.cooldowns or {}
									config.economy.cooldowns[selected] = response
									modifyKey("economy", config.economy)
									updatePage(allPages.economy.number)
								end
							end, true)
						end, true, {
							{
								label = "Crime",
								value = "crime",
								emoji = resolvedEmojis.edit
							},
							{
								label = "Work",
								value = "work",
								emoji = resolvedEmojis.edit
							},
							{
								label = "Rob",
								value = "rob",
								emoji = resolvedEmojis.edit
							},
							{
								label = "Beg",
								value = "beg",
								emoji = resolvedEmojis.edit
							},
							{
								label = "Gamble (Blackjack, Slotmachine)",
								value = "gamble",
								emoji = resolvedEmojis.edit
							},
						}, 1, nil, true)
					elseif first == "createcollectionrole"then
						local data = { role = "", amount = nil, target = "wallet", cooldown = nil }

						if first == "createcollectionrole" and checkLimit(ia, "collection roles", isPlusGuild, config.economy.collectionroles, "collectionRoles") then
							updatePage(allPages.economy.number)
							return
						end

						prompt(ia, "Create Collection Role", {
							{
								question = "What role should receive this collection?",
								component = discordia.SelectMenu({
									id = "role",
									placeholder = "Select a collection role...",
									type = "role",
									max_values = 1,
									required = true,
								}):raw(),
								validate = function(response)
									if table.find(config.economy.collectionroles, function(value, id)
										return id == response
									end) then
										return false, "There is already a collection for that role."
									end

									return true
								end
							},
							{
								question = "How much money should be collected?",
								placeholder = "Example: 1000, 450, 10000...",
								required = true,
							},
							{
								question = "Where should the money be added?",
								component = discordia.SelectMenu({
									id = "target",
									placeholder = "Select an option...",
									max_values = 1,
									required = false,
									options = {
										{
											label = "Wallet",
											value = "wallet"
										},
										{
											label = "Bank",
											value = "bank"
										}
									}
								}):raw()
							},
							{
								question = "What should the collection cooldown be?",
								placeholder = "Example: 20m, 5h, 2d...",
								required = false,
							}
						}, function(mia, responses)
							if mia then
								local role = responses and responses["What role should receive this collection?"]
								local amount = responses and responses["How much money should be collected?"]
								local target = responses and responses["Where should the money be added?"]
								local cooldown = responses and responses["What should the collection cooldown be?"]

								data.role = role
								data.amount = amount and math.max(0, tonumber(amount) or 0)
								data.target = target or "wallet"
								data.cooldown = (cooldown and convert(cooldown)) or 0

								config.economy.collectionroles = config.economy.collectionroles or {}

								if type(config.economy.collectionroles) ~= "table" then
									config.economy.collectionroles = {}
								end

								table.insert(config.economy.collectionroles, data)

								modifyKey("economy", config.economy)
								updatePage(allPages.economy.number)
							end
						end, true)

					elseif first == "editcollectionrole" then
						if not config.economy.collectionroles or #config.economy.collectionroles == 0 then
							return ia:fail("No collection roles exist.", nil, true)
						end

						if first == "editcollectionrole" and checkLimit(ia, "collection roles", isPlusGuild, config.economy.collectionroles, "collectionRoles", true) then
							updatePage(allPages.economy.number)
							return
						end

						local opts = {}
						for i, data in ipairs(config.economy.collectionroles) do
							local role = interaction.guild:getRole(data.role)
							table.insert(opts, {
								label = "Collection Role #" .. i,
								value = i,
								description = (role and role.name or "Unknown") ..
									" " .. emojis.dot .. " " .. (formatNumber(data.amount or 0)) ..
									" " .. emojis.dot .. " " .. (data.target or "wallet"),
								emoji = resolvedEmojis.edit
							})
						end

						return optionsSelect(ia, "Select a collection role to edit...", function(index, oia)
							if index then
								local data = config.economy.collectionroles[tonumber(index)]

								prompt(oia, "Edit Collection Role", {
									{
										question = "What role should receive this collection?",
										component = discordia.SelectMenu({
											id = "role",
											placeholder = "Select a collection role...",
											type = "role",
											max_values = 1,
											required = false,
											default_values = data and data.role and {{ id = data.role, type = "role" }} or nil
										}):raw(),
										validate = function(response)
											if table.find(config.economy.collectionroles, function(value, id)
												return id == response
											end) then
												return false, "There is already a collection for that role."
											end

											return true
										end
									},
									{
										question = "How much money should be collected?",
										placeholder = "Example: 1000, 450, 10000...",
										default = data and data.amount,
										required = false,
									},
									{
										question = "Where should the money be added?",
										component = discordia.SelectMenu({
											id = "target",
											placeholder = "Select an option...",
											max_values = 1,
											required = false,
											options = {
												{
													label = "Wallet",
													value = "wallet",
													default = (data and data.target == "wallet" and true)
												},
												{
													label = "Bank",
													value = "bank",
													default = (data and data.target == "bank" and true)
												}
											}
										}):raw()
									},
									{
										question = "What should the collection cooldown be?",
										placeholder = "Example: 20m, 5h, 2d...",
										required = false,
										default = data and data.cooldown and readable(data.cooldown)
									}
								}, function(mia, responses)
									if mia then
										local role = responses and responses["What role should receive this collection?"]
										local amount = responses and responses["How much money should be collected?"]
										local target = responses and responses["Where should the money be added?"]
										local cooldown = responses and responses["What should the collection cooldown be?"]

										local newAmount = amount and math.max(0, tonumber(amount) or 0)
										local newCooldown = cooldown and convert(cooldown)

										data.role = role ~= nil and role ~= data.role and role or data.role
										data.amount = newAmount ~= nil and newAmount ~= data.amount and newAmount or data.amount
										data.target = target ~= nil and target ~= data.target and target or data.target
										data.cooldown = newCooldown ~= nil and newCooldown ~= data.cooldown and newCooldown or data.cooldown

										config.economy.collectionroles = config.economy.collectionroles or {}

										if type(config.economy.collectionroles) ~= "table" then
											config.economy.collectionroles = {}
										end

										config.economy.collectionroles[tonumber(index)] = data

										modifyKey("economy", config.economy)
										updatePage(allPages.economy.number)
									end
								end, true)
							end
						end, true, opts, 1, nil, true)

					elseif first == "deletecollectionrole" then
						if not config.economy.collectionroles or #config.economy.collectionroles == 0 then
							return ia:fail("No collection roles exist.", nil, true)
						end

						local opts = {}
						for i, data in ipairs(config.economy.collectionroles) do
							if (not data.role) or (not data.amount) then
								table.remove(config.economy.collectionroles, i)
								modifyKey("economy", config.economy)
							end
							local role = interaction.guild:getRole(data.role)
							table.insert(opts, {
								label = "Collection Role #" .. i,
								value = i,
								description = (role and role.name or "Unknown") .. " " .. emojis.dot .. " " .. formatNumber(data.amount) .. " " .. emojis.dot .. " " .. data.target,
								emoji = resolvedEmojis.delete
							})
						end

						optionsSelect(ia, "Select a collection role to delete...", function(index, oia)
							if index then
								table.remove(config.economy.collectionroles, tonumber(index))
								modifyKey("economy", config.economy)
								updatePage(allPages.economy.number)
							end
						end, true, opts, 1, nil, true)
					elseif first == "createshopitem" or first == "editshopitem" then
						local itemIndex = nil
						local itemData = { name = "", description = nil, price = nil, role = nil, useonpurchase = false, message = nil, id = snowGen:next() }

						if first == "createshopitem" and checkLimit(ia, "shop items", isPlusGuild, config.economy.shop, "shopItems") then
							updatePage(allPages.economy.number)
							return
						elseif first == "editshopitem" and checkLimit(ia, "shop items", isPlusGuild, config.economy.shop, "shopItems", true) then
							updatePage(allPages.economy.number)
							return
						end

						local builder

						local function startBuilder()
							local function updateBuilder(int)
								local comps = discordia.Components()
									:selectMenu({
										id = "shopitembuildermenu",
										placeholder = "Select an action...",
										actionRow = 1,
										min_values = 0,
										max_values = 1,
										options = {
											{ label = "Edit Name", value = "editname", emoji = resolvedEmojis.edit },
											{ label = "Edit Description", value = "editdescription", emoji = resolvedEmojis.edit },
											{ label = "Edit Price", value = "editprice", emoji = resolvedEmojis.edit },
											{ label = "Edit Role", value = "editrole", emoji = resolvedEmojis.role },
											{ label = "Toggle Use-on-Purchase", value = "toggleuseonpurchase", emoji = resolvedEmojis.shop},
											{ label = "Edit Message", value = "editmessage", emoji = resolvedEmojis.chat},
										}
									})
									:button({
										id = "save",
										label = "Save",
										style = "success",
										emoji = resolvedEmojis.yeswhite
									})
									:button({
										id = "cancel",
										label = "Cancel",
										style = "danger",
										emoji = resolvedEmojis.nowhite
									})
									:button({
										id = "variables",
										label = "Variables",
										style = "secondary",
										emoji = resolvedEmojis.json
									})

								local parsed = itemData.message and parseTable({ message = itemData.message }, {
									["item.name"] = (itemData.name and itemData.name ~= "" and itemData.name) or "N/A",
									["item.id"] = (itemData.id and itemData.id ~= "" and itemData.id) or "N/A",
									["item.price"] = (itemData.price and itemData.price ~= "" and formatNumber(tonumber(itemData.price))) or "N/A",
									["item.role"] = (itemData.role and itemData.role ~= "" and "<@&" .. itemData.role .. ">") or "N/A",
									["economy.currency"] = ((config.economy and config.economy.currency ~= "" and config.economy.currency) or emojis.quack or "N/A"),
									["user.name"] = "`{user.name}`",
									["user.username"] = "`{user.username}`",
									["user.id"] = "`{user.id}`",
									["user.mention"] = "`{user.mention}`",
									["timestamp"] = tostring(os.time())
								})

								local payload = {
									embed = {
										title = emojis.shop .. " Shop Item Builder",
										color = colors.yellow,
										description = emojis.right .. " **Name:** " .. ((itemData.name ~= "" and itemData.name) or emojis.fail) .. "\n" ..
											emojis.right .. " **Description:** " .. (itemData.description ~= "" and itemData.description or emojis.fail) .. "\n" ..
											emojis.right .. " **Price:** " .. formatNumber(tonumber(itemData.price or 0)) .. "\n" .. emojis.right ..
											" **Role:** " .. ((itemData.role and "<@&" .. itemData.role .. ">") or emojis.fail) .. "\n" .. emojis.right ..
											" **Use on Purchase:** " .. ((itemData.useonpurchase and emojis.success) or emojis.fail) .. "\n" .. emojis.right ..
											" **Message:** " .. ((parsed and parsed.message) or emojis.fail) .. "\n" .. emojis.right .. " **ID:** " .. itemData.id
									},
									components = comps:raw(),
									ephemeral = true
								}


								if type(builder) == "table" then
									if int then
										int:update(payload)
									else
									ia:editReply(payload, builder.id)
									end
								else
									builder = ia:reply(payload, true)
								end
							end

							updateBuilder()

							onComp(builder, nil, nil, ia.user.id, false, function(cia)
								local id = cia.data.custom_id
								local selected = cia.data.values and cia.data.values[1]

								if id == "shopitembuildermenu" then
									if selected == "editname" then
										prompt(cia, "Shop Item Name", {
											{
												question = "Enter Item Name",
												placeholder = "Example: Golden Duck",
												default = itemData.name or "",
											}
										}, function(_, responses)
											itemData.name = responses["Enter Item Name"] or ""
											updateBuilder()
										end, true)

									elseif selected == "editdescription" then
										prompt(cia, "Shop Item Description", {
											{
												question = "Enter Description",
												placeholder = "Optional: Describe this item",
												default = itemData.description or "",
												required = false
											}
										}, function(_, responses)
											itemData.description = responses["Enter Description"]
											updateBuilder()
										end, true)

									elseif selected == "editprice" then
										prompt(cia, "Shop Item Price", {
											{
												question = "Enter Price",
												placeholder = "Example: 5000",
												default = tostring(itemData.price or "")
											}
										}, function(_, responses)
											itemData.price = tonumber(responses["Enter Price"]) or 0
											updateBuilder()
										end, true)

									elseif selected == "editrole" then
										roleSelect(cia, "Select a role to give on purchase...", function(role)
											itemData.role = role
											updateBuilder()
										end, true, nil, 1, itemData.role or nil)

									elseif selected == "toggleuseonpurchase" then
										itemData.useonpurchase = not itemData.useonpurchase
										updateBuilder()
										cia:updateDeferred(true)

									elseif selected == "editmessage" then
										prompt(cia, "Custom Message", {
											{
												question = "Message",
												placeholder = "Optional: Enter a custom message that is send on use...",
												style = "paragraph",
												default = (itemData and itemData.message)
											}
										}, function(mia, responses)
											if mia then
												if responses and responses["Message"] ~= nil or responses["Message"] ~= "" then
													itemData.message = responses["Message"]
													updateBuilder()
												else
													cia:fail("The message cannot be empty.", nil, true)
												end
											end
										end, true)
									end
								elseif id == "save" then
									if type(config.economy.shop) ~= "table" then
										config.economy.shop = {}
									end
									if (not itemData.name) or (not itemData.price) then
										updateBuilder()
										return cia:fail("You must set a name and a price.", nil, true)
									end
									if first == "editshopitem" and itemIndex then
										config.economy.shop[itemIndex] = itemData
									else
										table.insert(config.economy.shop, itemData)
									end

									modifyKey("economy", config.economy)
									ia:deleteReply(builder.id)
									updatePage(allPages.economy.number)
								elseif id == "cancel" then
									updatePage(allPages.economy.number)
									ia:deleteReply(builder.id)
								elseif id == "variables" then
									cia:reply({
										embed = {
											title = emojis.json .. " Variables",
											description = emojis.right .. " **`{item.name}`:** The name of the item.\n" ..
												emojis.right .. " **`{item.id}`:** The ID of the item.\n" ..
												emojis.right .. " **`{item.price}`:** The price of the item.\n" ..
												emojis.right .. " **`{economy.currency}`:** The configured economy currency.\n" ..
												emojis.right .. " **`{user.name}`:** The user's name.\n" ..
												emojis.right .. " **`{user.username}`:** The user's username.\n" ..
												emojis.right .. " **`{user.id}`:** The user's ID.\n" ..
												emojis.right .. " **`{user.mention}`:** The user's mention.\n" ..
												emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp when the item was used.",
											color = colors.blank
										},
									}, true)
								end
							end)
						end

						if first == "editshopitem" then
							if not config.economy.shop or #config.economy.shop == 0 then
								return ia:fail("No shop items exist.", nil, true)
							end

							local opts = {}
							for i, data in ipairs(config.economy.shop) do
								table.insert(opts, {
									label = data.name or ("Shop Item #" .. i),
									value = i,
									description = (data.price and (formatNumber(data.price) .. " " .. (config.economy.currency or ""))) or "No price set",
									emoji = resolvedEmojis.edit
								})
							end

							optionsSelect(ia, "Select a shop item to edit...", function(index)
								if index then
									itemIndex = tonumber(index)
									itemData = config.economy.shop[itemIndex]
									startBuilder()
								end
							end, true, opts, 1, nil, true)
						else
							startBuilder()
						end

					elseif first == "deleteshopitem" then
						if not config.economy.shop or #config.economy.shop == 0 then
							return ia:fail("No shop items exist.", nil, true)
						end

						local opts = {}
						for i, data in ipairs(config.economy.shop) do
							table.insert(opts, {
								label = data.name or ("Shop Item #" .. i),
								value = i,
								description = (data.price and (formatNumber(data.price))) or "N/A",
								emoji = resolvedEmojis.delete
							})
						end

						optionsSelect(ia, "Select a shop item to delete...", function(index, oia)
							if index then
								table.remove(config.economy.shop, tonumber(index))
								modifyKey("economy", config.economy)
								updatePage(allPages.economy.number)
							end
						end, true, opts, 1, nil, true)
					elseif first == "createmultiplier" then
						config.economy = config.economy or {}
						config.economy.multipliers = config.economy.multipliers or {}

						prompt(ia, "Create Multiplier Role", {
							{
								question = "What role should receive this multiplier?",
								component = discordia.SelectMenu({
									id = "role",
									placeholder = "Select a multiplier role...",
									type = "role",
									max_values = 1
								}):raw(),
								validate = function(response)
									if table.find(config.economy.multipliers, function(value, id)
										return id == response
									end) then
										return false, "There is already a multiplier for that role."
									end

									return true
								end
							},
							{
								question = "How much should income be multiplied by?",
								placeholder = 'Enter a valid number, such as "0.5" for 0.5x or "2" for 2x...',
								style = "short",
								required = true,
								validate = function(response)
									local num = tonumber(response)

									if not num then
										return false, "Please enter a valid number."
									end

									if num <= 0 then
										return false, "Multiplier must be greater than 0."
									end

									return true
								end
							}
						}, function(mia, responses)
							if mia then
								local role = responses["What role should receive this multiplier?"]
								local multiplier = responses["How much should income be multiplied by?"]

								config.economy.multipliers[role] = multiplier
								modifyKey("economy", config.economy)
								updatePage(allPages.economy.number)
							end
						end, true)
					elseif first == "deletemultiplier" then
						if not (config.economy and config.economy.multipliers and next(config.economy.multipliers)) then
							return ia:fail("You have not created any economy multipliers.", nil, true)
						end

						local options = {}
						for id, multiplier in pairs(config.economy.multipliers) do
							local role = interaction.guild:getRole(id)

							table.insert(options, {
								label = string.truncate(role and role.name or id, 100),
								description = multiplier .. "x income multiplier",
								value = id,
								emoji = resolvedEmojis.delete
							})
						end

						optionsSelect(ia, "Select an economy multiplier...", function(opt)
							config.economy.multipliers[opt] = nil
							modifyKey("economy", config.economy)
							updatePage(allPages.economy.number)
						end, true, options, 1, nil, true)
					elseif first == "reseteconomy" then
						confirm(ia, "Are you sure you want to reset all server economy?", function(result, ria)
							if result == true then
								local success, err = sqldb:set(interaction.guild.id, {economy = "nil"}, "RESET_ECONOMY", interaction.member)
								modifyKey("economylogchannel", nil)
								if not success then
									return ria:fail(err, nil, true)
								end
								updatePage(allPages.economy.number)
							end
						end, true, 2000)
					elseif first == "resetbalances" then
						confirm(ia, "Are you sure you want to reset all account balances?", function(result, ria)
							if result == true then
								for _, account in pairs(config.economy.accounts or {}) do
									if account and account.balance then
										account.balance = { bank = 0, wallet = 0 }
									end
								end
								db:send(interaction.guild, "economylogchannel", {
									embed = {
										title = emojis.delete .. " Economy Balances Reset",
										author = author(interaction.member),
										color = colors.fail,
										description = getUserString(interaction.member) .. " has reset all account balances for this server."
									}
								})
								updatePage(allPages.economy.number)
							end
						end, true, 2000)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Server Economy",
				emoji = resolveEmoji(emojis.quack)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.tickets.number),
			color = colors.info,
			components = getcomps(allPages.tickets.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selections = ia.data.values
				local first = selections and selections[1]

				local function buildPanel(data, buildPanelInteraction, buildPanelID)
					local ia = buildPanelInteraction or ia

					local realpanels = {}
					for i, v in pairs(config.panels or {}) do
						local exists = false
						local PC = interaction.guild:getChannel(v.channel)

						if PC then
							if PC:getMessage(i) then
								exists = true
							end
						end

						if exists then
							realpanels[i] = v
						end
					end
					if table.count(realpanels or {}) ~= table.count(config.panels or {}) then
						modifyKey("panels", realpanels)
					end

					if (not buildPanelID) and checkLimit(ia, "ticket panels", isPlusGuild, config.panels, "ticketPanels") then
						return
					elseif buildPanelID and checkLimit(ia, "ticket panels", isPlusGuild, config.panels, "ticketPanels", true) then
						return
					end

					local panelBuilder = ia:reply({
						embed = {
							description = emojis.loading,
							color = colors.blank
						}
					}, true)

					if not panelBuilder then
						return
					end

					local panel = (data and table.deepcopy(data)) or {
						channel = nil,
						subjects = {},
						embeds = nil,
						disabled = nil
					}

					local function updateBuilder(int)
						local panelBuilderComps = discordia.Components()

						local editPanelSelect = discordia.SelectMenu({
							id = "editproperty",
							min_values = 1,
							max_values = 1,
							actionRow = 1,
							placeholder = "Edit panel...",
							options = {
								{
									label = "Edit Channel",
									value = "channel",
									emoji = resolvedEmojis.channel
								},
								{
									label = "Add Subject",
									value = "addsubject",
									emoji = resolvedEmojis.plus
								},
								{
									label = "Edit Subject",
									value = "editsubject",
									emoji = resolvedEmojis.edit
								},
								{
									label = "Delete Subject",
									value = "deletesubject",
									emoji = resolvedEmojis.delete
								},
								{
									label = "Edit Panel Embeds",
									value = "embed",
									emoji = resolvedEmojis.art
								},
								{
									label = "Import",
									value = "import",
									emoji = resolvedEmojis.import
								},
								{
									label = "Export",
									value = "export",
									emoji = resolvedEmojis.export
								},
								{
									label = (panel and panel.disabled and "Enable") or "Disable",
									value = "toggle",
									description = (panel and panel.disabled and "This panel is currently disabled.") or "This panel is currently enabled.",
									emoji = (panel and panel.disabled and resolvedEmojis.off) or resolvedEmojis.on
								}
							}
						})

						panelBuilderComps:selectMenu(editPanelSelect)

						local sendPanelButton = discordia.Button({
							id = "send",
							label = "Send Panel",
							emoji = resolvedEmojis.yeswhite,
							style = "success",
							actionRow = 2
						})

						panelBuilderComps:button(sendPanelButton)

						local cancelPanelButton = discordia.Button({
							id = "cancel",
							label = "Cancel",
							emoji = resolvedEmojis.nowhite,
							style = "danger",
							actionRow = 2
						})

						panelBuilderComps:button(cancelPanelButton)

						local subjectstr = ""

						local emb = {}
						local comps = {}

						if panel then
							for i, v in pairs(panel.subjects or {}) do
								subjectstr = subjectstr .. emojis.space .. emojis.right .. " " .. v.name .. (((i ~= #panel.subjects) and "\n") or "")
							end

							if not next(panel.subjects or {}) then
								subjectstr = emojis.space .. emojis.right .. " None"
							end

							emb = {
								title = emojis.ticket .. " Ticket Panel Builder",
								description =
								((panel.disabled and "-# " .. emojis.power .. " This panel is currently **disabled**.\n") or "")
								.. emojis.right .. " **Channel:** " .. ((panel.channel and "<#" .. panel.channel .. ">") or "None")
								.. "\n" .. emojis.right .. " **Ticket Subjects:**\n" .. subjectstr
								.. "\n" .. emojis.right .. " **Embeds:** " .. ((panel.embed and "Custom") or "None"),
								color = colors.blank
							}

							comps = panelBuilderComps:raw()
						else
							if int then
								int:updateDeferred(true)
							end
							return ia:deleteReply(panelBuilder.id)
						end

						if int then
							return int:update({
								embed = emb,
								components = comps
							})
						else
							return ia:editReply({
								embed = emb,
								components = comps
							}, panelBuilder.id)
						end
					end

					local s, e = updateBuilder()

					if e then
						ia:editReply({
							embed = {
								description = emojis.warning .. " " .. e,
								color = colors.warning
							},
							components = {}
						}, panelBuilder.id)
						return
					end

					onComp(panelBuilder, nil, nil, ia.user.id, false, function(bia)
						local id = bia.data.custom_id
						local selection = bia.data.values and bia.data.values[1]

						local function buildSubject(data, buildInteraction)
							local bia = buildInteraction or bia
							local subjectBuilder = bia:reply({
								embed = {
									description = emojis.loading,
									color = colors.blank
								}
							}, true)

							if not subjectBuilder then
								return
							end

							local subject = (data and table.deepcopy(data)) or {
								name = nil,
								description = nil,
								emoji = nil,
								requireReason = false,
								category = nil,
								support = {},
								mentionables = {},
								tickets = {},
								embeds = {},
								transcriptschannel = nil,
								form = nil
							}

							local function updateSubjectBuilder(int, onError)
								local emb = {}
								local comps = {}

								if subject then
									local supportrolestr = ""
									for i, v in pairs(subject.support or {}) do
										supportrolestr = supportrolestr .. emojis.space .. emojis.right .. " <@&" .. v .. ">" .. (((i ~= #subject.support) and "\n") or "")
									end
									if not next(subject.support or {}) then
										supportrolestr = emojis.space .. emojis.right .. " None"
									end

									local mentionablestr = ""
									for i, v in pairs(subject.mentionables or {}) do
										mentionablestr = mentionablestr .. emojis.space .. emojis.right .. " <@" .. ((interaction.guild:getRole(v) and "&") or "") .. v .. ">" .. (((i ~= #subject.mentionables) and "\n") or "")
									end
									if not next(subject.mentionables or {}) then
										mentionablestr = emojis.space .. emojis.right .. " None"
									end

									local blacklistedrolestr = ""
									for i, v in pairs(subject.blacklistedroles or {}) do
										blacklistedrolestr = blacklistedrolestr .. emojis.space .. emojis.right .. " <@&" .. v .. ">" .. (((i ~= #subject.blacklistedroles) and "\n") or "")
									end
									if not next(subject.blacklistedroles or {}) then
										blacklistedrolestr = emojis.space .. emojis.right .. " None"
									end

									emb = {
										title = emojis.ticket .. " Ticket Subject Builder",
										description = emojis.right .. " **Name:** " .. (subject.name or "None") .. "\n" .. emojis.right .. " **Description:** " .. (subject.description or "None") .. "\n" .. emojis.right .. " **Emoji:** " .. (subject.emoji or "None") .. "\n" .. emojis.right .. " **Category:** " .. ((subject.category and interaction.guild:getCategory(subject.category) and interaction.guild:getCategory(subject.category).name) or "None") .. --[["\n" .. emojis.right .. " **Require Close Reason:** " .. ((subject.requireReason and emojis.success) or emojis.fail) .. ]] "\n" .. emojis.right .. " **Transcripts Channel:** " .. ((subject.transcriptschannel and "<#" .. subject.transcriptschannel .. ">") or "N/A") .. "\n" .. emojis.right .. " **Unclaimed Ticket Name:** " .. (subject.ticketname or "None") .. "\n" .. emojis.right .. " **Claimed Ticket Name:** " .. (subject.claimedticketname or "None") .. "\n" .. emojis.right .. " **Ticket Claim Mode:** " .. (subject.ticketclaimmode and (subject.ticketclaimmode:usub(1, 1):upper() .. subject.ticketclaimmode:usub(2)) or "Hide") .. "\n" .. emojis.right .. " **Form:**\n" .. emojis.space .. emojis.right .. " " .. ((subject.form and subject.form.questions and table.count(subject.form.questions) > 0 and table.concatFn(subject.form.questions, "\n" .. emojis.space .. emojis.right .. " ", function(q)
											return "`" .. q.title .. "` (" .. string.capitalize(q.style) .. " Response)" .. ((q.required and emojis.lock) or "")
										end)) or "No questions added") .. "\n" .. emojis.right .. " **Support Roles:**\n" .. supportrolestr .. "\n" .. emojis.right .. " **Mentionables:**\n" .. mentionablestr .. "\n" .. emojis.right .. " **Blacklisted Roles:**\n" .. blacklistedrolestr,
										color = colors.blank
									}

									comps = subjectBuilderComps:raw()
								else
									if int then
										int:updateDeferred(true)
									end
									bia:deleteReply(subjectBuilder.id)
								end

								if int then
									return int:update({
										embed = emb,
										components = comps
									})
								else
									return bia:editReply({
										embed = emb,
										components = comps
									}, subjectBuilder.id)
								end
							end

							local s, e = updateSubjectBuilder()

							if e then
								bia:editReply({
									embed = {
										description = emojis.warning .. " " .. e,
										color = colors.warning
									},
									components = {}
								}, subjectBuilder.id)
								return
							end

							onComp(subjectBuilder, nil, nil, bia.user.id, false, function(sia)
								local id = sia.data.custom_id
								local selection = sia.data.values and sia.data.values[1]

								if id == "editproperty" then
									if selection == "name" then
										question(sia, "Edit subject name...", "What should this subject be called?", function(_, mia, response)
											if mia and response then
												subject.name = response
												mia:updateDeferred(true)
												updateSubjectBuilder()
											end
										end, "short", 0, 25)
									elseif selection == "description" then
										question(sia, "Edit subject description...", "What's this subject about?", function(_, mia, response)
											if mia and response then
												subject.description = response
												mia:updateDeferred(true)
												updateSubjectBuilder()
											end
										end, "short", 0, 75, false)
									elseif selection == "emoji" then
										question(sia, "Edit subject emoji...", "Enter a custom emoji's id...", function(_, mia, response)
											if mia and response then
												local emoji = interaction.guild:getEmoji(response)

												if emoji then
													subject.emoji = emoji.mentionString
													mia:updateDeferred(true)
												else
													mia:fail("I could not find that emoji. Ensure it's a custom one from this server.", nil, true)
												end

												updateSubjectBuilder()
											end
										end, "short", 0, 20, false)
									elseif selection == "category" then
										question(sia, "Edit subject category...", "Enter the category's name...", function(_, mia, response)
											if mia and response then
												local cat = interaction.guild.categories:find(function(c)
													return c.id == response or c.name:lower():find(response:lower())
												end)

												if cat then
													subject.category = cat.id
													mia:updateDeferred(true)
												else
													cat, e = interaction.guild:createCategory(response:usub(1, 25))
													if cat then
														subject.category = cat.id
														mia:updateDeferred(true)
													else
														mia:fail("Failed to create the **" .. response:usub(1, 25) .. "** channel category.\n-# " .. e:usub(1, 16), nil, true)
													end
												end
												updateSubjectBuilder()
											end
										end, "short", 0, 50)
									elseif selection == "ticketname" then
										question(sia, "Edit unclaimed ticket name...", "What should unclaimed tickets in this subject be named?", function(_, mia, response)
											if mia and response then
												subject.ticketname = response
												mia:updateDeferred(true)
												updateSubjectBuilder()
											end
										end, "short", nil, nil, false)
									elseif selection == "claimedticketname" then
										question(sia, "Edit claimed ticket name...", "What should claimed tickets in this subject be named?", function(_, mia, response)
											if mia and response then
												subject.claimedticketname = response
												mia:updateDeferred(true)
												updateSubjectBuilder()
											end
										end, "short", nil, nil, false)
									elseif selection == "ticketclaimmode" then
										local opts = {
											{
												label = "Hide",
												value = "hide",
												description = "Hide the ticket from other support staff when claimed.",
												emoji = resolvedEmojis.invis
											},
											{
												label = "Lock",
												value = "lock",
												description = "User can still see the channel but not type.",
												emoji = resolvedEmojis.lock
											},
											{
												label = "Open",
												value = "open",
												description = "Keep it open like unclaimed.",
												emoji = resolvedEmojis.eye
											}
										}

										optionsSelect(sia, "Select a claimed ticket mode...", function(opt)
											if not opt then
												return sia:fail("Invalid ticket claimed mode selected.", nil, true)
											end

											local chosenMode = tostring(opt)
											if chosenMode ~= "hide" and chosenMode ~= "lock" and chosenMode ~= "open" then
												return sia:fail("Invalid ticket claim mode selected.", nil, true)
											end

											subject.ticketclaimmode = chosenMode
											updateSubjectBuilder()
										end, true, opts, 1, nil, true)
									elseif selection == "addformquestion" then
										if subject.form and checkLimit(sia, "questions for this form", isPlusGuild, subject.form.questions, "ticketForms") then
											return
										end

										local newQuestion = {
											title = nil,
											placeholder = nil,
											style = "short",
											min = nil,
											max = nil,
											required = true
										}

										local questionBuilder = sia:reply({
											embed = {
												description = emojis.loading,
												color = colors.blank
											}
										}, true)

										local function updateQuestionBuilder()
											if questionBuilder and type(questionBuilder) == "table" then
												return sia:editReply({
													embed = {
														title = "Question Builder",
														color = colors.info,
														description = emojis.right .. " **Question:** " .. (newQuestion.title or "N/A") .. "\n" .. emojis.right .. " **Placeholder:** " .. (newQuestion.placeholder or "N/A") .. "\n" .. emojis.right .. " **Style:** " .. string.capitalize(newQuestion.style) .. "\n" .. emojis.right .. " **Minimum Response Length:** " .. (newQuestion.min or "None") .. "\n" .. emojis.right .. " **Maximum Response Length:** " .. (newQuestion.max or "None") .. "\n" .. emojis.right .. " **Required:** " .. ((newQuestion.required and emojis.success) or emojis.fail)
													},
													components = discordia.Components():selectMenu({
														id = "edit",
														placeholder = "Edit new question...",
														actionRow = 1,
														options = {
															{
																label = "Edit Question",
																value = "title",
																emoji = resolvedEmojis.document
															},
															{
																label = "Edit Placeholder",
																value = "placeholder",
																emoji = resolvedEmojis.draft
															},
															{
																label = "Toggle Style",
																value = "style",
																emoji = resolvedEmojis.edit
															},
															{
																label = "Edit Minimum Response Length",
																value = "min",
																emoji = resolvedEmojis.edit
															},
															{
																label = "Edit Maximum Response Length",
																value = "max",
																emoji = resolvedEmojis.edit
															},
															{
																label = "Toggle Required",
																value = "required",
																emoji = resolvedEmojis.lock
															}
														}
													}):button({
														id = "create",
														label = "Create",
														style = "success",
														emoji = resolvedEmojis.yeswhite
													}):button({
														id = "cancel",
														label = "Cancel",
														style = "danger",
														emoji = resolvedEmojis.nowhite
													}):raw()
												}, questionBuilder.id)
											else
												questionBuilder = sia:reply({
													{
														embed = {
															title = "Question Builder",
															color = colors.info,
															description = emojis.right .. " **Question:** " .. (newQuestion.title or "N/A") .. "\n" .. emojis.right .. " **Placeholder:** " .. (newQuestion.placeholder or "N/A") .. "\n" .. emojis.right .. " **Style:** " .. string.capitalize(newQuestion.style) .. "\n" .. emojis.right .. " **Minimum Response Length:** " .. (newQuestion.min or "None") .. "\n" .. emojis.right .. " **Maximum Response Length:** " .. (newQuestion.max or "None") .. "\n" .. emojis.right .. " **Required:** " .. ((newQuestion.required and emojis.success) or emojis.fail)
														},
														components = discordia.Components():selectMenu({
															id = "edit",
															placeholder = "Edit new question...",
															actionRow = 1,
															options = {
																{
																	label = "Edit Question",
																	value = "title",
																	emoji = resolvedEmojis.document
																},
																{
																	label = "Edit Placeholder",
																	value = "placeholder",
																	emoji = resolvedEmojis.draft
																},
																{
																	label = "Toggle Style",
																	value = "style",
																	emoji = resolvedEmojis.edit
																},
																{
																	label = "Edit Minimum Response Length",
																	value = "min",
																	emoji = resolvedEmojis.edit
																},
																{
																	label = "Edit Maximum Response Length",
																	value = "max",
																	emoji = resolvedEmojis.edit
																},
																{
																	label = "Toggle Required",
																	value = "required",
																	emoji = resolvedEmojis.lock
																}
															}
														}):button({
															id = "create",
															label = "Create",
															style = "success",
															emoji = resolvedEmojis.yeswhite
														}):button({
															id = "cancel",
															label = "Cancel",
															style = "danger",
															emoji = resolvedEmojis.nowhite
														}):raw()
													}
												})
											end
										end

										updateQuestionBuilder()

										onComp(questionBuilder, nil, nil, sia.user.id, false, function(qia)
											local id = qia.data.custom_id
											local first = qia.data.values and qia.data.values[1]

											if id == "edit" then
												if first == "title" then
													ask(qia, "Edit Question", "Enter a question...", nil, nil, "short", false, nil, function(_, mia, response)
														if mia then
															if response == "" then
																response = nil
															end
															newQuestion.title = response
															mia:updateDeferred(true)
															updateQuestionBuilder()
														end
													end, 0, 45)
												elseif first == "placeholder" then
													ask(qia, "Edit Placeholder", "Enter placeholder text...", nil, nil, "short", false, nil, function(_, mia, response)
														if mia then
															if response == "" then
																response = nil
															end
															newQuestion.placeholder = response
															mia:updateDeferred(true)
															updateQuestionBuilder()
														end
													end, 0, 100)
												elseif first == "min" then
													ask(qia, "Edit Minimum Response Length", "Enter a valid number...", nil, nil, "short", false, nil, function(_, mia, response)
														if mia then
															response = tonumber(tostring(response))
															if response then
																response = math.clamp(response, 0, 4000)
															end
															newQuestion.min = response
															mia:updateDeferred(true)
															updateQuestionBuilder()
														end
													end)
												elseif first == "max" then
													ask(qia, "Edit Maximum Response Length", "Enter a valid number...", nil, nil, "short", false, nil, function(_, mia, response)
														if mia then
															response = tonumber(tostring(response))
															if response then
																response = math.clamp(response, 0, 4000)
															end
															newQuestion.max = response
															mia:updateDeferred(true)
															updateQuestionBuilder()
														end
													end)
												elseif first == "style" then
													if newQuestion.style == "short" then
														newQuestion.style = "paragraph"
													else
														newQuestion.style = "short"
													end
													qia:updateDeferred(true)
													updateQuestionBuilder()
												elseif first == "required" then
													newQuestion.required = not newQuestion.required
													qia:updateDeferred(true)
													updateQuestionBuilder()
												end
											elseif id == "create" then
												if subject.form and checkLimit(sia, "questions for this form", isPlusGuild, subject.form.questions, "ticketForms") then
													return
												end

												if (not newQuestion.title) or newQuestion.title == "" then
													qia:fail("You have not set a title for this question.", nil, true)
													return
												end

												subject.form = subject.form or {}
												subject.form.questions = subject.form.questions or {}

												table.insert(subject.form.questions, newQuestion)
												qia:updateDeferred(true)
												sia:deleteReply(questionBuilder.id)
												updateSubjectBuilder()
												return true
											elseif id == "cancel" then
												qia:updateDeferred(true)
												sia:deleteReply(questionBuilder.id)
												updateSubjectBuilder()
												return true
											end
										end)
									elseif selection == "removeformquestion" then
										if subject.form and subject.form.questions and table.count(subject.form.questions) > 0 then
											local qopts = {}
											for qid, q in pairs(subject.form.questions) do
												table.insert(qopts, {
													label = q.title,
													description = string.capitalize(q.style .. " Response"),
													value = tostring(qid),
													emoji = resolvedEmojis.delete
												})
											end
											optionsSelect(sia, "Select a question to delete...", function(opt)
												table.remove(subject.form.questions, tonumber(opt))
												updateSubjectBuilder()
											end, true, qopts, nil, nil, true)
										else
											sia:fail("There are not any questions added to this form.", nil, true)
										end
									elseif selection == "support" then
										local rs = sia:reply({
											components = discordia.Components({
												discordia.SelectMenu({
													id = "supportroles",
													placeholder = "Select support roles...",
													min_values = 1,
													max_values = 5,
													type = "role",
													actionRow = 1
												})
											}):raw()
										}, true)

										onComp(rs, nil, nil, sia.user.id, true, function(ria)
											subject.support = ria.data.values or {}
											updateSubjectBuilder()
											sia:deleteReply(rs.id)
											ria:updateDeferred(true)
										end)
									elseif selection == "transcriptschannel" then
										local cs = sia:reply({
											components = discordia.Components({
												discordia.SelectMenu({
													id = "transcriptselect",
													placeholder = "Select transcripts channel...",
													min_values = 0,
													max_values = 1,
													type = "channel",
													actionRow = 1
												})
											}):raw()
										}, true)

										onComp(cs, nil, nil, sia.user.id, true, function(cia)
											subject.transcriptschannel = cia.data.values and cia.data.values[1]
											updateSubjectBuilder()
											sia:deleteReply(cs.id)
											cia:updateDeferred(true)
										end)
									elseif selection == "mentionables" then
										local rs = sia:reply({
											components = discordia.Components({
												discordia.SelectMenu({
													id = "mentionablesselect",
													placeholder = "Select mentionables...",
													min_values = 0,
													max_values = 5,
													type = "mentionable",
													actionRow = 1
												})
											}):raw()
										}, true)

										onComp(rs, nil, nil, sia.user.id, true, function(ria)
											subject.mentionables = ria.data.values or {}
											updateSubjectBuilder()
											sia:deleteReply(rs.id)
											ria:updateDeferred(true)
										end)
									elseif selection == "blacklistedroles" then
										local rs = sia:reply({
											components = discordia.Components({
												discordia.SelectMenu({
													id = "blacklistedroles",
													placeholder = "Select blacklisted roles...",
													min_values = 0,
													max_values = 5,
													type = "role",
													actionRow = 1
												})
											}):raw()
										}, true)

										onComp(rs, nil, nil, sia.user.id, true, function(ria)
											subject.blacklistedroles = ria.data.values or {}
											updateSubjectBuilder()
											sia:deleteReply(rs.id)
											ria:updateDeferred(true)
										end)
									elseif selection == "openembed" then
										multiEmbedEditor(sia, function(emb)
											subject.embeds = subject.embeds or {}
											subject.embeds.open = emb
											updateSubjectBuilder()
										end, emojis.right .. " **`{opener.mention}`:** The mention of the member that opened the ticket.\n" .. emojis.right .. " **`{opener.name}`:** The name of the member that opened the ticket.\n" .. emojis.right .. " **`{opener.username}`:** The username of the member that opened the ticket.\n" .. emojis.right .. " **`{opener.id}`:** The ID of the member that opened the ticket.\n" .. emojis.right .. " **`{roblox.name}`:** The Roblox username of the ticket opener.\n" .. emojis.right .. " **`{roblox.display}`:** The Roblox display name of the ticket opener.\n" .. emojis.right .. " **`{roblox.id}`:** The Roblox user ID of the ticket opener.\n" .. emojis.right .. " **`{roblox.profile}`:** The Roblox profile link of the ticket opener.\n" .. emojis.right .. " **`{roblox.hyperlink}`:** The Roblox username hyperlinked to the Roblox profile link of the ticket opener.\n" .. emojis.right .. " **`{ticket.id}`:** The ID of the ticket.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the ticket was opened.", subject.embeds and subject.embeds.open)
									elseif selection == "closeembed" then
										multiEmbedEditor(sia, function(emb)
											subject.embeds = subject.embeds or {}
											subject.embeds.close = emb
											updateSubjectBuilder()
										end, emojis.right .. " **`{closer.mention}`:** The mention of the member that closed the ticket.\n" .. emojis.right .. " **`{closer.name}`:** The name of the member that closed the ticket.\n" .. emojis.right .. " **`{closer.username}`:** The username of the member that closed the ticket.\n" .. emojis.right .. " **`{closer.id}`:** The ID of the member that closed the ticket.\n" .. emojis.right .. " **`{owner.mention}`:** The mention of the member that owns the ticket.\n" .. emojis.right .. " **`{owner.name}`:** The name of the member that owns the ticket.\n" .. emojis.right .. " **`{owner.username}`:** The username of the member that owns the ticket.\n" .. emojis.right .. " **`{owner.id}`:** The ID of the member that owns the ticket.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the ticket was closed.\n" .. emojis.right .. " **`{reason}`:** The close reason, or `N/A`.", subject.embeds and subject.embeds.close)
									elseif selection == "claimembed" then
										multiEmbedEditor(sia, function(emb)
											subject.embeds = subject.embeds or {}
											subject.embeds.claim = emb
											updateSubjectBuilder()
										end, emojis.right .. " **`{claimer.mention}`:** The mention of the member that claimed the ticket.\n" .. emojis.right .. " **`{claimer.name}`:** The name of the member that claimed the ticket.\n" .. emojis.right .. " **`{claimer.username}`:** The username of the member that claimed the ticket.\n" .. emojis.right .. " **`{claimer.id}`:** The ID of the member that claimed the ticket.\n" .. emojis.right .. " **`{owner.mention}`:** The mention of the member that owns the ticket.\n" .. emojis.right .. " **`{owner.name}`:** The name of the member that owns the ticket.\n" .. emojis.right .. " **`{owner.username}`:** The username of the member that owns the ticket.\n" .. emojis.right .. " **`{owner.id}`:** The ID of the member that owns the ticket.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the ticket was claimed.", subject.embeds and subject.embeds.claim)
									elseif selection == "unclaimembed" then
										multiEmbedEditor(sia, function(emb)
											subject.embeds = subject.embeds or {}
											subject.embeds.unclaim = emb
											updateSubjectBuilder()
										end, emojis.right .. " **`{unclaimer.mention}`:** The mention of the member that unclaimed the ticket.\n" .. emojis.right .. " **`{unclaimer.name}`:** The name of the member that unclaimed the ticket.\n" .. emojis.right .. " **`{unclaimer.username}`:** The username of the member that unclaimed the ticket.\n" .. emojis.right .. " **`{unclaimer.id}`:** The ID of the member that unclaimed the ticket.\n" .. emojis.right .. " **`{owner.mention}`:** The mention of the member that owns the ticket.\n" .. emojis.right .. " **`{owner.name}`:** The name of the member that owns the ticket.\n" .. emojis.right .. " **`{owner.username}`:** The username of the member that owns the ticket.\n" .. emojis.right .. " **`{owner.id}`:** The ID of the member that owns the ticket.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the ticket was unclaimed.", subject.embeds and subject.embeds.unclaim)
									elseif selection == "requestembed" then
										multiEmbedEditor(sia, function(emb)
											subject.embeds = subject.embeds or {}
											subject.embeds.request = emb
											updateSubjectBuilder()
										end, emojis.right .. " **`{requester.mention}`:** The mention of the member that is requesting to close the ticket.\n" .. emojis.right .. " **`{requester.name}`:** The name of the member that is requesting to close the ticket.\n" .. emojis.right .. " **`{requester.username}`:** The username of the member that is requesting to close the ticket.\n" .. emojis.right .. " **`{requester.id}`:** The ID of the member that is requesting to close the ticket.\n" .. emojis.right .. " **`{owner.mention}`:** The mention of the member that owns the ticket.\n" .. emojis.right .. " **`{owner.name}`:** The name of the member that owns the ticket.\n" .. emojis.right .. " **`{owner.username}`:** The username of the member that owns the ticket.\n" .. emojis.right .. " **`{owner.id}`:** The ID of the member that owns the ticket.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the ticket was requested to be closed.\n" .. emojis.right .. " **`{reason}`:** The closerequest reason, or `N/A`.", subject.embeds and subject.embeds.request)
									elseif selection == "variables" then
										sia:reply({
											embed = {
												title = emojis.json .. " Variables",
												description = "**Unclaimed Ticket Name**\n" .. emojis.right .. " **`{member.name}`:** The nickname of the member that opened the ticket.\n" .. emojis.right .. " **`{member.username}`:** The username of the member that opened the ticket.\n" .. emojis.right .. " **`{member.id}`:** The ID of the member that opened the ticket.\n" .. emojis.right .. " **`{ticket.id}`:** The ID of the ticket.\n**Claimed Ticket Name**\n" .. emojis.right .. " **`{member.name}`:** The nickname of the member that opened the ticket.\n" .. emojis.right .. " **`{member.username}`:** The username of the member that opened the ticket.\n" .. emojis.right .. " **`{member.id}`:** The ID of the member that opened the ticket.\n" .. emojis.right .. " **`{claimer.name}`:** The nickname of the member that claimed the ticket.\n" .. emojis.right .. " **`{claimer.username}`:** The username of the member that claimed the ticket.\n" .. emojis.right .. " **`{claimer.id}`:** The ID of the member that claimed the ticket.\n" .. emojis.right .. " **`{ticket.id}`:** The ID of the ticket.",
												color = colors.blank
											}
										}, true)
									end
								elseif id == "finish" then
									if (not subject.name) or (subject.name == "") then
										sia:fail("You have not set a name for this subject.", nil, true)
										return
									elseif (not subject.category) then
										sia:fail("You have not set a category for this subject.", nil, true)
										return
									elseif (not subject.support) or (table.count(subject.support) <= 0) then
										sia:fail("You have not set any support roles for this subject.", nil, true)
										return
									end

									subject.embeds = subject.embeds or {}

									subject.embeds.open = subject.embeds.open or {{
										title = subject.name,
										description = "> -# *Thank you for contacting support.*\n> A support member will assist you shortly.",
										color = colors.success
									}}

									subject.embeds.close = subject.embeds.close or {{
										title = "Ticket Closed",
										description = "> This ticket has been closed by {closer.mention}.",
										color = colors.fail
									}}

									subject.embeds.claim = subject.embeds.claim or {{
										title = "Ticket Claimed",
										description = "> {claimer.mention} will be assisting you today.\n> -# Thank you for your patience.",
										color = colors.success
									}}

									subject.embeds.unclaim = subject.embeds.unclaim or {{
										title = "Ticket Unclaimed",
										description = "> {unclaimer.mention} has unclaimed this ticket.\n> -# Please be patient while another support member arrives to assist you.",
										color = colors.warning
									}}

									subject.embeds.request = subject.embeds.request or {{
										title = "Ticket Close Request",
										description = "> {requester.mention} is requesting to close this ticket.\n> **Reason:** {reason}",
										color = colors.info
									}}

									subject.ticketname = subject.ticketname or "ticket-{member.name}"

									subject.tickets = subject.tickets or {}

									if data then
										for i, v in pairs(panel.subjects) do
											if v.name == data.name then
												table.remove(panel.subjects, i)
												break
											end
										end
									end

									table.insert(panel.subjects, subject)

									bia:deleteReply(subjectBuilder.id)
									sia:updateDeferred(true)
									updateBuilder()

									coroutine.wrap(function()
										local c = interaction.guild:getCategory(subject.category)
										if c and subject then
											local everyone = c:getPermissionOverwriteFor(interaction.guild.defaultRole)
											if everyone then
												everyone:denyPermissions(discordia.enums.permission.readMessages)
											end
											for i, v in pairs(subject.support) do
												local overwrite = c:getPermissionOverwriteFor(interaction.guild:getRole(v))
												if overwrite then
													overwrite:allowPermissions(discordia.enums.permission.readMessages, discordia.enums.permission.sendMessages, discordia.enums.permission.addReactions, discordia.enums.permission.embedLinks, discordia.enums.permission.attachFiles)
												end
											end
										end
									end)()
									return true
								elseif id == "cancel" then
									subject = nil
									updateSubjectBuilder(sia)
									return true
								end
							end)
						end

						if id == "editproperty" then
							if selection == "channel" then
								local rs = bia:reply({
									components = discordia.Components({
										discordia.SelectMenu({
											id = "channel",
											placeholder = "Select panel channel...",
											min_values = 1,
											max_values = 1,
											type = "channel",
											actionRow = 1
										})
									}):raw()
								}, true)

								onComp(rs, nil, nil, bia.user.id, true, function(ria)
									panel.channel = ria.data.values and ria.data.values[1]
									updateBuilder()
									bia:deleteReply(rs.id)
									ria:updateDeferred(true)
								end)
							elseif selection == "editsubject" then
								ask(bia, "Edit Subject", "Enter the subject you wish to edit's name...", nil, nil, "short", false, nil, function(_, mia, response)
									if mia then
										if response and response ~= "" then
											for _, sbj in pairs(panel.subjects or {}) do
												if sbj.name:lower():find(response:lower()) then
													buildSubject(sbj, mia)
													return
												end
											end

											return mia:fail("No subject was found with that name.", nil, true)
										else
											return mia:fail("You must provide a valid subject name.", nil, true)
										end
									end
								end)
							elseif selection == "addsubject" then
								buildSubject()
							elseif selection == "deletesubject" then
								ask(bia, "Delete Subject", "Enter the subject you wish to delete's name...", nil, nil, "short", false, nil, function(_, mia, response)
									if mia then
										if response and response ~= "" then
											for i, sbj in pairs(panel.subjects or {}) do
												if sbj.name:lower():find(response:lower()) then
													table.remove(panel.subjects, i)
													updateBuilder(mia)
													return
												end
											end

											return mia:fail("No subject was found with that name.", nil, true)
										else
											return mia:fail("You must provide a valid subject name.", nil, true)
										end
									end
								end)
							elseif selection == "embed" then
								multiEmbedEditor(bia, function(emb)
									panel.embeds = emb
									updateBuilder(bia)
								end, nil, panel.embeds)
							elseif selection == "import" then
								ask(bia, "Import from Exportable", "Enter a valid Ducky exportable code...", nil, nil, "short", false, nil, function(_, mia, response)
									local imported, err = _G.import(response or "_", "panel")

									if imported then
										panel = imported
										mia:updateDeferred(true)
									else
										mia:fail(err, nil, true)
									end
									updateBuilder()
								end)
							elseif selection == "export" then
								local exported, err = _G.export(panel, bia.user, "panel")

								if exported then
									bia:success("Your panel has been exported successfully! Here's your exportable code: ```\n" .. exported .. "```\n-# " .. emojis.right .. " You can share this code with other people for them to import your panel.", nil, true)
								else
									bia:fail(err, nil, true)
								end
								updateBuilder()
							elseif selection == "toggle" then
								panel.disabled = not panel.disabled
								updateBuilder(bia)
							end
						elseif id == "send" then
							if (not buildPanelID) and checkLimit(ia, "ticket panels", isPlusGuild, config.panels, "ticketForms") then
								return
							end

							if not panel.channel then
								bia:fail("You have not set a channel to send this panel to.", nil, true)
								return
							elseif (not panel.subjects) or (#panel.subjects <= 0) then
								bia:fail("You have not added any subjects to this panel.", nil, true)
								return
							elseif (not panel.embeds) then
								bia:fail("You have not created an embed for this panel.", nil, true)
								return
							end

							local ch = interaction.guild:getChannel(panel.channel)

							if ch then
								local tosend = {
									embeds = panel.embeds
								}

								tosend.components = discordia.Components()

								local subjectSelect = discordia.SelectMenu({
									id = "subjectselect",
									placeholder = "Select a subject...",
									min_values = 0,
									max_values = 1,
									actionRow = 1
								})

								for subjectid, subject in pairs(panel.subjects) do
									subjectSelect:option(subject.name, tostring(subjectid), subject.description, nil, subject.emoji and _G.resolveEmoji(subject.emoji))
								end

								tosend.components:selectMenu(subjectSelect)
								tosend.components = tosend.components:raw()

								local s, e

								if data and buildPanelID then
									local existingPanel = ch:getMessage(buildPanelID)
									if existingPanel then
										s, e = existingPanel:update(tosend)

										if s == true then
											s = existingPanel
										end
									elseif data and data.channel and panel.channel ~= data.channel then
										local oldch = interaction.guild:getChannel(data.channel)

										if oldch then
											local oldPanel = oldch:getMessage(buildPanelID)

											if oldPanel then
												oldPanel:delete()
											end
										end

										s, e = ch:send(tosend)
									else
										s, e = ch:send(tosend)
									end
								else
									s, e = ch:send(tosend)
								end

								if s then
									local c = sqldb:get(interaction.guild.id)
									if not c then
										c = config
									end

									c.panels = c.panels or {}
									c.panels[s.id] = panel
									config = c
									sqldb:set(interaction.guild.id, {
										panels = config.panels
									}, "TICKET_PANEL_CREATE", interaction.member)

									ia:editReply({
										embed = {
											description = emojis.success .. " This panel has been successfully sent to " .. ch.mentionString .. ".",
											color = colors.success
										},
										components = {}
									}, panelBuilder.id)
									updatePage(allPages.tickets.number)
									return true
								else
									bia:fail("I encountered an HTTP error while attempting to send this panel.\n-# " .. emojis.right .. " " .. e, nil, true)
								end
							else
								bia:fail("I could not find the channel to send this panel to.", nil, true)
								return
							end
						elseif id == "cancel" then
							panel = nil
							updateBuilder(bia)
							return true
						end
					end)
				end

				if id == "actions" then
					if first == "create" then
						buildPanel()
					elseif first == "edit" then
						if not config.panels then
							ia:fail("You have not created any ticket panels.", nil, true)
						end

						ask(ia, "Edit Panel", "Enter the message ID of the panel you wish to edit...", nil, nil, "short", false, nil, function(_, mia, response)
							if mia then
								if response and response ~= "" then
									if config.panels[response] then
										buildPanel(config.panels[response], mia, response)
										return
									end

									return mia:fail("No panel was found with that ID.", nil, true)
								else
									return mia:fail("You must provide a valid panel message ID.", nil, true)
								end
							end
						end)
					elseif first == "delete" then
						ask(ia, "Delete Panel", "Enter the message ID of the panel you wish to delete...", nil, nil, "short", false, nil, function(_, mia, response)
							if mia then
								if response and response ~= "" then
									if config.panels[response] then
										local panel = config.panels[response]
										if panel.channel then
											coroutine.wrap(function()
												local channel = interaction.guild:getChannel(panel.channel)
												local message = channel and channel:getMessage(response)
												if message then
													message:delete()
												end
											end)()
										end

										config.panels[response] = nil
										modifyKey("panels", config.panels)
										updatePage(allPages.tickets.number)
										mia:updateDeferred(true)
										return
									end

									return mia:fail("No panel was found with that ID.", nil, true)
								else
									return mia:fail("You must provide a valid panel message ID.", nil, true)
								end
							end
						end)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Tickets",
				emoji = resolveEmoji(emojis.ticket)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.responders.number),
			color = colors.info,
			components = getcomps(allPages.responders.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selections = ia.data.values
				local first = selections and selections[1]

				if id == "actions" then
					if first == "create" or first == "edit" then
						local autoresponders = config.autoresponders or {}

						if first == "create" and checkLimit(ia, "autoresponders", isPlusGuild, autoresponders, "autoresponders") then
							updatePage(allPages.responders.number)
							return
						elseif first == "edit" and checkLimit(ia, "autoresponders", isPlusGuild, autoresponders, "autoresponders", true) then
							updatePage(allPages.responders.number)
							return
						end

						local autoresponder = {
							name = nil,
							requiredrole = nil,
							trigger = nil,
							response = nil,
							casesensitive = false,
							matchexact = true,
							cooldown = 0,
							deletetrigger = false,
							disabled = nil
						}

						local autoresponderIndex

						local function startBuilder()
							local r = ia:reply({
								embed = {
									description = emojis.loading,
									color = colors.blank
								}
							}, true)

							local function updateBuilder(int)
								local payload = {
									embed = {
										title = emojis.chat .. " Autoresponder Builder",
										description = 
										((autoresponder.disabled and "-# " .. emojis.power .. " This autoresponder is currently **disabled**.\n") or "")
										.. emojis.right .. " **Name:** " .. (autoresponder.name or "N/A")
										.. "\n" .. emojis.right .. " **Trigger:** " .. (autoresponder.trigger or "N/A")
										.. "\n" .. emojis.right .. " **Response:** " .. (autoresponder.response or "N/A")
										.. "\n" .. emojis.right .. " **Required Role:** " .. ((autoresponder.requiredrole and ("<@&" .. autoresponder.requiredrole .. ">")) or "N/A")
										.. "\n" .. emojis.right .. " **Case-Sensitive:** " .. ((autoresponder.casesensitive and emojis.success) or emojis.fail)
										.. "\n" .. emojis.right .. " **Check Exact Match:** " .. ((autoresponder.matchexact and emojis.success) or emojis.fail)
										.. "\n" .. emojis.right .. " **Delete Trigger:** " .. ((autoresponder.deletetrigger and emojis.success) or emojis.fail)
										.. "\n" .. emojis.right .. " **Cooldown:** " .. ((autoresponder.cooldown and (autoresponder.cooldown > 0) and readable(autoresponder.cooldown)) or emojis.fail),
										color = colors.info
									},
									components = discordia.Components():selectMenu({
										id = "edit",
										placeholder = "Edit this autoresponder...",
										options = {
											{
												label = "Edit Name",
												value = "name",
												emoji = resolvedEmojis.edit
											},
											{
												label = "Edit Trigger",
												value = "trigger",
												emoji = resolvedEmojis.text
											},
											{
												label = "Edit Response",
												value = "response",
												emoji = resolvedEmojis.chat
											},
											{
												label = "Edit Required Role",
												value = "requiredrole",
												emoji = resolvedEmojis.lock
											},
											{
												label = "Toggle Case-Sensitivity",
												value = "casesensitive",
												emoji = resolvedEmojis.casesensitive
											},
											{
												label = "Toggle Check Exact Match",
												value = "matchexact",
												emoji = resolvedEmojis.search
											},
											{
												label = "Toggle Delete Trigger",
												value = "deletetrigger",
												emoji = resolvedEmojis.delete
											},
											{
												label = "Edit Cooldown",
												value = "cooldown",
												emoji = resolvedEmojis.clock
											},
											{
												label = (autoresponder.disabled and "Enable") or "Disable",
												value = "toggle",
												description = (autoresponder.disabled and "This autoresponder is currently disabled.") or "This autoresponder is currently enabled.",
												emoji = (autoresponder.disabled and resolvedEmojis.off) or resolvedEmojis.on
											}
										}
									}):button({
										id = "create",
										label = "Save",
										style = "success",
										emoji = resolvedEmojis.yeswhite
									}):button({
										id = "cancel",
										label = "Cancel",
										style = "danger",
										emoji = resolvedEmojis.nowhite
									}):raw()
								}

								if int then
									return int:update(payload)
								else
									return ia:editReply(payload, r.id)
								end
							end

							updateBuilder()

							onComp(r, nil, nil, ia.user.id, false, function(bia)
								if bia.data.custom_id == "edit" then
									local property = bia.data.values and bia.data.values[1]

									if property == "name" then
										ask(bia, "Edit Name", "Enter a name for this autoresponder...", nil, nil, "short", true, autoresponder.name, function(_, mia, response)
											if mia then
												if response and response ~= "" then
													autoresponder.name = response
													mia:updateDeferred(true)
													updateBuilder()
												else
													mia:fail("You did not provide a name.", nil, true)
												end
											end
										end)
									elseif property == "trigger" then
										ask(bia, "Edit Trigger", "What word/phrase should trigger this autoresponder?", nil, nil, "short", true, autoresponder.trigger, function(_, mia, response)
											if mia then
												if response and response ~= "" then
													autoresponder.trigger = response
													mia:updateDeferred(true)
													updateBuilder()
												else
													mia:fail("You did not provide a trigger.", nil, true)
												end
											end
										end)
									elseif property == "response" then
										ask(bia, "Edit Response", "What should be the response?", nil, nil, "paragraph", true, autoresponder.response, function(_, mia, response)
											if mia then
												if response and response ~= "" then
													autoresponder.response = response
													mia:updateDeferred(true)
													updateBuilder()
												else
													mia:fail("You did not provide a response.", nil, true)
												end
											end
										end)
									elseif property == "requiredrole" then
										roleSelect(bia, "Select a required role...", function(role)
											autoresponder.requiredrole = role
											updateBuilder()
										end, true, 0, 1, (autoresponder.requiredrole and {
											autoresponder.requiredrole
										}) or nil)
									elseif property == "cooldown" then
										ask(bia, "Edit Cooldown", "Enter a valid interval... (i.e. 5m, 15s, 6h)", nil, nil, "short", true, autoresponder.cooldown, function(_, mia, response)
											if mia then
												if response and response ~= "" then
													local converted = convert(response)

													if converted then
														autoresponder.cooldown = converted
														mia:updateDeferred(true)
														updateBuilder()
													else
														return mia:fail("You did not provide a valid interval.", nil, true)
													end
												else
													autoresponder.cooldown = 0
													mia:updateDeferred(true)
													updateBuilder()
												end
											end
										end)
									elseif property == "casesensitive" then
										autoresponder.casesensitive = not autoresponder.casesensitive
										updateBuilder(bia)
									elseif property == "matchexact" then
										autoresponder.matchexact = not autoresponder.matchexact
										updateBuilder(bia)
									elseif property == "deletetrigger" then
										autoresponder.deletetrigger = not autoresponder.deletetrigger
										updateBuilder(bia)
									elseif property == "toggle" then
										autoresponder.disabled = not autoresponder.disabled
										updateBuilder(bia)
									else
										bia:updateDeferred(true)
									end
								elseif bia.data.custom_id == "create" then
									if (not autoresponder.name) or (autoresponder.name == "") then
										bia:fail("You have not set a name for this autoresponder.", nil, true)
										return
									elseif (not autoresponder.trigger) or (autoresponder.trigger == "") then
										bia:fail("You have not set a trigger for this autoresponder.", nil, true)
										return
									elseif (not autoresponder.response) or (autoresponder.response == "") then
										bia:fail("You have not set a response for this autoresponder.", nil, true)
										return
									end

									local autoresponders = config.autoresponders or {}

									if first == "create" and not checkLimit(bia, "autoresponders", isPlusGuild, autoresponders, "autoresponders") then
										insertInto("autoresponders", autoresponder)
									elseif first == "edit" then
										table.remove(config.autoresponders, autoresponderIndex)
										table.insert(config.autoresponders, autoresponder)
										modifyKey("autoresponders", config.autoresponders)
									end

									bia:update({
										embed = {
											description = emojis.success .. " This autoresponder has been successfully saved.",
											color = colors.success
										},
										components = {}
									})

									updatePage(allPages.responders.number)
									return true
								elseif bia.data.custom_id == "cancel" then
									ia:deleteReply(r.id)
									updatePage(allPages.responders.number)
									return true
								end
							end)
						end

						if first == "edit" then
							if type(config.autoresponders) ~= "table" or table.count(config.autoresponders) < 1 then
								updatePage(allPages.responders.number)
								return ia:fail("You have not created any autoresponders.", nil, true)
							end

							local options = {}

							for i, ar in ipairs(config.autoresponders) do
								table.insert(options, {
									label = string.truncate(ar.name, 100),
									value = i,
									emoji = resolvedEmojis.edit
								})
							end

							optionsSelect(ia, "Select an autoresponder...", function(opt)
								autoresponder = config.autoresponders[tonumber(opt)]
								autoresponderIndex = tonumber(opt)
								startBuilder()
							end, true, options, 1, nil, true)
						else
							startBuilder()
						end
					elseif first == "delete" then
						if (not config.autoresponders) or table.count(config.autoresponders) <= 0 then
							return ia:fail("There are not any autoresponders to delete.", nil, true)
						end

						local arsOpts = {}

						for arid, ar in pairs(config.autoresponders) do
							table.insert(arsOpts, {
								label = ar.name,
								value = tostring(arid),
								description = string.truncate(ar.response, 20),
								emoji = resolvedEmojis.delete
							})
						end

						optionsSelect(ia, "Select an autoresponder to delete...", function(arid)
							table.remove(config.autoresponders, arid)
							modifyKey("autoresponders", config.autoresponders)
							updatePage(allPages.responders.number)
						end, true, arsOpts, nil, nil, true)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Autoresponders",
				emoji = resolveEmoji(emojis.chat)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.giveaways.number),
			color = colors.info,
			components = getcomps(allPages.giveaways.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selections = ia.data.values
				local first = selections and selections[1]

				if id == "actions" then
					if first == "giveawayembeds" then
						multiEmbedEditor(ia, function(embeds)
							modifyKey("giveawayembeds", embeds)
							ia:updateDeferred(true)
							updatePage(allPages.giveaways.number)
						end, emojis.right .. " **`{host.mention}`:** The mention of the giveaway host.\n" .. emojis.right .. " **`{host.name}`:** The name of the giveaway host.\n" .. emojis.right .. " **`{host.username}`:** The username of the giveaway host.\n" .. emojis.right .. " **`{host.id}`:** The ID of the giveaway host.\n" .. emojis.right .. " **`{giveaway.id}`:** The ID of the giveaway.\n" .. emojis.right .. " **`{giveaway.entries}`:** The amount of entries currently in the giveaway.\n" .. emojis.right .. " **`{giveaway.winners}`:** The amount of winners for the giveaway.\n" .. emojis.right .. " **`{giveaway.prize}`:** The prize for the giveaway.\n" .. emojis.right .. " **`{giveaway.duration}`:** The length of the giveaway.\n" .. emojis.right .. " **`{giveaway.ends}`:** The end timestamp of the giveaway.\n" .. emojis.right .. " **`{requiredserver.name}`:** The name of the required server.\n" .. emojis.right .. " **`{requiredserver.id}`:** The ID of the required server.\n" .. emojis.right .. " **`{requiredrole.name}`:** The name of the required role.\n" .. emojis.right .. " **`{requiredrole.mention}`:** The mention of the required role.\n" .. emojis.right .. " **`{requiredrole.id}`:** The ID of the required role.", config.giveawayembeds)
					elseif first == "giveawayblacklist" then
						roleSelect(ia, "Select a Giveaway Blacklist Role...", function(role)
							modifyKey("giveawayblacklist", role)
							updatePage(allPages.giveaways.number)
						end, true, 1, 1, config.giveawayblacklist)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Giveaways",
				emoji = resolveEmoji(emojis.gift)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.boards.number),
			color = colors.info,
			components = getcomps(allPages.boards.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selections = ia.data.values
				local first = selections and selections[1]

				if id == "actions" then
					if first == "create" or first == "edit" then
						if first == "create" and checkLimit(ia, "reaction boards", isPlusGuild, config.reactionboards, "reactionboards") then
							updatePage(allPages.boards.number)
							return
						elseif first == "edit" and checkLimit(ia, "reaction boards", isPlusGuild, config.reactionboards, "reactionboards", true) then
							updatePage(allPages.boards.number)
							return
						end

						local board = {
							reaction = nil,
							channel = nil,
							reactionsneeded = nil,
							disabled = nil,
							whitelistedChannels = {}
						}

						local function startBuilder()
							local builder

							local function updateBuilder(int)
								local payload = {
									embed = {
										title = emojis.board .. " Reaction Board Builder",
										description =
										((board.disabled and "-# " .. emojis.power .. " This reactionboard is currently **disabled**.\n") or "")
										.. emojis.right .. " **Reaction:** " .. ((board.reaction and ("`" .. board.reaction .. "`")) or "N/A")
										.. "\n" .. emojis.right .. " **Board Channel:** " .. ((board.channel and ("<#" .. board.channel .. ">")) or "N/A")
										.. "\n" .. emojis.right .. " **Reactions Needed:** " .. (board.reactionsneeded or "N/A") 
										.. "\n" .. emojis.right .. " **Whitelisted Channels:** " .. ((board.whitelistedChannels and table.count(board.whitelistedChannels) > 0 and ("\n" .. emojis.space .. emojis.right .. " " .. table.concatFn(board.whitelistedChannels, "\n" .. emojis.space .. emojis.right .. " ", function(c)
											return "<#" .. c .. ">"
										end))) or "All"),
										color = colors.blank
									},
									components = discordia.Components():selectMenu({
										id = "edit",
										placeholder = "Edit reaction board...",
										actionRow = 1,
										min_values = 0,
										options = {
											{
												label = "Edit Reaction",
												value = "reaction",
												emoji = resolvedEmojis.emoji
											},
											{
												label = "Edit Board Channel",
												value = "channel",
												emoji = resolvedEmojis.board
											},
											{
												label = "Edit Reactions Needed",
												value = "reactionsneeded",
												emoji = resolvedEmojis.counting
											},
											{
												label = "Edit Whitelisted Channels",
												value = "whitelistedchannels",
												emoji = resolvedEmojis.channel
											},
											{
												label = (board.disabled and "Enable") or "Disable",
												value = "toggle",
												description = (board.disabled and "This reactionboard is currently disabled.") or "This reactionboard is currently enabled.",
												emoji = (board.disabled and resolvedEmojis.off) or resolvedEmojis.on
											}
										}
									}):button({
										id = "create",
										label = "Save",
										emoji = resolvedEmojis.yeswhite,
										style = "success",
										actionRow = 2
									}):button({
										id = "cancel",
										label = "Cancel",
										emoji = resolvedEmojis.nowhite,
										style = "danger",
										actionRow = 2
									}):raw()
								}

								if type(builder) == "table" then
									if int then
										int:update(payload)
									else
										return ia:editReply(payload, builder.id)
									end
								else
									builder = ia:reply(payload, true)
								end
							end

							updateBuilder()

							onComp(builder, nil, nil, ia.user.id, false, function(bia)
								local id = bia.data.custom_id
								local selection = bia.data.values and bia.data.values[1]

								if id == "edit" then
									if selection == "reaction" then
										local reactor = bia:reply({
											embed = {
												description = "React to this message with the reaction you would like to use.",
												color = colors.blank
											}
										})

										if type(reactor) == "table" then
											local _, r = Client:waitFor("reactionAdd", nil, function(r, uid)
												return (r.message.id == reactor.id) and (uid == bia.user.id)
											end)

											board.reaction = r.emojiHash

											reactor:delete()
											updateBuilder()
										end
									elseif selection == "channel" then
										channelSelect(bia, "Select a board channel...", function(c)
											board.channel = c
											updateBuilder()
										end, true)
									elseif selection == "reactionsneeded" then
										ask(bia, "Edit Reactions Needed", "Enter a valid number 1-100...", nil, nil, "short", false, board.reactionsneeded and tostring(board.reactionsneeded), function(_, mia, response)
											if mia then
												if response and response ~= "" and tonumber(response) then
													if tonumber(response) < 1 then
														updateBuilder()
														return mia:fail("The amount of reactions needed must be at least 1.", nil, true)
													elseif tonumber(response) > 100 then
														updateBuilder()
														return mia:fail("The amount of reactions needed must be less than or equal to 100.", nil, true)
													end

													board.reactionsneeded = tonumber(response)
													updateBuilder()
													return mia:updateDeferred(true)
												else
													updateBuilder()
													return mia:fail("You did not provide a valid number.", nil, true)
												end
											end
										end, 0, 3)
									elseif selection == "whitelistedchannels" then
										channelSelect(bia, "Select whitelisted channels...", function(channels)
											board.whitelistedChannels = channels
											updateBuilder()
										end, true, 0, 5, board.whitelistedChannels)
									elseif selection == "toggle" then
										board.disabled = not board.disabled
										updateBuilder(bia)
									else
										updateBuilder(bia)
									end
								elseif id == "cancel" then
									bia:updateDeferred(true)
									ia:deleteReply(builder.id)
									updatePage(allPages.boards.number)
									return true
								elseif id == "create" then
									if not board.channel then
										bia:fail("You did not set a board channel.", nil, true)
										updateBuilder()
										return
									elseif not board.reaction then
										bia:fail("You did not set a reaction.", nil, true)
										updateBuilder()
										return
									elseif not board.reactionsneeded then
										bia:fail("You did not set a number of reactions needed.", nil, true)
										updateBuilder()
										return
									end

									local reactionBoards = config.reactionboards or {}

									if first == "create" and not checkLimit(ia, "reaction boards", isPlusGuild, config.reactionboards, "reactionboards") then
										table.insert(reactionBoards, board)
										modifyKey("reactionboards", reactionBoards)
									elseif first == "edit" and not checkLimit(ia, "reaction boards", isPlusGuild, config.reactionboards, "reactionboards", true) then
										local existingBoard = board.index and reactionBoards[board.index]

										if not existingBoard then
											updateBuilder()
											return bia:fail("I was unable to find the reactionboard you are editing.", nil, true)
										end

										reactionBoards[board.index] = board
										reactionBoards = table.values(reactionBoards)
									else
										return
									end

									ia:deleteReply(builder.id)
									updatePage(allPages.boards.number)
									return
								end
							end)
						end

						if first == "edit" then
							local reactor = ia:reply({
								embed = {
									description = "React to this message with the reaction of the board you would like to edit.",
									color = colors.blank
								}
							})

							local _, r = Client:waitFor("reactionAdd", nil, function(r, uid)
								return (r.message.id == reactor.id) and (uid == ia.user.id)
							end)

							local reactionBoards = config.reactionboards or {}
							for i, b in pairs(reactionBoards) do
								if b.reaction == r.emojiHash then
									b.index = i
									board = b
								end
							end

							startBuilder()
							reactor:delete()
						else
							startBuilder()
						end
					elseif first == "delete" then
						local reactor = ia:reply({
							embed = {
								description = "React to this message with the reaction of the board you would like to delete.",
								color = colors.blank
							}
						})

						local _, r = Client:waitFor("reactionAdd", nil, function(r, uid)
							return (r.message.id == reactor.id) and (uid == ia.user.id)
						end)

						local reactionBoards = config.reactionboards or {}
						for _, b in pairs(reactionBoards) do
							if b.reaction == r.emojiHash then
								table.remove(reactionBoards, bi)
								modifyKey("reactionboards", reactionBoards)
							end
						end

						updatePage(allPages.boards.number)
						reactor:delete()
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Reaction Boards",
				emoji = resolveEmoji(emojis.board)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.messages.number),
			color = colors.info,
			components = getcomps(allPages.messages.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				if id == "actions" then
					if selection == "stickyCreate" then
						if checkLimit(ia, "sticky messages", isPlusGuild, config.stickymessages, "stickymessages") then
							return
						end

						messageEditor(ia, function(message)
							if message then
								if type(config.stickymessages) == "table" and table.count(config.stickymessages) > 0 then
									for _, stickymsg in pairs(config.stickymessages) do
										if stickymsg.channel == message.channel then
											updatePage(allPages.messages.number)
											return ia:fail("That channel already has a Sticky Message.", nil, true)
										end
									end
								end

								message.id = ia.id

								local channel = ia.guild:getChannel(message.channel)

								if channel then
									local s, e = channel:send(message)

									if s then
										message.activeMessage = s.id
									end
								end

								insertInto("stickymessages", message)
								updatePage(allPages.messages.number)
							end
						end, nil, nil, true)
					elseif selection == "stickyEdit" then
						if not config.stickymessages or table.count(config.stickymessages) <= 0 then
							return ia:fail("No sticky messages have been created in this server.", nil, true)
						end

						local sms = {}
						for _, sm in pairs(config.stickymessages) do
							table.insert(sms, {
								label = "Sticky Message " .. emojis.dot .. " " .. sm.id,
								description = string.truncate(sm.content or (sm.embeds and sm.embeds[1] and (sm.embeds[1].title or sm.embeds[1].description)) or (sm.embed and (sm.embed.title or sm.embed.description)) or "No content found", 30),
								value = sm.id,
								emoji = resolvedEmojis.edit
							})
						end

						optionsSelect(ia, "Select a sticky message to edit...", function(smID)
							if not smID then
								return ia:fail("No sticky message selected.", nil, true)
							end

							local num = nil
							for i, sticky in ipairs(config.stickymessages) do
								if sticky.id == smID then
									num = i
									break
								end
							end

							if not num then
								return ia:fail("That sticky message no longer exists.", nil, true)
							end

							messageEditor(ia, function(message)
								if not message then return end

								local channel = ia.guild:getChannel(message.channel)
								local old = config.stickymessages[num]

								if channel then
									local s = channel:send(message)
									if s then
										if old.activeMessage then
											local oldMsg = channel:getMessage(old.activeMessage)
											if oldMsg then oldMsg:delete() end
										end

										message.activeMessage = s.id
									end
								end

								message.id = config.stickymessages[num] and config.stickymessages[num].id or snowGen:next()
								
								config.stickymessages[num] = message
								modifyKey("stickymessages", config.stickymessages)

								updatePage(allPages.messages.number)
							end, nil, config.stickymessages[num], true)
						end, true, sms, 1, nil, true)
					elseif selection == "stickyDelete" then
						if (not config.stickymessages) or table.count(config.stickymessages) <= 0 then
							ia:fail("No sticky messages have been created in this server.", nil, true)
							return
						end

						local sms = {}

						for smi, sm in pairs(config.stickymessages) do
							p(smi, sm)
							table.insert(sms, {
								label = "Sticky Message " .. sm.id,
								description = string.truncate(sm.content or (sm.embeds and sm.embeds[1] and (sm.embeds[1].title or sm.embeds[1].description)) or (sm.embed and (sm.embed.title or sm.embed.description)) or "No content found", 30),
								value = sm.id,
								emoji = resolvedEmojis.delete
							})
						end

						p(sms)

						optionsSelect(ia, "Select a sticky message to remove...", function(opt)
							removeFrom("stickymessages", opt, "id")
							updatePage(allPages.messages.number)
						end, true, sms, 1, nil, true)
					elseif selection == "autoDeleteCreate" or selection == "autoDeleteEdit" then
						if selection == "autoDeleteCreate" and checkLimit(ia, "Autodelete channels", isPlusGuild, config.autodeletechannels, "autodeletechannels") then
							return
						end

						if selection == "autoDeleteEdit" and checkLimit(ia, "Autodelete channels", isPlusGuild, config.autodeletechannels, "autodeletechannels", true) then
							return
						end

						local autodelete = {
							channel = nil,
							delay = 0,
							disabled = nil,
							botdelete = false
						}

						local builder

						local function startBuilder()
							local function updateBuilder(int)
								local payload = {
									embed = {
										title = emojis.delete .. " Autodelete Channel Builder",
										description =
										((autodelete.disabled and "-# " .. emojis.power .. " This Autodelete channel is currently **disabled**.\n") or "")
										.. emojis.right .. " **Channel:** " .. ((autodelete.channel and ("<#" .. autodelete.channel .. ">")) or "N/A")
										.. "\n" .. emojis.right .. " **Delay:** " .. ((autodelete.delay and readable(autodelete.delay)) or "N/A")
										.. "\n" .. emojis.right .. " **Delete Bot Messages:** " .. ((autodelete.botdelete and emojis.success) or emojis.fail),
										color = colors.blank
									},
									components = discordia.Components():selectMenu({
										id = "edit",
										placeholder = "Edit Autodelete channel...",
										actionRow = 1,
										min_values = 0,
										options = {{
											label = "Edit Channel",
											value = "channel",
											emoji = resolvedEmojis.channel
										}, {
											label = "Edit Delay",
											value = "delay",
											emoji = resolvedEmojis.clock
										}, {
											label = (autodelete.disabled and "Enable") or "Disable",
											value = "toggle",
											description = (autodelete.disabled and "This Autodelete channel is currently disabled.") or "This Autodelete channel is currently enabled.",
											emoji = (autodelete.disabled and resolvedEmojis.off) or resolvedEmojis.on
										}, {
											label = (autodelete.botdelete and "Disable Bot Delete") or "Enable Bot Delete",
											value = "togglebotdelete",
											emoji = (autodelete.botdelete and resolvedEmojis.on) or resolvedEmojis.off
										}}
									}):button({
										id = "create",
										label = "Save",
										emoji = resolvedEmojis.yeswhite,
										style = "success",
										actionRow = 2
									}):button({
										id = "cancel",
										label = "Cancel",
										emoji = resolvedEmojis.nowhite,
										style = "danger",
										actionRow = 2
									}):raw()
								}

								if type(builder) == "table" then
									if int then
										int:update(payload)
									else
										ia:editReply(payload, builder.id)
									end
								else
									builder = ia:reply(payload, true)
								end
							end

							updateBuilder()

							onComp(builder, nil, nil, ia.user.id, false, function(bia)
								local id = bia.data.custom_id
								local selection = bia.data.values and bia.data.values[1]

								if id == "edit" then
									if selection == "channel" then
										channelSelect(bia, "Select an Autodelete channel...", function(c)
											autodelete.channel = c
											updateBuilder()
										end, true)
									elseif selection == "delay" then
										prompt(bia, "Edit Autodelete Delay", {
											{
												question = "Delay",
												placeholder = "Ex: 1m10s",
												style = "short",
												required = false
											}
										}, function(mia, responses)
											if responses and responses["Delay"] then
												local delay = responses["Delay"] and convert(responses["Delay"])

												if (type(delay) ~= "number") or (delay < 1 or delay > 120) then
													mia:fail("You must provide a delay bewteen 1 and 120 seconds.", nil, true)
												end

												autodelete.delay = delay
												updateBuilder()
											else
												autodelete.delay = 0
												updateBuilder()
											end
										end, true)
									elseif selection == "toggle" then
										autodelete.disabled = not autodelete.disabled
										updateBuilder(bia)
									elseif selection == "togglebotdelete" then
										autodelete.botdelete = not autodelete.botdelete
										updateBuilder(bia)
									else
										updateBuilder(bia)
									end
								elseif id == "cancel" then
									bia:updateDeferred(true)
									ia:deleteReply(builder.id)
									updatePage(allPages.messages.number)
									return true
								elseif id == "create" then
									if not autodelete.channel then
										bia:fail("You did not set an Autodelete channel.", nil, true)
										updateBuilder()
										return
									end

									config.autodeletechannels = config.autodeletechannels or {}
									config.autodeletechannels[autodelete.channel] = autodelete

									ia:deleteReply(builder.id)
									modifyKey("autodeletechannels", config.autodeletechannels)
									updatePage(allPages.messages.number)
									return
								end
							end)
						end

						if selection == "autoDeleteEdit" then
							if type(config.autodeletechannels) ~= "table" or table.count(config.autodeletechannels) <= 0 then
								return ia:fail("No Autodelete channels have been created in this server.", nil, true)
							end

							local sms = {}
							for chID, ad in pairs(config.autodeletechannels) do
								local channel = ia.guild:getChannel(chID)
								if channel then
									table.insert(sms, {
										label = string.truncate(channel.name, 100),
										description = "Delay: " .. readable(ad.delay),
										value = chID,
										emoji = resolvedEmojis.edit
									})
								end
							end

							if not next(sms) then
								return ia:fail("No valid Autodelete channels have been found in this server.", nil, true)
							end

							optionsSelect(ia, "Select an Autodelete channel to edit...", function(opt, cia)
								autodelete = config.autodeletechannels[opt]

								if not autodelete then
									return cia:fail("I was not able to find that Autodelete channel.", nil, true)
								end

								startBuilder()
							end, true, sms, nil, nil, true)
						elseif selection == "autoDeleteCreate" then
							startBuilder()
						end
					elseif selection == "autoDeleteDelete" then
						if (not config.autodeletechannels) or table.count(config.autodeletechannels) <= 0 then
							ia:fail("No Autodelete channels have been created in this server.", nil, true)
							return
						end

						local sms = {}

						for smi, sm in pairs(config.autodeletechannels) do
							local channel = interaction.guild:getChannel(smi)

							if channel then
								table.insert(sms, {
									label = string.truncate(channel.name, 100),
									description = "Delay: " .. readable(sm.delay),
									value = smi,
									emoji = resolvedEmojis.delete
								})
							else
								config.autodeletechannels[smi] = nil
							end
						end

						if not next(sms) then
							ia:fail("No valid Autodelete channels have been found in this server.", nil, true)
							return
						end

						optionsSelect(ia, "Select an Autodelete channel to remove...", function(opt)
							config.autodeletechannels[opt] = nil

							modifyKey("autodeletechannels", config.autodeletechannels)
							updatePage(allPages.messages.number)
						end, true, sms, nil, nil, true)
					elseif selection == "valuableMessageCreate" then
						prompt(ia, "Mark as Valuable", {
							{
								question = "Message Link",
								placeholder = "https://discord.com/channels/.../.../...",
								style = "short",
								required = false
							}
						}, function(mia, responses)
							if mia then
								local link = responses and responses["Message Link"]

								if link then
									local message = parseMessageLink(link)

									if message then
										insertInto("valuablemessages", message.channel.id .. "/" .. message.id)
										mia:updateDeferred(true)
										return updatePage(allPages.messages.number)
									else
										mia:fail("That message could not be found.", nil, true)
										return updatePage(allPages.messages.number)
									end
								else
									mia:updateDeferred(true)
									return updatePage(allPages.messages.number)
								end
							end
						end)
					elseif selection == "valuableMessageEdit" then
						local valuable = config.valuablemessages or {}

						if not valuable or #valuable == 0 then
							return ia:fail("You have not marked any messages as valuable yet.", nil, true)
						end

						local cleaned = {}
						for _, v in ipairs(valuable) do
							if v then table.insert(cleaned, v) end
						end
						valuable = cleaned
						modifyKey("valuablemessages", valuable)

						local opts = {}
						for idx, mid in ipairs(valuable) do
							local split = string.split(mid, "/")
							local channel = ia.guild:getChannel(split[1])
							local valMsg = channel and channel:getMessage(split[2])
							if channel and valMsg then
								table.insert(opts, {
									label = string.truncate(channel.name, 80),
									description = string.truncate(valMsg.content or (valMsg.embeds and valMsg.embeds[1] and (valMsg.embeds[1].title or valMsg.embeds[1].description)) or "No content found", 50),
									value = tostring(idx),
									emoji = resolvedEmojis.edit
								})
							end
						end

						if #opts == 0 then
							return ia:fail("No valid valuable messages found.", nil, true)
						end

						optionsSelect(ia, "Select a message to edit...", function(selectedValue, bia)
							local index = tonumber(selectedValue)
							if not index or not valuable[index] then
								return bia:fail("Selected message is invalid.", nil, true)
							end

							prompt(bia, "Edit Valuable Message", {
								{
									question = "Message Link",
									placeholder = "https://discord.com/channels/.../.../...",
									style = "short",
									required = true
								}
							}, function(mia, responses)
								if not mia then return end

								local link = responses and responses["Message Link"]
								if not link then
									return mia:fail("You must provide a message link.", nil, true)
								end

								local message = parseMessageLink(link)
								if not message then
									mia:fail("That message could not be found.", nil, true)
									return updatePage(allPages.messages.number)
								end

								valuable[index] = message.channel.id .. "/" .. message.id
								modifyKey("valuablemessages", valuable)

								mia:updateDeferred(true)
								updatePage(allPages.messages.number)
							end)
						end, true, opts, 1, nil, true)
					elseif selection == "valuableMessageDelete" then
						local valuable = config.valuablemessages or {}
						if not valuable or #valuable == 0 then
							return ia:fail("You have not marked any messages as valuable yet.", nil, true)
						end

						local opts = {}
						for index, mid in ipairs(valuable) do
							local split = string.split(mid, "/")
							local channel = ia.guild:getChannel(split[1])
							if channel then
								local valMsg = channel:getMessage(split[2])
								if valMsg then
									table.insert(opts, {
										label = string.truncate(channel.name, 80),
										description = string.truncate(valMsg.content or (valMsg.embeds and valMsg.embeds[1] and (valMsg.embeds[1].title or valMsg.embeds[1].description)) or "No content found", 50),
										value = tostring(index),
										emoji = resolvedEmojis.delete
									})
								else
									valuable[index] = nil
								end
							else
								valuable[index] = nil
							end
						end

						local cleaned = {}
						for _, v in ipairs(valuable) do
							table.insert(cleaned, v)
						end
						valuable = cleaned
						modifyKey("valuablemessages", valuable)

						if #opts == 0 then
							return ia:fail("No valid valuable messages found.", nil, true)
						end

						optionsSelect(ia, "Select a message to remove...", function(index)
							index = tonumber(index)
							if not index or not valuable[index] then
								return ia:fail("Selected message is invalid.", nil, true)
							end

							table.remove(valuable, index)
							modifyKey("valuablemessages", valuable)
							updatePage(allPages.messages.number)
						end, true, opts, 1, nil, true)
					elseif selection == "createautoreactchannel" or selection == "editautoreactchannel" then
						local autoreactchannel = {
							reaction = nil,
							channel = nil,
							botreact = false,
						}

						local function startBuilder(mode)
							local builder

							local function updateBuilder(int)
								local payload = {
									embed = {
										title = emojis.channel .. " Autoreact Channel Builder",
										description = emojis.right .. " **Reaction:** " .. ((autoreactchannel.reaction and ("`" .. autoreactchannel.reaction .. "`")) or emojis.fail)
										.. "\n" .. emojis.right .. " **Channel:** " .. ((autoreactchannel.channel and ("<#" .. autoreactchannel.channel .. ">")) or emojis.fail)
										.. "\n" .. emojis.right .. " **React to Bots:** " .. ((autoreactchannel.botreact and emojis.success) or emojis.fail),
										color = colors.blank
									},
									components = discordia.Components():selectMenu({
										id = "edit",
										placeholder = "Edit autoreact channel...",
										actionRow = 1,
										min_values = 0,
										options = {
											{
												label = "Edit Reaction",
												value = "reaction",
												emoji = resolvedEmojis.emoji
											},
											{
												label = "Edit Channel",
												value = "channel",
												emoji = resolvedEmojis.channel
											},
											{
												label = "Toggle React to Bots",
												value = "botreact",
												emoji = resolvedEmojis.transfer
											}
										}
									}):button({
										id = "create",
										label = "Save",
										emoji = resolvedEmojis.yeswhite,
										style = "success",
										actionRow = 2
									}):button({
										id = "cancel",
										label = "Cancel",
										emoji = resolvedEmojis.nowhite,
										style = "danger",
										actionRow = 2
									}):raw()
								}

								if type(builder) == "table" then
									if int then
										int:update(payload)
									else
										return ia:editReply(payload, builder.id)
									end
								else
									builder = ia:reply(payload, true)
								end
							end

							updateBuilder()

							onComp(builder, nil, nil, ia.user.id, false, function(bia)
								local id = bia.data.custom_id
								local selected = bia.data.values and bia.data.values[1]

								if id == "edit" then
									if selected == "reaction" then
										local reactor = bia:reply({
											embed = {
												description = "React to this message with the reaction you would like to use.",
												color = colors.blank
											}
										})

										if type(reactor) == "table" then
											local _, r = Client:waitFor("reactionAdd", nil, function(r, uid)
												return (r.message.id == reactor.id) and (uid == bia.user.id)
											end)

											autoreactchannel.reaction = r.emojiHash

											reactor:delete()
											updateBuilder()
										end
									elseif selected == "channel" then
										channelSelect(bia, "Select a board channel...", function(c)
											autoreactchannel.channel = c
											updateBuilder()
										end, true)
									elseif selected == "botreact" then
										bia:updateDeferred(true)
										autoreactchannel.botreact = not autoreactchannel.botreact
										updateBuilder()
									else
										updateBuilder(bia)
									end
								elseif id == "cancel" then
									bia:updateDeferred(true)
									ia:deleteReply(builder.id)
									updatePage(allPages.messages.number)
									return true
								elseif id == "create" then
									if not autoreactchannel.channel then
										bia:fail("You did not set a channel.", nil, true)
										updateBuilder()
										return
									elseif not autoreactchannel.reaction then
										bia:fail("You did not set a reaction.", nil, true)
										updateBuilder()
										return
									end

									local autoreactchannels = config.autoreactchannels or {}

									if mode == "create" then
										table.insert(autoreactchannels, autoreactchannel)
									elseif mode == "edit" then
										if not autoreactchannel.index or not autoreactchannels[autoreactchannel.index] then
											updateBuilder()
											return bia:fail("I was unable to find the autoreact channel you are editing.", nil, true)
										end
										autoreactchannels[autoreactchannel.index] = autoreactchannel
									end

									modifyKey("autoreactchannels", autoreactchannels)
									ia:deleteReply(builder.id)
									updatePage(allPages.messages.number)
									return
								end
							end)
						end

						if selection == "editautoreactchannel" then
							local opts = {}
							for i, arChan in ipairs(config.autoreactchannels) do
								local chan = interaction.guild:getChannel(arChan.channel)
								table.insert(opts, {
									label = (chan and chan.name and string.truncate(chan.name, 30)),
									value = tostring(i),
									description = arChan.reaction,
									emoji = resolvedEmojis.edit
								})
							end

							optionsSelect(ia, "Select an option...", function(opt, oia)
								for i, arChan in ipairs(config.autoreactchannels) do
									if tostring(i) == tostring(opt) then
										autoreactchannel = {
											channel = arChan.channel,
											reaction = arChan.reaction,
											botreact = arChan.botreact,
											index = i
										}
										startBuilder("edit")
										break
									end
								end
							end, true, opts, 1, nil, true)
						else
							startBuilder("create")
						end
					elseif selection == "removeautoreactchannel" then
						local opts = {}
						for i, arChan in ipairs(config.autoreactchannels) do
							local chan = interaction.guild:getChannel(arChan.channel)
							table.insert(opts, {
								label = (chan and chan.name and string.truncate(chan.name, 30)),
								value = tostring(i),
								description = arChan.reaction,
								emoji = resolvedEmojis.edit
							})
						end

						local autoreactchannels = config.autoreactchannels or {}
						optionsSelect(ia, "Select an option...", function(opt, oia)
							for i, arChan in ipairs(config.autoreactchannels) do
								if tostring(i) == tostring(opt) then
									table.remove(autoreactchannels, i)
									modifyKey("autoreactchannels", autoreactchannels)
								end
							end
						end, true, opts, 1, nil, true)

						updatePage(allPages.messages.number)
					else
						ia:updateDeferred(true)
						return updatePage(allPages.messages.number)
					end
				end
			end,
			identifier = {
				text = "Message Management",
				emoji = resolveEmoji(emojis.send)
			}
		})

		table.insert(pages, {
			description = getEmbedDescription(allPages.departments.number),
			color = colors.info,
			components = getcomps(allPages.departments.number),
			otherCompCallback = function(ia)
				local id = ia.data.custom_id
				local selections = ia.data.values
				local first = selections and selections[1]

				if id == "actions" then
					if first == "linknew" then
						if db:isDepartment(ia.guild) then
							ia:fail("This server is a department, and therefore cannot link departments to itself.")
							return false
						end

						local linkCode = junkStr(25)

						prompt(ia, "Link Department", {
							{
								question = "Server ID",
								placeholder = "Enter the ID of the server you would like to link as a department.",
								style = "short",
								required = true
							}
						}, function(mia, responses)
							if mia and responses and responses["Server ID"] and tonumber(responses["Server ID"]) then
								local department = Client:getGuild(responses["Server ID"])

								if department then
									if department.id == interaction.guild.id then
										return mia:fail("You cannot link a server to itself.", nil, true)
									end

									local isDep, host = db:isDepartment(department)

									if isDep and host then
										mia:fail("**" .. department.name .. "** (`" .. department.id .. "`) is already a department of **" .. host.name .. "** (`" .. host.id .. "`).", nil, true)
										return
									end

									local owner = Client:getUser(department.ownerId)

									if owner then
										if owner:getPrivateChannel() then
											local request, err = owner:send({
												content = "# " .. emojis.guild .. " Department Request\n>>> **" .. ia.guild.name .. "** (`" .. ia.guild.id .. "`) is requesting to link your server, **" .. department.name .. "** (`" .. department.id .. "`), to their server as a " .. emojis.guild .. " **Department**. This will allow them to execute potentially dangerous actions on your server from their own. Please review the request and accept/deny it using the buttons below.\n-# " .. emojis.warning .. " This request will automatically time out <t:" .. (os.time() + 600) .. ":R>.",
												components = discordia.Components():button({
													id = "accept",
													style = "success",
													emoji = resolvedEmojis.yeswhite
												}):button({
													id = "deny",
													style = "danger",
													emoji = resolvedEmojis.nowhite
												}):raw()
											})

											if not request or class(request) ~= "Message" then
												updatePage(allPages.departments.number)

												local code = err:match("%d+")
												local errMsg = tonumber(code) and errCodes[tonumber(code)]

												return mia:fail("An error occurred while attempting to DM " .. getUserString(owner) .. ": " .. errMsg or tostring(err), nil, true)
											end

											local responded = false

											local resultMessage = mia:reply({
												embed = {
													description = emojis.clock .. " A department request has been sent to the owner of **" .. department.name .. "**, **@" .. owner.username .. "** (`" .. owner.id .. "`).",
													color = colors.info
												}
											}, true)

											onComp(request, nil, nil, owner.id, true, function(ia)
												responded = true

												if ia.data.custom_id == "accept" then
													local succ, config = sqldb:registerGuild(department.id)
													if not succ then
														request:update({
															content = emojis.fail .. " Your server's configuration could not be initialized. Please try again later.",
															components = {}
														})
														return
													end

													sqldb:set(department.id, {
														departmenthost = interaction.guild.id
													}, "DEPARTMENT_LINK", interaction.member)

													setValue("departments", department.id, {})

													request:update({
														content = emojis.success .. " Your server, **" .. department.name .. "** (`" .. department.id .. "`) has been successfully linked as a department of **" .. interaction.guild.name .. "** (`" .. interaction.guild.id .. "`).",
														components = {}
													})

													if type(resultMessage) == "table" then
														mia:editReply({
															embed = {
																description = emojis.success .. " **" .. department.name .. "** (`" .. department.id .. "`) has been successfully linked as a department of this server.",
																color = colors.success
															}
														}, resultMessage.id)
													else
														resultMessage = mia:reply({
															embed = {
																description = emojis.success .. " **" .. department.name .. "** (`" .. department.id .. "`) has been successfully linked as a department of this server.",
																color = colors.success
															}
														}, true)
													end

													updatePage(allPages.departments.number)
													return true
												elseif ia.data.custom_id == "deny" then
													request:update({
														content = emojis.fail .. " You have denied the department request from **" .. interaction.guild.name .. "** (`" .. interaction.guild.id .. "`).",
														components = {}
													})

													if type(resultMessage) == "table" then
														mia:editReply({
															embed = {
																description = emojis.fail .. " **" .. department.name .. "** (`" .. department.id .. "`) has denied the department request.",
																color = colors.fail
															}
														}, resultMessage.id)
													else
														resultMessage = mia:reply({
															embed = {
																description = emojis.fail .. " **" .. department.name .. "** (`" .. department.id .. "`) has denied the department request.",
																color = colors.fail
															}
														}, true)
													end

													updatePage(allPages.departments.number)
													return true
												end
											end)

											coroutine.wrap(function()
												timer.sleep(600000)
												if not responded then
													request:delete()
													if resultMessage then
														mia:editReply({
															embed = {
																description = emojis.fail .. " **" .. department.name .. "** (`" .. department.id .. "`) did not respond to the request within 10 minutes, and the request has now timed out.",
																color = colors.fail
															}
														}, resultMessage.id)
													else
														mia:reply({
															embed = {
																description = emojis.fail .. " **" .. department.name .. "** (`" .. department.id .. "`) did not respond to the request within 10 minutes, and the request has now timed out.",
																color = colors.fail
															}
														}, true)
													end
												end
											end)()
										else
											mia:fail("The owner of **" .. department.name .. "** (`" .. department.id .. "`) has their DMs disabled.", nil, true)
										end
									else
										mia:fail("I could not find the owner of that server.\n-# " .. emojis.right .. " Using `/membercount` in the department server might resolve this issue.", nil, true)
									end
								else
									mia:fail("I am not in that server, or the guild ID is invalid.", nil, true)
								end
							else
								mia:fail("You must provide a valid guild ID.", nil, true)
							end
						end)
					elseif first == "unlink" then
						local thisDep, thisHost = db:isDepartment(interaction.guild)

						if thisDep then
							modifyKey("departmenthost")

							local hostConfig = sqldb:get(thisHost.id)

							if hostConfig then
								if hostConfig.departments then
									hostConfig.departments[interaction.guild.id] = nil
									sqldb:set(thisHost.id, {
										departments = hostConfig.departments
									}, "DEPARTMENT_UNLINK", interaction.member)
								end
							end

							ia:success("This server has been unlinked as a department from **" .. thisHost.name .. "**.", nil, true)
							updatePage(allPages.departments.number)
						else
							prompt(ia, "Unlink Department", {
								{
									question = "Department ID",
									placeholder = "Enter the guild ID of the department you would like to unlink.",
									style = "short",
									required = true
								}
							}, function(mia, responses)
								if mia and responses and responses["Department ID"] and tonumber(responses["Department ID"]) then
									local departmentId = responses["Department ID"]
									local department = Client:getGuild(departmentId)

									if department then
										local isDep, host = db:isDepartment(department)

										if isDep then
											if host.id == ia.guild.id then
												sqldb:set(department.id, {
													departmenthost = "nil"
												}, "DEPARTMENT_UNLINK", interaction.member)
												setValue("departments", department.id, nil)
												mia:success("**" .. department.name .. "** has been unlinked from this server as a department.", nil, true)
												updatePage(allPages.departments.number)
												return
											else
												mia:fail("This server is not the host server of **" .. department.name .. "**.", nil, true)
											end
										else
											mia:fail("**" .. department.name .. "** is not a department of any server.", nil, true)
										end
									else
										local depConfig = sqldb:get(departmentId) or {}

										if depConfig.departmenthost then
											sqldb:set(departmentId, {
												departmenthost = "nil"
											}, "DEPARTMENT_UNLINK", interaction.member)
											setValue("departments", departmentId, nil)
											mia:success("**" .. departmentId .. "** has been unlinked from this server as a department.", nil, true)
											updatePage(allPages.departments.number)
											return
										else
											mia:fail("You must provide a valid guild ID.", nil, true)
										end
									end
								else
									mia:fail("You must provide a valid guild ID.", nil, true)
								end
							end)
						end
					elseif first == "createlinkedrole" then
						local opts = {}

						for id, _ in pairs(config.departments or {}) do
							local department = Client:getGuild(id)

							if department then
								table.insert(opts, {
									label = department.name,
									value = department.id,
									emoji = resolvedEmojis.guild
								})
							end
						end

						if not next(opts) then
							return ia:fail("This server does not host any departments.", nil, true)
						end

						local r = ia:reply({
							components = discordia.Components():selectMenu({
								placeholder = "Select a department...",
								id = "departmentselect",
								min_values = 1,
								max_values = 1,
								options = opts
							}):raw()
						}, true)

						onComp(r, nil, nil, ia.user.id, false, function(ria)
							local id = ria.data.custom_id
							local selections = ria.data.values
							local first = selections and selections[1]

							if id == "departmentselect" then
								local department = Client:getGuild(first)
								local depConfig = config.departments[department.id] or {}

								if checkLimit(ria, "linked roles for this department", isPlusGuild, depConfig.linkedroles, "departmentLinkedRoles") then
									return
								end

								if department then
									prompt(ria, "Create Linked Role", {
										{
											question = "Host Role ID",
											placeholder = "Enter the ID of the role within this server.",
											style = "short",
											required = true
										},
										{
											question = "Department Role ID",
											placeholder = "Enter the ID of the role within the department.",
											style = "short",
											required = true
										}
									}, function(mia, responses)
										if mia and responses and tonumber(responses["Host Role ID"]) and tonumber(responses["Department Role ID"]) then
											local hostRole = ia.guild:getRole(responses["Host Role ID"])
											local departmentRole = department:getRole(responses["Department Role ID"])

											if not hostRole then
												updatePage(allPages.departments.number)
												return mia:fail("You did not provide a valid host role.", nil, true)
											elseif not departmentRole then
												updatePage(allPages.departments.number)
												return mia:fail("You did not provide a valid department role.", nil, true)
											end

											depConfig.linkedroles = depConfig.linkedroles or {}
											table.insert(depConfig.linkedroles, {
												host = hostRole.id,
												department = departmentRole.id
											})
											setValue("departments", department.id, depConfig)

											updatePage(allPages.departments.number)
											mia:updateDeferred(true)

											return ia:editReply({
												embed = {
													description = emojis.success .. " The " .. hostRole.mentionString .. " role has been successfully linked with the **" .. departmentRole.name .. "** role in **" .. department.name .. "**.",
													color = colors.success
												},
												components = {}
											}, r.id)
										else
											updatePage(allPages.departments.number)
											return mia:fail("You did not provide valid role IDs.", nil, true)
										end
									end, false)
								else
									updatePage(allPages.departments.number)
									return ria:fail("The department you selected was not found.", nil, true)
								end
							end
						end)
					elseif first == "removelinkedrole" then
						local opts = {}

						for id, depConfig in pairs(config.departments or {}) do
							local department = Client:getGuild(id)

							if department then
								for _, link in pairs(depConfig.linkedroles or {}) do
									local hostRole = ia.guild:getRole(link.host)
									local departmentRole = department:getRole(link.department)

									table.insert(opts, {
										label = ((hostRole and hostRole.name) or "Host Role Removed") .. " 🔗 " .. ((departmentRole and departmentRole.name) or "Department Role Removed"),
										value = department.id .. "." .. link.host .. "-" .. link.department,
										emoji = resolvedEmojis.delete
									})
								end
							end
						end

						if not next(opts) then
							return ia:fail("This server does not host any departments, or does not have any linked roles.", nil, true)
						end

						local r = ia:reply({
							components = discordia.Components():selectMenu({
								placeholder = "Select a linked role...",
								id = "linkedroleselect",
								min_values = 1,
								max_values = 1,
								options = opts
							}):raw()
						}, true)

						onComp(r, nil, nil, ia.user.id, false, function(ria)
							local id = ria.data.custom_id
							local selections = ria.data.values
							local first = selections and selections[1]

							if id == "linkedroleselect" then
								local departmentID, hostRoleID, departmentRoleID = first:match("(%d+)%.(%d+)%-(%d+)")
								local depConfig = config.departments[departmentID] or {}

								for i, link in pairs(depConfig.linkedroles or {}) do
									if link.host == hostRoleID and link.department == departmentRoleID then
										table.remove(depConfig.linkedroles, i)
										break
									end
								end

								setValue("departments", departmentID, depConfig)

								updatePage(allPages.departments.number)

								ria:updateDeferred(true)
								ia:editReply({
									embed = {
										description = emojis.success .. " That linked role has been successfully deleted.",
										color = colors.success
									},
									components = {}
								}, r.id)
								return true
							end
						end)
					elseif first == "togglesyncnicknames" then
						local opts = {}

						for id, _ in pairs(config.departments or {}) do
							local department = Client:getGuild(id)

							if department then
								table.insert(opts, {
									label = department.name,
									value = department.id,
									emoji = resolvedEmojis.guild
								})
							end
						end

						if not next(opts) then
							return ia:fail("This server does not host any departments.", nil, true)
						end

						local r = ia:reply({
							components = discordia.Components():selectMenu({
								placeholder = "Select a department...",
								id = "departmentselect",
								min_values = 1,
								max_values = 1,
								options = opts
							}):raw()
						}, true)

						onComp(r, nil, nil, ia.user.id, false, function(ria)
							local id = ria.data.custom_id
							local selections = ria.data.values
							local first = selections and selections[1]

							if id == "departmentselect" then
								local department = Client:getGuild(first)
								local depConfig = config.departments[department.id] or {}

								if department then
									depConfig.syncnicknames = not depConfig.syncnicknames
									setValue("departments", department.id, depConfig)
									updatePage(allPages.departments.number)
									ria:updateDeferred(true)
									return ia:deleteReply(r.id)
								else
									updatePage(allPages.departments.number)
									return ria:fail("The department you selected was not found.", nil, true)
								end
							end
						end)
					else
						ia:updateDeferred(true)
					end
				end
			end,
			identifier = {
				text = "Departments",
				emoji = resolveEmoji(emojis.guild)
			}
		})

		local pgopts = {
			teleport = true,
			clamp = false,
			startPage = 1
		}

		local startPage = (slash and args and args.page) or ((not slash) and args and table.concat(args, " "))
		if startPage then
			if tonumber(startPage) then
				local toset = math.clamp(tonumber(startPage), 1, #pages)
				pgopts.startPage = toset
			else
				for i, p in pairs(pages) do
					if p.identifier and p.identifier.text and p.identifier.text:lower():find(startPage:lower()) then
						pgopts.startPage = i
						break
					end
				end
			end
		end

		pagination, updatePagination = paginate(interaction, pages, interaction.user, pgopts)
	end
}
