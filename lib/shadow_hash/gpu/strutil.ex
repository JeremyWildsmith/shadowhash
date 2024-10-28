defmodule ShadowHash.Gpu.Strutil do
  import Nx.Defn
  import ShadowHash.Gpu.Constants

  @max_str_size 150
  @max_message_size_bytes 64 * 4
  @max_message_size_dword 64

  def create_set(names) when is_list(names) do
    names
    |> Enum.map(fn n ->
      # zero_tensor()
      l = length(n)
      padding = @max_str_size - l - 1

      Enum.concat([length(n)], n)
      |> Nx.tensor(type: {:u, 8})
      |> Nx.pad(0, [{0, padding, 0}])
    end)
    |> Nx.stack()
    |> Nx.vectorize(:rows)
  end

  def create(name) do
    Nx.devectorize(create_set([name]))[0]
  end

  defn create_password_map(source, threshold) do
    max_password_length =
      source[0]
      |> Nx.devectorize(keep_names: false)
      |> Nx.reduce_max()

    [working, _] = Nx.broadcast_vectors([zero(), source])

    working = working |> Nx.as_type({:s, 32})

    {_, _, _, working} =
      while {x = 0, threshold, max_password_length, working}, Nx.less(x, max_password_length) do
        working =
          working
          |> Nx.indexed_put(
            Nx.reshape(x, {1}),
            threshold |> Nx.subtract(x)
          )

        {x + 1, threshold, max_password_length, working}
      end

    working |> Nx.max(0) |> Nx.min(1)
  end

  defn create_simple_map(threshold) do
    max_password_length =
      threshold
      |> Nx.devectorize(keep_names: false)
      |> Nx.reduce_max()

    [working, _] = Nx.broadcast_vectors([zero(), threshold])

    working = working |> Nx.as_type({:s, 32})

    {_, _, _, working} =
      while {x = 0, threshold, max_password_length, working}, Nx.less(x, max_password_length) do
        working =
          working
          |> Nx.indexed_put(
            Nx.reshape(x, {1}),
            threshold |> Nx.subtract(x)
          )

        {x + 1, threshold, max_password_length, working}
      end

    working |> Nx.max(0) |> Nx.min(1)
  end

  defn repeatedly(source, count) do
    [counter, _] = Nx.broadcast_vectors([counter(), source])

    m = create_password_map(source, count)
    zero = Nx.tensor([1]) |> Nx.subtract(m) |> Nx.multiply(@max_str_size - 1)

    index =
      counter
      |> Nx.remainder(source[0])
      |> Nx.add(1)
      |> Nx.multiply(m)
      |> Nx.add(zero)
      |> Nx.slice([0], [@max_str_size - 1])

    Nx.concatenate([count, Nx.take(source, index)])
  end

  defn unwrap_string_to_message(s) do
    Nx.slice(s, [1], [@max_str_size - 1])
    |> Nx.pad(0, [{0, @max_message_size_bytes - @max_str_size + 1, 0}])
  end

  defn(shift_tensor_right(t, a), do: shift_tensor(t, a, shift_right_t()))

  defn(shift_tensor_right_pin_head(t, a), do: shift_tensor(t, a, shift_right_pin_head_t()))

  defn(shift_tensor_left(t, a), do: shift_tensor(t, a, shift_left_t()))

  defn shift_tensor(t, a, mapping) do
    [shift_tensor, _] = Nx.broadcast_vectors([mapping, a])

    m32_shape =
      a
      |> Nx.devectorize(keep_names: false)
      |> Nx.reduce_max()

    {_, _, _, _, r} =
      while {x = 0, shift_tensor, m32_shape, a, t}, Nx.less(x, m32_shape) do
        choice_factor = Nx.min(1, Nx.max(0, Nx.subtract(a, x)))

        t =
          Nx.add(
            Nx.multiply(Nx.take(t, shift_tensor), choice_factor),
            Nx.multiply(t, 1 - choice_factor)
          )
          |> Nx.as_type({:u, 8})

        {x + 1, shift_tensor, m32_shape, a, t}
      end

    r
  end

  # Todo: eliminate code duplication
  # defn shift_message_tensor(t, a, mapping) do
  #  [shift_tensor, _] = Nx.broadcast_vectors([mapping, a])
  #
  #  m32_shape =
  #    a
  #    |> Nx.devectorize(keep_names: false)
  #    |> Nx.reduce_max()
  #
  #  {_, _, _, _, r} =
  #    while {x = 0, shift_tensor, m32_shape, a, t}, Nx.less(x, m32_shape) do
  #      choice_factor = Nx.min(1, Nx.max(0, Nx.subtract(a, x)))
  #
  #      t =
  #        Nx.add(
  #          Nx.multiply(Nx.take(t, shift_tensor), choice_factor),
  #          Nx.multiply(t, 1 - choice_factor)
  #        )
  #        |> Nx.as_type({:u, 32})
  #
  #      {x + 1, shift_tensor, m32_shape, a, t}
  #    end
  #
  #  r
  # end

  defn concat(a, b) do
    a_len = a[0]

    b
    |> Nx.as_type({:u, 8})
    |> Nx.take(right_shift_vectors()[a_len])
    |> Nx.add(a)
  end

  defn concat_length(a) do
    a_len = a[0]

    total_len =
      a_len
      |> Nx.add(1)

    Nx.concatenate([Nx.tensor([1]), a_len])
    |> Nx.pad(0, [{0, @max_str_size - 2, 0}])
    |> Nx.as_type({:u, 8})
    |> shift_tensor_right_pin_head(a_len)
    |> Nx.add(a)
  end

  defn pack_as_dwords(message) do
    shifted_message =
      message
      |> Nx.as_type({:u, 32})
      |> Nx.multiply(message_aggregate_shift_pattern())

    l0 = Nx.slice(Nx.tensor(shifted_message), [0], [@max_message_size_bytes], strides: [4])
    l1 = Nx.slice(Nx.tensor(shifted_message), [1], [@max_message_size_bytes - 1], strides: [4])
    l2 = Nx.slice(Nx.tensor(shifted_message), [2], [@max_message_size_bytes - 2], strides: [4])
    l3 = Nx.slice(Nx.tensor(shifted_message), [3], [@max_message_size_bytes - 3], strides: [4])

    l0
    |> Nx.add(l1)
    |> Nx.add(l2)
    |> Nx.add(l3)
    |> Nx.as_type({:u, 32})
  end

  defn build_m32b_slow(digest) do
    str_len = digest[0] |> Nx.as_type({:u, 32})

    pad_amount =
      Nx.tensor([56])
      |> Nx.subtract(Nx.remainder(Nx.add(str_len, 1), 64))
      |> Nx.add(64)
      |> Nx.remainder(64)

    total_effective_len =
      str_len
      |> Nx.add(pad_amount)
      |> Nx.add(1 + 8)
      |> Nx.divide(4)
      |> Nx.as_type({:u, 32})

    original_length_bits = Nx.multiply(str_len, 8)

    shift_amount = str_len |> Nx.add(pad_amount) |> Nx.add(1) |> Nx.remainder(256)

    length_little_endian =
      Nx.broadcast(original_length_bits, {4})
      |> Nx.divide(Nx.tensor([1, 256, 65536, 16_777_216]))
      |> Nx.as_type({:u, 8})
      |> Nx.pad(0, [{0, @max_message_size_bytes - 4, 0}])
      # |> Nx.take(shift_right_message_64_new()[shift_amount])
      |> shift_tensor(
        str_len |> Nx.add(pad_amount) |> Nx.add(1),
        shift_right_message_64()
      )

    [padding, _] = Nx.broadcast_vectors([message_m32b_padding(), digest])

    encoded =
      padding
      |> shift_tensor(str_len, shift_right_message_64())
      |> Nx.add(length_little_endian)
      |> Nx.add(unwrap_string_to_message(digest))
      |> pack_as_dwords()

    Nx.concatenate([total_effective_len, encoded])
  end

  defn build_m32b(digest) do
    str_len = digest[0] |> Nx.as_type({:u, 32})

    pad_amount =
      Nx.tensor([56])
      |> Nx.subtract(Nx.remainder(Nx.add(str_len, 1), 64))
      |> Nx.add(64)
      |> Nx.remainder(64)

    total_effective_len =
      str_len
      |> Nx.add(pad_amount)
      |> Nx.add(1 + 8)
      |> Nx.divide(4)
      |> Nx.as_type({:u, 32})

    original_length_bits = Nx.multiply(str_len, 8)

    shift_amount = str_len |> Nx.add(pad_amount) |> Nx.add(1) |> Nx.remainder(256)

    length_little_endian =
      Nx.broadcast(original_length_bits, {4})
      |> Nx.divide(Nx.tensor([1, 256, 65536, 16_777_216]))
      |> Nx.as_type({:u, 8})
      |> Nx.pad(0, [{0, @max_message_size_bytes - 4, 0}])
      |> Nx.take(shift_right_message_64_new()[shift_amount])
      |> Nx.squeeze()

    # |> shift_tensor(
    #  str_len |> Nx.add(pad_amount) |> Nx.add(1),
    #  shift_right_message_64()
    # )
    # |> IO.inspect(limit: :infinity)

    # exit(0)

    [padding, _] = Nx.broadcast_vectors([message_m32b_padding(), digest])

    shift_amount = str_len |> Nx.remainder(256)

    encoded =
      padding
      # |> shift_tensor(str_len, shift_right_message_64())
      |> Nx.take(shift_right_message_64_new()[shift_amount])
      |> Nx.squeeze()
      |> Nx.add(length_little_endian)
      |> Nx.add(unwrap_string_to_message(digest))
      |> pack_as_dwords()

    Nx.concatenate([total_effective_len, encoded])
  end

  # defp build_m32b(digest) do
  #  l = length(digest)

  #  pad_amount =
  #    case 56 - rem(l + 1, 64) do
  #      n when n < 0 -> n + 64
  #      n -> n
  #    end

  #  total_effective_len = l + pad_amount + 1 + 8

  #  alignment_padding = @max_message_size - total_effective_len

  #  digest
  #  |> Enum.concat(build_m32b_ending(l, pad_amount))
  #  |> Enum.concat(Stream.duplicate(0x0, alignment_padding))
  #  |> Enum.chunk_every(4)
  #  |> Enum.map(&(:binary.list_to_bin(&1) |> :binary.decode_unsigned(:little)))
  #  |> (&Enum.concat([div(total_effective_len, 4)], &1)).()
  #  |> Nx.tensor(type: {:u, 32})
  # end

  defn calc_md5_as_string(m32b) do
    m32b
    |> ShadowHash.Gpu.Md5core.md5_disect()
    |> Nx.pad(0, [{1, @max_str_size - 16 - 1, 0}])
    |> Nx.indexed_put(
      Nx.tensor([0]),
      16
    )
    |> Nx.as_type({:u, 8})
  end

  defn create_a_tail(pwd_len, even_char) do
    # 1, 0 len=2
    # calc_len = floor(:math.log(pwd_len) / :math.log(2)) + 1
    calc_len =
      pwd_len
      |> Nx.log()
      |> Nx.divide(Nx.log(2))
      |> Nx.add(1)
      |> Nx.as_type({:s, 32})

    pow_counter = Nx.iota({150}) |> Nx.min(20)
    divisors = Nx.broadcast(Nx.tensor([2]), {150}) |> Nx.pow(pow_counter) |> Nx.as_type({:u, 32})

    tw =
      Nx.broadcast(pwd_len, {150})
      |> Nx.as_type({:u, 32})
      |> Nx.divide(divisors)
      |> Nx.as_type({:u, 32})
      |> Nx.remainder(2)

    map = create_simple_map(calc_len)

    encoded =
      Nx.tensor([1])
      |> Nx.subtract(tw)
      |> Nx.multiply(even_char)
      |> Nx.multiply(map)
      |> Nx.as_type({:u, 8})
      |> Nx.slice([0], [@max_str_size - 1])

    Nx.concatenate([calc_len, encoded])
  end

  defn create_next_da(i, current_da, passwords, salt) do
    [salt, _] = Nx.broadcast_vectors([salt, passwords])

    msg_a_choice = Nx.remainder(i, 2)
    msg_b_choice = Nx.remainder(i, 3) |> Nx.min(1)
    msg_c_choice = Nx.remainder(i, 7) |> Nx.min(1)
    msg_d_choice = Nx.remainder(i, 2)

    msg =
      Nx.add(
        msg_a_choice |> Nx.multiply(passwords),
        1 |> Nx.subtract(msg_a_choice) |> Nx.multiply(current_da)
      )

    msg_b_eval = ShadowHash.Gpu.Strutil.concat(msg, salt)

    msg =
      Nx.add(
        msg_b_choice |> Nx.multiply(msg_b_eval),
        1 |> Nx.subtract(msg_b_choice) |> Nx.multiply(msg)
      )

    msg_c_eval = ShadowHash.Gpu.Strutil.concat(msg, passwords)

    msg =
      Nx.add(
        msg_c_choice |> Nx.multiply(msg_c_eval),
        1 |> Nx.subtract(msg_c_choice) |> Nx.multiply(msg)
      )

    msg_d_eval_a = ShadowHash.Gpu.Strutil.concat(msg, current_da)
    msg_d_eval_b = ShadowHash.Gpu.Strutil.concat(msg, passwords)

    msg =
      Nx.add(
        msg_d_choice |> Nx.multiply(msg_d_eval_a),
        1 |> Nx.subtract(msg_d_choice) |> Nx.multiply(msg_d_eval_b)
      )

    msg
    |> build_m32b()
    |> calc_md5_as_string()
  end

  defn md5crypt(passwords, salt) do
    # passwords = passwords |> create()

    # salt = Nx.devectorize(create([salt]))[0]

    [salt, magic, _] = Nx.broadcast_vectors([salt, str_magic(), passwords])

    db =
      passwords
      |> concat(salt)
      |> concat(passwords)
      |> build_m32b()
      |> calc_md5_as_string()

    a_message =
      passwords
      |> concat(magic)
      |> concat(salt)
      |> concat(repeatedly(db, passwords[0]))
      |> concat(create_a_tail(passwords[0], passwords[1]))

    da =
      a_message
      |> build_m32b()
      |> calc_md5_as_string()

    {_, _, _, r} =
      while {x = 0, passwords, salt, da}, Nx.less(x, 1000) do
        da = create_next_da(x, da, passwords, salt)
        {x + 1, passwords, salt, da}
      end

    r |> Nx.slice([1], [16])
  end

  defn md5crypt_find(passwords, salt, search) do
    w =
      md5crypt(passwords, salt)
      |> Nx.subtract(search)
      |> Nx.any()

    r = Nx.subtract(1, w)
    |> Nx.devectorize
    |> Nx.multiply(2)

    Nx.concatenate([Nx.tensor([1]), r])
    |> Nx.argmax
    |> Nx.subtract(1)
  end

  def test_concat() do
    a = ShadowHash.Gpu.Strutil.create_set([~c"bob", ~c"timmy"])
    b = ShadowHash.Gpu.Strutil.create_set([~c"cba", ~c"abc"])

    concat(a, b)
  end

  def test_concat_length() do
    a = ShadowHash.Gpu.Strutil.create_set([~c"bob", ~c"timmy"])

    concat_length(a)
  end

  def test_pack() do
    t = Nx.iota({@max_message_size_bytes}) |> Nx.as_type({:u, 8})
    t0 = Nx.add(Nx.iota({@max_message_size_bytes}), 5) |> Nx.as_type({:u, 8})

    r = Nx.stack([t, t0]) |> Nx.vectorize(:rows)

    pack_as_dwords(r)
  end

  def test_buildm32b() do
    a =
      ShadowHash.Gpu.Strutil.create_set([
        ~c"bob",
        ~c"timmaaaaaaaaaaaay"
      ])

    build_m32b(a)
    |> IO.inspect(limit: :infinity)

    # build_m32b_faster(a)
    |> IO.inspect(limit: :infinity)

    # IO.puts("------------")

    # ShadowHash.Gpu.Md5.build_m32b(~c"bob")
    # |> IO.inspect(limit: :infinity)

    # unwrap_string(a)
  end

  def test_create_password_map() do
    r =
      ShadowHash.Gpu.Strutil.create_set([
        ~c"bob",
        ~c"timmaaaaaaaaaaaay"
      ])

    IO.puts("What???")
    create_password_map(r, r[0]) |> IO.inspect(limit: :infinity)
  end

  def test_repeatedly() do
    r =
      ShadowHash.Gpu.Strutil.create_set([
        ~c"bob",
        ~c"timmaaaaaaaaaaaay"
      ])

    repeatedly(r, Nx.vectorize(Nx.tensor([8, 4], type: {:u, 8}), :rows))
  end

  def test_md5crypt() do
    compiled = Nx.Defn.jit(&md5crypt/2, compiler: EXLA)

    [
      ~c"tp"
      # ~c"bob"
    ]
    |> create_set()
    |> compiled.(create(~c"cobKo5Ks"))
  end

  def benchmark_do(compiled, data) do
    data
    |> compiled.(create(~c"cobKo5Ks"))
  end

  def benchmark() do
    compiled = Nx.Defn.jit(&md5crypt/2, compiler: EXLA)

    # compiled = Nx.Defn.compile(&md5crypt/2, [Nx.template({150}, :u8), Nx.template({150}, :u8)], compiler: EXLA)

    data =
      [~c"tp"]
      |> Enum.concat(test_benchmark_passwords())
      |> Enum.concat(test_benchmark_passwords())
      |> Enum.concat(test_benchmark_passwords())
      |> Enum.concat(test_benchmark_passwords())
      |> Enum.concat(test_benchmark_passwords())
      |> Enum.concat(test_benchmark_passwords())
      |> Enum.concat(test_benchmark_passwords())
      |> Enum.concat(test_benchmark_passwords())
      |> Enum.concat(test_benchmark_passwords())
      |> Enum.concat(test_benchmark_passwords())
      |> Enum.concat(test_benchmark_passwords())
      |> create_set()

    data
    |> compiled.(create(~c"cobKo5Ks"))

    IO.puts("Warmup done...")

    {time, r} = :timer.tc(__MODULE__, :benchmark_do, [compiled, data])

    IO.puts(time / 1000_000)
    r
  end

  def test_findmd5() do
    compiled = Nx.Defn.jit(&md5crypt_find/3, compiler: EXLA)

    passwords =
      [
        ~c"ab",
        ~c"cd",
        ~c"tp",
        ~c"fg"
      ]
      |> create_set()
      |> compiled.(
        create(~c"cobKo5Ks"),
        Nx.tensor([8, 56, 211, 120, 45, 179, 217, 228, 179, 252, 230, 245, 221, 171, 68, 113],
          type: {:u, 8}
        )
      )
  end
end
