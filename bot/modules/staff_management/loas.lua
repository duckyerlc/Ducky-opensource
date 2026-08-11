-- modules/loas.lua

local loas = {
	name = "loas",
	description = "Powers LOA approval/denial/expiration."
}

local connections = {}

loas.Start = function()
	connections["interactionLoas"] = Client:on("interactionLoas", function(interaction, config)
        local guild = interaction.guild
        local interactionId = interaction.data.custom_id

		if interactionId:usub(1,8) == "denyloa_" then
            local member = interactionId:usub(9) and guild:getMember(interactionId:usub(9))

            if not member then
                return interaction:fail("The member could not be found.", nil, true)
            end

            prompt(interaction, "Deny Reason", {
                {
                    question = "Deny Reason",
                    placeholder = "Enter the reason for this LOA's denial...",
                    style = "paragraph",
                    required = false
                }
            }, function(mia, responses)
                if mia then
                    responses = responses or {}
                    local success, err = db:denyLOA(member, responses and responses["Deny Reason"])
                    local embed = table.deepcopy(interaction.message.embeds[1])

                    if success then
                        embed.title = emojis.fail .. " LOA Denied"
                        embed.footer = {
                            text = "LOA denied by " .. interaction.member.name .. (((responses and responses["Deny Reason"]) and ": " .. responses["Deny Reason"]) or ""),
                            icon_url = interaction.user.avatarURL
                        }
                        embed.color = colors.fail

                        interaction.message:update({
                            embed = embed,
                            components = {}
                        })

                        mia:updateDeferred(true)

                        if config.loalogschannel and interaction.channel.id ~= config.loalogschannel then
                            local loalogschannel = guild:getChannel(config.loalogschannel)

                            if loalogschannel then
                                loalogschannel:send({
                                    embed = embed,
                                    components = {}
                                })
                            end
                        end
                    else
                        mia:fail(err or "An unknown error occurred. Please try again later.", nil, true)
                    end
                else
                    mia:updateDeferred(true)
                end
            end, false)
        elseif interactionId:usub(1,11) == "approveloa_" then
            local member = interactionId:usub(12) and guild:getMember(interactionId:usub(12))

            if not member then
                return interaction:fail("The member could not be found.", nil, true)
            end

            local s, e = db:approveLOA(member)

            local emb = table.deepcopy(interaction.message.embeds[1])

            if s then
                emb.title = emojis.success .. " LOA Approved"
                emb.footer = {
                    text = "LOA approved by " .. interaction.member.name,
                    icon_url = interaction.user.avatarURL
                }
                emb.color = colors.success

                interaction.message:update({
                    embed = emb,
                    components = {}
                })

                if config.loalogschannel and interaction.channel.id ~= config.loalogschannel then
                    local loalogschannel = guild:getChannel(config.loalogschannel)

                    if loalogschannel then
                        loalogschannel:send({
                            embed = emb,
                            components = {}
                        })
                    end
                end
            else
                interaction:fail(e or "An unknown error occurred. Please try again later.", nil, true)
            end
        end

	end)

    connections["scheduleLoas"] = Client:on("scheduleLoas", function(guild, config)
        if config.loas then
            for i, loa in pairs(config.loas) do
                if os.time() >= loa.ends and loa.active then
                    local loaMember = guild:getMember(loa.user)
                    if loaMember then
                        db:endLOA(loaMember, nil)
                    else
                        for i, v in pairs(config.loas or {}) do
                            if v.user == loa.user and loa.active then
                                loa.active = false
                                loa.ends = os.time()
                                config = select(2, sqldb:set(guild.id, { loas = config.loas }, "LOA_END"))
                            end
                        end
                    end
                end
            end
        end
    end)
end

loas.Stop = function()
	for event, connection in pairs(connections) do
		Client:removeListener(event, connection)
	end
    
    connections = nil
end

return loas
