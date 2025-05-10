register_type "python"

if [[ ! -d $ENVSROOT/python ]]; then
  mkdir $ENVSROOT/python
fi

# mkenv_python envname python_command
mkenv_python() {
  local envdir=$ENVSROOT/python/$1
  local python_command=${2:-python3}
  mkdir $envdir
  $python_command -m venv $envdir
# write envrc file
cat <<EOF >$envdir/.envrc
unset PYTHONHOME
export PATH=$envdir/bin:\$PATH
export VIRTUAL_ENV=$envdir
EOF
}

