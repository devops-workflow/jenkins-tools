#!/bin/bash
#
# Setup Python and virtual environment
# Using PyEnv and Virtualenv
#
# Design as Jenkins job to setup python environments on nodes
#

# Requirements:
#  git, curl
#  $HOME set to jenkins dir
#

function usage() {
  cat <<USAGE
usage: $0 parameters

Parameters:
-v, --python_version	Python version
-e, --env_name        virtual environment name - Should name space with job name
-p, --packages        python packages to ensure are installed
-P, --pkgs_latest     Make packages always be the latest
-r, --rebuild         Rebuild virtual environment
USAGE
  exit 1
}

function getParameters() {
  # Parse arguments
  optsLong='env_name:,packages:,pkgs_latest,rebuild,python_version:'
  optsShort='e:p:Prv:'
  temp=$(getopt -o ${optsShort} -l ${optsLong} -n $0 -- "$@")
  if [ $? -ne 0 ]; then
    usage
  fi
  eval set -- "${temp}"
  while true; do
    case "$1" in
      -e|--env_name)
        case "$2" in
          "") shift 2 ;;
          *) params[env_name]=$2 ; shift 2 ;;
        esac ;;
      -p|--packages)
        case "$2" in
          "") shift 2 ;;
          *) params[packages]=$2 ; shift 2 ;;
        esac ;;
      -P|--pkgs_latest)
        params[pkgs_latest]=1 ; shift ;;
      -r,--rebuild)
        params[rebuild]=1; shift ;;
      -v|--python_version)
        case "$2" in
          "") shift 2 ;;
          *) params[python_version]=$2 ; shift 2 ;;
        esac ;;
      --) shift ; break ;;
      *) echo "Internal error!" ; exit 1 ;;
    esac
  done
} # getParmeters

###
### Main
###
declare -A params
getParameters $@
# TODO: validate parameters

## Install PyEnv
export PYENV_ROOT="${HOME}/.pyenv"
export PATH="${PYENV_ROOT}/bin:${PATH}"
if [ ! -d "${PYENV_ROOT}" ]; then
  echo "Installing PyEnv..."
  curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
fi

## Install PyEnv VirtualEnv
if [ ! -d "$PYENV_ROOT/plugins/pyenv-virtualenv" ]; then
  echo "Installing pyenv-virtualenv ..."
  git clone https://github.com/yyuu/pyenv-virtualenv.git $PYENV_ROOT/plugins/pyenv-virtualenv
fi

# FAIL is PyEnv didn't get installed
if [ ! -d "${PYENV_ROOT}" ]; then
  exit 1
fi

## Update PyEnv
pyenv update
pushd $PYENV_ROOT/plugins/pyenv-virtualenv
git pull
popd

## Initialize PyEnv and virtualenv
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
export PYENV_VIRTUALENV_DISABLE_PROMPT=1

## Install Python version. If needed
if [ $(pyenv versions --skip-aliases --bare | grep ${params[python_version]} | wc -l) = 0 ]; then
  pyenv install ${params[python_version]}
  if [ $(pyenv versions --skip-aliases --bare | grep ${params[python_version]} | wc -l) = 0 ]; then
    echo "ERROR: failed to install Python: ${params[python_version]}"
    exit 1
  fi
fi

## Create Virtual Environment. If needed
# TODO:
#   Look at creating in local workspace
found=''
envs=$(pyenv virtualenvs --skip-aliases --bare)
for E in ${envs}; do
  if [ "${params[env_name]}" == "${E##*/}" ]; then
    found=1
    # FIX: Need to verify hash element exists first
    #if [ ${params[rebuild]} -eq 1 -o "${params[python_version]}" != ${E%%/*} ]; then
    #  echo "Rebuilding virtual environment for: ${params[python_version]} $${params[env_name]}"
    #  pyenv virtualenv-delete -f "${params[env_name]}"
    #  pyenv virtualenv "${params[python_version]}" "${params[env_name]}"
    #fi
  fi
done
if [ "${found}" != "1" ]; then
  echo "Creating new virtual environment for: ${params[python_version]} ${params[env_name]}"
  pyenv virtualenv "${params[python_version]}" "${params[env_name]}"
fi

if [ $(pyenv virtualenvs | grep ${params[env_name]} | wc -l) = 0 ]; then
  pyenv virtualenv "${params[python_version]}" "${params[env_name]}"
  if [ $(pyenv virtualenvs | grep ${params[env_name]} | wc -l) = 0 ]; then
    echo "ERROR: failed to create virtual environment ${params[python_version]} ${params[env_name]}"
    exit 1
  fi
fi

pyenv activate "${params[env_name]}"
# FIX: only upgrade if not latest
#pip install --upgrade pip

###
### Install and upgrade packages
###
# Ensure all requested packages are installed
declare -A pkgs_installed pkgs_to_install
for pkg in $(pip freeze); do
  pkg_name=${pkg%%=*}
  pkgs_installed[${pkg_name}]=1
done
# Build list of missing packages to install
for pkg in ${params[packages]}; do
  if [ ! ${pkgs_installed[${pkg}]} ]; then
    pkgs_to_install[${pkg}]=1
  fi
done
if [ $(echo "${!pkgs_to_install[@]}" | wc -c) -gt 1 ]; then
  pip install "${!pkgs_to_install[@]}"
fi

# If latest, update all outdated packages
# This can causes some packages to be too new and cause others to fails
# TODO: figure out better way
# FIX: need to verify hash element exists first
#if [ ${params[pkgs_latest]} -eq 1 ]; then
#  pkgs_to_upgrade=$(pip list --outdated | awk '{ print $1 }')
#  if [ -n "${pkgs_to_upgrade}" ]; then
#    pip install --upgrade ${pkgs_to_upgrade}
#  fi
#fi

###
### Validate
###
echo "PyEnv Versions"
pyenv versions
echo "Current Versions:"
echo -ne "pyenv version: " && pyenv version
python --version
pip --version
echo "Virtual Envs:"
pyenv virtualenvs
echo "Installed Python packages:"
#pip list
pip freeze
