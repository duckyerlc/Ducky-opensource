-- unban.lua
local slashCommand = tools.slashCommand("unban", "Unban a user.")
local option = tools.user("user", "The user to unban."):setRequired(true)
slashCommand = slashCommand:addOption(option)
local option = tools.string("reason", "The reason for the unban."):setRequired(false)
slashCommand = slashCommand:addOption(option)

return {
    name = "unban",
    description = "Unban a user.",
    aliases = {},
    category = "Moderation",
    slashCommand = slashCommand,
    requiredPermissions = {"ADMIN"},
    hybridCallback = function(interaction, args, command)
        local user = (interaction.mentionedUsers and interaction.mentionedUsers.first) or (args and args.user)
        local attempted = false
        if not user then
            if (not command) and (args[1]) then
                attempted = true
                if tonumber(args[1]) then
                    user = Client:getUser(args[1])
                end
            end
        end

        if (not user) and (not attempted) then
            return interaction:fail("You did not provide a user to unban.")
        elseif (not user) and (attempted) then
            return interaction:fail("I could not find that user.")
        end

        local reason = (args and args.reason) or ((not command) and table.remove(args, 1) and table.concat(args, " "))

        if reason == "" or reason == " " then
            reason = nil
        end

        if not interaction.guild:getBan(user.id) then
            return interaction:fail(getUserString(user) .. " is not banned.")
        end

        local unbanned, err = interaction.guild:unbanUser(user.id)

        if (not unbanned) then
            return interaction:fail("I could not unban that user: " .. err:usub(1, 16))
        end

        interaction:success(getUserString(user) .. " has been unbanned.")

        db:send(interaction.guild, "modlogchannel", {
            embed = {
                author = author(interaction.member),
                thumbnail = (user.avatarURL and {
                    url = user.avatarURL
                }) or (user.defaultAvatarURL and {
                    url = user.defaultAvatarURL
                }),
                title = emojis.success .. " Member Unbanned",
                description = getUserString(user) .. " was unbanned by " .. getUserString(interaction.member) .. ":" ..
                    ((reason and "\n" .. emojis.right .. " **Reason:** " .. reason) or "") .. "\n" .. emojis.right ..
                    " **Date:** <t:" .. os.time() .. ">",
                color = colors.success
            }
        })
    end
}