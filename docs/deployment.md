# Deployment of the Miarka software

There are two staging branches in the repository, one called monthly and the other bimonthly. The changes that do not need extensive testing and validation on stage should be pushed to the monthly branch, which is used to make stage and production deployments on a monthly cycle. Changes that need time for validation on stage (like pipeline version updates) should be pushed to the bimonthly branch.

Production deployments on the monthly release cycle are done on the last Monday of each month. A stage deployment from the monthly branch will be made two weeks before this date and the introduction of new changes to the monthly branch will be frozen. Only fixes to changes already merged will be approved to the monthly branch during this time.

Stage deployments from the bimonthly branch can be made outside of the monthly release cycle. The changes on the bimonthly branch would generally be pulled to the monthly branch and deployed to production in the monthly release cycle once all validations are complete.

## Requirements

The git repository does not contain any sensitive credentials. Instead, these need to be specified in the correct file under `env_vars` and `env_secrets` in the checked out `miarka-provision` folder you will be deploying from. In practice, you will probably copy these files from `/vulpes/ngi/deploy` or from the last deployment and only modify them when something needs changing.

Below is a list of variables that are expected to be defined:

### SNP&SEQ

In `env_secrets/site_upps_env_*.yml`:

```
charon_api_token
megaqc_access_token
tarzan_api_key
tower_workspace_id
```

In addition, valid SSL certificates for the web proxy need to be available on the main `vulpes` file system (i.e. accessible from `miarka1` and `miarka2`) under the path specified by the variable `tarzan_cert_path`. See `roles/tarzan/README.md` for details.

### NGI-S

In `env_secrets/site_sthlm_env_*.yml`:

```
charon_api_token
megaqc_access_token
orderportal_api_token
statusdb_password
statusdb_username
tower_workspace_id
```

## Development deployment

Typically roles are developed (or at least tested) locally on `miarka3`.

Start by forking the repository https://github.com/NationalGenomicsInfrastructure/miarka-provision to your private Github repo. On Miarka3, create a directory called `/vulpes/ngi/devel-<username>`. Clone you fork to this directory.

There you can develop your own Ansible roles in your private feature branch.

In `env_vars/` and `env_secrets/` you can find example variable files that can be used as a basis for
`deployment_environment`- or `site`-specific variable files:
```
cp env_vars/site_all_env_devel.yml.example env_vars/site_all_env_devel.yml
cp env_secrets/site_all_env_all.yml.example env_secrets/site_upps_env_devel.yml
```

Tip: The easiest way to get sensible devel vars is to copy them from another user's devel env.

If you want to test your roles/playbook, run:
```
    cd /path/to/development/resources/miarka-provision
    ansible-playbook -i inventory.yml -e site=upps install.yml
    ansible-playbook -i inventory.yml -e site=sthlm install.yml
```
This will install your development under `/vulpes/ngi/devel-<username>/<branch_name>.<date>.<commit hash>`

You can also run the sync playbook to test this functionality but in the devel environment, the rsync command will always run in `--dry-run` mode, so no data will be transferred.

Before doing the sync, make sure that a SSH master connection is active:
```
    ssh miarka2.uppmax.uu.se exit
```
Then do the sync with:
```
    ansible-playbook -i inventory.yml sync.yml
```

When you are satisfied with your changes you need to test it in staging. To do this, you must create a pull request to one of the two staging branches of miarka-provision and, once the feature has been approved, do a staging deployment.

## Staging deployment

To perform a deployment from one of the staging branches (monthly or bimonthly), navigate to the location of the repo and make sure that the desired branch is checked out and updated:
```
    cd /path/to/deployment/resources/miarka-provision
    git checkout [monthly/bimonthly]
    git pull origin [monthly/bimonthly]
```
Do the staging deployment to the local disk by running the `install.yml` playbook, once for each site, and specify the `deployment_environment` argument:
```
    ansible-playbook -i inventory.yml install.yml -e deployment_environment=staging -e site=upps
    ansible-playbook -i inventory.yml install.yml -e deployment_environment=staging -e site=sthlm
```
This will install your deployment under `/vulpes/ngi/staging/<deployment_version>`, where `deployment_version` is automatically constructed by the playbook according to `<date>.<commit hash>[-bimonthly]` (the `-bimonthly` suffix is added in case of a bimonthly deployment). If needed, you can override the deployment_version by passing `-e deployment_version=VERSION` to the playbook.

The `sync.yml` playbook is used to sync the deployment to the cluster and shared filesystem.

Before doing the sync, make sure that a SSH master connection is active:
```
    ssh miarka2.uppmax.uu.se exit
```
Then do the sync, specifying the deployment_environment:
```
    ansible-playbook -i inventory.yml sync.yml -e deployment_environment=staging
```

This will also move the `/vulpes/ngi/staging/latest` symlink on `miarka1` and `miarka2` to `/vulpes/ngi/staging/<deployment_version>`.

When everything is synced properly then login to the cluster as your personal user and source the new environment and activate the NGI conda environment (where `site` is `upps` or `sthlm` depending on location):
```
    source /vulpes/ngi/staging/latest/conf/sourceme_<site>.sh && source activate NGI
```
For convenience, add this to your personal bash init file `~/.bashrc` on `miarka1` or `miarka2`. This will load the staging environment for your user with the appropriate staging variables set.

