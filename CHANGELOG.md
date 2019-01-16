# Changelog

## v2.0.5 (2019-01-16)

Typespec/code formatting changes for Elixir v1.8.

## v2.0.4 (2018-11-20)

Version check no longer fails on erts versions with greater than 3 components.

## v2.0.3 (2018-08-14)

Log translator no longer ignores messages on OTP 21+.

## v2.0.2 (2018-05-11)

* Fix typespecs for start_link.
* Translator refactor means more logs are translated than before, as well as more accurately.
* The `child_spec/1` callback (for Elixir v1.6 child specs) is now generated automatically.

## v2.0.1 (2017-09-05)

Fix typespecs for OTP 20+.

## v2.0.0 (2016-09-21)

Add support for OTP 19.1.

### Backwards incompatible changes

  * On OTP 19.1, if you returned a callback mode explicitly from `code_change/4`, you should now return `:ok` instead, which will use the configured callback mode.

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
