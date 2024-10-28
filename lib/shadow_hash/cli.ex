defmodule ShadowHash.Cli do

  alias ShadowHash.Shadow

  # Entry point for escripts
  def main(argv) do
    parse_args(argv)
    |> Shadow.process()
  end

  def parse_args(argv),
    do:
      OptionParser.parse(argv,
        strict: [
          shadow: :string,
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
    do: %{
      shadow: shadow,
      user: "*",
      dictionary: nil,
      all_chars: false,
      non_worker: false,
      verbose: false
    }

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
  end

  defp _parse_args(_), do: :help
end
