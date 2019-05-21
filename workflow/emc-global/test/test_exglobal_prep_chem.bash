#! /bin/bash

# This is a test script to demonstrate how to add the
# exglobal_prep_chem.bash to an NCEP workflow.
#
# Inputs:
#   $1 = 2019081312 = date and time to run
#   $2 = path to a scratch space
#   $3 = path to FIXchem

set -xue # This line must be at the top of this script

YYYYMMDDHH="$1" # pass PDY and cyc together for convenience
workarea="$2" # will make a subdirectory here
export FIXchem="$3"

########################################################################
# This section contains information that should come from parm/config
# or higher level in the workflow.
# ----------------------------------------------------------------------

# Specify the resolution; should be in parm/config
export CASE=C384

# Specify data paths to "dcom" -- these should be changed to the
# actual dcom or parallel dcom locations.
export BBEM_MODIS_DATA=/gpfs/dell2/emc/obsproc/noscrub/Sudhir.Nadiga/MODISfiredata/datafiles/FIRMS/c6/Global/MODIS_C6_Global_MCD14DL_NRT_
export BBEM_WFABBA_DATA=/gpfs/dell2/emc/obsproc/noscrub/Samuel.Trahan/prep_chem/public/data/sat/nesdis/wf_abba/f

# The scrub space used by this workflow (nwtmp or experiement area).
# Normally, this would be passed down from the ecflow-level scripts,
# or from Rocoto.
randhex=$( printf '%02x%02x%02x%02x' $(( RANDOM%256 )) $(( RANDOM%256 )) $(( RANDOM%256 )) $(( RANDOM%256 )) )
testtop="$workarea"/test.$randhex

# Set the job's scrub space:
export DATA="$testtop/work"

# Installation area and its subdirectories:
parent=$( dirname "$0" )
cd "$parent/.."
export HOMEchem=$( pwd -P )
export PARMchem=$HOMEchem/parm
EXchem=$HOMEchem/scripts
EXECchem=$HOMEchem/exec

# Specify the name and path to the prep_chem_sources executable:
PREP_CHEM_SOURCES_EXE="$EXECchem/prep_chem_sources_RADM_FV3_SIMPLE.exe"

########################################################################
# This section contains information that should come from automated
# scripts that are specific to the NCEP environment.
# ----------------------------------------------------------------------

# PDY, cyc: normally, setpdy.sh or Rocoto would give you these two,
# but we need these as a script argument:
export PDY=${YYYYMMDDHH:0:8}
export cyc=${YYYYMMDDHH:8:2}

########################################################################
# Everything below this line goes in the actual J-JOB:
# ----------------------------------------------------------------------

set -xue # This line must be at the top of this script

# Job's output directory:
export COMOUTchem="$testtop/com/gens/gefs.$PDY/$cyc/chem/"

# Make sure the alternative date variables are NOT set:
unset SYEAR SDAY SMONTH SHOUR

# The output filename format; note that %INPUT% and %TILE% will be
# replaced automatically:
export CHEM_OUTPUT_FORMAT="gec00.t${cyc}z.chem%INPUT%.tile%TILE%.dat"

# Make sure all pre-installed directories exist:
test -d "$HOMEchem"
test -d "$EXchem"
test -d "$PARMchem"
test -d "$EXECchem"
test -d "$FIXchem"

# Make sure the executable exists, has non-zero size, and is executable:
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
mkdir -p "$DATA"
mkdir -p "$COMOUTchem"
cd "$DATA"

# Pass control to ex-script:
"$EXchem/exglobal_prep_chem.bash"
