-- suggestions.lua
local suggestions = {
	name = "suggestions",
	description = "Powers suggestion upvoting, downvoting, approving, & denying."
}

local connection = nil

suggestions.Start = function()
	connection = Client:on("interactionCreate", function(interaction)
		coroutine.wrap(function()
			if not interaction.guild or not interaction.channel or not interaction.message or not interaction.id or not interaction.user then
				return
			end

			local id = interaction.data.custom_id

			if not id then
				return
			end

			local function buildVoteEmbeds(config, suggestion)
				local suggester = Client:getUser(suggestion.submitter)

				local keys = {
					["submitter.name"] = suggester and suggester.name or "N/A",
					["submitter.username"] = suggester and suggester.username or "N/A",
					["submitter.id"] = suggestion.submitter,
					["submitter.mention"] = suggester and suggester.mentionString or ("<@" .. suggestion.submitter .. ">"),
					["submitter.avatar"] = suggester and suggester.avatarURL or "",
					["suggestion.suggestion"] = suggestion.suggestion,
					["suggestion.upvotes"] = tostring(#suggestion.upvotes),
					["suggestion.downvotes"] = tostring(#suggestion.downvotes),
					["suggestion.id"] = tostring(suggestion.id)
				}

				if config.suggestionsubmittedembeds then
					return parseTable(config.suggestionsubmittedembeds, keys)
				else
					return {
						{
							title = emojis.suggestion .. " Suggestion Submitted",
							description = emojis.right ..
								" **Submitter:** " .. suggester.mentionString .. "\n" ..
								emojis.right ..
								" **Suggestion:** " .. suggestion.suggestion .. "\n" ..
								emojis.right ..
								" **Upvotes:** " .. emojis.success .. " " .. tostring(#suggestion.upvotes) .. "\n" ..
								emojis.right ..
								" **Downvotes:** " .. emojis.fail .. " " .. tostring(#suggestion.downvotes) .. "\n" ..
								emojis.right ..
								" **ID:** `" .. suggestion.id .. "`",
							color = colors.info,
							thumbnail = suggester.avatarURL and {
								url = suggester.avatarURL
							} or nil,
							author = {
								name = "@" .. suggester.username,
								icon_url = suggester.avatarURL
							},
						}
					}
				end
			end

			if id:usub(1, 7) == "upvote_" then
				local suggestionID = id:usub(8)
				if not suggestionID then
					return
				end

				local config = sqldb:get(interaction.guild.id)
				if not config or not config.suggestions then
					return
				end

				local suggestion
				for _, s in pairs(config.suggestions) do
					if s.id == suggestionID then
						suggestion = s
						break
					end
				end
				if not suggestion then
					return
				end

				if table.find(suggestion.downvotes, interaction.user.id) then
					for i, v in pairs(suggestion.downvotes) do
						if v == interaction.user.id then
							table.remove(suggestion.downvotes, i)
							break
						end
					end
				end

				local alreadyUpvoted = table.find(suggestion.upvotes, interaction.user.id)
				local newUpvoteCount = #suggestion.upvotes
				if not alreadyUpvoted then
					newUpvoteCount = newUpvoteCount + 1
				else
					newUpvoteCount = newUpvoteCount - 1
				end

				local maxUpvotes = tonumber(config.suggestionsmaxupvotes)
				if maxUpvotes and newUpvoteCount >= maxUpvotes and not suggestion.approved then
					if not alreadyUpvoted then
						table.insert(suggestion.upvotes, interaction.user.id)
					end

					suggestion.approved = true
					suggestion.approverId = "AUTO"
					suggestion.approvereason = "Max upvotes reached."

					local suggester = interaction.guild:getMember(suggestion.submitter)

					local keys = {
						["submitter.name"] = suggester and suggester.name or "N/A",
						["submitter.username"] = suggester and suggester.username or "N/A",
						["submitter.id"] = suggestion.submitter,
						["submitter.mention"] = suggester and suggester.mentionString or ("<@" .. suggestion.submitter .. ">"),
						["submitter.avatar"] = suggester and suggester.avatarURL or "",
						["suggestion.suggestion"] = suggestion.suggestion,
						["suggestion.upvotes"] = tostring(#suggestion.upvotes),
						["suggestion.downvotes"] = tostring(#suggestion.downvotes),
						["suggestion.id"] = tostring(suggestion.id),
						["suggestion.approvereason"] = tostring(suggestion.approvereason),
						["approver.name"] = "N/A",
						["approver.username"] = "N/A",
						["approver.id"] = "N/A",
						["approver.mention"] = "N/A",
						["approver.avatar"] = ""
					}

					local embeds

					if config.suggestionapproveembeds then
						embeds = parseTable(config.suggestionapproveembeds, keys)
					else
						embeds = {
							{
								title = emojis.success .. " Suggestion Auto Approved",
								description = emojis.right ..
									" **Submitter:** " .. suggester.mentionString .. "\n" ..
									emojis.right ..
									" **Suggestion:** " .. suggestion.suggestion .. "\n" ..
									emojis.right ..
									" **Upvotes:** " .. emojis.success .. " " .. tostring(#suggestion.upvotes) .. "\n" ..
									emojis.right ..
									" **Downvotes:** " .. emojis.fail .. " " .. tostring(#suggestion.downvotes) .. "\n" ..
									emojis.right ..
									" **Reason:** " .. suggestion.approvereason,
								color = colors.success,
								thumbnail = suggester.avatarURL and {
									url = suggester.avatarURL
								} or nil,
								author = {
									name = "@" .. suggester.username,
									icon_url = suggester.avatarURL
								},
							}
						}
					end

					local suggestChannel = interaction.guild:getChannel(config.suggestchannel)
					if suggestChannel then
						local msg = suggestChannel:getMessage(suggestion.message)
						if msg then
							msg:update({
								embeds = embeds,
								components = {}
							})
						end
					end

					for i, s in ipairs(config.suggestions) do
						if s.id == suggestion.id then
							table.remove(config.suggestions, i)
							break
						end
					end

					sqldb:set(interaction.guild.id, {
						suggestions = config.suggestions
					}, "SUGGESTION_AUTO_APPROVE")
					return interaction:success("This suggestion has been auto-approved!", nil, true)
				end

				if alreadyUpvoted then
					for i, v in pairs(suggestion.upvotes) do
						if v == interaction.user.id then
							table.remove(suggestion.upvotes, i)
							break
						end
					end
					sqldb:set(interaction.guild.id, {
						suggestions = config.suggestions
					}, "SUGGESTION_UPVOTE_REMOVE")
					local newEmbeds = buildVoteEmbeds(config, suggestion)
					interaction.message:update({
						embeds = newEmbeds,
						components = interaction.message.components
					})
					interaction:success("Your upvote has been removed.", nil, true)
				else
					table.insert(suggestion.upvotes, interaction.user.id)
					sqldb:set(interaction.guild.id, {
						suggestions = config.suggestions
					}, "SUGGESTION_UPVOTE_ADD")
					local newEmbeds = buildVoteEmbeds(config, suggestion)
					interaction.message:update({
						embeds = newEmbeds,
						components = interaction.message.components
					})
					interaction:success("You have upvoted this suggestion.", nil, true)
				end
			elseif id:usub(1, 9) == "downvote_" then
				local suggestionID = id:usub(10)
				if not suggestionID then
					return
				end

				local config = sqldb:get(interaction.guild.id)
				if not config or not config.suggestions then
					return
				end

				local suggestion
				for _, s in pairs(config.suggestions) do
					if tostring(s.id) == tostring(suggestionID) then
						suggestion = s
						break
					end
				end
				if not suggestion then
					return
				end

				if table.find(suggestion.upvotes, interaction.user.id) then
					for i, v in pairs(suggestion.upvotes) do
						if v == interaction.user.id then
							table.remove(suggestion.upvotes, i)
							break
						end
					end
				end

				local alreadyDownvoted = table.find(suggestion.downvotes, interaction.user.id)
				local newDownvoteCount = #suggestion.downvotes
				if not alreadyDownvoted then
					newDownvoteCount = newDownvoteCount + 1
				else
					newDownvoteCount = newDownvoteCount - 1
				end

				if config.suggestionsmaxdownvotes and newDownvoteCount >= tonumber(config.suggestionsmaxdownvotes) and not suggestion.approved then
					if not alreadyDownvoted then
						table.insert(suggestion.downvotes, interaction.user.id)
					end

					suggestion.approved = false
					suggestion.denierId = "AUTO"
					suggestion.denyreason = "Max downvotes reached."

					local suggester = interaction.guild:getMember(suggestion.submitter)

					local keys = {
						["submitter.name"] = suggester and suggester.name or "N/A",
						["submitter.username"] = suggester and suggester.username or "N/A",
						["submitter.id"] = suggestion.submitter,
						["submitter.mention"] = suggester and suggester.mentionString or ("<@" .. suggestion.submitter .. ">"),
						["submitter.avatar"] = suggester and suggester.avatarURL or "",
						["suggestion.suggestion"] = suggestion.suggestion,
						["suggestion.upvotes"] = tostring(#suggestion.upvotes),
						["suggestion.downvotes"] = tostring(#suggestion.downvotes),
						["suggestion.id"] = tostring(suggestion.id),
						["suggestion.denyreason"] = tostring(suggestion.denyreason),
						["denier.name"] = "N/A",
						["denier.username"] = "N/A",
						["denier.id"] = "N/A",
						["denier.mention"] = "N/A",
						["denier.avatar"] = ""
					}

					local embeds

					if config.suggestiondenyembeds then
						embeds = parseTable(config.suggestiondenyembeds, keys)
					else
						embeds = {
							{
								title = emojis.fail .. " Suggestion Auto Denied",
								description = emojis.right ..
									" **Submitter:** " .. suggester.mentionString .. "\n" ..
									emojis.right ..
									" **Suggestion:** " .. suggestion.suggestion .. "\n" ..
									emojis.right ..
									" **Upvotes:** " .. emojis.success .. " " .. tostring(#suggestion.upvotes) .. "\n" ..
									emojis.right ..
									" **Downvotes:** " .. emojis.fail .. " " .. tostring(#suggestion.downvotes) .. "\n" ..
									emojis.right .. 
									" **Reason:** " .. suggestion.denyreason,
								color = colors.fail,
								thumbnail = suggester.avatarURL and {
									url = suggester.avatarURL
								} or nil,
								author = {
									name = "@" .. suggester.username,
									icon_url = suggester.avatarURL
								},
							}
						}
					end

					local suggestChannel = interaction.guild:getChannel(config.suggestchannel)
					if suggestChannel then
						local ok, msg = pcall(function()
							return suggestChannel:getMessage(suggestion.message)
						end)
						if ok and msg then
							msg:update({
								embeds = embeds,
								components = {}
							})
						end
					end

					for i, s in ipairs(config.suggestions) do
						if s.id == suggestion.id then
							table.remove(config.suggestions, i)
							break
						end
					end

					sqldb:set(interaction.guild.id, {
						suggestions = config.suggestions
					}, "SUGGESTION_AUTO_DENY")
					return interaction:success("This suggestion has been auto-denied!", nil, true)
				end

				if alreadyDownvoted then
					for i, v in pairs(suggestion.downvotes) do
						if v == interaction.user.id then
							table.remove(suggestion.downvotes, i)
							break
						end
					end
					sqldb:set(interaction.guild.id, {
						suggestions = config.suggestions
					}, "SUGGESTION_DOWNVOTE_REMOVE")
					local newEmbeds = buildVoteEmbeds(config, suggestion)
					interaction.message:update({
						embeds = newEmbeds,
						components = interaction.message.components
					})
					interaction:success("Your downvote has been removed.", nil, true)
				else
					table.insert(suggestion.downvotes, interaction.user.id)
					sqldb:set(interaction.guild.id, {
						suggestions = config.suggestions
					}, "SUGGESTION_DOWNVOTE_ADD")
					local newEmbeds = buildVoteEmbeds(config, suggestion)
					interaction.message:update({
						embeds = newEmbeds,
						components = interaction.message.components
					})
					interaction:success("You have downvoted this suggestion.", nil, true)
				end
			end
		end)()
	end)
end

suggestions.Stop = function()
	Client:removeListener("interactionCreate", connection)

	connection = nil
end

return suggestions
