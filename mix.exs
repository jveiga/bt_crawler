defmodule BtCrawler.Mixfile do
  use Mix.Project

  def project do
    [app: :bt_crawler,
     version: "0.0.1",
     elixir: "~> 1.0",
     escript: [main_module: BtCrawler.CLI],
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:socket,     "~> 0.2.8"},
     {:bencodex,   "~> 1.0.0"},
     {:pretty_hex, "~> 0.0.1"},
     {:ecto,       "~> 0.2.4"}
    ]
  end
end
