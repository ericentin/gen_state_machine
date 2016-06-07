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

  We start our `Switch` by calling `start_link/3`, passing the module with the
  server implmentation and its initial argument (a tuple where the first element
  is the initial state and the second is the initial data). We can primarily
  interact with the state machine by sending two types of messages. **call**
  messages expect a reply from the server (and are therefore synchronous) while
  **cast** messages do not.

  Every time you do a `call/3` or a `cast/2`, the message will be handled by
  `handle_event/4`.

  We can also use the `:state_functions` callback mode instead of the default,
  which is `:handle_event_function`:

      defmodule Switch do
        use GenStateMachine, callback_mode: :state_functions

        def off(:cast, :flip, data) do
          {:next_state, :on, data + 1}
        end
        def off(event_type, event_content, data) do
          handle_event(event_type, event_content, data)
        end

        def on(:cast, :flip, data) do
          {:next_state, :off, data}
        end
        def on(event_type, event_content, data) do
          handle_event(event_type, event_content, data)
        end

        def handle_event({:call, from}, :get_count, data) do
          {:keep_state_and_data, [{:reply, from, data}]}
        end
      end

      # Start the server
      {:ok, pid} = GenStateMachine.start_link(Switch, {:off, 0})

      # This is the client
      GenStateMachine.cast(pid, :flip)
      #=> :ok

      GenStateMachine.call(pid, :get_count)
      #=> 1

  Again, we start our `Switch` by calling `start_link/3`, passing the module
  with the server implmentation and its initial argument, and interacting with
  it via **call** and **cast**.

  However, in `:state_functions` callback mode, every time you do a `call/3` or
  a `cast/2`, the message will be handled by the `state_name/3` function which
  is named the same as the current state.

  ## Callbacks

  In the default `:handle_event_function` callback mode, there are 4 callbacks
  required to be implemented. By adding `use GenStateMachine` to your module,
  Elixir will automatically define all 4 callbacks for you, leaving it up to you
  to implement the ones you want to customize.

  In the `:state_functions` callback mode, there are 3 callbacks required to be
  implemented. By adding `use GenStateMachine, callback_mode: :state_functions`
  to your module, Elixir will automatically define all 3 callbacks for you,
  leaving it up to you to implement the ones you want to customize, as well as
  `state_name/3` functions named the same as the states you wish to support.

  ## Name Registration

  Both `start_link/3` and `start/3` support registering the `GenStateMachine`
  under a given name on start via the `:name` option. Registered names are also
  automatically cleaned up on termination. The supported values are:

    * an atom - the GenStateMachine is registered locally with the given name
      using `Process.register/2`.

    * `{:global, term}`- the GenStateMachine is registered globally with the
      given term using the functions in the `:global` module.

    * `{:via, module, term}` - the GenStateMachine is registered with the given
      mechanism and name. The `:via` option expects a module that exports
      `register_name/2`, `unregister_name/1`, `whereis_name/1` and `send/2`.
      One such example is the `:global` module which uses these functions
      for keeping the list of names of processes and their  associated pid's
      that are available globally for a network of Erlang nodes.

  For example, we could start and register our Switch server locally as follows:

      # Start the server and register it locally with name MySwitch
      {:ok, _} = GenStateMachine.start_link(Switch, {:off, 0}, name: MySwitch)

      # Now messages can be sent directly to MySwitch
      GenStateMachine.call(MySwitch, :get_count) #=> 0

  Once the server is started, the remaining functions in this module (`call/3`,
  `cast/2`, and friends) will also accept an atom, or any `:global` or `:via`
  tuples. In general, the following formats are supported:

    * a `pid`
    * an `atom` if the server is locally registered
    * `{atom, node}` if the server is locally registered at another node
    * `{:global, term}` if the server is globally registered
    * `{:via, module, name}` if the server is registered through an alternative
      registry

  ## Client / Server APIs

  Although in the example above we have used `GenStateMachine.start_link/3` and
  friends to directly start and communicate with the server, most of the
  time we don't call the `GenStateMachine` functions directly. Instead, we wrap
  the calls in new functions representing the public API of the server.

  Here is a better implementation of our Switch module:

      defmodule Switch do
        use GenStateMachine

        # Client

        def start_link() do
          GenStateMachine.start_link(Switch, {:off, 0})
        end

        def flip(pid) do
          GenStateMachine.cast(pid, :flip)
        end

        def get_count(pid) do
          GenStateMachine.call(pid, :get_count)
        end

        # Server (callbacks)

        def handle_event(:cast, :flip, :off, data) do
          {:next_state, :on, data + 1}
        end

        def handle_event(:cast, :flip, :on, data) do
          {:next_state, :off, data}
        end

        def handle_event({:call, from}, :get_count, state, data) do
          {:next_state, state, data, [{:reply, from, data}]}
        end

        def handle_event(event_type, event_content, state, data) do
          # Call the default implementation from GenStateMachine
          super(event_type, event_content, state, data)
        end
      end

  In practice, it is common to have both server and client functions in
  the same module. If the server and/or client implementations are growing
  complex, you may want to have them in different modules.

  ## Receiving custom messages

  The goal of a `GenStateMachine` is to abstract the "receive" loop for
  developers, automatically handling system messages, support code change,
  synchronous calls and more. Therefore, you should never call your own
  "receive" inside the GenServer callbacks as doing so will cause the GenServer
  to misbehave. If you want to receive custom messages, they will be delivered
  to the usual handler for your callback mode with event_type `:info`.

  ## Learn more

  If you wish to find out more about gen_statem, the documentation and links
  in Erlang can provide extra insight.

    * [`:gen_statem` module documentation](http://erlang.org/documentation/doc-8.0-rc1/lib/stdlib-3.0/doc/html/gen_statem.html)
    * [gen_statem Behaviour – OTP Design Principles](http://erlang.org/documentation/doc-8.0-rc1/doc/design_principles/statem.html)
  """

  @type state :: state_name | term

  @type state_name :: atom

  @type data :: term

  @type event_type ::
    {:call, GenServer.from} |
    :cast |
    :info |
    :timeout |
    :internal

  @type callback_mode :: :state_functions | :handle_event_function

  @type postpone :: boolean

  @type hibernate :: boolean

  @type event_timeout :: timeout

  @type reply_action :: {:reply, GenServer.from, term}

  @type reply_actions :: [reply_action] | reply_action

  @type event_content :: term

  @type action ::
    :postpone |
    {:postpone, postpone} |
    :hibernate |
    {:hibernate, hibernate} |
    event_timeout |
    {:timeout, event_timeout, event_content} |
    reply_action |
    {:next_event, event_type, event_content}

  @type actions :: [action] | action

  @type state_function_result ::
    {:next_state, state_name, data} |
    {:next_state, state_name, data, actions} |
    common_state_callback_result

  @type handle_event_result ::
    {:next_state, state, data} |
    {:next_state, state, data, actions} |
    common_state_callback_result

  @type common_state_callback_result ::
    :stop |
    {:stop, reason :: term} |
    {:stop, reason :: term, data} |
    {:stop_and_reply, reason :: term, reply_actions} |
    {:stop_and_reply, reason :: term, reply_actions, data} |
    {:keep_state, data} |
    {:keep_state, data, actions} |
    :keep_state_and_data |
    {:keep_state_and_data, actions}

  @callback init(args :: term) ::
    {:ok, state, data} |
    {:ok, state, data, actions} |
    {:stop, reason :: term} |
    :ignore

  @callback state_name(event_type, event_content, data) :: state_function_result

  @callback handle_event(event_type, event_content, state, data) :: handle_event_result

  @callback terminate(reason :: term, state, data) :: any

  @callback code_change(term | {:down, term}, state, data, extra :: term) ::
    {:ok, state, data} |
    {callback_mode, state, data} |
    reason :: term

  @callback format_status(:normal | :terminate, pdict_state_and_data :: list) :: term

  @optional_callbacks state_name: 3, handle_event: 4, format_status: 2

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

      @doc false
      def init(args) do
        case super(args) do
          {:ok, state, data} -> {@gen_statem_callback_mode, state, data}
          {:ok, state, data, actions} -> {@gen_statem_callback_mode, state, data, actions}
          other -> other
        end
      end

      @doc false
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

  @spec start_link(module, any, GenServer.options) :: GenServer.on_start
  def start_link(module, args, options \\ []) do
    name = options[:name]

    if name do
      name =
        if is_atom(name) do
          {:local, name}
        else
          name
        end

      :gen_statem.start_link(name, module, args, options)
    else
      :gen_statem.start_link(module, args, options)
    end
  end

  @spec start(module, any, GenServer.options) :: GenServer.on_start
  def start(module, args, options \\ []) do
    name = options[:name]

    if name do
      name =
        if is_atom(name) do
          {:local, name}
        else
          name
        end

      :gen_statem.start(name, module, args, options)
    else
      :gen_statem.start(module, args, options)
    end
  end

  @spec stop(GenServer.server, reason :: term, timeout) :: :ok
  def stop(server, reason \\ :normal, timeout \\ :infinity) do
    :gen_statem.stop(server, reason, timeout)
  end

  @spec call(GenServer.server, term, timeout) :: term
  def call(server, request, timeout \\ :infinity) do
    :gen_statem.call(server, request, timeout)
  end

  @spec cast(GenServer.server, term) :: :ok
  def cast(server, request) do
    :gen_statem.cast(server, request)
  end

  @spec reply([reply_action]) :: :ok
  def reply(replies) do
    :gen_statem.reply(replies)
  end

  @spec reply(GenServer.from, term) :: :ok
  def reply(client, reply) do
    :gen_statem.reply(client, reply)
  end
end
