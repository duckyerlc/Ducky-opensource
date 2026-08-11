-- time.lua

local slashCommand = tools.slashCommand("time", "Get the current time.")
---------------------------------------------------------------------------------
local subcmd = tools.subCommand("now", "Get the current time.")
slashCommand = slashCommand:addOption(subcmd)
---------------------------------------------------------------------------------
local subcmd = tools.subCommand("in", "Get the time it will be in this amount of time.")
local option = tools.string("in", "The amount of time to add to the current timestamp."):setRequired(true)
subcmd = subcmd:addOption(option)
slashCommand = slashCommand:addOption(subcmd)
---------------------------------------------------------------------------------
local subcmd = tools.subCommand("zone", "Get the current time in a specific timezone.")
local option = tools.string("timezone", "The timezone to get the time from."):setRequired(true)
subcmd = subcmd:addOption(option)
slashCommand = slashCommand:addOption(subcmd)
---------------------------------------------------------------------------------
local subcmd = tools.subCommand("zonelist", "Get a list of all registered timezones.")
slashCommand = slashCommand:addOption(subcmd)
---------------------------------------------------------------------------------

local levenshtein = string.levenshtein

local function findSimilarTimezones(input)
	input = input:lower()
    
	local suggestions = {}

	for _, tz in pairs(timezones) do
		local abrvLower = tz.abrv:lower()
		local nameLower = tz.name:lower()

		if abrvLower:find(input) or nameLower:find(input) then
			table.insert(suggestions, tz)
		elseif levenshtein(input, abrvLower) <= 1 then
			table.insert(suggestions, tz)
		end
	end

	return suggestions
end

return {
	name = "time",
	description = "Get the current time.",
	aliases = {},
	category = "Utility",
	slashCommand = slashCommand,
	subcommands = {
		"now",
		"in",
		"zone",
		"zonelist"
	},
	requiredPermissions = {},
	hybridCallback = function(interaction, args, command, subcmd)
		local UTCtimestamp = os.time(os.date("!*t"))
		local timestamp = os.time()

		if (not command) then
			table.remove(args, 1)
		end

		local formatters = {
			"",
			":t",
			":T",
			":d",
			":D",
			":f",
			":F",
			":R"
		}

		local emb = {
			color = colors.info
		}

		if subcmd == "now" then
			emb.title = emojis.clock .. " Right now, it's:"
			emb.description = ""
			for _, v in pairs(formatters) do
				local fmt = "<t:" .. timestamp .. v .. ">"
				emb.description = emb.description .. emojis.right .. " " .. fmt .. "・`" .. fmt .. "`\n"
			end
		elseif subcmd == "in" then
			local toadd = (args["in"] and convert(args["in"])) or (args[1] and convert(args[1]))
			if not toadd then
				return interaction:fail("You must provide a valid amount of time to add to the current timestamp.")
			end
			toadd = ((toadd <= 99999999) and toadd) or 99999999
			timestamp = timestamp + toadd
			emb.title = emojis.clock .. " In " .. readable(toadd) .. ", it will be:"
			emb.description = ""
			for _, v in pairs(formatters) do
				local fmt = "<t:" .. timestamp .. v .. ">"
				emb.description = emb.description .. emojis.right .. " " .. fmt .. "・`" .. fmt .. "`\n"
			end
		elseif subcmd == "zone" then
			local timezone = nil
			local timezoneInput = ((args and args.timezone and args.timezone:upper()) or (args and args[1] and args[1]:upper()))

			if not timezoneInput then
				return interaction:fail("You did not provide a timezone.", nil, true)
			end
			
			if timezoneInput:usub(1, 3) == "UTC" and tonumber(timezoneInput:usub(5)) then
				local sign = timezoneInput:usub(4, 4)
				local offsetStr = timezoneInput:usub(5)
				local offset = tonumber(offsetStr)

				if sign and offset then
					if (sign == "+") and (offset <= 14) then
						offset = offset
					elseif (sign == "-") and (offset <= 12) then
						offset = -offset
					else
						offset = nil
					end

					if offset then
						timezone = {
							abrv = "UTC" .. sign .. offsetStr,
							name = "Coordinated Universal Time " .. sign .. " " .. offset .. " hours",
							offset = offset,
							twelvehourclock = false
						}
					end
				end
			elseif timezoneInput:usub(1, 3) == "GMT" then
				local sign = timezoneInput:usub(4, 4)
				local offsetStr = timezoneInput:usub(5)
				local offset = tonumber(offsetStr)

				if sign and offset then
					if (sign == "+") and (offset <= 14) then
						offset = offset
					elseif (sign == "-") and (offset <= 12) then
						offset = -offset
					else
						offset = nil
					end

					if offset then
						timezone = {
							abrv = "GMT" .. sign .. offsetStr,
							name = "Greenwich Mean Time " .. sign .. " " .. offset .. " hours",
							offset = offset,
							twelvehourclock = false
						}
					end
				end
			end

			if not timezone then
				for _, tz in pairs(timezones) do
					if tz.abrv == timezoneInput then
						timezone = tz
					end
				end
			end

			if not timezone then
				local suggestions = findSimilarTimezones(timezoneInput)
				if #suggestions > 0 then
					emb.color = colors.fail
					emb.description = emojis.fail .. " No exact match was found for `" .. timezoneInput .. "`. Did you mean:\n"
					for _, suggestion in ipairs(suggestions) do
						emb.description = emb.description ..
						emojis.right .. " **" .. suggestion.name .. "** (`" .. suggestion.abrv .. "`)\n"
					end
				else
					return interaction:fail("You must provide a valid timezone.")
				end
			else
				emb.title = emojis.clock .. " In " .. timezone.name .. " (" .. timezone.abrv .. "), it's currently:"
				local d = os.date("!%B %d, %Y @ " .. ((timezone.twelvehourclock and "%I:%M:%S %p") or "%H:%M:%S"),
					UTCtimestamp + (timezone.offset * (60 * 60)))
				emb.description = emojis.right .. " " .. d
			end
		elseif subcmd == "zonelist" then
			local emb = {
				title = emojis.clock .. " Timezones (" .. #timezones .. ")",
				color = colors.info,
				description = ""
			}
			local pages = {}

			local tzop = 0

			for i, v in pairs(timezones) do
				local d = os.date("!%B %d, %Y @ " .. ((v.twelvehourclock and "%I:%M:%S %p") or "%H:%M:%S"),
					os.time() + (v.offset * (60 * 60)))
				emb.description = emb.description .. emojis.right .. " **" .. v.name .. "** (" .. v.abrv .. ")\n-# " .. emojis.space .. emojis.right .. " " .. d .. "\n"
				tzop = tzop + 1

				if tzop >= 11 then
					tzop = 0
					table.insert(pages, emb)
					emb = {
						title = emojis.clock .. " Timezones (" .. #timezones .. ")",
						color = colors.info,
						description = ""
					}
				elseif i >= #timezones then
					table.insert(pages, emb)
				end
			end

			return paginate(interaction, pages, interaction.user, { clamp = false })
		end

		interaction:reply({ embed = emb })
	end
}