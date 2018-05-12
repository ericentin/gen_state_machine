defmodule GenStateMachine.Translator do
  @moduledoc false

  @doc false
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
      | statem_exception(args, opts)
    ]

    if min_level == :debug do
      {:ok, statem_debug(args, opts, msg)}
    else
      {:ok, msg}
    end
  end

  defp statem_exception(args, _opts) do
    formatted = Exception.format(args.class, args.reason, args.stack)
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

  defp translate_arg({:postponed, postponed}, opts),
    do: ["\nPostponed events: " | inspect(postponed, opts)]

  defp translate_arg(_arg, _opts), do: []
end
