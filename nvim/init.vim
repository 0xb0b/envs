" generic environment configuration

let s:nvim_config_dir = stdpath("config")
execute 'source '.globpath(s:nvim_config_dir, 'init.vim')

if !empty($NVIM_ENVNAME)
  source $NVIM_ENVDIR/$NVIM_ENVNAME/init.vim
  command! Env :echo 'env: '.$NVIM_ENVNAME.' @ '.g:env_proj_root
else
  let g:env_proj_root = $HOME
  command! Env :echo 'env: -'
endif

set sessionoptions-=blank sessionoptions+=resize sessionoptions+=winpos
augroup env_autocmds
  autocmd!
" save environment session on exit
  if !empty($NVIM_ENVNAME)
    autocmd VimLeavePre * mksession! $NVIM_ENVDIR/$NVIM_ENVNAME/session.vim
  else
    autocmd VimLeavePre * mksession! $NVIM_ENVDIR/session.vim
  endif
augroup END

