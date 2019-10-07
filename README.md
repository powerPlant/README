# powerPlant's Software
This GitHub organization hosts recipe files for building Singularity images of the software used at [Plant & Food Research](https://www.plantandfood.co.nz)'s HPC cluster, powerPlant.

This document describes the generic guidelines that apply to all other repositories in this organization, unless overridden within a specific repository.

# Repositories
## License
All recipe files (`Singularity[.*]`) published in the different repositories within this GitHub organization are hereby distributed under a MIT license, unless a specific repository uses a different license.

Please see `LICENSE` in this repo for the license terms.

## Naming convention
Repositories are called the same as the name in lowercase of the software being containerized, with the suffix `-srf` (which stands for "Singularity Recipe Files").

For example, if the software to be packaged is called `HiC-Pro`, the repository with the recipe files should be called `hic-pro-srf`.

The repository's description should follow the following pattern:

> "Singularity recipe files for `<tool name>` (`<URL>`)"

## Repository content
In general, we follow [Singularity-Hub's requirements](https://github.com/singularityhub/singularityhub.github.io/wiki/Build-A-Container) to allow each repository being assigned a "Collection" and automated image builds.

In particular, the following are required:
- A `README.md` file that follows the format described [below](#readmemd-content)
- A `Singularity` symlink file pointing to the latest version that the repository maintainer supports.
- One or more `Singularity.<version>` files with the recipes building the version specified in the file name.
- Optionally, a `LICENSE` file must be included to override the generic MIT license that would otherwise apply.

### README.md content
The `README.md` file must have the following content:
```
<Markdown code for displaying the badge from Singularity Hub>
Singularity recipe files for [the ] `<tool name>` for `<tool purpose or description>`
```

Optionally, include any "Maintainer notes" to explain decisions made during the creation of the recipes, or any "Usage notes" which cannot be included in the Container Image's logic.

Singularity Hub's badges are generated after a Collection is created, so in most repositories they are added to the `README.md` file in a second commit.

# Recipe standards
## Labels
All containers must have, at a minimum, the following metadata labels:
- Maintainer
- Version

## Versioning
Versions should match whatever format or convention upstream decides to use when querying the version in the command line.

For example, if the software is released as `Tool-v1.0.0`, but `./Tool --version` returns `1.0.0`, the recipe files and the `Version` label should use `1.0.0` and **not** `v1.0.0`.

Additionally, any software that is manually downloaded (i.e.: not provided by the distribution repositories) **must** be version tagged.

For example:
```
% post
git clone https://github.com/LynchLab/MAPGD.git
cd /MAPGD
git checkout d3edee2
```

or
```
%post
wget https://github.com/jtamames/SqueezeMeta/archive/v0.4.4.tar.gz
```

## Base images
Unless upstream already provides a Docker or a Singularity image, all recipe files should `bootstrap` from a version-tagged OS base image. When selecting the base image, LTS versions are preferred.

For example:
```
Bootstrap: docker
From: ubuntu:bionic
```

## Entrypoint
All containers **must** define a suitable entrypoint that makes the image directly executable (i.e.: `./tool-version.simg`). For example:

```
%runscript
exec python3 /opt/RaGOO-1.02/ragoo.py "$@"
```
See below for other special cases.

### Dealing with multiple entrypoints
Some software tools do not provide a single binary that can be used as the container's entrypoint. We aspire for the Singularity images to be directly executable, so to work around this we use the following convention for the `%runscript` section:

```
%runscript
if [ $# -eq 0 ]; then
  /bin/echo -e "This Singularity image cannot provide a single entrypoint. Please use \"$SINGULARITY_NAME <cmd>\" or \"singularity exec $SINGULARITY_NAME <cmd>\", where <cmd> is one of the following:\n"
  exec ls /usr/local/bin
else
  exec "$@"
fi
```

NOTE: The block above assumes that `/usr/local/bin` only contains the binaries provided by the tool. You can generate this list in other ways if this approach does not suit.

### Dealing with bind-mounted data
Some software requires large read databases to be present in some predefined or user-configurable location. **Large datasets should not be included with the container image**. Instead, use the `%runscript` to advise the user how to bind mount it from their host system. For example:

```
%runscript
if [ ! -f /media/db/.dmanifest ]; then
  exec /bin/echo -e "This container requires that you bind mount the location of SqueezeMeta data into /media. Please use \"singularity run -B <path_to_squeezemedia_data>:/media $SINGULARITY_NAME\" and try again. You can download the latest version of the data files by running the \"download_databases.pl\" script. See https://github.com/jtamames/SqueezeMeta#3-downloading-or-building-databases for more information."
else
  exec perl /opt/SqueezeMeta-0.4.4/scripts/SqueezeMeta.pl "$@"
fi
```
## Cleanup
All images must have a cleanup section where build dependencies, package manager cache, and other artifacts are removed from the standard image. The best way to achieve this is with [Multi-Stage Builds](https://sylabs.io/guides/3.2/user-guide/definition_files.html#multi-stage-builds)

For example:

```
Stage: build

%post
  ## Download build prerequisites
  yum -y install bzip2-devel gcc gcc-c++ git make xz-devel zlib-devel

  ## Build
  cd /opt
  git clone --recursive https://github.com/walaj/svaba
  cd svaba
  git checkout c0fecb6
  ./configure
  make
(...)
Stage: final

%files from build
  /opt/svaba/src/svaba/svaba /usr/local/bin
```

If Multi-Stage Builds cannot be used for whatever reason, you **must** add a manual clean up section.

For example:

```
% post
yum -y install git gcc make zlib
(...)
git clone https://github.com/LynchLab/MAPGD.git
cd MAPGD
git checkout d3edee2
make
make install
(...)
# Cleanup
yum -y erase git gcc make
yum -y autoremove
yum -y clean all
```

# Helper script
The `./new.sh` helper script in this repository can be used to automate the creation of new repositories implementing some of the best practices described in this document.

Run `./new.sh -h`for usage instructions.

## Pre-requisites
- The [hub](https://github.com/github/hub) tool pre-configured with your account settings
- For your GitHub account to have permissions to create repositories in this GitHub organization

