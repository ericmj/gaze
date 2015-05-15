defmodule Gaze.Mixfile do
  use Mix.Project

  def project do
    [app: :gaze,
     version: "0.0.1",
     aliases: aliases,
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: {Gaze, []},
     applications: [:phoenix, :cowboy, :logger]]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies
  #
  # Type `mix help deps` for examples and options
  defp deps do
    [{:phoenix, "~> 0.13"},
     {:phoenix_live_reload, "~> 0.4", only: :dev},
     {:phoenix_html, "~> 1.0"},
     {:cowboy, "~> 1.0"}]
  end

  defp aliases do
    if heroku? do
      [compile: ["compile", &assets/1]]
    else
      []
    end
  end

  defp assets(args) do
    Mix.Task.run "phoenix.digest", args
    Mix.Project.build_structure
  end

  defp heroku?, do: !! System.get_env("DYNO")
end
