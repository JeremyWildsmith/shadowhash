use Mix.Config

config :exla, :clients,
  cuda: [platform: :cuda, memory_fraction: 0.5]
