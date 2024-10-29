defmodule ShadowHash.Cli do

  alias ShadowHash.Shadow

  # Entry point for escripts
  def main(argv) do
    parse_args(argv)
    |> Shadow.process()
  end

  def parse_args(argv),
    do:
      argv
      |> Enum.map(fn e -> e |> String.replace("–", "-") end) #In-case pasting from document.
      |> OptionParser.parse(
        strict: [
          password: :string,
          user: :string,
          all_chars: :boolean,
          workers: :integer,
          verbose: :boolean,
          gpu: :boolean,
          gpu_warmup: :boolean,
          dictionary: :string
        ]
      )
      |> _parse_args

  defp _parse_args({[], [shadow], []}),
    do: _parse_args({%{}, [shadow], []})

  defp _parse_args({[{:password, _} | _] = opt, [], []}) do
    _parse_args({opt, [nil], []})
  end

  defp _parse_args({optional, [shadow], []}) do
    cfg = %{shadow: shadow}

    for(
      {k, v} <- optional,
      into: cfg,
      do: {k, v}
    )
    |> Map.put_new(:dictionary, nil)
    |> Map.put_new(:all_chars, false)
    |> Map.put_new(:workers, :erlang.system_info(:logical_processors_available))
    |> Map.put_new(:verbose, false)
    |> Map.put_new(:user, "*")
    |> Map.put_new(:gpu, false)
    |> Map.put_new(:gpu_warmup, false)
    |> Map.put_new(:password, nil)
  end

  defp _parse_args(_args) do
    :help
  end
end
