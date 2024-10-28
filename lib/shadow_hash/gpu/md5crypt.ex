defmodule ShadowHash.Gpu.Md5crypt do
  import Nx.Defn
  import ShadowHash.Gpu.Constants

  @max_str_size 150
  @max_message_size_bytes 64 * 4

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

  defn concat(a, b) do
    a_len = a[0]

    b
    |> Nx.as_type({:u, 8})
    |> Nx.take(right_shift_vectors()[a_len])
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
      |> Nx.take(shift_right_message_64()[shift_amount])
      |> Nx.squeeze()

    [padding, _] = Nx.broadcast_vectors([message_m32b_padding(), digest])

    shift_amount = str_len |> Nx.remainder(256)

    encoded =
      padding
      |> Nx.take(shift_right_message_64()[shift_amount])
      |> Nx.squeeze()
      |> Nx.add(length_little_endian)
      |> Nx.add(unwrap_string_to_message(digest))
      |> pack_as_dwords()

    Nx.concatenate([total_effective_len, encoded])
  end

  defn calc_md5_as_string(m32b) do
    m32b
    |> ShadowHash.Gpu.Md5.md5_disect()
    |> Nx.pad(0, [{1, @max_str_size - 16 - 1, 0}])
    |> Nx.indexed_put(
      Nx.tensor([0]),
      16
    )
    |> Nx.as_type({:u, 8})
  end

  defn create_a_tail(pwd_len, even_char) do
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

    msg_b_eval = ShadowHash.Gpu.Md5crypt.concat(msg, salt)

    msg =
      Nx.add(
        msg_b_choice |> Nx.multiply(msg_b_eval),
        1 |> Nx.subtract(msg_b_choice) |> Nx.multiply(msg)
      )

    msg_c_eval = ShadowHash.Gpu.Md5crypt.concat(msg, passwords)

    msg =
      Nx.add(
        msg_c_choice |> Nx.multiply(msg_c_eval),
        1 |> Nx.subtract(msg_c_choice) |> Nx.multiply(msg)
      )

    msg_d_eval_a = ShadowHash.Gpu.Md5crypt.concat(msg, current_da)
    msg_d_eval_b = ShadowHash.Gpu.Md5crypt.concat(msg, passwords)

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

    r =
      Nx.subtract(1, w)
      |> Nx.devectorize()
      |> Nx.multiply(2)

    Nx.concatenate([Nx.tensor([1]), r])
    |> Nx.argmax()
    |> Nx.subtract(1)
  end
end
