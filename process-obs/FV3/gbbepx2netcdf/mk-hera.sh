#! /bin/sh

set -ue
module purge
module load gnu intel/2023.2.0 netcdf/4.7.0 szip hdf5
module list
set -x

fflags=$( nf-config --fflags )
flibs=$( nf-config --flibs )

ifort $fflags -I. -c -o mkncgbbepx.o mkncgbbepx.f90 -g -traceback
ifort $fflags -o mkncgbbepx.exe mkncgbbepx.o -g -traceback $flibs
