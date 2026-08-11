-- botreview.lua

local slashCommand = tools.slashCommand("botreview", "Leave feedback on Ducky.")
slashCommand = slashCommand:addOption(tools.string("rating", "The rating for Ducky.")
	:addChoice(tools.choice("⭐", "1"))
	:addChoice(tools.choice("⭐⭐", "2"))
	:addChoice(tools.choice("⭐⭐⭐", "3"))
	:addChoice(tools.choice("⭐⭐⭐⭐", "4"))
	:addChoice(tools.choice("⭐⭐⭐⭐⭐", "5"))
	:setRequired(true)
)
slashCommand = slashCommand:addOption(tools.string("feedback", "Feedback you would like to provide on Ducky."):setRequired(true))

return {
    name = "botreview",
    description = "Leave a review on Ducky.",
    aliases = {"botfeedback", "ratebot", "duckyfeedback", "duckyreview", "rateducky"},
    category = "General",
    slashCommand = slashCommand,
    requiredPermissions = {},
    hybridCallback = function(interaction, args, slash)
        local rating = (slash and args and args.rating and tonumber(args.rating)) or ((not slash) and args and args[1] and tonumber(args[1]))
        local feedback = (slash and args and args.feedback) or ((not slash) and args and table.remove(args, 1) and table.concat(args, " "))

        if not rating then
            return interaction:fail("You did not provide a valid rating.", nil, true)
        elseif (not feedback) or (feedback == "") then
            return interaction:fail("You did not provide feedback for this review.", nil, true)
        end

        rating = math.clamp(rating, 1, 5)

        local config = sqldb:get(duckysPond.id)

        if not config then
            return interaction:fail("An error occurred while attempting to fetch Ducky's feedback. Please try again later.", nil, true)
        end

        config.duckyfeedback = config.duckyfeedback or {}
        config.pendingduckyfeedback = config.pendingduckyfeedback or {}

        for _, v in pairs(config.pendingduckyfeedback) do
            if v.submitter == interaction.user.id then
                return interaction:fail("You already have a pending feedback.", nil, true)
            end
        end

        for _, v in pairs(config.duckyfeedback) do
            if v.submitter == interaction.user.id then
                return interaction:fail("You have already submitted feedback to Ducky.", nil, true)
            end
        end

        confirm(interaction,
        "Please confirm you understand:"
        .. "\n\n" .. emojis.right .. "This is a review for the bot "
        .. emojis.ducky .. " **Ducky**, and that your review will be placed on "
        .. emojis.ducky .. " **[Ducky's Website](https://duckybot.xyz/reviews)**."
        .. "\n" .. emojis.right .. "This is **NOT** a review for **" .. interaction.guild.name .. "**.",
        function(response, mia)
            if response then
                local s, e = duckysPond:getChannel("1349883167271686195"):send({
                    embed = {
                        title = emojis.star .. " Feedback Received",
                        description = ">>> [**@" .. interaction.user.username .. "**](https://discord.com/users/" .. interaction.user.id .. ") has submitted feedback on " .. emojis.ducky .. " **Ducky**:\n" .. emojis.right .. " **Rating:** " .. starMap[rating] .. "\n" .. emojis.right .. " **Feedback:** " .. feedback,
                        color = colors.warning,
                        author = {
                            name = "@" .. interaction.user.username,
                            icon_url = interaction.user.avatarURL
                        },
                        thumbnail = thumbnail(interaction.user)

                    },
                    components = discordia.Components()
                        :button({
                            id = "apprdf_" .. interaction.user.id,
                            emoji = resolvedEmojis.yeswhite,
                            style = "success"
                        })
                        :button({
                            id = "denydf_" .. interaction.user.id,
                            emoji = resolvedEmojis.nowhite,
                            style = "danger"
                        })
                        :raw()
                })

                table.insert(config.pendingduckyfeedback, {
                    submitter = interaction.user.id,
                    rating = rating,
                    feedback = feedback,
                    timestamp = os.time()
                })

                sqldb:set(duckysPond.id, {pendingduckyfeedback = config.pendingduckyfeedback}, "DUCKY_PENDING_FEEDBACK_SUBMIT")

                if s then
                    return mia:success("Your feedback has been submitted to staff for approval to ensure it's appropriate. This should not take longer than 3 hours, and you'll be notified if your feedback goes through.", nil, true)
                else
                    return mia:fail("An error occurred wihle attempting to submit your feedback for approval. Please try again later.", nil, true)
                end
            end
        end, true, 8000)
    end
}