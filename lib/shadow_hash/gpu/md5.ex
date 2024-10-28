defmodule ShadowHash.Gpu.Md5 do
  import Nx.Defn

  @shift_per_round Nx.tensor(
                     [
                       7,
                       12,
                       17,
                       22,
                       7,
                       12,
                       17,
                       22,
                       7,
                       12,
                       17,
                       22,
                       7,
                       12,
                       17,
                       22,
                       5,
                       9,
                       14,
                       20,
                       5,
                       9,
                       14,
                       20,
                       5,
                       9,
                       14,
                       20,
                       5,
                       9,
                       14,
                       20,
                       4,
                       11,
                       16,
                       23,
                       4,
                       11,
                       16,
                       23,
                       4,
                       11,
                       16,
                       23,
                       4,
                       11,
                       16,
                       23,
                       6,
                       10,
                       15,
                       21,
                       6,
                       10,
                       15,
                       21,
                       6,
                       10,
                       15,
                       21,
                       6,
                       10,
                       15,
                       21
                     ],
                     type: {:u, 32}
                   )

  @constant_per_round Nx.tensor(
                        [
                          0xD76AA478,
                          0xE8C7B756,
                          0x242070DB,
                          0xC1BDCEEE,
                          0xF57C0FAF,
                          0x4787C62A,
                          0xA8304613,
                          0xFD469501,
                          0x698098D8,
                          0x8B44F7AF,
                          0xFFFF5BB1,
                          0x895CD7BE,
                          0x6B901122,
                          0xFD987193,
                          0xA679438E,
                          0x49B40821,
                          0xF61E2562,
                          0xC040B340,
                          0x265E5A51,
                          0xE9B6C7AA,
                          0xD62F105D,
                          0x02441453,
                          0xD8A1E681,
                          0xE7D3FBC8,
                          0x21E1CDE6,
                          0xC33707D6,
                          0xF4D50D87,
                          0x455A14ED,
                          0xA9E3E905,
                          0xFCEFA3F8,
                          0x676F02D9,
                          0x8D2A4C8A,
                          0xFFFA3942,
                          0x8771F681,
                          0x6D9D6122,
                          0xFDE5380C,
                          0xA4BEEA44,
                          0x4BDECFA9,
                          0xF6BB4B60,
                          0xBEBFBC70,
                          0x289B7EC6,
                          0xEAA127FA,
                          0xD4EF3085,
                          0x04881D05,
                          0xD9D4D039,
                          0xE6DB99E5,
                          0x1FA27CF8,
                          0xC4AC5665,
                          0xF4292244,
                          0x432AFF97,
                          0xAB9423A7,
                          0xFC93A039,
                          0x655B59C3,
                          0x8F0CCC92,
                          0xFFEFF47D,
                          0x85845DD1,
                          0x6FA87E4F,
                          0xFE2CE6E0,
                          0xA3014314,
                          0x4E0811A1,
                          0xF7537E82,
                          0xBD3AF235,
                          0x2AD7D2BB,
                          0xEB86D391
                        ],
                        type: {:u, 32}
                      )

  defn rotate_left(n, shift_count) do
    r = Nx.remainder(shift_count, 32)

    Nx.as_type(
      Nx.bitwise_or(
        Nx.left_shift(n, r),
        Nx.right_shift(n, Nx.subtract(32, r))
      ),
      {:u, 32}
    )
  end

  defn md5_round_compute_f(i, abcd) do
    cond do
      i >= 0 and i <= 15 ->
        Nx.bitwise_or(
          Nx.bitwise_and(abcd[1], abcd[2]),
          Nx.bitwise_and(
            Nx.bitwise_not(abcd[1]),
            abcd[3]
          )
        )

      i >= 16 and i <= 31 ->
        Nx.bitwise_or(
          Nx.bitwise_and(abcd[3], abcd[1]),
          Nx.bitwise_and(
            Nx.bitwise_not(abcd[3]),
            abcd[2]
          )
        )

      i >= 32 and i <= 47 ->
        Nx.bitwise_xor(
          Nx.bitwise_xor(abcd[1], abcd[2]),
          abcd[3]
        )

      i >= 48 and i <= 63 ->
        Nx.bitwise_xor(
          abcd[2],
          Nx.bitwise_or(
            abcd[1],
            Nx.bitwise_not(abcd[3])
          )
        )

      # this should never happen, but we need to return a consistent shape and a true implementation is required.
      true ->
        abcd[0]
    end
  end

  defn md5_round_compute_g(i) do
    cond do
      i >= 0 and i <= 15 ->
        Nx.as_type(i, {:u, 4})

      i >= 16 and i <= 31 ->
        Nx.as_type(5 * i + 1, {:u, 4})

      i >= 32 and i <= 47 ->
        Nx.as_type(3 * i + 5, {:u, 4})

      i >= 48 and i <= 63 ->
        Nx.as_type(7 * i, {:u, 4})

      true ->
        0
    end
  end

  defn md5_round(abcd_m32b, i) do
    abcd = Nx.slice(abcd_m32b, [0], [4])
    m32b = Nx.slice(abcd_m32b, [4], [16])

    f = md5_round_compute_f(i, abcd)
    g = md5_round_compute_g(i)

    # Nx.slice(m32b, [g], [1])
    f =
      m32b[g]
      |> Nx.add(abcd[0])
      |> Nx.add(@constant_per_round[i])
      |> Nx.add(f)

    abcd =
      abcd
      |> Nx.take(Nx.tensor([3, 1, 1, 2]))
      |> Nx.add(
        Nx.stack([
          Nx.tensor(0, type: {:u, 32}),
          rotate_left(f, @shift_per_round[i]),
          Nx.tensor(0, type: {:u, 32}),
          Nx.tensor(0, type: {:u, 32})
        ])
      )

    Nx.concatenate([abcd, m32b])
  end

  defn md5_of_block(initial_abcd, m32b) do
    Nx.concatenate([initial_abcd, m32b])
    |> md5_round(0)
    |> md5_round(1)
    |> md5_round(2)
    |> md5_round(3)
    |> md5_round(4)
    |> md5_round(5)
    |> md5_round(6)
    |> md5_round(7)
    |> md5_round(8)
    |> md5_round(9)
    |> md5_round(10)
    |> md5_round(11)
    |> md5_round(12)
    |> md5_round(13)
    |> md5_round(14)
    |> md5_round(15)
    |> md5_round(16)
    |> md5_round(17)
    |> md5_round(18)
    |> md5_round(19)
    |> md5_round(20)
    |> md5_round(21)
    |> md5_round(22)
    |> md5_round(23)
    |> md5_round(24)
    |> md5_round(25)
    |> md5_round(26)
    |> md5_round(27)
    |> md5_round(28)
    |> md5_round(29)
    |> md5_round(30)
    |> md5_round(31)
    |> md5_round(32)
    |> md5_round(33)
    |> md5_round(34)
    |> md5_round(35)
    |> md5_round(36)
    |> md5_round(37)
    |> md5_round(38)
    |> md5_round(39)
    |> md5_round(40)
    |> md5_round(41)
    |> md5_round(42)
    |> md5_round(43)
    |> md5_round(44)
    |> md5_round(45)
    |> md5_round(46)
    |> md5_round(47)
    |> md5_round(48)
    |> md5_round(49)
    |> md5_round(50)
    |> md5_round(51)
    |> md5_round(52)
    |> md5_round(53)
    |> md5_round(54)
    |> md5_round(55)
    |> md5_round(56)
    |> md5_round(57)
    |> md5_round(58)
    |> md5_round(59)
    |> md5_round(60)
    |> md5_round(61)
    |> md5_round(62)
    |> md5_round(63)
    |> Nx.slice([0], [4])
    |> Nx.add(initial_abcd)
  end

  defn pad_message(m32b) do
  end

  defn md5_of(m32b) do
    abcd =
      Nx.tensor(
        [
          0x67452301,
          0xEFCDAB89,
          0x98BADCFE,
          0x10325476
        ],
        type: {:u, 32}
      )

    [m32b, abcd] = Nx.broadcast_vectors([m32b, abcd])

    hash_size =
      Nx.slice(m32b, [0], [1])
      |> Nx.divide(Nx.tensor(16, type: {:u, 32}))
      |> Nx.as_type({:u, 32})

    m32_shape =
      hash_size
      |> Nx.devectorize(keep_names: false)
      |> Nx.reduce_max()

    {_, _, _, _, r} =
      while {x = 0, m32b, m32_shape, hash_size, abcd}, Nx.less(x, m32_shape) do
        chunk = Nx.slice(m32b, [x * 16 + 1], [16])

        choice_factor = Nx.min(1, Nx.max(0, Nx.subtract(hash_size, x)))

        next_abcd =
          Nx.add(
            Nx.multiply(md5_of_block(abcd, chunk), choice_factor),
            Nx.multiply(abcd, 1 - choice_factor)
          )
          |> Nx.as_type({:u, 32})

        {x + 1, m32b, m32_shape, hash_size, next_abcd}
      end

    r
  end

  defn md5(m32b) do
    m32b
    |> md5_of
  end

  defn md5_disect(m32b) do
    final =
      m32b
      |> md5_of

    final_a = final |> Nx.bitwise_and(0xFF)
    final_b = final |> Nx.right_shift(8) |> Nx.bitwise_and(0xFF)
    final_c = final |> Nx.right_shift(16) |> Nx.bitwise_and(0xFF)
    final_d = final |> Nx.right_shift(24) |> Nx.bitwise_and(0xFF)

    Nx.concatenate([final_a, final_b, final_c, final_d])
    |> Nx.as_type({:u, 8})
    |> Nx.take(
      Nx.tensor([
        0,
        4,
        8,
        12,
        1,
        5,
        9,
        13,
        2,
        6,
        10,
        14,
        3,
        7,
        11,
        15
      ])
    )
  end
end
