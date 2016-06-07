# GenStateMachine

An idiomatic Elixir wrapper for `gen_statem` in OTP 19 (and above).

**Full documentation is available [here](https://hexdocs.pm/gen_state_machine).**

**You can find the package on Hex [here](https://hex.pm/packages/gen_state_machine).**

One important difference between `gen_statem` and this wrapper is that you
declare your callback mode as part of `use GenStateMachine` in this wrapper,
rather than returning it from your `init/1` and `code_change/4`. You can still,
however, switch callback modes in `code_change/4` by returning a callback mode.

Other than that (and the usual automatically-defined default callbacks as a
result of `use`-ing `GenStateMachine`), this wrapper does not make any
functional alterations.

## Installation

  1. Add `gen_state_machine` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:gen_state_machine, "~> 0.0.2"}]
    end
    ```

  2. Ensure `gen_state_machine` is added to your applications:

    ```elixir
    def application do
      [applications: [:gen_state_machine]]
    end
    ```
