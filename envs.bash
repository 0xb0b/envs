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
  local allowed_types=${ENVTYPES[@]}" t"
  if [[ -n $1 && ! " $allowed_types " =~ " ${1} " ]]; then
    allowed_types=$(printf ", %s" "${ENVTYPES[@]}")", t(ags)"
    printf "
list environments: unsupported environment type
usage: lsenv [<type>]
type is in {${allowed_types:2}} or blank to list all
"
    return 0
  fi

  if [[ $1 != "t" ]]; then
    local types
    if [[ -z $1 ]]; then
      types=${ENVTYPES[@]}
    else
      types=$1
    fi
    local envtype
    for envtype in $types
    do
      local envdirs=$(find $ENVSROOT/$envtype -maxdepth 1 -mindepth 1 -type d | sort)
      printf "
$envtype/
"
      local item
      for item in $envdirs
      do
        printf "    ${item##*/}\n"
      done
    done
  fi

  if [[ -z $1 || $1 = "t" ]]; then
    local tagfiles=$(find $ENVSROOT -maxdepth 1 -mindepth 1 -type f | sort)
    if [[ -n $tagfiles ]]; then
      printf "\n"
    fi
    local item
    for item in $tagfiles
    do
      local context=$(head -n 1 $item)
      printf "#${item##*/}: $context\n"
    done
  fi
}

mkenv() {
  if [[ -z $1 || -z $2 ]]; then
    local allowed_types=$(printf ", %s" "${ENVTYPES[@]}")", t(ags)"
    printf "
make environment
usage: mkenv <type> <name> [<parameters>]
type is in {${allowed_types:2}}
"
    return 0
  fi

  local envtype=$1
  local allowed_types=${ENVTYPES[@]}" t"
  if [[ ! " ${allowed_types} " =~ " ${envtype} " ]]; then
    allowed_types=$(printf ", %s" "${ENVTYPES[@]}")", t(ags)"
    printf "
make environment: unsupported environment type
usage: mkenv <type> <name> [<parameters>]
type is in {${allowed_types:2}}
"
    return 0
  fi

  if [[ -d $ENVSROOT/$envtype/$2 ]]; then
    printf "
make environment: environment already exists
"
    return 0
  fi

  if [[ $envtype = "t" ]]; then
    local active_envs=($ENVCONTEXT)
    if [[ ${#active_envs[@]} < 2 ]]; then
      printf "
make environment: more than one env has to be active to tag composite env
"
      return 0
    elif [[ -f $ENVSROOT/$2 ]]; then
      printf "
make environment: tag already exists
"
      return 0
    fi
    export ENVTAG=$2
cat <<EOF >$ENVSROOT/$2
$ENVCONTEXT
EOF
    printf "
make environment: done
"
  else
    mkenv_$envtype "${@:2}"
  fi
}

aenv() {
  if [[ -z $1 || -z $2 ]]; then
    local allowed_types=$(printf ", %s" "${ENVTYPES[@]}")", t(ags)"
    printf "
activate environment
usage: aenv <type> <name>
type is in {${allowed_types:2}}
"
    return 0
  fi

  local envtype=$1
  local allowed_types=${ENVTYPES[@]}" t"
  if [[ ! " ${allowed_types} " =~ " ${envtype} " ]]; then
    allowed_types=$(printf ", %s" "${ENVTYPES[@]}")", t(ags)"
    printf "
activate environment: unsupported environment type
usage: aenv <type> <name>
type is in {${allowed_types:2}}
"
    return 0
  fi

  local envname=$2
  if [[ ( $envtype = "t" && ! -f $ENVSROOT/$envname ) || ( $envtype != "t" && ! -d $ENVSROOT/$envtype/$envname ) ]]; then
    printf "
activate environment: environment does not exist, create it first with mkenv
"
    return 0
  fi

  if [[ -n $ENVCONTEXT ]]; then
    if [[ $envtype = "t" ]]; then
      printf "
activate environment: deactivate the active environment to activate the composite environment
"
      return 0
    fi
    # check if env type is already active
    local item
    for item in $ENVCONTEXT
    do
      if [[ $envtype = ${item%/*} ]]; then
        if [[ $envtype/$envname = $item ]]; then
          printf "
activate environment: $item is already active
"
        else
          printf "
activate environment: deactivate $item to replace it with $envtype/$envname
"
        fi
        return 0
      fi
    done
    unset ENVTAG
    export ENVCONTEXT="$ENVCONTEXT $envtype/$envname"
    aenv_$envtype $envname
  else
    (
      if [[ $envtype = "t" ]]; then
        local context=$(head -n 1 $ENVSROOT/$envname)
        local item
        for item in $context
        do
          aenv_${item%/*} ${item#*/}
        done
        export ENVTAG=$envname
        export ENVCONTEXT=$context
      else
        export ENVCONTEXT=$envtype/$envname
        aenv_$envtype $envname
      fi
      exec $SHELL
    )
  fi
}

# TODO add recycle bin and restore command
rmenv() {
  if [[ -z $1 || -z $2 ]]; then
    local allowed_types=$(printf ", %s" "${ENVTYPES[@]}")", t(ags)"
    printf "
remove environment
usage: rmenv <type> <name>
type is in {${allowed_types:2}}
"
    return 0
  fi

  local envtype=$1
  local allowed_types=${ENVTYPES[@]}" t"
  if [[ ! " ${allowed_types} " =~ " ${envtype} " ]]; then
    allowed_types=$(printf ", %s" "${ENVTYPES[@]}")", t(ags)"
    printf "
remove environment: unsupported environment type
usage: rmenv <type> <name>
type is in {${allowed_types:2}}
"
    return 0
  fi

  local envname=$2
  if [[ $envtype = "t" ]]; then
    if [[ $ENVTAG = $envname ]]; then
      printf "
remove environment: #$envname is active, deactivate to remove
"
      return 0
    fi
    if [[ ! -f $ENVSROOT/$envname ]]; then
      printf "
remove environment: environment not found
"
      return 0
    fi
    rm $ENVSROOT/$envname
  else
    local envdir=$ENVSROOT/$envtype/$envname
    if [[ ! -d $envdir ]]; then
      printf "
remove environment: environment not found
"
      return 0
    fi
    # check if env is active
    if [[ -n $ENVCONTEXT ]]; then
      local item
      for item in $ENVCONTEXT
      do
        if [[ $envtype/$envname = $item ]]; then
          printf "
remove environment: $item is active, deactivate to remove
"
          return 0
        fi
      done
    fi
    # TODO check if any composite env contains this env
    # check if any composite env has to be removed when removing this env
    # display a warning and a choice to proceed
    rm -rf $envdir
    printf "
remove environment: done
"
  fi
}

ps1_context() {
  if [[ -n $ENVCONTEXT ]]; then
    if [[ -n $ENVTAG ]]; then
      printf "
(#$ENVTAG)
"
    else
      printf "
($ENVCONTEXT)
"
    fi
  fi
}


# add the code of an environment type below
# environment type has to register itself to be visible
# environment type has to provide the following interface functions:
#    mkenv_<type>
#    aenv_<type>

source ~/proj/envs/nvim_env.bash
source ~/proj/envs/python_env.bash

