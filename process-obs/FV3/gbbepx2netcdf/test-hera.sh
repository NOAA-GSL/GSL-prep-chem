#! /bin/sh

set -ue
module load intel netcdf szip hdf5
set -x

exec ./mkncgbbepx.exe <<EOF
&mkncgbbepx
   title = "anthropogenic background input (C96, 10, tile1)"
   tile = 1
   date = '2020-02-01'
   nlon = 96
   nlat = 96
   outfile     = "FIRE_GBBEPx_data.tile1.nc"
   pathlon     = "/scratch1/BMC/gsd-fv3-dev/Haiqin.Li/Develop/emi_C96/lon/lon_tile1.dat"
   pathlat     = "/scratch1/BMC/gsd-fv3-dev/Haiqin.Li/Develop/emi_C96/lat/lat_tile1.dat"
   pathebc     = "/scratch1/BMC/gsd-fv3-dev/lzhang/GBBEPx/C96/20200201/GBBEPx.bc.20200201.FV3.C96Grid.tile1.bin"
   patheoc     = "/scratch1/BMC/gsd-fv3-dev/lzhang/GBBEPx/C96/20200201/GBBEPx.oc.20200201.FV3.C96Grid.tile1.bin"
   pathepm25   = "/scratch1/BMC/gsd-fv3-dev/lzhang/GBBEPx/C96/20200201/GBBEPx.pm25.20200201.FV3.C96Grid.tile1.bin"
   patheso2    = "/scratch1/BMC/gsd-fv3-dev/lzhang/GBBEPx/C96/20200201/GBBEPx.so2.20200201.FV3.C96Grid.tile1.bin"
   patheplume  = "/scratch1/BMC/gsd-fv3-dev/lzhang/GBBEPx/C96/20200201/meanFRP.20200201.FV3.C96Grid.tile1.bin"
/
EOF
