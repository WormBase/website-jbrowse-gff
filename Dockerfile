#Note that for the upload command to work, the AWS access key and the AWS
# secret key must be args in the docker run command as environment vaiables, 
# along with the WB release and species with bioproject, as below.
# Example invocation:

#     docker build --no-cache -f Dockerfile -t test-gff . 
#     docker run --rm  \
#                -e "AWS_ACCESS_KEY=<access_key>" \
#                -e "AWS_SECRET_KEY=<secret key>" \
#                 test-wb-gff

# Also note that this image only processes GFF files into NCList json and does
# not deal with processing FASTA data (since it changes relatively infrequently,
# that is the sort of thing that ought to be done "by hand").  It also doesn't
# deal with any other file types like BigWig or VCF.

FROM gmod/jbrowse-gff-base:latest 

LABEL maintainer="scott@scottcain.net"

ARG RELEASE=294

RUN git clone --single-branch --branch main https://github.com/WormBase/website-jbrowse-gff.git
RUN git clone --single-branch --branch jbrowse-$RELEASE https://github.com/WormBase/website-genome-browsers.git
RUN git clone --single-branch --branch master https://github.com/alliance-genome/agr_jbrowse_config.git

RUN cp  /website-jbrowse-gff/single_species_build.sh / && \
    cp  /website-jbrowse-gff/parallel.sh / && \
    cp  /website-genome-browsers/jbrowse/conf/log4perl.conf / && \
    mkdir -p /jbrowse/data/ && \
    cp -r /website-genome-browsers/jbrowse/jbrowse/data /jbrowse/data


VOLUME /data
#ENTRYPOINT ["/bin/sh", "/docker-wrapper.sh"]

#CMD ["/bin/bash", "/single_species_build.sh"]
CMD ["/bin/bash", "/parallel.sh"]
