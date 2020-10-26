[![Elixir CI](https://github.com/ericentin/gen_state_machine/workflows/Elixir%20CI/badge.svg)](https://github.com/ericentin/gen_state_machine/actions?query=workflow%3A%22Elixir+CI%22)

# GenStateMachine

An idiomatic Elixir wrapper for `gen_statem` in OTP 20 (and above).

**Full documentation is available [here](https://hexdocs.pm/gen_state_machine).**

**You can find the package on Hex [here](https://hex.pm/packages/gen_state_machine).**

One important difference between `gen_statem` and this wrapper is that you
declare your callback mode as part of `use GenStateMachine` in this wrapper,
rather than returning it from `callback_mode/0`.

Other than that (and the usual automatically-defined default callbacks as a
result of `use`-ing `GenStateMachine`), this wrapper does not make any
functional alterations.

This wrapper also provides a OTP error translator for `Logger`, which is
automatically added when the `:gen_state_machine` application is started.
Optionally, you may add `:gen_state_machine` to `:included_applications` rather
than `:applications` as indicated below if you do not want the translator to be
added to `Logger`.

## Installation

  1. Add `gen_state_machine` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:gen_state_machine, "~> 3.0"}]
  end
  ```

  2. Ensure `gen_state_machine` is added to your applications:

  ```elixir
  def application do
    [applications: [:gen_state_machine]]
  end
  ```

## Special Thanks

I would like to give special thanks to @fishcakez and @michalmuskala, who both
provided invaluable feedback on this library!
