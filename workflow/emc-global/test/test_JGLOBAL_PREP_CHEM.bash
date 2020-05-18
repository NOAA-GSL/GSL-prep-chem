#! /bin/bash

# IMPLEMENTATION NOTE: This script should be converted to an ecf file
# for ecflow (guidance below).

set -xue

# These three lines would not be present in the ecf file; they're here
# to make this script parameterizable:
YYYYMMDDHH="$1"
workarea="$2"
export FIXchem="$3"

# The PDY, cyc, and cycle should not be in the ecf file either; the
# JGLOBAL_PREP_CHEM will define them.  We have them here to override
# the date, and force JGLOBAL_PREP_CHEM to use the $1 date/time
# instead of now:
export PDY=${YYYYMMDDHH:0:8}
export cyc=${YYYYMMDDHH:8:2}
export cycle=t${cyc}z

# For test purposes, generate random com and nwtmp locations.  This
# section would not be in the ecf file; they're defined in envir-*.h:
randhex=$( printf '%02x%02x%02x%02x' $(( RANDOM%256 )) $(( RANDOM%256 )) $(( RANDOM%256 )) $(( RANDOM%256 )) )
testtop="$workarea"/test.$randhex
export COMROOT=$testtop/com
export DATAROOT=$testtop/nwtmp

# Figure out where the HOMEchem is installed based on the location of
# this script; this block would not exist in the ecf file.
parent=$( dirname "$0" )
cd "$parent/.."
export HOMEchem=$( pwd -P )
mkdir -p "$testtop"
cd "$testtop"

# Here, we use hard-coded dev areas for data.  Instead, the
# JGLOBAL_PREP_CHEM should be updated with the dcom locations, and
# these lines should be deleted:
export BBEM_MODIS_DIR_TODAY=/gpfs/dell2/emc/obsproc/noscrub/Samuel.Trahan/prep_chem/TEST_DATA/BBEM_MODIS_DIR/
export BBEM_MODIS_DIR_YESTERDAY="$BBEM_MODIS_DIR_TODAY"
export BBEM_WFABBA_DIR_TODAY=/gpfs/dell2/emc/obsproc/noscrub/Samuel.Trahan/prep_chem/TEST_DATA/BBEM_WFABBA_DIR/
export BBEM_WFABBA_DIR_YESTERDAY="$BBEM_WFABBA_DIR_TODAY"
export GBBEPX_DATA_DIR_YESTERDAY=/gpfs/dell1/nco/ops/dcom/dev/${YYYYMMDDHH:0:8}/firewx
export GBBEPX_DATA_DIR_TODAY=/gpfs/dell1/nco/ops/dcom/dev/${YYYYMMDDHH:0:8}/firewx

export gbbepx_list="GBBEPx.emis_BC GBBEPx.emis_OC GBBEPx.emis_SO2 GBBEPx.emis_PM25 GBBEPx.FRP"
export inout_list="plume,plumestuff OC-bb,ebu_oc BC-bb,ebu_bc BBURN2-bb,ebu_pm_25 BBURN3-bb,ebu_pm_10 SO2-bb,ebu_so2 SO4-bb,ebu_sulf"

# Copy whichever of these is relevant into your ecf file.  Do NOT load
# prod_util in your ecf file though; the head.h does that for you.
if [ -d /ptmpp2 ] ; then
    # WCOSS Phase 1 and 2 need to load the compiler and libraries.
    set +xu
    module load prod_util
    module load ics
    module load NetCDF/4.2/serial
    module load HDF5/1.8.9/serial
elif [ -e /usrx ] && ( readlink /usrx | grep dell > /dev/null 2>&1 ) ; then
    # WCOSS Phase 3 prerequisites:
    set +xu
    module load ips/18.0.1.163
    module load NetCDF/4.5.0
    module load HDF5-serial/1.10.1
    module load prod_util/1.1.1
elif [ -s /etc/SuSE-release -a -e /usrx ] ; then
    # WCOSS Cray; assumes NO "module purge" was done:
    set +xu
    module load intel
    module load NetCDF-intel-haswell/4.2
    module load HDF5-serial-intel-haswell/1.8.9
    module load prod_util
elif [ -d /scratch1 -a -d /scratch2 ] ; then
    # Hera
    set +xu
    # Should match prep-chem/fv3-prep-chem/bin/build/mk-fv3-hera
    module load intel/18.0.5.274
    module load hdf5/1.10.5
    module load netcdf/4.7.0

    # Have to get prod_util from a dev area:
    module use /scratch2/NCEPDEV/nwprod/NCEPLIBS/modulefiles/
    module load prod_util

    # Different data area:
    export BBEM_WFABBA_DIR_TODAY=/scratch2/BMC/public/data/sat/nesdis/wf_abba/
    export BBEM_WFABBA_DIR_YESTERDAY="$BBEM_WFABBA_DIR_TODAY"
    export BBEM_MODIS_DIR_TODAY=/scratch2/BMC/public/data/sat/firms/global/
    export BBEM_MODIS_DIR_YESTERDAY="$BBEM_MODIS_DIR_TODAY"
    export GBBEPX_DATA_DIR_TODAY=/scratch2/BMC/wrfruc/Samuel.Trahan/prep-chem/gbbepx-20200429/
    export GBBEPX_DATA_DIR_YESTERDAY="$GBBEPX_DATA_DIR_TODAY"
fi

set -xue

# Name of this task in the ecflow suite:
export job=jglobal_prep_chem

# Production/parallel level: test, para, prod.  Specifies where to
# get/send data.
export envir=para

# This line must be in the ecf file; it passes control to the j-job:
$HOMEchem/jobs/JGLOBAL_PREP_CHEM

#######################################################################

# Everything after this point belongs in the forecast job; it is here
# just for test purposes.

# These three lines doesn't go in the prep-chem job:
mkdir "$DATAROOT/test-link-chem"
cd "$DATAROOT/test-link-chem"
$HOMEchem/ush/global_link_chem.bash $COMROOT/gens/para/gefs.$PDY/chem/gefs.t${cyc}z.chem_

set +xue
echo 'Success!'
echo "EMISDIR: $DATAROOT/test-link-chem/EMISDIR"
echo "Chemistry COM: $COMROOT"
echo "Scrub files: $DATAROOT"
