defmodule GenStateMachine do
  @moduledoc """
  A behaviour module for implementing a state machine.

  The advantage of using this module is that it will have a standard set of
  interface functions and include functionality for tracing and error reporting.
  It will also fit into a supervision tree.

  ## Example

  The `GenStateMachine` behaviour abstracts the state machine. Developers are only
  required to implement the callbacks and functionality they are interested in.

  Let's start with a code example and then explore the available callbacks.
  Imagine we want a `GenStateMachine` that works like a switch, allowing us to
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
  server implementation and its initial argument, a tuple where the first element
  is the initial state and the second is the initial data. We can primarily
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
        def off({:call, from}, :get_count, data) do
          {:keep_state_and_data, [{:reply, from, data}]}
        end

        def on(:cast, :flip, data) do
          {:next_state, :off, data}
        end
        def on({:call, from}, :get_count, data) do
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
  with the server implementation and its initial argument, and interacting with
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

  It is important to note that the default implementation of the `code_change/4`
  callback results in an `:undefined` error. This is because `code_change/4` is
  related to the quite difficult topic of hot upgrades, and if you need it, you
  should really be implementing it yourself. In normal use this callback will
  not be invoked.

  ## State Enter Callbacks

  If you wish, you can register to receive callbacks when you enter a state by
  adding `:state_enter` to your `callback_mode`:

      defmodule Switch do
        use GenStateMachine, callback_mode: [:handle_event_function, :state_enter]

        def handle_event(:enter, _event, state, data) do
          {:next_state, state, %{data | enters: data.enters + 1}}
        end

        def handle_event(:cast, :flip, :off, data) do
          {:next_state, :on, %{data | flips: data.flips + 1}}
        end

        def handle_event(:cast, :flip, :on, data) do
          {:next_state, :off, data}
        end

        def handle_event({:call, from}, :get_count, _state, data) do
          {:keep_state_and_data, [{:reply, from, data}]}
        end
      end

      # Start the server
      {:ok, pid} = GenStateMachine.start_link(Switch, {:off, %{enters: 0, flips: 0}})

      # This is the client
      GenStateMachine.cast(pid, :flip)
      GenStateMachine.cast(pid, :flip)
      #=> :ok

      GenStateMachine.call(pid, :get_count)
      #=> %{enters: 3, flips: 1}

  See the Erlang [documentation](https://erlang.org/doc/man/gen_statem.html#type-state_enter)
  for more details.

  ## Name Registration

  Both `start_link/3` and `start/3` support registering the `GenStateMachine`
  under a given name on start via the `:name` option. Registered names are also
  automatically cleaned up on termination. The supported values are:

    * an atom - the `GenStateMachine` is registered locally with the given name
      using `Process.register/2`.

    * `{:global, term}`- the `GenStateMachine` is registered globally with the
      given term using the functions in the `:global` module.

    * `{:via, module, term}` - the `GenStateMachine` is registered with the given
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
  "receive" inside the `GenStateMachine` callbacks as doing so will cause the
  `GenStateMachine` to misbehave. If you want to receive custom messages, they
  will be delivered to the usual handler for your callback mode with event_type
  `:info`.

  ## Learn more

  If you wish to find out more about gen_statem, the documentation and links
  in Erlang can provide extra insight.

    * [`:gen_statem` module documentation](http://erlang.org/doc/man/gen_statem.html)
    * [gen_statem Behaviour – OTP Design Principles](http://erlang.org/doc/design_principles/statem.html)
  """

  @typedoc """
  The term representing the current state.

  In `:handle_event_function` callback mode, any term.

  In `:state_functions` callback mode, an atom.
  """
  @type state :: state_name | term

  @typedoc """
  The atom representing the current state in `:state_functions` callback mode.
  """
  @type state_name :: atom

  @typedoc """
  The persistent data (similar to a GenServer's `state`) for the GenStateMachine.
  """
  @type data :: term

  @typedoc """
  The source of the current event.

  `{:call, from}` will be received as a result of a call.

  `:cast` will be received as a result of a cast.

  `:info` will be received as a result of any regular process messages received.

  `:timeout` or `{:timeout, name}` will be received as a result of a `:timeout` action.

  `:state_timeout` will be received as a result of a `:state_timeout` action.

  `:internal` will be received as a result of a `:next_event` action.

  See the Erlang
  [documentation](https://erlang.org/doc/man/gen_statem.html#type-event_type)
  for details.
  """
  @type event_type :: :gen_statem.event_type()

  @typedoc """
  The callback mode for the GenStateMachine.

  See the Example section above for more info.
  """
  @type callback_mode_result :: :gen_statem.callback_mode_result()

  @typedoc """
  The message content received as the result of an event.
  """
  @type event_content :: term

  @typedoc """
  State transition actions.

  They may be invoked by returning them from a state function or init/1.

  If present in a list of actions, they are executed in order, and any that set
  transition options (postpone, hibernate, and timeout) override any previously
  provided options of the same type.

  If the state changes, the queue of incoming events is reset to start with the
  oldest postponed.

  All events added as a result of a `:next_event` action are inserted in the
  queue to be processed before all other events. An event of type `:internal`
  should be used when you want to reliably distinguish an event inserted this
  way from an external event.

  See the Erlang
  [documentation](https://erlang.org/doc/man/gen_statem.html#type-action)
  for the possible values.
  """
  @type action :: :gen_statem.action()

  @typedoc """
  The return type of an event handler function.

  See the Erlang [documentation](https://erlang.org/doc/man/gen_statem.html#type-event_handler_result)
  for a complete reference.
  """
  @type event_handler_result(state) :: :gen_statem.event_handler_result(state)

  @typedoc """
  The return type of a state enter function.

  See the Erlang [documentation](https://erlang.org/doc/man/gen_statem.html#type-state_enter_result)
  for a complete reference.
  """
  @type state_enter_result(state) :: :gen_statem.state_enter_result(state)

  @typedoc """
  The return type when the server is started.

  See the Erlang [documentation](https://erlang.org/doc/man/gen_statem.html#type-start_ret)
  for a complete reference.
  """
  @type on_start :: :gen_statem.start_ret()

  @typedoc """
  The type of allowed server names.

  See the Erlang [documentation](https://erlang.org/doc/man/gen_statem.html#type-server_ref)
  for a complete reference.
  """
  @type server_ref :: :gen_statem.server_ref()

  @doc """
  Invoked when the server is started. `start_link/3` (or `start/3`) will
  block until it returns.

  `args` is the argument term (second argument) passed to `start_link/3`.

  Returning `{:ok, state, data}` will cause `start_link/3` to return
  `{:ok, pid}` and the process to enter its loop.

  Returning `{:ok, state, data, actions}` is similar to `{:ok, state}`
  except the provided actions will be executed.

  Returning `:ignore` will cause `start_link/3` to return `:ignore` and the
  process will exit normally without entering the loop or calling `terminate/2`.
  If used when part of a supervision tree the parent supervisor will not fail
  to start nor immediately try to restart the `GenStateMachine`. The remainder
  of the supervision tree will be (re)started and so the `GenStateMachine`
  should not be required by other processes. It can be started later with
  `Supervisor.restart_child/2` as the child specification is saved in the parent
  supervisor. The main use cases for this are:

    * The `GenStateMachine` is disabled by configuration but might be enabled
      later.
    * An error occurred and it will be handled by a different mechanism than the
     `Supervisor`. Likely this approach involves calling
     `Supervisor.restart_child/2` after a delay to attempt a restart.

  Returning `{:stop, reason}` will cause `start_link/3` to return
  `{:error, reason}` and the process to exit with reason `reason` without
  entering the loop or calling `terminate/2`.

  This function can optionally throw a result to return it.
  """
  @callback init(args :: term) :: :gen_statem.init_result(state)

  @doc """
  Whenever a `GenStateMachine` in callback mode `:state_functions` receives a
  call, cast, or normal process message, a state function is called.

  This spec exists to document the callback, but in actual use the name of the
  function is probably not going to be `state_name`. Instead, there will be at
  least one state function named after each state you wish to handle. See the
  Examples section above for more info.

  These functions can optionally throw a result to return it.

  See the Erlang [documentation](https://erlang.org/doc/man/gen_statem.html#Module:StateName-3)
  for a complete reference.
  """
  @callback state_name(:enter, old_state_name :: state_name, data) ::
              state_enter_result(state_name)
  @callback state_name(event_type, event_content, data) :: event_handler_result(state_name)

  @doc """
  Whenever a `GenStateMachine` in callback mode `:handle_event_function` (the
  default) receives a call, cast, or normal process messsage, this callback will
  be invoked.

  This function can optionally throw a result to return it.

  See the Erlang [documentation](https://erlang.org/doc/man/gen_statem.html#Module:handle_event-4)
  for a complete reference.
  """
  @callback handle_event(:enter, old_state :: state, state, data) :: state_enter_result(state)
  @callback handle_event(event_type, event_content, state, data) :: event_handler_result(state)

  @doc """
  Invoked when the server is about to exit. It should do any cleanup required.

  `reason` is exit reason, `state` is the current state, and `data` is the
  current data of the `GenStateMachine`. The return value is ignored.

  `terminate/2` is called if a callback (except `init/1`) returns a `:stop`
  tuple, raises, calls `Kernel.exit/1` or returns an invalid value. It may also
  be called if the `GenStateMachine` traps exits using `Process.flag/2` *and*
  the parent process sends an exit signal.

  If part of a supervision tree a `GenStateMachine`'s `Supervisor` will send an
  exit signal when shutting it down. The exit signal is based on the shutdown
  strategy in the child's specification. If it is `:brutal_kill` the
  `GenStateMachine` is killed and so `terminate/2` is not called. However if it
  is a timeout the `Supervisor` will send the exit signal `:shutdown` and the
  `GenStateMachine` will have the duration of the timeout to call `terminate/2`
  - if the process is still alive after the timeout it is killed.

  If the `GenStateMachine` receives an exit signal (that is not `:normal`) from
  any process when it is not trapping exits it will exit abruptly with the same
  reason and so not call `terminate/2`. Note that a process does *NOT* trap
  exits by default and an exit signal is sent when a linked process exits or its
  node is disconnected.

  Therefore it is not guaranteed that `terminate/2` is called when a
  `GenStateMachine` exits. For such reasons, we usually recommend important
  clean-up rules to happen in separated processes either by use of monitoring or
  by links themselves. For example if the `GenStateMachine` controls a `port`
  (e.g. `:gen_tcp.socket`) or `File.io_device`, they will be closed on receiving
  a `GenStateMachine`'s exit signal and do not need to be closed in
  `terminate/2`.

  If `reason` is not `:normal`, `:shutdown` nor `{:shutdown, term}` an error is
  logged.

  This function can optionally throw a result, which is ignored.
  """
  @callback terminate(reason :: term, state, data) :: any

  @doc """
  Invoked to change the state of the `GenStateMachine` when a different version
  of a module is loaded (hot code swapping) and the state and/or data's term
  structure should be changed.

  `old_vsn` is the previous version of the module (defined by the `@vsn`
  attribute) when upgrading. When downgrading the previous version is wrapped in
  a 2-tuple with first element `:down`. `state` is the current state of the
  `GenStateMachine`, `data` is the current data, and `extra` is any extra data
  required to change the state.

  Returning `{:ok, new_state, new_data}` changes the state to `new_state`, the
  data to `new_data`, and the code change is successful.

  Returning `reason` fails the code change with reason `reason` and the state
  and data remains the same.

  If `code_change/4` raises the code change fails and the loop will continue
  with its previous state. Therefore this callback does not usually contain side
  effects.

  This function can optionally throw a result to return it.
  """
  @callback code_change(old_vsn :: term | {:down, vsn :: term}, state, data, extra :: term) ::
              {:ok, state, data}
              | (reason :: term)

  @doc """
  Invoked in some cases to retrieve a formatted version of the `GenStateMachine`
  status.

  This callback can be useful to control the *appearance* of the status of the
  `GenStateMachine`. For example, it can be used to return a compact
  representation of the `GenStateMachines`'s state/data to avoid having large
  terms printed.

    * one of `:sys.get_status/1` or `:sys.get_status/2` is invoked to get the
      status of the `GenStateMachine`; in such cases, `reason` is `:normal`

    * the `GenStateMachine` terminates abnormally and logs an error; in such cases,
      `reason` is `:terminate`

  `pdict_state_and_data` is a three-element list `[pdict, state, data]` where
  `pdict` is a list of `{key, value}` tuples representing the current process
  dictionary of the `GenStateMachine`, `state` is the current state of the
  `GenStateMachine`, and `data` is the current data.

  This function can optionally throw a result to return it.
  """
  @callback format_status(reason :: :normal | :terminate, pdict_state_and_data :: list) :: term

  @optional_callbacks state_name: 3, handle_event: 4, format_status: 2

  @doc false
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour GenStateMachine

      {callback_mode, opts} = Keyword.pop(opts, :callback_mode, :handle_event_function)

      @doc false
      def callback_mode do
        unquote(Macro.escape(callback_mode))
      end

      @doc false
      def init({state, data}) do
        {:ok, state, data}
      end

      @doc false
      def terminate(_reason, _state, _data) do
        :ok
      end

      @doc false
      def code_change(_old_vsn, _state, _data, _extra) do
        :undefined
      end

      unless Module.get_attribute(__MODULE__, :doc) do
        @doc """
        Returns a specification to start this module under a supervisor.

        See `Supervisor`.
        """
      end

      def child_spec(init_arg) do
        Supervisor.child_spec(
          %{id: __MODULE__, start: {__MODULE__, :start_link, [init_arg]}},
          unquote(Macro.escape(opts))
        )
      end

      defoverridable init: 1, terminate: 3, code_change: 4, child_spec: 1

      if :handle_event_function in List.wrap(callback_mode) do
        @doc false
        def handle_event(_event_type, _event_content, _state, _data) do
          {:stop, :bad_event}
        end

        defoverridable handle_event: 4
      end
    end
  end

  @doc """
  Starts a `GenStateMachine` process linked to the current process.

  This is often used to start the `GenStateMachine` as part of a supervision
  tree.

  Once the server is started, the `init/1` function of the given `module` is
  called with `args` as its arguments to initialize the server. To ensure a
  synchronized start-up procedure, this function does not return until `init/1`
  has returned.

  Note that a `GenStateMachine` started with `start_link/3` is linked to the
  parent process and will exit in case of crashes from the parent. The
  `GenStateMachine` will also exit due to the `:normal` reasons in case it is
  configured to trap exits in the `init/1` callback.

  ## Options

    * `:name` - used for name registration as described in the "Name
      registration" section of the module documentation

    * `:timeout` - if present, the server is allowed to spend the given amount of
      milliseconds initializing or it will be terminated and the start function
      will return `{:error, :timeout}`

    * `:debug` - if present, the corresponding function in the [`:sys`
      module](http://www.erlang.org/doc/man/sys.html) is invoked

    * `:spawn_opt` - if present, its value is passed as options to the
      underlying process as in `Process.spawn/4`

  ## Return values

  If the server is successfully created and initialized, this function returns
  `{:ok, pid}`, where `pid` is the pid of the server. If a process with the
  specified server name already exists, this function returns
  `{:error, {:already_started, pid}}` with the pid of that process.

  If the `init/1` callback fails with `reason`, this function returns
  `{:error, reason}`. Otherwise, if it returns `{:stop, reason}`
  or `:ignore`, the process is terminated and this function returns
  `{:error, reason}` or `:ignore`, respectively.
  """
  @spec start_link(module, any, GenServer.options()) :: on_start()
  def start_link(module, args, options \\ []) do
    {name, options} = Keyword.pop(options, :name)

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

  @doc """
  Starts a `GenStateMachine` process without links (outside of a supervision
  tree).

  See `start_link/3` for more information.
  """
  @spec start(module, any, GenServer.options()) :: on_start()
  def start(module, args, options \\ []) do
    {name, options} = Keyword.pop(options, :name)

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

  @doc """
  Stops the server with the given `reason`.

  The `terminate/2` callback of the given `server` will be invoked before
  exiting. This function returns `:ok` if the server terminates with the
  given reason; if it terminates with another reason, the call exits.

  This function keeps OTP semantics regarding error reporting.
  If the reason is any other than `:normal`, `:shutdown` or
  `{:shutdown, _}`, an error report is logged.
  """
  @spec stop(server_ref(), reason :: term, timeout) :: :ok
  def stop(server, reason \\ :normal, timeout \\ :infinity) do
    :gen_statem.stop(server, reason, timeout)
  end

  @doc """
  Makes a synchronous call to the `server` and waits for its reply.

  The client sends the given `request` to the server and waits until a reply
  arrives or a timeout occurs. The appropriate state function will be called on
  the server to handle the request.

  `server` can be any of the values described in the "Name registration"
  section of the documentation for this module.

  ## Timeouts

  `timeout` is an integer greater than zero which specifies how many
  milliseconds to wait for a reply, or the atom `:infinity` to wait
  indefinitely. The default value is `:infinity`. If no reply is received within
  the specified time, the function call fails and the caller exits.

  If the caller catches an exit, to avoid getting a late reply in the caller's
  inbox, this function spawns a proxy process that does the call. A late reply
  gets delivered to the dead proxy process, and hence gets discarded. This is
  less efficient than using `:infinity` as a timeout.
  """
  @spec call(server_ref(), term, timeout) :: term
  def call(server, request, timeout \\ :infinity) do
    :gen_statem.call(server, request, timeout)
  end

  @doc """
  Sends an asynchronous request to the `server`.

  This function always returns `:ok` regardless of whether
  the destination `server` (or node) exists. Therefore it
  is unknown whether the destination `server` successfully
  handled the message.

  The appropriate state function will be called on the server to handle
  the request.
  """
  @spec cast(server_ref(), term) :: :ok
  def cast(server, request) do
    :gen_statem.cast(server, request)
  end

  @doc """
  Sends replies to clients.

  Can be used to explicitly send replies to multiple clients.

  This function always returns `:ok`.

  See `reply/2` for more information.
  """
  @spec reply([:gen_statem.reply_action()] | :gen_statem.reply_action()) :: :ok
  def reply(replies) do
    :gen_statem.reply(replies)
  end

  @doc """
  Replies to a client.

  This function can be used to explicitly send a reply to a client that called
  `call/3` when the reply cannot be specified in the return value of a state
  function.

  `client` must be the `from` element of the event type accepted by state
  functions. `reply` is an arbitrary term which will be given
  back to the client as the return value of the call.

  Note that `reply/2` can be called from any process, not just the one
  that originally received the call (as long as that process communicated the
  `from` argument somehow).

  This function always returns `:ok`.

  ## Examples

      def handle_event({:call, from}, :reply_in_one_second, state, data) do
        Process.send_after(self(), {:reply, from}, 1_000)
        :keep_state_and_data
      end

      def handle_event(:info, {:reply, from}, state, data) do
        GenStateMachine.reply(from, :one_second_has_passed)
      end

  """
  @spec reply(:gen_statem.from(), term) :: :ok
  def reply(client, reply) do
    :gen_statem.reply(client, reply)
  end
end
