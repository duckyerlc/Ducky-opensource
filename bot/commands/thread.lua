-- thread.lua

return {
	name = "thread",
	description = "Internal command used to send a support panel thread in the event that it is not automatically sent.",
	aliases = {"threadpanel", "tp", "supportpanel", "sp"},
	category = "Support",
	slashCommand = nil,
	requiredPermissions = {"SUPPORT"},
	hybridCallback = function(interaction, args)
        local thread = interaction.channel and interaction.channel.type == discordia.enums.channelType.publicThread and interaction.channel
        if not thread then return interaction:fail("This is not a thread.") end

        Client:emit("threadCreate", thread, true)
        interaction:delete()
	end
}
