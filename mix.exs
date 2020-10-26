otp_release =
  :erlang.system_info(:otp_release)
  |> to_string()
  |> String.split(".")
  |> List.first()
  |> String.to_integer()

if otp_release < 20 do
  IO.warn("gen_state_machine requires Erlang/OTP 20 or greater", [])
end

defmodule GenStateMachine.Mixfile do
  use Mix.Project

  @version "3.0.0"

  def project do
    [
      app: :gen_state_machine,
      version: @version,
      elixir: "~> 1.5",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/ericentin/gen_state_machine",
      docs: [
        main: "GenStateMachine",
        extras: ["README.md"],
        source_ref: "v#{@version}"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {GenStateMachine.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false}
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
        "GitHub" => "https://github.com/ericentin/gen_state_machine"
      }
    ]
  end
end
