# GenStateMachine

[![Elixir CI](https://github.com/ericentin/gen_state_machine/workflows/Elixir%20CI/badge.svg)](https://github.com/ericentin/gen_state_machine/actions?query=workflow%3A%22Elixir+CI%22)
[![Module Version](https://img.shields.io/hexpm/v/gen_state_machine.svg)](https://hex.pm/packages/gen_state_machine)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/gen_state_machine/)
[![Total Download](https://img.shields.io/hexpm/dt/gen_state_machine.svg)](https://hex.pm/packages/gen_state_machine)
[![License](https://img.shields.io/hexpm/l/gen_state_machine.svg)](https://github.com/ericentin/gen_state_machine/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/ericentin/gen_state_machine.svg)](https://github.com/ericentin/gen_state_machine/commits/master)

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

Add `:gen_state_machine` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:gen_state_machine, "~> 3.0"}]
end
```

Ensure `:gen_state_machine` is added to your applications:

```elixir
def application do
  [applications: [:gen_state_machine]]
end
```

## Special Thanks

I would like to give special thanks to @fishcakez and @michalmuskala, who both
provided invaluable feedback on this library!

## License

Copyright (c) 2016 Eric Entin

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
