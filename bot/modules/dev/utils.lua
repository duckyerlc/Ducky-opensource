-- utils.lua
local utils = {
	name = "utils",
	description = "Stores utility functions to allow changes without having to reboot."
}

local Clock = discordia.Clock()
Clock:start()

local snowGen = snowflake.new(1, 6)

--[[Variables]]

_G.webEditorSessions = _G.webEditorSessions or {}

_G.starMap = {
	[0] 	= emojis.emptystar .. emojis.emptystar .. emojis.emptystar .. emojis.emptystar .. emojis.emptystar,
	[0.5] 	= emojis.halfstar  .. emojis.emptystar .. emojis.emptystar .. emojis.emptystar .. emojis.emptystar,
	[1] 	= emojis.star      .. emojis.emptystar .. emojis.emptystar .. emojis.emptystar .. emojis.emptystar,
	[1.5] 	= emojis.star      .. emojis.halfstar  .. emojis.emptystar .. emojis.emptystar .. emojis.emptystar,
	[2] 	= emojis.star      .. emojis.star      .. emojis.emptystar .. emojis.emptystar .. emojis.emptystar,
	[2.5] 	= emojis.star      .. emojis.star      .. emojis.halfstar  .. emojis.emptystar .. emojis.emptystar,
	[3] 	= emojis.star      .. emojis.star      .. emojis.star      .. emojis.emptystar .. emojis.emptystar,
	[3.5] 	= emojis.star      .. emojis.star      .. emojis.star      .. emojis.halfstar  .. emojis.emptystar,
	[4] 	= emojis.star      .. emojis.star      .. emojis.star      .. emojis.star      .. emojis.emptystar,
	[4.5] 	= emojis.star      .. emojis.star      .. emojis.star      .. emojis.star      .. emojis.halfstar,
	[5] 	= emojis.star      .. emojis.star      .. emojis.star      .. emojis.star      .. emojis.star
}

_G.remoteInGameCommands = {
	["priority"] = 		"ERLC_STAFF",
	["prty"] = 			"ERLC_STAFF",
	["peacetimer"] = 	"ERLC_STAFF",
	["pt"] = 			"ERLC_STAFF",
	["hint"] = 			"ERLC_STAFF",
	["h"] =				"ERLC_STAFF",
	["message"] = 		"ERLC_STAFF",
	["m"] =				"ERLC_STAFF",
	["kill"] = 			"ERLC_STAFF",
	["down"] = 			"ERLC_STAFF",
	["pm"] = 			"ERLC_STAFF",
	["refresh"] = 		"ERLC_STAFF",
	["kick"] = 			"ERLC_STAFF",
	["startfire"] = 	"ERLC_STAFF",
	["unwanted"] = 		"ERLC_STAFF",
	["wanted"] = 		"ERLC_STAFF",
	["time"] = 			"ERLC_STAFF",
	["stopfire"] = 		"ERLC_STAFF",
	["jail"] = 			"ERLC_STAFF",
	["unjail"] = 		"ERLC_STAFF",
	["tp"] = 			"ERLC_STAFF",
	["respawn"] = 		"ERLC_STAFF",
	["load"] = 			"ERLC_STAFF",
	["heal"] = 			"ERLC_STAFF",
	["mod"] = 			"ERLC_ADMIN",
	["weather"] = 		"ERLC_ADMIN",
	["unban"] = 		"ERLC_ADMIN",
	["ban"] = 			"ERLC_ADMIN",
	["unmod"] = 		"ERLC_ADMIN",
	["helper"] = 		"ERLC_ADMIN",
	["unhelper"] = 		"ERLC_ADMIN",
	["loadlayout"] = 	"ERLC_ADMIN",
	["unloadlayout"] =	"ERLC_ADMIN",
	["shutdown"] =		"ERLC_ADMIN",
	["admin"] = 		"ERLC_MANAGER",
	["unadmin"] = 		"ERLC_MANAGER"
}

_G.errCodes = {
	--[[ Discord API JSON Codes ]] --
	[50001] = "I do not have access to that resource. Ensure I have the correct permissions.\n-# " .. emojis.right .. " **HTTP Error:** `50001`", -- Missing Access
	[50002] = "I cannot perform that action on that entity.\n-# " .. emojis.right .. " **HTTP Error:** `50002`", -- Invalid Account Type
	[50003] = "I cannot perform this action on this channel type.\n-# " .. emojis.right .. " **HTTP Error:** `50003`", -- Cannot execute action on this channel type
	[50005] = "I cannot edit or delete messages from another system or webhook.\n-# " .. emojis.right .. " **HTTP Error:** `50005`",
	[50007] = "I'm unable to send messages to this user. Their privacy settings may prevent it.\n-# " .. emojis.right .. " **HTTP Error:** `50007`", -- Cannot send messages to this user
	[50013] = "I was unable to complete this action due to missing permissions.\n-# " .. emojis.right .. " This can happen if I lack the required permission or if my role is not high enough.\n" .. "-# " .. emojis.right .. " **HTTP Error:** `50013`",
	[50019] = "This message cannot be pinned or unpinned.\n-# " .. emojis.right .. " **HTTP Error:** `50019`",
	[50021] = "The provided role is invalid.\n-# " .. emojis.right .. " **HTTP Error:** `50021`",
	[50024] = "You cannot send an empty message.\n-# " .. emojis.right .. " **HTTP Error:** `50024`",
	[50033] = "The request was too large.\n-# " .. emojis.right .. " **HTTP Error:** `50033`",
	[50034] = "You are performing this action too fast.\n-# " .. emojis.right .. " **HTTP Error:** `50034`", -- Rate limit
	[50035] = "The nickname provided is invalid or too long. Please make sure it's under 32 characters.\n-# " .. emojis.right .. " **HTTP Error:** `50035`", -- Invalid Form Body
	[50036] = "This field is read-only.\n-# " .. emojis.right .. " **HTTP Error:** `50036`",
	[50041] = "This webhook token is invalid.\n-# " .. emojis.right .. " **HTTP Error:** `50041`",
	[50045] = "The channel has hit the maximum number of pins.\n-# " .. emojis.right .. " **HTTP Error:** `50045`",
	[50068] = "Invalid emoji used.\n-# " .. emojis.right .. " **HTTP Error:** `50068`",
	[50070] = "Reaction blocked. The user disabled DMs or reactions.\n-# " .. emojis.right .. " **HTTP Error:** `50070`",
	[50073] = "This action cannot be performed due to age restrictions.\n-# " .. emojis.right .. " **HTTP Error:** `50073`",
	[50278] = "The user could not be messaged because Ducky shares no mutual guilds with them or they have DMs disabled.\n-# " .. emojis.right .. " **HTTP Error:** `50278`"
}

