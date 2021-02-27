register_type "python"

if [[ ! -d $ENVSROOT/python ]]; then
  mkdir $ENVSROOT/python
fi

# mkenv_python envname
mkenv_python() {
  local envdir=$ENVSROOT/python/$1
  mkdir $envdir
  python3 -m venv $envdir
# write envrc file
cat <<EOF >$envdir/.envrc
unset PYTHONHOME
export PATH=$envdir/bin:\$PATH
EOF
}

