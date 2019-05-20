#! /bin/bash

# Runs the prep_chem_sources program to produce FV3 inputs for
# chemistry fields.  Expected inputs are all environment variables.
#
# Output filenames are generated from this pair of variables:
#   $COMOUTchem/$CHEM_OUTPUT_FORMAT
# The following two strings are replaced:
#   <input> = tracer name or other input name
#   <tile> = tile number
#
# Optional variables:
#   $NCP = "cp -p" or equivalent
#   $NLN = "ln -sf" or equivalent
#
# Date & Time:
#   $SYEAR, $SMONTH, $SDAY, $SHOUR
#     -or-
#   $PDY = $SYEAR$SMONTH$SDAY, $cyc = $SHOUR
#
# Executable: $PREP_CHEM_SOURCES_EXE
#
# Inputs:
#   $PARMchem/prep_chem_sources.inp.IN
#   $FIXchem = static input directory
#   $BBEM_MODIS_DATA_DIR = location of MODIS fire data
#   $BBEM_WFABBA_DATA_DIR = location of other input data
#   $FIX_GRID_SPEC = directory with FV3 model grid
#
# Other:
#   $DATA = where to run

# Dev nodes.  Test data for MODIS $BBEM_MODIS_DATA_DIR
#  Gyre/Surge/Venus: /gpfs/dell2/emc/obsproc/noscrub/Sudhir.Nadiga/MODISfiredata/datafiles/FIRMS/c6/Global
# For "other input data" $BBEM_WFABBA_DATA_DIR
#  Jet: /public/data/sat/nesdis/wf_abba/
#  Gyre/Surge/Venus: /gpfs/dell2/emc/obsproc/noscrub/Samuel.Trahan/prep_chem/public/data/sat/nesdis/wf_abba

set -xue

if [ ! -d "$COMOUTchem" ] ; then
    mkdir -p "$COMOUTchem"
fi

NCP="${NCP:-/bin/cp -pf}"
NLN="${NLN:-/bin/ln -sf}"

SYEAR="${SYEAR:-${PDY:0:4}}"
SMONTH="${SMONTH:-${PDY:4:2}}"
SDAY="${SDAY:-${PDY:6:2}}"
SHOUR="${SHOUR:-$cyc}"

PREP_CHEM_SOURCES_EXE="${PREP_CHEM_SOURCES_EXE:-$EXECchem/prep_chem_sources}"

print "in emission_setup:"
emiss_date="$SYEAR-$SMONTH-$SDAY-$SHOUR"
print "emiss_date: $emiss_date"
print "yr: $SYEAR mm: $SMONTH dd: $SDAY hh: $SHOUR"

$NCP "$PARMchem/prep_chem_sources.inp.IN" .
cat prep_chem_sources.inp.IN | sed \
    "s:%HH%:$SHOUR:g                                  ;
     s:%DD%:$SDAY:g                                   ;
     s:%MM%:$SMONTH:g                                 ;
     s:%YYYY%:$SYEAR:g                                ;
     s:%FIXchem%:$FIXchem                             ;
     s:%FIX_GRID_SPEC%:$FIXgridspec:g                 ;
     s:%BBEM_WFABBA_DATA_DIR%:$BBEM_WFABBA_DATA_DIR:g ;
     s:%BBEM_MODIS_DATA_DIR%:$BBEM_MODIS_DATA_DIR:g   ;
    " > prep_chem_sources.inp

if ( cat prep_chem_sources.inp | grep % ) ; then
    echo "Internal error: still have % signs in prep_chem_sources.inp" 1>&2
    echo "Some variables may not have been replaced." 1>&2
    echo "I will continue, but you should keep your fingers crossed." 1>&2
fi

#
$PREP_CHEM_SOURCES_EXE
#

inout_list="plume,plumestuff OC-bb,ebu_oc BC-bb,ebu_bc BBURN2-bb,ebu_pm_25 BBURN3-bb,ebu_pm_10 SO2-bb,ebu_so2 SO4-bb,ebu_sulf ALD-bb,ebu_ald ASH-bb,ebu_ash.dat CO-bb,ebu_co CSL-bb,ebu_csl DMS-bb,ebu_dms ETH-bb,ebu_eth HC3-bb,ebu_hc3 HC5-bb,ebu_hc5 HC8-bb,ebu_hc8 HCHO-bb,ebu_hcho ISO-bb,ebu_iso KET-bb,ebu_ket NH3-bb,ebu_nh3 NO2-bb,ebu_no2 NO-bb,ebu_no OLI-bb,ebu_oli OLT-bb,ebu_olt ORA2-bb,ebu_ora2 TOL-bb,ebu_tol XYL-bb,ebu_xyl"

for itile in $( seq 1 6 ) ; do
    tiledir=tile$itile
    pushd $tiledir

    for inout in $inout_list ; do
	if [[ $inout =~ '(.*),(.*)' ]] ; then
	    infile="${CASE}-T-${emiss_date}0000-${BASH_REMATCH[1]}.bin"
	    outfile=$( echo "$COMOUTchem/$CHEM_OUTPUT_FORMAT" | sed \
		"s:<input>:${BASH_REMATCH[2]}:g ;
                 s:<tile>:$itile:g" )
	else
	    echo "Internal error: could not split $inout into two elements at a comma." 1>&2
	    exit 9
	fi
	rm *-ab.bin
    done

    popd

    rm *-g${itile}.ctl *-g${itile}.vfm *-g${itile}.gra
done

echo 'Success!'
echo 'Please enjoy your new tracers.'
exit 0