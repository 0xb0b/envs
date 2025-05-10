# https://datagrok.org/python/activate/

# main idea: start a subshell instead of "source <env path>/bin/activate"

# envs are orthogonal - they can be combined into any composition and do not
# depend on each other.

# composite env is equivalent to several simple envs activated in a sequence.
# it is simply a reference to an aggregated environment under a single name
# that allows to activate a set of envs quickly.

# envs composition operator (envs addition) is commutative - the resulting
# composite env is equivalent to any other composite env with the changed
# order of the components.

# an activated set of envs can be made a composite env by a command,
# this is the only way to make a composite env.

# this script has to be sourced in .rc file of a shell.
# it is then executed when a subshell is started.


export ENVSROOT=$HOME/.env
if [[ ! -d $ENVSROOT ]]; then
  mkdir $ENVSROOT
fi

TAGTYPE="tag"
if [[ ! -d $ENVSROOT/$TAGTYPE ]]; then
  mkdir $ENVSROOT/$TAGTYPE
fi

export ENVTYPES=()

# register_type envtype
register_type() {
  if [[ ! " ${ENVTYPES[@]} " =~ " ${1} " ]]; then
    ENVTYPES+=($1)
  fi
}
# add the code of an environment type here
# environment type has to register itself to be visible
# environment type has to provide the following interface functions:
#    mkenv_<type>
source ~/proj/envs/nvim_env.sh
source ~/proj/envs/python_env.sh


# TODO add listing and starting envs with fzf
# lsenv [envtype]
lsenv() {
  local envtype=$1

  local allowed_types=(${ENVTYPES[@]} ${TAGTYPE})
  local allowed_types_str="${$(printf ", %s" $allowed_types):2}"
  if [[ -n $envtype && ! " ${allowed_types[@]} " =~ " ${envtype} " ]]; then
    printf "
list environments: unsupported environment type
usage: lsenv [<type>]
type is in {${allowed_types_str}} or blank to list all
"
    return 0
  fi

  if [[ $envtype != $TAGTYPE ]]; then
    local types=($ENVTYPES)
    if [[ -n $envtype ]]; then
      types=$envtype
    fi
    for item in $types
    do
      local envdirs=($(find $ENVSROOT/$item -maxdepth 1 -mindepth 1 -type d | sort))
      printf "
$item/
"
      for envdir in $envdirs
      do
        printf "    ${envdir##*/}\n"
      done
    done
  fi

  if [[ -z $envtype || $envtype = $TAGTYPE ]]; then
    local tagdirs=($(find $ENVSROOT/$TAGTYPE -maxdepth 1 -mindepth 1 -type d | sort))
    if [[ -n $tagdirs ]]; then
      printf "\n"
    fi
    for item in $tagdirs
    do
      printf "#${item##*/}: $(head -n 1 $item/context)\n"
    done
  fi
}

