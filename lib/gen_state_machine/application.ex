defmodule GenStateMachine.Application do
  @moduledoc false

  use Application

  @doc false
  def start(_type, _args) do
    Logger.add_translator({GenStateMachine.Translator, :translate})
    Supervisor.start_link([], strategy: :one_for_one)
  end
end
