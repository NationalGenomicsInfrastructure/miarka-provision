# Deployment playbooks for NGI-Pipeline and related software (Piper, TACA, Tarzan, etc.)

This repository concerns the creation and maintenance of the NGI environment; which is a collection of software 
and solutions utilized by NGI Production on the currently available HPC.

The NGI environment is currently deployed on Miarka using Ansible playbooks. Ansible playbooks are scripts written for 
easily adaptable automated deployment. The Ansible playbooks are stored here.

The deployment is intended to be performed in three stages:
- deployment to a local disk on the deployment node (miarka3)
- synchronize the deployment to the shared file system on the cluster
- create site-specific directories and re-initialize services on the cluster

## TL;DR

Below are the main commands to run for a staging or production deployment once the environment and relevant variables 
has been set up. For a detailed description and walk-through of the procedures, continue the reading below.

```
# setup the miarka environment
miarkaenv

# cd to the playbook directory and checkout the correct branch/version
cd /path/to/deployment/resources/miarka-provision
git fetch --tags origin
git checkout [monthly / bimonthly / tags/vX.Y]
git pull origin

# do deployment to local file system for each site
ansible-playbook -i inventory.yml install.yml -e deployment_environment=[staging / production] -e site=upps
ansible-playbook -i inventory.yml install.yml -e deployment_environment=[staging / production] -e site=sthlm

# sync the deployment to the main vulpes file system
ssh miarka2.uppmax.uu.se exit
ansible-playbook -i inventory.yml sync.yml -e deployment_environment=[staging / production]

# create site-specific directories on the "real" vulpes file system
# run on the appropriate login node using the funk account
/vulpes/ngi/[staging / production]/latest/resources/create_static_contents_[upps / sthlm].sh

# restart services as needed
```

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

## Deployment of the Miarka software

There are two staging branches in the repository, one called monthly and the other bimonthly. The changes that do not 
need extensive testing and validation on stage should be pushed to the monthly branch, which is used to make stage and 
production deployments on a monthly cycle. Changes that need time for validation on stage (like pipeline version 
updates) should be pushed to the bimonthly branch.

Production deployments on the monthly release cycle are done on the last Monday of each month. A stage deployment from 
the monthly branch will be made two weeks before this date and the introduction of new changes to the monthly branch 
will be frozen. Only fixes to changes already merged will be approved to the monthly branch during this time.

Stage deployments from the bimonthly branch can be made outside of the monthly release cycle. The changes on the 
bimonthly branch would generally be pulled to the monthly branch and deployed to production in the monthly release 
cycle once all validations are complete.

### Requirements

