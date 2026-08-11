-- role.lua
-- Add Role
local slashCommand = tools.slashCommand("role", "Use Ducky's role modification.")
local subcmd = tools.subCommand("add", "Add a role to a user.")
subcmd = subcmd:addOption(tools.user("user", "The user to add the role to."):setRequired(true))
subcmd = subcmd:addOption(tools.role("role", "The role to add to the user."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)

-- Remove Role
local subcmd = tools.subCommand("remove", "Remove a role from a user.")
subcmd = subcmd:addOption(tools.user("user", "The user to remove the role from."):setRequired(true))
subcmd = subcmd:addOption(tools.role("role", "The role to remove from the user."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)

-- Role Info
local subcmd = tools.subCommand("info", "View info on a role.")
subcmd = subcmd:addOption(tools.role("role", "The role to view info on."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)

-- Role Members
local subcmd = tools.subCommand("members", "View members with a role.")
subcmd = subcmd:addOption(tools.role("role", "The role to view members of."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)

-- Role All
local subcmd = tools.subCommand("all", "Update a role for all members.")

local option = tools.string("type", "Do you want to add or remove the role?")
option = option:addChoice(tools.choice("Add", "Add"))
option = option:addChoice(tools.choice("Remove", "Remove"))
option = option:setRequired(true)
subcmd = subcmd:addOption(option)

subcmd = subcmd:addOption(tools.role("role", "The role you want to update."):setRequired(true))
slashCommand = slashCommand:addOption(subcmd)

local cooldown = {}
local subcmds = {"add", "remove", "info", "members", "all"}

return {
    name = "role",
    description = "Use Ducky's role modification.",
    aliases = {},
    category = "Server Management",
    slashCommand = slashCommand,
    subcommands = subcmds,
    requiredPermissions = {},
    hybridCallback = function(interaction, args, slash, subcmd)
		subcmd = table.find(subcmds, subcmd)

        if (not slash) and subcmd then
            table.remove(args, 1)
        end

		if (subcmd ~= "info") and (not interaction.member:hasPermission("manageRoles")) then
			return interaction:fail("You do not have the **Manage Roles** permission.")
		end

		local function getRole(argnum, after)
			local query = nil

			if slash then
				return args.role
			end

			if argnum and args[argnum] then
				if after then
					query = table.concat(args, " ", argnum)
				else
					query = args[argnum]
				end
			elseif not argnum then
				query = table.concat(args, " ")
			else
				return nil
			end

			local role = nil

			if interaction.mentionedRoles and interaction.mentionedRoles.first and interaction.mentionedRoles.first.id then
				role = interaction.mentionedRoles.first
			elseif tonumber(query) then
				role = interaction.guild:getRole(query)
			else
				for _, v in pairs(interaction.guild.roles) do
					if v.name:lower() == query:lower() then
						role = v
						break
					end
				end

				if not role then
					for _, v in pairs(interaction.guild.roles) do
						if v.name:lower():find(query:lower()) then
							role = v
							break
						end
					end
				end
			end

			return role
		end

		local guild = interaction.guild

		if not table.find(subcmds, subcmd) then
			local member = fetchMemberFromInteraction(interaction, args, slash)
			local role = getRole(2, true)

			if member and role then
				if member:hasRole(role) then
					subcmd = "remove"
				else
					subcmd = "add"
				end
			else
				subcmd = "add"
			end
		end

		if subcmd == "add" then
			local member = fetchMemberFromInteraction(interaction, args, slash)

			if member then
				local role = getRole(2, true)

				if role then
					local selfHighest = (interaction.member.highestRole and interaction.member.highestRole.position) or 0
					if member:hasRole(role.id) then
						return interaction:warning("**" .. member.name .. "** already has the " .. role.mentionString .. " role.", nil, true)
					elseif selfHighest <= role.position and guild.ownerId ~= interaction.member.id then
						return interaction:fail("The " .. role.mentionString .. " role has a higher or same position than your highest role.", nil, true)
					end

					local managable, err = canManageRole(role)

					if not managable then
						return interaction:fail(err)
					end

					local s, e = member:addRole(role.id, "/role add command used by @" .. interaction.member.username)

					if s then
						return interaction:success("**" .. member.name .. "** has been given the " .. role.mentionString .. " role.")
					elseif e then
						return interaction:fail("Failed to give **" .. member.name .. "** the " .. role.mentionString .. " role: " .. e:usub(1, 16), nil, true)
					end
				else
					return interaction:fail("You did not provide a valid role to give **" .. member.name .. "**.", nil, true)
				end
			else
				return interaction:fail("You did not provide a valid member.", nil, true)
			end
		elseif subcmd == "remove" then
			local member = fetchMemberFromInteraction(interaction, args, slash)

			if member then
				local role = getRole(2, true)

				if role then
					local selfHighest = (interaction.member.highestRole and interaction.member.highestRole.position) or 0
					if not member:hasRole(role.id) then
						return interaction:warning("**" .. member.name .. "** does not have the " .. role.mentionString .. " role.", nil, true)
					elseif selfHighest <= role.position and guild.ownerId ~= interaction.member.id then
						return interaction:fail("The " .. role.mentionString .. " role has a higher or same position than your highest role.", nil, true)
					end

					local managable, err = canManageRole(role)

					if not managable then
						return interaction:fail(err)
					end

					local s, e = member:removeRole(role.id, "/role remove command used by @" .. interaction.member.username)

					if s then
						return interaction:success("The " .. role.mentionString .. " role has been removed from **" .. member.name .. "**.")
					elseif e then
						return interaction:fail("Failed to remove the " .. role.mentionString .. " role from **" .. member.name .. "**: " .. e:usub(1, 16), nil, true)
					end
				else
					return interaction:fail("You did not provide a valid role to remove from **" .. member.name .. "**.", nil, true)
				end
			else
				return interaction:fail("You did not provide a valid member.", nil, true)
			end
		elseif subcmd == "info" then
			local role = getRole()

			if role then
				local colorString = ((role.color == 0) and "Default") or ("`" .. discordia.Color(role.color):toHex() .. "`")
				local colorValue = ((role.color == 0) and colors.blank) or role.color
				local iconURL = (role._icon and ("https://cdn.discordapp.com/role-icons/" .. role.id .. "/" .. role._icon .. ".png?size=4096")) or nil

				interaction:reply({
					embed = {
						author = {
							name = role.name,
							icon_url = iconURL
						},
						title = emojis.role .. " Role Information",
						description = emojis.right .. " **ID:** `" .. role.id .. "`\n" .. emojis.right .. " **Mention:** " .. role.mentionString .. "\n" .. emojis.right .. " **Members:** " .. #role.members .. "\n" .. emojis.right .. " **Color:** " .. colorString .. "\n" .. emojis.right .. " **Position:** " .. role.position .. "\n" .. emojis.right .. " **Hoisted:** " .. ((role.hoisted and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Managed:** " .. ((role.managed and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Created:** <t:" .. math.floor(role.createdAt) .. ">",
						thumbnail = iconURL and {
							url = iconURL
						},
						color = colorValue
					}
				})
			else
				return interaction:fail("You did not provide a valid role.", nil, true)
			end
		elseif subcmd == "members" then
			local role = getRole()

			if role then
				loadMembers(interaction.guild)

				local members = role.members
				local colorValue = ((role.color == 0) and colors.blank) or role.color

				local pages = {}

				local embed = {}

				local function resetEmbed()
					embed = {
						title = emojis.people .. " " .. role.name .. " (" .. #members .. ")",
						description = "",
						color = colorValue
					}
				end

				resetEmbed()

				local onpage = 0
				local c = 0

				for _, v in pairs(members) do
					c = c + 1
					embed.description = embed.description .. emojis.right .. " " .. v.mentionString .. "\n"
					onpage = onpage + 1

					if (onpage >= 15) or (c >= #members) then
						onpage = 0
						table.insert(pages, embed)
						resetEmbed()
					end
				end

				if #members <= 0 then
					return interaction:fail("There are no members with that role.", nil, true)
				end

				return paginate(interaction, pages, interaction.user, {
					clamp = false,
					teleport = true
				})
			else
				return interaction:fail("You did not provide a valid role.", nil, true)
			end
		elseif subcmd == "all" then
			if cooldown[guild.id] and cooldown[guild.id] == 0 then
				return interaction:fail("I am already updating members.")
			end

			local plus = sqldb:plusGuild(guild)

			local cooldownTime = (plus and 1800) or 3600

			if cooldown[guild.id] and (os.time() - cooldown[guild.id] <= cooldownTime) then
				local remainingTime = cooldownTime - (os.time() - cooldown[guild.id])
				return interaction:fail("Please wait **" .. readable(remainingTime) .. "** before using this command again.")
			end

			local role = getRole(2, true)

			if role then
				local succ, result = canManageRole(role.id)

				if not succ then
					return interaction:fail(result)
				elseif (interaction.member.highestRole and interaction.member.highestRole.position and interaction.member.highestRole.position <= role.position) then
					return interaction:fail("You do not have permissions to manage this role.")
				end

				local inputType = (slash and args["type"]) or args[1]

				if type(inputType) ~= "string" or (inputType:lower() ~= "add" and inputType:lower() ~= "remove") then
					return interaction:fail("You must provide a valid type, either Add or Remove.")
				end

				cooldown[guild.id] = 0

				local r = interaction:reply({
					embed = {
						description = emojis.loading .. " Fetching members...",
						color = colors.blank
					}
				})

				loadMembers(guild)

				local membercount = #guild.members

				local completedCount = 0

				local plus = sqldb:plusGuild(guild)
				local sleepTime = (plus and 100) or 500
				local updateThreshold = math.ceil(membercount * 0.15)
				local nextUpdateAt = updateThreshold

				local remainingCount = membercount - completedCount
				local estimatedTime = math.ceil(remainingCount * (sleepTime / 1000))
				local timeString = readable(estimatedTime)

				local function updateMessage()
					coroutine.wrap(function()
						remainingCount = membercount - completedCount
						estimatedTime = math.ceil(remainingCount * (sleepTime / 1000))
						timeString = readable(estimatedTime)

						if r and type(r) == "table" then
							r:setEmbed({
								title = emojis.loading .. " Updating Members...",
								description = "> I've updated the roles for **" .. completedCount .. "/" .. membercount .. "** members so far." .. "\n> -# " .. emojis.clock .. " **Estimated Time Remaining:** " .. timeString .. "",
								color = colors.blank
							})
						else
							r = interaction:reply({
								embed = {
									title = emojis.loading .. " Updating Members...",
									description = "> I've updated the roles for **" .. completedCount .. "/" .. membercount .. "** members so far." .. "\n> -# " .. emojis.clock .. " **Estimated Time Remaining:** " .. timeString .. "",
									color = colors.blank
								}
							})
						end
					end)()
				end

				updateMessage()

				local starttime = realtime()

				local fails = 0
				if inputType:lower() == "add" then
					for _, member in pairs(guild.members) do
						local success, err = safeRoleOperation(member, role.id, "add", nil, "/role all add command used by @" .. interaction.member.username)
						if not success then
							fails = fails + 1
						end

						completedCount = completedCount + 1
						if completedCount >= nextUpdateAt then
							updateMessage()
							nextUpdateAt = nextUpdateAt + updateThreshold
						end

						timer.sleep(sleepTime)
					end
				elseif inputType:lower() == "remove" then
					for _, member in pairs(guild.members) do
						local success, err = safeRoleOperation(member, role.id, "remove", nil, "/role all remove command used by @" .. interaction.member.username)
						if not success then
							fails = fails + 1
						end

						completedCount = completedCount + 1
						if completedCount >= nextUpdateAt then
							updateMessage()
							nextUpdateAt = nextUpdateAt + updateThreshold
						end

						timer.sleep(sleepTime)
					end
				end

				cooldown[guild.id] = os.time()

				local elapsedTime = realtime() - starttime
				local endTime = readable(elapsedTime)

				if type(r) == "table" then
					r:setEmbed({
						title = emojis.success .. " Updated Members",
						description = "> I successfully updated the roles for all **" .. membercount .. "** members." .. "\n> -# " .. emojis.clock .. " **Elapsed Time:** " .. endTime .. ((fails > 0 and "\n> " .. emojis.fail .. " **Failed Operations:** " .. fails) or ""),
						color = colors.success
					})
				else
					interaction:reply({
						embed = {
							title = emojis.success .. " Updated Members",
							description = "> I successfully updated the roles for all **" .. membercount .. "** members." .. "\n> -# " .. emojis.clock .. " **Elapsed Time:** " .. endTime .. ((fails > 0 and "\n> " .. emojis.fail .. " **Failed Operations:** " .. fails) or ""),
							color = colors.success
						}
					})
				end
			else
				interaction:fail("You must provide a valid role.", nil, true)
			end
		end
	end
}
