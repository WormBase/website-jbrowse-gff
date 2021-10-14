website-jbrowse-gff

Dockerfile for processing GFF data for JBrowse

This README encompasses not only what is contained in this repo but also documents how
it fits in with the Alliance of Genome Resources data and server pipelines, as well as
the the data processing and JBrowse server tools in the `website-genome-browsers` repo
in the `jbrowse-*` branches.

Overview
========

The Dockerfile in this repo codes for a data processing tool that fetches GFF from
the WormBase FTP site, processes it into JBrowse NCList json format, and deposits
the results in the Alliance JBrowse S3 bucket. This processing is currently configured
to run through the Alliance GoCD system and making use of the ridiculously parallelizable
nature of processing data from many assemblies. If running on a single CPU is desired,
the `single_species` branch can be used (it is somewhat misleadingly named, as it will run all species, but one at a time).

Also running in the GoCD system at the Alliance are development/staging and production
versions of JBrowse configured to make use of these data.

Workflow
========

When starting a new release, a release-specific branch is created from the 
`jbrowse-staging` branch, typically called `jbrowse-$RELEASE`. Usually, the only
change that needs to be made for a release is to bump the `RELEASE=` line in
/website-genome-browsers/jbrowse/Dockerfile`. Once the release number has been
pushed into the release specific repo in website-genome-browser, two changes
need to be made in this repo:

1. The Dockerfile in this repo should be updated to change the github branch of
website-genome-browsers in the line
```
RUN git clone --single-branch --branch jbrowse-282 https://github.com/WormBase/website-genome-browsers.git
```

2. The line RELEASE=282 in parallel.sh should be updated the the current release.

Note that both of these items could potentially be parameterized and passed in when
running though Ansible using the $MOD_RELEASE_VERSION environment variable in the
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

Building JBrowse servers
========================

There are two servers for JBrowse instances:

1. http://jbrowse_wb_dev.alliancegenome.org/tools/genome/jbrowse/ for development/staging

2. http://jbrowse_wb_prod.alliancegenome.org/tools/genome/jbrowse/ for production

Both the development and production servers follow the same build procedure. The
GoCD pipeline for building the server container builds automatically when there are
commits to the branches in website-genome-browsers are commited to. For
development/staging, the jbrowse_staging branch is watched, and for production, it
watches jbrowse_production.

To create a staging version:

1. Create a `jbrowse-$RELEASE` branch of the website-genome-browsers repo off of the
`jbrowse_staging` branch.

2. Edit the Dockerfile at /website-genome-browsers/jbrowse/Dockerfile in that branch
to update the `ARG RELEASE=` line to update the release version,

3. Push this change to the `jbrowse-$RELEASE` github branch. At this point, local test
versions of the server can be created from the Dockerfile.

4. To update the staging server, merge these changes into the `jbrowse_staging` branch
which will cause GoCD to rerun the `JBrowseWBDev` pipeline, which rebuilds the server
container, then the `JBrowseWBDevServer` pipeline which moves the container onto the
server machine and starts it, and then finally runs the `NginxJBrowse` pipeline to
restart the proxy nginx server to point at the new server container. This rebuild
process can take up to 15 minutes. Note that the final step of restarting the nginx
proxy must be manually triggered in the GoCD website.

Building the production server
------------------------------

To create a production version merge the changes in the `jbrowse_staging` branch into
the `jbrowse_production` branch, which will cause GoCD to rebuild the server container
similarly to step four above, execpt that it runs the `JBrowseWBProd` and
`JBrowseWBProdServer` pipelines.

Older docs for previous procedure
=================================

Note that for the upload command to work, the AWS access key and the AWS
secret key must be args in the docker run command as environment vaiables,
along with the WB release and species with bioproject, as below.
Example invocation:

    docker build --no-cache -f Dockerfile -t gff-processor .
    docker run --rm  \
               -e "WB_RELEASE=280" \
               -e "WB_SPECIES=c_nigoni_PRJNA384657" \
               -e "AWS_ACCESS_KEY=<access_key>" \
               -e "AWS_SECRET_KEY=<secret key>" \
                gff-processor

The script "single_species_build.sh" is currently hard coded to do the processing
and assumes that the target S3 bucket is the one used for AGR's main JBrowse
instance, agrjbrowse, and the path is /mod-jbrowses/test (but this will change with the
next WB release) (perhaps this should be parameterized too).

Also note that this image only processes GFF files into NCList json and does
not deal with processing FASTA data (since it changes relatively infrequently,
that is the sort of thing that ought to be done "by hand").  It also doesn't deal
with any other file times like BigWig or VCF.
