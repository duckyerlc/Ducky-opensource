-- blacklist.lua
return {
    name = "blacklist",
    description = "Blacklist a user or guild from Ducky.",
    aliases = {},
    category = "Utility",
    slashCommand = nil,
    requiredPermissions = {"BOT_DEVELOPER"},
    callback = function(message, args)
        local id = args[1]

		if not id then 
			return message:fail("You must provide an ID.")
		end

		table.remove(args, 1)

		local reason = table.concat(args, " ")

		if (not reason) or (reason == "") then
			return message:fail("You must provide a reason for this blacklist.", nil, true)
		end

		local object = Client:getUser(id) or Client:getGuild(id)

		if not object then 
			return message:fail("No user or guild was found with the ID of **`" .. id .. "`**.", nil, true)
		end

		local name = (object.username and ("@" .. object.username)) or object.name
		
		local succ, err = sqldb:addBlacklist(id, reason)

		if succ then
			local user = (class(object) == "User" and object) or (object.ownerId and Client:getUser(object.ownerId))
			local dms = user and user:getPrivateChannel()
			local dmed = false

			if dms then
				local s, e
				
				if class(object) == "User" then
					s, e = dms:send(emojis.ban .. " You have been **blacklisted** from " .. emojis.ducky .. " **Ducky** for **" .. reason .. "**.\n-# " .. emojis.right .. " In order to appeal, open a " .. emojis.settings .. " **Management** ticket in [**Ducky's Pond**](https://duckybot.xyz/support).")
				elseif class(object) == "Guild" then
					s, e = dms:send(emojis.ban .. " Your server, **" .. object.name .. "**, has been **blacklisted** from " .. emojis.ducky .. " **Ducky** for **" .. reason .. "**.\n-# " .. emojis.right .. " In order to appeal, open a " .. emojis.settings .. " **Management** ticket in [**Ducky's Pond**](https://duckybot.xyz/support).")
				end

				dmed = not not s
			end

			return message:success("**" .. name .. "** has been blacklisted from " .. emojis.ducky .. " **Ducky** for **" .. reason .. "**." .. (((not dmed) and "\n-# " .. emojis.right .. " The " .. ((class(object) == "User" and "user") or "guild's owner") .. " could not be notified.") or ""), nil, true)
		else
			return message:fail("Failed to blacklist **" .. name .. "**: ```" .. err .. "```", nil, true)
		end
    end
}