# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for third-
# party users, it should be done in your mix.exs file.

# Sample configuration:
#
config :logger, :console,
level: :info,
format: "$date $time [$level] $metadata$message\n",
colors: [:enabled],
metadata: [:user_id]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

config :crawler,
bootstrap_node: { "router.bittorrent.com", 6881 },
node_id:        "3e3959057292785710e9",
info_hash:      "1619ecc9373c3639f4ee3e261638f29b33a6cbd6",
recv_timeout:   5000,
number_of_requests_per_torrent: 1000

## Database configuration
config :db,
user:     "bt_crawler",
pass:     "bt_crawler",
host:     "localhost",
database: "bt_crawler",
app_dir:  "priv/repo"
