-- session.lua

local slashCommand = tools.slashCommand("session", "Use the session commands.")
------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("start", "Send an SSU message in the configured channel.")
slashCommand = slashCommand:addOption(subcmd)
------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("end", "Send an SSD message in the configured channel, and run :kick all in your ERLC server if setup.")
subcmd = subcmd:addOption(tools.boolean("kick", "Whether or not to kick all players from the in-game server."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)
------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("low", "Send a low players message in the configured channel.")
slashCommand = slashCommand:addOption(subcmd)
------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("full", "Send a full server message in the configured channel.")
slashCommand = slashCommand:addOption(subcmd)
------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("vote", "Send a session vote and automatically start a session once the vote requirement is fulfilled.")
subcmd = subcmd:addOption(tools.integer("votes", "The amount of votes required to start a session."):setRequired(true))
subcmd = subcmd:addOption(tools.boolean("manual", "Whether or not you would like to manually initiate the session start-up."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)
------------------------------------------------------------------------------------------------
local subcmd = tools.subCommand("staffvote", "Send a session vote specifically for staff to confirm they can attend a session.")
subcmd = subcmd:addOption(tools.integer("votes", "The amount of votes required to start a session."):setRequired(true))
subcmd = subcmd:addOption(tools.integer("public_votes", "The amount of votes required on the public session vote."):setRequired(false))
subcmd = subcmd:addOption(tools.boolean("manual", "Whether or not you would like to manually initiate the public session vote."):setRequired(false))
slashCommand = slashCommand:addOption(subcmd)

return {
	name = "session",
	description = "Use the session commands.",
	aliases = {},
	category = "Sessions",
	slashCommand = slashCommand,
	subcommands = {
		"start",
		["end"] = {
			"shutdown"
		},
		low = {
			"boost"
		},
		"full",
		"vote",
		"staffvote"
	},
	requiredPermissions = {
		"SESSION_STARTER",
		"SETUP"
	},
	hybridCallback = function(interaction, args, slash, subcmd)
		if not subcmd then return end

		if (not slash) and subcmd then
			table.remove(args, 1)
		end

		local config = sqldb:get(interaction.guild.id) or {}
		local sessionsChannel = config.sessionschannel and interaction.guild:getChannel(config.sessionschannel)

		if not sessionsChannel then
			return interaction:fail("The sessions channel has not been configured in this server.", nil, true)
		elseif (not config.apikey) and (not config.serverInfo) then
			return interaction:fail("You must either link an ERLC API key or configure your server's info in order to use the " .. emojis.game .. " **Sessions** feature.")
		end

		if subcmd == "start" then
			local s, e = db:sessionStart(interaction.member)

			if s then
				if interaction.channel.id == sessionsChannel.id and not slash then
					return interaction:delete()
				else
					return interaction:success("This server's session has been successfully started.", nil, true)
				end
			else
				return interaction:fail(e, nil, true)
			end
		elseif subcmd == "end" or subcmd == "shutdown" then
			local kickAll = slash and args and args.kick

			if kickAll and not config.apikey then
				return interaction:fail("The kick all feature requires for you to link your ERLC API Key with Ducky via the " .. emojis.game .. " **ERLC Integration** page in `/setup`.")
			end

			local s, e = db:sessionEnd(interaction.member)

			if s then
				local server = kickAll and config.apikey and ERLC:getServer(config.apikey)
				local kickedAll = server and server:execute("shutdown") or false

				if interaction.channel.id == sessionsChannel.id and not slash then
					return interaction:delete()
				else
					return interaction:success("This server's session has been successfully shutdown" .. ((kickedAll and " and all players have been kicked from the in-game server.") or "."), nil, true)
				end
			else
				return interaction:fail(e, nil, true)
			end
		elseif subcmd == "vote" then
			local votesRequired = (slash and args and args.votes and math.floor(args.votes)) or ((not slash) and args and args[1] and tonumber(args[1]) and math.floor(tonumber(args[1])))
			local autoStart = not (slash and args and args.manual)

			if (not votesRequired) then
				return interaction:fail("You must provide a valid number of votes required to start the session.", nil, true)
			end	

			local s, e = db:sessionVote(interaction.member, votesRequired, autoStart)

			if s then
				if interaction.channel.id == sessionsChannel.id and not slash then
					return interaction:delete()
				else
					return interaction:success("A session vote has been successfully initiated" .. ((autoStart and " and will automatically start a session if it reaches **" .. votesRequired .. " votes**.") or "."), nil, true)
				end
			else
				return interaction:fail(e, nil, true)
			end
		elseif subcmd == "low" or subcmd == "boost" then
			local s, e = db:sessionLow(interaction.member)

			if s then
				if interaction.channel.id == sessionsChannel.id and not slash then
					return interaction:delete()
				else
					return interaction:success("The session low notification for this server has been successfully sent.", nil, true)
				end
			else
				return interaction:fail(e, nil, true)
			end
		elseif subcmd == "full" then
			local s, e = db:sessionFull(interaction.member)

			if s then
				if interaction.channel.id == sessionsChannel.id and not slash then
					return interaction:delete()
				else
					return interaction:success("The session full notification for this server has been successfully sent.", nil, true)
				end
			else
				return interaction:fail(e, nil, true)
			end
		elseif subcmd == "staffvote" then
			local votesRequired = (slash and args and args.votes and math.floor(args.votes)) or ((not slash) and args and args[1] and tonumber(args[1]) and math.floor(tonumber(args[1])))
			local publicVotesRequired = (slash and args and args.public_votes and math.floor(args.public_votes)) or ((not slash) and args and args[2] and tonumber(args[2]) and math.floor(tonumber(args[2])))
			local autoStart = not (slash and args and args.manual)

			if (not votesRequired) then
				return interaction:fail("You must provide a valid number of votes required on the staff vote to start the **public** session vote.", nil, true)
			elseif (autoStart) and (not publicVotesRequired) then
				return interaction:fail("You must provide a valid number of votes required on the **public** session vote to start the session.", nil, true)
			end

			local s, e = db:sessionStaffVote(interaction.member, interaction.channel, votesRequired, autoStart, publicVotesRequired)

			if s then
				if interaction.channel.id == sessionsChannel.id and not slash then
					return interaction:delete()
				else
					return interaction:success("A session staff vote has been successfully initiated" .. ((autoStart and " and will automatically start a **public** session vote if it reaches **" .. votesRequired .. " votes**.") or "."), nil, true)
				end
			else
				return interaction:fail(e, nil, true)
			end
		end
	end
}
