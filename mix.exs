defmodule Exgpg.Mixfile do
  use Mix.Project

  def project do
    [app: :exgpg,
     version: "0.0.3",
     elixir: "~> 1.0.0",
     deps: deps,
     package: package]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :porcelain]]
  end
  
  defp package do
    [
     files: ["config", "lib", "mix.exs", "README.md", "LICENSE*", "test*", "to_import"],
     contributors: ["Chris Duranti"],
     deps: deps,
     licenses: ["MIT"],
     links: %{
         "GitHub" => "https://github.com/rozap/exgpg",
     }
    ]
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
    [
      { :uuid, "~> 0.1.5" },
      { :porcelain, "~> 2.0.0"}
    ]
  end
end
