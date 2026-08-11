-- modules/sessions.lua

local sessions = {
	name = "sessions",
	description = "Handles all session related interactions.",
}

local connections = {}

local currentlyVoting = {}

sessions.Start = function()
	connections["interactionSessions"] = Client:on("interactionSessions", function(interaction, config)
		local guild = interaction.guild
		local interactionId = interaction.data.custom_id

		if interactionId == "show" then
			local session = config.session or {}
			if
				(session.status ~= "vote" and session.status ~= "staffvote")
				or not session.votes
				or (session.message ~= interaction.message.id)
			then
				return interaction:fail("This session vote is no longer active.", nil, true)
			elseif not next(session.votes) then
				return interaction:fail("Nobody has voted for this session.", nil, true)
			end

			local pages = {}
			local embed = {
				title = emojis.people
					.. " Session Voters ("
					.. table.count(session.votes)
					.. "/"
					.. session.votesRequired
					.. ")",
				description = "",
				color = colors.info,
			}
			local onPage = 0

			for c, id in pairs(session.votes) do
				embed.description = embed.description .. emojis.right .. " <@" .. id .. ">\n"

				onPage = onPage + 1

				if onPage >= 20 or c >= table.count(session.votes) then
					table.insert(pages, embed)
					embed = {
						title = emojis.people
							.. " Session Voters ("
							.. table.count(session.votes)
							.. "/"
							.. session.votesRequired
							.. ")",
						description = "",
						color = colors.info,
					}
					onPage = 0
				end
			end

			return paginate(interaction, pages, interaction.user, {
				clamp = false,
				ephemeral = true,
			})
		elseif interactionId == "vote" then
			local session = config.session or {}
			if
				(session.status ~= "vote" and session.status ~= "staffvote")
				or not session.votes
				or (session.message ~= interaction.message.id)
			then
				return interaction:fail("This session vote is no longer active.", nil, true)
			end

			if currentlyVoting[guild.id] then
				return interaction:fail("Someone is currently voting, **please try again**.\n-# " .. emojis.right .. " This is to prevent [race conditions](<https://en.wikipedia.org/wiki/Race_condition>).", nil, true)
			end

			local ok, err = pcall(function()
				currentlyVoting[guild.id] = true

				local initiator = guild:getMember(session.initiator)
				if not initiator then
					return interaction:fail(
						"This session vote is no longer valid as the initiator is no longer a member of this server.",
						nil,
						true
					)
				end

				local _, existing = table.find(session.votes, interaction.member.id)

				if existing then
					table.remove(session.votes, existing)
					interaction:warning("Your vote has been successfully removed.", nil, true)
				else
					table.insert(session.votes, interaction.member.id)
					interaction:success("Your vote has been successfully added.", nil, true)
				end

				local toupd = {
					content = interaction.message.content,
					components = discordia
						.Components()
						:button({
							id = "vote",
							label = "Vote (" .. table.count(session.votes) .. "/" .. session.votesRequired .. ")",
							style = "success",
							emoji = resolvedEmojis.yeswhite,
						})
						:button({
							id = "show",
							label = "Voters",
							emoji = resolvedEmojis.people,
							style = "secondary",
						})
						:raw(),
				}

				if session.status == "vote" then
					toupd.embeds = parseTable(
						config.voteembeds
							or {{
								author = {
									name = guild.name,
									icon_url = guild.iconURL,
								},
								title = emojis.game .. " Session Vote",
								description = "> The in-game server session may be started soon. Press the **Vote** button below to vote for the session. If this vote receives at least **{votes.required} votes**, a session will be started!\n> -# If you vote, you are **required** to join. Failure to do so may result in moderation.",
								color = colors.info,
								footer = {
									text = "Session vote initiated {initiator.name}",
									icon_url = "{initiator.avatar}",
								},
							}},
						DiscordUserVariables(initiator, "initiator", {
							["votes.received"] = tostring(table.count(session.votes)),
							["votes.required"] = tostring(session.votesRequired),
							["timestamp"] = tostring(session.timestamp),
						})
					)
				elseif session.status == "staffvote" then
					toupd.embeds = parseTable(
						config.staffvoteembeds
							or {{
								author = {
									name = guild.name,
									icon_url = guild.iconURL,
								},
								title = emojis.game .. " Session Staff Vote",
								description = "> The in-game server session may be started soon. If you will be able to attend the session, press the **Vote** button below. If this staff vote receives at least **{votes.required} votes**, a **public** session vote will be started!\n> -# If you vote, you are **required** to join. Failure to do so may result in an infraction.",
								color = colors.info,
								footer = {
									text = "Session staff vote initiated by {initiator.name}",
									icon_url = "{initiator.avatar}",
								},
							}},
						DiscordUserVariables(initiator, "initiator", {
							["votes.received"] = tostring(table.count(session.votes)),
							["votes.required"] = tostring(session.votesRequired),
							["timestamp"] = tostring(session.timestamp),
						})
					)
				end

				interaction.message:update(toupd)

				sqldb:set(guild.id, {
					session = session,
				}, "SESSION_VOTE_UPDATE")

				if session.autoStart and (table.count(session.votes) >= session.votesRequired) then
					if session.status == "vote" then
						return db:sessionStart(initiator)
					elseif session.status == "staffvote" then
						return db:sessionVote(initiator, session.publicVotesRequired, session.autoStart)
					end
				end
			end)

			currentlyVoting[guild.id] = nil

			if not ok then
				return interaction:fail("Something went wrong while trying to add/remove your vote: ```" .. tostring(err) .. "```")
			end
		end
	end)
end

sessions.Stop = function()
	for event, connection in pairs(connections) do
		Client:removeListener(event, connection)
	end

	connections = nil
end

return sessions
