-- wordle.lua
local slashCommand = tools.slashCommand("wordle", "Play a game of Wordle.")

return {
    name = "wordle",
    description = "Play a game of Wordle.",
    aliases = {},
    category = "Fun",
    slashCommand = slashCommand,
    requiredPermissions = {},
    hybridCallback = function(interaction, args, slash, subcmd)
        local game = {
            guesses = {},
            word = words[math.random(1, #words)],
            start = os.time()
        }

        local function validateGuess(guess)
            if guess:len() ~= 5 then
                return nil, "That word is not 5 letters."
            elseif not table.find(words, guess:upper()) then
                return nil, "That word is not in the word list."
            else
                return guess:upper()
            end
        end

        local function colorGuess(guess)
            guess = guess:upper()
            local word = game.word .. ""
            local colors = {}
            
            for pos = 1, 5 do
                local char = guess:usub(pos, pos)
                
                if word:usub(pos, pos) == char then
                    local c = word:find(char)
                    word = word:usub(0, c - 1) .. "_" .. word:usub(c + 1)
                    table.insert(colors, emojis["Green" .. char:upper()] or emojis.Blank)
                elseif word:find(char) then
                    local c = word:find(char)
                    word = word:usub(0, c - 1) .. "_" .. word:usub(c + 1)
                    table.insert(colors, emojis["Yellow" .. char:upper()] or emojis.Blank)
                else
                    table.insert(colors, emojis["Gray" .. char:upper()] or emojis.Blank)
                end
            end
            
            return table.concat(colors, "")
        end

        local r = interaction:loading()

        local tosend = {
            embed = {
                author = {
                    name = interaction.member.name .. " is playing Wordle",
                    icon_url = interaction.member.avatarURL
                },
                description = "",
                color = colors.info
            },
            components = discordia.Components()
                :button({
                    id = "guess",
                    label = "Guess",
                    style = "blurple"
                })
                :raw()
        }

        local function updateGame()
            tosend = {
                embed = {
                    author = {
                        name = interaction.member.name .. " is playing Wordle",
                        icon_url = interaction.member.avatarURL
                    },
                    description = "",
                    color = colors.info
                },
                components = discordia.Components()
                    :button({
                        id = "guess",
                        label = "Guess",
                        style = "blurple"
                    })
                    :raw()
            }

            for i = 1, 6 do
                if game.guesses[i] then
                    tosend.embed.description = tosend.embed.description .. colorGuess(game.guesses[i]) .. "\n"
                else
                    tosend.embed.description = tosend.embed.description .. emojis.Blank .. emojis.Blank .. emojis.Blank .. emojis.Blank .. emojis.Blank .. "\n"
                end
            end

            if game.guesses[#game.guesses] and game.guesses[#game.guesses]:upper() == game.word:upper() then --win
                tosend.embed.author = {
                    name = interaction.member.name .. " was playing Wordle",
                    icon_url = interaction.member.avatarURL
                }

                tosend.embed.description = tosend.embed.description .. "\n\n" .. emojis.success .. " You guessed the word in **" .. readable(os.time() - game.start) .. "** with **" .. #game.guesses .. " guesses**."
                tosend.embed.color = colors.success
                tosend.components = {}

                if game.connection then
                    Client:removeListener("messageCreate", game.connection)
                end
            elseif #game.guesses >= 6 then
                tosend.embed.author = {
                    name = interaction.member.name .. " was playing Wordle",
                    icon_url = interaction.member.avatarURL
                }

                tosend.embed.description = tosend.embed.description .. "\n\n" .. emojis.fail .. " The word was **" .. game.word .. "**."
                tosend.embed.color = colors.fail
                tosend.components = {}

                if game.connection then
                    Client:removeListener("messageCreate", game.connection)
                end
            end

            r:update(tosend)
        end

        updateGame()

        game.connection = Client:on("messageCreate", function(message)
            if message.channel and message.channel.id == interaction.channel.id and message.user and message.user.id == interaction.user.id and message.referencedMessage and message.referencedMessage.id == r.id then
                local guess, err = validateGuess(message.content)

                if guess then
                    table.insert(game.guesses, guess)
                    message:delete()
                    updateGame()
                else
                    message:fail(err) 
                end
            end
        end)

        onComp(r, nil, nil, interaction.user.id, false, function(ia)
            local id = ia.data.custom_id

            if id == "guess" then
                prompt(ia, "Guess Word", {
                    {
                        question = "Guess Word",
                        placeholder = "Enter a five-letter word...",
                        style = "short",
                        required = false
                    }
                }, function(mia, responses)
                    if mia then
                        if responses and responses["Guess Word"] then
                            local guess, err = validateGuess(responses["Guess Word"])

                            if guess then
                                table.insert(game.guesses, guess)
                                mia:updateDeferred(true)
                                updateGame()
                            else
                                mia:fail(err, nil, true)
                            end
                        end
                    end
                end, false)
            end
        end)
    end
}