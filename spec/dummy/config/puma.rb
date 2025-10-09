# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.

# Puma starts a single process to serve the application. This
# means that the application will not restart until the server
# is restarted.
# In development, it's recommended to use the default configuration,
# which starts a single process with a single thread.

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# workers ENV.fetch("WEB_CONCURRENCY") { 4 }

# Specifies that the worker count should be scaled based on the number of
# available CPU cores. This will dynamically set the worker count to
# the number of cores available.
# See https://github.com/puma/puma/blob/master/docs/architecture.md for more information.
#
# workers_per_cpu ENV.fetch("RAILS_MAX_THREADS") { 5 }

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT") { 3000 }

# Specifies the `environment` that Puma will run in.
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart
