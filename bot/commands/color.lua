-- color.lua
local slashCommand = tools.slashCommand("color", "Use Ducky's color utility.")
local subcmd = tools.subCommand("view", "View a color via hex code.")
local option = tools.string("hexcode", "The hex code of the color to view."):setRequired(true)
subcmd = subcmd:addOption(option)
slashCommand = slashCommand:addOption(subcmd)
local subcmd = tools.subCommand("random", "Generate a random color and view information on it.")
slashCommand = slashCommand:addOption(subcmd)

local Color = discordia.Color
local fromHex = Color.fromHex

local previewRes = {3000, 200}
local iconRes = {100, 100}

local API = {}

API.baseURL = "https://www.thecolorapi.com"

function API:get(url, headers)
	if not headers then headers = {{"Content-Type", "application/json"}} end
	local res, body = http.request("GET", API.baseURL .. url, headers)
	body = body and json.decode(body)
	return body
end

function API:colorFromHex(hex)
	return API:get("/id?format=json&hex=" .. hex)
end

function API:randomColor()
	local hex = string.format("%06X", math.random(0, 0xFFFFFF))
	return API:get("/id?format=json&hex=" .. hex), hex
end

return {
    name = "color",
    description = "Use Ducky's color utility.",
    aliases = {
		"colour"
	},
    category = "Utility",
	subcommands = {
		"view",
		"random"
	},
    slashCommand = slashCommand,
	requiredPermissions = {},
    hybridCallback = function(interaction, args, command, subcmd)
		if not command then
			if not (subcmd == "view" or subcmd == "random") then
				subcmd = "view"
			else
				table.remove(args, 1)
			end
		end

		--if true then
		--	return interaction:warning("This command is temporary unavailable due to regional API restrictions.", nil, true)
		--end
		
		if subcmd == "view" then
			local hex = (args and args.hexcode) or (args and args[1])
			if not hex then
				return interaction:fail("You must provide the hex code of the color to view.", nil, true)
			end

			hex = tostring(hex):gsub("^#", ""):upper()

			if not hex:match("^%x%x%x%x%x%x$") and not hex:match("^%x%x%x$") then
				return interaction:fail("That hex code is invalid.", nil, true)
			end

			if hex:match("^%x%x%x$") then
				hex = hex:sub(1,1):rep(2) .. hex:sub(2,2):rep(2) .. hex:sub(3,3):rep(2)
			end

			local color = fromHex(hex)
			if not color then
				if _G.colors and _G.colors[tostring(hex)] then
					color = Color(_G.colors[tostring(hex)])
				else
					return interaction:fail("That hex code is invalid.", nil, true)
				end
			end

			local DATA = API:colorFromHex(hex)
			local colorname = (DATA and DATA.name and DATA.name.value) or "Unknown"
			local rgb = DATA and DATA.rgb
			local RGBString = (rgb and rgb.r and rgb.g and rgb.b and rgb.r .. ", " .. rgb.g .. ", " .. rgb.b) or emojis.fail

			interaction:reply({
				embed = {
					title = emojis.paintbrush .. " " .. colorname,
					description = emojis.right .. " **Hex Code:** `" .. color:toHex() .. "`\n" .. emojis.right .. " **RGB Code:** " .. RGBString .. "\n-# " .. emojis.right .. " Color names are provided by the [**thecolorapi.com**](https://www.thecolorapi.com/id?hex=" .. hex .. ") community.",
					color = color.value,
					image = {url = "https://singlecolorimage.com/get/" .. color:toHex():usub(2) .. "/" .. previewRes[1] .. "x" .. previewRes[2]}
				}
			})
		elseif subcmd == "random" then
			local c = (args and args[2] and tonumber(args[2]) and tonumber(args[2]) < 5 and tonumber(args[2])) or 1
			for i = 1, c do
				local DATA, hex = API:randomColor()

				hex = tostring(hex):gsub("^#", ""):upper()

				if not hex:match("^%x%x%x%x%x%x$") and not hex:match("^%x%x%x$") then
					return interaction:fail("That hex code is invalid.", nil, true)
				end

				if hex:match("^%x%x%x$") then
					hex = hex:sub(1,1):rep(2) .. hex:sub(2,2):rep(2) .. hex:sub(3,3):rep(2)
				end

				if not DATA or not DATA.hex or not DATA.name then
					return interaction:fail("An error occurred while requesting data from the color API.", nil, true)
				end

				hex = DATA.hex.clean or hex
				local color = fromHex(hex)
				local colorname  = DATA.name.value  or "Unknown"
				local rgb = DATA and DATA.rgb
				local RGBString = (rgb and rgb.r and rgb.g and rgb.b and rgb.r .. ", " .. rgb.g .. ", " .. rgb.b) or emojis.fail
			
				interaction:reply({
					embed = {
						title = emojis.paintbrush .. " " .. colorname,
						description = emojis.right .. " **Hex Code:** `" .. color:toHex() .. "`\n" .. emojis.right .. " **RGB Code:** " .. RGBString .. "\n-# " .. emojis.right .. " Color names are provided by the [**thecolorapi.com**](https://www.thecolorapi.com/id?hex=" .. hex .. ") community.",
						color = color.value,
						image = {url = "https://singlecolorimage.com/get/" .. color:toHex():usub(2) .. "/" .. previewRes[1] .. "x" .. previewRes[2]}
					}
				})
			end
		end
    end
}
