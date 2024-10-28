defmodule ShadowHash.Gpu.Constants do
  import Nx.Defn
  @max_str_size 150

  defn counter() do
    Nx.iota({@max_str_size})
  end

  def test_benchmark_passwords() do
    [
      ~c"vengeful",
      ~c"endurable",
      ~c"trap",
      ~c"zealous",
      ~c"plants",
      ~c"growth",
      ~c"nation",
      ~c"shirt",
      ~c"basketball",
      ~c"brainy",
      ~c"same",
      ~c"grade",
      ~c"include",
      ~c"credit",
      ~c"marry",
      ~c"file",
      ~c"sail",
      ~c"door",
      ~c"squeal",
      ~c"squeamish",
      ~c"productive",
      ~c"puffy",
      ~c"boil",
      ~c"employ",
      ~c"reign",
      ~c"five",
      ~c"blushing",
      ~c"measly",
      ~c"receipt",
      ~c"helpless",
      ~c"account",
      ~c"chief",
      ~c"delight",
      ~c"women",
      ~c"weight",
      ~c"sparkle",
      ~c"minor",
      ~c"scintillating",
      ~c"tall",
      ~c"keen",
      ~c"tie",
      ~c"skin",
      ~c"waggish",
      ~c"thoughtless",
      ~c"art",
      ~c"panicky",
      ~c"loud",
      ~c"lowly",
      ~c"punishment",
      ~c"deafening",
      ~c"celery",
      ~c"paint",
      ~c"sordid",
      ~c"retire",
      ~c"festive",
      ~c"unruly",
      ~c"busy",
      ~c"normal",
      ~c"healthy",
      ~c"exuberant",
      ~c"concerned",
      ~c"foamy",
      ~c"bell",
      ~c"income",
      ~c"claim",
      ~c"fold",
      ~c"glorious",
      ~c"useful",
      ~c"odd",
      ~c"plucky",
      ~c"exotic",
      ~c"vigorous",
      ~c"doll",
      ~c"real",
      ~c"steam",
      ~c"cumbersome",
      ~c"pray",
      ~c"jittery",
      ~c"simplistic",
      ~c"pretty",
      ~c"rose",
      ~c"quack",
      ~c"gray",
      ~c"old",
      ~c"scared",
      ~c"bike",
      ~c"silent",
      ~c"degree",
      ~c"calendar",
      ~c"whip",
      ~c"cobweb",
      ~c"hideous",
      ~c"unite",
      ~c"regret",
      ~c"wasteful",
      ~c"beef",
      ~c"payment",
      ~c"superficial",
      ~c"heal",
      ~c"miscreant",
      ~c"eager",
      ~c"jewel",
      ~c"magenta",
      ~c"stocking",
      ~c"object",
      ~c"rampant",
      ~c"dirt",
      ~c"absorbing",
      ~c"carve",
      ~c"suffer",
      ~c"uptight",
      ~c"lick",
      ~c"holistic",
      ~c"statuesque",
      ~c"appreciate",
      ~c"striped",
      ~c"office",
      ~c"scandalous",
      ~c"ray",
      ~c"encouraging",
      ~c"machine",
      ~c"fluttering",
      ~c"heap",
      ~c"fasten",
      ~c"meek",
      ~c"butter",
      ~c"wing",
      ~c"crush",
      ~c"smash",
      ~c"turn",
      ~c"first",
      ~c"arch",
      ~c"fairies",
      ~c"elated",
      ~c"wire",
      ~c"wicked",
      ~c"cooperative",
      ~c"harmony",
      ~c"print",
      ~c"stone",
      ~c"hour",
      ~c"scribble",
      ~c"chew",
      ~c"summer",
      ~c"best",
      ~c"hospital",
      ~c"standing",
      ~c"float",
      ~c"toys",
      ~c"remarkable",
      ~c"nonstop",
      ~c"juicy",
      ~c"ball",
      ~c"finicky",
      ~c"screw",
      ~c"cars",
      ~c"needle",
      ~c"fog",
      ~c"discovery",
      ~c"guarantee",
      ~c"quill",
      ~c"idea",
      ~c"develop",
      ~c"ubiquitous",
      ~c"rotten",
      ~c"spell",
      ~c"drawer",
      ~c"complete",
      ~c"form",
      ~c"fly",
      ~c"plot",
      ~c"exchange",
      ~c"shade",
      ~c"youthful",
      ~c"bounce",
      ~c"tart",
      ~c"haircut",
      ~c"license",
      ~c"nail",
      ~c"hose",
      ~c"educated",
      ~c"berry",
      ~c"crack",
      ~c"tiny",
      ~c"houses",
      ~c"quicksand",
      ~c"waves",
      ~c"start",
      ~c"call",
      ~c"dispensable",
      ~c"alarm",
      ~c"tick",
      ~c"wrap",
      ~c"tired",
      ~c"trace",
      ~c"eatable",
      ~c"group",
      ~c"safe",
      ~c"jolly",
      ~c"multiply",
      ~c"screeching",
      ~c"dead",
      ~c"zephyr",
      ~c"arrive",
      ~c"pack",
      ~c"medical",
      ~c"sneeze",
      ~c"ready",
      ~c"vase",
      ~c"ashamed",
      ~c"zoo",
      ~c"possessive",
      ~c"spicy",
      ~c"thankful",
      ~c"better",
      ~c"chubby",
      ~c"press",
      ~c"self",
      ~c"feeling",
      ~c"pleasure",
      ~c"amuse",
      ~c"blue",
      ~c"filthy",
      ~c"injure",
      ~c"frogs",
      ~c"permissible",
      ~c"animal",
      ~c"land",
      ~c"instinctive",
      ~c"pancake",
      ~c"sleet",
      ~c"depressed",
      ~c"callous",
      ~c"soft",
      ~c"aberrant",
      ~c"naive",
      ~c"picayune",
      ~c"hospitable",
      ~c"worm",
      ~c"welcome",
      ~c"profuse",
      ~c"tempt",
      ~c"team",
      ~c"acceptable",
      ~c"peep",
      ~c"library",
      ~c"frantic",
      ~c"drag",
      ~c"color",
      ~c"water",
      ~c"tame",
      ~c"breezy",
      ~c"offend",
      ~c"empty",
      ~c"motionless",
      ~c"apparel",
      ~c"soup",
      ~c"money",
      ~c"gabby",
      ~c"common",
      ~c"calculator",
      ~c"silky",
      ~c"utter",
      ~c"pointless",
      ~c"staking",
      ~c"attempt",
      ~c"sink",
      ~c"strange",
      ~c"shave",
      ~c"sedate",
      ~c"hurt",
      ~c"camp",
      ~c"stove",
      ~c"suppose",
      ~c"godly",
      ~c"curtain",
      ~c"elegant",
      ~c"cheese",
      ~c"hope",
      ~c"wiry",
      ~c"grandmother",
      ~c"abstracted",
      ~c"simple",
      ~c"head",
      ~c"suggestion",
      ~c"wealth",
      ~c"inquisitive",
      ~c"harsh",
      ~c"robin",
      ~c"known",
      ~c"expansion",
      ~c"legs",
      ~c"quartz",
      ~c"sloppy",
      ~c"disappear",
      ~c"cook",
      ~c"courageous",
      ~c"cure",
      ~c"string",
      ~c"activity",
      ~c"man",
      ~c"laborer",
      ~c"development",
      ~c"release",
      ~c"yoke",
      ~c"protest",
      ~c"pig",
      ~c"request",
      ~c"heady",
      ~c"guarded",
      ~c"profit",
      ~c"carriage",
      ~c"towering",
      ~c"ambiguous",
      ~c"rod",
      ~c"draconian",
      ~c"deer",
      ~c"arm",
      ~c"stretch",
      ~c"peaceful",
      ~c"like",
      ~c"chilly",
      ~c"school",
      ~c"change",
      ~c"listen",
      ~c"hot",
      ~c"vagabond",
      ~c"statement",
      ~c"bright",
      ~c"grey",
      ~c"oranges",
      ~c"heavy",
      ~c"scarf",
      ~c"dogs",
      ~c"cracker",
      ~c"acidic",
      ~c"belligerent",
      ~c"smart",
      ~c"cowardly",
      ~c"whispering",
      ~c"one",
      ~c"poke",
      ~c"ajar",
      ~c"plate",
      ~c"concentrate",
      ~c"well",
      ~c"pets",
      ~c"value",
      ~c"abrasive",
      ~c"middle",
      ~c"type",
      ~c"limit",
      ~c"trade",
      ~c"risk",
      ~c"rings",
      ~c"truck",
      ~c"sofa",
      ~c"lip",
      ~c"war",
      ~c"hammer",
      ~c"attract",
      ~c"precede",
      ~c"ragged",
      ~c"open",
      ~c"suspect",
      ~c"wet",
      ~c"hypnotic",
      ~c"doubtful",
      ~c"air",
      ~c"puncture",
      ~c"judicious",
      ~c"opposite",
      ~c"lake",
      ~c"big",
      ~c"romantic",
      ~c"animated",
      ~c"long",
      ~c"rustic",
      ~c"testy",
      ~c"jog",
      ~c"married",
      ~c"versed",
      ~c"bee",
      ~c"efficacious",
      ~c"distinct",
      ~c"desire",
      ~c"oatmeal",
      ~c"sky",
      ~c"grab",
      ~c"special",
      ~c"shrug",
      ~c"interesting",
      ~c"nonchalant",
      ~c"jaded",
      ~c"ludicrous",
      ~c"warlike",
      ~c"camera",
      ~c"magic",
      ~c"boy",
      ~c"friendly",
      ~c"shiver",
      ~c"appear",
      ~c"mist",
      ~c"morning",
      ~c"aromatic",
      ~c"copper",
      ~c"applaud",
      ~c"funny",
      ~c"subsequent",
      ~c"grotesque",
      ~c"peel",
      ~c"handle",
      ~c"six",
      ~c"thundering",
      ~c"many",
      ~c"detailed",
      ~c"frog",
      ~c"yak",
      ~c"sip",
      ~c"pigs",
      ~c"hat",
      ~c"seashore",
      ~c"communicate",
      ~c"brown",
      ~c"destruction",
      ~c"chin",
      ~c"ocean",
      ~c"snobbish",
      ~c"selfish",
      ~c"ahead",
      ~c"useless",
      ~c"gullible",
      ~c"correct",
      ~c"succeed",
      ~c"effect",
      ~c"birthday",
      ~c"clam",
      ~c"enter",
      ~c"purple",
      ~c"transport",
      ~c"bustling",
      ~c"redundant",
      ~c"mammoth",
      ~c"film",
      ~c"round",
      ~c"blush",
      ~c"soothe",
      ~c"cultured",
      ~c"elderly",
      ~c"unkempt",
      ~c"sun",
      ~c"terrible",
      ~c"spotty",
      ~c"ugly",
      ~c"addicted",
      ~c"painstaking",
      ~c"achiever",
      ~c"gather",
      ~c"story",
      ~c"energetic",
      ~c"north",
      ~c"dog",
      ~c"sable",
      ~c"sense",
      ~c"analyze",
      ~c"modern",
      ~c"loutish",
      ~c"station",
      ~c"mailbox",
      ~c"unequaled",
      ~c"delightful",
      ~c"ruddy",
      ~c"excellent",
      ~c"wax",
      ~c"prickly",
      ~c"materialistic",
      ~c"hushed",
      ~c"thumb",
      ~c"wandering",
      ~c"wool",
      ~c"bolt",
      ~c"familiar",
      ~c"therapeutic",
      ~c"plantation",
      ~c"pushy",
      ~c"selective",
      ~c"shop",
      ~c"faithful",
      ~c"crib",
      ~c"theory",
      ~c"charge",
      ~c"poor",
      ~c"difficult",
      ~c"wakeful",
      ~c"cold",
      ~c"shoe",
      ~c"room",
      ~c"measure",
      ~c"cactus",
      ~c"donkey",
      ~c"boiling",
      ~c"invite",
      ~c"government",
      ~c"woozy",
      ~c"badge",
      ~c"sticks",
      ~c"record",
      ~c"delicious",
      ~c"labored",
      ~c"voice",
      ~c"hellish",
      ~c"calculate",
      ~c"surprise",
      ~c"consider",
      ~c"incompetent",
      ~c"pathetic",
      ~c"table",
      ~c"sigh",
      ~c"terrific",
      ~c"gusty",
      ~c"identify",
      ~c"puzzling",
      ~c"tramp",
      ~c"recondite",
      ~c"sleepy",
      ~c"comfortable",
      ~c"spiffy",
      ~c"sparkling",
      ~c"tent",
      ~c"ambitious",
      ~c"owe",
      ~c"deceive",
      ~c"vessel",
      ~c"chunky",
      ~c"tiger",
      ~c"tow",
      ~c"harmonious",
      ~c"holiday",
      ~c"approval",
      ~c"eight",
      ~c"permit",
      ~c"political",
      ~c"three",
      ~c"bump",
      ~c"reason",
      ~c"doctor",
      ~c"leather",
      ~c"yummy",
      ~c"furry",
      ~c"flap",
      ~c"bouncy",
      ~c"crate",
      ~c"obscene",
      ~c"rare",
      ~c"blot",
      ~c"exercise",
      ~c"ice",
      ~c"fact",
      ~c"allow",
      ~c"plausible",
      ~c"military",
      ~c"efficient",
      ~c"try",
      ~c"meddle",
      ~c"friend",
      ~c"treatment",
      ~c"choke",
      ~c"wrist",
      ~c"birds",
      ~c"woebegone",
      ~c"friction",
      ~c"capricious",
      ~c"tax",
      ~c"detail",
      ~c"accurate",
      ~c"damp",
      ~c"white",
      ~c"ceaseless",
      ~c"paper",
      ~c"jumbled",
      ~c"regular",
      ~c"sleep",
      ~c"tidy",
      ~c"island",
      ~c"adhesive",
      ~c"travel",
      ~c"matter",
      ~c"finger",
      ~c"troubled",
      ~c"adaptable",
      ~c"axiomatic",
      ~c"business",
      ~c"kaput",
      ~c"waste",
      ~c"overconfident",
      ~c"explain",
      ~c"visitor",
      ~c"punch",
      ~c"long",
      ~c"guess",
      ~c"skinny",
      ~c"steer",
      ~c"quizzical",
      ~c"creature",
      ~c"psychedelic",
      ~c"mellow",
      ~c"shock",
      ~c"sharp",
      ~c"cruel",
      ~c"meeting",
      ~c"porter",
      ~c"mix",
      ~c"spotless",
      ~c"disastrous",
      ~c"chicken",
      ~c"behave",
      ~c"stale",
      ~c"potato",
      ~c"obeisant",
      ~c"history",
      ~c"unused",
      ~c"store",
      ~c"snails",
      ~c"rescue",
      ~c"jelly",
      ~c"night",
      ~c"elfin",
      ~c"boot",
      ~c"vulgar",
      ~c"careless",
      ~c"snake",
      ~c"fallacious",
      ~c"piquant",
      ~c"dramatic",
      ~c"drip",
      ~c"juvenile",
      ~c"quiver",
      ~c"distribution",
      ~c"glamorous",
      ~c"angry",
      ~c"pink",
      ~c"settle",
      ~c"freezing",
      ~c"tawdry",
      ~c"gold",
      ~c"signal",
      ~c"perform",
      ~c"pipe",
      ~c"wall",
      ~c"mountain",
      ~c"sick",
      ~c"sturdy",
      ~c"thinkable",
      ~c"oval",
      ~c"bait",
      ~c"zebra",
      ~c"tenuous",
      ~c"momentous",
      ~c"industry",
      ~c"kind",
      ~c"church",
      ~c"count",
      ~c"arrogant",
      ~c"song",
      ~c"help",
      ~c"faulty",
      ~c"spray",
      ~c"brawny",
      ~c"rat",
      ~c"thoughtful",
      ~c"train",
      ~c"illustrious",
      ~c"slimy",
      ~c"competition",
      ~c"beam",
      ~c"sin",
      ~c"acrid",
      ~c"field",
      ~c"aspiring",
      ~c"recognise",
      ~c"maddening",
      ~c"cool",
      ~c"rightful",
      ~c"wash",
      ~c"longing",
      ~c"reduce",
      ~c"rain",
      ~c"cycle",
      ~c"yam",
      ~c"milk",
      ~c"girl",
      ~c"fear",
      ~c"blow",
      ~c"spiritual",
      ~c"hapless",
      ~c"half",
      ~c"second",
      ~c"letter",
      ~c"delicate",
      ~c"side",
      ~c"polish",
      ~c"calm",
      ~c"lazy",
      ~c"lethal",
      ~c"seemly",
      ~c"pat",
      ~c"bird",
      ~c"leg",
      ~c"sock",
      ~c"greedy",
      ~c"brick",
      ~c"humorous",
      ~c"grass",
      ~c"vanish",
      ~c"smoke",
      ~c"road",
      ~c"confess",
      ~c"savory",
      ~c"work",
      ~c"scatter",
      ~c"whisper",
      ~c"enthusiastic",
      ~c"pale",
      ~c"delirious",
      ~c"glue",
      ~c"penitent",
      ~c"loose",
      ~c"vein",
      ~c"flower",
      ~c"hallowed",
      ~c"determined",
      ~c"gun",
      ~c"fantastic",
      ~c"radiate",
      ~c"exultant",
      ~c"rhythm",
      ~c"title",
      ~c"attractive",
      ~c"public",
      ~c"alleged",
      ~c"tough",
      ~c"wooden",
      ~c"overt",
      ~c"tumble",
      ~c"garrulous",
      ~c"exclusive",
      ~c"tomatoes",
      ~c"tendency",
      ~c"shoes",
      ~c"program",
      ~c"absent",
      ~c"pollution",
      ~c"abrupt",
      ~c"agreeable",
      ~c"incredible",
      ~c"tip",
      ~c"thrill",
      ~c"march",
      ~c"scarce",
      ~c"icy",
      ~c"stew",
      ~c"knock",
      ~c"rude",
      ~c"adjustment",
      ~c"complex",
      ~c"thaw",
      ~c"giraffe",
      ~c"frame",
      ~c"sidewalk",
      ~c"stupid",
      ~c"territory",
      ~c"stupendous",
      ~c"halting",
      ~c"smile",
      ~c"vague",
      ~c"tasteless",
      ~c"accidental",
      ~c"cute",
      ~c"verse",
      ~c"flavor",
      ~c"fail",
      ~c"unable",
      ~c"shake",
      ~c"debonair",
      ~c"add",
      ~c"flock",
      ~c"abashed",
      ~c"grubby",
      ~c"peck",
      ~c"carpenter",
      ~c"position",
      ~c"floor",
      ~c"learned",
      ~c"guard",
      ~c"itch",
      ~c"melt",
      ~c"fanatical",
      ~c"small",
      ~c"coordinated",
      ~c"powder",
      ~c"crowded",
      ~c"fish",
      ~c"swim",
      ~c"weak",
      ~c"pies",
      ~c"moldy",
      ~c"lettuce",
      ~c"pet",
      ~c"mug",
      ~c"relax",
      ~c"spooky",
      ~c"delay",
      ~c"jumpy",
      ~c"cynical",
      ~c"trip",
      ~c"notebook",
      ~c"furniture",
      ~c"somber",
      ~c"extra",
      ~c"horrible",
      ~c"obnoxious",
      ~c"swift",
      ~c"cut",
      ~c"wind",
      ~c"accessible",
      ~c"discreet",
      ~c"experience",
      ~c"ruin",
      ~c"macabre",
      ~c"pleasant",
      ~c"bead",
      ~c"crowd",
      ~c"trick",
      ~c"ticket",
      ~c"coach",
      ~c"branch",
      ~c"violet",
      ~c"decide",
      ~c"ugliest",
      ~c"inform",
      ~c"wine",
      ~c"hateful",
      ~c"wave",
      ~c"strip",
      ~c"eye",
      ~c"scream",
      ~c"foregoing",
      ~c"phone",
      ~c"nippy",
      ~c"thirsty",
      ~c"pear",
      ~c"example",
      ~c"didactic",
      ~c"robust",
      ~c"argument",
      ~c"clean",
      ~c"horn",
      ~c"dapper",
      ~c"skirt",
      ~c"gorgeous",
      ~c"mitten",
      ~c"nest",
      ~c"thought",
      ~c"stormy",
      ~c"giants",
      ~c"hook",
      ~c"happy",
      ~c"violent",
      ~c"kneel",
      ~c"ill",
      ~c"hobbies",
      ~c"slope",
      ~c"copy",
      ~c"list",
      ~c"fortunate",
      ~c"premium",
      ~c"poison",
      ~c"happen",
      ~c"building",
      ~c"ten",
      ~c"sudden",
      ~c"discussion",
      ~c"aboriginal",
      ~c"snow",
      ~c"watch",
      ~c"pin",
      ~c"snail",
      ~c"ducks",
      ~c"habitual",
      ~c"plain",
      ~c"spark",
      ~c"strap",
      ~c"dance",
      ~c"reading",
      ~c"unique",
      ~c"stir",
      ~c"star",
      ~c"available",
      ~c"lyrical",
      ~c"inexpensive",
      ~c"secretive",
      ~c"tight",
      ~c"teeny",
      ~c"attach",
      ~c"miss",
      ~c"alike",
      ~c"expert",
      ~c"frightening",
      ~c"fall",
      ~c"workable",
      ~c"amused",
      ~c"purpose",
      ~c"sugar",
      ~c"babies",
      ~c"rambunctious",
      ~c"unit",
      ~c"unusual",
      ~c"shrill",
      ~c"fixed",
      ~c"texture",
      ~c"optimal",
      ~c"tank",
      ~c"remind",
      ~c"wobble",
      ~c"zany",
      ~c"rural",
      ~c"lumber",
      ~c"adjoining",
      ~c"short",
      ~c"knowledgeable",
      ~c"glistening",
      ~c"sad",
      ~c"books",
      ~c"agreement",
      ~c"trot",
      ~c"synonymous",
      ~c"brief",
      ~c"aboard",
      ~c"electric",
      ~c"obsequious",
      ~c"surround",
      ~c"inject",
      ~c"cave",
      ~c"pump",
      ~c"save",
      ~c"push",
      ~c"alcoholic",
      ~c"greet",
      ~c"channel",
      ~c"dinner",
      ~c"market",
      ~c"gentle",
      ~c"marble",
      ~c"boorish",
      ~c"able",
      ~c"annoy",
      ~c"silk",
      ~c"escape",
      ~c"tacit",
      ~c"teeth",
      ~c"intelligent",
      ~c"third",
      ~c"amuck",
      ~c"squeeze",
      ~c"knotty",
      ~c"creepy",
      ~c"prick",
      ~c"reflect",
      ~c"belong",
      ~c"overjoyed",
      ~c"influence",
      ~c"stimulating",
      ~c"righteous",
      ~c"excited",
      ~c"slow",
      ~c"confuse",
      ~c"rot",
      ~c"zippy",
      ~c"melted",
      ~c"heartbreaking",
      ~c"grandiose",
      ~c"frail",
      ~c"clear",
      ~c"afford",
      ~c"abhorrent",
      ~c"egg",
      ~c"tin",
      ~c"caption",
      ~c"cover",
      ~c"aback",
      ~c"second",
      ~c"tooth",
      ~c"painful",
      ~c"lively",
      ~c"coal",
      ~c"condition",
      ~c"rob",
      ~c"gamy",
      ~c"park",
      ~c"zip"
    ]
  end

  defn zero() do
    Nx.tensor(
      [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
      ],
      type: {:u, 8}
    )
  end

  defn str_magic() do
    Nx.tensor(
      [
        3,
        ?$,
        ?1,
        ?$,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
      ],
      type: {:u, 8}
    )
  end

  defn shift_left_t() do
    Nx.tensor(
      [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        35,
        36,
        37,
        38,
        39,
        40,
        41,
        42,
        43,
        44,
        45,
        46,
        47,
        48,
        49,
        50,
        51,
        52,
        53,
        54,
        55,
        56,
        57,
        58,
        59,
        60,
        61,
        62,
        63,
        64,
        65,
        66,
        67,
        68,
        69,
        70,
        71,
        72,
        73,
        74,
        75,
        76,
        77,
        78,
        79,
        80,
        81,
        82,
        83,
        84,
        85,
        86,
        87,
        88,
        89,
        90,
        91,
        92,
        93,
        94,
        95,
        96,
        97,
        98,
        99,
        100,
        101,
        102,
        103,
        104,
        105,
        106,
        107,
        108,
        109,
        110,
        111,
        112,
        113,
        114,
        115,
        116,
        117,
        118,
        119,
        120,
        121,
        122,
        123,
        124,
        125,
        126,
        127,
        128,
        129,
        130,
        131,
        132,
        133,
        134,
        135,
        136,
        137,
        138,
        139,
        140,
        141,
        142,
        143,
        144,
        145,
        146,
        147,
        148,
        149,
        0
      ],
      type: {:u, 8}
    )
  end

  defn shift_right_t() do
    Nx.tensor(
      [
        149,
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        35,
        36,
        37,
        38,
        39,
        40,
        41,
        42,
        43,
        44,
        45,
        46,
        47,
        48,
        49,
        50,
        51,
        52,
        53,
        54,
        55,
        56,
        57,
        58,
        59,
        60,
        61,
        62,
        63,
        64,
        65,
        66,
        67,
        68,
        69,
        70,
        71,
        72,
        73,
        74,
        75,
        76,
        77,
        78,
        79,
        80,
        81,
        82,
        83,
        84,
        85,
        86,
        87,
        88,
        89,
        90,
        91,
        92,
        93,
        94,
        95,
        96,
        97,
        98,
        99,
        100,
        101,
        102,
        103,
        104,
        105,
        106,
        107,
        108,
        109,
        110,
        111,
        112,
        113,
        114,
        115,
        116,
        117,
        118,
        119,
        120,
        121,
        122,
        123,
        124,
        125,
        126,
        127,
        128,
        129,
        130,
        131,
        132,
        133,
        134,
        135,
        136,
        137,
        138,
        139,
        140,
        141,
        142,
        143,
        144,
        145,
        146,
        147,
        148
      ],
      type: {:u, 8}
    )
  end

  defn shift_right_pin_head_t() do
    Nx.tensor(
      [
        0,
        149,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        35,
        36,
        37,
        38,
        39,
        40,
        41,
        42,
        43,
        44,
        45,
        46,
        47,
        48,
        49,
        50,
        51,
        52,
        53,
        54,
        55,
        56,
        57,
        58,
        59,
        60,
        61,
        62,
        63,
        64,
        65,
        66,
        67,
        68,
        69,
        70,
        71,
        72,
        73,
        74,
        75,
        76,
        77,
        78,
        79,
        80,
        81,
        82,
        83,
        84,
        85,
        86,
        87,
        88,
        89,
        90,
        91,
        92,
        93,
        94,
        95,
        96,
        97,
        98,
        99,
        100,
        101,
        102,
        103,
        104,
        105,
        106,
        107,
        108,
        109,
        110,
        111,
        112,
        113,
        114,
        115,
        116,
        117,
        118,
        119,
        120,
        121,
        122,
        123,
        124,
        125,
        126,
        127,
        128,
        129,
        130,
        131,
        132,
        133,
        134,
        135,
        136,
        137,
        138,
        139,
        140,
        141,
        142,
        143,
        144,
        145,
        146,
        147,
        148
      ],
      type: {:u, 8}
    )
  end

  defn message_aggregate_shift_pattern() do
    Nx.tensor([
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216,
      1,
      256,
      65536,
      16_777_216
    ])
  end

  defn message_m32b_padding() do
    Nx.tensor(
      [
        0b10000000,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
      ],
      type: {:u, 8}
    )
  end

  defn shift_right_message_64 do
    Nx.tensor(
      [
        255,
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        19,
        20,
        21,
        22,
        23,
        24,
        25,
        26,
        27,
        28,
        29,
        30,
        31,
        32,
        33,
        34,
        35,
        36,
        37,
        38,
        39,
        40,
        41,
        42,
        43,
        44,
        45,
        46,
        47,
        48,
        49,
        50,
        51,
        52,
        53,
        54,
        55,
        56,
        57,
        58,
        59,
        60,
        61,
        62,
        63,
        64,
        65,
        66,
        67,
        68,
        69,
        70,
        71,
        72,
        73,
        74,
        75,
        76,
        77,
        78,
        79,
        80,
        81,
        82,
        83,
        84,
        85,
        86,
        87,
        88,
        89,
        90,
        91,
        92,
        93,
        94,
        95,
        96,
        97,
        98,
        99,
        100,
        101,
        102,
        103,
        104,
        105,
        106,
        107,
        108,
        109,
        110,
        111,
        112,
        113,
        114,
        115,
        116,
        117,
        118,
        119,
        120,
        121,
        122,
        123,
        124,
        125,
        126,
        127,
        128,
        129,
        130,
        131,
        132,
        133,
        134,
        135,
        136,
        137,
        138,
        139,
        140,
        141,
        142,
        143,
        144,
        145,
        146,
        147,
        148,
        149,
        150,
        151,
        152,
        153,
        154,
        155,
        156,
        157,
        158,
        159,
        160,
        161,
        162,
        163,
        164,
        165,
        166,
        167,
        168,
        169,
        170,
        171,
        172,
        173,
        174,
        175,
        176,
        177,
        178,
        179,
        180,
        181,
        182,
        183,
        184,
        185,
        186,
        187,
        188,
        189,
        190,
        191,
        192,
        193,
        194,
        195,
        196,
        197,
        198,
        199,
        200,
        201,
        202,
        203,
        204,
        205,
        206,
        207,
        208,
        209,
        210,
        211,
        212,
        213,
        214,
        215,
        216,
        217,
        218,
        219,
        220,
        221,
        222,
        223,
        224,
        225,
        226,
        227,
        228,
        229,
        230,
        231,
        232,
        233,
        234,
        235,
        236,
        237,
        238,
        239,
        240,
        241,
        242,
        243,
        244,
        245,
        246,
        247,
        248,
        249,
        250,
        251,
        252,
        253,
        254
      ],
      type: {:u, 8}
    )
  end
end