You should now skip [down](#create-project-directories-symlinks-and-reload-services) to the procedures for reloading services.

When the staged environment has been verified to work OK, proceed with making a pull request from the staging branch to the master branch of the repository.

## Production deployment

Once all pull requests to monthly are approved and merged, create a production release at
https://github.com/NationalGenomicsInfrastructure/miarka-provision/releases/new. Make sure to write a good release note that summarizes all the significant changes that are included since the last production release.

To see all available production releases go to
https://github.com/NationalGenomicsInfrastructure/miarka-provision/releases

To perform the production deployment, use a similar approach as for the staging deployment (see above for details):

```
    cd /vulpes/ngi/staging/miarka-provision
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
This will install your deployment under `/vulpes/ngi/production/<deployment_version>` and move the `/vulpes/ngi/production/latest` symlink on `miarka1` and `miarka2` to `/vulpes/ngi/production/<deployment_version>`, where `deployment_version` is the git production release tag.

## Create project directories, symlinks and reload services

After the deployment has been synced, each facility need to update the crontab and update project-specific symlinks and paths. This should be run once per project (i.e. ngi2016001 and ngi2016003) by a member of each project (probably as the funk user). Also, any running services need to be restarted in order to run these from the new deployment.

On the node where the crontab and services are running (e.g. `miarka1` for production instances and `miarka2` for staging instances) and as the user currently having the crontab installed, run:
```
    /vulpes/ngi/<deployment_environment>/latest/resources/create_static_contents_<site>.sh
```
Then, as the user running the services needing a reboot, shut down the running instances of the services and re-start the new versions of the services.

### Arteria services

IMPORTANT: Ensure that you are working on the correct login node (`miarka1` for production and `miarka2` for staging) and as the user running the services and having the `crontab` installed (probably `funk_004`)

Specifically, the Arteria services are under control by `supervisord` and in order to restart these, 
it is usually sufficient to restart `supervisord`. This can be done by running `<stop/start>_supervisord_upps.sh` scripts. These scripts are located in `/vulpes/ngi/<deployment_environment>/latest/resources/`.

You can verify that the services are running with this command
```
$ pstree -u funk_004
```
and expect to see the Arteria services ordered under the supervisord process:
```
supervisord─┬─archive-upload-───{archive-upload-}
            ├─archive-verify-───{archive-verify-}
            ├─arteria-deliver───delivery-ws
            ├─arteria_sequenc───sequencing-repo
            ├─checkqc-ws───63*[{checkqc-ws}]
            ├─checksum-ws─┬─2*[md5sum]
            │             └─{checksum-ws}
            ├─metadata-servic───{metadata-servic}
            ├─redis-server───4*[{redis-server}]
            └─rq───{rq}

```

If needed, you can verify that the arteria services are started from the correct source (i.e. verify that they are started from the expected deployment version) using this command:
```
$ ps -eo ppid,pid,user,group,args |grep -e archive - arteria
```
Example output:
```
[...]
   4337    4623 funk_004 funk_004 /vulpes/ngi/production/v26.02/sw/anaconda/envs/arteria-delivery-ws/bin/python3.13 /vulpes/ngi/production/v26.02/sw/anaconda/envs/arteria-delivery-ws/bin/delivery-ws --configroot=/vulpes/ngi/production/v26.02/conf//arteria/arteria-delivery-ws --port=10440
[...]
```
Here it can be seen that the arteria-delivery service is started from the v26.02 environment.

Another way to verifying that the services have been started successfully is to inspect `/proj/ngi2016001/private/log/supervisord/supervisord.log`.

#### Step by step
1. Log in to the correct login node (`miarka1` for production and `miarka2` for staging)
2. Log in as `funk_004`
3. Run the script `/vulpes/ngi/<production,staging>/latest/resources/stop_supervisord_upps.sh`
4. Check the services from the previous deployment are no longer running
```bash
pgrep -fl vYY.MM
```
5. Start the services from the new deployment
```bash
/vulpes/ngi/<production,staging>/latest/resources/start_supervisord_upps.sh
```
6. Verify that the services are running as expected
```bash
pstree -u funk_004
```

## Miarka user

In order to automatically have the latest production environment activated upon login, a regular Miarka user should make sure to add the following lines to the bash init file `~/.bashrc`:
```
    source /vulpes/ngi/production/latest/conf/sourceme_<site>.sh
    source activate NGI
```
, where `<site>` can be `upps` or `sthlm`.

## Other

- Always run the `miarkaenv` alias before doing development or deployments in order to assert correct permissions
- Deploying requires the user to be in both the `ngi-sw` and the `ngi` groups
- Everything under `/vulpes/ngi/` is owned by `ngi-sw` and only this group has write access, with the exception of the
    staging project area `/vulpes/ngi/staging/wildwest`, which belongs to the `ngi` group.
- The Ansible log file is found at `/vulpes/ngi/deploy/resources/log/ansible.log`
- The rsync log file is found at `/vulpes/ngi/<deployment_environment>/<deployment_version>.rsync.log`
