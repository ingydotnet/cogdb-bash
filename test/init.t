#!/bin/bash

source test/setup
use Test::More

export COGDB_ROOT=test/test1-cog

cog=test/test1-cog

msg="`cogdb init $cog`"

like "$msg" 'Initialized empty Git repository in' \
  'init gives correct output'

ok "`[ -d $cog/node ]`" \
  "$cog/node directory exists"

done_testing
