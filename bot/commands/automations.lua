-- automations.lua
local slashCommand = tools.slashCommand("automations", "Use Ducky's automations module.")

local subCommand = tools.subCommand("create", "Create an automation.")
slashCommand = slashCommand:addOption(subCommand)

local subCommand = tools.subCommand("edit", "Edit an automation.")
subCommand = subCommand:addOption(tools.string("automation", "The automation name/ID of which you would like to edit."):setRequired(true))
slashCommand = slashCommand:addOption(subCommand)

local subCommand = tools.subCommand("list", "List all automations in your server.")
slashCommand = slashCommand:addOption(subCommand)

local subCommand = tools.subCommand("delete", "Delete an automation.")
subCommand = subCommand:addOption(tools.string("automation", "The automation name/ID of which you would like to delete."):setRequired(true))
slashCommand = slashCommand:addOption(subCommand)

local subCommand = tools.subCommand("run", "Manually run an automation.")
subCommand = subCommand:addOption(tools.string("automation", "The automation name/ID of which you would like to run."):setRequired(true))
slashCommand = slashCommand:addOption(subCommand)

--[[ Automation Builder ]] --

local triggerSelect = discordia.SelectMenu({
	placeholder = "Select a trigger for this automation...",
	id = "triggerselect",
	min_values = 0,
	max_values = 1,
	actionRow = 1
})

triggerSelect:option("Manual", "manual", "Trigger this automation manually to a create custom command.", false, resolvedEmojis.developer)
triggerSelect:option("Player Join", "playerjoin", "When a player joins...", false, resolvedEmojis.add)
triggerSelect:option("Player Leave", "playerleave", "When a player leaves...", false, resolvedEmojis.subtract)
triggerSelect:option("Playercount Reaches", "playercount", "When the playercount reaches...", false, resolvedEmojis.person)
triggerSelect:option("Playercount Rises Above", "playercountg", "When the playercount rises above...", false, resolvedEmojis.add)
triggerSelect:option("Playercount Drops Below", "playercountl", "When the playercount drops below...", false, resolvedEmojis.subtract)
triggerSelect:option("Player Killed", "playerkill", "When a player gets killed in-game...", false, resolvedEmojis.swords)
triggerSelect:option("Players Killed In", "killedin", "When a player kills x players in t...", false, resolvedEmojis.swords)
triggerSelect:option("Region Entered", "regionentered", "When a player enters a region...", false, resolvedEmojis.map)
triggerSelect:option("Region Exited", "regionexited", "When a player exits a region...", false, resolvedEmojis.map)
triggerSelect:option("Emergency Created", "emergencycall", "When a player calls emergency services...", false, resolvedEmojis.modcall)
triggerSelect:option("Vehicle Used", "vehiclespawn", "When a player spawned the specified vehicle...", false, resolvedEmojis.vehiclelocked)
triggerSelect:option("Livery Used", "liveryused", "When a player uses the specified livery...", false, resolvedEmojis.livery)
triggerSelect:option("Plate Used", "plate", "When a player uses a license plate...", false, resolvedEmojis.license)
triggerSelect:option("Player Joins Team", "team", "When a player joins the specified team...", false, resolvedEmojis.flag)
triggerSelect:option("Team Playercount Reaches", "teamcount", "When the amount of players on a team reaches...", false, resolvedEmojis.people)
triggerSelect:option("Callsign Used", "callsign", "When a player uses a callsign...", false, resolvedEmojis.channel)
triggerSelect:option("Troll Username Detected", "trollusername", "When a player has a troll username...", false, resolvedEmojis.avatar)
triggerSelect:option("Modcall Answered", "modcall", "When a moderator answers a modcall...", false, resolvedEmojis.modcall)
triggerSelect:option("Unanswered Modcalls Reaches", "modcallcount", "When the amount of unanswered modcalls reaches the specified amount...", false, resolvedEmojis.pings)
triggerSelect:option("Staff Kicks All", "kickall", "When a staff member kicks everyone...", false, resolvedEmojis.kick)
triggerSelect:option("Staff Bans All", "banall", "When an admin bans everyone...", false, resolvedEmojis.ban)
triggerSelect:option("Command Used", "cmdused", "When a staff member uses the specified command...", false, resolvedEmojis.settings)
triggerSelect:option("Shift Status Updated", "shiftUpdate", "When the shift status of a staff member updates...", false, resolvedEmojis.cycle)
triggerSelect:option("Interval", "interval", "Trigger this automation at an interval.", false, resolvedEmojis.clock)

local conditionSelect = discordia.SelectMenu({
	placeholder = "Add a condition to this automation...",
	id = "conditionselect",
	min_values = 0,
	max_values = 1,
	actionRow = 1
})

conditionSelect:option("Has Role", "role", "If the target user does have the specified role...", nil, resolvedEmojis.role)
conditionSelect:option("Does Not Have Role", "notrole", "If target user does not have the specified role...", nil, resolvedEmojis.role)
conditionSelect:option("In Region", "region", "If the target player is in the specified region...", nil, resolvedEmojis.map)
conditionSelect:option("Not in Region", "notregion", "If the target player is not in the specified region...", nil, resolvedEmojis.map)
conditionSelect:option("Team", "erlcTeam", "If the team of the player is...", nil, resolvedEmojis.flag)
conditionSelect:option("Session Status", "sessionStatus", "If the status of the session is...", nil, resolvedEmojis.game)
conditionSelect:option("Playercount", "playerCount", "If the amount of players in-game is...", nil, resolvedEmojis.people)
conditionSelect:option("Last Triggered", "lastTriggered", "If it has been x since this automation was last triggered...", nil, resolvedEmojis.clock)

local actionInserter = discordia.SelectMenu({
	placeholder = "Add an action to this automation...",
	id = "actionadd",
	min_values = 0,
	max_values = 1,
	actionRow = 1
})

actionInserter:option("Send a Command", "sendcommand", "Send a command to your in-game server.", false, resolvedEmojis.settings)
actionInserter:option("Send a Message", "sendmessage", "Send a message/embed to a channel.", false, resolvedEmojis.chat)
actionInserter:option("Session Start", "sessionstart", "Send the session start-up message.", false, resolvedEmojis.game)
actionInserter:option("Session Vote", "sessionvote", "Start an auto-starting session vote.", false, resolvedEmojis.game)
actionInserter:option("Session Shutdown", "sessionend", "Send the session shutdown message.", false, resolvedEmojis.game)
actionInserter:option("Delay", "delay", "Wait the specified amount of seconds before continuing.", false, resolvedEmojis.clock)
actionInserter:option("End Shifts", "endshifts", "End all active shifts.", false, resolvedEmojis.stop)
actionInserter:option("Re-check Conditions", "recheckconditions", "Re-check conditions, and do not continue if they are no longer met.", false, resolvedEmojis.reload)
actionInserter:option("Lock Channel", "lockchannel", "Lock a specified channel.", false, resolvedEmojis.lock)
actionInserter:option("Unlock Channel", "unlockchannel", "Unlock a specified channel.", false, resolvedEmojis.unlock)
actionInserter:option("Punish Player", "punish", "Issue the target player a punishment.", false, resolvedEmojis.moderate)

-----------------------------

----[[ Message Builder ]]----

local messageBuilder = discordia.Components()

local setChannelSelect = discordia.SelectMenu({
	id = "setchannel",
	type = "channel",
	actionRow = 1,
	placeholder = "Send to..."
})

messageBuilder:selectMenu(setChannelSelect)

local editContentButton = discordia.Button({
	id = "editcontent",
	style = "blurple",
	emoji = resolvedEmojis.edit,
	actionRow = 2,
	label = "Edit Content"
})

messageBuilder:button(editContentButton)

local editEmbedButton = discordia.Button({
	id = "editembed",
	style = "blurple",
	emoji = resolvedEmojis.edit,
	actionRow = 2,
	label = "Edit Embed"
})

messageBuilder:button(editEmbedButton)

local testButton = discordia.Button({
	id = "test",
	style = "blurple",
	emoji = resolvedEmojis.support,
	actionRow = 2,
	label = "Test Message"
})

messageBuilder:button(testButton)

local saveButton = discordia.Button({
	id = "save",
	style = "success",
	emoji = resolvedEmojis.yeswhite,
	actionRow = 3,
	label = "Save"
})

messageBuilder:button(saveButton)

local cancelButton = discordia.Button({
	id = "cancel",
	style = "danger",
	emoji = resolvedEmojis.nowhite,
	actionRow = 3,
	label = "Cancel"
})

messageBuilder:button(cancelButton)

-----------------------------

local liveryOptions = {
	{
		label = "Standard Livery",
		value = "Standard",
		description = "All standard liveries on all teams.",
		emoji = resolvedEmojis.draft
	},
	{
		label = "Custom Livery",
		value = "custom",
		description = "A custom livery uploaded to your server.",
		emoji = resolvedEmojis.paintbrush
	}
}

-----------------------------

local teamOptions = {
	{
		label = "Any",
		value = "any",
		description = "Any team.",
		emoji = resolvedEmojis.flag
	},
	{
		label = "Civilian",
		value = "Civilian",
		description = "The civilian team.",
		emoji = resolvedEmojis.person
	},
	{
		label = "Sheriff",
		value = "Sheriff",
		description = "The sheriff team.",
		emoji = resolvedEmojis.Sheriff
	},
	{
		label = "Firefighter",
		value = "Fire",
		description = "The firefighter team.",
		emoji = resolvedEmojis.Fire
	},
	{
		label = "Police",
		value = "Police",
		description = "The police team.",
		emoji = resolvedEmojis.Police
	},
	{
		label = "DOT",
		value = "DOT",
		description = "The DOT team.",
		emoji = resolvedEmojis.DOT
	},
	{
		label = "Jail",
		value = "Jail",
		description = "Civilians that got arrested.",
		emoji = resolvedEmojis.Criminal
	}
}

-----------------------------

local teamOptionsForConditions = {
	{
		label = "Civilian",
		value = "Civilian",
		description = "The civilian team.",
		emoji = resolvedEmojis.person
	},
	{
		label = "Sheriff",
		value = "Sheriff",
		description = "The sheriff team.",
		emoji = resolvedEmojis.Sheriff
	},
	{
		label = "Firefighter",
		value = "Fire",
		description = "The firefighter team.",
		emoji = resolvedEmojis.Fire
	},
	{
		label = "Police",
		value = "Police",
		description = "The police team.",
		emoji = resolvedEmojis.Police
	},
	{
		label = "DOT",
		value = "DOT",
		description = "The DOT team.",
		emoji = resolvedEmojis.DOT
	},
	{
		label = "Jail",
		value = "Jail",
		description = "Civilians that got arrested.",
		emoji = resolvedEmojis.Criminal
	}
}

-----------------------------

local sessionOptions = {
	{
		label = "Active",
		value = "active",
		description = "A session is active.",
		emoji = resolvedEmojis.play
	},
	{
		label = "Shutdown",
		value = "shutdown",
		description = "A session is shutdown.",
		emoji = resolvedEmojis.power
	},
	{
		label = "Vote",
		value = "vote",
		description = "A session vote is being held.",
		emoji = resolvedEmojis.list
	},
	{
		label = "Staff Vote",
		value = "staffvote",
		description = "A session staff vote is being held.",
		emoji = resolvedEmojis.quickfix
	}
}

-----------------------------

local comparisonOperatorsOptions = {
	{
		label = "Equals",
		value = "equal",
		description = "The playercount is equal to...",
		emoji = resolvedEmojis.equals
	},
	{
		label = "Not Equal",
		value = "notequal",
		description = "The playercount is not equal to...",
		emoji = resolvedEmojis.notequal
	},
	{
		label = "Less or Equals",
		value = "lessorequal",
		description = "The playercount is less than or equal to...",
		emoji = resolvedEmojis.lessorequal
	},
	{
		label = "Greater or Equals",
		value = "greaterorequal",
		description = "The playercount is greater than or equal to...",
		emoji = resolvedEmojis.greaterorequal
	},
	{
		label = "Less",
		value = "less",
		description = "The playercount is less than...",
		emoji = resolvedEmojis.less
	},
	{
		label = "Greater",
		value = "greater",
		description = "The playercount is greater than...",
		emoji = resolvedEmojis.greater
	}
}

-----------------------------

local shiftStatusOptions = {
	{
		label = "Any",
		value = "any",
		description = "Trigger the automation on any shift status change.",
		emoji = resolvedEmojis.flag
	},
	{
		label = "On Shift",
		value = "on",
		description = "When a staff member's shift changes to on shift.",
		emoji = resolvedEmojis.play
	},
	{
		label = "On Pause",
		value = "break",
		description = "When a staff member's shift changes to on pause.",
		emoji = resolvedEmojis.pause
	},
	{
		label = "Off Shift",
		value = "off",
		description = "When a staff member's shift changes to off shift.",
		emoji = resolvedEmojis.stop
	}
}

-----------------------------

local function resolveCar(input)
	if type(input) ~= "string" then
		return input
	end

	input = input:match( "^%s*(.-)%s*$" )
	local number, text = input:match("^(%d+)%s+(.+)$")
	if number and text then
		return text .. " " .. number
	else
		return input
	end
end

-----------------------------
local allowedConditionsForAllTriggersWithATarget = {
	"role",
	"notrole",
	"region",
	"notregion",
	"erlcTeam"
}

local allowedActionsForAllTriggersWithATarget = {
	"punish"
}

