register_type "python"

if [[ ! -d $ENVSROOT/python ]]; then
  mkdir $ENVSROOT/python
fi

mkenv_python() {
  local envdir=$ENVSROOT/python/$1
  mkdir $envdir
  python3 -m venv --copies $envdir
  printf "
make environment: done
"
}

aenv_python() {
  unset PYTHONHOME
  export PATH=$ENVSROOT/python/$1/bin:$PATH
}

