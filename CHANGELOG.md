# Changelog for v1.0

## v1.0.2 (2016-07-03)

Documentation spelling error fixed. Compilation warnings fixed.

## v1.0.1 (2016-06-23)

Minor doc punctuation error fixed, and docs regenerated with latest `ex_doc` so that optional callbacks are notated.

## v1.0.0 (2016-06-23)

### Backwards incompatible changes

  * `code_change/4` default implementation will now result in an error if it is invoked. This is because this callback is only related to hot code updates, and thus actually calling the default implementation of this callback is dangerous.

  Users of this library can implement a callback like:

  ```elixir
  def code_change(_old_vsn, state, data, _extra) do
    {:ok, state, data}
  end
  ```

  if they wish to keep the old behaviour.

  * `init/1` allowed callback modes as the first element of the return tuple. This is no longer allowed, and users of this library should return `:ok` instead.

### Enhancements

  * Added OTP error translator.

### Bug fixes

  * `init/1` and `code_change/4` did not actually allow you to throw a result previously. They now permit throwing results.
