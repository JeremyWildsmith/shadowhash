defmodule ShadowHash.Job.JobParser do
  alias ShadowHash.Job.DictionaryStreamJob
  alias ShadowHash.Job.DictionaryJob
  alias ShadowHash.Job.BruteforceJob

  @chunk_size 500


  defp skip_if_empty(nil, remaining, chunk_by), do: take_job(remaining, chunk_by)
  defp skip_if_empty({current, next}, remaining, _chunk_by), do: {current, [next] ++ remaining}

  def take_job(jobs, chunk_by \\ @chunk_size)
  def take_job([], _chunk_by), do: :empty
  def take_job([h | remaining], chunk_by), do: take_unit(h, chunk_by) |> skip_if_empty(remaining, chunk_by)

  defp take_unit(%DictionaryStreamJob{stream: stream}, chunk_by) do
    stream
    |> Stream.take(chunk_by)
    |> Enum.to_list()
    |> case do
      [] ->
        nil

      names ->
        {
          %DictionaryJob{names: names},
          %DictionaryStreamJob{stream: stream |> Stream.drop(chunk_by)}
        }
    end
  end

  defp take_unit(%DictionaryJob{}, _chunk_by) do
    raise "Should never be taking a unit from a dictionary job..."
  end

  defp take_unit(%BruteforceJob{begin: begin, last: :inf, charset: charset}, chunk_by) do
    {
      %BruteforceJob{begin: begin, last: begin + chunk_by - 1, charset: charset},
      %BruteforceJob{begin: begin + chunk_by, last: :inf, charset: charset}
    }
  end

  defp take_unit(%BruteforceJob{begin: begin, last: last}, _chunk_by) when last < begin do
    nil
  end

  defp take_unit(%BruteforceJob{begin: begin, last: last, charset: charset}, chunk_by) do
    {
      %BruteforceJob{begin: begin, last: min(begin + chunk_by - 1, last), charset: charset},
      %BruteforceJob{begin: begin + chunk_by, last: last, charset: charset}
    }
  end
end
