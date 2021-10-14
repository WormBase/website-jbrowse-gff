website-jbrowse-gff

Dockerfile for processing GFF data for JBrowse

This README encompasses not only what is contained in this repo but also documents how
it fits in with the Alliance of Genome Resources data and server pipelines, as well as
the the data processing and JBrowse server tools in the `website-genome-browsers` repo
in the `jbrowse-*` branches.

Overview
========

Workflow
========

Building JBrowse servers
========================

Building the production server
------------------------------


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
