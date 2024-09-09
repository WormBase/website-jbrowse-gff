website-jbrowse-gff

Dockerfile for processing GFF data for JBrowse

This README encompasses not only what is contained in this repo but also documents how
it fits in with the Alliance of Genome Resources data and server pipelines, as well as
the the data processing and JBrowse server tools in the `website-genome-browsers` repo
in the `jbrowse-*` branches.

# Overview

The Dockerfile in this repo codes for a data processing tool that fetches GFF from
the WormBase FTP site, processes it into JBrowse NCList json format, generates
search index files, generates "preliminary" trackList.json files for each
assembly (indicating what data types are available for each), and deposits
the results in the Alliance JBrowse S3 bucket. This processing is currently configured
to run through the Alliance GoCD system and making use of the ridiculously parallelizable
nature of processing data from many assemblies. If running on a single CPU is desired,
the `single_species` branch can be used (it is somewhat misleadingly named, as it will run all species, but one at a time).

# Workflow

When starting a new release, a release-specific branch is created from the
`jbrowse-staging` branch, typically called `jbrowse-$RELEASE`. Usually, only
two changes need to be made for a release: A) bump the `RELEASE=` line in
`/website-genome-browsers/jbrowse/Dockerfile`, and B) bump the release number
in `/website-genome-browsers/jbrowse/plugins/wormbase-glyphs/js/main.js` (look
for "WS$REELASE" in this file to find what needs to be updated). 
Once the release number has been pushed into the release specific repo in 
website-genome-browser, two changes need to be made in this repo:

1. The Dockerfile in this repo should be updated to change the value of the RELEASE
   ARG to the current release number:

```
ARG RELEASE=293
```

2. A similar line in the parallel.sh script should also be changed:

```
RELEASE=293
```

Both of these changes should be committed back to the main branch of this repo.

Note that both of these items could potentially be parameterized and passed in when
running though Ansible using the `$MOD_RELEASE_VERSION` environment variable in the
agr_ansible_devops WormBase specific environment
(https://github.com/alliance-genome/agr_ansible_devops/blob/master/environments/jbrowse/wb.yml),
but this hasn't been hooked up yet.

When these changes are commited to the main branch, the GoCD system will run the
`JBrowseSoftwareProcessWB` pipeline to build the Dockerfile in this repo, and then
run the `JBrowseProcessWB` pipeline, which will run a compute machine through Ansible
to process the WormBase GFF files. The script that it runs, `parallel.sh` uses
GNU parallel to process all of the assemblies in WormBase (currently 31). After
processing the the files, the script will upload the JBrowse data to the Alliance
JBrowse S3 bucket (agrjbrowse).

IMPORTANT NOTE about GoCD: typically, the `JBrowseSoftwareProcessWB` and
`JBrowseProcessWB` are paused to prevent them from accidentally running when
updates to this repo are commited. Be sure to unpause them when you want these
pipelines to run.

# Building JBrowse servers

See the documentation in https://github.com/WormBase/website-genome-browsers/blob/master/README.md
for build procedures for the AWS Amplify-powered JBrowse instances.
