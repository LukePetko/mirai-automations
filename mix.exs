defmodule MiraiAutomations.MixProject do
  use Mix.Project

  def project do
    [
      app: :mirai_automations,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: ["automations"],
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:mirai, path: "../mirai", runtime: false}
    ]
  end
end
