defmodule ShadowHash.ParseTest do
  use ExUnit.Case

  test "Parse yescrypt" do
    %{algo: algo, hash: hash} =
      ShadowHash.PasswordParse.parse(
        "$y$j9T$wi.UQKUsG0cTzYN/XoIXz1$IOtdTMHFbtJdfXrEXqjkZEme64ES2GL9pTNTd4cbrmB"
      )

    assert algo.method == :yescrypt
    assert algo.config == "$y$j9T$wi.UQKUsG0cTzYN/XoIXz1"
    assert hash == "IOtdTMHFbtJdfXrEXqjkZEme64ES2GL9pTNTd4cbrmB"
  end

  test "Parse bcrypt-a" do
    %{algo: algo, hash: hash} =
      ShadowHash.PasswordParse.parse(
        "$2a$05$xKW7x2RfaBhzW7Eg5B6FMuNqxAorNMXpiLEhagjk3Fi8YYC7tJVNe"
      )

    assert algo.method == :bcrypt_a

    assert algo.config == "$2a$05$xKW7x2RfaBhzW7Eg5B6FMu"
    assert hash == "NqxAorNMXpiLEhagjk3Fi8YYC7tJVNe"
  end

  test "Parse bcrypt-b" do
    %{algo: algo, hash: hash} =
      ShadowHash.PasswordParse.parse(
        "$2b$05$R/zfFNqEn3vRM.dTUepsbeyZZOfRBrU7LOJDhx9ANuVhy1WkAwDPy"
      )

    assert algo.method == :bcrypt_b

    assert algo.config == "$2b$05$R/zfFNqEn3vRM.dTUepsbe"
    assert hash == "yZZOfRBrU7LOJDhx9ANuVhy1WkAwDPy"
  end

  test "Parse sha512" do
    %{algo: algo, hash: hash} =
      ShadowHash.PasswordParse.parse(
        "$6$RWBYzBG3gcPf1knH$tkZMJGB4/LPH09g2YODLI5w3JqFc7Qh9kw.5ZYLBHqqSupzdqXdDPhrAfBaHRQbv.jfcsCijuHB53g.7dYtVr0"
      )

    assert algo.method == :sha512

    assert algo.config == "$6$RWBYzBG3gcPf1knH"

    assert hash ==
             "tkZMJGB4/LPH09g2YODLI5w3JqFc7Qh9kw.5ZYLBHqqSupzdqXdDPhrAfBaHRQbv.jfcsCijuHB53g.7dYtVr0"
  end

  test "Parse sha256" do
    %{algo: algo, hash: hash} =
      ShadowHash.PasswordParse.parse(
        "$5$zeDOAERRV2Omwn0x$UIeNQe1tm.LSBz3SJt7hOYfQj.6AToFEm5/JbKDtFiA"
      )

    assert algo.method == :sha256

    assert algo.config == "$5$zeDOAERRV2Omwn0x"
    assert hash == "UIeNQe1tm.LSBz3SJt7hOYfQj.6AToFEm5/JbKDtFiA"
  end

  test "Parse descrypt" do
    %{algo: algo, hash: hash} =
      ShadowHash.PasswordParse.parse("QCGyw25v5w.yk")

    assert algo.method == :descrypt

    assert algo.config == "QC"
    assert hash == "Gyw25v5w.yk"
  end

  test "Parse scrypt" do
    %{algo: algo, hash: hash} =
      ShadowHash.PasswordParse.parse(
        "$7$CU..../....fYmOUQItcMPFnSFHh57MV.$nLiY/9444kA5rcp/E9IPWQnEEUOrM3WNuKmDE9Qz2B8"
      )

    assert algo.method == :scrypt

    assert algo.config == "$7$CU..../....fYmOUQItcMPFnSFHh57MV."
    assert hash == "nLiY/9444kA5rcp/E9IPWQnEEUOrM3WNuKmDE9Qz2B8"
  end

  test "sunmd5" do
    %{algo: algo, hash: hash} =
      ShadowHash.PasswordParse.parse("$md5,rounds=36912$KxfrRqqx$$LovNKd30ubFzeTvc2ZtfK1")

    assert algo.method == :sunmd5

    assert algo.config == "$md5,rounds=36912$KxfrRqqx$$"
    assert hash == "LovNKd30ubFzeTvc2ZtfK1"
  end

  test "Parse MD5 Crypt" do
    %{algo: algo, hash: hash} =
      ShadowHash.PasswordParse.parse("$1$cobKo5Ks$RbB0fGCC2BvollDSnOS9p1")

    assert algo.method == :md5crypt

    assert algo.config == "$1$cobKo5Ks"
    assert hash == "RbB0fGCC2BvollDSnOS9p1"
  end

  test "Parse NT" do
    %{algo: algo, hash: hash} =
      ShadowHash.PasswordParse.parse("$3$$8e98570c3a7511785726a13ffed5f8d5")

    assert algo.method == :nt

    assert algo.config == "$3$$"
    assert hash == "8e98570c3a7511785726a13ffed5f8d5"
  end

  test "Parse gost-yescrypt" do
    %{algo: algo, hash: hash} =
      ShadowHash.PasswordParse.parse("$gy$j9T$W2Cj6u7yqrjUKD9Cbhi3I0$g4iyWjOZRbmKxEXh0BvFtZUXUPgCo0cy9d4gPIQmt5D")

    assert algo.method == :gost_yescrypt

    assert algo.config == "$gy$j9T$W2Cj6u7yqrjUKD9Cbhi3I0"
    assert hash == "g4iyWjOZRbmKxEXh0BvFtZUXUPgCo0cy9d4gPIQmt5D"
  end
end
