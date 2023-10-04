#! /bin/bash
# This is a bash script; not ksh or sh.  Do not change the above line.

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
#   $BBEM_MODIS_DATA_DIR_TODAY = directory with today's modis fire data
#   $BBEM_MODIS_DATA_DIR_YESTERDAY = directory with yesterday's modis fire data
#   $BBEM_WFABBA_DATA_DIR_TODAY = directory with today's wf_abba data
#   $BBEM_WFABBA_DATA_DIR_YESTERDAY = directory with yesterday's wf_abba data
#   $GBBEPX_DATA_DIR_TODAY = directory with today's GSCE GBBEPx data
#   $GBBEPX_DATA_DIR_YESTERDAY = directory with yesterday's GSCE GBBEPx data
# (Each data source must have both today and yesterday directories specified, but
# only one day per source must exist to run this script.)
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

set -x

if [[ ! -d "$COMOUTchem" ]] ; then
    mkdir -p "$COMOUTchem"
fi

if [[ ! -d "$DATA" ]] ; then
    mkdir -p "$DATA"
    cd "$DATA"
fi

SYEAR="${SYEAR:-${PDY:0:4}}"
SMONTH="${SMONTH:-${PDY:4:2}}"
SDAY="${SDAY:-${PDY:6:2}}"
SHOUR="${SHOUR:-$cyc}"
PDY="${PDY:-$SYEAR$SMONTH$SDAY}"

PREP_CHEM_SOURCES_EXE="${PREP_CHEM_SOURCES_EXE:-$EXECchem/prep_chem_sources_RADM_FV3_SIMPLE.exe}"

SENDCOM="${SENDCOM:-YES}"
# - this variable is not used - SENDDBN="${SENDDBN:-NO}"
# - this variable is not used - SENDECF="${SENDECF:-NO}"

echo "in emission_setup:"
emiss_date="$SYEAR-$SMONTH-$SDAY-$SHOUR"
echo "emiss_date: $emiss_date"
echo "yr: $SYEAR mm: $SMONTH dd: $SDAY hh: $SHOUR"

FIX_GRID_SPEC=$FIXchem/grid-spec/${CASE}/${CASE}_grid_spec

mkdir MODIS

jul_today=$( date -d "$SYEAR-$SMONTH-$SDAY 12:00:00 +0000" +%Y%j )
jul_yesterday=$( date -d "$SYEAR-$SMONTH-$SDAY 12:00:00 +0000 + -1 day" +%Y%j )

count_modis=0
count_gbbepx=0
expect_gbbepx=0
use_gbbepx=NO

gbbepx_list=${gbbepx_list:-"GBBEPxemis-BC GBBEPxemis-OC GBBEPxemis-SO2 GBBEPxemis-PM25 GBBEPxFRP-MeanFRP"}

cd MODIS

sHeader_modis="latitude,longitude,brightness,scan,track,acq_date,acq_time,satellite,confidence,version,bright_t31,frp,daynight"
set -x # This region is too verbose for "set -x"
for path in \
    "$BBEM_MODIS_DIR_YESTERDAY/MODIS_C6_1_Global_MCD14DL_NRT_$jul_yesterday"* \
    "$BBEM_MODIS_DIR_TODAY/MODIS_C6_1_Global_MCD14DL_NRT_$jul_today"*
do
    if [[ -s "$path" ]] ; then
        sHeader=`head -1 $path`
        if [[ $sHeader_modis == $sHeader ]]; then
            ln -s "$path" .
            count_modis=$(( count_modis+1 ))
            echo "WILL LINK: $path"
        else
            echo "Format is wrong and will NOT link: $path"
        fi
    else
        echo "EMPTY: $path"
    fi
done
echo "Found $count_modis MODIS fire data files."
set -x

cd ..

# Any variables have to be exported to the environment before substitution
if [[ $SHOUR == 00 ]] ; then
    export GBBEPX_DATA_DIR=$GBBEPX_DATA_DIR_YESTERDAY
    export gbbepx_days=${gbbepx_days:-'$PDYm2'}
else
    export GBBEPX_DATA_DIR=$GBBEPX_DATA_DIR_TODAY    
    export gbbepx_days=${gbbepx_days:-'$PDYm1'}
fi
gbbepx_pattern=${gbbepx_pattern:-'$GBBEPX_DATA_DIR/${local_name}-${CASE}${GTtile}_v4r0_blend_s${day}'}
gbbepx_days=$(env envsubst <<< $gbbepx_days)
for day in $gbbepx_days; do
    set -x  # This region is too verbose for "set -x"
    export day
    expect_gbbepx=0
    count_gbbepx=0
    for local_name in $gbbepx_list ; do
        export local_name
        for itile in 1 2 3 4 5 6 ; do
            export tiledir=tile$itile
            export GTtile=GT$itile
            export expect_gbbepx=$(( expect_gbbepx + 1 ))
            infile=$(env envsubst <<< $gbbepx_pattern)
            infile=$(ls ${infile}*.bin)
            if [[ -s "$infile" ]] ; then
                count_gbbepx=$(( count_gbbepx + 1 ))
            fi
        done
    done
    if (( count_gbbepx==expect_gbbepx )); then
        # We have all the GBBEPX files
        echo "For $PDY $SHOUR GBBEPX files found for $day at $gbbepx_pattern"
        break
    fi
    set -x
