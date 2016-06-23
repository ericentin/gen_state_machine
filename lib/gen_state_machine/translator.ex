defmodule GenStateMachine.Translator do
  @moduledoc false

  @doc false
  def translate(min_level, :error, :format, message) do
    opts = Application.get_env(:logger, :translator_inspect_opts)

    case message do
      {'** State machine ~p terminating~n' ++ rest, [name | args]} ->
        msg = ["GenStateMachine #{inspect name} terminating" |
          statem_exception(rest, args, opts)]
        if min_level == :debug do
          {:ok, statem_debug(rest, args, opts, msg)}
        else
          {:ok, msg}
        end

      _ ->
        :none
    end
  end

  def translate(_min_level, _level, _kind, _message) do
    :none
  end

  defp statem_exception('** Last event = ~p~n' ++ rest, [_msg | args], opts) do
    statem_exception(rest, args, opts)
  end
  defp statem_exception(rest, [_state, class, reason | args], _) do
    stack = statem_stack(rest, args)
    formatted = Exception.format(class, reason, stack)
    [?\n | :erlang.binary_part(formatted, 0, byte_size(formatted)-1)]
  end

  defp statem_stack(rest, args) do
    case :string.str(rest, 'Stacktrace') do
      0 -> []
      _ -> List.last(args)
    end
  end

  defp statem_debug('** Last event = ~p~n' ++ rest, [last | args], opts, msg) do
    msg = [msg, "\nLast message: " | inspect(last, opts)]
    statem_debug(rest, args, opts, msg)
  end
  defp statem_debug('** When server state  = ~p~n' ++ rest, args, opts, msg) do
    [state | args] = args
    msg = [msg, "\nState: " | inspect(state, opts)]
    statem_debug(rest, args, opts, msg)
  end
  defp statem_debug('** Reason for termination = ~w:~p~n' ++ rest, args, opts, msg) do
    [_class, _reason | args] = args
    statem_debug(rest, args, opts, msg)
  end
  defp statem_debug('** Callback mode = ~p~n' ++ rest, args, opts, msg) do
    [mode | args] = args
    msg = [msg, "\nCallback mode: " | inspect(mode)]
    statem_debug(rest, args, opts, msg)
  end
  defp statem_debug('** Queued = ~p~n' ++ rest, [queue | args], opts, msg) do
    msg = [msg, "\nQueued messages: " | inspect(queue, opts)]
    statem_debug(rest, args, opts, msg)
  end
  defp statem_debug('** Postponed = ~p~n' ++ _, [postpone | _], opts, msg) do
    [msg, "\nPostponed messages: " | inspect(postpone, opts)]
  end
  defp statem_debug(_, _, _, msg) do
    msg
  end
end
