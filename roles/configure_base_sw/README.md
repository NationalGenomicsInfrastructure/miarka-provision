configure_base_sw
=========

Creates file for deployed_tool_versions, which is used by most other roles. Deploys sourceme_common.sh and sourceme_site.sh.

Note that the files created here all have the 'force=no' flag. The implications of this is:
* New ngi versions are deployed in a new directory, so the files are always deployed in these cases
* Running individual roles, such as nextflow, doesn't remove settings from adjesent roles such as anaconda
