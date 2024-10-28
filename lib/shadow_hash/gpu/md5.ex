defmodule ShadowHash.Gpu.Md5 do
  alias ShadowHash.Gpu.Md5core

  @max_password_size 200

  @max_message_size 64 * 4

  @ito_index_lookup {
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
    0,
    0,
    0,
    0,
    0,
    0,
    0,
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
    0,
    0,
    0,
    0,
    0,
    0,
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
    63
  }

  @detranspose_map {12, 6, 0, 13, 7, 1, 14, 8, 2, 15, 9, 3, 5, 10, 4, 11}

  def decode_b64_hash_pair(p) do
    r =
      p
      |> Enum.with_index()
      |> Enum.map(fn {v, i} ->
        Bitwise.bsl(elem(@ito_index_lookup, v - 46), 6 * i)
      end)
      |> Enum.reduce(0, fn e, acc -> Bitwise.bor(e, acc) end)

    [
      r |> Bitwise.band(0xFF),
      r |> Bitwise.bsr(8) |> Bitwise.band(0xFF),
      r |> Bitwise.bsr(16) |> Bitwise.band(0xFF)
    ]
  end

  def decode_b64_hash(h) do
    h
    |> Enum.chunk_every(4)
    |> Enum.map(fn chunk ->
      chunk |> decode_b64_hash_pair
    end)
    |> List.flatten()
    |> Enum.take(16)
    |> Enum.with_index()
    |> Enum.sort(fn {_, i}, {_, i2} ->
      elem(@detranspose_map, i) < elem(@detranspose_map, i2)
    end)
    |> Enum.map(fn {v, _} -> v end)
  end

  defp build_m32b_ending(l, pad_amount) do
    original_length_bits = rem(l * 8, 2 ** 64)

    [0b10000000]
    |> Enum.concat(Stream.duplicate(0x0, pad_amount))
    |> Enum.concat(:binary.bin_to_list(<<original_length_bits::little-64>>))
  end

  def build_m32b(digest) do
    l = length(digest)

    pad_amount =
      case 56 - rem(l + 1, 64) do
        n when n < 0 -> n + 64
        n -> n
      end

    total_effective_len = l + pad_amount + 1 + 8

    alignment_padding = @max_message_size - total_effective_len

    digest
    |> Enum.concat(build_m32b_ending(l, pad_amount))
    |> Enum.concat(Stream.duplicate(0x0, alignment_padding))
    |> Enum.chunk_every(4)
    |> Enum.map(&(:binary.list_to_bin(&1) |> :binary.decode_unsigned(:little)))
    |> (&Enum.concat([div(total_effective_len, 4)], &1)).()
    |> Nx.tensor(type: {:u, 32})
  end

  def encode_messages_old(plaintext) when is_list(plaintext) do
    plaintext
    |> Enum.map(&build_m32b/1)
    |> Nx.stack()
    |> Nx.vectorize(:rows)
  end

  def encode_messages(plaintext) when is_list(plaintext) do
    r =
      plaintext
      |> ShadowHash.Gpu.Strutil.create_set()
      |> ShadowHash.Gpu.Strutil.build_m32b()
  end

  def md5_from_encoded(messages) do
    messages
    |> Md5core.md5()
    |> Nx.devectorize(keep_names: false)
    |> Nx.to_binary()
    |> :binary.bin_to_list()
    |> Enum.chunk_every(16)
    |> Enum.map(&Base.encode16(:binary.list_to_bin(&1)))
  end

  def _internal_md5_from_encoded(messages) do
    messages
    |> Md5core.md5_disect()
    |> Nx.devectorize(keep_names: false)
  end

  def repeatedly(src, count) do
    src = src |> List.to_tuple()

    for i <- 0..(count - 1) do
      elem(src, rem(i, tuple_size(src)))
    end
  end

  def create_a_tail(pwd_len, even_char) do
    """
    calc_len = floor(:math.log(pwd_len) / :math.log(2)) + 1

    old_r =
      Stream.unfold(pwd_len, fn l ->
        case l do
          0 ->
            nil

          n ->
            if rem(n, 2) == 0 do
              {even_char, div(n, 2)}
            else
              {0, div(n, 2)}
            end
        end
      end)

    calc_len = floor(:math.log(pwd_len) / :math.log(2)) + 1

    new_r =
      0..(calc_len - 1)
      |> Enum.map(fn n ->
        pwd_len = div(pwd_len, 2 ** n)
        if rem(pwd_len, 2) == 0 do
          even_char
        else
          0
        end
      end)

    eq =
      new_r
      |> Enum.zip(old_r)
      |> Enum.all?(fn {a, b} -> a == b end)

    if not eq do
      new_r
      |> Enum.zip(old_r)
      |> IO.inspect()

      raise "HMMM"
    end

    new_r
    # IO.puts("AAA")
    # IO.inspect(pwd_len)
    # w
    """

    calc_len = floor(:math.log(pwd_len) / :math.log(2)) + 1
    # Things start breaking when these numbers get too big
    pow_counter = Nx.iota({150}) |> Nx.min(20)
    divisors = Nx.broadcast(Nx.tensor([2]), {150}) |> Nx.pow(pow_counter) |> Nx.as_type({:u, 32})

    tw =
      Nx.broadcast(Nx.tensor([pwd_len]), {150})
      |> Nx.as_type({:u, 32})
      |> Nx.divide(divisors)
      |> Nx.as_type({:u, 32})
      |> Nx.remainder(2)

    t =
      Nx.tensor([1])
      |> Nx.subtract(tw)
      |> Nx.multiply(even_char)
      |> Nx.slice([0], [calc_len])
      |> Nx.to_list()

    r2 =
      0..(calc_len - 1)
      |> Enum.map(fn n ->
        pwd_len = div(pwd_len, 2 ** n)

        if rem(pwd_len, 2) == 0 do
          even_char
        else
          0
        end
      end)

    # r2 |> IO.inspect()
    # t |> IO.inspect()
    # exit(0)

    t
  end

  def create_next_da_old(i, current_da, passwords, salt, compiled_md5_disect) do
    t_da = ShadowHash.Gpu.Strutil.create_set(current_da)
    t_passwords = ShadowHash.Gpu.Strutil.create_set(passwords)
    [t_salt, _] = Nx.broadcast_vectors([ShadowHash.Gpu.Strutil.create(salt), t_passwords])

    msg_a_choice = Nx.remainder(i, 2)
    msg_b_choice = Nx.remainder(i, 3) |> Nx.min(1)
    msg_c_choice = Nx.remainder(i, 7) |> Nx.min(1)
    msg_d_choice = Nx.remainder(i, 2)

    msg =
      Nx.add(
        msg_a_choice |> Nx.multiply(t_passwords),
        1 |> Nx.subtract(msg_a_choice) |> Nx.multiply(t_da)
      )

    msg_b_eval = ShadowHash.Gpu.Strutil.concat(msg, t_salt)

    msg =
      Nx.add(
        msg_b_choice |> Nx.multiply(msg_b_eval),
        1 |> Nx.subtract(msg_b_choice) |> Nx.multiply(msg)
      )

    msg_c_eval = ShadowHash.Gpu.Strutil.concat(msg, t_passwords)

    msg =
      Nx.add(
        msg_c_choice |> Nx.multiply(msg_c_eval),
        1 |> Nx.subtract(msg_c_choice) |> Nx.multiply(msg)
      )

    msg_d_eval_a = ShadowHash.Gpu.Strutil.concat(msg, t_da)
    msg_d_eval_b = ShadowHash.Gpu.Strutil.concat(msg, t_passwords)

    msg =
      Nx.add(
        msg_d_choice |> Nx.multiply(msg_d_eval_a),
        1 |> Nx.subtract(msg_d_choice) |> Nx.multiply(msg_d_eval_b)
      )

    new_plain_output =
      msg
      |> Nx.to_list()
      |> Enum.map(fn r ->
        t = List.first(r)

        r
        |> Enum.drop(1)
        |> Enum.take(t)
      end)

    """
    old_plain_output =
      current_da
      |> Enum.zip(passwords)
      |> Enum.map(fn {da, pwd} ->
        msg =
          if rem(i, 2) == 1 do
            pwd
          else
            da
          end

        msg =
          if rem(i, 3) != 0 do
            Enum.concat(msg, salt)
          else
            msg
          end

        msg =
          if rem(i, 7) != 0 do
            Enum.concat(msg, pwd)
          else
            msg
          end

        if rem(i, 2) == 1 do
          Enum.concat(msg, da)
        else
          Enum.concat(msg, pwd)
        end
      end)

    matches = new_plain_output
    |> Enum.zip(old_plain_output)
    |> Enum.all?(fn {a, b} -> a == b end)

    if not matches do
      old_plain_output |> IO.inspect
      new_plain_output |> IO.inspect
      raise "Error"
    end
    """

    new_plain_output
    |> encode_messages()
    |> compiled_md5_disect.()
    |> Nx.to_list()
  end

  def create_next_da(i, current_da, passwords, salt, compiled_md5_disect) do
    t_da = ShadowHash.Gpu.Strutil.create_set(current_da)
    t_passwords = ShadowHash.Gpu.Strutil.create_set(passwords)
    #[t_salt, _] = Nx.broadcast_vectors([ShadowHash.Gpu.Strutil.create(salt), t_passwords])

    msg = ShadowHash.Gpu.Strutil.create_next_da(i, t_da, t_passwords, ShadowHash.Gpu.Strutil.create(salt))

    msg
    |> Nx.to_list()
    |> Enum.map(fn e -> e |> Enum.drop(1) |> Enum.take(16) end)
    #|> IO.inspect()

  end

  def md5crypt_raw(passwords, salt, compiled_md5_disect) do
    pwd_len = passwords |> Enum.map(&length/1)
    magic = ~c"$1$"

    db =
      passwords
      |> Enum.map(&Enum.concat([&1, salt, &1]))
      |> encode_messages()
      |> compiled_md5_disect.()
      |> Nx.to_list()

    a_message =
      passwords
      |> Enum.zip(pwd_len)
      |> Enum.zip(db)
      |> Enum.map(fn {{pwd, pwd_len}, db} ->
        Enum.concat([
          pwd,
          magic,
          salt,
          repeatedly(db, pwd_len),
          create_a_tail(pwd_len, pwd |> List.first())
        ])
      end)

    da =
      a_message
      |> encode_messages()
      |> compiled_md5_disect.()
      |> Nx.to_list()

    0..999
    |> Enum.reduce(da, fn i, da ->
      IO.puts(i)
      create_next_da(i, da, passwords, salt, compiled_md5_disect)
    end)
  end

  def md5crypt(passwords, salt) do
    compiled = Nx.Defn.jit(&Md5core.md5_disect/1, compiler: EXLA)

    IO.puts("start")

    md5crypt_raw(passwords, salt, compiled)
    # |> Enum.map(&Base.encode16(:binary.list_to_bin(&1)))
  end

  def test_hash() do
    t = [
      ~c"tp"
    ]

    md5crypt(t, ~c"cobKo5Ks")
  end

  def benchmark() do
    p = [
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

    p =
      p
      |> Enum.take(50)

    md5crypt(p, ~c"cobKo5Ks")
  end
end
