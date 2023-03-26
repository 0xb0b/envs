register_type "nvim"

if [[ ! -d $ENVSROOT/nvim ]]; then
  mkdir $ENVSROOT/nvim
fi

if [[ ! -f $ENVSROOT/nvim/init.vim ]]; then
# write generic nvim init file
cat <<EOF >$ENVSROOT/nvim/init.vim
execute 'source '.globpath(stdpath('config'), 'init.vim')

" generic nvim session configuration

let g:env_proj_root = '$HOME'
command! Env :echo 'no env'

" save generic session on exit
set sessionoptions-=blank sessionoptions+=resize sessionoptions+=winpos
augroup env_autocmds
  autocmd!
  autocmd VimLeavePre * mksession! $ENVSROOT/nvim/session.vim
augroup END

EOF
fi

e() {
  # if no nvim env is active then take generic init and session
  # otherwise take init and session from an active env
  local sessiondir=$ENVSROOT/nvim
  if [[ -n $ENVCONTEXT ]]; then
    for item in $ENVCONTEXT
    do
      if [[ ${item%/*} == "nvim" ]]; then
        sessiondir=$ENVSROOT/$item
        break
      fi
    done
  fi

  if [[ -f $sessiondir/session.vim ]]; then
    nvim -u $sessiondir/init.vim -S $sessiondir/session.vim $1
  else
    nvim -u $sessiondir/init.vim $1
  fi
}

# mkenv_nvim envname project_dir
mkenv_nvim() {
  local envname=$1
  local projdir=$2

  local projdir_full
  if [[ -z $projdir ]]; then
    printf "
make neovim environment: project root missing
usage: mkenv nvim <name> <project root directory>
"
    return 0
  else
    if [[ -d $projdir ]]; then
      # expand to full path
      # https://stackoverflow.com/a/13087801/3001041
      pushd $projdir >/dev/null
      projdir_full=$( pwd )
      popd >/dev/null
    else
      printf "
make neovim environment: directory $projdir does not exist
"
      return 0
    fi
  fi

  local envdir=$ENVSROOT/nvim/$envname
  mkdir $envdir

cat <<EOF >$envdir/init.vim
execute 'source '.globpath(stdpath('config'), 'init.vim')

let g:env_proj_root = '$projdir_full'
command! Env :echo '$envname @ '.g:env_proj_root

" save environment session on exit
set sessionoptions-=blank sessionoptions+=resize sessionoptions+=winpos
augroup env_autocmds
  autocmd!
  autocmd VimLeavePre * mksession! $envdir/session.vim
augroup END

" add the project configuration below.
" if the project config becomes complicated consider moving it
" to a separate file in the project repo under version control
" and source it here.

EOF
}

