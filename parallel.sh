#!/bin/bash

#set -e

RELEASE=290
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

SPECIESLIST=(
't_muris_PRJEB126'
#'c_elegans_PRJNA13758'
'p_pacificus_PRJNA12644'
#'c_nigoni_PRJNA384657'
'b_malayi_PRJNA10729'
#'c_angaria_PRJNA51225'
#'c_remanei_PRJNA577507'
'c_brenneri_PRJNA20035'
'c_briggsae_PRJNA10731'
#'c_elegans_PRJNA275000'
#'c_japonica_PRJNA12591'
'c_remanei_PRJNA53967'
#'c_sinica_PRJNA194557'
#'c_tropicalis_PRJNA53597'
'o_volvulus_PRJEB513'
#'p_redivivus_PRJNA186477'
's_ratti_PRJEB125'
#'c_elegans_PRJEB28388'
#'c_inopinata_PRJDB5687'
#'c_latens_PRJNA248912'
#'o_tipulae_PRJEB15512'
#'c_becei_PRJEB28243'
#'c_bovis_PRJEB34497'
#'c_panamensis_PRJEB28259'
#'c_parvicauda_PRJEB12595'
#'c_quiockensis_PRJEB11354'
#'c_sulstoni_PRJEB12601'
#'c_tribulationis_PRJEB12608'
#'c_uteleia_PRJEB12600'
#'c_waitukubuli_PRJEB12602'
#'c_zanzibari_PRJEB12596'
)

MAKEPATH=/website-genome-browsers/jbrowse/bin/make_jbrowse.pl

CONFPATH=/website-genome-browsers/jbrowse/conf/c_elegans.jbrowse.conf

#LOGFILE=$SPECIES
#LOGFILE+=".log"

#this is by far the longest running portion of the script (typically a few hours)
#$MAKEPATH $SKIPFLATFILE --conf $CONFPATH --quiet --species $SPECIES 2>1 | grep -v "Deep recursion"; mv 1 $LOGFILE
echo "starting processing gff files"
parallel -j "50%" $MAKEPATH --release $RELEASE --quiet --conf $CONFPATH  --species {} ::: "${SPECIESLIST[@]}"

INLINEINCLUDEPATH=/website-genome-browsers/jbrowse/bin/inline_includes.pl

DATADIR=/jbrowse/data

cd $DATADIR

#expand out include files
for species in "${SPECIESLIST[@]}"; do
    cp $species/trackList.json $species/trackList.json.orig
    $INLINEINCLUDEPATH --bio $species --rel "$RELEASE" --file $species/trackList.json > $species/trackList.json.new
    cp $species/trackList.json.new $species/trackList.json
done

UPLOADTOS3PATH=/agr_jbrowse_config/scripts/upload_to_S3.pl

# this path will need to be fixed for "real" releases. Something like:
#REMOTEPATH="MOD-jbrowses/WormBase/WS$RELEASE/$SPECIES"
#REMOTEPATH="test/WS$RELEASE/$SPECIES"

#$UPLOADTOS3PATH $ONLYTRACKLIST --bucket $AWSBUCKET --local "$SPECIES/" --remote $REMOTEPATH --AWSACCESS $AWSACCESS --AWSSECRET $AWSSECRET
parallel -j "50%"  $UPLOADTOS3PATH --bucket $AWSBUCKET --local {1}"/" --remote "MOD-jbrowses/WormBase/WS$RELEASE/"{1} --AWSACCESS $AWSACCESS --AWSSECRET $AWSSECRET ::: "${SPECIESLIST[@]}"
 


