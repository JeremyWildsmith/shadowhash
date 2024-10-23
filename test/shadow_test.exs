defmodule ShadowHash.ShadowTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  test "Shadow file does not exist" do
    output = capture_io(fn -> ShadowHash.Shadow.process_file("sample_user", {:error, :enoent}, nil, false) end)

    assert String.starts_with?(output, "Error, unable to open the shadow file.")
  end
end
