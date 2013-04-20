# -*- sh -*-

promptway () {
  _prompt_way=
  local -a _result
  local -a _wwfmt _wdfmt _wdsymfmt
  local -a _is_bwenable _bwdfmt _bwwfmt _bwdsymfmt
  zstyle -a ":prompt:way" formats _wwfmt
  zstyle -a ":prompt:dir" formats _wdfmt
  zstyle -a ":prompt:dir:symlink" formats _wdsymfmt
  zstyle -a ":prompt:backward" enable _is_bwenable
  zstyle -a ":prompt:backward:dir" formats _bwdfmt
  zstyle -a ":prompt:backward:way" formats _bwwfmt
  zstyle -a ":prompt:backward:dir:symlink" formats _bwdsymfmt

  local BACKWARD_DIR
  # <---(A)--->                     ~~(a)~~
  # /fooo/baaar/piyo_piyo/hoge/fuga/foo-bar/rdi/rsi/raaax
  #             ~~~(b)~~~ <--(B)-->         <-(C)-> ~(c)~
  # A) working-way
  # a) working-dir
  # B) backward-upper-way
  # b) backward-upper-dir
  # C) backward-under-way
  # c) backward-under-dir
  local WORKING_WAY BACKWARD_UPPER_DIR BACKWARD_UPPER_WAY WORKING_DIR BACKWARD_UNDER_WAY BACKWARD_UNDER_DIR
  local A

  if [[ -n $_is_bwenable ]] && [[ -n ${dirstack[1]} ]]; then
    BACKWARD_DIR="${dirstack[1]}"
    BACKWARD_UPPER_DIR=$(echo "$BACKWARD_DIR" | pathf Dtb | _promptway_filter)
    BACKWARD_UPPER_WAY=$(echo "$BACKWARD_DIR" | pathf dtB | _promptway_filter)
    BACKWARD_UNDER_DIR=$(pwd | pathf dtb "$BACKWARD_DIR" | _promptway_filter)
    BACKWARD_UNDER_WAY=$(pwd | pathf dtB "$BACKWARD_DIR" | _promptway_filter)
  else
    BACKWARD_DIR=
  fi
  WORKING_DIR=$(echo "$BACKWARD_DIR" | pathf D | pathf dtb)
  A=${PWD%%$(eval echo "$BACKWARD_UPPER_DIR$BACKWARD_UPPER_WAY$WORKING_DIR")}
  WORKING_WAY=$(pathf t "$A" | _promptway_filter)
  WORKING_DIR=$(_promptway_filter "$WORKING_DIR")

  local -a _ww _bupd _bupw _wd _budw _budd

  A=$(_promptway_unslash "$WORKING_WAY")
  zformat -f _ww "$_wwfmt" a:"$A"
  A=$(_promptway_unslash "$WORKING_DIR")
  if [[ -L $PWD ]]; then
    zformat -f _wd "$_wdsymfmt" a:"$A"
  else
    zformat -f _wd "$_wdfmt" a:"$A"
  fi

  _prompt_way="$_prompt_way$_ww"$(_promptway_slash "$WORKING_WAY")

  if [[ -n $BACKWARD_UPPER_DIR ]] || [[ -n $BACKWARD_UPPER_WAY ]]; then
    A=$(_promptway_unslash "$BACKWARD_UPPER_DIR")
    if [ -L "$BACKWARD_DIR" ]; then
      zformat -f _bupd "$_bwdsymfmt" a:"$A"
    else
      zformat -f _bupd "$_bwdfmt" a:"$A"
    fi
    A=$(_promptway_unslash "$BACKWARD_UPPER_WAY")
    zformat -f _bupw "$_bwwfmt" a:"$A"
    _prompt_way="$_prompt_way$_bupd"$(_promptway_slash "$BACKWARD_UPPER_DIR")
    _prompt_way="$_prompt_way$_bupw"$(_promptway_slash "$BACKWARD_UPPER_WAY")
  fi

  _prompt_way="$_prompt_way$_wd"

  if [[ -n $BACKWARD_UNDER_WAY ]] || [[ -n $BACKWARD_UNDER_DIR ]]; then
    A=$(_promptway_unslash "$BACKWARD_UNDER_WAY")
    zformat -f _budw "$_bwwfmt" a:"$A"
    A=$(_promptway_unslash "$BACKWARD_UNDER_DIR")
    if [ -L "$BACKWARD_DIR" ]; then
      zformat -f _budd "$_bwdsymfmt" a:"$A"
    else
      zformat -f _budd "$_bwdfmt" a:"$A"
    fi
    _prompt_way=$_prompt_way$(_promptway_slash "$WORKING_DIR")
    _prompt_way=$_prompt_way$_budw$(_promptway_slash "$BACKWARD_UNDER_WAY")
    _prompt_way=$_prompt_way$_budd
    # _prompt_way=$_prompt_way_$(_promptway_slash "$BACKWARD_UNDER_DIR")
  fi

  _promptway_backward
}

_promptway_backward () {
  _prompt_backward=
  local -a _is_bwenable _bwdfmt _bwwfmt
  zstyle -a ":prompt:backward" enable _is_bwenable
  zstyle -a ":prompt:backward:dir" formats _bwdfmt
  zstyle -a ":prompt:backward:way" formats _bwwfmt

  if [[ -z $_is_bwenable ]]; then
    return 0
  fi

  local relapath dirname basename WORKING_DIR BACKWARD_DIR
  local _budw _budd
  local A

  if [ $# -eq 0 ]; then
    WORKING_DIR=$PWD
    BACKWARD_DIR=$dirstack[1]
  fi

  if [[ -z $WORKING_DIR ]] || [[ -z $BACKWARD_DIR ]]; then
    return 0
  fi

  if which grealpath > /dev/null 2>&1; then
    relapath=`grealpath --no-symlinks --relative-to="$WORKING_DIR" "$BACKWARD_DIR"`
  else
    relapath=`realpath --no-symlinks --relative-to="$WORKING_DIR" "$BACKWARD_DIR"`
  fi

  case $relapath in
    *../*)
      case ${relapath##*../} in
        . | ..)
          return 0;;
        *)
          dirname=$(pathf Bt "$BACKWARD_DIR" | _promptway_filter)
          basename=$(pathf bt "$BACKWARD_DIR")
	  A=$(_promptway_unslash "$dirname")
	  zformat -f _budw "$_bwwfmt" a:"$A"
	  A=$(_promptway_unslash "$basename")
	  zformat -f _budd "$_bwdfmt" a:"$A"
	  _prompt_backward=$_budw$(_promptway_slash "$dirname")$_budd
    esac;;
  esac
}

_promptway_filter () {
  local w

  if [ $# -eq 0 ]; then
    read w
  else
    w=$1; shift
  fi

  if [ -n "$w" ] && \
     [ "$w" != "." ] && \
     [ "$w" != "/" ]; then
    echo "$w/"
  elif [ "$w" = "/" ]; then
    echo /
  else
    echo ""
  fi
}

_promptway_unslash () {
  local w

  if [ $# -eq 0 ]; then
    read w
  else
    w=$1; shift
  fi

  if [ "$w" = "/" ]; then
    echo /
  else
    echo "${w%%/}"
  fi
}

_promptway_slash () {
  local w

  if [ $# -eq 0 ]; then
    read w
  else
    w=$1; shift
  fi

  if [ -n "$w" ] && \
     [ "$w" != "/" ]; then
    echo /
  elif [ "$w" = "/" ]; then
    echo ""
  else
    echo ""
  fi
}