_G.words = {
	"ABACK",
	"ABASE",
	"ABATE",
	"ABBEY",
	"ABBOT",
	"ABHOR",
	"ABIDE",
	"ABLED",
	"ABODE",
	"ABORT",
	"ABOUT",
	"ABOVE",
	"ABUSE",
	"ABYSS",
	"ACORN",
	"ACRID",
	"ACTOR",
	"ACUTE",
	"ADAGE",
	"ADAPT",
	"ADEPT",
	"ADIEU",
	"ADMIN",
	"ADMIT",
	"ADOBE",
	"ADOPT",
	"ADORE",
	"ADORN",
	"ADULT",
	"AFFIX",
	"AFIRE",
	"AFOOT",
	"AFOUL",
	"AFTER",
	"AGAIN",
	"AGAPE",
	"AGATE",
	"AGENT",
	"AGILE",
	"AGING",
	"AGLOW",
	"AGONY",
	"AGREE",
	"AHEAD",
	"AIDER",
	"AISLE",
	"ALARM",
	"ALBUM",
	"ALERT",
	"ALGAE",
	"ALIBI",
	"ALIEN",
	"ALIGN",
	"ALIKE",
	"ALIVE",
	"ALLAY",
	"ALLEY",
	"ALLOT",
	"ALLOW",
	"ALLOY",
	"ALOFT",
	"ALONE",
	"ALONG",
	"ALOOF",
	"ALOUD",
	"ALPHA",
	"ALTAR",
	"ALTER",
	"AMASS",
	"AMAZE",
	"AMBER",
	"AMBLE",
	"AMEND",
	"AMISS",
	"AMITY",
	"AMONG",
	"AMPLE",
	"AMPLY",
	"AMUSE",
	"ANGEL",
	"ANGER",
	"ANGLE",
	"ANGRY",
	"ANGST",
	"ANIME",
	"ANKLE",
	"ANNEX",
	"ANNOY",
	"ANNUL",
	"ANODE",
	"ANTIC",
	"ANVIL",
	"AORTA",
	"APART",
	"APHID",
	"APING",
	"APNEA",
	"APPLE",
	"APPLY",
	"APRON",
	"APTLY",
	"ARBOR",
	"ARDOR",
	"ARENA",
	"ARGUE",
	"ARISE",
	"ARMOR",
	"AROMA",
	"AROSE",
	"ARRAY",
	"ARROW",
	"ARSON",
	"ARTSY",
	"ASCOT",
	"ASHEN",
	"ASIDE",
	"ASKEW",
	"ASSAY",
	"ASSET",
	"ATOLL",
	"ATONE",
	"ATTIC",
	"AUDIO",
	"AUDIT",
	"AUGUR",
	"AUNTY",
	"AVAIL",
	"AVERT",
	"AVIAN",
	"AVOID",
	"AWAIT",
	"AWAKE",
	"AWARD",
	"AWARE",
	"AWASH",
	"AWFUL",
	"AWOKE",
	"AXIAL",
	"AXIOM",
	"AXION",
	"AZURE",
	"BACON",
	"BADGE",
	"BADLY",
	"BAGEL",
	"BAGGY",
	"BAITS",
	"BAKER",
	"BALER",
	"BALMY",
	"BANAL",
	"BANJO",
	"BARGE",
	"BARON",
	"BASAL",
	"BASES",
	"BASIC",
	"BASIL",
	"BASIN",
	"BASIS",
	"BASTE",
	"BATCH",
	"BATHE",
	"BATON",
	"BATTY",
	"BAWDY",
	"BAYOU",
	"BEACH",
	"BEADY",
	"BEARD",
	"BEAST",
	"BEECH",
	"BEEFY",
	"BEFIT",
	"BEGAN",
	"BEGAT",
	"BEGET",
	"BEGIN",
	"BEGUN",
	"BEING",
	"BELCH",
	"BELIE",
	"BELLE",
	"BELLS",
	"BELLY",
	"BELOW",
	"BENCH",
	"BERET",
	"BERRY",
	"BERTH",
	"BESET",
	"BETEL",
	"BEVEL",
	"BEZEL",
	"BIBLE",
	"BICEP",
	"BIDDY",
	"BIGOT",
	"BILGE",
	"BILLY",
	"BINGE",
	"BINGO",
	"BIOME",
	"BIRCH",
	"BIRDS",
	"BIRTH",
	"BISON",
	"BITTY",
	"BLACK",
	"BLADE",
	"BLAME",
	"BLAND",
	"BLANK",
	"BLARE",
	"BLAST",
	"BLAZE",
	"BLEAK",
	"BLEAT",
	"BLEED",
	"BLEEP",
	"BLEND",
	"BLESS",
	"BLIMP",
	"BLIND",
	"BLINK",
	"BLISS",
	"BLITZ",
	"BLOAT",
	"BLOCK",
	"BLOKE",
	"BLOND",
	"BLOOD",
	"BLOOM",
	"BLOWN",
	"BLUER",
	"BLUFF",
	"BLUNT",
	"BLURB",
	"BLURT",
	"BLUSH",
	"BOARD",
	"BOAST",
	"BOATS",
	"BOBBY",
	"BONES",
	"BONEY",
	"BONGO",
	"BONUS",
	"BOOBY",
	"BOOST",
	"BOOTH",
	"BOOTY",
	"BOOZE",
	"BOOZY",
	"BORAX",
	"BORNE",
	"BOSOM",
	"BOSSY",
	"BOTCH",
	"BOUGH",
	"BOULE",
	"BOUND",
	"BOWEL",
	"BOXER",
	"BRACE",
	"BRAID",
	"BRAIN",
	"BRAKE",
	"BRAND",
	"BRASH",
	"BRASS",
	"BRAVE",
	"BRAVO",
	"BRAWL",
	"BRAWN",
	"BREAD",
	"BREAK",
	"BREED",
	"BRIAR",
	"BRIBE",
	"BRICK",
	"BRIDE",
	"BRIEF",
	"BRINE",
	"BRING",
	"BRINK",
	"BRINY",
	"BRISK",
	"BROAD",
	"BROIL",
	"BROKE",
	"BROOD",
	"BROOK",
	"BROOM",
	"BROTH",
	"BROWN",
	"BRUNT",
	"BRUSH",
	"BRUTE",
	"BUDDY",
	"BUDGE",
	"BUGGY",
	"BUGLE",
	"BUILD",
	"BUILT",
	"BULBS",
	"BULGE",
	"BULKY",
	"BULLS",
	"BULLY",
	"BUNCH",
	"BUNNY",
	"BURLY",
	"BURNT",
	"BURST",
	"BUSED",
	"BUSHY",
	"BUTCH",
	"BUTTE",
	"BUXOM",
	"BUYER",
	"BYLAW",
	"CABAL",
	"CABBY",
	"CABIN",
	"CABLE",
	"CACAO",
	"CACHE",
	"CACTI",
	"CADDY",
	"CADET",
	"CAGEY",
	"CAIRN",
	"CALLS",
	"CAMEL",
	"CAMEO",
	"CANAL",
	"CANDY",
	"CANNY",
	"CANOE",
	"CANON",
	"CAPER",
	"CAPUT",
	"CARAT",
	"CARDS",
	"CARES",
	"CARGO",
	"CAROL",
	"CARRY",
	"CARVE",
	"CASTE",
	"CATCH",
	"CATER",
	"CATTY",
	"CAULK",
	"CAUSE",
	"CAVIL",
	"CEASE",
	"CEDAR",
	"CELLO",
	"CELLS",
	"CHAFE",
	"CHAFF",
	"CHAIN",
	"CHAIR",
	"CHALK",
	"CHAMP",
	"CHANT",
	"CHAOS",
	"CHARD",
	"CHARM",
	"CHART",
	"CHASE",
	"CHASM",
	"CHEAP",
	"CHEAT",
	"CHECK",
	"CHEEK",
	"CHEER",
	"CHESS",
	"CHEST",
	"CHICK",
	"CHIDE",
	"CHIEF",
	"CHILD",
	"CHILI",
	"CHILL",
	"CHIME",
	"CHINA",
	"CHIRP",
	"CHOCK",
	"CHOIR",
	"CHOKE",
	"CHORD",
	"CHORE",
	"CHOSE",
	"CHUCK",
	"CHUMP",
	"CHUNK",
	"CHURN",
	"CHUTE",
	"CIDER",
	"CIGAR",
	"CINCH",
	"CIRCA",
	"CIVIC",
	"CIVIL",
	"CLACK",
	"CLAIM",
	"CLAMP",
	"CLANG",
	"CLANK",
	"CLASH",
	"CLASP",
	"CLASS",
	"CLEAN",
	"CLEAR",
	"CLEAT",
	"CLEFT",
	"CLERK",
	"CLICK",
	"CLIFF",
	"CLIMB",
	"CLING",
	"CLINK",
	"CLOAK",
	"CLOCK",
	"CLONE",
	"CLOSE",
	"CLOTH",
	"CLOUD",
	"CLOUT",
	"CLOVE",
	"CLOWN",
	"CLUCK",
	"CLUED",
	"CLUMP",
	"CLUNG",
	"COACH",
	"COAST",
	"COATS",
	"COBRA",
	"COCOA",
	"COLON",
	"COLOR",
	"COMET",
	"COMFY",
	"COMIC",
	"COMMA",
	"CONCH",
	"CONDO",
	"CONIC",
	"COPSE",
	"CORAL",
	"CORER",
	"CORNS",
	"CORNY",
	"COUCH",
	"COUGH",
	"COULD",
	"COUNT",
	"COUPE",
	"COURT",
	"COVEN",
	"COVER",
	"COVET",
	"COVEY",
	"COWER",
	"COYLY",
	"CRACK",
	"CRAFT",
	"CRAMP",
	"CRANE",
	"CRANK",
	"CRASH",
	"CRASS",
	"CRATE",
	"CRAVE",
	"CRAWL",
	"CRAZE",
	"CRAZY",
	"CREAK",
	"CREAM",
	"CREDO",
	"CREED",
	"CREEK",
	"CREEP",
	"CREME",
	"CREPE",
	"CREPT",
	"CRESS",
	"CREST",
	"CRICK",
	"CRIED",
	"CRIER",
	"CRIME",
	"CRIMP",
	"CRISP",
	"CROAK",
	"CROCK",
	"CRONE",
	"CRONY",
	"CROOK",
	"CROSS",
	"CROUP",
	"CROWD",
	"CROWN",
	"CRUDE",
	"CRUEL",
	"CRUMB",
	"CRUMP",
	"CRUSH",
	"CRUST",
	"CRYPT",
	"CUBIC",
	"CUMIN",
	"CURIO",
	"CURLY",
	"CURRY",
	"CURSE",
	"CURVE",
	"CURVY",
	"CUTIE",
	"CYBER",
	"CYCLE",
	"CYNIC",
	"DADDY",
	"DAILY",
	"DAIRY",
	"DAISY",
	"DALLY",
	"DANCE",
	"DANDY",
	"DATUM",
	"DAUNT",
	"DEALT",
	"DEATH",
	"DEBAR",
	"DEBIT",
	"DEBUG",
	"DEBUT",
	"DECAL",
	"DECAY",
	"DECOR",
	"DECOY",
	"DECRY",
	"DEFER",
	"DEIGN",
	"DEITY",
	"DELAY",
	"DELTA",
	"DELVE",
	"DEMON",
	"DEMUR",
	"DENIM",
	"DENSE",
	"DENTS",
	"DEPOT",
	"DEPTH",
	"DERBY",
	"DETER",
	"DETOX",
	"DEUCE",
	"DEVIL",
	"DIARY",
	"DICEY",
	"DIGIT",
	"DILLY",
	"DIMLY",
	"DINER",
	"DINGO",
	"DINGY",
	"DIODE",
	"DIRGE",
	"DIRTY",
	"DISCO",
	"DITCH",
	"DITTO",
	"DITTY",
	"DIVER",
	"DIZZY",
	"DODGE",
	"DODGY",
	"DOGMA",
	"DOING",
	"DOLLY",
	"DONOR",
	"DONUT",
	"DOPEY",
	"DOUBT",
	"DOUGH",
	"DOWDY",
	"DOWEL",
	"DOWNY",
	"DOWRY",
	"DOZEN",
	"DRAFT",
	"DRAIN",
	"DRAKE",
	"DRAMA",
	"DRANK",
	"DRAPE",
	"DRAWL",
	"DRAWN",
	"DREAD",
	"DREAM",
	"DRESS",
	"DRIED",
	"DRIER",
	"DRIFT",
	"DRILL",
	"DRINK",
	"DRIVE",
	"DROIT",
	"DROLL",
	"DRONE",
	"DROOL",
	"DROOP",
	"DROSS",
	"DROVE",
	"DROWN",
	"DRUID",
	"DRUNK",
	"DRYER",
	"DRYLY",
	"DUCHY",
	"DUCKY",
	"DULLY",
	"DUMMY",
	"DUMPY",
	"DUNCE",
	"DUSKY",
	"DUSTY",
	"DUTCH",
	"DUVET",
	"DWARF",
	"DWELL",
	"DWELT",
	"DYING",
	"EAGER",
	"EAGLE",
	"EARLY",
	"EARTH",
	"EASEL",
	"EATEN",
	"EATER",
	"EBONY",
	"ECLAT",
	"EDICT",
	"EDIFY",
	"EERIE",
	"EGRET",
	"EIGHT",
	"EJECT",
	"EKING",
	"ELATE",
	"ELBOW",
	"ELDER",
	"ELECT",
	"ELEGY",
	"ELFIN",
	"ELIDE",
	"ELITE",
	"ELOPE",
	"ELUDE",
	"EMAIL",
	"EMBED",
	"EMBER",
	"EMCEE",
	"EMPTY",
	"ENACT",
	"ENDOW",
	"ENEMA",
	"ENEMY",
	"ENJOY",
	"ENNUI",
	"ENSUE",
	"ENTER",
	"ENTRY",
	"ENVOY",
	"EPOCH",
	"EPOXY",
	"EQUAL",
	"EQUIP",
	"ERASE",
	"ERECT",
	"ERODE",
	"ERROR",
	"ERUPT",
	"ESSAY",
	"ESTER",
	"ETHER",
	"ETHIC",
	"ETHOS",
	"ETUDE",
	"EVADE",
	"EVENT",
	"EVERY",
	"EVICT",
	"EVOKE",
	"EXACT",
	"EXALT",
	"EXCEL",
	"EXERT",
	"EXILE",
	"EXIST",
	"EXPEL",
	"EXTOL",
	"EXTRA",
	"EXULT",
	"EYING",
	"FABLE",
	"FACET",
	"FAINT",
	"FAIRY",
	"FAITH",
	"FALSE",
	"FANCY",
	"FANNY",
	"FARCE",
	"FATAL",
	"FATTY",
	"FAULT",
	"FAUNA",
	"FAVOR",
	"FEAST",
	"FECAL",
	"FEIGN",
	"FELLA",
	"FELON",
	"FEMME",
	"FEMUR",
	"FENCE",
	"FERAL",
	"FERRY",
	"FETAL",
	"FETCH",
	"FETID",
	"FETUS",
	"FEVER",
	"FEWER",
	"FIBER",
	"FICUS",
	"FIELD",
	"FIEND",
	"FIERY",
	"FIFTH",
	"FIFTY",
	"FIGHT",
	"FILER",
	"FILET",
	"FILLY",
	"FILMY",
	"FILTH",
	"FINAL",
	"FINCH",
	"FINER",
	"FIRST",
	"FISHY",
	"FIXER",
	"FIZZY",
	"FJORD",
	"FLACK",
	"FLAIL",
	"FLAIR",
	"FLAKE",
	"FLAKY",
	"FLAME",
	"FLANK",
	"FLARE",
	"FLASH",
	"FLASK",
	"FLECK",
	"FLEET",
	"FLESH",
	"FLICK",
	"FLIER",
	"FLING",
	"FLINT",
	"FLIRT",
	"FLOAT",
	"FLOCK",
	"FLOOD",
	"FLOOR",
	"FLORA",
	"FLOSS",
	"FLOUR",
	"FLOUT",
	"FLOWN",
	"FLUFF",
	"FLUID",
	"FLUKE",
	"FLUME",
	"FLUNG",
	"FLUNK",
	"FLUSH",
	"FLUTE",
	"FLYER",
	"FOAMY",
	"FOCAL",
	"FOCUS",
	"FOGGY",
	"FOIST",
	"FOLIO",
	"FOLLY",
	"FORAY",
	"FORCE",
	"FORGE",
	"FORGO",
	"FORTE",
	"FORTH",
	"FORTY",
	"FORUM",
	"FOUND",
	"FOYER",
	"FRAIL",
	"FRAME",
	"FRANK",
	"FRAUD",
	"FREAK",
	"FREED",
	"FREER",
	"FRESH",
	"FRIAR",
	"FRIED",
	"FRILL",
	"FRISK",
	"FRITZ",
	"FROCK",
	"FROND",
	"FRONT",
	"FROST",
	"FROTH",
	"FROWN",
	"FROZE",
	"FRUIT",
	"FUDGE",
	"FUGUE",
	"FULLY",
	"FUNGI",
	"FUNKY",
	"FUNNY",
	"FUROR",
	"FURRY",
	"FUSSY",
	"FUZZY",
	"GAFFE",
	"GAILY",
	"GAMER",
	"GAMMA",
	"GAMUT",
	"GASSY",
	"GAUDY",
	"GAUGE",
	"GAUNT",
	"GAUZE",
	"GAVEL",
	"GAWKY",
	"GAYER",
	"GAYLY",
	"GAZER",
	"GECKO",
	"GEEKY",
	"GEESE",
	"GENIE",
	"GENRE",
	"GHOST",
	"GHOUL",
	"GIANT",
	"GIDDY",
	"GIPSY",
	"GIRLY",
	"GIRTH",
	"GILLS",
	"GIVEN",
	"GIVER",
	"GLADE",
	"GLAND",
	"GLARE",
	"GLASS",
	"GLAZE",
	"GLEAM",
	"GLEAN",
	"GLIDE",
	"GLINT",
	"GLOAT",
	"GLOBE",
	"GLOOM",
	"GLORY",
	"GLOSS",
	"GLOVE",
	"GLYPH",
	"GNASH",
	"GNOME",
	"GOALS",
	"GODLY",
	"GOING",
	"GOLDS",
	"GOLEM",
	"GOLLY",
	"GONAD",
	"GONER",
	"GOODY",
	"GOOEY",
	"GOOFY",
	"GOOSE",
	"GORGE",
	"GOUGE",
	"GOURD",
	"GRACE",
	"GRADE",
	"GRAFT",
	"GRAIL",
	"GRAIN",
	"GRAND",
	"GRANT",
	"GRAPE",
	"GRAPH",
	"GRASP",
	"GRASS",
	"GRATE",
	"GRAVE",
	"GRAVY",
	"GRAZE",
	"GREAT",
	"GREED",
	"GREEN",
	"GREET",
	"GRIEF",
	"GRILL",
	"GRIME",
	"GRIMY",
	"GRIND",
	"GRIPE",
	"GROAN",
	"GROIN",
	"GROOM",
	"GROPE",
	"GROSS",
	"GROUP",
	"GROUT",
	"GROVE",
	"GROWL",
	"GROWN",
	"GRUEL",
	"GRUFF",
	"GRUNT",
	"GUARD",
	"GUAVA",
	"GUESS",
	"GUEST",
	"GUIDE",
	"GUILD",
	"GUILE",
	"GUILT",
	"GUISE",
	"GULCH",
	"GULLY",
	"GUMBO",
	"GUMMY",
	"GUPPY",
	"GUSTO",
	"GUSTS",
	"GUSTY",
	"GYPSY",
	"HABIT",
	"HAIRY",
	"HALVE",
	"HANDS",
	"HANDY",
	"HAPPY",
	"HARDY",
	"HAREM",
	"HARPS",
	"HARPY",
	"HARRY",
	"HARSH",
	"HASTE",
	"HASTY",
	"HATCH",
	"HATER",
	"HAUNT",
	"HAUTE",
	"HAVEN",
	"HAVOC",
	"HAZEL",
	"HEADS",
	"HEADY",
	"HEARD",
	"HEART",
	"HEATH",
	"HEAVE",
	"HEAVY",
	"HEDGE",
	"HEFTY",
	"HEIST",
	"HELIX",
	"HELLO",
	"HENCE",
	"HERON",
	"HILLY",
	"HINGE",
	"HIPPO",
	"HIPPY",
	"HITCH",
	"HOARD",
	"HOBBY",
	"HOIST",
	"HOLLY",
	"HOMER",
	"HONEY",
	"HONOR",
	"HORDE",
	"HORNY",
	"HORSE",
	"HOTEL",
	"HOTLY",
	"HOUND",
	"HOUSE",
	"HOVEL",
	"HOVER",
	"HOWDY",
	"HUMAN",
	"HUMID",
	"HUMOR",
	"HUMPH",
	"HUMUS",
	"HUNCH",
	"HUNKY",
	"HURRY",
	"HUSKY",
	"HUSSY",
	"HUTCH",
	"HYDRO",
	"HYENA",
	"HYMEN",
	"HYPER",
	"ICILY",
	"ICING",
	"IDEAL",
	"IDIOM",
	"IDIOT",
	"IDLER",
	"IDYLL",
	"IGLOO",
	"ILIAC",
	"IMAGE",
	"IMBUE",
	"IMPEL",
	"IMPLY",
	"INANE",
	"INBOX",
	"INCUR",
	"INDEX",
	"INEPT",
	"INERT",
	"INFER",
	"INGOT",
	"INLAY",
	"INLET",
	"INNER",
	"INPUT",
	"INTER",
	"INTRO",
	"INTOX",
	"IONIC",
	"IRATE",
	"IRONY",
	"ISLET",
	"ISSUE",
	"ITCHY",
	"IVORY",
	"JAUNT",
	"JAZZY",
	"JELLY",
	"JERKY",
	"JETTY",
	"JEWEL",
	"JIFFY",
	"JOINT",
	"JOIST",
	"JOKER",
	"JOLLY",
	"JOUST",
	"JUDGE",
	"JUICE",
	"JUICY",
	"JUMBO",
	"JUMPY",
	"JUNTA",
	"JUNTO",
	"JUROR",
	"KAPPA",
	"KAPUT",
	"KARMA",
	"KAYAK",
	"KEBAB",
	"KHAKI",
	"KINKY",
	"KIOSK",
	"KITTY",
	"KNACK",
	"KNAVE",
	"KNEAD",
	"KNEED",
	"KNEEL",
	"KNELT",
	"KNIFE",
	"KNOCK",
	"KNOLL",
	"KNOWN",
	"KOALA",
	"KRILL",
	"LABEL",
	"LABOR",
	"LADEN",
	"LADLE",
	"LAGER",
	"LANCE",
	"LANKY",
	"LAPEL",
	"LAPSE",
	"LARGE",
	"LARVA",
	"LAMPS",
	"LASSO",
	"LATCH",
	"LATER",
	"LATHE",
	"LATTE",
	"LAUGH",
	"LAYER",
	"LEACH",
	"LEAFY",
	"LEAKY",
	"LEANT",
	"LEAPT",
	"LEARN",
	"LEASE",
	"LEASH",
	"LEAST",
	"LEAVE",
	"LEDGE",
	"LEECH",
	"LEERY",
	"LEFTY",
	"LEGAL",
	"LEGGY",
	"LEMON",
	"LEMUR",
	"LEPER",
	"LEVEL",
	"LEVER",
	"LIBEL",
	"LIEGE",
	"LIGHT",
	"LIKEN",
	"LILAC",
	"LIMBO",
	"LIMIT",
	"LINEN",
	"LINER",
	"LINGO",
	"LIPID",
	"LISTS",
	"LITHE",
	"LIVER",
	"LIVID",
	"LLAMA",
	"LOAMY",
	"LOATH",
	"LOBBY",
	"LOCAL",
	"LOCUS",
	"LODGE",
	"LOFTY",
	"LOGIC",
	"LOGIN",
	"LOOPY",
	"LOOSE",
	"LORRY",
	"LOSER",
	"LOUSE",
	"LOUSY",
	"LOVER",
	"LOWER",
	"LOWLY",
	"LOYAL",
	"LUCID",
	"LUCKY",
	"LUMEN",
	"LUMPY",
	"LUNAR",
	"LUNCH",
	"LUNGE",
	"LUPUS",
	"LURCH",
	"LURID",
	"LUSTY",
	"LYING",
	"LYMPH",
	"LYRIC",
	"MACAW",
	"MACHO",
	"MACRO",
	"MADAM",
	"MADLY",
	"MAFIA",
	"MAGIC",
	"MAGMA",
	"MAIZE",
	"MAJOR",
	"MAKER",
	"MAMBO",
	"MAMMA",
	"MAMMY",
	"MANGA",
	"MANGE",
	"MANGO",
	"MANGY",
	"MANIA",
	"MANIC",
	"MANLY",
	"MANOR",
	"MAPLE",
	"MARCH",
	"MARRY",
	"MARSH",
	"MASON",
	"MASSE",
	"MATCH",
	"MATEY",
	"MATHS",
	"MAUVE",
	"MAXIM",
	"MAYBE",
	"MAYOR",
	"MEALY",
	"MEANT",
	"MEATY",
	"MECCA",
	"MEDAL",
	"MEDIA",
	"MEDIC",
	"MELEE",
	"MELON",
	"MERCY",
	"MERGE",
	"MERIT",
	"MERRY",
	"METAL",
	"METER",
	"METRO",
	"MICRO",
	"MIDGE",
	"MIDST",
	"MIGHT",
	"MILKY",
	"MIMIC",
	"MINCE",
	"MINER",
	"MINIM",
	"MINOR",
	"MINTY",
	"MINUS",
	"MIRTH",
	"MISER",
	"MISSY",
	"MOCHA",
	"MODAL",
	"MODEL",
	"MODEM",
	"MOGUL",
	"MOIST",
	"MOLAR",
	"MOLDY",
	"MONEY",
	"MONTH",
	"MOODY",
	"MOONS",
	"MOOSE",
	"MORAL",
	"MORON",
	"MORPH",
	"MOSSY",
	"MOTEL",
	"MOTIF",
	"MOTOR",
	"MOTTO",
	"MOULT",
	"MOUND",
	"MOUNT",
	"MOURN",
	"MOUSE",
	"MOUTH",
	"MOVER",
	"MOVIE",
	"MOWER",
	"MUCKY",
	"MUCUS",
	"MUDDY",
	"MULCH",
	"MUMMY",
	"MUNCH",
	"MURAL",
	"MURKY",
	"MUSHY",
	"MUSIC",
	"MUSKY",
	"MUSTY",
	"MYRRH",
	"NADIR",
	"NAIVE",
	"NANNY",
	"NASAL",
	"NASTY",
	"NATAL",
	"NAVAL",
	"NAVEL",
	"NEEDY",
	"NEIGH",
	"NERDY",
	"NERVE",
	"NEVER",
	"NEWER",
	"NEWLY",
	"NICER",
	"NICHE",
	"NIECE",
	"NIGHT",
	"NINJA",
	"NINNY",
	"NINTH",
	"NOBLE",
	"NOBLY",
	"NOISE",
	"NOISY",
	"NOMAD",
	"NOOSE",
	"NORTH",
	"NOSEY",
	"NOTCH",
	"NOVEL",
	"NUDGE",
	"NURSE",
	"NUTTY",
	"NYLON",
	"NYMPH",
	"OAKEN",
	"OBESE",
	"OCCUR",
	"OCEAN",
	"OCTAL",
	"OCTET",
	"ODDER",
	"ODDLY",
	"OFFAL",
	"OFFER",
	"OFTEN",
	"OLDEN",
	"OLDER",
	"OLIVE",
	"OMBRE",
	"OMEGA",
	"ONION",
	"ONSET",
	"OPERA",
	"OPINE",
	"OPIUM",
	"OPTIC",
	"ORBIT",
	"ORDER",
	"ORGAN",
	"OTHER",
	"OTTER",
	"OUGHT",
	"OUNCE",
	"OUTDO",
	"OUTER",
	"OUTGO",
	"OVARY",
	"OVATE",
	"OVERT",
	"OVINE",
	"OVOID",
	"OWING",
	"OWNER",
	"OXIDE",
	"OZONE",
	"PADDY",
	"PAGAN",
	"PAINT",
	"PALER",
	"PALSY",
	"PANEL",
	"PANIC",
	"PANSY",
	"PANTS",
	"PAPAL",
	"PAPER",
	"PARER",
	"PARKA",
	"PARRY",
	"PARSE",
	"PARTY",
	"PASTA",
	"PASTE",
	"PASTY",
	"PATCH",
	"PATIO",
	"PATSY",
	"PATTY",
	"PAUSE",
	"PAYEE",
	"PAYER",
	"PEACE",
	"PEACH",
	"PEARL",
	"PECAN",
	"PEDAL",
	"PENAL",
	"PENCE",
	"PENNE",
	"PENNY",
	"PERCH",
	"PERIL",
	"PERKY",
	"PESKY",
	"PESTO",
	"PETAL",
	"PETTY",
	"PHASE",
	"PHONE",
	"PHONY",
	"PHOTO",
	"PIANO",
	"PICKY",
	"PIECE",
	"PIETY",
	"PIGGY",
	"PILOT",
	"PINCH",
	"PINEY",
	"PINKY",
	"PINTO",
	"PINTS",
	"PIPER",
	"PIQUE",
	"PITCH",
	"PITHY",
	"PIVOT",
	"PIXEL",
	"PIXIE",
	"PIZZA",
	"PLACE",
	"PLAID",
	"PLAIN",
	"PLAIT",
	"PLANE",
	"PLANK",
	"PLANT",
	"PLATE",
	"PLAYS",
	"PLAZA",
	"PLEAD",
	"PLEAT",
	"PLIED",
	"PLIER",
	"PLUCK",
	"PLUMB",
	"PLUME",
	"PLUMP",
	"PLUNK",
	"PLUSH",
	"POESY",
	"POINT",
	"POISE",
	"POKER",
	"POLAR",
	"POLKA",
	"POLLS",
	"POLYP",
	"POOCH",
	"POPPY",
	"PORCH",
	"PORTS",
	"POSER",
	"POSIT",
	"POSSE",
	"POUCH",
	"POUND",
	"POUTY",
	"POWER",
	"PRANK",
	"PRAWN",
	"PREEN",
	"PRESS",
	"PRICE",
	"PRICK",
	"PRIDE",
	"PRIED",
	"PRIME",
	"PRIMO",
	"PRINT",
	"PRIOR",
	"PRISM",
	"PRIVY",
	"PRIZE",
	"PROBE",
	"PRONE",
	"PRONG",
	"PROOF",
	"PROSE",
	"PROUD",
	"PROVE",
	"PROWL",
	"PROXY",
	"PRUDE",
	"PRUNE",
	"PSALM",
	"PUBIC",
	"PUDGY",
	"PUFFY",
	"PULPY",
	"PULSE",
	"PUNCH",
	"PUPIL",
	"PUPPY",
	"PUREE",
	"PURER",
	"PURGE",
	"PURSE",
	"PUSHY",
	"PUTTY",
	"PYGMY",
	"QUACK",
	"QUAIL",
	"QUAKE",
	"QUALM",
	"QUARK",
	"QUART",
	"QUASH",
	"QUASI",
	"QUEEN",
	"QUEER",
	"QUELL",
	"QUERY",
	"QUEST",
	"QUEUE",
	"QUICK",
	"QUIET",
	"QUILL",
	"QUILT",
	"QUIRK",
	"QUITE",
	"QUOTA",
	"QUOTE",
	"QUOTH",
	"RABBI",
	"RABID",
	"RACER",
	"RADAR",
	"RADII",
	"RADIO",
	"RAINY",
	"RAISE",
	"RAJAH",
	"RALLY",
	"RALPH",
	"RAMEN",
	"RANCH",
	"RANDY",
	"RANGE",
	"RANTS",
	"RANKS",
	"RAPID",
	"RARER",
	"RASPY",
	"RATIO",
	"RATTY",
	"RAVEN",
	"RAYON",
	"RAZOR",
	"REACH",
	"REACT",
	"READY",
	"REALM",
	"REARM",
	"REBAR",
	"REBEL",
	"REBUS",
	"REBUT",
	"RECAP",
	"RECUR",
	"RECUT",
	"REEDY",
	"REFER",
	"REFIT",
	"REGAL",
	"REHAB",
	"REIGN",
	"RELAX",
	"RELAY",
	"RELIC",
	"REMIT",
	"RENAL",
	"RENEW",
	"RENTS",
	"REPAY",
	"REPEL",
	"REPLY",
	"RERUN",
	"RESET",
	"RESIN",
	"RETCH",
	"RETRO",
	"RETRY",
	"REUSE",
	"REVEL",
	"REVUE",
	"RHINO",
	"RHYME",
	"RIDER",
	"RIDGE",
	"RIFLE",
	"RIGHT",
	"RIGID",
	"RIGOR",
	"RINSE",
	"RIPEN",
	"RIPER",
	"RISEN",
	"RISER",
	"RISKY",
	"RIVAL",
	"RIVER",
	"RIVET",
	"ROACH",
	"ROAST",
	"ROBIN",
	"ROBOT",
	"ROCKY",
	"RODEO",
	"ROGER",
	"ROGUE",
	"ROOMY",
	"ROOST",
	"ROTOR",
	"ROUGE",
	"ROUGH",
	"ROUND",
	"ROUSE",
	"ROUTE",
	"ROVER",
	"ROWDY",
	"ROWER",
	"ROYAL",
	"RUDDY",
	"RUDER",
	"RUGBY",
	"RULER",
	"RUMBA",
	"RUMOR",
	"RUPEE",
	"RURAL",
	"RUSTY",
	"SADLY",
	"SAFER",
	"SAINT",
	"SALAD",
	"SALLY",
	"SALON",
	"SALSA",
	"SALTY",
	"SALVE",
	"SALVO",
	"SANDY",
	"SANER",
	"SAPPY",
	"SASSY",
	"SATIN",
	"SATYR",
	"SAUCE",
	"SAUCY",
	"SAUNA",
	"SAUTE",
	"SAVES",
	"SAVOR",
	"SAVOY",
	"SAVVY",
	"SCALD",
	"SCALE",
	"SCALP",
	"SCALY",
	"SCAMP",
	"SCANT",
	"SCARE",
	"SCARF",
	"SCARY",
	"SCENE",
	"SCENT",
	"SCION",
	"SCOFF",
	"SCOLD",
	"SCONE",
	"SCOOP",
	"SCOPE",
	"SCORE",
	"SCORN",
	"SCOUR",
	"SCOUT",
	"SCOWL",
	"SCRAM",
	"SCRAP",
	"SCREE",
	"SCREW",
	"SCRUB",
	"SCRUM",
	"SCUBA",
	"SEDAN",
	"SEEDY",
	"SEGUE",
	"SEIZE",
	"SEMEN",
	"SENSE",
	"SEPIA",
	"SERIF",
	"SERUM",
	"SERVE",
	"SETUP",
	"SEVEN",
	"SEVER",
	"SEWER",
	"SHACK",
	"SHADE",
	"SHADY",
	"SHAFT",
	"SHAKE",
	"SHAKY",
	"SHALE",
	"SHALL",
	"SHALT",
	"SHAME",
	"SHANK",
	"SHAPE",
	"SHARD",
	"SHARE",
	"SHARK",
	"SHARP",
	"SHAVE",
	"SHAWL",
	"SHEAR",
	"SHEEN",
	"SHEEP",
	"SHEER",
	"SHEET",
	"SHEIK",
	"SHELF",
	"SHELL",
	"SHIED",
	"SHIFT",
	"SHINE",
	"SHINY",
	"SHIRE",
	"SHIRK",
	"SHIRT",
	"SHOAL",
	"SHOCK",
	"SHONE",
	"SHOOK",
	"SHOOT",
	"SHORE",
	"SHORN",
	"SHORT",
	"SHOUT",
	"SHOVE",
	"SHOWN",
	"SHOWY",
	"SHREW",
	"SHRUB",
	"SHRUG",
	"SHUCK",
	"SHUNT",
	"SHUSH",
	"SHYLY",
	"SIEGE",
	"SIEVE",
	"SIGHT",
	"SIGMA",
	"SILKY",
	"SILLY",
	"SINCE",
	"SINEW",
	"SINGE",
	"SIREN",
	"SISSY",
	"SIXTH",
	"SIXTY",
	"SKATE",
	"SKIER",
	"SKIFF",
	"SKILL",
	"SKIMP",
	"SKIRT",
	"SKULK",
	"SKULL",
	"SKUNK",
	"SLACK",
	"SLAIN",
	"SLANG",
	"SLANT",
	"SLASH",
	"SLATE",
	"SLEEK",
	"SLEEP",
	"SLEET",
	"SLEPT",
	"SLICE",
	"SLICK",
	"SLIDE",
	"SLIME",
	"SLIMY",
	"SLING",
	"SLINK",
	"SLOOP",
	"SLOPE",
	"SLOSH",
	"SLOTH",
	"SLUMP",
	"SLUNG",
	"SLUNK",
	"SLURP",
	"SLUSH",
	"SLYLY",
	"SMACK",
	"SMALL",
	"SMART",
	"SMASH",
	"SMEAR",
	"SMELL",
	"SMELT",
	"SMILE",
	"SMIRK",
	"SMITE",
	"SMITH",
	"SMOCK",
	"SMOKE",
	"SMOKY",
	"SMOTE",
	"SNACK",
	"SNAIL",
	"SNAKE",
	"SNAKY",
	"SNARE",
	"SNARL",
	"SNEAK",
	"SNEER",
	"SNIDE",
	"SNIFF",
	"SNIPE",
	"SNOOP",
	"SNORE",
	"SNORT",
	"SNOUT",
	"SNOWY",
	"SNUCK",
	"SNUFF",
	"SOAPY",
	"SOBER",
	"SOGGY",
	"SOILS",
	"SOLAR",
	"SOLID",
	"SOLVE",
	"SONAR",
	"SONIC",
	"SOOTH",
	"SOOTY",
	"SORRY",
	"SOUND",
	"SOUTH",
	"SOWER",
	"SPACE",
	"SPADE",
	"SPANK",
	"SPARE",
	"SPARK",
	"SPASM",
	"SPAWN",
	"SPEAK",
	"SPEAR",
	"SPECK",
	"SPEED",
	"SPELL",
	"SPELT",
	"SPEND",
	"SPENT",
	"SPERM",
	"SPICE",
	"SPICY",
	"SPIED",
	"SPIEL",
	"SPIKE",
	"SPIKY",
	"SPILL",
	"SPILT",
	"SPINE",
	"SPINY",
	"SPIRE",
	"SPITE",
	"SPLAT",
	"SPLIT",
	"SPOIL",
	"SPOKE",
	"SPOOF",
	"SPOOK",
	"SPOOL",
	"SPOON",
	"SPORE",
	"SPORT",
	"SPOUT",
	"SPRAY",
	"SPREE",
	"SPRIG",
	"SPUNK",
	"SPURN",
	"SPURT",
	"SQUAD",
	"SQUAT",
	"SQUIB",
	"STACK",
	"STAFF",
	"STAGE",
	"STAID",
	"STAIN",
	"STAIR",
	"STAKE",
	"STALE",
	"STALK",
	"STALL",
	"STAMP",
	"STAND",
	"STANK",
	"STARE",
	"STARK",
	"STARS",
	"START",
	"STASH",
	"STATE",
	"STAVE",
	"STEAD",
	"STEAK",
	"STEAL",
	"STEAM",
	"STEED",
	"STEEL",
	"STEEP",
	"STEER",
	"STEIN",
	"STERN",
	"STICK",
	"STIFF",
	"STILL",
	"STILT",
	"STING",
	"STINK",
	"STINT",
	"STOCK",
	"STOIC",
	"STOKE",
	"STOLE",
	"STOMP",
	"STONE",
	"STONY",
	"STOOD",
	"STOOL",
	"STOOP",
	"STORE",
	"STORK",
	"STORM",
	"STORY",
	"STOUT",
	"STOVE",
	"STRAP",
	"STRAW",
	"STRAY",
	"STRIP",
	"STRUT",
	"STUCK",
	"STUDY",
	"STUFF",
	"STUMP",
	"STUNG",
	"STUNK",
	"STUNT",
	"STYLE",
	"SUAVE",
	"SUGAR",
	"SUING",
	"SUITE",
	"SULKY",
	"SULLY",
	"SUMAC",
	"SUNNY",
	"SUPER",
	"SURER",
	"SURGE",
	"SURLY",
	"SUSHI",
	"SWAMI",
	"SWAMP",
	"SWARM",
	"SWASH",
	"SWATH",
	"SWEAR",
	"SWEAT",
	"SWEEP",
	"SWEET",
	"SWELL",
	"SWEPT",
	"SWIFT",
	"SWILL",
	"SWINE",
	"SWING",
	"SWIRL",
	"SWISH",
	"SWOON",
	"SWOOP",
	"SWORD",
	"SWORE",
	"SWORN",
	"SWUNG",
	"SYNOD",
	"SYRUP",
	"TABBY",
	"TABLE",
	"TABOO",
	"TACIT",
	"TACKY",
	"TAFFY",
	"TAINT",
	"TAKEN",
	"TAKER",
	"TALLY",
	"TALON",
	"TAMER",
	"TANGO",
	"TANGY",
	"TAPER",
	"TAPIR",
	"TARDY",
	"TAROT",
	"TASTE",
	"TASTY",
	"TATTY",
	"TAUNT",
	"TAWNY",
	"TEACH",
	"TEARY",
	"TEASE",
	"TEDDY",
	"TEETH",
	"TEMPO",
	"TENET",
	"TENOR",
	"TENSE",
	"TENTH",
	"TEPEE",
	"TEPID",
	"TERRA",
	"TERSE",
	"TESTY",
	"THANK",
	"THEFT",
	"THEIR",
	"THEME",
	"THERE",
	"THESE",
	"THETA",
	"THICK",
	"THIEF",
	"THIGH",
	"THING",
	"THINK",
	"THIRD",
	"THONG",
	"THORN",
	"THOSE",
	"THREE",
	"THREW",
	"THROB",
	"THROW",
	"THRUM",
	"THUMB",
	"THUMP",
	"THYME",
	"TIARA",
	"TIBIA",
	"TIDAL",
	"TIGER",
	"TIGHT",
	"TILDE",
	"TIMES",
	"TIMER",
	"TIMID",
	"TIPSY",
	"TIRED",
	"TIRES",
	"TITAN",
	"TITHE",
	"TITLE",
	"TOAST",
	"TODAY",
	"TODDY",
	"TOKEN",
	"TONAL",
	"TONGA",
	"TONIC",
	"TOOTH",
	"TOPAZ",
	"TOPIC",
	"TORCH",
	"TORSO",
	"TORUS",
	"TOTAL",
	"TOTEM",
	"TOUCH",
	"TOUGH",
	"TOWEL",
	"TOWER",
	"TOXIC",
	"TOXIN",
	"TRACE",
	"TRACK",
	"TRACT",
	"TRADE",
	"TRAIL",
	"TRAIN",
	"TRAIT",
	"TRAMP",
	"TRASH",
	"TRAWL",
	"TREAD",
	"TREAT",
	"TREND",
	"TRIAD",
	"TRIAL",
	"TRIBE",
	"TRICE",
	"TRICK",
	"TRIED",
	"TRIPE",
	"TRITE",
	"TROLL",
	"TROOP",
	"TROPE",
	"TROUT",
	"TROVE",
	"TRUCE",
	"TRUCK",
	"TRUER",
	"TRULY",
	"TRUMP",
	"TRUNK",
	"TRUSS",
	"TRUST",
	"TRUTH",
	"TRYST",
	"TUBAL",
	"TUBER",
	"TULIP",
	"TULLE",
	"TUMOR",
	"TUNIC",
	"TURBO",
	"TUTOR",
	"TWANG",
	"TWEAK",
	"TWEED",
	"TWEET",
	"TWICE",
	"TWINE",
	"TWIRL",
	"TWIST",
	"TWIXT",
	"TYING",
	"UDDER",
	"ULCER",
	"ULTRA",
	"UMBRA",
	"UNCLE",
	"UNCUT",
	"UNDER",
	"UNDID",
	"UNDUE",
	"UNFED",
	"UNFIT",
	"UNIFY",
	"UNION",
	"UNITE",
	"UNITY",
	"UNLIT",
	"UNMET",
	"UNSET",
	"UNTIE",
	"UNTIL",
	"UNWED",
	"UNZIP",
	"UPPER",
	"UPSET",
	"URBAN",
	"URINE",
	"USAGE",
	"USHER",
	"USING",
	"USUAL",
	"USURP",
	"UTILE",
	"UTTER",
	"VAGUE",
	"VALET",
	"VALID",
	"VALOR",
	"VALUE",
	"VALVE",
	"VAPID",
	"VAPOR",
	"VAULT",
	"VAUNT",
	"VEGAN",
	"VENOM",
	"VENUE",
	"VERGE",
	"VERSE",
	"VERSO",
	"VERVE",
	"VICAR",
	"VIDEO",
	"VIGIL",
	"VIGOR",
	"VILLA",
	"VINYL",
	"VIOLA",
	"VIPER",
	"VIRAL",
	"VIRUS",
	"VISIT",
	"VISOR",
	"VISTA",
	"VITAL",
	"VIVID",
	"VIXEN",
	"VOCAL",
	"VODKA",
	"VOGUE",
	"VOICE",
	"VOILA",
	"VOMIT",
	"VOTER",
	"VOUCH",
	"VOWEL",
	"VYING",
	"WACKY",
	"WAFER",
	"WAGER",
	"WAGON",
	"WAIST",
	"WAIVE",
	"WALTZ",
	"WARTY",
	"WASTE",
	"WATCH",
	"WATER",
	"WAVER",
	"WAXEN",
	"WEARY",
	"WEAVE",
	"WEDGE",
	"WEEDY",
	"WEEKS",
	"WEIGH",
	"WEIRD",
	"WELCH",
	"WELDS",
	"WELSH",
	"WHACK",
	"WHALE",
	"WHARF",
	"WHEAT",
	"WHEEL",
	"WHELP",
	"WHERE",
	"WHICH",
	"WHIFF",
	"WHILE",
	"WHINE",
	"WHINY",
	"WHIRL",
	"WHISK",
	"WHITE",
	"WHOLE",
	"WHOOP",
	"WHOSE",
	"WIDEN",
	"WIDER",
	"WIDOW",
	"WIDTH",
	"WIELD",
	"WIGHT",
	"WILLY",
	"WIMPY",
	"WINCE",
	"WINCH",
	"WINDY",
	"WIRES",
	"WISER",
	"WISPY",
	"WITCH",
	"WITTY",
	"WOKEN",
	"WOMAN",
	"WOMEN",
	"WOODY",
	"WOOER",
	"WOOLY",
	"WOOZY",
	"WORDS",
	"WORDY",
	"WORLD",
	"WORRY",
	"WORSE",
	"WORST",
	"WORTH",
	"WOULD",
	"WOUND",
	"WOVEN",
	"WRACK",
	"WRATH",
	"WREAK",
	"WRECK",
	"WREST",
	"WRING",
	"WRIST",
	"WRITE",
	"WRONG",
	"WROTE",
	"WRUNG",
	"WRYLY",
	"YACHT",
	"YEARN",
	"YEARS",
	"YEAST",
	"YIELD",
	"YOUNG",
	"YOUTH",
	"ZEBRA",
	"ZESTY",
	"ZONAL",
	"BOXED",
	"BUMPS",
	"CHIVE",
	"CHOMP",
	"CLIMB",
	"CRWTH",
	"EXPAT",
	"GIZMO",
	"GULPS",
	"HAWKS",
	"HYDRA",
	"JULEP",
	"JOWLS",
	"KINGS",
	"KUDOS",
	"LAZED",
	"MYTHS",
	"OASIS",
	"QUAFF",
	"QUIPS",
	"SYLPH",
	"VEXED",
	"VOXEL",
	"WHIZZ",
	"WIZEN",
	"XYLEM",
	"YODEL",
	"YOKEL",
	"YUMMY",
	"YUPPY",
	"ZAPPY",
	"ZILCH",
	"ZONED",
	"ZONKS"
}

_G.auditTypes = {
	{
		label = "Message Edit",
		value = "msgedit",
		description = "Send a log when a message is edited.",
		emoji = resolvedEmojis.chat
	},
	{
		label = "Message Delete",
		value = "msgdelete",
		description = "Send a log when a message is deleted.",
		emoji = resolvedEmojis.chat
	},
	{
		label = "Member Join",
		value = "memberjoin",
		description = "Send a log when a member joins the server.",
		emoji = resolvedEmojis.person
	},
	{
		label = "Member Update",
		value = "memberupdate",
		description = "Send a log when a member is changed.",
		emoji = resolvedEmojis.person
	},
	{
		label = "Member Leave",
		value = "memberleave",
		description = "Send a log when a member leaves the server.",
		emoji = resolvedEmojis.person
	},
	{
		label = "Channel Create",
		value = "channelcreate",
		description = "Send a log when a channel is created.",
		emoji = resolvedEmojis.channel
	},
	{
		label = "Channel Update",
		value = "channelupdate",
		description = "Send a log when a channel is changed.",
		emoji = resolvedEmojis.channel
	},
	{
		label = "Channel Delete",
		value = "channeldelete",
		description = "Send a log when a channel is deleted.",
		emoji = resolvedEmojis.channel
	},
	{
		label = "Role Create",
		value = "rolecreate",
		description = "Send a log when a role is created.",
		emoji = resolvedEmojis.role
	},
	{
		label = "Role Update",
		value = "roleupdate",
		description = "Send a log when a role is changed.",
		emoji = resolvedEmojis.role
	},
	{
		label = "Role Delete",
		value = "roledelete",
		description = "Send a log when a role is deleted.",
		emoji = resolvedEmojis.role
	},
	{
		label = "Reaction Add",
		value = "reactionadd",
		description = "Send a log when a reaction is added to a message.",
		emoji = resolvedEmojis.emoji
	},
	{
		label = "Reaction Remove",
		value = "reactionremove",
		description = "Send a log when a reaction is removed from a message.",
		emoji = resolvedEmojis.emoji
	},
	{
		label = "Guild Update",
		value = "guildupdate",
		description = "Send a log when the server is changed.",
		emoji = resolvedEmojis.guild
	},
	{
		label = "Message Pin/Unpin",
		value = "msgpin",
		description = "Send a log when a message is pinned or unpinned.",
		emoji = resolvedEmojis.pin
	},
	{
		label = "Emoji Update",
		value = "emojiupdate",
		description = "Send a log when an emoji is create/updated/deleted.",
		emoji = resolvedEmojis.emoji
	}
}

