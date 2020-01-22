
# https://datagrok.org/python/activate/
# instead of "source <env path>/bin/activate"
# start a subshell for the first env and replace the shell when env is changed

export ENVDIR=$HOME/.env
if [[ ! -d $ENVDIR ]]; then
  mkdir $ENVDIR
fi

export NVIM_ENVDIR=$ENVDIR/nvim
if [[ ! -d $NVIM_ENVDIR ]]; then
  mkdir $NVIM_ENVDIR
fi

py_envdir=$ENVDIR/python


e() {
  if [[ -z $NVIM_ENVNAME ]]; then
    sessiondir=$NVIM_ENVDIR
  else
    sessiondir=$NVIM_ENVDIR/$NVIM_ENVNAME
  fi

  if [[ -f $sessiondir/session.vim ]]; then
    nvim -u $NVIM_ENVDIR/init.vim -S $sessiondir/session.vim $1
  else
    nvim -u $NVIM_ENVDIR/init.vim $1
  fi
}

lsenv() {
  if [[ -z $1 || $1 = "all" ]]; then
    # list environments in the form "type/name"
    envlist=$(find $ENVDIR -maxdepth 2 -mindepth 2 -type d | sort)
    for item in $envlist
    do
      envtype=$( dirname $item )
      envname=$( basename $item )
      echo $( basename $envtype )/$envname
    done
  else
    # if type is provided list only names
    if [[ $1 = "nvim" && -d $NVIM_ENVDIR ]]; then
      envlist=$(find $NVIM_ENVDIR -maxdepth 1 -mindepth 1 -type d | sort)
    elif [[ ( $1 = "py" || $1 = "python" ) && -d $py_envdir ]]; then
      envlist=$(find $py_envdir -maxdepth 1 -mindepth 1 -type d | sort)
    else
      echo "list environments"
      echo "usage: lsenv [<type>]"
      echo "type: all (default), nvim, py[thon]"
      return 0
    fi
    for item in $envlist
    do
      echo $( basename $item )
    done
  fi
}

mkenv() {
  if [[ -z $1 ]]; then
    echo "make environment"
    echo "usage: mkenv [<type>/]<name> [<parameters>]"
    echo "type: nvim (default), python"
    echo "nvim parameter: project root path (if not present then current dir is used)"
    return 0
  fi

  envname=$( basename $1 )
  envtype=$( dirname $1 )
  if [[ $envtype = "." || $envtype = "nvim" ]]; then
    envdir=$NVIM_ENVDIR
  elif [[ $envtype = "python" ]]; then
    envdir=$py_envdir
  else
    echo "unsupported environment type (can be [nvim], python)"
    return 0
  fi

  if [[ -d $envdir/$envname ]]; then
    echo "environment ($1) already exists"
    return 0
  fi

  if [[ ! -d $envdir ]]; then
    mkdir $envdir
  fi

  if [[ $envdir = $NVIM_ENVDIR ]]; then
    if [[ -z $2 ]]; then
      projroot=$( pwd )
    else
      if [[ -d $2 ]]; then
        # expand to full path
        # https://stackoverflow.com/a/13087801/3001041
        pushd $2 >/dev/null
        projroot=$( pwd )
        popd >/dev/null
      else
        echo "directory $2 does not exist!"
        return 0
      fi
    fi
    mkdir $envdir/$envname
# write environment nvim config file
cat <<EOF >$envdir/$envname/init.vim
let g:env_proj_root = "$projroot"

" add project configuration below.
" if the project config becomes big consider moving it to the separate file in
" the project repo under version control.
" and then source it here.

EOF
    echo "done"
    return 0
  fi

  if [[ $envdir = $py_envdir ]]; then
    python3 -m venv --copies $envdir/$envname
    echo "done"
  fi
}

aenv() {
  if [[ -z $1 ]]; then
    echo "activate environment"
    echo "usage: aenv [<type>/]<name>"
    echo "type: nvim (default), python"
    return 0
  fi

  envtype=$( dirname $1 )
  envname=$( basename $1 )
  if [[ $envtype = "." || $envtype = "nvim" ]]; then
    envdir=$NVIM_ENVDIR
  elif [[ $envtype = "python" ]]; then
    envdir=$py_envdir
  else
    echo "unsupported environment type (can be [nvim], python)"
    return 0
  fi

  if [[ ! -d $envdir/$envname ]]; then
    echo "environment does not exist, create it first with mkenv"
    return 0
  fi

  if [[ $envdir = $NVIM_ENVDIR ]]; then
    if [[ -z $NVIM_ENVNAME ]]; then
      (
        # start subshell for the first environment
        export NVIM_ENVNAME=$envname
        if [[ -z $ENVCONTEXT ]]; then
          export ENVCONTEXT=$envname
        else
          export OLDCONTEXT=$ENVCONTEXT
          export ENVCONTEXT=$OLDCONTEXT.$envname
        fi
        exec $SHELL
      )
    else
      # change the environment
      export NVIM_ENVNAME=$envname
      if [[ -z $OLDCONTEXT ]]; then
        export ENVCONTEXT=$envname
      else
        export ENVCONTEXT=$OLDCONTEXT.$envname
      fi
    fi
    return 0
  fi

  if [[ $envdir = $py_envdir ]]; then
    if [[ -z $PY_ENVNAME ]]; then
      (
        # save original path at activation of the first env to correctly handle the case when
        # env is later changed from within this env
        export PY_ENVNAME=$envname
        if [[ -z $ENVCONTEXT ]]; then
          export ENVCONTEXT=$envtype/$envname
        else
          export OLDCONTEXT=$ENVCONTEXT
          export ENVCONTEXT=$OLDCONTEXT.$envtype/$envname
        fi
        unset PYTHONHOME
        export ORIGINAL_PATH=$PATH
        export PATH=$envdir/$envname/bin:$ORIGINAL_PATH
        exec $SHELL
      )
    else
      export PY_ENVNAME=$envname
      if [[ -z $OLDCONTEXT ]]; then
        export ENVCONTEXT=$envtype/$envname
      else
        export ENVCONTEXT=$OLDCONTEXT.$envtype/$envname
      fi
      unset PYTHONHOME
      export PATH=$envdir/$envname/bin:$ORIGINAL_PATH
    fi
  fi
}

rmenv() {
  if [[ -z $1 ]]; then
    echo "remove environment"
    echo "usage: rmenv [<type>/]<name>"
    echo "type: nvim (default), python"
    return 0
  fi

  envname=$( basename $1 )
  envtype=$( dirname $1 )
  if [[ $envtype = "." || $envtype = "vim" ]]; then
    envdir=$NVIM_ENVDIR
  elif [[ $envtype = "python" ]]; then
    envdir=$py_envdir
  else
    echo "unsupported environment type (can be [nvim], python)"
    return 0
  fi

  if [[ -d $envdir/$envname ]]; then
    rm -rf $envdir/$envname
    echo "done"
    if [[ $NVIM_ENVNAME = $envname || $PY_ENVNAME = $envname ]]; then
      # if removing the active env then quit it
      exit 0
    fi
  else
    echo "environment ($1) not found, nothing to remove"
  fi
}

