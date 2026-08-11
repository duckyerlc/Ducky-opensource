-- wiki.lua
return {
    name = "wiki",
    description = "Get the Discordia wiki page for the class/object, if specified.",
    aliases = {"dia", "discordia"},
    category = "Utility",
    slashCommand = nil,
    requiredPermissions = {"BOT_DEVELOPER"},
    callback = function(message, args)
        local map = {
            ["dia"] = "<https://github.com/SinisterRectus/Discordia/wiki",
            ["discordia"] = "<https://github.com/SinisterRectus/Discordia/wiki",
            ["comps"] = "<https://github.com/Bilal2453/discordia-components/wiki",
            ["components"] = "<https://github.com/Bilal2453/discordia-components/wiki",
            ["interactions"] = "<https://github.com/Bilal2453/discordia-interactions/wiki",
            ["ias"] = "<https://github.com/Bilal2453/discordia-interactions/wiki",
            ["ia"] = "<https://github.com/Bilal2453/discordia-interactions/wiki",
            ["slash"] = "<https://github.com/GitSparTV/discordia-slash/wiki",
            ["modals"] = "<https://github.com/GitSparTV/discordia-modals/wiki",
            ["modal"] = "<https://github.com/GitSparTV/discordia-modals/wiki"
        }
        local url = map[args[1]]
        local noarg = false
        if not url then noarg = true; url = map["discordia"] end
        if noarg then
            url = url .. "/" .. string.capitalize(args[1] or "") .. ">"
        else
            url = url .. "/" .. string.capitalize(args[2] or "") .. ">"
        end
        return message:reply(url)
    end
}