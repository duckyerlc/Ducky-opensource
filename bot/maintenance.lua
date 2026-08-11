local MAINTENANCE = {
	status = "🔨 ・ Ongoing maintenance",
	message = "<:ducky:1259003248266711081> **Ducky** is currently under maintenance for a **stability**. This interaction is unavailable at this time. There is **no ETA**."
}

local startl = 0

print("[Ducky] | Initializing SECRETS...")
startl = os.clock()
local SECRETS = require("secrets")
_G.SECRETS = SECRETS
print("[Ducky] | Initialized SECRETS in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing Discordia...")
startl = os.clock()
local discordia = require("discordia")
_G.discordia = discordia
print("[Ducky] | Initialized Discordia in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing discordia-components...")
startl = os.clock()
require("discordia-components")
print("[Ducky] | Initialized discordia-components in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing discordia-textchat...")
startl = os.clock()
require("discordia-textchat")
print("[Ducky] | Initialized discordia-textchat in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing discordia-voice-plus...")
startl = os.clock()
require("discordia-voice-plus")
print("[Ducky] | Initialized discordia-voice-plus in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing discordia-modals...")
startl = os.clock()
local dmodals = require("discordia-modals")
_G.dmodals = dmodals
print("[Ducky] | Initialized discordia-modals in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing discordia-slash...")
startl = os.clock()
local dslash = require("discordia-slash")
_G.dslash = dslash
print("[Ducky] | Initialized discordia-slash in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing discordia-slash tools...")
startl = os.clock()
local tools = dslash.util.tools()
_G.tools = tools
print("[Ducky] | Initialized discordia-slash tools in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing Discordia.extensions()...")
startl = os.clock()
discordia.extensions()
print("[Ducky] | Initialized Discordia.extensions() in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing querystring...")
startl = os.clock()
local querystring = require("querystring")
_G.querystring = querystring
print("[Ducky] | Initialized querystring in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing Client...")
startl = os.clock()
local Client = discordia.Client({
	logFile = "",
	routeDelay = 0,
	largeThreshold = 10,
	maxRetries = 2,
	dateTime = "%x @ %I:%M:%S%p",
	suppressUnhandledGatewayEvents = true
})
Client:useApplicationCommands()
Client:enableAllIntents()
Client:disableIntents(discordia.enums.gatewayIntent.guildPresences)
_G.Client = Client
print("[Ducky] | Initialized Client in " .. (os.clock() - startl) .. " seconds.\n")

