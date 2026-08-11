-- coinflip.lua
local slashCommand = tools.slashCommand("coinflip", "Flip a coin for heads or tails.")

return {
    name = "coinflip",
    description = "Flip a coin for heads or tails.",
    aliases = { "cf", "headsortails" },
    slashCommand = slashCommand,
    category = "Fun",
    hybridCallback = function(interaction, args, slash)
        math.randomseed(os.time() + math.floor(math.random() * 10000))

        local result = math.random(1, 2) == 1 and "heads" or "tails"

        local r = interaction:loading("Flipping...")

        timer.sleep(1500)

        r:update({
            embed = {
                description = emojis.quack .. " The coin landed on **" .. result .. "**.",
                color = colors.yellow
            }
        })
    end
}