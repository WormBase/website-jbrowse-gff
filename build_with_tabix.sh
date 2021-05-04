#!/bin/bash
# this is a simple test script for tabix indexing gff

set -e

RELEASE=280
while getopts r:s:a:k: option
do
case "${option}"
in
r) 
  RELEASE=${OPTARG}
  ;;
s) 
  SPECIES=${OPTARG}
  ;;
a)
  AWSACCESS=${OPTARG}
  ;;
k)
  AWSSECRET=${OPTARG}
  ;;
esac
done

if [ -z "$RELEASE" ]
then
    RELEASE=${WB_RELEASE}
fi

if [ -z "$SPECIES" ]
then
    SPECIES=${WB_SPECIES}
fi

if [ -z "$AWSACCESS" ]
then
    AWSACCESS=${AWS_ACCESS_KEY}
fi

if [ -z "$AWSSECRET" ]
then
    AWSSECRET=${AWS_SECRET_KEY}
fi

if [ -z "$AWSBUCKET" ]
then
    if [ -z "${AWS_S3_BUCKET}" ]
    then
        AWSBUCKET=agrjbrowse
    else
        AWSBUCKET=${AWS_S3_BUCKET}
    fi
fi

echo $PATH

wget ftp://ftp.wormbase.org/pub/wormbase/releases/WS280/species/c_elegans/PRJNA13758/c_elegans.PRJNA13758.WS280.annotations.gff3.gz
gzip -d c_elegans.PRJNA13758.WS280.annotations.gff3.gz

gt gff3 -tidy -sortlines -retainids c_elegans.PRJNA13758.WS280.annotations.gff3 > worm.gff

bzgip worm.gff
tabix worm.gff.gz

aws s3 cp --acl public-read worm.gff.gz s3://agrjbrowse/test/WS280/c_elegans_PRJNA13758/worm.gff.gz
aws s3 cp --acl public-read worm.gff.gz.tbi s3://agrjbrowse/test/WS280/c_elegans_PRJNA13758/worm.gff.gz.tbi

 