done

if (( count_modis==0 )) ; then
    echo "WARNING: NO MODIS FIRE DATA FOUND!" 1>&2
fi

if (( count_gbbepx == 0 )) ; then
    echo "WARNING: NO GBBEPX FILES FOUND!" 1>&2
    use_gbbepx=NO
elif (( count_gbbepx!=expect_gbbepx )) ; then
    echo "WARNING: EXPECTED $expect_gbbepx GBBEPX FILES BUT FOUND $count_gbbepx!  WILL NOT USE GBBEPX!" 1>&2
    use_gbbepx=NO
else
    use_gbbepx=YES
fi

if (( count_modis==0 && count_gbbepx!=expect_gbbepx )) ; then
    echo "WARNING: NO REAL-TIME DATA FOUND!  RESORTING TO STATIC DATA!" 1>&2
fi

cp -fp "$PARMchem/prep_chem_sources.inp.IN" .
cat prep_chem_sources.inp.IN | sed \
    "s:%HH%:$SHOUR:g                                             ;
     s:%DD%:$SDAY:g                                              ;
     s:%MM%:$SMONTH:g                                            ;
     s:%YYYY%:$SYEAR:g                                           ;
     s:%FIXchem%:$FIXchem:g                                      ;
     s:%FIX_GRID_SPEC%:$FIX_GRID_SPEC:g                          ;
     s:%BBEM_MODIS_DATA%:./MODIS/MODIS_C6_Global_MCD14DL_NRT_:g  ;
     s:%BBEM_WFABBA_DATA%:./WFABBA/f:g                           ;
    " > prep_chem_sources.inp

if ( cat prep_chem_sources.inp | grep % ) ; then
    echo "POSSIBLE ERROR: still have % signs in prep_chem_sources.inp" 1>&2
    echo "Some variables may not have been replaced." 1>&2
    echo "I will continue, but you should keep your fingers crossed." 1>&2
fi

#
if [[ "$use_gbbepx" == NO ]] ; then
    $PREP_CHEM_SOURCES_EXE
fi
#

if [[ "$use_gbbepx" == YES ]] ; then
    inout_list=${inout_list:-"GBBEPxemis-BC,ebu_bc GBBEPxemis-OC,ebu_oc GBBEPxemis-SO2,ebu_so2 GBBEPxemis-PM25,ebu_pm_25 GBBEPxFRP-MeanFRP,plumefrp"}
else
    inout_list=${inoout_list:-"plume,plumestuff OC-bb,ebu_oc BC-bb,ebu_bc BBURN2-bb,ebu_pm_25 BBURN3-bb,ebu_pm_10 SO2-bb,ebu_so2 SO4-bb,ebu_sulf"}
fi

if [[ "${SENDCOM:-YES}" == YES ]] ; then
    for itile in 1 2 3 4 5 6 ; do
        tiledir=tile$itile
        GTtile=GT$itile
        if [[ ! -d "$tiledir" ]] ; then
            echo "make directory $tiledir" 1>&2
            mkdir -p "$tiledir"
        fi
        pushd $tiledir

        set +x # A line-by-line log is too verbose here:
        for inout in $inout_list ; do
            if [[ $inout =~ (.*),(.*) ]] ; then
                local_name="${BASH_REMATCH[1]}"
                comdir_name="${BASH_REMATCH[2]}"

                is_gbbepx_data=NO
                for gdat in $gbbepx_list ; do
                    if [[ "$gdat" == "$local_name" ]] ; then
                        is_gbbepx_data=YES
                        break
                    fi
                done

                if [[ "$is_gbbepx_data" == YES ]] ; then
                    if [[ "$use_gbbepx" != YES ]] ; then
                        continue
                    fi
                    export local_name
                    infile=$(env envsubst <<< $gbbepx_pattern)
                    infile=$(ls ${infile}*.bin)
                else
                    infile="${CASE}-T-${emiss_date}0000-${local_name}.bin"
                fi
                step1="$COMOUTchem/$CHEM_OUTPUT_FORMAT"
                step2=${step1//%INPUT%/$comdir_name}
                outfile=${step2//%TILE%/$itile}
            else
                echo "Internal error: could not split \"$inout\" into two elements at a comma." 1>&2
                exit 9
            fi

            set -ue
            outdir=$( dirname "$outfile" )
            outbase=$( basename "$outfile" )
            randhex=$( printf '%02x%02x%02x%02x' $(( RANDOM%256 )) $(( RANDOM%256 )) $(( RANDOM%256 )) $(( RANDOM%256 )) )
            tempbase=".tmp.$outbase.$randhex.part"
            tempfile="$outdir/$tempbase"

            if [[ ! -d "$outdir" ]] ; then
                echo "make directory $outdir" 1>&2
                mkdir -p "$outdir"
            fi
            rm -f "$outfile"
            echo "copy $infile => $tempfile" 1>&2
            cp -fp "$infile" "$tempfile"
            echo "rename $tempbase => $outbase in $outdir" 1>&2
            mv -T -f "$tempfile" "$outfile"
        done
        set -x
        popd
    done
fi

echo 'Success!'
echo 'Please enjoy your new tracers.'
exit 0
