print("[Ducky] | Starting...")
local startl = 0
local startdeps = os.clock()

local function timestamp(timestamp)
	timestamp = timestamp or os.time()
	return discordia.Date:fromSeconds(timestamp):toString("%x @ %I:%M:%S%p")
end

_G.timestamp = timestamp

local ansiColors = {
	black = 30,
	red = 31,
	darkRed = "38;5;88",
	green = 32,
	yellow = 33,
	blue = 34,
	purple = 35,
	cyan = 36,
	white = 37
}

_G.ansiColors = ansiColors

local function prettyLog(name, color, text)
	return print(timestamp() .. "   \27[" .. ansiColors[color] .. "m\27[1m" .. name .. "\27[0m" .. string.rep(" ", 8 - name:len()) .. " " .. text)
end

_G.prettyLog = prettyLog
----------------------------------------------------------------------------------------------------------------
-- print("[Ducky] | Initializing profiler...")
-- startl = os.clock()
-- local profilerUtil = require("utils/profiler")
-- local profiler = profilerUtil.new(5, 10, 10000)
-- profiler:start()
-- _G.profiler = profiler
-- print("[Ducky] | Initialized profiler in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
-- print("[Ducky] | Initializing MemProfiler...")
-- startl = os.clock()
-- local MemProfiler = require("mem_profiler")
-- _G.MemProfiler = MemProfiler
-- print("[Ducky] | Initialized MemProfiler in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
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
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing fs...")
startl = os.clock()
local fs = require("fs")
_G.fs = fs
print("[Ducky] | Initialized fs in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing json...")
startl = os.clock()
local json = require("json")
_G.json = json
print("[Ducky] | Initialized json in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing cjson...")
startl = os.clock()
local cjson = require("cjson")
_G.cjson = cjson
print("[Ducky] | Initialized cjson in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing timer...")
startl = os.clock()
local timer = require("timer")
_G.timer = timer
print("[Ducky] | Initialized timer in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing coro-spawn...")
startl = os.clock()
local spawn = require("coro-spawn")
_G.spawn = spawn
print("[Ducky] | Initialized coro-spawn in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing ERLua...")
startl = os.clock()
local erlua = require("erlua")
local ERLC = erlua.Client({
	globalKey = SECRETS.ERLC_GLOBAL_API_KEY,
	ttl = 30,
	offlineEmpty = true,
	ignoredErrorCodes = { ["3002"] = true, ["2002"] = true },
	dateTime = "%x @ %I:%M:%S%p"
})
_G.erlua = erlua
_G.ERLC = ERLC
print("[Ducky] | Initialized ERLua in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing ropi...")
startl = os.clock()
local ropi = require("ropi")
ropi.SetCookie(SECRETS.ROBLOSECURITY)
_G.ropi = ropi
print("[Ducky] | Initialized ropi in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing querystring...")
startl = os.clock()
local querystring = require("querystring")
_G.querystring = querystring
print("[Ducky] | Initialized querystring in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing uv...")
startl = os.clock()
local uv = require("uv")
_G.uv = uv
print("[Ducky] | Initialized uv in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing base64...")
startl = os.clock()
local base64 = require("base64")
_G.base64 = base64
print("[Ducky] | Initialized base64 in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing path...")
startl = os.clock()
local luvitPath = require("path")
_G.luvitPath = luvitPath
print("[Ducky] | Initialized path in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing coro-http...")
startl = os.clock()
local http = require("coro-http")
_G.http = http
print("[Ducky] | Initialized coro-http in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing luvit-http...")
startl = os.clock()
local luvithttp = require("http")
_G.luvithttp = luvithttp
print("[Ducky] | Initialized luvit-http in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
print("[Ducky] | Initializing sqlite3...")
startl = os.clock()
local sqlite3 = require("sqlite3")
_G.sqlite3 = sqlite3
print("[Ducky] | Initialized sqlite3 in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
startl = os.clock()
print("[Ducky] | Initializing sqlite3 database...")
local sqldb = require("sqldb")
_G.sqldb = sqldb
print("[Ducky] | Initialized sqlite3 database in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
startl = os.clock()
print("[Ducky] | Initializing badwords...")
local badwords = require("utils/badwords")
_G.badwords = badwords
print("[Ducky] | Initialized badwords in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
startl = os.clock()
print("[Ducky] | Initializing bit...")
local bit = require("bit")
_G.bit = bit
print("[Ducky] | Initialized bit in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
startl = os.clock()
print("[Ducky] | Initializing bit64...")
local bit64 = require("bit64")
_G.bit64 = bit64
print("[Ducky] | Initialized bit64 in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------
startl = os.clock()
print("[Ducky] | Initializing snowflake...")
local snowflake = require("snowflake")
_G.snowflake = snowflake
print("[Ducky] | Initialized snowflake in " .. (os.clock() - startl) .. " seconds.\n")
------------------------------------------------------------------------------------------------------------------

_G.uptime = 0
_G.version = "v1.7.0"

local commands = {}
local modules = {}

print("[Ducky] | Initializing enums and other dependencies...")
startl = os.clock()

math.randomseed(os.time() + math.floor(math.random() * 10000))

_G.duckyplusassets = {
	{
		id = "114637999112749",
		collectible = "fb1790ed-02ff-4fe8-a4de-8574b6920966",
		using = false
	},
	{
		id = "134199688741263",
		collectible = "e506784b-d589-4ea7-b829-d384e8caeb81",
		using = false
	}
}

_G.erlcCycleRunningGuilds = {}

local colors = {
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

_G.colors = colors

local emojis = {
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

local function resolveEmoji(emojistr)
	if (not emojistr) or (type(emojistr) ~= "string") then
		return
	end
	local emojisplit = string.split(emojistr, ":")
	if not emojisplit or not emojisplit[1] or (emojisplit[1] == "") or not emojisplit[2] or (emojisplit[2] == "") or not emojisplit[3] or (emojisplit[3] == "") then
		return
	end
	local name = emojisplit[2]
	local id = emojisplit[3]:usub(1, emojisplit[3]:len() - 1)
	local animated = emojistr:usub(2, 2) == "a"

	local resolved = {
		name = tostring(name),
		id = tostring(id),
		animated = animated,
		hash = tostring(name) .. ":" .. tostring(id),
		image = "https://cdn.discordapp.com/emojis/" .. tostring(id),
		raw = tostring(emojistr)
	}
	if animated then
		resolved.hash = "a:" .. resolved.hash
		resolved.image = resolved.image .. ".gif"
	else
		resolved.image = resolved.image .. ".png"
	end
	return resolved
end

local resolvedEmojis = {}

for i, e in pairs(emojis) do
	resolvedEmojis[i] = resolveEmoji(e)
end

_G.emojis = emojis
_G.resolvedEmojis = resolvedEmojis
_G.resolveEmoji = resolveEmoji

local ERLCsolutions = {
	[1001] = "An error occurred communicating with the Roblox server. This is most likely a Roblox issue.",
	[1002] = "An internal PRC API system error has occurred.",
	[2000] = "You have not provided a PRC API key to Ducky. Run `/setup` to provide one.",
	[2001] = "The PRC API key provided is invalid. Check to make sure it matches the one in your private server's settings.",
	[2002] = "The PRC API key provided is invalid or has expired. It has been removed from our database. Please make sure you use the one in your private server's settings.",
	[2003] = "Internal Error | Ducky's Global key is incorrect.",
	[2004] = "Your PRC API key is banned from using the PRC API.",
	[3001] = "You provided an invalid command.",
	[3002] = "The server has no players, and is therefore offline.",
	[4001] = "The resource is being ratelimited.",
	[4002] = "The command you are trying to run is restricted.",
	[4003] = "The message you are trying to send is prohibited.",
	[9998] = "The resource you are accessing is restricted.",
	[9999] = "The ERLC API module in your server is out of date. Please have all players leave the in-game server and try again.",
	[1000] = "The ERLC API is offline. This is out of our control, and you will have to wait until the ERLC API is back online."
}

_G.ERLCsolutions = ERLCsolutions

local utilityChannels = {}

print("[Ducky] | Initialized enums and other dependencies in " .. (os.clock() - startl) .. " seconds.\n")
print("[Ducky] | Dependencies loaded in " .. (os.clock() - startdeps) .. " seconds.")
print("[Ducky] | Loading utility functions...")
startl = os.clock()

local function loadCommands(loadSlash, slashToLoad, loadModules)
	startl = os.clock()
	commands = {}
	local c = 0
	local cmdFolder = fs.readdirSync("commands")
	local modulesFolder = fs.readdirSync("modules")

	local errors = {}

	if loadModules then
		local startloadm = os.clock()
		prettyLog("MODS", "cyan", "Loading modules...")
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
			modules = {}
		end

		local function startModule(path, name)
			prettyLog("MODS", "cyan", "Loading module " .. name .. "...")
			package.loaded[path] = nil

			local filestr, err = load(fs.readFileSync(path))
			if err then
				prettyLog("MODS", "red", "Syntax error in module " .. name .. ":" .. err)
				table.insert(errors, {
					fileName = name,
					errorType = "Syntax",
					errorMessage = err
				})
			else
				local success, mod = pcall(filestr)
				if not success then
					prettyLog("MODS", "red", "Runtime error in module " .. name .. ": " .. mod)
					table.insert(errors, {
						fileName = name,
						errorType = "Runtime",
						errorMessage = mod
					})
				else
					if not mod.disabled then
						table.insert(modules, mod)
						mod.Start()
						prettyLog("MODS", "cyan", "Loaded module " .. mod.name)
					else
						prettyLog("MODS", "yellow", "Module " .. mod.name .. " is disabled")
					end
				end
			end
		end

		for _, moduleCategory in pairs(modulesFolder) do
			if moduleCategory:endswith(".lua") then
				startModule("modules/" .. moduleCategory, moduleCategory)
			else
				local directory = "modules/" .. moduleCategory
				prettyLog("MODS", "cyan", "Loading module category " .. moduleCategory .. "...")
				for _, moduleFileName in pairs(fs.readdirSync("modules/" .. moduleCategory)) do
					startModule("modules/" .. moduleCategory .. "/" .. moduleFileName, moduleFileName)
				end
				prettyLog("MODS", "cyan", "Loaded module category " .. moduleCategory)
			end
		end
		_G.modules = modules
		prettyLog("MODS", "cyan", "All modules loaded in " .. (os.clock() - startloadm) .. "s")
	end

	for i, commandFileName in pairs(cmdFolder) do
		prettyLog("CMDS", "cyan", "Loading command " .. commandFileName)
		package.loaded["commands/" .. commandFileName] = nil

		local filestr, err = load(fs.readFileSync("commands/" .. commandFileName))
		if err then
			prettyLog("CMDS", "red", "Syntax error in command " .. commandFileName .. ": " .. err)
			table.insert(errors, {
				fileName = commandFileName,
				errorType = "Syntax",
				errorMessage = err
			})
		else
			local cmd = nil
			local success, err = pcall(function()
				cmd = filestr()
			end)
			if err then
				prettyLog("CMDS", "red", "Runtime error in command " .. commandFileName .. ": " .. err)
				table.insert(errors, {
					fileName = commandFileName,
					errorType = "Runtime",
					errorMessage = err
				})
			else
				table.insert(commands, cmd)
				c = c + 1
				prettyLog("CMDS", "cyan", "Loading command " .. cmd.name)
			end
		end
	end

	if loadSlash then
		if slashToLoad then
			for i, command in pairs(commands) do
				if command.name:lower() == slashToLoad:lower() then
					if command.slashCommand then
						prettyLog("SLSH", "cyan", "Loading slash command /" .. slashToLoad:lower() .. " ...")
						local s, e = Client:createGlobalApplicationCommand(command.slashCommand)
						if e then
							prettyLog("SLSH", "red", "Failed to load slash command /" .. slashToLoad:lower() .. ": " .. e)
						else
							prettyLog("SLSH", "cyan", "Loaded slash command /" .. slashToLoad:lower())
						end
					else
						prettyLog("SLSH", "red", "Command " .. command.name .. " does not support a slash command")
					end
				end
			end
		else
			prettyLog("SLSH", "cyan", "Loading slash commands...")
			for i, command in pairs(commands) do
				if command.slashCommand then
					prettyLog("SLSH", "cyan", "Loading slash command /" .. command.name .. " ...")
					local s, e = Client:createGlobalApplicationCommand(command.slashCommand)
					if e then
						prettyLog("SLSH", "red", "Failed to load slash command /" .. command.name .. ": " .. e)
					else
						prettyLog("SLSH", "cyan", "Loaded slash command /" .. command.name)
					end
				else
					prettyLog("SLSH", "red", "Command " .. command.name .. " does not support a slash command")
				end
			end
		end
	end

	_G.commands = commands
	_G.loadCommands = loadCommands

	prettyLog("CMDS", "cyan", "All commands loaded in " .. (os.clock() - startl) .. " seconds.")

	return c, errors
end

print("[Ducky] | Loading events...")
startl = os.clock()

Client:once("ready", function()
	_G.uptime = os.time()
	_G.duckysPond = Client:getGuild("")

	print("[Ducky] | Loading commands...")

	loadCommands(false, nil, true)

	print("Setting activity...")

	updateActivity()

	print("Setting utility channels...")

	utilityChannels = {
		development = duckysPond:getChannel(""),
		status = duckysPond:getChannel(""),
		supporters = duckysPond:getChannel(""),
		receipts = duckysPond:getChannel(""),
		database = duckysPond:getChannel(""),
		errors = duckysPond:getChannel(""),
		api = duckysPond:getChannel(""),
		guilds = duckysPond:getChannel(""),
		boots = duckysPond:getChannel(""),
		shards = duckysPond:getChannel(""),
		commands = duckysPond:getChannel(""),
		watcher = duckysPond:getChannel("")
	}

	_G.utilityChannels = utilityChannels

	local rebootMessage = sqldb:getUtils("reboot", true)
	if rebootMessage then
		print("Editing rebooting message...")
		local splitRebooting = string.split(rebootMessage, ":")
		local statusID = splitRebooting[1]
		local cmdID = splitRebooting[2]
		local cmdChannelID = cmdID and string.split(cmdID, ";")[1]
		local cmdMessageID = cmdID and string.split(cmdID, ";")[2]
		local statusMessage = utilityChannels and utilityChannels.status and utilityChannels.status:getMessage(statusID)
		local commandMessage = cmdChannelID and cmdMessageID and duckysPond:getChannel(cmdChannelID) and duckysPond:getChannel(cmdChannelID):getMessage(cmdMessageID)
		if statusMessage then
			local s, e = statusMessage:setContent("~~" .. statusMessage.content .. "~~\n[<t:" .. os.time() .. ":T>] - " .. emojis.success .. " Complete!")
			if s then
				print("Successfully edited rebooting message.")
			else
				print("Failed to edit rebooting message: " .. e)
			end
		end
		if commandMessage then
			local s, e = commandMessage:update({
				embed = {
					description = emojis.success .. " Complete!",
					color = colors.success
				}
			})
			if s then
				print("Successfully edited rebooting command message.")
			else
				print("Failed to edit rebooting command message: " .. e)
			end
		end
		sqldb:deleteUtils("reboot", true)
	end

	_G.logallnewobjs = true

	_G.version = _G.version .. " " .. runtime()

	coroutine.wrap(function()
		local count = 0
		local allConfigs = sqldb:getAllGuildConfigs()

		for id, config in pairs(allConfigs or {}) do
			if config then
				local changes = {}

				if config.erlccommandqueue and config.erlccommandqueue[1] and type(config.erlccommandqueue[1]) == "string" then
					changes.erlccommandqueue = "nil"
				end

				if config.erlccache and not config.erlccache.old then
					changes.erlccache = "nil"
				end

				if next(changes) then
					sqldb:set(id, changes, "TRANSFER")
				end
			end
		end
	end)()

	utilityChannels.boots:send(emojis.success .. " **" .. Client.user.name .. "** has booted in " .. os.clock() .. " seconds and is now ready.\n-# " .. emojis.clock .. " <t:" .. os.time() .. ":T>")
	print("Fully loaded Ducky " .. version .. " in " .. os.clock() .. " seconds.")
end)

local function getCommand(query)
	if not commands or not next(commands) then
		return nil, emojis.ducky .. " **Ducky** is currently booting. Please try again in a few seconds."
	end

	for i, command in pairs(commands) do
		if command.name:lower() == query then
			return command
		end

		for subcmd, alias in pairs(command.aliases or {}) do
			if type(alias) == "table" then
				for _, a in pairs(alias) do
					if a:lower() == query then
						return command, subcmd
					end
				end
			else
				if alias:lower() == query then
					return command
				end
			end
		end
	end

	return nil, "The command you are attempting to use has been removed or merged into another command. Please open a support thread via [**Ducky's Pond**](https://duckybot.xyz/support) for further assistance."
end

_G.getCommand = getCommand

local function getModule(query)
	for i, module in pairs(modules) do
		if module.name:lower() == query then
			return module
		end
	end
end

_G.getModule = getModule

local function isdev(member)
	return (table.find(SECRETS.DEV_ACCESS_IDS or {}, member.id) and true) or false
end

local perms = {
	["FOUNDER"] = function(member)
		return member.id == "598958193032560642" or "You are not the **Ducky Founder**."
	end,
	["EXECUTIVE"] = function(member)
		if isdev(member) then
			return true
		end
		local dsmember = duckysPond:getMember(member.id)
		if dsmember then
			if dsmember:hasRole("1268775087650111500") then
				return true
			end
		end

		return "You are not a member of the **Ducky Executive** team."
	end,
	["BOT_DEVELOPER"] = function(member)
		return isdev(member) or "You are not a member of the **Ducky Development** team."
	end,
	["WEB_DEVELOPER"] = function(member)
		if isdev(member) then
			return true
		end

		local dsmember = duckysPond:getMember(member.id)
		if dsmember then
			if dsmember:hasRole("1286472622984400946") then
				return true
			end
		end

		return "You are not a member of the **Ducky Web Development** team."
	end,
	["SUPPORT"] = function(member)
		if isdev(member) then
			return true
		end
		local dsmember = duckysPond:getMember(member.id)
		if dsmember then
			if dsmember:hasRole("1259747747091972116") then
				return true
			end
		end

		return "You are not a member of the **Ducky Support** team."
	end,
	["MANAGEMENT"] = function(member)
		if isdev(member) then
			return true
		end
		local dsmember = duckysPond:getMember(member.id)
		if dsmember then
			if dsmember:hasRole("1268774900735148135") or dsmember:hasRole("1268775087650111500") then
				return true
			end
		end

		return "You are not a member of the **Ducky Management** team."
	end,
	["DUCKY_STAFF"] = function(member)
		if isdev(member) then
			return true
		end
		local dsmember = duckysPond:getMember(member.id)
		if dsmember then
			if dsmember:hasRole("1259747806697099285") or dsmember:hasRole("1259747827337396265") then
				return true
			end
		end

		return "You are not a member of the **Ducky Staff** team."
	end,
	["DUCKY_PLUS_MEMBER"] = function(member)
		local active = sqldb:plusMember(member)

		if active then
			return true
		else
			return "You are not a " .. emojis.duckyplus .. " **Ducky Plus+** member."
		end
	end,
	["DUCKY_PLUS_GUILD"] = function(member)
		local active = sqldb:plusGuild(member.guild)

		if active then
			return true
		else
			return "This server is not a " .. emojis.duckyplus .. " **Ducky Plus+** server."
		end
	end,
	["QUALITY_ASSURANCE"] = function(member)
		if isdev(member) then
			return true
		end
		local dsmember = duckysPond:getMember(member.id)
		if dsmember then
			if dsmember:hasRole("1260070830180667402") then
				return true
			end
		end

		return "You are not a member of the **Ducky Quality Assurance** team."
	end,
	["DOCWRITER"] = function(member)
		if isdev(member) then
			return true
		end
		local dsmember = duckysPond:getMember(member.id)
		if dsmember then
			if dsmember:hasRole("1311330617824378940") then
				return true
			end
		end

		return "You are not a member of the **Ducky Docwriters** team."
	end,
	["MANAGE_SERVER"] = function(member)
		return member:hasPermission("manageGuild") or "You do not have the **Manage Server** permission."
	end,
	["SETUP"] = function(member)
		if sqldb:get(member.guild.id) then
			return true
		else
			return "You have not configured this server."
		end
	end,
	["MOD"] = function(member, config)
		if member:hasPermission("manageGuild") then
			return true
		end

		config = config or sqldb:get(member.guild.id)

		if config then
			if config.adminroles then
				for _, adminrole in pairs(config.adminroles) do
					if member:hasRole(adminrole) then
						return true
					end
				end
			end

			if config.modroles then
				for _, modrole in pairs(config.modroles) do
					if member:hasRole(modrole) then
						return true
					end
				end
			else
				return "You have not configured the **Discord Moderator** permission."
			end
		else
			return "You have not configured this server."
		end

		return "You are missing the **Discord Moderator** permission."
	end,
	["ADMIN"] = function(member, config)
		if member:hasPermission("manageGuild") then
			return true
		end

		config = config or sqldb:get(member.guild.id)

		if config then
			if config.adminroles then
				for _, adminrole in pairs(config.adminroles) do
					if member:hasRole(adminrole) then
						return true
					end
				end
			else
				return "You have not configured the **Discord Administrator** permission."
			end
		else
			return "You have not configured this server."
		end

		return "You are missing the **Discord Administrator** permission."
	end,
	["ERLC_LINKED"] = function(member, config)
		if config then
			if config.apikey then
				return true
			else
				return "You have not linked your ERLC server."
			end
		else
			return "You have not configured this server."
		end
	end,
	["ERLC_STAFF"] = function(member, config)
		if member:hasPermission("manageGuild") then
			return true
		end

		config = config or sqldb:get(member.guild.id)

		if config then
			if config.erlcmanagerroles then
				for _, erlcmanagerrole in pairs(config.erlcmanagerroles) do
					if member:hasRole(erlcmanagerrole) then
						return true
					end
				end
			end

			if config.erlcadminroles then
				for _, erlcadminrole in pairs(config.erlcadminroles) do
					if member:hasRole(erlcadminrole) then
						return true
					end
				end
			end

			if config.erlcstaffroles then
				for _, erlcstaffrole in pairs(config.erlcstaffroles) do
					if member:hasRole(erlcstaffrole) then
						return true
					end
				end
			else
				return "You have not configured the **ERLC Staff** permission."
			end
		else
			return "You have not configured this server."
		end

		return "You are missing the **ERLC Staff** permission."
	end,
	["ERLC_ADMIN"] = function(member, config)
		if member:hasPermission("manageGuild") then
			return true
		end

		config = config or sqldb:get(member.guild.id)

		if config then
			if config.erlcmanagerroles then
				for _, erlcmanagerrole in pairs(config.erlcmanagerroles) do
					if member:hasRole(erlcmanagerrole) then
						return true
					end
				end
			end

			if config.erlcadminroles then
				for _, erlcadminrole in pairs(config.erlcadminroles) do
					if member:hasRole(erlcadminrole) then
						return true
					end
				end
			else
				return "You have not configured the **ERLC Administrator** permission."
			end
		else
			return "You have not configured this server."
		end

		return "You are missing the **ERLC Administrator** permission."
	end,
	["ERLC_MANAGER"] = function(member, config)
		if member:hasPermission("manageGuild") then
			return true
		end

		config = config or sqldb:get(member.guild.id)

		if config then
			if config.erlcmanagerroles then
				for _, erlcmanagerrole in pairs(config.erlcmanagerroles) do
					if member:hasRole(erlcmanagerrole) then
						return true
					end
				end
			else
				return "You have not configured the **ERLC Manager** permission."
			end
		else
			return "You have not configured this server."
		end

		return "You are missing the **ERLC Manager** permission."
	end,
	["SESSION_STARTER"] = function(member, config)
		if member:hasPermission("manageGuild") then
			return true
		end

		config = config or sqldb:get(member.guild.id)

		if config then
			if config.sessionstarterroles then
				for _, sessionstarterrole in pairs(config.sessionstarterroles) do
					if member:hasRole(sessionstarterrole) then
						return true
					end
				end
			else
				return "You have not configured the **Session Starter** permission."
			end
		else
			return "You have not configured this server."
		end

		return "You are missing the **Session Starter** permission."
	end
}

_G.perms = perms

local function hasPermission(member, perm, config, interaction, message)
	local has = perms[perm]
	if has then
		if _G.bypassPermissionsEnabled and perms["BOT_DEVELOPER"](member) == true then
			return true
		else
			local result = has(member, config)

			if result == true then
				return true
			else
				if interaction and message ~= false then
					interaction:fail(message or result, nil, true)
				end

				return false, result
			end
		end
	else
		Client:error("Failed to find permission: " .. tostring(perm))
		return false
	end
end

_G.hasPermission = hasPermission

local lastBlacklistNotify = {}

local function class(object)
	return discordia.class.type(object)
end

_G.class = class

local function blacklisted(object, interaction)
	if not object then
		return false
	end
	if type(object) == "string" then
		object = {
			id = object
		}
	end

	if interaction and lastBlacklistNotify[object.id] and os.time() - lastBlacklistNotify[object.id] <= 600 then
		interaction = nil
	end

	if class(object) == "Guild" then
		local guild = Client:getGuild(object.id)

		if guild then
			if sqldb:getBlacklist(guild.id) then
				if interaction then
					interaction:reply({
						embed = {
							description = emojis.ban .. " This server is **blacklisted** from " .. emojis.ducky .. " **Ducky**.\n-# " .. emojis.right .. " In order to appeal, open a " .. emojis.settings .. " **Management** ticket in [**Ducky's Pond**](https://duckybot.xyz/support).",
							color = colors.error
						}
					}, true)
					lastBlacklistNotify[object.id] = os.time()
				end

				return true
			elseif sqldb:getBlacklist(guild.ownerId) then
				if interaction then
					interaction:reply({
						embed = {
							description = emojis.ban .. " This server's owner is **blacklisted** from " .. emojis.ducky .. " **Ducky**.\n-# " .. emojis.right .. " In order to appeal, open a " .. emojis.settings .. " **Management** ticket in [**Ducky's Pond**](https://duckybot.xyz/support).",
							color = colors.error
						}
					}, true)
					lastBlacklistNotify[object.id] = os.time()
				end

				return true
			end
		end
	elseif sqldb:getBlacklist(object.id) then
		if interaction then
			interaction:reply({
				embed = {
					description = emojis.ban .. " You are **blacklisted** from " .. emojis.ducky .. " **Ducky**.\n-# " .. emojis.right .. " In order to appeal, open a " .. emojis.settings .. " **Management** ticket in [**Ducky's Pond**](https://duckybot.xyz/support).",
					color = colors.error
				}
			}, true)
			lastBlacklistNotify[object.id] = os.time()
		end

		return true
	end
end

_G.blacklisted = blacklisted

local function saveError(errID, cmd, err, guildID, userID)
	local errors = sqldb:getAllErrors() or {}

	local errormsg = err
	local line = "unknown"

	local file, l, msg = err:match("([^:]+):(%d+): (.*)")
	if l and msg then
		line = l
		errormsg = msg
	else
		local parts = string.split(err, ": ")
		errormsg = parts[#parts]
	end

	for _, v in pairs(errors) do
		if v.info and v.info.error == errormsg and v.info.line == tonumber(line) then
			local updatedError = {
				command = cmd,
				error = errormsg,
				line = tonumber(line),
				timestamp = os.time(),
				resolved = false,
				full = err,
				guildID = guildID,
				userID = userID
			}
			sqldb:saveError(v.id, updatedError)
			return v.id
		end
	end

	local newError = {
		command = cmd,
		error = errormsg,
		line = tonumber(line) or line,
		timestamp = os.time(),
		resolved = false,
		full = err,
		guildID = guildID,
		userID = userID
	}
	sqldb:saveError(errID, newError)
	return errID
end

local function parsePerms(interaction, command, member)
	local config = sqldb:get(interaction.guild.id) or {}
	if not command.requiredPermissions or (interaction.content and hasPermission(member, "BOT_DEVELOPER") and (_G.bypassPermissionsEnabled or interaction.content:find("%?bypassPermissions"))) then
		return true
	end
	for _, v in pairs(command.requiredPermissions) do
		local perm = perms[v]
		if not perm then
			interaction:warning("Unknown permission: `" .. tostring(v) .. "`")
			return false, "Unknown permission: `" .. tostring(v) .. "`"
		end

		local res = hasPermission(member, v, config, interaction)

		if not res then
			return false, "lacked permissions " .. v
		end
	end

	return true
end

local function reloadSQLDB()
	local oldSQLDB = _G.sqldb
	_G.onFlightSQLDBStart = true
	local newSQLDB = require("sqldb")
	_G.sqldb = newSQLDB
	timer.sleep(500)
	oldSQLDB:close()
end

_G.reloadSQLDB = reloadSQLDB

Client:on("messageCreate", function(message)
	if message.user.bot then
		return
	end
	if (not message.guild) or not message.member or not message.member.guild then
		return
	end

	local isBlacklisted = blacklisted(message.member) or blacklisted(message.guild)

	local config = sqldb:get(message.guild.id) or {}

	if not isBlacklisted and message.content == Client.user.mentionString or message.content == Client.user.mentionString .. " " then
		local botName = emojis.ducky .. " **Ducky**"
		if Client.user.name == "Ducky Dev" then
			botName = emojis.duckyoutline .. " **Ducky Dev**"
		end
		if sqldb:plusGuild(message.guild) then
			botName = emojis.duckyplus .. " **Ducky Plus+**"
		end
		message:reply(emojis.hiya .. " **Hiya,** I'm " .. botName .. ".\n-# " .. emojis.right .. " My prefix in this server is `" .. ((config and config.prefix) or "d!") .. "`.")
	end

	local prefix = config.prefix or "d!"
	local mentionPrefix = message.content:usub(1, Client.user.mentionString:len() + 1) == Client.user.mentionString .. " "

	if (message.content:usub(1, prefix:len()):lower() ~= prefix:lower()) and not mentionPrefix then
		return
	end

	if isBlacklisted and not (message.content and hasPermission(message.member, "BOT_DEVELOPER") and (_G.bypassPermissionsEnabled or message.content:find("%?bypassPermissions"))) then
		return blacklisted(message.member, message) or blacklisted(message.guild, message)
	end

	local args = {}

	if mentionPrefix then
		args = string.split(message.content:usub(Client.user.mentionString:len() + 2), " ")
	else
		args = string.split(message.content:usub(prefix:len() + 1), " ")
	end

	local command, subcmd = getCommand(args[1]:lower())

	if not command then
		return
	end

	if subcmd then
		args[1] = command.name
		table.insert(args, 2, subcmd)
	end

	if config then
		local baseName = command.name:lower()
		local subName = nil

		if command.subcommands and args[2] then
			local input1 = args[2]:lower()
			local input2 = args[3] and (input1 .. " " .. args[3]:lower())

			for key, data in pairs(command.subcommands) do
				local realName = tostring(key):lower()
				
				local matchFound = false

				if type(data) == "table" then
					if realName == input1 or realName == input2 then
						matchFound = true
					else
						for _, alias in ipairs(data) do
							if alias:lower() == input1 or alias:lower() == input2 then
								matchFound = true
								break
							end
						end
					end
				elseif type(data) == "string" then
					if data:lower() == input1 or data:lower() == input2 then
						subName = data:lower()
						break
					end
				end

				if matchFound then
					subName = realName
					break
				end
			end
		end

		local fullCommandName = baseName
		if subName then
			fullCommandName = baseName .. " " .. subName
		end

		local checks = {
			fullCommandName,
			baseName
		}

		for _, cmd in ipairs(checks) do
			if table.find(config.disabledcommands or {}, cmd) and not (hasPermission(message.member, "BOT_DEVELOPER") and (_G.bypassPermissionsEnabled or message.content:find("%?bypassPermissions"))) then
				return message:fail("This command has been disabled by server management.")
			end
		end

		if config.commandblacklists and not (hasPermission(message.member, "BOT_DEVELOPER") and (_G.bypassPermissionsEnabled or message.content:find("%?bypassPermissions"))) then
			if not (command.requiredPermissions and ((table.find(command.requiredPermissions, "BOT_DEVELOPER") and hasPermission(message.member, "BOT_DEVELOPER")) or (table.find(command.requiredPermissions, "SUPPORT") and hasPermission(message.member, "SUPPORT")))) and (not (config.commandblacklists.manageserverbypass and hasPermission(message.member, "MANAGE_SERVER"))) then
				
				local blacklistedChannels = config.commandblacklists.channels
				local blacklistedRoles = config.commandblacklists.roles

				local channelBlacklisted = table.find(blacklistedChannels, message.channel.id)
				local roleBlacklisted

				for _, roleId in pairs(blacklistedRoles) do
					if message.member:hasRole(roleId) then
						roleBlacklisted = roleId
						break
					end
				end

				if channelBlacklisted then
					local r = message:fail("Commands have been disabled in this channel by server management.", nil, true)

					coroutine.wrap(function()
						timer.sleep(5000)

						r:delete()
						if message then
							message:delete()
						end
					end)()

					return
				elseif roleBlacklisted then
					return message:fail("The <@&" .. roleBlacklisted .. "> role has been blacklisted from using commands by server management.", nil, true)
				end
			end
		end

		if config.economy and config.economy.blacklistedroles and next(config.economy.blacklistedroles) and command.category == "Economy" then
			if not (command.requiredPermissions and ((table.find(command.requiredPermissions, "BOT_DEVELOPER") and hasPermission(message.member, "BOT_DEVELOPER")))) then
				local blacklistedRoles = config.economy.blacklistedroles

				local role

				for _, roleId in pairs(blacklistedRoles) do
					if message.member:hasRole(roleId) then
						role = roleId
						break
					end
				end

				if role then
					return message:fail("The <@&" .. role .. "> role has been blacklisted from using economy commands by server management.", nil, true)
				end
			end
		end
	end

	table.remove(args, 1)

	local canuse, fail = parsePerms(message, command, message.member)
	if not canuse then
		Client:emit("commandUsed", message.member, {
			name = command.name,
			fail = fail,
			full = message.content,
			timestamp = message.createdAt,
			channel = message.channel.id,
			message = message
		})
		return
	end

	local cmdCb = ((hasPermission(message.member, "BOT_DEVELOPER") == true) and command.devCallback) or command.hybridCallback or command.callback
	local subcmd = args and args[1]
	local s, e = pcall(cmdCb, message, args, nil, subcmd and subcmd:lower())

	if not s then
		local errorID = "ducky_" .. junkStr(10)
		local errid = saveError(errorID, command.name, e, message.guild.id, message.user.id)
		message:reply({
			embed = {
				title = emojis.error .. " Whoops...",
				description = emojis.right .. " An unexpected error occurred while executing that command. Please join **[Ducky's Pond](https://discord.com/invite/w2dNr7vuKP)** and create a support thread.\n-# " .. emojis.right .. " **Error ID:** `" .. errid .. "`",
				color = colors.error
			}
		})

		Client:emit("commandUsed", message.member, {
			name = command.name,
			full = message.content,
			fail = "ran into error `" .. errorID .. "`",
			timestamp = message.createdAt,
			channel = message.channel.id,
			message = message
		})
	else
		Client:emit("commandUsed", message.member, {
			name = command.name,
			full = message.content,
			timestamp = message.createdAt,
			channel = message.channel.id,
			message = message
		})
	end
end)

Client:on("slashCommandAutocomplete", function(interaction, command, focused, args)
	if interaction and interaction.id and interaction.guild and interaction.user and interaction.member and interaction.channel and command and command.name then
		for i, v in pairs(commands) do
			if v.name:lower() == command.name:lower() then
				if v.autocomplete then
					coroutine.wrap(pcall)(v.autocomplete, interaction, command, focused, args)
				end
			end
		end
	end
end)

Client:on("slashCommand", function(interaction, command, args)
	if not interaction.user then
		interaction:fail("Interaction is invalid: Missing user object.", nil, true)
		return
	end

	if blacklisted(interaction.user, interaction) and not (interaction.content and hasPermission(interaction.user, "BOT_DEVELOPER") and (_G.bypassPermissionsEnabled or interaction.content:find("%?bypassPermissions"))) then
		return
	end

	if (not interaction.guild) or not interaction.member or not interaction.member.guild then
		interaction:fail("Ducky does not function in DMs.", nil, true)
		return
	end

	if not interaction.member then
		interaction:fail("Interaction is invalid: Missing member object.", nil, true)
		return
	end

	if blacklisted(interaction.guild, interaction) and not (interaction.content and hasPermission(interaction.user, "BOT_DEVELOPER") and (_G.bypassPermissionsEnabled or interaction.content:find("%?bypassPermissions"))) then
		return
	end

	if not command.guild_id then
		local command, err = getCommand(command.name:lower())

		if not command then
			return interaction:fail(err, nil, true)
		end

		local config = sqldb:get(interaction.guild.id)

		if config then
			local disabledCommands = config.disabledcommands or {}

			local fullCommandParts = {
				command.name:lower()
			}

			local subcmd
			local argsCopy = args
			if argsCopy and next(argsCopy) then
				local key = next(argsCopy)
				if type(argsCopy[key]) == "table" and class(argsCopy[key]) == "table" then
					subcmd = key
					argsCopy = argsCopy[key]

					if argsCopy and next(argsCopy) then
						local key = next(argsCopy)
						if type(argsCopy[key]) == "table" and class(argsCopy[key]) == "table" then
							subcmd = subcmd .. " " .. key
							argsCopy = argsCopy[key]
						end
					end
				end
			end

			if subcmd then
				for part in string.gmatch(subcmd, "%S+") do
					table.insert(fullCommandParts, part:lower())
				end
			end

			for i = #fullCommandParts, 1, -1 do
				local partial = table.concat(fullCommandParts, " ", 1, i)
				if table.find(disabledCommands, partial) then
					return interaction:fail("This command has been disabled by server management.", nil, true)
				end
			end
			if config.commandblacklists then
				if not (command.requiredPermissions and ((table.find(command.requiredPermissions, "BOT_DEVELOPER") and hasPermission(interaction.member, "BOT_DEVELOPER")) or (table.find(command.requiredPermissions, "SUPPORT") and hasPermission(interaction.member, "SUPPORT")))) and (not (config.commandblacklists.manageserverbypass and hasPermission(interaction.member, "MANAGE_SERVER"))) then
					local blacklistedChannels = config.commandblacklists.channels
					local blacklistedRoles = config.commandblacklists.roles

					local channelBlacklisted = table.find(blacklistedChannels, interaction.channel.id)
					local roleBlacklisted

					for _, roleId in pairs(blacklistedRoles) do
						if interaction.member:hasRole(roleId) then
							roleBlacklisted = roleId
							break
						end
					end

					if channelBlacklisted then
						return interaction:fail("Commands have been disabled in this channel by server management.", nil, true)
					elseif roleBlacklisted then
						return interaction:fail("The <@&" .. roleBlacklisted .. "> role has been blacklisted from using commands by server management.", nil, true)
					end
				end
			end
		end

		local subcmdParts = {}
		local optionsTree = interaction.data.options or {}
		local argsTree = args

		while optionsTree and #optionsTree == 1 and (optionsTree[1].type == 1 or optionsTree[1].type == 2) do
			local subName = optionsTree[1].name
			table.insert(subcmdParts, subName)
			optionsTree = optionsTree[1].options or {}
			if argsTree and argsTree[subName] then
				argsTree = argsTree[subName]
			else
				argsTree = {}
			end
		end

		local subcmd = table.concat(subcmdParts, " ")
		args = argsTree or {}

		local parts = {
			"/" .. command.name
		}

		if subcmd and subcmd ~= "" then
			table.insert(parts, subcmd)
		end

		if args and next(args) then
			table.insert(parts, table.concatFn(args, " ", function(value, key)
				local valueStr = tostring(value)
				if type(value) == "table" and value.id and class(value) then
					valueStr = class(value) .. ":" .. value.id
				end
				return tostring(key) .. ":" .. valueStr
			end))
		end

		local full = table.concat(parts, " ")

		local canuse, fail = parsePerms(interaction, command, interaction.member)
		if not canuse then
			Client:emit("commandUsed", interaction.member, {
				name = command.name,
				fail = fail,
				full = full,
				timestamp = interaction.createdAt,
				channel = interaction.channel and interaction.channel.id,
				message = nil
			})
			return
		end

		local cmdCb = ((hasPermission(interaction.member, "BOT_DEVELOPER") == true) and command.devCallback) or command.hybridCallback or command.slashCallback
		local s, e = pcall(cmdCb, interaction, args, command, subcmd and subcmd:lower())

		if not s then
			local errorID = "ducky_" .. junkStr(10)
			local errid = saveError(errorID, command.name, e, interaction.guild.id, interaction.user.id)
			interaction:reply({
				embed = {
					title = emojis.error .. " Whoops...",
					description = emojis.right .. " An unexpected error occurred while executing that command. Please join **[Ducky's Pond](https://discord.com/invite/w2dNr7vuKP)** and create a support thread.\n-# " .. emojis.right .. " **Error ID:** `" .. errid .. "`",
					color = colors.error
				}
			})

			Client:emit("commandUsed", interaction.member, {
				name = command.name,
				full = full,
				fail = "ran into error `" .. errorID .. "`",
				timestamp = interaction.createdAt,
				channel = interaction.channel and interaction.channel.id,
				message = nil
			})
		else
			Client:emit("commandUsed", interaction.member, {
				name = command.name,
				full = full,
				timestamp = interaction.createdAt,
				channel = interaction.channel and interaction.channel.id,
				message = nil
			})
		end
	else
		local config = sqldb:get(interaction.guild.id) or {}
		local automation

		for _, ams in pairs(config.automations or {}) do
			if ams.customization and ams.customization.customSlashCommand and ams.customization.customSlashCommand.id and ams.customization.customSlashCommand.id == command.id then
				automation = ams
				break
			end
		end

		if not automation then
			interaction:fail("I could not find an automation linked to that custom command. Deleting slash command...", nil, true)
			Client:deleteGuildApplicationCommand(interaction.guild.id, command.id)
			return
		end

		if automation.disabled then
			return interaction:fail("This automation is disabled.", nil, true)
		end

		if automation.customization and automation.customization.requiredRole then
			if (not interaction.member:hasRole(automation.customization.requiredRole)) and (not hasPermission(interaction.member, "MANAGE_SERVER")) then
				return interaction:fail("Only users with the <@&" .. automation.customization.requiredRole .. "> can run this automation.", nil, true)
			end
		elseif not hasPermission(interaction.member, "MANAGE_SERVER", config, interaction) then
			return
		end

		local r = interaction:loading("Executing **" .. emojis.automation .. " " .. automation.name .. "** automation...")

		local function fail(str)
			if type(r) == "table" then
				r:update({
					embed = {
						description = emojis.fail .. " " .. str,
						color = colors.fail
					}
				})
			else
				r = interaction:fail(str)
			end
		end

		local automationArgs = automation.customization.customArgs or {}
		local keys = {}

		for i = 1, 5 do
			local argInfo = automationArgs["arg" .. i]
			if not argInfo then
				break
			end

			local name = argInfo.name
			if name then
				if not args[name] and argInfo.required then
					return interaction:fail("The " .. ordinal(i) .. " argument, **`{" .. name .. "}`**, is required.")
				end

				keys[name] = args[name]
			end
		end

		local resultsTable, resultsEmbeds = runAutomation(automation, config, interaction.guild, nil, keys, nil, nil, interaction.member)

		if type(resultsTable) ~= "table" or not next(resultsTable) then
			return fail("An unknown error occurred while attempting to execute the automation.")
		end

		if type(r) == "table" then
			r:update({
				embeds = resultsEmbeds
			})
		else
			interaction:reply({
				embeds = resultsEmbeds
			})
		end
	end
end)

print("[Ducky] | Initialized events in " .. (os.clock() - startl) .. " seconds.\n")

print("[Ducky] | Running client...")
startl = os.clock()
Client:run("Bot " .. SECRETS.TOKEN)
print("[Ducky] | Ran client in " .. (os.clock() - startl) .. " seconds.\n")

print("[Ducky] | Completed main.lua in " .. os.clock() .. " seconds.")
