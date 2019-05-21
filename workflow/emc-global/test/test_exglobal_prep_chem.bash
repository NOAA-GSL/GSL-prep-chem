#! /bin/bash

# This is a test script to demonstrate how to add the
# exglobal_prep_chem.bash to an NCEP workflow.
#
# Inputs:
#   $1 = 2019081312 = date and time to run
#   $2 = path to a scratch space
#   $3 = path to FIXchem

set -xue

YYYYMMDDHH="$1" # pass PDY and cyc together for convenience
workarea="$2" # will make a subdirectory here
export FIXchem="$3"

########################################################################

# PDY, cyc: normally, setpdy.sh would give you these two, but we need
# these as a script argument:

export PDY=${YYYYMMDDHH:0:8}
export cyc=${YYYYMMDDHH:8:2}

# Make sure the optional variables are NOT set:
unset SYEAR SDAY SMONTH SHOUR NLN NCP

# Specify data paths to "dcom" -- these should be updated in the
# actual workflow.
export BBEM_MODIS_DATA=/gpfs/dell2/emc/obsproc/noscrub/Sudhir.Nadiga/MODISfiredata/datafiles/FIRMS/c6/Global/MODIS_C6_Global_MCD14DL_NRT_
export BBEM_WFABBA_DATA=/gpfs/dell2/emc/obsproc/noscrub/Samuel.Trahan/prep_chem/public/data/sat/nesdis/wf_abba/f

# Randomly generate a scrub space directory name:
randhex=$( printf '%02x%02x%02x%02x' $(( RANDOM%256 )) $(( RANDOM%256 )) $(( RANDOM%256 )) $(( RANDOM%256 )) )
testtop="$workarea"/test.$randhex

# Set the data locations:
export DATA="$testtop/work"
export COMOUTchem="$testtop/com/gens/gefs.$PDY/$cyc/chem/"
export CHEM_OUTPUT_FORMAT="gec00.t${cyc}z.chem<input>.tile<tile>.dat"

# Figure out HOMEchem and its subdirectories:
parent=$( dirname "$0" )
cd "$parent/.."
export HOMEchem=$( pwd -P )
export PARMchem=$HOMEchem/parm
EXchem=$HOMEchem/scripts
EXECchem=$HOMEchem/exec

# Make sure all pre-installed directories exist:
test -d "$HOMEchem"
test -d "$EXchem"
test -d "$PARMchem"
test -d "$EXECchem"
test -d "$FIXchem"

# Specify the name of the prep_chem_sources executable:
PREP_CHEM_SOURCES_EXE="$EXECchem/prep_chem_sources_RADM_FV3_SIMPLE.exe"
test -s "$PREP_CHEM_SOURCES_EXE"
test -x "$PREP_CHEM_SOURCES_EXE"

# Figure out how to run the prep_chem_sources:
if [[ -d /gpfs && -s /etc/SuSE-release ]] && ( which aprun ) ; then
    # On CRAY in a batch job, the prep_chem_sources must be run via aprun:
    PREP_CHEM_SOURCES_EXE="aprun -n 1 -j 1 $PREP_CHEM_SOURCES_EXE"
fi

# Export the execution information so the ex-script can see it:
export PREP_CHEM_SOURCES_EXE

# Make sure we have a fresh, new, scrub space:
if [ ! -d "$testtop" ] ; then
    rm -rf "$testtop"
fi
mkdir "$DATA"
mkdir "$COMOUTchem"
cd "$DATA"

# Pass control to ex-script:
"$EXchem/exglobal_prep_chem.bash"
