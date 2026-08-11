-- exec.lua
return {
	name = "exec",
	description = "Execute a shell/terminal command.",
	aliases = {
		"sh",
		"shell",
		"execute"
	},
	category = "Utility",
	slashCommand = nil,
	requiredPermissions = {
		"BOT_DEVELOPER"
	},
	callback = function(message, args)
		local r = message:loading()
		local success, output = shell(table.concat(args, " "))
		
		if success then
			r:update({
				embed = {
					description = "```\n" .. output .. "```",
					color = colors.success
				}
			})
		else
			r:update({
				embed = {
					description = "```\n" .. output .. "```",
					color = colors.fail
				}
			})
		end
	end
}
