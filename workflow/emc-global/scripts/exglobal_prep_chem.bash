#! /bin/bash

# NOTE: This is a bash script; not ksh or sh.  It uses bash regular
# expression captures for speed.

# Runs the prep_chem_sources program to produce FV3 inputs for
# chemistry fields.  All inputs are environment variables; any
# arguments are ignored.
#
# Output filenames are generated from this pair of variables:
#   $COMOUTchem/$CHEM_OUTPUT_FORMAT
# The following two strings are replaced:
#   %INPUT% = tracer name or other input name
#   %TILE% = tile number
#
# Date & Time:
#   $SYEAR, $SMONTH, $SDAY, $SHOUR
#     -or-
#   $PDY = $SYEAR$SMONTH$SDAY, $cyc = $SHOUR
#
# Executable: $PREP_CHEM_SOURCES_EXE
#
# Resolution (ie. C384): $CASE
#  NOTE: Only C384 will work presently.
#
# Input data:
#   $PARMchem/prep_chem_sources.inp.IN
#   $FIXchem = static input directory
#   $BBEM_MODIS_DATA = location of MODIS fire data plus filename prefix
#   $BBEM_WFABBA_DATA = location of other input data plus filename prefix
#
# Other:
#   $DATA = where to run
#   $SENDCOM = YES if data should be copied to COM; default is YES
#   $SENDDBN = ignored; would enable NCO's dbnet calls
#   $SENDECF = ignored; would enable ecflow_client calls

# DEV NOTES
# As of this writing, test data for MODIS $BBEM_MODIS_DATA is:
#  Gyre/Surge/Venus: /gpfs/dell2/emc/obsproc/noscrub/Sudhir.Nadiga/MODISfiredata/datafiles/FIRMS/c6/Global/MODIS_C6_Global_MCD14DL_NRT_
# For "other input data" $BBEM_WFABBA_DATA:
#  Jet: /public/data/sat/nesdis/wf_abba/
#  Gyre/Surge/Venus: /gpfs/dell2/emc/obsproc/noscrub/Samuel.Trahan/prep_chem/public/data/sat/nesdis/wf_abba/f
# The FIXchem:
#  Gyre/Surge/Venus: /gpfs/dell2/emc/obsproc/noscrub/Samuel.Trahan/prep_chem/FIXchem/

set -xue

if [ ! -d "$COMOUTchem" ] ; then
    mkdir -p "$COMOUTchem"
fi

if [ ! -d "$DATA" ] ; then
    mkdir -p "$DATA"
    cd "$DATA"
fi

SYEAR="${SYEAR:-${PDY:0:4}}"
SMONTH="${SMONTH:-${PDY:4:2}}"
SDAY="${SDAY:-${PDY:6:2}}"
SHOUR="${SHOUR:-$cyc}"

PREP_CHEM_SOURCES_EXE="${PREP_CHEM_SOURCES_EXE:-$EXECchem/prep_chem_sources}"

SENDCOM="${SENDCOM:-YES}"
# - this variable is not used - SENDDBN="${SENDDBN:-NO}"
# - this variable is not used - SENDECF="${SENDECF:-NO}"

echo "in emission_setup:"
emiss_date="$SYEAR-$SMONTH-$SDAY-$SHOUR"
echo "emiss_date: $emiss_date"
echo "yr: $SYEAR mm: $SMONTH dd: $SDAY hh: $SHOUR"

FIX_GRID_SPEC=$FIXchem/grid-spec/${CASE}/${CASE}_grid_spec

cp -fp "$PARMchem/prep_chem_sources.inp.IN" .
cat prep_chem_sources.inp.IN | sed \
    "s:%HH%:$SHOUR:g                                  ;
     s:%DD%:$SDAY:g                                   ;
     s:%MM%:$SMONTH:g                                 ;
     s:%YYYY%:$SYEAR:g                                ;
     s:%FIXchem%:$FIXchem:g                           ;
     s:%FIX_GRID_SPEC%:$FIX_GRID_SPEC:g               ;
     s:%BBEM_WFABBA_DATA%:$BBEM_WFABBA_DATA:g         ;
     s:%BBEM_MODIS_DATA%:$BBEM_MODIS_DATA:g           ;
    " > prep_chem_sources.inp

if ( cat prep_chem_sources.inp | grep % ) ; then
    echo "POSSIBLE ERROR: still have % signs in prep_chem_sources.inp" 1>&2
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
        set +x # A line-by-line log is too verbose here:
        if [[ $inout =~ (.*),(.*) ]] ; then
            infile="${CASE}-T-${emiss_date}0000-${BASH_REMATCH[1]}.bin"
            outfile=$( echo "$COMOUTchem/$CHEM_OUTPUT_FORMAT" | sed \
                "s:%INPUT%:${BASH_REMATCH[2]}:g ;
                 s:%TILE%:$itile:g" )
        else
            echo "Internal error: could not split \"$inout\" into two elements at a comma." 1>&2
            exit 9
        fi

        outdir=$( dirname "$outfile" )
        outbase=$( basename "$outfile" )
        randhex=$( printf '%02x%02x%02x%02x' $(( RANDOM%256 )) $(( RANDOM%256 )) $(( RANDOM%256 )) $(( RANDOM%256 )) )
        tempfile="$outdir/.tmp.$outbase.$randhex.part"

        set -x

        if [[ ! -d "$outdir" ]] ; then
            mkdir -p "$outdir"
        fi
        rm -f "$outfile"
        cp -fp "$infile" "$tempfile"
        mv -T -f "$tempfile" "$outfile"
    done

    popd
done

echo 'Success!'
echo 'Please enjoy your new tracers.'
exit 0