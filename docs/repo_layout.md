# Repo layout

## Ansible-specific content

`inventory.yml` defines the host addresses where tasks will be run

The main playbooks are `install.yml`, for deploying to the local disk and `sync.yml` for syncing the deployment to the
shared filesystem.

Common tasks used e.g. for setting up variables and paths required for deployment or syncing are defined under `tasks/`.

Typically, each software or function has its own role for deployment and these are defined under `roles/`.

### Variables

In ansible, variables can be defined in a number of different locations depending on context, precedence etc. The location where you should define a variable will thus very depending on the circumstances. Below are a few rules-of-thumb to help you identify where to find or define a variable.

#### `env_vars`
The conditions this playbook can be run under will mainly be a combination of `deployment_environment` (i.e. one of `devel`, `staging` or `production`) and `site` (i.e. one of `sthlm` and `upps`). Therefore, variables that depend on the specific `deployment_environment` and/or `site` are located in the corresponding variable file (named according to `site_[all | sthlm | upps]_env_[all | devel | staging | production ].yml`) in the `env_vars/` folder. When the playbook is run, the appropriate variable files will automatically be imported.

In `env_vars/` you can find an example variable file that can be used as a basis for `deployment_environment`- or `site`-specific variable files.

#### `env_secrets`
Similar to the `env_vars/` folder, the `env_secrets/` folder contains variable files organized in the same way according to `deployment_environment` and `site`. This is where variables that should be kept secret (e.g. api-keys, passwords etc.) should be defined. These variable files will be ignored by `git` and should thus never be checked in.

In `env_secrets/` you can find an example variable file that can be used as a basis for `deployment_environment`- or `site`-specific variable files.

#### `role / defaults`
Variables that are only used within a role and are independent of `deployment_environment` and `site` should be defined within the role, e.g. in `defaults/main.yml`.

#### `host_vars`

Variables that are used across roles or in the main plays and are specific to a host (e.g. the `deploy` host) should be defined in `host_vars/[host_name]/` (where `host_name` corresponds to the host name used in `inventory.yml`. Note that although these variables should in general be independent of `deployment_environment` and `site`, some may be overridden or depend implicitly on variables in `env_vars/`. In other words, these are dynamically resolved when the play executes.

#### `group_vars`

Variables that are used across roles or in the main plays and are specific for a group are defined under `group_vars/`. Currently, this only includes `all` which means that the variables are accessible to all hosts and throughout the playbooks.


### Other

The `docker/` directory contains files used for building a Singularity (and Docker) image that can be used for running Ansible.
