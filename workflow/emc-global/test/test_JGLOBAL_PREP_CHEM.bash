#! /bin/bash

set -xue

YYYYMMDDHH="$1"
workarea="$2"
export FIXchem="$3"

export PDY=${YYYYMMDDHH:0:8}
export cyc=${YYYYMMDDHH:8:2}
export cycle=t${cyc}z
export RUNMEM=gec00
export job=jglobal_prep_chem
export envir=para

randhex=$( printf '%02x%02x%02x%02x' $(( RANDOM%256 )) $(( RANDOM%256 )) $(( RANDOM%256 )) $(( RANDOM%256 )) )
testtop="$workarea"/test.$randhex
export COMROOT=$testtop/com
export DATAROOT=$testtop/nwtmp

parent=$( dirname "$0" )
cd "$parent/.."
export HOMEchem=$( pwd -P )

mkdir -p "$testtop"
cd "$testtop"

export BBEM_MODIS_DIR_TODAY=/gpfs/dell2/emc/obsproc/noscrub/Sudhir.Nadiga/MODISfiredata/datafiles/FIRMS/c6/Global/
export BBEM_MODIS_DIR_YESTERDAY=/gpfs/dell2/emc/obsproc/noscrub/Sudhir.Nadiga/MODISfiredata/datafiles/FIRMS/c6/Global/
export BBEM_WFABBA_DIR_TODAY=/gpfs/dell2/emc/obsproc/noscrub/Samuel.Trahan/prep_chem/public/data/sat/nesdis/wf_abba/
export BBEM_WFABBA_DIR_YESTERDAY=/gpfs/dell2/emc/obsproc/noscrub/Samuel.Trahan/prep_chem/public/data/sat/nesdis/wf_abba/

module load prod_util

$HOMEchem/jobs/JGLOBAL_PREP_CHEM
