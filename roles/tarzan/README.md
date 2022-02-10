# Tarzan

Ansible role for deploying the Kong (https://konghq.com/kong/) API and microservice management layer, used for proxying and authenticating NGI pipeline web services.

# Architecture

We use a database-less implementation of Kong, so all configuration is done in:
- `kong.conf`: high-level nginx-related items such as certificate paths and ports
- `kong.yml`: configuration of the services and authentication layer

# Singularity Container
We deploy Kong on Miarka using a Singularity container. The Singularity definition file, including the Kong version information, can be found in `files/kong.def`

Due to UPPMAX's security restrictions, the image must be built elsewhere and then uploaded to Miarka. Grab the def file and build on your own machine with: `sudo singularity build kong.sif kong.def`

The resulting image should be uploaded to the path defined in `tarzan_singularity_image_file_src`.

Finally, run the following command on the image file: `sha1sum /path-to-kong.sif`

Set `tarzan_singularity_image_sha1` to this value.

# Certificates

It is recommended to have a separate certificates for staging and production.

On the node running Kong, run: `openssl req -x509 -newkey rsa:2048 -keyout tarzan_key.pem -out tarzan_cert.pem -days 1460 -nodes -subj '/CN=miarka2.uppmax.uu.se'`.

Move the generate certificate and key to the paths defined in `tarzan_cert_file` and `tarzan_key_file`.

# Authentication

The Kong `key-auth` plugin is enabled on all routes.

Because we use a database-less implementation, we must generate our own API key and then put it in the appropriate `env_secrets` file with the key `tarzan_api_key`. You can generate a new key with e.g.:

`echo $RANDOM | md5sum | head -c 32; echo;`

It is recommended to have a separate key for staging and production.
