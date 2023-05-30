# Tarzan

Ansible role for deploying the Kong (https://konghq.com/kong/) API and microservice management layer, used for proxying and authenticating NGI pipeline web services.

# Architecture

We use a database-less implementation of Kong, so all configuration is done in:
- `kong.conf`: high-level nginx-related items such as certificate paths and ports
- `kong.yml`: configuration of the services and authentication layer

# Singularity Container
We deploy Kong on Miarka using a Singularity container. The Singularity definition file, including the Kong version information, can be found in `files/kong.def`

Due to UPPMAX's security restrictions, the image must be built elsewhere and then uploaded to Miarka. Grab the def file and build on your own machine with: `sudo singularity build kong.sif kong.def`

The resulting image should be uploaded to the path defined by `tarzan_singularity_image_file_src` in `defaults/main.yml`.

Finally, run the following command on the image file: `sha1sum /path/to/kong.sif`

Set `tarzan_singularity_image_sha1` in `defaults/main.yml` to this value.

# Certificates

It is recommended to have separate certificates for staging and production.

On the node running Kong, run:
```
openssl req -config <tarzan_conf_dir>/tarzan_cert_config.txt -newkey rsa:2048 -nodes -keyout tarzan_key.pem -x509 -days 1460 -out tarzan_cert.pem
```

Move the generated certificate and key to the paths defined by `tarzan_cert_file` and `tarzan_key_file` in `env_vars/site_[site]_env_[environment].yml`.

# Authentication

The Kong `key-auth` plugin is enabled on all routes.

Because we use a database-less implementation, we must generate our own API key and then put it in the appropriate `env_secrets` file with the key `tarzan_api_key`. You can generate a new key with e.g.:

`echo $RANDOM | md5sum | head -c 32; echo;`

It is recommended to have a separate key for staging and production.

# Starting / Stopping / Restarting Kong

Kong is started automatically by `cron` and usually, there is no need to manually restart or interact with Kong.
Specifically, `cron` will run the script `templates/start_kong.sh.j2` every hour, which will restart the Kong instance
(or start a new instance if it is not running).

If needed to explicitly interact with the Kong singularity image, refer to the script above for commands.
