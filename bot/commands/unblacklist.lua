-- unblacklist.lua




return {
    name = "unblacklist",
    description = "Unblacklist a user or guild from Ducky.",
    aliases = {},
    category = "Utility",
    slashCommand = nil,
    requiredPermissions = {"BOT_DEVELOPER"},
    callback = function(message, args)
		local id = args[1]

		if not id then
			return message:fail("An ID was not provided.")
		end

		local object = Client:getUser(id) or Client:getGuild(id)

		if not object then 
			return message:fail("No user or guild was found with the ID of `" .. id .. "`.")
		end
		
		if not blacklisted(object) then
			return message:fail("That user/guild is not blacklisted.")
		end

		local name

		if object.username then 
			name = "@" .. object.username
		else
			name = object.name
		end

		local succ, err = sqldb:removeBlacklist(id)

		if succ then
			local user = (class(object) == "User" and object) or (object.ownerId and Client:getUser(object.ownerId))
			local dms = user and user:getPrivateChannel()
			local dmed = false

			if dms then
				local s, e
				
				if class(object) == "User" then
					s, e = dms:send(emojis.success .. " You have been **unblacklisted** from " .. emojis.ducky .. " **Ducky**.")
				elseif class(object) == "Guild" then
					s, e = dms:send(emojis.success .. " Your server, **" .. object.name .. "**, has been **unblacklisted** from " .. emojis.ducky .. " **Ducky**.")
				end

				dmed = not not s
			end

			return message:success("**" .. name .. "** has been unblacklisted from " .. emojis.ducky .. " **Ducky**." .. (((not dmed) and "\n-# " .. emojis.right .. " The " .. ((class(object) == "User" and "user") or "guild's owner") .. " could not be notified.") or ""))
		else
			return message:fail("```" .. err .. "```")
		end
	end
}