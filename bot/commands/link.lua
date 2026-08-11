-- link.lua

local slashCommand = tools.slashCommand("link", "Link your Roblox account with Ducky, or unlink it if you are already linked.")









local words = {
	"Waddle",
	"Ducky",
	"Duck",
	"Versus",
	"Geese",
	"Goose",
	"Pond",
	"Water",
	"Grass",
	"Rubber",
	"Bathtub",
	"Yellow",
	"Blue"
}

local function generatePhrase(phraseLength, predicate)
	local phrase = ""

	math.randomseed(os.time() + math.floor(math.random() * 10000))
	
	for i = 1, phraseLength do
		phrase = phrase .. words[math.random(1,#words)] .. (((i < phraseLength) and " ") or "")
	end
	
	local meetspred = predicate and predicate(phrase)
	
	if not predicate then meetspred = true end
	
	return (meetspred and phrase) or generatePhrase(predicate)
end

return {
	name = "link",
	description = "Link your Roblox account with Ducky, or unlink it if you are already linked.",
	aliases = { "verify" },
	category = "Roblox",
	slashCommand = slashCommand,
	requiredPermissions = {},
	hybridCallback = function(interaction, args, command)
		local r = interaction:reply({embed = {
			description = emojis.loading,
			color = colors.blank
		}})
		
		local existingLink = sqldb:getLink(interaction.user.id)
		local linkedRoblox = existingLink and ropi.GetUser(existingLink.roblox)
		
		if existingLink and linkedRoblox and linkedRoblox.name and linkedRoblox.id and linkedRoblox.avatar then
			updateMember(interaction.member, "user updated themselves")
			r:update({
				embed = {
					title = emojis.roblox .. " Roblox Verification",
					description = "> " .. emojis.link .. " You are currently linked with **" .. linkedRoblox.name .. "**. If you would like to re-link with a different account, or unlink your Roblox account, press **Unlink** below.",
					color = colors.info,
					thumbnail = {url = linkedRoblox.avatar}
				},
				components = discordia.Components()
					:button({
						id = "unlink",
						label = "Unlink",
						emoji = resolvedEmojis.unlink,
						style = "danger"
					})
					:raw()
			})
			
			onComp(r, "button", nil, interaction.user.id, true, function(ia)
				local id = ia.data.custom_id
				
				if id == "unlink" then
					sqldb:unLink(interaction.member.id)

					r:update({
						embed = {
							title = emojis.roblox .. " Roblox Verification",
							description = "> " .. emojis.success .. " You have been successfully unlinked from **" .. linkedRoblox.name .. "**.",
							color = colors.success
						},
						components = {}
					})
					return true
				end
			end)
		else
			local authurl = "https://duckybot.xyz/link"
			r:update({
				embed = {
					title = emojis.roblox .. " Roblox Verification",
					description = "> You are not linked to a Roblox account. Press " .. emojis.link .. " **Link** below to link one.\n> -# *Having issues? Try using " .. emojis.roblox .. " **Legacy Verification**.*",
					color = colors.info
				},
				components = discordia.Components()
					:button({
						url = authurl,
						label = "Link",
						emoji = resolvedEmojis.link,
						style = "link",
					})
					:button({
						label = "Legacy Verification",
						emoji = resolvedEmojis.roblox,
						style = "secondary",
						id = "legacy"
					})
					:raw()
			})

			local rblx = nil
			local phrase = nil

			onComp(r, nil, nil, interaction.user.id, false, function(ia)
				local id = ia.data.custom_id

				if id == "legacy" then
					ask(ia, "Roblox Username", "Enter your Roblox username...", nil, nil, "short", true, nil, function(_, mia, response)
						if mia then
							if response and response ~= "" then
								rblx = ropi.SearchUser(response)

								if rblx then
									mia:updateDeferred(true)
									phrase = generatePhrase(7)

									r:update({
										embed = {
											title = emojis.roblox .. " Roblox Verification",
											description = "> Alright, **" .. rblx.name .. "**! Below, I have generated a phrase for you. Please place this phrase somewhere in your Roblox account's description. Once you have placed it into your description, press " .. emojis.yeswhite .. " **Done** below.\n```\n" .. phrase .. "```\n-# " .. emojis.right .. " If the phrase gets tagged, press **Regenerate Phrase** below.",
											thumbnail = {
												url = rblx.avatar
											},
											color = colors.info
										},
										components = discordia.Components()
											:button({
												id = "done",
												label = "Done",
												emoji = resolvedEmojis.yeswhite,
												style = "success"
											})
											:button({
												id = "cancel",
												label = "Cancel",
												emoji = resolvedEmojis.nowhite,
												style = "danger"
											})
											:button({
												url = rblx.profile,
												label = "Go to Profile",
												style = "link",
												emoji = resolvedEmojis.roblox
											})
											:button({
												id = "regenerate",
												label = "Regenerate Phrase",
												style = "secondary",
												emoji = resolvedEmojis.settings
											})
									})
								else
									return mia:fail("I could not find that user.", nil, true)
								end
							else
								return mia:fail("You must provide your Roblox username.", nil, true)
							end
						end
					end)
				elseif id == "regenerate" and rblx then
					phrase = generatePhrase(7)
					ia:update({
						embed = {
							title = emojis.roblox .. " Roblox Verification",
							description = "> Alright, **" .. rblx.name .. "**! Below, I have generated a phrase for you. Please place this phrase somewhere in your Roblox account's description. Once you have placed it into your description, press " .. emojis.yeswhite .. " **Done** below.\n```\n" .. phrase .. "```\n-# " .. emojis.right .. " If the phrase gets tagged, press **Regenerate Phrase** below.",
							thumbnail = {
								url = rblx.avatar
							},
							color = colors.info
						},
						components = discordia.Components()
							:button({
								id = "done",
								label = "Done",
								emoji = resolvedEmojis.yeswhite,
								style = "success"
							})
							:button({
								id = "cancel",
								label = "Cancel",
								emoji = resolvedEmojis.nowhite,
								style = "danger"
							})
							:button({
								url = rblx.profile,
								label = "Go to Profile",
								style = "link",
								emoji = resolvedEmojis.roblox
							})
							:button({
								id = "regenerate",
								label = "Regenerate Phrase",
								style = "secondary",
								emoji = resolvedEmojis.settings
							})
					})
				elseif id == "done" and rblx and phrase then
					rblx = ropi.GetUser(rblx.id, true)
					local desc = rblx.description or ""

					if desc:find(phrase) then
						local s, e = sqldb:link(interaction.member, rblx.id)

						if s then
							ia:update({
								embed = {
									title = emojis.roblox .. " Roblox Verification",
									color = colors.success,
									thumbnail = {
										url = rblx.avatar
									},
									description = "> " .. emojis.success .. " You have been successfully linked with **" .. rblx.name .. "**."
								},
								components = {}
							})
							return true
						else
							ia:fail(e or "An unknown error occurred. Please try again later.", nil, true)
							return
						end
					else
						ia:fail("It does not look like the phrase is in your description.", nil, true)
						return
					end
				elseif id == "cancel" then
					ia:update({
						embed = {
							title = emojis.roblox .. " Roblox Verification",
							description = "> " .. emojis.fail .. " This action has been canceled.",
							color = colors.fail
						},
						components = {}
					})
					return true
				end
			end)

			_G.DuckyAPI:waitFor("userLinked", nil, function(discord, roblox)
				if discord.id == interaction.user.id then
					rblx = roblox
					return true
				else
					return false
				end
			end)

			if rblx and rblx.name and rblx.avatar then
				r:update({
					embed = {
						title = emojis.roblox .. " Roblox Verification",
						description = "> " .. emojis.success .. " You have been successfully linked with **" .. rblx.name .. "**.",
						color = colors.success,
						thumbnail = {url = rblx.avatar}
					},
					components = {}
				})
			end
		end
	end
}