_G.emojis = {
	success = "<:success:1362343220096274530>",
	fail = "<:fail:1362339147494330440>",
	yeswhite = "<:yeswhite:1267876743423983678>",
	nowhite = "<:nowhite:1267876758494122177>",
	warning = "<:warning:1362344025948028938>",
	loading = "<a:loading:1362341012055265362>",
	beta = "<:be:1485289475406827590><:ta:1485289474375159889>",
	alpha = "<:alpha1:1266945879030497382><:alpha2:1266945892674568213>",
	quack = "<:quack:1362342057204514947>",
	duckyplus = "<:duckyplus:1362338075795001424>",
	ducky = "<:ducky:1259003248266711081>",
	left = "<:left:1362340643376074762>",
	right = "<:right:1362342488412520448>",
	bulletPoint = "-",
	bulletPointSpacing = "  ",
	bulletPointSpacing2 = "    ",
	settings = "<:settings:1362342928814702683>",
	moderate = "<:moderate:1362341154363801853>",
	support = "<:support:1396115109436198932>",
	log = "<:log:1388355844785176647>",
	game = "<:game:1388388391359484005>",
	wave = "<:wave:1362344200078626966>",
	roblox = "<:roblox:1362342636794417232>",
	chat = "<:chat:1362335853325582346>",
	role = "<:role:1271487267797729355>",
	channel = "<:channel:1271489699914977291>",
	member = "<:member:1271508998310461472>",
	emoji = "<:emoji:1271509169668751360>",
	document = "<:document:1307759713366310953>",
	pong = "<:pong:1335446815335514113>",
	pings = "<:pings:1362341496866476032>",
	delete = "<:delete:1362336695533436938>",
	edit = "<:edit:1362338620844933130>",
	suggestion = "<:suggestion:1362343471628947516>",
	suggester = "<:suggester:1427301332464697547>",
	reminder = "<:reminder:1362342324637532170>",
	pause = "<:pause:1362341334542844024>",
	play = "<:play:1362341631122079754>",
	stop = "<:stop:1362343094770601994>",
	counting = "<:counting:1362336545281151067>",
	timeout = "<:timeout:1277760307632279583>",
	kick = "<:kick:1277760553884057601>",
	ban = "<:ban:1277760353047941204>",
	clock = "<:clock:1310252672334696531>",
	link = "<:link:1279498351565606993>",
	unlink = "<:unlink:1279498367977783429>",
	blacklist = "<:blacklist:1362334784075993109>",
	plus = "<:plus:1279801788215853179>",
	minus = "<:minus:1279801815486959696>",
	add = "<:add:1279801721484480522>",
	subtract = "<:subtract:1279801756586348544>",
	lock = "<:lock:1307723440739844106>",
	unlock = "<:unlock:1307723473124327497>",
	guild = "<:guild:1281641990823481344>",
	pin = "<:pin:1307376204956958792>",
	protect = "<:protect:1307345410003701830>",
	text = "<:text:1289302246613323817>",
	image = "<:image:1289302951315116102>",
	paintbrush = "<:paintbrush:1289306340266737795>",
	art = "<:art:1289306815753883669>",
	json = "<:json:1289367215711195230>",
	ticket = "<:ticket:1289552484175450143>",
	error = "<:error:1362338773802680410>",
	import = "<:import:1289938661642735626>",
	export = "<:export:1289938824813740192>",
	founder = "<:founder:1362339414440673441>",
	executive = "<:executive:1362338992023928852>",
	developer = "<:developer:1362336884663255060>",
	inspiration = "<:inspiration:1362340319558897684>",
	contributor = "<:contributor:1362336340917747832>",
	affiliate = "<:affiliate:1362334249482588291>",
	partner = "<:partner:1362337180646641805>",
	quickfix = "<:quickfix:1362342182207619203>",
	search = "<:search:1427301426169905232>",
	duckyoutline = "<:duckyoutline:1362337895653970000>",
	duckyexperimental = "<:duckyexperimental:1390234431809388614>",
	discordStaff = "<:discordStaff:1362337518149832704>",
	bughunter = "<:bughunter:1427301322595631146>",
	activeDeveloper = "<:activeDeveloper:1362333935534608384>",
	chart = "<:chart:1362335657187479562>",
	boosting = "<:boosting:1292589883218464830>",
	power = "<:power:1428485958042648687>",
	hiya = "<a:hiya:1362340049429069927>",
	skull = "<:skull:1305572041533030410>",
	modcall = "<:modcall:1305843426171949170>",
	shop = "<:shop:1307345435513323670>",
	mail = "<:mail:1409192124598976604>",
	gift = "<:gift:1307345124816195606>",
	send = "<:send:1307344611550691430>",
	key = "<:key:1307376165991878686>",
	filter = "<:filter:1307376515020750979>",
	reload = "<:reload:1307376599188115547>",
	cloud = "<:cloud:1307376691852873770>",
	location = "<:location:1307376783586492476>",
	draft = "<:draft:1307725166415187979>",
	network = "<:network:1307377091523772466>",
	desktop = "<:desktop:1307377262034685952>",
	mobile = "<:mobile:1307377216786665492>",
	folder = "<:folder:1307377389159977080>",
	vehicle = "<:vehicle:1307716500290932736>",
	vehiclelocked = "<:vehiclelocked:1307723881628569633>",
	eye = "<:eye:1307725838577438831>",
	livery = "<:livery:1307726710686482553>",
	box = "<:box:1307759299199762534>",
	bookmark = "<:bookmark:1307767942875709480>",
	casesensitive = "<:casesensitive:1307773844878000129>",
	person = "<:person:1310251085205606430>",
	people = "<:people:1310251126490140752>",
	book = "<:book:1310251033745821776>",
	list = "<:list:1310251681119731722>",
	competitor = "<:competitor:1362336133790437376>",
	board = "<:board:1313674176128745512>",
	robux = "<:robux:1362342748581007451>",
	rename = "<:rename:1323269042659659836>",
	DOT = "<:DOT:1324331258733531229>",
	Fire = "<:Fire:1324331278350291025>",
	Sheriff = "<:Sheriff:1324331294024536106>",
	Police = "<:Police:1324331309207785552>",
	Criminal = "<:Criminal:1324414770266374226>",
	flag = "<:flag:1324399240855945297>",
	avatar = "<:avatar:1324544337056497725>",
	Bloxlink = "<:Bloxlink:1330190151141294162>",
	star = "<:star:1486443536995057685>",
	halfstar = "<:halfstar:1486443268311875755>",
	emptystar = "<:emptystar:1486443534188806325>",
	web = "<:web:1362344291007205480>",
	space = " ",
	AceOfHearts = "<:AceofHearts:1358086785959465082>",
	AceOfSpades = "<:AceofSpades:1358086799565520956>",
	AceOfDiamonds = "<:AceofDiamonds:1358086812622524456>",
	AceOfClubs = "<:AceofClubs:1358086823137644574>",
	TwoOfHearts = "<:2ofHearts:1358086928955605033>",
	TwoOfDiamonds = "<:2ofDiamonds:1358086940494401696>",
	TwoOfSpades = "<:2ofSpades:1358086955551817748>",
	TwoOfClubs = "<:2ofClubs:1358086965647638739>",
	ThreeOfClubs = "<:3ofClubs:1358086976921665696>",
	ThreeOfDiamonds = "<:3ofDiamonds:1358086991748792330>",
	ThreeOfHearts = "<:3ofHearts:1358087003375276082>",
	ThreeOfSpades = "<:3ofSpades:1358087033481986280>",
	FourOfClubs = "<:4ofClubs:1358087058870243439>",
	FourOfDiamonds = "<:4ofDiamonds:1358087069263597710>",
	FourOfHearts = "<:4ofHearts:1358087077962711160>",
	FourOfSpades = "<:4ofSpades:1358087087332524292>",
	FiveOfClubs = "<:5ofClubs:1358087095406825652>",
	FiveOfDiamonds = "<:5ofDiamonds:1358087104193757184>",
	FiveOfHearts = "<:5ofHearts:1358087114348171545>",
	FiveOfSpades = "<:5ofSpades:1358087122866667734>",
	SixOfDiamonds = "<:6ofDiamonds:1358087130923925716>",
	SixOfClubs = "<:6ofClubs:1358087146975526922>",
	SixOfHearts = "<:6ofHearts:1358087157230862418>",
	SixOfSpades = "<:6ofSpades:1358087168115081488>",
	SevenOfClubs = "<:7ofClubs:1358087179133390898>",
	SevenOfDiamonds = "<:7ofDiamonds:1358087187878383797>",
	SevenOfHearts = "<:7ofHearts:1358087199379427360>",
	SevenOfSpades = "<:7ofSpades:1358087241288650932>",
	EightOfClubs = "<:8ofClubs:1358087251476746412>",
	EightOfDiamonds = "<:8ofDiamonds:1358087258783092736>",
	EightOfHearts = "<:8ofHearts:1358087272041287782>",
	EightOfSpades = "<:8ofSpades:1358087284481851547>",
	NineOfClubs = "<:9ofClubs:1358087305549578475>",
	NineOfDiamonds = "<:9ofDiamonds:1358087318845784155>",
	NineOfHearts = "<:9ofHearts:1358087327561551882>",
	NineOfSpades = "<:9ofSpades:1358087336507867413>",
	TenOfClubs = "<:10ofClubs:1358087348608303285>",
	TenOfDiamonds = "<:10ofDiamonds:1358087357961867385>",
	TenOfHearts = "<:10ofHearts:1358087365838639204>",
	TenOfSpades = "<:10ofSpades:1358087374424248451>",
	JackOfClubs = "<:JackofClubs:1358087403700486236>",
	JackOfDiamonds = "<:JackofDiamonds:1358087410830803156>",
	JackOfHearts = "<:JackofHearts:1358087418380685453>",
	JackOfSpades = "<:JackofSpades:1358087425900937376>",
	KingOfClubs = "<:KingofClubs:1358087434880946266>",
	KingOfDiamonds = "<:KingofDiamonds:1358087445731741738>",
	KingOfHearts = "<:KingofHearts:1358087454049046598>",
	KingOfSpades = "<:KingofSpades:1358087461384753279>",
	QueenOfClubs = "<:QueenofClubs:1358087473602887761>",
	QueenOfDiamonds = "<:QueenofDiamonds:1358087482633228608>",
	QueenOfHearts = "<:QueenofHearts:1358087490526908598>",
	QueenOfSpades = "<:QueenofSpades:1358087499473223772>",
	CardBack = "<:CardBack:1358086451836747806>",
	backpack = "<:backpack:1358425724498739472>",
	smroll = "<a:smroll:1360384907192439096>",
	smplus = "<:smplus:1359117733786157166>",
	smexperimental = "<:smexperimental:1359117786634391682>",
	smducky = "<:smducky:1359117903584034816>",
	smdev = "<:smdev:1359117923154661416>",
	sale = "<:sale:1362341892540334251>",
	Blank = "<:Blank:1374565167752544337>",
	GrayA = "<:GrayA:1374559178336505856>",
	GrayB = "<:GrayB:1374557378162462782>",
	GrayC = "<:GrayC:1374557394453139598>",
	GrayD = "<:GrayD:1374557411167436892>",
	GrayE = "<:GrayE:1374557974676377660>",
	GrayF = "<:GrayF:1374558010550255748>",
	GrayG = "<:GrayG:1374558017063751701>",
	GrayH = "<:GrayH:1374558059879338004>",
	GrayI = "<:GrayI:1374558077277306982>",
	GrayJ = "<:GrayJ:1374558089147187251>",
	GrayK = "<:GrayK:1374558097200119909>",
	GrayL = "<:GrayL:1374558105735794698>",
	GrayM = "<:GrayM:1374558119438581831>",
	GrayN = "<:GrayN:1374558128502345878>",
	GrayO = "<:GrayO:1374558139411861584>",
	GrayP = "<:GrayP:1374558147481440286>",
	GrayQ = "<:GrayQ:1374558156390404156>",
	GrayR = "<:GrayR:1374558167832199288>",
	GrayS = "<:GrayS:1374558176296570941>",
	GrayT = "<:GrayT:1374558183305248850>",
	GrayU = "<:GrayU:1374558190506741791>",
	GrayV = "<:GrayV:1374558196206669944>",
	GrayW = "<:GrayW:1374558205421817906>",
	GrayX = "<:GrayX:1374558222299697193>",
	GrayY = "<:GrayY:1374558231371841599>",
	GrayZ = "<:GrayZ:1374558240213303296>",
	YellowA = "<:YellowA:1374559242907943002>",
	YellowB = "<:YellowB:1374559248897409125>",
	YellowC = "<:YellowC:1374559354530959431>",
	YellowD = "<:YellowD:1374559363989241917>",
	YellowE = "<:YellowE:1374559372407083018>",
	YellowF = "<:YellowF:1374559379424018483>",
	YellowG = "<:YellowG:1374559385002577971>",
	YellowH = "<:YellowH:1374559397623365692>",
	YellowI = "<:YellowI:1374559409686188103>",
	YellowJ = "<:YellowJ:1374559421564190811>",
	YellowK = "<:YellowK:1374559429231382658>",
	YellowL = "<:YellowL:1374559435191615508>",
	YellowM = "<:YellowM:1374559441944318004>",
	YellowN = "<:YellowN:1374559448361865356>",
	YellowO = "<:YellowO:1374559454611378306>",
	YellowP = "<:YellowP:1374559461968052284>",
	YellowQ = "<:YellowQ:1374559471443120268>",
	YellowR = "<:YellowR:1374559478334361721>",
	YellowS = "<:YellowS:1374559485166878750>",
	YellowT = "<:YellowT:1374559490292191393>",
	YellowU = "<:YellowU:1374559498399780874>",
	YellowV = "<:YellowV:1374559505227976835>",
	YellowW = "<:YellowW:1374559511313911918>",
	YellowX = "<:YellowX:1374559518209478706>",
	YellowY = "<:YellowY:1374559526434639902>",
	YellowZ = "<:YellowZ:1374559534139576450>",
	GreenA = "<:GreenA:1374558955564568660>",
	GreenB = "<:GreenB:1374558961197649952>",
	GreenC = "<:GreenC:1374558967518462044>",
	GreenD = "<:GreenD:1374558975978377216>",
	GreenE = "<:GreenE:1374558981418258442>",
	GreenF = "<:GreenF:1374558987311382589>",
	GreenG = "<:GreenG:1374558995771162737>",
	GreenH = "<:GreenH:1374559013039247411>",
	GreenI = "<:GreenI:1374559020114903091>",
	GreenJ = "<:GreenJ:1374559029866528808>",
	GreenK = "<:GreenK:1374559036284076072>",
	GreenL = "<:GreenL:1374559042672005160>",
	GreenM = "<:GreenM:1374559048657145946>",
	GreenN = "<:GreenN:1374559055926005791>",
	GreenO = "<:GreenO:1374559063471427686>",
	GreenP = "<:GreenP:1374559070513795092>",
	GreenQ = "<:GreenQ:1374559076922429462>",
	GreenR = "<:GreenR:1374559088213622784>",
	GreenS = "<:GreenS:1374559095159390229>",
	GreenT = "<:GreenT:1374559101685858364>",
	GreenU = "<:GreenU:1374559108669374524>",
	GreenV = "<:GreenV:1374559115761815666>",
	GreenW = "<:GreenW:1374559121398825102>",
	GreenX = "<:GreenX:1374559129166675988>",
	GreenY = "<:GreenY:1374559137177931818>",
	GreenZ = "<:GreenZ:1374559144748646502>",
	verified = "<:verified:1383094091243589674>",
	equals = "<:equals:1387781497481723955>",
	notequal = "<:notequal:1387782358941438063>",
	lessorequal = "<:lessorequal:1388074359213785138>",
	greaterorequal = "<:greaterorequal:1388074371305705593>",
	less = "<:less:1388074387508432926>",
	greater = "<:greater:1388074399722246284>",
	undo = "<:undo:1388247560539344989>",
	redo = "<:redo:1394136206769655898>",
	on = "<:on:1428488209712807946>",
	off = "<:off:1428488077990559845>",
	cycle = "<:cycle:1388380213661925517>",
	discord = "<:discord:1388386746844315738>",
	PRC = "<:PRC:1388387049882652792>",
	transfer = "<:transfer:1388387369497006161>",
	automation = "<:automation:1390176005217456158>",
	donation = "<:donation:1390233408281645117>",
	permission = "<:permission:1390302765925797909>",
	vertuo = "<:vertuo:1391625507577004123>",
	o7 = "<:o7:1391625499880591411>",
	goose = "<:goose:1391635445967880262>",
	music = "<:music:1392390638602944572>",
	line = "<:line:1394117623175843870>",
	swords = "<:swords:1399415988902039663>",
	qa = "<:qa:1427301246930255984>",
	invis = "<:invis:1421520794520916089>",
	thread = "<:thread:1421044263608909828>",
	merge = "<:merge:1428394375968456765>",
	dot = "・",
	target = "<:target:1436352976368308347>",
	map = "<:map:1478384445126873118>",
	license = "<:license:1486364562583322874>"
}

