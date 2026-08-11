-- kick.lua
local slashCommand = tools.slashCommand("kick", "Kick a user.")
local option = tools.user("user", "The user to kick."):setRequired(true)
slashCommand = slashCommand:addOption(option)
local option = tools.string("reason", "The reason for the kick."):setRequired(true)
slashCommand = slashCommand:addOption(option)
local option = tools.boolean("departmental", "Whether or not to kick this user from all of this server's departments as well."):setRequired(false)
slashCommand = slashCommand:addOption(option)
return {
	name = "kick",
	description = "Kick a user.",
	aliases = {},
	category = "Moderation",
	slashCommand = slashCommand,
	requiredPermissions = {
		"MOD"
	},
	hybridCallback = function(interaction, args, slash)
		local config = sqldb:get(interaction.guild.id) or {}
		local departmental = (slash and args and args.departmental == true) or false
		local member = fetchMemberFromInteraction(interaction, args, slash)

		if not member then
			return interaction:fail("You did not provide a member to kick.", nil, true)
		end

		local reason = (slash and args and args.reason) or ((not slash) and table.remove(args, 1) and table.concat(args, " ") ~= "" and table.concat(args, " "))

		if not reason then
			return interaction:fail("You did not provide a reason.", nil, true)
		end

		local moderatable, err = canModerate(interaction.member, member)
		if not moderatable then
			return interaction:fail(err, nil, true)
		end

		if departmental and (not config.departments or table.count(config.departments) <= 0) then
			return interaction:fail("This server does not host any departments.", nil, true)
		end

		local kicked, err = member:kick(reason)

		if (not kicked) then
			return interaction:fail("I could not kick that user: " .. err:usub(20), nil, true)
		end

		local case = db:case(member, interaction.member, "Kick", reason)

		if not case then
			return interaction:fail("An unknown error occurred when trying to kick that user. Please try again later.", nil, true)
		end

		member:warning("You have been kicked from **" .. interaction.guild.name .. "** for **" .. reason .. "**.", emojis.kick)

		if departmental then
			local results = {
				[interaction.guild.id] = {
					name = interaction.guild.name,
					success = kicked,
					error = nil
				}
			}
			local departments = config.departments or {}

			for id, _ in pairs(departments) do
				local department = Client:getGuild(id)

				if department then
					local s, e = department:kickUser(member.id, reason)

					results[id] = {
						name = department.name,
						success = s,
						error = e
					}
				end
			end

			return interaction:reply({
				embed = {
					title = emojis.guild .. " Departmental Kick Results",
					description = ">>> " .. getUserString(member) .. " has been kicked from the following servers:\n" .. emojis.right .. " " .. table.concatFn(results, "\n" .. emojis.right .. " ", function(result, id)
						return ((result.success and emojis.success) or emojis.fail) .. " " .. result.name .. " (`" .. id .. "`)" .. ((result.error and (": `" .. result.error .. "`")) or "")
					end),
					color = colors.info
				}
			})
		else
			interaction:success(getUserString(member) .. " has been kicked for **" .. reason .. "**.\n-# " .. emojis.right .. " **Case ID:** `" .. case.caseID .. "`")
		end

		db:send(interaction.guild, "modlogchannel", {
			embed = {
				author = author(interaction.member),
				thumbnail = thumbnail(member),
				title = emojis.kick .. " Member Kicked",
				description = getUserString(member) .. " was kicked by " .. getUserString(interaction.member) .. ":\n" .. emojis.right .. " **Reason:** " .. case.reason .. "\n" .. emojis.right .. " **Date:** <t:" .. case.timestamp .. ">\n" .. emojis.right .. " **Case ID:** " .. case.caseID,
				color = colors.fail
			}
		})
	end
}
