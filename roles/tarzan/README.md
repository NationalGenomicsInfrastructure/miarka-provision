# Tarzan

Ansible role for deploying the Kong (https://konghq.com/kong/) API and microservice management layer.

To be used for e.g. proxying other NGI pipeline web services and adding an authentication layer on top.

# Kong

We deploy Kong on Miarka using a Singularity container.

The Singularity definition file, including the Kong version information, can be found in `files/kong.def`

Due to UPPMAX's security restrictions, the image must be built elsewhere and then uploaded to Miarka.

Grab the def file and build on your own machine: `sudo singularity build kong.sif kong.def`

The resulting image should be uploaded to the path defined in `tarzan_singularity_image_file` in `defaults/main.yml`.
