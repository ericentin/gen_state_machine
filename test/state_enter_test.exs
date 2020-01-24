defmodule StateEnterTest do
  use ExUnit.Case


  defmodule EventFunctionEnterSwitch do
    use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

    def handle_event(:enter, _event, state, data) do
      {:next_state, state, %{data | enters: data.enters+1}}
    end

    def handle_event(:cast, :flip, :off, data) do
      {:next_state, :on, %{data | flips: data.flips+1}}
    end

    def handle_event(:cast, :flip, :on, data) do
      {:next_state, :off, data}
    end

    def handle_event({:call, from}, :get_count, _state, data) do
      {:keep_state_and_data, [{:reply, from, data}]}
    end
  end

  test "handle_event_function and state_enter" do
    {:ok, pid} = GenStateMachine.start_link(EventFunctionEnterSwitch, {:off, %{enters: 0, flips: 0}})

    {:links, links} = Process.info(self(), :links)
    assert pid in links

    assert GenStateMachine.cast(pid, :flip) == :ok
    assert GenStateMachine.cast(pid, :flip) == :ok
    assert GenStateMachine.cast(pid, :flip) == :ok

    assert %{enters: 4, flips: 2} = GenStateMachine.call(pid, :get_count)
    assert GenStateMachine.stop(pid) == :ok
  end
end
