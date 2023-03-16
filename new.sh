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
hub create -d "Apptainer recipe files for $1 (${2})" powerPlant/${1,,}-srf
echo "Apptainer recipe files for " >> README.md
cat > Apptainer.version <<'EOF'
Bootstrap: docker
From: ubuntu:jammy
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
From: ubuntu:jammy
Stage: final

%labels
Maintainer @plantandfood.co.nz
Version 

%files from build
  /opt/URL/bin/tool /usr/local/bin/

%runscript
  exec tool "$@"

==OR==

if [ -x /usr/local/bin/$APPTAINER_NAME ]; then
    exec $APPTAINER_NAME "$@"
else
  /bin/echo -e "This Apptainer image cannot provide a single entrypoint. Please use \"apptainer exec $APPTAINER_NAME <cmd>\", where <cmd> is one of the following:\n"
  exec ls /usr/local/bin
fi
EOF
