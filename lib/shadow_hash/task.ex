defmodule Mix.Tasks.ShadowHash do
  #Entry point for task
  def run(args) do
    Mix.Task.run("app.start")
    ShadowHash.Cli.main(args)
  end

end