As described [above](#variables), the git repository does not contain any sensitive credentials. Instead, these need to 
be specified in the correct file under `env_vars` and `env_secrets` in the checked out `miarka-provision` folder you 
will be deploying from. In practice, you will probably copy these files from `/vulpes/ngi/deploy` or from the last 
deployment and only modify them when something needs changing.

Below is a list of variables that are expected to be defined:

#### SNP&SEQ

In `env_secrets/site_upps_env_*.yml`:

```
charon_api_token
megaqc_access_token
snic_api_password
snic_api_user
tarzan_api_key
tower_workspace_id
```

In addition, valid SSL certificates for the web proxy need to be available on the main `vulpes` file system (i.e. 
accessible from `miarka1` and `miarka2`) under the path specified by the variable `tarzan_cert_path`. See 
`roles/tarzan/README.md` for details.

#### NGI-S

In `env_secrets/site_sthlm_env_*.yml`:

```
charon_api_token
megaqc_access_token
orderportal_api_token
snic_api_password
snic_api_user
statusdb_password
statusdb_username
tower_workspace_id
```

### Development deployment

Typically roles are developed (or at least tested) locally on `miarka3`.

Start by forking the repository https://github.com/NationalGenomicsInfrastructure/miarka-provision to your private 
Github repo. Clone this repository to a suitable location (i.e. NOT from where the stage and production 
deployments are performed) on miarka3. Below, it is assumed that the clone is at 
`/path/to/development/resources/miarka-provision`.

There you can develop your own Ansible roles in your private feature branch.

In `env_vars/` and `env_secrets/` you can find example variable files that can be used as a basis for 
`deployment_environment`- or `site`-specific variable files:
```
cp env_vars/site_all_env_devel.yml.example env_vars/site_all_env_devel.yml
cp env_secrets/site_all_env_all.yml.example env_secrets/site_upps_env_devel.yml
```

If you want to test your roles/playbook, run:
```
    cd /path/to/development/resources/miarka-provision
    ansible-playbook -i inventory.yml -e site=upps install.yml
    ansible-playbook -i inventory.yml -e site=sthlm install.yml
```
This will install your development under `/vulpes/ngi/devel-<username>/<branch_name>.<date>.<commit hash>`

You can also run the sync playbook to test this functionality but in the devel environment, the rsync command will 
always run in `--dry-run` mode, so no data will be transferred.

Before doing the sync, make sure that a SSH master connection is active:
```
    ssh miarka2.uppmax.uu.se exit
```
Then do the sync with:
```
    ansible-playbook -i inventory.yml sync.yml
```

When you are satisfied with your changes you need to test it in staging. To do this, you must create a pull request to 
one of the two staging branches of miarka-provision and, once the feature has been approved, do a staging deployment. 

### Staging deployment

To perform a deployment from one of the staging branches (monthly or bimonthly), navigate to the location of the repo
and make sure that the desired branch is checked out and updated:
```
    cd /path/to/deployment/resources/miarka-provision
    git checkout [monthly/bimonthly]
    git pull origin [monthly/bimonthly]
```
Do the staging deployment to the local disk by running the `install.yml` playbook, once for each site, and specify the 
`deployment_environment` argument:
```
    ansible-playbook -i inventory.yml install.yml -e deployment_environment=staging -e site=upps
    ansible-playbook -i inventory.yml install.yml -e deployment_environment=staging -e site=sthlm 
```
This will install your deployment under `/vulpes/ngi/staging/<deployment_version>`, where `deployment_version` is 
automatically constructed by the playbook according to `<date>.<commit hash>[-bimonthly]` (the `-bimonthly` suffix is 
added in case of a bimonthly deployment). If needed, you can override the deployment_version by passing 
`-e deployment_version=VERSION` to the playbook.

The `sync.yml` playbook is used to sync the deployment to the cluster and shared filesystem.

Before doing the sync, make sure that a SSH master connection is active:
```
    ssh miarka2.uppmax.uu.se exit
```
Then do the sync, specifying the deployment_environment:
```
    ansible-playbook -i inventory.yml sync.yml -e deployment_environment=staging
```

This will also move the `/vulpes/ngi/staging/latest` symlink on `miarka1` and `miarka2` to 
`/vulpes/ngi/staging/<deployment_version>`.

When everything is synced properly then login to the cluster as your personal user and source the new environment and
activate the NGI conda environment (where `site` is `upps` or `sthlm` depending on location): 
```
    source /vulpes/ngi/staging/latest/conf/sourceme_<site>.sh && source activate NGI
```
For convenience, add this to your personal bash init file `~/.bashrc` on `miarka1` or `miarka2`. This will load the 
staging environment for your user with the appropriate staging variables set.

You should now skip [down](#reload-services) to the procedures for reloading services.

When the staged environment has been verified to work OK, proceed with making a pull request from the staging branch to 
the master branch of the repository. 

### Production deployment

Once all pull requests to master are approved and merged, create a production release at 
https://github.com/NationalGenomicsInfrastructure/miarka-provision/releases/new. Make sure to write a good release note 
that summarizes all the significant changes that are included since the last production release.

To see all available production releases go to 
https://github.com/NationalGenomicsInfrastructure/miarka-provision/releases

To perform the production deployment, use a similar approach as for the staging deployment (see above for details):

```
    cd /path/to/deployment/resources/miarka-provision
    git checkout master && git fetch --tags && git checkout tags/vX.Y
```
, where "vX.Y" is the production release to deploy.

Deploy and sync the deployment using the playbooks similarly to above:

```
    ssh miarka2.uppmax.uu.se exit
    ansible-playbook -i inventory.yml install.yml -e site=upps -e deployment_environment=production
    ansible-playbook -i inventory.yml install.yml -e site=sthlm -e deployment_environment=production
    ansible-playbook -i inventory.yml sync.yml -e deployment_environment=production
```
This will install your deployment under `/vulpes/ngi/production/<deployment_version>` and move the 
`/vulpes/ngi/production/latest` symlink on `miarka1` and `miarka2` to `/vulpes/ngi/production/<deployment_version>`, 
where `deployment_version` is the git production release tag.

You should now skip down to the procedures for reloading services.

### Create project directories, symlinks and reload services

After the deployment has been synced, each facility need to update the crontab and update project-specific symlinks and 
paths. This should be run once per project (i.e. ngi2016001 and ngi2016003) by a member of each project (probably as the funk 
user). Also, any running services need to be restarted in order to run these from the new deployment.

On the node where the crontab and services are running (e.g. `miarka1` for production instances and `miarka2` for 
staging instances) and as the user currently having the crontab installed, run:
```
    /vulpes/ngi/<deployment_environment>/latest/resources/create_static_contents_<site>.sh
```
Then, as the user running the services needing a reboot, shut down the running instances of the services and re-start 
the new versions of the services.

#### Arteria services

Specifically, the Arteria services are under control by `supervisord` and in order to restart these, 
it is usually sufficient to restart `supervisord`. This can be done by running 
`restart_supervisord_upps.sh`, or preferably `stop_supervisord_upps.sh` and let `cron` start the service again. These 
scripts are located in `/vulpes/ngi/<deployment_environment>/latest/resources/`.

If needed, you can verify the source the arteria services are running from with the command and inspect the command 
arguments listed in the output.  
```
$ ps -eo ppid,pid,user,group,args |grep -e archive-upload-ws -e arteria-checksum-ws -e arteria-delivery-ws
```

You can also verify that the arteria services are running as a subprocess to supervisord by checking that all arteria 
services listed by the command above have the same value in the first column (the `ppid` field). You can also run
```
$ pstree -u funk_004
```
and expect to see the Arteria services ordered under the supervisord process:
```
supervisord─┬─archive-upload-───{archive-upload-}
            ├─checksum-ws───{checksum-ws}
            └─delivery-ws
```
Again, ensure that you are working on the correct login node (`miarka1` for production and `miarka2` for staging) and 
as the user running the services and having the `crontab` installed (probably `funk_004`). 

## Miarka user

In order to automatically have the latest production environment activated upon login, a regular Miarka user should 
make sure to add the following lines to the bash init file `~/.bashrc`:
```
    source /vulpes/ngi/production/latest/conf/sourcme_<site>.sh
    source activate NGI
```
, where `<site>` can be `upps` or `sthlm`, 

## Other

- Always run the `miarkaenv` alias before doing development or deployments in order to assert correct permissions
- Deploying requires the user to be in both the `ngi-sw` and the `ngi` groups
- Everything under `/vulpes/ngi/` is owned by `ngi-sw` and only this group has write access, with the exception of the
    staging project area `/vulpes/ngi/staging/wildwest`, which belongs to the `ngi` group.
- The Ansible log file is found at `/path/to/deployment/resources/log/ansible.log`
- The rsync log file is found at `/vulpes/ngi/<deployment_environment>/<deployment_version>.rsync.log`
