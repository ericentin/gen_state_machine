defmodule GenStateMachine.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :gen_state_machine,
     version: @version,
     elixir: "~> 1.3-rc",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     description: description,
     package: package,
     docs: [
       main: "GenStateMachine",
       extras: ["README.md"],
       source_ref: "v#{@version}"
     ]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.11.5", only: :dev}
    ]
  end

  defp description do
    "An Elixir wrapper for gen_statem."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Eric Entin"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/antipax/gen_state_machine"
      }
    ]
  end
end
