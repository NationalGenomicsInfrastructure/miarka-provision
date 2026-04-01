# Deployment playbooks for NGI

This repository concerns the creation and maintenance of the NGI environment; which is a collection of software
and solutions utilized by NGI Production on the currently available HPC.

The NGI environment is currently deployed on Miarka using Ansible playbooks. Ansible playbooks are scripts written for
easily adaptable automated deployment. The Ansible playbooks are stored here.

The deployment is intended to be performed in three stages:
- deployment to a local disk on the deployment node (miarka3)
- synchronize the deployment to the shared file system on the cluster
- create site-specific directories and re-initialize services on the cluster

More in-depth information can be found in [docs](./docs/). Specifically:
* [Repo layout](./docs/repo_layout.md): Describes the overall layout of the repo, where variables are found etc.
* [Setup](./docs/setup.md): Describes how to install the development environment on Miarka, as well a user specific setup needed for a deployer.
* [Deployment](./docs/deployment.md): Describes the deployment process in greater detail than the checklist below. It also describes how to set up a personal development environment.

## Checklist for deployment

Below are the main tasks and commands to perform for a staging or production deployment once the environment and relevant variables has been set up.

* Create a change log
    * This usually means [comparing main to monthly](https://github.com/NationalGenomicsInfrastructure/miarka-provision/compare/main...monthly) and list all changes that will be introduced. Save this list locally.
*  Create the new release **[Production deployment only]**
    * Create a PR to merge monthly into main
    * When merged, create a release. The tag should be `v[YY].[MM]`. For example `v26.03` if the deployment is done in March 2026. The tag should point to the current head of the main branch. Add the change log to the release description.
* Deploy
    * Log on to Miarka3 and perform the following commands:
```
# setup the miarka environment
miarkaenv

# cd to the playbook directory and checkout the correct branch/version
cd /vulpes/ngi/deploy/miarka-provision
git fetch --tags origin
git checkout [monthly / bimonthly / vX.Y]
git pull origin # only needed if checking out a branch (not a tag)

# do deployment to local file system for each site
ansible-playbook -i inventory.yml install.yml -e deployment_environment=[staging / production] -e site=upps
ansible-playbook -i inventory.yml install.yml -e deployment_environment=[staging / production] -e site=sthlm

# sync the deployment to the main vulpes file system
ssh miarka2.uppmax.uu.se exit
ansible-playbook -i inventory.yml sync.yml -e deployment_environment=[staging / production]
```
* Create site-specific directories
    * Run the following as the func account of your site (and ask a deployment team member of other site to run it as theirs):
```
/vulpes/ngi/[staging / production]/latest/resources/create_static_contents_[upps / sthlm].sh
```
* Assess if services should be restarted **[Currently only applicable for Uppsala]**
    * First, determine if a restart is needed
        * In general, web services should be restarted after deployment. There might be reason to wait however, for example if a runfolder is being processed. In that case, discuss with the production team when a restart can be scheduled.
        * A reason to not restart the services is if a bimonthly env is being verified and a new staging env has been deployed. If you are unsure, consult with your team.
    * Log into miarka1 (production) or miarka2 (staging)
    * Stop the services using `vulpes/ngi/<deployment_environment>/latest/resources/stop_supervisord_[site].sh`
    * Verify that all services have stopped (read more about this in docs/deployment.md)
    * Start the services with `vulpes/ngi/<deployment_environment>/latest/resources/start_supervisord_[site].sh`
* Inform about the deployment
    * Post the deployment version and change log in the [miarka provision Slack channel](https://scilifelab.slack.com/archives/G4WSG4C0G)
