defmodule GenStateMachine.Translator do
  @moduledoc false

  @doc false
  # OTP21 and after
  def translate(min_level, :error, :report, {:logger, %{label: label} = report}) do
    case label do
      {:gen_statem, :terminate} ->
        do_translate(min_level, report)

      _ ->
        :none
    end
  end

  # OTP20 and before
  def translate(min_level, :error, :format, message) do
    opts = Application.get_env(:logger, :translator_inspect_opts)

    case message do
      {'** State machine ~tp terminating~n' ++ _ = format, args} ->
        do_translate(min_level, format, args, opts)

      {'** State machine ~p terminating~n' ++ _ = format, args} ->
        do_translate(min_level, format, args, opts)

      _ ->
        :none
    end
  end

  def translate(_min_level, _level, _kind, _message) do
    :none
  end

  # OTP21 and after
  defp do_translate(min_level, report) do
    inspect_opts = Application.get_env(:logger, :translator_inspect_opts)

    %{name: name, state: state} = report

    msg = ["GenStateMachine #{inspect(name)} terminating", statem_exception(report)]

    if min_level == :debug do
      msg = [msg, "\nState: ", inspect(state, inspect_opts)]
      {:ok, statem_debug(report, inspect_opts, msg)}
    else
      {:ok, msg}
    end
  end

  # OTP20 and before
  defp do_translate(min_level, format, args, opts) do
    keys =
      format
      |> to_string()
      |> String.split(~r/~tp|~p/, trim: true)
      |> Enum.flat_map(&map_key/1)

    args =
      [keys, args]
      |> List.zip()
      |> Map.new()

    msg = [
      "GenStateMachine #{inspect(args.name)} terminating"
      | statem_exception(args)
    ]

    if min_level == :debug do
      {:ok, statem_debug(args, opts, msg)}
    else
      {:ok, msg}
    end
  end

  # OTP21 and later
  defp statem_exception(%{reason: {class, reason, stack}}) do
    do_statem_exception(class, reason, stack)
  end

  # OTP20 and before
  defp statem_exception(%{class: class, reason: reason, stack: stack}) do
    do_statem_exception(class, reason, stack)
  end

  defp do_statem_exception(class, reason, stack) do
    formatted = Exception.format(class, reason, stack)
    [?\n | :erlang.binary_part(formatted, 0, byte_size(formatted) - 1)]
  end

  defp map_key(arg) do
    String.split(arg, ~r/\*\* |~n/, trim: true)
    |> Enum.filter(&(String.contains?(&1, "=") || String.contains?(&1, "State machine")))
    |> case do
      [] -> []
      ["State machine" <> _] -> [:name]
      ["Last event" <> _] -> [:last_event]
      ["When server state" <> _] -> [:state]
      ["Reason for termination" <> _] -> [:class, :reason]
      ["Callback mode" <> _] -> [:callback_mode]
      ["Stacktrace" <> _] -> [:stack]
      ["Queued" <> _] -> [:queued]
      ["Postponed" <> _] -> [:postponed]
    end
  end

  defp statem_debug(args, opts, msg) do
    [msg, Enum.map(Enum.sort(args), &translate_arg(&1, opts))]
  end

  defp translate_arg({:last_event, last_event}, opts),
    do: ["\nLast event: " | inspect(last_event, opts)]

  defp translate_arg({:state, state}, opts),
    do: ["\nState: " | inspect(state, opts)]

  defp translate_arg({:callback_mode, callback_mode}, opts),
    do: ["\nCallback mode: " | inspect(callback_mode, opts)]

  defp translate_arg({:queued, queued}, opts),
    do: ["\nQueued events: " | inspect(queued, opts)]

  defp translate_arg({:queue, [last | queued]}, opts),
    do: ["\nLast event: ", inspect(last, opts), "\nQueued events: " | inspect(queued, opts)]

  defp translate_arg({:postponed, postponed}, opts),
    do: ["\nPostponed events: " | inspect(postponed, opts)]

  defp translate_arg(_arg, _opts), do: []
end
