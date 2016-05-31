defmodule GenStateMachine do
  @moduledoc """
  A behaviour module for implementing a state machine.

  The advantage of using this module is that it will have a standard set of
  interface functions and include functionality for tracing and error reporting.
  It will also fit into a supervision tree.

  ## Example

  The GenStateMachine behaviour abstracts the state machine. Developers are only
  required to implement the callbacks and functionality they are interested in.

  Let's start with a code example and then explore the available callbacks.
  Imagine we want a GenStateMachine that works like a switch, allowing us to
  turn it on and off, as well as see how many times the switch has been turned
  on:

      defmodule Switch do
        use GenStateMachine

        # Callbacks

        def handle_event(:cast, :flip, :off, data) do
          {:next_state, :on, data + 1}
        end

        def handle_event(:cast, :flip, :on, data) do
          {:next_state, :off, data}
        end

        def handle_event({:call, from}, :get_count, state, data) do
          {:next_state, state, data, [{:reply, from, data}]}
        end
      end

      # Start the server
      {:ok, pid} = GenStateMachine.start_link(Switch, {:off, 0})

      # This is the client
      GenStateMachine.cast(pid, :flip)
      #=> :ok

      GenStateMachine.call(pid, :get_count)
      #=> 1
  """

  @callback init(args :: term) ::
    :ok

  @doc false
  defmacro __using__(args) do
    callback_mode = Keyword.get(args, :callback_mode, :handle_event_function)

    quote location: :keep do
      @behaviour GenStateMachine
      @before_compile GenStateMachine
      @gen_statem_callback_mode unquote(callback_mode)

      @doc false
      def init({state, data}) do
        {:ok, state, data}
      end

      if @gen_statem_callback_mode == :handle_event_function do
        @doc false
        def handle_event(_event_type, _event_content, _state, _data) do
          {:stop, :bad_event}
        end
      end

      @doc false
      def terminate(_reason, _state, _data) do
        :ok
      end

      @doc false
      def code_change(_old_vsn, state, data, _extra) do
        {:ok, state, data}
      end

      overridable_funcs = [init: 1, terminate: 3, code_change: 4]

      overridable_funcs =
        if @gen_statem_callback_mode == :handle_event_function do
          overridable_funcs = [handle_event: 4] ++ overridable_funcs
        else
          overridable_funcs
        end

      defoverridable overridable_funcs
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote location: :keep do
      defoverridable [init: 1, code_change: 4]

      def init(args) do
        case super(args) do
          {:ok, state, data} -> {@gen_statem_callback_mode, state, data}
          {:ok, state, data, actions} -> {@gen_statem_callback_mode, state, data, actions}
          other -> other
        end
      end

      def code_change(old_vsn, state, data, extra) do
        case super(old_vsn, state, data, extra) do
          {:handle_event_function, state, data} -> {:handle_event_function, state, data}
          {:state_functions, state, data} -> {:state_functions, state, data}
          {:ok, state, data} -> {@gen_statem_callback_mode, state, data}
          other -> other
        end
      end
    end
  end

  def start_link(module, args, options \\ []) do
    if options[:name] do
      :gen_statem.start_link(options[:name], module, args, options)
    else
      :gen_statem.start_link(module, args, options)
    end
  end

  def start(module, args, options \\ []) do
    if options[:name] do
      :gen_statem.start(options[:name], module, args, options)
    else
      :gen_statem.start(module, args, options)
    end
  end

  def stop(server, reason \\ :normal, timeout \\ :infinity) do
    :gen_statem.stop(server, reason, timeout)
  end

  def call(server, request, timeout \\ :infinity) do
    :gen_statem.call(server, request, timeout)
  end

  def cast(server, request) do
    :gen_statem.cast(server, request)
  end

  def reply(replies) do
    :gen_statem.reply(replies)
  end

  def reply(client, reply) do
    :gen_statem.reply(client, reply)
  end
end
