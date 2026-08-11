-- sync.lua
return {
	name = "sync",
	description = "Synchronize the bot's commands.",
	aliases = {
		"synchronize"
	},
	category = "Utility",
	slashCommand = nil,
	requiredPermissions = {
		"BOT_DEVELOPER"
	},
	callback = function(message, args)
		local loadSlash = args[1] == "slash"
		local loadModules = args[1] == "modules"
		local slashToLoad = args[2]

		local r = message:reply({
			embed = {
				title = emojis.loading .. " Fetching Commits...",
				description = emojis.right .. " This may take a few seconds...",
				color = colors.blank
			}
		})

		local success, str = shell("git pull")

		if not success then
			return r:update({
				embed = {
					title = emojis.fail .. " Failed to Fetch Commits",
					description = emojis.right .. " The latest commits could not be fetched. Please try again later.",
					color = colors.fail
				}
			})
		end

		if str:find("modules") then loadModules = true end
		if str:find("main%.lua") or str:find("badwords%.lua") or str:find("watchduck%.lua") or str:find("profiler%.lua") or str:find("json%.lua") or str:find("sqlpg%.lua") or str:find("postgres%.lua") or str:find("backup%.lua") or str:find("restore%.lua") then
			r:update({
				embed = {
					title = emojis.warning .. " Rebooting...",
					description = emojis.right .. " An internal file has been changed. Ducky is now rebooting to apply the changes.",
					color = colors.warning
				}
			})

			prettyLog("GITHUB", "white", "Received commit containing changes to an internal file, rebooting...")
			utilityChannels.boots:send(emojis.developer .. " Received GitHub commit containing changes to an internal file, rebooting...\n-# " .. emojis.clock .. " <t:" .. os.time() .. ":T>")

			updateActivity("⏳ Rebooting...", "idle")
			return os.exit(1)
		elseif str:find("sqldb%.lua") then
			r:update({
				embed = {
					title = emojis.warning .. " Reloading SQLDB...",
					description = emojis.right .. " A SQLDB change was detected, reloading database...",
					color = colors.warning
				}
			})
			reloadSQLDB()
		end

		local emb = {
			title = emojis.loading .. " Synchronizing Commands...",
			description = emojis.right .. " This may take a few seconds...",
			color = colors.blank
		}
		if loadSlash then
			if slashToLoad then
				emb.description = emb.description .. "\n-# " .. emojis.right .. " `/" .. slashToLoad .. "` is being reconstructed."
			else
				emb.description = emojis.right .. " This may take a few minutes...\n-# " .. emojis.right .. " All slash commands being reconstructed."
			end
		end
		if loadModules then
			emb.title = emojis.loading .. " Synchronizing Modules..."
			emb.description = emojis.right .. " This may take a few seconds...\n-# " .. emojis.right .. " All modules are being reloaded."
		end

		r:update({
			embed = emb
		})

		local c, errors = _G.loadCommands(loadSlash, slashToLoad, loadModules)

		if not r then return end

		emb = {
			title = emojis.success .. " Synchronized Commands",
			description = emojis.right .. " " .. c .. " commands were synchronized successfully.",
			color = colors.success
		}

		if loadSlash then
			if slashToLoad then
				emb.description = emojis.right .. " `/" .. slashToLoad .. "` has been reconstructed."
			else
				emb.description = emojis.right .. " All slash commands have been reconstructed."
			end
		end
		if loadModules then
			emb.title = emojis.success .. " Synchronized Modules"
			emb.description = emojis.right .. " All modules have been reloaded."
		end

		if #errors > 0 then
			emb.description = emb.description .. "\n\n**Errors:**\n"
			for _, err in pairs(errors) do
				local emoji = ""
				if err.errorType == "Runtime" then
					emoji = _G.emojis.error
				elseif err.errorType == "Syntax" then
					emoji = _G.emojis.warning
				end
				emb.description = emb.description .. ">>> " .. emojis.right .. " " .. emoji .. " " .. err.errorType .. " error in `" .. err.fileName .. "`: " .. err.errorMessage .. "\n"
			end
			emb.color = _G.colors.fail
		end

		timer.sleep(500) -- I hate that unedits

		r:setEmbed(emb)
	end
}