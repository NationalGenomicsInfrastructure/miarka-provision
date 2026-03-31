# Setup TODO Is all info necessary

This document describes the layout of miarka-provision and how to set it up.

## Repo layout

### Ansible-specific content

`inventory.yml` defines the host addresses where tasks will be run

The main playbooks are `install.yml`, for deploying to the local disk and `sync.yml` for syncing the deployment to the
shared filesystem. 

Common tasks used e.g. for setting up variables and paths required for deployment or syncing are defined under `tasks/`.

Typically, each software or function has its own role for deployment and these are defined under `roles/`.

#### Variables

In ansible, variables can be defined in a number of different locations depending on context, precedence etc. The 
location where you should define a variable will thus very depending on the circumstances. Below are a few 
rules-of-thumb to help you identify where to find or define a variable.

##### `env_vars`
The conditions this playbook can be run under will mainly be a combination of `deployment_environment` (i.e. one of 
`devel`, `staging` or `production`) and `site` (i.e. one of `sthlm` and `upps`). Therefore, variables that depend on 
the specific `deployment_environment` and/or `site` are located in the corresponding variable file (named according to 
`site_[all | sthlm | upps]_env_[all | devel | staging | production ].yml`) in the `env_vars/` folder. When the playbook
is run, the appropriate variable files will automatically be imported.

In `env_vars/` you can find an example variable file that can be used as a basis for `deployment_environment`- or 
`site`-specific variable files.

##### `env_secrets`
Similar to the `env_vars/` folder, the `env_secrets/` folder contains variable files organized in the same way 
according to `deployment_environment` and `site`. This is where variables that should be kept secret (e.g. api-keys, 
passwords etc.) should be defined. These variable files will be ignored by `git` and should thus never be checked in.

In `env_secrets/` you can find an example variable file that can be used as a basis for `deployment_environment`- or 
`site`-specific variable files.

##### `role / defaults`
Variables that are only used within a role and are independent of `deployment_environment` and `site` should be defined
within the role, e.g. in `defaults/main.yml`.

##### `host_vars`

Variables that are used across roles or in the main plays and are specific to a host (e.g. the `deploy` host) should be
defined in `host_vars/[host_name]/` (where `host_name` corresponds to the host name used in `inventory.yml`. Note that 
although these variables should in general be independent of `deployment_environment` and `site`, some may be 
overridden or depend implicitly on variables in `env_vars/`. In other words, these are dynamically resolved when the 
play executes.
 
##### `group_vars`

Variables that are used across roles or in the main plays and are specific for a group are defined under `group_vars/`. 
Currently, this only includes `all` which means that the variables are accessible to all hosts and throughout the 
playbooks.


### Other

The `docker/` directory contains files used for building a Singularity (and Docker) image that can be used for running
Ansible.

The `bootstrap/` directory contains files and scripts used for setting up and configuring the environment on the 
deployment node (primarily if the Singularity image is not used for deployment). 

## Setting up Ansible for deployments

Ansible can either be run in a Singularity container (preferred) or from an installation in the local environment on 
Miarka3. 

For the first option, follow the Singularity instructions below. For the second option, skip down to the local 
environment bootstrap instructions [below](#bootstrap-the-ansible-environment).

### Building a singularity image

The preferred way of running Ansible is in a Singularity container. Currently, the container needs to be built 
in an environment where the user can have sufficient privileges. This is not possible on Miarka.

If there is already a current singularity image available in `/vulpes/ngi/deploy` on `miarka3` you should use this for 
staging and production deployments (also for devel unless there is a reason not to).

The singularity image is built from a Docker image whose definition file is available at `docker/Dockerfile`. The image 
has been built and tested with Docker v20.10.7 and Singularity v3.7.1. 

To build the singularity image, clone this repository and run `docker/build_singularity.sh`. This will create a 
singularity image, `miarka-ansible.<commit hash>.sif` in the working directory. The image itself is not dependent on 
changes to the miarka-provision repo, with the exception to changes in the `docker` folder. For clarity, the image 
will be tagged with the git commit hash of the repo that the image was built from.

The singularity image can be then be uploaded to `miarka3` and used for deployment. When you are confident that the 
image is stable and should be used in production, move it to the `/vulpes/ngi/deploy` folder and move the 
`miarka-ansible.sif` symlink to point to this image.


### Setting up the environment for using the singularity image

On `miarka3`, clone the `miarka-provision` repo by running:

```
cd /path/to/deployment/resources
singularity run /path/to/miarka-ansible.sif
```

This will clone the devel branch of this repo under the current working directory and copy the `bootsrap/bashrc` file
here.

For convenience, it is recommended that the user adds the following line (or something similar) into `~/.bashrc`:

```
alias miarkaenv='source /path/to/deployment/resources/bashrc'
alias ansible-playbook='singularity run --bind /vulpes,/sw,/scratch /path/to/miarka-ansible.sif ansible-playbook'
```

Note that this will add an alias for `ansible-playbook` that refers to the singularity container. If this is not 
suitable for your specific use case, you can skip this. The commands below will assume the alias exist.


### Bootstrap the Ansible environment

If you will be running Ansible in a singularity container, you should skip this section.

Before any deployments can be done we need to setup the Ansible environment. If we've got a clean environment then this 
can be done by running the bootstrap script:

```
newgrp ngi-sw

curl -L \
https://raw.githubusercontent.com/NationalGenomicsInfrastructure/miarka-provision/devel/bootstrap/bootstrap.sh \
-o /tmp/bootstrap.sh

bash /tmp/bootstrap.sh /path/to/deployment/resources
```

For convenience, it is recommended that the user adds the following two lines (or something similar) into `~/.bashrc`:

```
alias miarkaenv='source /path/to/deployment/resources/bashrc'
alias ansibleenv='source /path/to/deployment/resources/ansible-env/bin/activate'
```

## User prerequisites before developing or deploying

Before a user starts developing new Ansible playbooks/roles or deploy them, the current umask and GID needs to be set. 
This is accomplished by *manually* running the bash alias: `miarkaenv` (defined above).

If you are running Ansible from the local environment, Ansible the virtual environment needs to be loaded. To do this, 
execute the bash alias `ansibleenv` (defined above). Note that the order is important, and that the aliases should not 
be run automatically at login, because that will cause an infinite loop that will lock the user out.

### SSH multiplexing
For syncing deployments to the target host, it is necessary to set up the environment so that connections can be made 
to the target host without needing interaction from the user (which ansible doesn't support). This can be done with 
ssh-multiplexing. Add the following to the `~/.ssh/config` file (create the file first if it doesn't exist):
```
Host *.uppmax.uu.se
    ControlMaster auto
    ControlPath ~/.ssh/master-%r@%h:%p.socket
    ControlPersist 60m
```
This will establish a SSH connection that will persist for 60 min after an initial connection has been made, which will 
be re-used by subsequent SSH connections, even if the initial session has been closed. 
