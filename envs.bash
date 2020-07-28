# https://datagrok.org/python/activate/

# main idea: start a subshell instead of "source <env path>/bin/activate"

# envs are orthogonal - they can be combined into any composition and do not
# depend on each other

# composite env is equivalent to several simple envs activated in sequence
# it is a reference to an aggregated environment under a single name,
# it allows to activate a set of envs quickly

# envs composition operator (envs addition) is commutative - the resulting
# composite env is equivalent to any other composite env with the changed
# components order

# an activated set of envs can be made a composite env by a command
#     this is the only way to make a composite env


export ENVSROOT=$HOME/.env
if [[ ! -d $ENVSROOT ]]; then
  mkdir $ENVSROOT
fi

register_type() {
  if [[ ! " ${ENVTYPES[@]} " =~ " ${1} " ]]; then
    export ENVTYPES+=($1)
  fi
}

# TODO add listing and starting envs with fzf
lsenv() {
  if [[ -z $1 || $1 = "all" ]]; then
    local types=${ENVTYPES[@]}
  else
    if [[ -d $ENVSROOT/$1 ]]; then
      local types=$1
    else
      local types=$(printf ", %s" "${ENVTYPES[@]}")
      echo "
list environments: unsupported environment type
usage: lsenv [<type>]
type is in {all (default)$types}"
      return 0
    fi
  fi
  local envtype
  for envtype in $types
  do
    local envdirs=$(find $ENVSROOT/$envtype -maxdepth 1 -mindepth 1 -type d | sort)
    echo "
$envtype/"
    local item
    for item in $envdirs
    do
      echo "    ${item##*/}"
    done
  done
}

mkenv() {
  if [[ -z $1 || -z $2 ]]; then
    local types=$(printf ", %s" "${ENVTYPES[@]}")
    echo "
make environment
usage: mkenv <type> <name> [<parameters>]
type is in {${types:2}}"
    return 0
  fi

  local envtype=$1
  if [[ ! " ${ENVTYPES[@]} " =~ " ${envtype} " ]]; then
    local types=$(printf ", %s" "${ENVTYPES[@]}")
    echo "
make environment: unsupported environment type
usage: mkenv <type> <name> [<parameters>]
type is in {${types:2}}"
    return 0
  fi

  local envdir=$ENVSROOT/$envtype/$2
  if [[ -d $envdir ]]; then
    echo "
make environment: environment already exists"
    return 0
  fi

  mkenv_$envtype "${@:2}"
  echo "
make environment: done"
}

aenv() {
  if [[ -z $1 || -z $2 ]]; then
    local types=$(printf ", %s" "${ENVTYPES[@]}")
    echo "
activate environment
usage: aenv <type> <name>
type is in {${types:2}}"
    return 0
  fi

  local envtype=$1
  if [[ ! " ${ENVTYPES[@]} " =~ " ${envtype} " ]]; then
    local types=$(printf ", %s" "${ENVTYPES[@]}")
    echo "
activate environment: unsupported environment type
usage: aenv <type> <name>
type is in {${types:2}}"
    return 0
  fi

  local envname=$2
  local envdir=$ENVSROOT/$envtype/$envname
  if [[ ! -d $envdir ]]; then
    echo "
activate environment: environment does not exist, create it first with mkenv"
    return 0
  fi

  if [[ -n $ENVCONTEXT ]]; then
    # check if env type is already active
    local item
    for item in $ENVCONTEXT
    do
      if [[ $envtype == ${item%/*} ]]; then
        if [[ $envtype/$envname == $item ]]; then
          echo "
activate environment: $item is already active"
        else
          echo "
activate environment: $item is active
deactivate and reactivate to replace it with $envtype/$envname"
        fi
        return 0
      fi
    done
    export ENVCONTEXT="$ENVCONTEXT $envtype/$envname"
    aenv_$envtype $envname
  else
    (
      export ENVCONTEXT=$envtype/$envname
      aenv_$envtype $envname
      exec $SHELL
    )
  fi
}

# TODO add recycle bin and restore command
rmenv() {
  if [[ -z $1 || -z $2 ]]; then
    local types=$(printf ", %s" "${ENVTYPES[@]}")
    echo "
remove environment
usage: rmenv <type> <name>
type is in {${types:2}}"
    return 0
  fi

  local envtype=$1
  if [[ ! " ${ENVTYPES[@]} " =~ " ${envtype} " ]]; then
    local types=$(printf ", %s" "${ENVTYPES[@]}")
    echo "
remove environment: unsupported environment type
usage: rmenv <type> <name>
type is in {${types:2}}"
    return 0
  fi

  local envname=$2
  local envdir=$ENVSROOT/$envtype/$envname
  if [[ -d $envdir ]]; then
    # check if env is active
    if [[ -n $ENVCONTEXT ]]; then
      local item
      for item in $ENVCONTEXT
      do
        if [[ $envtype/$envname == $item ]]; then
          echo "
remove environment: $item is active, deactivate to remove"
          return 0
        fi
      done
    fi
    rm -rf $envdir
    echo "
remove environment: done"
  else
    echo "
remove environment: environment not found"
  fi
}

ps1_context() {
  if [[ -n "$ENVCONTEXT" ]]; then
    echo "
($ENVCONTEXT)"
  fi
}


# add the code of an environment type below
# environment type has to register itself to be visible
# environment type has to provide the following interface functions:
#    mkenv_<type>
#    aenv_<type>

source ~/proj/envs/nvim_env.bash
source ~/proj/envs/python_env.bash

