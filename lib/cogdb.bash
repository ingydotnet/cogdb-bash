CogDB:main() {
  # "global" variables:
  local bin=
  local cmd= args=() editor= quiet=false
  local node_id= node_path=

  # Setup everything:
  CogDB:init "$@"
  CogDB:get-options "$@"
  CogDB:assert-env

  # Run the commandline command:
  "CogDB::Command:$cmd" "${args[@]}"
}

CogDB:init() {
  # Assert COGDB_ROOT
  : ${COGDB_ROOT:=$PWD}
  COGDB_ROOT="`abspath $COGDB_ROOT`"
  # Sanity check:
  if [ -z "$COGDB_ROOT" ] || [[ $COGDB_ROOT =~ [\ \(\)] ]]; then
    die "'$COGDB_ROOT' doesn't seem to be a valid COGDB_ROOT"
  fi

  local binpath="`abspath $0`"
  bin="${binpath##*/}"
  binpath="${binpath%/*}"
  local bashplus_bin="`abspath "$binpath/../../bashplus/bin"`"

  if [ ! -d "$COGDB_ROOT" ]; then
    [ "$1" == init ] ||
      die "'$COGDB_ROOT' does not exist and command is not 'init'"
    mkdir -p "$COGDB_ROOT"
  fi
  cd "$COGDB_ROOT"

  GIT_WORK_TREE="$COGDB_ROOT"
  GIT_DIR=".cog"
  COGDB_SRC="`abspath $binpath/..`"
  editor="${COGDB_EDITOR:-${EDITOR:-vim}}"

  export COGDB_ROOT COGDB_SRC
  export GIT_WORK_TREE GIT_DIR
}

CogDB:get-options() {
  args=()
  case "$1" in
  init|new|edit|publish) cmd=$1; shift;;
  *) die "Unknown '${0##*/}' command: '$1'";;
  esac

  for arg; do
    case "$arg" in
    -q) quiet=true;;
    *) args+=("$arg");;
    esac
  done
}

CogDB:assert-env() {
  if [ $cmd == init ]; then
    for d in $GIT_DIR node index; do
      [ -d $d ] && die "'$COGDB_ROOT' is already a COGDB_ROOT"
    done
  else
    for d in $GIT_DIR node index; do
      [ -d $d ] || die "'$COGDB_ROOT' is invalid COGDB_ROOT"
    done
  fi
  :
}

CogDB:edit-node() {
  local node_id="$1"
  local node_path="node/$node_id.cog"
  [ -f "$node_path" ] ||
    die "No such node: '$node_id'"
  "$editor" "$node_path"
}

CogDB:save-node() {
  # get old title
  old_title=`grep -E '^==' $node_path`
  # get file time stamp
  # edit file
  ${EDITOR:-vim} $node_path
  # return unless file changed
  # if title changed
  #   delete old title index
  #   add new title index
  # git commit
}

CogDB::new-id() {
  while true; do
    node_id=`cat /dev/urandom | tr -dc a-hj-np-z2-9 | head -c4`
    [[ $node_id =~ [a-z] ]] && [[ $node_id =~ [0-9] ]] &&
      [[ ! -f node/$node_id ]] && touch node/$node_id && return
  done
}

#------------------------------------------------------------------------------
# Commandline action methods:
#------------------------------------------------------------------------------

# Turn an empty directory into a cogdb:
CogDB::Command:init() {
  [ -z "`ls -A .`" ] ||
    die "$bin - Can't init '$COGDB_ROOT'. Directory not empty."
  git init > /dev/null
  mkdir node index conf template
  mkdir index/title index/name index/time index/tag
  touch ReadMe conf/cogdb.ini
  for d in node index/*; do
    touch $d/_
  done
  cp $COGDB_SRC/template/node.cog template/
  cp $COGDB_SRC/template/ReadMe ./
  cp $COGDB_SRC/template/cogdb.ini conf/
  git add . > /dev/null
  git commit -m 'Initialized new cogdb' > /dev/null
  say "Initialized new cogdb in '$COGDB_ROOT'"
}


CogDB::Command:new() {
  CogDB:new-id
  $edit_on_new && CogDB:edit-node
  say "Created new node: $node_id"
}

CogDB::Command:edit() {
  CogDB:find "$@"
  CogDB:edit "$node_id"
  CogDB:save
  if $changed; then
    say "CogDB node '$node_id' saved"
  elif $error; then
    prompt "Error: $error_msg. Press enter to fix, ctl-c to quit:"
    CogDB:Command:edit $node_id
  else
    say "No changes made."
  fi
}

CogDB::Command:publish() {
  git push &&
    say "CogDB published"
}

#------------------------------------------------------------------------------
# Helper functions:
#------------------------------------------------------------------------------
# XXX Find robust way to do in bash. Add to bash+.
abspath() { perl -MCwd -le 'print Cwd::abs_path(shift)' "$1"; }

say() {
  if ! $quiet; then
    echo "$1"
  fi
}
