"""

def test_concat() do
  a = ShadowHash.Gpu.Md5crypt.create_set([~c"bob", ~c"timmy"])
  b = ShadowHash.Gpu.Md5crypt.create_set([~c"cba", ~c"abc"])

  concat(a, b)
end

def test_pack() do
  t = Nx.iota({@max_message_size_bytes}) |> Nx.as_type({:u, 8})
  t0 = Nx.add(Nx.iota({@max_message_size_bytes}), 5) |> Nx.as_type({:u, 8})

  r = Nx.stack([t, t0]) |> Nx.vectorize(:rows)

  pack_as_dwords(r)
end

def test_buildm32b() do
  a =
    ShadowHash.Gpu.Md5crypt.create_set([
      ~c"bob",
      ~c"timmaaaaaaaaaaaay"
    ])

  build_m32b(a)
  |> IO.inspect(limit: :infinity)

  # build_m32b_faster(a)
  |> IO.inspect(limit: :infinity)
end

def test_create_password_map() do
  r =
    ShadowHash.Gpu.Md5crypt.create_set([
      ~c"bob",
      ~c"timmaaaaaaaaaaaay"
    ])

  IO.puts("What???")
  create_password_map(r, r[0]) |> IO.inspect(limit: :infinity)
end

def test_repeatedly() do
  r =
    ShadowHash.Gpu.Md5crypt.create_set([
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

def test_findmd5() do
  compiled = Nx.Defn.jit(&md5crypt_find/3, compiler: EXLA)

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
"""

defmodule Md5cryptTest do

end
