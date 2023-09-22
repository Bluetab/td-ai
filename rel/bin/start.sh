#!/bin/sh

set -o errexit
set -o xtrace

export PHX_SERVER=true

bin/td_ai eval 'Elixir.TdAi.Release.migrate()'
bin/td_ai start
