defmodule GenStateMachine.Mixfile do
  use Mix.Project

  def project do
    [app: :gen_state_machine,
     version: "0.0.1",
     elixir: "~> 1.3-rc",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod]
  end
end
