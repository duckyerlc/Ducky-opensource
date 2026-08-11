-- define.lua
local slashCommand = tools.slashCommand("define", "Fetch the dictionary definition of a word.")
slashCommand = slashCommand:addOption(tools.string("word", "The word to define."):setRequired(true))
slashCommand = slashCommand:addOption(tools.string("pos", "The part of speech to use."):setRequired(false))

return {
	name = "define",
	description = "Fetch the dictionary definition of a word.",
	aliases = {
		"dictionary",
		"definition",
		"definitions"
	},
	category = "Utility",
	slashCommand = slashCommand,
	requiredPermissions = {},
	hybridCallback = function(interaction, args, slash, subcmd)
		local query = (slash and args and args.word) or ((not slash) and args and args[1]) or nil
		query = query ~= nil and query ~= "" and query ~= " " and query:lower()
		if not query then
			return interaction:fail("You must provide a word to define.", nil, true)
		end
		
		local pos = (slash and args and args.pos) or ((not slash) and args and args[2])

		if query then
			local _, violate = sanitize(query, interaction.guild)

			if not violate then
				local function fetch(query, lower)
					if lower then
						query = query:lower()
					end

					local result, word = http.request("GET", "https://freedictionaryapi.com/api/v1/entries/en/" .. query)
					word = word and json.decode(word)

					if result and word and word.entries and next(word.entries) then
						return word
					elseif lower then
						return fetch(string.capitalize(query:lower()))
					end
				end

				local word = fetch(query, true)

				if word then
                    local pages = {}

                    for i, entry in pairs(word.entries) do
                        local pronunciation = table.find(entry.pronunciations, function(p)
							return table.find(p.tags, "US")
						end) or { text = word.word }

                        local synonyms = {}
						for _, synonym in pairs(table.chop(entry.synonyms, 3)) do
							local cleaned, violate = sanitize(synonym, interaction.guild)

							table.insert(synonyms, (((not violate) and (cleaned)) or (emojis.error .. " This synonym has been sanitized.")))
						end

						local antonyms = {}
						for _, antonym in pairs(table.chop(entry.antonyms, 3)) do
							local cleaned, violate = sanitize(antonym, interaction.guild)

							table.insert(antonyms, (((not violate) and (cleaned)) or (emojis.error .. " This antonym has been sanitized.")))
						end

                        local page = {
                            title = emojis.book .. " " .. word.word .. " (" .. entry.partOfSpeech .. ")",
                            description = emojis.right .. " **Pronunciation:** " .. pronunciation.text .. "\n"
                            .. emojis.right .. " **Synonyms:** " .. ((synonyms and next(synonyms) and ("\n" .. emojis.space .. emojis.right .. " " .. table.concat(synonyms, "\n" .. emojis.space .. emojis.right .. " "))) or emojis.fail) .. "\n"
							.. emojis.right .. " **Antonyms:** " .. ((antonyms and next(antonyms) and ("\n" .. emojis.space .. emojis.right .. " " .. table.concat(antonyms, "\n" .. emojis.space .. emojis.right .. " "))) or emojis.fail) .. "\n"
							.. emojis.right .. " **Definitions:** \n"
                            .. emojis.space .. emojis.right .. " " .. table.concatFn(entry.senses, "\n" .. emojis.space .. emojis.right .. " ", function(definition, i)
								local cleaned, violate = sanitize(definition.definition, interaction.guild)

                                return "**" .. i .. ".** " .. (((not violate) and (cleaned)) or (emojis.error .. " This definition has been sanitized."))
                            end) .. "\n"
							.. "-# " .. emojis.right .. " Definitions are provided by the [**freedictionaryapi.com**](https://freedictionaryapi.com) API.",
                            color = colors.info,
                            identifier = {
                                emoji = resolvedEmojis.book,
                                text = word.word .. " (" .. entry.partOfSpeech .. ")",
                                description = pronunciation.text
                            },
							entry = entry
                        }
                        
                        table.insert(pages, page)
                    end

					local start = 1

					if pos then
						for i, page in pairs(pages) do
							local entry = page.entry

							if entry.partOfSpeech:lower() == pos:lower() then
								start = i
								break
							end
						end
					end
                    
					return paginate(interaction, pages, interaction.user, {
                        clamp = false,
                        teleport = true,
						startPage = start
                    })
				else
					return interaction:fail("**" .. query .. "** could not be defined.", nil, true)
				end
			else
				return interaction:fail("The word you attempted to define was sanitized.", nil, true)
			end
		else
			return interaction:fail("You did not provide a word to define.", nil, true)
		end
	end
}
