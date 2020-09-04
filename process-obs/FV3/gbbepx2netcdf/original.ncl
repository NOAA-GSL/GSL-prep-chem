; This code was the basis of the fortran program.
; It is only here for reference purposes, not for actual use.

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin
   nlon = 96
   nlat = 96

   pathlon     = "/scratch1/BMC/gsd-fv3-dev/Haiqin.Li/Develop/emi_C96/lon/lon_tile1.dat"
   pathlat     = "/scratch1/BMC/gsd-fv3-dev/Haiqin.Li/Develop/emi_C96/lat/lat_tile1.dat"
   pathebc     = "/scratch1/BMC/gsd-fv3-dev/lzhang/GBBEPx/C96/20200201/GBBEPx.bc.20200201.FV3.C96Grid.tile1.bin"
   patheoc     = "/scratch1/BMC/gsd-fv3-dev/lzhang/GBBEPx/C96/20200201/GBBEPx.oc.20200201.FV3.C96Grid.tile1.bin"
   pathepm25   = "/scratch1/BMC/gsd-fv3-dev/lzhang/GBBEPx/C96/20200201/GBBEPx.pm25.20200201.FV3.C96Grid.tile1.bin"
   patheso2    = "/scratch1/BMC/gsd-fv3-dev/lzhang/GBBEPx/C96/20200201/GBBEPx.so2.20200201.FV3.C96Grid.tile1.bin"
   patheplume  = "/scratch1/BMC/gsd-fv3-dev/lzhang/GBBEPx/C96/20200201/meanFRP.20200201.FV3.C96Grid.tile1.bin"

   nrec = 0
   dims = (/96,96/)

   setfileoption("bin","ReadByteOrder","LittleEndian")

   lon     = fbinrecread(pathlon,    nrec, nlon, "float")
   lat     = fbinrecread(pathlat,    nrec, nlat, "float")
   ebu_bc    = fbinrecread(pathebc,    nrec, dims, "float")
   ebu_oc    = fbinrecread(patheoc,    nrec, dims, "float")
   ebu_pm_25 = fbinrecread(pathepm25,  nrec, dims, "float")
   ebu_so2   = fbinrecread(patheso2,   nrec, dims, "float")
   ebu_frp = fbinrecread(patheplume, nrec, dims, "float")

   lat!0   = "lat"
   lat&lat = lat

   lon!0   = "lon"
   lon&lon = lon


   ebu_bc!0="lat"
   ebu_bc!1="lon"
   ebu_bc&lat  = lat
   ebu_bc&lon  = lon

   ebu_oc!0="lat"
   ebu_oc!1="lon"
   ebu_oc&lat  = lat
   ebu_oc&lon  = lon

   ebu_pm_25!0="lat"
   ebu_pm_25!1="lon"
   ebu_pm_25&lat  = lat
   ebu_pm_25&lon  = lon

   ebu_so2!0="lat"
   ebu_so2!1="lon"
   ebu_so2&lat  = lat
   ebu_so2&lon  = lon

   ebu_frp!0="lat"
   ebu_frp!1="lon"
   ebu_frp&lat  = lat
   ebu_frp&lon  = lon
                                                                  
  ;============================================================
  ; create the output file
  ;============================================================
  diro = "./"                              ; Output directory
  filo = "FIRE_GBBEPx_data.tile1.nc"            ; Output file
  system("/bin/rm -f " + diro + filo)      ; remove if exists
  fout = addfile (diro + filo, "c")        ; open output file
  ;============================================================
  fout@title     ="anthropogenic background input (C96, 10, tile1)"
  fout->lat      = lat
  fout->lon      = lon
  fout->ebu_bc     = ebu_bc
  fout->ebu_oc     = ebu_oc
  fout->ebu_pm_25  = ebu_pm_25
  fout->ebu_so2    = ebu_so2
  fout->ebu_frp  = ebu_frp

end