_G.featureLimits = {
	automationActions = {
		normal = 5,
		plus = 15
	},
	automationConditions = {
		normal = 5
	},
	automations = {
		normal = 15,
		plus = 50
	},
	autoresponders = {
		normal = 3,
		plus = 25
	},
	reactionboards = {
		normal = 1,
		plus = 10
	},
	ticketPanels = {
		normal = 1,
		plus = 5
	},
	ticketForms = {
		normal = 2,
		plus = 5
	},
	infractionTypes = {
		normal = 25
	},
	infractionActions = {
		normal = 5
	},
	shiftTypes = {
		normal = 25
	},
	departmentLinkedRoles = {
		normal = 10
	},
	discordStatusChannels = {
		normal = 3,
		plus = 6
	},
	erlcStatusChannels = {
		normal = 3,
		plus = 6
	},
	autodeletechannels = {
		normal = 3,
		plus = 10
	},
	stickymessages = {
		normal = 3,
		plus = 10
	},
	erlcCommandQueueLimit = {
		plus = 20
	},
	economyReplies = {
		normal = 25
	},
	collectionRoles = {
		normal = 25
	},
	shopItems = {
		normal = 25
	},
	economyMultipliers = {
		normal = 25
	},
	regionPoints = {
		normal = 10,
		plus = 25
	},
	regions = {
		normal = 10,
		plus = 25
	}
}

