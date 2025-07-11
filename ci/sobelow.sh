#!/bin/sh
set -o errexit
set -o nounset
set -o xtrace

mix local.hex --force
mix local.rebar --force
mix sobelow --private --compact --exit High --ignore Config.Secrets,Config.HTTPS