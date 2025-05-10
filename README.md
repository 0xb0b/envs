# envs

https://datagrok.org/python/activate/
main idea: start a subshell instead of "source <env path>/bin/activate"

envs of different types are orthogonal - they can be combined into any
composition and do not depend on each other.

envs.sh has to be sourced in .rc file of a shell. 
it is then executed when a subshell is started.

## usage:

list environments
    > lsenv

list environments of a certain type (python in this case)
    > lsenv python

make environment named myenv (of the type python in this case)
    > mkenv python myenv

make python environment named myenv using a certain python installation
(if the optional path parameter is not provided than the default python command is python3)
    > mkenv python myenv ~/.local/share/uv/python/cpython-3.10.17-macos-aarch64-none/bin/python3.10

activate environment
    > aenv python myenv

remove environment
    > rmenv python myenv