utils.Start = function()
	print("[Ducky] | Loading utility functions...")
	local startl = os.clock()

	local function toISO(epoch)
		return discordia.Date.fromSeconds(epoch):toISO()
	end

	_G.toISO = toISO

	local function fromISO(iso)
		if (not iso) or (iso == "") then
			return 0
		else
			return math.floor(discordia.Date.fromISO(iso):toSeconds())
		end
	end

	_G.fromISO = fromISO

	local junkletters = {
		"A",
		"B",
		"C",
		"D",
		"E",
		"F",
		"G",
		"H",
		"I",
		"J",
		"K",
		"L",
		"M",
		"N",
		"O",
		"P",
		"Q",
		"R",
		"S",
		"T",
		"U",
		"V",
		"W",
		"X",
		"Y",
		"Z"
	}
	local junknums = {
		"1",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"8",
		"9",
		"0"
	}

	local function junkStr(len)
		local str = ""

		for i = 1, len do
			local letornum = math.random(1, 2)
			if letornum == 1 then
				local randomlet = junkletters[math.random(1, #junkletters)]
				local caporlow = math.random(1, 2)
				if caporlow == 1 then
					str = str .. randomlet
				else
					str = str .. randomlet:lower()
				end
			else
				local randomnum = junknums[math.random(1, #junknums)]
				str = str .. randomnum
			end
		end

		return str
	end

	_G.junkStr = junkStr

	local function convert(str, denyseconds)
		if not str then
			return nil
		end

		str = str:gsub(" ", ""):gsub(",", ""):gsub("second", "s"):gsub("seconds", "s"):gsub("minute", "m"):gsub("minutes", "m"):gsub("hour", "h"):gsub("hours", "h"):gsub("day", "d"):gsub("days", "d"):gsub("week", "w"):gsub("weeks", "w"):gsub("year", "y"):gsub("years", "y")

		local units = {
			s = 1,
			m = 60,
			h = 3600,
			d = 86400,
			w = 604800,
			y = 31449600
		}
		local matchpattern = ""

		if denyseconds then
			units.s = nil
			matchpattern = "(%d+)([mhdwy"
		else
			matchpattern = "(%d+)([smhdwy"
		end

		matchpattern = matchpattern .. "]?)"

		local total = 0

		for i, v in str:gmatch(matchpattern) do
			local add = tonumber(i) * (units[v] or ((denyseconds and 0) or 1))
			total = total + add
		end

		if total == 0 then
			return nil
		end

		return total
	end

	_G.convert = convert

	local function realtime()
		local seconds, microseconds = _G.uv.gettimeofday()

		return seconds + (microseconds / 1000000)
	end

	_G.realtime = realtime

	local function readable(s, noMS)
		if type(s) == "table" then
			if s.weekday then
				return string.format("Every %s at %02d:%02d %s", s.weekday, s.time.hour, s.time.min, s.tz)
			elseif s.type == "daily" then
				return string.format("Every day at %02d:%02d %s", s.time.hour, s.time.min, s.tz)
			else
				return string.format("%s at %02d:%02d %s", string.capitalize(s.type), s.time.hour, s.time.min, s.tz)
			end
		else
			local r = discordia.Time.fromSeconds(s):toString()

			return (noMS and r:gsub(", %d+ milliseconds", "")) or r
		end
	end

	_G.readable = readable

	local function prompt(ia, title, questions, callback, defer)
		local newModalData = {}

		newModalData.title = title
		newModalData.custom_id = junkStr(25)
		newModalData.components = {}

		local responseMap = {}

		for _, question in ipairs(questions) do
			question.identifier = question.component and question.component.custom_id or junkStr(5)

			if question.question then
				table.insert(newModalData.components, {
					type = 18,
					label = string.truncate(question.question, 45),
					component = question.component or {
						type = 4,
						custom_id = question.identifier,
						placeholder = question.placeholder and string.truncate(question.placeholder, 100),
						style = (question.style == "long" or question.style == "paragraph") and 2 or 1,
						required = question.required,
						value = question.default,
						min_length = question.min,
						max_length = question.max
					}
				})
			elseif question.text then
				table.insert(newModalData.components, {
					type = 10,
					content = question.text
				})
			end
		end

		if not ia then
			return responseMap
		end

		ia:modal(newModalData)

		local _, mia = Client:waitModal(newModalData.custom_id, ia.user.id)
		if (not mia) then
			return
		end

		for _, label in pairs(mia.data and mia.data.components or {}) do
			local component = label.component
			local id = component and component.custom_id
			local question = table.find(questions, function(v)
				return v.identifier == id
			end)

			if question then
				local response = (question and question.component and question.component.max_values == 1 and component.values and component.values[1]) or component.values or component.value

				if type(response) == "table" and not next(response) then
					response = nil
				end

				if response ~= nil and response ~= "" or question.required then
					if question.validate then
						local success, err = question.validate(response)
						if not success then
							return mia:fail(err, nil, true)
						elseif success ~= true then
							response = success
						end
					end

					responseMap[question.question] = response
				end
			end
		end

		if defer then
			mia:updateDeferred(true)
		end

		return callback(mia, responseMap)
	end

	_G.prompt = prompt

	local function ask(intr, title, placeholder, id, inputid, style, required, default, cb, min, max)
		if required == nil then
			required = true
		end
		return prompt(intr, title, {
			{
				question = string.truncate(title, 45),
				placeholder = placeholder and string.truncate(placeholder, 100),
				default = default,
				min = min,
				max = max,
				required = required,
				style = style
			}
		}, function(mia, responses)
			if mia then
				cb(_, mia, responses[string.truncate(title, 45)])
			end
		end)
	end

	_G.ask = ask

	local function fixCompId(t, direction, clean)
		if type(t) ~= "table" then
			return
		end

		local isComponent = (t.type == 2 or t.type == 3)

		if isComponent then
			if direction == "custom_id" then
				if t.id then
					t.custom_id = t.custom_id or t.id
					if clean then
						t.id = nil
					end
				end

			elseif direction == "id" then
				if t.custom_id then
					t.id = t.id or t.custom_id
					if clean then
						t.custom_id = nil
					end
				end
			end
		end

		for k, v in pairs(t) do
			if k ~= "emoji" and type(v) == "table" then
				fixCompId(v, direction, clean)
			end
		end
	end

	_G.fixCompId = fixCompId

	local function sanitizeButtons(components)
		if not components then
			return
		end

		for _, row in ipairs(components) do
			if row.components then
				for _, component in ipairs(row.components) do
					if component.style == 5 then
						component.custom_id = nil
						component.id = nil
					else
						component.url = nil
						component.custom_id = component.custom_id
						component.id = nil
					end
				end
			end
		end
	end

	_G.sanitizeButtons = sanitizeButtons

	local function validateButtons(components)
		if not components then
			return nil, nil
		end

		local removed = {}
		local newComponents = {}

		for rowIndex, row in ipairs(components) do
			if row and row.type == 1 and row.components then
				local newRow = {
					type = 1,
					components = {}
				}

				for compIndex, component in ipairs(row.components) do
					if component and component.type == 2 then
						local label = component.label or ("Button " .. compIndex)

						if component.style == 5 then
							if not component.url then
								removed[#removed + 1] = "Removed link button '" .. label .. "' (row " .. rowIndex .. "): missing url"
							else
								component.custom_id = nil
								component.id = nil
								newRow.components[#newRow.components + 1] = component
							end
						else
							local cid = component.custom_id or component.id

							if not cid then
								removed[#removed + 1] = "Removed button '" .. label .. "' (row " .. rowIndex .. "): missing custom_id"
							else
								component.custom_id = cid
								component.id = nil
								component.url = nil
								newRow.components[#newRow.components + 1] = component
							end
						end
					end
				end

				if #newRow.components > 0 then
					newComponents[#newComponents + 1] = newRow
				end
			end
		end

		if #removed > 0 then
			return newComponents, table.concat(removed, "\n")
		end

		return newComponents, nil
	end

	_G.validateButtons = validateButtons

	local function onComp(msg, comptype, compid, userid, once, callback, noco)
		local debugInfo = debug.getinfo(2, "Sl")
		local origin = debugInfo.short_src .. ":" .. debugInfo.currentline

		if not msg then
			Client:error("onComp | No message was provided | " .. origin)
			return
		elseif type(msg) ~= "table" then
			Client:error("onComp | Message type is not table | " .. origin)
			return
		elseif (not msg.reply) then
			Client:error("onComp | Message is not replyable | " .. origin)
			return
		elseif (not msg.channel) then
			Client:error("onComp | Message does not contain a channel | " .. origin)
			return
		elseif (not msg.components) then
			Client:error("onComp | Message does not contain components | " .. origin)
			return
		end

		coroutine.wrap(function()
			while true do
				local _, ia = msg:waitComponent(comptype, compid)
				local ui = userid or ia.user.id
				if ia.user.id == ui then
					local breakloop = coroutine.wrap(callback)(ia)
					if once or (breakloop == true) then
						break
					end
				else
					ia:fail("This is <@" .. userid .. ">'s menu. You cannot interact with these components.", nil, true)
				end
			end
		end)()
	end

	_G.onComp = onComp

	local function history(data)
		local history = {}
		local index = 1

		table.insert(history, table.deepcopy(data))

		local function save(d)
			if index ~= table.count(history) then
				for i = table.count(history), index, -1 do
					if i ~= 1 then
						table.remove(history, i)
					end
				end
			end
			local copy = table.deepcopy(d)
			table.insert(history, copy)
			index = table.count(history)
			return copy, history
		end

		local function undo()
			index = math.clamp(index - 1, 1, table.count(history))
			return table.deepcopy(history[index]), history
		end

		local function redo()
			index = math.clamp(index + 1, 1, table.count(history))
			return table.deepcopy(history[index]), history
		end

		return save, undo, redo
	end

	_G.history = history

	local function embedEditor(ia, cb, variableEmbedDescription, defaultEmbed)
		local embedEditorComps = discordia.Components()

		local editPropertySelect = discordia.SelectMenu({
			id = "editproperty",
			placeholder = "Edit a property...",
			actionRow = 1,
			min_values = 0,
			max_values = 1,
			options = {
				{
					label = "Edit Title",
					value = "title",
					emoji = resolvedEmojis.text
				},
				{
					label = "Edit Description",
					value = "description",
					emoji = resolvedEmojis.text
				},
				{
					label = "Edit Author",
					value = "author",
					emoji = resolvedEmojis.text
				},
				{
					label = "Edit Footer",
					value = "footer",
					emoji = resolvedEmojis.text
				},
				{
					label = "Edit Thumbnail",
					value = "thumbnail",
					emoji = resolvedEmojis.image
				},
				{
					label = "Edit Banner",
					value = "banner",
					emoji = resolvedEmojis.image
				},
				{
					label = "Add Field",
					value = "addfield",
					emoji = resolvedEmojis.list
				},
				{
					label = "Edit Field",
					value = "editfield",
					emoji = resolvedEmojis.list
				},
				{
					label = "Remove Field",
					value = "removefield",
					emoji = resolvedEmojis.list
				},
				{
					label = "Edit Color",
					value = "color",
					emoji = resolvedEmojis.paintbrush
				},
				{
					label = "Import",
					value = "import",
					emoji = resolvedEmojis.import
				},
				{
					label = "Export",
					value = "export",
					emoji = resolvedEmojis.export
				}
			}
		})

		embedEditorComps:selectMenu(editPropertySelect)

		coroutine.wrap(function()
			local variableEmbed = {
				title = emojis.json .. " Variables",
				description = variableEmbedDescription or emojis.fail .. " There are not any variables available for this embed.",
				color = (variableEmbedDescription and colors.blank) or colors.fail
			}

			if variableEmbedDescription and variableEmbedDescription ~= "" then
				local embedEditorVariables = discordia.Button({
					id = "variables",
					label = "Variables",
					emoji = resolvedEmojis.json,
					actionRow = 2,
					style = "secondary"
				})

				embedEditorComps:button(embedEditorVariables)
			end

			local embed = defaultEmbed or {
				title = emojis.art .. " Embed Editor",
				description = "> You can edit this embed using the components below, and press **" .. emojis.yeswhite .. " Save** when you are done.",
				color = colors.blank
			}

			local save, undo, redo = history(embed)

			embedEditorComps:button({
				id = "save",
				label = "Save",
				emoji = resolvedEmojis.yeswhite,
				actionRow = 2,
				style = "success"
			})

			embedEditorComps:button({
				id = "delete",
				label = "Delete",
				emoji = resolvedEmojis.delete,
				actionRow = 2,
				style = "danger"
			})

			embedEditorComps:button({
				id = "undo",
				emoji = resolvedEmojis.undo,
				actionRow = 2,
				style = "secondary"
			})

			embedEditorComps:button({
				id = "redo",
				emoji = resolvedEmojis.redo,
				actionRow = 2,
				style = "secondary"
			})

			local eb

			local function updateEditor(onError)
				local s, e = nil, nil

				local emb = parseTable(embed, {
					["(%S+)%.avatar"] = "https://cdn.discordapp.com/emojis/1316411205799247913.png"
				})

				local payload = {
					embed = emb,
					components = embedEditorComps:raw()
				}

				if type(eb) == "table" then
					if ia.editReply then
						s, e = ia:editReply({
							embed = emb,
							components = embedEditorComps:raw()
						}, eb.id)
					elseif eb.update then
						s, e = eb:update({
							embed = emb,
							components = embedEditorComps:raw()
						})
					end
				else
					s, e = ia:reply(payload, true)

					if s then
						eb = s
					end
				end

				if (not s) and (onError) then
					Client:error("Embed Editor received an error while attempting to update itself: " .. tostring(e))
					onError(e)
				elseif (not s) then
					if type(eb) == "table" then
						if ia.editReply then
							s, e = ia:editReply({
								embed = {
									title = emojis.warning .. " HTTP Error",
									description = emojis.right .. " An unhandled HTTP error occurred while attempting to load your embed:\n```\n" .. tostring(e) .. "```",
									color = colors.warning
								},
								components = embedEditorComps:raw()
							}, eb.id)
						elseif eb.update then
							s, e = eb:update({
								embed = {
									title = emojis.warning .. " HTTP Error",
									description = emojis.right .. " An unhandled HTTP error occurred while attempting to load your embed:\n```" .. tostring(e) .. "```",
									color = colors.warning
								},
								components = embedEditorComps:raw()
							})
						end
					else
						eb = ia:reply({
							embed = {
								title = emojis.warning .. " HTTP Error",
								description = emojis.right .. " An unhandled HTTP error occurred while attempting to load your embed:\n```\n" .. tostring(e) .. "```",
								color = colors.warning
							},
							components = embedEditorComps:raw()
						}, true)
					end
				end
			end

			updateEditor()

			onComp(eb, nil, nil, ia.user.id, false, function(eia)
				local id = eia.data.custom_id
				local selection = eia.data.values and eia.data.values[1]

				if id == "editproperty" then
					if selection == "title" then
						prompt(eia, "Edit Title", {
							{
								question = "Edit Title",
								placeholder = "Edit the embed's title...",
								default = embed.title,
								required = false
							}
						}, function(mia, responses)
							embed.title = responses["Edit Title"]
							embed = save(embed)
							updateEditor(function()
								embed = undo()
								updateEditor()
							end)
						end, true)
					elseif selection == "description" then
						prompt(eia, "Edit Description", {
							{
								question = "Edit Description",
								placeholder = "Edit the embed's description...",
								default = embed.description,
								required = false,
								style = "paragraph",
								max = 4000
							}
						}, function(mia, responses)
							embed.description = responses["Edit Description"]
							embed = save(embed)
							updateEditor(function()
								embed = undo()
								updateEditor()
							end)
						end, true)
					elseif selection == "author" then
						prompt(eia, "Edit Author", {
							{
								question = "Author Name",
								placeholder = "The small text on the top of the embed.",
								default = embed.author and embed.author.name,
								required = false,
								max = 256
							},
							{
								question = "Author Icon",
								placeholder = "The image URL for an icon next to the author's name.",
								default = embed.author and embed.author.icon_url,
								required = false
							}
						}, function(mia, responses)
							if responses["Author Icon"] and not responses["Author Name"] then
								responses["Author Icon"] = ""
							end

							embed.author = {
								name = responses["Author Name"] or "",
								icon_url = responses["Author Icon"] or ""
							}
							embed = save(embed)

							updateEditor(function()
								embed = undo()
								updateEditor()
							end)
						end, true)
					elseif selection == "footer" then
						prompt(eia, "Edit Footer", {
							{
								question = "Footer Text",
								placeholder = "The small text on the bottom of the embed.",
								default = embed.footer and embed.footer.text,
								required = false,
								max = 2048
							},
							{
								question = "Footer Icon",
								placeholder = "The image URL for an icon next to the footer text.",
								default = embed.footer and embed.footer.icon_url,
								required = false
							}
						}, function(mia, responses)
							if responses["Footer Icon"] and not responses["Footer Text"] then
								responses["Footer Icon"] = ""
							end

							embed.footer = {
								text = responses["Footer Text"] or "",
								icon_url = responses["Footer Icon"] or ""
							}
							embed = save(embed)

							updateEditor(function()
								embed = undo()
								updateEditor()
							end)
						end, true)
					elseif selection == "thumbnail" then
						prompt(eia, "Edit Thumbnail", {
							{
								question = "Edit Thumbnail",
								placeholder = "Enter a valid image URL...",
								default = embed.thumbnail and embed.thumbnail.url,
								required = false
							}
						}, function(mia, responses)
							embed.thumbnail = responses and responses["Edit Thumbnail"] and {
								url = responses["Edit Thumbnail"]
							}
							embed = save(embed)
							updateEditor(function()
								embed = undo()
								updateEditor()
							end)
						end, true)
					elseif selection == "banner" then
						prompt(eia, "Edit Banner", {
							{
								question = "Edit Banner",
								placeholder = "Enter a valid image URL...",
								default = embed.image and embed.image.url,
								required = false
							}
						}, function(mia, responses)
							embed.image = responses and responses["Edit Banner"] and {
								url = responses["Edit Banner"]
							}
							embed = save(embed)
							updateEditor(function()
								embed = undo()
								updateEditor()
							end)
						end, true)
					elseif selection == "addfield" then
						if (table.count(embed.fields or {}) >= 25) then
							eia:fail("You cannot add more than 25 fields to this embed.", nil, true)
							return
						end

						prompt(eia, "Add Field", {
							{
								question = "Field Name",
								placeholder = "What should this field be called?",
								required = true,
								style = "short",
								max = 256
							},
							{
								question = "Field Text",
								placeholder = "What should be within this field?",
								required = true,
								style = "paragraph",
								max = 1024
							},
							{
								question = "Field Inline",
								placeholder = "Should this field be inline? (Y/N)",
								require = false,
								style = "short",
								max = 1
							}
						}, function(mia, responses)
							local newField = {}

							if (not responses["Field Name"]) or (responses["Field Name"] == "") then
								return mia:fail("You did not provide a name for this field.", nil, true)
							end

							newField.name = responses["Field Name"]

							if (not responses["Field Text"]) or (responses["Field Text"] == "") then
								return mia:fail("You did not provide text for this field.", nil, true)
							end

							newField.value = responses["Field Text"]

							newField.inline = (responses["Field Inline"] and responses["Field Inline"]:lower() and ((responses["Field Inline"]:lower() == "y") or (responses["Field Inline"]:lower() == "i") or (responses["Field Inline"]:lower() == "t"))) or false

							embed.fields = embed.fields or {}

							table.insert(embed.fields, newField)
							embed = save(embed)

							updateEditor(function()
								embed = undo()
								updateEditor()
							end)
						end, true)
					elseif selection == "editfield" then
						if (not embed.fields) or (table.count(embed.fields) <= 0) then
							return eia:fail("There are no fields on this embed.", nil, true)
						end

						local options = {}

						for fieldIndex, field in pairs(embed.fields) do
							table.insert(options, {
								label = string.truncate(field.name, 25),
								description = string.truncate(field.value, 100),
								value = tostring(fieldIndex),
								emoji = resolvedEmojis.edit
							})
						end

						optionsSelect(eia, "Select a field...", function(opt, ia, r)
							local field = embed.fields and embed.fields[tonumber(opt)]

							if not field then
								return ia:fail("I could not find that field.", nil, true)
							end

							prompt(ia, "Edit Field", {
								{
									question = "Field Name",
									placeholder = "What should this field be called?",
									required = true,
									style = "short",
									max = 256,
									default = field.name
								},
								{
									question = "Field Text",
									placeholder = "What should be within this field?",
									required = true,
									style = "paragraph",
									max = 1024,
									default = field.value
								},
								{
									question = "Field Inline",
									placeholder = "Should this field be inline? (Y/N)",
									require = false,
									style = "short",
									max = 1,
									default = (field.inline and "Y") or "N"
								}
							}, function(mia, responses)
								local newField = {}

								if (not responses["Field Name"]) or (responses["Field Name"] == "") then
									return mia:fail("You did not provide a name for this field.", nil, true)
								end

								newField.name = responses["Field Name"]

								if (not responses["Field Text"]) or (responses["Field Text"] == "") then
									return mia:fail("You did not provide text for this field.", nil, true)
								end

								newField.value = responses["Field Text"]

								newField.inline = (responses["Field Inline"] and responses["Field Inline"]:lower() and ((responses["Field Inline"]:lower() == "y") or (responses["Field Inline"]:lower() == "i") or (responses["Field Inline"]:lower() == "t"))) or false

								embed.fields = embed.fields or {}
								embed.fields[tonumber(opt)] = newField
								embed = save(embed)

								eia:deleteReply(r.id)
								updateEditor(function()
									embed = undo()
									updateEditor()
								end)
							end, true)
						end, false, options, 1, nil, true)
					elseif selection == "removefield" then
						if (not embed.fields) or (table.count(embed.fields) <= 0) then
							return eia:fail("There are no fields on this embed.", nil, true)
						end

						local options = {}

						for fieldIndex, field in pairs(embed.fields) do
							table.insert(options, {
								label = string.truncate(field.name, 25),
								description = string.truncate(field.value, 100),
								value = tostring(fieldIndex),
								emoji = resolvedEmojis.delete
							})
						end

						optionsSelect(eia, "Select a field...", function(opt)
							table.remove(embed.fields or {}, tonumber(opt))
							embed = save(embed)
							updateEditor(function()
								embed = undo()
								updateEditor()
							end)
						end, true, options, 1, nil, true)
					elseif selection == "color" then
						prompt(eia, "Edit Color", {
							{
								question = "Edit Color",
								placeholder = "Enter a valid hex code...",
								default = embed.color and discordia.Color(embed.color):toHex(),
								required = false,
								max = 7
							}
						}, function(mia, responses)
							embed.color = responses["Edit Color"] and (colors[tostring(responses["Edit Color"])] or discordia.Color.fromHex(responses["Edit Color"]).value) or embed.color
							embed = save(embed)
							updateEditor(function()
								embed = undo()
								updateEditor()
							end)
						end, true)
					elseif selection == "import" then
						prompt(eia, "Import from JSON or Exportable", {
							{
								question = "Import Data",
								placeholder = "Enter a valid Ducky exportable code or JSON data...",
								style = "paragraph",
								required = false
							}
						}, function(mia, responses)
							if mia then
								if responses and responses["Import Data"] then
									local decoded, _, err = json.decode(responses["Import Data"])

									if decoded then
										embed = (decoded.embeds and decoded.embeds[1]) or decoded
										embed = save(embed)
										updateEditor(function()
											embed = undo()
											updateEditor()
										end)
									else
										local imported, err = import(responses["Import Data"], "embed")

										if imported then
											embed = imported
											embed = save(embed)
											updateEditor(function()
												embed = undo()
												updateEditor()
											end)
											return mia:updateDeferred(true)
										else
											updateEditor()
											return mia:fail(err, nil, true)
										end
									end
								else
									return mia:updateDeferred(true)
								end
							end
						end)
					elseif selection == "export" then
						prompt(eia, "Exportable Name", {
							{
								question = "What should this exportable be named?",
								placeholder = "Enter a name for this exportable...",
								style = "short",
								max = 100
							}
						}, function(mia, responses)
							local exported, err = export(embed, mia.user, "embed", responses["What should this exportable be named?"])

							if exported then
								mia:success("Your embed has been exported successfully! Here's your exportable code: ```\n" .. exported .. "```\n-# " .. emojis.right .. " You can share this code with other people for them to import your message.", nil, true)
							else
								mia:fail(err, nil, true)
							end
							updateEditor()
						end, true)
					else
						eia:updateDeferred(true)
					end
				elseif id == "variables" then
					eia:reply({
						embed = variableEmbed
					}, true)
				elseif id == "undo" then
					embed = undo()
					eia:updateDeferred(true)
					updateEditor(function()
						embed = redo()
						updateEditor()
					end)
				elseif id == "redo" then
					embed = redo()
					eia:updateDeferred(true)
					updateEditor(function()
						embed = undo()
						updateEditor()
					end)
				elseif id == "save" then
					updateEditor()
					if ia.deleteReply then
						ia:deleteReply(eb.id)
					else
						eb:delete()
					end
					pcall(cb, embed)
					return true
				elseif id == "delete" then
					if ia.deleteReply then
						ia:deleteReply(eb.id)
					else
						eb:delete()
					end
					pcall(cb, nil)
					return true
				else
					ia:updateDeferred(true)
				end
			end)
		end)()
	end

	_G.embedEditor = embedEditor

	local function multiEmbedEditor(ia, cb, variableEmbedDescription, defaultEmbeds)
		local multiEmbedEditorComps = discordia.Components()

		local multiEmbedSelectMenu = discordia.SelectMenu({
			id = "changeembeds",
			placeholder = "Edit embeds...",
			actionRow = 1,
			min_values = 0,
			max_values = 1,
			options = {
				{
					label = "Add Embed",
					value = "add",
					emoji = resolvedEmojis.add
				},
				{
					label = "Edit Embed",
					value = "edit",
					emoji = resolvedEmojis.edit
				},
				{
					label = "Remove Embed",
					value = "remove",
					emoji = resolvedEmojis.subtract
				},
				{
					label = "Import Embeds",
					value = "import",
					emoji = resolvedEmojis.import
				},
				{
					label = "Export Embeds",
					value = "export",
					emoji = resolvedEmojis.export
				}
			}
		})

		multiEmbedEditorComps:selectMenu(multiEmbedSelectMenu)

		local variableEmbed = {
			title = emojis.json .. " Variables",
			description = variableEmbedDescription or emojis.fail .. " There are not any variables available for this embed.",
			color = (variableEmbedDescription and colors.blank) or colors.fail
		}

		if variableEmbedDescription and variableEmbedDescription ~= "" then
			local embedEditorVariables = discordia.Button({
				id = "variables",
				label = "Variables",
				emoji = resolvedEmojis.json,
				actionRow = 2,
				style = "secondary"
			})

			multiEmbedEditorComps:button(embedEditorVariables)
		end

		local embeds = defaultEmbeds or {}

		local save, undo, redo = history(embeds)

		multiEmbedEditorComps:button({
			id = "save",
			label = "Save",
			emoji = resolvedEmojis.yeswhite,
			actionRow = 2,
			style = "success"
		})

		multiEmbedEditorComps:button({
			id = "delete",
			label = "Delete",
			emoji = resolvedEmojis.delete,
			actionRow = 2,
			style = "danger"
		})

		multiEmbedEditorComps:button({
			id = "undo",
			emoji = resolvedEmojis.undo,
			actionRow = 2,
			style = "secondary"
		})

		multiEmbedEditorComps:button({
			id = "redo",
			emoji = resolvedEmojis.redo,
			actionRow = 2,
			style = "secondary"
		})

		local meb

		local function updateEditor(onError)
			local s, e = nil, nil

			local embs = next(embeds) and parseTable(embeds, {
				["(%S+)%.avatar"] = "https://cdn.discordapp.com/emojis/1316411205799247913.png"
			}) or {
				{
					title = emojis.art .. " Multi Embed Editor",
					description = "> You can add/edit/remove embeds using the select menu below, and press **" .. emojis.yeswhite .. " Save** when you are done.",
					color = colors.blank
				}
			}

			local payload = {
				embeds = embs,
				components = multiEmbedEditorComps:raw()
			}

			if type(meb) == "table" then
				if ia.editReply then
					s, e = ia:editReply(payload, meb.id)
				elseif meb.update then
					s, e = meb:update(payload)
				end
			else
				s, e = ia:reply(payload, true)

				if s then
					meb = s
				end
			end

			if (not s) and (onError) then
				Client:error("Embed Editor received an error while attempting to update itself: " .. tostring(e))
				onError(e)
			elseif (not s) then
				if type(meb) == "table" then
					if ia.editReply then
						s, e = ia:editReply({
							embed = {
								title = emojis.warning .. " HTTP Error",
								description = emojis.right .. " An unhandled HTTP error occurred while attempting to load your embed:\n```\n" .. tostring(e) .. "```",
								color = colors.warning
							},
							components = multiEmbedEditorComps:raw()
						}, meb.id)
					elseif meb.update then
						s, e = meb:update({
							embed = {
								title = emojis.warning .. " HTTP Error",
								description = emojis.right .. " An unhandled HTTP error occurred while attempting to load your embed:\n```" .. tostring(e) .. "```",
								color = colors.warning
							},
							components = multiEmbedEditorComps:raw()
						})
					end
				else
					meb = ia:reply({
						embed = {
							title = emojis.warning .. " HTTP Error",
							description = emojis.right .. " An unhandled HTTP error occurred while attempting to load your embed:\n```\n" .. tostring(e) .. "```",
							color = colors.warning
						},
						components = multiEmbedEditorComps:raw()
					}, true)
				end
			end
		end

		updateEditor()

		onComp(meb, nil, nil, ia.user.id, false, function(meia)
			local id = meia.data.custom_id
			local selection = meia.data.values and meia.data.values[1]

			if id == "changeembeds" then
				if selection == "add" then
					if table.count(embeds) >= 10 then
						return meia:fail("The maximum amount of embeds is 10.", nil, true)
					end

					embedEditor(meia, function(embed)
						if embed then
							table.insert(embeds, embed)
						end

						embeds = save(embeds)

						updateEditor(function()
							embeds = undo()
							updateEditor()
						end)
					end, variableEmbedDescription)
				elseif selection == "edit" then
					if not next(embeds) then
						return meia:fail("You have not added any embeds.", nil, true)
					end

					local opts = {}

					for i, embed in ipairs(embeds) do
						table.insert(opts, {
							label = "#" .. tostring(i) .. " Embed",
							description = (embed.title and string.truncate(sanitizeUTF8(embed.title), 50)) or (embed.description and string.truncate(sanitizeUTF8(embed.description), 50)),
							value = tostring(i),
							emoji = resolvedEmojis.edit
						})
					end

					optionsSelect(meia, "Select an embed...", function(opt, cia, cr)
						local emb1 = embeds[tonumber(opt)]

						if not emb1 then
							return cia:fail("I could not find that embed.", nil, true)
						end

						meia:deleteReply(cr.id)
						embedEditor(cia, function(emb2)
							if not embeds[tonumber(opt)] then
								return cia:fail("I could not find that embed.", nil, true)
							end

							embeds[tonumber(opt)] = emb2
							embeds = save(embeds)

							updateEditor(function()
								embeds = undo()
								updateEditor()
							end)
						end, variableEmbedDescription, emb1)
					end, false, opts, 1, nil, true)
				elseif selection == "remove" then
					if not next(embeds) then
						return meia:fail("You have not added any embeds.", nil, true)
					end

					local opts = {}

					for i, embed in ipairs(embeds) do
						table.insert(opts, {
							label = "#" .. tostring(i) .. " Embed",
							description = (embed.title and string.truncate(sanitizeUTF8(embed.title), 50)) or (embed.description and string.truncate(sanitizeUTF8(embed.description), 50)),
							value = tostring(i),
							emoji = resolvedEmojis.edit
						})
					end

					optionsSelect(meia, "Select an embed...", function(opt, cia, cr)
						local emb1 = embeds[tonumber(opt)]

						if not emb1 then
							return cia:fail("I could not find that embed.", nil, true)
						end

						meia:deleteReply(cr.id)
						cia:updateDeferred(true)
						table.remove(embeds, tonumber(opt))
						embeds = save(embeds)

						updateEditor(function()
							embeds = undo()
							updateEditor()
						end)
					end, false, opts, 1, nil, true)
				elseif selection == "import" then
					prompt(meia, "Import from JSON or Exportable", {
						{
							question = "Import Data",
							placeholder = "Enter a valid Ducky exportable code or JSON data...",
							style = "paragraph",
							required = false
						}
					}, function(mia, responses)
						if mia then
							if responses and responses["Import Data"] then
								local decoded, _, err = json.decode(responses["Import Data"])

								if decoded then
									embeds = decoded.embeds or decoded
									embeds = save(embeds)
									updateEditor(function()
										embeds = undo()
										updateEditor()
									end)
									return mia:updateDeferred(true)
								else
									local imported, err = import(responses["Import Data"], "embeds")

									if imported then
										embeds = imported
										embeds = save(embeds)
										updateEditor(function()
											embeds = undo()
											updateEditor()
										end)
										return mia:updateDeferred(true)
									else
										updateEditor()
										return mia:fail(err, nil, true)
									end
								end
							else
								return mia:updateDeferred(true)
							end
						end
					end)
				elseif selection == "export" then
					prompt(meia, "Exportable Name", {
						{
							question = "What should this exportable be named?",
							placeholder = "Enter a name for this exportable...",
							style = "short",
							max = 100
						}
					}, function(mia, responses)
						local exported, err = export(embeds, mia.user, "embeds", responses["What should this exportable be named?"])

						if exported then
							mia:success("Your embeds have been exported successfully! Here's your exportable code: ```\n" .. exported .. "```\n-# " .. emojis.right .. " You can share this code with other people for them to import your embeds.", nil, true)
						else
							mia:fail(err, nil, true)
						end
						updateEditor()
					end, true)
				else
					meia:updateDeferred(true)
				end
			elseif id == "variables" then
				return meia:reply({
					embed = variableEmbed
				}, true)
			elseif id == "undo" then
				embeds = undo()
				meia:updateDeferred(true)
				updateEditor(function()
					embeds = redo()
					updateEditor()
				end)
			elseif id == "redo" then
				embeds = redo()
				meia:updateDeferred(true)
				updateEditor(function()
					embeds = undo()
					updateEditor()
				end)
			elseif id == "save" then
				updateEditor()
				if ia.deleteReply then
					ia:deleteReply(meb.id)
				else
					meb:delete()
				end
				pcall(cb, embeds)
				return true
			elseif id == "delete" then
				if ia.deleteReply then
					ia:deleteReply(meb.id)
				else
					meb:delete()
				end
				pcall(cb, nil)
				return true
			else
				ia:updateDeferred(true)
			end
		end)
	end

	_G.multiEmbedEditor = multiEmbedEditor

	local function componentsEditor(ia, cb, defaultComps)
		local comps = defaultComps or {}

		local save, undo, redo = history(comps)
		local cer

		local function updateEditor()
			local allComps = discordia.Components()

			local row = 1
			local countInRow = 0

			local function nextRow()
				row = row + 1
				countInRow = 0
			end

			for _, r in ipairs(comps) do
				for _, comp in ipairs(r.components or {}) do
					if comp.type == 3 then
						if countInRow > 0 then
							nextRow()
						end

						if row > 2 then
							p("ignoring extra selectMenu (would exceed 2 rows)")
							break
						end

						comp.actionRow = row
						allComps:selectMenu(comp)

						nextRow()
					else
						if countInRow >= 5 then
							nextRow()
						end
						if row > 2 then
							p("ignoring extra buttons (would exceed 2 rows)")
							break
						end

						comp.actionRow = row
						allComps:button(comp)

						countInRow = countInRow + 1
					end
				end
			end

			if countInRow > 0 then
				nextRow()
			end

			allComps:selectMenu({
				id = "editcomps",
				placeholder = "Edit components...",
				actionRow = row,
				min_values = 0,
				max_values = 1,
				options = {
					{
						label = "Add Button",
						value = "addbutton",
						emoji = resolvedEmojis.add
					},
					{
						label = "Edit Button",
						value = "editbutton",
						emoji = resolvedEmojis.edit
					},
					{
						label = "Remove Button",
						value = "removebutton",
						emoji = resolvedEmojis.subtract
					},
					{
						label = "Add Dropdown Menu",
						value = "adddropdown",
						emoji = resolvedEmojis.add
					},
					{
						label = "Edit Dropdown Menu",
						value = "editdropdown",
						emoji = resolvedEmojis.edit
					},
					{
						label = "Remove Dropdown Menu",
						value = "removedropdown",
						emoji = resolvedEmojis.subtract
					}
				}
			}):button({
				id = "save",
				label = "Save",
				emoji = resolvedEmojis.yeswhite,
				actionRow = row + 1,
				style = "success"
			}):button({
				id = "delete",
				label = "Delete",
				emoji = resolvedEmojis.delete,
				actionRow = row + 1,
				style = "danger"
			}):button({
				id = "undo",
				emoji = resolvedEmojis.undo,
				actionRow = row + 1,
				style = "secondary"
			}):button({
				id = "redo",
				emoji = resolvedEmojis.redo,
				actionRow = row + 1,
				style = "secondary"
			})

			local s, e

			if type(cer) == "table" then
				if ia.editReply then
					s, e = ia:editReply({
						components = allComps:raw()
					}, cer.id)
				elseif cer.update then
					s, e = cer:update({
						components = allComps:raw()
					})
				end
			else
				cer = ia:reply({
					components = allComps:raw()
				}, true)
			end
		end

		updateEditor()

		onComp(cer, nil, nil, ia.user.id, false, function(ceia)
			local id = ceia.data.custom_id
			local selection = ceia.data.values and ceia.data.values[1]

			if id == "editcomps" then
				local function promptButton(ia, opt, existingPath)
					local existingSplit = string.split(existingPath, "/")
					local existingIdx1, existingIdx2 = tonumber(existingSplit[1]), tonumber(existingSplit[2])

					local existing = comps and comps[existingIdx1] and comps[existingIdx1].components and comps[existingIdx1].components[existingIdx2]

					if existingPath and not existing then
						return ia:fail("I could not find that button.", nil, true)
					end

					local questions = {
						{
							question = "What text should show on the button?",
							style = "short",
							required = false,
							max = 80,
							default = existing and existing.label
						},
						{
							question = "What emoji should the button have?",
							placeholder = "Either a Ducky emoji name or an emoji ID...",
							style = "short",
							required = false,
							max = 30,
							default = existing and existing.emoji and ((emojis[existing.emoji.name] and existing.emoji.name) or existing.emoji.id)
						},
						{
							question = "Should this button be disabled?",
							component = discordia.SelectMenu({
								id = "toggle",
								placeholder = "Select an option...",
								max_values = 1,
								required = false,
								options = {
									{
										label = "Yes",
										value = "yes",
										emoji = resolvedEmojis.success,
										default = existing and existing.disabled == true or false
									},
									{
										label = "No",
										value = "no",
										emoji = resolvedEmojis.fail,
										default = not (existing and existing.disabled == true)
									}
								}
							}):raw(),
							required = false
						}
					}

					if opt == "link" then
						table.insert(questions, {
							question = "To what link should this link button go to?",
							placeholder = "Must be a URL that starts with https://...",
							style = "short",
							required = true,
							max = 512,
							default = existing and existing.url
						})
					else
						table.insert(questions, {
							question = "What exportable should Ducky reply with?",
							style = "short",
							required = false,
							max = 31,
							default = (existing and not existing.disabled and existing.id) and existing.id:match("^ducky_(.+)$") or nil
						})
					end

					prompt(ia, (existing and "Edit" or "New") .. " Button", questions, function(mia, responses)
						if not mia then
							return
						end

						if not responses["What text should show on the button?"] and not responses["What emoji should the button have?"] then
							mia:fail("You must provide a Label and/or an Emoji.", nil, true)
							return updateEditor()
						end

						local isDisabled = responses["Should this button be disabled?"] == "yes"

						local resolvedEmoji
						if responses["What emoji should the button have?"] then
							local emojiInput = responses["What emoji should the button have?"]
							if emojis[emojiInput] then
								resolvedEmoji = resolvedEmojis[emojiInput]
							else
								local guildEmoji = ia.guild:getEmoji(emojiInput)
								if not guildEmoji then
									return mia:fail("You did not provide a valid emoji.", nil, true)
								end
								resolvedEmoji = resolveEmoji(guildEmoji.mentionString)
							end
						end

						local exportableInput = responses["What exportable should Ducky reply with?"]

						if not isDisabled and opt ~= "link" then
							if not exportableInput or exportableInput == "" then
								mia:fail("You need to provide a valid exportable code.", nil, true)
								return updateEditor()
							end
						end

						local exportable = exportableInput and import(exportableInput, nil, true)
						if exportableInput and (not exportable or (exportable.type ~= "embed" and exportable.type ~= "message")) then
							mia:fail("You must provide a valid Embed or Message exportable.", nil, true)
							return updateEditor()
						end

						for idx1, row in ipairs(comps) do
							for idx2, comp in ipairs(row.components or {}) do
								if exportable and comp.id == "compbuilder_" .. exportable.id and (not existing or idx1 ~= existingIdx1 or idx2 ~= existingIdx2) then
									mia:fail("That exportable has already been used in a button.", nil, true)
									return updateEditor()
								end
							end
						end

						local isLink = opt == "link"
						local urlRes = responses["To what link should this link button go to?"]

						local id
						local url

						if isLink then
							if not urlRes or not urlRes:match("^https?://") then
								return mia:fail("You must provide a valid HTTPS URL.", nil, true)
							end

							url = urlRes
							id = nil
						else
							url = nil

							if not isDisabled then
								if not exportable then
									return mia:fail("You must provide a valid Embed or Message exportable.", nil, true)
								end

								id = "compbuilder_" .. exportable.id
							else
								id = existing and existing.id or ("disabled_" .. snowGen:next())
							end
						end

						local newButton = {
							type = 2,
							label = responses["What text should show on the button?"],
							emoji = resolvedEmoji,
							style = opt,
							url = url,
							id = id,
							disabled = isDisabled
						}

						if existing then
							for idx1, row in ipairs(comps) do
								if idx1 == existingIdx1 then
									for idx2, comp in ipairs(row.components or {}) do
										if idx2 == existingIdx2 then
											comps[idx1].components[idx2] = newButton
										end
									end
								end
							end
						else
							local lastRow = comps[#comps]
							local countInLastRow = lastRow and #lastRow.components or 0
							local currentRows = #comps

							local wouldExceedRows = false
							if countInLastRow >= 5 then
								if (currentRows + 1) > 2 then
									wouldExceedRows = true
								end
							else
								if currentRows > 2 then
									wouldExceedRows = true
								end
							end

							if wouldExceedRows then
								ia:fail("You cannot add more than 2 rows of components.", nil, true)
								return updateEditor()
							end

							if #comps == 0 then
								table.insert(comps, {
									components = {
										newButton
									}
								})
							else
								local lastRow = comps[#comps]
								if #lastRow.components >= 5 then
									table.insert(comps, {
										components = {
											newButton
										}
									})
								else
									table.insert(lastRow.components, newButton)
								end
							end
						end

						comps = save(comps)
						updateEditor()
					end, true)
				end

				local function promptDrodown(ia, existingPath)
					local existingSplit = string.split(existingPath, "/")
					local existingIdx1, existingIdx2 = tonumber(existingSplit[1]), tonumber(existingSplit[2])

					local existing = comps and comps[existingIdx1] and comps[existingIdx1].components and comps[existingIdx1].components[existingIdx2]

					if existingPath and not existing then
						return ia:fail("I could not find that dropdown menu.", nil, true)
					end

					local dropdownOptions = existing and table.deepcopy(existing.options) or {}

					local questions = {
						{
							question = "What text should show in the dropdown?",
							style = "short",
							required = true,
							max = 80,
							default = existing and existing.placeholder
						},
						{
							question = "Should this dropdown be disabled?",
							component = discordia.SelectMenu({
								id = "toggle",
								placeholder = "Select an option...",
								max_values = 1,
								required = false,
								options = {
									{
										label = "Yes",
										value = "yes",
										emoji = resolvedEmojis.success,
										default = existing and existing.disabled == true or false
									},
									{
										label = "No",
										value = "no",
										emoji = resolvedEmojis.fail,
										default = not (existing and existing.disabled == true)
									}
								}
							}):raw(),
							required = false
						}
					}

					prompt(ia, (existing and "Edit" or "New") .. " Dropdown Menu", questions, function(mia, responses)
						if mia then
							local placeholder = responses and responses["What text should show in the dropdown?"]
							local disabled = responses and responses["Should this dropdown be disabled?"] == "yes" and true

							local builder

							local function buildDescription()
								local description = emojis.right .. " **Placeholder:** " .. placeholder .. "\n" .. emojis.right .. " **Disabled:** " .. ((disabled and emojis.success) or emojis.fail) .. "\n" .. emojis.right .. " **Options**\n"

								if #dropdownOptions == 0 then
									description = description .. emojis.space .. emojis.right .. " None"
								else
									for i, opt in ipairs(dropdownOptions) do
										local emojiStr = "None"
										if opt.emoji then
											if opt.emoji.name and opt.emoji.id then
												emojiStr = "<:" .. opt.emoji.name .. ":" .. opt.emoji.id .. ">"
											end
										end

										local exportable = opt.value:usub(13)
										description = description .. emojis.space .. emojis.right .. " " .. i .. "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Label:** " .. opt.label .. "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Emoji:** " .. emojiStr .. "\n" .. emojis.space .. emojis.space .. emojis.right .. " **Embed/Message Exportable:** `" .. exportable .. "`\n"
									end
								end

								return description
							end

							local function buildComps()
								return discordia.Components():selectMenu({
									id = "dropdown_option_builder",
									placeholder = "Select an option...",
									min_values = 1,
									max_values = 1,
									options = {
										{
											label = "Add Option",
											value = "add",
											emoji = resolvedEmojis.add
										},
										{
											label = "Edit Option",
											value = "edit",
											emoji = resolvedEmojis.edit
										},
										{
											label = "Remove Option",
											value = "remove",
											emoji = resolvedEmojis.subtract
										}
									}
								}):button({
									id = "save",
									label = "Save",
									style = "success",
									emoji = resolvedEmojis.yeswhite
								}):button({
									id = "cancel",
									label = "Cancel",
									style = "danger",
									emoji = resolvedEmojis.nowhite
								})
							end

							local function updateBuilder(int)
								local payload = {
									embed = {
										title = emojis.json .. " Dropdown Menu Builder",
										description = buildDescription(),
										color = colors.yellow
									},
									components = buildComps():raw(),
									ephemeral = true
								}

								if type(builder) == "table" then
									if int then
										int:update(payload)
									else
										ia:editReply(payload, builder.id)
									end
								else
									builder = ia:reply(payload, true)
								end
							end

							updateBuilder()

							local function getOptionSelectOptions()
								local opts = {}

								for i, opt in ipairs(dropdownOptions) do
									table.insert(opts, {
										label = opt.label,
										value = tostring(i),
										description = string.truncate(opt.value:usub(13), 34)
									})
								end

								return opts
							end

							onComp(builder, nil, nil, ia.user.id, false, function(dmbia)
								local id = dmbia.data.custom_id
								local selection = dmbia.data.values and dmbia.data.values[1]

								local optionQuestions = {
									{
										question = "What text should show on the option?",
										required = false,
										style = "short",
										max = 80
									},
									{
										question = "What emoji should the option have?",
										placeholder = "Either a Ducky emoji name or an emoji ID...",
										style = "short",
										required = false,
										max = 30
									},
									{
										question = "What exportable should Ducky reply with?",
										placeholder = "Which exportable should Ducky reply with?",
										style = "short",
										required = true,
										max = 31
									}
								}

								if id == "dropdown_option_builder" then
									if selection == "add" then
										prompt(dmbia, "Add Dropdown Option", optionQuestions, function(mia, responses)
											if not mia then
												return
											end

											if not responses["What text should show on the option?"] and not responses["What emoji should the option have?"] then
												return mia:fail("You must provide a label and/or an emoji.", nil, true)
											end

											local resolvedEmoji
											if responses["What emoji should the option have?"] then
												local emojiInput = responses["What emoji should the option have?"]
												if emojis[emojiInput] then
													resolvedEmoji = resolvedEmojis[emojiInput]
												else
													local guildEmoji = ia.guild:getEmoji(emojiInput)
													if not guildEmoji then
														return mia:fail("You did not provide a valid emoji.", nil, true)
													end
													resolvedEmoji = resolveEmoji(guildEmoji.mentionString)
												end
											end

											local exportableInput = responses["What exportable should Ducky reply with?"]
											local exportable = exportableInput and import(exportableInput, nil, true)
											if exportableInput and (not exportable or (exportable.type ~= "embed" and exportable.type ~= "message") and (exportable.type ~= "embeds")) then
												mia:fail("You must provide a valid Embed or Message exportable.", nil, true)
												return updateBuilder()
											end

											for _, opt in ipairs(dropdownOptions) do
												if opt.value == (exportable and ("compbuilder_" .. exportable.id) or nil) then
													mia:fail("This exportable has already been used in another option.", nil, true)
													return updateBuilder()
												end
											end

											table.insert(dropdownOptions, {
												label = responses["What text should show on the option?"],
												value = exportable and ("compbuilder_" .. exportable.id) or nil,
												emoji = resolvedEmoji
											})

											mia:updateDeferred(true)
											updateBuilder()
										end, true)

									elseif selection == "edit" then
										if #dropdownOptions == 0 then
											return dmbia:fail("There are no options to edit.", nil, true)
										end

										optionsSelect(dmbia, "Select an option to edit...", function(idx, oia)
											local opt = dropdownOptions[tonumber(idx)]

											local optionQuestions = {
												{
													question = "What text should show on the option?",
													required = false,
													style = "short",
													max = 80,
													default = opt.label
												},
												{
													question = "What emoji should the option have?",
													placeholder = "Either a Ducky emoji name, or the id of a custom emoji on this server.",
													style = "short",
													required = false,
													max = 30,
													default = opt.emoji and ((emojis[opt.emoji.name] and opt.emoji.name) or opt.emoji.id)
												},
												{
													question = "What exportable should Ducky reply with?",
													placeholder = "What exportable should Ducky reply the option is selected.",
													style = "short",
													required = true,
													max = 31,
													default = opt.value and opt.value:match("^[^_]*_(.*)$")
												}
											}

											prompt(oia, "Edit Dropdown Option", optionQuestions, function(mia, responses)
												if not mia then
													return
												end

												if not responses["What text should show on the option?"] and not responses["What emoji should the option have?"] then
													mia:fail("You must provide a label and/or an emoji.", nil, true)
													return updateBuilder()
												end

												local resolvedEmoji
												if responses["What emoji should the option have?"] then
													local emojiInput = responses["What emoji should the option have?"]
													if emojis[emojiInput] then
														resolvedEmoji = resolvedEmojis[emojiInput]
													else
														local guildEmoji = ia.guild:getEmoji(emojiInput)
														if not guildEmoji then
															return mia:fail("You did not provide a valid emoji.", nil, true)
														end
														resolvedEmoji = resolveEmoji(guildEmoji.mentionString)
													end
												end

												local exportableInput = responses["What exportable should Ducky reply with?"]
												local exportable = exportableInput and import(exportableInput, nil, true)
												if exportableInput and (not exportable or (exportable.type ~= "embed" and exportable.type ~= "message") and (exportable.type ~= "embeds")) then
													mia:fail("You must provide a valid Embed or Message exportable.", nil, true)
													return updateBuilder()
												end

												for _, otherOpt in ipairs(dropdownOptions) do
													if otherOpt ~= opt then
														if otherOpt.value == (exportable and ("compbuilder_" .. exportable.id) or nil) then
															mia:fail("This exportable has already been used in another option.", nil, true)
															return updateBuilder()
														end
													end
												end

												for idx1, row in ipairs(comps) do
													for idx2, comp in ipairs(row.components or {}) do
														if exportable and comp.id == "compbuilder_" .. exportable.id and (not existing or idx1 ~= existingIdx1 or idx2 ~= existingIdx2) then
															return mia:fail("That exportable has already been used in a button.", nil, true)
														end
													end
												end

												opt.label = responses["What text should show on the option?"]
												opt.value = exportable and ("compbuilder_" .. exportable.id) or nil
												opt.emoji = resolvedEmoji

												mia:updateDeferred(true)
												updateBuilder()
											end, true)
										end, true, getOptionSelectOptions(), 1, nil, true)

									elseif selection == "remove" then
										if #dropdownOptions == 0 then
											dmbia:fail("There are no options to remove.", nil, true)
											return updateBuilder()
										end

										optionsSelect(dmbia, "Select an option to remove...", function(idx)
											table.remove(dropdownOptions, tonumber(idx))
											dmbia:updateDeferred(true)
											updateBuilder()
										end, true, getOptionSelectOptions(), 1, nil, true)
									end
								elseif id == "save" then
									dmbia:updateDeferred(true)

									if #dropdownOptions == 0 then
										return dmbia:fail("You must add at least one option.", nil, true)
									end

									local newDropdown = {
										type = 3,
										placeholder = placeholder,
										min_values = 0,
										max_values = 1,
										disabled = disabled,
										options = dropdownOptions,
										id = existing and existing.id or ("compbuilder_dropdown")
									}

									if existing then
										for idx1, row in ipairs(comps) do
											if idx1 == existingIdx1 then
												for idx2, comp in ipairs(row.components or {}) do
													if idx2 == existingIdx2 then
														comps[idx1].components[idx2] = newDropdown
													end
												end
											end
										end
									else
										local lastRow = comps[#comps]
										local countInLastRow = lastRow and #lastRow.components or 0
										local currentRows = #comps

										local wouldExceedRows = false
										if countInLastRow >= 5 then
											if (currentRows + 1) > 2 then
												wouldExceedRows = true
											end
										else
											if currentRows > 2 then
												wouldExceedRows = true
											end
										end

										if wouldExceedRows then
											ia:fail("You cannot add more than 2 rows of components.", nil, true)
											return updateEditor()
										end

										if #comps == 0 then
											table.insert(comps, {
												components = {
													newDropdown
												}
											})
										else
											local lastRow = comps[#comps]
											if #lastRow.components >= 5 then
												table.insert(comps, {
													components = {
														newDropdown
													}
												})
											else
												table.insert(lastRow.components, newDropdown)
											end
										end
									end

									comps = save(comps)
									updateEditor()
									if ia.deleteReply then
										ia:deleteReply(builder.id)
									end

								elseif id == "cancel" then
									if ia.deleteReply then
										ia:deleteReply(builder.id)
									end
									updateEditor()
								else
									dmbia:updateDeferred(true)
								end
							end)
						end
					end, true)
				end

				local buttonTypeOptions = {
					{
						label = "Primary",
						value = "blurple",
						emoji = resolvedEmojis.livery
					},
					{
						label = "Secondary",
						value = "secondary",
						emoji = resolvedEmojis.draft
					},
					{
						label = "Success",
						value = "success",
						emoji = resolvedEmojis.success
					},
					{
						label = "Danger",
						value = "danger",
						emoji = resolvedEmojis.fail
					},
					{
						label = "Link",
						value = "link",
						emoji = resolvedEmojis.link
					}
				}

				if selection == "addbutton" then
					optionsSelect(ceia, "Select a button type...", function(opt, cia, cr)
						ceia:deleteReply(cr.id)
						promptButton(cia, opt)
					end, false, buttonTypeOptions, 1, nil, true)
				elseif selection == "editbutton" then
					if not next(comps) then
						updateEditor()
						return ceia:fail("You have not added any components yet.", nil, true)
					end

					local opts = {}

					for idx1, row in ipairs(comps) do
						for idx2, comp in ipairs(row.components or {}) do
							if comp.type == 2 then
								table.insert(opts, {
									label = "#" .. tostring(idx1) .. "/" .. tostring(idx2) .. " Button",
									description = (comp.label and string.truncate(comp.label, 80)) or comp.style,
									emoji = resolvedEmojis.edit,
									value = tostring(idx1) .. "/" .. tostring(idx2)
								})
							end
						end
					end

					optionsSelect(ceia, "Edit a button...", function(buttonPath)
						optionsSelect(ceia, "Select a new button type...", function(opt, cia, cr)
							promptButton(cia, opt, buttonPath)
						end, true, buttonTypeOptions, 1, nil, true)
					end, true, opts, 1, nil, true)
				elseif selection == "removebutton" then
					if not next(comps) then
						updateEditor()
						return ceia:fail("You have not added any components yet.", nil, true)
					end

					local opts = {}

					for idx1, row in ipairs(comps) do
						for idx2, comp in ipairs(row.components or {}) do
							if comp.type == 2 then
								table.insert(opts, {
									label = "#" .. tostring(idx1) .. "/" .. tostring(idx2) .. " Button",
									description = (comp.label and string.truncate(comp.label, 80)) or comp.style,
									emoji = resolvedEmojis.edit,
									value = tostring(idx1) .. "/" .. tostring(idx2)
								})
							end
						end
					end

					optionsSelect(ceia, "Remove a button...", function(buttonPath, cia, cr)
						local existingSplit = string.split(buttonPath, "/")
						local existingIdx1, existingIdx2 = tonumber(existingSplit[1]), tonumber(existingSplit[2])

						local row = comps and comps[existingIdx1]
						local existing = row and row.components and row.components[existingIdx2]

						ceia:deleteReply(cr)

						if not existing then
							return cia:fail("I could not find that button.", nil, true)
						end

						table.remove(row.components, existingIdx2)

						if not next(row.components) then
							table.remove(comps, existingIdx1)
						end

						updateEditor()
						return cia:updateDeferred(true)
					end, false, opts, 1, nil, true)
				elseif selection == "adddropdown" then
					promptDrodown(ceia, nil)
				elseif selection == "editdropdown" then
					if not next(comps) then
						updateEditor()
						return ceia:fail("You have not added any components yet.", nil, true)
					end

					local opts = {}

					for idx1, row in ipairs(comps) do
						for idx2, comp in ipairs(row.components or {}) do
							if comp.type == 3 then
								table.insert(opts, {
									label = "#" .. tostring(idx1) .. "/" .. tostring(idx2) .. " Dropdown",
									description = (comp.placeholder and string.truncate(comp.placeholder, 80)),
									emoji = resolvedEmojis.edit,
									value = tostring(idx1) .. "/" .. tostring(idx2)
								})
							end
						end
					end

					optionsSelect(ceia, "Select a dropdown to edit...", function(dropdownPath, oia)
						promptDrodown(oia, dropdownPath)
					end, true, opts, 1, nil, true)
				elseif selection == "removedropdown" then
					if not next(comps) then
						updateEditor()
						return ceia:fail("You have not added any components yet.", nil, true)
					end

					local opts = {}

					for idx1, row in ipairs(comps) do
						for idx2, comp in ipairs(row.components or {}) do
							if comp.type == 3 then
								table.insert(opts, {
									label = "#" .. tostring(idx1) .. "/" .. tostring(idx2) .. " Dropdown",
									description = (comp.placeholder and string.truncate(comp.placeholder, 80)),
									emoji = resolvedEmojis.edit,
									value = tostring(idx1) .. "/" .. tostring(idx2)
								})
							end
						end
					end

					optionsSelect(ceia, "Select a dropdown to remove...", function(dropdownPath, cia, cr)
						local existingSplit = string.split(dropdownPath, "/")
						local existingIdx1, existingIdx2 = tonumber(existingSplit[1]), tonumber(existingSplit[2])

						local row = comps and comps[existingIdx1]
						local existing = row and row.components and row.components[existingIdx2]

						ceia:deleteReply(cr)

						if not existing then
							return cia:fail("I could not find that dropdown.", nil, true)
						end

						table.remove(row.components, existingIdx2)

						if not next(row.components) then
							table.remove(comps, existingIdx1)
						end

						updateEditor()
						return cia:updateDeferred(true)
					end, false, opts, 1, nil, true)
				else
					ceia:updateDeferred(true)
				end

			elseif id == "save" then
				updateEditor()
				if ia.deleteReply then
					ia:deleteReply(cer.id)
				else
					cer:delete()
				end

				local finalComps = discordia.Components()

				local row = 1
				local countInRow = 0

				local function nextRow()
					row = row + 1
					countInRow = 0
				end

				for _, r in ipairs(comps or {}) do
					for _, comp in ipairs(r.components or {}) do
						if comp.type == 3 then
							if countInRow > 0 then
								nextRow()
							end

							if row > 2 then
								return
							end

							comp.actionRow = row
							finalComps:selectMenu(comp)
							nextRow()
						else
							if countInRow >= 5 then
								nextRow()
							end

							if row > 2 then
								return
							end

							comp.actionRow = row
							finalComps:button(comp)
							countInRow = countInRow + 1
						end
					end
				end

				pcall(cb, finalComps:raw())
				return true
			elseif id == "delete" then
				if ia.deleteReply then
					ia:deleteReply(cer.id)
				else
					cer:delete()
				end

				pcall(cb, nil)
				return true
			else
				ceia:updateDeferred(true)
			end
		end)
	end

	_G.componentsEditor = componentsEditor

	local function messageEditor(ia, cb, variableEmbedDescription, defaultMessage, requireChannel, includeComps)
		coroutine.wrap(function()
			local variableEmbed = {
				title = emojis.json .. " Variables",
				description = variableEmbedDescription or emojis.fail .. " There are not any variables available for this embed.",
				color = colors.blank
			}

			local builtMessage = defaultMessage or {
				content = emojis.right .. " Welcome to the " .. emojis.chat .. " **Message Editor**. You can edit this message's content and embeds using the components below, and press **" .. emojis.yeswhite .. " Save** when you are done."
			}

			if builtMessage and builtMessage.embed and next(builtMessage.embed) then
				builtMessage.embeds = builtMessage.embeds or {}
				table.insert(builtMessage.embeds, builtMessage.embed)
				builtMessage.embed = nil
			end

			local eb

			local function updateEditor(onError)
				local s, e = nil, nil

				---/// COMPONENTS ///---
				local messageEditorComps = discordia.Components()

				local row = 1
				local countInRow = 0

				local function nextRow()
					row = row + 1
					countInRow = 0
				end

				for _, r in ipairs(builtMessage.components or {}) do
					for _, comp in ipairs(r.components or {}) do
						if comp.type == 3 then
							if countInRow > 0 then
								nextRow()
							end
							if row > 2 then
								p("ignoring extra selectMenu (would exceed 2 rows)")
								break
							end
							comp.actionRow = row

							fixCompId(comp, "id")

							messageEditorComps:selectMenu(comp)
							nextRow()
						else
							if countInRow >= 5 then
								nextRow()
							end
							if row > 2 then
								p("ignoring extra buttons (would exceed 2 rows)")
								break
							end
							comp.actionRow = row

							fixCompId(comp, "id")

							messageEditorComps:button(comp)
							countInRow = countInRow + 1
						end
					end
				end

				if countInRow > 0 then
					nextRow()
				end

				local editPropertySelect = discordia.SelectMenu({
					id = "editproperty",
					placeholder = "Edit this message...",
					actionRow = row,
					min_values = 0,
					max_values = 1,
					options = {
						{
							label = "Edit Content",
							value = "content",
							emoji = resolvedEmojis.text
						},
						{
							label = "Edit Embeds",
							value = "embeds",
							emoji = resolvedEmojis.art
						},
						(includeComps and {
							label = "Edit Components",
							value = "comps",
							emoji = resolvedEmojis.settings
						})
					}
				})

				if requireChannel then
					editPropertySelect:option("Edit Channel", "channel", nil, nil, resolvedEmojis.channel)
				end

				editPropertySelect:option("Import", "import", nil, nil, resolvedEmojis.import)
				editPropertySelect:option("Export", "export", nil, nil, resolvedEmojis.export)

				messageEditorComps:selectMenu(editPropertySelect)

				if (variableEmbedDescription) and (variableEmbedDescription ~= "") then
					messageEditorComps:button({
						id = "variables",
						label = "Variables",
						emoji = resolvedEmojis.json,
						actionRow = row + 1,
						style = "secondary"
					})
				end

				messageEditorComps:button({
					id = "save",
					label = "Save",
					emoji = resolvedEmojis.yeswhite,
					actionRow = row + 1,
					style = "success"
				})

				messageEditorComps:button({
					id = "delete",
					label = "Delete",
					emoji = resolvedEmojis.delete,
					actionRow = row + 1,
					style = "danger"
				})
				---/// COMPONENTS ///---

				if builtMessage and builtMessage.embed and next(builtMessage.embed) then
					builtMessage.embeds = builtMessage.embeds or {}
					table.insert(builtMessage.embeds, builtMessage.embed)
					builtMessage.embed = nil
				end

				---/// PAYLOAD ///---
				local payload = {
					content = builtMessage.content or "",
					embeds = (builtMessage.embeds or (builtMessage.embed and {
						builtMessage.embed
					})) and parseTable(builtMessage.embeds or (builtMessage.embed and {
						builtMessage.embed
					}), {
						["(%S+)%.avatar"] = "https://cdn.discordapp.com/emojis/1316411205799247913.png"
					}),
					components = messageEditorComps:raw()
				}

				---/// PAYLOAD ///---

				if class(eb) == "Message" then
					if ia.editReply then
						s, e = ia:editReply(payload, eb.id)
					elseif eb.update then
						s, e = eb:update(payload)
					end
				else
					eb, e = ia:reply(payload, true)
					s = not not eb
				end

				if (not s) and (onError) then
					Client:error("Message Editor received an error while attempting to update itself: " .. tostring(e))
					onError(e)
				elseif (not s) and (type(eb) == "table") then
					if ia.editReply then
						s, e = ia:editReply({
							embed = {
								title = emojis.warning .. " HTTP Error",
								description = emojis.right .. " An unhandled HTTP error occurred while attempting to load your message:\n> ```\n" .. tostring(e) .. "```",
								color = colors.warning
							},
							components = messageEditorComps:raw()
						}, eb.id)
					elseif eb.update then
						s, e = eb:update({
							embed = {
								title = emojis.warning .. " HTTP Error",
								description = emojis.right .. " An unhandled HTTP error occurred while attempting to load your message:\n> ```" .. tostring(e) .. "```",
								color = colors.warning
							},
							components = messageEditorComps:raw()
						})
					end
				end
			end

			updateEditor(function(error)
				ia:fail("Discord returned an error while trying to display your message, the default message will be used: ```" .. error .. "```", nil, true)
				builtMessage = {
					content = emojis.right .. " Welcome to the " .. emojis.chat .. " **Message Editor**. You can edit this message's content and embeds using the components below, and press **" .. emojis.yeswhite .. " Save** when you are done."
				}
				updateEditor()
			end)

			if class(eb) ~= "Message" then
				return
			end

			onComp(eb, nil, nil, ia.user.id, false, function(eia)
				local id = eia.data.custom_id
				local selection = eia.data.values and eia.data.values[1]

				if id == "editproperty" then
					if selection == "content" then
						prompt(eia, "Edit Content", {
							{
								question = "New Content",
								placeholder = "Enter the new content for this message...",
								default = builtMessage.content,
								required = false,
								style = "paragraph",
								max = 2000
							}
						}, function(mia, responses)
							local oldContent = (builtMessage.content and builtMessage.content ~= "" and tostring(builtMessage.content) .. "") or nil -- make it a seperate string object so it stays as that idk how else to do it so yes yes
							builtMessage.content = responses["New Content"]

							updateEditor(function(er)
								builtMessage.content = oldContent
								updateEditor()
							end)
						end, true)
					elseif selection == "embeds" then
						local oldEmbeds = (builtMessage.embeds and table.deepcopy(builtMessage.embeds)) or nil
						multiEmbedEditor(eia, function(es)
							builtMessage.embeds = es
							updateEditor(function()
								builtMessage.embeds = oldEmbeds
								updateEditor()
							end)
						end, variableEmbedDescription, oldEmbeds)
					elseif selection == "comps" then
						componentsEditor(eia, function(comps)
							builtMessage.components = comps
							updateEditor()
						end, builtMessage.components)
					elseif selection == "channel" then
						channelSelect(eia, "Select a channel for this message...", function(c)
							builtMessage.channel = c
							updateEditor()
						end, true, 0, 1)
					elseif selection == "import" then
						prompt(eia, "Import Message from Exportable Code", {
							{
								question = "Exportable Code",
								placeholder = "Enter the exportable code to import the message from...",
								required = false,
								style = "short",
								max = 2000
							}
						}, function(mia, responses)
							local imported, err = _G.import((responses and responses["Exportable Code"]) or "_", "message")

							if imported then
								builtMessage = imported

								if imported.embed and not imported.embeds then
									imported.embeds = {
										imported.embed
									}
									imported.embed = nil
								end

								mia:updateDeferred(true)
							else
								mia:fail(err, nil, true)
							end

							updateEditor()
						end, true)
					elseif selection == "export" then
						prompt(eia, "Exportable Name", {
							{
								question = "What should this exportable be named?",
								placeholder = "Enter a name for this exportable...",
								style = "short",
								max = 100
							}
						}, function(mia, responses)
							local exported, err = export(builtMessage, mia.user, "message", responses["What should this exportable be named?"])

							if exported then
								mia:success("Your message has been exported successfully! Here's your exportable code: ```\n" .. exported .. "```\n-# " .. emojis.right .. " You can share this code with other people for them to import your message.", nil, true)
							else
								mia:fail(err, nil, true)
							end
							updateEditor()
						end, true)
					else
						eia:updateDeferred(true)
					end
				elseif id == "variables" then
					eia:reply({
						embed = variableEmbed
					}, true)
				elseif id == "save" then
					if requireChannel and (not builtMessage.channel) then
						eia:fail("You did not provide a channel for this message.", nil, true)
						return
					end

					updateEditor()
					if ia.deleteReply then
						ia:deleteReply(eb.id)
					else
						eb:delete()
					end

					fixCompId(builtMessage.components or {}, "custom_id", true)

					pcall(cb, builtMessage)
					return true
				elseif id == "delete" then
					if ia.deleteReply then
						ia:deleteReply(eb.id)
					else
						eb:delete()
					end
					pcall(cb, nil)
					return true
				end
			end)
		end)()
	end

	_G.messageEditor = messageEditor

	local function confirm(ia, message, cb, delete, delay)
		coroutine.wrap(function()
			if (not ia) or (not message) or (not cb) then
				return
			end

			local comps = discordia.Components():button({
				id = "confirm",
				emoji = resolvedEmojis.yeswhite,
				style = "success",
				disabled = delay and true
			}):button({
				id = "cancel",
				emoji = resolvedEmojis.nowhite,
				style = "danger",
				disabled = delay and true
			})

			local r = ia:reply({
				embed = {
					description = emojis.warning .. " " .. message .. ((delay and "\n\n-# " .. emojis.clock .. " *You can continue <t:" .. math.floor(os.time() + (delay / 1000)) .. ":R>.*") or ""),
					color = colors.warning
				},
				components = comps:raw()
			}, true)

			if type(r) ~= "table" then
				return ia:fail("Something went wrong trying to ask for confirmation, **please try again**.", nil, true)
			end

			if delay then
				timer.sleep(delay)

				comps = discordia.Components():button({
					id = "confirm",
					emoji = resolvedEmojis.yeswhite,
					style = "success"
				}):button({
					id = "cancel",
					emoji = resolvedEmojis.nowhite,
					style = "danger"
				})

				local toupd = {
					embed = {
						description = emojis.warning .. " " .. message,
						color = colors.warning
					},
					components = comps:raw()
				}

				if ia.editReply then
					ia:editReply(toupd, r.id)
				elseif r.update then
					r:update(toupd)
				end
			end

			onComp(r, nil, nil, ia.user.id, true, function(ria)
				local id = ria.data.custom_id

				if id == "confirm" then
					if delete then
						if ia.deleteReply then
							ia:deleteReply(r.id)
						else
							r:delete()
						end
					end

					return cb(true, ria, r)
				elseif id == "cancel" then
					if delete then
						if ia.deleteReply then
							ia:deleteReply(r.id)
						else
							r:delete()
						end
					end

					return cb(false, ria, r)
				end
			end)
		end)()
	end

	_G.confirm = confirm

	local function jsonCompatible(t, blacklist)
		local tbl = table.deepcopy(t, nil, blacklist)

		for k, v in pairs(tbl) do
			if table.find(blacklist or {}, tostring(k)) then
				tbl[k] = nil
			end
		end

		table.deeppairs(tbl, function(t, k, v)
			if table.find(blacklist or {}, tostring(k)) then
				return nil
			elseif type(v) == "function" then
				return tostring(v)
			else
				return v
			end
		end)
		return tbl
	end

	_G.jsonCompatible = jsonCompatible

	local function paginate(interaction, pages, owner, customOptions)
		-- load options

		local options = {
			showTotalPages = true,
			teleport = true,
			clamp = false,
			useTitleAsIdentifier = false,
			startPage = 1,
			ephemeral = false,
			style = "secondary"
		}

		for key, value in pairs(customOptions) do
			options[key] = value
		end

		-- variables

		local currentPageNumber = options.startPage
		local currentPage

		-- build components

		local pagination = ((interaction.user.id == Client.user.id) and interaction) or nil

		local function updatePagination(num)
			currentPageNumber = num or currentPageNumber
			currentPage = pages[currentPageNumber]

			if currentPage.description and currentPage.description:len() > 4096 then
				currentPage.description = string.truncate(currentPage.description, 4000) .. "\n-# " .. emojis.warning .. " This page was truncated. Not all information may be shown."
			end

			local components = (currentPage.components and discordia.Components(currentPage.components)) or discordia.Components()
			local actionRow = table.count(components:raw()) + 1

			components:button({
				id = "previous",
				emoji = resolvedEmojis.left,
				style = options.style,
				disabled = (currentPageNumber <= 1 and options.clamp),
				actionRow = actionRow
			})

			components:button({
				id = "teleporter",
				emoji = currentPage.identifier and currentPage.identifier.emoji,
				label = string.truncate((currentPage.identifier and currentPage.identifier.text) or (options.useTitleAsIdentifier and currentPage.title) or (options.showTotalPages and (currentPageNumber .. "/" .. #pages) or "Error"), 80),
				style = options.style,
				disabled = not options.teleport,
				actionRow = actionRow
			})

			components:button({
				id = "next",
				emoji = resolvedEmojis.right,
				style = options.style,
				disabled = (currentPageNumber >= #pages and options.clamp),
				actionRow = actionRow
			})

			local tosend = {
				embed = jsonCompatible(currentPage, {
					"components",
					"otherCompCallback"
				}),
				components = components:raw()
			}

			if pagination then
				if options.ephemeral and interaction.editReply then
					local success, err = interaction:editReply(tosend, pagination.id)
					local code = err and err:match("(%d+)")

					if not success then
						interaction:editReply({
							embed = {
								title = emojis.warning .. " HTTP Error",
								description = (code and errCodes[tonumber(code)]) or ("An unexpected error occurred while attempting to display this page.\n>>> ```" .. err .. "```"),
								color = colors.warning
							}
						}, pagination.id)
					end
				else
					local success, err = pagination:update(tosend)

					if not success then
						pagination:update({
							embed = {
								title = emojis.warning .. " HTTP Error",
								description = (code and errCodes[tonumber(code)]) or ("An unexpected error occurred while attempting to display this page.\n>>> ```" .. err .. "```"),
								color = colors.warning
							}
						})
					end
				end
			else
				local success, err = interaction:reply(tosend, options.ephemeral)

				if not success then
					interaction:reply({
						embed = {
							title = emojis.warning .. " HTTP Error",
							description = (code and errCodes[tonumber(code)]) or ("An unexpected error occurred while attempting to display this page.\n>>> ```" .. err .. "```"),
							color = colors.warning
						}
					}, options.ephemeral)
				else
					pagination = success
				end
			end
		end

		updatePagination()

		local function fetchCurrentPage()
			return currentPage, currentPageNumber
		end

		onComp(pagination, nil, nil, owner and owner.id or nil, false, function(ia)
			local id = ia.data.custom_id

			if id == "previous" then
				if currentPageNumber - 1 < 1 then
					currentPageNumber = #pages
				else
					currentPageNumber = currentPageNumber - 1
				end

				ia:updateDeferred(true)
				updatePagination()
			elseif id == "next" then
				if currentPageNumber + 1 > #pages then
					currentPageNumber = 1
				else
					currentPageNumber = currentPageNumber + 1
				end

				ia:updateDeferred(true)
				updatePagination()
			elseif id == "teleporter" then
				local options = {}
				local min, max = 1, math.clamp(25, 1, #pages)

				if #pages > 25 then
					min = math.clamp(currentPageNumber - 12, 1, #pages)
					max = math.clamp(currentPageNumber + 12, 1, #pages)
				end

				for pageNumber = min, max do
					local page = pages[pageNumber]

					table.insert(options, {
						label = string.truncate((page.identifier and page.identifier.text) or ("Page " .. pageNumber), 100),
						emoji = page.identifier and page.identifier.emoji,
						description = page.identifier and page.identifier.description,
						value = tostring(pageNumber)
					})
				end

				local teleporter = ia:reply({
					components = discordia.Components():selectMenu({
						id = "pageselect",
						placeholder = "Select a page...",
						options = options
					}):raw()
				}, true)

				onComp(teleporter, nil, nil, ia.user.id, false, function(tia)
					local id = tia.data.custom_id
					local selections = tia.data.values
					local first = selections and selections[1]

					if id == "pageselect" then
						if first and tonumber(first) then
							currentPageNumber = tonumber(first)
							tia:updateDeferred(true)
							ia:deleteReply(teleporter.id)
							updatePagination()
							return true
						else
							return tia:fail("You did not select a valid page.", nil, true)
						end
					end
				end)
			elseif currentPage.otherCompCallback then
				pcall(currentPage.otherCompCallback, ia)
			end
		end)

		return pagination, updatePagination, fetchCurrentPage
	end

	_G.paginate = paginate

	local function parseTable(tbl, keysUnescaped, s1, s2, excludeFromReplaced, legacy)
		tbl = tbl or {}
		keysUnescaped = keysUnescaped or {}
		local keys = {}
		local patterns = {}

		for k, v in pairs(keysUnescaped) do
			if k == "(%S+)%.avatar" then
				patterns[k] = v
			else
				keys[k:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1")] = v
			end
		end
		excludeFromReplaced = excludeFromReplaced or {}
		s1, s2 = s1 or "{", s2 or "}"

		local s1_escaped = s1:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1")
		local s2_escaped = s2:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1")

		local function safeEval(expr)
			expr = expr:gsub("%s+", "")
			if expr:match("[^%d%+%-%*/%.%(%)%s]") then
				return nil
			end
			local function compute(e)
				while e:find("%b()") do
					e = e:gsub("%b()", function(sub)
						local inner = sub:usub(2, -2)
						return compute(inner) or sub
					end)
				end
				while e:find("[%.%d]+[%*/][%.%d]+") do
					e = e:gsub("([%.%d]+)%*([%.%d]+)", function(a, b)
						return tostring(tonumber(a) * tonumber(b))
					end)
					e = e:gsub("([%.%d]+)/([%.%d]+)", function(a, b)
						b = tonumber(b)
						if not b or b == 0 then
							return "0"
						end
						return tostring(tonumber(a) / b)
					end)
				end
				while e:find("[%.%d]+[%+%-][%.%d]+") do
					e = e:gsub("([%.%d]+)%+([%.%d]+)", function(a, b)
						return tostring(tonumber(a) + tonumber(b))
					end)
					e = e:gsub("([%.%d]+)%-([%.%d]+)", function(a, b)
						return tostring(tonumber(a) - tonumber(b))
					end)
				end
				return e
			end
			local r = compute(expr)
			return tonumber(r)
		end

		local ret = {}
		local variablesReplaced = 0
		for k, v in pairs(tbl) do
			if type(v) == "string" then
				local new = v
				if legacy then
					for key, val in pairs(keys) do
						local found
						new, found = new:gsub(s1_escaped .. key .. s2_escaped, tostring(val))
						if not table.find(excludeFromReplaced, key) then
							variablesReplaced = variablesReplaced + found
						end
					end
				else
					new = new:gsub(s1_escaped .. "([^%s" .. s2_escaped .. "]-)" .. s2_escaped, function(expr)
						if expr == "" then
							return s1 .. expr .. s2
						end

						for pattern, val in pairs(patterns) do
							if expr:match("^" .. pattern .. "$") then
								if not table.find(excludeFromReplaced, pattern) then
									variablesReplaced = variablesReplaced + 1
								end
								return tostring(val)
							end
						end

						if keysUnescaped[expr] then
							if not table.find(excludeFromReplaced, expr) then
								variablesReplaced = variablesReplaced + 1
							end
							return tostring(keysUnescaped[expr])
						end

						if expr:match("[%+%-%*/]") then
							local replaced = expr
							local hasValidKey = false
							for key, val in pairs(keys) do
								local unescapedKey = key:gsub("%%(.)", "%1")
								if replaced:match(key) and keysUnescaped[unescapedKey] and type(keysUnescaped[unescapedKey]) == "number" then
									replaced = replaced:gsub(key, tostring(val))
									hasValidKey = true
									if not table.find(excludeFromReplaced, unescapedKey) then
										variablesReplaced = variablesReplaced + 1
									end
								end
							end

							if hasValidKey then
								local result = safeEval(replaced)
								if result ~= nil then
									return tostring(result)
								end
							end
						end

						return s1 .. expr .. s2
					end)
				end
				ret[k] = new
			elseif type(v) == "table" then
				local new, count = parseTable(v, keysUnescaped, s1, s2, excludeFromReplaced, legacy)
				ret[k] = new
				variablesReplaced = variablesReplaced + count
			else
				ret[k] = v
			end
		end
		return ret, variablesReplaced
	end

	_G.parseTable = parseTable

	local insert = table.insert
	local ArrayIterable = discordia.ArrayIterable

	local function parseMentions(content, pattern)
		if not content:find("%b<>") then
			return {}
		end
		local mentions, seen = {}, {}
		for id in content:gmatch(pattern) do
			if not seen[id] then
				insert(mentions, id)
				seen[id] = true
			end
		end
		return mentions
	end

	local function getMentionedUsers(str)
		local users = Client._users
		local mentions = parseMentions(str, "<@!?(%d+)>")
		return ArrayIterable(mentions, function(id)
			return users:get(id)
		end)
	end

	local function getMentionedRoles(str)
		local mentions = parseMentions(str, "<@&(%d+)>")
		return ArrayIterable(mentions, function(id)
			local guild = Client._role_map[id]
			return guild and guild._roles:get(id) or nil
		end)
	end

	local usersMeta = {
		__index = function(_, k)
			return "@" .. k
		end
	}
	local rolesMeta = {
		__index = function(_, k)
			return "@" .. k
		end
	}
	local channelsMeta = {
		__index = function(_, k)
			return "#" .. k
		end
	}
	local everyone = "@\226\128\139everyone"
	local here = "@\226\128\139here"

	local function sanitize(str, guild, replace)
		local content = str
		local cleaned = ""
		local users = setmetatable({}, usersMeta)
		for user in getMentionedUsers(str):iter() do
			local member = guild and guild._members:get(user._id)
			users[user._id] = "@" .. (member and member._nick or user._username)
		end
		local roles = setmetatable({}, rolesMeta)
		for role in getMentionedRoles(str):iter() do
			roles[role._id] = "@" .. role._name
		end

		-- Swears
		local function sanitizeInput(word)
			return word:gsub("[%p%c%s]", ""):lower()
		end

		local violate = false
		local splitted = string.split(content, " ")
		for i, v in pairs(splitted) do
			local sanitized = sanitizeInput(v)
			for _, swear in pairs(badwords) do
				if sanitized == swear or sanitized:lower():find(swear:lower(), 1, true) then
					violate = true
					splitted[i] = replace or ""
				end
			end
		end
		content = table.concat(splitted, " ")

		-- Links
		local beforeLinks = content
		content = content:gsub("https?://[%w-_%.%?%.:/%%#@&=+]+", replace or "")
		if beforeLinks ~= content then
			violate = true
		end

		-- Discord invites
		local beforeInvites = content
		content = content:gsub("discord%.gg/%w+", replace or "")
		content = content:gsub("discord%.com/invite/%w+", replace or "")
		if beforeInvites ~= content then
			violate = true
		end

		-- Pings
		cleaned = content:gsub("<@!?(%d+)>", users):gsub("<@&(%d+)>", roles):gsub("@everyone", everyone):gsub("@here", here):gsub("{timestamp}", tostring(os.time()))

		return cleaned, violate
	end

	_G.sanitize = sanitize

	local function loadMembers(guild)
		local total = guild.totalMemberCount or 0

		if table.count(guild.members) == total then
			return true
		end

		guild:requestMembers()

		local maxTime = 5
		local startTime = os.time()

		while table.count(guild.members) < total and os.time() - startTime <= maxTime do
			timer.sleep(100)
		end

		return true
	end

	_G.loadMembers = loadMembers

	local function fetchMemberFromInteraction(interaction, args, slash, userArgName)
		userArgName = userArgName or "user"
		local user
		local member

		if not interaction then
			return
		end

		if not args or ((slash and not args[userArgName]) and not args[1]) then
			return
		end

		if slash and args[userArgName] then
			user = args[userArgName]
			member = user and interaction.guild:getMember(user.id)
		elseif tonumber(args[1]) then
			user = Client:getUser(args[1])
			member = interaction.guild:getMember(args[1])
		else
			user = interaction.mentionedUsers and interaction.mentionedUsers.first
			member = user and interaction.guild:getMember(user.id)

			if (not user) and args[1] and args[1] ~= "" then
				loadMembers(interaction.guild)

				for _, v in pairs(interaction.guild.members) do
					if v.name:lower():find(args[1]:lower()) or v.user.username:lower():find(args[1]:lower()) or v.id == tostring(args[1]) then
						user = v.user
						member = v
					end
				end
			end
		end

		return member, user
	end

	_G.fetchMemberFromInteraction = fetchMemberFromInteraction

	local function fetchChannelFromInteraction(interaction, channelArg)
		local channel

		if not interaction or not channelArg then
			return
		end

		if tonumber(channelArg) then
			channel = interaction.guild:getChannel(channelArg)
		else
			channel = interaction.mentionedChannels and interaction.mentionedChannels.first

			if not channel and channelArg ~= "" then
				for _, v in pairs(interaction.guild.textChannels) do
					if v.name:lower():find(channelArg:lower()) then
						channel = v
					end
				end
			end
		end

		return channel
	end

	_G.fetchChannelFromInteraction = fetchChannelFromInteraction

	local function getTotalUserCount()
		local tmc = 0

		for _, gu in pairs(Client.guilds) do
			tmc = tmc + (gu.totalMemberCount or 0)
		end

		return tmc
	end

	_G.getTotalUserCount = getTotalUserCount

	local function stringToUser(input, guild)
		if not input or input == "" then
			return
		end

		local user, member

		local id = input:match("^<@!?(%d+)>$") or input:match("^(%d+)$")
		if id then
			user = Client:getUser(id)
			member = guild and guild:getMember(id)
			if member or user then
				return user, member
			end
		end

		if guild then
			loadMembers(guild)

			local lowered = input:lower()
			for _, m in pairs(guild.members) do
				local uname = m.user and m.user.username or ""
				local dname = m.name or ""
				if uname:lower():find(lowered, 1, true) or dname:lower():find(lowered, 1, true) or tostring(m.id) == input then
					user = m.user
					member = m
					break
				end
			end

			return user, member
		end
	end

	_G.stringToUser = stringToUser

	local function generateGuildInvite(guild, unique)
		if guild.vanityCode and guild.vanityCode ~= "" then
			return "https://discord.com/invite/" .. guild.vanityCode, guild.vanityCode
		end

		local textChannel = guild.textChannels and guild.textChannels:toArray()[1]

		if textChannel then
			local invite = textChannel:createInvite({
				unique = unique
			})

			if invite and invite.code and invite.code ~= "" then
				return "https://discord.com/invite/" .. invite.code, invite.code
			else
				return
			end
		end
	end

	_G.generateGuildInvite = generateGuildInvite

	local function canManageRole(role, member)
		role = (type(role) == "table" and role) or (type(role) == "string" and Client:getRole(role))
		if not role then
			return false, "Invalid role."
		end

		local guild = role.guild
		if not guild or not guild.me then
			return false, "Invalid guild or bot not in guild."
		end

		if role.id == guild.id then
			return false, "Cannot manage the @​everyone role."
		end

		if role.managed then
			return false, "This role is managed by an integration."
		end

		if not guild.me:hasPermission("manageRoles") then
			return false, "Ducky does not have the Manage Roles permission."
		end

		local highest = guild.me.highestRole
		if not highest then
			return false, "Cannot determine Ducky's highest role."
		elseif highest.position <= role.position then
			return false, "Ducky's highest role must be higher than the target role."
		end

		if member and member.id ~= guild.ownerId then
			local memberHighestPosition = member.highestRole and member.highestRole.position or 0
			if memberHighestPosition <= role.position then
				return false, "Your highest role must be higher than the target role."
			end
		end

		return true
	end

	_G.canManageRole = canManageRole

	local function canModerate(moderator, member, config)
		local guild = moderator.guild
		local config = config or sqldb:get(guild.id) or {}

		if config.discordstaffimmunity and hasPermission(member, "MOD") == true then
			return false, "You cannot moderate other staff members."
		end

		if member.highestRole and moderator.highestRole and moderator.highestRole.position <= member.highestRole.position then
			return false, "You cannot moderate members with a higher role than you."
		end

		return true
	end

	_G.canModerate = canModerate

	local function roleSelect(ia, name, cb, defer, min, max, defaults, ignorePerms)
		min = min or 0
		max = max or 1

		local default_values = nil
		if defaults and type(defaults) == "table" then
			default_values = {}
			for _, default_id in ipairs(defaults) do
				table.insert(default_values, {
					id = default_id,
					type = "role"
				})
			end
		elseif defaults then
			default_values = {
				{
					id = defaults,
					type = "role"
				}
			}
		end

		local comps = discordia.SelectMenu({
			id = _G.junkStr(5),
			placeholder = name,
			type = "role",
			actionRow = 1,
			min_values = min,
			max_values = max,
			default_values = default_values
		})

		local r = ia:reply({
			components = discordia.Components({
				comps
			}):raw()
		}, true)

		if r then
			onComp(r, nil, nil, ia.user.id, defer, function(ria)
				local selection = ((max == 1) and ria.data and ria.data.values and ria.data.values[1]) or (ria.data and ria.data.values)

				if not ignorePerms then
					local embed = {
						title = emojis.filter .. " Roles Excluded",
						description = "The following roles were excluded from your selection:\n",
						color = colors.warning
					}

					if type(selection) == "table" then
						local failed = 0

						for i, roleId in pairs(selection) do
							local success, result = canManageRole(roleId, ia.member)

							if not success then
								failed = failed + 1
								table.remove(selection, i)

								embed.description = embed.description .. emojis.right .. " **<@&" .. roleId .. ">:** " .. result .. "\n"
							end
						end

						if failed > 0 then
							ria:reply({
								embed = embed
							}, true)
						end
					else
						local success, result = canManageRole(selection, ia.member)

						if not success then
							embed.description = embed.description .. emojis.right .. " **<@&" .. selection .. ">:** " .. result .. "\n"

							selection = nil

							ria:reply({
								embed = embed
							}, true)
						end
					end
				end

				if (type(selection) == "table") and (not selection[1]) then
					selection = nil
				end

				cb(selection)
				if defer then
					ria:updateDeferred(true)
					ia:deleteReply(r.id)
				end
			end)
		end
	end

	_G.roleSelect = roleSelect

	local function channelSelect(ia, name, cb, defer, min, max, defaults, types)
		min = min or 0
		max = max or 1

		local default_values = nil
		if defaults and type(defaults) == "table" then
			default_values = {}
			for _, default_id in ipairs(defaults) do
				table.insert(default_values, {
					id = default_id,
					type = "channel"
				})
			end
		elseif defaults then
			default_values = {
				{
					id = defaults,
					type = "channel"
				}
			}
		end

		local comps = discordia.SelectMenu({
			id = _G.junkStr(5),
			placeholder = name,
			type = "channel",
			actionRow = 1,
			min_values = min,
			max_values = max,
			default_values = default_values,
			channel_types = types
		})
		local c = discordia.Components({
			comps
		}):raw()

		local r = ia:reply({
			components = c
		}, true)

		if r then
			onComp(r, nil, nil, ia.user.id, defer, function(cia)
				local selection = ((max == 1) and cia.data and cia.data.values and cia.data.values[1]) or (cia.data and cia.data.values)

				if (type(selection) == "table") and (not selection[1]) then
					selection = nil
				end

				cb(selection, r)
				if defer then
					cia:updateDeferred(true)
					ia:deleteReply(r.id)
				end
			end)
		end
	end

	_G.channelSelect = channelSelect

	local function mentionableSelect(ia, name, cb, defer, min, max, defaults)
		min = min or 0
		max = max or 1

		local default_values = nil
		if defaults and type(defaults) == "table" then
			default_values = {}
			for _, default_id in ipairs(defaults) do
				local type = nil
				if ia.guild:getRole(default_id) then
					type = "role"
				else
					type = "user"
				end
				table.insert(default_values, {
					id = default_id,
					type = type
				})
			end
		elseif defaults then
			local type = nil
			if ia.guild:getRole(defaults) then
				type = "role"
			else
				type = "user"
			end
			default_values = {
				{
					id = defaults,
					type = type
				}
			}
		end

		local comps = discordia.SelectMenu({
			id = _G.junkStr(5),
			placeholder = name,
			type = "mentionable",
			actionRow = 1,
			min_values = min,
			max_values = max,
			default_values = default_values
		})

		local r = ia:reply({
			components = discordia.Components({
				comps
			}):raw()
		}, true)

		if r then
			onComp(r, nil, nil, ia.user.id, defer, function(mia)
				local selection = mia.data and mia.data.values

				if (type(selection) == "table") and (not selection[1]) then
					selection = nil
				end

				cb(selection)
				if defer then
					mia:updateDeferred(true)
					ia:deleteReply(r.id)
				end
			end)
		end
	end

	_G.mentionableSelect = mentionableSelect

	local function optionsSelect(ia, name, cb, defer, options, max, defaults, single)
		local optionsTable = table.deepcopy(options)

		for _, option in pairs(optionsTable) do
			if type(option) == "table" then
				if type(option.label) == "string" then
					option.label = sanitizeUTF8(string.truncate(option.label, 45))
				end

				if type(option.description) == "string" then
					option.description = sanitizeUTF8(string.truncate(option.description, 100))
				end
			end
		end

		if defaults then
			for _, option in pairs(optionsTable) do
				if option and type(option) == "table" and table.find(defaults, option.value) then
					option.default = true
				end
			end
		end

		local min_values = single and nil or 0
		local max_values = single and nil or (max or table.count(optionsTable))

		local selectMenu = discordia.SelectMenu({
			id = _G.junkStr(5),
			placeholder = name,
			min_values = min_values,
			max_values = max_values,
			options = optionsTable,
			actionRow = 1
		})

		local r, err = ia:reply({
			components = discordia.Components():selectMenu(selectMenu):raw()
		}, true)

		if not r then
			return Client:error("optionsSelect failed, name: " .. name .. ", error: " .. err)
		end

		onComp(r, nil, nil, ia.user.id, defer, function(cia)
			local selections = cia.data and cia.data.values

			if type(selections) == "table" and not selections[1] then
				selections = nil
			end

			if single and type(selections) == "table" then
				selections = selections[1]
			end

			cb(selections, cia, r)

			if defer then
				cia:updateDeferred(true)
				ia:deleteReply(r.id)
			end
		end)
	end

	_G.optionsSelect = optionsSelect

	local recentNotifications = {}

	local function NotifyRemoveFromConfig(guildID, setupPosition, title, reason)
		local guild = Client:getGuild(guildID)

		if not guild then
			return
		end

		local ownerId = guild.ownerId
		local owner = ownerId and guild:getMember(ownerId)

		if not owner then
			return
		end

		local identifierKey = guildID .. ":" .. ownerId .. ":" .. title

		if not table.find(recentNotifications, identifierKey) then
			owner:send({
				content = "## " .. emojis.warning .. " " .. title .. " Removed\n" .. emojis.right .. " The **" .. title .. "** in your server, **" .. guild.name .. "**, has been removed because " .. reason .. "\n\n" .. emojis.right .. " To reconfigure this, navigate to the **" .. setupPosition .. "** page via **`/setup`** and reconfigure the **" .. title .. "**.\n" .. emojis.right .. " If you need further assistance, contact us via our support server, " .. emojis.ducky .. " [**Ducky's Pond**](https://duckybot.xyz/support).",

				components = discordia.Components():button({
					url = "https://discord.gg/w2dNr7vuKP",
					style = "link",
					label = "Ducky's Pond",
					emoji = resolvedEmojis.ducky
				}):raw()
			})

			table.insert(recentNotifications, identifierKey)
		end

		if table.count(recentNotifications) > 10 then
			table.remove(recentNotifications, 1)
		end
	end

	_G.NotifyRemoveFromConfig = NotifyRemoveFromConfig

	local function parseMentionables(guild, ids, here, everyone)
		local mentionables = {}

		for _, id in pairs(ids) do
			local obj = guild:getRole(id) or guild:getMember(id) or guild:getChannel(id)
			if obj then
				table.insert(mentionables, obj.mentionString)
			end
		end

		if here then
			table.insert(mentionables, "@here")
		end
		if everyone then
			table.insert(mentionables, "@everyone")
		end

		return mentionables
	end

	_G.parseMentionables = parseMentionables

	local function parsePings(mentionables)
		if (mentionables) and type(mentionables) == "table" and table.count(mentionables) > 0 then
			return "-# " .. emojis.pings .. " " .. table.concat(mentionables, " ")
		end
	end

	_G.parsePings = parsePings

	local function DiscordUserObject(user)
		local isMember = user.guild ~= nil

		return {
			name = user.name,
			username = user.username,
			id = user.id,
			avatar = user.avatarURL,
			vc = (isMember and user.voiceChannel and {
				name = user.voiceChannel.name,
				id = user.voiceChannel.id
			}) or nil
		}
	end

	_G.DiscordUserObject = DiscordUserObject

	local function DiscordUserVariables(user, identifier, keys, restricted)
		keys = keys or {}

		if not user then
			return keys
		end

		keys[identifier .. ".name"] = user.name
		keys[identifier .. ".username"] = user.username
		keys[identifier .. ".id"] = user.id
		if not restricted then
			keys[identifier .. ".mention"] = user.mentionString
			keys[identifier .. ".avatar"] = user.avatarURL
		end

		return keys
	end

	_G.DiscordUserVariables = DiscordUserVariables

	local function RobloxUserVariables(user, identifier, keys, restricted)
		keys = keys or {}
		user = user or {}

		keys[identifier .. ".display"] = user.displayName or emojis.fail
		keys[identifier .. ".name"] = user.name or emojis.fail
		keys[identifier .. ".id"] = (user.id and tostring(user.id)) or emojis.fail
		if not restricted then
			keys[identifier .. ".avatar"] = user.avatar or emojis.fail
			keys[identifier .. ".description"] = user.description or emojis.fail
			keys[identifier .. ".banned"] = (user.banned and emojis.success) or emojis.fail
			keys[identifier .. ".verified"] = (user.verified and emojis.success) or emojis.fail
			keys[identifier .. ".profile"] = user.profile or emojis.fail
			keys[identifier .. ".hyperlink"] = user.hyperlink or emojis.fail
		end

		return keys
	end

	_G.RobloxUserVariables = RobloxUserVariables

	local function disableComponents(comps)
		for row, data in pairs(comps) do
			for _, component in pairs(data.components) do
				component.disabled = true
			end
		end

		return comps
	end

	_G.disableComponents = disableComponents

	local function formatNumber(n)
		if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then
			return tostring(n)
		end

		local s = tostring(n)

		local minus, int, frac = s:match("^(-?)(%d+)(%.?.*)")

		if not int then
			return tostring(n)
		end

		int = int:reverse():gsub("(%d%d%d)", "%1,")
		int = int:reverse()

		int = int:gsub("^,", "")

		return minus .. int .. frac
	end

	_G.formatNumber = formatNumber

	local function checkLimit(interaction, item, isPlus, amount, feature, exceeding)
		amount = (type(amount) == "number" and amount) or (type(amount) == "table" and table.count(amount)) or 0

		local function fail(str)
			if interaction then
				interaction:fail(str, nil, true)
			end
		end

		if type(feature) ~= "string" or type(featureLimits[feature]) ~= "table" then
			fail("Invalid feature provided to checkLimit.")
			return true
		end

		local normalLimit = featureLimits[feature].normal
		local duckyPlusLimit = featureLimits[feature].plus

		if duckyPlusLimit then
			if normalLimit then
				if isPlus then
					if (not exceeding and amount >= duckyPlusLimit) or (amount > duckyPlusLimit) then
						fail("You have already created " .. amount .. "/" .. normalLimit .. " " .. item .. ".")
						return true
					end
				elseif (not exceeding and amount >= normalLimit) or (amount > normalLimit) then
					fail("You have already created " .. amount .. "/" .. normalLimit .. " " .. item .. ".\n-# " .. emojis.right .. " You can create up to " .. duckyPlusLimit .. " " .. item .. " with " .. emojis.duckyplus .. " **Ducky Plus+**.")
					return true
				end
			else
				if isPlus then
					if (not exceeding and amount >= duckyPlusLimit) or (amount > duckyPlusLimit) then
						fail("You have already created " .. amount .. "/" .. normalLimit .. " " .. item .. ".")
						return true
					end
				else
					fail(item .. " is a " .. emojis.duckyplus .. " **Ducky Plus+** only feature.")
					return true
				end
			end
		else
			if (not exceeding and amount >= normalLimit) or (amount > normalLimit) then
				fail("You have already created " .. amount .. "/" .. normalLimit .. " " .. item .. ".")
				return true
			end
		end

		return false
	end

	_G.checkLimit = checkLimit

	local function fetchBulkMessages(channel, count, batchCallback, oldestFirst)
		local function sort(secondaryCache)
			local array = (secondaryCache and secondaryCache:toArray()) or {}
			array = table.values(array)
			table.sort(array, function(a, b)
				return (oldestFirst and a.createdAt < b.createdAt) or ((not oldestFirst) and a.createdAt > b.createdAt)
			end)

			return array
		end

		local messages = {}
		local bulks = math.clamp(math.floor(count / 100), 0, math.huge)
		count = count - (bulks * 100)
		local reference

		local function found(id)
			for _, m in pairs(messages) do
				if m.id == id then
					return true
				end
			end
		end

		for i = 1, bulks do
			local bulk

			if reference then
				bulk = channel:getMessagesBefore(reference.id, 100)
			else
				bulk = channel:getMessages(100)
			end

			bulk = sort(bulk)
			reference = (oldestFirst and bulk[1]) or bulk[#bulk]

			for i = #bulk, 1, -1 do
				local m = bulk[i]
				if not found(m.id) then
					table.insert(messages, m)
				else
					table.remove(bulk, i)
				end
			end

			if batchCallback then
				coroutine.wrap(batchCallback)(bulk)
			end
		end

		if count > 0 then
			local bulk

			if reference then
				bulk = channel:getMessagesBefore(reference.id, count)
			else
				bulk = channel:getMessages(count)
			end

			bulk = sort(bulk)

			for i = #bulk, 1, -1 do
				local m = bulk[i]
				if not found(m.id) then
					table.insert(messages, m)
				else
					table.remove(bulk, i)
				end
			end

			if batchCallback then
				coroutine.wrap(batchCallback)(bulk)
			end
		end

		table.sort(messages, function(a, b)
			return (oldestFirst and a.createdAt < b.createdAt) or ((not oldestFirst) and a.createdAt > b.createdAt)
		end)

		return messages
	end

	_G.fetchBulkMessages = fetchBulkMessages

	local function contentString(message, includeAuthor, includeTimestamp)
		if not message then
			return ""
		end

		local str = (message.embeds and message.embeds[1] and "[EMBED: " .. tostring(message.embeds[1].description or message.embeds[1].title or (message.embeds[1].image and message.embeds[1].image.url) or (message.embeds[1].thumbnail and message.embeds[1].thumbnail.url) or message.embeds[1].url) .. "]") or (message.sticker and "[STICKER: " .. tostring(message.sticker.name) .. "]") or message.content

		if includeAuthor then
			str = "@" .. message.user.username .. ": " .. str
		end
		if includeTimestamp then
			str = "[" .. os.date("!%x %X", math.floor(message.createdAt)) .. "] " .. str
		end

		return str
	end

	_G.contentString = contentString

	local function transcriptChannel(channel)
		channel._delete_protection = true
		local messages = fetchBulkMessages(channel, 500, nil, true)
		local transcript = ""

		local webTranscript = {
			guild = {
				name = channel.guild.name,
				icon = channel.guild.iconURL
			},
			channel = {
				name = channel.name,
				id = channel.id
			},
			messages = {},
			generatedTimestamp = os.time()
		}

		for i, v in pairs(messages) do
			local content = contentString(v, true, true)

			transcript = transcript .. ((i ~= 1 and "\n\n") or "") .. content

			table.insert(webTranscript.messages, {
				author = v.author.username,
				pfp = v.author.avatarURL or v.author.defaultAvatarURL,
				content = v.content,
				embeds = v.embeds or (v.embed and {
					v.embed
				}),
				sticker = v.sticker and {
					name = v.sticker.name,
					url = v.sticker.url
				},
				attachments = v.attachments,
				timestamp = math.floor(v.createdAt)
			})
		end

		local config = sqldb:get(channel.guild.id) or {}
		config.transcripts = config.transcripts or {}
		config.transcripts[channel.id] = webTranscript
		sqldb:set(channel.guild.id, {
			transcripts = config.transcripts
		}, "TICKET_TRANSCRIPT_SAVE")

		local url = "https://duckybot.xyz/transcripts/" .. channel.guild.id .. "/" .. channel.id
		channel._delete_protection = false
		return transcript, url
	end

	_G.transcriptChannel = transcriptChannel

	local function indicateNumber(num)
		num = tonumber(num)

		if not num then
			return ""
		end

		if num > 0 then
			return "+" .. tostring(num)
		else
			return tostring(num)
		end
	end

	_G.indicateNumber = indicateNumber

	local function convertEnumerationName(name)
		return name:gsub("(%l)(%u)", function(lower, upper)
			return lower .. " " .. upper
		end):gsub("^%l", string.upper)
	end

	_G.convertEnumerationName = convertEnumerationName

	local function diagnose(guild)
		local ducky = guild and guild.me
		local necessary = {
			"readMessages",
			"sendMessages",
			"kickMembers",
			"banMembers",
			"manageChannels",
			"addReactions",
			"viewAuditLog",
			"manageMessages",
			"embedLinks",
			"attachFiles",
			"useExternalEmojis",
			"manageNicknames",
			"manageRoles",
			"moderateMembers"
		}
		local permissions = {}

		for _, permission in pairs(necessary) do
			table.insert(permissions, {
				truename = permission,
				name = convertEnumerationName(permission),
				enabled = not not ducky:hasPermission(permission)
			})
		end

		table.sort(permissions, function(a, b)
			local aval = (a.enabled and 1) or 0
			local bval = (b.enabled and 1) or 0

			return aval > bval
		end)

		return permissions
	end

	_G.diagnose = diagnose

	local function fetchMentionable(id, guild)
		if (not id) or (not guild) then
			return
		end

		if type(id) == "string" then
			return (guild:getMember(id) and ("<@" .. id .. ">")) or (guild:getRole(id) and ("<@&" .. id .. ">")) or (id)
		elseif type(id) == "table" and id.name and id.mentionString then
			if id.name == "@everyone" then
				return "@everyone"
			elseif id.name == "@here" then
				return "@here"
			else
				return id.mentionString
			end
		end
	end

	_G.fetchMentionable = fetchMentionable

	local function pondMember(user)
		if type(user) == "table" then
			user = user.id
		elseif not user then
			return
		end

		return duckysPond:getMember(user)
	end

	_G.pondMember = pondMember

	local function moduleEnabled(module, config)
		local modules = config.modules or {}

		return not not table.find(modules, module:lower())
	end

	_G.moduleEnabled = moduleEnabled

	local function runtime()
		return ({
			["1257389588910182411"] = "Stable",
			["1388258365976612894"] = "Stable",
			["1284586408945647727"] = "Dev",
			["1305166672172417157"] = "Experimental"
		})[Client.user.id]
	end

	_G.runtime = runtime

	local function updateActivity(state, status)
		Client:setActivity({
			name = "statistics",
			state = state or "🐤 Powering " .. formatNumber(#Client.guilds) .. " servers・duckybot.xyz",
			type = 4
		})

		if status then
			Client:setStatus(discordia.enums.status[status])
		end
	end

	_G.updateActivity = updateActivity

	local function inDiscord(player, guild)
		local link = sqldb:getLink(player.id)
		local member = link and guild:getMember(link.discord)

		return member or table.find(guild.members, function(m)
			return m.name:lower():find(player.name:lower())
		end)
	end

	_G.inDiscord = inDiscord

	local function author(object, includeID)
		if class(object) == "User" or class(object) == "Member" then
			return {
				name = "@" .. object.username .. ((includeID and (" (" .. object.id .. ")")) or ""),
				icon_url = object.avatarURL or object.defaultAvatarURL
			}
		elseif class(object) == "Guild" then
			return {
				name = object.name .. ((includeID and (" (" .. object.id .. ")")) or ""),
				icon_url = object.iconURL or "https://duckybot.xyz/images/misc/defaultpfp.webp"
			}
		end
	end

	_G.author = author

	local function thumbnail(object)
		if class(object) == "User" or class(object) == "Member" then
			return (object.avatarURL and {
				url = object.avatarURL
			}) or (object.defaultAvatarURL and {
				url = object.defaultAvatarURL
			})
		elseif class(object) == "Guild" then
			return (object.iconURL and {
				url = object.iconURL
			}) or "https://duckybot.xyz/images/misc/defaultpfp.webp"
		end
	end

	_G.thumbnail = thumbnail

	local function parseMessageLink(link)
		local split = string.split(link, "/")
		local guild = Client:getGuild(split[5])
		local channel = guild and guild:getChannel(split[6])
		local message = channel and channel:getMessage(split[7])

		return message
	end

	_G.parseMessageLink = parseMessageLink

	local function shell(cmd, input)
		local process, err = spawn("/bin/bash", {
			args = {
				"-c",
				cmd .. " 2>&1"
			}
		})

		if process then
			if input then
				process.stdin.write(input)
				process.stdin.handle:close()
			end

			local output = {}

			for chunk in process.stdout.read do
				table.insert(output, chunk)
			end

			process.waitExit()

			output = table.concat(output)

			if output and output ~= "" and output ~= " " then
				return true, output
			else
				return true, "Output is empty."
			end
		else
			return false, tostring(err)
		end
	end

	_G.shell = shell

	local function accentClean(str)
		local replacements = {
			["á"] = "a",
			["é"] = "e",
			["í"] = "i",
			["ó"] = "o",
			["ú"] = "u",
			["Á"] = "A",
			["É"] = "E",
			["Í"] = "I",
			["Ó"] = "O",
			["Ú"] = "U",
			["ñ"] = "n",
			["Ñ"] = "N",
			["ü"] = "u",
			["Ü"] = "U",
			["ç"] = "c",
			["Ç"] = "C"
		}

		local cleaned = str:gsub(".", function(c)
			return replacements[c] or c
		end)

		return cleaned
	end

	_G.accentClean = accentClean

	local function durationReadable(s)
		s = math.floor(s)
		local minutes = math.floor(s / 60)
		local seconds = s % 60
		return string.format("%d:%02d", minutes, seconds)
	end

	_G.durationReadable = durationReadable

	local function transcribeAudio(PCM)
		p("transcribeAudio")
		local path = "../vosk/temp/" .. realtime() .. ".wav"
		p("creating", path)
		local success, output = shell("ffmpeg -f s16le -ar 44100 -ac 2 -i pipe:0 " .. path, PCM)
		if (success and fs.existsSync(path)) then
			p("exists, transcripting")
			local success, transcription = shell("vosk-transcriber -i " .. path .. " -m ../vosk/models/small")
			p("transcription, deleting", transcription)
			local deleted = shell("rm " .. path)

			if deleted then
				p("deleted, extracting")
				local text
				local lines = {}
				for line in string.gmatch(transcription, "[^\r\n]+") do
					table.insert(lines, line)
				end

				for i = #lines, 1, -1 do
					local line = lines[i]
					local trimmed = string.gsub(line, "^%s*(.-)%s*$", "%1")
					p("parse line", line, trimmed)

					if trimmed ~= "" and not string.match(trimmed, "^INFO") and not string.match(trimmed, "^LOG") and not string.find(trimmed:lower(), "execution time:") and not string.match(trimmed, "^{'%a+':%s*'.+'}$") then
						text = trimmed
						break
					end
				end

				p("text", text)

				if text then
					return text
				else
					return nil, "Failed to extract final transcription."
				end
			else
				return nil, "Failed to delete temporary WAV."
			end
		else
			return nil, "Failed to create temporary WAV."
		end
	end

	_G.transcribeAudio = transcribeAudio

	local function listen(voiceChannel, id, callback)
		id = (type(id) == "table" and id.id) or id

		if not voiceChannel then
			return false, "A voice channel was not provided."
		end
		if not id then
			return false, "An ID or User/Member object was not provided."
		end

		local connection = voiceChannel.connection or voiceChannel:join()

		if connection then
			connection:playFFmpeg("sounds/success.mp3")

			local user = connection.map:get(id)

			if user then
				user:unsubscribe()
				user:subscribe()

				local last = realtime()
				local CHANNELS, BIT_DEPTH, SAMPLE_RATE, MS_PER_S = 2, 16, 48000, 1000
				local silence = string.rep("\0", SAMPLE_RATE * CHANNELS * (BIT_DEPTH / 8) / MS_PER_S)

				user:on("speaking", function(speaking)
					if not speaking then
						return
					end

					callback("start")

					local data = ""

					user:on("pcmString", function(pcm)
						local now = realtime()
						local gap = last - now
						last = now

						if gap < 100 then
							gap = 0
						end

						data = data .. silence:rep(gap) .. pcm
						callback("pcm", pcm, gap, data)
					end)

					user:waitFor("speaking", 30000, function(s)
						return not s
					end)

					callback("stop")

					local transcription, err = transcribeAudio(data)
					if transcription then
						local unsubscribe = callback("transcription", transcription)

						if unsubscribe then
							user:unsubscribe()
						end
					else
						callback("error", err)
					end
				end)
			else
				return false, "User is not in the voice channel."
			end
		else
			return false, "Failed to connect to voice channel."
		end
	end

	_G.listen = listen

	local function getUserString(userOrId)
		if type(userOrId) == "table" then
			return "**@" .. userOrId.username .. "**"
		elseif tonumber(userOrId) then
			return "**@" .. userOrId .. "**"
		else
			return "***@" .. "unknown" .. "***"
		end
	end

	_G.getUserString = getUserString

	local function sanitizeUTF8(str)
		if not str or type(str) ~= "string" then
			return "Unable to display string."
		elseif str:usub(1, 2) == "!$" then -- skip utf8 sanitization
			return str:usub(3)
		end

		str = str:gsub("[^%w%p%s]", "")

		if str == "" then
			return "Unable to display string."
		end

		return str
	end

	_G.sanitizeUTF8 = sanitizeUTF8

	local function sanitizeGuildName(name)
		if not name or name:len() == 0 then
			return "???"
		end

		for _, code in utf8.codes(name) do
			if not ((code >= 32 and code <= 126) or (code > 127)) then
				return "???"
			end

			if code >= 0x1D400 and code <= 0x1D7FF then
				return "???"
			end
		end

		return name
	end

	_G.sanitizeGuildName = sanitizeGuildName

	local function containsComponentsV2(components)
		if not components then
			return false
		end

		for _, row in ipairs(components) do
			if row.type and row.type >= 16 then
				return true
			end

			if row.components then
				for _, comp in ipairs(row.components) do
					if comp.type and comp.type >= 16 then
						return true
					end
				end
			end
		end

		return false
	end

	_G.containsComponentsV2 = containsComponentsV2

	local function getOriginFunctionName()
		local info = debug.getinfo(3, "nSl")

		if not info then
			return "unknown"
		end

		if info.name then
			return info.name
		end

		local src = info.short_src or "unknown source"
		local line = info.linedefined or "?"
		return ("anonymous @ %s:%s"):format(src, line)
	end

	_G.getOriginFunctionName = getOriginFunctionName

	local function isURL(str)
		if (not str) or (type(str) ~= "string") then
			return
		end
		return (str:match("^https?://[%w-_]+%.[%w-_%.%?%.:/]+") and true) or false
	end

	_G.isURL = isURL

	local function urlToImage(url)
		local result, response = http.request("GET", url)
		if result and response then
			return "data:;base64," .. tostring(base64.encode(response))
		end
	end

	_G.urlToImage = urlToImage

	local function getUserFromAvatarURL(url, guild)
		local id = url:match("https://cdn%.discordapp%.com/avatars/(%d+)/")
		if id then
			return (guild and guild:getMember(id)) or ((not guild) and Client:getUser(id)) or nil
		end
	end

	_G.getUserFromAvatarURL = getUserFromAvatarURL

	local function migrate(channel, from, count)
		if not channel then
			return false, "No channel was provided."
		end
		if not from then
			return false, "No bot was provided."
		end

		local guild = channel.guild
		local config = sqldb:get(guild.id) or {}
		config.punishments = config.punishments or {}
		config.shifts = config.shifts or {}
		config.shifts.waves = config.shifts.waves or {}

		local existingPunishmentIds = {}
		for _, p in ipairs(config.punishments) do
			existingPunishmentIds[p.id] = true
		end

		local function field(embed, name)
			for _, f in pairs(embed.fields or {}) do
				if f.name:lower() == name:lower() then
					return f.value
				end
			end
		end

		local key = {
			erm = {
				name = "ERM",
				id = "", -- bot id
				punishments = {
					title = "",
					scrape = function(message)
						local embed = message.embed

						local existing = table.find(config.punishments, function(p)
							return p.id == message.id
						end)
						if existing then
							return false, "This punishment has already been migrated."
						end
					end
				},
				shifts = {}
			},
			trident = {
				name = "Trident",
				id = "1041159026324545566",
				punishments = {
					title = "Moderation | (%d+)",
					scrape = function(message)
						local embed = message.embed

						local existing = table.find(config.punishments, function(p)
							return p.id == message.id
						end)
						if existing then
							return false, "This punishment has already been migrated."
						end

						local moderator = getUserFromAvatarURL(embed.footer and embed.footer.icon_url, guild)
						if not moderator then
							return false, "The moderator could not be found."
						end

						local player = tonumber(field(embed, "User ID"))
						if not player then
							return false, "The Roblox player could not be found."
						end

						local type = field(embed, "Punishment")
						if not type then
							return false, "The punishment type could not be found."
						end

						local reason = field(embed, "Reason")
						if not reason then
							return false, "The punishment reason could not be found."
						end

						local timestamp = math.floor(message.createdAt)

						return {
							player = player,
							type = type,
							reason = reason,
							moderator = moderator.id,
							id = message.id,
							timestamp = timestamp
						}
					end
				},
				shifts = {}
			},
			melonly = {
				name = "Melonly",
				id = "1043430551601811456",
				punishments = {
					title = "Log Created",
					scrape = function(message)
						local embed = message.embed

						if existingPunishmentIds[message.id] then
							return false, "This punishment has already been migrated."
						end

						local player = field(embed, "User") and field(embed, "User"):match("%(`(%d+)`%)")
						if not player then
							return false, "The Roblox player could not be found."
						end

						local type = field(embed, "Type")
						if not type then
							return false, "The punishment type could not be found."
						end

						local reason = field(embed, "Reason")
						if not reason then
							return false, "The punishment reason could not be found."
						end

						local timestamp = math.floor(message.createdAt)

						local punishment = {
							player = tonumber(player),
							type = type,
							reason = reason,
							moderator = "1043430551601811456", -- Melonly embeds suck so you cannot get the moderator, this is Melonly bot ID
							id = message.id,
							timestamp = timestamp
						}

						return punishment
					end
				},
				shifts = {}
			},
			cyni = {
				name = "Cyni",
				id = "1136945734399295538",
				punishments = {
					title = "🛡️ Logged Punishment",
					scrape = function(message)
						local embed = message.embed

						local existing = table.find(config.punishments, function(p)
							return p.id == message.id
						end)
						if existing then
							return false, "This punishment has already been migrated."
						end

						local moderator = field(embed, "Moderator Information") and field(embed, "Moderator Information"):match("%*%*Mention:%*%*%s*<@(%d+)>%s*\n")
						moderator = moderator and guild:getMember(moderator)
						if not moderator then
							return false, "The moderator could not be found."
						end

						local player = field(embed, "Punishment Information") and field(embed, "Punishment Information"):match("%*%*Player:%*%*%s*(.-)\n")
						player = player and ropi.SearchUser(player)
						player = player and player.id
						if not player then
							return false, "The Roblox player could not be found."
						end

						local type = field(embed, "Punishment Information") and field(embed, "Punishment Information"):match("%*%*Type:%*%*%s*(.-)\n")
						if not type then
							return false, "The punishment type could not be found."
						end

						local reason = field(embed, "Punishment Information") and field(embed, "Punishment Information"):match("%*%*Reason:%*%*%s*(.-)\n")
						if not reason then
							return false, "The punishment reason could not be found."
						end

						local timestamp = math.floor(message.createdAt)

						local punishment = {
							player = tonumber(player),
							type = type,
							reason = reason,
							moderator = moderator.id,
							id = message.id,
							timestamp = timestamp
						}

						return punishment
					end
				},
				shifts = {}
			}
		}

		local bot = key[from:lower()]
		if not bot then
			return false, "The bot provided is invalid."
		end

		local fails = {}
		local logsProgress = 0
		local punishments = {}
		local shifts = {}

		fetchBulkMessages(channel, count or 500, function(batch)
			local batchSize = table.count(batch)

			for _, log in pairs(batch) do
				if log.user.id == bot.id and log.embed then
					if bot.punishments and bot.punishments.scrape and ((log.embed.title and log.embed.title:match(bot.punishments.title)) or (log.embed.author and log.embed.author.name:match(bot.punishments.title))) then
						local punishment, err = bot.punishments.scrape(log)

						if punishment then
							existingPunishmentIds[punishment.id] = true
							table.insert(punishments, punishment)
						else
							table.insert(fails, "Failed to migrate punishment " .. log.id .. " from " .. bot.name .. ": " .. err)
						end
					elseif bot.shifts and bot.shifts.scrape and ((log.embed.title and log.embed.title:match(bot.shifts.title)) or (log.embed.author and log.embed.author.name:match(bot.shifts.title))) then
						local shift, err = bot.shifts.scrape(log)

						if shift then
							table.insert(shifts, shift)
						else
							table.insert(fails, "Failed to migrate shift " .. log.id .. " from " .. bot.name .. ": " .. err)
						end
					end
				end
			end

			logsProgress = logsProgress + batchSize
			if logsProgress % 1000 == 0 or batchSize ~= 100 then
				channel:send("Fetched and scraped " .. logsProgress)
			end
		end)

		local punishmentsMigrated = 0
		local shiftsMigrated = 0

		for _, punishment in ipairs(punishments) do
			punishmentsMigrated = punishmentsMigrated + 1
			table.insert(config.punishments, punishment)
		end
		punishments = nil

		for _, shift in ipairs(shifts) do
			shiftsMigrated = shiftsMigrated + 1
			db:shiftInsert(guild, shift)
		end
		shifts = nil

		local success, err = sqldb:set(guild.id, {
			punishments = config.punishments
		}, "PUNISHMENTS_MIGRATE")
		if not success then
			return false, "Failed to save migrated data: " .. err
		end

		channel:send("Successfully migrated " .. punishmentsMigrated .. " punishments and " .. shiftsMigrated .. " shifts from " .. bot.name .. ".")

		return true, table.concat(fails, "\n")
	end

	_G.migrate = migrate

	local function hasKeys(tbl, keys)
		local ret = table.deepcopy(tbl)
		local result = false

		table.deeppairs(ret, function(t, i, v)
			if type(v) == "string" then
				for _, key in pairs(keys) do
					if v:find(key) then
						result = true
					end
				end
			else
				return v
			end
		end)

		return result
	end

	_G.hasKeys = hasKeys

	local function runAutomation(automation, config, guild, players, keys, executions, ranAt, executor)
		if automation.disabled then
			return
		end

		local function debug(str)
			if guild.id == "1459609014475166024" and tostring(automation.id) == "5" then
				p(str)
			end
		end

		local nowRound = os.time()
		local actions = automation.actions or {}
		local conditions = automation.conditions or {}
		local results = {}
		ranAt = ranAt or realtime()
		local oldLastTriggered = automation.lastTriggered
		local hasLastTriggered = false

		local splitTrigger = string.split(automation.trigger.value, ":")
		local trigger = splitTrigger[1]

		for _, condition in pairs(conditions) do
			local valueStr = condition.value or ""
			local split = string.split(valueStr, ":")
			local name = split[1]
			local value = split[2]

			if name == "lastTriggered" then
				debug("AMS oldLastTriggered: " .. oldLastTriggered)
				debug("AMS diff: " .. (realtime() - oldLastTriggered))
				if oldLastTriggered and ((realtime() - oldLastTriggered) < tonumber(value)) then
					return
				end

				hasLastTriggered = true
				break
			end
		end

		if trigger == "interval" then
			hasLastTriggered = true
		end

		if hasLastTriggered then
			local finalTimestamp = ranAt
			if trigger == "interval" then
				local interval = automation.trigger.interval
				if interval and interval.type == "interval" then
					local newNextRun = ranAt
					local now = realtime()
					while now >= newNextRun do
						newNextRun = newNextRun + interval.seconds
					end
					finalTimestamp = newNextRun - interval.seconds
				end
			end

			debug("AMS: updating last triggered")
			sqldb:_queryRun({
				query = [[
					UPDATE guilds
					SET setting_value = (
						SELECT json_group_array(
							CASE 
								WHEN json_extract(value, '$.id') = ? 
								THEN json_set(value, '$.lastTriggered', ?)
								ELSE value 
							END
						)
						FROM json_each(COALESCE(setting_value, '[]'))
					)
					WHERE guild_id = ? AND setting_key = 'automations';
				]],
				values = {automation.id, finalTimestamp, guild.id}
			})
			debug("AMS: updated last triggered")

			if config.automations then
				for i, ams in ipairs(config.automations) do
					if ams.id == automation.id then
						config.automations[i].lastTriggered = finalTimestamp
						break
					end
				end
			end
		end

		debug("AMS: 1")

		if not executions or table.count(executions) <= 0 then
			executions = (keys and {
				keys
			}) or {
				{}
			}
		end

		if not players then
			local server = config.apikey and ERLC:getServer(config.apikey)
			if server then
				players = server.players
			end
		end

		for exei, _ in ipairs(executions) do
			results[exei] = {
				conditions = {},
				actions = {}
			}
		end

		debug("AMS: 2")

		if type(executor) == "string" then
			executor = Client:getUser(executor)
		end

		local executorLink = executor and sqldb:getLink(executor.id)
		local executorRoblox = executorLink and ropi.GetUser(executorLink.roblox)

		-- Check conditions for a single execution. Returns boolean
		local function checkConditions(localKeys, exei, recheck)
			local copiedKeys = localKeys and table.deepcopy(localKeys)
			local passedAll = true

			for _, cond in pairs(conditions) do
				local valueStr = cond.value or ""
				local split = string.split(valueStr, ":")
				local name, value, target = split[1], split[2], split[3]
				local passedCond = true

				if name == "session" then
					config.session = config.session or {}
					if not config.session.status then
						passedCond = false
					else
						if value == "equal" and config.session.status ~= target then
							passedCond = false
						end
						if value == "notequal" and config.session.status == target then
							passedCond = false
						end
					end
				elseif name == "playerCount" then
					local plrcount = table.count(players)
					local tnum = tonumber(target)
					if value == "equal" and plrcount ~= tnum then
						passedCond = false
					end
					if value == "notequal" and plrcount == tnum then
						passedCond = false
					end
					if value == "lessorequal" and plrcount > tnum then
						passedCond = false
					end
					if value == "greaterorequal" and plrcount < tnum then
						passedCond = false
					end
					if value == "less" and plrcount >= tnum then
						passedCond = false
					end
					if value == "greater" and plrcount <= tnum then
						passedCond = false
					end
				else
					-- Conditions that depend on local keys
					if not copiedKeys or table.count(copiedKeys) == 0 then
						passedCond = false
					else
						local targetMap = {
							player = {
								id = copiedKeys["player.id"] or copiedKeys["caller.id"],
								name = copiedKeys["player.name"] or copiedKeys["called.name"]
							},
							mod = {
								id = copiedKeys["moderator.id"],
								name = copiedKeys["moderator.name"]
							},
							staff = {
								id = copiedKeys["staff.id"],
								name = copiedKeys["staff.name"]
							},
							killed = {
								id = copiedKeys["killed.id"],
								name = copiedKeys["killed.name"]
							},
							killer = {
								id = copiedKeys["killer.id"],
								name = copiedKeys["killer.name"]
							}
						}

						local tgt = targetMap[target]
						local targetId = tgt and tgt.id
						local targetName = tgt and tgt.name

						if not targetId or not targetName then
							passedCond = false
						else
							local m = inDiscord({
								id = targetId,
								name = targetName
							}, guild)

							if name == "notrole" then
								if m and m:hasRole(value) then
									passedCond = false
								end
							elseif name == "role" then
								if not m or not m:hasRole(value) then
									passedCond = false
								end
							elseif name == "erlcTeamequal" or name == "erlcTeamnotequal" then
								local ingamePlayer = table.find(players, function(p)
									return p.id == targetId
								end)

								if name == "erlcTeamequal" then
									if not ingamePlayer or ingamePlayer.team ~= value then
										passedCond = false
									end
								else -- erlcTeamnotequal
									if ingamePlayer and ingamePlayer.team == value then
										passedCond = false
									end
								end
							elseif name == "region" or name == "notregion" then
								local ingamePlayer = table.find(players, function(p)
									return p.id == targetId
								end)

								local region = config.regions and table.find(config.regions, function(r)
									return r.name:lower() == value:lower()
								end)
								local Region = region and erlua.Region(region.name, region.points)

								if name == "region" then
									if not Region or not ingamePlayer or not Region:contains(ingamePlayer.location) then
										passedCond = false
									end
								elseif Region then
									if ingamePlayer and Region:contains(ingamePlayer.location) then
										passedCond = false
									end
								end
							end
						end
					end
				end

				table.insert(results[exei].conditions, {
					passed = passedCond,
					name = cond.name,
					recheck = recheck
				})
				if not passedCond then
					passedAll = false
					break
				end
			end

			return passedAll
		end

		debug("AMS: 3")

		local commandKeys = {}
		local passedExecutions = {}
		local passMap = {} -- passMap[actionIndex] = { [exei] = true }

		for exei, localKeys in ipairs(executions) do
			if checkConditions(localKeys, exei) then
				passedExecutions[exei] = true
			end

			if not localKeys["timestamp"] then
				localKeys["timestamp"] = nowRound
			end

			if executor then
				localKeys = DiscordUserVariables(executor, "executor.discord", localKeys)
			end

			if executorRoblox then
				localKeys = RobloxUserVariables(executorRoblox, "executor.roblox", localKeys)
			end
		end

		debug("AMS: 4")

		for ai, action in ipairs(actions) do
			passMap[ai] = {}
			local name, value = action.value:match("^(.-):(.*)$")
			if not name then
				name = action.value
			end

			if name == "sendcommand" then
				for exei, localKeys in ipairs(executions) do
					if passedExecutions[exei] then
						passMap[ai][exei] = true
						for keyName, v in pairs(localKeys) do
							if (type(v) == "string" or type(v) == "number") and value and value:find("{" .. keyName .. "}") then
								commandKeys[keyName] = commandKeys[keyName] or {}
								commandKeys[keyName][v] = true
							end
						end
					end
				end
			else
				for exei, localKeys in ipairs(executions) do
					if passedExecutions[exei] then
						passMap[ai][exei] = true
					end
				end
			end
		end

		debug("AMS: 5")

		for keyName, set in pairs(commandKeys) do
			local list = {}
			for v, _ in pairs(set) do
				table.insert(list, v)
			end
			commandKeys[keyName] = table.concat(list, ",")
		end

		local flags = {
            staff = {
                match = {"{staff}", "{staff.count}"},
                check = function(plr)
                    return plr.permission ~= erlua.enums.permission.normal
                end,
                fallback = "(No-Staff-Found)"
            },
            notindiscord = {
                match = {"{notindiscord}", "{notindiscord.count}"},
                check = function(plr)
                    return not inDiscord(plr, guild)
                end,
                fallback = "(All-Players-In-Discord)"
            },
            onshift = {
                match = {"{onshift}", "{onshift.count}"},
                check = function(plr)
                    local discord = inDiscord(plr, guild)
                    if discord and plr.permission ~= erlua.enums.permission.normal then
                        local active, pause = db:shiftActive(discord)
                        if active and not pause then
                            return true
                        end
                    end
                end,
                fallback = "(None-On-Shift)"
            },
            onpause = {
                match = {"{onpause}", "{onpause.count}"},
                check = function(plr)
                    local discord = inDiscord(plr, guild)
                    if discord and plr.permission ~= erlua.enums.permission.normal then
                        local active, pause = db:shiftActive(discord)
                        if active and pause then
                            return true
                        end
                    end
                end,
                fallback = "(None-On-Pause)"
            },
            offshift = {
                match = {"{offshift}", "{offshift.count}"},
                check = function(plr)
                    local discord = inDiscord(plr, guild)
                    if discord and plr.permission ~= erlua.enums.permission.normal then
                        local active = db:shiftActive(discord)
                        if not active then
                            return true
                        end
                    end
                end,
                fallback = "(None-Off-Shift)"
            },
            police = {
                match = {"{police}", "{police.count}"},
                check = function(plr)
                    return plr.team == "Police"
                end,
                fallback = "(No-Police)"
            },
            sheriff = {
                match = {"{sheriff}", "{sheriff.count}"},
                check = function(plr)
                    return plr.team == "Sheriff"
                end,
                fallback = "(No-Sheriffs)"
            },
            fire = {
                match = {"{fire}", "{fire.count}"},
                check = function(plr)
                    return plr.team == "Fire"
                end,
                fallback = "(No-Firefighters)"
            },
            dot = {
                match = {"{dot}", "{dot.count}"},
                check = function(plr)
                    return plr.team == "DOT"
                end,
                fallback = "(No-DOT)"
            },
            civilian = {
                match = {"{civilian}", "{civilian.count}"},
                check = function(plr)
                    return plr.team == "Civilian"
                end,
                fallback = "(No-Civilians)"
            }
        }

		local flagKeys = {}
		local loadFlagKeys = false

		for _, action in ipairs(actions) do
			local name, value = action.value:match("^(.-):(.*)$")
			if not name then
				name = action.value
			end

			if name == "sendcommand" or name == "sendmessage" and value then
				for key, flag in pairs(flags) do
					for _, s in pairs(flag.match) do
						if value:find(s, 1, true) then
							loadFlagKeys = true
							break
						end
					end
				end
			end
		end

		if loadFlagKeys then
			if players then
				loadMembers(guild)

				for _, plr in pairs(players) do
					for key, flag in pairs(flags) do
						if flag.check(plr) then
							flagKeys[key] = flagKeys[key] or {}
							table.insert(flagKeys[key], plr.name)
						end
					end
				end

				for key, flag in pairs(flags) do
					local rawFlagvalue = flagKeys[key]
					local flagvalue = flag.fallback
					local flagcount = 0

					if type(rawFlagvalue) == "table" and next(rawFlagvalue) then
						flagvalue = table.concat(rawFlagvalue, ",")
						flagcount = table.count(rawFlagvalue)
					end

					for exei, _ in pairs(executions) do
						executions[exei][key] = flagvalue
						executions[exei][key .. ".count"] = flagcount
					end

					commandKeys[key] = flagvalue
					commandKeys[key .. ".count"] = flagcount
				end
			end
		end

		debug("AMS: 6")

		if not commandKeys["timestamp"] then
			commandKeys["timestamp"] = nowRound
		end

		local executedCommands = {}
		local function executeCommand(cmd)
			if (not config.apikey) or (type(cmd) ~= "string") or (executedCommands[cmd]) then
				return
			end

			local server, err = ERLC:getServer(config.apikey)
			if not server then
				return false, err
			end

			executedCommands[cmd] = true

			local singleExeCmds = {
				unadmin = true,
				admin = true,
				helper = true,
				unhelper = true,
				mod = true,
				unmod = true,
				ban = true,
				unban = true
			}

			local args = string.split(cmd, " ")
			local verb = args[1]
			local targets = args[2] and string.split(args[2], ",")

			if singleExeCmds[verb] and targets and table.count(targets) > 1 then
				local copyargs = table.copy(args)
				table.remove(copyargs, 1)
				table.remove(copyargs, 1)
				local ext = (next(copyargs) and table.concat(copyargs, " ")) or ""

				local succ, response = true, nil
				for _, target in pairs(targets) do
					local fullCmd = ":" .. verb .. " " .. target .. (ext ~= "" and " " .. ext or "")
					local s, r = server:execute(fullCmd)
					if not s then
						succ, response = s, r
					end
				end
				return succ, response
			else
				local succ, response = server:execute(cmd)
				if not succ then
					executedCommands[cmd] = nil
				end
				return succ, response
			end
		end

		debug("AMS: 7")

		for ai, action in ipairs(actions) do
			local name, value = action.value:match("^(.-):(.*)$")
			if not name then
				name = action.value
			end

			if name == "delay" then
				if next(passMap[ai]) then
					timer.sleep(tonumber(value) * 1000)
					for exei, _ in pairs(passMap[ai]) do
						table.insert(results[exei].actions, {
							name = action.name,
							success = true
						})
					end
				end
			elseif name == "sendcommand" then
				local succ, response
				if next(passMap[ai]) then
					if next(commandKeys) then
						local cmds = parseTable({
							value
						}, commandKeys)
						if cmds and cmds[1] then
							succ, response = executeCommand(cmds[1])
						end
					else
						succ, response = executeCommand(value)
					end

					for exei, _ in pairs(passMap[ai]) do
						table.insert(results[exei].actions, {
							name = action.name,
							success = succ,
							error = response or nil
						})
					end

					timer.sleep(10)
				else
					for exei, _ in pairs(passMap[ai]) do
						table.insert(results[exei].actions, {
							name = action.name,
							success = false,
							error = "Conditions failed"
						})
					end
				end
			elseif name == "sendmessage" then
				for exei, _ in pairs(passMap[ai]) do
					local localKeys = executions[exei]
					local split = string.split(value, ":")
					local channelid = split[1]
					table.remove(split, 1)
					local data = table.concat(split, ":")
					local channel = guild:getChannel(channelid)
					if channel then
						local decoded = json.decode(data)
						if decoded then
							local tosend = parseTable({
								decoded
							}, localKeys)
							if tosend and tosend[1] then
								local succ, err = channel:send(tosend[1])
								table.insert(results[exei].actions, {
									name = action.name,
									success = not not succ,
									error = err or nil
								})
							else
								channel:fail("An error occurred while attempting to send an automation message.")
								table.insert(results[exei].actions, {
									name = action.name,
									success = false,
									error = "Failed to parse variables."
								})
							end
						else
							if channel then
								channel:fail("An error occurred while attempting to send an automation message")
							end
							table.insert(results[exei].actions, {
								name = action.name,
								success = false,
								error = "Failed to decode message."
							})
						end
					else
						table.insert(results[exei].actions, {
							name = action.name,
							success = false,
							error = "Channel not found."
						})
					end
				end
			elseif name == "endshifts" then
				for exei, _ in pairs(passMap[ai]) do
					local succ, err = db:shiftEndAll(guild, nil, nil, "automation " .. automation.id .. ", action #" .. tostring(ai))
					table.insert(results[exei].actions, {
						name = action.name,
						success = succ,
						error = err or nil
					})
				end
			elseif name == "recheckconditions" then
				local pass = true

				for exei, _ in pairs(passMap[ai]) do
					local localKeys = executions[exei]
					local still = checkConditions(localKeys, exei, true)
					if not still then
						for aj = ai + 1, #actions do
							if passMap[aj] then
								passMap[aj][exei] = nil
							end
						end
						passMap[ai][exei] = nil
						table.insert(results[exei].actions, {
							name = action.name,
							success = false,
							error = "Conditions no longer met"
						})
						pass = false
						break
					else
						table.insert(results[exei].actions, {
							name = action.name,
							success = true
						})
					end
				end

				if not pass then
					break
				end
			elseif name == "lockchannel" then
				for exei, _ in pairs(passMap[ai]) do
					local channel = guild:getChannel(value)
					local success, err
					if channel then
						local everyone = guild.defaultRole

						local permissionOverwrite = channel:getPermissionOverwriteFor(everyone)
						local locked = permissionOverwrite:getDeniedPermissions():has(discordia.enums.permission.sendMessages)

						if not locked then
							success, err = permissionOverwrite:denyPermissions(discordia.enums.permission.sendMessages)
						else
							success = false
							err = "The channel is already locked."
						end
					end

					table.insert(results[exei].actions, {
						name = action.name,
						success = success and true or false,
						error = err or nil
					})
				end
			elseif name == "unlockchannel" then
				for exei, _ in pairs(passMap[ai]) do
					local channel = guild:getChannel(value)
					local success, err
					if channel then
						local everyone = guild.defaultRole

						local permissionOverwrite = channel:getPermissionOverwriteFor(everyone)
						local locked = permissionOverwrite:getDeniedPermissions():has(discordia.enums.permission.sendMessages)

						if locked then
							success, err = permissionOverwrite:allowPermissions(discordia.enums.permission.sendMessages)
						else
							success = false
							err = "The channel is not locked."
						end
					end

					table.insert(results[exei].actions, {
						name = action.name,
						success = success and true or false,
						error = err or nil
					})
				end
			elseif name == "sessionstart" then
				for exei, _ in pairs(passMap[ai]) do
					if guild:getMember(automation.author) then
						local succ, err = db:sessionStart(guild:getMember(automation.author))
						table.insert(results[exei].actions, {
							name = action.name,
							success = succ,
							error = err or nil
						})
					else
						table.insert(results[exei].actions, {
							name = action.name,
							success = false,
							error = "Author is missing"
						})
					end
				end

			elseif name == "sessionvote" then
				for exei, _ in pairs(passMap[ai]) do
					if guild:getMember(automation.author) then
						local succ, err = db:sessionVote(guild:getMember(automation.author), tonumber(value), true)
						table.insert(results[exei].actions, {
							name = action.name,
							success = succ,
							error = err or nil
						})
					else
						table.insert(results[exei].actions, {
							name = action.name,
							success = false,
							error = "Author is missing"
						})
					end
				end

			elseif name == "sessionend" then
				for exei, _ in pairs(passMap[ai]) do
					if guild:getMember(automation.author) then
						local succ, err = db:sessionEnd(guild:getMember(automation.author))
						table.insert(results[exei].actions, {
							name = action.name,
							success = succ,
							error = err or nil
						})
					else
						table.insert(results[exei].actions, {
							name = action.name,
							success = false,
							error = "Author is missing"
						})
					end
				end
			elseif name == "punish" then
				local split = string.split(value, ":")
				local target = split and split[1]
				local type = split and split[2]
				local reason = split and split[3]

				for exei, _ in pairs(passMap[ai]) do
					if not target or not type or not reason then
						table.insert(results[exei].actions, {
							name = action.name,
							success = false,
							error = "Invalid target, type or reason"
						})

						goto skip
					end

					local localKeys = executions[exei]
					local targetMap = {
						player = {
							id = localKeys["player.id"] or localKeys["caller.id"],
							name = localKeys["player.name"] or localKeys["called.name"]
						},
						mod = {
							id = localKeys["moderator.id"],
							name = localKeys["moderator.name"]
						},
						staff = {
							id = localKeys["staff.id"],
							name = localKeys["staff.name"]
						},
						killed = {
							id = localKeys["killed.id"],
							name = localKeys["killed.name"]
						},
						killer = {
							id = localKeys["killer.id"],
							name = localKeys["killer.name"]
						}
					}

					local targetId = targetMap[target] and targetMap[target].id

					if not targetId then
						table.insert(results[exei].actions, {
							name = action.name,
							success = false,
							error = "Invalid targetId"
						})

						goto skip
					end

					if not guild.me then
						table.insert(results[exei].actions, {
							name = action.name,
							success = false,
							error = "me property is nil on guild"
						})

						goto skip
					end

					local targetPlayer = ropi.GetUser(targetId)

					if not targetPlayer then
						table.insert(results[exei].actions, {
							name = action.name,
							success = false,
							error = "Target player not found"
						})

						goto skip
					end

					local punishment = db:punishmentCreate({id = snowGen:next()}, guild.me, targetPlayer, type, reason)

					if not punishment then
						table.insert(results[exei].actions, {
							name = action.name,
							success = false,
							error = "Punishment creation returned no punishment"
						})

						goto skip
					end

					table.insert(results[exei].actions, {
						name = action.name,
						success = true,
					})

					::skip::
				end
			else
				for exei, _ in pairs(passMap[ai]) do
					table.insert(results[exei].actions, {
						name = action.name,
						success = false,
						error = "Unknown action"
					})
				end
			end
		end

		debug("AMS: 8")

		local embedTemplate = {
			author = {
				name = " #" .. automation.id .. "・" .. automation.name .. " Execution Result",
				icon_url = resolvedEmojis.automation.image
			},
			title = "",
			description = "",
			color = colors.success
		}

		local embeds = {}

		if type(results) == "table" and next(results) then
			for exei, result in ipairs(results) do
				if type(result) == "table" and (next(result.conditions) or next(result.actions)) then
					local embed = table.deepcopy(embedTemplate)

					embed.title = emojis.draft .. " Execution #" .. tostring(exei)

					if next(result.conditions) then
						embed.description = embed.description .. emojis.right .. " Conditions"

						for _, condition in ipairs(result.conditions) do
							if condition.passed then
								embed.description = embed.description .. "\n" .. emojis.space .. emojis.success .. " " .. ((condition.recheck and "Re-checking condition") or "Condition") .. " **" .. condition.name .. "** has passed"
							else
								embed.description = embed.description .. "\n" .. emojis.space .. emojis.fail .. " " .. ((condition.recheck and "Re-checking condition") or "Condition") .. " **" .. condition.name .. "** has failed"
								embed.color = colors.fail
							end
						end

						embed.description = embed.description .. "\n"
					end

					if next(result.actions) then
						embed.description = embed.description .. emojis.right .. " Actions"

						for _, action in ipairs(result.actions) do
							if action.success then
								embed.description = embed.description .. "\n" .. emojis.space .. emojis.success .. " Action **" .. action.name .. "** has been executed successfully"
							else
								embed.description = embed.description .. "\n" .. emojis.space .. emojis.fail .. " Action **" .. action.name .. "** has failed to execute: `" .. ((action.error and type(action.error) == "string" and action.error) or (action.error and type(action.error) == "table" and action.error.message) or "Unknown error") .. "`"
								embed.color = colors.fail
							end
						end
					end

					table.insert(embeds, embed)
				end
			end

			if automation.resultschannel and next(embeds) then
				local resultschannel = guild:getChannel(automation.resultschannel)

				if resultschannel then
					local message = {
						embeds = {}
					}

					for i, embed in pairs(embeds) do
						table.insert(message.embeds, embed)

						if table.count(message.embeds) == 10 or i == table.count(embeds) then
							resultschannel:send(message)
							message = {
								embeds = {}
							}
						end
					end
				end
			end
		end

		return results, embeds
	end

	_G.runAutomation = runAutomation

	local function fetchAutomationContexts(automation, guild)
		local contexts = {}
		local seen = {}

		local function exists(type, value)
			if not guild or not value then
				return false
			end

			if type == "channel" then
				return guild:getChannel(value) ~= nil
			elseif type == "role" then
				return guild:getRole(value) ~= nil
			elseif type == "punishment" then
				for _, type in pairs(sqldb:get(guild.id).punishmenttypes or {}) do
					if value:lower() == type:lower() then
						return true
					end
				end
			end

			return false
		end

		local function add(type, id, usage, target, reason)
			if not id then
				return
			end

			local key = type .. ":" .. id
			if seen[key] then
				return
			end
			seen[key] = true

			if exists(type, id) then
				return
			end

			table.insert(contexts, {
				type = type,
				value = id,
				usage = usage,
				target = target,
				reason = reason
			})
		end

		if automation.resultschannel then
			add("resultschannel", automation.resultschannel, "results channel")
		end

		for _, cond in ipairs(automation.conditions or {}) do
			local split = string.split(cond.value or "", ":")
			local name = split[1]
			local id = split[2]

			if name == "role" then
				add("role", id, "has role condition")
			elseif name == "notrole" then
				add("role", id, "does not have role condition")
			end
		end

		for _, action in ipairs(automation.actions or {}) do
			local splitAction = action.value:split(":")
			local name, value, value2, value3 = splitAction[1], splitAction[2] or splitAction[1], splitAction[3], splitAction[4]

			if name == "sendmessage" and value then
				add("channel", value, "send a message")
			elseif name == "lockchannel" then
				add("channel", value, "lock a channel")
			elseif name == "unlockchannel" then
				add("channel", value, "unlock a channel")
			elseif name == "punish" then
				add("punishment", value2, "punish a player", value, value3)
			end
		end

		if automation.customization and automation.customization.requiredRole then
			add("customizable_requiredRole", automation.customization.requiredRole, "customization required role")
		end

		return contexts
	end
	_G.fetchAutomationContexts = fetchAutomationContexts

	local function safeRoleOperation(member, roleId, operation, maxRetries, initiation)
		maxRetries = maxRetries or 3
		local attempts = 0

		while attempts < maxRetries do
			attempts = attempts + 1

			local function executeOperation()
				if operation == "add" then
					if not member:hasRole(roleId) then
						return member:addRole(roleId, initiation)
					else
						return true
					end
				elseif operation == "remove" then
					if member:hasRole(roleId) then
						return member:removeRole(roleId, initiation)
					else
						return true
					end
				end
			end

			local success, err = executeOperation()

			if success then
				return true
			else
				if err and (string.find(err, "rate limit") or string.find(err, "429")) then
					local backoffDelay = math.min(1000 * (2 ^ (attempts - 1)), 8000)
					timer.sleep(backoffDelay)
				elseif attempts >= maxRetries then
					print("Failed to " .. operation .. " role " .. roleId .. " for member " .. member.id .. ": " .. tostring(err))
					return false, err
				else
					timer.sleep(500)
				end
			end
		end

		return false
	end

	_G.safeRoleOperation = safeRoleOperation

	local function batchRoleOperations(member, rolesToAdd, rolesToRemove, initiation)
		local operations = {}
		local success = true

		for _, roleId in pairs(rolesToAdd or {}) do
			if not member:hasRole(roleId) then
				table.insert(operations, {
					role = roleId,
					operation = "add"
				})
			end
		end

		for _, roleId in pairs(rolesToRemove or {}) do
			if member:hasRole(roleId) then
				table.insert(operations, {
					role = roleId,
					operation = "remove"
				})
			end
		end

		for i, op in pairs(operations) do
			local opSuccess = safeRoleOperation(member, op.role, op.operation, nil, initiation)
			if not opSuccess then
				success = false
			end

			if i < #operations then
				timer.sleep(50)
			end
		end

		return success, table.count(operations)
	end

	local function updateMember(member, initiation)
		if not member or not member.id or not member.user or member.user.bot then
			return false, "Invalid member or provided member is a bot."
		end

		local guild = member.guild
		local config = sqldb:get(guild.id) or {}

		--- Checking if roles can be managed --
		local changes = {}
		for i, v in pairs(config.verifiedroles or {}) do
			local succ, result = canManageRole(v)

			if not succ then
				table.remove(config.verifiedroles, i)
				changes["verifiedroles"] = config.verifiedroles
				local role = member.guild:getRole(v)
				NotifyRemoveFromConfig(member.guild.id, emojis.roblox .. " Roblox Verification", ((role and role.name) or "*Unknown*") .. " Verified Role", result)
			end
		end

		for i, v in pairs(config.unverifiedroles or {}) do
			local succ, result = canManageRole(v)

			if not succ then
				table.remove(config.unverifiedroles, i)
				changes["unverifiedroles"] = config.unverifiedroles
				local role = member.guild:getRole(v)
				NotifyRemoveFromConfig(member.guild.id, emojis.roblox .. " Roblox Verification", ((role and role.name) or "*Unknown*") .. " Unverified Role", result)
			end
		end

		for i, v in pairs(config.joinroles or {}) do
			local succ, result = canManageRole(v)

			if not succ then
				table.remove(config.joinroles, i)
				changes["joinroles"] = config.joinroles
				local role = member.guild:getRole(v)
				NotifyRemoveFromConfig(member.guild.id, emojis.wave .. " Welcome/Autoroles", ((role and role.name) or "*Unknown*") .. " AutoRole", result)
			end
		end

		if next(changes) then
			sqldb:set(member.guild.id, changes, "NO_PERMISSIONS_UPDATE_MEMBER_ROLES")
		end
		--- End checking if roles can be managed --

		local rolesToAdd = {}
		local rolesToRemove = {}

		local link = sqldb:getLink(member.id)
		local roblox = link and link.roblox and ropi.GetUser(link.roblox)

		if roblox then
			local nameKeys = {
				["roblox.username"] = roblox.name,
				["roblox.display"] = roblox.displayName,
				["roblox.id"] = tostring(roblox.id),
				["discord.username"] = member.user.username,
				["discord.name"] = member.user.globalName or member.user.name,
				["discord.id"] = tostring(member.user.id)
			}

			if config.verifiednickname then
				local nickname = parseTable({
					config.verifiednickname
				}, nameKeys)[1]
				nickname = nickname:usub(1, 32)
				member:setNickname(nickname)
			end

			if config.verifiedroles then
				for _, roleId in pairs(config.verifiedroles) do
					table.insert(rolesToAdd, roleId)
				end
			end

			if config.unverifiedroles then
				for _, roleId in pairs(config.unverifiedroles) do
					table.insert(rolesToRemove, roleId)
				end
			end
		else
			if config.unverifiedroles then
				for _, roleId in pairs(config.unverifiedroles) do
					table.insert(rolesToAdd, roleId)
				end
			end

			if config.verifiedroles then
				for _, roleId in pairs(config.verifiedroles) do
					table.insert(rolesToRemove, roleId)
				end
			end
		end

		if config.joinroles then
			for _, roleId in pairs(config.joinroles) do
				table.insert(rolesToAdd, roleId)
			end
		end

		local success, opCount = batchRoleOperations(member, rolesToAdd, rolesToRemove, initiation)
		return success, opCount
	end

	_G.updateMember = updateMember

	local timezones = {
		{
			abrv = "UTC",
			name = "Coordinated Universal Time",
			offset = 0,
			twelvehourclock = true
		},
		{
			abrv = "EST",
			name = "Eastern Standard Time",
			offset = -5,
			twelvehourclock = true
		},
		{
			abrv = "EDT",
			name = "Eastern Daylight Time",
			offset = -4,
			twelvehourclock = true
		},
		{
			abrv = "CST",
			name = "Central Standard Time",
			offset = -6,
			twelvehourclock = true
		},
		{
			abrv = "CDT",
			name = "Central Daylight Time",
			offset = -5,
			twelvehourclock = true
		},
		{
			abrv = "MST",
			name = "Mountain Standard Time",
			offset = -7,
			twelvehourclock = true
		},
		{
			abrv = "MDT",
			name = "Mountain Daylight Time",
			offset = -6,
			twelvehourclock = true
		},
		{
			abrv = "PST",
			name = "Pacific Standard Time",
			offset = -8,
			twelvehourclock = true
		},
		{
			abrv = "PDT",
			name = "Pacific Daylight Time",
			offset = -7,
			twelvehourclock = true
		},
		{
			abrv = "AKST",
			name = "Alaska Standard Time",
			offset = -9,
			twelvehourclock = true
		},
		{
			abrv = "AKDT",
			name = "Alaska Daylight Time",
			offset = -8,
			twelvehourclock = true
		},
		{
			abrv = "HST",
			name = "Hawaii Standard Time",
			offset = -10,
			twelvehourclock = true
		},
		{
			abrv = "HDT",
			name = "Hawaii Daylight Time",
			offset = -9,
			twelvehourclock = true
		},
		{
			abrv = "ATST",
			name = "Atlantic Standard Time",
			offset = -4,
			twelvehourclock = true
		},
		{
			abrv = "ADT",
			name = "Atlantic Daylight Time",
			offset = -3,
			twelvehourclock = true
		},
		{
			abrv = "NST",
			name = "Newfoundland Standard Time",
			offset = -3.5,
			twelvehourclock = true
		},
		{
			abrv = "NDT",
			name = "Newfoundland Daylight Time",
			offset = -2.5,
			twelvehourclock = true
		},
		{
			abrv = "GMT",
			name = "Greenwich Mean Time",
			offset = 0,
			twelvehourclock = false
		},
		{
			abrv = "BST",
			name = "British Summer Time",
			offset = 1,
			twelvehourclock = false
		},
		{
			abrv = "CET",
			name = "Central European Time",
			offset = 1,
			twelvehourclock = false
		},
		{
			abrv = "CEST",
			name = "Central European Summer Time",
			offset = 2,
			twelvehourclock = false
		},
		{
			abrv = "EET",
			name = "Eastern European Time",
			offset = 2,
			twelvehourclock = false
		},
		{
			abrv = "EEST",
			name = "Eastern European Summer Time",
			offset = 3,
			twelvehourclock = false
		},
		{
			abrv = "IST",
			name = "India Standard Time",
			offset = 5.5,
			twelvehourclock = false
		},
		{
			abrv = "CST",
			name = "China Standard Time",
			offset = 8,
			twelvehourclock = false
		},
		{
			abrv = "JST",
			name = "Japan Standard Time",
			offset = 9,
			twelvehourclock = false
		},
		{
			abrv = "AEST",
			name = "Australian Eastern Standard Time",
			offset = 10,
			twelvehourclock = true
		},
		{
			abrv = "AEDT",
			name = "Australian Eastern Daylight Time",
			offset = 11,
			twelvehourclock = true
		},
		{
			abrv = "ACST",
			name = "Australian Central Standard Time",
			offset = 9.5,
			twelvehourclock = true
		},
		{
			abrv = "ACDT",
			name = "Australian Central Daylight Time",
			offset = 10.5,
			twelvehourclock = true
		},
		{
			abrv = "AWST",
			name = "Australian Western Standard Time",
			offset = 8,
			twelvehourclock = true
		},
		{
			abrv = "AWDT",
			name = "Australian Western Daylight Time",
			offset = 9,
			twelvehourclock = true
		},
		{
			abrv = "AWDT",
			name = "Australian Western Daylight Time",
			offset = 9,
			twelvehourclock = true
		},
		{
			abrv = "NZDT",
			name = "New Zealand Daylight Time",
			offset = 13,
			twelvehourclock = true
		},
		{
			abrv = "NZST",
			name = "New Zealand Standard Time",
			offset = 12,
			twelvehourclock = true
		},
		{
			abrv = "CHADT",
			name = "Chatham Island Daylight Time",
			offset = 13.75,
			twelvehourclock = true
		},
		{
			abrv = "CHAST",
			name = "Chatham Island Standard Time",
			offset = 12.75,
			twelvehourclock = true
		},
		{
			abrv = "ARST",
			name = "Arabia Standard Time",
			offset = 3,
			twelvehourclock = true
		}
	}

	table.sort(timezones, function(a, b)
		return a.abrv:lower() < b.abrv:lower()
	end)

	_G.timezones = timezones

	local weekdays = {
		sunday = 1,
		monday = 2,
		tuesday = 3,
		wednesday = 4,
		thursday = 5,
		friday = 6,
		saturday = 7
	}

	local function parseTime(str)
		local h, m = str:match("^(%d%d?):(%d%d)$")
		if not h then
			return nil, "Invalid time format. Use HH:MM (e.g. 8:00 or 08:00)."
		end

		h, m = tonumber(h), tonumber(m)
		if h > 23 or m > 59 then
			return nil, "Invalid time value. Hours must be 0–23 and minutes 0–59."
		end

		return {
			hour = h,
			min = m
		}
	end

	local function intervalParse(input)
		input = input:lower():gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")

		local info = {}

		local num, unit = input:match("every%s+(%d+)%s*(%a+)")
		if num and unit then
			local seconds
			if unit:find("min") then
				seconds = tonumber(num) * 60
			elseif unit:find("hour") then
				seconds = tonumber(num) * 3600
			elseif unit:find("day") then
				seconds = tonumber(num) * 86400
			end
			if seconds then
				info.type = "interval"
				info.seconds = seconds
				return info
			else
				return nil, "Unknown unit after number (expected minutes, hours, or days)."
			end
		end

		local time, tz = input:match("every%s+day%s+at%s+([%d:]+)%s*(%a+)")
		if input:find("every%s+day") then
			if not input:find("at") then
				return nil, "Missing `at` time. Example: `Every day at 12:00 UTC`."
			elseif not time then
				return nil, "Missing or invalid time after `every day at`. Use HH:MM format."
			elseif not tz or tz == "" then
				return nil, "Missing timezone after time (e.g. `UTC`, `CEST`)."
			end
		end

		if time then
			local parsedTime, err = parseTime(time)
			if not parsedTime then
				return nil, err
			end

			for _, timezone in pairs(timezones) do
				if timezone.abrv:upper() == tz:upper() then
					tz = timezone
					break
				end
			end

			if type(tz) ~= "table" then
				return nil, "Invalid timezone provided (" .. tz:upper() .. ")."
			end

			info.type = "daily"
			info.time = parsedTime
			info.tz = tz.abrv:upper()
			return info
		end

		local weekday, atTime, tz2 = input:match("every%s+(%a+)%s+at%s+([%d:]+)%s*(%a*)")
		if weekday and weekdays[weekday] then
			if not atTime then
				return nil, "Missing time after `at`. Example: `Every Monday at 08:00 UTC`."
			end
			if not tz2 or tz2 == "" then
				return nil, "Missing timezone after time (e.g. `UTC`, `CEST`)."
			end

			local parsedTime, err = parseTime(atTime)
			if not parsedTime then
				return nil, err
			end

			for _, timezone in pairs(timezones) do
				if timezone.abrv:upper() == tz2:upper() then
					tz2 = timezone
					break
				end
			end

			if type(tz2) ~= "table" then
				return nil, "Invalid timezone provided (" .. tz2:upper() .. ")."
			end

			info.type = "weekly"
			info.weekday = weekday
			info.time = parsedTime
			info.tz = tz2.abrv:upper()
			return info
		elseif input:match("every%s+(%a+)%s+at") then
			local w = input:match("every%s+(%a+)%s+at")
			if not weekdays[w] then
				return nil, ("Invalid weekday: `%s`. Expected something like `Monday` or `Friday`."):format(w)
			end
		end

		return nil, "Invalid interval format. Example: `Every 2 hours` or `Every Monday at 08:00 UTC`."
	end

	_G.intervalParse = intervalParse

	local function intervalNextRun(info, now)
		now = now or realtime()

		if info.type == "interval" then
			return now + info.seconds
		end

		local date = os.date("!*t", now)
		local tzOffset = 0

		for _, timezone in pairs(timezones) do
			if timezone.abrv:upper() == info.tz:upper() then
				tzOffset = timezone.offset * 3600
				break
			end
		end

		if info.type == "daily" then
			local target = os.time {
				year = date.year,
				month = date.month,
				day = date.day,
				hour = info.time.hour,
				min = info.time.min,
				sec = 0
			} - tzOffset

			if target <= now then
				target = target + 86400
			end
			return target
		end

		if info.type == "weekly" then
			local tzOffset = 0
			for _, timezone in pairs(timezones) do
				if timezone.abrv:upper() == info.tz:upper() then
					tzOffset = timezone.offset * 3600
					break
				end
			end

			local localNow = now + tzOffset
			local localDate = os.date("!*t", localNow)

			local target = os.time {
				year = localDate.year,
				month = localDate.month,
				day = localDate.day,
				hour = info.time.hour,
				min = info.time.min,
				sec = 0
			} - tzOffset

			local targetWday = weekdays[info.weekday]
			local localTargetDate = os.date("!*t", target + tzOffset)
			local daysUntil = (targetWday - localTargetDate.wday) % 7
			if daysUntil == 0 and target <= now then
				daysUntil = 7
			end
			target = target + daysUntil * 86400

			return target
		end

		return nil, "Unsupported interval type"
	end

	_G.intervalNextRun = intervalNextRun

	local function ordinal(n)
		if type(n) ~= "number" then
			return tostring(n)
		end

		local suffix = "th"
		local lastTwo = n % 100
		local lastOne = n % 10

		if lastTwo < 11 or lastTwo > 13 then
			if lastOne == 1 then
				suffix = "st"
			elseif lastOne == 2 then
				suffix = "nd"
			elseif lastOne == 3 then
				suffix = "rd"
			end
		end

		return tostring(n) .. suffix
	end

	_G.ordinal = ordinal

	local function getMembersJoinedWithin(guild, t)
		local ts = os.time() - t

		local members = guild.members

		local within = {}

		for _, v in pairs(members) do
			if math.floor(discordia.Date.fromISO(v.joinedAt):toSeconds()) >= ts then
				table.insert(within, v)
			end
		end

		return within
	end
	_G.getMembersJoinedWithin = getMembersJoinedWithin

	local function dbg(str)
		prettyLog("DEBUG", "yellow", str)
		utilityChannels.development:send(string.truncate(tostring(str), 2000))
	end
	_G.dbg = dbg

	local function generateUUID()
		local f = io.open("/dev/urandom", "rb")
		if not f then
			return nil, "Random source could not be accessed"
		end

		local bytes = f:read(16)
		f:close()
		local b = {
			string.byte(bytes, 1, 16)
		}
		b[7] = bit.bor(bit.band(b[7], 0x0f), 0x40)

		b[9] = bit.bor(bit.band(b[9], 0x3f), 0x80)
		return string.format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x", b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15], b[16])
	end
	_G.generateUUID = generateUUID

	local function container(data)
		local container = {
			type = 17,
			accent_color = data.color,
			spoiler = data.spoiler,
			components = {}
		}

		for _, component in pairs(data.components) do
			if component.text then -- Text Display
				table.insert(container.components, {
					type = 10,
					content = component.text
				})
			elseif component.divider then -- Separator
				table.insert(container.components, {
					type = 14,
					divider = component.divider,
					spacing = component.padding or 1
				})
			elseif component.texts then -- Section
				local section = {
					type = 9,
					components = {}
				}

				for _, text in pairs(component.texts) do
					table.insert(section.components, {
						type = 10,
						content = text
					})
				end

				if component.accessory.raw or component.accessory.style then
					section.accessory = (component.accessory.raw and component.accessory:raw()) or {
						type = 2,
						style = discordia.enums.buttonStyle[component.accessory.style],
						label = component.accessory.label,
						emoji = component.accessory.emoji,
						custom_id = component.accessory.id,
						url = component.accessory.url,
						disabled = component.accessory.disabled
					}
				elseif component.accessory.media then
					section.accessory = {
						type = 11,
						media = {
							url = component.accessory.media
						},
						description = component.accessory.description,
						spoiler = component.accessory.spoiler
					}
				end

				table.insert(container.components, section)
			elseif component.file then -- File
				table.insert(container.components, {
					type = 13,
					spoiler = component.spoiler,
					file = {
						url = component.file
					}
				})
			elseif component.media then -- Media Gallery (Single image)
				table.insert(container.components, {
					type = 12,
					items = {
						{
							media = {
								url = component.media
							}
						}
					}
				})
			elseif component.items then -- Media Gallery
				table.insert(container.components, {
					type = 12,
					items = component.items
				})
			elseif component.raw then -- Action Row
				table.insert(container.components, component:raw()[1])
			end
		end

		return {
			flags = 32768,
			components = {
				container
			}
		}
	end

	_G.container = container

	local function webEditor(author, type, expires, callback, query)
		local code = junkStr(25)

		local session = {
			guild = author.guild.id,
			plus = not not sqldb:plusGuild(author.guild),
			author = author.id,
			type = type,
			created = os.time(),
			expires = expires,
			code = code,
			url = "https://duckybot.xyz/editor/" .. type .. "?session=" .. code .. (query and ("&" .. querystring.stringify(query)) or ""),
			callback = callback
		}
		table.insert(webEditorSessions, session)

		timer.setTimeout((expires - os.time()) * 1000, function()
			for i, s in pairs(webEditorSessions) do
				if s.code == session.code then
					table.remove(webEditorSessions, i)
					break
				end
			end
		end)

		return session
	end

	_G.webEditor = webEditor

	local function signature(guild)
		return discordia.Components():button({
			style = "link",
			url = generateGuildInvite(guild) or "https://duckybot.xyz/404",
			label = "Sent from " .. string.truncate(sanitizeGuildName(guild.name), 30) .. " (" .. guild.id .. ")",
			emoji = resolvedEmojis.send
		}):raw()
	end

	_G.signature = signature

	local DISCORD_EPOCH = 1420070400000
	local function isDiscordSnowflake(id)
		local idStr = tostring(id)
		if #idStr < 17 or #idStr > 19 then return false end
		local n = tonumber(idStr)
		if not n then return false end
		local ms = math.floor(n / 2^22) + DISCORD_EPOCH
		return ms > 1420070400000 and ms < 9999999999999
	end

	_G.isDiscordSnowflake = isDiscordSnowflake

	print("[Ducky] | Loaded utility functions in " .. (os.clock() - startl) .. " seconds.\n")
end

utils.Stop = function()
	-- nothing to stop muahahhahahaha
end

return utils
