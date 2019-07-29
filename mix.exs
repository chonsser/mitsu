defmodule Mitsu.MixProject do
  use Mix.Project

  def project do
    [
      app: :mitsu,
      version: "1.0.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Mitsu, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:amqp, "~> 1.2"},
      {:websockex, "~> 0.4.2"},
      {:httpoison, "~> 1.4"},
      {:jason, "~> 1.1"}
    ]
  end

end