_G.colors = {
	blank = 0x403C44,
	success = 0x66FF66,
	fail = 0xFF6666,
	info = 0x5C8FFF,
	warning = 0xFFC72B,
	heavyred = 0xB51A00,
	error = 0xB51A00, -- alias for heavyred
	duckypluspink = 0xFF54F9,
	pink = 0xFF54F9, -- alias for duckypluspink
	duckyyellow = 0xF5FF82,
	yellow = 0xF5FF82, -- alias for duckyyellow
	pond = 0x38B6FF
}

Client:once("ready", function()
    Client:setActivity({
        name = "maintenance",
        state = MAINTENANCE.status or "🔨・Ongoing maintenance",
        type = 4
    })

    Client:setStatus(discordia.enums.status.idle)
end)

Client:on("messageCreate", function(message)
	if message.user.bot then
		return
	end
	if (not message.guild) or not message.member or not message.member.guild then
		return
	end

    if message.content:startswith("d!") then
        message:reply({
			embed = {
				color = colors.yellow,
				description = MAINTENANCE.message or "Ducky is currently under maintenance, join [**Ducky's Pond**](https://discord.gg/w2dNr7vuKP) for updates."
			}
		})
    end
end)

Client:on("slashCommand", function(interaction)
    interaction:reply({
		embed = {
			color = colors.yellow,
			description = MAINTENANCE.message or "Ducky is currently under maintenance, join [**Ducky's Pond**](https://discord.gg/w2dNr7vuKP) for updates."
		}
	}, true)
end)

Client:on("interactionCreate", function(interaction)
    interaction:reply({
		embed = {
			color = colors.yellow,
			description = MAINTENANCE.message or "Ducky is currently under maintenance, join [**Ducky's Pond**](https://discord.gg/w2dNr7vuKP) for updates."
		}
	}, true)
end)

Client:run("Bot " .. SECRETS.TOKEN)