local triggerOptions = {
	["playerjoin"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Player",
				value = "player",
				description = "The player that joined the server.",
				emoji = resolvedEmojis.person
			}
		}
	},
	["playerleave"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Player",
				value = "player",
				description = "The player that left the server.",
				emoji = resolvedEmojis.person
			}
		}
	},
	["playerkill"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Killed",
				value = "killed",
				description = "The player that got killed.",
				emoji = resolvedEmojis.swords
			},
			{
				label = "Killer",
				value = "killer",
				description = "The player that killed the other player.",
				emoji = resolvedEmojis.swords
			}
		}
	},
	["emergencycall"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Player",
				value = "player",
				description = "The player that called emergency services.",
				emoji = resolvedEmojis.person
			}
		}
	},
	["modcall"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Player",
				value = "player",
				description = "The player that called a moderator.",
				emoji = resolvedEmojis.person
			},
			{
				label = "Moderator",
				value = "mod",
				description = "The moderator that answered the modcall.",
				emoji = resolvedEmojis.moderate
			}
		}
	},
	["kickall"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Staff Member",
				value = "staff",
				description = "The staff member that kicked everyone.",
				emoji = resolvedEmojis.moderate
			}
		}
	},
	["banall"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Staff Member",
				value = "staff",
				description = "The staff member that banned everyone.",
				emoji = resolvedEmojis.moderate
			}
		}
	},
	["vehiclespawn"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Player",
				value = "player",
				description = "The player using the vehicle.",
				emoji = resolvedEmojis.person
			}
		}
	},
	["liveryused"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Player",
				value = "player",
				description = "The player using the livery.",
				emoji = resolvedEmojis.person
			}
		}
	},
	["team"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Player",
				value = "player",
				description = "The player that joined the team.",
				emoji = resolvedEmojis.person
			}
		}
	},
	["regionentered"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Player",
				value = "player",
				description = "The player that entered the region.",
				emoji = resolvedEmojis.person
			}
		}
	},
	["regionexited"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Player",
				value = "player",
				description = "The player that exited the region.",
				emoji = resolvedEmojis.person
			}
		}
	},
	["cmdused"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Staff",
				value = "staff",
				description = "The staff member has used the command.",
				emoji = resolvedEmojis.support
			}
		}
	},
	["avatar"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Player",
				value = "player",
				description = "The player with the unrealistic avatar.",
				emoji = resolvedEmojis.avatar
			}
		}
	},
	["plate"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Player",
				value = "player",
				description = "The player using the plate.",
				emoji = resolvedEmojis.person
			}
		}
	},
	["callsign"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Player",
				value = "player",
				description = "The player using the callsign.",
				emoji = resolvedEmojis.person
			}
		}
	},
	["killedin"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Killer",
				value = "killer",
				description = "The player that killed the other player.",
				emoji = resolvedEmojis.swords
			}
		}
	},
	["shiftUpdate"] = {
		allowedconditions = allowedConditionsForAllTriggersWithATarget,
		allowedactions = allowedActionsForAllTriggersWithATarget,
		targetOptions = {
			{
				label = "Staff",
				value = "staff",
				description = "The staff member that the shift status updated for.",
				emoji = resolvedEmojis.support
			}
		}
	}
}

-----------------------------

local vars = {
	["playerjoin"] = emojis.right .. " **`{player.name}`:** The name of the player that joined.\n" .. emojis.right .. " **`{player.id}`:** The ID of the player that joined.\n" .. emojis.right .. " **`{player.profile}`:** The link to the player's profile that joined.\n" .. emojis.right .. " **`{player.hyperlink}`:** The hyperlink to the player's profile that joined.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the player joined.",
	["playerleave"] = emojis.right .. " **`{player.name}`:** The name of the player that left.\n" .. emojis.right .. " **`{player.id}`:** The ID of the player that left.\n" .. emojis.right .. " **`{player.profile}`:** The link to the player's profile that left.\n" .. emojis.right .. " **`{player.hyperlink}`:** The hyperlink to the player's profile that left.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the player left.",
	["playerkill"] = emojis.right .. " **`{killed.name}`:** The name of the player that got killed.\n" .. emojis.right .. " **`{killed.id}`:** The ID of the player that got killed.\n" .. emojis.right .. " **`{killed.profile}`:** The profile link to the killed player's profile.\n" .. emojis.right .. " **`{killed.hyperlink}`:** The hyperlink to the killed player's profile.\n" .. emojis.right .. " **`{killer.name}`:** The name of the killer.\n" .. emojis.right .. " **`{killer.id}`:** The ID of the killer.\n" .. emojis.right .. " **`{killer.profile}`:** The profile link to the killer's profile.\n" .. emojis.right .. " **`{killer.hyperlink}`:** The hyperlink to the killer's profile.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the player was killed.",
	["emergencycall"] = emojis.right .. " **`{call.team}`:** The emergency service that was called.\n" .. emojis.right .. " **`{call.number}`:** The call number.\n" .. emojis.right .. " **`{call.description}`:** The description of the call.\n" .. emojis.right .. " **`{call.position.x}`:** The X coordinate of the call's position.\n" .. emojis.right .. " **`{call.position.z}`:** The Z coordinate of the call's position.\n" .. emojis.right .. " **`{call.position.descriptor}`:** The descriptor of the call's position.\n" .. emojis.right .. " **`{caller.name}`:** The name of the player who called emergency services.\n" .. emojis.right .. " **`{caller.id}`:** The ID of the player who called emergency services.\n" .. emojis.right .. " **`{caller.profile}`:** The profile link to the caller's profile.\n" .. emojis.right .. " **`{caller.hyperlink}`:** The hyperlink to the caller's profile.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the emergency services were called.",
	["modcall"] = emojis.right .. " **`{caller.name}`:** The name of the player who called !mod.\n" .. emojis.right .. " **`{caller.id}`:** The ID of the player who called !mod.\n" .. emojis.right .. " **`{caller.profile}`:** The profile link to the player's profile that called !mod.\n" .. emojis.right .. " **`{caller.hyperlink}`:** The hyperlink to the player who called !mod's profile.\n" .. emojis.right .. " **`{moderator.name}`:** The name of the moderator who answered the modcall.\n" .. emojis.right .. " **`{moderator.id}`:** The ID of the moderator who answered the modcall.\n" .. emojis.right .. " **`{moderator.profile}`:** The profile link of the moderator who answered the mod call.\n" .. emojis.right .. " **`{moderator.hyperlink}`:** The hyperlink to the moderator's profile.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the modcall was answered.",
	["kickall"] = emojis.right .. " **`{staff.name}`:** The name of the staff member.\n" .. emojis.right .. " **`{staff.id}`:** The ID of the staff member.\n" .. emojis.right .. " **`{staff.profile}`:** The profile link to the staff member's profile.\n" .. emojis.right .. " **`{staff.hyperlink}`:** The hyperlink to the staff member's profile.\n" .. emojis.right .. " **`{kickedUsers.ids}`:** A string of all ids of the players that got kicked.\n" .. emojis.right .. " **`{kickedUsers.names}`:** A string of all names of the the players that got kicked.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the staff kicked all.",
	["banall"] = emojis.right .. " **`{staff.name}`:** The name of the staff member.\n" .. emojis.right .. " **`{staff.id}`:** The ID of the staff member.\n" .. emojis.right .. " **`{staff.profile}`:** The profile link to the staff member's profile.\n" .. emojis.right .. " **`{staff.hyperlink}`:** The hyperlink to the staff member's profile.\n" .. emojis.right .. " **`{bannedUsers.ids}`:** A string of all ids of the players that got banned.\n" .. emojis.right .. " **`{bannedUsers.names}`:** A string of all names of the the players that got banned.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the admin banned all.",
	["vehiclespawn"] = emojis.right .. " **`{vehicle.name}`:** The name of the vehicle spawned.\n" .. emojis.right .. " **`{vehicle.make}`:** The make of the vehicle spawned.\n" .. emojis.right .. " **`{vehicle.model}`:** The model of the vehicle spawned.\n" .. emojis.right .. " **`{vehicle.year}`:** The year of the vehicle spawned.\n" .. emojis.right .. " **`{vehicle.plate}`:** The plate of the vehicle spawned.\n" .. emojis.right .. " **`{vehicle.livery}`:** The livery of the vehicle spawned.\n" .. emojis.right .. " **`{vehicle.color}`:** The color of the vehicle spawned.\n" .. emojis.right .. " **`{player.name}`:** The name of the player that is using the vehicle.\n" .. emojis.right .. " **`{player.id}`:** The ID of the player that is using the vehicle.\n" .. emojis.right .. " **`{player.profile}`:** The profile link of the player that is using the vehicle.\n" .. emojis.right .. " **`{player.hyperlink}`:** The hyperlink to the player that is using the vehicle's profile.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the player spawned the vehicle.",
	["liveryused"] = emojis.right .. " **`{vehicle.name}`:** The name of the vehicle using the livery.\n" .. emojis.right .. " **`{vehicle.make}`:** The make of the vehicle using the livery.\n" .. emojis.right .. " **`{vehicle.model}`:** The model of the vehicle using the livery.\n" .. emojis.right .. " **`{vehicle.year}`:** The year of the vehicle using the livery.\n" .. emojis.right .. " **`{vehicle.plate}`:** The plate of the vehicle using the livery.\n" .. emojis.right .. " **`{vehicle.livery}`:** The exact livery the vehicle used.\n" .. emojis.right .. " **`{vehicle.color}`:** The color of the vehicle using the livery.\n" .. emojis.right .. " **`{player.name}`:** The name of the player that is using the vehicle.\n" .. emojis.right .. " **`{player.id}`:** The ID of the player that is using the vehicle.\n" .. emojis.right .. " **`{player.profile}`:** The profile link of the player that is using the vehicle.\n" .. emojis.right .. " **`{player.hyperlink}`:** The hyperlink to the player that is using the vehicle's profile.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the player used the livery.",
	["team"] = emojis.right .. " **`{player.name}`:** The name of the player that joined the team.\n" .. emojis.right .. " **`{player.id}`:** The ID of the player that joined the team.\n" .. emojis.right .. " **`{player.profile}`:** The link to the player's profile that joined the team.\n" .. emojis.right .. " **`{player.hyperlink}`:** The hyperlink to the player's profile that joined the team.\n" .. emojis.right .. " **`{player.team}`:** The team that the player joined.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the player joined the team.",
	["any"] = emojis.right .. " **`{team}`:** The team that reached the playercount threshold.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the team met the playercount threshold.",
	["Civilian"] = emojis.right .. " **`{team}`:** The team that reached the playercount threshold.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the team met the playercount threshold.",
	["Fire"] = emojis.right .. " **`{team}`:** The team that reached the playercount threshold.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the team met the playercount threshold.",
	["Sheriff"] = emojis.right .. " **`{team}`:** The team that reached the playercount threshold.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the team met the playercount threshold.",
	["Police"] = emojis.right .. " **`{team}`:** The team that reached the playercount threshold.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the team met the playercount threshold.",
	["DOT"] = emojis.right .. " **`{team}`:** The team that reached the playercount threshold.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the team met the playercount threshold.",
	["Jail"] = emojis.right .. " **`{team}`:** The team that reached the playercount threshold.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the team met the playercount threshold.",
	["regionentered"] = emojis.right .. " **`{player.name}`:** The name of the player that entered the region.\n" .. emojis.right .. " **`{player.id}`:** The ID of the player that entered the region.\n" .. emojis.right .. " **`{player.profile}`:** The profile link to the player that entered the region.\n" .. emojis.right .. " **`{player.hyperlink}`:** The hyperlink to the player that entered the region.\n" .. emojis.right .. " **`{region.name}`:** The region's name.\n" .. emojis.right .. " **`{region.area}`:** The region's area in studs.\n" .. emojis.right .. " **`{region.points}`:** The amount of points the region has.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the region was entered.",
	["regionexited"] = emojis.right .. " **`{player.name}`:** The name of the player that exited the region.\n" .. emojis.right .. " **`{player.id}`:** The ID of the player that exited the region.\n" .. emojis.right .. " **`{player.profile}`:** The profile link to the player that exited the region.\n" .. emojis.right .. " **`{player.hyperlink}`:** The hyperlink to the player that exited the region.\n" .. emojis.right .. " **`{region.name}`:** The region's name.\n" .. emojis.right .. " **`{region.area}`:** The region's area in studs.\n" .. emojis.right .. " **`{region.points}`:** The amount of points the region has.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the region was exited.",
	["cmdused"] = emojis.right .. " **`{staff.name}`:** The name of the staff member that used the command.\n" .. emojis.right .. " **`{staff.id}`:** The ID of the staff member that used the command.\n" .. emojis.right .. " **`{staff.profile}`:** The profile link to the staff member that used the command.\n" .. emojis.right .. " **`{staff.hyperlink}`:** The hyperlink to the staff member that used the command.\n" .. emojis.right .. " **`{fullcmd}`:** The full command that the staff member used.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the command was used.",
	["trollusername"] = emojis.right .. " **`{player.name}`:** The name of the player with a troll username.\n" .. emojis.right .. " **`{player.id}`:** The ID of the player with a troll username.\n" .. emojis.right .. " **`{player.profile}`:** The link to the player's profile with a troll username.\n" .. emojis.right .. " **`{player.hyperlink}`:** The hyperlink to the player's profile with a troll username.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the troll username was detected.",
	["plate"] = emojis.right .. " **`{vehicle.name}`:** The name of the vehicle that used the plate.\n" .. emojis.right .. " **`{vehicle.make}`:** The make of the vehicle that used the plate.\n" .. emojis.right .. " **`{vehicle.model}`:** The model of the vehicle that used the plate.\n" .. emojis.right .. " **`{vehicle.year}`:** The year of the vehicle that used the plate.\n" .. emojis.right .. " **`{vehicle.plate}`:** The exact plate the vehicle used.\n" .. emojis.right .. " **`{vehicle.livery}`:** The livery of the vehicle that used the plate.\n" .. emojis.right .. " **`{vehicle.color}`:** The color of the vehicle that used the plate.\n" .. emojis.right .. " **`{player.name}`:** The name of the player that used the plate.\n" .. emojis.right .. " **`{player.id}`:** The ID of the player that is using the plate.\n" .. emojis.right .. " **`{player.profile}`:** The link to the player using the plate's profile.\n" .. emojis.right .. " **`{player.hyperlink}`:** The hyperlink to the player using the plate's profile.\n" .. emojis.right .. " **`{player.team}`:** The player's team.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the plate was used.",
	["callsign"] = emojis.right .. " **`{player.name}`:** The name of the player that used the callsign.\n" .. emojis.right .. " **`{player.id}`:** The ID of the player that is using the callsign.\n" .. emojis.right .. " **`{player.profile}`:** The link to the player using the callsign's profile.\n" .. emojis.right .. " **`{player.hyperlink}`:** The hyperlink to the player using the callsign's profile.\n" .. emojis.right .. " **`{player.team}`:** The player's team.\n" .. emojis.right .. " **`{player.callsign}`:** The exact callsign that was used.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the callsign was used.",
	["killedin"] = emojis.right .. " **`{killer.name}`:** The name of the killer.\n" .. emojis.right .. " **`{killer.id}`:** The ID of the killer.\n" .. emojis.right .. " **`{killer.profile}`:** The profile link to the killer's profile.\n" .. emojis.right .. " **`{killer.hyperlink}`:** The hyperlink to the killer's profile.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when it was detected.",
	["shiftUpdate"] = emojis.right .. " **`{staff.discord.*}`:** Includes `.name`, `.username`, `.id`, `.mention`, `.avatar`.\n" .. emojis.right .. " **`{staff.roblox.*}`:** Includes `.display`, `.name`, `.id`, `.avatar`, `.description`, `.banned`, `.verified`, `.profile`, `.hyperlink`. Only available if user is linked with Ducky.\n" .. emojis.right .. " **`{shift.status}`:** The current status of their shift.\n" .. emojis.right .. " **`{shift.started}`:** The timestamp of when their shift started.\n" .. emojis.right .. " **`{shift.ended}`:** The timestamp of when their shift ended.\n" .. emojis.right .. " **`{shift.elapsed}`:** That total elapsed time of their shift.\n" .. emojis.right .. " **`{shift.punishments}`:** The amount of punishments they logged during their shift.\n" .. emojis.right .. " **`{shift.commands}`:** The amount of in-game commands they used during their shift.\n" .. emojis.right .. " **`{shift.pauses}`:** The amount of pauses they made during their shift.\n" .. emojis.right .. " **`{shift.pausetime}`:** The total elapsed time paused during their shift.\n" .. emojis.right .. " **`{shift.type}`:** The shift type they used during their shift.\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the shift status updated.",
	["manual"] = emojis.right .. " **`{executor.discord.*}`:** Includes `.name`, `.username`, `.id`, `.mention`, `.avatar`.\n" .. emojis.right .. " **`{executor.roblox.*}`:** Includes `.display`, `.name`, `.id`, `.avatar`, `.description`, `.banned`, `.verified`, `.profile`, `.hyperlink`. Only available if user is linked with Ducky.",
	["interval"] = emojis.right .. " **`{executor.discord.*}`:** Includes `.name`, `.username`, `.id`, `.mention`, `.avatar`.\n" .. emojis.right .. " **`{executor.roblox.*}`:** Includes `.display`, `.name`, `.id`, `.avatar`, `.description`, `.banned`, `.verified`, `.profile`, `.hyperlink`. Only available if user is linked with Ducky."
}

