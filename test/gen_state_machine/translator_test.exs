defmodule GenStateMachine.TranslatorTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  defmodule FailingStateMachine do
    use GenStateMachine

    def handle_event(_, :error, _, _), do: raise("oops")
    def handle_event(_, actions, _, _), do: {:keep_state_and_data, actions}
  end

  test "translates :gen_statem crashes" do
    {:ok, pid} = GenStateMachine.start(FailingStateMachine, {:state, :data})

    assert capture_log([level: :info], fn ->
             catch_exit(GenStateMachine.call(pid, :error))
             :timer.sleep(100)
           end) =~ """
           [error] GenStateMachine #{inspect(pid)} terminating
           ** (RuntimeError) oops
           """
  end

  test "translates :gen_statem crashes debug" do
    {:ok, pid} = GenStateMachine.start(FailingStateMachine, {:state, :data})

    assert capture_log([level: :debug], fn ->
             actions = [
               {:next_event, :internal, :postpone},
               {:next_event, :internal, :error},
               {:next_event, :internal, :queued}
             ]

             catch_exit(GenStateMachine.call(pid, actions))
             :timer.sleep(100)
           end) =~
             ~r"""
             \[error\] GenStateMachine #PID<\d+\.\d+\.\d+> terminating
             \*\* \(RuntimeError\) oops
             .*/\d+
             Callback mode: :handle_event_function
             Last event: {:internal, :error}
             Postponed events: \[internal: :postpone\]
             Queued events: \[internal: :queued\]
             State: {:state, :data}
             """s
  end
end
