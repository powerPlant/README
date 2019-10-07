#!/bin/bash
function usage () {
  echo "Usage: $BASH_SOURCE ToolName URL"
}

if [[ $# -ne 2 ]]; then
  usage
  exit 2
fi

git init ${1,,}-srf
cd ${1,,}-srf
hub create -d "Singularity recipe files for $1 (${2})" powerPlant/${1,,}-srf
echo "Singularity recipe files for " >> README.md
cat > Singularity.version <<'EOF'
Bootstrap: docker
From: ubuntu:bionic
Stage: build

%post
  ## Download build prerequisites
  apt-get update
  apt-get -y install git make build-dependency1
  
  ## Build
  cd /opt
  git clone URL
  make

Bootstrap: docker
From: ubuntu:bionic
Stage: final

%labels
Maintainer @plantandfood.co.nz
Version 

%files from build
  /opt/URL/bin/tool /usr/local/bin/

%runscript
  exec tool "$@"

==OR==

if [ $# -eq 0 ]; then
  /bin/echo -e "This Singularity image cannot provide a single entrypoint. Please use \"$SINGULARITY_NAME <cmd>\" or \"singularity exec $SINGULARITY_NAME <cmd>\", where <cmd> is one of the following:\n"
  exec ls /usr/local/bin
else
  exec "$@"
fi
EOF
