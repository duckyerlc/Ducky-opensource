-- reboot.lua

local colors, emojis = _G.colors, _G.emojis

return {
    name = "reboot",
    description = "Reboot Ducky.",
    aliases = {"rbt", "restart"},
    category = "Utility",
    slashCommand = nil,
    requiredPermissions = {"BOT_DEVELOPER"},
	hybridCallback = function(interaction, args)
		updateActivity("⏳ Rebooting...", "idle")
        local pull = args[1] and args[1]:lower() == "pull"

        local tosend = {
            embed = {
                description = emojis.loading .. " Rebooting...\n-# " .. emojis.right .. " This may take few seconds...",
                color = colors.blank
            }
        }

        if pull then
            table.remove(args, 1)
            tosend.embed.description = emojis.loading .. " Rebooting & pulling...\n-# This takes about 1m 30s seconds on average."
        end

        local reason = table.concat(args, " ")

        if reason == "" then reason = nil end

        local r = interaction:reply(tosend)

        local statusChannel = (_G.utilityChannels and _G.utilityChannels.status) or interaction.channel

		local statusMessage = statusChannel:send("[<t:" .. os.time() .. ":T>] - " .. emojis.loading .. " Rebooting" .. ((reason and " for " .. reason) or "") .. "...")
        utilityChannels.boots:send(emojis.cycle .. " **@" .. interaction.user.username .. "** has initiated a reboot.\n-# " .. emojis.clock .. " <t:" .. os.time() .. ":T>・" .. emojis.edit .. " " .. (reason or "N/A"))
        if statusMessage and statusMessage.id then
            sqldb:setUtils("reboot", statusMessage.id .. ":" .. r.channel.id .. ";" .. r.id, true)
        end

        if pull then
            coroutine.wrap(function()
                _G.spawn("cmd", {args = "/c", "git", "pull", "origin", "master"})
            end)()
        end

        if #modules > 0 then
			prettyLog("MODS", "cyan", "Stopping active modules...")
			for i, mod in pairs(modules) do
				if mod.Stop then
					prettyLog("MODS", "cyan", "Stopping module " .. mod.name .. "...")
					mod.Stop()
					prettyLog("MODS", "cyan", "Stopped module " .. mod.name)
				else
					prettyLog("MODS", "red", "Module " .. mod.name .. " cannot be stopped")
				end
			end
		end

		os.exit(1)
	end
}
