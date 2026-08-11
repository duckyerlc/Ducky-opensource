-- test.lua

return {
    name = "test",
    description = "Testing command which changes purposes sometimes :D",
    aliases = {},
    category = "Utility",
    requiredPermissions = {"QUALITY_ASSURANCE"},
    hybridCallback = function(interaction, args)
        return interaction:warning("nuh")
    end
}
