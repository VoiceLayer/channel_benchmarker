# ChannelBenchmarker

## NOTE This is a work in progress

This utility can be used to benchmark Phoenix Channels

## Running

This requires a compatible server. Currently this is
https://github.com/Gazler/phoenix_chat_example/tree/feat/channel-bench

You can run the server my doing:

```shell
git clone git@github.com:Gazler/phoenix_chat_example -b feat/channel-bench
cd phoenix_chat_example
mix deps.get
MIX_ENV=prod mix compile
PORT=4000 MIX_ENV=prod iex --erl "+A 100 +K true +P 1000000" -S mix phoenix.server
```

The benchmarker can be run with the following command:

    mix run bench.exs --channels 100 --messages 100 --users-per-channel 2 --format terminal

Please ensure users-per-channel is at least 2.