# mkenv envtype envname
mkenv() {
  local envtype=$1
  local envname=$2

  local allowed_types=(${ENVTYPES[@]} ${TAGTYPE})
  local allowed_types_str="${$(printf ", %s" $allowed_types):2}"
  if [[ -z $envtype || -z $envname ]]; then
    printf "
make environment
usage: mkenv <type> <name> [<parameters>]
type is in {${allowed_types_str}}
"
    return 0
  fi

  if [[ ! " ${allowed_types[@]} " =~ " ${envtype} " ]]; then
    printf "
make environment: unsupported environment type
usage: mkenv <type> <name> [<parameters>]
type is in {${allowed_types_str}}
"
    return 0
  fi

  if [[ -d $ENVSROOT/$envtype/$envname ]]; then
    printf "
make environment: environment already exists
"
    return 0
  fi

  if [[ $envtype = $TAGTYPE ]]; then
    local active_envs=(${(ps: :)ENVCONTEXT})
    if [[ ${#active_envs} < 2 ]]; then
      printf "
make environment: more than one env has to be active to tag a composite env
"
      return 0
    fi
    export ENVTAG=$envname
    mkdir $ENVSROOT/$envtype/$envname
# write context to a file
cat <<EOF >$ENVSROOT/$envtype/$envname/context
$ENVCONTEXT
EOF
  else
    mkenv_$envtype "${@:2}"
  fi

  printf "
make environment: done
"
}

# aenv envtype envname
aenv() {
  local envtype=$1
  local envname=$2

  local allowed_types=(${ENVTYPES[@]} ${TAGTYPE})
  local allowed_types_str="${$(printf ", %s" $allowed_types):2}"
  if [[ -z $envtype || -z $envname ]]; then
    printf "
activate environment
usage: aenv <type> <name>
type is in {${allowed_types_str}}
"
    return 0
  fi

  if [[ ! " ${allowed_types[@]} " =~ " ${envtype} " ]]; then
    printf "
activate environment: unsupported environment type
usage: aenv <type> <name>
type is in {${allowed_types_str}}
"
    return 0
  fi

  local envdir=$ENVSROOT/$envtype/$envname
  if [[ ! -d $envdir ]]; then
    printf "
activate environment: environment does not exist, create it first with mkenv
"
    return 0
  fi

  if [[ -n $ENVCONTEXT ]]; then
    if [[ $envtype = $TAGTYPE ]]; then
      printf "
activate environment: deactivate the current environment to activate the composite environment
"
      return 0
    fi
    # check if env type is already active
    local context=(${(ps: :)ENVCONTEXT})
    for item in $context
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
    [[ -e $envdir/.envrc ]] && source $envdir/.envrc
  else
    (
      if [[ $envtype = $TAGTYPE ]]; then
        local context=($(head -n 1 $envdir/context))
        > $envdir/.envrc
        for item in $context
        do
          [[ -e $ENVSROOT/$item/.envrc ]] && cat $ENVSROOT/$item/.envrc >> $envdir/.envrc
        done
        export ENVTAG=$envname
        export ENVCONTEXT="${context[@]}"
      else
        export ENVCONTEXT=$envtype/$envname
      fi
      # when new subshell is started envrc is sourced at the end of this script
      export ENVRC=$envdir/.envrc
      exec $SHELL
    )
  fi
}

# TODO add recycle bin and restore command
# rmenv envtype envname
rmenv() {
  local envtype=$1
  local envname=$2

  local allowed_types=(${ENVTYPES[@]} ${TAGTYPE})
  local allowed_types_str="${$(printf ", %s" $allowed_types):2}"
  if [[ -z $envtype || -z $envname ]]; then
    printf "
remove environment
usage: rmenv <type> <name>
type is in {${allowed_types_str}}
"
    return 0
  fi

  if [[ ! " ${allowed_types[@]} " =~ " ${envtype} " ]]; then
    printf "
remove environment: unsupported environment type
usage: rmenv <type> <name>
type is in {${allowed_types_str}}
"
    return 0
  fi

  local envdir=$ENVSROOT/$envtype/$envname
  if [[ ! -d $envdir ]]; then
    printf "
remove environment: environment not found
"
    return 0
  fi

  # check if env is active
  if [[ $envtype = $TAGTYPE && $ENVTAG = $envname ]]; then
    printf "
remove environment: #$envname is active, deactivate to remove
"
    return 0
  else
    if [[ -n $ENVCONTEXT ]]; then
      local context=(${(ps: :)ENVCONTEXT})
      for item in $context
      do
        if [[ $envtype/$envname = $item ]]; then
          printf "
remove environment: $item is active, deactivate to remove
"
          return 0
        fi
      done
    fi
  fi

  # TODO check if any composite env contains this env
  # if any composite env has to be removed when removing this env
  # then display a warning and a choice to proceed
  rm -rf $envdir

  printf "
remove environment: done
"
}

prompt_context() {
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


[[ -n $ENVRC && -e $ENVRC ]] && source $ENVRC

