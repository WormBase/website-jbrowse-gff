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

#wget ftp://ftp.wormbase.org/pub/wormbase/releases/WS280/species/c_elegans/PRJNA13758/c_elegans.PRJNA13758.WS280.annotations.gff3.gz
#gzip -d c_elegans.PRJNA13758.WS280.annotations.gff3.gz

wget http://sgd-archive.yeastgenome.org/sequence/S288C_reference/genome_releases/S288C_reference_genome_R64-3-1_20210421.tgz
tar zxvf  S288C_reference_genome_R64-3-1_20210421.tgz
gzip -d S288C_reference_genome_R64-3-1_20210421/saccharomyces_cerevisiae_R64-3-1_20210421.gff.gz 
cp S288C_reference_genome_R64-3-1_20210421/saccharomyces_cerevisiae_R64-3-1_20210421.gff yeast.gff
perl -pi -e 's/\t\.\t0\t\./\t.\t.\t./' yeast.gff



gt gff3 -tidy -sortlines -retainids yeast.gff > yeast.tidy.gff 

bgzip yeast.tidy.gff
tabix yeast.tidy.gff.gz

aws s3 cp --acl public-read yeast.tidy.gff.gz s3://agrjbrowse/test/yeast/yeast.tidy.gff.gz
aws s3 cp --acl public-read yeast.tidy.gff.gz.tbi s3://agrjbrowse/test/yeast.tidy.gff.gz.tbi

 


