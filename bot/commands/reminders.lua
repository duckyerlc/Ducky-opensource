-- reminders.lua
local slashCommand = tools.slashCommand("reminders", "Manage your reminders.")
local subcmd = tools.subCommand("set", "Set a reminder for yourself.")
subcmd = subcmd:addOption(tools.string("in", "The amount of time to remind you in."):setRequired(true))
subcmd = subcmd:addOption(tools.string("content", "The reminder's content."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("list", "List your pending reminders.")
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("cancel", "Cancel an active reminder.")
subcmd = subcmd:addOption(tools.string("reminder", "The reminder to cancel."):setRequired(true):setAutocomplete(true))
slashCommand = slashCommand:addOption(subcmd)

return {
	name = "reminders",
	description = "Set a reminder for yourself.",
	aliases = {
		"reminder",
        "remindme",
        "remind"
	},
	category = "Utility",
	slashCommand = slashCommand,
	requiredPermissions = {},
    subcommands = {
        "set",
        "list",
        "cancel"
    },
	autocomplete = function(interaction, command, focused, args)
		local opts = {}
		if focused and (focused.name == "reminder") then
            local userSettings = sqldb:getUserSettings(interaction.user.id) or {}
            userSettings.reminders = userSettings.reminders or {}

			for i, reminder in pairs(userSettings.reminders) do
                table.insert(opts, {
                    name = "#" .. i .. "・" .. string.truncate(reminder.content, 25),
                    value = tostring(i)
                })
            end
		end

		return interaction:autocomplete(opts)
	end,
	hybridCallback = function(interaction, args, slash, subcmd)
        if not slash then
            table.remove(args, 1)
        end

        if subcmd == "set" then
            local time = (slash and args and args["in"] and convert(args["in"])) or ((not slash) and args and args[1] and convert(args[1]))
            local content = (slash and args and args.content) or ((not slash) and args and args[2] and table.concat(args, " ", 2))

            if (not time) or (time <= 0) then
                return interaction:fail("You did not provide a valid amount of time.", nil, true)
            elseif (not content) or (content == "") then
                return interaction:fail("You did not provide the content for this reminder.", nil, true)
            end

            local userSettings = sqldb:getUserSettings(interaction.user.id) or {}
            userSettings.reminders = userSettings.reminders or {}
            
            local start = os.time()

            table.insert(userSettings.reminders, {
                content = content,
                timestamp = start,
                remind = start + time
            })

            local success, err = sqldb:setUserSettings(interaction.user.id, userSettings)
            if success then
                return interaction:success("You will be reminded in **" .. readable(time) .. "**: " .. content)
            else
                return interaction:fail("An unexpected error occurred while saving your reminder: " .. tostring(err), nil, true)
            end
        elseif subcmd == "list" then
            local userSettings = sqldb:getUserSettings(interaction.user.id) or {}
            userSettings.reminders = userSettings.reminders or {}

            if table.count(userSettings.reminders) <= 0 then
                return interaction:fail("You do not have any reminders set.", nil, true)
            end

            local pages = {}
            local page
            local onpage

            local function resetPage()
                page = {
                    author = author(interaction.user),
                    title = emojis.reminder .. " Reminders",
                    description = "",
                    color = colors.yellow
                }
                onpage = 0
            end

            resetPage()

            for i, reminder in pairs(userSettings.reminders) do
                page.description = page.description .. emojis.right .. " **Reminder #" .. i .. "**\n" .. emojis.space .. emojis.right .. " **Content:** " .. tostring(reminder.content) .. "\n" .. emojis.space .. emojis.right .. " **Set:** <t:" .. reminder.timestamp .. "> (<t:" .. reminder.timestamp .. ":R>)\n" .. emojis.space .. emojis.right .. " **Reminds:** <t:" .. reminder.remind .. "> (<t:" .. reminder.remind .. ":R>)\n"
                onpage = onpage + 1

                if i >= #userSettings.reminders or onpage >= 5 then
                    table.insert(pages, page)
                    resetPage()
                end
            end

            return paginate(interaction, pages, interaction.user, {
                clamp = false,
                teleport = true,
                ephemeral = true
            })
        elseif subcmd == "cancel" then
            local userSettings = sqldb:getUserSettings(interaction.user.id) or {}
            userSettings.reminders = userSettings.reminders or {}
            
            local reminderID = (slash and args and args.reminder and tonumber(args.reminder)) or ((not slash) and args and args[1] and tonumber(args[1]))
            local reminder = userSettings.reminders[reminderID]
            if not reminder then
                return interaction:fail("You do not have a reminder with that ID.", nil, true)
            end

            table.remove(userSettings.reminders, reminderID)
            
            local success, err = sqldb:setUserSettings(interaction.user.id, userSettings)
            if success then
                return interaction:success("That reminder has been canceled.", nil, true)
            else
                return interaction:fail("An unexpected error occurred while cancelling that reminder: " .. tostring(err), nil, true)
            end
        end
	end
}
