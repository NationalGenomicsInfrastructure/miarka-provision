# Setup

How to set up the miarka-provision environment for deployments. If the main setup is already setup and you only are interested in user specific setup instructions, skip to [User prerequisites](#user-prerequisites)

## Setting up Ansible for deployments

### Building a singularity image

The container needs to be built in an environment where the user can have sufficient privileges. This is not possible on Miarka.

If there is already a current singularity image available in `/vulpes/ngi/deploy` on `miarka3` you should use this.

The singularity image is built from a Docker image whose definition file is available at `docker/Dockerfile`.

To build the singularity image, clone this repository and run `docker/build_singularity.sh`. This will create a singularity image, `miarka-ansible.<commit hash>.sif` in the working directory. The image itself is not dependent onchanges to the miarka-provision repo, with the exception to changes in the `docker` folder. For clarity, the image will be tagged with the git commit hash of the repo that the image was built from.

The singularity image can be then be uploaded to `miarka3` and used for deployment. When you are confident that the image is stable and should be used in production, move it to the `/vulpes/ngi/deploy` folder and move the `miarka-ansible.sif` symlink to point to this image.


### Setting up the environment for using the singularity image

On `miarka3`, clone the `miarka-provision` repo by running:

```
cd /vulpes/ngi/deploy
singularity run miarka-ansible.sif
```

This will clone the devel branch of this repo under the current working directory and copy the `bootsrap/bashrc` file here.

## User prerequisites

Each usser should add the following lines into `~/.bashrc`:

```
alias miarkaenv='source /vulpes/ngi/deploy/bashrc'
alias ansible-playbook='singularity run --bind /vulpes,/sw,/scratch /vulpes/ngi/deploy/miarka-ansible.sif ansible-playbook'
```

Before a user starts developing new Ansible playbooks/roles or deploy them, the current umask and GID needs to be set.This is accomplished by *manually* running the bash alias: `miarkaenv` (defined above).

### SSH multiplexing
For syncing deployments to the target host, it is necessary to set up the environment so that connections can be made to the target host without needing interaction from the user (which ansible doesn't support). This can be done with ssh-multiplexing. Add the following to the `~/.ssh/config` file (create the file first if it doesn't exist):
```
Host *.uppmax.uu.se
    ControlMaster auto
    ControlPath ~/.ssh/master-%r@%h:%p.socket
    ControlPersist 60m
```
This will establish a SSH connection that will persist for 60 min after an initial connection has been made, which will be re-used by subsequent SSH connections, even if the initial session has been closed.
