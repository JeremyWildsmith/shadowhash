defmodule ShadowHash.Cli do
  use Mix.Task

  alias ShadowHash.Shadow

  #Entry point for escripts
  def main(argv) do
    parse_args(argv)
    |> Shadow.process()
  end

  def parse_args(argv),
    do:
      OptionParser.parse(argv,
        strict: [shadow: :string, user: :string, all_chars: :boolean, non_worker: :boolean, verbose: :boolean, gpu: :boolean, dictionary: :string]
      )
      |> _parse_args

  defp _parse_args({[], [shadow], []}),
    do: %{shadow: shadow, user: "*", dictionary: nil, all_chars: false, non_worker: false, verbose: false}

  defp _parse_args({optional, [shadow], []}) do
    cfg = %{shadow: shadow}

    for(
      {k, v} <- optional,
      into: cfg,
      do: {k, v}
    )
    |> Map.put_new(:dictionary, nil)
    |> Map.put_new(:all_chars, false)
    |> Map.put_new(:non_worker, false)
    |> Map.put_new(:verbose, false)
    |> Map.put_new(:user, "*")
    |> Map.put_new(:gpu, false)
  end

  defp _parse_args(_), do: :help
end
