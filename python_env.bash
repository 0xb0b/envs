register_type "python"

if [[ ! -d $ENVSROOT/python ]]; then
  mkdir $ENVSROOT/python
fi

mkenv_python() {
  local envdir=$ENVSROOT/python/$1
  mkdir $envdir
  python3 -m venv --copies $envdir
}

aenv_python() {
  local envdir=$ENVSROOT/python/$1
  unset PYTHONHOME
  export PATH=$envdir/bin:$PATH
  # variable for poetry to recognize virtual environment
  export VIRTUAL_ENV=$envdir
}

