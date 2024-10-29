defmodule Mix.Tasks.ShadowHash do
  def run(args) do
    Mix.Task.run("app.start")
    ShadowHash.Cli.main(args)
  end

end
