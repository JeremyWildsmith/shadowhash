defmodule ShadowHash.CliTest do
  use ExUnit.Case

  test "No arguments" do
    output = ShadowHash.Cli.parse_args([])

    assert output == :help
  end

  test "Too many arguments" do
    output = ShadowHash.Cli.parse_args(["toomany", "arguments", "hello", "world"])

    assert output == :help
  end

  test "Shadow file and username provided" do
    %{shadow: shadow, user: user} = ShadowHash.Cli.parse_args(["testshadow", "--user", "testuser"])

    assert shadow == "testshadow"
    assert user == "testuser"
  end
end
