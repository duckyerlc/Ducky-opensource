-- modules/feedback.lua
local feedback = {
	name = "feedback",
	description = "Handles all feedback related interactions."
}

local connections = {}

feedback.Start = function()
	connections["interactionFeedback"] = Client:on("interactionFeedback", function(interaction, config)
		local guild = interaction.guild
		local interactionId = interaction.data.custom_id

		if interactionId:usub(1, 7) == "apprdf_" then
			local id = interactionId:usub(8)

			config.pendingduckyfeedback = config.pendingduckyfeedback or {}
			config.duckyfeedback = config.duckyfeedback or {}

			for i, pending in pairs(config.pendingduckyfeedback) do
				if pending.submitter == id then
					local submitter = Client:getUser(pending.submitter)

					table.insert(config.duckyfeedback, pending)
					table.remove(config.pendingduckyfeedback, i)

					sqldb:set(duckysPond.id, {
						duckyfeedback = config.duckyfeedback,
						pendingduckyfeedback = config.pendingduckyfeedback
					}, "DUCKY_FEEDBACK_APPROVE")

					local emb = interaction.message.embed
					emb.color = colors.success
					emb.footer = {
						text = "Approved by " .. interaction.member.name,
						icon_url = interaction.member.avatarURL
					}

					interaction.message:update({
						embed = emb,
						components = {}
					})

					submitter:send(emojis.success .. " **Good news!** Your feedback on " .. emojis.ducky .. " **Ducky** was approved. Thank you!")
					return mia:updateDeferred(true)
				end
			end

			return interaction:fail("This feedback was not found.", nil, true)
		elseif interactionId:usub(1, 7) == "denydf_" then
			local id = interactionId:usub(8)

			config.pendingduckyfeedback = config.pendingduckyfeedback or {}

			for i, pending in pairs(config.pendingduckyfeedback) do
				if pending.submitter == id then
					return prompt(interaction, "Deny Feedback", {
						{
							question = "Denial Reason",
							required = true,
							placeholder = "Why are you denying this feedback?",
							style = "short"
						}
					}, function(mia, responses)
						if mia and responses and responses["Denial Reason"] and responses["Denial Reason"] ~= "" then
							local reason = responses["Denial Reason"]

							local submitter = Client:getUser(pending.submitter)

							table.remove(config.pendingduckyfeedback, i)

							sqldb:set(duckysPond.id, {
								pendingduckyfeedback = config.pendingduckyfeedback
							}, "DUCKY_FEEDBACK_DENY")

							local emb = interaction.message.embed
							emb.color = colors.fail
							emb.footer = {
								text = "Denied by " .. interaction.member.name .. ": " .. reason,
								icon_url = interaction.member.avatarURL
							}

							interaction.message:update({
								embed = emb,
								components = {}
							})

							submitter:send(emojis.fail .. " **Bad news.** Your feedback on " .. emojis.ducky .. " **Ducky** was denied: **" .. reason .. "**.")
							return mia:updateDeferred(true)
						else
							return mia:fail("You did not provide a reason for the denial of this feedback.", nil, true)
						end
					end)
				end
			end

			return interaction:fail("This feedback was not found.", nil, true)
		end
	end)
end

feedback.Stop = function()
	for event, connection in pairs(connections) do
		Client:removeListener(event, connection)
	end

	connections = nil
end

return feedback