-----------------------------

local customArgsOrder = {"arg1", "arg2", "arg3", "arg4", "arg5"}

-----------------------------

local savingAutomations = {}

return {
	name = "automations",
	description = "Use Ducky's automations module.",
	aliases = {
		"ams",
		"autos",
		"am"
	},
	subcommands = {
		"create",
		list = {
			"view"
		},
		"delete",
		run = {
			"trigger"
		},
		"edit"
	},
	category = "ERLC",
	slashCommand = slashCommand,
	requiredPermissions = {
		"SETUP"
	},
	hybridCallback = function(interaction, args, command, subcmd)
		local config = sqldb:get(interaction.guild.id) or {}

		local function requireAPIKey(ia)
			if not config.apikey then
				return false, ia:fail("This feature requires for you to link your ERLC API Key with Ducky via the " .. emojis.game .. " **ERLC Integration** page in `/setup`.", nil, true)
			else
				return true
			end
		end

		local automationCount = table.count(config.automations or {})
		local plus = sqldb:plusGuild(interaction.guild)
		local maxAutomationCount = (plus and featureLimits.automations.plus) or featureLimits.automations.normal

		if subcmd == "create" or subcmd == "edit" then
			if not hasPermission(interaction.member, "MANAGE_SERVER", config, interaction) then
				return
			end

			if subcmd == "create" and checkLimit(interaction, "automations", plus, automationCount, "automations") then
				return
			elseif subcmd == "edit" and checkLimit(interaction, "automations", plus, automationCount, "automations", true) then
				return
			end

			local automation

			if subcmd == "edit" then
				local id = (args and args.automation) or (args and table.remove(args, 1) and args[1] and table.concat(args, " "))

				if not id then
					return interaction:fail("You must provide a valid automation name or ID.", nil, true)
				end

				config.automations = config.automations or {}

				for i, ams in pairs(config.automations) do
					if ams.id == tonumber(id) then
						automation = ams
						break
					elseif ams.name:lower() == id:lower() then
						automation = ams
						break
					end
				end

				if not automation then
					return interaction:fail("An automation with the name or ID of `" .. tostring(id) .. "` was not found.", nil, true)
				end
			end

			automation = automation or {
				trigger = nil,
				actions = {},
				name = nil,
				author = interaction.user.id,
                lastTriggered = realtime()
			}

			local ab = nil

			local function updateBuilder()
				local actionsstr = ""
				for i, v in pairs(automation.actions) do
					actionsstr = actionsstr .. emojis.space .. emojis.right .. " " .. v.name .. "\n"
				end

				if table.count(automation.actions) == 0 then
					actionsstr = actionsstr .. emojis.space .. emojis.right .. " No actions added"
				end

				if automation.trigger and automation.condition then
					local splitTrigger = string.split(automation.trigger.value, ":")
					local triggerId = splitTrigger and splitTrigger[1]

					local splitCondition = string.split(automation.condition.value, ":")
					local conditionId = splitCondition[1]

					if not triggerOptions[triggerId] or not table.find(triggerOptions[triggerId].allowedconditions, conditionId) then
						automation.condition = nil
					end
				else
					automation.condition = nil
				end

				local trigger = (automation.trigger and automation.trigger.name) or "No trigger selected"

				if automation.customization and not next(automation.customization) then
					automation.customization = nil
				end

				local customization = automation.customization

				local automationBuilder = discordia.Components()

				local editOptions = {}

				table.insert(editOptions, {
					label = "Edit Name",
					value = "name",
					description = "Edit this automation's identifiable name.",
					emoji = resolvedEmojis.rename
				})

				if automation.disabled then
					table.insert(editOptions, {
						label = "Enable",
						value = "toggle",
						description = "This automation is currently disabled.",
						emoji = resolvedEmojis.off
					})
				else
					table.insert(editOptions, {
						label = "Disable",
						value = "toggle",
						description = "This automation is currently enabled.",
						emoji = resolvedEmojis.on
					})
				end

				table.insert(editOptions, {
					label = "Results Channel",
					value = "resultschannel",
					description = "When the automation is ran, the result will be posted in that channel.",
					emoji = resolvedEmojis.channel
				})

				if automation.trigger and automation.trigger.value and automation.trigger.value == "manual" then
					table.insert(editOptions, {
						label = "Customize",
						value = "customize",
						description = "Edit the required role, custom variables, and custom slash command.",
						emoji = resolvedEmojis.livery
					})
				end

				table.insert(editOptions, {
					label = "Edit Trigger",
					value = "trigger",
					description = "Choose when or how this automation gets triggered.",
					emoji = resolvedEmojis.contributor
				})
				table.insert(editOptions, {
					label = "Add Condition",
					value = "addcondition",
					description = "Choose a condition that must be met before this automation runs.",
					emoji = resolvedEmojis.plus
				})
				table.insert(editOptions, {
					label = "Remove Condition",
					value = "removecondition",
					description = "Choose a condition that must be met before this automation runs.",
					emoji = resolvedEmojis.minus
				})
				table.insert(editOptions, {
					label = "Add Action",
					value = "addaction",
					description = "Add an action to this automation.",
					emoji = resolvedEmojis.plus
				})
				table.insert(editOptions, {
					label = "Edit Action",
					value = "editaction",
					description = "Edit an action in this automation.",
					emoji = resolvedEmojis.edit
				})
				table.insert(editOptions, {
					label = "Remove Action",
					value = "removeaction",
					description = "Remove an action from this automation.",
					emoji = resolvedEmojis.minus
				})
				table.insert(editOptions, {
					label = "Export Automation",
					value = "export",
					description = "Export this automation.",
					emoji = resolvedEmojis.export
				})
				table.insert(editOptions, {
					label = "Import Automation",
					value = "import",
					description = "Import an automation.",
					emoji = resolvedEmojis.import
				})

				local editSelect = discordia.SelectMenu({
					placeholder = "Edit this automation...",
					id = "edit",
					options = editOptions,
					actionRow = 1,
					min_values = 0,
					max_values = 1
				})

				automationBuilder:selectMenu(editSelect)

				local createButton = discordia.Button({
					label = "Save",
					emoji = resolvedEmojis.yeswhite,
					id = "create",
					style = "success",
					actionRow = 2
				})

				automationBuilder:button(createButton)

				local cancelButton = discordia.Button({
					label = "Cancel",
					emoji = resolvedEmojis.nowhite,
					id = "cancel",
					style = "danger",
					actionRow = 2
				})

				automationBuilder:button(cancelButton)

				local variablesButton = discordia.Button({
					label = "Variables",
					emoji = resolvedEmojis.json,
					id = "vars",
					style = "secondary",
					actionRow = 2
				})

				automationBuilder:button(variablesButton)

				local emb = {
					title = emojis.automation .. " Automation Builder",
					description =
					((automation.disabled and "-# " .. emojis.power .. " This automation is currently **disabled**.") or "")
					.. "\n" .. emojis.bulletPoint .. " **Name:** " .. (automation.name or emojis.fail)
					.. "\n" .. emojis.bulletPoint .. " **Results Channel:** " .. (automation.resultschannel and "<#" .. automation.resultschannel .. ">" or emojis.fail) .. "\n"
					.. ((customization and
						emojis.bulletPoint .. " **Customization:** "
							.. "\n" .. emojis.bulletPointSpacing .. emojis.bulletPoint .. " **Required Role:** " .. ((customization.requiredRole and "<@&" .. customization.requiredRole .. ">") or emojis.fail)
							.. "\n" .. emojis.bulletPointSpacing .. emojis.bulletPoint .. " **Custom Arguments:** "
								.. (customization.customArgs and next(customization.customArgs) and "\n" .. emojis.bulletPointSpacing2 .. emojis.bulletPoint .. " " .. table.concatFn(customArgsOrder, "\n" .. emojis.bulletPointSpacing2 .. emojis.bulletPoint .. " ", function(orderedArg, i)
									local arg = customization.customArgs[orderedArg]

									if arg then
										return "**" .. tostring(i) .. ":** `{" .. arg.name .. "}`" .. ((arg.required and " (" .. emojis.lock .. ")") or "")
									else
										return ""
									end
								end) or emojis.fail)
							.. "\n" .. emojis.bulletPointSpacing .. emojis.bulletPoint .. " **Custom Slash Command:** " 
								.. ((customization.customSlashCommand and ((customization.customSlashCommand.id and "</" .. customization.customSlashCommand.name .. ":" .. customization.customSlashCommand.id .. ">") or ("`/" .. customization.customSlashCommand.name .. "`"))) or emojis.fail)
					.. "\n") or "")
					.. emojis.bulletPoint .. " **Logic:**" .. "\n" .. emojis.bulletPointSpacing .. emojis.bulletPoint .. " " .. trigger .. ((automation.conditions and table.count(automation.conditions) > 0 and "\n" .. emojis.bulletPointSpacing .. emojis.bulletPoint .. " " .. table.concatFn(automation.conditions, "\n" .. emojis.bulletPointSpacing .. emojis.bulletPoint .. " ", function(c)
						return c.name
					end)) or "") .. "\n" .. emojis.bulletPointSpacing2 .. emojis.bulletPoint .. " " .. ((automation.actions and table.count(automation.actions) > 0 and table.concatFn(automation.actions, "\n" .. emojis.bulletPointSpacing2 .. emojis.bulletPoint .. " ", function(a)
						return a.name
					end)) or "No actions added"),
					color = colors.yellow
				}

				if type(ab) == "table" then
					return ab:update({
						embed = emb,
						components = automationBuilder:raw()
					})
				else
					ab = interaction:reply({
						embed = emb,
						components = automationBuilder:raw()
					})
					return
				end
			end

			updateBuilder()

			onComp(ab, nil, nil, interaction.user.id, false, function(ia)
				local id = ia.data.custom_id
				local selection = ia.data.values and ia.data.values[1]

				if id == "edit" and selection == "trigger" then
					local r = ia:reply({
						components = discordia.Components({
							triggerSelect
						}):raw()
					}, true)

					onComp(r, nil, nil, interaction.user.id, true, function(ria)
						local selection = ria.data and ria.data.values and ria.data.values[1]

						ia:deleteReply(r.id)

						if selection == "playerjoin" then
							if not requireAPIKey(ria) then
								return
							end

							automation.trigger = {
								name = "When a player joins the in-game server...",
								value = "playerjoin"
							}
							updateBuilder()
							ria:updateDeferred(true)
						elseif selection == "playerleave" then
							if not requireAPIKey(ria) then
								return
							end

							automation.trigger = {
								name = "When a player leaves the in-game server...",
								value = "playerleave"
							}
							updateBuilder()
							ria:updateDeferred(true)
						elseif selection == "playercount" then
							if not requireAPIKey(ria) then
								return
							end

							ask(ria, "When the playercount reaches...", "At what playercount should this be triggered at?", "fgsfugdg", "dfusfgy78fdgy", "short", true, nil, function(_, mia, response)
								if mia and response then
									if (not tonumber(response)) or (tonumber(response) < 0) or (tonumber(response) > 50) then
										updateBuilder()
										return mia:fail("The response must be a number between 0 and 50.", nil, true)
									end

									automation.trigger = {
										name = "When the playercount reaches " .. tonumber(response) .. "...",
										value = "playercount:" .. tonumber(response)
									}
									updateBuilder()
									mia:updateDeferred(true)
								end
							end)
						elseif selection == "playercountg" then
							if not requireAPIKey(ria) then
								return
							end

							ask(ria, "When the playercount rises above...", "At above what playercount should this be triggered at?", "dfuygysdfg", "dfsiyg", "short", true, nil, function(_, mia, response)
								if mia and response then
									if (not tonumber(response)) or (tonumber(response) < 0) or (tonumber(response) > 49) then
										updateBuilder()
										return mia:fail("The response must be a number between 0 and 49.", nil, true)
									end

									automation.trigger = {
										name = "When the playercount rises above " .. tonumber(response) .. "...",
										value = "playercountg:" .. tonumber(response)
									}
									updateBuilder()
									mia:updateDeferred(true)
								end
							end)
						elseif selection == "playercountl" then
							if not requireAPIKey(ria) then
								return
							end

							ask(ria, "When the playercount drops below...", "At below what playercount should this be triggered at?", "dfuygysdfg", "dfsiyg", "short", true, nil, function(_, mia, response)
								if mia and response then
									if (not tonumber(response)) or (tonumber(response) < 1) or (tonumber(response) > 50) then
										updateBuilder()
										return mia:fail("The response must be a number between 1 and 50.", nil, true)
									end

									automation.trigger = {
										name = "When the playercount drops below " .. tonumber(response) .. "...",
										value = "playercountl:" .. tonumber(response)
									}
									updateBuilder()
									mia:updateDeferred(true)
								end
							end)
						elseif selection == "playerkill" then
							if not requireAPIKey(ria) then
								return
							end

							automation.trigger = {
								name = "When a player is killed...",
								value = "playerkill"
							}
							updateBuilder()
							ria:updateDeferred(true)
						elseif selection == "emergencycall" then
							if not requireAPIKey(ria) then
								return
							end

							automation.trigger = {
								name = "When a player calls emergency services...",
								value = "emergencycall"
							}
							updateBuilder()
							ria:updateDeferred(true)
						elseif selection == "modcall" then
							if not requireAPIKey(ria) then
								return
							end

							automation.trigger = {
								name = "When a modcall gets answered...",
								value = "modcall"
							}
							updateBuilder()
							ria:updateDeferred(true)
						elseif selection == "modcallcount" then
							if not requireAPIKey(ria) then
								return
							end

							ask(ria, "The amount of unanswered modcalls reaches...", "At how many unanswered modcalls should the automation be triggered?", "fgsfugdg", "dfusfgy78fdgy", "short", true, nil, function(_, mia, response)
								if mia and response then
									if (not tonumber(response)) or (tonumber(response) < 0) or (tonumber(response) > 20) then
										updateBuilder()
										return mia:fail("The response must be a number between 0 and 20.", nil, true)
									end

									automation.trigger = {
										name = "When the amount of unanswered modcalls reaches " .. tonumber(response) .. "...",
										value = "modcallcount:" .. tonumber(response)
									}
									updateBuilder()
									mia:updateDeferred(true)
								end
							end)
						elseif selection == "kickall" then
							if config.erlckickbanchannel then
								automation.trigger = {
									name = "When a staff member kicks everyone...",
									value = "kickall"
								}

								ria:updateDeferred(true)
							else
								ria:fail("An **ERLC Kick/Ban Logs Channel** has not been selected in the " .. emojis.game .. " **ERLC Integration** `/setup` page.", nil, true)
							end

							updateBuilder()
						elseif selection == "banall" then
							if config.erlckickbanchannel then
								automation.trigger = {
									name = "When an admin bans everyone...",
									value = "banall"
								}

								ria:updateDeferred(true)
							else
								ria:fail("An **ERLC Kick/Ban Logs Channel** has not been selected in the " .. emojis.game .. " **ERLC Integration** `/setup` page.", nil, true)
							end

							updateBuilder()
						elseif selection == "vehiclespawn" then
							if not requireAPIKey(ria) then
								return
							end

							ask(ria, "When these vehicle(s) are being used...", "vehicle1,vehicle2,vehicle3,vehicle4", "dfuygysdfg", "dfsiyg", "short", true, nil, function(_, mia, response)
								if mia and response then
									local vehicleNames = {}
									for name in response:gmatch("[^,]+") do
										table.insert(vehicleNames, resolveCar(name))
									end

									if table.count(vehicleNames) > 35 then
										mia:fail("You cannot input more than 35 vehicles.", nil, true)
									else
										local displayNames = table.concat(vehicleNames, "`, `")
										local valueNames = table.concat(vehicleNames, ",")

										automation.trigger = {
											name = "When the vehicle(s) `" .. displayNames .. "` are being used...",
											value = "vehiclespawn:" .. valueNames
										}
									end

									updateBuilder()
									mia:updateDeferred(true)
								end
							end)
						elseif selection == "liveryused" then
							if not requireAPIKey(ria) then
								return
							end

							optionsSelect(ria, "Select Livery", function(opt, cia, r)
								if opt == "Standard" then
									automation.trigger = {
										name = "When a standard livery is being used...",
										value = "liveryused:" .. opt
									}
									updateBuilder()
									cia:updateDeferred(true)
								elseif opt == "custom" then
									ask(cia, "When the following livery is being used...", "Type the exact name of the livery!", "dfuygysdfg", "dfsiyg", "short", true, nil, function(_, mia, response)
										if mia and response then
											automation.trigger = {
												name = "When the livery `" .. response .. "` is being used...",
												value = "liveryused:" .. response
											}
											updateBuilder()
											mia:updateDeferred(true)
										end
									end)
								end
							end, false, liveryOptions, 1, nil, true)
						elseif selection == "team" then
							if not requireAPIKey(ria) then
								return
							end

							optionsSelect(ria, "Select Team", function(opt, cia, r)
								if opt and opt ~= "" then
									automation.trigger = {
										name = "When a player joins " .. ((opt and (opt ~= "any") and ("the `" .. opt .. "`")) or "any") .. " team...",
										value = "team:" .. opt
									}
									updateBuilder()
								end
							end, true, teamOptions, 1, nil, true)
						elseif selection == "killedin" then
							if not requireAPIKey(ria) then
								return
							end
							prompt(ria, "Amount of Players Killed In...", {
								{
									question = "How many players?",
									placeholder = "How many players should have been killed before the automation triggers?",
									style = "short",
									required = true
								},
								{
									question = "In how much time?",
									placeholder = "After how long should Ducky forget about a kill?",
									style = "short",
									required = true
								}
							}, function(mia, responses)
								if mia then
									if responses["How many players?"] and responses["In how much time?"] then
										local amountPlayers = tonumber(responses["How many players?"])
										local forgetTime = convert(responses["In how much time?"])

										if not tonumber(amountPlayers) then
											return mia:fail("You must provide a valid amount of players.", nil, true)
										elseif not forgetTime then
											return mia:fail("You must provide a valid time.", nil, true)
										elseif forgetTime < 5 or forgetTime > 43200 then
											return mia:fail("You must provide a time between 5 seconds and 12 hours.", nil, true)
										end

										automation.trigger = {
											name = "When a player kills " .. amountPlayers .. " players in " .. readable(forgetTime) .. "...",
											value = "killedin:" .. amountPlayers .. ":" .. forgetTime
										}

										updateBuilder()
										return mia:updateDeferred(true)
									else
										updateBuilder()
										return mia:updateDeferred(true)
									end
								end
							end, false)
						elseif selection == "teamcount" then
							if not requireAPIKey(ria) then
								return
							end
							optionsSelect(ria, "Select Team", function(team, cia, r)
								if team and team ~= "" then
									ask(cia, "The amount of players on the team reaches...", "At how many players on the team should the automation trigger?", "fgsfugdg", "dfusfgy78fdgy", "short", true, nil, function(_, mia, amount)
										if mia and amount then
											if (not tonumber(amount)) or (tonumber(amount) < 0) or (tonumber(amount) > 50) then
												updateBuilder()
												return mia:fail("The response must be a number between 0 and 50.", nil, true)
											end

											automation.trigger = {
												name = "When the amount of players on the `" .. team .. "` team reaches " .. amount .. "...",
												value = team .. ":" .. tonumber(amount)
											}
											updateBuilder()
											mia:updateDeferred(true)
										end
									end)
								end
							end, true, teamOptions, 1, nil, true)
						elseif selection == "regionentered" then
							if not requireAPIKey(ria) then
								return
							end

							local options = {}

							for i, region in pairs(config.regions or {}) do
								local Region = erlua.Region(region.name, region.points)
								table.insert(options, {
									label = Region.name,
									description = formatNumber(Region.area) .. " studs², " .. #region.points .. " points",
									emoji = resolvedEmojis.map,
									value = tostring(i)
								})
							end

							if table.count(options) <= 0 then
								ria:fail("You have not created any regions yet.", nil, true)
								return updateBuilder()
							end

							optionsSelect(ria, "Select a region...", function(index)
								local region = config.regions[tonumber(index)]
								if region then
									automation.trigger = {
										name = "When a player enters the " .. region.name .. " region...",
										value = "regionentered:" .. region.name
									}
									updateBuilder()
								end
							end, true, options, 1, nil, true)
						elseif selection == "regionexited" then
							if not requireAPIKey(ria) then
								return
							end

							local options = {}

							for i, region in pairs(config.regions or {}) do
								local Region = erlua.Region(region.name, region.points)
								table.insert(options, {
									label = Region.name,
									description = formatNumber(Region.area) .. " studs², " .. #region.points .. " points",
									emoji = resolvedEmojis.map,
									value = tostring(i)
								})
							end

							if table.count(options) <= 0 then
								ria:fail("You have not created any regions yet.", nil, true)
								return updateBuilder()
							end

							optionsSelect(ria, "Select a region...", function(index)
								local region = config.regions[tonumber(index)]
								if region then
									automation.trigger = {
										name = "When a player exits the " .. region.name .. " region...",
										value = "regionexited:" .. region.name
									}
									updateBuilder()
								end
							end, true, options, 1, nil, true)
						elseif selection == "cmdused" then
							if config.erlccmdschannel then
								ask(ria, "Command", "What command should trigger this automation?", "sfo8y7", "o98yery", "short", true, nil, function(_, mia, response)
									if mia and response then
										if response:usub(1, 1) == ":" then
											response = response:usub(2)
										end
										local params = string.split(response, " ")

										if not remoteInGameCommands[params[1]:lower()] then
											updateBuilder()
											return mia:fail("That is not a valid command.", nil, true)
										end

										automation.trigger = {
											name = "When the command `" .. params[1]:lower() .. "` is used...",
											value = "cmdused:" .. params[1]:lower()
										}

										updateBuilder()
										mia:updateDeferred(true)
									end
								end)
							else
								ria:fail("An **ERLC Command Logs Channel** has not been selected in the " .. emojis.game .. " **ERLC Integration** `/setup` page.", nil, true)
							end
						elseif selection == "plate" then
							prompt(ria, "When a plate is used...", {
								{
									question = "Plate",
									placeholder = "* for wildcard, # for any number, and @ for any letter.",
									style = "short",
									required = true,
									min = 3,
									max = 7
								}
							}, function(mia, responses)
								if mia then
									local plate = responses and responses["Plate"]

									if plate and plate:len() >= 3 and plate:len() <= 7 then
										automation.trigger = {
											name = "When the plate `" .. plate .. "` is used...",
											value = "plate:" .. plate
										}

										updateBuilder()
										return mia:updateDeferred(true)
									else
										updateBuilder()
										return mia:fail("You did not provide a valid plate between 3-7 characters.", nil, true)
									end
								end
							end, false)
						elseif selection == "callsign" then
							prompt(ria, "When a callsign is used...", {
								{
									question = "Callsign",
									placeholder = "* for wildcard, # for any number, and @ for any letter.",
									style = "short",
									required = true,
									min = 3,
									max = 6
								}
							}, function(mia, responses)
								if mia then
									local callsign = responses and responses["Callsign"]

									if callsign and callsign:len() >= 3 and callsign:len() <= 6 and select(2, callsign:gsub("%a", "")) <= 3 then
										automation.trigger = {
											name = "When the callsign `" .. callsign .. "` is used...",
											value = "callsign:" .. callsign
										}

										updateBuilder()
										return mia:updateDeferred(true)
									else
										updateBuilder()
										return mia:fail("You did not provide a valid callsign between 3-6 characters with less than 3 letters.", nil, true)
									end
								end
							end, false)
						elseif selection == "shiftUpdate" then
							optionsSelect(ria, "Select a shift status...", function(status)
								local resolveShiftStatus = {
									["any"] = "Any",
									["on"] = "On Shift",
									["break"] = "On Pause",
									["off"] = "Off Shift"
								}

								automation.trigger = {
									name = "When a staff member's shift changes to " .. resolveShiftStatus[status],
									value = "shiftUpdate:" .. status
								}

								updateBuilder()
								ria:updateDeferred(true)
							end, true, shiftStatusOptions, 1, nil, true)
						elseif selection == "trollusername" then
							if not requireAPIKey(ria) then
								return
							end
							automation.trigger = {
								name = "When a player has a troll username...",
								value = "trollusername"
							}
							updateBuilder()
							ria:updateDeferred(true)
						elseif selection == "manual" then
							automation.trigger = {
								name = "When this automation is manually triggered...",
								value = "manual"
							}
							updateBuilder()
							ria:updateDeferred(true)
						elseif selection == "interval" then
							prompt(ria, "Automation Interval Trigger", {
								{
									question = "Automation Interval",
									placeholder = "i.e. 'every day at 16:00 EDT', 'every sunday at 12:00 CEST'",
									style = "short",
									required = false
								}
							}, function(mia, responses)
								if mia then
									local response = responses and responses["Automation Interval"]

									if response then
										local interval, err = intervalParse(response)

										if interval then
											automation.trigger = {
												name = (interval.type == "interval" and "Every " .. readable(interval.seconds, true) or readable(interval)) .. "...",
												value = "interval",
												interval = interval
											}

											updateBuilder()
											return mia:updateDeferred(true)
										else
											updateBuilder()
											return mia:fail(err, nil, true)
										end
									end
								end
							end)
						else
							ria:updateDeferred(true)
							updateBuilder()
						end
					end)
				elseif id == "edit" and selection == "customize" then
					if not automation.trigger or automation.trigger.value ~= "manual" then
						return ia:fail("This is only supported on manual trigger.")
					end

					local customization = automation.customization or {} --[[ 
                        {
                            requiredRole = "",
                            customArgs = {
                                    -- 3 args is not required
                                    arg1 = {
                                        name = "",
										description = "",
                                        required = true/false
                                    },
                                    arg2 = {
                                        name = "",
										description = "",
                                        required = true/false
                                    },
                                    arg3 = {
                                        name = "",
										description = "",
                                        required = true/false
                                    }
                            },
                            customSlashCommand = {
                                name = "",
                                description = "",
                                id = "" (only available in automation edit)
                            }
                        } 
                    ]] --

					local builder

					local function updateCustomizeBuilder()
						local customizeBuilderComps = discordia.Components():selectMenu({
							placeholder = "Customize this automation...",
							id = "customize",
							options = {
								{
									label = "Edit Required Role",
									value = "requiredRole",
									emoji = resolvedEmojis.role
								},
								{
									label = "Edit Custom Argument",
									value = "customArgs",
									emoji = resolvedEmojis.json
								},
								{
									label = "Remove Custom Argument",
									value = "removeCustomArg",
									emoji = resolvedEmojis.delete
								},
								{
									label = "Edit Custom Slash Command",
									value = "customSlashCommand",
									emoji = resolvedEmojis.developer
								}
							},
							actionRow = 1,
							min_values = 0,
							max_values = 1
						}):button({
							label = "Save",
							emoji = resolvedEmojis.yeswhite,
							id = "save",
							style = "success",
							actionRow = 2
						}):button({
							label = "Cancel",
							emoji = resolvedEmojis.nowhite,
							id = "cancel",
							style = "danger",
							actionRow = 2
						}):raw()

						local emb = {
							title = emojis.livery .. " Customize",
							description = emojis.bulletPoint .. " **Required Role:** " .. ((customization.requiredRole and "<@&" .. customization.requiredRole .. ">") or emojis.fail) .. "\n" .. emojis.bulletPoint .. " **Custom Arguments:** " .. (customization.customArgs and next(customization.customArgs) and "\n" .. emojis.bulletPointSpacing .. emojis.bulletPoint .. " " .. table.concatFn(customArgsOrder, "\n" .. emojis.bulletPointSpacing .. emojis.bulletPoint .. " ", function(orderedArg, i)
									local arg = customization.customArgs[orderedArg]

									if arg then
										return "**" .. tostring(i) .. ":** `{" .. arg.name .. "}`" .. ((arg.required and " (" .. emojis.lock .. ")") or "")
									else
										return ""
									end
								end) or emojis.fail) .. "\n" .. emojis.bulletPoint .. " **Custom Slash Command:** " .. ((customization.customSlashCommand and ((customization.customSlashCommand.id and "</" .. customization.customSlashCommand.name .. ":" .. customization.customSlashCommand.id .. ">") or ("`/" .. customization.customSlashCommand.name .. "`"))) or emojis.fail),
							color = colors.yellow
						}

						if type(builder) == "table" then
							ia:editReply({
								embed = emb,
								components = customizeBuilderComps
							}, builder.id)
						else
							builder = ia:reply({
								embed = emb,
								components = customizeBuilderComps
							}, true)
						end
					end

					updateCustomizeBuilder()

					onComp(builder, nil, nil, interaction.user.id, false, function(bia)
						local id = bia.data.custom_id
						local selection = bia.data.values and bia.data.values[1]

						if id == "customize" and selection == "requiredRole" then
							roleSelect(bia, "Select a role...", function(role)
								customization.requiredRole = role
								updateCustomizeBuilder()
							end, true, 0, 1, customization.requiredRole, true)
						elseif id == "customize" and selection == "customArgs" then
							optionsSelect(bia, "Select an argument to edit...", function(selectedArg, cia, cr)
								customization.customArgs = customization.customArgs or {}
								local existingArg = customization.customArgs[selectedArg]

								local argNumber = selectedArg:match("(%d+)$")
								argNumber = tonumber(argNumber)
								if argNumber ~= 1 then
									local previouseArg = customization.customArgs["arg" .. tostring(argNumber - 1)]

									if not previouseArg then
										updateCustomizeBuilder()
										return cia:fail("You cannot skip argument, configure the previouse one first.", nil, true)
									end
								end

								bia:deleteReply(cr.id)

								prompt(cia, "Argument Options: " .. selectedArg, {
									{
										question = "Name",
										placeholder = "What is this argument called?",
										style = "short",
										default = existingArg and existingArg.name,
										max = 32,
										required = true
									},
									{
										question = "Description",
										placeholder = "Give more details on what this argument expects.",
										style = "short",
										default = existingArg and existingArg.description,
										max = 100,
										required = true
									},
									{
										question = "Required",
										placeholder = "yes/no",
										style = "short",
										default = existingArg and existingArg.required and "yes" or "no",
										max = 3,
										required = true
									}
								}, function(mia, responses)
									if mia then
										local nameInput = responses["Name"]
										local descriptionInput = responses["Description"]
										local requiredInput = responses["Required"]

										if type(nameInput) ~= "string" or nameInput == "" or not nameInput:match("^[%w_-]+$") then
											updateCustomizeBuilder()
											return mia:fail("You must provide a valid name that only contains letters, numbers, undercores and hyphens.", nil, true)
										end

										if type(requiredInput) ~= "string" or (requiredInput:lower() ~= "yes" and requiredInput:lower() ~= "no") then
											updateCustomizeBuilder()
											return mia:fail("You must state either `yes` or `no` in the in the `Required` field.", nil, true)
										end

										requiredInput = requiredInput:lower()
										customization.customArgs[selectedArg] = {
											name = nameInput:lower(),
											description = descriptionInput,
											required = (requiredInput == "yes" and true) or (requiredInput == "no" and false)
										}
										updateCustomizeBuilder()
									end
								end, true)
							end, true, {
								{
									label = "Argument 1",
									value = "arg1",
									emoji = resolvedEmojis.json
								},
								{
									label = "Argument 2",
									value = "arg2",
									emoji = resolvedEmojis.json
								},
								{
									label = "Argument 3",
									value = "arg3",
									emoji = resolvedEmojis.json
								},
								{
									label = "Argument 4",
									value = "arg4",
									emoji = resolvedEmojis.json
								},
								{
									label = "Argument 5",
									value = "arg5",
									emoji = resolvedEmojis.json
								},
							}, 1, nil, true)
						elseif id == "customize" and selection == "removeCustomArg" then
							local opts = {
								(customization.customArgs["arg1"] and {
									label = "Argument 1",
									value = "arg1",
									emoji = resolvedEmojis.delete
								}),
								(customization.customArgs["arg2"] and {
									label = "Argument 2",
									value = "arg2",
									emoji = resolvedEmojis.delete
								}),
								(customization.customArgs["arg3"] and {
									label = "Argument 3",
									value = "arg3",
									emoji = resolvedEmojis.delete
								}),
								(customization.customArgs["arg4"] and {
									label = "Argument 4",
									value = "arg4",
									emoji = resolvedEmojis.delete
								}),
								(customization.customArgs["arg5"] and {
									label = "Argument 5",
									value = "arg5",
									emoji = resolvedEmojis.delete
								}),
							}

							if not next(opts) then
								return bia:fail("You have not added any custom arguments yet.", nil, true)
							end

							optionsSelect(bia, "Select an argument to edit...", function(selectedArgIndex, cia, cr)
								customization.customArgs[selectedArgIndex] = nil

								customization.customArgs = customization.customArgs or {}
								local selectedArgNumber = tonumber(selectedArgIndex:match("(%d+)$"))

								for _, i in ipairs(customArgsOrder) do
									local arg = customization.customArgs[i]
									if i ~= selectedArgIndex and arg then
										local argNumber = tonumber(i:match("(%d+)$"))

										if argNumber > selectedArgNumber then
											customization.customArgs["arg" .. tostring(argNumber -1)] = arg
											customization.customArgs[i] = nil
										end
									end
								end

								bia:deleteReply(cr.id)
								updateCustomizeBuilder()
							end, true, opts, 1, nil, true)
						elseif id == "customize" and selection == "customSlashCommand" then
							prompt(bia, "Custom Slash Command", {
								{
									question = "Name",
									placeholder = "What is the name of the slash command?",
									style = "short",
									default = customization.customSlashCommand and customization.customSlashCommand.name,
									max = 32,
									required = true
								},
								{
									question = "Description",
									placeholder = "Give more details on what this automation does.",
									style = "short",
									default = customization.customSlashCommand and customization.customSlashCommand.description,
									max = 100,
									required = true
								}
							}, function(mia, responses)
								local nameInput = responses["Name"]
								local descriptionInput = responses["Description"]

								if type(nameInput) ~= "string" or nameInput == "" or not nameInput:match("^[%w_-]+$") then
									updateCustomizeBuilder()
									return mia:fail("You must provide a valid name that only contains letters, numbers, undercores and hyphens.", nil, true)
								end

								customization.customSlashCommand = {
									name = nameInput:lower(),
									description = descriptionInput,
									id = customization.customSlashCommand and customization.customSlashCommand.id
								}
								updateCustomizeBuilder()
							end, true)
						elseif id == "save" then
							automation.customization = customization
							updateBuilder()
							ia:deleteReply(builder.id)
							bia:updateDeferred(true)
						elseif id == "cancel" then
							updateBuilder()
							ia:deleteReply(builder.id)
							bia:updateDeferred(true)
						end
					end)
				elseif id == "edit" and selection == "addcondition" then
					if not automation.trigger then
						ia:fail("You have not selected a trigger.", nil, true)
						updateBuilder()
						return
					end

					local r = ia:reply({
						components = discordia.Components({
							conditionSelect
						}):raw()
					}, true)

					onComp(r, nil, nil, interaction.user.id, true, function(ria)
						ia:deleteReply(r.id)

						local conditionsTable = {
							["role"] = {
								process = function(callback)
									local splitTrigger = string.split(automation.trigger.value, ":")
									local triggerId = splitTrigger and splitTrigger[1]
									local triggerOption = triggerOptions[triggerId]

									roleSelect(ria, "Select a role...", function(role)
										if not role then
											updateBuilder()
											return
										end

										if table.count(triggerOption.targetOptions) > 1 then
											optionsSelect(ria, "Select target...", function(opt)
												if opt then
													callback({
														name = "and the " .. opt .. " does have the <@&" .. role .. "> role...",
														value = "role:" .. role .. ":" .. opt
													})
												end
											end, true, triggerOption.targetOptions, 1, nil, true)
										else
											callback({
												name = "and the " .. triggerOption.targetOptions[1].value .. " does have the <@&" .. role .. "> role...",
												value = "role:" .. role .. ":" .. triggerOption.targetOptions[1].value
											})
										end
									end, true, nil, nil, nil, true)
								end
							},
							["notrole"] = {
								process = function(callback)
									local splitTrigger = string.split(automation.trigger.value, ":")
									local triggerId = splitTrigger and splitTrigger[1]
									local triggerOption = triggerOptions[triggerId]

									roleSelect(ria, "Select a role...", function(role)
										if not role then
											updateBuilder()
											return
										end

										local condition

										if table.count(triggerOption.targetOptions) > 1 then
											optionsSelect(ria, "Select target...", function(opt)
												if opt then
													callback({
														name = "and the " .. opt .. " does not have the <@&" .. role .. "> role...",
														value = "notrole:" .. role .. ":" .. opt
													})
												end
											end, true, triggerOption.targetOptions, 1, nil, true)
										else
											callback({
												name = "and the " .. triggerOption.targetOptions[1].value .. " does not have the <@&" .. role .. "> role...",
												value = "notrole:" .. role .. ":" .. triggerOption.targetOptions[1].value
											})
										end
									end, true, nil, nil, nil, true)
								end
							},
							["region"] = {
								process = function(callback)
									local splitTrigger = string.split(automation.trigger.value, ":")
									local triggerId = splitTrigger and splitTrigger[1]
									local triggerOption = triggerOptions[triggerId]

									local options = {}

									for i, region in pairs(config.regions or {}) do
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
									end
									
									optionsSelect(ia, "Select a region...", function(index, cia)
										local region = config.regions[tonumber(index)]

										if table.count(triggerOption.targetOptions) > 1 then
											optionsSelect(cia, "Select target...", function(opt)
												if opt then
													callback({
														name = "and the " .. opt .. " is in the " .. region.name .. " region...",
														value = "region:" .. region.name .. ":" .. opt
													})
												end
											end, true, triggerOption.targetOptions, 1, nil, true)
										else
											callback({
												name = "and the " .. triggerOption.targetOptions[1].value .. " is in the " .. region.name .. " region...",
												value = "region:" .. region.name .. ":" .. triggerOption.targetOptions[1].value
											})
										end
									end, true, options, 1, nil, true)
								end
							},
							["notregion"] = {
								process = function(callback)
									local splitTrigger = string.split(automation.trigger.value, ":")
									local triggerId = splitTrigger and splitTrigger[1]
									local triggerOption = triggerOptions[triggerId]

									local options = {}

									for i, region in pairs(config.regions or {}) do
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
									end
									
									optionsSelect(ia, "Select a region...", function(index, cia)
										local region = config.regions[tonumber(index)]

										if table.count(triggerOption.targetOptions) > 1 then
											optionsSelect(cia, "Select target...", function(opt)
												if opt then
													callback({
														name = "and the " .. opt .. " is not in the " .. region.name .. " region...",
														value = "notregion:" .. region.name .. ":" .. opt
													})
												end
											end, true, triggerOption.targetOptions, 1, nil, true)
										else
											callback({
												name = "and the " .. triggerOption.targetOptions[1].value .. " is not in the " .. region.name .. " region...",
												value = "notregion:" .. region.name .. ":" .. triggerOption.targetOptions[1].value
											})
										end
									end, true, options, 1, nil, true)
								end
							},
							["sessionStatus"] = {
								bypassTriggerCheck = true,
								process = function(callback)
									optionsSelect(ria, "Select a mode...", function(mode, cia, cr)
										optionsSelect(cia, "Select a status...", function(status)
											cia:deleteReply(cr.id)
											callback({
												name = "and the session status " .. ((mode == "equal" and "is equal to") or (mode == "notequal" and "is not equal to")) .. " " .. status .. "...",
												value = "session:" .. mode .. ":" .. status
											})
										end, true, sessionOptions, 1, nil, true)
									end, false, {
										{
											label = "Equals",
											value = "equal",
											description = "The status is equal to...",
											emoji = resolvedEmojis.equals
										},
										{
											label = "Not Equal",
											value = "notequal",
											description = "The status is not equal to...",
											emoji = resolvedEmojis.notequal
										}
									}, 1, nil, true)
								end
							},
							["playerCount"] = {
								requiresAPIKey = true,
								bypassTriggerCheck = true,
								process = function(callback)
									optionsSelect(ria, "Select a mode...", function(mode, cia, cr)
										local question

										for _, option in pairs(comparisonOperatorsOptions) do
											if option.value == mode then
												question = option.description
											end
										end

										ria:deleteReply(cr.id)
										prompt(cia, "Playercount", {
											{
												question = question,
												placeholder = "A number between 0 and 50.",
												style = "short",
												required = true
											}
										}, function(mia, responses)
											local plrcount = responses[question]

											if not tonumber(plrcount) or tonumber(plrcount) < 0 or tonumber(plrcount) > 50 then
												mia:fail("You must provide a valid number between 0 and 50.", nil, true)
												return callback()
											end

											local modeLabel = question:lower()
											modeLabel = modeLabel:gsub("%.%.%.$", "")

											callback({
												name = "and " .. modeLabel .. " " .. plrcount .. "...",
												value = "playerCount:" .. mode .. ":" .. plrcount
											})
										end, true)
									end, false, comparisonOperatorsOptions, 1, nil, true)
								end
							},
							["erlcTeam"] = {
								requiresAPIKey = true,
								process = function(callback)
									local splitTrigger = string.split(automation.trigger.value, ":")
									local triggerId = splitTrigger and splitTrigger[1]
									local triggerOption = triggerOptions[triggerId]

									optionsSelect(ria, "Select a mode...", function(mode, modeIA, modeR)

										optionsSelect(modeIA, "Select a team...", function(team, teamIA, teamR)
											modeIA:deleteReply(modeR.id)

											if table.count(triggerOption.targetOptions) > 1 then

												optionsSelect(teamIA, "Select target...", function(opt, targetIA, targetR)
													if opt then
														targetIA:deleteReply(targetR.id)

														callback({
															name = "and the " .. opt .. "'s team " .. ((mode == "equal" and "is equal to") or (mode == "notequal" and "is not equal to")) .. " " .. team .. "...",
															value = "erlcTeam" .. mode .. ":" .. team .. ":" .. opt
														})
													end
												end, true, triggerOption.targetOptions, 1, nil, true)

											else
												callback({
													name = "and the " .. triggerOption.targetOptions[1].value .. "'s team " .. ((mode == "equal" and "is equal to") or (mode == "notequal" and "is not equal to")) .. " " .. team .. "...",
													value = "erlcTeam" .. mode .. ":" .. team .. ":" .. triggerOption.targetOptions[1].value
												})
											end

											teamIA:deleteReply(teamR.id)
										end, true, teamOptionsForConditions, 1, nil, true)

									end, true, {
										{
											label = "Equals",
											value = "equal",
											description = "The status is equal to...",
											emoji = resolvedEmojis.equals
										},
										{
											label = "Not Equal",
											value = "notequal",
											description = "The status is not equal to...",
											emoji = resolvedEmojis.notequal
										}
									}, 1, nil, true)

								end
							},
							["lastTriggered"] = {
								bypassTriggerCheck = true,
								process = function(callback)
									prompt(ria, "Last Triggered", {
										{
											question = "How long before it can trigger again?",
											placeholder = "Ex. 4m, 7h, 2d",
											style = "short",
											required = true
										}
									}, function(mia, responses)
										if mia and responses then
											local waitTimeInput = responses["How long before it can trigger again?"]
											local waitTime = waitTimeInput and convert(waitTimeInput)

											if not waitTime then
												mia:fail("You must provide a valid time input.", nil, true)
												return callback()
											end

											mia:updateDeferred(true)
											callback({
												name = "and it has been " .. readable(waitTime) .. " since the last trigger of this automation",
												value = "lastTriggered:" .. waitTime
											})
										end
									end)
								end
							}
						}

						local splitTrigger = string.split(automation.trigger.value, ":")
						local trigger = splitTrigger and splitTrigger[1]
						local selection = ria.data and ria.data.values and ria.data.values[1]

						if (not trigger or not triggerOptions[trigger] or not table.find(triggerOptions[trigger].allowedconditions, selection)) and not conditionsTable[selection].bypassTriggerCheck then
							return ria:fail("The selected trigger does not support the `" .. selection .. "` condition.", nil, true)
						end

						if conditionsTable[selection].requiresAPIKey and not requireAPIKey(ria) then
							return
						end

						if checkLimit(ria, "conditions", plus, table.count(automation.conditions or {}), "automationConditions") then
							return
						end

						conditionsTable[selection].process(function(condition)
							if condition then
								automation.conditions = automation.conditions or {}
								table.insert(automation.conditions, condition)
							end

							updateBuilder()
						end)
					end)
				elseif id == "edit" and selection == "removecondition" then
					if not automation.conditions or not next(automation.conditions) then
						return ia:fail("You have not added any conditions.", nil, true)
					end

					local options = {}

					for i, condition in pairs(automation.conditions) do
						table.insert(options, {
							label = "#" .. tostring(i),
							value = tostring(i),
							description = string.truncate(condition.name, 100),
							emoji = resolvedEmojis.channel
						})
					end

					optionsSelect(ia, "Select a condition...", function(opt)
						automation.conditions[tonumber(opt)] = nil
						automation.conditions = table.values(automation.conditions)
						updateBuilder()
					end, true, options, 1, nil, true)
				elseif id == "edit" and selection == "addaction" then
                    if checkLimit(ia, "actions", plus, table.count(automation.actions or {}), "automationActions") then
                        updateBuilder()
                        return
                    end

					local r = ia:reply({
						components = discordia.Components({
							actionInserter
						}):raw()
					}, true)

					onComp(r, nil, nil, interaction.user.id, true, function(ria)
						local selection = ria.data and ria.data.values and ria.data.values[1]

						ia:deleteReply(r.id)

						if selection == "sendcommand" then
							if not requireAPIKey(ria) then
								return
							end

							ask(ria, "Command", "What command should be sent to the in-game server?", "sfo8y7", "o98yery", "short", true, nil, function(_, mia, response)
								if mia and response then
									if response:usub(1, 1) == ":" then
										response = response:usub(2)
									end
									local params = string.split(response, " ")

									if not remoteInGameCommands[params[1]:lower()] then
										updateBuilder()
										return mia:fail("That is not a valid command, or that command cannot be run by Remote Server Management.", nil, true)
									end

									local cmd = response

									table.insert(automation.actions, {
										name = "Send the `:" .. string.truncate(cmd, 50) .. "` command to the in-game server",
										value = "sendcommand:" .. cmd
									})
									updateBuilder()
									mia:updateDeferred(true)
								end
							end)
						elseif selection == "delay" then
							ask(ria, "Wait...", "How long should the delay be? (i.e. 30s, 1m, 5m)", "487brsf", "r87gy8sd7fg", "short", true, nil, function(_, mia, response)
								if mia and response then
									if (not _G.convert(tostring(response))) then
										updateBuilder()
										return mia:fail("The response must be a valid interval of time.", nil, true)
									end

									table.insert(automation.actions, {
										name = "Wait " .. readable(_G.convert(tostring(response))),
										value = "delay:" .. _G.convert(tostring(response))
									})
									updateBuilder()
									mia:updateDeferred(true)
								end
							end)
						elseif selection == "endshifts" then
							table.insert(automation.actions, {
								name = "End all active shifts",
								value = "endshifts"
							})
							updateBuilder()
							ria:updateDeferred(true)
						elseif selection == "recheckconditions" then
							if (not automation.conditions) or (table.count(automation.conditions) <= 0) then
								ria:fail("There are not any conditions on this automation.", nil, true)
								updateBuilder()
								return
							end

							local delayed = false

							for i = table.count(automation.actions), 1, -1 do
								local action = automation.actions[i]

								if action.value:split(":")[1] == "delay" then
									delayed = true
									break
								elseif action.value == "recheckconditions" then
									break
								end
							end

							if not delayed then
								ria:fail("You must add a delay action before re-checking conditions.", nil, true)
								updateBuilder()
								return
							end

							table.insert(automation.actions, {
								name = "Re-check conditions",
								value = "recheckconditions"
							})
							updateBuilder()
							ria:updateDeferred(true)
						elseif selection == "lockchannel" then
							prompt(ria, "Lock Channel", {
								{
									question = "Which channel should be locked?",
									component = discordia.SelectMenu({
										id = "channel",
										placeholder = "Select a channel...",
										max_values = 1,
										type = "channel"
									}):raw()
								}
							}, function(mia, responses)
								if mia then
									local channel = responses and responses["Which channel should be locked?"] and interaction.guild:getChannel(responses["Which channel should be locked?"])

									if channel then
										table.insert(automation.actions, {
											name = "Lock the " .. channel.mentionString .. " channel",
											value = "lockchannel:" .. channel.id
										})
										updateBuilder()
										mia:updateDeferred(true)
									else
										updateBuilder()
										return mia:fail("You did not select a valid channel to be locked.")
									end
								end
							end)
						elseif selection == "unlockchannel" then
							prompt(ria, "Unlock Channel", {
								{
									question = "Which channel should be unlocked?",
									component = discordia.SelectMenu({
										id = "channel",
										placeholder = "Select a channel...",
										max_values = 1,
										type = "channel"
									}):raw()
								}
							}, function(mia, responses)
								if mia then
									local channel = responses and responses["Which channel should be unlocked?"] and interaction.guild:getChannel(responses["Which channel should be unlocked?"])

									if channel then
										table.insert(automation.actions, {
											name = "Unlock the " .. channel.mentionString .. " channel",
											value = "unlockchannel:" .. channel.id
										})
										updateBuilder()
										mia:updateDeferred(true)
									else
										updateBuilder()
										return mia:fail("You did not select a valid channel to be unlocked.")
									end
								end
							end)
						elseif selection == "punish" then
							local splitTrigger = automation.trigger and automation.trigger.value and string.split(automation.trigger.value, ":")
							local triggerId = splitTrigger and splitTrigger[1]
							local triggerOption = triggerOptions[triggerId]

							if (not triggerOption) or (not table.find(triggerOption.allowedactions, "punish")) then
								ria:fail("The selected trigger does not support this action.", nil, true)
								return updateBuilder()
							elseif (not config.punishmenttypes) or (not next(config.punishmenttypes)) then
								ria:fail("No punishment types have been configured for this server.",  nil, true)
								return updateBuilder()
							end

							local typeOptions = {}
							for _, type in pairs(config.punishmenttypes) do
								table.insert(typeOptions, {
									label = type,
									value = type,
									emoji = resolvedEmojis.moderate
								})
							end

							optionsSelect(ria, "Select target...", function(opt, cia, r)
								ria:deleteReply(r.id)

								if opt then
									prompt(cia, "Punish the " .. opt .. " with...", {
										{
											question = "What type should the punishment be of?",
											component = discordia.SelectMenu({
												id = "punishmenttype",
												placeholder = "Select a punishment type...",
												options = typeOptions,
												max_values = 1,
												required = true
											}):raw()
										},
										{
											question = "What should the punishment's reason be?",
											placeholder = "Enter a reason for the punishment...",
											style = "short",
											required = true
										}
									}, function(mia, responses)
										if mia then
											local type = responses and responses["What type should the punishment be of?"]
											local reason = responses and responses["What should the punishment's reason be?"]

											if (not type) or (type == "") then
												updateBuilder()
												return mia:fail("You did not provide a valid type for the punishment.", nil, true)
											elseif (not reason) or (reason == "") then
												updateBuilder()
												return mia:fail("You did not provide a reason for the punishment.", nil, true)
											end

											table.insert(automation.actions, {
												name = "Punish the " .. opt .. " with a " .. type .. " for " .. reason,
												value = "punish:" .. opt .. ":" .. type .. ":" .. reason
											})
											updateBuilder()
											return mia:updateDeferred(true)
										end
									end)
								end
							end, false, triggerOption.targetOptions, 1, nil, true)
						elseif selection == "sendmessage" then
							messageEditor(ia, function(response)
								if not response then
									return
								end

								local data = {
									content = response.content,
									embeds = response.embeds,
									components = response.components
								}

								local succ, jsonData = pcall(json.encode, data)

								if succ and jsonData then
									table.insert(automation.actions, {
										name = "Send a message to <#" .. response.channel .. ">",
										value = "sendmessage:" .. response.channel .. ":" .. jsonData
									})
								else
									ia:fail("The message data could not be encoded. Please try again later.", nil, true)
								end

								updateBuilder()
							end, nil, nil, true, true)
						elseif selection == "sessionstart" then
							table.insert(automation.actions, {
								name = "Send the session start-up message",
								value = "sessionstart"
							})
							updateBuilder()
							ria:updateDeferred(true)
						elseif selection == "sessionend" then
							table.insert(automation.actions, {
								name = "Send the session shutdown message",
								value = "sessionend"
							})
							updateBuilder()
							ria:updateDeferred(true)
						elseif selection == "sessionvote" then
							ask(ria, "How many votes are needed?", "Must be a number from 1-50.", "asdpfyasihld", "liusfh", "short", true, nil, function(_, mia, response)
								if mia and response then
									if tonumber(response) then
										local votesRequired = math.clamp(math.floor(tonumber(response) + 0.5), 1, 50)

										table.insert(automation.actions, {
											name = "Start a session vote that requires " .. votesRequired .. " votes",
											value = "sessionvote:" .. votesRequired
										})
										updateBuilder()
										mia:updateDeferred(true)
									else
										mia:fail("The response must be a number between 1-50.", nil, true)
									end
								end
							end)
						else
							ria:updateDeferred(true)
						end
					end)
				elseif id == "edit" and selection == "editaction" then
					if (not automation.actions) or (table.count(automation.actions) <= 0) then
						ia:fail("There are not any actions on this automation.", nil, true)
						updateBuilder()
						return
					end

					local opts = {}

					for actionID, action in ipairs(automation.actions) do
						local actionType = string.split(action.value, ":")[1]

						if actionType == "sendcommand" then
							table.insert(opts, {
								label = "Send a command to the in-game server",
								description = "Action #" .. tostring(actionID),
								value = tostring(actionID),
								emoji = resolvedEmojis.edit
							})
						elseif actionType == "sendmessage" then
							table.insert(opts, {
								label = "Send a message to a channel",
								description = "Action #" .. tostring(actionID),
								value = tostring(actionID),
								emoji = resolvedEmojis.edit
							})
						elseif actionType == "sessionvote" then
							table.insert(opts, {
								label = "Start a session vote",
								description = "Action #" .. tostring(actionID),
								value = tostring(actionID),
								emoji = resolvedEmojis.edit
							})
						elseif actionType == "delay" then
							table.insert(opts, {
								label = string.truncate(action.name, 45),
								description = "Action #" .. tostring(actionID),
								value = tostring(actionID),
								emoji = resolvedEmojis.edit
							})
						elseif actionType == "lockchannel" then
							table.insert(opts, {
								label = "Lock a channel",
								description = "Action #" .. tostring(actionID),
								value = tostring(actionID),
								emoji = resolvedEmojis.edit
							})
						elseif actionType == "unlockchannel" then
							table.insert(opts, {
								label = "Unlock a channel",
								description = "Action #" .. tostring(actionID),
								value = tostring(actionID),
								emoji = resolvedEmojis.edit
							})
						elseif actionType == "punish" then
							table.insert(opts, {
								label = "Punish a player",
								description = "Action #" .. tostring(actionID),
								value = tostring(actionID),
								emoji = resolvedEmojis.edit
							})
						end
					end

					if table.count(opts) <= 0 then return ia:fail("There are no editable actions added to this automation.", nil, true) end

					optionsSelect(ia, "Edit an action...", function(actionID, cia)
						if (not automation.actions) or (table.count(automation.actions) <= 0) then
							cia:fail("There are not any actions on this automation.", nil, true)
							updateBuilder()
							return
						end

						local action = automation.actions[tonumber(actionID)]

						if not action then
							cia:fail("I was unable to find that action.", nil, true)
							updateBuilder()
							return
						end

						local actionType, actionParam = action.value:match("^(.-):(.*)$")

						if not actionType then
							actionType = action.value
						end

						if actionType == "sendcommand" then
							if not requireAPIKey(cia) then
								return
							end

							ask(cia, "Command", "What command should be sent to the in-game server?", "sfo8y7", "o98yery", "short", true, actionParam, function(_, mia, response)
								if mia and response then
									if response:usub(1, 1) == ":" then
										response = response:usub(2)
									end
									local params = string.split(response, " ")

									if not remoteInGameCommands[params[1]:lower()] then
										updateBuilder()
										return mia:fail("That is not a valid command, or that command cannot be run by Remote Server Management.", nil, true)
									end

									local cmd = response

									automation.actions[tonumber(actionID)] = {
										name = "Send the `:" .. string.truncate(cmd, 50) .. "` command to the in-game server",
										value = "sendcommand:" .. cmd
									}
									updateBuilder()
									mia:updateDeferred(true)
								end
							end)
						elseif actionType == "sendmessage" then
							local _, value = action.value:match("^(.-):(.*)$")

							local split = string.split(value, ":")
							table.remove(split, 1)
							local jsonEncodedToSend = table.concat(split, ":")

							local succ, tosend = pcall(json.decode, jsonEncodedToSend)

							if not succ then
								cia:fail("Failed to decode JSON message information: ```" .. tosend .. "```")
								updateBuilder()
								return
							end

							messageEditor(cia, function(response)
								if not response then
									updateBuilder()
									return
								end

								local data = {
									content = response.content,
									embeds = response.embeds,
									components = response.components
								}

								local succ, jsonData = pcall(json.encode, data)

								if succ and jsonData then
									automation.actions[tonumber(actionID)] = {
										name = "Send a message to <#" .. response.channel .. ">",
										value = "sendmessage:" .. response.channel .. ":" .. jsonData
									}
									updateBuilder()
									return
								else
									cia:fail("The message data could not be encoded. Please try again later.", nil, true)
									updateBuilder()
									return
								end
							end, nil, tosend, true, true)
						elseif actionType == "sessionvote" then
							ask(cia, "How many votes are needed?", "Must be a number from 1-50.", nil, nil, "short", true, nil, function(_, mia, response)
								if mia and response then
									if tonumber(response) then
										local votesRequired = math.clamp(math.floor(tonumber(response) + 0.5), 1, 50)

										automation.actions[tonumber(actionID)] = {
											name = "Start a session vote that requires " .. votesRequired .. " votes",
											value = "sessionvote:" .. votesRequired
										}
										updateBuilder()
										return mia:updateDeferred(true)
									else
										mia:fail("The response must be a number between 1-50.", nil, true)
									end
								end
							end)
						elseif actionType == "delay" then
							ask(cia, "Wait...", "How long should the delay be? (i.e. 30s, 1m, 5m)", "487brsf", "r87gy8sd7fg", "short", true, actionParam, function(_, mia, response)
								if mia and response then
									if (not _G.convert(tostring(response))) then
										updateBuilder()
										return mia:fail("The response must be a valid interval of time.", nil, true)
									end

									automation.actions[tonumber(actionID)] = {
										name = "Wait " .. readable(_G.convert(tostring(response))),
										value = "delay:" .. _G.convert(tostring(response))
									}
									updateBuilder()
									mia:updateDeferred(true)
								end
							end)
						elseif actionType == "lockchannel" then
							prompt(cia, "Lock Channel", {
								{
									question = "Which channel should be locked?",
									component = discordia.SelectMenu({
										id = "channel",
										placeholder = "Select a channel...",
										default_values = {{ id = actionParam, type = "channel" }},
										max_values = 1,
										type = "channel"
									}):raw()
								}
							}, function(mia, responses)
								if mia then
									local channel = responses and responses["Which channel should be locked?"] and interaction.guild:getChannel(responses["Which channel should be locked?"])

									if channel then
										automation.actions[tonumber(actionID)] = {
											name = "Lock the " .. channel.mentionString .. " channel",
											value = "lockchannel:" .. channel.id
										}
										updateBuilder()
										mia:updateDeferred(true)
									else
										updateBuilder()
										return mia:fail("You did not select a valid channel to be locked.", nil, true)
									end
								end
							end)
						elseif actionType == "unlockchannel" then
							prompt(cia, "Unlock Channel", {
								{
									question = "Which channel should be unlocked?",
									component = discordia.SelectMenu({
										id = "channel",
										placeholder = "Select a channel...",
										default_values = {{ id = actionParam, type = "channel" }},
										max_values = 1,
										type = "channel"
									}):raw()
								}
							}, function(mia, responses)
								if mia then
									local channel = responses and responses["Which channel should be unlocked?"] and interaction.guild:getChannel(responses["Which channel should be unlocked?"])

									if channel then
										automation.actions[tonumber(actionID)] = {
											name = "Unlock the " .. channel.mentionString .. " channel",
											value = "unlockchannel:" .. channel.id
										}
										updateBuilder()
										mia:updateDeferred(true)
									else
										updateBuilder()
										return mia:fail("You did not select a valid channel to be locked.", nil, true)
									end
								end
							end)
						elseif selection == "punish" then
							local splitTrigger = automation.trigger and automation.trigger.value and string.split(automation.trigger.value, ":")
							local triggerId = splitTrigger and splitTrigger[1]
							local triggerOption = triggerOptions[triggerId]

							if (not triggerOption) or (not table.find(triggerOption.allowedactions, "punish")) then
								cia:fail("The selected trigger does not support this action.", nil, true)
								return updateBuilder()
							elseif (not config.punishmenttypes) or (not next(config.punishmenttypes)) then
								cia:fail("No punishment types have been configured for this server.",  nil, true)
								return updateBuilder()
							end

							local typeOptions = {}

							for _, type in pairs(config.punishmenttypes) do
								table.insert(typeOptions, {
									label = type,
									value = type,
									emoji = resolvedEmojis.moderate
								})
							end

							optionsSelect(cia, "Select target...", function(opt, ocia, r)
								cia:deleteReply(r.id)

								if opt then
									prompt(ocia, "Punish the " .. opt .. " with...", {
										{
											question = "What type should the punishment be of?",
											component = discordia.SelectMenu({
												id = "punishmenttype",
												placeholder = "Select a punishment type...",
												options = typeOptions,
												max_values = 1,
												required = true
											}):raw()
										},
										{
											question = "What should the punishment's reason be?",
											placeholder = "Enter a reason for the punishment...",
											style = "short",
											required = true
										}
									}, function(mia, responses)
										if mia then
											local type = responses and responses["What type should the punishment be of?"]
											local reason = responses and responses["What should the punishment's reason be?"]

											if (not type) or (type == "") then
												updateBuilder()
												return mia:fail("You did not provide a valid type for the punishment.", nil, true)
											elseif (not reason) or (reason == "") then
												updateBuilder()
												return mia:fail("You did not provide a reason for the punishment.", nil, true)
											end

											table.insert(automation.actions, {
												name = "Punish the " .. opt .. " with a " .. type .. " for " .. reason,
												value = "punish:" .. opt .. ":" .. type .. ":" .. reason
											})
											updateBuilder()
											return mia:updateDeferred(true)
										end
									end)
								end
							end, false, triggerOption.targetOptions, 1, nil, true)
						end
					end, true, opts, 1, nil, true)
				elseif id == "edit" and selection == "removeaction" then
					if (not automation.actions) or (table.count(automation.actions) <= 0) then
						ia:fail("There are not any actions on this automation.", nil, true)
						updateBuilder()
						return
					end

					local opts = {}

					for actionID, action in pairs(automation.actions) do
						local label

						if string.split(action.value, ":")[1] == "sendcommand" then
							label = "Send a command to the in-game server"
						elseif string.split(action.value, ":")[1] == "sendmessage" then
							label = "Send a message to a channel"
						elseif string.split(action.value, ":")[1] == "punish" then
							label = "Punish a player"
						else
							label = string.truncate(action.name, 45)
						end

						table.insert(opts, {
							label = label,
							description = "Action #" .. tostring(actionID),
							value = tostring(actionID),
							emoji = resolvedEmojis.edit
						})
					end

					optionsSelect(ia, "Remove an action...", function(actionID, cia)
						table.remove(automation.actions, tonumber(actionID))
						updateBuilder()
					end, true, opts, 1, nil, true)
				elseif id == "edit" and selection == "name" then
					ask(ia, "Edit automation name...", "What should this automation be called?", "siudfhiasfd", "8s7gyso8dgh", "short", true, nil, function(_, mia, response)
						if mia then
							automation.name = response
							mia:updateDeferred(true)
							updateBuilder()
						end
					end)
				elseif id == "edit" and selection == "toggle" then
					if automation.disabled and not plus and type(automation.actions) == "table" and table.count(automation.actions) > featureLimits.automationActions.normal then
						ia:fail("This automation cannot be enabled as it exceeds the " .. emojis.automation .. " **Automations** action limit, " .. table.count(automation.actions) .. "/" .. featureLimits.automationActions.normal .. " actions.\n-# " .. emojis.right .. " Remove actions or purchase " .. emojis.duckyplus .. " **Ducky Plus+** to enabled this automation.", nil, true)
					else
						automation.disabled = not automation.disabled
						ia:updateDeferred(true)
					end

					updateBuilder()
				elseif id == "edit" and selection == "resultschannel" then
					channelSelect(ia, "Select a results channel...", function(channel)
						automation.resultschannel = channel
						updateBuilder()
					end, true, 0, 1, automation.resultschannel)
				elseif id == "edit" and selection == "export" then
					if not automation.name then
						ia:fail("You must set the automation's name.", nil, true)
						return updateBuilder()
					elseif not automation.trigger then
						ia:fail("You must set the automation's trigger.", nil, true)
						return updateBuilder()
					elseif not next(automation.actions) then
						ia:fail("You have not inserted any actions into this automation.", nil, true)
						return updateBuilder()
					end

					local exportable, err = export(automation, interaction.user, "automation", automation.name)

					if not exportable then
						ia:fail(err, nil, true)
						return updateBuilder()
					else
						ia:success("Your automation has been successfully exported. Here's your exportable code: ```\n" .. exportable .. "```", nil, true)
						return updateBuilder()
					end
				elseif id == "edit" and selection == "import" then
					prompt(ia, "Import Automation", {
						{
							question = "Exportable Code",
							style = "short",
							placeholder = "Enter a valid exportable code..."
						}
					}, function(mia, responses)
						if mia then
							local imported, err = import(responses and responses["Exportable Code"], "automation")
							if not imported then
								mia:fail(err, nil, true)
								return updateBuilder()
							end

							automation = imported
							automation.name = nil

							local allCurrentIDs = {}

							for _, ams in pairs(config.automations or {}) do
								table.insert(allCurrentIDs, ams.id)
							end

							local highestID = table.count(allCurrentIDs) > 0 and math.max(table.unpack(allCurrentIDs)) or 0

							for i = 1, highestID do
								if not table.find(allCurrentIDs, i) then
									automation.id = i
									break
								end
							end

							automation.id = highestID + 1

							local contexts = fetchAutomationContexts(imported, ia.guild)
							if contexts and #contexts > 0 then
								local i = 1

								local function step()
									updateBuilder()
									if i > #contexts then
										if subcmd == "edit" then
											confirm(ia, "Are you sure you want to overwrite the current automation you're editing?\n-# " .. emojis.right .. " This action cannot be undone.", function(confirm, ria)
												if ria then
													if confirm then
														automation = imported
														automation.name = nil
													end
													ria:updateDeferred(true)
												end
											end, true)
										else
											automation = imported
											automation.name = nil
										end
										return
									end

									local ctx = contexts[i]
									local text = "Select a new " .. ctx.usage .. " " .. ctx.type .. "..."

									if ctx.type == "channel" then
										channelSelect(ia, text, function(channel)
											for _, action in ipairs(automation.actions or {}) do
												action.value = action.value:gsub(ctx.value, channel)
												action.name = action.name:gsub(ctx.value, channel)
											end

											i = i + 1
											updateBuilder()
											step()
										end, true, 0, 1)
									elseif ctx.type == "role" then
										roleSelect(ia, text, function(role)
											for _, cond in ipairs(automation.conditions or {}) do
												cond.value = cond.value:gsub(ctx.value, role)
												cond.name = cond.name:gsub(ctx.value, role)
											end

											i = i + 1
											updateBuilder()
											step()
										end, true, 0, 1)
									elseif ctx.type == "resultschannel" then
										channelSelect(ia, "Select a new results channel...", function(channel)
											automation.resultschannel = channel
											i = i + 1
											updateBuilder()
											step()
										end, true, 0, 1)
									elseif ctx.type == "punishment" then
										local typeOptions = {}
										for _, type in pairs(config.punishmenttypes or {}) do
											table.insert(typeOptions, {
												label = type,
												value = type,
												emoji = resolvedEmojis.moderate
											})
										end

										if #typeOptions == 0 then
											updateBuilder()
											return ia:fail("You have not configured any punishment types for this server.", nil, true)
										end

										optionsSelect(ia, "Punish the " .. ctx.target .. " with...", function(opt)
											for _, action in ipairs(automation.actions or {}) do
												action.value = action.value:gsub(ctx.value, opt)
												action.name = action.name:gsub(ctx.value, opt)
											end

											i = i + 1
											updateBuilder()
											step()
										end, true, typeOptions, 1, nil, true)
									elseif ctx.type == "customizable_requiredRole" then
										roleSelect(ia, "select a new required role...", function(role)
											if automation.customization then
												automation.customization.requiredRole = role
											end

											i = i +1
											updateBuilder()
											step()
										end, true, 0, 1)
									end
								end
								step()
								return
							end
						end
					end, true)

					return updateBuilder()
				elseif id == "cancel" then
					ia:update({
						embed = {
							description = emojis.fail .. " This builder has been closed.",
							color = colors.fail
						},
						components = {}
					})
					return true
				elseif id == "vars" then
					if automation.trigger and automation.trigger.value then
						local triggervars = vars[string.split(automation.trigger.value, ":")[1]] or ""

						triggervars = ((triggervars ~= "" and (triggervars .. "\n")) or "")
						.. "\n" .. emojis.right .. " **`{notindiscord}`:** A list of all in-game players that are not in the Discord server." 
						.. "\n" .. emojis.right .. " **`{notindiscord.count}`:** The amount of in-game players that are not in the Discord server." 
						.. "\n" .. emojis.right .. " **`{staff}`:** A list of all in-game players with staff permissions."
						.. "\n" .. emojis.right .. " **`{staff.count}`:** The amount of in-game players with staff permissions."
						.. "\n" .. emojis.right .. " **`{onshift}`:** A list of all in-game players that have an active shift."
						.. "\n" .. emojis.right .. " **`{onshift.count}`:** The amount of in-game players that have an active shift."
						.. "\n" .. emojis.right .. " **`{onpause}`:** A list of all in-game players that have a paused shift."
						.. "\n" .. emojis.right .. " **`{onpause.count}`:** The amount of in-game players that have a paused shift."
						.. "\n" .. emojis.right .. " **`{offshift}`:** A list of all in-game players that do not have an active shift."
						.. "\n" .. emojis.right .. " **`{offshift.count}`:** The amount of in-game players that do not have an active shift."
						.. "\n" .. emojis.right .. " **`{police}`:** A list of all in-game players that are on the Police team."
						.. "\n" .. emojis.right .. " **`{police.count}`:** The amount of in-game players that are on the Police team."
						.. "\n" .. emojis.right .. " **`{sheriff}`:** A list of all in-game players that are on the Sheriff team."
						.. "\n" .. emojis.right .. " **`{sheriff.count}`:** The amount of in-game players that are on the Sheriff team."
						.. "\n" .. emojis.right .. " **`{fire}`:** A list of all in-game players that are on the Fire team."
						.. "\n" .. emojis.right .. " **`{fire.count}`:** The amount of in-game players that are on the Fire team."
						.. "\n" .. emojis.right .. " **`{dot}`:** A list of all in-game players that are on the DOT team."
						.. "\n" .. emojis.right .. " **`{dot.count}`:** The amount of in-game players that are on the DOT team."
						.. "\n" .. emojis.right .. " **`{civilian}`:** A list of all in-game players that are on the Civilian team."
						.. "\n" .. emojis.right .. " **`{civilian.count}`:** The amount of in-game players that are on the Civilian team."
						.. ((not triggervars:match("{timestamp}") and "\n" .. emojis.right .. " [`{timestamp}`](https://docs.duckybot.xyz/misc/timestamps): The timestamp of when the automation was ran.") or "")

						if automation.customization and automation.customization.customArgs then
							triggervars = triggervars .. "\n" .. emojis.right .. " " .. table.concatFn(customArgsOrder, "\n" .. emojis.right .. " ", function(orderedArg)
								local arg = automation.customization.customArgs[orderedArg]

								if arg then
									return "**`{" .. arg.name .. "}`:** " .. arg.description .. " (Custom Argument)"
								else
									return ""
								end
							end)
						end


						ia:reply({
							embed = {
								title = emojis.json .. " Variables",
								description = triggervars .. "\n-# " .. emojis.right .. " Variables can be used in the " .. emojis.settings .. " **Send a Command** and " .. emojis.chat .. " **Send a Message** action.",
								color = colors.blank
							}
						}, true)
					else
						ia:fail("You have not selected a trigger.", nil, true)
					end
				elseif id == "create" then
					if savingAutomations[interaction.guild.id] then
						return ia:fail("You are currently already saving an automation.", nil, true)
					end

					savingAutomations[interaction.guild.id] = true

					local ok, err = pcall(function ()
						if automationCount >= maxAutomationCount then
							ia:update({
								embed = {
									description = emojis.fail .. " You have already created " .. automationCount .. "/" .. maxAutomationCount .. " available automations." .. ((not plus) and "\n-# " .. emojis.duckyplus .. " **Ducky Plus+** members can make up to 50 automations."),
									color = colors.fail
								},
								components = {}
							})
							return true
						end

						if not automation.name then
							ia:fail("You must set the automation's name.", nil, true)
							return
						elseif not automation.trigger then
							ia:fail("You must set the automation's trigger.", nil, true)
							return
						elseif not next(automation.actions) then
							ia:fail("You have not inserted any actions into this automation.", nil, true)
							return
						end

						for _, action in ipairs(automation.actions or {}) do
							local splitAction = action.value:split(":")
							local name, value, value2, value3 = splitAction[1], splitAction[2] or splitAction[1], splitAction[3], splitAction[4]

							if name == "sendmessage" and value then
								local split = string.split(value, ":")
								if not interaction.guild:getChannel(split[1]) then
									ia:fail("Action **Send a message** has invalid an channel configured.", nil, true)
									return updateBuilder()
								end
							elseif name == "lockchannel" and value then
								if not interaction.guild:getChannel(value) then
									ia:fail("Action **Lock channel** has invalid an channel configured.", nil, true)
									return updateBuilder()
								end
							elseif name == "unlockchannel" and value then
								if not interaction.guild:getChannel(value) then
									ia:fail("Action **Unlock channel** has an invalid channel configured.", nil, true)
									return updateBuilder()
								end
							elseif name == "punish" and value and value2 then
								if not table.find(config.punishmenttypes or {}, function(pt)
									return pt:lower() == value2:lower()
								end) then
									ia:fail("Action **Punish a player** has an invalid punishment type configured.", nil, true)
									return updateBuilder()
								end
							end
						end

						for _, cond in ipairs(automation.conditions or {}) do
							local split = string.split(cond.value or "", ":")
							local name = split[1]
							local id = split[2]

							if name == "role" then
								if not interaction.guild:getRole(id) then
									ia:fail("Condition **Has role** has an invalid role configured.", nil, true)
									return updateBuilder()
								end
							elseif name == "notrole" then
								if not interaction.guild:getRole(id) then
									ia:fail("Condition **Does not have role** has an invalid role configured.", nil, true)
									return updateBuilder()
								end
							elseif name == "region" then
								if not table.find(config.regions or {}, function(r)
									return r.name:lower() == id:lower()
								end) then
									ia:fail("Condition **In region** has an invalid region configured.", nil, true)
									return updateBuilder()
								end
							elseif name == "notregion" then
								if not table.find(config.regions or {}, function(r)
									return r.name:lower() == id:lower()
								end) then
									ia:fail("Condition **Not in region** has an invalid region configured.", nil, true)
									return updateBuilder()
								end
							end
						end

						if automation.resultschannel and not interaction.guild:getChannel(automation.resultschannel) then
							ia:fail("The configured Results Channel is invalid.", nil, true)
							return updateBuilder()
						end

						config = sqldb:get(interaction.guild.id) or {}
						config.automations = config.automations or {}

						if subcmd == "create" then
							local allCurrentIDs = {}

							for _, ams in pairs(config.automations or {}) do
								table.insert(allCurrentIDs, ams.id)
							end

							local highestID = table.count(allCurrentIDs) > 0 and math.max(table.unpack(allCurrentIDs)) or 0

							for i = 1, highestID do
								if not table.find(allCurrentIDs, i) then
									automation.id = i
									break
								end
							end

							automation.id = automation.id or (highestID + 1)

							local customSlashCmdRaw = automation.customization and automation.customization.customSlashCommand
							if customSlashCmdRaw then
								local customSlashCommand = tools.slashCommand(customSlashCmdRaw.name, customSlashCmdRaw.description)

								if type(automation.customization.customArgs) == "table" and next(automation.customization.customArgs) then
									for _, orderedArg in pairs(customArgsOrder) do
										local arg = automation.customization.customArgs[orderedArg]

										if arg then
											customSlashCommand:addOption(tools.string(arg.name, arg.description):setRequired((arg.required and true) or false))
										end
									end
								end

								local s, e = Client:createGuildApplicationCommand(interaction.guild.id, customSlashCommand)

								if not s then
									return ia:fail("Failed to create custom slash command: ```" .. e .. "```", nil, true)
								else
									automation.customization.customSlashCommand.id = s.id
								end
							end

							table.insert(config.automations, automation)
							sqldb:set(interaction.guild.id, {
								automations = config.automations
							}, "AUTOMATION_CREATE")

							ia:update({
								embed = {
									description = emojis.success .. " This automation has been successfully created.\n-# " .. emojis.right .. " **ID:** `" .. automation.id .. "`",
									color = colors.success
								},
								components = {}
							})
						elseif subcmd == "edit" and automation.id then
							for i, ams in pairs(config.automations or {}) do
								if ams.id == automation.id then

									local customSlashCmdRaw = automation.customization and automation.customization.customSlashCommand
									if customSlashCmdRaw then
										local customSlashCommand = tools.slashCommand(customSlashCmdRaw.name, customSlashCmdRaw.description)

										if type(automation.customization.customArgs) == "table" and next(automation.customization.customArgs) then
											for _, orderedArg in pairs(customArgsOrder) do
												local arg = automation.customization.customArgs[orderedArg]

												if arg then
													customSlashCommand:addOption(tools.string(arg.name, arg.description):setRequired((arg.required and true) or false))
												end
											end
										end

										if customSlashCmdRaw.id then
											local s, e = Client:editGuildApplicationCommand(interaction.guild.id, customSlashCmdRaw.id, customSlashCommand)

											if not s then
												if e:find("10063") then
													s, e = Client:createGuildApplicationCommand(interaction.guild.id, customSlashCommand)

													if not s then
														return ia:fail("Failed to create custom slash command: ```" .. e .. "```", nil, true)
													else
														automation.customization.customSlashCommand.id = s.id
													end
												else
													return ia:fail("Failed to edit custom slash command: ```" .. e .. "```", nil, true)
												end
											end
										else
											local s, e = Client:createGuildApplicationCommand(interaction.guild.id, customSlashCommand)

											if not s then
												return ia:fail("Failed to create custom slash command: ```" .. e .. "```", nil, true)
											else
												automation.customization.customSlashCommand.id = s.id
											end
										end
									end

									config.automations[i] = automation
									sqldb:set(interaction.guild.id, {
										automations = config.automations
									}, "AUTOMATION_EDIT")

									ia:update({
										embed = {
											description = emojis.success .. " This automation has been successfully edited.",
											color = colors.success
										},
										components = {}
									})

									break
								end
							end
						else
							ia:fail("Something went wrong, please contact us in [Ducky's Pond](http://duckybot.xyz/support).")
						end

						return true
					end)

					savingAutomations[interaction.guild.id] = nil
				else
					ia:updateDeferred(true)
				end
			end)
		elseif subcmd == "list" or subcmd == "view" then
			if not hasPermission(interaction.member, "MANAGE_SERVER", config, interaction) then
				return
			end

			if automationCount <= 0 then
				return interaction:fail("There are not any automations in this server.", nil, true)
			else
				local pages = {}

				table.sort(config.automations, function(a, b)
					return a.id < b.id
				end)

				for i, automation in ipairs(config.automations) do
					local trigger = automation.trigger.name
					local customization = automation.customization

					table.insert(pages, {
						title = emojis.automation .. " #" .. automation.id .. "・" .. automation.name,
						author = {
							name = "Automations (" .. #config.automations .. "/" .. maxAutomationCount .. ")",
							icon_url = resolvedEmojis.automation.image
						},
						description =
						((automation.disabled and "-# " .. emojis.power .. " This automation is currently **disabled**.") or "")
						.. "\n" .. emojis.bulletPoint .. " **Results Channel:** " .. (automation.resultschannel and "<#" .. automation.resultschannel .. ">" or emojis.fail) .. "\n"
						.. ((customization and
							emojis.bulletPoint .. " **Customization:** "
							.. "\n" .. emojis.bulletPointSpacing .. emojis.bulletPoint .. " **Required Role:** " .. ((customization.requiredRole and "<@&" .. customization.requiredRole .. ">") or emojis.fail)
							.. "\n" .. emojis.bulletPointSpacing .. emojis.bulletPoint .. " **Custom Arguments:** "
								.. (customization.customArgs and next(customization.customArgs) and "\n" .. emojis.bulletPointSpacing2 .. emojis.bulletPoint .. " " .. table.concatFn(customArgsOrder, "\n" .. emojis.bulletPointSpacing2 .. emojis.bulletPoint .. " ", function(orderedArg, i)
									local arg = customization.customArgs[orderedArg]

									if arg then
										return "**" .. tostring(i) .. ":** `{" .. arg.name .. "}`" .. ((arg.required and " (" .. emojis.lock .. ")") or "")
									else
										return ""
									end
								end) or emojis.fail)
							.. "\n" .. emojis.bulletPointSpacing .. emojis.bulletPoint .. " **Custom Slash Command:** " 
								.. ((customization.customSlashCommand and ((customization.customSlashCommand.id and "</" .. customization.customSlashCommand.name .. ":" .. customization.customSlashCommand.id .. ">") or ("`/" .. customization.customSlashCommand.name .. "`"))) or emojis.fail)
						.. "\n") or "")
						.. emojis.bulletPoint .. " **Logic:**"
							.. "\n" .. emojis.bulletPointSpacing .. emojis.bulletPoint .. " " .. trigger .. ((automation.conditions and table.count(automation.conditions) > 0 and "\n" .. emojis.bulletPointSpacing .. emojis.bulletPoint .. " " .. table.concatFn(automation.conditions, "\n" .. emojis.bulletPointSpacing .. emojis.bulletPoint .. " ", function(c)
								return c.name
							end)) or "") .. "\n" .. emojis.bulletPointSpacing2 .. emojis.bulletPoint .. " " .. ((automation.actions and table.count(automation.actions) > 0 and table.concatFn(automation.actions, "\n" .. emojis.bulletPointSpacing2 .. emojis.bulletPoint .. " ", function(a)
								return a.name
							end)) or "No actions added"),
						color = colors.yellow,
						identifier = {
							text = "#" .. automation.id .. "・" .. automation.name,
							description = automation.trigger and automation.trigger.name,
							emoji = resolvedEmojis.automation
						}
					})
				end

				return _G.paginate(interaction, pages, interaction.user, {
					showTotalPages = true,
					clamp = false,
					teleport = true
				})
			end
		elseif subcmd == "delete" then
			if not hasPermission(interaction.member, "MANAGE_SERVER", config, interaction) then
				return
			end

			local id = (args and args.automation) or (args and table.remove(args, 1) and args[1] and table.concat(args, " "))

			if not id then
				return interaction:fail("You must provide a valid automation name or ID.", nil, true)
			end

			local automation, automationIndex

			if tonumber(id) then
				for i, ams in pairs(config.automations or {}) do
					if ams.id == tonumber(id) then
						automation = ams
						automationIndex = i
						break
					end
				end
			else
				for i, ams in pairs(config.automations or {}) do
					if ams.name:lower() == id:lower() then
						automation = ams
						automationIndex = i
						break
					end
				end
			end

			if automation then
				local automationName = automation.name

				if automation.customization and automation.customization.customSlashCommand and automation.customization.customSlashCommand.id then
					Client:deleteGuildApplicationCommand(interaction.guild.id, automation.customization.customSlashCommand.id)
				end

				table.remove(config.automations, automationIndex)

				sqldb:set(interaction.guild.id, {
					automations = config.automations
				}, "AUTOMATION_DELETE")

				return interaction:success("The **" .. tostring(automationName) .. "** automation has been successfully deleted.")
			else
				return interaction:fail("An automation with the name or ID of `" .. tostring(id) .. "` was not found.", nil, true)
			end
		elseif subcmd == "trigger" or subcmd == "run" then
			local id = (args and args.automation) or (args and table.remove(args, 1) and args[1])
			table.remove(args, 1)

			if not id then
				return interaction:fail("You must provide a valid automation name or ID.", nil, true)
			end

			local automation

			if tonumber(id) then
				for i, ams in pairs(config.automations or {}) do
					if ams.id == tonumber(id) then
						automation = ams
						break
					end
				end
			else
				for i, ams in pairs(config.automations or {}) do
					if ams.name:lower() == id:lower() then
						automation = ams
						break
					end
				end
			end

			if automation then
				if automation.disabled then
					return interaction:fail("This automation is disabled.", nil, true)
				end

				if automation.trigger.value ~= "manual" and automation.trigger.value ~= "interval" then
					return interaction:fail("That automation's trigger is not manual or interval.", nil, true)
				end

				if automation.customization and automation.customization.requiredRole then
					if (not interaction.member:hasRole(automation.customization.requiredRole)) and (not hasPermission(interaction.member, "MANAGE_SERVER")) then
						return interaction:fail("Only users with the <@&" .. automation.customization.requiredRole .. "> can run this automation.", nil, true)
					end
				elseif not hasPermission(interaction.member, "MANAGE_SERVER", config, interaction) then
					return
				end

				local keys = {}

				if automation.customization and automation.customization.customArgs then
					for i = 1, 5 do
						local argInfo = automation.customization.customArgs["arg" .. i]
						if not argInfo then break end

						local name = argInfo.name
						if name then
							if not args[i] and argInfo.required then
								return interaction:fail("The " .. ordinal(i) .. " argument, **`{" .. name .. "}`**, is required.")
							end

							keys[name] = args[i]
						end
					end
				end

				local r = interaction:loading("Executing **" .. emojis.automation .. " " .. automation.name .. "** automation...")

				local function fail(str)
					if type(r) == "table" then
						r:update({embed = {description = emojis.fail .. " " .. str,color = colors.fail}})
					else
						r = interaction:fail(str)
					end
				end

				local resultsTable, resultsEmbeds = runAutomation(automation, config, interaction.guild, nil, keys, nil, nil, interaction.member)

				if type(resultsTable) ~= "table" or not next(resultsTable) then
					return fail("An unknown error occurred while attempting to execute the automation.")
				end

				if type(r) == "table" then
					r:update({embeds = resultsEmbeds})
				else
					interaction:reply({embeds = resultsEmbeds})
				end
			else
				return interaction:fail("An automation with the name or ID of `" .. tostring(id) .. "` was not found.", nil, true)
			end
		end
	end
}
